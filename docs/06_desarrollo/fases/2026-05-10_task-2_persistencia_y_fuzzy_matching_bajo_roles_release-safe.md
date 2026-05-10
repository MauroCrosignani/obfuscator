# Task 2 - Persistencia y fuzzy matching bajo roles release-safe

## Resumen

Se implemento la segunda task del plan de rediseño UX/UI de clasificacion `release-safe`.

Conclusion practica:
- las plantillas ya pueden persistir el modelo canonico de roles;
- la carga conserva compatibilidad con plantillas viejas;
- y el flujo actual de la app no queda roto mientras la UI principal todavia usa el modelo anterior.

## Objetivo del task

Preservar continuidad de uso durante la migracion de UX:

- guardar plantillas con roles canonicos nuevos;
- cargar plantillas nuevas y viejas;
- mantener fuzzy matching;
- y seguir excluyendo metadata restringida de release/review.

## Archivos modificados

- [R/obfuscator_core.R](c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R)
- [R/shiny_app.R](c:/Users/mcros/Documents/obfuscator/R/shiny_app.R)
- [test_persistence_release_flow.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_persistence_release_flow.R)

## Cambios realizados

### 1. Persistencia canónica

Las plantillas nuevas ahora pueden persistir roles en formato canonico:

- `id`
- `qi`
- `sens`
- `priv`
- `keep`
- `exc`

Esto ocurre desde [build_persistable_role_template()](c:/Users/mcros/Documents/obfuscator/R/shiny_app.R).

### 2. Compatibilidad hacia atras

La carga de plantillas en [load_roles_from_json()](c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R) ahora entiende dos mundos:

- plantillas nuevas en formato canonico;
- plantillas viejas en formato legacy.

La funcion devuelve:

- `canonical_exact`
- `exact`
- `suggested`

Eso permite:
- preservar el modelo nuevo como contrato;
- y seguir alimentando la UI vieja mientras no se implemente la tabla nueva.

### 3. Proyeccion conservadora al modelo viejo

Cuando una plantilla canonica guarda un rol `QI`, la carga lo reproyecta al modelo legado actual segun el tipo de la columna:

- fecha -> `date`
- numerica -> `numeric`
- otro caso -> `categorical`

Esta decision fue intencionalmente conservadora:
- no inventa una distincion que la UI vieja no puede representar;
- pero mantiene continuidad de uso y de pruebas.

### 4. Persistencia restringida sigue protegida

La tarea mantuvo fuera de las plantillas comunes:

- `numeric_offsets`
- `release_state`
- `manual_review`
- `artifact`

Con eso se conserva la frontera entre:
- clasificacion reutilizable por esquema;
- y artefactos restringidos de release/review.

## Casos de prueba cubiertos

En [test_persistence_release_flow.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_persistence_release_flow.R) quedaron cubiertos:

- guardado y carga de roles canonicos;
- compatibilidad hacia atras con plantillas viejas;
- preservacion de fuzzy matching para columnas renombradas;
- y exclusion de metadata restringida.

## Verificacion ejecutada

Comandos corridos:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_persistence_release_flow.R')"
Rscript tests/testthat.R
```

Resultados:

- `test_persistence_release_flow.R`: `PASS 43`
- suite completa: `PASS 250`

Nota:
- aparecio el warning de entorno `package 'testthat' was built under R version 4.2.3`, sin impacto funcional.

## Alternativas consideradas

### 1. Persistir solo el modelo nuevo y romper compatibilidad con el viejo

Motivo de descarte:
- demasiado agresivo para una migracion por fases;
- hubiera dejado sin continuidad a usuarios y pruebas del flujo actual.

### 2. Seguir persistiendo solo el modelo viejo

Motivo de descarte:
- posterga la migracion semantica;
- y deja la nueva UX sin un contrato persistible propio.

## Impacto sobre presentacion tecnica

Este task aporta un mensaje importante para tecnicos:

- el rediseño no sacrifica continuidad operativa;
- las plantillas no quedan atadas ciegamente a una sola version de la interfaz;
- y la migracion se esta haciendo con compatibilidad explicita, no por sustitucion brusca.

## Limites vigentes

- la reproyeccion `QI -> date/numeric/categorical` es un puente transitorio, no la forma final deseada;
- la UI principal todavia no consume directamente `canonical_exact`;
- el comportamiento fino de `QI` por subtipo seguira dependiendo de tareas posteriores del plan.

## Siguiente paso recomendado

Ejecutar la Task 3 del plan:

- introducir la tabla principal de clasificacion por variable;
- y empezar a mostrar visualmente el nuevo modelo de roles como experiencia dominante.
