# 2026-05-18 - Housekeeping documental y alineacion de referencias vigentes

## Resumen ejecutivo

Se realizo una pasada de housekeeping documental para reducir dispersion de artefactos, mejorar la navegacion de la documentacion y dejar una referencia operativa vigente del helper `profile_dataset_for_ai()`.

Conclusion practica:

- ya no quedan artefactos del premortem del 2026-05-11 sueltos en la raiz del repositorio;
- la documentacion principal ahora apunta a una guia operativa unica para el helper de perfilado seguro para IA;
- y el plan manual del MVP deja de usar `release-safe` como nombre operativo de la UI actual cuando habla del flujo vigente.

## Que se hizo

### 1. Reubicacion de artefactos documentales sueltos

Se movieron desde la raiz del repositorio a la familia correcta de auditorias:

- [premortem-report-20260511-175339.html](c:/Users/mcros/Documents/obfuscator/docs/04_auditorias/premortem-report-20260511-175339.html)
- [premortem-transcript-20260511-175339.md](c:/Users/mcros/Documents/obfuscator/docs/04_auditorias/premortem-transcript-20260511-175339.md)

Esto alinea el repositorio con la regla ya explicitada en [docs/README.md](c:/Users/mcros/Documents/obfuscator/docs/README.md): la documentacion de auditoria y premortem debe vivir bajo `docs/04_auditorias/`.

### 2. Creacion de una guia operativa vigente del helper de perfilado IA

Se agrego:

- [2026-05-18_guia-operativa-profile_dataset_for_ai.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-18_guia-operativa-profile_dataset_for_ai.md)

Su funcion es concentrar en un solo artefacto:

- la firma vigente de `profile_dataset_for_ai()`;
- la firma vigente de `render_dataset_profile_for_ai()`;
- parametros actuales;
- valores posibles de `tipo_fuente`;
- claves soportadas en `config`;
- comportamiento vigente de `archivo_fuente` y `metadata_dir`;
- y ejemplos de uso actualizables.

### 3. Alineacion de indices y documentos de entrada

Se actualizaron:

- [README.md](c:/Users/mcros/Documents/obfuscator/README.md)
- [docs/README.md](c:/Users/mcros/Documents/obfuscator/docs/README.md)

Objetivo:

- hacer visible que hoy conviven dos frentes practicos:
  - liberacion controlada en la app;
  - perfilado seguro para IA desde RStudio;
- y evitar que la navegacion principal quede atrasada respecto del estado actual del repositorio.

### 4. Correccion de referencias operativas desactualizadas

Se corrigieron referencias en:

- [manual_testing_plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/manual_testing_plan.md)
- [2026-05-11_presentacion_mvp_y_premortem.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-11_presentacion_mvp_y_premortem.md)
- [2026-05-18_cierre_del_bloque_resolvedor_de_fuente_y_metadata_para_perfilado_ia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-18_cierre_del_bloque_resolvedor_de_fuente_y_metadata_para_perfilado_ia.md)

Cambios principales:

- referencias al premortem del 2026-05-11 ahora apuntan a `docs/04_auditorias/`;
- la documentacion operativa actual evita seguir llamando `release-safe` al flujo visible actual cuando la interfaz ya habla de `liberacion controlada`;
- el cierre del bloque de perfilado IA ya nombra al helper por su nombre real implementado: `profile_dataset_for_ai()`.

## Alternativas consideradas

### 1. Reescribir toda la documentacion historica para eliminar `release-safe`

No se eligio.

Motivo:

- muchos documentos antiguos registran decisiones y fases historicas donde ese termino era correcto en su contexto;
- reescribirlos todos mezclaria housekeeping con reinterpretacion historica.

Decision:

- corregir primero los documentos que hoy funcionan como referencias operativas o de entrada;
- dejar los documentos historicos como trazabilidad, salvo que generen confusion practica adicional.

### 2. Mantener una guia de uso del helper repartida entre cierres de fase

No se eligio.

Motivo:

- los parametros y valores vigentes quedaban dispersos entre varios hitos;
- eso hacia mas dificil encontrar la interfaz actual sin releer varias notas.

Decision:

- crear una guia operativa unica y enlazarla desde los indices principales.

## Verificacion realizada

Se hicieron comprobaciones documentales y estructurales, no pruebas funcionales de codigo.

Chequeos realizados:

- confirmacion de que los artefactos del premortem ya no quedan en la raiz del repo;
- verificacion de enlaces actualizados al premortem reubicado;
- verificacion de que existe la nueva guia operativa del helper;
- busqueda de referencias operativas antiguas en los documentos corregidos.

Comandos o procedimientos usados:

- inventario de archivos en raiz y bajo `docs/`;
- busquedas con `rg` sobre rutas y terminos operativos;
- lectura en UTF-8 de los documentos modificados.

## Limitaciones y cautelas

- No se intento reescribir toda la documentacion historica del proyecto.
- Es esperable que permanezcan menciones a `release-safe` en documentos de diseño o cierres de fase antiguos cuando describen decisiones de ese momento.
- No se tocaron en este housekeeping los cambios manuales vigentes de la presentacion ni otros archivos locales ajenos al frente documental.

## Valor creado

Problema resuelto:

- habia documentacion suelta y referencias operativas repartidas o envejecidas.

Valor creado:

- ahora existe una ruta mas clara para encontrar:
  - la documentacion principal del proyecto;
  - la interfaz vigente del helper de perfilado IA;
  - y los artefactos de auditoria del premortem.

Riesgo evitado:

- seguir propagando rutas de archivos movidos o una descripcion parcial de parametros y valores soportados.

Explicacion simple para terceros:

> Se ordeno la documentacion para que el estado actual del proyecto sea encontrable y defendible sin depender de la memoria conversacional ni de leer varios hitos en paralelo.

## Siguiente paso recomendado

Quedan dos caminos razonables:

1. seguir con housekeeping de documentacion historica si aparece otro punto de confusion real;
2. o cambiar de foco a ergonomia del helper desde RStudio o a la futura biblioteca compartida de metadata por oficina o grupo.
