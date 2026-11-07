# modules/chapter5.R
# Chapter 5: Non-Personalized Recommendations
# Theory + Code Lab: PopularityBasedRecs, Bayesian average, trending, seeded recs
# Mirrors: recs/popularity_recommender.py

chapter5_ui <- function(id) {
  ns <- NS(id)
  tagList(

    div(class = "meta-hero",
        tags$h1("Chapter 5: Non-Personalized Recommendations"),
        tags$h2("Popularity, Bayesian Average, Trending, and Seeded Recommenders"),
        div(
          span(class = "hero-badge", "Popularity"),
          span(class = "hero-badge", "Bayesian Average"),
          span(class = "hero-badge", "Trending"),
          span(class = "hero-badge", "popularity_recommender.py")
        )
    ),

    fluidRow(
      box(title = "🎯 Chapter Overview", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, div(class = "metric-card", span(class = "metric-value", "Simple"),
                          span(class = "metric-label", "No User Profile Needed"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "Baseline"),
                          span(class = "metric-label", "Hard to Beat"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "Cold"),
                          span(class = "metric-label", "Solves Cold-Start"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "4"),
                          span(class = "metric-label", "Strategies Implemented")))
          )
      )
    ),

    fluidRow(
      tabBox(width = 12, id = ns("ch5_tabs"),

        # ── THEORY ─────────────────────────────────────────
        tabPanel(title = tagList(icon("book"), " Theory"),
          fluidRow(
            box(title = "📢 Why Non-Personalized Recs Matter", status = "info",
                solidHeader = TRUE, width = 6,
                div(class = "success-box",
                    HTML("<strong>✅ Never underestimate the baseline.</strong> Popularity-based recs
                    outperform sophisticated algorithms in cold-start situations and work perfectly
                    when you have no user history at all.")),
                br(),
                div(class = "framework-card",
                    tags$h5("When to Use"),
                    tags$ul(
                      tags$li(HTML("<strong>New users:</strong> No interaction history yet")),
                      tags$li(HTML("<strong>Anonymous visitors:</strong> No login, no profile")),
                      tags$li(HTML("<strong>Homepage:</strong> Before any preference is expressed")),
                      tags$li(HTML("<strong>A/B test baseline:</strong> What is personalisation beating?"))
                    )
                ),
                br(),
                div(class = "framework-card",
                    tags$h5("Types of Non-Personalized Recs"),
                    tags$p(HTML("<strong>1. Most Popular:</strong> Rank by rating count")),
                    tags$p(HTML("<strong>2. Highest Rated:</strong> Rank by average rating")),
                    tags$p(HTML("<strong>3. Bayesian Average:</strong> Balance popularity + rating")),
                    tags$p(HTML("<strong>4. Trending:</strong> Recency-weighted popularity")),
                    tags$p(HTML("<strong>5. Seeded:</strong> 'Users who bought X also bought Y'"))
                )
            ),
            box(title = "🐍 MovieGEEK: popularity_recommender.py", status = "warning",
                solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("recommend_items(user_id)"),
                    tags$p("Groups ratings by movie_id, counts unique raters, returns top-N sorted by count.
                           Excludes items already rated by the target user.")
                ),
                div(class = "framework-card",
                    tags$h5("predict_score(user_id, item_id)"),
                    tags$p("Returns avg rating for item from ALL OTHER users.
                           Same prediction regardless of user identity — truly non-personalized.")
                ),
                div(class = "framework-card",
                    tags$h5("recommend_items_from_log(num)"),
                    tags$p("Uses Log table (event='buy') not ratings. Counts purchases per item.
                           Returns most-purchased items — mirrors Ch 6 seeded recs.")
                ),
                br(),
                div(class = "tip-box",
                    HTML("<strong>💡 Bayesian Average Problem:</strong> 1 rating of 5★ ranks above
                    1000 ratings averaging 4.8★. Bayesian average pulls low-count items toward the
                    global mean, fixing this."))
            )
          ),
          fluidRow(
            box(title = "🧮 Bayesian Average Formula", status = "success",
                solidHeader = TRUE, width = 12,
                fluidRow(
                  column(6,
                    div(class = "framework-card",
                        tags$h5("Formula"),
                        tags$p(HTML("<strong>Bayesian avg = (C × m + Σr) / (C + n)</strong>")),
                        tags$p(HTML("<strong>C:</strong> Confidence weight (≈ avg number of ratings per item)")),
                        tags$p(HTML("<strong>m:</strong> Global mean rating")),
                        tags$p(HTML("<strong>n:</strong> Number of ratings for this item")),
                        tags$p(HTML("<strong>Σr:</strong> Sum of ratings for this item")),
                        br(),
                        tags$p("When n is small → result ≈ m (global mean). As n grows → result ≈ true average.")
                    )
                  ),
                  column(6,
                    div(class = "framework-card",
                        tags$h5("Used By"),
                        tags$ul(
                          tags$li("IMDb Top 250"),
                          tags$li("Rotten Tomatoes Tomatometer"),
                          tags$li("Goodreads ratings"),
                          tags$li("Steam game scores")
                        )
                    )
                  )
                )
            )
          )
        ), # end Theory

        # ── CODE LAB ───────────────────────────────────────
        tabPanel(title = tagList(icon("code"), " Code Lab"),

          code_lab_header(
            title    = "PopularityBasedRecs — R Implementation",
            subtitle = "Full mirror of popularity_recommender.py. Four strategies: most popular, highest rated, Bayesian average, trending. Compare them side-by-side.",
            badges   = c("R", "dplyr", "mirrors: popularity_recommender.py")
          ),

          fluidRow(
            box(title = "⚙️ Configuration", status = "primary",
                solidHeader = TRUE, width = 4,
                div(class = "control-panel",
                    div(class = "section-heading-dark", "Settings"),
                    sliderInput(ns("top_n"), "Top-N recommendations",
                                min = 3, max = 20, value = 10, step = 1),
                    numericInput(ns("target_user"), "Target user ID (exclude their ratings)",
                                 value = 1, min = 1, max = 50),
                    br(),
                    div(class = "section-heading-dark", "Bayesian Average"),
                    sliderInput(ns("bayes_c"), "Confidence weight (C)",
                                min = 1, max = 50, value = 10, step = 1),
                    br(),
                    div(class = "section-heading-dark", "Trending"),
                    sliderInput(ns("half_life"), "Recency half-life (days)",
                                min = 7, max = 180, value = 30, step = 7),
                    br(),
                    run_button(ns("run_pop"), "▶  Run All Strategies")
                ),
                br(),
                r_code_block(
'# popularity_recommender.py in R

m <- mean(sample_ratings$rating)
C <- 10  # confidence weight

pop_recs <- sample_ratings %>%
  filter(user_id != target_user) %>%
  group_by(movie_id) %>%
  summarise(
    n_ratings  = n(),
    avg_rating = mean(rating)
  ) %>%
  mutate(
    # Bayesian average
    bayes_avg = (C*m + avg_rating*n_ratings) /
                (C + n_ratings),
    # Trending: exponential decay
    trending_score = sum(
      rating * 0.5^(age_days/half_life)
    )
  )'
                )
            ),

            box(title = "📊 Strategy Comparison", status = "success",
                solidHeader = TRUE, width = 8,
                fluidRow(
                  column(3, div(class = "metric-card",
                                span(class = "metric-value",
                                     textOutput(ns("m_global_mean"), inline = TRUE)),
                                span(class = "metric-label", "Global Mean"))),
                  column(3, div(class = "metric-card",
                                span(class = "metric-value",
                                     textOutput(ns("m_n_items"), inline = TRUE)),
                                span(class = "metric-label", "Eligible Items"))),
                  column(3, div(class = "metric-card",
                                span(class = "metric-value",
                                     textOutput(ns("m_max_pop"), inline = TRUE)),
                                span(class = "metric-label", "Max Rater Count"))),
                  column(3, div(class = "metric-card",
                                span(class = "metric-value",
                                     textOutput(ns("m_overlap"), inline = TRUE)),
                                span(class = "metric-label", "Top-10 Rank Agreement")))
                ),
                br(),
                div(class = "section-heading-dark",
                    "Ranked by Bayesian Average — all four rank columns shown"),
                DTOutput(ns("comparison_table"))
            )
          ),

          fluidRow(
            box(title = "🔥 Popularity vs Quality Scatter", status = "warning",
                solidHeader = TRUE, width = 6,
                div(class = "tip-box",
                    HTML("<strong>Reading the chart:</strong> Items in the top-right corner are both
                    popular AND highly rated. Colour = Bayesian average. Bottom-right = popular but divisive.")),
                plotlyOutput(ns("pop_vs_rated_plot"))
            ),
            box(title = "⚖️ Bayesian Average Shrinkage Effect", status = "info",
                solidHeader = TRUE, width = 6,
                div(class = "tip-box",
                    HTML("<strong>Watch:</strong> Low-count items get pulled toward the global mean (dashed line).
                    Items with many ratings are barely affected.")),
                plotlyOutput(ns("bayes_effect_plot"))
            )
          ),

          fluidRow(
            box(title = "📈 Trending: Recency-Weighted Popularity", status = "primary",
                solidHeader = TRUE, width = 6,
                plotlyOutput(ns("trending_plot")),
                br(),
                r_code_block(
'# Trending score: exponential decay

trending <- sample_ratings %>%
  filter(user_id != target) %>%
  mutate(
    age_days = as.numeric(difftime(
      Sys.time(),
      as.POSIXct(timestamp,
                 origin="1970-01-01"),
      units = "days")),
    decay    = 0.5^(age_days / half_life),
    w_rating = rating * decay
  ) %>%
  group_by(movie_id) %>%
  summarise(score = sum(w_rating)) %>%
  arrange(desc(score))'
                )
            ),
            box(title = "🛒 Seeded Recs from Purchase Log", status = "success",
                solidHeader = TRUE, width = 6,
                div(class = "info-box-plain",
                    HTML("<strong>Mirrors recommend_items_from_log():</strong>
                    Uses buy events from the event log. Most purchased items that
                    this user hasn't bought yet.")),
                div(class = "control-panel",
                    numericInput(ns("seed_user"), "User ID for seeded recs",
                                 value = 1, min = 1, max = 50),
                    run_button(ns("run_seeded"), "▶  Get Seeded Recs")
                ),
                uiOutput(ns("seeded_result")),
                br(),
                r_code_block(
'# recommend_items_from_log() in R

user_bought <- sample_events %>%
  filter(user_id == uid,
         event == "buy") %>%
  pull(content_id)

seeded <- sample_events %>%
  filter(event == "buy",
         !content_id %in% user_bought) %>%
  count(content_id,
        name = "buy_count") %>%
  arrange(desc(buy_count))'
                )
            )
          )
        ) # end Code Lab
      )
    )
  )
}

chapter5_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    pop_data <- eventReactive(input$run_pop, {
      target <- input$target_user
      C      <- input$bayes_c
      hl     <- input$half_life
      m      <- mean(sample_ratings$rating)

      base <- sample_ratings %>%
        filter(user_id != target) %>%
        group_by(movie_id) %>%
        summarise(n_ratings  = n(),
                  avg_rating = round(mean(rating), 3),
                  .groups    = "drop")

      bayes_df <- base %>%
        mutate(bayes_avg = round((C * m + avg_rating * n_ratings) /
                                   (C + n_ratings), 3))

      trending_df <- sample_ratings %>%
        filter(user_id != target) %>%
        mutate(
          age_days = as.numeric(difftime(
            Sys.time(),
            as.POSIXct(timestamp, origin = "1970-01-01"),
            units = "days")),
          decay    = 0.5 ^ (age_days / hl),
          w_rating = rating * decay
        ) %>%
        group_by(movie_id) %>%
        summarise(trending_score = round(sum(w_rating), 3), .groups = "drop")

      combined <- bayes_df %>%
        left_join(trending_df, by = "movie_id") %>%
        left_join(sample_movies %>% select(movie_id, title, genre), by = "movie_id") %>%
        mutate(
          rank_popular  = rank(-n_ratings,       ties.method = "first"),
          rank_rated    = rank(-avg_rating,       ties.method = "first"),
          rank_bayes    = rank(-bayes_avg,        ties.method = "first"),
          rank_trending = rank(-trending_score,   ties.method = "first")
        )

      list(df = combined, m = m)
    }, ignoreNULL = FALSE)

    output$m_global_mean <- renderText(round(pop_data()$m, 3))
    output$m_n_items     <- renderText(nrow(pop_data()$df))
    output$m_max_pop     <- renderText(max(pop_data()$df$n_ratings))
    output$m_overlap     <- renderText({
      df   <- pop_data()$df %>% arrange(rank_popular) %>% head(10)
      hits <- sum(df$rank_bayes <= 10)
      paste0(hits, "/10")
    })

    output$comparison_table <- renderDT({
      df <- pop_data()$df %>%
        arrange(rank_bayes) %>%
        head(input$top_n) %>%
        select(Title = title, Genre = genre,
               `# Ratings` = n_ratings, `Avg` = avg_rating,
               `Bayes Avg` = bayes_avg, `Trending` = trending_score,
               `Rk Pop` = rank_popular, `Rk Avg` = rank_rated,
               `Rk Bayes` = rank_bayes, `Rk Trend` = rank_trending)
      datatable(df, options = list(pageLength = input$top_n, scrollX = TRUE,
                                   dom = "t"), rownames = FALSE) %>%
        formatStyle("Rk Bayes",
                    background = styleColorBar(c(1, input$top_n), "#00A39A"),
                    backgroundSize = "95% 55%", backgroundRepeat = "no-repeat",
                    backgroundPosition = "center")
    })

    output$pop_vs_rated_plot <- renderPlotly({
      df <- pop_data()$df
      plot_ly(df, x = ~n_ratings, y = ~avg_rating, text = ~title,
              type = "scatter", mode = "markers",
              marker = list(color = ~bayes_avg,
                            colorscale = list(c(0,"#b2dfdb"), c(1,"#008A82")),
                            showscale = TRUE,
                            colorbar = list(title = "Bayes", tickfont = list(color="#8a9bb0")),
                            size = 9, opacity = 0.85),
              hovertemplate = "<b>%{text}</b><br>Ratings: %{x}<br>Avg: %{y:.2f}<extra></extra>") %>%
        layout(title = list(text = "Popularity vs Quality",
                            font = list(color="#d0f0ed",size=13)),
               xaxis = list(title="# Ratings",color="#8a9bb0",gridcolor="rgba(255,255,255,0.08)"),
               yaxis = list(title="Avg Rating",color="#8a9bb0",gridcolor="rgba(255,255,255,0.08)")) %>%
        plotly_dark_theme()
    })

    output$bayes_effect_plot <- renderPlotly({
      df <- pop_data()$df %>% arrange(n_ratings) %>% head(20)
      m  <- pop_data()$m
      plot_ly(df, x = ~reorder(title, n_ratings)) %>%
        add_trace(y = ~avg_rating, type = "bar", name = "Simple Avg",
                  marker = list(color = "rgba(59,130,246,0.7)")) %>%
        add_trace(y = ~bayes_avg,  type = "bar", name = "Bayesian Avg",
                  marker = list(color = "rgba(0,163,154,0.85)")) %>%
        add_trace(y = rep(m, nrow(df)), type = "scatter", mode = "lines",
                  name = "Global Mean",
                  line = list(color = "#fbbf24", dash = "dash", width = 2)) %>%
        layout(barmode = "group",
               title = list(text="Bayesian Shrinkage: Low-Count → Global Mean",
                            font=list(color="#d0f0ed",size=13)),
               xaxis = list(title="",color="#8a9bb0",tickangle=-35),
               yaxis = list(title="Rating",color="#8a9bb0",gridcolor="rgba(255,255,255,0.08)"),
               legend = list(font=list(color="#8a9bb0"))) %>%
        plotly_dark_theme()
    })

    output$trending_plot <- renderPlotly({
      df <- pop_data()$df %>% arrange(rank_trending) %>% head(15)
      plot_ly(df, x = ~reorder(title, trending_score), y = ~trending_score, type = "bar",
              marker = list(color = ~trending_score,
                            colorscale = list(c(0,"#b2dfdb"),c(1,"#e8410a"))),
              hovertemplate = "<b>%{x}</b><br>Score: %{y:.2f}<extra></extra>") %>%
        layout(title = list(text = paste0("Trending (half-life=",input$half_life,"d)"),
                            font = list(color="#d0f0ed",size=13)),
               xaxis = list(title="",color="#8a9bb0",tickangle=-35),
               yaxis = list(title="Trending Score",color="#8a9bb0",
                            gridcolor="rgba(255,255,255,0.08)")) %>%
        plotly_dark_theme()
    })

    seeded_result <- eventReactive(input$run_seeded, {
      uid       <- input$seed_user
      user_buys <- sample_events %>%
        filter(user_id == uid, event == "buy") %>%
        pull(content_id) %>% unique()
      recs <- sample_events %>%
        filter(event == "buy", !content_id %in% user_buys) %>%
        count(content_id, name = "buy_count") %>%
        arrange(desc(buy_count)) %>%
        head(10) %>%
        left_join(sample_movies %>% select(movie_id, title, genre),
                  by = c("content_id" = "movie_id"))
      list(recs = recs, uid = uid, n_bought = length(user_buys))
    }, ignoreNULL = FALSE)

    output$seeded_result <- renderUI({
      r <- seeded_result()
      if (nrow(r$recs) == 0)
        return(div(class="warn-box", HTML("<strong>No purchase data for this user.</strong>")))
      rows <- lapply(seq_len(nrow(r$recs)), function(i)
        tags$tr(tags$td(paste0("#",i)), tags$td(r$recs$title[i]),
                tags$td(r$recs$genre[i]), tags$td(r$recs$buy_count[i])))
      div(class="result-card",
          tags$h5(paste0("Seeded Recs — User ",r$uid," (bought ",r$n_bought," items)")),
          tags$table(class="algo-table",
                     tags$thead(tags$tr(tags$th("#"),tags$th("Movie"),
                                        tags$th("Genre"),tags$th("Buy Count"))),
                     tags$tbody(rows)))
    })
  })
}
