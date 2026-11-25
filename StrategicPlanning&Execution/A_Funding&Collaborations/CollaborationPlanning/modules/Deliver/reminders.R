# ---- module ----------------------------------------------
# id:           reminders
# name:         Reminders
# icon:         bell
# description:  Email owners about tasks and milestones due soon and decisions closing; you press the button (no scheduler on shinyapps.io)
# packages:     shiny, DT
# -----------------------------------------------------------
# Ported from BOS modules/Gantt to Tickets/email_send.R and email_configuration.R: one email per person listing their items.

reminders_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("mail_note")),
    card("What would be sent", p(class = "small muted", textOutput(ns("window"), inline = TRUE)), DTOutput(ns("preview")),
      layout_columns(col_widths = c(8, 4),
        textAreaInput(ns("intro"), "Opening line", "Here is what is coming up in the next few days. Thank you!", rows = 2, width = "100%"),
        div(class = "align-bottom", actionButton(ns("send"), "Send reminders", class = "btn-brand", icon = icon("paper-plane"))))),
    uiOutput(ns("result")),
    card("Sent before", DTOutput(ns("log"))))
}

reminders_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    days <- reactive(max(1, num(ctx$settings()$reminder_days)))
    output$window <- renderText(sprintf("Tasks and milestones due in the next %d days (and overdue ones not done), and open decisions closing within 3 days, by person.", days()))
    output$mail_note <- renderUI(if (!smtp_ready(ctx$settings())) note("warn", "Email is not set up, so nothing can be sent yet. An admin can set it up in Admin > Email."))
    items <- reactive({
      lim <- Sys.Date() + days(); pr <- ctx$data$projects(); vis <- ctx$programmes()
      pr <- pr[pr$programme_id %in% vis$programme_id, , drop = FALSE]
      t <- ctx$data$tasks(); t <- t[t$project_id %in% pr$project_id & t$status != "done" & valid_email(t$owner_email), , drop = FALSE]
      t <- t[suppressWarnings(as.Date(t$end_date)) <= lim, , drop = FALSE]
      m <- latest_by(ctx$table("milestones")(), "milestone_id")
      m <- m[m$project_id %in% pr$project_id & m$status == "planned" & valid_email(m$owner_email) & suppressWarnings(as.Date(m$due_date)) <= lim, , drop = FALSE]
      d <- ctx$data$decisions(); d <- d[d$status == "open" & suppressWarnings(as.Date(d$deadline)) <= Sys.Date() + 3, , drop = FALSE]
      ins <- latest_by(ctx$table("decision_inputs")(), c("decision_id", "email"))
      dec_rows <- do.call(rbind, c(list(data.frame(to = character(0), what = character(0), due = character(0), item = character(0))),
        lapply(seq_len(nrow(d)), function(i) {
          who <- unique(tolower(c(d$driver[i], d$approver[i], split_emails(d$contributors[i]))))
          who <- setdiff(who[valid_email(who)], tolower(ins$email[ins$decision_id == d$decision_id[i]]))   # only those who have not weighed in
          if (length(who)) data.frame(to = who, what = "Decision", due = d$deadline[i], item = d$title[i])
        })))
      ptitle <- function(id) pr$title[match(id, pr$project_id)]
      rows <- function(df, what, title, due) if (!nrow(df)) NULL else
        data.frame(to = tolower(df$owner_email), what = what, due = df[[due]], item = paste0(df[[title]], " (", ptitle(df$project_id), ")"))
      rbind(dec_rows[0, ], rows(t, "Task", "task", "end_date"), rows(m, "Milestone", "title", "due_date"), dec_rows)
    })
    output$preview <- renderDT({ x <- items(); x <- x[order(x$to, x$due), , drop = FALSE]
      datatable(setNames(x, c("To", "What", "Due", "Item")), rownames = FALSE, options = list(dom = "tip", pageLength = 15)) })
    observeEvent(input$send, {
      x <- items(); if (!nrow(x)) return(output$result <- renderUI(note("info", "Nothing is due, so nothing was sent.")))
      conf <- smtp_config(ctx$settings()); log <- list()
      withProgress(message = "Sending reminders...", value = 0, for (who in unique(x$to)) {
        y <- x[x$to == who, , drop = FALSE]; y <- y[order(y$due), , drop = FALSE]
        body <- paste0("Hello,\n\n", input$intro, "\n\n", paste(sprintf("- %s due %s: %s%s", y$what, y$due, y$item,
                                                                         ifelse(suppressWarnings(as.Date(y$due)) < Sys.Date(), " (overdue)", "")), collapse = "\n"),
                       "\n\nOpen ", APP_NAME, " to update them.\n")
        subj <- sprintf("%s: %d item(s) coming up", APP_NAME, nrow(y))
        r <- tryCatch({ send_mail(who, subj, body, conf = conf); "" }, error = function(e) safe_error_text(e))
        log[[length(log) + 1]] <- data.frame(sent_at = now_ts(), to_email = who, subject = subj, items = nrow(y), ok = if (nzchar(r)) "FALSE" else "TRUE",
                                             detail = r, sent_by = ctx$user(), stringsAsFactors = FALSE)
        incProgress(1 / length(unique(x$to)))
      })
      l <- do.call(rbind, log); store_append("reminders_log", l, user = ctx$user()); ctx$bump()
      output$result <- renderUI(note(if (all(l$ok == "TRUE")) "ok" else "warn", sprintf("Sent to %d of %d people.", sum(l$ok == "TRUE"), nrow(l)),
                                     if (any(l$ok != "TRUE")) paste(" Failed:", paste(unique(l$detail[l$ok != "TRUE"]), collapse = "; "))))
    })
    output$log <- renderDT({ l <- ctx$table("reminders_log")(); l <- l[order(l$sent_at, decreasing = TRUE), , drop = FALSE]
      datatable(utils::head(l[, c("sent_at", "to_email", "items", "ok", "detail", "sent_by")], 200), rownames = FALSE, options = list(dom = "tip", pageLength = 10)) })
  })
}
