# Spec: Studio 2.0 Premium Experience

**Fecha:** 2026-03-19  
**Estado:** En revisión  

## 1. Problema
La interfaz actual, aunque funcional y moderna, carece de elementos de "Studio de alto rendimiento":
- No hay modo oscuro (esencial para analistas de datos).
- El feedback de privacidad es textual/auditado, no visual en tiempo real.
- La distinción entre tipos de variables en el board es puramente por nombre.
- El diseño no se siente "vivo" (falta de micro-animaciones).

## 2. Solución Propuesta (Studio 2.0)
Transformar el ObfuscatoR Studio en un entorno premium mediante una arquitectura de componentes reactivos y un sistema de diseño persistente.

## 3. Arquitectura y Componentes

### 3.1 `ThemeManager` (JS + CSS Variables)
- **Persistencia**: Uso de `localStorage.getItem('obfuscator-theme')`.
- **Implementación**:
  - Un botón toggle en el header (Icons: `sun`/`moon`).
  - Al cambiar, se añade/elimina la clase `.dark-theme` al `<body>`.
  - Definición de tokens de diseño en `:root` (Light) y `body.dark-theme` (Dark).

### 3.2 `PrivacyScoreEngine` (R + Shiny Reactivity)
- **Cálculo**: El score de privacidad se calculará dinámicamente:
  - Base: 0.
  - +25 por cada variable `id` ofuscada.
  - +15 por cada variable `categorical` con jerarquía.
  - Multiplicador basado en `input$k_value` (k=2: x1.0, k=5: x1.5, k=10: x2.0).
- **UI**: Un componente `gauge` o barra circular en la sidebar.

### 3.3 `GlassSystem 2.0` (CSS)
- Evolución del glassmorphism actual:
  - `backdrop-filter: blur(16px)`.
  - Bordes `1px` con degradado sutil (`linear-gradient`).
  - Sombras `box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.15)`.

### 3.4 `TypeIdentityBadges` (R)
- En `render_role_zone_ui`, cada tarjeta de variable incluirá un badge minimalista:
  - Numeric: `#` (Gold)
  - String/Char: `A` (Cyan)
  - Date: `◷` (Blue)

## 4. Accesibilidad (W3C AA)
- El modo oscuro debe mantener un ratio de contraste de al menos 4.5:1 para todo el texto.
- Los botones de acción deben tener un estado `focus-visible` claro.

## 5. Roadmap de Implementación
1.  **Fundamentos**: CSS Variables y JS Theme Switcher.
2.  **Identidad**: Badges de tipo de dato en el Board.
3.  **Inteligencia Visual**: Lógica del Privacy Meter.
4.  **Refinamiento**: Animaciones de transición suave entre zonas.
