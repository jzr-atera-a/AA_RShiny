library(shiny)
library(plotly)
library(dplyr)

# Generate sample fitness data
set.seed(123)
daily_data <- data.frame(
  date = seq(as.Date("2025-05-01"), as.Date("2025-05-31"), by = "day"),
  steps = sample(5000:12000, 31, replace = TRUE),
  calories = sample(300:800, 31, replace = TRUE),
  distance = sample(3:15, 31, replace = TRUE)
)

ui <- fluidPage(
  tags$head(
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0"),
    tags$style(HTML("
      * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
      }
      
      body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        min-height: 100vh;
        color: #333;
      }
      
      .container-fluid {
        padding: 15px;
        max-width: 100%;
        margin: 0 auto;
      }
      
      @media (min-width: 768px) {
        .container-fluid {
          max-width: 1200px;
          padding: 20px;
        }
      }
      
      .custom-tabs {
        display: flex;
        background: rgba(255, 255, 255, 0.9);
        border-radius: 25px;
        padding: 8px;
        margin-bottom: 20px;
        box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        backdrop-filter: blur(10px);
        overflow-x: auto;
        scrollbar-width: none;
        -ms-overflow-style: none;
      }
      
      .custom-tabs::-webkit-scrollbar {
        display: none;
      }
      
      .section-card {
        background: white;
        border-radius: 20px;
        box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        margin-bottom: 20px;
        overflow: hidden;
        transition: transform 0.3s ease, box-shadow 0.3s ease;
      }
      
      .section-card:hover {
        transform: translateY(-5px);
        box-shadow: 0 15px 40px rgba(0,0,0,0.15);
      }
      
      .card-header {
        background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        color: white;
        padding: 20px;
        text-align: center;
        font-weight: 600;
        font-size: 1.2em;
      }
      
      .card-content {
        padding: 20px;
      }
      
      .stats-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
        gap: 15px;
        margin-bottom: 20px;
      }
      
      .stat-card {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        padding: 20px;
        border-radius: 15px;
        text-align: center;
        box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        transition: transform 0.3s ease;
      }
      
      .stat-card:hover {
        transform: scale(1.05);
      }
      
      .stat-value {
        font-size: 2em;
        font-weight: bold;
        margin-bottom: 5px;
      }
      
      .stat-label {
        font-size: 0.9em;
        opacity: 0.9;
      }
      
      .chart-container {
        background: #f8f9fa;
        border-radius: 15px;
        padding: 20px;
        margin-top: 20px;
        text-align: center;
      }
      
      .simple-chart {
        display: flex;
        align-items: end;
        justify-content: space-between;
        height: 200px;
        margin: 20px 0;
        padding: 10px;
        background: white;
        border-radius: 10px;
        box-shadow: 0 2px 10px rgba(0,0,0,0.1);
      }
      
      .chart-bar {
        background: linear-gradient(to top, #4facfe, #00f2fe);
        border-radius: 4px 4px 0 0;
        margin: 0 2px;
        min-width: 20px;
        position: relative;
        transition: all 0.3s ease;
        display: flex;
        flex-direction: column;
        justify-content: end;
      }
      
      .chart-bar:hover {
        transform: scale(1.05);
        box-shadow: 0 5px 15px rgba(79, 172, 254, 0.3);
      }
      
      .bar-label {
        font-size: 10px;
        color: #666;
        margin-top: 5px;
        text-align: center;
      }
      
      .bar-value {
        position: absolute;
        top: -25px;
        left: 50%;
        transform: translateX(-50%);
        font-size: 10px;
        font-weight: bold;
        color: #666;
        background: white;
        padding: 2px 6px;
        border-radius: 4px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.2);
        opacity: 0;
        transition: opacity 0.3s ease;
      }
      
      .chart-bar:hover .bar-value {
        opacity: 1;
      }
      
      .weekly-circles {
        display: grid;
        grid-template-columns: repeat(7, 1fr);
        gap: 15px;
        margin: 20px 0;
      }
      
      .day-circle {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 8px;
      }
      
      .circle-progress {
        width: 60px;
        height: 60px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: bold;
        color: white;
        font-size: 12px;
        position: relative;
        background: conic-gradient(from 0deg, #4facfe var(--progress), #e0e0e0 var(--progress));
      }
      
      .circle-progress::before {
        content: '';
        position: absolute;
        width: 45px;
        height: 45px;
        border-radius: 50%;
        background: white;
      }
      
      .circle-progress span {
        position: relative;
        z-index: 1;
        color: #333;
        font-weight: 600;
      }
      
      .day-label {
        font-size: 12px;
        color: #666;
        font-weight: 500;
      }
      
      .route-info {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
        gap: 10px;
        margin-top: 15px;
      }
      
      .route-stat {
        background: #e3f2fd;
        padding: 15px;
        border-radius: 10px;
        text-align: center;
        border-left: 4px solid #2196f3;
      }
      
      .route-stat-value {
        font-size: 1.5em;
        font-weight: bold;
        color: #1976d2;
      }
      
      .route-stat-label {
        font-size: 0.8em;
        color: #666;
        margin-top: 5px;
      }
      
      .custom-tabs .shiny-input-radiogroup {
        display: flex;
        width: 100%;
        margin: 0;
      }
      
      .custom-tabs .shiny-input-radiogroup .shiny-options-group {
        display: flex;
        width: 100%;
        margin: 0;
      }
      
      .custom-tabs .radio {
        flex: 1;
        margin: 0;
      }
      
      .custom-tabs input[type='radio'] {
        display: none;
      }
      
      .custom-tabs label {
        display: block;
        width: 100%;
        text-align: center;
        padding: 12px 20px;
        border-radius: 20px;
        font-weight: 500;
        font-size: 14px;
        color: #666;
        cursor: pointer;
        transition: all 0.3s ease;
        margin: 0;
      }
      
      .custom-tabs label:hover {
        color: #4facfe;
        background: rgba(79, 172, 254, 0.1);
      }
      
      .custom-tabs input[type='radio']:checked + label {
        background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        color: white;
        box-shadow: 0 5px 15px rgba(79, 172, 254, 0.3);
        transform: translateY(-1px);
      }
      
      @media (max-width: 768px) {
        .section-card {
          margin-bottom: 15px;
          border-radius: 15px;
        }
        
        .card-content {
          padding: 15px;
        }
        
        .stats-grid {
          grid-template-columns: repeat(2, 1fr);
          gap: 10px;
        }
        
        .stat-card {
          padding: 15px;
        }
        
        .stat-value {
          font-size: 1.5em;
        }
        
        .weekly-circles {
          grid-template-columns: repeat(7, 1fr);
          gap: 8px;
        }
        
        .circle-progress {
          width: 45px;
          height: 45px;
          font-size: 10px;
        }
        
        .circle-progress::before {
          width: 35px;
          height: 35px;
        }
      }
    "))
  ),
  
  div(class = "container-fluid",
      div(class = "custom-tabs",
          radioButtons("selected_tab", "",
                       choices = list("Activity" = "activity", "Routes" = "routes", "Progress" = "progress"),
                       selected = "activity",
                       inline = TRUE
          )
      ),
      
      conditionalPanel(
        condition = "input.selected_tab == 'activity'",
        div(class = "section-card",
            div(class = "card-header", "Today's Activity"),
            div(class = "card-content",
                div(class = "stats-grid",
                    div(class = "stat-card",
                        div(class = "stat-value", "8,254"),
                        div(class = "stat-label", "Steps Today")
                    ),
                    div(class = "stat-card",
                        div(class = "stat-value", "87%"),
                        div(class = "stat-label", "Goal Reached")
                    ),
                    div(class = "stat-card",
                        div(class = "stat-value", "2.3"),
                        div(class = "stat-label", "km Distance")
                    ),
                    div(class = "stat-card",
                        div(class = "stat-value", "1,472"),
                        div(class = "stat-label", "Calories")
                    )
                )
            )
        ),
        
        div(class = "section-card",
            div(class = "card-header", "This Week"),
            div(class = "card-content",
                div(class = "weekly-circles",
                    div(class = "day-circle",
                        div(class = "circle-progress", style = "--progress: 82%", 
                            tags$span("82%")),
                        div(class = "day-label", "M")
                    ),
                    div(class = "day-circle",
                        div(class = "circle-progress", style = "--progress: 95%", 
                            tags$span("95%")),
                        div(class = "day-label", "T")
                    ),
                    div(class = "day-circle",
                        div(class = "circle-progress", style = "--progress: 78%", 
                            tags$span("78%")),
                        div(class = "day-label", "W")
                    ),
                    div(class = "day-circle",
                        div(class = "circle-progress", style = "--progress: 102%", 
                            tags$span("102%")),
                        div(class = "day-label", "T")
                    ),
                    div(class = "day-circle",
                        div(class = "circle-progress", style = "--progress: 89%", 
                            tags$span("89%")),
                        div(class = "day-label", "F")
                    ),
                    div(class = "day-circle",
                        div(class = "circle-progress", style = "--progress: 120%", 
                            tags$span("120%")),
                        div(class = "day-label", "S")
                    ),
                    div(class = "day-circle",
                        div(class = "circle-progress", style = "--progress: 65%", 
                            tags$span("65%")),
                        div(class = "day-label", "S")
                    )
                )
            )
        )
      ),
      
      conditionalPanel(
        condition = "input.selected_tab == 'routes'",
        div(class = "section-card",
            div(class = "card-header", "Today's Route"),
            div(class = "card-content",
                div(style = "height: 500px; border-radius: 15px; overflow: hidden; box-shadow: 0 5px 15px rgba(0,0,0,0.1);",
                    plotlyOutput("route_map", height = "500px")
                ),
                div(class = "route-info",
                    div(class = "route-stat",
                        div(class = "route-stat-value", "8.2"),
                        div(class = "route-stat-label", "km")
                    ),
                    div(class = "route-stat",
                        div(class = "route-stat-value", "52"),
                        div(class = "route-stat-label", "min")
                    ),
                    div(class = "route-stat",
                        div(class = "route-stat-value", "487"),
                        div(class = "route-stat-label", "cal")
                    ),
                    div(class = "route-stat",
                        div(class = "route-stat-value", "145"),
                        div(class = "route-stat-label", "avg BPM")
                    )
                )
            )
        )
      ),
      
      conditionalPanel(
        condition = "input.selected_tab == 'progress'",
        div(class = "section-card",
            div(class = "card-header", "Monthly Progress"),
            div(class = "card-content",
                div(class = "chart-container",
                    h4("Daily Steps This Month", style = "margin-bottom: 15px; color: #666;"),
                    div(class = "simple-chart", id = "monthly-chart")
                )
            )
        ),
        
        div(class = "section-card",
            div(class = "card-header", "Weekly Activity Summary"),
            div(class = "card-content",
                div(class = "chart-container",
                    h4("Average Daily Steps by Weekday", style = "margin-bottom: 15px; color: #666;"),
                    div(class = "simple-chart", id = "weekly-chart")
                )
            )
        )
      )
  ),
  
  tags$script(HTML("
    $(document).ready(function() {
      var monthlyData = [7500, 8200, 6800, 9100, 8500, 7900, 10200, 8800, 9500, 7200, 8900, 9800, 7600, 8400, 9200, 8100, 7800, 9600, 8700, 9300, 7400, 8600, 9100, 7700, 8300, 9400, 8000, 8800, 9000, 7900, 8500];
      
      var weeklyData = [
        {day: 'Mon', steps: 8200},
        {day: 'Tue', steps: 9500},
        {day: 'Wed', steps: 7800},
        {day: 'Thu', steps: 10200},
        {day: 'Fri', steps: 8900},
        {day: 'Sat', steps: 12000},
        {day: 'Sun', steps: 6500}
      ];
      
      function createChart(containerId, data, isWeekly = false) {
        var container = $('#' + containerId);
        var maxValue = Math.max(...(isWeekly ? data.map(d => d.steps) : data));
        
        container.empty();
        
        data.forEach(function(item, index) {
          var value = isWeekly ? item.steps : item;
          var height = (value / maxValue) * 180;
          var label = isWeekly ? item.day : (index + 1);
          
          var bar = $('<div class=\"chart-bar\"></div>');
          bar.css('height', height + 'px');
          bar.append('<div class=\"bar-value\">' + value.toLocaleString() + '</div>');
          bar.append('<div class=\"bar-label\">' + label + '</div>');
          
          container.append(bar);
        });
      }
      
      $('input[name=\"selected_tab\"]').change(function() {
        if ($(this).val() === 'progress') {
          setTimeout(function() {
            createChart('monthly-chart', monthlyData);
            createChart('weekly-chart', weeklyData, true);
          }, 100);
        }
      });
      
      if ($('input[name=\"selected_tab\"]:checked').val() === 'progress') {
        createChart('monthly-chart', monthlyData);
        createChart('weekly-chart', weeklyData, true);
      }
    });
  "))
)

server <- function(input, output, session) {
  
  route_data <- data.frame(
    lat = c(51.5074, 51.5085, 51.5095, 51.5105, 51.5115),
    lon = c(-0.1278, -0.1268, -0.1258, -0.1248, -0.1238),
    point_type = c("start", "waypoint", "waypoint", "waypoint", "end"),
    time = c("9:00", "9:15", "9:30", "9:45", "10:00"),
    stringsAsFactors = FALSE
  )
  
  route_data$hover_text <- paste(
    "<b>", ifelse(route_data$point_type == "start", "Start Point", 
                  ifelse(route_data$point_type == "end", "Finish Point", "Waypoint")), "</b><br>",
    "<b>Time:</b>", route_data$time, "<br>",
    "<b>Location:</b> Central London<br>",
    "<b>Coordinates:</b>", round(route_data$lat, 4), ",", round(route_data$lon, 4)
  )
  
  output$route_map <- renderPlotly({
    tryCatch({
      plot_ly() %>%
        add_trace(
          type = 'scattermapbox',
          mode = 'lines',
          lon = route_data$lon,
          lat = route_data$lat,
          line = list(color = '#4facfe', width = 6),
          hoverinfo = 'skip',
          showlegend = FALSE
        ) %>%
        add_trace(
          type = 'scattermapbox',
          mode = 'markers',
          lon = list(route_data$lon[1]),
          lat = list(route_data$lat[1]),
          marker = list(size = 15, color = '#4caf50'),
          text = route_data$hover_text[1],
          hovertemplate = "%{text}<extra></extra>",
          showlegend = FALSE
        ) %>%
        add_trace(
          type = 'scattermapbox',
          mode = 'markers',
          lon = list(route_data$lon[5]),
          lat = list(route_data$lat[5]),
          marker = list(size = 15, color = '#f44336'),
          text = route_data$hover_text[5],
          hovertemplate = "%{text}<extra></extra>",
          showlegend = FALSE
        ) %>%
        layout(
          mapbox = list(
            style = 'open-street-map',
            center = list(lon = -0.1278, lat = 51.5074),
            zoom = 14
          ),
          showlegend = FALSE,
          margin = list(l = 0, r = 0, t = 0, b = 0)
        ) %>%
        config(displayModeBar = FALSE)
    }, error = function(e) {
      plot_ly(
        data = route_data,
        x = ~lon,
        y = ~lat,
        type = 'scatter',
        mode = 'lines+markers',
        line = list(color = '#4facfe', width = 3),
        marker = list(
          size = c(12, 6, 6, 6, 12),
          color = c('#4caf50', '#2196f3', '#2196f3', '#2196f3', '#f44336')
        ),
        text = ~hover_text,
        hovertemplate = "%{text}<extra></extra>"
      ) %>%
        layout(
          title = "Route Map",
          xaxis = list(title = "Longitude"),
          yaxis = list(title = "Latitude"),
          showlegend = FALSE
        ) %>%
        config(displayModeBar = FALSE)
    })
  })
}

shinyApp(ui = ui, server = server)