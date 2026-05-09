# Premortem Transcript: Liberacion Segura a Terceros Implementation Plan

- Fecha: 2026-05-07 00:18:33
- Plan analizado: `c:\Users\mcros\Documents\obfuscator\docs\superpowers\plans\2026-05-06-liberacion-segura-a-terceros-implementation-plan.md`
- Especificacion base: `c:\Users\mcros\Documents\obfuscator\ESPECIFICACION_DE_REQUERIMIENTOS_v3.0.md`

## Contexto usado

### Que es
Un plan de implementacion para reorientar ObfuscatoR desde un estudio de ofuscacion de doble proposito hacia una herramienta defendible de liberacion segura de datasets a terceros.

### Para quien es
Analistas institucionales que custodian datasets sensibles y necesitan decidir si un dataset puede compartirse con terceros, incluida una IA, sin exponer informacion confidencial.

### Que significa exito
- una unica UI coherente;
- exportacion bloqueada por defecto;
- `k-anonymity` obligatorio para liberacion a terceros;
- chequeos adicionales de columnas riesgosas y combinaciones riesgosas;
- revision manual auditable;
- persistencia JSON y fuzzy matching preservados;
- y consistencia entre app Shiny, codigo R generado y API/script del paquete.

---

## Marco del premortem

Es seis meses en el futuro. El plan fracaso. El producto no llego a convertirse en una herramienta confiable y defendible de liberacion segura a terceros. Estamos mirando hacia atras para entender por que murio.

---

## Razones crudas de fracaso

1. La implementacion colapso bajo complejidad de estado porque demasiada logica de decision de liberacion quedo dentro de `R/shiny_app.R`.
2. Las heuristicas generales y las reglas de bloqueo generaron demasiados falsos positivos y los analistas dejaron de confiar en la herramienta.
3. La reescritura rompio persistencia JSON, fuzzy matching y continuidad de plantillas, volviendo a la nueva version una degradacion operativa.
4. La revision manual y la auditabilidad quedaron superficiales, asi que la herramienta afirmo defendibilidad sin evidencia reproducible.
5. El modelo de liberacion divergio entre UI, codigo R generado y API/core, creando semanticas contradictorias sobre que era interno, revisable o realmente liberable.
6. El equipo invirtio mas en estados, etiquetas y heuristicas que en probar si las transformaciones de privacidad realmente alcanzaban para datasets reales.

---

## Deep Dives por modo de falla

### 1. Complejidad de estado en `R/shiny_app.R`

**Historia del fracaso**

El colapso empezo en la Fase 2, justo donde el plan proponia insertar la nueva capa de decision dentro de `R/shiny_app.R`. En vez de extraer un verdadero modelo de dominio, el equipo fue agregando `reactiveVal()` para nombre del dataset, estado de liberacion, razones de bloqueo, revisiones manuales, persistencia y sugerencias fuzzy. Para cuando llegaron la separacion de artefactos internos y la revision activa, una accion del usuario podia disparar cinco caminos reactivos: clasificacion, recalculo de riesgo, recomputo de estado, refresco de persistencia y actualizacion visual de badges.

El punto de quiebre llego al preservar persistencia y fuzzy matching. Cargar una plantilla rehidrataba roles antes de que el nombre del dataset y las heuristicas de riesgo quedaran estabilizados. Las revisiones quedaban asociadas a columnas equivocadas, la exportacion seguia bloqueada despues de arreglos validos y en otros casos se desbloqueaba por orden de eventos. El equipo paso semanas ajustando `observeEvent()`, `ignoreInit`, `isolate` y guardas reactivas, pero cada parche rompia otro flujo.

**Supuesto subyacente**

Se asumio que la reactividad de Shiny alcanzaba como arquitectura para orquestar la politica de liberacion, asi que se postergo la extraccion de un modelo puro de decision.

**Senales tempranas**

- Cada nueva regla se implementa agregando mas `reactiveVal()` y `observeEvent()` en vez de helpers puros con tests.
- El mismo escenario produce estados distintos segun el orden de acciones del usuario.

### 2. Falsos positivos y fatiga de bloqueo

**Historia del fracaso**

La Fase 3 aterrizo con nombre prometedor: heuristicas de alto riesgo, deteccion de combinaciones riesgosas, exportacion bloqueada y revision activa. En la practica, la politica general fue demasiado tosca. Datasets institucionales corrientes disparaban a la vez patrones nominales, reglas de fechas y alertas por combinaciones antes incluso de que el analista contextualizara el caso. Equipos que procesaban datasets recurrentes encontraban media planilla en `En revision` o `Bloqueado` por motivos tecnicamente plausibles pero operativamente irrelevantes.

La continuidad con plantillas JSON tampoco salvo la experiencia. Aunque la clasificacion se recuperaba, el nuevo motor de decision seguia obligando a repetir revisiones porque interpretaba pequenos cambios de esquema como riesgo nuevo. Los usuarios terminaron describiendo a la app como "la que siempre dice que no". Dejaron de confiar en los bloqueos y volvieron a scripts ad hoc y ediciones manuales.

**Supuesto subyacente**

Se asumio que una politica general conservadora podia ser suficientemente defendible sin volverse tan ruidosa que los analistas la ignoraran.

**Senales tempranas**

- En pilotos, mas de la mitad de los datasets corrientes siguen `Bloqueado` despues de una primera pasada completa.
- Usuarios con plantillas guardadas igual tienen que revalidar una y otra vez las mismas columnas o combinaciones.

### 3. Regresion de persistencia y fuzzy matching

**Historia del fracaso**

La reescritura salio con nuevo modelo de estados, bloqueo por defecto y revision auditable, pero la Fase 4 se trato como alineacion tardia y no como riesgo de migracion. La reescritura de defaults y semanticas cambio `k_value`, `project_key`, `numeric_mode` y los metadatos de revision. Las viejas plantillas seguian cargando, pero ya no restauraban un estado canonico completo. Fuzzy matching seguia sugiriendo coincidencias de esquema, pero no alcanzaba a reconstruir las nuevas expectativas de riesgo y revision.

Cuando los analistas intentaron procesar datasets recurrentes, perdieron justamente el acelerador que mas valor tenia: cargar un archivo conocido, recuperar la clasificacion y avanzar. En la nueva version volvian a revisar columnas, rehacer confirmaciones y resolver bloqueos "nuevos" sobre archivos estandarizados desde hace meses. El producto quedo mas defendible en el papel y mas lento en la practica.

**Supuesto subyacente**

Se asumio que persistencia y fuzzy matching eran comodidades perifericas, cuando en realidad formaban parte del contrato central de continuidad del producto.

**Senales tempranas**

- Plantillas guardadas cargan con estado degradado, flags reseteados o datasets que reabren como `En revision`.
- Datasets recurrentes requieren casi el mismo esfuerzo manual que uno completamente nuevo.

### 4. Auditabilidad superficial

**Historia del fracaso**

Seis meses despues, la demo del producto se veia muy bien: UI limpia, exportacion bloqueada, `k-anonymity` exigido, panel de riesgos detectados. Pero la implementacion de la revision manual quedo en metadatos ligeros dentro de `R/shiny_app.R`, no en un verdadero modelo de evidencia. La app registraba cosas como `reviewed = TRUE`, comentarios libres y algun tratamiento elegido, pero no obligaba a vincular la revision a un bloqueo concreto ni a un dato verificable.

El problema se hizo visible cuando un revisor interno pidio el rastro de liberacion de un dataset que paso de bloqueado a liberable. El informe explicaba que conclusion habia tomado el sistema, pero no podia reconstruir como se habia llegado ahi. No habia registro durable del conteo unico declarado por el usuario, ni snapshots antes/despues de combinaciones riesgosas, ni una liga estructurada entre alertas y decisiones manuales. La pretendida defendibilidad no sobrevivia auditoria real.

**Supuesto subyacente**

Se asumio que con campos "estructurados" y exportacion bloqueada por defecto la evidencia resultante iba a ser automaticamente defendible.

**Senales tempranas**

- Los registros de revision solo contienen `approved`, `comment` o `treatment_selected`.
- Un informe de liberacion no permite reconstruir que alertas se resolvieron, por quien y con que evidencia.

### 5. Divergencia entre UI, codigo generado y API

**Historia del fracaso**

Al mes dos, el equipo sentia que habia cerrado la Fase 2 porque la app mostraba estados explicitos y bloqueaba la exportacion salvo que el dataset estuviera `Liberable`. Pero la arquitectura se rompio justo donde el plan era mas fragil: la semantica nueva vivia sobre todo en `R/shiny_app.R`, mientras el codigo R generado y la API del core seguian siendo mas permisivos. Un analista podia generar codigo desde una sesion bloqueada, ejecutar ese script, obtener un dataset transformado con `privacy_report` y tomarlo como practicamente liberable porque el camino por script no tenia un gate equivalente al de la UI.

La ruptura se agravo al preservar persistencia antes de unificar semanticas. Una plantilla restauraba roles y tratamientos, pero no una unica verdad sobre que significaba "interno", "review-only" o "releasable". A los seis meses, la UI decia "bloqueado", el codigo generado parecia listo para correr y la API seguia comportandose como motor de transformacion. Nadie podia explicar que salida gobernaba realmente la liberacion.

**Supuesto subyacente**

Se asumio que si primero se corregian las semanticas de la UI, el codigo generado y la API iban a quedar alineados casi por arrastre.

**Senales tempranas**

- Una sesion bloqueada puede seguir generando codigo ejecutable sin marca explicita de `internal-only`.
- No existen tests transversales que exijan el mismo veredicto de liberacion para UI, codigo generado y API directa.

### 6. Mucha gobernanza, poca prueba de transformacion real

**Historia del fracaso**

El equipo ejecuto con fuerza las tareas de estados, heuristicas, revisiones y reportes. Las demos lucian serias: el sistema sabia decir `Bloqueado`, `En revision` o `Liberable`, y podia explicar por que. Pero casi toda la energia de test y desarrollo se fue a validar helpers y flujos de interfaz, no a demostrar que las transformaciones de privacidad funcionaban bien sobre datasets realistas. La suite probaba mas la logica de estado que la adecuacion de las transformaciones sobre quasi-identificadores, precision temporal o singularidad residual.

El fracaso llego en la primera revision institucional seria. Un dataset real con fechas, categorias dispersas y numericas muy distintivas pasaba partes del flujo y aun asi producia salidas que revisores juzgaban inseguras o analiticamente inconsistentes. El producto parecia burocraticamente estricto, no tecnicamente defendible: muchos bloqueos, muchos labels y poca prueba de que el motor pudiera volver realmente liberable un dataset dificil.

**Supuesto subyacente**

Se asumio que estados fuertes, heuristicas y auditabilidad podian compensar no haber probado con suficiente rigor la adecuacion del motor de transformacion sobre casos reales de alto riesgo.

**Senales tempranas**

- Casi todos los tests nuevos son de helpers de `R/shiny_app.R` y transiciones de estado.
- Las demos muestran bloqueos e informes, pero no dos o tres casos reales creibles que lleguen a `Liberable` con evidencia defendible.

---

## Sintesis

### La falla mas probable

La mas probable es la combinacion de complejidad de estado en `R/shiny_app.R` con divergencia entre UI, codigo generado y API. El plan depende de ir agregando semantica de liberacion sobre una app Shiny ya cargada de responsabilidades y recien mas tarde alinea el resto de los caminos de uso. Eso hace muy probable un sistema donde cada ruta diga una verdad distinta.

### La falla mas peligrosa

La mas peligrosa es construir una herramienta con mucha gobernanza de liberacion y poca prueba de que las transformaciones realmente alcanzan para datasets reales. Esa combinacion puede dar una falsa sensacion de seguridad institucional: la app parece estricta y auditable, pero falla justo cuando la usan para un caso serio.

### La suposicion oculta

La mayor suposicion no cuestionada es esta:

> Se puede superponer una capa de decision de liberacion defendible sobre la app y el core actuales sin extraer antes un contrato compartido de estado, evidencia y semantica de salida.

Esa suposicion explica casi todos los modos de falla: reactividad desbordada, persistencia que no migra bien, UI y API que divergen, revisiones que quedan decorativas y tests que validan forma en vez de fondo.

---

## Plan revisado

### Revision 1: Agregar una Fase 0 de contrato y arquitectura

Antes de tocar UI:
- definir una estructura pura y compartida para:
  - release state;
  - release verdict;
  - alert objects;
  - manual review evidence;
  - artifact type (`preview`, `internal_work`, `releasable_external`);
- escribir tests transversales de contrato entre:
  - UI;
  - codigo R generado;
  - API/script.

### Revision 2: Mover persistencia y fuzzy matching mas arriba

No dejar persistencia como alineacion tardia. Debe entrar apenas exista el contrato canonico. La migracion de plantillas debe probarse antes de reescribir el bloque principal de parametros.

### Revision 3: Separar el motor de decision del servidor Shiny

Toda regla de negocio nueva debe nacer como helper puro con test. `R/shiny_app.R` debe quedar como integrador de estado visual, no como policy engine.

### Revision 4: Introducir un paquete pequeno de datasets de verificacion realista

Antes de cerrar Fases 2 y 3, definir 2 o 3 fixtures sinteticos pero realistas:
- fechas sensibles;
- categorias raras;
- numericas distintivas;
- texto libre;
- esquemas recurrentes con fuzzy matching.

El objetivo no es solo bloquear, sino demostrar cuando un dataset logra volverse liberable y cuando no.

### Revision 5: Endurecer auditabilidad como contrato, no como mejora

La evidencia manual minima debe incluir:
- alert ID;
- objeto revisado;
- timestamp;
- usuario si existe;
- verificacion activa exigida;
- accion aplicada;
- reevaluacion posterior;
- resultado antes/despues.

No debe existir informe de liberacion sin ese rastro.

### Revision 6: Agregar una puerta de ruido operativo

Antes de declarar lista la politica general, medir:
- tasa de datasets piloto que quedan bloqueados;
- cantidad de revisiones repetidas sobre datasets recurrentes;
- tiempo de reuso con plantillas;
- falsos positivos percibidos por usuarios.

Si el sistema es defendible pero inutilizable, el plan tambien fracaso.

---

## Checklist previo a ejecutar

1. Existe un contrato puro compartido para estado, evidencia, alertas y tipos de artefacto.
2. Hay al menos un test que exige el mismo veredicto de liberacion en UI, codigo generado y API.
3. Hay fixtures realistas que demuestran tanto un caso `Liberable` como un caso `No liberable sin rediseno`.
4. Persistencia JSON y fuzzy matching pasan pruebas de continuidad antes de remover o rearmar el flujo principal de parametros.
5. Una revision manual deja evidencia suficiente para reconstruir una liberacion completa sin mirar la sesion viva.

