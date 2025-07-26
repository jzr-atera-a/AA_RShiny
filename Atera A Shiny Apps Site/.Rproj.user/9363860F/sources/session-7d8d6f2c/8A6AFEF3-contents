# Load required libraries (NO terra dependencies)
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(dplyr)
library(ggplot2)
library(readr)
library(leaflet)  # Replace problematic maps with leaflet

# Define color palette for different technologies
tech_colors <- c(
  "#008A82", "#00A39A", "#002C3C", "#FF6B6B", "#4ECDC4", 
  "#45B7D1", "#F9CA24", "#6C5B7B", "#C44569", "#F8B500",
  "#2ECC71", "#E74C3C", "#9B59B6", "#1ABC9C", "#F39C12"
)

# Data centres data with coordinates
data_centres <- data.frame(
  location = c("London", "Manchester", "Liverpool", "Newcastle", "Cardiff", "Slough", "Leeds", 
               "Edinburgh", "Birmingham UK", "Cambridge", "Farnborough", "Milton Keynes", "Kent", 
               "Portsmouth", "Berkshire", "Woking", "Belfast", "Peterborough", "Nottingham", "Derby", 
               "Glasgow", "Bedford", "Redhill", "Wakefield", "Northamptonshire", "Bournemouth", 
               "South Wales", "Sheffield", "Reigate", "Halifax", "Poole", "York", "Swindon", 
               "Stevenage", "Colchester", "Newbury", "Fleet", "Guildford", "Somerset", "Telford", 
               "Luton", "Middlesbrough", "Aberdeen", "Essex", "Coventry", "Crawley", "Blackpool", 
               "Blyth", "Cheltenham", "Dundee", "Durham", "Gloucester", "Hertford", "High Wycombe", 
               "Lincolnshire", "Londonderry", "Norwich", "Southampton", "Bristol UK", "Hull", 
               "Oxfordshire", "Exeter", "Bolton", "Chester", "Crewe", "Cumnock", "Falmouth", 
               "Fareham", "Glenrothes", "Leicester", "Leiston", "North Wales", "Shropshire", 
               "Surrey", "Welwyn Garden City", "Wherstead", "Wiltshire"),
  count = c(177, 29, 8, 8, 12, 19, 15, 6, 20, 8, 9, 5, 5, 9, 10, 5, 5, 2, 5, 2, 5, 2, 1, 1, 2, 4, 
            2, 5, 1, 2, 2, 3, 4, 3, 2, 2, 1, 1, 1, 1, 4, 4, 3, 3, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
            1, 1, 1, 8, 5, 5, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1),
  lat = c(51.5074, 53.4808, 53.4084, 54.9783, 51.4816, 51.5105, 53.8008, 55.9533, 52.4862, 52.2053, 
          51.2877, 52.0406, 51.2787, 50.8198, 51.4584, 51.3148, 54.5973, 52.5755, 52.9548, 52.9225, 
          55.8642, 52.1372, 51.2407, 53.6833, 52.2405, 50.7192, 51.6214, 53.3811, 51.2362, 53.7248, 
          50.7156, 53.9590, 51.5581, 51.9012, 51.8959, 51.4014, 51.2798, 51.2362, 51.1500, 52.6851, 
          51.8787, 54.5742, 57.1497, 51.7365, 52.4068, 51.1132, 53.8175, 55.1278, 51.8994, 56.4620, 
          54.7753, 51.8642, 51.7963, 51.6281, 53.2307, 54.9966, 52.6309, 50.9097, 51.4545, 53.7457, 
          51.7520, 50.7184, 53.5770, 53.1906, 53.0982, 55.4520, 50.1503, 50.8429, 56.1165, 52.6369, 
          52.2081, 53.0833, 52.6708, 51.2362, 51.8014, 52.0406, 51.3428),
  lon = c(-0.1278, -2.2426, -2.9916, -1.6178, -3.1791, -0.5950, -1.5491, -3.1883, -1.8904, 0.1218, 
          -0.7645, -0.7594, 1.0789, -1.0880, -0.9738, -0.5582, -5.9301, -0.2405, -1.1581, -1.4746, 
          -4.2518, -0.4669, -0.1687, -1.4990, -0.8936, -1.8795, -3.1791, -1.4659, -0.1951, -1.8590, 
          -1.9872, -1.0781, -1.7849, -0.2008, 0.8998, -1.3232, -0.8432, -0.5895, -3.1067, -2.4440, 
          -0.4040, -1.2348, -2.0943, 0.4691, -1.5197, -0.1873, -3.0518, -1.4777, -2.0769, -2.9707, 
          -1.5849, -2.2431, -0.2395, -0.7548, -0.4040, -7.3086, 1.2974, -1.4043, -2.5879, -0.3369, 
          -1.2577, -3.5339, -2.4282, -2.8912, -2.4460, -4.2026, -5.0527, -1.3089, -3.1570, -1.0856, 
          1.6121, -3.0833, -2.6708, -0.5895, -0.2006, -0.7594, -1.8785),
  region = c("London", "North West", "North West", "North East", "Wales", "South East", "Yorkshire", 
             "Scotland", "West Midlands", "East", "South East", "South East", "South East", "South East", 
             "South East", "South East", "Northern Ireland", "East", "East Midlands", "East Midlands", 
             "Scotland", "East", "South East", "Yorkshire", "East Midlands", "South West", "Wales", 
             "Yorkshire", "South East", "Yorkshire", "South West", "Yorkshire", "South West", "East", 
             "East", "South East", "South East", "South East", "South West", "West Midlands", "East", 
             "North East", "Scotland", "East", "West Midlands", "South East", "North West", "North East", 
             "South West", "Scotland", "North East", "South West", "East", "South East", "East Midlands", 
             "Northern Ireland", "East", "South East", "South West", "Yorkshire", "South East", "South West", 
             "North West", "North West", "North West", "Scotland", "South West", "South East", "Scotland", 
             "East Midlands", "East", "Wales", "West Midlands", "South East", "East", "East", "South West"),
  country = c("England", "England", "England", "England", "Wales", "England", "England", "Scotland", 
              "England", "England", "England", "England", "England", "England", "England", "England", 
              "Northern Ireland", "England", "England", "England", "Scotland", "England", "England", 
              "England", "England", "England", "Wales", "England", "England", "England", "England", 
              "England", "England", "England", "England", "England", "England", "England", "England", 
              "England", "England", "England", "Scotland", "England", "England", "England", "England", 
              "England", "England", "Scotland", "England", "England", "England", "England", "England", 
              "Northern Ireland", "England", "England", "England", "England", "England", "England", 
              "England", "England", "England", "Scotland", "England", "England", "Scotland", "England", 
              "England", "Wales", "England", "England", "England", "England", "England")
)

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
                                       choices = c("All", sort(unique(data_centres$region))),
                                       selected = "All"
                           )
                    ),
                    column(3,
                           selectInput("dc_country_filter", "Select Country:",
                                       choices = c("All", sort(unique(data_centres$country))),
                                       selected = "All"
                           )
                    ),
                    column(3,
                           numericInput("min_datacentres", "Minimum Data Centres:",
                                        value = 1,
                                        min = 1,
                                        max = max(data_centres$count),
                                        step = 1
                           )
                    ),
                    column(3,
                           selectInput("dc_location_filter", "Select Location:",
                                       choices = c("All", sort(data_centres$location)),
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
                  
                  leafletOutput("datacentre_map", height = "550px")
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
  
  # Load renewable energy data
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
        municipality = ifelse(is.na(municipality) | municipality == "", "Unknown Municipality", municipality)
      )
    
    return(df)
  })
  
  # Initialize filter choices for renewable energy plants
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
  
  # Filtered renewable energy data
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
  
  # Update dependent filters for renewable energy
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
  
  # Filtered data centres data
  filtered_dc_data <- reactive({
    df <- data_centres
    
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
  
  # Create color palette function for technologies
  get_tech_color <- function(technologies) {
    unique_techs <- unique(technologies)
    n_techs <- length(unique_techs)
    colors <- tech_colors[1:min(n_techs, length(tech_colors))]
    names(colors) <- unique_techs
    return(colors)
  }
  
  # Render renewable energy plants map using leaflet
  output$power_plant_map <- renderLeaflet({
    req(filtered_data())
    df <- filtered_data()
    
    if (nrow(df) == 0) {
      # Show empty map when no data
      leaflet() %>%
        addTiles() %>%
        setView(lng = -3.5, lat = 55.0, zoom = 6) %>%
        addPopups(lng = -3.5, lat = 55.0, "No data matches current filters")
    } else {
      # Get color palette for technologies
      tech_colors_map <- get_tech_color(df$technology)
      
      # Create leaflet map
      map <- leaflet(df) %>%
        addTiles() %>%
        setView(lng = -3.5, lat = 55.0, zoom = 6)
      
      # Add circles with colors based on technology
      for (tech in names(tech_colors_map)) {
        tech_data <- df %>% filter(technology == tech)
        if (nrow(tech_data) > 0) {
          map <- map %>%
            addCircleMarkers(
              data = tech_data,
              lng = ~lon, 
              lat = ~lat,
              radius = ~pmax(3, pmin(15, electrical_capacity/20)),
              color = tech_colors_map[tech],
              fillColor = tech_colors_map[tech],
              fillOpacity = 0.7,
              stroke = TRUE,
              weight = 1,
              popup = ~paste(
                "<strong>Site:</strong>", ifelse(is.na(site_name) | site_name == "", "Unnamed Site", site_name), "<br>",
                "<strong>Technology:</strong>", technology, "<br>",
                "<strong>Capacity:</strong>", electrical_capacity, "MW<br>",
                "<strong>Region:</strong>", region, "<br>",
                "<strong>Municipality:</strong>", municipality
              ),
              group = tech
            )
        }
      }
      
      # Add layers control
      map <- map %>%
        addLayersControl(
          overlayGroups = names(tech_colors_map),
          options = layersControlOptions(collapsed = FALSE)
        )
      
      return(map)
    }
  })
  
  # Render data centres map using leaflet
  output$datacentre_map <- # Render data centres map using leaflet
    output$datacentre_map <- renderLeaflet({
      req(filtered_dc_data())
      df <- filtered_dc_data()
      
      if (nrow(df) == 0) {
        # Show empty map when no data
        leaflet() %>%
          addTiles() %>%
          setView(lng = -3.5, lat = 55.0, zoom = 6) %>%
          addPopups(lng = -3.5, lat = 55.0, "No data matches current filters")
      } else {
        # Create color palette based on count
        pal <- colorNumeric(
          palette = "viridis",
          domain = df$count
        )
        
        # Create leaflet map
        leaflet(df) %>%
          addTiles() %>%
          setView(lng = -3.5, lat = 55.0, zoom = 6) %>%
          addCircleMarkers(
            lng = ~lon, 
            lat = ~lat,
            radius = ~pmax(4, pmin(20, count * 1.5)),
            color = ~pal(count),
            fillColor = ~pal(count),
            fillOpacity = 0.7,
            stroke = TRUE,
            weight = 1,
            popup = ~paste(
              "<strong>Location:</strong>", location, "<br>",
              "<strong>Data Centres:</strong>", count, "<br>",
              "<strong>Region:</strong>", region, "<br>",
              "<strong>Country:</strong>", country
            )
          ) %>%
          addLegend(
            pal = pal,
            values = ~count,
            title = "Data Centres Count",
            opacity = 1,
            position = "bottomright"
          )
      }
    })
  
  # Summary statistics for renewable energy
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
  
  # Data centre summary statistics
  output$dc_summary_stats <- renderText({
    req(filtered_dc_data())
    df <- filtered_dc_data()
    
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
  
  # Data table for data centres
  output$datacentre_table <- DT::renderDataTable({
    req(filtered_dc_data())
    df <- filtered_dc_data()
    
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