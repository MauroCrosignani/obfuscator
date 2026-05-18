# Diseno de normalizacion de nombres y renombres para perfilado IA

## Proposito

Definir como deberia tratar el subproyecto `dataset_profile_for_ai` la estandarizacion de nombres de variables y los posibles renombres aplicados despues de la carga.

El objetivo es mejorar la robustez del matching entre:

- columnas esperadas segun la fuente;
- metadata declarada por tabla o consulta;
- y columnas efectivamente presentes en el objeto actual en R.

## Problema de diseno

En el uso real pueden coexistir varios escenarios:

- `GCA.net` exporta columnas en mayusculas;
- `GCA2` suele exportarlas en minusculas;
- algunos scripts aplican `janitor::clean_names()`;
- otros hacen renombres manuales por legibilidad o por reglas del negocio;
- y esos renombres pueden hacer que el `data.frame` final ya no tenga exactamente los nombres esperados segun la fuente original.

Si esto no se trata con cuidado, el sistema puede:

- dejar de encontrar columnas esperadas;
- asumir falsamente que una columna falta;
- o perder la capacidad de aplicar metadata por fuente de forma consistente.

## Decision principal

No conviene asumir desde ahora una politica obligatoria de aplicar `janitor::clean_names()` en todos los scripts.

Si conviene, en cambio, diseñar el helper para trabajar con tres niveles de nombre:

1. **nombre de origen**
2. **nombre normalizado**
3. **nombre actual observado**

Y priorizar el matching por nombre normalizado cuando no haya coincidencia exacta.

## Politica recomendada sobre `clean_names()`

### No imponerla como requisito

No se recomienda que el helper exija que todos los usuarios hayan aplicado `janitor::clean_names()`.

Eso seria demasiado fuerte para esta etapa y podria romper adopcion.

### Si tomarla como convenciÃ³n de referencia

Si se recomienda usar una normalizacion equivalente a `clean_names()` como capa interna de comparacion.

Es decir:

- aunque el usuario no la haya aplicado al objeto;
- el helper puede derivar una forma normalizada auxiliar de los nombres para comparar mejor origen y estado actual.

## Tres capas de nombres recomendadas

### 1. `nombre_origen`

El nombre tal como aparece en la fuente o en la metadata declarada.

Ejemplos:

- `CODIGO_CAJA`
- `FECHA_ULT_ACT`

### 2. `nombre_normalizado`

Version normalizada solo para matching interno.

Ejemplos:

- `codigo_caja`
- `fecha_ult_act`

### 3. `nombre_actual`

Nombre realmente presente hoy en el objeto en R.

Ejemplos:

- `codigo_caja`
- `fecha_ult_act`
- `fecha_ultima_actualizacion`
- `nro_empresa_normalizado`

## Regla recomendada de matching

El helper futuro deberia intentar resolver nombres en este orden:

1. coincidencia exacta con `nombre_actual`
2. coincidencia por `nombre_normalizado`
3. coincidencia por alias declarados si alguna capa futura los aporta
4. si sigue habiendo ambiguedad, no asumir match automatico fuerte

## Valor de esta estrategia

Esto ayuda especialmente en casos como:

- metadata de fuente en mayusculas desde `GCA.net`
- objeto actual con nombres en snake_case por `clean_names()`
- diferencias entre `GCA.net` y `GCA2` para la misma consulta funcional

## Renombres manuales como transformacion especial

Los renombres no son una transformacion cualquiera.

Tienen un impacto especial porque:

- afectan la correspondencia entre origen y objeto actual;
- pueden romper el matching contra metadata;
- y pueden ocultar que una variable si existe, pero con otro nombre.

### Decision de diseno

No se recomienda intentar reconstruir automaticamente todos los renombres desde el script en esta etapa.

Si se recomienda tratarlos conceptualmente como un caso especial de desajuste entre:

- columna esperada en origen
- y columna actual en el objeto

## Alertas utiles futuras

Cuando exista suficiente contexto de origen, podria ser util advertir casos como:

- `FECHA_ULT_ACT` esperada en la fuente, pero no encontrada literalmente; posible correspondencia con `fecha_ult_act`.
- `NRO_EMPRESA` esperada en la fuente, pero el objeto actual contiene `numero_empresa_normalizado`; revisar si hubo renombre o derivacion.

Estas alertas serian mas utiles que intentar narrar todo el pipeline.

## Relacion con metadata por fuente

La metadata por fuente deberia poder guardar el nombre de origen como clave principal dentro de `columnas`.

Pero el helper, al compararla contra el objeto actual, deberia:

- normalizar ambas partes;
- e intentar detectar equivalencias razonables antes de declarar una columna faltante.

Esto es importante porque:

- en `GCA.net` la metadata probablemente conserve mayusculas;
- en el objeto actual puede haberse aplicado `clean_names()`;
- y ambos pueden referirse a la misma variable.

## Recomendacion de futuro para metadata

Si mas adelante hiciera falta mayor precision, la ficha por fuente podria crecer con un campo opcional como:

```json
"aliases": ["fecha_ult_act"]
```

o incluso con una capa especifica de equivalencias por columna.

Pero no conviene exigirlo en la primera version.

## Politica recomendada para esta etapa del proyecto

1. no imponer `janitor::clean_names()` como obligacion
2. si usar una normalizacion equivalente como herramienta interna de comparacion
3. tratar los renombres como transformacion especial y potencial fuente de desajuste
4. no declarar automaticamente columnas faltantes sin antes intentar matching normalizado

## Anti-patrones a evitar

No se recomienda:

- asumir que mayusculas y minusculas ya representan columnas distintas
- exigir que todos los scripts usen `clean_names()`
- o inferir renombres complejos solo por parecido de nombres sin contexto suficiente

## Decision final

Se aprueba una politica de comparacion por nombres con tres capas:

- origen
- normalizado
- actual

Y se aprueba tratar los renombres manuales como una transformacion especial que afecta el matching contra metadata, pero sin intentar aun reconstruir automaticamente todo el historial de nombres desde el script.
