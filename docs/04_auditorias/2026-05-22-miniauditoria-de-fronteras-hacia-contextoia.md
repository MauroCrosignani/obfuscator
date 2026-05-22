# Mini Auditoria de Fronteras hacia `contextoia`

## Fecha

2026-05-22

## Proposito

Este documento registra una mini auditoria estructural del helper de perfilado seguro para IA para responder una pregunta puntual: que tan cerca esta hoy de poder extraerse como paquete independiente `contextoia`, y que partes siguen siendo propias de ObfuscatoR o solo de compatibilidad transicional.

La conclusion practica es que el helper ya esta bastante aislado del flujo Shiny y del MVP principal, pero todavia conserva tres dependencias base heredadas de [obfuscator_core.R](c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R) y una exposicion publica incompleta para su futura API como paquete.

## Alcance

La auditoria cubre:

- [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R)
- [obfuscator_core.R](c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R)
- [release_decision_helpers.R](c:/Users/mcros/Documents/obfuscator/R/release_decision_helpers.R)
- [shiny_app.R](c:/Users/mcros/Documents/obfuscator/R/shiny_app.R)
- [NAMESPACE](c:/Users/mcros/Documents/obfuscator/NAMESPACE)
- [DESCRIPTION](c:/Users/mcros/Documents/obfuscator/DESCRIPTION)

No es una auditoria funcional ni de producto. No reevalua la calidad de las heuristicas del helper ni la UX de la app Shiny. Su foco es solo estructural.

## Hallazgos principales

### 1. El helper ya esta desacoplado del flujo Shiny

Hecho:

- [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R) no referencia `shiny` ni `run_obfuscator_app()`.
- La app vive en [shiny_app.R](c:/Users/mcros/Documents/obfuscator/R/shiny_app.R).

Interpretacion:

- Esto es una muy buena senal para la futura extraccion.
- El helper no depende estructuralmente de la interfaz grafica.

### 2. El helper todavia depende de tres utilidades base que hoy viven en `obfuscator_core.R`

Hecho:

- [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R) usa:
  - `%||%`
  - `normalize_release_safe_column_name()`
  - `release_safe_text_like_column()`
- Las tres viven hoy en [obfuscator_core.R](c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R).

Interpretacion:

- Este es el acoplamiento tecnico mas claro que todavia impide una extraccion casi mecanica a `contextoia`.
- No es un problema grande, pero si una frontera que conviene resolver de forma explicita.

Decision sugerida:

- mover estas utilidades a un archivo propio del futuro helper;
- o duplicarlas transitoriamente dentro del modulo `contextoia` antes de extraer.

Alternativa descartada:

- mantenerlas en `obfuscator_core.R` y hacer que `contextoia` dependa de ObfuscatoR.

Motivo de descarte:

- eso invertiria la relacion deseada y haria mas fragil la separacion futura.

### 3. `obfuscator_core.R` contiene un bridge transicional, no el corazon del helper

Hecho:

- [obfuscator_core.R](c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R) contiene:
  - el bootstrap `load_obfuscator_companion()`;
  - la logica de compatibilidad entre `source()` y `devtools::load_all()`;
  - y la carga de [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R).

Interpretacion:

- Esta pieza no deberia migrar como parte central de `contextoia`.
- Su rol es de compatibilidad transicional mientras el helper siga viviendo dentro de este repo.

Decision sugerida:

- tratar todo este bridge como codigo de transicion;
- documentarlo como tal;
- y no reforzar la idea de que `obfuscator_core.R` es el dueño permanente del helper.

### 4. La API futura de `contextoia` ya esta bastante clara, pero hoy no esta exportada completa

Hecho:

- La API conceptual ya definida para el futuro paquete es:
  - `resumen_de()`
  - `profile_dataset_for_ai()`
  - `render_dataset_profile_for_ai()`
- En [NAMESPACE](c:/Users/mcros/Documents/obfuscator/NAMESPACE) hoy solo esta exportado `resumen_de()` de ese frente.

Interpretacion:

- Esto no rompe el uso actual.
- Pero muestra que la superficie publica de `contextoia` aun no coincide del todo con la del repo actual.

Decision sugerida:

- mantener `resumen_de()` como puerta principal;
- y decidir en una etapa posterior si `profile_dataset_for_ai()` y `render_dataset_profile_for_ai()` deben exportarse tambien en ObfuscatoR o quedar solo como API del futuro paquete independiente.

### 5. El archivo del helper esta bien encaminado para ser modulo extraible

Hecho:

- [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R) concentra:
  - deteccion de fuente;
  - metadata por carpeta;
  - perfilado;
  - render;
  - y la interfaz amigable `resumen_de()`.

Interpretacion:

- Aunque el archivo es grande, tiene una cohesion bastante alta en torno al mismo subproblema.
- Esto facilita mucho una extraccion futura a `contextoia` frente a una situacion donde esa logica estuviera dispersa por toda la app.

Riesgo:

- si sigue creciendo sin modularizacion interna, podria volverse mas dificil de mantener aunque siga siendo extraible.

## Clasificacion estructural actual

### Listo o casi listo para `contextoia`

- [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R)
- API visible ya consolidada para usuarios:
  - `resumen_de()`
- API tecnica ya consolidada a nivel conceptual:
  - `profile_dataset_for_ai()`
  - `render_dataset_profile_for_ai()`

### Propio de ObfuscatoR y no del futuro helper

- [shiny_app.R](c:/Users/mcros/Documents/obfuscator/R/shiny_app.R)
- flujo de ofuscacion:
  - `obfuscate_dataset()`
  - `obfuscate_csv()`
  - `detect_column_roles()`
  - `revert_reversible_ids()`
- helpers de decision de liberacion:
  - [release_decision_helpers.R](c:/Users/mcros/Documents/obfuscator/R/release_decision_helpers.R)

### Compatibilidad transicional

- `load_obfuscator_companion()`
- `obfuscator_companion_loading_mode()`
- `obfuscator_is_namespace_context()`
- uso de `source("R/obfuscator_core.R")` como camino corto de adopcion

## Relevancia practica de la auditoria

Esta auditoria deja tres conclusiones practicas:

1. no conviene meter mas acoplamiento del helper a la app ni al core de ofuscacion;
2. la extraccion futura a `contextoia` es viable sin rediseño de producto;
3. el siguiente cuello de botella ya no es `load_all()`, sino separar o reubicar las utilidades compartidas minimas y decidir la API publica final.

## Evidencia usada

Se verifico:

- exports vigentes del namespace con:

```r
devtools::load_all(".")
sort(getNamespaceExports("ObfuscatoR"))
```

- referencias estructurales del helper con:

```powershell
rg -n "shiny|run_obfuscator_app|normalize_release_safe_column_name|release_safe_text_like_column" R\ai_dataset_profile.R
```

Resultado relevante:

- `resumen_de()` si esta exportada;
- `profile_dataset_for_ai()` y `render_dataset_profile_for_ai()` no lo estan;
- no hay referencias del helper a Shiny;
- si hay referencias a utilidades compartidas de [obfuscator_core.R](c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R).

## Que esta auditoria no permite concluir

No permite concluir:

- que `contextoia` ya este listo para separarse mañana sin mas trabajo;
- que la API tecnica final ya este cerrada al 100%;
- ni que la modularizacion interna de [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R) sea ya optima.

## Siguiente paso recomendado

Abrir una pasada corta de desacople tecnico con este orden:

1. mover o duplicar las utilidades compartidas minimas del helper fuera de la zona central de [obfuscator_core.R](c:/Users/mcros/Documents/obfuscator/R/obfuscator_core.R);
2. decidir si la API tecnica del futuro `contextoia` exportara tambien `profile_dataset_for_ai()` y `render_dataset_profile_for_ai()`;
3. evaluar si conviene partir [ai_dataset_profile.R](c:/Users/mcros/Documents/obfuscator/R/ai_dataset_profile.R) en submodulos antes de la extraccion real.
