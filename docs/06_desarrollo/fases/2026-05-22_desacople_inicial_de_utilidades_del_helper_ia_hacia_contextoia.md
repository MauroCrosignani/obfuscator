# Desacople Inicial de Utilidades del Helper IA hacia `contextoia`

## Fecha

2026-05-22

## Objetivo del paso

Reducir el acoplamiento tecnico entre el helper de perfilado seguro para IA y el core principal de ObfuscatoR, como preparacion para una futura extraccion a un paquete independiente llamado `contextoia`.

Este paso responde directamente a la mini auditoria de fronteras:

- [2026-05-22-miniauditoria-de-fronteras-hacia-contextoia.md](c:/Users/mcros/Documents/obfuscator/docs/04_auditorias/2026-05-22-miniauditoria-de-fronteras-hacia-contextoia.md)

## Problema identificado

El helper [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R) no dependia de Shiny, pero si usaba utilidades del core principal:

- `normalize_release_safe_column_name()`
- `release_safe_text_like_column()`

Esas funciones pertenecen conceptualmente al flujo de ObfuscatoR y a la liberacion segura, no al futuro paquete `contextoia`. Mantener esa dependencia complicaria una extraccion limpia.

## Cambio implementado

Se agregaron utilidades propias del helper:

- `ai_profile_normalize_column_name()`
- `ai_profile_text_like_column()`

Y se reemplazaron las referencias internas del helper para que [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R) ya no dependa de esas funciones `release_safe_*`.

## Prueba agregada

Se agrego un contrato en [test_ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/tests/testthat/test_ai_dataset_profile.R) que carga [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R) en un entorno candidato a `contextoia`, donde existe solo el operador `%||%` pero no existen las utilidades `release_safe_*`.

La prueba falla si el helper vuelve a depender de:

- `normalize_release_safe_column_name()`
- `release_safe_text_like_column()`

## Verificacion

Se ejecuto:

```r
Rscript -e "library(testthat); test_file('tests/testthat/test_ai_dataset_profile.R')"
```

Resultado:

- `PASS 243`

Tambien se verifico que [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R) ya no contiene referencias a esas utilidades:

```powershell
rg -n "normalize_release_safe_column_name|release_safe_text_like_column" R\ai_dataset_profile.R
```

Resultado:

- sin coincidencias.

## Limitaciones

Este paso no completa la extraccion a `contextoia`.

Todavia queda pendiente decidir:

- si `%||%` se mantiene como utilidad comun minima o se reemplaza por una funcion propia del helper;
- si `profile_dataset_for_ai()` y `render_dataset_profile_for_ai()` deben exportarse en ObfuscatoR antes de la extraccion;
- si [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R) debe partirse en archivos internos mas pequeños antes de crear el paquete independiente.

## Siguiente paso sugerido

El siguiente paso razonable es decidir la API tecnica publica:

- mantener solo `resumen_de()` como funcion exportada de cara a usuarios;
- o exportar tambien `profile_dataset_for_ai()` y `render_dataset_profile_for_ai()` para usuarios tecnicos y para facilitar la futura transicion a `contextoia`.
