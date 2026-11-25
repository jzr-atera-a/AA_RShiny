# ---- module ----------------------------------------------
# id:           admin_analytics
# name:         Usage analytics
# icon:         chart-pie
# description:  Owner only: each person's contributions, sign-ins and activity over time, with copies saved to Google Drive
# packages:     shiny, plotly, DT
# -----------------------------------------------------------
# Contributions are counted from the author column of each table (one row = one saved contribution), so they
# include changes the change log does not record (votes, drafts, task edits). Sign-ins come from login_log.

# table -> list(user column, time column, label)
CONTRIB_SOURCES <- list(
  programmes = c("added_by", "added_at", "Programmes added"),
  suggestions = c("created_by", "updated_at", "Suggestions"),
  analyses = c("created_by", "updated_at", "Claude analyses"),
  eligibility = c("checked_by", "checked_at", "Eligibility checks"),
  priorities = c("email", "updated_at", "Fit scores"),
  gonogo = c("updated_by", "updated_at", "Go/no-go trees"),
  people = c("added_by", "updated_at", "Contacts"),
  consortium = c("updated_by", "updated_at", "Consortium updates"),
  messages = c("created_by", "created_at", "Messages"),
  decisions = c("created_by", "created_at", "Decisions opened"),
  decision_inputs = c("email", "updated_at", "Decision views"),
  ideas = c("created_by", "created_at", "Ideas"),
  idea_votes = c("email", "updated_at", "Idea votes"),
  tasks = c("updated_by", "updated_at", "Task edits"),
  risks = c("updated_by", "updated_at", "Risks"),
  budget = c("updated_by", "updated_at", "Budget lines"),
  answers = c("updated_by", "updated_at", "Answer drafts"),
  canvases = c("created_by", "created_at", "Canvases"),
  weekly = c("email", "updated_at", "Weekly updates"),
  milestones = c("updated_by", "updated_at", "Milestones"),
  outcomes = c("recorded_by", "recorded_at", "Outcomes"),
  question_sets = c("added_by", "added_at", "Question sets"),
  collab_ideas = c("created_by", "updated_at", "Collaboration ideas"),
  collab_notes = c("email", "created_at", "Notes on ideas"))

contributions_long <- function() {
  rows <- lapply(names(CONTRIB_SOURCES), function(t) {
    src <- CONTRIB_SOURCES[[t]]; d <- store_read(t)
    if (!nrow(d) || !all(src[1:2] %in% names(d))) return(NULL)
    u <- tolower(trimws(d[[src[1]]])); keep <- valid_email(u)
    if (!any(keep)) return(NULL)
    data.frame(user = u[keep], area = src[3], when = substr(d[[src[2]]][keep], 1, 10), stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, Filter(Negate(is.null), rows))
  if (is.null(out)) data.frame(user = character(0), area = character(0), when = character(0)) else out
}

admin_analytics_ui <- function(id) {
  ns <- NS(id)
  tagList(
    card(NULL, layout_columns(col_widths = c(4, 4, 4),
      dateRangeInput(ns("dates"), "Between", start = Sys.Date() - 90, end = Sys.Date(), weekstart = 1),
      selectInput(ns("who"), "Person", "All", width = "100%"),
      div(class = "align-bottom btn-row",
          actionButton(ns("refresh"), "Refresh", class = "btn-ghost sm", icon = icon("rotate")),
          downloadButton(ns("dl"), "Download (.csv)", class = "btn-ghost sm"))),
      uiOutput(ns("kpis"))),
    layout_columns(col_widths = c(7, 5),
      card("Contributions by person", plotlyOutput(ns("by_user"), height = "380px")),
      card("Sign-ins by person", plotlyOutput(ns("logins"), height = "380px"))),
    card("Activity by week", plotlyOutput(ns("timeline"), height = "300px")),
    card("People", DTOutput(ns("people"))),
    card("Sign-in log (latest first, including refused emails)", DTOutput(ns("loglist"))),
    card("Google Drive",
      p(class = "small muted", "Saves this page's numbers (people summary, contributions, sign-in log) to ",
        tags$code("Analytics/<date>/"), ", and can copy every table of the app to ", tags$code("Backups/<date>/"), "."),
      div(class = "btn-row",
          actionButton(ns("to_drive"), "Save analytics to Google Drive", class = "btn-brand", icon = icon("cloud-arrow-up")),
          actionButton(ns("backup"), "Back up all tables to Google Drive", class = "btn-ghost", icon = icon("box-archive"))),
      uiOutput(ns("drive_status"))))
}

admin_analytics_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    observeEvent(input$refresh, { store_clear_cache(); ctx$bump() })
    users <- reactive({ u <- ctx$data$users(); u$email <- tolower(trimws(u$email)); u })
    logins <- reactive({ l <- ctx$data$login_log(); l$email <- tolower(trimws(l$email)); l$day <- substr(l$timestamp, 1, 10); l })
    contrib <- reactive({ ctx$tick(); input$refresh; contributions_long() })
    observe({ u <- users(); ch <- c("All", sort(unique(c(u$email, contrib()$user))))
              updateSelectInput(session, "who", choices = ch, selected = pick_sel(isolate(input$who), ch)) })
    in_range <- function(day) { d <- suppressWarnings(as.Date(day)); !is.na(d) & d >= input$dates[1] & d <= input$dates[2] }
    who_ok <- function(u) identical(input$who %||% "All", "All") | u == input$who
    c_f <- reactive({ req(input$dates); c <- contrib(); c[in_range(c$when) & who_ok(c$user), , drop = FALSE] })
    l_f <- reactive({ req(input$dates); l <- logins(); l[in_range(l$day) & who_ok(l$email), , drop = FALSE] })

    summary_df <- reactive({
      req(ctx$is_owner()); u <- users(); call <- contrib(); lall <- logins(); c <- c_f(); l <- l_f()
      emails <- sort(unique(c(u$email, c$user, l$email[is_true_vec(l$success)])))
      emails <- emails[valid_email(emails) & (identical(input$who %||% "All", "All") | emails == input$who)]
      cnt <- function(df, e, area = NULL) sum(df$user == e & (is.null(area) | df$area %in% area))
      data.frame(
        Email = emails, Name = u$name[match(emails, u$email)] %|% "", Role = u$role[match(emails, u$email)] %|% "(not on the list)",
        `Sign-ins` = vapply(emails, function(e) sum(l$email == e & is_true_vec(l$success)), 1L),
        `Refused` = vapply(emails, function(e) sum(l$email == e & !is_true_vec(l$success)), 1L),
        `Last sign-in` = vapply(emails, function(e) { x <- lall$timestamp[lall$email == e & is_true_vec(lall$success)]; if (length(x)) max(x) else "" }, ""),
        Contributions = vapply(emails, function(e) cnt(c, e), 1L),
        Suggestions = vapply(emails, function(e) cnt(c, e, "Suggestions"), 1L),
        Analyses = vapply(emails, function(e) cnt(c, e, "Claude analyses"), 1L),
        `Decision views` = vapply(emails, function(e) cnt(c, e, "Decision views"), 1L),
        `Ideas and votes` = vapply(emails, function(e) cnt(c, e, c("Ideas", "Idea votes")), 1L),
        `Last contribution` = vapply(emails, function(e) { x <- call$when[call$user == e]; if (length(x)) max(x) else "" }, ""),
        check.names = FALSE, row.names = NULL, stringsAsFactors = FALSE)
    })

    output$kpis <- renderUI({
      req(ctx$is_owner()); c <- c_f(); l <- l_f(); ok <- is_true_vec(l$success)
      stat <- function(n, lab) div(class = "stat", div(class = "stat-n", n), div(class = "stat-l", lab))
      div(class = "stat-row",
          stat(length(unique(l$email[ok])), "people signed in"), stat(sum(ok), "sign-ins"), stat(sum(!ok), "refused sign-ins"),
          stat(nrow(c), "contributions"), stat(sum(c$area == "Suggestions"), "suggestions"), stat(sum(c$area == "Claude analyses"), "analyses"))
    })
    output$by_user <- renderPlotly({
      c <- c_f(); req(nrow(c) > 0)
      tot <- sort(table(c$user)); c$user <- factor(c$user, levels = names(tot))
      t <- as.data.frame(table(user = c$user, area = c$area), stringsAsFactors = FALSE); t <- t[t$Freq > 0, , drop = FALSE]
      pal <- rep(c("#0f4a5c", "#1a9aa8", "#22c3d6", "#e3a21a", "#2f9e6e", "#d6336c", "#6b7c88", "#0b2a3c", "#8fd3dc", "#b78512"), 3)
      areas <- sort(unique(t$area))
      plot_ly(t, y = ~user, x = ~Freq, color = ~area, colors = setNames(pal[seq_along(areas)], areas), type = "bar", orientation = "h", hovertemplate = "%{y}<br>%{fullData.name}: %{x}<extra></extra>") |>
        layout(barmode = "stack", xaxis = list(title = "Contributions"), yaxis = list(title = "", categoryorder = "array", categoryarray = names(tot)),
               legend = list(orientation = "h", y = -0.2), margin = list(l = 10)) |> config(displayModeBar = FALSE)
    })
    output$logins <- renderPlotly({
      l <- l_f(); req(nrow(l) > 0)
      l$result <- ifelse(is_true_vec(l$success), "Signed in", "Refused")
      t <- as.data.frame(table(email = l$email, result = l$result), stringsAsFactors = FALSE); t <- t[t$Freq > 0, , drop = FALSE]
      plot_ly(t, y = ~email, x = ~Freq, color = ~result, colors = c("Refused" = "#d6336c", "Signed in" = "#1a9aa8"), type = "bar", orientation = "h") |>
        layout(barmode = "stack", xaxis = list(title = "Sign-in attempts"), yaxis = list(title = ""), legend = list(orientation = "h", y = -0.2)) |>
        config(displayModeBar = FALSE)
    })
    output$timeline <- renderPlotly({
      c <- c_f(); l <- l_f()[is_true_vec(l_f()$success), , drop = FALSE]; req(nrow(c) + nrow(l) > 0)
      wk <- function(d) { d <- as.Date(d); format(d - (as.integer(format(d, "%u")) - 1)) }
      weeks <- sort(unique(c(wk(c$when), wk(l$day))))
      d <- data.frame(week = weeks, Contributions = vapply(weeks, function(w) sum(wk(c$when) == w), 1L),
                      `Sign-ins` = vapply(weeks, function(w) sum(wk(l$day) == w), 1L), check.names = FALSE)
      plot_ly(d, x = ~week) |> add_lines(y = ~Contributions, name = "Contributions", line = list(color = "#0f4a5c", width = 3)) |>
        add_lines(y = ~`Sign-ins`, name = "Sign-ins", line = list(color = "#1a9aa8", dash = "dot")) |>
        layout(xaxis = list(title = "Week starting"), yaxis = list(title = ""), legend = list(orientation = "h")) |> config(displayModeBar = FALSE)
    })
    output$people <- renderDT(datatable(summary_df(), rownames = FALSE, options = list(dom = "ftip", pageLength = 15, scrollX = TRUE, order = list(list(6, "desc")))))
    output$loglist <- renderDT({
      l <- l_f(); l <- l[order(l$timestamp, decreasing = TRUE), , drop = FALSE]
      datatable(data.frame(When = l$timestamp, Email = l$email, Result = ifelse(is_true_vec(l$success), "signed in", "refused"), Detail = l$detail),
                rownames = FALSE, options = list(dom = "ftip", pageLength = 10)) |>
        formatStyle("Result", color = styleEqual("refused", "#d6336c"), fontWeight = "bold")
    })
    output$dl <- downloadHandler(filename = function() paste0("usage_analytics_", format(Sys.Date(), "%Y%m%d"), ".csv"),
                                 content = function(file) writeLines(csv_text(summary_df()), file, sep = "", useBytes = TRUE))

    observeEvent(input$to_drive, {
      req(ctx$is_owner())
      r <- tryCatch({
        s <- ctx$settings(); day <- format(Sys.Date()); tag <- paste0(format(input$dates[1]), "_to_", format(input$dates[2]))
        drive_save_file(c("Analytics", day), paste0("people_", tag, ".csv"), csv_text(summary_df()), "text/csv", s)
        drive_save_file(c("Analytics", day), paste0("contributions_", tag, ".csv"), csv_text(c_f()), "text/csv", s)
        drive_save_file(c("Analytics", day), paste0("sign_ins_", tag, ".csv"), csv_text(l_f()[, c("timestamp", "email", "success", "detail")]), "text/csv", s)
        log_change(ctx$user(), "drive-analytics", "analytics", paste("Analytics", day))
        note("ok", "Saved three files to Google Drive: Analytics/", day, "/")
      }, error = function(e) note("bad", safe_error_text(e)))
      output$drive_status <- renderUI(r)
    })
    observeEvent(input$backup, {
      req(ctx$is_owner())
      r <- withProgress(message = "Copying every table to Google Drive...", tryCatch(drive_backup_tables(ctx$settings(), ctx$user()),
                        error = function(e) list(error = safe_error_text(e))))
      ctx$bump()
      output$drive_status <- renderUI(if (!is.null(r$error)) note("bad", r$error)
        else note(if (length(r$problems)) "warn" else "ok", sprintf("Copied %d of %d tables to %s.", r$saved, r$total, r$folder),
                  if (length(r$problems)) paste(" First problem:", r$problems[1])))
    })
  })
}
