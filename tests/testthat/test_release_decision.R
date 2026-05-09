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
