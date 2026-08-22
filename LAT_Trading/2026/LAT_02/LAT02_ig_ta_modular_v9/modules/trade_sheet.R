# modules/trade_sheet.R
# An interactive, fillable "Individual Trade Sheet" matching the uploaded
# Trade_Sheet_-_Template-1.docx layout: student name, Trade Entry block, Set-up/
# Trigger/Execution/Stop/Target reasoning, an in-trade management note, a Trade
# Exit block (supports multiple partial exits), Reason for Exit, and Lessons
# Learned. Unlike the Weekly Activity tabs, this is a blank form the student
# fills in themselves — there is no synthetic data here — plus a "Download as
# PDF" button that lays the filled form out to match the template, using the
# same dependency-free base-R PDF approach as export_weekly_pdf() (no
# officer/Word dependency, consistent with the rest of the app).
#
# Chart images: the template has "[Insert chart picture here]" placeholders at
# 3 points (entry, in-trade management, exit). This tab lets the student upload
# an image for each of those slots (fileInput), and the PDF export embeds
# whichever ones were provided.

trade_sheet_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        width = 12, solidHeader = FALSE, status = "primary",
        div(style = "display:flex; align-items:center; gap:16px; flex-wrap:wrap;",
            downloadButton(ns("downloadTradeSheet"), "Download Trade Sheet (PDF)", class = "btn-primary"),
            actionButton(ns("resetForm"), "Reset Form", icon = icon("rotate-left"), class = "btn-default"),
            tags$span("Fill in the fields below, then download a print-ready PDF matching the LAT trade sheet template.",
                      style = "font-size:12px; color:#666;")
        )
      )
    ),

    fluidRow(
      box(title = "Trade Sheet", status = "primary", solidHeader = TRUE, width = 12,
        textInput(ns("studentName"), "Name:", value = "Jose Zubizarreta", width = "100%"),

        tags$h5("Trade Entry", style = "color:#002C3C; margin-top:14px;"),
        fluidRow(
          column(3, textInput(ns("chartPeriod"), "Chart Period", placeholder = "e.g. M15 / H1 / Daily")),
          column(3, textInput(ns("expectedDuration"), "Expected Trade Duration", placeholder = "e.g. 2 hours")),
          column(2, numericInput(ns("initialRisk"), "Initial Risk (£)", value = NA, min = 0)),
          column(2, numericInput(ns("initialReward"), "Initial Reward (£)", value = NA, min = 0)),
          column(2, textInput(ns("initialRRR"), "Initial RRR", placeholder = "e.g. 1:2"))
        ),
        fluidRow(
          column(2, dateInput(ns("entryDate"), "Date")),
          column(2, textInput(ns("entryTime"), "Time", placeholder = "HH:MM")),
          column(1, selectInput(ns("entryBS"), "B/S", choices = c("Buy" = "B", "Sell" = "S"))),
          column(2, textInput(ns("entryAsset"), "Asset")),
          column(1, numericInput(ns("entryLotSize"), "Lot Size", value = NA)),
          column(2, numericInput(ns("entryPrice"), "Price", value = NA)),
          column(1, numericInput(ns("entryStop"), "Stop Loss", value = NA))
        ),
        fluidRow(column(2, numericInput(ns("entryTarget"), "Target", value = NA))),

        fluidRow(
          column(6, textAreaInput(ns("setupFundamental"), "Set-up (fundamental)", rows = 2, width = "100%")),
          column(6, textAreaInput(ns("setupTechnical"), "Set-up (technical)", rows = 2, width = "100%"))
        ),
        fluidRow(
          column(6, textAreaInput(ns("trigger"), "Trigger", rows = 2, width = "100%")),
          column(6, textAreaInput(ns("execution"), "Execution", rows = 2, width = "100%"))
        ),
        fluidRow(
          column(6, textAreaInput(ns("reasonStop"), "Reason for Stop Loss placement", rows = 2, width = "100%")),
          column(6, textAreaInput(ns("reasonTarget"), "Reason for Target Limit placement", rows = 2, width = "100%"))
        ),
        fileInput(ns("entryChart"), "Insert chart picture here (entry)", accept = c("image/png","image/jpeg")),

        tags$h5("In-Trade Management", style = "color:#002C3C; margin-top:14px;"),
        tags$p("If you cut part of your position and/or move your stop loss, explain here and attach an updated chart.",
               style = "font-size:11.5px; color:#666;"),
        textAreaInput(ns("inTradeManagement"), NULL, rows = 3, width = "100%",
                      placeholder = "Explanation of any position/stop adjustments..."),
        fileInput(ns("mgmtChart"), "Insert chart picture here (in-trade management, if applicable)", accept = c("image/png","image/jpeg")),

        tags$h5("Trade Exit", style = "color:#002C3C; margin-top:14px;"),
        tags$p("If you exit in separate steps, add one row per partial exit.", style = "font-size:11.5px; color:#666;"),
        fluidRow(column(3, textInput(ns("actualDuration"), "Actual Trade Duration (hours)"))),
        tags$p("Double-click a cell to edit. Add rows below if you exited in more than 3 steps.",
               style = "font-size:11px; color:#888; margin-bottom:4px;"),
        DT::dataTableOutput(ns("exitTable")),
        tags$div(style = "margin-top:8px;",
          actionButton(ns("addExitRow"), "Add Exit Row", icon = icon("plus"), class = "btn-sm")
        ),

        fluidRow(
          column(6, textAreaInput(ns("reasonExit"), "Reason for Exit", rows = 2, width = "100%")),
          column(6, textAreaInput(ns("lessonsLearned"), "Lessons Learned", rows = 2, width = "100%"))
        ),
        fileInput(ns("exitChart"), "Insert chart picture here (exit)", accept = c("image/png","image/jpeg"))
      )
    )
  )
}

trade_sheet_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {

    exit_rows <- reactiveVal(data.frame(
      Date = character(3), Time = character(3), `B/S` = character(3), Asset = character(3),
      `Lot Size` = numeric(3), `Entry Price` = numeric(3), `Exit Price` = numeric(3),
      Pips = numeric(3), `Profit (Loss) £` = numeric(3), check.names = FALSE, stringsAsFactors = FALSE
    ))

    output$exitTable <- DT::renderDataTable({
      DT::datatable(exit_rows(), rownames = FALSE, editable = TRUE,
                    options = list(dom = 't', paging = FALSE, ordering = FALSE))
    })
    exit_proxy <- DT::dataTableProxy("exitTable")
    observeEvent(input$exitTable_cell_edit, {
      info <- input$exitTable_cell_edit
      df <- exit_rows()
      df[info$row, info$col + 1] <- DT::coerceValue(info$value, df[info$row, info$col + 1])
      exit_rows(df)
      DT::replaceData(exit_proxy, df, resetPaging = FALSE, rownames = FALSE)
    })
    observeEvent(input$addExitRow, {
      df <- exit_rows()
      df[nrow(df) + 1, ] <- NA
      exit_rows(df)
    })

    observeEvent(input$resetForm, {
      updateTextInput(session, "studentName", value = "")
      updateTextInput(session, "chartPeriod", value = "")
      updateTextInput(session, "expectedDuration", value = "")
      updateNumericInput(session, "initialRisk", value = NA)
      updateNumericInput(session, "initialReward", value = NA)
      updateTextInput(session, "initialRRR", value = "")
      updateTextInput(session, "entryTime", value = "")
      updateTextInput(session, "entryAsset", value = "")
      updateNumericInput(session, "entryLotSize", value = NA)
      updateNumericInput(session, "entryPrice", value = NA)
      updateNumericInput(session, "entryStop", value = NA)
      updateNumericInput(session, "entryTarget", value = NA)
      updateTextAreaInput(session, "setupFundamental", value = "")
      updateTextAreaInput(session, "setupTechnical", value = "")
      updateTextAreaInput(session, "trigger", value = "")
      updateTextAreaInput(session, "execution", value = "")
      updateTextAreaInput(session, "reasonStop", value = "")
      updateTextAreaInput(session, "reasonTarget", value = "")
      updateTextAreaInput(session, "inTradeManagement", value = "")
      updateTextInput(session, "actualDuration", value = "")
      updateTextAreaInput(session, "reasonExit", value = "")
      updateTextAreaInput(session, "lessonsLearned", value = "")
      exit_rows(data.frame(
        Date = character(3), Time = character(3), `B/S` = character(3), Asset = character(3),
        `Lot Size` = numeric(3), `Entry Price` = numeric(3), `Exit Price` = numeric(3),
        Pips = numeric(3), `Profit (Loss) £` = numeric(3), check.names = FALSE, stringsAsFactors = FALSE
      ))
      showNotification("Form reset.", type = "message", duration = 2)
    })

    # -- Base-R PDF export matching the template layout, dependency-free (no
    #    officer/Word), consistent with export_weekly_pdf()'s approach. --
    output$downloadTradeSheet <- downloadHandler(
      filename = function() paste0("trade_sheet_", format(Sys.Date(), "%Y%m%d_%H%M"), ".pdf"),
      contentType = "application/pdf",
      content = function(file) {
        grDevices::pdf(file, width = 8.27, height = 11.69, onefile = TRUE)
        on.exit(grDevices::dev.off(), add = TRUE)

        wrap_field <- function(label, value, width_chars = 95) {
          val <- if (is.null(value) || is.na(value) || value == "") "\u2014" else as.character(value)
          paste0(strwrap(paste0(label, ": ", val), width = width_chars), collapse = "\n")
        }

        graphics::par(mfrow = c(1, 1), mar = c(1, 1, 1, 1), oma = c(0, 0, 0, 0))
        graphics::plot.new()
        graphics::plot.window(xlim = c(0, 1), ylim = c(0, 1))

        y <- 0.98
        step <- function(dy) y <<- y - dy

        graphics::text(0.02, y, "Individual Trade Sheet", cex = 1.5, font = 2, col = "#002C3C", adj = c(0, 1)); step(0.035)
        graphics::text(0.02, y, paste0("Name: ", input$studentName %||% "\u2014"), cex = 1.0, adj = c(0, 1)); step(0.045)

        graphics::text(0.02, y, "Trade Entry", cex = 1.15, font = 2, col = "#002C3C", adj = c(0, 1)); step(0.03)
        entry_lines <- c(
          wrap_field("Chart Period", input$chartPeriod),
          wrap_field("Expected Trade Duration", input$expectedDuration),
          wrap_field("Initial Risk / Reward / RRR", paste0(input$initialRisk %||% "\u2014", " / ", input$initialReward %||% "\u2014", " / ", input$initialRRR %||% "\u2014")),
          wrap_field("Date / Time / B-S / Asset", paste0(format(input$entryDate %||% Sys.Date()), " / ", input$entryTime %||% "\u2014", " / ", input$entryBS %||% "\u2014", " / ", input$entryAsset %||% "\u2014")),
          wrap_field("Lot Size / Price / Stop Loss / Target", paste0(input$entryLotSize %||% "\u2014", " / ", input$entryPrice %||% "\u2014", " / ", input$entryStop %||% "\u2014", " / ", input$entryTarget %||% "\u2014"))
        )
        for (ln in entry_lines) { graphics::text(0.02, y, ln, cex = 0.85, adj = c(0, 1)); step(0.028 * (length(strsplit(ln,"\n")[[1]]))) }

        step(0.01)
        block_lines <- c(
          wrap_field("Set-up (fundamental)", input$setupFundamental),
          wrap_field("Set-up (technical)", input$setupTechnical),
          wrap_field("Trigger", input$trigger),
          wrap_field("Execution", input$execution),
          wrap_field("Reason for Stop Loss placement", input$reasonStop),
          wrap_field("Reason for Target Limit placement", input$reasonTarget)
        )
        for (ln in block_lines) { graphics::text(0.02, y, ln, cex = 0.85, adj = c(0, 1)); step(0.028 * (length(strsplit(ln,"\n")[[1]]))) }

        embed_image <- function(finfo, cap) {
          if (is.null(finfo)) return(invisible())
          step(0.02)
          if (y < 0.32) { graphics::plot.new(); graphics::plot.window(xlim=c(0,1), ylim=c(0,1)); y <<- 0.98 }
          graphics::text(0.02, y, cap, cex = 0.8, font = 3, col = "#666666", adj = c(0, 1)); step(0.03)
          img <- tryCatch({
            ext <- tolower(tools::file_ext(finfo$datapath))
            if (ext %in% c("jpg","jpeg")) jpeg::readJPEG(finfo$datapath) else png::readPNG(finfo$datapath)
          }, error = function(e) NULL)
          if (!is.null(img)) {
            asp <- dim(img)[1] / dim(img)[2]
            w <- 0.9; h <- min(0.28, w * asp)
            graphics::rasterImage(img, 0.02, y - h, 0.02 + w, y, interpolate = TRUE)
            step(h + 0.03)
          }
        }
        embed_image(input$entryChart, "[Chart — Trade Entry]")

        step(0.02)
        graphics::text(0.02, y, "In-Trade Management", cex = 1.15, font = 2, col = "#002C3C", adj = c(0, 1)); step(0.03)
        mgmt_ln <- wrap_field("Notes", input$inTradeManagement, width_chars = 100)
        graphics::text(0.02, y, mgmt_ln, cex = 0.85, adj = c(0, 1)); step(0.028 * length(strsplit(mgmt_ln,"\n")[[1]]))
        embed_image(input$mgmtChart, "[Chart — In-Trade Management]")

        if (y < 0.35) { graphics::plot.new(); graphics::plot.window(xlim=c(0,1), ylim=c(0,1)); y <<- 0.98 }
        step(0.02)
        graphics::text(0.02, y, "Trade Exit", cex = 1.15, font = 2, col = "#002C3C", adj = c(0, 1)); step(0.03)
        graphics::text(0.02, y, wrap_field("Actual Trade Duration (hours)", input$actualDuration), cex = 0.85, adj = c(0, 1)); step(0.03)

        et <- exit_rows()
        hdr <- sprintf("%-10s %-6s %-4s %-8s %-6s %-10s %-10s %-6s %-10s", "Date","Time","B/S","Asset","Lots","Entry","Exit","Pips","P/L (£)")
        graphics::text(0.02, y, hdr, cex = 0.7, family = "mono", font = 2, adj = c(0, 1)); step(0.022)
        for (r in seq_len(nrow(et))) {
          row <- et[r, ]
          if (all(is.na(row) | row == "")) next
          line <- sprintf("%-10s %-6s %-4s %-8s %-6s %-10s %-10s %-6s %-10s",
                           as.character(row[["Date"]] %||% ""), as.character(row[["Time"]] %||% ""),
                           as.character(row[["B/S"]] %||% ""), as.character(row[["Asset"]] %||% ""),
                           as.character(row[["Lot Size"]] %||% ""), as.character(row[["Entry Price"]] %||% ""),
                           as.character(row[["Exit Price"]] %||% ""), as.character(row[["Pips"]] %||% ""),
                           as.character(row[["Profit (Loss) \u00a3"]] %||% ""))
          graphics::text(0.02, y, line, cex = 0.7, family = "mono", adj = c(0, 1)); step(0.022)
        }

        step(0.015)
        exit_block <- c(wrap_field("Reason for Exit", input$reasonExit), wrap_field("Lessons Learned", input$lessonsLearned))
        for (ln in exit_block) { graphics::text(0.02, y, ln, cex = 0.85, adj = c(0, 1)); step(0.028 * length(strsplit(ln,"\n")[[1]])) }
        embed_image(input$exitChart, "[Chart — Trade Exit]")

        graphics::mtext(paste0("LAT Trade Sheet \u2014 ", input$studentName %||% ""), side = 1, outer = FALSE,
                         cex = 0.6, col = "#888888", line = -1)
      }
    )

    session$onSessionEnded(function() {})
  })
}
