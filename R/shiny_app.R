build_default_ui_roles <- function(df) {
  roles <- detect_column_roles(df, obfuscator_config())
  roles <- enrich_release_review_roles(df, roles)
  assigned <- unique(unlist(roles, use.names = FALSE))
  roles$available <- setdiff(colnames(df), assigned)
  if (is.null(roles$preserve)) roles$preserve <- character(0)
  roles
}

enrich_release_review_roles <- function(df, roles) {
  roles$sensitive <- unique(roles$sensitive %||% character(0))
  roles$private <- unique(roles$private %||% character(0))

  cols <- colnames(df)
  if (length(cols) == 0) {
    return(roles)
  }

  normalized <- tolower(cols)

  private_name_patterns <- c(
    "observ", "coment", "nota", "texto", "descripcion",
    "direccion", "telefono", "mail", "correo"
  )
  sensitive_name_patterns <- c(
    "privad", "sensib", "diagn", "enfer", "ingreso",
    "salario", "monto", "beneficio", "subsid", "tramo_ingreso"
  )

  has_pattern <- function(name_vec, patterns) {
    vapply(name_vec, function(x) any(vapply(patterns, grepl, logical(1), x, fixed = TRUE)), logical(1))
  }

  text_like_cols <- cols[vapply(df, function(column) {
    if (!(is.character(column) || is.factor(column))) {
      return(FALSE)
    }
    values <- as.character(column)
    values <- values[!is.na(values) & nzchar(trimws(values))]
    if (length(values) == 0) {
      return(FALSE)
    }
    mean(nchar(values), na.rm = TRUE) >= 18
  }, logical(1))]

  private_candidates <- unique(c(
    cols[has_pattern(normalized, private_name_patterns)],
    text_like_cols
  ))
  sensitive_candidates <- unique(c(
    cols[has_pattern(normalized, sensitive_name_patterns)]
  ))

  protected_roles <- unique(c(
    roles$id %||% character(0),
    roles$date %||% character(0),
    roles$numeric %||% character(0),
    roles$preserve %||% character(0),
    roles$exclude %||% character(0)
  ))

  private_candidates <- setdiff(private_candidates, protected_roles)
  sensitive_candidates <- setdiff(sensitive_candidates, c(protected_roles, private_candidates))

  roles$categorical <- setdiff(roles$categorical %||% character(0), c(private_candidates, sensitive_candidates))
  roles$private <- unique(c(roles$private, private_candidates))
  roles$sensitive <- unique(c(roles$sensitive, sensitive_candidates))
  roles
}

quasi_identifier_choices <- function(df, ui_roles) {
  if (is.list(ui_roles) && length(ui_roles) > 0) {
    canonical_entries <- vapply(
      ui_roles,
      function(entry) is.list(entry) && !is.null(entry$role),
      logical(1)
    )
    if (all(canonical_entries)) {
      return(intersect(release_safe_quasi_identifiers(ui_roles), colnames(df)))
    }
  }

  intersect(unique(c(
    ui_roles$id %||% character(0),
    ui_roles$date %||% character(0),
    ui_roles$categorical %||% character(0),
    ui_roles$numeric %||% character(0)
  )), colnames(df))
}

build_release_safe_audit_context <- function(df, role_state, suggested_roles = list()) {
  if (!is.data.frame(df) || ncol(df) == 0) {
    return(list(
      qi = character(0),
      sensitive = character(0),
      private = character(0),
      roles_by_variable = setNames(character(0), character(0))
    ))
  }

  variables <- colnames(df)
  roles_by_variable <- stats::setNames(
    vapply(
      variables,
      function(var_name) release_safe_role_from_state(var_name, role_state, suggested_roles = suggested_roles),
      character(1)
    ),
    variables
  )
  visible_sets <- release_safe_display_role_sets(df, role_state, suggested_roles = suggested_roles)

  list(
    qi = intersect(visible_sets$qi, variables),
    sensitive = intersect(visible_sets$sensitive, variables),
    private = intersect(visible_sets$private, variables),
    roles_by_variable = roles_by_variable
  )
}

build_release_safe_privacy_model <- function(
  df,
  role_state,
  k_enabled,
  k_value,
  k_suppression = "rows",
  group_ids = FALSE,
  hierarchies = list(),
  suggested_roles = list()
) {
  if (!isTRUE(k_enabled)) {
    return(NULL)
  }

  normalized_k <- suppressWarnings(as.integer(k_value))
  if (is.na(normalized_k) || normalized_k < 2L) {
    normalized_k <- 2L
  }

  audit_context <- build_release_safe_audit_context(
    df,
    role_state = role_state,
    suggested_roles = suggested_roles
  )

  list(
    type = "k_anonymity",
    k = normalized_k,
    quasi_identifiers = audit_context$qi,
    suppression = k_suppression,
    group_ids = isTRUE(group_ids),
    hierarchies = hierarchies
  )
}

augment_release_audit_log_with_release_safe_context <- function(
  log_info,
  df,
  role_state,
  suggested_roles = list()
) {
  augmented_log <- log_info %||% list()
  audit_context <- build_release_safe_audit_context(
    df,
    role_state = role_state,
    suggested_roles = suggested_roles
  )

  augmented_log$release_safe <- audit_context
  augmented_log$roles <- augmented_log$roles %||% list()
  augmented_log$roles$qi <- intersect(audit_context$qi, colnames(df))
  augmented_log$roles$sensitive <- intersect(audit_context$sensitive, colnames(df))
  augmented_log$roles$private <- intersect(audit_context$private, colnames(df))
  augmented_log
}

build_release_role_summary <- function(df, roles, k_enabled = FALSE) {
  visible_sets <- release_safe_display_role_sets(df, roles)
  qis <- visible_sets$qi
  sensitive <- visible_sets$sensitive
  private <- visible_sets$private

  chips_or_fallback <- function(values, empty_text) {
    if (length(values) == 0) {
      return(shiny::tags$span(class = "release-role-empty", empty_text))
    }
    lapply(values, function(value) shiny::tags$span(class = "release-role-chip", value))
  }

  shiny::tags$div(
    class = "release-role-summary",
    shiny::tags$div(
      class = "release-role-card",
      shiny::tags$strong("Quasi-identificadores usados por k-anonymity"),
      shiny::tags$div(class = "release-role-list", chips_or_fallback(qis, "Todavia no hay quasi-identificadores.")),
      shiny::tags$p(
        class = "help-text",
        if (isTRUE(k_enabled)) {
          "Este resumen refleja las variables marcadas como QI en la vista principal de liberacion."
        } else {
          "Activa k-anonymity para evaluar liberacion externa con esta lista."
        }
      )
    ),
    shiny::tags$div(
      class = "release-role-card",
      shiny::tags$strong("Variables sensibles"),
      shiny::tags$div(class = "release-role-list", chips_or_fallback(sensitive, "Sin variables sensibles clasificadas.")),
      shiny::tags$p(class = "help-text", "No entran automaticamente como quasi-identificadores. Requieren interpretacion especifica del riesgo.")
    ),
    shiny::tags$div(
      class = "release-role-card",
      shiny::tags$strong("Variables privadas"),
      shiny::tags$div(class = "release-role-list", chips_or_fallback(private, "Sin variables privadas clasificadas.")),
      shiny::tags$p(class = "help-text", "Incluye campos de texto libre u otras columnas que ameritan cautela adicional.")
    )
  )
}

release_safe_role_definition <- function(role) {
  switch(
    toupper(role %||% ""),
    ID = "Identifica directamente a la unidad de analisis y no debe liberarse tal cual.",
    QI = "Puede identificar por combinacion con otras variables y entra a k-anonymity.",
    SENS = "Revela informacion delicada, aunque no identifique por si sola.",
    PRIV = "Contiene informacion especialmente riesgosa o dificil de controlar, como texto libre.",
    KEEP = "Puede conservarse en la salida sin ser eje principal del control de anonimato.",
    EXC = "Debe excluirse de la salida final.",
    "Rol sin definir."
  )
}

release_safe_role_glossary <- function() {
  setNames(
    lapply(release_safe_allowed_roles(), release_safe_role_definition),
    release_safe_allowed_roles()
  )
}

release_safe_workflow_steps <- function() {
  c(
    "Carga el dataset y revisa las sugerencias automaticas.",
    "Confirma el rol principal de cada variable desde la tabla.",
    "Abre Ver detalle en las variables dudosas para leer impacto y tratamiento.",
    "Si el resultado es solo para uso interno, puedes conservarlo como artefacto interno; si va a terceros, manten k-anonymity activo y revisa el estado final.",
    "Ejecuta la evaluacion y revisa bloqueos, advertencias y resumen de auditoria.",
    "Exporta solo si el estado final del dataset es Liberable."
  )
}

privacy_meter_explanation_points <- function() {
  list(
    preliminar = c(
      "Antes de ejecutar, la estimacion usa el valor de k, la cantidad de variables clasificadas como ID y QI, y la presencia de jerarquias activas.",
      "Es una heuristica orientativa: ayuda a detectar configuraciones debiles, pero no decide por si sola si un dataset puede liberarse."
    ),
    evaluado = c(
      "Despues de ejecutar, el medidor deja de ser solo preliminar y refleja el ultimo estado evaluado de liberacion.",
      "Si el estado final es Liberable, el medidor pasa a verde; si queda Bloqueado, muestra ese resultado aunque la configuracion preliminar pareciera prometedora."
    ),
    alcance = c(
      "El criterio formal de liberacion sigue estando en el resumen de auditoria, no en el porcentaje aislado.",
      "El medidor no implementa l-diversity ni t-closeness en este MVP."
    )
  )
}

render_privacy_meter_help_content <- function() {
  points <- privacy_meter_explanation_points()

  shiny::tags$div(
    style = "padding: 15px;",
    shiny::tags$h4("Como se calcula la estimacion preliminar"),
    shiny::tags$ul(lapply(points$preliminar, shiny::tags$li)),
    shiny::tags$h4("Que cambia despues de ejecutar"),
    shiny::tags$ul(lapply(points$evaluado, shiny::tags$li)),
    shiny::tags$h4("Alcance y limites"),
    shiny::tags$ul(lapply(points$alcance, shiny::tags$li))
  )
}

release_safe_privacy_meter_state <- function(role_state, k_value, hierarchy_count = 0, release_state = NULL, log_info = NULL) {
  role_state <- role_state %||% list()
  k <- as.numeric(k_value %||% studio_parameter_defaults()$k_value)
  if (is.na(k)) {
    k <- studio_parameter_defaults()$k_value
  }

  heuristic_score <- 10 + (k * 4)
  heuristic_score <- heuristic_score + (length(role_state$id %||% character(0)) * 5)
  heuristic_score <- heuristic_score + (length(role_state$categorical %||% character(0)) * 2)
  heuristic_score <- heuristic_score + (as.integer(hierarchy_count %||% 0) * 8)
  heuristic_score <- max(0, min(100, heuristic_score))

  state_status <- release_state$status %||% NULL
  privacy_report <- log_info$privacy_report %||% list()
  evaluated <- !is.null(privacy_report$after)

  if (evaluated && identical(state_status, "Liberable") && isTRUE(privacy_report$after$satisfied)) {
    score <- max(heuristic_score, 82)
    return(list(
      score = score,
      color_class = "meter-high",
      label = "Liberable",
      caption = "Refleja la ultima evaluacion ejecutada: el dataset quedo liberable para salida externa."
    ))
  }

  if (evaluated && identical(state_status, "Bloqueado")) {
    score <- min(heuristic_score, 39)
    return(list(
      score = score,
      color_class = if (score < 40) "meter-low" else "meter-med",
      label = "Bloqueado",
      caption = "Refleja la ultima evaluacion ejecutada: todavia faltan ajustes antes de una salida externa."
    ))
  }

  color_class <- if (heuristic_score < 40) "meter-low" else if (heuristic_score < 75) "meter-med" else "meter-high"
  label <- if (heuristic_score < 40) "Preliminar bajo" else if (heuristic_score < 75) "Preliminar medio" else "Preliminar alto"

  list(
    score = heuristic_score,
    color_class = color_class,
    label = label,
    caption = "Antes de ejecutar es una estimacion preliminar basada en k-anonymity y roles asignados."
  )
}

render_release_role_glossary <- function() {
  glossary <- release_safe_role_glossary()

  shiny::tags$div(
    class = "release-role-glossary",
    lapply(names(glossary), function(role) {
      shiny::tags$div(
        class = "release-role-glossary-item",
        render_release_role_badge(role),
        shiny::tags$span(glossary[[role]])
      )
    })
  )
}

render_release_workflow_guide <- function() {
  shiny::tags$div(
    class = "release-workflow-guide",
    shiny::tags$h4("Guia breve de trabajo"),
    shiny::tags$p(
      class = "help-text",
      "k-anonymity es un piso formal para la liberacion externa, no una garantia suficiente por si sola."
    ),
    shiny::tags$ol(lapply(release_safe_workflow_steps(), shiny::tags$li)),
    shiny::tags$h4("Roles principales"),
    render_release_role_glossary()
  )
}

render_controlled_release_help <- function() {
  shiny::tags$div(
    style = "padding: 15px;",
    shiny::tags$h4("Clasificacion y plantillas"),
    shiny::tags$ul(
      shiny::tags$li(shiny::tags$strong("Confirmar Todo:"), " aplica de una vez las sugerencias automaticas actuales sobre toda la tabla."),
      shiny::tags$li(shiny::tags$strong("Guardar Plantilla:"), " guarda la clasificacion actual para volver a usarla con datasets del mismo esquema o de uno muy parecido."),
      shiny::tags$li(shiny::tags$strong("Cargar Plantilla:"), " vuelve a aplicar la clasificacion guardada para este esquema cuando exista una plantilla compatible.")
    ),
    shiny::tags$p(class = "help-text", "Las plantillas guardan clasificacion reutilizable por estructura. No guardan el resultado ofuscado ni estados restringidos de revision.")
  )
}

format_preview_dataset <- function(df) {
  if (!is.data.frame(df) || ncol(df) == 0) {
    return(df)
  }

  out <- df
  for (col_name in names(out)) {
    column <- out[[col_name]]
    if (inherits(column, "Date")) {
      out[[col_name]] <- ifelse(is.na(column), NA_character_, format(column, "%Y-%m-%d"))
    } else if (inherits(column, c("POSIXct", "POSIXt"))) {
      out[[col_name]] <- ifelse(is.na(column), NA_character_, format(column, "%Y-%m-%d %H:%M:%S"))
    }
  }
  out
}

build_preview_mode_control <- function(has_obfuscated_data = FALSE) {
  if (isTRUE(has_obfuscated_data)) {
    return(
      shiny::tags$label(
        class = "preview-toggle preview-toggle-locked",
        shiny::tags$input(type = "checkbox", checked = "checked", disabled = "disabled"),
        shiny::tags$span("Vista del resultado ofuscado (solo 10 filas)")
      )
    )
  }

  shiny::checkboxInput("live_preview", "Vista previa de ofuscacion (solo 10 filas)", value = FALSE)
}

build_preview_notice <- function(df, release_state = NULL) {
  if (!is.data.frame(df) || nrow(df) > 0) {
    return(NULL)
  }

  status <- release_state$status %||% "Sin estado"
  message <- if (identical(status, "No liberable sin rediseno")) {
    "La configuracion actual elimina todas las filas del resultado. El artefacto final queda vacio y requiere rediseñar el criterio de liberacion."
  } else {
    "La ofuscacion actual produjo un resultado sin filas visibles."
  }

  shiny::tags$div(
    class = "preview-empty-state",
    shiny::tags$strong(sprintf("Estado: %s", status)),
    shiny::tags$p(message)
  )
}

apply_persisted_template_to_roles <- function(dataset, persisted) {
  roles <- build_default_ui_roles(dataset)

  if (is.null(persisted)) {
    return(list(
      roles = roles,
      suggested = list(),
      hierarchies = list(),
      numeric_offsets = list(),
      loaded = FALSE
    ))
  }

  for (r in names(persisted$exact %||% list())) {
    cols_to_move <- persisted$exact[[r]]
    if (length(cols_to_move) > 0) {
      for (orig_r in names(roles)) {
        roles[[orig_r]] <- setdiff(roles[[orig_r]], cols_to_move)
      }
      roles[[r]] <- unique(c(roles[[r]], cols_to_move))
    }
  }

  list(
    roles = roles,
    suggested = persisted$suggested %||% list(),
    hierarchies = persisted$hierarchies %||% list(),
    numeric_offsets = persisted$numeric_offsets %||% list(),
    loaded = TRUE
  )
}

build_template_notification <- function(hash_id, suggested_count = 0L, action = c("loaded", "saved")) {
  action <- match.arg(action)
  if (identical(action, "saved")) {
    return(sprintf("Plantilla de clasificacion guardada para el esquema actual (%s).", hash_id))
  }

  if (suggested_count > 0) {
    return(sprintf("Se cargo una plantilla compatible para el esquema actual (%s), con %d sugerencia(s) por coincidencia aproximada.", hash_id, suggested_count))
  }

  sprintf("Se cargo una plantilla compatible para el esquema actual (%s).", hash_id)
}

render_audit_log_dump <- function(log_info) {
  if (is.null(log_info)) {
    return("No hay log de auditoria disponible todavia.")
  }

  paste(capture.output(dput(log_info)), collapse = "\n")
}

release_safe_role_from_state <- function(var_name, role_state, suggested_roles = list()) {
  if (!is.null(role_state[[var_name]]) && is.list(role_state[[var_name]]) && !is.null(role_state[[var_name]]$role)) {
    return(toupper(role_state[[var_name]]$role))
  }

  legacy_role_map <- c(
    id = "ID",
    date = "QI",
    categorical = "QI",
    numeric = "QI",
    sensitive = "SENS",
    private = "PRIV",
    preserve = "KEEP",
    exclude = "EXC"
  )

  for (legacy_role in names(legacy_role_map)) {
    if (var_name %in% (role_state[[legacy_role]] %||% character(0))) {
      return(legacy_role_map[[legacy_role]])
    }
  }

  suggestion <- suggested_roles[[var_name]] %||% list()
  toupper(suggestion$role %||% "KEEP")
}

release_safe_variable_type_label <- function(column_data, role = NULL) {
  if (inherits(column_data, c("Date", "POSIXct", "POSIXt"))) {
    return("Fecha")
  }

  if (is.numeric(column_data) || is.integer(column_data)) {
    return("Numerica")
  }

  if (is.logical(column_data)) {
    return("Categorica")
  }

  values <- as.character(column_data)
  values <- values[!is.na(values)]
  if (length(values) == 0) {
    return("Categorica")
  }

  median_chars <- stats::median(nchar(trimws(values)))
  unique_ratio <- length(unique(values)) / length(values)
  if (identical(role, "PRIV") || median_chars >= 28 || (median_chars >= 18 && unique_ratio > 0.65)) {
    return("Texto")
  }

  "Categorica"
}

release_safe_treatment_label <- function(role, type_label) {
  if (identical(role, "ID")) {
    return("Reemplazar identificador directo o excluir")
  }

  if (identical(role, "QI")) {
    if (identical(type_label, "Fecha")) {
      return("Generalizar fecha para reducir reidentificacion")
    }
    if (identical(type_label, "Numerica")) {
      return("Generalizar en rangos como cuasi-identificador")
    }
    return("Agrupar categorias o jerarquizar como cuasi-identificador")
  }

  if (identical(role, "SENS")) {
    return("Conservar con control de riesgo residual o excluir")
  }

  if (identical(role, "PRIV")) {
    return("Revision manual o exclusion por contenido expresivo")
  }

  if (identical(role, "EXC")) {
    return("Excluir de la salida final")
  }

  "Conservar en salida sin tratamiento principal"
}

release_safe_risk_label <- function(role) {
  switch(
    role,
    ID = "Critico",
    QI = "Alto",
    SENS = "Alto",
    PRIV = "Critico",
    KEEP = "Bajo",
    EXC = "Bajo",
    "Medio"
  )
}

release_safe_status_label <- function(role, suggestion_role = NULL) {
  if (identical(role, "EXC")) {
    return("OK")
  }

  if (identical(role, suggestion_role) && identical(role, "QI")) {
    return("Sugerido")
  }

  if (role %in% c("ID", "PRIV")) {
    return("Bloquea")
  }

  if (role %in% c("QI", "SENS")) {
    return("Revisar")
  }

  "OK"
}

release_safe_role_input_id <- function(var_name) {
  paste0("release_role__", gsub("[^A-Za-z0-9_]+", "_", var_name))
}

release_safe_detail_input_id <- function(var_name) {
  paste0("release_detail__", gsub("[^A-Za-z0-9_]+", "_", var_name))
}

release_safe_display_role_sets <- function(df, role_state, suggested_roles = list()) {
  if (!is.data.frame(df) || ncol(df) == 0) {
    return(list(qi = character(0), sensitive = character(0), private = character(0)))
  }

  variables <- colnames(df)
  roles_by_variable <- vapply(
    variables,
    function(var_name) release_safe_role_from_state(var_name, role_state, suggested_roles = suggested_roles),
    character(1)
  )

  list(
    qi = variables[roles_by_variable == "QI"],
    sensitive = variables[roles_by_variable == "SENS"],
    private = variables[roles_by_variable == "PRIV"]
  )
}

release_safe_role_to_legacy_bucket <- function(df, var_name, role) {
  normalized_role <- toupper(role %||% "")
  column_data <- df[[var_name]]

  switch(
    normalized_role,
    ID = "id",
    QI = if (inherits(column_data, c("Date", "POSIXct", "POSIXt"))) {
      "date"
    } else if (is.numeric(column_data) || is.integer(column_data)) {
      "numeric"
    } else {
      "categorical"
    },
    SENS = "sensitive",
    PRIV = "private",
    KEEP = "preserve",
    EXC = "exclude",
    stop(sprintf("Rol release-safe no soportado: %s", normalized_role))
  )
}

apply_release_safe_role_change <- function(df, role_state, var_name, new_role) {
  if (!is.data.frame(df) || !(var_name %in% colnames(df))) {
    return(role_state)
  }

  normalized_role <- toupper(trimws(new_role %||% ""))
  if (!(normalized_role %in% release_safe_allowed_roles())) {
    stop(sprintf("Rol release-safe invalido: %s", normalized_role))
  }

  updated_roles <- role_state
  managed_slots <- c("available", "id", "date", "categorical", "numeric", "sensitive", "private", "preserve", "exclude")
  for (slot in managed_slots) {
    updated_roles[[slot]] <- setdiff(updated_roles[[slot]] %||% character(0), var_name)
  }

  target_slot <- release_safe_role_to_legacy_bucket(df, var_name, normalized_role)
  updated_roles[[target_slot]] <- unique(c(updated_roles[[target_slot]] %||% character(0), var_name))

  assigned <- unique(unlist(updated_roles[setdiff(managed_slots, "available")], use.names = FALSE))
  updated_roles$available <- setdiff(colnames(df), assigned)
  updated_roles
}

build_release_variable_rows <- function(df, role_state, suggested_roles = list(), search_term = NULL) {
  if (!is.data.frame(df) || ncol(df) == 0) {
    return(list())
  }

  variables <- colnames(df)
  if (nzchar(search_term %||% "")) {
    pattern <- tolower(search_term)
    variables <- variables[grepl(pattern, tolower(variables), fixed = TRUE)]
  }

  lapply(variables, function(var_name) {
    role <- release_safe_role_from_state(var_name, role_state, suggested_roles)
    suggestion_role <- toupper((suggested_roles[[var_name]] %||% list())$role %||% role)
    type_label <- release_safe_variable_type_label(df[[var_name]], role = role)

    list(
      variable = var_name,
      type = type_label,
      role = role,
      treatment = release_safe_treatment_label(role, type_label),
      risk = release_safe_risk_label(role),
      status = release_safe_status_label(role, suggestion_role),
      action_label = "Ver detalle"
    )
  })
}

render_release_role_badge <- function(role) {
  shiny::tags$span(
    class = sprintf("release-role-badge release-role-%s", tolower(role)),
    title = release_safe_role_definition(role),
    role
  )
}

render_release_role_control <- function(var_name, selected_role) {
  options <- lapply(release_safe_allowed_roles(), function(role) {
    shiny::tags$option(
      value = role,
      selected = if (identical(role, selected_role)) "selected" else NULL,
      role
    )
  })

  shiny::tags$div(
    class = "release-role-control",
    render_release_role_badge(selected_role),
    shiny::tags$select(
      id = release_safe_role_input_id(var_name),
      class = "release-role-select",
      `aria-label` = sprintf("Rol principal para %s", var_name),
      options
    )
  )
}

render_release_signal_badge <- function(value, kind = c("risk", "status")) {
  kind <- match.arg(kind)
  normalized <- tolower(gsub("[^a-z0-9]+", "-", value))
  shiny::tags$span(
    class = sprintf("release-signal-badge %s-badge %s-%s", kind, kind, normalized),
    value
  )
}

render_release_variable_table <- function(df, role_state, suggested_roles = list(), search_term = NULL) {
  rows <- build_release_variable_rows(
    df,
    role_state = role_state,
    suggested_roles = suggested_roles,
    search_term = search_term
  )

  if (length(rows) == 0) {
    return(shiny::tags$p(class = "release-variable-empty", "Carga un dataset para revisar variables en la tabla principal."))
  }

  header_labels <- c("Variable", "Tipo", "Rol", "Tratamiento", "Riesgo", "Estado", "Accion")
  body_rows <- lapply(rows, function(row) {
    shiny::tags$tr(
      shiny::tags$td(class = "release-col-variable", shiny::tags$strong(row$variable)),
      shiny::tags$td(row$type),
      shiny::tags$td(render_release_role_control(row$variable, row$role)),
      shiny::tags$td(class = "release-col-treatment", row$treatment),
      shiny::tags$td(render_release_signal_badge(row$risk, "risk")),
      shiny::tags$td(render_release_signal_badge(row$status, "status")),
      shiny::tags$td(
        shiny::actionButton(
          inputId = release_safe_detail_input_id(row$variable),
          class = "btn btn-default action-button btn-sm secondary-btn release-table-action",
          row$action_label
        )
      )
    )
  })

  shiny::tags$div(
    class = "release-variable-table-shell",
    shiny::tags$div(
      class = "release-variable-table-wrapper",
      shiny::tags$table(
        class = "release-variable-table",
        shiny::tags$thead(
          shiny::tags$tr(lapply(header_labels, shiny::tags$th))
        ),
        shiny::tags$tbody(body_rows)
      )
    )
  )
}

render_release_variable_table_for_test <- function(df) {
  render_release_variable_table(
    df,
    role_state = build_default_ui_roles(df),
    suggested_roles = suggest_release_safe_roles(df)
  )
}

release_safe_sample_values <- function(column_data, max_n = 3) {
  values <- unique(as.character(column_data))
  values <- values[!is.na(values) & nzchar(trimws(values))]
  if (length(values) == 0) {
    return("Sin valores de ejemplo disponibles.")
  }

  sample_values <- utils::head(values, max_n)
  paste(sample_values, collapse = " | ")
}

release_safe_treatment_choices <- function(role, type_label) {
  if (identical(role, "ID")) {
    return(c("Mapa deterministico", "Excluir"))
  }

  if (identical(role, "QI")) {
    if (identical(type_label, "Fecha")) {
      return(c("Mes", "Trimestre", "Anio"))
    }
    if (identical(type_label, "Numerica")) {
      return(c("Rango fino", "Rango amplio", "Decil"))
    }
    return(c("Valor original", "Agrupar raras", "Jerarquia"))
  }

  if (identical(role, "SENS")) {
    return(c("Conservar con control", "Revision manual", "Excluir"))
  }

  if (identical(role, "PRIV")) {
    return(c("Bloquear", "Revision manual", "Excluir"))
  }

  if (identical(role, "EXC")) {
    return("Excluir de la salida")
  }

  c("Conservar", "Revisar si aporta a la salida")
}

release_safe_impact_text <- function(role) {
  if (identical(role, "ID")) {
    return("No debe salir como identificador directo. Bloquea la liberacion hasta reemplazarlo o excluirlo y no participa como QI valido para k-anonymity.")
  }

  if (identical(role, "QI")) {
    return("Participa en k-anonymity como quasi-identificador. Puede exigir generalizacion adicional y deja la variable en revision hasta confirmar que la combinacion no reidentifica.")
  }

  if (identical(role, "SENS")) {
    return("No entra automaticamente a k-anonymity, pero requiere revision por riesgo residual. Puede bloquear la salida si el contenido sensible queda demasiado expuesto.")
  }

  if (identical(role, "PRIV")) {
    return("No entra automaticamente a k-anonymity y suele bloquear la liberacion hasta completar revision manual o exclusion por contenido expresivo.")
  }

  if (identical(role, "EXC")) {
    return("Queda fuera de la salida final. No participa en k-anonymity y no agrega bloqueo si realmente se excluye.")
  }

  "No participa como quasi-identificador principal. Aun asi conviene revisar si aporta contexto que pueda requerir ajuste manual."
}

release_safe_help_text <- function(var_name, role, suggestion_reason) {
  role_explanation <- switch(
    role,
    ID = "Se interpreta como identificador directo.",
    QI = "Se interpreta como variable que puede identificar por combinacion.",
    SENS = "Se interpreta como variable sensible.",
    PRIV = "Se interpreta como informacion privada o texto libre.",
    KEEP = "Se interpreta como variable conservable.",
    EXC = "Se interpreta como variable para excluir.",
    "Requiere revision manual."
  )

  paste(
    role_explanation,
    sprintf("Se sugirio asi para `%s` porque %s.", var_name, tolower(suggestion_reason %||% "requiere revision contextual")),
    "Usa esta ficha para entender el riesgo antes de liberar."
  )
}

build_release_variable_detail <- function(df, var_name, role_state, suggested_roles = list()) {
  if (!is.data.frame(df) || !(var_name %in% colnames(df))) {
    return(NULL)
  }

  role <- release_safe_role_from_state(var_name, role_state, suggested_roles)
  type_label <- release_safe_variable_type_label(df[[var_name]], role = role)
  suggestion <- suggested_roles[[var_name]] %||% list()
  suggestion_role <- toupper(suggestion$role %||% role)
  suggestion_reason <- suggestion$reason %||% "no hubo una sugerencia automatica fuerte"
  sample_values <- release_safe_sample_values(df[[var_name]])

  list(
    variable = var_name,
    type = type_label,
    role = role,
    summary = sprintf(
      "Tipo detectado: %s. Valores de ejemplo: %s. Sugerencia automatica: %s.",
      type_label,
      sample_values,
      suggestion_role
    ),
    treatment = release_safe_treatment_label(role, type_label),
    treatment_choices = release_safe_treatment_choices(role, type_label),
    impact = release_safe_impact_text(role),
    help = release_safe_help_text(var_name, role, suggestion_reason),
    suggestion_reason = suggestion_reason
  )
}

render_release_detail_block <- function(title, content, extra_class = NULL) {
  shiny::tags$section(
    class = paste("release-detail-block", extra_class %||% ""),
    shiny::tags$h4(title),
    content
  )
}

render_release_variable_detail_panel <- function(df, selected_var, role_state, suggested_roles = list()) {
  if (!is.data.frame(df) || ncol(df) == 0) {
    return(shiny::tags$div(
      class = "release-variable-detail release-variable-detail-empty",
      shiny::tags$h3("Ficha por variable"),
      shiny::tags$p("Carga un dataset para abrir una ficha de detalle por variable.")
    ))
  }

  if (is.null(selected_var) || !nzchar(selected_var) || !(selected_var %in% colnames(df))) {
    return(shiny::tags$div(
      class = "release-variable-detail release-variable-detail-empty",
      shiny::tags$h3("Ficha por variable"),
      shiny::tags$p("Usa el boton Ver detalle de la tabla principal para abrir el detalle de una variable.")
    ))
  }

  detail <- build_release_variable_detail(df, selected_var, role_state, suggested_roles)
  if (is.null(detail)) {
    return(NULL)
  }

  shiny::tags$aside(
    class = "release-variable-detail",
    shiny::tags$div(
      class = "release-variable-detail-header",
      shiny::tags$div(
        shiny::tags$h3(detail$variable),
        shiny::tags$p(sprintf("Tipo: %s", detail$type))
      ),
      render_release_role_badge(detail$role)
    ),
    render_release_detail_block(
      "Resumen",
      shiny::tagList(
        shiny::tags$p(detail$summary),
        shiny::tags$p(
          class = "help-text",
          sprintf("Motivo de sugerencia: %s", detail$suggestion_reason)
        )
      )
    ),
    render_release_detail_block(
      "Rol principal",
      shiny::tagList(
        shiny::tags$p(sprintf("Rol actual: %s", detail$role)),
        shiny::tags$p(release_safe_role_definition(detail$role)),
        shiny::tags$p(class = "help-text", "Si quieres cambiar este rol, hazlo desde el selector de la tabla principal.")
      )
    ),
    render_release_detail_block(
      "Tratamiento tecnico",
      shiny::tagList(
        shiny::tags$p(detail$treatment),
        shiny::tags$ul(lapply(detail$treatment_choices, shiny::tags$li))
      )
    ),
    render_release_detail_block(
      "Impacto",
      shiny::tagList(
        shiny::tags$p(detail$impact),
        render_release_signal_badge(release_safe_risk_label(detail$role), "risk"),
        render_release_signal_badge(release_safe_status_label(detail$role, toupper((suggested_roles[[selected_var]] %||% list())$role %||% detail$role)), "status")
      )
    ),
    render_release_detail_block(
      "Ayuda",
      shiny::tagList(
        shiny::tags$p(detail$help),
        shiny::tags$p(class = "help-text", "Usa esta ficha para interpretar el riesgo y decidir si la variable puede participar en una liberacion controlada.")
      )
    )
  )
}

render_release_variable_detail_panel_for_test <- function(df, selected_var) {
  render_release_variable_detail_panel(
    df,
    selected_var = selected_var,
    role_state = build_default_ui_roles(df),
    suggested_roles = suggest_release_safe_roles(df)
  )
}

render_release_workflow_guide_for_test <- function() {
  render_release_workflow_guide()
}

build_download_button_control <- function(state) {
  if (can_export_external_release(state)) {
    return(shiny::downloadButton("download_csv", "Descargar CSV"))
  }

  shiny::actionButton("download_blocked", "Descargar CSV (bloqueado)", class = "secondary-btn")
}

detect_suspicious_date_character_columns <- function(df) {
  if (!is.data.frame(df) || ncol(df) == 0) {
    return(character(0))
  }

  is_date_like_name <- function(x) {
    normalized <- toupper(trimws(x))
    grepl("(^FECHA($|_))|(^FEC($|_))|(_FECHA($|_))|(^DATE($|_))|(_DATE($|_))", normalized)
  }

  is_date_prefix <- function(x) {
    grepl(
      "^(\\d{4}[-/.]\\d{2}[-/.]\\d{2}|\\d{2}[-/.]\\d{2}[-/.]\\d{4})$",
      x
    )
  }

  suspicious <- vapply(names(df), function(col_name) {
    column <- df[[col_name]]
    if (!is.character(column)) {
      return(FALSE)
    }

    name_looks_like_date <- is_date_like_name(col_name)
    non_na <- column[!is.na(column) & nzchar(trimws(column))]
    if (length(non_na) == 0) {
      return(name_looks_like_date)
    }

    sample_values <- head(trimws(non_na), 50)
    first_ten <- substr(sample_values, 1, 10)
    fully_date_like_text <- mean(is_date_prefix(first_ten), na.rm = TRUE) >= 0.6
    has_date_prefix_with_extra <- any(
      nchar(sample_values) > 10 & is_date_prefix(first_ten)
    )

    name_looks_like_date || has_date_prefix_with_extra || fully_date_like_text
  }, logical(1))

  names(df)[suspicious]
}

load_dataset_for_app <- function(source_mode, file_info = NULL, object_name = NULL) {
  if (identical(source_mode, "file")) {
    if (is.null(file_info)) {
      stop("Debes cargar un archivo para continuar.")
    }

    extension <- tolower(tools::file_ext(file_info$name %||% file_info$datapath))
    if (extension == "csv") {
      return(readr::read_csv(
        file_info$datapath,
        show_col_types = FALSE,
        guess_max = 100000
      ))
    }
    if (extension %in% c("xls", "xlsx")) {
      return(readxl::read_excel(file_info$datapath, guess_max = 100000))
    }
    if (extension == "rds") {
      obj <- readRDS(file_info$datapath)
      if (!is.data.frame(obj)) {
        stop("El archivo RDS no contiene un data.frame o tibble.")
      }
      return(obj)
    }

    stop("Formato no soportado. Usa CSV, XLS, XLSX o RDS.")
  }

  if (identical(source_mode, "environment")) {
    if (is.null(object_name) || !nzchar(object_name)) {
      stop("Debes seleccionar un objeto del entorno.")
    }
    if (!exists(object_name, envir = .GlobalEnv, inherits = FALSE)) {
      stop("El objeto seleccionado no existe en el entorno global.")
    }

    obj <- get(object_name, envir = .GlobalEnv, inherits = FALSE)
    if (!is.data.frame(obj)) {
      stop("El objeto seleccionado no es un data.frame o tibble.")
    }
    return(obj)
  }

  stop("Modo de carga no soportado.")
}

studio_parameter_defaults <- function() {
  list(
    seed = 123,
    id_prefix = "999",
    project_key = NULL,
    numeric_mode = "range_random",
    k_value = 5,
    k_suppression = "rows",
    group_ids = FALSE,
    enable_k = TRUE
  )
}

resolve_dataset_display_name <- function(source_mode, object_name = NULL, file_name = NULL) {
  if (identical(source_mode, "environment") && nzchar(object_name %||% "")) {
    return(object_name)
  }

  if (identical(source_mode, "file") && nzchar(file_name %||% "")) {
    return(file_name)
  }

  "Ninguno"
}

build_demo_personas_dataset <- function() {
  n <- 20L
  data.frame(
    persona_id = sprintf("P%03d", seq_len(n)),
    fecha_alta = as.Date("2024-01-01") + seq(0, by = 14, length.out = n),
    tramo = rep(c("A", "B", "C", "D"), length.out = n),
    departamento = rep(c("Montevideo", "Canelones", "Maldonado", "Salto", "Paysandu"), length.out = n),
    edad = c(23, 24, 25, 31, 32, 33, 40, 41, 42, 50, 51, 52, 60, 61, 62, 28, 29, 30, 45, 46),
    ingreso = round(seq(18000, 56000, length.out = n), 0),
    indicador_privado = rep(c("alto", "medio", "bajo", "medio"), length.out = n),
    observacion = c(
      "Seguimiento local con notas internas",
      "Caso derivado con informacion sensible",
      "Revision manual requerida por texto libre",
      "Observacion administrativa extendida",
      "Seguimiento local con notas internas",
      "Caso derivado con informacion sensible",
      "Revision manual requerida por texto libre",
      "Observacion administrativa extendida",
      "Seguimiento local con notas internas",
      "Caso derivado con informacion sensible",
      "Revision manual requerida por texto libre",
      "Observacion administrativa extendida",
      "Seguimiento local con notas internas",
      "Caso derivado con informacion sensible",
      "Revision manual requerida por texto libre",
      "Observacion administrativa extendida",
      "Seguimiento local con notas internas",
      "Caso derivado con informacion sensible",
      "Revision manual requerida por texto libre",
      "Observacion administrativa extendida"
    ),
    stringsAsFactors = FALSE
  )
}

studio_demo_datasets <- function() {
  list(
    iris = datasets::iris,
    mtcars = datasets::mtcars,
    airquality = datasets::airquality,
    obfuscator_demo_personas = build_demo_personas_dataset(),
    obfuscator_demo_bloqueado = data.frame(
      persona_id = c("X001", "X002", "X003", "X004"),
      fecha_alta = as.Date(c("2024-01-03", "2024-02-11", "2024-03-19", "2024-04-27")),
      localidad = c("A", "B", "C", "D"),
      edad = c(19, 47, 73, 91),
      stringsAsFactors = FALSE
    )
  )
}

ensure_studio_demo_datasets <- function(target_env = .GlobalEnv) {
  demo_sets <- studio_demo_datasets()
  for (nm in names(demo_sets)) {
    if (!exists(nm, envir = target_env, inherits = FALSE)) {
      assign(nm, demo_sets[[nm]], envir = target_env)
    }
  }
  invisible(names(demo_sets))
}

build_obfuscation_code_snippet <- function(
  data_reference,
  seed,
  id_prefix,
  numeric_mode,
  project_key = NULL,
  col_roles = list(),
  numeric_offsets = list(),
  hierarchies = list(),
  exclude_cols = character(0),
  privacy_model = NULL
) {
  col_roles_str <- if (length(col_roles) > 0) {
    lines <- vapply(names(col_roles), function(role_name) {
      sprintf(
        "    %s = c(%s)",
        role_name,
        paste0(sprintf("'%s'", col_roles[[role_name]]), collapse = ", ")
      )
    }, character(1))
    sprintf("list(\n%s\n  )", paste(lines, collapse = ",\n"))
  } else {
    "list()"
  }

  offsets_str <- if (length(numeric_offsets) > 0) {
    lines <- vapply(names(numeric_offsets), function(variable) {
      sprintf("    '%s' = 0, # [INGRESE_CLAVE_PARA_%s]", variable, toupper(variable))
    }, character(1))
    sprintf("list(\n%s\n  )", paste(lines, collapse = ",\n"))
  } else {
    "list()"
  }

  has_hierarchies <- length(hierarchies) > 0 || length(privacy_model$hierarchies %||% list()) > 0
  hierarchies_str <- if (has_hierarchies) "hierarchies_obj" else "NULL"

  privacy_model_str <- if (is.null(privacy_model)) {
    "NULL"
  } else {
    quasi_identifiers <- privacy_model$quasi_identifiers %||% character(0)
    suppression <- privacy_model$suppression %||% "rows"
    group_ids <- isTRUE(privacy_model$group_ids)
    sprintf(
      paste(
        "list(",
        "type = 'k_anonymity',",
        "k = %s,",
        "quasi_identifiers = c(%s),",
        "suppression = '%s',",
        "group_ids = %s,",
        "hierarchies = %s",
        ")"
      ),
      privacy_model$k,
      paste0(sprintf("'%s'", quasi_identifiers), collapse = ", "),
      suppression,
      if (group_ids) "TRUE" else "FALSE",
      hierarchies_str
    )
  }

  exclude_cols_str <- if (length(exclude_cols) > 0) {
    paste0("c(", paste0(sprintf("'%s'", exclude_cols), collapse = ", "), ")")
  } else {
    "character(0)"
  }

  sprintf(
"library(obfuscator)

# 1. Cargar datos
df <- %s # REEMPLAZAR con el comando de carga (p. ej. read.csv('archivo.csv'))

# Nota importante:
# Este script reproduce transformaciones internas, pero NO implica que el dataset sea liberable hacia terceros.
# La decision de liberacion externa requiere revisar el reporte de privacidad y el estado de release por separado.

# 2. Configurar ofuscacion
config <- obfuscator_config(
  seed = %s,
  id_prefix = '%s',
  numeric_mode = '%s',
  project_key = %s,
  col_roles = %s,
  numeric_offsets = %s,
  exclude_cols = %s,
  privacy_model = %s
)

# Si usas jerarquias, define `hierarchies_obj` antes de ejecutar la configuracion.

# 3. Ejecutar
resultado <- obfuscate_dataset(df, config = config)

# Ver resultado
head(resultado)",
    data_reference,
    seed,
    id_prefix,
    numeric_mode,
    if (nchar(project_key %||% "") > 0) sprintf("'%s'", project_key) else "NULL",
    col_roles_str,
    offsets_str,
    exclude_cols_str,
    privacy_model_str
  )
}

role_column_choices <- function(df, ui_roles) {
  list(
    id = intersect(ui_roles$id %||% character(0), colnames(df)),
    date = intersect(ui_roles$date %||% character(0), colnames(df)),
    categorical = intersect(ui_roles$categorical %||% character(0), colnames(df)),
    numeric = intersect(ui_roles$numeric %||% character(0), colnames(df)),
    preserve = intersect(ui_roles$preserve %||% character(0), colnames(df))
  )
}

build_persistable_role_template <- function(
  role_state,
  hierarchies = list(),
  numeric_offsets = list(),
  release_state = NULL,
  manual_review = NULL,
  artifact = NULL
) {
  persisted_roles <- list(
    id = unique(role_state$id %||% character(0)),
    qi = unique(c(
      role_state$qi %||% character(0),
      role_state$date %||% character(0),
      role_state$categorical %||% character(0),
      role_state$numeric %||% character(0)
    )),
    sens = unique(c(
      role_state$sens %||% character(0),
      role_state$sensitive %||% character(0)
    )),
    priv = unique(c(
      role_state$priv %||% character(0),
      role_state$private %||% character(0)
    )),
    keep = unique(c(
      role_state$keep %||% character(0),
      role_state$preserve %||% character(0)
    )),
    exc = unique(c(
      role_state$exc %||% character(0),
      role_state$exclude %||% character(0)
    ))
  )
  persisted_roles <- Filter(function(x) length(x) > 0, persisted_roles)

  if (length(hierarchies) > 0) {
    persisted_roles$hierarchies <- hierarchies
  }

  # Only schema-bound classification data is persisted in ordinary templates.
  # We intentionally do not persist:
  # - `available`, because it is derived from the current dataset schema.
  # - `numeric_offsets`, because they are manual secret keys.
  # - `release_state`, `manual_review`, and `artifact`, because they belong to
  #   restricted release/review workflow state rather than reusable templates.
  invisible(numeric_offsets)
  invisible(release_state)
  invisible(manual_review)
  invisible(artifact)

  persisted_roles
}

build_release_parameters_card <- function() {
  defaults <- studio_parameter_defaults()

  shiny::tags$div(
    class = "panel-card",
    shiny::tags$h3(studio_icon("settings", "Parametros"), " Parametros"),
    shiny::numericInput("seed", "Semilla", value = defaults$seed, min = 1),
    shiny::checkboxInput("enable_k", "Activar k-anonymity", value = isTRUE(defaults$enable_k)),
    shiny::conditionalPanel(
      "input.enable_k === true",
      shiny::numericInput("k_value", "Valor de k", value = defaults$k_value, min = 2, step = 1),
      shiny::radioButtons(
        "k_suppression",
        "Supresion residual",
        choices = c(
          "Eliminar filas" = "rows",
          "Agrupar categorias residuales" = "group",
          "Conservar sin anonimizar" = "none"
        ),
        selected = defaults$k_suppression
      ),
      shiny::checkboxInput("group_ids", "Agrupar IDs por k-clases", value = defaults$group_ids),
      shiny::tags$div(
        class = "help-text",
        style = "margin-top: -10px; margin-bottom: 10px;",
        shiny::tags$em("Tip: Si 'k' es alto y no ves datos, prueba 'Agrupar categorias residuales' o usa jerarquias para reducir la diversidad de los quasi-identificadores.")
      )
    ),
    shiny::tags$details(
      class = "advanced-options",
      shiny::tags$summary("Opciones Avanzadas (clic para abrir)"),
      shiny::tags$br(),
      shiny::textInput("id_prefix", "Prefijo para IDs", value = defaults$id_prefix),
      shiny::passwordInput("project_key", "Llave del Proyecto (Opcional)", placeholder = "Sincroniza multiples archivos"),
      shiny::selectInput(
        "numeric_mode",
        "Modo numerico general",
        choices = c(
          "Rango Aleatorio" = "range_random",
          "Preservar rango" = "preserve_rank",
          "Permutacion" = "permute"
        ),
        selected = defaults$numeric_mode,
        selectize = FALSE
      )
    ),
    shiny::actionButton("run_obfuscation", "Ofuscar dataset", class = "primary-btn")
  )
}

build_obfuscator_app_ui <- function(asset_version) {
  shiny::fluidPage(
    shiny::tags$head(
      shiny::tags$link(
        rel = "stylesheet",
        type = "text/css",
        href = sprintf("obfuscator-www/app.css?v=%s", asset_version)
      ),
      shiny::tags$script(src = sprintf("obfuscator-www/app.js?v=%s", asset_version))
    ),
    shiny::tags$div(
      class = "app-shell",
      shiny::tags$div(
        class = "hero",
        shiny::tags$div(
          class = "hero-copy",
          shiny::tags$h1("ObfuscatoR Studio"),
          shiny::tags$p("Interfaz grafica para revisar, clasificar y ofuscar datos con apoyo visual y auditoria.")
        ),
        shiny::tags$div(
          class = "hero-meta",
          shiny::tags$button(
            id = "theme-toggle",
            class = "hero-chip theme-btn",
            onclick = "toggleTheme()",
            title = "Cambiar Tema (Claro/Oscuro)",
            studio_icon("theme", "Tema"),
            shiny::tags$span(class = "theme-label", "CL")
          ),
          shiny::tags$button(
            id = "open_help",
            class = "hero-chip help-btn",
            onclick = "Shiny.setInputValue('show_help', Math.random(), {priority: 'event'})",
            title = "Manual y Ayuda de Studio",
            studio_icon("help", "Ayuda")
          ),
          shiny::uiOutput("hero_chips_ui", inline = TRUE)
        )
      ),
      shiny::fluidRow(
        shiny::column(
          width = 4,
          shiny::tags$div(
            class = "panel-card",
            shiny::tags$h3("Fuente de datos"),
            shiny::radioButtons(
              "source_mode",
              NULL,
              choices = c("Archivo" = "file", "Entorno global" = "environment"),
              inline = TRUE
            ),
            shiny::conditionalPanel(
              "input.source_mode === 'file'",
              shiny::fileInput("input_file", "Cargar CSV, Excel o RDS", accept = c(".csv", ".xls", ".xlsx", ".rds"))
            ),
            shiny::tags$div(
              class = "help-text",
              "Tamano maximo de carga configurado en esta app: 300 MB. Para archivos aun mayores, conviene usar un objeto del entorno global."
            ),
            shiny::conditionalPanel(
              "input.source_mode === 'environment'",
              shiny::selectInput("env_object", "Objeto del entorno", choices = character(0))
            ),
            shiny::actionButton("load_data", "Cargar dataset", class = "primary-btn"),
            shiny::tags$div(class = "help-text", "Si eliges un objeto del entorno, debe ser un data.frame o tibble.")
          ),
          shiny::tags$aside(
            class = "sidebar",
            shiny::tags$div(
              class = "panel-card privacy-meter-container",
              shiny::tags$div(
                class = "section-header",
                shiny::tags$h3(studio_icon("privacy", "Privacidad"), " Nivel de Privacidad"),
                shiny::actionButton("show_privacy_meter_help", "?", class = "help-btn inline-help-btn", title = "Como se calcula esta estimacion")
              ),
              shiny::uiOutput("privacy_meter_ui"),
              shiny::tags$p(class = "help-text", "Antes de ejecutar funciona como una estimacion preliminar. Despues refleja la ultima evaluacion de liberacion.")
            ),
            build_release_parameters_card()
          ),
          shiny::tags$div(
            class = "panel-card",
            shiny::tags$h3("Salida"),
            shiny::textInput("output_object_name", "Guardar objeto en entorno como", value = "dataset_ofuscado"),
            shiny::tags$div(
              class = "btn-group-custom",
              shiny::actionButton("save_to_env", "Guardar en entorno (uso interno)"),
              shiny::actionButton("revert_btn", "Revertir actual", class = "secondary-btn")
            ),
            shiny::tags$div(
              class = "btn-group-custom",
              style = "margin-top: 10px;",
              shiny::uiOutput("download_button_ui", inline = TRUE),
              shiny::actionButton("view_r_code", shiny::tagList(studio_icon("code", "Codigo R"), " Ver Codigo R"))
            )
          )
        ),
        shiny::column(
          width = 8,
          shiny::tags$div(
            class = "panel-card",
            shiny::tags$h3("Estado del dataset"),
            shiny::uiOutput("dataset_summary_ui")
          ),
          shiny::tags$div(
            class = "panel-card",
            shiny::tags$h3("Clasificacion para liberacion"),
            shiny::uiOutput("release_role_summary_ui")
          ),
          shiny::tags$div(
            class = "panel-card",
            shiny::uiOutput("release_workflow_guide_ui")
          ),
          shiny::tags$div(
            class = "panel-card",
            shiny::tags$div(
              class = "section-header",
              shiny::tags$div(
                shiny::tags$h3("Tabla principal por variable"),
                shiny::tags$p("Vista principal por variable para liberacion controlada. Este es el mecanismo principal de clasificacion.")
              )
            ),
            shiny::tags$div(
              class = "release-workbench",
              shiny::tags$div(
                class = "release-primary-actions",
                shiny::actionButton("confirm_suggestions", shiny::tagList(studio_icon("check", "Confirmar"), " Confirmar Todo"), class = "btn-sm"),
                shiny::actionButton("save_template", shiny::tagList(studio_icon("save", "Guardar"), " Guardar Plantilla"), class = "btn-sm"),
                shiny::actionButton("load_template", shiny::tagList(studio_icon("open", "Cargar"), " Cargar Plantilla"), class = "btn-sm"),
                shiny::actionButton("show_template_help", "?", class = "help-btn inline-help-btn", title = "Como funciona este modulo")
              ),
              shiny::uiOutput("release_variable_table_ui"),
              shiny::uiOutput("release_variable_detail_ui")
            ),
            shiny::tags$details(
              class = "legacy-role-board legacy-role-board-details",
              shiny::tags$summary("Modo heredado de arrastre (experimental)"),
              shiny::tags$div(
                class = "legacy-role-board-intro",
                shiny::tags$p("Este modo ya no es la clasificacion principal. Usalo solo si necesitas apoyar o corregir la transicion desde el esquema anterior.")
              ),
              shiny::tags$div(
                class = "section-header legacy-role-board-header",
                shiny::tags$div(
                  shiny::tags$h4("Tablero heredado"),
                  shiny::tags$p("La tabla principal y la ficha lateral son ahora el camino preferido para clasificar.")
                ),
                shiny::tags$div(
                  class = "search-wrapper",
                  shiny::tags$div(
                    class = "btn-group-custom",
                    shiny::tags$span(class = "help-text", "Las plantillas ahora se gestionan desde la interfaz principal.")
                  ),
                  shiny::textInput("var_search", NULL, placeholder = "Filtrar por nombre...", width = "200px")
                )
              ),
              shiny::uiOutput("role_board_ui")
            )
          ),
          shiny::tags$div(
            class = "panel-card",
            shiny::tags$div(
              class = "section-header",
              shiny::tags$h3("Vista previa"),
              shiny::uiOutput("preview_mode_ui")
            ),
            shiny::uiOutput("preview_notice_ui"),
            shiny::tags$div(
              class = "preview-table-wrapper",
              shiny::tableOutput("preview_table")
            )
          ),
          shiny::tags$div(
            class = "panel-card",
            shiny::tags$div(
              class = "section-header",
              shiny::tags$h3("Resumen de auditoria"),
              shiny::actionButton("show_audit_log", "Ver log tecnico", class = "btn-sm")
            ),
            shiny::verbatimTextOutput("audit_log_text")
          )
        )
      )
    )
  )
}

run_obfuscator_app_ui_for_test <- function() {
  build_obfuscator_app_ui(asset_version = "test")
}

studio_icon <- function(name, label = NULL, extra_class = NULL) {
  glyphs <- c(
    chart = "D",
    hierarchy = "J",
    key = "R",
    theme = "T",
    help = "?",
    privacy = "k",
    settings = "=",
    code = "R",
    check = "OK",
    save = "G",
    open = "C",
    add = "+",
    folder = "G",
    dataset = "DB",
    rows = "#",
    shield = "k",
    copy = "CP"
  )

  glyph <- glyphs[[name]] %||% toupper(substr(name, 1, 2))
  title_text <- label %||% name

  shiny::tags$span(
    class = paste("studio-icon", paste0("studio-icon-", name), extra_class %||% ""),
    title = title_text,
    `aria-label` = title_text,
    glyph
  )
}

render_role_zone_ui <- function(title, role_name, variables, warning_vars = character(0), suggested_vars = list(), active_hierarchies = character(0), active_offsets = character(0), numeric_cols = character(0), accent_class = "accent-slate") {
  index_width <- if (length(variables) > 99) 3 else 2

  shiny::tags$div(
    class = paste("role-zone", accent_class),
    `data-role` = role_name,
    shiny::tags$div(class = "role-zone-header", sprintf("%s (%s)", title, length(variables))),
    shiny::tags$div(
      class = "role-zone-body",
      lapply(seq_along(variables), function(idx) {
        var_name <- variables[[idx]]
        is_warning <- var_name %in% warning_vars
        # Sugerencia si esta en la lista y el rol coincide
        is_suggested <- !is.null(suggested_vars[[var_name]]) && suggested_vars[[var_name]]$role == role_name
        
        shiny::tags$div(
          class = paste("draggable-var", 
                        if (is_warning) "warning-var" else "",
                        if (is_suggested) "suggested-var" else ""),
          draggable = "true",
          `data-var-name` = var_name,
          `data-from-role` = role_name,
          title = if (is_suggested) sprintf("Sugerencia basada en '%s' (%.0f%% match)", 
                                           suggested_vars[[var_name]]$original, 
                                           suggested_vars[[var_name]]$score * 100) else NULL,
          shiny::tags$span(
            class = "var-index-badge",
            formatC(idx, width = index_width, flag = "0")
          ),
          if (is_warning) {
            shiny::tags$span(
              class = "var-warning-icon",
              title = "Posible fecha almacenada como texto",
              "!"
            )
          },
          # NUEVO: Badge de tipo
          shiny::tags$span(
            class = paste0("var-badge var-badge-", if(var_name %in% numeric_cols) "num" else "cat"),
            if(var_name %in% numeric_cols) "#" else "A"
          ),
          shiny::tags$span(
            class = "var-label",
            title = var_name,
            `data-full-label` = var_name,
            var_name
          ),
          # Nuevo: Boton para ver distribucion
          shiny::tags$button(
            class = "btn-dist-icon",
            onclick = sprintf("Shiny.setInputValue('view_distribution', '%s', {priority: 'event'})", var_name),
            title = "Ver Distribucion de Datos",
            studio_icon("chart", "Distribucion")
          ),
          # Nuevo: Boton para configurar jerarquia (solo para Categoricas, Fechas e IDs)
          if (role_name %in% c("categorical", "date", "id")) {
            has_h <- var_name %in% active_hierarchies
            shiny::tags$button(
              class = paste("btn-hierarchy-icon", if (has_h) "has-hierarchy" else ""),
              onclick = sprintf("Shiny.setInputValue('open_hierarchy_editor', '%s', {priority: 'event'})", var_name),
              title = if (has_h) "Jerarquia configurada (Click para editar)" else "Configurar Jerarquia de Anonimizacion",
              studio_icon("hierarchy", "Jerarquia")
            )
          },
          # NUEVO: Boton para Cifrado/Offset (Solo para Identificadoras que sean Numericas)
          if (role_name == "id" && var_name %in% numeric_cols) {
            has_o <- var_name %in% active_offsets
            shiny::tags$button(
              class = paste("btn-offset-icon", if (has_o) "has-offset" else ""),
              onclick = sprintf("Shiny.setInputValue('open_offset_editor', '%s', {priority: 'event'})", var_name),
              title = if (has_o) "Cifrado Reversible activo (Click para editar)" else "Configurar Cifrado por Desfase (Reversible)",
              studio_icon("key", "Reversible")
            )
          }
        )
      })
    )
  )
}

run_obfuscator_app <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("La app requiere el paquete `shiny` instalado.")
  }
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("La app requiere el paquete `ggplot2` instalado para las visualizaciones.")
  }

  options(shiny.maxRequestSize = 300 * 1024^2)

  frame_ofiles <- vapply(
    sys.frames(),
    function(frame) {
      if (is.null(frame$ofile)) "" else frame$ofile
    },
    character(1)
  )
  candidate_files <- frame_ofiles[grepl("(shiny_app|app)\\.R$", frame_ofiles)]
  base_dir <- if (length(candidate_files) > 0) {
    dirname(normalizePath(candidate_files[[length(candidate_files)]]))
  } else {
    getwd()
  }

  project_dir <- if (basename(base_dir) == "R") dirname(base_dir) else base_dir
  www_dir <- normalizePath(file.path(project_dir, "www"), winslash = "/", mustWork = FALSE)
  if (!dir.exists(www_dir)) {
    stop("No se encontro la carpeta `www` de la app Shiny.")
  }

  shiny::addResourcePath("obfuscator-www", www_dir)
  asset_version <- paste0(obfuscator_version(), "-", as.integer(Sys.time()))

  ui <- build_obfuscator_app_ui(asset_version)

  server <- function(input, output, session) {
    # Reactivos para el estado de la app
    ensure_studio_demo_datasets(.GlobalEnv)
    source_data <- shiny::reactiveVal(NULL)
    role_state <- shiny::reactiveVal(list(
      available = character(0),
      id = character(0), 
      date = character(0), 
      categorical = character(0), 
      numeric = character(0), 
      sensitive = character(0),
      private = character(0),
      preserve = character(0),
      exclude = character(0) # NUEVO: Zona de exclusion
    ))
    suggested_roles <- shiny::reactiveVal(list()) # Para fuzzy matching
    # Jerarquias (listas de listas: mapping, name)
    hierarchies <- shiny::reactiveVal(list())
    role_input_observers <- shiny::reactiveVal(list())
    detail_input_observers <- shiny::reactiveVal(list())
    selected_release_variable <- shiny::reactiveVal(NULL)
    
    # NUEVO: Offsets numericos
    numeric_offsets <- shiny::reactiveVal(list())
    
    dist_var <- shiny::reactiveVal(NULL) # Para el modal de distribucion
    obfuscated_data <- shiny::reactiveVal(NULL)
    audit_log <- shiny::reactiveVal(NULL)
    progress_status <- shiny::reactiveVal("Todavia no se ejecuto ninguna ofuscacion.")
    loaded_dataset_name <- shiny::reactiveVal("Ninguno")
    release_state <- shiny::reactiveVal(initial_release_state())

    shiny::observe({
      objects <- ls(envir = .GlobalEnv)
      object_choices <- objects[vapply(objects, function(obj_name) {
        inherits(get(obj_name, envir = .GlobalEnv), "data.frame")
      }, logical(1))]
      shiny::updateSelectInput(
        session,
        "env_object",
        choices = object_choices,
        selected = if (length(object_choices) > 0) object_choices[[1]] else ""
      )
    })

    shiny::observeEvent(input$k_value, {
      if (is.null(input$k_value) || is.na(input$k_value)) {
        return()
      }
      if (isTRUE(input$k_value < 2)) {
        shiny::updateNumericInput(session, "k_value", value = 2)
        shiny::showNotification("k-anonymity requiere un valor de k mayor o igual a 2. Se ajusto automaticamente a 2.", type = "warning")
      }
    }, ignoreInit = TRUE)

    shiny::observeEvent(input$load_data, {
      dataset <- load_dataset_for_app(
        source_mode = input$source_mode,
        file_info = input$input_file,
        object_name = input$env_object
      )
      source_data(dataset)
      loaded_dataset_name(
        resolve_dataset_display_name(
          source_mode = input$source_mode,
          object_name = input$env_object,
          file_name = input$input_file$name %||% NULL
        )
      )
      
      # Persistence: Intentar carga automatica basada en hash
      hash_id <- generate_schema_hash(dataset)
      config_path <- file.path("config", paste0(hash_id, ".json"))
      
      suggested_roles(list())
      if (file.exists(config_path)) {
        persisted <- load_roles_from_json(dataset, config_path)
        applied <- apply_persisted_template_to_roles(dataset, persisted)
        if (isTRUE(applied$loaded)) {
          role_state(applied$roles)
          suggested_roles(applied$suggested)
          hierarchies(applied$hierarchies)
          numeric_offsets(applied$numeric_offsets)
          shiny::showNotification(
            build_template_notification(hash_id, suggested_count = length(applied$suggested), action = "loaded"),
            type = "message"
          )
        } else {
          role_state(build_default_ui_roles(dataset))
        }
      } else {
        role_state(build_default_ui_roles(dataset))
      }
      
      selected_release_variable(NULL)
      obfuscated_data(NULL)
      audit_log(NULL)
      progress_status("Dataset cargado. Se busco persistencia por esquema.")
      release_state(transition_release_state(
        release_state(),
        "material_change",
        context = list(metadata = list(
          trigger = "dataset_loaded",
          dataset_name = loaded_dataset_name()
        ))
      ))
    }, ignoreNULL = TRUE)

    shiny::observeEvent(source_data(), {
      existing_observers <- role_input_observers()
      if (length(existing_observers) > 0) {
        invisible(lapply(existing_observers, function(observer_ref) {
          if (!is.null(observer_ref)) {
            observer_ref$destroy()
          }
          NULL
        }))
      }

      existing_detail_observers <- detail_input_observers()
      if (length(existing_detail_observers) > 0) {
        invisible(lapply(existing_detail_observers, function(observer_ref) {
          if (!is.null(observer_ref)) {
            observer_ref$destroy()
          }
          NULL
        }))
      }

      df <- source_data()
      shiny::req(df)

      observers <- lapply(colnames(df), function(var_name) {
        input_id <- release_safe_role_input_id(var_name)
        shiny::observeEvent(input[[input_id]], ignoreInit = TRUE, {
          updated_roles <- apply_release_safe_role_change(
            df = df,
            role_state = role_state(),
            var_name = var_name,
            new_role = input[[input_id]]
          )
          role_state(updated_roles)
        })
      })

      names(observers) <- colnames(df)
      role_input_observers(observers)

      detail_observers <- lapply(colnames(df), function(var_name) {
        input_id <- release_safe_detail_input_id(var_name)
        shiny::observeEvent(input[[input_id]], ignoreInit = TRUE, {
          selected_release_variable(var_name)
        })
      })

      names(detail_observers) <- colnames(df)
      detail_input_observers(detail_observers)
    }, ignoreNULL = TRUE)

    shiny::observeEvent(input$open_hierarchy_editor, {
      var_name <- input$open_hierarchy_editor
      df <- source_data()
      shiny::req(df, var_name)
      
      unique_vals <- unique(as.character(df[[var_name]]))
      current_h <- hierarchies()[[var_name]] %||% list()
      
      shiny::showModal(shiny::modalDialog(
        title = sprintf("Configurar Jerarquia: %s", var_name),
        size = "l",
        footer = shiny::tagList(
          shiny::modalButton("Cancelar"),
          shiny::actionButton("save_hierarchy", "Guardar Jerarquia", class = "btn-primary")
        ),
        shiny::tags$div(
          class = "hierarchy-editor-container",
          `data-var` = var_name,
          # Panel Izquierdo: Valores Disponibles
          shiny::tags$div(
            class = "hierarchy-source-panel",
            shiny::tags$div(class = "hierarchy-header", "Valores Unicos"),
            shiny::tags$div(
              id = "hierarchy-source-list",
              class = "hierarchy-body",
              lapply(unique_vals, function(v) {
                shiny::tags$div(class = "hierarchy-item", `data-value` = v, v)
              })
            )
          ),
          # Panel Derecho: Estructura de Niveles
          shiny::tags$div(
            class = "hierarchy-dest-panel",
            shiny::tags$div(
              class = "hierarchy-header", 
              "Grupos (Nivel 1)",
              shiny::actionButton("add_hierarchy_group", shiny::tagList(studio_icon("add", "Nuevo grupo"), " Nuevo Grupo"), class = "btn-xs")
            ),
            shiny::tags$div(
              id = "hierarchy-dest-list",
              class = "hierarchy-body",
              # Se llenará via JS o renderizado inicial con current_h
              if (length(current_h) > 0) {
                 lapply(names(current_h$mapping), function(grp) {
                    shiny::tags$div(
                      class = "hierarchy-folder",
                      `data-group` = grp,
                      shiny::tags$div(class = "folder-header", studio_icon("folder", "Grupo"), grp),
                      shiny::tags$div(
                        class = "folder-content",
                        lapply(current_h$mapping[[grp]], function(v) {
                          shiny::tags$div(class = "hierarchy-item", `data-value` = v, v)
                        })
                      )
                    )
                 })
              }
            )
          ),
          # Barra flotante de seleccion
          shiny::tags$div(
             class = "hierarchy-floating-bar",
             id = "hierarchy-selection-bar",
             style = "display: none;",
             shiny::tags$span(id = "hierarchy-selection-count", "0 seleccionado(s)"),
             shiny::actionButton("group_selected", "Agrupar", class = "btn-primary btn-sm")
          )
        )
      ))
      
      # Inicializar el editor de jerarquías en el modal
      shiny::insertUI(
        selector = "body",
        where = "beforeEnd",
        ui = shiny::tags$script("initHierarchySortable();"),
        immediate = TRUE
      )
    })

    shiny::observeEvent(input$save_hierarchy, {
      # Recibir el arbol estructurado desde JS
      tree_data <- input$hierarchy_tree_state
      var_name <- input$open_hierarchy_editor
      
      if (!is.null(tree_data) && !is.null(var_name)) {
        h <- hierarchies()
        h[[var_name]] <- list(
          mapping = tree_data,
          name = sprintf("Jerarquia %s", var_name)
        )
        hierarchies(h)
        shiny::showNotification("Jerarquia guardada temporalmente.", type = "message")
      }
      shiny::removeModal()
    })

    shiny::observeEvent(input$view_distribution, {
      var_name <- input$view_distribution
      shiny::req(source_data(), var_name)
      dist_var(var_name)
      
      shiny::showModal(shiny::modalDialog(
        title = sprintf("Distribucion: %s", var_name),
        size = "l",
        easyClose = TRUE,
        footer = shiny::modalButton("Cerrar"),
        shiny::tags$div(
          class = "distribution-container",
          shiny::plotOutput("dist_plot", height = "400px")
        )
      ))
    })

    output$dist_plot <- shiny::renderPlot({
      var_name <- dist_var()
      df <- source_data()
      roles <- role_state()
      shiny::req(df, var_name)
      
      column_data <- df[[var_name]]
      is_quasi <- var_name %in% c(roles$id, roles$categorical)
      
      p <- ggplot2::ggplot(df, ggplot2::aes(x = .data[[var_name]]))
      
      if (is_quasi) {
        # Si el usuario lo marco como categorico o ID, priorizamos gráfico de barras
        # incluso si el dato subyacente es numerico (se trata como discreto)
        counts <- as.data.frame(table(column_data))
        counts <- counts[order(-counts$Freq), ]
        top_counts <- utils::head(counts, 15)
        
        p <- ggplot2::ggplot(top_counts, ggplot2::aes(x = reorder(column_data, -Freq), y = Freq)) +
          ggplot2::geom_bar(stat = "identity", fill = "#10b981") +
          ggplot2::theme_minimal() +
          ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +
          ggplot2::labs(title = paste("Top 15 valores de", var_name), 
                        subtitle = "Visualización como variable categórica",
                        y = "Frecuencia", x = var_name)
      } else if (is.numeric(column_data)) {
        p <- p + 
          ggplot2::geom_histogram(fill = "#eab308", color = "white", bins = 30) +
          ggplot2::theme_minimal() +
          ggplot2::labs(title = paste("Histograma de", var_name), y = "Frecuencia", x = var_name)
      } else if (inherits(column_data, "Date") || inherits(column_data, "POSIXt")) {
        p <- p + 
          ggplot2::geom_histogram(fill = "#3b82f6", color = "white", bins = 30) +
          ggplot2::theme_minimal() +
          ggplot2::labs(title = paste("Distribucion Temporal de", var_name), y = "Frecuencia", x = var_name)
      } else {
        # Categorical / ID: Top 15 categories
        counts <- as.data.frame(table(column_data))
        counts <- counts[order(-counts$Freq), ]
        top_counts <- utils::head(counts, 15)
        
        p <- ggplot2::ggplot(top_counts, ggplot2::aes(x = reorder(column_data, -Freq), y = Freq)) +
          ggplot2::geom_bar(stat = "identity", fill = "#10b981") +
          ggplot2::theme_minimal() +
          ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +
          ggplot2::labs(title = paste("Top 15 categorias de", var_name), y = "Frecuencia", x = var_name)
      }
      
      p + ggplot2::theme(
        plot.title = ggplot2::element_text(face = "bold", size = 16),
        panel.grid.minor = ggplot2::element_blank()
      )
    })

    # --- Lógica de Hero Chips Meta ---
    output$hero_chips_ui <- shiny::renderUI({
      df <- source_data()
      defaults <- studio_parameter_defaults()
      k <- input$k_value %||% defaults$k_value
      name <- loaded_dataset_name()
      rows <- nrow(df %||% data.frame())
      
      shiny::tagList(
        shiny::tags$div(class = "hero-chip", studio_icon("dataset", "Dataset"), " Dataset: ", shiny::tags$strong(name)),
        shiny::tags$div(class = "hero-chip", studio_icon("rows", "Filas"), " Filas: ", shiny::tags$strong(rows)),
        shiny::tags$div(class = "hero-chip", studio_icon("shield", "k"), " k: ", shiny::tags$strong(k)),
        shiny::tags$div(class = "hero-chip", sprintf("v%s", obfuscator_version()))
      )
    })

    # --- Lógica de Privacy Meter ---
    output$privacy_meter_ui <- shiny::renderUI({
      meter <- release_safe_privacy_meter_state(
        role_state = role_state(),
        k_value = input$k_value %||% studio_parameter_defaults()$k_value,
        hierarchy_count = length(hierarchies()),
        release_state = release_state(),
        log_info = audit_log()
      )

      shiny::tags$div(
        class = paste("privacy-meter", meter$color_class),
        shiny::tags$div(class = "meter-track", 
          shiny::tags$div(class = "meter-fill", style = sprintf("width: %d%%", meter$score))
        ),
        shiny::tags$div(class = "meter-label", 
          shiny::tags$span(class = "score-val", sprintf("%d%%", meter$score)),
          shiny::tags$span(class = "score-text", meter$label)
        ),
        shiny::tags$p(class = "meter-caption", meter$caption)
      )
    })
    
    # NUEVO: Generador de Codigo R
    get_obfuscation_code <- function() {
       df <- source_data()
       roles <- role_state()
       h <- hierarchies()
       o <- numeric_offsets()
       privacy_model <- build_release_safe_privacy_model(
         df,
         role_state = roles,
         k_enabled = isTRUE(input$enable_k),
         k_value = input$k_value,
         k_suppression = input$k_suppression,
         group_ids = input$group_ids,
         hierarchies = h,
         suggested_roles = suggested_roles()
       )

       build_obfuscation_code_snippet(
         data_reference = if (input$source_mode == "environment") input$env_object else "data",
         seed = input$seed,
         id_prefix = input$id_prefix,
         numeric_mode = input$numeric_mode,
         project_key = if (nchar(input$project_key) > 0) input$project_key else NULL,
         col_roles = role_column_choices(df, roles),
         numeric_offsets = o,
         hierarchies = h,
         exclude_cols = roles$exclude,
         privacy_model = privacy_model
       )
    }

    shiny::observeEvent(input$view_r_code, {
       code <- get_obfuscation_code()
       shiny::showModal(shiny::modalDialog(
         title = "Codigo R para Reproduccion",
         size = "l",
         easyClose = TRUE,
         footer = shiny::modalButton("Cerrar"),
         shiny::tags$div(
           class = "code-container",
           shiny::tags$button(
             id = "copy-code-btn",
             class = "copy-code-btn",
             onclick = "copyRCodeToClipboard()",
             studio_icon("copy", "Copiar codigo"),
             " Copiar Codigo"
           ),
           shiny::tags$pre(
             style = "background: #f8fafc; padding: 25px 15px 15px; border-radius: 12px; border: 1px solid #e2e8f0; white-space: pre-wrap; font-family: monospace; font-size: 13px;",
             code
           )
         ),
         shiny::tags$p(class = "help-text", "Copia este codigo en un script de R para automatizar el proceso sin usar la interfaz.")
       ))
    })

    shiny::observeEvent(input$role_drop, {
      shiny::req(source_data())
      payload <- input$role_drop
      roles <- role_state()
      from_role <- payload$from_role
      to_role <- payload$to_role
      var_name <- payload$var_name

      if (!(from_role %in% names(roles)) || !(to_role %in% names(roles))) {
        return()
      }

      roles[[from_role]] <- setdiff(roles[[from_role]], var_name)
      roles[[to_role]] <- unique(c(roles[[to_role]], var_name))
      for (role_name in names(roles)) {
        roles[[role_name]] <- unique(roles[[role_name]])
      }
      role_state(roles)
    })

    output$dataset_summary_ui <- shiny::renderUI({
      df <- source_data()
      if (is.null(df)) {
        return(shiny::tags$p("Todavia no hay un dataset cargado."))
      }

      roles <- role_state()
      shiny::tags$div(
        class = "summary-grid",
        shiny::tags$div(class = "summary-card", shiny::tags$strong("Filas"), nrow(df)),
        shiny::tags$div(class = "summary-card", shiny::tags$strong("Columnas"), ncol(df)),
        shiny::tags$div(class = "summary-card", shiny::tags$strong("IDs"), length(roles$id)),
        shiny::tags$div(class = "summary-card", shiny::tags$strong("Fechas"), length(roles$date)),
        shiny::tags$div(class = "summary-card", shiny::tags$strong("Categoricas"), length(roles$categorical)),
        shiny::tags$div(class = "summary-card", shiny::tags$strong("Numericas"), length(roles$numeric)),
        shiny::tags$div(class = "summary-card", shiny::tags$strong("Sensibles"), length(roles$sensitive %||% character(0))),
        shiny::tags$div(class = "summary-card", shiny::tags$strong("Privadas"), length(roles$private %||% character(0))),
        shiny::tags$div(class = "summary-card", shiny::tags$strong("Para conservar"), length(roles$preserve))
      )
    })

    output$release_role_summary_ui <- shiny::renderUI({
      df <- source_data()
      if (is.null(df)) {
        return(shiny::tags$p("Carga un dataset para ver como quedarian separados los quasi-identificadores, sensibles y privados."))
      }
      build_release_role_summary(df, role_state(), k_enabled = isTRUE(input$enable_k))
    })

    output$release_workflow_guide_ui <- shiny::renderUI({
      render_release_workflow_guide()
    })

    output$release_variable_table_ui <- shiny::renderUI({
      df <- source_data()
      if (is.null(df)) {
        return(shiny::tags$p("Carga un dataset para revisar variables en la tabla principal de liberacion controlada."))
      }

      render_release_variable_table(
        df,
        role_state = role_state(),
        suggested_roles = suggested_roles(),
        search_term = input$var_search %||% ""
      )
    })

    output$release_variable_detail_ui <- shiny::renderUI({
      df <- source_data()
      if (is.null(df)) {
        return(render_release_variable_detail_panel(NULL, NULL, role_state = list()))
      }

      render_release_variable_detail_panel(
        df,
        selected_var = selected_release_variable(),
        role_state = role_state(),
        suggested_roles = suggested_roles()
      )
    })

    output$preview_mode_ui <- shiny::renderUI({
      build_preview_mode_control(has_obfuscated_data = !is.null(obfuscated_data()))
    })

    output$preview_notice_ui <- shiny::renderUI({
      preview_df <- obfuscated_data()
      build_preview_notice(preview_df, release_state())
    })

    output$role_board_ui <- shiny::renderUI({
      df <- source_data()
      if (is.null(df)) {
        return(shiny::tags$p("Carga un dataset para revisar las variables detectadas."))
      }

      roles <- role_state()
      sug_roles <- suggested_roles()
      active_h <- names(hierarchies())
      active_o <- names(numeric_offsets())
      numeric_cols <- colnames(df)[vapply(df, is.numeric, logical(1))]
      warning_vars <- detect_suspicious_date_character_columns(df)
      
      # Filter available variables based on search input
      all_vars <- colnames(df)
      available_vars <- setdiff(all_vars, unlist(roles[names(roles) != "available"]))
      
      search_term <- tolower(input$var_search)
      if (nzchar(search_term)) {
        available_vars <- available_vars[grepl(search_term, tolower(available_vars))]
        roles$id <- roles$id[grepl(search_term, tolower(roles$id))]
        roles$date <- roles$date[grepl(search_term, tolower(roles$date))]
        roles$categorical <- roles$categorical[grepl(search_term, tolower(roles$categorical))]
        roles$numeric <- roles$numeric[grepl(search_term, tolower(roles$numeric))]
        roles$sensitive <- (roles$sensitive %||% character(0))[grepl(search_term, tolower(roles$sensitive %||% character(0)))]
        roles$private <- (roles$private %||% character(0))[grepl(search_term, tolower(roles$private %||% character(0)))]
        roles$preserve <- roles$preserve[grepl(search_term, tolower(roles$preserve))]
        roles$exclude <- roles$exclude[grepl(search_term, tolower(roles$exclude))] # Filter exclude zone
      }

      shiny::tags$div(
        class = "role-board",
        render_role_zone_ui("Disponibles", "available", available_vars, warning_vars = warning_vars, suggested_vars = sug_roles, active_hierarchies = active_h, active_offsets = active_o, numeric_cols = numeric_cols, accent_class = "accent-slate"),
        render_role_zone_ui("Identificadoras", "id", roles$id, warning_vars = warning_vars, suggested_vars = sug_roles, active_hierarchies = active_h, active_offsets = active_o, numeric_cols = numeric_cols, accent_class = "accent-red"),
        render_role_zone_ui("Fechas", "date", roles$date, warning_vars = warning_vars, suggested_vars = sug_roles, active_hierarchies = active_h, active_offsets = active_o, numeric_cols = numeric_cols, accent_class = "accent-blue text-sm"),
        render_role_zone_ui("Categoricas", "categorical", roles$categorical, warning_vars = warning_vars, suggested_vars = sug_roles, active_hierarchies = active_h, active_offsets = active_o, numeric_cols = numeric_cols, accent_class = "accent-green text-sm"),
        render_role_zone_ui("Sensibles", "sensitive", roles$sensitive %||% character(0), warning_vars = warning_vars, suggested_vars = sug_roles, active_hierarchies = active_h, active_offsets = active_o, numeric_cols = numeric_cols, accent_class = "accent-burgundy text-sm"),
        render_role_zone_ui("Privadas", "private", roles$private %||% character(0), warning_vars = warning_vars, suggested_vars = sug_roles, active_hierarchies = active_h, active_offsets = active_o, numeric_cols = numeric_cols, accent_class = "accent-gold text-sm"),
        render_role_zone_ui("Numericas", "numeric", roles$numeric, warning_vars = warning_vars, suggested_vars = sug_roles, active_hierarchies = active_h, active_offsets = active_o, numeric_cols = numeric_cols, accent_class = "accent-gold text-sm"),
        render_role_zone_ui("Excluir", "exclude", roles$exclude, warning_vars = warning_vars, suggested_vars = sug_roles, active_hierarchies = active_h, active_offsets = active_o, numeric_cols = numeric_cols, accent_class = "accent-gray text-sm"), # NUEVA ZONA
        render_role_zone_ui("Conservar", "preserve", roles$preserve, warning_vars = warning_vars, suggested_vars = sug_roles, active_hierarchies = active_h, active_offsets = active_o, numeric_cols = numeric_cols, accent_class = "accent-gray text-sm")
      )
    })

    output$preview_table <- shiny::renderTable({
      df <- source_data()
      shiny::req(df)

      preview_df <- obfuscated_data()

      if (!is.null(preview_df)) {
        df <- preview_df
      } else if (isTRUE(input$live_preview)) {
        roles <- role_state()
        privacy_model <- build_release_safe_privacy_model(
          df,
          role_state = roles,
          k_enabled = isTRUE(input$enable_k),
          k_value = input$k_value,
          k_suppression = input$k_suppression,
          group_ids = input$group_ids,
          hierarchies = hierarchies(),
          suggested_roles = suggested_roles()
        )
        config <- obfuscator_config(
          seed = input$seed,
          id_prefix = input$id_prefix,
          numeric_mode = input$numeric_mode,
          col_roles = role_column_choices(df, roles),
          project_key = if (nchar(input$project_key) > 0) input$project_key else NULL,
          numeric_offsets = numeric_offsets(),
          exclude_cols = roles$exclude,
          privacy_model = privacy_model
        )
        df <- obfuscate_dataset(utils::head(df, 10), config = config)
      }

      if (nrow(df) == 0) {
        return(NULL)
      }

      utils::head(format_preview_dataset(df), 10)
    }, rownames = TRUE)

    shiny::observeEvent(input$run_obfuscation, {
      df <- source_data()
      shiny::req(df)

      roles <- role_state()
      release_state(transition_release_state(
        release_state(),
        "start_review",
        context = list(metadata = list(trigger = "run_obfuscation"))
      ))
      privacy_model <- build_release_safe_privacy_model(
        df,
        role_state = roles,
        k_enabled = isTRUE(input$enable_k),
        k_value = input$k_value,
        k_suppression = input$k_suppression,
        group_ids = input$group_ids,
        hierarchies = hierarchies(),
        suggested_roles = suggested_roles()
      )
      if (isTRUE(input$enable_k) && length(privacy_model$quasi_identifiers %||% character(0)) == 0) {
        shiny::showNotification("k-anonymity necesita al menos un quasi-identificador seleccionado.", type = "error")
        return()
      }

      config <- obfuscator_config(
        seed = input$seed,
        id_prefix = input$id_prefix,
        numeric_mode = input$numeric_mode,
        col_roles = role_column_choices(df, roles),
        privacy_model = privacy_model,
        project_key = if (nchar(input$project_key) > 0) input$project_key else NULL,
        numeric_offsets = numeric_offsets(),
        exclude_cols = roles$exclude
      )
      last_percent <- 0
      last_bucket <- -1

      shiny::withProgress(message = "Procesando dataset", value = 0, {
        config$progress_callback <- function(event) {
          target_percent <- max(0, min(100, event$percent %||% 0))
          increment <- max(0, (target_percent - last_percent) / 100)
          if (increment > 0) {
            shiny::incProgress(
              increment,
              detail = paste(
                sprintf("%d%%", round(target_percent)),
                "-",
                event$stage %||% "Procesando",
                if (!is.null(event$detail) && nzchar(event$detail)) paste0(" (", event$detail, ")") else ""
              )
            )
            last_percent <<- target_percent
          }

          current_bucket <- floor(target_percent / 10)
          if (current_bucket > last_bucket) {
            progress_status(sprintf(
              "Avance %d%%: %s%s",
              current_bucket * 10,
              event$stage %||% "Procesando",
              if (!is.null(event$detail) && nzchar(event$detail)) paste0(" (", event$detail, ")") else ""
            ))
            last_bucket <<- current_bucket
          }
        }

        result <- obfuscate_dataset(df, config = config)
        obfuscated_data(result)
        log_info <- augment_release_audit_log_with_release_safe_context(
          attr(result, "obfuscator_log"),
          df = source_data(),
          role_state = roles,
          suggested_roles = suggested_roles()
        )
        attr(result, "obfuscator_log") <- log_info
        audit_log(log_info)

        privacy_report <- log_info$privacy_report %||% list()
        release_state(derive_release_state_from_obfuscation(
          privacy_enabled = isTRUE(input$enable_k),
          privacy_satisfied = isTRUE(privacy_report$after$satisfied),
          has_internal_preview = TRUE,
          final_row_count = nrow(result)
        ))
      })

      progress_status("Ofuscacion completada al 100%.")
      shiny::showNotification("Ofuscacion completada.", type = "message")
    })

    shiny::observeEvent(input$save_template, {
      df <- source_data()
      shiny::req(df)
      hash_id <- generate_schema_hash(df)
      config_path <- file.path("config", paste0(hash_id, ".json"))
      
      config_to_save <- build_persistable_role_template(
        role_state = role_state(),
        hierarchies = hierarchies(),
        numeric_offsets = numeric_offsets()
      )

      save_roles_to_json(config_to_save, config_path)
      shiny::showNotification(build_template_notification(hash_id, action = "saved"), type = "message")
    })

    shiny::observeEvent(input$load_template, {
      df <- source_data()
      shiny::req(df)
      hash_id <- generate_schema_hash(df)
      config_path <- file.path("config", paste0(hash_id, ".json"))

      if (!file.exists(config_path)) {
        shiny::showNotification("No hay una plantilla guardada para el esquema actual.", type = "warning")
        return()
      }

      persisted <- load_roles_from_json(df, config_path)
      applied <- apply_persisted_template_to_roles(df, persisted)

      if (!isTRUE(applied$loaded)) {
        shiny::showNotification("No se pudo cargar la plantilla para este esquema.", type = "error")
        return()
      }

      role_state(applied$roles)
      suggested_roles(applied$suggested)
      hierarchies(applied$hierarchies)
      numeric_offsets(applied$numeric_offsets)
      selected_release_variable(NULL)
      shiny::showNotification(
        build_template_notification(hash_id, suggested_count = length(applied$suggested), action = "loaded"),
        type = "message"
      )
    })

    shiny::observeEvent(input$confirm_suggestions, {
      sug <- suggested_roles()
      if (length(sug) == 0) {
        shiny::showNotification("No hay sugerencias que confirmar.", type = "warning")
        return()
      }
      
      roles <- role_state()
      for (col in names(sug)) {
        role_name <- sug[[col]]$role
        # Quitar de donde este ahora (available usualmente)
        for (r in names(roles)) roles[[r]] <- setdiff(roles[[r]], col)
        # Poner en el nuevo rol
        roles[[role_name]] <- unique(c(roles[[role_name]], col))
      }
      
      role_state(roles)
      suggested_roles(list())
      shiny::showNotification("Sugerencias confirmadas.", type = "message")
    })

    output$audit_log_text <- shiny::renderPrint({
      log_info <- audit_log()
      report_text <- build_release_audit_summary(
        release_state(),
        log_info = log_info
      )
      cat(report_text, "\n")
    })

    shiny::observeEvent(input$show_audit_log, {
      shiny::showModal(shiny::modalDialog(
        title = "Log tecnico de auditoria",
        size = "l",
        easyClose = TRUE,
        shiny::tags$p(class = "help-text", "Este log muestra el objeto tecnico registrado por la ofuscacion actual."),
        shiny::verbatimTextOutput("audit_log_dump_text"),
        footer = shiny::modalButton("Cerrar")
      ))
    })

    output$audit_log_dump_text <- shiny::renderText({
      render_audit_log_dump(audit_log())
    })

    output$download_button_ui <- shiny::renderUI({
      build_download_button_control(release_state())
    })

    shiny::observeEvent(input$download_blocked, {
      shiny::showModal(shiny::modalDialog(
        title = "Exportacion externa bloqueada",
        easyClose = TRUE,
        footer = shiny::modalButton("Cerrar"),
        shiny::tags$p("El dataset actual no esta en estado Liberable para exportacion externa."),
        shiny::tags$p(
          class = "help-text",
          "Revisa el resumen de auditoria para entender por que esta bloqueado y que ajustes faltan antes de descargar."
        )
      ))
    })

    shiny::observeEvent(input$save_to_env, {
      shiny::req(obfuscated_data())
      object_name <- input$output_object_name
      shiny::validate(shiny::need(nzchar(object_name), "Debes indicar un nombre de objeto valido."))
      assign(object_name, obfuscated_data(), envir = .GlobalEnv)
      shiny::showNotification(sprintf("Objeto `%s` guardado en el entorno global.", object_name), type = "message")
    })

    shiny::observeEvent(input$revert_btn, {
      res <- obfuscated_data()
      shiny::req(res)
      log <- attr(res, "obfuscator_log")
      if (is.null(log)) {
        shiny::showNotification("No hay informacion de auditoria para revertir este dataset.", type = "error")
        return()
      }
      
      tryCatch({
        reverted <- revert_obfuscation(res, log)
        source_data(reverted)
        obfuscated_data(NULL)
        audit_log(NULL)
        selected_release_variable(NULL)
        progress_status("Dataset restaurado al estado previo a la ofuscacion.")
        release_state(transition_release_state(
          release_state(),
          "material_change",
          context = list(metadata = list(trigger = "revert"))
        ))
        shiny::showNotification("Dataset restaurado al estado previo a la ofuscacion.", type = "message")
      }, error = function(e) {
        shiny::showNotification(paste("Error al revertir:", e$message), type = "error")
      })
    })

    # --- Lógica de Cifrado Reversible (Manual) ---
    shiny::observeEvent(input$open_offset_editor, {
      var_name <- input$open_offset_editor
      current_val <- numeric_offsets()[[var_name]] %||% 0
      
      shiny::showModal(shiny::modalDialog(
        title = paste("Configurar Cifrado Reversible:", var_name),
        size = "s",
        # Usamos passwordInput para que la clave sea secreta al ingresarla
        shiny::passwordInput("offset_value", "Ingrese Clave Numerica de Desfase:", value = as.character(current_val)),
        shiny::tags$p(class = "help-text", "Esta clave se sumara al ID original. Es necesaria para el proceso inverso y NO se exporta en el codigo R."),
        footer = shiny::tagList(
          shiny::modalButton("Cancelar"),
          shiny::actionButton("save_offset_v2", "Guardar Clave", class = "primary-btn")
        )
      ))
    })
    
    shiny::observeEvent(input$save_offset_v2, {
      var_name <- input$open_offset_editor
      val <- as.numeric(input$offset_value)
      
      if (is.na(val)) {
        shiny::showNotification("Error: Por favor ingrese un numero valido.", type = "error")
        return()
      }
      
      o <- numeric_offsets()
      o[[var_name]] <- val
      numeric_offsets(o)
      shiny::removeModal()
      shiny::showNotification(sprintf("Cifrado reversible guardado para %s", var_name))
    })

    # --- Sistema de Ayuda Integrado ---
    shiny::observeEvent(input$show_help, {
      shiny::showModal(shiny::modalDialog(
        title = "Manual de ObfuscatoR Studio 2.0",
        size = "l",
        easyClose = TRUE,
        shiny::tabsetPanel(
          shiny::tabPanel("Guia Rapida", 
            shiny::tags$div(style = "padding: 15px;",
              shiny::tags$h4("Flujo de trabajo para liberacion"),
              shiny::tags$p("La tabla principal por variable y la ficha lateral permiten clasificar y revisar el dataset antes de decidir su salida."),
              shiny::tags$ol(
                shiny::tags$li("Carga el dataset y revisa las sugerencias automaticas."),
                shiny::tags$li("Confirma o ajusta el rol principal de cada variable desde la tabla."),
                shiny::tags$li("Usa Ver detalle para entender impacto, tratamiento y riesgo."),
                shiny::tags$li("Si el resultado es solo interno, puedes guardarlo como artefacto interno; si va a terceros, revisa el estado final antes de exportar."),
                shiny::tags$li("Usa el boton junto a Nivel de Privacidad para leer como funciona la estimacion preliminar.")
              ),
              shiny::tags$h4("Roles principales"),
              shiny::tags$ul(
                shiny::tags$li(shiny::tags$strong("ID:"), " identifica directamente y no debe liberarse tal cual."),
                shiny::tags$li(shiny::tags$strong("QI:"), " puede identificar por combinacion y entra a k-anonymity."),
                shiny::tags$li(shiny::tags$strong("SENS:"), " revela informacion delicada aunque no identifique por si sola."),
                shiny::tags$li(shiny::tags$strong("PRIV:"), " contiene informacion riesgosa o texto libre y requiere cautela adicional."),
                shiny::tags$li(shiny::tags$strong("KEEP / EXC:"), " permiten conservar o excluir variables de la salida final.")
              ),
              shiny::tags$p("Usa el boton de distribucion ", studio_icon("chart", "Distribucion"), " para ver la distribucion de los datos.")
            )
          ),
          shiny::tabPanel("Cifrado Reversible", 
            shiny::tags$div(style = "padding: 15px;",
              shiny::tags$h4("Cifrado por Desfase (Identificadoras Numericas)"),
              shiny::tags$p("Si una variable ID es numerica, veras el boton reversible ", studio_icon("key", "Reversible"), "."),
              shiny::tags$ol(
                shiny::tags$li("Haz clic en la llave e ingresa un numero secreto."),
                shiny::tags$li("El sistema sumara ese numero a todos los registros."),
                shiny::tags$li("Este proceso es reversible restando la misma clave."),
                shiny::tags$li(shiny::tags$strong("Seguridad:"), " Las claves NO se exportan en el codigo R ni se guardan en el servidor.")
              ),
              shiny::tags$p("Para revertir programaticamente usa: ", shiny::tags$code("revert_reversible_ids(data, list(Col = CLAVE))"))
            )
          ),
          shiny::tabPanel("Jerarquias", 
            shiny::tags$div(style = "padding: 15px;",
              shiny::tags$h4("Jerarquias de Anonimizacion"),
              shiny::tags$p("Usa el boton de jerarquias ", studio_icon("hierarchy", "Jerarquia"), " para agrupar valores sensibles en categorias mas generales (ej: Ciudad -> Provincia)."),
              shiny::tags$p("Esto es fundamental para el ", shiny::tags$strong("k-anonimato"), ", ya que permite que varios individuos compartan las mismas caracteristicas.")
            )
          ),
          shiny::tabPanel("Privacidad (k)", 
            shiny::tags$div(style = "padding: 15px;",
              shiny::tags$h4("Modelo k-anonymity"),
              shiny::tags$p("k-anonymity es el piso formal minimo para liberacion externa en este MVP."),
              shiny::tags$ul(
                shiny::tags$li(shiny::tags$strong("Antes de ejecutar:"), " el panel lateral muestra una estimacion preliminar basada en roles y configuracion."),
                shiny::tags$li(shiny::tags$strong("Despues de ejecutar:"), " el resumen de auditoria y el estado Liberable/Bloqueado mandan sobre la decision real de salida."),
                shiny::tags$li(shiny::tags$strong("Uso interno:"), " puedes guardar un artefacto interno sin tratarlo automaticamente como liberable hacia terceros."),
                shiny::tags$li(shiny::tags$strong("Liberacion externa:"), " solo debe ocurrir cuando el estado final del dataset sea Liberable.")
              ),
              shiny::tags$p("Subir k o generalizar mas puede mejorar la liberabilidad, pero tambien puede degradar la utilidad analitica.")
            )
          ),
          shiny::tabPanel("Plantillas",
            render_controlled_release_help()
          ),
          shiny::tabPanel("Medidor preliminar",
            render_privacy_meter_help_content()
          )
        ),
        footer = shiny::modalButton("Cerrar")
      ))
    })

    shiny::observeEvent(input$show_privacy_meter_help, {
      shiny::showModal(shiny::modalDialog(
        title = "Estimacion preliminar del nivel de privacidad",
        size = "m",
        easyClose = TRUE,
        render_privacy_meter_help_content(),
        footer = shiny::modalButton("Cerrar")
      ))
    })

    shiny::observeEvent(input$show_template_help, {
      shiny::showModal(shiny::modalDialog(
        title = "Clasificacion y plantillas",
        size = "m",
        easyClose = TRUE,
        render_controlled_release_help(),
        footer = shiny::modalButton("Cerrar")
      ))
    })

    output$download_csv <- shiny::downloadHandler(
      filename = function() {
        paste0("dataset_ofuscado_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        shiny::req(obfuscated_data())
        if (!can_export_external_release(release_state())) {
          stop("El dataset no esta en estado Liberable para exportacion externa.")
        }
        readr::write_csv(obfuscated_data(), file)
      }
    )
  }

  shiny::shinyApp(ui = ui, server = server, options = list(launch.browser = TRUE))
}
