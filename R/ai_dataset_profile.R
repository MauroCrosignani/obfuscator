ai_profile_identifier_name <- function(column_name) {
  normalized_name <- ai_profile_normalize_column_name(column_name)
  grepl(
    "(^|_)(id|rut|cedula|dni|nie|nic)(_|$)|identificador|persona_id|pers_id|expediente|matricula|contribuyente|correo|mail|email|e_mail|telefono|celular",
    normalized_name
  )
}

ai_profile_sensitive_name <- function(column_name) {
  normalized_name <- ai_profile_normalize_column_name(column_name)
  grepl(
    "diagnost|enfermed|patolog|beneficio|subsid|sancion|riesgo|situacion|indicador_privado|sensib|privad|ingreso",
    normalized_name
  )
}

ai_profile_quasi_identifier_name <- function(column_name) {
  normalized_name <- ai_profile_normalize_column_name(column_name)
  grepl(
    "fecha|date|nacimiento|alta|periodo|mes|anio|edad|antiguedad|cantidad_hijos|tam_hogar|ingreso|salario|monto|facturacion|departamento|localidad|ocupacion|sector|tramo|educ|sexo",
    normalized_name
  )
}

ai_profile_expected_missingness_name <- function(column_name) {
  normalized_name <- ai_profile_normalize_column_name(column_name)
  grepl(
    "fecha_hasta|hasta$|end_date|fecha_fin|fin_vigencia|baja_fecha|cancelacion_fecha|cese_fecha|closed_at|ended_at",
    normalized_name
  )
}

ai_profile_numeric_code_like_name <- function(column_name) {
  normalized_name <- ai_profile_normalize_column_name(column_name)
  grepl("(cod|codigo|id|identif|tipo|clase|unidad)", normalized_name)
}

ai_profile_empty_config <- function() {
  list(
    faltantes_esperables = character(0),
    columnas_sensibles = character(0),
    columnas_identificatorias = character(0),
    columnas_texto_libre = character(0)
  )
}

ai_profile_normalize_config <- function(config) {
  normalized <- ai_profile_empty_config()
  warnings <- character(0)

  if (is.null(config)) {
    return(list(config = normalized, warnings = warnings))
  }

  if (!is.list(config)) {
    stop("`config` debe ser NULL o una lista declarativa.")
  }

  known_keys <- names(normalized)
  provided_keys <- names(config) %||% character(0)
  unknown_keys <- setdiff(provided_keys, known_keys)
  if (length(unknown_keys) > 0) {
    warnings <- c(
      warnings,
      sprintf(
        "Se ignoraron claves desconocidas en config: %s.",
        paste(sort(unknown_keys), collapse = ", ")
      )
    )
  }

  for (key in intersect(provided_keys, known_keys)) {
    values <- config[[key]]
    if (is.null(values)) {
      next
    }
    normalized[[key]] <- unique(as.character(values))
    normalized[[key]] <- normalized[[key]][nzchar(normalized[[key]])]
  }

  list(config = normalized, warnings = warnings)
}

ai_profile_validate_config <- function(config, data_names) {
  warnings <- character(0)

  for (key in names(config)) {
    missing_columns <- setdiff(config[[key]], data_names)
    if (length(missing_columns) > 0) {
      warnings <- c(
        warnings,
        vapply(
          missing_columns,
          function(column_name) {
            sprintf(
              "La columna '%s' fue declarada en %s pero no esta presente en el dataset.",
              column_name,
              key
            )
          },
          character(1)
        )
      )
    }
  }

  warnings
}

profile_dataset_for_ai <- function(data, dataset_name = NULL, config = NULL, tipo_fuente = NULL, archivo_fuente = NULL, metadata_dir = NULL, max_levels = 12, top_n = 10, round_digits = 2) {
  if (!is.data.frame(data)) {
    stop("`data` debe ser un data.frame o tibble.")
  }

  dataset_name <- dataset_name %||% deparse(substitute(data))
  source_context_result <- ai_profile_normalize_tipo_fuente(tipo_fuente)
  file_context_result <- ai_profile_detect_source_from_file(archivo_fuente)
  merged_source_context_result <- ai_profile_merge_source_context(
    tipo_fuente_context = source_context_result,
    file_context = file_context_result
  )
  source_metadata <- ai_profile_resolve_source_metadata(
    metadata_dir = metadata_dir,
    source_context = merged_source_context_result$source_context,
    dataset_name = dataset_name,
    data_names = names(data)
  )
  normalized_config_result <- ai_profile_normalize_config(config)
  normalized_config <- normalized_config_result$config
  config_warnings <- c(
    merged_source_context_result$warnings,
    source_metadata$warnings,
    normalized_config_result$warnings,
    ai_profile_validate_config(normalized_config, names(data))
  )
  variable_profiles <- stats::setNames(
    lapply(names(data), function(column_name) {
      build_variable_profile_for_ai(
        column_name,
        data[[column_name]],
        config = normalized_config,
        round_digits = round_digits,
        max_levels = max_levels,
        top_n = top_n
      )
    }),
    names(data)
  )

  config_applied <- lapply(variable_profiles, `[[`, "applied_rules")
  config_applied <- config_applied[vapply(config_applied, length, integer(1)) > 0]

  global_warnings <- unique(c(
    unlist(lapply(variable_profiles, `[[`, "warnings"), use.names = FALSE),
    config_warnings
  ))
  source_alerts <- ai_profile_build_source_alerts(
    source_metadata = source_metadata,
    variable_profiles = variable_profiles
  )

  list(
    dataset_name = dataset_name,
    dimensions = list(rows = nrow(data), cols = ncol(data)),
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    source_context = merged_source_context_result$source_context,
    source_metadata = source_metadata,
    source_alerts = source_alerts,
    variables = variable_profiles,
    config_applied = config_applied,
    warnings = global_warnings
  )
}

# Ejemplo de uso desde RStudio:
# profile <- profile_dataset_for_ai(iris, "iris")
# cat(render_dataset_profile_for_ai(profile))
render_ai_profile_variable <- function(variable_profile, mode = "compact") {
  name <- variable_profile$name
  imported_type <- variable_profile$imported_type
  inferred_type <- variable_profile$inferred_type
  summary <- variable_profile$summary
  role_guess <- variable_profile$role_guess
  missing_pct <- variable_profile$missing_pct %||% 0
  missingness_hint <- variable_profile$missingness_hint %||% "none"
  missing_text <- switch(
    missingness_hint,
    expected = sprintf("; faltantes %.1f%% (esperables)", missing_pct),
    high_unexpected = sprintf("; faltantes %.1f%% (revisar)", missing_pct),
    present = sprintf("; faltantes %.1f%%", missing_pct),
    none = sprintf("; faltantes %.1f%%", missing_pct),
    sprintf("; faltantes %.1f%%", missing_pct)
  )
  render_prefix <- function(semantic_label, style = "legacy") {
    if (identical(style, "numeric_programmatic")) {
      return(sprintf(
        "tipo importado: %s; clasificacion programatica: %s",
        imported_type,
        semantic_label
      ))
    }

    sprintf("importada como %s; interpretada como %s", imported_type, semantic_label)
  }

  if (identical(inferred_type, "identifier")) {
    return(sprintf(
      "- %s: %s; unicidad aproximada %.1f%%; patron aproximado: %s%s.",
      name,
      render_prefix("identificador"),
      summary$approximate_uniqueness %||% 0,
      summary$approximate_pattern %||% "alfanumerico estructurado",
      missing_text
    ))
  }

  if (identical(inferred_type, "categorical")) {
    visible_values <- summary$values %||% character(0)
    max_value_length <- if (length(visible_values) == 0) 0 else max(nchar(visible_values), na.rm = TRUE)
    categorical_label <- if (identical(summary$value_shape %||% NULL, "compound_delimited")) {
      "categorica compuesta"
    } else {
      "categorica"
    }
    top_label <- if (identical(summary$value_shape %||% NULL, "compound_delimited")) "top etiquetas" else "top niveles"
    values_label <- if (identical(summary$value_shape %||% NULL, "compound_delimited")) "etiquetas observadas" else "valores observados"
    if (
      identical(mode, "conservative") &&
      !isTRUE(summary$values_redacted) &&
      !identical(role_guess, "sensitive") &&
      max_value_length > 4
    ) {
      return(sprintf(
        "- %s: %s; niveles observados: %s; valores no listados por modo conservador%s.",
        name,
        render_prefix(categorical_label),
        summary$level_count %||% length(summary$values %||% character(0)),
        missing_text
      ))
    }
    if (isTRUE(summary$values_redacted)) {
      return(sprintf(
        "- %s: %s; niveles observados: %s; valores no listados por seguridad%s.",
        name,
        render_prefix(paste(categorical_label, "sensible")),
        summary$level_count %||% 0,
        missing_text
      ))
    }
    if (!is.null(summary$values)) {
      return(sprintf(
        "- %s: %s; %s: %s%s.",
        name,
        render_prefix(categorical_label),
        values_label,
        paste(ai_profile_quote_values(summary$values), collapse = ", "),
        missing_text
      ))
    }
    return(sprintf(
      "- %s: %s; niveles observados: %s; %s: %s%s.",
      name,
      render_prefix(categorical_label),
      summary$level_count %||% 0,
      top_label,
      paste(ai_profile_quote_values(summary$top_levels %||% character(0)), collapse = ", "),
      missing_text
    ))
  }

  if (identical(inferred_type, "numeric")) {
    suffix <- if (!identical(role_guess, "analytic")) {
      sprintf("; posible %s", gsub("_", " ", role_guess))
    } else {
      ""
    }
    numeric_label <- switch(
      summary$numeric_kind %||% "double",
      integer = "numerica entera",
      double = "numerica decimal",
      "numerica"
    )
    return(sprintf(
      "- %s: %s%s%s; rango aproximado %s-%s%s%s.",
      name,
      render_prefix(numeric_label, style = "numeric_programmatic"),
      if (length(summary$observed_evidence %||% character(0)) > 0) {
        sprintf("; evidencia observada: %s", paste(summary$observed_evidence, collapse = "; "))
      } else {
        ""
      },
      if (length(summary$heuristic_signal %||% character(0)) > 0) {
        sprintf("; senal heuristica: %s", paste(summary$heuristic_signal, collapse = "; "))
      } else {
        ""
      },
      format(summary$min, trim = TRUE, scientific = FALSE),
      format(summary$max, trim = TRUE, scientific = FALSE),
      suffix,
      missing_text
    ))
  }

  if (identical(inferred_type, "date") || identical(inferred_type, "datetime")) {
    detail <- if (!is.null(variable_profile$observed_pattern)) {
      sprintf("; formato observado %s", variable_profile$observed_pattern)
    } else {
      ""
    }
    granularity <- if (!is.null(summary$granularity)) {
      sprintf("; granularidad %s", summary$granularity)
    } else {
      ""
    }
    return(sprintf(
      "- %s: %s%s%s; rango aproximado %s%s.",
      name,
      render_prefix(if (identical(inferred_type, "date")) "fecha" else "fecha-hora"),
      detail,
      granularity,
      summary$range %||% "no disponible",
      missing_text
    ))
  }

  if (identical(inferred_type, "free_text")) {
    return(sprintf(
      "- %s: %s; longitud tipica %s; alta variabilidad; no se incluyen ejemplos por seguridad%s.",
      name,
      render_prefix("texto libre"),
      summary$typical_length %||% "no disponible",
      missing_text
    ))
  }

  if (identical(inferred_type, "entity_label")) {
    uniqueness_label <- if ((summary$approximate_uniqueness %||% 0) >= 80) {
      "alta unicidad"
    } else {
      "unicidad moderada"
    }
    return(sprintf(
      "- %s: %s; %s; longitud tipica %s; no se incluyen ejemplos reales por seguridad%s.",
      name,
      render_prefix("etiqueta nominal de entidad"),
      uniqueness_label,
      summary$typical_length %||% "no disponible",
      missing_text
    ))
  }

  if (identical(inferred_type, "collection")) {
    element_label <- switch(
      summary$element_type %||% "unknown",
      character = "texto",
      integer = "enteros",
      double = "numeros decimales",
      unknown = "elementos",
      summary$element_type %||% "elementos"
    )
    collection_detail <- switch(
      summary$collection_cardinality %||% "variable",
      mostly_empty = "muchas filas vacias",
      single_value = "como maximo un elemento por fila",
      variable = "cardinalidad variable",
      "cardinalidad variable"
    )
    return(sprintf(
      "- %s: %s; contiene colecciones de %s por fila; %s%s.",
      name,
      render_prefix("columna lista"),
      element_label,
      collection_detail,
      missing_text
    ))
  }

  sprintf("- %s: %s%s.", name, render_prefix(sprintf("tipo inferido %s", inferred_type)), missing_text)
}

render_dataset_profile_for_ai <- function(profile, mode = "compact") {
  stopifnot(is.list(profile), !is.null(profile$variables))
  if (!mode %in% c("compact", "conservative")) {
    stop("`mode` debe ser 'compact' o 'conservative'.")
  }

  lines <- c(
    sprintf("Dataset: %s", profile$dataset_name %||% "dataset"),
    sprintf(
      "Dimensiones: %s filas, %s columnas",
      profile$dimensions$rows %||% 0,
      profile$dimensions$cols %||% 0
    )
  )

  if (!is.null(profile$source_context$type)) {
    source_label <- switch(
      profile$source_context$source %||% "declared_by_user",
      declared_by_user = "Fuente declarada por el usuario",
      detected_from_file = "Fuente inferida desde archivo",
      "Fuente de origen"
    )
    lines <- c(
      lines,
      sprintf("%s: %s.", source_label, profile$source_context$type)
    )
  }

  if (identical(profile$source_metadata$status %||% NULL, "matched")) {
    lines <- c(
      lines,
      sprintf(
        "Metadata de fuente aplicada: %s (match por %s).",
        profile$source_metadata$metadata$display_name %||% "sin nombre",
        profile$source_metadata$matched_by %||% "regla interna"
      )
    )
    if (!is.null(profile$source_metadata$column_resolution$summary)) {
      summary <- profile$source_metadata$column_resolution$summary
      lines <- c(
        lines,
        sprintf(
          "Matching de columnas con metadata: %s exactas, %s normalizadas, %s sin resolver, %s ambiguas.",
          summary$exact %||% 0,
          summary$normalized %||% 0,
          summary$unresolved %||% 0,
          summary$ambiguous %||% 0
        )
      )
    }
  }

  lines <- c(lines, "", "Resumen por variable:")

  variable_lines <- vapply(
    profile$variables,
    function(variable_profile) render_ai_profile_variable(variable_profile, mode = mode),
    character(1)
  )
  lines <- c(lines, variable_lines)

  if (length(profile$source_alerts %||% character(0)) > 0) {
    lines <- c(lines, "", "Alertas de consistencia respecto del origen:")
    lines <- c(lines, paste0("- ", profile$source_alerts))
  }

  warnings <- unique(profile$warnings)
  if (length(warnings) > 0) {
    lines <- c(lines, "", "Advertencias:")
    lines <- c(lines, paste0("- ", warnings))
  }

  if (length(profile$config_applied %||% list()) > 0) {
    lines <- c(lines, "", "Reglas declaradas por usuario:")
    config_lines <- vapply(
      names(profile$config_applied),
      function(column_name) {
        sprintf("- %s: %s", column_name, paste(profile$config_applied[[column_name]], collapse = ", "))
      },
      character(1)
    )
    lines <- c(lines, config_lines)
  }

  paste(lines, collapse = "\n")
}

resumen_de <- function(
  data,
  nombre_dataset = NULL,
  config = NULL,
  tipo_fuente = NULL,
  archivo_fuente = NULL,
  metadata_dir = NULL,
  modo = "normal",
  salida = "texto"
) {
  if (!is.data.frame(data)) {
    stop("`data` debe ser un data.frame o tibble.")
  }

  modos_validos <- c("normal", "conservador")
  if (!modo %in% modos_validos) {
    stop(sprintf(
      "`modo = '%s'` no es valido. Valores aceptados: %s.",
      modo,
      paste(modos_validos, collapse = ", ")
    ))
  }

  salidas_validas <- c("texto", "estructura")
  if (!salida %in% salidas_validas) {
    stop(sprintf(
      "`salida = '%s'` no es valida. Valores aceptados: %s.",
      salida,
      paste(salidas_validas, collapse = ", ")
    ))
  }

  dataset_name <- nombre_dataset %||% deparse(substitute(data))
  render_mode <- switch(
    modo,
    normal = "compact",
    conservador = "conservative"
  )

  profile <- profile_dataset_for_ai(
    data = data,
    dataset_name = dataset_name,
    config = config,
    tipo_fuente = tipo_fuente,
    archivo_fuente = archivo_fuente,
    metadata_dir = metadata_dir
  )

  if (identical(salida, "estructura")) {
    return(profile)
  }

  render_dataset_profile_for_ai(profile, mode = render_mode)
}
