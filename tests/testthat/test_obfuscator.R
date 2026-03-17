library(testthat)

source(file.path("..", "..", "R", "obfuscator_core.R"))

test_that("sourcear el script no dispara la CLI", {
  expect_silent(source(file.path("..", "..", "obfuscator.R")))
})

test_that("la configuracion valida conserva clase y valores clave", {
  cfg <- obfuscator_config(
    id_cols = "ID",
    seed = 123,
    numeric_mode = "preserve_rank",
    consistency_rules = list(list(type = "ordered", lower = "A", upper = "B"))
  )

  expect_s3_class(cfg, "obfuscator_config")
  expect_equal(cfg$seed, 123)
  expect_equal(cfg$numeric_mode, "preserve_rank")
})

test_that("la configuracion invalida falla con mensaje claro en espanol", {
  df <- data.frame(ID = 1:3)

  expect_error(
    obfuscate_dataset(df, config = list(numeric_mode = "desconocido")),
    "numeric_mode"
  )
})

test_that("el modelo de privacidad invalido falla con mensaje claro", {
  df <- data.frame(edad = c(21, 22), sexo = c("F", "M"))

  expect_error(
    obfuscate_dataset(
      df,
      config = list(
        privacy_model = list(type = "k_anonymity", k = 1, quasi_identifiers = c("edad", "sexo"))
      )
    ),
    "mayor o igual a 2"
  )
})

test_that("los roles de columnas se detectan y pueden declararse explicitamente", {
  df <- data.frame(
    ID_EMPRESA = c(1, 2),
    FECHA = as.Date(c("2024-01-01", "2024-02-01")),
    ESTADO = c("A", "B"),
    MONTO = c(10.5, 20.5)
  )

  roles_auto <- detect_column_roles(df, obfuscator_config())
  roles_explicit <- detect_column_roles(
    df,
    obfuscator_config(col_roles = list(id = "ID_EMPRESA", date = "FECHA", categorical = "ESTADO", numeric = "MONTO"))
  )

  expect_true("ID_EMPRESA" %in% roles_auto$id)
  expect_equal(roles_explicit$id, "ID_EMPRESA")
  expect_equal(roles_explicit$date, "FECHA")
})

test_that("IDs se mapean de forma consistente y determinista", {
  df <- data.frame(ID = c(1, 2, 1, 3), stringsAsFactors = FALSE)
  cfg <- obfuscator_config(seed = 123, id_cols = "ID", log = TRUE)
  out1 <- obfuscate_dataset(df, config = cfg)
  out2 <- obfuscate_dataset(df, config = cfg)

  expect_equal(out1$ID, out2$ID)
  expect_true(all(grepl("^999", as.character(out1$ID))))
  expect_equal(length(unique(out1$ID)), 3)
})

test_that("IDs alfanumericos se ofuscan sin perder cardinalidad ni NAs", {
  df <- data.frame(ID = c("A-001", NA, "B-002", "A-001"), stringsAsFactors = FALSE)
  out <- obfuscate_dataset(df, config = obfuscator_config(seed = 99, id_cols = "ID"))

  expect_equal(is.na(out$ID), is.na(df$ID))
  expect_equal(length(unique(na.omit(out$ID))), length(unique(na.omit(df$ID))))
  expect_true(all(grepl("^999", na.omit(out$ID))))
})

test_that("Fechas se mezclan pero conservan el conjunto de valores", {
  df <- data.frame(FECHA = as.Date(c("2023-01-01", "2023-02-01", "2023-03-01")))
  out <- obfuscate_dataset(df, config = obfuscator_config(seed = 42))

  expect_setequal(out$FECHA, df$FECHA)
})

test_that("Categorias conservan sus frecuencias", {
  df <- data.frame(ESTADO = c("A", "A", "B", "C", "A"), stringsAsFactors = FALSE)
  out <- obfuscate_dataset(df, config = obfuscator_config(seed = 123))

  expect_equal(sort(table(df$ESTADO)), sort(table(out$ESTADO)))
})

test_that("NAs se mantienen en la misma posicion", {
  df <- data.frame(
    ID = c(1, NA, 2),
    FECHA = as.Date(c("2023-01-01", NA, "2023-03-01")),
    MONTO = c(10, NA, 20)
  )
  out <- obfuscate_dataset(df, config = obfuscator_config(seed = 7))

  expect_equal(is.na(out$ID), is.na(df$ID))
  expect_equal(is.na(out$FECHA), is.na(df$FECHA))
  expect_equal(is.na(out$MONTO), is.na(df$MONTO))
})

test_that("Valores numericos mantienen rango y signo en modo range_random", {
  df <- data.frame(MONTO = c(-100, -50, 0, 50, 100))
  out <- obfuscate_dataset(df, config = obfuscator_config(seed = 55, numeric_mode = "range_random"))

  expect_equal(sign(out$MONTO), sign(df$MONTO))
  expect_equal(range(out$MONTO, na.rm = TRUE), range(df$MONTO, na.rm = TRUE))
})

test_that("El modo preserve_rank conserva el orden relativo de los numericos", {
  df <- data.frame(MONTO = c(10, 30, 20, 40))
  out <- obfuscate_dataset(df, config = obfuscator_config(seed = 3, numeric_mode = "preserve_rank"))

  expect_equal(order(df$MONTO), order(out$MONTO))
})

test_that("Se pueden definir modos numericos por columna", {
  df <- data.frame(MONTO = c(10, 20, 30), SCORE = c(3, 1, 2))
  out <- obfuscate_dataset(
    df,
    config = obfuscator_config(
      seed = 10,
      numeric_mode = "range_random",
      numeric_modes = list(SCORE = "preserve_rank")
    )
  )

  expect_equal(order(df$SCORE), order(out$SCORE))
  expect_equal(range(out$MONTO), range(df$MONTO))
})

test_that("Variables enteras siguen siendo enteras y las binarias preservan valores posibles", {
  df <- data.frame(CANT = c(0L, 1L, 1L, 0L, 1L))
  out <- obfuscate_dataset(df, config = obfuscator_config(seed = 2024))

  expect_type(out$CANT, "integer")
  expect_setequal(unique(out$CANT), unique(df$CANT))
})

test_that("Numericos double sin decimales no se fuerzan a integer ni fallan con rangos enormes", {
  df <- data.frame(MONTO = c(1000000000000, 1000000000500, 1000000000900))

  expect_silent({
    out <- obfuscate_dataset(df, config = obfuscator_config(seed = 2027))
    expect_type(out$MONTO, "double")
    expect_equal(length(out$MONTO), nrow(df))
    expect_false(any(is.na(out$MONTO)))
  })
})

test_that("Columnas con infinitos y NaN preservan esos valores especiales", {
  df <- data.frame(MONTO = c(-Inf, -1, NaN, 0, 1, Inf))
  out <- obfuscate_dataset(df, config = obfuscator_config(seed = 2025))

  expect_true(is.infinite(out$MONTO[1]) && out$MONTO[1] < 0)
  expect_true(is.nan(out$MONTO[3]))
  expect_true(is.infinite(out$MONTO[6]) && out$MONTO[6] > 0)
})

test_that("Columnas 100 por ciento NA se mantienen intactas", {
  df <- data.frame(ID = c(NA, NA), FECHA = as.Date(c(NA, NA)), MONTO = c(NA_real_, NA_real_))
  out <- obfuscate_dataset(df, config = obfuscator_config(id_cols = "ID", seed = 8, log = FALSE))

  expect_identical(df, out)
})

test_that("Dataset de una fila no falla ni rompe tipos", {
  df <- data.frame(
    ID = 123L,
    FECHA = as.Date("2023-01-01"),
    ESTADO = "A",
    MONTO = 10.5,
    stringsAsFactors = FALSE
  )
  out <- obfuscate_dataset(df, config = obfuscator_config(seed = 123, id_cols = "ID"))

  expect_equal(nrow(out), 1)
  expect_type(out$ID, "integer")
  expect_s3_class(out$FECHA, "Date")
  expect_type(out$ESTADO, "character")
  expect_type(out$MONTO, "double")
})

test_that("El log de auditoria se adjunta con trazabilidad enriquecida", {
  df <- data.frame(ID = c(1, 2), MONTO = c(10, 20))
  out <- obfuscate_dataset(df, config = obfuscator_config(seed = 1, id_cols = "ID", log = TRUE))
  log_info <- attr(out, "obfuscator_log")

  expect_true(is.list(log_info))
  expect_equal(log_info$seed, 1)
  expect_equal(log_info$package_version, obfuscator_version())
  expect_true("ID" %in% log_info$roles$id)
  expect_true(all(c("ID", "MONTO") %in% names(log_info$transformations)))
})

test_that("Las reglas ordered corrigen consistencia entre fechas", {
  df <- data.frame(
    FECHA_INICIO = as.Date(c("2024-01-01", "2024-01-10", "2024-01-20", "2024-01-25")),
    FECHA_FIN = as.Date(c("2024-02-01", "2024-02-10", "2024-02-20", "2024-02-25"))
  )

  out <- obfuscate_dataset(
    df,
    config = obfuscator_config(
      seed = 77,
      consistency_rules = list(
        list(type = "ordered", lower = "FECHA_INICIO", upper = "FECHA_FIN", allow_equal = TRUE)
      )
    )
  )

  expect_true(all(out$FECHA_INICIO <= out$FECHA_FIN))
})

test_that("Las reglas ordered corrigen consistencia entre columnas numericas", {
  df <- data.frame(
    MINIMO = c(1, 10, 20, 30),
    MAXIMO = c(5, 15, 25, 35)
  )

  out <- obfuscate_dataset(
    df,
    config = obfuscator_config(
      seed = 88,
      consistency_rules = list(
        list(type = "ordered", lower = "MINIMO", upper = "MAXIMO", allow_equal = TRUE)
      )
    )
  )

  expect_true(all(out$MINIMO <= out$MAXIMO))
})

test_that("Las reglas de consistencia quedan registradas en el log con cantidad de ajustes", {
  rules <- list(list(type = "ordered", lower = "A", upper = "B", allow_equal = TRUE))
  df <- data.frame(A = c(10, 2), B = c(1, 3))

  out <- obfuscate_dataset(df, config = obfuscator_config(seed = 5, consistency_rules = rules, log = TRUE))
  log_info <- attr(out, "obfuscator_log")

  expect_equal(log_info$consistency_rules[[1]]$type, "ordered")
  expect_true(log_info$consistency_rules[[1]]$rows_adjusted >= 0)
})

test_that("k-anonymity se puede cumplir mediante generalizacion progresiva", {
  df <- data.frame(
    edad = c(21, 22, 23, 24, 61, 62, 63, 64),
    fecha = as.Date(c(
      "2024-01-01", "2024-01-02", "2024-01-03", "2024-01-04",
      "2024-02-01", "2024-02-02", "2024-02-03", "2024-02-04"
    )),
    sexo = c("F", "F", "M", "M", "F", "F", "M", "M"),
    monto = c(100, 120, 140, 160, 200, 220, 240, 260)
  )

  out <- obfuscate_dataset(
    df,
    config = obfuscator_config(
      seed = 2026,
      privacy_model = list(
        type = "k_anonymity",
        k = 2,
        quasi_identifiers = c("edad", "fecha", "sexo"),
        suppression = "none"
      )
    )
  )

  log_info <- attr(out, "obfuscator_log")
  expect_true(is.list(log_info$privacy_report))
  expect_true(log_info$privacy_report$after$satisfied)
  expect_true(any(log_info$privacy_report$generalization_steps != "identity"))
})

test_that("k-anonymity puede suprimir filas residuales cuando no alcanza con generalizar", {
  df <- data.frame(
    edad = c(21, 22, 23, 90),
    sexo = c("F", "F", "M", "X"),
    region = c("N", "N", "S", "UNICA"),
    monto = c(10, 20, 30, 40)
  )

  out <- obfuscate_dataset(
    df,
    config = obfuscator_config(
      seed = 11,
      privacy_model = list(
        type = "k_anonymity",
        k = 2,
        quasi_identifiers = c("edad", "sexo", "region"),
        suppression = "rows",
        hierarchies = list(
          edad = c("identity"),
          sexo = c("identity"),
          region = c("identity")
        )
      )
    )
  )

  log_info <- attr(out, "obfuscator_log")
  expect_true(log_info$privacy_report$rows_suppressed >= 1)
  expect_true(log_info$privacy_report$after$satisfied || nrow(out) == 0)
})

test_that("k-anonymity respeta jerarquias parametrizadas por columna", {
  df <- data.frame(
    fecha = as.Date(c("2024-01-01", "2024-01-02", "2024-05-01", "2024-05-02")),
    tramo = c("A", "A", "B", "C")
  )

  out <- obfuscate_dataset(
    df,
    config = obfuscator_config(
      seed = 99,
      privacy_model = list(
        type = "k_anonymity",
        k = 2,
        quasi_identifiers = c("fecha", "tramo"),
        suppression = "none",
        hierarchies = list(
          fecha = c("identity", "year"),
          tramo = c("identity", "global")
        )
      )
    )
  )

  log_info <- attr(out, "obfuscator_log")
  expect_true(log_info$privacy_report$after$satisfied)
  expect_true(log_info$privacy_report$generalization_steps[["fecha"]] %in% c("identity", "year"))
})
