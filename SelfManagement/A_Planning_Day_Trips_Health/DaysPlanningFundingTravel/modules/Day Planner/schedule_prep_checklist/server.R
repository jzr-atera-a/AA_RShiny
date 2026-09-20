# modules/Day Planner/schedule_prep_checklist/server.R

schedule_prep_checklist_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    ns <- session$ns
    steps_data <- reactiveVal(data.frame())
    registered_checkboxes <- reactiveVal(character())

    load_steps <- function() {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
      tryCatch({
        d <- api_manager$bq_get_prep_steps_for_date(as.character(input$select_date))
        steps_data(d)
      }, error = function(e) { showNotification(paste("Error:", e$message), type = "error") })
    }

    observeEvent(input$select_date, { load_steps() })
    observeEvent(input$btn_refresh, { load_steps(); showNotification("✓ Progress refreshed!", type = "message") })

    output$progress_stats <- renderUI({
      d <- steps_data()
      if (nrow(d) == 0) return(tags$p("No preparation steps for this date. Generate some in Generate Prep Steps.", class = "text-muted"))

      total <- nrow(d); completed <- sum(as.logical(d$is_completed)); pct <- round(100 * completed / total)
      msg <- if (pct >= 100) "🎉 Fantastic! You're all set for tomorrow!"
             else if (pct >= 66) "💪 You're almost done! Keep going!"
             else if (pct >= 33) "🚀 Halfway there! Stay focused!"
             else "⚡ Let's get started! You've got this!"

      tagList(
        fluidRow(
          column(4, div(class = "metric-box", style = "width: 100%; text-align: center;",
                        div(class = "metric-value", completed), div(class = "metric-label", "Completed"))),
          column(4, div(class = "metric-box", style = "width: 100%; text-align: center;",
                        div(class = "metric-value", total - completed), div(class = "metric-label", "Remaining"))),
          column(4, div(class = "metric-box", style = "width: 100%; text-align: center;",
                        div(class = "metric-value", paste0(pct, "%")), div(class = "metric-label", "Complete")))
        ),
        tags$div(style = "background-color: #ecf0f1; border-radius: 4px; overflow: hidden; height: 25px; margin-top: 10px;",
                 tags$div(style = sprintf("background-color: #008A82; height: 100%%; width: %d%%; text-align: center; color: white; font-weight: bold; line-height: 25px;", pct),
                          if (pct > 10) paste0(pct, "%") else "")),
        tags$div(class = "status-success", style = "margin-top: 10px;", msg)
      )
    })

    output$steps_checklist <- renderUI({
      d <- steps_data()
      if (nrow(d) == 0) return(tags$div())

      # Register one observer per step_id the first time we see it (idempotent
      # if the same date/steps are reloaded - the checkbox handler just makes
      # the same UPDATE again, which is harmless).
      new_ids <- setdiff(as.character(d$id), registered_checkboxes())
      for (step_id in new_ids) {
        local({
          s_id <- step_id
          cb_id <- paste0("step_", s_id)
          observeEvent(input[[cb_id]], {
            if (!is.null(input[[cb_id]])) {
              tryCatch({
                api_manager$bq_update_prep_completion(s_id, isTRUE(input[[cb_id]]))
                showNotification("✓ Saved", type = "message", duration = 1)
              }, error = function(e) showNotification(paste("Error:", e$message), type = "error"))
            }
          }, ignoreInit = TRUE)
        })
      }
      registered_checkboxes(union(registered_checkboxes(), new_ids))

      tagList(lapply(seq_len(nrow(d)), function(i) {
        row <- d[i, ]
        is_done <- isTRUE(row$is_completed)
        tags$div(class = "viz-card", style = if (is_done) "opacity: 0.65;" else "",
                 tags$div(style = "display:flex; align-items:flex-start; gap:12px;",
                          checkboxInput(ns(paste0("step_", row$id)), label = NULL, value = is_done, width = "24px"),
                          tags$div(style = "flex-grow:1;",
                                   tags$span(paste0(row$step_sequence, ". "), style = "font-weight:bold; color:#008A82;"),
                                   tags$span(row$step_text, style = if (is_done) "text-decoration: line-through;" else ""),
                                   tags$div(style = "margin-top:6px;",
                                            if (has_real_value(row$category)) tags$span(class = "section-tag", row$category) else NULL,
                                            if (has_real_value(row$location)) tags$span(class = "section-tag", row$location) else NULL
                                   )
                          )
                 )
        )
      }))
    })

    session$onSessionEnded(function() {})
  })
}
