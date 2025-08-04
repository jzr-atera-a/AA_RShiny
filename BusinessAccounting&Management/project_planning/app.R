# Load required libraries
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(dplyr)
library(reshape2)

# Enhanced CSS for better visual appeal
css <- "
  .main-header .navbar { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    border: none !important; 
    box-shadow: 0 2px 10px rgba(0,0,0,0.1) !important;
  }
  .main-header .navbar-brand { 
    color: white !important; 
    font-weight: 700 !important; 
    font-size: 18px !important;
  }
  .main-sidebar { 
    background: linear-gradient(180deg, #2c3e50 0%, #34495e 100%) !important; 
  }
  .sidebar-menu > li > a { 
    color: #ecf0f1 !important; 
    border-left: 3px solid transparent; 
    transition: all 0.3s ease !important;
    font-weight: 500 !important;
  }
  .sidebar-menu > li.active > a { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    border-left: 3px solid #f39c12 !important; 
    color: white !important; 
    box-shadow: inset 0 0 10px rgba(0,0,0,0.2) !important;
  }
  .sidebar-menu > li:hover > a { 
    background-color: #3e5771 !important; 
    color: white !important; 
  }
  .content-wrapper { 
    background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%) !important; 
  }
  .box { 
    border: none !important; 
    border-radius: 12px !important; 
    box-shadow: 0 4px 20px rgba(0,0,0,0.08) !important;
    background: white !important;
  }
  .box-header { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    color: white !important;
    border-radius: 12px 12px 0 0 !important; 
    font-weight: 600 !important;
  }
  .data-source-box { 
    background: linear-gradient(135deg, #ffffff 0%, #f8f9ff 100%);
    border: none;
    border-left: 5px solid #667eea; 
    padding: 25px; 
    margin-bottom: 25px; 
    border-radius: 12px; 
    box-shadow: 0 4px 15px rgba(102, 126, 234, 0.1);
  }
  .reference-box {
    background: linear-gradient(135deg, #f8f9ff 0%, #ffffff 100%);
    border: 1px solid #e3e8ff;
    border-left: 5px solid #4f46e5;
    padding: 20px;
    margin-top: 25px;
    border-radius: 12px;
    box-shadow: 0 2px 10px rgba(79, 70, 229, 0.1);
  }
  .small-box { 
    border-radius: 12px !important; 
    box-shadow: 0 4px 15px rgba(0,0,0,0.1) !important;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
  }
  .small-box .icon { opacity: 0.8 !important; }
  .plotly { 
    border-radius: 12px !important; 
    box-shadow: 0 2px 10px rgba(0,0,0,0.05) !important;
  }
  .dataTables_wrapper { 
    background: white; 
    border-radius: 12px; 
    padding: 20px; 
    box-shadow: 0 2px 10px rgba(0,0,0,0.05);
  }
  .btn-primary { 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important; 
    border: none !important; 
    border-radius: 8px !important;
    font-weight: 600 !important;
  }
  h4 { color: #2c3e50; font-weight: 600; }
  .reference-box h4 { color: #4f46e5; }
  .gantt-legend {
    background: white;
    padding: 15px;
    border-radius: 8px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    margin-bottom: 20px;
  }
  .legend-item {
    display: inline-block;
    margin-right: 20px;
    margin-bottom: 5px;
  }
  .legend-color {
    width: 20px;
    height: 15px;
    display: inline-block;
    margin-right: 5px;
    vertical-align: middle;
    border-radius: 3px;
  }
"

# Project data matching the Gantt chart
project_data <- data.frame(
  ID = c("1", "1.1", "1.2", "1.3", "1.4", 
         "2", "2.1", "2.2", "2.3",
         "3", "3.1", "3.2", "3.3",
         "4", "4.1", "4.2", "4.3", "4.4", "4.5", "4.6", "4.7",
         "5", "5.1", "5.2", "5.3", "5.4", "5.5", "5.6", "5.7",
         "6", "6.1", "6.2", "6.3", "6.4", "6.5", "6.6", "6.7", "6.8",
         "7", "7.1", "7.2"),
  
  Task = c("Initial Tools and Management Setup",
           "KOM - Zenzic and MSP", "Software Tools Selection and basic testing", 
           "Hardware Tools Selection and basic testing", "Meeting AI advisors on project setup",
           "Route 10 Deliveres",
           "Proof of concept algorithm and visual output for indicative large-scale automated assessment (eg regional)",
           "Proof of concept algorithm with manual assistance and numerical/agentic output for indicative small-scale automated assessment (eg local)",
           "Report Including - Background Methodology and Conclusions",
           "Front End Application",
           "Exploratory Data Analysis", "Develop visualisation and users interfaces", "Rendering of POC Visualisations at interface",
           "Project Management and Setup",
           "Scope and Goal Setting", "Quarterly Objectives Review & Planning", "Session with advisors & stakeholders",
           "Web Tools Setup & Integration Environment", "Training & Technical Events", "QRM 1 with Monitoring Officer", "Hardware Setup",
           "Data Integration and Architecture",
           "CAM Operations Data Enablement", "End to End Data Architecture Design", "Validate EV CAM performance data",
           "Digital Data Model Definition", "Data Integration with External Sources", "AI Data Enrichment & Integration of Data Sets",
           "Visualisation of Route Navigation Data",
           "CCAV Integration and Testing",
           "Atera A. CAM Data API Connectivity", "Design for CAM 5G Teleoperation in Kia Niro EV", "Prepare Data for AI Network Models",
           "Design Machine Learning Path Planning", "Train Models for Remote control Driving KPIs", "Validate AI Models",
           "NVidia Xavier module deployment", "Automated Data access via API",
           "Final Delivery",
           "Full implementation of platform", "Project Reporting and Presentation"),
  
  Owner = c("", "PM/Lead", "PM/Lead", "PM/Lead", "PM/Lead",
            "", "Collaborators - Route 10", "Collaborators - Route 10", "Collaborators - Route 10",
            "", "Lead & Application Developer", "Application Developer", "Application Developer",
            "", "PM/Lead", "PM/Lead", "Whole Team", "Lead & Application Developer", "Whole Team", "PM/Lead", "Lead & Application Developer",
            "", "Lead & Application Developer", "Lead & Application Developer", "Collaborators - Route 10",
            "AI Specialist", "Application and Data Dev", "Lead & Application Developer", "AI Specialist",
            "", "Lead & Application Developer", "Collaborators - Route 10", "Lead & Application Developer",
            "AI Specialist", "PM/Lead & AI Specialist", "Lead & AI Specialist", "Contractor", "Application and Data Dev",
            "", "Whole Team", "Whole Team"),
  
  # Status values: 0 = not started, 1 = work left to do/in progress, 2 = complete, 3 = additional effort
  Apr = c(0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
  May = c(0, 2, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 1, 1, 1, 1, 1, 0, 2, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
  Jun = c(0, 2, 2, 2, 2, 0, 1, 1, 0, 0, 1, 0, 0, 0, 2, 2, 1, 1, 1, 2, 2, 0, 2, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
  Jul = c(0, 2, 2, 2, 2, 0, 2, 2, 1, 0, 2, 1, 0, 0, 2, 2, 2, 3, 3, 2, 2, 0, 2, 2, 2, 2, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
  Aug = c(0, 2, 2, 2, 2, 0, 2, 2, 2, 0, 2, 2, 1, 0, 2, 2, 2, 3, 3, 2, 2, 0, 2, 2, 2, 2, 2, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0),
  Sep = c(0, 2, 2, 2, 2, 0, 2, 2, 2, 0, 2, 2, 2, 0, 2, 2, 2, 3, 3, 3, 3, 0, 2, 2, 2, 2, 2, 2, 0, 0, 2, 2, 2, 1, 0, 0, 0, 0, 0, 0, 0),
  Oct = c(0, 2, 2, 2, 2, 0, 2, 2, 2, 0, 2, 2, 2, 0, 2, 3, 3, 3, 3, 3, 3, 0, 2, 2, 2, 3, 3, 3, 0, 0, 2, 2, 2, 2, 1, 1, 0, 1, 0, 0, 0),
  Nov = c(0, 2, 2, 2, 2, 0, 2, 2, 2, 0, 2, 2, 2, 0, 2, 3, 3, 3, 3, 3, 3, 0, 2, 2, 2, 3, 3, 3, 0, 0, 2, 2, 2, 2, 2, 2, 1, 2, 0, 1, 0),
  Dec = c(0, 2, 2, 2, 2, 0, 2, 2, 2, 0, 2, 2, 2, 0, 2, 3, 3, 3, 3, 3, 3, 0, 2, 2, 2, 3, 3, 3, 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 0, 2, 1),
  Jan = c(0, 2, 2, 2, 2, 0, 2, 2, 2, 0, 2, 2, 2, 0, 2, 3, 3, 3, 3, 3, 3, 0, 2, 2, 2, 3, 3, 3, 0, 0, 2, 2, 2, 2, 3, 3, 3, 3, 0, 2, 2),
  Feb = c(0, 2, 2, 2, 2, 0, 2, 2, 2, 0, 2, 2, 2, 0, 2, 3, 3, 3, 3, 3, 3, 0, 2, 2, 2, 3, 3, 3, 0, 0, 2, 2, 2, 2, 3, 3, 3, 3, 0, 2, 2),
  Mar = c(0, 2, 2, 2, 2, 0, 2, 2, 2, 0, 2, 2, 2, 0, 2, 3, 3, 3, 3, 3, 3, 0, 2, 2, 2, 3, 3, 3, 0, 0, 2, 2, 2, 2, 3, 3, 3, 3, 0, 2, 2),
  stringsAsFactors = FALSE
)

# Color mapping based on the legend
status_colors <- c(
  "0" = "#E8E8E8",  # Light gray - not started
  "1" = "#5DADE2",  # Light blue - work left to do/in progress  
  "2" = "#2E86AB",  # Dark blue - work effort put in, complete
  "3" = "#A8E6CF"   # Light green - additional effort added to schedule
)

status_labels <- c(
  "0" = "Not Started",
  "1" = "Work left to do / in progress",
  "2" = "Work effort put in, complete", 
  "3" = "Additional effort added to schedule"
)

# UI
ui <- dashboardPage(
  dashboardHeader(title = "Atera Analytics - Project Management Dashboard"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Gantt Chart", tabName = "gantt", icon = icon("chart-gantt")),
      menuItem("Task Overview", tabName = "overview", icon = icon("tasks")),
      menuItem("Team Workload", tabName = "workload", icon = icon("users")),
      menuItem("Progress Analytics", tabName = "analytics", icon = icon("chart-bar"))
    )
  ),
  
  dashboardBody(
    tags$head(tags$style(HTML(css))),
    
    tabItems(
      # Gantt Chart Tab
      tabItem(tabName = "gantt",
              fluidRow(
                box(
                  title = "Atera Analytics - Optimising Technology Feasibility for Autonomous and Remotely Controlled Vehicles",
                  status = "primary", solidHeader = TRUE, width = 12,
                  
                  # Legend
                  div(class = "gantt-legend",
                      h4("Progress Legend:"),
                      div(class = "legend-item",
                          span(class = "legend-color", style = paste0("background-color: ", status_colors["0"])),
                          span("Not Started")
                      ),
                      div(class = "legend-item",
                          span(class = "legend-color", style = paste0("background-color: ", status_colors["1"])),
                          span("Work left to do / in progress")
                      ),
                      div(class = "legend-item",
                          span(class = "legend-color", style = paste0("background-color: ", status_colors["2"])),
                          span("Work effort put in, complete")
                      ),
                      div(class = "legend-item",
                          span(class = "legend-color", style = paste0("background-color: ", status_colors["3"])),
                          span("Additional effort added to schedule")
                      )
                  ),
                  
                  br(),
                  
                  # Controls
                  fluidRow(
                    column(3,
                           selectInput("edit_task", "Select Task to Edit:",
                                       choices = setNames(1:nrow(project_data), paste(project_data$ID, "-", project_data$Task)),
                                       selected = 1)
                    ),
                    column(3,
                           selectInput("edit_month", "Select Month:",
                                       choices = c("Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar"),
                                       selected = "Apr")
                    ),
                    column(3,
                           selectInput("edit_status", "New Status:",
                                       choices = setNames(names(status_labels), status_labels),
                                       selected = "0")
                    ),
                    column(3,
                           br(),
                           actionButton("update_status", "Update Status", class = "btn-primary")
                    )
                  ),
                  
                  br(),
                  
                  # Gantt Chart
                  DT::dataTableOutput("gantt_table")
                )
              )
      ),
      
      # Task Overview Tab
      tabItem(tabName = "overview",
              fluidRow(
                # Summary boxes
                valueBoxOutput("total_tasks"),
                valueBoxOutput("completed_tasks"),
                valueBoxOutput("in_progress_tasks")
              ),
              
              fluidRow(
                box(
                  title = "Task Details", status = "primary", solidHeader = TRUE, width = 12,
                  DT::dataTableOutput("task_details")
                )
              )
      ),
      
      # Team Workload Tab
      tabItem(tabName = "workload",
              fluidRow(
                box(
                  title = "Team Workload Distribution", status = "primary", solidHeader = TRUE, width = 12,
                  plotlyOutput("workload_chart", height = "500px")
                )
              ),
              
              fluidRow(
                box(
                  title = "Team Member Task Count", status = "primary", solidHeader = TRUE, width = 12,
                  DT::dataTableOutput("team_summary")
                )
              )
      ),
      
      # Progress Analytics Tab
      tabItem(tabName = "analytics",
              fluidRow(
                box(
                  title = "Monthly Progress Overview", status = "primary", solidHeader = TRUE, width = 12,
                  plotlyOutput("progress_chart", height = "400px")
                )
              ),
              
              fluidRow(
                box(
                  title = "Project Phase Progress", status = "primary", solidHeader = TRUE, width = 6,
                  plotlyOutput("phase_progress", height = "400px")
                ),
                box(
                  title = "Completion Timeline", status = "primary", solidHeader = TRUE, width = 6,
                  plotlyOutput("completion_timeline", height = "400px")
                )
              )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Reactive values to store updated project data
  project_reactive <- reactiveVal(project_data)
  
  # Update status when button is clicked
  observeEvent(input$update_status, {
    current_data <- project_reactive()
    task_row <- as.numeric(input$edit_task)
    month_col <- input$edit_month
    new_status <- as.numeric(input$edit_status)
    
    current_data[task_row, month_col] <- new_status
    project_reactive(current_data)
    
    showNotification("Task status updated!", type = "success")
  })
  
  # Gantt Chart Table
  output$gantt_table <- DT::renderDataTable({
    data <- project_reactive()
    
    # Create display data with colored cells
    display_data <- data[, c("ID", "Task", "Owner", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar")]
    
    # Format month columns with colors
    month_cols <- c("Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar")
    
    DT::datatable(display_data,
                  options = list(
                    scrollX = TRUE,
                    pageLength = 50,
                    dom = 't',
                    columnDefs = list(
                      list(targets = which(names(display_data) %in% month_cols) - 1, 
                           render = JS(
                             "function(data, type, row, meta) {",
                             "  if(type === 'display') {",
                             "    var colors = {'0': '#E8E8E8', '1': '#5DADE2', '2': '#2E86AB', '3': '#A8E6CF'};",
                             "    var color = colors[data] || '#FFFFFF';",
                             "    return '<div style=\"background-color: ' + color + '; padding: 8px; text-align: center; border-radius: 4px;\">' + (data == '0' ? '' : '') + '</div>';",
                             "  }",
                             "  return data;",
                             "}"
                           )
                      )
                    )
                  ),
                  rownames = FALSE,
                  escape = FALSE
    ) %>%
      DT::formatStyle(month_cols, backgroundColor = "white")
  })
  
  # Summary value boxes
  output$total_tasks <- renderValueBox({
    data <- project_reactive()
    # Count only tasks with actual content (not section headers)
    task_count <- sum(data$Owner != "")
    
    valueBox(
      value = task_count,
      subtitle = "Total Tasks",
      icon = icon("tasks"),
      color = "blue"
    )
  })
  
  output$completed_tasks <- renderValueBox({
    data <- project_reactive()
    # Count completed tasks (status 2 in at least one month)
    month_cols <- c("Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar")
    completed <- sum(apply(data[data$Owner != "", month_cols], 1, function(x) any(x == 2)))
    
    valueBox(
      value = completed,
      subtitle = "Completed Tasks",
      icon = icon("check-circle"),
      color = "green"
    )
  })
  
  output$in_progress_tasks <- renderValueBox({
    data <- project_reactive()
    month_cols <- c("Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar")
    in_progress <- sum(apply(data[data$Owner != "", month_cols], 1, function(x) any(x == 1)))
    
    valueBox(
      value = in_progress,
      subtitle = "In Progress",
      icon = icon("clock"),
      color = "yellow"
    )
  })
  
  # Task details table
  output$task_details <- DT::renderDataTable({
    data <- project_reactive()
    # Filter out section headers
    task_data <- data[data$Owner != "", c("ID", "Task", "Owner")]
    
    DT::datatable(task_data,
                  options = list(pageLength = 15, scrollX = TRUE),
                  rownames = FALSE
    )
  })
  
  # Team workload chart
  output$workload_chart <- renderPlotly({
    data <- project_reactive()
    
    # Count tasks per owner
    workload <- data %>%
      filter(Owner != "") %>%
      count(Owner, sort = TRUE)
    
    p <- ggplot(workload, aes(x = reorder(Owner, n), y = n)) +
      geom_col(fill = "#667eea") +
      coord_flip() +
      labs(title = "Tasks per Team Member", x = "Team Member", y = "Number of Tasks") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Team summary table
  output$team_summary <- DT::renderDataTable({
    data <- project_reactive()
    
    team_summary <- data %>%
      filter(Owner != "") %>%
      count(Owner, sort = TRUE) %>%
      rename("Team Member" = Owner, "Task Count" = n)
    
    DT::datatable(team_summary,
                  options = list(pageLength = 10),
                  rownames = FALSE
    )
  })
  
  # Monthly progress chart
  output$progress_chart <- renderPlotly({
    data <- project_reactive()
    month_cols <- c("Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar")
    
    # Calculate progress for each month
    progress_data <- data.frame(
      Month = month_cols,
      Not_Started = numeric(12),
      In_Progress = numeric(12),
      Complete = numeric(12),
      Additional = numeric(12)
    )
    
    for(i in 1:12) {
      month_data <- data[data$Owner != "", month_cols[i]]
      progress_data$Not_Started[i] <- sum(month_data == 0)
      progress_data$In_Progress[i] <- sum(month_data == 1)
      progress_data$Complete[i] <- sum(month_data == 2)
      progress_data$Additional[i] <- sum(month_data == 3)
    }
    
    # Reshape for plotting
    progress_long <- reshape2::melt(progress_data, id.vars = "Month", variable.name = "Status", value.name = "Count")
    progress_long$Month <- factor(progress_long$Month, levels = month_cols)
    
    p <- ggplot(progress_long, aes(x = Month, y = Count, fill = Status)) +
      geom_col(position = "stack") +
      scale_fill_manual(values = c("Not_Started" = "#E8E8E8", "In_Progress" = "#5DADE2", 
                                   "Complete" = "#2E86AB", "Additional" = "#A8E6CF")) +
      labs(title = "Task Status by Month", x = "Month", y = "Number of Tasks") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p)
  })
  
  # Phase progress chart
  output$phase_progress <- renderPlotly({
    data <- project_reactive()
    
    # Define phases based on ID
    phases <- c("1" = "Initial Setup", "2" = "Route 10 Deliverables", "3" = "Front End App", 
                "4" = "Project Management", "5" = "Data Integration", "6" = "CCAV Integration", "7" = "Final Delivery")
    
    # Calculate phase completion
    phase_data <- data.frame(
      Phase = character(0),
      Completed = numeric(0),
      Total = numeric(0)
    )
    
    for(phase_id in names(phases)) {
      phase_tasks <- data[grepl(paste0("^", phase_id, "\\."), data$ID) & data$Owner != "", ]
      if(nrow(phase_tasks) > 0) {
        month_cols <- c("Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar")
        completed <- sum(apply(phase_tasks[, month_cols], 1, function(x) any(x == 2)))
        total <- nrow(phase_tasks)
        
        phase_data <- rbind(phase_data, data.frame(
          Phase = phases[phase_id],
          Completed = completed,
          Total = total,
          Percentage = round(completed/total * 100, 1)
        ))
      }
    }
    
    p <- ggplot(phase_data, aes(x = reorder(Phase, Percentage), y = Percentage)) +
      geom_col(fill = "#764ba2") +
      coord_flip() +
      labs(title = "Phase Completion Percentage", x = "Phase", y = "Completion %") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Completion timeline
  output$completion_timeline <- renderPlotly({
    data <- project_reactive()
    month_cols <- c("Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar")
    
    # Filter to only tasks with owners (exclude section headers)
    task_data <- data[data$Owner != "", ]
    
    if(nrow(task_data) == 0) {
      # Return empty plot if no data
      p <- ggplot() + 
        geom_blank() + 
        labs(title = "No task data available") +
        theme_minimal()
      return(ggplotly(p))
    }
    
    # Calculate cumulative completions
    cumulative_data <- data.frame(
      Month = month_cols,
      Cumulative_Complete = numeric(12)
    )
    
    total_completed <- 0
    for(i in 1:12) {
      month_data <- task_data[, month_cols[i], drop = FALSE]
      
      if(i == 1) {
        # For first month, count all tasks with status 2
        newly_completed <- sum(month_data == 2, na.rm = TRUE)
      } else {
        # For subsequent months, count tasks that became completed (status 2) 
        # and weren't completed in previous months
        prev_months <- task_data[, month_cols[1:(i-1)], drop = FALSE]
        current_month <- task_data[, month_cols[i], drop = FALSE]
        
        # Tasks that are complete now but weren't complete before
        was_not_complete <- apply(prev_months, 1, function(x) all(x != 2, na.rm = TRUE))
        is_complete_now <- current_month == 2
        
        newly_completed <- sum(was_not_complete & is_complete_now, na.rm = TRUE)
      }
      
      total_completed <- total_completed + newly_completed
      cumulative_data$Cumulative_Complete[i] <- total_completed
    }
    
    cumulative_data$Month <- factor(cumulative_data$Month, levels = month_cols)
    
    p <- ggplot(cumulative_data, aes(x = Month, y = Cumulative_Complete, group = 1)) +
      geom_line(color = "#667eea", size = 2) +
      geom_point(color = "#764ba2", size = 3) +
      labs(title = "Cumulative Task Completions", x = "Month", y = "Tasks Completed") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p)
  })
}

# Run the application
shinyApp(ui = ui, server = server)