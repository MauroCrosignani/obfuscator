# Task 8 - Degradacion del tablero heredado

## Resumen

Se implemento la octava task del plan de rediseño UX/UI de clasificacion `release-safe`.

Conclusion practica:
- la tabla principal por variable queda consolidada como camino dominante;
- el drag-and-drop viejo deja de presentarse como clasificacion principal;
- y el modo heredado pasa a quedar explicitamente marcado como secundario y experimental.

## Objetivo del task

Retirar o degradar el mecanismo heredado de arrastre de forma que la interfaz no transmita dos modelos principales en competencia.

En esta fase se eligio la estrategia de:

- **degradacion fuerte**, no retiro completo.

## Archivos modificados

- [R/shiny_app.R](c:/Users/mcros/Documents/obfuscator/R/shiny_app.R)
- [www/app.css](c:/Users/mcros/Documents/obfuscator/www/app.css)
- [test_obfuscator.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_obfuscator.R)

## Cambios realizados

### 1. Clasificacion principal explicitada

La seccion de la tabla release-safe ahora declara de forma directa que:

- es el `mecanismo principal de clasificacion`.

Esto reduce ambigüedad al probar o presentar la app.

### 2. Tablero viejo colapsado y marcado como experimental

El flujo heredado de arrastre:

- ya no aparece desplegado como parte del flujo principal;
- pasa a un bloque `details`;
- y queda rotulado como:
  - `Modo heredado de arrastre (experimental)`.

### 3. Cambio de lenguaje

Se reemplazo la presentacion anterior del tablero heredado por una redaccion mas honesta:

- `Tablero heredado`
- uso solo para apoyar o corregir la transicion
- tabla principal y ficha lateral como camino preferido

### 4. Estilo visual acorde a su nuevo rol

Se agregaron estilos para el bloque colapsable heredado, reforzando visualmente que:

- existe;
- pero no es el modo recomendado.

## Casos de prueba cubiertos

En [test_obfuscator.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_obfuscator.R) quedo cubierta la verificacion de que la UI:

- sigue exponiendo la tabla principal;
- la describe como mecanismo principal;
- y marca el camino viejo como `experimental`.

## Verificacion ejecutada

Comandos corridos:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R')"
Rscript tests/testthat.R
```

Resultados:

- `test_obfuscator.R`: `PASS 119`
- suite completa: `PASS 341`

Nota:
- aparecio el warning de entorno `package 'testthat' was built under R version 4.2.3`, sin impacto funcional.

## Alternativas consideradas

### 1. Eliminar por completo el drag-and-drop

Motivo de descarte:
- todavia puede servir como respaldo transitorio mientras se consolida la migracion;
- y cortarlo ahora aumentaba el riesgo de retrabajo si algun flujo dependiente quedaba sin reemplazo visible.

### 2. Mantenerlo visible como hasta ahora

Motivo de descarte:
- seguia comunicando que habia dos mecanismos principales equivalentes;
- y eso iba en contra del objetivo del rediseño.

## Impacto sobre presentacion tecnica

Este task mejora mucho la claridad al mostrar el MVP:

- ya no hace falta explicar por narrativa oral que “lo importante es la tabla nueva”;
- la propia interfaz lo deja claro;
- y el modo viejo queda defendiblemente relegado a compatibilidad transitoria.

## Limites vigentes

- el tablero heredado sigue existiendo;
- el codigo JS de arrastre sigue presente como soporte;
- y la retirada completa puede evaluarse despues de la validacion manual final.

## Siguiente paso recomendado

Ejecutar la Task 9 del plan:

- verificacion completa;
- ajuste final del plan manual de pruebas;
- y cierre del bloque UX/UI release-safe.
