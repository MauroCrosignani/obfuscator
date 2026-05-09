# Retrospectiva - Bloque fundacional del modelo release-safe

## Resumen ejecutivo

- fecha: 2026-05-09
- estado: retrospectiva consolidada sobre trabajo ya estable
- alcance: contrato compartido, continuidad de persistencia, simplificacion de parametros y correccion de nombre de dataset
- conclusion practica: este bloque fue el que transformo a ObfuscatoR desde una app con buenas piezas aisladas hacia un sistema con contrato comun, continuidad de configuracion y una UI menos contradictoria.

## Proposito

Este documento reconstruye retrospectivamente un conjunto de tasks ya completados cuyo resultado se considera suficientemente firme como para preservarlo en la documentacion del proyecto antes de que se pierda contexto de trabajo.

En lugar de dejar cada task solo en commits y conversacion, se resume aqui el bloque funcional que hizo posible el resto del modelo de liberacion segura.

## Alcance cubierto

Este bloque resume principalmente los siguientes hitos de la rama [release-contract-task0](c:/Users/mcros/Documents/obfuscator/.worktrees/release-contract-task0):

- `8d132a6` `feat: define shared release contract`
- `fea06ad` `test: define canonical release UI expectations`
- `dacae96` `feat: preserve release-safe template persistence`
- `d1a2aa6` `feat: unify release parameters UI`

## Problema que resolvia

Antes de este bloque, el proyecto tenia varios sintomas de fragmentacion:

- la UI mezclaba mas de un modelo de parametros;
- el nombre del dataset cargado no reflejaba con claridad el origen real;
- la persistencia JSON podia contaminarse con estado de release o revision que no debia viajar como plantilla reusable;
- y la semantica de liberacion no tenia todavia un contrato puro capaz de sobrevivir fuera de la app.

Eso hacia que cualquier avance posterior en bloqueo, riesgo o auditoria se apoyara sobre una base todavia inestable.

## Decisiones tomadas

### 1. Definir un contrato compartido de release en helpers puros

Se eligio crear una capa focalizada en [R/release_decision_helpers.R](c:/Users/mcros/Documents/obfuscator/.worktrees/release-contract-task0/R/release_decision_helpers.R) en lugar de dejar que la politica de release naciera dispersa dentro de la reactividad de la app.

Motivo:

- permitia testear la semantica sin depender de una sesion Shiny;
- daba una base comun para UI, codigo generado y uso programatico;
- reducia el riesgo de divergencia entre caminos de uso.

### 2. Tratar la persistencia como contrato de continuidad, no como detalle tardio

Se mantuvo la persistencia por hash de esquema y fuzzy recovery, pero separando explicitamente:

- lo que es plantilla reusable de clasificacion;
- de lo que es artefacto restringido de release o revision.

Motivo:

- evitar que offsets, estado de release o evidencia de revision se guarden como si fueran configuracion inocua;
- preservar una continuidad ya valiosa para la experiencia de la app.

### 3. Unificar el panel de parametros

Se eligio eliminar duplicaciones visibles y canonizar defaults unicos para:

- `k_value`
- `id_prefix`
- `project_key`
- `numeric_mode`

Motivo:

- dos paneles de parametros con semantica parcialmente solapada eran una fuente de confusion real;
- cualquier decision posterior de release iba a ser menos defendible sobre una UI duplicada.

### 4. Corregir el nombre visible del dataset cargado

Se introdujo una fuente canonica de nombre cargado para reflejar mejor el origen del dataset en la UI.

Motivo:

- era un bug de claridad visible;
- afectaba la confiabilidad de la app en demo y uso real.

## Alternativas consideradas

### Mantener la persistencia para mas adelante

Se descarto porque la persistencia y el fuzzy matching ya eran parte del valor percibido del producto. Romperlos para luego "arreglarlos" habria degradado continuidad y pruebas.

### Resolver la UI solo con etiquetas o cambios cosmeticos

Se descarto porque el problema no era solo de texto. Habia duplicacion de estado y defaults incompatibles.

### Dejar el contrato de release dentro de la app hasta completar el MVP

Se descarto porque el premortem y la auditoria mostraron que esa ruta aumentaba mucho el riesgo de divergencia entre UI, API y codigo generado.

## Implementacion realizada

En este bloque se incorporo:

- contrato puro de estados y artefactos de release;
- pruebas de contrato y expectativas canonicas de UI;
- persistencia segura de plantillas JSON bajo el nuevo modelo;
- recuperacion por esquema y fuzzy matching preservadas;
- extraccion de helpers UI testeables;
- un solo panel de parametros con defaults unificados;
- nombre de dataset cargado resuelto de forma consistente.

## Verificacion ejecutada en su momento

La evidencia de ese bloque quedo en la rama de implementacion mediante:

- `tests/testthat/test_release_contract.R`
- `tests/testthat/test_persistence_release_flow.R`
- `tests/testthat/test_obfuscator.R`
- y sucesivas corridas de `Rscript tests/testthat.R`

Mas adelante, sobre esa misma base, la suite completa siguio pasando en iteraciones posteriores, lo que refuerza que este bloque se mantuvo estable.

## Valor creado

Este bloque no era vistoso, pero fue estructural. Hizo tres cosas decisivas:

1. bajo el riesgo de contradiccion entre caminos de uso;
2. preservo continuidad de la experiencia de clasificacion;
3. limpio el terreno para que bloqueo, riesgo y auditoria se apoyaran en una base coherente.

## Riesgo evitado

Se evito un escenario muy probable: construir una capa sofisticada de liberacion segura sobre una app que seguia teniendo persistencia mezclada, parametros duplicados y semantica repartida.

## Explicacion simple para terceros tecnicos

> Antes de endurecer decisiones de privacidad, primero se ordeno el contrato comun, la persistencia y la UI basica. Eso permitio que las siguientes capas de bloqueo y auditoria no fueran parches sobre una base contradictoria.

## Siguiente paso historico que habilito

Este bloque habilito directamente:

- estados de liberacion y gating de exportacion;
- heuristicas de riesgo;
- deteccion de reenlazabilidad;
- revision manual auditable;
- reportes de liberacion y no liberacion.
