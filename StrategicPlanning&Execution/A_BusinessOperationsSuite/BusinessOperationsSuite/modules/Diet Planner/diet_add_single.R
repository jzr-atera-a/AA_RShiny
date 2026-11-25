# modules/Diet Planner/diet_add_single.R
# ---- module ----------------------------------------------
# id:           diet_add_single
# name:         Add Single Entry
# icon:         plus-circle
# description:  Log a single meal entry
# packages:     shiny, shinydashboard
# -----------------------------------------------------------

# ---- UI ----
diet_add_single_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Log a Single Meal Entry",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        dateInput(ns("log_date"), "Date:", value = Sys.Date()),
        bos_tz_dropdown_ui(ns, help = "Saved with the entry, so calendar exports use the right zone."),
        diet_type_dropdown_ui(ns),
        textInput(ns("dietary_restrictions"), "Dietary Restrictions (optional):", placeholder = "e.g., Gluten-free"),

        hr(),

        selectInput(ns("row_type"), "Row Type:", choices = c("Meal", "Summary")),
        textInput(ns("meal_name"), "Meal Name:", placeholder = "e.g., Breakfast - Oatmeal with Berries"),
        textInput(ns("meal_details"), "Details:", placeholder = "e.g., Ingredients and preparation notes"),
        textInput(ns("meal_time"), "Meal Time (Meal rows only):", placeholder = "e.g., 7:30 AM, or N/A"),
        textInput(ns("calories_macros"), "Calories / Macros:", placeholder = "e.g., 420 kcal (P:32g / C:38g / F:14g)"),
        textAreaInput(ns("observations"), "Observations:", rows = 4, placeholder = "Tips, substitutions, or day-level insights..."),

        br(),
        actionButton(ns("submit"), "Submit Entry", class = "btn-success btn-lg", icon = icon("save"), style = "width: 100%;"),
        br(), br(),
        htmlOutput(ns("status"))
      )
    )
  )
}

# ---- Server ----
diet_add_single_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    diet_type_react <- setup_diet_type_cascade(input, output, session, api_manager)

    observeEvent(input$submit, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      dt <- diet_type_react()
      if (nchar(dt) == 0 || trimws(input$meal_name) == "" || trimws(input$meal_details) == "") {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                   " Please fill in Diet Type, Meal Name, and Details")
        })
        return()
      }

      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Submitting...") })

      tryCatch({
        log_date_chr <- as.character(input$log_date)

        next_seq <- tryCatch({
          safe_date <- safe_sql_escape(log_date_chr)
          q <- sprintf("SELECT COALESCE(MAX(row_sequence), 0) as max_seq FROM `%s` WHERE log_date = '%s'",
                       api_manager$bq_full_table_diet, safe_date)
          r <- api_manager$bq_query(q)
          as.integer(r$max_seq[1]) + 1
        }, error = function(e) 1)

        df <- data.frame(
          log_date = log_date_chr, diet_type = dt,
          dietary_restrictions = ifelse(trimws(input$dietary_restrictions) == "", "N/A", trimws(input$dietary_restrictions)),
          row_type = input$row_type, row_sequence = next_seq,
          meal_name = trimws(input$meal_name), meal_details = trimws(input$meal_details),
          meal_time = ifelse(trimws(input$meal_time) == "", "N/A", trimws(input$meal_time)),
          calories_macros = trimws(input$calories_macros), observations = trimws(input$observations),
          stringsAsFactors = FALSE
        )

        df$time_zone <- bos_tz_value(input$time_zone)
        api_manager$bq_insert_diet(df)
        api_manager$trigger_state_update_diet()

        output$status <- renderUI({ tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), " Entry submitted successfully!") })
        showNotification("✓ Entry submitted!", type = "message")

        updateTextInput(session, "meal_name", value = "")
        updateTextInput(session, "meal_details", value = "")
        updateTextInput(session, "meal_time", value = "")
        updateTextInput(session, "calories_macros", value = "")
        updateTextAreaInput(session, "observations", value = "")

      }, error = function(e) {
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$status <- renderUI({ tags$div() })
    session$onSessionEnded(function() {})
  })
}
