# Cierre del bloque: resolvedor de fuente y metadata para perfilado IA

## Resumen ejecutivo

Con la finalización de las etapas 1 a 5, quedó cerrada una primera versión coherente del bloque de:

- contexto de fuente,
- resolución de origen,
- carga de metadata declarativa,
- matching normalizado de columnas,
- y alertas por desajustes relevantes

para el subproyecto `profile_dataset_for_ai()`.

El resultado es un helper que sigue siendo útil como reemplazo enriquecido de `glimpse()` aun sin configuración adicional, pero que ahora también puede aprovechar:

- contexto declarado por el usuario;
- artefactos de origen como planillas `GCA.net` y `GCA2`;
- fichas JSON por fuente;
- y una capa de alertas útil para no pasarle a la IA un contexto engañosamente “limpio”.

## Qué quedó resuelto en este bloque

### Etapa 1: `tipo_fuente`

- se aceptan pistas declarativas en español;
- `oracle` se trata como categoría semántica válida;
- `odbc` no se acepta como tipo aprobado y se sugiere `oracle`.

### Etapa 2: `archivo_fuente`

- detección liviana de contexto `GCA.net` y `GCA2`;
- integración con el contexto declarado;
- degradación segura cuando la evidencia del archivo no alcanza.

### Etapa 3: `metadata_dir`

- carga de fichas JSON por fuente;
- validación mínima del formato canónico;
- match por `source_id` o `alias`;
- y rechazo prudente de matches ambiguos.

### Etapa 4: matching normalizado de columnas

- comparación por nombre exacto;
- comparación por normalización equivalente a `clean_names()`;
- detección de columnas no resueltas;
- y rechazo de “renombres adivinados” sin evidencia suficiente.

### Etapa 5: alertas por desajustes relevantes

- fechas no reparadas;
- identificadores no normalizados;
- faltantes altos esperables;
- y faltantes altos inesperados.

## Artefactos principales

- Helper central:
  - [R/ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R)
- Tests del subproyecto:
  - [test_ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_ai_dataset_profile.R)
- Diseño y plan maestro:
  - [2026-05-18-arquitectura-del-resolvedor-de-fuente-y-metadata-para-perfilado-ia.md](c:/Users/mcros/Documents/obfuscator/docs/02_diseno/2026-05-18-arquitectura-del-resolvedor-de-fuente-y-metadata-para-perfilado-ia.md)
  - [2026-05-18-resolvedor-de-fuente-y-metadata-para-perfilado-ia-implementation-plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-18-resolvedor-de-fuente-y-metadata-para-perfilado-ia-implementation-plan.md)

## Verificación consolidada

Pruebas enfocadas del subproyecto:

```r
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Resultado final:

- `PASS 157`

Suite completa del proyecto:

```r
Rscript tests/testthat.R
```

Resultado final:

- `PASS 541`

## Limitaciones que siguen vigentes

Este cierre no debe interpretarse como “solución institucional completa”. Todavía quedan fuera del bloque:

- inspección del script activo;
- reconstrucción automática de joins, renombres y derivaciones;
- detección automática de `oracle` a partir de conexiones vivas;
- múltiples bibliotecas de metadata con gobernanza multi-oficina;
- UI de edición para fichas por fuente.

## Alternativas consideradas y por qué no se eligieron

### 1. Forzar metadata siempre que existiera una coincidencia parcial

No se eligió porque incrementaba demasiado el riesgo de aplicar metadata equivocada con falsa confianza.

### 2. Exigir configuración detallada por variable para usar el helper

No se eligió porque habría destruido la adopción como reemplazo práctico de `glimpse()`.

### 3. Reconstruir el pipeline completo de transformaciones

No se eligió porque, en esta etapa, sería complejo, frágil y costoso en contexto sin asegurar mejor resultado.

## Valor creado para explicar a terceros

La explicación más simple y defendible de este bloque es:

> El helper ya no se limita a describir el dataset “como viene”. Ahora puede combinar lo que observa en el objeto actual con contexto de origen y metadata declarativa, y advertir cuándo algo importante no coincide con lo esperable.

## Próximo paso recomendado

El bloque quedó suficientemente maduro como para cambiar de foco. Las dos rutas más razonables a partir de aquí son:

1. mejorar la experiencia de uso desde RStudio con ejemplos, helpers o configuración más accesible;
2. o diseñar con más detalle la biblioteca compartida de metadata por oficina o grupo antes de intentar automatizar su consumo a mayor escala.
