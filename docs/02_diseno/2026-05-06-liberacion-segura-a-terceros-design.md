# Diseno: Reformulacion de ObfuscatoR como herramienta de liberacion segura a terceros
**Fecha:** 2026-05-06  
**Estado:** Documento de apoyo y handoff de decisiones, validado conversacionalmente

---

## 1. Motivacion
El proyecto habia evolucionado desde un caso de uso inicial muy fuerte: preparar datos para consultar a una IA sin exponer informacion protegida.

Esa motivacion fue util para arrancar, pero deja una ambiguedad peligrosa:
* puede sugerir que la utilidad para IA justifica flexibilizar la privacidad;
* puede empujar a una UI centrada en "ofuscar" sin gobernar realmente una decision de liberacion;
* y no representa bien otros escenarios de salida a terceros.

La reformulacion aprobada consiste en asumir que:
* la IA es un tercero mas;
* la prioridad absoluta es la no divulgacion defendible;
* la exportacion externa solo debe ocurrir cuando la app pueda sostener tecnicamente esa decision;
* y la existencia de artefactos internos de trabajo no equivale a liberacion.

---

## 2. Cambio de modelo
### Antes
La narrativa dominante del producto podia leerse como:
* transformar datos para que sigan siendo utiles para analisis y para IA;
* agregar opcionalmente `k-anonymity`.

### Ahora
La narrativa aprobada pasa a ser:
* preparar datasets para su liberacion segura a terceros;
* usar `k-anonymity` como piso formal minimo;
* sumar controles adicionales de riesgo;
* bloquear por defecto;
* y exigir evidencia auditable cuando haya revision humana.

---

## 3. Principios de diseno aprobados
1. La IA no recibe un estandar mas permisivo que otros terceros.
2. La utilidad analitica queda subordinada a la no divulgacion.
3. `k-anonymity` es obligatorio para liberacion a terceros, aunque siga siendo capacidad configurable del motor en otros contextos.
4. Cumplir `k` no es suficiente por si solo.
5. Deben evaluarse columnas de alto riesgo y combinaciones de columnas.
6. El texto libre debe bloquear por defecto salvo resolucion segura.
7. Si no existe resolucion segura defendible, no se libera.
8. La app no debe ofrecer "liberar igual bajo mi responsabilidad".
9. La revision manual debe ser verificable y dejar evidencia.
10. La UI futura debe tener un unico flujo principal y no paneles de parametros duplicados.
11. El producto inicial debe ser general y conservador, no sectorialmente omnipotente.

---

## 4. Implicancias funcionales
### 4.1 Sobre la exportacion
La exportacion deja de ser el resultado natural de una transformacion y pasa a ser una decision condicionada por controles.

Debe distinguirse entre:
* previsualizacion interna;
* dataset transformado de trabajo interno;
* y dataset exportable a terceros.

### 4.2 Sobre la UI
La UI debe dejar de parecer una consola tecnica de tuning y pasar a ser un flujo de:
* carga;
* clasificacion;
* deteccion de riesgo;
* tratamiento;
* reevaluacion;
* decision de liberacion;
* salida o informe.

### 4.3 Sobre el motor
El motor actual no necesita descartarse, pero si reencuadrarse:
* varias capacidades del core siguen siendo valiosas;
* algunas deben quedar subordinadas al contexto de liberacion;
* otras requieren una representacion mas fiel en la UI y en el codigo reproducible.

Las capacidades reversibles o internas no deben abrir un atajo hacia liberacion externa.

### 4.4 Sobre la documentacion
La especificacion maestra debe pasar a ser el contrato fuerte del producto.

Los demas documentos:
* auditorias;
* specs de features;
* README(s);
* planes;

deben alinearse a ella y no competir con ella.

---

## 5. Riesgos reconocidos
Esta reformulacion no elimina todos los riesgos.

Se reconocen especialmente:
* dominios con sensibilidad semantica alta que exceden heuristicas generales;
* columnas narrativas o de texto libre;
* rarezas que puedan ser inofensivas en un sector y gravisimas en otro;
* tension entre utilidad analitica y no divulgacion;
* sobrepromesa si el sistema afirma garantias universales que no puede sostener.

La estrategia aprobada para esto es:
* producto general conservador;
* bloqueo por defecto;
* informe de no liberacion cuando no haya salida defendible;
* posibilidad de especializaciones futuras por dominio, pero no en la primera fase.

---

## 6. Decisiones cerradas en esta etapa
Las siguientes decisiones quedaron validadas:
* el producto se reformula alrededor de la liberacion segura a terceros;
* la IA se trata como tercero;
* la exportacion queda bloqueada por defecto;
* `k-anonymity` es obligatorio para liberacion a terceros;
* la ausencia de resolucion segura genera informe y no exportacion;
* deben revisarse columnas y combinaciones;
* la revision del usuario debe exigir verificaciones activas;
* el texto libre se bloquea por defecto;
* la especificacion nueva debe ser detallada y conservar los elementos normativos utiles del material previo.

---

## 7. Salidas esperadas de la siguiente fase
La siguiente fase ya no deberia discutir proposito, sino implementar un plan concreto para:
1. limpiar la especificacion publica y de handoff;
2. unificar la UI en un unico panel coherente;
3. arreglar bugs de estado ya detectados;
4. modelar la decision de liberacion de punta a punta;
5. alinear el codigo reproducible con el estado real de la configuracion;
6. reducir la brecha entre core y UI.

---

## 8. Relacion con la planificacion futura
Este documento no es aun el plan de implementacion.

Su rol es:
* fijar el modelo funcional;
* preservar el contexto de decisiones;
* permitir que la siguiente conversacion arranque desde una base estable;
* y habilitar la escritura de un plan por fases sin volver a debatir principios ya cerrados.
