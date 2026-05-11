# Diseno: modulo de plantillas y guardrails de clasificacion para liberacion controlada

## Resumen

Este documento propone la siguiente evolucion del flujo de clasificacion de ObfuscatoR:

- transformar la persistencia automatica por esquema en un modulo explicito de plantillas;
- hacer visible cuando una plantilla fue aplicada;
- permitir volver rapidamente a las sugerencias automaticas de la app;
- y agregar guardrails para cambios de clasificacion que puedan debilitar la evaluacion de riesgo.

La conclusion practica es que conviene dejar de tratar las plantillas como una conveniencia implícita y pasarlas a un flujo visible, reversible y gobernado.

## Problema

El comportamiento actual aporta continuidad, pero tiene tres debilidades:

1. Una plantilla previa puede reaplicarse sin suficiente conciencia del usuario.
2. No existe una accion directa para volver al estado sugerido automaticamente por la app.
3. Cambios de rol potencialmente riesgosos, por ejemplo mover una variable sugerida como `QI` a `ID` o `KEEP`, no activan hoy una advertencia proporcional.

Esto no rompe el motor, pero sí puede degradar la confianza, inducir clasificaciones heredadas no deseadas y dificultar una presentacion defendible ante terceros.

## Objetivos

- hacer visible el origen de la clasificacion actual;
- permitir explorar sin “contaminar” futuras cargas por accidente;
- conservar la utilidad de la persistencia por esquema;
- y agregar guardrails donde la decision del usuario pueda debilitar el modelo de liberacion controlada.

## Principios de diseño

### 1. Visibilidad

Toda clasificacion aplicada automaticamente debe dejar una huella visible en la UI.

### 2. Reversibilidad

El usuario debe poder:

- volver a sugerencias automaticas;
- descartar la plantilla aplicada;
- y elegir conscientemente otra plantilla compatible.

### 3. Proporcionalidad

No todos los cambios de rol requieren la misma friccion. La app debe endurecer solo los cambios que puedan empeorar significativamente la interpretacion del riesgo.

### 4. Separacion entre prueba y continuidad

Una plantilla usada en una prueba exploratoria no deberia adquirir automaticamente el mismo estatus que una plantilla estable de trabajo.

## Propuesta funcional

## A. Modulo visible de plantillas

El bloque principal de clasificacion deberia incluir un submodulo visible con:

- `Plantilla activa: <nombre visible>`
- `Origen: automatica / guardada por el usuario / sugerencias automáticas`
- `Compatibilidad: exacta / aproximada`
- acciones:
  - `Guardar plantilla`
  - `Cargar plantilla`
  - `Volver a sugerencias automáticas`
  - `Descartar plantilla activa`

### Estados del modulo

1. `Sin plantilla activa`
2. `Plantilla aplicada automaticamente`
3. `Plantilla seleccionada manualmente`
4. `Clasificacion modificada respecto de la plantilla`

Eso permite entender si la tabla actual refleja:

- una sugerencia fresca de la app;
- una continuidad del trabajo previo;
- o una mezcla de ambas cosas.

## B. Plantillas nombradas

Las plantillas deberian tener:

- nombre amigable editable;
- hash de esquema como dato tecnico interno;
- opcion de descripcion corta;
- y, mas adelante, categoria o familia.

Ejemplos:

- `Personas - clasificacion conservadora`
- `Personas - demo tecnica`
- `Ingresos trimestrales - prueba`

## C. Selector de plantillas compatibles

En lugar de depender solo del hash, la app deberia ofrecer una lista de plantillas compatibles con:

- nombre visible;
- nivel de compatibilidad;
- fecha de ultima actualizacion;
- y origen.

Compatibilidad sugerida:

- `Exacta`
- `Aproximada`
- `No recomendada`

## D. Volver a sugerencias automáticas

Debe existir un boton claro que:

- descarte la plantilla actualmente aplicada;
- regenere la clasificacion sugerida por la app para el dataset cargado;
- y deje constancia visible de que se volvio al estado sugerido automatico.

Esta accion es especialmente importante para pruebas y para evitar heredar decisiones experimentales.

## E. Guardrails de clasificacion

Se recomienda endurecer ciertos cambios con una advertencia contextual.

### Cambios que deberian advertirse

- `QI -> KEEP`
- `QI -> ID`
- `SENS -> KEEP`
- `PRIV -> KEEP`
- `PRIV -> SENS`

La advertencia no necesariamente debe bloquear, pero sí explicar:

- que riesgo se reduce o se pierde de vista;
- por que la app habia sugerido otra cosa;
- y que el cambio puede alterar la evaluacion de liberacion controlada.

## F. Registro visible de cambios sensibles

La interfaz podria mostrar un pequeño estado como:

- `Sin cambios sensibles`
- `1 cambio sensible pendiente de confirmar`
- `3 cambios sensibles respecto de las sugerencias`

Eso mejora mucho la auditabilidad humana sin convertir la experiencia en un flujo burocratico.

## Alternativas consideradas

### Mantener solo persistencia automatica por hash

No se recomienda. Es comoda, pero demasiado silenciosa para un flujo donde la clasificacion afecta la interpretacion del riesgo.

### Quitar por completo la carga automatica

Tampoco se recomienda. Haria perder continuidad en casos donde la funcionalidad actual sí agrega valor real.

### Hacer que toda plantilla requiera seleccion manual

Es defendible, pero probablemente demasiado pesada para el MVP. Conviene una solucion intermedia: permitir carga automatica, pero hacerla visible y reversible.

## Recomendacion

La mejor evolucion es:

1. mantener la compatibilidad automatica por esquema;
2. volverla visible en la UI;
3. permitir revertir a sugerencias automaticas;
4. y agregar guardrails solo en cambios de rol realmente sensibles.

Eso conserva la comodidad actual, pero reduce mucho el riesgo de heredar clasificaciones equivocadas sin darse cuenta.

## Siguiente paso recomendado

Convertir este diseño en un plan corto de implementacion por tareas, priorizando:

1. banner y estado visible de plantilla activa;
2. boton `Volver a sugerencias automáticas`;
3. notificaciones y nombres amigables;
4. selector de plantillas compatibles;
5. guardrails de reclasificacion sensible.
