# ObfuscatoR 0.4.6

Version de granularidad por persona, documento y solicitud en `resumen_de()`.

- Reconoce identificadores personales como `PERS_ID` y `PERS_IDENTIFICADOR`.
- Reconoce el compuesto `TD` + `PAIS` + `DOCUMENTO` como documento personal sin convertir necesariamente `TD` y `PAIS` en identificadores individuales.
- Evalua claves candidatas como empresa + aportacion + persona y solicitud + persona.
- Trata denominaciones y razones sociales como etiquetas de entidad para evitar listar nombres reales de empresas o personas.

# ObfuscatoR 0.4.5

Version de granularidad institucional compuesta en `resumen_de()`.

- Agrupa identificadores equivalentes de empresa y contribuyente cuando hay representaciones internas y externas de la misma entidad.
- Evalua claves compuestas candidatas como empresa + contribuyente + aportacion + periodo.
- Informa senales temporales cuando un periodo `YYYYMM` parece explicar multiples filas por entidad/aportacion.
- Separa identificadores casi unicos, como titulos o documentos, de la granularidad analitica principal.

# ObfuscatoR 0.4.4

Version de analisis de granularidad por identificadores en `resumen_de()`.

- Agrega una seccion de granularidad observada cuando el dataset contiene identificadores detectados.
- Informa cuantos identificadores distintos hay, cuantas filas se observan por identificador y si hay multiples filas por identificador.
- Sugiere variables candidatas para refinar la granularidad, priorizando categorias, periodos y codigos normativos sin incluir montos ni texto libre.

# ObfuscatoR 0.4.3

Version de ajuste para descripciones de codigo en bloques con columnas intermedias.

- Permite emparejar `DESC_*` o `DESCRIPCION_*` con columnas de codigo cercanas aunque no sean estrictamente adyacentes.
- Mantiene una ventana corta y coincidencia por nucleo de nombre para evitar emparejamientos especulativos.

# ObfuscatoR 0.4.2

Version de precision semantica para codigos normativos y descripciones de codigos.

- Evita clasificar `TIPO_TITULO` como identificador cuando funciona como variable categorica.
- Trata `NRO_ART` y nombres equivalentes de articulo/ley/norma como referencias normativas, no como identificadores.
- Detecta descripciones de codigo cuando `DESC_*` o `DESCRIPCION_*` esta emparejada con una columna vecina compatible.
- Mantiene como texto libre prudente las columnas de descripcion sin emparejamiento claro.

# ObfuscatoR 0.4.1

Version de seguridad semantica para el helper `resumen_de()`.

- Trata identificadores institucionales como `NRO_EMPRESA` y `NRO_CONTRIBUYENTE_*` como identificadores, evitando listar valores frecuentes.
- Evita clasificar como identificadores medidas o estados que contienen la palabra `CONTRIBUYENTE`, como deuda o juicio.
- Restringe la deteccion de telefonos a columnas con senal de telefono para no confundir codigos numericos largos.
- Reconoce periodos `YYYYMM` en columnas de periodo y los describe sin convertirlos en categorias.
- Describe columnas completamente faltantes como sin valores observados, conservando el tipo importado.

# ObfuscatoR 0.4.0

Release base de Studio 2.0 con persistencia, contrato de release y helper `resumen_de()` integrado.
