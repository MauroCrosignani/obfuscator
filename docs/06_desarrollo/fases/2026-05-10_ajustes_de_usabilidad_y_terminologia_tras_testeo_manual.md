# Ajustes de usabilidad y terminologia tras testeo manual

## Objetivo del paso

Resolver observaciones surgidas durante el testeo manual temprano del rediseño release-safe, priorizando claridad operativa, consistencia terminologica y senales visuales mas comprensibles.

## Contexto de entrada

Durante los casos manuales 1 a 5C se detectaron varios problemas de usabilidad:

- el selector de objetos del entorno podia quedar visualmente por debajo del panel siguiente;
- el bloque `Opciones Avanzadas` tenia poca separacion del boton principal y poca affordance de click;
- el boton `Editar` resultaba enganoso porque la ficha lateral no edita directamente;
- el estado `Sugerido` se mostraba tambien para `KEEP`, lo que confundia su diferencia respecto de `QI`;
- la etiqueta `REMANENTE` no era la mejor descripcion para una salida de demo;
- `k-anonymity` no venia activo por defecto pese al modelo conceptual actual del producto.

## Decisiones tomadas

1. Se activo `k-anonymity` por defecto en la configuracion de la UI.
2. Se renombro la accion de tabla de `Editar` a `Ver detalle`.
3. Se reescribio la ayuda contextual de la ficha para indicar con claridad que el cambio de rol se hace desde la tabla principal.
4. Se cambio la opcion de supresion residual y su resultado visible desde el lenguaje de `remanentes` a `categorias residuales` / `AGRUPADO`.
5. Se ajusto la logica visual para que `Sugerido` quede reservado a `QI` y no a variables `KEEP`.
6. Se reforzo el estilo visual de `Opciones Avanzadas` y del control inline de rol.
7. Se elevo el `z-index` del selector de entorno para evitar solapamientos visuales con el panel siguiente.

## Alternativas consideradas

- Mantener `Editar` y agregar una nota aclaratoria.
  - Se descarto porque seguia induciendo a pensar que la ficha lateral edita directamente.
- Mantener `REMANENTE`.
  - Se descarto porque suena demasiado tecnico y no describe tan bien el sentido de generalizacion visible.
- Mantener `KEEP` como `Sugerido`.
  - Se descarto porque licuaba la diferencia entre una variable analitica conservada y un quasi-identificador sugerido.

## Implementacion realizada

Archivos principales modificados:

- [R/shiny_app.R](c:/Users/mcros/Documents/obfuscator/R/shiny_app.R)
- [R/obfuscator_core.R](c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R)
- [www/app.css](c:/Users/mcros/Documents/obfuscator/www/app.css)
- [tests/testthat/test_release_safe_roles_ui.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_release_safe_roles_ui.R)
- [tests/testthat/test_obfuscator.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_obfuscator.R)
- [docs/03_planes/manual_testing_plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/manual_testing_plan.md)

Cambios concretos:

- `enable_k = TRUE` como default release-safe;
- `Ver detalle` como accion principal de la tabla;
- mensaje de ficha lateral orientado a leer detalle y cambiar rol desde la tabla;
- `Agrupar categorias residuales` como rotulo de supresion residual;
- salida `AGRUPADO` en el core cuando aplica agrupacion residual;
- mejoras visuales de espacio y contraste en controles inline y `Opciones Avanzadas`;
- ajuste de `z-index` para el dropdown del entorno;
- actualizacion del plan de testeo manual para reflejar la nueva terminologia.

## Verificacion ejecutada

- `Rscript -e "library(testthat); test_file('tests/testthat/test_release_safe_roles_ui.R'); test_file('tests/testthat/test_obfuscator.R')"`
  - Resultado: verde
- `Rscript tests/testthat.R`
  - Resultado: `PASS 346`

## Riesgos o limites conocidos

- El fix del selector de entorno se basa en apilado visual (`z-index`). Conviene confirmarlo visualmente de nuevo con varios objetos cargados en el Environment.
- La ficha lateral sigue siendo principalmente explicativa. No edita tratamiento tecnico fino todavia desde el panel.
- La ayuda ya es mas clara, pero todavia puede madurar mas si en pruebas posteriores aparecen dudas repetidas sobre `KEEP`, `QI`, `SENS` y `PRIV`.

## Impacto sobre la especificacion

No cambia el contrato conceptual de la `spec v3.1`, pero si mejora la alineacion entre:

- el modelo release-safe documentado;
- la terminologia visible de la UI;
- y la interpretacion que una persona usuaria puede hacer del estado de cada variable.

## Impacto sobre la futura presentacion

Este paso mejora varios puntos de demo:

- el sistema ya no sugiere una accion falsa de edicion;
- `k-anonymity` aparece como comportamiento base del flujo actual;
- la salida agrupada usa una palabra mas comprensible para audiencias tecnicas no autoras del proyecto;
- y el testeo manual ya puede seguir sobre una interfaz mas coherente.

## Siguientes pasos

1. Repetir visualmente los casos ya observados para confirmar:
   - selector del entorno;
   - separacion visual de badges y selectores;
   - affordance de `Opciones Avanzadas`;
   - comportamiento de `KEEP` vs `QI`.
2. Retomar el plan de testeo manual desde `Caso 5D` en adelante.
