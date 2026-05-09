# Iteracion 2 de Evaluacion Comparativa de Dispatch de Agentes

**Version:** borrador operativo 0.1  
**Estado:** listo para ejecucion  
**Fecha:** 2026-05-08  
**Marco metodologico base:** `docs/superpowers/specs/2026-05-07-agent-dispatch-evaluation-protocol.md`

---

## 1. Objetivo de la iteracion

La Iteracion 2 busca comparar la variante A y la variante B en una tarea de **alto riesgo de contexto y continuidad**, donde el error mas peligroso no es un fallo obvio de tests sino una regresion silenciosa en persistencia o una mala lectura del contrato del producto.

Esta iteracion debe ayudarnos a responder si el dispatch reforzado:
- reduce soluciones localmente correctas pero globalmente frágiles;
- mejora la lectura de notas de ejecucion y excepciones del plan;
- y captura mejor restricciones de continuidad que no estan concentradas en un solo helper.

---

## 2. Tarea elegida

### 2.1 Tarea candidata

La tarea seleccionada para la Iteracion 2 es la **Task 10** del plan:

> Preserve persistence JSON and fuzzy matching under the release model.

### 2.2 Justificacion

Esta tarea es una buena segunda comparacion porque:
- tiene mas dependencia de contexto normativo que la Iteracion 1;
- involucra continuidad y compatibilidad, no solo comportamiento visible inmediato;
- el propio plan indica una nota de ejecucion especial que puede perderse facilmente;
- y obliga a distinguir entre artefactos persistibles normales y artefactos restringidos del flujo de liberacion.

### 2.3 Perfil experimental

Dentro de la matriz general del protocolo, esta iteracion representa mejor el tipo:

- `Tarea con ambiguedad o alto riesgo de contexto`

No es una tarea ideal para medir solo velocidad. Es una tarea ideal para medir:
- comprension de restricciones;
- lectura del plan;
- y riesgo de romper continuidad silenciosamente.

---

## 3. Requisitos funcionales esperados

La tarea incluye como minimo:
- crear `tests/testthat/test_persistence_release_flow.R`
- escribir tests fallidos para persistencia y fuzzy continuity
- conservar la persistencia basada en `schema hash`
- conservar la recuperacion fuzzy
- evitar que metadata de release/review se persista como si fuera una plantilla comun
- dejar documentado en codigo que se persiste y que no se persiste

---

## 4. Baseline experimental

### 4.1 Regla de igualdad de condiciones

La variante A y la variante B deben arrancar desde el mismo baseline verde.

### 4.2 Baseline recomendado en ObfuscatoR

Para esta iteracion, el baseline recomendado es el cierre de `Task 0`:

- branch base: `codex/release-contract-task0`
- commit base: `8d132a6`
- descripcion: `feat: define shared release contract`

### 4.2.1 Nota de ejecucion real

En la ejecucion efectivamente realizada, el baseline recomendado se mantuvo sin cambios:

- commit usado: `8d132a6`
- descripcion: `feat: define shared release contract`

Esto fue util porque la propia `Task 10` pide ejecutarse inmediatamente despues del baseline del contrato, antes de simplificaciones mayores de UI.

### 4.3 Motivo de este baseline

La `Task 10` tiene una nota explicita en el plan:

- debe ejecutarse inmediatamente despues del baseline del contrato compartido
- antes de considerar segura la simplificacion principal de la UI

Por eso, a diferencia de la Iteracion 1, aqui no conviene basarse en el checkpoint rojo de `Task 1`.

### 4.4 Verificacion previa del baseline

Antes de crear worktrees A/B, correr:

```powershell
git rev-parse --verify 8d132a6
git show --stat --oneline 8d132a6
```

Y verificar el baseline con:

```powershell
Rscript tests/testthat.R
```

Solo si sigue verde debe lanzarse la comparacion.

---

## 5. Worktrees concretos para Iteracion 2

### 5.1 Nombres recomendados

- `c:\Users\mcros\Documents\obfuscator\.worktrees\dispatch-iter2-a-task10`
- `c:\Users\mcros\Documents\obfuscator\.worktrees\dispatch-iter2-b-task10`

### 5.2 Branches recomendadas

- `codex/dispatch-iter2-a-task10`
- `codex/dispatch-iter2-b-task10`

### 5.3 Comandos de creacion

```powershell
git worktree add .worktrees/dispatch-iter2-a-task10 -b codex/dispatch-iter2-a-task10 8d132a6
git worktree add .worktrees/dispatch-iter2-b-task10 -b codex/dispatch-iter2-b-task10 8d132a6
```

### 5.4 Regla de aislamiento

La iteracion no debe ejecutarse sobre:
- el workspace principal
- `release-contract-task0`
- ni los worktrees de la Iteracion 1

---

## 6. Variante A

### 6.1 Descripcion

La Variante A usa dispatch actual.

### 6.2 Prompt A

El prompt debe:
- describir la task
- indicar archivos de propiedad principales
- incluir el objetivo funcional
- pedir la verificacion focalizada

Pero no debe incluir:
- checklist de preflight
- sincronizacion documental reforzada como protocolo
- ni exigencia de citar documentacion normativa local

### 6.3 Archivos de propiedad sugeridos

Archivos principales:
- `R/shiny_app.R`
- `tests/testthat/test_persistence_release_flow.R`

Archivo secundario permitido solo si el agente concluye que es estrictamente necesario:
- `R/obfuscator_core.R`

Eso debe aplicarse igual en A y en B para no sesgar el experimento.

---

## 7. Variante B

### 7.1 Descripcion

La Variante B usa dispatch reforzado.

### 7.2 Precondiciones

Antes del dispatch:
- sincronizar documentacion normativa en el worktree si no estuviera presente;
- verificar rutas reales dentro del worktree;
- correr preflight del prompt;
- correr un premortem corto del prompt.

### 7.3 Documentacion normativa a sincronizar

- `ESPECIFICACION_DE_REQUERIMIENTOS_v3.0.md`
- `docs/AUDITORIA_ESTADO_ACTUAL_2026-05-06.md`
- `docs/superpowers/specs/2026-05-06-liberacion-segura-a-terceros-design.md`
- `docs/superpowers/plans/2026-05-06-liberacion-segura-a-terceros-implementation-plan.md`
- `docs/AGENT_EXECUTION_NOTES.md`

### 7.4 Razon para incluir notas de ejecucion

En esta iteracion, `docs/AGENT_EXECUTION_NOTES.md` pasa a ser contexto normativo secundario porque ya contiene una leccion real:
- el valor de sincronizar documentacion en worktrees antes del dispatch

---

## 8. Preflight especifico para esta iteracion

Antes de despachar la Variante B, responder:

1. ¿La Task 10 está citada con suficiente detalle en el prompt?
2. ¿El prompt menciona la nota especial del plan que pide adelantar esta task?
3. ¿Existen dentro del worktree B los documentos normativos definidos arriba?
4. ¿Las rutas del prompt apuntan al worktree B y no al workspace principal?
5. ¿Está claro qué se puede persistir y qué no debe persistirse?
6. ¿Está claro que el agente no debe “resolver” la task persistiendo artefactos restringidos por comodidad?
7. ¿El criterio de éxito pide explícitamente la verificación focalizada?

---

## 9. Premortem corto del prompt B

Para esta iteracion, el premortem corto del prompt debe cubrir al menos estos modos de falla:

- el agente conserva la persistencia feliz pero rompe el fuzzy matching
- el agente hace pasar tests de persistencia sin proteger la separacion entre plantillas comunes y artefactos restringidos
- el agente asume que todo lo serializable debe persistirse
- el agente modifica solo UI y deja inconsistente el helper real de persistencia
- el agente ignora la nota del plan que adelanta esta task y la trata como un ajuste cosmético tardío
- el agente usa el workspace principal como referencia y no el worktree

Si el prompt no protege razonablemente contra eso, debe corregirse antes del dispatch B.

---

## 10. Secuencia operativa exacta

### 10.1 Preparar baseline

```powershell
git rev-parse --verify 8d132a6
git worktree add .worktrees/dispatch-iter2-a-task10 -b codex/dispatch-iter2-a-task10 8d132a6
git worktree add .worktrees/dispatch-iter2-b-task10 -b codex/dispatch-iter2-b-task10 8d132a6
```

### 10.2 Verificar ambos worktrees

```powershell
git -C .worktrees/dispatch-iter2-a-task10 status --short
git -C .worktrees/dispatch-iter2-b-task10 status --short
Rscript .worktrees/dispatch-iter2-a-task10/tests/testthat.R
Rscript .worktrees/dispatch-iter2-b-task10/tests/testthat.R
```

### 10.3 Ejecutar Variante A

Pasos:
1. lanzar el agente con `Prompt A`
2. esperar primera entrega
3. auditar diff y verificaciones
4. registrar resultados

### 10.4 Ejecutar Variante B

Pasos:
1. sincronizar documentos
2. completar checklist de preflight
3. correr premortem corto del prompt
4. lanzar el agente con `Prompt B`
5. auditar diff y verificaciones con el mismo rigor aplicado a A
6. registrar resultados

---

## 11. Prompt concreto para Variante A

```text
Implementa la Task 10 del plan en este worktree.

Proyecto: ObfuscatoR
Tarea: Preserve persistence JSON and fuzzy matching under the release model

Worktree:
<RUTA_WORKTREE_A>

Archivos principales de tu propiedad:
- R/shiny_app.R
- tests/testthat/test_persistence_release_flow.R

Archivo secundario permitido solo si concluyes que es estrictamente necesario:
- R/obfuscator_core.R

No estas solo en el codebase. No reviertas cambios ajenos ni toques archivos fuera de esta task salvo que sea estrictamente necesario y lo justifiques.

Objetivo funcional:
- escribir tests fallidos para persistencia y continuidad fuzzy
- mantener la persistencia basada en schema hash
- mantener la recuperacion fuzzy
- evitar que metadata de release/review se persista como si fuera una plantilla comun
- dejar documentado en codigo que se persiste y que no se persiste

Pasos esperados:
1. usa TDD
2. mantente acotado a esta task
3. corre la verificacion focalizada

Verificacion requerida:
Rscript -e "library(testthat); test_file('tests/testthat/test_persistence_release_flow.R')"

Trabaja directamente en ese worktree y al final reporta:
- status: DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED
- archivos cambiados
- comandos de verificacion corridos y resultado
- cualquier preocupacion relevante
```

---

## 12. Prompt concreto para Variante B

```text
Implementa la Task 10 del plan en este worktree usando la documentacion normativa local presente en disco como fuente principal de contexto.

Proyecto: ObfuscatoR
Tarea: Preserve persistence JSON and fuzzy matching under the release model

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
- R/shiny_app.R
- tests/testthat/test_persistence_release_flow.R

Archivo secundario permitido solo si concluyes que es estrictamente necesario:
- R/obfuscator_core.R

No estas solo en el codebase. No reviertas cambios ajenos ni toques archivos fuera de esta task salvo que sea estrictamente necesario y lo justifiques.

Objetivo funcional:
- escribir tests fallidos para persistencia y continuidad fuzzy
- mantener la persistencia basada en schema hash
- mantener la recuperacion fuzzy
- evitar que metadata de release/review se persista como si fuera una plantilla comun
- dejar documentado en codigo que se persiste y que no se persiste

Restricciones metodologicas:
- usa TDD
- toma en cuenta la nota del plan que adelanta esta task inmediatamente despues del baseline del contrato
- no trates cualquier objeto serializable como persistible por defecto
- no arregles el test de forma artificial si eso deja borrosa la frontera entre plantillas comunes y artefactos restringidos
- manten la solucion acotada a esta task

Verificacion requerida:
Rscript -e "library(testthat); test_file('tests/testthat/test_persistence_release_flow.R')"

Trabaja directamente en ese worktree y al final reporta:
- status: DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED
- archivos cambiados
- comandos de verificacion corridos y resultado
- que partes del plan/spec/notas consultaste
- cualquier preocupacion sobre continuidad, persistencia o contexto
```

---

## 13. Resultado esperado de la iteracion

Al finalizar la Iteracion 2 deberiamos poder responder:

- si el dispatch reforzado ayuda mas cuando la complejidad es de continuidad y no de UI inmediata
- si el preflight + premortem corto del prompt mejora la calidad del trabajo
- y si la documentacion sincronizada reduce errores silenciosos en tareas de persistencia
