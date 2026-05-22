# Decision de API Publica en Espanol para `contextoia`

## Fecha

2026-05-22

## Objetivo del paso

Resolver la tension entre dos ideas que aparecian en la documentacion:

- por un lado, `contextoia` debe tener interfaz publica en espanol;
- por otro, el helper todavia conserva funciones tecnicas con nombres en ingles: `profile_dataset_for_ai()` y `render_dataset_profile_for_ai()`.

## Decision

La API publica del helper queda, por ahora, limitada a:

- `resumen_de()`

Las funciones:

- `profile_dataset_for_ai()`
- `render_dataset_profile_for_ai()`

siguen disponibles como capa tecnica heredada dentro del desarrollo, pero no se exportan como API publica nueva.

## Justificacion

Esta decision mantiene alineado el producto con el criterio de adopcion definido por el usuario:

- una sola funcion principal;
- nombre en espanol;
- interfaz facil de usar;
- y futura extraccion a un paquete pensado para usuarios hispanohablantes.

Exportar funciones tecnicas en ingles ahora generaria una superficie publica menos coherente justo cuando el helper empieza a prepararse para vivir como paquete independiente.

## Contrato agregado

Se agrego una prueba en [test_ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_ai_dataset_profile.R) para fijar que:

- `resumen_de()` debe estar exportada;
- `profile_dataset_for_ai()` no debe exportarse por ahora;
- `render_dataset_profile_for_ai()` no debe exportarse por ahora.

## Documentacion actualizada

Se alinearon:

- [2026-05-22-diseno-de-transicion-hacia-contextoia-como-paquete-independiente.md](c:/Users/mcros/Documents/obfuscator/docs/02_diseno/2026-05-22-diseno-de-transicion-hacia-contextoia-como-paquete-independiente.md)
- [2026-05-22-transicion-hacia-contextoia-como-paquete-independiente-implementation-plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-22-transicion-hacia-contextoia-como-paquete-independiente-implementation-plan.md)
- [2026-05-22-miniauditoria-de-fronteras-hacia-contextoia.md](c:/Users/mcros/Documents/obfuscator/docs/04_auditorias/2026-05-22-miniauditoria-de-fronteras-hacia-contextoia.md)
- [2026-05-22_desacople_inicial_de_utilidades_del_helper_ia_hacia_contextoia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-22_desacople_inicial_de_utilidades_del_helper_ia_hacia_contextoia.md)

## Limitaciones

Esta decision no impide que mas adelante exista una API tecnica publica.

Si aparece una necesidad real, convendra diseñarla deliberadamente, probablemente con nombres en espanol, en vez de exportar sin mas los nombres tecnicos heredados.

## Siguiente paso sugerido

Evaluar si [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R) debe modularizarse internamente antes de una extraccion real a `contextoia`.
