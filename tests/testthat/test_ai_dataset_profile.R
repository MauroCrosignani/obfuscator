library(testthat)

source(file.path("..", "..", "R", "obfuscator_core.R"))

test_that("profile_dataset_for_ai devuelve estructura base", {
  profile <- profile_dataset_for_ai(iris, dataset_name = "iris")

  expect_equal(profile$dataset_name, "iris")
  expect_equal(profile$dimensions$rows, 150)
  expect_equal(profile$dimensions$cols, 5)
  expect_true("variables" %in% names(profile))
  expect_length(profile$variables, 5)
})

test_that("render_dataset_profile_for_ai devuelve texto compacto util", {
  profile <- profile_dataset_for_ai(iris, dataset_name = "iris")
  rendered <- render_dataset_profile_for_ai(profile)

  expect_type(rendered, "character")
  expect_length(rendered, 1)
  expect_match(rendered, "Dataset: iris")
  expect_match(rendered, "Dimensiones: 150 filas, 5 columnas")
  expect_match(rendered, "Sepal\\.Length")
})

test_that("fechas importadas como texto se infieren como datetime con advertencia", {
  df <- data.frame(
    fecha_evento = c(
      "2026-05-17 14:22:31.123456",
      "2026-05-18 09:10:11.654321"
    ),
    stringsAsFactors = FALSE
  )

  profile <- profile_dataset_for_ai(df, dataset_name = "fechas_texto")
  var_profile <- profile$variables$fecha_evento

  expect_equal(var_profile$imported_type, "character")
  expect_equal(var_profile$inferred_type, "datetime")
  expect_equal(var_profile$summary$granularity, "microsegundos")
  expect_equal(var_profile$role_guess, "quasi_identifier")
  expect_true(any(grepl("normalizacion|parse", var_profile$warnings, ignore.case = TRUE)))
})

test_that("variables semanticas reciben role_guess liviano y render temporal mas informativo", {
  df <- data.frame(
    edad = c(23, 24, 31),
    indicador_privado = c("alto", "medio", "bajo"),
    fecha_alta = c("2026-05-17", "2026-05-18", "2026-05-19"),
    stringsAsFactors = FALSE
  )

  profile <- profile_dataset_for_ai(df, dataset_name = "roles_semanticos")
  rendered <- render_dataset_profile_for_ai(profile)

  expect_equal(profile$variables$edad$role_guess, "quasi_identifier")
  expect_equal(profile$variables$indicador_privado$role_guess, "sensitive")
  expect_equal(profile$variables$fecha_alta$summary$granularity, "dia")
  expect_match(rendered, "granularidad dia", ignore.case = TRUE)
})

test_that("identificadores se describen sin exponer ejemplos literales completos", {
  df <- data.frame(persona_id = c("P001", "P002", "P003"), stringsAsFactors = FALSE)

  profile <- profile_dataset_for_ai(df, dataset_name = "ids")
  rendered <- render_dataset_profile_for_ai(profile)

  expect_equal(profile$variables$persona_id$inferred_type, "identifier")
  expect_match(rendered, "persona_id")
  expect_false(grepl("P001|P002|P003", rendered))
  expect_match(rendered, "patron aproximado|patr[oó]n aproximado", ignore.case = TRUE)
})

test_that("texto libre se detecta y no expone valores reales", {
  df <- data.frame(
    observacion = c(
      "Seguimiento local con notas internas",
      "Caso derivado con informacion sensible",
      "Revision manual requerida por texto libre"
    ),
    stringsAsFactors = FALSE
  )

  profile <- profile_dataset_for_ai(df, dataset_name = "texto_libre")
  rendered <- render_dataset_profile_for_ai(profile)

  expect_equal(profile$variables$observacion$inferred_type, "free_text")
  expect_false(grepl("Seguimiento local|Caso derivado|Revision manual", rendered))
  expect_match(rendered, "texto libre", ignore.case = TRUE)
})

test_that("categoricas cortas no se confunden con texto libre por muestras chicas", {
  df <- data.frame(tramo = c("A", "B", "C"), stringsAsFactors = FALSE)

  profile <- profile_dataset_for_ai(df, dataset_name = "categorica_corta")
  rendered <- render_dataset_profile_for_ai(profile)

  expect_equal(profile$variables$tramo$inferred_type, "categorical")
  expect_match(rendered, "tramo: categorica", ignore.case = TRUE)
  expect_match(rendered, "A, B, C")
})
