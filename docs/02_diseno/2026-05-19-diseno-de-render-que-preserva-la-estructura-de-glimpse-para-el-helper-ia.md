# Diseño de render que preserva la estructura de `glimpse()` para el helper IA

## Resumen

Este documento define el siguiente ajuste de diseño recomendado para [resumen_de()](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R) y [profile_dataset_for_ai()](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R):

- conservar explícitamente en la salida visible la clase importada real de cada variable;
- mantener la interpretación semántica lograda en las mejoras recientes;
- y combinar ambas capas en una redacción corta, útil y prudente.

Conclusión práctica:

- el helper ya mejoró mucho como resumen semántico;
- pero todavía no preserva suficientemente lo que `glimpse()` aporta como referencia estructural rápida;
- por lo tanto, la siguiente evolución del renderer debe mostrar siempre:
  1. cómo llegó la variable a R;
  2. cómo la interpretamos semánticamente;
  3. y cuál es el resumen seguro que conviene pasar a la IA.

## Contexto

La salida actual es más rica que la primera versión en:

- categorías compuestas;
- alta cardinalidad nominal;
- `list-columns`;
- diferenciación entre `integer` y `double`;
- y separación entre `entity_label` y `free_text`.

Sin embargo, la mayor parte de esa mejora quedó del lado de la interpretación semántica y no de la forma original de la variable.

Esto genera un desbalance:

- la IA entiende mejor qué parece ser la variable;
- pero ve menos claramente cómo está representada en R.

Si el helper aspira a sustituir parcialmente a `glimpse(data, width = 0)` como contexto para IA, no alcanza con “interpretar mejor”. También tiene que conservar la evidencia estructural que `glimpse()` comunica de un vistazo.

## Problema de producto

Hoy una línea como:

```text
sex: categorica; valores observados: female, hermaphroditic, male, none; faltantes 4.6%.
```

es semánticamente útil, pero omite algo importante:

- si `sex` llegó como `character`;
- si fue importada como `factor`;
- o si se normalizó después de la carga.

Para una IA, esa omisión puede afectar:

- razonamiento sobre transformaciones futuras;
- lectura de pipelines;
- inferencia sobre calidad de importación;
- y adecuación de sugerencias de código en R.

## Decisión principal

Se recomienda que el renderer pase a un modelo de **doble capa explícita** por variable:

1. **tipo importado exacto**
2. **interpretación semántica**

La política recomendada es:

- nunca ocultar `imported_type` en la salida visible de variables “bien clasificadas”;
- usar la semántica inferida como complemento, no como reemplazo de la estructura importada.

## Principio rector

La pregunta que debe poder responder cada línea es:

> “¿Cómo vino esta variable a R y cómo conviene entenderla para trabajar con una IA?”

No solo:

> “¿Qué parece ser esta variable?”

## Estructura recomendada de salida

Cada variable debería renderizarse siguiendo este orden:

1. nombre de variable
2. tipo importado exacto
3. interpretación semántica
4. resumen estructural o estadístico seguro
5. faltantes

### Plantilla general

```text
- <variable>: importada como <tipo_importado>; interpretada como <lectura_semantica>; <detalle_resumen>; faltantes <x>%.
```

No hace falta usar siempre la palabra `interpretada`, pero sí respetar ese orden conceptual.

## Ejemplos recomendados

### 1. Numéricas

En vez de:

```text
- height: numerica entera; rango aproximado 66-264; faltantes 6.9%.
```

usar algo como:

```text
- height: importada como integer; interpretada como numerica entera; rango aproximado 66-264; faltantes 6.9%.
```

Y:

```text
- mass: importada como double; interpretada como numerica decimal; rango aproximado 15-1358; faltantes 32.2%.
```

### 2. Categóricas simples

```text
- sex: importada como character; interpretada como categorica; valores observados: female, hermaphroditic, male, none; faltantes 4.6%.
```

Si viniera como `factor`:

```text
- sex: importada como factor; interpretada como categorica; valores observados: female, hermaphroditic, male, none; faltantes 4.6%.
```

### 3. Categóricas de alta cardinalidad

```text
- homeworld: importada como character; interpretada como categorica; niveles observados: 48; top niveles: Naboo, Tatooine, Alderaan, Coruscant, Kamino; faltantes 11.5%.
```

### 4. Categóricas compuestas

```text
- hair_color: importada como character; interpretada como categorica compuesta; etiquetas observadas: auburn, black, blond, blonde, brown, grey, none, white; faltantes 5.8%.
```

### 5. Etiquetas de entidad

```text
- name: importada como character; interpretada como etiqueta nominal de entidad; alta unicidad; longitud tipica 3-21 caracteres; no se incluyen ejemplos reales por seguridad; faltantes 0.0%.
```

### 6. Texto libre

```text
- observacion: importada como character; interpretada como texto libre; longitud tipica 40-120 caracteres; alta variabilidad; no se incluyen ejemplos reales por seguridad; faltantes 3.2%.
```

### 7. `list-columns`

```text
- films: importada como list; interpretada como columna lista; contiene colecciones de texto por fila; cardinalidad variable; faltantes 0.0%.
```

### 8. Temporales

Para temporales ya se expone parcialmente el tipo importado. Se recomienda mantenerlo y solo homogeneizar el estilo:

```text
- fecha_evento: importada como POSIXct; interpretada como fecha-hora; formato observado YYYY-mm-dd HH:MM:SS.ffffff; granularidad microsegundos; rango aproximado ...; faltantes 0.0%.
```

Y si llegó como texto:

```text
- fecha_evento: importada como character; interpretada como fecha-hora; formato observado YYYY-mm-dd HH:MM:SS.ffffff; requiere normalizacion de parseo; faltantes 0.0%.
```

## Decisión sobre vocabulario

Se recomienda mantener dos etiquetas distintas:

- `importada como ...`
- `interpretada como ...`

Porque:

- son comprensibles para usuarios no técnicos;
- dejan muy clara la diferencia entre evidencia y heurística;
- y ayudan a que la IA no confunda clase base con lectura semántica.

## Alternativas consideradas

### 1. Mantener la salida actual y confiar en `salida = "estructura"`

Ventajas:

- no alarga el texto;
- evita tocar el renderer de nuevo.

Problemas:

- obliga a quien usa `resumen_de()` a inspeccionar el objeto estructurado para recuperar algo que `glimpse()` daba a simple vista;
- contradice el objetivo de una interfaz simple.

Se descarta.

### 2. Agregar solo un prefijo técnico corto estilo `<chr>`, `<int>`, `<dbl>`

Ejemplos:

```text
- sex <chr>: categorica; ...
- height <int>: numerica entera; ...
```

Ventajas:

- muy compacto;
- muy cercano a `glimpse()`.

Problemas:

- menos legible para usuarios no técnicos;
- exige conocer abreviaturas de clase de R;
- puede ser demasiado críptico en un flujo orientado a IA y a usuarios heterogéneos.

Se considera una opción válida para un futuro `modo_tecnico`, pero no como default recomendado.

### 3. Mostrar explícitamente `importada como ...`

Ventajas:

- más claro para audiencia amplia;
- sigue siendo corto;
- conserva la estructura real;
- y no requiere conocimiento previo de abreviaturas.

Esta es la opción recomendada para el modo visible por defecto.

## Recomendación complementaria: futuro `modo_tecnico`

No es prioridad inmediata, pero queda recomendado evaluar más adelante un modo opcional tipo:

- `modo = "tecnico"`

que use una sintaxis más compacta, por ejemplo:

```text
- sex <character>: categorica; ...
- height <integer>: numerica entera; ...
- films <list>: columna lista; ...
```

Esto permitiría:

- mantener un modo más didáctico por defecto;
- y ofrecer otro más cercano a `glimpse()` para usuarios avanzados.

## Impacto esperado

Con este ajuste, el helper ganaría en tres dimensiones a la vez:

1. **mejor contexto para IA**
   - más información sobre la forma real del objeto;
2. **mejor continuidad con flujos R**
   - menor pérdida respecto de `glimpse()`;
3. **mejor trazabilidad**
   - más claridad sobre qué es observación y qué es inferencia.

## Qué no resuelve este diseño

Este ajuste no resuelve por sí solo:

- la taxonomía definitiva de categorías compuestas;
- todos los edge cases de `entity_label`;
- ni la inferencia de transformaciones aplicadas después de la carga.

Eso pertenece a mejoras posteriores.

## Siguiente paso recomendado

Implementar primero este cambio de renderer antes de agregar más semántica nueva.

Orden sugerido:

1. mostrar `imported_type` en todas las familias principales;
2. homogenizar la redacción por variable con la estructura `importada como ...; interpretada como ...`;
3. recién después refinar la taxonomía de compuestas y otros matices semánticos.
