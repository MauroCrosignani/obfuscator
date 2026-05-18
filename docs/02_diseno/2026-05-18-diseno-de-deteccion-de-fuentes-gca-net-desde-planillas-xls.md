# Diseno de deteccion de fuentes `GCA.net` desde planillas `.xls`

## Proposito

Definir como deberia detectar e interpretar el sistema una fuente exportada desde `GCA.net` cuando el archivo disponible es una planilla `.xls` con estructura de metadatos embebida.

El objetivo es que la deteccion:

- no dependa ciegamente del nombre del archivo;
- aproveche la estructura fija de la hoja de informacion;
- y distinga con honestidad entre una identidad confirmada y una identidad solo inferida.

## Contexto de uso

En `GCA.net`, el nombre del archivo exportado no siempre es una pista confiable:

- puede depender totalmente del nombre que le haya dado el usuario;
- puede no incluir el numero de consulta;
- y distintas consultas pueden terminar con nombres parecidos.

En cambio, la planilla suele incluir una primera hoja con informacion estructurada sobre la consulta ejecutada.

### Ejemplo observado

Planilla `.xls` con:

- hoja `Informacion de la consulta`
- hoja `Datos_Consulta1`

Contenido relevante de la primera hoja:

- `A1`: `Planilla generada por el GCA: ...`
- `A3`: `TituloL`
- `A4`: titulo de la consulta
- `A6`: `Descripcion:`
- `A7`: descripcion libre de la consulta
- `A9`: `Parametros:`

En el ejemplo compartido:

- `A4`: `Plan de Codigo de la Cuenta`
- `A7`: incluye descripcion y lista declarada de columnas esperadas

## Problema de diseno

En muchos casos, la planilla permite afirmar con bastante confianza que el origen es `GCA.net`, pero no necesariamente permite reconstruir con certeza el numero de consulta.

Por eso no conviene:

- asumir que toda planilla `GCA.net` puede resolverse a `gca:<numero>`;
- ni tratar como identidad confirmada algo que en realidad solo se dedujo por titulo o estructura.

## Decision principal

La deteccion de `GCA.net` desde planillas `.xls` deberia trabajar con dos niveles de certeza:

1. **identidad confirmada**
2. **identidad provisional**

Y deberia registrar siempre:

- tipo de fuente detectado;
- evidencia estructural utilizada;
- nivel de confianza;
- y, si corresponde, un `source_id` provisional cuando no exista un id explicito confiable.

## Firma estructural recomendada para reconocer `GCA.net`

Se recomienda considerar que una planilla coincide con el patron `GCA.net` cuando se verifiquen en conjunto varias de estas señales:

- existencia de hoja `Informacion de la consulta`
- existencia de al menos una hoja `Datos_Consulta*`
- `A1` de la hoja informativa contiene `Planilla generada por el GCA`
- `A3` contiene o equivale a `TituloL`
- `A6` contiene `Descripcion:`
- `A9` contiene `Parametros:`

### Regla recomendada

No exigir coincidencia perfecta de todas las celdas para detectar el tipo de fuente, pero si exigir suficientes marcas combinadas como para que el reconocimiento no sea fragil.

## Metadatos que conviene extraer

Una vez detectada la firma `GCA.net`, el parser deberia intentar extraer:

- titulo de la consulta
- descripcion
- presencia o ausencia de parametros
- patron de nombres de hojas de datos
- columnas declaradas dentro de la descripcion, si estan presentes y son parseables
- formato del libro (`xls`)

## Modelo de salida recomendado para deteccion

Ejemplo conceptual:

```json
{
  "source_type_detected": "gca",
  "source_identity_confidence": "medium",
  "detection_evidence": {
    "workbook_format": "xls",
    "metadata_sheet_name": "Informacion de la consulta",
    "data_sheet_pattern": "Datos_Consulta*",
    "a1_matches_gca_signature": true,
    "a3_matches_title_label": true,
    "a6_matches_description_label": true,
    "a9_matches_parameters_label": true
  },
  "extracted_details": {
    "query_title": "Plan de Codigo de la Cuenta",
    "query_description": "Es la tabla entera cta_plan_codigo de produccion",
    "parameters_present": false,
    "declared_columns": [
      "CODIGO_CAJA",
      "CODIGO_PAGO",
      "SUBCODIGO_PAGO",
      "COD_TIPO_PAGO",
      "DESCRIPCION",
      "FECHA_CARGO_DESDE",
      "FECHA_CARGO_HASTA",
      "VIGENCIA_DESDE",
      "VIGENCIA_HASTA",
      "TIPO_APORTE",
      "MONEDA",
      "DISTRIBUIBLE",
      "PAGO_MINIMO",
      "VALIDO_CTA",
      "SIGNO",
      "TIPO_CREDITO",
      "IMPONIBLE_MULTA",
      "FECHA_ULT_ACT",
      "USUARIO_ULT_ACT",
      "DEDUCIBLE",
      "AFECTA_SECUENCIA",
      "OBLIG_CORRIENTE",
      "PRESCRIBE"
    ]
  }
}
```

## Identidad confirmada

Cuando por algun medio confiable el numero de consulta esta disponible y puede afirmarse sin ambiguedad, se recomienda:

```json
"source_type": "gca",
"source_id": "gca:5553"
```

Esto podria surgir, por ejemplo, de:

- una celda explicita con numero de consulta;
- metadata externa confiable;
- o una regla institucional confirmada que vincule sin dudas ese libro con ese id.

## Identidad provisional

Cuando el libro permite reconocer el origen y extraer metadata rica, pero no el numero de consulta, se recomienda construir una identidad provisional.

Ejemplo:

```json
"source_type": "gca",
"source_id": "gca:unresolved:plan-de-codigo-de-la-cuenta:sha1_abcd1234"
```

### Recomendacion para esa identidad provisional

Construirla con:

- prefijo `gca:unresolved:`
- slug del titulo de la consulta
- hash corto derivado de evidencia relativamente estable, por ejemplo:
  - titulo
  - descripcion
  - lista declarada de columnas

Esto reduce el riesgo de colision entre consultas con nombres parecidos.

## Nivel de confianza recomendado

### `high`

Usar cuando:

- se reconoce la firma `GCA.net`
- y se conoce de forma confiable el numero de consulta o una identidad canonica inequívoca

### `medium`

Usar cuando:

- se reconoce claramente la firma `GCA.net`
- se extraen titulo y descripcion
- pero no se dispone de id explicito confiable

### `low`

Usar solo si:

- hay señales parciales del formato,
- pero faltan varias marcas estructurales
- o la planilla esta degradada

En ese caso no conviene aplicar metadata automaticamente.

## Uso de la lista declarada de columnas

La lista declarada dentro de la descripcion es especialmente valiosa y se recomienda conservarla cuando pueda parsearse.

Puede servir para:

- comparar columnas observadas vs esperadas
- detectar campos faltantes
- advertir renombres o variaciones
- y reforzar el matching contra una ficha de metadata preexistente

Tambien puede ayudar a identificar columnas temporalmente delicadas como:

- `FECHA_CARGO_DESDE`
- `FECHA_CARGO_HASTA`
- `VIGENCIA_DESDE`
- `VIGENCIA_HASTA`
- `FECHA_ULT_ACT`

especialmente cuando el parser de R no las importe automaticamente como fecha o datetime.

## Relacion con la biblioteca de metadata

La resolucion recomendada para una planilla `GCA.net` deberia ser:

1. detectar si el libro coincide con la firma `GCA.net`
2. extraer titulo, descripcion y columnas declaradas
3. intentar match contra metadata conocida por:
   - `source_id` exacto si existe
   - `aliases`
   - fingerprint compatible
4. si no hay match confiable:
   - seguir con heuristicas del dataset
   - pero registrar que la fuente se detecto como `gca` con identidad no resuelta

## Que no deberia hacer esta etapa

No conviene que esta deteccion:

- reconstruya joins;
- infiera equivalencias funcionales con `GCA2` automaticamente;
- ni trate una coincidencia de titulo como si fuera identidad confirmada.

Las relaciones funcionales con otras fuentes, si existen, deberian expresarse despues en `related_sources`.

## Anti-patrones a evitar

No se recomienda:

- usar el nombre del archivo como identidad principal
- asumir que siempre existe el numero de consulta dentro del libro
- tratar el titulo como `source_id`
- o aplicar metadata declarada de otra fuente solo porque el nombre “se parece”

## Decision final

Se aprueba un modelo de deteccion `GCA.net` basado en:

- firma estructural de la hoja informativa
- extraccion de titulo, descripcion y columnas declaradas
- niveles de confianza explicitos
- e identidad provisional cuando no haya id confiable

Esto permite aprovechar mucha informacion util sin excederse en la seguridad de las afirmaciones sobre la identidad real de la consulta.
