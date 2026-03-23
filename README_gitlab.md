# ObfuscatoR

Este README está pensado para una clonación en GitLab corporativo o en entornos con restricciones parciales de internet.

## Qué es

ObfuscatoR es un paquete y script en `R` para ofuscar datasets sensibles y seguir trabajando con ellos de forma analítica, auditable y local.

La variante corporate-safe prioriza:

- funcionamiento local de la app Shiny sin depender de CDN en el flujo principal
- mensajes y documentación en español
- fallback visible cuando una capacidad del navegador no está garantizada
- compatibilidad con `source("obfuscator.R")` y con el paquete en `R/`

## Qué hace

- ofusca identificadores
- permuta fechas preservando estructura operativa
- transforma variables categóricas y numéricas
- soporta reglas de consistencia
- permite `k-anonymity` con jerarquías configurables
- genera código R reproducible desde la app

## Uso rápido

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

Para lanzarla desde la raíz del proyecto:

```r
source("R/obfuscator_core.R")
source("R/shiny_app.R")
run_obfuscator_app()
```

O por línea de comandos:

```sh
Rscript -e "source('R/obfuscator_core.R'); source('R/shiny_app.R'); run_obfuscator_app()"
```

## Nota para entorno corporativo

- La funcionalidad principal de Studio debe operar con assets locales del repositorio.
- Si el portapapeles programático falla, la app debe permitir copia manual del código reproducible.
- Si tu instancia GitLab expone badges propios, sustituye este encabezado por el badge institucional correspondiente.
- Si prefieres un README sin badges remotos, puedes dejar este archivo tal cual o adaptarlo a un badge local.

## Tests

Desde la raíz del proyecto:

```sh
Rscript tests/testthat.R
```
