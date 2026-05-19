# Guia rapida de adopcion de `resumen_de()` desde RStudio

## Proposito

Dar un camino de uso muy corto para que una persona pueda probar el helper de perfilado seguro para IA sin tener que aprender primero su arquitectura interna.

## Cuando usar esta guia

Usa esta guia si:

- trabajas desde RStudio;
- quieres reemplazar rapidamente una inspeccion tipo `glimpse()`;
- y necesitas un texto prudente para pegar en una IA sin pasar muestras crudas del dataset.

## Camino mas simple

Si ya tienes el dataset cargado en el entorno:

```r
source("c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R")
cat(resumen_de(mi_dataset))
```

## Modo mas prudente

Si quieres que las categoricas no triviales se muestren de forma mas reservada:

```r
source("c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R")
cat(resumen_de(mi_dataset, modo = "conservador"))
```

## Si quieres inspeccionar la estructura

```r
source("c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R")
perfil <- resumen_de(mi_dataset, salida = "estructura")
str(perfil, max.level = 1)
```

## Ejemplos listos para correr

En el repo quedaron estos scripts:

- [demo_resumen_de_minimo.R](c:/Users/mcros/Documents/obfuscator/scripts/demo_resumen_de_minimo.R)
  - usa `iris` y muestra el camino feliz minimo.
- [demo_resumen_de_config.R](c:/Users/mcros/Documents/obfuscator/scripts/demo_resumen_de_config.R)
  - muestra un caso pequeno con `config` y `modo = "conservador"`.

## Que no hace falta saber para empezar

No hace falta empezar sabiendo:

- `profile_dataset_for_ai()`
- `render_dataset_profile_for_ai()`
- `tipo_fuente`
- `archivo_fuente`
- `metadata_dir`

Todo eso sigue existiendo, pero solo hace falta si el caso lo necesita.

## Siguiente escalon

Cuando el uso basico ya te quede comodo, el siguiente paso recomendado es:

1. agregar `config` solo si necesitas corregir heuristicas;
2. sumar `tipo_fuente` si conoces bien el origen;
3. y recien despues evaluar `archivo_fuente` o `metadata_dir`.
