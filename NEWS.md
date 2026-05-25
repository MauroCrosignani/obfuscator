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
