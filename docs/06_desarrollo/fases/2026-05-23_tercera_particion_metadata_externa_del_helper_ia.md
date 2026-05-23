# Tercera Particion: Metadata Externa del Helper IA

## Fecha

2026-05-23

## Objetivo del paso

Separar el bloque de carga, validacion y resolucion de metadata externa del helper de perfilado seguro para IA, continuando la modularizacion incremental hacia el futuro paquete `contextoia`.

## Cambio implementado

Se creo:

- [ai_profile_metadata.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_metadata.R)

Alli se movieron las funciones responsables de:

- estructura vacia de metadata de fuente;
- validacion de fichas JSON;
- carga de metadata desde `metadata_dir`;
- resolucion de fuentes por `source_id` y alias;
- matching de columnas esperadas contra columnas observadas;
- y construccion de alertas por desajuste entre metadata de origen y estado actual del objeto.

El archivo [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R) conserva ahora:

- heuristicas de nombres;
- configuracion declarativa;
- inferencia semantica por variable;
- construccion del perfil;
- render;
- y la API publica `resumen_de()`.

## Ajuste de carga

Se actualizo [obfuscator_core.R](c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R) para cargar en este orden cuando se usa `source("R/obfuscator_core.R")`:

1. [release_decision_helpers.R](c:/Users/mcros/Documents/obfuscator/R/release_decision_helpers.R)
2. [ai_profile_utils.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_utils.R)
3. [ai_profile_source_context.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_source_context.R)
4. [ai_profile_metadata.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_metadata.R)
5. [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R)

## Prueba ajustada

Se actualizo el entorno candidato a `contextoia` en [test_ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_ai_dataset_profile.R) para cargar tambien [ai_profile_metadata.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_metadata.R) antes de [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R).

Esto preserva la prueba de que el helper IA puede cargarse sin depender de utilidades `release_safe_*` del core de ObfuscatoR.

## Verificacion

Se ejecuto:

```r
Rscript -e "source('R/obfuscator_core.R'); cat(exists('resumen_de', mode='function'))"
Rscript -e "devtools::load_all('.'); cat(exists('resumen_de', mode = 'function'))"
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
Rscript tests/testthat.R
git diff --check
```

Resultado:

- `source("R/obfuscator_core.R")`: `TRUE`
- `devtools::load_all(".")`: `TRUE`
- `PASS 250`
- suite completa: `PASS 634`
- `git diff --check`: sin errores; solo avisos de conversion LF/CRLF esperables en Windows.

## Limitaciones

Este paso no separa todavia:

- inferencia por variable;
- render;
- ni API publica.

La separacion sigue siendo incremental para evitar un diff demasiado grande y preservar trazabilidad de cada frontera.

## Siguiente paso sugerido

Si se continua modularizando, el siguiente bloque natural seria separar inferencia y resumen por variable en `R/ai_profile_variables.R`. Conviene hacerlo solo despues de confirmar que esta particion de metadata queda verde en suite completa y CI.
