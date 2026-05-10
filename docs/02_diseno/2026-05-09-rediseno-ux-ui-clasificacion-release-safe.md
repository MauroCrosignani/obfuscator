# Diseno UX/UI: clasificacion simplificada por rol principal para release-safe
**Fecha:** 2026-05-09  
**Estado:** Propuesta de diseno validada conversacionalmente

---

## 1. Resumen

Este documento propone reemplazar el mecanismo principal de clasificacion basado en multiples zonas de drag-and-drop por una interfaz centrada en `un rol principal por variable`.

Conclusion practica:
- la UI actual ya expresa mejor el modelo `release-safe` que al inicio del proyecto;
- pero empieza a degradarse en usabilidad a medida que agregamos mas conceptos;
- por eso conviene redisenar la clasificacion alrededor de una tabla de variables, una ficha lateral de detalle y una ayuda contextual mucho mas clara.

---

## 2. Problema que resuelve

La UI actual tiene una virtud real: hace visible que las variables no son todas iguales.

Pero tambien tiene un limite fuerte:
- cuanto mas refinamos el modelo conceptual;
- mas casilleros, zonas y decisiones de arrastre aparecen;
- y mas dificil se vuelve usar la app con datasets anchos o ambiguedades reales.

El caso de `edad` expuso bien el problema:
- siendo numerica, puede actuar como cuasi-identificador;
- pero la UI no ofrece una manera sencilla y clara de expresar eso;
- y seguir sumando zonas visuales no parece una solucion sostenible.

El objetivo de este rediseño es:
- preservar la solidez conceptual lograda;
- y reducir la carga cognitiva del usuario al clasificar variables.

---

## 3. Principio rector

La clasificacion de variables no debe obligar al usuario a "armar listas" distribuyendo columnas entre muchas zonas.

La interfaz debe permitir responder, para cada variable:

1. que rol conceptual cumple;
2. que tratamiento tecnico corresponde;
3. que impacto tiene sobre la liberacion.

Eso implica separar:
- `semantica del rol`
- de
- `tratamiento tecnico`

---

## 4. Recomendacion de diseno elegida

Se evaluaron tres enfoques:

1. ampliar el drag-and-drop con mas zonas;
2. usar un `rol principal por variable` en una tabla o lista;
3. dividir la clasificacion en dos pasos formales: rol conceptual y tratamiento tecnico.

### Opcion recomendada

Se recomienda una combinacion de `2 + 3`:

- la `vista principal` usa un `rol principal por variable`;
- la `ficha lateral` permite configurar el `tratamiento tecnico` y el impacto sobre la liberacion.

Esta opcion fue elegida porque:
- escala mejor a datasets grandes;
- evita una proliferacion de casilleros;
- mantiene visible el modelo conceptual;
- y deja una base mas defendible para una futura presentacion tecnica.

---

## 5. Modelo de pantalla propuesto

### 5.1 Vista principal

La clasificacion pasa a mostrarse como una tabla o lista de variables con columnas como:

- `Variable`
- `Tipo`
- `Rol`
- `Tratamiento`
- `Riesgo`
- `Estado`
- `Accion`

#### Contenido esperado por columna

`Variable`
- nombre completo;
- tooltip si es largo;
- indicador visual si hay alerta.

`Tipo`
- `fecha`
- `numerica`
- `categorica`
- `texto`

`Rol`
- badge corto editable:
  - `ID`
  - `QI`
  - `SENS`
  - `PRIV`
  - `KEEP`
  - `EXC`

`Tratamiento`
- texto corto del tratamiento tecnico vigente.

`Riesgo`
- `bajo`
- `medio`
- `alto`
- `critico`

`Estado`
- `ok`
- `revisar`
- `bloquea`
- `sin definir`

`Accion`
- boton `Editar`

### 5.2 Ficha lateral

Al hacer click en `Editar`, se abre una ficha lateral por variable con cinco bloques:

1. `Resumen`
2. `Rol principal`
3. `Tratamiento tecnico`
4. `Impacto`
5. `Ayuda`

#### Bloque 1. Resumen

Debe mostrar:
- nombre de la variable;
- tipo detectado;
- muestra breve de valores;
- sugerencia automatica del sistema.

#### Bloque 2. Rol principal

Selector unico entre:
- `ID`
- `QI`
- `SENS`
- `PRIV`
- `KEEP`
- `EXC`

#### Bloque 3. Tratamiento tecnico

Opciones contextuales segun tipo y rol.

Ejemplos:

- `ID`
  - mapa deterministico
  - excluir

- `QI` fecha
  - dia
  - semana
  - mes
  - trimestre
  - anio

- `QI` numerica
  - valor exacto
  - rango fino
  - rango amplio
  - decil
  - excluir

- `QI` categorica
  - valor original
  - agrupar raras
  - jerarquia

- `SENS`
  - conservar con control de riesgo residual
  - excluir

- `PRIV`
  - bloquear
  - excluir
  - revision manual

#### Bloque 4. Impacto

Debe responder en texto simple:
- participa o no en `k-anonymity`;
- puede bloquear por riesgo residual o no;
- requiere revision manual o no.

#### Bloque 5. Ayuda

Debe incluir:
- que significa el rol;
- por que el sistema lo sugirio;
- ejemplo breve de riesgo asociado.

---

## 6. Semantica oficial de roles

### `ID`
Variable que identifica directamente a la unidad de analisis.

### `QI`
Variable que no identifica sola, pero puede identificar por combinacion.

### `SENS`
Variable que revela informacion delicada aunque no identifique por si sola.

### `PRIV`
Variable con informacion especialmente riesgosa, expresiva o dificil de controlar automaticamente.

### `KEEP`
Variable que se conserva en la salida, pero no se usa como base principal de anonimización.

### `EXC`
Variable que debe excluirse de la salida final.

---

## 7. Reglas iniciales de sugerencia automatica

La sugerencia automatica debe ser:
- conservadora;
- explicable;
- y facil de corregir.

### Prioridad de reglas

Si una columna activa varias reglas, se recomienda priorizar:

1. `ID`
2. `PRIV`
3. `SENS`
4. `QI`
5. `EXC`
6. `KEEP`

### Sugerir `ID`

Para nombres y patrones como:
- `id`
- `pers_id`
- `persona_id`
- `identificador`
- `rut`
- `cedula`
- `dni`
- `nie`
- `nic`
- `nro_int`
- `expediente`
- `matricula`
- `contribuyente`

### Sugerir `QI`

#### Fechas
- tipos `Date` o `POSIX`
- nombres que parezcan fecha
- texto con formato de fecha

#### Numericas cuasi-identificadoras
- `edad`
- `antiguedad`
- `cantidad_hijos`
- `tam_hogar`
- `ingreso`
- `salario`
- `monto`
- `facturacion`

#### Categoricas cuasi-identificadoras
- departamento
- localidad
- ocupacion
- sector
- tramo
- nivel educativo
- sexo, cuando corresponda

### Sugerir `SENS`

Para columnas como:
- `diagnostico`
- `enfermedad`
- `patologia`
- `beneficio`
- `subsidio`
- `sancion`
- `riesgo`
- `situacion`
- `indicador_privado`

### Sugerir `PRIV`

Para columnas como:
- `observacion`
- `comentario`
- `nota`
- `descripcion`
- `direccion`
- `telefono`
- `mail`
- `correo`
- `detalle`
- `texto`

Y tambien para texto libre largo o muy variado.

### Sugerir `KEEP`

Cuando la variable aporta valor analitico y no activa señales fuertes de:
- identificacion directa;
- cuasi-identificacion;
- sensibilidad;
- privacidad.

---

## 8. Sistema de ayuda recomendado

La ayuda no debe vivir solo en un modal largo ni en un manual separado.

Se recomienda una ayuda en tres niveles:

### 8.1 Ayuda contextual minima

Tooltips en:
- rol;
- tratamiento;
- riesgo;
- estado.

### 8.2 Ayuda aplicada en ficha lateral

Cada variable debe mostrar:
- que significa el rol elegido;
- por que fue sugerido;
- como impacta en `k-anonymity`;
- como puede bloquear la liberacion.

### 8.3 Guia de flujo de trabajo

La interfaz debe explicar el flujo general:

1. cargar dataset
2. revisar sugerencias
3. confirmar rol principal
4. ajustar tratamiento tecnico
5. ejecutar evaluacion
6. revisar bloqueos y resumen de auditoria
7. exportar solo si el estado final es `Liberable`

---

## 9. Implicancias sobre el MVP actual

### Lo que este rediseño intenta preservar

- resumen de auditoria;
- preview;
- plantillas;
- generacion de codigo;
- gating de exportacion;
- modelo `release-safe`.

### Lo que este rediseño desplaza

- el drag-and-drop deja de ser el mecanismo principal de clasificacion;
- la semantica ya no se infiere de la topologia visual de zonas;
- la explicacion pasa a estar mas cerca de la variable concreta.

---

## 10. Estrategia de implementacion sugerida

Se recomienda una implementacion por fases:

### Fase 1
- tabla principal de variables;
- badge de rol principal;
- ayuda contextual minima.

### Fase 2
- ficha lateral de detalle;
- tratamiento tecnico contextual;
- motivo de sugerencia.

### Fase 3
- migracion de la logica actual de zonas al modelo nuevo;
- compatibilidad con persistencia y plantillas.

### Fase 4
- retiro o degradacion del drag-and-drop viejo a modo secundario o experimental.

---

## 11. Riesgos y limites

- el rediseño no sustituye por si solo la implementacion de `l-diversity` o `t-closeness`;
- una mejor UI no elimina la necesidad de criterio humano;
- si se intenta conservar simultaneamente la vieja UX y la nueva sin transicion clara, el producto puede quedar mas confuso, no menos.

---

## 12. Siguiente paso recomendado

Transformar esta propuesta en un plan de implementacion UX/UI especifico, con:
- alcance por fase;
- impacto sobre tests;
- compatibilidad con plantillas;
- y estrategia de migracion desde el modelo actual.
