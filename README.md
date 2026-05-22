# ObfuscatoR

[![Checks](https://github.com/MauroCrosignani/obfuscator/actions/workflows/checks.yml/badge.svg)](https://github.com/MauroCrosignani/obfuscator/actions/workflows/checks.yml)

ObfuscatoR es una herramienta en `R` para preparar datasets sensibles para su liberacion controlada a terceros. Su prioridad es reducir riesgo de reidentificacion, dejar evidencia auditable y bloquear exportaciones cuando la salida no es defendible.

La IA se trata como un tercero mas. El objetivo del proyecto no es "pasar datos a modelos" con una capa cosmetica de ofuscacion, sino sostener una decision de liberacion segura cuando sea posible y explicar por que se bloquea cuando no lo es.

Si necesitas llevarlo a GitLab corporativo o a un entorno con restricciones parciales de internet, el repositorio incluye tambien [README_gitlab.md](c:/Users/mcros/Documents/obfuscator/README_gitlab.md) como variante orientada a ese despliegue.

## Prioridades del producto

- mensajes claros en espanol
- configuracion explicita pero usable
- compatibilidad con script, paquete y app Shiny
- trazabilidad y auditabilidad
- conservadurismo frente a terceros

## Dos frentes actuales del proyecto

Hoy el repo tiene dos frentes practicos complementarios:

1. el flujo principal de liberacion controlada en la app Shiny;
2. un helper interno de perfilado seguro para IA pensado para usar desde RStudio sin pasar muestras crudas del dataset.

La guia operativa vigente del helper de perfilado seguro para IA esta en:

- [2026-05-18_guia-operativa-profile_dataset_for_ai.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-18_guia-operativa-profile_dataset_for_ai.md)

## Que hace hoy

- ofusca identificadores con scrambling o cifrado reversible endurecido
- permuta fechas preservando estructura operativa
- transforma variables categoricas y numericas
- permite reglas de consistencia
- soporta `k-anonymity` con jerarquias configurables
- mantiene un estado explicito de liberacion en la app
- bloquea exportacion externa salvo estado `Liberable`
- muestra reportes legibles de liberacion o no liberacion

## Lo que no promete

- no promete que todo dataset sensible pueda volverse compartible
- no promete que cumplir `k-anonymity` alcance por si solo para liberar
- no promete que generar codigo R equivalga a aprobar una liberacion externa
- no promete un camino mas permisivo para IA que para otros terceros

## Formas de uso

Puedes usarlo de tres maneras:

1. como script compatible con flujos existentes
2. como paquete con codigo organizado en `R/`
3. como app Shiny con interfaz grafica

## ObfuscatoR Studio

La app Shiny ofrece:

- carga de CSV, Excel (`.xls`, `.xlsx`) o RDS
- seleccion de `data.frame` o tibble desde el entorno global
- clasificacion visual de variables
- tabla principal por variable como mecanismo dominante de clasificacion
- modo heredado de drag and drop solo como apoyo experimental
- persistencia de clasificacion con plantillas JSON basadas en esquema
- sugerencias por fuzzy matching para recuperacion por nombres parecidos
- editor visual de jerarquias
- resumen de auditoria legible
- exportacion CSV solo cuando el estado es `Liberable`

En la carga de CSV y Excel, la deteccion de tipos usa `guess_max = 100000` para mejorar la inferencia en archivos grandes o heterogeneos.

La carga por navegador tiene un limite configurado de 300 MB. Para archivos mas grandes o navegadores restringidos, conviene leer el dataset en R y elegirlo desde el entorno global dentro de la app.

## App Shiny

Para lanzarla desde la raiz del proyecto:

```r
library(datasets)
data(iris)
source("R/obfuscator_core.R")
source("R/shiny_app.R")
run_obfuscator_app()
```

O por linea de comandos:

```sh
Rscript -e "library(datasets); data(iris); source('R/obfuscator_core.R'); source('R/shiny_app.R'); run_obfuscator_app()"
```

## Perfilado seguro para IA

Ademas del flujo principal de la app, el repo incluye un helper para describir datasets de forma util y prudente antes de darle contexto a una IA.

Camino recomendado:

- `resumen_de()`

Capa tecnica vigente:

- `profile_dataset_for_ai()`
- `render_dataset_profile_for_ai()`

Ubicaciones:

- implementacion:
  - [R/ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R)
- tests:
  - [test_ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_ai_dataset_profile.R)
- guia operativa:
  - [2026-05-18_guia-operativa-profile_dataset_for_ai.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-18_guia-operativa-profile_dataset_for_ai.md)

Uso minimo:

```r
library(datasets)
data(iris)
source("R/obfuscator_core.R")

cat(resumen_de(iris))
```

Semantica vigente mas importante:

- conserva en el texto visible el `tipo importado` exacto y la `interpretacion semantica` de cada variable;
- entrecomilla los valores categoricos visibles para evitar ambiguedad sobre espacios o delimitacion;
- distingue `numerica entera` de `numerica decimal`;
- detecta `categorica compuesta` cuando una celda contiene varias etiquetas;
- evita caer tan facil en `unknown` para columnas nominales de alta cardinalidad;
- describe `list-columns` como colecciones por fila;
- separa mejor `texto libre` de `etiqueta nominal de entidad`, incluyendo nombres institucionales repetibles;
- y puede interpretar como `fecha` una `POSIXct` cuya hora no aporta informacion sustantiva.

Patron visible actual del renderer:

- `importada como <tipo>; interpretada como <semantica>; ...`

Ejemplos esperables:

- `height: importada como integer; interpretada como numerica entera; ...`
- `sex: importada como character; interpretada como categorica; valores observados: "female", "male", ...`
- `films: importada como list; interpretada como columna lista; ...`
- `FECHA_DESDE: importada como POSIXct; interpretada como fecha; ...`

Ejemplos listos para correr:

- [demo_resumen_de_minimo.R](c:/Users/mcros/Documents/obfuscator/scripts/demo_resumen_de_minimo.R)
- [demo_resumen_de_config.R](c:/Users/mcros/Documents/obfuscator/scripts/demo_resumen_de_config.R)
- [2026-05-19_guia-rapida-de-adopcion-de-resumen_de-desde-rstudio.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-19_guia-rapida-de-adopcion-de-resumen_de-desde-rstudio.md)

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

## Modelo de privacidad

Actualmente el control formal principal disponible para liberacion externa es `k-anonymity`.

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

- `type = "k_anonymity"`: activa el modelo
- `k`: tamano minimo de cada grupo equivalente
- `quasi_identifiers`: columnas que se consideran sensibles para reidentificacion
- `suppression`: `rows`, `group` o `none`
- `hierarchies`: pasos de generalizacion por columna

El log incluye un `privacy_report` con:

- riesgo antes y despues
- pasos de generalizacion aplicados
- cantidad de filas suprimidas
- confirmacion de si el criterio `k` quedo satisfecho

Importante:

- satisfacer `k` es una condicion necesaria dentro del flujo actual, pero no debe interpretarse como garantia suficiente en cualquier contexto
- la decision de liberacion externa debe considerar tambien el estado de release, los bloqueos detectados y el reporte de auditoria

## Exportacion y uso por terceros

En la app Shiny:

- guardar en entorno se considera uso interno
- la exportacion CSV queda bloqueada salvo estado `Liberable`
- si la salida no es defendible, la app debe explicar por que y que acciones faltan

En uso programatico:

- puedes ejecutar transformaciones y reproducir configuraciones
- eso no equivale por si solo a una aprobacion de liberacion externa

## Modos numericos

`numeric_mode` acepta:

- `range_random`
- `preserve_rank`
- `permute`

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
