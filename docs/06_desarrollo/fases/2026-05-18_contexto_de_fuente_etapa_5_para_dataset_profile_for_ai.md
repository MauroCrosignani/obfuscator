# Etapa 5: Alertas por desajustes relevantes para `dataset_profile_for_ai()`

## Resumen

En esta etapa se incorporó una capa breve de alertas de consistencia entre:

- lo que la metadata de origen declara como esperable;
- y el estado actual del objeto que se quiere describir para una IA.

La decisión metodológica fue mantener estas alertas en un nivel útil y sobrio. No se intentó reconstruir el historial completo de transformaciones ni explicar el pipeline línea por línea. Se priorizaron solo señales que puedan cambiar la interpretación del dataset o revelar un problema de preparación.

## Qué se completó

- Se agregó un generador de `source_alerts` al perfil estructurado.
- Se incorporaron alertas para cuatro casos iniciales:
  - variable temporal esperada como `datetime` o `date` que sigue importada como `character`
  - identificador esperado normalizado que sigue como `numeric` o `integer`
  - faltantes altos pero declarados como esperables
  - faltantes altos inesperados
- El renderer ahora muestra una sección breve:
  - `Alertas de consistencia respecto del origen`
  - solo si realmente existen alertas

## Artefactos tocados

- Helper principal:
  - [R/ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R)
- Tests del subproyecto:
  - [test_ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_ai_dataset_profile.R)

## Decisión metodológica aplicada

Se evaluaron dos enfoques posibles:

1. describir el pipeline completo de transformaciones;
2. resumir únicamente desajustes relevantes entre origen esperado y estado actual.

Se eligió el segundo porque:

- tiene mucha menos fricción para el usuario;
- consume menos contexto cuando se copia la salida a una IA;
- y evita aparentar una trazabilidad que hoy todavía no se puede reconstruir con seguridad.

## Verificación ejecutada

Pruebas enfocadas:

```r
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Resultado:

- `PASS 156`

Suite completa:

```r
Rscript tests/testthat.R
```

Resultado:

- `PASS 540`

## Qué no se hizo todavía

Esta etapa no incorpora todavía:

- cardinalidad anómala respecto de lo esperado;
- granularidad temporal más fina de la esperable;
- diferencias sistemáticas entre `tipo_esperado` y tipo actual fuera de los casos más riesgosos;
- reconstrucción de renombres o transformaciones intermedias.

## Problema resuelto

Antes de esta etapa, el helper podía conocer mejor la fuente y matchear metadata por columnas, pero todavía no sintetizaba qué diferencias importantes valía la pena advertirle a la IA o al usuario del script. Ahora esa información ya aparece en una forma compacta y accionable.

## Valor creado

- Mejora la calidad del contexto que se entrega a la IA.
- Hace visibles problemas reales de preparación sin exigir contar todo el pipeline.
- Complementa el perfil descriptivo con una capa de juicio técnico mínima pero útil.

## Riesgo evitado

- Asumir que una variable ya fue normalizada solo porque existe metadata de origen.
- Tratar como inocuos datasets con fechas no reparadas o identificadores todavía numéricos.
- Sobreexplicar transformaciones irrelevantes y gastar contexto innecesariamente.

## Siguiente paso recomendado

El bloque principal del resolvedor de fuente y metadata ya quedó cerrado de forma coherente en su primera versión. El siguiente paso razonable no es seguir agregando complejidad interna a ciegas, sino decidir si conviene:

1. consolidar el bloque con ejemplos de uso más explícitos desde RStudio; o
2. abrir una nueva línea de trabajo sobre biblioteca compartida de metadata por oficina o grupo.
