# Liberacion Sin Cuasi-Identificadores Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permitir liberacion controlada cuando no existan cuasi-identificadores relevantes, manteniendo advertencias y estados diferenciados para variables sensibles, privadas y resultados no defendibles.

**Architecture:** El cambio debe concentrarse en la capa pura de decision de liberacion y en los puntos de integracion de la app, no en parches dispersos del flujo reactivo. Primero se fijan pruebas y helpers para distinguir `k-anonymity no aplicado` de `k-anonymity fallido`, y solo despues se ajustan mensajes de UI, auditoria y CTA asociados.

**Tech Stack:** R, Shiny, testthat, CSS existente en `www/`

---

## File Structure

### Existing files to modify
- `R/release_decision_helpers.R`
  - Define la semantica del veredicto de liberacion y del resumen de auditoria.
  - Debe incorporar el nuevo camino `sin QI relevantes`.
- `R/shiny_app.R`
  - Integra la construccion del `privacy_model`, el disparo de ofuscacion y los mensajes de UI.
  - Debe dejar de tratar la ausencia de `QI` como error cuando el escenario sea defendible.
- `tests/testthat/test_release_decision.R`
  - Cobertura principal del contrato de decision y de los mensajes de auditoria.
- `tests/testthat/test_obfuscator.R`
  - Regresiones del flujo visible en la app cuando corresponda.
- `docs/03_planes/manual_testing_plan.md`
  - Casos manuales para validar este escenario.

### Normative context
- `docs/02_diseno/2026-05-11-liberacion-controlada-sin-cuasi-identificadores.md`
- `docs/01_especificaciones/ESPECIFICACION_DE_REQUERIMIENTOS_v3.1.md`
- `docs/03_planes/2026-05-06-liberacion-segura-a-terceros-implementation-plan.md`

---

### Task 1: Fijar el contrato del nuevo escenario en pruebas

**Files:**
- Modify: `tests/testthat/test_release_decision.R`
- Test: `tests/testthat/test_release_decision.R`

- [ ] **Step 1: Escribir una prueba para liberacion sin QI y sin riesgos adicionales**

Agregar un caso que afirme:

```r
test_that("puede liberar sin k-anonymity cuando no hay quasi-identificadores relevantes", {
  state <- derive_release_state_from_obfuscation(
    privacy_enabled = TRUE,
    privacy_satisfied = FALSE,
    final_row_count = 10,
    quasi_identifier_count = 0,
    has_private_variables = FALSE,
    has_sensitive_variables = FALSE,
    has_blocking_risk = FALSE
  )

  expect_equal(state$release_state, "Liberable")
  expect_true(any(grepl("no fue aplicado", state$notes)))
})
```

- [ ] **Step 2: Escribir una prueba para `SENS` en ausencia de QI**

Esperar `Liberable con advertencias` o el estado equivalente definido por el helper, con CTA explicita.

- [ ] **Step 3: Escribir una prueba para `PRIV` en ausencia de QI**

Esperar `Requiere revision manual`, no `Liberable`.

- [ ] **Step 4: Escribir una prueba para resultado vacio**

Confirmar que el artefacto siga siendo `No liberable sin rediseno`.

- [ ] **Step 5: Correr la prueba enfocada y verificar que falle**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_decision.R')"
```

Expected:
- FAIL en los nuevos casos porque la semantica actual sigue exigiendo `k-anonymity`

- [ ] **Step 6: Commit**

```bash
git add tests/testthat/test_release_decision.R
git commit -m "test: define no-QI controlled release semantics"
```

---

### Task 2: Implementar la semantica pura de decision

**Files:**
- Modify: `R/release_decision_helpers.R`
- Test: `tests/testthat/test_release_decision.R`

- [ ] **Step 1: Extender el helper de decision con senales explicitas**

Agregar parametros claros como:

- `quasi_identifier_count`
- `has_sensitive_variables`
- `has_private_variables`
- `has_blocking_risk`

- [ ] **Step 2: Implementar el camino `sin QI relevantes`**

Aplicar la politica documentada:

- `Liberable` si no hay `QI`, no hay `PRIV`, no hay bloqueo residual y el resultado no esta vacio;
- `Liberable con advertencias` si hay `SENS` pero no bloqueo duro;
- `Requiere revision manual` si hay `PRIV`;
- `No liberable sin rediseno` si el resultado final queda vacio.

- [ ] **Step 3: Ajustar las notas y razones del estado**

Agregar texto explicito:

- `k-anonymity no fue aplicado porque no se definieron cuasi-identificadores relevantes`
- CTA especifica para `SENS`
- CTA especifica para `PRIV`

- [ ] **Step 4: Reescribir el resumen de auditoria asociado**

Hacer que `build_release_audit_summary()` o helpers relacionados distingan claramente:

- `k-anonymity satisfecha`
- `k-anonymity no aplicado`
- `revision manual requerida`

- [ ] **Step 5: Correr la prueba enfocada y verificar que pase**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_decision.R')"
```

Expected:
- PASS en los casos nuevos y existentes

- [ ] **Step 6: Commit**

```bash
git add R/release_decision_helpers.R tests/testthat/test_release_decision.R
git commit -m "feat: support controlled release without quasi-identifiers"
```

---

### Task 3: Integrar el nuevo flujo en la app sin romper el caso clasico de k-anonymity

**Files:**
- Modify: `R/shiny_app.R`
- Test: `tests/testthat/test_obfuscator.R`
- Test: `tests/testthat/test_release_decision.R`

- [ ] **Step 1: Ajustar la validacion previa a la ofuscacion**

Cuando `k-anonymity` este activado pero no existan `QI`, no mostrar error automatico si:

- hay identificadores transformables o excluibles;
- y el escenario puede evaluarse con la ruta `sin QI`.

Mantener el bloqueo solo donde realmente corresponda.

- [ ] **Step 2: Pasar a la capa pura las senales necesarias**

Desde el flujo de server, informar:

- cantidad de `QI`;
- presencia de `SENS`;
- presencia de `PRIV`;
- si el resultado final quedo vacio.

- [ ] **Step 3: Ajustar mensajes de UI**

Mostrar mensajes como:

- `No hay cuasi-identificadores definidos. La liberacion se evaluara sin k-anonymity.`
- `Existen variables privadas fuera del control automatico. Se requiere revision manual.`

- [ ] **Step 4: Agregar una regresion minima de UI/helper**

En `tests/testthat/test_obfuscator.R`, cubrir el helper o mensaje que ya no trate la ausencia de `QI` como error generico.

- [ ] **Step 5: Correr pruebas focalizadas**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R'); test_file('tests/testthat/test_release_decision.R')"
```

Expected:
- PASS

- [ ] **Step 6: Commit**

```bash
git add R/shiny_app.R tests/testthat/test_obfuscator.R tests/testthat/test_release_decision.R
git commit -m "feat: integrate no-QI release path in app flow"
```

---

### Task 4: Cerrar validacion manual y documentacion operativa

**Files:**
- Modify: `docs/03_planes/manual_testing_plan.md`
- Create or modify: `docs/06_desarrollo/fases/2026-05-11_liberacion_sin_cuasi_identificadores.md`

- [ ] **Step 1: Agregar casos manuales**

Incluir:

- identificadores directos + sin `QI` + sin `SENS`/`PRIV`
- identificadores directos + sin `QI` + `SENS`
- identificadores directos + sin `QI` + `PRIV`

- [ ] **Step 2: Documentar resultados esperados**

Para cada caso, indicar:

- estado de liberacion esperado;
- mensaje de auditoria esperado;
- y si corresponde revision manual.

- [ ] **Step 3: Documentar el cierre del cambio**

Registrar:

- por que se hizo;
- que hueco conceptual corrige;
- y que limita todavia el MVP.

- [ ] **Step 4: Commit**

```bash
git add docs/03_planes/manual_testing_plan.md docs/06_desarrollo/fases/2026-05-11_liberacion_sin_cuasi_identificadores.md
git commit -m "docs: capture no-QI controlled release workflow"
```

---

## Verification checklist before claiming complete

- [ ] `Rscript -e "library(testthat); test_file('tests/testthat/test_release_decision.R')"` passes
- [ ] `Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R')"` passes
- [ ] `Rscript tests/testthat.R` passes
- [ ] Manual scenario without `QI` yields the expected non-error flow
- [ ] Audit summary explicitly distinguishes `k-anonymity no aplicado` from `k-anonymity insatisfecha`
