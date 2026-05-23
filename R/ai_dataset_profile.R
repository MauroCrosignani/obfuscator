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

ai_profile_observed_temporal_pattern <- function(values) {
  values <- as.character(values)
  values <- values[nzchar(trimws(values))]
  if (length(values) == 0) {
    return(NULL)
  }

  if (all(grepl("^\\d{4}-\\d{2}-\\d{2}[ T]\\d{2}:\\d{2}:\\d{2}[\\.,]\\d+$", values))) {
    return("YYYY-mm-dd HH:MM:SS.ffffff")
  }
  if (all(grepl("^\\d{4}-\\d{2}-\\d{2}[ T]\\d{2}:\\d{2}:\\d{2}$", values))) {
    return("YYYY-mm-dd HH:MM:SS")
  }
  if (all(grepl("^\\d{4}-\\d{2}-\\d{2}$", values))) {
    return("YYYY-mm-dd")
  }

  NULL
}

ai_profile_detect_compound_delimiter <- function(values) {
  values <- as.character(values)
  values <- trimws(values)
  values <- values[nzchar(values)]
  if (length(values) == 0) {
    return(NULL)
  }

  delimiters <- c(",", ";")
  for (delimiter in delimiters) {
    hits <- grepl(delimiter, values, fixed = TRUE)
    if (sum(hits) >= 2 && mean(hits) >= 0.03) {
      return(delimiter)
    }
  }

  NULL
}

ai_profile_looks_like_nominal_high_cardinality <- function(values, max_levels) {
  values <- as.character(values)
  values <- trimws(values)
  values <- values[nzchar(values)]
  if (length(values) == 0) {
    return(FALSE)
  }

  unique_values <- unique(values)
  if (length(unique_values) <= max_levels) {
    return(FALSE)
  }

  max_length <- max(nchar(values), na.rm = TRUE)
  avg_words <- mean(lengths(strsplit(values, "\\s+")))
  punctuation_rate <- mean(grepl("[\\.!\\?;:]", values))

  max_length <= 30 && avg_words <= 3 && punctuation_rate < 0.1
}

ai_profile_looks_like_entity_label <- function(column_name, values) {
  values <- as.character(values)
  values <- trimws(values)
  values <- values[nzchar(values)]
  if (length(values) == 0) {
    return(FALSE)
  }

  unique_ratio <- length(unique(values)) / length(values)
  max_length <- max(nchar(values), na.rm = TRUE)
  word_counts <- lengths(strsplit(values, "\\s+"))
  avg_words <- mean(word_counts)
  punctuation_rate <- mean(grepl("[\\.!\\?;:]", values))
  digit_rate <- mean(grepl("\\d", values))
  title_case_rate <- mean(grepl("^[[:upper:]][[:alpha:]'`.-]*( [[:upper:]][[:alpha:]'`.-]*)*$", values))
  uppercase_label_rate <- mean(grepl("^[[:upper:]0-9'`.,()/-]+( [[:upper:]0-9'`.,()/-]+)*$", values))
  explicit_name_hint <- grepl(
    "(^|_)(name|nombre|label|etiqueta|title|titulo|cliente|persona|paciente|proveedor|unidad|oficina|gerencia|division|departamento|sector|area)($|_)",
    column_name,
    ignore.case = TRUE
  )

  base_shape_match <- max_length <= 60 &&
    avg_words >= 1.5 &&
    avg_words <= 6 &&
    punctuation_rate < 0.05 &&
    digit_rate < 0.2

  repeated_institutional_label <- explicit_name_hint &&
    uppercase_label_rate >= 0.6 &&
    unique_ratio >= 0.4 &&
    length(unique(values)) >= 3

  canonical_entity_label <- unique_ratio >= 0.7 &&
    (title_case_rate >= 0.6 || explicit_name_hint || uppercase_label_rate >= 0.6)

  base_shape_match && (canonical_entity_label || repeated_institutional_label)
}

ai_profile_posix_has_substantive_time <- function(x) {
  if (!inherits(x, c("POSIXct", "POSIXlt", "POSIXt"))) {
    return(TRUE)
  }

  lt <- as.POSIXlt(x)
  any((lt$hour %||% 0) != 0 | (lt$min %||% 0) != 0 | (lt$sec %||% 0) != 0, na.rm = TRUE)
}

ai_profile_collection_element_type <- function(x) {
  if (!is.list(x)) {
    return(NULL)
  }

  flattened <- unlist(x, recursive = FALSE, use.names = FALSE)
  if (length(flattened) == 0) {
    return("unknown")
  }

  non_missing <- flattened[!vapply(flattened, function(value) {
    length(value) == 1 && is.na(value)
  }, logical(1))]
  if (length(non_missing) == 0) {
    return("unknown")
  }

  if (all(vapply(non_missing, is.character, logical(1)))) {
    return("character")
  }
  if (all(vapply(non_missing, is.integer, logical(1)))) {
    return("integer")
  }
  if (all(vapply(non_missing, is.numeric, logical(1)))) {
    return("double")
  }

  "unknown"
}

ai_profile_collection_cardinality <- function(x) {
  if (!is.list(x)) {
    return(NULL)
  }

  sizes <- vapply(x, length, integer(1))
  if (length(sizes) == 0) {
    return("empty")
  }
  if (all(sizes == 0)) {
    return("mostly_empty")
  }
  if (mean(sizes == 0) >= 0.4) {
    return("mostly_empty")
  }
  if (all(sizes <= 1)) {
    return("single_value")
  }
  "variable"
}

ai_profile_identifier_content <- function(values) {
  values <- as.character(values)
  values <- values[nzchar(trimws(values))]
  if (length(values) == 0) {
    return(NULL)
  }

  if (all(grepl("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", values))) {
    return(list(
      inferred_type = "identifier",
      observed_pattern = "email",
      warnings = "No se incluiran ejemplos literales de correos electronicos.",
      confidence = "high"
    ))
  }

  if (all(grepl("^\\+?[0-9][0-9\\-\\s]{7,}$", values))) {
    return(list(
      inferred_type = "identifier",
      observed_pattern = "phone",
      warnings = "No se incluiran ejemplos literales de telefonos.",
      confidence = "high"
    ))
  }

  if (all(grepl("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", values))) {
    return(list(
      inferred_type = "identifier",
      observed_pattern = "uuid",
      warnings = "No se incluiran ejemplos literales de identificadores unicos.",
      confidence = "high"
    ))
  }

  NULL
}

ai_profile_temporal_granularity <- function(observed_pattern, inferred_type) {
  if (is.null(observed_pattern)) {
    if (identical(inferred_type, "date")) {
      return("dia")
    }
    if (identical(inferred_type, "datetime")) {
      return("segundos")
    }
    return(NULL)
  }

  if (identical(observed_pattern, "YYYY-mm-dd")) {
    return("dia")
  }
  if (identical(observed_pattern, "YYYY-mm-dd HH:MM:SS")) {
    return("segundos")
  }
  if (identical(observed_pattern, "YYYY-mm-dd HH:MM:SS.ffffff")) {
    return("microsegundos")
  }

  "ambigua"
}

ai_profile_infer_type <- function(column_name, x, max_levels = 12) {
  imported_type <- ai_profile_imported_type(x)
  values <- ai_profile_non_missing_values(x)
  n_values <- length(values)
  observed_pattern <- NULL
  warnings <- character(0)
  confidence <- "medium"

  if (n_values == 0) {
    return(list(
      inferred_type = "unknown",
      observed_pattern = NULL,
      warnings = "La columna no tiene valores no faltantes para inferencia.",
      confidence = "low"
    ))
  }

  if (ai_profile_identifier_name(column_name)) {
    return(list(
      inferred_type = "identifier",
      observed_pattern = NULL,
      warnings = "No se incluiran ejemplos literales de identificadores.",
      confidence = "high"
    ))
  }

  if (inherits(x, c("POSIXct", "POSIXlt", "POSIXt"))) {
    return(list(
      inferred_type = if (ai_profile_posix_has_substantive_time(x)) "datetime" else "date",
      observed_pattern = "POSIXt",
      warnings = character(0),
      confidence = "high"
    ))
  }

  if (inherits(x, "Date")) {
    return(list(
      inferred_type = "date",
      observed_pattern = "Date",
      warnings = character(0),
      confidence = "high"
    ))
  }

  if (is.list(x)) {
    return(list(
      inferred_type = "collection",
      observed_pattern = NULL,
      warnings = "Se detectaron columnas lista; la salida describira su estructura sin expandir sus elementos.",
      confidence = "high"
    ))
  }

  if (is.character(x) || is.factor(x)) {
    identifier_by_content <- ai_profile_identifier_content(values)
    if (!is.null(identifier_by_content)) {
      return(identifier_by_content)
    }

    observed_pattern <- ai_profile_observed_temporal_pattern(values)
    if (!is.null(observed_pattern)) {
      warnings <- c(
        warnings,
        "La columna parece temporal, pero llego como texto y puede requerir normalizacion de parseo."
      )
      return(list(
        inferred_type = if (grepl("HH:MM:SS", observed_pattern, fixed = TRUE)) "datetime" else "date",
        observed_pattern = observed_pattern,
        warnings = warnings,
        confidence = "high"
      ))
    }

    if (ai_profile_looks_like_entity_label(column_name, values)) {
      return(list(
        inferred_type = "entity_label",
        observed_pattern = NULL,
        warnings = "Se detectaron nombres o etiquetas de entidad; no se incluiran ejemplos reales por seguridad.",
        confidence = "high"
      ))
    }

    unique_values <- unique(as.character(values))
    max_length <- if (length(values) == 0) 0 else max(nchar(as.character(values)), na.rm = TRUE)
    if ((length(unique_values) <= max_levels && max_length <= 12) ||
        (max_length <= 4 && length(unique_values) <= max(20L, n_values))) {
      return(list(
        inferred_type = "categorical",
        observed_pattern = NULL,
        warnings = warnings,
        confidence = "medium"
      ))
    }

    if (ai_profile_text_like_column(x)) {
      return(list(
        inferred_type = "free_text",
        observed_pattern = NULL,
        warnings = "Se detectaron columnas de texto libre; no se incluiran ejemplos reales por seguridad.",
        confidence = "high"
      ))
    }

    if (length(unique_values) <= max(12L, floor(n_values * 0.5))) {
      return(list(
        inferred_type = "categorical",
        observed_pattern = NULL,
        warnings = warnings,
        confidence = "medium"
      ))
    }

    if (ai_profile_looks_like_nominal_high_cardinality(values, max_levels = max_levels)) {
      return(list(
        inferred_type = "categorical",
        observed_pattern = NULL,
        warnings = warnings,
        confidence = "medium"
      ))
    }
  }

  if (is.numeric(x)) {
    return(list(
      inferred_type = "numeric",
      observed_pattern = NULL,
      warnings = warnings,
      confidence = "high"
    ))
  }

  list(
    inferred_type = "unknown",
    observed_pattern = observed_pattern,
    warnings = warnings,
    confidence = confidence
  )
}

ai_profile_identifier_pattern <- function(values) {
  values <- as.character(values)
  values <- values[nzchar(trimws(values))]
  if (length(values) == 0) {
    return("alfanumerico estructurado")
  }

  if (all(grepl("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", values))) {
    return("correo electronico")
  }

  if (all(grepl("^\\+?[0-9][0-9\\-\\s]{7,}$", values))) {
    return("telefono")
  }

  if (all(grepl("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", values))) {
    return("uuid")
  }

  if (all(grepl("^[A-Za-z]+[-_]?\\d+$", values))) {
    digit_counts <- unique(nchar(sub("^.*?([0-9]+)$", "\\1", values)))
    if (length(digit_counts) == 1) {
      if (any(grepl("[-_]", values))) {
        return(sprintf("prefijo alfabetico + separador + %s digitos", digit_counts))
      }
      return(sprintf("prefijo alfabetico + %s digitos", digit_counts))
    }
    return("prefijo alfabetico + digitos")
  }

  if (all(grepl("^\\d+$", values))) {
    widths <- nchar(values)
    return(sprintf("solo digitos; largo aproximado %s-%s", min(widths), max(widths)))
  }

  "alfanumerico estructurado"
}

ai_profile_temporal_range <- function(values, inferred_type) {
  values <- as.character(values)
  values <- values[nzchar(trimws(values))]
  if (length(values) == 0) {
    return(NULL)
  }

  if (identical(inferred_type, "date")) {
    return(sprintf("%s a %s", min(values), max(values)))
  }

  if (identical(inferred_type, "datetime")) {
    range_values <- range(values)
    return(sprintf("%s a %s", substr(range_values[1], 1, 19), substr(range_values[2], 1, 19)))
  }

  NULL
}

ai_profile_role_guess <- function(column_name, inferred_type, x) {
  if (identical(inferred_type, "identifier")) {
    return("identifier")
  }
  if (identical(inferred_type, "free_text")) {
    return("free_text")
  }
  if (identical(inferred_type, "entity_label")) {
    return("entity_label")
  }
  if (ai_profile_sensitive_name(column_name)) {
    return("sensitive")
  }
  if (identical(inferred_type, "date") || identical(inferred_type, "datetime")) {
    return("quasi_identifier")
  }
  if (identical(inferred_type, "numeric") && ai_profile_quasi_identifier_name(column_name)) {
    return("quasi_identifier")
  }
  if (identical(inferred_type, "categorical") && ai_profile_quasi_identifier_name(column_name)) {
    return("quasi_identifier")
  }
  if (identical(inferred_type, "numeric") || identical(inferred_type, "categorical")) {
    return("analytic")
  }
  "unknown"
}

ai_profile_missingness_hint <- function(column_name, missing_pct) {
  if (ai_profile_expected_missingness_name(column_name) && missing_pct > 0) {
    return("expected")
  }
  if (missing_pct >= 40) {
    return("high_unexpected")
  }
  if (missing_pct > 0) {
    return("present")
  }
  "none"
}

ai_profile_config_rules_for_column <- function(column_name, config) {
  rules <- names(config)[vapply(config, function(values) column_name %in% values, logical(1))]
  rules
}

ai_profile_apply_config_overrides <- function(column_name, inferred_type, role_guess, missingness_hint, config) {
  applied_rules <- ai_profile_config_rules_for_column(column_name, config)
  warnings <- character(0)

  classification_rules <- intersect(
    applied_rules,
    c("columnas_identificatorias", "columnas_texto_libre", "columnas_sensibles")
  )

  if (length(classification_rules) > 1) {
    warnings <- c(
      warnings,
      sprintf(
        "La columna '%s' aparece en categorias incompatibles; se prioriza 'columnas_identificatorias', luego 'columnas_texto_libre' y luego 'columnas_sensibles'.",
        column_name
      )
    )
  }

  classification_source <- "inferred_automatically"
  missingness_source <- "inferred_automatically"

  final_inferred_type <- inferred_type
  final_role_guess <- role_guess
  final_missingness_hint <- missingness_hint

  if ("columnas_identificatorias" %in% applied_rules) {
    final_inferred_type <- "identifier"
    final_role_guess <- "identifier"
    classification_source <- "declared_by_user"
  } else if ("columnas_texto_libre" %in% applied_rules) {
    final_inferred_type <- "free_text"
    final_role_guess <- "free_text"
    classification_source <- "declared_by_user"
  } else if ("columnas_sensibles" %in% applied_rules) {
    final_role_guess <- "sensitive"
    classification_source <- "declared_by_user"
  }

  if ("faltantes_esperables" %in% applied_rules) {
    final_missingness_hint <- "expected"
    missingness_source <- "declared_by_user"
  }

  list(
    inferred_type = final_inferred_type,
    role_guess = final_role_guess,
    missingness_hint = final_missingness_hint,
    classification_source = classification_source,
    missingness_source = missingness_source,
    applied_rules = applied_rules,
    warnings = warnings
  )
}

ai_profile_variable_summary <- function(column_name, x, inferred_type, role_guess, round_digits, max_levels, top_n) {
  values <- ai_profile_non_missing_values(x)

  if (identical(inferred_type, "identifier")) {
    unique_ratio <- if (length(values) == 0) 0 else length(unique(values)) / length(values)
    return(list(
      approximate_uniqueness = round(unique_ratio * 100, 1),
      approximate_pattern = ai_profile_identifier_pattern(values)
    ))
  }

  if (identical(inferred_type, "categorical")) {
    values_chr <- as.character(values)
    delimiter_hint <- ai_profile_detect_compound_delimiter(values_chr)
    value_shape <- if (is.null(delimiter_hint)) "simple" else "compound_delimited"

    flattened_values <- values_chr
    if (!is.null(delimiter_hint)) {
      split_values <- strsplit(values_chr, delimiter_hint, fixed = TRUE)
      flattened_values <- trimws(unlist(split_values, use.names = FALSE))
      flattened_values <- flattened_values[nzchar(flattened_values)]
    }

    levels_seen <- sort(unique(flattened_values))
    unique_ratio <- if (length(flattened_values) == 0) 0 else length(levels_seen) / length(flattened_values)
    cardinality_class <- if (
      length(levels_seen) > max_levels ||
      (length(levels_seen) >= 8 && unique_ratio >= 0.7)
    ) {
      "high"
    } else {
      "low"
    }

    if (identical(role_guess, "sensitive")) {
      return(list(
        level_count = length(levels_seen),
        values_redacted = TRUE,
        value_shape = value_shape,
        delimiter_hint = delimiter_hint,
        cardinality_class = cardinality_class
      ))
    }
    if (length(levels_seen) <= max_levels && !identical(cardinality_class, "high")) {
      return(list(
        level_count = length(levels_seen),
        values = levels_seen,
        value_shape = value_shape,
        delimiter_hint = delimiter_hint,
        cardinality_class = cardinality_class
      ))
    }
    freq <- sort(table(flattened_values), decreasing = TRUE)
    return(list(
      level_count = length(levels_seen),
      top_levels = head(names(freq), top_n),
      value_shape = value_shape,
      delimiter_hint = delimiter_hint,
      cardinality_class = cardinality_class
    ))
  }

  if (identical(inferred_type, "numeric")) {
    numeric_values <- as.numeric(values)
    non_missing_numeric <- numeric_values[!is.na(numeric_values)]
    unique_non_missing <- unique(non_missing_numeric)
    all_integerish <- length(non_missing_numeric) > 0 &&
      all(abs(non_missing_numeric - round(non_missing_numeric)) < .Machine$double.eps^0.5)
    all_equal <- length(unique_non_missing) == 1
    observed_evidence <- character(0)
    heuristic_signal <- character(0)

    if (all_equal) {
      observed_evidence <- c(
        observed_evidence,
        sprintf(
          "todos los valores observados son iguales: %s",
          format(non_missing_numeric[[1]], trim = TRUE, scientific = FALSE)
        )
      )
    } else if (!is.integer(x) && all_integerish) {
      observed_evidence <- c(observed_evidence, "solo toma valores enteros")
    }

    if (
      ai_profile_numeric_code_like_name(column_name) &&
      (all_equal || (!is.integer(x) && all_integerish))
    ) {
      heuristic_signal <- c(heuristic_signal, "podria funcionar como codigo numerico")
    }

    return(list(
      min = round(min(numeric_values), round_digits),
      max = round(max(numeric_values), round_digits),
      numeric_kind = if (is.integer(x)) "integer" else "double",
      observed_evidence = observed_evidence,
      heuristic_signal = heuristic_signal
    ))
  }

  if (identical(inferred_type, "date") || identical(inferred_type, "datetime")) {
    return(list(
      range = ai_profile_temporal_range(values, inferred_type),
      granularity = ai_profile_temporal_granularity(
        observed_pattern = ai_profile_observed_temporal_pattern(values),
        inferred_type = inferred_type
      )
    ))
  }

  if (identical(inferred_type, "free_text")) {
    text_values <- as.character(values)
    lengths <- nchar(text_values)
    return(list(
      typical_length = sprintf("%s-%s caracteres", min(lengths), max(lengths)),
      variability = "alta"
    ))
  }

  if (identical(inferred_type, "entity_label")) {
    text_values <- as.character(values)
    lengths <- nchar(text_values)
    unique_ratio <- if (length(text_values) == 0) 0 else length(unique(text_values)) / length(text_values)
    return(list(
      typical_length = sprintf("%s-%s caracteres", min(lengths), max(lengths)),
      approximate_uniqueness = round(unique_ratio * 100, 1)
    ))
  }

  if (identical(inferred_type, "collection")) {
    return(list(
      element_type = ai_profile_collection_element_type(x),
      collection_cardinality = ai_profile_collection_cardinality(x)
    ))
  }

  list()
}

build_variable_profile_for_ai <- function(column_name, x, config = NULL, round_digits = 2, max_levels = 12, top_n = 10) {
  inference <- ai_profile_infer_type(column_name, x, max_levels = max_levels)
  imported_type <- ai_profile_imported_type(x)
  role_guess <- ai_profile_role_guess(column_name, inference$inferred_type, x)
  missing_pct <- round(mean(is.na(x)) * 100, 2)
  missingness_hint <- ai_profile_missingness_hint(column_name, missing_pct)
  override <- ai_profile_apply_config_overrides(
    column_name = column_name,
    inferred_type = inference$inferred_type,
    role_guess = role_guess,
    missingness_hint = missingness_hint,
    config = config %||% ai_profile_empty_config()
  )
  summary <- ai_profile_variable_summary(
    column_name = column_name,
    x = x,
    inferred_type = override$inferred_type,
    role_guess = override$role_guess,
    round_digits = round_digits,
    max_levels = max_levels,
    top_n = top_n
  )

  list(
    name = column_name,
    imported_type = imported_type,
    observed_pattern = inference$observed_pattern,
    inferred_type = override$inferred_type,
    inference_confidence = inference$confidence,
    role_guess = override$role_guess,
    classification_source = override$classification_source,
    missing_pct = missing_pct,
    missingness_hint = override$missingness_hint,
    missingness_source = override$missingness_source,
    applied_rules = override$applied_rules,
    summary = summary,
    warnings = unique(c(inference$warnings, override$warnings))
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
