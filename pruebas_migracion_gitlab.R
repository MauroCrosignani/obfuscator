# Runner de pruebas manuales para migracion a GitLab corporativo
# Genera y actualiza un reporte Markdown acumulativo en getwd().

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) y else x
}

safe_string <- function(x) {
  if (length(x) == 0 || is.null(x)) {
    return("")
  }

  if (is.function(x)) {
    fn_text <- paste(deparse(x), collapse = " ")
    return(paste0("<function> ", fn_text))
  }

  if (is.environment(x)) {
    return("<environment>")
  }

  if (is.list(x) && !is.data.frame(x)) {
    rendered <- capture.output(str(x, give.attr = FALSE, vec.len = 5))
    return(paste(rendered, collapse = " | "))
  }

  rendered <- tryCatch(
    paste(as.character(x), collapse = ", "),
    error = function(e) {
      paste(capture.output(str(x, give.attr = FALSE, vec.len = 5)), collapse = " | ")
    }
  )

  rendered
}

markdown_escape <- function(x) {
  x <- safe_string(x)
  x <- gsub("\\|", "\\\\|", x)
  x <- gsub("\r", "", x)
  x
}

report_file_path <- function() {
  file.path(getwd(), "REPORTE_PRUEBAS_MIGRACION_GITLAB.md")
}

append_lines <- function(path, lines) {
  cat(paste0(lines, collapse = "\n"), file = path, append = TRUE)
  cat("\n", file = path, append = TRUE)
}

init_report_if_needed <- function(path) {
  if (file.exists(path)) {
    return(invisible(path))
  }

  lines <- c(
    "# Reporte de Pruebas de Migracion a GitLab Corporativo",
    "",
    "Este documento se completa automaticamente desde `pruebas_migracion_gitlab.R`.",
    "",
    "## Convenciones",
    "",
    "- `Resultado automatico`: lo que el script pudo deducir por si mismo.",
    "- `Observacion del usuario`: lo que requiere validacion visual o manual.",
    "- `Conclusion`: lectura resumida del resultado.",
    "- `Accion recomendada`: proximo paso sugerido para una migracion fluida.",
    ""
  )
  append_lines(path, lines)
  invisible(path)
}

format_kv_lines <- function(x) {
  if (length(x) == 0) {
    return("- Sin datos automaticos adicionales.")
  }

  values <- unlist(x, recursive = FALSE, use.names = TRUE)
  vapply(names(values), function(nm) {
    sprintf("- `%s`: %s", nm, markdown_escape(values[[nm]]))
  }, character(1), USE.NAMES = FALSE)
}

prompt_yes_no <- function(question) {
  repeat {
    answer <- trimws(readline(paste0(question, " [s/n]: ")))
    normalized <- tolower(iconv(answer, to = "ASCII//TRANSLIT"))
    if (normalized %in% c("s", "si", "y", "yes")) return("Si")
    if (normalized %in% c("n", "no")) return("No")
    message("Respuesta no reconocida. Escribe 's' o 'n'.")
  }
}

prompt_optional_text <- function(question) {
  trimws(readline(paste0(question, " (opcional): ")))
}

write_run_header <- function(path, metadata) {
  lines <- c(
    "",
    sprintf("## Corrida %s", metadata$run_started),
    "",
    sprintf("- **Directorio de trabajo:** `%s`", markdown_escape(metadata$working_directory)),
    sprintf("- **Host:** `%s`", markdown_escape(metadata$host)),
    sprintf("- **Usuario:** `%s`", markdown_escape(metadata$user)),
    sprintf("- **Version de R:** `%s`", markdown_escape(metadata$r_version)),
    sprintf("- **Plataforma:** `%s`", markdown_escape(metadata$platform)),
    sprintf("- **Sistema operativo:** `%s`", markdown_escape(metadata$sysname)),
    ""
  )
  append_lines(path, lines)
}

write_test_section <- function(path, test, automatic, manual, conclusion, action) {
  lines <- c(
    sprintf("### %s. %s", markdown_escape(test$id), markdown_escape(test$title)),
    "",
    sprintf("**Objetivo:** %s", markdown_escape(test$objective)),
    "",
    sprintf("**Metodo:** %s", markdown_escape(test$method)),
    "",
    "**Resultado automatico**",
    ""
  )
  lines <- c(lines, format_kv_lines(automatic), "")

  if (length(manual) > 0) {
    lines <- c(lines, "**Observacion del usuario**", "")
    lines <- c(lines, format_kv_lines(manual), "")
  }

  lines <- c(
    lines,
    sprintf("**Conclusion:** %s", markdown_escape(conclusion)),
    "",
    sprintf("**Accion recomendada:** %s", markdown_escape(action)),
    ""
  )
  append_lines(path, lines)
}

run_remote_probe <- function(url, timeout_seconds = 10) {
  started <- Sys.time()
  result <- list(
    url = url,
    ok = FALSE,
    message = "",
    seconds = NA_real_
  )

  con <- NULL
  old_timeout <- getOption("timeout")
  on.exit({
    options(timeout = old_timeout)
    if (!is.null(con)) {
      try(close(con), silent = TRUE)
    }
  }, add = TRUE)

  options(timeout = timeout_seconds)

  probe <- tryCatch({
    con <- url(url, open = "rb")
    raw <- readBin(con, what = "raw", n = 512)
    list(ok = length(raw) > 0, message = sprintf("Se leyeron %s bytes.", length(raw)))
  }, error = function(e) {
    list(ok = FALSE, message = conditionMessage(e))
  })

  result$ok <- isTRUE(probe$ok)
  result$message <- probe$message
  result$seconds <- round(as.numeric(difftime(Sys.time(), started, units = "secs")), 3)
  result
}

run_shiny_probe <- function(title, ui_builder, server_builder = NULL) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    return(list(
      app_started = FALSE,
      app_result = NULL,
      error = "El paquete `shiny` no esta instalado."
    ))
  }

  if (is.null(server_builder)) {
    server_builder <- function(input, output, session) {
      shiny::observeEvent(input$finish_test, {
        shiny::stopApp(list(finished = TRUE))
      })
    }
  }

  app <- shiny::shinyApp(
    ui = ui_builder(),
    server = server_builder
  )

  started <- FALSE
  result <- NULL
  err <- NULL

  tryCatch({
    started <- TRUE
    result <- shiny::runApp(app, launch.browser = TRUE)
  }, error = function(e) {
    err <<- conditionMessage(e)
  })

  list(
    app_started = started && is.null(err),
    app_result = result,
    error = err
  )
}

manual_result_block <- function(question, extra_prompt = "Comentario breve") {
  list(
    observed = prompt_yes_no(question),
    comment = prompt_optional_text(extra_prompt)
  )
}

test_environment_diagnostics <- function() {
  installed <- rownames(installed.packages())
  list(
    automatic = list(
      working_directory = getwd(),
      shiny_instalado = "shiny" %in% installed,
      readr_instalado = "readr" %in% installed,
      readxl_instalado = "readxl" %in% installed,
      navegador_opcion = getOption("browser") %||% "",
      interactive = interactive(),
      lib_paths = paste(.libPaths(), collapse = " | ")
    ),
    manual = list(),
    conclusion = "Diagnostico base registrado.",
    action = "Usar esta seccion como referencia del entorno exacto donde se ejecutaron las demas pruebas."
  )
}

test_network_connectivity <- function() {
  urls <- c(
    fontawesome_cdn = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css",
    sortable_cdn = "https://cdn.jsdelivr.net/npm/sortablejs@1.15.0/Sortable.min.js",
    gitlab_badge = "https://img.shields.io/badge/GitLab-remoto-orange"
  )

  probes <- lapply(urls, run_remote_probe)
  automatic <- unlist(lapply(names(probes), function(nm) {
    probe <- probes[[nm]]
    c(
      setNames(as.list(probe$ok), paste0(nm, "_ok")),
      setNames(as.list(probe$seconds), paste0(nm, "_segundos")),
      setNames(as.list(probe$message), paste0(nm, "_mensaje"))
    )
  }), recursive = FALSE, use.names = TRUE)

  ok_count <- sum(vapply(probes, function(x) isTRUE(x$ok), logical(1)))
  conclusion <- if (ok_count == length(probes)) {
    "El host de R alcanzo todos los recursos remotos probados."
  } else if (ok_count == 0) {
    "El host de R no pudo acceder a ninguno de los recursos remotos probados."
  } else {
    "El host de R alcanzo solo una parte de los recursos remotos probados."
  }

  action <- if (ok_count == 0) {
    "Asumir entorno fuertemente restringido y priorizar vendorizar assets en `www/`."
  } else {
    "Comparar este resultado con las pruebas visuales del navegador para distinguir restriccion del host vs restriccion del browser."
  }

  list(
    automatic = automatic,
    manual = list(),
    conclusion = conclusion,
    action = action
  )
}

fontawesome_test_ui <- function() {
  shiny::fluidPage(
    shiny::tags$head(
      shiny::tags$link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css"),
      shiny::tags$script(
        shiny::HTML(
          "document.addEventListener('DOMContentLoaded', function() {
             if (window.Shiny) {
               Shiny.setInputValue('fa_dom_loaded', true, {priority: 'event'});
             }
           });"
        )
      )
    ),
    shiny::tags$h2("Prueba Font Awesome desde CDN"),
    shiny::tags$p("Deberias ver cinco iconos correctamente dibujados, no cuadros vacios."),
    shiny::tags$div(
      style = "display:flex; gap:20px; font-size:32px; margin:20px 0;",
      shiny::tags$i(class = "fas fa-chart-simple"),
      shiny::tags$i(class = "fas fa-sitemap"),
      shiny::tags$i(class = "fas fa-key"),
      shiny::tags$i(class = "fas fa-moon"),
      shiny::tags$i(class = "fas fa-question-circle")
    ),
    shiny::tags$code("fas fa-chart-simple / fa-sitemap / fa-key / fa-moon / fa-question-circle"),
    shiny::tags$hr(),
    shiny::actionButton("finish_test", "Finalizar prueba")
  )
}

fontawesome_test_server <- function(input, output, session) {
  loaded <- shiny::reactiveVal(FALSE)
  shiny::observeEvent(input$fa_dom_loaded, loaded(TRUE))
  shiny::observeEvent(input$finish_test, {
    shiny::stopApp(list(dom_loaded = loaded()))
  })
}

test_fontawesome_cdn <- function() {
  probe <- run_shiny_probe(
    "Font Awesome CDN",
    ui_builder = fontawesome_test_ui,
    server_builder = fontawesome_test_server
  )

  manual <- manual_result_block(
    "Viste correctamente los iconos de Font Awesome desde CDN?",
    "Si no se vieron bien, describe que aparecio"
  )

  automatic <- list(
    app_started = probe$app_started,
    js_dom_loaded = probe$app_result$dom_loaded %||% FALSE,
    app_error = probe$error %||% ""
  )

  ok <- identical(manual$observed, "Si")
  list(
    automatic = automatic,
    manual = manual,
    conclusion = if (ok) "Los iconos remotos se renderizaron visualmente en este entorno." else "No hay confirmacion visual de render correcto de Font Awesome remoto.",
    action = if (ok) "Font Awesome remoto podria mantenerse, aunque sigue siendo recomendable planificar fallback local." else "Vendorizar Font Awesome o reemplazar iconos por recursos locales o alternativas de Shiny."
  )
}

sortable_test_ui <- function() {
  shiny::fluidPage(
    shiny::tags$head(
      shiny::tags$script(src = "https://cdn.jsdelivr.net/npm/sortablejs@1.15.0/Sortable.min.js"),
      shiny::tags$script(
        shiny::HTML(
          "document.addEventListener('DOMContentLoaded', function() {
             setTimeout(function() {
               var status = typeof Sortable !== 'undefined';
               if (window.Shiny) {
                 Shiny.setInputValue('sortable_available', status, {priority: 'event'});
               }
               if (!status) return;
               var list = document.getElementById('sortable-list');
               new Sortable(list, { animation: 150 });
             }, 200);
           });
           function reportOrder() {
             var items = Array.from(document.querySelectorAll('#sortable-list li')).map(function(el) {
               return el.innerText;
             });
             if (window.Shiny) {
               Shiny.setInputValue('sortable_order', items, {priority: 'event'});
             }
           }"
        )
      )
    ),
    shiny::tags$h2("Prueba SortableJS desde CDN"),
    shiny::tags$p("Intenta reordenar los elementos y luego presiona 'Reportar orden' y 'Finalizar prueba'."),
    shiny::tags$ul(
      id = "sortable-list",
      style = "list-style:none; padding:0; width:320px;",
      shiny::tags$li(style = "padding:10px; margin:5px 0; border:1px solid #ccc; cursor:move;", "Item A"),
      shiny::tags$li(style = "padding:10px; margin:5px 0; border:1px solid #ccc; cursor:move;", "Item B"),
      shiny::tags$li(style = "padding:10px; margin:5px 0; border:1px solid #ccc; cursor:move;", "Item C")
    ),
    shiny::tags$button(type = "button", onclick = "reportOrder()", "Reportar orden"),
    shiny::actionButton("finish_test", "Finalizar prueba")
  )
}

sortable_test_server <- function(input, output, session) {
  sortable_available <- shiny::reactiveVal(FALSE)
  final_order <- shiny::reactiveVal(character(0))

  shiny::observeEvent(input$sortable_available, sortable_available(isTRUE(input$sortable_available)))
  shiny::observeEvent(input$sortable_order, {
    final_order(input$sortable_order)
  })
  shiny::observeEvent(input$finish_test, {
    shiny::stopApp(list(
      sortable_available = sortable_available(),
      final_order = paste(final_order(), collapse = " > ")
    ))
  })
}

test_sortable_cdn <- function() {
  probe <- run_shiny_probe(
    "SortableJS CDN",
    ui_builder = sortable_test_ui,
    server_builder = sortable_test_server
  )

  manual <- manual_result_block(
    "Pudiste reordenar visualmente la lista usando SortableJS?",
    "Si no funciono, describe si la lista estuvo inmovil, si falto JS o si hubo otro sintoma"
  )

  automatic <- list(
    app_started = probe$app_started,
    sortable_available = probe$app_result$sortable_available %||% FALSE,
    final_order = probe$app_result$final_order %||% "",
    app_error = probe$error %||% ""
  )

  ok <- identical(manual$observed, "Si")
  list(
    automatic = automatic,
    manual = manual,
    conclusion = if (ok) "SortableJS remoto parece utilizable en este entorno." else "No hay evidencia visual suficiente de que SortableJS remoto funcione correctamente.",
    action = if (ok) "Puede mantenerse temporalmente, aunque conviene evaluar version local para independencia de CDN." else "Vendorizar SortableJS o reemplazar esa interaccion por una alternativa mas simple compatible con el entorno."
  )
}

js_inline_test_ui <- function() {
  shiny::fluidPage(
    shiny::tags$head(
      shiny::tags$script(
        shiny::HTML(
          "function inlineJsChange() {
             var el = document.getElementById('inline-js-target');
             el.innerText = 'Texto cambiado por JavaScript inline';
             if (window.Shiny) {
               Shiny.setInputValue('inline_js_counter', (new Date()).getTime(), {priority: 'event'});
             }
           }"
        )
      )
    ),
    shiny::tags$h2("Prueba JavaScript inline"),
    shiny::tags$p(id = "inline-js-target", "Texto original"),
    shiny::tags$button(type = "button", onclick = "inlineJsChange()", "Ejecutar JavaScript inline"),
    shiny::tags$hr(),
    shiny::actionButton("finish_test", "Finalizar prueba")
  )
}

js_inline_test_server <- function(input, output, session) {
  counter <- shiny::reactiveVal(0)
  shiny::observeEvent(input$inline_js_counter, {
    counter(counter() + 1)
  })
  shiny::observeEvent(input$finish_test, {
    shiny::stopApp(list(inline_js_triggered = counter()))
  })
}

test_js_inline <- function() {
  probe <- run_shiny_probe(
    "JavaScript inline",
    ui_builder = js_inline_test_ui,
    server_builder = js_inline_test_server
  )

  manual <- manual_result_block(
    "Al presionar el boton, cambio el texto de la pagina?",
    "Si no cambio, describe lo que sucedio"
  )

  automatic <- list(
    app_started = probe$app_started,
    inline_js_triggered = probe$app_result$inline_js_triggered %||% 0,
    app_error = probe$error %||% ""
  )

  ok <- identical(manual$observed, "Si")
  list(
    automatic = automatic,
    manual = manual,
    conclusion = if (ok) "El navegador ejecuto JavaScript inline dentro de la app Shiny." else "No hay confirmacion de ejecucion correcta de JavaScript inline.",
    action = if (ok) "Las mejoras JS simples parecen viables en el entorno." else "Reducir dependencia de JS custom y revisar politicas del navegador corporativo."
  )
}

localstorage_test_ui <- function() {
  shiny::fluidPage(
    shiny::tags$head(
      shiny::tags$script(
        shiny::HTML(
          "function saveLocalStorageValue() {
             var value = 'obfuscator-test-' + (new Date()).getTime();
             localStorage.setItem('obfuscator-test-key', value);
             document.getElementById('ls-value').innerText = value;
             if (window.Shiny) {
               Shiny.setInputValue('ls_saved_value', value, {priority: 'event'});
             }
           }
           function readLocalStorageValue() {
             var value = localStorage.getItem('obfuscator-test-key') || '';
             document.getElementById('ls-value').innerText = value;
             if (window.Shiny) {
               Shiny.setInputValue('ls_read_value', value, {priority: 'event'});
             }
           }
           document.addEventListener('DOMContentLoaded', function() {
             var supported = typeof localStorage !== 'undefined';
             if (window.Shiny) {
               Shiny.setInputValue('ls_supported', supported, {priority: 'event'});
             }
             if (supported) readLocalStorageValue();
           });"
        )
      )
    ),
    shiny::tags$h2("Prueba localStorage"),
    shiny::tags$p("Puedes guardar un valor y recargar la pagina para ver si persiste."),
    shiny::tags$p("Valor visible:", shiny::tags$strong(id = "ls-value", "")),
    shiny::tags$button(type = "button", onclick = "saveLocalStorageValue()", "Guardar valor"),
    shiny::tags$button(type = "button", onclick = "readLocalStorageValue()", "Leer valor"),
    shiny::tags$hr(),
    shiny::actionButton("finish_test", "Finalizar prueba")
  )
}

localstorage_test_server <- function(input, output, session) {
  supported <- shiny::reactiveVal(FALSE)
  saved <- shiny::reactiveVal("")
  readv <- shiny::reactiveVal("")

  shiny::observeEvent(input$ls_supported, supported(isTRUE(input$ls_supported)))
  shiny::observeEvent(input$ls_saved_value, saved(input$ls_saved_value))
  shiny::observeEvent(input$ls_read_value, readv(input$ls_read_value))
  shiny::observeEvent(input$finish_test, {
    shiny::stopApp(list(
      ls_supported = supported(),
      saved_value = saved(),
      read_value = readv()
    ))
  })
}

test_localstorage <- function() {
  probe <- run_shiny_probe(
    "localStorage",
    ui_builder = localstorage_test_ui,
    server_builder = localstorage_test_server
  )

  manual <- manual_result_block(
    "Pudiste guardar y recuperar un valor usando localStorage, incluso tras recargar?",
    "Si hubo limitaciones, describe si fue al guardar, leer o persistir"
  )

  automatic <- list(
    app_started = probe$app_started,
    ls_supported = probe$app_result$ls_supported %||% FALSE,
    saved_value = probe$app_result$saved_value %||% "",
    read_value = probe$app_result$read_value %||% "",
    app_error = probe$error %||% ""
  )

  ok <- identical(manual$observed, "Si")
  list(
    automatic = automatic,
    manual = manual,
    conclusion = if (ok) "localStorage parece disponible y utilizable en este entorno." else "No hay confirmacion de persistencia util de localStorage en este entorno.",
    action = if (ok) "Se puede mantener persistencia simple en cliente, aunque conviene tener fallback del lado servidor." else "Evitar depender de localStorage para funciones criticas o agregar fallback sin almacenamiento del navegador."
  )
}

clipboard_test_ui <- function() {
  shiny::fluidPage(
    shiny::tags$head(
      shiny::tags$link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css"),
      shiny::tags$script(
        shiny::HTML(
          "function copyProbeText() {
             var text = 'OBFUSCATOR_CLIPBOARD_OK';
             navigator.clipboard.writeText(text).then(function() {
               if (window.Shiny) {
                 Shiny.setInputValue('clipboard_status', 'ok', {priority: 'event'});
                 Shiny.setInputValue('clipboard_value', text, {priority: 'event'});
               }
             }).catch(function(err) {
               if (window.Shiny) {
                 Shiny.setInputValue('clipboard_status', 'error: ' + err, {priority: 'event'});
               }
             });
           }"
        )
      )
    ),
    shiny::tags$h2("Prueba navigator.clipboard"),
    shiny::tags$p("Presiona el boton, luego pega el contenido en el comentario de consola si quieres confirmarlo."),
    shiny::tags$button(type = "button", onclick = "copyProbeText()", shiny::tags$i(class = "fas fa-clipboard"), " Copiar texto de prueba"),
    shiny::tags$hr(),
    shiny::actionButton("finish_test", "Finalizar prueba")
  )
}

clipboard_test_server <- function(input, output, session) {
  status <- shiny::reactiveVal("")
  value <- shiny::reactiveVal("")
  shiny::observeEvent(input$clipboard_status, status(input$clipboard_status))
  shiny::observeEvent(input$clipboard_value, value(input$clipboard_value))
  shiny::observeEvent(input$finish_test, {
    shiny::stopApp(list(
      clipboard_status = status(),
      clipboard_value = value()
    ))
  })
}

test_clipboard <- function() {
  probe <- run_shiny_probe(
    "Clipboard",
    ui_builder = clipboard_test_ui,
    server_builder = clipboard_test_server
  )

  manual <- manual_result_block(
    "Se copio correctamente el texto al portapapeles?",
    "Si quieres, pega aqui el texto obtenido o describe el error"
  )

  automatic <- list(
    app_started = probe$app_started,
    clipboard_status = probe$app_result$clipboard_status %||% "",
    clipboard_value = probe$app_result$clipboard_value %||% "",
    app_error = probe$error %||% ""
  )

  ok <- identical(manual$observed, "Si")
  list(
    automatic = automatic,
    manual = manual,
    conclusion = if (ok) "navigator.clipboard parece utilizable en este entorno." else "No hay evidencia suficiente de que el portapapeles programatico funcione correctamente.",
    action = if (ok) "El copy-to-clipboard puede mantenerse, pero conviene dejar opcion de copia manual." else "Hacer opcional la copia programatica y proveer siempre un fallback visual seleccionable."
  )
}

dragdrop_test_ui <- function() {
  shiny::fluidPage(
    shiny::tags$head(
      shiny::tags$script(
        shiny::HTML(
          "document.addEventListener('DOMContentLoaded', function() {
             var item = document.getElementById('drag-item');
             var target = document.getElementById('drop-zone');
             item.addEventListener('dragstart', function(ev) {
               ev.dataTransfer.setData('text/plain', 'drag-item');
             });
             target.addEventListener('dragover', function(ev) {
               ev.preventDefault();
             });
             target.addEventListener('drop', function(ev) {
               ev.preventDefault();
               target.appendChild(item);
               if (window.Shiny) {
                 Shiny.setInputValue('dragdrop_success', true, {priority: 'event'});
               }
             });
           });"
        )
      )
    ),
    shiny::tags$h2("Prueba Drag and Drop HTML5"),
    shiny::tags$p("Arrastra la caja azul hacia la zona punteada."),
    shiny::tags$div(
      id = "drag-item",
      draggable = "true",
      style = "width:180px; padding:12px; background:#dbeafe; border:1px solid #60a5fa; margin-bottom:16px; cursor:move;",
      "Arrastrame"
    ),
    shiny::tags$div(
      id = "drop-zone",
      style = "width:260px; min-height:120px; border:2px dashed #94a3b8; padding:14px;",
      "Zona de destino"
    ),
    shiny::tags$hr(),
    shiny::actionButton("finish_test", "Finalizar prueba")
  )
}

dragdrop_test_server <- function(input, output, session) {
  dropped <- shiny::reactiveVal(FALSE)
  shiny::observeEvent(input$dragdrop_success, dropped(TRUE))
  shiny::observeEvent(input$finish_test, {
    shiny::stopApp(list(dragdrop_success = dropped()))
  })
}

test_dragdrop_html5 <- function() {
  probe <- run_shiny_probe(
    "Drag and Drop HTML5",
    ui_builder = dragdrop_test_ui,
    server_builder = dragdrop_test_server
  )

  manual <- manual_result_block(
    "Funciono el drag and drop HTML5 basico?",
    "Si no funciono, describe si no arrastro, no solto o no hubo reaccion"
  )

  automatic <- list(
    app_started = probe$app_started,
    dragdrop_success = probe$app_result$dragdrop_success %||% FALSE,
    app_error = probe$error %||% ""
  )

  ok <- identical(manual$observed, "Si")
  list(
    automatic = automatic,
    manual = manual,
    conclusion = if (ok) "El drag and drop HTML5 basico parece soportado por el navegador." else "No hay evidencia suficiente de soporte confiable para drag and drop HTML5 basico.",
    action = if (ok) "Si SortableJS falla pero esta prueba pasa, el problema es probablemente la libreria remota y no el browser." else "Disenar interacciones alternativas sin depender de drag and drop."
  )
}

create_local_asset_files <- function() {
  asset_dir <- file.path(tempdir(), "obfuscator_migration_assets")
  dir.create(asset_dir, recursive = TRUE, showWarnings = FALSE)

  css_path <- file.path(asset_dir, "probe.css")
  js_path <- file.path(asset_dir, "probe.js")
  svg_path <- file.path(asset_dir, "local-badge.svg")

  writeLines(c(
    "body { background: #f8fafc; }",
    ".probe-box { background: #111827; color: white; padding: 12px; border-radius: 10px; display: inline-block; }"
  ), css_path, useBytes = TRUE)

  writeLines(c(
    "document.addEventListener('DOMContentLoaded', function() {",
    "  var el = document.getElementById('local-asset-status');",
    "  if (el) {",
    "    el.innerText = 'JS local cargado';",
    "  }",
    "  if (window.Shiny) {",
    "    Shiny.setInputValue('local_asset_js_loaded', true, {priority: 'event'});",
    "  }",
    "});"
  ), js_path, useBytes = TRUE)

  writeLines(c(
    "<svg xmlns='http://www.w3.org/2000/svg' width='220' height='48'>",
    "<rect width='220' height='48' fill='#FC6D26' rx='8' ry='8'/>",
    "<text x='18' y='30' font-size='20' fill='white' font-family='Arial'>GitLab Local Badge</text>",
    "</svg>"
  ), svg_path, useBytes = TRUE)

  list(dir = asset_dir, css = css_path, js = js_path, svg = svg_path)
}

local_assets_test_ui <- function(asset_prefix) {
  shiny::fluidPage(
    shiny::tags$head(
      shiny::tags$link(rel = "stylesheet", href = sprintf("%s/probe.css", asset_prefix)),
      shiny::tags$script(src = sprintf("%s/probe.js", asset_prefix))
    ),
    shiny::tags$h2("Prueba de assets locales"),
    shiny::tags$div(class = "probe-box", "Si el CSS local cargo, esta caja sera oscura con texto blanco."),
    shiny::tags$p(id = "local-asset-status", "Esperando JS local..."),
    shiny::tags$img(src = sprintf("%s/local-badge.svg", asset_prefix), style = "margin-top:12px;"),
    shiny::tags$hr(),
    shiny::actionButton("finish_test", "Finalizar prueba")
  )
}

local_assets_test_server <- function(input, output, session) {
  loaded <- shiny::reactiveVal(FALSE)
  shiny::observeEvent(input$local_asset_js_loaded, loaded(TRUE))
  shiny::observeEvent(input$finish_test, {
    shiny::stopApp(list(local_asset_js_loaded = loaded()))
  })
}

test_local_assets <- function() {
  assets <- create_local_asset_files()
  prefix <- paste0("probe-assets-", as.integer(Sys.time()))
  shiny::addResourcePath(prefix, assets$dir)

  probe <- run_shiny_probe(
    "Assets locales",
    ui_builder = function() local_assets_test_ui(prefix),
    server_builder = local_assets_test_server
  )

  manual <- manual_result_block(
    "Se vieron correctamente el estilo local, el JS local y el badge SVG local?",
    "Describe que partes locales funcionaron o fallaron"
  )

  automatic <- list(
    app_started = probe$app_started,
    local_asset_js_loaded = probe$app_result$local_asset_js_loaded %||% FALSE,
    asset_dir = assets$dir,
    app_error = probe$error %||% ""
  )

  ok <- identical(manual$observed, "Si")
  list(
    automatic = automatic,
    manual = manual,
    conclusion = if (ok) "Los assets locales servidos por Shiny funcionaron correctamente." else "No hay evidencia suficiente de que la carga local de assets sea totalmente confiable.",
    action = if (ok) "Priorizar estrategia offline con assets locales en `www/`." else "Revisar politicas del navegador, mapeo de recursos y permisos locales antes de migrar la UI."
  )
}

download_test_ui <- function() {
  shiny::fluidPage(
    shiny::tags$h2("Prueba de descarga"),
    shiny::tags$p("Haz clic en el boton para descargar un CSV de prueba y luego finaliza."),
    shiny::downloadButton("download_probe", "Descargar CSV de prueba"),
    shiny::tags$hr(),
    shiny::actionButton("finish_test", "Finalizar prueba")
  )
}

download_test_server <- function(input, output, session) {
  marker_dir <- tempdir()
  marker_path <- file.path(marker_dir, "obfuscator_download_probe_marker.txt")
  if (file.exists(marker_path)) {
    unlink(marker_path, force = TRUE)
  }

  output$download_probe <- shiny::downloadHandler(
    filename = function() {
      "probe_download.csv"
    },
    content = function(file) {
      write.csv(data.frame(valor = c("ok", "download")), file, row.names = FALSE)
      writeLines(as.character(Sys.time()), marker_path, useBytes = TRUE)
    }
  )

  shiny::observeEvent(input$finish_test, {
    shiny::stopApp(list(
      download_invoked = file.exists(marker_path),
      marker_path = marker_path
    ))
  })
}

test_download_handler <- function() {
  probe <- run_shiny_probe(
    "Download handler",
    ui_builder = download_test_ui,
    server_builder = download_test_server
  )

  manual <- manual_result_block(
    "Pudiste descargar el archivo CSV desde el navegador?",
    "Si hubo un problema, describe si fue bloqueo del navegador, falta de descarga o archivo vacio"
  )

  automatic <- list(
    app_started = probe$app_started,
    download_invoked = probe$app_result$download_invoked %||% FALSE,
    marker_path = probe$app_result$marker_path %||% "",
    app_error = probe$error %||% ""
  )

  ok <- identical(manual$observed, "Si")
  list(
    automatic = automatic,
    manual = manual,
    conclusion = if (ok) "La descarga via Shiny parece utilizable en este entorno." else "No hay confirmacion de descarga exitosa desde el navegador.",
    action = if (ok) "Se puede mantener exportacion desde la app." else "Prever opcion alternativa de guardado en entorno o exportacion fuera de la UI."
  )
}

remote_badge_test_ui <- function() {
  shiny::fluidPage(
    shiny::tags$head(
      shiny::tags$script(
        shiny::HTML(
          "function reportRemoteBadge(status) {
             if (window.Shiny) {
               Shiny.setInputValue('remote_badge_status', status, {priority: 'event'});
             }
           }"
        )
      )
    ),
    shiny::tags$h2("Prueba de badge remoto"),
    shiny::tags$p("Deberias ver un badge naranja remoto cargado desde internet."),
    shiny::tags$img(
      src = "https://img.shields.io/badge/GitLab-remoto-orange",
      onload = "reportRemoteBadge('loaded')",
      onerror = "reportRemoteBadge('error')"
    ),
    shiny::tags$hr(),
    shiny::actionButton("finish_test", "Finalizar prueba")
  )
}

remote_badge_test_server <- function(input, output, session) {
  status <- shiny::reactiveVal("")
  shiny::observeEvent(input$remote_badge_status, status(input$remote_badge_status))
  shiny::observeEvent(input$finish_test, {
    shiny::stopApp(list(remote_badge_status = status()))
  })
}

test_remote_badge <- function() {
  probe <- run_shiny_probe(
    "Badge remoto",
    ui_builder = remote_badge_test_ui,
    server_builder = remote_badge_test_server
  )

  manual <- manual_result_block(
    "Se vio correctamente el badge remoto estilo Git?",
    "Describe si cargo, quedo roto o no se mostro"
  )

  automatic <- list(
    app_started = probe$app_started,
    remote_badge_status = probe$app_result$remote_badge_status %||% "",
    app_error = probe$error %||% ""
  )

  ok <- identical(manual$observed, "Si")
  list(
    automatic = automatic,
    manual = manual,
    conclusion = if (ok) "Las imagenes remotas estilo badge parecen visibles en este entorno." else "No hay confirmacion de carga visual de badges remotos.",
    action = if (ok) "El badge remoto podria mantenerse si la politica corporativa lo permite." else "Preparar README alternativo con badge de GitLab corporativo o fallback sin recursos externos."
  )
}

local_badge_test_ui <- function(asset_prefix) {
  shiny::fluidPage(
    shiny::tags$h2("Prueba de badge local"),
    shiny::tags$p("Este badge se sirve localmente desde Shiny."),
    shiny::tags$img(src = sprintf("%s/local-badge.svg", asset_prefix)),
    shiny::tags$hr(),
    shiny::actionButton("finish_test", "Finalizar prueba")
  )
}

local_badge_test_server <- function(input, output, session) {
  shiny::observeEvent(input$finish_test, {
    shiny::stopApp(list(finished = TRUE))
  })
}

test_local_badge <- function() {
  assets <- create_local_asset_files()
  prefix <- paste0("probe-badge-", as.integer(Sys.time()))
  shiny::addResourcePath(prefix, assets$dir)

  probe <- run_shiny_probe(
    "Badge local",
    ui_builder = function() local_badge_test_ui(prefix),
    server_builder = local_badge_test_server
  )

  manual <- manual_result_block(
    "Se vio correctamente el badge local servido por Shiny?",
    "Describe cualquier diferencia con el badge remoto"
  )

  automatic <- list(
    app_started = probe$app_started,
    local_badge_path = assets$svg,
    app_error = probe$error %||% ""
  )

  ok <- identical(manual$observed, "Si")
  list(
    automatic = automatic,
    manual = manual,
    conclusion = if (ok) "El badge local se ve correctamente y sirve como fallback viable." else "No hay confirmacion visual de badge local correcto.",
    action = if (ok) "Usar badge local o badge GitLab corporativo cuando la carga remota sea dudosa." else "Revisar carga local de imagenes en Shiny antes de definir el README corporativo."
  )
}

build_test_catalog <- function() {
  list(
    list(
      id = "T01",
      title = "Diagnostico base del entorno",
      objective = "Registrar contexto tecnico del host donde se ejecutan las pruebas.",
      method = "Inspeccion automatica de R, sistema, paquetes y directorio de trabajo.",
      runner = test_environment_diagnostics
    ),
    list(
      id = "T02",
      title = "Conectividad remota desde R",
      objective = "Determinar si el host de R puede alcanzar recursos remotos relevantes para la UI.",
      method = "Lectura parcial de recursos remotos via conexiones URL desde R.",
      runner = test_network_connectivity
    ),
    list(
      id = "T03",
      title = "Font Awesome desde CDN",
      objective = "Verificar si los iconos remotos usados por la app se renderizan correctamente.",
      method = "Mini app Shiny con la hoja de estilos remota y los iconos reales del proyecto.",
      runner = test_fontawesome_cdn
    ),
    list(
      id = "T04",
      title = "SortableJS desde CDN",
      objective = "Verificar si la libreria remota de reordenamiento se carga y funciona en el navegador.",
      method = "Mini app Shiny con una lista reordenable y reporte de orden final.",
      runner = test_sortable_cdn
    ),
    list(
      id = "T05",
      title = "JavaScript inline",
      objective = "Verificar ejecucion basica de JavaScript embebido en la app.",
      method = "Mini app Shiny con boton que modifica el DOM y reporta evento a Shiny.",
      runner = test_js_inline
    ),
    list(
      id = "T06",
      title = "localStorage",
      objective = "Verificar si el navegador permite persistencia simple en cliente.",
      method = "Mini app Shiny con guardado y lectura de una clave en localStorage.",
      runner = test_localstorage
    ),
    list(
      id = "T07",
      title = "navigator.clipboard",
      objective = "Verificar si el portapapeles programatico esta permitido.",
      method = "Mini app Shiny con boton de copia y reporte del estado hacia Shiny.",
      runner = test_clipboard
    ),
    list(
      id = "T08",
      title = "Drag and Drop HTML5 sin librerias",
      objective = "Distinguir soporte basico de drag and drop respecto de fallas especificas de librerias externas.",
      method = "Mini app Shiny con elemento draggable y zona de drop nativa.",
      runner = test_dragdrop_html5
    ),
    list(
      id = "T09",
      title = "Assets locales servidos por Shiny",
      objective = "Verificar que CSS, JS e imagenes locales puedan reemplazar dependencias remotas.",
      method = "Mini app Shiny con `addResourcePath` y assets creados temporalmente.",
      runner = test_local_assets
    ),
    list(
      id = "T10",
      title = "Descarga de archivo",
      objective = "Verificar exportacion desde el navegador mediante `downloadHandler`.",
      method = "Mini app Shiny con descarga de CSV de prueba y marcador de ejecucion.",
      runner = test_download_handler
    ),
    list(
      id = "T11",
      title = "Badge remoto estilo Git",
      objective = "Verificar carga visual de badges remotos desde internet.",
      method = "Mini app Shiny con una imagen SVG remota estilo badge.",
      runner = test_remote_badge
    ),
    list(
      id = "T12",
      title = "Fallback local para badge",
      objective = "Verificar que un badge local sirva como reemplazo del recurso remoto.",
      method = "Mini app Shiny con SVG local servido mediante Shiny.",
      runner = test_local_badge
    )
  )
}

run_single_test <- function(test, report_path) {
  cat("\n", strrep("=", 78), "\n", sep = "")
  cat(sprintf("[%s] %s\n", test$id, test$title))
  cat(test$objective, "\n")
  cat("Metodo:", test$method, "\n")
  cat(strrep("=", 78), "\n", sep = "")

  started <- Sys.time()
  outcome <- test$runner()
  ended <- Sys.time()

  automatic <- c(
    list(
      started_at = format(started, "%Y-%m-%d %H:%M:%S"),
      ended_at = format(ended, "%Y-%m-%d %H:%M:%S"),
      elapsed_seconds = round(as.numeric(difftime(ended, started, units = "secs")), 3)
    ),
    outcome$automatic %||% list()
  )

  write_test_section(
    path = report_path,
    test = test,
    automatic = automatic,
    manual = outcome$manual %||% list(),
    conclusion = outcome$conclusion %||% "",
    action = outcome$action %||% ""
  )

  invisible(outcome)
}

run_migration_checks <- function(selected_tests = NULL) {
  report_path <- report_file_path()
  init_report_if_needed(report_path)

  metadata <- list(
    run_started = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    working_directory = getwd(),
    host = tryCatch(Sys.info()[["nodename"]], error = function(e) ""),
    user = tryCatch(Sys.info()[["user"]], error = function(e) ""),
    r_version = R.version.string,
    platform = R.version$platform,
    sysname = tryCatch(paste(Sys.info()[c("sysname", "release", "version")], collapse = " | "), error = function(e) "")
  )

  write_run_header(report_path, metadata)
  tests <- build_test_catalog()

  if (!is.null(selected_tests)) {
    wanted <- toupper(as.character(selected_tests))
    tests <- Filter(function(x) toupper(x$id) %in% wanted, tests)
  }

  if (length(tests) == 0) {
    stop("No hay pruebas seleccionadas para ejecutar.")
  }

  cat("Reporte Markdown acumulativo:\n")
  cat(report_path, "\n\n")

  results <- lapply(tests, run_single_test, report_path = report_path)

  append_lines(report_path, c(
    "> Fin de corrida.",
    ""
  ))

  cat("\nCorrida finalizada. Reporte actualizado en:\n")
  cat(report_path, "\n")

  invisible(results)
}

list_migration_checks <- function() {
  tests <- build_test_catalog()
  data.frame(
    id = vapply(tests, `[[`, character(1), "id"),
    title = vapply(tests, `[[`, character(1), "title"),
    stringsAsFactors = FALSE
  )
}
