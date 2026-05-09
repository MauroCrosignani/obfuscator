library(testthat)

source(file.path("..", "..", "R", "obfuscator_core.R"))
source(file.path("..", "..", "R", "shiny_app.R"))

test_that("release state starts as not evaluated", {
  st <- initial_release_state()

  expect_s3_class(st, "release_state")
  expect_equal(st$status, "No evaluado")
  expect_equal(st$reasons, list())
  expect_false(st$can_export_external)
  expect_equal(st$metadata, list())
})

test_that("release state can be built as explicitly releasable", {
  st <- build_release_state("Liberable", metadata = list(trigger = "privacy_pass"))

  expect_equal(st$status, "Liberable")
  expect_true(st$can_export_external)
  expect_equal(st$metadata$trigger, "privacy_pass")
})

test_that("release state transitions through review and blocking states", {
  st <- initial_release_state()
  reviewing <- transition_release_state(st, "start_review")
  blocked <- transition_release_state(
    reviewing,
    "block",
    context = list(reasons = list("k-anonymity no satisfecha"))
  )

  expect_equal(reviewing$status, "En revision")
  expect_equal(blocked$status, "Bloqueado")
  expect_false(can_export_external_release(blocked))
  expect_equal(blocked$reasons, list("k-anonymity no satisfecha"))
})

test_that("release state can become releasable after review", {
  reviewing <- transition_release_state(initial_release_state(), "start_review")
  releasable <- transition_release_state(
    reviewing,
    "approve",
    context = list(metadata = list(trigger = "privacy_pass"))
  )

  expect_equal(releasable$status, "Liberable")
  expect_true(can_export_external_release(releasable))
  expect_equal(releasable$metadata$trigger, "privacy_pass")
})

test_that("no-liberable state requires material changes before restarting", {
  non_releasable <- transition_release_state(
    initial_release_state(),
    "mark_non_releasable",
    context = list(reasons = list("texto libre sin tratamiento seguro"))
  )

  stuck <- transition_release_state(non_releasable, "start_review")
  restarted <- transition_release_state(
    non_releasable,
    "material_change",
    context = list(metadata = list(change_type = "schema_update"))
  )

  expect_equal(non_releasable$status, "No liberable sin rediseno")
  expect_equal(stuck$status, "No liberable sin rediseno")
  expect_false(can_export_external_release(stuck))
  expect_equal(restarted$status, "No evaluado")
  expect_equal(restarted$metadata$change_type, "schema_update")
})

test_that("internal preview does not imply releasable export", {
  st <- build_release_state("Bloqueado", metadata = list(
    has_internal_preview = TRUE,
    artifact = release_artifact("internal_work")
  ))

  expect_true(st$metadata$has_internal_preview)
  expect_equal(st$metadata$artifact$type, "internal_work")
  expect_false(can_export_external_release(st))
})

test_that("internal obfuscation output is not automatically marked releasable", {
  blocked <- derive_release_state_from_obfuscation(
    privacy_enabled = FALSE,
    privacy_satisfied = FALSE,
    has_internal_preview = TRUE
  )
  releasable <- derive_release_state_from_obfuscation(
    privacy_enabled = TRUE,
    privacy_satisfied = TRUE,
    has_internal_preview = TRUE
  )

  expect_equal(blocked$metadata$artifact$type, "internal_work")
  expect_false(can_export_external_release(blocked))
  expect_true(can_export_external_release(releasable))
})

test_that("nominal high-risk detector includes approved patterns", {
  cols <- c("pers_id", "emp", "telefono", "comentario", "monto")
  flagged <- detect_high_risk_name_patterns(cols)

  expect_true(all(c("pers_id", "emp", "telefono", "comentario") %in% flagged))
  expect_false("monto" %in% flagged)
})

test_that("text-like long fields are flagged for review", {
  df <- data.frame(
    observacion = c(
      "Paciente derivado por cuadro raro con seguimiento externo",
      "Empresa con nota libre y referencia a expediente interno"
    ),
    stringsAsFactors = FALSE
  )

  alerts <- detect_high_risk_columns(df)

  expect_true(any(vapply(alerts, function(alert) identical(alert$code, "text_like_column"), logical(1))))
  expect_true(any(vapply(alerts, function(alert) "observacion" %in% alert$fields, logical(1))))
})

test_that("high-cardinality identifier-like columns are flagged for review", {
  df <- data.frame(
    pers_identificador = sprintf("ID-%03d", 1:10),
    monto = seq(100, 1000, by = 100),
    stringsAsFactors = FALSE
  )

  alerts <- detect_high_risk_columns(df)

  expect_true(any(vapply(alerts, function(alert) identical(alert$code, "high_cardinality_identifier"), logical(1))))
  expect_true(any(vapply(alerts, function(alert) "pers_identificador" %in% alert$fields, logical(1))))
})

test_that("combinations below k are flagged", {
  df <- data.frame(
    edad = c("40-49", "40-49", "50-59"),
    zona = c("A", "A", "B"),
    sector = c("x", "x", "y"),
    stringsAsFactors = FALSE
  )

  alerts <- detect_risky_combinations(df, cols = c("edad", "zona", "sector"), k = 2)

  expect_true(length(alerts) > 0)
  expect_true(any(vapply(alerts, function(alert) identical(alert$code, "combination_below_k"), logical(1))))
})

test_that("meeting k does not automatically clear homogeneous sensitive classes", {
  df <- data.frame(
    edad = c("40-49", "40-49", "40-49", "40-49"),
    zona = c("A", "A", "A", "A"),
    diagnostico = c("raro", "raro", "raro", "raro"),
    stringsAsFactors = FALSE
  )

  alerts <- detect_residual_risk_combinations(
    df,
    quasi_cols = c("edad", "zona"),
    sensitive_cols = "diagnostico",
    k = 4
  )

  expect_true(length(alerts) > 0)
  expect_true(any(vapply(alerts, function(alert) identical(alert$code, "homogeneous_sensitive_class"), logical(1))))
})

test_that("precise linkable combinations remain blocked even when k passes", {
  df <- data.frame(
    fecha = c("2026-01-03", "2026-01-03", "2026-01-03", "2026-01-03"),
    localidad = c("Pueblo Chico", "Pueblo Chico", "Pueblo Chico", "Pueblo Chico"),
    evento = c("operativo", "operativo", "operativo", "operativo"),
    stringsAsFactors = FALSE
  )

  alerts <- detect_residual_risk_combinations(
    df,
    quasi_cols = c("fecha", "localidad", "evento"),
    sensitive_cols = character(0),
    k = 4
  )

  expect_true(length(alerts) > 0)
  expect_true(any(vapply(alerts, function(alert) identical(alert$code, "precise_linkable_combination"), logical(1))))
})
