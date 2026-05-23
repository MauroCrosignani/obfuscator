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
- diseno vigente para conservar en el render la estructura que hacia util a `glimpse()`:
  - [2026-05-19-diseno-de-render-que-preserva-la-estructura-de-glimpse-para-el-helper-ia.md](c:/Users/mcros/Documents/obfuscator/docs/02_diseno/2026-05-19-diseno-de-render-que-preserva-la-estructura-de-glimpse-para-el-helper-ia.md)
- diseno vigente de ajustes semanticos basados en prueba real del helper IA:
  - [2026-05-22-diseno-de-ajustes-semanticos-basados-en-prueba-real-del-helper-ia.md](c:/Users/mcros/Documents/obfuscator/docs/02_diseno/2026-05-22-diseno-de-ajustes-semanticos-basados-en-prueba-real-del-helper-ia.md)
- diseno vigente para numericas institucionales con evidencia y senales heuristicas:
  - [2026-05-22-diseno-de-evidencia-y-senales-heuristicas-para-numericas-institucionales.md](c:/Users/mcros/Documents/obfuscator/docs/02_diseno/2026-05-22-diseno-de-evidencia-y-senales-heuristicas-para-numericas-institucionales.md)
- diseno vigente de transicion hacia `contextoia` como paquete independiente:
  - [2026-05-22-diseno-de-transicion-hacia-contextoia-como-paquete-independiente.md](c:/Users/mcros/Documents/obfuscator/docs/02_diseno/2026-05-22-diseno-de-transicion-hacia-contextoia-como-paquete-independiente.md)
- plan vigente para implementar esa interfaz amigable:
  - [2026-05-18-resumen_de-como-interfaz-amigable-para-perfilado-ia-implementation-plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-18-resumen_de-como-interfaz-amigable-para-perfilado-ia-implementation-plan.md)
- plan vigente de mejoras semanticas para ese helper:
  - [2026-05-19-mejoras-semanticas-para-resumen_de-y-profile_dataset_for_ai-implementation-plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-19-mejoras-semanticas-para-resumen_de-y-profile_dataset_for_ai-implementation-plan.md)
- plan vigente para preservar la estructura de `glimpse()` en el render:
  - [2026-05-19-render-que-preserva-la-estructura-de-glimpse-para-el-helper-ia-implementation-plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-19-render-que-preserva-la-estructura-de-glimpse-para-el-helper-ia-implementation-plan.md)
- plan vigente de ajustes semanticos basados en prueba real del helper IA:
  - [2026-05-22-ajustes-semanticos-basados-en-prueba-real-del-helper-ia-implementation-plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-22-ajustes-semanticos-basados-en-prueba-real-del-helper-ia-implementation-plan.md)
- plan vigente para numericas institucionales con evidencia y senales heuristicas:
  - [2026-05-22-evidencia-y-senales-heuristicas-para-numericas-institucionales-implementation-plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-22-evidencia-y-senales-heuristicas-para-numericas-institucionales-implementation-plan.md)
- plan vigente de transicion hacia `contextoia` como paquete independiente:
  - [2026-05-22-transicion-hacia-contextoia-como-paquete-independiente-implementation-plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-22-transicion-hacia-contextoia-como-paquete-independiente-implementation-plan.md)
- cierre vigente de implementacion de esas mejoras semanticas:
  - [2026-05-19_mejoras_semanticas_para_el_helper_de_perfilado_ia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-19_mejoras_semanticas_para_el_helper_de_perfilado_ia.md)
- analisis critico vigente del render actual del helper IA:
  - [2026-05-19_analisis_critico_del_render_actual_del_helper_ia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-19_analisis_critico_del_render_actual_del_helper_ia.md)
- cierre vigente de diseno y plan para preservar la estructura de `glimpse()`:
  - [2026-05-19_diseno_y_plan_para_preservar_la_estructura_de_glimpse_en_el_helper_ia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-19_diseno_y_plan_para_preservar_la_estructura_de_glimpse_en_el_helper_ia.md)
- cierre vigente de implementacion del render que preserva estructura de `glimpse()`:
  - [2026-05-19_render_que_preserva_la_estructura_de_glimpse_para_el_helper_ia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-19_render_que_preserva_la_estructura_de_glimpse_para_el_helper_ia.md)
- cierre vigente de diseno y plan de ajustes semanticos basados en prueba real:
  - [2026-05-22_diseno_y_plan_de_ajustes_semanticos_basados_en_prueba_real_del_helper_ia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-22_diseno_y_plan_de_ajustes_semanticos_basados_en_prueba_real_del_helper_ia.md)
- cierre vigente de implementacion de esos ajustes semanticos basados en prueba real:
  - [2026-05-22_ajustes_semanticos_basados_en_prueba_real_del_helper_ia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-22_ajustes_semanticos_basados_en_prueba_real_del_helper_ia.md)
- cierre vigente de diseno y plan para numericas institucionales con evidencia y senales:
  - [2026-05-22_diseno_y_plan_para_numericas_institucionales_con_evidencia_y_senales.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-22_diseno_y_plan_para_numericas_institucionales_con_evidencia_y_senales.md)
- cierre vigente de implementacion para numericas institucionales con evidencia y senales:
  - [2026-05-22_numericas_institucionales_con_evidencia_y_senales.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-22_numericas_institucionales_con_evidencia_y_senales.md)
- cierre vigente de diseno y plan de transicion hacia `contextoia`:
  - [2026-05-22_diseno_y_plan_de_transicion_hacia_contextoia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-22_diseno_y_plan_de_transicion_hacia_contextoia.md)
- cierre vigente de implementacion de la compatibilidad transicional hacia `contextoia`:
  - [2026-05-22_transicion_hacia_contextoia_como_paquete_independiente.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-22_transicion_hacia_contextoia_como_paquete_independiente.md)
- mini auditoria vigente de fronteras estructurales hacia `contextoia`:
  - [2026-05-22-miniauditoria-de-fronteras-hacia-contextoia.md](c:/Users/mcros/Documents/obfuscator/docs/04_auditorias/2026-05-22-miniauditoria-de-fronteras-hacia-contextoia.md)
- cierre vigente del desacople inicial de utilidades del helper IA hacia `contextoia`:
  - [2026-05-22_desacople_inicial_de_utilidades_del_helper_ia_hacia_contextoia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-22_desacople_inicial_de_utilidades_del_helper_ia_hacia_contextoia.md)
- decision vigente de API publica en espanol para `contextoia`:
  - [2026-05-22_decision_de_api_publica_en_espanol_para_contextoia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-22_decision_de_api_publica_en_espanol_para_contextoia.md)
- evaluacion vigente de modularizacion interna del helper IA:
  - [2026-05-22-evaluacion-de-modularizacion-interna-del-helper-ia.md](c:/Users/mcros/Documents/obfuscator/docs/04_auditorias/2026-05-22-evaluacion-de-modularizacion-interna-del-helper-ia.md)
- cierre vigente de primera particion de utilidades del helper IA:
  - [2026-05-22_primera_particion_de_utilidades_del_helper_ia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-22_primera_particion_de_utilidades_del_helper_ia.md)
- cierre vigente de segunda particion de contexto de fuente del helper IA:
  - [2026-05-22_segunda_particion_contexto_de_fuente_del_helper_ia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-22_segunda_particion_contexto_de_fuente_del_helper_ia.md)
- cierre vigente de tercera particion de metadata externa del helper IA:
  - [2026-05-23_tercera_particion_metadata_externa_del_helper_ia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-23_tercera_particion_metadata_externa_del_helper_ia.md)
- cierre vigente de cuarta particion de inferencia y resumen por variable del helper IA:
  - [2026-05-23_cuarta_particion_inferencia_y_resumen_por_variable_del_helper_ia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-23_cuarta_particion_inferencia_y_resumen_por_variable_del_helper_ia.md)
- cierre post-merge vigente del PR #1 sobre helper IA y transicion hacia `contextoia`:
  - [2026-05-23_cierre_post_merge_pr1_contextoia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-23_cierre_post_merge_pr1_contextoia.md)
- ajuste vigente de dependencias de tests para CI:
  - [2026-05-19_alineacion_de_dependencias_de_tests_para_ci.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-19_alineacion_de_dependencias_de_tests_para_ci.md)
- cierre vigente del bloque de resolvedor de fuente y metadata para perfilado IA:
  - [2026-05-18_cierre_del_bloque_resolvedor_de_fuente_y_metadata_para_perfilado_ia.md](c:/Users/mcros/Documents/obfuscator/docs/06_desarrollo/fases/2026-05-18_cierre_del_bloque_resolvedor_de_fuente_y_metadata_para_perfilado_ia.md)
- plan vigente de pruebas manuales:
  - [manual_testing_plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/manual_testing_plan.md)
- diseno principal:
  - [2026-05-06-liberacion-segura-a-terceros-design.md](c:/Users/mcros/Documents/obfuscator/docs/02_diseno/2026-05-06-liberacion-segura-a-terceros-design.md)
- insumo comparativo vigente sobre ObfuscatoR frente a ARX:
  - [ventajas_obfuscator_frente_a_arx.md](c:/Users/mcros/Documents/obfuscator/docs/05_investigacion/ventajas_obfuscator_frente_a_arx.md)

## Mantenimiento

Si aparece documentacion nueva en la raiz del repositorio o en carpetas temporales:

1. clasificarla por tipo de artefacto;
2. moverla a la familia adecuada;
3. actualizar este indice si cambia la navegacion general;
4. registrar el cambio en un cierre de fase o nota de desarrollo cuando afecte continuidad.
