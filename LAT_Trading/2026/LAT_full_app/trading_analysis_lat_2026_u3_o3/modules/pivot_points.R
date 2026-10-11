# modules/pivot_points.R

pivot_points_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "About Pivot Points", status = "primary", solidHeader = TRUE, width = 12,
        tags$p(HTML(paste0(
          "Pivot Points are calculated from the <em>previous</em> period's High, Low, and Close: ",
          "PP = (H + L + C) / 3. Resistance levels R1&ndash;R3 sit above the pivot and support levels ",
          "S1&ndash;S3 sit below it, giving a full map of likely intraday support/resistance for the next session."
        )), style = "font-size:12px; color:#444; line-height:1.6;")
      )
    ),
    fluidRow(
      box(
        title = "Pivot Levels (most recent completed session)", status = "info", solidHeader = TRUE, width = 4,
        withSpinner(DT::dataTableOutput(ns("pivotPointsTable")))
      ),
      box(
        title = "Recent Price vs Pivot Levels", status = "primary", solidHeader = TRUE, width = 8,
        withSpinner(plotlyOutput(ns("pivotPointsChart"), height = "420px")),
        tags$p(paste0(
          "The last 30 sessions of closing price plotted against the pivot, resistance, and support levels ",
          "derived from the most recently completed session."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    )
  )
}

pivot_points_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    # NOTE: reactive() only re-computes when one of ITS OWN reactive reads changes.
    # This must call state_trigger() itself (not just rely on the outputs that use it
    # doing so) or it will cache its first result forever and never refresh on a new
    # asset/resolution/refresh, even though the outputs below re-run correctly.
    pivot_levels <- reactive({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      data <- data %>% arrange(Date)
      req(nrow(data) >= 1)
      
      last_row <- tail(data, 1)
      H <- last_row$High; L <- last_row$Low; C <- last_row$Close
      
      PP <- (H + L + C) / 3
      R1 <- (2 * PP) - L
      S1 <- (2 * PP) - H
      R2 <- PP + (H - L)
      S2 <- PP - (H - L)
      R3 <- H + 2 * (PP - L)
      S3 <- L - 2 * (H - PP)
      
      data.frame(
        Level = c("R3", "R2", "R1", "PP", "S1", "S2", "S3"),
        Value = round(c(R3, R2, R1, PP, S1, S2, S3), 4)
      )
    })
    
    output$pivotPointsTable <- renderDT({
      lv <- pivot_levels()
      datatable(lv, options = list(dom = 't', paging = FALSE), rownames = FALSE) %>%
        formatStyle("Level",
                    backgroundColor = styleEqual(
                      c("R3", "R2", "R1", "PP", "S1", "S2", "S3"),
                      c("#fadbd8", "#fadbd8", "#fadbd8", "#d6eaf8", "#d5f5e3", "#d5f5e3", "#d5f5e3")
                    ))
    })
    
    output$pivotPointsChart <- renderPlotly({
      data_manager$state_trigger()
      data <- data_manager$get_data()
      req(data)
      data <- tail(data %>% arrange(Date), 30)
      lv <- pivot_levels()
      
      p <- plot_ly(data, x = ~Date, y = ~Close, type = "scatter", mode = "lines",
                   name = "Close", line = list(color = "#002C3C", width = 2))
      
      colors <- c(R3 = "#c0392b", R2 = "#e74c3c", R1 = "#e67e22", PP = "#2980b9",
                  S1 = "#27ae60", S2 = "#16a085", S3 = "#1abc9c")
      for (i in seq_len(nrow(lv))) {
        lvl <- lv$Level[i]; val <- lv$Value[i]
        p <- p %>% add_trace(x = data$Date, y = rep(val, nrow(data)), type = "scatter", mode = "lines",
                              name = lvl, line = list(color = colors[[lvl]], width = 1, dash = "dot"))
      }
      
      p %>% layout(title = paste("Recent Price vs Pivot Levels —", data_manager$current_asset),
                   xaxis = list(title = "Date"), yaxis = list(title = "Price"),
                   plot_bgcolor = "white", paper_bgcolor = "white")
    })
    
    session$onSessionEnded(function() {})
  })
}
