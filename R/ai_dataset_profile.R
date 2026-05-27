ai_profile_identifier_name <- function(column_name) {
  normalized_name <- ai_profile_normalize_column_name(column_name)
  if (ai_profile_identifier_negative_name(column_name)) {
    return(FALSE)
  }

  grepl(
    "(^|_)(id|rut|cedula|dni|nie|nic|nro|numero)(_|$)|identificador|documento|solicitud|persona_id|pers_id|pers_identificador|expediente|matricula|correo|mail|email|e_mail|telefono|celular|nro_empresa|nro_int_emp|nro_int_contr|nro_contribuyente|nro_solicitud|id_solicitud|(^|_)titulo($|_)",
    normalized_name
  )
}

ai_profile_identifier_negative_name <- function(column_name) {
  normalized_name <- ai_profile_normalize_column_name(column_name)
  grepl(
    "fecha|date|deuda|monto|saldo|importe|valor|cantidad|cant|porcentaje|tasa|juicio|estado|marca|descripcion|desc|tipo_estado|^tipo_documento$|etapa|^tipo_titulo$|^nro_art$|articulo|ley|norma",
    normalized_name
  )
}

ai_profile_phone_like_name <- function(column_name) {
  normalized_name <- ai_profile_normalize_column_name(column_name)
  grepl("telefono|celular|phone|movil|tel_contacto", normalized_name)
}

ai_profile_period_name <- function(column_name) {
  normalized_name <- ai_profile_normalize_column_name(column_name)
  grepl("periodo|period|mes_anio|anio_mes|yyyymm", normalized_name)
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

ai_profile_normative_code_name <- function(column_name) {
  normalized_name <- ai_profile_normalize_column_name(column_name)
  grepl("(^|_)nro_art($|_)|(^|_)articulo($|_)|(^|_)ley($|_)|norma|normativa", normalized_name)
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

ai_profile_is_granularity_candidate <- function(variable_profile) {
  inferred_type <- variable_profile$inferred_type %||% NULL
  role_guess <- variable_profile$role_guess %||% NULL

  if (identical(inferred_type, "identifier") || identical(role_guess, "identifier")) {
    return(FALSE)
  }

  if (inferred_type %in% c("categorical", "period")) {
    return(TRUE)
  }

  if (identical(role_guess, "normative_code")) {
    return(TRUE)
  }

  FALSE
}

ai_profile_candidate_uniqueness <- function(identifier_values, candidate_values) {
  usable <- !is.na(identifier_values) & !is.na(candidate_values)
  if (!any(usable)) {
    return(NULL)
  }

  keys <- paste(
    as.character(identifier_values[usable]),
    as.character(candidate_values[usable]),
    sep = "\r"
  )
  combination_counts <- table(keys)
  row_counts <- unname(combination_counts[keys])

  list(
    rows_considered = length(keys),
    distinct_combinations = length(combination_counts),
    unique_row_pct = round(mean(row_counts == 1) * 100, 1),
    duplicate_rows_remaining = sum(row_counts > 1)
  )
}

ai_profile_identifier_entity <- function(column_name) {
  normalized_name <- ai_profile_normalize_column_name(column_name)

  if (grepl("empresa|(^|_)emp($|_)", normalized_name)) {
    return("empresa")
  }
  if (grepl("contrib|(^|_)contr($|_)|(^|_)cont($|_)|(^|_)rut($|_)|(^|_)ruc($|_)", normalized_name)) {
    return("contribuyente")
  }
  if (grepl("(^|_)pers($|_)|(^|_)pers_id($|_)|pers_identificador|persona", normalized_name)) {
    return("persona")
  }
  if (grepl("documento|cedula|dni|nie", normalized_name)) {
    return("documento_persona")
  }
  if (grepl("solicitud", normalized_name)) {
    return("solicitud")
  }
  if (grepl("(^|_)titulo($|_)", normalized_name)) {
    return("titulo")
  }

  column_name
}

ai_profile_columns_matching_normalized <- function(data_names, normalized_targets) {
  normalized_names <- vapply(data_names, ai_profile_normalize_column_name, character(1))
  unname(data_names[match(normalized_targets, normalized_names, nomatch = 0L)])
}

ai_profile_build_identifier_groups <- function(data, identifier_columns) {
  if (length(identifier_columns) == 0) {
    return(list())
  }

  grouped_columns <- split(identifier_columns, vapply(identifier_columns, ai_profile_identifier_entity, character(1)))
  group_names <- intersect(c("empresa", "contribuyente", "persona", "solicitud"), names(grouped_columns))

  groups <- lapply(group_names, function(entity) {
    columns <- grouped_columns[[entity]]
    distinct_counts <- vapply(
      columns,
      function(column_name) {
        values <- data[[column_name]]
        length(unique(as.character(values[!is.na(values)])))
      },
      integer(1)
    )

    list(
      entity = entity,
      columns = columns,
      representative_column = columns[[1]],
      distinct_identifiers = max(distinct_counts, na.rm = TRUE)
    )
  })

  document_columns <- ai_profile_columns_matching_normalized(names(data), c("td", "pais", "documento"))
  if (length(document_columns) == 3) {
    document_parts <- lapply(document_columns, function(column_name) data[[column_name]])
    usable_document <- Reduce(`&`, lapply(document_parts, function(values) !is.na(values)))
    document_values <- do.call(
      paste,
      c(lapply(document_parts, function(values) as.character(values[usable_document])), sep = "\r")
    )
    groups <- c(
      groups,
      list(list(
        entity = "documento_persona",
        columns = document_columns,
        representative_column = document_columns[[3]],
        distinct_identifiers = length(unique(document_values))
      ))
    )
  }

  groups[vapply(groups, function(group) {
    group$entity %in% c("empresa", "contribuyente", "persona", "documento_persona", "solicitud") &&
      length(group$columns) > 0
  }, logical(1))]
}

ai_profile_granularity_key_summary <- function(data, columns, label, role) {
  if (length(columns) == 0 || !all(columns %in% names(data))) {
    return(NULL)
  }

  key_parts <- lapply(columns, function(column_name) data[[column_name]])
  usable <- Reduce(`&`, lapply(key_parts, function(values) !is.na(values)))
  if (!any(usable)) {
    return(NULL)
  }

  keys <- do.call(
    paste,
    c(lapply(key_parts, function(values) as.character(values[usable])), sep = "\r")
  )
  counts <- table(keys)
  row_counts <- unname(counts[keys])

  list(
    role = role,
    label = label,
    columns = columns,
    rows_considered = length(keys),
    distinct_keys = length(counts),
    unique_row_pct = round(mean(row_counts == 1) * 100, 1),
    duplicate_rows_remaining = sum(row_counts > 1),
    max_rows_per_key = max(counts)
  )
}

ai_profile_aportacion_columns <- function(data_names) {
  normalized <- vapply(data_names, ai_profile_normalize_column_name, character(1))
  data_names[grepl("^tipo_aportacion$|^ta$|aportacion", normalized)]
}

ai_profile_period_columns <- function(variable_profiles) {
  names(variable_profiles)[vapply(
    variable_profiles,
    function(variable_profile) {
      identical(variable_profile$inferred_type, "period") ||
        grepl("mes_cargo|anio_mes|ano_mes", ai_profile_normalize_column_name(variable_profile$name))
    },
    logical(1)
  )]
}

ai_profile_build_composite_summaries <- function(data, identifier_groups, variable_profiles) {
  if (length(identifier_groups) == 0) {
    return(list())
  }

  entity_columns <- stats::setNames(
    vapply(identifier_groups, `[[`, character(1), "representative_column"),
    vapply(identifier_groups, `[[`, character(1), "entity")
  )

  aportacion_columns <- ai_profile_aportacion_columns(names(data))
  period_columns <- ai_profile_period_columns(variable_profiles)
  summaries <- list()
  group_columns_by_entity <- stats::setNames(
    lapply(identifier_groups, `[[`, "columns"),
    vapply(identifier_groups, `[[`, character(1), "entity")
  )

  if (all(c("empresa", "contribuyente") %in% names(entity_columns))) {
    summaries <- c(
      summaries,
      list(ai_profile_granularity_key_summary(
        data = data,
        columns = unname(entity_columns[c("empresa", "contribuyente")]),
        label = "empresa + contribuyente",
        role = "entidad"
      ))
    )
  }

  if (all(c("empresa", "contribuyente") %in% names(entity_columns)) && length(aportacion_columns) > 0) {
    aportacion_column <- aportacion_columns[[1]]
    entity_aportacion_columns <- c(unname(entity_columns[c("empresa", "contribuyente")]), aportacion_column)
    summaries <- c(
      summaries,
      list(ai_profile_granularity_key_summary(
        data = data,
        columns = entity_aportacion_columns,
        label = paste("empresa + contribuyente", aportacion_column, sep = " + "),
        role = "entidad_aportacion"
      ))
    )

    if (length(period_columns) > 0) {
      summaries <- c(
        summaries,
        lapply(period_columns, function(period_column) {
          ai_profile_granularity_key_summary(
            data = data,
            columns = c(entity_aportacion_columns, period_column),
            label = paste("empresa + contribuyente", aportacion_column, period_column, sep = " + "),
            role = "entidad_aportacion_periodo"
          )
        })
      )
    }
  }

  persona_columns <- if ("persona" %in% names(group_columns_by_entity)) {
    group_columns_by_entity[["persona"]][[1]]
  } else if ("documento_persona" %in% names(entity_columns)) {
    group_columns_by_entity[["documento_persona"]]
  } else {
    NULL
  }
  persona_label <- if ("persona" %in% names(entity_columns)) "persona" else "documento_persona"
  if (!is.null(persona_columns) && "empresa" %in% names(entity_columns)) {
    if (length(aportacion_columns) > 0) {
      aportacion_column <- aportacion_columns[[1]]
      summaries <- c(
        summaries,
        list(ai_profile_granularity_key_summary(
          data = data,
          columns = c(unname(entity_columns[["empresa"]]), aportacion_column, unname(persona_columns)),
          label = paste("empresa", aportacion_column, persona_label, sep = " + "),
          role = "empresa_aportacion_persona"
        ))
      )
    } else {
      summaries <- c(
        summaries,
        list(ai_profile_granularity_key_summary(
          data = data,
          columns = c(unname(entity_columns[["empresa"]]), unname(persona_columns)),
          label = paste("empresa", persona_label, sep = " + "),
          role = "empresa_persona"
        ))
      )
    }
  }

  if (!is.null(persona_columns) && "solicitud" %in% names(entity_columns)) {
    summaries <- c(
      summaries,
      list(ai_profile_granularity_key_summary(
        data = data,
        columns = c(unname(entity_columns[["solicitud"]]), unname(persona_columns)),
        label = paste("solicitud", persona_label, sep = " + "),
        role = "solicitud_persona"
      ))
    )
  }

  Filter(Negate(is.null), summaries)
}

ai_profile_build_temporal_signals <- function(data, composite_summaries, variable_profiles) {
  period_columns <- ai_profile_period_columns(variable_profiles)
  if (length(period_columns) == 0 || length(composite_summaries) == 0) {
    return(list())
  }

  base_summaries <- Filter(
    function(summary) identical(summary$role, "entidad_aportacion"),
    composite_summaries
  )
  if (length(base_summaries) == 0) {
    return(list())
  }

  unlist(lapply(base_summaries, function(base_summary) {
    lapply(period_columns, function(period_column) {
      key_summary <- ai_profile_granularity_key_summary(
        data = data,
        columns = base_summary$columns,
        label = base_summary$label,
        role = base_summary$role
      )
      period_summary <- ai_profile_granularity_key_summary(
        data = data,
        columns = c(base_summary$columns, period_column),
        label = paste(base_summary$label, period_column, sep = " + "),
        role = paste0(base_summary$role, "_periodo")
      )
      if (is.null(key_summary) || is.null(period_summary) || key_summary$max_rows_per_key <= 1) {
        return(NULL)
      }

      list(
        base_role = base_summary$role,
        base_label = base_summary$label,
        period_column = period_column,
        base_max_rows_per_key = key_summary$max_rows_per_key,
        period_unique_row_pct = period_summary$unique_row_pct
      )
    })
  }), recursive = FALSE)
}

ai_profile_build_granularity_analysis <- function(data, variable_profiles, max_candidates = 5) {
  identifier_columns <- names(variable_profiles)[vapply(
    variable_profiles,
    function(variable_profile) {
      identical(variable_profile$inferred_type, "identifier") ||
        identical(variable_profile$role_guess, "identifier")
    },
    logical(1)
  )]

  if (length(identifier_columns) == 0) {
    return(list(
      available = FALSE,
      identifier_summaries = list()
    ))
  }

  identifier_groups <- ai_profile_build_identifier_groups(data, identifier_columns)
  composite_summaries <- ai_profile_build_composite_summaries(
    data = data,
    identifier_groups = identifier_groups,
    variable_profiles = variable_profiles
  )
  temporal_signals <- Filter(
    Negate(is.null),
    ai_profile_build_temporal_signals(
      data = data,
      composite_summaries = composite_summaries,
      variable_profiles = variable_profiles
    )
  )

  candidate_columns <- names(variable_profiles)[vapply(
    variable_profiles,
    ai_profile_is_granularity_candidate,
    logical(1)
  )]

  identifier_summaries <- lapply(identifier_columns, function(identifier_column) {
    identifier_values <- data[[identifier_column]]
    usable_identifier <- !is.na(identifier_values)
    identifier_counts <- table(as.character(identifier_values[usable_identifier]))
    rows_considered <- sum(identifier_counts)

    candidate_summaries <- lapply(setdiff(candidate_columns, identifier_column), function(candidate_column) {
      uniqueness <- ai_profile_candidate_uniqueness(
        identifier_values = identifier_values,
        candidate_values = data[[candidate_column]]
      )
      if (is.null(uniqueness)) {
        return(NULL)
      }

      c(
        list(
          column = candidate_column,
          inferred_type = variable_profiles[[candidate_column]]$inferred_type,
          role_guess = variable_profiles[[candidate_column]]$role_guess
        ),
        uniqueness
      )
    })
    candidate_summaries <- Filter(Negate(is.null), candidate_summaries)

    if (length(candidate_summaries) > 0) {
      candidate_order <- order(
        -vapply(candidate_summaries, `[[`, numeric(1), "unique_row_pct"),
        vapply(candidate_summaries, `[[`, numeric(1), "duplicate_rows_remaining"),
        vapply(candidate_summaries, `[[`, character(1), "column")
      )
      candidate_summaries <- candidate_summaries[candidate_order]
      candidate_summaries <- utils::head(candidate_summaries, max_candidates)
    }

    list(
      identifier_column = identifier_column,
      rows_considered = rows_considered,
      distinct_identifiers = length(identifier_counts),
      mean_rows_per_identifier = if (length(identifier_counts) > 0) round(mean(identifier_counts), 1) else NA_real_,
      median_rows_per_identifier = if (length(identifier_counts) > 0) stats::median(identifier_counts) else NA_real_,
      max_rows_per_identifier = if (length(identifier_counts) > 0) max(identifier_counts) else NA_integer_,
      single_row_identifier_pct = if (length(identifier_counts) > 0) round(mean(identifier_counts == 1) * 100, 1) else NA_real_,
      multirow_identifier_pct = if (length(identifier_counts) > 0) round(mean(identifier_counts > 1) * 100, 1) else NA_real_,
      candidate_columns = candidate_summaries
    )
  })

  list(
    available = TRUE,
    identifier_groups = identifier_groups,
    composite_summaries = composite_summaries,
    temporal_signals = temporal_signals,
    identifier_summaries = identifier_summaries
  )
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
        top_n = top_n,
        data_names = names(data)
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
  granularity <- ai_profile_build_granularity_analysis(
    data = data,
    variable_profiles = variable_profiles
  )

  list(
    dataset_name = dataset_name,
    dimensions = list(rows = nrow(data), cols = ncol(data)),
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    source_context = merged_source_context_result$source_context,
    source_metadata = source_metadata,
    source_alerts = source_alerts,
    granularity = granularity,
    variables = variable_profiles,
    config_applied = config_applied,
    warnings = global_warnings
  )
}

# Ejemplo de uso desde RStudio:
# profile <- profile_dataset_for_ai(iris, "iris")
# cat(render_dataset_profile_for_ai(profile))
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
