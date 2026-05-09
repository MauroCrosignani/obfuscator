# **El Estándar de Anonimización en la Administración Pública Uruguaya: Marco Jurídico, Modelos Técnicos y Gobernanza de Datos en la Era de la Transparencia**

La República Oriental del Uruguay ha consolidado, a lo largo de las últimas dos décadas, un ecosistema normativo de vanguardia que busca equilibrar dos derechos fundamentales de rango constitucional: el derecho al acceso a la información pública y el derecho a la protección de los datos personales. Este equilibrio se manifiesta con particular intensidad cuando un órgano estatal es consultado por un ciudadano bajo el amparo de la Ley N° 18.381 de Derecho de Acceso a la Información Pública.1 En este escenario, el organismo se enfrenta al desafío técnico y legal de entregar la mayor cantidad de información posible para satisfacer el principio de transparencia, sin vulnerar la privacidad de los titulares de los datos que puedan estar contenidos en los registros administrativos.3

El estándar de anonimización que corresponde utilizar a un órgano estatal uruguayo no es una fórmula estática, sino un conjunto de procesos y criterios técnicos definidos primordialmente por la Unidad Reguladora y de Control de Datos Personales (URCDP) y la Agencia de Gobierno Electrónico y Sociedad de la Información y del Conocimiento (AGESIC). Estos procesos se agrupan bajo el concepto jurídico de disociación, el cual se define como el tratamiento de datos personales de manera que la información obtenida no pueda vincularse a una persona determinada o determinable.5

## **El Marco Normativo de Referencia: La Dualidad entre Acceso y Privacidad**

Para comprender el estándar de anonimización en Uruguay, es imperativo analizar la interacción entre las dos leyes pilares del sistema. La Ley N° 18.381 establece que toda información producida, obtenida o en posesión de cualquier organismo público, estatal o no estatal, se presume pública, salvo las excepciones de secreto, reserva o confidencialidad establecidas expresamente por ley.1 Por su parte, la Ley N° 18.331 de Protección de Datos Personales reconoce este derecho como inherente a la persona humana y establece que el tratamiento de datos personales es lícito solo cuando el titular presta su consentimiento o cuando se da bajo excepciones legales específicas, entre las que se encuentra la disociación.7

El punto de convergencia más crítico ocurre a través del Principio de Divisibilidad, consagrado en el artículo 14 de la Ley N° 18.381. Este principio dispone que, si un documento contiene información que debe ser entregada e información que debe denegarse por causa legal, el organismo no puede negar el acceso al documento completo, sino que debe dar acceso a la información pública eliminando o tachando únicamente la porción exceptuada.6 Es aquí donde la anonimización (o disociación técnica) se vuelve la herramienta indispensable para que el Estado cumpla con su deber de transparencia sin incurrir en responsabilidades administrativas o penales por la divulgación de datos confidenciales.2

| Ley | Objeto Principal | Concepto Clave para Anonimización |
| :---- | :---- | :---- |
| Ley N° 18.381 | Garantizar el derecho de acceso a la información pública. | Principio de Divisibilidad (Art. 14). |
| Ley N° 18.331 | Proteger los datos personales como derecho humano. | Disociación de datos (Art. 4, Lit. G). |
| Ley N° 19.355 | Presupuesto y modernización estatal. | Obligatoriedad de publicar Datos Abiertos (Art. 82). |
| Decreto 232/010 | Reglamentación de la Ley 18.381. | Procedimientos para transparencia activa y pasiva. |
| Decreto 414/009 | Reglamentación de la Ley 18.331. | Definiciones técnicas de tratamiento y seguridad. |

Fuentes: 1

## **Definiciones Técnicas y Conceptuales: Disociación, Anonimización y Seudonimización**

En la práctica administrativa uruguaya, existe a menudo una confusión terminológica entre disociación, anonimización y seudonimización. La normativa nacional, a través de la Guía de Criterios de Disociación de la URCDP y la Guía sobre Anonimización de AGESIC, establece distinciones precisas basadas en la reversibilidad y el riesgo de reidentificación.6

### **La Disociación como Género**

La disociación es el término legal utilizado por la Ley N° 18.331 para describir el resultado final: que el titular del dato ya no sea identificable.5 Técnicamente, esta se divide en dos subcategorías: la anonimización (irreversible) y la seudonimización (reversible mediante información adicional).10

### **El Estándar de la Anonimización Irreversible**

Para que un proceso de anonimización sea aceptado por los órganos de control uruguayos, este debe ser irreversible. La URCDP define la anonimización como un tratamiento que impide la identificación o que no hace identificable al titular, siendo un procedimiento definitivo que rompe el vínculo entre el dato y la persona física de manera permanente.14 El estándar técnico uruguayo no exige una imposibilidad matemática absoluta de reidentificación, sino que esta no sea posible mediante un "esfuerzo desproporcionado".6 Para evaluar este esfuerzo, se deben considerar factores como el coste, el tiempo y las tecnologías disponibles en el momento del tratamiento.6

### **La Seudonimización: Una Medida de Seguridad, no de Apertura**

La seudonimización reduce el vínculo de un conjunto de datos con la identidad original del interesado mediante la sustitución de identificadores por códigos o tokens, pero permite la atribución a un interesado específico si se recurre a información adicional mantenida por separado bajo medidas técnicas de seguridad.10 Es crucial notar que, para la normativa uruguaya y en línea con el RGPD europeo, los datos seudonimizados siguen siendo considerados datos personales y están sujetos a todas las obligaciones de la Ley N° 18.331.15 Por tanto, un organismo estatal no puede entregar datos meramente seudonimizados en respuesta a un pedido de acceso a la información pública, a menos que exista una base legal distinta que lo permita, ya que el riesgo de reidentificación permanece latente para quien posee la "llave" de los datos.15

## **El Protocolo de Actuación para Órganos Estatales**

El estándar uruguayo exige que el proceso de anonimización sea metódico y documentado. La AGESIC recomienda un protocolo de tres etapas fundamentales: pre-anonimización, anonimización propiamente dicha y control.6

### **Etapa 1: Pre-anonimización y Clasificación de Variables**

En esta fase, el organismo debe realizar un inventario exhaustivo de los atributos contenidos en la base de datos y clasificarlos según su grado de identificabilidad.6 Esta clasificación es vital para determinar qué técnica aplicar a cada columna:

1. **Identificadores Directos:** Atributos que permiten la identificación inequívoca e inmediata de un individuo, como la Cédula de Identidad, el nombre completo o el número de pasaporte. El estándar exige la remoción total de estos atributos en la fase inicial.6  
2. **Quasi-identificadores (QI):** Atributos que, aunque no identifican por sí solos, pueden permitir la reidentificación si se combinan entre sí o con fuentes externas de datos. Ejemplos críticos en Uruguay incluyen la fecha de nacimiento, el sexo, el departamento de residencia, el código postal o la ocupación.6  
3. **Atributos Sensibles o Confidenciales:** Contienen la información de valor que se desea analizar pero que conlleva un riesgo de afectación si se vincula al titular, como el diagnóstico de una enfermedad, el nivel salarial o la afiliación sindical.6  
4. **Atributos No Confidenciales:** Datos que no presentan riesgos significativos de privacidad.6

### **Etapa 2: Aplicación de Técnicas de Anonimización**

Una vez clasificados los datos, el organismo debe seleccionar la técnica o combinación de técnicas más apropiada para reducir el riesgo de reidentificación preservando la utilidad de la información.6 Estas se dividen principalmente en dos familias: aleatorización y generalización.10

### **Etapa 3: Control y Gestión de Riesgos**

El estándar de anonimización no termina con la aplicación del algoritmo. El organismo estatal debe realizar un análisis de riesgo residual para evaluar la probabilidad de que un atacante, utilizando técnicas de singularización, vinculabilidad o inferencia, pueda revertir el proceso.15 La URCDP enfatiza que este monitoreo debe ser permanente, especialmente ante la aparición de nuevas tecnologías o la publicación de nuevos conjuntos de datos abiertos que puedan servir para ataques de triangulación.12

## **Profundización en los Modelos de Privacidad: K, L, T y Privacidad Diferencial**

El estándar técnico uruguayo, alineado con las mejores prácticas internacionales, reconoce que la simple eliminación de nombres es insuficiente frente a los ataques modernos a la privacidad. Por ello, las guías de AGESIC y URCDP detallan modelos matemáticos de privacidad que los organismos deben aspirar a implementar.6

### **K-Anonymity (Anonimato K)**

El modelo de ![][image1]\-anonymity es la base del estándar para microdatos en Uruguay. Su objetivo primordial es combatir la singularización: asegurar que un registro no pueda distinguirse de otros en el mismo conjunto.6 Un conjunto de datos cumple con el anonimato ![][image1] si cada registro es idéntico a al menos ![][image2] otros registros respecto a sus quasi-identificadores.6

Para alcanzar el nivel ![][image1], los organismos suelen emplear dos métodos:

* **Supresión:** Se reemplazan valores de los quasi-identificadores por un asterisco o valor nulo si no se logra agruparlos.10  
* **Generalización:** Se disminuye el nivel de detalle de los valores. Por ejemplo, en lugar de registrar una edad de "34 años", se registra el rango "30-40".6

Aunque no existe un valor de ![][image1] único obligatorio por ley para todas las bases de datos, las guías ilustran el concepto con ![][image3] como base pedagógica, pero sugieren niveles superiores en función de la sensibilidad de los datos.11 La debilidad inherente del ![][image1]\-anonymity es que no protege contra ataques de inferencia si el atributo sensible es homogéneo dentro del grupo ![][image1].10

### **L-Diversity (Diversidad L)**

Para solventar las limitaciones del ![][image1]\-anonymity, el estándar uruguayo introduce el concepto de diversidad ![][image4]. Este modelo exige que en cada clase de equivalencia (el grupo de ![][image1] registros idénticos), existan al menos ![][image4] valores "bien representados" para el atributo sensible.6

*Implicancia práctica:* Si un organismo publica una tabla de pacientes anonimizada con ![][image5] para el departamento de Artigas, pero los 5 registros de ese grupo tienen el mismo diagnóstico (ej. "Listeria"), un atacante que sepa que un vecino de Artigas está en la tabla podrá inferir con total certeza que padece esa enfermedad, violando su privacidad a pesar del anonimato ![][image1].10 La diversidad ![][image4] obliga al organismo a asegurar que haya variedad en los diagnósticos dentro de cada grupo.

### **T-Closeness (Proximidad T)**

Como nivel de protección superior, se menciona la proximidad ![][image6]. Este modelo aborda el riesgo de que la distribución de un atributo sensible en una clase de equivalencia sea significativamente distinta a la distribución global del atributo en toda la base de datos.10 Esto previene ataques basados en el conocimiento de la prevalencia de una característica en subpoblaciones específicas.

### **Differential Privacy (Privacidad Diferencial)**

La AGESIC incorpora la privacidad diferencial como una técnica avanzada dentro de la familia de la aleatorización.6 A diferencia de los modelos anteriores que se basan en la manipulación de registros individuales (microdatos), la privacidad diferencial se enfoca en el resultado de las consultas estadísticas.15

Consiste en la inyección controlada de "ruido aleatorio" en el conjunto de datos o en los resultados de las consultas, de modo que sea matemáticamente imposible determinar si la información de un individuo específico fue incluida en el cálculo.10 La privacidad diferencial es el estándar de oro para la publicación de censos y grandes estadísticas nacionales, ya que ofrece una garantía de privacidad robusta frente a atacantes con poder computacional ilimitado y acceso a fuentes externas de información.15

## **Comparativa de Técnicas de Transformación de Datos**

| Técnica | Familia | Mecanismo | Nivel de Privacidad | Utilidad de Datos |
| :---- | :---- | :---- | :---- | :---- |
| **Supresión** | Reducción | Elimina registros u outliers identificables. | Alto (si se aplica bien) | Baja (pierde registros) |
| **Enmascaramiento** | Reducción | Oculta partes del dato (ej. C.I. 1.234.XXX-X). | Medio-Bajo | Media |
| **Generalización** | Generalización | Agrupa valores en categorías (ej. rangos de edad). | Medio-Alto | Media-Alta |
| **Adición de Ruido** | Aleatorización | Modifica valores numéricos levemente. | Alto | Media-Alta |
| **Permutación** | Aleatorización | Intercambia valores entre registros. | Alto | Baja para correlaciones |
| **Datos Sintéticos** | Generación | Crea datos nuevos basados en modelos estadísticos. | Muy Alto | Variable según el modelo |

Fuentes: 6

## **Enfoques Modernos: Synthetic Data y PETs en Uruguay**

El ecosistema digital uruguayo está transitando hacia la adopción de Tecnologías que Preservan la Privacidad (PETs, por sus siglas en inglés). El informe "Open Loop Uruguay 2024" destaca el potencial de los datos sintéticos como una alternativa disruptiva para el sector público.19

Los datos sintéticos no se obtienen de observaciones directas de personas reales, sino que se generan artificialmente mediante algoritmos de aprendizaje automático que replican las correlaciones y patrones del conjunto de datos original.18 Para un organismo estatal, los datos sintéticos representan una solución ideal en casos donde el riesgo de reidentificación es demasiado alto para usar técnicas tradicionales, como en el entrenamiento de modelos de Inteligencia Artificial en salud o seguridad pública.20 Al no haber un vínculo directo entre un registro sintético y un ciudadano real, estos datos pueden compartirse con mayor libertad para investigación y desarrollo, cumpliendo con el espíritu de la Ley 18.331.19

## **Herramientas de Implementación: El Ecosistema ARX**

AGESIC recomienda explícitamente el uso de herramientas de software especializadas para que los organismos no tengan que desarrollar sus propios algoritmos de anonimización desde cero. La herramienta de referencia es **ARX (Data Anonymization Tool)**.6

ARX es una solución de código abierto que permite a los equipos técnicos estatales:

1. **Modelado de Riesgo:** Calcular métricas de riesgo de reidentificación antes de publicar la base de datos.6  
2. **Configuración de Jerarquías:** Definir cómo se generalizan los datos (ej. de Ciudad a Departamento, de Fecha a Año).6  
3. **Análisis de Utilidad:** Evaluar cuánta precisión estadística se pierde al aplicar las técnicas de privacidad, permitiendo encontrar el punto de equilibrio óptimo.6  
4. **Soporte Multi-Modelo:** Aplicar simultáneamente ![][image1]\-anonymity, ![][image4]\-diversity, ![][image6]\-closeness y privacidad diferencial sobre un mismo conjunto de datos.6

Otras herramientas mencionadas en el ámbito técnico incluyen **Amnesia**, que ofrece funcionalidades similares para la gestión de microdatos complejos.6

## **Gobernanza y Responsabilidades del Organismo Público**

La anonimización en Uruguay no es solo una tarea técnica de los departamentos de TI, sino una obligación de gobernanza institucional. El personal que administre, manipule o conserve información pública es responsable, solidariamente con la autoridad de la dependencia, por las acciones u omisiones que deriven en la alteración o divulgación indebida de la información.2

### **La Inscripción de Bases de Datos**

Aun cuando un organismo esté en proceso de anonimizar sus datos, la base de datos original (con datos personales) debe estar debidamente inscripta ante la URCDP.21 Esta inscripción debe declarar la finalidad, el tipo de datos tratados y, fundamentalmente, las medidas de seguridad adoptadas, incluyendo las técnicas de disociación que se aplicarán para la entrega de información a terceros o para la publicación de datos abiertos.21

### **Transparencia Activa y Datos Abiertos**

Uruguay lidera la región en el Índice de Desarrollo del Gobierno Electrónico (EGDI) y mantiene una política agresiva de Datos Abiertos.24 Las entidades públicas tienen la obligación legal de publicar información en formato de dato abierto en el Catálogo Nacional.11 El estándar de anonimización aquí es particularmente estricto, ya que la información es de acceso universal y permanente.18 AGESIC proporciona guías de calidad que exigen que los datos sean completos, primarios, oportunos y procesables por máquina, pero siempre sujetos a la previa aplicación de criterios de disociación que aseguren la no identificación de las personas físicas.25

### **Casos de Uso Específicos: Salud y Seguridad**

El estándar de anonimización se vuelve más riguroso en sectores sensibles:

* **Salud:** El tratamiento de datos de salud requiere el consentimiento expreso del titular, salvo que se apliquen mecanismos de disociación para estudios epidemiológicos o estadísticos.5 AGESIC cuenta con guías específicas para la anonimización de datos en salud a través del programa Salud.uy.6  
* **Videovigilancia:** Las imágenes captadas por cámaras estatales constituyen datos personales. Ante una solicitud de acceso, el organismo debe proteger la privacidad de terceros mediante la utilización de "máscaras" de seguridad (enmascaramiento digital de rostros) o brindando la información en forma de informe escrito descriptivo que no permita la identificación visual.23

## **Implicancias de la Adecuación Internacional (RGPD)**

Es relevante destacar que Uruguay cuenta con una declaración de "nivel adecuado" por parte de la Comisión Europea.28 Esto significa que los estándares de protección y anonimización de Uruguay son equivalentes a los del Reglamento General de Protección de Datos (RGPD) de la Unión Europea.19 Esta equivalencia garantiza que cuando un organismo estatal uruguayo anonimiza datos para cooperar con organismos internacionales o para fomentar la investigación científica, el estándar aplicado es reconocido globalmente como robusto y confiable.15

## **Conclusiones y Recomendaciones para la Función Pública**

El estándar de anonimización que corresponde utilizar a un órgano estatal uruguayo se define por la integración de procesos legales de disociación con técnicas matemáticas de preservación de la privacidad. No se trata meramente de "borrar nombres", sino de un proceso integral de gestión de riesgos de reidentificación.

Para cumplir con la normativa vigente (Leyes 18.381 y 18.331), los organismos públicos deben:

1. **Adoptar el Principio de Privacidad desde el Diseño:** Integrar la anonimización en el ciclo de vida de los datos, desde su recolección hasta su publicación.30  
2. **Utilizar Modelos de Privacidad de Grupo:** Superar la seudonimización y aplicar modelos de ![][image1]\-anonymity y ![][image4]\-diversity para la entrega de microdatos administrativos.6  
3. **Documentar el Proceso:** Mantener registros técnicos de las jerarquías de generalización y las métricas de riesgo calculadas, lo cual sirve como prueba de cumplimiento ante eventuales auditorías de la URCDP o la UAIP.6  
4. **Priorizar la Utilidad:** Seleccionar técnicas que, aunque protejan la privacidad, no destruyan el valor estadístico de la información, permitiendo que la sociedad civil y la academia utilicen los datos públicos para la toma de decisiones basada en evidencia.6  
5. **Capacitación Continua:** Asegurar que los equipos técnicos y legales comprendan que la anonimización es un campo en constante evolución tecnológica, requiriendo una actualización periódica de los algoritmos y herramientas de software.11

En definitiva, el estándar uruguayo es una manifestación del compromiso del Estado con la transparencia proactiva, donde la tecnología actúa como el puente necesario para garantizar el derecho a saber sin comprometer el derecho a la intimidad de sus ciudadanos. La correcta aplicación de estos estándares no solo evita sanciones legales, sino que construye la infraestructura de confianza necesaria para una verdadera sociedad de la información y el conocimiento.

#### **Obras citadas**

1. Sobre la Ley N° 18.381 | Unidad de Acceso a la Información Pública \- GUB.UY, fecha de acceso: mayo 7, 2026, [https://www.gub.uy/unidad-acceso-informacion-publica/comunicacion/publicaciones/preguntas-frecuentes/preguntas-frecuentes/sobre-ley-n-18381](https://www.gub.uy/unidad-acceso-informacion-publica/comunicacion/publicaciones/preguntas-frecuentes/preguntas-frecuentes/sobre-ley-n-18381)  
2. Ley N° 18381 \- IMPO, fecha de acceso: mayo 7, 2026, [https://www.impo.com.uy/bases/leyes/18381-2008](https://www.impo.com.uy/bases/leyes/18381-2008)  
3. Ley 18.381 \- Derecho de Acceso a la Información Pública \- CAinfo, fecha de acceso: mayo 7, 2026, [http://www.cainfo.org.uy/images/18381.pdf](http://www.cainfo.org.uy/images/18381.pdf)  
4. Acceso a la Información – IMPO, fecha de acceso: mayo 7, 2026, [https://www.impo.com.uy/informacionpublica/](https://www.impo.com.uy/informacionpublica/)  
5. Ley N° 18331 \- IMPO, fecha de acceso: mayo 7, 2026, [https://www.impo.com.uy/bases/leyes/18331-2008](https://www.impo.com.uy/bases/leyes/18331-2008)  
6. Guía sobre Anonimización de Datos \- GUB.UY, fecha de acceso: mayo 7, 2026, [https://www.gub.uy/agencia-gobierno-electronico-sociedad-informacion-conocimiento/sites/agencia-gobierno-electronico-sociedad-informacion-conocimiento/files/documentos/publicaciones/Gu%C3%ADa%20sobre%20Anonimizaci%C3%B3n%20de%20Datos%20vf.pdf](https://www.gub.uy/agencia-gobierno-electronico-sociedad-informacion-conocimiento/sites/agencia-gobierno-electronico-sociedad-informacion-conocimiento/files/documentos/publicaciones/Gu%C3%ADa%20sobre%20Anonimizaci%C3%B3n%20de%20Datos%20vf.pdf)  
7. Ley 18.331 de Protección de Datos Personales y Acción de Habeas Data \- OAS.org, fecha de acceso: mayo 7, 2026, [http://www.oas.org/es/sla/ddi/docs/U4%20Ley%2018.331%20de%20Protecci%C3%B3n%20de%20Datos%20Personales%20y%20Acci%C3%B3n%20de%20Habeas%20Data.pdf](http://www.oas.org/es/sla/ddi/docs/U4%20Ley%2018.331%20de%20Protecci%C3%B3n%20de%20Datos%20Personales%20y%20Acci%C3%B3n%20de%20Habeas%20Data.pdf)  
8. Ley 18.331 \- Protección de Datos Personales y acción de Habeas Data \- Correo Uruguayo, fecha de acceso: mayo 7, 2026, [https://www.correo.com.uy/ley-18331](https://www.correo.com.uy/ley-18331)  
9. URCDP Datos Personales \- OSE, fecha de acceso: mayo 7, 2026, [http://www.ose.com.uy/transparencia/urcdp-datos-personales](http://www.ose.com.uy/transparencia/urcdp-datos-personales)  
10. Guía Criterios de Disociación de Datos Personales. \- GUB.UY, fecha de acceso: mayo 7, 2026, [https://www.gub.uy/unidad-reguladora-control-datos-personales/book/12866/download](https://www.gub.uy/unidad-reguladora-control-datos-personales/book/12866/download)  
11. Capítulo 4\. Conjunto de técnicas de anonimización | Unidad ..., fecha de acceso: mayo 7, 2026, [https://www.gub.uy/unidad-reguladora-control-datos-personales/comunicacion/publicaciones/guia-criterios-disociacion-datos-personales/guia-criterios-disociacion-3](https://www.gub.uy/unidad-reguladora-control-datos-personales/comunicacion/publicaciones/guia-criterios-disociacion-datos-personales/guia-criterios-disociacion-3)  
12. Guía Criterios de Disociación de Datos Personales. | Unidad ..., fecha de acceso: mayo 7, 2026, [https://www.gub.uy/unidad-reguladora-control-datos-personales/comunicacion/publicaciones/guia-criterios-disociacion-datos-personales/guia-criterios-disociacion](https://www.gub.uy/unidad-reguladora-control-datos-personales/comunicacion/publicaciones/guia-criterios-disociacion-datos-personales/guia-criterios-disociacion)  
13. 3.2 Anonimización | Unidad Reguladora y de Control de Datos Personales \- GUB.UY, fecha de acceso: mayo 7, 2026, [https://www.gub.uy/unidad-reguladora-control-datos-personales/comunicacion/publicaciones/guia-criterios-disociacion-datos-personales/capitulo-3-etapas-del-0](https://www.gub.uy/unidad-reguladora-control-datos-personales/comunicacion/publicaciones/guia-criterios-disociacion-datos-personales/capitulo-3-etapas-del-0)  
14. La anonimización y disociación de los datos personales \- Porto Legal, fecha de acceso: mayo 7, 2026, [https://www.porto.legal/blog/anonimizacion-y-disociacion-de-datos-personales/](https://www.porto.legal/blog/anonimizacion-y-disociacion-de-datos-personales/)  
15. GRUPO DE TRABAJO SOBRE PROTECCIÓN DE DATOS DEL ARTÍCULO 29 \- AEPD, fecha de acceso: mayo 7, 2026, [https://www.aepd.es/documento/wp216-es.pdf](https://www.aepd.es/documento/wp216-es.pdf)  
16. Guía básica de anonimización, fecha de acceso: mayo 7, 2026, [https://www.aepd.es/documento/guia-basica-anonimizacion.pdf](https://www.aepd.es/documento/guia-basica-anonimizacion.pdf)  
17. Guía introductoria a la anonimización de datos, fecha de acceso: mayo 7, 2026, [https://wikiguias.digital.gob.cl/documentos/gui%CC%81a\_anonimizacion\_de\_datos.pdf](https://wikiguias.digital.gob.cl/documentos/gui%CC%81a_anonimizacion_de_datos.pdf)  
18. Guía de Datos Abiertos PROPUESTA \- Gobierno Electrónico, fecha de acceso: mayo 7, 2026, [https://aportecivico.gobiernoelectronico.gob.ec/system/documents/attachments/000/000/009/original/142533af163f52ac11b3dac2e415dbd4457adddc.pdf](https://aportecivico.gobiernoelectronico.gob.ec/system/documents/attachments/000/000/009/original/142533af163f52ac11b3dac2e415dbd4457adddc.pdf)  
19. Prototipo de política pública: Guía para la adopción de ... \- Open Loop, fecha de acceso: mayo 7, 2026, [https://openloop.org/reports/2024/03/uruguay-report-pets-es.pdf](https://openloop.org/reports/2024/03/uruguay-report-pets-es.pdf)  
20. ATLAS INTELIGENCIA ARTIFICIAL DESARROLLO HUMANO \- United Nations Development Programme, fecha de acceso: mayo 7, 2026, [https://www.undp.org/sites/g/files/zskgke326/files/2025-06/atlas\_a\_8\_6\_compressed\_0\_0.pdf](https://www.undp.org/sites/g/files/zskgke326/files/2025-06/atlas_a_8_6_compressed_0_0.pdf)  
21. Cómo inscribir una base de datos en la URCDP en Uruguay (Guía 2025\) \- Asesoría Digital, fecha de acceso: mayo 7, 2026, [https://asesoriadigital.uy/inscribir-base-datos-urcdp/](https://asesoriadigital.uy/inscribir-base-datos-urcdp/)  
22. Dictamen N° 15/021 . | Unidad Reguladora y de Control de Datos Personales \- GUB.UY, fecha de acceso: mayo 7, 2026, [https://www.gub.uy/unidad-reguladora-control-datos-personales/institucional/normativa/dictamen-n-15021](https://www.gub.uy/unidad-reguladora-control-datos-personales/institucional/normativa/dictamen-n-15021)  
23. EL DERECHO AL OLVIDO Y A LA PROTECCIÓN DE DATOS PERSONALES EN URUGUAY, fecha de acceso: mayo 7, 2026, [https://revistaderecho.um.edu.uy/wp-content/uploads/2017/09/SCHIAVI-Pablo-El-derecho-al-olvido-y-a-la-proteccion-de-datos-personales-en-Uruguay.pdf?form=MG0AV3](https://revistaderecho.um.edu.uy/wp-content/uploads/2017/09/SCHIAVI-Pablo-El-derecho-al-olvido-y-a-la-proteccion-de-datos-personales-en-Uruguay.pdf?form=MG0AV3)  
24. GOBERNANZA PUBLICA y DATOS ABIERTOS EN URUGUAY \- OAS.org, fecha de acceso: mayo 7, 2026, [https://www.oas.org/en/sla/dlc/mesicic/docs/Uruguay\_Open\_Data.pdf](https://www.oas.org/en/sla/dlc/mesicic/docs/Uruguay_Open_Data.pdf)  
25. Preguntas frecuentes \- Catálogo de Datos Abiertos, fecha de acceso: mayo 7, 2026, [https://catalogodatos.gub.uy/agesic/portal/faq](https://catalogodatos.gub.uy/agesic/portal/faq)  
26. Guías para la apertura y publicación de datos abiertos | Agencia de ..., fecha de acceso: mayo 7, 2026, [https://www.gub.uy/agencia-gobierno-electronico-sociedad-informacion-conocimiento/comunicacion/publicaciones/guias-para-apertura-publicacion-datos-abiertos](https://www.gub.uy/agencia-gobierno-electronico-sociedad-informacion-conocimiento/comunicacion/publicaciones/guias-para-apertura-publicacion-datos-abiertos)  
27. Protección de datos personales ante la expansión de la videovigilancia privada \- Revista de la Asociación de Escribanos del Uruguay, fecha de acceso: mayo 7, 2026, [https://revista.aeu.org.uy/index.php/raeu/article/download/597/522/579](https://revista.aeu.org.uy/index.php/raeu/article/download/597/522/579)  
28. La Comisión Europea ratifica el nivel adecuado de Uruguay para la protección de datos | Unidad Reguladora y de Control de Datos Personales \- GUB.UY, fecha de acceso: mayo 7, 2026, [https://www.gub.uy/unidad-reguladora-control-datos-personales/comunicacion/noticias/comision-europea-ratifica-nivel-adecuado-uruguay-para-proteccion-datos-0](https://www.gub.uy/unidad-reguladora-control-datos-personales/comunicacion/noticias/comision-europea-ratifica-nivel-adecuado-uruguay-para-proteccion-datos-0)  
29. Protección de Datos Personales: Comisión Europea Ratifica el Nivel Adecuado de Uruguay, fecha de acceso: mayo 7, 2026, [https://bergsteinlaw.com/proteccion-de-datos-personales-comision-europea-ratifica-el-nivel-adecuado-de-uruguay/](https://bergsteinlaw.com/proteccion-de-datos-personales-comision-europea-ratifica-el-nivel-adecuado-de-uruguay/)  
30. Guía de Anonimización de Datos Estructurados \- Archivo General de la Nación, fecha de acceso: mayo 7, 2026, [https://www.archivogeneral.gov.co/sites/default/files/Estructura\_Web/5\_Consulte/Recursos/Publicacionees/Guia\_de\_Anonimizacion-min.pdf](https://www.archivogeneral.gov.co/sites/default/files/Estructura_Web/5_Consulte/Recursos/Publicacionees/Guia_de_Anonimizacion-min.pdf)  
31. 1.9 Estrategia de Datos Abiertos para el período 2021 – 2024., fecha de acceso: mayo 7, 2026, [https://miradordegobiernoabierto.agesic.gub.uy/SigesVisualizador/gu/o/GA/p/2267](https://miradordegobiernoabierto.agesic.gub.uy/SigesVisualizador/gu/o/GA/p/2267)  
32. Guía sobre anonimización de datos | Agencia de Gobierno Electrónico y Sociedad de la Información y del Conocimiento \- GUB.UY, fecha de acceso: mayo 7, 2026, [https://www.gub.uy/agencia-gobierno-electronico-sociedad-informacion-conocimiento/comunicacion/publicaciones/guia-sobre-anonimizacion-datos](https://www.gub.uy/agencia-gobierno-electronico-sociedad-informacion-conocimiento/comunicacion/publicaciones/guia-sobre-anonimizacion-datos)

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAsAAAAXCAYAAADduLXGAAAA4ElEQVR4XuXSscuBURTH8aM3RaGU0SBRMvoDjDYbo+H9BwwsVtnEZDOaRcqsjDaTRcnkD3gtNr7Hvbd0n0dW9f7qU88959a99/SIfGUiyCDtN/wM8Yc7ul4vNA1cUfUbYZngiKzf8JPCFmvEvF4gZVzQs2t9bAk1xN0mlxZuYppRDDDCSkIe7O5bQB8VMZsC09G57rDHVMyVNHqNDhJ2/czryIo4YClvHuqPbCbmJD2xjl9blyQ2mIt5mEY361qnMEbe1iWHM9quQJo4YWHrOsZn9EOP+3EFGz3x4w/1f/MAmBojHto7TqYAAAAASUVORK5CYII=>

[image2]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACwAAAAYCAYAAACBbx+6AAABYElEQVR4Xu2VPyhGURiHX0lR/kRKySBRMhqMRosMirIYGA0GFqtMxGRjYjKIlFkZbSYLySTFRMrG8+ucW/c7fd+9t9S933CeeoZzztvXr/O9571mkUgmLdiPveFBM7KHn/iLm8FZFXTgquVc3gJ+4XR4UBJ9uIQn+IZPOFhTEXCIjzgUHpSEAs/jFJ5ZTuBuvMVrbA/OquDUcgJP4Ctu+bUe4DjOmOunsskNvIw/5gK24Q7u45VV8whzAyf9O4rbOGkuaFVTIzOwRscd3uORufYQaokN7PTreqjf9aNF1IxXqxUhM3DSv+/mblnt0FNT0ZhZPC7oruXM1RSZgdPzdwwf8NKqnRaZgcP5q2K1iG5jDlf8fpk0DNyFN3hubjoIFWutcXaAI36/TJTh2ep8xIbxBddTe4vmii/8ftGH8l8GzH28PsxNJ/ltLstaUqQw+utbkw2Pbr7oA4lEIpEm4Q8ST0iRTbPvTwAAAABJRU5ErkJggg==>

[image3]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAC4AAAAYCAYAAACFms+HAAABwElEQVR4Xu2WTShEURTHj6QoHynykcUkSpYW7CyVhR02oqxYWbCxlYUSK0qRkqVEyk4JO6SslHwkCSUbNhaK/3/OvTP3PWNmTHmPer/69ebdjzrvvXPOHZGIiJzIgxWw3D/xl5mGL/ADjvnmwiAfdsEFYy8s8qxw6IavsN0/ETAFcB5OwAY4BJ/hKYwllyWZgxewzj8RMJ1wR7xxDMB3uCz6YAlK4T7choXuRAiMi6Ysg7TwIa7hOax2xqUZ3otuIizUJtghaXLrl2iFJ3DYGauFl0b+TtAP30QD5aeYhDNwS/5GsbLuWH+b4ssIm98sBhZFi2jAmbpMIzyCVz+wL74ze/giV+AjbHMn2LcPRat2UTRtCFNlFBab+7Dogbei2eDB5veT6FtnmpR5VoQH3/CxuX7B7d/89GeSIpe+gQdFlWjBZGtJfGdmGOyBaEyEKcO2mDjZ/f17VTR1uICn16AZTwXTiGt4smWrTcV0xOC6uVoq4ZJo644//a7oItvYGTjv2QZnYb0ZD4oauAcfxFvUd3BNTJwxeANHeGNgMbDZb5hx9vQgsQdQKqfsIgbFlGCuuvBL/Kt/iRERERG58wl0Il0b9AwhKwAAAABJRU5ErkJggg==>

[image4]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAYAAAAZCAYAAAASTF8GAAAAeUlEQVR4XmNgoBngBWJxIGaGCWgD8Q0g/g/EF4FYFCYBAoJAfBKIlwIxI7KEFhA/A+JMZEEQiAXiz0Bshy4xmQGP+WuAmBVZgnTzcUqQb7EmENfCJLyB+CMDxPwcII6CSYBC8zQQ7wXiJUAsAJMAAZDZIAUodgw+AADajRkHBC7yJQAAAABJRU5ErkJggg==>

[image5]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAC4AAAAYCAYAAACFms+HAAAByklEQVR4Xu2WTShEURiGP6Eov6VIkkTJkqQoS1Y28leiJBvJAgvZyU6UwkYp2ShEypZSNthYKfnJioWFYmOheN/5zhl3TjNjSPda3Keeac7PzJx75j3fvSIhIb8iDRbBQnfgPzMHX+AHnHDGgqAHNsNc0Q0thgOwzjvJ0glfYYs74DMZcEt0E71uwwLPvChL8BqWuQMBsAYv4C3cge0wPWaGIQ8ewwOY5YwFwTJscDvjUQsf4JRpM1c1sBVm20k+kvLC++Gb6EIz4Sych/sSzGFdgYvwHN7BE1gfM8Ng810FZ0RPLxf8XZWphmeiWUzVvsgnk7MOp+Ur16woj7DRTiCs26eih2FVNDaEURmHOabtJzxz3sPIgsGd3xRNRASb7yfRXWdM8u3gP6EU3sArWGI7vfWbf/0l3JPUqgt3hTcHfnGq8qaSjCHR8zbi6bMLp3wfwa3fG6LRYYRYPwdNfzwYI87p/oE2iolgZXuX2IXbqByJuXC+sMEib7PDhbPNMrgAK02/XzSJVpVolkEvfIZdtqMC3sMx2yE6yKvbNf2s6X7C35uEh3BYNBE8g6NmLDqJkXBvp/wngn5KLIcdsE0SPKOEhISE/A2fALBaUZhrK+QAAAAASUVORK5CYII=>

[image6]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAcAAAAYCAYAAAA20uedAAAAjUlEQVR4XmNgGOQgBYh3AbEwugQHEG+BYhAbBcgA8T0gbkcW5AViKSAOB+LPQBwJxBJAzAqSTATi2UB8C4g/AvFSIJ4MxCogSRAg3T4YcAPiT1AaA9QA8SMgVkaXgNm3G4i5GSCu7AZiWZCkKBBfZEDYFwLEhUDMCOKAiGYgvgHEK6FssB+RgSAUD1EAADI3Fz6al+aFAAAAAElFTkSuQmCC>