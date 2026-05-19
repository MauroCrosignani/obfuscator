# Render que preserva la estructura de `glimpse()` para el helper IA Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hacer que `resumen_de()` y `render_dataset_profile_for_ai()` muestren siempre el tipo importado exacto de cada variable, conservando la semantica segura ya alcanzada.

**Architecture:** El cambio debe concentrarse en el renderer y en pruebas de contrato visibles, sin reabrir toda la inferencia semantica. La estrategia es mantener el objeto estructurado actual, enriquecer solo lo necesario para el render y estandarizar la redaccion variable por variable como `importada como ...; interpretada como ...`.

**Tech Stack:** R, testthat, renderer actual en `R/ai_dataset_profile.R`, suite en `tests/testthat/test_ai_dataset_profile.R`, documentacion en `docs/02_diseno`, `docs/03_planes` y `docs/06_desarrollo/fases`

---

## File Structure

### Existing files to modify
- `R/ai_dataset_profile.R`
  - ajustar `render_ai_profile_variable()`;
  - revisar textos por familia de variable;
  - agregar cualquier helper minimo de presentacion si hace falta.
- `tests/testthat/test_ai_dataset_profile.R`
  - fijar contrato visible del nuevo renderer;
  - cubrir continuidad con `salida = "estructura"`.
- `docs/03_planes/2026-05-18_guia-operativa-profile_dataset_for_ai.md`
  - alinear ejemplos y wording del render una vez implementado.
- `README.md`
  - actualizar ejemplo o descripcion visible del helper si cambia el texto de salida.

### New files to create
- `docs/06_desarrollo/fases/2026-05-19_render_que_preserva_la_estructura_de_glimpse_para_el_helper_ia.md`
  - cierre documental de implementacion del renderer.

### Reference files
- `docs/02_diseno/2026-05-19-diseno-de-render-que-preserva-la-estructura-de-glimpse-para-el-helper-ia.md`
- `docs/02_diseno/2026-05-19-diseno-de-mejoras-semanticas-para-resumen_de-y-profile_dataset_for_ai.md`
- `docs/06_desarrollo/fases/2026-05-19_analisis_critico_del_render_actual_del_helper_ia.md`
- `R/ai_dataset_profile.R`
- `tests/testthat/test_ai_dataset_profile.R`

---

## Task 1: Fijar en tests el nuevo contrato visible del renderer

**Files:**
- Modify: `tests/testthat/test_ai_dataset_profile.R`
- Reference: `docs/02_diseno/2026-05-19-diseno-de-render-que-preserva-la-estructura-de-glimpse-para-el-helper-ia.md`

- [ ] **Step 1: Agregar una prueba de numericas con tipo importado visible**

Crear o ampliar una prueba para esperar algo como:

```text
altura: importada como integer; interpretada como numerica entera
peso: importada como double; interpretada como numerica decimal
```

- [ ] **Step 2: Agregar una prueba de categorica `character` visible**

Esperar algo como:

```text
sex: importada como character; interpretada como categorica
```

- [ ] **Step 3: Agregar una prueba especifica para `factor`**

Crear un caso sintetico donde una columna categórica llegue como `factor` y esperar explícitamente:

```text
importada como factor; interpretada como categorica
```

- [ ] **Step 4: Agregar una prueba de `entity_label` con tipo importado visible**

Esperar algo como:

```text
cliente: importada como character; interpretada como etiqueta nominal de entidad
```

- [ ] **Step 5: Agregar una prueba de `list-columns` con tipo importado visible**

Esperar algo como:

```text
films: importada como list; interpretada como columna lista
```

- [ ] **Step 6: Agregar una prueba de temporal ya parseada y temporal en texto**

Cubrir dos casos:

- `Date` o `POSIXct`:
  - `importada como Date` o `importada como POSIXct`
- fecha detectada desde `character`:
  - `importada como character; interpretada como fecha...`

- [ ] **Step 7: Correr el bloque nuevo y confirmar rojo atribuible**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Expected:
- FAIL localizado en los nuevos contratos del renderer, sin tocar aun la implementacion.

- [ ] **Step 8: No commitear mientras el renderer nuevo siga rojo**

Checkpoint local de TDD:

- sin commit mientras los contratos visibles nuevos no pasen.

---

## Task 2: Ajustar el renderer para mostrar `imported_type` en todas las familias principales

**Files:**
- Modify: `R/ai_dataset_profile.R`
- Test: `tests/testthat/test_ai_dataset_profile.R`

- [ ] **Step 1: Estandarizar la estructura verbal**

Adoptar como regla general:

```text
importada como <tipo>; interpretada como <semantica>; ...
```

No hace falta usarla en el mismo orden textual exacto en todos los casos si hubiera una excepción fuerte, pero sí debe quedar visible la doble capa.

- [ ] **Step 2: Aplicar el nuevo render a numericas**

Actualizar:

- `numerica entera`
- `numerica decimal`

para que expongan también:

- `importada como integer`
- `importada como double`

- [ ] **Step 3: Aplicar el nuevo render a categoricas simples y de alta cardinalidad**

Actualizar:

- `categorica`
- `categorica compuesta`

para que expongan:

- `importada como character`
- `importada como factor`

según corresponda.

- [ ] **Step 4: Aplicar el nuevo render a `entity_label`, `free_text` y `collection`**

Actualizar estas familias para que muestren:

- `importada como character`
- `importada como list`

antes de la lectura semántica.

- [ ] **Step 5: Homogeneizar el estilo de temporales**

Mantener el detalle temporal actual, pero alinearlo con el resto del render:

- primero tipo importado;
- luego interpretación;
- luego formato, granularidad y rango cuando aplique.

- [ ] **Step 6: Mantener compatibilidad de `salida = "estructura"`**

No alterar:

- `imported_type`
- `inferred_type`
- `summary`
- `warnings`

como contrato estructurado; el cambio de esta task es principalmente de texto visible.

- [ ] **Step 7: Correr tests del helper y confirmar verde**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Expected:
- PASS en el archivo del helper.

- [ ] **Step 8: Correr suite completa**

Run:

```powershell
Rscript tests/testthat.R
```

Expected:
- PASS total sin regresiones.

- [ ] **Step 9: Commit**

```bash
git add R/ai_dataset_profile.R tests/testthat/test_ai_dataset_profile.R
git commit -m "feat: preserve imported types in ai summary renderer"
```

---

## Task 3: Alinear documentacion visible

**Files:**
- Modify: `docs/03_planes/2026-05-18_guia-operativa-profile_dataset_for_ai.md`
- Modify: `README.md`
- Modify: `docs/README.md`
- Create: `docs/06_desarrollo/fases/2026-05-19_render_que_preserva_la_estructura_de_glimpse_para_el_helper_ia.md`

- [ ] **Step 1: Actualizar la guia operativa**

Explicar que el helper ahora muestra:

- tipo importado exacto;
- interpretacion semantica;
- y resumen seguro.

- [ ] **Step 2: Actualizar el README**

Refrescar la descripcion del helper para que no quede atras respecto del render vigente.

- [ ] **Step 3: Registrar el cierre del paso**

Documentar:

- que problema resolvia este cambio;
- que artefactos se tocaron;
- que verificaciones se corrieron;
- y que sigue pendiente despues.

- [ ] **Step 4: Actualizar el indice documental**

Agregar el nuevo cierre y, si corresponde, el nuevo plan al [docs/README.md](c:/Users/mcros/Documents/obfuscator/docs/README.md).

- [ ] **Step 5: Verificacion documental minima**

Run:

```powershell
rg -n "importada como|interpretada como" README.md docs/03_planes/2026-05-18_guia-operativa-profile_dataset_for_ai.md
```

Expected:
- referencias visibles y consistentes con el renderer nuevo.

- [ ] **Step 6: Commit**

```bash
git add README.md docs/03_planes/2026-05-18_guia-operativa-profile_dataset_for_ai.md docs/README.md docs/06_desarrollo/fases/2026-05-19_render_que_preserva_la_estructura_de_glimpse_para_el_helper_ia.md
git commit -m "docs: align ai helper docs with imported-type renderer"
```

---

## Recommended execution notes

- Implementar primero el contrato visible del renderer antes de volver a tocar heurísticas nuevas.
- No reabrir en esta misma pasada la taxonomía de categorías compuestas salvo que el cambio de wording obligue.
- Mantener el cambio enfocado en preservar estructura, no en reinventar toda la semántica.

## Final verification

Antes de cerrar la implementación completa de este plan:

- [ ] correr `Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"`
- [ ] correr `Rscript tests/testthat.R`
- [ ] revisar `git diff --check`
- [ ] confirmar que no se mezclen cambios ajenos del árbol de trabajo

## Immediate next step after this plan

Ejecutar `Task 1` con TDD estricto y verificar primero el bloque de renderer antes de considerar nuevas refinaciones semánticas.
