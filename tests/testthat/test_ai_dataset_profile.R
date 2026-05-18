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

test_that("profile_dataset_for_ai sigue funcionando sin tipo_fuente", {
  profile <- profile_dataset_for_ai(iris, dataset_name = "iris")

  expect_true("source_context" %in% names(profile))
  expect_null(profile$source_context$type)
  expect_equal(profile$source_context$source, "none")
})

test_that("tipo_fuente declarado se registra en el perfil", {
  profile <- profile_dataset_for_ai(
    iris,
    dataset_name = "iris",
    tipo_fuente = "gca2"
  )
  rendered <- render_dataset_profile_for_ai(profile)

  expect_equal(profile$source_context$type, "gca2")
  expect_equal(profile$source_context$source, "declared_by_user")
  expect_match(rendered, "Fuente declarada por el usuario: gca2\\.", ignore.case = TRUE)
})

test_that("oracle es una categoria valida de tipo_fuente", {
  profile <- profile_dataset_for_ai(
    iris,
    dataset_name = "iris",
    tipo_fuente = "oracle"
  )

  expect_equal(profile$source_context$type, "oracle")
  expect_equal(profile$source_context$source, "declared_by_user")
})

test_that("valores invalidos de tipo_fuente advierten y sugieren oracle", {
  profile <- profile_dataset_for_ai(
    iris,
    dataset_name = "iris",
    tipo_fuente = "odbc"
  )

  expect_null(profile$source_context$type)
  expect_equal(profile$source_context$source, "none")
  expect_true(any(grepl("oracle", profile$warnings, ignore.case = TRUE)))
  expect_true(any(grepl("tipo_fuente", profile$warnings, ignore.case = TRUE)))
})

test_that("el perfil y el renderer incluyen porcentaje de faltantes por variable", {
  df <- data.frame(
    edad = c(23, NA, 31, NA),
    tramo = c("A", "B", NA, "C"),
    stringsAsFactors = FALSE
  )

  profile <- profile_dataset_for_ai(df, dataset_name = "faltantes")
  rendered <- render_dataset_profile_for_ai(profile)

  expect_equal(profile$variables$edad$missing_pct, 50)
  expect_equal(profile$variables$tramo$missing_pct, 25)
  expect_match(rendered, "faltantes 50\\.0%", ignore.case = TRUE)
  expect_match(rendered, "faltantes 25\\.0%", ignore.case = TRUE)
})

test_that("faltantes estructuralmente esperables no se presentan como alarma de calidad", {
  df <- data.frame(
    fecha_hasta = c(NA, NA, "2026-05-01", NA),
    stringsAsFactors = FALSE
  )

  profile <- profile_dataset_for_ai(df, dataset_name = "faltantes_esperables")
  rendered <- render_dataset_profile_for_ai(profile)

  expect_equal(profile$variables$fecha_hasta$missingness_hint, "expected")
  expect_match(rendered, "faltantes 75\\.0% \\(esperables\\)", ignore.case = TRUE)
})

test_that("faltantes altos no esperables generan senal de cautela", {
  df <- data.frame(
    ingreso = c(12000, NA, NA, 18000, NA),
    stringsAsFactors = FALSE
  )

  profile <- profile_dataset_for_ai(df, dataset_name = "faltantes_altos")
  rendered <- render_dataset_profile_for_ai(profile)

  expect_equal(profile$variables$ingreso$missingness_hint, "high_unexpected")
  expect_match(rendered, "faltantes 60\\.0% \\(revisar\\)", ignore.case = TRUE)
})

test_that("config opcional en espanol aplica overrides y registra origen", {
  df <- data.frame(
    fecha_hasta = c(NA, "2026-05-01", NA),
    diagnostico = c("A", "B", "C"),
    correo_contacto = c("ana@x.org", "bruno@x.org", "carla@x.org"),
    observacion = c("uno", "dos", "tres"),
    stringsAsFactors = FALSE
  )

  config <- list(
    faltantes_esperables = c("fecha_hasta"),
    columnas_sensibles = c("diagnostico"),
    columnas_identificatorias = c("correo_contacto"),
    columnas_texto_libre = c("observacion")
  )

  profile <- profile_dataset_for_ai(df, dataset_name = "config_basica", config = config)
  rendered <- render_dataset_profile_for_ai(profile)

  expect_equal(profile$variables$fecha_hasta$missingness_hint, "expected")
  expect_equal(profile$variables$diagnostico$role_guess, "sensitive")
  expect_equal(profile$variables$correo_contacto$inferred_type, "identifier")
  expect_equal(profile$variables$observacion$inferred_type, "free_text")
  expect_equal(profile$variables$diagnostico$classification_source, "declared_by_user")
  expect_equal(profile$variables$fecha_hasta$missingness_source, "declared_by_user")
  expect_true("columnas_sensibles" %in% profile$variables$diagnostico$applied_rules)
  expect_match(rendered, "Reglas declaradas por usuario", ignore.case = TRUE)
  expect_match(rendered, "diagnostico: columnas_sensibles", ignore.case = TRUE)
})

test_that("config puede sobreescribir una heuristica automatica", {
  df <- data.frame(tramo = c("A", "B", "C"), stringsAsFactors = FALSE)

  config <- list(columnas_sensibles = c("tramo"))
  profile <- profile_dataset_for_ai(df, dataset_name = "override", config = config)

  expect_equal(profile$variables$tramo$inferred_type, "categorical")
  expect_equal(profile$variables$tramo$role_guess, "sensitive")
  expect_equal(profile$variables$tramo$classification_source, "declared_by_user")
})

test_that("config advierte por columnas inexistentes sin romper el helper", {
  df <- data.frame(tramo = c("A", "B", "C"), stringsAsFactors = FALSE)

  config <- list(columnas_sensibles = c("no_existe"))
  profile <- profile_dataset_for_ai(df, dataset_name = "columna_inexistente", config = config)

  expect_true(any(grepl("no_existe", profile$warnings, fixed = TRUE)))
  expect_equal(profile$variables$tramo$classification_source, "inferred_automatically")
})

test_that("config resuelve conflictos priorizando la categoria mas restrictiva", {
  df <- data.frame(diagnostico = c("A", "B", "C"), stringsAsFactors = FALSE)

  config <- list(
    columnas_sensibles = c("diagnostico"),
    columnas_identificatorias = c("diagnostico")
  )

  profile <- profile_dataset_for_ai(df, dataset_name = "conflicto", config = config)

  expect_equal(profile$variables$diagnostico$inferred_type, "identifier")
  expect_equal(profile$variables$diagnostico$role_guess, "identifier")
  expect_true(any(grepl("categorias incompatibles", profile$warnings, ignore.case = TRUE)))
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

test_that("categorias sensibles no listan sus valores reales por defecto", {
  df <- data.frame(
    diagnostico = c("VIH", "Cancer", "Diabetes"),
    stringsAsFactors = FALSE
  )

  profile <- profile_dataset_for_ai(df, dataset_name = "categoria_sensible")
  rendered <- render_dataset_profile_for_ai(profile)

  expect_equal(profile$variables$diagnostico$inferred_type, "categorical")
  expect_equal(profile$variables$diagnostico$role_guess, "sensitive")
  expect_false(grepl("VIH|Cancer|Diabetes", rendered))
  expect_match(rendered, "valores no listados por seguridad", ignore.case = TRUE)
})

test_that("correos y otros identificadores complejos no se exponen literalmente", {
  df <- data.frame(
    correo_contacto = c("ana@example.org", "bruno@example.org", "carla@example.org"),
    stringsAsFactors = FALSE
  )

  profile <- profile_dataset_for_ai(df, dataset_name = "ids_complejos")
  rendered <- render_dataset_profile_for_ai(profile)

  expect_equal(profile$variables$correo_contacto$inferred_type, "identifier")
  expect_false(grepl("ana@example|bruno@example|carla@example", rendered))
  expect_match(rendered, "correo electronico|patron aproximado", ignore.case = TRUE)
})

test_that("telefonos se tratan como identificadores y texto de direccion como privado", {
  df <- data.frame(
    telefono_contacto = c("099123456", "098765432", "091111222"),
    direccion = c(
      "Av. Siempre Viva 742",
      "Calle Falsa 1234",
      "Ruta 8 km 17"
    ),
    stringsAsFactors = FALSE
  )

  profile <- profile_dataset_for_ai(df, dataset_name = "contacto")
  rendered <- render_dataset_profile_for_ai(profile)

  expect_equal(profile$variables$telefono_contacto$inferred_type, "identifier")
  expect_equal(profile$variables$direccion$inferred_type, "free_text")
  expect_false(grepl("099123456|098765432|091111222", rendered))
  expect_false(grepl("Siempre Viva|Calle Falsa|Ruta 8", rendered))
})

test_that("modo conservador redacciona categoricas no triviales aunque no sean sensibles", {
  df <- data.frame(
    departamento = c("Montevideo", "Canelones", "Salto"),
    tramo = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )

  profile <- profile_dataset_for_ai(df, dataset_name = "modo_conservador")
  rendered <- render_dataset_profile_for_ai(profile, mode = "conservative")

  expect_match(rendered, "departamento: categorica; niveles observados: 3; valores no listados por modo conservador", ignore.case = TRUE)
  expect_match(rendered, "tramo: categorica; valores observados: A, B, C", ignore.case = TRUE)
})
