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

test_that("release-safe variable table helpers expose one row per variable", {
  df <- build_demo_personas_dataset()
  rows <- build_release_variable_rows(
    df,
    role_state = build_default_ui_roles(df),
    suggested_roles = suggest_release_safe_roles(df)
  )

  expect_length(rows, ncol(df))
  expect_true(all(c(
    "variable", "type", "role", "treatment", "risk", "status", "action_label"
  ) %in% names(rows[[1]])))

  edad_row <- rows[[match("edad", vapply(rows, `[[`, character(1), "variable"))]]
  observacion_row <- rows[[match("observacion", vapply(rows, `[[`, character(1), "variable"))]]

  expect_equal(edad_row$role, "QI")
  expect_match(edad_row$treatment, "rango|generaliz|cuasi", ignore.case = TRUE)
  expect_match(edad_row$risk, "alto|medio", ignore.case = TRUE)

  expect_equal(observacion_row$role, "PRIV")
  expect_match(observacion_row$type, "Texto", ignore.case = TRUE)
  expect_match(observacion_row$status, "bloquea|revis", ignore.case = TRUE)
})

test_that("main classification table render exposes release-safe columns and role badges", {
  html <- as.character(render_release_variable_table_for_test(build_demo_personas_dataset()))

  expect_match(html, "Variable")
  expect_match(html, "Tipo")
  expect_match(html, "Rol")
  expect_match(html, "Tratamiento")
  expect_match(html, "Riesgo")
  expect_match(html, "Estado")
  expect_match(html, "Accion")
  expect_match(html, "Editar")
  expect_match(html, "release-variable-table")
  expect_match(html, "release-role-badge")
})

test_that("main classification table renders an inline role control per row", {
  df <- build_demo_personas_dataset()

  html <- as.character(render_release_variable_table_for_test(df))

  expect_match(html, "release-role-control")
  expect_match(html, "release_role__edad")
  expect_match(html, "release_role__observacion")
})

test_that("quick role changes update visible QI state, table row and release summary", {
  df <- build_demo_personas_dataset()
  roles <- build_default_ui_roles(df)

  initial_sets <- release_safe_display_role_sets(df, roles)
  expect_true("edad" %in% initial_sets$qi)
  expect_false("edad" %in% initial_sets$sensitive)

  updated_roles <- apply_release_safe_role_change(df, roles, "edad", "SENS")
  updated_sets <- release_safe_display_role_sets(df, updated_roles)

  expect_false("edad" %in% updated_sets$qi)
  expect_true("edad" %in% updated_sets$sensitive)
  expect_false("edad" %in% (updated_roles$numeric %||% character(0)))
  expect_true("edad" %in% (updated_roles$sensitive %||% character(0)))

  rows <- build_release_variable_rows(
    df,
    role_state = updated_roles,
    suggested_roles = suggest_release_safe_roles(df)
  )
  edad_row <- rows[[match("edad", vapply(rows, `[[`, character(1), "variable"))]]
  expect_equal(edad_row$role, "SENS")
  expect_match(edad_row$status, "Revisar", ignore.case = TRUE)

  summary_html <- as.character(build_release_role_summary(df, updated_roles))
  expect_true(grepl("Variables sensibles", summary_html, fixed = TRUE))
  expect_true(grepl("edad", summary_html, fixed = TRUE))
})

test_that("variable detail helper exposes contextual release-safe content", {
  df <- build_demo_personas_dataset()
  roles <- build_default_ui_roles(df)
  suggestions <- suggest_release_safe_roles(df)

  edad_detail <- build_release_variable_detail(
    df,
    var_name = "edad",
    role_state = roles,
    suggested_roles = suggestions
  )
  observacion_detail <- build_release_variable_detail(
    df,
    var_name = "observacion",
    role_state = roles,
    suggested_roles = suggestions
  )
  indicador_detail <- build_release_variable_detail(
    df,
    var_name = "indicador_privado",
    role_state = roles,
    suggested_roles = suggestions
  )

  expect_true(all(c(
    "variable", "type", "role", "summary", "treatment",
    "impact", "help", "suggestion_reason"
  ) %in% names(edad_detail)))

  expect_equal(edad_detail$variable, "edad")
  expect_equal(edad_detail$role, "QI")
  expect_match(edad_detail$type, "Numerica", ignore.case = TRUE)
  expect_match(edad_detail$treatment, "rango|generaliz|cuasi", ignore.case = TRUE)
  expect_match(edad_detail$impact, "k-anonymity|quasi|revision", ignore.case = TRUE)
  expect_match(edad_detail$help, "edad|sugeri|combin", ignore.case = TRUE)

  expect_equal(observacion_detail$role, "PRIV")
  expect_match(observacion_detail$type, "Texto", ignore.case = TRUE)
  expect_match(observacion_detail$treatment, "manual|exclusion|expresiv", ignore.case = TRUE)
  expect_match(observacion_detail$impact, "bloque|manual|k-anonymity", ignore.case = TRUE)
  expect_match(observacion_detail$help, "texto|observ|priv", ignore.case = TRUE)

  expect_equal(indicador_detail$role, "SENS")
  expect_match(indicador_detail$treatment, "conservar|riesgo|excluir", ignore.case = TRUE)
  expect_match(indicador_detail$impact, "revision|residual|k-anonymity", ignore.case = TRUE)
  expect_match(indicador_detail$help, "sens|privad|delicad", ignore.case = TRUE)
})

test_that("variable detail panel render includes the five expected blocks", {
  df <- build_demo_personas_dataset()

  html <- as.character(
    render_release_variable_detail_panel_for_test(
      df,
      selected_var = "observacion"
    )
  )

  expect_match(html, "release-variable-detail")
  expect_match(html, "Resumen")
  expect_match(html, "Rol principal")
  expect_match(html, "Tratamiento tecnico")
  expect_match(html, "Impacto")
  expect_match(html, "Ayuda")
  expect_match(html, "observacion")
  expect_match(html, "Texto", ignore.case = TRUE)
  expect_match(html, "PRIV")
})
