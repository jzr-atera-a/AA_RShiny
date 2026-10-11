# modules/yield_curves.R

yield_curves_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        width = 12, solidHeader = FALSE, status = "warning",
        div(style = "display:flex; align-items:flex-start; gap:14px;",
          icon("circle-info", style = "font-size:22px; color:#e67e22; margin-top:2px; flex-shrink:0;"),
          div(
            tags$strong("About this tab:", style = "color:#7d4a00; font-size:14px;"),
            tags$p(HTML(paste0(
              "A <strong>yield curve</strong> plots interest rates across maturities at a fixed point in ",
              "time. <strong>Normal</strong> (upward-sloping) signals expected long-term economic growth; ",
              "<strong>Inverted</strong> (downward-sloping) is the rarest shape and historically a recession ",
              "predictor; <strong>Flat</strong> often marks a transition between the two. Defaults below ",
              "reproduce the UK Gilt / US Treasury rates as of 2 December 2013 from the FX reference manual — ",
              "edit any field to explore other curve shapes."
            )), style = "font-size:13px; color:#5a3500; margin:4px 0 0 0; line-height:1.6;")
          )
        )
      )
    ),
    fluidRow(
      box(
        title = "UK Gilt Yields (%)", status = "primary", solidHeader = TRUE, width = 3,
        numericInput(ns("giltY3m"),  "3 Month:", value = NA, step = 0.01),
        numericInput(ns("giltY6m"),  "6 Month:", value = 0.37, step = 0.01),
        numericInput(ns("giltY1y"),  "1 Year:",  value = 0.42, step = 0.01),
        numericInput(ns("giltY2y"),  "2 Year:",  value = 0.43, step = 0.01),
        numericInput(ns("giltY5y"),  "5 Year:",  value = 1.06, step = 0.01),
        numericInput(ns("giltY10y"), "10 Year:", value = 2.19, step = 0.01),
        numericInput(ns("giltY30y"), "30 Year:", value = 3.36, step = 0.01)
      ),
      box(
        title = "US Treasury Yields (%)", status = "primary", solidHeader = TRUE, width = 3,
        numericInput(ns("usY3m"),  "3 Month:", value = 0.08, step = 0.01),
        numericInput(ns("usY6m"),  "6 Month:", value = 0.11, step = 0.01),
        numericInput(ns("usY1y"),  "1 Year:",  value = NA, step = 0.01),
        numericInput(ns("usY2y"),  "2 Year:",  value = 0.29, step = 0.01),
        numericInput(ns("usY5y"),  "5 Year:",  value = 0.86, step = 0.01),
        numericInput(ns("usY10y"), "10 Year:", value = 2.00, step = 0.01),
        numericInput(ns("usY30y"), "30 Year:", value = 3.15, step = 0.01)
      ),
      box(
        title = "Yield Curve", status = "primary", solidHeader = TRUE, width = 6,
        withSpinner(plotlyOutput(ns("yieldCurveChart"), height = "360px")),
        uiOutput(ns("yieldCurveClassification"))
      )
    )
  )
}

yield_curves_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    yield_curve_data <- reactive({
      maturities <- c("3m", "6m", "1y", "2y", "5y", "10y", "30y")
      maturity_labels <- factor(maturities, levels = maturities)
      
      gilt <- c(input$giltY3m, input$giltY6m, input$giltY1y, input$giltY2y,
                input$giltY5y, input$giltY10y, input$giltY30y)
      us   <- c(input$usY3m, input$usY6m, input$usY1y, input$usY2y,
                input$usY5y, input$usY10y, input$usY30y)
      
      list(maturities = maturity_labels, gilt = gilt, us = us)
    })
    
    # Classifies a yield curve as Normal/Inverted/Flat by comparing the shortest and
    # longest available maturities. Thresholds (>0.5pp = Normal, <-0.1pp = Inverted,
    # otherwise Flat) are an illustrative implementation choice — the reference manual
    # describes the three shapes qualitatively but doesn't specify exact numeric cutoffs.
    classify_curve <- function(yields, maturities) {
      valid <- !is.na(yields)
      if (sum(valid) < 2) return(list(label = "Insufficient data", color = "#7f8c8d"))
      yv <- yields[valid]
      short <- yv[1]; long <- yv[length(yv)]
      spread <- long - short
      if (spread > 0.5) list(label = "Normal (upward-sloping)", color = "#27ae60")
      else if (spread < -0.1) list(label = "Inverted (downward-sloping)", color = "#e74c3c")
      else list(label = "Flat", color = "#e67e22")
    }
    
    output$yieldCurveChart <- renderPlotly({
      yc <- yield_curve_data()
      
      plot_ly() %>%
        add_trace(x = yc$maturities, y = yc$gilt, type = "scatter", mode = "lines+markers",
                  name = "UK Gilt", line = list(color = "#002C3C", width = 3), connectgaps = TRUE) %>%
        add_trace(x = yc$maturities, y = yc$us, type = "scatter", mode = "lines+markers",
                  name = "US Treasury", line = list(color = "#008A82", width = 3), connectgaps = TRUE) %>%
        layout(
          title = "Yield Curve",
          xaxis = list(title = "Maturity", type = "category"),
          yaxis = list(title = "Yield (%)"),
          plot_bgcolor = "white", paper_bgcolor = "white"
        )
    })
    
    output$yieldCurveClassification <- renderUI({
      yc <- yield_curve_data()
      gilt_class <- classify_curve(yc$gilt, yc$maturities)
      us_class   <- classify_curve(yc$us, yc$maturities)
      
      tagList(
        tags$hr(),
        fluidRow(
          column(6, div(style = paste0("text-align:center; padding:10px; border-radius:8px; background:", gilt_class$color, "22;"),
                        tags$div("UK Gilt Shape", style = "font-size:11px; color:#666;"),
                        tags$strong(gilt_class$label, style = paste0("color:", gilt_class$color, "; font-size:13px;")))),
          column(6, div(style = paste0("text-align:center; padding:10px; border-radius:8px; background:", us_class$color, "22;"),
                        tags$div("US Treasury Shape", style = "font-size:11px; color:#666;"),
                        tags$strong(us_class$label, style = paste0("color:", us_class$color, "; font-size:13px;"))))
        ),
        tags$p("Classification compares the shortest vs longest available maturity yields; thresholds are illustrative, not a formal rule from the reference manual.",
               style = "font-size:10.5px; color:#999; font-style:italic; margin-top:8px;")
      )
    })
    
    session$onSessionEnded(function() {})
  })
}
