library(shiny)
library(plotly)
library(dplyr)

# Generate sample fitness data
set.seed(123)
fitness_activities <- data.frame(
  date = rep(seq(as.Date("2025-09-15"), as.Date("2025-09-21"), by = "day"), each = 4),
  time = rep(c("09:00", "09:30", "11:00", "11:45"), 7),
  activity = rep(c("Morning Run", "Stretching", "Gym Session", "Cool Down"), 7),
  duration = rep(c(45, 15, 60, 20), 7),
  calories = rep(c(387, 45, 520, 85), 7),
  stringsAsFactors = FALSE
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
        background: linear-gradient(135deg, #ff9a9e 0%, #fecfef 50%, #fecfef 100%);
        min-height: 100vh;
        color: #333;
        overflow-x: hidden;
      }
      
      .mobile-container {
        max-width: 400px;
        margin: 0 auto;
        background: white;
        min-height: 100vh;
        position: relative;
        box-shadow: 0 0 20px rgba(0,0,0,0.1);
      }
      
      .status-bar {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 8px 20px;
        font-size: 14px;
        font-weight: 600;
        background: white;
        border-bottom: 1px solid #f0f0f0;
      }
      
      .status-left {
        font-size: 16px;
      }
      
      .status-right {
        display: flex;
        align-items: center;
        gap: 5px;
      }
      
      .signal-bars {
        display: flex;
        gap: 2px;
      }
      
      .bar {
        width: 3px;
        background: #333;
        border-radius: 1px;
      }
      
      .bar:nth-child(1) { height: 4px; }
      .bar:nth-child(2) { height: 6px; }
      .bar:nth-child(3) { height: 8px; }
      .bar:nth-child(4) { height: 10px; }
      
      .battery {
        width: 24px;
        height: 12px;
        border: 1px solid #333;
        border-radius: 2px;
        position: relative;
        margin-left: 5px;
      }
      
      .battery::after {
        content: '';
        position: absolute;
        right: -3px;
        top: 3px;
        width: 2px;
        height: 6px;
        background: #333;
        border-radius: 0 1px 1px 0;
      }
      
      .battery-fill {
        width: 80%;
        height: 100%;
        background: #4caf50;
        border-radius: 1px;
      }
      
      .header {
        padding: 20px;
        background: white;
        display: flex;
        justify-content: space-between;
        align-items: center;
      }
      
      .hamburger {
        font-size: 24px;
        cursor: pointer;
        color: #666;
      }
      
      .profile-pic {
        width: 40px;
        height: 40px;
        border-radius: 50%;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        font-weight: bold;
        font-size: 16px;
      }
      
      .title-section {
        padding: 0 20px 20px;
        background: white;
      }
      
      .main-title {
        font-size: 28px;
        font-weight: bold;
        color: #333;
        margin-bottom: 5px;
      }
      
      .subtitle {
        color: #999;
        font-size: 16px;
      }
      
      .calendar-header {
        display: flex;
        justify-content: space-between;
        padding: 0 20px;
        margin-bottom: 15px;
        background: white;
      }
      
      .day-column {
        text-align: center;
        flex: 1;
        padding: 10px 5px;
      }
      
      .day-name {
        font-size: 12px;
        color: #999;
        margin-bottom: 8px;
        font-weight: 500;
      }
      
      .day-number {
        font-size: 18px;
        font-weight: 600;
        color: #333;
        width: 32px;
        height: 32px;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 0 auto;
        cursor: pointer;
        transition: all 0.2s ease;
      }
      
      .day-number:hover {
        background: #f5f5f5;
      }
      
      .day-number.today {
        background: #6c5ce7;
        color: white;
        box-shadow: 0 4px 12px rgba(108, 92, 231, 0.3);
      }
      
      .schedule-container {
        background: #f8f9fa;
        flex: 1;
        border-radius: 25px 25px 0 0;
        padding: 25px 20px;
        margin-top: 10px;
        min-height: 60vh;
      }
      
      .activity-item {
        display: flex;
        align-items: center;
        background: white;
        padding: 15px;
        margin-bottom: 12px;
        border-radius: 16px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.06);
        border-left: 4px solid;
        cursor: pointer;
        transition: transform 0.2s ease, box-shadow 0.2s ease;
      }
      
      .activity-item:hover {
        transform: translateY(-2px);
        box-shadow: 0 4px 16px rgba(0,0,0,0.1);
      }
      
      .activity-item.morning { border-left-color: #4caf50; }
      .activity-item.afternoon { border-left-color: #ff9800; }
      .activity-item.evening { border-left-color: #9c27b0; }
      .activity-item.night { border-left-color: #3f51b5; }
      
      .time-column {
        min-width: 60px;
        margin-right: 15px;
      }
      
      .activity-time {
        font-size: 14px;
        color: #666;
        font-weight: 600;
      }
      
      .activity-duration {
        font-size: 11px;
        color: #999;
        margin-top: 2px;
      }
      
      .activity-content {
        flex: 1;
      }
      
      .activity-title {
        font-size: 16px;
        font-weight: 600;
        color: #333;
        margin-bottom: 4px;
      }
      
      .activity-details {
        font-size: 13px;
        color: #666;
      }
      
      .add-button {
        position: fixed;
        bottom: 30px;
        right: 30px;
        width: 56px;
        height: 56px;
        background: #6c5ce7;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        font-size: 24px;
        box-shadow: 0 8px 24px rgba(108, 92, 231, 0.4);
        cursor: pointer;
        transition: transform 0.2s ease;
        border: none;
        z-index: 1000;
      }
      
      .add-button:hover {
        transform: scale(1.1);
      }
      
      .route-modal {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0,0,0,0.5);
        display: none;
        z-index: 2000;
      }
      
      .route-content {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        background: white;
        border-radius: 20px;
        padding: 20px;
        width: 90%;
        max-width: 350px;
        max-height: 70vh;
        overflow-y: auto;
      }
      
      .modal-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 15px;
      }
      
      .modal-title {
        font-size: 18px;
        font-weight: 600;
      }
      
      .close-button {
        font-size: 24px;
        cursor: pointer;
        color: #666;
        background: none;
        border: none;
      }
      
      .stats-row {
        display: flex;
        justify-content: space-around;
        margin: 15px 0;
      }
      
      .stat-item {
        text-align: center;
      }
      
      .stat-value {
        font-size: 20px;
        font-weight: bold;
        color: #6c5ce7;
      }
      
      .stat-label {
        font-size: 12px;
        color: #666;
        margin-top: 4px;
      }
      
      .empty-state {
        text-align: center;
        padding: 40px 20px;
        color: #999;
      }
      
      .empty-icon {
        font-size: 48px;
        margin-bottom: 15px;
        opacity: 0.3;
      }
      
      .empty-text {
        font-size: 16px;
        margin-bottom: 8px;
      }
      
      .empty-subtext {
        font-size: 14px;
        opacity: 0.8;
      }
      
      @media (max-width: 380px) {
        .mobile-container {
          max-width: 100%;
        }
        
        .day-column {
          padding: 8px 3px;
        }
        
        .activity-item {
          padding: 12px;
        }
        
        .add-button {
          right: 20px;
          bottom: 20px;
          width: 50px;
          height: 50px;
        }
      }
    "))
  ),
  
  div(class = "mobile-container",
      # Status bar
      div(class = "status-bar",
          div(class = "status-left", "9:41"),
          div(class = "status-right",
              div(class = "signal-bars",
                  div(class = "bar"),
                  div(class = "bar"),
                  div(class = "bar"),
                  div(class = "bar")
              ),
              span("📶 📶 📢"),
              div(class = "battery",
                  div(class = "battery-fill")
              )
          )
      ),
      
      # Header
      div(class = "header",
          div(class = "hamburger", "☰"),
          div(class = "profile-pic", "JD")
      ),
      
      # Title section
      div(class = "title-section",
          div(class = "main-title", "My week"),
          div(class = "subtitle", "September, 15 - 21")
      ),
      
      # Calendar header
      div(class = "calendar-header",
          div(class = "day-column",
              div(class = "day-name", "Mon"),
              div(class = "day-number", "15")
          ),
          div(class = "day-column",
              div(class = "day-name", "Tue"),
              div(class = "day-number", "16")
          ),
          div(class = "day-column",
              div(class = "day-name", "Wed"),
              div(class = "day-number today", "17")
          ),
          div(class = "day-column",
              div(class = "day-name", "Thu"),
              div(class = "day-number", "18")
          ),
          div(class = "day-column",
              div(class = "day-name", "Fri"),
              div(class = "day-number", "19")
          ),
          div(class = "day-column",
              div(class = "day-name", "Sat"),
              div(class = "day-number", "20")
          ),
          div(class = "day-column",
              div(class = "day-name", "Sun"),
              div(class = "day-number", "21")
          )
      ),
      
      # Schedule container
      div(class = "schedule-container",
          uiOutput("schedule_content")
      ),
      
      # Add button
      tags$button(class = "add-button", onclick = "showRouteModal()", "+")
  ),
  
  # Route modal
  div(class = "route-modal", id = "routeModal",
      div(class = "route-content",
          div(class = "modal-header",
              div(class = "modal-title", "Today's Route"),
              tags$button(class = "close-button", onclick = "hideRouteModal()", "×")
          ),
          div(style = "height: 300px; margin: 15px 0;",
              plotlyOutput("route_map", height = "300px")
          ),
          div(class = "stats-row",
              div(class = "stat-item",
                  div(class = "stat-value", "8.2"),
                  div(class = "stat-label", "km")
              ),
              div(class = "stat-item",
                  div(class = "stat-value", "52"),
                  div(class = "stat-label", "min")
              ),
              div(class = "stat-item",
                  div(class = "stat-value", "487"),
                  div(class = "stat-label", "cal")
              ),
              div(class = "stat-item",
                  div(class = "stat-value", "145"),
                  div(class = "stat-label", "avg BPM")
              )
          )
      )
  ),
  
  tags$script(HTML("
    function showRouteModal() {
      document.getElementById('routeModal').style.display = 'block';
    }
    
    function hideRouteModal() {
      document.getElementById('routeModal').style.display = 'none';
    }
    
    // Sample activities for today (Wednesday)
    var todayActivities = [
      {time: '09:00', duration: '45 min', title: 'Morning Run', details: '5K riverside route', type: 'morning'},
      {time: '09:30', duration: '15 min', title: 'Stretching', details: 'Post-run flexibility', type: 'morning'},
      {time: '11:00', duration: '60 min', title: 'Gym Session', details: 'Upper body strength', type: 'afternoon'},
      {time: '11:45', duration: '20 min', title: 'Cool Down', details: 'Sauna & hydration', type: 'afternoon'}
    ];
    
    function renderTodaySchedule() {
      var container = document.querySelector('.schedule-container');
      var html = '';
      
      if (todayActivities.length === 0) {
        html = '<div class=\"empty-state\"><div class=\"empty-icon\">🏃</div><div class=\"empty-text\">No activities today</div><div class=\"empty-subtext\">Tap + to add your first workout</div></div>';
      } else {
        todayActivities.forEach(function(activity) {
          html += '<div class=\"activity-item ' + activity.type + '\">' +
                    '<div class=\"time-column\">' +
                      '<div class=\"activity-time\">' + activity.time + '</div>' +
                      '<div class=\"activity-duration\">' + activity.duration + '</div>' +
                    '</div>' +
                    '<div class=\"activity-content\">' +
                      '<div class=\"activity-title\">' + activity.title + '</div>' +
                      '<div class=\"activity-details\">' + activity.details + '</div>' +
                    '</div>' +
                  '</div>';
        });
      }
      
      container.innerHTML = html;
    }
    
    // Initialize on page load
    $(document).ready(function() {
      renderTodaySchedule();
    });
    
    // Close modal when clicking outside
    document.getElementById('routeModal').addEventListener('click', function(e) {
      if (e.target === this) {
        hideRouteModal();
      }
    });
  "))
)

server <- function(input, output, session) {
  
  output$schedule_content <- renderUI({
    # This will be populated by JavaScript
    div()
  })
  
  output$route_map <- renderPlotly({
    route_data <- data.frame(
      lat = c(51.5074, 51.5085, 51.5095, 51.5105, 51.5115),
      lon = c(-0.1278, -0.1268, -0.1258, -0.1248, -0.1238),
      point_type = c("start", "waypoint", "waypoint", "waypoint", "end"),
      stringsAsFactors = FALSE
    )
    
    route_data$hover_text <- paste(
      "<b>", ifelse(route_data$point_type == "start", "Start Point", 
                    ifelse(route_data$point_type == "end", "Finish Point", "Waypoint")), "</b><br>",
      "<b>Location:</b> Central London<br>",
      "<b>Coordinates:</b>", round(route_data$lat, 4), ",", round(route_data$lon, 4)
    )
    
    plot_ly(route_data, 
            type = 'scattermapbox',
            lon = ~lon, 
            lat = ~lat,
            mode = 'markers+lines',
            marker = list(
              size = c(12, 6, 6, 6, 12),
              color = c('#4caf50', '#6c5ce7', '#6c5ce7', '#6c5ce7', '#f44336'),
              sizemode = 'diameter',
              opacity = 0.9,
              line = list(width = 1, color = 'white')
            ),
            line = list(color = '#6c5ce7', width = 3),
            text = ~hover_text,
            hovertemplate = "%{text}<extra></extra>"
    ) %>%
      layout(
        mapbox = list(
          style = 'open-street-map',
          center = list(lon = -0.1278, lat = 51.5074),
          zoom = 13
        ),
        showlegend = FALSE,
        margin = list(l = 0, r = 0, t = 0, b = 0),
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = 'rgba(0,0,0,0)'
      ) %>%
      config(displayModeBar = FALSE)
  })
}

shinyApp(ui = ui, server = server)