# Guía operativa vigente del helper de perfilado seguro para IA

## Propósito

Concentrar en un solo lugar la interfaz vigente del helper de perfilado seguro para IA, para no depender de notas dispersas entre diseños, planes e hitos de implementación.

## Ubicaciones principales

- implementación:
  - [R/ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R)
- tests:
  - [test_ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_ai_dataset_profile.R)
- cierre del bloque de contexto de fuente y metadata:
  - [2026-05-18_cierre_del_bloque_resolvedor_de_fuente_y_metadata_para_perfilado_ia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-18_cierre_del_bloque_resolvedor_de_fuente_y_metadata_para_perfilado_ia.md)
- plan maestro de implementación ya ejecutado para este bloque:
  - [2026-05-18-resolvedor-de-fuente-y-metadata-para-perfilado-ia-implementation-plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-18-resolvedor-de-fuente-y-metadata-para-perfilado-ia-implementation-plan.md)

## Camino recomendado de uso

La interfaz recomendada para uso cotidiano desde RStudio ahora es:

```r
library(datasets)
data(iris)
source("c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R")

cat(resumen_de(iris))
```

Si necesitas una salida mas prudente:

```r
cat(resumen_de(iris, modo = "conservador"))
```

Si necesitas inspeccionar el objeto estructurado:

```r
perfil <- resumen_de(iris, salida = "estructura")
str(perfil, max.level = 1)
```

Si quieres ejemplos listos para correr desde RStudio:

- [demo_resumen_de_minimo.R](c:/Users/mcros/Documents/obfuscator/scripts/demo_resumen_de_minimo.R)
- [demo_resumen_de_config.R](c:/Users/mcros/Documents/obfuscator/scripts/demo_resumen_de_config.R)
- [2026-05-19_guia-rapida-de-adopcion-de-resumen_de-desde-rstudio.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-19_guia-rapida-de-adopcion-de-resumen_de-desde-rstudio.md)

## Capas vigentes

### 1. Interfaz amigable

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

### 2. Core tecnico

`resumen_de()` se apoya sobre estas dos funciones, que siguen siendo utiles para pruebas, depuracion y uso avanzado.

## Mejoras semanticas vigentes

Hoy el helper ya no se limita a resumir por tipo importado. Tambien preserva mejor parte de la semantica estructural que hace util a `glimpse()`, pero sin exponer muestras crudas.

Esto incluye:

- distincion entre `numerica entera` y `numerica decimal`;
- deteccion de categorias compuestas cuando una misma celda contiene varias etiquetas separadas;
- mejor tratamiento de `character` nominales de alta cardinalidad para no caer innecesariamente en `unknown`;
- descripcion estructural de `list-columns` como colecciones por fila;
- diferenciacion entre `texto libre` y `etiqueta nominal de entidad` cuando la evidencia alcanza;
- advertencias mas precisas por familia de riesgo en vez de una sola advertencia demasiado general.

## Firmas vigentes del core

### 1. Perfil estructurado

```r
profile_dataset_for_ai(
  data,
  dataset_name = NULL,
  config = NULL,
  tipo_fuente = NULL,
  archivo_fuente = NULL,
  metadata_dir = NULL,
  max_levels = 12,
  top_n = 10,
  round_digits = 2
)
```

### 2. Render listo para pegar en una IA

```r
render_dataset_profile_for_ai(
  profile,
  mode = "compact"
)
```

## Parámetros vigentes

### `resumen_de()`

#### Obligatorio

- `data`
  - debe ser `data.frame` o `tibble`.

#### Opcionales

- `nombre_dataset`
  - nombre visible del dataset.
  - si queda en `NULL`, usa el nombre del objeto cuando sea posible.
- `config`
  - misma configuracion declarativa en espanol que ya usa el core.
- `tipo_fuente`
  - pista semantica liviana sobre el origen.
- `archivo_fuente`
  - artefacto de origen para enriquecer contexto.
- `metadata_dir`
  - carpeta con fichas JSON por fuente.
- `modo`
  - valores vigentes:
    - `"normal"`
    - `"conservador"`
- `salida`
  - valores vigentes:
    - `"texto"`
    - `"estructura"`

### `profile_dataset_for_ai()`

#### Obligatorio

- `data`
  - debe ser `data.frame` o `tibble`.

#### Opcionales

- `dataset_name`
  - nombre visible del dataset en la salida.
- `config`
  - lista declarativa en español para overrides puntuales.
- `tipo_fuente`
  - pista semántica liviana sobre el origen.
- `archivo_fuente`
  - ruta a un artefacto de origen, útil para detectar contexto `GCA.net` o `GCA2`.
- `metadata_dir`
  - carpeta con fichas JSON por fuente.
- `max_levels`
  - cantidad máxima de niveles categóricos que se listan completos antes de resumir.
- `top_n`
  - cantidad máxima de niveles principales cuando una categórica tiene muchos valores.
- `round_digits`
  - redondeo para rangos numéricos.

### `render_dataset_profile_for_ai()`

- `profile`
  - objeto devuelto por `profile_dataset_for_ai()`.
- `mode`
  - valores vigentes:
    - `"compact"`
    - `"conservative"`

## Valores vigentes de `tipo_fuente`

Valores aceptados hoy:

- `"gca"`
- `"gca2"`
- `"oracle"`
- `"excel"`
- `"csv"`
- `"desconocida"`

Notas:

- `odbc` no es un valor aprobado de API.
- si se usa `tipo_fuente = "odbc"`, el helper advierte y sugiere `oracle`.
- `tipo_fuente` sigue siendo opcional: el helper debe funcionar igual sin declararlo.

## Estructura vigente de `config`

La primera versión soporta estas claves:

- `faltantes_esperables`
- `columnas_sensibles`
- `columnas_identificatorias`
- `columnas_texto_libre`

Ejemplo:

```r
config_perfil_ia <- list(
  faltantes_esperables = c("fecha_hasta"),
  columnas_sensibles = c("diagnostico"),
  columnas_identificatorias = c("correo_contacto"),
  columnas_texto_libre = c("observacion")
)
```

## Qué hace hoy con `archivo_fuente`

### Soportado hoy

- si recibe una planilla `GCA.net` con firma reconocible, puede construir contexto de origen con confianza media;
- si recibe una planilla `GCA2`, puede detectar `source_id` como `gca2:<id_consulta>` con confianza alta;
- si la evidencia del archivo no alcanza, degrada con advertencia y no inventa metadata fuerte.

### No resuelto todavía

- detección automática de `oracle` desde conexiones vivas;
- análisis del script activo para reconstruir la línea de carga;
- verificación completa de carga parcial en libros con varias hojas de datos;
- resolución específica de `.csv` derivados de `GCA2` por volumen.

## Qué hace hoy con `metadata_dir`

- carga fichas JSON válidas por fuente;
- intenta match conservador por `source_id`;
- si no hay `source_id` fuerte, intenta por `aliases` y `display_name`;
- si el match es ambiguo, no aplica metadata automáticamente;
- compara columnas esperadas contra el objeto actual con matching:
  - exacto;
  - normalizado en estilo equivalente a `clean_names()`.

## Alertas vigentes respecto del origen

Hoy el helper puede señalar, entre otras, estas situaciones:

- fecha o fecha-hora esperada que sigue llegando como `character`;
- identificador esperado que sigue como `numeric` o `integer`;
- faltantes altos esperables;
- faltantes altos inesperados;
- columnas esperadas no resueltas por nombre exacto o normalizado.

## Semantica vigente por familia de columna

### Numericas

- distinguen entre `integer` y `double`;
- se renderizan como `numerica entera` o `numerica decimal`;
- mantienen rango aproximado y faltantes.

### Categoricas

- si son cortas y simples, listan valores observados;
- si tienen alta cardinalidad, pasan a `niveles observados` y `top niveles`;
- si contienen varias etiquetas en una misma celda, se tratan como `categorica compuesta` y evitan render engañoso por comas internas.

### Etiquetas de entidad y texto libre

- nombres o etiquetas nominales de entidad pueden clasificarse aparte como `etiqueta nominal de entidad`;
- el texto libre abierto sigue sin exponer ejemplos reales;
- ambas familias dejan advertencias distintas para no exagerar ni ocultar riesgo.

### `list-columns`

- ya no quedan como `unknown` por defecto;
- se describen como `columna lista`;
- cuando la evidencia alcanza, informan tipo de elemento y cardinalidad aproximada por fila.

## Ejemplos de uso vigentes

### Uso simple

```r
library(datasets)
data(iris)
source("c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R")

cat(resumen_de(iris))
```

### Uso avanzado con configuración local

```r
source("c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R")

config_perfil_ia <- list(
  faltantes_esperables = c("fecha_hasta"),
  columnas_sensibles = c("diagnostico"),
  columnas_identificatorias = c("correo_contacto"),
  columnas_texto_libre = c("observacion")
)

cat(resumen_de(
  data = mi_dataset,
  nombre_dataset = "mi_dataset",
  config = config_perfil_ia
))
```

### Uso avanzado con contexto de fuente

```r
source("c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R")

cat(resumen_de(
  data = mi_dataset,
  nombre_dataset = "consulta_18631",
  tipo_fuente = "gca2",
  archivo_fuente = "c:/ruta/consulta_18631_123456.xlsx",
  metadata_dir = "c:/ruta/metadata_fuentes",
  modo = "conservador"
))
```

## Criterio operativo recomendado

Orden de adopción sugerido:

1. usar el helper sin configuración;
2. empezar por `resumen_de()` antes de bajar al core tecnico;
3. agregar `config` solo cuando haga falta corregir o enriquecer heurísticas;
4. usar `tipo_fuente` cuando el origen sea conocido;
5. sumar `archivo_fuente` si el artefacto de origen agrega contexto útil;
6. usar `metadata_dir` cuando exista una biblioteca de fichas suficientemente confiable.

## Mantenimiento de esta guía

Actualizar este documento cuando cambie cualquiera de estos puntos:

- firma de `resumen_de()`;
- firma de `profile_dataset_for_ai()`;
- firma de `render_dataset_profile_for_ai()`;
- claves soportadas en `config`;
- valores aceptados de `tipo_fuente`;
- semántica de `archivo_fuente`;
- comportamiento de `metadata_dir`;
- o estrategia de render (`compact` / `conservative`).
