# Diseno y plan para numericas institucionales con evidencia y senales

## Fecha

2026-05-22

## Objetivo del paso

Dejar asentado el siguiente bloque de trabajo del helper IA para columnas numericas institucionales que hoy llegan como `double` o `integer`, pero cuyo comportamiento observado puede sugerir codigo tecnico o valor constante.

## Decision principal

No reclasificar automaticamente esas columnas como `codigo numerico`.

En cambio, separar de forma explicita:

1. `tipo importado`
2. `clasificacion programatica`
3. `evidencia observada`
4. `senal heuristica`

## Ajustes de redaccion aprobados

Se fijo este criterio de wording:

- evitar `interpretada como`, porque deja ambiguo el sujeto que interpreta;
- usar `clasificacion programatica`, para dejar claro que la taxonomia visible la produce el helper;
- evitar frases abstractas como `sin variacion observada`;
- preferir evidencia literal como:
  - `evidencia observada: solo toma valores enteros`
  - `evidencia observada: todos los valores observados son iguales: 14`

## Artefactos creados

- diseno:
  - [2026-05-22-diseno-de-evidencia-y-senales-heuristicas-para-numericas-institucionales.md](c:/Users/mcros/Documents/obfuscator/docs/02_diseno/2026-05-22-diseno-de-evidencia-y-senales-heuristicas-para-numericas-institucionales.md)
- plan:
  - [2026-05-22-evidencia-y-senales-heuristicas-para-numericas-institucionales-implementation-plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-22-evidencia-y-senales-heuristicas-para-numericas-institucionales-implementation-plan.md)

## Alcance previsto del siguiente paso

El plan deja priorizado este orden:

1. cambiar el wording visible para numericas;
2. agregar evidencia observada para enteriformes y valores unicos;
3. sumar la senal heuristica prudente `podria funcionar como codigo numerico`;
4. alinear documentacion y cerrar con verificacion.

## Verificacion

No se hicieron cambios de codigo ni se corrieron tests en esta pasada.

La salida de este paso es exclusivamente de diseno y plan.

## Siguiente paso sugerido

Ejecutar `Task 1` del plan sobre [test_ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_ai_dataset_profile.R), fijando primero el wording visible antes de tocar la heuristica de posible codigo numerico.
