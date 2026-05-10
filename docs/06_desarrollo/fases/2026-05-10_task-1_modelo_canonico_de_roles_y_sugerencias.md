# Task 1 - Modelo canonico de roles y sugerencias release-safe

## Resumen

Se implemento la primera task del plan de rediseño UX/UI de clasificacion `release-safe`.

Conclusion practica:
- el proyecto ya tiene un vocabulario canonico de roles;
- cuenta con sugerencias automaticas explicables por columna;
- y quedo fijada la separacion semantica minima necesaria para seguir con la nueva tabla de clasificacion sin depender del modelo viejo.

## Objetivo del task

Definir una base pura y testeable para:

- roles permitidos;
- prioridad entre roles;
- sugerencias automaticas por columna con motivo explicable;
- y construccion canonica del conjunto de `quasi-identifiers`.

## Archivos modificados

- [R/obfuscator_core.R](c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R)
- [R/shiny_app.R](c:/Users/mcros/Documents/obfuscator/R/shiny_app.R)
- [test_release_safe_roles_ui.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_release_safe_roles_ui.R)

## Cambios realizados

### 1. Roles canonicos

Se definieron roles oficiales:

- `ID`
- `QI`
- `SENS`
- `PRIV`
- `KEEP`
- `EXC`

Tambien se fijo la prioridad de sugerencia:

1. `ID`
2. `PRIV`
3. `SENS`
4. `QI`
5. `EXC`
6. `KEEP`

### 2. Sugerencias automaticas explicables

Se agregaron helpers puros para sugerir rol por columna en funcion de:

- nombre de la variable;
- tipo de dato;
- patrones nominales;
- y señales simples de texto libre.

Cada sugerencia devuelve:

- `role`
- `reason`

Esto deja una base mas defendible para la futura UI, porque el sistema no solo clasifica: tambien explica.

### 3. Conjunto canonico de quasi-identificadores

Se agrego un helper canonico para construir `quasi-identifiers` desde sugerencias release-safe puras, evitando que:

- `SENS`
- `PRIV`

entren automaticamente al calculo de `k-anonymity`.

### 4. Compatibilidad minima con el flujo actual

En [R/shiny_app.R](c:/Users/mcros/Documents/obfuscator/R/shiny_app.R) se dejo una adaptacion minima para que `quasi_identifier_choices()` pueda entender el nuevo formato de sugerencias, sin reescribir todavia la UI principal.

## Casos de prueba cubiertos

El nuevo archivo [test_release_safe_roles_ui.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_release_safe_roles_ui.R) cubre:

- estabilidad de roles y prioridad;
- sugerencias explicables sobre el dataset demo;
- exclusion de `SENS` y `PRIV` del conjunto `QI`;
- prioridad correcta cuando una columna activa varias señales.

Ejemplos fijados:

- `edad` -> `QI`
- `observacion` -> `PRIV`
- `indicador_privado` -> `SENS`

## Verificacion ejecutada

Comandos corridos:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_release_safe_roles_ui.R')"
Rscript tests/testthat.R
```

Resultados:

- `test_release_safe_roles_ui.R`: `PASS 15`
- suite completa: `PASS 228`

Nota:
- aparecio el warning de entorno `package 'testthat' was built under R version 4.2.3`, sin impacto funcional.

## Alternativas consideradas

### 1. Esperar a la tabla nueva antes de fijar helpers puros

Motivo de descarte:
- hubiera mezclado semantica y presentacion demasiado pronto.

### 2. Resolver la sugerencia solo dentro de `shiny_app.R`

Motivo de descarte:
- peor auditabilidad;
- menos testabilidad;
- y mayor riesgo de acoplar la semantica al flujo visual actual.

## Impacto sobre presentacion tecnica

Este task deja una base importante para explicar el producto a tecnicos:

- ya existe un vocabulario de roles consistente;
- la app puede justificar sugerencias;
- y `edad` deja de quedar conceptualmente invisible por el solo hecho de ser numerica.

## Limites vigentes

- la UI principal todavia no expone este modelo como experiencia dominante;
- la ficha lateral y la tabla nueva aun no existen;
- la heuristica sigue siendo conservadora y simple, no pretende inteligencia total.

## Siguiente paso recomendado

Ejecutar la Task 2 del plan:

- preservar persistencia y fuzzy matching bajo el nuevo modelo de roles;
- y asegurar que la migracion futura de UX no rompa continuidad de plantillas.
