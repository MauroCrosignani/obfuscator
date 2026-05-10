# Task 6 - Ayuda contextual y guia de flujo

## Resumen

Se implemento la sexta task del plan de rediseño UX/UI de clasificacion `release-safe`.

Conclusion practica:
- la interfaz ya no solo muestra roles y estados;
- ahora tambien explica que significan y como recorrer el flujo minimo de trabajo;
- y deja una base mucho mas defendible para pruebas manuales y presentacion tecnica.

## Objetivo del task

Introducir ayuda contextual minima pero util para:

- definiciones de roles `ID/QI/SENS/PRIV/KEEP/EXC`;
- una guia breve de trabajo release-safe;
- y apoyo visible sobre el papel de `k-anonymity`.

## Archivos modificados

- [R/shiny_app.R](c:/Users/mcros/Documents/obfuscator/R/shiny_app.R)
- [test_obfuscator.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_obfuscator.R)
- [manual_testing_plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/manual_testing_plan.md)
- [mensajes_clave_para_tecnicos.md](c:/Users/mcros/Documents/obfuscator/docs/07_presentacion/mensajes_clave_para_tecnicos.md)

## Cambios realizados

### 1. Definiciones minimas por rol

Se agregaron helpers puros para explicar cada rol principal:

- `release_safe_role_definition()`
- `release_safe_role_glossary()`

Estas definiciones ahora alimentan:

- tooltips en badges de rol;
- la ficha lateral;
- y la nueva guia breve visible en la app.

### 2. Guia breve de trabajo

Se agrego un bloque visible de ayuda con:

- rol de `k-anonymity` como piso formal;
- pasos minimos del flujo recomendado;
- glosario corto de roles principales.

La intencion fue reducir friccion conceptual sin introducir todavia un wizard completo.

### 3. Ayuda aplicada dentro de la ficha

La ficha lateral ahora explicita tambien la definicion del rol actual de la variable, no solo su nombre.

Eso mejora especialmente casos ambiguos como:

- `edad` como `QI`;
- `indicador_privado` como `SENS`;
- `observacion` como `PRIV`.

### 4. Actualizacion de la documentacion de prueba

Se ajusto el plan manual para reflejar que la UI ya ofrece una taxonomia visible minima y una guia de flujo, aunque la revision manual avanzada siga pendiente.

## Casos de prueba cubiertos

En [test_obfuscator.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_obfuscator.R) quedaron cubiertos:

- glosario release-safe con todos los roles oficiales;
- definiciones minimas con lenguaje interpretable;
- guia breve con:
  - `k-anonymity`
  - pasos de flujo
  - y roles principales.

## Verificacion ejecutada

Comandos corridos:

```powershell
Rscript -e "library(testthat); test_file('tests/testthat/test_obfuscator.R')"
Rscript tests/testthat.R
```

Resultados:

- `test_obfuscator.R`: `PASS 107`
- suite completa: `PASS 309`

Nota:
- aparecio el warning de entorno `package 'testthat' was built under R version 4.2.3`, sin impacto funcional.

## Alternativas consideradas

### 1. Esperar a un manual completo externo

Motivo de descarte:
- dejaba la UI muda frente a conceptos esenciales;
- y obligaba a probar el MVP con demasiada memoria del proyecto en la cabeza.

### 2. Implementar ya un wizard completo

Motivo de descarte:
- demasiado grande para esta fase;
- y no necesario para entregar ayuda inmediata y testeable.

## Impacto sobre presentacion tecnica

Este task mejora la defensa del producto ante tecnicos no autores:

- ya hay una forma visible de explicar el flujo;
- las definiciones basicas viven en la interfaz;
- y el producto deja de depender tanto de relato oral para ser entendido.

## Limites vigentes

- la ayuda sigue siendo breve y no reemplaza un flujo guiado de revision por alerta;
- `l-diversity` y `t-closeness` siguen fuera del MVP;
- la distincion entre ayuda contextual y accion operativa todavia puede madurar mas.

## Siguiente paso recomendado

Ejecutar la Task 7 del plan:

- conectar la clasificacion nueva con `k-anonymity`, preview y auditoria de forma mas directa;
- especialmente para `QI` numericos como `edad`.
