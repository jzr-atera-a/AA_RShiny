# Load required libraries
library(shiny)
library(shinydashboard)
library(leaflet)
library(DT)
library(plotly)
library(dplyr)
library(ggplot2)
library(readr)
library(RColorBrewer)

# Define color palette for different technologies
tech_colors <- c(
  "#008A82", "#00A39A", "#002C3C", "#FF6B6B", "#4ECDC4", 
  "#45B7D1", "#F9CA24", "#6C5B7B", "#C44569", "#F8B500",
  "#2ECC71", "#E74C3C", "#9B59B6", "#1ABC9C", "#F39C12"
)

# UI
ui <- dashboardPage(
  dashboardHeader(title = "UK Renewable Energy Analysis"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Energy Colocation Importance", tabName = "importance", icon = icon("info-circle")),
      menuItem("Interactive Power Plant Map", tabName = "map", icon = icon("map"))
    )
  ),
  
  dashboardBody(
    # Custom CSS styling
    tags$style(HTML("
        .skin-blue .main-header .navbar {
          background-color: #008A82 !important;
        }
        
        .skin-blue .main-header .logo {
          background-color: #002C3C !important;
        }
        
        .skin-blue .main-header .logo:hover {
          background-color: #008A82 !important;
        }
        
        .skin-blue .main-sidebar {
          background-color: #00A39A !important;
        }
        
        .skin-blue .sidebar-menu > li.header {
          background: #008A82 !important;
          color: white !important;
        }
        
        .skin-blue .sidebar-menu > li > a {
          color: white !important;
        }
        
        .skin-blue .sidebar-menu > li:hover > a,
        .skin-blue .sidebar-menu > li.active > a {
          background-color: #008A82 !important;
          color: white !important;
        }
        
        .content-wrapper, .right-side {
          background-color: #002C3C !important;
        }
        
        .box {
          background: #00A39A !important;
          border-top: none !important;
          color: white !important;
        }
        
        .box-header {
          background: #00A39A !important;
          color: white !important;
        }
        
        .box-body {
          background: white !important;
          color: #2c3e50 !important;
        }
        
        .box-title {
          color: white !important;
        }
        
        .metric-box {
          background: white;
          border-radius: 8px;
          padding: 15px;
          margin: 10px 0;
          border-left: 4px solid #00A39A;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
          color: #2c3e50 !important;
        }
        
        .network-container {
          height: 600px;
          border: 1px solid #ddd;
          border-radius: 8px;
          background: white;
        }
        
        .form-control {
          background-color: rgba(255,255,255,0.9) !important;
          border: 1px solid #bdc3c7 !important;
          color: #2c3e50 !important;
        }
        
        .form-control:focus {
          border-color: #008A82 !important;
          box-shadow: 0 0 0 0.2rem rgba(0, 163, 154, 0.25) !important;
        }
        
        .reference-box {
          background: #f8f9fa;
          border: 1px solid #dee2e6;
          border-radius: 8px;
          padding: 15px;
          margin: 20px 0;
          font-size: 0.9em;
          color: #495057;
        }
        
        .reference-box h5 {
          color: #00A39A;
          margin-bottom: 10px;
          font-weight: bold;
        }
      ")),
    
    tabItems(
      # First tab: Importance of Energy Colocation
      tabItem(tabName = "importance",
              fluidRow(
                box(
                  title = "The Strategic Importance of Colocating Energy-Demanding Services Near Renewable Energy Plants",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  height = "auto",
                  
                  div(class = "metric-box",
                      h3("Why Colocation Matters", style = "color: #008A82; margin-top: 0;"),
                      p("The strategic placement of energy-intensive services near renewable energy generation sites represents a fundamental shift in how we approach sustainable energy systems. This approach offers significant advantages in terms of efficiency, cost reduction, and environmental impact."),
                      
                      h4("Key Benefits of Energy Colocation:", style = "color: #00A39A; margin-top: 20px;"),
                      
                      tags$ul(
                        tags$li(strong("Reduced Transmission Losses:"), " By locating energy consumers close to generation sources, we minimize the energy lost during long-distance transmission, which can account for 8-15% of generated electricity."),
                        tags$li(strong("Grid Stability:"), " Local consumption of renewable energy reduces strain on the national grid and helps balance supply and demand fluctuations inherent in renewable sources."),
                        tags$li(strong("Cost Efficiency:"), " Reduced transmission infrastructure needs and lower transmission charges result in significant cost savings for both producers and consumers."),
                        tags$li(strong("Enhanced Energy Security:"), " Distributed energy systems with local consumption are more resilient to grid failures and external disruptions."),
                        tags$li(strong("Economic Development:"), " Energy-intensive industries located near renewable plants can create local jobs and stimulate regional economic growth.")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Ideal Industries for Renewable Energy Colocation",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  
                  div(class = "metric-box",
                      h4("High Energy-Intensity Industries:", style = "color: #008A82;"),
                      tags$ul(
                        tags$li(strong("Data Centers:"), " Require 24/7 power supply and can benefit from direct renewable connections"),
                        tags$li(strong("Green Hydrogen Production:"), " Electrolysis plants can utilize excess renewable capacity"),
                        tags$li(strong("Electric Vehicle Charging Hubs:"), " Strategic placement along transport corridors"),
                        tags$li(strong("Manufacturing:"), " Steel, aluminum, and chemical processing facilities"),
                        tags$li(strong("Cryptocurrency Mining:"), " Can provide flexible load management services"),
                        tags$li(strong("Desalination Plants:"), " Water treatment facilities with high energy demands"),
                        tags$li(strong("Cold Storage Facilities:"), " Food processing and pharmaceutical storage")
                      )
                  )
                ),
                
                box(
                  title = "Implementation Strategies",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  
                  div(class = "metric-box",
                      h4("Best Practices for Colocation:", style = "color: #008A82;"),
                      tags$ul(
                        tags$li(strong("Site Assessment:"), " Evaluate renewable resource availability, grid connection capacity, and land use compatibility"),
                        tags$li(strong("Energy Storage Integration:"), " Combine battery storage to manage intermittency and provide grid services"),
                        tags$li(strong("Smart Grid Technologies:"), " Implement advanced monitoring and control systems for optimal energy management"),
                        tags$li(strong("Regulatory Coordination:"), " Work with local authorities for planning permissions and grid connection agreements"),
                        tags$li(strong("Community Engagement:"), " Ensure local stakeholder buy-in and address environmental concerns"),
                        tags$li(strong("Scalable Design:"), " Plan for future expansion and technology upgrades")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Environmental and Economic Impact",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  div(class = "metric-box",
                      h4("Quantifiable Benefits:", style = "color: #008A82;"),
                      
                      fluidRow(
                        column(4,
                               div(style = "text-align: center; padding: 20px; border-radius: 8px; background: linear-gradient(135deg, #008A82, #00A39A); color: white; margin: 10px;",
                                   h3("8-15%", style = "margin: 0; font-size: 2.5em;"),
                                   p("Reduction in transmission losses", style = "margin: 5px 0 0 0;")
                               )
                        ),
                        column(4,
                               div(style = "text-align: center; padding: 20px; border-radius: 8px; background: linear-gradient(135deg, #00A39A, #008A82); color: white; margin: 10px;",
                                   h3("25-40%", style = "margin: 0; font-size: 2.5em;"),
                                   p("Cost reduction potential", style = "margin: 5px 0 0 0;")
                               )
                        ),
                        column(4,
                               div(style = "text-align: center; padding: 20px; border-radius: 8px; background: linear-gradient(135deg, #002C3C, #008A82); color: white; margin: 10px;",
                                   h3("50-70%", style = "margin: 0; font-size: 2.5em;"),
                                   p("Improved grid stability", style = "margin: 5px 0 0 0;")
                               )
                        )
                      ),
                      
                      div(class = "reference-box",
                          h5("References and Further Reading"),
                          p("• International Energy Agency (2023). 'Renewable Energy Market Update'"),
                          p("• UK Department for Business, Energy & Industrial Strategy (2024). 'Energy Infrastructure Strategy'"),
                          p("• European Commission (2023). 'Smart Grids and Energy Storage Systems'"),
                          p("• National Grid ESO (2024). 'Future Energy Scenarios Report'")
                      )
                  )
                )
              )
      ),
      
      # Second tab: Interactive Map
      tabItem(tabName = "map",
              fluidRow(
                box(
                  title = "Filter Controls",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(3,
                           selectInput("region_filter", "Select Region:",
                                       choices = NULL,
                                       selected = "All"
                           )
                    ),
                    column(3,
                           selectInput("country_filter", "Select Country:",
                                       choices = NULL,
                                       selected = "All"
                           )
                    ),
                    column(3,
                           selectInput("technology_filter", "Select Technology:",
                                       choices = NULL,
                                       selected = "All"
                           )
                    ),
                    column(3,
                           selectInput("municipality_filter", "Select Municipality:",
                                       choices = NULL,
                                       selected = "All"
                           )
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "UK Renewable Energy Plants Location Map",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  height = "600px",
                  
                  leafletOutput("power_plant_map", height = "550px")
                ),
                
                box(
                  title = "Summary Statistics",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 4,
                  height = "600px",
                  
                  div(class = "metric-box", style = "margin-bottom: 15px;",
                      h4("Filtered Results", style = "color: #008A82; margin-top: 0;"),
                      verbatimTextOutput("summary_stats")
                  ),
                  
                  div(class = "metric-box",
                      h4("Technology Distribution", style = "color: #008A82; margin-top: 0;"),
                      plotlyOutput("technology_chart", height = "200px")
                  ),
                  
                  div(class = "metric-box",
                      h4("Capacity by Region", style = "color: #008A82; margin-top: 0;"),
                      plotlyOutput("capacity_chart", height = "150px")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Detailed Plant Information",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  DT::dataTableOutput("plant_table")
                )
              )
      )
    )
  ),
  
  skin = "blue"
)

# Server
server <- function(input, output, session) {
  
  # Load data
  data <- reactive({
    req(file.exists("renewable_power_plants_UK.csv"))
    df <- read_csv("renewable_power_plants_UK.csv", show_col_types = FALSE)
    
    # Clean and prepare data
    df <- df %>%
      filter(!is.na(lon), !is.na(lat), !is.na(electrical_capacity)) %>%
      mutate(
        electrical_capacity = as.numeric(electrical_capacity),
        region = ifelse(is.na(region) | region == "", "Unknown Region", region),
        country = ifelse(is.na(country) | country == "", "Unknown Country", country),
        technology = ifelse(is.na(technology) | technology == "", "Unknown Technology", technology),
        municipality = ifelse(is.na(municipality) | municipality == "", "Unknown Municipality", municipality),
        popup_text = paste(
          "<strong>", ifelse(is.na(site_name) | site_name == "", "Unnamed Site", site_name), "</strong><br/>",
          "Technology: ", technology, "<br/>",
          "Capacity: ", electrical_capacity, " MW<br/>",
          "Region: ", region, "<br/>",
          "Municipality: ", municipality, "<br/>",
          "Commissioned: ", ifelse(is.na(commissioning_date), "Unknown", commissioning_date)
        )
      )
    
    return(df)
  })
  
  # Initialize filter choices
  observe({
    req(data())
    df <- data()
    
    # Update region choices
    region_choices <- c("All", sort(unique(df$region)))
    updateSelectInput(session, "region_filter", choices = region_choices)
    
    # Update country choices
    country_choices <- c("All", sort(unique(df$country)))
    updateSelectInput(session, "country_filter", choices = country_choices)
    
    # Update technology choices
    tech_choices <- c("All", sort(unique(df$technology)))
    updateSelectInput(session, "technology_filter", choices = tech_choices)
    
    # Update municipality choices
    municipality_choices <- c("All", sort(unique(df$municipality)))
    updateSelectInput(session, "municipality_filter", choices = municipality_choices)
  })
  
  # Filtered data based on user selections
  filtered_data <- reactive({
    req(data())
    df <- data()
    
    if (input$region_filter != "All") {
      df <- df %>% filter(region == input$region_filter)
    }
    
    if (input$country_filter != "All") {
      df <- df %>% filter(country == input$country_filter)
    }
    
    if (input$technology_filter != "All") {
      df <- df %>% filter(technology == input$technology_filter)
    }
    
    if (input$municipality_filter != "All") {
      df <- df %>% filter(municipality == input$municipality_filter)
    }
    
    return(df)
  })
  
  # Update dependent filters
  observe({
    req(data())
    df <- data()
    
    # Filter based on current selections for dependent dropdowns
    if (input$region_filter != "All") {
      df <- df %>% filter(region == input$region_filter)
    }
    if (input$country_filter != "All") {
      df <- df %>% filter(country == input$country_filter)
    }
    if (input$technology_filter != "All") {
      df <- df %>% filter(technology == input$technology_filter)
    }
    
    # Update municipality choices based on other filters
    available_municipalities <- c("All", sort(unique(df$municipality)))
    if (input$municipality_filter %in% available_municipalities) {
      updateSelectInput(session, "municipality_filter", choices = available_municipalities)
    } else {
      updateSelectInput(session, "municipality_filter", choices = available_municipalities, selected = "All")
    }
  })
  
  # Render map
  output$power_plant_map <- renderLeaflet({
    req(filtered_data())
    df <- filtered_data()
    
    if (nrow(df) == 0) {
      return(leaflet() %>% 
               addTiles() %>%
               setView(lng = -3.5, lat = 55.0, zoom = 6))
    }
    
    # Create color palette for technologies
    unique_techs <- unique(df$technology)
    colors <- tech_colors[1:length(unique_techs)]
    names(colors) <- unique_techs
    
    # Create color function
    color_func <- colorFactor(colors, domain = unique_techs)
    
    leaflet(df) %>%
      addTiles() %>%
      addCircleMarkers(
        lng = ~lon,
        lat = ~lat,
        popup = ~popup_text,
        radius = ~pmax(3, pmin(15, sqrt(electrical_capacity))),
        color = ~color_func(technology),
        fillColor = ~color_func(technology),
        fillOpacity = 0.7,
        stroke = TRUE,
        weight = 2
      ) %>%
      addLegend(
        position = "bottomright",
        pal = color_func,
        values = ~technology,
        title = "Technology Type",
        opacity = 1
      ) %>%
      setView(lng = -3.5, lat = 55.0, zoom = 6)
  })
  
  # Summary statistics
  output$summary_stats <- renderText({
    req(filtered_data())
    df <- filtered_data()
    
    total_plants <- nrow(df)
    total_capacity <- round(sum(df$electrical_capacity, na.rm = TRUE), 2)
    avg_capacity <- round(mean(df$electrical_capacity, na.rm = TRUE), 2)
    unique_techs <- length(unique(df$technology))
    unique_regions <- length(unique(df$region))
    
    paste(
      "Total Plants:", total_plants, "\n",
      "Total Capacity:", total_capacity, "MW\n",
      "Average Capacity:", avg_capacity, "MW\n",
      "Technologies:", unique_techs, "\n",
      "Regions:", unique_regions
    )
  })
  
  # Technology distribution chart
  output$technology_chart <- renderPlotly({
    req(filtered_data())
    df <- filtered_data()
    
    if (nrow(df) == 0) return(NULL)
    
    tech_summary <- df %>%
      group_by(technology) %>%
      summarise(count = n(), .groups = 'drop') %>%
      arrange(desc(count))
    
    p <- ggplot(tech_summary, aes(x = reorder(technology, count), y = count)) +
      geom_col(fill = tech_colors[1:nrow(tech_summary)]) +
      coord_flip() +
      labs(x = "Technology", y = "Number of Plants") +
      theme_minimal() +
      theme(
        text = element_text(size = 10),
        axis.text.y = element_text(size = 8)
      )
    
    ggplotly(p, tooltip = c("x", "y")) %>%
      config(displayModeBar = FALSE)
  })
  
  # Capacity by region chart
  output$capacity_chart <- renderPlotly({
    req(filtered_data())
    df <- filtered_data()
    
    if (nrow(df) == 0) return(NULL)
    
    region_summary <- df %>%
      group_by(region) %>%
      summarise(total_capacity = sum(electrical_capacity, na.rm = TRUE), .groups = 'drop') %>%
      arrange(desc(total_capacity)) %>%
      head(8)  # Show top 8 regions
    
    p <- ggplot(region_summary, aes(x = reorder(region, total_capacity), y = total_capacity)) +
      geom_col(fill = tech_colors[2]) +
      coord_flip() +
      labs(x = "Region", y = "Total Capacity (MW)") +
      theme_minimal() +
      theme(
        text = element_text(size = 10),
        axis.text.y = element_text(size = 8)
      )
    
    ggplotly(p, tooltip = c("x", "y")) %>%
      config(displayModeBar = FALSE)
  })
  
  # Data table
  output$plant_table <- DT::renderDataTable({
    req(filtered_data())
    df <- filtered_data()
    
    display_df <- df %>%
      select(
        `Site Name` = site_name,
        `Technology` = technology,
        `Capacity (MW)` = electrical_capacity,
        `Region` = region,
        `Municipality` = municipality,
        `Commissioned` = commissioning_date,
        `Operator` = operator
      ) %>%
      mutate(
        `Site Name` = ifelse(is.na(`Site Name`) | `Site Name` == "", "Unnamed Site", `Site Name`),
        `Commissioned` = ifelse(is.na(`Commissioned`), "Unknown", `Commissioned`),
        `Operator` = ifelse(is.na(`Operator`) | `Operator` == "", "Unknown", `Operator`)
      )
    
    DT::datatable(
      display_df,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        autoWidth = TRUE
      ),
      rownames = FALSE
    )
  })
}

# Run the application
shinyApp(ui = ui, server = server)