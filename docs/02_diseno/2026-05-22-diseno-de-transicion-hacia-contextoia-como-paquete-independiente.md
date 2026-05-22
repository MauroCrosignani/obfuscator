# Diseno de transicion hacia `contextoia` como paquete independiente

## Resumen

Este documento fija la direccion arquitectonica para el helper de perfilado seguro para IA: evolucionar hacia un paquete R independiente llamado `contextoia`, con `resumen_de()` como interfaz principal y completamente en espanol.

La decision no es extraerlo de inmediato, sino preparar esa separacion de forma ordenada y con bajo riesgo.

## Decision principal

El helper de perfilado seguro para IA no deberia reforzar su acoplamiento estructural con ObfuscatoR.

En cambio, mientras siga viviendo dentro de este repositorio, conviene tratarlo como un submodulo extraible que:

- funcione bien con `devtools::load_all()`;
- mantenga compatibilidad transicional con `source("R/obfuscator_core.R")`;
- y reduzca dependencias innecesarias del flujo Shiny o del dominio principal de liberacion controlada.

## Nombre y puerta de entrada

Se fijan estas decisiones de interfaz:

- nombre futuro del paquete: `contextoia`
- funcion principal recomendada: `resumen_de()`

La interfaz visible debe mantenerse exclusivamente en espanol.

## Problema que resuelve este diseno

Hoy el helper vive dentro de ObfuscatoR y eso crea una tension:

- por un lado, ya tiene entidad propia como herramienta de descripcion segura para IA;
- por otro, todavia se usa desde un repo cuyo objetivo principal es distinto.

Si hoy se solucionara `load_all()` solo como parche local, se podria reforzar un acoplamiento que despues haga mas costosa la separacion.

Por eso el objetivo de este diseno es que cualquier mejora de carga o empaquetado:

- sirva hoy para el flujo con `{devtools}` y `{usethis}`;
- y a la vez facilite la futura extraccion a `contextoia`.

## Alcance

Este diseno cubre:

1. estrategia de transicion;
2. criterio de carga como paquete;
3. criterio de compatibilidad transicional con `source()`;
4. y criterio de desacople interno.

## No alcance

Este documento no cubre todavia:

- la extraccion efectiva a otro repositorio;
- renombres masivos de archivos;
- reescritura completa del loader actual;
- ni cambios sobre la app Shiny principal.

## Alternativas consideradas

### 1. Mantener el helper dentro de ObfuscatoR y solo parchear `load_all()`

No se elige porque resuelve la molestia inmediata, pero no ayuda a la futura separacion.

### 2. Separarlo inmediatamente a otro repo

No se elige por ahora porque aumenta riesgo operativo y rompe continuidad del trabajo actual antes de cerrar bien la compatibilidad y el desacople.

### 3. Tratarlo ya como submodulo extraible dentro de este repo

Esta es la opcion recomendada porque:

- mejora el flujo actual;
- baja el costo de extraccion futura;
- y evita meter decisiones irreversibles demasiado pronto.

## Arquitectura recomendada

### Etapa 1. Compatibilidad limpia como paquete dentro de este repo

Objetivo:

- que el helper funcione bien con `devtools::load_all()`;
- sin depender de resoluciones fragiles basadas en el directorio de trabajo;
- y manteniendo `source("R/obfuscator_core.R")` como puente transicional.

### Etapa 2. Aislamiento interno

Objetivo:

- identificar que partes pertenecen realmente al futuro `contextoia`;
- reducir acoplamientos con Shiny, liberacion controlada y loaders heredados;
- y dejar fronteras claras entre:
  - API del helper;
  - core tecnico;
  - y puente de compatibilidad dentro de ObfuscatoR.

### Etapa 3. Extraccion real

Objetivo:

- mover el helper a un paquete independiente `contextoia`;
- conservar `resumen_de()` como interfaz principal;
- y decidir despues si ObfuscatoR lo consume como dependencia o deja de depender de el.

## Criterio de diseno para los proximos cambios

Toda mejora nueva en este frente deberia evaluarse con esta pregunta:

> ¿Este cambio hace mas facil o mas dificil extraer luego `contextoia` a un paquete propio?

Si el cambio:

- mete referencias duras a Shiny;
- asume que el helper solo puede vivir dentro de `obfuscator_core.R`;
- o refuerza carga por `sys.source()` entre archivos de `R/`;

entonces va en contra de este diseno.

## Recomendacion final

El siguiente paso correcto no es extraer ya el paquete, sino:

- mejorar la compatibilidad con carga tipo paquete;
- desacoplar internamente el helper;
- y dejar `source()` como compatibilidad transicional, no como arquitectura principal.

## Siguiente paso sugerido

Preparar un plan corto de implementacion para:

1. soportar mejor `devtools::load_all()`;
2. reducir dependencia de loaders fragiles;
3. y documentar que parte del helper se considera ya perteneciente al futuro `contextoia`.
