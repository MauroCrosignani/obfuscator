# Retrospectiva - Bloque de estados, riesgo y revision auditable

## Resumen ejecutivo

- fecha: 2026-05-09
- estado: retrospectiva consolidada sobre trabajo ya estable
- alcance: estados de release, gating, heuristicas de riesgo, reenlazabilidad y revision manual
- conclusion practica: este bloque convirtio a ObfuscatoR en algo mas cercano a una herramienta de decision de liberacion que a una app que solo transforma datos.

## Proposito

Preservar en forma compacta pero defendible las decisiones ya firmes del bloque que introdujo:

- el estado explicito de liberacion;
- la separacion entre artefacto interno y salida externamente liberable;
- el bloqueo por riesgo;
- y la revision manual como evidencia, no como clic superficial.

## Alcance cubierto

Este bloque resume principalmente los siguientes hitos de la rama [release-contract-task0](c:/Users/mcros/Documents/obfuscator/.worktrees/release-contract-task0):

- `3c6fb73` `feat: add release state and export gating`
- `94bcccb` `feat: add release risk heuristics`
- `ead8de6` `feat: detect high-dimensional relinkability`
- `062d835` `feat: add auditable manual review requirements`

## Problema que resolvia

Teniamos ya ofuscacion, `k-anonymity` y una UI mas ordenada, pero todavia faltaba algo central:

- decidir cuando una salida seguia siendo solo trabajo interno;
- cuando podia aspirar a ser externamente liberable;
- y por que razon concreta debia bloquearse.

Sin este bloque, la app podia parecer una herramienta de transformacion con algunos controles, pero no una herramienta defendible de liberacion segura.

## Decisiones tomadas

### 1. Introducir estados explicitos de release

Se definieron estados como:

- `No evaluado`
- `En revision`
- `Bloqueado`
- `Liberable`
- `No liberable sin rediseno`

Motivo:

- hacer visible que la liberacion es una decision de workflow, no un efecto colateral de ejecutar ofuscacion.

### 2. Bloquear exportacion externa salvo estado `Liberable`

La exportacion CSV se acoplo al estado de release y no solo a que existiera un resultado transformado.

Motivo:

- impedir la confusion entre "se pudo producir un dataset" y "ese dataset se puede compartir con terceros".

### 3. Tratar el riesgo en mas de una capa

Se incorporaron heuristicas para:

- patrones nominales de alto riesgo;
- texto libre;
- columnas sospechosas de alta cardinalidad;
- combinaciones pequenas por debajo de `k`;
- homogeneidad sensible aun cuando `k` se cumpla;
- combinaciones demasiado precisas y vinculables;
- reenlazabilidad por alta dimensionalidad cuando el tercero ya conoce muchas variables de origen.

Motivo:

- en los casos reales de la organizacion, sacar identificadores directos no alcanza;
- el riesgo esta muchas veces en la combinacion de rasgos y en la posibilidad de enlazar con la fuente original.

### 4. Modelar la revision manual como evidencia verificable

No se adopto un modelo de "el usuario aprueba y listo". En cambio, se empezo a estructurar:

- tipo de revision requerida;
- objeto revisado;
- verificacion explicita;
- evidencia asociada.

Motivo:

- la herramienta debia ser defendible incluso frente a un uso descuidado;
- la revision manual tenia que aportar trazabilidad, no discrecionalidad opaca.

## Alternativas consideradas

### Confiar solo en `k-anonymity`

Se descarto porque ya habia evidencia y casos reales donde `k` puede cumplirse sin resolver riesgo residual suficiente.

### Limitar combinaciones de riesgo a 1, 2 o 3 columnas sin mas

Se uso como baseline, pero no como respuesta completa. Fue necesario agregar reenlazabilidad de alta dimensionalidad para cubrir escenarios donde el tercero ya conoce muchas variables descriptivas.

### Permitir exportar con advertencia fuerte

Se descarto por criterio conceptual del proyecto: ante duda material no resuelta, la app debe bloquear.

## Implementacion realizada

En este bloque se agrego:

- state machine puro de release;
- gating de exportacion externa;
- separacion de artefacto interno vs externamente liberable;
- heuristicas de columnas y combinaciones de alto riesgo;
- deteccion de reenlazabilidad por dataset fuente conocido;
- requirements de revision manual auditable.

## Verificacion ejecutada en su momento

La evidencia quedo en la rama de implementacion a traves de:

- `tests/testthat/test_release_decision.R`
- escenarios realistas en `tests/testthat/test_release_realistic_scenarios.R`
- y corridas completas de `Rscript tests/testthat.R`

Posteriormente, las iteraciones siguientes del plan siguieron pasando sobre esta base, lo que refuerza que el bloque quedo estable.

## Valor creado

Este bloque introdujo el corazon metodologico del producto:

- la app ya no solo transforma;
- decide, bloquea y explica.

Tambien acerco mucho la herramienta al caso institucional real donde el tercero puede conocer o haber aportado ya una gran cantidad de variables descriptivas.

## Riesgo evitado

Se evito presentar como segura una salida que solo hubiera pasado por ofuscacion y por `k-anonymity` basico, pero siguiera siendo reenlazable o peligrosamente singular.

## Explicacion simple para terceros tecnicos

> La app paso de "ofuscar datos" a evaluar si una salida puede compartirse. Para eso no alcanza con sacar nombres ni con cumplir una sola metrica: tambien se mira riesgo residual, combinaciones raras y posibilidad de reenlazar con datos ya conocidos.

## Siguiente paso historico que habilito

Este bloque habilito directamente:

- reportes legibles de liberacion y no liberacion;
- alineacion del codigo generado con la semantica de release;
- y la limpieza posterior de README(s) y narrativa publica.
