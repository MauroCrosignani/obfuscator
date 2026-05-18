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

build_variable_profile_for_ai <- function(column_name, x, round_digits = 2, max_levels = 12, top_n = 10) {
  inference <- ai_profile_infer_type(column_name, x, max_levels = max_levels)
  imported_type <- ai_profile_imported_type(x)
  role_guess <- ai_profile_role_guess(column_name, inference$inferred_type, x)
  missing_pct <- round(mean(is.na(x)) * 100, 2)
  summary <- ai_profile_variable_summary(
    column_name = column_name,
    x = x,
    inferred_type = inference$inferred_type,
    role_guess = role_guess,
    round_digits = round_digits,
    max_levels = max_levels,
    top_n = top_n
  )

  list(
    name = column_name,
    imported_type = imported_type,
    observed_pattern = inference$observed_pattern,
    inferred_type = inference$inferred_type,
    inference_confidence = inference$confidence,
    role_guess = role_guess,
    missing_pct = missing_pct,
    summary = summary,
    warnings = unique(inference$warnings)
  )
}

profile_dataset_for_ai <- function(data, dataset_name = NULL, max_levels = 12, top_n = 10, round_digits = 2) {
  if (!is.data.frame(data)) {
    stop("`data` debe ser un data.frame o tibble.")
  }

  dataset_name <- dataset_name %||% deparse(substitute(data))
  variable_profiles <- stats::setNames(
    lapply(names(data), function(column_name) {
      build_variable_profile_for_ai(
        column_name,
        data[[column_name]],
        round_digits = round_digits,
        max_levels = max_levels,
        top_n = top_n
      )
    }),
    names(data)
  )

  global_warnings <- unique(unlist(lapply(variable_profiles, `[[`, "warnings"), use.names = FALSE))

  list(
    dataset_name = dataset_name,
    dimensions = list(rows = nrow(data), cols = ncol(data)),
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    variables = variable_profiles,
    warnings = global_warnings
  )
}

# Ejemplo de uso desde RStudio:
# profile <- profile_dataset_for_ai(iris, "iris")
# cat(render_dataset_profile_for_ai(profile))
render_ai_profile_variable <- function(variable_profile) {
  name <- variable_profile$name
  imported_type <- variable_profile$imported_type
  inferred_type <- variable_profile$inferred_type
  summary <- variable_profile$summary
  role_guess <- variable_profile$role_guess

  if (identical(inferred_type, "identifier")) {
    return(sprintf(
      "- %s: identificador; importado como %s; unicidad aproximada %.1f%%; patron aproximado: %s.",
      name,
      imported_type,
      summary$approximate_uniqueness %||% 0,
      summary$approximate_pattern %||% "alfanumerico estructurado"
    ))
  }

  if (identical(inferred_type, "categorical")) {
    if (isTRUE(summary$values_redacted)) {
      return(sprintf(
        "- %s: categorica sensible; niveles observados: %s; valores no listados por seguridad.",
        name,
        summary$level_count %||% 0
      ))
    }
    if (!is.null(summary$values)) {
      return(sprintf(
        "- %s: categorica; valores observados: %s.",
        name,
        paste(summary$values, collapse = ", ")
      ))
    }
    return(sprintf(
      "- %s: categorica; niveles observados: %s; top niveles: %s.",
      name,
      summary$level_count %||% 0,
      paste(summary$top_levels %||% character(0), collapse = ", ")
    ))
  }

  if (identical(inferred_type, "numeric")) {
    suffix <- if (!identical(role_guess, "analytic")) {
      sprintf("; posible %s", gsub("_", " ", role_guess))
    } else {
      ""
    }
    return(sprintf(
      "- %s: numerica; rango aproximado %s-%s%s.",
      name,
      format(summary$min, trim = TRUE, scientific = FALSE),
      format(summary$max, trim = TRUE, scientific = FALSE),
      suffix
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
      "- %s: %s; importada como %s%s%s; rango aproximado %s.",
      name,
      if (identical(inferred_type, "date")) "fecha" else "fecha-hora",
      imported_type,
      detail,
      granularity,
      summary$range %||% "no disponible"
    ))
  }

  if (identical(inferred_type, "free_text")) {
    return(sprintf(
      "- %s: texto libre; longitud tipica %s; alta variabilidad; no se incluyen ejemplos por seguridad.",
      name,
      summary$typical_length %||% "no disponible"
    ))
  }

  sprintf("- %s: tipo inferido %s; importado como %s.", name, inferred_type, imported_type)
}

render_dataset_profile_for_ai <- function(profile, mode = "compact") {
  stopifnot(is.list(profile), !is.null(profile$variables))
  if (!identical(mode, "compact")) {
    stop("Por ahora solo se implementa `mode = 'compact'`.")
  }

  lines <- c(
    sprintf("Dataset: %s", profile$dataset_name %||% "dataset"),
    sprintf(
      "Dimensiones: %s filas, %s columnas",
      profile$dimensions$rows %||% 0,
      profile$dimensions$cols %||% 0
    ),
    "",
    "Resumen por variable:"
  )

  variable_lines <- vapply(profile$variables, render_ai_profile_variable, character(1))
  lines <- c(lines, variable_lines)

  warnings <- unique(profile$warnings)
  if (length(warnings) > 0) {
    lines <- c(lines, "", "Advertencias:")
    lines <- c(lines, paste0("- ", warnings))
  }

  paste(lines, collapse = "\n")
}
