# Budget Module

library(dplyr)
library(DT)

budgetUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Set Quarterly Budget",
        status = "primary",
        solidHeader = TRUE,
        width = 6,
        p(strong("Instructions:"), "Enter the budget amounts for each category for the current quarter."),
        hr(),
        textInput(ns("quarter"), "Quarter (e.g., Q1 2026):", 
                 value = paste0("Q", ceiling(as.numeric(format(Sys.Date(), "%m"))/3), " ", format(Sys.Date(), "%Y")), width = "100%"),
        hr(),
        fluidRow(
          column(6, numericInput(ns("labour_budget"), "Labour:", value = 0, min = 0, step = 100, width = "100%")),
          column(6, numericInput(ns("overheads_budget"), "Overheads:", value = 0, min = 0, step = 100, width = "100%"))
        ),
        fluidRow(
          column(6, numericInput(ns("materials_budget"), "Materials:", value = 0, min = 0, step = 100, width = "100%")),
          column(6, numericInput(ns("capital_usage_budget"), "Capital Usage:", value = 0, min = 0, step = 100, width = "100%"))
        ),
        fluidRow(
          column(6, numericInput(ns("ts_budget"), "TS:", value = 0, min = 0, step = 100, width = "100%")),
          column(6, numericInput(ns("contractor_budget"), "Contractor:", value = 0, min = 0, step = 100, width = "100%"))
        ),
        fluidRow(
          column(6, numericInput(ns("nc_fees_budget"), "NC Fees:", value = 0, min = 0, step = 100, width = "100%")),
          column(6, numericInput(ns("other_budget"), "Other:", value = 0, min = 0, step = 100, width = "100%"))
        ),
        hr(),
        actionButton(ns("add_budget_btn"), "Add Budget Entry", class = "btn-primary", icon = icon("plus-circle"), width = "100%"),
        hr(),
        actionButton(ns("transfer_budget_btn"), "Transfer Budget to Transaction Tab", 
                    class = "btn-warning", icon = icon("arrow-right"), width = "100%")
      ),
      
      box(
        title = "Load/Save Budget",
        status = "info",
        solidHeader = TRUE,
        width = 6,
        p(strong("Load:"), "Load a previously saved budget file."),
        fileInput(ns("load_budget_file"), "Load Budget File (Excel or CSV):",
                 multiple = FALSE, accept = c(".xlsx", ".csv"),
                 placeholder = "Select budget file", buttonLabel = "Browse..."),
        hr(),
        p(strong("Save:"), "Download current budget data."),
        textInput(ns("save_filename"), "File Name:", value = "quarterly_budget", width = "100%"),
        selectInput(ns("file_format"), "Format:", 
                   choices = c("Excel (.xlsx)" = "xlsx", "CSV (.csv)" = "csv"),
                   selected = "xlsx", width = "100%"),
        downloadButton(ns("download_budget"), "Download Budget File", 
                      class = "btn-success", style = "width: 100%;"),
        hr(),
        uiOutput(ns("save_status"))
      )
    ),
    
    fluidRow(
      box(
        title = "Budget Table",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        p("Current budget entries. Double-click cells to edit."),
        hr(),
        DT::dataTableOutput(ns("budget_table"))
      )
    )
  )
}

budgetServer <- function(id, shared_rv) {
  moduleServer(id, function(input, output, session) {
    
    rv <- reactiveValues(
      budget_data = data.frame(
        Quarter = character(), 
        Labour = numeric(), 
        Overheads = numeric(),
        Materials = numeric(), 
        Capital_Usage = numeric(), 
        TS = numeric(),
        Contractor = numeric(),
        NC_Fees = numeric(),
        Other = numeric(),
        stringsAsFactors = FALSE
      )
    )
    
    observeEvent(input$add_budget_btn, {
      req(input$quarter)
      if (nchar(trimws(input$quarter)) == 0) {
        showNotification("Please enter a quarter", type = "warning")
        return()
      }
      if (input$quarter %in% rv$budget_data$Quarter) {
        showModal(modalDialog(
          title = "Quarter Exists", 
          paste("Budget for", input$quarter, "already exists. Update it?"),
          footer = tagList(
            modalButton("Cancel"), 
            actionButton(session$ns("confirm_update"), "Update", class = "btn-warning")
          )
        ))
        return()
      }
      rv$budget_data <- rbind(rv$budget_data, data.frame(
        Quarter = input$quarter, 
        Labour = input$labour_budget, 
        Overheads = input$overheads_budget,
        Materials = input$materials_budget, 
        Capital_Usage = input$capital_usage_budget,
        TS = input$ts_budget, 
        Contractor = input$contractor_budget,
        NC_Fees = input$nc_fees_budget,
        Other = input$other_budget,
        stringsAsFactors = FALSE
      ))
      showNotification(paste("Budget for", input$quarter, "added"), type = "message")
    })
    
    observeEvent(input$confirm_update, {
      idx <- which(rv$budget_data$Quarter == input$quarter)
      rv$budget_data[idx, ] <- data.frame(
        Quarter = input$quarter, 
        Labour = input$labour_budget, 
        Overheads = input$overheads_budget,
        Materials = input$materials_budget,
        Capital_Usage = input$capital_usage_budget, 
        TS = input$ts_budget,
        Contractor = input$contractor_budget,
        NC_Fees = input$nc_fees_budget,
        Other = input$other_budget,
        stringsAsFactors = FALSE
      )
      removeModal()
      showNotification(paste("Budget for", input$quarter, "updated"), type = "message")
    })
    
    observeEvent(input$transfer_budget_btn, {
      req(nrow(rv$budget_data) > 0)
      shared_rv$budget_data <- rv$budget_data
      showModal(modalDialog(
        title = "✓ Budget Transferred",
        "Budget data has been transferred to the Transaction Categorization tab.",
        easyClose = TRUE,
        footer = modalButton("OK")
      ))
      showNotification("Budget transferred successfully!", type = "message", duration = 5)
    })
    
    output$budget_table <- DT::renderDataTable({
      DT::datatable(
        rv$budget_data, 
        editable = list(target = 'cell'),
        options = list(pageLength = 10, scrollX = TRUE, order = list(list(0, 'desc'))), 
        rownames = FALSE
      ) %>%
        DT::formatCurrency(
          columns = c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor", "NC_Fees", "Other"), 
          currency = "£", digits = 2
        )
    })
    
    observeEvent(input$budget_table_cell_edit, {
      info <- input$budget_table_cell_edit
      i <- info$row; j <- info$col + 1; v <- info$value
      if (j > 1) {
        if (!is.na(as.numeric(v))) rv$budget_data[i, j] <- as.numeric(v)
        else showNotification("Please enter a valid number", type = "warning")
      } else {
        rv$budget_data[i, j] <- as.character(v)
      }
    })
    
    # Download handler - PROPER way to save files in Shiny
    output$download_budget <- downloadHandler(
      filename = function() {
        clean_filename <- gsub("[^a-zA-Z0-9_-]", "_", input$save_filename)
        file_ext <- if (input$file_format == "xlsx") ".xlsx" else ".csv"
        paste0(clean_filename, file_ext)
      },
      content = function(file) {
        req(nrow(rv$budget_data) > 0)
        if (input$file_format == "xlsx") {
          openxlsx::write.xlsx(rv$budget_data, file)
        } else {
          write.csv(rv$budget_data, file, row.names = FALSE)
        }
        shared_rv$budget_data <- rv$budget_data
      }
    )
    
    observeEvent(input$load_budget_file, {
      req(input$load_budget_file)
      tryCatch({
        file_ext <- tolower(tools::file_ext(input$load_budget_file$name))
        loaded_data <- if (file_ext == "xlsx") {
          openxlsx::read.xlsx(input$load_budget_file$datapath)
        } else {
          read.csv(input$load_budget_file$datapath, stringsAsFactors = FALSE)
        }
        required_cols <- c("Quarter", "Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor")
        if (!all(required_cols %in% names(loaded_data))) {
          showModal(modalDialog(
            title = "Invalid File Format",
            "The file is missing required budget columns.",
            easyClose = TRUE,
            footer = modalButton("OK")
          ))
          return()
        }
        for (col in c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor", "NC_Fees", "Other")) {
          if (col %in% names(loaded_data)) {
            loaded_data[[col]] <- as.numeric(loaded_data[[col]])
          } else {
            loaded_data[[col]] <- 0
          }
        }
        rv$budget_data <- loaded_data
        shared_rv$budget_data <- loaded_data
        output$save_status <- renderUI({
          tags$div(
            class = "alert alert-success",
            tags$strong("✓ Loaded: "), 
            input$load_budget_file$name,
            tags$br(),
            tags$small(paste(nrow(loaded_data), "entries"))
          )
        })
        showNotification("Budget file loaded successfully", type = "message", duration = 5)
      }, error = function(e) {
        showModal(modalDialog(
          title = "Error Loading File",
          paste("Failed to load file:", e$message),
          easyClose = TRUE,
          footer = modalButton("OK")
        ))
      })
    })
  })
}
