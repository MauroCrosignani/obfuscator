# Dataset Profile for AI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar un helper externo de RStudio que construya un perfil seguro y semantico de un dataset y lo renderice como texto util para interacciones con IA.

**Architecture:** La implementacion debe separarse en dos funciones: una capa de analisis estructurado y una capa de render textual. El analisis no debe depender de la UI Shiny ni del flujo de liberacion controlada, aunque puede reutilizar heuristicas o helpers pequeños ya existentes si no acoplan la solucion a la app.

**Tech Stack:** R, testthat, base R/tibble, helpers existentes del repo cuando sean reutilizables sin acoplamiento

---

## File Structure

### New files to create
- `R/ai_dataset_profile.R`
  - Contendra `profile_dataset_for_ai()` y `render_dataset_profile_for_ai()`.
  - Debe encapsular inferencia de tipos, reglas de seguridad y render compacto.
- `tests/testthat/test_ai_dataset_profile.R`
  - Cobertura dedicada del helper.

### Existing files to modify
- `R/obfuscator_core.R`
  - Solo si conviene extraer o reutilizar utilidades de deteccion de identificadores, texto libre o fechas sin meter dependencias cruzadas feas.
- `tests/testthat.R`
  - Solo si fuera necesario registrar explicitamente el nuevo archivo de tests, segun el patron actual del repo.
- `docs/02_diseno/2026-05-17-diseno-dataset-profile-for-ai.md`
  - Referencia normativa y funcional del plan.

### Normative context
- `docs/02_diseno/2026-05-17-diseno-dataset-profile-for-ai.md`
- `docs/README.md`

---

### Task 1: Fijar el contrato base en tests

**Files:**
- Create: `tests/testthat/test_ai_dataset_profile.R`
- Test: `tests/testthat/test_ai_dataset_profile.R`

- [ ] **Step 1: Escribir una prueba para la estructura minima del perfil**

Agregar un caso que afirme que `profile_dataset_for_ai()` devuelve al menos:

```r
test_that("profile_dataset_for_ai devuelve estructura base", {
  profile <- profile_dataset_for_ai(iris, dataset_name = "iris")

  expect_equal(profile$dataset_name, "iris")
  expect_equal(profile$dimensions$rows, 150)
  expect_equal(profile$dimensions$cols, 5)
  expect_true("variables" %in% names(profile))
  expect_true(length(profile$variables) == 5)
})
```

- [ ] **Step 2: Escribir una prueba para render compacto**

Confirmar que `render_dataset_profile_for_ai()` devuelve texto y menciona dataset, dimensiones y al menos una variable.

- [ ] **Step 3: Escribir una prueba para fechas importadas como texto**

Construir un `data.frame` pequeño con valores tipo:

```r
c("2026-05-17 14:22:31.123456", "2026-05-18 09:10:11.654321")
```

Esperar:

- `imported_type == "character"`
- `inferred_type == "datetime"`
- advertencia de parseo o necesidad de normalizacion

- [ ] **Step 4: Escribir una prueba para identificadores sin exponer ejemplos**

Usar una columna tipo `P001`, `P002`, `P003` y verificar que el render:

- mencione el patron;
- no incluya ejemplos literales completos.

- [ ] **Step 5: Escribir una prueba para texto libre**

Verificar que el perfil lo marque como `free_text` o `unknown` con senal de texto libre, y que el render no liste valores reales.

- [ ] **Step 6: Correr la prueba enfocada y verificar que falle**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Expected:
- FAIL porque la funcionalidad aun no existe

- [ ] **Step 7: Commit**

```bash
git add tests/testthat/test_ai_dataset_profile.R
git commit -m "test: define dataset profile for ai contract"
```

---

### Task 2: Implementar la capa estructurada de perfil

**Files:**
- Create: `R/ai_dataset_profile.R`
- Modify: `R/obfuscator_core.R` (solo si hace falta extraer helpers chicos)
- Test: `tests/testthat/test_ai_dataset_profile.R`

- [ ] **Step 1: Crear helpers internos pequenos y separados**

Diseñar funciones internas como:

- `infer_imported_type()`
- `infer_observed_pattern()`
- `infer_semantic_type()`
- `build_variable_profile()`

Mantener responsabilidades chicas y testeables.

- [ ] **Step 2: Implementar `profile_dataset_for_ai()`**

Debe construir:

- nombre de dataset;
- dimensiones;
- timestamp de generacion;
- lista de perfiles por variable;
- advertencias globales.

- [ ] **Step 3: Implementar reglas minimas por clase**

Cubrir al menos:

- identificadores;
- categoricas;
- numericas;
- fechas y fechas-hora;
- texto libre.

- [ ] **Step 4: Implementar la distincion `imported_type` vs `inferred_type`**

En particular, las fechas que lleguen como `character` no deben degradarse automaticamente a texto libre.

- [ ] **Step 5: Correr la prueba enfocada y verificar que pase en la estructura base**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Expected:
- PASS en los casos de estructura y de inferencia minima

- [ ] **Step 6: Commit**

```bash
git add R/ai_dataset_profile.R tests/testthat/test_ai_dataset_profile.R R/obfuscator_core.R
git commit -m "feat: add structured dataset profile for ai"
```

---

### Task 3: Implementar el renderer compacto para IA

**Files:**
- Modify: `R/ai_dataset_profile.R`
- Test: `tests/testthat/test_ai_dataset_profile.R`

- [ ] **Step 1: Implementar `render_dataset_profile_for_ai()`**

Debe devolver un bloque textual legible con:

- nombre del dataset;
- dimensiones;
- resumen por variable;
- advertencias finales.

- [ ] **Step 2: Aplicar reglas de seguridad por defecto**

No incluir por defecto:

- filas completas;
- ejemplos literales de identificadores;
- texto libre real;
- valores crudos altamente sensibles.

- [ ] **Step 3: Renderizar variables segun su clase**

Ejemplos esperados:

- categoricas con niveles pocos;
- categoricas con top `n` si hay muchos niveles;
- numericas con rangos redondeados;
- temporales con rango y granularidad;
- identificadores con patron aproximado;
- texto libre sin contenido real.

- [ ] **Step 4: Correr la prueba enfocada**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Expected:
- PASS

- [ ] **Step 5: Commit**

```bash
git add R/ai_dataset_profile.R tests/testthat/test_ai_dataset_profile.R
git commit -m "feat: render dataset profile as ai-ready text"
```

---

### Task 4: Endurecer inferencias temporales y de riesgo semantico

**Files:**
- Modify: `R/ai_dataset_profile.R`
- Test: `tests/testthat/test_ai_dataset_profile.R`

- [ ] **Step 1: Agregar deteccion de granularidad temporal**

Distinguir:

- fecha;
- fecha-hora;
- fecha-hora con fracciones;
- y formatos ambiguos.

- [ ] **Step 2: Agregar confianza de inferencia**

Usar al menos:

- `high`
- `medium`
- `low`

- [ ] **Step 3: Agregar `role_guess` liviano**

Valores sugeridos:

- `identifier`
- `quasi_identifier`
- `sensitive`
- `free_text`
- `analytic`
- `unknown`

- [ ] **Step 4: Reforzar advertencias de parseo**

Cuando una fecha temporal llegue como texto y el patron sea claro, emitir advertencia tipo:

- `parece fecha-hora, pero llego como character`
- `requiere normalizacion de parseo`

- [ ] **Step 5: Correr la prueba enfocada**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Expected:
- PASS

- [ ] **Step 6: Commit**

```bash
git add R/ai_dataset_profile.R tests/testthat/test_ai_dataset_profile.R
git commit -m "feat: improve temporal and semantic inference for ai profiles"
```

---

### Task 5: Cerrar verificacion y ejemplo de uso desde RStudio

**Files:**
- Modify: `tests/testthat/test_ai_dataset_profile.R`
- Optionally modify: `docs/02_diseno/2026-05-17-diseno-dataset-profile-for-ai.md`
- Create or modify: `docs/06_desarrollo/fases/2026-05-17_dataset_profile_for_ai.md`

- [ ] **Step 1: Agregar un ejemplo de uso real con dataset demo**

Ejemplo en comentarios o en nota de cierre:

```r
profile <- profile_dataset_for_ai(obfuscator_demo_personas, "obfuscator_demo_personas")
cat(render_dataset_profile_for_ai(profile))
```

- [ ] **Step 2: Correr la suite focalizada**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Expected:
- PASS

- [ ] **Step 3: Correr la suite completa**

Run:

```powershell
Rscript tests/testthat.R
```

Expected:
- PASS

- [ ] **Step 4: Documentar cierre del paso**

Registrar:

- que el helper es externo a la UI;
- que no envia muestras crudas;
- y como trata fechas importadas como texto.

- [ ] **Step 5: Commit**

```bash
git add tests/testthat/test_ai_dataset_profile.R docs/06_desarrollo/fases/2026-05-17_dataset_profile_for_ai.md docs/02_diseno/2026-05-17-diseno-dataset-profile-for-ai.md
git commit -m "docs: capture dataset profile for ai completion"
```

---

## Validation Notes

- Mantener esta funcionalidad desacoplada de `shiny_app.R`.
- No introducir salida por defecto que exponga texto libre real.
- Si se reutilizan helpers del core, evitar dependencias circulares o semanticas propias de la UI.
- Preferir reglas explicables antes que heuristicas demasiado "magicas".

## Execution Recommendation

La implementacion deberia arrancar por `Task 1` y `Task 2`, porque fijan el contrato y la forma del objeto antes de discutir detalles del renderer textual.
