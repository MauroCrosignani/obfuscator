library(testthat)
source("R/obfuscator_core.R")

context("PersistenceManager")

test_that("generate_schema_hash is deterministic", {
  df1 <- data.frame(A = 1, B = 2)
  df2 <- data.frame(B = 3, A = 4)
  
  expect_equal(generate_schema_hash(df1), generate_schema_hash(df2))
})

test_that("save and load roles (exact match)", {
  tmp_file <- tempfile(fileext = ".json")
  roles <- list(id = "Var1", numeric = "Var2")
  save_roles_to_json(roles, tmp_file)
  
  df <- data.frame(Var1 = 1, Var2 = 2, Var3 = 3)
  loaded <- load_roles_from_json(df, tmp_file)
  
  expect_equal(loaded$exact$id, "Var1")
  expect_equal(loaded$exact$numeric, "Var2")
  expect_equal(length(loaded$suggested), 0)
  
  unlink(tmp_file)
})

test_that("fuzzy match works for renamed columns", {
  tmp_file <- tempfile(fileext = ".json")
  # Grabamos "FECHA_NACIMIENTO" como date
  roles <- list(date = "FECHA_NACIMIENTO")
  save_roles_to_json(roles, tmp_file)
  
  # Cargamos un dataset que tiene "FEC_NACIM"
  df <- data.frame(FEC_NACIM = "2020-01-01", OTRO = 1)
  loaded <- load_roles_from_json(df, tmp_file, threshold = 0.5)
  
  expect_equal(length(loaded$exact$date), 0)
  expect_true("FEC_NACIM" %in% names(loaded$suggested))
  expect_equal(loaded$suggested$FEC_NACIM$role, "date")
  expect_equal(loaded$suggested$FEC_NACIM$original, "FECHA_NACIMIENTO")
  
  unlink(tmp_file)
})

test_that("fuzzy match respects threshold", {
  tmp_file <- tempfile(fileext = ".json")
  roles <- list(id = "COLUMNA_MUY_LARGA_X")
  save_roles_to_json(roles, tmp_file)
  
  # Dataset con algo totalmente distinto
  df <- data.frame(Z = 1)
  loaded <- load_roles_from_json(df, tmp_file, threshold = 0.9)
  
  expect_equal(length(loaded$suggested), 0)
  unlink(tmp_file)
})
