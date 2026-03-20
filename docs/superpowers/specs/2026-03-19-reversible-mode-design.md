# Spec: Modo Reversible (Keyed Offset)

**Fecha:** 2026-03-19  
**Estado:** Propuesto  

## 1. Problema
Se requiere que los identificadores numéricos enviados a clientes externos puedan ser revertidos a su valor original por personal autorizado (poseedores de una "Llave Maestra"), sin necesidad de almacenar archivos de mapeo adicionales y manteniendo un formato numérico.

## 2. Solución: Cifrado por Desplazamiento basado en Llave (Keyed Offset)
Utilizar un algoritmo determinista que genere un desplazamiento (offset) único para cada columna a partir de una clave secreta. 

### Algoritmo de Ofuscación
`Valor_Ofuscado = Valor_Original + Generar_Sal(Master_Key, Nombre_Columna)`

### Algoritmo de Reversión
`Valor_Original = Valor_Ofuscado - Generar_Sal(Master_Key, Nombre_Columna)`

## 3. Especificaciones Técnicas

### 3.1 Generación de Sal (`get_keyed_salt`)
Para garantizar que cada columna tenga un desplazamiento distinto incluso con la misma Llave Maestra:
1.  Concatenar `Master_Key` + `Nombre_Columna`.
2.  Calcular un hash (ej. SHA-256).
3.  Convertir los primeros 7-8 caracteres hexadecimales a un entero de gran tamaño (entre 10^7 y 10^9).
4.  Este entero es el `salt`.

### 3.2 Interfaz de Usuario (Studio)
-   **Toggle "Modo Reversible"**: En el panel de parámetros.
-   **Input Password**: Campo de contraseña "Llave Maestra" (con máscara de caracteres `***`).
-   **Visualización**: En el board, las variables en modo reversible tendrán un icono de "Candado" en lugar de la llave simple.

### 3.3 Utilidad de Reversión
Implementar la función `revert_obfuscator(data, master_key)` que automatice la resta de los salts detectando las columnas que fueron ofuscadas de esta manera.

## 4. Consideraciones de Seguridad
-   **No Persistencia de Llave**: La `Master_Key` **NUNCA** se guarda en el JSON de la plantilla ni en los logs.
-   **Seguridad por Algoritmo**: La seguridad depende totalmente de la robustez de la `Master_Key`. Si se pierde, los datos son irrecuperables por computación estándar.
-   **Colisiones**: Al usar un rango de 10^9 para el salt, la probabilidad de colisión en los IDs resultantes es extremadamente baja para 2M de registros.

## 5. Casos de Prueba
-   **Identidad**: `revertir(ofuscar(x, "123"), "123") == x`.
-   **Integridad**: Usar una llave diferente ("456") para revertir debe dar resultados erróneos (ruido).
-   **Volumen**: Probar con un vector de 2M de enteros para asegurar que el tiempo de ejecución sea < 1s.
