# Analisis critico del render actual del helper de perfilado IA

## Resumen

Se realizo una nueva evaluacion critica del resultado actual de [resumen_de()](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R) tomando como referencia:

- el estado vigente del plan de mejoras semanticas;
- el comportamiento actual sobre `starwars`;
- y el criterio funcional de preservar, para la IA, parte del valor estructural que antes aportaba `glimpse()`.

Conclusion practica:

- el helper mejoro mucho como resumen semantico;
- pero todavia no preserva de forma visible y sistematica el tipo exacto importado de cada variable;
- por lo tanto, la siguiente mejora recomendada no es agregar mas heuristicas, sino ajustar el renderer para que muestre explicitamente `imported_type`.

## Problema identificado

La salida actual responde bien a:

- “que parece ser esta variable”

pero peor a:

- “como vino representada realmente a R”

Ese segundo punto importa porque:

- `character` no es lo mismo que `factor`;
- `integer` no es lo mismo que `double`;
- `list` no es lo mismo que `character`;
- y `Date`, `POSIXct` o `character` con patron temporal no implican el mismo estado de preparacion.

## Hallazgos principales

### 1. El helper ya gano semantica util

Quedo mejor resuelto:

- `homeworld` y otras nominales de alta cardinalidad;
- `hair_color` como categoria compuesta;
- `films`, `vehicles` y `starships` como `list-columns`;
- `height` y `mass` diferenciando `integer` y `double`;
- `name` como `entity_label`.

### 2. Sigue faltando visibilidad del tipo importado

Aunque el objeto estructurado conserva `imported_type`, la salida visible no lo muestra de forma consistente.

Eso hace que:

- la IA reciba interpretacion semantica;
- pero menos evidencia estructural que la que `glimpse()` daba de inmediato.

### 3. La salida actual privilegia interpretacion sobre evidencia

Ejemplos:

- `sex: categorica` no deja visible que fue importada como `character`;
- `name: etiqueta nominal de entidad` no deja visible que fue `character`;
- `films: columna lista` no deja visible que fue `list`;
- `height: numerica entera` no deja visible que fue `integer`.

### 4. Todavia quedan mejoras semanticas de segundo orden

El analisis tambien confirmo que siguen abiertas, aunque ya no son la primera prioridad:

- refinamiento de categorias compuestas;
- robustez adicional de `entity_label`;
- y mayor precisión en semantica de `list-columns`.

## Decision recomendada

La siguiente evolucion del helper debe ser:

1. hacer visible el tipo importado exacto en cada variable;
2. conservar la interpretacion semantica actual;
3. y ordenar el render como:
   - `importada como ...`
   - `interpretada como ...`
   - `resumen seguro`

## Artefacto asociado

Esta recomendacion se formalizo en:

- [2026-05-19-diseno-de-render-que-preserva-la-estructura-de-glimpse-para-el-helper-ia.md](c:/Users/mcros/Documents/obfuscator/docs/02_diseno/2026-05-19-diseno-de-render-que-preserva-la-estructura-de-glimpse-para-el-helper-ia.md)

## Siguiente paso recomendado

No avanzar todavia con mas heuristicas nuevas.

El siguiente paso con mejor relacion valor-esfuerzo es:

1. rediseñar el renderer para mostrar `imported_type` de forma sistematica;
2. y recien despues seguir refinando compuestas, `entity_label` y otras familias.
