# Deteccion y normalizacion de contexto de fuente para el helper IA.

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
  slug <- ai_profile_normalize_column_name(text %||% "")
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
