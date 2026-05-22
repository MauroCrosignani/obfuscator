# Diseno y plan de ajustes semanticos basados en prueba real del helper IA

## Resumen

Se documentaron tres mejoras priorizadas a partir de una prueba real del helper de perfilado seguro para IA sobre datasets institucionales.

Las mejoras definidas son:

1. entrecomillar valores categoricos visibles;
2. reclasificar mejor nombres institucionales repetibles como `NOMBRE_UNIDAD`;
3. reinterpretar como `fecha` las `POSIXct` cuya hora no aporta informacion.

## Artefactos principales

- diseno:
  - [2026-05-22-diseno-de-ajustes-semanticos-basados-en-prueba-real-del-helper-ia.md](c:/Users/mcros/Documents/obfuscator/docs/02_diseno/2026-05-22-diseno-de-ajustes-semanticos-basados-en-prueba-real-del-helper-ia.md)
- plan:
  - [2026-05-22-ajustes-semanticos-basados-en-prueba-real-del-helper-ia-implementation-plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-22-ajustes-semanticos-basados-en-prueba-real-del-helper-ia-implementation-plan.md)

## Decision metodologica

No se abrio implementacion en esta pasada. Primero se fijo el criterio a partir de evidencia real para evitar cambios guiados solo por intuicion.

## Evidencia usada

La evidencia vino de pruebas reales del usuario sobre:

- `gca_7014_202301`
- `Resultado_GCA`
- `Resultado_GCA2`

## Verificacion

No se corrieron tests ni comandos de R en esta pasada, porque fue un cierre de diseno y plan.

## Siguiente paso recomendado

Ejecutar el plan en tres bloques chicos:

1. comillas dobles en categorias visibles;
2. nombres institucionales como `entity_label`;
3. `POSIXct` con interpretacion de `fecha` cuando la hora sea no sustantiva.
