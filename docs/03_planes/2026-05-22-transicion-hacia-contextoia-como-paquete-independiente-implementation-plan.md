# Transicion hacia `contextoia` como paquete independiente Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preparar el helper de perfilado seguro para IA para una futura extraccion a `contextoia`, mejorando la compatibilidad con carga como paquete y reduciendo acoplamientos fragiles sin romper el flujo actual con `source()`.

**Architecture:** La implementacion debe priorizar compatibilidad limpia con `devtools::load_all()`, manteniendo un puente transicional con `source("R/obfuscator_core.R")`. El trabajo debe distinguir entre codigo propio del helper y codigo que solo existe para exponerlo dentro de ObfuscatoR.

**Tech Stack:** R, `devtools`, `pkgload`, organizacion de archivos en `R/`, tests de helper en `tests/testthat`, documentacion operativa en `README.md` y `docs/03_planes`.

---

### Task 1: Auditar el mecanismo actual de carga del helper

**Files:**
- Inspect: `R/obfuscator_core.R`
- Inspect: archivos `R/` usados por `resumen_de()` y el helper IA
- Modify: `tests/testthat/test_ai_dataset_profile.R` si hace falta fijar contrato nuevo

- [ ] Identificar si hoy el helper depende de `sys.source()` o de busqueda fragil de archivos companeros.
- [ ] Listar que partes son:
  - propias del helper;
  - propias del flujo principal de ObfuscatoR;
  - o solo de compatibilidad.
- [ ] Si hace falta, agregar un test que reproduzca el fallo actual o la limitacion actual con carga tipo paquete.

### Task 2: Introducir compatibilidad limpia con `devtools::load_all()`

**Files:**
- Modify: `R/obfuscator_core.R`
- Modify: archivos del helper IA si necesitan exportacion o carga mas directa
- Test: `tests/testthat/test_ai_dataset_profile.R`

- [ ] Diseñar una ruta de carga que funcione con `devtools::load_all()` sin depender del directorio de trabajo actual.
- [ ] Mantener compatibilidad transicional con `source("R/obfuscator_core.R")`.
- [ ] Evitar soluciones que refuercen el acoplamiento a `obfuscator_core.R` como “dueño” permanente del helper.
- [ ] Verificar con una prueba o script reproducible que el helper puede cargarse bien en ambos modos.

### Task 3: Marcar fronteras internas del futuro `contextoia`

**Files:**
- Modify: `R/obfuscator_core.R`
- Modify: `README.md`
- Modify: `docs/03_planes/2026-05-18_guia-operativa-profile_dataset_for_ai.md`

- [ ] Documentar que funciones forman la API visible del futuro paquete:
  - `resumen_de()`
  - `profile_dataset_for_ai()`
  - `render_dataset_profile_for_ai()`
- [ ] Dejar claro que el helper no deberia depender estructuralmente del flujo Shiny.
- [ ] Si aparece codigo de puente o bootstrap, identificarlo como compatibilidad transicional.

### Task 4: Documentar el cierre del paso

**Files:**
- Modify: `docs/README.md`
- Create: `docs/06_desarrollo/fases/2026-05-22_transicion_hacia_contextoia_como_paquete_independiente.md`

- [ ] Registrar que se mejoro para `load_all()`.
- [ ] Registrar que se mantuvo para `source()`.
- [ ] Dejar explicitamente asentado si la futura extraccion a `contextoia` quedo facilitada o si quedan puntos de acoplamiento pendientes.

## Prioridad recomendada

1. entender el loader actual
2. arreglar `load_all()` sin fragilidad
3. marcar fronteras del helper
4. documentar el cierre

Esta secuencia evita arreglos cosmeticos y mantiene foco en facilitar una futura separacion real.
