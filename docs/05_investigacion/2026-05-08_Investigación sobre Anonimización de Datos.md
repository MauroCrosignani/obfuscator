# **Estrategias y sistemas avanzados para la desidentificación y publicación segura de datos: un marco técnico-reglamentario para la gobernanza de la privacidad en la era de la inteligencia artificial**

El panorama contemporáneo de la gestión de activos digitales se encuentra en una intersección crítica entre la necesidad de explotar el valor analítico de los grandes volúmenes de información y el imperativo ético y legal de proteger la privacidad de los individuos. En un entorno donde los datos se han convertido en la piedra angular del desarrollo tecnológico, particularmente para el entrenamiento y despliegue de sistemas de Inteligencia Artificial, la capacidad de liberar conjuntos de datos a terceros de manera segura deja de ser una opción técnica para convertirse en un requisito de cumplimiento y confianza institucional. Este informe técnico profundiza en los mecanismos, marcos regulatorios y herramientas de vanguardia que permiten la desidentificación y anonimización de datos, con un enfoque especial en la robustez de las pruebas de validación y la aplicabilidad de estos principios en el contexto normativo uruguayo e internacional.

## **El ecosistema de la privacidad y la desidentificación en el siglo XXI**

La transición de una sociedad que simplemente recolectaba datos a una que depende de ellos para la toma de decisiones automatizadas ha redefinido el concepto de anonimato. Tradicionalmente, se consideraba que eliminar el nombre de una persona de un registro era suficiente para garantizar su privacidad. Sin embargo, la proliferación de fuentes de datos externas y el aumento de la capacidad de procesamiento han demostrado que la reidentificación es un riesgo dinámico y persistente.1 La desidentificación no debe entenderse como un estado binario, sino como un proceso continuo de gestión de riesgos que busca reducir la probabilidad de que un individuo sea identificado dentro de un conjunto de datos, equilibrando esta protección con la utilidad de la información para fines analíticos.3

En este contexto, el proyecto de una herramienta de liberación segura de datasets debe contemplar a la Inteligencia Artificial no solo como una herramienta de procesamiento, sino como un receptor de datos que posee capacidades de inferencia superiores a las humanas. Por lo tanto, los mecanismos de protección deben ser lo suficientemente sofisticados para resistir ataques de vinculación, ataques de homogeneidad y ataques de inferencia de membresía, los cuales son particularmente relevantes cuando los modelos de aprendizaje automático consumen la información.5

## **El marco regulatorio uruguayo y su interpretación técnica**

Uruguay ha consolidado un marco normativo robusto que posiciona al país como un referente en la protección de datos personales en la región. La Ley N° 18.331 de Protección de Datos Personales y Acción de "Habeas Data" establece los principios fundamentales que rigen el tratamiento de la información, reconociendo la privacidad como un derecho fundamental.7 Para una herramienta de liberación segura de datos, es vital comprender cómo la Unidad Reguladora y de Control de Datos Personales (URCDP) y la Agencia de Gobierno Electrónico y Sociedad de la Información y del Conocimiento (AGESIC) interpretan la anonimización y la disociación de datos.

### **La doctrina de la URCDP y el principio de disociación**

La URCDP ha mantenido una postura firme respecto a que la ley se aplica a cualquier dato personal, independientemente de si este se encuentra o no organizado en una base de datos formal.8 Esto implica que cualquier proceso de compartición de información con terceros debe pasar por un tamiz de protección que garantice la disociación. En el Dictamen N° 01/018, referente al proyecto "Cercanía Digital" de la Intendencia de Montevideo, la Unidad analizó la legitimidad del tratamiento de datos provenientes de fuentes propias, de terceros y de redes sociales.8 Este dictamen es fundamental para el proyecto en cuestión, ya que establece que la legitimidad no solo depende de la fuente, sino de la capacidad del organismo para tratar los datos de manera que no se revelen las identidades de los titulares, respetando el secreto estadístico y la confidencialidad.8

La normativa uruguaya, a través del Decreto N° 64/020, ha reforzado las obligaciones de las organizaciones, incluyendo la necesidad de designar delegados de protección de datos (DPO) en ciertos sectores y la obligación de documentar mediante contrato cualquier servicio de tratamiento por terceros.9 Para una herramienta de liberación de datos, esto sugiere que la funcionalidad no debe limitarse a la técnica, sino que debe facilitar la generación de la documentación y los contratos que respalden la legalidad de la transferencia.

### **Guía de anonimización de AGESIC: un enfoque metodológico**

AGESIC propone una metodología de cinco pasos para la anonimización, que sirve como base para el diseño funcional de cualquier sistema de publicación segura. Esta guía enfatiza que la anonimización es un proceso de "borrado permanente" de la identidad, donde el resultado final no debe permitir establecer vínculos con el titular sin un esfuerzo desproporcionado.10

| Paso Metodológico (AGESIC) | Descripción Técnica y Requisitos | Criterio de Éxito |
| :---- | :---- | :---- |
| **Paso 1: Conozca sus datos** | Clasificación exhaustiva de variables en identificadores directos (cédula, nombre), quasi-identificadores (fecha de nacimiento, sexo, código postal) y datos sensibles (salud, raza). | Mapa completo de riesgos de privacidad del dataset original.10 |
| **Paso 2: Desidentificar** | Remoción técnica de identificadores directos. Se recomienda no solo cifrar, sino eliminar o sustituir por seudónimos irrelevantes si no hay necesidad de reidentificación. | Eliminación del vínculo obvio con el individuo.10 |
| **Paso 3: Aplicar técnicas** | Aplicación de generalización, supresión de outliers, microagregación o adición de ruido según el tipo de dato. | Reducción de la singularidad de los registros a niveles aceptables.11 |
| **Paso 4: Calcule su riesgo** | Uso de modelos estadísticos para medir la probabilidad de reidentificación tras la transformación. | Cuantificación del riesgo residual (e.g., umbrales de k-anonimidad).10 |
| **Paso 5: Gestione riesgos** | Implementación de controles contractuales, monitorización post-publicación y protocolos de respuesta ante incidentes. | Aseguramiento de la protección durante todo el ciclo de vida del dato.10 |

El diseño funcional de la herramienta debe integrar estos pasos de manera fluida, permitiendo que el usuario pase de la carga de datos a la clasificación y, finalmente, a la aplicación de modelos de privacidad que generen informes técnicos defendibles ante la autoridad de control.

## **Marcos internacionales y estándares de desidentificación**

Mientras que el caso uruguayo proporciona la base legal, los estándares internacionales ofrecen el rigor técnico necesario para validar que una herramienta es "profesionalmente segura".

### **ISO/IEC 20889:2023: Terminología y clasificación de técnicas**

Este estándar internacional es la referencia definitiva para clasificar las técnicas de desidentificación. Divide los métodos en categorías según su impacto en los datos y su capacidad para mitigar riesgos específicos.14 Para una herramienta de software, adoptar la terminología de ISO/IEC 20889 asegura la interoperabilidad y la comprensión por parte de auditores internacionales.

Las técnicas se clasifican en:

1. **Técnicas de supresión:** Eliminación de variables o registros.  
2. **Técnicas de generalización:** Reducción de la granularidad (e.g., pasar de fecha exacta a año).  
3. **Técnicas de aleatorización:** Adición de ruido o permutación.  
4. **Modelos de privacidad formal:** Como la Privacidad Diferencial, que ofrece garantías matemáticas independientemente del conocimiento previo del atacante.3

### **NIST SP 800-188: Gobernanza de datos gubernamentales**

El Instituto Nacional de Estándares y Tecnología (NIST) de EE. UU. proporciona una guía exhaustiva para agencias gubernamentales que deseen publicar datasets.16 Un concepto clave que puede transferirse al proyecto es el de la **Junta de Revisión de Divulgación (Disclosure Review Board \- DRB)**. El NIST sugiere que el proceso de desidentificación no sea una decisión puramente algorítmica, sino que sea supervisado por un panel de expertos que evalúe tanto el riesgo técnico como el contexto de la liberación.4

El NIST también destaca la importancia de elegir el modelo de liberación adecuado:

* **Publicación de microdatos deidentificados:** Datos a nivel de registro con transformaciones aplicadas.  
* **Datos sintéticos:** Creación de un dataset artificial que imita las propiedades estadísticas del original.  
* **Interfaz de consulta:** No se entrega el dataset, sino que se permite a terceros realizar consultas que son anonimizadas en tiempo real (e.g., mediante privacidad diferencial).4

### **El Marco de Toma de Decisiones de Anonimización (ADF) de UKAN**

El UK Anonymisation Network (UKAN) propone un marco de 12 pasos que integra aspectos legales, sociales y éticos. Su principio fundamental es que "no se puede decidir si los datos son seguros solo examinando los datos; se debe examinar la situación de los datos".2

| Etapa del ADF | Componente Crítico | Relevancia para el Proyecto |
| :---- | :---- | :---- |
| **Evaluación de la Situación** | Mapeo del ecosistema de datos, identificación de interesados y casos de uso. | Define los límites del entorno de compartición (e.g., si es una nube privada o acceso público).20 |
| **Análisis de Riesgo y Control** | Identificación de procesos para evaluar riesgo de divulgación y controles técnicos pertinentes. | Selección de algoritmos específicos basados en el escenario de ataque plausible.19 |
| **Gestión de Impacto** | Planificación de comunicación con interesados y protocolos para cuando algo sale mal. | Estrategia de respuesta ante reidentificaciones accidentales.19 |

El ADF introduce la **Prueba del Intruso Motivado**, un ejercicio de validación donde se intenta reidentificar individuos simulando a un atacante con recursos razonables y acceso a información pública.1 Esta prueba es un benchmark cualitativo esencial para demostrar que se ha cumplido con el estándar de "esfuerzo proporcionado" que exige la ley.

## **Análisis profundo de productos y frameworks técnicos**

Para construir una herramienta robusta, es necesario analizar las funcionalidades de las soluciones líderes actuales, no solo su discurso comercial, sino su implementación técnica y métodos de validación.

### **ARX Data Anonymization Tool**

ARX es, posiblemente, el framework de código abierto más completo para la anonimización de datos tabulares. Su diseño se basa en una arquitectura de tres pasos: configuración, transformación y análisis.21

#### **Funcionalidades concretas de ARX**

ARX permite definir metadatos precisos para cada atributo. Los atributos se marcan como:

* **Identificadores:** Se eliminan automáticamente.  
* **Quasi-identificadores:** Se someten a transformación mediante jerarquías de generalización.  
* **Atributos sensibles:** Se mantienen pero se protegen mediante modelos como l-diversidad o t-closeness para evitar la divulgación de atributos.  
* **Atributos insensibles:** Se mantienen sin cambios.23

Una funcionalidad crítica de ARX es su soporte para **jerarquías funcionales y relacionales**. El usuario puede definir cómo se transforman los datos de manera multinivel (e.g., Ciudad \-\> Departamento \-\> País). Estas jerarquías pueden guardarse y reutilizarse, facilitando la persistencia de la configuración en proyectos recurrentes.11

#### **Validación y métricas de seguridad en ARX**

ARX no solo transforma los datos, sino que proporciona un panel de análisis de riesgo que calcula:

1. **Riesgo de reidentificación:** Basado en modelos de atacantes (Prosecutor, Journalist, Marketer). Evalúa cuántos registros en el conjunto de salida están por encima de un umbral de riesgo definido.24  
2. **Métricas de utilidad de datos:** Mide la pérdida de información utilizando modelos como "Granularidad", "Entropía No Uniforme" y métricas orientadas a tareas de clasificación (workload-aware models).22

ARX valida sus resultados asegurando que el dataset final cumpla estrictamente con el **modelo de privacidad seleccionado** (e.g., que no existan grupos de menos de ![][image1] individuos indistinguibles). Su algoritmo de búsqueda clasifica todo el espacio de soluciones posibles para encontrar la transformación que maximice la utilidad manteniendo el nivel de privacidad requerido.22

### **Amnesia (OpenAIRE)**

Amnesia se distingue por su enfoque en datos transaccionales y su facilidad de uso para investigadores no expertos en informática.25

#### **Funcionalidades concretas de Amnesia**

Su característica diferencial es el soporte para **km-anonymity**. Mientras que la k-anonimidad tradicional se aplica a registros únicos, la km-anonimidad se aplica a conjuntos de valores (set-valued data), como listas de compras o registros de navegación, asegurando que ninguna combinación de ![][image2] ítems pueda identificar a menos de ![][image1] personas.25

Amnesia ofrece:

* **Generación automática de jerarquías:** Crea estructuras de generalización basadas en la distribución de los datos para ahorrar tiempo al usuario.26  
* **Visualización de soluciones candidatas:** Permite al usuario navegar por un grafo de posibles estados del dataset anonimizado y elegir el que mejor se adapte a sus necesidades de análisis.25  
* **Supresión de outliers:** En lugar de generalizar todo el dataset para cubrir un solo caso atípico (lo que arruinaría la utilidad), Amnesia permite eliminar esos registros específicos.25

#### **Validación en Amnesia**

Amnesia utiliza herramientas gráficas para mostrar la distribución de valores antes y después de la anonimización, permitiendo una validación visual de la pérdida de utilidad. Además, garantiza formalmente el cumplimiento de los modelos ![][image1] y ![][image3] mediante algoritmos optimizados para arquitecturas multinúcleo.25

### **Microsoft Presidio**

Presidio está diseñado para el mundo de los datos no estructurados y semi-estructurados, siendo una pieza clave para la "liberación segura" hacia modelos de IA.29

#### **Funcionalidades concretas de Presidio**

Funciona a través de dos motores principales:

1. **Analyzer:** Detecta PII utilizando una combinación de NER (Spacy, Transformers), expresiones regulares con validación de checksum (e.g., algoritmo de Luhn para tarjetas de crédito) y listas de denegación.29  
2. **Anonymizer:** Ejecuta las transformaciones. Sus operadores incluyen:  
   * replace: Sustituye por una etiqueta fija.  
   * mask: Oculta parte del dato (e.g., dejar solo los últimos 4 dígitos).  
   * encrypt: Cifrado reversible que permite la recuperación controlada de la identidad si es necesario.29

#### **Validación y Benchmarks de Presidio**

Microsoft ofrece el paquete **Presidio-Research**, que incluye herramientas para generar datos sintéticos y evaluar el rendimiento del sistema mediante métricas estándar de ciencia de datos 33:

| Métrica de Validación | Definición en el contexto de PII | Relevancia |
| :---- | :---- | :---- |
| **Precision** | Proporción de entidades detectadas que son realmente PII. | Evita la "sobre-anonimización" que daña la utilidad del texto.33 |
| **Recall (Sensibilidad)** | Proporción de PII reales que fueron efectivamente detectadas. | Es la métrica crítica; un bajo recall significa que se filtró información sensible.33 |
| **F-beta Score (![][image4])** | Media armónica que prioriza el recall sobre la precisión. | Recomendada por Presidio para asegurar que la seguridad es la prioridad.33 |

En estudios comparativos independientes, Presidio ha demostrado un **recall de 0.74 y una precisión de 0.51** en textos clínicos, superando en precisión a herramientas como Philter, aunque quedando ligeramente por debajo en sensibilidad bruta.35 Estos benchmarks son fundamentales para que el proyecto pueda sostener que su motor de detección es competitivo a nivel mundial.

## **La IA como receptor: riesgos específicos y validación**

Cuando se liberan datos para alimentar una IA, la desidentificación debe resistir ataques sofisticados que no afectan a los analistas humanos tradicionales.

### **Ataques de Inferencia de Membrecía (MIA)**

Un MIA intenta determinar si un punto de dato específico fue parte del conjunto de entrenamiento de un modelo. Si un modelo "memoriza" demasiado, su salida revelará información sobre sus inputs.5

* **Validación:** Se utilizan modelos de "sombra" (shadow models) para simular el comportamiento de un atacante y medir su éxito. Un modelo se considera seguro si la ventaja del atacante para adivinar la membresía es mínima.37  
* **Defensa:** La implementación de **Privacidad Diferencial (DP-SGD)** añade ruido a los gradientes durante el entrenamiento, garantizando que la presencia o ausencia de un solo individuo no altere significativamente los pesos finales del modelo.6

### **Inversión de Modelo y Extracción de Atributos**

Estos ataques buscan reconstruir los datos originales a partir de las predicciones del modelo.

* **Validación:** Benchmarks de "fidelidad de reconstrucción". Se mide qué tan cerca puede llegar un atacante a la imagen o texto original basándose solo en las respuestas de la API del modelo.38

## **Mapa comparativo de soluciones y estrategias**

Este mapa resume las opciones para el diseño de la herramienta, permitiendo seleccionar componentes según la prioridad.

| Solución / Framework | Fortaleza Principal | Funcionalidad Clave | Método de Validación |
| :---- | :---- | :---- | :---- |
| **ARX** | Rigor Estadístico | Modelos ![][image5] y DP combinables. | Análisis de riesgo formal y métricas de utilidad analítica.24 |
| **Amnesia** | Usabilidad e Innovación | Soporte para datos transaccionales (![][image3]\-anonymity). | Grafo visual de soluciones y visualización de distribución.26 |
| **MS Presidio** | Datos No Estructurados | Detección contextual de PII mediante NLP. | Benchmarks de Precision/Recall (F2-score).33 |
| **NIST SP 800-188** | Gobernanza | Modelo de Junta de Revisión (DRB). | Estudios de reidentificación y estándares de rendimiento.4 |
| **UKAN ADF** | Gestión Situacional | Evaluación del entorno de compartición. | Prueba del Intruso Motivado.1 |
| **Synthesized/Mostly AI** | Calidad de Datos | Generación de datos sintéticos de alta fidelidad. | Comparación de distribuciones estadísticas original vs. sintético.40 |

## **Transferencia al proyecto: diseño funcional y estrategia de testing**

Basado en la investigación profunda, se extraen las siguientes directrices para el desarrollo de la herramienta de liberación segura de datasets.

### **Diseño Funcional: El "Pipeline de Publicación Segura"**

La herramienta no debe ser un simple filtro, sino un flujo de trabajo de gobernanza que incluya:

1. **Módulo de Descubrimiento e Inventario:** Integrar un motor de detección basado en reglas y ML (estilo Presidio) para identificar no solo columnas con nombres, sino también PII ocultas en campos de comentarios o logs de texto. Debe generar un "Mapa de Calor de Riesgo" del dataset.29  
2. **Orquestador de Transformaciones:** Permitir al usuario elegir entre diferentes "Recetas de Privacidad" basadas en el estándar ISO 20889\.  
   * *Receta para IA:* Enfoque en privacidad diferencial y síntesis de datos para preservar correlaciones complejas sin exponer registros individuales.4  
   * *Receta para Estadística:* Enfoque en generalización y microagregación para mantener promedios exactos.11  
3. **Simulador de Atacante (Sandbox de Validación):** Antes de la liberación definitiva, la herramienta debe permitir ejecutar ataques simulados (MIA, vinculación) contra el dataset transformado para proporcionar un "Certificado de Riesgo Residual".5  
4. **Generador de Evidencia Regulatoria:** Creación automática de un documento técnico que detalle el proceso seguido, las jerarquías usadas y las métricas de validación obtenidas, alineado con los requerimientos de la URCDP (Uruguay) y el GDPR.9

### **Estrategia de Testing y Garantía de Calidad**

Para sostener que los resultados son "seguros y defendibles", el plan de pruebas del proyecto debe incluir:

* **Test de Regresión de Privacidad:** Cada vez que se actualice el software, se deben procesar datasets de referencia (como el dataset de adultos de UCI) y verificar que los niveles de k-anonimidad se mantengan constantes.  
* **Pruebas de "Ruido Blanco":** Para implementaciones de Privacidad Diferencial, realizar pruebas estadísticas para confirmar que el ruido añadido sigue la distribución teórica (e.g., Laplace o Gaussiana) y que el "presupuesto de privacidad" (![][image6]) se consume correctamente.  
* **Evaluación de "Intruso Amigo":** Implementar un protocolo de testing donde un equipo distinto al de desarrollo intente reidentificar registros utilizando datasets públicos de Uruguay (como datos abiertos de AGESIC o el padrón de beneficiarios sociales si estuviera disponible para fines de prueba).1  
* **Benchmark de Utilidad post-IA:** Si el dataset está destinado a entrenar una IA, el test final debe ser entrenar un modelo con datos reales y otro con datos anonimizados. La pérdida de precisión en la tarea de la IA no debe exceder un porcentaje definido (e.g., 5%) para validar que la herramienta es útil en la práctica.24

## **Consideraciones finales sobre la responsabilidad proactiva**

La construcción de un sistema de liberación segura de datos es un ejercicio de **responsabilidad proactiva**. No basta con cumplir con el mínimo técnico; se debe poder demostrar que se han considerado los riesgos emergentes, especialmente los derivados de las capacidades de la IA. El caso uruguayo, con su enfoque en la disociación y la gestión de riesgos de AGESIC, proporciona un terreno fértil para el despliegue de estas tecnologías, siempre que se acompañen de una validación técnica rigurosa y una gobernanza que incluya la revisión humana en los puntos críticos de decisión.9 La integración de métricas de recall en la detección de PII y umbrales de riesgo de reidentificación en microdatos permitirá al proyecto posicionarse como una solución de "grado de cumplimiento", esencial para la economía de datos moderna.

#### **Obras citadas**

1. How do we ensure anonymisation is effective? | ICO, fecha de acceso: mayo 8, 2026, [https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/data-sharing/anonymisation/how-do-we-ensure-anonymisation-is-effective/](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/data-sharing/anonymisation/how-do-we-ensure-anonymisation-is-effective/)  
2. The Anonymisation Decision-making Framework, fecha de acceso: mayo 8, 2026, [https://fpf.org/wp-content/uploads/2016/11/Mackey-Elliot-and-OHara-Anonymisation-Decision-making-Framework-v1-Oct-2016.pdf](https://fpf.org/wp-content/uploads/2016/11/Mackey-Elliot-and-OHara-Anonymisation-Decision-making-Framework-v1-Oct-2016.pdf)  
3. Ten quick tips for protecting health data using de-identification and perturbation of structured datasets \- PMC, fecha de acceso: mayo 8, 2026, [https://pmc.ncbi.nlm.nih.gov/articles/PMC12456793/](https://pmc.ncbi.nlm.nih.gov/articles/PMC12456793/)  
4. SP 800-188, De-Identifying Government Datasets: Techniques and ..., fecha de acceso: mayo 8, 2026, [https://csrc.nist.gov/pubs/sp/800/188/final](https://csrc.nist.gov/pubs/sp/800/188/final)  
5. Systematic Evaluation of Privacy Risks of Machine Learning Models \- USENIX, fecha de acceso: mayo 8, 2026, [https://www.usenix.org/system/files/sec21fall-song.pdf](https://www.usenix.org/system/files/sec21fall-song.pdf)  
6. Differential Privacy Protection Against Membership Inference Attack on Machine Learning for Genomic Data \- PSB conference, fecha de acceso: mayo 8, 2026, [https://psb.stanford.edu/psb-online/proceedings/psb21/chen\_j.pdf](https://psb.stanford.edu/psb-online/proceedings/psb21/chen_j.pdf)  
7. Guía sobre anonimización de datos | Agencia de Gobierno Electrónico y Sociedad de la Información y del Conocimiento \- GUB.UY, fecha de acceso: mayo 8, 2026, [https://www.gub.uy/agencia-gobierno-electronico-sociedad-informacion-conocimiento/comunicacion/publicaciones/guia-sobre-anonimizacion-datos](https://www.gub.uy/agencia-gobierno-electronico-sociedad-informacion-conocimiento/comunicacion/publicaciones/guia-sobre-anonimizacion-datos)  
8. Resoluciones Dictámenes e Informes \- GUB.UY, fecha de acceso: mayo 8, 2026, [https://www.gub.uy/unidad-reguladora-control-datos-personales/sites/unidad-reguladora-control-datos-personales/files/documentos/publicaciones/2018\_ResolucionesYdictamentes.pdf](https://www.gub.uy/unidad-reguladora-control-datos-personales/sites/unidad-reguladora-control-datos-personales/files/documentos/publicaciones/2018_ResolucionesYdictamentes.pdf)  
9. Uruguay dicta nuevas normas sobre protección de datos \- IAPP, fecha de acceso: mayo 8, 2026, [https://iapp.org/news/a/uruguay-dicta-nuevas-normas-sobre-proteccion-de-datos](https://iapp.org/news/a/uruguay-dicta-nuevas-normas-sobre-proteccion-de-datos)  
10. Guía básica de anonimización, fecha de acceso: mayo 8, 2026, [https://www.aepd.es/documento/guia-basica-anonimizacion.pdf](https://www.aepd.es/documento/guia-basica-anonimizacion.pdf)  
11. Guía sobre Anonimización de Datos \- GUB.UY, fecha de acceso: mayo 8, 2026, [https://www.gub.uy/agencia-gobierno-electronico-sociedad-informacion-conocimiento/sites/agencia-gobierno-electronico-sociedad-informacion-conocimiento/files/documentos/publicaciones/Gu%C3%ADa%20sobre%20Anonimizaci%C3%B3n%20de%20Datos%20vf.pdf](https://www.gub.uy/agencia-gobierno-electronico-sociedad-informacion-conocimiento/sites/agencia-gobierno-electronico-sociedad-informacion-conocimiento/files/documentos/publicaciones/Gu%C3%ADa%20sobre%20Anonimizaci%C3%B3n%20de%20Datos%20vf.pdf)  
12. Guía introductoria a la anonimización de datos, fecha de acceso: mayo 8, 2026, [https://wikiguias.digital.gob.cl/documentos/gui%CC%81a\_anonimizacion\_de\_datos.pdf](https://wikiguias.digital.gob.cl/documentos/gui%CC%81a_anonimizacion_de_datos.pdf)  
13. Guía de Anonimización de Datos Estructurados \- Archivo General de la Nación, fecha de acceso: mayo 8, 2026, [https://www.archivogeneral.gov.co/sites/default/files/Estructura\_Web/5\_Consulte/Recursos/Publicacionees/Guia\_de\_Anonimizacion-min.pdf](https://www.archivogeneral.gov.co/sites/default/files/Estructura_Web/5_Consulte/Recursos/Publicacionees/Guia_de_Anonimizacion-min.pdf)  
14. ISO/IEC 20889 \- Privacy enhancing data deidentification terminology and classification of techniques \- Standards | GlobalSpec, fecha de acceso: mayo 8, 2026, [https://standards.globalspec.com/std/10267481/iso-iec-20889](https://standards.globalspec.com/std/10267481/iso-iec-20889)  
15. Classification of identifier between ISO/IEC 20889 and NIST IR 8053 \- ResearchGate, fecha de acceso: mayo 8, 2026, [https://www.researchgate.net/figure/Classification-of-identifier-between-ISO-IEC-20889-and-NIST-IR-8053\_tbl1\_366764396](https://www.researchgate.net/figure/Classification-of-identifier-between-ISO-IEC-20889-and-NIST-IR-8053_tbl1_366764396)  
16. SP 800-188, De-Identifying Government Datasets | CSRC, fecha de acceso: mayo 8, 2026, [https://csrc.nist.gov/pubs/sp/800/188/2pd](https://csrc.nist.gov/pubs/sp/800/188/2pd)  
17. NIST Publishes SP 800-188 | CSRC, fecha de acceso: mayo 8, 2026, [https://csrc.nist.gov/News/2023/nist-publishes-sp-800-188](https://csrc.nist.gov/News/2023/nist-publishes-sp-800-188)  
18. SP 800-188, De-Identifying Government Data Sets | CSRC, fecha de acceso: mayo 8, 2026, [https://csrc.nist.gov/pubs/sp/800/188/3pd](https://csrc.nist.gov/pubs/sp/800/188/3pd)  
19. The Anonymisation Decision-making Framework, fecha de acceso: mayo 8, 2026, [https://fpf.org/wp-content/uploads/2016/11/Brussels-Symposium-08-11-2016-v4.pdf](https://fpf.org/wp-content/uploads/2016/11/Brussels-Symposium-08-11-2016-v4.pdf)  
20. Prototype – An introduction to the UKAN Anonymisation Decision-Making Framework, fecha de acceso: mayo 8, 2026, [https://theodi.github.io/anonymisation.learndata.info/](https://theodi.github.io/anonymisation.learndata.info/)  
21. ARX – Data Anonymization Tool – A comprehensive software for privacy-preserving microdata publishing, fecha de acceso: mayo 8, 2026, [https://arx.deidentifier.org/](https://arx.deidentifier.org/)  
22. ARX \- A Comprehensive Tool for Anonymizing Biomedical Data \- PMC, fecha de acceso: mayo 8, 2026, [https://pmc.ncbi.nlm.nih.gov/articles/PMC4419984/](https://pmc.ncbi.nlm.nih.gov/articles/PMC4419984/)  
23. Configuration – ARX – Data Anonymization Tool, fecha de acceso: mayo 8, 2026, [https://arx.deidentifier.org/anonymization-tool/configuration/](https://arx.deidentifier.org/anonymization-tool/configuration/)  
24. Overview – ARX – Data Anonymization Tool, fecha de acceso: mayo 8, 2026, [https://arx.deidentifier.org/overview/](https://arx.deidentifier.org/overview/)  
25. Amnesia \- Anonymize your data before publishing, fecha de acceso: mayo 8, 2026, [https://datamanagement.univie.ac.at/fileadmin/user\_upload/p\_phaidraservice/Amnesia.pdf](https://datamanagement.univie.ac.at/fileadmin/user_upload/p_phaidraservice/Amnesia.pdf)  
26. Amnesia \- Anonymize your data before publishing \- OpenAIRE, fecha de acceso: mayo 8, 2026, [https://www.openaire.eu/amnesia-guide](https://www.openaire.eu/amnesia-guide)  
27. dTsitsigkos/Amnesia \- GitHub, fecha de acceso: mayo 8, 2026, [https://github.com/dTsitsigkos/Amnesia](https://github.com/dTsitsigkos/Amnesia)  
28. Amnesia, fecha de acceso: mayo 8, 2026, [https://wiki.geant.org/download/attachments/121345970/8\_Amnesia.pdf?version=1\&modificationDate=1564398006779\&api=v2](https://wiki.geant.org/download/attachments/121345970/8_Amnesia.pdf?version=1&modificationDate=1564398006779&api=v2)  
29. Protecting Sensitive Data in the Age of AI with Microsoft Presidio \- Zionclouds, fecha de acceso: mayo 8, 2026, [https://zionclouds.com/popular-blogs/protecting-sensitive-data-in-the-age-of-ai-with-microsoft-presidio](https://zionclouds.com/popular-blogs/protecting-sensitive-data-in-the-age-of-ai-with-microsoft-presidio)  
30. (PDF) Enterprise-Scale PII De-Identification with Microsoft Presidio Anonymizer: Architecture, Use Cases, and Best Practices \- ResearchGate, fecha de acceso: mayo 8, 2026, [https://www.researchgate.net/publication/399570056\_Enterprise-Scale\_PII\_De-Identification\_with\_Microsoft\_Presidio\_Anonymizer\_Architecture\_Use\_Cases\_and\_Best\_Practices](https://www.researchgate.net/publication/399570056_Enterprise-Scale_PII_De-Identification_with_Microsoft_Presidio_Anonymizer_Architecture_Use_Cases_and_Best_Practices)  
31. Microsoft Presidio: An Open Source Tool Specialized in Personal Information Protection, fecha de acceso: mayo 8, 2026, [https://developer.mamezou-tech.com/en/blogs/2025/01/04/presidio-intro/](https://developer.mamezou-tech.com/en/blogs/2025/01/04/presidio-intro/)  
32. Microsoft Presidio: an engineer's introduction to PII detection and de ..., fecha de acceso: mayo 8, 2026, [https://medium.com/neural-engineer/microsoft-presidio-an-engineers-introduction-to-pii-detection-and-de-identification-6a7c3fed6e50](https://medium.com/neural-engineer/microsoft-presidio-an-engineers-introduction-to-pii-detection-and-de-identification-6a7c3fed6e50)  
33. PII detection evaluation \- Microsoft Presidio, fecha de acceso: mayo 8, 2026, [https://microsoft.github.io/presidio/evaluation/](https://microsoft.github.io/presidio/evaluation/)  
34. Custom text classification evaluation metrics \- Foundry Tools | Microsoft Learn, fecha de acceso: mayo 8, 2026, [https://learn.microsoft.com/en-us/azure/ai-services/language-service/custom-text-classification/concepts/evaluation-metrics](https://learn.microsoft.com/en-us/azure/ai-services/language-service/custom-text-classification/concepts/evaluation-metrics)  
35. Evaluating the accuracy of automated and semi-automated anonymization tools for unstructured health records \- PMC, fecha de acceso: mayo 8, 2026, [https://pmc.ncbi.nlm.nih.gov/articles/PMC12477974/](https://pmc.ncbi.nlm.nih.gov/articles/PMC12477974/)  
36. Comparison of recall, precision and F1 scores for Presidio and Philter. \- ResearchGate, fecha de acceso: mayo 8, 2026, [https://www.researchgate.net/figure/Comparison-of-recall-precision-and-F1-scores-for-Presidio-and-Philter\_tbl1\_394212470](https://www.researchgate.net/figure/Comparison-of-recall-precision-and-F1-scores-for-Presidio-and-Philter_tbl1_394212470)  
37. Membership inference attack on differentially private block coordinate descent \- PMC, fecha de acceso: mayo 8, 2026, [https://pmc.ncbi.nlm.nih.gov/articles/PMC10588713/](https://pmc.ncbi.nlm.nih.gov/articles/PMC10588713/)  
38. Privacy-Preserving Machine Learning Techniques: Cryptographic Approaches, Challenges, and Future Directions \- MDPI, fecha de acceso: mayo 8, 2026, [https://www.mdpi.com/2076-3417/16/1/277](https://www.mdpi.com/2076-3417/16/1/277)  
39. Privacy-Preserving in Federated Learning: A Comparison between Differential Privacy and Homomorphic Encryption across Different Scenarios | IEEE Conference Publication, fecha de acceso: mayo 8, 2026, [https://ieeexplore.ieee.org/document/10962468/](https://ieeexplore.ieee.org/document/10962468/)  
40. Top 8 Data Anonymization Tools: Safeguarding Sensitive Data \- GoReplay, fecha de acceso: mayo 8, 2026, [https://goreplay.org/blog/data-anonymization-tools-20250808133113/](https://goreplay.org/blog/data-anonymization-tools-20250808133113/)  
41. 3.2 Anonimización | Unidad Reguladora y de Control de Datos Personales \- GUB.UY, fecha de acceso: mayo 8, 2026, [https://www.gub.uy/unidad-reguladora-control-datos-personales/comunicacion/publicaciones/guia-criterios-disociacion-datos-personales/capitulo-3-etapas-del-0](https://www.gub.uy/unidad-reguladora-control-datos-personales/comunicacion/publicaciones/guia-criterios-disociacion-datos-personales/capitulo-3-etapas-del-0)

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAsAAAAXCAYAAADduLXGAAAA4ElEQVR4XuXSscuBURTH8aM3RaGU0SBRMvoDjDYbo+H9BwwsVtnEZDOaRcqsjDaTRcnkD3gtNr7Hvbd0n0dW9f7qU88959a99/SIfGUiyCDtN/wM8Yc7ul4vNA1cUfUbYZngiKzf8JPCFmvEvF4gZVzQs2t9bAk1xN0mlxZuYppRDDDCSkIe7O5bQB8VMZsC09G57rDHVMyVNHqNDhJ2/czryIo4YClvHuqPbCbmJD2xjl9blyQ2mIt5mEY361qnMEbe1iWHM9quQJo4YWHrOsZn9EOP+3EFGz3x4w/1f/MAmBojHto7TqYAAAAASUVORK5CYII=>

[image2]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABEAAAAYCAYAAAAcYhYyAAABGElEQVR4Xu3SsUsCYRjH8SdCsCEtokWiWYQGHQwaWpxCCBFpDZoUoaUQl0T8F9qSlmanIiSCwH8gaNa2jCAIpH+g73P3vvGYDo4N94MPer+7e7h73xOJEmXxJFHEtjuOIY+y6ZaQxpH71ePfrOIKbbziGLeo4gJjHKKLFk4wxLmYHKCGLD7xiDV3LoUR3rDrOs0NniR8gCB1CQdU8I2CP0EyeEfTdHqjDuhJ+NpTucQLNk1XwgT7pvODT00XJIGBzE7Xwfr+W6bTmz+wY7ogfvqZ6eY99gr6jv5viFkrvx7zHtsO1q3V3dKN0K2/FrO4HTxjwxcSfjdf2DOd3nCPB9whZ85J3F1gs4x1+fNRuV4Xf2ZnovzH/AAy5i321bVWKAAAAABJRU5ErkJggg==>

[image3]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABgAAAAVCAYAAABc6S4mAAABpUlEQVR4Xu2UPSjGURTGj6QYfIWSJPlKRmVVDEoSidHAZqFYDEoyKB+TLAzq3ZTIx6yMNlIWJQmLpEgZFM/zv+dwO69F/cf3qV+995z73nvPc877iuT0T+WBSlDuE2loGbyCLzDjcqlpGLyBTp9IS+vgGtT6RBoqAafgGBS6XCpqA49gVtdseCvoAUUaqwF9oELXfEg3GIhi+aADDIE6jSUaBR8SDiwAi2AVHEhoOm3bBivgAoyDQ/2eWdsFdsGU8iCRbFMTWADtEg62qZoAvRIq+ARbEh5C8cXP4BzUa6wYnOjnZO7PdMOmBLsoWjQNysC8BIvmwD1o0T0Uq34Hg1GMFfPBicz/Jw3SnlJLRqLnHAI/COzbHWiMYryUv6tE8fw3gyuwL9nTxFfdgKUoZpfSDtpCcUA2wKVt8vOfkWAZresHYxo3K9gHk1kRX1ot4XBe8tMMdt+axgu45niugQaN0/+/rPCXcnRfNJd0/RZM/uZlRIIVexpnyZzvHcm2jhPGvfYIilXRgSMu+GVawQNisTL/r8qY7wur5pR5MV7lgzll6RuwrlBlxc1WvAAAAABJRU5ErkJggg==>

[image4]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACoAAAAVCAYAAAAw73wjAAABR0lEQVR4Xu2Vvy5EQRSHj2wkrKz4G4liI0GnURERUVApNGhpxBsgIlRaidAoKBQkHoBC4hGISqWRqHgHvrPHxtxjd+NqZor9kq85505y78zvnhFp0uQXrTiLi9ibbaXDBF7jOq7hAy6FD6TAGF5iV1DbxjvsCGpRacdTHHX1XbzHkqtHYwq3XE1f/haPsMX1orGHM9iGg9iNy2IZHfp5LC6avxOcxlf8/PZD7OdKhmE8FDte3Und0SIe4JXYuKpHj1g8XnK4X1n5DxZwwxfF5qjusH5IEuxI7SPW+fmO474Rg2o++30DjvFJaveqaFz6xOLyVzVeudFj1Zuo09XL+CyW00ajSfM7jys5nKyszInm802yi3V+nuGNZG+pqOj8XBW7fS7wHB9xU+yFkyDMZwEHxPLW6KijEM7PpKk3P5NjDkd8MTW+AD/PNV4BhqkGAAAAAElFTkSuQmCC>

[image5]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACQAAAAVCAYAAAAuJkyQAAAB7ElEQVR4Xu2WTyhFQRTGj6Qof0Mk6SXKnxVLC0sbSYqNsrCwULKgsGAhO1GKlbIR2YgUS8pSSpRESrKwsRBSlOL73sy85k335c59b6N89as753gzc86cM0PkX39cWaAMlLiOCCoAFSDbdYTVPHgF32Dc8fmoGVyLmucClCe7/dQL3kC76/AUM3wCNkVlPbKWwS2odh2eagKPYNh1+KgQHIN9kOv4fDUgGci0iWpKj5nqBtAB8swfhRQz7VM/LHw2QMw2MqoPURvIAXNgAeyJX5Gb+tkWNU8Y1YAlsGsbTf3UgVnQKmojvl2XTv0wGXGZqM7BqqhJKR7ZGMjX4zBKp36mzYeJ6klUlnhcRcbpKd/6MWIjsaHisu+fenAl6jx9uy1K/RjxqrkzA/f+WRc1MRfoAoPaTvFJ4PMSdOHZ9dMIZiyf6aRUQbJ+3vnBBY4kOSpuiGO2+yKo1fZScAZeQJu22eoU5WOmR0C/5RsCX2BLgrPHIB74EQP3YNRy9olK3462m2xw8wfgE0xomy1m4BQcgg1QbPm6wTO4AVWW3YgNdMkPLsajcV9lLp7q1Wd67QBsMXpuLCgLPK4VUOk6tIJ+E0qTEnxkv4lHzxKIvHCQWsCa+D8nPAFuJnH5ZUqshSj/DbBueiS4OxP6AQ3OU6TI/3COAAAAAElFTkSuQmCC>

[image6]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAAYCAYAAADH2bwQAAAAhUlEQVR4XmNgGAW4ACsQS0AxiA0H/EA8GYifAvEGIJ4KxBowSQUgvgbEc4GYEyYIAyBjVgHxPSBWQpMDAy0gfgbEn4D4LhKOhikwBeK3QFwBE0AHhkD8mgGPApCjNjFA3AHzFiMQc8NVAIEkEG8D4v1APBuIDwJxLQNaOIAALwOWABr6AAATDROo9oIsPQAAAABJRU5ErkJggg==>