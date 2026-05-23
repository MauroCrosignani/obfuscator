# Relevamiento de Limpiezas Post Modularizacion del Helper IA

## Fecha

2026-05-23

## Proposito

Relevar limpiezas pendientes despues de completar las particiones internas del helper de perfilado seguro para IA, sin borrar ni mover artefactos que puedan tener valor historico o de desarrollo local sin decision explicita.

## Estado observado

El helper IA quedo separado en modulos internos:

- [ai_profile_utils.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_utils.R)
- [ai_profile_source_context.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_source_context.R)
- [ai_profile_metadata.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_metadata.R)
- [ai_profile_variables.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_variables.R)
- [ai_profile_render.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_render.R)
- [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R)

Despues de la quinta particion, [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R) conserva principalmente:

- heuristicas de nombres para roles y configuracion;
- normalizacion y validacion de `config`;
- orquestacion de `profile_dataset_for_ai()`;
- API publica `resumen_de()`.

## Limpiezas recomendables

### 1. Worktrees historicos de experimentos con agentes

Se detectaron worktrees locales bajo `.worktrees/`:

- `dispatch-iter1-a-task2`: cambios locales no committeados en `R/shiny_app.R`; no borrar automaticamente.
- `dispatch-iter1-b-task2`: cambios locales y documentos no trackeados; no borrar automaticamente.
- `dispatch-iter2-a-task10`: cambios locales y test no trackeado; no borrar automaticamente.
- `dispatch-iter2-b-task10`: cambios locales y documentos/tests no trackeados; no borrar automaticamente.
- `dispatch-iter3-a-task4`: cambios locales y test no trackeado; no borrar automaticamente.
- `dispatch-iter3-b-task4`: cambios locales y documentos/tests no trackeados; no borrar automaticamente.
- `release-contract-task0`: varios commits unicos frente a `main` y documentos no trackeados; no borrar automaticamente.
- `task7-release-safe-alignment`: cambios locales no committeados; no borrar automaticamente.

Recomendacion:

- revisar si contienen cambios no integrados antes de eliminarlos;
- si estan cerrados documentalmente, removerlos con `git worktree remove`;
- luego borrar ramas locales asociadas solo si ya no aportan trazabilidad.

No se eliminaron automaticamente para evitar perder evidencia de experimentos o cambios locales no revisados.

### 2. Archivos raiz con posible valor historico o local

Se observaron archivos versionados en la raiz que conviene clasificar antes de la extraccion a `contextoia`:

- [README_gitlab.md](c:/Users/mcros/Documents/obfuscator/README_gitlab.md): README alternativo para clonacion o uso en GitLab corporativo; conservar por ahora o mover a documentacion de distribucion corporativa.
- [pruebas_migracion_gitlab.R](c:/Users/mcros/Documents/obfuscator/pruebas_migracion_gitlab.R): runner manual de pruebas de migracion a GitLab; candidato a `scripts/` o `docs/99_archivo/` segun vigencia.
- [verify_consistency.R](c:/Users/mcros/Documents/obfuscator/verify_consistency.R): smoke test manual de consistencia/reversion; candidato a `scripts/` si sigue vigente.
- [lanzar_obfuscator.bat](c:/Users/mcros/Documents/obfuscator/lanzar_obfuscator.bat): launcher local de desarrollo en laptop; conservar en raiz mientras siga siendo util.
- [CLAUDE.md](c:/Users/mcros/Documents/obfuscator/CLAUDE.md): guia para agentes Claude; se sincronizo con [AGENTS.md](c:/Users/mcros/Documents/obfuscator/AGENTS.md) en estado/protocolo vigente.

Recomendacion:

- decidir si siguen siendo parte del producto, de migracion historica, de desarrollo local o de documentacion para agentes;
- mover a `docs/99_archivo/` lo que sea historico;
- mantener en raiz solo lo necesario para usuarios o automatizacion vigente.

No se movieron automaticamente porque algunos pueden ser utiles para la historia del proyecto o para flujos locales ya existentes.

### 3. Documentacion historica que menciona `R/ai_dataset_profile.R`

Hay muchos documentos anteriores que describen correctamente el estado historico donde el helper estaba concentrado en [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R).

Recomendacion:

- no reescribir documentos historicos de planes o cierres ya ejecutados;
- si se crea una guia vigente para `contextoia`, usar las rutas modulares nuevas;
- en documentos vigentes de referencia, agregar una nota de estado actual si todavia inducen a editar solo `ai_dataset_profile.R`.

### 4. Nombre de `ai_dataset_profile.R`

El nombre sigue siendo comprensible, pero despues de las particiones internas el archivo ya no contiene todo el perfilado.

Recomendacion:

- no renombrarlo todavia dentro de ObfuscatoR, para evitar churn antes de la extraccion;
- al crear `contextoia`, evaluar nombres mas expresivos como `profile_dataset.R`, `api_resumen.R` o `orquestacion_perfil.R`, manteniendo `resumen_de()` como unica funcion publica amigable.

### 5. Preparacion real de paquete `contextoia`

La limpieza estructural mas relevante ya no es otra particion interna, sino crear un plan de extraccion a paquete independiente.

Recomendacion:

- definir esqueleto de paquete `contextoia`;
- decidir exports publicos;
- trasladar tests del helper;
- declarar dependencias con flujo `usethis`/`devtools`;
- preservar compatibilidad transicional desde ObfuscatoR mientras se migra.

## Limpiezas no recomendadas por ahora

- No eliminar documentos historicos solo porque mencionan rutas antiguas.
- No borrar worktrees sin revisar si contienen cambios no integrados.
- No renombrar `ai_dataset_profile.R` antes de decidir la estructura del paquete independiente.
- No mover `lanzar_obfuscator.bat` si sigue siendo util para desarrollo local en esta laptop.

## Siguiente paso sugerido

Hacer un bloque separado de housekeeping documental/operativo para:

1. decidir explicitamente que worktrees se conservan por evidencia y cuales se archivan;
2. mover, si corresponde, scripts historicos de migracion a `scripts/` o `docs/99_archivo/`;
3. ejecutar el plan de extraccion inicial de `contextoia`.
