## Resumen ejecutivo

- fase o hito: etapa 1 de contexto de fuente para `dataset_profile_for_ai()`
- fecha: 2026-05-18
- estado: completado
- conclusion practica: el helper sigue siendo util sin contexto extra, pero ahora acepta `tipo_fuente` como pista declarativa liviana, en espanol y con trazabilidad visible.

## Objetivo de la fase

Agregar una primera capa de contexto de origen que permita orientar mejor la interpretacion del dataset sin exigir archivo fuente, metadata externa ni reconstruccion del pipeline.

## Contexto de entrada

Ya estaba aprobado el diseno incremental para este frente:

1. `tipo_fuente`
2. `archivo_fuente`
3. inspeccion futura del script activo

Tambien ya estaba decidido que:

- la API debia usar nombres en espanol;
- `oracle` debia ser la categoria semantica aprobada en lugar de `odbc`;
- y el helper debia seguir siendo util en modo cero-configuracion.

## Decisiones tomadas

- introducir `tipo_fuente = NULL` en `profile_dataset_for_ai()`
- aceptar en esta etapa:
  - `gca`
  - `gca2`
  - `oracle`
  - `excel`
  - `csv`
  - `desconocida`
- registrar el contexto declarado dentro de `source_context`
- no volver obligatorio `tipo_fuente`
- advertir en espanol cuando el usuario use `odbc` y sugerir `oracle`
- hacer visible el contexto declarado en el renderer solo cuando exista

## Alternativas consideradas

- no agregar todavia ninguna pista de contexto de fuente
- pasar directamente a `archivo_fuente`
- usar `odbc` como categoria tecnica principal
- forzar errores duros para cualquier valor invalido

## Motivo de la eleccion

No agregar ninguna pista dejaba al helper demasiado ciego frente a un conocimiento que muchas veces el usuario ya tiene. Pasar directamente a `archivo_fuente` abria demasiado alcance para esta etapa. Usar `odbc` mezclaba mecanismo tecnico con origen semantico. Y errores duros para cualquier valor invalido aumentaban friccion innecesariamente.

La opcion elegida mantiene el helper simple, mejora su utilidad real y conserva una degradacion elegante.

## Implementacion realizada

En [R/ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R):

- nuevo parametro `tipo_fuente = NULL`
- nuevo helper `ai_profile_normalize_tipo_fuente()`
- soporte de `source_context` en el perfil final con:
  - `type`
  - `source`
  - `confidence`
  - `warnings`
- integracion de advertencias de `tipo_fuente` al bloque global de `warnings`
- render opcional de una linea breve:
  - `Fuente declarada por el usuario: <tipo>.`

En [test_ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_ai_dataset_profile.R):

- pruebas para uso sin `tipo_fuente`
- pruebas para `tipo_fuente = "gca2"`
- pruebas para `tipo_fuente = "oracle"`
- pruebas para valor invalido `odbc`
- prueba de visibilidad del contexto en el renderer

## Ejemplo de uso actual

```r
source("c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R")

profile <- profile_dataset_for_ai(
  data = mi_dataset,
  dataset_name = "consulta_personas",
  tipo_fuente = "gca2"
)

cat(render_dataset_profile_for_ai(profile))
```

Ejemplo alternativo:

```r
profile <- profile_dataset_for_ai(
  data = mi_dataset,
  dataset_name = "relaciones_laborales",
  tipo_fuente = "oracle"
)
```

## Verificacion ejecutada

- `Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"` -> `PASS 79`
- `Rscript tests/testthat.R` -> `PASS 463`

## Riesgos, limites o deuda remanente

- `tipo_fuente` todavia no valida contra un archivo real
- no existe aun `archivo_fuente`
- todavia no hay resolvedor de metadata por carpeta
- `source_context` en esta etapa expresa declaracion del usuario, no deteccion automatica robusta
- no se resuelve aun la diferencia entre origen esperado y estado actual del objeto

## Impacto sobre la especificacion

Este paso consolida la primera capa de contexto de fuente y deja una base limpia para las siguientes fases. A partir de aqui, `archivo_fuente` y la metadata externa pueden integrarse sobre una estructura ya visible y testeada.

## Impacto sobre la futura presentacion tecnica

Refuerza que el subproyecto no es solo una muestra de filas mejorada: empieza a incorporar conocimiento del origen de los datos de una forma prudente, declarativa y compatible con el trabajo real en RStudio.

## Siguiente paso recomendado

El siguiente paso natural es la etapa 2:

- `archivo_fuente`
- deteccion basica de `GCA.net` y `GCA2`
- y resolucion inicial de contexto desde el artefacto origen, sin abrir todavia metadata por carpeta.
