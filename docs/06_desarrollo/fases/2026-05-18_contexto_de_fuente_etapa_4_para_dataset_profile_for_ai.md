# Etapa 4: Matching normalizado de columnas para `dataset_profile_for_ai()`

## Resumen

En esta etapa se incorporó una capa de comparación entre la metadata de origen y los nombres actuales del objeto en R, sin depender solo de coincidencias literales.

El helper ahora puede distinguir entre:

- match exacto por nombre actual;
- match por normalización equivalente a `clean_names()`;
- columnas sin resolver después de intentar normalizar;
- y casos ambiguos donde normalizar no alcanza para decidir con seguridad.

La regla que se preservó en toda la etapa fue la misma del resto del resolvedor: **mejor advertir un posible renombre o desajuste que adivinar un match fuerte sin evidencia suficiente**.

## Qué se completó

- Se agregó una normalización interna de nombres para matching, sin imponer `janitor::clean_names()` como requisito para los usuarios.
- Se implementó una resolución por columna dentro de `source_metadata`, con esta estructura:
  - `matched`
  - `unresolved`
  - `ambiguous`
  - `summary`
  - `warnings`
- Se incorporó el orden de comparación aprobado en diseño:
  1. nombre actual exacto
  2. nombre normalizado
  3. si no hay evidencia suficiente, dejar sin resolver
- Se agregaron advertencias explícitas cuando una columna esperada no aparece ni por match exacto ni por normalización.
- El renderer ahora informa un resumen del matching de columnas cuando se aplicó una ficha de metadata.

## Artefactos tocados

- Helper principal:
  - [R/ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R)
- Tests del subproyecto:
  - [test_ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_ai_dataset_profile.R)
- Metadata del paquete:
  - [DESCRIPTION](c:/Users/mcros/Documents/obfuscator/DESCRIPTION)

## Decisión metodológica aplicada

Se consideraron dos caminos posibles:

1. hacer matching solo por igualdad literal;
2. usar una capa interna de normalización antes de declarar que una columna falta.

Se eligió la segunda opción porque refleja mejor la realidad del proyecto:

- `GCA.net` puede venir en mayúsculas;
- `GCA2` puede venir en minúsculas;
- algunos scripts aplican una limpieza tipo `clean_names()`;
- y otros dejan el nombre original intacto.

También se descartó, por ahora, intentar reconstruir renombres fuertes a partir de similitud libre. Casos como `FECHA_ULT_ACT` versus `fecha_ultima_actualizacion` siguen quedando como desajustes a revisar, no como matches automáticos.

## Verificación ejecutada

Pruebas enfocadas:

```r
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Resultado:

- `PASS 136`

Suite completa:

```r
Rscript tests/testthat.R
```

Resultado:

- `PASS 511`

## Qué no se hizo todavía

Esta etapa no incluye:

- reconstrucción automática de renombres desde el script activo;
- aliases por columna dentro de la metadata;
- matching semántico libre por parecido lingüístico;
- alertas estructuradas sobre diferencias entre `tipo_esperado` y tipo actual.

## Problema resuelto

Antes de esta etapa, una ficha de metadata podía resolverse correctamente a nivel de fuente, pero seguir siendo poco útil si los nombres de columnas no coincidían literalmente con los del objeto actual. Ahora esa ficha conserva valor práctico aun cuando haya diferencias razonables de formato entre origen y objeto.

## Valor creado

- Reduce falsos “faltantes” por diferencias superficiales de nombres.
- Hace más útil la metadata de consultas `GCA.net` cuando el objeto ya fue limpiado o estandarizado en R.
- Mantiene una frontera prudente frente a renombres realmente fuertes o ambiguos.

## Riesgo evitado

- Declarar columnas faltantes cuando en realidad solo estaban normalizadas.
- Aplicar metadata equivocada a columnas parecidas pero no equivalentes.
- Introducir una política obligatoria de `clean_names()` para toda la organización.

## Siguiente paso recomendado

Avanzar con la fase 5 del plan maestro:

- alertas por desajustes relevantes entre metadata esperada y estado actual del objeto;
- especialmente para:
  - `tipo_esperado`
  - faltantes esperables/no esperables
  - e identificadores o fechas que no quedaron normalizados como se esperaba.
