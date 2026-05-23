# Segunda Particion: Contexto de Fuente del Helper IA

## Fecha

2026-05-22

## Objetivo del paso

Separar el bloque de contexto de fuente del helper de perfilado seguro para IA, continuando la modularizacion incremental hacia el futuro paquete `contextoia`.

## Cambio implementado

Se creo:

- [ai_profile_source_context.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_source_context.R)

Alli se movieron las funciones responsables de:

- normalizar `tipo_fuente`;
- detectar planillas `GCA.net`;
- detectar planillas `GCA2`;
- resolver contexto desde `archivo_fuente`;
- fusionar contexto declarado y contexto detectado.

El archivo principal [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R) conserva ahora la logica de metadata, perfilado por variable, render y API publica.

## Ajuste de carga

Se actualizo [obfuscator_core.R](c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R) para cargar en este orden cuando se usa `source("R/obfuscator_core.R")`:

1. [release_decision_helpers.R](c:/Users/mcros/Documents/obfuscator/R/release_decision_helpers.R)
2. [ai_profile_utils.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_utils.R)
3. [ai_profile_source_context.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_source_context.R)
4. [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R)

## Prueba ajustada

Se actualizo el entorno candidato a `contextoia` en [test_ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_ai_dataset_profile.R) para cargar:

- [ai_profile_utils.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_utils.R)
- [ai_profile_source_context.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_source_context.R)
- [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R)

Tambien se agrego una asercion minima para confirmar que `ai_profile_normalize_tipo_fuente("GCA2")` sigue funcionando en ese entorno.

## Verificacion

Se ejecuto:

```r
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Resultado:

- `PASS 246`

Tambien se ejecuto:

```r
Rscript -e "source('R/obfuscator_core.R'); cat(exists('resumen_de', mode='function'))"
```

Resultado:

- `TRUE`

Tambien se ejecuto:

```r
Rscript -e "devtools::load_all('.'); cat(exists('resumen_de', mode = 'function'))"
```

Resultado:

- `TRUE`

Finalmente se ejecuto la suite completa:

```r
Rscript tests/testthat.R
```

Resultado:

- `PASS 630`

## Limitaciones

Este paso no mueve todavia:

- metadata externa;
- inferencia y resumen por variable;
- render;
- ni la API publica `resumen_de()`.

La separacion sigue siendo incremental. No se recomienda partir todos los bloques restantes en la misma pasada.

## Siguiente paso sugerido

Si se continua modularizando despues, el siguiente bloque natural seria metadata externa, pero solo si la rama sigue enfocada en preparar la extraccion a `contextoia`.
