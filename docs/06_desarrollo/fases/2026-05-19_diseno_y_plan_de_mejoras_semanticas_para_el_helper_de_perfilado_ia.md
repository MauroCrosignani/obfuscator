# Diseno y plan de mejoras semanticas para el helper de perfilado IA

## Resumen ejecutivo

En esta fase se cerro el frente de diseno y planificacion para mejorar la calidad semantica de `resumen_de()` y `profile_dataset_for_ai()` a partir de casos reales como `starwars`.

Conclusion practica:

- el problema quedo acotado en un diseno formal;
- el plan de implementacion ya quedo ordenado por oleadas y tareas;
- y el criterio de ejecucion quedo endurecido para no aceptar commits con tests rojos mezclados.

## Artefactos principales

- diseno formal:
  - [2026-05-19-diseno-de-mejoras-semanticas-para-resumen_de-y-profile_dataset_for_ai.md](c:/Users/mcros/Documents/obfuscator/docs/02_diseno/2026-05-19-diseno-de-mejoras-semanticas-para-resumen_de-y-profile_dataset_for_ai.md)
- plan de implementacion:
  - [2026-05-19-mejoras-semanticas-para-resumen_de-y-profile_dataset_for_ai-implementation-plan.md](c:/Users/mcros/Documents/obfuscator/docs/03_planes/2026-05-19-mejoras-semanticas-para-resumen_de-y-profile_dataset_for_ai-implementation-plan.md)
- notas de uso de subagentes:
  - [AGENT_EXECUTION_NOTES.md](c:/Users/mcros/Documents/obfuscator/docs/AGENT_EXECUTION_NOTES.md)

## Problema tratado

La evaluacion critica del helper mostro limitaciones concretas:

- categorias compuestas con render ambiguo;
- `character` nominales de alta cardinalidad que caian en `unknown`;
- `list-columns` con semantica pobre;
- falta de distincion entre `integer` y `double`;
- mezcla entre nombres de entidad y texto libre;
- y advertencias demasiado generales.

## Decision principal

Se aprobo una estrategia en dos oleadas:

1. primero resolver lo estructuralmente mas visible:
   - categorias compuestas;
   - alta cardinalidad nominal;
   - `list-columns`;
   - `integer` vs `double`.
2. despues refinar:
   - nombres de entidad vs texto libre;
   - advertencias mas precisas.

## Ajuste metodologico importante

Durante la revision del plan se detecto un riesgo de disciplina:

- la secuencia original permitia interpretar que se podia commitear despues de abrir tests nuevos en rojo.

Eso se corrigio explicitamente en el plan:

- los checkpoints con rojo quedan permitidos solo como estado local de TDD;
- y los commits requieren rerun explicito en verde del bloque nuevo y de la suite previa relevante.

## Alternativas descartadas

### 1. Parchar solo el renderer

Se descarto porque no mejoraba el modelo interno.

### 2. Resolver todo en una sola oleada

Se descarto porque mezclaba demasiadas heuristicas nuevas y volvia mas difusa la validacion.

### 3. Aceptar commits intermedios con rojo

Se descarto por riesgo de regresion y de branch inconsistente.

## Uso de subagentes

Se uso un subagente revisor de plan en varias rondas. El resultado fue util para detectar:

- mezcla indebida entre oleadas;
- ausencia de prueba negativa para sobreclasificacion de texto libre;
- y contradicciones operativas entre TDD y checkpoints de commit.

La trazabilidad de ese uso quedo asentada en:

- [AGENT_EXECUTION_NOTES.md](c:/Users/mcros/Documents/obfuscator/docs/AGENT_EXECUTION_NOTES.md)

## Verificacion realizada

No se ejecutaron tests de R porque esta fase fue de diseno y planificacion.

Si se verifico:

- existencia de los artefactos nuevo de diseno y plan;
- indexacion del frente en la documentacion;
- y consistencia de la secuencia del plan respecto de la regla de no commitear con rojo.

## Siguiente paso recomendado

Ejecutar el plan empezando por `Task 1`, con foco en:

1. contrato semantico en tests;
2. bloque nuevo filtrable;
3. y verificacion verde de la suite previa antes de cualquier commit.
