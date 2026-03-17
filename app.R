frame_ofiles <- vapply(
  sys.frames(),
  function(frame) {
    if (is.null(frame$ofile)) "" else frame$ofile
  },
  character(1)
)
candidate_files <- frame_ofiles[grepl("app\\.R$", frame_ofiles)]
app_dir <- if (length(candidate_files) > 0) {
  dirname(normalizePath(candidate_files[[length(candidate_files)]]))
} else {
  getwd()
}

source(file.path(app_dir, "R", "obfuscator_core.R"), local = FALSE)
source(file.path(app_dir, "R", "shiny_app.R"), local = FALSE)

run_obfuscator_app()
