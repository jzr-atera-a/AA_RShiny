# ---- module ----------------------------------------------
# id:           work_packages
# name:         Work packages and Gantt
# icon:         bars-progress
# description:  Work packages and tasks per project, from a template or an Excel Gantt, with a Gantt chart
# packages:     shiny, DT, plotly, readxl, writexl
# -----------------------------------------------------------
# Ported from BOS modules/Gantt to Tickets/upload_gantt.R and review_edit.R. Saved to tasks (latest row per task wins).

work_packages_ui <- function(id) {
  ns <- NS(id)
  tagList(
    card(NULL, layout_columns(col_widths = c(6, 2, 2, 2),
      selectInput(ns("proj"), "Project", NULL, width = "100%"),
      dateInput(ns("start"), "Starts"), dateInput(ns("end"), "Ends"),
      div(class = "align-bottom", actionButton(ns("save_dates"), "Save dates", class = "btn-ghost sm")))),
    uiOutput(ns("empty")),
    card("Gantt", plotlyOutput(ns("gantt"), height = "420px")),
    card("Tasks",
      p(class = "small muted", "Double-click a cell to edit it. Dates as YYYY-MM-DD; status is one of: to do, in progress, done, blocked."),
      DTOutput(ns("table")),
      div(class = "btn-row", actionButton(ns("delete"), "Delete selected task", class = "btn-ghost sm", icon = icon("trash")))),
    layout_columns(col_widths = c(7, 5),
      card("Add a task",
        layout_columns(col_widths = c(6, 6), selectizeInput(ns("a_wp"), "Work package", NULL, options = list(create = TRUE)),
                       textInput(ns("a_task"), "Task", width = "100%")),
        layout_columns(col_widths = c(3, 3, 6), dateInput(ns("a_start"), "Start"), dateInput(ns("a_end"), "End", Sys.Date() + 30),
                       selectInput(ns("a_owner"), "Owner", NULL, width = "100%")),
        textInput(ns("a_desc"), "Description", width = "100%"),
        actionButton(ns("add"), "Add task", class = "btn-brand")),
      card("Excel Gantt",
        p(class = "small muted", "Columns: Task_Name, Description, Start_Date, End_Date, Assignee, Work_Package (Labels also works). ",
          "Rows are added to this project."),
        downloadButton(ns("template"), "Download the template", class = "btn-ghost sm"),
        fileInput(ns("xlsx"), NULL, accept = c(".xlsx", ".xls"), buttonLabel = "Upload Gantt"),
        if (!has_pkg("readxl") || !has_pkg("writexl")) note("warn", "Excel upload needs the R packages readxl and writexl (run install.R)."),
        uiOutput(ns("xlsx_status")))))
}

work_packages_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    observe({ ch <- project_picker_choices(ctx); updateSelectInput(session, "proj", choices = ch, selected = pick_sel(isolate(input$proj), ch, ctx$handoff$project)) })
    proj <- reactive({ pr <- ctx$data$projects(); pr[pr$project_id == (input$proj %||% ""), , drop = FALSE] })
    tasks <- reactive({ t <- ctx$data$tasks(); t <- t[t$project_id == (input$proj %||% ""), , drop = FALSE]; t[order(t$work_package, t$start_date), , drop = FALSE] })
    observeEvent(proj(), { r <- proj(); req(nrow(r) > 0)
      updateDateInput(session, "start", value = r$start_date); updateDateInput(session, "end", value = r$end_date)
      ctx$handoff$project <- r$project_id })
    observe({
      r <- proj(); req(nrow(r) > 0)
      updateSelectizeInput(session, "a_wp", choices = unique(c(tasks()$work_package, names(WP_TEMPLATE))))
      updateSelectInput(session, "a_owner", choices = c("(nobody yet)" = "", project_people(r$programme_id, ctx$data$consortium())))
    })
    observeEvent(input$save_dates, { r <- proj(); req(nrow(r) > 0, !ctx$is_partner())
      update_project(r$project_id, list(start_date = format(input$start), end_date = format(input$end)), ctx$user()); ctx$bump()
      showNotification("Dates saved.", type = "message") })

    output$empty <- renderUI({
      if (!length(project_picker_choices(ctx))) return(project_empty_note())
      r <- proj(); req(nrow(r) > 0); if (nrow(tasks())) return(NULL)
      card("No tasks yet", p("Start from the standard four work packages, then change them to fit this bid."),
           actionButton(ns("from_template"), "Create work packages from the template", class = "btn-brand"))
    })
    observeEvent(input$from_template, {
      r <- proj(); req(nrow(r) > 0); p <- ctx$programmes()
      store_append("tasks", template_tasks(r, p$category[p$programme_id == r$programme_id][1] %||% "Grant", ctx$user()), user = ctx$user())
      ctx$bump(); showNotification("Work packages created.", type = "message")
    })

    output$gantt <- renderPlotly({
      t <- tasks(); req(nrow(t) > 0)
      t$s <- as.Date(t$start_date); t$e <- as.Date(t$end_date); t <- t[!is.na(t$s) & !is.na(t$e), , drop = FALSE]; req(nrow(t) > 0)
      t$label <- paste0(substr(t$work_package, 1, 3), " ", t$task)
      t$label <- factor(t$label, levels = rev(unique(t$label)))
      cols <- c("to do" = "#1a9aa8", "in progress" = "#0f4a5c", "done" = "#2f9e6e", "blocked" = "#d6336c")
      t$status <- factor(ifelse(t$status %in% names(cols), t$status, "to do"), levels = names(cols))
      plot_ly(t, colors = cols) |>
        add_segments(x = ~s, xend = ~e, y = ~label, yend = ~label, color = ~status, line = list(width = 14),
                     text = ~paste0(task, "<br>", start_date, " to ", end_date, "<br>", owner_email), hoverinfo = "text") |>
        layout(xaxis = list(title = "", type = "date"), yaxis = list(title = ""), margin = list(l = 10),
               shapes = list(list(type = "line", x0 = Sys.Date(), x1 = Sys.Date(), y0 = 0, y1 = 1, yref = "paper", line = list(color = "#e3a21a", dash = "dot")))) |>
        config(displayModeBar = FALSE)
    })

    shown_cols <- c("work_package", "task", "start_date", "end_date", "owner_email", "partner", "status", "description")
    output$table <- renderDT({
      d <- tasks()[, shown_cols, drop = FALSE]
      names(d) <- c("Work package", "Task", "Start", "End", "Owner", "Partner", "Status", "Description")
      datatable(d, rownames = FALSE, selection = "single", editable = if (ctx$is_partner()) FALSE else list(target = "cell"),
                options = list(dom = "ftip", pageLength = 20, scrollX = TRUE))
    })
    observeEvent(input$table_cell_edit, {
      req(!ctx$is_partner()); e <- input$table_cell_edit; t <- tasks(); r <- t[e$row, , drop = FALSE]; col <- shown_cols[e$col + 1]
      v <- trimws(as.character(e$value))
      if (col %in% c("start_date", "end_date") && !grepl("^\\d{4}-\\d{2}-\\d{2}$", v)) return(showNotification("Dates as YYYY-MM-DD.", type = "warning"))
      if (col == "status" && !v %in% TASK_STATUS) return(showNotification(paste("Status must be one of:", paste(TASK_STATUS, collapse = ", ")), type = "warning"))
      r[[col]] <- v; r$updated_at <- now_ts(); r$updated_by <- ctx$user()
      store_append("tasks", r, user = ctx$user(), log = FALSE); ctx$bump()
    })
    observeEvent(input$delete, {
      req(!ctx$is_partner()); i <- input$table_rows_selected; if (!length(i)) return(showNotification("Select a task first.", type = "warning"))
      r <- tasks()[i, , drop = FALSE]; r$deleted <- "TRUE"; r$updated_at <- now_ts(); r$updated_by <- ctx$user()
      store_append("tasks", r, user = ctx$user()); ctx$bump(); showNotification("Task deleted.", type = "message")
    })
    observeEvent(input$add, {
      r <- proj(); req(nrow(r) > 0, !ctx$is_partner())
      if (blank(input$a_task) || blank(input$a_wp)) return(showNotification("Add a work package and a task.", type = "warning"))
      store_append("tasks", data.frame(task_id = new_id("task"), project_id = r$project_id, work_package = input$a_wp, task = input$a_task,
        start_date = format(input$a_start), end_date = format(input$a_end), owner_email = input$a_owner %||% "", partner = "",
        status = "to do", trello_card_id = "", updated_at = now_ts(), description = input$a_desc %||% "", trello_url = "",
        deleted = "FALSE", updated_by = ctx$user(), stringsAsFactors = FALSE), user = ctx$user())
      updateTextInput(session, "a_task", value = ""); updateTextInput(session, "a_desc", value = "")
      ctx$bump(); showNotification("Task added.", type = "message")
    })
    output$template <- downloadHandler(filename = "gantt_template.xlsx", content = function(file) { need_pkg("writexl"); writexl::write_xlsx(data.frame(
      Task_Name = c("Kick-off", "Prototype", "Field trial"), Description = c("Agree the plan with partners", "First working version", "Trial with two users"),
      Start_Date = format(Sys.Date() + c(0, 14, 60)), End_Date = format(Sys.Date() + c(7, 59, 120)),
      Assignee = c("you@company.com", "", ""), Work_Package = c("WP1 Project management", "WP2 Technical work", "WP3 Testing and validation")), file) })
    observeEvent(input$xlsx, {
      r <- proj(); req(nrow(r) > 0, !ctx$is_partner())
      res <- tryCatch({
        need_pkg("readxl"); x <- as.data.frame(readxl::read_excel(input$xlsx$datapath)); names(x) <- gsub("[ .]", "_", names(x))
        g <- function(...) { for (n in c(...)) if (n %in% names(x)) { v <- as.character(x[[n]]); v[is.na(v)] <- ""; return(v) }; rep("", nrow(x)) }
        dt <- function(v) { d <- suppressWarnings(as.Date(v)); ifelse(is.na(d), "", format(d)) }
        tn <- g("Task_Name", "Task", "task"); keep <- nzchar(tn)
        if (!any(keep)) stop("No Task_Name column or no rows.")
        wp <- g("Work_Package", "Labels"); wp[!nzchar(wp)] <- "Imported"
        own <- g("Assignee", "Owner"); own <- ifelse(valid_email(own), tolower(own), "")
        df <- data.frame(task_id = vapply(seq_len(nrow(x)), function(i) new_id("task"), ""), project_id = r$project_id, work_package = wp,
          task = tn, start_date = dt(g("Start_Date")), end_date = dt(g("End_Date")), owner_email = own, partner = "",
          status = "to do", trello_card_id = "", updated_at = now_ts(), description = g("Description"), trello_url = "",
          deleted = "FALSE", updated_by = ctx$user(), stringsAsFactors = FALSE)[keep, , drop = FALSE]
        store_append("tasks", df, user = ctx$user()); note("ok", sprintf("Added %d task(s).", nrow(df)))
      }, error = function(e) note("bad", "Could not read the file: ", safe_error_text(e)))
      output$xlsx_status <- renderUI(res); ctx$bump()
    })
  })
}
