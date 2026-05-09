# Iteracion 1 de Evaluacion Comparativa de Dispatch de Agentes

**Version:** borrador operativo 0.1  
**Estado:** listo para ejecucion cuando se decida correr la comparacion  
**Fecha:** 2026-05-07  
**Marco metodologico base:** `docs/superpowers/specs/2026-05-07-agent-dispatch-evaluation-protocol.md`

---

## 1. Objetivo de la iteracion

La Iteracion 1 busca comparar la variante A y la variante B en una tarea de **integracion moderada y acotada**, donde:
- haya dependencia real de especificacion y plan;
- exista verificacion objetiva;
- y el resultado pueda auditarse con relativa claridad.

El objetivo no es decidir todavia si la mejora se institucionaliza, sino obtener la primera evidencia comparable de:
- calidad tecnica;
- robustez de contexto;
- retrabajo requerido;
- y valor agregado de la auditoria posterior.

---

## 2. Tarea elegida

### 2.1 Tarea candidata

La tarea seleccionada para la Iteracion 1 es la actual **Task 2** del plan:

> Introduce canonical UI helper defaults and dataset-name resolution.

### 2.2 Justificacion

Esta tarea es una buena primera comparacion porque:
- no es trivial, pero tampoco demasiado grande;
- toca tanto helpers puros como cableado con estado de la app;
- depende de leer correctamente el plan y la especificacion;
- y tiene un criterio de verificacion concreto mediante tests focalizados.

### 2.3 Requisitos funcionales esperados

La tarea incluye:
- crear `studio_parameter_defaults()`;
- crear `resolve_dataset_display_name(...)`;
- actualizar el flujo de carga para almacenar un nombre canonico del dataset;
- dejar de usar `input$dataset_name` en el chip hero correspondiente;
- y lograr que los tests agregados en `Task 1` pasen.

---

## 3. Baseline experimental

### 3.1 Regla de igualdad de condiciones

La variante A y la variante B deben correr desde el **mismo baseline funcional**.

Eso significa:
- mismo commit de partida;
- mismo contenido del repositorio;
- mismo estado de tests;
- y worktrees separados para evitar contaminacion cruzada.

### 3.2 Baseline recomendado

Se recomienda correr la iteracion solo despues de que el estado previo quede congelado en un commit claro.

Idealmente:
- `Task 0` aprobada y committeada;
- `Task 1` en el estado que se decida usar como punto de partida comun;
- sin mezclar cambios parciales no consolidados entre una variante y otra.

### 3.3 Estructura recomendada

Usar:
- un worktree para `Iteracion1-A`;
- un worktree para `Iteracion1-B`;
- ambos creados desde el mismo commit base.

---

## 4. Variante A

### 4.1 Descripcion

La Variante A usa el dispatch actual, sin refuerzo metodologico especial.

### 4.2 Prompt A

El prompt debe:
- describir la tarea;
- indicar archivos de propiedad;
- incluir el objetivo funcional;
- y pedir verificaciones.

Pero no debe incluir:
- checklist de preflight;
- sincronizacion documental reforzada como regla explicitada;
- ni auditoria posterior obligatoria como parte del protocolo de la variante.

### 4.3 Instrucciones minimas del prompt A

Debe incluir:
- nombre de la tarea;
- branch/worktree;
- archivos a modificar;
- pasos de la task;
- requerimiento de TDD si corresponde;
- verificacion esperada;
- formato de reporte final del agente.

---

## 5. Variante B

### 5.1 Descripcion

La Variante B usa dispatch reforzado.

### 5.2 Precondiciones

Antes del dispatch:
- sincronizar la documentacion normativa en el worktree si no estuviera presente por git;
- verificar rutas reales dentro del worktree;
- correr un preflight del prompt;
- y, si la tarea lo amerita, un premortem corto del prompt.

### 5.3 Prompt B

El prompt B debe contener todo lo del A, mas:
- rutas reales del worktree a spec, plan y auditoria;
- una nota explícita de que el agente debe apoyarse en esos archivos;
- confirmacion de que el baseline documental esta presente localmente;
- y criterio de trazabilidad esperado en su reporte.

### 5.4 Auditoria obligatoria

En la Variante B, la auditoria posterior no es opcional.

Debe incluir:
- revision tecnica del diff;
- rerun de verificaciones clave por el controlador;
- y evaluacion de brechas entre autorevision y hallazgos reales.

---

## 6. Preflight especifico para esta iteracion

Antes de despachar la Variante B, responder:

1. ¿La `Task 2` esta citada con suficiente detalle en el prompt?
2. ¿Existen dentro del worktree:
   - la especificacion v3.0,
   - la auditoria,
   - el design doc,
   - y el implementation plan?
3. ¿Las rutas en el prompt apuntan al worktree correcto?
4. ¿Se aclara que el agente no debe tocar archivos fuera de la task?
5. ¿El criterio de exito menciona explicitamente que deben pasar los tests agregados en Task 1?
6. ¿Hay algun riesgo de que el agente implemente los helpers pero deje inconsistencias en el flujo real de carga?

---

## 7. Premortem corto del prompt

Para esta iteracion, el premortem corto del prompt debe mirar al menos estos modos de falla:
- el agente implementa solo los helpers, pero no actualiza el estado reactivo real;
- el agente hace pasar los tests de forma artificial sin corregir el comportamiento;
- el agente toca mas UI de la necesaria;
- el agente usa contexto del workspace principal y no del worktree;
- el agente rompe el flujo actual de carga al introducir el nombre del dataset.

Si el prompt no protege razonablemente contra esos riesgos, debe corregirse antes del dispatch B.

---

## 8. Metricas a registrar en esta iteracion

### 8.1 Calidad tecnica
- ¿Se implemento todo lo pedido?
- ¿Los tests focalizados pasan?
- ¿Hay regresiones visibles?

### 8.2 Calidad de contexto
- ¿El agente uso correctamente la documentacion?
- ¿Mostro confusion sobre el estado del repo o del worktree?
- ¿Pidio aclaraciones relevantes o evitables?

### 8.3 Costo operativo
- tiempo hasta primera entrega;
- tiempo total hasta aprobacion;
- cantidad de rondas de correccion;
- esfuerzo de auditoria posterior.

### 8.4 Calidad de auditoria
- cantidad de hallazgos detectados en auditoria;
- cantidad de esos hallazgos no detectados por el propio agente;
- gravedad de los hallazgos.

### 8.5 Trazabilidad
- claridad del reporte final del agente;
- claridad sobre que verifico;
- claridad sobre que no verifico;
- facilidad para heredar el trabajo en una sesion futura.

---

## 9. Criterio de comparacion para Iteracion 1

La variante B se considera superior en esta iteracion si muestra una mejora material en una o varias de estas dimensiones:
- menos hallazgos relevantes en auditoria;
- menos retrabajo;
- mejor uso del contexto documental;
- reporte final mas trazable;
- o misma calidad tecnica con menor correccion posterior.

La variante B no gana automaticamente solo por ser mas pesada metodologicamente.

Si agrega mucho costo sin reducir defectos o retrabajo, debe considerarse que no mejoro de forma suficiente.

---

## 10. Plantilla resumida de registro para Iteracion 1

### 10.1 Variante A
- Baseline:
- Worktree:
- Prompt usado:
- Tiempo hasta primera entrega:
- Tiempo total:
- Tests corridos por el agente:
- Hallazgos en auditoria:
- Retrabajo requerido:
- Evaluacion global:

### 10.2 Variante B
- Baseline:
- Worktree:
- Prompt usado:
- Preflight realizado:
- Premortem corto realizado:
- Tiempo hasta primera entrega:
- Tiempo total:
- Tests corridos por el agente:
- Hallazgos en auditoria:
- Retrabajo requerido:
- Evaluacion global:

### 10.3 Comparacion final
- Ganador de la iteracion:
- Diferencia principal observada:
- Leccion metodologica:
- Cambio recomendado antes de la Iteracion 2:

---

## 11. Secuencia recomendada de ejecucion

1. congelar el baseline comun;
2. crear dos worktrees hermanos desde ese baseline;
3. verificar que ambos worktrees abran con el mismo estado inicial;
4. correr la Variante A y registrar su ejecucion;
5. correr la Variante B y registrar su ejecucion;
6. auditar ambas entregas con el mismo rigor;
7. completar la comparacion final en el registro acumulativo.

---

## 12. Baseline operativo concreto para esta iteracion

### 12.1 Regla de seleccion del baseline

El baseline de la Iteracion 1 debe ser un commit que cumpla simultaneamente:
- `Task 0` aprobada y committeada;
- suite de tests verde en ese punto;
- sin cambios experimentales de `Task 2` ya mezclados en el arbol;
- y suficientemente cercano al estado actual como para que la tarea siga siendo representativa.

### 12.2 Baseline recomendado en ObfuscatoR

Para esta iteracion, el baseline recomendado es el commit de cierre de `Task 0`:

- branch base: `codex/release-contract-task0`
- commit base esperado: `8d132a6`
- descripcion: `feat: define shared release contract`

Si antes de correr la comparacion apareciera un commit posterior que cambie el contexto de `Task 2`, la iteracion debe revalidarse antes de ejecutarse.

### 12.2.1 Nota de ejecucion real

En la ejecucion efectivamente realizada el baseline final fue:

- commit usado: `fea06ad`
- descripcion: `test: define canonical release UI expectations`

Motivo:
- para comparar de forma justa la implementacion de `Task 2`, se fijo primero `Task 1` como checkpoint rojo comun;
- eso evito tener que reproducir manualmente el mismo estado fallido en cada worktree experimental.

### 12.3 Verificacion previa del baseline

Antes de crear worktrees A/B, correr:

```powershell
git rev-parse --verify 8d132a6
git show --stat --oneline 8d132a6
```

Y luego verificar en el worktree o branch base:

```powershell
Rscript tests/testthat.R
```

Solo si ese baseline sigue verde debe lanzarse la comparacion.

---

## 13. Worktrees concretos para Iteracion 1

### 13.1 Nombres recomendados

Para evitar confusiones con el worktree de implementacion principal, usar dos worktrees nuevos y explicitamente experimentales:

- `c:\Users\mcros\Documents\obfuscator\.worktrees\dispatch-iter1-a-task2`
- `c:\Users\mcros\Documents\obfuscator\.worktrees\dispatch-iter1-b-task2`

### 13.2 Branches recomendadas

Crear branches separadas desde el mismo baseline:

- `codex/dispatch-iter1-a-task2`
- `codex/dispatch-iter1-b-task2`

### 13.3 Comandos de creacion

```powershell
git worktree add .worktrees/dispatch-iter1-a-task2 -b codex/dispatch-iter1-a-task2 8d132a6
git worktree add .worktrees/dispatch-iter1-b-task2 -b codex/dispatch-iter1-b-task2 8d132a6
```

### 13.4 Regla de aislamiento

La comparacion de Iteracion 1 no debe ejecutarse sobre:
- el workspace principal;
- ni `c:\Users\mcros\Documents\obfuscator\.worktrees\release-contract-task0`

Ese worktree sigue reservado al flujo real del plan y no debe contaminarse con el experimento metodologico.

---

## 14. Preparacion minima de cada worktree

### 14.1 Variante A

En el worktree A:

```powershell
git status --short
Rscript tests/testthat.R
```

Si el baseline esta limpio y verde, el worktree queda listo para el dispatch A.

### 14.2 Variante B

En el worktree B:

1. verificar `git status --short`
2. correr `Rscript tests/testthat.R`
3. confirmar presencia local de la documentacion normativa

Archivos a verificar dentro del worktree B:
- `ESPECIFICACION_DE_REQUERIMIENTOS_v3.0.md`
- `docs/AUDITORIA_ESTADO_ACTUAL_2026-05-06.md`
- `docs/superpowers/specs/2026-05-06-liberacion-segura-a-terceros-design.md`
- `docs/superpowers/plans/2026-05-06-liberacion-segura-a-terceros-implementation-plan.md`

Si alguno no existe por no estar committeado en `HEAD`, sincronizar una copia local antes del dispatch.

### 14.3 Comprobacion de rutas reales

Antes de lanzar B, validar por shell que las rutas usadas en el prompt existen realmente:

```powershell
Test-Path 'c:\Users\mcros\Documents\obfuscator\.worktrees\dispatch-iter1-b-task2\ESPECIFICACION_DE_REQUERIMIENTOS_v3.0.md'
Test-Path 'c:\Users\mcros\Documents\obfuscator\.worktrees\dispatch-iter1-b-task2\docs\AUDITORIA_ESTADO_ACTUAL_2026-05-06.md'
Test-Path 'c:\Users\mcros\Documents\obfuscator\.worktrees\dispatch-iter1-b-task2\docs\superpowers\specs\2026-05-06-liberacion-segura-a-terceros-design.md'
Test-Path 'c:\Users\mcros\Documents\obfuscator\.worktrees\dispatch-iter1-b-task2\docs\superpowers\plans\2026-05-06-liberacion-segura-a-terceros-implementation-plan.md'
```

---

## 15. Secuencia operativa exacta

### 15.1 Preparar baseline

```powershell
git rev-parse --verify 8d132a6
git worktree add .worktrees/dispatch-iter1-a-task2 -b codex/dispatch-iter1-a-task2 8d132a6
git worktree add .worktrees/dispatch-iter1-b-task2 -b codex/dispatch-iter1-b-task2 8d132a6
```

### 15.2 Verificar ambos worktrees

```powershell
git -C .worktrees/dispatch-iter1-a-task2 status --short
git -C .worktrees/dispatch-iter1-b-task2 status --short
Rscript .worktrees/dispatch-iter1-a-task2/tests/testthat.R
Rscript .worktrees/dispatch-iter1-b-task2/tests/testthat.R
```

### 15.3 Ejecutar Variante A

Pasos:
1. lanzar el agente con `Prompt A`
2. esperar primera entrega
3. registrar tiempo y observaciones
4. auditar diff y verificaciones
5. registrar hallazgos en `docs/AGENT_DISPATCH_EVAL_RESULTS.md`

### 15.4 Ejecutar Variante B

Pasos:
1. sincronizar documentos si hiciera falta
2. completar checklist de preflight
3. correr premortem corto del prompt si sigue habiendo riesgo de ambiguedad
4. lanzar el agente con `Prompt B`
5. esperar primera entrega
6. auditar diff y verificaciones con el mismo rigor aplicado a A
7. registrar hallazgos en `docs/AGENT_DISPATCH_EVAL_RESULTS.md`

### 15.5 Cerrar comparacion

Al finalizar ambas variantes:
1. completar la seccion `Comparacion de Iteracion 1`
2. escribir una conclusion metodologica corta
3. decidir si la Iteracion 2 mantiene el mismo protocolo o si se ajusta

---

## 16. Reglas de auditoria para mantener comparabilidad

La auditoria de A y B debe usar el mismo minimo comun:
- revisar diff completo;
- rerun de verificaciones que el agente afirme haber corrido;
- al menos una lectura manual de los archivos principales tocados;
- y explicitar si hubo o no hallazgos.

La comparacion se sesga si:
- una variante recibe auditoria superficial;
- la otra recibe auditoria profunda;
- o se aceptan estandares distintos de evidencia.

---

## 17. Registro exacto esperado

El registro acumulativo de esta iteracion debe dejar explicitamente:
- commit baseline usado;
- worktree A y B efectivamente creados;
- si B requirio sincronizacion documental;
- comandos de verificacion corridos por cada agente;
- comandos de verificacion corridos en auditoria;
- numero de rondas de correccion;
- y conclusion comparativa.

La fuente principal para ese registro es:

- `docs/AGENT_DISPATCH_EVAL_RESULTS.md`

---

## 18. Nota practica

Si la comparacion no puede correrse completa en una sola sesion, no debe relanzarse "de memoria".

Antes de retomarla:
- releer este documento;
- revisar `docs/AGENT_DISPATCH_EVAL_RESULTS.md`;
- y confirmar que ambos worktrees sigan correspondiendo al mismo baseline.
3. correr variante A;
4. auditar variante A;
5. restaurar mirada neutral;
6. correr variante B;
7. auditar variante B;
8. completar la comparacion final;
9. registrar resultados en `docs/AGENT_EXECUTION_NOTES.md`.

---

## 12. Resultado esperado de esta iteracion

Al finalizar la Iteracion 1 deberiamos poder responder, con mas evidencia que intuicion:

- si el contexto documental sincronizado reduce errores reales;
- si el preflight del prompt aporta valor practico;
- si la auditoria posterior obligatoria captura defectos que el agente no ve;
- y si todo eso justifica el costo operativo extra.

---

## 13. Prompt concreto para Variante A

Este prompt debe usarse con el baseline elegido para la iteracion, sin agregarle ayudas metodologicas extra.

```text
Implementa la Task 2 del plan en este worktree.

Proyecto: ObfuscatoR
Tarea: Introduce canonical UI helper defaults and dataset-name resolution

Worktree:
<RUTA_WORKTREE_A>

Archivos de tu propiedad para esta tarea:
- R/shiny_app.R
- tests/testthat/test_obfuscator.R

No estás solo en el codebase. No reviertas cambios ajenos ni toques archivos fuera de esta tarea salvo que sea estrictamente necesario y lo justifiques.

Objetivo funcional:
- agregar un helper puro `studio_parameter_defaults()` con defaults canónicos:
  - `seed = 123`
  - `id_prefix = "999"`
  - `project_key = NULL`
  - `numeric_mode = "range_random"`
  - `k_value = 5`
  - `k_suppression = "rows"`
  - `group_ids = FALSE`
- agregar un helper puro `resolve_dataset_display_name(source_mode, object_name = NULL, file_name = NULL)`
- actualizar el flujo actual de carga para almacenar un nombre canónico del dataset
- dejar de usar `input$dataset_name` en el chip hero y usar el nuevo estado reactivo
- lograr que pasen los tests agregados en Task 1

Pasos esperados:
1. usar TDD
2. implementar solo lo necesario para esta task
3. correr la verificación focalizada

Verificación requerida:
Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R')"

Al final reporta:
- status: DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED
- archivos cambiados
- comandos de verificación corridos y resultado
- cualquier preocupación relevante
```

---

## 14. Prompt concreto para Variante B

Este prompt debe usarse solo despues de preflight y con documentacion normativa ya sincronizada dentro del worktree.

```text
Implementa la Task 2 del plan en este worktree usando la documentacion normativa local presente en disco como fuente principal de contexto.

Proyecto: ObfuscatoR
Tarea: Introduce canonical UI helper defaults and dataset-name resolution

Worktree:
<RUTA_WORKTREE_B>

Documentacion normativa disponible dentro del worktree:
- <RUTA_WORKTREE_B>/ESPECIFICACION_DE_REQUERIMIENTOS_v3.0.md
- <RUTA_WORKTREE_B>/docs/AUDITORIA_ESTADO_ACTUAL_2026-05-06.md
- <RUTA_WORKTREE_B>/docs/superpowers/specs/2026-05-06-liberacion-segura-a-terceros-design.md
- <RUTA_WORKTREE_B>/docs/superpowers/plans/2026-05-06-liberacion-segura-a-terceros-implementation-plan.md

Usa esas rutas reales del worktree. No asumas contexto del workspace principal ni de archivos que no existan en este worktree.

Archivos de tu propiedad para esta tarea:
- R/shiny_app.R
- tests/testthat/test_obfuscator.R

No estás solo en el codebase. No reviertas cambios ajenos ni toques archivos fuera de esta tarea salvo que sea estrictamente necesario y lo justifiques.

Objetivo funcional:
- agregar un helper puro `studio_parameter_defaults()` con defaults canónicos:
  - `seed = 123`
  - `id_prefix = "999"`
  - `project_key = NULL`
  - `numeric_mode = "range_random"`
  - `k_value = 5`
  - `k_suppression = "rows"`
  - `group_ids = FALSE`
- agregar un helper puro `resolve_dataset_display_name(source_mode, object_name = NULL, file_name = NULL)`
- actualizar el flujo actual de carga para almacenar un nombre canónico del dataset
- dejar de usar `input$dataset_name` en el chip hero y usar el nuevo estado reactivo
- lograr que pasen los tests agregados en Task 1

Restricciones metodológicas:
- usa TDD
- no pases por alto el flujo real de carga: no alcanza con hacer que el helper exista
- no arregles el test de forma artificial dejando inconsistente el comportamiento real
- mantén la solución acotada a esta task

Verificación requerida:
Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R')"

Reporte final requerido:
- status: DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED
- archivos cambiados
- comandos de verificación corridos y resultado
- qué partes del plan/spec consultaste
- cualquier preocupación sobre contexto, semántica o efectos colaterales
```

---

## 15. Preflight operativo para Variante B

Antes de lanzar el prompt B, completar esto:

- [ ] La Task 2 está copiada o referenciada con suficiente detalle en el prompt.
- [ ] La especificación, auditoría, design doc y plan existen dentro del worktree B.
- [ ] Las rutas del prompt B apuntan al worktree B y no al workspace principal.
- [ ] El baseline del worktree B coincide con el de la variante A.
- [ ] El agente tiene claro qué archivos son de su propiedad.
- [ ] El criterio de éxito menciona explícitamente la verificación requerida.
- [ ] El prompt B no permite “cumplir localmente” ignorando el flujo real de carga.

---

## 16. Premortem corto sugerido para el prompt B

Antes del dispatch B, correr este chequeo mental o documental:

> Imagina que esta ejecución ya fracasó. ¿Cómo falló el prompt?

Preguntas mínimas:
- ¿Podría el agente implementar solo los helpers y olvidar el estado reactivo real?
- ¿Podría hacer pasar el test tocando expectativas en vez de comportamiento?
- ¿Podría leer documentación fuera del worktree y mezclar contextos?
- ¿Podría tocar más UI de la necesaria para esta task?
- ¿Podría dejar funcionando el helper pero roto el flujo real de carga?

Si alguna respuesta es “sí, fácilmente”, corregir el prompt antes de despacharlo.
