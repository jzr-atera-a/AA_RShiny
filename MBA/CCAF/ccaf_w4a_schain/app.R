# Enhanced Supply Chain Analysis R Shiny Dashboard - Full Data Integration
# Load required libraries
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(dplyr)
library(ggplot2)
library(scales)
library(shinycssloaders)
library(readxl)

# Read data from CSV file
supply_chain_data <- read.csv("supply_chain_data.csv", stringsAsFactors = FALSE)

# Clean and convert numeric columns
supply_chain_data$Market_Cap_M <- as.numeric(gsub("[^0-9.]", "", supply_chain_data$Market_Cap_M))
supply_chain_data$Total_Relationship_Size_M <- as.numeric(gsub("[^0-9.]", "", supply_chain_data$Total_Relationship_Size_M))

# Read Excel data
excel_file <- "supply_chain_overview_full (1).xlsx"

# Function to read and clean Excel sheets
read_excel_sheet <- function(file, sheet_name) {
  tryCatch({
    data <- read_excel(file, sheet = sheet_name)
    return(data)
  }, error = function(e) {
    return(NULL)
  })
}

# Read all Excel sheets
amzn_geo <- read_excel_sheet(excel_file, "overview_AMZN_top_geo")
amzn_risks <- read_excel_sheet(excel_file, "overview_AMZN_risks")
amzn_commodities <- read_excel_sheet(excel_file, "overview_AMZN_commodities")
amzn_suppliers <- read_excel_sheet(excel_file, "overview_AMZN_suppliers")
amzn_customers <- read_excel_sheet(excel_file, "overview_AMZN_customers")

msft_geo <- read_excel_sheet(excel_file, "overview_MSFT_top_geo")
msft_risks <- read_excel_sheet(excel_file, "overview_MSFT_risks")
msft_suppliers <- read_excel_sheet(excel_file, "overview_MSFT_suppliers")
msft_customers <- read_excel_sheet(excel_file, "overview_MSFT_customers")

# Filter data by company
amazon_data <- supply_chain_data %>% filter(Company == "Amazon")
microsoft_data <- supply_chain_data %>% filter(Company == "Microsoft")
google_data <- supply_chain_data %>% filter(Company == "Google")
coreweave_data <- supply_chain_data %>% filter(Company == "CoreWeave")

# Company info
company_info <- data.frame(
  company = c("Amazon", "Microsoft", "Google", "CoreWeave"),
  ticker = c("AMZN US", "MSFT US", "GOOGL US", "CRWV US"),
  price = c(1222.69, 522.04, 201.42, 129.55),
  change = c(-0.44, 1.20, 4.90, 8.47),
  volume = c("32,970,477", "15,531,009", "39,161,826", "17,159,705"),
  stringsAsFactors = FALSE
)

# Define UI
ui <- dashboardPage(
  skin = "black",
  
  # Header
  dashboardHeader(
    title = "Supply Chain Analysis Dashboard",
    titleWidth = 350
  ),
  
  # Sidebar
  dashboardSidebar(
    width = 280,
    sidebarMenu(
      id = "tabs",
      menuItem("Overview", tabName = "overview", icon = icon("chart-line")),
      menuItem("Amazon", tabName = "amazon", icon = icon("shopping-cart")),
      menuItem("Microsoft", tabName = "microsoft", icon = icon("windows")),
      menuItem("Google", tabName = "google", icon = icon("google")),
      menuItem("CoreWeave", tabName = "coreweave", icon = icon("server")),
      menuItem("Cross-Analysis", tabName = "cross", icon = icon("project-diagram"))
    )
  ),
  
  # Body
  dashboardBody(
    # Custom CSS for dark grey theme with WHITE backgrounds for plots and tables
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #2c3e50;
        }
        
        .box {
          background-color: #34495e;
          border: 1px solid #4a5f7a;
          color: #ecf0f1;
        }
        
        .box-header {
          color: #ecf0f1;
          border-bottom-color: #4a5f7a;
        }
        
        .info-box {
          background-color: #34495e;
          color: #ecf0f1;
          border: 1px solid #4a5f7a;
        }
        
        .info-box-icon {
          background-color: #4a5f7a !important;
        }
        
        .value-box {
          background-color: #34495e;
          color: #ecf0f1;
        }
        
        .small-box {
          background-color: #34495e !important;
          color: #ecf0f1 !important;
        }
        
        .small-box h3, .small-box p {
          color: #ecf0f1 !important;
        }
        
        .main-header .navbar {
          background-color: #1a252f !important;
        }
        
        .main-header .logo {
          background-color: #1a252f !important;
          color: #ecf0f1 !important;
        }
        
        .sidebar {
          background-color: #1a252f !important;
        }
        
        .sidebar-menu > li > a {
          color: #ecf0f1 !important;
        }
        
        .sidebar-menu > li.active > a {
          background-color: #34495e !important;
          border-left-color: #3498db !important;
        }
        
        /* WHITE backgrounds for tables and plots */
        .dataTables_wrapper {
          background-color: white !important;
          color: #333 !important;
        }
        
        .dataTables_wrapper table {
          background-color: white !important;
          color: #333 !important;
        }
        
        .dataTables_wrapper .dataTables_filter input {
          background-color: white !important;
          color: #333 !important;
          border: 1px solid #ccc !important;
        }
        
        .dataTables_wrapper .dataTables_length select {
          background-color: white !important;
          color: #333 !important;
          border: 1px solid #ccc !important;
        }
        
        .dataTables_wrapper .dataTables_info {
          color: #333 !important;
        }
        
        .page-link {
          background-color: white !important;
          border-color: #ccc !important;
          color: #333 !important;
        }
        
        .page-link:hover {
          background-color: #f8f9fa !important;
          border-color: #adb5bd !important;
          color: #333 !important;
        }
        
        .page-item.active .page-link {
          background-color: #3498db !important;
          border-color: #3498db !important;
          color: white !important;
        }
        
        /* Plotly plot backgrounds */
        .js-plotly-plot {
          background-color: white !important;
        }
      "))
    ),
    
    tabItems(
      # Overview Tab
      tabItem(tabName = "overview",
              fluidRow(
                box(
                  title = "Company Stock Overview", status = "primary", solidHeader = TRUE,
                  width = 12, height = 200,
                  div(
                    style = "display: flex; justify-content: space-around; align-items: center; height: 120px;",
                    div(
                      style = "text-align: center;",
                      h4("Amazon (AMZN)", style = "color: #ecf0f1; margin-bottom: 10px;"),
                      h3("$1,222.69", style = "color: #e74c3c; margin-bottom: 5px;"),
                      p("(-0.44)", style = "color: #e74c3c; font-size: 14px; margin-bottom: 0;"),
                      p("Vol: 32.97M", style = "color: #bdc3c7; font-size: 12px;")
                    ),
                    div(
                      style = "text-align: center;",
                      h4("Microsoft (MSFT)", style = "color: #ecf0f1; margin-bottom: 10px;"),
                      h3("$522.04", style = "color: #27ae60; margin-bottom: 5px;"),
                      p("(+1.20)", style = "color: #27ae60; font-size: 14px; margin-bottom: 0;"),
                      p("Vol: 15.53M", style = "color: #bdc3c7; font-size: 12px;")
                    ),
                    div(
                      style = "text-align: center;",
                      h4("Google (GOOGL)", style = "color: #ecf0f1; margin-bottom: 10px;"),
                      h3("$201.42", style = "color: #27ae60; margin-bottom: 5px;"),
                      p("(+4.90)", style = "color: #27ae60; font-size: 14px; margin-bottom: 0;"),
                      p("Vol: 39.16M", style = "color: #bdc3c7; font-size: 12px;")
                    ),
                    div(
                      style = "text-align: center;",
                      h4("CoreWeave (CRWV)", style = "color: #ecf0f1; margin-bottom: 10px;"),
                      h3("$129.55", style = "color: #27ae60; margin-bottom: 5px;"),
                      p("(+8.47)", style = "color: #27ae60; font-size: 14px; margin-bottom: 0;"),
                      p("Vol: 17.16M", style = "color: #bdc3c7; font-size: 12px;")
                    )
                  )
                )
              ),
              
              fluidRow(
                valueBoxOutput("total_suppliers", width = 3),
                valueBoxOutput("total_semiconductors", width = 3),
                valueBoxOutput("largest_relationship", width = 3),
                valueBoxOutput("common_suppliers", width = 3)
              ),
              
              fluidRow(
                box(
                  title = "Industry Distribution Across All Companies", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  withSpinner(plotlyOutput("industry_plot"), color = "#3498db")
                ),
                box(
                  title = "Top 10 Suppliers by Market Cap", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  withSpinner(plotlyOutput("market_cap_plot"), color = "#3498db")
                )
              ),
              
              fluidRow(
                box(
                  title = "Supplier Count by Company", 
                  status = "primary", solidHeader = TRUE, width = 12,
                  withSpinner(plotlyOutput("supplier_count_plot"), color = "#3498db")
                )
              )
      ),
      
      # Amazon Tab
      tabItem(tabName = "amazon",
              fluidRow(
                valueBoxOutput("amazon_suppliers", width = 3),
                valueBoxOutput("amazon_semiconductors", width = 3),
                valueBoxOutput("amazon_utilities", width = 3),
                valueBoxOutput("amazon_top_relationship", width = 3)
              ),
              
              # Risk Analysis Row
              fluidRow(
                valueBoxOutput("amazon_sanctions_suppliers", width = 3),
                valueBoxOutput("amazon_sanctions_customers", width = 3),
                valueBoxOutput("amazon_distressed_suppliers", width = 3),
                valueBoxOutput("amazon_top_geo", width = 3)
              ),
              
              fluidRow(
                box(
                  title = "Amazon Industry Breakdown", 
                  status = "primary", solidHeader = TRUE, width = 4,
                  withSpinner(plotlyOutput("amazon_industry_plot"), color = "#3498db")
                ),
                box(
                  title = "Geographic Distribution", 
                  status = "primary", solidHeader = TRUE, width = 4,
                  withSpinner(plotlyOutput("amazon_geo_plot"), color = "#3498db")
                ),
                box(
                  title = "Commodity Price Changes", 
                  status = "primary", solidHeader = TRUE, width = 4,
                  withSpinner(plotlyOutput("amazon_commodities_plot"), color = "#3498db")
                )
              ),
              
              fluidRow(
                box(
                  title = "Top Amazon Suppliers (Detailed)", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  withSpinner(DT::dataTableOutput("amazon_suppliers_detailed"), color = "#3498db")
                ),
                box(
                  title = "Top Amazon Customers", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  withSpinner(DT::dataTableOutput("amazon_customers_table"), color = "#3498db")
                )
              ),
              
              fluidRow(
                box(
                  title = "Amazon Supply Chain Data (Full)", 
                  status = "primary", solidHeader = TRUE, width = 12,
                  withSpinner(DT::dataTableOutput("amazon_table"), color = "#3498db")
                )
              )
      ),
      
      # Microsoft Tab
      tabItem(tabName = "microsoft",
              fluidRow(
                valueBoxOutput("microsoft_suppliers", width = 3),
                valueBoxOutput("microsoft_semiconductors", width = 3),
                valueBoxOutput("microsoft_top_relationship", width = 3),
                valueBoxOutput("microsoft_capex_impact", width = 3)
              ),
              
              # Risk Analysis Row
              fluidRow(
                valueBoxOutput("microsoft_sanctions_suppliers", width = 3),
                valueBoxOutput("microsoft_sanctions_customers", width = 3),
                valueBoxOutput("microsoft_distressed_suppliers", width = 3),
                valueBoxOutput("microsoft_top_geo", width = 3)
              ),
              
              fluidRow(
                box(
                  title = "Microsoft Industry Breakdown", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  withSpinner(plotlyOutput("microsoft_industry_plot"), color = "#3498db")
                ),
                box(
                  title = "Geographic Distribution", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  withSpinner(plotlyOutput("microsoft_geo_plot"), color = "#3498db")
                )
              ),
              
              fluidRow(
                box(
                  title = "Top Microsoft Suppliers (Detailed)", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  withSpinner(DT::dataTableOutput("microsoft_suppliers_detailed"), color = "#3498db")
                ),
                box(
                  title = "Top Microsoft Customers", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  withSpinner(DT::dataTableOutput("microsoft_customers_table"), color = "#3498db")
                )
              ),
              
              fluidRow(
                box(
                  title = "Microsoft Supply Chain Data (Full)", 
                  status = "primary", solidHeader = TRUE, width = 12,
                  withSpinner(DT::dataTableOutput("microsoft_table"), color = "#3498db")
                )
              )
      ),
      
      # Google Tab
      tabItem(tabName = "google",
              fluidRow(
                valueBoxOutput("google_suppliers", width = 3),
                valueBoxOutput("google_semiconductors", width = 3),
                valueBoxOutput("google_top_relationship", width = 3),
                valueBoxOutput("google_capex_impact", width = 3)
              ),
              
              fluidRow(
                box(
                  title = "Google Industry Breakdown", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  withSpinner(plotlyOutput("google_industry_plot"), color = "#3498db")
                ),
                box(
                  title = "Top 10 Google Suppliers by Relationship Size", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  withSpinner(plotlyOutput("google_relationships_plot"), color = "#3498db")
                )
              ),
              
              fluidRow(
                box(
                  title = "Google Supply Chain Data", 
                  status = "primary", solidHeader = TRUE, width = 12,
                  withSpinner(DT::dataTableOutput("google_table"), color = "#3498db")
                )
              )
      ),
      
      # CoreWeave Tab
      tabItem(tabName = "coreweave",
              fluidRow(
                valueBoxOutput("coreweave_suppliers", width = 3),
                valueBoxOutput("coreweave_hardware", width = 3),
                valueBoxOutput("coreweave_top_relationship", width = 3),
                valueBoxOutput("coreweave_capex_impact", width = 3)
              ),
              
              fluidRow(
                box(
                  title = "CoreWeave Industry Breakdown", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  withSpinner(plotlyOutput("coreweave_industry_plot"), color = "#3498db")
                ),
                box(
                  title = "CoreWeave Suppliers by Market Cap", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  withSpinner(plotlyOutput("coreweave_market_cap_plot"), color = "#3498db")
                )
              ),
              
              fluidRow(
                box(
                  title = "CoreWeave Supply Chain Data", 
                  status = "primary", solidHeader = TRUE, width = 12,
                  withSpinner(DT::dataTableOutput("coreweave_table"), color = "#3498db")
                )
              )
      ),
      
      # Cross-Analysis Tab
      tabItem(tabName = "cross",
              fluidRow(
                box(
                  title = "Common Suppliers Across Companies", 
                  status = "primary", solidHeader = TRUE, width = 12,
                  withSpinner(DT::dataTableOutput("common_suppliers_table"), color = "#3498db")
                )
              ),
              
              fluidRow(
                box(
                  title = "Supplier Overlap Analysis", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  withSpinner(plotlyOutput("supplier_overlap_plot"), color = "#3498db")
                ),
                box(
                  title = "Industry Concentration by Company", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  withSpinner(plotlyOutput("industry_concentration_plot"), color = "#3498db")
                )
              ),
              
              fluidRow(
                box(
                  title = "Risk Analysis Comparison", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  withSpinner(plotlyOutput("risk_comparison_plot"), color = "#3498db")
                ),
                box(
                  title = "Top Relationships Across All Companies", 
                  status = "primary", solidHeader = TRUE, width = 6,
                  withSpinner(plotlyOutput("top_relationships_plot"), color = "#3498db")
                )
              )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Helper function to safely convert percentage strings to numeric
  percent_to_numeric <- function(x) {
    as.numeric(gsub("%", "", x))
  }
  
  # Overview Tab Outputs
  output$total_suppliers <- renderValueBox({
    valueBox(
      value = nrow(supply_chain_data),
      subtitle = "Total Suppliers",
      icon = icon("industry"),
      color = "blue"
    )
  })
  
  output$total_semiconductors <- renderValueBox({
    semiconductor_count <- sum(supply_chain_data$Industry == "Semiconductors", na.rm = TRUE)
    valueBox(
      value = semiconductor_count,
      subtitle = "Semiconductor Companies",
      icon = icon("microchip"),
      color = "green"
    )
  })
  
  output$largest_relationship <- renderValueBox({
    max_relationship <- max(supply_chain_data$Total_Relationship_Size_M, na.rm = TRUE)
    if(is.finite(max_relationship)) {
      value_text <- paste0("$", round(max_relationship/1000, 1), "B")
    } else {
      value_text <- "N/A"
    }
    valueBox(
      value = value_text,
      subtitle = "Largest Relationship (MSFT-NVIDIA)",
      icon = icon("handshake"),
      color = "yellow"
    )
  })
  
  output$common_suppliers <- renderValueBox({
    valueBox(
      value = "NVIDIA",
      subtitle = "Most Common Supplier",
      icon = icon("share-alt"),
      color = "red"
    )
  })
  
  # Industry distribution plot
  output$industry_plot <- renderPlotly({
    industry_counts <- supply_chain_data %>%
      count(Industry, sort = TRUE) %>%
      head(10)
    
    p <- ggplot(industry_counts, aes(x = reorder(Industry, n), y = n)) +
      geom_bar(stat = "identity", fill = "#3498db") +
      coord_flip() +
      theme_minimal() +
      theme(
        plot.background = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA),
        text = element_text(color = "#333"),
        axis.text = element_text(color = "#333"),
        panel.grid = element_line(color = "#e0e0e0")
      ) +
      labs(x = "Industry", y = "Number of Suppliers")
    
    ggplotly(p) %>%
      layout(
        plot_bgcolor = 'white',
        paper_bgcolor = 'white',
        font = list(color = '#333')
      )
  })
  
  # Market cap plot
  output$market_cap_plot <- renderPlotly({
    top_market_cap <- supply_chain_data %>%
      filter(!is.na(Market_Cap_M) & Market_Cap_M > 0) %>%
      arrange(desc(Market_Cap_M)) %>%
      head(10)
    
    if(nrow(top_market_cap) > 0) {
      p <- ggplot(top_market_cap, aes(x = reorder(Supplier_Name, Market_Cap_M), y = Market_Cap_M/1000)) +
        geom_bar(stat = "identity", fill = "#e74c3c") +
        coord_flip() +
        theme_minimal() +
        theme(
          plot.background = element_rect(fill = "white", color = NA),
          panel.background = element_rect(fill = "white", color = NA),
          text = element_text(color = "#333"),
          axis.text = element_text(color = "#333"),
          panel.grid = element_line(color = "#e0e0e0")
        ) +
        labs(x = "Supplier", y = "Market Cap (Billions)")
      
      ggplotly(p) %>%
        layout(
          plot_bgcolor = 'white',
          paper_bgcolor = 'white',
          font = list(color = '#333')
        )
    } else {
      plotly_empty() %>%
        layout(
          title = "No market cap data available",
          plot_bgcolor = 'white',
          paper_bgcolor = 'white'
        )
    }
  })
  
  # Supplier count plot
  output$supplier_count_plot <- renderPlotly({
    supplier_counts <- supply_chain_data %>%
      count(Company)
    
    p <- ggplot(supplier_counts, aes(x = Company, y = n)) +
      geom_bar(stat = "identity", fill = c("#ff9f43", "#00d2d3", "#ff6b6b", "#4834d4")) +
      theme_minimal() +
      theme(
        plot.background = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA),
        text = element_text(color = "#333"),
        axis.text = element_text(color = "#333"),
        panel.grid = element_line(color = "#e0e0e0")
      ) +
      labs(x = "Company", y = "Number of Suppliers")
    
    ggplotly(p) %>%
      layout(
        plot_bgcolor = 'white',
        paper_bgcolor = 'white',
        font = list(color = '#333')
      )
  })
  
  # Amazon Tab Outputs
  output$amazon_suppliers <- renderValueBox({
    valueBox(
      value = nrow(amazon_data),
      subtitle = "Total Suppliers",
      icon = icon("list"),
      color = "blue"
    )
  })
  
  output$amazon_semiconductors <- renderValueBox({
    valueBox(
      value = sum(amazon_data$Industry == "Semiconductors", na.rm = TRUE),
      subtitle = "Semiconductor Suppliers",
      icon = icon("microchip"),
      color = "green"
    )
  })
  
  output$amazon_utilities <- renderValueBox({
    valueBox(
      value = sum(amazon_data$Industry == "Electric Utilities", na.rm = TRUE),
      subtitle = "Electric Utilities",
      icon = icon("bolt"),
      color = "yellow"
    )
  })
  
  output$amazon_top_relationship <- renderValueBox({
    max_amazon <- max(amazon_data$Total_Relationship_Size_M, na.rm = TRUE)
    if(is.finite(max_amazon)) {
      value_text <- paste0("$", round(max_amazon/1000, 1), "B")
    } else {
      value_text <- "N/A"
    }
    valueBox(
      value = value_text,
      subtitle = "Top Relationship (NVIDIA)",
      icon = icon("handshake"),
      color = "red"
    )
  })
  
  # Amazon Risk Analysis Value Boxes
  output$amazon_sanctions_suppliers <- renderValueBox({
    if(!is.null(amzn_risks)) {
      sanctions_count <- amzn_risks %>% 
        filter(Risk == "Suppliers with sanctions") %>% 
        pull(Count) %>% 
        first()
      if(is.na(sanctions_count) || sanctions_count == "") sanctions_count <- 0
    } else {
      sanctions_count <- "N/A"
    }
    valueBox(
      value = sanctions_count,
      subtitle = "Suppliers with Sanctions",
      icon = icon("exclamation-triangle"),
      color = "red"
    )
  })
  
  output$amazon_sanctions_customers <- renderValueBox({
    if(!is.null(amzn_risks)) {
      customer_sanctions <- amzn_risks %>% 
        filter(Risk == "Customers with sanctions") %>% 
        pull(Count) %>% 
        first()
      if(is.na(customer_sanctions)) customer_sanctions <- 0
    } else {
      customer_sanctions <- "N/A"
    }
    valueBox(
      value = customer_sanctions,
      subtitle = "Customers with Sanctions",
      icon = icon("ban"),
      color = "orange"
    )
  })
  
  output$amazon_distressed_suppliers <- renderValueBox({
    if(!is.null(amzn_risks)) {
      distressed_count <- amzn_risks %>% 
        filter(Risk == "Suppliers are Distressed") %>% 
        pull(Count) %>% 
        first()
      if(is.na(distressed_count)) distressed_count <- 0
    } else {
      distressed_count <- "N/A"
    }
    valueBox(
      value = distressed_count,
      subtitle = "Distressed Suppliers",
      icon = icon("chart-line-down"),
      color = "yellow"
    )
  })
  
  output$amazon_top_geo <- renderValueBox({
    if(!is.null(amzn_geo)) {
      top_geo <- amzn_geo %>% 
        slice(1) %>% 
        pull(`Country/Region`)
      if(is.na(top_geo)) top_geo <- "USA"
    } else {
      top_geo <- "USA"
    }
    valueBox(
      value = top_geo,
      subtitle = "Top Geographic Region",
      icon = icon("globe"),
      color = "blue"
    )
  })
  
  # Amazon Geographic Distribution Plot
  output$amazon_geo_plot <- renderPlotly({
    if(!is.null(amzn_geo)) {
      amzn_geo_clean <- amzn_geo %>%
        mutate(Percentage = percent_to_numeric(`AMZN Facs`)) %>%
        filter(!is.na(Percentage) & Percentage > 0)
      
      if(nrow(amzn_geo_clean) > 0) {
        p <- ggplot(amzn_geo_clean, aes(x = reorder(`Country/Region`, Percentage), y = Percentage)) +
          geom_bar(stat = "identity", fill = "#ff9f43") +
          coord_flip() +
          theme_minimal() +
          theme(
            plot.background = element_rect(fill = "white", color = NA),
            panel.background = element_rect(fill = "white", color = NA),
            text = element_text(color = "#333"),
            axis.text = element_text(color = "#333"),
            panel.grid = element_line(color = "#e0e0e0")
          ) +
          labs(x = "Country/Region", y = "Facility Percentage (%)")
        
        ggplotly(p) %>%
          layout(
            plot_bgcolor = 'white',
            paper_bgcolor = 'white',
            font = list(color = '#333')
          )
      } else {
        plotly_empty() %>%
          layout(
            title = "No geographic data available",
            plot_bgcolor = 'white',
            paper_bgcolor = 'white'
          )
      }
    } else {
      plotly_empty() %>%
        layout(
          title = "No geographic data available",
          plot_bgcolor = 'white',
          paper_bgcolor = 'white'
        )
    }
  })
  
  # Amazon Commodities Plot
  output$amazon_commodities_plot <- renderPlotly({
    if(!is.null(amzn_commodities)) {
      amzn_commodities_clean <- amzn_commodities %>%
        mutate(Price_Change = percent_to_numeric(`3M Price Chg`)) %>%
        filter(!is.na(Price_Change))
      
      if(nrow(amzn_commodities_clean) > 0) {
        p <- ggplot(amzn_commodities_clean, aes(x = reorder(Commodity, Price_Change), y = Price_Change)) +
          geom_bar(stat = "identity", fill = ifelse(amzn_commodities_clean$Price_Change >= 0, "#27ae60", "#e74c3c")) +
          coord_flip() +
          theme_minimal() +
          theme(
            plot.background = element_rect(fill = "white", color = NA),
            panel.background = element_rect(fill = "white", color = NA),
            text = element_text(color = "#333"),
            axis.text = element_text(color = "#333"),
            panel.grid = element_line(color = "#e0e0e0")
          ) +
          labs(x = "Commodity", y = "3M Price Change (%)")
        
        ggplotly(p) %>%
          layout(
            plot_bgcolor = 'white',
            paper_bgcolor = 'white',
            font = list(color = '#333')
          )
      } else {
        plotly_empty() %>%
          layout(
            title = "No commodity data available",
            plot_bgcolor = 'white',
            paper_bgcolor = 'white'
          )
      }
    } else {
      plotly_empty() %>%
        layout(
          title = "No commodity data available",
          plot_bgcolor = 'white',
          paper_bgcolor = 'white'
        )
    }
  })
  
  output$amazon_industry_plot <- renderPlotly({
    industry_counts <- amazon_data %>%
      count(Industry, sort = TRUE)
    
    p <- ggplot(industry_counts, aes(x = reorder(Industry, n), y = n)) +
      geom_bar(stat = "identity", fill = "#ff9f43") +
      coord_flip() +
      theme_minimal() +
      theme(
        plot.background = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA),
        text = element_text(color = "#333"),
        axis.text = element_text(color = "#333"),
        panel.grid = element_line(color = "#e0e0e0")
      ) +
      labs(x = "Industry", y = "Number of Suppliers")
    
    ggplotly(p) %>%
      layout(
        plot_bgcolor = 'white',
        paper_bgcolor = 'white',
        font = list(color = '#333')
      )
  })
  
  # Amazon Detailed Suppliers Table
  output$amazon_suppliers_detailed <- DT::renderDataTable({
    if(!is.null(amzn_suppliers)) {
      DT::datatable(
        amzn_suppliers,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv', 'excel'),
          searchHighlight = TRUE
        ),
        colnames = c("Supplier Name", "Supplier's Revenue %", "AMZN's Cost %", "3M Price Change"),
        filter = 'top',
        rownames = FALSE
      )
    } else {
      DT::datatable(data.frame(Message = "No detailed supplier data available"))
    }
  }, server = FALSE)
  
  # Amazon Customers Table
  output$amazon_customers_table <- DT::renderDataTable({
    if(!is.null(amzn_customers)) {
      DT::datatable(
        amzn_customers,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv', 'excel'),
          searchHighlight = TRUE
        ),
        colnames = c("Customer Name", "AMZN's Revenue %", "Customer's Cost %", "3M Price Change"),
        filter = 'top',
        rownames = FALSE
      )
    } else {
      DT::datatable(data.frame(Message = "No customer data available"))
    }
  }, server = FALSE)
  
  output$amazon_table <- DT::renderDataTable({
    DT::datatable(
      amazon_data %>%
        select(Rank, Supplier_Name, Industry, Market_Cap_M, Total_Relationship_Size_M, 
               Cost_Category_Percent, Supplier_Source_Revenue_Percent, Size_Source),
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel'),
        searchHighlight = TRUE
      ),
      colnames = c("Rank", "Supplier Name", "Industry", "Market Cap (M)", 
                   "Relationship Size (M)", "Cost Category", "Source Revenue", "Size Source"),
      filter = 'top',
      rownames = FALSE
    ) %>%
      formatCurrency(c("Market_Cap_M", "Total_Relationship_Size_M"), digits = 2, mark = ",")
  }, server = FALSE)
  
  # Microsoft Tab Outputs
  output$microsoft_suppliers <- renderValueBox({
    valueBox(
      value = nrow(microsoft_data),
      subtitle = "Total Suppliers",
      icon = icon("list"),
      color = "blue"
    )
  })
  
  output$microsoft_semiconductors <- renderValueBox({
    valueBox(
      value = sum(microsoft_data$Industry == "Semiconductors", na.rm = TRUE),
      subtitle = "Semiconductor Suppliers",
      icon = icon("microchip"),
      color = "green"
    )
  })
  
  output$microsoft_top_relationship <- renderValueBox({
    max_microsoft <- max(microsoft_data$Total_Relationship_Size_M, na.rm = TRUE)
    if(is.finite(max_microsoft)) {
      value_text <- paste0("$", round(max_microsoft/1000, 1), "B")
    } else {
      value_text <- "N/A"
    }
    valueBox(
      value = value_text,
      subtitle = "Top Relationship (NVIDIA)",
      icon = icon("handshake"),
      color = "yellow"
    )
  })
  
  output$microsoft_capex_impact <- renderValueBox({
    valueBox(
      value = "46.96%",
      subtitle = "Top CAPEX Impact",
      icon = icon("chart-line"),
      color = "red"
    )
  })
  
  # Microsoft Risk Analysis Value Boxes
  output$microsoft_sanctions_suppliers <- renderValueBox({
    if(!is.null(msft_risks)) {
      sanctions_count <- msft_risks %>% 
        filter(Risk == "Suppliers with sanctions") %>% 
        pull(Count) %>% 
        first()
      if(is.na(sanctions_count)) sanctions_count <- 0
    } else {
      sanctions_count <- "N/A"
    }
    valueBox(
      value = sanctions_count,
      subtitle = "Suppliers with Sanctions",
      icon = icon("exclamation-triangle"),
      color = "red"
    )
  })
  
  output$microsoft_sanctions_customers <- renderValueBox({
    if(!is.null(msft_risks)) {
      customer_sanctions <- msft_risks %>% 
        filter(Risk == "Customers with sanctions") %>% 
        pull(Count) %>% 
        first()
      if(is.na(customer_sanctions)) customer_sanctions <- 0
    } else {
      customer_sanctions <- "N/A"
    }
    valueBox(
      value = customer_sanctions,
      subtitle = "Customers with Sanctions",
      icon = icon("ban"),
      color = "orange"
    )
  })
  
  output$microsoft_distressed_suppliers <- renderValueBox({
    if(!is.null(msft_risks)) {
      distressed_count <- msft_risks %>% 
        filter(Risk == "Suppliers are Distressed") %>% 
        pull(Count) %>% 
        first()
      if(is.na(distressed_count)) distressed_count <- 0
    } else {
      distressed_count <- "N/A"
    }
    valueBox(
      value = distressed_count,
      subtitle = "Distressed Suppliers",
      icon = icon("chart-line-down"),
      color = "yellow"
    )
  })
  
  output$microsoft_top_geo <- renderValueBox({
    if(!is.null(msft_geo)) {
      top_geo <- msft_geo %>% 
        slice(1) %>% 
        pull(`Country/Region`)
      if(is.na(top_geo)) top_geo <- "USA"
    } else {
      top_geo <- "USA"
    }
    valueBox(
      value = top_geo,
      subtitle = "Top Geographic Region",
      icon = icon("globe"),
      color = "blue"
    )
  })
  
  # Microsoft Geographic Distribution Plot
  output$microsoft_geo_plot <- renderPlotly({
    if(!is.null(msft_geo)) {
      msft_geo_clean <- msft_geo %>%
        mutate(Percentage = percent_to_numeric(`MSFT Facs`)) %>%
        filter(!is.na(Percentage) & Percentage > 0)
      
      if(nrow(msft_geo_clean) > 0) {
        p <- ggplot(msft_geo_clean, aes(x = reorder(`Country/Region`, Percentage), y = Percentage)) +
          geom_bar(stat = "identity", fill = "#00d2d3") +
          coord_flip() +
          theme_minimal() +
          theme(
            plot.background = element_rect(fill = "white", color = NA),
            panel.background = element_rect(fill = "white", color = NA),
            text = element_text(color = "#333"),
            axis.text = element_text(color = "#333"),
            panel.grid = element_line(color = "#e0e0e0")
          ) +
          labs(x = "Country/Region", y = "Facility Percentage (%)")
        
        ggplotly(p) %>%
          layout(
            plot_bgcolor = 'white',
            paper_bgcolor = 'white',
            font = list(color = '#333')
          )
      } else {
        plotly_empty() %>%
          layout(
            title = "No geographic data available",
            plot_bgcolor = 'white',
            paper_bgcolor = 'white'
          )
      }
    } else {
      plotly_empty() %>%
        layout(
          title = "No geographic data available",
          plot_bgcolor = 'white',
          paper_bgcolor = 'white'
        )
    }
  })
  
  output$microsoft_industry_plot <- renderPlotly({
    industry_counts <- microsoft_data %>%
      count(Industry, sort = TRUE)
    
    p <- ggplot(industry_counts, aes(x = reorder(Industry, n), y = n)) +
      geom_bar(stat = "identity", fill = "#00d2d3") +
      coord_flip() +
      theme_minimal() +
      theme(
        plot.background = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA),
        text = element_text(color = "#333"),
        axis.text = element_text(color = "#333"),
        panel.grid = element_line(color = "#e0e0e0")
      ) +
      labs(x = "Industry", y = "Number of Suppliers")
    
    ggplotly(p) %>%
      layout(
        plot_bgcolor = 'white',
        paper_bgcolor = 'white',
        font = list(color = '#333')
      )
  })
  
  # Microsoft Detailed Suppliers Table
  output$microsoft_suppliers_detailed <- DT::renderDataTable({
    if(!is.null(msft_suppliers)) {
      DT::datatable(
        msft_suppliers,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv', 'excel'),
          searchHighlight = TRUE
        ),
        colnames = c("Supplier Name", "Supplier's Revenue %", "MSFT's Cost %", "3M Price Change"),
        filter = 'top',
        rownames = FALSE
      )
    } else {
      DT::datatable(data.frame(Message = "No detailed supplier data available"))
    }
  }, server = FALSE)
  
  # Microsoft Customers Table
  output$microsoft_customers_table <- DT::renderDataTable({
    if(!is.null(msft_customers)) {
      DT::datatable(
        msft_customers,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv', 'excel'),
          searchHighlight = TRUE
        ),
        colnames = c("Customer Name", "MSFT's Revenue %", "Customer's Cost %", "3M Price Change"),
        filter = 'top',
        rownames = FALSE
      )
    } else {
      DT::datatable(data.frame(Message = "No customer data available"))
    }
  }, server = FALSE)
  
  output$microsoft_table <- DT::renderDataTable({
    DT::datatable(
      microsoft_data %>%
        select(Rank, Supplier_Name, Industry, Market_Cap_M, Total_Relationship_Size_M, 
               Cost_Category_Percent, Supplier_Source_Revenue_Percent, Size_Source),
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel'),
        searchHighlight = TRUE
      ),
      colnames = c("Rank", "Supplier Name", "Industry", "Market Cap (M)", 
                   "Relationship Size (M)", "Cost Category", "Source Revenue", "Size Source"),
      filter = 'top',
      rownames = FALSE
    ) %>%
      formatCurrency(c("Market_Cap_M", "Total_Relationship_Size_M"), digits = 2, mark = ",")
  }, server = FALSE)
  
  # Google Tab Outputs (unchanged from original)
  output$google_suppliers <- renderValueBox({
    valueBox(
      value = nrow(google_data),
      subtitle = "Total Suppliers",
      icon = icon("list"),
      color = "blue"
    )
  })
  
  output$google_semiconductors <- renderValueBox({
    valueBox(
      value = sum(google_data$Industry == "Semiconductors", na.rm = TRUE),
      subtitle = "Semiconductor Suppliers",
      icon = icon("microchip"),
      color = "green"
    )
  })
  
  output$google_top_relationship <- renderValueBox({
    max_google <- max(google_data$Total_Relationship_Size_M, na.rm = TRUE)
    if(is.finite(max_google)) {
      value_text <- paste0("$", round(max_google/1000, 1), "B")
    } else {
      value_text <- "N/A"
    }
    valueBox(
      value = value_text,
      subtitle = "Top Relationship (SK Hynix)",
      icon = icon("handshake"),
      color = "yellow"
    )
  })
  
  output$google_capex_impact <- renderValueBox({
    valueBox(
      value = "5.28%",
      subtitle = "Top CAPEX Impact",
      icon = icon("chart-line"),
      color = "red"
    )
  })
  
  output$google_industry_plot <- renderPlotly({
    industry_counts <- google_data %>%
      count(Industry, sort = TRUE)
    
    p <- ggplot(industry_counts, aes(x = reorder(Industry, n), y = n)) +
      geom_bar(stat = "identity", fill = "#ff6b6b") +
      coord_flip() +
      theme_minimal() +
      theme(
        plot.background = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA),
        text = element_text(color = "#333"),
        axis.text = element_text(color = "#333"),
        panel.grid = element_line(color = "#e0e0e0")
      ) +
      labs(x = "Industry", y = "Number of Suppliers")
    
    ggplotly(p) %>%
      layout(
        plot_bgcolor = 'white',
        paper_bgcolor = 'white',
        font = list(color = '#333')
      )
  })
  
  output$google_relationships_plot <- renderPlotly({
    google_relationships <- google_data %>%
      filter(!is.na(Total_Relationship_Size_M) & Total_Relationship_Size_M > 0) %>%
      arrange(desc(Total_Relationship_Size_M)) %>%
      head(10)
    
    if(nrow(google_relationships) > 0) {
      p <- ggplot(google_relationships, aes(x = reorder(Supplier_Name, Total_Relationship_Size_M), 
                                            y = Total_Relationship_Size_M/1000)) +
        geom_bar(stat = "identity", fill = "#ff6b6b") +
        coord_flip() +
        theme_minimal() +
        theme(
          plot.background = element_rect(fill = "white", color = NA),
          panel.background = element_rect(fill = "white", color = NA),
          text = element_text(color = "#333"),
          axis.text = element_text(color = "#333"),
          panel.grid = element_line(color = "#e0e0e0")
        ) +
        labs(x = "Supplier", y = "Relationship Size (Billions)")
      
      ggplotly(p) %>%
        layout(
          plot_bgcolor = 'white',
          paper_bgcolor = 'white',
          font = list(color = '#333')
        )
    } else {
      plotly_empty() %>%
        layout(
          title = "No relationship data available",
          plot_bgcolor = 'white',
          paper_bgcolor = 'white'
        )
    }
  })
  
  output$google_table <- DT::renderDataTable({
    DT::datatable(
      google_data %>%
        select(Rank, Supplier_Name, Industry, Market_Cap_M, Total_Relationship_Size_M, 
               Cost_Category_Percent, Supplier_Source_Revenue_Percent, Size_Source),
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel'),
        searchHighlight = TRUE
      ),
      colnames = c("Rank", "Supplier Name", "Industry", "Market Cap (M)", 
                   "Relationship Size (M)", "Cost Category", "Source Revenue", "Size Source"),
      filter = 'top',
      rownames = FALSE
    ) %>%
      formatCurrency(c("Market_Cap_M", "Total_Relationship_Size_M"), digits = 2, mark = ",")
  }, server = FALSE)
  
  # CoreWeave Tab Outputs (unchanged from original)
  output$coreweave_suppliers <- renderValueBox({
    valueBox(
      value = nrow(coreweave_data),
      subtitle = "Total Suppliers",
      icon = icon("list"),
      color = "blue"
    )
  })
  
  output$coreweave_hardware <- renderValueBox({
    valueBox(
      value = sum(coreweave_data$Industry == "Technology Hardware", na.rm = TRUE),
      subtitle = "Tech Hardware Suppliers",
      icon = icon("server"),
      color = "green"
    )
  })
  
  output$coreweave_top_relationship <- renderValueBox({
    max_coreweave <- max(coreweave_data$Total_Relationship_Size_M, na.rm = TRUE)
    if(is.finite(max_coreweave)) {
      value_text <- paste0("$", round(max_coreweave, 1), "M")
    } else {
      value_text <- "N/A"
    }
    valueBox(
      value = value_text,
      subtitle = "Top Relationship (Bloom Energy)",
      icon = icon("handshake"),
      color = "yellow"
    )
  })
  
  output$coreweave_capex_impact <- renderValueBox({
    valueBox(
      value = "0.13%",
      subtitle = "Top CAPEX Impact",
      icon = icon("chart-line"),
      color = "red"
    )
  })
  
  output$coreweave_industry_plot <- renderPlotly({
    industry_counts <- coreweave_data %>%
      count(Industry, sort = TRUE)
    
    p <- ggplot(industry_counts, aes(x = reorder(Industry, n), y = n)) +
      geom_bar(stat = "identity", fill = "#4834d4") +
      coord_flip() +
      theme_minimal() +
      theme(
        plot.background = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA),
        text = element_text(color = "#333"),
        axis.text = element_text(color = "#333"),
        panel.grid = element_line(color = "#e0e0e0")
      ) +
      labs(x = "Industry", y = "Number of Suppliers")
    
    ggplotly(p) %>%
      layout(
        plot_bgcolor = 'white',
        paper_bgcolor = 'white',
        font = list(color = '#333')
      )
  })
  
  output$coreweave_market_cap_plot <- renderPlotly({
    coreweave_filtered <- coreweave_data %>%
      filter(!is.na(Market_Cap_M) & Market_Cap_M > 0)
    
    if(nrow(coreweave_filtered) > 0) {
      p <- ggplot(coreweave_filtered, aes(x = reorder(Supplier_Name, Market_Cap_M), 
                                          y = Market_Cap_M/1000)) +
        geom_bar(stat = "identity", fill = "#4834d4") +
        coord_flip() +
        theme_minimal() +
        theme(
          plot.background = element_rect(fill = "white", color = NA),
          panel.background = element_rect(fill = "white", color = NA),
          text = element_text(color = "#333"),
          axis.text = element_text(color = "#333"),
          panel.grid = element_line(color = "#e0e0e0")
        ) +
        labs(x = "Supplier", y = "Market Cap (Billions)")
      
      ggplotly(p) %>%
        layout(
          plot_bgcolor = 'white',
          paper_bgcolor = 'white',
          font = list(color = '#333')
        )
    } else {
      plotly_empty() %>%
        layout(
          title = "No market cap data available",
          plot_bgcolor = 'white',
          paper_bgcolor = 'white'
        )
    }
  })
  
  output$coreweave_table <- DT::renderDataTable({
    DT::datatable(
      coreweave_data %>%
        select(Rank, Supplier_Name, Industry, Market_Cap_M, Total_Relationship_Size_M, 
               Cost_Category_Percent, Supplier_Source_Revenue_Percent, Size_Source),
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel'),
        searchHighlight = TRUE
      ),
      colnames = c("Rank", "Supplier Name", "Industry", "Market Cap (M)", 
                   "Relationship Size (M)", "Cost Category", "Source Revenue", "Size Source"),
      filter = 'top',
      rownames = FALSE
    ) %>%
      formatCurrency(c("Market_Cap_M", "Total_Relationship_Size_M"), digits = 2, mark = ",")
  }, server = FALSE)
  
  # Cross-Analysis Tab Outputs
  output$common_suppliers_table <- DT::renderDataTable({
    # Identify common suppliers
    common_suppliers_analysis <- supply_chain_data %>%
      group_by(Supplier_Name, Industry) %>%
      summarise(
        Companies = paste(unique(Company), collapse = ", "),
        Company_Count = n_distinct(Company),
        Avg_Market_Cap = mean(Market_Cap_M, na.rm = TRUE),
        Total_Relationships = sum(Total_Relationship_Size_M, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      filter(Company_Count > 1) %>%
      arrange(desc(Company_Count), desc(Avg_Market_Cap))
    
    DT::datatable(
      common_suppliers_analysis,
      options = list(
        pageLength = 15,
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel'),
        searchHighlight = TRUE
      ),
      colnames = c("Supplier Name", "Industry", "Companies Served", "Company Count", 
                   "Avg Market Cap (M)", "Total Relationships (M)"),
      filter = 'top',
      rownames = FALSE
    ) %>%
      formatCurrency(c("Avg_Market_Cap", "Total_Relationships"), digits = 2, mark = ",")
  }, server = FALSE)
  
  output$supplier_overlap_plot <- renderPlotly({
    # Calculate supplier overlaps between companies
    companies <- unique(supply_chain_data$Company)
    overlap_data <- data.frame()
    
    for(i in 1:(length(companies)-1)) {
      for(j in (i+1):length(companies)) {
        comp1_suppliers <- supply_chain_data$Supplier_Name[supply_chain_data$Company == companies[i]]
        comp2_suppliers <- supply_chain_data$Supplier_Name[supply_chain_data$Company == companies[j]]
        common_count <- length(intersect(comp1_suppliers, comp2_suppliers))
        
        overlap_data <- rbind(overlap_data, data.frame(
          Comparison = paste(companies[i], "vs", companies[j]),
          Common_Suppliers = common_count
        ))
      }
    }
    
    p <- ggplot(overlap_data, aes(x = reorder(Comparison, Common_Suppliers), y = Common_Suppliers)) +
      geom_bar(stat = "identity", fill = "#9b59b6") +
      coord_flip() +
      theme_minimal() +
      theme(
        plot.background = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA),
        text = element_text(color = "#333"),
        axis.text = element_text(color = "#333"),
        panel.grid = element_line(color = "#e0e0e0")
      ) +
      labs(x = "Company Pairs", y = "Number of Common Suppliers")
    
    ggplotly(p) %>%
      layout(
        plot_bgcolor = 'white',
        paper_bgcolor = 'white',
        font = list(color = '#333')
      )
  })
  
  output$industry_concentration_plot <- renderPlotly({
    # Calculate industry concentration for each company
    industry_concentration <- supply_chain_data %>%
      group_by(Company, Industry) %>%
      summarise(Count = n(), .groups = 'drop') %>%
      group_by(Company) %>%
      mutate(Percentage = (Count / sum(Count)) * 100) %>%
      ungroup()
    
    p <- ggplot(industry_concentration, aes(x = Company, y = Percentage, fill = Industry)) +
      geom_bar(stat = "identity", position = "stack") +
      scale_fill_brewer(type = "qual", palette = "Set3") +
      theme_minimal() +
      theme(
        plot.background = element_rect(fill = "white", color = NA),
        panel.background = element_rect(fill = "white", color = NA),
        text = element_text(color = "#333"),
        axis.text = element_text(color = "#333"),
        panel.grid = element_line(color = "#e0e0e0"),
        legend.background = element_rect(fill = "white", color = NA),
        legend.text = element_text(color = "#333")
      ) +
      labs(x = "Company", y = "Percentage of Suppliers", fill = "Industry")
    
    ggplotly(p) %>%
      layout(
        plot_bgcolor = 'white',
        paper_bgcolor = 'white',
        font = list(color = '#333'),
        legend = list(bgcolor = 'white', font = list(color = '#333'))
      )
  })
  
  # Risk Comparison Plot (New)
  output$risk_comparison_plot <- renderPlotly({
    # Create risk comparison data
    risk_data <- data.frame(
      Company = character(),
      Risk_Type = character(),
      Count = numeric()
    )
    
    if(!is.null(amzn_risks)) {
      amzn_risk_data <- amzn_risks %>%
        mutate(Company = "Amazon", Count = as.numeric(ifelse(Count == "", 0, Count))) %>%
        select(Company, Risk_Type = Risk, Count)
      risk_data <- rbind(risk_data, amzn_risk_data)
    }
    
    if(!is.null(msft_risks)) {
      msft_risk_data <- msft_risks %>%
        mutate(Company = "Microsoft", Count = as.numeric(Count)) %>%
        select(Company, Risk_Type = Risk, Count)
      risk_data <- rbind(risk_data, msft_risk_data)
    }
    
    if(nrow(risk_data) > 0) {
      p <- ggplot(risk_data, aes(x = Risk_Type, y = Count, fill = Company)) +
        geom_bar(stat = "identity", position = "dodge") +
        scale_fill_manual(values = c("Amazon" = "#ff9f43", "Microsoft" = "#00d2d3")) +
        theme_minimal() +
        theme(
          plot.background = element_rect(fill = "white", color = NA),
          panel.background = element_rect(fill = "white", color = NA),
          text = element_text(color = "#333"),
          axis.text = element_text(color = "#333", angle = 45, hjust = 1),
          panel.grid = element_line(color = "#e0e0e0"),
          legend.background = element_rect(fill = "white", color = NA),
          legend.text = element_text(color = "#333")
        ) +
        labs(x = "Risk Type", y = "Count", fill = "Company")
      
      ggplotly(p) %>%
        layout(
          plot_bgcolor = 'white',
          paper_bgcolor = 'white',
          font = list(color = '#333'),
          legend = list(bgcolor = 'white', font = list(color = '#333'))
        )
    } else {
      plotly_empty() %>%
        layout(
          title = "No risk data available",
          plot_bgcolor = 'white',
          paper_bgcolor = 'white'
        )
    }
  })
  
  output$top_relationships_plot <- renderPlotly({
    # Create top relationships data across all companies
    top_relationships <- supply_chain_data %>%
      filter(!is.na(Total_Relationship_Size_M) & Total_Relationship_Size_M > 0) %>%
      arrange(desc(Total_Relationship_Size_M)) %>%
      head(10) %>%
      mutate(Company_Supplier = paste(Company, "-", Supplier_Name))
    
    if(nrow(top_relationships) > 0) {
      p <- ggplot(top_relationships, aes(x = reorder(Company_Supplier, Total_Relationship_Size_M), 
                                         y = Total_Relationship_Size_M/1000, fill = Company)) +
        geom_bar(stat = "identity") +
        scale_fill_manual(values = c("Amazon" = "#ff9f43", "Microsoft" = "#00d2d3", 
                                     "Google" = "#ff6b6b", "CoreWeave" = "#4834d4")) +
        coord_flip() +
        theme_minimal() +
        theme(
          plot.background = element_rect(fill = "white", color = NA),
          panel.background = element_rect(fill = "white", color = NA),
          text = element_text(color = "#333"),
          axis.text = element_text(color = "#333"),
          panel.grid = element_line(color = "#e0e0e0"),
          legend.background = element_rect(fill = "white", color = NA),
          legend.text = element_text(color = "#333")
        ) +
        labs(x = "Company - Supplier", y = "Relationship Size (Billions)", fill = "Company")
      
      ggplotly(p) %>%
        layout(
          plot_bgcolor = 'white',
          paper_bgcolor = 'white',
          font = list(color = '#333'),
          legend = list(bgcolor = 'white', font = list(color = '#333'))
        )
    } else {
      plotly_empty() %>%
        layout(
          title = "No relationship data available",
          plot_bgcolor = 'white',
          paper_bgcolor = 'white'
        )
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)