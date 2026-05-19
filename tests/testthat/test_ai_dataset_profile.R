library(testthat)

source(file.path("..", "..", "R", "obfuscator_core.R"))

write_test_workbook <- function(path, sheets) {
  expect_true(requireNamespace("writexl", quietly = TRUE))
  writexl::write_xlsx(sheets, path = path)
  path
}

write_test_json <- function(path, content) {
  expect_true(requireNamespace("jsonlite", quietly = TRUE))
  jsonlite::write_json(content, path = path, auto_unbox = TRUE, pretty = TRUE, null = "null")
  path
}

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

test_that("profile_dataset_for_ai sigue funcionando sin archivo_fuente", {
  profile <- profile_dataset_for_ai(iris, dataset_name = "iris")

  expect_true("source_context" %in% names(profile))
  expect_true(is.null(profile$source_context$file))
})

test_that("archivo_fuente inexistente agrega advertencia sin romper el helper", {
  missing_file <- file.path(tempdir(), "no_existe_fuente.xlsx")
  profile <- profile_dataset_for_ai(
    iris,
    dataset_name = "iris",
    archivo_fuente = missing_file
  )

  expect_equal(profile$source_context$file$status, "missing")
  expect_true(any(grepl("archivo_fuente", profile$warnings, ignore.case = TRUE)))
})

test_that("archivo_fuente con firma GCA detecta contexto de origen", {
  workbook_path <- file.path(tempdir(), "gca_signature.xlsx")
  meta <- data.frame(
    X1 = c(
      "Planilla generada por el GCA: Martes, 19 de Diciembre de 2023",
      NA,
      "TituloL",
      "Plan de Codigo de la Cuenta",
      NA,
      "Descripcion:",
      "Es la tabla entera cta_plan_codigo de produccion",
      NA,
      "Parametros:"
    ),
    stringsAsFactors = FALSE
  )
  datos <- data.frame(CODIGO_CAJA = c("A", "B"), stringsAsFactors = FALSE)
  write_test_workbook(
    workbook_path,
    list("Informacion de la consulta" = meta, "Datos_Consulta1" = datos)
  )

  profile <- profile_dataset_for_ai(
    datos,
    dataset_name = "gca_dataset",
    archivo_fuente = workbook_path
  )

  expect_equal(profile$source_context$type, "gca")
  expect_equal(profile$source_context$source, "detected_from_file")
  expect_equal(profile$source_context$confidence, "medium")
  expect_match(profile$source_context$source_id, "^gca:unresolved:")
  expect_match(
    render_dataset_profile_for_ai(profile),
    "Fuente inferida desde archivo: gca\\.",
    ignore.case = TRUE
  )
})

test_that("archivo_fuente con firma GCA2 detecta contexto de origen", {
  workbook_path <- file.path(tempdir(), "consulta_18631_123456.xlsx")
  caratula <- data.frame(
    col1 = c(NA, "Planilla generada por GCA2", "Nombre", "Id de Consulta", "Descripcion", "Id. Ejecucion"),
    col2 = c(NA, NA, "Consulta demo", "18631", "GCA2_18631_demo", "123456"),
    stringsAsFactors = FALSE
  )
  salida <- data.frame(persona_id = c("P001", "P002"), stringsAsFactors = FALSE)
  write_test_workbook(
    workbook_path,
    list("Caratula" = caratula, "salida_gca" = salida)
  )

  profile <- profile_dataset_for_ai(
    salida,
    dataset_name = "gca2_dataset",
    archivo_fuente = workbook_path
  )

  expect_equal(profile$source_context$type, "gca2")
  expect_equal(profile$source_context$source, "detected_from_file")
  expect_equal(profile$source_context$confidence, "high")
  expect_equal(profile$source_context$source_id, "gca2:18631")
  expect_match(
    render_dataset_profile_for_ai(profile),
    "Fuente inferida desde archivo: gca2\\.",
    ignore.case = TRUE
  )
})

test_that("archivo_fuente ambiguo o incompleto no fuerza contexto fuerte", {
  workbook_path <- file.path(tempdir(), "ambiguous_source.xlsx")
  sheet <- data.frame(a = c("sin", "firma", "clara"), stringsAsFactors = FALSE)
  write_test_workbook(workbook_path, list("Hoja1" = sheet))

  profile <- profile_dataset_for_ai(
    sheet,
    dataset_name = "ambiguous_dataset",
    archivo_fuente = workbook_path
  )

  expect_null(profile$source_context$type)
  expect_equal(profile$source_context$source, "none")
  expect_equal(profile$source_context$file$status, "unresolved")
  expect_true(any(grepl("No se pudo resolver", profile$warnings, ignore.case = TRUE)))
})

test_that("metadata_dir NULL no rompe el helper ni fuerza metadata", {
  profile <- profile_dataset_for_ai(
    iris,
    dataset_name = "iris",
    tipo_fuente = "gca2"
  )

  expect_true("source_metadata" %in% names(profile))
  expect_equal(profile$source_metadata$status, "none")
})

test_that("metadata_dir inexistente agrega advertencia y degrada con seguridad", {
  missing_dir <- file.path(tempdir(), "metadata_dir_inexistente")
  profile <- profile_dataset_for_ai(
    iris,
    dataset_name = "iris",
    tipo_fuente = "gca2",
    metadata_dir = missing_dir
  )

  expect_equal(profile$source_metadata$status, "missing_dir")
  expect_true(any(grepl("metadata_dir", profile$warnings, ignore.case = TRUE)))
})

test_that("metadata valida matchea por source_id exacto", {
  workbook_path <- file.path(tempdir(), "consulta_18631_123456.xlsx")
  caratula <- data.frame(
    col1 = c(NA, "Planilla generada por GCA2", "Nombre", "Id de Consulta", "Descripcion", "Id. Ejecucion"),
    col2 = c(NA, NA, "Consulta demo", "18631", "GCA2_18631_demo", "123456"),
    stringsAsFactors = FALSE
  )
  salida <- data.frame(persona_id = c("P001", "P002"), stringsAsFactors = FALSE)
  write_test_workbook(
    workbook_path,
    list("Caratula" = caratula, "salida_gca" = salida)
  )

  metadata_dir <- file.path(tempdir(), "metadata_exacta")
  dir.create(metadata_dir, recursive = TRUE, showWarnings = FALSE)
  write_test_json(
    file.path(metadata_dir, "gca2_18631.json"),
    list(
      version = 1,
      source_type = "gca2",
      source_id = "gca2:18631",
      display_name = "Consulta demo",
      aliases = list("Consulta demo"),
      related_sources = list(),
      source_details = list(query_id = "18631"),
      columnas = list(persona_id = list(rol = "identificatoria"))
    )
  )

  profile <- profile_dataset_for_ai(
    salida,
    dataset_name = "gca2_dataset",
    archivo_fuente = workbook_path,
    metadata_dir = metadata_dir
  )

  expect_equal(profile$source_metadata$status, "matched")
  expect_equal(profile$source_metadata$matched_by, "source_id")
  expect_equal(profile$source_metadata$metadata$display_name, "Consulta demo")
})

test_that("metadata puede matchear por alias cuando no hay source_id canonico", {
  workbook_path <- file.path(tempdir(), "gca_alias.xlsx")
  meta <- data.frame(
    X1 = c(
      "Planilla generada por el GCA: Martes, 19 de Diciembre de 2023",
      NA,
      "TituloL",
      "Plan de Codigo de la Cuenta",
      NA,
      "Descripcion:",
      "Es la tabla entera cta_plan_codigo de produccion",
      NA,
      "Parametros:"
    ),
    stringsAsFactors = FALSE
  )
  datos <- data.frame(CODIGO_CAJA = c("A", "B"), stringsAsFactors = FALSE)
  write_test_workbook(
    workbook_path,
    list("Informacion de la consulta" = meta, "Datos_Consulta1" = datos)
  )

  metadata_dir <- file.path(tempdir(), "metadata_alias")
  dir.create(metadata_dir, recursive = TRUE, showWarnings = FALSE)
  write_test_json(
    file.path(metadata_dir, "gca_alias.json"),
    list(
      version = 1,
      source_type = "gca",
      source_id = "gca:5553",
      display_name = "Plan de Codigo de la Cuenta",
      aliases = list("Plan de Codigo de la Cuenta"),
      related_sources = list(),
      source_details = list(query_id = "5553"),
      columnas = list(CODIGO_CAJA = list(rol = "identificatoria"))
    )
  )

  profile <- profile_dataset_for_ai(
    datos,
    dataset_name = "gca_dataset",
    archivo_fuente = workbook_path,
    metadata_dir = metadata_dir
  )

  expect_equal(profile$source_metadata$status, "matched")
  expect_equal(profile$source_metadata$matched_by, "alias")
  expect_equal(profile$source_metadata$metadata$source_id, "gca:5553")
})

test_that("metadata ambigua por alias no se aplica automaticamente", {
  workbook_path <- file.path(tempdir(), "gca_alias_ambigua.xlsx")
  meta <- data.frame(
    X1 = c(
      "Planilla generada por el GCA: Martes, 19 de Diciembre de 2023",
      NA,
      "TituloL",
      "Plan de Codigo de la Cuenta",
      NA,
      "Descripcion:",
      "Es la tabla entera cta_plan_codigo de produccion",
      NA,
      "Parametros:"
    ),
    stringsAsFactors = FALSE
  )
  datos <- data.frame(CODIGO_CAJA = c("A", "B"), stringsAsFactors = FALSE)
  write_test_workbook(
    workbook_path,
    list("Informacion de la consulta" = meta, "Datos_Consulta1" = datos)
  )

  metadata_dir <- file.path(tempdir(), "metadata_ambigua")
  dir.create(metadata_dir, recursive = TRUE, showWarnings = FALSE)
  shared_alias <- list("Plan de Codigo de la Cuenta")
  write_test_json(
    file.path(metadata_dir, "gca_alias_1.json"),
    list(
      version = 1,
      source_type = "gca",
      source_id = "gca:1111",
      display_name = "Consulta A",
      aliases = shared_alias,
      related_sources = list(),
      source_details = list(query_id = "1111"),
      columnas = list(CODIGO_CAJA = list(rol = "identificatoria"))
    )
  )
  write_test_json(
    file.path(metadata_dir, "gca_alias_2.json"),
    list(
      version = 1,
      source_type = "gca",
      source_id = "gca:2222",
      display_name = "Consulta B",
      aliases = shared_alias,
      related_sources = list(),
      source_details = list(query_id = "2222"),
      columnas = list(CODIGO_CAJA = list(rol = "identificatoria"))
    )
  )

  profile <- profile_dataset_for_ai(
    datos,
    dataset_name = "gca_dataset",
    archivo_fuente = workbook_path,
    metadata_dir = metadata_dir
  )

  expect_equal(profile$source_metadata$status, "ambiguous")
  expect_true(is.null(profile$source_metadata$metadata))
  expect_true(any(grepl("ambigua", profile$warnings, ignore.case = TRUE)))
})

test_that("metadata JSON invalida advierte y degrada sin romper", {
  metadata_dir <- file.path(tempdir(), "metadata_invalida")
  dir.create(metadata_dir, recursive = TRUE, showWarnings = FALSE)
  writeLines("{\"version\": 1, \"source_type\": \"gca2\"}", con = file.path(metadata_dir, "invalida.json"))

  profile <- profile_dataset_for_ai(
    iris,
    dataset_name = "iris",
    tipo_fuente = "gca2",
    metadata_dir = metadata_dir
  )

  expect_true(profile$source_metadata$status %in% c("none", "no_match"))
  expect_true(any(grepl("metadata", profile$warnings, ignore.case = TRUE)))
})

test_that("metadata en mayusculas puede matchear contra nombres normalizados en minusculas", {
  workbook_path <- file.path(tempdir(), "consulta_22001_123456.xlsx")
  caratula <- data.frame(
    col1 = c(NA, "Planilla generada por GCA2", "Nombre", "Id de Consulta"),
    col2 = c(NA, NA, "Consulta demo columnas", "22001"),
    stringsAsFactors = FALSE
  )
  salida <- data.frame(persona_id = c("P001", "P002"), stringsAsFactors = FALSE)
  write_test_workbook(
    workbook_path,
    list("Caratula" = caratula, "salida_gca" = salida)
  )

  metadata_dir <- file.path(tempdir(), "metadata_columnas_mayusculas")
  dir.create(metadata_dir, recursive = TRUE, showWarnings = FALSE)
  write_test_json(
    file.path(metadata_dir, "gca2_22001.json"),
    list(
      version = 1,
      source_type = "gca2",
      source_id = "gca2:22001",
      display_name = "Consulta demo columnas",
      aliases = list(),
      related_sources = list(),
      source_details = list(query_id = "22001"),
      columnas = list(PERSONA_ID = list(rol = "identificatoria"))
    )
  )

  profile <- profile_dataset_for_ai(
    salida,
    dataset_name = "gca2_dataset",
    archivo_fuente = workbook_path,
    metadata_dir = metadata_dir
  )

  expect_equal(profile$source_metadata$column_resolution$matched$PERSONA_ID$actual_name, "persona_id")
  expect_equal(profile$source_metadata$column_resolution$matched$PERSONA_ID$match_type, "normalized")
})

test_that("metadata con puntuacion puede matchear por normalizacion tipo snake_case", {
  workbook_path <- file.path(tempdir(), "consulta_22002_123456.xlsx")
  caratula <- data.frame(
    col1 = c(NA, "Planilla generada por GCA2", "Nombre", "Id de Consulta"),
    col2 = c(NA, NA, "Consulta demo codigos", "22002"),
    stringsAsFactors = FALSE
  )
  salida <- data.frame(codigo_pago = c("A", "B"), stringsAsFactors = FALSE)
  write_test_workbook(
    workbook_path,
    list("Caratula" = caratula, "salida_gca" = salida)
  )

  metadata_dir <- file.path(tempdir(), "metadata_columnas_puntuacion")
  dir.create(metadata_dir, recursive = TRUE, showWarnings = FALSE)
  write_test_json(
    file.path(metadata_dir, "gca2_22002.json"),
    list(
      version = 1,
      source_type = "gca2",
      source_id = "gca2:22002",
      display_name = "Consulta demo codigos",
      aliases = list(),
      related_sources = list(),
      source_details = list(query_id = "22002"),
      columnas = structure(
        list(list(rol = "analitica")),
        names = "CODIGO.PAGO"
      )
    )
  )

  profile <- profile_dataset_for_ai(
    salida,
    dataset_name = "gca2_dataset",
    archivo_fuente = workbook_path,
    metadata_dir = metadata_dir
  )

  expect_equal(profile$source_metadata$column_resolution$matched[["CODIGO.PAGO"]]$actual_name, "codigo_pago")
  expect_equal(profile$source_metadata$column_resolution$matched[["CODIGO.PAGO"]]$match_type, "normalized")
})

test_that("columnas sin match ni por normalizacion quedan sin resolver", {
  workbook_path <- file.path(tempdir(), "consulta_22003_123456.xlsx")
  caratula <- data.frame(
    col1 = c(NA, "Planilla generada por GCA2", "Nombre", "Id de Consulta"),
    col2 = c(NA, NA, "Consulta demo faltante", "22003"),
    stringsAsFactors = FALSE
  )
  salida <- data.frame(persona_id = c("P001", "P002"), stringsAsFactors = FALSE)
  write_test_workbook(
    workbook_path,
    list("Caratula" = caratula, "salida_gca" = salida)
  )

  metadata_dir <- file.path(tempdir(), "metadata_columna_faltante")
  dir.create(metadata_dir, recursive = TRUE, showWarnings = FALSE)
  write_test_json(
    file.path(metadata_dir, "gca2_22003.json"),
    list(
      version = 1,
      source_type = "gca2",
      source_id = "gca2:22003",
      display_name = "Consulta demo faltante",
      aliases = list(),
      related_sources = list(),
      source_details = list(query_id = "22003"),
      columnas = list(FECHA_ULT_ACT = list(rol = "temporal"))
    )
  )

  profile <- profile_dataset_for_ai(
    salida,
    dataset_name = "gca2_dataset",
    archivo_fuente = workbook_path,
    metadata_dir = metadata_dir
  )

  expect_true("FECHA_ULT_ACT" %in% profile$source_metadata$column_resolution$unresolved)
  expect_true(any(grepl("FECHA_ULT_ACT", profile$warnings, fixed = TRUE)))
})

test_that("renombre fuerte no se adivina como match automatico", {
  workbook_path <- file.path(tempdir(), "consulta_22004_123456.xlsx")
  caratula <- data.frame(
    col1 = c(NA, "Planilla generada por GCA2", "Nombre", "Id de Consulta"),
    col2 = c(NA, NA, "Consulta demo renombre", "22004"),
    stringsAsFactors = FALSE
  )
  salida <- data.frame(fecha_ultima_actualizacion = c("2024-01-01", "2024-01-02"), stringsAsFactors = FALSE)
  write_test_workbook(
    workbook_path,
    list("Caratula" = caratula, "salida_gca" = salida)
  )

  metadata_dir <- file.path(tempdir(), "metadata_renombre_fuerte")
  dir.create(metadata_dir, recursive = TRUE, showWarnings = FALSE)
  write_test_json(
    file.path(metadata_dir, "gca2_22004.json"),
    list(
      version = 1,
      source_type = "gca2",
      source_id = "gca2:22004",
      display_name = "Consulta demo renombre",
      aliases = list(),
      related_sources = list(),
      source_details = list(query_id = "22004"),
      columnas = list(FECHA_ULT_ACT = list(rol = "temporal"))
    )
  )

  profile <- profile_dataset_for_ai(
    salida,
    dataset_name = "gca2_dataset",
    archivo_fuente = workbook_path,
    metadata_dir = metadata_dir
  )

  expect_false("FECHA_ULT_ACT" %in% names(profile$source_metadata$column_resolution$matched))
  expect_true("FECHA_ULT_ACT" %in% profile$source_metadata$column_resolution$unresolved)
})

test_that("genera alerta cuando se esperaba datetime y la columna sigue como character", {
  workbook_path <- file.path(tempdir(), "consulta_22005_123456.xlsx")
  caratula <- data.frame(
    col1 = c(NA, "Planilla generada por GCA2", "Nombre", "Id de Consulta"),
    col2 = c(NA, NA, "Consulta demo fecha", "22005"),
    stringsAsFactors = FALSE
  )
  salida <- data.frame(
    fecha_evento = c("2024-01-01 10:00:00.123456", "2024-01-02 11:00:00.654321"),
    stringsAsFactors = FALSE
  )
  write_test_workbook(
    workbook_path,
    list("Caratula" = caratula, "salida_gca" = salida)
  )

  metadata_dir <- file.path(tempdir(), "metadata_alerta_datetime")
  dir.create(metadata_dir, recursive = TRUE, showWarnings = FALSE)
  write_test_json(
    file.path(metadata_dir, "gca2_22005.json"),
    list(
      version = 1,
      source_type = "gca2",
      source_id = "gca2:22005",
      display_name = "Consulta demo fecha",
      aliases = list(),
      related_sources = list(),
      source_details = list(query_id = "22005"),
      columnas = list(fecha_evento = list(rol = "temporal", tipo_esperado = "datetime"))
    )
  )

  profile <- profile_dataset_for_ai(
    salida,
    dataset_name = "gca2_dataset",
    archivo_fuente = workbook_path,
    metadata_dir = metadata_dir
  )

  expect_true(length(profile$source_alerts) > 0)
  expect_true(any(grepl("fecha_evento", profile$source_alerts, fixed = TRUE)))
  expect_true(any(grepl("datetime", profile$source_alerts, ignore.case = TRUE)))
  expect_true(any(grepl("character", profile$source_alerts, ignore.case = TRUE)))
})

test_that("genera alerta cuando un identificador esperado sigue como numerico", {
  workbook_path <- file.path(tempdir(), "consulta_22006_123456.xlsx")
  caratula <- data.frame(
    col1 = c(NA, "Planilla generada por GCA2", "Nombre", "Id de Consulta"),
    col2 = c(NA, NA, "Consulta demo identificador", "22006"),
    stringsAsFactors = FALSE
  )
  salida <- data.frame(numero_empresa = c(1234567890123, 2234567890123), stringsAsFactors = FALSE)
  write_test_workbook(
    workbook_path,
    list("Caratula" = caratula, "salida_gca" = salida)
  )

  metadata_dir <- file.path(tempdir(), "metadata_alerta_id")
  dir.create(metadata_dir, recursive = TRUE, showWarnings = FALSE)
  write_test_json(
    file.path(metadata_dir, "gca2_22006.json"),
    list(
      version = 1,
      source_type = "gca2",
      source_id = "gca2:22006",
      display_name = "Consulta demo identificador",
      aliases = list(),
      related_sources = list(),
      source_details = list(query_id = "22006"),
      columnas = list(numero_empresa = list(rol = "identificatoria", tipo_esperado = "character"))
    )
  )

  profile <- profile_dataset_for_ai(
    salida,
    dataset_name = "gca2_dataset",
    archivo_fuente = workbook_path,
    metadata_dir = metadata_dir
  )

  expect_true(any(grepl("numero_empresa", profile$source_alerts, fixed = TRUE)))
  expect_true(any(grepl("identificador", profile$source_alerts, ignore.case = TRUE)))
  expect_true(any(grepl("numeric", profile$source_alerts, ignore.case = TRUE)))
})

test_that("registra faltantes altos pero esperables como senal informativa", {
  workbook_path <- file.path(tempdir(), "consulta_22007_123456.xlsx")
  caratula <- data.frame(
    col1 = c(NA, "Planilla generada por GCA2", "Nombre", "Id de Consulta"),
    col2 = c(NA, NA, "Consulta demo faltantes esperables", "22007"),
    stringsAsFactors = FALSE
  )
  salida <- data.frame(
    fecha_hasta = c(NA, NA, "2024-03-01", NA, NA),
    stringsAsFactors = FALSE
  )
  write_test_workbook(
    workbook_path,
    list("Caratula" = caratula, "salida_gca" = salida)
  )

  metadata_dir <- file.path(tempdir(), "metadata_alerta_faltantes_esperables")
  dir.create(metadata_dir, recursive = TRUE, showWarnings = FALSE)
  write_test_json(
    file.path(metadata_dir, "gca2_22007.json"),
    list(
      version = 1,
      source_type = "gca2",
      source_id = "gca2:22007",
      display_name = "Consulta demo faltantes esperables",
      aliases = list(),
      related_sources = list(),
      source_details = list(query_id = "22007"),
      columnas = list(fecha_hasta = list(rol = "temporal", faltantes = "esperables"))
    )
  )

  profile <- profile_dataset_for_ai(
    salida,
    dataset_name = "gca2_dataset",
    archivo_fuente = workbook_path,
    metadata_dir = metadata_dir
  )

  expect_true(any(grepl("fecha_hasta", profile$source_alerts, fixed = TRUE)))
  expect_true(any(grepl("esperables", profile$source_alerts, ignore.case = TRUE)))
})

test_that("genera alerta cuando hay faltantes altos inesperados", {
  workbook_path <- file.path(tempdir(), "consulta_22008_123456.xlsx")
  caratula <- data.frame(
    col1 = c(NA, "Planilla generada por GCA2", "Nombre", "Id de Consulta"),
    col2 = c(NA, NA, "Consulta demo faltantes inesperados", "22008"),
    stringsAsFactors = FALSE
  )
  salida <- data.frame(
    ingreso = c(100, NA, NA, NA, 200),
    stringsAsFactors = FALSE
  )
  write_test_workbook(
    workbook_path,
    list("Caratula" = caratula, "salida_gca" = salida)
  )

  metadata_dir <- file.path(tempdir(), "metadata_alerta_faltantes_inesperados")
  dir.create(metadata_dir, recursive = TRUE, showWarnings = FALSE)
  write_test_json(
    file.path(metadata_dir, "gca2_22008.json"),
    list(
      version = 1,
      source_type = "gca2",
      source_id = "gca2:22008",
      display_name = "Consulta demo faltantes inesperados",
      aliases = list(),
      related_sources = list(),
      source_details = list(query_id = "22008"),
      columnas = list(ingreso = list(rol = "analitica"))
    )
  )

  profile <- profile_dataset_for_ai(
    salida,
    dataset_name = "gca2_dataset",
    archivo_fuente = workbook_path,
    metadata_dir = metadata_dir
  )

  expect_true(any(grepl("ingreso", profile$source_alerts, fixed = TRUE)))
  expect_true(any(grepl("faltantes", profile$source_alerts, ignore.case = TRUE)))
  expect_true(any(grepl("revis", profile$source_alerts, ignore.case = TRUE)))
})

test_that("el renderer no muestra seccion de alertas si no hay source_alerts", {
  profile <- profile_dataset_for_ai(iris, dataset_name = "iris")
  rendered <- render_dataset_profile_for_ai(profile)

  expect_false(grepl("Alertas de consistencia respecto del origen", rendered, fixed = TRUE))
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

test_that("resumen_de devuelve texto por defecto", {
  rendered <- resumen_de(iris)

  expect_type(rendered, "character")
  expect_length(rendered, 1)
  expect_match(rendered, "Dataset: iris")
  expect_match(rendered, "Dimensiones: 150 filas, 5 columnas")
})

test_that("resumen_de respeta nombre_dataset cuando se provee", {
  rendered <- resumen_de(iris, nombre_dataset = "iris_demo")

  expect_match(rendered, "Dataset: iris_demo")
})

test_that("resumen_de puede devolver la estructura cruda del perfil", {
  resumen_estructurado <- resumen_de(iris, salida = "estructura")
  perfil_core <- profile_dataset_for_ai(iris, dataset_name = "iris")

  expect_type(resumen_estructurado, "list")
  expect_equal(resumen_estructurado$dataset_name, perfil_core$dataset_name)
  expect_equal(resumen_estructurado$dimensions, perfil_core$dimensions)
  expect_equal(names(resumen_estructurado$variables), names(perfil_core$variables))
})

test_that("resumen_de traduce modo visible al renderer actual", {
  rendered_normal <- resumen_de(iris, modo = "normal")
  rendered_conservador <- resumen_de(
    data.frame(
      departamento = c("Montevideo", "Canelones", "Salto"),
      stringsAsFactors = FALSE
    ),
    modo = "conservador"
  )

  expect_match(rendered_normal, "Dataset: iris")
  expect_match(rendered_conservador, "valores no listados por modo conservador", ignore.case = TRUE)
})

test_that("resumen_de preserva forwarding de config, tipo_fuente y metadata_dir", {
  metadata_dir <- file.path(tempdir(), "metadata_resumen_de_forwarding")
  dir.create(metadata_dir, recursive = TRUE, showWarnings = FALSE)
  write_test_json(
    file.path(metadata_dir, "gca2_18631.json"),
    list(
      version = 1,
      source_type = "gca2",
      source_id = "gca2:18631",
      display_name = "Consulta demo",
      aliases = list("Consulta demo"),
      related_sources = list(),
      source_details = list(query_id = "18631"),
      columnas = list(persona_id = list(rol = "identificatoria"))
    )
  )

  workbook_path <- file.path(tempdir(), "consulta_18631_123456.xlsx")
  caratula <- data.frame(
    col1 = c(NA, "Planilla generada por GCA2", "Nombre", "Id de Consulta", "Descripcion", "Id. Ejecucion"),
    col2 = c(NA, NA, "Consulta demo", "18631", "GCA2_18631_demo", "123456"),
    stringsAsFactors = FALSE
  )
  salida <- data.frame(persona_id = c("P001", "P002"), stringsAsFactors = FALSE)
  write_test_workbook(
    workbook_path,
    list("Caratula" = caratula, "salida_gca" = salida)
  )

  config <- list(columnas_texto_libre = c("observacion"))
  df <- data.frame(
    persona_id = c("P001", "P002"),
    observacion = c("uno", "dos"),
    stringsAsFactors = FALSE
  )

  resumen_estructurado <- resumen_de(
    df,
    nombre_dataset = "demo_resumen",
    config = config,
    tipo_fuente = "gca2",
    archivo_fuente = workbook_path,
    metadata_dir = metadata_dir,
    salida = "estructura"
  )

  expect_equal(resumen_estructurado$dataset_name, "demo_resumen")
  expect_equal(resumen_estructurado$source_context$type, "gca2")
  expect_equal(resumen_estructurado$source_metadata$status, "matched")
  expect_equal(resumen_estructurado$variables$observacion$inferred_type, "free_text")
})

test_that("resumen_de falla en espanol cuando data no es tabular", {
  expect_error(
    resumen_de(1:3),
    "`data` debe ser un data\\.frame o tibble\\.",
    fixed = FALSE
  )
})

test_that("resumen_de falla en espanol para modo invalido", {
  expect_error(
    resumen_de(iris, modo = "otra_cosa"),
    "Valores aceptados: normal, conservador",
    fixed = TRUE
  )
})

test_that("resumen_de falla en espanol para salida invalida", {
  expect_error(
    resumen_de(iris, salida = "otra_cosa"),
    "Valores aceptados: texto, estructura",
    fixed = TRUE
  )
})

test_that("resumen_de debe quedar exportada en el paquete", {
  namespace_lines <- readLines(file.path("..", "..", "NAMESPACE"), warn = FALSE)
  expect_true(any(grepl("^export\\(resumen_de\\)$", namespace_lines)))
})
