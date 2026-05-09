# ObfuscatoR

Este README esta pensado para una clonacion en GitLab corporativo o en entornos con restricciones parciales de internet.

## Que es

ObfuscatoR es una herramienta en `R` para preparar datasets sensibles para su liberacion controlada a terceros, manteniendo el procesamiento local, la auditabilidad y un criterio conservador de bloqueo cuando la salida no es defendible.

La variante corporate-safe prioriza:

- funcionamiento local de la app Shiny sin depender de CDN en el flujo principal
- mensajes y documentacion en espanol
- fallback visible cuando una capacidad del navegador no esta garantizada
- compatibilidad con `source("obfuscator.R")` y con el paquete en `R/`
- una semantica clara de liberacion externa frente a artefactos internos de trabajo

## Que hace

- ofusca identificadores
- permuta fechas preservando estructura operativa
- transforma variables categoricas y numericas
- soporta reglas de consistencia
- permite `k-anonymity` con jerarquias configurables
- genera codigo R reproducible desde la app
- bloquea la exportacion externa salvo estado `Liberable`
- muestra reportes legibles de liberacion o no liberacion

## Advertencias importantes

- La IA debe tratarse como un tercero mas, no como un destinatario con reglas mas blandas.
- No todo dataset llega a ser liberable.
- Ejecutar un script o generar codigo R no equivale a aprobar una liberacion externa.
- Si la app bloquea la salida, ese bloqueo debe interpretarse como una restriccion metodologica real, no como un detalle opcional de UX.

## Uso rapido

```r
source("obfuscator.R")

cfg <- obfuscator_config(
  id_cols = c("ID_EMPRESA"),
  seed = 123,
  numeric_mode = "preserve_rank"
)

ofuscado <- obfuscate_dataset(mi_tabla, config = cfg)
```

## App Shiny

Para lanzarla desde la raiz del proyecto:

```r
source("R/obfuscator_core.R")
source("R/shiny_app.R")
run_obfuscator_app()
```

O por linea de comandos:

```sh
Rscript -e "source('R/obfuscator_core.R'); source('R/shiny_app.R'); run_obfuscator_app()"
```

## Nota para entorno corporativo

- La funcionalidad principal de Studio debe operar con assets locales del repositorio.
- Si el portapapeles programatico falla, la app debe permitir copia manual del codigo reproducible.
- Si tu instancia GitLab expone badges propios, sustituye este encabezado por el badge institucional correspondiente.
- Si prefieres un README sin badges remotos, puedes dejar este archivo tal cual o adaptarlo a un badge local.
- Si la organizacion necesita evidencia de por que una salida fue bloqueada, el flujo de auditoria de la app debe usarse como insumo y no reemplazarse por juicio informal.

## Tests

Desde la raiz del proyecto:

```sh
Rscript tests/testthat.R
```
