# Diseno de identidad de fuente para metadata de perfilado IA

## Proposito

Definir como debe identificarse de forma estable una fuente de datos para asociarle metadata reutilizable dentro del subproyecto de perfilado seguro para IA.

El objetivo es que la metadata no dependa del nombre accidental del archivo exportado ni del script puntual que la consumio, sino de una identidad tecnica y funcional suficientemente estable.

## Problema de diseno

En el contexto de uso real de la organizacion, los datasets no provienen todos del mismo tipo de origen:

- consultas exportadas desde `GCA.net`
- consultas exportadas desde `GCA2`
- tablas o vistas extraidas desde bases Oracle usadas como Sandbox

Ademas:

- los nombres de archivo no siempre son confiables;
- en `GCA.net` el nombre del archivo puede depender del usuario;
- en `GCA2` el nombre del archivo puede tener un patron estable, pero incluye sufijos de ejecucion;
- y una misma consulta funcional puede existir tanto en `GCA.net` como en `GCA2` con identificadores distintos.

Por eso no conviene usar:

- el nombre del archivo como identidad principal;
- ni asumir equivalencia entre ids de `GCA.net` y `GCA2`;
- ni omitir la base en el caso de Oracle.

## Decision principal

Se recomienda una identidad **por tipo de origen**, con clave principal construida segun ese tipo:

- `gca:<numero_consulta>`
- `gca2:<numero_consulta>`
- `oracle:<base>.<schema>.<objeto>`

Las relaciones funcionales entre fuentes distintas no deben resolverse dentro de la clave principal, sino con un campo separado de relaciones o equivalencias.

## Tipos de fuente recomendados

Valores iniciales de `source_type`:

- `gca`
- `gca2`
- `oracle`

No se recomienda agregar mas tipos hasta necesitarlos de verdad.

## Campos comunes recomendados

### `version`

Version del formato del archivo de metadata.

Ejemplo:

```json
"version": 1
```

### `source_type`

Tipo tecnico de origen.

Ejemplos:

```json
"source_type": "gca"
"source_type": "gca2"
"source_type": "oracle"
```

### `source_id`

Identificador tecnico estable y canónico de la fuente.

Debe ser:

- unico dentro de la biblioteca;
- generado segun `source_type`;
- y util para matching exacto.

Ejemplos:

```json
"source_id": "gca:1234"
"source_id": "gca2:56789"
"source_id": "oracle:BASE1.ESQUEMA1.TABLA1"
```

### `display_name`

Nombre legible para humanos.

No cumple el rol de clave tecnica. Sirve para:

- UI futura
- inspeccion manual
- trazabilidad comprensible

Ejemplo:

```json
"display_name": "Padron de personas activas"
```

### `aliases`

Lista de nombres alternativos utiles para reconocer la fuente.

Puede incluir:

- nombre visible de la consulta
- variantes conocidas
- nombres de archivo estables cuando ayuden, pero no como identidad principal

Ejemplo:

```json
"aliases": [
  "Padron personas activas",
  "Consulta personas activas"
]
```

### `related_sources`

Lista de fuentes tecnicamente distintas pero funcionalmente relacionadas.

Esto sirve para casos como:

- una consulta migrada desde `GCA.net` a `GCA2`
- una fuente equivalente o sucesora

Ejemplo:

```json
"related_sources": [
  "gca:1234",
  "gca2:56789"
]
```

Importante:

- `related_sources` no significa identidad tecnica comun;
- solo expresa relacion funcional conocida.

### `source_details`

Bloque opcional con detalles especificos del tipo de origen.

Se recomienda porque `gca`, `gca2` y `oracle` no comparten los mismos metadatos.

## Detalles por tipo de fuente

### Para `gca`

```json
"source_details": {
  "query_id": "1234",
  "query_name": "Padron personas activas"
}
```

### Para `gca2`

```json
"source_details": {
  "query_id": "56789",
  "query_name": "Padron personas activas v2"
}
```

### Para `oracle`

```json
"source_details": {
  "database": "BASE1",
  "schema": "ESQUEMA1",
  "object_name": "TABLA1",
  "object_type": "table"
}
```

## Estructura minima recomendada

Ejemplo completo:

```json
{
  "version": 1,
  "source_type": "gca2",
  "source_id": "gca2:56789",
  "display_name": "Padron de personas activas",
  "aliases": [
    "Padron personas activas"
  ],
  "related_sources": [
    "gca:1234"
  ],
  "source_details": {
    "query_id": "56789",
    "query_name": "Padron personas activas v2"
  },
  "columnas": {}
}
```

## Reglas de resolucion recomendadas

Orden sugerido para identificar una fuente:

1. match exacto por `source_id`
2. match por `aliases`
3. si hay varias coincidencias plausibles:
   - no elegir automaticamente;
   - emitir advertencia de ambiguedad;
   - y preferir no aplicar metadata antes que aplicar la equivocada.

## Anti-patrones a evitar

No se recomienda:

- usar el nombre del archivo exportado como identidad principal
- asumir que `gca:1234` y `gca2:1234` son equivalentes
- omitir la base en el caso de Oracle
- mezclar identidad tecnica con relacion funcional en un unico campo

## Decision final

Se aprueba un modelo con:

- identidad principal por tipo de origen;
- nombre legible separado;
- aliases para reconocimiento;
- y relaciones funcionales expresadas por fuera de la clave tecnica.

Esto deja bien preparado el camino para definir despues el bloque `columnas` sin arrastrar ambiguedades sobre de que fuente se esta hablando.
