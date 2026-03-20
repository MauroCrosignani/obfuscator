build_default_ui_roles <- function(df) {
  roles <- detect_column_roles(df, obfuscator_config())
  assigned <- unique(unlist(roles, use.names = FALSE))
  roles$available <- setdiff(colnames(df), assigned)
  if (is.null(roles$preserve)) roles$preserve <- character(0)
  roles
}

detect_suspicious_date_character_columns <- function(df) {
  if (!is.data.frame(df) || ncol(df) == 0) {
    return(character(0))
  }

  is_date_like_name <- function(x) {
    normalized <- toupper(trimws(x))
    grepl("(^FECHA($|_))|(^FEC($|_))|(_FECHA($|_))|(^DATE($|_))|(_DATE($|_))", normalized)
  }

  is_date_prefix <- function(x) {
    grepl(
      "^(\\d{4}[-/.]\\d{2}[-/.]\\d{2}|\\d{2}[-/.]\\d{2}[-/.]\\d{4})$",
      x
    )
  }

  suspicious <- vapply(names(df), function(col_name) {
    column <- df[[col_name]]
    if (!is.character(column)) {
      return(FALSE)
    }

    name_looks_like_date <- is_date_like_name(col_name)
    non_na <- column[!is.na(column) & nzchar(trimws(column))]
    if (length(non_na) == 0) {
      return(name_looks_like_date)
    }

    sample_values <- head(trimws(non_na), 50)
    first_ten <- substr(sample_values, 1, 10)
    fully_date_like_text <- mean(is_date_prefix(first_ten), na.rm = TRUE) >= 0.6
    has_date_prefix_with_extra <- any(
      nchar(sample_values) > 10 & is_date_prefix(first_ten)
    )

    name_looks_like_date || has_date_prefix_with_extra || fully_date_like_text
  }, logical(1))

  names(df)[suspicious]
}

load_dataset_for_app <- function(source_mode, file_info = NULL, object_name = NULL) {
  if (identical(source_mode, "file")) {
    if (is.null(file_info)) {
      stop("Debes cargar un archivo para continuar.")
    }

    extension <- tolower(tools::file_ext(file_info$name %||% file_info$datapath))
    if (extension == "csv") {
      return(readr::read_csv(
        file_info$datapath,
        show_col_types = FALSE,
        guess_max = 100000
      ))
    }
    if (extension %in% c("xls", "xlsx")) {
      return(readxl::read_excel(file_info$datapath, guess_max = 100000))
    }
    if (extension == "rds") {
      obj <- readRDS(file_info$datapath)
      if (!is.data.frame(obj)) {
        stop("El archivo RDS no contiene un data.frame o tibble.")
      }
      return(obj)
    }

    stop("Formato no soportado. Usa CSV, XLS, XLSX o RDS.")
  }

  if (identical(source_mode, "environment")) {
    if (is.null(object_name) || !nzchar(object_name)) {
      stop("Debes seleccionar un objeto del entorno.")
    }
    if (!exists(object_name, envir = .GlobalEnv, inherits = FALSE)) {
      stop("El objeto seleccionado no existe en el entorno global.")
    }

    obj <- get(object_name, envir = .GlobalEnv, inherits = FALSE)
    if (!is.data.frame(obj)) {
      stop("El objeto seleccionado no es un data.frame o tibble.")
    }
    return(obj)
  }

  stop("Modo de carga no soportado.")
}

role_column_choices <- function(df, ui_roles) {
  list(
    id = intersect(ui_roles$id %||% character(0), colnames(df)),
    date = intersect(ui_roles$date %||% character(0), colnames(df)),
    categorical = intersect(ui_roles$categorical %||% character(0), colnames(df)),
    numeric = intersect(ui_roles$numeric %||% character(0), colnames(df)),
    preserve = intersect(ui_roles$preserve %||% character(0), colnames(df))
  )
}

render_role_zone_ui <- function(title, role_name, variables, warning_vars = character(0), suggested_vars = list(), active_hierarchies = character(0), active_offsets = character(0), numeric_cols = character(0), accent_class = "accent-slate") {
  index_width <- if (length(variables) > 99) 3 else 2

  shiny::tags$div(
    class = paste("role-zone", accent_class),
    `data-role` = role_name,
    shiny::tags$div(class = "role-zone-header", sprintf("%s (%s)", title, length(variables))),
    shiny::tags$div(
      class = "role-zone-body",
      lapply(seq_along(variables), function(idx) {
        var_name <- variables[[idx]]
        is_warning <- var_name %in% warning_vars
        # Sugerencia si esta en la lista y el rol coincide
        is_suggested <- !is.null(suggested_vars[[var_name]]) && suggested_vars[[var_name]]$role == role_name
        
        shiny::tags$div(
          class = paste("draggable-var", 
                        if (is_warning) "warning-var" else "",
                        if (is_suggested) "suggested-var" else ""),
          draggable = "true",
          `data-var-name` = var_name,
          `data-from-role` = role_name,
          title = if (is_suggested) sprintf("Sugerencia basada en '%s' (%.0f%% match)", 
                                           suggested_vars[[var_name]]$original, 
                                           suggested_vars[[var_name]]$score * 100) else NULL,
          shiny::tags$span(
            class = "var-index-badge",
            formatC(idx, width = index_width, flag = "0")
          ),
          if (is_warning) {
            shiny::tags$span(
              class = "var-warning-icon",
              title = "Posible fecha almacenada como texto",
              "!"
            )
          },
          # NUEVO: Badge de tipo
          shiny::tags$span(
            class = paste0("var-badge var-badge-", if(var_name %in% numeric_cols) "num" else "cat"),
            if(var_name %in% numeric_cols) "#" else "A"
          ),
          shiny::tags$span(
            class = "var-label",
            var_name
          ),
          # Nuevo: Boton para ver distribucion
          shiny::tags$button(
            class = "btn-dist-icon",
            onclick = sprintf("Shiny.setInputValue('view_distribution', '%s', {priority: 'event'})", var_name),
            title = "Ver Distribucion de Datos",
            shiny::tags$i(class = "fas fa-chart-simple")
          ),
          # Nuevo: Boton para configurar jerarquia (solo para Categoricas, Fechas e IDs)
          if (role_name %in% c("categorical", "date", "id")) {
            has_h <- var_name %in% active_hierarchies
            shiny::tags$button(
              class = paste("btn-hierarchy-icon", if (has_h) "has-hierarchy" else ""),
              onclick = sprintf("Shiny.setInputValue('open_hierarchy_editor', '%s', {priority: 'event'})", var_name),
              title = if (has_h) "Jerarquia configurada (Click para editar)" else "Configurar Jerarquia de Anonimizacion",
              shiny::tags$i(class = "fas fa-sitemap")
            )
          },
          # NUEVO: Boton para Cifrado/Offset (Solo para Identificadoras que sean Numericas)
          if (role_name == "id" && var_name %in% numeric_cols) {
            has_o <- var_name %in% active_offsets
            shiny::tags$button(
              class = paste("btn-offset-icon", if (has_o) "has-offset" else ""),
              onclick = sprintf("Shiny.setInputValue('open_offset_editor', '%s', {priority: 'event'})", var_name),
              title = if (has_o) "Cifrado Reversible activo (Click para editar)" else "Configurar Cifrado por Desfase (Reversible)",
              shiny::tags$i(class = "fas fa-key")
            )
          }
        )
      })
    )
  )
}

run_obfuscator_app <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("La app requiere el paquete `shiny` instalado.")
  }
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("La app requiere el paquete `ggplot2` instalado para las visualizaciones.")
  }

  options(shiny.maxRequestSize = 300 * 1024^2)

  frame_ofiles <- vapply(
    sys.frames(),
    function(frame) {
      if (is.null(frame$ofile)) "" else frame$ofile
    },
    character(1)
  )
  candidate_files <- frame_ofiles[grepl("(shiny_app|app)\\.R$", frame_ofiles)]
  base_dir <- if (length(candidate_files) > 0) {
    dirname(normalizePath(candidate_files[[length(candidate_files)]]))
  } else {
    getwd()
  }

  project_dir <- if (basename(base_dir) == "R") dirname(base_dir) else base_dir
  www_dir <- normalizePath(file.path(project_dir, "www"), winslash = "/", mustWork = FALSE)
  if (!dir.exists(www_dir)) {
    stop("No se encontro la carpeta `www` de la app Shiny.")
  }

  shiny::addResourcePath("obfuscator-www", www_dir)
  asset_version <- paste0(obfuscator_version(), "-", as.integer(Sys.time()))

  ui <- shiny::fluidPage(
    shiny::tags$head(
      shiny::tags$link(
        rel = "stylesheet",
        type = "text/css",
        href = sprintf("obfuscator-www/app.css?v=%s", asset_version)
      ),
      # FontAwesome y SortableJS
      shiny::tags$link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css"),
      shiny::tags$script(src = "https://cdn.jsdelivr.net/npm/sortablejs@1.15.0/Sortable.min.js"),
      shiny::tags$script(src = sprintf("obfuscator-www/app.js?v=%s", asset_version))
    ),
    shiny::tags$div(
      class = "app-shell",
      shiny::tags$div(
        class = "hero",
        shiny::tags$div(
          class = "hero-copy",
          shiny::tags$h1("ObfuscatoR Studio"),
          shiny::tags$p("Interfaz grafica para revisar, clasificar y ofuscar datos con apoyo visual y auditoria.")
        ),
        shiny::tags$div(
          class = "hero-meta",
          shiny::tags$button(
            id = "theme-toggle",
            class = "hero-chip theme-btn",
            onclick = "toggleTheme()",
            title = "Cambiar Tema (Claro/Oscuro)",
            shiny::tags$i(class = "fas fa-moon")
          ),
          # NUEVO: Boton de Ayuda
          shiny::tags$button(
            id = "open_help",
            class = "hero-chip help-btn",
            onclick = "Shiny.setInputValue('show_help', Math.random(), {priority: 'event'})",
            title = "Manual y Ayuda de Studio",
            shiny::tags$i(class = "fas fa-question-circle")
          ),
          shiny::uiOutput("hero_chips_ui", inline = TRUE)
        ),
      ),
      shiny::fluidRow(
        shiny::column(
          width = 4,
          shiny::tags$div(
            class = "panel-card",
            shiny::tags$h3("Fuente de datos"),
            shiny::radioButtons(
              "source_mode",
              NULL,
              choices = c("Archivo" = "file", "Entorno global" = "environment"),
              inline = TRUE
            ),
            shiny::conditionalPanel(
              "input.source_mode === 'file'",
              shiny::fileInput("input_file", "Cargar CSV, Excel o RDS", accept = c(".csv", ".xls", ".xlsx", ".rds"))
            ),
            shiny::tags$div(
              class = "help-text",
              "Tamano maximo de carga configurado en esta app: 300 MB. Para archivos aun mayores, conviene usar un objeto del entorno global."
            ),
            shiny::conditionalPanel(
              "input.source_mode === 'environment'",
              shiny::selectInput("env_object", "Objeto del entorno", choices = character(0))
            ),
            shiny::actionButton("load_data", "Cargar dataset", class = "primary-btn"),
            shiny::tags$div(class = "help-text", "Si eliges un objeto del entorno, debe ser un data.frame o tibble.")
          ),
          shiny::tags$aside(
            class = "sidebar",
            # NUEVO: Privacy Meter (Dinamico)
            shiny::tags$div(
              class = "panel-card privacy-meter-container",
              shiny::tags$h3(shiny::tags$i(class = "fas fa-gauge-high"), " Nivel de Privacidad"),
              shiny::uiOutput("privacy_meter_ui"),
              shiny::tags$p(class = "help-text", "Estimación basada en el k-anonymity y roles asignados.")
            ),
            shiny::tags$div(
              class = "panel-card",
              shiny::tags$h3(shiny::tags$i(class = "fas fa-sliders"), " Parametros"),
              shiny::numericInput("k_value", "k-anonymity (k)", value = 3, min = 2, max = 20),
              
              # NUEVO: Opciones Avanzadas (Progressive Disclosure)
              shiny::tags$details(
                class = "advanced-options",
                shiny::tags$summary("Opciones Avanzadas"),
                shiny::tags$br(),
                shiny::textInput("id_prefix", "Prefijo de IDs", value = "999"),
                shiny::textInput("project_key", "Llave de Proyecto (Sal)", value = "obfuscator_secret_v1"),
                shiny::selectInput("numeric_mode", "Modo Numérico", choices = c("Rango Aleatorio" = "range_random", "Permutación" = "permute"))
              )
            )
          ),
          shiny::tags$div(
            class = "panel-card",
            shiny::tags$h3("Parametros"),
            shiny::numericInput("seed", "Semilla", value = 123, min = 1),
            shiny::textInput("id_prefix", "Prefijo para IDs", value = "999"),
            shiny::passwordInput("project_key", "Llave del Proyecto (Opcional)", placeholder = "Sincroniza multiples archivos"),
            shiny::selectInput(
              "numeric_mode",
              "Modo numerico general",
              choices = c("range_random", "preserve_rank", "permute"),
              selected = "range_random"
            ),
            shiny::checkboxInput("enable_k", "Activar k-anonymity", value = FALSE),
            shiny::conditionalPanel(
              "input.enable_k === true",
              shiny::numericInput("k_value", "Valor de k", value = 5, min = 2, step = 1),
              shiny::radioButtons(
                "k_suppression",
                "Supresion residual",
                choices = c(
                  "Eliminar filas" = "rows", 
                  "Agrupar remanentes" = "group", 
                  "Conservar sin anonimizar" = "none"
                )
              ),
              shiny::checkboxInput("group_ids", "Agrupar IDs por k-clases", value = FALSE),
              shiny::tags$div(
                class = "help-text",
                style = "margin-top: -10px; margin-bottom: 10px;",
                shiny::tags$em("Tip: Si 'k' es alto y no ves datos, prueba 'Agrupar remanentes' o usa jerarquías para reducir la diversidad de los quasi-identificadores.")
              )
            ),
            shiny::actionButton("run_obfuscation", "Ofuscar dataset", class = "primary-btn")
          ),
          shiny::tags$div(
            class = "panel-card",
            shiny::tags$h3("Salida"),
            shiny::textInput("output_object_name", "Guardar objeto en entorno como", value = "dataset_ofuscado"),
            shiny::tags$div(
               class = "btn-group-custom",
               shiny::actionButton("save_to_env", "Guardar en entorno"),
               shiny::actionButton("revert_btn", "Revertir actual", class = "secondary-btn")
            ),
            shiny::tags$div(
              class = "btn-group-custom",
              style = "margin-top: 10px;",
              shiny::downloadButton("download_csv", "Descargar CSV"),
              shiny::actionButton("view_r_code", "Ver Código R", icon = shiny::icon("code"))
            )
          )
        ),
        shiny::column(
          width = 8,
          shiny::tags$div(
            class = "panel-card",
            shiny::tags$h3("Estado del dataset"),
            shiny::uiOutput("dataset_summary_ui")
          ),
          shiny::tags$div(
            class = "panel-card",
            shiny::tags$div(
              class = "section-header",
              shiny::tags$div(
                shiny::tags$h3("Clasificacion visual de variables"),
                shiny::tags$p("Arrastra variables entre zonas para corregir la deteccion automatica.")
              ),
              shiny::tags$div(
                class = "search-wrapper",
                shiny::tags$div(
                  class = "btn-group-custom",
                  shiny::actionButton("confirm_suggestions", "Confirmar Todo", icon = shiny::icon("check"), class = "btn-sm"),
                  shiny::actionButton("save_template", "Guardar Plantilla", icon = shiny::icon("save"), class = "btn-sm"),
                  shiny::actionButton("load_template", "Cargar Plantilla", icon = shiny::icon("folder-open"), class = "btn-sm")
                ),
                shiny::textInput("var_search", NULL, placeholder = "Filtrar por nombre...", width = "200px")
              )
            ),
            shiny::uiOutput("role_board_ui")
          ),
          shiny::tags$div(
            class = "panel-card",
            shiny::tags$div(
              class = "section-header",
              shiny::tags$h3("Vista previa"),
              shiny::checkboxInput("live_preview", "Vista previa de ofuscacion (solo 10 filas)", value = FALSE)
            ),
            shiny::tags$div(
              class = "preview-table-wrapper",
              shiny::tableOutput("preview_table")
            )
          ),
          shiny::tags$div(
            class = "panel-card",
            shiny::tags$h3("Resumen de auditoria"),
            shiny::verbatimTextOutput("audit_log_text")
          )
        )
      )
    )
  )

  server <- function(input, output, session) {
    # Reactivos para el estado de la app
    source_data <- shiny::reactiveVal(NULL)
    role_state <- shiny::reactiveVal(list(
      available = character(0),
      id = character(0), 
      date = character(0), 
      categorical = character(0), 
      numeric = character(0), 
      preserve = character(0),
      exclude = character(0) # NUEVO: Zona de exclusion
    ))
    suggested_roles <- shiny::reactiveVal(list()) # Para fuzzy matching
    # Jerarquias (listas de listas: mapping, name)
    hierarchies <- shiny::reactiveVal(list())
    
    # NUEVO: Offsets numericos
    numeric_offsets <- shiny::reactiveVal(list())
    
    dist_var <- shiny::reactiveVal(NULL) # Para el modal de distribucion
    obfuscated_data <- shiny::reactiveVal(NULL)
    audit_log <- shiny::reactiveVal(NULL)
    progress_status <- shiny::reactiveVal("Todavia no se ejecuto ninguna ofuscacion.")

    shiny::observe({
      objects <- ls(envir = .GlobalEnv)
      object_choices <- objects[vapply(objects, function(obj_name) {
        inherits(get(obj_name, envir = .GlobalEnv), "data.frame")
      }, logical(1))]
      shiny::updateSelectInput(
        session,
        "env_object",
        choices = object_choices,
        selected = if (length(object_choices) > 0) object_choices[[1]] else ""
      )
    })

    shiny::observeEvent(input$load_data, {
      dataset <- load_dataset_for_app(
        source_mode = input$source_mode,
        file_info = input$input_file,
        object_name = input$env_object
      )
      source_data(dataset)
      
      # Persistence: Intentar carga automatica basada en hash
      hash_id <- generate_schema_hash(dataset)
      config_path <- file.path("config", paste0(hash_id, ".json"))
      
      suggested_roles(list())
      if (file.exists(config_path)) {
        persisted <- load_roles_from_json(dataset, config_path)
        if (!is.null(persisted)) {
          # Mezclamos matches exactos con los demas detectados
          roles <- build_default_ui_roles(dataset)
          # Sobrescribir con los exactos
          for (r in names(persisted$exact)) {
             cols_to_move <- persisted$exact[[r]]
             if (length(cols_to_move) > 0) {
               # Limpiar de cualquier zona previa
               for (orig_r in names(roles)) {
                 roles[[orig_r]] <- setdiff(roles[[orig_r]], cols_to_move)
               }
               # Asignar a la zona persistida
               roles[[r]] <- unique(c(roles[[r]], cols_to_move))
             }
          }
          role_state(roles)
          suggested_roles(persisted$suggested %||% list())
          hierarchies(persisted$hierarchies %||% list())
          numeric_offsets(persisted$numeric_offsets %||% list())
          
          msg <- sprintf("Hash %s detectado. Se cargo configuracion previa.", hash_id)
          if (length(persisted$suggested) > 0) {
            msg <- paste(msg, sprintf("(%d sugerencias fuzzy)", length(persisted$suggested)))
          }
          shiny::showNotification(msg, type = "message")
        } else {
          role_state(build_default_ui_roles(dataset))
        }
      } else {
        role_state(build_default_ui_roles(dataset))
      }
      
      obfuscated_data(NULL)
      audit_log(NULL)
      progress_status("Dataset cargado. Se busco persistencia por esquema.")
    }, ignoreNULL = TRUE)

    shiny::observeEvent(input$open_hierarchy_editor, {
      var_name <- input$open_hierarchy_editor
      df <- source_data()
      shiny::req(df, var_name)
      
      unique_vals <- unique(as.character(df[[var_name]]))
      current_h <- hierarchies()[[var_name]] %||% list()
      
      shiny::showModal(shiny::modalDialog(
        title = sprintf("Configurar Jerarquia: %s", var_name),
        size = "l",
        footer = shiny::tagList(
          shiny::modalButton("Cancelar"),
          shiny::actionButton("save_hierarchy", "Guardar Jerarquia", class = "btn-primary")
        ),
        shiny::tags$div(
          class = "hierarchy-editor-container",
          `data-var` = var_name,
          # Panel Izquierdo: Valores Disponibles
          shiny::tags$div(
            class = "hierarchy-source-panel",
            shiny::tags$div(class = "hierarchy-header", "Valores Unicos"),
            shiny::tags$div(
              id = "hierarchy-source-list",
              class = "hierarchy-body",
              lapply(unique_vals, function(v) {
                shiny::tags$div(class = "hierarchy-item", `data-value` = v, v)
              })
            )
          ),
          # Panel Derecho: Estructura de Niveles
          shiny::tags$div(
            class = "hierarchy-dest-panel",
            shiny::tags$div(
              class = "hierarchy-header", 
              "Grupos (Nivel 1)",
              shiny::actionButton("add_hierarchy_group", "Nuevo Grupo", icon = shiny::icon("plus"), class = "btn-xs")
            ),
            shiny::tags$div(
              id = "hierarchy-dest-list",
              class = "hierarchy-body",
              # Se llenará via JS o renderizado inicial con current_h
              if (length(current_h) > 0) {
                 lapply(names(current_h$mapping), function(grp) {
                    shiny::tags$div(
                      class = "hierarchy-folder",
                      `data-group` = grp,
                      shiny::tags$div(class = "folder-header", shiny::tags$i(class = "fas fa-folder-open"), grp),
                      shiny::tags$div(
                        class = "folder-content",
                        lapply(current_h$mapping[[grp]], function(v) {
                          shiny::tags$div(class = "hierarchy-item", `data-value` = v, v)
                        })
                      )
                    )
                 })
              }
            )
          ),
          # Barra flotante de seleccion
          shiny::tags$div(
             class = "hierarchy-floating-bar",
             id = "hierarchy-selection-bar",
             style = "display: none;",
             shiny::tags$span(id = "hierarchy-selection-count", "0 seleccionado(s)"),
             shiny::actionButton("group_selected", "Agrupar", class = "btn-primary btn-sm")
          )
        )
      ))
      
      # Inicializar SortableJS en el modal
      shiny::insertUI(
        selector = "body",
        where = "beforeEnd",
        ui = shiny::tags$script("initHierarchySortable();"),
        immediate = TRUE
      )
    })

    shiny::observeEvent(input$save_hierarchy, {
      # Recibir el arbol estructurado desde JS
      tree_data <- input$hierarchy_tree_state
      var_name <- input$open_hierarchy_editor
      
      if (!is.null(tree_data) && !is.null(var_name)) {
        h <- hierarchies()
        h[[var_name]] <- list(
          mapping = tree_data,
          name = sprintf("Jerarquia %s", var_name)
        )
        hierarchies(h)
        shiny::showNotification("Jerarquia guardada temporalmente.", type = "message")
      }
      shiny::removeModal()
    })

    shiny::observeEvent(input$view_distribution, {
      var_name <- input$view_distribution
      shiny::req(source_data(), var_name)
      dist_var(var_name)
      
      shiny::showModal(shiny::modalDialog(
        title = sprintf("Distribucion: %s", var_name),
        size = "l",
        easyClose = TRUE,
        footer = shiny::modalButton("Cerrar"),
        shiny::tags$div(
          class = "distribution-container",
          shiny::plotOutput("dist_plot", height = "400px")
        )
      ))
    })

    output$dist_plot <- shiny::renderPlot({
      var_name <- dist_var()
      df <- source_data()
      roles <- role_state()
      shiny::req(df, var_name)
      
      column_data <- df[[var_name]]
      is_quasi <- var_name %in% c(roles$id, roles$categorical)
      
      p <- ggplot2::ggplot(df, ggplot2::aes(x = .data[[var_name]]))
      
      if (is_quasi) {
        # Si el usuario lo marco como categorico o ID, priorizamos gráfico de barras
        # incluso si el dato subyacente es numerico (se trata como discreto)
        counts <- as.data.frame(table(column_data))
        counts <- counts[order(-counts$Freq), ]
        top_counts <- utils::head(counts, 15)
        
        p <- ggplot2::ggplot(top_counts, ggplot2::aes(x = reorder(column_data, -Freq), y = Freq)) +
          ggplot2::geom_bar(stat = "identity", fill = "#10b981") +
          ggplot2::theme_minimal() +
          ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +
          ggplot2::labs(title = paste("Top 15 valores de", var_name), 
                        subtitle = "Visualización como variable categórica",
                        y = "Frecuencia", x = var_name)
      } else if (is.numeric(column_data)) {
        p <- p + 
          ggplot2::geom_histogram(fill = "#eab308", color = "white", bins = 30) +
          ggplot2::theme_minimal() +
          ggplot2::labs(title = paste("Histograma de", var_name), y = "Frecuencia", x = var_name)
      } else if (inherits(column_data, "Date") || inherits(column_data, "POSIXt")) {
        p <- p + 
          ggplot2::geom_histogram(fill = "#3b82f6", color = "white", bins = 30) +
          ggplot2::theme_minimal() +
          ggplot2::labs(title = paste("Distribucion Temporal de", var_name), y = "Frecuencia", x = var_name)
      } else {
        # Categorical / ID: Top 15 categories
        counts <- as.data.frame(table(column_data))
        counts <- counts[order(-counts$Freq), ]
        top_counts <- utils::head(counts, 15)
        
        p <- ggplot2::ggplot(top_counts, ggplot2::aes(x = reorder(column_data, -Freq), y = Freq)) +
          ggplot2::geom_bar(stat = "identity", fill = "#10b981") +
          ggplot2::theme_minimal() +
          ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +
          ggplot2::labs(title = paste("Top 15 categorias de", var_name), y = "Frecuencia", x = var_name)
      }
      
      p + ggplot2::theme(
        plot.title = ggplot2::element_text(face = "bold", size = 16),
        panel.grid.minor = ggplot2::element_blank()
      )
    })

    # --- Lógica de Hero Chips Meta ---
    output$hero_chips_ui <- shiny::renderUI({
      df <- source_data()
      k <- input$k_value %||% 3
      name <- input$dataset_name %||% "Ninguno"
      rows <- nrow(df %||% data.frame())
      
      shiny::tagList(
        shiny::tags$div(class = "hero-chip", shiny::tags$i(class = "fas fa-database"), " Dataset: ", shiny::tags$strong(name)),
        shiny::tags$div(class = "hero-chip", shiny::tags$i(class = "fas fa-table-columns"), " Filas: ", shiny::tags$strong(rows)),
        shiny::tags$div(class = "hero-chip", shiny::tags$i(class = "fas fa-shield-halved"), " k: ", shiny::tags$strong(k)),
        shiny::tags$div(class = "hero-chip", sprintf("v%s", obfuscator_version()))
      )
    })

    # --- Lógica de Privacy Meter ---
    output$privacy_meter_ui <- shiny::renderUI({
      roles <- role_state()
      k <- input$k_value %||% 3
      
      # Calculo heuristico del score (0 a 100)
      # k=2 es base, cada punto de k suma. Roles de ID y Categorical con jerarquia suman mas.
      score <- 10 + (k * 4)
      n_ids <- length(roles$id)
      n_cat <- length(roles$categorical)
      n_hierarchies <- length(hierarchies())
      
      score <- score + (n_ids * 5) + (n_cat * 2) + (n_hierarchies * 8)
      score <- min(100, score)
      
      color_class <- if(score < 40) "meter-low" else if(score < 75) "meter-med" else "meter-high"
      label <- if(score < 40) "Bajo" else if(score < 75) "Medio" else "Excelente"
      
      shiny::tags$div(
        class = paste("privacy-meter", color_class),
        shiny::tags$div(class = "meter-track", 
          shiny::tags$div(class = "meter-fill", style = sprintf("width: %d%%", score))
        ),
        shiny::tags$div(class = "meter-label", 
          shiny::tags$span(class = "score-val", sprintf("%d%%", score)),
          shiny::tags$span(class = "score-text", label)
        )
      )
    })
    
    # NUEVO: Generador de Codigo R
    get_obfuscation_code <- function() {
       df <- source_data()
       roles <- role_state()
       h <- hierarchies()
       o <- numeric_offsets()
       
       # Formatear col_roles
       col_roles_str <- if (length(role_column_choices(df, roles)) > 0) {
         roles_list <- role_column_choices(df, roles)
         lines <- vapply(names(roles_list), function(r) {
            sprintf("    %s = %s", r, paste0("c(", paste0("'", roles_list[[r]], "'", collapse = ", "), ")"))
         }, character(1))
         sprintf("list(\n%s\n  )", paste(lines, collapse = ",\n"))
       } else "list()"
        # Formatear Offsets (Modo Reversible con Placeholders)
        offsets_str <- if (length(o) > 0) {
          lines <- vapply(names(o), function(v) {
             # CAMBIO: Usar placeholders para NO exportar claves reales en el codigo R
             sprintf("    '%s' = 0, # [INGRESE_CLAVE_PARA_%s]", v, toupper(v))
          }, character(1))
          sprintf("list(\n%s\n  )", paste(lines, collapse = ",\n"))
        } else "list()"
       
       # Note: Hierarchies are complex to serialize in text, we provide a placeholder
       h_str <- if (length(h) > 0) "hierarchies_obj" else "NULL"
       
       code <- sprintf(
"library(obfuscator)

# 1. Cargar datos
df <- %s # REEMPLAZAR con el comando de carga (p. ej. read.csv('archivo.csv'))

# 2. Configurar Ofuscacion
config <- obfuscator_config(
  seed = %s,
  id_prefix = '%s',
  numeric_mode = '%s',
  project_key = %s,
  col_roles = %s,
  numeric_offsets = %s,
  exclude_cols = %s,
  privacy_model = %s
)

# 3. Ejecutar
resultado <- obfuscate_dataset(df, config = config)

# Ver resultado
head(resultado)",
         if (input$source_mode == "environment") input$env_object else "data",
         input$seed,
         input$id_prefix,
         input$numeric_mode,
         if (nchar(input$project_key) > 0) sprintf("'%s'", input$project_key) else "NULL",
         col_roles_str,
         offsets_str,
         if (length(roles$exclude) > 0) paste0("c(", paste0("'", roles$exclude, "'", collapse = ", "), ")") else "character(0)",
         if (isTRUE(input$enable_k)) sprintf("list(type = 'k_anonymity', k = %s, suppression = '%s')", input$k_value, input$k_suppression) else "NULL"
       )
       
       code
    }

    shiny::observeEvent(input$view_r_code, {
       code <- get_obfuscation_code()
       shiny::showModal(shiny::modalDialog(
         title = "Código R para Reproducción",
         size = "l",
         easyClose = TRUE,
         footer = shiny::modalButton("Cerrar"),
         shiny::tags$div(
           class = "code-container",
           shiny::tags$button(
             id = "copy-code-btn",
             class = "copy-code-btn",
             onclick = "copyRCodeToClipboard()",
             shiny::tags$i(class = "fas fa-clipboard"),
             " Copiar Código"
           ),
           shiny::tags$pre(
             style = "background: #f8fafc; padding: 25px 15px 15px; border-radius: 12px; border: 1px solid #e2e8f0; white-space: pre-wrap; font-family: monospace; font-size: 13px;",
             code
           )
         ),
         shiny::tags$p(class = "help-text", "Copia este código en un script de R para automatizar el proceso sin usar la interfaz.")
       ))
    })

    shiny::observeEvent(input$role_drop, {
      shiny::req(source_data())
      payload <- input$role_drop
      roles <- role_state()
      from_role <- payload$from_role
      to_role <- payload$to_role
      var_name <- payload$var_name

      if (!(from_role %in% names(roles)) || !(to_role %in% names(roles))) {
        return()
      }

      roles[[from_role]] <- setdiff(roles[[from_role]], var_name)
      roles[[to_role]] <- unique(c(roles[[to_role]], var_name))
      for (role_name in names(roles)) {
        roles[[role_name]] <- unique(roles[[role_name]])
      }
      role_state(roles)
    })

    output$dataset_summary_ui <- shiny::renderUI({
      df <- source_data()
      if (is.null(df)) {
        return(shiny::tags$p("Todavia no hay un dataset cargado."))
      }

      roles <- role_state()
      shiny::tags$div(
        class = "summary-grid",
        shiny::tags$div(class = "summary-card", shiny::tags$strong("Filas"), nrow(df)),
        shiny::tags$div(class = "summary-card", shiny::tags$strong("Columnas"), ncol(df)),
        shiny::tags$div(class = "summary-card", shiny::tags$strong("IDs"), length(roles$id)),
        shiny::tags$div(class = "summary-card", shiny::tags$strong("Fechas"), length(roles$date)),
        shiny::tags$div(class = "summary-card", shiny::tags$strong("Categoricas"), length(roles$categorical)),
        shiny::tags$div(class = "summary-card", shiny::tags$strong("Numericas"), length(roles$numeric)),
        shiny::tags$div(class = "summary-card", shiny::tags$strong("Para conservar"), length(roles$preserve))
      )
    })

    output$role_board_ui <- shiny::renderUI({
      df <- source_data()
      if (is.null(df)) {
        return(shiny::tags$p("Carga un dataset para revisar las variables detectadas."))
      }

      roles <- role_state()
      sug_roles <- suggested_roles()
      active_h <- names(hierarchies())
      active_o <- names(numeric_offsets())
      numeric_cols <- colnames(df)[vapply(df, is.numeric, logical(1))]
      warning_vars <- detect_suspicious_date_character_columns(df)
      
      # Filter available variables based on search input
      all_vars <- colnames(df)
      available_vars <- setdiff(all_vars, unlist(roles[names(roles) != "available"]))
      
      search_term <- tolower(input$var_search)
      if (nzchar(search_term)) {
        available_vars <- available_vars[grepl(search_term, tolower(available_vars))]
        roles$id <- roles$id[grepl(search_term, tolower(roles$id))]
        roles$date <- roles$date[grepl(search_term, tolower(roles$date))]
        roles$categorical <- roles$categorical[grepl(search_term, tolower(roles$categorical))]
        roles$numeric <- roles$numeric[grepl(search_term, tolower(roles$numeric))]
        roles$preserve <- roles$preserve[grepl(search_term, tolower(roles$preserve))]
        roles$exclude <- roles$exclude[grepl(search_term, tolower(roles$exclude))] # Filter exclude zone
      }

      shiny::tags$div(
        class = "role-board",
        render_role_zone_ui("Disponibles", "available", available_vars, warning_vars = warning_vars, suggested_vars = sug_roles, active_hierarchies = active_h, active_offsets = active_o, numeric_cols = numeric_cols, accent_class = "accent-slate"),
        render_role_zone_ui("Identificadoras", "id", roles$id, warning_vars = warning_vars, suggested_vars = sug_roles, active_hierarchies = active_h, active_offsets = active_o, numeric_cols = numeric_cols, accent_class = "accent-red"),
        render_role_zone_ui("Fechas", "date", roles$date, warning_vars = warning_vars, suggested_vars = sug_roles, active_hierarchies = active_h, active_offsets = active_o, numeric_cols = numeric_cols, accent_class = "accent-blue text-sm"),
        render_role_zone_ui("Categoricas", "categorical", roles$categorical, warning_vars = warning_vars, suggested_vars = sug_roles, active_hierarchies = active_h, active_offsets = active_o, numeric_cols = numeric_cols, accent_class = "accent-green text-sm"),
        render_role_zone_ui("Numericas", "numeric", roles$numeric, warning_vars = warning_vars, suggested_vars = sug_roles, active_hierarchies = active_h, active_offsets = active_o, numeric_cols = numeric_cols, accent_class = "accent-gold text-sm"),
        render_role_zone_ui("Excluir", "exclude", roles$exclude, warning_vars = warning_vars, suggested_vars = sug_roles, active_hierarchies = active_h, active_offsets = active_o, numeric_cols = numeric_cols, accent_class = "accent-gray text-sm"), # NUEVA ZONA
        render_role_zone_ui("Conservar", "preserve", roles$preserve, warning_vars = warning_vars, suggested_vars = sug_roles, active_hierarchies = active_h, active_offsets = active_o, numeric_cols = numeric_cols, accent_class = "accent-gray text-sm")
      )
    })

    output$preview_table <- shiny::renderTable({
      df <- source_data()
      shiny::req(df)

      if (isTRUE(input$live_preview)) {
        roles <- role_state()
        config <- obfuscator_config(
          seed = input$seed,
          id_prefix = input$id_prefix,
          numeric_mode = input$numeric_mode,
          col_roles = role_column_choices(df, roles),
          project_key = if (nchar(input$project_key) > 0) input$project_key else NULL,
          numeric_offsets = numeric_offsets(),
          exclude_cols = roles$exclude,
          privacy_model = if (isTRUE(input$enable_k)) {
            list(
              type = "k_anonymity", 
              k = input$k_value,
              quasi_identifiers = intersect(unique(c(roles$id, roles$date, roles$categorical)), names(df)),
              suppression = input$k_suppression,
              group_ids = input$group_ids,
              hierarchies = hierarchies()
            )
          } else NULL
        )
        df <- obfuscate_dataset(utils::head(df, 10), config = config)
      } else {
        df <- obfuscated_data() %||% df
      }

      utils::head(df, 10)
    }, rownames = TRUE)

    shiny::observeEvent(input$run_obfuscation, {
      df <- source_data()
      shiny::req(df)

      roles <- role_state()
      privacy_model <- if (isTRUE(input$enable_k)) {
        qis <- unique(c(roles$id, roles$date, roles$categorical))
        if (length(qis) == 0) {
          shiny::showNotification("k-anonymity necesita al menos un quasi-identificador seleccionado.", type = "error")
          return()
        }

        list(
          type = "k_anonymity",
          k = input$k_value,
          quasi_identifiers = qis,
          suppression = input$k_suppression,
          group_ids = input$group_ids,
          hierarchies = hierarchies()
        )
      } else {
        NULL
      }

      config <- obfuscator_config(
        seed = input$seed,
        id_prefix = input$id_prefix,
        numeric_mode = input$numeric_mode,
        col_roles = role_column_choices(df, roles),
        privacy_model = privacy_model,
        project_key = if (nchar(input$project_key) > 0) input$project_key else NULL,
        numeric_offsets = numeric_offsets(),
        exclude_cols = roles$exclude
      )
      last_percent <- 0
      last_bucket <- -1

      shiny::withProgress(message = "Procesando dataset", value = 0, {
        config$progress_callback <- function(event) {
          target_percent <- max(0, min(100, event$percent %||% 0))
          increment <- max(0, (target_percent - last_percent) / 100)
          if (increment > 0) {
            shiny::incProgress(
              increment,
              detail = paste(
                sprintf("%d%%", round(target_percent)),
                "-",
                event$stage %||% "Procesando",
                if (!is.null(event$detail) && nzchar(event$detail)) paste0(" (", event$detail, ")") else ""
              )
            )
            last_percent <<- target_percent
          }

          current_bucket <- floor(target_percent / 10)
          if (current_bucket > last_bucket) {
            progress_status(sprintf(
              "Avance %d%%: %s%s",
              current_bucket * 10,
              event$stage %||% "Procesando",
              if (!is.null(event$detail) && nzchar(event$detail)) paste0(" (", event$detail, ")") else ""
            ))
            last_bucket <<- current_bucket
          }
        }

        result <- obfuscate_dataset(df, config = config)
        obfuscated_data(result)
        audit_log(attr(result, "obfuscator_log"))
      })

      progress_status("Ofuscacion completada al 100%.")
      shiny::showNotification("Ofuscacion completada.", type = "message")
    })

    shiny::observeEvent(input$save_template, {
      df <- source_data()
      shiny::req(df)
      hash_id <- generate_schema_hash(df)
      config_path <- file.path("config", paste0(hash_id, ".json"))
      
      roles <- role_state()
      # No guardamos 'available' para no ensuciar, solo asignaciones explicitas
      config_to_save <- roles[names(roles) != "available"]
      config_to_save$hierarchies <- hierarchies()
      config_to_save$numeric_offsets <- numeric_offsets() # NUEVO
      
      save_roles_to_json(config_to_save, config_path)
      shiny::showNotification(sprintf("Plantilla guardada para hash %s.", hash_id), type = "message")
    })

    shiny::observeEvent(input$confirm_suggestions, {
      sug <- suggested_roles()
      if (length(sug) == 0) {
        shiny::showNotification("No hay sugerencias que confirmar.", type = "warning")
        return()
      }
      
      roles <- role_state()
      for (col in names(sug)) {
        role_name <- sug[[col]]$role
        # Quitar de donde este ahora (available usualmente)
        for (r in names(roles)) roles[[r]] <- setdiff(roles[[r]], col)
        # Poner en el nuevo rol
        roles[[role_name]] <- unique(c(roles[[role_name]], col))
      }
      
      role_state(roles)
      suggested_roles(list())
      shiny::showNotification("Sugerencias confirmadas.", type = "message")
    })

    output$audit_log_text <- shiny::renderPrint({
      log_info <- audit_log()
      if (is.null(log_info)) {
        cat(progress_status(), "\n")
      } else {
        print(log_info)
      }
    })

    shiny::observeEvent(input$save_to_env, {
      shiny::req(obfuscated_data())
      object_name <- input$output_object_name
      shiny::validate(shiny::need(nzchar(object_name), "Debes indicar un nombre de objeto valido."))
      assign(object_name, obfuscated_data(), envir = .GlobalEnv)
      shiny::showNotification(sprintf("Objeto `%s` guardado en el entorno global.", object_name), type = "message")
    })

    shiny::observeEvent(input$revert_btn, {
      res <- obfuscated_data()
      shiny::req(res)
      log <- attr(res, "obfuscator_log")
      if (is.null(log)) {
        shiny::showNotification("No hay informacion de auditoria para revertir este dataset.", type = "error")
        return()
      }
      
      tryCatch({
        reverted <- revert_obfuscation(res, log)
        obfuscated_data(reverted)
        shiny::showNotification("Dataset revertido correctamente.", type = "message")
      }, error = function(e) {
        shiny::showNotification(paste("Error al revertir:", e$message), type = "error")
      })
    })

    # --- Lógica de Cifrado Reversible (Manual) ---
    shiny::observeEvent(input$open_offset_editor, {
      var_name <- input$open_offset_editor
      current_val <- numeric_offsets()[[var_name]] %||% 0
      
      shiny::showModal(shiny::modalDialog(
        title = paste("Configurar Cifrado Reversible:", var_name),
        size = "s",
        # Usamos passwordInput para que la clave sea secreta al ingresarla
        shiny::passwordInput("offset_value", "Ingrese Clave Numérica de Desfase:", value = as.character(current_val)),
        shiny::tags$p(class = "help-text", "Esta clave se sumará al ID original. Es necesaria para el proceso inverso y NO se exporta en el código R."),
        footer = shiny::tagList(
          shiny::modalButton("Cancelar"),
          shiny::actionButton("save_offset_v2", "Guardar Clave", class = "primary-btn")
        )
      ))
    })
    
    shiny::observeEvent(input$save_offset_v2, {
      var_name <- input$open_offset_editor
      val <- as.numeric(input$offset_value)
      
      if (is.na(val)) {
        shiny::showNotification("Error: Por favor ingrese un número válido.", type = "error")
        return()
      }
      
      o <- numeric_offsets()
      o[[var_name]] <- val
      numeric_offsets(o)
      shiny::removeModal()
      shiny::showNotification(sprintf("Cifrado reversible guardado para %s", var_name))
    })

    # --- Sistema de Ayuda Integrado ---
    shiny::observeEvent(input$show_help, {
      shiny::showModal(shiny::modalDialog(
        title = "Manual de ObfuscatoR Studio 2.0",
        size = "l",
        easyClose = TRUE,
        shiny::tabsetPanel(
          shiny::tabPanel("Guía Rápida", 
            shiny::tags$div(style = "padding: 15px;",
              shiny::tags$h4("Configuración de Roles"),
              shiny::tags$p("Arrastra las variables de la zona 'Disponibles' a las zonas activas:"),
              shiny::tags$ul(
                shiny::tags$li(shiny::tags$strong("Identificadoras:"), " Para IDs, nombres o claves únicas."),
                shiny::tags$li(shiny::tags$strong("Categorización:"), " Para variables tipo texto que quieras agrupar."),
                shiny::tags$li(shiny::tags$strong("Fechas:"), " Serán permutadas para mantener el orden pero ocultar el día exacto."),
                shiny::tags$li(shiny::tags$strong("Conservar:"), " Estas variables no se tocan.")
              ),
              shiny::tags$p("Usa el icono de ", shiny::tags$i(class = "fas fa-chart-simple"), " para ver la distribución de los datos.")
            )
          ),
          shiny::tabPanel("Cifrado Reversible", 
            shiny::tags$div(style = "padding: 15px;",
              shiny::tags$h4("Cifrado por Desfase (Identificadoras Numéricas)"),
              shiny::tags$p("Si una variable ID es numérica, verás un icono de llave ", shiny::tags$i(class = "fas fa-key"), "."),
              shiny::tags$ol(
                shiny::tags$li("Haz clic en la llave e ingresa un número secreto."),
                shiny::tags$li("El sistema sumará ese número a todos los registros."),
                shiny::tags$li("Este proceso es reversible restando la misma clave."),
                shiny::tags$li(shiny::tags$strong("Seguridad:"), " Las claves NO se exportan en el código R ni se guardan en el servidor.")
              ),
              shiny::tags$p("Para revertir programáticamente usa: ", shiny::tags$code("revert_reversible_ids(data, list(Col = CLAVE))"))
            )
          ),
          shiny::tabPanel("Jerarquías", 
            shiny::tags$div(style = "padding: 15px;",
              shiny::tags$h4("Jerarquías de Anonimización"),
              shiny::tags$p("Usa el icono ", shiny::tags$i(class = "fas fa-sitemap"), " para agrupar valores sensibles en categorías más generales (ej: Ciudad -> Provincia)."),
              shiny::tags$p("Esto es fundamental para el ", shiny::tags$strong("k-anonimato"), ", ya que permite que varios individuos compartan las mismas características.")
            )
          ),
          shiny::tabPanel("Privacidad (k)", 
            shiny::tags$div(style = "padding: 15px;",
              shiny::tags$h4("Modelo k-anonymity"),
              shiny::tags$p("El ", shiny::tags$strong("Privacy Meter"), " estima la seguridad de tu dataset."),
              shiny::tags$ul(
                shiny::tags$li(shiny::tags$strong("Score Bajo:"), " Los datos son fáciles de re-identificar."),
                shiny::tags$li(shiny::tags$strong("Score Alto:"), " Has logrado agrupar a los individuos de forma que es difícil distinguirlos.")
              ),
              shiny::tags$p("Aumenta el valor de 'k' o usa más jerarquías para mejorar el puntaje.")
            )
          )
        ),
        footer = shiny::modalButton("Cerrar")
      ))
    })

    output$download_csv <- shiny::downloadHandler(
      filename = function() {
        paste0("dataset_ofuscado_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        shiny::req(obfuscated_data())
        readr::write_csv(obfuscated_data(), file)
      }
    )
  }

  shiny::shinyApp(ui = ui, server = server, options = list(launch.browser = TRUE))
}
