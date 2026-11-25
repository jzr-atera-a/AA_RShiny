# modules/Diet Planner/generate_diet.R
# ---- module ----------------------------------------------
# id:           generate_diet
# name:         Generate Diet
# icon:         utensils
# description:  AI-generated daily meal plan
# packages:     shiny, shinydashboard, httr, curl, jsonlite, shinyjs, DT
# api_required: claude
# -----------------------------------------------------------

# ---- UI ----
generate_diet_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Day Information",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        fluidRow(
          column(6,
                 dateInput(ns("log_date"), "Date:", value = Sys.Date()),
                 diet_type_dropdown_ui(ns),
                 bos_tz_dropdown_ui(ns),
                 numericInput(ns("target_calories"), "Daily Calorie Target (optional):",
                              value = NA, min = 800, max = 5000, step = 50)
          ),
          column(6,
                 textInput(ns("dietary_restrictions"), "Dietary Restrictions / Allergies (optional):",
                           placeholder = "e.g., Gluten-free, Nut allergy, Lactose intolerant"),
                 textAreaInput(ns("preferences"), "Additional Preferences:", height = "120px",
                               placeholder = paste(
                                 "e.g., High protein, avoid dairy,",
                                 "prefer quick meals under 20 minutes,",
                                 "like Mediterranean flavours",
                                 sep = "\n"))
          )
        ),

        hr(),

        fluidRow(
          column(3, actionButton(ns("generate"), "Plan Diet", icon = icon("utensils"),
                                 class = "btn-primary btn-lg", style = "width: 100%;")),
          column(3, actionButton(ns("copy_to_bulk"), "Copy to Bulk Import", icon = icon("arrow-right"),
                                 class = "btn-info btn-lg", style = "width: 100%;")),
          column(3, actionButton(ns("parse_and_upload"), "Parse & Upload Direct", icon = icon("cloud-upload-alt"),
                                 class = "btn-success btn-lg", style = "width: 100%;")),
          column(3, downloadButton(ns("download"), "Download Text", class = "btn-warning", style = "width: 100%;"))
        )
      )
    ),

    fluidRow(
      box(
        title = "Generated Diet Plan",
        status = "success",
        solidHeader = TRUE,
        width = 12,

        div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
            icon("spinner", class = "fa-spin fa-3x"),
            h4("Planning meals... This may take 30-60 seconds.")),

        h5("Review & Edit (re-parse after any manual fix):"),
        textAreaInput(ns("diet_text_edit"), NULL, height = "350px",
                      placeholder = "Generated diet plan will appear here - editable before upload."),
        actionButton(ns("reparse"), "Re-Parse & Update Preview", icon = icon("sync"), class = "btn-default"),

        br(), br(),
        htmlOutput(ns("status")),
        br(),
        DT::dataTableOutput(ns("preview_table"))
      )
    )
  )
}

# ---- Server ----
generate_diet_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    parsed_preview <- reactiveVal(NULL)
    diet_type_react <- setup_diet_type_cascade(input, output, session, api_manager)

    run_parse_preview <- function(text, quiet = FALSE) {
      if (trimws(text) == "") {
        parsed_preview(NULL)
        output$preview_table <- DT::renderDataTable({})
        return(invisible(NULL))
      }
      tryCatch({
        df <- parse_diet_text(text, default_tz = input$time_zone)
        parsed_preview(df)
        output$preview_table <- DT::renderDataTable({
          DT::datatable(df, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
        })

        warnings <- c()
        if (!"Summary" %in% df$row_type) warnings <- c(warnings, "No Summary row found - the day total/insights row is missing.")
        if (!"Meal" %in% df$row_type) warnings <- c(warnings, "No Meal row found - is this really a full day of meals?")

        if (!quiet) {
          output$status <- renderUI({
            tagList(
              tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                       sprintf(" Parsed %d row(s)", nrow(df))),
              if (length(warnings) > 0) tags$div(class = "status-warning",
                       tags$i(class = "fa fa-exclamation-triangle"),
                       paste(" Warning:", paste(warnings, collapse = "; "))) else NULL
            )
          })
        }
      }, error = function(e) {
        parsed_preview(NULL)
        output$preview_table <- DT::renderDataTable({})
        if (!quiet) {
          output$status <- renderUI({
            tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
                     " Parse issue (blocking): ", e$message)
          })
        }
      })
    }

    observeEvent(input$generate, {

      if (!api_manager$claude_authenticated) {
        showNotification("Please configure and save Claude API credentials first!", type = "error", duration = 10)
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                   " Please configure Claude API in the Claude API Config tab first!")
        })
        return()
      }

      dt <- diet_type_react()
      if (nchar(dt) == 0) { showNotification("Please select or enter a Diet Type!", type = "error"); return() }

      shinyjs::show("loading_spinner")
      updateTextAreaInput(session, "diet_text_edit", value = "")

      progress_msg <- reactiveVal("Initializing...")
      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " ", progress_msg())
      })

      prompt <- tryCatch({
        bos_tz_wrap_prompt(generate_diet_prompt(
          as.character(input$log_date), dt,
          input$dietary_restrictions, input$preferences, input$target_calories
        ), input$time_zone, input$log_date)
      }, error = function(e) {
        shinyjs::hide("loading_spinner")
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Failed to build prompt: ", e$message)
        })
        NULL
      })
      if (is.null(prompt)) return()

      tryCatch({
        result <- api_manager$call_claude(
          prompt = prompt,
          progress_callback = function(msg) { progress_msg(msg) }
        )

        diet_text <- bos_tz_set_header(overwrite_diet_header(
          result$text, as.character(input$log_date), dt, input$dietary_restrictions
        ), input$time_zone)

        updateTextAreaInput(session, "diet_text_edit", value = diet_text)
        shinyjs::hide("loading_spinner")

        run_parse_preview(diet_text, quiet = TRUE)

        truncation_note <- if (isTRUE(result$truncated)) {
          tagList(tags$br(), tags$span(style = "color: #f39c12;",
                                        "⚠️ Response truncated - increase Max Tokens and try again"))
        } else NULL

        output$status <- renderUI({
          tags$div(class = if (isTRUE(result$truncated)) "status-warning" else "status-success",
                   tags$i(class = if (isTRUE(result$truncated)) "fa fa-exclamation-triangle" else "fa fa-check-circle"),
                   " ✓ Diet plan ready!", truncation_note)
        })

        showNotification("✓ Diet plan generated successfully!", type = "message")

      }, error = function(e) {
        shinyjs::hide("loading_spinner")
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Planning Failed: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error", duration = 15)
      })
    })

    observeEvent(input$reparse, {
      run_parse_preview(input$diet_text_edit)
    })

    observeEvent(input$copy_to_bulk, {
      current_text <- input$diet_text_edit
      if (nchar(trimws(current_text %||% "")) > 0) {
        api_manager$set_pending_bulk_text_diet(current_text)
        nav_goto(session, "diet_bulk_import")
        showNotification("✓ Diet plan copied to Bulk Import tab!", type = "message")
      } else {
        showNotification("No diet plan to copy. Generate first.", type = "warning")
      }
    })

    observeEvent(input$parse_and_upload, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      current_text <- input$diet_text_edit
      if (nchar(trimws(current_text %||% "")) == 0) { showNotification("No diet plan to upload. Generate first.", type = "warning"); return() }

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing and uploading...")
      })

      tryCatch({
        parsed_df <- parse_diet_text(current_text, default_tz = input$time_zone)
        rows_uploaded <- api_manager$bq_insert_diet(parsed_df)
        api_manager$trigger_state_update_diet()

        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully uploaded %d rows!", rows_uploaded))
        })
        showNotification(sprintf("✓ Uploaded %d rows!", rows_uploaded), type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$download <- downloadHandler(
      filename = function() paste0("diet_", as.character(input$log_date), "_", format(Sys.Date(), "%Y%m%d"), ".txt"),
      content = function(file) writeLines(input$diet_text_edit %||% "", file)
    )

    output$status <- renderUI({ tags$div() })
    output$preview_table <- DT::renderDataTable({})

    session$onSessionEnded(function() {})
  })
}
