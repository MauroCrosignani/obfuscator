# Iteracion 3 de Evaluacion Comparativa de Dispatch de Agentes

**Version:** borrador operativo 0.1  
**Estado:** listo para ejecucion  
**Fecha:** 2026-05-08  
**Marco metodologico base:** `docs/superpowers/specs/2026-05-07-agent-dispatch-evaluation-protocol.md`

---

## 1. Objetivo de la iteracion

La Iteracion 3 busca comparar la variante A y la variante B en una tarea de **contrato y tests**, donde el foco principal no es una UI compleja ni una continuidad sutil, sino la calidad con que el agente:
- formaliza expectativas del modelo;
- define helpers puros;
- y mantiene consistencia semantica entre tests y diseño.

Con esta iteracion cerramos los tres perfiles previstos por el protocolo:
- integracion moderada
- alto riesgo de contexto
- contrato/tests

---

## 2. Tarea elegida

### 2.1 Tarea candidata

La tarea seleccionada para la Iteracion 3 es la **Task 4** del plan:

> Create a release-state helper layer.

### 2.2 Justificacion

Esta tarea es una buena tercera comparacion porque:
- se apoya fuerte en helpers puros;
- depende de leer bien el contrato conceptual del producto;
- obliga a traducir lenguaje de especificacion a estructuras y transiciones concretas;
- y permite una auditoria relativamente limpia sobre tests, nombres y semantica.

### 2.3 Perfil experimental

Dentro de la matriz general del protocolo, esta iteracion representa mejor el tipo:

- `Tarea de contrato o tests`

---

## 3. Requisitos funcionales esperados

La tarea incluye como minimo:
- crear `tests/testthat/test_release_decision.R`
- escribir tests fallidos para estados de liberacion y transiciones
- implementar helpers puros en `R/release_decision_helpers.R`
- si hace falta, tocar `R/shiny_app.R` de forma acotada solo para alineacion con el helper layer
- dejar claro que el estado inicial no habilita exportacion externa

---

## 4. Baseline experimental

### 4.1 Regla de igualdad de condiciones

La variante A y la variante B deben arrancar desde el mismo baseline verde.

### 4.2 Baseline recomendado en ObfuscatoR

Para esta iteracion, el baseline recomendado vuelve a ser el cierre de `Task 0`:

- branch base: `codex/release-contract-task0`
- commit base: `8d132a6`
- descripcion: `feat: define shared release contract`

### 4.3 Motivo de este baseline

La `Task 4` forma parte del arranque del release-state model, así que compararla desde el baseline del contrato compartido evita contaminar la medicion con trabajo posterior de UI o persistencia.

### 4.4 Verificacion previa del baseline

Antes de crear worktrees A/B, correr:

```powershell
git rev-parse --verify 8d132a6
git show --stat --oneline 8d132a6
Rscript tests/testthat.R
```

---

## 5. Worktrees concretos para Iteracion 3

### 5.1 Nombres recomendados

- `c:\Users\mcros\Documents\obfuscator\.worktrees\dispatch-iter3-a-task4`
- `c:\Users\mcros\Documents\obfuscator\.worktrees\dispatch-iter3-b-task4`

### 5.2 Branches recomendadas

- `codex/dispatch-iter3-a-task4`
- `codex/dispatch-iter3-b-task4`

### 5.3 Comandos de creacion

```powershell
git worktree add .worktrees/dispatch-iter3-a-task4 -b codex/dispatch-iter3-a-task4 8d132a6
git worktree add .worktrees/dispatch-iter3-b-task4 -b codex/dispatch-iter3-b-task4 8d132a6
```

---

## 6. Variante A

### 6.1 Descripcion

La Variante A usa dispatch actual.

### 6.2 Prompt A

El prompt debe:
- describir la task;
- indicar archivos de propiedad;
- incluir el objetivo funcional;
- pedir la verificacion focalizada.

Pero no debe incluir:
- checklist de preflight;
- contexto documental sincronizado como regla;
- ni exigencia de citar rutas normativas locales.

### 6.3 Archivos de propiedad sugeridos

Archivos principales:
- `R/release_decision_helpers.R`
- `tests/testthat/test_release_decision.R`

Archivo secundario permitido solo si fuera estrictamente necesario:
- `R/shiny_app.R`

---

## 7. Variante B

### 7.1 Descripcion

La Variante B usa dispatch reforzado.

### 7.2 Precondiciones

Antes del dispatch:
- sincronizar documentacion normativa en el worktree si no estuviera presente;
- verificar rutas reales;
- correr preflight;
- correr premortem corto del prompt.

### 7.3 Documentacion normativa a sincronizar

- `ESPECIFICACION_DE_REQUERIMIENTOS_v3.0.md`
- `docs/AUDITORIA_ESTADO_ACTUAL_2026-05-06.md`
- `docs/superpowers/specs/2026-05-06-liberacion-segura-a-terceros-design.md`
- `docs/superpowers/plans/2026-05-06-liberacion-segura-a-terceros-implementation-plan.md`
- `docs/AGENT_EXECUTION_NOTES.md`

---

## 8. Preflight especifico para esta iteracion

Antes de despachar la Variante B, responder:

1. ¿La Task 4 está citada con suficiente detalle en el prompt?
2. ¿Existen dentro del worktree B los documentos normativos listados arriba?
3. ¿Las rutas del prompt apuntan al worktree correcto?
4. ¿Está claro que el foco principal está en helpers puros y contrato de estados?
5. ¿Está claro que el estado inicial no puede permitir exportacion externa?
6. ¿Está claro qué archivos son de propiedad y cuáles no?
7. ¿El criterio de éxito pide explícitamente la verificación focalizada?

---

## 9. Premortem corto del prompt B

Para esta iteracion, el premortem corto del prompt debe cubrir al menos:

- el agente escribe tests que validan solo nombres pero no semantica de transicion
- el agente crea helpers inconsistentes con el lenguaje de la spec
- el agente implementa estado “liberable” demasiado liviano
- el agente toca UI innecesariamente en vez de mantener el helper layer puro
- el agente deja una capa de contrato util solo para tests y no para uso real

---

## 10. Prompt concreto para Variante A

```text
Implementa la Task 4 del plan en este worktree.

Proyecto: ObfuscatoR
Tarea: Create a release-state helper layer

Worktree:
<RUTA_WORKTREE_A>

Archivos principales de tu propiedad:
- R/release_decision_helpers.R
- tests/testthat/test_release_decision.R

Archivo secundario permitido solo si concluyes que es estrictamente necesario:
- R/shiny_app.R

No estas solo en el codebase. No reviertas cambios ajenos ni toques archivos fuera de esta task salvo que sea estrictamente necesario y lo justifiques.

Objetivo funcional:
- escribir tests fallidos para estados de liberacion y transiciones
- implementar los helpers puros minimos para soportarlos
- asegurar que el estado inicial no habilita exportacion externa
- mantener la solucion acotada a esta task

Pasos esperados:
1. usa TDD
2. mantenete acotado a esta task
3. corre la verificacion focalizada

Verificacion requerida:
Rscript -e "library(testthat); test_file('tests/testthat/test_release_decision.R')"

Trabaja directamente en ese worktree y al final reporta:
- status: DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED
- archivos cambiados
- comandos de verificacion corridos y resultado
- cualquier preocupacion relevante
```

---

## 11. Prompt concreto para Variante B

```text
Implementa la Task 4 del plan en este worktree usando la documentacion normativa local presente en disco como fuente principal de contexto.

Proyecto: ObfuscatoR
Tarea: Create a release-state helper layer

Worktree:
<RUTA_WORKTREE_B>

Documentacion normativa disponible dentro del worktree:
- <RUTA_WORKTREE_B>/ESPECIFICACION_DE_REQUERIMIENTOS_v3.0.md
- <RUTA_WORKTREE_B>/docs/AUDITORIA_ESTADO_ACTUAL_2026-05-06.md
- <RUTA_WORKTREE_B>/docs/superpowers/specs/2026-05-06-liberacion-segura-a-terceros-design.md
- <RUTA_WORKTREE_B>/docs/superpowers/plans/2026-05-06-liberacion-segura-a-terceros-implementation-plan.md
- <RUTA_WORKTREE_B>/docs/AGENT_EXECUTION_NOTES.md

Usa esas rutas reales del worktree. No asumas contexto del workspace principal ni de archivos que no existan en este worktree.

Archivos principales de tu propiedad:
- R/release_decision_helpers.R
- tests/testthat/test_release_decision.R

Archivo secundario permitido solo si concluyes que es estrictamente necesario:
- R/shiny_app.R

No estas solo en el codebase. No reviertas cambios ajenos ni toques archivos fuera de esta task salvo que sea estrictamente necesario y lo justifiques.

Objetivo funcional:
- escribir tests fallidos para estados de liberacion y transiciones
- implementar los helpers puros minimos para soportarlos
- asegurar que el estado inicial no habilita exportacion externa
- mantener la solucion acotada a esta task

Restricciones metodologicas:
- usa TDD
- mantén el foco en contrato puro, no en parchear UI sin necesidad
- alinea nombres, estados y transiciones con la especificacion del producto
- evita helpers que solo “hagan pasar el test” sin dejar una capa reutilizable

Verificacion requerida:
Rscript -e "library(testthat); test_file('tests/testthat/test_release_decision.R')"

Trabaja directamente en ese worktree y al final reporta:
- status: DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED
- archivos cambiados
- comandos de verificacion corridos y resultado
- que partes del plan/spec/notas consultaste
- cualquier preocupacion sobre semantica, transiciones o contexto
```

