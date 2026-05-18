# Diseno de resolucion de metadata para `dataset_profile_for_ai()`

## Proposito

Definir como deberia resolver el helper una biblioteca de metadata por fuente sin:

- obligar al usuario a pasar siempre rutas manualmente;
- introducir efectos secundarios invisibles;
- ni depender desde el inicio de una infraestructura institucional compartida.

## Problema de diseno

El subproyecto de perfilado seguro para IA ya admite heuristicas y configuracion local opcional. El siguiente paso natural es poder enriquecer esas decisiones con metadata por fuente, por ejemplo:

- roles esperables por columna;
- faltantes estructuralmente esperables;
- sensibilidad conocida de ciertas variables;
- o tipos temporales complejos que una oficina ya conoce bien.

Pero la resolucion de esa metadata necesita cuidar tres cosas al mismo tiempo:

1. facilidad de uso;
2. ausencia de efectos colaterales sorpresivos;
3. prudencia institucional sobre que metadata puede ver cada oficina.

## Decision principal

Se recomienda un modelo de resolucion en capas, con prioridad local:

1. `metadata_dir` explicito en la llamada
2. carpeta predeterminada declarada en opciones locales
3. sin metadata declarada, usar heuristicas y `config`

No se recomienda por ahora:

- fijar automaticamente una carpeta global como efecto secundario del perfilado;
- ni depender desde ya de una biblioteca institucional compartida transversal.

## API recomendada

La funcion principal deberia poder crecer a algo como:

```r
profile_dataset_for_ai(
  data,
  dataset_name = NULL,
  config = NULL,
  metadata_dir = NULL,
  max_levels = 12,
  top_n = 10,
  round_digits = 2
)
```

## Regla de resolucion

### 1. Ruta explicita por llamada

Si `metadata_dir` viene informado, esa ruta se usa solo para esa ejecucion.

Eso debe tener prioridad maxima porque:

- expresa intencion puntual del usuario;
- evita ambiguedad;
- y permite pruebas o usos experimentales sin tocar la configuracion del entorno.

### 2. Ruta predeterminada local

Si `metadata_dir` es `NULL`, el helper deberia mirar una opcion local, por ejemplo:

```r
getOption("obfuscator.metadata_dir")
```

Esto encaja bien con entornos como RStudio Server y carpetas compartidas por oficina, por ejemplo:

- `/datos/sinf/metadata_fuentes/`

### 3. Sin metadata disponible

Si no hay ruta explicita ni opcion configurada, el helper debe seguir funcionando solo con:

- heuristicas automaticas;
- y `config` local opcional.

La ausencia de metadata no debe romper el flujo.

## Estado visible esperado

El resultado deberia poder informar, al menos internamente:

- `metadata_source = "none" | "explicit_dir" | "configured_dir"`
- `metadata_path = "..." | NULL`
- `metadata_match = "exact" | "none" | "ambiguous"`

Y, cuando sea util en el renderer o en advertencias:

- `No se encontro metadata declarada para esta fuente; se usaron heuristicas.`
- `Metadata aplicada desde: /datos/sinf/metadata_fuentes/padron_personas.json`

## Por que no fijar la carpeta automaticamente

No se recomienda que `profile_dataset_for_ai()` haga algo como:

- detectar que no hay carpeta configurada;
- usar `metadata_dir` una vez;
- y guardarla automaticamente como opcion global.

Eso seria un efecto secundario silencioso, dificil de ver y de revertir.

Desde UX/API, una funcion de perfilado no deberia mutar configuracion persistente o semiglobal sin una accion explicita separada.

## Recomendacion para fijar carpeta predeterminada

La forma recomendada es una funcion separada, por ejemplo:

```r
set_obfuscator_metadata_dir("/datos/sinf/metadata_fuentes")
```

o una variante equivalente en espanol si despues se prioriza una API totalmente localizada.

Su responsabilidad deberia ser:

- validar que la ruta exista;
- guardarla en `options(obfuscator.metadata_dir = "...")`;
- devolver confirmacion clara;
- y no hacer nada mas.

## Sugerencia de adopcion sin efectos secundarios

Cuando el usuario llame:

```r
profile_dataset_for_ai(
  data,
  dataset_name = "mi_tabla",
  metadata_dir = "/datos/sinf/metadata_fuentes"
)
```

y no exista carpeta predeterminada configurada, el helper podria emitir un mensaje no intrusivo como:

```text
Se uso metadata_dir solo para esta ejecucion.
Si quieres reutilizar esta carpeta como predeterminada en esta sesion, ejecuta:
set_obfuscator_metadata_dir("/datos/sinf/metadata_fuentes")
```

Eso reduce friccion y al mismo tiempo evita efectos secundarios ocultos.

## Ubicacion recomendada de la metadata

Para el contexto actual, se recomienda empezar por una carpeta local o de grupo, por ejemplo:

- `/datos/<grupo>/metadata_fuentes/`

Ejemplo:

- `/datos/sinf/metadata_fuentes/`

No se recomienda, en esta etapa, usar ya una biblioteca corporativa unica visible por todas las oficinas, porque la metadata misma puede revelar informacion institucional sensible sobre:

- existencia de ciertas fuentes;
- nombres de columnas;
- o estructura funcional de otros dominios.

## Futuro posible

Mas adelante podria agregarse una capa adicional de resolucion, si existe gobernanza clara:

1. `metadata_dir` explicito
2. carpeta local configurada
3. biblioteca compartida autorizada
4. heuristica pura

Pero ese paso no deberia darse antes de resolver permisos y visibilidad entre oficinas.

## Decision final

Se aprueba un modelo de resolucion con prioridad local, sin efectos secundarios automaticos y con una funcion separada para fijar la carpeta predeterminada.

El helper debe seguir siendo:

- usable sin metadata;
- mas potente con metadata local;
- y prudente respecto de la visibilidad inter-oficinas.
