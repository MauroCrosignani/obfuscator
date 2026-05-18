# Ficha JSON canonica de ejemplo para metadata de perfilado IA

## Proposito

Consolidar en un unico ejemplo canonico el formato recomendado para una ficha de metadata por fuente.

Esta ficha debe integrar:

- identidad de fuente;
- metadatos comunes;
- y bloque `columnas`.

El objetivo es dejar un ejemplo suficientemente completo para:

- guiar la futura implementacion en R;
- servir como contrato informal del formato;
- y facilitar una futura interfaz grafica de edicion sin volver a discutir el modelo base.

## Estructura canonica recomendada

```json
{
  "version": 1,
  "source_type": "gca2",
  "source_id": "gca2:56789",
  "display_name": "Padron de personas activas",
  "aliases": [
    "Padron personas activas",
    "Consulta personas activas"
  ],
  "related_sources": [
    "gca:1234"
  ],
  "source_details": {
    "query_id": "56789",
    "query_name": "Padron personas activas v2"
  },
  "columnas": {
    "persona_id": {
      "rol": "identificatoria",
      "descripcion": "Identificador interno de la persona"
    },
    "fecha_alta": {
      "rol": "temporal",
      "tipo_esperado": "datetime",
      "descripcion": "Fecha de alta del vinculo"
    },
    "fecha_hasta": {
      "rol": "temporal",
      "tipo_esperado": "datetime",
      "faltantes": "esperables",
      "descripcion": "Fecha de finalizacion del vinculo"
    },
    "tramo": {
      "rol": "cuasi_identificadora",
      "descripcion": "Tramo o segmento administrativo"
    },
    "diagnostico": {
      "rol": "sensible",
      "descripcion": "Categoria de diagnostico"
    },
    "observacion": {
      "rol": "texto_libre",
      "descripcion": "Observaciones administrativas"
    },
    "ingreso": {
      "rol": "analitica",
      "tipo_esperado": "numeric",
      "descripcion": "Ingreso nominal mensual"
    }
  }
}
```

## Lectura campo por campo

### `version`

Indica la version del formato de la ficha.

Ejemplo:

```json
"version": 1
```

Debe permitir evolucion futura sin romper consumidores viejos.

### `source_type`

Indica el tipo tecnico de origen.

Ejemplo:

```json
"source_type": "gca2"
```

Valores iniciales recomendados:

- `gca`
- `gca2`
- `oracle`

### `source_id`

Es la identidad tecnica principal y estable.

Ejemplo:

```json
"source_id": "gca2:56789"
```

No debe depender del nombre del archivo exportado ni del identificador de ejecucion de una descarga puntual.

### `display_name`

Nombre legible y apto para UI.

Ejemplo:

```json
"display_name": "Padron de personas activas"
```

### `aliases`

Nombres alternativos utiles para matching o reconocimiento asistido.

Ejemplo:

```json
"aliases": [
  "Padron personas activas",
  "Consulta personas activas"
]
```

### `related_sources`

Lista de fuentes tecnicamente distintas pero funcionalmente relacionadas.

Ejemplo:

```json
"related_sources": [
  "gca:1234"
]
```

Importante:

- no expresa identidad tecnica compartida;
- solo vinculo funcional o historico conocido.

### `source_details`

Bloque opcional con detalles especificos del origen.

Para `gca` o `gca2`, se recomienda:

```json
"source_details": {
  "query_id": "56789",
  "query_name": "Padron personas activas v2"
}
```

Para `oracle`, se recomienda una variante como:

```json
"source_details": {
  "database": "BASE1",
  "schema": "ESQUEMA1",
  "object_name": "TABLA1",
  "object_type": "table"
}
```

## Estructura del bloque `columnas`

Cada clave dentro de `columnas` representa el nombre real de una variable esperada en la fuente.

Ejemplo:

```json
"columnas": {
  "persona_id": {
    "rol": "identificatoria"
  }
}
```

### Regla principal

El nombre de la clave debe ser el nombre real de la columna, no un alias.

## Campos recomendados por variable

### `rol`

Campo central y obligatorio.

Valores recomendados:

- `identificatoria`
- `sensible`
- `texto_libre`
- `temporal`
- `cuasi_identificadora`
- `analitica`

### `tipo_esperado`

Campo opcional.

Valores recomendados:

- `character`
- `integer`
- `numeric`
- `date`
- `datetime`
- `logical`

Sirve especialmente para columnas que el parser puede importar de forma imperfecta.

### `faltantes`

Campo opcional.

Valor inicial recomendado:

- `esperables`

### `descripcion`

Campo opcional.

No debe ser obligatorio para mantener la carga baja, pero es muy util para:

- inspeccion humana;
- futura UI;
- y contexto semantico adicional.

## Ejemplo equivalente para Oracle

```json
{
  "version": 1,
  "source_type": "oracle",
  "source_id": "oracle:BASE1.ESQUEMA1.RELACIONES_LABORALES",
  "display_name": "Relaciones laborales activas",
  "aliases": [
    "RELACIONES_LABORALES"
  ],
  "related_sources": [],
  "source_details": {
    "database": "BASE1",
    "schema": "ESQUEMA1",
    "object_name": "RELACIONES_LABORALES",
    "object_type": "table"
  },
  "columnas": {
    "persona_id": {
      "rol": "identificatoria"
    },
    "fecha_desde": {
      "rol": "temporal",
      "tipo_esperado": "datetime"
    },
    "fecha_hasta": {
      "rol": "temporal",
      "tipo_esperado": "datetime",
      "faltantes": "esperables"
    },
    "sector": {
      "rol": "cuasi_identificadora"
    },
    "comentario": {
      "rol": "texto_libre"
    }
  }
}
```

## Como deberia usarlo el helper

La ficha no reemplaza por completo la heuristica del helper. La complementa.

Orden recomendado de precedencia:

1. `config` explicita del usuario
2. metadata de fuente
3. heuristica automatica

Eso significa que el helper podria:

- leer `rol`
- leer `tipo_esperado`
- leer `faltantes`
- y usarlos como overrides o refuerzos sobre su interpretacion automatica

## Que no deberia intentar resolver esta ficha

No se recomienda que este formato intente capturar todavia:

- joins entre fuentes;
- derivaciones complejas;
- logica del script intermedio;
- ni equivalencias transformacionales fila a fila.

La ficha describe una fuente, no un pipeline entero.

## Validaciones minimas recomendadas para el futuro parser

Cuando se implemente el parser de esta ficha, deberia validar:

- `version` presente y valida
- `source_type` dentro del vocabulario permitido
- `source_id` presente
- `display_name` presente
- `columnas` presente y con formato de objeto
- `rol` presente en cada columna declarada
- `tipo_esperado` dentro del vocabulario permitido cuando exista
- `faltantes` dentro del vocabulario permitido cuando exista

## Decision final

Se aprueba esta ficha como ejemplo canonico del formato JSON por fuente.

No es aun una especificacion formal de parser, pero si un contrato de diseno suficientemente claro para:

- implementar lectura en R;
- generar ejemplos reales;
- y mas adelante construir una interfaz visual de edicion sin reabrir la arquitectura basica.
