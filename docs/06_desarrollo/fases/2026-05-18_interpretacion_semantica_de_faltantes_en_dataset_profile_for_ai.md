## Resumen ejecutivo

- fase o hito: interpretacion semantica de faltantes
- fecha: 2026-05-18
- estado: completado
- conclusion practica: el helper ya no muestra solo el porcentaje de `NA`; ahora distingue entre faltantes esperables y faltantes que conviene revisar.

## Objetivo de la fase

Evitar que el perfil para IA trate toda alta densidad de faltantes como un problema inesperado, incorporando una heuristica simple para casos estructuralmente esperables como `fecha_hasta`.

## Contexto de entrada

Ya se habia agregado `missing_pct` al objeto y al renderer. El paso siguiente necesario era darle una interpretacion semantica minima, porque no todo faltante alto implica mala calidad.

## Decisiones tomadas

- introducir `missingness_hint` como senal ligera por variable
- usar una clasificacion acotada y explicable:
  - `expected`
  - `high_unexpected`
  - `present`
  - `none`
- detectar faltantes esperables por patron de nombre, empezando por variantes de `fecha_hasta` y `fecha_fin`
- mostrar esa interpretacion directamente en el renderer

## Alternativas consideradas

- dejar solo el porcentaje crudo sin interpretacion
- crear una heuristica compleja de completitud
- esconder la senal salvo cuando hubiera un problema extremo

## Motivo de la eleccion

El renderer esta pensado para pegarse directamente en una IA. Si solo muestra porcentajes, la IA puede sobrerreaccionar ante faltantes que son normales de negocio. Una clasificacion corta y explicable mejora mucho el contexto sin volver el helper opaco.

## Implementacion realizada

En [R/ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R):

- nueva heuristica `ai_profile_expected_missingness_name()`
- nueva clasificacion `ai_profile_missingness_hint()`
- inclusion de `missingness_hint` en el objeto por variable
- render enriquecido:
  - `faltantes 75.0% (esperables)`
  - `faltantes 60.0% (revisar)`

En [test_ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_ai_dataset_profile.R):

- prueba para `fecha_hasta` con faltantes estructuralmente esperables
- prueba para `ingreso` con faltantes altos no esperables

## Verificacion ejecutada

- `Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"` -> `PASS 50`
- `Rscript tests/testthat.R` -> `PASS 434`

## Riesgos, limites o deuda remanente

- la deteccion de faltantes esperables se basa por ahora en nombres de columna
- aun no se modelan faltantes esperables por logica de negocio mas compleja
- no hay configuracion externa para definir politicas propias por institucion

## Impacto sobre la especificacion

Refuerza la calidad del subproyecto como traductor de estructura y contexto hacia IA: ahora no solo mide completitud, sino que intenta interpretarla con prudencia metodologica.

## Impacto sobre la futura presentacion tecnica

Suma un argumento importante para mostrar madurez: incluso un detalle como los `NA` se trata de forma contextual, evitando alarmas falsas sobre variables donde el faltante es esperable.

## Siguiente paso recomendado

Si seguimos profundizando, el siguiente salto natural seria permitir una configuracion externa de politicas de faltantes esperables por esquema o por organizacion.
