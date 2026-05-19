# Resumen de como interfaz amigable para perfilado IA Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Agregar `resumen_de()` como interfaz publica, unica y en espanol para el helper de perfilado seguro para IA, manteniendo el core tecnico actual como capa avanzada.

**Architecture:** La implementacion debe introducir un wrapper liviano sobre `profile_dataset_for_ai()` y `render_dataset_profile_for_ai()`, sin duplicar logica ni cambiar contratos internos que ya estan cubiertos por tests. La nueva superficie publica debe priorizar facilidad de uso, traduciendo nombres y valores amigables al modelo tecnico vigente.

**Tech Stack:** R, testthat, helper actual en `R/ai_dataset_profile.R`, documentacion operativa en `docs/03_planes`

---

## File Structure

### Existing files to modify
- `R/ai_dataset_profile.R`
  - agregar `resumen_de()`
  - validar parametros en espanol
  - traducir `modo` y `salida`
- `NAMESPACE`
  - exportar `resumen_de()` como interfaz publica del paquete
- `tests/testthat/test_ai_dataset_profile.R`
  - cubrir contrato de `resumen_de()`
- `docs/03_planes/2026-05-18_guia-operativa-profile_dataset_for_ai.md`
  - actualizar el camino recomendado de uso
- `README.md`
  - mencionar `resumen_de()` como interfaz amigable
- `docs/README.md`
  - indexar la nueva recomendacion de uso

### New files to create
- `docs/06_desarrollo/fases/2026-05-18_implementacion_de_resumen_de_como_interfaz_amigable.md`
  - cierre documental del paso, una vez implementado

### Reference files
- `docs/02_diseno/2026-05-18-diseno-de-resumen_de-como-interfaz-amigable-para-perfilado-ia.md`
- `R/ai_dataset_profile.R`
- `tests/testthat/test_ai_dataset_profile.R`
- `docs/03_planes/2026-05-18_guia-operativa-profile_dataset_for_ai.md`

---

### Task 1: Fijar el contrato publico de `resumen_de()` en tests

**Files:**
- Modify: `tests/testthat/test_ai_dataset_profile.R`
- Reference: `docs/02_diseno/2026-05-18-diseno-de-resumen_de-como-interfaz-amigable-para-perfilado-ia.md`

- [ ] **Step 1: Escribir prueba para salida de texto por defecto**

Agregar una prueba donde:

```r
resultado <- resumen_de(iris)
```

Esperar:

- que `resultado` sea `character(1)` o un bloque de texto no vacio;
- y que no requiera llamadas manuales a `render_dataset_profile_for_ai()`.

- [ ] **Step 2: Escribir prueba para `nombre_dataset`**

Agregar una prueba donde:

```r
resultado <- resumen_de(iris, nombre_dataset = "iris_demo")
```

Esperar:

- que el texto refleje `iris_demo`;
- y que el wrapper preserve el mapeo `nombre_dataset -> dataset_name`.

- [ ] **Step 3: Escribir prueba para `salida = "estructura"`**

Agregar una prueba donde:

```r
perfil <- resumen_de(iris, salida = "estructura")
```

Esperar:

- que el resultado sea una lista estructurada equivalente al perfil del core;
- y que contenga los campos principales ya vigentes.

- [ ] **Step 4: Escribir prueba para traduccion de `modo`**

Agregar pruebas para:

```r
resumen_de(iris, modo = "normal")
resumen_de(iris, modo = "conservador")
```

Esperar:

- que ambos caminos funcionen;
- y que la traduccion interna no cambie el contrato del renderer existente.

- [ ] **Step 5: Escribir pruebas de forwarding real**

Agregar al menos un caso por cada capacidad avanzada:

- `config`
- `tipo_fuente`
- `archivo_fuente`
- `metadata_dir`

Esperar que `resumen_de(..., salida = "estructura")` conserve en campos clave el mismo comportamiento que `profile_dataset_for_ai(...)`.

- [ ] **Step 6: Escribir prueba para `data` invalido**

Caso:

```r
resumen_de(1:3)
```

Esperar:

- error claro en espanol;
- alineado con la validacion del core.

- [ ] **Step 7: Escribir prueba para valores invalidos**

Casos:

```r
resumen_de(iris, modo = "otra_cosa")
resumen_de(iris, salida = "otra_cosa")
```

Esperar:

- mensajes en espanol;
- listado claro de valores aceptados.

- [ ] **Step 8: Correr prueba enfocada y verificar que falle**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Expected:
- FAIL en los casos nuevos porque `resumen_de()` aun no existe

- [ ] **Step 9: Commit**

```bash
git add tests/testthat/test_ai_dataset_profile.R
git commit -m "test: define public contract for resumen_de"
```

---

### Task 2: Implementar `resumen_de()` como wrapper liviano

**Files:**
- Modify: `R/ai_dataset_profile.R`
- Modify: `NAMESPACE`
- Test: `tests/testthat/test_ai_dataset_profile.R`

- [ ] **Step 1: Agregar `resumen_de()` al helper**

Implementar la firma:

```r
resumen_de(
  data,
  nombre_dataset = NULL,
  config = NULL,
  tipo_fuente = NULL,
  archivo_fuente = NULL,
  metadata_dir = NULL,
  modo = "normal",
  salida = "texto"
)
```

- [ ] **Step 2: Exportar la nueva interfaz publica**

Actualizar `NAMESPACE` para exponer `resumen_de()` en instalaciones del paquete.

- [ ] **Step 3: Validar parametros visibles en espanol**

Implementar validacion explicita para:

- `modo`
- `salida`

Mensajes esperados:

- breves;
- en espanol;
- accionables.

- [ ] **Step 4: Traducir `modo` al renderer actual**

Mapear:

- `normal` -> `compact`
- `conservador` -> `conservative`

Sin cambiar la API interna existente.

- [ ] **Step 5: Reenviar `nombre_dataset` y capacidades avanzadas**

Preservar sin perdida:

- `nombre_dataset -> dataset_name`
- `config`
- `tipo_fuente`
- `archivo_fuente`
- `metadata_dir`

- [ ] **Step 6: Resolver `salida`**

Implementar:

- `salida = "texto"` -> `render_dataset_profile_for_ai(profile, mode = ...)`
- `salida = "estructura"` -> devolver `profile`

- [ ] **Step 7: Mantener el core tecnico intacto**

No mover ni renombrar:

- `profile_dataset_for_ai()`
- `render_dataset_profile_for_ai()`

`resumen_de()` debe limitarse a orquestar.

- [ ] **Step 8: Correr prueba enfocada**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Expected:
- PASS en los casos nuevos de `resumen_de()`

- [ ] **Step 9: Commit**

```bash
git add R/ai_dataset_profile.R NAMESPACE tests/testthat/test_ai_dataset_profile.R
git commit -m "feat: add resumen_de as friendly ai profile wrapper"
```

---

### Task 3: Actualizar la documentacion operativa y el camino recomendado

**Files:**
- Modify: `docs/03_planes/2026-05-18_guia-operativa-profile_dataset_for_ai.md`
- Modify: `README.md`
- Modify: `docs/README.md`
- Reference: `docs/02_diseno/2026-05-18-diseno-de-resumen_de-como-interfaz-amigable-para-perfilado-ia.md`

- [ ] **Step 1: Actualizar la guia operativa**

Agregar una seccion al principio explicando que:

- `resumen_de()` pasa a ser el camino recomendado;
- `profile_dataset_for_ai()` y `render_dataset_profile_for_ai()` quedan como capa avanzada.

- [ ] **Step 2: Agregar ejemplos minimos de uso**

Incluir:

```r
resumen_de(mi_dataset)
resumen_de(mi_dataset, modo = "conservador")
resumen_de(mi_dataset, salida = "estructura")
```

- [ ] **Step 3: Ajustar indices generales**

Actualizar:

- `README.md`
- `docs/README.md`

para que mencionen la nueva interfaz publica sin borrar referencias utiles al core tecnico.

- [ ] **Step 4: Alinear la carga explicita de `iris`**

Corregir ejemplos donde corresponda para respetar el protocolo local de carga real:

```r
library(datasets)
data(iris)
```

antes de usar `iris`.

- [ ] **Step 5: Verificar consistencia documental**

Buscar referencias desactualizadas con algo como:

```powershell
rg -n "profile_dataset_for_ai\\(|render_dataset_profile_for_ai\\(" README.md docs
```

Expected:
- referencias tecnicas correctas;
- y al menos una referencia clara a `resumen_de()` como camino feliz.

- [ ] **Step 6: Commit**

```bash
git add docs/03_planes/2026-05-18_guia-operativa-profile_dataset_for_ai.md README.md docs/README.md
git commit -m "docs: recommend resumen_de as primary ai profile entrypoint"
```

---

### Task 4: Verificacion final y cierre del paso

**Files:**
- Modify: `docs/06_desarrollo/fases/2026-05-18_implementacion_de_resumen_de_como_interfaz_amigable.md`
- Verify: `R/ai_dataset_profile.R`
- Verify: `tests/testthat/test_ai_dataset_profile.R`

- [ ] **Step 1: Correr la prueba enfocada**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Expected:
- PASS

- [ ] **Step 2: Correr la suite completa**

Run:

```powershell
Rscript tests/testthat.R
```

Expected:
- PASS sin regresiones

- [ ] **Step 3: Probar ejemplos minimos**

Run:

```powershell
Rscript -e "library(datasets); data(iris); source('R/obfuscator_core.R'); cat(resumen_de(iris))"
Rscript -e "library(datasets); data(iris); source('R/obfuscator_core.R'); str(resumen_de(iris, salida = 'estructura'), max.level = 1)"
Rscript -e "ns <- parseNamespaceFile('ObfuscatoR', '.'); stopifnot('resumen_de' %in% ns$exports)"
```

Expected:
- texto util en el primer caso;
- lista estructurada en el segundo.
- `resumen_de` exportada en `NAMESPACE` como API publica del paquete.

- [ ] **Step 4: Documentar el cierre**

Crear el documento de fase con:

- archivos cambiados;
- razon del cambio;
- comandos de verificacion;
- resultado;
- y siguiente paso recomendado.

- [ ] **Step 5: Commit**

```bash
git add docs/06_desarrollo/fases/2026-05-18_implementacion_de_resumen_de_como_interfaz_amigable.md
git commit -m "docs: record resumen_de implementation step closure"
```
