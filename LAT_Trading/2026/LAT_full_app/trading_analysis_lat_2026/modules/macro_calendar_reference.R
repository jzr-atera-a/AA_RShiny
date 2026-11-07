# modules/macro_calendar_reference.R

macro_calendar_reference_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        width = 12, solidHeader = FALSE, status = "warning",
        div(style = "display:flex; align-items:flex-start; gap:14px;",
          icon("circle-info", style = "font-size:22px; color:#e67e22; margin-top:2px; flex-shrink:0;"),
          div(
            tags$strong("About this table:", style = "color:#7d4a00; font-size:14px;"),
            tags$p(paste0(
              "Reference data reproduced from the US Macro Crib Sheet, covering the highest-impact scheduled ",
              "US economic releases. Expected outcomes are general historical tendencies, subject to prevailing ",
              "financial conditions and monetary policy stance — not a guaranteed reaction."
            ), style = "font-size:13px; color:#5a3500; margin:4px 0 0 0; line-height:1.6;")
          )
        )
      )
    ),
    fluidRow(
      box(
        title = "Reaction Simulator", status = "primary", solidHeader = TRUE, width = 4,
        selectInput(ns("macroIndicator"), "Select Release:", choices = NULL),
        radioButtons(ns("macroDirection"), "Scenario:",
                     choices = c("Actual beats Forecast"  = "beat",
                                 "Actual misses Forecast" = "miss"),
                     selected = "beat"),
        uiOutput(ns("macroReactionResult"))
      ),
      box(
        title = "Full Calendar Reference", status = "info", solidHeader = TRUE, width = 8,
        withSpinner(DT::dataTableOutput(ns("macroCalendarTable")))
      )
    )
  )
}

macro_calendar_reference_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    macro_calendar_data <- data.frame(
      Release = c("ISM Manufacturing PMI", "ISM Services PMI", "ADP Employment Change",
                  "Average Hourly Earnings m/m", "Non-Farm Payrolls", "Unemployment Rate",
                  "PPI", "CPI", "Core CPI", "Core PCE Price Index", "Core Retail Sales m/m",
                  "Retail Sales m/m", "FOMC Economic Projections", "FOMC Statement",
                  "Federal Funds Rate", "FOMC Press Conference", "Advance GDP q/q"),
      Frequency = c("Monthly (1st/2nd business day)", "Monthly (3rd business day)", "Monthly (1st Wednesday)",
                    "Monthly (1st Friday)", "Monthly (1st Friday)", "Monthly (1st business day)",
                    "Monthly (mid-month)", "Monthly (mid-month)", "Monthly (mid-month)", "Monthly (end of month)",
                    "Monthly (mid-month)", "Monthly (mid-month)", "4x per year", "8x per year",
                    "8x per year", "8x per year", "Quarterly (~30 days after quarter end)"),
      WhatIsIt = c(
        "Diffusion index of surveyed manufacturing purchasing managers.",
        "Diffusion index of surveyed purchasing managers, excluding manufacturing.",
        "Estimated change in private-sector employment, excluding farming and government.",
        "Change in the price businesses pay for labour, excluding farming.",
        "Change in the number of employed people, excluding farming.",
        "Percentage of the workforce unemployed and actively seeking work.",
        "Change in the price of finished goods and services sold by producers.",
        "Change in the price of goods and services purchased by consumers.",
        "CPI excluding food and energy.",
        "Fed's preferred inflation gauge; consumer spending ex food & energy.",
        "Change in total retail sales value, excluding automobiles.",
        "Change in total retail sales value.",
        "FOMC's projections for growth, inflation, and individual members' rate forecasts ('dot plot').",
        "FOMC's statement on the interest rate decision and economic outlook.",
        "Rate at which depository institutions lend to each other overnight.",
        "Press conference following the FOMC statement; often the primary driver of volatility.",
        "Annualised, inflation-adjusted change in the value of all goods and services produced."
      ),
      WhyTradersCare = c(
        "Leading indicator of economic health; businesses react quickly to market conditions.",
        "Leading indicator of economic health in the (much larger) services sector.",
        "Leading indicator of consumer spending, which drives most of economic activity.",
        "Leading indicator of consumer inflation via labour cost pass-through.",
        "Leading indicator of consumer spending and overall economic activity.",
        "Signals overall economic health; heavily weighted in monetary policy decisions.",
        "Leading indicator of consumer inflation via producer cost pass-through.",
        "Central to currency valuation — drives central bank interest rate decisions.",
        "Removes volatile components to show the underlying inflation trend.",
        "Rumoured to be the Fed's favourite inflation measure.",
        "Considered a better gauge of underlying spending trends than headline retail sales.",
        "Primary gauge of consumer spending, the majority of economic activity.",
        "Primary tool for communicating the Fed's economic and rate projections to markets.",
        "Primary tool for communicating monetary policy outcomes and outlook.",
        "The paramount short-term interest rate driving currency valuation.",
        "Unscripted Q&A creates the heaviest volatility of any scheduled US release.",
        "Broadest single measure of economic activity and health."
      ),
      ExpectedOutcome = c(
        "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
        "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
        "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
        "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
        "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
        "Actual > Forecast: USD down / Indices up. Actual < Forecast: USD up / Indices down.",
        "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
        "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
        "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
        "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
        "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
        "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
        "More hawkish than expected: USD up / Indices down. More dovish: USD down / Indices up.",
        "More hawkish than expected: USD up / Indices down. More dovish: USD down / Indices up.",
        "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up.",
        "More hawkish than expected: USD up / Indices down. More dovish: USD down / Indices up.",
        "Actual > Forecast: USD up / Indices down. Actual < Forecast: USD down / Indices up."
      ),
      stringsAsFactors = FALSE
    )
    
    observe({
      updateSelectInput(session, "macroIndicator", choices = macro_calendar_data$Release)
    })
    
    output$macroCalendarTable <- renderDT({
      datatable(macro_calendar_data,
                colnames = c("Release", "Frequency", "What Is It?", "Why Traders Care", "Expected Outcome"),
                options = list(pageLength = 8, scrollX = TRUE), rownames = FALSE)
    })
    
    output$macroReactionResult <- renderUI({
      req(input$macroIndicator, input$macroDirection)
      row <- macro_calendar_data[macro_calendar_data$Release == input$macroIndicator, ]
      req(nrow(row) == 1)
      
      is_unemployment <- row$Release == "Unemployment Rate"
      is_narrative <- row$Release %in% c("FOMC Economic Projections", "FOMC Statement", "FOMC Press Conference")
      
      if (input$macroDirection == "beat") {
        usd_dir <- if (is_unemployment) "Down" else "Up"
        idx_dir <- if (is_unemployment) "Up" else "Down"
        scenario_label <- if (is_narrative) "More hawkish than expected" else "Actual beats Forecast"
      } else {
        usd_dir <- if (is_unemployment) "Up" else "Down"
        idx_dir <- if (is_unemployment) "Down" else "Up"
        scenario_label <- if (is_narrative) "More dovish than expected" else "Actual misses Forecast"
      }
      
      usd_color <- if (usd_dir == "Up") "#27ae60" else "#e74c3c"
      idx_color <- if (idx_dir == "Up") "#27ae60" else "#e74c3c"
      
      tagList(
        tags$p(tags$strong(row$Release), style = "margin-bottom:2px;"),
        tags$p(scenario_label, style = "font-size:12px; color:#888; margin-bottom:10px;"),
        div(style = "display:flex; gap:12px;",
          div(style = paste0("flex:1; text-align:center; padding:10px; border-radius:8px; background:", usd_color, "22;"),
              tags$div("USD", style = "font-size:12px; color:#666;"),
              tags$h4(usd_dir, style = paste0("color:", usd_color, "; margin:2px 0 0 0;"))
          ),
          div(style = paste0("flex:1; text-align:center; padding:10px; border-radius:8px; background:", idx_color, "22;"),
              tags$div("Indices", style = "font-size:12px; color:#666;"),
              tags$h4(idx_dir, style = paste0("color:", idx_color, "; margin:2px 0 0 0;"))
          )
        ),
        tags$p("General historical tendency only — actual reaction depends on prevailing financial conditions and monetary policy stance.",
               style = "font-size:11px; color:#999; font-style:italic; margin-top:10px;")
      )
    })
    
    session$onSessionEnded(function() {})
  })
}
