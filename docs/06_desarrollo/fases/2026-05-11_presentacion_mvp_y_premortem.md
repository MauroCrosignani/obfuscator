# 2026-05-11 - Premortem y presentacion del MVP

## Objetivo

Preparar una presentacion en Quarto y revealJS para exponer ObfuscatoR ante una docente y asistentes de un curso centrado en informes con metodologia CRISP-DM, cuidando especialmente:

- la utilidad practica de la herramienta;
- la honestidad sobre el estado actual del MVP;
- el encuadre metodologico;
- y la sensibilidad institucional del uso de IA con datos.

## Decisiones tomadas

### 1. Se corrio un premortem antes de disenar la presentacion

Motivo:

- evitar una presentacion que pareciera solo una demo tecnica;
- identificar objeciones probables;
- y corregir la narrativa antes de escribir las diapositivas.

Artefactos:

- [premortem-report-20260511-175339.html](c:/Users/mcros/Documents/obfuscator/premortem-report-20260511-175339.html)
- [premortem-transcript-20260511-175339.md](c:/Users/mcros/Documents/obfuscator/premortem-transcript-20260511-175339.md)

### 2. Se eligio una narrativa principal de utilidad institucional

En lugar de presentar primero la interfaz, la narrativa se reorganizo alrededor de:

1. problema institucional;
2. metodologia y especificacion viva;
3. estado real del MVP;
4. uso practico con IA;
5. limites y proximo camino.

### 3. Se adopto un tono explicitamente prudente

La presentacion deja claro que:

- es una iniciativa personal;
- no es una herramienta formalmente impulsada por la institucion;
- no promete anonimización perfecta;
- y no sustituye una evaluacion institucional futura.

## Implementacion realizada

Se crearon:

- [obfuscator-presentacion-curso.qmd](c:/Users/mcros/Documents/obfuscator/docs/07_presentacion/obfuscator-presentacion-curso.qmd)
- [obfuscator-presentacion-curso.css](c:/Users/mcros/Documents/obfuscator/docs/07_presentacion/obfuscator-presentacion-curso.css)

Se renderizo:

- [obfuscator-presentacion-curso.html](c:/Users/mcros/Documents/obfuscator/docs/07_presentacion/obfuscator-presentacion-curso.html)

Se generaron capturas reales del estado actual de la app en:

- [capturas](c:/Users/mcros/Documents/obfuscator/docs/07_presentacion/capturas)

## Verificacion

Se verifico que:

- Quarto estuviera disponible localmente;
- el `.qmd` renderizara correctamente a revealJS;
- existieran capturas reales del sistema funcionando;
- y la presentacion incluyera notas de orador con guion completo.

Comando ejecutado:

```powershell
quarto render docs/07_presentacion/obfuscator-presentacion-curso.qmd --to revealjs
```

Resultado esperado y observado:

- generacion correcta de `obfuscator-presentacion-curso.html`

## Limites conocidos

- Las capturas usadas corresponden al estado actual del MVP y a un dataset de ejemplo cargado automaticamente en el entorno de prueba.
- La presentacion no sustituye una futura revision institucional de seguridad de la informacion.
- Si antes de la exposicion cambia mucho la interfaz, convendra regenerar capturas.

## Impacto sobre la presentacion

Este paso deja listo un artefacto presentable para:

- exponer el MVP;
- defender su metodologia;
- y mostrar utilidad real sin sobreprometer madurez.

## Siguiente paso recomendado

- revisar una vez el HTML final en pantalla completa;
- ajustar solo detalles menores de redaccion o ritmo si hiciera falta;
- y preparar una version de apoyo con preguntas-respuesta breves para la ronda final.
