## Resumen ejecutivo

- fase o hito: etapa 2 de contexto de fuente para `dataset_profile_for_ai()`
- fecha: 2026-05-18
- estado: completado
- conclusion practica: el helper ahora puede recibir un `archivo_fuente` opcional y resolver de forma liviana si el origen se parece a `GCA.net` o `GCA2`, degradando con advertencias cuando la evidencia no alcanza.

## Objetivo de la fase

Agregar una segunda capa de contexto de origen basada en el artefacto fuente, sin depender todavia de metadata por carpeta ni de inspeccion del script activo.

## Contexto de entrada

Ya existia la etapa 1:

- `tipo_fuente`
- trazabilidad declarada por el usuario

Tambien ya estaban aprobados:

- el diseno de deteccion de `GCA.net`
- el diseno de deteccion de `GCA2`
- y la regla central de degradacion segura:
  - mejor volver a heuristicas que aplicar metadata equivocada con falsa confianza

## Decisiones tomadas

- introducir `archivo_fuente = NULL` en `profile_dataset_for_ai()`
- validar existencia del archivo sin volver obligatorio su uso
- soportar deteccion liviana por contenido de libro para:
  - `GCA.net`
  - `GCA2`
- mantener `tipo_fuente` como capa superior cuando el usuario lo declara
- guardar informacion del archivo dentro de `source_context$file`
- no forzar contexto fuerte cuando el libro es ambiguo o incompleto

## Alternativas consideradas

- postergar por completo `archivo_fuente`
- depender del nombre del archivo como unica evidencia
- leer solo la hoja cargada y no el libro completo
- volver error duro cualquier archivo no resoluble

## Motivo de la eleccion

Postergar `archivo_fuente` hubiera retrasado una mejora muy valiosa para el contexto real de uso. Confiar solo en el nombre del archivo era demasiado fragil. Leer solo una hoja perdia justo la metadata que distingue `GCA.net` y `GCA2`. Y convertir todo caso ambiguo en error duro hacia la API demasiado hostil.

La implementacion elegida mejora mucho el contexto disponible sin dejar de ser opcional y prudente.

## Implementacion realizada

En [R/ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R):

- nuevo parametro `archivo_fuente = NULL`
- helpers nuevos:
  - `ai_profile_simple_hash()`
  - `ai_profile_slugify()`
  - `ai_profile_read_sheet_matrix()`
  - `ai_profile_sheet_char_matrix()`
  - `ai_profile_find_label_value()`
  - `ai_profile_detect_gca_source_from_workbook()`
  - `ai_profile_detect_gca2_source_from_workbook()`
  - `ai_profile_detect_source_from_file()`
  - `ai_profile_merge_source_context()`
- enriquecimiento de `source_context` con:
  - `source_id`
  - `file`
  - `details`
- deteccion liviana de:
  - firma `Informacion de la consulta` + `Datos_Consulta*` para `gca`
  - firma `Caratula` + `salida_gca` e `Id de Consulta` para `gca2`

En [test_ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_ai_dataset_profile.R):

- pruebas para:
  - `archivo_fuente = NULL`
  - archivo inexistente
  - archivo con firma `GCA.net`
  - archivo con firma `GCA2`
  - archivo ambiguo o incompleto

## Ejemplo de uso actual

```r
source("c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R")

profile <- profile_dataset_for_ai(
  data = mi_dataset,
  dataset_name = "consulta_personas",
  archivo_fuente = "c:/ruta/consulta_18631_123456.xlsx"
)

cat(render_dataset_profile_for_ai(profile))
```

Ejemplo combinado con contexto declarado:

```r
profile <- profile_dataset_for_ai(
  data = mi_dataset,
  dataset_name = "consulta_personas",
  tipo_fuente = "gca2",
  archivo_fuente = "c:/ruta/consulta_18631_123456.xlsx"
)
```

## Verificacion ejecutada

- `Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"` -> `PASS 98`
- `Rscript tests/testthat.R` -> `PASS 482`

## Riesgos, limites o deuda remanente

- el detector `GCA.net` se prueba por firma de contenido, no por un `.xls` binario real
- no se inspeccionan aun multiples hojas de datos para detectar carga parcial
- las salidas `.csv` todavia no tienen resolvedor especifico
- `oracle` sigue siendo una categoria declarativa, no una deteccion automatica
- no existe aun matching contra metadata por carpeta

## Impacto sobre la especificacion

Este paso convierte al helper en algo bastante mas contextual: ya no solo describe el objeto actual, sino que puede empezar a reconocer de que familia de fuente proviene el artefacto cuando el usuario conserva el archivo original.

## Impacto sobre la futura presentacion tecnica

Fortalece la narrativa de que el subproyecto no solo protege lo que se muestra a una IA, sino que intenta entender de donde vino ese dataset y con que grado de confianza puede afirmar algo sobre su origen.

## Siguiente paso recomendado

El siguiente salto natural es la fase 3:

- lectura de metadata por carpeta
- validacion de la ficha JSON canonica
- y matching inicial por `source_id` o `aliases`

sin abrir todavia matching avanzado de columnas ni alertas por desajustes.
