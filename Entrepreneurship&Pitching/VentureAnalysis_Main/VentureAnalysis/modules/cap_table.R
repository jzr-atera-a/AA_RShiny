# modules/cap_table.R: Interactive Cap Table

cap_table_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(5, "\U0001f4ca", "Cap Table",
      "The capitalisation table is the ledger of who owns what in your company. Every financing event: grant, SAFE, seed round, Series A: reshapes it. Model your dilution before you sign, not after.",
      c("DILUTION MODEL", "FULLY DILUTED", "ROUND MODELLING", "DEEPTECH MULTI-ROUND")),

    # ── How to use this tab ───────────────────────────────────
    fluidRow(
      box(title = "\U0001f4a1 How to Use This Tab", status = "warning",
          solidHeader = TRUE, width = 12,
        tags$p(style = "color:#8fb0d8;font-size:13px;line-height:1.7;margin:0;",
          tags$b(style = "color:#00e5ff;", "\U0001f3b2 Interactive Dilution Modeller: "),
          "all sliders on the left update every chart and table instantly.
          Start by setting your ",
          tags$b(style = "color:#cdd9f5;", "Seed parameters"),
          " (how much raised and at what pre-money valuation), then set your ",
          tags$b(style = "color:#cdd9f5;", "Series A parameters"),
          " and the option pool percentage. The stacked bar chart shows ownership at each stage.",
          tags$br(), tags$br(),
          tags$b(style = "color:#00e5ff;", "What to watch: "),
          "the ",
          tags$b(style = "color:#cdd9f5;", "Option Pool bar"),
          " at the 'After Option Pool' stage: this is all pre-money dilution to founders
          before the VC even invests. Try increasing option pool from 8% to 15% and watch
          founder ownership drop. This is the option pool shuffle in action.",
          tags$br(), tags$br(),
          tags$b(style = "color:#00e5ff;", "Pie chart: "),
          "shows the ownership split at Series A close: the view your VC will show in their deck.
          The stats panel on the right shows the key metrics: founder % at Series A, founder % at
          Series B, and the implied share price at each round.",
          tags$br(), tags$br(),
          tags$b(style = "color:#00e5ff;", "DT table: "),
          "the formatted table at the bottom shows every holder, their share count, ownership
          percentage, and implied value at the Series A share price.",
          tags$br(), tags$br(),
          tags$b(style = "color:#00e5ff;", "\U0001f4cc Rule of thumb: "),
          "a DeepTech founder should target retaining at least 20:30% at Series B close.
          Watch the 'Founder % at Series B' metric as you adjust round sizes."
        )
      )
    ),

      

    fluidRow(
      box(title = "Interactive Dilution Modeller: QuantumLeap AI", status = "primary", solidHeader = TRUE, width = 12,
        p(class = "info-box-plain", HTML("\U0001f4ca <strong>How to use:</strong> Adjust the round parameters below to model how different Series A terms affect founder ownership through to exit. The chart shows the full ownership stack at each stage.")),
        fluidRow(
          column(3,
            sh("Seed Round (Actual)"),
            sliderInput(ns("seed_raised"), "Seed Raised (£M)", 0.5, 5, 2.1, 0.1),
            sliderInput(ns("seed_premoney"), "Seed Pre-Money (£M)", 2, 15, 6, 0.5),
            sh("Series A Parameters"),
            sliderInput(ns("serA_raised"), "Series A (£M)", 3, 30, 12, 0.5),
            sliderInput(ns("serA_premoney"), "Series A Pre-Money (£M)", 10, 80, 28, 1),
            sliderInput(ns("option_pool"), "Option Pool % (pre-A)", 5, 20, 12, 1),
            sh("Series B (Projected)"),
            sliderInput(ns("serB_raised"), "Series B (£M)", 10, 80, 30, 5),
            sliderInput(ns("serB_premoney"), "Series B Pre-Money (£M)", 40, 200, 90, 5)
          ),
          column(9,
            plotlyOutput(ns("dilution_chart"), height = "400px"),
            br(),
            fluidRow(
              column(6, plotlyOutput(ns("ownership_pie"), height = "280px")),
              column(6, uiOutput(ns("cap_stats")))
            )
          )
        )
      )
    ),

    fluidRow(
      box(title = "Cap Table: QuantumLeap AI at Series A Close", status = "info", solidHeader = TRUE, width = 12,
        p(class = "info-box-plain", HTML("\U0001f4ca <strong>Methodology:</strong> Cap table computed from slider inputs. Fully diluted share count includes issued shares plus unissued option pool. Ownership % = shares held / total fully diluted × 100.")),
        DT::dataTableOutput(ns("cap_table_dt"))
      )
    )
  )
}

cap_table_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {

    # Reactive cap table calculations
    cap <- reactive({
      total_shares <- 10000000  # 10M shares at founding

      # Seed round
      seed_post  <- input$seed_premoney + input$seed_raised
      seed_pct   <- input$seed_raised / seed_post
      seed_shares <- round(total_shares * seed_pct / (1 - seed_pct))
      total_after_seed <- total_shares + seed_shares

      # Option pool pre-Series A
      pool_shares <- round(total_after_seed * (input$option_pool / 100) / (1 - input$option_pool / 100))
      total_pre_serA <- total_after_seed + pool_shares

      # Series A
      serA_post  <- input$serA_premoney + input$serA_raised
      serA_pct   <- input$serA_raised / serA_post
      serA_shares <- round(total_pre_serA * serA_pct / (1 - serA_pct))
      total_after_serA <- total_pre_serA + serA_shares

      # Series B
      serB_post  <- input$serB_premoney + input$serB_raised
      serB_pct   <- input$serB_raised / serB_post
      serB_shares <- round(total_after_serA * serB_pct / (1 - serB_pct))
      total_after_serB <- total_after_serA + serB_shares

      list(
        founder_shares = total_shares,
        seed_shares    = seed_shares,
        pool_shares    = pool_shares,
        serA_shares    = serA_shares,
        serB_shares    = serB_shares,
        total_seed     = total_after_seed,
        total_pre_serA = total_pre_serA,
        total_serA     = total_after_serA,
        total_serB     = total_after_serB,
        founder_pct_serA = total_shares / total_after_serA * 100,
        founder_pct_serB = total_shares / total_after_serB * 100,
        serA_price     = input$serA_premoney * 1e6 / total_pre_serA,
        serB_price     = input$serB_premoney * 1e6 / total_after_serA
      )
    })

    output$dilution_chart <- renderPlotly({
      c <- cap()
      stages <- c("Founding", "After Seed", "After Option Pool", "After Series A", "After Series B")
      founder <- c(100,
                   c$founder_shares / c$total_seed * 100,
                   c$founder_shares / c$total_pre_serA * 100,
                   c$founder_shares / c$total_serA * 100,
                   c$founder_shares / c$total_serB * 100)
      seed_inv <- c(0,
                    c$seed_shares / c$total_seed * 100,
                    c$seed_shares / c$total_pre_serA * 100,
                    c$seed_shares / c$total_serA * 100,
                    c$seed_shares / c$total_serB * 100)
      pool_pct <- c(0, 0,
                    c$pool_shares / c$total_pre_serA * 100,
                    c$pool_shares / c$total_serA * 100,
                    c$pool_shares / c$total_serB * 100)
      serA_pct <- c(0, 0, 0,
                    c$serA_shares / c$total_serA * 100,
                    c$serA_shares / c$total_serB * 100)
      serB_pct <- c(0, 0, 0, 0,
                    c$serB_shares / c$total_serB * 100)

      plot_ly() %>%
        add_trace(x = stages, y = round(founder, 1), type = "bar", name = "Founders",
                  marker = list(color = "#00e5ff")) %>%
        add_trace(x = stages, y = round(seed_inv, 1), type = "bar", name = "Seed Investors",
                  marker = list(color = "#00aa55")) %>%
        add_trace(x = stages, y = round(pool_pct, 1), type = "bar", name = "Option Pool",
                  marker = list(color = "#7aa8e0")) %>%
        add_trace(x = stages, y = round(serA_pct, 1), type = "bar", name = "Series A VC",
                  marker = list(color = "#0066cc")) %>%
        add_trace(x = stages, y = round(serB_pct, 1), type = "bar", name = "Series B VC",
                  marker = list(color = "#003d99")) %>%
        layout(barmode = "stack",
               title = list(text = "Ownership Dilution Through Funding Rounds", font = list(color = "#cdd9f5")),
               yaxis = list(title = "Ownership %", range = c(0, 100)),
               xaxis = list(title = "")) %>% dt_theme()
    })

    output$ownership_pie <- renderPlotly({
      c <- cap()
      t <- c$total_serA
      labels <- c("Founders", "Seed Investors", "Option Pool", "Series A VC")
      values <- c(c$founder_shares, c$seed_shares, c$pool_shares, c$serA_shares)
      colors <- c("#00e5ff", "#00aa55", "#7aa8e0", "#0066cc")

      plot_ly(labels = labels, values = values, type = "pie",
              marker = list(colors = colors, line = list(color = "#020a1a", width = 2)),
              textinfo = "label+percent",
              textfont = list(color = "#ffffff")) %>%
        layout(title = list(text = "Ownership at Series A Close", font = list(color = "#cdd9f5")),
               showlegend = FALSE) %>% dt_theme()
    })

    output$cap_stats <- renderUI({
      c <- cap()
      div(
        sh("Key Metrics"),
        mc_stat(paste0(round(c$founder_pct_serA, 1), "%"), "Founder % at Series A"),
        mc_stat(paste0(round(c$founder_pct_serB, 1), "%"), "Founder % at Series B"),
        mc_stat(paste0("£", round(c$serA_price, 2)), "Series A Price Per Share"),
        mc_stat(paste0("£", round(c$serB_price, 2)), "Series B Price Per Share"),
        div(class = "tip-box", style = "margin-top:12px;",
          tags$strong("\U0001f4a1 Rule of thumb: "), "A DeepTech founder should target retaining at least ",
          tags$b("20:30%"), " ownership at Series B close to maintain meaningful economic participation in the exit.")
      )
    })

    output$cap_table_dt <- DT::renderDataTable({
      c <- cap()
      t <- c$total_serA
      df <- data.frame(
        Holder         = c("Founding Team", "Seed Investors", "Option Pool (unissued)", "Series A VC", "TOTAL"),
        Shares         = c(c$founder_shares, c$seed_shares, c$pool_shares, c$serA_shares,
                           c$total_serA),
        `Ownership %`  = c(round(c$founder_shares/t*100, 2),
                           round(c$seed_shares/t*100, 2),
                           round(c$pool_shares/t*100, 2),
                           round(c$serA_shares/t*100, 2), 100.00),
        `Value at SerA Price` = paste0("£", formatC(c(
          c$founder_shares, c$seed_shares, c$pool_shares, c$serA_shares, t
        ) * c$serA_price / 1e6, format = "f", digits = 2), "M"),
        Type = c("Common", "Preferred (Seed)", "Options", "Preferred (Series A)", ""),
        stringsAsFactors = FALSE
      )
      DT::datatable(df, rownames = FALSE, options = list(dom = "t", pageLength = 10),
                    class = "cell-border") %>%
        DT::formatStyle("Holder", fontWeight = "bold", color = "#cdd9f5") %>%
        DT::formatStyle(names(df), backgroundColor = "rgba(7,26,62,0.60)", color = "#8fb0d8")
    })
  })
}
