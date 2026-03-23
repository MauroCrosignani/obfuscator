# Documento de Especificación de Requerimientos: "ObfuscatoR"
**Versión:** 2.0  
**Estado:** Vigente y alineado con la implementación observada al 21 de marzo de 2026  
**Autor:** Codex, a partir de la especificación original y de la evolución efectiva del proyecto

---

## 1. Visión Estratégica (El "Porqué")
### 1.1 El Problema Humano
Los equipos de análisis de datos en organismos públicos necesitan aprovechar herramientas de IA sin exponer información protegida por secreto tributario, fiscal, estadístico o administrativo. La construcción manual de datasets ficticios consume tiempo, introduce errores y degrada la utilidad analítica del material usado para consultar, prototipar o depurar código.

ObfuscatoR existe para resolver esa fricción mediante una plataforma local en R que transforme datasets sensibles en datasets ofuscados, auditables y suficientemente fieles para soportar análisis exploratorios, generación de código asistida por IA y validaciones funcionales.

### 1.2 Valores y Principios Guía
* **Privacidad por Diseño:** La transformación debe ejecutarse localmente, sin enviar datos a servicios remotos de procesamiento.
* **Auditabilidad Explícita:** La ofuscación debe dejar huellas verificables, visibles y trazables para facilitar revisión humana y control posterior.
* **Paridad Operativa:** El resultado debe conservar nombres de columnas, clases, cardinalidades e invariantes útiles para que el código generado sobre datos ofuscados sea aplicable al dataset original.
* **UX para Usuarios Hispanoparlantes:** La solución debe priorizar mensajes, documentación y flujos comprensibles en español.
* **Gradualidad de Privacidad:** La solución debe cubrir tanto ofuscación analítica como un modelo formal opcional de `k-anonymity`, sin confundir ambos niveles.
* **Reproducibilidad:** La configuración, la clasificación de variables y los criterios de privacidad deben poder reusarse y auditarse.

### 1.3 Métricas de Éxito (KPIs)
1. **Fidelidad Estructural:** 0 diferencias no justificadas en nombres de columnas, tipos base y cantidad de columnas cuando no se usen exclusiones explícitas.
2. **Fidelidad Analítica Operativa:** El código de manipulación usual en R (`dplyr`, `tidyr`, agregaciones, joins, filtros y gráficos exploratorios) debe ejecutarse sobre los datos ofuscados sin necesidad de rediseño.
3. **Tiempo de Preparación:** El usuario debe poder pasar de un dataset sensible a uno ofuscado en segundos o pocos minutos, sin edición manual fila a fila.
4. **Auditabilidad:** Toda transformación relevante debe quedar reflejada en un log o reporte de privacidad suficiente para revisión posterior.
5. **Usabilidad Local:** La solución debe ser utilizable tanto por script como por interfaz Shiny, sin requerir conocimientos avanzados para tareas comunes.

---

## 2. Terreno de Juego (Restricciones y Supuestos)
### 2.1 Restricciones Técnicas
* **Entorno objetivo principal:** R / RStudio / RStudio Server en entornos locales o institucionales.
* **Ejecución:** 100% local para el procesamiento de datos.
* **Tecnología principal:** paquete/script en R con interfaz Shiny opcional.
* **Formatos de entrada soportados en la interfaz:** `csv`, `xls`, `xlsx`, `rds`, además de objetos `data.frame` o `tibble` del entorno global.
* **Límite práctico de carga en navegador:** 300 MB configurados en Shiny; para volúmenes mayores se debe permitir la carga previa en el entorno global.
* **Inferencia de tipos en archivos tabulares:** la lectura de CSV y Excel debe usar `guess_max = 100000`.

### 2.2 Supuestos Operativos
* El usuario posee permisos para leer el dataset original dentro del entorno local.
* El usuario puede revisar y corregir la detección automática de roles de variables.
* El usuario comprende que la ofuscación no equivale automáticamente a anonimización formal.
* La persistencia de configuraciones y plantillas se realiza sobre el esquema del dataset, no sobre una semántica universal del dominio.

### 2.3 Restricciones de Seguridad
* No deben persistirse claves sensibles de cifrado reversible si el diseño las considera secretas.
* Los logs y artefactos auxiliares que incluyan mappings o claves enmascarables deben tratarse como material restringido.
* Las dependencias remotas de front-end deben considerarse una deuda o riesgo a explicitar cuando contradigan el ideal de funcionamiento totalmente offline.

### 2.5 Hallazgos de Migracion a Entorno Corporativo
De acuerdo con las pruebas manuales realizadas mediante `pruebas_migracion_gitlab.R`, la siguiente version del producto debe asumir:
* el host de R puede no tener salida directa a internet aunque el navegador del usuario si logre cargar ciertos recursos remotos;
* las dependencias por CDN pueden funcionar en algunos casos, pero no deben considerarse confiables para una distribucion corporativa;
* `JavaScript` inline, `drag and drop` HTML5 y `downloadHandler` resultan viables en el entorno probado;
* `navigator.clipboard` no debe tratarse como capacidad garantizada y requiere fallback manual;
* los assets locales servidos por Shiny constituyen el camino preferente para endurecer la app.

### 2.4 Restricciones de Diseño y Alcance
* La detección automática de roles es heurística y no reemplaza una clasificación semántica explícita.
* El modelo formal de privacidad vigente es `k-anonymity`; no forman parte del alcance obligatorio actual `l-diversity` ni `t-closeness`.
* La reversibilidad es parcial y depende del método aplicado a cada columna.

---

## 3. Gobernanza (Matriz RACI)
* **Aprobador (A):** Responsable funcional o metodológico del uso del dataset ofuscado.
* **Responsable (R):** Plataforma ObfuscatoR, incluyendo motor de ofuscación, configuración, persistencia y app Shiny.
* **Consultado (C):** Seguridad de la Información, Auditoría, Gobierno de Datos y eventualmente responsables legales.
* **Informado (I):** Analistas consumidores del dataset ofuscado, equipos de IA y revisores del proceso.

### 3.1 Responsabilidades de la Solución
La solución debe:
* validar configuraciones de entrada;
* detectar o aceptar roles de columnas;
* aplicar transformaciones consistentes con la configuración;
* devolver datos operativos y auditables;
* ofrecer una interfaz gráfica suficiente para usuarios no programadores;
* permitir reuso de configuraciones mediante persistencia por esquema.

### 3.2 Responsabilidades del Usuario
El usuario debe:
* verificar que la clasificación automática de columnas sea correcta;
* definir cuasi-identificadores cuando active `k-anonymity`;
* custodiar logs, mappings y archivos exportados conforme a la política institucional;
* decidir conscientemente si se usarán exclusiones, preservaciones o modos reversibles.

---

## 4. Comportamientos Clave (El "Qué")
### 4.1 Contrato General
La solución debe aceptar como entrada un `data.frame` o `tibble` y producir un objeto tabular equivalente en estructura operativa, salvo que la configuración indique exclusiones explícitas.

### 4.2 API y Modos de Consumo
La solución debe ofrecer al menos estos modos de uso:
1. **Como script compatible con flujos heredados** mediante `source("obfuscator.R")`.
2. **Como paquete R** con funciones exportadas y estructura `R/`, `DESCRIPTION` y `NAMESPACE`.
3. **Como aplicación Shiny** para operación visual.

Las funciones públicas mínimas esperadas son:
* `obfuscator_config()`
* `detect_column_roles()`
* `obfuscate_dataset()`
* `obfuscate_csv()`
* `revert_reversible_ids()`
* `run_obfuscator_app()`

### 4.3 Clasificación de Roles de Variables
La solución debe soportar los roles:
* `id`
* `date`
* `categorical`
* `numeric`
* `preserve`
* `exclude`

La solución debe permitir:
* detección automática heurística;
* declaración explícita de roles;
* corrección manual vía interfaz gráfica;
* persistencia y recuperación de la clasificación basada en hash de esquema;
* sugerencias fuzzy para datasets similares con nombres parcialmente cambiados.

### 4.4 Ofuscación de Identificadores
La solución debe:
* mapear identificadores de forma determinista dentro de la ejecución;
* preservar cardinalidad y consistencia intra-dataset;
* soportar IDs numéricos y alfanuméricos;
* permitir prefijos evidentes de auditoría;
* permitir estabilidad determinística entre ejecuciones mediante `project_key` cuando se configure;
* soportar, en ciertos escenarios, desfases reversibles sobre columnas numéricas.

### 4.5 Ofuscación de Fechas
La solución debe:
* permutar fechas preservando el conjunto de valores observados;
* preservar `NA`;
* conservar la clase de fecha/fecha-tiempo cuando corresponda;
* permitir reglas posteriores de consistencia para restaurar relaciones ordenadas entre columnas.

### 4.6 Ofuscación de Variables Categóricas
La solución debe:
* permutar o reasignar categorías preservando frecuencias;
* soportar `character` y `factor`;
* mantener estructura útil para agrupaciones, resúmenes y tablas;
* admitir generalización adicional si se activa `k-anonymity`.

### 4.7 Ofuscación de Variables Numéricas
La solución debe soportar al menos los modos:
* `range_random`
* `preserve_rank`
* `permute`
* `additive_offset`

Además, debe:
* permitir un modo general y modos específicos por columna;
* preservar signo, tipo, `NA`, `Inf`, `-Inf` y `NaN` cuando aplique;
* evitar coerciones erróneas en columnas `double` con rangos grandes;
* mantener columnas enteras como enteras cuando la columna original lo sea.

### 4.8 Reglas de Consistencia
La solución debe soportar reglas de consistencia configurables post-ofuscación.

Como mínimo, debe soportar la regla:
* `ordered`: asegurar `lower <= upper` por fila mediante intercambio controlado de valores.

La solución debe registrar en el log cuántas filas fueron ajustadas por cada regla aplicada.

### 4.9 Modelo Formal de Privacidad Opcional
La solución debe soportar un `privacy_model` opcional con:
* `type = "k_anonymity"`
* `k`
* `quasi_identifiers`
* `suppression`
* `hierarchies`

El modelo debe:
* medir riesgo antes y después;
* aplicar generalización progresiva;
* soportar jerarquías predefinidas y personalizadas;
* permitir supresión residual;
* registrar un `privacy_report` auditable.

### 4.10 Reversibilidad y Persistencia
La solución debe distinguir entre:
* transformaciones reversibles;
* transformaciones no reversibles;
* configuraciones persistibles;
* secretos que no deben persistirse.

Debe existir soporte para:
* reversión de offsets reversibles cuando se cuente con claves;
* persistencia de roles y jerarquías en JSON;
* recuperación aproximada de configuraciones por hash de esquema y fuzzy matching.

### 4.11 Logging y Auditoría
La solución debe adjuntar un log enriquecido cuando `log = TRUE`, incluyendo al menos:
* fecha y hora;
* versión del paquete;
* semilla;
* dimensiones del dataset;
* roles aplicados;
* modos numéricos;
* reglas de consistencia;
* transformaciones por columna;
* `privacy_report` cuando corresponda.

### 4.12 Interfaz Gráfica
La app Shiny debe funcionar como subsistema propio y no solo como accesorio.

Debe permitir:
* elegir fuente de datos;
* cargar archivos o seleccionar objetos del entorno;
* visualizar el estado del dataset;
* revisar la clasificación de variables;
* mover variables entre zonas con drag and drop;
* ver advertencias visuales;
* configurar ofuscación y `k-anonymity`;
* lanzar el proceso con feedback de avance;
* previsualizar el resultado;
* guardar el resultado en entorno y descargar CSV;
* guardar y cargar plantillas;
* generar código R reproducible.

### 4.13 UX y Accesibilidad
La solución debe priorizar:
* idioma español;
* mensajes claros;
* doble codificación visual cuando haya alertas;
* feedback de progreso por etapas;
* tolerancia a datasets medianos o anchos;
* corrección manual de heurísticas sin escribir código.

### 4.14 Requerimientos para la Version Corporate-Safe
La próxima versión orientada a GitLab corporativo debe:
* eliminar la dependencia operativa de `Font Awesome` y `SortableJS` servidos por CDN, reemplazándolos por assets locales bajo `www/`;
* mantener la experiencia visual y funcional principal aun cuando no exista acceso saliente a internet desde el host de R;
* tratar la funcionalidad de copiado al portapapeles como opcional, con fallback visible y seleccionable por el usuario;
* conservar compatibilidad con `JavaScript` inline y con interacciones de `drag and drop` cuando el navegador las permita;
* reemplazar o desacoplar badges remotos del `README` por una variante apta para GitLab corporativo;
* documentar explícitamente qué capacidades requieren navegador moderno y cuáles quedan cubiertas completamente offline.

---

## 5. Especificación Ejecutable (Casos de Prueba)

### 5.1 Casos de Uso Óptimos (Fidelidad para la IA y para el Analista)
La solución debe considerarse satisfactoria si soporta, al menos, estos 20 casos:

1. **Join por IDs ofuscados:** unir tablas transformadas debe preservar la cantidad esperada de matches.
2. **Agrupación por categorías:** `group_by() %>% summarise()` debe mantener estructura de salida útil.
3. **Filtros numéricos:** condiciones sobre montos, saldos o conteos deben seguir siendo operables.
4. **Ordenamientos:** `arrange()` sobre numéricas ofuscadas debe seguir siendo funcional.
5. **Uso de fechas en series temporales:** agrupaciones por año, mes o trimestre deben seguir funcionando.
6. **Conteo de nulos:** `sum(is.na())` debe ser equivalente.
7. **Detección de duplicados:** `distinct()` y conteos de cardinalidad deben seguir siendo consistentes.
8. **Gráficos exploratorios:** histogramas, barras y series deben conservar forma operativa razonable.
9. **Validación de clases:** `class()`, `is.numeric()`, `is.character()`, `inherits(..., "Date")` deben mantenerse.
10. **Permutación categórica con frecuencias preservadas:** tablas de frecuencia deben conservar distribución.
11. **Consistencia temporal post-ofuscación:** pares como `FECHA_INICIO` y `FECHA_FIN` deben poder corregirse.
12. **Consistencia numérica post-ofuscación:** pares como `MINIMO` y `MAXIMO` deben poder corregirse.
13. **Aplicación de modos numéricos por columna:** una columna puede usar `preserve_rank` y otra `range_random`.
14. **Cálculo de rankings:** funciones como `dense_rank()` deben seguir siendo aplicables.
15. **Análisis con dataset de una fila:** no debe romper tipos ni lanzar errores.
16. **Aplicación de `k-anonymity`:** debe generalizar o suprimir según configuración y devolver reporte.
17. **Persistencia de clasificación:** una plantilla guardada debe poder reutilizarse en un dataset compatible.
18. **Corrección visual manual:** el usuario debe poder reclasificar variables en la app sin editar código.
19. **Generación de código reproducible:** la app debe poder producir un script base equivalente a la configuración aplicada.
20. **Integración con flujo legacy:** `source("obfuscator.R")` debe seguir siendo utilizable.

### 5.2 Casos Límite (Robustez y Seguridad)
La solución debe contemplar al menos estos 20 casos:

1. **Dataset vacío:** no debe fallar.
2. **Columnas 100% `NA`:** deben preservarse intactas.
3. **IDs alfanuméricos:** deben soportarse sin pérdida de cardinalidad.
4. **Valores `Inf`, `-Inf`, `NaN`:** deben conservarse correctamente.
5. **Rangos numéricos enormes:** no deben provocar generación de secuencias inviables ni coerciones incorrectas.
6. **Dataset de una sola fila:** el proceso no debe romperse.
7. **Columnas con muy pocos únicos:** pueden requerir reclasificación heurística como categóricas.
8. **Factores:** deben manejarse sin degradación funcional.
9. **Columnas con espacios en el nombre:** deben soportarse en jerarquías y privacidad.
10. **`k` imposible de satisfacer:** el sistema debe generalizar y/o suprimir según política, y reportarlo.
11. **Jerarquías personalizadas incompletas:** deben manejarse sin colapso total del proceso.
12. **Mappings duplicados o vacíos:** el motor de generalización debe tolerarlos razonablemente.
13. **RDS no tabular:** la app debe rechazarlo con error claro.
14. **Objeto del entorno no tabular:** la app debe rechazarlo con error claro.
15. **Archivo no soportado:** la app debe rechazarlo con error claro.
16. **Variables `character` con apariencia de fecha:** la app debe advertirlo visualmente.
17. **Archivos grandes en navegador:** la app debe advertir la limitación y proponer el uso del entorno global.
18. **Persistencia con esquema parecido pero no idéntico:** deben existir sugerencias fuzzy, no reasignación ciega.
19. **Logs con datos sensibles derivados:** deben considerarse artefactos restringidos.
20. **Dependencias de UI no disponibles offline:** debe documentarse el riesgo y contemplarse endurecimiento futuro.

### 5.3 Evidencia de Verificación Esperada
Los requerimientos anteriores deben poder validarse mediante una combinación de:
* tests automáticos en `tests/`;
* validaciones manuales de la app;
* ejemplos reproducibles en `README` y `vignettes`;
* revisión de logs y reportes.

### 5.4 Estado de Implementación por Área
Para efectos de control del alcance, cada funcionalidad debe clasificarse como:
* **Implementada y testeada**
* **Implementada con validación manual predominante**
* **Documentada pero con evidencia automatizada insuficiente**

Aplicación inicial sobre el estado actual:
* **Implementada y testeada:** core de ofuscación, validación de configuración, modos numéricos, reglas `ordered`, `k-anonymity` base, persistencia por esquema, carga legacy y log enriquecido.
* **Implementada con validación manual predominante:** gran parte de la UX Shiny, editor visual de jerarquías, flujo visual de persistencia, advertencias visuales, copy-to-clipboard y parte del estudio interactivo.
* **Documentada pero con evidencia automatizada insuficiente:** algunas capacidades avanzadas del “Studio”, endurecimiento offline total, cobertura integral de accesibilidad y performance formal con umbrales automatizados.

---

## 6. Artefactos de Salida y Evolución
### 6.1 Artefactos de Salida Esperados
1. **Dataset ofuscado:** objeto tabular utilizable en R y exportable a CSV.
2. **Log de auditoría:** atributo `obfuscator_log` con trazabilidad de la ejecución.
3. **Reporte de privacidad:** `privacy_report` cuando se use `k-anonymity`.
4. **Plantillas JSON:** persistencia de roles, sugerencias y jerarquías basadas en esquema.
5. **Script reproducible:** código R generado por la app para reconstruir la configuración aplicada.
6. **App Shiny operativa:** interfaz gráfica para usuarios no programadores.

### 6.2 Artefactos Efímeros o Restringidos
Se consideran especialmente sensibles:
* mappings reversibles completos;
* claves manuales de offset o cifrado reversible;
* logs que permitan inferir equivalencias directas con datos reales.

Estos artefactos no deben persistirse automáticamente salvo decisión explícita, informada y segura.

### 6.3 Evolución del Producto
Cualquier ampliación funcional relevante debe acompañarse de:
* actualización de esta especificación;
* actualización de documentación de uso;
* revisión de casos de uso y casos límite impactados;
* ampliación de tests o plan manual según corresponda.

Se consideran líneas de evolución probables:
* reglas de consistencia más expresivas;
* separación explícita entre “ofuscación analítica” y “anonimización formal”;
* formalización adicional de API pública;
* reducción de dependencias remotas de la UI;
* tests end-to-end de Shiny y performance con umbrales.

### 6.5 Criterios de Aceptacion para la Variante GitLab Corporativa
Se considerará aceptable la variante corporativa cuando:
* la suite automática del repositorio siga en verde;
* la app Shiny pueda ejecutarse sin depender de CDN para su funcionalidad principal;
* el flujo de carga, clasificación, ofuscación y descarga se mantenga operativo en entorno corporativo;
* el `README` quede preparado para GitLab corporativo con badges y referencias apropiadas;
* la nueva documentación deje claro qué funcionalidades tienen fallback y cuáles son completamente autosuficientes.

### 6.4 Criterio de Cambio Controlado
No debería modificarse la lógica principal de ofuscación, persistencia, privacidad o UI crítica sin:
* revisar compatibilidad con el runner de tests;
* validar coherencia con `README`, `vignettes` y especificación;
* reevaluar riesgos de filtración, pérdida de estructura o falsas garantías de anonimización.

---

# Anatomía de esta Especificación
*¿Por qué esta versión 2.0 es necesaria?*

1. **Respeta el documento original:** conserva la macroestructura estratégica, operativa y ejecutable de la v1.0.
2. **Refleja el producto real:** ya no describe solo un script, sino una plataforma local con motor, privacidad formal, persistencia, auditoría y Studio Shiny.
3. **Distingue niveles de madurez:** separa lo testeado, lo validado manualmente y lo que aún requiere endurecimiento contractual.
4. **Protege contra sobrepromesas:** reconoce límites reales, especialmente en reversibilidad, anonimización formal, accesibilidad y dependencia offline.
5. **Sirve como documento puente:** permite gobernar roadmap, validación y auditoría sin perder el foco original de utilidad práctica para trabajo con IA.

---

## Anexo A. Matriz Resumida de Requerimientos
| ID | Requerimiento | Estado esperado |
| --- | --- | --- |
| RF-01 | Ofuscar datasets tabulares preservando estructura operativa | Obligatorio |
| RF-02 | Soportar IDs, fechas, categóricas y numéricas | Obligatorio |
| RF-03 | Permitir configuración explícita y detección heurística de roles | Obligatorio |
| RF-04 | Soportar reglas de consistencia parametrizadas | Obligatorio |
| RF-05 | Soportar `k-anonymity` como capa opcional | Obligatorio |
| RF-06 | Adjuntar log de auditoría | Obligatorio |
| RF-07 | Permitir uso como script, paquete y app | Obligatorio |
| RF-08 | Persistir clasificación por esquema | Obligatorio |
| RF-09 | Proveer feedback de progreso en la app | Obligatorio |
| RF-10 | Advertir variables sospechosas de fecha mal tipada | Obligatorio |
| RNF-01 | Operar localmente y en español | Obligatorio |
| RNF-02 | Mantener compatibilidad con flujos legacy | Obligatorio |
| RNF-03 | Tratar mappings y claves como artefactos sensibles | Obligatorio |
| RNF-04 | Mantener pipeline de tests y parseo | Obligatorio |
| RNF-05 | Mejorar gradualmente validación UI, performance y offline total | Evolutivo |

## Anexo B. Referencias del Repositorio
Artefactos principales a los que esta especificación se alinea:
* `ESPECIFICACION_DE_REQUERIMIENTOS.md`
* `DETALLES_CASOS_DE_USO_CASOS_LIMITE.md`
* `README.md`
* `DESCRIPTION`
* `R/obfuscator_core.R`
* `R/shiny_app.R`
* `tests/testthat/test_obfuscator.R`
* `tests/test-kanonymity-robust.R`
* `tests/test-hierarchies-core.R`
* `tests/test-persistence.R`
* `docs/manual_testing_plan.md`
* `vignettes/*.Rmd`
