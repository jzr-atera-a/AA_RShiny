# Categorize Receipts Module

categorizeUI <- function(id) {
  ns <- NS(id)
  
  fluidRow(
    box(
      title = "Categorize Receipts",
      status = "info",
      solidHeader = TRUE,
      width = 12,
      p(strong("Instructions:"), "Edit the category columns to categorize receipts. Use 0 or 1 values (0 = unchecked, 1 = checked). Only ONE category should be set to 1 per receipt."),
      hr(),
      p(strong("Categories:"), "Labour, Overheads, Materials, Capital Usage (Capital_Usage), T&S (TS), Contractor"),
      hr(),
      p(strong("How it works:"), "When you set any category to 1, all other categories in that row automatically become 0 (radio button behavior). Category totals update automatically below."),
      hr(),
      textInput(
        ns("category_base_path"),
        "Category Folders Base Path:",
        value = file.path(getwd(), "categorized_receipts"),
        placeholder = "Enter path where category folders will be created"
      ),
      p(class = "text-muted", strong("Folders will be created:")),
      p(class = "text-muted", "Labour/, Overheads/, Materials/, Capital_Usage/, TS/, Contractor/"),
      p(class = "text-muted", strong("Example paths:")),
      p(class = "text-muted", "Windows: C:/Users/YourName/Documents/categorized_receipts"),
      p(class = "text-muted", "Mac/Linux: /home/username/Documents/categorized_receipts"),
      actionButton(ns("browse_category_folder"), "Show Path Info", 
                   class = "btn-info", icon = icon("info-circle")),
      hr(),
      actionButton(ns("save_categories"), "Save Categories to Excel", 
                   class = "btn-success", icon = icon("save")),
      actionButton(ns("copy_files_to_categories"), "Copy Files to Category Folders", 
                   class = "btn-warning", icon = icon("copy")),
      actionButton(ns("refresh_categorize"), "Refresh Data", 
                   class = "btn-info", icon = icon("refresh")),
      hr(),
      uiOutput(ns("category_totals_ui")),
      hr(),
      p(strong("Edit the table below:"), "Click on any cell in the category columns (columns 2-7) to edit. Other columns are read-only."),
      DT::dataTableOutput(ns("categorize_table"))
    )
  )
}

categorizeServer <- function(id, shared_rv) {
  moduleServer(id, function(input, output, session) {
    
    # Local reactive values
    rv <- reactiveValues(
      categorize_data = NULL,
      category_totals = NULL
    )
    
    # Function to calculate category totals
    calculate_category_totals <- function() {
      if (!is.null(rv$categorize_data)) {
        totals <- list(
          Labour = sum(rv$categorize_data$amount[rv$categorize_data$Labour == 1], na.rm = TRUE),
          Overheads = sum(rv$categorize_data$amount[rv$categorize_data$Overheads == 1], na.rm = TRUE),
          Materials = sum(rv$categorize_data$amount[rv$categorize_data$Materials == 1], na.rm = TRUE),
          Capital_Usage = sum(rv$categorize_data$amount[rv$categorize_data$Capital_Usage == 1], na.rm = TRUE),
          TS = sum(rv$categorize_data$amount[rv$categorize_data$TS == 1], na.rm = TRUE),
          Contractor = sum(rv$categorize_data$amount[rv$categorize_data$Contractor == 1], na.rm = TRUE)
        )
        rv$category_totals <- totals
      }
    }
    
    # Show path info
    observeEvent(input$browse_category_folder, {
      showNotification(
        "Enter the full folder path in the text box above. Six category folders will be created automatically inside this path.",
        type = "message",
        duration = 8
      )
    })
    
    # Refresh data
    observeEvent(input$refresh_categorize, {
      if (file.exists(shared_rv$excel_filename)) {
        data <- openxlsx::read.xlsx(shared_rv$excel_filename)
        
        # Add category columns if they don't exist
        category_cols <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor")
        for (col in category_cols) {
          if (!col %in% names(data)) {
            data[[col]] <- 0L
          } else {
            data[[col]] <- as.integer(data[[col]])
          }
        }
        
        # Ensure amount is numeric
        if ("amount" %in% names(data)) {
          data$amount <- as.numeric(data$amount)
        }
        
        rv$categorize_data <- data
        calculate_category_totals()
        showNotification("Data refreshed successfully", type = "message", duration = 2)
      } else {
        showNotification("No data file found", type = "warning", duration = 3)
      }
    })
    
    # Display category totals UI
    output$category_totals_ui <- renderUI({
      req(rv$category_totals)
      
      tags$div(
        class = "category-totals",
        tags$h4("Category Totals", style = "color: #7ec8e3; margin-bottom: 15px; font-weight: bold;"),
        tags$p("Sum of amounts for each category (only receipts with category = 1):", 
               style = "color: #c7d2fe; margin-bottom: 15px;"),
        lapply(names(rv$category_totals), function(cat) {
          tags$div(
            class = "category-total-item",
            tags$div(class = "category-total-label", gsub("_", " ", cat)),
            tags$div(class = "category-total-amount", 
                     paste0("£", format(rv$category_totals[[cat]], nsmall = 2, big.mark = ",")))
          )
        })
      )
    })
    
    # Display categorize table with editable checkboxes
    output$categorize_table <- DT::renderDataTable({
      # Auto-load data if not already loaded
      if (is.null(rv$categorize_data) && file.exists(shared_rv$excel_filename)) {
        data <- openxlsx::read.xlsx(shared_rv$excel_filename)
        
        # Add category columns if they don't exist
        category_cols <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor")
        for (col in category_cols) {
          if (!col %in% names(data)) {
            data[[col]] <- 0L
          } else {
            data[[col]] <- as.integer(data[[col]])
          }
        }
        
        # Ensure amount is numeric
        if ("amount" %in% names(data)) {
          data$amount <- as.numeric(data$amount)
        }
        
        rv$categorize_data <- data
        calculate_category_totals()
      }
      
      req(rv$categorize_data)
      
      # Reorder columns for display
      display_data <- rv$categorize_data[, c(
        "filename",
        "Labour",
        "Overheads",
        "Materials",
        "Capital_Usage",
        "TS",
        "Contractor",
        "receipt_id",
        "provider",
        "amount",
        "date",
        "description",
        "processed_timestamp"
      )]
      
      # Create editable datatable
      DT::datatable(
        display_data,
        editable = list(
          target = 'cell', 
          disable = list(columns = c(0, 7, 8, 9, 10, 11, 12))
        ),
        options = list(
          pageLength = 25,
          scrollX = TRUE,
          columnDefs = list(
            list(targets = 1:6, className = 'dt-center')
          ),
          order = list(list(12, 'desc'))
        ),
        rownames = FALSE
      )
    })
    
    # Handle cell edits in categorize table
    observeEvent(input$categorize_table_cell_edit, {
      info <- input$categorize_table_cell_edit
      row <- info$row
      col <- info$col + 1
      value <- as.integer(info$value)
      
      # In display order, category columns are 2-7
      if (col >= 2 && col <= 7) {
        # Map display column to original column
        original_col <- col + 6
        
        # Implement radio button behavior
        rv$categorize_data[row, 8:13] <- 0L
        if (value == 1) {
          rv$categorize_data[row, original_col] <- 1L
        }
        # Recalculate totals
        calculate_category_totals()
      }
    })
    
    # Save categories to Excel
    observeEvent(input$save_categories, {
      req(rv$categorize_data)
      
      # Ensure all category columns are integers
      category_cols <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor")
      for (col in category_cols) {
        if (col %in% names(rv$categorize_data)) {
          rv$categorize_data[[col]] <- as.integer(rv$categorize_data[[col]])
        }
      }
      
      # Ensure amount is numeric
      if ("amount" %in% names(rv$categorize_data)) {
        rv$categorize_data$amount <- as.numeric(rv$categorize_data$amount)
      }
      
      # Save to Excel file
      openxlsx::write.xlsx(rv$categorize_data, shared_rv$excel_filename)
      
      # Recalculate totals
      calculate_category_totals()
      
      # Show success notification
      showNotification("Categories saved successfully to Excel file!", 
                       type = "message", duration = 3)
    })
    
    # Copy files to category folders
    observeEvent(input$copy_files_to_categories, {
      req(rv$categorize_data)
      
      # Get base path from user input
      base_path <- input$category_base_path
      
      # Create base folder if it doesn't exist
      if (!dir.exists(base_path)) {
        dir.create(base_path, recursive = TRUE)
        showNotification(paste("Created base folder:", base_path), type = "message", duration = 3)
      }
      
      # Define category names
      categories <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor")
      
      # Create category folders
      for (cat in categories) {
        cat_folder <- file.path(base_path, cat)
        if (!dir.exists(cat_folder)) {
          dir.create(cat_folder, recursive = TRUE)
        }
      }
      
      # Show progress
      withProgress(message = 'Copying files to category folders...', value = 0, {
        copied_count <- 0
        skipped_count <- 0
        
        for (i in 1:nrow(rv$categorize_data)) {
          row <- rv$categorize_data[i, ]
          filename <- row$filename
          source_path <- file.path(shared_rv$receipts_folder, filename)
          
          if (file.exists(source_path)) {
            # Find which category is selected (value = 1)
            category_selected <- FALSE
            for (cat in categories) {
              if (row[[cat]] == 1) {
                dest_path <- file.path(base_path, cat, filename)
                file.copy(source_path, dest_path, overwrite = TRUE)
                copied_count <- copied_count + 1
                category_selected <- TRUE
                break
              }
            }
            if (!category_selected) {
              skipped_count <- skipped_count + 1
            }
          } else {
            skipped_count <- skipped_count + 1
          }
          
          incProgress(1/nrow(rv$categorize_data))
        }
        
        # Show completion message
        showNotification(
          paste0("File copy complete!\n",
                 "Copied: ", copied_count, " file(s)\n",
                 "Skipped: ", skipped_count, " file(s) (no category or file not found)"),
          type = "message",
          duration = 8
        )
      })
    })
    
  })
}
