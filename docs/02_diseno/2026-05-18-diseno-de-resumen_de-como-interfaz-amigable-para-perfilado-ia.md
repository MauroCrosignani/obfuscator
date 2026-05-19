# Diseno de `resumen_de()` como interfaz amigable para perfilado IA

## Proposito

Definir una interfaz publica mucho mas facil de adoptar para el subproyecto de perfilado seguro para IA, sin reemplazar ni desordenar el core tecnico ya implementado.

La intencion es que una persona pueda pasar de algo como:

```r
glimpse(data, width = 0)
```

a una llamada igual de simple, pero mas util para una interaccion con IA:

```r
resumen_de(mi_dataset)
```

## Problema de diseno

Hoy el helper ya es potente, pero su superficie publica sigue estando demasiado orientada a una capa tecnica:

- `profile_dataset_for_ai()`
- `render_dataset_profile_for_ai()`

Eso funciona bien para desarrollo y testing, pero tiene mas friccion de la deseable para:

- personas que usan RStudio de forma practica;
- personas no tecnicas o no angloparlantes;
- y usuarios que quieren una mejora inmediata sobre `glimpse()` sin entender la arquitectura interna.

Si el camino recomendado exige:

- aprender dos funciones en vez de una;
- entender conceptos como `profile` y `render`;
- o recordar nombres en ingles;

entonces la adopcion baja, aunque la implementacion tecnica sea buena.

## Decision principal

Se recomienda exponer una **funcion unica y en espanol** como puerta de entrada recomendada:

```r
resumen_de()
```

La nueva funcion no reemplaza el core tecnico existente. Actua como wrapper amable sobre:

- `profile_dataset_for_ai()`
- `render_dataset_profile_for_ai()`

## Criterios UX/UI

Con lente de `brainstorming` y `ui-ux-pro-max`, la solucion debe cumplir:

### 1. Friccion minima

La llamada mas simple debe ser:

```r
resumen_de(mi_dataset)
```

Y debe devolver directamente un texto listo para copiar o pegar.

### 2. Escalado progresivo

La complejidad solo debe aparecer cuando la persona la necesita:

```r
resumen_de(mi_dataset, modo = "conservador")
resumen_de(mi_dataset, tipo_fuente = "gca2")
resumen_de(mi_dataset, archivo_fuente = "c:/ruta/consulta.xlsx")
resumen_de(mi_dataset, salida = "estructura")
```

### 3. Nombres legibles en espanol

La API visible debe usar parametros entendibles para terceros, incluso si no conocen ingles ni el internals del helper.

### 4. Reversibilidad y confianza

La nueva funcion no debe introducir logica paralela ni efectos secundarios. Debe limitarse a:

- traducir nombres y valores amigables;
- llamar al core actual;
- y devolver la salida en el formato solicitado.

## Formas consideradas

### Opcion 1: mantener solo la API tecnica actual

Ventajas:

- cero trabajo adicional;
- sin wrapper nuevo.

Desventajas:

- adopcion mas baja;
- poca cercania con el gesto mental de `glimpse()`;
- nombres menos amigables para uso compartido.

### Opcion 2: una funcion unica en espanol como wrapper

Ejemplo:

```r
resumen_de(mi_dataset)
```

Ventajas:

- altisima facilidad de uso;
- mas intuitiva como sustituto practico de `glimpse()`;
- deja el core tecnico intacto.

Desventajas:

- requiere cuidar bien la documentacion para no duplicar caminos.

### Opcion 3: wizard o asistente guiado desde el inicio

Ventajas:

- puede bajar friccion para algunos casos complejos.

Desventajas:

- agrega mas superficie de producto;
- aumenta implementacion y mantenimiento;
- es demasiado pronto para esta etapa.

## Recomendacion

Se recomienda la **Opcion 2**:

- `resumen_de()` como interfaz publica amigable;
- funciones tecnicas actuales conservadas como capa avanzada;
- y documentacion actualizada para que el camino feliz sea evidente.

## API propuesta

### Camino feliz

La interfaz recomendada para primer uso debe poder entenderse casi sin leer documentacion:

```r
resumen_de(
  data,
  nombre_dataset = NULL,
  modo = "normal",
  salida = "texto"
)
```

### Opciones avanzadas

Las opciones avanzadas siguen existiendo, pero no deben competir visualmente con el camino feliz:

```r
resumen_de(
  data,
  nombre_dataset = NULL,
  config = NULL,
  tipo_fuente = NULL,
  archivo_fuente = NULL,
  metadata_dir = NULL,
  modo = "normal",
  salida = "texto"
)
```

La idea es que:

- la persona nueva empiece con `resumen_de(mi_dataset)`;
- y recien despues use `config`, `tipo_fuente`, `archivo_fuente` o `metadata_dir` si hace falta.

## Semantica de la API

### Parametros

- `data`
  - dataset a resumir.
- `nombre_dataset`
  - nombre visible opcional del dataset.
  - si queda en `NULL`, debe preservar la semantica actual del core: usar el nombre del objeto cuando sea posible.
- `config`
  - reglas declaradas en espanol ya soportadas por el core.
  - en esta etapa, las claves vigentes son exactamente:
    - `faltantes_esperables`
    - `columnas_sensibles`
    - `columnas_identificatorias`
    - `columnas_texto_libre`
- `tipo_fuente`
  - pista semantica del origen, opcional.
  - valores vigentes:
    - `"gca"`
    - `"gca2"`
    - `"oracle"`
    - `"excel"`
    - `"csv"`
    - `"desconocida"`
  - `odbc` no es un valor valido de API; el comportamiento recomendado es advertir y sugerir `oracle`.
- `archivo_fuente`
  - artefacto de origen, opcional.
  - puede enriquecer o inferir contexto de origen, pero no siempre representa una fuente declarada por el usuario.
- `metadata_dir`
  - carpeta con fichas JSON por fuente, opcional.
- `modo`
  - nivel de prudencia de la salida.
- `salida`
  - formato devuelto por la funcion.

### Valores de `modo`

Valores visibles recomendados:

- `"normal"`
- `"conservador"`

Traduccion interna:

- `"normal"` -> `mode = "compact"`
- `"conservador"` -> `mode = "conservative"`

### Valores de `salida`

- `"texto"`
- `"estructura"`

Comportamiento recomendado:

- `salida = "texto"` debe ser el valor por defecto;
- `salida = "estructura"` debe devolver el objeto crudo de `profile_dataset_for_ai()` sin renderizar, no una estructura simplificada nueva.

## Relacion con el core actual

La nueva funcion no debe duplicar ni reemplazar el core ya construido.

Flujo interno recomendado:

1. validar parametros visibles de `resumen_de()`;
2. traducir `modo` a los valores del renderer actual;
3. traducir `nombre_dataset` al parametro `dataset_name` del core;
4. reenviar `config`, `tipo_fuente`, `archivo_fuente` y `metadata_dir` sin perder comportamiento;
5. llamar a `profile_dataset_for_ai()`;
6. si `salida = "texto"`, llamar a `render_dataset_profile_for_ai()`;
7. si `salida = "estructura"`, devolver el perfil.

Esto debe preservar el contrato actual del core y solo cambiar la ergonomia de entrada.

## Semantica de origen

`resumen_de()` puede aceptar tanto:

- `tipo_fuente` declarado por la persona usuaria;
- como `archivo_fuente`, que a veces permite inferir o enriquecer el contexto.

La documentacion no debe prometer que ambos casos se cuentan igual en la salida. Cuando el origen venga de deteccion por archivo, el resultado debe distinguir entre:

- fuente declarada;
- y fuente inferida desde archivo.

La interfaz amigable no deberia fabricar una narrativa falsa sobre el origen real del dataset.

## Error handling recomendado

La experiencia de uso debe priorizar mensajes:

- en espanol;
- cortos;
- accionables;
- sin mencionar internals innecesarios.

Ejemplos:

- si `modo` no es valido, listar `normal` y `conservador`;
- si `salida` no es valida, listar `texto` y `estructura`;
- si `data` no es un `data.frame` o `tibble`, mantener la validacion clara ya existente.

## Testing recomendado

La incorporacion de `resumen_de()` debe cubrir al menos:

1. salida de texto por defecto;
2. nombre visible provisto con `nombre_dataset`;
3. salida estructurada cuando se solicita;
4. traduccion correcta de `modo = "normal"` y `modo = "conservador"`;
5. forwarding correcto de `config`, `tipo_fuente`, `archivo_fuente` y `metadata_dir`;
6. validacion de `data` invalido;
7. no regresion del core actual;
8. mensajes en espanol para valores invalidos.

## Documentacion recomendada

La adopcion no depende solo del wrapper. Tambien requiere:

- actualizar la guia operativa para que `resumen_de()` sea el camino recomendado;
- conservar `profile_dataset_for_ai()` y `render_dataset_profile_for_ai()` como capa avanzada;
- agregar ejemplos minimos y reales de uso.

## No objetivos de esta etapa

No se recomienda incluir todavia:

- un wizard interactivo;
- parametros duplicados o demasiados alias;
- cambios de nombre en el core tecnico;
- ni deprecaciones prematuras de las funciones actuales.

## Resultado esperado

Al terminar este frente, la adopcion cotidiana deberia poder empezar con una sola linea:

```r
resumen_de(mi_dataset)
```

y crecer, solo si hace falta, hacia los parametros avanzados ya soportados por el sistema.
