# Guía de Pruebas Manuales (UI/UX)

Sigue estos pasos para verificar las nuevas funcionalidades de ObfuscatoR Studio en tu entorno.

## 1. Lanzar la Aplicación
Ejecuta el archivo **`lanzar_obfuscator.bat`** (doble clic) o usa el siguiente comando en R:

```r
source("R/obfuscator_core.R")
source("R/shiny_app.R")
run_obfuscator_app()
```

## 2. Carga de Datos de Prueba
1.  En la App, selecciona **Fuente de datos**: "Entorno global".
2.  Busca **iris** en el menú desplegable y haz clic en **Cargar dataset**.

## 3. Panel de Distribución (Refinado)
1.  **Icono de Gráfico**: El icono ahora es gris por defecto y cambia a **amarillo** al pasar el mouse.
2.  **Lógica Categórica**: Si mueves una variable numérica (como `Sepal.Length`) a la zona de **Categoricas**, al hacer clic en el gráfico ahora verás un **Gráfico de Barras** (frecuencias) en lugar de un histograma, respetando el rol asignado.

## 4. Jerarquías k-anonymity y Feedback Visual
1.  Haz clic en el icono de **jerarquía** en la fila de `Species`.
2.  Agrupa "setosa" y "versicolor" en un nuevo grupo llamado "Variedades A" y haz clic en **Guardar Jerarquía**.
3.  **Indicador Visual**: Verás que el icono de la jeraquía ahora es de **color azul/índigo** y tiene un borde resaltado. Esto indica que la variable tiene una jerarquía activa.

## 5. Entendiendo los Resultados de k-anonymity
En el dataset `iris` (150 filas), cada especie tiene 50 registros.
-   **Si pones k=100**: Ninguna especie por sí sola cumple k=100. 
-   **Eliminar filas**: Verás 0 filas en la previsualización porque todas fallan el umbral k=100.
-   **Agrupar remanentes**: Verás el valor "REMANENTE" porque la clase no llega a 100.
-   **Conservar sin anonimizar**: Verás "OTROS" (o el valor original si la lógica de salida lo permite) indicando que no se pudo anonimizar pero se mantuvo por configuración.

*Nota: Para ver resultados con datos reales en iris, intenta con **k=20** o **k=50** después de agrupar especies.*

---

**Si este comportamiento y los nuevos indicadores visuales te parecen correctos, avísame para proceder con los commits finales.**
