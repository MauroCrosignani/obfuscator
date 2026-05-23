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

## Protocolo Local para Agentes
- Antes de delegar implementación a agentes en un `worktree`, verificar que la documentación normativa vigente del proyecto exista dentro de ese mismo `worktree`.
- Si la especificación, auditoría, plan o notas de diseño todavía no están committeadas y por eso no aparecen en el `worktree`, sincronizar copias locales al `worktree` antes de despachar agentes.
- En el prompt del agente, referenciar rutas reales dentro del `worktree`, no solo rutas del workspace principal ni resúmenes conversacionales.
- Si por alguna razón excepcional el agente debe trabajar con texto reenviado en el prompt y no con archivos presentes en disco, dejarlo explícitamente asentado como limitación temporal y corregirlo antes de la siguiente delegación.
- Registrar resultados, problemas y ajustes de uso de agentes en `docs/06_desarrollo/metodologia-agentes/AGENT_EXECUTION_NOTES.md` para evaluar si esta práctica conviene persistir más adelante como mejora reusable.
