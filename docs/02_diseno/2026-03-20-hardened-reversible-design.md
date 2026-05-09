# Spec: Modo Reversible (Seguridad Reforzada)

**Fecha:** 2026-03-20  
**Estado:** Propuesto  

## 1. Problema
El usuario desea que el "Modo Reversible" para identificadores numéricos sea tratado con máxima confidencialidad:
- No informar al desarrollador (o sistema) de las claves usadas.
- No exportar las claves en el código R generado (para que el cliente externo no las vea).
- Permitir el ingreso manual por personal autorizado en el momento de la configuración.

## 2. Solución: Cifrado por Desfase con "Zero-Knowledge" Export
Aprovechar la infraestructura de "Numeric Offset" pero con protecciones de privacidad adicionales.

## 3. Especificaciones de seguridad Studio 2.0

### 3.1 Interfaz de Usuario (Modal de Cifrado)
-   **Campo Enmascarado**: Utilizar un input que permita ocultar el número una vez ingresado (similar a una contraseña).
-   **Etiqueta**: Cambiar "Offset" por "Clave de Cifrado Reversible".

### 3.2 Generación de Código R (Confidencialidad)
-   **Placeholders**: Al generar el código reproducible para el cliente, los valores de las llaves se reemplazarán por `[INGRESE_CLAVE_MAESTRA]`.
-   **Documentación**: El código incluirá un comentario instruyendo al cliente que necesita contactar al personal autorizado para obtener la clave de reversión si fuera necesario.

### 3.3 Auditoría y Logs
-   **Sin Rastros**: El log seguirá mostrando `***` para los offsets, asegurando que ni siquiera en los logs locales quede registro de los números específicos.

## 4. Flujo de Trabajo
1.  El analista marca la variable ID como numérica.
2.  Personal autorizado abre el modal (icono de llave/candado).
3.  Ingresa el número secreto.
4.  La vista previa se actualiza (Cifrado local).
5.  Se genera el código R para el cliente externo con las claves protegidas/omitidas.

---

### ¿Por qué este enfoque?
Cumple con la premisa de "No informar al sistema qué número es", ya que el número solo reside en la memoria volátil de la sesión actual y nunca se exporta en texto claro.
