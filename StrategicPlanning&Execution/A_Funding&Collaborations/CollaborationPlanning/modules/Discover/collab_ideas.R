# ---- module ----------------------------------------------
# id:           collab_ideas
# name:         General collaboration ideas
# icon:         handshake-angle
# description:  Commercial ideas to explore with clients and partners (not funding): the team adds, builds on and moves them forward
# packages:     shiny, DT
# -----------------------------------------------------------
# Same shape as Programmes, but for commercial work: who the client is, what value we offer, how we would be paid,
# how big it could be and what to do next. Everyone in the team sees every idea and can add notes to build on it
# (partners do not see this tab). Saved to collab_ideas (latest row per idea wins) and collab_notes.

collab_ideas_ui <- function(id) {
  ns <- NS(id)
  tagList(
    note("info", "Ideas for paid work with clients and partners that do not depend on a grant: a pilot for a client, a joint service ",
         "with a university, a product for a new market. Add an idea, then everyone can build on it with notes. ",
         "Rows marked Example show what a good entry looks like."),
    card(NULL,
      layout_columns(col_widths = c(3, 3, 6),
        selectInput(ns("f_status"), "Status", c("All", COLLAB_STATUS)),
        selectInput(ns("f_sector"), "Sector", "All"),
        textInput(ns("f_q"), "Search", width = "100%", placeholder = "client, idea, tag...")),
      DTOutput(ns("table"))),
    uiOutput(ns("detail")),
    card(textOutput(ns("form_title"), inline = TRUE),
      layout_columns(col_widths = c(6, 6),
        textInput(ns("title"), "Idea", width = "100%", placeholder = "e.g. AI triage pilot for a regional logistics firm"),
        textInput(ns("client"), "Client or partner", width = "100%", placeholder = "Who would pay or work with us")),
      layout_columns(col_widths = c(4, 4, 4),
        textInput(ns("sector"), "Sector", width = "100%", placeholder = "e.g. Logistics"),
        textInput(ns("country"), "Country", "United Kingdom", width = "100%"),
        textInput(ns("tags"), "Tags (separated by ;)", width = "100%")),
      textAreaInput(ns("summary"), "What it is", rows = 2, width = "100%"),
      textAreaInput(ns("value"), "Value for the client (why they would buy)", rows = 2, width = "100%"),
      layout_columns(col_widths = c(6, 6),
        textAreaInput(ns("customers"), "Target customers", rows = 2, width = "100%"),
        textAreaInput(ns("revenue"), "How we would be paid", rows = 2, width = "100%", placeholder = "e.g. paid pilot, then yearly licence")),
      layout_columns(col_widths = c(3, 3, 3, 3),
        numericInput(ns("value_gbp"), "Possible value (GBP)", NA, min = 0, step = 1000),
        selectInput(ns("effort"), "Effort", COLLAB_EFFORT, "medium"),
        selectInput(ns("status"), "Status", COLLAB_STATUS),
        selectInput(ns("owner"), "Who leads it", NULL)),
      layout_columns(col_widths = c(6, 6),
        textInput(ns("next_step"), "Next step", width = "100%", placeholder = "e.g. call the operations director by Friday"),
        selectInput(ns("prog"), "Related funding programme (optional)", NULL, width = "100%")),
      textInput(ns("url"), "Link for more information (optional)", width = "100%"),
      div(class = "btn-row",
          actionButton(ns("save"), "Save idea", class = "btn-brand", icon = icon("floppy-disk")),
          actionButton(ns("clear"), "New idea", class = "btn-ghost"))))
}

collab_ideas_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    editing <- reactiveVal("")
    ideas <- reactive({ d <- latest_by(ctx$table("collab_ideas")(), "idea_id"); d[!is_true_vec(d$deleted), , drop = FALSE] })
    notes <- reactive(ctx$table("collab_notes")())
    observe({
      d <- ideas(); ch <- c("All", sort(unique(d$sector[nzchar(d$sector)])))
      updateSelectInput(session, "f_sector", choices = ch, selected = pick_sel(isolate(input$f_sector), ch))
      u <- ctx$data$users(); u <- u[u$role %in% c("admin", "member"), , drop = FALSE]
      och <- c("(nobody yet)" = "", named(tolower(u$email), ifelse(nzchar(u$name), paste0(u$name, " <", u$email, ">"), u$email)))
      updateSelectInput(session, "owner", choices = och, selected = pick_sel(isolate(input$owner), och, tolower(ctx$user())))
      pch <- programme_choices(ctx$programmes(), none = "(none)")
      updateSelectInput(session, "prog", choices = pch, selected = pick_sel(isolate(input$prog), pch, ""))
    })
    shown <- reactive({
      d <- ideas()
      if (!identical(input$f_status, "All")) d <- d[d$status == input$f_status, , drop = FALSE]
      if (!identical(input$f_sector %||% "All", "All")) d <- d[d$sector == input$f_sector, , drop = FALSE]
      q <- tolower(trimws(input$f_q %||% ""))
      if (nzchar(q)) d <- d[grepl(q, tolower(paste(d$title, d$client, d$summary, d$tags, d$sector)), fixed = TRUE), , drop = FALSE]
      d[order(is_true_vec(d$is_example), d$updated_at, decreasing = c(FALSE, TRUE), method = "radix"), , drop = FALSE]
    })
    output$table <- renderDT({
      d <- shown(); n <- notes()
      out <- data.frame(Idea = d$title, Client = d$client, Sector = d$sector, Status = d$status,
                        `Value (GBP)` = ifelse(nzchar(d$est_value_gbp), fmt_num(d$est_value_gbp), ""), Effort = d$effort,
                        Notes = vapply(d$idea_id, function(i) sum(n$idea_id == i), 1L), Lead = d$owner_email,
                        Example = ifelse(is_true_vec(d$is_example), "Example", ""), check.names = FALSE)
      # the chosen idea stays selected when the table refreshes (for example after adding a note)
      keep <- match(isolate(picked()), d$idea_id)
      datatable(out, rownames = FALSE, selection = list(mode = "single", selected = if (is.na(keep)) NULL else keep),
                options = list(dom = "tip", pageLength = 10, scrollX = TRUE, displayStart = if (is.na(keep)) 0 else (keep - 1) %/% 10 * 10)) |>
        formatStyle("Status", color = styleEqual(c("won", "parked"), c("#2f9e6e", "#6b7c88")), fontWeight = "bold")
    })
    picked <- reactiveVal("")
    observeEvent(input$table_rows_selected, { i <- input$table_rows_selected; d <- shown(); if (length(i) && i <= nrow(d)) picked(d$idea_id[i]) })
    observeEvent(input$table_cell_clicked, { if (!length(input$table_rows_selected)) picked("") }, ignoreInit = TRUE)
    sel <- reactive({ d <- shown(); r <- d[d$idea_id == picked(), , drop = FALSE]; if (nrow(r)) r else NULL })
    can_edit <- function(r) ctx$is_owner() || ctx$is_admin() || tolower(r$created_by) == tolower(ctx$user()) || tolower(r$owner_email) == tolower(ctx$user())

    output$detail <- renderUI({
      r <- sel(); if (is.null(r)) return(p(class = "small muted", "Select an idea to see it in full and build on it."))
      n <- notes(); n <- n[n$idea_id == r$idea_id, , drop = FALSE]; n <- n[order(n$created_at), , drop = FALSE]
      p_name <- { p <- ctx$programmes(); p$programme_name[p$programme_id == r$related_programme_id][1] }
      row <- function(l, v) if (length(v) && !is.na(v) && nzchar(v)) tags$tr(tags$th(l), tags$td(v))
      card(tagList(r$title, if (is_true(r$is_example)) example_badge()),
        layout_columns(col_widths = c(7, 5),
          tags$table(class = "kv",
            row("Client or partner", r$client), row("Sector / country", paste(c(r$sector, r$country)[nzchar(c(r$sector, r$country))], collapse = " / ")),
            row("What it is", r$summary), row("Value for the client", r$value_proposition), row("Target customers", r$target_customers),
            row("How we would be paid", r$revenue_model), row("Possible value", if (nzchar(r$est_value_gbp)) fmt_gbp(r$est_value_gbp) else ""),
            row("Effort", r$effort), row("Status", r$status), row("Next step", r$next_step), row("Led by", r$owner_email),
            row("Related programme", p_name), row("Tags", r$tags),
            if (nzchar(r$url)) tags$tr(tags$th("Link"), tags$td(tags$a(href = r$url, target = "_blank", rel = "noopener", r$url)))),
          div(h5("Building on it"),
            if (!nrow(n)) p(class = "small muted", "No notes yet. Add the first one.")
            else lapply(seq_len(nrow(n)), function(i) div(class = "res-card", div(class = "small muted", n$email[i], " - ", substr(n$created_at[i], 1, 16)), n$note[i])),
            textAreaInput(ns("note"), NULL, rows = 2, width = "100%", placeholder = "Add a thought, a contact, a risk or a next step"),
            actionButton(ns("add_note"), "Add note", class = "btn-ghost sm", icon = icon("comment")))),
        div(class = "btn-row",
            if (can_edit(r)) actionButton(ns("edit"), "Edit", class = "btn-ghost sm", icon = icon("pen")),
            if (can_edit(r)) selectInput(ns("quick_status"), NULL, COLLAB_STATUS, r$status, width = "190px"),
            if (can_edit(r)) actionButton(ns("set_status"), "Update status", class = "btn-ghost sm"),
            if (ctx$is_owner()) actionButton(ns("analyse"), "Analyse with Claude", class = "btn-brand sm", icon = icon("robot")),
            if (can_edit(r)) actionButton(ns("del"), "Delete", class = "btn-ghost sm", icon = icon("trash"))))
    })

    fields <- c(title = "title", client = "client", sector = "sector", country = "country", tags = "tags", summary = "summary",
                value_proposition = "value", target_customers = "customers", revenue_model = "revenue", next_step = "next_step", url = "url")
    clear <- function() { editing(""); for (f in fields) updateTextInput(session, f, value = if (f == "country") "United Kingdom" else "")
                          updateNumericInput(session, "value_gbp", value = NA) }
    output$form_title <- renderText(if (nzchar(editing())) "Edit the idea" else "Add an idea")
    observeEvent(input$clear, clear())
    observeEvent(input$edit, {
      r <- sel(); req(r, can_edit(r)); editing(r$idea_id)
      for (k in names(fields)) updateTextInput(session, fields[[k]], value = r[[k]])
      updateNumericInput(session, "value_gbp", value = if (nzchar(r$est_value_gbp)) num(r$est_value_gbp) else NA)
      updateSelectInput(session, "effort", selected = r$effort); updateSelectInput(session, "status", selected = r$status)
      updateSelectInput(session, "owner", selected = r$owner_email); updateSelectInput(session, "prog", selected = r$related_programme_id)
    })
    observeEvent(input$save, {
      if (blank(input$title) || blank(input$summary)) return(showNotification("Add at least the idea and what it is.", type = "warning"))
      old <- if (nzchar(editing())) { d <- ideas(); d[d$idea_id == editing(), , drop = FALSE] } else NULL
      if (!is.null(old) && nrow(old) && !can_edit(old)) return(showNotification("Only the person who added it, its lead or an admin can change it.", type = "error"))
      url <- trimws(input$url %||% ""); if (nzchar(url) && !grepl("^https?://", url)) url <- paste0("https://", url)
      row <- data.frame(idea_id = editing() %|% new_id("cid"), stringsAsFactors = FALSE)
      for (k in names(fields)) row[[k]] <- trimws(input[[fields[[k]]]] %||% "")
      row$url <- url
      row$est_value_gbp <- if (is.na(input$value_gbp %||% NA)) "" else format(input$value_gbp, scientific = FALSE)
      row$effort <- input$effort; row$status <- input$status; row$owner_email <- input$owner %||% ""; row$related_programme_id <- input$prog %||% ""
      row$is_example <- if (!is.null(old) && nrow(old)) old$is_example else "FALSE"
      row$created_by <- if (!is.null(old) && nrow(old)) old$created_by else tolower(ctx$user())
      row$created_at <- if (!is.null(old) && nrow(old)) old$created_at else now_ts()
      row$updated_at <- now_ts(); row$deleted <- "FALSE"
      store_append("collab_ideas", row, user = ctx$user()); ctx$bump(); clear()
      showNotification("Idea saved.", type = "message")
    })
    observeEvent(input$add_note, {
      r <- sel(); req(r); txt <- trimws(input$note %||% "")
      if (!nzchar(txt)) return(showNotification("Write the note first.", type = "warning"))
      store_append("collab_notes", data.frame(note_id = new_id("cn"), idea_id = r$idea_id, email = tolower(ctx$user()), note = txt,
                                              created_at = now_ts(), stringsAsFactors = FALSE), user = ctx$user())
      updateTextAreaInput(session, "note", value = ""); ctx$bump()
    })
    observeEvent(input$set_status, { r <- sel(); req(r, can_edit(r)); r$status <- input$quick_status; r$updated_at <- now_ts()
      store_append("collab_ideas", r, user = ctx$user()); ctx$bump(); showNotification("Status updated.", type = "message") })
    observeEvent(input$del, { r <- sel(); req(r, can_edit(r)); r$deleted <- "TRUE"; r$updated_at <- now_ts()
      store_append("collab_ideas", r, user = ctx$user()); picked(""); ctx$bump() })
    # owner: turn the idea into a suggestion and open the Claude analysis workbench on it
    observeEvent(input$analyse, {
      r <- sel(); req(r, ctx$is_owner())
      s <- latest_suggestions(store_read("suggestions", fresh = TRUE)); hit <- s$suggestion_id[s$notes == paste("From collaboration idea", r$idea_id)]
      sid <- if (length(hit)) hit[1] else {
        id <- new_id("sug")
        store_append("suggestions", data.frame(suggestion_id = id, kind = "collaboration", title = r$title,
          description = paste(c(r$summary, if (nzchar(r$value_proposition)) paste("Value for the client:", r$value_proposition),
                                if (nzchar(r$revenue_model)) paste("How we would be paid:", r$revenue_model)), collapse = "\n"),
          url = r$url, ideas = paste(c(r$next_step, paste("Client or partner:", r$client)), collapse = "\n"), country = r$country,
          category = "Collaboration", topic = r$sector, funder = "", amount_text = if (nzchar(r$est_value_gbp)) fmt_gbp(r$est_value_gbp) else "",
          deadline = "", contact = r$owner_email, notes = paste("From collaboration idea", r$idea_id), status = "new",
          created_by = tolower(r$created_by %|% ctx$user()), created_at = now_ts(), updated_at = now_ts(), deleted = "FALSE",
          stringsAsFactors = FALSE), user = ctx$user())
        id }
      ctx$bump(); ctx$handoff$suggestion <- sid; ctx$nav("suggest", "analysis_workbench")
    })
  })
}
