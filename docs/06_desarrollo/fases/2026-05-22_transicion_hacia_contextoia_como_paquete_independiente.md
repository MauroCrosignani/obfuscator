# Transicion hacia `contextoia` como paquete independiente

## Fecha

2026-05-22

## Objetivo del paso

Mejorar la compatibilidad del helper de perfilado seguro para IA con carga tipo paquete, sin romper el flujo actual con `source()`, y dejando mas claro su rol como futuro candidato a extraccion hacia `contextoia`.

## Problema inicial

Antes de este ajuste, el repo fallaba al ejecutar:

```r
devtools::load_all(".")
```

porque [obfuscator_core.R](c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R) intentaba resolver archivos companeros exclusivamente desde `source()`/`sys.source()` y abortaba cuando se cargaba en contexto de namespace.

## Cambios implementados

### Implementacion

- [obfuscator_core.R](c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R)

Se introdujeron helpers internos para distinguir:

- contexto de carga por `source()`;
- contexto de carga en namespace, por ejemplo con `devtools::load_all()`.

Con eso:

- `load_obfuscator_companion()` sigue `sys.source()`-ando companions cuando el archivo se carga desde disco;
- y pasa a ser un no-op transicional cuando el codigo se carga como paquete, dejando que `pkgload`/R resuelva los archivos de `R/` por su cuenta.

Tambien se dejo visible el bridge de compatibilidad en vez de eliminarlo con `rm(load_obfuscator_companion)`, para poder testearlo y tratarlo explicitamente como bootstrap transicional.

### Tests

- [test_ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_ai_dataset_profile.R)

Se agregaron contratos para cubrir:

- deteccion de contexto `source` vs `namespace`;
- comportamiento de `load_obfuscator_companion()` como no-op en contexto de namespace.

### Documentacion

- [README.md](c:/Users/mcros/Documents/obfuscator/README.md)
- [2026-05-18_guia-operativa-profile_dataset_for_ai.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-18_guia-operativa-profile_dataset_for_ai.md)
- [2026-05-22-diseno-de-transicion-hacia-contextoia-como-paquete-independiente.md](c:/Users/mcros/Documents/obfuscator/docs/02_diseno/2026-05-22-diseno-de-transicion-hacia-contextoia-como-paquete-independiente.md)
- [2026-05-22-transicion-hacia-contextoia-como-paquete-independiente-implementation-plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-22-transicion-hacia-contextoia-como-paquete-independiente-implementation-plan.md)
- [2026-05-22_diseno_y_plan_de_transicion_hacia_contextoia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-22_diseno_y_plan_de_transicion_hacia_contextoia.md)

## Verificacion

Se ejecutaron estas verificaciones:

- `Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"` -> `PASS 239`
- `Rscript tests/testthat.R` -> `PASS 623`
- `Rscript -e "devtools::load_all('.'); cat(exists('resumen_de', mode = 'function'))"` -> `TRUE`

## Resultado

El helper ahora:

- sigue funcionando con `source("R/obfuscator_core.R")`;
- ya funciona con `devtools::load_all()` durante desarrollo;
- y queda menos acoplado a una resolucion fragil basada en `ofile` o en el directorio de trabajo.

Esto no completa todavia la extraccion a `contextoia`, pero si reduce un obstaculo concreto para llegar a esa separacion mas adelante.

## Acoplamientos pendientes

Todavia quedan pendientes para una futura extraccion:

- separar con mas claridad que piezas pertenecen solo al helper;
- revisar si conviene mantener o no el bootstrap en `obfuscator_core.R`;
- y decidir si ObfuscatoR consumira despues `contextoia` como dependencia o si ambos quedaran completamente separados.

## Mini auditoria posterior

Despues de resolver la compatibilidad con `devtools::load_all()`, se completo una mini auditoria estructural especifica:

- [2026-05-22-miniauditoria-de-fronteras-hacia-contextoia.md](c:/Users/mcros/Documents/obfuscator/docs/04_auditorias/2026-05-22-miniauditoria-de-fronteras-hacia-contextoia.md)

La conclusion de esa auditoria fue:

- el helper ya esta desacoplado del flujo Shiny;
- la futura extraccion a `contextoia` es viable sin rediseño funcional;
- pero todavia hay tres utilidades compartidas heredadas de [obfuscator_core.R](c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R) que conviene mover o duplicar antes de extraer;
- y la API publica futura sigue mas clara en diseño que en exports reales del namespace.

## Siguiente paso sugerido

Abrir una pasada corta de desacople tecnico:

- mover o duplicar las utilidades compartidas minimas del helper;
- decidir la exposicion publica de `profile_dataset_for_ai()` y `render_dataset_profile_for_ai()`;
- y evaluar si conviene modularizar internamente [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R) antes de la extraccion real.
