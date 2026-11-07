# modules/Day Planner/schedule_add_commitment/server.R

schedule_add_commitment_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    last_saved_id <- reactiveVal(NULL)

    category_react <- setup_commitment_category_cascade(input, output, session, api_manager)
    sector_react <- setup_commitment_sector_cascade(input, output, session, api_manager)
    topic_react <- setup_commitment_topic_cascade(input, output, session, api_manager)

    observeEvent(input$btn_save, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      cat_val <- category_react(); sector_val <- sector_react(); topic_val <- topic_react()
      if (nchar(cat_val) == 0 || nchar(sector_val) == 0 || nchar(topic_val) == 0 || trimws(input$description) == "") {
        output$save_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                   " Please fill in Category, Sector, Topic, and a Description")
        })
        return()
      }

      output$save_status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Saving...") })

      tryCatch({
        df <- data.frame(
          category = cat_val, sector = sector_val, topic = topic_val,
          commitment_date = as.character(input$commitment_date), deadline = as.character(input$deadline),
          status = "Not Started", description = trimws(input$description),
          stakeholders = trimws(input$stakeholders), value_of_delivery = trimws(input$value_of_delivery),
          consequences_of_failure = trimws(input$consequences_of_failure),
          trello_card_id = "N/A", trello_card_url = "N/A", stringsAsFactors = FALSE
        )

        new_id <- api_manager$bq_insert_commitment(df)
        last_saved_id(new_id)

        output$save_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   " Commitment saved! You can now optionally push it to Trello below, ",
                   "or find it later in Browse Commitments.")
        })
        showNotification("✓ Commitment saved!", type = "message")

        updateTextAreaInput(session, "description", value = "")
        updateTextAreaInput(session, "stakeholders", value = "")
        updateTextAreaInput(session, "value_of_delivery", value = "")
        updateTextAreaInput(session, "consequences_of_failure", value = "")

      }, error = function(e) {
        output$save_status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$load_trello_lists, {
      req(api_manager$commitment_trello_key, api_manager$commitment_trello_token, api_manager$commitment_trello_board_id)
      tryCatch({
        lists <- api_manager$get_commitment_trello_lists()
        if (length(lists) == 0) { showNotification("Board has no lists.", type = "warning"); return() }
        list_choices <- setNames(sapply(lists, function(x) as.character(x$id)), sapply(lists, function(x) as.character(x$name)))
        updateSelectInput(session, "trello_list", choices = list_choices)
        showNotification(paste("Loaded", length(list_choices), "lists"), type = "message")
      }, error = function(e) { showNotification(paste("Error:", e$message), type = "error") })
    })

    observeEvent(input$btn_push_trello, {
      if (is.null(last_saved_id())) { showNotification("Save a commitment first.", type = "warning"); return() }
      if (!api_manager$commitment_trello_authenticated) { showNotification("Please configure Commitment Trello Config first!", type = "error"); return() }
      req(input$trello_list)

      tryCatch({
        commitment <- api_manager$bq_get_commitment_by_id(last_saved_id())
        if (nrow(commitment) == 0) { showNotification("Could not reload the saved commitment.", type = "error"); return() }
        r <- commitment[1, ]

        card_desc <- paste0(
          "Category: ", r$category, " | Sector: ", r$sector, " | Topic: ", r$topic, "\n",
          "Deadline: ", r$deadline, "\n\n",
          "Stakeholders: ", r$stakeholders, "\n\n",
          "Value of delivering: ", r$value_of_delivery, "\n\n",
          "Consequences of not delivering: ", r$consequences_of_failure
        )

        result <- api_manager$create_commitment_trello_card(input$trello_list, r$description, card_desc)

        if (isTRUE(result$success)) {
          api_manager$bq_update_commitment(last_saved_id(), list(trello_card_id = result$id, trello_card_url = result$url))
          output$trello_push_status <- renderUI({
            tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                     " Pushed to Trello: ", tags$a(href = result$url, target = "_blank", result$url))
          })
          showNotification("✓ Pushed to Trello!", type = "message")
        } else {
          output$trello_push_status <- renderUI({
            tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Trello error: ", result$error)
          })
        }

      }, error = function(e) {
        output$trello_push_status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$save_status <- renderUI({ tags$div() })
    output$trello_push_status <- renderUI({ tags$div() })

    session$onSessionEnded(function() {})
  })
}
