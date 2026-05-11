# Diseno: liberacion controlada sin cuasi-identificadores

## Resumen

Este documento fija una regla funcional corta para un caso de borde ya observado en pruebas manuales: datasets donde los identificadores directos deben transformarse, pero no quedan variables cuasi-identificadoras relevantes sobre las que aplicar `k-anonymity`.

La decision de producto propuesta es no bloquear automaticamente la liberacion por ausencia de `QI`. En cambio, la app debe distinguir entre:

- `k-anonymity aplicado y satisfecho`;
- `k-anonymity no aplicado por ausencia de cuasi-identificadores`;
- y `bloqueo o revision manual por variables sensibles, privadas o riesgo residual`.

## Problema

Hoy el flujo mezcla dos situaciones distintas:

1. no se activo o no se pudo ejecutar `k-anonymity` cuando hacia falta;
2. ya no existen `QI` relevantes luego de transformar o excluir identificadores directos.

En la primera situacion, el bloqueo puede ser correcto. En la segunda, el bloqueo es demasiado rigido y transmite una semantica equivocada: parece que falto proteger algo que, en realidad, ya no esta presente como riesgo de cuasi-identificacion.

## Regla funcional corta

### Regla principal

Si el artefacto final:

- no contiene variables marcadas como `QI`;
- ya transformo o excluyo los identificadores directos;
- y no presenta bloqueo duro por variables `PRIV`, riesgo residual o resultado vacio,

entonces la app puede considerarlo `Liberable` sin requerir `k-anonymity`, dejando constancia explicita de que no fue aplicado por ausencia de cuasi-identificadores relevantes.

### Texto funcional recomendado para auditoria

- `k-anonymity no fue aplicado porque no se definieron cuasi-identificadores relevantes.`
- `La liberacion se evaluo sobre transformacion de identificadores directos y revision de variables sensibles o privadas.`

## Flujo de trabajo recomendado

1. cargar dataset;
2. clasificar variables;
3. si no hay `QI`, informar ese estado antes de ofuscar;
4. al ejecutar:
   - transformar o excluir `ID`;
   - omitir `k-anonymity`;
   - evaluar `SENS`, `PRIV` y otras senales de riesgo;
5. emitir un veredicto final segun el resto del riesgo detectado.

## Estados recomendados

### 1. Liberable

Aplicar cuando:

- no hay `QI`;
- no hay `PRIV`;
- no hay senales de bloqueo residual;
- y las variables `SENS`, si existen, no exigen una intervencion adicional segun las reglas vigentes del MVP.

La auditoria debe decir explicitamente que la liberacion ocurre sin `k-anonymity`.

### 2. Liberable con advertencias

Aplicar cuando:

- no hay `QI`;
- no hay `PRIV` bloqueantes;
- pero si hay `SENS` que requieren verificacion humana del contenido o del destinatario.

La UI debe dejar una llamada a la accion clara, no solo una nota pasiva.

### 3. Requiere revision manual

Aplicar cuando:

- no hay `QI`;
- pero hay `PRIV`, texto libre u otra informacion que quede fuera del control automatico;
- o cuando la ausencia de `QI` no elimina la necesidad de confirmar aceptabilidad del contenido.

### 4. Bloqueado

Aplicar cuando:

- el artefacto final queda vacio;
- o persiste un riesgo duro no resuelto;
- o las reglas del producto identifiquen una situacion no defendible para liberacion.

## Tratamiento de variables sensibles y privadas en este escenario

### Variables `SENS`

No deberian bloquear siempre por defecto. En este caso, su efecto recomendado para el MVP es:

- permitir liberacion con advertencia fuerte cuando no haya otra senal de bloqueo;
- exigir verificacion explicita del usuario sobre aceptabilidad del contenido para el destinatario.

### Variables `PRIV`

No conviene tratarlas como si la ausencia de `QI` resolviera su riesgo. Para el MVP, el camino recomendado es:

- `Requiere revision manual` por defecto;
- con auditoria que explique que quedaron fuera del control automatico de `k-anonymity`.

## Mensajes sugeridos para la UI

### Banner o nota previa

- `No hay cuasi-identificadores definidos. La liberacion se evaluara sin k-anonymity.`

### Resumen de auditoria

- `Estado de liberacion: Liberable`
- `Nota: k-anonymity no fue aplicado porque no se definieron cuasi-identificadores relevantes.`

o bien:

- `Estado de liberacion: Requiere revision manual`
- `Nota: no hay cuasi-identificadores, pero existen variables privadas o expresivas fuera del control automatico.`

## Implicancias para el MVP

Esta politica no intenta introducir nuevos modelos formales de anonimidad. Solo corrige una rigidez semantica del flujo actual y alinea mejor el producto con un criterio de liberacion controlada mas defendible:

- no fingir `k-anonymity` donde no aplica;
- no bloquear automaticamente por ausencia de `QI`;
- y no relajar indebidamente las advertencias por `SENS` o `PRIV`.

## Siguiente paso recomendado

Implementar este flujo como un cambio acotado del modelo de decision de liberacion, con pruebas dedicadas para:

- ausencia de `QI` + salida segura;
- ausencia de `QI` + `SENS`;
- ausencia de `QI` + `PRIV`;
- y ausencia de `QI` + resultado vacio.
