# Diseno por etapas para contexto de fuente en `dataset_profile_for_ai`

## Proposito

Definir una estrategia gradual para enriquecer el perfilado seguro para IA con contexto de origen del dataset, sin volver obligatoria ni fragil una integracion demasiado compleja desde el inicio.

El objetivo es mejorar la calidad del perfil cuando el usuario conoce de donde vienen los datos, pero sin exigir:

- pasar el script completo;
- reconstruir manualmente el pipeline;
- ni depender desde el dia 1 de analisis automatico del codigo activo en RStudio.

## Problema de diseno

Si el helper recibe solo un `data.frame`, pierde informacion potencialmente muy valiosa sobre el origen:

- si viene de `GCA.net`
- si viene de `GCA2`
- si viene de una fuente Oracle
- si habia una hoja de `Caratula` o `Informacion de la consulta`
- si habia varias hojas de datos
- o si el usuario cargo solo una parte del resultado

La solucion mas ambiciosa seria inspeccionar el script activo para reconstruir la linea de carga, los parametros `sheet`, las conexiones y las asignaciones intermedias.

Pero hoy eso seria costoso y fragil:

- distintos estilos de codigo;
- uso de pipes;
- helpers propios;
- multiples archivos;
- sesiones interactivas;
- y poca certeza sobre cual es el "script activo" relevante.

## Decision principal

Se recomienda una estrategia **por etapas**, con estos principios:

1. el helper debe seguir siendo util con solo el dataset;
2. el usuario puede aportar contexto declarativo liviano cuando lo conozca;
3. el analisis del script activo queda explicitamente como linea futura, no como requisito inmediato.

## Terminologia aprobada

No se recomienda usar `odbc` como categoria de fuente en esta capa de diseno.

Cuando el usuario habla de "odbc", en este contexto se refiere concretamente a conexiones contra bases Oracle. Por lo tanto, el modelo deberia trabajar con el origen semantico:

- `oracle`

y no con el mecanismo tecnico intermedio.

## Etapa 1: pista declarativa liviana

La primera mejora recomendada es permitir que el usuario indique, de forma opcional, el tipo de fuente.

### Parametro recomendado

```r
tipo_fuente = NULL
```

### Valores iniciales sugeridos

- `gca`
- `gca2`
- `oracle`
- `excel`
- `csv`
- `desconocida`

### Objetivo

Este parametro no deberia reemplazar la deteccion automatica, sino orientar mejor la interpretacion.

Ejemplo:

```r
profile_dataset_for_ai(
  data = mi_dataset,
  dataset_name = "padron",
  tipo_fuente = "gca2"
)
```

### Ventajas

- friccion muy baja;
- facil de explicar;
- util para personas que saben de donde viene el archivo;
- y mucho mas simple que pasar el script entero.

## Etapa 2: archivo origen opcional

Una vez que exista el resolvedor de fuentes, se recomienda permitir un segundo nivel de enriquecimiento con el archivo de origen.

### Parametro recomendado

```r
archivo_fuente = NULL
```

### Objetivo

Si el archivo origen esta disponible, el helper podria:

- inspeccionar todas las hojas del libro;
- detectar `Caratula` o `Informacion de la consulta`;
- verificar si existen varias hojas de datos;
- y advertir si el dataset cargado parece incompleto o parcial.

Ejemplo:

```r
profile_dataset_for_ai(
  data = mi_dataset,
  dataset_name = "padron",
  tipo_fuente = "gca2",
  archivo_fuente = "/ruta/consulta_18631_123456.xlsx"
)
```

### Importante

El helper deberia revisar el libro completo, no solo asumir que la hoja cargada fue la correcta.

Esto es especialmente valioso porque:

- a veces el usuario no recuerda que el libro tiene varias hojas;
- a veces carga solo una hoja de datos;
- y a veces ignora la hoja de metadata que daria contexto muy relevante.

## Etapa 3: inspeccion futura del script activo

Se aprueba como linea futura, pero no como prioridad inmediata.

### Idea

Explorar si mas adelante puede inspeccionarse el script activo para:

- detectar la linea de carga del dataset;
- reconstruir el archivo de origen;
- recuperar `sheet`, `range`, `skip`, `query`, etc.;
- y seguir la cadena de asignaciones hasta el objeto actual.

### Motivos para no priorizarlo ahora

- alta complejidad;
- baja robustez inicial;
- mucho riesgo de falsos positivos;
- y posible friccion cognitiva para usuarios que solo quieren una mejora practica sobre `glimpse()`.

## Parametros recomendados en espanol

Se aprueba mantener los nombres de parametros en espanol cuando esta capa se implemente.

### Forma recomendada

```r
profile_dataset_for_ai(
  data,
  dataset_name = NULL,
  config = NULL,
  tipo_fuente = NULL,
  archivo_fuente = NULL,
  metadata_dir = NULL,
  max_levels = 12,
  top_n = 10,
  round_digits = 2
)
```

## Rol de cada parametro nuevo

### `tipo_fuente`

Pista declarativa liviana.

Sirve para:

- orientar la deteccion;
- reducir ambiguedad;
- y evitar pedirle demasiado al usuario.

### `archivo_fuente`

Pista enriquecida.

Sirve para:

- inspeccionar el artefacto origen;
- detectar metadata embebida;
- y emitir advertencias de integridad o carga parcial.

## Orden de precedencia conceptual recomendado

Para interpretar el origen, el helper deberia razonar asi:

1. `tipo_fuente` declarado por el usuario
2. metadata inferida desde `archivo_fuente`
3. deteccion automatica a partir del dataset

Esto mantiene la consistencia con otras decisiones ya tomadas en el subproyecto:

- lo explicitamente declarado por el usuario tiene prioridad;
- la automatizacion complementa;
- no sustituye ciegamente.

## UX recomendada

### No exigir estos parametros

La herramienta debe seguir funcionando bien sin ellos.

### Usarlos como mejora progresiva

La narrativa de uso deberia ser:

- con solo el dataset, ya aporta valor;
- con `tipo_fuente`, mejora la interpretacion;
- con `archivo_fuente`, mejora todavia mas.

### Evitar sobrecargar al usuario

No conviene pedir:

- el script entero;
- un mapa de joins;
- ni una descripcion manual de todas las transformaciones intermedias.

Eso desalentaria la adopcion.

## Anti-patrones a evitar

No se recomienda:

- usar `odbc` como categoria semantica principal cuando en realidad la fuente es `oracle`
- volver obligatorios `tipo_fuente` o `archivo_fuente`
- inspeccionar el script activo antes de consolidar etapas 1 y 2
- ni pedir al usuario que explique manualmente todo el pipeline

## Decision final

Se aprueba una evolucion por etapas del contexto de fuente para `dataset_profile_for_ai`:

1. `tipo_fuente` como pista declarativa liviana
2. `archivo_fuente` como enriquecimiento opcional
3. inspeccion del script activo como linea futura

Y se aprueba mantener los nombres de parametros en espanol en esta capa de la API.
