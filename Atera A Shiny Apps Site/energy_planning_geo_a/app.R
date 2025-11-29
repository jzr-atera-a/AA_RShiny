# UK Renewable Energy Analysis Dashboard
# NO terra, NO sf, NO raster - Pure leaflet and base R only

# Load ONLY these specific libraries
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(dplyr)
library(ggplot2)
library(readr)
library(leaflet)

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
              "England", "Wales", "England", "England", "England", "England", "England"),
  stringsAsFactors = FALSE
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
    tags$style(HTML("
        .skin-blue .main-header .navbar { background-color: #008A82 !important; }
        .skin-blue .main-header .logo { background-color: #002C3C !important; }
        .skin-blue .main-header .logo:hover { background-color: #008A82 !important; }
        .skin-blue .main-sidebar { background-color: #00A39A !important; }
        .skin-blue .sidebar-menu > li.header { background: #008A82 !important; color: white !important; }
        .skin-blue .sidebar-menu > li > a { color: white !important; }
        .skin-blue .sidebar-menu > li:hover > a,
        .skin-blue .sidebar-menu > li.active > a { background-color: #008A82 !important; color: white !important; }
        .content-wrapper, .right-side { background-color: #002C3C !important; }
        .box { background: #00A39A !important; border-top: none !important; color: white !important; }
        .box-header { background: #00A39A !important; color: white !important; }
        .box-body { background: white !important; color: #2c3e50 !important; }
        .box-title { color: white !important; }
        .metric-box {
          background: white; border-radius: 8px; padding: 15px; margin: 10px 0;
          border-left: 4px solid #00A39A; box-shadow: 0 2px 10px rgba(0,0,0,0.1);
          color: #2c3e50 !important;
        }
        .form-control {
          background-color: rgba(255,255,255,0.9) !important;
          border: 1px solid #bdc3c7 !important; color: #2c3e50 !important;
        }
        .form-control:focus {
          border-color: #008A82 !important;
          box-shadow: 0 0 0 0.2rem rgba(0, 163, 154, 0.25) !important;
        }
        .reference-box {
          background: #f8f9fa; border: 1px solid #dee2e6; border-radius: 8px;
          padding: 15px; margin: 20px 0; font-size: 0.9em; color: #495057;
        }
        .reference-box h5 { color: #00A39A; margin-bottom: 10px; font-weight: bold; }
      ")),
    
    tabItems(
      # First tab: Importance
      tabItem(tabName = "importance",
              fluidRow(
                box(title = "The Strategic Importance of Colocating Energy-Demanding Services Near Renewable Energy Plants",
                    status = "primary", solidHeader = TRUE, width = 12,
                    div(class = "metric-box",
                        h3("Why Colocation Matters", style = "color: #008A82; margin-top: 0;"),
                        p("The strategic placement of energy-intensive services near renewable energy generation sites represents a fundamental shift in how we approach sustainable energy systems."),
                        h4("Key Benefits:", style = "color: #00A39A; margin-top: 20px;"),
                        tags$ul(
                          tags$li(strong("Reduced Transmission Losses:"), " 8-15% energy saved"),
                          tags$li(strong("Grid Stability:"), " Balanced supply and demand"),
                          tags$li(strong("Cost Efficiency:"), " Lower infrastructure costs"),
                          tags$li(strong("Energy Security:"), " Resilient distributed systems"),
                          tags$li(strong("Economic Development:"), " Local job creation")
                        )
                    )
                )
              ),
              fluidRow(
                box(title = "Ideal Industries", status = "primary", solidHeader = TRUE, width = 6,
                    div(class = "metric-box",
                        tags$ul(
                          tags$li(strong("Data Centers")), tags$li(strong("Green Hydrogen Production")),
                          tags$li(strong("EV Charging Hubs")), tags$li(strong("Manufacturing")),
                          tags$li(strong("Cryptocurrency Mining")), tags$li(strong("Desalination Plants"))
                        )
                    )
                ),
                box(title = "Implementation", status = "primary", solidHeader = TRUE, width = 6,
                    div(class = "metric-box",
                        tags$ul(
                          tags$li(strong("Site Assessment")), tags$li(strong("Energy Storage")),
                          tags$li(strong("Smart Grids")), tags$li(strong("Regulatory Coordination"))
                        )
                    )
                )
              )
      ),
      
      # Second tab: Power Plants
      tabItem(tabName = "map",
              fluidRow(
                box(title = "Filter Controls", status = "primary", solidHeader = TRUE, width = 12,
                    fluidRow(
                      column(3, selectInput("region_filter", "Region:", choices = NULL, selected = "All")),
                      column(3, selectInput("country_filter", "Country:", choices = NULL, selected = "All")),
                      column(3, selectInput("technology_filter", "Technology:", choices = NULL, selected = "All")),
                      column(3, selectInput("municipality_filter", "Municipality:", choices = NULL, selected = "All"))
                    )
                )
              ),
              fluidRow(
                box(title = "UK Renewable Energy Plants", status = "primary", solidHeader = TRUE, 
                    width = 8, height = "600px",
                    leafletOutput("power_plant_map", height = "550px")
                ),
                box(title = "Statistics", status = "primary", solidHeader = TRUE, width = 4, height = "600px",
                    div(class = "metric-box", style = "margin-bottom: 15px;",
                        h4("Results", style = "color: #008A82; margin-top: 0;"),
                        verbatimTextOutput("summary_stats")
                    ),
                    div(class = "metric-box",
                        h4("Technology", style = "color: #008A82; margin-top: 0;"),
                        plotlyOutput("technology_chart", height = "200px")
                    ),
                    div(class = "metric-box",
                        h4("By Region", style = "color: #008A82; margin-top: 0;"),
                        plotlyOutput("capacity_chart", height = "150px")
                    )
                )
              ),
              fluidRow(
                box(title = "Detailed Information", status = "primary", solidHeader = TRUE, width = 12,
                    DT::dataTableOutput("plant_table")
                )
              )
      ),
      
      # Third tab: Data Centres
      tabItem(tabName = "datacentres",
              fluidRow(
                box(title = "Filter Controls", status = "primary", solidHeader = TRUE, width = 12,
                    fluidRow(
                      column(3, selectInput("dc_region_filter", "Region:",
                                            choices = c("All", sort(unique(data_centres$region))), selected = "All")),
                      column(3, selectInput("dc_country_filter", "Country:",
                                            choices = c("All", sort(unique(data_centres$country))), selected = "All")),
                      column(3, numericInput("min_datacentres", "Min Data Centres:", value = 1, min = 1, 
                                             max = max(data_centres$count), step = 1)),
                      column(3, selectInput("dc_location_filter", "Location:",
                                            choices = c("All", sort(data_centres$location)), selected = "All"))
                    )
                )
              ),
              fluidRow(
                box(title = "UK Data Centres", status = "primary", solidHeader = TRUE, 
                    width = 8, height = "600px",
                    leafletOutput("datacentre_map", height = "550px")
                ),
                box(title = "Statistics", status = "primary", solidHeader = TRUE, width = 4, height = "600px",
                    div(class = "metric-box", style = "margin-bottom: 15px;",
                        h4("Results", style = "color: #008A82; margin-top: 0;"),
                        verbatimTextOutput("dc_summary_stats")
                    ),
                    div(class = "metric-box",
                        h4("By Region", style = "color: #008A82; margin-top: 0;"),
                        plotlyOutput("dc_region_chart", height = "200px")
                    ),
                    div(class = "metric-box",
                        h4("Top 10", style = "color: #008A82; margin-top: 0;"),
                        plotlyOutput("dc_location_chart", height = "150px")
                    )
                )
              ),
              fluidRow(
                box(title = "Detailed Information", status = "primary", solidHeader = TRUE, width = 12,
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
  
  # Load data
  data <- reactive({
    req(file.exists("renewable_power_plants_UK.csv"))
    df <- read_csv("renewable_power_plants_UK.csv", show_col_types = FALSE)
    df <- df[!is.na(df$lon) & !is.na(df$lat) & !is.na(df$electrical_capacity), ]
    df$electrical_capacity <- as.numeric(df$electrical_capacity)
    df$region <- ifelse(is.na(df$region) | df$region == "", "Unknown", df$region)
    df$country <- ifelse(is.na(df$country) | df$country == "", "Unknown", df$country)
    df$technology <- ifelse(is.na(df$technology) | df$technology == "", "Unknown", df$technology)
    df$municipality <- ifelse(is.na(df$municipality) | df$municipality == "", "Unknown", df$municipality)
    return(df)
  })
  
  # Initialize filters
  observe({
    req(data())
    df <- data()
    updateSelectInput(session, "region_filter", choices = c("All", sort(unique(df$region))))
    updateSelectInput(session, "country_filter", choices = c("All", sort(unique(df$country))))
    updateSelectInput(session, "technology_filter", choices = c("All", sort(unique(df$technology))))
    updateSelectInput(session, "municipality_filter", choices = c("All", sort(unique(df$municipality))))
  })
  
  # Filtered data
  filtered_data <- reactive({
    req(data())
    df <- data()
    if (input$region_filter != "All") df <- df[df$region == input$region_filter, ]
    if (input$country_filter != "All") df <- df[df$country == input$country_filter, ]
    if (input$technology_filter != "All") df <- df[df$technology == input$technology_filter, ]
    if (input$municipality_filter != "All") df <- df[df$municipality == input$municipality_filter, ]
    return(df)
  })
  
  # Update dependent filters
  observe({
    req(data())
    df <- data()
    if (input$region_filter != "All") df <- df[df$region == input$region_filter, ]
    if (input$country_filter != "All") df <- df[df$country == input$country_filter, ]
    if (input$technology_filter != "All") df <- df[df$technology == input$technology_filter, ]
    avail_muni <- c("All", sort(unique(df$municipality)))
    if (!(input$municipality_filter %in% avail_muni)) {
      updateSelectInput(session, "municipality_filter", choices = avail_muni, selected = "All")
    } else {
      updateSelectInput(session, "municipality_filter", choices = avail_muni)
    }
  })
  
  # Filtered DC data
  filtered_dc_data <- reactive({
    df <- data_centres
    if (input$dc_region_filter != "All") df <- df[df$region == input$dc_region_filter, ]
    if (input$dc_country_filter != "All") df <- df[df$country == input$dc_country_filter, ]
    if (input$dc_location_filter != "All") df <- df[df$location == input$dc_location_filter, ]
    df <- df[df$count >= input$min_datacentres, ]
    return(df)
  })
  
  # Color function
  get_tech_color <- function(techs) {
    unique_techs <- unique(techs)
    n <- length(unique_techs)
    colors <- rep(tech_colors, length.out = n)
    names(colors) <- unique_techs
    return(colors)
  }
  
  # Power plant map
  output$power_plant_map <- renderLeaflet({
    req(filtered_data())
    df <- filtered_data()
    if (nrow(df) == 0) {
      return(leaflet() %>% addTiles() %>% setView(-3.5, 55.0, 6) %>%
               addPopups(-3.5, 55.0, "No data"))
    }
    colors_map <- get_tech_color(df$technology)
    map <- leaflet(df) %>% addTiles() %>% setView(-3.5, 55.0, 6)
    for (tech in names(colors_map)) {
      tech_df <- df[df$technology == tech, ]
      if (nrow(tech_df) > 0) {
        map <- addCircleMarkers(map, data = tech_df, lng = ~lon, lat = ~lat,
                                radius = ~pmax(3, pmin(15, electrical_capacity/20)),
                                color = colors_map[tech], fillColor = colors_map[tech],
                                fillOpacity = 0.7, stroke = TRUE, weight = 1,
                                popup = ~paste("<strong>Site:</strong>", 
                                               ifelse(is.na(site_name) | site_name == "", "Unnamed", site_name),
                                               "<br><strong>Tech:</strong>", technology,
                                               "<br><strong>Capacity:</strong>", electrical_capacity, "MW"),
                                group = tech)
      }
    }
    map %>% addLayersControl(overlayGroups = names(colors_map), 
                             options = layersControlOptions(collapsed = FALSE))
  })
  
  # DC map
  output$datacentre_map <- renderLeaflet({
    req(filtered_dc_data())
    df <- filtered_dc_data()
    if (nrow(df) == 0) {
      return(leaflet() %>% addTiles() %>% setView(-3.5, 55.0, 6) %>%
               addPopups(-3.5, 55.0, "No data"))
    }
    pal <- colorNumeric("viridis", df$count)
    leaflet(df) %>% addTiles() %>% setView(-3.5, 55.0, 6) %>%
      addCircleMarkers(lng = ~lon, lat = ~lat, radius = ~pmax(4, pmin(20, count * 1.5)),
                       color = ~pal(count), fillColor = ~pal(count), fillOpacity = 0.7,
                       stroke = TRUE, weight = 1,
                       popup = ~paste("<strong>Location:</strong>", location,
                                      "<br><strong>Data Centres:</strong>", count)) %>%
      addLegend(pal = pal, values = ~count, title = "Count", opacity = 1, position = "bottomright")
  })
  
  # Summary stats
  output$summary_stats <- renderText({
    req(filtered_data())
    df <- filtered_data()
    paste("Total Plants:", nrow(df), "\n",
          "Total Capacity:", round(sum(df$electrical_capacity, na.rm = TRUE), 2), "MW\n",
          "Avg Capacity:", round(mean(df$electrical_capacity, na.rm = TRUE), 2), "MW\n",
          "Technologies:", length(unique(df$technology)), "\n",
          "Regions:", length(unique(df$region)))
  })
  
  output$dc_summary_stats <- renderText({
    req(filtered_dc_data())
    df <- filtered_dc_data()
    paste("Locations:", nrow(df), "\n",
          "Total DCs:", sum(df$count), "\n",
          "Avg per Location:", round(mean(df$count), 2), "\n",
          "Regions:", length(unique(df$region)))
  })
  
  # Charts with error handling
  output$technology_chart <- renderPlotly({
    req(filtered_data())
    df <- filtered_data()
    if (nrow(df) == 0) return(plotly_empty())
    tryCatch({
      tech_summary <- df %>% group_by(technology) %>% 
        summarise(count = n(), .groups = 'drop') %>% arrange(desc(count))
      fills <- rep(tech_colors, length.out = nrow(tech_summary))
      p <- ggplot(tech_summary, aes(x = reorder(technology, count), y = count)) +
        geom_col(fill = fills) + coord_flip() + 
        labs(x = "Technology", y = "Plants") + theme_minimal()
      ggplotly(p, tooltip = c("x", "y")) %>% config(displayModeBar = FALSE)
    }, error = function(e) plotly_empty())
  })
  
  output$capacity_chart <- renderPlotly({
    req(filtered_data())
    df <- filtered_data()
    if (nrow(df) == 0) return(plotly_empty())
    tryCatch({
      reg_summary <- df %>% group_by(region) %>%
        summarise(cap = sum(electrical_capacity, na.rm = TRUE), .groups = 'drop') %>%
        arrange(desc(cap)) %>% head(8)
      p <- ggplot(reg_summary, aes(x = reorder(region, cap), y = cap)) +
        geom_col(fill = tech_colors[2]) + coord_flip() +
        labs(x = "Region", y = "Capacity (MW)") + theme_minimal()
      ggplotly(p, tooltip = c("x", "y")) %>% config(displayModeBar = FALSE)
    }, error = function(e) plotly_empty())
  })
  
  output$dc_region_chart <- renderPlotly({
    req(filtered_dc_data())
    df <- filtered_dc_data()
    if (nrow(df) == 0) return(plotly_empty())
    tryCatch({
      reg_summary <- df %>% group_by(region) %>%
        summarise(total = sum(count), .groups = 'drop') %>% arrange(desc(total))
      p <- ggplot(reg_summary, aes(x = reorder(region, total), y = total)) +
        geom_col(fill = tech_colors[3]) + coord_flip() +
        labs(x = "Region", y = "Data Centres") + theme_minimal()
      ggplotly(p, tooltip = c("x", "y")) %>% config(displayModeBar = FALSE)
    }, error = function(e) plotly_empty())
  })
  
  output$dc_location_chart <- renderPlotly({
    req(filtered_dc_data())
    df <- filtered_dc_data()
    if (nrow(df) == 0) return(plotly_empty())
    tryCatch({
      loc_summary <- df %>% arrange(desc(count)) %>% head(10)
      p <- ggplot(loc_summary, aes(x = reorder(location, count), y = count)) +
        geom_col(fill = tech_colors[4]) + coord_flip() +
        labs(x = "Location", y = "Count") + theme_minimal()
      ggplotly(p, tooltip = c("x", "y")) %>% config(displayModeBar = FALSE)
    }, error = function(e) plotly_empty())
  })
  
  # Tables
  output$plant_table <- DT::renderDataTable({
    req(filtered_data())
    df <- filtered_data()
    display_df <- df[, c("site_name", "technology", "electrical_capacity", 
                         "region", "municipality", "commissioning_date", "operator")]
    names(display_df) <- c("Site", "Technology", "Capacity (MW)", "Region", 
                           "Municipality", "Commissioned", "Operator")
    display_df$Site <- ifelse(is.na(display_df$Site) | display_df$Site == "", "Unnamed", display_df$Site)
    DT::datatable(display_df, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
  })
  
  output$datacentre_table <- DT::renderDataTable({
    req(filtered_dc_data())
    df <- filtered_dc_data()
    display_df <- df[order(-df$count), c("location", "count", "region", "country", "lat", "lon")]
    names(display_df) <- c("Location", "Count", "Region", "Country", "Latitude", "Longitude")
    DT::datatable(display_df, options = list(pageLength = 15, scrollX = TRUE), rownames = FALSE)
  })
}

shinyApp(ui = ui, server = server)