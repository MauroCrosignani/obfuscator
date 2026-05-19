# Sistema Documental de ObfuscatoR

## Proposito

Esta carpeta organiza la documentacion del proyecto para tres usos complementarios:

1. dar continuidad al desarrollo del MVP sin depender de la memoria conversacional;
2. dejar trazabilidad defendible de decisiones, alternativas y verificaciones;
3. acumular desde cada fase los insumos necesarios para una futura presentacion tecnica en Quarto y revealJS.

## Estructura

- `01_especificaciones/`
  - especificaciones vigentes e historicas;
  - casos de uso, alcance y restricciones funcionales.
- `02_diseno/`
  - documentos de diseno de producto, arquitectura y decisiones de interfaz.
- `03_planes/`
  - planes de implementacion, pruebas manuales y secuencias de trabajo.
- `04_auditorias/`
  - auditorias de estado, contrastes metodologicos, premortems y revisiones criticas.
- `05_investigacion/`
  - investigacion normativa, benchmarking, productos comparados y deep research.
- `06_desarrollo/`
  - cierres de fase, notas de ejecucion, decisiones de implementacion y metodologia operativa.
  - backlog transversal de continuidad y documentacion.
- `07_presentacion/`
  - puntos de venta, mensajes clave, objeciones previsibles, evidencia de solidez y futuros materiales Quarto/revealJS.
- `99_archivo/`
  - materiales obsoletos, supersedidos o retenidos solo por trazabilidad.

## Regla de documentacion por fase

Cada fase o hito relevante del proyecto debe dejar, como minimo:

1. un cierre de fase;
2. un registro claro de decisiones tomadas;
3. las alternativas consideradas y el motivo de descarte;
4. evidencia de verificacion;
5. al menos un aporte a los insumos de presentacion tecnica.

## Convenciones editoriales

Cuando corresponda, cada documento deberia distinguir explicitamente:

- hecho;
- decision;
- justificacion;
- alternativa descartada;
- evidencia;
- riesgo o limitacion;
- siguiente paso.

## Documentos de referencia

- especificacion vigente:
  - [ESPECIFICACION_DE_REQUERIMIENTOS_v3.1.md](c:/Users/mcros/Documents/obfuscator/docs/01_especificaciones/ESPECIFICACION_DE_REQUERIMIENTOS_v3.1.md)
- plan vigente del MVP de liberacion controlada:
  - [2026-05-06-liberacion-segura-a-terceros-implementation-plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-06-liberacion-segura-a-terceros-implementation-plan.md)
- guia operativa vigente del helper de perfilado seguro para IA:
  - [2026-05-18_guia-operativa-profile_dataset_for_ai.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-18_guia-operativa-profile_dataset_for_ai.md)
- guia rapida de adopcion desde RStudio para ese helper:
  - [2026-05-19_guia-rapida-de-adopcion-de-resumen_de-desde-rstudio.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-19_guia-rapida-de-adopcion-de-resumen_de-desde-rstudio.md)
- diseno vigente de la interfaz amigable para ese helper:
  - [2026-05-18-diseno-de-resumen_de-como-interfaz-amigable-para-perfilado-ia.md](c:/Users/mcros/Documents/obfuscator/docs/02_diseno/2026-05-18-diseno-de-resumen_de-como-interfaz-amigable-para-perfilado-ia.md)
- diseno vigente de mejoras semanticas para ese helper:
  - [2026-05-19-diseno-de-mejoras-semanticas-para-resumen_de-y-profile_dataset_for_ai.md](c:/Users/mcros/Documents/obfuscator/docs/02_diseno/2026-05-19-diseno-de-mejoras-semanticas-para-resumen_de-y-profile_dataset_for_ai.md)
- plan vigente para implementar esa interfaz amigable:
  - [2026-05-18-resumen_de-como-interfaz-amigable-para-perfilado-ia-implementation-plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-18-resumen_de-como-interfaz-amigable-para-perfilado-ia-implementation-plan.md)
- cierre vigente del bloque de resolvedor de fuente y metadata para perfilado IA:
  - [2026-05-18_cierre_del_bloque_resolvedor_de_fuente_y_metadata_para_perfilado_ia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-18_cierre_del_bloque_resolvedor_de_fuente_y_metadata_para_perfilado_ia.md)
- plan vigente de pruebas manuales:
  - [manual_testing_plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/manual_testing_plan.md)
- diseno principal:
  - [2026-05-06-liberacion-segura-a-terceros-design.md](c:/Users/mcros/Documents/obfuscator/docs/02_diseno/2026-05-06-liberacion-segura-a-terceros-design.md)

## Mantenimiento

Si aparece documentacion nueva en la raiz del repositorio o en carpetas temporales:

1. clasificarla por tipo de artefacto;
2. moverla a la familia adecuada;
3. actualizar este indice si cambia la navegacion general;
4. registrar el cambio en un cierre de fase o nota de desarrollo cuando afecte continuidad.
