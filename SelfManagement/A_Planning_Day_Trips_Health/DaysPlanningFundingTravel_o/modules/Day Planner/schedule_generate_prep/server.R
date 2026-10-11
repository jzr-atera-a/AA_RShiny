# modules/Day Planner/schedule_generate_prep/server.R

schedule_generate_prep_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    generated_steps <- reactiveVal(NULL)
    plan_data <- reactiveVal(NULL)

    category_react <- setup_prep_category_cascade(input, output, session, api_manager)
    location_react <- setup_prep_location_cascade(input, output, session, api_manager)

    refresh_dates <- function() {
      if (!api_manager$bq_authenticated) return(invisible(NULL))
      tryCatch({
        dates <- api_manager$bq_query(sprintf(
          "SELECT DISTINCT schedule_date FROM `%s` ORDER BY schedule_date DESC", api_manager$bq_full_table_schedule
        ))
        if (nrow(dates) > 0) {
          updateSelectInput(session, "select_date", choices = setNames(dates$schedule_date, dates$schedule_date))
        } else {
          updateSelectInput(session, "select_date", choices = c("(no planned days yet - use Generate Schedule first)" = ""))
        }
      }, error = function(e) {})
    }

    observeEvent(api_manager$state_trigger_schedule(), { refresh_dates() }, ignoreInit = FALSE)

    observeEvent(input$select_date, {
      req(input$select_date, api_manager$bq_authenticated)
      tryCatch({
        safe_date <- safe_sql_escape(input$select_date)
        rows <- api_manager$bq_query(sprintf(
          "SELECT * FROM `%s` WHERE schedule_date = '%s' ORDER BY row_sequence", api_manager$bq_full_table_schedule, safe_date
        ))
        plan_data(rows)
      }, error = function(e) { plan_data(NULL) })
    })

    output$plan_preview <- renderUI({
      d <- plan_data()
      if (is.null(d) || nrow(d) == 0) return(tags$p("Select a date above", class = "text-muted"))
      summary_row <- d[d$row_type == "Summary", ]
      title <- if (nrow(summary_row) > 0) summary_row$location_details[1] else paste(d$day_type[1], "day")
      tags$div(class = "reference-box",
               tags$strong(d$day_type[1], " - ", d$schedule_date[1]), tags$p(title))
    })

    output$schedule_preview <- renderUI({
      d <- plan_data()
      if (is.null(d) || nrow(d) == 0) return(tags$p("Select a date to see the schedule", class = "text-muted"))
      loc_rows <- d[d$row_type %in% c("Location", "Transport"), ]
      if (nrow(loc_rows) == 0) return(tags$p("No events found for this day", class = "text-muted"))
      shown <- loc_rows[seq_len(min(5, nrow(loc_rows))), ]
      tagList(
        lapply(seq_len(nrow(shown)), function(i) {
          tags$div(class = "details-text", sprintf("%s - %s (%s)", shown$recommended_time[i], shown$location_name[i], shown$row_type[i]))
        }),
        if (nrow(loc_rows) > 5) tags$p(class = "text-muted", sprintf("...and %d more events", nrow(loc_rows) - 5)) else NULL
      )
    })

    run_generate <- function() {
      if (!api_manager$claude_authenticated) {
        showNotification("Please configure Claude API credentials first!", type = "error", duration = 10)
        return()
      }
      d <- plan_data()
      if (is.null(d) || nrow(d) == 0) { showNotification("Please select a planned date first!", type = "error"); return() }

      shinyjs::show("loading_spinner")
      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Generating...") })

      summary_row <- d[d$row_type == "Summary", ]
      plan_summary <- if (nrow(summary_row) > 0) summary_row$location_details[1] else paste(d$day_type[1], "day")

      loc_rows <- d[d$row_type %in% c("Location", "Transport"), ]
      schedule_text <- paste(sprintf("%s: %s (%s)", loc_rows$recommended_time, loc_rows$location_name, loc_rows$row_type), collapse = "\n")

      prompt <- generate_prep_steps_prompt(
        schedule_date = d$schedule_date[1], plan_summary = plan_summary, schedule_text = schedule_text,
        category = category_react(), location = location_react(), additional_context = input$additional_context
      )

      tryCatch({
        result <- api_manager$call_claude(prompt = prompt, progress_callback = function(msg) {})
        steps_df <- parse_prep_steps_text(result$text)
        generated_steps(steps_df)
        shinyjs::hide("loading_spinner")

        output$generated_steps_display <- renderUI({
          tagList(lapply(seq_len(nrow(steps_df)), function(i) {
            tags$div(class = "viz-card", style = "margin-bottom: 10px;",
                     tags$span(paste0(steps_df$step_sequence[i], ". "), style = "font-weight: bold; color: #008A82;"),
                     tags$span(steps_df$step_text[i]))
          }))
        })
        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), sprintf(" %d steps generated!", nrow(steps_df)))
        })
        showNotification("✓ Prep steps generated!", type = "message")

      }, error = function(e) {
        shinyjs::hide("loading_spinner")
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error", duration = 15)
      })
    }

    observeEvent(input$btn_generate, { run_generate() })
    observeEvent(input$btn_regenerate, { run_generate() })

    observeEvent(input$btn_save, {
      steps_df <- generated_steps()
      d <- plan_data()
      if (is.null(steps_df) || nrow(steps_df) == 0) { showNotification("No steps to save. Generate first.", type = "warning"); return() }
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      tryCatch({
        # Replace any previously-saved steps for this date, matching the
        # original "delete existing steps for this day before saving new
        # ones" behavior - this is the one place in Day Planner that's
        # intentionally NOT append-only, since regenerating should replace,
        # not accumulate duplicate checklists for the same day.
        api_manager$bq_delete_prep_steps_for_date(d$schedule_date[1])

        upload_df <- data.frame(
          schedule_date = d$schedule_date[1], category = category_react(), location = location_react(),
          additional_context = input$additional_context %||% "", step_sequence = steps_df$step_sequence,
          step_text = steps_df$step_text, is_completed = FALSE, stringsAsFactors = FALSE
        )
        rows <- api_manager$bq_insert_prep_steps(upload_df)

        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Saved %d steps! View them in Prep Checklist.", rows))
        })
        showNotification(sprintf("✓ Saved %d prep steps!", rows), type = "message")

      }, error = function(e) {
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$btn_reset, {
      generated_steps(NULL)
      updateTextAreaInput(session, "additional_context", value = "")
      output$generated_steps_display <- renderUI({ tags$div() })
      output$status <- renderUI({ tags$div() })
    })

    output$generated_steps_display <- renderUI({ tags$div() })
    output$status <- renderUI({ tags$div() })

    session$onSessionEnded(function() {})
  })
}
