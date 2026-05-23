# Evaluacion de Modularizacion Interna del Helper IA

## Fecha

2026-05-22

## Proposito

Evaluar si conviene partir [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R) en varios archivos antes de extraer el futuro paquete `contextoia`.

La conclusion practica es que no conviene hacer una particion grande todavia. Si se modulariza ahora, debe ser una modularizacion incremental y guiada por fronteras estables, no un refactor cosmetico.

## Contexto

El archivo [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R) tiene actualmente 1966 lineas y concentra casi todo el helper de perfilado seguro para IA:

- utilidades internas;
- deteccion de fuente;
- carga y resolucion de metadata;
- inferencia semantica por variable;
- resumen estructurado;
- render textual;
- y la funcion publica `resumen_de()`.

Esto lo hace grande, pero tambien lo mantiene cohesivo: casi todo lo que contiene pertenece al mismo subproyecto.

## Fronteras naturales observadas

La lectura de funciones muestra cinco bloques naturales.

### 1. Utilidades base del helper

Responsabilidad:

- valores no faltantes;
- tipo importado;
- normalizacion de nombres;
- deteccion de texto libre;
- quoting seguro de valores.

Ejemplos:

- `ai_profile_non_missing_values()`
- `ai_profile_imported_type()`
- `ai_profile_normalize_column_name()`
- `ai_profile_text_like_column()`
- `ai_profile_quote_values()`

### 2. Contexto de fuente

Responsabilidad:

- normalizar `tipo_fuente`;
- detectar `GCA.net` y `GCA2` desde libros Excel;
- fusionar fuente declarada y fuente detectada.

Ejemplos:

- `ai_profile_normalize_tipo_fuente()`
- `ai_profile_detect_gca_source_from_workbook()`
- `ai_profile_detect_gca2_source_from_workbook()`
- `ai_profile_detect_source_from_file()`
- `ai_profile_merge_source_context()`

### 3. Metadata externa

Responsabilidad:

- validar fichas JSON;
- cargar metadata por carpeta;
- resolver fuente por `source_id` o aliases;
- resolver columnas con matching normalizado;
- construir alertas de desajuste.

Ejemplos:

- `ai_profile_validate_source_metadata_entry()`
- `ai_profile_load_source_metadata()`
- `ai_profile_resolve_source_metadata()`
- `ai_profile_resolve_metadata_columns()`
- `ai_profile_build_source_alerts()`

### 4. Inferencia y resumen por variable

Responsabilidad:

- inferir tipo semantico;
- detectar patrones temporales;
- detectar categorias compuestas;
- detectar etiquetas de entidad;
- generar resumen por variable.

Ejemplos:

- `ai_profile_infer_type()`
- `ai_profile_observed_temporal_pattern()`
- `ai_profile_detect_compound_delimiter()`
- `ai_profile_looks_like_entity_label()`
- `ai_profile_variable_summary()`
- `build_variable_profile_for_ai()`

### 5. Orquestacion y render

Responsabilidad:

- construir el perfil de dataset;
- renderizar variables;
- renderizar el dataset completo;
- exponer la funcion publica en espanol.

Ejemplos:

- `profile_dataset_for_ai()`
- `render_ai_profile_variable()`
- `render_dataset_profile_for_ai()`
- `resumen_de()`

## Alternativas consideradas

### Alternativa 1: no partir el archivo hasta crear `contextoia`

Ventaja:

- reduce el riesgo de mover mucho codigo sin necesidad inmediata.

Problema:

- la extraccion futura puede llegar con un archivo demasiado grande y dificil de revisar.

### Alternativa 2: partir ahora el archivo en muchos modulos

Ventaja:

- se parece mas a la arquitectura futura del paquete independiente.

Problema:

- podria crear mucho movimiento de codigo sin mejorar todavia la API ni el comportamiento;
- aumenta el riesgo de errores por orden de carga con el bridge transicional;
- y puede producir churn innecesario en una rama que todavia convive con ObfuscatoR.

### Alternativa 3: modularizacion incremental guiada por estabilidad

Ventaja:

- permite preparar `contextoia` sin sobreactuar el refactor;
- reduce riesgo;
- y hace que cada particion tenga un motivo tecnico claro.

Problema:

- deja por ahora un archivo grande.

Decision recomendada:

- elegir la alternativa 3.

## Recomendacion

No partir todo [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R) de inmediato.

La siguiente modularizacion deberia hacerse en pasos pequeños, cada uno con tests verdes y con una frontera clara:

1. `R/ai_profile_utils.R`
2. `R/ai_profile_source_context.R`
3. `R/ai_profile_metadata.R`
4. `R/ai_profile_variables.R`
5. `R/ai_profile_render.R`

La primera candidata, cuando se decida tocar codigo, seria `R/ai_profile_utils.R`, porque contiene funciones base ya estables y con bajo acoplamiento. Despues convendria separar fuente y metadata, porque son bloques conceptualmente distintos del perfilado por variable.

## Criterio para decidir cada particion

Antes de mover codigo a otro archivo, deberia cumplirse al menos una de estas condiciones:

- el bloque tiene responsabilidad clara y estable;
- el bloque no depende de la app Shiny ni de ObfuscatoR;
- el movimiento facilita directamente la futura extraccion a `contextoia`;
- existe test que cubre la frontera afectada;
- el orden de carga con `devtools::load_all()` y `source("R/obfuscator_core.R")` queda verificado.

## Riesgos a evitar

### Refactor grande sin ganancia funcional

Mover muchas funciones a la vez puede generar diffs grandes, dificiles de revisar y sin valor inmediato para usuarios.

### Nombres de archivo demasiado ligados a la implementacion actual

Los archivos deberian nombrarse por responsabilidad estable, no por la forma accidental en que hoy esta ordenado el archivo.

### Romper el bridge con `source()`

Mientras ObfuscatoR siga usando `load_obfuscator_companion()`, cualquier particion debe verificar que el camino con `source("R/obfuscator_core.R")` siga funcionando.

### Exportar demasiado pronto

La particion interna no debe confundirse con ampliar la API publica. La funcion publica sigue siendo `resumen_de()`.

## Estado actual de preparacion para `contextoia`

El helper ya tiene condiciones favorables:

- no depende de Shiny;
- funciona con `devtools::load_all()`;
- tiene tests dedicados;
- ya no depende de las utilidades `release_safe_*` del core;
- y tiene una API publica en espanol protegida por tests.

Todavia falta:

- decidir si `%||%` se mantiene como utilidad compartida o se internaliza;
- evaluar modularizacion por archivos;
- preparar, mas adelante, `DESCRIPTION`, `NAMESPACE`, documentacion y tests del paquete independiente.

## Siguiente paso sugerido

Cuando se retome implementacion estructural, hacer solo la primera particion:

- crear `R/ai_profile_utils.R`;
- mover alli utilidades base del helper;
- verificar `source("R/obfuscator_core.R")`;
- verificar `devtools::load_all(".")`;
- correr la suite completa.

No se recomienda partir fuente, metadata, variables y render en la misma pasada.

## Actualizacion posterior

La primera particion se implemento en:

- [2026-05-22_primera_particion_de_utilidades_del_helper_ia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-22_primera_particion_de_utilidades_del_helper_ia.md)

Se creo [ai_profile_utils.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_utils.R) y se movieron alli las utilidades base del helper. La recomendacion de no partir todos los bloques en una sola pasada sigue vigente.

## Actualizacion posterior 2

La segunda particion se implemento en:

- [2026-05-22_segunda_particion_contexto_de_fuente_del_helper_ia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-22_segunda_particion_contexto_de_fuente_del_helper_ia.md)

Se creo [ai_profile_source_context.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_source_context.R) y se movieron alli las funciones de normalizacion, deteccion y fusion de contexto de fuente. La recomendacion de modularizacion incremental sigue vigente.
