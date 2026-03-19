# verify_consistency.R
source("R/obfuscator_core.R")

# Helper to remove attributes for clean comparison
clean_df <- function(df) {
  attr(df, "obfuscator_log") <- NULL
  as.data.frame(df)
}

# Sample data
df <- data.frame(
  id = c("A", "B", "A", "C"),
  cat = c("X", "Y", "X", "Z"),
  val = c(10, 20, 30, 40),
  office = c("Off1", "Off2", "Off1", "Off3"),
  stringsAsFactors = FALSE
)

# 1. Test Consistency & Revertibility
config1 <- obfuscator_config(seed = 123, project_key = "secret1", col_roles = list(id = "id", categorical = "cat"))
res1 <- obfuscate_dataset(df, config1)
res1_again <- obfuscate_dataset(df, config1)

message("Test consistency (same data/key): ", identical(clean_df(res1), clean_df(res1_again)))

reverted <- revert_obfuscation(res1)
message("Test reversal: ", identical(df$id, reverted$id) && identical(df$cat, reverted$cat))

# 2. Test Selective Obfuscation (Preserve)
config_pres <- obfuscator_config(seed = 123, project_key = "secret1", col_roles = list(id = "id", preserve = "office"))
res_pres <- obfuscate_dataset(df, config_pres)
message("Test preserve (office unchanged): ", identical(df$office, res_pres$office))

# 3. Test K-Anonymity Grouping
df_k <- df
df_k$cat <- "Same"
config_k <- obfuscator_config(
  seed = 123, 
  project_key = "secret1", 
  col_roles = list(id = "id", categorical = "cat"),
  privacy_model = list(type = "k_anonymity", k = 2, quasi_identifiers = "cat", group_ids = TRUE)
)
res_k <- obfuscate_dataset(df_k, config_k)
message("Test ID grouping (all same ID): ", length(unique(res_k$id)) == 1)
message("IDs assigned: ", paste(unique(res_k$id), collapse = ", "))
