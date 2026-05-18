# Resolvedor de Fuente y Metadata para Perfilado IA Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar de forma incremental un resolvedor de fuente y metadata para `dataset_profile_for_ai()` que pueda combinar contexto declarado por el usuario, deteccion de origen, metadata por fuente y alertas por desajustes, sin degradar la utilidad actual del helper ni aplicar metadata equivocada con falsa confianza.

**Architecture:** La implementacion debe seguir la arquitectura aprobada en capas:
1. perfilado del objeto actual
2. contexto declarado por el usuario
3. resolucion de fuente
4. carga y matching de metadata
5. alertas de desajuste

La regla central es: **mejor degradar a heuristicas con advertencia que aplicar metadata equivocada con falsa seguridad**.

**Tech Stack:** R, testthat, `R/ai_dataset_profile.R`, posibles helpers adicionales en `R/`, lectura futura de Excel/CSV/JSON, documentacion en `docs/02_diseno` y `docs/06_desarrollo`.

---

## File Structure

### Existing files to modify
- `R/ai_dataset_profile.R`
  - integrar nuevas capas de contexto
  - orquestar resolucion y matching
  - renderizar trazabilidad y alertas
- `tests/testthat/test_ai_dataset_profile.R`
  - cobertura de resolucion, metadata, ambiguedad y desajustes

### Candidate new files to create
- `R/ai_source_context.R`
  - helpers de contexto y resolucion de fuente
- `R/ai_source_metadata.R`
  - helpers de lectura y matching de metadata por fuente
- `R/ai_name_matching.R`
  - normalizacion de nombres y comparacion origen/actual
- `R/ai_source_alerts.R`
  - reglas futuras de alertas por desajustes
- `docs/06_desarrollo/fases/`
  - un cierre documental por cada etapa relevante

### Reference files
- `docs/02_diseno/2026-05-18-arquitectura-del-resolvedor-de-fuente-y-metadata-para-perfilado-ia.md`
- `docs/02_diseno/2026-05-18-premortem-10-casos-de-borde-para-resolvedor-de-fuente-y-metadata-ia.md`
- `docs/02_diseno/2026-05-18-diseno-de-resolucion-de-metadata-para-dataset-profile-for-ai.md`
- `docs/02_diseno/2026-05-18-ficha-json-canonica-de-ejemplo-para-metadata-de-perfilado-ia.md`
- `docs/02_diseno/2026-05-18-diseno-de-normalizacion-de-nombres-y-renombres-para-perfilado-ia.md`
- `docs/03_planes/2026-05-18-contexto-de-fuente-etapa-1-para-dataset-profile-for-ai-implementation-plan.md`

---

## Strategy general

Este plan maestro no reemplaza el plan de `tipo_fuente` de etapa 1. Lo toma como prerequisito y organiza las fases siguientes.

### Orden recomendado

1. completar etapa 1 (`tipo_fuente`)
2. agregar `archivo_fuente` y resolucion basica de origen
3. incorporar metadata por carpeta y matching de fichas
4. incorporar matching normalizado de columnas
5. incorporar alertas por desajustes relevantes

Cada fase debe conservar:

- degradacion segura
- mensajes en espanol
- utilidad del helper sin contexto extra

---

## Fase 1: Contexto declarado por el usuario

### Estado

Ya tiene plan propio:

- `docs/03_planes/2026-05-18-contexto-de-fuente-etapa-1-para-dataset-profile-for-ai-implementation-plan.md`

### Resultado esperado

- `tipo_fuente`
- trazabilidad de contexto declarado
- renderer breve del origen declarado

### Regla

No abrir las fases siguientes hasta verificar que esta capa no rompe el helper actual.

---

## Fase 2: `archivo_fuente` y resolucion basica de origen

### Goal

Permitir que el helper reciba un artefacto origen opcional y, cuando sea posible, detecte:

- `gca`
- `gca2`
- `oracle` futuro por metadata declarada

sin depender aun de metadata por carpeta.

### Scope

Incluye:
- `archivo_fuente = NULL`
- validacion de existencia de archivo
- deteccion basica de extensiones:
  - `.xls`
  - `.xlsx`
  - `.csv`
- detectores livianos:
  - `GCA.net` por firma de hoja `Informacion de la consulta`
  - `GCA2` por `Caratula`

No incluye:
- parseo del script activo
- resolucion `oracle` automatica desde conexiones
- lectura profunda de multiples hojas de datos

### Task 2.1: Fijar contrato de `archivo_fuente` en tests

- [ ] prueba para `archivo_fuente = NULL`
- [ ] prueba para ruta inexistente
- [ ] prueba para archivo reconocido como `gca`
- [ ] prueba para archivo reconocido como `gca2`
- [ ] prueba para archivo ambiguo o incompleto

### Task 2.2: Implementar estructura de `source_context`

- [ ] definir un bloque comun como:
  - `type`
  - `source`
  - `confidence`
  - `source_id`
  - `warnings`
- [ ] integrar `tipo_fuente` y `archivo_fuente` sin conflicto

### Task 2.3: Implementar detectores livianos

- [ ] `resolve_gca_source_from_workbook()`
- [ ] `resolve_gca2_source_from_workbook()`
- [ ] politica de confianza `high/medium/low`

### Task 2.4: Verificacion

- [ ] correr prueba enfocada
- [ ] correr suite completa
- [ ] documentar cierre de la fase

---

## Fase 3: Lectura de metadata por carpeta

### Goal

Permitir que el helper busque y cargue fichas JSON de metadata por fuente desde una carpeta configurable.

### Scope

Incluye:
- `metadata_dir` explicito
- opcion global como fallback futuro
- lectura de JSON por fuente
- validacion minima del formato canonico

No incluye:
- biblioteca compartida multi-oficina
- permisos por red
- UI de edicion

### Task 3.1: Fijar contrato de resolucion de carpeta en tests

- [ ] sin `metadata_dir`, no falla
- [ ] carpeta inexistente -> advertencia clara
- [ ] carpeta valida con JSON valido -> metadata cargada
- [ ] carpeta con JSON invalido -> advertencia y degradacion

### Task 3.2: Implementar cargador de metadata

- [ ] helper tipo `load_ai_source_metadata()`
- [ ] validacion de:
  - `version`
  - `source_type`
  - `source_id`
  - `display_name`
  - `columnas`
- [ ] tolerancia a campos extra con advertencia

### Task 3.3: Implementar matching de ficha por fuente

- [ ] match exacto por `source_id`
- [ ] match por `aliases`
- [ ] si hay ambiguedad, no aplicar metadata automaticamente

### Task 3.4: Verificacion

- [ ] prueba enfocada
- [ ] suite completa
- [ ] documento de cierre

---

## Fase 4: Matching normalizado de columnas

### Goal

Comparar metadata de origen con el objeto actual sin depender solo de coincidencia literal de nombres.

### Scope

Incluye:
- normalizacion interna equivalente a `clean_names()`
- comparacion entre:
  - nombre de origen
  - nombre normalizado
  - nombre actual

No incluye:
- reconstruccion automatica completa de renombres desde el script
- aliases complejos por columna en primera instancia

### Task 4.1: Fijar contrato de matching en tests

- [ ] metadata en mayusculas vs objeto en minusculas
- [ ] metadata en snake_case vs objeto exacto
- [ ] nombre esperado ausente pero nombre normalizado presente
- [ ] renombre fuerte sin match seguro -> advertencia, no match automatico

### Task 4.2: Implementar normalizador de nombres

- [ ] helper interno de normalizacion
- [ ] politica consistente con `janitor::clean_names()` sin volverla obligatoria

### Task 4.3: Implementar comparador origen/actual

- [ ] devolver:
  - matches fuertes
  - matches normalizados
  - columnas no resueltas
  - ambiguedades

### Task 4.4: Verificacion

- [ ] prueba enfocada
- [ ] suite completa
- [ ] documento de cierre

---

## Fase 5: Alertas por desajustes relevantes

### Goal

Informar diferencias significativas entre origen esperado y estado actual del objeto sin reconstruir todo el pipeline.

### Scope

Incluye alertas sobre:
- tipos no alineados
- fechas no reparadas
- identificadores no normalizados
- faltantes inesperados
- cardinalidad anomala respecto de lo esperado

No incluye:
- historial completo de transformaciones
- parseo del script activo

### Task 5.1: Fijar contrato de alertas en tests

- [ ] tipo esperado `datetime` vs actual `character`
- [ ] identificador esperado normalizado vs actual `numeric`
- [ ] faltantes altos pero esperables
- [ ] faltantes altos inesperados

### Task 5.2: Implementar generador de alertas

- [ ] helper tipo `build_ai_profile_source_alerts()`
- [ ] solo alertas utiles
- [ ] sin sobrecargar salida

### Task 5.3: Integrar alertas al renderer

- [ ] seccion breve y visible
- [ ] no mostrar seccion vacia si no hay alertas

### Task 5.4: Verificacion

- [ ] prueba enfocada
- [ ] suite completa
- [ ] documento de cierre

---

## Fase 6: Lineas futuras, fuera del alcance inmediato

Estas lineas no deberian entrar en la primera implementacion del resolvedor:

- inspeccion del script activo
- reconstruccion de joins
- equivalencias automaticas complejas entre `GCA.net` y `GCA2`
- biblioteca compartida multi-oficina con permisos
- UI de edicion de metadata

Conviene mantenerlas en backlog o diseno, no abrirlas antes de validar las fases 1 a 5.

---

## Validation Notes

- nunca volver obligatorios `tipo_fuente`, `archivo_fuente` o `metadata_dir`
- nunca aplicar metadata automaticamente cuando hay ambiguedad fuerte
- no usar `odbc` como tipo semantico aprobado
- mantener mensajes y advertencias en espanol
- preferir degradacion elegante a match dudoso
- no romper el helper actual para usuarios que solo quieren una alternativa mejor a `glimpse()`

## Execution Recommendation

La ejecucion deberia seguir este orden:

1. completar primero el plan especifico de `tipo_fuente`
2. luego abrir Fase 2 en una sesion separada
3. avanzar solo una fase por vez, con verificaciones completas entre fases

La razon es simple: este frente acumula varias clases de incertidumbre, y separar las fases reduce mucho el riesgo de acoplar decisiones todavia inmaduras.
