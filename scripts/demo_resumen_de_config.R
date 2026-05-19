demo_dataset <- data.frame(
  persona_id = c("P001", "P002", "P003"),
  fecha_hasta = c(NA, "2026-05-01", NA),
  diagnostico = c("A", "B", "C"),
  observacion = c(
    "Seguimiento local con notas internas",
    "Caso derivado con informacion sensible",
    "Revision manual requerida por texto libre"
  ),
  stringsAsFactors = FALSE
)

config_perfil_ia <- list(
  faltantes_esperables = c("fecha_hasta"),
  columnas_sensibles = c("diagnostico"),
  columnas_texto_libre = c("observacion")
)

source("R/obfuscator_core.R")

cat(
  resumen_de(
    demo_dataset,
    nombre_dataset = "demo_dataset",
    config = config_perfil_ia,
    modo = "conservador"
  )
)
cat("\n")
