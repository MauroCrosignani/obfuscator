# Etapa 3: Metadata por carpeta para `dataset_profile_for_ai()`

## Resumen

En esta etapa se incorporó una primera capa de carga y resolución de metadata por fuente para el subproyecto interno de perfilado seguro para IA. El helper ahora puede recibir una carpeta de fichas JSON, validar su formato mínimo y aplicar una ficha únicamente cuando existe un match claro por `source_id` o por `alias`.

La decisión metodológica central se mantuvo deliberadamente conservadora: **si la metadata es inválida, falta, o es ambigua, el helper degrada a heurísticas con advertencia y no aplica la ficha automáticamente**.

## Qué se completó

- Se agregó el parámetro opcional `metadata_dir` a `profile_dataset_for_ai()`.
- Se incorporó el bloque `source_metadata` al perfil resultante.
- Se implementó la carga de archivos `.json` desde una carpeta declarada por el usuario.
- Se validó el formato mínimo de cada ficha:
  - `version`
  - `source_type`
  - `source_id`
  - `display_name`
  - `columnas`
- Se incorporó matching en dos niveles:
  - match exacto por `source_id`
  - match por `aliases` y `display_name`
- Se registró explícitamente el origen del match mediante `matched_by`.
- El renderer ahora informa cuando se aplicó metadata de fuente y por qué criterio se resolvió.

## Artefactos tocados

- Script principal del helper:
  - [R/ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R)
- Tests del subproyecto:
  - [test_ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_ai_dataset_profile.R)

## Decisión de diseño aplicada

Se evaluaron dos comportamientos posibles:

1. Aplicar automáticamente la primera ficha “parecida” disponible.
2. Aplicar metadata solo cuando el match fuera claro y degradar con advertencia en los demás casos.

Se eligió la segunda opción porque evita el riesgo más costoso de esta etapa: **atribuir a un dataset una metadata equivocada con falsa confianza**.

## Verificación ejecutada

Pruebas enfocadas:

```r
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Resultado:

- `PASS 120`

Suite completa:

```r
Rscript tests/testthat.R
```

Resultado:

- `PASS 504`

## Limitaciones actuales

Esta etapa todavía no incorpora:

- fallback por `options(obfuscator.metadata_dir = ...)`
- lectura de múltiples carpetas de metadata
- matching normalizado por nombre de columnas
- alertas por desajustes entre metadata esperada y estado actual del objeto
- lectura automática de `oracle` desde conexiones vivas

## Qué problema se resolvió

Antes de esta etapa, el helper podía recibir contexto declarado (`tipo_fuente`) y evidencia del archivo de origen (`archivo_fuente`), pero no podía consumir una ficha declarativa compartida por fuente. Con esta capa, ya es posible enriquecer el perfil con metadata externa sin romper el uso básico ni obligar a que todos los datasets tengan una ficha disponible.

## Valor creado

- Permite compartir conocimiento estructural por fuente sin acoplarlo todavía a la app Shiny.
- Mantiene el helper útil en modo cero-configuración.
- Da un camino de madurez hacia bibliotecas locales por oficina o grupo.

## Riesgo evitado

- Aplicación silenciosa de metadata dudosa.
- Dependencia obligatoria de una carpeta de metadata para usar el helper.
- Lecturas optimistas de JSON incompletos o corruptos.

## Siguiente paso recomendado

Avanzar con la fase 4 del plan maestro:

- matching normalizado de columnas
- comparación entre nombre de origen, nombre normalizado y nombre actual
- y primeras advertencias sobre columnas no resueltas o renombres fuertes
