# Contexto de Fuente Etapa 1 para Dataset Profile for AI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Agregar una primera capa de contexto de fuente al helper `dataset_profile_for_ai()` mediante un parametro opcional `tipo_fuente`, manteniendo el helper util en modo cero-configuracion y sin introducir todavia `archivo_fuente` ni analisis del script activo.

**Architecture:** La primera etapa debe ser deliberadamente liviana. `tipo_fuente` funciona como una pista declarativa del usuario, con nombres en espanol y prioridad sobre la heuristica automatica, pero sin reemplazar ni endurecer el resto del helper. La meta es orientar mejor la interpretacion, no resolver aun la deteccion completa de origen ni el matching contra metadata externa.

**Tech Stack:** R, testthat, helper actual en `R/ai_dataset_profile.R`, documentacion en `docs/02_diseno`, ejemplos desde RStudio.

---

## File Structure

### Existing files to modify
- `R/ai_dataset_profile.R`
  - agregar soporte para `tipo_fuente`
  - validar valores aceptados
  - registrar origen declarado por el usuario
- `tests/testthat/test_ai_dataset_profile.R`
  - cobertura de `tipo_fuente`, precedencia y mensajes

### New files to create
- `docs/06_desarrollo/fases/2026-05-18_contexto_de_fuente_etapa_1_para_dataset_profile_for_ai.md`
  - cierre documental del paso

### Reference files
- `docs/02_diseno/2026-05-18-diseno-por-etapas-para-contexto-de-fuente-en-dataset-profile-for-ai.md`
- `docs/02_diseno/2026-05-18-diseno-de-resolucion-de-metadata-para-dataset-profile-for-ai.md`
- `docs/02_diseno/2026-05-18-diseno-de-identidad-de-fuente-para-metadata-de-perfilado-ia.md`
- `docs/02_diseno/2026-05-18-diseno-de-deteccion-de-fuentes-gca-net-desde-planillas-xls.md`
- `docs/02_diseno/2026-05-18-diseno-de-deteccion-de-fuentes-gca2-desde-planillas-xlsx-y-salidas-csv.md`
- `R/ai_dataset_profile.R`
- `tests/testthat/test_ai_dataset_profile.R`

---

## Scope de esta etapa

### Incluye
- parametro opcional `tipo_fuente`
- vocabulario controlado inicial:
  - `gca`
  - `gca2`
  - `oracle`
  - `excel`
  - `csv`
  - `desconocida`
- validacion y advertencias en espanol
- trazabilidad del origen declarado por el usuario
- ejemplos de uso desde RStudio

### No incluye
- `archivo_fuente`
- inspeccion de hojas Excel
- deteccion desde `Caratula` o `Informacion de la consulta`
- parseo del script activo
- resolvedor de metadata por carpeta

---

## Task 1: Fijar el contrato de `tipo_fuente` en tests

**Files:**
- Modify: `tests/testthat/test_ai_dataset_profile.R`
- Reference: `docs/02_diseno/2026-05-18-diseno-por-etapas-para-contexto-de-fuente-en-dataset-profile-for-ai.md`

- [ ] **Step 1: Agregar prueba para uso sin `tipo_fuente`**

Verificar que el helper siga funcionando igual que hoy cuando `tipo_fuente = NULL`.

Esperar:
- mismo comportamiento base;
- sin requirement nuevo;
- sin advertencias adicionales.

- [ ] **Step 2: Agregar prueba para `tipo_fuente = "gca2"`**

Construir un caso sencillo y verificar que:
- el perfil registre que la fuente fue declarada por el usuario;
- el valor quede disponible en el objeto resultante;
- no falle aunque el dataset por si solo no permita detectar el origen.

- [ ] **Step 3: Agregar prueba para `tipo_fuente = "oracle"`**

Verificar que:
- `oracle` sea aceptado como categoria valida;
- no exista necesidad de usar `odbc`;
- y el helper mantenga el termino semantico aprobado.

- [ ] **Step 4: Agregar prueba para valor invalido**

Ejemplo:

```r
profile_dataset_for_ai(df, "demo", tipo_fuente = "odbc")
```

Esperar:
- advertencia o error claro en espanol;
- mensaje que sugiera `oracle` como termino correcto.

- [ ] **Step 5: Correr prueba enfocada y verificar que falle**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Expected:
- FAIL en las pruebas nuevas porque `tipo_fuente` aun no existe

---

## Task 2: Implementar el parametro `tipo_fuente`

**Files:**
- Modify: `R/ai_dataset_profile.R`
- Test: `tests/testthat/test_ai_dataset_profile.R`

- [ ] **Step 1: Agregar `tipo_fuente = NULL` a la firma principal**

Actualizar:

```r
profile_dataset_for_ai(
  data,
  dataset_name = NULL,
  config = NULL,
  tipo_fuente = NULL,
  max_levels = 12,
  top_n = 10,
  round_digits = 2
)
```

- [ ] **Step 2: Definir vocabulario controlado**

Implementar validacion para:
- `gca`
- `gca2`
- `oracle`
- `excel`
- `csv`
- `desconocida`

- [ ] **Step 3: Crear helper de normalizacion**

Agregar algo como:
- `ai_profile_normalize_tipo_fuente()`

Responsabilidades:
- aceptar `NULL`
- normalizar a minusculas
- validar valores
- devolver mensajes legibles en espanol

- [ ] **Step 4: Correr prueba enfocada**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Expected:
- las pruebas de contrato ya no fallan por ausencia del parametro

---

## Task 3: Registrar trazabilidad del contexto declarado

**Files:**
- Modify: `R/ai_dataset_profile.R`
- Test: `tests/testthat/test_ai_dataset_profile.R`

- [ ] **Step 1: Agregar metadata de fuente al perfil**

El perfil deberia exponer algo como:

- `source_context$type`
- `source_context$source`

Ejemplo:
- `type = "gca2"`
- `source = "declared_by_user"`

- [ ] **Step 2: Mantener prioridad sin bloquear heuristicas**

`tipo_fuente` no deberia romper el resto del helper.

Debe:
- convivir con tipos inferidos por variable;
- enriquecer el contexto global;
- sin pretender aun resolver hojas, ids o metadata de archivo.

- [ ] **Step 3: Definir advertencias asociadas**

Ejemplo deseable:
- si el usuario declara `tipo_fuente = "gca2"`, pero no hay mas evidencia, no advertir fuerte;
- si declara `tipo_fuente = "odbc"`, avisar que el termino aprobado es `oracle`.

- [ ] **Step 4: Correr prueba enfocada**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Expected:
- PASS en los casos de trazabilidad

---

## Task 4: Hacer visible `tipo_fuente` en el renderer

**Files:**
- Modify: `R/ai_dataset_profile.R`
- Test: `tests/testthat/test_ai_dataset_profile.R`

- [ ] **Step 1: Agregar una linea breve de contexto al renderer**

Ejemplo de salida:

```text
Fuente declarada por el usuario: gca2.
```

o

```text
Fuente declarada por el usuario: oracle.
```

### Recomendacion

Mantenerlo breve, arriba del resumen por variable o dentro del bloque de advertencias/contexto.

- [ ] **Step 2: No sobrecargar el texto cuando no hay `tipo_fuente`**

Si `tipo_fuente = NULL`, el renderer no deberia inventar una seccion vacia.

- [ ] **Step 3: Correr prueba enfocada**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Expected:
- PASS

---

## Task 5: Verificacion final y documentacion del paso

**Files:**
- Create: `docs/06_desarrollo/fases/2026-05-18_contexto_de_fuente_etapa_1_para_dataset_profile_for_ai.md`
- Modify: `R/ai_dataset_profile.R` solo si hace falta pulido final

- [ ] **Step 1: Agregar ejemplo de uso desde RStudio**

Ejemplos sugeridos:

```r
profile <- profile_dataset_for_ai(
  data = mi_dataset,
  dataset_name = "consulta_personas",
  tipo_fuente = "gca2"
)

cat(render_dataset_profile_for_ai(profile))
```

y

```r
profile <- profile_dataset_for_ai(
  data = mi_dataset,
  dataset_name = "relaciones_laborales",
  tipo_fuente = "oracle"
)
```

- [ ] **Step 2: Correr prueba focalizada**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Expected:
- PASS

- [ ] **Step 3: Correr suite completa**

Run:

```powershell
Rscript tests/testthat.R
```

Expected:
- PASS

- [ ] **Step 4: Documentar cierre del paso**

Registrar:
- que `tipo_fuente` es opcional;
- que la API conserva nombres en espanol;
- que `oracle` reemplaza semanticamente a `odbc`;
- y que el helper sigue siendo util en modo cero-configuracion.

---

## Validation Notes

- no volver obligatorio `tipo_fuente`
- no introducir `archivo_fuente` en esta etapa
- no usar `odbc` como valor aprobado de API
- mantener mensajes y advertencias en espanol
- no acoplar todavia esta etapa a metadata externa por carpeta

## Execution Recommendation

La implementacion deberia arrancar por `Task 1` y `Task 2`, porque fijan el contrato visible y el vocabulario controlado antes de tocar renderer o trazabilidad.
