# Diseno de `dataset_profile_for_ai()`

## Proposito

Definir un helper de R pensado para ejecutarse desde RStudio, fuera de la UI de ObfuscatoR, con el fin de generar un perfil seguro y util de un dataset para pegar como contexto en una interaccion con una IA.

La idea no es mostrar filas de ejemplo ni construir un resumen humano generalista. El objetivo es producir un contexto suficientemente informativo para que una IA:

- entienda la estructura del dataset;
- identifique riesgos plausibles de reidentificacion;
- sugiera transformaciones o criterios de uso;
- y razone sobre el significado probable de las columnas sin recibir datos crudos innecesarios.

## Alcance

Este diseno cubre:

- la forma del objeto de perfil;
- las funciones recomendadas;
- reglas de inferencia de tipo;
- reglas de salida por clase de variable;
- y restricciones de seguridad de la informacion.

No cubre todavia:

- implementacion en R;
- integracion con la app Shiny;
- integracion con el flujo de liberacion controlada;
- ni persistencia de perfiles.

## Decision principal

Se recomienda un enfoque de dos capas:

1. una funcion que analice el dataset y construya un objeto estructurado;
2. una funcion separada que renderice ese objeto a texto listo para pegar en una IA.

La alternativa descartada fue una sola funcion que imprima texto directamente.

Motivo del descarte:

- seria menos testeable;
- mezclaria analisis con presentacion;
- y dificultaria agregar versiones compactas, extendidas o reglas de seguridad diferenciadas.

## Funciones propuestas

### 1. `profile_dataset_for_ai()`

Responsabilidad:

- inspeccionar un `data.frame` o `tibble`;
- inferir la semantica probable de las columnas;
- resumir estructura, patrones y advertencias;
- devolver un objeto rico y reusable.

Firma orientativa:

```r
profile_dataset_for_ai(
  data,
  dataset_name = NULL,
  max_levels = 12,
  top_n = 10,
  round_digits = 2
)
```

### 2. `render_dataset_profile_for_ai()`

Responsabilidad:

- tomar el objeto devuelto por `profile_dataset_for_ai()`;
- convertirlo a un bloque textual claro y seguro;
- dejarlo listo para copiar en Copilot, Cursor u otra IA conversacional.

Firma orientativa:

```r
render_dataset_profile_for_ai(
  profile,
  mode = "compact"
)
```

## Forma del objeto de perfil

La salida de `profile_dataset_for_ai()` deberia ser una lista con esta estructura general:

```r
list(
  dataset_name = "personas_2026",
  dimensions = list(rows = 20000, cols = 18),
  generated_at = "2026-05-17 15:20:00",
  variables = list(...),
  warnings = c(...)
)
```

Cada variable deberia devolver algo de este estilo:

```r
list(
  name = "fecha_evento",
  imported_type = "character",
  observed_pattern = "2026-05-17 14:22:31.123456",
  inferred_type = "datetime",
  inference_confidence = "high",
  role_guess = "quasi_identifier",
  missing_pct = 0.02,
  summary = list(...),
  warnings = c(...)
)
```

## Distincion clave: tipo importado vs tipo inferido

El diseno no debe confiar solo en la clase R de una columna.

Una variable puede llegar como `character` y en realidad ser:

- una fecha;
- una fecha-hora;
- un timestamp con fracciones finas;
- o una mezcla de formatos temporales que el parser no pudo resolver automaticamente.

Por eso cada variable debe distinguir al menos:

- `imported_type`: como llego a R;
- `observed_pattern`: patron dominante observado en el contenido;
- `inferred_type`: que parece ser semanticamente;
- `inference_confidence`: confianza de esa inferencia;
- `warnings`: problemas de parseo, mezcla de formatos o ambiguedad.

## Tipos inferidos recomendados

Valores recomendados para `inferred_type`:

- `identifier`
- `categorical`
- `numeric`
- `date`
- `datetime`
- `free_text`
- `unknown`

Valores recomendados para `inference_confidence`:

- `high`
- `medium`
- `low`

## Resumen por clase de variable

### 1. Identificadores

Principio:

- no incluir ejemplos literales por defecto.

Informacion recomendada:

- tipo importado;
- tipo inferido;
- longitud minima y maxima;
- unicidad aproximada;
- patron aproximado;
- regex orientativa solo si es defendible;
- prefijos o sufijos estables cuando no impliquen exponer identificacion sensible.

Ejemplo de salida textual:

```text
persona_id: importado como character; inferido como identificador; unicidad ~100%; patron aproximado: prefijo alfabetico + 3 digitos.
```

### 2. Variables categoricas

Principio:

- si hay pocos niveles, enumerarlos;
- si hay muchos, resumirlos.

Informacion recomendada:

- cantidad de niveles;
- lista completa si los niveles son pocos;
- top `n` si los niveles son muchos;
- porcentaje de faltantes.

Ejemplo:

```text
tramo: categorica; valores observados: A, B, C, D.
```

### 3. Variables numericas

Principio:

- resumir rango y forma gruesa;
- no exponer listas fila a fila.

Informacion recomendada:

- minimo y maximo redondeados;
- mediana opcional;
- cuantiles gruesos opcionales;
- porcentaje de faltantes;
- `role_guess` si parece analitica, cuasi-identificadora o sensible.

Ejemplo:

```text
edad: numerica; rango aproximado 18-89; sin faltantes; posible cuasi-identificador.
```

### 4. Fechas y fechas-hora

Este es un caso prioritario del diseno.

El perfil debe cubrir fechas que:

- llegaron como `Date` o `POSIXct`;
- llegaron como `character`;
- o no pudieron parsearse por formatos con fracciones finas de segundo.

Informacion recomendada:

- `imported_type`;
- `inferred_type`;
- formato observado;
- granularidad;
- rango observado;
- advertencia si el parseo no fue confiable.

Ejemplo:

```text
fecha_evento: importada como character; inferida como fecha-hora; formato observado similar a YYYY-mm-dd HH:MM:SS.ffffff; granularidad de microsegundos; rango aproximado 2024-01 a 2026-03; requiere normalizacion de parseo.
```

### 5. Texto libre

Principio:

- no exponer contenido real por defecto.

Informacion recomendada:

- longitud tipica;
- cardinalidad o variabilidad;
- porcentaje de faltantes;
- senal de texto libre.

Ejemplo:

```text
observacion: texto libre; longitud tipica 40-120 caracteres; alta variabilidad; no se incluyen ejemplos por seguridad.
```

## `role_guess`

El helper no necesita replicar todo el modelo de roles de la UI, pero si conviene una inferencia liviana que oriente a la IA.

Valores sugeridos:

- `identifier`
- `quasi_identifier`
- `sensitive`
- `free_text`
- `analytic`
- `unknown`

Esta inferencia no debe venderse como clasificacion definitiva. Debe verse como ayuda contextual.

## Modo de render para IA

La salida de `render_dataset_profile_for_ai()` deberia ser un bloque compacto, claro y directamente pegable en una conversacion.

Ejemplo orientativo:

```text
Dataset: obfuscator_demo_personas
Dimensiones: 20 filas, 8 columnas

Resumen por variable:
- persona_id: identificador; importado como character; unicidad alta; patron aproximado tipo prefijo + numero.
- fecha_alta: fecha; importada como Date; rango aproximado 2024-01 a 2024-12.
- tramo: categorica; valores observados: A, B, C, D.
- departamento: categorica; valores observados: Montevideo, Canelones, Maldonado, Salto, Paysandu.
- edad: numerica; rango aproximado 23-62; posible cuasi-identificador.
- ingreso: numerica; rango aproximado 18000-56000; posible variable sensible o cuasi-identificadora segun contexto.
- indicador_privado: categorica; valores observados: bajo, medio, alto; potencialmente sensible.
- observacion: texto libre; alta variabilidad; no se incluyen ejemplos.

Advertencias:
- Algunas variables pueden actuar como cuasi-identificadores por combinacion.
- No se incluyen valores crudos de texto libre ni ejemplos literales de identificadores.
```

## Reglas de seguridad

Por defecto, el helper no deberia incluir:

- filas completas de ejemplo;
- identificadores literales;
- texto libre literal;
- timestamps exactos de alta precision si no son necesarios;
- ejemplos crudos de categorias sensibles si su sola enumeracion ya expone demasiado.

Tampoco deberia asumir que "mas detalle" implica "mejor contexto". Para IA, en este caso, el valor esta en describir bien la forma y el riesgo, no en entregar registros.

## Advertencias que conviene emitir

El perfil deberia poder incluir advertencias como:

- `la columna parece temporal, pero llego como character`
- `se detectaron fracciones de segundo que pueden requerir normalizacion`
- `la columna tiene alta unicidad y podria actuar como identificador`
- `la columna parece texto libre y no se incluiran ejemplos`
- `la columna categorica tiene demasiados niveles para listar todos`

## Estrategia de crecimiento recomendada

Cuando se implemente, el orden recomendado es:

1. construir el objeto estructurado base;
2. agregar el renderer compacto para IA;
3. agregar heuristicas de inferencia temporal, identificadores y texto libre;
4. agregar modos de salida mas ricos si hicieran falta.

## Decision final

Se aprueba avanzar, cuando corresponda, con un helper externo de RStudio basado en perfil semantico del dataset y no en muestra de filas.

Esa decision se considera mejor porque:

- expone menos datos innecesarios;
- da mejor contexto estructural a la IA;
- reduce el riesgo de sesgo por una muestra accidental;
- y documenta mejor columnas complejas, en especial fechas importadas como texto.
