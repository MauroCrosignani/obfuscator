# Utilidades base del helper de perfilado seguro para IA.

ai_profile_non_missing_values <- function(x) {
  values <- x[!is.na(x)]
  if (is.factor(values)) {
    values <- as.character(values)
  }
  values
}

ai_profile_imported_type <- function(x) {
  if (inherits(x, "Date")) {
    return(class(x)[1] %||% "Date")
  }
  if (inherits(x, "POSIXct")) {
    return("POSIXct")
  }
  if (inherits(x, "POSIXlt")) {
    return("POSIXlt")
  }
  if (inherits(x, "POSIXt")) {
    return(class(x)[1] %||% "POSIXt")
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
    return("double")
  }
  if (is.logical(x)) {
    return("logical")
  }

  class(x)[1] %||% typeof(x)
}

ai_profile_normalize_column_name <- function(column_name) {
  normalized <- tolower(trimws(column_name %||% ""))
  normalized <- iconv(normalized, from = "", to = "ASCII//TRANSLIT", sub = "")
  gsub("[^a-z0-9]+", "_", normalized)
}

ai_profile_text_like_column <- function(column_data) {
  if (!(is.character(column_data) || is.factor(column_data))) {
    return(FALSE)
  }

  values <- as.character(column_data)
  values <- values[!is.na(values) & nzchar(trimws(values))]
  if (length(values) == 0) {
    return(FALSE)
  }

  unique_ratio <- length(unique(values)) / length(values)
  mean(nchar(values), na.rm = TRUE) >= 18 || unique_ratio >= 0.8
}

ai_profile_quote_values <- function(values) {
  escaped <- gsub("\\\\", "\\\\\\\\", as.character(values))
  escaped <- gsub('"', '\\\\"', escaped)
  sprintf('"%s"', escaped)
}
