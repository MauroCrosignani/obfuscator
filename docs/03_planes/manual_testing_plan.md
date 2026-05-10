# Plan de Pruebas Manuales del MVP Release-Safe

## Resumen

Este documento define un plan de pruebas manuales para verificar el estado real del MVP de ObfuscatoR Studio a fecha 2026-05-09.

Audiencia:
- equipo funcional del proyecto;
- responsables tecnicos que necesiten ver la herramienta en funcionamiento;
- autor del producto antes de presentar el MVP a terceros.

Conclusion practica:
- el producto ya permite probar un flujo defendible de carga, clasificacion, ofuscacion, `k-anonymity`, bloqueo de exportacion externa y resumen de auditoria;
- la UI ya ofrece una clasificacion principal por variable, una ficha lateral de detalle y una guia breve de trabajo release-safe;
- todavia no implementa modelos avanzados como `l-diversity` o `t-closeness`;
- y la interfaz aun no implementa una revision manual completa por alertas ni una experiencia final madura de liberacion formal.

Este plan debe leerse como una guia para validar lo que el MVP realmente hace hoy, no como una promesa de capacidades futuras.

## Objetivo

Verificar por observacion directa:

1. que la app carga datasets de prueba y cambia de estado correctamente;
2. que la ofuscacion y `k-anonymity` producen efectos visibles y coherentes;
3. que la liberacion externa queda bloqueada cuando corresponde;
4. que el resumen de auditoria explica el resultado de forma entendible;
5. que los nuevos datasets demo permiten ensayar casos que `iris` no cubre bien;
6. y que las limitaciones actuales queden identificadas sin ambiguedad.

## Estado actual del proyecto que este plan asume

### Lo que ya esta implementado

- carga de datasets desde archivo o entorno global;
- clasificacion visual de variables por rol;
- persistencia de plantillas de clasificacion;
- un unico panel principal de parametros;
- configuracion de `k-anonymity` con:
  - activacion explicita;
  - valor de `k`;
  - supresion residual por:
    - eliminar filas;
    - agrupar remanentes;
    - conservar sin anonimizar;
- estado de liberacion:
  - `No evaluado`;
  - `En revision`;
  - `Bloqueado`;
  - `Liberable`;
  - `No liberable sin rediseno`;
- bloqueo de exportacion externa cuando el estado no es `Liberable`;
- resumen de auditoria legible;
- heuristicas internas de riesgo residual y reenlazabilidad;
- generacion de codigo R con advertencia de que generar codigo no equivale a aprobar liberacion externa;
- clasificacion principal por variable con:
  - cambio rapido de rol;
  - ficha lateral de detalle;
  - ayuda contextual minima;
  - guia breve de trabajo release-safe;
- datasets demo precargados en el entorno global al iniciar la app:
  - `iris`
  - `mtcars`
  - `airquality`
  - `obfuscator_demo_personas`

### Lo que no esta implementado hoy

- `l-diversity`;
- `t-closeness`;
- una interfaz completa de revision manual por alerta;
- configuracion avanzada persistente por variable dentro de la ficha lateral;
- una pantalla de liberacion formal que conduzca al usuario paso a paso por cada bloqueo.

## Preparacion de la prueba

### Arranque recomendado

Usar este comando en R para asegurar carga limpia del entorno:

```r
library(datasets)
data(iris)
source("R/obfuscator_core.R")
source("R/shiny_app.R")
run_obfuscator_app()
```

### Datasets recomendados para la prueba

#### 1. `iris`

Utilidad:
- caso simple;
- permite ver rapido clasificacion automatica, preview y `k-anonymity`.

Limitacion:
- no tiene identificadores reales;
- no tiene texto libre;
- no representa bien un caso institucional real.

#### 2. `mtcars`

Utilidad:
- varias numericas;
- una categorica util para experimentar;
- sirve para ver como responde la clasificacion en un dataset no personal.

Limitacion:
- tampoco representa un caso de liberacion de datos personales.

#### 3. `airquality`

Utilidad:
- mezcla numericas con faltantes;
- permite observar como responde el sistema ante `NA`.

Limitacion:
- no tiene identificadores ni texto libre.

#### 4. `obfuscator_demo_personas`

Utilidad:
- dataset sintetico de demostracion para el MVP;
- incluye una mezcla mas cercana al problema real.

Columnas esperadas:
- `persona_id`
- `fecha_alta`
- `tramo`
- `departamento`
- `edad`
- `ingreso`
- `indicador_privado`
- `observacion`

Este es el dataset mas importante para la demo funcional porque permite ensayar:
- identificadores;
- fecha;
- categoricas;
- numericas;
- un indicador sensible;
- y texto libre corto.

## Casos de prueba recomendados

### Caso 1. Arranque y visibilidad de datasets demo

Objetivo:
- confirmar que la app levanta y que los datasets demo quedaron realmente disponibles en el entorno.

Pasos:
1. abrir la app;
2. elegir `Fuente de datos -> Entorno global`;
3. abrir el selector de objeto;
4. verificar que aparecen:
   - `iris`
   - `mtcars`
   - `airquality`
   - `obfuscator_demo_personas`

Resultado esperado:
- todos los datasets anteriores aparecen sin tener que crearlos manualmente;
- no hay error al elegirlos.

Registrar si falla:
- nombre del dataset faltante;
- mensaje visible;
- error de consola, si existe.

### Caso 2. Chip de dataset y estado basico con `iris`

Objetivo:
- comprobar que la app refleja mejor el dataset cargado y no queda en `Dataset: Ninguno`.

Pasos:
1. cargar `iris`;
2. observar el encabezado superior;
3. observar el bloque `Estado del dataset`.

Resultado esperado:
- el nombre del dataset ya no debe quedar fijo en `Ninguno`;
- deben verse filas y columnas coherentes;
- la clasificacion visual debe poblarse.

Registrar:
- nombre mostrado;
- cantidad de filas;
- cantidad de columnas;
- si hubo que recargar para que el estado se refrescara.

### Caso 3. Panel unico de parametros

Objetivo:
- verificar que ya no hay dos bloques distintos de `Parametros`.

Pasos:
1. con cualquier dataset cargado, recorrer el panel lateral;
2. identificar la seccion `Parametros`.

Resultado esperado:
- debe existir un unico bloque principal de `Parametros`;
- no deben repetirse:
  - `k-anonymity`;
  - `Prefijo para IDs`;
  - `Llave del proyecto`;
  - `Modo numerico`.

Registrar:
- si aparece duplicacion;
- si algun control queda tapado o mal alineado.

### Caso 4. Reproduccion del warning reportado con `iris`

Objetivo:
- confirmar que no reaparece el warning en consola al usar `k = 13` y `Agrupar remanentes`.

Pasos:
1. cargar `iris`;
2. activar `k-anonymity`;
3. poner `k = 13`;
4. seleccionar `Agrupar remanentes`;
5. ejecutar la ofuscacion.

Resultado esperado:
- no debe aparecer el warning:
  - `numero de items para sustituir no es un multiplo de la longitud del reemplazo`
- la ofuscacion debe terminar;
- el resumen de auditoria debe reflejar el estado resultante.

Nota:
- este caso sirve tambien para verificar el bugfix de mapeo de IDs con repetidos.

### Caso 5. Bloqueo por no activar `k-anonymity`

Objetivo:
- comprobar que la liberacion externa no se considera aprobada si no se activa `k-anonymity`.

Pasos:
1. cargar `iris` o `mtcars`;
2. no activar `k-anonymity`;
3. ejecutar la ofuscacion;
4. revisar el resumen de auditoria;
5. intentar `Descargar CSV`.

Resultado esperado:
- la app debe tratar la salida como bloqueada para liberacion externa;
- el resumen debe explicar que la liberacion externa requiere `k-anonymity`;
- la descarga externa no debe comportarse como una aprobacion automatica.

Registrar:
- mensaje exacto visto;
- si el boton quedo habilitado o no;
- si el bloqueo fue claro o confuso.

### Caso 6. `k-anonymity` con supresion por filas

Objetivo:
- observar un caso donde el sistema deba suprimir filas o bloquear.

Pasos:
1. cargar `obfuscator_demo_personas`;
2. clasificar `persona_id`, `fecha_alta`, `departamento` y `tramo` como roles relevantes;
3. activar `k-anonymity`;
4. probar con `k` alto, por ejemplo `k = 5` o superior;
5. elegir `Eliminar filas`;
6. ejecutar.

Resultado esperado:
- la salida debe mostrar reduccion de filas o bloqueo;
- el resumen debe mencionar supresion residual, si la hubo;
- el estado de liberacion no debe ser `Liberable` si persiste riesgo.

### Caso 7. `k-anonymity` con `Agrupar remanentes`

Objetivo:
- verificar que las clases chicas se agrupen visualmente como remanentes.

Pasos:
1. repetir el caso anterior;
2. elegir `Agrupar remanentes`;
3. ejecutar.

Resultado esperado:
- deben aparecer valores `REMANENTE` en cuasi-identificadores afectados, si la configuracion lo requiere;
- el resumen debe explicar que hubo agrupacion residual;
- la salida debe ser visualmente distinta del modo `Eliminar filas`.

### Caso 8. Texto libre y senales de riesgo con `obfuscator_demo_personas`

Objetivo:
- comprobar si el MVP al menos detecta indirectamente un caso con texto libre y variable privada.

Pasos:
1. cargar `obfuscator_demo_personas`;
2. localizar `observacion` e `indicador_privado`;
3. ejecutar una ofuscacion con `k-anonymity` activo;
4. revisar el resumen de auditoria.

Resultado esperado hoy:
- puede haber bloqueo o alertas indirectas en el resumen;
- pero no se espera todavia una UX avanzada y explicita por cada tipo de alerta.

Interpretacion correcta:
- si la deteccion es poco visible, eso confirma una brecha real del MVP;
- no debe maquillarse como funcionalidad ya resuelta.

### Caso 9. Resumen de auditoria

Objetivo:
- verificar que el panel de auditoria traduzca el resultado tecnico a una conclusion entendible.

Pasos:
1. ejecutar al menos un caso bloqueado;
2. ejecutar al menos un caso mas permisivo;
3. leer el bloque `Resumen de auditoria`.

Resultado esperado:
- el resumen no debe ser solo un log crudo;
- debe explicar por que el dataset queda bloqueado o liberable;
- debe sugerir pasos siguientes cuando no se puede liberar.

Registrar:
- si la redaccion es clara para un tecnico que no conoce el codigo;
- si parece un log interno o una conclusion defendible.

### Caso 10. Generacion de codigo R

Objetivo:
- confirmar que el codigo generado no se interprete como autorizacion de liberacion externa.

Pasos:
1. configurar una corrida cualquiera;
2. abrir `Ver Codigo R`;
3. leer el texto generado.

Resultado esperado:
- el codigo debe reflejar mejor la configuracion actual;
- debe quedar claro que generar codigo no equivale a aprobar la liberacion externa.

### Caso 11. Guardado y carga de plantilla

Objetivo:
- verificar continuidad de la clasificacion de variables.

Pasos:
1. cargar `obfuscator_demo_personas`;
2. asignar roles manualmente;
3. guardar plantilla;
4. recargar la app o cambiar de dataset;
5. volver a cargar la plantilla.

Resultado esperado:
- la clasificacion reutilizable debe restaurarse;
- no deberian persistirse artefactos restringidos como si fueran una plantilla general.

## Matriz de evaluacion sugerida

Para cada caso, registrar:

- `Paso probado`
- `Dataset`
- `Resultado esperado`
- `Resultado observado`
- `Estado`
  - `OK`
  - `Parcial`
  - `Falla`
- `Notas`
- `Captura o evidencia`

## Como interpretar el estado actual del MVP

### Senales de que el MVP ya es util

- bloquea exportaciones cuando el estado no es liberable;
- obliga a pensar en `k-anonymity`;
- deja evidencia en el resumen de auditoria;
- permite experimentar con datasets mas representativos que `iris`;
- y ya incorpora una nocion operativa de riesgo residual y reenlazabilidad.

### Senales de que todavia falta madurez

- la UI aun no guia bien la distincion entre:
  - identificadores directos;
  - cuasi-identificadores;
  - variables sensibles;
  - informacion privada;
- no existe aun una implementacion formal de `l-diversity` ni `t-closeness`;
- el flujo de revision manual todavia esta mas maduro en helpers y logica interna que en experiencia visual completa.

## Recomendacion de prueba para demo interna

Si solo hubiera tiempo para una demo corta, conviene hacer esta secuencia:

1. mostrar `iris` para explicar el flujo basico;
2. mostrar `obfuscator_demo_personas` para explicar por que `iris` no alcanza;
3. correr un caso bloqueado sin `k-anonymity`;
4. correr un caso con `k-anonymity`;
5. mostrar el resumen de auditoria;
6. remarcar honestamente que hoy el MVP implementa un piso defendible, no una solucion avanzada completa de anonimizacion formal.

## Trigger de actualizacion

Actualizar este plan cuando ocurra alguno de estos cambios:

- se agreguen datasets demo nuevos;
- la UI incorpore alertas explicitas para cuasi-identificadores o variables sensibles;
- se implemente `l-diversity`, `t-closeness` u otra proteccion adicional;
- cambie el comportamiento del resumen de auditoria o del gating de exportacion.
