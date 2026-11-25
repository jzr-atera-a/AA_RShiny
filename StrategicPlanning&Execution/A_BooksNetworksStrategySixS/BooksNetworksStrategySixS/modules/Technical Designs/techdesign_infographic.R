# modules/Technical Designs/techdesign_infographic.R
# ---- module --------------------------------------------------------------------------------------
# id:           techdesign_infographic
# name:         Infographic Studio
# icon:         palette
# description:  Rich infographic posters generated with sourced web research, saved to BigQuery, downloadable as PDF, HTML, JPEG, GIF or PNG
# packages:     shiny, shinydashboard, shinyjs, jsonlite, DT
# api_optional: claude, bigquery
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

techdesign_infographic_ui <- function(id) {
  ns <- NS(id)
  seeds <- ig_seed_files()
  tagList(
    fluidRow(
      box(
        title = "Infographic Studio: rich visual posters from a topic", status = "primary", solidHeader = TRUE, width = 12,
        div(class = "alert alert-info",
            tags$strong("How this works:"),
            " describe a topic. The Editing Tool plans the story and picks a block type for each section (big numbers, donut, pencil or bar chart, people pictogram, region tile map, quote cards, branching tree, steps, icon rows and more). ",
            "It researches the figures on the web with quotes and source URLs, the app checks each quote against the cited page, and then draws the whole poster itself from a fixed library of icons and themes. ",
            "Choose a long poster or a deck of slides (16:9, 4:3, 1:1, 4:5, 9:16, A4) and download it as PowerPoint, PDF, HTML, JPEG, PNG or GIF. Each version is stored as one row in the Technical Designs table."),
        textAreaInput(ns("topic"), "What is the infographic about? *", rows = 3, width = "100%",
                      placeholder = "e.g., The future of big data: where it comes from, why it matters, the risks and the opportunities."),
        textInput(ns("extra"), "Extra instructions (optional):", width = "100%", placeholder = "e.g., aimed at city managers; focus on Europe; keep it positive but balanced"),
        fluidRow(
          column(4, selectInput(ns("format"), "Page format:", choices = IG_FORMAT_CHOICES, selected = "poster")),
          column(4, conditionalPanel("input.format == 'poster'", ns = ns, sliderInput(ns("n_sections"), "Number of sections:", min = 4, max = 10, value = 8, step = 1)),
                    conditionalPanel("input.format != 'poster'", ns = ns, sliderInput(ns("n_slides"), "Number of slides / pages:", min = 1, max = 8, value = 4, step = 1))),
          column(4, selectInput(ns("theme"), "Colour theme:", choices = c("Let the Editing Tool choose" = "auto", IG_THEME_CHOICES[IG_THEME_CHOICES != "custom"]), selected = "auto"))
        ),
        fluidRow(
          column(6, radioButtons(ns("research"), "Evidence:", choices = c("Research the web (sourced)" = "web", "Knowledge only (illustrative)" = "knowledge"), selected = "web", inline = TRUE)),
          column(6, numericInput(ns("max_uses"), "Max web searches per section:", value = 4, min = 1, max = 8, step = 1))
        ),
        fluidRow(
          column(4, selectInput(ns("layout"), "Visual style / layout:", choices = c("Illustrated flow: connected, stylised shapes" = "flow", "Dashboard: several panels per slide" = "dashboard", "Stacked: one section per slide or band (classic)" = "stacked"), selected = "flow")),
          column(8, p(style = "color:#7f8c8d;font-size:12px;margin-top:26px;", "Illustrated flow links the sections with one continuous path, ribbon headings, icon orbs and ribbons. Dashboard shows panels on a grid. Stacked is the classic poster / one block per page. (On a long poster, Dashboard behaves like Stacked.)"))),
        conditionalPanel("input.format != 'poster'", ns = ns,
          fluidRow(
            column(3, conditionalPanel("input.layout != 'stacked'", ns = ns, sliderInput(ns("panels"), "Sections per slide:", min = 2, max = 6, value = 4, step = 1))),
            column(3, selectInput(ns("cover"), "Title cover slide:", choices = c("Automatic" = "auto", "Yes (first slide is a cover)" = "yes", "No (content only)" = "no"), selected = "auto")),
            column(3, selectInput(ns("text_size"), "Text size:", choices = c("Small (finer print, room for more detail)" = "small", "Normal" = "normal", "Large (bigger canvas text, fewer details)" = "large"), selected = "normal"))
          )),
        tags$details(style = "margin-bottom:10px;",
          tags$summary(style = "cursor:pointer;font-weight:600;", "Facts, requirements and brand colours (optional, recommended for grant applications)"),
          textAreaInput(ns("facts"), "Facts supplied by you (the Editing Tool may use these numbers as your data and will not invent others):", rows = 5, width = "100%",
                        placeholder = "e.g., Detector mAP 0.87 and precision 0.91 on road imagery (CCAV CAM Pathfinder). Telemetry latency under 200 ms. Kalman tracker proven on Jetson. Drone field tests: not done. SAPIENT validation: not done. Build February 2027, independent trials March 2027."),
          textAreaInput(ns("requirements"), "Requirements the infographic must address (one per line):", rows = 4, width = "100%",
                        placeholder = "e.g., Detect and track two or more drones at once\nPassive sensing, no RF emissions\nSAPIENT (BSI Flex 335) output\nTRL 6 by the end of the project"),
          fluidRow(
            column(3, textInput(ns("pal_navy"), "Brand colour 1 (dark, hex):", placeholder = "#0B2545")),
            column(3, textInput(ns("pal_teal"), "Brand colour 2 (hex):", placeholder = "#13A0AF")),
            column(3, textInput(ns("pal_magenta"), "Brand colour 3 (hex):", placeholder = "#C2185B")),
            column(3, textInput(ns("pal_ochre"), "Brand colour 4 (hex):", placeholder = "#DB9A22"))
          ),
          uiOutput(ns("pal_swatch")),
          p(style = "color:#7f8c8d;font-size:12px;", "Enter all four colours to use them (the theme list then offers 'Your brand colours'). Items taken from your facts show a navy diamond; things the Editing Tool proposes itself are labelled TARGET or SELF-ASSESSED; anything not yet done is shown as [INSERT]. Nothing is invented.")),
        p(style = "color:#7f8c8d;font-size:12px;margin-top:-6px;", "Slide formats (16:9, 4:3, 1:1, 4:5, 9:16, A4) draw each slide as a fixed-size page: a title cover (landscape and square formats, when you ask for 2 or more slides), one section per slide, and the sources on the last slide. ",
          "Dashboard layout puts 2-6 panels (pipelines, zone diagrams, gauges, comparison matrices, readiness scales, timelines, charts) on each slide. You can switch format, layout, panels or slide count at any time without calling the Editing Tool again; the sections are simply re-flowed onto the pages."),
        checkboxGroupInput(ns("types"), "Block types the Editing Tool may use:", choiceNames = unname(IG_TYPE_LABELS[IG_ALL_TYPES]), choiceValues = IG_ALL_TYPES, selected = IG_ALL_TYPES, inline = TRUE),
        checkboxInput(ns("verify"), "Fetch cited pages and check the quotes", value = TRUE),
        p(style = "color:#7f8c8d;font-size:12px;", "Web research makes one call per statistics section (about 20-60 seconds each), plus one to plan and one to write the text sections. Web search must be enabled for your organisation in the Anthropic Console."),
        hr(),
        fluidRow(
          column(3, actionButton(ns("generate"), "Generate Infographic", icon = icon("magic"), class = "btn-primary btn-lg", style = "width: 100%;")),
          column(3, actionButton(ns("preview"), "Re-Parse & Draw", icon = icon("sync"), class = "btn-info btn-lg", style = "width: 100%;")),
          column(3, actionButton(ns("save"), "Save to BigQuery", icon = icon("cloud-upload-alt"), class = "btn-success btn-lg", style = "width: 100%;")),
          column(3, downloadButton(ns("dl_json"), "Download JSON", class = "btn-warning btn-lg", style = "width: 100%;"))
        ),
        br(),
        fluidRow(
          column(6, selectInput(ns("seed"), "Example:", choices = if (length(seeds) > 0) seeds else c("(none)" = ""))),
          column(3, br(), actionButton(ns("load_seed"), "Load Example", icon = icon("folder-open"), style = "width:100%;"))
        ),
        htmlOutput(ns("status"))
      )
    ),
    fluidRow(
      box(title = "Infographic", status = "info", solidHeader = TRUE, width = 12,
          ig_export_ui(ns, ns("export_target"), "infographic"),
          uiOutput(ns("diagram")))
    ),
    fluidRow(
      box(title = "Facts and Evidence", status = "warning", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE,
          p(style = "color:#7f8c8d;font-size:12px;", "Every statistic with its evidence status, metric, date, quote and source ids."),
          DT::dataTableOutput(ns("facts")))
    ),
    fluidRow(
      box(title = "Data (editable JSON)", status = "success", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE,
          p(style = "color:#7f8c8d;font-size:12px;", "Edit any heading, number, label, icon name or theme, then click 'Re-Parse & Draw'. 'Save' stores exactly what is in this box; if you loaded a saved infographic, saving adds a NEW VERSION of it. ",
            "Icon names must come from the built-in library (", paste(IG_ICON_NAMES, collapse = ", "), "); unknown names fall back to a star."),
          textAreaInput(ns("gen_text"), NULL, rows = 18, width = "100%", placeholder = "The infographic JSON will appear here."))
    ),
    fluidRow(
      box(title = "Saved Infographics", status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE,
          fluidRow(column(12, selectInput(ns("saved_id"), "Saved infographic:", choices = c("(none saved yet)" = ""), width = "100%"))),
          fluidRow(
            column(3, actionButton(ns("load_view"), "Show Infographic", icon = icon("eye"), class = "btn-primary", style = "width: 100%;")),
            column(3, actionButton(ns("load_edit"), "Load into Editor", icon = icon("edit"), class = "btn-info", style = "width: 100%;")),
            column(3, actionButton(ns("delete"), "Delete", icon = icon("trash"), class = "btn-danger", style = "width: 100%;")),
            column(3, actionButton(ns("refresh"), "Refresh List", icon = icon("sync"), class = "btn-default", style = "width: 100%;"))
          ))
    )
  )
}

# ==== Server =======================================================================================

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
      lay <- tryCatch(ig_layout(d), error = function(e) { showNotification(paste("Layout problem:", app_err_text(e)), type = "error"); NULL })
      if (is.null(lay)) return(invisible(NULL))
      layout_pages(lay$pages); layout_notes(lay$notes)
      fm <- ig_format_id(d$meta$format)
      if (!identical(fm, isolate(last_fmt()))) { last_fmt(fm); session$sendCustomMessage("ig_export_default", list(id = session$ns("ig_format"), fmt = fm)) }
      output$diagram <- renderUI(export_capture_wrapper(session$ns, render_infographic(d, lay), d$meta$title %||% "infographic", meta = d))
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
      tryCatch(load_seed(sd), error = function(e) showNotification(paste("Could not load the example:", app_err_text(e)), type = "error"))
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
        set_status("status-error", "fa fa-times-circle", paste("Failed:", app_err_text(e)))
        showNotification(paste("Error:", app_err_text(e)), type = "error", duration = 12)
      })
    })

    observeEvent(input$preview, {
      if (nchar(trimws(input$gen_text %||% "")) == 0) { showNotification("The text box is empty.", type = "warning"); return() }
      tryCatch({ d <- parse_infographic_text(input$gen_text); draw(d); sync_layout_inputs(d); set_status("status-success", "fa fa-check-circle", summary_msg(d), warn_ui(d)) },
               error = function(e) set_status("status-error", "fa fa-times-circle", paste("Parse problem:", app_err_text(e))))
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
      }, error = function(e) { set_status("status-error", "fa fa-times-circle", paste("Save failed:", app_err_text(e))); showNotification(paste("Error:", app_err_text(e)), type = "error", duration = 12) })
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
      tryCatch(list(design = infographic_from_row(row), id = sid), error = function(e) { showNotification(app_err_text(e), type = "error"); NULL })
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
      tryCatch({ api_manager$bq_insert_techdesign(row); showNotification("Infographic deleted.", type = "message") }, error = function(e) showNotification(paste("Error:", app_err_text(e)), type = "error"))
    })

    output$status <- renderUI(tags$div())
    output$diagram <- renderUI(tags$div(class = "status-info", "Generate or load an infographic to see it here."))
  })
}
