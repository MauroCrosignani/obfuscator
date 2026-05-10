# Propuesta de rediseño UX/UI para clasificacion release-safe

## Resumen

Se formalizo una propuesta de rediseño UX/UI para reemplazar el mecanismo principal de clasificacion basado en multiples zonas por un modelo de `rol principal por variable`.

Conclusion practica:
- el proyecto gana una direccion de interfaz mas escalable;
- se preserva la semantica del modelo `release-safe`;
- y se reduce el riesgo de que la app se vuelva conceptualmente correcta pero dificil de usar.

## Motivo

Las pruebas manuales y la discusion sobre `edad`, `variables sensibles` y `privadas` mostraron una tension clara:

- el modelo conceptual del producto mejoro mucho;
- pero seguir representandolo como listas y zonas de drag-and-drop lo vuelve cada vez menos usable.

Por eso se priorizo documentar un rediseño antes de seguir agregando controles aislados.

## Decision tomada

Se aprobo como direccion de diseño:

- una vista principal tipo tabla de variables;
- un `rol principal` visible y editable por variable;
- una ficha lateral para tratamiento tecnico, impacto y ayuda;
- y una ayuda mucho mas contextual y orientada al flujo de trabajo.

## Artefactos principales

- [2026-05-09-rediseno-ux-ui-clasificacion-release-safe.md](c:/Users/mcros/Documents/obfuscator/docs/02_diseno/2026-05-09-rediseno-ux-ui-clasificacion-release-safe.md)
- [puntos_de_venta.md](c:/Users/mcros/Documents/obfuscator/docs/07_presentacion/puntos_de_venta.md)

## Alcance del diseño

El documento deja definidos:

- problema de usabilidad actual;
- enfoque recomendado;
- estructura de pantalla;
- ficha lateral;
- semantica de roles;
- reglas iniciales de sugerencia automatica;
- estrategia de ayuda;
- e implementacion sugerida por fases.

## Verificacion

No se corrieron tests del producto en este paso porque fue una definicion de diseno, no una modificacion funcional del comportamiento.

La validacion realizada fue:

- coherencia con el modelo `release-safe` ya implementado;
- coherencia con los hallazgos de prueba manual recientes;
- y utilidad directa para futura planificacion e insumos de presentacion tecnica.

## Siguiente paso recomendado

Usar este diseno como base para escribir un plan de implementacion UX/UI especifico antes de tocar el flujo principal de clasificacion.
