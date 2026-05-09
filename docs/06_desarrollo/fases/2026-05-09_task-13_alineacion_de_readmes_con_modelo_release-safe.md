# Task 13 - Alineacion de README(s) con el modelo release-safe

## Resumen ejecutivo

- fecha: 2026-05-09
- estado: completado en la rama principal de documentacion
- conclusion practica: la documentacion publica principal del repositorio deja de presentar a ObfuscatoR como una ayuda para compartir datos con IA y pasa a describirlo como una herramienta de liberacion segura a terceros, con bloqueo por defecto y advertencias explicitas sobre sus limites.

## Audiencia y proposito

Este documento registra el cierre de `Task 13` del plan de implementacion. Su objetivo es:

1. dejar trazabilidad del cambio narrativo en la documentacion publica;
2. evitar que los README sigan prometiendo una semantica mas laxa que la implementacion real;
3. capturar mensajes reutilizables para presentacion tecnica y revision institucional.

## Objetivo del task

Actualizar `README.md` y `README_gitlab.md` solo despues de que la conducta principal del producto ya existiera, para que la documentacion:

- describa primero la liberacion segura a terceros;
- trate a la IA como tercero;
- advierta que no todo dataset es liberable;
- y no confunda reproduccion programatica con aprobacion de liberacion externa.

## Artefactos modificados

- [README.md](c:/Users/mcros/Documents/obfuscator/README.md)
- [README_gitlab.md](c:/Users/mcros/Documents/obfuscator/README_gitlab.md)

## Decision tomada

Se eligio reescribir ambos README en lugar de hacer retoques parciales sobre el texto anterior.

La razon fue doble:

1. el mensaje previo seguia demasiado atado a "ofuscacion para IA";
2. los archivos arrastraban problemas de codificacion y terminologia que ya no convenia seguir parchando.

## Motivo de la eleccion

La reescritura completa permitio:

- dejar una narrativa limpia y coherente con la especificacion v3.1;
- explicitar limites y no-promesas del producto;
- alinear el README general con el README corporativo sin contradicciones semanticas.

## Alternativas consideradas

### Alternativa A: retoques minimos sobre los README existentes

Ventaja:
- menos trabajo inmediato.

Motivo de descarte:
- mantenia una base narrativa equivocada;
- no resolvia bien la codificacion heredada;
- dejaba mensajes mezclados entre "ofuscacion" y "liberacion segura".

### Alternativa B: esperar al final del MVP

Ventaja:
- evitaba tocar documentacion mientras la implementacion seguia moviendose.

Motivo de descarte:
- el repositorio ya necesitaba una descripcion mas fiel para revision tecnica;
- seguir con README desalineados aumentaba el riesgo de malinterpretacion.

### Alternativa C: reescritura sobria, basada en comportamiento ya implementado

Ventaja:
- mejor coherencia entre producto y discurso;
- menos sobrepromesa;
- mejor base para presentacion institucional.

Motivo de eleccion:
- fue la opcion mas defendible en esta etapa.

## Implementacion realizada

En `README.md` se reoriento la narrativa para destacar:

- liberacion segura a terceros;
- IA como tercero;
- exportacion bloqueada salvo estado `Liberable`;
- distincion entre uso interno y salida externa;
- limites del producto y no-promesas explicitas.

En `README_gitlab.md` se reforzo ademas:

- el caracter corporate-safe del despliegue;
- la necesidad de operar con assets locales;
- el uso del flujo de auditoria como evidencia cuando la salida se bloquea.

## Verificacion ejecutada

Verificacion realizada:

- lectura manual completa de [README.md](c:/Users/mcros/Documents/obfuscator/README.md)
- lectura manual completa de [README_gitlab.md](c:/Users/mcros/Documents/obfuscator/README_gitlab.md)
- contraste con la especificacion vigente [ESPECIFICACION_DE_REQUERIMIENTOS_v3.1.md](c:/Users/mcros/Documents/obfuscator/docs/01_especificaciones/ESPECIFICACION_DE_REQUERIMIENTOS_v3.1.md)

No se corrieron tests automatizados, porque este task fue documental.

## Riesgos y limites conocidos

1. Los README ya no sobreprometen, pero todavia no reemplazan una futura documentacion funcional mas extensa para usuarios finales.
2. La narrativa publica ya esta mejor alineada, pero debera revisarse otra vez cuando se complete el MVP y se defina la presentacion final en Quarto/revealJS.

## Lo que este paso permite concluir

- el repositorio principal ya describe el producto de forma coherente con el modelo release-safe;
- disminuye el riesgo de que un lector externo crea que ObfuscatoR es solo una utilidad para "mandar datos a IA";
- README general y README corporativo quedaron semantica y metodologicamente mas cerca entre si.

## Lo que este paso no permite concluir

- no implica que toda la documentacion secundaria del proyecto ya este alineada;
- no reemplaza la futura presentacion tecnica ni la documentacion de uso institucional;
- no convierte a los README en especificacion normativa.

## Impacto sobre presentacion tecnica

### Valor creado

El discurso publico del proyecto ya acompana la decision conceptual central: privacidad y liberacion segura primero, utilidad analitica despues.

### Riesgo evitado

Se evita una objecion muy probable: que el propio README del repositorio sugiera una postura mas laxa que la implementacion real.

### Explicacion simple para terceros tecnicos

> El producto ya no se presenta como una ayuda para pasar datos a IA, sino como una herramienta para decidir si un dataset puede compartirse con terceros y para bloquearlo cuando no puede defenderse esa salida.

## Siguiente paso recomendado

Continuar con el backlog de documentacion retrospectiva de tasks ya estables y, mas adelante, preparar la narrativa de demo en Quarto a partir de `docs/07_presentacion/`.

## Trigger de actualizacion

Este documento deberia actualizarse o quedar referenciado por un paso posterior cuando:

- cambie materialmente el alcance funcional del MVP;
- se reescriba la documentacion publica para la presentacion final;
- aparezcan nuevos warnings o restricciones que deban ser visibles desde los README.
