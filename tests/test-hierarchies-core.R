library(testthat)
source("R/obfuscator_core.R")

context("k-anonymity Hierarchies (Core)")

test_that("generalize_mapping_step works for simple mapping", {
  x <- c("A", "B", "C", "D")
  mapping <- list(
    "G1" = c("A", "B"),
    "G2" = c("C")
  )
  
  result <- generalize_mapping_step(x, mapping)
  
  expect_equal(result[1], "G1")
  expect_equal(result[2], "G1")
  expect_equal(result[3], "G2")
  expect_equal(result[4], "D") # D no estaba mapeado, queda igual
})

test_that("generalize_mapping_step works with UI format", {
  x <- c("setosa", "versicolor", "virginica")
  # Formato que guarda el UI: list(mapping = list(...), name = "...")
  step <- list(
    mapping = list(
      "Grupo1" = c("setosa", "versicolor")
    )
  )
  
  result <- generalize_mapping_step(x, step)
  expect_equal(result[1], "Grupo1")
  expect_equal(result[2], "Grupo1")
  expect_equal(result[3], "virginica")
})

test_that("generalize_quasi_identifier dispatches to mapping", {
  x <- c("X", "Y")
  step <- list(mapping = list("Group" = "X"))
  
  result <- generalize_quasi_identifier(x, step)
  expect_equal(result[1], "Group")
  expect_equal(result[2], "Y")
})
