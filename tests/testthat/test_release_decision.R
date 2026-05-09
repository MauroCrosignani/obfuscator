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

test_that("high-dimensional source-known data is flagged as relinkable", {
  df <- data.frame(
    sexo = c("F", "M", "F", "M", "F", "M"),
    edad = c("34", "45", "29", "52", "41", "38"),
    departamento = c("A", "B", "C", "D", "E", "F"),
    ocupacion = c("docente", "medico", "abogado", "contador", "arquitecta", "ingeniero"),
    tam_hogar = c("2", "4", "1", "3", "5", "2"),
    nivel_edu = c("terciaria", "secundaria", "terciaria", "primaria", "terciaria", "secundaria"),
    antiguedad = c("11", "7", "2", "19", "13", "5"),
    tramo_ingreso = c("alto", "medio", "bajo", "alto", "medio", "bajo"),
    stringsAsFactors = FALSE
  )

  alerts <- detect_high_dimensional_relinkability(
    df,
    known_source_cols = colnames(df),
    min_dimensions = 6,
    uniqueness_threshold = 0.8
  )

  expect_true(length(alerts) > 0)
  expect_true(any(vapply(alerts, function(alert) identical(alert$code, "high_dimensional_relinkability"), logical(1))))
})

test_that("repeated wide signatures do not trigger high-dimensional relinkability by default", {
  df <- data.frame(
    sexo = c("F", "F", "M", "M", "F", "F"),
    edad = c("30-39", "30-39", "40-49", "40-49", "30-39", "30-39"),
    departamento = c("A", "A", "B", "B", "A", "A"),
    ocupacion = c("admin", "admin", "admin", "admin", "admin", "admin"),
    tam_hogar = c("2", "2", "3", "3", "2", "2"),
    nivel_edu = c("sec", "sec", "sec", "sec", "sec", "sec"),
    antiguedad = c("0-5", "0-5", "6-10", "6-10", "0-5", "0-5"),
    tramo_ingreso = c("medio", "medio", "medio", "medio", "medio", "medio"),
    stringsAsFactors = FALSE
  )

  alerts <- detect_high_dimensional_relinkability(
    df,
    known_source_cols = colnames(df),
    min_dimensions = 6,
    uniqueness_threshold = 0.8
  )

  expect_equal(length(alerts), 0)
})

test_that("text fields require active review evidence", {
  review <- build_manual_review_result(
    object_id = "observacion",
    review_type = "text_free",
    verified = TRUE,
    evidence = list(unique_values_confirmed = 12)
  )

  expect_equal(review$object_id, "observacion")
  expect_equal(review$review_type, "text_free")
  expect_true(review$verified)
  expect_equal(review$evidence$unique_values_confirmed, 12)
})

test_that("manual review alone does not unlock blocked export", {
  review <- build_manual_review_result(
    object_id = "observacion",
    review_type = "text_free",
    verified = TRUE,
    evidence = list(unique_values_confirmed = 12)
  )
  st <- build_release_state(
    "Bloqueado",
    reasons = list("texto libre pendiente"),
    metadata = list(reviews = list(review))
  )

  expect_false(can_export_external_release(st))
})

test_that("release review requirements mark text and combinations as active blockers", {
  alerts <- list(
    release_alert(
      code = "text_like_column",
      severity = "critical",
      message = "Texto libre detectado",
      fields = "observacion",
      artifact_type = "internal_work"
    ),
    release_alert(
      code = "high_dimensional_relinkability",
      severity = "critical",
      message = "Reenlazabilidad alta",
      fields = c("sexo", "edad", "ocupacion"),
      artifact_type = "internal_work"
    )
  )

  requirements <- build_review_requirements(alerts)

  expect_true(requirements$required)
  expect_equal(length(requirements$items), 2)
  expect_true(any(vapply(requirements$items, function(item) identical(item$review_type, "text_free"), logical(1))))
  expect_true(any(vapply(requirements$items, function(item) identical(item$review_type, "relinkability"), logical(1))))
})

test_that("non-release report explains unresolved blockers", {
  report <- build_non_release_report(
    status = "Bloqueado",
    reasons = list("texto libre", "combinacion singular"),
    next_steps = list("excluir observacion", "generalizar fecha"),
    reviews = list(),
    metadata = list(privacy_satisfied = TRUE)
  )

  expect_match(report, "Bloqueado")
  expect_match(report, "texto libre")
  expect_match(report, "generalizar fecha")
  expect_match(report, "k-anonymity")
})

test_that("release report includes status controls and reviews", {
  review <- build_manual_review_result(
    object_id = "observacion",
    review_type = "text_free",
    verified = TRUE,
    evidence = list(unique_values_confirmed = 12)
  )

  report <- build_release_report(
    status = "Liberable",
    controls_passed = list("k-anonymity satisfecha", "sin identificadores directos"),
    reviews = list(review),
    metadata = list(artifact = release_artifact("releasable_external"))
  )

  expect_match(report, "Liberable")
  expect_match(report, "k-anonymity satisfecha")
  expect_match(report, "observacion")
  expect_match(report, "releasable_external")
})

test_that("audit summary adapts blocked states into actionable non-release guidance", {
  state <- build_release_state(
    "Bloqueado",
    reasons = list("La configuracion actual no satisface k-anonymity para liberacion externa.")
  )

  summary_text <- build_release_audit_summary(
    state,
    log_info = list(
      privacy_report = list(
        k = 5,
        after = list(satisfied = FALSE)
      )
    )
  )

  expect_match(summary_text, "Bloqueado")
  expect_match(summary_text, "no satisface k-anonymity")
  expect_match(summary_text, "aumentar k o generalizar")
})

test_that("audit summary uses release controls when the dataset is releasable", {
  state <- build_release_state(
    "Liberable",
    metadata = list(artifact = release_artifact("releasable_external"))
  )

  summary_text <- build_release_audit_summary(
    state,
    log_info = list(
      roles = list(id = "ID"),
      transformations = list(ID = list(method = "deterministic-map"), edad = list(method = "range_random")),
      privacy_report = list(
        k = 5,
        rows_suppressed = 2,
        after = list(satisfied = TRUE)
      )
    )
  )

  expect_match(summary_text, "Liberable")
  expect_match(summary_text, "k-anonymity satisfecha")
  expect_match(summary_text, "identificadores transformados")
  expect_match(summary_text, "supresion residual aplicada")
})
