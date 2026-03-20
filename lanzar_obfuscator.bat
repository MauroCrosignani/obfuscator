@echo off
echo --- DIAGNOSTICO DE RUTA ---
echo Directorio actual: %CD%
dir R\shiny_app.R
echo --------------------------
echo Limpiando procesos previos...
taskkill /F /IM Rscript.exe /T 2>nul
echo Iniciando ObfuscatoR Studio (TEST NUCLEAR) en puerto 9901...
Rscript -e "library(datasets); data(iris); options(shiny.port = 9901, shiny.launch.browser = TRUE); source('R/obfuscator_core.R'); source('R/shiny_app.R'); run_obfuscator_app()"
pause
