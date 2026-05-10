library(testthat)

source(file.path("..", "..", "R", "obfuscator_core.R"))
source(file.path("..", "..", "R", "shiny_app.R"))

test_that("role templates still persist and load by schema hash under the release model", {
  df <- data.frame(
    patient_id = 1:3,
    city = c("A", "B", "C"),
    notes = c("x", "y", "z"),
    stringsAsFactors = FALSE
  )

  template_path <- file.path(
    tempdir(),
    "config",
    paste0(generate_schema_hash(df), ".json")
  )
  dir.create(dirname(template_path), recursive = TRUE, showWarnings = FALSE)

  template <- build_persistable_role_template(
    role_state = list(
      available = "notes",
      id = "patient_id",
      categorical = "city",
      sensitive = "notes",
      exclude = "notes"
    ),
    hierarchies = list(
      city = list(
        REGION = c("A", "B", "C")
      )
    ),
    numeric_offsets = list(patient_id = 500123),
    release_state = release_decision_for_api(list(
      artifact = release_artifact("internal_work", name = "review.csv"),
      signals = list(
        direct_identifiers_removed = TRUE,
        dates_generalized = TRUE,
        distinctive_numerics_masked = TRUE,
        rare_categories_grouped = TRUE,
        text_like_risk = FALSE
      )
    )),
    manual_review = list(
      manual_review_evidence(
        kind = "text_like_risk",
        summary = "Restricted review artifact.",
        fields = "notes",
        recommendation = "Do not persist this in ordinary templates."
      )
    )
  )

  save_roles_to_json(template, template_path)
  loaded <- load_roles_from_json(df, template_path)

  expect_equal(loaded$exact$id, "patient_id")
  expect_equal(loaded$exact$categorical, "city")
  expect_equal(loaded$exact$sensitive, "notes")
  expect_equal(loaded$exact$exclude, "notes")
  expect_equal(loaded$hierarchies$city$REGION, c("A", "B", "C"))
  expect_false("numeric_offsets" %in% names(loaded))
  expect_false("release_state" %in% names(loaded))
  expect_false("manual_review" %in% names(loaded))
})

test_that("fuzzy suggestions still appear for near-match schemas", {
  original_df <- data.frame(
    patient_id = 1:3,
    city_name = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )
  new_df <- data.frame(
    patient_id = 1:3,
    city_nam = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )

  template_path <- tempfile(fileext = ".json")

  save_roles_to_json(
    build_persistable_role_template(
      role_state = list(
        id = "patient_id",
        categorical = "city_name"
      )
    ),
    template_path
  )

  loaded <- load_roles_from_json(new_df, template_path)

  expect_equal(loaded$exact$id, "patient_id")
  expect_equal(loaded$suggested$city_nam$role, "categorical")
  expect_equal(loaded$suggested$city_nam$original, "city_name")
  expect_gt(loaded$suggested$city_nam$score, 0.8)
})

test_that("loading ignores release-review metadata without corrupting persisted roles", {
  df <- data.frame(
    patient_id = 1:2,
    city = c("A", "B"),
    notes = c("alpha", "beta"),
    stringsAsFactors = FALSE
  )
  template_path <- tempfile(fileext = ".json")

  jsonlite::write_json(
    list(
      id = "patient_id",
      categorical = "city",
      exclude = "notes",
      hierarchies = list(city = list(REGION = c("A", "B"))),
      release_state = release_decision_for_api(list(
        artifact = release_artifact("internal_work", name = "review.csv"),
        signals = list(
          direct_identifiers_removed = TRUE,
          dates_generalized = TRUE,
          distinctive_numerics_masked = TRUE,
          rare_categories_grouped = FALSE,
          text_like_risk = FALSE
        )
      )),
      manual_review = list(
        manual_review_evidence(
          kind = "warning_review",
          summary = "Residual warning.",
          fields = "city",
          recommendation = "Keep this restricted."
        )
      ),
      artifact = release_artifact("internal_work", name = "review.csv"),
      numeric_offsets = list(patient_id = 999999)
    ),
    template_path,
    auto_unbox = TRUE,
    pretty = TRUE
  )

  loaded <- load_roles_from_json(df, template_path)

  expect_equal(loaded$exact$id, "patient_id")
  expect_equal(loaded$exact$categorical, "city")
  expect_equal(loaded$exact$exclude, "notes")
  expect_equal(loaded$hierarchies$city$REGION, c("A", "B"))
  expect_false("artifact" %in% names(loaded))
  expect_false("release_state" %in% names(loaded))
  expect_false("manual_review" %in% names(loaded))
  expect_false("numeric_offsets" %in% names(loaded))
})

test_that("restricted release artifacts cannot be saved as ordinary templates", {
  template_path <- tempfile(fileext = ".json")

  expect_error(
    save_roles_to_json(
      list(
        id = "patient_id",
        release_state = release_decision_for_api(list(
          artifact = release_artifact("internal_work", name = "review.csv"),
          signals = list(
            direct_identifiers_removed = TRUE,
            dates_generalized = TRUE,
            distinctive_numerics_masked = TRUE,
            rare_categories_grouped = TRUE,
            text_like_risk = FALSE
          )
        ))
      ),
      template_path
    ),
    "persist|template|restricted|release"
  )
})
