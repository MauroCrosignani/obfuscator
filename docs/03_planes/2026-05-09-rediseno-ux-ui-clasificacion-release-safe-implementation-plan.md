# Rediseno UX/UI de Clasificacion Release-Safe Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reemplazar el mecanismo principal de clasificacion por zonas y listas por una experiencia basada en `rol principal por variable`, con ayuda contextual clara y compatibilidad con el modelo `release-safe`.

**Architecture:** Mantener el motor de ofuscacion y el modelo `release-safe` existentes, pero migrar la UX de clasificacion a una tabla principal de variables y una ficha lateral de detalle. La implementacion debe preservar continuidad de plantillas, resumen de auditoria, export gating y codigo generado, evitando un rediseño “big bang”. Primero se introduce el nuevo modelo de datos y sugerencias, luego la tabla principal, despues la ficha lateral, y solo al final se retira o degrada el drag-and-drop viejo.

**Tech Stack:** R, Shiny, testthat, CSS local en `www/app.css`, JS local en `www/app.js`

---

## File Structure

### Existing files to modify
- `R/shiny_app.R`
  - UI principal, estado reactivo, clasificacion visual, resumen de dataset, ayuda y wiring de `k-anonymity`.
  - Sera el punto principal de integracion del rediseño.
- `R/obfuscator_core.R`
  - Deteccion de roles, plantillas persistibles y helpers base de clasificacion.
  - Debe ampliarse de forma conservadora para soportar el nuevo modelo de roles y sugerencias.
- `R/release_decision_helpers.R`
  - Helpers de release state, alertas y resumen de auditoria.
  - Solo debe tocarse si la nueva UX requiere exponer mejor impacto o estados por variable.
- `tests/testthat/test_obfuscator.R`
  - Cobertura principal de helpers UI-adjacent.
  - Recibira pruebas del nuevo modelo de roles, tabla y ayuda contextual.
- `tests/testthat/test_persistence_release_flow.R`
  - Cobertura de plantillas, hash de esquema y fuzzy matching.
  - Debe proteger compatibilidad de persistencia durante la migracion.
- `www/app.css`
  - Estilos de paneles, tarjetas, tabla, badges y ficha lateral.
- `www/app.js`
  - Interacciones de UI. Solo tocar si la nueva ficha lateral o controles inline lo necesitan.

### Existing design/doc context
- `docs/02_diseno/2026-05-09-rediseno-ux-ui-clasificacion-release-safe.md`
- `docs/02_diseno/2026-05-06-liberacion-segura-a-terceros-design.md`
- `docs/03_planes/manual_testing_plan.md`
- `docs/01_especificaciones/ESPECIFICACION_DE_REQUERIMIENTOS_v3.1.md`

### New files to create
- `tests/testthat/test_release_safe_roles_ui.R`
  - Pruebas especificas para:
    - roles `ID/QI/SENS/PRIV/KEEP/EXC`
    - sugerencias iniciales
    - tabla principal
    - ficha lateral
    - ayuda contextual

### Strong recommendations before coding
- No eliminar el flujo actual completo en la primera tarea.
- Mantener compatibilidad temporal entre el modelo viejo y el nuevo mientras los tests migran.
- No meter logica sustantiva en `www/app.js` si puede vivir como helper puro en R.
- Hacer que toda sugerencia automatica devuelva motivo explicable, no solo etiqueta.

---

## Phase Overview

### Phase 1: Modelo de roles y compatibilidad de persistencia
Outcome:
- roles oficiales estables para `ID`, `QI`, `SENS`, `PRIV`, `KEEP`, `EXC`
- sugerencias iniciales explicables
- continuidad de plantillas por esquema sin romper fuzzy matching

### Phase 2: Tabla principal de clasificacion
Outcome:
- nueva vista principal por variable
- lectura mas clara del dataset
- cambio rapido de rol sin abrir modales complejos

### Phase 3: Ficha lateral y ayuda contextual
Outcome:
- detalle por variable
- tratamiento tecnico contextual
- impacto sobre `k-anonymity`, riesgo residual y revision manual

### Phase 4: Migracion controlada desde drag-and-drop
Outcome:
- coexistencia temporal minimizada
- retiro o degradacion del mecanismo anterior
- plan de pruebas manuales actualizado

---

### Task 1: Definir el modelo canonico de roles y sugerencias

**Files:**
- Modify: `R/shiny_app.R`
- Modify: `R/obfuscator_core.R`
- Create: `tests/testthat/test_release_safe_roles_ui.R`
- Test: `tests/testthat/test_release_safe_roles_ui.R`

- [ ] **Step 1: Write the failing tests for canonical roles**

Cubrir al menos:
- roles permitidos `ID`, `QI`, `SENS`, `PRIV`, `KEEP`, `EXC`
- prioridad de sugerencia
- exclusion de `SENS` y `PRIV` del conjunto automatico de `QI`
- motivo de sugerencia legible

Ejemplo:

```r
test_that("edad se sugiere como QI numerico y observacion como PRIV", {
  df <- build_demo_personas_dataset()
  suggestions <- suggest_release_safe_roles(df)

  expect_equal(suggestions$edad$role, "QI")
  expect_equal(suggestions$observacion$role, "PRIV")
  expect_match(suggestions$edad$reason, "combin")
})
```

- [ ] **Step 2: Run the focused test and verify failure**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_safe_roles_ui.R')"
```

Expected:
- FAIL because canonical suggestion helpers do not exist yet

- [ ] **Step 3: Implement minimal pure helpers**

Agregar helpers puros para:
- roles permitidos
- sugerencia inicial por columna
- motivo explicable
- conjunto de `quasi-identifiers`

- [ ] **Step 4: Re-run the focused tests**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_safe_roles_ui.R')"
```

Expected:
- PASS

- [ ] **Step 5: Commit**

```bash
git add R/shiny_app.R R/obfuscator_core.R tests/testthat/test_release_safe_roles_ui.R
git commit -m "feat: define canonical release-safe role suggestions"
```

---

### Task 2: Preservar persistencia y fuzzy matching bajo el nuevo modelo

**Files:**
- Modify: `R/shiny_app.R`
- Modify: `R/obfuscator_core.R`
- Modify: `tests/testthat/test_persistence_release_flow.R`
- Test: `tests/testthat/test_persistence_release_flow.R`

- [ ] **Step 1: Write failing persistence tests for new roles**

Cubrir:
- guardado y carga de `SENS` y `PRIV`
- persistencia de `KEEP/EXC` si aplica
- no persistir artefactos restringidos
- fuzzy matching que conserva el rol sugerido correcto

- [ ] **Step 2: Run the persistence tests and confirm failure**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_persistence_release_flow.R')"
```

- [ ] **Step 3: Extend template persistence minimally**

Implementar solo lo necesario para:
- guardar roles nuevos;
- cargar roles nuevos;
- mantener compatibilidad con plantillas previas.

- [ ] **Step 4: Re-run persistence tests**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_persistence_release_flow.R')"
```

- [ ] **Step 5: Commit**

```bash
git add R/shiny_app.R R/obfuscator_core.R tests/testthat/test_persistence_release_flow.R
git commit -m "feat: preserve templates under role-based release-safe model"
```

---

### Task 3: Introducir la tabla principal de clasificacion

**Files:**
- Modify: `R/shiny_app.R`
- Modify: `www/app.css`
- Modify: `tests/testthat/test_obfuscator.R`
- Modify: `tests/testthat/test_release_safe_roles_ui.R`
- Test: `tests/testthat/test_obfuscator.R`
- Test: `tests/testthat/test_release_safe_roles_ui.R`

- [ ] **Step 1: Write failing UI-adjacent tests for the variable table**

Cubrir al menos:
- la vista principal renderiza una tabla/lista por variable;
- cada fila muestra `Variable`, `Tipo`, `Rol`, `Tratamiento`, `Riesgo`, `Estado`, `Accion`;
- los badges de rol son visibles.

Ejemplo:

```r
test_that("main classification view exposes one row per variable", {
  html <- as.character(render_release_variable_table_for_test(build_demo_personas_dataset()))
  expect_match(html, "Rol")
  expect_match(html, "Tratamiento")
  expect_match(html, "Editar")
})
```

- [ ] **Step 2: Run focused tests and confirm failure**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R'); test_file('tests/testthat/test_release_safe_roles_ui.R')"
```

- [ ] **Step 3: Implement the table view with minimal styling**

Crear helpers de render para:
- filas por variable;
- badges de rol;
- riesgo y estado resumidos.

- [ ] **Step 4: Re-run focused tests**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R'); test_file('tests/testthat/test_release_safe_roles_ui.R')"
```

- [ ] **Step 5: Commit**

```bash
git add R/shiny_app.R www/app.css tests/testthat/test_obfuscator.R tests/testthat/test_release_safe_roles_ui.R
git commit -m "feat: add variable table for release-safe classification"
```

---

### Task 4: Agregar cambio rapido de rol desde la vista principal

**Files:**
- Modify: `R/shiny_app.R`
- Modify: `tests/testthat/test_release_safe_roles_ui.R`
- Test: `tests/testthat/test_release_safe_roles_ui.R`

- [ ] **Step 1: Write failing tests for quick role changes**

Cubrir:
- cambio de rol principal desde control inline;
- recalculo del conjunto de `QI`;
- reflejo del cambio en estado y resumen visual.

- [ ] **Step 2: Run the focused test and verify failure**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_safe_roles_ui.R')"
```

- [ ] **Step 3: Implement minimal inline role change support**

Agregar solo lo necesario para:
- editar el rol principal;
- actualizar `role_state`;
- refrescar tabla y resumen.

- [ ] **Step 4: Re-run the focused test**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_safe_roles_ui.R')"
```

- [ ] **Step 5: Commit**

```bash
git add R/shiny_app.R tests/testthat/test_release_safe_roles_ui.R
git commit -m "feat: support inline release-safe role updates"
```

---

### Task 5: Implementar ficha lateral de detalle por variable

**Files:**
- Modify: `R/shiny_app.R`
- Modify: `www/app.css`
- Modify: `www/app.js` only if UI behavior strictly requires it
- Modify: `tests/testthat/test_release_safe_roles_ui.R`
- Test: `tests/testthat/test_release_safe_roles_ui.R`

- [ ] **Step 1: Write failing tests for the detail panel**

Cubrir:
- apertura de ficha de detalle;
- bloques `Resumen`, `Rol principal`, `Tratamiento tecnico`, `Impacto`, `Ayuda`;
- contenido contextual segun tipo de variable.

- [ ] **Step 2: Run the focused test and confirm failure**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_safe_roles_ui.R')"
```

- [ ] **Step 3: Implement the minimal detail panel**

Crear el panel de detalle sin cerrar todavia el flujo viejo.

- [ ] **Step 4: Re-run the focused test**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_safe_roles_ui.R')"
```

- [ ] **Step 5: Commit**

```bash
git add R/shiny_app.R www/app.css www/app.js tests/testthat/test_release_safe_roles_ui.R
git commit -m "feat: add release-safe variable detail panel"
```

---

### Task 6: Introducir ayuda contextual y guia de flujo

**Files:**
- Modify: `R/shiny_app.R`
- Modify: `tests/testthat/test_obfuscator.R`
- Modify: `docs/03_planes/manual_testing_plan.md`
- Modify: `docs/07_presentacion/mensajes_clave_para_tecnicos.md`
- Test: `tests/testthat/test_obfuscator.R`

- [ ] **Step 1: Write failing tests for contextual help**

Cubrir:
- tooltips o textos cortos por rol;
- ayuda visible sobre `k-anonymity` y flujo de trabajo;
- definicion minima de `ID/QI/SENS/PRIV/KEEP/EXC`.

- [ ] **Step 2: Run the focused test and confirm failure**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R')"
```

- [ ] **Step 3: Implement contextual help minimally**

Agregar:
- ayuda contextual minima en la tabla;
- ayuda aplicada en la ficha;
- guia breve de flujo de trabajo.

- [ ] **Step 4: Re-run the focused test**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R')"
```

- [ ] **Step 5: Update docs**

Actualizar:
- plan manual de pruebas;
- mensajes tecnicos clave.

- [ ] **Step 6: Commit**

```bash
git add R/shiny_app.R tests/testthat/test_obfuscator.R docs/03_planes/manual_testing_plan.md docs/07_presentacion/mensajes_clave_para_tecnicos.md
git commit -m "feat: add contextual release-safe help"
```

---

### Task 7: Conectar la nueva clasificacion con `k-anonymity`, auditoria y preview

**Files:**
- Modify: `R/shiny_app.R`
- Modify: `R/release_decision_helpers.R` only if impact text needs pure helpers
- Modify: `tests/testthat/test_obfuscator.R`
- Modify: `tests/testthat/test_release_decision.R`
- Test: `tests/testthat/test_obfuscator.R`
- Test: `tests/testthat/test_release_decision.R`

- [ ] **Step 1: Write failing tests for behavioral alignment**

Cubrir:
- `QI` numericos entran a `quasi_identifiers`;
- `SENS` y `PRIV` no entran automaticamente;
- preview, resumen y auditoria reflejan la nueva clasificacion.

- [ ] **Step 2: Run focused tests and confirm failure**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R'); test_file('tests/testthat/test_release_decision.R')"
```

- [ ] **Step 3: Implement minimal alignment**

Conectar:
- tabla/ficha;
- `role_state`;
- `privacy_model`;
- resumen de auditoria.

- [ ] **Step 4: Re-run focused tests**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R'); test_file('tests/testthat/test_release_decision.R')"
```

- [ ] **Step 5: Commit**

```bash
git add R/shiny_app.R R/release_decision_helpers.R tests/testthat/test_obfuscator.R tests/testthat/test_release_decision.R
git commit -m "feat: align role-based classification with release-safe behavior"
```

---

### Task 8: Retirar o degradar el drag-and-drop antiguo

**Files:**
- Modify: `R/shiny_app.R`
- Modify: `www/app.js`
- Modify: `www/app.css`
- Modify: `tests/testthat/test_obfuscator.R`
- Test: `tests/testthat/test_obfuscator.R`

- [ ] **Step 1: Write failing regression tests for old/new coexistence removal**

Cubrir:
- la vista principal ya no depende de las zonas antiguas;
- si el drag-and-drop subsiste, queda como secundario y no como clasificacion primaria.

- [ ] **Step 2: Run focused tests and confirm failure**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R')"
```

- [ ] **Step 3: Remove or demote the old interaction path**

Elegir una sola estrategia:
- retirar el drag-and-drop viejo;
- o degradarlo a modo secundario/experimental claramente marcado.

- [ ] **Step 4: Re-run the focused tests**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R')"
```

- [ ] **Step 5: Commit**

```bash
git add R/shiny_app.R www/app.js www/app.css tests/testthat/test_obfuscator.R
git commit -m "feat: migrate release-safe classification away from drag-and-drop"
```

---

### Task 9: Full verification and updated manual validation

**Files:**
- Modify: `docs/03_planes/manual_testing_plan.md`
- Modify: `docs/06_desarrollo/BACKLOG.md` only if continuity tasks change
- Test: `tests/testthat/test_release_safe_roles_ui.R`
- Test: `tests/testthat/test_obfuscator.R`
- Test: `tests/testthat/test_persistence_release_flow.R`
- Test: `tests/testthat/test_release_decision.R`
- Test: `tests/testthat.R`

- [ ] **Step 1: Run targeted test files**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_safe_roles_ui.R')"
Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R')"
Rscript -e "library(testthat); test_file('tests/testthat/test_persistence_release_flow.R')"
Rscript -e "library(testthat); test_file('tests/testthat/test_release_decision.R')"
```

- [ ] **Step 2: Run the full suite**

Run:

```powershell
Rscript tests/testthat.R
```

Expected:
- PASS

- [ ] **Step 3: Update the manual test plan for the new UI**

Registrar:
- como probar la tabla principal;
- como probar la ficha lateral;
- como verificar `QI` numericos como `edad`;
- como interpretar `SENS` y `PRIV`.

- [ ] **Step 4: Commit**

```bash
git add docs/03_planes/manual_testing_plan.md docs/06_desarrollo/BACKLOG.md tests/testthat/test_release_safe_roles_ui.R tests/testthat/test_obfuscator.R tests/testthat/test_persistence_release_flow.R tests/testthat/test_release_decision.R
git commit -m "test: verify role-based release-safe classification flow"
```

---

## Risks to watch during execution

- que el nuevo modelo de roles conviva demasiado tiempo con el viejo y genere ambiguedad;
- que la sugerencia automatica se vuelva opaca o “magica” en lugar de explicable;
- que la persistencia vieja quede incompatible sin una ruta de migracion razonable;
- que la ayuda quede muy larga y rompa el objetivo de simplicidad operativa.

## Success criteria

El rediseño puede considerarse exitoso cuando:

1. un usuario puede clasificar `edad` como `QI` sin lucha con la UI;
2. `observacion` e `indicador_privado` no quedan mezcladas como simples categoricas;
3. el flujo de ayuda explica bien roles y efectos sin exigir leer un manual largo;
4. plantillas y fuzzy matching siguen funcionando;
5. la suite completa sigue verde.
