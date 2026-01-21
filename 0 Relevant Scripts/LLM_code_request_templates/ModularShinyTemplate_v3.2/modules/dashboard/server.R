# modules/dashboard/server.R
# Dashboard Module Server

dashboard_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    # Value boxes
    output$box1 <- renderValueBox({
      valueBox(
        value = "3",
        subtitle = "Active Modules",
        icon = icon("cubes"),
        color = "aqua"
      )
    })
    
    output$box2 <- renderValueBox({
      valueBox(
        value = if (api_manager$authenticated) "Connected" else "Not Connected",
        subtitle = "API Status",
        icon = icon("plug"),
        color = if (api_manager$authenticated) "green" else "yellow"
      )
    })
    
    output$box3 <- renderValueBox({
      valueBox(
        value = "v3.0",
        subtitle = "Template Version",
        icon = icon("code"),
        color = "purple"
      )
    })
    
    output$box4 <- renderValueBox({
      valueBox(
        value = format(Sys.Date(), "%b %d"),
        subtitle = "Current Date",
        icon = icon("calendar"),
        color = "blue"
      )
    })
    
    # Sample plot
    output$sample_plot <- renderPlot({
      # Generate sample data
      data <- data.frame(
        x = 1:10,
        y = rnorm(10, mean = 50, sd = 10)
      )
      
      ggplot2::ggplot(data, ggplot2::aes(x = x, y = y)) +
        ggplot2::geom_line(color = "#008A82", size = 1.5) +
        ggplot2::geom_point(color = "#00A39A", size = 3) +
        ggplot2::theme_minimal() +
        ggplot2::labs(title = "Sample Data", x = "Index", y = "Value") +
        ggplot2::theme(
          plot.title = ggplot2::element_text(color = "#002C3C", face = "bold"),
          panel.grid.major = ggplot2::element_line(color = "#e0e0e0")
        )
    })
    
    # System status
    output$system_status <- renderUI({
      tags$div(
        tags$p(tags$strong("R Version:"), " ", R.version$version.string),
        tags$p(tags$strong("Shiny Version:"), " ", as.character(packageVersion("shiny"))),
        tags$p(tags$strong("Platform:"), " ", R.version$platform),
        tags$hr(),
        tags$p(tags$strong("API Manager:"), " ", 
               if (api_manager$authenticated) {
                 tags$span(class = "text-success", "✓ Ready")
               } else {
                 tags$span(class = "text-warning", "⚠ Not configured")
               })
      )
    })
  })
}
