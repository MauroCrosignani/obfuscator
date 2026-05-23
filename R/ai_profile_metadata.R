# Carga, validacion y resolucion de metadata externa para el helper IA.

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

ai_profile_normalize_column_name_for_matching <- function(name) {
  ai_profile_normalize_column_name(name %||% "")
}

ai_profile_empty_column_resolution <- function() {
  list(
    matched = list(),
    unresolved = character(0),
    ambiguous = character(0),
    warnings = character(0),
    summary = list(
      exact = 0L,
      normalized = 0L,
      unresolved = 0L,
      ambiguous = 0L
    )
  )
}

ai_profile_resolve_metadata_columns <- function(metadata, data_names) {
  resolution <- ai_profile_empty_column_resolution()
  expected_names <- names(metadata$columnas %||% list())

  if (length(expected_names) == 0) {
    return(resolution)
  }

  normalized_actual <- vapply(data_names, ai_profile_normalize_column_name_for_matching, character(1))
  actual_by_normalized <- split(data_names, normalized_actual)

  for (expected_name in expected_names) {
    if (expected_name %in% data_names) {
      resolution$matched[[expected_name]] <- list(
        actual_name = expected_name,
        match_type = "exact",
        normalized_name = ai_profile_normalize_column_name_for_matching(expected_name)
      )
      next
    }

    expected_normalized <- ai_profile_normalize_column_name_for_matching(expected_name)
    candidates <- actual_by_normalized[[expected_normalized]] %||% character(0)

    if (length(candidates) == 1) {
      resolution$matched[[expected_name]] <- list(
        actual_name = candidates[[1]],
        match_type = "normalized",
        normalized_name = expected_normalized
      )
      next
    }

    if (length(candidates) > 1) {
      resolution$ambiguous <- c(resolution$ambiguous, expected_name)
      resolution$warnings <- c(
        resolution$warnings,
        sprintf(
          "La columna esperada '%s' tiene un matching ambiguo despues de normalizar nombres.",
          expected_name
        )
      )
      next
    }

    resolution$unresolved <- c(resolution$unresolved, expected_name)
    resolution$warnings <- c(
      resolution$warnings,
      sprintf(
        "La columna esperada '%s' no se encontro ni por nombre exacto ni por normalizacion; posible renombre o desajuste.",
        expected_name
      )
    )
  }

  matched_types <- vapply(
    resolution$matched,
    function(entry) entry$match_type %||% "unknown",
    character(1)
  )
  resolution$summary <- list(
    exact = sum(matched_types == "exact"),
    normalized = sum(matched_types == "normalized"),
    unresolved = length(resolution$unresolved),
    ambiguous = length(resolution$ambiguous)
  )
  resolution$warnings <- unique(resolution$warnings)
  resolution
}

ai_profile_resolve_source_metadata <- function(metadata_dir, source_context, dataset_name = NULL, data_names = character(0)) {
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
      base_result$column_resolution <- ai_profile_resolve_metadata_columns(exact_matches[[1]], data_names)
      base_result$warnings <- unique(c(base_result$warnings, base_result$column_resolution$warnings))
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
    base_result$column_resolution <- ai_profile_resolve_metadata_columns(alias_matches[[1]], data_names)
    base_result$warnings <- unique(c(base_result$warnings, base_result$column_resolution$warnings))
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

ai_profile_build_source_alerts <- function(source_metadata, variable_profiles) {
  if (!identical(source_metadata$status %||% NULL, "matched")) {
    return(character(0))
  }

  metadata <- source_metadata$metadata %||% NULL
  column_resolution <- source_metadata$column_resolution %||% NULL
  if (is.null(metadata) || is.null(column_resolution)) {
    return(character(0))
  }

  alerts <- character(0)
  matched_columns <- column_resolution$matched %||% list()
  if (length(matched_columns) == 0) {
    return(character(0))
  }

  for (expected_name in names(matched_columns)) {
    resolution_entry <- matched_columns[[expected_name]]
    actual_name <- resolution_entry$actual_name %||% NULL
    metadata_column <- metadata$columnas[[expected_name]] %||% NULL
    variable_profile <- variable_profiles[[actual_name]] %||% NULL

    if (is.null(actual_name) || is.null(metadata_column) || is.null(variable_profile)) {
      next
    }

    expected_role <- metadata_column$rol %||% NULL
    expected_type <- metadata_column$tipo_esperado %||% NULL
    imported_type <- variable_profile$imported_type %||% NULL
    observed_pattern <- variable_profile$observed_pattern %||% NULL
    missing_pct <- variable_profile$missing_pct %||% 0
    missingness_hint <- variable_profile$missingness_hint %||% "none"

    if (!is.null(expected_type) &&
        expected_type %in% c("date", "datetime") &&
        identical(imported_type, "character")) {
      alerts <- c(
        alerts,
        sprintf(
          "%s: se esperaba %s segun la metadata de origen; estado actual character%s.",
          actual_name,
          expected_type,
          if (!is.null(observed_pattern)) {
            sprintf(" con patron %s", observed_pattern)
          } else {
            ""
          }
        )
      )
    }

    if (identical(expected_role, "identificatoria") && imported_type %in% c("double", "integer", "numeric")) {
      alerts <- c(
        alerts,
        sprintf(
          "%s: se esperaba identificador normalizado; estado actual %s.",
          actual_name,
          imported_type
        )
      )
    }

    if (identical(metadata_column$faltantes %||% NULL, "esperables") && missing_pct >= 40) {
      alerts <- c(
        alerts,
        sprintf(
          "%s: faltantes altos detectados (%.1f%%), consistentes con metadata declarada como esperables.",
          actual_name,
          missing_pct
        )
      )
    }

    if (!identical(metadata_column$faltantes %||% NULL, "esperables") &&
        identical(missingness_hint, "high_unexpected")) {
      alerts <- c(
        alerts,
        sprintf(
          "%s: faltantes altos detectados (%.1f%%); revisar porque no estaban declarados como esperables.",
          actual_name,
          missing_pct
        )
      )
    }
  }

  unique(alerts)
}

