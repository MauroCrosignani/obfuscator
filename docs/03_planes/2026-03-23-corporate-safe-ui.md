# Corporate-Safe UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Endurecer la app Shiny para uso corporativo eliminando dependencias operativas de CDN, agregando fallback de clipboard y preparando documentación orientada a GitLab sin alterar el motor de ofuscación.

**Architecture:** El cambio se concentra en la capa Studio: `R/shiny_app.R` deja de inyectar recursos remotos y pasa a depender solo de `www/`. `www/app.js` absorbe la lógica cliente necesaria para iconografía local, editor visual de jerarquías sin CDN y fallback de clipboard. La documentación se complementa con un `README_gitlab.md` y la especificación actualizada ya define los criterios de aceptación.

**Tech Stack:** R, Shiny, JavaScript vanilla, CSS, Markdown, testthat.

---

### Task 1: Congelar el alcance y preparar verificación base

**Files:**
- Modify: `ESPECIFICACION_DE_REQUERIMIENTOS_v2.0.md`
- Test: `tests/testthat.R`

- [ ] **Step 1: Confirmar la especificación vigente**

Revisar que el documento incluya:
- versión objetivo corporate-safe
- eliminación de CDN
- fallback de clipboard
- `README_gitlab.md`

- [ ] **Step 2: Ejecutar baseline de tests**

Run: `Rscript tests/testthat.R`
Expected: suite verde antes de tocar la UI

- [ ] **Step 3: Registrar baseline**

Anotar si hay fallos previos para no atribuirlos erróneamente a la migración corporate-safe.

### Task 2: Eliminar dependencias remotas del arranque de Shiny

**Files:**
- Modify: `R/shiny_app.R`
- Test: `R/shiny_app.R`

- [ ] **Step 1: Identificar recursos remotos**

Quitar del `head` de la app:
- CDN de Font Awesome
- CDN de SortableJS

- [ ] **Step 2: Mantener solo assets locales**

Dejar únicamente:
- `www/app.css`
- `www/app.js`
- cualquier asset adicional local necesario

- [ ] **Step 3: Reemplazar helpers dependientes de icon fonts**

Sustituir `tags$i(...)` y `shiny::icon(...)` por helpers o spans locales que no requieran fuentes remotas.

- [ ] **Step 4: Verificar parseo**

Run: `Rscript -e "parse(file='R/shiny_app.R')"`
Expected: parse exitoso

### Task 3: Resolver iconografía local y estados visuales

**Files:**
- Modify: `R/shiny_app.R`
- Modify: `www/app.css`
- Modify: `www/app.js`

- [ ] **Step 1: Diseñar un sistema local de iconografía**

Usar uno de estos caminos:
- caracteres Unicode
- `span` con siglas cortas
- combinación de texto y badge visual

- [ ] **Step 2: Reemplazar iconos del shell principal**

Cubrir al menos:
- tema
- ayuda
- privacidad
- parámetros
- distribución
- jerarquías
- offset reversible
- chips de hero
- botón de copiar código

- [ ] **Step 3: Ajustar estilos**

Actualizar CSS para que botones y badges sigan siendo legibles sin Font Awesome.

- [ ] **Step 4: Adaptar JavaScript de tema**

Cambiar la lógica que hoy modifica clases `fas fa-sun/fa-moon` para que trabaje con el nuevo sistema local.

### Task 4: Reemplazar SortableJS en el editor de jerarquías

**Files:**
- Modify: `www/app.js`
- Modify: `R/shiny_app.R`
- Modify: `www/app.css`

- [ ] **Step 1: Escribir el comportamiento objetivo**

El editor debe seguir permitiendo:
- arrastrar desde la lista fuente
- crear grupos
- mover elementos a grupos
- mantener reporte final a Shiny

- [ ] **Step 2: Implementar drag and drop local**

Reusar HTML5 Drag and Drop ya presente en la app donde sea posible y eliminar llamadas a `new Sortable(...)`.

- [ ] **Step 3: Ajustar inicialización del modal**

Cambiar `initHierarchySortable()` para que inicialice la solución local y no espere librerías externas.

- [ ] **Step 4: Revisar estados vacíos y grupos**

Confirmar que agregar grupos, soltar elementos y persistir estructura siga funcionando.

### Task 5: Endurecer copy-to-clipboard con fallback manual

**Files:**
- Modify: `www/app.js`
- Modify: `R/shiny_app.R`
- Modify: `www/app.css`

- [ ] **Step 1: Mantener intento de copia programática**

Seguir intentando `navigator.clipboard` cuando esté disponible.

- [ ] **Step 2: Agregar fallback no bloqueante**

Si falla:
- seleccionar el contenido automáticamente o
- mostrar una instrucción visible de copia manual

- [ ] **Step 3: Reflejar el estado en la UI**

Cambiar texto/estilo del botón o mostrar ayuda contextual para que el usuario entienda qué hacer.

- [ ] **Step 4: Verificar que no rompa el modal de código**

El usuario siempre debe poder obtener el script reproducible.

### Task 6: Preparar documentación GitLab

**Files:**
- Create: `README_gitlab.md`
- Modify: `README.md`

- [ ] **Step 1: Mantener `README.md` público estable**

No romper la variante GitHub salvo ajustes menores de consistencia.

- [ ] **Step 2: Crear `README_gitlab.md`**

Incluir:
- descripción del proyecto
- instrucciones de uso
- nota sobre assets locales / entorno corporativo
- badge adaptable a GitLab o placeholder local

- [ ] **Step 3: Alinear la documentación con la especificación**

Verificar que el README corporativo no prometa dependencias remotas para la UI principal.

### Task 7: Verificación final y preparación de commit

**Files:**
- Test: `tests/testthat.R`
- Test: `R/shiny_app.R`
- Test: `R/obfuscator_core.R`
- Test: `README_gitlab.md`

- [ ] **Step 1: Ejecutar tests**

Run: `Rscript tests/testthat.R`
Expected: PASS

- [ ] **Step 2: Verificar parseo de R**

Run: `Rscript -e "parse(file='R/shiny_app.R'); parse(file='R/obfuscator_core.R'); parse(file='pruebas_migracion_gitlab.R')"`
Expected: sin errores

- [ ] **Step 3: Revisar diff**

Run: `git diff -- R/shiny_app.R www/app.js www/app.css README.md README_gitlab.md ESPECIFICACION_DE_REQUERIMIENTOS_v2.0.md`
Expected: cambios acotados a corporate-safe

- [ ] **Step 4: Commit**

```bash
git add ESPECIFICACION_DE_REQUERIMIENTOS_v2.0.md R/shiny_app.R www/app.js www/app.css README.md README_gitlab.md docs/superpowers/plans/2026-03-23-corporate-safe-ui.md
git commit -m "feat: harden studio for corporate-safe deployment"
```
