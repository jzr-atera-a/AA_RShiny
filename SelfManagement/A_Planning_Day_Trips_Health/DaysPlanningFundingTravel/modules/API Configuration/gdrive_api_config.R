# modules/API Configuration/gdrive_api_config.R
# ---- module ----------------------------------------------
# id:           gdrive_api_config
# name:         Google Drive
# label:        Google Drive
# icon:         cloud-upload-alt
# description:  Shared Google Drive folder where saved diagrams are kept for other R Shiny apps
# packages:     shiny, shinydashboard, jsonlite, httr2, gargle, DT
# api_optional: bigquery
# -----------------------------------------------------------

# ---- UI ----
gdrive_api_config_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Google Drive for Saved Diagrams",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        uiOutput(ns("status_banner")),

        p("Diagrams saved from the visualisation tabs go into one shared Google Drive folder. ",
          "Other R Shiny apps can read them by path, for example:"),
        tags$pre(style = "white-space: pre-wrap;",
                 "<root folder>/Day Planner/Visualizations/2026-11-22/time_allocation.png"),

        div(class = "alert alert-info",
            tags$strong("Before you connect: "),
            "create a folder in Google Drive, share it with the service-account e-mail shown below as ",
            tags$strong("Editor"), ", then paste the folder's link."),

        fluidRow(
          column(6,
                 h5("1. Service-account key"),
                 checkboxInput(ns("use_bq"), "Use the BigQuery service-account key (same account)", value = TRUE),
                 conditionalPanel(
                   condition = sprintf("input['%s'] == false", ns("use_bq")),
                   fileInput(ns("json_file"), "Select a Drive service-account JSON file:", accept = ".json", width = "100%")
                 ),
                 p(style = "color: #7f8c8d; font-size: 12px;",
                   "The key is read only. It is never copied into the app's data or shown on screen.")
          ),
          column(6,
                 h5("2. Shared root folder"),
                 textInput(ns("root"), "Folder link or ID:", width = "100%",
                           placeholder = "https://drive.google.com/drive/folders/..."),
                 actionButton(ns("connect"), "Save and test connection", icon = icon("plug"),
                              class = "btn-primary", style = "width: 100%;"),
                 br(), br(),
                 actionButton(ns("disconnect"), "Disconnect", icon = icon("unlink"), style = "width: 100%;")
          )
        ),

        hr(),
        h4("Connection status"),
        htmlOutput(ns("connect_status")),

        hr(),
        h4("Folders in Drive"),
        p("Lists the folders and files saved under the root (three levels deep). Use it to check the layout."),
        actionButton(ns("show_tree"), "Show saved folders", icon = icon("folder-tree")),
        br(), br(),
        DT::dataTableOutput(ns("tree_tbl"))
      )
    )
  )
}

# ---- Server ----
gdrive_api_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    msg <- reactiveVal(NULL)
    tree <- reactiveVal(NULL)

    output$status_banner <- renderUI({
      invalidateLater(4000, session)
      if (isTRUE(api_manager$gdrive_authenticated)) {
        cred_banner(TRUE, sprintf("Connected. Diagrams are saved to “%s” as %s.",
                                  api_manager$gdrive_root_name %||% "root", api_manager$gdrive_account %||% "the service account"))
      } else {
        cred_banner(FALSE, "Not connected to Google Drive yet. Diagrams can be saved once the folder is set up below.")
      }
    })

    output$connect_status <- renderUI({
      m <- msg()
      if (is.null(m)) return(tags$div())
      tags$div(class = if (isTRUE(m$ok)) "status-success" else "status-error", style = "margin-top: 8px;",
               tags$i(class = if (isTRUE(m$ok)) "fa fa-check-circle" else "fa fa-times-circle"), " ", m$text)
    })

    observeEvent(input$connect, {
      res <- tryCatch({
        if (isTRUE(input$use_bq)) {
          api_manager$gdrive_use_bq_key <- TRUE
          api_manager$gdrive_key_path <- NULL
          key <- api_manager$bq_key_path
        } else {
          if (is.null(input$json_file$datapath)) stop("Select a Drive service-account JSON file, or tick the BigQuery option.")
          # keep our own copy: the upload's temporary file belongs to this browser session
          kp <- tempfile(fileext = ".json")
          file.copy(input$json_file$datapath, kp, overwrite = TRUE)
          api_manager$gdrive_use_bq_key <- FALSE
          api_manager$gdrive_key_path <- kp
          key <- kp
        }
        gdrive_connect(api_manager, key, input$root)
        gdrive_settings_save(api_manager)
        list(ok = TRUE, text = sprintf("Connected to “%s”. Share it with %s as Editor if you have not already.",
                                       api_manager$gdrive_root_name, api_manager$gdrive_account))
      }, error = function(e) {
        api_manager$gdrive_authenticated <- FALSE
        list(ok = FALSE, text = conditionMessage(e))
      })
      msg(res)
      if (isTRUE(res$ok)) showNotification("Google Drive connected.", type = "message")
    })

    observeEvent(input$disconnect, {
      gdrive_disconnect(api_manager)
      gdrive_settings_save(api_manager)
      tree(NULL)
      msg(list(ok = TRUE, text = "Disconnected. Diagrams will not be saved until you connect again."))
    })

    observeEvent(input$show_tree, {
      if (!isTRUE(api_manager$gdrive_authenticated)) {
        showNotification("Connect to Google Drive first.", type = "warning")
        return()
      }
      tr <- tryCatch(gdrive_tree(gdrive_key_for(api_manager), api_manager$gdrive_root_id, depth = 3L),
                     error = function(e) { showNotification(paste("Could not list folders:", conditionMessage(e)), type = "error"); NULL })
      tree(tr)
    })

    output$tree_tbl <- DT::renderDataTable({
      d <- tree()
      req(!is.null(d))
      DT::datatable(d, rownames = FALSE, options = list(pageLength = 25, dom = "tp"))
    })
  })
}
