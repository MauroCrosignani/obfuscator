# Notas de Ejecucion con Agentes

## 2026-05-07 - Protocolo de contexto documental en worktrees

### Decision
Para este proyecto, los agentes no deben implementarse en un `worktree` que no contenga localmente la documentacion normativa vigente del paso en curso.

Esto incluye, segun corresponda:
- especificacion vigente;
- auditoria del estado actual;
- documento de diseno;
- plan de implementacion;
- y cualquier otra nota operativa que el paso dependa materialmente de consultar.

### Motivo
En la primera ejecucion de `Task 0`, el agente implementador recibio el texto del task en el prompt y pudo avanzar, pero el `worktree` no contenia todavia las copias locales de la especificacion y el plan porque esos archivos aun no estaban committeados en `HEAD`.

Eso no invalido automaticamente el trabajo, pero si debilito la trazabilidad y la capacidad del agente de revisar el contexto general directamente desde disco.

### Regla operativa adoptada
Antes de despachar agentes en este proyecto:
1. verificar si la documentacion necesaria existe dentro del `worktree`;
2. si no existe porque aun no esta committeada, sincronizar copias locales al `worktree`;
3. usar en el prompt rutas reales del `worktree`;
4. dejar constancia de cualquier excepcion.

### Evaluacion inicial
- Resultado: mejora adoptada como protocolo local del proyecto.
- Estado: en observacion.
- Criterio para persistirla como mejora reusable fuera del proyecto:
  - que reduzca errores de contexto en varias iteraciones;
  - que no introduzca friccion operativa desproporcionada;
  - y que produzca trazabilidad claramente mejor que el simple reenvio de texto en prompts.

## 2026-05-07 - Resultado de Iteracion 1 del experimento A/B

### Baseline efectivo usado
- commit: `fea06ad`
- descripcion: `test: define canonical release UI expectations`
- motivo: usar `Task 1` como checkpoint rojo comun antes de comparar la implementacion de `Task 2`

### Resultado resumido
- la variante A y la variante B llevaron la suite focalizada y la suite completa a verde
- la variante B produjo mejor resultado semantico y mejor trazabilidad
- la variante A resolvio el test, pero dejo inconsistencias menores en defaults canonicos y agrego fallbacks no pedidos en `resolve_dataset_display_name()`

### Leccion operativa
La mejora reforzada mostro valor no porque el agente "trabajara mas", sino porque el contexto normativo local y el preflight redujeron la probabilidad de una solucion de minimo esfuerzo compatible con el test pero menos alineada con la intencion del plan.

### Ajuste para siguientes iteraciones
- medir con mayor precision el tiempo de primera entrega
- registrar de forma separada:
  - verde de tests
  - adherencia semantica a la task
  - y cantidad de correccion posterior requerida

## 2026-05-08 - Resultado de Iteracion 2 del experimento A/B

### Baseline efectivo usado
- commit: `8d132a6`
- descripcion: `feat: define shared release contract`
- motivo: la `Task 10` del plan tiene nota explicita de ejecucion temprana, inmediatamente despues del baseline del contrato

### Resultado resumido
- ambas variantes conservaron continuidad tecnica y quedaron verdes
- la variante A pidio validacion de enfoque antes de completar y termino persistiendo `numeric_offsets` como parte de la plantilla comun
- la variante B separo mejor plantilla comun versus artefacto restringido y agrego cobertura mas fuerte

### Leccion operativa
Cuando la tarea depende de restricciones sutiles de continuidad, el dispatch reforzado agrega mas valor que en tareas de UI local. La combinacion de:
- documentacion normativa en disco
- preflight
- y premortem corto del prompt

redujo la probabilidad de "preservar lo viejo" aunque eso contradijera la semantica nueva del producto.

### Ajuste para siguientes iteraciones
- registrar timestamps de ida y vuelta cuando una variante pida aclaraciones
- explicitar aun mas en el prompt si ciertos artefactos deben tratarse como restringidos por diseno
- seguir distinguiendo:
  - verde de tests
  - continuidad tecnica
  - y coherencia con el contrato conceptual

## 2026-05-08 - Resultado de Iteracion 3 del experimento A/B

### Baseline efectivo usado
- commit: `8d132a6`
- descripcion: `feat: define shared release contract`
- motivo: la `Task 4` del plan permitia probar el tercer perfil del protocolo, una tarea de helper puro y contrato compartido

### Resultado resumido
- ambas variantes implementaron la task y quedaron verdes
- la variante A construyo una capa minima y valida, pero con estados tecnicos menos alineados con el lenguaje del producto
- la variante B consulto mejor la documentacion normativa y dejo una capa de estados mas reusable, mas completa y mejor nombrada

### Leccion operativa
En tareas de modelo puro o contrato semantico, el dispatch reforzado agrega valor mas alla del test verde. Ayuda a que el agente:
- traduzca lenguaje de especificacion a helpers reutilizables;
- cubra mejor transiciones y estados esperados por el producto;
- y reduzca el riesgo de entregar una solucion estrecha que pase tests pero no consolide bien el contrato compartido.

### Cierre del experimento
Con tres iteraciones corridas:
- Iteracion 1: gana B
- Iteracion 2: gana B
- Iteracion 3: gana B

La evidencia ya alcanza para tratar el dispatch reforzado como mejora reusable, aunque de aplicacion selectiva. La conclusion no es que deba usarse siempre, sino que conviene activarlo cuando la tarea tenga dependencia fuerte de:
- documentacion normativa;
- contratos semanticos;
- persistencia sensible;
- o alto costo de error conceptual.

## Notas incorporadas desde la ubicacion historica docs/AGENT_EXECUTION_NOTES.md

Estas notas se consolidan aqui para dejar una unica ubicacion canonica de metodologia de agentes.


## 2026-05-19

### Contexto

Se utilizo un subagente en modo de revision documental para evaluar un plan de implementacion del helper de perfilado seguro para IA.

### Objetivo

Revisar criticamente:

- el diseno:
  - [2026-05-19-diseno-de-mejoras-semanticas-para-resumen_de-y-profile_dataset_for_ai.md](c:/Users/mcros/Documents/obfuscator/docs/02_diseno/2026-05-19-diseno-de-mejoras-semanticas-para-resumen_de-y-profile_dataset_for_ai.md)
- el plan:
  - [2026-05-19-mejoras-semanticas-para-resumen_de-y-profile_dataset_for_ai-implementation-plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-19-mejoras-semanticas-para-resumen_de-y-profile_dataset_for_ai-implementation-plan.md)

y contrastarlos contra el estado actual del codigo y de los tests.

### Protocolo aplicado

- se usaron rutas reales del workspace principal;
- la tarea fue solo de lectura, sin permiso de editar archivos;
- se delimito el alcance a huecos de plan, riesgos de regresion y debilidad de verificaciones;
- se pidio explicitamente foco en:
  - compatibilidad hacia atras;
  - `list-columns`;
  - riesgo de sobreclasificar texto libre;
  - y verificaciones con `starwars`.

### Limitacion temporal

La revision se hizo sin worktree separado, porque el objetivo fue solo auditoria de documentos y no implementacion concurrente. Para tareas futuras con escritura o multiples agentes editando codigo, conviene usar aislamiento mas fuerte.

### Uso esperado del resultado

Tomar los hallazgos del subagente y ajustar el plan antes de iniciar la implementacion.

### Resultado observado

Se hicieron tres rondas de revision:

1. primera ronda:
   - detecto mezcla entre oleada 1 y oleada 2;
   - permisividad indebida para commits con tests rojos;
   - y falta de prueba negativa contra sobreclasificacion de texto libre.
2. segunda ronda:
   - confirmo que lo anterior habia mejorado;
   - pero encontro que seguia faltando un paso explicito de volver a correr en verde antes de ciertos commits.
3. tercera ronda:
   - mantuvo ese mismo blocker operativo como ultimo punto no resuelto.

### Ajuste aplicado

Como el loop de revision ya habia alcanzado tres iteraciones, el ajuste final se hizo manualmente en el plan:

- se agregaron pasos explicitos de rerun en verde antes de los commits de `Task 1` y `Task 2`;
- y se dejo mas claro el criterio de cierre por task.

### Aprendizaje de uso

Para revisiones futuras de planes:

- conviene pedir al subagente que mire tambien la secuencia exacta de `FAIL -> rerun -> PASS -> commit`, no solo el contenido conceptual del plan;
- y cuando el riesgo principal sea disciplina de TDD o checkpoints de commit, vale la pena modelar esos pasos con mas literalidad desde la primera version del plan.

## 2026-05-19 - implementacion semantica del helper de perfilado IA

### Contexto

Se utilizo un subagente adicional para intentar una revision paralela del bloque de mejoras semanticas ya implementado en:

- [R/ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R)
- [test_ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_ai_dataset_profile.R)

### Objetivo

- contrastar el cambio contra el diseno y plan vigentes;
- buscar brechas de especificacion o riesgos de regresion;
- y sumar una capa de auditoria mientras corria la suite completa.

### Resultado observado

- el intento de paralelizar revisiones encontro un limite de hilos de agentes disponibles;
- uno de los agentes adicionales no pudo lanzarse;
- el agente que si se lanzo devolvio una revision util, pero no dentro de la primera espera aplicada;
- el resultado se recupero al cerrar el agente y sirvio para detectar dos brechas reales:
  - falsos positivos de `categorica compuesta` con slash en codigos cortos;
  - dependencia excesiva del nombre de columna para `entity_label`.

### Limitacion y ajuste aplicado

- la primera espera fue demasiado corta para usar el resultado en caliente;
- aun asi, el hallazgo del agente se reincorporo despues y fue verificado localmente antes del cierre;
- el cierre del paso se sostuvo con verificacion local directa mas esa auditoria adicional ya contrastada contra el codigo;
- para futuras pasadas conviene reservar capacidad de agentes antes de abrir varias ramas de revision en paralelo y contemplar tiempos de espera algo mas amplios para revisiones sustantivas.

## 2026-05-19 - renderer que preserva la estructura de `glimpse()`

### Contexto

Se utilizo un subagente de lectura acotada para revisar el cambio planificado sobre el renderer del helper IA, mientras la implementacion principal seguia un ciclo TDD local.

### Objetivo

- ubicar con precision las ramas del renderer que habia que tocar;
- anticipar casos de borde de wording y de cobertura;
- y confirmar que el cambio podia hacerse sin reabrir la estructura interna del perfil.

### Protocolo aplicado

- se compartieron rutas reales del workspace principal;
- la tarea del subagente fue solo de lectura, sin permiso de escribir;
- el alcance se restringio a:
  - [R/ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R)
  - [test_ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_ai_dataset_profile.R)
- se pidio foco en:
  - puntos exactos del renderer a tocar;
  - riesgos de tests por wording;
  - y forma minima de implementacion.

### Resultado observado

El subagente devolvio una revision util y bien focalizada:

- confirmo que el cambio debia concentrarse en `render_ai_profile_variable()`;
- advirtio que `categorical` tenia varias subramas visibles que habia que homogeneizar;
- y ayudo a detectar que el cambio de `numeric` a tipo exacto podia impactar alertas de metadata de origen.

### Ajuste aplicado

- la implementacion principal mantuvo la estructura del perfil y rehizo solo el renderer visible;
- se actualizo tambien la deteccion de alertas para identificadores esperados cuando el tipo importado quedo como `double`;
- y se ampliaron tests visibles para `factor`, temporales y `list-columns`.

### Aprendizaje de uso

Para cambios de wording con muchas ramas visibles, una revision de lectura bien acotada agrega valor rapido:

- reduce riesgo de olvidar subramas del renderer;
- ayuda a prever regresiones por contratos de texto;
- y permite mantener la implementacion local concentrada en TDD y verificacion.
