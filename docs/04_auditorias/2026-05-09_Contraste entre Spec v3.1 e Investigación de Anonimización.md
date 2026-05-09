# Contraste entre la Spec v3.1 y la investigación sobre anonimización

**Fecha:** 2026-05-09  
**Proyecto:** ObfuscatoR  
**Propósito del documento:** consolidar el contraste entre la especificación actual del producto y los dos documentos de investigación incorporados al repositorio, para orientar la siguiente fase de diseño, testing y endurecimiento metodológico.

## 1. Fuentes consideradas

Este contraste se apoya en:

- [ESPECIFICACION_DE_REQUERIMIENTOS_v3.1.md](c:/Users/mcros/Documents/obfuscator/ESPECIFICACION_DE_REQUERIMIENTOS_v3.1.md)
- [2026-05-08_Anonimización de Datos Públicos Uruguay.md](c:/Users/mcros/Documents/obfuscator/docs/2026-05-08_Anonimización%20de%20Datos%20Públicos%20Uruguay.md)
- [2026-05-08_Investigación sobre Anonimización de Datos.md](c:/Users/mcros/Documents/obfuscator/docs/2026-05-08_Investigación%20sobre%20Anonimización%20de%20Datos.md)

## 2. Diagnóstico general

La conclusión principal es positiva: la spec v3.1 ya quedó mucho más cerca del estándar conceptual correcto que la versión anterior del proyecto.

En particular, la investigación externa confirma como bien encaminadas estas decisiones ya tomadas:

- reformular el producto como herramienta de `liberación segura a terceros`;
- tratar a la IA como un tercero, sin régimen permisivo especial;
- bloquear la exportación por defecto;
- exigir `k-anonymity` como piso mínimo y no como adorno opcional;
- distinguir entre artefacto interno, artefacto de trabajo y dataset realmente liberable;
- exigir revisión humana auditable en vez de una aprobación superficial.

Sin embargo, la investigación también muestra con bastante claridad que la spec actual todavía tiene dos debilidades estructurales:

1. define bien el **modelo de decisión**, pero todavía no explicita lo suficiente el **modelo de validación técnica del riesgo residual**;
2. describe bien qué debería bloquear, pero todavía no convierte eso en una **estrategia de pruebas inspirada en estándares y herramientas maduras**.

En otras palabras: la spec ya está bastante bien como contrato de producto, pero todavía le falta subir de nivel como contrato de validación.

## 3. Lo que la investigación confirma

### 3.1 Confirmación fuerte del enfoque uruguayo

La investigación sobre Uruguay confirma algo muy importante para el posicionamiento del producto:

- el estándar relevante no es “quitar nombres”;
- es `disociación` entendida como proceso de reducción defendible del riesgo de identificación;
- y debe evaluarse contra la posibilidad de volver a una persona “determinada o determinable” con esfuerzo no desproporcionado.

Esto fortalece la orientación de la spec v3.1, porque:

- justifica el enfoque de riesgo residual;
- justifica que `k-anonymity` no sea suficiente por sí sola;
- y justifica el lenguaje de “liberable / no liberable” más que el lenguaje de simple “ofuscación”.

### 3.2 Confirmación del rol central de los quasi-identificadores

La investigación confirma que el problema real no está solo en los identificadores directos.

También está en:

- fechas;
- edad;
- sexo;
- ubicación;
- actividad;
- y combinaciones con fuentes externas.

Eso valida directamente:

- el detector multicapa planteado en la spec;
- la revisión de combinaciones de tamaño 1, 2 y 3;
- y la idea de tratar fechas y columnas raras como riesgosas por defecto.

### 3.3 Confirmación de la separación entre seudonimización y anonimización

La investigación uruguaya marca con fuerza que la seudonimización sigue siendo dato personal si existe posibilidad de reversión mediante información adicional.

Eso respalda de manera muy clara la decisión ya tomada en la spec:

- mappings reversibles;
- claves manuales;
- offsets reversibles;
- y artefactos que permitan reconstrucción

no deben considerarse datasets liberables a terceros.

Esta confirmación es especialmente importante porque ordena el tratamiento de:

- `project_key`;
- `numeric_offsets`;
- reportes internos;
- y logs o configuraciones con capacidad de reconstrucción.

## 4. Lo que la investigación agrega y hoy falta fortalecer

### 4.1 Falta una política más explícita de riesgo residual

La spec v3.1 ya dice que cumplir `k` no alcanza, pero todavía no define con suficiente precisión cómo se evalúa el riesgo residual después de alcanzar `k`.

La investigación externa sugiere reforzar explícitamente:

- ataques de homogeneidad dentro de clases de equivalencia;
- ataques por inferencia;
- ataques por vinculabilidad con fuentes externas;
- y pruebas orientadas al “intruso motivado”.

Mi conclusión es que el producto debería incorporar una capa metodológica más explícita de:

- `evaluación post-transformación`;
- `simulación de reidentificación plausible`;
- y `criterios de no liberación por riesgo residual` aun si la métrica base da verde.

### 4.2 Falta una separación más fuerte entre modelos de privacidad

Hoy la spec v3.1 pone a `k-anonymity` como piso mínimo, lo cual está bien para una primera fase general.

Pero la investigación muestra que, conceptualmente, el ecosistema serio no se agota en `k`.

Aparecen al menos:

- `l-diversity`;
- `t-closeness`;
- privacidad diferencial;
- datos sintéticos;
- y modelos de consulta segura en vez de liberación de microdatos.

Mi recomendación no es meter todo eso ahora en implementación. Sería demasiado.

Mi recomendación es más precisa:

- mantener `k-anonymity` como piso obligatorio de la primera fase;
- pero actualizar la documentación del producto para declarar explícitamente que ese piso no agota el estándar posible;
- y dejar abierta una línea de evolución formal hacia `l-diversity` y `t-closeness` para escenarios donde el atributo sensible dentro de la clase siga siendo demasiado homogéneo.

### 4.3 Falta una estrategia para texto libre basada en herramientas maduras

La spec actual acierta al bloquear texto libre por defecto.

La investigación adicional aporta una precisión importante:

- en productos serios para texto no estructurado, como Presidio, la validación se hace con métricas tipo `precision`, `recall` y `F-beta`;
- el problema no es solo “si parece sensible”, sino qué tasa de fuga deja el detector.

Esto no obliga a convertir a ObfuscatoR en un sistema NLP grande ahora mismo.

Pero sí sugiere dos decisiones:

1. mantener el bloqueo por defecto del texto libre como política correcta;
2. documentar que una futura capacidad de tratamiento de texto libre deberá evaluarse con métricas explícitas de detección, no solo con intuición.

### 4.4 Falta institucionalizar la idea de “atacante”

Uno de los aportes más valiosos de la investigación comparada es que varias referencias maduras no validan solo “propiedades del dataset”, sino escenarios de ataque.

Eso aparece en:

- NIST;
- UKAN;
- ARX;
- y el marco de intruso motivado.

Hoy la spec habla de combinaciones riesgosas, pero no formaliza todavía un pequeño catálogo de modelos de atacante.

Yo recomendaría agregar en la siguiente revisión conceptual algo como:

- `atacante con conocimiento local razonable`;
- `atacante con acceso a fuentes públicas`;
- `atacante con conocimiento parcial del sujeto`;
- `atacante que conoce pertenencia probable al dataset`.

Eso haría mucho más defendible la lógica de bloqueo, porque la discusión dejaría de ser puramente abstracta.

## 5. Qué decisiones actuales del proyecto quedan especialmente validadas

Estas decisiones deberían considerarse fuertes y bien apoyadas por la investigación:

- la exportación no debe habilitarse por aceptación liviana del usuario;
- la revisión humana debe ser activa, verificable y auditable;
- la UI debe gobernar una decisión de liberación, no solo una transformación;
- el producto debe diferenciar claramente artefactos internos de dataset liberable;
- la anonimización para IA no debe presentarse como régimen de menor exigencia;
- la política general inicial debe ser conservadora;
- y la solución debe poder producir informe de no liberación, no solo datasets exportables.

## 6. Qué ajustes conceptuales convendría introducir a la spec

### 6.1 Ajustes recomendados de prioridad alta

1. Agregar una subsección explícita sobre `riesgo residual post-k-anonymity`.
2. Introducir un lenguaje básico de `modelos de atacante plausibles`.
3. Explicitar que la seudonimización reversible no satisface por sí sola el estándar de liberación a terceros.
4. Declarar formalmente que la primera fase del producto implementa un `piso conservador general`, no el máximo estado del arte posible.

### 6.2 Ajustes recomendados de prioridad media

1. Incorporar una línea de evolución para:
   - `l-diversity`
   - `t-closeness`
   - datos sintéticos
   - privacidad diferencial o mecanismos de consulta segura
2. Agregar una política más detallada para campos no estructurados.
3. Describir mejor cuándo el producto debería recomendar no liberar microdatos y preferir otro modo de compartir información.

## 7. Qué pruebas concretas deberíamos incorporar o adaptar

Esta es, probablemente, la parte más valiosa de la investigación para la fase siguiente.

### 7.1 Pruebas mínimas nuevas de prioridad alta

1. **Pruebas de equivalence classes**
   - verificar tamaño mínimo de clases para los quasi-identificadores elegidos;
   - verificar bloqueo cuando hay clases menores a `k`.

2. **Pruebas de homogeneidad dentro de clases**
   - dataset que cumple `k`, pero donde el atributo sensible queda prácticamente determinado dentro de la clase;
   - el sistema debería bloquear o al menos no marcar automáticamente como liberable.

3. **Pruebas de singularidad combinatoria**
   - datasets donde ninguna columna sola es crítica, pero la combinación sí;
   - verificar que la app promueve el caso a bloqueo.

4. **Pruebas de granularidad temporal**
   - fechas exactas, agrupación por días, mes, trimestre o año;
   - verificar que el reanálisis cambia realmente el estado según la granularidad.

5. **Pruebas de separación de artefactos**
   - dataset interno transformado no equivale a dataset liberable;
   - persistencia de plantillas no debe arrastrar secretos o material reversible.

6. **Pruebas de bloqueo por texto libre**
   - campos narrativos deben bloquear mientras no exista tratamiento seguro soportado.

7. **Pruebas de gating de exportación**
   - ninguna exportación externa si el estado no es `Liberable`.

### 7.2 Pruebas metodológicas nuevas de prioridad media

1. **Prueba de intruso motivado**
   - no necesariamente automatizada al principio;
   - sí documentada como procedimiento manual reproducible.

2. **Pruebas de vinculabilidad con fuentes externas simuladas**
   - cruzar un dataset liberado contra una tabla pública simplificada o dataset auxiliar de prueba.

3. **Pruebas de utilidad post-transformación**
   - no solo que haya privacidad;
   - también que el dataset mantenga cierta operabilidad básica cuando la política lo permita.

4. **Pruebas de informe defendible**
   - validar que el informe de no liberación explique causa, evidencia y acciones necesarias para reevaluar.

### 7.3 Pruebas futuras, no necesariamente de la fase inmediata

1. benchmarks comparativos estilo ARX sobre pérdida de información;
2. evaluación formal de detectores de texto sensible con métricas `precision/recall`;
3. comparación entre microdatos transformados y datos sintéticos;
4. evaluación de riesgo frente a ataques de inferencia de membresía en escenarios de IA.

## 8. Recomendación de estrategia para la próxima fase

Mi recomendación es no intentar “absorber todo el estado del arte” en una sola iteración.

La secuencia más sana sería:

### Fase A. Endurecimiento de la especificación

Actualizar la spec v3.1 con:

- riesgo residual post-`k`;
- modelos básicos de atacante;
- aclaración formal entre seudonimización y liberación externa;
- y hoja de ruta explícita de modelos futuros.

### Fase B. Endurecimiento del plan de testing

Convertir estos hallazgos en:

- nuevos casos de prueba automatizados;
- nuevos casos de prueba manual/metodológica;
- y criterios de aceptación más duros para estado `Liberable`.

### Fase C. Revisión del alcance de implementación

Antes de meternos con features avanzadas, decidir:

- qué entra ya en el motor;
- qué queda como regla de bloqueo sin tratamiento automático;
- y qué queda documentado como evolución futura.

## 9. Conclusión final

La investigación no contradice la dirección tomada por ObfuscatoR. Más bien la fortalece.

La spec v3.1 ya está bastante bien orientada en su idea central: una herramienta de liberación segura a terceros, conservadora, auditable y con bloqueo por defecto.

Lo que la investigación agrega no es tanto un cambio de filosofía, sino una exigencia de madurez:

- pensar más explícitamente en atacantes;
- validar más explícitamente el riesgo residual;
- y construir una batería de pruebas inspirada en estándares y herramientas que ya existen.

La mejor lectura posible es esta:

- el proyecto ya corrigió su orientación conceptual;
- ahora le toca endurecer su metodología de validación.
