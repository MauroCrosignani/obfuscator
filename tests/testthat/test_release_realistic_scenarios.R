library(testthat)

source(file.path("..", "..", "R", "obfuscator_core.R"))

liberable_release_fixture <- function() {
  list(
    artifact = list(
      type = "releasable_external",
      name = "ventas_mensuales_socios_2026-04.csv"
    ),
    signals = list(
      direct_identifiers_removed = TRUE,
      dates_generalized = TRUE,
      distinctive_numerics_masked = TRUE,
      rare_categories_grouped = TRUE,
      text_like_risk = FALSE
    ),
    evidence = list(
      transformed_fields = c("fecha_alta", "ingreso_mensual", "segmento"),
      notes = c(
        "Exact dates were reduced to month-level buckets.",
        "Rare partner segments were grouped into OTROS.",
        "Distinctive income values were obfuscated before release."
      )
    )
  )
}

redesign_required_fixture <- function() {
  list(
    artifact = list(
      type = "releasable_external",
      name = "casos_clinicos_terceros_2026-04.csv"
    ),
    signals = list(
      direct_identifiers_removed = TRUE,
      dates_generalized = FALSE,
      distinctive_numerics_masked = FALSE,
      rare_categories_grouped = FALSE,
      text_like_risk = TRUE
    ),
    evidence = list(
      risky_fields = c("fecha_evento", "monto_exacto", "diagnostico_texto", "subespecialidad"),
      notes = c(
        "Exact event dates remain in the release artifact.",
        "A distinctive amount 987654.32 appears unchanged.",
        "Free-text diagnosis notes still describe rare conditions.",
        "Rare categories were not grouped before external sharing."
      )
    )
  )
}

ui_shape_from_fixture <- function(fixture) {
  list(
    artifact_type = fixture$artifact$type,
    artifact_name = fixture$artifact$name,
    direct_identifiers_removed = fixture$signals$direct_identifiers_removed,
    dates_generalized = fixture$signals$dates_generalized,
    distinctive_numerics_masked = fixture$signals$distinctive_numerics_masked,
    rare_categories_grouped = fixture$signals$rare_categories_grouped,
    text_like_risk = fixture$signals$text_like_risk,
    evidence = fixture$evidence
  )
}

source_core_from_isolated_workdir <- function() {
  core_path <- normalizePath(
    file.path("..", "..", "R", "obfuscator_core.R"),
    winslash = "/",
    mustWork = TRUE
  )
  original_wd <- getwd()
  on.exit(setwd(original_wd), add = TRUE)
  setwd(tempdir())

  script_env <- new.env(parent = globalenv())
  source(core_path, local = script_env)
  script_env
}

test_that("a realistic third-party release can be Liberable", {
  state <- release_decision_for_api(liberable_release_fixture())

  expect_equal(state$verdict, "Liberable")
  expect_true(state$can_release)
  expect_length(state$alerts, 0)
  expect_false(state$manual_review$required)
})

test_that("a realistic risky release becomes No liberable sin rediseno", {
  state <- release_decision_for_api(redesign_required_fixture())

  expect_equal(state$verdict, "No liberable sin rediseno")
  expect_false(state$can_release)
  expect_true(length(state$alerts) >= 3)
  expect_false(state$manual_review$required)
  expect_true(any(vapply(state$alerts, `[[`, character(1), "code") == "text_like_risk"))
})

test_that("ui-facing helpers match a real script-facing load of the release contract", {
  fixture <- redesign_required_fixture()
  script_env <- source_core_from_isolated_workdir()

  ui_state <- release_decision_for_ui(ui_shape_from_fixture(fixture))
  expect_true(exists("release_decision_for_api", envir = script_env, inherits = FALSE))
  api_state <- script_env$release_decision_for_api(fixture)

  expect_equal(ui_state$verdict, api_state$verdict)
  expect_equal(ui_state$can_release, api_state$can_release)
  expect_equal(ui_state$artifact$type, api_state$artifact$type)
})
