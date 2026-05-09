release_contract_default <- function(x, default) {
  if (is.null(x)) default else x
}

release_workflow_statuses <- function() {
  c(
    "No evaluado",
    "En revision",
    "Bloqueado",
    "Liberable",
    "No liberable sin rediseno"
  )
}

build_release_state <- function(status, reasons = list(), metadata = list()) {
  allowed_statuses <- release_workflow_statuses()
  if (!is.character(status) || length(status) != 1 || !(status %in% allowed_statuses)) {
    stop(sprintf(
      "`status` must use one of: %s.",
      paste(allowed_statuses, collapse = ", ")
    ))
  }

  state <- list(
    status = status,
    reasons = if (is.list(reasons)) reasons else as.list(reasons),
    metadata = if (is.list(metadata)) metadata else list(value = metadata),
    can_export_external = identical(status, "Liberable")
  )
  class(state) <- c("release_state", "list")
  state
}

initial_release_state <- function() {
  build_release_state("No evaluado")
}

can_export_external_release <- function(state) {
  isTRUE(state$can_export_external) && identical(state$status, "Liberable")
}

transition_release_state <- function(current_state, event, context = list()) {
  allowed_events <- c("start_review", "block", "approve", "mark_non_releasable", "material_change")
  if (!is.character(event) || length(event) != 1 || !(event %in% allowed_events)) {
    stop(sprintf(
      "`event` must use one of: %s.",
      paste(allowed_events, collapse = ", ")
    ))
  }

  if (is.null(current_state) || !inherits(current_state, "release_state")) {
    current_state <- initial_release_state()
  }

  if (identical(current_state$status, "No liberable sin rediseno") && !identical(event, "material_change")) {
    return(current_state)
  }

  reasons <- context$reasons %||% list()
  metadata <- utils::modifyList(current_state$metadata %||% list(), context$metadata %||% list())

  switch(
    event,
    start_review = build_release_state("En revision", metadata = metadata),
    block = build_release_state("Bloqueado", reasons = reasons, metadata = metadata),
    approve = build_release_state("Liberable", metadata = metadata),
    mark_non_releasable = build_release_state("No liberable sin rediseno", reasons = reasons, metadata = metadata),
    material_change = build_release_state("No evaluado", metadata = context$metadata %||% list())
  )
}

derive_release_state_from_obfuscation <- function(
  privacy_enabled,
  privacy_satisfied = FALSE,
  has_internal_preview = TRUE
) {
  metadata <- list(
    has_internal_preview = isTRUE(has_internal_preview),
    artifact = release_artifact("internal_work")
  )

  if (!isTRUE(privacy_enabled)) {
    return(build_release_state(
      "Bloqueado",
      reasons = list("La liberacion externa requiere activar k-anonymity."),
      metadata = metadata
    ))
  }

  if (isTRUE(privacy_satisfied)) {
    metadata$artifact <- release_artifact("releasable_external")
    return(build_release_state("Liberable", metadata = metadata))
  }

  build_release_state(
    "Bloqueado",
    reasons = list("La configuracion actual no satisface k-anonymity para liberacion externa."),
    metadata = metadata
  )
}

normalize_risk_name <- function(x) {
  normalized <- iconv(as.character(x), to = "ASCII//TRANSLIT")
  normalized[is.na(normalized)] <- as.character(x)[is.na(normalized)]
  tolower(normalized)
}

high_risk_name_patterns <- function() {
  c(
    "nombre",
    "apellido",
    "documento",
    "cedula",
    "rut",
    "pers_id",
    "pers_identificador",
    "nro_int",
    "nie",
    "nic",
    "contribuyente",
    "contrib",
    "emp",
    "empresa",
    "telefono",
    "mail",
    "correo",
    "direccion",
    "comentario",
    "observacion",
    "fecha_nac",
    "nacimiento",
    "expediente",
    "tramite"
  )
}

detect_high_risk_name_patterns <- function(cols) {
  normalized_cols <- normalize_risk_name(cols)
  patterns <- high_risk_name_patterns()

  cols[vapply(normalized_cols, function(col) {
    any(vapply(patterns, function(pattern) grepl(pattern, col, fixed = TRUE), logical(1)))
  }, logical(1))]
}

looks_like_text_free_field <- function(x) {
  if (!(is.character(x) || is.factor(x))) {
    return(FALSE)
  }

  values <- as.character(stats::na.omit(x))
  if (length(values) == 0) {
    return(FALSE)
  }

  mean(nchar(values), na.rm = TRUE) >= 25
}

looks_like_high_cardinality_identifier <- function(x) {
  values <- stats::na.omit(as.character(x))
  if (length(values) == 0) {
    return(FALSE)
  }

  unique_ratio <- length(unique(values)) / length(values)
  unique_ratio >= 0.8
}

detect_high_risk_columns <- function(df, artifact_type = "internal_work") {
  stopifnot(is.data.frame(df))

  alerts <- list()
  risky_names <- detect_high_risk_name_patterns(colnames(df))

  add_alert <- function(code, severity, message, fields, evidence = list()) {
    alerts[[length(alerts) + 1L]] <<- release_alert(
      code = code,
      severity = severity,
      message = message,
      fields = fields,
      artifact_type = artifact_type,
      evidence = evidence
    )
  }

  for (col in colnames(df)) {
    values <- df[[col]]
    normalized_col <- normalize_risk_name(col)

    if (looks_like_text_free_field(values)) {
      add_alert(
        code = "text_like_column",
        severity = "critical",
        message = sprintf("La columna `%s` parece texto libre y requiere revision manual.", col),
        fields = col,
        evidence = list(mean_length = mean(nchar(as.character(stats::na.omit(values))), na.rm = TRUE))
      )
    }

    if (col %in% risky_names && looks_like_high_cardinality_identifier(values)) {
      add_alert(
        code = "high_cardinality_identifier",
        severity = "critical",
        message = sprintf("La columna `%s` combina patron nominal de riesgo con alta cardinalidad.", col),
        fields = col,
        evidence = list(unique_ratio = length(unique(stats::na.omit(as.character(values)))) / max(1, length(stats::na.omit(as.character(values)))))
      )
    } else if (col %in% risky_names) {
      add_alert(
        code = "high_risk_name_pattern",
        severity = "warning",
        message = sprintf("La columna `%s` coincide con patrones nominales de alto riesgo.", col),
        fields = col,
        evidence = list(pattern_source = normalized_col)
      )
    }
  }

  alerts
}

combination_sets_up_to_three <- function(cols) {
  unique(unlist(lapply(1:min(3, length(cols)), function(size) {
    combn(cols, size, simplify = FALSE)
  }), recursive = FALSE), recursive = FALSE)
}

combination_min_class_size <- function(df, cols) {
  groups <- interaction(df[cols], drop = TRUE, lex.order = TRUE)
  min(table(groups))
}

detect_risky_combinations <- function(df, cols, k, artifact_type = "internal_work") {
  stopifnot(is.data.frame(df))
  if (length(cols) == 0) {
    return(list())
  }

  alerts <- list()
  for (combo in combination_sets_up_to_three(cols)) {
    min_class <- combination_min_class_size(df, combo)
    if (is.finite(min_class) && min_class < k) {
      alerts[[length(alerts) + 1L]] <- release_alert(
        code = "combination_below_k",
        severity = "critical",
        message = sprintf(
          "La combinacion `%s` genera clases de equivalencia menores a k.",
          paste(combo, collapse = " + ")
        ),
        fields = combo,
        artifact_type = artifact_type,
        evidence = list(
          min_class_size = unname(min_class),
          k = k,
          combination_size = length(combo)
        )
      )
    }
  }

  alerts
}

is_high_precision_linkable_name <- function(cols) {
  normalized <- normalize_risk_name(cols)
  any(grepl("fecha", normalized, fixed = TRUE)) &&
    any(grepl("localidad", normalized, fixed = TRUE) | grepl("zona", normalized, fixed = TRUE)) &&
    any(grepl("evento", normalized, fixed = TRUE) | grepl("sector", normalized, fixed = TRUE) | grepl("actividad", normalized, fixed = TRUE))
}

detect_residual_risk_combinations <- function(df, quasi_cols, sensitive_cols = character(0), k, artifact_type = "internal_work") {
  stopifnot(is.data.frame(df))
  if (length(quasi_cols) == 0) {
    return(list())
  }

  alerts <- list()
  groups <- interaction(df[quasi_cols], drop = TRUE, lex.order = TRUE)
  class_sizes <- table(groups)

  if (length(sensitive_cols) > 0) {
    for (sens in sensitive_cols) {
      homogeneous <- tapply(df[[sens]], groups, function(values) length(unique(values)) == 1)
      qualifying_groups <- names(class_sizes)[class_sizes >= k]
      if (any(homogeneous[qualifying_groups], na.rm = TRUE)) {
        alerts[[length(alerts) + 1L]] <- release_alert(
          code = "homogeneous_sensitive_class",
          severity = "critical",
          message = sprintf(
            "La clase de equivalencia definida por `%s` mantiene homogeneidad sensible en `%s`.",
            paste(quasi_cols, collapse = " + "),
            sens
          ),
          fields = c(quasi_cols, sens),
          artifact_type = artifact_type,
          evidence = list(
            k = k,
            qualifying_groups = qualifying_groups[homogeneous[qualifying_groups] %in% TRUE]
          )
        )
      }
    }
  }

  if (all(class_sizes >= k) && length(class_sizes) == 1 && is_high_precision_linkable_name(quasi_cols)) {
    alerts[[length(alerts) + 1L]] <- release_alert(
      code = "precise_linkable_combination",
      severity = "critical",
      message = sprintf(
        "La combinacion `%s` sigue siendo demasiado precisa y vinculable externamente aunque cumpla k.",
        paste(quasi_cols, collapse = " + ")
      ),
      fields = quasi_cols,
      artifact_type = artifact_type,
      evidence = list(
        k = k,
        class_size = unname(class_sizes[[1]])
      )
    )
  }

  alerts
}

detect_high_dimensional_relinkability <- function(
  df,
  known_source_cols,
  min_dimensions = 6,
  uniqueness_threshold = 0.8,
  artifact_type = "internal_work"
) {
  stopifnot(is.data.frame(df))
  cols <- intersect(known_source_cols, colnames(df))
  if (length(cols) < min_dimensions) {
    return(list())
  }

  signature_df <- df[cols]
  signature_keys <- apply(signature_df, 1, function(row) paste(row, collapse = "||"))
  unique_ratio <- length(unique(signature_keys)) / max(1, length(signature_keys))

  if (unique_ratio < uniqueness_threshold) {
    return(list())
  }

  list(release_alert(
    code = "high_dimensional_relinkability",
    severity = "critical",
    message = paste(
      "El dataset conserva demasiadas firmas descriptivas unicas o casi unicas",
      "cuando el tercero ya conoce las columnas fuente."
    ),
    fields = cols,
    artifact_type = artifact_type,
    evidence = list(
      dimensions = length(cols),
      uniqueness_ratio = unique_ratio,
      threshold = uniqueness_threshold
    )
  ))
}

build_manual_review_result <- function(
  object_id,
  review_type,
  verified = FALSE,
  evidence = list(),
  notes = NULL
) {
  if (!is.character(object_id) || length(object_id) != 1 || !nzchar(object_id)) {
    stop("`object_id` must be a non-empty scalar character value.")
  }
  if (!is.character(review_type) || length(review_type) != 1 || !nzchar(review_type)) {
    stop("`review_type` must be a non-empty scalar character value.")
  }

  review <- list(
    object_id = object_id,
    review_type = review_type,
    verified = isTRUE(verified),
    evidence = if (is.list(evidence)) evidence else list(value = evidence),
    notes = notes %||% NA_character_
  )
  class(review) <- c("manual_review_result", "list")
  review
}

review_type_from_alert <- function(alert) {
  switch(
    alert$code,
    text_like_column = "text_free",
    high_dimensional_relinkability = "relinkability",
    combination_below_k = "combination_risk",
    homogeneous_sensitive_class = "sensitive_homogeneity",
    precise_linkable_combination = "relinkability",
    "general_risk"
  )
}

build_review_requirements <- function(alerts) {
  if (length(alerts) == 0) {
    return(list(required = FALSE, items = list()))
  }

  critical_alerts <- Filter(function(alert) identical(alert$severity, "critical"), alerts)
  if (length(critical_alerts) == 0) {
    return(list(required = FALSE, items = list()))
  }

  items <- lapply(critical_alerts, function(alert) {
    list(
      object_id = paste(alert$fields, collapse = " + "),
      review_type = review_type_from_alert(alert),
      reason = alert$message,
      fields = alert$fields,
      alert_code = alert$code
    )
  })

  list(required = TRUE, items = items)
}

collapse_lines <- function(lines) {
  paste(unlist(lines, recursive = TRUE, use.names = FALSE), collapse = "\n")
}

build_release_report <- function(status, controls_passed = list(), reviews = list(), metadata = list()) {
  artifact_type <- metadata$artifact$type %||% "desconocido"
  review_lines <- if (length(reviews) == 0) {
    "- Sin revisiones manuales requeridas."
  } else {
    vapply(reviews, function(review) {
      sprintf(
        "- `%s` [%s]: verificado=%s",
        review$object_id,
        review$review_type,
        if (isTRUE(review$verified)) "si" else "no"
      )
    }, character(1))
  }

  collapse_lines(c(
    sprintf("Estado de liberacion: %s", status),
    sprintf("Tipo de artefacto: %s", artifact_type),
    "",
    "Controles superados:",
    if (length(controls_passed) == 0) "- Sin controles registrados." else paste0("- ", unlist(controls_passed, use.names = FALSE)),
    "",
    "Revisiones manuales:",
    review_lines
  ))
}

build_non_release_report <- function(status, reasons = list(), next_steps = list(), reviews = list(), metadata = list()) {
  privacy_note <- if (isTRUE(metadata$privacy_satisfied)) {
    "Nota: k-anonymity puede haberse satisfecho, pero persiste riesgo residual inaceptable."
  } else {
    "Nota: k-anonymity no alcanza o no fue satisfecha para la liberacion externa."
  }

  review_lines <- if (length(reviews) == 0) {
    "- Sin revisiones manuales concluyentes."
  } else {
    vapply(reviews, function(review) {
      sprintf(
        "- `%s` [%s]: verificado=%s",
        review$object_id,
        review$review_type,
        if (isTRUE(review$verified)) "si" else "no"
      )
    }, character(1))
  }

  collapse_lines(c(
    sprintf("Estado de liberacion: %s", status),
    privacy_note,
    "",
    "Bloqueos no resueltos:",
    if (length(reasons) == 0) "- Sin razones registradas." else paste0("- ", unlist(reasons, use.names = FALSE)),
    "",
    "Revisiones manuales:",
    review_lines,
    "",
    "Acciones recomendadas:",
    if (length(next_steps) == 0) "- Sin acciones propuestas." else paste0("- ", unlist(next_steps, use.names = FALSE))
  ))
}

release_controls_from_log <- function(log_info = list()) {
  if (is.null(log_info)) {
    return(character(0))
  }

  privacy_report <- log_info$privacy_report %||% list()
  roles <- log_info$roles %||% list()
  transformations <- log_info$transformations %||% list()
  controls <- character(0)

  if (isTRUE(privacy_report$after$satisfied)) {
    controls <- c(controls, "k-anonymity satisfecha")
  }

  if (!is.null(privacy_report$k)) {
    controls <- c(controls, sprintf("valor de k evaluado: %s", privacy_report$k))
  }

  id_cols <- roles$id %||% character(0)
  if (length(id_cols) > 0) {
    controls <- c(controls, sprintf("identificadores transformados: %s columna(s)", length(id_cols)))
  }

  if (is.numeric(privacy_report$rows_suppressed) && length(privacy_report$rows_suppressed) == 1 && privacy_report$rows_suppressed > 0) {
    controls <- c(controls, sprintf("supresion residual aplicada: %s fila(s)", privacy_report$rows_suppressed))
  }

  if (length(transformations) > 0) {
    controls <- c(controls, sprintf("transformaciones registradas: %s", length(transformations)))
  }

  unique(controls)
}

release_next_steps_from_state <- function(state, log_info = list()) {
  reasons <- unlist(state$reasons %||% list(), use.names = FALSE)
  privacy_report <- log_info$privacy_report %||% list()
  steps <- character(0)

  if (identical(state$status, "No evaluado")) {
    steps <- c(steps, "ejecutar la ofuscacion para evaluar la liberacion externa")
  }

  if (identical(state$status, "En revision")) {
    steps <- c(steps, "completar la evaluacion de riesgo antes de exportar")
  }

  if (any(grepl("activar k-anonymity", reasons, fixed = TRUE))) {
    steps <- c(steps, "activar k-anonymity y definir quasi-identificadores relevantes")
  }

  if (any(grepl("no satisface k-anonymity", reasons, fixed = TRUE)) || (!is.null(privacy_report$after) && !isTRUE(privacy_report$after$satisfied))) {
    steps <- c(steps, "aumentar k o generalizar los quasi-identificadores")
  }

  if (isTRUE(privacy_report$after$satisfied) && identical(state$status, "Bloqueado")) {
    steps <- c(steps, "resolver el riesgo residual antes de habilitar la liberacion")
  }

  if (length(steps) == 0 && identical(state$status, "No liberable sin rediseno")) {
    steps <- c(steps, "redisenar el dataset o el criterio de liberacion antes de reintentar")
  }

  if (length(steps) == 0 && identical(state$status, "Bloqueado")) {
    steps <- c(steps, "revisar los bloqueos detectados y aplicar una resolucion segura")
  }

  unique(steps)
}

build_release_audit_summary <- function(state, log_info = NULL, reviews = list()) {
  if (is.null(state) || !inherits(state, "release_state")) {
    state <- initial_release_state()
  }

  if (length(reviews) == 0) {
    reviews <- state$metadata$reviews %||% list()
  }

  metadata <- state$metadata %||% list()
  privacy_report <- log_info$privacy_report %||% list()

  if (is.null(metadata$artifact)) {
    metadata$artifact <- release_artifact(if (can_export_external_release(state)) "releasable_external" else "internal_work")
  }
  metadata$privacy_satisfied <- isTRUE(privacy_report$after$satisfied)

  if (identical(state$status, "No evaluado")) {
    return(collapse_lines(c(
      "Estado de liberacion: No evaluado",
      "Accion recomendada: ejecutar la ofuscacion para evaluar si el dataset puede liberarse."
    )))
  }

  if (identical(state$status, "En revision")) {
    return(collapse_lines(c(
      "Estado de liberacion: En revision",
      "Accion recomendada: completar la evaluacion de riesgo y las revisiones requeridas antes de exportar."
    )))
  }

  if (identical(state$status, "Liberable")) {
    return(build_release_report(
      status = state$status,
      controls_passed = as.list(release_controls_from_log(log_info)),
      reviews = reviews,
      metadata = metadata
    ))
  }

  reasons <- unlist(state$reasons %||% list(), use.names = FALSE)
  if (length(reasons) == 0 && !isTRUE(privacy_report$after$satisfied)) {
    reasons <- c(reasons, "La configuracion actual no satisface k-anonymity para liberacion externa.")
  }

  build_non_release_report(
    status = state$status,
    reasons = as.list(unique(reasons)),
    next_steps = as.list(release_next_steps_from_state(state, log_info = log_info)),
    reviews = reviews,
    metadata = metadata
  )
}

release_artifact <- function(type, name = NULL) {
  allowed_types <- c("preview", "internal_work", "releasable_external")
  if (!is.character(type) || length(type) != 1 || !(type %in% allowed_types)) {
    stop("`artifact` must use one of: preview, internal_work, releasable_external.")
  }

  artifact <- list(
    type = type,
    name = release_contract_default(name, NA_character_)
  )
  class(artifact) <- c("release_artifact", "list")
  artifact
}

release_alert <- function(code, severity, message, fields = character(0), artifact_type, evidence = list()) {
  allowed_severity <- c("info", "warning", "critical")
  if (!is.character(code) || length(code) != 1 || identical(code, "")) {
    stop("`code` must be a non-empty scalar character value.")
  }
  if (!is.character(severity) || length(severity) != 1 || !(severity %in% allowed_severity)) {
    stop("`severity` must use one of: info, warning, critical.")
  }
  if (!is.character(message) || length(message) != 1 || identical(message, "")) {
    stop("`message` must be a non-empty scalar character value.")
  }

  artifact <- release_artifact(artifact_type)
  alert <- list(
    code = code,
    severity = severity,
    message = message,
    fields = as.character(fields),
    artifact_type = artifact$type,
    evidence = if (is.list(evidence)) evidence else list(value = evidence)
  )
  class(alert) <- c("release_alert", "list")
  alert
}

manual_review_evidence <- function(kind, summary, fields = character(0), examples = character(0), recommendation) {
  if (!is.character(kind) || length(kind) != 1 || identical(kind, "")) {
    stop("`kind` must be a non-empty scalar character value.")
  }
  if (!is.character(summary) || length(summary) != 1 || identical(summary, "")) {
    stop("`summary` must be a non-empty scalar character value.")
  }
  if (!is.character(recommendation) || length(recommendation) != 1 || identical(recommendation, "")) {
    stop("`recommendation` must be a non-empty scalar character value.")
  }

  evidence <- list(
    kind = kind,
    summary = summary,
    fields = as.character(fields),
    examples = as.character(examples),
    recommendation = recommendation
  )
  class(evidence) <- c("manual_review_evidence", "list")
  evidence
}

normalize_release_scenario <- function(input, path = c("api", "ui")) {
  path <- match.arg(path)

  if (identical(path, "ui")) {
    list(
      artifact = list(
        type = input$artifact_type,
        name = input$artifact_name
      ),
      signals = list(
        direct_identifiers_removed = input$direct_identifiers_removed,
        dates_generalized = input$dates_generalized,
        distinctive_numerics_masked = input$distinctive_numerics_masked,
        rare_categories_grouped = input$rare_categories_grouped,
        text_like_risk = input$text_like_risk
      ),
      evidence = release_contract_default(input$evidence, list())
    )
  } else {
    input
  }
}

release_contract_alerts <- function(artifact, signals, evidence = list()) {
  alerts <- list()

  add_alert <- function(code, severity, message, fields = character(0), extra = list()) {
    alerts[[length(alerts) + 1L]] <<- release_alert(
      code = code,
      severity = severity,
      message = message,
      fields = fields,
      artifact_type = artifact$type,
      evidence = extra
    )
  }

  if (!isTRUE(signals$direct_identifiers_removed)) {
    add_alert(
      "direct_identifiers_present",
      "critical",
      "Direct identifiers are still present in the release artifact.",
      fields = "identifiers",
      extra = evidence
    )
  }

  if (!isTRUE(signals$dates_generalized)) {
    add_alert(
      "exact_dates_exposed",
      "critical",
      "Exact dates remain visible for third-party release.",
      fields = "dates",
      extra = evidence
    )
  }

  if (!isTRUE(signals$distinctive_numerics_masked)) {
    add_alert(
      "distinctive_numeric_risk",
      "critical",
      "Distinctive numeric values remain visible in the artifact.",
      fields = "numeric_values",
      extra = evidence
    )
  }

  if (!isTRUE(signals$rare_categories_grouped)) {
    add_alert(
      "rare_category_risk",
      "warning",
      "Rare categories remain visible in the artifact.",
      fields = "rare_categories",
      extra = evidence
    )
  }

  if (isTRUE(signals$text_like_risk)) {
    add_alert(
      "text_like_risk",
      "critical",
      "Free-text or text-like content still carries re-identification risk.",
      fields = "text",
      extra = evidence
    )
  }

  alerts
}

manual_review_from_alerts <- function(alerts) {
  warning_alerts <- Filter(function(alert) identical(alert$severity, "warning"), alerts)
  if (length(warning_alerts) == 0) {
    return(list(required = FALSE, evidence = list()))
  }

  fields <- unique(unlist(lapply(warning_alerts, function(alert) alert$fields), use.names = FALSE))
  evidence <- manual_review_evidence(
    kind = "warning_review",
    summary = "Residual warning-level risks require manual review before release.",
    fields = fields,
    examples = vapply(warning_alerts, `[[`, character(1), "message"),
    recommendation = "Review warning signals and confirm they are acceptable for the intended audience."
  )

  list(required = TRUE, evidence = list(evidence))
}

evaluate_release_contract <- function(scenario) {
  artifact <- do.call(release_artifact, scenario$artifact)
  signals <- release_contract_default(scenario$signals, list())
  evidence <- release_contract_default(scenario$evidence, list())
  alerts <- release_contract_alerts(artifact, signals, evidence = evidence)

  critical_present <- any(vapply(alerts, function(alert) identical(alert$severity, "critical"), logical(1)))

  if (identical(artifact$type, "releasable_external")) {
    if (critical_present) {
      verdict <- "No liberable sin rediseno"
      can_release <- FALSE
      manual_review <- list(required = FALSE, evidence = list())
    } else if (length(alerts) == 0) {
      verdict <- "Liberable"
      can_release <- TRUE
      manual_review <- list(required = FALSE, evidence = list())
    } else {
      verdict <- "Requiere revision manual"
      can_release <- FALSE
      manual_review <- manual_review_from_alerts(alerts)
    }
  } else {
    verdict <- "Requiere revision manual"
    can_release <- FALSE
    manual_review <- manual_review_from_alerts(alerts)
  }

  state <- list(
    verdict = verdict,
    can_release = can_release,
    artifact = artifact,
    alerts = alerts,
    manual_review = manual_review
  )
  class(state) <- c("release_state", "list")
  state
}

release_decision_for_api <- function(input) {
  evaluate_release_contract(normalize_release_scenario(input, path = "api"))
}

release_decision_for_ui <- function(input) {
  evaluate_release_contract(normalize_release_scenario(input, path = "ui"))
}
