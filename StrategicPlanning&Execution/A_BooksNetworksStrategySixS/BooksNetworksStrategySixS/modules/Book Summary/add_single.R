# modules/Book Summary/add_single.R
# ---- module --------------------------------------------------------------------------------------
# id:           add_single
# name:         Add Single Entry
# icon:         plus
# description:  Add individual book summary entries
# packages:     shiny, shinydashboard
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

add_single_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Add Single Book Summary Entry",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        textInput(ns("book_name"), "Book Name:", placeholder = "Enter book title"),
        textInput(ns("author"), "Author:", placeholder = "Enter author name"),
        genre_topic_dropdown_ui(ns),
        textInput(ns("chapter"), "Chapter:", placeholder = "e.g., Chapter 01: Introduction"),
        textInput(ns("section"), "Section:", placeholder = "e.g., All Sections"),
        textAreaInput(ns("main_details"), "Main Details:", rows = 8,
                      placeholder = "Enter summary content..."),
        textInput(ns("numeric_data"), "Numeric Data (comma-separated):",
                  placeholder = "e.g., 10,25,30,45,60,75"),

        br(),
        actionButton(ns("submit"), "Submit Entry", class = "btn-success btn-lg",
                    icon = icon("save"), style = "width: 100%;"),
        br(), br(),
        htmlOutput(ns("status"))
      )
    )
  )
}

# ==== Server =======================================================================================

add_single_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    genre_topic <- setup_genre_topic_cascade(input, output, session, api_manager)

    observeEvent(input$submit, {

      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }

      if (trimws(input$book_name) == "" || trimws(input$author) == "" ||
          trimws(input$chapter) == "" || trimws(input$section) == "" ||
          trimws(input$main_details) == "") {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please fill in all required fields")
        })
        return()
      }

      gt <- genre_topic()
      if (nchar(gt$genre) == 0 || nchar(gt$topic) == 0) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please select or enter both Genre and Topic")
        })
        return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Submitting...")
      })

      tryCatch({
        df <- data.frame(
          book_name = trimws(input$book_name),
          author = trimws(input$author),
          genre = gt$genre,
          topic = gt$topic,
          chapter = trimws(input$chapter),
          section = trimws(input$section),
          main_details = trimws(input$main_details),
          formula = "",
          formula_explanation = "",
          reference_url = "",
          reference_description = "",
          numeric_data = trimws(input$numeric_data),
          numeric_data_description = "",
          stringsAsFactors = FALSE
        )

        api_manager$bq_insert_books(df)

        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " Entry submitted successfully!")
        })

        showNotification("✓ Entry submitted!", type = "message")

        # Clear inputs
        updateTextInput(session, "book_name", value = "")
        updateTextInput(session, "author", value = "")
        updateTextInput(session, "chapter", value = "")
        updateTextInput(session, "section", value = "")
        updateTextAreaInput(session, "main_details", value = "")
        updateTextInput(session, "numeric_data", value = "")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Error: ", app_err_text(e))
        })
        showNotification(paste("Error:", app_err_text(e)), type = "error")
      })
    })

    output$status <- renderUI({ tags$div() })
  })
}
