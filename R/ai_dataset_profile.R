ai_profile_identifier_name <- function(column_name) {
  normalized_name <- ai_profile_normalize_column_name(column_name)
  if (ai_profile_identifier_negative_name(column_name)) {
    return(FALSE)
  }

  grepl(
    "(^|_)(id|rut|cedula|dni|nie|nic|nro|numero)(_|$)|identificador|persona_id|pers_id|expediente|matricula|correo|mail|email|e_mail|telefono|celular|nro_empresa|nro_int_emp|nro_int_contr|nro_contribuyente|(^|_)titulo($|_)",
    normalized_name
  )
}

ai_profile_identifier_negative_name <- function(column_name) {
  normalized_name <- ai_profile_normalize_column_name(column_name)
  grepl(
    "deuda|monto|saldo|importe|valor|cantidad|cant|porcentaje|tasa|juicio|estado|marca|descripcion|desc|tipo_estado|etapa|^tipo_titulo$|^nro_art$|articulo|ley|norma",
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
