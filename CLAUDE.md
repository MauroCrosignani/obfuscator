# ObfuscatoR - Guía de Desarrollo y Continuidad

## Continuidad del Proyecto
> [!IMPORTANT]
> **Instrucción de Carga**: Al iniciar cualquier sesión, utiliza siempre las skills de `C:\Users\mcros\.codex\superpowers`.

## Comando de Arranque (Shiny App)
```r
library(datasets)
data(iris)
source('R/obfuscator_core.R')
source('R/shiny_app.R')
run_obfuscator_app()
```

## Estado Actual
- **Fase**: Implementación de "Persistencia de Clasificación (Proactive Assistant)".
- **Último hito**: k-anonymity verificado y corregido en UI/Core.
- **Pendiente**: Sistema de guardado/carga de plantillas JSON con fuzzy matching.

## Reglas de Oro
1. **Auditoría Radical**: Las transformaciones deben ser obvias visualmente (ej. prefijo 999).
2. **UX Premium**: Contraste WCAG AA (mínimo 4.5:1), glassmorphism y micro-animaciones.
3. **No Push Prematuro**: No hacer push al repositorio remoto hasta que la funcionalidad actual esté completada y verificada al 100%.
4. **Carga Real**: Asegurar que `iris` esté cargado explícitamente en el entorno antes de lanzar la app.

## Skills de Superpowers
Ubicación: `C:\Users\mcros\.codex\superpowers`
Skills clave: `brainstorming`, `writing-plans`, `executing-plans`, `verification-before-completion`.
