# Diseno de evidencia y senales heuristicas para numericas institucionales

## Resumen

Este documento fija el siguiente ajuste semantico del helper de perfilado seguro para IA para columnas numericas institucionales que hoy llegan como `double`, pero cuyo comportamiento observado no siempre corresponde a una medida continua clasica.

La decision central es no reemplazar la clasificacion base por una afirmacion mas fuerte, sino agregar capas explicitas y ordenadas:

1. tipo importado;
2. clasificacion programatica;
3. evidencia observada;
4. senal heuristica.

Con esto se preserva la parte reproducible del resumen y, a la vez, se habilita una lectura mas util para IA cuando una numerica parece codigo, valor constante o columna enteriforme.

## Evidencia de origen

La necesidad surge de la prueba real sobre datasets institucionales, donde aparecieron casos como:

- `COD_TIPO_VARIABLE`
- `UNIDAD_FUNCIONAL`
- `PERIODICIDAD`
- `CANT_TOTAL`

En esos ejemplos, la salida actual comunica bien el tipo importado y el rango, pero todavia deja un hueco:

- puede decir `importada como double; interpretada como numerica decimal`;
- pero no deja explicitamente asentado si la columna:
  - solo toma valores enteros;
  - tiene un unico valor observado;
  - o podria funcionar mas como codigo que como medida.

## Problema de producto

El helper ya viene haciendo un buen trabajo al preservar el tipo importado exacto, pero aca aparece una tension:

- si no agregamos nada mas, la IA puede tratar una columna tecnica como si fuera una medida continua;
- si la reclasificamos directamente como `codigo numerico`, corremos el riesgo de afirmar demasiado.

La salida correcta tiene que sostener ambas cosas:

- hecho reproducible y programaticamente verificable;
- y lectura heuristica prudente cuando la evidencia lo amerita.

## Alcance

Este diseno cubre solo columnas numericas importadas como `double` o `integer` donde la evidencia observada sugiera:

- comportamiento entero;
- valor unico observado;
- o posible uso como codigo numerico.

## No alcance

Este documento no cubre todavia:

- cambios sobre categoricas o temporales;
- metadata por fuente;
- deteccion de codigos alfanumericos;
- ni nuevas advertencias globales a nivel dataset.

## Decision 1: separar evidencia de clasificacion base

### Problema

Hoy el helper usa una redaccion como:

- `importada como double; interpretada como numerica decimal`

Eso es util, pero no deja claro el sujeto de la accion de interpretar ni separa suficientemente el hecho de la sugerencia.

### Decision

Para este frente, la salida debe pasar a una estructura mas explicita:

- `tipo importado: ...`
- `clasificacion programatica: ...`
- `evidencia observada: ...`
- `senal heuristica: ...`

### Justificacion

`clasificacion programatica` comunica mejor que la taxonomia visible proviene del helper y no de una verdad ontologica del dataset.

## Decision 2: expresar la evidencia en lenguaje literal y no implicito

### Problema

Formulas como `sin variacion observada` o reglas implicitas tipo `min = max` pueden ser demasiado abstractas para una IA o para una persona que no conozca el criterio interno.

### Decision

La evidencia debe expresarse de forma mas literal, por ejemplo:

- `evidencia observada: solo toma valores enteros`
- `evidencia observada: todos los valores observados son iguales: 14`

### Justificacion

Ese lenguaje:

- evita obligar a inferir la regla tecnica;
- deja visible el dato relevante;
- y reduce el riesgo de lectura ambigua.

## Decision 3: mantener la clasificacion base y sumar una senal heuristica prudente

### Problema

Una columna puede parecer codigo numerico sin que el helper tenga certeza suficiente para afirmarlo.

### Decision

No se debe reemplazar automaticamente:

- `clasificacion programatica: numerica decimal`

por:

- `clasificacion programatica: codigo numerico`

En cambio, cuando la evidencia alcance, se debe agregar:

- `senal heuristica: podria funcionar como codigo numerico`

### Criterios tentativos para activar la senal

La senal puede activarse cuando coincidan varias condiciones, por ejemplo:

- todos los valores observados son enteros;
- cardinalidad baja o media respecto a la cantidad de filas;
- nombre de columna compatible con codigo, id, tipo, clase, unidad o patron parecido;
- o columna constante claramente no continua.

Estos criterios se deben mantener prudentes y revisables.

## Ejemplos recomendados

### Caso constante y potencialmente tecnico

```text
COD_TIPO_VARIABLE: tipo importado: double; clasificacion programatica: numerica decimal; evidencia observada: todos los valores observados son iguales: 14; senal heuristica: podria funcionar como codigo numerico; faltantes 0.0%.
```

### Caso enteriforme con dominio institucional

```text
UNIDAD_FUNCIONAL: tipo importado: double; clasificacion programatica: numerica decimal; evidencia observada: solo toma valores enteros; senal heuristica: podria funcionar como codigo numerico; rango aproximado 124-244; faltantes 0.0%.
```

## Alternativas consideradas

### 1. Reclasificar directamente como `codigo numerico`

No se eligio porque afirmaria demasiado con evidencia todavia indirecta.

### 2. No decir nada extra y dejar solo el rango

No se eligio porque deja pasar una senal valiosa para la IA en columnas institucionales frecuentes.

### 3. Convertir esto en advertencias globales del dataset

No se eligio porque la lectura relevante es por variable, no por dataset completo.

## Siguiente paso recomendado

Implementar primero el cambio de wording y la nueva estructura del renderer para numericas, y recien despues calibrar el disparador de `podria funcionar como codigo numerico` con tests sinteticos y un caso inspirado en `COD_TIPO_VARIABLE`.
