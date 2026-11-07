# modules/chapter03.R — Alternative Data for Finance: Categories and Use Cases

chapter3_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(3, "🛰️", "Alternative Data for Finance",
      "Categories and Use Cases - The alternative data revolution is transforming investment research by providing novel signals from satellites, web scraping, geolocation, and social sentiment.",
      c("Satellite Imagery", "Web Scraping", "Geolocation", "Social Sentiment")),

    stats_row(
      list("400+", "Data Providers"),
      list("4", "Main Sources"), 
      list("$1B+", "Market Size"),
      list("10x", "Growth (2015-2025)")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          fluidRow(
            box(title = "🌍 The Alternative Data Revolution", status = "info", solidHeader = TRUE, width = 12,
                framework_card("What is Alternative Data?",
                  "Alternative data refers to information sources outside traditional financial statements, economic reports, and market prices. These novel datasets provide unique insights into economic activity, consumer behavior, and business operations before they appear in conventional financial metrics."
                ),
                div(style = "margin-top: 15px;",
                  plotlyOutput(ns("alt_data_growth"), height = "280px")
                )
            )
          ),
          
          fluidRow(
            box(title = "📡 Sources of Alternative Data", status = "warning", solidHeader = TRUE, width = 12,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(
                    tags$th("Source Category"), 
                    tags$th("Data Types"), 
                    tags$th("Example Providers"),
                    tags$th("Use Cases")
                  )),
                  tags$tbody(
                    tags$tr(
                      tags$td(tags$strong("🧑 Individuals")),
                      tags$td("Social media, app usage, search trends, reviews"),
                      tags$td("Twitter, Google Trends, Yelp, App Annie"),
                      tags$td("Sentiment analysis, product popularity, brand perception")
                    ),
                    tags$tr(
                      tags$td(tags$strong("🏢 Business Processes")),
                      tags$td("Credit card transactions, email receipts, supply chain"),
                      tags$td("Second Measure, Earnest Research, Bloomberg"),
                      tags$td("Consumer spending patterns, revenue proxies")
                    ),
                    tags$tr(
                      tags$td(tags$strong("🛰️ Satellites")),
                      tags$td("Imagery, parking lots, shipping, agriculture"),
                      tags$td("Planet Labs, Orbital Insight, Descartes Labs"),
                      tags$td("Retail traffic, commodity supply, construction activity")
                    ),
                    tags$tr(
                      tags$td(tags$strong("📍 Geolocation")),
                      tags$td("Mobile location, foot traffic, visit patterns"),
                      tags$td("SafeGraph, Foursquare, Cuebiq"),
                      tags$td("Store visits, competitive analysis, urbanization trends")
                    ),
                    tags$tr(
                      tags$td(tags$strong("📊 Sensors/IoT")),
                      tags$td("Weather, pollution, energy usage, shipping"),
                      tags$td("Weather Source, MarineTraffic, FlightRadar24"),
                      tags$td("Agricultural yields, shipping volumes, travel demand")
                    )
                  )
                )
            )
          ),
          
          fluidRow(
            box(title = "✅ Evaluation Criteria for Alternative Data", status = "success", solidHeader = TRUE, width = 6,
                framework_card("Signal Quality",
                  tags$ul(
                    tags$li(tags$strong("Asset Class Coverage:"), " Equities, fixed income, commodities, FX"),
                    tags$li(tags$strong("Investment Style:"), " Value, momentum, quality, event-driven"),
                    tags$li(tags$strong("Risk Premiums:"), " Factor exposure and systematic risks"),
                    tags$li(tags$strong("Alpha Content:"), " Incremental predictive power vs existing data"),
                    tags$li(tags$strong("Decay Rate:"), " How quickly the edge dissipates")
                  )
                ),
                framework_card("Data Quality",
                  tags$ul(
                    tags$li(tags$strong("Accuracy:"), " Error rates, validation against ground truth"),
                    tags$li(tags$strong("Completeness:"), " Coverage gaps, missing values"),
                    tags$li(tags$strong("Consistency:"), " Definition changes, methodology shifts"),
                    tags$li(tags$strong("Survivorship Bias:"), " Historical availability")
                  )
                )
            ),
            
            box(title = "⚖️ Legal and Technical Considerations", status = "danger", solidHeader = TRUE, width = 6,
                framework_card("Legal & Reputational Risks",
                  tags$ul(
                    tags$li(tags$strong("Material Non-Public Info:"), " Ensure data is legally obtained"),
                    tags$li(tags$strong("Privacy Regulations:"), " GDPR, CCPA compliance"),
                    tags$li(tags$strong("Terms of Service:"), " Web scraping limitations"),
                    tags$li(tags$strong("Licensing Rights:"), " Permitted usage and redistribution"),
                    tags$li(tags$strong("Reputational Risk:"), " Controversial data sources")
                  )
                ),
                framework_card("Technical Aspects",
                  tags$ul(
                    tags$li(tags$strong("Latency:"), " Time from event to data availability"),
                    tags$li(tags$strong("Frequency:"), " Update cadence (real-time to annual)"),
                    tags$li(tags$strong("Format:"), " API, files, manual delivery"),
                    tags$li(tags$strong("Reliability:"), " Uptime, consistency, vendor stability"),
                    tags$li(tags$strong("Scalability:"), " Historical depth, forward availability")
                  )
                ),
                tip_box("Exclusivity", "Exclusive datasets command premium pricing but provide stronger edge. However, popular datasets can still add value when combined with unique processing methods or integrated with proprietary signals.")
            )
          ),
          
          fluidRow(
            box(title = "💡 Alternative Data Use Case Examples", status = "info", solidHeader = TRUE, width = 12,
                plotlyOutput(ns("use_case_examples"), height = "400px")
            )
          ),
          
          fluidRow(
            box(title = "🕷️ Web Scraping Techniques", status = "warning", solidHeader = TRUE, width = 6,
                framework_card("Common Tools and Frameworks",
                  tags$ul(
                    tags$li(tags$strong("Requests + BeautifulSoup:"), " Parse static HTML pages"),
                    tags$li(tags$strong("Selenium:"), " Browser automation for JavaScript-rendered content"),
                    tags$li(tags$strong("Scrapy:"), " Production-grade scraping framework with pipelines"),
                    tags$li(tags$strong("Splash:"), " Headless browser for JavaScript rendering"),
                    tags$li(tags$strong("Playwright/Puppeteer:"), " Modern browser automation")
                  )
                ),
                framework_card("Best Practices",
                  tags$ol(
                    tags$li("Respect robots.txt and rate limits"),
                    tags$li("Rotate user agents and IP addresses"),
                    tags$li("Implement exponential backoff for retries"),
                    tags$li("Cache responses to minimize requests"),
                    tags$li("Monitor for website structure changes"),
                    tags$li("Store raw HTML before parsing")
                  )
                )
            ),
            
            box(title = "📊 Data Provider Market Landscape", status = "success", solidHeader = TRUE, width = 6,
                framework_card("Market Segments",
                  tags$ul(
                    tags$li(tags$strong("Social Sentiment:"), " StockTwits, Sentdex, RavenPack"),
                    tags$li(tags$strong("Satellite Imagery:"), " Planet Labs, Orbital Insight"),
                    tags$li(tags$strong("Geolocation:"), " SafeGraph, Foursquare, Placer.ai"),
                    tags$li(tags$strong("Email Receipts:"), " Edison Trends, Earnest Research"),
                    tags$li(tags$strong("Web Traffic:"), " SimilarWeb, Alexa (retired), SEMrush"),
                    tags$li(tags$strong("Job Postings:"), " Thinknum, Revelio Labs"),
                    tags$li(tags$strong("App Analytics:"), " Sensor Tower, App Annie (now data.ai)")
                  )
                ),
                info_box("<strong>💰 Pricing Models:</strong> Subscription (annual/monthly), pay-per-use, minimum commitments, and enterprise licensing. Costs range from thousands to millions annually depending on coverage and exclusivity.")
            )
          ),
          
          fluidRow(
            box(title = "🎯 Example: Restaurant Data Analysis", status = "info", solidHeader = TRUE, width = 12,
                framework_card("OpenTable Scraping Project",
                  tagList(
                    tags$p("A common beginner project involves scraping restaurant booking and rating data from OpenTable to predict restaurant chain performance before quarterly earnings."),
                    tags$h5("Implementation Steps:"),
                    tags$ol(
                      tags$li(tags$strong("Target Identification:"), " Select restaurant chains with public equity (Darden, Bloomin' Brands)"),
                      tags$li(tags$strong("Data Collection:"), " Scrape booking availability, ratings, review counts, price tier"),
                      tags$li(tags$strong("Frequency:"), " Weekly or bi-weekly snapshots"),
                      tags$li(tags$strong("Feature Engineering:"), " Booking rate changes, rating momentum, review velocity"),
                      tags$li(tags$strong("Signal Generation:"), " Detect inflections in booking trends vs prior periods"),
                      tags$li(tags$strong("Validation:"), " Backtest signals against reported same-store sales growth")
                    )
                  )
                ),
                framework_card("Earnings Call Transcript Analysis",
                  tagList(
                    tags$p("Natural language processing of quarterly earnings call transcripts can reveal sentiment shifts, management tone, and discussion topic changes."),
                    tags$h5("Key Techniques:"),
                    tags$ul(
                      tags$li("Sentiment scoring using financial dictionaries (Loughran-McDonald)"),
                      tags$li("Topic modeling to track discussion themes"),
                      tags$li("Management vs analyst Q&A sentiment comparison"),
                      tags$li("Measure evasiveness, uncertainty, and complexity in responses")
                    )
                  )
                )
            )
          )
        ), # end Theory

        tabPanel(title = tagList(icon("code"), " Python Code"),
          python_code_tab()
        )
      )
    )
  )
}

chapter3_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    # Alternative data market growth
    output$alt_data_growth <- renderPlotly({
      growth_data <- data.frame(
        Year = c(2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025),
        Market_Size_M = c(100, 150, 230, 350, 500, 680, 900, 1150, 1450, 1800, 2200),
        Providers = c(50, 75, 120, 180, 250, 320, 380, 430, 470, 500, 530)
      )
      
      p <- plot_ly(growth_data) %>%
        add_trace(
          x = ~Year,
          y = ~Market_Size_M,
          name = "Market Size ($M)",
          type = "scatter",
          mode = "lines+markers",
          yaxis = "y1",
          line = list(color = "#008A82", width = 3),
          marker = list(size = 8, color = "#008A82"),
          hovertemplate = "<b>%{x}</b><br>Market Size: $%{y}M<extra></extra>"
        ) %>%
        add_trace(
          x = ~Year,
          y = ~Providers,
          name = "Number of Providers",
          type = "scatter",
          mode = "lines+markers",
          yaxis = "y2",
          line = list(color = "#FF6B35", width = 3, dash = "dash"),
          marker = list(size = 8, color = "#FF6B35"),
          hovertemplate = "<b>%{x}</b><br>Providers: %{y}<extra></extra>"
        ) %>%
        layout(
          title = list(text = "Alternative Data Market Growth (2015-2025)", font = list(color = "#E6EDF3")),
          xaxis = list(
            title = "Year",
            color = "#8B949E"
          ),
          yaxis = list(
            title = "Market Size ($ Million)",
            color = "#008A82",
            gridcolor = "#30363D",
            side = "left"
          ),
          yaxis2 = list(
            title = "Number of Providers",
            color = "#FF6B35",
            overlaying = "y",
            side = "right",
            showgrid = FALSE
          ),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(
            font = list(color = "#E6EDF3"),
            bgcolor = "rgba(28, 33, 40, 0.8)",
            x = 0.02,
            y = 0.98
          ),
          hovermode = "x unified"
        )
      
      p
    })
    
    # Use case examples
    output$use_case_examples <- renderPlotly({
      use_cases <- data.frame(
        Data_Source = c("Satellite Parking Lots", "Credit Card Data", "App Downloads", 
                       "Geolocation Foot Traffic", "Social Sentiment", "Web Traffic"),
        Predictive_Power = c(0.75, 0.85, 0.70, 0.80, 0.55, 0.65),
        Implementation_Difficulty = c(0.80, 0.90, 0.50, 0.70, 0.40, 0.45),
        Cost = c(0.85, 0.95, 0.60, 0.75, 0.30, 0.40),
        Category = c("Satellite", "Financial", "Digital", "Geolocation", "Social", "Digital")
      )
      
      # Create color mapping
      color_map <- c(
        "Satellite" = "#7B68EE",
        "Financial" = "#FF6B35",
        "Digital" = "#00A39A",
        "Geolocation" = "#F7931E",
        "Social" = "#20B2AA"
      )
      
      p <- plot_ly(
        data = use_cases,
        x = ~Implementation_Difficulty,
        y = ~Predictive_Power,
        type = "scatter",
        mode = "markers+text",
        marker = list(
          size = ~Cost * 50,
          color = ~Category,
          colors = color_map,
          line = list(color = "white", width = 2),
          opacity = 0.8
        ),
        text = ~Data_Source,
        textposition = "top center",
        textfont = list(size = 9, color = "#E6EDF3"),
        hovertemplate = paste(
          "<b>%{text}</b><br>",
          "Predictive Power: %{y:.0%}<br>",
          "Implementation Difficulty: %{x:.0%}<br>",
          "Relative Cost: %{marker.size:.0f}<br>",
          "<extra></extra>"
        )
      ) %>%
        layout(
          title = list(
            text = "Alternative Data Use Cases<br><sub>Size = Relative Cost | Position = Power vs Difficulty</sub>", 
            font = list(color = "#E6EDF3")
          ),
          xaxis = list(
            title = "Implementation Difficulty →",
            color = "#8B949E",
            gridcolor = "#30363D",
            range = c(0.2, 1),
            tickformat = ".0%"
          ),
          yaxis = list(
            title = "← Predictive Power",
            color = "#8B949E",
            gridcolor = "#30363D",
            range = c(0.4, 1),
            tickformat = ".0%"
          ),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          showlegend = TRUE,
          legend = list(
            title = list(text = "Category", font = list(color = "#E6EDF3")),
            font = list(color = "#E6EDF3"),
            bgcolor = "rgba(28, 33, 40, 0.8)"
          ),
          annotations = list(
            list(
              x = 0.3,
              y = 0.9,
              text = "Sweet Spot:<br>High Power,<br>Lower Difficulty",
              showarrow = FALSE,
              font = list(size = 10, color = "#28A745"),
              bgcolor = "rgba(40, 167, 69, 0.1)",
              bordercolor = "#28A745",
              borderwidth = 1,
              borderpad = 4
            )
          )
        )
      
      p
    })
    
  })
}
