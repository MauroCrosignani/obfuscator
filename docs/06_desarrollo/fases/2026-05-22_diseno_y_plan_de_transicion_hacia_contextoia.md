# Diseno y plan de transicion hacia `contextoia`

## Fecha

2026-05-22

## Objetivo del paso

Dejar asentada la estrategia para que el helper de perfilado seguro para IA pueda evolucionar hacia un paquete independiente `contextoia`, con `resumen_de()` como puerta de entrada principal y totalmente en espanol.

## Decisiones fijadas

- nombre futuro del paquete: `contextoia`
- funcion principal futura: `resumen_de()`
- direccion arquitectonica recomendada: tratar el helper como submodulo extraible dentro de este repo

## Criterio rector

Los proximos cambios sobre carga, bootstrap o organizacion interna deberian evaluarse segun si:

- facilitan la futura extraccion a `contextoia`;
- o refuerzan el acoplamiento con ObfuscatoR.

La recomendacion aprobada fue:

- mejorar compatibilidad con `devtools::load_all()`;
- mantener `source("R/obfuscator_core.R")` como puente transicional;
- y reducir dependencias fragiles del helper respecto al repo principal.

## Artefactos creados

- diseno:
  - [2026-05-22-diseno-de-transicion-hacia-contextoia-como-paquete-independiente.md](c:/Users/mcros/Documents/obfuscator/docs/02_diseno/2026-05-22-diseno-de-transicion-hacia-contextoia-como-paquete-independiente.md)
- plan:
  - [2026-05-22-transicion-hacia-contextoia-como-paquete-independiente-implementation-plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-22-transicion-hacia-contextoia-como-paquete-independiente-implementation-plan.md)

## Alcance del siguiente paso

El plan deja priorizado este orden:

1. auditar el mecanismo actual de carga del helper;
2. mejorar la compatibilidad con `devtools::load_all()`;
3. marcar fronteras internas del futuro `contextoia`;
4. documentar que queda como compatibilidad transicional y que queda listo para separacion.

## Verificacion

No se hicieron cambios de codigo ni se corrieron tests en esta pasada.

La salida de este paso es exclusivamente de diseno y plan.

## Siguiente paso sugerido

Ejecutar `Task 1` del plan empezando por [obfuscator_core.R](c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R), para entender bien el loader actual antes de proponer el ajuste para `load_all()`.
