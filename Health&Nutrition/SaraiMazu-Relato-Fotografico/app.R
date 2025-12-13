# Galería de Medios - Sistema de Gestión de Fotos y Videos
# Aplicación interactiva para subir y ver medios con descripciones
# Con tema de gradiente azul-púrpura

library(shiny)
library(shinydashboard)
library(DT)
library(shinyWidgets)

# Definir UI
ui <- dashboardPage(
  dashboardHeader(title = "Galería de Medios"),
  
  dashboardSidebar(
    # Título personalizado encima de los tabs
    div(
      style = "padding: 20px 15px; text-align: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); margin-bottom: 10px; border-radius: 8px; margin: 10px;",
      h3("Sarai Mazu", style = "color: #ffffff; margin: 0; font-weight: bold; text-shadow: 2px 2px 4px rgba(0,0,0,0.3);")
    ),
    sidebarMenu(id = "sidebar_menu",
                menuItem("Galería de Fotos", tabName = "photo_gallery", icon = icon("images")),
                menuItem("Galería de Videos", tabName = "video_gallery", icon = icon("film")),
                menuItem("Login Subir Fotos", tabName = "login", icon = icon("key")),
                conditionalPanel(
                  condition = "output.is_authenticated == true",
                  menuItem("Subir Fotos", tabName = "upload_photos", icon = icon("camera")),
                  menuItem("Subir Videos", tabName = "upload_videos", icon = icon("video"))
                )
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        /* Paleta de colores basada en la imagen */
        :root {
          --deep-blue: #0a1128;
          --dark-blue: #1e3c72;
          --medium-blue: #2a5298;
          --bright-blue: #4a90e2;
          --light-blue: #7ec8e3;
          --purple-dark: #3d1f4f;
          --purple-medium: #5e2e6c;
          --purple-light: #764ba2;
          --gradient-main: linear-gradient(135deg, #0a1128 0%, #1e3c72 25%, #2a5298 50%, #4a90e2 75%, #7ec8e3 100%);
          --gradient-purple: linear-gradient(135deg, #3d1f4f 0%, #5e2e6c 50%, #764ba2 100%);
          --gradient-blue: linear-gradient(135deg, #1e3c72 0%, #2a5298 50%, #4a90e2 100%);
        }
        
        /* Header styling */
        .skin-blue .main-header .navbar {
          background: linear-gradient(90deg, #1e3c72 0%, #2a5298 50%, #4a90e2 100%) !important;
          border-bottom: 3px solid #7ec8e3;
        }
        
        .skin-blue .main-header .logo {
          background: linear-gradient(135deg, #0a1128 0%, #1e3c72 100%) !important;
          color: #ffffff !important;
          font-weight: 600;
          border-right: 2px solid #4a90e2;
        }
        
        .skin-blue .main-header .logo:hover {
          background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%) !important;
        }
        
        /* Sidebar styling */
        .skin-blue .main-sidebar {
          background: linear-gradient(180deg, #0a1128 0%, #1e3c72 50%, #2a5298 100%) !important;
          box-shadow: 4px 0 15px rgba(10, 17, 40, 0.5);
        }
        
        .skin-blue .main-sidebar .sidebar .sidebar-menu .active a {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          color: #ffffff !important;
          font-weight: bold;
          border-left: 4px solid #7ec8e3;
          box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
        }
        
        .skin-blue .main-sidebar .sidebar .sidebar-menu a {
          color: #e0e7ff !important;
          transition: all 0.3s ease;
        }
        
        .skin-blue .main-sidebar .sidebar .sidebar-menu a:hover {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
          color: #ffffff !important;
          border-left: 4px solid #7ec8e3;
          transform: translateX(5px);
        }
        
        /* Content wrapper */
        .content-wrapper {
          background: linear-gradient(135deg, #0a1128 0%, #1a2744 100%) !important;
        }
        
        /* Box styling */
        .box {
          background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%) !important;
          border: 2px solid #4a90e2 !important;
          border-radius: 12px !important;
          box-shadow: 0 8px 25px rgba(74, 144, 226, 0.3) !important;
          transition: all 0.3s ease;
        }
        
        .box:hover {
          box-shadow: 0 12px 35px rgba(74, 144, 226, 0.5) !important;
          transform: translateY(-2px);
        }
        
        .box.box-primary {
          border-top-color: #7ec8e3 !important;
          border-top-width: 4px !important;
        }
        
        .box.box-primary .box-header {
          color: #ffffff !important;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          border-radius: 10px 10px 0 0 !important;
          border-bottom: 2px solid #4a90e2 !important;
          padding: 15px;
          font-weight: 600;
        }
        
        .box.box-info .box-header {
          color: #ffffff !important;
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
          border-radius: 10px 10px 0 0 !important;
          border-bottom: 2px solid #7ec8e3 !important;
          padding: 15px;
          font-weight: 600;
        }
        
        .box-body {
          background: linear-gradient(135deg, #0f1f3f 0%, #1a2f5a 100%) !important;
          color: #e0e7ff !important;
          padding: 20px !important;
          border-radius: 0 0 10px 10px;
        }
        
        /* Text styling */
        p { 
          color: #c7d2fe !important; 
          line-height: 1.7 !important; 
        }
        
        strong { 
          color: #7ec8e3 !important; 
          font-weight: 600;
        }
        
        h3, h4, h5, h6 {
          color: #ffffff !important;
        }
        
        /* Upload area styling */
        .upload-area {
          background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%) !important;
          border: 3px dashed #7ec8e3 !important;
          border-radius: 12px;
          padding: 30px;
          text-align: center;
          margin: 20px 0;
          transition: all 0.3s ease;
        }
        
        .upload-area:hover {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%) !important;
          border-color: #a0d8ef !important;
          transform: scale(1.02);
        }
        
        /* Media card styling */
        .media-card {
          background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%) !important;
          border: 2px solid #4a90e2;
          border-radius: 12px;
          padding: 15px;
          margin: 15px;
          box-shadow: 0 6px 20px rgba(74, 144, 226, 0.3);
          transition: all 0.3s ease;
        }
        
        .media-card:hover {
          transform: translateY(-5px);
          box-shadow: 0 10px 30px rgba(74, 144, 226, 0.5);
        }
        
        .media-card img {
          width: 100%;
          border-radius: 8px;
          border: 2px solid #7ec8e3;
        }
        
        .media-card video {
          width: 100%;
          max-height: 500px;
          border-radius: 8px;
          border: 2px solid #7ec8e3;
        }
        
        .media-description {
          background: linear-gradient(135deg, #0f1f3f 0%, #1a2f5a 100%);
          border-radius: 8px;
          padding: 12px;
          margin-top: 10px;
          border: 1px solid #4a90e2;
        }
        
        /* Input styling */
        .form-control {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%) !important;
          color: #ffffff !important;
          border: 2px solid #4a90e2 !important;
          border-radius: 8px;
        }
        
        .form-control:focus {
          border-color: #7ec8e3 !important;
          box-shadow: 0 0 15px rgba(126, 200, 227, 0.4) !important;
        }
        
        textarea.form-control {
          resize: vertical;
          min-height: 100px;
        }
        
        /* Button styling */
        .btn {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          color: #ffffff !important;
          border: none !important;
          border-radius: 8px;
          padding: 10px 20px;
          font-weight: bold;
          transition: all 0.3s ease;
          box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
        }
        
        .btn:hover {
          background: linear-gradient(135deg, #764ba2 0%, #667eea 100%) !important;
          transform: translateY(-2px);
          box-shadow: 0 6px 20px rgba(118, 75, 162, 0.4);
        }
        
        .btn-danger {
          background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important;
        }
        
        .btn-danger:hover {
          background: linear-gradient(135deg, #c0392b 0%, #e74c3c 100%) !important;
        }
        
        /* File input styling */
        .btn-file {
          position: relative;
          overflow: hidden;
          background: linear-gradient(135deg, #4a90e2 0%, #7ec8e3 100%) !important;
        }
        
        .btn-file:hover {
          background: linear-gradient(135deg, #7ec8e3 0%, #4a90e2 100%) !important;
        }
        
        /* Notification styling */
        .shiny-notification {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
          color: #ffffff !important;
          border: 2px solid #7ec8e3 !important;
          border-radius: 8px;
          box-shadow: 0 6px 20px rgba(102, 126, 234, 0.5);
        }
        
        /* Empty state styling */
        .empty-state {
          text-align: center;
          padding: 40px;
          color: #c7d2fe;
        }
        
        .empty-state i {
          font-size: 48px;
          color: #7ec8e3;
          margin-bottom: 20px;
        }
        
        /* Scrollbar styling */
        ::-webkit-scrollbar {
          width: 12px;
        }
        
        ::-webkit-scrollbar-track {
          background: #0a1128;
        }
        
        ::-webkit-scrollbar-thumb {
          background: linear-gradient(135deg, #2a5298 0%, #4a90e2 100%);
          border-radius: 6px;
        }
        
        ::-webkit-scrollbar-thumb:hover {
          background: linear-gradient(135deg, #4a90e2 0%, #7ec8e3 100%);
        }
        
        /* Grid layout for gallery */
        .gallery-grid {
          display: grid;
          grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
          gap: 20px;
          padding: 20px;
        }
        
        /* Video gallery - full width */
        .video-gallery-grid {
          display: flex;
          flex-direction: column;
          gap: 30px;
          padding: 20px;
        }
        
        .video-card-full {
          background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%) !important;
          border: 2px solid #4a90e2;
          border-radius: 12px;
          padding: 20px;
          box-shadow: 0 6px 20px rgba(74, 144, 226, 0.3);
          transition: all 0.3s ease;
        }
        
        .video-card-full:hover {
          box-shadow: 0 10px 30px rgba(74, 144, 226, 0.5);
        }
        
        .video-card-full video {
          width: 100%;
          max-height: 600px;
          border-radius: 8px;
          border: 2px solid #7ec8e3;
        }
        
        /* Status indicator */
        .status-indicator {
          display: inline-block;
          width: 10px;
          height: 10px;
          border-radius: 50%;
          margin-right: 8px;
          animation: pulse 2s infinite;
        }
        
        .status-success {
          background-color: #2ecc71;
        }
        
        .status-error {
          background-color: #e74c3c;
        }
        
        @keyframes pulse {
          0% {
            box-shadow: 0 0 0 0 rgba(126, 200, 227, 0.7);
          }
          70% {
            box-shadow: 0 0 0 10px rgba(126, 200, 227, 0);
          }
          100% {
            box-shadow: 0 0 0 0 rgba(126, 200, 227, 0);
          }
        }
        
        /* Photo item styling */
        .photo-item {
          background: linear-gradient(135deg, #1a2f5a 0%, #2a4070 100%);
          border: 2px solid #4a90e2;
          border-radius: 8px;
          padding: 15px;
          margin-bottom: 15px;
        }
        
        .photo-item img {
          max-width: 200px;
          border-radius: 6px;
          border: 2px solid #7ec8e3;
          margin-bottom: 10px;
        }
        
        /* Login form styling */
        .login-container {
          max-width: 500px;
          margin: 50px auto;
          padding: 40px;
          background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
          border: 2px solid #4a90e2;
          border-radius: 15px;
          box-shadow: 0 10px 30px rgba(74, 144, 226, 0.4);
        }
        
        .login-container h3 {
          text-align: center;
          margin-bottom: 30px;
          color: #ffffff;
        }
        
        .login-container .fa-lock {
          font-size: 48px;
          color: #7ec8e3;
          text-align: center;
          display: block;
          margin-bottom: 20px;
        }
        
        .login-success {
          background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%);
          padding: 20px;
          border-radius: 10px;
          text-align: center;
          color: #ffffff;
          font-weight: bold;
          margin-top: 20px;
        }
        
        .login-error {
          background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);
          padding: 15px;
          border-radius: 10px;
          text-align: center;
          color: #ffffff;
          font-weight: bold;
          margin-top: 20px;
        }
      "))
    ),
    
    tabItems(
      # Tab Login
      tabItem(tabName = "login",
              fluidRow(
                column(12,
                       div(class = "login-container",
                           icon("lock", class = "fa-3x"),
                           h3("Acceso para Subir Contenido"),
                           p("Ingresa la contraseña para habilitar las opciones de subida de fotos y videos.",
                             style = "text-align: center; color: #c7d2fe; margin-bottom: 30px;"),
                           passwordInput("login_password",
                                         label = "Contraseña:",
                                         placeholder = "Ingresa tu contraseña",
                                         width = "100%"),
                           br(),
                           actionButton("login_submit",
                                        "Iniciar Sesión",
                                        icon = icon("sign-in-alt"),
                                        class = "btn btn-primary",
                                        style = "width: 100%; font-size: 16px; padding: 12px;"),
                           uiOutput("login_status")
                       )
                )
              )
      ),
      
      # Tab Subir Fotos
      tabItem(tabName = "upload_photos",
              fluidRow(
                box(width = 12, title = "Subir Fotos", status = "primary", solidHeader = TRUE,
                    div(class = "upload-area",
                        icon("cloud-upload-alt", class = "fa-3x"),
                        h4("Seleccionar Fotos para Subir"),
                        p("Formatos soportados: JPG, JPEG, PNG"),
                        fileInput("photo_upload", 
                                  label = NULL,
                                  accept = c(".jpg", ".jpeg", ".png"),
                                  multiple = TRUE,
                                  buttonLabel = "Buscar Fotos",
                                  placeholder = "No hay archivos seleccionados")
                    ),
                    
                    uiOutput("photo_preview_area")
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Estado de Subida", status = "info",
                    uiOutput("photo_upload_status")
                )
              )
      ),
      
      # Tab Subir Videos
      tabItem(tabName = "upload_videos",
              fluidRow(
                box(width = 12, title = "Subir Videos", status = "primary", solidHeader = TRUE,
                    div(class = "upload-area",
                        icon("video", class = "fa-3x"),
                        h4("Seleccionar Videos para Subir"),
                        p("Formato soportado: MP4 (sin límite de tamaño)"),
                        fileInput("video_upload", 
                                  label = NULL,
                                  accept = c(".mp4"),
                                  multiple = TRUE,
                                  buttonLabel = "Buscar Videos",
                                  placeholder = "No hay archivos seleccionados")
                    ),
                    
                    conditionalPanel(
                      condition = "output.videos_uploaded",
                      br(),
                      h4("Agregar Descripción para los Videos Subidos"),
                      textAreaInput("video_description", 
                                    label = "Descripción:",
                                    placeholder = "Ingresa una descripción para tus videos...",
                                    rows = 4,
                                    width = "100%"),
                      br(),
                      actionButton("save_videos", "Guardar Videos y Descripción", 
                                   icon = icon("save"),
                                   class = "btn btn-primary",
                                   width = "100%")
                    )
                )
              ),
              
              fluidRow(
                box(width = 12, title = "Estado de Subida", status = "info",
                    uiOutput("video_upload_status")
                )
              )
      ),
      
      # Tab Galería de Fotos
      tabItem(tabName = "photo_gallery",
              fluidRow(
                box(width = 12, title = "Galería de Fotos", status = "primary", solidHeader = TRUE,
                    actionButton("refresh_photos", "Actualizar Galería", 
                                 icon = icon("sync"),
                                 class = "btn btn-info"),
                    hr(),
                    uiOutput("photo_gallery_content")
                )
              )
      ),
      
      # Tab Galería de Videos
      tabItem(tabName = "video_gallery",
              fluidRow(
                box(width = 12, title = "Galería de Videos", status = "primary", solidHeader = TRUE,
                    actionButton("refresh_videos", "Actualizar Galería", 
                                 icon = icon("sync"),
                                 class = "btn btn-info"),
                    hr(),
                    uiOutput("video_gallery_content")
                )
              )
      )
    )
  )
)

# Definir Server
server <- function(input, output, session) {
  
  # Aumentar límite de tamaño de archivo a 500MB
  options(shiny.maxRequestSize = 500*1024^2)
  
  # Contraseña correcta (oculta en el código)
  CORRECT_PASSWORD <- "MichiRules01!"
  
  # Crear directorios si no existen
  if (!dir.exists("media_uploads")) {
    dir.create("media_uploads")
  }
  if (!dir.exists("media_uploads/photos")) {
    dir.create("media_uploads/photos")
  }
  if (!dir.exists("media_uploads/videos")) {
    dir.create("media_uploads/videos")
  }
  if (!dir.exists("media_uploads/descriptions")) {
    dir.create("media_uploads/descriptions")
  }
  
  # Valores reactivos para almacenar el estado de subida y autenticación
  photo_data <- reactiveVal(list())
  upload_state <- reactiveValues(
    video_saved = FALSE,
    authenticated = FALSE,
    login_attempts = 0
  )
  
  # Output para verificar si hay videos subidos
  output$videos_uploaded <- reactive({
    !is.null(input$video_upload)
  })
  outputOptions(output, "videos_uploaded", suspendWhenHidden = FALSE)
  
  # Output para verificar autenticación
  output$is_authenticated <- reactive({
    return(upload_state$authenticated)
  })
  outputOptions(output, "is_authenticated", suspendWhenHidden = FALSE)
  
  # Manejar intento de login
  observeEvent(input$login_submit, {
    req(input$login_password)
    
    if (input$login_password == CORRECT_PASSWORD) {
      upload_state$authenticated <- TRUE
      upload_state$login_attempts <- 0
      
      showNotification("¡Acceso concedido! Ahora puedes subir fotos y videos.", 
                       type = "message", duration = 3)
      
      # Cambiar a la pestaña de subir fotos
      updateTabItems(session, "sidebar_menu", "upload_photos")
      
    } else {
      upload_state$authenticated <- FALSE
      upload_state$login_attempts <- upload_state$login_attempts + 1
      
      showNotification("Contraseña incorrecta. Intenta nuevamente.", 
                       type = "error", duration = 3)
    }
    
    # Limpiar campo de contraseña
    updateTextInput(session, "login_password", value = "")
  })
  
  # Estado de login
  output$login_status <- renderUI({
    if (upload_state$authenticated) {
      div(class = "login-success",
          icon("check-circle"),
          " ¡Acceso concedido!",
          br(),
          br(),
          "Ahora puedes acceder a las pestañas de subida de contenido.",
          br(),
          br(),
          actionButton("go_to_upload_photos", 
                       "Ir a Subir Fotos", 
                       icon = icon("camera"),
                       class = "btn btn-success",
                       style = "margin-right: 10px;"),
          actionButton("go_to_upload_videos", 
                       "Ir a Subir Videos", 
                       icon = icon("video"),
                       class = "btn btn-success")
      )
    } else if (upload_state$login_attempts > 0) {
      div(class = "login-error",
          icon("times-circle"),
          " Contraseña incorrecta",
          br(),
          paste("Intentos fallidos:", upload_state$login_attempts)
      )
    }
  })
  
  # Navegación desde login exitoso
  observeEvent(input$go_to_upload_photos, {
    updateTabItems(session, "sidebar_menu", "upload_photos")
  })
  
  observeEvent(input$go_to_upload_videos, {
    updateTabItems(session, "sidebar_menu", "upload_videos")
  })
  
  # Área de vista previa de fotos con descripciones individuales
  output$photo_preview_area <- renderUI({
    req(input$photo_upload)
    
    photo_files <- input$photo_upload
    num_photos <- nrow(photo_files)
    
    # Crear lista de inputs para cada foto
    photo_inputs <- lapply(1:num_photos, function(i) {
      photo_info <- photo_files[i, ]
      
      # Leer la imagen para mostrar preview
      img_data <- readBin(photo_info$datapath, "raw", file.info(photo_info$datapath)$size)
      img_base64 <- base64enc::base64encode(img_data)
      img_src <- paste0("data:image/jpeg;base64,", img_base64)
      
      div(class = "photo-item",
          fluidRow(
            column(3,
                   img(src = img_src, style = "max-width: 100%; border-radius: 6px; border: 2px solid #7ec8e3;")
            ),
            column(9,
                   h5(photo_info$name, style = "color: #7ec8e3;"),
                   textAreaInput(
                     inputId = paste0("photo_desc_", i),
                     label = "Descripción:",
                     placeholder = "Ingresa una descripción para esta foto...",
                     rows = 3,
                     width = "100%"
                   )
            )
          )
      )
    })
    
    div(
      br(),
      h4("Fotos Seleccionadas - Agrega Descripción Individual"),
      photo_inputs,
      br(),
      actionButton("save_all_photos", "Guardar Todas las Fotos con Descripciones", 
                   icon = icon("save"),
                   class = "btn btn-primary",
                   style = "width: 100%; font-size: 16px; padding: 15px;")
    )
  })
  
  # Guardar todas las fotos con sus descripciones individuales
  observeEvent(input$save_all_photos, {
    req(input$photo_upload)
    
    tryCatch({
      photo_files <- input$photo_upload
      num_photos <- nrow(photo_files)
      
      for (i in 1:num_photos) {
        photo_info <- photo_files[i, ]
        
        # Generar nombre único con timestamp
        timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
        new_filename <- paste0(timestamp, "_", i, "_", photo_info$name)
        
        # Copiar archivo a directorio de fotos
        file.copy(photo_info$datapath, 
                  file.path("media_uploads/photos", new_filename),
                  overwrite = TRUE)
        
        # Guardar descripción individual
        desc_input_id <- paste0("photo_desc_", i)
        description <- input[[desc_input_id]]
        
        if (!is.null(description) && nchar(description) > 0) {
          desc_filename <- paste0(tools::file_path_sans_ext(new_filename), ".txt")
          writeLines(description, 
                     file.path("media_uploads/descriptions", desc_filename))
        } else {
          # Guardar descripción vacía si no hay texto
          desc_filename <- paste0(tools::file_path_sans_ext(new_filename), ".txt")
          writeLines("Sin descripción", 
                     file.path("media_uploads/descriptions", desc_filename))
        }
      }
      
      showNotification("¡Fotos y descripciones guardadas exitosamente!", 
                       type = "message", duration = 3)
      
      # Limpiar el input de archivo
      session$sendCustomMessage("resetFileInput", "photo_upload")
      
    }, error = function(e) {
      showNotification(paste("Error al guardar fotos:", e$message), 
                       type = "error", duration = 5)
    })
  })
  
  # Manejar subida y guardado de videos
  observeEvent(input$save_videos, {
    req(input$video_upload)
    
    tryCatch({
      for (i in 1:nrow(input$video_upload)) {
        file_info <- input$video_upload[i,]
        
        # Generar nombre único con timestamp
        timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
        new_filename <- paste0(timestamp, "_", file_info$name)
        
        # Copiar archivo a directorio de videos
        file.copy(file_info$datapath, 
                  file.path("media_uploads/videos", new_filename),
                  overwrite = TRUE)
        
        # Guardar descripción
        if (!is.null(input$video_description) && nchar(input$video_description) > 0) {
          desc_filename <- paste0(tools::file_path_sans_ext(new_filename), ".txt")
          writeLines(input$video_description, 
                     file.path("media_uploads/descriptions", desc_filename))
        }
      }
      
      upload_state$video_saved <- TRUE
      
      showNotification("¡Videos y descripción guardados exitosamente!", 
                       type = "message", duration = 3)
      
      # Resetear inputs
      updateTextAreaInput(session, "video_description", value = "")
      
    }, error = function(e) {
      showNotification(paste("Error al guardar videos:", e$message), 
                       type = "error", duration = 5)
    })
  })
  
  # Estado de subida de fotos
  output$photo_upload_status <- renderUI({
    if (!is.null(input$save_all_photos) && input$save_all_photos > 0) {
      div(
        span(class = "status-indicator status-success"),
        strong("¡Éxito! "),
        "Las fotos han sido guardadas en la galería.",
        br(),
        br(),
        p("Puedes verlas en la pestaña Galería de Fotos.")
      )
    } else if (!is.null(input$photo_upload)) {
      div(
        icon("info-circle"),
        strong(" Listo para guardar: "),
        paste(nrow(input$photo_upload), "foto(s) seleccionada(s)."),
        br(),
        "Por favor agrega descripciones y haz clic en 'Guardar Todas las Fotos con Descripciones'."
      )
    } else {
      div(class = "empty-state",
          icon("images"),
          br(),
          "No hay fotos subidas aún.",
          br(),
          "Selecciona fotos usando el área de subida arriba."
      )
    }
  })
  
  # Estado de subida de videos
  output$video_upload_status <- renderUI({
    if (upload_state$video_saved) {
      div(
        span(class = "status-indicator status-success"),
        strong("¡Éxito! "),
        "Los videos han sido guardados en la galería.",
        br(),
        br(),
        p("Puedes verlos en la pestaña Galería de Videos.")
      )
    } else if (!is.null(input$video_upload)) {
      div(
        icon("info-circle"),
        strong(" Listo para guardar: "),
        paste(nrow(input$video_upload), "video(s) seleccionado(s)."),
        br(),
        "Por favor agrega una descripción y haz clic en 'Guardar Videos y Descripción'."
      )
    } else {
      div(class = "empty-state",
          icon("film"),
          br(),
          "No hay videos subidos aún.",
          br(),
          "Selecciona videos usando el área de subida arriba."
      )
    }
  })
  
  # Función para obtener descripción de un archivo de medios
  get_description <- function(filename) {
    desc_file <- paste0(tools::file_path_sans_ext(filename), ".txt")
    desc_path <- file.path("media_uploads/descriptions", desc_file)
    
    if (file.exists(desc_path)) {
      return(paste(readLines(desc_path, warn = FALSE), collapse = "\n"))
    } else {
      return("Sin descripción disponible")
    }
  }
  
  # Contenido de galería de fotos
  photo_gallery <- reactive({
    input$refresh_photos
    input$save_all_photos
    
    photo_files <- list.files("media_uploads/photos", 
                              pattern = "\\.(jpg|jpeg|png)$", 
                              ignore.case = TRUE,
                              full.names = FALSE)
    
    if (length(photo_files) == 0) {
      return(div(class = "empty-state",
                 icon("images", class = "fa-3x"),
                 h4("No hay fotos en la galería aún"),
                 p("Sube fotos en la pestaña 'Subir Fotos' para verlas aquí.")))
    }
    
    # Crear tarjetas de galería
    photo_cards <- lapply(photo_files, function(photo) {
      photo_path <- file.path("media_uploads/photos", photo)
      
      # Obtener imagen codificada en base64
      img_base64 <- base64enc::base64encode(photo_path)
      img_src <- paste0("data:image/jpeg;base64,", img_base64)
      
      # Obtener descripción
      description <- get_description(photo)
      
      # Extraer nombre de archivo original (remover timestamp)
      display_name <- sub("^[0-9]{8}_[0-9]{6}_[0-9]+_", "", photo)
      
      div(class = "media-card",
          h5(display_name, style = "color: #7ec8e3; margin-bottom: 10px;"),
          img(src = img_src, style = "width: 100%; border-radius: 8px;"),
          div(class = "media-description",
              p(strong("Descripción:"), style = "color: #7ec8e3; margin-bottom: 5px;"),
              p(description, style = "color: #e0e7ff;")
          ),
          p(style = "color: #c7d2fe; font-size: 11px; margin-top: 10px;",
            paste("Subida:", sub("_.*", "", photo)))
      )
    })
    
    div(class = "gallery-grid", photo_cards)
  })
  
  output$photo_gallery_content <- renderUI({
    photo_gallery()
  })
  
  # Contenido de galería de videos (ancho completo)
  video_gallery <- reactive({
    input$refresh_videos
    input$save_videos
    
    video_files <- list.files("media_uploads/videos", 
                              pattern = "\\.mp4$", 
                              ignore.case = TRUE,
                              full.names = FALSE)
    
    if (length(video_files) == 0) {
      return(div(class = "empty-state",
                 icon("film", class = "fa-3x"),
                 h4("No hay videos en la galería aún"),
                 p("Sube videos en la pestaña 'Subir Videos' para verlos aquí.")))
    }
    
    # Crear tarjetas de galería en ancho completo
    video_cards <- lapply(video_files, function(video) {
      video_path <- file.path("media_uploads/videos", video)
      video_path_abs <- normalizePath(video_path, winslash = "/")
      
      # Codificar video en base64 para reproducción en línea
      video_data <- readBin(video_path, "raw", file.info(video_path)$size)
      video_base64 <- base64enc::base64encode(video_data)
      video_src <- paste0("data:video/mp4;base64,", video_base64)
      
      # Obtener descripción
      description <- get_description(video)
      
      # Extraer nombre de archivo original (remover timestamp)
      display_name <- sub("^[0-9]{8}_[0-9]{6}_", "", video)
      
      div(class = "video-card-full",
          h4(display_name, style = "color: #7ec8e3; margin-bottom: 15px;"),
          tags$video(
            src = video_src,
            controls = TRUE,
            style = "width: 100%; max-height: 600px; border-radius: 8px; border: 2px solid #7ec8e3;"
          ),
          div(class = "media-description", style = "margin-top: 15px;",
              p(strong("Descripción:"), style = "color: #7ec8e3; margin-bottom: 5px;"),
              p(description, style = "color: #e0e7ff; font-size: 14px;")
          ),
          p(style = "color: #c7d2fe; font-size: 11px; margin-top: 10px;",
            paste("Subida:", sub("_.*", "", video)))
      )
    })
    
    div(class = "video-gallery-grid", video_cards)
  })
  
  output$video_gallery_content <- renderUI({
    video_gallery()
  })
  
  # Resetear estado de subida al cambiar de pestaña
  observeEvent(input$sidebarItemExpanded, {
    upload_state$video_saved <- FALSE
  })
}

# JavaScript para resetear input de archivo
js_code <- "
Shiny.addCustomMessageHandler('resetFileInput', function(id) {
  var input = document.getElementById(id);
  if (input) {
    input.value = '';
    $(input).trigger('change');
  }
});
"

# Ejecutar la aplicación
shinyApp(
  ui = tagList(
    tags$script(HTML(js_code)),
    ui
  ), 
  server = server
)