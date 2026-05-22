# Ajustes semanticos basados en prueba real del helper IA Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ajustar el helper de perfilado seguro para IA a partir de evidencia real de uso institucional, mejorando tres casos concretos sin reabrir todo el modelo semantico.

**Architecture:** El cambio debe concentrarse en `R/ai_dataset_profile.R` y en contratos visibles de `tests/testthat/test_ai_dataset_profile.R`. La estrategia es atacar primero el renderer de categorias, despues la heuristica de nombres institucionales y al final la reinterpretacion semantica de ciertos `POSIXct`.

**Tech Stack:** R, testthat, renderer y heuristicas en `R/ai_dataset_profile.R`, documentacion en `docs/02_diseno`, `docs/03_planes` y `docs/06_desarrollo/fases`.

---

## Task 1: Entrecomillar valores categoricos visibles

**Files:**
- Modify: `tests/testthat/test_ai_dataset_profile.R`
- Modify: `R/ai_dataset_profile.R`

- [ ] Agregar tests visibles para `valores observados`, `top niveles`, `etiquetas observadas` y `top etiquetas` con comillas dobles.
- [ ] Verificar rojo localizado del bloque nuevo.
- [ ] Ajustar el renderer para usar comillas dobles sin romper casos con comas internas.
- [ ] Correr `Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"` y confirmar verde.

## Task 2: Reclasificar nombres institucionales repetibles

**Files:**
- Modify: `tests/testthat/test_ai_dataset_profile.R`
- Modify: `R/ai_dataset_profile.R`

- [ ] Agregar un caso sintetico similar a `NOMBRE_UNIDAD`:
  - nombres institucionales;
  - longitud media o alta;
  - repeticion real;
  - sin narratividad abierta.
- [ ] Fijar como contrato esperado `entity_label` y no `free_text`.
- [ ] Ajustar la heuristica para dar mas peso a repeticion institucional y menos a longitud sola.
- [ ] Re-correr tests del helper y confirmar verde.

## Task 3: Reinterpretar `POSIXct` con hora no sustantiva como `fecha`

**Files:**
- Modify: `tests/testthat/test_ai_dataset_profile.R`
- Modify: `R/ai_dataset_profile.R`

- [ ] Agregar dos pruebas:
  - `POSIXct` con hora siempre `00:00:00` -> interpretada como `fecha`
  - `POSIXct` con hora variable -> sigue como `fecha-hora`
- [ ] Verificar rojo localizado.
- [ ] Ajustar la logica de interpretacion temporal manteniendo visible `importada como POSIXct`.
- [ ] Correr:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
Rscript tests/testthat.R
```

- [ ] Confirmar PASS antes de cualquier commit.

## Task 4: Alinear documentacion

**Files:**
- Modify: `README.md`
- Modify: `docs/03_planes/2026-05-18_guia-operativa-profile_dataset_for_ai.md`
- Modify: `docs/README.md`
- Create: `docs/06_desarrollo/fases/2026-05-22_ajustes_semanticos_basados_en_prueba_real_del_helper_ia.md`

- [ ] Actualizar la guia operativa con el nuevo criterio de comillas, nombres institucionales y `POSIXct` sin hora sustantiva.
- [ ] Refrescar el README si cambia el ejemplo visible del helper.
- [ ] Registrar el cierre del paso con evidencia de verificacion.

## Prioridad recomendada

1. comillas dobles en categorias visibles
2. nombres institucionales como `entity_label`
3. `POSIXct` con interpretacion de `fecha`

Esta secuencia maximiza valor y reduce riesgo.
