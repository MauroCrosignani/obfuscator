# Diseno de alertas por desajustes entre origen y estado actual para perfilado IA

## Proposito

Definir una linea de diseno para el subproyecto `dataset_profile_for_ai` en la que el helper pueda, en el futuro, advertir diferencias significativas entre:

- lo esperable segun la fuente o metadata de origen;
- y el estado actual del objeto ya transformado en R.

La meta es enriquecer el contexto entregado a una IA sin exigir reconstruir todo el pipeline de transformaciones.

## Problema de diseno

En el uso real, el objeto sobre el que se consulta a la IA no siempre coincide con el contenido crudo importado.

Es frecuente que, despues de la carga:

- se reparen fechas importadas como texto;
- se normalicen identificadores;
- se recodifiquen variables;
- o se transformen tipos para volverlos mas consistentes con las reglas del negocio.

Por eso, limitarse a describir:

- solo el origen esperado;
- o solo el estado actual observado;

puede ser insuficiente.

### Riesgo 1

Si se describe solo el origen esperado, la IA puede asumir que ciertas normalizaciones ya existen cuando en realidad no se aplicaron.

### Riesgo 2

Si se describe solo el estado actual, la IA puede no detectar que una variable importante quedo en un formato problematico o inesperado.

## Decision principal

No se recomienda modelar, en esta etapa, un historial completo de transformaciones ni intentar reconstruir todo el pipeline.

Si se recomienda dejar abierta una capa futura de:

- **alertas o desajustes entre origen esperado y estado actual**

Estas alertas deberian resumir solo las diferencias relevantes, no la historia completa de como se llego a ellas.

## Que no necesita la IA

No parece necesario, en principio, pasarle a la IA:

- cada mutacion realizada sobre el objeto;
- cada linea del script;
- cada helper intermedio;
- ni una narrativa completa del pipeline.

Eso agregaria mucha friccion y gastaria contexto sin garantizar mejor interpretacion.

## Que si puede ser util para la IA

Si parece valioso informarle a la IA cuando existan diferencias significativas como:

- una variable que se esperaba como fecha sigue siendo texto;
- un identificador que se esperaba normalizado sigue como numerico;
- una columna con faltantes altos inesperados no fue reparada;
- una variable temporal mantiene granularidad mas fina de la esperable;
- una categorica esperada con pocos niveles quedo con cardinalidad anomala.

## Modelo conceptual recomendado

La informacion futura deberia poder distinguir al menos tres capas:

1. **origen esperado**
2. **estado actual observado**
3. **alertas de consistencia o desajuste**

No hace falta todavia una cuarta capa de historial detallado.

## Ejemplos de alertas utiles

### Tipo no alineado con lo esperado

```text
numero_empresa: se esperaba identificador normalizado como character; estado actual numeric.
```

### Fecha no reparada

```text
fecha_evento: se esperaba datetime; estado actual character con patron de fecha-hora.
```

### Faltantes altos pero esperables

```text
fecha_hasta: faltantes altos detectados; consistentes con metadata declarada como esperables.
```

### Cardinalidad inusual

```text
codigo_pais: se esperaba categorica de baja cardinalidad; estado actual con cardinalidad inusualmente alta.
```

## Relacion con `tipo_fuente`, `archivo_fuente` y metadata externa

Estas alertas no deberian existir en el vacio.

Su valor depende de combinar, en el futuro:

- `tipo_fuente` declarado o inferido;
- metadata de origen por fuente;
- y perfil actual del objeto.

Pero eso no obliga a reconstruir el pipeline.

## UX recomendada

### Regla principal

Mostrar solo alertas que aporten una señal clara de posible problema o de consistencia importante.

### No sobrecargar

No conviene listar cada diferencia menor.

### Priorizar desajustes relevantes

La salida deberia enfocarse en:

- diferencias de tipo;
- problemas de parseo temporal;
- identificadores no normalizados;
- faltantes inesperados;
- y cardinalidad anomala cuando choque con lo esperable.

## Anti-patrones a evitar

No se recomienda:

- intentar reconstruir todo el pipeline antes de consolidar el helper base;
- pasarle a la IA el script entero;
- o asumir que la historia completa de transformaciones siempre mejora la interpretacion.

## Decision final

Se aprueba que la evolucion futura del helper priorice:

- alertas sobre diferencias relevantes entre origen esperado y estado actual;

y no:

- un historial completo de transformaciones.

Esto mantiene baja la friccion, protege la ventana de contexto y conserva valor practico para identificar problemas reales de preparacion de datos.
