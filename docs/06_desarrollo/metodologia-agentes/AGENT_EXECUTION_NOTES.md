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
