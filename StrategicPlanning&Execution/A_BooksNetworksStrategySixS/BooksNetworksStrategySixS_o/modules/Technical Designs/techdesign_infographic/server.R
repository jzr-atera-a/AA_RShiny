# modules/Technical Designs/techdesign_infographic/server.R

techdesign_infographic_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    current <- reactiveVal(NULL)
    editing_id <- reactiveVal(NULL)
    want_sel <- reactiveVal(NULL)    # design_id to select in the Saved Infographics list after a save
    last_fmt <- reactiveVal("")

    set_status <- function(cls, icon_cls, msg, extra = NULL) {
      output$status <- renderUI(tags$div(class = cls, style = "margin-top:10px;", tags$i(class = icon_cls), " ", msg, extra))
    }
    layout_notes <- reactiveVal(character(0))
    warn_ui <- function(d) { w <- unique(c(d$warnings, layout_notes())); if (length(w) == 0) NULL else tags$ul(style = "margin-top:6px;", lapply(w, tags$li)) }
    summary_msg <- function(d) {
      cnt <- ig_evidence_counts(d)
      fmt <- ig_format_id(d$meta$format)
      sprintf("%d sections, %s, theme '%s'. Evidence: %d verified, %d unverified, %d contradicted, %d from your facts, %d judgment, %d source(s).",
              length(d$sections), if (identical(fmt, "poster")) "long poster" else sprintf("%s %s of %d slide(s)", IG_FORMATS[[fmt]]$short, if (identical(d$meta$layout, "dashboard")) "dashboard deck" else if (identical(d$meta$layout, "flow")) "flow deck" else "deck", length(layout_pages())), d$meta$theme, cnt[["verified"]], cnt[["unverified"]], cnt[["contradicted"]], cnt[["applicant"]], cnt[["judgment"]], nrow(d$sources))
    }
    layout_pages <- reactiveVal(list())
    sync_layout_inputs <- function(d) {
      fmt <- ig_format_id(d$meta$format)
      if (!identical(input$format %||% "poster", fmt)) updateSelectInput(session, "format", selected = fmt)
      if (!is.null(d$meta$slides) && !identical(as.integer(input$n_slides %||% 4L), as.integer(d$meta$slides))) updateSliderInput(session, "n_slides", value = d$meta$slides)
      if (!identical(input$layout %||% "dashboard", d$meta$layout)) updateSelectInput(session, "layout", selected = d$meta$layout)
      if (!identical(as.integer(input$panels %||% 4L), as.integer(d$meta$panels))) updateSliderInput(session, "panels", value = max(2L, d$meta$panels))
      if (!identical(input$cover %||% "auto", d$meta$cover)) updateSelectInput(session, "cover", selected = d$meta$cover)
      if (!identical(input$text_size %||% "normal", d$meta$text_size)) updateSelectInput(session, "text_size", selected = d$meta$text_size)
      updateTextAreaInput(session, "facts", value = d$meta$facts %||% ""); updateTextAreaInput(session, "requirements", value = d$meta$requirements %||% "")
      pal <- d$meta$palette %||% list()
      for (k in c("navy", "teal", "magenta", "ochre")) updateTextInput(session, paste0("pal_", k), value = pal[[k]] %||% "")
    }
    palette_in <- function() {
      p <- list(navy = ig_hex(input$pal_navy), teal = ig_hex(input$pal_teal), magenta = ig_hex(input$pal_magenta), ochre = ig_hex(input$pal_ochre))
      if (all(nzchar(unlist(p)))) p else list()
    }
    output$pal_swatch <- renderUI({
      cols <- c(input$pal_navy, input$pal_teal, input$pal_magenta, input$pal_ochre); ok <- vapply(cols, function(x) nzchar(ig_hex(x)), TRUE)
      if (!any(ok)) return(NULL)
      tags$div(style = "margin-bottom:8px;", lapply(seq_along(cols), function(i) tags$span(style = sprintf("display:inline-block;width:36px;height:18px;border-radius:4px;margin-right:6px;border:1px solid #ccc;background:%s;", if (ok[i]) ig_hex(cols[i]) else "#fff"))))
    })
    observe({
      has <- length(palette_in()) > 0; cur <- isolate(input$theme %||% "auto")
      ch <- c("Let the Editing Tool choose" = "auto", if (has) c("Your brand colours" = "custom"), IG_THEME_CHOICES[IG_THEME_CHOICES != "custom"])
      updateSelectInput(session, "theme", choices = ch, selected = if (cur == "custom" && !has) "auto" else cur)
    })
    draw <- function(d) {
      current(d)
      lay <- tryCatch(ig_layout(d), error = function(e) { showNotification(paste("Layout problem:", e$message), type = "error"); NULL })
      if (is.null(lay)) return(invisible(NULL))
      layout_pages(lay$pages); layout_notes(lay$notes)
      fm <- ig_format_id(d$meta$format)
      if (!identical(fm, isolate(last_fmt()))) { last_fmt(fm); session$sendCustomMessage("ig_export_default", list(id = session$ns("ig_format"), fmt = fm)) }
      output$diagram <- renderUI(export_capture_wrapper(session$ns, render_infographic(d, lay), d$meta$title %||% "infographic"))
      output$facts <- DT::renderDataTable(DT::datatable(ig_facts_table(d), rownames = FALSE, filter = "top", options = list(pageLength = 15, scrollX = TRUE)))
    }
    show_text <- function(d) updateTextAreaInput(session, "gen_text", value = infographic_to_text(d))

    load_seed <- function(path) {
      d <- parse_infographic_text(paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n"))
      editing_id(NULL); show_text(d); draw(d); sync_layout_inputs(d)
      updateSelectInput(session, "theme", selected = d$meta$theme)
      set_status("status-info", "fa fa-info-circle", paste("Example loaded (illustrative figures, no sources).", summary_msg(d)), warn_ui(d))
    }
    observeEvent(TRUE, {
      f <- ig_seed_files()   # start on the Illustrated flow example so the style box shows the default (Flow)
      if (length(f) > 0) { fl <- f[grepl("flow", basename(f), ignore.case = TRUE)]; tryCatch(load_seed(if (length(fl)) fl[[1]] else f[[1]]), error = function(e) NULL) }
    }, once = TRUE)
    observeEvent(input$load_seed, {
      sd <- input$seed %||% ""
      if (!nzchar(sd) || !file.exists(sd)) { showNotification("No example selected.", type = "warning"); return() }
      tryCatch(load_seed(sd), error = function(e) showNotification(paste("Could not load the example:", e$message), type = "error"))
    })

    # live theme switch (no API call)
    observeEvent(input$theme, {
      d <- current(); th <- input$theme %||% "auto"
      if (is.null(d) || identical(th, "auto") || identical(th, d$meta$theme)) return()
      if (identical(th, "custom")) { p <- palette_in(); if (length(p) == 0) return(); d$meta$palette <- p }
      d$meta$theme <- th; show_text(d); draw(d)
    }, ignoreInit = TRUE)
    observeEvent(list(input$pal_navy, input$pal_teal, input$pal_magenta, input$pal_ochre), {
      d <- current(); p <- palette_in(); if (is.null(d) || length(p) == 0 || !identical(d$meta$theme, "custom") || identical(d$meta$palette, p)) return()
      d$meta$palette <- p; show_text(d); draw(d)
    }, ignoreInit = TRUE)

    # live page-format / slide-count switch (no API call): the same sections are re-flowed onto the new pages
    observeEvent(list(input$format, input$n_slides, input$layout, input$panels, input$cover, input$text_size), {
      d <- current(); if (is.null(d)) return()
      fmt <- ig_format_id(input$format); sl <- ig_slides_n(input$n_slides)
      ly <- if (is.null(input$layout)) d$meta$layout else if (input$layout %in% c("stacked", "flow", "dashboard")) input$layout else "stacked"; pn <- as.integer(input$panels %||% d$meta$panels); cv <- input$cover %||% d$meta$cover; ts <- input$text_size %||% d$meta$text_size
      if (identical(fmt, ig_format_id(d$meta$format)) && identical(sl, ig_slides_n(d$meta$slides)) && identical(ly, d$meta$layout) && identical(pn, as.integer(d$meta$panels)) && identical(cv, d$meta$cover) && identical(ts, d$meta$text_size)) return()
      d$meta$format <- fmt; d$meta$slides <- sl; d$meta$layout <- ly; d$meta$panels <- pn; d$meta$cover <- cv; d$meta$text_size <- ts; show_text(d); draw(d)
      set_status(if (length(layout_notes()) > 0) "status-warning" else "status-info", "fa fa-th-large", summary_msg(d), warn_ui(d))
    }, ignoreInit = TRUE)

    observeEvent(input$generate, {
      if (!api_manager$claude_authenticated) { showNotification("Please configure and save Editing Tool API credentials first!", type = "error", duration = 10); return() }
      topic <- trimws(input$topic %||% "")
      if (nchar(topic) < 10) { showNotification("Please describe the topic (at least a sentence).", type = "warning"); return() }
      if (length(input$types %||% character(0)) == 0) { showNotification("Select at least one block type.", type = "warning"); return() }
      editing_id(NULL)
      tryCatch({
        d <- withProgress(message = "Generating infographic", value = 0.1, {
          ig_run_pipeline(api_manager, topic, n_sections = input$n_sections %||% 8, format = input$format %||% "poster", slides = input$n_slides %||% 4L, allowed = input$types, theme = input$theme %||% "auto",
                          research = identical(input$research, "web"), max_uses = input$max_uses %||% 4, verify = isTRUE(input$verify), extra = input$extra %||% "",
                          layout = input$layout %||% "stacked", panels = input$panels %||% 4L, cover = input$cover %||% "auto", text_size = input$text_size %||% "normal", palette = palette_in(),
                          facts = input$facts %||% "", requirements = input$requirements %||% "",
                          progress = function(m) { cat("[Infographic]", m, "\n"); setProgress(detail = m) })
        })
        show_text(d); draw(d); updateSelectInput(session, "theme", selected = d$meta$theme)
        set_status(if (length(d$warnings) > 0 || length(layout_notes()) > 0) "status-warning" else "status-success", "fa fa-check-circle", paste(summary_msg(d), "Review it, download it, or 'Save to BigQuery'."), warn_ui(d))
      }, error = function(e) {
        set_status("status-error", "fa fa-times-circle", paste("Failed:", e$message))
        showNotification(paste("Error:", e$message), type = "error", duration = 12)
      })
    })

    observeEvent(input$preview, {
      if (nchar(trimws(input$gen_text %||% "")) == 0) { showNotification("The text box is empty.", type = "warning"); return() }
      tryCatch({ d <- parse_infographic_text(input$gen_text); draw(d); sync_layout_inputs(d); set_status("status-success", "fa fa-check-circle", summary_msg(d), warn_ui(d)) },
               error = function(e) set_status("status-error", "fa fa-times-circle", paste("Parse problem:", e$message)))
    })

    observeEvent(input$save, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }
      if (nchar(trimws(input$gen_text %||% "")) == 0) { showNotification("Nothing to save - generate an infographic first.", type = "warning"); return() }
      tryCatch({
        d <- parse_infographic_text(input$gen_text); eid <- editing_id(); did <- eid %||% generate_new_design_id(IG_GROUP)
        api_manager$bq_insert_techdesign(ig_to_row(d, did, d$meta$title, change_type = if (is.null(eid)) "create" else "update"))
        editing_id(did); draw(d); want_sel(did)
        set_status("status-success", "fa fa-check-circle", sprintf("Saved '%s' (design_id: %s). It is now selected in the Saved Infographics list below.", d$meta$title, did), warn_ui(d))
        showNotification("Infographic saved to BigQuery", type = "message")
      }, error = function(e) { set_status("status-error", "fa fa-times-circle", paste("Save failed:", e$message)); showNotification(paste("Error:", e$message), type = "error", duration = 12) })
    })

    output$dl_json <- downloadHandler(filename = function() paste0("infographic_", format(Sys.Date(), "%Y%m%d"), ".json"),
                                      content = function(file) writeLines(input$gen_text %||% "", file, useBytes = TRUE))

    saved_list <- reactive({
      api_manager$state_trigger_techdesign(); input$refresh
      if (!api_manager$bq_authenticated) return(data.frame())
      api_manager$bq_get_techdesign_list(IG_GROUP)
    })
    observe({
      lst <- saved_list()
      if (nrow(lst) == 0) { updateSelectInput(session, "saved_id", choices = c("(none saved yet)" = "")); return() }
      lbl <- sprintf("%s  [%s]", lst$title, format(lst$created_at, "%Y-%m-%d %H:%M")); cur <- isolate(input$saved_id)
      w <- isolate(want_sel())
      sel <- if (!is.null(w) && w %in% lst$design_id) w else if (!is.null(cur) && cur %in% lst$design_id) cur else lst$design_id[1]
      if (!is.null(w)) want_sel(NULL)
      updateSelectInput(session, "saved_id", choices = setNames(lst$design_id, lbl), selected = sel)
    })
    fetch_selected <- function() {
      sid <- input$saved_id %||% ""
      if (!nzchar(sid)) { showNotification("Select a saved infographic first.", type = "warning"); return(NULL) }
      row <- api_manager$bq_get_techdesign(sid)
      if (nrow(row) == 0) { showNotification("Could not load that infographic.", type = "error"); return(NULL) }
      tryCatch(list(design = infographic_from_row(row), id = sid), error = function(e) { showNotification(e$message, type = "error"); NULL })
    }
    observeEvent(input$load_view, {
      sel <- fetch_selected(); if (is.null(sel)) return()
      draw(sel$design); sync_layout_inputs(sel$design); set_status("status-success", "fa fa-check-circle", paste0("Showing saved infographic '", sel$design$meta$title, "'. ", summary_msg(sel$design)))
    })
    observeEvent(input$load_edit, {
      sel <- fetch_selected(); if (is.null(sel)) return()
      show_text(sel$design); editing_id(sel$id); draw(sel$design); sync_layout_inputs(sel$design)
      set_status("status-info", "fa fa-info-circle", "Loaded into the editor. Saving now adds a NEW VERSION of this same infographic.")
    })
    observeEvent(input$delete, {
      if (!nzchar(input$saved_id %||% "")) { showNotification("Select a saved infographic first.", type = "warning"); return() }
      showModal(modalDialog(title = "Delete this infographic?", "It will be hidden from the lists (a 'delete' version is appended; nothing is physically removed from BigQuery).",
                            footer = tagList(modalButton("Cancel"), actionButton(session$ns("confirm_delete"), "Delete", class = "btn-danger"))))
    })
    observeEvent(input$confirm_delete, {
      removeModal(); row <- api_manager$bq_get_techdesign(input$saved_id %||% ""); if (nrow(row) == 0) return()
      row$change_type <- "delete"; row$id <- NULL; row$created_at <- NULL
      tryCatch({ api_manager$bq_insert_techdesign(row); showNotification("Infographic deleted.", type = "message") }, error = function(e) showNotification(paste("Error:", e$message), type = "error"))
    })

    output$status <- renderUI(tags$div())
    output$diagram <- renderUI(tags$div(class = "status-info", "Generate or load an infographic to see it here."))
  })
}
