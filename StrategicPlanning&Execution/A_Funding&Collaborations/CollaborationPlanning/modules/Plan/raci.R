# ---- module ----------------------------------------------
# id:           raci
# name:         RACI
# icon:         table-cells
# description:  Who is Responsible, Accountable, Consulted and Informed for each task
# packages:     shiny, DT
# -----------------------------------------------------------
# Grid of tasks by consortium people (and the team). Exactly one A per task. Saved to raci (latest per cell wins).

raci_ui <- function(id) {
  ns <- NS(id)
  tagList(
    card(NULL, selectInput(ns("proj"), "Project", NULL, width = "100%")),
    uiOutput(ns("checks")),
    card("Grid",
      p(class = "small muted", "Double-click a cell and type R, A, C or I (leave empty to clear). ",
        "R = does the work, A = answers for it (one per task), C = asked before, I = told after."),
      DTOutput(ns("grid"))))
}

raci_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    observe({ ch <- project_picker_choices(ctx); updateSelectInput(session, "proj", choices = ch, selected = pick_sel(isolate(input$proj), ch, ctx$handoff$project)) })
    proj <- reactive({ pr <- ctx$data$projects(); pr[pr$project_id == (input$proj %||% ""), , drop = FALSE] })
    tasks <- reactive({ t <- ctx$data$tasks(); t <- t[t$project_id == (input$proj %||% ""), , drop = FALSE]; t[order(t$work_package, t$start_date), , drop = FALSE] })
    people <- reactive({ r <- proj(); req(nrow(r) > 0); project_people(r$programme_id, ctx$data$consortium()) })
    cells <- reactive({ x <- latest_by(ctx$table("raci")(), c("project_id", "task_id", "email")); x[x$project_id == (input$proj %||% ""), , drop = FALSE] })
    grid <- reactive({
      t <- tasks(); pp <- people(); x <- cells()
      if (!nrow(t)) return(data.frame(Task = character(0)))
      g <- data.frame(Task = paste0(substr(t$work_package, 1, 3), " ", t$task), stringsAsFactors = FALSE)
      for (e in pp) g[[e]] <- vapply(t$task_id, function(tid) { v <- x$letter[x$task_id == tid & x$email == e]; if (length(v)) v else "" }, "")
      g
    })
    output$checks <- renderUI({
      if (!length(project_picker_choices(ctx))) return(project_empty_note())
      t <- tasks(); req(nrow(t) > 0); g <- grid()
      if (ncol(g) < 2) return(note("warn", "Nobody to assign yet. Add people to the bid's consortium (3 Team up > Consortium)."))
      nA <- apply(g[, -1, drop = FALSE], 1, function(r) sum(r == "A")); nR <- apply(g[, -1, drop = FALSE], 1, function(r) sum(r == "R"))
      bad <- c(if (any(nA != 1)) paste0(sum(nA != 1), " task(s) without exactly one A: ", paste(utils::head(g$Task[nA != 1], 5), collapse = "; ")),
               if (any(nR == 0)) paste0(sum(nR == 0), " task(s) with no R."))
      if (length(bad)) note("warn", paste(bad, collapse = " ")) else note("ok", "Every task has one A and at least one R.")
    })
    output$grid <- renderDT({
      g <- grid(); req(nrow(g) > 0)
      names(g)[-1] <- names(people())[match(names(g)[-1], people())]
      datatable(g, rownames = FALSE, selection = "none", editable = if (ctx$is_partner()) FALSE else list(target = "cell", disable = list(columns = 0)),
                options = list(dom = "t", paging = FALSE, scrollX = TRUE, ordering = FALSE)) |>
        formatStyle(names(g)[-1], backgroundColor = styleEqual(c("A", "R", "C", "I"), c("#0f4a5c", "#1a9aa8", "#cfe9ec", "#eef5f7")),
                    color = styleEqual(c("A", "R"), c("#fff", "#fff")), textAlign = "center", fontWeight = "bold")
    })
    observeEvent(input$grid_cell_edit, {
      req(!ctx$is_partner()); e <- input$grid_cell_edit
      v <- toupper(trimws(e$value)); if (!v %in% c("R", "A", "C", "I", "")) return(showNotification("Use R, A, C or I.", type = "warning"))
      t <- tasks(); email <- people()[e$col]
      store_append("raci", data.frame(project_id = input$proj, task_id = t$task_id[e$row], email = email, letter = v,
                                      updated_at = now_ts(), stringsAsFactors = FALSE), user = ctx$user(), log = FALSE)
      ctx$bump()
    })
  })
}
