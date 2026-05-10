library(testthat)

source(file.path("..", "..", "R", "obfuscator_core.R"))
source(file.path("..", "..", "R", "shiny_app.R"))

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

test_that("IDs numericos con duplicados se ofuscan sin warnings de longitud", {
  df <- data.frame(ID = c(101, 205, 101, 330, 205), stringsAsFactors = FALSE)

  expect_no_warning({
    out <- obfuscate_dataset(df, config = obfuscator_config(seed = 321, id_cols = "ID"))
    expect_equal(length(out$ID), nrow(df))
    expect_equal(length(unique(out$ID)), length(unique(df$ID)))
  })
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

test_that("las etiquetas de variables exponen el nombre completo para tooltip", {
  ui <- render_role_zone_ui(
    title = "Disponibles",
    role_name = "available",
    variables = "NOMBRE_DE_COLUMNA_DEMASIADO_LARGO_PARA_VERSE_COMPLETO",
    numeric_cols = character(0)
  )

  html <- as.character(ui)

  expect_match(html, 'class="var-label"')
  expect_match(html, 'title="NOMBRE_DE_COLUMNA_DEMASIADO_LARGO_PARA_VERSE_COMPLETO"')
  expect_match(html, 'data-full-label="NOMBRE_DE_COLUMNA_DEMASIADO_LARGO_PARA_VERSE_COMPLETO"')
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

test_that("las definiciones release-safe explican cada rol con lenguaje minimo claro", {
  glossary <- release_safe_role_glossary()

  expect_true(all(release_safe_allowed_roles() %in% names(glossary)))
  expect_match(release_safe_role_definition("QI"), "k-anonymity|combin", ignore.case = TRUE)
  expect_match(release_safe_role_definition("SENS"), "delicad|sensible", ignore.case = TRUE)
  expect_match(release_safe_role_definition("PRIV"), "texto libre|riesgos", ignore.case = TRUE)
})

test_that("la guia release-safe expone flujo breve y definiciones de roles", {
  html <- as.character(render_release_workflow_guide_for_test())

  expect_match(html, "Guia breve de trabajo")
  expect_match(html, "k-anonymity")
  expect_match(html, "Carga el dataset")
  expect_match(html, "uso interno", ignore.case = TRUE)
  expect_match(html, "liberacion", ignore.case = TRUE)
  expect_match(html, "Exporta solo si el estado final del dataset es Liberable")
  expect_match(html, "Roles principales")
  expect_match(html, "ID")
  expect_match(html, "QI")
  expect_match(html, "SENS")
  expect_match(html, "PRIV")
  expect_match(html, "KEEP")
  expect_match(html, "EXC")
})

test_that("invalid k values are normalized for release-safe privacy model", {
  df <- build_demo_personas_dataset()
  roles <- build_default_ui_roles(df)

  privacy_model <- build_release_safe_privacy_model(
    df,
    role_state = roles,
    k_enabled = TRUE,
    k_value = 1,
    k_suppression = "rows",
    group_ids = FALSE,
    hierarchies = list(),
    suggested_roles = suggest_release_safe_roles(df)
  )

  expect_equal(privacy_model$k, 2)
})

test_that("privacy meter state aligns with a liberable evaluated release", {
  df <- build_demo_personas_dataset()
  roles <- build_default_ui_roles(df)
  log_info <- list(
    privacy_report = list(
      after = list(satisfied = TRUE)
    )
  )

  meter <- release_safe_privacy_meter_state(
    role_state = roles,
    k_value = 5,
    hierarchy_count = 0,
    release_state = build_release_state("Liberable"),
    log_info = log_info
  )

  expect_equal(meter$label, "Liberable")
  expect_equal(meter$color_class, "meter-high")
  expect_true(meter$score >= 82)
})

test_that("privacy meter help explains heuristics and limits", {
  html <- as.character(render_privacy_meter_help_content())

  expect_match(html, "estimacion preliminar", ignore.case = TRUE)
  expect_match(html, "heuristica orientativa", ignore.case = TRUE)
  expect_match(html, "l-diversity", ignore.case = TRUE)
})

test_that("preview formatter renders Date columns as ISO text", {
  df <- data.frame(
    fecha = as.Date(c("2024-01-01", NA)),
    valor = c(10, 20)
  )

  out <- format_preview_dataset(df)

  expect_type(out$fecha, "character")
  expect_equal(out$fecha[[1]], "2024-01-01")
  expect_true(is.na(out$fecha[[2]]))
  expect_equal(out$valor, df$valor)
})

test_that("preview mode control locks after obfuscation exists", {
  locked_html <- as.character(build_preview_mode_control(TRUE))
  editable_html <- as.character(build_preview_mode_control(FALSE))

  expect_match(locked_html, "disabled")
  expect_match(locked_html, "resultado ofuscado")
  expect_match(editable_html, "live_preview")
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

test_that("release UI uses one canonical parameter configuration", {
  cfg <- studio_parameter_defaults()

  expect_equal(cfg$k_value, 5)
  expect_equal(cfg$id_prefix, "999")
  expect_null(cfg$project_key)
  expect_equal(cfg$numeric_mode, "range_random")
  expect_true(cfg$enable_k)
})

test_that("dataset display name comes from the loaded source", {
  expect_equal(resolve_dataset_display_name("environment", object_name = "iris"), "iris")
  expect_equal(
    resolve_dataset_display_name("file", file_name = "personas.xlsx"),
    "personas.xlsx"
  )
})

test_that("studio demo datasets include built-ins and a mixed synthetic case", {
  demo_sets <- studio_demo_datasets()

  expect_true(all(c("iris", "mtcars", "airquality", "obfuscator_demo_personas") %in% names(demo_sets)))
  expect_true(all(c(
      "persona_id",
      "fecha_alta",
      "tramo",
      "departamento",
      "edad",
      "ingreso",
      "indicador_privado",
      "observacion"
    ) %in% names(demo_sets$obfuscator_demo_personas)))
})

test_that("release review enrichment separates sensitive and private demo fields", {
  df <- build_demo_personas_dataset()
  roles <- build_default_ui_roles(df)

  expect_true("indicador_privado" %in% (roles$sensitive %||% character(0)))
  expect_true("observacion" %in% (roles$private %||% character(0)))
  expect_false("indicador_privado" %in% roles$categorical)
  expect_false("observacion" %in% roles$categorical)
})

test_that("quasi identifiers exclude sensitive and private roles", {
  df <- build_demo_personas_dataset()
  roles <- list(
    id = "persona_id",
    date = "fecha_alta",
    categorical = c("tramo", "departamento"),
    sensitive = "indicador_privado",
    private = "observacion"
  )

  qis <- quasi_identifier_choices(df, roles)

  expect_true(all(c("persona_id", "fecha_alta", "tramo", "departamento") %in% qis))
  expect_false("indicador_privado" %in% qis)
  expect_false("observacion" %in% qis)
})

test_that("release-safe privacy model includes numeric QI and keeps SENS/PRIV out of k-anonymity", {
  df <- build_demo_personas_dataset()
  roles <- build_default_ui_roles(df)
  suggestions <- suggest_release_safe_roles(df)

  privacy_model <- build_release_safe_privacy_model(
    df,
    role_state = roles,
    k_enabled = TRUE,
    k_value = 5,
    k_suppression = "group",
    group_ids = TRUE,
    suggested_roles = suggestions
  )
  audit_context <- build_release_safe_audit_context(
    df,
    role_state = roles,
    suggested_roles = suggestions
  )

  expect_equal(privacy_model$type, "k_anonymity")
  expect_equal(privacy_model$k, 5)
  expect_equal(privacy_model$suppression, "group")
  expect_true(privacy_model$group_ids)
  expect_true(all(c("fecha_alta", "tramo", "departamento", "edad", "ingreso") %in% privacy_model$quasi_identifiers))
  expect_false("indicador_privado" %in% privacy_model$quasi_identifiers)
  expect_false("observacion" %in% privacy_model$quasi_identifiers)

  expect_true("edad" %in% audit_context$qi)
  expect_true("indicador_privado" %in% audit_context$sensitive)
  expect_true("observacion" %in% audit_context$private)
})

test_that("download control renders a blocked action when release is not allowed", {
  control <- build_download_button_control(initial_release_state())
  html <- as.character(control)

  expect_match(html, "download_blocked")
  expect_match(html, "bloqueado")
})

test_that("the main UI renders a single parameters section", {
  ui_text <- paste(capture.output(print(run_obfuscator_app_ui_for_test())), collapse = "\n")

  expect_equal(sum(gregexpr("studio-icon-settings", ui_text, fixed = TRUE)[[1]] > 0), 1)
  expect_equal(sum(gregexpr("id=\"k_value\"", ui_text, fixed = TRUE)[[1]] > 0), 1)
  expect_equal(sum(gregexpr("id=\"id_prefix\"", ui_text, fixed = TRUE)[[1]] > 0), 1)
  expect_equal(sum(gregexpr("id=\"project_key\"", ui_text, fixed = TRUE)[[1]] > 0), 1)
  expect_equal(sum(gregexpr("id=\"numeric_mode\"", ui_text, fixed = TRUE)[[1]] > 0), 1)
  expect_match(ui_text, "Modo numerico general")
})

test_that("the main UI includes the release-safe variable table as visible primary structure", {
  ui_text <- paste(capture.output(print(run_obfuscator_app_ui_for_test())), collapse = "\n")

  expect_match(ui_text, "release_variable_table_ui")
  expect_match(ui_text, "Tabla principal por variable")
  expect_match(ui_text, "mecanismo principal de clasificacion")
  expect_match(ui_text, "Modo heredado de arrastre \\(experimental\\)")
  expect_match(ui_text, "Tablero heredado")
  expect_match(ui_text, "show_privacy_meter_help")
  expect_match(ui_text, "preview_mode_ui")
})

test_that("generated R code reflects release privacy inputs and warns about approval", {
  code <- build_obfuscation_code_snippet(
    data_reference = "iris",
    seed = 123,
    id_prefix = "999",
    numeric_mode = "range_random",
    project_key = NULL,
    col_roles = list(
      id = "id_persona",
      date = "fecha_evento",
      categorical = "tramo",
      exclude = "observacion"
    ),
    numeric_offsets = list(id_persona = 17),
    hierarchies = list(tramo = c("identity", "global")),
    privacy_model = list(
      type = "k_anonymity",
      k = 5,
      quasi_identifiers = c("id_persona", "fecha_evento", "tramo"),
      suppression = "group",
      group_ids = TRUE,
      hierarchies = list(tramo = c("identity", "global"))
    )
  )

  expect_match(code, "quasi_identifiers")
  expect_match(code, "group_ids = TRUE")
  expect_match(code, "suppression = 'group'")
  expect_match(code, "hierarchies_obj")
  expect_match(code, "NO implica que el dataset sea liberable")
})
