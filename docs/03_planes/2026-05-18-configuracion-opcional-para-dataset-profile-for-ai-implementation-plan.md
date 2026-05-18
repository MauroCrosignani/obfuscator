# Configuracion Opcional para Dataset Profile for AI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Agregar una configuracion opcional, declarativa y en espanol a `dataset_profile_for_ai()` para permitir overrides puntuales sin perder utilidad en modo cero-configuracion.

**Architecture:** La implementacion debe conservar el flujo actual como camino por defecto y sumar una capa liviana de `config` como override por grupos de columnas. La resolucion final debe distinguir entre heuristica automatica y reglas declaradas por usuario, y dejar la puerta abierta a una futura biblioteca compartida sin introducirla todavia.

**Tech Stack:** R, testthat, helpers actuales en `R/ai_dataset_profile.R`, documentacion en `docs/02_diseno` y `docs/06_desarrollo`

---

## File Structure

### Existing files to modify
- `R/ai_dataset_profile.R`
  - agregar soporte para `config`
  - validar claves y conflictos
  - registrar origen de clasificaciones y reglas aplicadas
- `tests/testthat/test_ai_dataset_profile.R`
  - cobertura de config opcional, precedencia y mensajes
- `docs/06_desarrollo/fases/2026-05-18_interpretacion_semantica_de_faltantes_en_dataset_profile_for_ai.md`
  - solo si hiciera falta referencia cruzada al nuevo enfoque

### New files to create
- `docs/06_desarrollo/fases/2026-05-18_configuracion_opcional_para_dataset_profile_for_ai.md`
  - cierre documental del paso

### Reference files
- `docs/02_diseno/2026-05-18-diseno-de-configuracion-opcional-para-dataset-profile-for-ai.md`
- `R/ai_dataset_profile.R`
- `tests/testthat/test_ai_dataset_profile.R`

---

### Task 1: Fijar el contrato de `config` en tests

**Files:**
- Modify: `tests/testthat/test_ai_dataset_profile.R`
- Reference: `docs/02_diseno/2026-05-18-diseno-de-configuracion-opcional-para-dataset-profile-for-ai.md`

- [ ] **Step 1: Escribir prueba para overrides en espanol**

Agregar una prueba donde:

```r
config <- list(
  faltantes_esperables = c("fecha_hasta"),
  columnas_sensibles = c("diagnostico"),
  columnas_identificatorias = c("correo_contacto"),
  columnas_texto_libre = c("observacion")
)
```

Y verificar que el perfil:

- aplique esas decisiones a esas columnas;
- marque el origen como `declarado_por_usuario`;
- y no requiera que la heuristica acierte para funcionar.

- [ ] **Step 2: Escribir prueba para precedencia sobre heuristica**

Construir un caso donde una columna que por heuristica seria `categorical` pase a `sensitive` o `free_text` por `config`.

Esperar:

- clasificacion final segun `config`;
- y trazabilidad del origen.

- [ ] **Step 3: Escribir prueba para columna inexistente en config**

Usar algo como:

```r
config <- list(columnas_sensibles = c("no_existe"))
```

Esperar:

- advertencia en espanol;
- y que el helper no falle por completo.

- [ ] **Step 4: Escribir prueba para conflicto entre categorias**

Ejemplo:

```r
config <- list(
  columnas_sensibles = c("diagnostico"),
  columnas_identificatorias = c("diagnostico")
)
```

Esperar:

- advertencia o error claro;
- politica definida y testeada sobre como resolver el conflicto.

- [ ] **Step 5: Correr prueba enfocada y verificar que falle**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Expected:
- FAIL en los casos nuevos porque `config` aun no existe

- [ ] **Step 6: Commit**

```bash
git add tests/testthat/test_ai_dataset_profile.R
git commit -m "test: define optional config contract for ai dataset profile"
```

---

### Task 2: Implementar la estructura minima de `config`

**Files:**
- Modify: `R/ai_dataset_profile.R`
- Test: `tests/testthat/test_ai_dataset_profile.R`

- [ ] **Step 1: Agregar el parametro `config = NULL`**

Actualizar la firma de:

```r
profile_dataset_for_ai(
  data,
  dataset_name = NULL,
  config = NULL,
  max_levels = 12,
  top_n = 10,
  round_digits = 2
)
```

- [ ] **Step 2: Definir claves aceptadas**

Implementar soporte para:

- `faltantes_esperables`
- `columnas_sensibles`
- `columnas_identificatorias`
- `columnas_texto_libre`

Todas deben aceptar vectores de nombres de columnas.

- [ ] **Step 3: Normalizar y validar `config`**

Crear helpers chicos, por ejemplo:

- `ai_profile_normalize_config()`
- `ai_profile_validate_config()`

Responsabilidades:

- completar listas faltantes con vectores vacios;
- validar que las claves sean conocidas;
- producir advertencias legibles en espanol.

- [ ] **Step 4: Correr prueba enfocada**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Expected:
- algunas pruebas nuevas siguen fallando, pero la estructura de `config` ya existe

- [ ] **Step 5: Commit**

```bash
git add R/ai_dataset_profile.R tests/testthat/test_ai_dataset_profile.R
git commit -m "feat: add optional config scaffolding for ai profiles"
```

---

### Task 3: Aplicar overrides y registrar precedencia

**Files:**
- Modify: `R/ai_dataset_profile.R`
- Test: `tests/testthat/test_ai_dataset_profile.R`

- [ ] **Step 1: Implementar resolucion de reglas declaradas**

Agregar una capa de overrides que permita:

- forzar `role_guess = sensitive`
- forzar `role_guess = identifier`
- forzar `inferred_type = free_text` cuando aplique
- forzar `missingness_hint = expected`

- [ ] **Step 2: Registrar origen de la clasificacion**

Cada variable deberia poder exponer algo como:

- `classification_source = "inferred_automatically"`
- `classification_source = "declared_by_user"`

Y, si aplica, una lista como:

- `applied_rules = c("faltantes_esperables")`

- [ ] **Step 3: Resolver conflictos de precedencia**

Implementar la politica aprobada:

1. regla explicita del usuario
2. futura biblioteca compartida
3. heuristica automatica

En esta fase solo se implementa el punto 1 sobre el 3.

- [ ] **Step 4: Ajustar renderer o metadata para hacer visible el origen**

No hace falta sobrecargar el texto principal, pero el perfil deberia dejar disponible el origen por variable y una advertencia global tipo:

- `Se aplicaron reglas declaradas por usuario para: fecha_hasta, diagnostico, correo_contacto.`

- [ ] **Step 5: Correr prueba enfocada**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Expected:
- PASS en los casos de precedencia y origen

- [ ] **Step 6: Commit**

```bash
git add R/ai_dataset_profile.R tests/testthat/test_ai_dataset_profile.R
git commit -m "feat: apply user-declared rules to ai dataset profiles"
```

---

### Task 4: Endurecer validaciones y mensajes para terceros

**Files:**
- Modify: `R/ai_dataset_profile.R`
- Test: `tests/testthat/test_ai_dataset_profile.R`

- [ ] **Step 1: Definir politica para columnas inexistentes**

Elegir e implementar una de estas dos:

- advertencia y continuar;
- o error duro si la configuracion es claramente invalida.

Recomendacion:

- advertencia y continuar, para mantener baja friccion.

- [ ] **Step 2: Definir politica para conflictos**

Ejemplo:

- una columna aparece en `columnas_sensibles` y `columnas_identificatorias`

Recomendacion:

- priorizar la categoria mas restrictiva;
- emitir advertencia clara.

- [ ] **Step 3: Mantener mensajes de validacion en espanol**

Ejemplos deseables:

- `La columna 'no_existe' fue declarada en config pero no esta presente en el dataset.`
- `La columna 'diagnostico' aparece en categorias incompatibles; se prioriza 'columnas_identificatorias'.`

- [ ] **Step 4: Correr prueba enfocada**

Run:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Expected:
- PASS

- [ ] **Step 5: Commit**

```bash
git add R/ai_dataset_profile.R tests/testthat/test_ai_dataset_profile.R
git commit -m "feat: validate optional config for ai dataset profiles"
```

---

### Task 5: Cierre de verificacion y documentacion

**Files:**
- Modify: `R/ai_dataset_profile.R` (solo si hace falta pulido final)
- Create: `docs/06_desarrollo/fases/2026-05-18_configuracion_opcional_para_dataset_profile_for_ai.md`
- Reference: `docs/02_diseno/2026-05-18-diseno-de-configuracion-opcional-para-dataset-profile-for-ai.md`

- [ ] **Step 1: Agregar ejemplo de uso desde RStudio**

Ejemplo sugerido:

```r
config_perfil_ia <- list(
  faltantes_esperables = c("fecha_hasta"),
  columnas_sensibles = c("diagnostico"),
  columnas_identificatorias = c("correo_contacto"),
  columnas_texto_libre = c("observacion")
)

profile <- profile_dataset_for_ai(
  data = mi_dataset,
  dataset_name = "mi_dataset",
  config = config_perfil_ia
)

cat(render_dataset_profile_for_ai(profile))
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

- que `config` sigue siendo opcional;
- que la herramienta conserva valor en cero-configuracion;
- y que ahora admite overrides legibles en espanol.

- [ ] **Step 5: Commit**

```bash
git add R/ai_dataset_profile.R tests/testthat/test_ai_dataset_profile.R docs/06_desarrollo/fases/2026-05-18_configuracion_opcional_para_dataset_profile_for_ai.md
git commit -m "docs: capture optional config support for ai dataset profiles"
```

---

## Validation Notes

- mantener la utilidad del helper sin `config`
- no introducir claves en ingles en la API principal de configuracion
- no acoplar todavia esta funcionalidad a biblioteca compartida externa
- evitar que la configuracion obligue a revisar columna por columna para ser util
- priorizar mensajes y advertencias en espanol

## Execution Recommendation

La implementacion deberia arrancar por `Task 1` y `Task 2`, porque fijan el contrato y la estructura de `config` antes de discutir precedencia, conflictos y visibilidad de reglas aplicadas.
