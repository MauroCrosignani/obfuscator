# Diseno del bloque `columnas` para metadata de perfilado IA

## Proposito

Definir la estructura minima y el vocabulario controlado del bloque `columnas` dentro de cada archivo JSON de metadata por fuente.

Este bloque debe permitir que R:

- lea la metadata de forma robusta;
- complemente las heuristicas automaticas del helper;
- y, mas adelante, pueda ser editado desde una interfaz grafica sin cambiar el modelo de datos.

## Problema de diseno

El bloque `columnas` no puede ser:

- tan pobre que no aporte mas que las heuristicas actuales;
- ni tan rico que obligue a describir manualmente decenas de variables para que la herramienta sea util.

Ademas, la metadata por variable tiene que servir para tres fines a la vez:

1. mejorar el perfil para IA;
2. hacer visibles expectativas institucionales sobre cada columna;
3. seguir siendo entendible y editable mas adelante desde una UI.

## Decision principal

Se recomienda un bloque `columnas` con:

- un diccionario por nombre de variable;
- pocos campos obligatorios;
- varios campos opcionales;
- y vocabulario controlado corto y estable.

No se recomienda en esta etapa:

- modelar reglas complejas por regex dentro de cada columna;
- guardar logica de joins o derivaciones;
- ni exigir descripcion exhaustiva para que la ficha sea valida.

## Estructura general recomendada

Ejemplo de estructura:

```json
{
  "columnas": {
    "persona_id": {
      "rol": "identificatoria",
      "descripcion": "Identificador interno de la persona"
    },
    "fecha_hasta": {
      "rol": "temporal",
      "tipo_esperado": "datetime",
      "faltantes": "esperables",
      "descripcion": "Fecha de finalizacion del vinculo"
    },
    "diagnostico": {
      "rol": "sensible",
      "descripcion": "Categoria de diagnostico"
    },
    "observacion": {
      "rol": "texto_libre",
      "descripcion": "Observaciones administrativas"
    }
  }
}
```

## Modelo recomendado por variable

Cada entrada dentro de `columnas` deberia ser un objeto con esta forma:

```json
"nombre_columna": {
  "rol": "...",
  "tipo_esperado": "...",
  "faltantes": "...",
  "descripcion": "..."
}
```

Todos los campos salvo `rol` deberian ser opcionales en la primera version.

## Campo `rol`

### Objetivo

Expresar la expectativa semantica principal sobre la columna.

### Valores recomendados

- `identificatoria`
- `sensible`
- `texto_libre`
- `temporal`
- `cuasi_identificadora`
- `analitica`

### Sentido practico

Este campo deberia mapearse facilmente al helper actual:

- `identificatoria` -> override de identificador
- `sensible` -> override de sensibilidad
- `texto_libre` -> override de texto libre
- `temporal` -> refuerzo de interpretacion temporal
- `cuasi_identificadora` -> sugerencia o override de rol semantico
- `analitica` -> explicitacion de columna util pero no riesgosa por defecto

### Recomendacion

`rol` deberia ser el unico campo realmente obligatorio para considerar util una ficha minima por variable.

## Campo `tipo_esperado`

### Objetivo

Permitir que la metadata exprese como se espera que llegue o deba entenderse la columna, especialmente cuando el parser puede fallar.

### Valores recomendados

- `character`
- `integer`
- `numeric`
- `date`
- `datetime`
- `logical`

### Uso esperado

No deberia reemplazar ciegamente el tipo observado, sino servir como:

- referencia;
- pista para interpretar;
- o advertencia cuando haya diferencia entre importado e inferido.

Ejemplo importante:

- una fecha con microsegundos puede llegar como `character`
- pero `tipo_esperado = "datetime"`

Eso ayuda a que el helper no la trate como texto cualquiera.

## Campo `faltantes`

### Objetivo

Declarar expectativas estructurales sobre valores faltantes.

### Valor inicial recomendado

- `esperables`

No agregaria mas valores hasta necesitarlos de verdad.

### Uso esperado

Este campo deberia alimentar la logica que hoy ya distingue:

- `expected`
- `high_unexpected`
- `present`
- `none`

La metadata aqui deberia tener precedencia sobre la heuristica por nombre.

## Campo `descripcion`

### Objetivo

Ayudar a:

- humanos que revisan la ficha;
- futuras interfaces;
- y eventualmente a enriquecer el contexto para IA si se decide usarlo.

### Recomendacion

Debe ser opcional.

No conviene volverla obligatoria porque subiria mucho la friccion de carga de metadata.

## Campos no recomendados por ahora

No agregaria todavia:

- `regex_esperada`
- `niveles_permitidos`
- `cuantiles_esperados`
- `owner`
- `ultima_actualizacion_manual`
- `ejemplos`

No porque sean malos, sino porque en esta etapa harian demasiado pesada la ficha.

## Reglas de validacion recomendadas

### 1. La clave del diccionario debe ser el nombre real de la columna

No usar aliases dentro del bloque `columnas`.

Si una columna se renombra despues en el script, eso deberia tratarse en otra capa, no aqui.

### 2. `rol` debe pertenecer al vocabulario controlado

Si aparece otro valor:

- advertir;
- o rechazar segun la politica futura.

### 3. `tipo_esperado` debe pertenecer al vocabulario permitido

Nada de cadenas libres en la primera version.

### 4. `faltantes` debe ser un conjunto muy chico

Inicialmente:

- solo `esperables`

### 5. Los campos desconocidos no deberian romper el parseo

Recomendacion:

- advertir y seguir, para no volver fragil la evolucion del archivo.

## Relacion con el helper actual

El bloque `columnas` deberia integrarse al helper como una capa de reglas declaradas.

Orden conceptual recomendado:

1. metadata de la fuente
2. `config` explicita del usuario
3. heuristica automatica

o, si se mantiene la regla ya aprobada de precedencia local:

1. `config` explicita del usuario
2. metadata de fuente
3. heuristica automatica

La segunda opcion es la mas consistente con lo ya decidido.

## Anti-patrones a evitar

No se recomienda:

- exigir que todas las columnas tengan metadata;
- usar descripciones largas como sustituto de estructura;
- mezclar semantica de variable con logica de transformacion derivada del script;
- o diseñar la ficha pensando primero en edicion manual y no en parseo robusto.

## Decision final

Se aprueba un bloque `columnas`:

- por nombre de variable;
- con `rol` como campo central;
- y con `tipo_esperado`, `faltantes` y `descripcion` como extensiones opcionales.

Ese modelo mantiene la friccion baja, sirve para el helper actual y deja una base muy razonable para una futura interfaz grafica de edicion.
