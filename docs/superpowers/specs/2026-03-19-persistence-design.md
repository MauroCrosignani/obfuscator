# Spec: Persistencia de Clasificación (Proactive Assistant)

**Fecha:** 2026-03-19  
**Estado:** Aprobado  

## 1. Problema
Actualmente, `ObfuscatoR Studio` requiere que el usuario clasifique manualmente las columnas del dataset (IDs, Fechas, etc.) en cada sesión, incluso si se trata del mismo archivo o esquema. Esto genera fricción y desincentiva el uso repetitivo.

## 2. Solución Propuesta (Opción 1: Asistente Proactivo)
Implementar un sistema de persistencia basado en plantillas JSON vinculadas a la estructura del dataset (hash de columnas) que permita el mapeo automático y sugerencias inteligentes mediante "fuzzy matching".

## 3. Arquitectura y Componentes
### 3.1 Módulo `PersistenceManager` (R)
- **Función `generate_schema_hash(df)`**: Crea un identificador único basado en los nombres de las columnas ordenadas.
- **Función `save_role_config(roles, path)`**: Serializa el estado de las zonas a JSON.
- **Función `load_role_config(df, config_path)`**:
  - Busca coincidencias exactas por nombre de columna.
  - Utiliza **distancia de Levenshtein** para encontrar coincidencias parciales (umbral sugerido: > 0.8).

### 3.2 Interfaz de Usuario (Shiny + JS)
- **Controles**: Botones de "Guardar Plantilla" y "Cargar Plantilla" en el panel lateral.
- **Visualización de Sugerencias**:
  - Las variables con coincidencia parcial aparecerán con un **borde punteado** (`border-style: dashed`) y un icono de ayuda.
  - Un botón de **Confirmar Sugerencias** permitirá validar los cambios en lote.

## 4. Accesibilidad (W3C AA)
- **Contraste**: La paleta de colores de las zonas se ajustará para cumplir con el ratio 4.5:1 (ej. Ocre para numéricas, Verde oscuro para categóricas).
- **Doble Codificación**: Las sugerencias se indicarán mediante estilo visual (borde) e iconos de texto, no solo color.

## 5. Casos de Prueba
- **Match Exacto**: Cargar un dataset, clasificarlo, guardar, recargar -> Las columnas deben aparecer en sus zonas originales.
- **Match Parcial**: Guardar configuración para `FECHA_NAC`, cargar dataset con `FEC_NACIM` -> Debe aparecer en la zona "Fechas" como sugerencia punteada.
- **Sin Configuración**: Cargar un dataset nuevo -> Debe seguir funcionando la detección automática por defecto.
