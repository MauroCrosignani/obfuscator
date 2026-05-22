# Evidencia y senales heuristicas para numericas institucionales Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mejorar el renderer del helper IA para numericas institucionales, separando tipo importado, clasificacion programatica, evidencia observada y senales heuristicas prudentes sin sobreafirmar que una columna es un codigo.

**Architecture:** El cambio debe concentrarse en `R/ai_dataset_profile.R` y en contratos visibles de `tests/testthat/test_ai_dataset_profile.R`. Primero se fija el wording visible, despues se agrega evidencia observada para numericas constantes o enteriformes, y por ultimo se activa una senal heuristica prudente de posible codigo numerico.

**Tech Stack:** R, testthat, renderer y heuristicas en `R/ai_dataset_profile.R`, documentacion operativa en `README.md`, `docs/03_planes` y `docs/06_desarrollo/fases`.

---

### Task 1: Fijar el nuevo wording visible para numericas

**Files:**
- Modify: `tests/testthat/test_ai_dataset_profile.R`
- Modify: `R/ai_dataset_profile.R`

- [ ] Agregar tests visibles que esperen la nueva estructura para numericas:
  - `tipo importado: ...`
  - `clasificacion programatica: ...`
- [ ] Incluir un caso simple `double` continuo que no active evidencia adicional.
- [ ] Correr `Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"` y confirmar rojo en el bloque nuevo.
- [ ] Ajustar el renderer para usar `tipo importado:` y `clasificacion programatica:` en las ramas numericas.
- [ ] Re-correr `Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"` y confirmar verde.

### Task 2: Agregar evidencia observada para numericas enteriformes y constantes

**Files:**
- Modify: `tests/testthat/test_ai_dataset_profile.R`
- Modify: `R/ai_dataset_profile.R`

- [ ] Agregar un test para `double` con solo valores enteros observados.
- [ ] Agregar un test para columna numerica con valor unico observado.
- [ ] Fijar como contrato frases literales:
  - `evidencia observada: solo toma valores enteros`
  - `evidencia observada: todos los valores observados son iguales: 14`
- [ ] Implementar la logica minima para detectar esos casos sin romper otras familias.
- [ ] Re-correr tests del helper y confirmar verde.

### Task 3: Activar una senal heuristica prudente de posible codigo numerico

**Files:**
- Modify: `tests/testthat/test_ai_dataset_profile.R`
- Modify: `R/ai_dataset_profile.R`

- [ ] Agregar un caso inspirado en `COD_TIPO_VARIABLE` o `UNIDAD_FUNCIONAL` con:
  - nombre de columna compatible;
  - `double` enteriforme;
  - cardinalidad compatible con dominio tecnico.
- [ ] Fijar como contrato visible:
  - `senal heuristica: podria funcionar como codigo numerico`
- [ ] Agregar al menos una prueba negativa donde una numerica continua no deba disparar esa senal.
- [ ] Implementar una heuristica prudente basada en evidencia combinada, sin reclasificar la columna como `codigo numerico`.
- [ ] Correr:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
Rscript tests/testthat.R
```

- [ ] Confirmar PASS antes de cualquier commit.

### Task 4: Alinear documentacion

**Files:**
- Modify: `README.md`
- Modify: `docs/03_planes/2026-05-18_guia-operativa-profile_dataset_for_ai.md`
- Modify: `docs/README.md`
- Create: `docs/06_desarrollo/fases/2026-05-22_numericas_institucionales_con_evidencia_y_senales.md`

- [ ] Actualizar el README con el nuevo wording visible para numericas.
- [ ] Actualizar la guia operativa para explicitar la separacion entre evidencia observada y senal heuristica.
- [ ] Registrar el cierre del paso con ejemplos y evidencia de verificacion.

## Prioridad recomendada

1. nuevo wording visible
2. evidencia observada para enteriformes y constantes
3. senal heuristica de posible codigo numerico

Esta secuencia minimiza el riesgo de sobrerreaccionar heuristicas antes de tener un lenguaje visible claro y testeado.
