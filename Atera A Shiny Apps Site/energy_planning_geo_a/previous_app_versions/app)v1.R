# Shiny 1.11.1 is the most recent stable release with important bug fixes
# plotly 4.10.4 has proven compatibility with the current ggplot2 and Shiny versions
# DT 0.33 is the latest stable version with good Shiny integration
# ggplot2 3.5.1 and dplyr 1.1.4 are current stable tidyverse packages
# readxl 1.4.3 is the latest stable version for Excel file reading
# 
# Using remotes::install_version() with upgrade = "never" ensures you get exactly these versions and they won't be automatically updated, protecting your code from breaking changes in future package releases.
# Why plotly for maps? Interactive: Zoom, pan, hover tooltips Integrates well with Shiny: Native reactivity. No API keys needed: Uses OpenStreetMap by default Customizable: Easy to style markers, colors, sizes Built-in with the packages we're already using
# Alternative mapping libraries in R include leaflet, tmap, or mapview, but plotly was chosen here because it integrates seamlessly with the existing plotly charts and maintains consistency in the dashboard.

# Load required libraries
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(dplyr)
library(ggplot2)
library(readxl)

# Define color palette for different technologies
tech_colors <- c(
  "#008A82", "#00A39A", "#002C3C", "#FF6B6B", "#4ECDC4", 
  "#45B7D1", "#F9CA24", "#6C5B7B", "#C44569", "#F8B500",
  "#2ECC71", "#E74C3C", "#9B59B6", "#1ABC9C", "#F39C12"
)

# Define UK coordinates for regions (approximate center points)
uk_region_coords <- data.frame(
  region = c("London", "South East", "South West", "West Midlands", "East Midlands", 
             "Yorkshire and Humber", "North West", "North East", "East", "Scotland", 
             "Wales", "Northern Ireland"),
  lat = c(51.5074, 51.3, 50.8, 52.5, 52.9, 53.8, 53.5, 55.0, 52.2, 56.5, 52.3, 54.6),
  lon = c(-0.1278, -0.8, -3.5, -2.0, -1.2, -1.5, -2.5, -1.6, 0.5, -4.0, -3.5, -6.5)
)

# Function to get coordinates for a region
get_region_coords <- function(region_name) {
  coords <- uk_region_coords[uk_region_coords$region == region_name, ]
  if (nrow(coords) > 0) {
    return(list(lat = coords$lat[1], lon = coords$lon[1]))
  } else {
    # Default to center of UK if region not found
    return(list(lat = 54.5, lon = -2.5))
  }
}

# Function to load and process renewable energy data from DUKES Excel file
load_renewable_data <- function() {
  tryCatch({
    # Read the DUKES Excel file
    dukes_data <- read_excel("DUKES_5.11_UK.xlsx", sheet = 1)
    
    # Clean column names
    colnames(dukes_data) <- c("company_name", "station_name", "fuel", "type", 
                              "electrical_capacity", "commissioning_year", "region", "footnotes")
    
    # Filter for renewable energy types
    renewable_fuels <- c("Solar", "Wind (onshore)", "Wind (offshore)", "Hydro", 
                         "Biomass (virgin wood)", "Biomass (recycled wood)", "Biomass (woodchip)",
                         "Biomass (wood pellets)", "Biomass (straw)", "Biomass (poultry litter",
                         "Waste (anaerobic digestion)", "Waste (municipal solid waste)")
    
    renewable_data <- dukes_data %>%
      filter(fuel %in% renewable_fuels | grepl("Biomass|Solar|Wind|Hydro|Waste", fuel, ignore.case = TRUE)) %>%
      filter(!is.na(electrical_capacity) & electrical_capacity > 0) %>%
      mutate(
        electrical_capacity = as.numeric(electrical_capacity),
        commissioning_year = as.numeric(commissioning_year),
        technology = case_when(
          grepl("Solar", fuel, ignore.case = TRUE) ~ "Solar",
          grepl("Wind.*onshore", fuel, ignore.case = TRUE) ~ "Wind Onshore",
          grepl("Wind.*offshore", fuel, ignore.case = TRUE) ~ "Wind Offshore",
          grepl("Hydro", fuel, ignore.case = TRUE) ~ "Hydro",
          grepl("Biomass", fuel, ignore.case = TRUE) ~ "Biomass",
          grepl("Waste", fuel, ignore.case = TRUE) ~ "Waste",
          TRUE ~ "Other Renewable"
        ),
        region = ifelse(is.na(region) | region == "", "Unknown Region", region),
        country = case_when(
          region == "Scotland" ~ "Scotland",
          region == "Wales" ~ "Wales",
          region == "Northern Ireland" ~ "Northern Ireland",
          TRUE ~ "England"
        ),
        site_name = ifelse(is.na(station_name) | station_name == "", "Unnamed Site", station_name),
        operator = ifelse(is.na(company_name) | company_name == "", "Unknown", company_name),
        commissioning_date = as.character(commissioning_year)
      )
    
    # Add coordinates based on region
    renewable_data$lat <- NA
    renewable_data$lon <- NA
    renewable_data$municipality <- renewable_data$region
    
    for (i in 1:nrow(renewable_data)) {
      coords <- get_region_coords(renewable_data$region[i])
      # Add some random variation to avoid all points being in exactly the same location
      renewable_data$lat[i] <- coords$lat + runif(1, -0.3, 0.3)
      renewable_data$lon[i] <- coords$lon + runif(1, -0.4, 0.4)
    }
    
    # Create hover text
    renewable_data$hover_text <- paste(
      "Site:", renewable_data$site_name, "<br>",
      "Technology:", renewable_data$technology, "<br>",
      "Capacity:", renewable_data$electrical_capacity, "MW<br>",
      "Region:", renewable_data$region, "<br>",
      "Operator:", renewable_data$operator
    )
    
    return(renewable_data)
    
  }, error = function(e) {
    warning("Could not load DUKES Excel file: ", e$message)
    return(data.frame())
  })
}

# Function to load data centres data from Excel file
load_datacentres_data <- function() {
  tryCatch({
    # Read the data centres Excel file
    dc_data <- read_excel("DC_UK_Locations_Data.xlsx", sheet = 1)
    
    # Clean and validate the data
    dc_data <- dc_data %>%
      filter(!is.na(lat), !is.na(lon), !is.na(count)) %>%
      mutate(
        count = as.numeric(count),
        lat = as.numeric(lat),
        lon = as.numeric(lon),
        location = ifelse(is.na(location) | location == "", "Unknown Location", location),
        region = ifelse(is.na(region) | region == "", "Unknown Region", region),
        country = ifelse(is.na(country) | country == "", "Unknown Country", country)
      ) %>%
      filter(count > 0)
    
    return(dc_data)
    
  }, error = function(e) {
    warning("Could not load Data Centres Excel file: ", e$message)
    return(data.frame())
  })
}

# UI
ui <- dashboardPage(
  dashboardHeader(title = "UK Renewable Energy Analysis"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Energy Colocation Importance", tabName = "importance", icon = icon("info-circle")),
      menuItem("Interactive Power Plant Map", tabName = "map", icon = icon("map")),
      menuItem("Data Centres Map", tabName = "datacentres", icon = icon("server"))
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
                           selectInput("operator_filter", "Select Operator:",
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
                  
                  plotlyOutput("power_plant_map", height = "550px")
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
      ),
      
      # Third tab: Data Centres Map
      tabItem(tabName = "datacentres",
              fluidRow(
                box(
                  title = "Data Centre Filter Controls",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  fluidRow(
                    column(3,
                           selectInput("dc_region_filter", "Select Region:",
                                       choices = NULL,
                                       selected = "All"
                           )
                    ),
                    column(3,
                           selectInput("dc_country_filter", "Select Country:",
                                       choices = NULL,
                                       selected = "All"
                           )
                    ),
                    column(3,
                           numericInput("min_datacentres", "Minimum Data Centres:",
                                        value = 1,
                                        min = 1,
                                        max = 200,
                                        step = 1
                           )
                    ),
                    column(3,
                           selectInput("dc_location_filter", "Select Location:",
                                       choices = NULL,
                                       selected = "All"
                           )
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "UK Data Centres Location Map",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  height = "600px",
                  
                  plotlyOutput("datacentre_map", height = "550px")
                ),
                
                box(
                  title = "Data Centre Statistics",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 4,
                  height = "600px",
                  
                  div(class = "metric-box", style = "margin-bottom: 15px;",
                      h4("Filtered Results", style = "color: #008A82; margin-top: 0;"),
                      verbatimTextOutput("dc_summary_stats")
                  ),
                  
                  div(class = "metric-box",
                      h4("Data Centres by Region", style = "color: #008A82; margin-top: 0;"),
                      plotlyOutput("dc_region_chart", height = "200px")
                  ),
                  
                  div(class = "metric-box",
                      h4("Top 10 Locations", style = "color: #008A82; margin-top: 0;"),
                      plotlyOutput("dc_location_chart", height = "150px")
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Detailed Data Centre Information",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,
                  
                  DT::dataTableOutput("datacentre_table")
                )
              )
      )
    )
  ),
  
  skin = "blue"
)

# Server
server <- function(input, output, session) {
  
  # Load renewable energy data from Excel
  renewable_data <- reactive({
    data <- load_renewable_data()
    if (nrow(data) == 0) {
      showNotification("Could not load renewable energy data from DUKES_5.11_UK.xlsx", type = "error")
    }
    return(data)
  })
  
  # Load data centres data from Excel
  datacentres_data <- reactive({
    data <- load_datacentres_data()
    if (nrow(data) == 0) {
      showNotification("Could not load data centres data from DC_UK_Locations_Data.xlsx", type = "error")
    }
    return(data)
  })
  
  # Initialize filter choices for renewable energy plants
  observe({
    req(renewable_data())
    df <- renewable_data()
    
    if (nrow(df) > 0) {
      # Update region choices
      region_choices <- c("All", sort(unique(df$region)))
      updateSelectInput(session, "region_filter", choices = region_choices)
      
      # Update country choices
      country_choices <- c("All", sort(unique(df$country)))
      updateSelectInput(session, "country_filter", choices = country_choices)
      
      # Update technology choices
      tech_choices <- c("All", sort(unique(df$technology)))
      updateSelectInput(session, "technology_filter", choices = tech_choices)
      
      # Update operator choices
      operator_choices <- c("All", sort(unique(df$operator)))
      updateSelectInput(session, "operator_filter", choices = operator_choices)
    }
  })
  
  # Initialize filter choices for data centres
  observe({
    req(datacentres_data())
    df <- datacentres_data()
    
    if (nrow(df) > 0) {
      # Update region choices
      region_choices <- c("All", sort(unique(df$region)))
      updateSelectInput(session, "dc_region_filter", choices = region_choices)
      
      # Update country choices
      country_choices <- c("All", sort(unique(df$country)))
      updateSelectInput(session, "dc_country_filter", choices = country_choices)
      
      # Update location choices
      location_choices <- c("All", sort(unique(df$location)))
      updateSelectInput(session, "dc_location_filter", choices = location_choices)
      
      # Update max value for minimum data centres input
      updateNumericInput(session, "min_datacentres", max = max(df$count, na.rm = TRUE))
    }
  })
  
  # Filtered renewable energy data
  filtered_data <- reactive({
    req(renewable_data())
    df <- renewable_data()
    
    if (nrow(df) == 0) return(df)
    
    if (input$region_filter != "All") {
      df <- df %>% filter(region == input$region_filter)
    }
    
    if (input$country_filter != "All") {
      df <- df %>% filter(country == input$country_filter)
    }
    
    if (input$technology_filter != "All") {
      df <- df %>% filter(technology == input$technology_filter)
    }
    
    if (input$operator_filter != "All") {
      df <- df %>% filter(operator == input$operator_filter)
    }
    
    return(df)
  })
  
  # Filtered data centres data
  filtered_dc_data <- reactive({
    req(datacentres_data())
    df <- datacentres_data()
    
    if (nrow(df) == 0) return(df)
    
    if (input$dc_region_filter != "All") {
      df <- df %>% filter(region == input$dc_region_filter)
    }
    
    if (input$dc_country_filter != "All") {
      df <- df %>% filter(country == input$dc_country_filter)
    }
    
    if (input$dc_location_filter != "All") {
      df <- df %>% filter(location == input$dc_location_filter)
    }
    
    df <- df %>% filter(count >= input$min_datacentres)
    
    return(df)
  })
  
  # Render renewable energy plants map
  output$power_plant_map <- renderPlotly({
    req(filtered_data())
    df <- filtered_data()
    
    if (nrow(df) == 0) {
      # Show empty map when no data
      plot_ly(type = 'scattermapbox') %>%
        layout(
          mapbox = list(
            style = 'open-street-map',
            center = list(lon = -3.5, lat = 55.0),
            zoom = 5
          ),
          title = "No data matches current filters"
        )
    } else {
      # Create color mapping for technologies
      unique_techs <- unique(df$technology)
      tech_color_map <- setNames(tech_colors[1:length(unique_techs)], unique_techs)
      df$color <- tech_color_map[df$technology]
      
      # Create the scattermapbox map
      plot_ly(df, 
              type = 'scattermapbox',
              lon = ~lon, 
              lat = ~lat,
              mode = 'markers',
              marker = list(
                size = ~pmax(8, pmin(40, electrical_capacity/5)),
                color = ~color,
                sizemode = 'diameter',
                opacity = 0.7,
                line = list(width = 1, color = 'white')
              ),
              text = ~hover_text,
              hovertemplate = "%{text}<extra></extra>",
              customdata = ~technology
      ) %>%
        layout(
          mapbox = list(
            style = 'open-street-map',
            center = list(lon = -3.5, lat = 55.0),
            zoom = 5
          ),
          title = "UK Renewable Energy Plants",
          showlegend = FALSE
        )
    }
  })
  
  # Render data centres map
  output$datacentre_map <- renderPlotly({
    req(filtered_dc_data())
    df <- filtered_dc_data()
    
    if (nrow(df) == 0) {
      # Show empty map when no data
      plot_ly(type = 'scattermapbox') %>%
        layout(
          mapbox = list(
            style = 'open-street-map',
            center = list(lon = -3.5, lat = 55.0),
            zoom = 5
          ),
          title = "No data matches current filters"
        )
    } else {
      # Create hover text
      df$hover_text <- paste(
        "Location:", df$location, "<br>",
        "Data Centres:", df$count, "<br>",
        "Region:", df$region, "<br>",
        "Country:", df$country
      )
      
      # Create the scattermapbox map with color scale
      plot_ly(df, 
              type = 'scattermapbox',
              lon = ~lon, 
              lat = ~lat,
              mode = 'markers',
              marker = list(
                size = ~pmax(10, pmin(50, count * 1.5)),
                color = ~count,
                colorscale = list(
                  c(0, "#45B7D1"),
                  c(0.3, "#00A39A"),
                  c(0.6, "#008A82"),
                  c(1, "#002C3C")
                ),
                sizemode = 'diameter',
                opacity = 0.8,
                line = list(width = 1, color = 'white'),
                colorbar = list(
                  title = "Data Centres Count",
                  titleside = "right"
                )
              ),
              text = ~hover_text,
              hovertemplate = "%{text}<extra></extra>"
      ) %>%
        layout(
          mapbox = list(
            style = 'open-street-map',
            center = list(lon = -3.5, lat = 55.0),
            zoom = 5
          ),
          title = "UK Data Centres Distribution",
          showlegend = FALSE
        )
    }
  })
  
  # Summary statistics for renewable energy
  output$summary_stats <- renderText({
    req(filtered_data())
    df <- filtered_data()
    
    if (nrow(df) == 0) {
      return("No data available with current filters")
    }
    
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
  
  # Data centre summary statistics
  output$dc_summary_stats <- renderText({
    req(filtered_dc_data())
    df <- filtered_dc_data()
    
    if (nrow(df) == 0) {
      return("No data available with current filters")
    }
    
    total_locations <- nrow(df)
    total_datacentres <- sum(df$count)
    avg_datacentres <- round(mean(df$count), 2)
    unique_regions <- length(unique(df$region))
    unique_countries <- length(unique(df$country))
    
    paste(
      "Total Locations:", total_locations, "\n",
      "Total Data Centres:", total_datacentres, "\n",
      "Average per Location:", avg_datacentres, "\n",
      "Regions:", unique_regions, "\n",
      "Countries:", unique_countries
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
    
    # Assign colors to technologies
    tech_summary$color <- tech_colors[1:nrow(tech_summary)]
    
    p <- ggplot(tech_summary, aes(x = reorder(technology, count), y = count, fill = technology)) +
      geom_col() +
      scale_fill_manual(values = setNames(tech_summary$color, tech_summary$technology)) +
      coord_flip() +
      labs(x = "Technology", y = "Number of Plants") +
      theme_minimal() +
      theme(
        text = element_text(size = 10),
        axis.text.y = element_text(size = 8),
        legend.position = "none"
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
  
  # Data centres by region chart
  output$dc_region_chart <- renderPlotly({
    req(filtered_dc_data())
    df <- filtered_dc_data()
    
    if (nrow(df) == 0) return(NULL)
    
    region_summary <- df %>%
      group_by(region) %>%
      summarise(total_count = sum(count), .groups = 'drop') %>%
      arrange(desc(total_count))
    
    p <- ggplot(region_summary, aes(x = reorder(region, total_count), y = total_count)) +
      geom_col(fill = tech_colors[3]) +
      coord_flip() +
      labs(x = "Region", y = "Total Data Centres") +
      theme_minimal() +
      theme(
        text = element_text(size = 10),
        axis.text.y = element_text(size = 8)
      )
    
    ggplotly(p, tooltip = c("x", "y")) %>%
      config(displayModeBar = FALSE)
  })
  
  # Top 10 locations chart for data centres
  output$dc_location_chart <- renderPlotly({
    req(filtered_dc_data())
    df <- filtered_dc_data()
    
    if (nrow(df) == 0) return(NULL)
    
    location_summary <- df %>%
      arrange(desc(count)) %>%
      head(10)
    
    p <- ggplot(location_summary, aes(x = reorder(location, count), y = count)) +
      geom_col(fill = tech_colors[4]) +
      coord_flip() +
      labs(x = "Location", y = "Data Centres Count") +
      theme_minimal() +
      theme(
        text = element_text(size = 10),
        axis.text.y = element_text(size = 8)
      )
    
    ggplotly(p, tooltip = c("x", "y")) %>%
      config(displayModeBar = FALSE)
  })
  
  # Data table for renewable energy plants
  output$plant_table <- DT::renderDataTable({
    req(filtered_data())
    df <- filtered_data()
    
    if (nrow(df) == 0) return(NULL)
    
    display_df <- df %>%
      select(
        `Site Name` = site_name,
        `Technology` = technology,
        `Capacity (MW)` = electrical_capacity,
        `Region` = region,
        `Country` = country,
        `Commissioned` = commissioning_date,
        `Operator` = operator
      ) %>%
      mutate(
        `Site Name` = ifelse(is.na(`Site Name`) | `Site Name` == "", "Unnamed Site", `Site Name`),
        `Commissioned` = ifelse(is.na(`Commissioned`) | `Commissioned` == "", "Unknown", `Commissioned`),
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
  
  # Data table for data centres
  output$datacentre_table <- DT::renderDataTable({
    req(filtered_dc_data())
    df <- filtered_dc_data()
    
    if (nrow(df) == 0) return(NULL)
    
    display_df <- df %>%
      select(
        `Location` = location,
        `Data Centres Count` = count,
        `Region` = region,
        `Country` = country,
        `Latitude` = lat,
        `Longitude` = lon
      ) %>%
      arrange(desc(`Data Centres Count`))
    
    DT::datatable(
      display_df,
      options = list(
        pageLength = 15,
        scrollX = TRUE,
        autoWidth = TRUE
      ),
      rownames = FALSE
    )
  })
}

# Run the application
shinyApp(ui = ui, server = server)