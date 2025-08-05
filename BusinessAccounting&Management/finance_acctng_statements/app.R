library(shiny)
library(shinydashboard)
library(DT)
library(openxlsx)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Balance Sheet Financial Statement Dashboard"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Balance Sheet Overview", tabName = "overview", icon = icon("info-circle")),
      menuItem("Interactive Template", tabName = "template", icon = icon("edit")),
      menuItem("Income Statement Overview", tabName = "income_overview", icon = icon("chart-line")),
      menuItem("Cash Flow Overview", tabName = "cashflow_overview", icon = icon("exchange-alt"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #2c3e50 !important;
        }
        .main-header .navbar {
          background-color: #34495e !important;
        }
        .main-header .logo {
          background-color: #2c3e50 !important;
        }
        .main-sidebar {
          background-color: #2c3e50 !important;
        }
        .sidebar-menu > li > a {
          color: #ecf0f1 !important;
        }
        .box {
          background-color: #34495e !important;
          border: 1px solid #4a5568 !important;
        }
        .box-header {
          color: #ecf0f1 !important;
        }
        .box-body {
          color: #ecf0f1 !important;
        }
        h1, h2, h3, h4, h5, h6, p, li {
          color: #ecf0f1 !important;
        }
        .form-control {
          background-color: #4a5568 !important;
          border: 1px solid #6c757d !important;
          color: #ecf0f1 !important;
        }
        .form-control:focus {
          background-color: #4a5568 !important;
          border-color: #17a2b8 !important;
          color: #ecf0f1 !important;
        }
        .btn-primary {
          background-color: #17a2b8 !important;
          border-color: #17a2b8 !important;
        }
        .dataTables_wrapper {
          color: #ecf0f1 !important;
        }
        table.dataTable {
          background-color: #34495e !important;
          color: #ecf0f1 !important;
        }
        table.dataTable thead th {
          background-color: #2c3e50 !important;
          color: #ecf0f1 !important;
        }
      "))
    ),
    
    tabItems(
      # Balance Sheet Overview Tab
      tabItem(tabName = "overview",
              fluidRow(
                box(
                  title = "Balance Sheet Statement - Detailed Overview", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  h3("What is a Balance Sheet?"),
                  p("The Balance Sheet is a financial statement that provides a snapshot of a company's financial position at a specific point in time. It follows the fundamental accounting equation:"),
                  h4("Assets = Liabilities + Shareholders' Equity"),
                  
                  h3("Key Components:"),
                  
                  h4("1. ASSETS (Resources and Financing Sources)"),
                  h5("Current Assets (converted to cash within one year):"),
                  tags$ul(
                    tags$li("Cash and Cash Equivalents"),
                    tags$li("Short-term Investments"),
                    tags$li("Accounts Receivable"),
                    tags$li("Inventory"),
                    tags$li("Prepaid Expenses"),
                    tags$li("Other Current Assets")
                  ),
                  
                  h5("Non-Current Assets (long-term resources):"),
                  tags$ul(
                    tags$li("Property, Plant & Equipment (PPE)"),
                    tags$li("Intangible Assets"),
                    tags$li("Long-term Investments"),
                    tags$li("Goodwill"),
                    tags$li("Other Non-Current Assets")
                  ),
                  
                  h4("2. LIABILITIES (What the company owes)"),
                  h5("Current Liabilities (due within one year):"),
                  tags$ul(
                    tags$li("Accounts Payable"),
                    tags$li("Short-term Debt"),
                    tags$li("Accrued Expenses"),
                    tags$li("Current Portion of Long-term Debt"),
                    tags$li("Other Current Liabilities")
                  ),
                  
                  h5("Non-Current Liabilities (long-term obligations):"),
                  tags$ul(
                    tags$li("Long-term Debt"),
                    tags$li("Deferred Tax Liabilities"),
                    tags$li("Pension Obligations"),
                    tags$li("Other Non-Current Liabilities")
                  ),
                  
                  h4("3. SHAREHOLDERS' EQUITY (Ownership interest)"),
                  tags$ul(
                    tags$li("Common Stock"),
                    tags$li("Additional Paid-in Capital"),
                    tags$li("Retained Earnings"),
                    tags$li("Accumulated Other Comprehensive Income"),
                    tags$li("Treasury Stock (if applicable)")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Example: Apple Inc. Consolidated Balance Sheet (Simplified)", 
                  status = "info", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  p("Based on Apple's recent annual report (amounts in millions):"),
                  
                  DT::dataTableOutput("apple_balance_sheet")
                )
              )
      ),
      
      # Interactive Template Tab
      tabItem(tabName = "template",
              fluidRow(
                box(
                  title = "Balance Sheet Template - Enter Your Company Data", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(6,
                           h4("Company Information"),
                           textInput("company_name", "Company Name:", value = "Your Company Name"),
                           dateInput("report_date", "As of Date:", value = Sys.Date()),
                           br(),
                           
                           h4("ASSETS"),
                           h5("Current Assets"),
                           numericInput("cash", "Cash and Cash Equivalents ($):", value = 0, min = 0),
                           numericInput("receivables", "Accounts Receivable ($):", value = 0, min = 0),
                           numericInput("inventory", "Inventory ($):", value = 0, min = 0),
                           numericInput("prepaid", "Prepaid Expenses ($):", value = 0, min = 0),
                           numericInput("other_current_assets", "Other Current Assets ($):", value = 0, min = 0),
                           
                           h5("Non-Current Assets"),
                           numericInput("ppe", "Property, Plant & Equipment (net) ($):", value = 0, min = 0),
                           numericInput("intangible", "Intangible Assets ($):", value = 0, min = 0),
                           numericInput("goodwill", "Goodwill ($):", value = 0, min = 0),
                           numericInput("other_noncurrent_assets", "Other Non-Current Assets ($):", value = 0, min = 0)
                    ),
                    
                    column(6,
                           h4("LIABILITIES"),
                           h5("Current Liabilities"),
                           numericInput("accounts_payable", "Accounts Payable ($):", value = 0, min = 0),
                           numericInput("short_term_debt", "Short-term Debt ($):", value = 0, min = 0),
                           numericInput("accrued_expenses", "Accrued Expenses ($):", value = 0, min = 0),
                           numericInput("other_current_liab", "Other Current Liabilities ($):", value = 0, min = 0),
                           
                           h5("Non-Current Liabilities"),
                           numericInput("long_term_debt", "Long-term Debt ($):", value = 0, min = 0),
                           numericInput("deferred_tax", "Deferred Tax Liabilities ($):", value = 0, min = 0),
                           numericInput("other_noncurrent_liab", "Other Non-Current Liabilities ($):", value = 0, min = 0),
                           
                           h4("SHAREHOLDERS' EQUITY"),
                           numericInput("common_stock", "Common Stock ($):", value = 0, min = 0),
                           numericInput("additional_paid", "Additional Paid-in Capital ($):", value = 0, min = 0),
                           numericInput("retained_earnings", "Retained Earnings ($):", value = 0, min = 0),
                           numericInput("other_equity", "Other Comprehensive Income ($):", value = 0)
                    )
                  ),
                  
                  br(),
                  fluidRow(
                    column(12, align = "center",
                           actionButton("generate_statement", "Generate Balance Sheet", 
                                        class = "btn-primary btn-lg"),
                           br(), br(),
                           downloadButton("download_excel", "Download as Excel", 
                                          class = "btn-success btn-lg")
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Generated Balance Sheet", 
                  status = "success", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  DT::dataTableOutput("generated_balance_sheet")
                )
              )
      ),
      
      # Income Statement Overview Tab
      tabItem(tabName = "income_overview",
              fluidRow(
                box(
                  title = "Income Statement - Detailed Overview", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  h3("What is an Income Statement?"),
                  p("The Income Statement (also called Profit & Loss Statement or P&L) shows a company's financial performance over a specified period of time. It measures profitability by showing revenues, expenses, and the resulting net income."),
                  
                  h3("Key Characteristics:"),
                  tags$ul(
                    tags$li("Reported for a specified period of time (monthly, quarterly, annually)"),
                    tags$li("Uses accrual-based accounting (revenue recognized when earned, expenses when incurred)"),
                    tags$li("Shows the company's ability to generate profit from operations"),
                    tags$li("Follows the formula: Revenues - Expenses = Net Income")
                  ),
                  
                  h3("Key Components:"),
                  
                  h4("1. REVENUES (Top Line)"),
                  tags$ul(
                    tags$li("Net Sales/Revenue - primary business income"),
                    tags$li("Other Operating Revenues"),
                    tags$li("Non-Operating Income (interest, dividends, gains on investments)")
                  ),
                  
                  h4("2. COST OF GOODS SOLD (COGS)"),
                  tags$ul(
                    tags$li("Direct costs of producing goods/services"),
                    tags$li("Raw materials, direct labor, manufacturing overhead"),
                    tags$li("Gross Profit = Revenue - COGS")
                  ),
                  
                  h4("3. OPERATING EXPENSES"),
                  tags$ul(
                    tags$li("Selling, General & Administrative (SG&A) expenses"),
                    tags$li("Research & Development (R&D)"),
                    tags$li("Marketing and advertising"),
                    tags$li("Depreciation and amortization"),
                    tags$li("Other operating expenses")
                  ),
                  
                  h4("4. NON-OPERATING ITEMS"),
                  tags$ul(
                    tags$li("Interest expense"),
                    tags$li("Interest income"),
                    tags$li("Gains/losses on asset sales"),
                    tags$li("Foreign exchange gains/losses")
                  ),
                  
                  h4("5. TAXES AND NET INCOME"),
                  tags$ul(
                    tags$li("Income tax expense"),
                    tags$li("Net Income (Bottom Line)"),
                    tags$li("Earnings per Share (EPS)")
                  ),
                  
                  h3("Key Metrics Derived:"),
                  tags$ul(
                    tags$li("Gross Profit Margin = (Gross Profit / Revenue) × 100"),
                    tags$li("Operating Margin = (Operating Income / Revenue) × 100"),
                    tags$li("Net Profit Margin = (Net Income / Revenue) × 100"),
                    tags$li("EBITDA = Earnings Before Interest, Taxes, Depreciation & Amortization")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Example: Microsoft Corporation Income Statement (Simplified)", 
                  status = "info", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  p("Based on Microsoft's recent annual report (amounts in millions):"),
                  
                  DT::dataTableOutput("microsoft_income_statement")
                )
              )
      ),
      
      # Cash Flow Statement Overview Tab
      tabItem(tabName = "cashflow_overview",
              fluidRow(
                box(
                  title = "Cash Flow Statement - Detailed Overview", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  h3("What is a Cash Flow Statement?"),
                  p("The Cash Flow Statement tracks the actual cash inflows and outflows during a specified period. Unlike the income statement which uses accrual accounting, this statement shows only actual cash movements, providing insight into the company's liquidity and cash management."),
                  
                  h3("Key Characteristics:"),
                  tags$ul(
                    tags$li("Reported for a specified period of time (same as income statement)"),
                    tags$li("Uses cash-based accounting (only actual cash movements)"),
                    tags$li("Shows change in cash from cash in- and outflows"),
                    tags$li("Reconciles beginning and ending cash balances"),
                    tags$li("Essential for assessing liquidity and financial flexibility")
                  ),
                  
                  h3("Three Main Categories:"),
                  
                  h4("1. OPERATING ACTIVITIES (Cash from core business operations)"),
                  h5("Cash Inflows:"),
                  tags$ul(
                    tags$li("Cash received from customers"),
                    tags$li("Interest and dividends received"),
                    tags$li("Other operating receipts")
                  ),
                  h5("Cash Outflows:"),
                  tags$ul(
                    tags$li("Cash paid to suppliers and employees"),
                    tags$li("Interest paid"),
                    tags$li("Income taxes paid"),
                    tags$li("Other operating payments")
                  ),
                  h5("Key Adjustments (Indirect Method):"),
                  tags$ul(
                    tags$li("Start with Net Income"),
                    tags$li("Add back non-cash expenses (depreciation, amortization)"),
                    tags$li("Adjust for changes in working capital"),
                    tags$li("Remove gains/losses on asset sales")
                  ),
                  
                  h4("2. INVESTING ACTIVITIES (Cash from investment-related transactions)"),
                  h5("Cash Inflows:"),
                  tags$ul(
                    tags$li("Sale of property, plant & equipment"),
                    tags$li("Sale of investments/securities"),
                    tags$li("Collection of loans made to others"),
                    tags$li("Proceeds from business disposals")
                  ),
                  h5("Cash Outflows:"),
                  tags$ul(
                    tags$li("Purchase of property, plant & equipment"),
                    tags$li("Purchase of investments/securities"),
                    tags$li("Loans made to others"),
                    tags$li("Business acquisitions")
                  ),
                  
                  h4("3. FINANCING ACTIVITIES (Cash from financing-related transactions)"),
                  h5("Cash Inflows:"),
                  tags$ul(
                    tags$li("Proceeds from issuing stock"),
                    tags$li("Proceeds from borrowing (loans, bonds)"),
                    tags$li("Other financing receipts")
                  ),
                  h5("Cash Outflows:"),
                  tags$ul(
                    tags$li("Dividend payments to shareholders"),
                    tags$li("Repurchase of company stock"),
                    tags$li("Repayment of debt"),
                    tags$li("Interest payments on debt")
                  ),
                  
                  h3("Key Analysis Points:"),
                  tags$ul(
                    tags$li("Positive operating cash flow indicates healthy core business"),
                    tags$li("Free Cash Flow = Operating Cash Flow - Capital Expenditures"),
                    tags$li("Cash flow quality: compare net income to operating cash flow"),
                    tags$li("Sustainable dividend payments require positive free cash flow")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Example: Amazon.com Inc. Cash Flow Statement (Simplified)", 
                  status = "info", 
                  solidHeader = TRUE,
                  width = 12,
                  
                  p("Based on Amazon's recent annual report (amounts in millions):"),
                  
                  DT::dataTableOutput("amazon_cashflow_statement")
                )
              )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Apple Balance Sheet Example
  output$apple_balance_sheet <- DT::renderDataTable({
    apple_data <- data.frame(
      "Item" = c(
        "ASSETS",
        "Current Assets:",
        "  Cash and Cash Equivalents",
        "  Short-term Investments", 
        "  Accounts Receivable",
        "  Inventories",
        "  Other Current Assets",
        "Total Current Assets",
        "",
        "Non-Current Assets:",
        "  Property, Plant & Equipment (net)",
        "  Other Non-Current Assets",
        "Total Non-Current Assets",
        "",
        "TOTAL ASSETS",
        "",
        "LIABILITIES AND SHAREHOLDERS' EQUITY",
        "Current Liabilities:",
        "  Accounts Payable",
        "  Other Current Liabilities",
        "Total Current Liabilities",
        "",
        "Non-Current Liabilities:",
        "  Long-term Debt",
        "  Other Non-Current Liabilities",
        "Total Non-Current Liabilities",
        "",
        "Total Liabilities",
        "",
        "Shareholders' Equity:",
        "  Common Stock and Additional Paid-in Capital",
        "  Retained Earnings",
        "Total Shareholders' Equity",
        "",
        "TOTAL LIABILITIES AND SHAREHOLDERS' EQUITY"
      ),
      "Amount_Millions" = c(
        "",
        "",
        "29,965",
        "31,590",
        "29,508",
        "6,331",
        "14,695",
        "112,089",
        "",
        "",
        "43,715",
        "217,350",
        "261,065",
        "",
        "373,154",
        "",
        "",
        "",
        "64,115",
        "58,829",
        "122,944",
        "",
        "",
        "123,930",
        "54,293",
        "178,223",
        "",
        "301,167",
        "",
        "",
        "73,812",
        "-1,825",
        "71,987",
        "",
        "373,154"
      )
    )
    
    DT::datatable(apple_data, 
                  options = list(dom = 't', pageLength = 50, ordering = FALSE),
                  rownames = FALSE,
                  colnames = c("Balance Sheet Item", "Amount ($ Millions)")) %>%
      DT::formatStyle(columns = 1:2, backgroundColor = "#34495e", color = "#ecf0f1")
  }, server = FALSE)
  
  # Microsoft Income Statement Example
  output$microsoft_income_statement <- DT::renderDataTable({
    microsoft_data <- data.frame(
      "Item" = c(
        "REVENUE",
        "  Product Revenue",
        "  Service Revenue", 
        "Total Revenue",
        "",
        "COST OF REVENUE",
        "  Product Cost",
        "  Service Cost",
        "Total Cost of Revenue",
        "",
        "GROSS PROFIT",
        "",
        "OPERATING EXPENSES",
        "  Research & Development",
        "  Sales & Marketing",
        "  General & Administrative",
        "Total Operating Expenses",
        "",
        "OPERATING INCOME",
        "",
        "OTHER INCOME (EXPENSE)",
        "  Interest Income",
        "  Interest Expense",
        "  Other, Net",
        "Total Other Income",
        "",
        "INCOME BEFORE TAXES",
        "Income Tax Expense",
        "",
        "NET INCOME",
        "",
        "EARNINGS PER SHARE",
        "  Basic",
        "  Diluted"
      ),
      "Amount_Millions" = c(
        "",
        "72,732",
        "135,620",
        "211,915",
        "",
        "",
        "16,017",
        "43,586",
        "65,525",
        "",
        "146,390",
        "",
        "",
        "27,195",
        "22,759",
        "7,384",
        "57,338",
        "",
        "89,052",
        "",
        "",
        "2,994",
        "(1,968)",
        "447",
        "1,473",
        "",
        "90,525",
        "(16,950)",
        "",
        "73,575",
        "",
        "",
        "$9.94",
        "$9.65"
      )
    )
    
    DT::datatable(microsoft_data, 
                  options = list(dom = 't', pageLength = 50, ordering = FALSE),
                  rownames = FALSE,
                  colnames = c("Income Statement Item", "Amount ($ Millions)")) %>%
      DT::formatStyle(columns = 1:2, backgroundColor = "#34495e", color = "#ecf0f1")
  }, server = FALSE)
  
  # Amazon Cash Flow Statement Example
  output$amazon_cashflow_statement <- DT::renderDataTable({
    amazon_data <- data.frame(
      "Item" = c(
        "OPERATING ACTIVITIES",
        "Net Income",
        "Adjustments to reconcile net income:",
        "  Depreciation & Amortization",
        "  Stock-based Compensation",
        "  Other Operating Activities",
        "Changes in Working Capital:",
        "  Accounts Receivable",
        "  Inventories",
        "  Accounts Payable",
        "  Other Working Capital Changes",
        "Net Cash from Operating Activities",
        "",
        "INVESTING ACTIVITIES",
        "Capital Expenditures",
        "Acquisitions, net of cash acquired",
        "Sales/Maturities of Investment Securities",
        "Purchases of Investment Securities",
        "Other Investing Activities",
        "Net Cash used in Investing Activities",
        "",
        "FINANCING ACTIVITIES",
        "Proceeds from Long-term Debt",
        "Repayments of Long-term Debt",
        "Principal Repayments of Finance Leases",
        "Common Stock Repurchased",
        "Other Financing Activities",
        "Net Cash used in Financing Activities",
        "",
        "Effect of Exchange Rate Changes",
        "",
        "Net Increase in Cash and Cash Equivalents",
        "Cash and Cash Equivalents, Beginning of Year",
        "Cash and Cash Equivalents, End of Year"
      ),
      "Amount_Millions" = c(
        "",
        "33,364",
        "",
        "48,753",
        "19,621",
        "2,186",
        "",
        "(6,539)",
        "(7,613)",
        "4,838",
        "(1,744)",
        "84,946",
        "",
        "",
        "(63,645)",
        "(3,304)",
        "18,086",
        "(7,705)",
        "(1,235)",
        "(57,803)",
        "",
        "",
        "24,214",
        "(1,590)",
        "(9,585)",
        "(6,000)",
        "(924)",
        "6,115",
        "",
        "(294)",
        "",
        "32,964",
        "36,477",
        "69,441"
      )
    )
    
    DT::datatable(amazon_data, 
                  options = list(dom = 't', pageLength = 50, ordering = FALSE),
                  rownames = FALSE,
                  colnames = c("Cash Flow Statement Item", "Amount ($ Millions)")) %>%
      DT::formatStyle(columns = 1:2, backgroundColor = "#34495e", color = "#ecf0f1")
  }, server = FALSE)
  
  # Reactive values for the generated balance sheet
  balance_sheet_data <- reactiveVal(data.frame())
  
  # Generate balance sheet when button is clicked
  observeEvent(input$generate_statement, {
    
    # Calculate totals
    total_current_assets <- input$cash + input$receivables + input$inventory + 
      input$prepaid + input$other_current_assets
    
    total_noncurrent_assets <- input$ppe + input$intangible + input$goodwill + 
      input$other_noncurrent_assets
    
    total_assets <- total_current_assets + total_noncurrent_assets
    
    total_current_liab <- input$accounts_payable + input$short_term_debt + 
      input$accrued_expenses + input$other_current_liab
    
    total_noncurrent_liab <- input$long_term_debt + input$deferred_tax + 
      input$other_noncurrent_liab
    
    total_liabilities <- total_current_liab + total_noncurrent_liab
    
    total_equity <- input$common_stock + input$additional_paid + 
      input$retained_earnings + input$other_equity
    
    total_liab_equity <- total_liabilities + total_equity
    
    # Create balance sheet data frame
    bs_data <- data.frame(
      "Item" = c(
        paste(input$company_name, "- Balance Sheet"),
        paste("As of", input$report_date),
        "",
        "ASSETS",
        "Current Assets:",
        "  Cash and Cash Equivalents",
        "  Accounts Receivable",
        "  Inventory",
        "  Prepaid Expenses",
        "  Other Current Assets",
        "Total Current Assets",
        "",
        "Non-Current Assets:",
        "  Property, Plant & Equipment (net)",
        "  Intangible Assets",
        "  Goodwill",
        "  Other Non-Current Assets",
        "Total Non-Current Assets",
        "",
        "TOTAL ASSETS",
        "",
        "LIABILITIES AND SHAREHOLDERS' EQUITY",
        "Current Liabilities:",
        "  Accounts Payable",
        "  Short-term Debt",
        "  Accrued Expenses",
        "  Other Current Liabilities",
        "Total Current Liabilities",
        "",
        "Non-Current Liabilities:",
        "  Long-term Debt",
        "  Deferred Tax Liabilities",
        "  Other Non-Current Liabilities",
        "Total Non-Current Liabilities",
        "",
        "Total Liabilities",
        "",
        "Shareholders' Equity:",
        "  Common Stock",
        "  Additional Paid-in Capital",
        "  Retained Earnings",
        "  Other Comprehensive Income",
        "Total Shareholders' Equity",
        "",
        "TOTAL LIABILITIES AND SHAREHOLDERS' EQUITY",
        "",
        "Balance Check (should be 0):",
        paste("Assets - (Liabilities + Equity) =", 
              formatC(total_assets - total_liab_equity, format = "f", digits = 2))
      ),
      "Amount" = c(
        "",
        "",
        "",
        "",
        "",
        formatC(input$cash, format = "f", digits = 2, big.mark = ","),
        formatC(input$receivables, format = "f", digits = 2, big.mark = ","),
        formatC(input$inventory, format = "f", digits = 2, big.mark = ","),
        formatC(input$prepaid, format = "f", digits = 2, big.mark = ","),
        formatC(input$other_current_assets, format = "f", digits = 2, big.mark = ","),
        formatC(total_current_assets, format = "f", digits = 2, big.mark = ","),
        "",
        "",
        formatC(input$ppe, format = "f", digits = 2, big.mark = ","),
        formatC(input$intangible, format = "f", digits = 2, big.mark = ","),
        formatC(input$goodwill, format = "f", digits = 2, big.mark = ","),
        formatC(input$other_noncurrent_assets, format = "f", digits = 2, big.mark = ","),
        formatC(total_noncurrent_assets, format = "f", digits = 2, big.mark = ","),
        "",
        formatC(total_assets, format = "f", digits = 2, big.mark = ","),
        "",
        "",
        "",
        formatC(input$accounts_payable, format = "f", digits = 2, big.mark = ","),
        formatC(input$short_term_debt, format = "f", digits = 2, big.mark = ","),
        formatC(input$accrued_expenses, format = "f", digits = 2, big.mark = ","),
        formatC(input$other_current_liab, format = "f", digits = 2, big.mark = ","),
        formatC(total_current_liab, format = "f", digits = 2, big.mark = ","),
        "",
        "",
        formatC(input$long_term_debt, format = "f", digits = 2, big.mark = ","),
        formatC(input$deferred_tax, format = "f", digits = 2, big.mark = ","),
        formatC(input$other_noncurrent_liab, format = "f", digits = 2, big.mark = ","),
        formatC(total_noncurrent_liab, format = "f", digits = 2, big.mark = ","),
        "",
        formatC(total_liabilities, format = "f", digits = 2, big.mark = ","),
        "",
        "",
        formatC(input$common_stock, format = "f", digits = 2, big.mark = ","),
        formatC(input$additional_paid, format = "f", digits = 2, big.mark = ","),
        formatC(input$retained_earnings, format = "f", digits = 2, big.mark = ","),
        formatC(input$other_equity, format = "f", digits = 2, big.mark = ","),
        formatC(total_equity, format = "f", digits = 2, big.mark = ","),
        "",
        formatC(total_liab_equity, format = "f", digits = 2, big.mark = ","),
        "",
        "",
        ""
      )
    )
    
    balance_sheet_data(bs_data)
  })
  
  # Display generated balance sheet
  output$generated_balance_sheet <- DT::renderDataTable({
    req(balance_sheet_data())
    DT::datatable(balance_sheet_data(), 
                  options = list(dom = 't', pageLength = 50, ordering = FALSE),
                  rownames = FALSE,
                  colnames = c("Balance Sheet Item", "Amount ($)")) %>%
      DT::formatStyle(columns = 1:2, backgroundColor = "#34495e", color = "#ecf0f1")
  }, server = FALSE)
  
  # Download handler for Excel file
  output$download_excel <- downloadHandler(
    filename = function() {
      paste0(gsub(" ", "_", input$company_name), "_Balance_Sheet_", 
             format(input$report_date, "%Y%m%d"), ".xlsx")
    },
    content = function(file) {
      req(balance_sheet_data())
      
      # Create workbook
      wb <- createWorkbook()
      addWorksheet(wb, "Balance Sheet")
      
      # Write data
      writeData(wb, "Balance Sheet", balance_sheet_data(), 
                startCol = 1, startRow = 1, colNames = TRUE)
      
      # Style the workbook
      headerStyle <- createStyle(fontSize = 12, fontColour = "white", 
                                 fgFill = "#34495e", textDecoration = "bold")
      addStyle(wb, "Balance Sheet", headerStyle, rows = 1, cols = 1:2)
      
      # Save workbook
      saveWorkbook(wb, file, overwrite = TRUE)
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)