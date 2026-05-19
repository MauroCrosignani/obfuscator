# Mejoras semanticas para `resumen_de()` y `profile_dataset_for_ai()` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mejorar el helper de perfilado seguro para IA para que preserve mejor la semantica estructural de las columnas sin perder prudencia, atendiendo primero los casos que hoy producen salidas confusas o demasiado pobres.

**Architecture:** La implementacion debe mantener `resumen_de()` como interfaz amigable y concentrar los cambios semanticos en el core de [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R). La estrategia es enriquecer el perfil estructurado por variable y luego ajustar el renderer para usar esas pistas nuevas, en vez de seguir parcheando texto de salida sin mejorar el modelo interno.

**Tech Stack:** R, testthat, helper actual en `R/ai_dataset_profile.R`, suite en `tests/testthat/test_ai_dataset_profile.R`, documentacion en `docs/02_diseno`, `docs/03_planes` y `docs/06_desarrollo/fases`

---

## File Structure

### Existing files to modify
- `R/ai_dataset_profile.R`
  - ampliar el modelo semantico por variable;
  - ajustar inferencia de `character`, `list` y numericas;
  - reescribir partes del renderer para usar la semantica nueva.
- `tests/testthat/test_ai_dataset_profile.R`
  - agregar casos reales y sinteticos para las nuevas heuristicas.
- `docs/03_planes/2026-05-18_guia-operativa-profile_dataset_for_ai.md`
  - alinear la guia operativa cuando la implementacion quede lista.
- `README.md`
  - ajustar ejemplos o descripcion si la salida cambia de manera relevante.

### New files to create
- `docs/06_desarrollo/fases/2026-05-19_mejoras_semanticas_para_el_helper_de_perfilado_ia.md`
  - cierre documental de la implementacion una vez completada.

### Reference files
- `docs/02_diseno/2026-05-19-diseno-de-mejoras-semanticas-para-resumen_de-y-profile_dataset_for_ai.md`
- `docs/03_planes/2026-05-18_guia-operativa-profile_dataset_for_ai.md`
- `docs/06_desarrollo/fases/2026-05-19_diseno_de_mejoras_semanticas_para_el_helper_de_perfilado_ia.md`
- `R/ai_dataset_profile.R`
- `tests/testthat/test_ai_dataset_profile.R`

---

## Scope strategy

Este plan cubre los seis frentes del diseno, pero los ejecuta en dos oleadas:

### Oleada 1: prioridad alta
- categorias compuestas con separadores internos;
- `character` nominales de alta cardinalidad;
- `list-columns`;
- diferenciacion entre `integer` y `double`.

### Oleada 2: refinamiento posterior dentro del mismo plan
- nombres de entidad vs texto libre abierto;
- advertencias mas precisas por familia de riesgo.

La razon es practica:

- la oleada 1 resuelve los sintomas mas visibles y estructuralmente pobres;
- la oleada 2 exige mas calibracion heuristica y conviene apoyarla sobre una base ya mas expresiva.

## Regla de ejecucion importante

Este plan no admite commits con la suite enfocada en rojo.

Si se usa TDD para abrir trabajo en curso:

- los tests nuevos deben agregarse en bloques acotados y atribuibles;
- y cada task que termina en commit debe cerrar con el bloque de pruebas relevante en verde.

En particular:

- no se debe dejar `tests/testthat/test_ai_dataset_profile.R` con fallos deliberados mezclados con el resto de la suite;
- si hace falta introducir rojo primero, conviene correr solo el bloque o descripcion nueva que se esta abriendo;
- y antes de cada commit deben seguir pasando los tests existentes fuera del bloque nuevo.

---

## Task 1: Fijar el nuevo contrato semantico en tests

**Files:**
- Modify: `tests/testthat/test_ai_dataset_profile.R`
- Reference: `docs/02_diseno/2026-05-19-diseno-de-mejoras-semanticas-para-resumen_de-y-profile_dataset_for_ai.md`

- [ ] **Step 1: Agregar un caso real basado en `starwars` para categorizacion rica**

Escribir una prueba con un subconjunto o el dataset `starwars` que cubra:

- `name`
- `height`
- `mass`
- `hair_color`
- `homeworld`
- `films`

Esperar, al menos:

- que `hair_color` no se renderice como una lista plana ambigua;
- que `homeworld` no caiga en `unknown`;
- que `films` no quede solo como `unknown`.

- [ ] **Step 2: Escribir una prueba sintetica para categorias compuestas**

Crear un `data.frame` tipo:

```r
df <- data.frame(
  color = c("white, blue", "white", "black", "auburn, grey"),
  stringsAsFactors = FALSE
)
```

Esperar:

- `inferred_type = "categorical"`
- presencia de una pista estructural tipo `value_shape`
- renderer sin duplicaciones engañosas como `white, white, blue`.

- [ ] **Step 3: Escribir una prueba para alta cardinalidad nominal**

Crear una columna `character` con:

- valores cortos o medianos;
- bastante cardinalidad;
- pero sin rasgos de texto libre narrativo.

Esperar:

- `inferred_type = "categorical"`
- `cardinality_class = "high"` o equivalente;
- renderer con `niveles observados` y `top niveles`.

- [ ] **Step 4: Escribir una prueba negativa para alta cardinalidad que siga siendo `free_text`**

Crear una columna `character` con:

- alta cardinalidad;
- frases cortas o medianas;
- pero rasgos claramente narrativos o de observacion.

Esperar:

- que no se sobreclasifique como `categorical`;
- y que siga tratandose como `free_text`.

- [ ] **Step 5: Escribir una prueba para `list-columns`**

Crear un `data.frame` con una columna lista:

```r
df <- tibble::tibble(
  films = list(c("A New Hope", "Return of the Jedi"), character(0), "The Empire Strikes Back")
)
```

Esperar:

- `inferred_type = "collection"` o equivalente;
- informacion sobre `element_type = "character"` cuando la evidencia alcance;
- renderer que describa estructura de coleccion y no `unknown`.

- [ ] **Step 6: Escribir una prueba para `integer` vs `double`**

Crear dos columnas:

```r
df <- data.frame(
  altura = c(170L, 180L, 190L),
  peso = c(70.5, 80.0, 90.2)
)
```

Esperar:

- `numeric_kind = "integer"` para `altura`
- `numeric_kind = "double"` para `peso`
- renderer distinguible, por ejemplo `numerica entera` y `numerica decimal`.

- [ ] **Step 7: Agregar checks de regresion para renderer existente**

Reforzar o agregar pruebas para asegurar que:

- las categoricas cortas existentes sigan bien;
- el modo conservador siga redactando como hoy donde corresponde;
- y el cambio de categorias compuestas no rompa los casos simples.

- [ ] **Step 8: Correr solo el bloque nuevo y verificar que falle**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R', filter = 'semantica_(starwars|categorias_compuestas|alta_cardinalidad|list_columns|numeric_kind)')"
```

Expected:
- FAIL atribuible solo a los contratos nuevos, porque la semantica todavia no esta implementada

- [ ] **Step 9: No commitear mientras el bloque nuevo siga rojo**

Este paso es solo un checkpoint local de TDD.

Criterio:

- mientras el filtro nuevo siga rojo, no hacer commit;
- el primer commit del frente debe ocurrir recien cuando el bloque nuevo y la suite previa relevante esten en verde.

- [ ] **Step 10: Volver a correr el bloque nuevo y la suite previa ya en verde**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R', filter = 'semantica_(starwars|categorias_compuestas|alta_cardinalidad|list_columns|numeric_kind)')"
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R', filter = '^(?!.*semantica_).*$')"
```

Expected:
- PASS en el bloque nuevo abierto en este task;
- PASS en la suite previa relevante.

- [ ] **Step 11: Commit**

```bash
git add tests/testthat/test_ai_dataset_profile.R
git commit -m "test: define semantic improvements contract for ai profiling helper"
```

---

## Task 2: Ampliar el modelo estructurado por variable

**Files:**
- Modify: `R/ai_dataset_profile.R`
- Test: `tests/testthat/test_ai_dataset_profile.R`

- [ ] **Step 1: Agregar propiedades estructurales nuevas al perfil por variable**

Incorporar, cuando corresponda:

- `value_shape`
- `cardinality_class`
- `numeric_kind`
- `element_type`
- `collection_cardinality`
- `render_strategy_hint`
- `delimiter_hint` cuando aplique

No hace falta llenar todas para todas las columnas, pero si definir una estructura coherente.

- [ ] **Step 2: Mantener compatibilidad hacia atras**

No romper campos ya consumidos por:

- `render_dataset_profile_for_ai()`
- `resumen_de()`
- tests vigentes

Si hace falta, agregar nuevas claves sin renombrar las existentes.

- [ ] **Step 3: Fijar contrato de compatibilidad para `salida = "estructura"`**

Dejar explicito en codigo y en pruebas que:

- los campos existentes siguen presentes;
- las claves nuevas son aditivas y opcionales;
- y si aparece `collection` o `entity_label`, no se rompen `role_guess`, `warnings` ni el acceso basico al perfil.

- [ ] **Step 4: Asegurar que el perfil siga siendo usable con `salida = "estructura"`**

Verificar que:

- la lista siga siendo navegable;
- y que las nuevas pistas no vuelvan ilegible el objeto.

- [ ] **Step 5: Correr el bloque nuevo y el resto de la suite existente**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R', filter = 'semantica_(starwars|categorias_compuestas|alta_cardinalidad|list_columns|numeric_kind)')"
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R', filter = '^(?!.*semantica_).*$')"
```

Expected:
- el bloque nuevo puede seguir rojo si faltan heuristicas o renderer;
- el resto de la suite debe seguir verde.

- [ ] **Step 6: Mantener cambios locales sin commit si el bloque nuevo sigue rojo**

Criterio:

- si cualquier filtro nuevo sigue rojo, no commitear este task;
- conservar el trabajo como progreso local o continuar directo al siguiente task;
- recien cerrar con commit cuando filtros relevantes y suite previa queden en verde.

- [ ] **Step 7: Volver a correr el bloque nuevo y la suite previa ya en verde**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R', filter = 'semantica_(starwars|categorias_compuestas|alta_cardinalidad|list_columns|numeric_kind)')"
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R', filter = '^(?!.*semantica_).*$')"
```

Expected:
- PASS en el bloque nuevo que este task deja estabilizado;
- PASS en la suite previa relevante.

- [ ] **Step 8: Commit**

```bash
git add R/ai_dataset_profile.R tests/testthat/test_ai_dataset_profile.R
git commit -m "feat: enrich variable profile structure for ai summaries"
```

---

## Task 3: Mejorar inferencia de `character` categoricos y compuestos

**Files:**
- Modify: `R/ai_dataset_profile.R`
- Test: `tests/testthat/test_ai_dataset_profile.R`

- [ ] **Step 1: Detectar categorias compuestas con separadores internos**

Agregar heuristica para identificar cuando una categorica contiene:

- delimitadores recurrentes;
- y combinaciones plausibles de etiquetas.

La salida debe marcar al menos:

- `value_shape = "compound_delimited"`
- `delimiter_hint = ","` cuando aplique.

- [ ] **Step 2: Evitar render engañoso en categorias compuestas**

No listar valores crudos con `paste(..., collapse = ", ")` cuando eso genera ambiguedad.

Usar una estrategia tipo:

- ejemplos de etiquetas;
- o declaracion de combinaciones textuales;
- o redaccion equivalente.

- [ ] **Step 3: Mejorar inferencia de alta cardinalidad nominal**

Agregar una via para que una columna `character`:

- corta o mediana;
- con valores nominales plausibles;
- y sin rasgos de fecha, identificador ni texto libre,

pueda clasificarse como categorica aunque tenga muchos niveles.

- [ ] **Step 4: Correr bloque de oleada 1 en verde**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R', filter = 'semantica_(starwars|categorias_compuestas|alta_cardinalidad)')"
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R', filter = '^(?!.*semantica_).*$')"
```

Expected:
- PASS en casos de categorias compuestas y alta cardinalidad;
- mejora automatizada y verificable en el caso estilo `starwars`;
- sin romper la suite preexistente.

- [ ] **Step 5: Commit**

```bash
git add R/ai_dataset_profile.R tests/testthat/test_ai_dataset_profile.R
git commit -m "feat: improve semantic inference for character columns"
```

---

## Task 4: Tratar `list-columns` y distinguir `integer` de `double`

**Files:**
- Modify: `R/ai_dataset_profile.R`
- Test: `tests/testthat/test_ai_dataset_profile.R`

- [ ] **Step 1: Incorporar tratamiento especifico para `list-columns`**

Cuando una columna sea `list`, evitar `unknown` generico y describirla como coleccion no atomica.

Inferir cuando sea razonable:

- `element_type`
- `collection_cardinality`

Definir explicitamente como se preservan:

- `warnings`
- `role_guess`
- y el contrato de `salida = "estructura"`

para que `collection` no sea solo un `unknown` con otro nombre.

- [ ] **Step 2: Ajustar el renderer para columnas lista**

Agregar una salida del tipo:

```text
films: columna lista; contiene colecciones de texto por fila; cardinalidad variable.
```

Sin expandir contenido interno fila a fila.

- [ ] **Step 3: Incorporar `numeric_kind`**

Distinguir explicitamente:

- `integer`
- `double`

y preservar esa informacion en el perfil y en el renderer.

- [ ] **Step 4: Ajustar texto del renderer para numericas**

Permitir variantes como:

- `numerica entera`
- `numerica decimal`

sin perder la informacion de rango ni `role_guess`.

- [ ] **Step 5: Correr bloque de list-columns y numeric kind en verde**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R', filter = 'semantica_(list_columns|numeric_kind|starwars)')"
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R', filter = '^(?!.*semantica_).*$')"
```

Expected:
- PASS en list-columns
- PASS en integer/double
- PASS en la suite preexistente

- [ ] **Step 6: Commit**

```bash
git add R/ai_dataset_profile.R tests/testthat/test_ai_dataset_profile.R
git commit -m "feat: add list-column handling and numeric kind details"
```

---

## Task 5: Refinar advertencias y documentacion operativa

**Files:**
- Modify: `R/ai_dataset_profile.R`
- Modify: `docs/03_planes/2026-05-18_guia-operativa-profile_dataset_for_ai.md`
- Modify: `README.md`
- Test: `tests/testthat/test_ai_dataset_profile.R`

- [ ] **Step 1: Refinar advertencias globales**

Separar, cuando aplique:

- texto libre abierto;
- nombres de entidad;
- columnas lista;
- categorias sensibles.

Evitar mensajes demasiado vagos como unica salida.

- [ ] **Step 2: Abrir la segunda oleada para `entity_label`**

Ahora si agregar pruebas e implementacion para:

- nombre de entidad vs texto libre abierto;
- y salida sin ejemplos reales.

Esto ya no debe convivir mezclado con la apertura inicial de oleada 1.

- [ ] **Step 3: Revisar que la salida siga siendo compacta**

Confirmar que el renderer no se vuelva demasiado largo ni tecnico.

- [ ] **Step 4: Endurecer la verificacion automatica con `starwars`**

Agregar asserts automaticos, no solo inspeccion visual, para verificar que:

- `name` no expone nombres reales;
- `homeworld` no queda en `unknown`;
- `films` no queda en `unknown`;
- `height` y `mass` distinguen su naturaleza numerica;
- y `hair_color` no colapsa en una lista plana engañosa.

- [ ] **Step 5: Actualizar guia operativa**

Documentar:

- que el helper ahora preserva mejor estructura tipo `glimpse()`;
- como interpreta `list-columns`;
- y como distingue numericas enteras y decimales.

- [ ] **Step 6: Ajustar README si la explicacion general lo necesita**

Agregar una nota breve sobre la capacidad de resumir:

- categorias compuestas;
- `list-columns`;
- y tipos numericos mas finos.

- [ ] **Step 7: Correr pruebas y ejemplos**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
Rscript tests/testthat.R
Rscript -e "library(datasets); data(iris); source('R/obfuscator_core.R'); cat(resumen_de(iris))"
Rscript -e "library(datasets); data(starwars, package = 'dplyr'); source('R/obfuscator_core.R'); cat(resumen_de(tibble::as_tibble(starwars), nombre_dataset = 'starwars'))"
```

Expected:
- PASS en suite enfocada
- PASS en suite completa
- salida legible en `iris`
- salida semanticamente mejor en `starwars`

- [ ] **Step 8: Documentar cierre**

Crear:

- `docs/06_desarrollo/fases/2026-05-19_mejoras_semanticas_para_el_helper_de_perfilado_ia.md`

incluyendo:

- problema resuelto;
- archivos tocados;
- alternativas descartadas;
- comandos de verificacion;
- limites remanentes;
- y siguiente paso recomendado.

- [ ] **Step 9: Commit**

```bash
git add R/ai_dataset_profile.R tests/testthat/test_ai_dataset_profile.R docs/03_planes/2026-05-18_guia-operativa-profile_dataset_for_ai.md README.md docs/06_desarrollo/fases/2026-05-19_mejoras_semanticas_para_el_helper_de_perfilado_ia.md
git commit -m "feat: improve semantic quality of ai dataset summaries"
```

---

## Validation Notes

- no exponer nombres reales ni texto libre real en los nuevos caminos;
- no tratar categorias compuestas como listas planas de niveles simples;
- no forzar nuevas clases semanticas si con propiedades adicionales alcanza;
- mantener la API publica de `resumen_de()` intacta;
- preferir `categorical` con matices antes que `unknown` cuando la evidencia sea suficiente;
- y no perder compatibilidad con el perfil estructurado ya vigente.

## Execution Recommendation

El orden recomendado de ejecucion es exactamente el del plan:

1. contrato en tests;
2. modelo estructurado;
3. inferencia de `character`;
4. `list-columns` y `numeric_kind`;
5. advertencias y documentacion.

La razon es que cada tarea reduce incertidumbre para la siguiente y evita mezclar demasiadas heuristicas nuevas en un solo commit.
