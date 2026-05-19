# Diseno de mejoras semanticas para `resumen_de()` y `profile_dataset_for_ai()`

## Resumen

Este documento define una mejora semantica del helper de perfilado seguro para IA a partir de una evaluacion critica de resultados reales, en particular con el dataset `starwars` de `tidyverse`.

Conclusion practica:

- el helper ya aporta valor como alternativa prudente a una muestra de filas;
- pero hoy pierde parte de la semantica estructural que hace util a `glimpse()`;
- y en algunos casos produce salidas literalmente correctas pero conceptualmente pobres o confusas.

La decision recomendada es evolucionar el helper para que:

1. preserve mejor la forma real de las columnas;
2. reduzca ambiguedades de render;
3. trate explicitamente casos como categorizaciones compuestas y `list-columns`;
4. y mantenga la politica de seguridad sin degradar demasiado el valor informativo para una IA.

## Contexto del problema

El comportamiento actual funciona razonablemente bien para:

- numericas simples;
- categoricas cortas;
- fechas o fechas-hora detectables;
- y texto libre evidente.

Sin embargo, al evaluar un caso real como `starwars`, aparecen varios sintomas:

- categorias con comas internas se ven como si fueran niveles distintos o duplicados;
- columnas `character` nominales de alta cardinalidad caen en `unknown`;
- `list-columns` quedan practicamente sin semantica;
- no se distingue `integer` de `double`;
- nombres de entidad quedan mezclados con `texto libre`;
- y la advertencia general por texto libre puede sonar mas fuerte o mas vaga de lo necesario.

Esto no invalida el helper. Lo que muestra es que la primera version priorizo seguridad y generalidad, pero todavia no expresa bien ciertas estructuras comunes en data wrangling real.

## Problema de producto

Si el helper quiere sustituir parcialmente a `glimpse(data, width = 0)` para dar contexto a una IA, no basta con "resumir mas seguro". Tambien tiene que conservar parte de la semantica estructural que `glimpse()` si comunica:

- clase importada;
- discrecion o continuidad de la variable;
- cardinalidad;
- forma compuesta o simple del valor;
- y organizacion no atomica de columnas tipo lista.

La mejora, por lo tanto, no es cosmetica. Es una mejora de poder explicativo.

## Alcance

Este diseno cubre seis frentes:

1. categorias compuestas o con separadores internos;
2. `character` nominales de alta cardinalidad;
3. `list-columns`;
4. discriminacion entre `integer` y `double`;
5. separacion entre nombres de entidad y texto libre abierto;
6. reformulacion de advertencias globales y por variable.

Tambien define una decision transversal:

- el helper debe describir mejor la forma de la columna, no solo su clase semantica principal.

## No alcance

Este documento no cubre todavia:

- implementacion concreta en R;
- integracion con la app Shiny;
- cambios en la API publica de `resumen_de()`;
- ni nuevas reglas de metadata por oficina o grupo.

## Alternativas consideradas

### 1. Mantener la heuristica actual y solo pulir el texto del renderer

Ventajas:

- bajo costo;
- riesgo de regresion menor.

Problemas:

- no resuelve clasificaciones pobres como `homeworld -> unknown`;
- no agrega semantica real a `list-columns`;
- y deja intacta la perdida de informacion estructural.

Se descarta como solucion principal.

### 2. Agregar parches puntuales caso por caso

Ventajas:

- rapida mejora en datasets conocidos;
- cambios localizados.

Problemas:

- termina en una coleccion de excepciones;
- hace mas dificil sostener consistencia conceptual;
- y escala mal frente a nuevos tipos de columnas.

Se descarta como enfoque rector, aunque algunos cambios puntuales podran usarse en la implementacion.

### 3. Introducir una capa semantica mas expresiva y luego ajustar el renderer

Ventajas:

- mejora la calidad del objeto estructurado;
- permite renderizar distinto sin perder trazabilidad;
- y deja una base mas sana para nuevas heuristicas.

Problemas:

- exige tocar tanto inferencia como render;
- y requiere ampliar pruebas.

Esta es la opcion recomendada.

## Decision principal

Se aprueba una evolucion del helper basada en dos ideas:

1. la salida estructurada debe describir no solo "que parece ser una columna", sino tambien "como se presenta estructuralmente";
2. el renderer debe usar esa informacion para producir un texto mas informativo y menos engañoso.

En otras palabras:

- primero mejorar el modelo interno;
- despues mejorar la forma del texto.

## Diseno recomendado

## 1. Categorias compuestas o con separadores internos

### Problema actual

Hoy el helper trata cadenas como:

- `"auburn, grey"`
- `"white, blue"`

igual que categorias simples. Despues las renderiza uniendo valores con `", "`, lo que genera salidas ambiguas o directamente engañosas.

### Decision

Agregar una distincion explicita entre:

- `categorical_simple`
- `categorical_compound`

No necesariamente como nuevo `inferred_type`, sino al menos como propiedad estructural adicional, por ejemplo:

```r
value_shape = "simple" | "compound_delimited"
delimiter_hint = ","
```

### Regla recomendada

Cuando una categorica tenga una proporcion relevante de valores con separadores reconocibles:

- no listar valores crudos completos como si fueran niveles simples;
- informar que se trata de categorias compuestas o multietiqueta codificadas en texto;
- y, si se listan ejemplos, usar un formato que no colapse con la propia puntuacion del valor.

### Render recomendado

En lugar de:

```text
hair_color: categorica; valores observados: auburn, auburn, grey, ...
```

usar algo mas cercano a:

```text
hair_color: categorica compuesta; niveles observados con combinaciones textuales; ejemplos de etiquetas: auburn, grey, white, black, blond; faltantes 5.8%.
```

### Justificacion

Esto conserva valor semantico y evita que el renderer invente niveles por accidente.

## 2. `character` nominales de alta cardinalidad

### Problema actual

Columnas como `homeworld` pueden caer en `unknown` aunque, en la practica, sean nominales de alta cardinalidad y no texto libre.

### Decision

Agregar una via de inferencia para:

- `categorical_high_cardinality`

De nuevo, esto puede modelarse como:

- `inferred_type = "categorical"`
- `cardinality_class = "high"`

en vez de crear demasiados tipos nuevos.

### Regla recomendada

Si una columna:

- no parece fecha;
- no parece identificador;
- no parece texto libre;
- y presenta valores cortos o medianos con repeticion nominal plausible,

debe preferirse:

- `categorical`

antes que:

- `unknown`

### Render recomendado

```text
homeworld: categorica; niveles observados: 49; top niveles: Tatooine, Naboo, Alderaan, Coruscant, Kamino; faltantes 11.5%.
```

### Justificacion

Para la IA, esto es muy superior a `unknown`, y sigue siendo prudente.

## 3. Tratamiento especifico de `list-columns`

### Problema actual

Columnas como `films`, `vehicles` y `starships` quedan como:

- `tipo inferido unknown; importado como list`

Eso es tecnicamente correcto, pero muy poco informativo.

### Decision

Incorporar una familia semantica para columnas no atomicas, por ejemplo:

- `collection`
- o `list_column`

con propiedades de contenido cuando se pueda inferir sin demasiada agresividad:

- `element_type = "character" | "numeric" | "unknown"`
- `collection_cardinality = "variable" | "mostly_empty" | "single_value" | "multi_value"`

### Regla recomendada

Cuando una columna sea `list`, el helper no debe intentar tratarla como `unknown` generico. Debe describirla como estructura no atomica.

### Render recomendado

```text
films: columna lista; contiene colecciones de texto por fila; cardinalidad variable; sin faltantes 0.0%.
vehicles: columna lista; contiene colecciones de texto por fila; muchas filas vacias; sin faltantes 0.0%.
```

### Justificacion

Esto ayuda mucho mas a una IA que necesita entender la forma del dataset.

## 4. Diferenciacion entre `integer` y `double`

### Problema actual

El helper colapsa ambas clases en `numerica`, perdiendo una senal estructural valiosa.

### Decision

Mantener `numeric` como familia general, pero agregar una propiedad explicita como:

```r
numeric_kind = "integer" | "double"
```

### Regla recomendada

El resumen estructurado debe guardar:

- `imported_type` exacto;
- `numeric_kind` cuando corresponda;
- y, en el renderer, mostrarlo cuando agregue valor.

### Render recomendado

```text
height: numerica entera; rango aproximado 66-264; faltantes 6.9%.
mass: numerica decimal; rango aproximado 15-1358; faltantes 32.2%.
```

### Justificacion

Esto preserva mejor parte de la lectura rapida de `glimpse()` y ayuda a detectar problemas de importacion.

## 5. Nombres de entidad vs texto libre abierto

### Problema actual

Columnas como `name` pueden caer en `free_text`, aunque no sean comentario abierto ni observacion narrativa.

### Decision

Distinguir entre:

- `entity_label`
- `free_text`

La diferencia conceptual es:

- `entity_label` = nombre o etiqueta nominal de una entidad;
- `free_text` = contenido abierto, potencialmente narrativo o altamente variable.

### Regla recomendada

Si una columna:

- tiene valores relativamente cortos;
- alta cardinalidad;
- y patron de nombre o etiqueta, sin evidencias de texto narrativo,

deberia clasificarse como `entity_label` o equivalente, no como `free_text`.

### Render recomendado

```text
name: etiqueta nominal de entidad; alta unicidad; no se incluyen ejemplos reales por seguridad; faltantes 0.0%.
```

### Justificacion

Esto evita sobregeneralizar la advertencia de texto libre y mejora la interpretabilidad.

## 6. Advertencias mas precisas

### Problema actual

La advertencia global por texto libre puede sonar demasiado amplia cuando el caso real es solo una columna nominal de nombres.

### Decision

Separar advertencias por familia de riesgo:

- texto libre abierto;
- nombres de entidad;
- categorias sensibles;
- estructuras no atomicas;
- y columnas temporales mal parseadas.

### Regla recomendada

Las advertencias globales deben derivarse de categorias de problema mas precisas. Por ejemplo:

- `Se detectaron columnas de texto libre; no se incluiran ejemplos reales.`
- `Se detectaron nombres de entidad; no se incluiran ejemplos reales por seguridad.`
- `Se detectaron columnas lista; la salida resume su forma, no cada elemento interno.`

### Justificacion

Esto mejora confianza y evita mensajes correctos pero demasiado vagos.

## Decision transversal: preservar mejor la forma de la columna

Ademas de las decisiones anteriores, se recomienda que el objeto estructurado por variable pueda describir:

- `imported_type`
- `inferred_type`
- `value_shape`
- `cardinality_class`
- `numeric_kind`
- `element_type` en `list-columns`
- y un `render_strategy_hint` opcional

No es obligatorio exponer todas estas claves en la API publica, pero si conviene que existan en el perfil interno para no forzar al renderer a redescubrir semantica ya inferida.

## Impacto esperado en el renderer

La salida textual deberia mejorar en tres dimensiones:

1. menos ambiguedad;
2. mejor descripcion estructural;
3. menor tendencia a usar `unknown` cuando el helper si sabe algo util.

## Reglas de prudencia

Estas mejoras no deben romper la politica de seguridad vigente. En particular:

- no listar nombres reales de entidad;
- no exponer texto libre abierto;
- no expandir listas internas fila a fila;
- no tratar categorias compuestas como categorias simples;
- y no reemplazar prudencia por falsa precision.

## Estrategia de implementacion sugerida

Orden recomendado:

1. ampliar el objeto estructurado por variable;
2. ajustar inferencia para `character` de alta cardinalidad;
3. agregar soporte especifico de `list-columns`;
4. incorporar `numeric_kind`;
5. separar `entity_label` de `free_text`;
6. reescribir el renderer para usar estas pistas nuevas;
7. agregar pruebas con `starwars` u otros datasets reales equivalentes.

## Casos de prueba recomendados

### Dataset `starwars`

Debe servir para cubrir:

- nombres de entidad;
- enteros vs dobles;
- categorias compuestas;
- categorizacion nominal de alta cardinalidad;
- y `list-columns`.

### Casos sinteticos adicionales

- categoricas con separador interno pero pocas categorias;
- `list-columns` de enteros;
- `character` de alta cardinalidad que si deberia seguir siendo `free_text`;
- y variables numericas que parecen identificadores mal importados.

## Riesgos y limites

### Riesgo 1

Clasificar demasiado rapido como `categorical` algo que era texto libre corto.

Mitigacion:

- mantener heuristicas prudentes;
- y usar pruebas de contraste.

### Riesgo 2

Introducir demasiadas categorias nuevas y volver inmanejable el modelo.

Mitigacion:

- mantener una familia corta de tipos principales;
- y expresar parte de la complejidad con propiedades adicionales.

### Riesgo 3

Aumentar demasiado la verbosidad del renderer.

Mitigacion:

- priorizar frases cortas;
- y reservar detalle extra para el perfil estructurado, no para el texto por defecto.

## Decision final

Se aprueba avanzar con una mejora semantica del helper que atienda todos los puntos detectados en la evaluacion critica:

1. categorias compuestas;
2. `character` nominales de alta cardinalidad;
3. `list-columns`;
4. `integer` vs `double`;
5. nombres de entidad vs texto libre;
6. advertencias mas precisas.

La conclusion de diseno es que el helper debe seguir siendo seguro, pero acercarse mas a la riqueza estructural que hoy comunica `glimpse()` sin volver a exponer datos crudos.

## Proximo paso recomendado

Convertir este diseno en un plan corto de implementacion por etapas, con foco primero en:

1. categorias compuestas;
2. alta cardinalidad nominal;
3. y discriminacion `integer` / `double`.
