# modules/Gantt to Tickets/gantt_email_send/server.R

gantt_email_send_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    # Resolve an Assignee value to an email address: use it directly if it
    # already looks like an email, otherwise look up a matching full_name
    # in the assignee contact list (gantt_contacts).
    resolve_email <- function(assignee) {
      if (is.na(assignee) || nchar(trimws(assignee)) == 0) return(NA_character_)
      if (grepl("@", assignee)) return(trimws(assignee))
      if (api_manager$bq_authenticated) {
        contacts <- tryCatch(api_manager$bq_get_gantt_contacts(), error = function(e) data.frame())
        if (nrow(contacts) > 0) {
          match_row <- contacts[tolower(trimws(contacts$full_name)) == tolower(trimws(assignee)), ]
          if (nrow(match_row) > 0) return(match_row$email[1])
        }
      }
      NA_character_
    }

    fill_template <- function(template, task) {
      out <- template
      for (col in c("Task_Name", "Description", "Start_Date", "End_Date", "Duration_Days", "Assignee", "Priority", "Status", "Labels")) {
        val <- if (col %in% names(task) && !is.na(task[[col]])) as.character(task[[col]]) else "N/A"
        out <- gsub(paste0("\\{", col, "\\}"), val, out, fixed = FALSE)
      }
      out
    }

    grouped_emails <- reactive({
      req(api_manager$gantt_tasks_data)
      d <- api_manager$gantt_tasks_data
      if (is.null(d) || nrow(d) == 0 || !"Assignee" %in% names(d)) return(list())

      assignees <- unique(d$Assignee[!is.na(d$Assignee) & nchar(trimws(d$Assignee)) > 0])
      lapply(assignees, function(a) {
        tasks <- d[d$Assignee == a & !is.na(d$Assignee), ]
        list(assignee = a, email = resolve_email(a), tasks = tasks)
      })
    })

    output$email_preview_table <- DT::renderDataTable({
      groups <- grouped_emails()
      if (length(groups) == 0) return(DT::datatable(data.frame(), options = list(dom = 't')))

      preview_df <- do.call(rbind, lapply(groups, function(g) {
        data.frame(Assignee = g$assignee, Email = g$email %||% "NOT FOUND",
                  Task_Count = nrow(g$tasks), stringsAsFactors = FALSE)
      }))
      DT::datatable(preview_df, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
    })

    output$email_summary <- renderText({
      groups <- grouped_emails()
      if (length(groups) == 0) return("No tasks with assignees found. Upload and review a Gantt file first.")
      n_resolved <- sum(sapply(groups, function(g) !is.na(g$email)))
      sprintf("%d assignee(s) found, %d with resolvable email addresses.", length(groups), n_resolved)
    })

    observeEvent(input$send_emails, {
      if (!api_manager$gantt_smtp_authenticated) {
        showNotification("Please configure and test SMTP in Email Config first!", type = "error"); return()
      }
      groups <- grouped_emails()
      if (length(groups) == 0) { showNotification("No emails to send.", type = "warning"); return() }

      cc_list <- if (nchar(trimws(input$cc_emails)) > 0) trimws(strsplit(input$cc_emails, ",")[[1]]) else NULL
      results <- c()

      withProgress(message = 'Sending emails...', value = 0, {
        for (g in groups) {
          if (is.na(g$email)) {
            results <- c(results, paste("✗", g$assignee, "- No email address found"))
            incProgress(1 / length(groups)); next
          }

          body_parts <- sapply(seq_len(nrow(g$tasks)), function(i) fill_template(api_manager$gantt_email_body_template, g$tasks[i, ]))
          subject <- fill_template(api_manager$gantt_email_subject_template, g$tasks[1, ])
          body <- paste(body_parts, collapse = "\n\n---\n\n")

          result <- tryCatch({
            api_manager$send_email_via_curl(
              host = api_manager$gantt_smtp_host, port = api_manager$gantt_smtp_port,
              user = api_manager$gantt_smtp_user, password = api_manager$gantt_smtp_password,
              from = api_manager$gantt_smtp_user, to = g$email, subject = subject, body = body, cc = cc_list
            )
            "✓"
          }, error = function(e) paste("✗ Error:", e$message))

          results <- c(results, paste(result, g$assignee, "(", g$email, ")"))
          incProgress(1 / length(groups))
        }
      })

      output$email_send_result <- renderText({ paste(results, collapse = "\n") })
      showNotification(sprintf("Sent %d of %d emails", sum(grepl("^✓", results)), length(results)), type = "message")
    })

    output$email_send_result <- renderText({ "" })
    session$onSessionEnded(function() {})
  })
}
