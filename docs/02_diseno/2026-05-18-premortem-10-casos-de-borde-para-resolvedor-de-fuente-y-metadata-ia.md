# Premortem: 10 casos de borde para el resolvedor de fuente y metadata de perfilado IA

## Proposito

Anticipar los casos de borde mas probables y peligrosos que podrian hacer fallar la futura implementacion del resolvedor de fuente y del matching contra metadata en `dataset_profile_for_ai`.

El objetivo no es solo listar riesgos, sino dejar recomendada una forma de resolucion optima para cada uno antes de escribir codigo.

## Alcance

Este premortem se enfoca en la futura implementacion de:

- `tipo_fuente`
- `archivo_fuente`
- deteccion de `gca`, `gca2` y `oracle`
- lectura de metadata por fuente
- matching entre metadata de origen y objeto actual
- y comparacion entre nombres esperados y nombres observados

No cubre en detalle:

- la UI futura de edicion de metadata
- ni el parseo del script activo

## Criterio general de resolucion

Cuando exista duda razonable, la politica recomendada es:

- **preferir no aplicar metadata antes que aplicar metadata equivocada**

Es decir:

- tolerar degradacion controlada a heuristicas puras;
- pero evitar inferencias agresivas o silenciosas con alto costo de error.

---

## Caso 1: `tipo_fuente` declarado por el usuario contradice la evidencia disponible

### Ejemplo

El usuario declara:

```r
tipo_fuente = "gca2"
```

pero el archivo o la estructura observada se parece mucho mas a `GCA.net` o a un `.csv` simple.

### Riesgo

Aplicar reglas de deteccion o metadata de una familia de fuente equivocada.

### Resolucion recomendada

- no ignorar automaticamente lo declarado por el usuario;
- pero si registrar una advertencia de inconsistencia;
- y reducir la confianza de la resolucion.

### Politica optima

1. conservar `tipo_fuente` declarado como pista principal
2. marcar conflicto entre declaracion y evidencia
3. no aplicar metadata automatica de fuente si la contradiccion es fuerte
4. degradar a heuristicas o pedir confirmacion futura

---

## Caso 2: `GCA.net` detectado con confianza media, pero sin numero de consulta confirmable

### Ejemplo

La planilla `.xls` tiene:

- `Informacion de la consulta`
- `Datos_Consulta1`
- firma textual de `GCA`

pero no aparece un id de consulta confiable dentro del libro.

### Riesgo

Asociar la planilla a la metadata de otra consulta por parecido de titulo o estructura.

### Resolucion recomendada

- reconocer `source_type = gca`
- construir identidad provisional
- no aplicar metadata ajena por similitud debil

### Politica optima

1. detectar el origen
2. registrar confianza `medium`
3. usar `source_id` provisional
4. aplicar metadata solo si existe match muy fuerte por alias + fingerprint
5. si no, seguir con heuristicas

---

## Caso 3: `GCA2` trae nombre de archivo consistente, pero `Caratula` ausente o degradada

### Ejemplo

Existe un archivo:

- `consulta_18631_123456.xlsx`

pero la hoja `Caratula` no esta, esta corrupta o no cumple el formato esperado.

### Riesgo

Tomar el nombre del archivo como prueba suficiente y aplicar metadata de forma demasiado confiada.

### Resolucion recomendada

- usar el nombre del archivo como evidencia auxiliar, no definitiva
- bajar la confianza de la resolucion
- y evitar match automatico fuerte si la `Caratula` no confirma

### Politica optima

1. inferir posible `gca2`
2. marcar confianza `medium` o `low`
3. no elevar a identidad confirmada sin `Caratula` valida o metadata externa confiable

---

## Caso 4: salida `.csv` de `GCA2` sin `Caratula` acompaÃ±ante

### Ejemplo

La consulta supera el limite de Excel y la salida es `.csv`. El usuario solo conserva el `.csv`.

### Riesgo

Querer forzar una identidad exacta cuando el artefacto disponible ya no trae metadata embebida suficiente.

### Resolucion recomendada

- permitir que el usuario declare `tipo_fuente = "gca2"`
- tratar el nombre del archivo como evidencia auxiliar
- no asumir identidad fuerte sin mas respaldo

### Politica optima

1. aceptar resolucion parcial del tipo de fuente
2. no asumir `source_id` exacto solo por nombre del archivo
3. si no hay metadata adicional, seguir con perfilado del dataset y advertencia

---

## Caso 5: metadata de origen en mayusculas y objeto actual con `clean_names()` o renombres

### Ejemplo

Metadata de origen:

- `FECHA_ULT_ACT`

Objeto actual:

- `fecha_ult_act`

o incluso:

- `fecha_ultima_actualizacion`

### Riesgo

Declarar falsamente que faltan columnas o perder el matching contra metadata util.

### Resolucion recomendada

- distinguir entre nombre de origen, nombre normalizado y nombre actual
- intentar matching normalizado antes de declarar ausencia

### Politica optima

1. match exacto
2. match por normalizacion equivalente a `clean_names()`
3. si sigue sin haber match, advertir posible renombre o desajuste
4. no inventar una correspondencia compleja sin suficiente evidencia

---

## Caso 6: columna esperada en metadata no existe porque el usuario cargo solo una hoja parcial

### Ejemplo

La fuente original tenia:

- varias hojas de datos

pero el usuario importo solo una.

### Riesgo

Interpretar esa ausencia como problema de contenido del dataset, cuando en realidad fue una carga incompleta del artefacto fuente.

### Resolucion recomendada

- este caso no puede resolverse bien solo con el `data.frame`
- requiere, en el futuro, `archivo_fuente`
- mientras tanto, no conviene sobreactuar

### Politica optima

1. sin `archivo_fuente`, limitarse a advertencia suave si la diferencia es grande
2. con `archivo_fuente`, revisar estructura del libro completo
3. si hay varias hojas de datos, emitir advertencia clara de posible carga parcial

---

## Caso 7: dos fuentes distintas matchean el mismo alias o nombre visible

### Ejemplo

En la biblioteca existen dos fichas con:

- `display_name` muy parecido
- o alias compartidos

y el dataset actual no ofrece suficiente evidencia para desempatar.

### Riesgo

Aplicar metadata de una fuente equivocada sin que el usuario lo note.

### Resolucion recomendada

- no desempatar automaticamente
- registrar ambiguedad
- y no aplicar metadata declarada hasta contar con mejor evidencia

### Politica optima

1. `source_id` exacto gana siempre
2. alias solo si hay una coincidencia unica y razonable
3. si hay mas de una, degradar a `ambiguous_match`
4. seguir con heuristicas

---

## Caso 8: metadata de fuente y `config` del usuario se contradicen

### Ejemplo

La metadata por fuente dice:

- `diagnostico` es `sensible`

pero el usuario declara en `config` algo que lo fuerza a otra categoria menos restrictiva.

### Riesgo

Perder proteccion semantica importante por un override local demasiado liviano.

### Resolucion recomendada

- mantener la precedencia ya aprobada:
  1. `config` del usuario
  2. metadata de fuente
  3. heuristica
- pero emitir advertencia si el override del usuario rebaja el nivel de riesgo esperado

### Politica optima

1. respetar `config`
2. registrar el conflicto
3. advertir cuando el override reduce severidad
4. dejar trazabilidad visible en el perfil final

---

## Caso 9: el origen esperado dice una cosa y el estado actual del objeto otra

### Ejemplo

- se esperaba `datetime`
- pero la columna actual sigue como `character`

o:

- se esperaba identificador normalizado
- pero sigue como `numeric`

### Riesgo

La IA puede asumir que el objeto ya esta bien preparado cuando no lo esta.

### Resolucion recomendada

- no reconstruir el pipeline completo
- si agregar alertas de desajuste relevantes

### Politica optima

1. comparar origen esperado vs estado actual
2. generar alertas solo para diferencias significativas
3. no describir todo el historial de transformaciones

---

## Caso 10: el usuario no sabe ni el tipo de fuente ni conserva el archivo de origen

### Ejemplo

Solo existe un `data.frame` ya transformado en R, sin archivo original y sin contexto adicional.

### Riesgo

Querer forzar una deteccion de fuente demasiado especulativa.

### Resolucion recomendada

- aceptar que este es un caso legitimo
- mantener el helper util en modo cero-configuracion
- y no castigar al usuario por no tener mas contexto

### Politica optima

1. no exigir `tipo_fuente`
2. no exigir `archivo_fuente`
3. perfilar por heuristicas puras
4. marcar simplemente que no hay contexto de origen confiable

---

## Los tres fallos mas peligrosos

### 1. Aplicar metadata de fuente equivocada con alta confianza

Este es el peor error posible, porque contamina silenciosamente todo el perfil.

### 2. Declarar columnas faltantes por no contemplar normalizacion o renombres

Esto puede volver inutil una biblioteca de metadata aunque la fuente este bien descripta.

### 3. Confiar demasiado en artefactos incompletos

Especialmente:

- `.csv` sin `Caratula`
- `GCA.net` sin id de consulta
- libros con varias hojas de datos cargados solo en parte

## Recomendaciones transversales

### 1. Degradacion elegante

Siempre que haya ambiguedad fuerte, preferir:

- `sin metadata`
- `match ambiguo`
- `confianza media`

antes que un acierto falso con confianza alta.

### 2. Trazabilidad visible

El perfil futuro deberia poder decir:

- si una fuente fue declarada por el usuario
- si fue detectada automaticamente
- si hubo conflicto
- si hubo match ambiguo
- y si la metadata se aplico o no

### 3. Matching por capas

No depender solo de:

- nombre del archivo
- ni nombre literal de la columna

Sino combinar:

- evidencia estructural
- ids tecnicos
- nombres normalizados
- aliases
- y confianza de resolucion

## Acciones recomendables cuando una crisis abre una oportunidad

Cada crisis de uso, prueba o implementacion deberia tratarse como una oportunidad acotada para mejorar el sistema, no como una invitacion a cambiarlo todo. La reaccion optima es capturar el aprendizaje mientras esta fresco, pero convertirlo en una mejora pequena, verificable y documentada.

### 1. Separar incidente, causa y oportunidad

Ante un fallo o una salida confusa, registrar tres cosas por separado:

- que ocurrio;
- que supuesto se rompio;
- que nueva capacidad o regla conviene agregar.

Esto evita confundir el sintoma inmediato con una solucion apresurada.

### 2. Convertir la crisis en un caso de prueba

Si el problema puede repetirse, deberia transformarse en:

- un test automatico;
- un caso manual de verificacion;
- o un ejemplo documental minimo.

La crisis solo queda realmente aprovechada cuando el mismo error no puede reaparecer silenciosamente.

### 3. Documentar la decision antes de normalizarla

Cuando la crisis obliga a elegir una politica nueva, la decision deberia quedar escrita con:

- el problema observado;
- la alternativa elegida;
- las alternativas descartadas;
- y el criterio para revisar la decision mas adelante.

Esto es especialmente importante si la solucion afecta metadata, inferencia semantica o advertencias al usuario.

### 4. Mantener degradacion segura como respuesta por defecto

En una crisis, la tentacion natural es resolver mas agresivamente. Para este helper, la oportunidad se aprovecha mejor si la respuesta por defecto sigue siendo:

- bajar confianza;
- advertir;
- no aplicar metadata dudosa;
- y conservar utilidad con heuristicas.

La crisis debe aumentar la precision futura, no la audacia silenciosa del sistema.

### 5. Extraer una regla reusable si el patron se repite

Si el mismo tipo de crisis aparece en mas de un dataset, fuente o usuario, conviene convertirlo en una regla reusable:

- una nueva heuristica;
- una alerta especifica;
- una validacion de metadata;
- o una recomendacion de uso en la guia operativa.

Si aparece una sola vez, puede alcanzar con documentarlo como caso conocido y no sobrediseniar.

### 6. Usar la crisis para mejorar comunicacion, no solo codigo

Algunas crisis no revelan un bug tecnico sino una ambiguedad para el usuario o para la IA. En esos casos, la mejora optima puede ser:

- cambiar una frase del resumen;
- distinguir evidencia de supuesto;
- explicar mejor el nivel de confianza;
- o agregar una advertencia accionable.

El aprendizaje no siempre debe terminar en mas automatizacion.

## Decision final

Antes de implementar el resolvedor de fuente y metadata, se aprueba este premortem como guia de robustez.

La regla central que atraviesa los 10 casos es:

- **es mejor degradar a heuristicas con advertencia que aplicar metadata equivocada con falsa seguridad**

Ese criterio deberia gobernar toda la implementacion posterior.
