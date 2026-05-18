# Diseno de configuracion opcional para `dataset_profile_for_ai()`

## Proposito

Definir una forma de configuracion que:

- no vuelva inutil el helper cuando se usa por primera vez;
- no obligue a revisar columna por columna para obtener valor;
- permita correcciones puntuales sobre heuristicas automaticas;
- y deje abierto el camino a una futura biblioteca compartida de reglas por esquema o tabla.

## Problema de diseno

El helper `dataset_profile_for_ai()` compite, conceptualmente, con algo tan simple como:

```r
glimpse(data, width = 0)
```

Si su uso requiere que la persona:

- analice manualmente decenas de variables;
- configure columna por columna antes de obtener un resultado util;
- o aprenda una API compleja para empezar;

entonces deja de ser una mejora pragmatica y pasa a ser una herramienta con demasiada friccion.

Al mismo tiempo, solo confiar en heuristicas automaticas deja fuera contexto institucional valioso, por ejemplo:

- faltantes estructuralmente esperables;
- columnas conocidas como sensibles;
- identificadores operativos que no se detectan bien solo por nombre o contenido;
- o convenciones compartidas por varios usuarios sobre una misma tabla.

## Decision principal

Se recomienda un modelo de **configuracion opcional y liviana**, con esta jerarquia:

1. el helper debe ser util sin configuracion;
2. la configuracion local del usuario debe actuar como override puntual;
3. una futura biblioteca compartida debe poder agregarse mas adelante sin romper la API base.

No se recomienda, por ahora:

- exigir configuracion por columna como condicion de uso;
- ni depender desde ya de una biblioteca institucional compartida.

## Criterios UX/UI

Con lente de `brainstorming` y `ui-ux-pro-max`, la configuracion recomendada debe cumplir:

### 1. Friccion minima de arranque

La llamada mas simple debe seguir siendo:

```r
profile <- profile_dataset_for_ai(data, dataset_name = "mi_tabla")
cat(render_dataset_profile_for_ai(profile))
```

Eso tiene que producir un resultado util por si solo.

### 2. Legibilidad para personas no tecnicas o no angloparlantes

Los nombres de configuracion deben ser:

- en espanol;
- orientados a intencion;
- y revisables por terceros sin necesidad de leer el codigo del helper.

### 3. Visibilidad del origen de las decisiones

El sistema debe distinguir entre:

- inferido automaticamente;
- declarado por el usuario;
- y, en el futuro, declarado por una biblioteca compartida.

La salida no deberia decir solo "se aplicaron reglas", sino **cuales reglas se aplicaron a cuales variables**.

### 4. Reversibilidad

Quitar o cambiar una regla debe ser simple y evidente.

Por eso no se recomienda un formato demasiado anidado o cargado para la primera version.

## Formas de configuracion consideradas

### Opcion 1: configuracion tecnica corta

```r
config = list(
  expected_missing = c("fecha_hasta"),
  sensitive_columns = c("diagnostico"),
  identifier_columns = c("correo_contacto")
)
```

Ventajas:

- breve;
- familiar para quien programa en R.

Desventajas:

- claves en ingles;
- poca legibilidad para usuarios no tecnicos;
- mas propensa a errores silenciosos.

### Opcion 2: configuracion declarativa en espanol

```r
config = list(
  faltantes_esperables = c("fecha_hasta"),
  columnas_sensibles = c("diagnostico"),
  columnas_identificatorias = c("correo_contacto"),
  columnas_texto_libre = c("observacion")
)
```

Ventajas:

- clara;
- mantenible;
- orientada a intencion;
- apta para scripts compartidos.

Desventajas:

- menos compacta;
- menos “tecnica” para quien esperaria nombres en ingles.

### Opcion 3: configuracion por columna

```r
config = list(
  persona_id = list(tipo_forzado = "identificatoria"),
  fecha_hasta = list(faltantes = "esperables"),
  diagnostico = list(tipo_forzado = "sensible"),
  observacion = list(tipo_forzado = "texto_libre")
)
```

Ventajas:

- muy explicita;
- precisa por variable.

Desventajas:

- demasiado verbosa para empezar;
- poco compatible con el objetivo de mantener baja friccion.

## Recomendacion

Se recomienda la **Opcion 2** como primera capa.

Es decir, una configuracion declarativa, en espanol y por grupos de columnas:

```r
config_perfil_ia <- list(
  faltantes_esperables = c("fecha_hasta"),
  columnas_sensibles = c("diagnostico"),
  columnas_identificatorias = c("correo_contacto"),
  columnas_texto_libre = c("observacion")
)
```

## API propuesta

La funcion principal podria aceptar:

```r
profile_dataset_for_ai(
  data,
  dataset_name = NULL,
  config = NULL,
  max_levels = 12,
  top_n = 10,
  round_digits = 2
)
```

Donde `config` sea opcional.

## Semantica de `config`

### Campos recomendados para primera version

- `faltantes_esperables`
- `columnas_sensibles`
- `columnas_identificatorias`
- `columnas_texto_libre`

Cada uno deberia aceptar un vector de nombres de columnas.

### Ejemplo de uso

```r
config_perfil_ia <- list(
  faltantes_esperables = c("fecha_hasta"),
  columnas_sensibles = c("diagnostico", "beneficio"),
  columnas_identificatorias = c("correo_contacto", "telefono_contacto"),
  columnas_texto_libre = c("observacion")
)

profile <- profile_dataset_for_ai(
  data = mi_dataset,
  dataset_name = "mi_dataset",
  config = config_perfil_ia
)
```

## Regla de precedencia

La resolucion recomendada es:

1. regla explicita del usuario en `config`
2. regla proveniente de futura biblioteca compartida
3. heuristica automatica del helper

Motivo:

- respeta la intencion local del script;
- deja espacio para gobernanza compartida;
- y evita que la heuristica opaque decisiones humanas declaradas.

## Reglas de visibilidad del estado

El objeto de perfil y, cuando corresponda, el renderer, deberian poder informar para cada variable:

- clasificacion final;
- origen de la clasificacion;
- y reglas declaradas aplicadas.

Ejemplos deseables:

- `fecha_hasta`: faltantes esperables (`declarado por usuario`)
- `diagnostico`: sensible (`declarado por usuario`)
- `correo_contacto`: identificatoria (`declarado por usuario`)
- `tramo`: categorica (`inferido automaticamente`)

Y a nivel general:

- `Se aplicaron reglas declaradas por usuario para: fecha_hasta, diagnostico, correo_contacto.`

## Validaciones recomendadas

La primera version no deberia ser demasiado compleja, pero si deberia:

- advertir si una columna declarada en `config` no existe en `data`;
- advertir si una misma columna aparece en categorias incompatibles;
- mantener mensajes en espanol;
- y evitar ignorar silenciosamente errores de configuracion.

## No objetivo inmediato

No se recomienda implementar todavia:

- reglas por regex;
- politicas jerarquicas complejas;
- multiples capas institucionales simultaneas;
- ni integracion directa con tablas o vistas externas.

Todo eso puede venir despues, si el helper demuestra valor sostenido.

## Camino de evolucion recomendado

### Etapa 1

Helper autosuficiente con heuristicas, mas `config` opcional y liviana.

### Etapa 2

Posibilidad de cargar una biblioteca compartida, por ejemplo:

```r
config_perfil_ia <- cargar_reglas_perfil("padron_personas")
```

### Etapa 3

Soporte mas rico para reglas por esquema, fuente o institucion.

## Decision final

Se aprueba avanzar, cuando corresponda, con una **configuracion opcional, declarativa y en espanol**, orientada a intencion y no a detalle excesivamente tecnico.

La herramienta debe seguir siendo util sin configuracion, y la configuracion debe mejorar el resultado, no ser un requisito para que el helper valga la pena.
