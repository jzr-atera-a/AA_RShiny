# modules/Six Sigma Analysis/sixsigma_recommender/server.R

sixsigma_recommender_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    recommendations <- reactiveVal(NULL)

    observeEvent(input$recommend, {

      if (!api_manager$claude_authenticated) {
        showNotification("Please configure and save Claude API credentials first!", type = "error", duration = 10)
        return()
      }
      if (nchar(trimws(input$problem_description %||% "")) < 15) {
        showNotification("Please describe the problem in a bit more detail.", type = "error")
        return()
      }

      shinyjs::show("loading_spinner")
      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Analysing (this may take 20-40 seconds)...")
      })
      recommendations(NULL)
      output$recommendations_table <- DT::renderDataTable({})

      n <- input$num_recommendations
      prompt <- generate_sixsigma_recommendation_prompt(input$problem_description, n)

      # ---- DEBUG ----
      cat("========================================================\n")
      cat("🧠 [Six Sigma Recommender][DEBUG] Requesting tool recommendations from Claude\n")
      cat(sprintf("    num_recommendations : %d\n", n))
      cat(sprintf("    problem_description  : %s\n", input$problem_description))
      cat(sprintf("    catalog_size          : %d tools offered\n", length(SIXSIGMA_ALL_TYPES)))
      cat(sprintf("    prompt_length         : %d characters\n", nchar(prompt)))
      cat("========================================================\n")

      tryCatch({
        t0 <- Sys.time()
        response_text <- api_manager$call_claude(prompt = prompt)
        elapsed <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1)

        df <- parse_sixsigma_recommendations(response_text, n)
        recommendations(df)

        cat(sprintf("🧠 [Six Sigma Recommender][DEBUG] Got %d valid recommendation(s) in %ss: %s\n",
                    nrow(df), elapsed, paste(df$diagram_type, collapse = ", ")))

        shinyjs::hide("loading_spinner")

        rank_badge <- function(r) sprintf('<div class="recommender-rank-badge">%d</div>', r)
        tool_link <- function(dtype, label) sprintf(
          '<a href="#" class="recommender-tool-link" onclick="Shiny.setInputValue(\'%s\', \'%s\', {priority: \'event\'}); return false;">%s</a>',
          session$ns("tool_clicked"), dtype, htmltools::htmlEscape(label)
        )

        display_df <- data.frame(
          Rank = sapply(df$rank, rank_badge),
          Tool = mapply(tool_link, df$diagram_type, df$diagram_label),
          Group = df$diagram_group_label,
          Reasoning = htmltools::htmlEscape(df$reasoning),
          Drawbacks = htmltools::htmlEscape(df$drawbacks),
          stringsAsFactors = FALSE
        )

        output$recommendations_table <- DT::renderDataTable({
          DT::datatable(
            display_df,
            escape = FALSE,
            rownames = FALSE,
            selection = "none",
            options = list(
              pageLength = 10, dom = "t", ordering = FALSE,
              columnDefs = list(
                list(width = "60px", targets = 0, className = "dt-center"),
                list(width = "180px", targets = 1),
                list(width = "110px", targets = 2)
              )
            ),
            class = "display recommender-table"
          )
        })

        if (nrow(df) < n) {
          output$status <- renderUI({
            tags$div(class = "status-warning", tags$i(class = "fa fa-exclamation-triangle"),
                     sprintf(" Got %d valid recommendation(s) out of the %d requested (one or more had an unrecognized tool id and was dropped - see console).", nrow(df), n))
          })
        } else {
          output$status <- renderUI({
            tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                     sprintf(" %d recommendation(s) ready. Click any tool name to generate it.", nrow(df)))
          })
        }

      }, error = function(e) {
        shinyjs::hide("loading_spinner")
        cat(sprintf("❌ [Six Sigma Recommender][DEBUG] Failed: %s\n", e$message))
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error", duration = 15)
      })
    })

    # ---- Click-through handoff: store the chosen diagram_type id, then
    #     switch to the Generate Six Sigma Diagram tab, where an observer
    #     on api_manager$pending_sixsigma_selection() auto-selects the
    #     matching Group + Type dropdowns. ----
    observeEvent(input$tool_clicked, {
      dtype <- input$tool_clicked
      if (is.null(dtype) || !dtype %in% SIXSIGMA_ALL_TYPES) return()

      cat(sprintf("🖱️  [Six Sigma Recommender][DEBUG] Recommended tool clicked: %s -> jumping to Generate Six Sigma Diagram\n", dtype))
      api_manager$set_pending_sixsigma_selection(dtype)
      updateTabItems(session$rootScope(), "sidebar_menu", selected = "generate_sixsigma")
      showNotification(sprintf("✓ %s selected - jumping to Generate Six Sigma Diagram", SIXSIGMA_TYPE_LABELS[[dtype]]), type = "message")
    })

    output$status <- renderUI({ tags$div() })
    output$recommendations_table <- DT::renderDataTable({})
  })
}
