library(testthat)

source(file.path("..", "..", "R", "obfuscator_core.R"))
source(file.path("..", "..", "R", "shiny_app.R"))

test_that("canonical release-safe roles and priority are stable", {
  expect_equal(
    release_safe_allowed_roles(),
    c("ID", "QI", "SENS", "PRIV", "KEEP", "EXC")
  )

  expect_equal(
    names(release_safe_role_priority()),
    c("ID", "PRIV", "SENS", "QI", "EXC", "KEEP")
  )
})

test_that("demo dataset suggestions are explainable and follow release-safe semantics", {
  df <- build_demo_personas_dataset()

  suggestions <- suggest_release_safe_roles(df)

  expect_equal(suggestions$edad$role, "QI")
  expect_match(suggestions$edad$reason, "combin|edad|cuasi", ignore.case = TRUE)

  expect_equal(suggestions$observacion$role, "PRIV")
  expect_match(suggestions$observacion$reason, "texto|priv|observ", ignore.case = TRUE)

  expect_equal(suggestions$indicador_privado$role, "SENS")
  expect_match(suggestions$indicador_privado$reason, "sens|privad|delicad", ignore.case = TRUE)
})

test_that("canonical quasi identifiers exclude sensitive and private suggestions", {
  df <- build_demo_personas_dataset()

  suggestions <- suggest_release_safe_roles(df)
  qis <- release_safe_quasi_identifiers(suggestions)

  expect_true(all(c("fecha_alta", "tramo", "departamento", "edad", "ingreso") %in% qis))
  expect_false("persona_id" %in% qis)
  expect_false("indicador_privado" %in% qis)
  expect_false("observacion" %in% qis)
})

test_that("column-level helper returns the highest-priority matching role", {
  repeated_id_text <- sprintf("ID formal %03d", seq_len(12))

  id_suggestion <- suggest_release_safe_role_for_column(
    column_name = "persona_id_observacion",
    column_data = repeated_id_text
  )
  expect_equal(id_suggestion$role, "ID")
  expect_match(id_suggestion$reason, "id|ident", ignore.case = TRUE)

  private_text_suggestion <- suggest_release_safe_role_for_column(
    column_name = "observacion",
    column_data = c(
      "texto libre extenso con detalle operativo",
      "texto libre extenso con riesgo contextual"
    )
  )
  expect_equal(private_text_suggestion$role, "PRIV")
})
