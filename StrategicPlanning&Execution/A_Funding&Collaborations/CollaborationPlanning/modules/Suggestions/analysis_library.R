# ---- module ----------------------------------------------
# id:           analysis_library
# name:         Analysis library
# icon:         layer-group
# description:  The analysis tables you can see, filed by country, category, topic and programme; the owner sees all, classifies them and syncs with Google Drive
# packages:     shiny
# -----------------------------------------------------------
# Access: an analysis is listed for the owner and for each email in its access list (R/analysis.R can_see_analysis()).

analysis_library_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("owner_bar")),
    layout_columns(col_widths = c(4, 8),
      card("Country > Category > Topic > Programme",
        div(class = "btn-row", textInput(ns("q"), NULL, placeholder = "Search titles, topics and tables", width = "100%"),
            actionButton(ns("refresh"), NULL, icon = icon("rotate"), class = "btn-ghost sm", title = "Check for newly shared analyses")),
        uiOutput(ns("tree"))),
      uiOutput(ns("view"))))
}

analysis_library_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    picked <- reactiveVal("")
    visible <- reactive({
      a <- latest_analyses(ctx$table("analyses")())
      a <- a[can_see_analysis(a, ctx$user(), ctx$is_owner()), , drop = FALSE]
      q <- tolower(trimws(input$q %||% ""))
      if (nzchar(q)) a <- a[grepl(q, tolower(paste(a$title, a$summary, a$country, a$category, a$topic, a$programme, a$tables_json)), fixed = TRUE), , drop = FALSE]
      a
    })
    output$tree <- renderUI({
      a <- visible()
      if (!nrow(a)) return(p(class = "small muted", if (ctx$is_owner()) "No analyses yet. Run one in Analysis workbench."
                                                    else "Nothing shared with you yet. Suggest a programme or an idea in My suggestions."))
      analysis_tree(a, ns("pick"), picked())
    })
    observeEvent(input$pick, picked(input$pick))
    observeEvent(input$refresh, { store_clear_cache("analyses"); ctx$bump() })
    observeEvent(ctx$handoff$analysis, picked(ctx$handoff$analysis), ignoreNULL = TRUE)
    sel <- reactive({ a <- visible(); a[a$analysis_id == picked(), , drop = FALSE] })

    output$view <- renderUI({
      a <- sel()
      if (!nrow(a)) return(card(NULL, p(class = "muted", "Choose a programme in the tree to see its tables.")))
      s <- latest_suggestions(ctx$table("suggestions")()); s <- s[s$suggestion_id == a$suggestion_id, , drop = FALSE]
      tagList(
        card(a$title,
          p(class = "small muted", paste(level_value(c(a$country, a$category, a$topic, a$programme %|% a$title)), collapse = "  >  ")),
          if (nzchar(a$summary)) p(a$summary),
          if (nrow(s) && (ctx$is_owner() || tolower(s$created_by) == tolower(ctx$user())))
            p(class = "small", tags$b("Suggested by "), s$created_by, if (nzchar(s$url)) tagList(". ", tags$a(href = s$url, target = "_blank", rel = "noopener", "More information"))),
          render_tables(tables_from_json(a$tables_json)),
          div(class = "btn-row", downloadButton(ns("dl"), "Download (.html)", class = "btn-ghost sm"),
              if (nzchar(a$drive_synced_at)) span(class = "small muted", icon("cloud"), " On Google Drive since ", substr(a$drive_synced_at, 1, 16), ": ", a$drive_path))),
        if (ctx$is_owner()) card("Classify and share (owner)",
          do.call(layout_columns, c(list(col_widths = c(3, 3, 3, 3)), lapply(names(HIERARCHY), function(k) {
            all <- latest_analyses(ctx$table("analyses")())
            selectizeInput(ns(paste0("c_", k)), HIERARCHY[[k]], choices = sort(unique(c(all[[k]][nzchar(all[[k]])], a[[k]]))), selected = a[[k]],
                           options = list(create = TRUE, placeholder = "Type or choose"))
          }))),
          selectizeInput(ns("access"), "Who can see it", choices = sort(unique(c("everyone", tolower(get_users()$email), split_emails(a$access_emails)))),
                         selected = split_emails(a$access_emails), multiple = TRUE, width = "100%", options = list(create = TRUE)),
          div(class = "btn-row", actionButton(ns("save"), "Save", class = "btn-brand"),
              actionButton(ns("open_wb"), "Open in the workbench", class = "btn-ghost"),
              actionButton(ns("del"), "Delete", class = "btn-ghost", icon = icon("trash")))))
    })
    output$dl <- downloadHandler(filename = function() paste0(safe_name(sel()$title), ".html"),
                                 content = function(file) writeLines(enc2utf8(analysis_html(sel())), file, useBytes = TRUE))
    observeEvent(input$save, {
      a <- sel(); req(nrow(a) > 0, ctx$is_owner())
      s <- latest_suggestions(ctx$table("suggestions")()); creator <- s$created_by[s$suggestion_id == a$suggestion_id]
      for (k in names(HIERARCHY)) a[[k]] <- input[[paste0("c_", k)]] %||% ""
      a$access_emails <- paste(unique(c(tolower(creator), split_emails(input$access))), collapse = ", "); a$updated_at <- now_ts()
      store_append("analyses", a, user = ctx$user()); ctx$bump()
      showNotification(if (nzchar(a$drive_synced_at)) "Saved. Upload again to move the Drive copy to its new folder." else "Saved.", type = "message")
    })
    observeEvent(input$del, { a <- sel(); req(nrow(a) > 0, ctx$is_owner()); a$deleted <- "TRUE"; a$updated_at <- now_ts()
      store_append("analyses", a, user = ctx$user()); picked(""); ctx$bump() })
    observeEvent(input$open_wb, { a <- sel(); req(nrow(a) > 0); ctx$handoff$suggestion <- a$suggestion_id; ctx$nav("suggest", "analysis_workbench") })

    # ---- owner: Google Drive ----
    output$owner_bar <- renderUI({
      req(ctx$is_owner()); s <- ctx$settings()
      card(NULL, div(class = "btn-row",
        span(icon("cloud"), " Google Drive: ", tags$b(switch(drive_mode(s), api = "Drive API", folder = "synced folder", "not set up")),
             if (!drive_ready(s)) span(class = "small muted", " (Admin > Google Drive)")),
        if (drive_ready(s)) actionButton(ns("push_all"), "Upload all to Drive", class = "btn-ghost sm", icon = icon("cloud-arrow-up")),
        if (drive_ready(s)) actionButton(ns("pull"), "Pull back from Drive", class = "btn-brand sm", icon = icon("cloud-arrow-down"))),
        uiOutput(ns("sync_status")))
    })
    observeEvent(input$push_all, {
      req(ctx$is_owner()); a <- latest_analyses(ctx$table("analyses")()); done <- 0; err <- character(0)
      withProgress(message = "Uploading to Google Drive...", value = 0, for (i in seq_len(nrow(a))) {
        r <- tryCatch(drive_save_analysis(a[i, , drop = FALSE], ctx$settings()), error = function(e) list(error = safe_error_text(e)))
        if (!is.null(r$error)) err <- c(err, r$error) else {
          row <- a[i, , drop = FALSE]; row$drive_id <- r$id; row$drive_path <- r$path; row$drive_synced_at <- now_ts()
          store_append("analyses", row, user = ctx$user(), log = FALSE); done <- done + 1 }
        incProgress(1 / nrow(a))
      })
      log_change(ctx$user(), "drive-upload", "analyses", sprintf("%d uploaded", done)); ctx$bump()
      output$sync_status <- renderUI(note(if (length(err)) "warn" else "ok", sprintf("Uploaded %d of %d.", done, nrow(a)), if (length(err)) paste(" First problem:", err[1])))
    })
    observeEvent(input$pull, {
      req(ctx$is_owner())
      d <- withProgress(message = "Reading from Google Drive...", tryCatch(drive_pull_analyses(ctx$settings()), error = function(e) structure(safe_error_text(e), class = "err")))
      if (inherits(d, "err")) return(output$sync_status <- renderUI(note("bad", d)))
      have <- latest_by(store_read("analyses", fresh = TRUE), "analysis_id")
      # a Drive copy is taken when the app does not have it, or the copy is newer (edited on Drive or in another copy of the app)
      newer <- vapply(seq_len(nrow(d)), function(i) { h <- have[have$analysis_id == d$analysis_id[i], , drop = FALSE]
        !nrow(h) || d$updated_at[i] > h$updated_at[1] }, TRUE)
      if (any(newer)) { d2 <- d[newer, , drop = FALSE]; d2$drive_synced_at <- now_ts(); store_append("analyses", d2, user = ctx$user()) }
      ctx$bump()
      output$sync_status <- renderUI(note("ok", sprintf("Found %d analysis file(s) on Drive; %d new or newer brought into the app.", nrow(d), sum(newer))))
    })
  })
}
