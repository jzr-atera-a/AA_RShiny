# modules/chapter4.R
# Chapter 4: Ratings and How to Calculate Them
# Theory + Code Lab: Full implicit rating pipeline mirroring MovieGEEK

chapter4_ui <- function(id) {
  ns <- NS(id)
  tagList(

    div(class = "meta-hero",
        tags$h1("Chapter 4: Ratings and How to Calculate Them"),
        tags$h2("Transforming Raw Events into Usable Implicit Ratings"),
        div(
          span(class = "hero-badge", "Implicit Ratings"),
          span(class = "hero-badge", "Event Weighting"),
          span(class = "hero-badge", "Normalisation"),
          span(class = "hero-badge", "implicit_ratings_calculator.py")
        )
    ),

    fluidRow(
      box(title = "🎯 Chapter Overview", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, div(class = "metric-card", span(class = "metric-value", "1–10"),
                          span(class = "metric-label", "Normalised Rating Scale"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "5"),
                          span(class = "metric-label", "Event Types Weighted"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "SGD"),
                          span(class = "metric-label", "Uses in Matrix Factorization"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "Key"),
                          span(class = "metric-label", "Foundation for All Algos")))
          )
      )
    ),

    fluidRow(
      tabBox(
        width = 12, id = ns("ch4_tabs"),

        # ─────────────────────────────────────────────────────
        # THEORY TAB
        # ─────────────────────────────────────────────────────
        tabPanel(
          title = tagList(icon("book"), " Theory"),

          fluidRow(
            box(title = "⭐ Types of Ratings", status = "info",
                solidHeader = TRUE, width = 6,
                div(class = "section-heading-dark", "Explicit vs Implicit Ratings"),
                div(class = "framework-card",
                    tags$h5("Explicit Ratings"),
                    tags$p(HTML("<strong>Format:</strong> 1–5 stars, thumbs up/down")),
                    tags$p(HTML("<strong>Source:</strong> Direct user input")),
                    tags$p(HTML("<strong>Availability:</strong> Rare — only ~5% of users rate")),
                    tags$p(HTML("<strong>Noise:</strong> Low — user meant to give this rating"))
                ),
                br(),
                div(class = "framework-card",
                    tags$h5("Implicit Ratings"),
                    tags$p(HTML("<strong>Format:</strong> Derived from behaviour (view, buy, etc.)")),
                    tags$p(HTML("<strong>Source:</strong> Passive observation")),
                    tags$p(HTML("<strong>Availability:</strong> Abundant — 100% of interactions")),
                    tags$p(HTML("<strong>Noise:</strong> Higher — buy ≠ liked"))
                ),
                br(),
                div(class = "tip-box",
                    HTML("<strong>💡 MovieGEEK Approach:</strong> Uses explicit star ratings where available,
                    falls back to implicit ratings computed from the event log."))
            ),

            box(title = "🧮 The Rating Calculation Pipeline", status = "warning",
                solidHeader = TRUE, width = 6,
                div(class = "section-heading-dark",
                    "How implicit_ratings_calculator.py Works"),
                div(class = "framework-card",
                    tags$h5("Step 1: Collect Events"),
                    tags$p("Read all events from the Log table for a user-item pair.")
                ),
                div(class = "framework-card",
                    tags$h5("Step 2: Apply Weights"),
                    tags$p(HTML("Assign a numeric weight to each event:<br>
                    buy=5, addtocart=3, details=2, view=1, search=0.5"))
                ),
                div(class = "framework-card",
                    tags$h5("Step 3: Aggregate"),
                    tags$p("Sum weights per user-item pair to get a raw score.")
                ),
                div(class = "framework-card",
                    tags$h5("Step 4: Normalise"),
                    tags$p("Scale to 1–10 range across all user-item pairs.")
                ),
                div(class = "framework-card",
                    tags$h5("Step 5: Store"),
                    tags$p("Save as Rating objects alongside explicit ratings.")
                )
            )
          ),

          fluidRow(
            box(title = "📉 Rating Distribution Analysis", status = "success",
                solidHeader = TRUE, width = 12,
                div(class = "success-box",
                    HTML("<strong>✅ Key Insight:</strong> Explicit ratings follow a J-curve (most people give high ratings).
                    Implicit ratings follow a power law (most interactions are passive views).
                    Understanding this distribution is critical for choosing your algorithm.")),
                br(),
                plotlyOutput(ns("rating_dist_theory"))
            )
          )
        ), # end Theory

        # ─────────────────────────────────────────────────────
        # CODE LAB TAB
        # ─────────────────────────────────────────────────────
        tabPanel(
          title = tagList(icon("code"), " Code Lab"),

          code_lab_header(
            title    = "Implicit Rating Calculator",
            subtitle = paste0(
              "Full R implementation of MovieGEEK's implicit_ratings_calculator.py. ",
              "Edit event weights, run the pipeline on the built-in event log, inspect results."
            ),
            badges   = c("R", "dplyr", "mirrors: implicit_ratings_calculator.py")
          ),

          # ── Section 1: Weight editor + run ────────────────
          fluidRow(
            box(title = "⚖️ Event Weights Editor", status = "primary",
                solidHeader = TRUE, width = 5,
                div(class = "section-heading-dark",
                    "Adjust weights — exactly as in MovieGEEK's EVENT_WEIGHTS dict"),
                div(class = "info-box-plain",
                    HTML("<strong>MovieGEEK Python:</strong><br>
                    <code>EVENT_WEIGHTS = {'buy':5, 'addtocart':3, 'details':2, 'view':1, 'search':0.5}</code>")),
                br(),
                div(class = "control-panel",
                    numericInput(ns("w_buy"),       "buy  weight",       value = 5,   min = 0, max = 20, step = 0.5),
                    numericInput(ns("w_addtocart"), "addtocart weight",  value = 3,   min = 0, max = 20, step = 0.5),
                    numericInput(ns("w_details"),   "details weight",    value = 2,   min = 0, max = 20, step = 0.5),
                    numericInput(ns("w_view"),      "view weight",       value = 1,   min = 0, max = 20, step = 0.5),
                    numericInput(ns("w_search"),    "search weight",     value = 0.5, min = 0, max = 20, step = 0.5),
                    br(),
                    div(class = "section-heading-dark", "Normalisation Range"),
                    fluidRow(
                      column(6, numericInput(ns("norm_min"), "Min rating", value = 1, min = 0, max = 5)),
                      column(6, numericInput(ns("norm_max"), "Max rating", value = 10, min = 5, max = 20))
                    ),
                    br(),
                    run_button(ns("run_implicit"), "▶  Calculate Implicit Ratings")
                ),
                br(),
                r_code_block(
'# R implementation of implicit_ratings_calculator.py

event_weights <- c(
  buy       = 5,
  addtocart = 3,
  details   = 2,
  view      = 1,
  search    = 0.5
)

# Step 1+2: Apply weights
weighted <- sample_events %>%
  mutate(weight = event_weights[event]) %>%
  filter(!is.na(weight))

# Step 3: Aggregate by user-item
raw_scores <- weighted %>%
  group_by(user_id, content_id) %>%
  summarise(raw_score = sum(weight), .groups="drop")

# Step 4: Normalise to 1-10 scale
max_s <- max(raw_scores$raw_score)
min_s <- min(raw_scores$raw_score)

implicit_ratings <- raw_scores %>%
  mutate(
    rating = (raw_score - min_s) /
             (max_s - min_s) * 9 + 1,
    rating = round(rating, 2)
  )'
                )
            ),

            box(title = "📊 Implicit Rating Results", status = "success",
                solidHeader = TRUE, width = 7,
                div(class = "section-heading-dark", "Computed Ratings"),
                fluidRow(
                  column(4, div(class = "metric-card",
                                span(class = "metric-value",
                                     textOutput(ns("n_pairs"), inline=TRUE)),
                                span(class = "metric-label", "User-Item Pairs"))),
                  column(4, div(class = "metric-card",
                                span(class = "metric-value",
                                     textOutput(ns("avg_rating"), inline=TRUE)),
                                span(class = "metric-label", "Avg Implicit Rating"))),
                  column(4, div(class = "metric-card",
                                span(class = "metric-value",
                                     textOutput(ns("coverage_pct"), inline=TRUE)),
                                span(class = "metric-label", "User-Item Coverage")))
                ),
                br(),
                DTOutput(ns("implicit_table"))
            )
          ),

          # ── Section 2: Distribution plots ─────────────────
          fluidRow(
            box(title = "📈 Implicit Rating Distribution", status = "warning",
                solidHeader = TRUE, width = 6,
                plotlyOutput(ns("implicit_dist_plot"))
            ),

            box(title = "🔗 Explicit vs Implicit Comparison", status = "info",
                solidHeader = TRUE, width = 6,
                div(class = "tip-box",
                    HTML("<strong>💡 Expected Difference:</strong> Explicit ratings cluster at 4-5 (positivity bias).
                    Implicit ratings are right-skewed — most interactions are low-signal views.")),
                plotlyOutput(ns("explicit_vs_implicit_plot"))
            )
          ),

          # ── Section 3: Heatmap ─────────────────────────────
          fluidRow(
            box(title = "🗺️ User–Item Implicit Rating Heatmap", status = "primary",
                solidHeader = TRUE, width = 12,
                div(class = "section-heading-dark",
                    "Top 15 Users × Top 15 Movies by Event Count"),
                div(class = "info-box-plain",
                    HTML("<strong>Reading the map:</strong> Dark teal = high implicit rating (many strong interactions).
                    White = no interaction recorded. Sparsity is normal and expected.")),
                plotlyOutput(ns("rating_heatmap"), height = "420px")
            )
          ),

          # ── Section 4: Raw event inspector ────────────────
          fluidRow(
            box(title = "🔍 Trace a Single User-Item Pair", status = "success",
                solidHeader = TRUE, width = 12,
                div(class = "section-heading-dark",
                    "See exactly how the rating is computed — full audit trail"),
                div(class = "control-panel",
                    fluidRow(
                      column(4, numericInput(ns("trace_user"),  "User ID",  value = 1, min=1, max=50)),
                      column(4, numericInput(ns("trace_item"),  "Movie ID", value = 1, min=1, max=30)),
                      column(4, br(), run_button(ns("run_trace"), "▶  Trace Calculation"))
                    )
                ),
                uiOutput(ns("trace_output"))
            )
          )
        ) # end Code Lab
      )
    )
  )
}

chapter4_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # ── Theory plot ──────────────────────────────────────────
    output$rating_dist_theory <- renderPlotly({
      explicit_sim <- c(sample(1:2, 30,  replace=TRUE),
                        sample(3:3, 50,  replace=TRUE),
                        sample(4:4, 120, replace=TRUE),
                        sample(5:5, 200, replace=TRUE))
      impl_sim <- round(1 + rexp(400, 0.4) * 2.5)
      impl_sim <- pmin(impl_sim, 10)

      df_exp <- data.frame(rating = explicit_sim, type = "Explicit (1-5 stars)")
      df_imp <- data.frame(rating = impl_sim,     type = "Implicit (1-10 normalised)")

      df <- rbind(
        df_exp %>% mutate(rating = rating * 2),  # scale to 1-10
        df_imp
      )

      plot_ly(df, x = ~rating, color = ~type,
              colors  = c("Explicit (1-5 stars)" = "#00A39A",
                          "Implicit (1-10 normalised)" = "#3b82f6"),
              type    = "histogram", nbinsx = 10, opacity = 0.75,
              hovertemplate = "Rating %{x}: %{y} users<extra></extra>") %>%
        layout(
          barmode = "overlay",
          title   = list(text = "Explicit vs Implicit Rating Distributions",
                         font = list(color = "#d0f0ed", size = 13)),
          xaxis   = list(title = "Rating Value", color = "#8a9bb0",
                         gridcolor = "rgba(255,255,255,0.08)"),
          yaxis   = list(title = "Count", color = "#8a9bb0",
                         gridcolor = "rgba(255,255,255,0.08)"),
          legend  = list(font = list(color = "#8a9bb0"))
        ) %>%
        plotly_dark_theme()
    })

    # ── Core implicit rating computation ─────────────────────
    implicit_data <- eventReactive(input$run_implicit, {
      weights <- c(
        buy       = input$w_buy,
        addtocart = input$w_addtocart,
        details   = input$w_details,
        view      = input$w_view,
        search    = input$w_search
      )
      norm_min <- input$norm_min
      norm_max <- input$norm_max
      range_   <- norm_max - norm_min

      weighted <- sample_events %>%
        mutate(weight = weights[event]) %>%
        filter(!is.na(weight))

      raw_scores <- weighted %>%
        group_by(user_id, content_id) %>%
        summarise(
          raw_score   = sum(weight),
          n_events    = n(),
          event_types = paste(sort(unique(event)), collapse = ", "),
          .groups     = "drop"
        )

      max_s <- max(raw_scores$raw_score)
      min_s <- min(raw_scores$raw_score)

      result <- raw_scores %>%
        mutate(
          rating = if (max_s == min_s) norm_min
          else (raw_score - min_s) / (max_s - min_s) * range_ + norm_min,
          rating = round(rating, 2)
        ) %>%
        left_join(
          sample_movies %>% select(movie_id, title),
          by = c("content_id" = "movie_id")
        ) %>%
        arrange(desc(rating))

      result
    }, ignoreNULL = FALSE)

    output$n_pairs      <- renderText(nrow(implicit_data()))
    output$avg_rating   <- renderText(round(mean(implicit_data()$rating), 2))
    output$coverage_pct <- renderText({
      n <- nrow(implicit_data())
      total <- N_USERS * N_MOVIES
      paste0(round(n / total * 100, 1), "%")
    })

    output$implicit_table <- renderDT({
      df <- implicit_data() %>%
        select(user_id, content_id, title, event_types, raw_score, rating) %>%
        rename(User    = user_id,
               `Movie ID` = content_id,
               Title   = title,
               Events  = event_types,
               `Raw Score` = raw_score,
               Rating  = rating)
      datatable(df,
                options  = list(pageLength = 10, scrollX = TRUE, dom = "frtip"),
                rownames = FALSE) %>%
        formatStyle("Rating",
                    background = styleColorBar(range(df$Rating), "#00A39A"),
                    backgroundSize = "98% 60%",
                    backgroundRepeat = "no-repeat",
                    backgroundPosition = "center")
    })

    # ── Distribution plot ────────────────────────────────────
    output$implicit_dist_plot <- renderPlotly({
      df <- implicit_data()

      plot_ly(df, x = ~rating, type = "histogram",
              nbinsx  = 20,
              marker  = list(color = "#00A39A", line = list(color = "#007a72", width = 1)),
              hovertemplate = "Rating %{x:.1f}: %{y} pairs<extra></extra>") %>%
        layout(
          title  = list(text = "Implicit Rating Distribution",
                        font = list(color = "#d0f0ed", size = 13)),
          xaxis  = list(title = paste0("Rating (", input$norm_min, "–", input$norm_max, ")"),
                        color = "#8a9bb0", gridcolor = "rgba(255,255,255,0.08)"),
          yaxis  = list(title = "Count", color = "#8a9bb0",
                        gridcolor = "rgba(255,255,255,0.08)")
        ) %>%
        plotly_dark_theme()
    })

    # ── Explicit vs implicit comparison ─────────────────────
    output$explicit_vs_implicit_plot <- renderPlotly({
      df_impl <- implicit_data() %>%
        mutate(
          rating_scaled = (rating - input$norm_min) / (input$norm_max - input$norm_min) * 4 + 1,
          type = "Implicit"
        ) %>%
        select(rating = rating_scaled, type)

      df_expl <- sample_ratings %>%
        mutate(type = "Explicit") %>%
        select(rating, type)

      df <- rbind(df_impl, df_expl)

      plot_ly(df, x = ~rating, color = ~type,
              colors = c(Explicit = "#3b82f6", Implicit = "#00A39A"),
              type = "histogram", nbinsx = 10, opacity = 0.75) %>%
        layout(
          barmode = "overlay",
          title   = list(text = "Explicit vs Implicit (scaled to 1–5)",
                         font = list(color = "#d0f0ed", size = 13)),
          xaxis   = list(title = "Rating", color = "#8a9bb0",
                         gridcolor = "rgba(255,255,255,0.08)"),
          yaxis   = list(title = "Count", color = "#8a9bb0",
                         gridcolor = "rgba(255,255,255,0.08)"),
          legend  = list(font = list(color = "#8a9bb0"))
        ) %>%
        plotly_dark_theme()
    })

    # ── Heatmap ──────────────────────────────────────────────
    output$rating_heatmap <- renderPlotly({
      df <- implicit_data()

      # Top 15 users and items by number of ratings
      top_users <- df %>% count(user_id,  sort=TRUE) %>% head(15) %>% pull(user_id)
      top_items <- df %>% count(content_id, sort=TRUE) %>% head(15) %>% pull(content_id)

      heat_df <- df %>%
        filter(user_id %in% top_users, content_id %in% top_items)

      mat <- matrix(NA_real_, nrow=15, ncol=15,
                    dimnames=list(paste0("U",top_users), paste0("M",top_items)))
      for (i in seq_len(nrow(heat_df))) {
        r_nm <- paste0("U", heat_df$user_id[i])
        c_nm <- paste0("M", heat_df$content_id[i])
        if (r_nm %in% rownames(mat) && c_nm %in% colnames(mat))
          mat[r_nm, c_nm] <- heat_df$rating[i]
      }

      plot_ly(
        z         = mat,
        x         = colnames(mat),
        y         = rownames(mat),
        type      = "heatmap",
        colorscale= list(c(0,"#e0f4f2"), c(1,"#008A82")),
        na.action = na.pass,
        colorbar  = list(title = "Rating", tickfont = list(color="#8a9bb0")),
        hovertemplate = "%{y} × %{x}<br>Rating: %{z:.2f}<extra></extra>"
      ) %>%
        layout(
          title  = list(text = "Implicit Rating Heatmap (Top 15 Users × Top 15 Movies)",
                        font = list(color = "#d0f0ed", size = 13)),
          xaxis  = list(title = "Movie", color = "#8a9bb0", tickangle = -30),
          yaxis  = list(title = "User",  color = "#8a9bb0")
        ) %>%
        plotly_dark_theme()
    })

    # ── Trace single user-item calculation ───────────────────
    trace_result <- eventReactive(input$run_trace, {
      uid  <- input$trace_user
      mid  <- input$trace_item

      events_for_pair <- sample_events %>%
        filter(user_id == uid, content_id == mid)

      weights <- c(
        buy       = input$w_buy,
        addtocart = input$w_addtocart,
        details   = input$w_details,
        view      = input$w_view,
        search    = input$w_search
      )

      if (nrow(events_for_pair) == 0) {
        return(list(found = FALSE, uid = uid, mid = mid))
      }

      events_for_pair <- events_for_pair %>%
        mutate(weight = weights[event])

      raw_score <- sum(events_for_pair$weight, na.rm = TRUE)

      # Normalise against full dataset
      all_pairs <- implicit_data()
      max_s <- max(all_pairs$raw_score)
      min_s <- min(all_pairs$raw_score)
      norm_range <- input$norm_max - input$norm_min

      rating <- if (max_s == min_s) input$norm_min
      else (raw_score - min_s) / (max_s - min_s) * norm_range + input$norm_min

      movie_title <- sample_movies$title[sample_movies$movie_id == mid]
      if (length(movie_title) == 0) movie_title <- paste("Movie", mid)

      list(found = TRUE, uid = uid, mid = mid, title = movie_title,
           events = events_for_pair, raw_score = raw_score,
           rating = round(rating, 3))
    }, ignoreNULL = FALSE)

    output$trace_output <- renderUI({
      r <- trace_result()

      if (!r$found) {
        return(div(class = "warn-box",
                   HTML(paste0("<strong>No events found</strong> for User ", r$uid,
                               " × Movie ", r$mid, ".<br>",
                               "This pair has an implicit rating of 0 (no interaction)."))))
      }

      rows <- lapply(seq_len(nrow(r$events)), function(i) {
        ev <- r$events[i, ]
        tags$tr(
          tags$td(as.POSIXct(ev$timestamp, origin = "1970-01-01") %>%
                    format("%Y-%m-%d %H:%M")),
          tags$td(ev$session_id),
          tags$td(tags$strong(ev$event)),
          tags$td(ev$weight)
        )
      })

      tagList(
        div(class = "result-card",
            tags$h5(paste0("Calculation Trace: User ", r$uid,
                           " × ", r$title, " (ID ", r$mid, ")")),
            fluidRow(
              column(4, div(class = "metric-card",
                            span(class = "metric-value", nrow(r$events)),
                            span(class = "metric-label", "Events Found"))),
              column(4, div(class = "metric-card",
                            span(class = "metric-value", round(r$raw_score, 2)),
                            span(class = "metric-label", "Raw Score (Σ weights)"))),
              column(4, div(class = "metric-card",
                            span(class = "metric-value", r$rating),
                            span(class = "metric-label", "Normalised Rating")))
            ),
            br(),
            tags$table(class = "algo-table",
                       tags$thead(tags$tr(
                         tags$th("Timestamp"), tags$th("Session"),
                         tags$th("Event"), tags$th("Weight")
                       )),
                       tags$tbody(rows)
            ),
            br(),
            r_code_block(paste0(
'# Audit trail for User ', r$uid, ' × ', r$title, '
# Raw score = sum of all event weights
# ', paste(paste0(r$events$event, " × ", r$events$weight), collapse = " + "),
' = ', r$raw_score, '
# Normalised: ', r$rating, ' (scale ', input$norm_min, '–', input$norm_max, ')'
            ))
        )
      )
    })

  })
}
