# Documento de Especificacion de Requerimientos: "ObfuscatoR"
**Version:** 3.1  
**Estado:** Documento maestro vigente tras ajuste conceptual posterior al contraste con investigación externa  
**Fecha:** 2026-05-09  
**Autor:** Codex, a partir de la especificacion v2.0/v2.1, la auditoria del estado actual del repositorio, la reformulacion v3.0 y el contraste posterior con investigación normativa y técnica

---

## 1. Vision Estrategica
### 1.1 Proposito Reformulado
ObfuscatoR es una herramienta de liberacion segura de datasets hacia terceros.

Su objetivo principal es transformar datasets sensibles en versiones suficientemente protegidas como para que puedan compartirse fuera del area custodiante sin exponer informacion confidencial sobre personas, empresas u otras unidades de analisis.

En esta definicion:
* la IA es un tercero mas y no recibe un tratamiento mas permisivo que otros destinatarios;
* la utilidad analitica sigue siendo importante, pero queda subordinada a la no divulgacion;
* la app no debe limitarse a "ofuscar" datos, sino gobernar una decision de liberacion;
* si el sistema no puede defender tecnicamente la liberacion, debe bloquear la salida y explicar por que.

### 1.2 Problema Humano
Los equipos de analisis de datos en organismos publicos y otras instituciones con obligaciones de reserva necesitan compartir datos fuera de su area custodiante para fines validos de trabajo:
* colaboracion con otras areas;
* consulta a terceros;
* analisis externo controlado;
* generacion de codigo asistida por IA;
* pruebas funcionales o exploracion metodologica.

La construccion manual de datasets ficticios:
* consume tiempo;
* introduce errores;
* degrada la utilidad analitica;
* dificulta la auditoria;
* y no garantiza por si sola una politica consistente de no divulgacion.

ObfuscatoR existe para reducir esa friccion con una plataforma local en R que combine transformacion, controles de riesgo, evidencia auditable y una decision defendible de liberacion o de bloqueo.

### 1.3 Jerarquia de Prioridades
La solucion debe explicitar esta jerarquia:
1. minimizar el riesgo de reidentificacion y revelacion indebida;
2. dejar trazabilidad y justificacion auditable;
3. preservar utilidad estructural y analitica solo en la medida compatible con 1 y 2.

### 1.4 Valores y Principios Guia
* **Privacidad por diseno:** la transformacion debe ejecutarse localmente.
* **Liberacion defendible:** el sistema no debe permitir liberar datos cuando no puede sostener tecnicamente esa decision.
* **Auditabilidad explicita:** toda decision relevante debe dejar evidencia.
* **Paridad operativa controlada:** la estructura resultante debe seguir siendo util cuando ello no contradiga el objetivo de no divulgacion.
* **Gradualidad de transformaciones:** no toda transformacion equivale a anonimato formal.
* **Conservadurismo frente a terceros:** ante duda material no resuelta, la app debe bloquear.
* **UX para usuarios hispanoparlantes:** mensajes, documentacion y flujos deben ser comprensibles en espanol.
* **Reproducibilidad:** configuraciones, clasificaciones y decisiones de riesgo deben poder revisarse.

### 1.5 Lo que el producto no debe prometer
La solucion no debe afirmar:
* que garantiza seguridad perfecta en cualquier dominio sin criterio institucional;
* que todo dataset sensible puede volverse liberable automaticamente;
* que la utilidad para IA tiene prioridad sobre la proteccion de datos;
* que el cumplimiento de una sola metrica formal equivale por si mismo a seguridad suficiente.

---

## 2. Casos de Uso del Producto
### 2.1 Caso de Uso Principal: Liberacion segura a terceros
Un area custodiante posee un dataset sensible y necesita compartirlo fuera de su ambito de control.

El tercero puede ser:
* otra oficina;
* un equipo metodologico;
* un proveedor;
* una consultora;
* una universidad;
* una IA;
* cualquier actor externo al ambito custodiante.

La solucion debe permitir:
* clasificar variables;
* detectar riesgos;
* aplicar transformaciones;
* reevaluar el riesgo;
* y concluir si la liberacion es defendible o no.

### 2.2 Subcaso de Uso: Preparacion de material para consulta a IA
La IA requiere una muestra de datos o un dataset de referencia para producir codigo, sugerencias o diagnosticos.

Este subcaso:
* queda dentro del caso principal de liberacion a terceros;
* no habilita un estandar de privacidad mas debil;
* y debe tratar a la IA como a cualquier otro destinatario externo.

### 2.3 Caso de Uso Secundario: Preparacion analitica interna
La herramienta puede ofrecer un modo de trabajo interno para preparacion analitica, exploracion o prototipado local.

Sin embargo:
* este modo no debe confundirse con liberacion a terceros;
* no debe heredar automaticamente el derecho a exportar;
* y debe documentarse como un flujo distinto del de liberacion segura.

En este modo:
* puede existir previsualizacion o generacion de artefactos internos de trabajo;
* no debe habilitarse una exportacion externa como si el dataset fuera liberable;
* cualquier pasaje posterior a liberacion a terceros debe obligar a correr el flujo completo de evaluacion y bloqueo.

### 2.4 Caso de Uso Ilustrativo de Alto Riesgo
Una oficina recibe una tabla con informacion de personas, empresas u otras unidades de analisis y debe agregar datos bajo su propia custodia. Luego necesita devolver la tabla enriquecida para estudios de correlacion, cruce o explotacion analitica.

La solucion debe permitir:
* anonimizar o generalizar lo necesario para proteger a la unidad de analisis;
* preservar en lo posible la posibilidad de hacer estudios legitimos;
* impedir una liberacion si la estructura sigue permitiendo inferencias indebidas sobre un caso concreto.

---

## 3. Restricciones y Supuestos
### 3.1 Restricciones Tecnicas
* Entorno objetivo principal: R / RStudio / RStudio Server.
* Ejecucion: local para el procesamiento de datos.
* Tecnologia principal: paquete o script en R con interfaz Shiny.
* Formatos de entrada soportados por la app: `csv`, `xls`, `xlsx`, `rds`, ademas de `data.frame` o `tibble` del entorno global.
* Limite practico de carga en navegador: 300 MB configurados en Shiny.
* Inferencia de tipos en archivos tabulares: lectura de CSV y Excel con `guess_max = 100000`.

### 3.2 Restricciones de Seguridad
* Los secretos, claves manuales y mappings que permitan reconstruccion no deben persistirse sin una decision explicita y segura.
* Los logs y artefactos auxiliares que permitan inferir equivalencias directas deben tratarse como restringidos.
* Toda dependencia de UI que suponga acceso remoto debe considerarse riesgo y deuda de despliegue.
* La capa UI no debe asumir simetria de conectividad entre el proceso R y el navegador.
* Las capacidades del navegador que no sean criticas deben degradarse con fallback visible.

### 3.3 Supuestos Operativos
* El usuario puede revisar y corregir la deteccion automatica de roles.
* El usuario comprende que la revision humana es parte del proceso, pero no reemplaza los controles del sistema.
* El usuario no debe poder "forzar exportacion" cuando el sistema no pueda defender tecnicamente la liberacion.
* La persistencia de configuraciones se realiza sobre el esquema del dataset y no sobre una semantica universal del dominio.

### 3.4 Restricciones de Alcance para esta version
Esta version debe definirse como un producto general, no sectorial.

Por lo tanto:
* debe existir una politica general conservadora;
* no deben prometerse desde el inicio perfiles completos para salud, educacion, tributario u otros dominios;
* si una situacion requiere conocimiento de dominio que el sistema no puede representar de forma defendible, debe bloquear y explicarlo.

---

## 4. Marco Conceptual del Producto
### 4.1 Distincion obligatoria entre transformacion y liberacion
La solucion debe distinguir explicitamente entre:
* transformaciones de ofuscacion analitica;
* anonimización formal;
* controles de riesgo para liberacion;
* decision final de exportacion.

No debe tratarse como equivalentes:
* "dataset transformado";
* "dataset util";
* "dataset liberable".

### 4.2 Piso formal minimo
El piso formal minimo para la liberacion segura debe ser `k-anonymity`.

Sin embargo, cumplir `k-anonymity` no debe bastar por si solo para declarar que el dataset es liberable.

### 4.3 Alcance de la obligatoriedad de `k-anonymity`
La solucion puede seguir soportando `k-anonymity` como una capacidad configurable del motor y de la API general.

Sin embargo, para el caso de uso principal de liberacion a terceros:
* `k-anonymity` deja de ser opcional;
* pasa a ser un requisito obligatorio del flujo de decision;
* y no debe existir un camino de exportacion a terceros que omita esa evaluacion.

### 4.4 Controles adicionales obligatorios
Ademas del piso formal minimo, el sistema debe evaluar:
* columnas de alto riesgo;
* texto libre;
* fechas con granularidad excesiva;
* combinaciones de variables con singularidad riesgosa;
* y otras senales de posible revelacion indebida.

### 4.5 Politica de conservadurismo
Ante una situacion no resuelta, el sistema debe:
* bloquear por defecto;
* sugerir resoluciones seguras cuando existan;
* generar un informe si no existe una resolucion segura defendible.

No debe ofrecer una salida del tipo:
* "liberar igual bajo mi responsabilidad".

### 4.6 Distincion formal entre seudonimizacion y liberacion externa
La solucion debe distinguir explicitamente entre:
* anonimización irreversible o disociacion defendible para liberacion externa;
* seudonimizacion reversible o transformaciones internas con capacidad de reconstruccion;
* y artefactos tecnicamente utiles para trabajo interno, pero insuficientes para compartir a terceros.

Reglas obligatorias:
* la seudonimizacion reversible no debe considerarse liberacion segura a terceros por si sola;
* la existencia de una clave, mapping, offset manual o informacion adicional que permita reconstruir identidades mantiene al artefacto dentro del universo de datos personales o de alto riesgo;
* si el flujo produce un resultado reversible, ese resultado debe quedar tratado como artefacto interno o restringido, no como dataset liberable;
* cualquier afirmacion de liberabilidad debe basarse en la evaluacion del riesgo residual del dataset resultante y no solo en la sustitucion de identificadores directos.

---

## 5. API, Modos de Consumo y Artefactos
### 5.1 Modos de uso
La solucion debe ofrecer al menos:
1. uso como script compatible con flujos heredados;
2. uso como paquete R;
3. uso como aplicacion Shiny.

### 5.2 Funciones publicas minimas esperadas
* `obfuscator_config()`
* `detect_column_roles()`
* `obfuscate_dataset()`
* `obfuscate_csv()`
* `revert_reversible_ids()`
* `run_obfuscator_app()`

### 5.3 Artefactos de salida esperados
1. dataset transformado de trabajo interno cuando el flujo lo permita;
2. log de auditoria;
3. `privacy_report` cuando corresponda;
4. plantillas JSON para persistencia de configuraciones visuales;
5. script reproducible generado por la app;
6. informe de liberacion o de no liberacion.

### 5.4 Distincion obligatoria entre artefactos internos y liberacion externa
La especificacion debe distinguir al menos tres categorias de artefactos:
1. **Artefacto interno de previsualizacion:** resultado parcial o temporal visible solo dentro del flujo de trabajo local.
2. **Artefacto interno de trabajo:** dataset transformado util para exploracion o configuracion, pero no marcado como liberable.
3. **Artefacto liberable a terceros:** dataset cuya exportacion externa queda habilitada porque ya supero todos los controles de liberacion.

Reglas obligatorias:
* un artefacto interno no debe presentarse como liberable;
* la existencia de un dataset transformado no implica derecho de exportacion externa;
* la UI debe diferenciar visualmente los artefactos internos de los liberables;
* si el estado del dataset no es `Liberable`, solo pueden permitirse acciones internas compatibles con ese estado.

### 5.5 Artefactos efimeros o restringidos
Se consideran especialmente sensibles:
* mappings reversibles completos;
* claves manuales de offset o cifrado reversible;
* logs que permitan reconstruccion;
* informes intermedios con datos reveladores;
* configuraciones que contengan secretos efectivos.

---

## 6. Clasificacion de Variables
### 6.1 Roles soportados
La solucion debe soportar al menos estos roles:
* `id`
* `date`
* `categorical`
* `numeric`
* `preserve`
* `exclude`

### 6.2 Requerimientos funcionales de clasificacion
La solucion debe permitir:
* deteccion heuristica inicial;
* declaracion explicita de roles;
* correccion manual por UI;
* persistencia y recuperacion basada en esquema;
* sugerencias fuzzy para datasets similares;
* y revisiones forzadas sobre columnas de alto riesgo.

### 6.3 Deteccion de alto riesgo por nombre
La politica general debe contemplar una lista no jerarquica, ilustrativa y extensible de patrones nominales heurísticos de riesgo, incluyendo al menos:
* `nombre`
* `apellido`
* `documento`
* `cedula`
* `rut`
* `pers_id`
* `pers_identificador`
* `nro_int`
* `nie`
* `nic`
* `contribuyente`
* `contrib`
* `emp`
* `empresa`
* `telefono`
* `mail`
* `direccion`
* `comentario`
* `observacion`
* `fecha_nacimiento`
* `expediente`
* `tramite`

La especificacion debe tratar todos estos patrones al mismo nivel conceptual: como disparadores heurísticos de revision y no como categorias jerarquicamente distintas.

---

## 7. Estrategia de Deteccion de Riesgo
### 7.1 Principio
La deteccion de riesgo debe ser multicapa, conservadora y explicitamente no omnisciente.

### 7.2 Familias de riesgo a detectar
La app debe identificar al menos:
* identificadores directos;
* quasi-identificadores;
* atributos sensibles potencialmente reveladores;
* texto libre potencialmente identificante;
* combinaciones con alta singularidad;
* granularidades excesivas en tiempo, espacio o monto;
* artefactos que permitan reconstruccion o vinculacion indebida.

### 7.3 Senales por estructura
La app debe usar senales como:
* cardinalidad alta;
* proporcion alta de valores unicos;
* formatos compatibles con identificadores;
* timestamps precisos;
* codigos alfanumericos institucionales;
* texto largo o semiestructurado;
* categorias extremadamente raras;
* montos o conteos excesivamente especificos.

### 7.4 Senales por combinacion
La app debe revisar combinaciones potencialmente riesgosas de:
* edad o rango etario;
* fecha o periodo;
* ubicacion;
* actividad o sector;
* atributos demograficos;
* indicadores sensibles;
* categorias de baja frecuencia;
* variables especialmente distintivas.

### 7.5 Regla operativa inicial para combinaciones
Para la politica general inicial del producto, la app debe evaluar de forma automatica combinaciones de tamano 1, 2 y 3 entre:
* columnas candidatas a quasi-identificador;
* columnas marcadas como de alto riesgo;
* fechas, ubicaciones y variables demograficas relevantes;
* columnas categoricas de baja frecuencia;
* numericas fuertemente distintivas cuando permanezcan con granularidad alta.

Una combinacion debe promoverse a bloqueo al menos en estos casos:
* produce clases de equivalencia por debajo de `k`;
* produce filas singulares o casi singulares segun la politica general;
* conserva granularidad excesiva en columnas ya marcadas como riesgosas;
* o sigue permitiendo una descripcion demasiado precisa de un subconjunto pequeno defendiblemente identificable.

La politica general inicial debe dejar trazado:
* que combinacion se evaluo;
* que tamanos de clase produjo;
* y por que el sistema la considero bloqueante o revisable.

### 7.6 Modelos basicos de atacante
La politica general inicial debe declarar al menos estos modelos basicos de atacante plausibles:
* atacante con conocimiento local razonable sobre una unidad de analisis;
* atacante con acceso a fuentes publicas o administrativas externas;
* atacante que conoce parcialmente ciertos atributos del sujeto;
* atacante que sospecha o conoce la pertenencia probable de una unidad al dataset liberado.

La deteccion y la decision de liberacion deben interpretarse a la luz de estos modelos y no solo como propiedades abstractas del dataset.

Implicancias minimas:
* una combinacion de atributos no debe evaluarse solo por unicidad matematica, sino tambien por su plausibilidad de vinculacion externa;
* una fecha, una ubicacion o una categoria rara pueden ser inocuas en aislamiento y peligrosas frente a un atacante con conocimiento contextual;
* la decision de no liberar puede apoyarse en riesgo defendiblemente previsible aun cuando no exista prueba de reidentificacion efectiva en ese caso puntual.

### 7.7 Niveles de confianza del detector
La deteccion debe poder clasificar alertas como:
* riesgo altamente probable;
* riesgo probable;
* riesgo posible que requiere revision.

### 7.8 Resultado estructurado de la deteccion
Cada alerta relevante debe registrar:
* objeto evaluado;
* tipo de senal;
* severidad;
* motivo tecnico;
* tratamiento sugerido;
* estado de resolucion.

---

## 8. Modelo de Decision de Liberacion
### 8.1 Regla base
La liberacion queda bloqueada por defecto.

Solo puede pasar a `liberable` si:
* se cumple el piso formal minimo;
* no quedan columnas de alto riesgo sin resolver;
* no quedan combinaciones peligrosas sin tratamiento;
* no existen observaciones bloqueantes no resueltas;
* hay evidencia auditable suficiente.

### 8.2 Piso formal minimo con `k-anonymity`
La solucion debe:
* construir quasi-identificadores relevantes;
* evaluar si cada fila pertenece a una clase de equivalencia de tamano al menos `k`;
* intentar resolver mediante generalizacion o supresion segun politica;
* bloquear si `k` no se alcanza.

### 8.3 Cumplir `k` no es suficiente
Aunque `k` se cumpla, el sistema debe bloquear si:
* persiste texto libre no resuelto;
* las fechas siguen siendo demasiado precisas;
* ciertas combinaciones siguen siendo semantica o contextualmente peligrosas;
* la salida sigue permitiendo inferencias indebidas defendiblemente previsibles.

### 8.4 Riesgo residual post-`k-anonymity`
La solucion debe tratar la evaluacion posterior al cumplimiento de `k` como una etapa obligatoria del flujo de liberacion y no como una nota accesoria.

El riesgo residual debe considerar al menos:
* homogeneidad o baja diversidad de atributos sensibles dentro de las clases de equivalencia;
* capacidad de inferencia sobre atributos sensibles a partir de la pertenencia a una clase pequena o semantica muy descriptiva;
* plausibilidad de vinculacion con fuentes externas publicas o razonablemente accesibles;
* persistencia de granularidad excesiva en tiempo, espacio, monto o categoria;
* y cualquier situacion donde el resultado siga permitiendo una descripcion demasiado precisa de una unidad o subconjunto defendiblemente identificable.

Consecuencias obligatorias:
* cumplir `k` no habilita automaticamente el estado `Liberable`;
* el estado solo puede pasar a `Liberable` si la reevaluacion posterior concluye que el riesgo residual queda dentro de la politica general defendible del producto;
* si el riesgo residual persiste y no existe tratamiento seguro disponible dentro del flujo actual, el sistema debe bloquear o concluir `No liberable sin rediseno`.

### 8.5 Estados posibles del dataset
La app debe trabajar con estados como:
* `No evaluado`
* `En revision`
* `Bloqueado`
* `Liberable`
* `No liberable sin rediseno`

### 8.6 Transiciones minimas de estado
Las transiciones esperadas deben ser, como minimo:
* `No evaluado` -> `En revision` cuando el dataset ya fue cargado y entro al flujo de evaluacion;
* `En revision` -> `Bloqueado` cuando existen riesgos no resueltos o controles no superados;
* `En revision` -> `Liberable` cuando se superan los controles formales y adicionales;
* `Bloqueado` -> `En revision` cuando el usuario aplica tratamientos o completa revisiones pendientes;
* `Bloqueado` -> `No liberable sin rediseno` cuando el sistema concluye que no existe resolucion segura defendible dentro del flujo actual;
* `No liberable sin rediseno` -> `En revision` solo si el usuario reinicia la evaluacion con cambios materiales de datos, clasificacion o politica aplicable.

Comportamiento obligatorio por estado:
* `No evaluado`: sin exportacion, sin decision de liberacion.
* `En revision`: sin exportacion externa; puede haber previsualizacion interna.
* `Bloqueado`: sin exportacion externa; debe mostrarse causa de bloqueo.
* `Liberable`: exportacion externa habilitada y generacion de informe de liberacion.
* `No liberable sin rediseno`: exportacion externa deshabilitada; solo informe de no liberacion y opciones de reinicio del proceso.

### 8.7 Ausencia de resolucion segura
Si no existe una resolucion segura defendible:
* no debe permitirse exportar;
* debe generarse un informe de no liberacion;
* el sistema debe explicar que riesgos persisten y que cambios serian necesarios para reevaluar.

---

## 9. Revision del Usuario y Evidencia Auditable
### 9.1 Principio
La app no debe apoyarse en aprobaciones superficiales.

Toda revision manual relevante debe:
* responder a un bloqueo concreto;
* requerir una accion verificable;
* dejar evidencia;
* poder ser auditada.

### 9.2 Rol del usuario
El usuario debe poder:
* revisar columnas;
* confirmar observaciones;
* elegir entre tratamientos seguros;
* y completar validaciones activas.

No debe poder:
* anular el bloqueo sin resolucion segura;
* liberar por simple declaracion;
* convertir una duda material en aprobacion informal.

### 9.3 Validacion activa
Para ciertas revisiones, la app debe exigir evidencia activa del usuario, por ejemplo:
* indicar la cantidad de valores unicos observados en una columna;
* confirmar si detecto contenido potencialmente identificante;
* declarar la granularidad temporal observada;
* seleccionar un tratamiento entre alternativas seguras.

### 9.4 Riesgos que requieren validacion activa obligatoria
La validacion activa debe ser obligatoria, como minimo, para:
* texto libre o campos narrativos;
* columnas marcadas por heuristica nominal fuerte;
* columnas con cardinalidad muy alta;
* fechas o periodos de alta precision;
* combinaciones promovidas a bloqueo;
* y cualquier alerta cuya resolucion dependa de observacion humana del contenido.

### 9.5 Regla de destrabe
Una validacion activa por si sola no debe destrabar la liberacion.

El destrabe solo puede ocurrir cuando:
1. el usuario completa la revision exigida;
2. aplica un tratamiento seguro disponible;
3. el sistema reevaluado deja de encontrar la condicion bloqueante;
4. y el estado general del dataset pasa a `Liberable`.

Existen casos en que la revision solo puede confirmar bloqueo y no habilitar salida. Esto debe ocurrir, por ejemplo, cuando:
* existe texto libre sin transformacion segura soportada;
* el riesgo por combinacion persiste tras las alternativas disponibles;
* o la granularidad minima aceptable sigue siendo insuficiente para la politica general.

### 9.6 Evidencia minima a registrar
Cada revision manual debe poder registrar:
* fecha y hora;
* usuario actuante, si el entorno lo permite;
* columna o combinacion revisada;
* tipo de riesgo;
* accion sugerida;
* accion aplicada;
* dato de verificacion exigido;
* resultado posterior de la reevaluacion.

### 9.7 Informes
La app debe producir:
* `Informe de liberacion`
* `Informe de no liberacion`

Ambos deben incluir suficiente justificacion tecnica y trazabilidad para revision posterior.

---

## 10. Transformaciones Soportadas por el Motor
### 10.1 Identificadores
La solucion debe:
* mapear identificadores de forma determinista dentro de la ejecucion;
* preservar cardinalidad y consistencia intra-dataset;
* soportar IDs numericos y alfanumericos;
* permitir prefijos visibles de auditoria;
* permitir estabilidad deterministica entre ejecuciones mediante `project_key` cuando corresponda;
* soportar, en escenarios internos o acotados, desfases reversibles sobre columnas numericas.

Si una capacidad reversible se usa en modo interno:
* no debe convertir automaticamente ese artefacto en liberable;
* no debe presentarse como medida suficiente de anonimización;
* y debe quedar separada del flujo de liberacion a terceros.

La especificacion debe considerar explicitamente que:
* una transformacion reversible puede ser util como medida de seguridad operacional interna;
* pero no satisface por si sola el estandar de liberacion externa defendible;
* y no debe presentarse al usuario como sinonimo de anonimización irreversible.

### 10.2 Fechas
La solucion debe:
* permutar fechas preservando el conjunto cuando se use ofuscacion base;
* permitir reglas posteriores de consistencia;
* y soportar generalizacion temporal cuando el contexto de liberacion lo requiera.

La liberacion a terceros no debe asumir que una simple permutacion es suficiente.

### 10.3 Categóricas
La solucion debe:
* permutar o reasignar categorias preservando frecuencias cuando corresponda;
* admitir agrupaciones o jerarquias para reducir riesgo;
* soportar `character` y `factor`;
* mantener estructura util para agrupaciones y resúmenes cuando sea compatible con la privacidad.

### 10.4 Numericas
La solucion debe soportar al menos los modos:
* `range_random`
* `preserve_rank`
* `permute`
* `additive_offset`

Ademas:
* debe permitir un modo general y modos especificos por columna;
* preservar `NA`, `Inf`, `-Inf` y `NaN` cuando aplique;
* evitar coerciones erróneas;
* mantener enteros como enteros cuando la columna original lo sea.

### 10.5 Reglas de consistencia
La solucion debe soportar reglas post-ofuscacion como minimo para:
* relaciones ordenadas entre columnas (`ordered`);
* consistencia temporal o numerica derivada;
* y futuras ampliaciones expresivas.

### 10.6 `k-anonymity`
La solucion debe soportar `k-anonymity` como capacidad del motor y de la API general, con:
* `type = "k_anonymity"`
* `k`
* `quasi_identifiers`
* `suppression`
* `hierarchies`
* `group_ids` cuando corresponda

El modelo debe:
* medir riesgo antes y despues;
* aplicar generalizacion progresiva;
* soportar jerarquias predefinidas y personalizadas;
* permitir supresion residual;
* registrar un `privacy_report` auditable.

Para evitar ambiguedad:
* en la API general el modelo puede seguir siendo una capacidad configurable;
* en el flujo de liberacion a terceros su uso pasa a ser obligatorio;
* en modos internos puede no exigirse para previsualizaciones o trabajo exploratorio no liberable.

---

## 11. Modelo Funcional de la Futura UI
### 11.1 Principio de organizacion
La UI debe responder a la pregunta:

> "Este dataset puede liberarse a un tercero de forma defendible?"

### 11.2 Flujo principal
El flujo principal visible debe ser:
1. carga del dataset;
2. clasificacion de variables;
3. deteccion de riesgos;
4. propuesta de tratamientos;
5. reevaluacion;
6. decision de liberacion;
7. exportacion o informe de bloqueo.

### 11.3 Bloques funcionales recomendados
La app debe estructurarse alrededor de:
* `Fuente de datos`
* `Estado del dataset`
* `Clasificacion de variables`
* `Riesgos detectados`
* `Tratamientos y configuraciones`
* `Resultado de evaluacion`
* `Salida`

### 11.4 Reglas de claridad de UI
La app no debe mostrar:
* paneles duplicados con el mismo significado;
* distintos controles con el mismo `inputId`;
* defaults contradictorios para una misma decision;
* opciones avanzadas fuera de contexto.

### 11.5 Exportacion
La exportacion no debe ser un boton siempre activo.

Debe depender del estado del dataset:
* si `Liberable`, exporta y produce informe de liberacion;
* si `Bloqueado`, no exporta y produce informe de no liberacion o de bloqueo parcial;
* si `En revision`, mantiene el bloqueo hasta completar los pasos necesarios;
* si `No evaluado`, no habilita exportacion;
* si `No liberable sin rediseno`, no exporta y debe producir un informe de no liberacion defendible.

---

## 12. Especificacion Ejecutable
### 12.1 Casos de uso optimos
La solucion debe seguir cubriendo, como minimo, estos casos:
1. join por IDs transformados con consistencia intra-dataset;
2. agrupacion por categorias con estructura util;
3. filtros numericos operables;
4. ordenamientos sobre numericas transformadas;
5. uso de fechas en series temporales cuando la granularidad lo permita;
6. conteo de nulos equivalente;
7. deteccion de duplicados y cardinalidad consistente;
8. graficos exploratorios razonables;
9. validacion de clases y tipos base;
10. preservacion de distribuciones categoricas cuando sea compatible con la politica de riesgo;
11. consistencia temporal post-transformacion;
12. consistencia numerica post-transformacion;
13. aplicacion de modos numericos por columna;
14. calculo de rankings cuando corresponda;
15. operacion con dataset de una fila sin romper tipos;
16. aplicacion de `k-anonymity` con reporte;
17. persistencia de clasificacion;
18. correccion visual manual;
19. generacion de codigo reproducible;
20. integracion con flujo legacy.

### 12.2 Casos limite
La solucion debe contemplar al menos:
1. dataset vacio;
2. columnas 100% `NA`;
3. IDs alfanumericos;
4. `Inf`, `-Inf`, `NaN`;
5. rangos numericos enormes;
6. dataset de una sola fila;
7. columnas con pocos unicos;
8. factores;
9. nombres de columnas con espacios;
10. `k` imposible de satisfacer;
11. jerarquias personalizadas incompletas;
12. mappings duplicados o vacios;
13. RDS no tabular;
14. objeto del entorno no tabular;
15. archivo no soportado;
16. columnas `character` con apariencia de fecha;
17. archivos grandes en navegador;
18. persistencia con esquema parecido pero no identico;
19. logs con datos sensibles derivados;
20. dependencias de UI no disponibles offline.

### 12.3 Casos especificos de liberacion segura
Ademas de los casos tradicionales, la nueva orientacion del producto debe verificar:
1. la IA es tratada como tercero y no reduce el estandar de privacidad;
2. una columna de texto libre no resuelta bloquea la liberacion;
3. una combinacion singular de atributos bloquea aunque el usuario crea que ninguna columna aislada es sensible;
4. el sistema no libera si `k` no se alcanza;
5. el sistema no libera si `k` se alcanza pero persiste riesgo residual no resuelto;
6. una revision manual sin evidencia verificable no destraba el bloqueo;
7. la ausencia de resolucion segura genera informe de no liberacion;
8. la exportacion queda deshabilitada cuando el estado no es `Liberable`.
9. una salida seudonimizada o reversible no se marca como liberable solo por haber removido identificadores directos;
10. una clase de equivalencia que cumple `k` pero mantiene un atributo sensible practicamente homogeneo no se considera automaticamente segura;
11. una combinacion de atributos defendiblemente vinculable con fuentes externas puede bloquear aunque la unicidad estricta no sea absoluta;
12. una reevaluacion posterior a la generalizacion temporal o categorial debe poder modificar el estado del dataset segun el riesgo residual observado.

---

## 13. Estado de Implementacion y Gobierno del Cambio
### 13.1 Niveles de madurez
Cada capacidad debe poder clasificarse como:
* implementada y testeada;
* implementada con validacion manual predominante;
* documentada pero con evidencia automatizada insuficiente.

### 13.2 Reglas de cambio controlado
No deberia modificarse la logica principal de:
* ofuscacion;
* persistencia;
* privacidad;
* deteccion de riesgo;
* UI critica;
* decisiones de liberacion;

sin:
* revisar compatibilidad con la suite automatica;
* validar coherencia con `README` y documentacion;
* reevaluar riesgos de filtracion o falsas garantias;
* actualizar especificacion y handoff.

### 13.3 Evolucion prevista
Se consideran lineas de evolucion probables:
* perfiles sectoriales de politica de riesgo;
* reglas de consistencia mas expresivas;
* separacion operacional mas clara entre preparacion interna y liberacion a terceros;
* endurecimiento adicional de deteccion de riesgo;
* mayor cobertura automatizada de UI y performance.

---

## 14. Criterios de Aceptacion para la Proxima Etapa
La siguiente etapa del producto se considerara bien encaminada cuando:
* exista una unica especificacion maestra alineada con el proposito reformulado;
* la UI deje de presentar paneles y parametros duplicados;
* el flujo de liberacion segura quede modelado de punta a punta;
* la exportacion este bloqueada por defecto;
* existan criterios explicitos de riesgo a nivel de columnas y combinaciones;
* el sistema pueda producir informes de liberacion y de no liberacion;
* la documentacion deje de presentar a la ofuscacion para IA como caso mas permisivo;
* el producto pueda presentarse como una herramienta general de liberacion segura a terceros.

---

## Anexo A. Matriz resumida de requerimientos
| ID | Requerimiento | Estado esperado |
| --- | --- | --- |
| RF-01 | Liberar datasets hacia terceros con bloqueo por defecto | Obligatorio |
| RF-02 | Tratar a la IA como tercero sin reducir exigencia de privacidad | Obligatorio |
| RF-03 | Distinguir transformacion, anonimizacion y decision de liberacion | Obligatorio |
| RF-04 | Soportar IDs, fechas, categoricas y numericas | Obligatorio |
| RF-05 | Soportar `k-anonymity` como piso formal minimo | Obligatorio |
| RF-06 | Detectar columnas de alto riesgo | Obligatorio |
| RF-07 | Detectar combinaciones de columnas riesgosas | Obligatorio |
| RF-08 | Bloquear texto libre no resuelto | Obligatorio |
| RF-09 | Requerir revision manual auditable cuando corresponda | Obligatorio |
| RF-10 | Producir informe de liberacion o no liberacion | Obligatorio |
| RF-11 | Mantener uso como script, paquete y app | Obligatorio |
| RF-12 | Mantener persistencia por esquema | Obligatorio |
| RF-13 | Mantener Studio operativo sin dependencias remotas criticas | Obligatorio |
| RF-14 | Generar codigo reproducible coherente con la configuracion aplicada | Obligatorio |
| RNF-01 | Operar localmente y en espanol | Obligatorio |
| RNF-02 | Mantener auditabilidad y trazabilidad | Obligatorio |
| RNF-03 | Tratar mappings y claves como artefactos sensibles | Obligatorio |
| RNF-04 | Mantener pipeline de tests y parseo | Obligatorio |
| RNF-05 | Ser defendible frente a auditoria y uso no experto | Obligatorio |
| RNF-06 | No prometer liberacion segura universal automatica | Obligatorio |

## Anexo B. Referencias del repositorio
Artefactos relevantes para esta especificacion:
* `ESPECIFICACION_DE_REQUERIMIENTOS.md`
* `ESPECIFICACION_DE_REQUERIMIENTOS_v2.0.md`
* `DETALLES_CASOS_DE_USO_CASOS_LIMITE.md`
* `README.md`
* `README_gitlab.md`
* `R/obfuscator_core.R`
* `R/shiny_app.R`
* `docs/AUDITORIA_ESTADO_ACTUAL_2026-05-06.md`
* `docs/superpowers/specs/2026-05-06-liberacion-segura-a-terceros-design.md`
