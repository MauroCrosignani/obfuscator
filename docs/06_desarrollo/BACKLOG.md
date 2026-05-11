# Backlog de Desarrollo y Continuidad

## Proposito

Registrar pendientes transversales que no deben perderse entre fases, cambios de rama o compactaciones de contexto.

## Pendientes activos

### 0. Persistencia operativa del resumen de auditoria para produccion

**Estado:** activo  
**Prioridad:** media

Cuando el proyecto salga del MVP, el resumen de auditoria no deberia quedar solo visible en pantalla o embebido en el objeto resultante. Conviene definir un mecanismo persistente y trazable para registrar:

- fecha y hora de cada evaluacion;
- usuario o proceso que la ejecuto, si el entorno lo permite;
- configuracion relevante de privacidad;
- veredicto final de liberacion;
- resumen de controles y bloqueos;
- referencia al artefacto exportado o retenido.

Objetivo:

- soportar auditoria posterior;
- facilitar soporte operativo y trazabilidad institucional;
- preparar una futura puesta en produccion con evidencias consultables.

Alternativas a evaluar mas adelante:

- log estructurado local por ejecucion;
- almacenamiento en base de datos o tabla institucional;
- adjunto del resumen como metadata del artefacto exportado;
- combinacion de registro operativo + informe descargable.

### 0A. Gestion explicita de plantillas de clasificacion

**Estado:** activo  
**Prioridad:** media

La persistencia automatica por esquema resulto util, pero en pruebas manuales aparecio una limitacion importante: el usuario puede no advertir que se reaplico una clasificacion previa y, si esa clasificacion era solo experimental, puede inducir una reutilizacion no deseada.

Pendientes recomendados:

- boton para volver a las sugerencias automaticas de la app;
- posibilidad de nombrar plantillas con un nombre amigable;
- selector visible de plantillas compatibles, en lugar de depender solo del hash de esquema;
- advertencia clara cuando se cargue automaticamente una plantilla previa;
- posibilidad de distinguir entre plantillas personales de prueba y plantillas estables de trabajo.

Valor adicional explorado:

- banner persistente que indique cuando una clasificacion fue aplicada automaticamente;
- historial minimo de la plantilla activa: nombre visible, origen y momento de carga;
- opcion para desactivar la carga automatica durante pruebas exploratorias;
- criterio para agrupar plantillas por una raiz comun de nombre cuando varias estructuras pertenecen a la misma familia de datasets.
- antes de implementar el primer paquete funcional, realizar un analisis UX/UI especifico del modulo de plantillas para validar:
  - visibilidad de plantilla activa;
  - friccion adecuada de `Volver a sugerencias automáticas`;
  - y lugar correcto del selector de plantillas dentro del flujo principal.

### 0B. Guardrails de clasificacion y confianza del usuario

**Estado:** activo  
**Prioridad:** media

En las pruebas manuales aparecio una necesidad clara de reforzar la gobernanza del flujo de clasificacion, especialmente cuando un usuario cambia variables sugeridas como quasi-identificadores o conserva variables sensibles/privadas sin una señal suficientemente fuerte.

Pendientes recomendados:

- advertencia o confirmacion reforzada al cambiar una variable sugerida como `QI` a `ID`, `KEEP` o `EXC`;
- call-to-action mas visible cuando existan variables `SENS` o `PRIV` sin revision manual formal;
- explicacion mas fuerte del costo analitico de la generalizacion extrema;
- criterios visibles para distinguir artefacto interno, liberacion bloqueada y liberacion controlada.

Valor adicional explorado:

- posibilidad de exigir una justificacion corta del usuario en cambios de rol particularmente riesgosos;
- semaforo de “cambios sensibles de clasificacion” dentro de la tabla principal;
- registro de decisiones de clasificacion relevantes para una futura trazabilidad operativa.

### 0C. Casos de laboratorio y pruebas guiadas de bloqueo

**Estado:** activo  
**Prioridad:** media

El testeo manual mostro que no siempre es obvio construir casos donde la app bloquee, suprima filas o degrade completamente la utilidad. Conviene fortalecer el set de laboratorios guiados para que el producto pueda presentarse y validarse con ejemplos reproducibles.

Pendientes recomendados:

- uno o mas datasets demo adicionales pensados especificamente para:
  - bloqueo;
  - supresion residual efectiva;
  - homogeneidad sensible;
  - y reenlazabilidad por alta dimensionalidad;
- ejemplos guiados en el plan manual con expectativa explicita de resultado;
- mensajes mas explicativos cuando el resultado final queda vacio o practicamente inutil para analisis.

### 0D. Liberacion sin cuasi-identificadores relevantes

**Estado:** activo  
**Prioridad:** media

En pruebas manuales aparecio un caso de borde importante: datasets donde los identificadores directos se transforman o excluyen, pero no quedan variables `QI` sobre las que aplicar `k-anonymity`.

Pendientes recomendados:

- permitir liberacion controlada sin `k-anonymity` cuando no existan `QI` relevantes y el resto del artefacto no active bloqueos duros;
- diferenciar explicitamente en auditoria entre:
  - `k-anonymity satisfecho`;
  - `k-anonymity no aplicado por ausencia de cuasi-identificadores`;
  - `revision manual requerida`;
  - `bloqueado`;
- definir una llamada a la accion mas clara cuando existan `SENS` o `PRIV` en este escenario;
- evitar que la ausencia de `QI` se trate como error de configuracion si el riesgo de cuasi-identificacion ya no existe.

Documento base:

- [2026-05-11-liberacion-controlada-sin-cuasi-identificadores.md](c:/Users/mcros/Documents/obfuscator/docs/02_diseno/2026-05-11-liberacion-controlada-sin-cuasi-identificadores.md)

### 1. Documentacion retrospectiva de tasks ya completados y estables

**Estado:** parcialmente cumplido  
**Prioridad:** alta

Debe documentarse retrospectivamente cada task ya cumplido cuyo resultado este suficientemente firme como para no esperar retrabajo estructural por tareas posteriores.

Objetivo:

- no depender de la memoria de sesion para reconstruir decisiones ya consolidadas;
- dejar trazabilidad de por que se eligio cada solucion;
- alimentar de forma incremental la futura presentacion tecnica.

Alcance inicial recomendado:

- contrato compartido de liberacion segura;
- persistencia segura de plantillas y recuperacion por esquema;
- unificacion del panel de parametros;
- estados de liberacion y gating de exportacion externa;
- heuristicas de riesgo y combinaciones pequenas;
- reenlazabilidad por alta dimensionalidad;
- requisitos de revision manual auditable.

Avance ya documentado:

- [2026-05-09_retro_bloque_fundacional_release-safe.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-09_retro_bloque_fundacional_release-safe.md)
- [2026-05-09_retro_bloque_riesgo_y_revision.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-09_retro_bloque_riesgo_y_revision.md)

Pendiente restante:

- decidir si conviene seguir con cierres retrospectivos por task fino o si alcanza con estos bloques para la primera preservacion de contexto;
- completar retrospectiva adicional si algun task estable requiere mas detalle por valor de demo o auditoria.

Salida esperada:

- un cierre documental por task o, si conviene mas, un documento retrospectivo por bloque funcional coherente;
- actualizacion de insumos en `docs/07_presentacion/` cuando el paso agregue valor para demo, defensa tecnica u objeciones previsibles.

### 2. Mantener cierre documental inmediato despues de cada task nuevo

**Estado:** activo  
**Prioridad:** alta

Regla operativa:

- al cerrar un task de implementacion, registrar enseguida:
  - que se hizo;
  - por que se eligio;
  - alternativas consideradas;
  - evidencia de verificacion;
  - impacto sobre presentacion tecnica;
  - siguiente paso.

## Trigger de actualizacion

Actualizar este backlog cuando:

- se complete un pendiente transversal;
- aparezca un nuevo frente de continuidad que no pertenezca a un solo task;
- se redefina la politica de documentacion por fase.
