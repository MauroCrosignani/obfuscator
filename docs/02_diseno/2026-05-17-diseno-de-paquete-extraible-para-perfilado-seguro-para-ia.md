# Diseno de paquete extraible para perfilado seguro para IA

## Proposito

Definir un subproyecto que pueda vivir en el futuro como paquete R independiente, separado de ObfuscatoR, para generar perfiles seguros de datasets antes de compartir contexto con una IA.

La motivacion principal es esta:

- si solo se extrae un renderer textual sin deteccion semantica y sin guardrails de seguridad, se corre el riesgo de pasar a la IA informacion todavia peligrosa;
- por eso el paquete futuro no deberia contener solo `profile_dataset_for_ai()`, sino el conjunto de capacidades necesarias para inferir, resumir y restringir la informacion de forma coherente.

## Objetivo del subproyecto

Construir una base reusable para:

- detectar tipos importados y tipos inferidos;
- reconocer identificadores, texto libre, variables categoricas, numericas y temporales;
- resumir estructura y patrones sin exponer datos crudos innecesarios;
- producir una salida pegable en interacciones con IA;
- y advertir cuando el contexto sintetizado sigue teniendo senales de riesgo.

## Decision principal

El futuro paquete debe agrupar un **conjunto completo de perfilado seguro**, no una sola funcion aislada.

La alternativa descartada fue extraer un helper minimalista de render.

Motivo del descarte:

- seria facil de compartir, pero facil tambien de usar mal;
- dejaria afuera la logica que evita mandar a la IA ejemplos peligrosos;
- y obligaria a cada consumidor a reinventar heuristicas de riesgo y de tipo semantico.

## Alcance funcional del paquete futuro

El paquete deberia incluir al menos estas familias de funcionalidad.

### 1. Perfilado estructural

Responsabilidad:

- dimensiones del dataset;
- tipos importados;
- perfil por variable;
- advertencias globales.

Funciones candidatas:

- `profile_dataset_for_ai()`
- `build_variable_profile()`

### 2. Inferencia semantica

Responsabilidad:

- detectar si una columna parece identificador;
- detectar si una columna importada como texto parece fecha o fecha-hora;
- detectar si una columna parece texto libre;
- distinguir entre categorica, numerica, temporal y desconocida.

Funciones candidatas:

- `infer_imported_type()`
- `infer_observed_pattern()`
- `infer_semantic_type()`
- `infer_temporal_granularity()`

### 3. Heuristicas de riesgo para compartir con IA

Responsabilidad:

- marcar variables con potencial de cuasi-identificacion;
- marcar variables sensibles;
- marcar texto libre;
- advertir alta unicidad o formatos peligrosamente especificos.

Funciones candidatas:

- `infer_role_guess()`
- `flag_high_uniqueness()`
- `flag_free_text()`
- `flag_sensitive_like_variable()`

### 4. Resumen seguro por clase de variable

Responsabilidad:

- resumir identificadores sin mostrar ejemplos literales;
- resumir categoricas con niveles o top `n`;
- resumir numericas con rangos redondeados;
- resumir fechas con rango, formato y granularidad;
- resumir texto libre sin contenido real.

Funciones candidatas:

- `summarise_identifier_pattern()`
- `summarise_categorical_levels()`
- `summarise_numeric_distribution()`
- `summarise_temporal_range()`
- `summarise_free_text_metadata()`

### 5. Render para IA

Responsabilidad:

- convertir el perfil estructurado en un bloque compacto y seguro;
- dejarlo listo para pegar en Copilot, Cursor u otra IA.

Funciones candidatas:

- `render_dataset_profile_for_ai()`
- `render_dataset_profile_for_ai_extended()`

### 6. Validacion previa al render

Responsabilidad:

- controlar que la salida no incluya filas crudas;
- controlar que no se cuelen identificadores literales;
- controlar que no se pegue texto libre real por accidente.

Funciones candidatas:

- `validate_ai_safe_profile()`
- `assert_no_raw_examples()`

## Lo que el paquete no deberia incluir

Para que quede bien delimitado, el paquete futuro no deberia arrastrar:

- la UI Shiny de ObfuscatoR;
- el flujo de liberacion controlada de la app;
- la semantica completa de estados `Liberable/Bloqueado/Requiere revision`;
- la persistencia de plantillas de clasificacion;
- CSS, capturas o artefactos de presentacion;
- logica de exportacion de la app.

Es decir: debe ser un paquete de **perfilado seguro para IA**, no una extraccion parcial de la app completa.

## Frontera propuesta con ObfuscatoR

La relacion ideal seria:

- ObfuscatoR sigue siendo la aplicacion de liberacion controlada;
- el paquete futuro provee utilidades puras de perfilado semantico y render seguro;
- ObfuscatoR podria consumir ese paquete o copiar su logica en version interna, pero el paquete no debe depender de Shiny ni del estado reactivo de la app.

## Arquitectura sugerida del paquete

Una estructura razonable seria:

```text
R/
  profile_dataset_for_ai.R
  render_dataset_profile_for_ai.R
  infer_semantic_types.R
  summarise_identifiers.R
  summarise_categoricals.R
  summarise_numerics.R
  summarise_temporals.R
  summarise_free_text.R
  validate_safe_output.R
tests/testthat/
  test-profile_dataset_for_ai.R
  test-render_dataset_profile_for_ai.R
  test-infer_semantic_types.R
  test-summarise_temporals.R
  test-validate_safe_output.R
```

La idea es evitar un archivo gigante y mantener unidades pequenas y con una sola responsabilidad.

## Contrato minimo del paquete

El paquete deberia poder garantizar, como minimo:

1. construir un perfil estructurado consistente;
2. distinguir `imported_type` de `inferred_type`;
3. detectar fechas importadas como texto cuando el parser no las resolvio;
4. no incluir por defecto texto libre real;
5. no incluir por defecto identificadores literales;
6. renderizar un resumen directamente util para una IA.

## Casos especialmente importantes

### Fechas importadas como texto

Este caso debe considerarse de primera clase dentro del paquete.

Ejemplo problematico:

- fechas con microsegundos o fracciones finas;
- columnas `character` que semantica y visualmente son temporales;
- mezclas de fecha y fecha-hora.

El paquete debe poder reportar:

- tipo importado;
- tipo inferido;
- patron observado;
- granularidad;
- advertencia de parseo;
- rango aproximado.

### Identificadores con formato institucional

El paquete debe poder describir:

- longitud;
- unicidad;
- patron aproximado;

pero no exponer por defecto:

- ejemplos reales completos;
- valores literales pegables;
- ni reconstrucciones demasiado precisas de patrones sensibles.

### Texto libre

El paquete debe tratar texto libre como un caso de alto cuidado.

Por defecto:

- sin ejemplos;
- sin top de valores;
- sin snippets;
- solo longitud, variabilidad y advertencias.

## Estrategia de extraibilidad

Para que luego compartirlo sea sencillo, conviene preparar desde ahora cuatro cosas:

1. **pureza funcional**
   - helpers sin dependencia de `input`, `output`, `reactiveVal` ni estado de Shiny.

2. **tests propios**
   - una suite que no dependa de lanzar la app.

3. **limites de responsabilidad**
   - evitar mezclar liberacion controlada con perfilado para IA.

4. **documentacion de frontera**
   - dejar claro que queda adentro y que queda afuera del paquete.

## Estrategia de crecimiento

La evolucion recomendada del subproyecto seria:

1. helper interno bien aislado dentro del repo;
2. tests dedicados;
3. small API coherente;
4. documentacion de extraibilidad;
5. extraccion a paquete separado cuando la funcionalidad ya no dependa de decisiones inestables del MVP.

## Decision final

Se aprueba tratar este frente como subproyecto prioritario de **perfilado seguro para IA extraible como paquete independiente**.

Ese paquete futuro debera incluir no solo el renderer final, sino tambien las heuristicas y guardrails necesarios para evitar que el usuario termine entregando a la IA datos todavia peligrosos bajo una falsa apariencia de seguridad.
