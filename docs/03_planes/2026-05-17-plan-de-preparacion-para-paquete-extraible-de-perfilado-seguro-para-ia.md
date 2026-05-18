# Plan de preparacion para paquete extraible de perfilado seguro para IA

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preparar dentro de ObfuscatoR una base de codigo y pruebas que permita extraer mas adelante un paquete R independiente de perfilado seguro para IA sin arrastrar dependencias de la app.

**Architecture:** El trabajo se organiza en tres capas: primero aislar helpers puros y su suite de tests, despues consolidar una API interna estable, y por ultimo documentar la frontera de extraccion. El objetivo no es todavia publicar un paquete, sino dejar la funcionalidad lista para volverse paquete con bajo costo y baja incertidumbre.

**Tech Stack:** R, testthat, estructura actual de `R/` y `tests/testthat/`, documentacion en `docs/`

---

## File Structure

### New files to create
- `R/ai_dataset_profile.R`
  - API principal del subproyecto.
- `tests/testthat/test_ai_dataset_profile.R`
  - Pruebas del helper principal.
- `docs/06_desarrollo/fases/2026-05-17_subproyecto_paquete_perfilado_ia.md`
  - Cierre de fase cuando se avance en la implementacion.

### Existing files to modify
- `R/obfuscator_core.R`
  - Solo si hay que mover o extraer helpers puros reutilizables.
- `docs/02_diseno/2026-05-17-diseno-dataset-profile-for-ai.md`
  - Ya define la funcionalidad base.
- `docs/02_diseno/2026-05-17-diseno-de-paquete-extraible-para-perfilado-seguro-para-ia.md`
  - Ya define la frontera del futuro paquete.
- `docs/03_planes/2026-05-17-dataset-profile-for-ai-implementation-plan.md`
  - Plan funcional del helper.

### Extraction target (future, not now)
- paquete R independiente, nombre a definir luego.

---

### Task 1: Definir la API interna minima y su frontera

**Files:**
- Modify: `docs/02_diseno/2026-05-17-diseno-dataset-profile-for-ai.md`
- Modify: `docs/02_diseno/2026-05-17-diseno-de-paquete-extraible-para-perfilado-seguro-para-ia.md`

- [ ] **Step 1: Fijar el conjunto de funciones publicas minimas**

Dejar explicitamente marcadas como candidatas publicas:

- `profile_dataset_for_ai()`
- `render_dataset_profile_for_ai()`
- `validate_ai_safe_profile()` o equivalente

- [ ] **Step 2: Fijar el conjunto de helpers internos**

Listar funciones que deben quedar internas aunque existan:

- deteccion de patrones;
- parseo inferido;
- resumenes por clase de variable.

- [ ] **Step 3: Documentar que el subproyecto no depende de Shiny**

Dejar claro que:

- no usa reactividad;
- no usa estado de UI;
- no depende del modelo de liberacion de la app.

- [ ] **Step 4: Commit**

```bash
git add docs/02_diseno/2026-05-17-diseno-dataset-profile-for-ai.md docs/02_diseno/2026-05-17-diseno-de-paquete-extraible-para-perfilado-seguro-para-ia.md
git commit -m "docs: define extractable ai profiling api boundary"
```

---

### Task 2: Aislar el helper funcional dentro del repo

**Files:**
- Create: `R/ai_dataset_profile.R`
- Create: `tests/testthat/test_ai_dataset_profile.R`
- Modify: `R/obfuscator_core.R` (solo si hace falta mover helpers puros)

- [ ] **Step 1: Implementar el helper en archivo propio**

No mezclarlo con:

- `shiny_app.R`
- helpers de estado reactivo
- logica de exportacion

- [ ] **Step 2: Evitar acoplamientos innecesarios**

Si se reutilizan funciones del core:

- verificar si conviene copiarlas;
- o extraer una utilidad pura compartible.

- [ ] **Step 3: Construir tests dedicados**

La suite del subproyecto debe poder correrse sin levantar la app.

- [ ] **Step 4: Verificar que no existan dependencias sobre UI**

Revisar imports, nombres y dependencias para que el archivo sea portable.

- [ ] **Step 5: Commit**

```bash
git add R/ai_dataset_profile.R tests/testthat/test_ai_dataset_profile.R R/obfuscator_core.R
git commit -m "feat: isolate ai profiling helper for future extraction"
```

---

### Task 3: Fortalecer los guardrails de seguridad del helper

**Files:**
- Modify: `R/ai_dataset_profile.R`
- Modify: `tests/testthat/test_ai_dataset_profile.R`

- [ ] **Step 1: Agregar validaciones explicitas**

Validar por defecto que el render no incluya:

- filas completas;
- identificadores literales;
- texto libre literal;
- timestamps excesivamente precisos si no hacen falta.

- [ ] **Step 2: Cubrir fechas problemáticas importadas como texto**

Agregar casos de prueba con:

- microsegundos;
- formatos mixtos;
- parseo no confiable.

- [ ] **Step 3: Cubrir identificadores y texto libre**

Confirmar que:

- describen patron y riesgo;
- pero no se imprimen ejemplos crudos.

- [ ] **Step 4: Commit**

```bash
git add R/ai_dataset_profile.R tests/testthat/test_ai_dataset_profile.R
git commit -m "feat: harden ai-safe profiling guardrails"
```

---

### Task 4: Hacer visible la extraibilidad futura

**Files:**
- Modify: `docs/03_planes/2026-05-17-dataset-profile-for-ai-implementation-plan.md`
- Create or modify: `docs/06_desarrollo/fases/2026-05-17_subproyecto_paquete_perfilado_ia.md`
- Optionally create later: `inst/examples/` or `scripts/` (si se considera util)

- [ ] **Step 1: Registrar que el helper ya es extraible o casi extraible**

Documentar:

- si ya esta desacoplado;
- si todavia depende de funciones del core;
- y que faltaria para convertirlo en paquete.

- [ ] **Step 2: Dejar un checklist de extraccion**

Checklist minimo:

- archivo `DESCRIPTION`
- `NAMESPACE`
- roxygen o documentacion equivalente
- ejemplos reproducibles
- tests independientes
- licencia y nombre del paquete

- [ ] **Step 3: Registrar riesgos pendientes**

Por ejemplo:

- heuristicas todavia inestables;
- dependencias del core;
- necesidad de datasets de ejemplo anonimizados.

- [ ] **Step 4: Commit**

```bash
git add docs/03_planes/2026-05-17-dataset-profile-for-ai-implementation-plan.md docs/06_desarrollo/fases/2026-05-17_subproyecto_paquete_perfilado_ia.md
git commit -m "docs: record extraction readiness for ai profiling package"
```

---

## Validation Notes

- No tratar la futura extraccion como refactor cosmetico.
- Si una heuristica afecta seguridad, debe quedar dentro del paquete y bien testeada.
- Mantener la API del subproyecto mas chica que la API de la app.
- No publicar ni empaquetar hasta que la frontera entre helper y ObfuscatoR sea clara.

## Execution Recommendation

Si se prioriza este subproyecto, el mejor orden es:

1. implementar el helper funcional y su suite de tests;
2. endurecer guardrails de seguridad;
3. recien despues declarar que esta listo para extraccion.
