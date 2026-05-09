[PROMPT ORIGINAL]
Soy analista de datos y trabajo en un organismo estatal en el que no puedo usar los datos de mi trabajo con la IA. Cada vez que tengo que hacer una consulta a una IA tengo que poner datos ficticios para obtener una respuesta de la IA sin violar el secreto tributario. Trabajo con R bajo RStudio Server en un servidor con rocky linux. Quisiera tener una solución con R (que es un lenguaje que puedo auditar) que a partir de un tibble con datos confidenciales me permitiera generar otro tibble transformado donde los números identificadores (NRO_EMPRESA, NRO_CONTRIBUYENTE, NRO_CONT_TIT, PERSID, DOCUMENTO, etc.) pudieran ser ofuscados de alguna manera evidente (o sea... quiero que si luego se audita mi uso de la IA se pueda notar a simple vista que los números ya no son como los típicos... su rango es diferente, pero conservan el tipo de datos y permite que el código que pueda obtener a partir de ellos sea aplicable al tibble original. Quisiera que las fechas las transformara, pero que lo que hiciera fuera un scramble del total de fechas posibles, que los códigos posibles para una variable se mantuvieran, pero asignados a otras empresas, quisiera que se mantuvieran los conteos de cada estado para las variables categóricas, los rangos para las variables de importes y numéricas, el que las variables enteras sigan siendo enteras y las que tienen valores decimales también los presenten, que las que no tienen valor en ninguna celda permanezcan así, y cualquier otra cosa que se te ocurra que pueda ser útil para maximizar su utilidad al mismo tiempo que impidiendo que los datos puedan revelar datos secretos. Ofrece 20 casos de uso óptimos para considerar que hagan óptimo el resultado y 20 casos límites que prueben los límites de la solución.   


[RESPUESTA IA]
Excelente planteamiento. Has definido un problema crítico de "última milla" en el uso de IA en entornos gubernamentales: **la fricción entre la utilidad de la IA y la seguridad de los datos sensibles**. Tu enfoque de "ofuscación evidente" es brillante porque no solo protege el dato, sino que facilita la auditoría visual.

Como tu **Consejero Estratégico**, voy a integrar lo que me has dado y pasaremos a las siguientes fases para robustecer la especificación.

---

### **Paso 1: Síntesis de la Visión (Validación)**

*   **El Problema Humano:** La imposibilidad de usar IA con datos reales debido al secreto tributario obliga a los analistas a crear datos ficticios manualmente, lo cual es lento, propenso a errores y a menudo resulta en datos que no representan fielmente la estructura del problema original.
*   **Valores y Principios:**
    1.  **Audibilidad Radical:** La transformación debe ser obvia para un ojo humano (ej. IDs que empiezan por 999...).
    2.  **Paridad Estructural:** El código generado por la IA para los datos ofuscados debe funcionar en los datos reales sin cambios (misma clase de objetos, nombres de columnas y tipos de datos).
    3.  **Soberanía del Dato:** El proceso debe ser 100% local (R en Rocky Linux) sin llamadas a APIs externas para la transformación.
*   **KPIs:**
    1.  **Fidelidad de Ejecución:** El 100% del código de manipulación de datos (dplyr, tidyr) generado con datos ofuscados debe ejecutarse en los reales.
    2.  **Tiempo de Preparación:** Reducción del tiempo de "anonimización" de minutos/horas a segundos.
    3.  **Riesgo de Re-identificación:** Cero rastro de valores reales en campos clave.

---

### **Paso 2: Contexto y Límites (El "Terreno de Juego")**

Para avanzar, necesito que definamos las reglas del juego técnico:

1.  **Restricciones Técnicas:** Trabajamos en **RStudio Server sobre Rocky Linux**. ¿Hay restricciones de librerías? (Ej: "¿Solo podemos usar `base` y `tidyverse`?" o "¿Podemos usar paquetes de simulación como `charlatan` o `synthpop`?").
2.  **Restricción de Memoria:** ¿Hablamos de tibbles que caben cómodamente en RAM (ej: < 1GB) o debemos prever procesamiento por bloques para tablas masivas?
3.  **Supuestos Clave:**
    *   Asumimos que la IA no necesita los *valores exactos* de los importes para escribir el código, solo sus rangos y tipos.
    *   Asumimos que el usuario sabe identificar qué columnas son sensibles (NRO_EMPRESA) y cuáles no.

---

### **Paso 3: Alinear a los Humanos (Gobernanza y Comportamientos)**

Para que esta especificación sea "ejecutable" por un equipo o una IA, definamos responsabilidades y comportamientos:

1.  **Matriz RACI (Propuesta):**
    *   **Aprobador (Accountable):** Tú (Analista/Dueño del proceso).
    *   **Responsable (Responsible):** El script de R que desarrollaremos.
    *   **Consultado (Consulted):** Oficial de Seguridad de la Información (para validar que la ofuscación cumple la norma).
    *   **Informado (Informed):** Auditores del organismo.

2.  **Comportamientos Clave de la Solución:**
    *   **Mapeo Consistente:** Si el NRO_EMPRESA `123` aparece 10 veces, en el tibble ofuscado debe aparecer siempre como el mismo ID ficticio (ej. `9990001`) para mantener las relaciones de integridad referencial dentro del dataset.
    *   **Preservación de NAs:** Si una celda es `NA`, debe permanecer `NA`.
    *   **Scramble de Fechas:** Las fechas deben mezclarse pero mantenerse dentro del rango del dataset original para no romper lógicas estacionales o de series temporales.
    *   **Mantenimiento de Distribución:** Las variables categóricas (ej. "Estado: ACTIVO") deben mantener su frecuencia (si hay 80% activos, el output debe tener 80% de algo, aunque el nombre del estado cambie o se reasigne).

---

### **Paso 4: Priorizar la Entrega de Valor (MVP)**

El **MVP** consistirá en una función de R que reciba un tibble y una lista de "tipos de columnas" y devuelva el tibble transformado para los 3 tipos de datos más críticos: **Identificadores, Fechas e Importes**.

---

### **Paso 5: Hacer la Especificación Ejecutable (Casos de Prueba)**

Aquí es donde elevamos la calidad. Has solicitado 20 casos de uso óptimos y 20 casos límite. Vamos a definirlos para que la solución sea infalible.

#### **20 Casos de Uso Óptimos (Fidelidad de la IA)**
*Para que la IA genere código útil, la solución debe pasar estas pruebas:*
1.  **Join de Tablas:** Unir dos tibbles ofuscados por un ID ficticio (debe dar el mismo resultado que con IDs reales).
2.  **Agrupación y Resumen:** `group_by(CATEGORIA) %>% summarise(mean(MONTO))` debe devolver la misma estructura de tabla.
3.  **Series Temporales:** `floor_date(FECHA, "month")` debe funcionar sobre las fechas mezcladas.
4.  **Filtros de Rango:** `filter(MONTO > 1000)` debe retornar un número proporcional de filas similar al original.
5.  **Detección de Duplicados:** `distinct(ID_OFUSCADO)` debe arrojar el mismo conteo que el original.
6.  **Mutate Condicional:** `if_else(TIPO == "A", 1, 0)` debe ser aplicable.
7.  **Pivotaje:** `pivot_wider` basado en categorías ofuscadas.
8.  **Cálculo de Antigüedad:** Diferencia entre dos columnas de fechas (ej. FECHA_FIN - FECHA_INI).
9.  **Validación de Tipos:** `is.numeric()`, `is.character()`, `is.POSIXct()` deben retornar lo mismo.
10. **Ordenamiento:** `arrange(desc(MONTO))` debe mantener la jerarquía de los valores.
11. **Gráficos de Distribución:** Un `geom_histogram` de montos debe verse estructuralmente igual.
12. **Manejo de Outliers:** Los valores extremos deben seguir siendo extremos en la versión ofuscada.
13. **Filtros de Texto:** Búsqueda de patrones con `str_detect` en campos de texto anonimizados.
14. **Conteo de Nulos:** `sum(is.na(COL))` debe ser idéntico.
15. **Conversión de Unidades:** Dividir una columna de moneda por un tipo de cambio simulado.
16. **Rankings:** Uso de `dense_rank()` sobre IDs u otros valores numéricos.
17. **Concatenación:** Unir dos columnas de texto (ej. NOMBRE + APELLIDO) ofuscadas.
18. **Cálculo de Proporciones:** `n() / sum(n())` por grupo.
19. **Regresiones Simples:** Correlación entre dos variables numéricas preservada estructuralmente.
20. **Exportación:** El tibble resultante debe poder guardarse en `.csv` o `.xlsx` sin errores de encoding.

#### **20 Casos Límite (Robustez y Seguridad)**
*Situaciones donde la solución podría fallar o filtrar datos:*
1.  **Tibble Vacío:** ¿Qué pasa si el input no tiene filas?
2.  **Columnas con 100% NAs:** La función debe evitar errores al intentar calcular rangos.
3.  **IDs con Formato Alfanumérico:** (Ej: "A-123-B") ¿Cómo se ofuscan manteniendo el patrón?
4.  **Fechas en Formato Texto:** Detectar y avisar que no se mezclaron porque no son tipo `Date`.
5.  **Valores Cero o Negativos:** En importes, asegurar que el signo se mantenga si es relevante.
6.  **Columnas con Valor Único:** (Constantes) No deben causar error en el proceso de mezcla.
7.  **Datasets con 1 Sola Fila:** El "scramble" de fechas no tiene efecto; ¿se debe añadir un ruido aleatorio?
8.  **IDs Muy Largos (BigInt):** Asegurar que el ID ficticio no cause overflow.
9.  **Nombres de Columnas Sensibles:** Si el nombre de la columna es secreto (raro, pero posible), ¿se debe ofuscar?
10. **Columnas con Listas (List-columns):** Manejo de tibbles anidados.
11. **Codificación de Caracteres (UTF-8):** Asegurar que caracteres especiales no rompan la ofuscación.
12. **Diferentes Formatos de Fecha:** Mezcla de `Date` y `POSIXct` en el mismo dataset.
13. **Importes con Infinito o NaN:** Manejo de errores matemáticos pre-existentes.
14. **Variables Binarias (0/1):** Asegurar que no se transformen en otros números.
15. **Variables con Muy Pocas Categorías:** (Ej: Sexo M/F) El scramble puede no ser suficiente para anonimizar si se cruza con otros datos.
16. **Relaciones Lógicas entre Columnas:** (Ej: FECHA_NACIMIENTO debe ser menor a FECHA_DEFUNCION). El scramble aleatorio podría romper esto.
17. **Datasets Extremadamente Anchos:** (>1000 columnas) Rendimiento de la función.
18. **Campos de Texto Largo (Comentarios):** ¿Cómo ofuscar párrafos sin perder la estructura gramatical para análisis de texto?
19. **Preservación de Precisión Decimal:** Asegurar que valores de moneda no ganen o pierdan decimales inesperadamente.
20. **Colisión de IDs Ficticios:** Garantizar que el generador de IDs "999..." no asigne el mismo número a dos IDs reales distintos por azar.

---

### **Próximo Paso**

Para finalizar el **Paso 6 (Definir los Artefactos)** y generar el **Documento de Especificación de la Solución** final:

**¿Tienes alguna preferencia sobre cómo quieres que se generen los números ficticios?** (Ej: "Que siempre empiecen por 999", o "Que sean el hash del valor original pero convertido a entero").

Una vez me respondas, procederé a sintetizar todo en el documento final estructurado.