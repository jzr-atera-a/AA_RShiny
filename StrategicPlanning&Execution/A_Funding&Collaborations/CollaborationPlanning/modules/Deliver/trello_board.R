# ---- module ----------------------------------------------
# id:           trello_board
# name:         Trello board
# icon:         trello
# description:  Send a project's tasks to Trello (one list per work package, one card per task) and pull their status back
# packages:     shiny, httr, DT
# -----------------------------------------------------------
# Ported from the Trello part of BOS modules/Gantt to Tickets/submit_boards.R (and DaysPlanning gantt_submit_boards.R).
# The card id is stored on the task, so sending again updates the card instead of making a copy.

trello_board_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("setup")),
    card(NULL, layout_columns(col_widths = c(6, 6),
      selectInput(ns("proj"), "Project", NULL, width = "100%"),
      selectInput(ns("board"), "Trello board", NULL, width = "100%"))),
    card("Tasks",
      checkboxInput(ns("prefix"), "Start list names with the project name (useful when several projects share a board)", TRUE),
      DTOutput(ns("table")),
      div(class = "btn-row",
          actionButton(ns("send"), "Send to Trello", class = "btn-brand", icon = icon("trello")),
          actionButton(ns("pull"), "Pull status from Trello", class = "btn-ghost", icon = icon("rotate"))),
      uiOutput(ns("result"))))
}

trello_board_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ready <- reactive(nzchar(trello_key()) && nzchar(trello_token()))
    output$setup <- renderUI({
      if (!ready()) note("warn", "Trello is not connected. An admin can add the key and token in Admin > Trello.")
      else if (!nzchar(ctx$settings()$trello_board_id)) note("info", "No default board is chosen in Admin > Trello; pick one below.")
    })
    observe({ ch <- project_picker_choices(ctx); updateSelectInput(session, "proj", choices = ch, selected = pick_sel(isolate(input$proj), ch, ctx$handoff$project)) })
    boards <- reactive({ req(ready()); input$proj; tryCatch(trello_boards(), error = function(e) { log_debug("[Trello] ", safe_error_text(e)); NULL }) })
    observe({
      b <- boards(); def <- ctx$settings()$trello_board_id
      ch <- if (!is.null(b) && nrow(b)) setNames(b$id, b$name) else if (nzchar(def)) c("Board from settings" = def) else character(0)
      updateSelectInput(session, "board", choices = ch, selected = pick_sel(isolate(input$board), ch, def))
    })
    proj <- reactive({ pr <- ctx$data$projects(); pr[pr$project_id == (input$proj %||% ""), , drop = FALSE] })
    tasks <- reactive({ t <- ctx$data$tasks(); t <- t[t$project_id == (input$proj %||% ""), , drop = FALSE]; t[order(t$work_package, t$start_date), , drop = FALSE] })
    output$table <- renderDT({
      t <- tasks()
      d <- data.frame(`Work package` = t$work_package, Task = t$task, Due = t$end_date, Owner = t$owner_email, Status = t$status,
                      `On Trello` = ifelse(nzchar(t$trello_url), sprintf('<a href="%s" target="_blank" rel="noopener">card</a>', t$trello_url), ""), check.names = FALSE)
      datatable(d, rownames = FALSE, escape = -6, selection = "none", options = list(dom = "tip", pageLength = 20))
    })
    list_name <- function(wp) { r <- proj(); if (isTRUE(input$prefix)) paste0(substr(r$title, 1, 40), " - ", wp) else wp }

    observeEvent(input$send, {
      t <- tasks(); req(nrow(t) > 0); b <- input$board
      if (!ready() || !nzchar(b %||% "")) return(output$result <- renderUI(note("bad", "Connect Trello and choose a board first.")))
      out <- character(0); upd <- list()
      res <- withProgress(message = "Sending to Trello...", value = 0, tryCatch({
        lists <- trello_lists(b)
        for (wp in unique(t$work_package)) if (!list_name(wp) %in% lists$name)
          lists <- rbind(lists, data.frame(id = trello_list_create(b, list_name(wp)), name = list_name(wp)))
        for (i in seq_len(nrow(t))) {
          r <- t[i, ]; lid <- lists$id[match(list_name(r$work_package), lists$name)]
          desc <- paste(c(r$description, paste("Owner:", r$owner_email %|% "not set"), paste("Starts:", r$start_date),
                          paste("From", APP_NAME, "task", r$task_id)), collapse = "\n")
          card <- tryCatch(trello_card_upsert(r$trello_card_id, lid, r$task, desc, r$end_date, r$status == "done"),
            error = function(e) {
              # a card deleted on Trello: make a new one
              if (nzchar(r$trello_card_id) && grepl("not found|invalid id|404", conditionMessage(e), ignore.case = TRUE))
                trello_card_upsert("", lid, r$task, desc, r$end_date, r$status == "done") else stop(e) })
          if (!identical(r$trello_card_id, card$id)) { r$trello_card_id <- card$id; r$trello_url <- card$shortUrl %||% card$url %||% ""
            r$updated_at <- now_ts(); r$updated_by <- ctx$user(); upd[[length(upd) + 1]] <- r }
          out <- c(out, r$task); incProgress(1 / nrow(t))
        }
        NULL
      }, error = function(e) safe_error_text(e)))
      if (length(upd)) store_append("tasks", do.call(rbind, upd), user = ctx$user())
      log_change(ctx$user(), "trello", "tasks", sprintf("%d card(s) sent for %s", length(out), proj()$title)); ctx$bump()
      output$result <- renderUI(if (is.null(res)) note("ok", sprintf("%d card(s) sent: %d new, %d updated.", length(out), length(upd), length(out) - length(upd)))
                                else note("bad", sprintf("Stopped after %d card(s): %s", length(out), res)))
    })

    observeEvent(input$pull, {
      t <- tasks(); t <- t[nzchar(t$trello_card_id), , drop = FALSE]; b <- input$board
      if (!nrow(t)) return(output$result <- renderUI(note("info", "No tasks have been sent to Trello yet.")))
      res <- tryCatch({
        cards <- trello_board_cards(b); lists <- trello_lists(b); changed <- list()
        for (i in seq_len(nrow(t))) {
          cd <- cards[cards$id == t$trello_card_id[i], , drop = FALSE]; if (!nrow(cd)) next
          ln <- tolower(lists$name[match(cd$idList, lists$id)] %||% "")
          st <- if (cd$closed || cd$dueComplete || grepl("done|complete", ln)) "done" else if (grepl("doing|progress", ln)) "in progress"
                else if (grepl("block", ln)) "blocked" else t$status[i]
          if (!identical(st, t$status[i])) { r <- t[i, ]; r$status <- st; r$updated_at <- now_ts(); r$updated_by <- "Trello"; changed[[length(changed) + 1]] <- r }
        }
        if (length(changed)) store_append("tasks", do.call(rbind, changed), user = ctx$user())
        note("ok", sprintf("Checked %d card(s); %d status change(s).", nrow(t), length(changed)))
      }, error = function(e) note("bad", safe_error_text(e)))
      ctx$bump(); output$result <- renderUI(res)
    })
  })
}
