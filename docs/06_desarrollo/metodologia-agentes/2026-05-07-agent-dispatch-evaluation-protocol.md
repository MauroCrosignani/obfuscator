# Protocolo de Evaluacion Comparativa para Mejoras en Dispatch de Agentes

**Version:** borrador 0.1  
**Estado:** protocolo experimental generalizable  
**Fecha:** 2026-05-07  
**Autor:** Codex, a partir de la experiencia de ejecucion en ObfuscatoR y decisiones validadas en conversacion

---

## 1. Proposito

Este protocolo existe para evaluar, con evidencia comparativa, si una mejora en la forma de despachar agentes produce resultados materialmente mejores que el metodo actual.

La mejora candidata no debe evaluarse por intuicion, simpatia hacia una forma de trabajo o una sola anecdota. Debe evaluarse con iteraciones repetidas, criterios consistentes y auditoria posterior independiente.

---

## 2. Hipotesis a evaluar

La hipotesis de trabajo es:

> Un dispatch reforzado con mejor contexto documental, preflight del prompt y auditoria posterior obligatoria produce resultados mas robustos que un dispatch estandar.

La comparacion no debe limitarse a la calidad del codigo. Debe incluir tambien el costo operativo total de obtener un resultado aceptable.

---

## 3. Variantes a comparar

### 3.1 Variante A: dispatch actual

La variante A representa el metodo base.

Incluye:
- prompt de tarea normal;
- contexto provisto segun la practica habitual;
- sin preflight sistematico del prompt;
- sin protocolo reforzado de sincronizacion documental mas alla de lo que ocurra de forma natural;
- auditoria posterior segun necesidad, pero no como parte obligatoria del experimento.

### 3.2 Variante B: dispatch reforzado

La variante B representa la mejora candidata.

Incluye:
- documentacion normativa sincronizada en el `worktree` antes del dispatch;
- rutas reales dentro del `worktree` en el prompt del agente;
- checklist de preflight del prompt antes de despachar;
- auditoria posterior obligatoria por un revisor separado del agente implementador;
- registro estructurado de fallos de contexto, retrabajo y defectos detectados.

### 3.3 Regla metodologica

Las variantes A y B deben compararse sobre tareas equivalentes en complejidad y objetivo.

No se debe sesgar el experimento haciendo que:
- A reciba una tarea mas ambigua;
- B reciba una tarea mas facil;
- o una variante reciba soporte humano extra que la otra no tenga.

---

## 4. Alcance de la evaluacion

La evaluacion debe ser integral.

Eso significa que no solo interesa:
- si el agente entrego algo que "funciona";

Sino tambien:
- cuanto retrabajo requirio;
- cuanto contexto falto;
- cuanta auditoria correctiva hubo que hacer;
- y si el resultado final es mas defendible y reutilizable.

---

## 5. Diseño experimental

### 5.1 Numero de iteraciones

Se realizaran **tres iteraciones**.

Tres iteraciones no eliminan toda la varianza, pero ya permiten distinguir mejor entre:
- una mejora genuina;
- una tarea especialmente facil o dificil;
- y una simple buena o mala suerte en una sola corrida.

### 5.2 Tipo de tareas

Las tres iteraciones deben cubrir tareas de perfiles distintos.

Se recomienda esta matriz:

1. **Tarea de contrato o tests**
   - foco en helpers, expectativas y control de regresiones.

2. **Tarea de integracion moderada**
   - toca varias piezas relacionadas y requiere coherencia entre componentes.

3. **Tarea con ambiguedad o alto riesgo de contexto**
   - mas dependiente de documentacion, supuestos y lectura correcta del objetivo.

### 5.3 Unidad de comparacion

Cada iteracion compara:
- una ejecucion con variante A;
- una ejecucion con variante B;
- sobre tareas equivalentes o sobre el mismo tipo de tarea, si la duplicacion exacta no es operativamente razonable.

### 5.4 Auditoria posterior

Toda iteracion debe incluir auditoria posterior separada del agente implementador.

La auditoria debe evaluar:
- defectos reales;
- omisiones respecto al plan o la especificacion;
- debilidades de contexto;
- y costo de correccion.

La autorevision del agente implementador no se considera evidencia suficiente.

---

## 6. Preflight del prompt para la variante B

Antes de despachar un agente bajo la variante B, se debe ejecutar un preflight breve.

### 6.1 Objetivos del preflight

El preflight busca detectar:
- contexto faltante;
- ambiguedades del pedido;
- archivos normativos ausentes en el `worktree`;
- supuestos no explicitados;
- riesgos de que el agente "cumpla la tarea" de forma local pero falle en el contexto global.

### 6.2 Checklist minimo de preflight

Antes del dispatch, responder:

1. ¿La tarea refiere a una especificacion, plan o auditoria concreta?
2. ¿Esos archivos existen dentro del `worktree` del agente?
3. ¿El prompt contiene rutas reales dentro del `worktree`?
4. ¿El criterio de exito esta expresado de forma verificable?
5. ¿Se aclaro que archivos son de su propiedad y cuales no?
6. ¿Se indico el tipo de verificacion esperada?
7. ¿Hay una forma obvia en que el agente pueda malinterpretar el objetivo aunque cumpla localmente?

### 6.3 Uso de premortem sobre el prompt

Cuando la tarea sea importante, ambigua o con alto costo de error, se recomienda un premortem corto del prompt antes del dispatch.

No se trata de correr un premortem gigante del proyecto entero, sino de preguntar:
- como podria fallar este prompt;
- que contexto podria faltar;
- que salida "aparentemente correcta" podria ser en realidad deficiente.

El objetivo es debilitar el prompt antes de que lo haga la realidad.

---

## 7. Metricas de evaluacion

### 7.1 Calidad tecnica del resultado

Medir:
- si cumple la tarea pedida;
- si pasa las verificaciones requeridas;
- si evita regresiones;
- si introduce deuda tecnica clara;
- si la solucion respeta los limites de la tarea.

### 7.2 Adherencia a especificacion y plan

Medir:
- grado de cumplimiento del plan;
- cumplimiento de restricciones;
- si el agente resolvio el problema correcto;
- si confundio el objetivo local con el objetivo global.

### 7.3 Robustez de contexto

Medir:
- cantidad de aclaraciones necesarias;
- errores causados por falta de contexto;
- uso correcto o incorrecto de documentacion normativa;
- referencias a rutas inexistentes o contexto no disponible.

### 7.4 Costo operativo

Medir:
- tiempo hasta primera entrega;
- tiempo total hasta aceptacion;
- cantidad de iteraciones de correccion;
- numero de hallazgos en auditoria posterior;
- cantidad de trabajo correctivo hecho por el controlador.

### 7.5 Calidad de la auditoria

Medir:
- cuantas fallas relevantes detecto la auditoria posterior;
- cuantas no detecto la autorevision;
- cuanta profundidad de inspeccion adicional hizo falta desde el controlador.

### 7.6 Trazabilidad y defendibilidad

Medir:
- claridad del reporte del agente;
- capacidad de reconstruir por que hizo lo que hizo;
- claridad sobre que verifico y que no verifico;
- y si el resultado es facil de heredar en una sesion futura.

---

## 8. Plantilla de registro por iteracion

Cada iteracion debe registrarse con esta estructura minima.

### 8.1 Identificacion

- Iteracion:
- Fecha:
- Proyecto:
- Tipo de tarea:
- Variante: A o B
- Agente:

### 8.2 Entrada

- Descripcion breve de la tarea:
- Archivos normativos usados:
- Si hubo preflight:
- Si hubo premortem del prompt:

### 8.3 Ejecucion

- Tiempo hasta primera entrega:
- Tiempo total hasta aceptacion o rechazo:
- Aclaraciones pedidas por el agente:
- Bloqueos encontrados:

### 8.4 Resultado tecnico

- Verificaciones corridas:
- Estado de tests / checks:
- Calidad tecnica percibida:
- Cumplimiento del plan o spec:

### 8.5 Auditoria posterior

- Hallazgos detectados:
- Hallazgos no detectados por el agente:
- Retrabajo requerido:
- Profundidad de intervencion del controlador:

### 8.6 Evaluacion global

- Fortalezas:
- Debilidades:
- ¿Supero a la otra variante en esta iteracion?:
- Observaciones metodologicas:

---

## 9. Criterios para decidir si la mejora vale la pena

La variante B no debe adoptarse globalmente solo porque "se siente mejor".

Debe mostrar evidencia de una o varias ventajas materiales:
- menos defectos relevantes;
- menos retrabajo;
- mejor auditori­a posterior;
- mejor trazabilidad;
- menos errores de contexto;
- o calidad equivalente con menor costo total de supervision correctiva.

Tambien debe evaluarse si introduce costos excesivos:
- prompts demasiado pesados;
- friccion operativa exagerada;
- tiempos de despacho desproporcionados;
- o sobrecarga documental que no mejora resultados reales.

---

## 10. Regla de adopcion

### 10.1 Si la mejora funciona

Si las tres iteraciones muestran mejora consistente y el costo operativo adicional es razonable:
- promover la practica a mejora reusable;
- evaluar si conviene incorporarla a una skill o sub-skill;
- definir que parte sera obligatoria y cual opcional.

### 10.2 Si la mejora no funciona claramente

Si el beneficio no es consistente:
- mantenerla como protocolo opcional;
- conservar aprendizajes utiles;
- y evitar institucionalizar complejidad que no demuestra valor real.

### 10.3 Si el resultado es mixto

Si mejora solo en ciertos tipos de tarea:
- no generalizarla como regla absoluta;
- convertirla en protocolo selectivo por tipo de trabajo;
- por ejemplo, solo para tareas con alta dependencia documental o alta criticidad.

---

## 11. Aplicacion inicial en ObfuscatoR

Este proyecto sirve como banco de prueba inicial porque ya mostró:
- un problema real de contexto documental en worktrees;
- valor claro de la auditoria posterior con mayor contexto global;
- y necesidad de distinguir entre autorevision del agente e inspeccion real del controlador.

Por lo tanto, ObfuscatoR es un buen primer campo para ejecutar las tres iteraciones y reunir evidencia antes de proponer una mejora reusable mas general.

---

## 12. Relacion con `AGENT_EXECUTION_NOTES.md`

`docs/AGENT_EXECUTION_NOTES.md` debe registrar:
- decisiones operativas locales;
- problemas encontrados;
- y observaciones de campo.

Este protocolo, en cambio, define:
- el metodo experimental;
- las metricas;
- y el criterio de evaluacion comparativa.

Ambos documentos son complementarios.

---

## 13. Siguiente paso recomendado

La siguiente accion recomendada es preparar:
- la primera iteracion comparativa;
- su tarea concreta;
- el prompt A;
- el prompt B;
- y la planilla de evaluacion de resultados.
