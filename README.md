# ObfuscatoR

[![Checks](https://github.com/MauroCrosignani/obfuscator/actions/workflows/checks.yml/badge.svg)](https://github.com/MauroCrosignani/obfuscator/actions/workflows/checks.yml)

ObfuscatoR es un paquete y script en `R` pensado para equipos hispanoparlantes que necesitan compartir datos ofuscados con herramientas de IA sin exponer informacion sensible.

La prioridad de UX es simple:

- mensajes claros en espanol
- configuracion explicita pero amigable
- compatibilidad con `source("obfuscator.R")`
- trazabilidad para auditoria

## Que hace

- Ofusca identificadores con prefijos evidentes como `999`.
- Reordena fechas preservando el conjunto de valores.
- Permuta variables categoricas preservando frecuencias.
- Transforma columnas numericas con modos configurables.
- Permite reglas de consistencia entre columnas.
- Permite aplicar `k-anonymity` de forma opcional y parametrizable.
- Adjunta un log de auditoria con configuracion, roles detectados y reglas aplicadas.

## Estructura de uso

Puedes usarlo de dos maneras:

1. Como script compatible con flujos existentes.
2. Como paquete con codigo organizado en `R/`.
3. Como app Shiny con interfaz grafica.

## App Shiny

La app permite:

- cargar un CSV, Excel (`.xls`, `.xlsx`) o RDS
- seleccionar un `data.frame` o tibble desde el entorno global
- detectar automaticamente variables candidatas a identificacion
- revisar visualmente tipos de variables
- mover variables entre zonas con drag and drop
- **Persistencia de Clasificación**: Guarda y carga la asignación de roles mediante plantillas JSON basadas en el esquema de datos (hash).
- **Asistente Proactivo**: Sugiere roles mediante *fuzzy matching* (distancia de Levenshtein) ante cambios menores en los nombres de las columnas.
- **Accesibilidad (WCAG AA)**: Colores y contraste optimizados para cumplir con el ratio 4.5:1, con indicadores visuales dobles (color + icono).
- ejecutar la ofuscacion y descargar el resultado

En la carga de CSV y Excel, la deteccion de tipos usa `guess_max = 100000` para mejorar la inferencia de columnas en archivos grandes o heterogeneos.

La carga por navegador tiene ahora un limite aumentado a 300 MB. Para archivos mas grandes o entornos con restricciones del navegador, conviene leer el dataset en R y elegirlo desde el entorno global dentro de la app.

Para lanzarla desde la raiz del proyecto:

```r
source("R/obfuscator_core.R")
source("R/shiny_app.R")
run_obfuscator_app()
```

O directamente:

```sh
Rscript -e "source('R/obfuscator_core.R'); source('R/shiny_app.R'); run_obfuscator_app()"
```

## Uso rapido

```r
source("obfuscator.R")

cfg <- obfuscator_config(
  id_cols = c("ID_EMPRESA"),
  seed = 123,
  numeric_mode = "preserve_rank",
  consistency_rules = list(
    list(
      type = "ordered",
      lower = "FECHA_INICIO",
      upper = "FECHA_FIN",
      allow_equal = TRUE
    )
  )
)

ofuscado <- obfuscate_dataset(mi_tabla, config = cfg)
log <- attr(ofuscado, "obfuscator_log")
```

## Roles de columnas

Si quieres control total, puedes declarar roles explicitamente:

```r
cfg <- obfuscator_config(
  col_roles = list(
    id = c("ID_EMPRESA", "DOCUMENTO"),
    date = c("FECHA_INICIO", "FECHA_FIN"),
    categorical = c("ESTADO", "SEGMENTO"),
    numeric = c("MONTO", "SALDO")
  )
)
```

## Modelo de privacidad opcional

Si necesitas una capa adicional de anonimizacion, puedes activar `k-anonymity`.

Ejemplo:

```r
cfg <- obfuscator_config(
  privacy_model = list(
    type = "k_anonymity",
    k = 5,
    quasi_identifiers = c("edad", "sexo", "fecha_nacimiento"),
    suppression = "rows"
  )
)
```

Parametros principales:

- `type = "k_anonymity"`: activa el modelo.
- `k`: tamano minimo de cada grupo equivalente.
- `quasi_identifiers`: columnas que se consideran sensibles para reidentificacion.
- `suppression`: `rows` elimina filas residuales si no alcanza con generalizar; `none` conserva todas las filas.
- `hierarchies`: opcional, permite definir pasos de generalizacion por columna. Soporta tanto niveles predefinidos como **Jerarquías Visuales Personalizadas**.

### Jerarquías Visuales (Visual Tree UI)

La App Shiny incluye un editor visual potente para variables categóricas y fechas:

1.  **Configuración**: Haz clic en el icono de jerarquía en las filas de variables categóricas/fechas.
2.  **Agrupación**: Arrastra valores para agruparlos o usa la selección múltiple para crear carpetas instantáneamente.
3.  **Recursión**: Las jerarquías se aplican de forma incremental. Puedes agrupar grupos ya creados para definir multiniveles.
4.  **Persistencia**: Las jerarquías se guardan automáticamente en tus plantillas JSON.

Jerarquias predefinidas (strings):

- numericas: `identity`, `interval_5`, `interval_10`, `interval_20`, `global`
- fechas: `identity`, `month`, `quarter`, `year`
- categoricas: `identity`, `rare_2`, `rare_5`, `rare_10`, `global`

El log incluye un `privacy_report` con:

- riesgo antes y despues
- pasos de generalizacion aplicados
- cantidad de filas suprimidas
- confirmacion de si el criterio `k` quedo satisfecho

Si no lo haces, ObfuscatoR intenta inferirlos.

## Modos numericos

`numeric_mode` acepta:

- `range_random`: preserva signo, rango y tipo.
- `preserve_rank`: intenta conservar el orden relativo.
- `permute`: reordena los valores observados.

Tambien puedes definir un modo por columna:

```r
cfg <- obfuscator_config(
  numeric_mode = "range_random",
  numeric_modes = list(
    SCORE = "preserve_rank",
    MONTO = "range_random"
  )
)
```

## Reglas de consistencia

Regla soportada actualmente:

- `ordered`: asegura que `lower <= upper` por fila. Si no se cumple, intercambia ambos valores en esa fila.

Ejemplo:

```r
cfg <- obfuscator_config(
  consistency_rules = list(
    list(type = "ordered", lower = "MINIMO", upper = "MAXIMO", allow_equal = TRUE)
  )
)
```

## CSV por linea de comandos

```sh
Rscript obfuscator.R datos_entrada.csv datos_salida.csv
```

## Tests

Desde la raiz del proyecto:

```sh
Rscript tests/testthat.R
```
