# Arquitectura del resolvedor de fuente y metadata para perfilado IA

## Proposito

Sintetizar en una sola arquitectura operativa el frente de:

- contexto de fuente
- metadata por fuente
- matching contra el objeto actual
- y degradacion segura a heuristicas

para el subproyecto `dataset_profile_for_ai`.

El objetivo es que, cuando se pase a implementacion, exista una vision unica y compacta de:

- componentes
- orden de resolucion
- entradas opcionales
- salidas esperadas
- y politicas de seguridad ante ambiguedad

## Problema que resuelve

El helper ya perfila bien el objeto actual, pero todavia no integra de forma robusta:

- de donde vienen los datos;
- que metadata de origen podria existir;
- si el nombre actual de las columnas coincide con el de la fuente;
- ni si conviene aplicar conocimiento declarado por fuente o degradar a heuristicas.

Sin una arquitectura clara, este frente corre dos riesgos:

1. crecer en piezas sueltas y acopladas;
2. aplicar metadata equivocada con exceso de confianza.

## Principio rector

La regla central de toda esta arquitectura es:

- **mejor degradar a heuristicas con advertencia que aplicar metadata equivocada con falsa seguridad**

## Vision general

La arquitectura recomendada tiene cinco capas:

1. **perfilado del objeto actual**
2. **contexto declarado por el usuario**
3. **resolucion de fuente**
4. **carga y matching de metadata**
5. **alertas por desajustes relevantes**

Las capas 1 y 2 pueden existir por si solas.

Las capas 3, 4 y 5 agregan valor progresivo, pero no deben volver inutil al helper cuando faltan.

## Capa 1: perfilado del objeto actual

### Responsabilidad

Describir el objeto tal como esta hoy en R.

### Incluye

- tipos importados
- tipos inferidos
- patrones identificatorios
- granularidad temporal
- faltantes
- texto libre
- riesgo semantico basico

### Estado actual

Esta capa ya existe y funciona dentro de `R/ai_dataset_profile.R`.

### Regla

Nunca debe depender de metadata externa para seguir siendo util.

## Capa 2: contexto declarado por el usuario

### Responsabilidad

Permitir pistas livianas y overrides explicitos.

### Componentes

- `config`
- `tipo_fuente` en etapa 1
- `archivo_fuente` en etapa 2

### Precedencia

Lo declarado por el usuario tiene prioridad sobre:

- metadata por fuente
- heuristicas automaticas

### Regla

Esta capa no debe mutar configuracion global silenciosamente.

## Capa 3: resolucion de fuente

### Responsabilidad

Intentar identificar el origen tecnico de la fuente.

### Tipos iniciales aprobados

- `gca`
- `gca2`
- `oracle`
- `excel`
- `csv`
- `desconocida`

### Subdetectores futuros

- detector `GCA.net` desde `.xls`
- detector `GCA2` desde `.xlsx`
- detector `GCA2` desde `.csv`
- detector `oracle` por metadata declarada o contexto externo

### Salida conceptual recomendada

```text
source_context
  - tipo
  - origen_de_la_evidencia
  - confianza
  - source_id si existe
  - advertencias si aplica
```

### Regla

No forzar identidad fuerte cuando solo existe evidencia parcial.

## Capa 4: carga y matching de metadata

### Responsabilidad

Buscar una ficha de metadata por fuente y decidir si puede aplicarse al objeto actual.

### Entradas futuras

- `metadata_dir` explicito
- opcion global de carpeta de metadata
- `source_id` o evidencias de fuente

### Orden de resolucion recomendado

1. `metadata_dir` explicito
2. carpeta configurada por opcion
3. si no existe ninguna, continuar sin metadata

### Matching recomendado

1. `source_id` exacto
2. `aliases`
3. fingerprint compatible en casos especiales
4. si hay ambiguedad, no aplicar metadata automatica

### Matching de columnas recomendado

1. nombre actual exacto
2. nombre normalizado
3. alias futuros si existieran
4. si no hay match seguro, marcar desajuste

### Regla

No declarar una columna faltante sin antes intentar matching normalizado.

## Capa 5: alertas por desajustes relevantes

### Responsabilidad

Informar solo diferencias utiles entre:

- origen esperado
- y estado actual del objeto

### Ejemplos

- fecha esperada como `datetime` sigue como `character`
- identificador esperado como normalizado sigue como `numeric`
- faltantes altos inesperados
- cardinalidad anomala respecto de lo esperado

### Regla

No reconstruir el pipeline completo.

La salida debe priorizar alertas utiles, no historia exhaustiva.

## Componentes recomendados

### 1. `profile_dataset_for_ai()`

Orquestador principal.

Responsabilidades:

- perfilar el objeto actual
- integrar `config`
- integrar `tipo_fuente`
- y mas adelante integrar `archivo_fuente` y metadata externa

### 2. Normalizadores chicos

Ejemplos futuros:

- normalizador de `tipo_fuente`
- normalizador de nombres de variables
- normalizador de rutas de metadata

### 3. Resolutores de fuente

Ejemplos futuros:

- `resolve_gca_source()`
- `resolve_gca2_source()`
- `resolve_oracle_source()`

### 4. Cargador de metadata

Responsabilidades:

- ubicar ficha por fuente
- validar estructura minima
- devolver match, ambiguedad o ausencia

### 5. Comparador origen vs estado actual

Responsabilidades:

- comparar columnas esperadas y observadas
- detectar desajustes relevantes
- producir alertas resumidas

## Flujo de datos recomendado

```text
data.frame actual
  -> perfilado base
  -> aplicar config declarada
  -> integrar tipo_fuente si existe
  -> resolver fuente si hay evidencia suficiente
  -> buscar metadata si hay contexto de fuente y carpeta
  -> hacer matching de columnas
  -> generar alertas de desajuste
  -> render final para IA
```

## Politica de degradacion

### Caso ideal

- `tipo_fuente` claro
- `source_id` claro
- metadata exacta
- matching de columnas alto

### Caso intermedio

- tipo de fuente conocido
- metadata ambigua o ausente
- helper sigue con heuristicas + advertencias

### Caso minimo

- solo `data.frame`
- sin contexto extra
- helper sigue siendo util y seguro

## Lo que no deberia hacer esta arquitectura en la primera implementacion

No conviene mezclar ya mismo:

- lectura profunda de Excel multihoja
- parseo del script activo
- reconstruccion de joins
- equivalencias automáticas complejas entre `GCA.net` y `GCA2`
- ni una biblioteca compartida multi-oficina con permisos todavia no resueltos

## Decisiones de precedencia consolidadas

### Sobre semantica de columnas

1. `config` del usuario
2. metadata por fuente
3. heuristica automatica

### Sobre contexto de fuente

1. `tipo_fuente` declarado por el usuario
2. evidencia desde `archivo_fuente`
3. deteccion automatica por dataset o nombre

### Sobre aplicacion de metadata

1. match exacto confiable
2. match secundario razonable
3. si hay ambiguedad, no aplicar

## Riesgos principales que esta arquitectura intenta contener

- aplicar metadata equivocada
- romper el helper para usuarios sin contexto extra
- declarar columnas faltantes por diferencias de nombres
- confundir id de consulta con id de ejecucion
- y sobrediseñar el sistema antes de tener evidencia de uso real

## Arquitectura incremental recomendada

### Fase 1

- `tipo_fuente`
- trazabilidad de contexto declarado

### Fase 2

- `archivo_fuente`
- detectores basicos `gca` / `gca2`

### Fase 3

- carga de metadata por carpeta
- matching por `source_id` y nombres normalizados

### Fase 4

- alertas por desajustes origen vs estado actual

### Fase 5

- exploracion futura del script activo

## Decision final

Se aprueba esta arquitectura como sintesis operativa del frente de resolvedor de fuente y metadata para perfilado IA.

Su valor principal es que deja claro que:

- el helper debe seguir siendo util sin contexto extra;
- el contexto adicional debe entrar por capas;
- y toda automatizacion futura debe degradar con seguridad cuando la evidencia no alcance.
