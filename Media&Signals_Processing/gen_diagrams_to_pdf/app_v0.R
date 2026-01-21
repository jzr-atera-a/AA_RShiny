library(shiny)
library(shinydashboard)
library(shinyFiles)
library(pagedown)

ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = "HTML to PDF Converter"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Converter", tabName = "converter", icon = icon("file-pdf")),
      menuItem("Help", tabName = "help", icon = icon("question-circle"))
    )
  ),
  dashboardBody(
    tags$head(
      tags$style(HTML("
      .skin-blue .main-header .navbar {
        background-color: #008A82 !important;
      }
      .skin-blue .main-header .logo {
        background-color: #002C3C !important;
      }
      .skin-blue .main-header .logo:hover {
        background-color: #008A82 !important;
      }
      .skin-blue .main-sidebar {
        background-color: #00A39A !important;
      }
      .skin-blue .sidebar-menu > li.header {
        background: #008A82 !important;
        color: white !important;
      }
      .skin-blue .sidebar-menu > li > a {
        color: white !important;
      }
      .skin-blue .sidebar-menu > li:hover > a,
      .skin-blue .sidebar-menu > li.active > a {
        background-color: #008A82 !important;
        color: white !important;
      }
      .content-wrapper, .right-side {
        background-color: #002C3C !important;
      }
      .box {
        background: #00A39A !important;
        border-top: none !important;
        color: white !important;
      }
      .box-header {
        background: #00A39A !important;
        color: white !important;
      }
      .box-body {
        background: white !important;
        color: #2c3e50 !important;
      }
      .box-title {
        color: white !important;
      }
      .metric-box {
        background: white;
        border-radius: 8px;
        padding: 15px;
        margin: 10px 0;
        border-left: 4px solid #00A39A;
        box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        color: #2c3e50 !important;
      }
      .form-control {
        background-color: rgba(255,255,255,0.9) !important;
        border: 1px solid #bdc3c7 !important;
        color: #2c3e50 !important;
      }
      .form-control:focus {
        border-color: #008A82 !important;
        box-shadow: 0 0 0 0.2rem rgba(0, 163, 154, 0.25) !important;
      }
      .info-box {
        background: #f8f9fa;
        border: 1px solid #dee2e6;
        border-radius: 8px;
        padding: 15px;
        margin: 20px 0;
        font-size: 0.9em;
        color: #495057;
      }
      .info-box h5 {
        color: #00A39A;
        margin-bottom: 10px;
        font-weight: bold;
      }
      .btn-primary {
        background-color: #008A82 !important;
        border-color: #008A82 !important;
      }
      .btn-primary:hover {
        background-color: #00A39A !important;
        border-color: #00A39A !important;
      }
      .directory-display {
        background-color: #f8f9fa;
        border: 1px solid #dee2e6;
        border-radius: 4px;
        padding: 10px;
        min-height: 40px;
        font-family: monospace;
        color: #495057;
        word-break: break-all;
      }
      .file-list-item {
        background: #f8f9fa;
        border-left: 3px solid #00A39A;
        padding: 10px;
        margin: 5px 0;
        border-radius: 4px;
      }
      .alert-success {
        background: #d4edda;
        color: #155724;
        border: 1px solid #c3e6cb;
        border-radius: 4px;
        padding: 12px;
        margin: 10px 0;
      }
      .alert-danger {
        background: #f8d7da;
        color: #721c24;
        border: 1px solid #f5c6cb;
        border-radius: 4px;
        padding: 12px;
        margin: 10px 0;
      }
      .alert-info {
        background: #d1ecf1;
        color: #0c5460;
        border: 1px solid #bee5eb;
        border-radius: 4px;
        padding: 12px;
        margin: 10px 0;
      }
      .file-input-box {
        border: 2px dashed #cbd5e0;
        border-radius: 8px;
        padding: 20px;
        text-align: center;
        background: #f8f9fa;
        transition: all 0.3s ease;
      }
      .file-input-box:hover {
        border-color: #00A39A;
        background: #fff;
      }
      h4.box-title {
        font-weight: 600;
      }
      .help-section {
        background: white;
        border-radius: 8px;
        padding: 20px;
        margin-bottom: 20px;
        color: #2c3e50;
      }
      .help-section h3 {
        color: #00A39A;
        margin-bottom: 15px;
      }
      .help-section ul {
        margin-left: 20px;
      }
      .help-section li {
        margin-bottom: 8px;
      }
      .page-range-group {
        display: flex;
        align-items: center;
        gap: 10px;
      }
      .page-range-group label {
        margin: 0;
        font-weight: 600;
        color: #2c3e50;
      }
      .page-range-group select {
        width: 80px;
      }
    "))
    ),
    tabItems(
      tabItem(
        tabName = "converter",
        fluidRow(
          box(
            title = "Step 1: Select HTML Files",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            div(class = "file-input-box",
                fileInput("html_files", NULL, multiple = TRUE, accept = c(".html", ".htm"),
                          width = "100%", buttonLabel = "Browse Files", placeholder = "Choose 1-8 HTML files")
            ),
            uiOutput("file_list_display")
          )
        ),
        fluidRow(
          box(
            title = "Step 2: Configure Output Settings",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            fluidRow(
              column(4,
                     tags$label("Output Folder:", style = "font-weight: 600; color: #2c3e50;"),
                     br(),
                     shinyDirButton("output_dir", "Select Folder", "Choose output directory",
                                    class = "btn btn-primary", icon = icon("folder-open"), style = "margin-top: 10px;"),
                     br(), br(),
                     div(class = "directory-display", textOutput("selected_dir_display"))
              ),
              column(4,
                     selectInput("page_size",
                                 label = tags$label("Page Size:", style = "font-weight: 600; color: #2c3e50;"),
                                 choices = c(
                                   "A4 (210×297mm)" = "A4",
                                   "Letter (8.5×11in)" = "Letter",
                                   "16:9 Widescreen" = "16:9",
                                   "4:3 Standard" = "4:3"
                                 ),
                                 selected = "A4"
                     ),
                     selectInput("orientation",
                                 label = tags$label("Orientation:", style = "font-weight: 600; color: #2c3e50;"),
                                 choices = c("Portrait (Vertical)" = "portrait", "Landscape (Horizontal)" = "landscape"),
                                 selected = "portrait"
                     )
              ),
              column(4,
                     div(class = "info-box",
                         tags$h5("Page Dimensions:"),
                         uiOutput("page_dimensions_info")
                     )
              )
            ),
            hr(style = "border-color: #dee2e6;"),
            fluidRow(
              column(4,
                     tags$label("Page Range:", style = "font-weight: 600; color: #2c3e50; display: block; margin-bottom: 10px;"),
                     div(class = "page-range-group",
                         tags$span("From page", style = "color: #2c3e50;"),
                         selectInput("page_from", NULL, choices = 1:20, selected = 1, width = "80px"),
                         tags$span("to page", style = "color: #2c3e50;"),
                         selectInput("page_to", NULL, choices = 1:20, selected = 1, width = "80px")
                     )
              ),
              column(4,
                     numericInput("scale_percent",
                                  label = tags$label("Scale (%):", style = "font-weight: 600; color: #2c3e50;"),
                                  value = 100,
                                  min = 10,
                                  max = 200,
                                  step = 5
                     )
              ),
              column(4,
                     div(class = "info-box", style = "margin-top: 0;",
                         tags$h5("Tips:"),
                         HTML("<small>Set page range to 1-1 to save only the first page and avoid blank pages.<br>
                        Scale 100% maintains original size.</small>")
                     )
              )
            )
          )
        ),
        fluidRow(
          box(
            title = "Step 3: Convert Files",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            div(style = "text-align: center; padding: 20px;",
                actionButton("convert_btn", "Convert to PDF", class = "btn btn-primary btn-lg",
                             icon = icon("file-pdf"), style = "font-size: 18px; padding: 12px 40px;")
            ),
            uiOutput("progress_ui"),
            uiOutput("status_message")
          )
        )
      ),
      tabItem(
        tabName = "help",
        fluidRow(
          box(
            title = "User Guide",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "help-section",
                h3("How to Use This Application"),
                tags$ol(
                  tags$li(tags$strong("Select HTML Files:"), " Click 'Browse Files' and choose 1-8 HTML files you want to convert to PDF."),
                  tags$li(tags$strong("Choose Output Folder:"), " Click 'Select Folder' to choose where the PDF files will be saved."),
                  tags$li(tags$strong("Configure Page Settings:"), " Select page size, orientation, page range, and scale."),
                  tags$li(tags$strong("Set Page Range:"), " Use page range to control which pages to save (default 1-1 saves only first page)."),
                  tags$li(tags$strong("Convert:"), " Click the 'Convert to PDF' button to start the conversion process.")
                )
            ),
            div(class = "help-section",
                h3("Page Range Control"),
                tags$ul(
                  tags$li(tags$strong("Default (1 to 1):"), " Saves only the first page, preventing blank extra pages"),
                  tags$li(tags$strong("Multiple Pages:"), " Set range like 1 to 3 to save pages 1, 2, and 3"),
                  tags$li(tags$strong("Single Page:"), " Keep both dropdowns at the same number to save one page"),
                  tags$li(tags$strong("Tip:"), " If you see blank pages, use page range 1-1 to save only the content page")
                )
            ),
            div(class = "help-section",
                h3("Scale Control"),
                tags$ul(
                  tags$li(tags$strong("100%:"), " Original size (default, recommended)"),
                  tags$li(tags$strong("Less than 100%:"), " Shrinks content (e.g., 80% makes it smaller)"),
                  tags$li(tags$strong("More than 100%:"), " Enlarges content (e.g., 120% makes it bigger)"),
                  tags$li(tags$strong("Range:"), " Allowed from 10% to 200%")
                )
            ),
            div(class = "help-section",
                h3("Page Size Options"),
                tags$ul(
                  tags$li(tags$strong("A4:"), " Standard document size (210×297mm / 8.27×11.69in)"),
                  tags$li(tags$strong("Letter:"), " US standard (8.5×11 inches / 215.9×279.4mm)"),
                  tags$li(tags$strong("16:9 Widescreen:"), " PowerPoint widescreen format (10×5.625 inches)"),
                  tags$li(tags$strong("4:3 Standard:"), " PowerPoint standard format (10×7.5 inches)")
                )
            ),
            div(class = "help-section",
                h3("Features"),
                tags$ul(
                  tags$li("Page range control: Save specific pages only"),
                  tags$li("Scale adjustment: Resize content from 10% to 200%"),
                  tags$li("Multiple orientations: Portrait or Landscape"),
                  tags$li("PowerPoint compatible formats: 16:9 and 4:3 ratios"),
                  tags$li("Batch conversion: Process up to 8 HTML files at once"),
                  tags$li("High-resolution output: Maintains HTML quality")
                )
            )
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  rv <- reactiveValues(output_dir = NULL, converting = FALSE)
  
  volumes <- c(Home = fs::path_home(), getVolumes()())
  if (.Platform$OS.type == "windows") {
    drive_letters <- LETTERS[3:26]
    for (letter in drive_letters) {
      drive_path <- paste0(letter, ":/")
      if (dir.exists(drive_path)) {
        volumes[[paste0(letter, ":")]] <- drive_path
      }
    }
  }
  
  shinyDirChoose(input, "output_dir", roots = volumes, session = session,
                 restrictions = system.file(package = "base"))
  
  observeEvent(input$output_dir, {
    if (!is.null(input$output_dir) && !is.integer(input$output_dir)) {
      dir_path <- parseDirPath(volumes, input$output_dir)
      if (length(dir_path) > 0) {
        rv$output_dir <- dir_path
      }
    }
  })
  
  output$selected_dir_display <- renderText({
    if (!is.null(rv$output_dir) && length(rv$output_dir) > 0) {
      as.character(rv$output_dir)
    } else {
      "No folder selected"
    }
  })
  
  output$page_dimensions_info <- renderUI({
    page_dims <- get_page_dimensions(input$page_size, input$orientation)
    HTML(paste0(
      "<strong>Width:</strong> ", page_dims$width, " in<br>",
      "<strong>Height:</strong> ", page_dims$height, " in<br>",
      "<strong>Orientation:</strong> ", ifelse(input$orientation == "portrait", "Portrait", "Landscape")
    ))
  })
  
  get_page_dimensions <- function(size, orientation) {
    dims <- switch(size,
                   "A4" = list(width = 8.27, height = 11.69),
                   "Letter" = list(width = 8.5, height = 11),
                   "16:9" = list(width = 10, height = 5.625),
                   "4:3" = list(width = 10, height = 7.5),
                   list(width = 8.27, height = 11.69)
    )
    
    if (orientation == "landscape") {
      list(width = dims$height, height = dims$width)
    } else {
      dims
    }
  }
  
  output$file_list_display <- renderUI({
    req(input$html_files)
    if (nrow(input$html_files) > 8) {
      div(class = "alert-danger", icon("exclamation-triangle"),
          " Please select a maximum of 8 files. You have selected ", nrow(input$html_files), " files.")
    } else {
      div(
        tags$h5("Selected Files:", style = "color: #2c3e50; font-weight: 600; margin-top: 15px;"),
        lapply(1:nrow(input$html_files), function(i) {
          div(class = "file-list-item", icon("file-alt", style = "color: #00A39A;"),
              paste0(" ", input$html_files$name[i]))
        })
      )
    }
  })
  
  observeEvent(input$convert_btn, {
    if (is.null(input$html_files)) {
      showNotification("Please select HTML files to convert.", type = "error", duration = 5)
      return()
    }
    if (nrow(input$html_files) > 8) {
      showNotification("Please select a maximum of 8 files.", type = "error", duration = 5)
      return()
    }
    if (is.null(rv$output_dir) || length(rv$output_dir) == 0) {
      showNotification("Please select an output folder.", type = "error", duration = 5)
      return()
    }
    if (as.numeric(input$page_from) > as.numeric(input$page_to)) {
      showNotification("'From page' must be less than or equal to 'To page'.", type = "error", duration = 5)
      return()
    }
    
    rv$converting <- TRUE
    tryCatch({
      n_files <- nrow(input$html_files)
      success_count <- 0
      
      withProgress(message = 'Converting files...', value = 0, {
        for (i in 1:n_files) {
          incProgress(1/n_files, detail = paste("Processing", input$html_files$name[i]))
          
          input_file <- input$html_files$datapath[i]
          output_name <- tools::file_path_sans_ext(input$html_files$name[i])
          output_file <- file.path(rv$output_dir, paste0(output_name, ".pdf"))
          
          page_dims <- get_page_dimensions(input$page_size, input$orientation)
          scale_factor <- as.numeric(input$scale_percent) / 100
          
          page_ranges <- paste0(input$page_from, "-", input$page_to)
          
          tryCatch({
            pagedown::chrome_print(
              input = input_file,
              output = output_file,
              options = list(
                paperWidth = page_dims$width,
                paperHeight = page_dims$height,
                printBackground = TRUE,
                preferCSSPageSize = FALSE,
                landscape = (input$orientation == "landscape"),
                scale = scale_factor,
                displayHeaderFooter = FALSE,
                marginTop = 0,
                marginBottom = 0,
                marginLeft = 0,
                marginRight = 0,
                pageRanges = page_ranges
              ),
              verbose = FALSE,
              timeout = 60
            )
            success_count <- success_count + 1
          }, error = function(e) {
            showNotification(paste("Error converting", input$html_files$name[i], ":", e$message),
                             type = "warning", duration = 10)
          })
        }
      })
      
      if (success_count > 0) {
        showNotification(paste("Successfully converted", success_count, "of", n_files, "file(s) to PDF!"),
                         type = "message", duration = 5)
      }
    }, error = function(e) {
      showNotification(paste("Error during conversion:", e$message), type = "error", duration = 10)
    }, finally = {
      rv$converting <- FALSE
    })
  })
  
  output$progress_ui <- renderUI({
    if (rv$converting) {
      div(style = "margin-top: 20px;",
          div(class = "alert-info", icon("spinner", class = "fa-spin"), " Converting files... Please wait.")
      )
    }
  })
  
  output$status_message <- renderUI({
    if (!rv$converting && !is.null(input$html_files) && nrow(input$html_files) <= 8 &&
        !is.null(rv$output_dir) && length(rv$output_dir) > 0) {
      div(class = "alert-info", style = "margin-top: 15px;",
          icon("info-circle"), " Ready to convert. Click the button above to start.")
    }
  })
}

shinyApp(ui = ui, server = server)