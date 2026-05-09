
# Documento de Especificación de la Solución: "ObfuscatoR" 🛡️
**Versión:** 1.0  
**Estado:** Listo para Implementación  
**Autor:** Consejero Estratégico de Especificaciones & [Tu Nombre/Cargo]

---

## 1. Visión Estratégica (El "Porqué")
### 1.1 El Problema Humano
Los analistas de datos en organismos estatales enfrentan un dilema: la necesidad de usar Inteligencia Artificial para ganar eficiencia versus la obligación legal de proteger el secreto tributario. La creación manual de datos ficticios es ineficiente y propensa a errores que invalidan el código generado por la IA.

### 1.2 Valores y Principios Guía
*   **Privacidad por Diseño:** Ningún dato sensible debe salir del servidor local (Rocky Linux).
*   **Obviedad Auditativa:** Las transformaciones deben ser evidentes a simple vista (ej. prefijos "999") para facilitar la supervisión humana.
*   **Paridad Funcional:** El `tibble` resultante debe ser estructuralmente idéntico al original para asegurar que el código generado sea 100% aplicable.

### 1.3 Métricas de Éxito (KPIs)
1.  **Tasa de Error de Ejecución:** 0% de diferencia en la estructura de columnas/clases entre el dato real y el ofuscado.
2.  **Tiempo de Ofuscación:** < 5 segundos para datasets de hasta 100,000 filas.
3.  **Auditabilidad:** Identificación visual instantánea de datos ficticios por parte de un tercero.

---

## 2. Terreno de Juego (Restricciones y Supuestos)
*   **Entorno:** RStudio Server sobre Rocky Linux. Ejecución 100% local, sin dependencias de APIs externas.
*   **Librerías:** Preferencia por `tidyverse` (dplyr, tidyr, purrr) para máxima legibilidad y auditoría del código.
*   **Memoria:** Procesamiento optimizado para `tibbles` en RAM.
*   **Supuesto Clave:** El usuario tiene permisos para ejecutar scripts de R y leer los datos originales en el servidor.

---

## 3. Gobernanza (Matriz RACI)
*   **Aprobador (A):** Analista Solicitante (Dueño de la metodología).
*   **Responsable (R):** Script de R "ObfuscatoR".
*   **Consultado (C):** Departamento de Seguridad de la Información / Auditoría.
*   **Informado (I):** IA Generativa (quien recibe los datos ofuscados).

---

## 4. Comportamientos Clave (El "Qué")
La solución debe procesar un `tibble` y aplicar reglas según el tipo de columna:

1.  **Identificadores (IDs):** Mapeo determinista. Un ID real `123` siempre se convierte en el ID ficticio `9990001` dentro de la misma sesión.
2.  **Fechas:** "Scramble" (permutación aleatoria) del vector de fechas completo. Se mantienen las fechas existentes pero se reasignan a filas distintas.
3.  **Variables Categóricas:** Reasignación aleatoria que preserve el conteo/frecuencia original (Ej: si hay 10 "Grandes Contribuyentes", el output tendrá 10, pero en filas distintas).
4.  **Importes y Números:** Mantener el rango `[min, max]` y la precisión decimal. Preservar el signo (positivo/negativo).
5.  **Integridad de NAs:** Todo valor `NA` original debe permanecer como `NA` en el output.

---

## 5. Especificación Ejecutable (Casos de Prueba)

### 5.1 Casos de Uso Óptimos (Fidelidad para la IA)
*   *Prueba de Join:* Unir dos tablas ofuscadas por ID debe dar el mismo número de matches que las reales.
*   *Prueba de Agrupación:* `group_by() %>% summarise()` debe arrojar la misma cantidad de filas resumen.
*   *Prueba de Tipos:* `sapply(df, class)` debe ser idéntico en ambos datasets.
*   *Prueba de Rango:* `range(monto_ofuscado)` debe ser aproximadamente igual al original.
*   *Prueba de Gráficos:* Un histograma de los datos ofuscados debe mostrar la misma distribución que el original.
*(Se incluyen los 20 casos definidos en la interacción previa).*

### 5.2 Casos Límite (Robustez y Seguridad)
*   *Dataset de 1 Fila:* El scramble de fechas no debe fallar, aunque no cambie el valor.
*   *Columnas 100% NAs:* No debe intentar calcular medias o rangos.
*   *IDs Alfanuméricos:* Debe manejar strings como "ID-2023-X" sin romperse.
*   *Valores Infinitos:* Manejo de `Inf` o `NaN` en columnas numéricas.
*   *Colisión de Hash:* Garantizar que dos IDs reales distintos nunca mapeen al mismo ID ficticio.
*(Se incluyen los 20 casos críticos definidos en la interacción previa).*

---

## 6. Artefactos de Salida y Evolución
1.  **Script R (`obfuscator.R`):** Función principal `obfuscate_dataset(df, config)`.
2.  **Diccionario de Mapeo Volátil:** Un objeto temporal (no guardado en disco) que asocia IDs reales con ficticios durante la sesión.
3.  **Documentación de Auditoría:** Un log simple que indique: "Dataset X ofuscado el [fecha] con éxito".

### Ciclo de Vida del Documento
Cualquier cambio en la lógica de ofuscación (ej. añadir un nuevo tipo de dato como Coordenadas GPS) requiere una actualización de este documento y la re-validación de los 40 casos de prueba antes de modificar el código.

---

# Anatomía de esta Especificación
*¿Por qué este documento es vital para tu éxito?*

1.  **La Visión Estratégica:** Al definir el "Problema Humano", nos aseguramos de que no estamos haciendo "tecnología por tecnología", sino resolviendo un bloqueo legal real.
2.  **Métricas (KPIs):** Al decir que el éxito es "0% diferencia estructural", le estamos dando a la IA de codificación un objetivo binario y claro. No hay ambigüedad.
3.  **Comportamientos Clave:** Al separar la lógica por tipos de datos (IDs, Fechas, Importes), permitimos que el código sea modular y fácil de auditar por tu departamento técnico.
4.  **Casos Límite (Edge Cases):** Esta es la sección más "ejecutable". Previene que el script falle un viernes a última hora cuando te encuentres con un `NA` inesperado o una tabla vacía.
5.  **Auditabilidad:** Al incluirla como un valor central, proteges tu carrera profesional. El documento demuestra que pensaste en la seguridad antes que en la conveniencia.

**¿Deseas que procedamos a generar un boceto del código en R basado estrictamente en esta especificación o prefieres ajustar algún detalle de los casos de prueba?**