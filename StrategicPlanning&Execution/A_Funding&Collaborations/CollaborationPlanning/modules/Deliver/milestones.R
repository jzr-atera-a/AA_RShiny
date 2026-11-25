# ---- module ----------------------------------------------
# id:           milestones
# name:         Milestones and claims
# icon:         flag-checkered
# description:  Milestones and grant claim dates per project; a missed milestone opens a decision
# packages:     shiny, DT
# -----------------------------------------------------------

milestones_ui <- function(id) {
  ns <- NS(id)
  tagList(
    card(NULL, selectInput(ns("proj"), "Project", NULL, width = "100%")),
    uiOutput(ns("overdue")),
    card("Milestones and claims", DTOutput(ns("table")), uiOutput(ns("row_btns"))),
    uiOutput(ns("add_box")))
}

milestones_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    observe({ ch <- project_picker_choices(ctx); updateSelectInput(session, "proj", choices = ch, selected = pick_sel(isolate(input$proj), ch, ctx$handoff$project)) })
    proj <- reactive({ pr <- ctx$data$projects(); pr[pr$project_id == (input$proj %||% ""), , drop = FALSE] })
    ms <- reactive({ m <- latest_by(ctx$table("milestones")(), "milestone_id"); m <- m[m$project_id == (input$proj %||% "") & m$status != "deleted", , drop = FALSE]
                     m[order(m$due_date), , drop = FALSE] })
    output$overdue <- renderUI({
      if (!length(project_picker_choices(ctx))) return(project_empty_note())
      m <- ms(); late <- m[m$status == "planned" & suppressWarnings(as.Date(m$due_date)) < Sys.Date(), , drop = FALSE]
      if (nrow(late)) note("warn", sprintf("%d past their date and still planned: %s. Mark each as done or missed.", nrow(late), paste(late$title, collapse = "; ")))
    })
    output$table <- renderDT({
      m <- ms()
      datatable(data.frame(Due = m$due_date, Kind = m$kind, Title = m$title, `Claim (GBP)` = m$amount_gbp, Owner = m$owner_email,
                           Status = m$status, Note = m$note, check.names = FALSE), rownames = FALSE, selection = "single",
                options = list(dom = "tip", pageLength = 15)) |>
        formatStyle("Status", color = styleEqual(c("done", "missed"), c("#2f9e6e", "#d6336c")), fontWeight = "bold")
    })
    sel <- reactive({ i <- input$table_rows_selected; if (length(i)) ms()[i, , drop = FALSE] else NULL })
    output$row_btns <- renderUI({ r <- sel(); req(r, !ctx$is_partner())
      div(class = "btn-row", actionButton(ns("done"), "Mark done", class = "btn-ghost sm", icon = icon("check")),
          actionButton(ns("missed"), "Mark missed", class = "btn-ghost sm", icon = icon("xmark")),
          actionButton(ns("del"), "Delete", class = "btn-ghost sm", icon = icon("trash"))) })
    set_status <- function(st) { r <- sel(); req(r); r$status <- st; r$updated_at <- now_ts(); r$updated_by <- ctx$user(); r }
    observeEvent(input$done, { store_append("milestones", set_status("done"), user = ctx$user()); ctx$bump() })
    observeEvent(input$del, { store_append("milestones", set_status("deleted"), user = ctx$user()); ctx$bump() })
    observeEvent(input$missed, {
      r <- set_status("missed"); pr <- proj()
      did <- create_decision(paste0("Milestone \"", r$title, "\" missed: what now?"),
        paste0("Project: ", pr$title, ". The ", r$kind, " \"", r$title, "\" was due on ", r$due_date, ".", if (nzchar(r$note)) paste(" Note:", r$note) else ""),
        c("Re-plan the work and keep the scope", "Ask the funder for a change", "Drop or reduce this part of the scope"),
        ctx$user(), programme_id = pr$programme_id, kind = "milestone")
      r$decision_id <- did; store_append("milestones", r, user = ctx$user())
      ctx$bump(); showNotification("Marked missed. A decision has been opened in 4 Decide.", type = "warning", duration = 8)
    })
    output$add_box <- renderUI({ r <- proj(); req(nrow(r) > 0, !ctx$is_partner())
      card("Add a milestone or claim",
        layout_columns(col_widths = c(3, 5, 4), selectInput(ns("kind"), "Kind", c("milestone", "claim", "report")),
                       textInput(ns("title"), "Title", width = "100%"), dateInput(ns("due"), "Due", Sys.Date() + 30)),
        layout_columns(col_widths = c(3, 5, 4), numericInput(ns("amt"), "Claim amount (GBP)", NA, min = 0),
                       selectInput(ns("owner"), "Owner", c("(nobody)" = "", project_people(r$programme_id, ctx$data$consortium()))),
                       textInput(ns("note"), "Note", width = "100%")),
        actionButton(ns("add"), "Add", class = "btn-brand")) })
    observeEvent(input$add, {
      req(proj(), !ctx$is_partner()); if (blank(input$title)) return(showNotification("Give it a title.", type = "warning"))
      store_append("milestones", data.frame(milestone_id = new_id("ms"), project_id = input$proj, title = input$title, kind = input$kind,
        due_date = format(input$due), amount_gbp = if (is.na(input$amt %||% NA)) "" else as.character(input$amt), owner_email = input$owner %||% "",
        status = "planned", decision_id = "", note = input$note %||% "", updated_by = ctx$user(), updated_at = now_ts(), stringsAsFactors = FALSE), user = ctx$user())
      updateTextInput(session, "title", value = ""); ctx$bump(); showNotification("Added.", type = "message")
    })
  })
}
