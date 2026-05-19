ai_profile_non_missing_values <- function(x) {
  values <- x[!is.na(x)]
  if (is.factor(values)) {
    values <- as.character(values)
  }
  values
}

ai_profile_imported_type <- function(x) {
  if (inherits(x, c("POSIXct", "POSIXlt", "POSIXt"))) {
    return("datetime")
  }
  if (inherits(x, "Date")) {
    return("date")
  }
  if (is.factor(x)) {
    return("factor")
  }
  if (is.character(x)) {
    return("character")
  }
  if (is.integer(x)) {
    return("integer")
  }
  if (is.numeric(x)) {
    return("numeric")
  }
  if (is.logical(x)) {
    return("logical")
  }

  class(x)[1] %||% typeof(x)
}

ai_profile_identifier_name <- function(column_name) {
  normalized_name <- normalize_release_safe_column_name(column_name)
  grepl(
    "(^|_)(id|rut|cedula|dni|nie|nic)(_|$)|identificador|persona_id|pers_id|expediente|matricula|contribuyente|correo|mail|email|e_mail|telefono|celular",
    normalized_name
  )
}

ai_profile_sensitive_name <- function(column_name) {
  normalized_name <- normalize_release_safe_column_name(column_name)
  grepl(
    "diagnost|enfermed|patolog|beneficio|subsid|sancion|riesgo|situacion|indicador_privado|sensib|privad|ingreso",
    normalized_name
  )
}

ai_profile_quasi_identifier_name <- function(column_name) {
  normalized_name <- normalize_release_safe_column_name(column_name)
  grepl(
    "fecha|date|nacimiento|alta|periodo|mes|anio|edad|antiguedad|cantidad_hijos|tam_hogar|ingreso|salario|monto|facturacion|departamento|localidad|ocupacion|sector|tramo|educ|sexo",
    normalized_name
  )
}

ai_profile_expected_missingness_name <- function(column_name) {
  normalized_name <- normalize_release_safe_column_name(column_name)
  grepl(
    "fecha_hasta|hasta$|end_date|fecha_fin|fin_vigencia|baja_fecha|cancelacion_fecha|cese_fecha|closed_at|ended_at",
    normalized_name
  )
}

ai_profile_empty_config <- function() {
  list(
    faltantes_esperables = character(0),
    columnas_sensibles = character(0),
    columnas_identificatorias = character(0),
    columnas_texto_libre = character(0)
  )
}

ai_profile_normalize_tipo_fuente <- function(tipo_fuente) {
  warnings <- character(0)

  if (is.null(tipo_fuente)) {
    return(list(tipo_fuente = NULL, source_context = list(
      type = NULL,
      source = "none",
      confidence = NULL,
      warnings = character(0)
    ), warnings = warnings))
  }

  normalized <- tolower(trimws(as.character(tipo_fuente)[1]))
  valid_types <- c("gca", "gca2", "oracle", "excel", "csv", "desconocida")

  if (!normalized %in% valid_types) {
    warnings <- c(
      warnings,
      if (identical(normalized, "odbc")) {
        "`tipo_fuente = 'odbc'` no es un valor aprobado; usa `oracle` como categoria semantica."
      } else {
        sprintf(
          "`tipo_fuente = '%s'` no es valido. Valores aceptados: %s.",
          normalized,
          paste(valid_types, collapse = ", ")
        )
      }
    )

    return(list(tipo_fuente = NULL, source_context = list(
      type = NULL,
      source = "none",
      confidence = NULL,
      warnings = warnings
    ), warnings = warnings))
  }

  list(
    tipo_fuente = normalized,
    source_context = list(
      type = normalized,
      source = "declared_by_user",
      confidence = "declared",
      warnings = character(0)
    ),
    warnings = warnings
  )
}

ai_profile_simple_hash <- function(text) {
  values <- utf8ToInt(enc2utf8(text %||% ""))
  if (length(values) == 0) {
    return("00000000")
  }
  sprintf("%08x", sum(values * seq_along(values)) %% 2147483647)
}

ai_profile_slugify <- function(text) {
  slug <- normalize_release_safe_column_name(text %||% "")
  slug <- gsub("_+", "-", slug)
  slug <- gsub("(^-|-$)", "", slug)
  if (!nzchar(slug)) {
    slug <- "fuente"
  }
  slug
}

ai_profile_read_sheet_matrix <- function(path, sheet) {
  suppressWarnings(
    readxl::read_excel(path, sheet = sheet, col_names = FALSE, .name_repair = "minimal")
  )
}

ai_profile_sheet_char_matrix <- function(sheet_data) {
  if (nrow(sheet_data) == 0 || ncol(sheet_data) == 0) {
    return(matrix(character(0), nrow = 0, ncol = 0))
  }
  matrix(
    trimws(replace(as.character(as.matrix(sheet_data)), is.na(as.matrix(sheet_data)), "")),
    nrow = nrow(sheet_data),
    ncol = ncol(sheet_data)
  )
}

ai_profile_find_label_value <- function(char_matrix, label) {
  if (length(char_matrix) == 0) {
    return(NULL)
  }
  matches <- which(char_matrix == label, arr.ind = TRUE)
  if (nrow(matches) == 0) {
    return(NULL)
  }
  row <- matches[1, "row"]
  col <- matches[1, "col"]

  if (col < ncol(char_matrix)) {
    right_values <- char_matrix[row, seq.int(col + 1, ncol(char_matrix))]
    right_values <- right_values[nzchar(right_values)]
    if (length(right_values) > 0) {
      return(right_values[1])
    }
  }

  if (row < nrow(char_matrix)) {
    down_values <- char_matrix[seq.int(row + 1, nrow(char_matrix)), col]
    down_values <- down_values[nzchar(down_values)]
    if (length(down_values) > 0) {
      return(down_values[1])
    }
  }

  NULL
}

ai_profile_detect_gca_source_from_workbook <- function(path, sheets) {
  if (!("Informacion de la consulta" %in% sheets) || !any(grepl("^Datos_Consulta", sheets))) {
    return(NULL)
  }

  info_sheet <- ai_profile_read_sheet_matrix(path, "Informacion de la consulta")
  char_matrix <- ai_profile_sheet_char_matrix(info_sheet)
  if (length(char_matrix) == 0) {
    return(NULL)
  }

  flat_values <- as.vector(char_matrix)
  has_signature <- any(grepl("Planilla generada por el GCA", flat_values, ignore.case = TRUE))
  has_title_label <- any(flat_values == "TituloL")
  has_description_label <- any(grepl("^Descripcion:?$", flat_values, ignore.case = TRUE))
  has_parameters_label <- any(grepl("^Parametros:?$", flat_values, ignore.case = TRUE))

  if (!(has_signature && has_title_label && has_description_label && has_parameters_label)) {
    return(NULL)
  }

  query_title <- ai_profile_find_label_value(char_matrix, "TituloL")
  query_description <- ai_profile_find_label_value(char_matrix, "Descripcion:")
  if (is.null(query_description)) {
    query_description <- ai_profile_find_label_value(char_matrix, "Descripcion")
  }
  parameters_value <- ai_profile_find_label_value(char_matrix, "Parametros:")
  if (is.null(parameters_value)) {
    parameters_value <- ai_profile_find_label_value(char_matrix, "Parametros")
  }

  seed <- paste(query_title %||% "", query_description %||% "", collapse = "|")
  source_id <- sprintf(
    "gca:unresolved:%s:%s",
    ai_profile_slugify(query_title %||% "consulta"),
    ai_profile_simple_hash(seed)
  )

  list(
    type = "gca",
    source = "detected_from_file",
    confidence = "medium",
    source_id = source_id,
    warnings = character(0),
    file = list(
      path = path,
      status = "resolved",
      extension = tools::file_ext(path)
    ),
    details = list(
      query_title = query_title,
      query_description = query_description,
      parameters_present = !is.null(parameters_value) && nzchar(parameters_value)
    )
  )
}

ai_profile_detect_gca2_source_from_workbook <- function(path, sheets) {
  if (!("Caratula" %in% sheets) || !("salida_gca" %in% sheets)) {
    return(NULL)
  }

  cover_sheet <- ai_profile_read_sheet_matrix(path, "Caratula")
  char_matrix <- ai_profile_sheet_char_matrix(cover_sheet)
  if (length(char_matrix) == 0) {
    return(NULL)
  }

  flat_values <- as.vector(char_matrix)
  has_signature <- any(flat_values == "Planilla generada por GCA2")
  query_id <- ai_profile_find_label_value(char_matrix, "Id de Consulta")
  execution_id <- ai_profile_find_label_value(char_matrix, "Id. Ejecucion")
  if (is.null(execution_id)) {
    execution_id <- ai_profile_find_label_value(char_matrix, "Id. Ejecución")
  }

  if (!(has_signature && !is.null(query_id) && grepl("^\\d+$", query_id))) {
    return(NULL)
  }

  list(
    type = "gca2",
    source = "detected_from_file",
    confidence = "high",
    source_id = sprintf("gca2:%s", query_id),
    warnings = character(0),
    file = list(
      path = path,
      status = "resolved",
      extension = tools::file_ext(path)
    ),
    details = list(
      query_id = query_id,
      execution_id = execution_id,
      query_name = ai_profile_find_label_value(char_matrix, "Nombre"),
      query_description = ai_profile_find_label_value(char_matrix, "Descripcion")
    )
  )
}

ai_profile_detect_source_from_file <- function(archivo_fuente) {
  if (is.null(archivo_fuente)) {
    return(list(
      source_context = list(
        type = NULL,
        source = "none",
        confidence = NULL,
        source_id = NULL,
        warnings = character(0),
        file = NULL,
        details = NULL
      ),
      warnings = character(0)
    ))
  }

  path <- normalizePath(archivo_fuente, winslash = "/", mustWork = FALSE)
  if (!file.exists(path)) {
    warning_text <- sprintf("El archivo_fuente '%s' no existe o no esta accesible.", archivo_fuente)
    return(list(
      source_context = list(
        type = NULL,
        source = "none",
        confidence = NULL,
        source_id = NULL,
        warnings = warning_text,
        file = list(path = path, status = "missing", extension = tools::file_ext(path)),
        details = NULL
      ),
      warnings = warning_text
    ))
  }

  extension <- tolower(tools::file_ext(path))
  detected <- NULL

  if (extension %in% c("xls", "xlsx")) {
    sheets <- tryCatch(readxl::excel_sheets(path), error = function(e) NULL)
    if (!is.null(sheets)) {
      detected <- ai_profile_detect_gca2_source_from_workbook(path, sheets)
      if (is.null(detected)) {
        detected <- ai_profile_detect_gca_source_from_workbook(path, sheets)
      }
    }
  }

  if (is.null(detected)) {
    warning_text <- sprintf(
      "No se pudo resolver el contexto de origen desde archivo_fuente '%s'.",
      basename(path)
    )
    return(list(
      source_context = list(
        type = NULL,
        source = "none",
        confidence = NULL,
        source_id = NULL,
        warnings = warning_text,
        file = list(path = path, status = "unresolved", extension = extension),
        details = NULL
      ),
      warnings = warning_text
    ))
  }

  list(source_context = detected, warnings = detected$warnings %||% character(0))
}

ai_profile_merge_source_context <- function(tipo_fuente_context, file_context) {
  declared_type <- tipo_fuente_context$source_context$type
  file_type <- file_context$source_context$type
  warnings <- unique(c(tipo_fuente_context$warnings, file_context$warnings))

  if (!is.null(declared_type)) {
    source_context <- tipo_fuente_context$source_context
    source_context$file <- file_context$source_context$file
    source_context$details <- file_context$source_context$details
    source_context$source_id <- file_context$source_context$source_id
    if (!is.null(file_type) && !identical(declared_type, file_type)) {
      warnings <- c(
        warnings,
        sprintf(
          "El tipo_fuente declarado ('%s') no coincide con la evidencia detectada en archivo_fuente ('%s').",
          declared_type,
          file_type
        )
      )
    }
    source_context$warnings <- unique(c(source_context$warnings, warnings))
    return(list(source_context = source_context, warnings = unique(warnings)))
  }

  source_context <- file_context$source_context
  source_context$warnings <- unique(c(source_context$warnings, warnings))
  list(source_context = source_context, warnings = unique(warnings))
}

ai_profile_empty_source_metadata <- function() {
  list(
    status = "none",
    matched_by = NULL,
    path = NULL,
    metadata = NULL,
    warnings = character(0)
  )
}

ai_profile_validate_source_metadata_entry <- function(metadata, path) {
  warnings <- character(0)
  required_fields <- c("version", "source_type", "source_id", "display_name", "columnas")
  missing_fields <- setdiff(required_fields, names(metadata))

  if (length(missing_fields) > 0) {
    warnings <- c(
      warnings,
      sprintf(
        "La metadata '%s' no tiene el formato minimo requerido. Faltan campos: %s.",
        basename(path),
        paste(sort(missing_fields), collapse = ", ")
      )
    )
    return(list(valid = FALSE, metadata = NULL, warnings = warnings))
  }

  if (!is.list(metadata$columnas)) {
    warnings <- c(
      warnings,
      sprintf(
        "La metadata '%s' no tiene un bloque 'columnas' valido.",
        basename(path)
      )
    )
    return(list(valid = FALSE, metadata = NULL, warnings = warnings))
  }

  metadata$aliases <- unique(as.character(unlist(metadata$aliases %||% character(0), use.names = FALSE)))
  metadata$aliases <- metadata$aliases[nzchar(metadata$aliases)]
  metadata$path <- path

  list(valid = TRUE, metadata = metadata, warnings = warnings)
}

ai_profile_load_source_metadata <- function(metadata_dir) {
  empty_metadata <- ai_profile_empty_source_metadata()

  if (is.null(metadata_dir)) {
    return(empty_metadata)
  }

  path <- normalizePath(metadata_dir, winslash = "/", mustWork = FALSE)
  if (!dir.exists(path)) {
    warning_text <- sprintf("El metadata_dir '%s' no existe o no esta accesible.", metadata_dir)
    result <- empty_metadata
    result$status <- "missing_dir"
    result$path <- path
    result$warnings <- warning_text
    return(result)
  }

  json_files <- list.files(path, pattern = "\\.json$", full.names = TRUE)
  warnings <- character(0)
  entries <- list()

  for (json_file in json_files) {
    parsed <- tryCatch(
      jsonlite::fromJSON(json_file, simplifyVector = FALSE),
      error = function(e) e
    )

    if (inherits(parsed, "error")) {
      warnings <- c(
        warnings,
        sprintf(
          "No se pudo leer la metadata '%s': %s",
          basename(json_file),
          conditionMessage(parsed)
        )
      )
      next
    }

    validated <- ai_profile_validate_source_metadata_entry(parsed, json_file)
    warnings <- c(warnings, validated$warnings)
    if (isTRUE(validated$valid)) {
      entries[[length(entries) + 1L]] <- validated$metadata
    }
  }

  result <- empty_metadata
  result$status <- "loaded"
  result$path <- path
  result$entries <- entries
  result$warnings <- unique(warnings)
  result
}

ai_profile_metadata_candidate_names <- function(source_context, dataset_name) {
  candidates <- c(
    source_context$details$query_title %||% character(0),
    source_context$details$query_name %||% character(0),
    dataset_name %||% character(0)
  )
  candidates <- unique(trimws(as.character(candidates)))
  candidates[nzchar(candidates)]
}

ai_profile_resolve_source_metadata <- function(metadata_dir, source_context, dataset_name = NULL) {
  loaded <- ai_profile_load_source_metadata(metadata_dir)
  base_result <- ai_profile_empty_source_metadata()
  base_result$status <- loaded$status
  base_result$path <- loaded$path
  base_result$warnings <- loaded$warnings

  if (!identical(loaded$status, "loaded")) {
    return(base_result)
  }

  entries <- loaded$entries %||% list()
  if (length(entries) == 0) {
    base_result$status <- "no_match"
    return(base_result)
  }

  source_id <- source_context$source_id %||% NULL
  if (!is.null(source_id)) {
    exact_matches <- entries[vapply(
      entries,
      function(entry) identical(entry$source_id %||% NULL, source_id),
      logical(1)
    )]

    if (length(exact_matches) == 1) {
      base_result$status <- "matched"
      base_result$matched_by <- "source_id"
      base_result$metadata <- exact_matches[[1]]
      return(base_result)
    }

    if (length(exact_matches) > 1) {
      base_result$status <- "ambiguous"
      base_result$warnings <- unique(c(
        base_result$warnings,
        sprintf("La metadata para source_id '%s' es ambigua y no se aplico automaticamente.", source_id)
      ))
      return(base_result)
    }
  }

  candidate_names <- ai_profile_metadata_candidate_names(source_context, dataset_name)
  if (length(candidate_names) == 0) {
    base_result$status <- "no_match"
    return(base_result)
  }

  alias_matches <- entries[vapply(
    entries,
    function(entry) {
      aliases <- unique(c(entry$display_name %||% character(0), entry$aliases %||% character(0)))
      aliases <- tolower(trimws(as.character(aliases)))
      any(tolower(candidate_names) %in% aliases)
    },
    logical(1)
  )]

  if (length(alias_matches) == 1) {
    base_result$status <- "matched"
    base_result$matched_by <- "alias"
    base_result$metadata <- alias_matches[[1]]
    return(base_result)
  }

  if (length(alias_matches) > 1) {
    base_result$status <- "ambiguous"
    base_result$warnings <- unique(c(
      base_result$warnings,
      sprintf(
        "La metadata candidata para '%s' es ambigua y no se aplico automaticamente.",
        candidate_names[1]
      )
    ))
    return(base_result)
  }

  base_result$status <- "no_match"
  base_result
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
      inferred_type = "datetime",
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

    if (release_safe_text_like_column(x)) {
      return(list(
        inferred_type = "free_text",
        observed_pattern = NULL,
        warnings = "Se detecto texto libre; no se incluiran ejemplos reales por seguridad.",
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
    if (identical(role_guess, "sensitive")) {
      return(list(
        level_count = length(sort(unique(as.character(values)))),
        values_redacted = TRUE
      ))
    }
    levels_seen <- sort(unique(as.character(values)))
    if (length(levels_seen) <= max_levels) {
      return(list(level_count = length(levels_seen), values = levels_seen))
    }
    freq <- sort(table(as.character(values)), decreasing = TRUE)
    return(list(
      level_count = length(levels_seen),
      top_levels = head(names(freq), top_n)
    ))
  }

  if (identical(inferred_type, "numeric")) {
    numeric_values <- as.numeric(values)
    return(list(
      min = round(min(numeric_values), round_digits),
      max = round(max(numeric_values), round_digits)
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
    dataset_name = dataset_name
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

  list(
    dataset_name = dataset_name,
    dimensions = list(rows = nrow(data), cols = ncol(data)),
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    source_context = merged_source_context_result$source_context,
    source_metadata = source_metadata,
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

  if (identical(inferred_type, "identifier")) {
    return(sprintf(
      "- %s: identificador; importado como %s; unicidad aproximada %.1f%%; patron aproximado: %s%s.",
      name,
      imported_type,
      summary$approximate_uniqueness %||% 0,
      summary$approximate_pattern %||% "alfanumerico estructurado",
      missing_text
    ))
  }

  if (identical(inferred_type, "categorical")) {
    visible_values <- summary$values %||% character(0)
    max_value_length <- if (length(visible_values) == 0) 0 else max(nchar(visible_values), na.rm = TRUE)
    if (
      identical(mode, "conservative") &&
      !isTRUE(summary$values_redacted) &&
      !identical(role_guess, "sensitive") &&
      max_value_length > 4
    ) {
      return(sprintf(
        "- %s: categorica; niveles observados: %s; valores no listados por modo conservador%s.",
        name,
        summary$level_count %||% length(summary$values %||% character(0)),
        missing_text
      ))
    }
    if (isTRUE(summary$values_redacted)) {
      return(sprintf(
        "- %s: categorica sensible; niveles observados: %s; valores no listados por seguridad%s.",
        name,
        summary$level_count %||% 0,
        missing_text
      ))
    }
    if (!is.null(summary$values)) {
      return(sprintf(
        "- %s: categorica; valores observados: %s%s.",
        name,
        paste(summary$values, collapse = ", "),
        missing_text
      ))
    }
    return(sprintf(
      "- %s: categorica; niveles observados: %s; top niveles: %s%s.",
      name,
      summary$level_count %||% 0,
      paste(summary$top_levels %||% character(0), collapse = ", "),
      missing_text
    ))
  }

  if (identical(inferred_type, "numeric")) {
    suffix <- if (!identical(role_guess, "analytic")) {
      sprintf("; posible %s", gsub("_", " ", role_guess))
    } else {
      ""
    }
    return(sprintf(
      "- %s: numerica; rango aproximado %s-%s%s%s.",
      name,
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
      "- %s: %s; importada como %s%s%s; rango aproximado %s%s.",
      name,
      if (identical(inferred_type, "date")) "fecha" else "fecha-hora",
      imported_type,
      detail,
      granularity,
      summary$range %||% "no disponible",
      missing_text
    ))
  }

  if (identical(inferred_type, "free_text")) {
    return(sprintf(
      "- %s: texto libre; longitud tipica %s; alta variabilidad; no se incluyen ejemplos por seguridad%s.",
      name,
      summary$typical_length %||% "no disponible",
      missing_text
    ))
  }

  sprintf("- %s: tipo inferido %s; importado como %s%s.", name, inferred_type, imported_type, missing_text)
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
    lines <- c(
      lines,
      sprintf("Fuente declarada por el usuario: %s.", profile$source_context$type)
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
  }

  lines <- c(lines, "", "Resumen por variable:")

  variable_lines <- vapply(
    profile$variables,
    function(variable_profile) render_ai_profile_variable(variable_profile, mode = mode),
    character(1)
  )
  lines <- c(lines, variable_lines)

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
