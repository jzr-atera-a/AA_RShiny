# modules/Receipt Processor/receipt_categorize.R
# Subtab: Categorize Receipts

receipt_categorize_ui <- function(id) {
  ns <- NS(id)

  fluidRow(
    box(title = "Categorize Receipts", status = "info", solidHeader = TRUE, width = 12,
        p(strong("Instructions:"), "Edit the category columns to categorize receipts. Use 0 or 1 values (0 = unchecked, 1 = checked). Only ONE category should be set to 1 per receipt."),
        hr(),
        p(strong("Categories:"), "Labour, Overheads, Materials, Capital Usage (Capital_Usage), T&S (TS), Contractor"),
        hr(),
        p(strong("How it works:"), "When you set any category to 1, all other categories in that row automatically become 0 (radio button behavior). Category totals update automatically below."),
        hr(),
        textInput(ns("category_base_path"), "Category Folders Base Path:", value = file.path(getwd(), "categorized_receipts"),
                  placeholder = "Enter path where category folders will be created"),
        p(class = "text-muted", strong("Folders will be created:")),
        p(class = "text-muted", "Labour/, Overheads/, Materials/, Capital_Usage/, TS/, Contractor/"),
        p(class = "text-muted", strong("Example paths:")),
        p(class = "text-muted", "Windows: C:/Users/YourName/Documents/categorized_receipts"),
        p(class = "text-muted", "Mac/Linux: /home/username/Documents/categorized_receipts"),
        actionButton(ns("browse_category_folder"), "Show Path Info", class = "btn-info", icon = icon("info-circle")),
        hr(),
        actionButton(ns("save_categories"), "Save Categories to Excel", class = "btn-success", icon = icon("save")),
        actionButton(ns("copy_files_to_categories"), "Copy Files to Category Folders", class = "btn-warning", icon = icon("copy")),
        actionButton(ns("refresh_categorize"), "Refresh Data", class = "btn-info", icon = icon("refresh")),
        hr(),
        uiOutput(ns("category_totals_ui")),
        hr(),
        p(strong("Edit the table below:"), "Click on any cell in the category columns (columns 2-7) to edit. Other columns are read-only."),
        DT::dataTableOutput(ns("categorize_table")))
  )
}

receipt_categorize_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    rv <- reactiveValues(categorize_data = NULL, category_totals = NULL)
    category_cols <- c("Labour", "Overheads", "Materials", "Capital_Usage", "TS", "Contractor")

    calculate_category_totals <- function() {
      if (!is.null(rv$categorize_data)) {
        rv$category_totals <- setNames(
          lapply(category_cols, function(cat) sum(rv$categorize_data$amount[rv$categorize_data[[cat]] == 1], na.rm = TRUE)),
          category_cols
        )
      }
    }

    load_data <- function() {
      if (file.exists(api_manager$receipt_excel_filename)) {
        data <- openxlsx::read.xlsx(api_manager$receipt_excel_filename)
        for (col in category_cols) {
          if (!col %in% names(data)) data[[col]] <- 0L else data[[col]] <- as.integer(data[[col]])
        }
        if ("amount" %in% names(data)) data$amount <- as.numeric(data$amount)
        rv$categorize_data <- data
        calculate_category_totals()
      }
    }

    observeEvent(input$browse_category_folder, {
      showNotification("Enter the full folder path in the text box above. Six category folders will be created automatically inside this path.",
                       type = "message", duration = 8)
    })

    observeEvent(input$refresh_categorize, {
      if (file.exists(api_manager$receipt_excel_filename)) {
        load_data()
        showNotification("Data refreshed successfully", type = "message", duration = 2)
      } else {
        showNotification("No data file found", type = "warning", duration = 3)
      }
    })

    output$category_totals_ui <- renderUI({
      req(rv$category_totals)
      tags$div(class = "category-totals",
               tags$h4("Category Totals", style = "color: #7ec8e3; margin-bottom: 15px; font-weight: bold;"),
               tags$p("Sum of amounts for each category (only receipts with category = 1):", style = "color: #c7d2fe; margin-bottom: 15px;"),
               lapply(names(rv$category_totals), function(cat) {
                 tags$div(class = "category-total-item",
                          tags$div(class = "category-total-label", gsub("_", " ", cat)),
                          tags$div(class = "category-total-amount", paste0("£", format(rv$category_totals[[cat]], nsmall = 2, big.mark = ","))))
               }))
    })

    output$categorize_table <- DT::renderDataTable({
      if (is.null(rv$categorize_data) && file.exists(api_manager$receipt_excel_filename)) load_data()
      req(rv$categorize_data)

      display_data <- rv$categorize_data[, c("filename", category_cols, "receipt_id", "provider", "amount", "date", "description", "processed_timestamp")]

      DT::datatable(display_data,
                    editable = list(target = 'cell', disable = list(columns = c(0, 7, 8, 9, 10, 11, 12))),
                    options = list(pageLength = 25, scrollX = TRUE,
                                   columnDefs = list(list(targets = 1:6, className = 'dt-center')),
                                   order = list(list(12, 'desc'))),
                    rownames = FALSE)
    })

    observeEvent(input$categorize_table_cell_edit, {
      info <- input$categorize_table_cell_edit
      row <- info$row
      col <- info$col + 1
      value <- as.integer(info$value)

      if (col >= 2 && col <= 7) {
        original_col <- col + 6
        rv$categorize_data[row, 8:13] <- 0L
        if (value == 1) rv$categorize_data[row, original_col] <- 1L
        calculate_category_totals()
      }
    })

    observeEvent(input$save_categories, {
      req(rv$categorize_data)
      for (col in category_cols) if (col %in% names(rv$categorize_data)) rv$categorize_data[[col]] <- as.integer(rv$categorize_data[[col]])
      if ("amount" %in% names(rv$categorize_data)) rv$categorize_data$amount <- as.numeric(rv$categorize_data$amount)

      openxlsx::write.xlsx(rv$categorize_data, api_manager$receipt_excel_filename)
      calculate_category_totals()
      showNotification("Categories saved successfully to Excel file!", type = "message", duration = 3)
    })

    observeEvent(input$copy_files_to_categories, {
      req(rv$categorize_data)

      base_path <- input$category_base_path
      if (!dir.exists(base_path)) {
        dir.create(base_path, recursive = TRUE)
        showNotification(paste("Created base folder:", base_path), type = "message", duration = 3)
      }

      for (cat in category_cols) {
        cat_folder <- file.path(base_path, cat)
        if (!dir.exists(cat_folder)) dir.create(cat_folder, recursive = TRUE)
      }

      withProgress(message = 'Copying files to category folders...', value = 0, {
        copied_count <- 0
        skipped_count <- 0

        for (i in 1:nrow(rv$categorize_data)) {
          row <- rv$categorize_data[i, ]
          source_path <- file.path(api_manager$receipt_folder, row$filename)

          if (file.exists(source_path)) {
            category_selected <- FALSE
            for (cat in category_cols) {
              if (row[[cat]] == 1) {
                file.copy(source_path, file.path(base_path, cat, row$filename), overwrite = TRUE)
                copied_count <- copied_count + 1
                category_selected <- TRUE
                break
              }
            }
            if (!category_selected) skipped_count <- skipped_count + 1
          } else {
            skipped_count <- skipped_count + 1
          }

          incProgress(1 / nrow(rv$categorize_data))
        }

        showNotification(paste0("File copy complete!\nCopied: ", copied_count, " file(s)\nSkipped: ", skipped_count, " file(s) (no category or file not found)"),
                         type = "message", duration = 8)
      })
    })
  })
}
