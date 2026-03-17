# Script de compatibilidad para usuarios que siguen trabajando con:
#   source("obfuscator.R")
#
# La implementacion principal del paquete vive en R/obfuscator_core.R.

frame_ofiles <- vapply(
  sys.frames(),
  function(frame) {
    if (is.null(frame$ofile)) "" else frame$ofile
  },
  character(1)
)

candidate_files <- frame_ofiles[grepl("obfuscator\\.R$", frame_ofiles)]
script_dir <- if (length(candidate_files) > 0) {
  dirname(normalizePath(candidate_files[[length(candidate_files)]]))
} else {
  getwd()
}

source(file.path(script_dir, "R", "obfuscator_core.R"), local = FALSE)

if (sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) >= 2) {
    obfuscate_csv(args[[1]], args[[2]])
  } else {
    message("Uso: Rscript obfuscator.R <input.csv> <output.csv>")
  }
}
