# Task 11 - Alineacion entre codigo generado, API y semantica de liberacion

## Resumen ejecutivo

- fecha: 2026-05-09
- estado: completado en rama de implementacion, pendiente de integracion a la rama principal
- rama de trabajo: `codex/release-contract-task0`
- commit de cierre del task: `51c215a`
- conclusion practica: el codigo R generado ya no simplifica en exceso el modelo de privacidad y la ejecucion programatica deja explicitamente de interpretarse como aprobacion automatica de liberacion externa.

## Audiencia y proposito

Este documento deja trazabilidad del cierre del `Task 11` del plan vigente. Su proposito es:

1. sostener continuidad del desarrollo sin depender de la conversacion;
2. explicar la decision metodologica adoptada;
3. capturar material reutilizable para la futura presentacion tecnica del MVP.

## Objetivo del task

Alinear tres planos que podian divergir:

- la UI;
- el codigo R generado para reproduccion;
- y el uso directo de la API / script.

El objetivo era evitar que un flujo programatico pareciera mas permisivo o mas “aprobado” que el flujo de liberacion modelado en la app.

## Artefactos modificados

Los cambios funcionales viven actualmente en el worktree de implementacion:

- [R/shiny_app.R](c:/Users/mcros/Documents/obfuscator/.worktrees/release-contract-task0/R/shiny_app.R)
- [R/release_decision_helpers.R](c:/Users/mcros/Documents/obfuscator/.worktrees/release-contract-task0/R/release_decision_helpers.R)
- [tests/testthat/test_obfuscator.R](c:/Users/mcros/Documents/obfuscator/.worktrees/release-contract-task0/tests/testthat/test_obfuscator.R)
- [tests/testthat/test_release_decision.R](c:/Users/mcros/Documents/obfuscator/.worktrees/release-contract-task0/tests/testthat/test_release_decision.R)

## Decision tomada

Se eligio hacer dos cambios concretos:

1. extraer un helper puro para generar el snippet de codigo R;
2. introducir un helper puro para evaluar resultados programaticos bajo semantica de liberacion segura.

Esto permite que:

- el codigo generado incluya los parametros reales de `privacy_model`;
- el codigo generado advierta explicitamente que reproducir transformaciones no equivale a aprobar liberacion externa;
- la API pueda devolver un `release_state` coherente sin fingir que toda ejecucion programatica produce un artefacto externamente liberable.

## Motivo de la eleccion

La alternativa mas simple era dejar el generador actual y asumir que quien usa el codigo entiende las limitaciones. Se descarto porque eso introducia un riesgo de interpretacion peligroso:

- el snippet omitia `quasi_identifiers`, `group_ids` y jerarquias;
- el uso por API podia leerse como un camino “mas directo” hacia una salida aparentemente aprobada;
- la semantica de liberacion quedaba mejor defendida en la UI que en el uso programatico.

La opcion elegida mejora la coherencia del producto sin requerir todavia una refactorizacion grande del core.

## Alternativas consideradas

### Alternativa A: dejar el generador actual y solo agregar una advertencia visual en el modal

Ventaja:
- cambio rapido.

Motivo de descarte:
- no corregia el problema estructural de omitir parametros reales del modelo de privacidad.

### Alternativa B: mover toda la logica de liberacion al core antes de tocar el generador

Ventaja:
- maximo alineamiento conceptual.

Motivo de descarte:
- demasiado grande para este task;
- retrasaba una correccion importante y acotada.

### Alternativa C: helper puro para codigo + helper puro para resultado API

Ventaja:
- mejora testabilidad;
- alinea semantica sin depender del modal UI;
- deja base reusable para pasos posteriores.

Motivo de eleccion:
- fue la mejor relacion entre claridad, alcance y riesgo.

## Implementacion realizada

Se implemento:

- un builder puro del codigo R generado;
- inclusion de:
  - `quasi_identifiers`;
  - `suppression`;
  - `group_ids`;
  - placeholder de jerarquias;
- advertencia textual explicita dentro del snippet sobre que la reproduccion programatica no equivale a aprobar liberacion externa;
- un helper para derivar `release_state` desde resultados de API o script;
- criterio conservador por defecto: la ejecucion programatica se considera `internal_work` salvo que se explicite otra intencion de artefacto.

## Verificacion ejecutada

Verificacion realizada en el worktree [release-contract-task0](c:/Users/mcros/Documents/obfuscator/.worktrees/release-contract-task0):

1. `Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R'); test_file('tests/testthat/test_release_decision.R')"`
   - resultado: ambos archivos en verde
2. `Rscript tests/testthat.R`
   - resultado: `PASS 198`

## Riesgos y limites conocidos

1. Este paso alinea semantica y mensaje, pero no resuelve todavia todo el flujo de revision manual desde uso programatico.
2. El helper de resultado API usa una postura conservadora por defecto; si en el futuro se agrega un flujo programatico de liberacion externa formal, habra que explicitar ese camino.
3. El trabajo aun no esta integrado en la rama principal.

## Lo que este paso permite concluir

- el snippet de codigo ya no subrepresenta el modelo de privacidad realmente usado;
- ejecutar ofuscacion por API ya no debe interpretarse como “aprobacion” de liberacion externa;
- la coherencia conceptual entre UI y uso programatico queda mas fuerte que antes.

## Lo que este paso no permite concluir

- no implica que exista ya un workflow programatico completo de aprobacion externa;
- no reemplaza futuras pruebas end-to-end sobre codigo generado y uso por terceros;
- no agota la alineacion futura entre UI, API y documentacion publica.

## Impacto sobre presentacion tecnica

### Valor creado

El producto no solo protege datos: tambien reduce riesgo de malinterpretacion operativa por parte de perfiles tecnicos que consuman el sistema desde script o API.

### Riesgo evitado

Se evita que alguien lea “generar codigo” como sinonimo de “dataset listo para compartir”.

### Explicacion simple para terceros tecnicos

> El sistema puede generar codigo para reproducir transformaciones, pero esa reproduccion no equivale por si sola a una aprobacion de liberacion externa. La semantica de release sigue siendo una decision separada y defendible.

## Siguiente paso recomendado

Seguir con el siguiente bloque del plan de implementacion y, cuando corresponda, reflejar este mismo criterio en la documentacion publica y en la demo del producto.

## Trigger de actualizacion

Este documento deberia actualizarse o quedar referenciado por un paso posterior si ocurre cualquiera de estas situaciones:

- integracion del worktree a la rama principal;
- creacion de un flujo programatico formal para artefactos `releasable_external`;
- cambios en el formato del codigo generado o en el contrato del `release_state`.
