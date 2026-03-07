library(shiny)
library(shinydashboard)

# Source all modules
source("modules/settings_module.R")
source("modules/pdf_converter_module.R")
source("modules/to_pdf_converter_module.R")
source("modules/upload_module.R")
source("modules/data_view_module.R")
source("modules/categorize_module.R")
source("modules/statements_to_table_module.R")
source("modules/budget_module.R")
source("modules/transaction_categorization_module.R")
source("utils/api_utils.R")
source("utils/file_utils.R")
source("ui/styles.R")

# UI Definition
ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = "Receipt Processor"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Settings", tabName = "settings", icon = icon("cog")),
      menuItem("PDF to JPG Converter", tabName = "converter", icon = icon("file-image")),
      menuItem("Convert to PDF", tabName = "topdf", icon = icon("file-pdf")),
      menuItem("Upload Receipts", tabName = "upload", icon = icon("upload")),
      menuItem("View Processed Data", tabName = "data", icon = icon("table")),
      menuItem("Categorize Receipts", tabName = "categorize", icon = icon("tags")),
      menuItem("Statements to Table", tabName = "statements", icon = icon("file-invoice-dollar")),
      menuItem("Quarterly Budget", tabName = "budget", icon = icon("chart-line")),
      menuItem("Transaction Categorization", tabName = "txn_categorization", icon = icon("list-check"))
    )
  ),
  
  dashboardBody(
    # Include CSS styles
    includeCSS_styles(),
    
    tabItems(
      # Settings Tab
      tabItem(
        tabName = "settings",
        settingsUI("settings")
      ),
      
      # PDF to JPG Converter Tab
      tabItem(
        tabName = "converter",
        pdfConverterUI("pdf_converter")
      ),
      
      # Convert to PDF Tab
      tabItem(
        tabName = "topdf",
        toPdfConverterUI("to_pdf_converter")
      ),
      
      # Upload Tab
      tabItem(
        tabName = "upload",
        uploadUI("upload")
      ),
      
      # Data View Tab
      tabItem(
        tabName = "data",
        dataViewUI("data_view")
      ),
      
      # Categorize Tab
      tabItem(
        tabName = "categorize",
        categorizeUI("categorize")
      ),
      
      # Statements to Table Tab
      tabItem(
        tabName = "statements",
        statementsToTableUI("statements")
      ),
      
      # Quarterly Budget Tab
      tabItem(
        tabName = "budget",
        budgetUI("budget")
      ),
      
      # Transaction Categorization Tab
      tabItem(
        tabName = "txn_categorization",
        transactionCategorizationUI("txn_categorization")
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Shared reactive values across all modules
  shared_rv <- reactiveValues(
    api_key = NULL,
    receipts_folder = "receipts",
    excel_filename = "receipt_data.xlsx",
    budget_file_path = NULL,
    budget_data = NULL
  )
  
  # Initialize folders and files on startup
  observe({
    # Create receipts folder if it doesn't exist
    if (!dir.exists(shared_rv$receipts_folder)) {
      dir.create(shared_rv$receipts_folder, recursive = TRUE)
    }
    
    # Create Excel file with headers if it doesn't exist
    if (!file.exists(shared_rv$excel_filename)) {
      empty_df <- data.frame(
        receipt_id = character(),
        filename = character(),
        provider = character(),
        amount = numeric(),
        date = character(),
        description = character(),
        processed_timestamp = character(),
        Labour = integer(),
        Overheads = integer(),
        Materials = integer(),
        Capital_Usage = integer(),
        TS = integer(),
        Contractor = integer(),
        stringsAsFactors = FALSE
      )
      openxlsx::write.xlsx(empty_df, shared_rv$excel_filename)
    }
  })
  
  # Call all module servers
  settingsServer("settings", shared_rv)
  pdfConverterServer("pdf_converter", shared_rv)
  toPdfConverterServer("to_pdf_converter", shared_rv)
  uploadServer("upload", shared_rv)
  dataViewServer("data_view", shared_rv)
  categorizeServer("categorize", shared_rv)
  statementsToTableServer("statements", shared_rv)
  budgetServer("budget", shared_rv)
  transactionCategorizationServer("txn_categorization", shared_rv)
}

# Run the application
shinyApp(ui = ui, server = server)