# Render textual del perfil seguro para IA.

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

  if (identical(inferred_type, "empty")) {
    return(sprintf(
      "- %s: tipo importado: %s; sin valores observados; no se infiere contenido%s.",
      name,
      imported_type,
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
    suffix <- if (!identical(role_guess, "analytic") && !identical(role_guess, "normative_code")) {
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

  if (identical(inferred_type, "period")) {
    detail <- if (!is.null(variable_profile$observed_pattern)) {
      sprintf("; formato observado %s", variable_profile$observed_pattern)
    } else {
      ""
    }
    return(sprintf(
      "- %s: %s%s; rango aproximado %s%s.",
      name,
      render_prefix("periodo"),
      detail,
      summary$range %||% "no disponible",
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

  if (identical(inferred_type, "code_description")) {
    associated_column <- summary$associated_column %||% "no identificada"
    return(sprintf(
      "- %s: %s; columna asociada: %s; longitud tipica %s; no se incluyen ejemplos por seguridad%s.",
      name,
      render_prefix("descripcion de codigo"),
      associated_column,
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

render_ai_profile_granularity <- function(granularity) {
  if (!isTRUE(granularity$available) || length(granularity$identifier_summaries %||% list()) == 0) {
    return(character(0))
  }

  lines <- "Granularidad observada:"
  identifier_groups <- granularity$identifier_groups %||% list()
  composite_summaries <- granularity$composite_summaries %||% list()
  temporal_signals <- granularity$temporal_signals %||% list()

  grouped_identifier_columns <- unique(unlist(
    lapply(identifier_groups, `[[`, "columns"),
    use.names = FALSE
  ))

  if (length(identifier_groups) > 0) {
    lines <- c(lines, "- Identificadores equivalentes detectados:")
    group_lines <- vapply(
      identifier_groups,
      function(group) {
        sprintf("  %s: %s.", group$entity, paste(group$columns, collapse = ", "))
      },
      character(1)
    )
    lines <- c(lines, group_lines)
  }

  if (length(composite_summaries) > 0) {
    best_summary <- composite_summaries[[order(
      -vapply(composite_summaries, `[[`, numeric(1), "unique_row_pct"),
      vapply(composite_summaries, `[[`, numeric(1), "duplicate_rows_remaining")
    )[[1]]]]
    lines <- c(
      lines,
      "- Unidad de observacion candidata:",
      sprintf(
        "  %s; %.1f%% de filas quedan unicas con esta combinacion.",
        best_summary$label,
        best_summary$unique_row_pct
      )
    )
  }

  if (length(temporal_signals) > 0) {
    signal <- temporal_signals[[1]]
    lines <- c(
      lines,
      "- Senal temporal:",
      sprintf(
        "  %s parece representar periodos; hay multiples periodos por %s.",
        signal$period_column,
        signal$base_label
      )
    )
  }

  nearly_unique_identifiers <- vapply(
    granularity$identifier_summaries,
    function(identifier_summary) {
      unique_pct <- if ((identifier_summary$rows_considered %||% 0) > 0) {
        identifier_summary$distinct_identifiers / identifier_summary$rows_considered * 100
      } else {
        0
      }
      if (
        unique_pct >= 95 &&
          !identifier_summary$identifier_column %in% grouped_identifier_columns
      ) {
        identifier_summary$identifier_column
      } else {
        NA_character_
      }
    },
    character(1)
  )
  nearly_unique_identifiers <- nearly_unique_identifiers[!is.na(nearly_unique_identifiers)]
  if (length(nearly_unique_identifiers) > 0) {
    lines <- c(
      lines,
      sprintf("- Otros identificadores casi unicos: %s.", paste(nearly_unique_identifiers, collapse = ", "))
    )
  }

  if (length(identifier_groups) > 0 || length(composite_summaries) > 0 || length(temporal_signals) > 0) {
    return(lines)
  }

  for (identifier_summary in granularity$identifier_summaries) {
    lines <- c(
      lines,
      sprintf(
        "- %s: %s identificadores distintos en %s filas; filas por identificador: promedio %s, mediana %s, maximo %s; %.1f%% de identificadores tienen multiples filas.",
        identifier_summary$identifier_column,
        identifier_summary$distinct_identifiers,
        identifier_summary$rows_considered,
        format(identifier_summary$mean_rows_per_identifier, trim = TRUE, scientific = FALSE),
        format(identifier_summary$median_rows_per_identifier, trim = TRUE, scientific = FALSE),
        format(identifier_summary$max_rows_per_identifier, trim = TRUE, scientific = FALSE),
        identifier_summary$multirow_identifier_pct
      )
    )

    candidates <- identifier_summary$candidate_columns %||% list()
    if (length(candidates) > 0) {
      candidate_details <- vapply(
        candidates,
        function(candidate) {
          sprintf(
            "%s (%.1f%% de filas quedan unicas al combinarla con el identificador)",
            candidate$column,
            candidate$unique_row_pct
          )
        },
        character(1)
      )
      lines <- c(
        lines,
        sprintf(
          "- Variables candidatas para refinar granularidad: %s.",
          paste(candidate_details, collapse = ", ")
        )
      )
    }
  }

  lines
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

  granularity_lines <- render_ai_profile_granularity(profile$granularity %||% list())
  if (length(granularity_lines) > 0) {
    lines <- c(lines, "", granularity_lines)
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

