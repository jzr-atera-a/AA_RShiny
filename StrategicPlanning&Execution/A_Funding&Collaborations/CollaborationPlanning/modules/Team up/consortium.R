# ---- module ----------------------------------------------
# id:           consortium
# name:         Consortium
# icon:         users
# description:  Partners per bid: role, status, budget share and the documents each one owes
# packages:     shiny, DT
# -----------------------------------------------------------
# Saved to the consortium table, append-only (latest row per programme + email wins).

consortium_ui <- function(id) {
  ns <- NS(id)
  tagList(
    card(NULL, selectInput(ns("pid"), "Bid (programme)", NULL, width = "100%")),
    uiOutput(ns("share_note")),
    card("Members", DTOutput(ns("table")), uiOutput(ns("edit"))),
    uiOutput(ns("add_box")))
}

consortium_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    observe({ ch <- programme_choices(ctx$programmes(), STAGES[-1])
              updateSelectInput(session, "pid", choices = ch, selected = pick_sel(isolate(input$pid), ch, ctx$handoff$programme)) })
    members <- reactive({ c <- ctx$data$consortium(); c[c$programme_id == (input$pid %||% ""), , drop = FALSE] })
    output$share_note <- renderUI({
      m <- members(); m <- m[m$status != "declined", , drop = FALSE]; req(nrow(m) > 0)
      tot <- sum(num(m$budget_share_pct))
      owed <- sum(vapply(seq_len(nrow(m)), function(i) length(setdiff(split_list(m$documents_owed[i]), split_list(m$documents_received[i]))), 1L))
      tagList(
        if (abs(tot - 100) > 0.01) note("warn", sprintf("Budget shares add up to %s%%, not 100%%.", round(tot, 1)))
        else note("ok", "Budget shares add up to 100%."),
        if (owed) note("info", sprintf("%d document(s) still to come from partners.", owed)))
    })
    output$table <- renderDT({
      m <- members()
      d <- data.frame(Name = ifelse(nzchar(m$name), m$name, m$email), Organisation = m$organisation, Email = m$email,
                      Role = m$role, Status = m$status, `Share %` = m$budget_share_pct,
                      `Documents owed` = m$documents_owed, Received = m$documents_received, Updated = m$updated_at, check.names = FALSE)
      datatable(d, rownames = FALSE, selection = "single", options = list(dom = "tip", pageLength = 10, scrollX = TRUE)) |>
        formatStyle("Status", color = styleEqual(c("committed", "declined"), c("#2f9e6e", "#d6336c")), fontWeight = "bold")
    })
    sel <- reactive({ i <- input$table_rows_selected; if (length(i)) members()[i, , drop = FALSE] else NULL })
    can_edit <- function(r) !ctx$is_partner() || identical(tolower(r$email), tolower(ctx$user()))
    output$edit <- renderUI({
      r <- sel(); req(r)
      if (!can_edit(r)) return(p(class = "small muted", "You can only update your own entry."))
      tagList(tags$hr(), h5("Update ", r$name %|% r$email),
        layout_columns(col_widths = c(3, 3, 2, 4),
          selectInput(ns("e_role"), "Role", CONSORTIUM_ROLES, r$role),
          selectInput(ns("e_status"), "Status", CONSORTIUM_STATUS, r$status),
          numericInput(ns("e_share"), "Share %", num(r$budget_share_pct), min = 0, max = 100),
          textInput(ns("e_owed"), "Documents owed (separated by ;)", r$documents_owed, width = "100%")),
        checkboxGroupInput(ns("e_recv"), "Received", choices = split_list(r$documents_owed), selected = split_list(r$documents_received), inline = TRUE),
        actionButton(ns("e_save"), "Save", class = "btn-brand"))
    })
    observeEvent(input$e_save, {
      r <- sel(); req(r, can_edit(r))
      r$role <- input$e_role; r$status <- input$e_status; r$budget_share_pct <- as.character(input$e_share %||% "")
      r$documents_owed <- input$e_owed; r$documents_received <- paste(input$e_recv, collapse = "; ")
      r$updated_at <- now_ts(); r$updated_by <- ctx$user()
      store_append("consortium", r, user = ctx$user()); ctx$bump(); showNotification("Saved.", type = "message")
    })
    output$add_box <- renderUI({
      req(!ctx$is_partner())
      ppl <- ctx$data$people(); ppl <- ppl[nzchar(ppl$email), , drop = FALSE]
      u <- get_users(); u <- u[u$role %in% c("admin", "member"), , drop = FALSE]
      ch <- c(named(ppl$email, paste0(ppl$name, " (", ppl$organisation, ")")), named(u$email, paste0(u$name %|% u$email, " (team)")))
      ch <- ch[!duplicated(ch)]
      card("Add a member",
        layout_columns(col_widths = c(5, 3, 2, 2),
          selectizeInput(ns("a_email"), "Person (from Collaborators or the team)", ch, options = list(placeholder = "Choose...")),
          selectInput(ns("a_role"), "Role", CONSORTIUM_ROLES, "partner"),
          selectInput(ns("a_status"), "Status", CONSORTIUM_STATUS, "asked"),
          numericInput(ns("a_share"), "Share %", NA, min = 0, max = 100)),
        textInput(ns("a_owed"), "Documents owed (separated by ;)", "Letter of support; Finance form", width = "100%"),
        actionButton(ns("a_add"), "Add to the bid", class = "btn-brand"))
    })
    observeEvent(input$a_add, {
      req(input$pid, input$a_email, !ctx$is_partner())
      e <- tolower(input$a_email); ppl <- ctx$data$people(); pr <- ppl[ppl$email == e, , drop = FALSE]
      u <- get_users(); ur <- u[u$email == e, , drop = FALSE]
      store_append("consortium", data.frame(programme_id = input$pid, email = e, role = input$a_role, status = input$a_status,
        budget_share_pct = if (is.na(input$a_share %||% NA)) "" else as.character(input$a_share), documents_owed = input$a_owed,
        updated_at = now_ts(), documents_received = "", name = (pr$name[1] %||% ur$name[1]) %||% "",
        organisation = (pr$organisation[1] %||% ur$organisation[1]) %||% "", updated_by = ctx$user(), stringsAsFactors = FALSE), user = ctx$user())
      p <- ctx$programmes(); if (p$stage[p$programme_id == input$pid][1] %in% c("Discover", "Qualify")) move_programme_stage(input$pid, "Team up", ctx$user())
      ctx$bump(); showNotification("Added.", type = "message")
    })
  })
}
