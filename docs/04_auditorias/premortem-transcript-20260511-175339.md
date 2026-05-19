# Premortem de Presentacion: ObfuscatoR, IA y liberacion controlada

**Timestamp:** 2026-05-11 17:53:39  
**Objeto del premortem:** presentacion para docente y asistentes de un curso sobre informes con metodologia CRISP-DM, enfocada en mostrar ObfuscatoR como herramienta util para usar IA institucional con datos ofuscados o liberados de forma controlada.  
**Audiencia principal:** docente del curso y asistentes que estan aprendiendo a construir informes metodologicamente solidos y utiles en la practica.  
**Stakeholders secundarios:** institucion, equipos que usan Copilot, algunos desarrolladores que usan Cursor, areas custodias de datos.  
**Criterio de exito inferido:** que la audiencia entienda el problema institucional, vea la relacion con CRISP-DM, perciba que la solucion tiene utilidad practica real hoy, comprenda honestamente sus limites del MVP y salga con una imagen de rigor metodologico, no de demo aislada.

## Marco del premortem

Premisa: estamos a seis meses de la presentacion. La presentacion fracaso. No logro convencer a la docente ni a la audiencia de que la herramienta fuera metodologicamente seria, util en la practica o bien alineada con el uso institucional de IA. Estamos mirando hacia atras para entender por que murio.

## Fallas crudas identificadas

1. La presentacion se percibio como una demo de producto y no como un caso serio de trabajo metodologico alineado con CRISP-DM.
2. Se sobreprometio el estado actual del MVP y la audiencia detecto rapidamente huecos entre el discurso y la herramienta real.
3. El puente entre normativa, riesgo institucional y uso concreto de IA quedo demasiado abstracto o juridico, sin bajar a decisiones operativas.
4. La historia del proyecto se volvio autorreferencial: mucha especificacion, backlog y cambios de diseno, pero poca claridad sobre para que le sirve manana a un usuario institucional.
5. La audiencia no entendio con precision cuando el resultado es liberable, cuando requiere revision manual y cuando debe bloquearse.
6. La presentacion no resolvio la pregunta central que la docente realmente hizo: como construir un informe y una herramienta que produzcan uso real, no acumulacion de informacion.
7. La demo visual se apoyo demasiado en capturas o en una corrida fragil y no logro mostrar un flujo de trabajo simple, creible y repetible.
8. El cierre no dejo una adopcion plausible: la audiencia vio una idea interesante, pero no un camino de uso institucional con Copilot o Cursor.

## Deep dives

### Falla 1: Se percibio como demo de producto y no como trabajo metodologico serio

**Historia de la falla**  
La presentacion abrio mostrando interfaz, roles de variables y pantallas del sistema antes de anclar el problema dentro de CRISP-DM. La docente y quienes estaban aprendiendo a hacer informes sintieron que se les estaba mostrando una solucion ya construida, pero no un ejemplo de como una metodologia rigurosa lleva a una herramienta util. A medida que avanzaron las diapositivas, la arquitectura, los cambios de UI y el estado del MVP ocuparon mas espacio que el problema, las decisiones metodologicas y la relacion entre investigacion, requerimientos, validacion y utilidad practica.

El efecto fue sutil pero demoledor: la audiencia no rechazo el proyecto, pero lo reclasifico mentalmente como "interesante desarrollo tecnico" en vez de "ejemplo defendible de trabajo metodologico aplicable". Eso vacio de fuerza pedagogica a la presentacion y la hizo menos valiosa para el curso.

**Supuesto subyacente**  
Suponias que, si el producto se ve interesante y riguroso, la audiencia inferiria por si sola la estructura metodologica que lo produjo.

**Senales tempranas**  
- En los primeros minutos aparecen preguntas como "si, pero cual fue el problema de negocio o institucional concreto?"  
- Tomas mas tiempo explicando pantallas que explicando decisiones de analisis, validacion y reformulacion del problema.

### Falla 2: Se sobreprometio el estado real del MVP

**Historia de la falla**  
La presentacion quiso ser convincente y, en ese intento, hablo de "liberacion controlada", "trazabilidad", "uso con IA" y "decision defendible" sin distinguir con suficiente precision entre lo que el MVP ya hace, lo que hace de modo heuristico y lo que sigue pendiente. Cuando aparecieron preguntas tecnicas sobre `l-diversity`, persistencia de auditoria, revision manual, plantillas o criterios formales mas alla de `k-anonymity`, el relato empezo a tambalear.

No hizo falta que alguien atacara el proyecto. Bastaron dos o tres preguntas honestas para que pareciera que el discurso iba por delante del software. La audiencia tolera un MVP incompleto; lo que no tolera bien es la sensacion de promesa inflada.

**Supuesto subyacente**  
Suponias que era mejor hablar en lenguaje fuerte de producto para dar mas confianza, aunque algunas capacidades todavia fueran parciales.

**Senales tempranas**  
- Necesidad frecuente de decir "eso esta en backlog" justo despues de haber hecho una afirmacion fuerte.  
- Sensacion de que los disclaimers aparecen tarde, como correccion, y no como parte del encuadre.

### Falla 3: El puente entre normativa, riesgo institucional y uso de IA quedo abstracto

**Historia de la falla**  
La presentacion dedico una parte a la normativa uruguaya y otra a la herramienta, pero no termino de unirlas mediante decisiones concretas de producto. La audiencia escucho principios correctos sobre reserva, terceros, IA y no divulgacion, pero no pudo ver con claridad que ciertas reglas del sistema existen justamente para responder a ese marco: por ejemplo, por que la exportacion se bloquea, por que `k-anonymity` es un piso y no una garantia, o por que texto libre y variables privadas requieren otra cautela.

El resultado fue una brecha extraña: la parte legal parecia teorica y la parte tecnica parecia aplicada, pero no se sentia la cadena causal entre ambas. Entonces la presentacion perdio fuerza institucional.

**Supuesto subyacente**  
Suponias que exponer normativa y luego exponer funcionalidad alcanzaba para que la audiencia viera por si sola la traduccion entre una y otra.

**Senales tempranas**  
- La audiencia toma notas de la normativa pero no la vuelve a mencionar cuando mira la herramienta.  
- Falta de frases del estilo "esta decision de diseno existe por este riesgo institucional concreto".

### Falla 4: La historia del proyecto se volvio autorreferencial

**Historia de la falla**  
En el afan de mostrar rigor, la presentacion entro en detalles sobre especificaciones versionadas, backlog, premortems, redisenos de UX y evolucion del documento maestro. Aunque todo eso era real y valioso, se corrio el riesgo de contar demasiado la historia interna de construccion y demasiado poco la historia externa de valor. La audiencia termino sabiendo que el proyecto estuvo bien pensado, pero no necesariamente que les resolvia un problema urgente.

La frase "la especificacion es un artefacto vivo" salio bien una vez, pero repetida o mal ubicada empezo a sonar a inestabilidad y cambio permanente en vez de aprendizaje disciplinado.

**Supuesto subyacente**  
Suponias que mostrar mucho proceso interno necesariamente aumentaria la confianza del publico.

**Senales tempranas**  
- Varias diapositivas hablan del proyecto mirandose a si mismo.  
- Se tarda mas en explicar como se penso que en explicar que permite hacer hoy.

### Falla 5: No quedo clara la logica de liberacion

**Historia de la falla**  
La audiencia vio estados como `Liberable`, `Bloqueado` y `Requiere revision manual`, pero no termino de entender bajo que reglas cae un dataset en cada uno. Cuando aparecieron casos de borde, como ausencia de QI, variables sensibles o privadas, o generalizacion extrema, el flujo conceptual no se sintio obvio. Algunas personas se quedaron con la impresion de que el sistema aplica reglas complejas pero opacas.

Eso es particularmente grave porque el corazon del producto no es "ofuscar", sino gobernar una decision de liberacion. Si esa decision no se entiende, se erosiona la confianza.

**Supuesto subyacente**  
Suponias que bastaba con mostrar la interfaz y el resumen de auditoria para que la logica de liberacion resultara intuitiva.

**Senales tempranas**  
- Preguntas del tipo "entonces cuando exactamente deja liberar?" o "por que este caso si y este no?"  
- Necesidad de explicaciones largas para cada captura.

### Falla 6: No resolvio la consigna pedagogica central del curso

**Historia de la falla**  
La docente pidio pensar en informes y herramientas utiles en la practica, no en acumulacion de informacion. Si la presentacion se iba demasiado a los detalles del sistema y no mostraba una cadena clara "problema -> investigacion -> requerimientos -> decisiones -> prototipo util -> validacion", podia decepcionar justo en el eje pedagogico que mas importaba.

La audiencia podia salir admirando el trabajo, pero sin entender como eso les ensena a construir mejores informes o mejores soluciones institucionales. En ese escenario, la presentacion falla como pieza didactica aunque tecnicamente sea buena.

**Supuesto subyacente**  
Suponias que el valor pedagogico de la experiencia era obvio por el solo hecho de haber trabajado metodologicamente.

**Senales tempranas**  
- La docente pregunta por la estructura del proceso y no tanto por la interfaz.  
- La audiencia comenta mas el software que el metodo.

### Falla 7: La demo visual no fue robusta ni clara

**Historia de la falla**  
La presentacion dependio demasiado de una corrida en vivo, de capturas no suficientemente guiadas o de estados de UI que exigen contexto previo para entenderse. Algunos detalles visuales, nombres de estados o diferencias entre preview y resultado real podian confundir. Si algo no cargaba, una plantilla reaplicada cambiaba el estado o una captura mostraba demasiada informacion a la vez, la narrativa perdia continuidad.

No hace falta un error fatal para que una demo muera. Basta con una experiencia visual ligeramente opaca para que el publico deje de seguir el hilo.

**Supuesto subyacente**  
Suponias que, como tu ya conoces el flujo, las capturas y pantallas iban a resultar suficientemente autoexplicativas para el resto.

**Senales tempranas**  
- Necesidad de decir "esto hay que imaginarlo" o "aca en realidad lo importante es..." mientras muestras una pantalla.  
- Varias capturas requieren mucha traduccion oral para ser entendidas.

### Falla 8: No dejo una via creible de adopcion

**Historia de la falla**  
La presentacion mostro una buena idea, pero no termino de responder: "muy bien, y entonces como se usaria esto realmente en la institucion con Copilot o Cursor?" Sin ese aterrizaje, el proyecto podia quedar como una pieza prometedora pero no como una herramienta con camino operativo. La audiencia necesita imaginar el dia despues: quien la usa, sobre que tipo de datos, para hacer que consulta, con que cautelas y con que beneficios.

Si eso no queda vivo, la herramienta no se percibe como puente entre datos e IA, sino como otra capa conceptual mas.

**Supuesto subyacente**  
Suponias que la utilidad institucional era implicita porque el problema original ya era real.

**Senales tempranas**  
- Falta una diapositiva o relato claro de "flujo de uso en la practica".  
- La presentacion termina sin una escena concreta de adopcion institucional.

## Sintesis

### La falla mas probable

La falla mas probable es la numero 1: que la presentacion se perciba como una demo de producto y no como un ejemplo metodologico serio alineado con CRISP-DM. Es la mas probable porque el proyecto tiene mucha riqueza tecnica y documental, y justamente por eso es facil contar primero lo construido en vez de la logica que lo justifica.

### La falla mas peligrosa

La falla mas peligrosa es la numero 2: sobreprometer el estado del MVP. La audiencia puede perdonar limitaciones, pero si percibe que el relato promete mas de lo que el software hace hoy, cae tanto la confianza metodologica como la confianza institucional.

### El supuesto oculto mas importante

El supuesto oculto mas grande es este: que la audiencia vera automaticamente la cadena entre investigacion, normativa, especificacion, UX/UI y prototipo si se le muestran suficientes piezas. En realidad, esa cadena hay que construirla activamente en la narrativa.

## Plan revisado

1. Abrir con el problema institucional y el caso de uso con IA, no con la interfaz.  
   Decir con claridad: "tenemos herramientas de IA utiles, pero no podemos darles contexto con datos reales sin una politica y una herramienta de liberacion controlada".

2. Enmarcar la presentacion explicitamente en CRISP-DM.  
   Mostrar que la evolucion de requerimientos, investigaciones y redisenos no es desorden, sino iteracion disciplinada sobre comprension del problema, comprension de datos, preparacion, evaluacion y despliegue potencial.

3. Tratar la especificacion viva como fortaleza metodologica, pero una sola vez y con precision.  
   Frase sugerida: "la especificacion es un artefacto vivo porque nuevas investigaciones y pruebas revelan riesgos y necesidades que obligan a refinar la solucion". No insistir mas de lo necesario.

4. Ser radicalmente honesto con el estado actual.  
   Decir que el MVP ya hace ciertas cosas hoy: `k-anonymity`, bloqueo de exportacion, clasificacion por variable, resumen de auditoria, casos de prueba, flujo de liberacion controlada. Y decir tambien lo que no hace aun: persistencia operativa de auditoria, modelos formales mas avanzados, flujo maduro de revision manual, modulo final de plantillas.

5. Mostrar un flujo de uso institucional concreto.  
   Ejemplo: area custodiante toma un dataset, clasifica variables, genera una salida controlada, verifica advertencias y luego usa esa salida para dar contexto a Copilot en una consulta concreta. Esto conecta producto con practica.

6. Usar pocas capturas, cada una con una pregunta clara.  
   No mostrar pantallas solo porque existen. Cada captura debe responder algo:
   - como se clasifica el riesgo;
   - como se bloquea una salida;
   - como se documenta una decision;
   - como quedaria un flujo de uso con IA.

7. Cerrar con una madurez realista.  
   "No es una solucion terminada para produccion plena, pero ya es un MVP util para mostrar como una ingenieria de requerimientos seria puede traducirse en una herramienta institucionalmente util."

## Checklist previo a la presentacion

1. Confirmar una narrativa de 4 actos:
   - problema institucional;
   - metodo de trabajo;
   - MVP actual;
   - uso practico y siguientes pasos.

2. Preparar una diapositiva de honestidad tecnica:
   - que hace hoy;
   - que no hace todavia;
   - por que igual es util.

3. Preparar un flujo concreto de uso con Copilot y datos liberados de forma controlada.

4. Elegir solo capturas que sean autoexplicativas o faciles de explicar en 20-30 segundos.

5. Preparar una respuesta corta a esta pregunta:
   - "por que esto es un informe metodologicamente serio y no solo una demo?"

## Entrevista posterior recomendada

Para optimizar la presentacion, las preguntas mas valiosas para el autor son:

1. Cual es exactamente el objetivo de evaluacion de la docente: metodologia, utilidad institucional, calidad del informe, o una mezcla con pesos distintos?
2. Cuanto tiempo real tienes para presentar y cuanto para preguntas?
3. Quieres posicionar esto mas como caso de estudio metodologico o mas como herramienta institucional?
4. Que grado de detalle legal conviene: marco general, articulos concretos, o solo implicancias de diseno?
5. Habra demo en vivo o solo capturas?
6. Que objecion tecnica o institucional te preocupa mas que te hagan?
7. Cual quieres que sea la idea mas recordada al final?
