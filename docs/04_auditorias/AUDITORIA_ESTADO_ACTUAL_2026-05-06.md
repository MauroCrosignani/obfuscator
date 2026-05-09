# Auditoria del Estado Actual del Proyecto
**Fecha:** 2026-05-06  
**Objeto auditado:** especificacion, UI Shiny y coherencia con el motor de transformacion y privacidad

---

## 1. Objetivo de la auditoria
Esta auditoria consolida el estado actual del repositorio antes de una nueva fase de redisenio funcional y documental.

Su finalidad es:
* identificar desalineaciones entre especificacion, UI y motor;
* registrar bugs y ambiguedades relevantes;
* distinguir entre problemas de documentacion, problemas de modelado conceptual y problemas de implementacion;
* dejar una base de handoff para futuras fases del proyecto.

---

## 2. Dictamen general
El proyecto posee una base funcional valida, pero no describe hoy un unico modelo coherente de parametros y liberacion.

La situacion observada puede resumirse asi:
* existe un motor de transformacion y privacidad real con capacidades no triviales;
* existe una especificacion maestra util, pero mezclada con roadmap y notas de diseno;
* existe una UI que superpone capas historicas y expone decisiones ambiguas o duplicadas;
* el producto necesita reformularse como herramienta de liberacion segura a terceros y no como mero estudio de ofuscacion para IA.

---

## 3. Hallazgos sobre la documentacion
### 3.1 Especificacion maestra util pero parcialmente desactualizada
La fuente mas vigente hasta esta auditoria es `ESPECIFICACION_DE_REQUERIMIENTOS_v2.0.md`, aunque su encabezado interno se presenta como "Version 2.1" y mezcla estado actual con alcance futuro.

Impacto:
* cuesta saber si el documento describe producto vigente o version objetivo;
* dificulta usarlo como contrato unico de implementacion;
* alimenta ambiguedad funcional en la UI.

### 3.2 Mezcla de contrato, roadmap y notas de diseno
El repositorio contiene:
* una especificacion v1 historica;
* una v2.0/v2.1 mas rica;
* varios specs de `docs/superpowers/specs/` de distinta madurez;
* y README(s) que a veces presentan como vigentes capacidades aun no consolidadas.

Impacto:
* el lector puede interpretar features propuestas como si fueran comportamiento estable;
* se debilita la defendibilidad del producto frente a auditoria o handoff.

### 3.3 README con riesgo de sobrepromesa
La documentacion publica del repo presenta capacidades avanzadas del Studio y de reversibilidad de una forma mas afirmativa que la evidencia automatizada y el estado de la UI permiten sostener sin matices.

Impacto:
* riesgo de sobreventa funcional;
* dificultad para alinear expectativas de usuarios futuros;
* tension entre producto descrito y producto efectivamente gobernable.

---

## 4. Hallazgos sobre la UI actual
### 4.1 Duplicacion real del panel `Parametros`
La app renderiza dos paneles llamados `Parametros`, con semanticas parcialmente superpuestas.

No se trata solo de un problema cosmetico:
* existen controles duplicados;
* existen labels distintos para conceptos parecidos;
* existen defaults incompatibles;
* y existen `inputId` repetidos.

Impacto:
* estado ambiguo dentro de Shiny;
* riesgo de que el usuario crea configurar una cosa y el sistema termine leyendo otra;
* imposibilidad de sostener que la UI modela una sola decision funcional coherente.

### 4.2 Bug del nombre del dataset
El chip superior de `Dataset: ...` no tiene una fuente de verdad correctamente conectada al flujo de carga.

Consecuencia:
* el dataset puede cargarse correctamente;
* las filas y columnas pueden actualizarse;
* pero el nombre visible seguir en `Ninguno`.

### 4.3 Ambiguedad en `k-anonymity`
La UI actual mezcla:
* un `k` visible por defecto;
* otro `k` condicionado a activacion;
* defaults distintos;
* y un medidor de privacidad que sigue usando `k` incluso cuando el modelo formal no esta activado.

Consecuencia:
* la interfaz insinua una falsa continuidad entre "ofuscacion general" y "anonimizacion formal";
* el usuario puede creer que ya esta trabajando bajo `k-anonymity` cuando no es asi.

### 4.4 Ambiguedad en `project_key`
La misma nocion aparece una vez como "sal" con valor prellenado y otra como llave opcional vacia.

Consecuencia:
* no queda claro si es un parametro obligatorio, opcional, interno o de sincronizacion;
* la UI no representa bien la semantica real del motor.

### 4.5 Catalogos incompletos o contradictorios de `numeric_mode`
Los dos paneles de parametros ofrecen listas diferentes de modos numericos, y ninguna coincide plenamente con el soporte real del core.

Consecuencia:
* la UI subrepresenta capacidades del motor;
* y ademas lo hace de forma inconsistente.

---

## 5. Hallazgos sobre el motor y su representacion
### 5.1 El motor es mas potente que la UI
El core soporta:
* cuatro modos numericos base;
* modos numericos por columna;
* `k-anonymity` con mas semantica que la expuesta por la UI;
* offsets numericos;
* tratamiento de grupos de equivalencia para IDs;
* jerarquias mas ricas que las actualmente representadas visualmente.

La UI actual no refleja fielmente ese soporte.

### 5.2 La generacion de codigo no representa toda la configuracion real
El snippet de codigo reproducible que hoy produce la app no refleja una configuracion completa y defendible de `k-anonymity`.

Consecuencia:
* el usuario puede creer que el codigo generado equivale a lo configurado visualmente;
* pero puede faltar informacion relevante para reconstruir la decision real.

### 5.3 La ayuda contextual actual simplifica demasiado algunos conceptos
Hay mensajes de ayuda sobre fechas, offsets y otras capacidades que no distinguen con precision suficiente entre:
* transformacion util;
* seguridad efectiva;
* persistencia;
* y limites de la reconstruccion.

---

## 6. Hallazgos conceptuales
### 6.1 El producto venia formulado demasiado cerca del caso "usar IA"
Esa formulacion original fue util para iniciar el proyecto, pero ya no es suficientemente robusta como base de una herramienta institucional.

Problema:
* si la IA se piensa como caso especial, la tentacion natural es flexibilizar demasiado la salida;
* eso contradice el objetivo de una herramienta defendible de liberacion segura.

### 6.2 Falta una separacion tajante entre transformacion y decision de liberacion
La arquitectura conceptual del producto debe diferenciar:
* dataset transformado;
* dataset util para analisis;
* dataset formalmente evaluado;
* dataset liberable.

Mientras eso no este explicitado, la UI tiende a colapsar decisiones distintas en un mismo bloque de "Parametros".

### 6.3 La decision institucional correcta es bloqueo por defecto
Durante esta auditoria se valido que:
* la IA debe tratarse como tercero;
* la exportacion debe bloquearse por defecto;
* no debe existir una salida de "liberar igual bajo mi responsabilidad";
* y si no existe resolucion segura defendible, debe generarse un informe de no liberacion.

---

## 7. Conclusiones de auditoria
### 7.1 Sobre la especificacion
La especificacion anterior es `parcialmente desactualizada`.

Tiene un nucleo valioso, pero no sirve ya como contrato maestro limpio para la siguiente etapa.

### 7.2 Sobre la UI
La UI actual no debe tomarse como expresion legitima del modelo funcional futuro.

Debe considerarse:
* funcional en algunos flujos;
* util como base exploratoria;
* pero conceptualmente desalineada con el producto que ahora se desea construir.

### 7.3 Sobre el motor
El motor conserva valor y capacidades reales.

El problema central no es que el core sea insuficiente, sino que:
* la UI lo representa mal;
* la documentacion lo cuenta de forma desigual;
* y el producto no estaba reordenado alrededor de una decision de liberacion segura.

---

## 8. Recomendaciones para la siguiente fase
1. adoptar una nueva especificacion maestra con proposito reformulado;
2. separar con claridad transformacion, anonimización y liberacion;
3. redisenar la UI alrededor de un unico flujo principal;
4. bloquear exportacion por defecto;
5. introducir evaluacion de riesgo a nivel de columnas y combinaciones;
6. fortalecer revision manual con evidencia verificable;
7. actualizar README y demas documentos publicos una vez que la especificacion maestra quede aceptada;
8. recien despues escribir un plan de implementacion por fases.

---

## 9. Artefactos derivados
Esta auditoria se complementa con:
* `ESPECIFICACION_DE_REQUERIMIENTOS_v3.0.md`
* `docs/superpowers/specs/2026-05-06-liberacion-segura-a-terceros-design.md`

