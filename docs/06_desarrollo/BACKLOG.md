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
