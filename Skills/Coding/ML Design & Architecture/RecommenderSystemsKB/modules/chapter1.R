# modules/chapter1.R
# Chapter 1: What is a Recommender?
# Theory (from KB) + Code Lab: Long Tail Explorer & Rec Type Simulator

chapter1_ui <- function(id) {
  ns <- NS(id)
  tagList(

    # ── Hero (outside tabs) ──────────────────────────────────
    div(class = "meta-hero",
        tags$h1("Chapter 1: What is a Recommender?"),
        tags$h2("Understanding Recommendation Systems and Their Impact"),
        div(
          span(class = "hero-badge", "Foundations"),
          span(class = "hero-badge", "Long Tail"),
          span(class = "hero-badge", "Netflix Prize"),
          span(class = "hero-badge", "Real-World Examples")
        )
    ),

    fluidRow(
      box(title = "🎯 Chapter Overview", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, div(class = "metric-card", span(class = "metric-value", "3"),
                          span(class = "metric-label", "Main Sections"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "5"),
                          span(class = "metric-label", "Key Concepts"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "$1M"),
                          span(class = "metric-label", "Netflix Prize"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "80%"),
                          span(class = "metric-label", "Netflix Watches from Recs")))
          )
      )
    ),

    # ── Tabbed content ───────────────────────────────────────
    fluidRow(
      tabBox(
        width = 12, id = ns("ch1_tabs"),

        # ─────────────────────────────────────────────────────
        # THEORY TAB
        # ─────────────────────────────────────────────────────
        tabPanel(
          title = tagList(icon("book"), " Theory"),

          fluidRow(
            box(title = "📚 Real-Life Recommendations", status = "info",
                solidHeader = TRUE, width = 6,
                div(class = "section-heading-dark", "How Recommendations Work in Everyday Life"),
                div(class = "framework-card",
                    tags$h5("The Restaurant Analogy"),
                    tags$p("When a friend recommends a restaurant, they consider:"),
                    tags$p(HTML("<strong>Your preferences:</strong> Vegetarian? Spicy food lover?")),
                    tags$p(HTML("<strong>Context:</strong> Casual lunch or romantic dinner?")),
                    tags$p(HTML("<strong>Their experience:</strong> What they know about the place")),
                    tags$p(HTML("<strong>Trust:</strong> Their track record of good recommendations"))),
                div(class = "success-box",
                    HTML("<strong>✅ Key Insight:</strong> Recommender systems automate this process at scale.")),
                div(class = "section-heading-dark", "From Human to Algorithmic Recommendations"),
                tags$p(style = "color:#8a9bb0;font-size:12px;line-height:1.65;",
                       "Traditional recommendations relied on experts. Digital recommender systems democratized this by:",
                       tags$ul(
                         tags$li(HTML("<strong>Aggregating wisdom of crowds:</strong> Millions of user ratings")),
                         tags$li(HTML("<strong>Finding patterns:</strong> People who liked X also liked Y")),
                         tags$li(HTML("<strong>Personalizing at scale:</strong> Unique recommendations per user")),
                         tags$li(HTML("<strong>Real-time adaptation:</strong> Learning from every interaction"))
                       ))
            ),

            box(title = "🌐 Recommender Systems on the Internet", status = "warning",
                solidHeader = TRUE, width = 6,
                div(class = "section-heading-dark", "Where Recommenders Are Used"),
                tags$table(class = "algo-table",
                           tags$tr(tags$td(HTML("<strong>E-commerce:</strong>")),  tags$td("Amazon product recommendations")),
                           tags$tr(tags$td(HTML("<strong>Streaming:</strong>")),   tags$td("Netflix movies, Spotify playlists")),
                           tags$tr(tags$td(HTML("<strong>Social Media:</strong>")),tags$td("Facebook friends, LinkedIn connections")),
                           tags$tr(tags$td(HTML("<strong>Content:</strong>")),     tags$td("YouTube videos, news articles")),
                           tags$tr(tags$td(HTML("<strong>Travel:</strong>")),      tags$td("Booking.com hotels, TripAdvisor")),
                           tags$tr(tags$td(HTML("<strong>Dating:</strong>")),      tags$td("Match.com, Tinder matches"))
                ),
                br(),
                div(class = "tip-box",
                    HTML("<strong>💡 Business Impact:</strong> Amazon reports 35% of revenue from recs.
                     Netflix estimates 80% of watched content is discovered through recommendations.")),
                br(),
                div(class = "section-heading-dark", "Why Companies Invest in RecSys"),
                tags$ul(style = "color:#8a9bb0;font-size:12px;line-height:1.75;",
                        tags$li(HTML("<strong>Increased engagement</strong>")),
                        tags$li(HTML("<strong>Higher conversion rates</strong>")),
                        tags$li(HTML("<strong>Customer satisfaction & loyalty</strong>")),
                        tags$li(HTML("<strong>Discovery of long-tail content</strong>"))
                )
            )
          ),

          fluidRow(
            box(title = "📊 The Long Tail Phenomenon", status = "success",
                solidHeader = TRUE, width = 12,
                div(class = "info-box-plain",
                    HTML("<strong>The Long Tail Theory:</strong> Chris Anderson's concept that online businesses
                     can profit from selling small quantities of many niche items.")),
                br(),
                plotlyOutput(ns("long_tail_plot")),
                br(),
                fluidRow(
                  column(4, div(class = "metric-card", span(class = "metric-value", "20%"),
                                span(class = "metric-label", "Popular Items"))),
                  column(4, div(class = "metric-card", span(class = "metric-value", "80%"),
                                span(class = "metric-label", "Long Tail Items"))),
                  column(4, div(class = "metric-card", span(class = "metric-value", "∞"),
                                span(class = "metric-label", "Digital Shelf Space")))
                )
            )
          ),

          fluidRow(
            box(title = "🏆 The Netflix Prize", status = "primary",
                solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("Competition Details (2006–2009)"),
                    tags$p(HTML("<strong>Challenge:</strong> Beat Cinematch by 10% RMSE")),
                    tags$p(HTML("<strong>Prize:</strong> $1 million")),
                    tags$p(HTML("<strong>Dataset:</strong> 100M ratings, 480K users, 17,770 movies")),
                    tags$p(HTML("<strong>Winner:</strong> BellKor's Pragmatic Chaos (2009)"))
                ),
                div(class = "success-box",
                    HTML("<strong>✅ Impact:</strong> Popularized collaborative filtering and matrix factorization.")),
                plotlyOutput(ns("netflix_prize_plot"))
            ),

            box(title = "🎬 Types of Recommendations", status = "warning",
                solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("1. Non-Personalized"),
                    tags$p("Same recommendations for all users. Based on popularity."),
                    tags$p(HTML("<strong>Examples:</strong> Trending Now, Top Rated"))
                ),
                div(class = "framework-card",
                    tags$h5("2. Content-Based Filtering"),
                    tags$p("Recommend items similar to what user liked before."),
                    tags$p(HTML("<strong>Examples:</strong> More like this, Same genre"))
                ),
                div(class = "framework-card",
                    tags$h5("3. Collaborative Filtering"),
                    tags$p("Recommend based on similar users' preferences."),
                    tags$p(HTML("<strong>Examples:</strong> Users who liked X also liked Y"))
                ),
                div(class = "framework-card",
                    tags$h5("4. Hybrid Systems"),
                    tags$p("Combine multiple approaches for better performance."),
                    tags$p(HTML("<strong>Examples:</strong> Netflix, Amazon, Spotify"))
                ),
                div(class = "tip-box",
                    HTML("<strong>💡 Real-World Practice:</strong> Production systems almost always use hybrids."))
            )
          )
        ), # end Theory tab

        # ─────────────────────────────────────────────────────
        # CODE LAB TAB
        # ─────────────────────────────────────────────────────
        tabPanel(
          title = tagList(icon("code"), " Code Lab"),

          # ── Header ────────────────────────────────────────
          code_lab_header(
            title    = "Long Tail Explorer & Rec Type Simulator",
            subtitle = "Interact with the power law distribution and compare what each recommendation strategy returns.",
            badges   = c("R", "plotly")
          ),

          # ── Section 1: Long Tail Explorer ─────────────────
          fluidRow(
            box(title = "📉 Interactive Long Tail Explorer", status = "success",
                solidHeader = TRUE, width = 8,
                div(class = "section-heading-dark", "Adjust the Power Law Parameters"),
                div(class = "control-panel",
                    fluidRow(
                      column(6,
                             sliderInput(ns("alpha"), "Power Law Exponent (α)",
                                         min = 0.5, max = 3.0, value = 1.5, step = 0.1)),
                      column(6,
                             sliderInput(ns("n_items"), "Number of Items",
                                         min = 100, max = 2000, value = 500, step = 100))
                    ),
                    run_button(ns("run_longtail"), "▶  Update Distribution")
                ),
                plotlyOutput(ns("longtail_interactive"))
            ),

            box(title = "📐 Power Law Formula", status = "info",
                solidHeader = TRUE, width = 4,
                div(class = "section-heading-dark", "The Formula"),
                r_code_block(
'# Power law (Zipf-like) distribution
# popularity(rank) = C / rank^alpha

alpha  <- 1.5   # exponent
n      <- 500   # number of items
ranks  <- 1:n

popularity <- 10000 / ranks^alpha

# Higher alpha = steeper tail
# Lower alpha  = flatter (more equal)'
                ),
                br(),
                div(class = "framework-card",
                    tags$h5("What α Controls"),
                    tags$p(HTML("<strong>α ≈ 0.5:</strong> Very flat — niche items nearly as popular as hits")),
                    tags$p(HTML("<strong>α = 1.0:</strong> Classic Zipf law")),
                    tags$p(HTML("<strong>α ≈ 1.5:</strong> Typical for movies/music")),
                    tags$p(HTML("<strong>α ≥ 2.0:</strong> Winner-take-all — top items dominate"))
                ),
                br(),
                div(class = "result-card",
                    tags$h5("Live Stats"),
                    uiOutput(ns("longtail_stats"))
                )
            )
          ),

          # ── Section 2: RMSE Calculator ────────────────────
          fluidRow(
            box(title = "🏆 Netflix Prize RMSE Calculator", status = "primary",
                solidHeader = TRUE, width = 6,
                div(class = "section-heading-dark", "Reproduce the Netflix Prize Metric"),
                div(class = "tip-box",
                    HTML("<strong>Context:</strong> The prize required a 10% improvement over Netflix's Cinematch baseline
                    (RMSE = 0.9525). Enter any baseline and improved RMSE to see the % gain.")),
                div(class = "control-panel",
                    fluidRow(
                      column(6, numericInput(ns("rmse_base"),     "Baseline RMSE",  value = 0.9525, step = 0.001)),
                      column(6, numericInput(ns("rmse_improved"), "Improved RMSE",  value = 0.8567, step = 0.001))
                    ),
                    run_button(ns("calc_rmse"), "▶  Calculate Improvement")
                ),
                uiOutput(ns("rmse_result")),
                br(),
                r_code_block(
'# RMSE improvement percentage
rmse_improvement <- function(baseline, improved) {
  pct <- (baseline - improved) / baseline * 100
  cat("Improvement:", round(pct, 3), "%\\n")
  if (pct >= 10) cat("🏆 Prize threshold reached!\\n")
  else cat("Still", round(10 - pct, 3), "% to go\\n")
}

rmse_improvement(0.9525, 0.8567)'
                )
            ),

            # ── Section 3: Rec Type Toy Demo ──────────────
            box(title = "🎬 Recommendation Type Comparison", status = "warning",
                solidHeader = TRUE, width = 6,
                div(class = "section-heading-dark", "5-User × 5-Movie Toy Example"),
                div(class = "info-box-plain",
                    HTML("<strong>Scenario:</strong> 5 users rated 5 movies (1–5 stars, NA = not seen).
                    Compare what each strategy recommends for User 1.")),
                div(class = "control-panel",
                    selectInput(ns("rec_type"), "Strategy for User 1:",
                                choices = c("Popularity (Most Rated)"   = "popular",
                                            "Random (No Personalisation)" = "random",
                                            "User-Based CF (Naive)"      = "usercf")),
                    run_button(ns("run_rectypes"), "▶  Show Recommendations")
                ),
                DTOutput(ns("toy_matrix")),
                br(),
                uiOutput(ns("rec_type_result"))
            )
          )
        ) # end Code Lab tab
      )
    )
  )
}

chapter1_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # ── Theory plots (from KB) ───────────────────────────────
    output$long_tail_plot <- renderPlotly({
      items <- 1:1000
      df    <- data.frame(rank = items, views = 10000 / items^1.5)
      plot_ly(df, x = ~rank, y = ~views, type = "scatter", mode = "lines",
              line = list(color = "#e8410a", width = 3),
              fill = "tozeroy", fillcolor = "rgba(232,65,10,0.2)",
              hovertemplate = "<b>Rank:</b> %{x}<br><b>Views:</b> %{y:.0f}<extra></extra>") %>%
        layout(title = list(text = "The Long Tail: Item Popularity Distribution",
                            font = list(color = "#ffb49a", size = 14)),
               xaxis = list(title = "Item Rank"),
               yaxis = list(title = "Views / Sales"),
               annotations = list(
                 list(x = 80,  y = 10000 * 0.8, text = "The HEAD",
                      showarrow = TRUE, arrowcolor = "#ffb49a",
                      font = list(color = "#ffb49a", size = 11)),
                 list(x = 600, y = 10000 * 0.15, text = "The TAIL",
                      showarrow = TRUE, arrowcolor = "#ffb49a",
                      font = list(color = "#ffb49a", size = 11))
               )) %>%
        plotly_dark_theme()
    })

    output$netflix_prize_plot <- renderPlotly({
      yrs <- rep(seq(2006.5, 2009.5, by = 0.25), 3)
      df  <- data.frame(
        year = yrs,
        team = rep(c("BellKor","Dinosaur Planet","Gravity"), each = 14),
        pct  = c(
          c(0,1.2,2.5,3.8,5.1,6.3,7.2,8.1,8.7,9.2,9.5,9.8,10.0,10.06),
          c(0,0.8,1.9,3.2,4.5,5.6,6.5,7.3,7.9,8.4,8.8,9.1,9.4, 9.7),
          c(0,0.5,1.3,2.4,3.7,4.8,5.7,6.4,7.0,7.5,7.9,8.3,8.6, 8.9)
        )
      )
      plot_ly() %>%
        add_trace(data = df[df$team=="BellKor",],         x=~year,y=~pct,type="scatter",
                  mode="lines+markers", name="BellKor (Winner)",
                  line=list(color="#e8410a",width=3),   marker=list(size=6)) %>%
        add_trace(data = df[df$team=="Dinosaur Planet",], x=~year,y=~pct,type="scatter",
                  mode="lines+markers", name="Dinosaur Planet",
                  line=list(color="#3b82f6",width=2),   marker=list(size=5)) %>%
        add_trace(data = df[df$team=="Gravity",],         x=~year,y=~pct,type="scatter",
                  mode="lines+markers", name="Gravity",
                  line=list(color="#10b981",width=2),   marker=list(size=5)) %>%
        layout(
          title = list(text = "Netflix Prize: Race to 10% RMSE Improvement",
                       font = list(color = "#ffb49a", size = 14)),
          xaxis = list(title = "Year", gridcolor = "rgba(255,255,255,0.08)", color = "#8a9bb0"),
          yaxis = list(title = "RMSE Improvement (%)", gridcolor = "rgba(255,255,255,0.08)", color = "#8a9bb0"),
          shapes = list(list(type="line", x0=2006.5, x1=2009.5, y0=10, y1=10,
                             line=list(color="#fbbf24",width=2,dash="dash"))),
          annotations = list(list(x=2009,y=10.5,text="10% Target",showarrow=FALSE,
                                  font=list(color="#fbbf24",size=11))),
          legend = list(font = list(color = "#8a9bb0"))
        ) %>%
        plotly_dark_theme()
    })

    # ── Code Lab: Long Tail Interactive ─────────────────────
    longtail_data <- eventReactive(input$run_longtail, {
      alpha   <- input$alpha
      n       <- input$n_items
      ranks   <- 1:n
      pop     <- 10000 / ranks^alpha
      head_n  <- sum(pop > sum(pop) * 0.8 / n)  # approx head count
      data.frame(rank = ranks, popularity = pop,
                 zone = ifelse(ranks <= round(n * 0.1), "Head", "Tail"))
    }, ignoreNULL = FALSE)

    output$longtail_interactive <- renderPlotly({
      df    <- longtail_data()
      alpha <- input$alpha

      plot_ly(df, x = ~rank, y = ~popularity, color = ~zone,
              colors  = c(Head = "#00A39A", Tail = "#3b82f6"),
              type    = "scatter", mode = "lines",
              fill    = "tozeroy",
              fillcolor = "rgba(0,163,154,0.15)",
              hovertemplate = "Rank %{x}: %{y:.0f} views<extra></extra>") %>%
        layout(
          title  = list(text = paste0("Power Law Distribution (α = ", alpha, ")"),
                        font = list(color = "#d0f0ed", size = 13)),
          xaxis  = list(title = "Item Rank (by popularity)", color = "#8a9bb0",
                        gridcolor = "rgba(255,255,255,0.08)"),
          yaxis  = list(title = "Estimated Views", color = "#8a9bb0",
                        gridcolor = "rgba(255,255,255,0.08)"),
          legend = list(font = list(color = "#8a9bb0"))
        ) %>%
        plotly_dark_theme()
    })

    output$longtail_stats <- renderUI({
      df        <- longtail_data()
      total     <- sum(df$popularity)
      head_pct  <- round(sum(df$popularity[df$zone == "Head"]) / total * 100, 1)
      tail_pct  <- 100 - head_pct
      n_head    <- sum(df$zone == "Head")

      tagList(
        tags$p(HTML(paste0("<strong>Top 10% items (", n_head, ")</strong> account for:")),
               style = "font-size:12px; color:#546e7a; margin-bottom:6px;"),
        div(class = "stat-highlight", paste0(head_pct, "%")),
        tags$p(paste0("of all views — remaining ", tail_pct, "% from tail"),
               style = "font-size:11px; color:#546e7a; margin-top:4px;")
      )
    })

    # ── Code Lab: RMSE Calculator ───────────────────────────
    rmse_result_val <- eventReactive(input$calc_rmse, {
      base <- input$rmse_base
      impr <- input$rmse_improved
      pct  <- (base - impr) / base * 100
      list(base = base, improved = impr, pct = round(pct, 4),
           won = pct >= 10)
    }, ignoreNULL = FALSE)

    output$rmse_result <- renderUI({
      r <- rmse_result_val()
      colour <- if (r$won) "#008A82" else "#e67e22"
      icon_s <- if (r$won) "🏆" else "📈"
      msg    <- if (r$won)
        "Netflix Prize threshold reached!"
      else
        paste0("Need ", round(10 - r$pct, 3), "% more to win")

      div(class = "result-card",
          tags$h5(paste(icon_s, "RMSE Improvement Result")),
          fluidRow(
            column(4, div(class = "metric-card", style = paste0("background:", colour),
                          span(class = "metric-value", paste0(r$pct, "%")),
                          span(class = "metric-label", "RMSE Improvement"))),
            column(4, div(class = "metric-card",
                          span(class = "metric-value", r$base),
                          span(class = "metric-label", "Baseline RMSE"))),
            column(4, div(class = "metric-card",
                          span(class = "metric-value", r$improved),
                          span(class = "metric-label", "Improved RMSE")))
          ),
          br(),
          div(class = if (r$won) "success-box" else "warn-box",
              HTML(paste0("<strong>", msg, "</strong>")))
      )
    })

    # ── Code Lab: Rec Type Toy Demo ─────────────────────────
    toy_ratings <- matrix(
      c(5,4,NA,2,NA,
        4,NA,3,NA,1,
        NA,5,4,NA,3,
        2,NA,NA,4,5,
        NA,3,5,2,NA),
      nrow = 5, byrow = TRUE,
      dimnames = list(paste0("User ", 1:5),
                      c("Matrix","Inception","Interstellar","Titanic","Die Hard"))
    )

    output$toy_matrix <- renderDT({
      df <- as.data.frame(toy_ratings)
      df[is.na(df)] <- "—"
      datatable(df, options = list(dom = "t", ordering = FALSE, pageLength = 5),
                rownames = TRUE) %>%
        formatStyle(columns = 1:5,
                    backgroundColor = styleEqual("—", "#f9f9f9"),
                    color           = styleEqual("—", "#cccccc"))
    })

    rec_result <- eventReactive(input$run_rectypes, {
      strategy <- input$rec_type

      if (strategy == "popular") {
        # Count non-NA per column = rating count
        counts <- colSums(!is.na(toy_ratings))
        recs   <- sort(counts, decreasing = TRUE)
        # Exclude items User 1 already rated
        seen   <- !is.na(toy_ratings[1, ])
        recs   <- recs[!seen[names(recs)]]
        method <- "Most rated by all users (excluding already seen)"

      } else if (strategy == "random") {
        unseen <- names(which(is.na(toy_ratings[1, ])))
        recs   <- setNames(rep(NA_real_, length(unseen)), sample(unseen))
        method <- "Random shuffle of unseen items (no personalisation)"

      } else {
        # Naive user-based CF: find most similar user by overlap
        u1     <- toy_ratings[1, ]
        sims   <- sapply(2:5, function(i) {
          u2   <- toy_ratings[i, ]
          both <- !is.na(u1) & !is.na(u2)
          if (sum(both) == 0) return(0)
          cor(as.numeric(u1[both]), as.numeric(u2[both]), method = "pearson")
        })
        best_u <- which.max(sims) + 1        # +1 because we started at 2
        nbr    <- toy_ratings[best_u, ]
        unseen_by_u1 <- is.na(u1)
        recs   <- sort(nbr[unseen_by_u1], decreasing = TRUE, na.last = NA)
        method <- paste0("Items rated highly by User ", best_u,
                         " (Pearson sim = ", round(max(sims), 2), ")")
      }

      list(recs = recs, method = method, strategy = strategy)
    }, ignoreNULL = FALSE)

    output$rec_type_result <- renderUI({
      r <- rec_result()
      if (length(r$recs) == 0) {
        return(div(class = "warn-box", HTML("<strong>No recommendations available.</strong>")))
      }

      rows <- lapply(seq_along(r$recs), function(i) {
        score_txt <- if (is.na(r$recs[i])) "—" else as.character(r$recs[i])
        tags$tr(
          tags$td(paste0("#", i)),
          tags$td(names(r$recs)[i]),
          tags$td(score_txt)
        )
      })

      div(class = "result-card",
          tags$h5(paste0("Recommendations for User 1 · ", r$strategy)),
          tags$p(style = "font-size:11.5px; color:#546e7a; margin-bottom:10px;",
                 r$method),
          tags$table(class = "algo-table",
                     tags$thead(tags$tr(tags$th("Rank"), tags$th("Movie"),
                                        tags$th("Score"))),
                     tags$tbody(rows)
          )
      )
    })

  })
}
