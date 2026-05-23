# Extraccion Inicial de `contextoia` como Paquete Independiente

## Objetivo

Crear un paquete R independiente llamado `contextoia` que concentre el helper de perfilado seguro para IA, manteniendo una interfaz publica simple y en espanol, y preservando una compatibilidad transicional desde ObfuscatoR.

## Principios de implementacion

- La API publica principal debe ser `resumen_de()`.
- Los nombres de parametros publicos deben mantenerse en espanol.
- Las funciones tecnicas en ingles pueden permanecer internas durante la transicion.
- La extraccion debe ser incremental, verificable y reversible.
- La gestion de dependencias debe seguir el flujo habitual con `devtools` y `usethis` cuando se agreguen paquetes.

## Estado de partida

El helper IA ya esta modularizado en:

- [ai_profile_utils.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_utils.R)
- [ai_profile_source_context.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_source_context.R)
- [ai_profile_metadata.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_metadata.R)
- [ai_profile_variables.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_variables.R)
- [ai_profile_render.R](c:/Users/mcros/Documents/obfuscator/R/ai_profile_render.R)
- [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R)

La suite focalizada actual vive en:

- [test_ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_ai_dataset_profile.R)

## Fase 1: Crear esqueleto del paquete

1. Crear estructura `contextoia/` en una rama dedicada.
2. Usar `usethis::create_package()` si se crea fuera del repo, o una estructura equivalente si se crea como subdirectorio transitorio.
3. Definir `DESCRIPTION` con nombre, titulo, licencia, autores y dependencias minimas.
4. Inicializar `testthat` con `usethis::use_testthat()`.
5. Definir `NAMESPACE` exportando solo `resumen_de()` al inicio.

## Fase 2: Migrar codigo del helper IA

1. Copiar los modulos `ai_profile_*.R` y `ai_dataset_profile.R`.
2. Revisar el orden de carga natural del paquete, evitando depender de `source()` manual.
3. Internalizar o declarar `%||%` como utilidad propia si sigue siendo necesaria.
4. Confirmar que no haya dependencias de Shiny ni de funciones `release_safe_*`.

## Fase 3: Migrar tests

1. Copiar tests focalizados del helper IA.
2. Adaptar rutas de fixtures y helpers de test.
3. Mantener tests de compatibilidad para:
   - `resumen_de()`;
   - `salida = "texto"`;
   - `salida = "estructura"`;
   - `modo = "normal"` y `modo = "conservador"`;
   - carga con metadata externa;
   - deteccion de GCA/GCA2 cuando haya archivo fuente.

## Fase 4: Dependencias y documentacion

1. Declarar dependencias con `usethis::use_package()`.
2. Usar `usethis::use_package(..., type = "Suggests")` para dependencias solo de tests o ejemplos.
3. Documentar `resumen_de()` con roxygen2.
4. Generar `NAMESPACE` con `devtools::document()`.
5. Agregar README minimo de `contextoia`.

## Fase 5: Compatibilidad transicional con ObfuscatoR

1. Decidir si ObfuscatoR sigue conteniendo copia interna del helper o si importa `contextoia`.
2. Mientras no exista version publicada de `contextoia`, mantener compatibilidad local con el codigo interno.
3. Evitar cambiar el comportamiento visible de `resumen_de()` durante la extraccion.
4. Agregar una nota en README de ObfuscatoR cuando el paquete independiente sea el camino recomendado.

## Verificacion requerida

Antes de cerrar la extraccion inicial:

```r
devtools::load_all("contextoia")
devtools::test("contextoia")
devtools::check("contextoia")
```

Y en ObfuscatoR:

```r
Rscript -e "source('R/obfuscator_core.R'); cat(exists('resumen_de', mode='function'))"
Rscript tests/testthat.R
```

## Riesgos

- duplicar codigo entre ObfuscatoR y `contextoia` por demasiado tiempo;
- declarar mal dependencias y romper CI en entornos limpios;
- exportar funciones tecnicas antes de estabilizar la API publica;
- perder compatibilidad con usuarios que hoy usan `source("R/obfuscator_core.R")`;
- mezclar limpieza documental con cambios funcionales.

## Decision recomendada

El proximo bloque de implementacion deberia crear el esqueleto de `contextoia` y migrar solo el helper IA, sin tocar todavia la app Shiny ni el flujo principal de ObfuscatoR.
