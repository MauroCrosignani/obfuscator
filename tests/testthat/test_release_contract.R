library(testthat)

source(file.path("..", "..", "R", "obfuscator_core.R"))

test_that("the canonical release state shape is stable", {
  state <- release_decision_for_api(list(
    artifact = release_artifact("releasable_external", name = "partner_extract.csv"),
    signals = list(
      direct_identifiers_removed = TRUE,
      dates_generalized = TRUE,
      distinctive_numerics_masked = TRUE,
      rare_categories_grouped = TRUE,
      text_like_risk = FALSE
    )
  ))

  expect_equal(
    names(state),
    c("verdict", "can_release", "artifact", "alerts", "manual_review")
  )
  expect_match(
    state$verdict,
    "^(Liberable|Requiere revision manual|No liberable sin rediseno)$"
  )
  expect_type(state$can_release, "logical")
  expect_equal(length(state$can_release), 1)
  expect_equal(state$artifact$type, "releasable_external")
  expect_type(state$alerts, "list")
  expect_equal(names(state$manual_review), c("required", "evidence"))
})

test_that("the canonical alert shape is stable", {
  alert <- release_alert(
    code = "rare_category_risk",
    severity = "warning",
    message = "Rare categories remain visible in the artifact.",
    fields = "provincia",
    artifact_type = "preview",
    evidence = list(level = "Localidad-X")
  )

  expect_equal(
    names(alert),
    c("code", "severity", "message", "fields", "artifact_type", "evidence")
  )
  expect_equal(alert$code, "rare_category_risk")
  expect_equal(alert$severity, "warning")
  expect_equal(alert$artifact_type, "preview")
  expect_equal(alert$fields, "provincia")
  expect_type(alert$evidence, "list")
})

test_that("the canonical manual-review evidence shape is stable", {
  evidence <- manual_review_evidence(
    kind = "text_like_risk",
    summary = "Free-text notes still contain re-identification clues.",
    fields = c("observaciones", "comentarios"),
    examples = c("Paciente derivado por cuadro raro", "Turno reagendado por fecha exacta"),
    recommendation = "Redact or exclude free text before external release."
  )

  expect_equal(
    names(evidence),
    c("kind", "summary", "fields", "examples", "recommendation")
  )
  expect_equal(evidence$kind, "text_like_risk")
  expect_equal(evidence$fields, c("observaciones", "comentarios"))
  expect_length(evidence$examples, 2)
  expect_match(evidence$recommendation, "Redact|exclude")
})

test_that("artifact typing is canonical and restricted", {
  expect_equal(release_artifact("preview")$type, "preview")
  expect_equal(release_artifact("internal_work")$type, "internal_work")
  expect_equal(release_artifact("releasable_external")$type, "releasable_external")
  expect_error(release_artifact("draft_attachment"), "artifact")
})
