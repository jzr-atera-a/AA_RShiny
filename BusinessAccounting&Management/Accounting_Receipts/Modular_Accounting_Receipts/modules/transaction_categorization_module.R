# Transaction Categorization Module

library(dplyr)
library(DT)

transactionCategorizationUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Add custom CSS for better cell highlighting
    tags$head(
      tags$style(HTML("
        /* Make selected category cells highly visible */
        #txn_categorization-transactions_table td.dt-center {
          font-weight: bold;
          font-size: 14px;
        }
        /* Highlight cells with value 1 */
        .category-selected {
          background-color: #28a745 !important;
          color: white !important;
          font-weight: bold !important;
        }
        /* Better hover effect */
        #txn_categorization-transactions_table tbody tr:hover {
          background-color: #f0f0f0 !important;
        }
      "))
    ),
    
    fluidRow(
      box(
        title = "Budget Tracking",
        status = "warning",
        solidHeader = TRUE,
        width = 12,
        uiOutput(ns("budget_tracking"))
      )
    ),
    
    fluidRow(
      box(
        title = "Category Totals (Current Expenses)",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        uiOutput(ns("category_totals"))
      )
    ),
    
    fluidRow(
      box(
        title = "Save/Load Data",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        fluidRow(
          column(3,
                 fileInput(ns("load_csv_files"), "Load from CSV Files:",
                           multiple = TRUE, accept = c(".csv", "text/csv"),
                           placeholder = "Select CSV files", buttonLabel = "Browse...")
          ),
          column(3,
                 fileInput(ns("load_excel_file"), "Load from Excel File:",
                           multiple = FALSE, accept = c(".xlsx"),
                           placeholder = "Select Excel file", buttonLabel = "Browse...")
          ),
          column(3,
                 textInput(ns("save_filename"), "File Name:", value = "transaction_categorization", width = "100%")
          ),
          column(3,
                 br(),
                 downloadButton(ns("download_transactions"), "Download Excel", 
                                class = "btn-success", style = "width: 100%;")
          )
        ),
        uiOutput(ns("load_status"))
      )
    ),
    
    fluidRow(
      box(
        title = "Transaction Categorization",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        p(strong("Instructions:"), "Load transactions from CSV or Excel files. Select ONE category per transaction by entering 1."),
        hr(),
        DT::dataTableOutput(ns("transactions_table")),
        hr(),
        p(strong("Note:"), "All data and selections are kept in memory.")
      )
    )
  )
}

transactionCategorizationServer <- function(id, shared_rv) {
  moduleServer(id, function(input, output, session) {
    
    rv <- reactiveValues(transactions_data = NULL)
    
    calculate_totals <- reactive({
      req(rv$transactions_data)
      data <- rv$transactions_data
      list(
        In = sum(as.numeric(data$In), na.rm = TRUE),
        Labour = sum(as.numeric(data$Expense[data$Labour == 1]), na.rm = TRUE),
        Overheads = sum(as.numeric(data$Expense[data$Overheads == 1]), na.rm = TRUE),
        Materials = sum(as.numeric(data$Expense[data$Materials == 1]), na.rm = TRUE),
        Capital_Usage = sum(as.numeric(data$Expense[data$Capital_Usage == 1]), na.rm = TRUE),
        TS = sum(as.numeric(data$Expense[data$TS == 1]), na.rm = TRUE),
        Contractor = sum(as.numeric(data$Expense[data$Contractor == 1]), na.rm = TRUE),
        NC_Fees = sum(as.numeric(data$Expense[data$NC_Fees == 1]), na.rm = TRUE),
        Other = sum(as.numeric(data$Expense[data$Other == 1]), na.rm = TRUE)
      )
    })
    
    output$budget_tracking <- renderUI({
      if (is.null(shared_rv$budget_data) || nrow(shared_rv$budget_data) == 0) {
        return(tags$div(
          class = "alert alert-info",
          style = "font-size: 16px;",
          tags$strong("No Budget Data: "),
          "Go to 'Quarterly Budget' tab and click 'Transfer Budget to Transaction Tab'."
        ))
      }
      
      budget <- shared_rv$budget_data[nrow(shared_rv$budget_data), ]
      totals <- if (!is.null(rv$transactions_data)) calculate_totals() else list(
        Labour = 0, Overheads = 0, Materials = 0, Capital_Usage = 0, 
        TS = 0, Contractor = 0, NC_Fees = 0, Other = 0
      )
      
      categories <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor", "NC_Fees", "Other")
      budget_values <- sapply(categories, function(cat) {
        if (cat %in% names(budget)) as.numeric(budget[[cat]]) else 0
      })
      expense_values <- sapply(categories, function(cat) totals[[cat]])
      remaining_values <- budget_values - expense_values
      percent_used <- ifelse(budget_values > 0, (expense_values / budget_values) * 100, 0)
      
      tagList(
        tags$h4(paste("Budget Period:", budget$Quarter), 
                style = "color: white; margin-bottom: 15px; background-color: #3c8dbc; padding: 10px; border-radius: 4px;"),
        tags$div(
          style = "overflow-x: auto;",
          tags$table(
            class = "table table-bordered",
            style = "background-color: white; margin-bottom: 0; border: 2px solid #ddd;",
            tags$thead(
              tags$tr(
                tags$th("", style = "background-color: #222d32; color: white; font-weight: bold; padding: 12px; font-size: 14px;"),
                lapply(categories, function(cat) {
                  tags$th(cat, style = "background-color: #222d32; color: white; text-align: center; padding: 12px; font-size: 14px; font-weight: bold;")
                })
              )
            ),
            tags$tbody(
              tags$tr(
                tags$td(tags$strong("Available Budget"), 
                        style = "background-color: #ecf0f1; font-weight: bold; padding: 10px; color: #2c3e50; font-size: 13px;"),
                lapply(budget_values, function(val) {
                  tags$td(sprintf("£%.2f", val), 
                          style = "text-align: right; background-color: #ffffff; padding: 10px; color: #2c3e50; font-weight: 600; font-size: 13px;")
                })
              ),
              tags$tr(
                tags$td(tags$strong("Current Expenses"), 
                        style = "background-color: #ecf0f1; font-weight: bold; padding: 10px; color: #2c3e50; font-size: 13px;"),
                lapply(expense_values, function(val) {
                  tags$td(sprintf("£%.2f", val), 
                          style = "text-align: right; background-color: #fff8dc; padding: 10px; color: #856404; font-weight: 600; font-size: 13px;")
                })
              ),
              tags$tr(
                tags$td(tags$strong("Remaining Budget"), 
                        style = "background-color: #ecf0f1; font-weight: bold; padding: 10px; color: #2c3e50; font-size: 13px;"),
                lapply(1:length(remaining_values), function(i) {
                  val <- remaining_values[i]
                  if (val < 0) {
                    bg_color <- "#f8d7da"
                    text_color <- "#721c24"
                  } else {
                    bg_color <- "#d4edda"
                    text_color <- "#155724"
                  }
                  tags$td(sprintf("£%.2f", val), 
                          style = paste0("text-align: right; background-color: ", bg_color, 
                                         "; padding: 10px; color: ", text_color, "; font-weight: 700; font-size: 13px;"))
                })
              ),
              tags$tr(
                tags$td(tags$strong("% Used"), 
                        style = "background-color: #ecf0f1; font-weight: bold; padding: 10px; color: #2c3e50; font-size: 13px;"),
                lapply(1:length(percent_used), function(i) {
                  pct <- percent_used[i]
                  if (pct > 100) {
                    bg_color <- "#f8d7da"
                    text_color <- "#721c24"
                  } else if (pct > 80) {
                    bg_color <- "#fff3cd"
                    text_color <- "#856404"
                  } else {
                    bg_color <- "#d1ecf1"
                    text_color <- "#0c5460"
                  }
                  tags$td(sprintf("%.2f%%", pct), 
                          style = paste0("text-align: right; background-color: ", bg_color, 
                                         "; padding: 10px; color: ", text_color, "; font-weight: 700; font-size: 13px;"))
                })
              )
            )
          )
        )
      )
    })
    
    output$category_totals <- renderUI({
      totals <- calculate_totals()
      
      create_total_box <- function(label, value, is_income = FALSE) {
        bg_color <- if (is_income) "#28a745" else "#dc3545"
        tags$div(
          style = paste0("background-color: ", bg_color, "; padding: 15px; border-radius: 5px; text-align: center; box-shadow: 0 2px 4px rgba(0,0,0,0.1);"),
          tags$h5(label, style = "margin: 0; color: white; font-weight: 600;"),
          tags$h3(sprintf("£%.2f", value), style = "margin: 5px 0 0 0; color: white; font-weight: bold;")
        )
      }
      
      tagList(
        fluidRow(
          column(2, create_total_box("Total In", totals$In, TRUE)),
          column(2, create_total_box("Labour", totals$Labour)),
          column(2, create_total_box("Overheads", totals$Overheads)),
          column(2, create_total_box("Materials", totals$Materials)),
          column(2, create_total_box("Capital Usage", totals$Capital_Usage)),
          column(2, create_total_box("TS", totals$TS))
        ),
        br(),
        fluidRow(
          column(2, create_total_box("Contractor", totals$Contractor)),
          column(2, create_total_box("NC Fees", totals$NC_Fees)),
          column(2, create_total_box("Other", totals$Other))
        )
      )
    })
    
    observeEvent(input$load_csv_files, {
      req(input$load_csv_files)
      tryCatch({
        all_data <- list()
        for (i in 1:nrow(input$load_csv_files)) {
          csv_data <- read.csv(input$load_csv_files$datapath[i], stringsAsFactors = FALSE)
          if (!all(c("Date", "Details", "In", "Out") %in% names(csv_data))) next
          
          # Process data without dplyr pipeline
          csv_data$Date_parsed <- as.Date(csv_data$Date, format = "%d/%m/%Y")
          csv_data$Date <- format(csv_data$Date_parsed, "%Y-%m-%d")
          csv_data$Details <- as.character(csv_data$Details)
          csv_data$In <- ifelse(is.na(csv_data$In) | csv_data$In == "", 0, as.numeric(csv_data$In))
          csv_data$Expense <- ifelse(is.na(csv_data$Out) | csv_data$Out == "", 0, as.numeric(csv_data$Out))
          csv_data$Labour <- 0L
          csv_data$Overheads <- 0L
          csv_data$Materials <- 0L
          csv_data$Capital_Usage <- 0L
          csv_data$TS <- 0L
          csv_data$Contractor <- 0L
          csv_data$NC_Fees <- 0L
          csv_data$Other <- 0L
          
          # Sort by date
          csv_data <- csv_data[order(csv_data$Date_parsed), ]
          
          # Keep only required columns
          csv_data <- csv_data[, c("Date", "Details", "In", "Expense", "Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor", "NC_Fees", "Other")]
          
          all_data[[i]] <- csv_data
        }
        if (length(all_data) > 0) {
          rv$transactions_data <- do.call(rbind, all_data)
          output$load_status <- renderUI({
            tags$div(class = "alert alert-success", tags$strong("✓ CSV Loaded: "), 
                     sprintf("%d transactions", nrow(rv$transactions_data)))
          })
        }
      }, error = function(e) {
        showModal(modalDialog(title = "Error Loading CSV", paste("Failed:", e$message), easyClose = TRUE, footer = modalButton("OK")))
      })
    })
    
    observeEvent(input$load_excel_file, {
      req(input$load_excel_file)
      tryCatch({
        excel_data <- openxlsx::read.xlsx(input$load_excel_file$datapath, sheet = 1)
        required_cols <- c("Date", "Details", "In", "Expense", "Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor", "NC_Fees", "Other")
        if (!all(required_cols %in% names(excel_data))) {
          showModal(modalDialog(title = "Invalid Excel File", "Missing required columns", easyClose = TRUE, footer = modalButton("OK")))
          return()
        }
        
        # Process data without dplyr pipeline to avoid namespace issues
        excel_data$Date_parsed <- as.Date(excel_data$Date, format = "%d/%m/%Y")
        excel_data$Date <- format(excel_data$Date_parsed, "%Y-%m-%d")
        excel_data$Details <- as.character(excel_data$Details)
        excel_data$In <- as.numeric(excel_data$In)
        excel_data$Expense <- as.numeric(excel_data$Expense)
        excel_data$Labour <- as.integer(excel_data$Labour)
        excel_data$Overheads <- as.integer(excel_data$Overheads)
        excel_data$Materials <- as.integer(excel_data$Materials)
        excel_data$Capital_Usage <- as.integer(excel_data$Capital_Usage)
        excel_data$TS <- as.integer(excel_data$TS)
        excel_data$Contractor <- as.integer(excel_data$Contractor)
        excel_data$NC_Fees <- as.integer(excel_data$NC_Fees)
        excel_data$Other <- as.integer(excel_data$Other)
        
        # Sort by date
        excel_data <- excel_data[order(excel_data$Date_parsed), ]
        
        # Remove temporary date column
        excel_data$Date_parsed <- NULL
        
        # Keep only required columns in correct order
        excel_data <- excel_data[, c("Date", "Details", "In", "Expense", "Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor", "NC_Fees", "Other")]
        
        rv$transactions_data <- excel_data
        output$load_status <- renderUI({
          tags$div(class = "alert alert-success", tags$strong("✓ Excel Loaded: "), sprintf("%d transactions", nrow(excel_data)))
        })
      }, error = function(e) {
        showModal(modalDialog(title = "Error Loading Excel", paste("Failed:", e$message), easyClose = TRUE, footer = modalButton("OK")))
      })
    })
    
    output$transactions_table <- DT::renderDataTable({
      req(rv$transactions_data)
      
      dt <- DT::datatable(
        rv$transactions_data, 
        editable = list(target = 'cell', disable = list(columns = c(0, 1, 2, 3))),
        options = list(
          pageLength = 50,
          scrollX = TRUE,
          dom = 'Bfrtip',
          order = list(list(0, 'asc')),
          stateSave = TRUE,
          columnDefs = list(
            list(className = 'dt-center', targets = 4:11)
          )
        ),
        rownames = FALSE
      ) %>%
        DT::formatCurrency(columns = c("In", "Expense"), currency = "£", digits = 2) %>%
        DT::formatStyle(
          columns = c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor", "NC_Fees", "Other"),
          backgroundColor = DT::styleEqual(c(0, 1), c('white', '#28a745')),
          color = DT::styleEqual(c(0, 1), c('#333333', 'white')),
          fontWeight = DT::styleEqual(c(0, 1), c('normal', 'bold')),
          fontSize = '14px'
        )
      
      dt
    })
    
    observeEvent(input$transactions_table_cell_edit, {
      info <- input$transactions_table_cell_edit
      i <- info$row; j <- info$col + 1; v <- info$value
      if (j >= 5 && j <= 12) {
        new_val <- as.integer(v)
        if (new_val %in% c(0, 1)) {
          if (new_val == 1) rv$transactions_data[i, 5:12] <- 0L
          rv$transactions_data[i, j] <- new_val
        }
      }
    })
    
    # Download with budget summary as second sheet
    output$download_transactions <- downloadHandler(
      filename = function() {
        clean_filename <- gsub("[^a-zA-Z0-9_-]", "_", input$save_filename)
        paste0(clean_filename, ".xlsx")
      },
      content = function(file) {
        req(rv$transactions_data)
        
        # Create workbook
        wb <- openxlsx::createWorkbook()
        
        # Sheet 1: Transactions
        openxlsx::addWorksheet(wb, "Transactions")
        openxlsx::writeData(wb, "Transactions", rv$transactions_data)
        
        # Sheet 2: Budget Summary (if budget exists)
        if (!is.null(shared_rv$budget_data) && nrow(shared_rv$budget_data) > 0) {
          budget <- shared_rv$budget_data[nrow(shared_rv$budget_data), ]
          totals <- calculate_totals()
          
          categories <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor", "NC_Fees", "Other")
          
          budget_summary <- data.frame(
            Category = c("Quarter", categories),
            Available_Budget = c(budget$Quarter, sapply(categories, function(cat) {
              if (cat %in% names(budget)) as.numeric(budget[[cat]]) else 0
            })),
            Current_Expenses = c("", sapply(categories, function(cat) totals[[cat]])),
            Remaining_Budget = c("", sapply(categories, function(cat) {
              budget_val <- if (cat %in% names(budget)) as.numeric(budget[[cat]]) else 0
              budget_val - totals[[cat]]
            })),
            Percent_Used = c("", sapply(categories, function(cat) {
              budget_val <- if (cat %in% names(budget)) as.numeric(budget[[cat]]) else 0
              if (budget_val > 0) (totals[[cat]] / budget_val) * 100 else 0
            })),
            stringsAsFactors = FALSE
          )
          
          openxlsx::addWorksheet(wb, "Budget Summary")
          openxlsx::writeData(wb, "Budget Summary", budget_summary)
          
          # Format the budget summary sheet
          header_style <- openxlsx::createStyle(fgFill = "#3c8dbc", fontColour = "white", textDecoration = "bold")
          openxlsx::addStyle(wb, "Budget Summary", header_style, rows = 1, cols = 1:5, gridExpand = TRUE)
        }
        
        # Save workbook
        openxlsx::saveWorkbook(wb, file, overwrite = TRUE)
      }
    )
  })
}