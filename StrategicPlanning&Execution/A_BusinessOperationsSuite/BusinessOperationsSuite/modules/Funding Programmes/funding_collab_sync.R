# modules/Funding Programmes/funding_collab_sync.R
# Subtab: Collaboration Sync - exchange funding programmes with the CollaborationPlanning app (used by other people to
# explore funding and collaboration), through its tables AND its Drive folder.
#   Import: its programmes list and the programmes in its Claude analyses - from its tables (BigQuery cp_*, or its
#           Sheet) and/or its Drive folder (analyses + latest Backups/<date>/programmes.csv)
#           -> preview (New / Repeated / Already imported) -> funding_programmes in BigQuery, repeated rows flagged.
#   Share:  our programmes -> its programmes list (its tables) and -> analyses in its format (its tables + Drive).
# Its tables: R/suite_cp.R (its own storage code). Drive: R/utils_collab_sync.R.
# The folder and how to reach it: API Settings > Google Drive > CollaborationPlanning folder. Code: R/utils_collab_sync.R

funding_collab_sync_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(title = "CollaborationPlanning Tables and Folder", status = "primary", solidHeader = TRUE, width = 12,
          p("Both apps exchange programmes through CollaborationPlanning's ", tags$b("tables"), " (BigQuery ", tags$code("cp_programmes"),
            ", ", tags$code("cp_analyses"), ", and its Google Sheet when it has one) and its ", tags$b("Google Drive folder"),
            ": its Claude analyses (", tags$code("<Country>/<Category>/<Topic>/<programme>__<id>.json"), ") and its daily backup ",
            "(", tags$code("Backups/<date>/programmes.csv"), "). Set both in ", tags$b("API Settings > Google Drive"), "."),
          actionButton(ns("check"), "Check Tables and Folder", icon = icon("folder-open"), class = "btn-info"),
          uiOutput(ns("folder_status")))
    ),
    fluidRow(
      box(title = "Import from CollaborationPlanning into BigQuery", status = "success", solidHeader = TRUE, width = 12,
          fluidRow(
            column(4, checkboxInput(ns("use_tables"), "Its tables: programmes list + analyses (current)", value = TRUE)),
            column(4, checkboxInput(ns("use_backup"), "Drive: its programmes list (latest daily backup)", value = FALSE),
                      checkboxInput(ns("use_analyses"), "Drive: programmes found in its analysis files", value = FALSE)),
            column(4, actionButton(ns("read"), "Read", icon = icon("cloud-download-alt"), class = "btn-primary", style = "width:100%"))),
          uiOutput(ns("read_status")),
          DT::dataTableOutput(ns("preview")),
          br(),
          fluidRow(
            column(6, checkboxInput(ns("include_already"), "Also load rows that were imported before (marked as repeated)", value = FALSE)),
            column(6, actionButton(ns("load"), "Load into BigQuery", icon = icon("database"), class = "btn-success", style = "width:100%"))),
          tags$p(class = "help-block",
                 tags$b("New"), ": not in our table yet. ",
                 tags$b("Repeated"), ": a programme with the same name and funder/sponsor is already in our table (or earlier in this list); ",
                 "it is loaded too, with ", tags$code("repeated = TRUE"), " so it is easy to spot in Browse Data. ",
                 tags$b("Already imported"), ": this very record of CollaborationPlanning was loaded before; left out unless ticked above."),
          uiOutput(ns("load_status")))
    ),
    fluidRow(
      box(title = "Share Our Programmes with CollaborationPlanning", status = "warning", solidHeader = TRUE, width = 12,
          p("Where to write (people using CollaborationPlanning see it under ", tags$b("Discover"), " and ", tags$b("Suggestions > Analysis library"), "):"),
          fluidRow(
            column(4, checkboxInput(ns("to_programmes"), "Its programmes list (its tables; programmes already there by funder + name are skipped)", value = TRUE)),
            column(4, checkboxInput(ns("to_table_analyses"), "As analyses in its tables (shown at once)", value = TRUE)),
            column(4, checkboxInput(ns("to_drive"), "As analysis files in its Drive folder (Country/Category/Topic)", value = TRUE))),
          fluidRow(
            column(4, radioButtons(ns("which"), "Programmes to share",
                                   choices = c("Added in this app (not the ones imported from CollaborationPlanning)" = "ours",
                                               "All programmes in our table" = "all"), selected = "ours")),
            column(4, selectizeInput(ns("countries"), "Only these countries (empty = all)", choices = NULL, multiple = TRUE),
                      selectizeInput(ns("categories"), "Only these categories (empty = all)", choices = NULL, multiple = TRUE)),
            column(4, br(), actionButton(ns("preview_share"), "Preview", icon = icon("eye"), class = "btn-info", style = "width:100%"),
                      br(), br(), actionButton(ns("share"), "Write to CollaborationPlanning", icon = icon("cloud-upload-alt"), class = "btn-warning", style = "width:100%"))),
          uiOutput(ns("share_status")))
    )
  )
}

funding_collab_sync_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    marked <- reactiveVal(NULL)
    note <- function(cls, ...) tags$div(class = cls, ...)
    sa_path <- function() tryCatch(cred_local()$json_path, error = function(e) NA)
    folder <- function() {
      s <- collab_load_settings()
      if (!collab_ready(s, sa_path())) stop("The CollaborationPlanning folder is not set up: open API Settings > Google Drive > CollaborationPlanning folder.", call. = FALSE)
      list(s = s, f = collab_folder(s, sa_path()))
    }

    observeEvent(input$check, {
      t <- tryCatch({ st <- cp_connect(api_manager)
        sprintf("✓ Tables reachable (%s, prefix %s; writing to %s, it reads from %s). Programmes: %d, analyses: %d.",
                st$dataset, st$prefix, paste(st$write_to, collapse = " + "), st$read_from, nrow(cp_read("programmes")), nrow(cp_read("analyses"))) },
        error = function(e) e)
      r <- tryCatch({
        x <- folder(); b <- x$f$latest_backup("programmes"); a <- x$f$analyses()
        list(mode = x$f$mode, where = x$f$where, backup = if (is.null(b)) "none yet" else b$day, analyses = length(a))
      }, error = function(e) e)
      output$folder_status <- renderUI(tagList(
        if (inherits(t, "error")) note("status-error", "Tables: ", conditionMessage(t)) else note("status-success", t),
        if (inherits(r, "error")) note("status-error", "Folder: ", conditionMessage(r)) else
          note("status-success", sprintf("✓ Folder reachable (%s: %s). Latest programmes backup: %s. Analysis files: %d.",
                                         if (r$mode == "api") "Google Drive API" else "folder on this computer", r$where, r$backup, r$analyses))))
    })

    # ---- import
    observeEvent(input$read, {
      if (!isTRUE(input$use_tables) && !isTRUE(input$use_backup) && !isTRUE(input$use_analyses)) return(output$read_status <- renderUI(note("status-warning", "Tick at least one source.")))
      if (!api_manager$bq_authenticated) return(output$read_status <- renderUI(note("status-error", "Connect to BigQuery first (API Settings > BigQuery Config): the repeat check needs our table.")))
      res <- withProgress(message = "Reading CollaborationPlanning...", tryCatch({
        parts <- list(); info <- character(0)
        if (isTRUE(input$use_tables)) {
          st <- cp_connect(api_manager)
          p <- cp_programme_rows(); parts$table <- p
          ra <- cp_analysis_rows(); parts$table_analyses <- ra$rows
          info <- c(info, sprintf("%d programme(s) and %d from %d analysis(es) in its tables (%s)", nrow(p), nrow(ra$rows), ra$analyses, st$read_from))
        }
        x <- if (isTRUE(input$use_backup) || isTRUE(input$use_analyses)) folder()
        if (isTRUE(input$use_backup)) {
          b <- x$f$latest_backup("programmes")
          if (is.null(b)) info <- c(info, "no programmes backup yet") else {
            p <- collab_programmes_to_bos(collab_read_csv_text(b$text)); parts$backup <- p
            info <- c(info, sprintf("%d programme(s) from the backup of %s", nrow(p), b$day)) }
        }
        if (isTRUE(input$use_analyses)) {
          incProgress(0.4)
          ra <- collab_read_analyses(x$f$analyses()); parts$analyses <- ra$rows
          info <- c(info, sprintf("%d programme(s) from %d analysis file(s)%s", nrow(ra$rows), ra$analyses,
                                  if (ra$skipped_own) sprintf(" (%d shared by this app skipped)", ra$skipped_own) else ""))
        }
        parts <- Filter(function(d) is.data.frame(d) && nrow(d) > 0, parts)
        incoming <- if (length(parts)) do.call(rbind, lapply(parts, collab_conform)) else collab_conform(NULL)
        # the same record read twice (its table and its backup/analysis file): keep the first (the tables come first)
        dup <- nzchar(incoming$source_ref) & duplicated(incoming$source_ref)
        if (any(dup)) { info <- c(info, sprintf("%d duplicate(s) of the same record left out", sum(dup))); incoming <- incoming[!dup, , drop = FALSE] }
        incProgress(0.3)
        list(m = if (nrow(incoming)) collab_mark_repeats(incoming, api_manager$bq_funding_keys()) else incoming, info = info)
      }, error = function(e) e))
      if (inherits(res, "error")) { marked(NULL); return(output$read_status <- renderUI(note("status-error", conditionMessage(res)))) }
      marked(res$m)
      n <- function(st) if (nrow(res$m)) sum(res$m$status == st) else 0
      output$read_status <- renderUI(note("status-info", paste0(paste(res$info, collapse = "; "), ". "),
        tags$b(sprintf("New: %d, Repeated: %d, Already imported: %d.", n("New"), n("Repeated"), n("Already imported")))))
    })

    output$preview <- DT::renderDataTable({
      m <- marked(); req(m, nrow(m))
      show <- m[, c("status", "programme_name", "key_sponsors", "country", "category", "amount_of_money", "deadline", "source", "same_as_id")]
      names(show) <- c("Status", "Programme", "Funder / sponsors", "Country", "Category", "Amount", "Deadline", "From", "Same as our id")
      DT::formatStyle(DT::datatable(show, rownames = FALSE, options = list(pageLength = 15, scrollX = TRUE)), "Status",
                      backgroundColor = DT::styleEqual(c("New", "Repeated", "Already imported"), c("#d4edda", "#fff3cd", "#e2e3e5")),
                      fontWeight = "bold")
    })

    observeEvent(input$load, {
      m <- marked()
      if (is.null(m) || !nrow(m)) return(output$load_status <- renderUI(note("status-warning", "Read first.")))
      rows <- collab_rows_for_bq(m, isTRUE(input$include_already))
      if (!nrow(rows)) return(output$load_status <- renderUI(note("status-warning", "Nothing to load: every row was imported before.")))
      r <- withProgress(message = sprintf("Loading %d row(s) into BigQuery...", nrow(rows)), tryCatch(api_manager$bq_insert_funding(rows), error = function(e) e))
      if (inherits(r, "error")) return(output$load_status <- renderUI(note("status-error", "Not loaded: ", conditionMessage(r))))
      rep_n <- sum(rows$repeated == "TRUE")
      cat(sprintf("[Collaboration Sync] loaded %d row(s) from CollaborationPlanning (%d repeated)\n", r, rep_n))
      api_manager$bq_bump("state_trigger_funding")
      marked(collab_mark_repeats(m[, setdiff(names(m), c("status", "same_as_id"))], api_manager$bq_funding_keys()))
      output$load_status <- renderUI(note("status-success", sprintf("✓ Loaded %d programme(s) into BigQuery: %d new, %d marked as repeated. ", r, r - rep_n, rep_n),
                                          "See them in Browse Data (column ", tags$code("repeated"), ")."))
    })

    # ---- share
    share_rows <- function() {
      if (!api_manager$bq_authenticated) stop("Connect to BigQuery first (API Settings > BigQuery Config).", call. = FALSE)
      api_manager$bq_need("funding")
      if (!isTRUE(api_manager$bq_time_zone_ready[["funding"]])) api_manager$bq_ensure_time_zone_column("funding")
      d <- api_manager$bq_query(sprintf("SELECT * FROM `%s`", api_manager$bq_full_table_funding))
      if (is.null(d) || !nrow(d)) return(data.frame())
      if (input$which == "ours" && "source" %in% names(d)) d <- d[is.na(d$source) | !startsWith(as.character(d$source), "CollaborationPlanning"), , drop = FALSE]
      if (length(input$countries)) d <- d[d$country %in% input$countries, , drop = FALSE]
      if (length(input$categories)) d <- d[d$category %in% input$categories, , drop = FALSE]
      d
    }
    observe({   # filter choices from the table (once connected)
      api_manager$state_trigger_funding()
      req(api_manager$bq_authenticated)
      tx <- tryCatch(api_manager$bq_get_funding_taxonomy(), error = function(e) NULL)
      if (!is.null(tx)) {
        updateSelectizeInput(session, "countries", choices = sort(unique(tx$country %|g|% character(0))), server = TRUE)
        updateSelectizeInput(session, "categories", choices = sort(unique(tx$category %|g|% character(0))), server = TRUE)
      }
    })
    observeEvent(input$preview_share, {
      d <- tryCatch(share_rows(), error = function(e) e)
      output$share_status <- renderUI(if (inherits(d, "error")) note("status-error", conditionMessage(d)) else
        note("status-info", sprintf("%d programme(s) would be written as analyses: %s%s", nrow(d),
                                    paste(utils::head(d$programme_name, 8), collapse = "; "), if (nrow(d) > 8) "; ..." else "")))
    })
    observeEvent(input$share, {
      if (!isTRUE(input$to_programmes) && !isTRUE(input$to_table_analyses) && !isTRUE(input$to_drive))
        return(output$share_status <- renderUI(note("status-warning", "Tick at least one place to write to.")))
      res <- withProgress(message = "Writing to CollaborationPlanning...", tryCatch({
        s <- collab_load_settings(); d <- share_rows()
        if (!nrow(d)) stop("No programmes match.", call. = FALSE)
        user <- collab_first(s$exported_by, tryCatch(session$userData$user_email %|g|% "", error = function(e) ""))
        out <- list(paths = character(0), programmes = NULL, analyses = 0L)
        # never send back what came from that app
        mine <- if ("source" %in% names(d)) is.na(d$source) | !startsWith(as.character(d$source), "CollaborationPlanning") else rep(TRUE, nrow(d))
        if (isTRUE(input$to_programmes) || isTRUE(input$to_table_analyses)) cp_connect(api_manager, s)
        if (isTRUE(input$to_programmes)) out$programmes <- cp_write_programmes(d[mine, , drop = FALSE], user)
        incProgress(0.2)
        recs <- lapply(which(mine), function(i) collab_export_record(d[i, , drop = FALSE], s, user))
        if (isTRUE(input$to_table_analyses)) out$analyses <- cp_write_analyses(recs, user)
        incProgress(0.2)
        if (isTRUE(input$to_drive)) {
          x <- folder()
          for (e in recs) { out$paths <- c(out$paths, x$f$write_analysis(e$levels, e$stem, e$json, e$html, e$analysis_id)); incProgress(0.6 / length(recs)) }
        }
        out
      }, error = function(e) e))
      if (inherits(res, "error")) return(output$share_status <- renderUI(note("status-error", "Not shared: ", conditionMessage(res))))
      cat(sprintf("[Collaboration Sync] shared with CollaborationPlanning: %s programme(s) added to its list, %d analysis row(s), %d Drive file pair(s)\n",
                  res$programmes$added %|g|% 0, res$analyses, length(res$paths)))
      output$share_status <- renderUI(note("status-success", "✓ Written to CollaborationPlanning. ",
        if (!is.null(res$programmes)) sprintf("Programmes list: %d added, %d already there. ", res$programmes$added, res$programmes$skipped),
        if (res$analyses) sprintf("Analyses in its tables: %d (shown in Suggestions > Analysis library). ", res$analyses),
        if (length(res$paths)) sprintf("Drive: %d analysis file pair(s). ", length(res$paths)),
        if (length(res$paths)) tags$details(tags$summary("Files"), tags$pre(paste(res$paths, collapse = "\n")))))
    })
  })
}
