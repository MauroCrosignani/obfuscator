library(testthat)
library(tibble)
source("R/obfuscator_core.R")

context("k-anonymity Hierarchies (Robust Tests)")

# --- Success Cases (15) ---

test_that("[Success 1] Simple grouping of 2 categorical values", {
  df <- tibble(col1 = c("A", "A", "B", "B"))
  pm <- list(type="k_anonymity", k=4, quasi_identifiers="col1", 
             hierarchies=list(col1=list(mapping=list(G1=c("A", "B")))))
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(unique(res$data$col1), "G1")
})

test_that("[Success 2] Multiple groups in one level", {
  df <- tibble(col1 = c("A", "B", "C", "D"))
  pm <- list(type="k_anonymity", k=2, quasi_identifiers="col1", 
             hierarchies=list(col1=list(mapping=list(G1=c("A", "B"), G2=c("C", "D")))))
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(as.character(res$data$col1), c("G1", "G1", "G2", "G2"))
})

test_that("[Success 3] Numeric values with custom hierarchy", {
  df <- tibble(val = c(1, 2, 10, 11))
  pm <- list(type="k_anonymity", k=2, quasi_identifiers="val", 
             hierarchies=list(val=list(mapping=list(Low=c("1", "2"), High=c("10", "11")))))
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(as.character(res$data$val), c("Low", "Low", "High", "High"))
})

test_that("[Success 4] k-anonymity satisfies k exactly (groups of 2, k=2)", {
  df <- tibble(x = c("A", "A", "B", "B"))
  pm <- list(type="k_anonymity", k=2, quasi_identifiers="x")
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(res$report$after$satisfied, TRUE)
  expect_equal(as.character(res$report$generalization_steps$x), "identity")
})

test_that("[Success 5] Mixed default and custom plans", {
  df <- tibble(cat = c("A", "B"), num = c(10, 10))
  pm <- list(type="k_anonymity", k=2, quasi_identifiers=c("cat", "num"),
             hierarchies=list(cat=list(mapping=list(All=c("A", "B")))))
  res <- apply_k_anonymity_model(df, pm)
  expect_true(res$report$after$satisfied)
  expect_equal(res$data$cat[1], "All")
})

test_that("[Success 6] Date hierarchy application", {
  df <- tibble(d = as.Date(c("2023-01-01", "2023-01-02", "2023-02-01", "2023-02-02")))
  pm <- list(type="k_anonymity", k=2, quasi_identifiers="d",
             hierarchies=list(d="month"))
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(res$data$d[1], "2023-01")
  expect_equal(res$data$d[3], "2023-02")
})

test_that("[Success 7] Sorting preservation after obfuscation", {
  df <- tibble(id = 1:4, val = c("A", "A", "B", "B"))
  pm <- list(type="k_anonymity", k=2, quasi_identifiers="val")
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(res$data$id, 1:4)
})

test_that("[Success 8] Row suppression works when k is impossible", {
  df <- tibble(v = c("A", "A", "B"))
  pm <- list(type="k_anonymity", k=5, quasi_identifiers="v", suppression="rows")
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(nrow(res$data), 0)
})

test_that("[Success 9] Group suppression (REMANENTE) works", {
  df <- tibble(v = c("A", "A", "B"))
  pm <- list(type="k_anonymity", k=5, quasi_identifiers="v", suppression="group")
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(unique(res$data$v), "REMANENTE")
})

test_that("[Success 10] Greedy behavior: moves to global if hierarchy not enough", {
  df <- tibble(v = c("a", "A", "B"))
  pm <- list(type="k_anonymity", k=2, quasi_identifiers="v",
             hierarchies=list(v=list(mapping=list(Upper=c("A", "B")))))
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(unique(res$data$v), "OTROS")
})

test_that("[Success 11] Custom hierarchy with multiple steps (manual list)", {
  df <- tibble(v = c("A", "B", "C"))
  plan <- list("identity", list(G1=c("A", "B")), list(ALL=c("G1", "C")), "global")
  pm <- list(type="k_anonymity", k=3, quasi_identifiers="v", hierarchies=list(v=plan))
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(unique(res$data$v), "ALL")
})

test_that("[Success 12] Factors are handled correctly", {
  df <- tibble(v = factor(c("A", "A", "B", "B")))
  pm <- list(type="k_anonymity", k=2, quasi_identifiers="v")
  res <- apply_k_anonymity_model(df, pm)
  expect_true(res$report$after$satisfied)
})

test_that("[Success 13] Empty hierarchy list results in default behavior", {
  df <- tibble(v = c("A", "A", "B", "B"))
  pm <- list(type="k_anonymity", k=2, quasi_identifiers="v", hierarchies=list())
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(as.character(res$report$generalization_steps$v), "identity")
})

test_that("[Success 14] Audit log contains correct class IDs", {
  df <- tibble(a = c(1,1,2,2))
  pm <- list(type="k_anonymity", k=2, quasi_identifiers="a")
  res <- apply_k_anonymity_model(df, pm)
  expect_true(".obfuscator_class_id" %in% names(res$data))
})

test_that("[Success 15] Large k handles correctly (beyond rows)", {
  df <- tibble(a = 1:5)
  pm <- list(type="k_anonymity", k=10, quasi_identifiers="a")
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(nrow(res$data), 0)
})

# --- Edge Cases (15) ---

test_that("[Edge 1] Empty dataset", {
  df <- tibble(a = character(0))
  pm <- list(type="k_anonymity", k=2, quasi_identifiers="a")
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(nrow(res$data), 0)
})

test_that("[Edge 2] All NAs in quasi-identifiers", {
  df <- tibble(a = c(NA_character_, NA_character_))
  pm <- list(type="k_anonymity", k=2, quasi_identifiers="a")
  res <- apply_k_anonymity_model(df, pm)
  expect_true(res$report$after$satisfied)
})

test_that("[Edge 3] k=1 (Should do nothing)", {
  df <- tibble(a = 1:5)
  pm <- list(type="k_anonymity", k=1, quasi_identifiers="a")
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(as.character(res$report$generalization_steps$a), "identity")
})

test_that("[Edge 4] Hierarchy with values NOT in data", {
  df <- tibble(v = c("A", "A", "B", "B"))
  pm <- list(type="k_anonymity", k=2, quasi_identifiers="v",
             hierarchies=list(v=list(mapping=list(G=c("Z")))))
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(unique(res$data$v), c("A", "B"))
})

test_that("[Edge 5] Hierarchy where one group is empty in map", {
  df <- tibble(v = c("A", "A", "B"))
  pm <- list(type="k_anonymity", k=3, quasi_identifiers="v", 
             hierarchies=list(v=list(mapping=list(Empty=character(0), Real=c("A", "B")))))
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(unique(res$data$v), "Real")
})

test_that("[Edge 6] Column name with spaces in hierarchy", {
  df <- tibble(`Col Spaces` = c("A", "A", "B", "B"))
  pm <- list(type="k_anonymity", k=4, quasi_identifiers="Col Spaces",
             hierarchies=list(`Col Spaces`=list(mapping=list(G=c("A", "B")))))
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(unique(res$data$`Col Spaces`), "G")
})

test_that("[Edge 7] Non-existent quasi-identifier in config", {
  df <- tibble(a = 1:5)
  pm <- list(type="k_anonymity", k=2, quasi_identifiers="MISSING")
  expect_error(apply_k_anonymity_model(df, pm))
})

test_that("[Edge 8] Duplicate values in hierarchy mapping", {
  df <- tibble(v = c("A", "B"))
  pm <- list(type="k_anonymity", k=2, quasi_identifiers="v",
             hierarchies=list(v=list(mapping=list(G1=c("A"), G2=c("A", "B")))))
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(unique(res$data$v), "G2")
})

test_that("[Edge 9] Hierarchy mapping to an already existing value in data", {
  df <- tibble(v = c("A", "B"))
  pm <- list(type="k_anonymity", k=2, quasi_identifiers="v",
             hierarchies=list(v=list(mapping=list(B=c("A")))))
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(unique(res$data$v), "B")
})

test_that("[Edge 10] Hierarchy on numeric column but using character strings", {
  df <- tibble(v = c(1, 1, 2, 2))
  pm <- list(type="k_anonymity", k=4, quasi_identifiers="v",
             hierarchies=list(v=list(mapping=list(Pair=c("1", "2")))))
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(unique(res$data$v), "Pair")
})

test_that("[Edge 11] k-anonymity with suppression 'none' (force fail)", {
  df <- tibble(v = 1:3)
  pm <- list(type="k_anonymity", k=10, quasi_identifiers="v", suppression="none")
  res <- apply_k_anonymity_model(df, pm)
  expect_false(res$report$after$satisfied)
})

test_that("[Edge 12] Single row dataset", {
  df <- tibble(a = "X")
  pm <- list(type="k_anonymity", k=2, quasi_identifiers="a")
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(nrow(res$data), 0)
})

test_that("[Edge 13] Character column with numbers as strings", {
  df <- tibble(v = c("10", "10", "20", "20"))
  pm <- list(type="k_anonymity", k=2, quasi_identifiers="v")
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(res$data$v[1], "10")
})

test_that("[Edge 14] Hierarchy with NULL elements", {
  df <- tibble(v = c("A", "A", "B", "B"))
  pm <- list(type="k_anonymity", k=2, quasi_identifiers="v",
             hierarchies=list(v=list(mapping=list(G=NULL))))
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(unique(res$data$v), c("A", "B"))
})

test_that("[Edge 15] ExtremeCase: Mapping to NAs", {
  df <- tibble(v = c("A", "A", "B", "B"))
  pm <- list(type="k_anonymity", k=4, quasi_identifiers="v", 
             hierarchies=list(v=list(mapping=list(`NA`=c("A", "B")))))
  res <- apply_k_anonymity_model(df, pm)
  expect_equal(as.character(res$data$v[1]), "NA")
})
