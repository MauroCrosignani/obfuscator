library(testthat)

script_path <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
tests_dir <- normalizePath(dirname(script_path), winslash = "/", mustWork = TRUE)
root_dir <- normalizePath(file.path(tests_dir, ".."), winslash = "/", mustWork = TRUE)

source(file.path(root_dir, "obfuscator.R"))

test_dir(file.path(root_dir, "tests", "testthat"))
