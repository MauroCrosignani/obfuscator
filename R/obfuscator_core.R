# Core de ObfuscatoR.

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

obfuscator_version <- function() {
  "0.3.0"
}

obfuscator_config <- function(
  col_roles = NULL,
  id_cols = NULL,
  seed = NULL,
  id_prefix = "999",
  log = TRUE,
  clone = TRUE,
  consistency_rules = list(),
  numeric_mode = "range_random",
  numeric_modes = NULL,
  privacy_model = NULL,
  locale = "es",
  infer_roles = TRUE,
  progress_callback = NULL,
  project_key = NULL
) {
  config <- list(
    col_roles = col_roles,
    id_cols = id_cols,
    seed = seed,
    id_prefix = id_prefix,
    log = log,
    clone = clone,
    consistency_rules = consistency_rules,
    numeric_mode = numeric_mode,
    numeric_modes = numeric_modes,
    privacy_model = privacy_model,
    locale = locale,
    infer_roles = infer_roles,
    progress_callback = progress_callback,
    project_key = project_key
  )

  class(config) <- c("obfuscator_config", "list")
  config
}

copy_df <- function(df) {
  if (tibble::is_tibble(df)) {
    return(tibble::as_tibble(as.data.frame(df, stringsAsFactors = FALSE)))
  }

  as.data.frame(df, stringsAsFactors = FALSE)
}

is_integerish_obfuscator <- function(x) {
  if (!is.numeric(x)) {
    return(FALSE)
  }

  finite_x <- x[is.finite(x)]
  if (length(finite_x) == 0) {
    return(TRUE)
  }

  all(abs(finite_x - round(finite_x)) < sqrt(.Machine$double.eps))
}

decimal_places_obfuscator <- function(x) {
  finite_x <- x[is.finite(x)]
  if (length(finite_x) == 0) {
    return(0L)
  }

  formatted <- format(finite_x, scientific = FALSE, trim = TRUE, nsmall = 0)
  suffix <- sub("^-?\\d+\\.?","", formatted)
  max(nchar(suffix), na.rm = TRUE)
}

scramble_vector_obfuscator <- function(x) {
  na_mask <- is.na(x)
  if (all(na_mask)) {
    return(x)
  }

  values <- x[!na_mask]
  if (length(values) <= 1) {
    return(x)
  }

  out <- x
  if (length(values) > 0) {
    out[!na_mask] <- sample(values, length(values), replace = FALSE)
  }
  out
}

#' Scramble Vector with key
scramble_vector_deterministic <- function(x, project_key = NULL, col_name = "") {
  na_mask <- is.na(x)
  if (all(na_mask)) return(x)
  
  uniq <- sort(unique(as.character(x[!na_mask])))
  if (length(uniq) <= 1) return(x)
  
  # Deterministic shuffle of levels
  set.seed(sum(utf8ToInt(paste0(project_key, col_name))) %% .Machine$integer.max)
  scrambled_uniq <- sample(uniq, length(uniq), replace = FALSE)
  
  mapping <- setNames(scrambled_uniq, uniq)
  
  out <- x
  # Map each value to its scrambled counterpart
  out[!na_mask] <- mapping[as.character(x[!na_mask])]
  
  return(list(data = out, mapping = mapping))
}

validate_obfuscator_config <- function(df, config) {
  allowed_keys <- c(
    "col_roles",
    "id_cols",
    "seed",
    "id_prefix",
    "log",
    "clone",
    "consistency_rules",
    "numeric_mode",
    "numeric_modes",
    "privacy_model",
    "locale",
    "infer_roles",
    "progress_callback",
    "project_key"
  )

  unknown_keys <- setdiff(names(config), allowed_keys)
  if (length(unknown_keys) > 0) {
    stop(sprintf(
      "La configuracion contiene claves no soportadas: %s",
      paste(unknown_keys, collapse = ", ")
    ))
  }

  if (!is.null(config$seed) && (!is.numeric(config$seed) || length(config$seed) != 1 || is.na(config$seed))) {
    stop("`seed` debe ser un valor numerico escalar o NULL.")
  }

  if (!is.character(config$id_prefix) || length(config$id_prefix) != 1 || nchar(config$id_prefix) == 0) {
    stop("`id_prefix` debe ser un texto no vacio.")
  }

  if (!is.logical(config$log) || length(config$log) != 1) {
    stop("`log` debe ser TRUE o FALSE.")
  }

  if (!is.logical(config$clone) || length(config$clone) != 1) {
    stop("`clone` debe ser TRUE o FALSE.")
  }

  if (!is.logical(config$infer_roles) || length(config$infer_roles) != 1) {
    stop("`infer_roles` debe ser TRUE o FALSE.")
  }

  if (!is.null(config$progress_callback) && !is.function(config$progress_callback)) {
    stop("`progress_callback` debe ser una funcion o NULL.")
  }

  if (!is.null(config$project_key) && (!is.character(config$project_key) || length(config$project_key) != 1)) {
    stop("`project_key` debe ser un texto escalar o NULL.")
  }

  valid_numeric_modes <- c("range_random", "preserve_rank", "permute")
  if (!config$numeric_mode %in% valid_numeric_modes) {
    stop(sprintf(
      "`numeric_mode` debe ser uno de: %s",
      paste(valid_numeric_modes, collapse = ", ")
    ))
  }

  if (!is.null(config$numeric_modes)) {
    if (is.null(names(config$numeric_modes)) || any(names(config$numeric_modes) == "")) {
      stop("`numeric_modes` debe ser una lista o vector nombrado por columna.")
    }

    invalid_modes <- setdiff(unname(unlist(config$numeric_modes, use.names = FALSE)), valid_numeric_modes)
    if (length(invalid_modes) > 0) {
      stop(sprintf(
        "Se detectaron modos numericos no soportados en `numeric_modes`: %s",
        paste(unique(invalid_modes), collapse = ", ")
      ))
    }
  }

  if (!is.null(config$col_roles)) {
    valid_role_names <- c("id", "date", "categorical", "numeric", "preserve")
    invalid_role_names <- setdiff(names(config$col_roles), valid_role_names)
    if (length(invalid_role_names) > 0) {
      stop(sprintf(
        "`col_roles` solo admite estos nombres: %s",
        paste(valid_role_names, collapse = ", ")
      ))
    }

    role_columns <- unique(unlist(config$col_roles, use.names = FALSE))
    missing_columns <- setdiff(role_columns, colnames(df))
    if (length(missing_columns) > 0) {
      stop(sprintf(
        "Las siguientes columnas definidas en `col_roles` no existen en el dataset: %s",
        paste(missing_columns, collapse = ", ")
      ))
    }
  }

  if (!is.null(config$privacy_model)) {
    if (!is.list(config$privacy_model) || is.null(config$privacy_model$type)) {
      stop("`privacy_model` debe ser una lista con al menos el campo `type`.")
    }

    if (!identical(config$privacy_model$type, "k_anonymity")) {
      stop("Por ahora solo se soporta `privacy_model$type = \"k_anonymity\"`.")
    }

    k <- config$privacy_model$k %||% NULL
    if (is.null(k) || !is.numeric(k) || length(k) != 1 || is.na(k) || k < 2) {
      stop("En `privacy_model`, `k` debe ser un numero entero mayor o igual a 2.")
    }

    qis <- config$privacy_model$quasi_identifiers %||% character(0)
    if (!is.character(qis) || length(qis) == 0) {
      stop("En `privacy_model`, `quasi_identifiers` debe ser un vector de columnas no vacio.")
    }

    missing_qis <- setdiff(qis, colnames(df))
    if (length(missing_qis) > 0) {
      stop(sprintf(
        "Las siguientes columnas definidas como quasi-identificadores no existen: %s",
        paste(missing_qis, collapse = ", ")
      ))
    }

    suppression <- config$privacy_model$suppression %||% "rows"
    if (!suppression %in% c("rows", "none", "group")) {
      stop("En `privacy_model`, `suppression` debe ser `rows`, `none` o `group`.")
    }
  }

  TRUE
}

emit_progress_obfuscator <- function(callback, percent, stage, detail = NULL) {
  if (is.null(callback)) {
    return(invisible(NULL))
  }

  callback(list(
    percent = max(0, min(100, percent)),
    stage = stage,
    detail = detail
  ))
  invisible(NULL)
}

detect_column_roles <- function(df, config = obfuscator_config()) {
  validate_obfuscator_config(df, config)

  col_names <- colnames(df)

  infer_id_cols <- function(names_vec) {
    patterns <- c(
      "^id$",
      "^id_",
      "_id$",
      "^nro_",
      "documento",
      "persid",
      "cuit",
      "cuil",
      "empresa",
      "contrib"
    )
    names_vec[grepl(paste(patterns, collapse = "|"), names_vec, ignore.case = TRUE)]
  }

  explicit_roles <- if (!is.null(config$col_roles)) config$col_roles else list()

  roles <- list(
    id = unique(c(
      explicit_roles$id %||% character(0),
      config$id_cols %||% character(0),
      if (isTRUE(config$infer_roles)) infer_id_cols(col_names) else character(0)
    )),
    date = unique(c(
      explicit_roles$date %||% character(0),
      col_names[vapply(df, function(x) inherits(x, c("Date", "POSIXct", "POSIXlt", "POSIXt")), logical(1))]
    )),
    categorical = unique(explicit_roles$categorical %||% character(0)),
    numeric = unique(explicit_roles$numeric %||% character(0)),
    preserve = unique(explicit_roles$preserve %||% character(0))
  )

  auto_categorical <- col_names[vapply(df, function(x) is.character(x) || is.factor(x), logical(1))]
  auto_numeric <- col_names[vapply(df, is.numeric, logical(1))]

  # Initialize roles with auto-detected and explicitly defined roles
  # Then refine based on heuristics and explicit overrides
  inferred_roles <- list(
    id = character(0),
    date = character(0),
    categorical = character(0),
    numeric = character(0),
    preserve = character(0)
  )

  for (col in col_names) {
    # Check for explicit roles first
    if (col %in% roles$id) {
      inferred_roles$id <- c(inferred_roles$id, col)
    } else if (col %in% roles$date) {
      inferred_roles$date <- c(inferred_roles$date, col)
    } else if (col %in% roles$preserve) {
      inferred_roles$preserve <- c(inferred_roles$preserve, col)
    } else if (col %in% roles$categorical) {
      inferred_roles$categorical <- c(inferred_roles$categorical, col)
    } else if (col %in% roles$numeric) {
      inferred_roles$numeric <- c(inferred_roles$numeric, col)
    } else {
      # Apply heuristics for auto-detection if not explicitly set
      # Enhanced heuristic: If numeric with few unique values and many repetitions, it is likely categorical
      is_cat_heuristic <- FALSE
      if (is.numeric(df[[col]])) {
        uniq_count <- length(unique(df[[col]]))
        if (uniq_count > 0 && uniq_count < 100 && uniq_count < (nrow(df) * 0.2)) {
          is_cat_heuristic <- TRUE
        }
      }

      if (col %in% auto_categorical || is_cat_heuristic) {
        inferred_roles$categorical <- c(inferred_roles$categorical, col)
      } else if (col %in% auto_numeric) {
        inferred_roles$numeric <- c(inferred_roles$numeric, col)
      }
      # If neither, it remains unassigned, which is fine for now.
    }
  }

  # Overwrite initial roles with inferred_roles, ensuring uniqueness and intersection with col_names
  roles$id <- intersect(unique(inferred_roles$id), col_names)
  roles$date <- intersect(unique(inferred_roles$date), col_names)
  roles$categorical <- intersect(unique(inferred_roles$categorical), col_names)
  roles$numeric <- intersect(unique(inferred_roles$numeric), col_names)
  roles$preserve <- intersect(unique(inferred_roles$preserve), col_names)

  # Final cleanup: ensure no column is in multiple roles (priority: id > date > preserve > categorical > numeric)
  roles$date <- setdiff(roles$date, roles$id)
  roles$preserve <- setdiff(roles$preserve, c(roles$id, roles$date))
  roles$categorical <- setdiff(roles$categorical, c(roles$id, roles$date, roles$preserve))
  roles$numeric <- setdiff(roles$numeric, c(roles$id, roles$date, roles$preserve, roles$categorical))

  roles
}

apply_consistency_rules_obfuscator <- function(data, rules) {
  if (length(rules) == 0) {
    return(list(data = data, report = list()))
  }

  normalize_rule <- function(rule) {
    if (!is.list(rule) || is.null(rule$type)) {
      stop("Cada regla de consistencia debe ser una lista con un campo `type`.")
    }
    rule
  }

  report <- vector("list", length(rules))

  enforce_order_rule <- function(data, rule) {
    required_fields <- c("lower", "upper")
    missing_fields <- setdiff(required_fields, names(rule))
    if (length(missing_fields) > 0) {
      stop(sprintf(
        "La regla `ordered` requiere los campos: %s",
        paste(required_fields, collapse = ", ")
      ))
    }

    lower <- rule$lower
    upper <- rule$upper
    allow_equal <- if (!is.null(rule$allow_equal)) isTRUE(rule$allow_equal) else TRUE
    swap_strategy <- if (!is.null(rule$swap_strategy)) rule$swap_strategy else "swap"

    if (!(lower %in% names(data)) || !(upper %in% names(data))) {
      stop(sprintf("Las columnas `%s` y `%s` deben existir para aplicar una regla `ordered`.", lower, upper))
    }

    lower_values <- data[[lower]]
    upper_values <- data[[upper]]
    comparable_mask <- !is.na(lower_values) & !is.na(upper_values)
    if (!any(comparable_mask)) {
      return(list(data = data, report = c(rule, list(rows_adjusted = 0L))))
    }

    violating_mask <- if (allow_equal) {
      lower_values[comparable_mask] > upper_values[comparable_mask]
    } else {
      lower_values[comparable_mask] >= upper_values[comparable_mask]
    }

    violating_rows <- which(comparable_mask)[violating_mask]
    if (length(violating_rows) == 0) {
      return(list(data = data, report = c(rule, list(rows_adjusted = 0L))))
    }

    if (!identical(swap_strategy, "swap")) {
      stop("Por ahora solo se soporta `swap_strategy = \"swap\"`.")
    }

    tmp <- data[[lower]][violating_rows]
    data[[lower]][violating_rows] <- data[[upper]][violating_rows]
    data[[upper]][violating_rows] <- tmp

    list(data = data, report = c(rule, list(rows_adjusted = length(violating_rows))))
  }

  for (idx in seq_along(rules)) {
    rule <- normalize_rule(rules[[idx]])

    if (identical(rule$type, "ordered")) {
      result <- enforce_order_rule(data, rule)
      data <- result$data
      report[[idx]] <- result$report
    } else {
      stop(sprintf("Tipo de regla de consistencia no soportado: `%s`.", rule$type))
    }
  }

  list(data = data, report = report)
}

obfuscate_numeric_range <- function(x, integer_col, preserve_integer_storage = FALSE) {
  finite_mask <- is.finite(x)
  if (!any(finite_mask)) {
    return(x)
  }

  finite_values <- x[finite_mask]
  if (length(finite_values) <= 1 || all(finite_values == finite_values[[1]])) {
    return(x)
  }

  unique_finite <- sort(unique(finite_values))
  if (length(unique_finite) <= 2) {
    out <- x
    out[finite_mask] <- scramble_vector_obfuscator(finite_values)
    if (preserve_integer_storage) {
      out[finite_mask] <- as.integer(round(out[finite_mask]))
    }
    return(out)
  }

  generate_group <- function(values) {
    if (length(values) == 0) {
      return(values)
    }
    if (length(values) == 1 || min(values) == max(values)) {
      return(values)
    }

    rng <- range(values, na.rm = TRUE)
    if (integer_col) {
      lower_bound <- ceiling(rng[1])
      upper_bound <- floor(rng[2])

      if (!is.finite(lower_bound) || !is.finite(upper_bound) || upper_bound < lower_bound) {
        return(values)
      }

      # Evita construir secuencias gigantes cuando el rango entero es enorme.
      generated <- round(stats::runif(length(values), min = lower_bound, max = upper_bound))
    } else {
      generated <- stats::runif(length(values), min = rng[1], max = rng[2])
      generated <- round(generated, digits = decimal_places_obfuscator(values))
    }

    generated[which.min(values)[1]] <- rng[1]
    generated[which.max(values)[1]] <- rng[2]
    generated
  }

  transformed <- finite_values
  positive_mask <- finite_values > 0
  negative_mask <- finite_values < 0
  zero_mask <- finite_values == 0

  transformed[positive_mask] <- generate_group(finite_values[positive_mask])
  transformed[negative_mask] <- generate_group(finite_values[negative_mask])
  transformed[zero_mask] <- 0

  out <- x
  out[finite_mask] <- transformed
  if (preserve_integer_storage) {
    out[finite_mask] <- as.integer(round(out[finite_mask]))
  }
  out
}

obfuscate_numeric_preserve_rank <- function(x, integer_col, preserve_integer_storage = FALSE) {
  finite_mask <- is.finite(x)
  if (!any(finite_mask)) {
    return(x)
  }

  finite_values <- x[finite_mask]
  if (length(finite_values) <= 1 || all(finite_values == finite_values[[1]])) {
    return(x)
  }

  ranks <- rank(finite_values, ties.method = "first")
  sorted_ranks <- order(ranks)
  rng <- range(finite_values, na.rm = TRUE)

  if (integer_col) {
    candidate <- seq.int(from = ceiling(rng[1]), to = floor(rng[2]), length.out = length(finite_values))
    candidate <- round(candidate)
  } else {
    candidate <- seq(from = rng[1], to = rng[2], length.out = length(finite_values))
    candidate <- round(candidate, digits = decimal_places_obfuscator(finite_values))
  }

  jittered <- candidate
  if (length(jittered) > 2 && diff(rng) > 0) {
    inner <- seq_len(length(jittered) - 2) + 1
    jittered[inner] <- sort(candidate[inner] + stats::runif(length(inner), -0.2, 0.2) * diff(rng))
    if (!integer_col) {
      jittered <- round(jittered, digits = decimal_places_obfuscator(finite_values))
    }
  }

  transformed <- numeric(length(finite_values))
  transformed[sorted_ranks] <- sort(jittered)

  out <- x
  out[finite_mask] <- transformed
  if (preserve_integer_storage) {
    out[finite_mask] <- as.integer(round(out[finite_mask]))
  }
  out
}

obfuscate_numeric_column <- function(x, mode) {
  integer_col <- is_integerish_obfuscator(x)
  preserve_integer_storage <- identical(typeof(x), "integer")

  if (identical(mode, "permute")) {
    out <- x
    finite_mask <- is.finite(x)
    out[finite_mask] <- scramble_vector_obfuscator(x[finite_mask])
    if (preserve_integer_storage) {
      out[finite_mask] <- as.integer(round(out[finite_mask]))
    }
    return(out)
  }

  if (identical(mode, "preserve_rank")) {
    return(obfuscate_numeric_preserve_rank(x, integer_col, preserve_integer_storage = preserve_integer_storage))
  }

  obfuscate_numeric_range(x, integer_col, preserve_integer_storage = preserve_integer_storage)
}

make_id_map_obfuscator <- function(values, prefix, prefer_integer) {
  uniq <- unique(values)
  n <- length(uniq)

  if (n == 0) {
    return(setNames(character(0), character(0)))
  }

  if (prefer_integer) {
    prefix_num <- suppressWarnings(as.numeric(prefix))
    base <- if (is.na(prefix_num)) 999000000 else as.numeric(paste0(prefix, "000000"))
    generated <- base + seq_len(n)

    if (!any(generated > .Machine$integer.max)) {
      return(setNames(as.integer(generated), as.character(uniq)))
    }
  }

  width <- max(6L, nchar(as.character(n)))
  setNames(paste0(prefix, "_", formatC(seq_len(n), width = width, flag = "0")), as.character(uniq))
}

obfuscate_id_col_obfuscator <- function(col, id_prefix) {
  na_mask <- is.na(col)
  if (all(na_mask)) {
    return(col)
  }

  original_is_factor <- is.factor(col)
  values_chr <- as.character(col)
  non_na_values <- values_chr[!na_mask]
  id_map <- get_deterministic_id_map(non_na_values, id_prefix, project_key = NULL) # Placeholder, will be passed from top

  mapped_chr <- values_chr
  mapped_chr[!na_mask] <- unname(id_map[non_na_values])

  if (original_is_factor) {
    return(factor(mapped_chr, exclude = NULL))
  }

  if (identical(typeof(col), "integer") && is.numeric(id_map)) {
    return(as.integer(mapped_chr))
  }

  if (is.numeric(col) && is.numeric(id_map)) {
    return(as.numeric(mapped_chr))
  }

  mapped_chr
}

#' Obtiene el mapa de identificadores de forma deterministica si hay project_key
get_deterministic_id_map <- function(values, prefix, project_key = NULL) {
  is_num <- is.numeric(values)
  uniq_original <- if (is_num) sort(unique(values)) else sort(unique(as.character(values)))
  uniq <- as.character(uniq_original)

  if (length(uniq) == 0) return(list())
  
  if (is.null(project_key)) {
    return(make_id_map_obfuscator(uniq_original, prefix, prefer_integer = is_num))
  }
  
  # Deterministic seed based on key and value
  get_seed <- function(val) {
    sum(utf8ToInt(paste0(project_key, val))) %% .Machine$integer.max
  }
  
  mapped <- vapply(uniq, function(v) {
    set.seed(get_seed(v))
    # Generate a random ID with prefix
    paste0(prefix, "_", sprintf("%08d", sample(1:99999999, 1)))
  }, character(1))
  
  setNames(mapped, uniq)
}

#' Obfuscate ID Column
obfuscate_id_col_obfuscator_v2 <- function(col, id_prefix, project_key = NULL) {
  na_mask <- is.na(col)
  if (all(na_mask)) return(col)
  
  original_is_factor <- is.factor(col)
  values_chr <- as.character(col)
  non_na_values <- col[!na_mask]
  id_map <- get_deterministic_id_map(non_na_values, id_prefix, project_key)

  mapped_chr <- values_chr
  mapped_chr[!na_mask] <- unname(id_map[non_na_values])
  
  if (original_is_factor) {
    mapped_data <- factor(mapped_chr, exclude = NULL)
  } else if (is.numeric(col) && is.numeric(id_map)) {
    # Type stable conversion
    num_vals <- as.numeric(mapped_chr)
    mapped_data <- if (is.integer(col)) as.integer(round(num_vals)) else num_vals
  } else {
    mapped_data <- mapped_chr
  }
  
  return(list(data = mapped_data, mapping = id_map))
}

summarize_k_anonymity_risk <- function(data, quasi_identifiers, k) {
  if (length(quasi_identifiers) == 0) {
    return(list(
      k = k,
      quasi_identifiers = quasi_identifiers,
      row_count = nrow(data),
      equivalence_classes = 0L,
      violating_classes = 0L,
      violating_rows = 0L,
      satisfied = TRUE
    ))
  }

  qi_data <- data[quasi_identifiers]
  complete_mask <- stats::complete.cases(qi_data)

  if (!any(complete_mask)) {
    return(list(
      k = k,
      quasi_identifiers = quasi_identifiers,
      row_count = nrow(data),
      equivalence_classes = 0L,
      violating_classes = 0L,
      violating_rows = 0L,
      satisfied = TRUE
    ))
  }

  keys <- do.call(
    paste,
    c(lapply(qi_data[complete_mask, , drop = FALSE], as.character), sep = "\r")
  )
  counts <- table(keys)
  violating_keys <- names(counts[counts < k])

  list(
    k = k,
    quasi_identifiers = quasi_identifiers,
    row_count = nrow(data),
    equivalence_classes = length(counts),
    violating_classes = length(violating_keys),
    violating_rows = sum(counts[counts < k]),
    satisfied = all(counts >= k)
  )
}

build_generalization_plan <- function(column, values, hierarchy = NULL) {
  if (!is.null(hierarchy)) {
    # Si ya es un plan completo (por ejemplo, viene de tests robustos), devolverlo.
    if (is.list(hierarchy) && length(hierarchy) > 0 && identical(hierarchy[[1]], "identity")) {
      return(hierarchy)
    }
    # El UI envia list(mapping = ..., name = ...). Extraemos solo el mapping como paso.
    step <- if (is.list(hierarchy) && !is.null(hierarchy$mapping)) hierarchy$mapping else hierarchy
    return(list("identity", step, "global"))
  }

  if (inherits(values, c("Date", "POSIXct", "POSIXlt", "POSIXt"))) {
    return(c("identity", "month", "quarter", "year"))
  }

  if (is.numeric(values)) {
    return(c("identity", "interval_5", "interval_10", "interval_20", "global"))
  }

  if (is.factor(values) || is.character(values)) {
    return(c("identity", "rare_2", "rare_5", "rare_10", "global"))
  }

  c("identity", "global")
}

generalize_numeric_step <- function(x, step) {
  if (identical(step, "identity")) {
    return(x)
  }

  if (identical(step, "global")) {
    out <- rep(NA_character_, length(x))
    non_na <- !is.na(x) & is.finite(x)
    if (any(non_na)) {
      rng <- range(x[non_na], na.rm = TRUE)
      out[non_na] <- sprintf("[%s,%s]", format(rng[1], trim = TRUE), format(rng[2], trim = TRUE))
    }
    return(out)
  }

  width <- suppressWarnings(as.numeric(sub("^interval_", "", step)))
  if (is.na(width)) {
    stop(sprintf("Paso de generalizacion numerica no soportado: `%s`.", step))
  }

  out <- rep(NA_character_, length(x))
  non_na <- !is.na(x) & is.finite(x)
  if (!any(non_na)) {
    return(out)
  }

  lower <- floor(x[non_na] / width) * width
  upper <- lower + width - 1
  if (!is_integerish_obfuscator(x)) {
    upper <- lower + width
  }
  out[non_na] <- sprintf("[%s,%s]", format(lower, trim = TRUE), format(upper, trim = TRUE))
  out
}

generalize_date_step <- function(x, step) {
  if (identical(step, "identity")) {
    return(as.character(x))
  }

  out <- rep(NA_character_, length(x))
  non_na <- !is.na(x)
  if (!any(non_na)) {
    return(out)
  }

  dates <- as.Date(x[non_na])
  if (identical(step, "month")) {
    out[non_na] <- format(dates, "%Y-%m")
  } else if (identical(step, "quarter")) {
    out[non_na] <- paste0(format(dates, "%Y"), "-T", ((as.integer(format(dates, "%m")) - 1) %/% 3) + 1)
  } else if (identical(step, "year")) {
    out[non_na] <- format(dates, "%Y")
  } else if (identical(step, "global")) {
    out[non_na] <- "FECHA_GENERALIZADA"
  } else {
    stop(sprintf("Paso de generalizacion de fechas no soportado: `%s`.", step))
  }

  out
}

generalize_categorical_step <- function(x, step) {
  values <- as.character(x)
  if (identical(step, "identity")) {
    return(values)
  }

  out <- values
  non_na <- !is.na(values)
  if (!any(non_na)) {
    return(out)
  }

  if (identical(step, "global")) {
    out[non_na] <- "OTROS"
    return(out)
  }

  threshold <- suppressWarnings(as.numeric(sub("^rare_", "", step)))
  if (is.na(threshold)) {
    stop(sprintf("Paso de generalizacion categorica no soportado: `%s`.", step))
  }

  freq <- table(values[non_na])
  rare_levels <- names(freq[freq < threshold])
  out[non_na & values %in% rare_levels] <- "OTROS"
  out
}

generalize_mapping_step <- function(x, step) {
  # step es una lista con 'mapping' (list) y opcionalmente 'name'
  mapping <- if (is.list(step) && !is.null(step$mapping)) step$mapping else step
  
  values <- as.character(x)
  out <- values
  
  # Construir vector de busqueda
  lookup_names <- names(mapping)
  if (is.null(lookup_names)) return(out)
  
  for (group_name in lookup_names) {
    matches <- mapping[[group_name]]
    out[values %in% matches] <- group_name
  }
  
  out
}

generalize_quasi_identifier <- function(x, step, original = NULL) {
  # Si el paso es una lista (mapping definido por el usuario)
  if (is.list(step)) {
    # Las jerarquias personalizadas son incrementales: aplicamos sobre x
    return(generalize_mapping_step(x, step))
  }
  
  # Para pasos predefinidos (strings), preferimos original si esta disponible
  # para evitar errores de parseo en fechas/numeros
  val_to_use <- if (!is.null(original)) original else x
  
  if (step %in% c("month", "quarter", "year", "decade", "century")) {
    return(generalize_date_step(val_to_use, step))
  }
  
  if (grepl("^interval_|^round_|^log", step)) {
    return(generalize_numeric_step(val_to_use, step))
  }
  
  # Categorical default or global
  if (step == "global") {
    # Para global ("OTROS"), da igual x o original, usaremos x por consistencia con rare levels
    return(generalize_categorical_step(x, "global"))
  }
  
  generalize_categorical_step(val_to_use, step)
}

apply_k_anonymity_model <- function(data, privacy_model, progress_callback = NULL) {
  if (is.null(privacy_model)) {
    return(list(data = data, report = NULL))
  }

  k <- as.integer(privacy_model$k)
  quasi_identifiers <- privacy_model$quasi_identifiers
  suppression <- privacy_model$suppression %||% "rows"
  hierarchies <- privacy_model$hierarchies %||% list()

  before_risk <- summarize_k_anonymity_risk(data, quasi_identifiers, k)
  emit_progress_obfuscator(progress_callback, 5, "Analizando riesgo de k-anonymity")
  if (before_risk$satisfied) {
    report <- list(
      type = "k_anonymity",
      k = k,
      quasi_identifiers = quasi_identifiers,
      suppression = suppression,
      before = before_risk,
      after = before_risk,
      generalization_steps = setNames(as.list(rep("identity", length(quasi_identifiers))), quasi_identifiers),
      rows_suppressed = 0L
    )
    # NEW: Add class IDs even on early return
    qi_data_final <- data[quasi_identifiers]
    if (nrow(qi_data_final) > 0) {
      class_keys <- do.call(paste, c(lapply(qi_data_final, as.character), sep = "\r"))
      data$.obfuscator_class_id <- as.integer(factor(class_keys))
    }
    return(list(data = data, report = report))
  }

  plans <- lapply(quasi_identifiers, function(col) build_generalization_plan(col, data[[col]], hierarchies[[col]] %||% NULL))
  names(plans) <- quasi_identifiers
  plan_positions <- setNames(rep(1L, length(quasi_identifiers)), quasi_identifiers)

  generalized <- copy_df(data)
  best_state <- generalized
  best_risk <- before_risk

  max_iterations <- max(vapply(plans, length, integer(1)), 1L) * max(length(quasi_identifiers), 1L) * 2L
  iteration <- 0L

  while (iteration < max_iterations) {
    iteration <- iteration + 1L
    current_risk <- summarize_k_anonymity_risk(generalized, quasi_identifiers, k)
    loop_percent <- 5 + (iteration / max_iterations) * 75
    emit_progress_obfuscator(
      progress_callback,
      loop_percent,
      "Generalizando quasi-identificadores",
      sprintf("Iteracion %s de %s", iteration, max_iterations)
    )
    best_state <- generalized
    best_risk <- current_risk

    if (current_risk$satisfied) {
      break
    }

    next_candidates <- names(plan_positions)[vapply(names(plan_positions), function(col) {
      plan_positions[[col]] < length(plans[[col]])
    }, logical(1))]

    if (length(next_candidates) == 0) {
      break
    }

    candidate_scores <- vapply(next_candidates, function(col) {
      plan_positions[[col]] + 1L
    }, integer(1))
    target_col <- next_candidates[which.min(candidate_scores)][1]
    plan_positions[[target_col]] <- plan_positions[[target_col]] + 1L
    selected_step <- plans[[target_col]][[plan_positions[[target_col]]]]
    generalized[[target_col]] <- generalize_quasi_identifier(generalized[[target_col]], selected_step, data[[target_col]])
  }

  final_data <- best_state
  final_risk <- best_risk
  rows_suppressed <- 0L

  if (!final_risk$satisfied && suppression != "none") {
    qi_data <- final_data[quasi_identifiers]
    complete_mask <- stats::complete.cases(qi_data)
    keys <- rep(NA_character_, nrow(final_data))
    if (any(complete_mask)) {
      keys[complete_mask] <- do.call(
        paste,
        c(lapply(qi_data[complete_mask, , drop = FALSE], as.character), sep = "\r")
      )
      counts <- table(keys[complete_mask])
      violating_keys <- names(counts[counts < k])
      
      if (identical(suppression, "rows")) {
        keep_mask <- !(keys %in% violating_keys)
        rows_suppressed <- sum(!keep_mask, na.rm = TRUE)
        final_data <- final_data[keep_mask, , drop = FALSE]
      } else if (identical(suppression, "group")) {
        # NEW: Residual grouping into "REMANENTE"
        violating_mask <- keys %in% violating_keys
        if (any(violating_mask)) {
          for (qi in quasi_identifiers) {
            final_data[violating_mask, qi] <- "REMANENTE"
          }
        }
        rows_suppressed <- 0L
      }
    }
    final_risk <- summarize_k_anonymity_risk(final_data, quasi_identifiers, k)
    emit_progress_obfuscator(progress_callback, 95, "Aplicando supresion residual")
  }

  applied_steps <- setNames(lapply(quasi_identifiers, function(col) {
    plans[[col]][[plan_positions[[col]]]]
  }), quasi_identifiers)

  report <- list(
    type = "k_anonymity",
    k = k,
    quasi_identifiers = quasi_identifiers,
    suppression = suppression,
    before = before_risk,
    after = final_risk,
    generalization_steps = applied_steps,
    rows_suppressed = rows_suppressed
  )

  # Add class IDs for final record
  qi_data_final <- final_data[quasi_identifiers]
  if (nrow(qi_data_final) > 0) {
    class_keys <- do.call(paste, c(lapply(qi_data_final, as.character), sep = "\r"))
    final_data$.obfuscator_class_id <- as.integer(factor(class_keys))
  }

  emit_progress_obfuscator(progress_callback, 100, "k-anonymity finalizado")
  list(data = final_data, report = report)
}

obfuscate_dataset <- function(df, config = obfuscator_config()) {
  stopifnot(is.data.frame(df))

  if (!inherits(config, "obfuscator_config")) {
    config <- do.call(obfuscator_config, config)
  }

  validate_obfuscator_config(df, config)
  progress_callback <- config$progress_callback

  if (is.null(config$seed)) {
    config$seed <- as.integer(Sys.time()) %% .Machine$integer.max
  }

  emit_progress_obfuscator(progress_callback, 0, "Preparando configuracion")

  old_seed_exists <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  old_seed <- if (old_seed_exists) get(".Random.seed", envir = .GlobalEnv) else NULL
  set.seed(config$seed)
  on.exit({
    if (old_seed_exists) {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)

  roles <- detect_column_roles(df, config)
  out <- if (isTRUE(config$clone)) copy_df(df) else df
  emit_progress_obfuscator(progress_callback, 10, "Roles de columnas detectados")

  log_entries <- list(
    timestamp = Sys.time(),
    package_version = obfuscator_version(),
    locale = config$locale,
    seed = config$seed,
    n_rows = nrow(df),
    n_cols = ncol(df),
    roles = roles,
    numeric_mode = config$numeric_mode,
    numeric_modes = config$numeric_modes,
    privacy_model = config$privacy_model,
    transformations = list()
  )

  for (col in roles$id) {
    res <- obfuscate_id_col_obfuscator_v2(out[[col]], config$id_prefix, config$project_key)
    out[[col]] <- if (is.list(res)) res$data else res
    log_entries$transformations[[col]] <- list(
      type = "id", 
      method = "deterministic-map",
      mapping = if (is.list(res)) res$mapping else NULL
    )
  }
  emit_progress_obfuscator(progress_callback, 25, "Identificadores ofuscados", sprintf("%s columnas", length(roles$id)))

  for (col in roles$date) {
    out[[col]] <- scramble_vector_obfuscator(out[[col]])
    log_entries$transformations[[col]] <- list(type = "date", method = "permute")
  }
  emit_progress_obfuscator(progress_callback, 40, "Fechas procesadas", sprintf("%s columnas", length(roles$date)))

  for (col in roles$categorical) {
    if (is.null(config$project_key)) {
      out[[col]] <- scramble_vector_obfuscator(out[[col]])
      log_entries$transformations[[col]] <- list(type = "categorical", method = "permute")
    } else {
      res <- scramble_vector_deterministic(out[[col]], config$project_key, col)
      out[[col]] <- if (is.list(res)) res$data else res
      log_entries$transformations[[col]] <- list(
        type = "categorical", 
        method = "deterministic-permute",
        mapping = if (is.list(res)) res$mapping else NULL
      )
    }
  }
  emit_progress_obfuscator(progress_callback, 55, "Variables categoricas procesadas", sprintf("%s columnas", length(roles$categorical)))

  per_column_numeric_modes <- config$numeric_modes %||% list()
  numeric_total <- max(length(roles$numeric), 1L)
  numeric_done <- 0L
  for (col in roles$numeric) {
    col_mode <- per_column_numeric_modes[[col]] %||% config$numeric_mode
    out[[col]] <- obfuscate_numeric_column(out[[col]], col_mode)
    log_entries$transformations[[col]] <- list(type = "numeric", method = col_mode)
    numeric_done <- numeric_done + 1L
    emit_progress_obfuscator(
      progress_callback,
      55 + (numeric_done / numeric_total) * 15,
      "Variables numericas procesadas",
      sprintf("%s/%s columnas", numeric_done, length(roles$numeric))
    )
  }

  consistency_result <- apply_consistency_rules_obfuscator(out, config$consistency_rules)
  out <- consistency_result$data
  if (length(config$consistency_rules) > 0) {
    log_entries$consistency_rules <- consistency_result$report
  }
  emit_progress_obfuscator(progress_callback, 75, "Reglas de consistencia aplicadas")

  privacy_progress <- if (is.null(progress_callback)) {
    NULL
  } else {
    function(event) {
      mapped_percent <- 75 + (event$percent / 100) * 20
      emit_progress_obfuscator(progress_callback, mapped_percent, event$stage, event$detail)
    }
  }

  privacy_result <- apply_k_anonymity_model(out, config$privacy_model, progress_callback = privacy_progress)
  out <- privacy_result$data
  if (!is.null(privacy_result$report)) {
    log_entries$privacy_report <- privacy_result$report
    
    # NEW: ID Grouping logic if enabled in privacy_model
    group_ids <- config$privacy_model$group_ids %||% FALSE
    if (isTRUE(group_ids) && ".obfuscator_class_id" %in% names(out)) {
       class_ids <- out$.obfuscator_class_id
       for (col in roles$id) {
         # Map each class to a new deterministic ID
         # We use a combined key to ensure it is different from individual IDs if needed
         class_mapping <- get_deterministic_id_map(unique(class_ids), paste0(config$id_prefix, "_GRP"), config$project_key)
         out[[col]] <- unname(class_mapping[as.character(class_ids)])
       }
       out$.obfuscator_class_id <- NULL # Clean up
    } else {
       if (".obfuscator_class_id" %in% names(out)) out$.obfuscator_class_id <- NULL
    }
  }
  emit_progress_obfuscator(progress_callback, 95, "Modelo de privacidad aplicado")

  if (isTRUE(config$log)) {
    attr(out, "obfuscator_log") <- log_entries
  }

  emit_progress_obfuscator(progress_callback, 100, "Ofuscacion finalizada")

  out
}

obfuscate_csv <- function(input_path, output_path, config = obfuscator_config()) {
  df <- readr::read_csv(input_path, show_col_types = FALSE)
  out <- obfuscate_dataset(df, config = config)
  readr::write_csv(out, output_path)
  invisible(out)
}

#' Reversion de Ofuscacion
#'
#' Revierte las transformaciones de IDs y Categoricas si el log tiene los mapas.
#'
#' @param df Dataframe ofuscado.
#' @param log Log de ofuscacion (obtenido via attr(df, "obfuscator_log")).
#' @return Dataframe revertido.
#' @export
revert_obfuscation <- function(df, log = NULL) {
  if (is.null(log)) {
    log <- attr(df, "obfuscator_log")
  }
  
  if (is.null(log)) {
    stop("No se encontro el log de ofuscacion. No se puede revertir de forma segura.")
  }
  
  out <- df
  trans <- log$transformations
  
  for (col in names(trans)) {
    if (is.null(out[[col]])) next
    
    entry <- trans[[col]]
    if (!is.null(entry$mapping)) {
      # Invert dictionary
      mapping <- entry$mapping
      inv_map <- setNames(names(mapping), as.character(mapping))
      
      old_values <- as.character(out[[col]])
      na_mask <- is.na(old_values)
      
      reverted <- old_values
      reverted[!na_mask] <- inv_map[old_values[!na_mask]]
      
      # Try to restore type if numeric
      if (all(grepl("^[0-9.-]+$", reverted[!na_mask]))) {
        out[[col]] <- as.numeric(reverted)
      } else {
        out[[col]] <- reverted
      }
    }
  }
  
  out
}

# --- Module: PersistenceManager ---

#' Generar hash del esquema de un dataset
#' @param df Dataframe o tibble.
#' @return Un string con el hash MD5 de los nombres de columnas ordenados.
generate_schema_hash <- function(df) {
  cols <- sort(colnames(df))
  # Usamos digest si esta disponible, sino una suma simple de caracteres como fallback deterministico
  if (requireNamespace("digest", quietly = TRUE)) {
    return(digest::digest(cols, algo = "md5"))
  }
  # Fallback: concatenacion y suma de bytes
  char_sum <- sum(utf8ToInt(paste(cols, collapse = "|"))) %% 1000000
  sprintf("hash_%d_%d", length(cols), char_sum)
}

#' Guardar configuracion de roles a JSON
#' @param roles Lista de roles obtenida de role_state().
#' @param path Ruta del archivo destino.
save_roles_to_json <- function(roles, path) {
  # Limpiar roles vacios para un JSON mas compacto
  clean_roles <- Filter(function(x) length(x) > 0, roles)
  jsonlite::write_json(clean_roles, path, pretty = TRUE)
}

#' Cargar roles desde JSON con soporte para fuzzy matching
#' @param df Dataframe actual para validar columnas.
#' @param path Ruta del JSON.
#' @param threshold Umbral de similitud (0 a 1) para fuzzy matching.
#' @return Lista con roles asigados (exactos) y sugeridos (fuzzy).
load_roles_from_json <- function(df, path, threshold = 0.8) {
  if (!file.exists(path)) return(NULL)
  
  saved_roles <- jsonlite::read_json(path, simplifyVector = TRUE)
  current_cols <- colnames(df)
  
  result <- list(
    exact = list(id = c(), date = c(), categorical = c(), numeric = c(), preserve = c()),
    suggested = list() # Lista de listas: list(col_actual, role_sugerido, original_name, score)
  )
  
  for (role_name in names(result$exact)) {
    cols_in_role <- saved_roles[[role_name]] %||% c()
    for (col in cols_in_role) {
      if (col %in% current_cols) {
        # Match exacto
        result$exact[[role_name]] <- c(result$exact[[role_name]], col)
      } else {
        # Intentar Fuzzy Match si no hay match exacto en ninguna zona
        distances <- adist(col, current_cols, ignore.case = TRUE)[1, ]
        max_len <- max(nchar(col), nchar(current_cols))
        similarity <- 1 - (distances / max_len)
        
        best_idx <- which.max(similarity)
        if (as.numeric(similarity[best_idx]) >= threshold) {
          suggested_col <- current_cols[best_idx]
          # Solo sugerir si la columna actual no tiene ya un match exacto asignado
          already_assigned_exact <- suggested_col %in% unlist(result$exact)
          if (!already_assigned_exact) {
             # Tambien verificar si ya fue sugerida (prioridad al primer rol encontrado)
             if (is.null(result$suggested[[suggested_col]])) {
                result$suggested[[suggested_col]] <- list(
                  role = role_name,
                  original = col,
                  score = as.numeric(similarity[best_idx])
                )
             }
          }
        }
      }
    }
  }
  
  # New: Restore hierarchies if they exist
  if (!is.null(saved_roles$hierarchies)) {
    # No necesitamos fuzzy matching para las jerarquias completas (por ahora)
    # pero las pasamos para que el UI las recupere si los nombres coinciden
    result$hierarchies <- saved_roles$hierarchies
  }
  
  result
}
