# Diseno de ajustes semanticos basados en prueba real del helper IA

## Resumen

Este documento registra tres ajustes priorizados a partir de una prueba real del helper de perfilado seguro para IA sobre datasets institucionales.

Los resultados muestran que el helper ya es util, pero todavia necesita tres mejoras de alta prioridad:

1. entrecomillar valores categoricos visibles;
2. evitar que nombres institucionales como `NOMBRE_UNIDAD` caigan en `texto libre`;
3. reinterpretar como `fecha` las columnas `POSIXct` cuya hora efectiva no aporta informacion.

La conclusion practica es simple:

- el helper ya conserva mejor la estructura de `glimpse()`;
- ahora conviene refinar la semantica de lectura en casos institucionales frecuentes.

## Evidencia de origen

La prueba real se hizo sobre:

- `gca_7014_202301`
- `Resultado_GCA`
- `Resultado_GCA2`

Hallazgos principales observados:

- `CANAL`, `MOTIVO` y `RANGO` se renderizan como categoricas sin comillas en sus valores visibles;
- `NOMBRE_UNIDAD` queda como `texto libre`, aunque representa nombres de unidades organizativas con repeticion real;
- `FECHA_DESDE` y `FECHA_HASTA` se muestran como `fecha-hora` pese a que la granularidad efectiva es `dia` y la hora visible es `00:00:00`;
- `FCH_ULT_ACT` si parece una `fecha-hora` genuina, por lo que no conviene degradar todas las `POSIXct` por igual.

## Problema de producto

La salida actual ya es prudente y bastante informativa, pero en estos casos institucionales aparece una tension:

- la estructura importada se preserva;
- la interpretacion semantica a veces exagera precision o clasifica demasiado agresivamente como `texto libre`.

Eso importa porque la IA no necesita solo "tipos seguros". Tambien necesita que el resumen le comunique correctamente si una variable es:

- una categoria con valores textuales definidos;
- un nombre institucional repetible;
- o una fecha sin componente horario relevante.

## Alcance

Este diseno cubre solo tres frentes:

1. render de valores categoricos visibles;
2. heuristica de nombres institucionales;
3. reinterpretacion semantica de `POSIXct` con hora no sustantiva.

## No alcance

Este documento no cubre todavia:

- codigos numericos o numericas enteriformes importadas como `double`;
- deteccion de columnas constantes;
- mejoras nuevas sobre metadata por fuente;
- ni cambios sobre la UI Shiny.

## Decision 1: entrecomillar valores categoricos visibles

### Problema

Hoy el renderer muestra:

- `valores observados: PRESENCIAL, WEB`
- `valores observados: involucra inmuebles, Otros motivos`

Eso deja ambiguedad sobre:

- espacios al inicio o final;
- alcance exacto de cada valor;
- y casos con puntuacion o espaciado interno como `RANGO`.

### Decision

Los valores visibles de:

- `valores observados`
- `top niveles`
- `etiquetas observadas`
- `top etiquetas`

deben renderizarse entre comillas dobles.

### Ejemplo recomendado

En vez de:

```text
valores observados: PRESENCIAL, WEB
```

usar:

```text
valores observados: "PRESENCIAL", "WEB"
```

## Decision 2: nombres institucionales repetibles no deben caer tan facil en `texto libre`

### Problema

`NOMBRE_UNIDAD` hoy queda como `texto libre`, pero el usuario aporto evidencia de dominio:

- representa nombres de unidades organizativas;
- los valores se repiten en varias filas;
- no son observaciones abiertas ni notas narrativas.

### Decision

La heuristica debe favorecer `etiqueta nominal de entidad` cuando una columna `character`:

- parece nombre institucional;
- tiene repeticion real;
- y no presenta rasgos fuertes de texto libre abierto.

### Consecuencia

En este tipo de casos, el helper debe preferir:

- `etiqueta nominal de entidad`

por encima de:

- `texto libre`

## Decision 3: `POSIXct` con hora no sustantiva debe poder interpretarse como `fecha`

### Problema

En `FECHA_DESDE` y `FECHA_HASTA` la salida actual dice:

- `importada como POSIXct; interpretada como fecha-hora; granularidad dia`

Eso preserva el tipo importado, pero la interpretacion semantica exagera precision.

### Decision

Si una columna `POSIXct`:

- tiene granularidad efectiva `dia`;
- y la hora observada es sistematicamente no informativa, por ejemplo `00:00:00`;

entonces el helper debe mostrar:

- `importada como POSIXct; interpretada como fecha`

### Excepcion importante

No se debe aplicar esta degradacion a columnas como `FCH_ULT_ACT`, donde la hora si varia y aporta informacion real.

## Alternativas consideradas

### 1. Mantener el render actual y solo mejorar documentacion

No se eligio porque el problema ya no es de explicacion sino de semantica visible.

### 2. Quitar `POSIXct` del texto visible y mostrar solo la interpretacion

No se eligio porque iría contra la decision previa de conservar lo valioso de `glimpse()`.

### 3. Agregar mas heuristicas antes de cerrar estas tres

No se eligio porque estas tres mejoras tienen evidencia directa de uso real y conviene resolverlas primero.

## Siguiente paso recomendado

Implementar estas tres mejoras en este orden:

1. comillas dobles en categorias visibles;
2. reclasificacion de nombres institucionales;
3. reinterpretacion de `POSIXct` con hora no sustantiva.
