library(shiny)
library(plotly)
library(dplyr)

# Generate sample EV fleet data
set.seed(123)
daily_data <- data.frame(
  date = seq(as.Date("2025-05-01"), as.Date("2025-05-31"), by = "day"),
  vehicles_active = sample(45:65, 31, replace = TRUE),
  total_distance = sample(800:1500, 31, replace = TRUE),
  energy_consumed = sample(120:250, 31, replace = TRUE),
  charging_sessions = sample(25:45, 31, replace = TRUE)
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
        background: white;
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
        background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
        border-radius: 25px;
        padding: 8px;
        margin-bottom: 20px;
        box-shadow: 0 10px 30px rgba(0,0,0,0.3);
        backdrop-filter: blur(10px);
        overflow-x: auto;
        scrollbar-width: none;
        -ms-overflow-style: none;
      }
      
      .custom-tabs::-webkit-scrollbar {
        display: none;
      }
      
      .section-card {
        background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
        border-radius: 20px;
        box-shadow: 0 10px 30px rgba(0,0,0,0.3);
        margin-bottom: 20px;
        overflow: hidden;
        transition: transform 0.3s ease, box-shadow 0.3s ease;
      }
      
      .section-card:hover {
        transform: translateY(-5px);
        box-shadow: 0 15px 40px rgba(0,0,0,0.15);
      }
      
      .card-header {
        background: linear-gradient(135deg, #0ea5e9 0%, #0284c7 100%);
        color: white;
        padding: 20px;
        text-align: center;
        font-weight: 600;
        font-size: 1.2em;
      }
      
      .card-content {
        padding: 20px;
        color: white;
      }
      
      .stats-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
        gap: 15px;
        margin-bottom: 20px;
      }
      
      .stat-card {
        background: linear-gradient(135deg, #0ea5e9 0%, #0284c7 100%);
        color: white;
        padding: 20px;
        border-radius: 15px;
        text-align: center;
        box-shadow: 0 5px 15px rgba(14, 165, 233, 0.3);
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
        background: #1e293b;
        border-radius: 15px;
        padding: 20px;
        margin-top: 20px;
        text-align: center;
      }
      
      .chart-container h4 {
        color: white;
      }
      
      .simple-chart {
        display: flex;
        align-items: end;
        justify-content: space-between;
        height: 200px;
        margin: 20px 0;
        padding: 10px;
        background: #0f172a;
        border-radius: 10px;
        box-shadow: 0 2px 10px rgba(0,0,0,0.3);
      }
      
      .line-chart {
        height: 200px;
        margin: 20px 0;
        padding: 20px;
        background: #0f172a;
        border-radius: 10px;
        box-shadow: 0 2px 10px rgba(0,0,0,0.3);
        position: relative;
      }
      
      .chart-bar {
        background: linear-gradient(to top, #0ea5e9, #38bdf8);
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
        box-shadow: 0 5px 15px rgba(14, 165, 233, 0.4);
      }
      
      .bar-label {
        font-size: 10px;
        color: #cbd5e1;
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
        color: #cbd5e1;
        background: #1e293b;
        padding: 2px 6px;
        border-radius: 4px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.5);
        opacity: 0;
        transition: opacity 0.3s ease;
      }
      
      .chart-bar:hover .bar-value {
        opacity: 1;
      }
      
      .chart-legend {
        display: flex;
        justify-content: center;
        gap: 20px;
        margin-top: 15px;
        flex-wrap: wrap;
      }
      
      .legend-item {
        display: flex;
        align-items: center;
        gap: 8px;
        font-size: 12px;
        color: #666;
      }
      
      .legend-color {
        width: 16px;
        height: 3px;
        border-radius: 2px;
      }
      
      .legend-fuel { background: #ef4444; }
      .legend-maintenance { background: #f59e0b; }
      .legend-total { background: #059669; }
      
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
        background: conic-gradient(from 0deg, #0ea5e9 var(--progress), #374151 var(--progress));
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
        color: #cbd5e1;
        font-weight: 500;
      }
      
      .fleet-info {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
        gap: 15px;
        margin-top: 20px;
      }
      
      .fleet-stat {
        background: linear-gradient(135deg, #f1f5f9 0%, #e2e8f0 100%);
        padding: 18px;
        border-radius: 12px;
        text-align: center;
        border-left: 4px solid #0ea5e9;
        transition: transform 0.3s ease;
      }
      
      .fleet-stat:hover {
        transform: translateY(-2px);
        box-shadow: 0 5px 15px rgba(14, 165, 233, 0.2);
      }
      
      .fleet-stat-value {
        font-size: 1.6em;
        font-weight: bold;
        color: #0c4a6e;
        margin-bottom: 5px;
      }
      
      .fleet-stat-label {
        font-size: 0.85em;
        color: #075985;
        font-weight: 500;
      }
      
      .map-placeholder {
        height: 400px;
        background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 50%, #bae6fd 100%);
        border-radius: 15px;
        border: 2px dashed #0ea5e9;
        display: flex;
        align-items: center;
        justify-content: center;
        color: #0c4a6e;
        font-size: 1.1em;
        font-weight: 500;
        position: relative;
        overflow: hidden;
      }
      
      .map-placeholder::before {
        content: '';
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background-image: 
          radial-gradient(circle at 20% 30%, rgba(14, 165, 233, 0.1) 2px, transparent 2px),
          radial-gradient(circle at 60% 70%, rgba(14, 165, 233, 0.1) 1px, transparent 1px),
          radial-gradient(circle at 80% 20%, rgba(14, 165, 233, 0.1) 1.5px, transparent 1.5px);
        background-size: 40px 40px, 25px 25px, 35px 35px;
      }
      
      .monitoring-header {
        background: linear-gradient(135deg, #0ea5e9 0%, #0284c7 100%);
        color: white;
        padding: 15px 20px;
        border-radius: 12px;
        margin: 20px 0 15px 0;
        font-weight: 600;
        text-align: center;
        box-shadow: 0 5px 15px rgba(14, 165, 233, 0.3);
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
        color: #cbd5e1;
        cursor: pointer;
        transition: all 0.3s ease;
        margin: 0;
      }
      
      .custom-tabs label:hover {
        color: #0ea5e9;
        background: rgba(14, 165, 233, 0.1);
      }
      
      .custom-tabs input[type='radio']:checked + label {
        background: linear-gradient(135deg, #0ea5e9 0%, #38bdf8 100%);
        color: white;
        box-shadow: 0 5px 15px rgba(14, 165, 233, 0.4);
        transform: translateY(-1px);
      }
      
      .operations-grid {
        display: flex;
        flex-direction: column;
        gap: 20px;
      }
      
      .operations-card {
        background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
        border-radius: 15px;
        box-shadow: 0 8px 25px rgba(0,0,0,0.3);
        overflow: hidden;
        transition: transform 0.3s ease;
      }
      
      .operations-card:hover {
        transform: translateY(-3px);
        box-shadow: 0 12px 35px rgba(0,0,0,0.4);
      }
      
      .operations-header {
        background: linear-gradient(135deg, #0ea5e9 0%, #0284c7 100%);
        color: white;
        padding: 18px;
        font-weight: 600;
        font-size: 1.1em;
      }
      
      .operations-content {
        padding: 20px;
        color: white;
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
        
        .fleet-info {
          grid-template-columns: repeat(2, 1fr);
          gap: 10px;
        }
        
        .map-placeholder {
          height: 300px;
        }
      }
    "))
  ),
  
  div(class = "container-fluid",
      div(class = "custom-tabs",
          radioButtons("selected_tab", "",
                       choices = list("Dashboard" = "dashboard", "Fleet Optimisation" = "fleet", "Operational Improvements" = "operations"),
                       selected = "dashboard",
                       inline = TRUE
          )
      ),
      
      conditionalPanel(
        condition = "input.selected_tab == 'dashboard'",
        div(class = "section-card",
            div(class = "card-header", "Fleet Overview"),
            div(class = "card-content",
                div(class = "stats-grid",
                    div(class = "stat-card",
                        div(class = "stat-value", "52"),
                        div(class = "stat-label", "Active Vehicles")
                    ),
                    div(class = "stat-card",
                        div(class = "stat-value", "94%"),
                        div(class = "stat-label", "Fleet Utilization")
                    ),
                    div(class = "stat-card",
                        div(class = "stat-value", "1,247"),
                        div(class = "stat-label", "km Today")
                    ),
                    div(class = "stat-card",
                        div(class = "stat-value", "183"),
                        div(class = "stat-label", "kWh Consumed")
                    )
                )
            )
        ),
        
        div(class = "section-card",
            div(class = "card-header", "Weekly Performance"),
            div(class = "card-content",
                div(class = "weekly-circles",
                    div(class = "day-circle",
                        div(class = "circle-progress", style = "--progress: 88%", 
                            tags$span("88%")),
                        div(class = "day-label", "M")
                    ),
                    div(class = "day-circle",
                        div(class = "circle-progress", style = "--progress: 92%", 
                            tags$span("92%")),
                        div(class = "day-label", "T")
                    ),
                    div(class = "day-circle",
                        div(class = "circle-progress", style = "--progress: 85%", 
                            tags$span("85%")),
                        div(class = "day-label", "W")
                    ),
                    div(class = "day-circle",
                        div(class = "circle-progress", style = "--progress: 96%", 
                            tags$span("96%")),
                        div(class = "day-label", "T")
                    ),
                    div(class = "day-circle",
                        div(class = "circle-progress", style = "--progress: 91%", 
                            tags$span("91%")),
                        div(class = "day-label", "F")
                    ),
                    div(class = "day-circle",
                        div(class = "circle-progress", style = "--progress: 78%", 
                            tags$span("78%")),
                        div(class = "day-label", "S")
                    ),
                    div(class = "day-circle",
                        div(class = "circle-progress", style = "--progress: 82%", 
                            tags$span("82%")),
                        div(class = "day-label", "S")
                    )
                )
            )
        )
      ),
      
      conditionalPanel(
        condition = "input.selected_tab == 'fleet'",
        div(class = "section-card",
            div(class = "card-header", "Fleet Route Optimization"),
            div(class = "card-content",
                div(class = "map-placeholder",
                    div(style = "z-index: 2; position: relative;", 
                        "🗺️ Interactive Fleet Map",
                        tags$br(),
                        tags$small("Map integration placeholder")
                    )
                ),
                div(class = "monitoring-header", "RT Monitoring of Fleet"),
                div(class = "fleet-info",
                    div(class = "fleet-stat",
                        div(class = "fleet-stat-value", "47"),
                        div(class = "fleet-stat-label", "Vehicles Online")
                    ),
                    div(class = "fleet-stat",
                        div(class = "fleet-stat-value", "12.4"),
                        div(class = "fleet-stat-label", "Avg Speed (km/h)")
                    ),
                    div(class = "fleet-stat",
                        div(class = "fleet-stat-value", "8"),
                        div(class = "fleet-stat-label", "Charging")
                    ),
                    div(class = "fleet-stat",
                        div(class = "fleet-stat-value", "73%"),
                        div(class = "fleet-stat-label", "Avg Battery")
                    ),
                    div(class = "fleet-stat",
                        div(class = "fleet-stat-value", "2.3"),
                        div(class = "fleet-stat-label", "Route Efficiency")
                    ),
                    div(class = "fleet-stat",
                        div(class = "fleet-stat-value", "0"),
                        div(class = "fleet-stat-label", "Alerts")
                    )
                )
            )
        )
      ),
      
      conditionalPanel(
        condition = "input.selected_tab == 'operations'",
        div(class = "operations-grid",
            div(class = "operations-card",
                div(class = "operations-header", "Operations Optimization"),
                div(class = "operations-content",
                    div(class = "chart-container",
                        h4("Fleet Utilization Efficiency", style = "margin-bottom: 15px; color: white; font-size: 1.1em;"),
                        div(class = "simple-chart", id = "utilization-chart")
                    )
                )
            ),
            
            div(class = "operations-card",
                div(class = "operations-header", "Cost Reduction Analysis"),
                div(class = "operations-content",
                    div(class = "chart-container",
                        h4("Monthly Operating Costs (£)", style = "margin-bottom: 15px; color: white; font-size: 1.1em;"),
                        div(class = "line-chart", id = "costs-chart"),
                        div(class = "chart-legend",
                            div(class = "legend-item",
                                div(class = "legend-color legend-fuel"),
                                "Energy Costs"
                            ),
                            div(class = "legend-item",
                                div(class = "legend-color legend-maintenance"),
                                "Maintenance"
                            ),
                            div(class = "legend-item",
                                div(class = "legend-color legend-total"),
                                "Total Costs"
                            )
                        )
                    )
                )
            )
        )
      )
  ),
  
  tags$script(HTML("
    $(document).ready(function() {
      var utilizationData = [78, 82, 75, 88, 85, 89, 92, 87, 90, 86, 91, 88, 84, 89, 93];
      
      var costsData = [
        {month: 'Jan', fuelCost: 4500, maintenanceCost: 2200, totalCost: 6700},
        {month: 'Feb', fuelCost: 4200, maintenanceCost: 2100, totalCost: 6300},
        {month: 'Mar', fuelCost: 3900, maintenanceCost: 1950, totalCost: 5850},
        {month: 'Apr', fuelCost: 3700, maintenanceCost: 1800, totalCost: 5500},
        {month: 'May', fuelCost: 3500, maintenanceCost: 1700, totalCost: 5200},
        {month: 'Jun', fuelCost: 3400, maintenanceCost: 1650, totalCost: 5050}
      ];
      
      function createChart(containerId, data, isMonthly = false) {
        var container = $('#' + containerId);
        if (isMonthly) {
          createLineChart(container, data);
        } else {
          createBarChart(container, data);
        }
      }
      
      function createBarChart(container, data) {
        var maxValue = Math.max(...data);
        container.empty();
        
        data.forEach(function(item, index) {
          var height = (item / maxValue) * 180;
          var label = index + 1;
          
          var bar = $('<div class=\"chart-bar\"></div>');
          bar.css('height', height + 'px');
          bar.append('<div class=\"bar-value\">' + item + '%</div>');
          bar.append('<div class=\"bar-label\">' + label + '</div>');
          
          container.append(bar);
        });
      }
      
      function createLineChart(container, data) {
        container.empty();
        container.css('position', 'relative');
        
        var containerWidth = container.width() || 400;
        var containerHeight = 180;
        var padding = 30;
        var chartWidth = containerWidth - (padding * 2);
        var chartHeight = containerHeight - (padding * 2);
        
        var maxValue = Math.max(...data.map(d => Math.max(d.fuelCost, d.maintenanceCost, d.totalCost)));
        var minValue = Math.min(...data.map(d => Math.min(d.fuelCost, d.maintenanceCost, d.totalCost)));
        var range = maxValue - minValue;
        
        container.html('<div style=\"width: 100%; height: ' + containerHeight + 'px; background: #0f172a; border-radius: 8px; position: relative;\"></div>');
        var chartContainer = container.find('div').first();
        
        var fuelPoints = [];
        var maintenancePoints = [];
        var totalPoints = [];
        
        data.forEach(function(d, i) {
          var x = padding + (i / (data.length - 1)) * chartWidth;
          var fuelY = padding + (chartHeight - ((d.fuelCost - minValue) / range) * chartHeight);
          var maintenanceY = padding + (chartHeight - ((d.maintenanceCost - minValue) / range) * chartHeight);
          var totalY = padding + (chartHeight - ((d.totalCost - minValue) / range) * chartHeight);
          
          fuelPoints.push({x: x, y: fuelY, value: d.fuelCost, month: d.month});
          maintenancePoints.push({x: x, y: maintenanceY, value: d.maintenanceCost, month: d.month});
          totalPoints.push({x: x, y: totalY, value: d.totalCost, month: d.month});
        });
        
        for (var i = 0; i < data.length - 1; i++) {
          var fuelLine = createLine(fuelPoints[i], fuelPoints[i + 1], '#ef4444');
          chartContainer.append(fuelLine);
          
          var maintenanceLine = createLine(maintenancePoints[i], maintenancePoints[i + 1], '#f59e0b');
          chartContainer.append(maintenanceLine);
          
          var totalLine = createLine(totalPoints[i], totalPoints[i + 1], '#059669');
          chartContainer.append(totalLine);
        }
        
        fuelPoints.forEach(function(point) {
          var dot = $('<div style=\"position: absolute; width: 8px; height: 8px; background: white; border: 3px solid #ef4444; border-radius: 50%; cursor: pointer; transform: translate(-50%, -50%);\" title=\"Energy: £' + point.value.toLocaleString() + '\"></div>');
          dot.css({left: point.x + 'px', top: point.y + 'px'});
          chartContainer.append(dot);
        });
        
        maintenancePoints.forEach(function(point) {
          var dot = $('<div style=\"position: absolute; width: 8px; height: 8px; background: white; border: 3px solid #f59e0b; border-radius: 50%; cursor: pointer; transform: translate(-50%, -50%);\" title=\"Maintenance: £' + point.value.toLocaleString() + '\"></div>');
          dot.css({left: point.x + 'px', top: point.y + 'px'});
          chartContainer.append(dot);
        });
        
        totalPoints.forEach(function(point) {
          var dot = $('<div style=\"position: absolute; width: 8px; height: 8px; background: white; border: 3px solid #059669; border-radius: 50%; cursor: pointer; transform: translate(-50%, -50%);\" title=\"Total: £' + point.value.toLocaleString() + '\"></div>');
          dot.css({left: point.x + 'px', top: point.y + 'px'});
          chartContainer.append(dot);
        });
        
        data.forEach(function(d, i) {
          var x = padding + (i / (data.length - 1)) * chartWidth;
          var label = $('<div style=\"position: absolute; font-size: 12px; color: #cbd5e1; text-align: center; transform: translateX(-50%);\">' + d.month + '</div>');
          label.css({left: x + 'px', top: (containerHeight - 15) + 'px'});
          chartContainer.append(label);
        });
      }
      
      function createLine(point1, point2, color) {
        var dx = point2.x - point1.x;
        var dy = point2.y - point1.y;
        var length = Math.sqrt(dx * dx + dy * dy);
        var angle = Math.atan2(dy, dx) * 180 / Math.PI;
        
        return $('<div style=\"position: absolute; width: ' + length + 'px; height: 3px; background: ' + color + '; transform-origin: 0 50%; transform: rotate(' + angle + 'deg);\"></div>')
          .css({left: point1.x + 'px', top: point1.y + 'px'});
      }
      
      function initCharts() {
        var currentTab = $('input[name=\"selected_tab\"]:checked').val();
        if (currentTab === 'operations') {
          createChart('utilization-chart', utilizationData, false);
          createChart('costs-chart', costsData, true);
        }
      }
      
      $('input[name=\"selected_tab\"]').change(function() {
        setTimeout(initCharts, 100);
      });
      
      setTimeout(initCharts, 500);
    });
  "))
)

server <- function(input, output, session) {
  # Server logic can be added here for dynamic content
}

shinyApp(ui = ui, server = server)