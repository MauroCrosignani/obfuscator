# Diseno de deteccion de fuentes `GCA2` desde planillas `.xlsx` y salidas `.csv`

## Proposito

Definir como deberia detectar e interpretar el sistema una fuente exportada desde `GCA2`, aprovechando que este origen ofrece una estructura mas estable que `GCA.net`.

El objetivo es que la deteccion:

- use el `Id de Consulta` como identidad tecnica principal cuando este disponible;
- distinga claramente entre id de consulta e id de ejecucion;
- y contemple tanto las salidas `.xlsx` como el caso en que la exportacion se realiza en `.csv` por exceder el limite de filas de Excel.

## Contexto de uso

En `GCA2`, la salida por defecto usa un nombre de archivo estandar.

Ejemplo:

- consulta numero `18631`
- ejecucion numero `123456`
- archivo resultante:
  - `consulta_18631_123456.xlsx`

En la salida compartida:

- el libro es `.xlsx`
- tiene dos hojas:
  - `Caratula`
  - `salida_gca`

Si el volumen supera aproximadamente el millon de lineas, el sistema puede exportar la salida como `.csv` en lugar de planilla Excel.

## Problema de diseno

En `GCA2` hay mas informacion estructurada que en `GCA.net`, pero sigue siendo importante no mezclar:

- la identidad estable de la consulta;
- con el identificador puntual de la ejecucion;
- ni con el nombre del archivo exportado.

Ademas, el helper deberia poder reconocer:

- una planilla `.xlsx` completa con hoja `Caratula`;
- y mas adelante una salida `.csv` asociada a la misma consulta, aunque ahi la evidencia embebida puede ser menor.

## Decision principal

Se recomienda que, para `GCA2`, la identidad tecnica principal sea:

```json
"source_type": "gca2",
"source_id": "gca2:18631"
```

Y que el identificador de ejecucion quede fuera de `source_id`, dentro de `source_details`.

## Firma estructural recomendada para planillas `.xlsx`

Se recomienda reconocer una planilla `GCA2` cuando se verifiquen en conjunto estas señales:

- nombre de archivo con patron compatible `consulta_<id_consulta>_<id_ejecucion>.xlsx`
- existencia de hoja `Caratula`
- existencia de hoja `salida_gca`
- `B2` contiene `Planilla generada por GCA2`
- `B3` contiene `Nombre`
- `B4` contiene `Id de Consulta`
- `C4` contiene un valor interpretable como numero de consulta
- `B6` contiene `Id. Ejecucion`
- `C6` contiene un correlativo de ejecucion

### Regla recomendada

La deteccion no deberia depender solo del nombre del archivo, porque ese patron puede ayudar mucho pero la evidencia fuerte esta dentro de la `Caratula`.

## Metadatos que conviene extraer desde `Caratula`

Se recomienda extraer, al menos:

- `Nombre` de la consulta
- `Id de Consulta`
- `Descripcion`
- `Id. Ejecucion`
- `Usuario`
- `Fecha de inicio`
- `Fecha de fin`
- `Parametros`
- nombre de planilla de entrada en `D10` si existe

## Mapeo sugerido de celdas

### Celdas relevantes

- `B2`: firma de origen
- `B3`: etiqueta `Nombre`
- `C3`: nombre de la consulta
- `B4`: etiqueta `Id de Consulta`
- `C4`: id de consulta
- `B5`: etiqueta `Descripcion`
- `C5`: descripcion
- `B6`: etiqueta `Id. Ejecucion`
- `C6`: id de ejecucion
- `B7`: etiqueta `Usuario`
- `C7`: usuario
- `B8`: etiqueta `Fecha de inicio`
- `C8`: fecha de inicio
- `B9`: etiqueta `Fecha de fin`
- `C9`: fecha de fin
- `B10`: etiqueta `Parametros`
- `C10`: modo de parametros
- `D10`: nombre de planilla de entrada cuando aplique

## Modelo de salida recomendado para la deteccion

Ejemplo conceptual:

```json
{
  "source_type_detected": "gca2",
  "source_identity_confidence": "high",
  "detection_evidence": {
    "workbook_format": "xlsx",
    "default_filename_pattern_matches": true,
    "cover_sheet_name": "Caratula",
    "data_sheet_name": "salida_gca",
    "b2_matches_gca2_signature": true,
    "c4_query_id_present": true,
    "c6_execution_id_present": true
  },
  "extracted_details": {
    "query_id": "18631",
    "query_name": "<nombre>",
    "query_description": "GCA2_18631_GIC6621_<nombre>",
    "execution_id": "123456",
    "user": "<usuario_red>",
    "started_at": "<fecha_inicio>",
    "finished_at": "<fecha_fin>",
    "parameters_mode": "Excel",
    "input_filename": "input_18631_<nombre>.xlsx"
  }
}
```

## Distincion entre identidad estable y ejecucion puntual

### Identidad estable

Debe basarse en el `Id de Consulta`.

Ejemplo:

```json
"source_id": "gca2:18631"
```

### Ejecucion puntual

Debe conservarse en `source_details`.

Ejemplo:

```json
"source_details": {
  "query_id": "18631",
  "execution_id": "123456"
}
```

### Anti-patron a evitar

No usar:

```json
"source_id": "gca2:18631:123456"
```

porque eso volveria inestable la identidad de la fuente y la ligaria a una corrida concreta.

## Tratamiento del nombre de archivo

El patron:

- `consulta_<id_consulta>_<id_ejecucion>.xlsx`

es una señal util y deberia aprovecharse como evidencia auxiliar.

Pero no deberia ser la unica fuente de verdad.

Si el nombre del archivo contradice la `Caratula`, deberia prevalecer la informacion embebida en la planilla.

## Caso de exportacion `.csv`

Cuando el resultado supera el limite de filas de Excel, `GCA2` puede exportar en `.csv`.

### Decision recomendada

La deteccion de una salida `.csv` de `GCA2` no deberia asumir automaticamente identidad fuerte si no existe una `Caratula` asociada o metadata externa confiable.

Se recomienda distinguir:

1. **csv acompaÃ±ado por metadata confiable**
2. **csv sin metadata acompaÃ±ante**

### Caso 1: `.csv` con metadata confiable

Si existe una fuente complementaria confiable, por ejemplo:

- una `Caratula` guardada aparte;
- o metadata operacional externa;

entonces puede resolverse:

```json
"source_type": "gca2",
"source_id": "gca2:18631"
```

### Caso 2: `.csv` sin metadata acompaÃ±ante

Si solo existe el `.csv`, el helper deberia ser prudente:

- intentar extraer señales del nombre del archivo;
- registrar la confianza como `medium` o `low`;
- y no aplicar metadata automaticamente si la identidad no queda suficientemente respaldada.

## Parametros de entrada

El bloque de parametros tiene valor funcional porque permite distinguir, al menos:

- consultas sin parametros
- consultas parametrizadas manualmente
- consultas alimentadas por planilla de entrada

### Recomendacion

Conservar esta informacion dentro de `source_details`, por ejemplo:

```json
"source_details": {
  "parameters_mode": "Excel",
  "input_filename": "input_18631_<nombre>.xlsx"
}
```

Esto no cambia la identidad de la fuente, pero si puede ayudar a interpretar diferencias entre ejecuciones.

## Relacion con la biblioteca de metadata

La resolucion recomendada para una fuente `GCA2` seria:

1. detectar si la planilla coincide con la firma `GCA2`
2. extraer `Id de Consulta` desde `C4`
3. construir `source_id = gca2:<id_consulta>`
4. intentar match exacto con la biblioteca de metadata
5. usar `aliases` solo como apoyo secundario

Esto hace que `GCA2` sea un caso mas fuerte que `GCA.net`, porque generalmente si ofrece una clave tecnica directa.

## Uso conjunto con fuentes `GCA.net`

Una consulta funcional puede existir:

- en `GCA.net`
- y en `GCA2`

pero con ids distintos.

Por eso no se recomienda intentar deducir equivalencia directa entre:

- `gca:5553`
- `gca2:18631`

La relacion, si se conoce, deberia expresarse despues en:

- `related_sources`

## Anti-patrones a evitar

No se recomienda:

- usar el id de ejecucion como parte de la identidad estable
- usar solo el nombre del archivo como verdad definitiva
- tratar una salida `.csv` sin metadata acompaÃ±ante como identidad confirmada
- mezclar identidad de consulta con detalles operativos de una ejecucion puntual

## Decision final

Se aprueba un modelo de deteccion `GCA2` basado en:

- firma estructural de la hoja `Caratula`
- lectura explicita del `Id de Consulta`
- separacion entre identidad estable y ejecucion puntual
- y tratamiento prudente del caso `.csv`

Esto permite una resolucion de fuente mucho mas robusta que en `GCA.net`, sin perder cautela cuando el artefacto disponible no trae toda la metadata embebida.
