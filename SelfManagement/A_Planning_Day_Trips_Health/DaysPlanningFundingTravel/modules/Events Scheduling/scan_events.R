# modules/Events Scheduling/scan_events.R
# ---- module ----------------------------------------------
# id:           scan_events
# name:         Scan Events
# icon:         search-location
# description:  AI-powered city event scanning via Claude web search
# packages:     shiny, shinydashboard, httr, curl, jsonlite, shinyjs, DT
# api_required: claude
# -----------------------------------------------------------

# ---- UI ----
scan_events_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "City Event Scanner", status = "primary", solidHeader = TRUE, width = 12,

        h4("Scan Events Using Claude AI"),
        p("Enter a location and date range — Claude will generate a structured list of events. ",
          "City is optional: leave blank to get the top N most notable events globally or by country."),

        # ── Row 1: Location + Dates + Top-N ─────────────────
        fluidRow(
          column(4,
                 textInput(ns("city"),    "City (optional):",
                           placeholder = "e.g., London — leave blank for country/global scan"),
                 textInput(ns("country"), "Country (optional):",
                           placeholder = "e.g., United Kingdom")
          ),
          column(4,
                 dateInput(ns("date_from"), "From Date:",
                           value = Sys.Date(), format = "yyyy-mm-dd"),
                 dateInput(ns("date_to"),   "To Date:",
                           value = Sys.Date() + 30, format = "yyyy-mm-dd"),
                 bos_tz_dropdown_ui(ns, label = "Time zone for event times:")
          ),
          column(4,
                 selectInput(ns("top_n"), "Number of Events (Top N):",
                             choices  = setNames(seq(5, 30, by = 5),
                                                 paste(seq(5, 30, by = 5), "events")),
                             selected = 10),
                 div(class = "alert alert-info", style = "margin-top: 6px; font-size: 0.85em;",
                     icon("info-circle"), " ",
                     "When city is blank or date range is broad, Claude returns the ",
                     tags$strong("top N most relevant"), " events.")
          )
        ),

        hr(),

        # ── Row 2: Category cascade + Extra info ─────────────
        fluidRow(
          column(6,
                 h5("Category Filter"),
                 p(class = "text-muted", style = "margin-top:-8px; font-size:0.88em;",
                   "Select existing values from your database, or type a new one."),
                 events_category_dropdown_ui(ns)
          ),
          column(6,
                 h5("Additional Context (optional)"),
                 p(class = "text-muted", style = "margin-top:-8px; font-size:0.88em;",
                   "Sent verbatim to Claude — e.g. \"outdoor only\", \"free events\", \"family-friendly\"."),
                 textAreaInput(ns("extra_info"), label = NULL, rows = 3,
                               placeholder = "e.g., Focus on free outdoor events suitable for families.")
          )
        ),

        hr(),

        # ── Row 3: Optional fields radio ─────────────────────
        fluidRow(
          column(12,
                 h5("Optional Fields to Include"),
                 p(class = "text-muted", style = "font-size:0.88em;",
                   "Controls which optional fields Claude is asked to populate. ",
                   "Fewer fields = faster response. ",
                   tags$strong("Core only"), " is recommended for reliable results."),
                 radioButtons(
                   ns("optional_fields"),
                   label = NULL,
                   choices = list(
                     "Core only — event_name, organiser, category, subcategory, event_date, event_time, venue_name, address, description, price_range, source_url" = "core",
                     "Core + Location — also include latitude & longitude"                                         = "core_geo",
                     "Core + Tickets — also include ticket_url & extra_info"                                       = "core_tickets",
                     "Full — all fields including latitude, longitude, ticket_url & extra_info"                    = "full"
                   ),
                   selected = "core",
                   inline = FALSE
                 )
          )
        ),

        hr(),

        # ── Action buttons ────────────────────────────────────
        fluidRow(
          column(3,
                 actionButton(ns("scan"), "Scan Events", icon = icon("search"),
                              class = "btn-primary btn-lg", style = "width: 100%;")
          ),
          column(3,
                 actionButton(ns("copy_to_bulk"), "Copy to Bulk Import", icon = icon("arrow-right"),
                              class = "btn-info btn-lg", style = "width: 100%;")
          ),
          column(3,
                 actionButton(ns("parse_and_upload"), "Parse & Upload Direct",
                              icon = icon("cloud-upload-alt"),
                              class = "btn-success btn-lg", style = "width: 100%;")
          ),
          column(3,
                 downloadButton(ns("download"), "Download Text",
                                class = "btn-warning", style = "width: 100%;")
          )
        )
      )
    ),

    # ── Output panel ─────────────────────────────────────────
    fluidRow(
      box(
        title = "Generated Events", status = "success", solidHeader = TRUE, width = 12,

        div(id = ns("loading_spinner"),
            style = "display: none; text-align: center; padding: 30px;",
            tags$i(class = "fa fa-spinner fa-spin fa-3x"),
            h4("Scanning for events... check the R console for live progress.")),

        h5("Review & Edit (re-parse after any manual fix):"),
        textAreaInput(ns("scan_text_edit"), NULL, height = "350px",
                      placeholder = "Scanned events will appear here - editable before upload."),
        actionButton(ns("reparse"), "Re-Parse & Update Preview", icon = icon("sync"), class = "btn-default"),

        br(), br(),
        htmlOutput(ns("status")),
        br(),
        DT::dataTableOutput(ns("preview_table"))
      )
    )
  )
}

# ---- Server ----
scan_events_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    parsed_preview <- reactiveVal(NULL)

    # Wire the Category -> Subcategory cascade (renamed to avoid colliding
    # with Funding Programmes' own Category cascade - see utils_common.R)
    cat_sub <- setup_events_category_cascade(input, output, session, api_manager)

    run_parse_preview <- function(text, quiet = FALSE) {
      if (trimws(text) == "") {
        parsed_preview(NULL)
        output$preview_table <- DT::renderDataTable({})
        return(invisible(NULL))
      }
      tryCatch({
        df <- parse_events_text(text, default_tz = input$time_zone)
        parsed_preview(df)
        output$preview_table <- DT::renderDataTable({
          DT::datatable(df, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
        })
        if (!quiet) {
          output$status <- renderUI({
            tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"), sprintf(" Parsed %d event(s)", nrow(df)))
          })
        }
      }, error = function(e) {
        parsed_preview(NULL)
        output$preview_table <- DT::renderDataTable({})
        if (!quiet) {
          output$status <- renderUI({
            tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Parse issue (blocking): ", e$message)
          })
        }
      })
    }

    observeEvent(input$scan, {

      if (!api_manager$claude_authenticated) {
        showNotification("Please configure Claude API credentials first!", type = "error", duration = 10)
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                   " Please configure Claude API in the Claude API Config tab first!")
        })
        return()
      }

      if (!is.null(input$date_from) && !is.null(input$date_to) && input$date_from > input$date_to) {
        showNotification("'From Date' must be before 'To Date'!", type = "error")
        return()
      }

      cs <- cat_sub()

      shinyjs::show("loading_spinner")
      updateTextAreaInput(session, "scan_text_edit", value = "")

      progress_msg <- reactiveVal("Initializing...")
      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " ", progress_msg())
      })

      top_n <- as.integer(input$top_n %||% 10)

      prompt <- bos_tz_wrap_prompt(generate_scan_prompt(
        city            = trimws(input$city    %||% ""),
        country         = trimws(input$country %||% ""),
        date_from       = if (!is.null(input$date_from)) as.character(input$date_from) else NULL,
        date_to         = if (!is.null(input$date_to))   as.character(input$date_to)   else NULL,
        category        = cs$category,
        subcategory     = cs$subcategory,
        top_n           = top_n,
        extra_info      = trimws(input$extra_info %||% ""),
        optional_fields = input$optional_fields %||% "core"
      ), input$time_zone, if (!is.null(input$date_from)) input$date_from else Sys.Date())

      cat("✓ [scan_events] Prompt built (", nchar(prompt), "chars) | top_n =", top_n,
          "| city =", trimws(input$city %||% "(blank)"), "| category =", cs$category, "/", cs$subcategory, "\n")

      tryCatch({
        progress_msg(paste0("Sending request to Claude for top ", top_n, " events (web search enabled)..."))

        # enable_web_search = TRUE - Events needs real, currently-happening
        # events with verified source URLs, not training-data recall alone.
        api_result <- api_manager$call_claude(
          prompt = prompt,
          progress_callback = function(msg) { progress_msg(msg) },
          enable_web_search = TRUE
        )

        city_val    <- trimws(input$city    %||% "")
        country_val <- trimws(input$country %||% "")

        events_text <- bos_tz_set_header(overwrite_events_header(api_result$text, city = city_val, country = country_val, scan_date = as.character(Sys.Date())), input$time_zone)

        updateTextAreaInput(session, "scan_text_edit", value = events_text)
        shinyjs::hide("loading_spinner")

        run_parse_preview(events_text, quiet = TRUE)

        truncation_warning <- if (isTRUE(api_result$truncated)) {
          tagList(tags$br(), tags$span(style = "color: #e67e22; font-weight: bold;",
                    "⚠️ Response was cut off at the Max Tokens limit - some events may be missing."))
        } else NULL

        n_found <- length(grep("^\\[event_name\\]:", strsplit(events_text, "\n")[[1]], ignore.case = TRUE))

        output$status <- renderUI({
          tags$div(class = if (isTRUE(api_result$truncated)) "status-warning" else "status-success",
                   tags$i(class = if (isTRUE(api_result$truncated)) "fa fa-exclamation-triangle" else "fa fa-check-circle"),
                   if (isTRUE(api_result$truncated)) " Scan complete (truncated)" else " ✓ Scan complete!",
                   tags$br(), tags$small(sprintf("Found %d events - %d characters generated", n_found, nchar(events_text))),
                   truncation_warning)
        })

        if (!isTRUE(api_result$truncated)) showNotification(sprintf("✓ %d events scanned!", n_found), type = "message")
        else showNotification("⚠️ Response truncated - increase Max Tokens", type = "warning", duration = 15)

      }, error = function(e) {
        shinyjs::hide("loading_spinner")
        suggestion <- ""
        if (grepl("timeout", e$message, ignore.case = TRUE)) suggestion <- "💡 Try: Increase timeout in Claude API Config"
        else if (grepl("401|authentication", e$message, ignore.case = TRUE)) suggestion <- "💡 Try: Re-enter your API key in Claude API Config"
        else if (grepl("429|rate limit", e$message, ignore.case = TRUE)) suggestion <- "💡 Try: Wait a few moments and try again"

        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Scan Failed",
                   tags$br(), tags$strong("Error: "), tags$small(e$message),
                   if (nchar(suggestion) > 0) tagList(tags$br(), tags$br(), tags$span(style = "color:#f39c12;", suggestion)) else NULL)
        })
        showNotification(paste("Error:", e$message), type = "error", duration = 15)
      })
    })

    observeEvent(input$reparse, {
      run_parse_preview(input$scan_text_edit)
    })

    observeEvent(input$copy_to_bulk, {
      current_text <- input$scan_text_edit
      if (nchar(trimws(current_text %||% "")) > 0) {
        api_manager$set_pending_bulk_text_events(current_text)
        nav_goto(session, "bulk_import_events")
        showNotification("✓ Events copied to Bulk Import tab!", type = "message")
      } else {
        showNotification("No events to copy. Scan first.", type = "warning")
      }
    })

    observeEvent(input$parse_and_upload, {
      if (!api_manager$bq_authenticated) { showNotification("Please authenticate with BigQuery first!", type = "error"); return() }

      current_text <- input$scan_text_edit
      if (nchar(trimws(current_text %||% "")) == 0) { showNotification("No events to upload. Scan first.", type = "warning"); return() }

      output$status <- renderUI({ tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing and uploading...") })

      tryCatch({
        parsed_df     <- parse_events_text(current_text, default_tz = input$time_zone)
        rows_uploaded <- api_manager$bq_insert_events(parsed_df)
        api_manager$trigger_state_update_events()

        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Successfully uploaded %d events!", rows_uploaded))
        })
        showNotification(sprintf("✓ Uploaded %d events!", rows_uploaded), type = "message")

      }, error = function(e) {
        output$status <- renderUI({ tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message) })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    output$download <- downloadHandler(
      filename = function() {
        city_part <- if (nchar(trimws(input$city %||% "")) > 0) gsub(" ", "_", trimws(input$city)) else "global"
        paste0("events_", city_part, "_", format(Sys.Date(), "%Y%m%d"), ".txt")
      },
      content = function(file) { writeLines(input$scan_text_edit %||% "", file) }
    )

    output$status <- renderUI({ tags$div() })
    output$preview_table <- DT::renderDataTable({})
    session$onSessionEnded(function() {})
  })
}
