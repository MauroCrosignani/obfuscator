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

render_role_zone_ui <- function(title, role_name, variables, warning_vars = character(0), accent_class = "accent-slate") {
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
        shiny::tags$div(
          class = paste("draggable-var", if (is_warning) "warning-var" else ""),
          draggable = "true",
          `data-var-name` = var_name,
          `data-from-role` = role_name,
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
          shiny::tags$span(
            class = "var-label",
            var_name
          )
        )
      })
    )
  )
}

run_obfuscator_app <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("La app requiere el paquete `shiny` instalado.")
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
          shiny::tags$div(class = "hero-chip", sprintf("Version %s", obfuscator_version())),
          shiny::tags$div(class = "hero-chip", "UX en espanol"),
          shiny::tags$div(class = "hero-chip", "Drag & drop")
        )
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
              shiny::checkboxInput("group_ids", "Agrupar IDs por k-clases", value = FALSE)
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
            shiny::downloadButton("download_csv", "Descargar CSV")
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
    source_data <- shiny::reactiveVal(NULL)
    role_state <- shiny::reactiveVal(list(
      available = character(0),
      id = character(0),
      date = character(0),
      categorical = character(0),
      numeric = character(0),
      preserve = character(0)
    ))
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
      role_state(build_default_ui_roles(dataset))
      obfuscated_data(NULL)
      audit_log(NULL)
      progress_status("Dataset cargado. Puedes revisar la clasificacion y ejecutar la ofuscacion.")
    }, ignoreNULL = TRUE)

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
      warning_vars <- detect_suspicious_date_character_columns(df)
      shiny::tags$div(
        class = "role-board",
        render_role_zone_ui("Disponibles", "available", roles$available, warning_vars = warning_vars, accent_class = "accent-slate"),
        render_role_zone_ui("Identificadoras", "id", roles$id, warning_vars = warning_vars, accent_class = "accent-red"),
        render_role_zone_ui("Fechas", "date", roles$date, warning_vars = warning_vars, accent_class = "accent-blue text-sm"),
        render_role_zone_ui("Categoricas", "categorical", roles$categorical, warning_vars = warning_vars, accent_class = "accent-green text-sm"),
        render_role_zone_ui("Numericas", "numeric", roles$numeric, warning_vars = warning_vars, accent_class = "accent-gold text-sm"),
        render_role_zone_ui("Conservar", "preserve", roles$preserve, warning_vars = warning_vars, accent_class = "accent-gray text-sm")
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
          privacy_model = if (isTRUE(input$enable_k)) {
            list(
              type = "k_anonymity", 
              k = input$k_value,
              quasi_identifiers = intersect(unique(c(roles$id, roles$date, roles$categorical)), names(df)),
              suppression = input$k_suppression,
              group_ids = input$group_ids
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
          group_ids = input$group_ids
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
        project_key = if (nchar(input$project_key) > 0) input$project_key else NULL
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
