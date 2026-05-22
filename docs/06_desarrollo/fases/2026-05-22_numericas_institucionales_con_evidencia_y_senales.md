# Numericas institucionales con evidencia y senales

## Fecha

2026-05-22

## Objetivo del paso

Implementar en el helper IA una capa mas prudente y expresiva para columnas numericas institucionales, separando:

1. tipo importado;
2. clasificacion programatica;
3. evidencia observada;
4. senal heuristica.

## Motivacion

Las pruebas reales mostraron columnas `double` que no siempre se leen bien como medidas continuas:

- `COD_TIPO_VARIABLE`
- `UNIDAD_FUNCIONAL`
- `PERIODICIDAD`
- `CANT_TOTAL`

El problema no era el tipo importado, sino la falta de una capa visible que diferenciara hechos observables de sugerencias programaticas prudentes.

## Cambios implementados

### Implementacion

- [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R)

Se ajusto el helper para que en numericas:

- use `tipo importado: ...` y `clasificacion programatica: ...`;
- agregue `evidencia observada: ...` cuando la columna:
  - solo toma valores enteros pese a venir como `double`;
  - o presenta un unico valor observado;
- y agregue `senal heuristica: podria funcionar como codigo numerico` cuando coinciden evidencia numerica fuerte y un nombre de columna tecnicamente sugerente.

### Tests

- [test_ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_ai_dataset_profile.R)

Se agregaron y ajustaron contratos para cubrir:

- el nuevo wording visible de numericas;
- evidencia observada para `double` enteriformes;
- evidencia observada para valor unico;
- senal heuristica prudente de posible codigo numerico;
- y una prueba negativa para evitar disparar esa senal sobre una medida continua comun.

### Documentacion

- [README.md](c:/Users/mcros/Documents/obfuscator/README.md)
- [2026-05-18_guia-operativa-profile_dataset_for_ai.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-18_guia-operativa-profile_dataset_for_ai.md)
- [2026-05-22-diseno-de-evidencia-y-senales-heuristicas-para-numericas-institucionales.md](c:/Users/mcros/Documents/obfuscator/docs/02_diseno/2026-05-22-diseno-de-evidencia-y-senales-heuristicas-para-numericas-institucionales.md)
- [2026-05-22-evidencia-y-senales-heuristicas-para-numericas-institucionales-implementation-plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-22-evidencia-y-senales-heuristicas-para-numericas-institucionales-implementation-plan.md)
- [2026-05-22_diseno_y_plan_para_numericas_institucionales_con_evidencia_y_senales.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-22_diseno_y_plan_para_numericas_institucionales_con_evidencia_y_senales.md)

## Verificacion

Se ejecutaron estas verificaciones:

- `Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"` -> `PASS 234`
- `Rscript tests/testthat.R` -> `PASS 618`

## Resultado

El helper ahora distingue mejor entre:

- lo que sabe por tipo importado;
- lo que clasifica programaticamente;
- lo que puede afirmar como evidencia observada;
- y lo que solo debe presentar como senal heuristica prudente.

Esto mejora la utilidad del resumen para IA sin exagerar certeza sobre si una columna es realmente un codigo.

## Siguiente paso sugerido

Probar este nuevo wording con otro dataset real donde haya:

- columnas `double` enteriformes con nombres menos obvios;
- columnas constantes que no sean tecnicas;
- y algun caso donde la senal `podria funcionar como codigo numerico` deba deliberadamente no activarse.
