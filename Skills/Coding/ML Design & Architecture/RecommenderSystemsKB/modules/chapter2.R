# modules/chapter2.R
# Chapter 2: User Behavior and How to Collect It
# Theory + Code Lab: Event Log Explorer & Implicit Signal Analyser

chapter2_ui <- function(id) {
  ns <- NS(id)
  tagList(

    div(class = "meta-hero",
        tags$h1("Chapter 2: User Behavior and How to Collect It"),
        tags$h2("Understanding and Capturing Implicit Signals"),
        div(
          span(class = "hero-badge", "Data Collection"),
          span(class = "hero-badge", "Implicit Signals"),
          span(class = "hero-badge", "Event Logs"),
          span(class = "hero-badge", "Session Analysis")
        )
    ),

    fluidRow(
      box(title = "🎯 Chapter Overview", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, div(class = "metric-card", span(class = "metric-value", "2"),
                          span(class = "metric-label", "Signal Types"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "5"),
                          span(class = "metric-label", "Event Types"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "90%"),
                          span(class = "metric-label", "Data is Implicit"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "Key"),
                          span(class = "metric-label", "Cold-Start Solver")))
          )
      )
    ),

    fluidRow(
      tabBox(
        width = 12, id = ns("ch2_tabs"),

        # ─────────────────────────────────────────────────────
        # THEORY TAB
        # ─────────────────────────────────────────────────────
        tabPanel(
          title = tagList(icon("book"), " Theory"),

          fluidRow(
            box(title = "🎯 Types of User Feedback", status = "info",
                solidHeader = TRUE, width = 6,
                div(class = "section-heading-dark", "Explicit vs Implicit Feedback"),
                div(class = "framework-card",
                    tags$h5("Explicit Feedback"),
                    tags$p(HTML("<strong>What it is:</strong> User directly expresses preference")),
                    tags$p(HTML("<strong>Examples:</strong> Star ratings, thumbs up/down, reviews")),
                    tags$p(HTML("<strong>Pros:</strong> Clear signal, easy to interpret")),
                    tags$p(HTML("<strong>Cons:</strong> Rare — only 1-5% of users rate items"))
                ),
                br(),
                div(class = "framework-card",
                    tags$h5("Implicit Feedback"),
                    tags$p(HTML("<strong>What it is:</strong> Inferred from user actions")),
                    tags$p(HTML("<strong>Examples:</strong> Views, clicks, time spent, purchases")),
                    tags$p(HTML("<strong>Pros:</strong> Abundant — 100% of users leave traces")),
                    tags$p(HTML("<strong>Cons:</strong> Noisy, ambiguous (view ≠ liked)"))
                ),
                br(),
                div(class = "success-box",
                    HTML("<strong>✅ Production Reality:</strong> Most RecSys rely predominantly on
                    implicit feedback because explicit ratings are too sparse."))
            ),

            box(title = "📡 What to Collect", status = "warning",
                solidHeader = TRUE, width = 6,
                div(class = "section-heading-dark", "Event Types and Their Signals"),
                tags$table(class = "algo-table",
                           tags$thead(tags$tr(tags$th("Event"), tags$th("Signal Strength"),
                                              tags$th("Example"))),
                           tags$tbody(
                             tags$tr(tags$td("view"),      tags$td("Low (0.5–1)"),  tags$td("Browsed item page")),
                             tags$tr(tags$td("search"),    tags$td("Low (0.5)"),    tags$td("Searched for item")),
                             tags$tr(tags$td("details"),   tags$td("Medium (2)"),   tags$td("Clicked for more info")),
                             tags$tr(tags$td("addtocart"), tags$td("High (3)"),     tags$td("Added to shopping cart")),
                             tags$tr(tags$td("buy"),       tags$td("Highest (5)"),  tags$td("Completed purchase"))
                           )
                ),
                br(),
                div(class = "tip-box",
                    HTML("<strong>💡 MovieGEEK:</strong> The <code>collector</code> app stores each
                    event in the <code>Log</code> model: session_id, user_id, content_id, event, timestamp.")),
                br(),
                div(class = "section-heading-dark", "Session vs User Tracking"),
                div(class = "framework-card",
                    tags$h5("Session-Level Tracking"),
                    tags$p("Group events by session for context. A session = one browsing period."),
                    tags$p(HTML("<strong>Session ID:</strong> Used for association rules (Ch 6)")),
                    tags$p(HTML("<strong>User ID:</strong> For personalised recommendations (Ch 8+)"))
                )
            )
          ),

          fluidRow(
            box(title = "🏗️ The MovieGEEK Data Pipeline", status = "success",
                solidHeader = TRUE, width = 12,
                div(class = "section-heading-dark", "From Raw Events to Recommendations"),
                fluidRow(
                  column(4, div(class = "framework-card",
                                tags$h5("Step 1: Collect"),
                                tags$p("JavaScript collector.js fires events on user actions."),
                                tags$p(HTML("<code>POST /collector/</code> → stored in Log table"))
                  )),
                  column(4, div(class = "framework-card",
                                tags$h5("Step 2: Process"),
                                tags$p("implicit_ratings_calculator.py reads Log, applies weights, normalises to ratings.")
                  )),
                  column(4, div(class = "framework-card",
                                tags$h5("Step 3: Recommend"),
                                tags$p("Algorithms use the processed ratings to generate personalised recommendations.")
                  ))
                ),
                br(),
                div(class = "warn-box",
                    HTML("<strong>⚠️ Privacy Consideration:</strong> Always anonymise user data.
                    Use session IDs for anonymous visitors, user IDs only for logged-in users."))
            )
          )
        ), # end Theory

        # ─────────────────────────────────────────────────────
        # CODE LAB TAB
        # ─────────────────────────────────────────────────────
        tabPanel(
          title = tagList(icon("code"), " Code Lab"),

          code_lab_header(
            title    = "Event Log Explorer & Session Analyser",
            subtitle = "Explore the built-in event log (600 events, 50 users, 30 movies). Mirrors the MovieGEEK collector.Log model.",
            badges   = c("R", "dplyr", "plotly")
          ),

          # ── Event log overview ─────────────────────────────
          fluidRow(
            box(title = "📋 Event Log (sample_events)", status = "primary",
                solidHeader = TRUE, width = 12,
                div(class = "section-heading-dark", "Built-in Data — mirrors MovieGEEK collector.Log"),
                r_code_block(
'# The event log structure (from global.R)
# Mirrors MovieGEEK: collector/models.py -> Log model

head(sample_events, 5)
#   session_id user_id content_id    event  timestamp
# 1         S7      12         14     view  1709123400
# 2        S42       3          2      buy  1708234512
# 3        S18      27         19  details  1707891234
# ...

nrow(sample_events)   # 600 events
n_distinct(sample_events$user_id)    # 50 users
n_distinct(sample_events$content_id) # up to 30 movies'
                ),
                fluidRow(
                  column(3, div(class = "metric-card",
                                span(class = "metric-value",
                                     textOutput(ns("total_events"), inline = TRUE)),
                                span(class = "metric-label", "Total Events"))),
                  column(3, div(class = "metric-card",
                                span(class = "metric-value",
                                     textOutput(ns("unique_users"), inline = TRUE)),
                                span(class = "metric-label", "Unique Users"))),
                  column(3, div(class = "metric-card",
                                span(class = "metric-value",
                                     textOutput(ns("unique_items"), inline = TRUE)),
                                span(class = "metric-label", "Unique Items"))),
                  column(3, div(class = "metric-card",
                                span(class = "metric-value",
                                     textOutput(ns("unique_sessions"), inline = TRUE)),
                                span(class = "metric-label", "Sessions")))
                ),
                br(),
                DTOutput(ns("event_log_table"))
            )
          ),

          # ── Event distribution ─────────────────────────────
          fluidRow(
            box(title = "📊 Event Type Distribution", status = "success",
                solidHeader = TRUE, width = 6,
                r_code_block(
'# Summarise event types
event_summary <- sample_events %>%
  group_by(event) %>%
  summarise(
    count   = n(),
    pct     = round(n() / nrow(sample_events) * 100, 1),
    n_users = n_distinct(user_id)
  ) %>%
  arrange(desc(count))'
                ),
                run_button(ns("run_event_dist"), "▶  Analyse Events"),
                plotlyOutput(ns("event_dist_plot"))
            ),

            box(title = "👤 Per-User Engagement", status = "warning",
                solidHeader = TRUE, width = 6,
                r_code_block(
'# Events per user
user_activity <- sample_events %>%
  group_by(user_id) %>%
  summarise(
    total_events    = n(),
    unique_items    = n_distinct(content_id),
    buy_count       = sum(event == "buy"),
    last_event      = max(timestamp)
  ) %>%
  arrange(desc(total_events))'
                ),
                run_button(ns("run_user_eng"), "▶  Show User Activity"),
                plotlyOutput(ns("user_activity_plot"))
            )
          ),

          # ── Session analysis ───────────────────────────────
          fluidRow(
            box(title = "🔗 Session Analysis", status = "info",
                solidHeader = TRUE, width = 6,
                div(class = "section-heading-dark",
                    "Sessions Group Events — Foundation for Association Rules (Ch 6)"),
                r_code_block(
'# Session-level analysis
session_summary <- sample_events %>%
  group_by(session_id) %>%
  summarise(
    n_events      = n(),
    n_items       = n_distinct(content_id),
    has_buy       = any(event == "buy"),
    event_seq     = paste(event, collapse = "→")
  )

# Conversion rate = sessions with a buy
conv_rate <- mean(session_summary$has_buy)'
                ),
                run_button(ns("run_sessions"), "▶  Analyse Sessions"),
                uiOutput(ns("session_stats")),
                br(),
                DTOutput(ns("session_table"))
            ),

            box(title = "📈 Implicit Signal Quality", status = "primary",
                solidHeader = TRUE, width = 6,
                div(class = "section-heading-dark",
                    "How Reliable Are Different Event Types?"),
                div(class = "info-box-plain",
                    HTML("<strong>Key Question:</strong> A 'view' event means the user saw the item,
                    but did they like it? Each event carries a different confidence level.")),
                br(),
                r_code_block(
'# Signal confidence by event type
# (from MovieGEEK implicit_ratings_calculator.py)
confidence <- data.frame(
  event      = c("buy","addtocart","details","view","search"),
  weight     = c(5, 3, 2, 1, 0.5),
  confidence = c("Very High","High","Medium","Low","Very Low"),
  noise      = c("~5%","~10%","~20%","~40%","~60%")
)'
                ),
                div(class = "result-card",
                    tags$h5("Event Confidence Table"),
                    tags$table(class = "algo-table",
                               tags$thead(tags$tr(
                                 tags$th("Event"), tags$th("Weight"), tags$th("Confidence"), tags$th("Noise")
                               )),
                               tags$tbody(
                                 tags$tr(tags$td("buy"),       tags$td("5"),   tags$td("Very High"), tags$td("~5%")),
                                 tags$tr(tags$td("addtocart"), tags$td("3"),   tags$td("High"),      tags$td("~10%")),
                                 tags$tr(tags$td("details"),   tags$td("2"),   tags$td("Medium"),    tags$td("~20%")),
                                 tags$tr(tags$td("view"),      tags$td("1"),   tags$td("Low"),       tags$td("~40%")),
                                 tags$tr(tags$td("search"),    tags$td("0.5"), tags$td("Very Low"),  tags$td("~60%"))
                               )
                    )
                )
            )
          )
        ) # end Code Lab
      )
    )
  )
}

chapter2_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # ── Static metrics ───────────────────────────────────────
    output$total_events    <- renderText(nrow(sample_events))
    output$unique_users    <- renderText(length(unique(sample_events$user_id)))
    output$unique_items    <- renderText(length(unique(sample_events$content_id)))
    output$unique_sessions <- renderText(length(unique(sample_events$session_id)))

    output$event_log_table <- renderDT({
      df <- sample_events %>%
        arrange(desc(timestamp)) %>%
        head(200) %>%
        mutate(timestamp = as.POSIXct(timestamp, origin = "1970-01-01") %>%
                 format("%Y-%m-%d %H:%M"))
      datatable(df, options = list(pageLength = 8, scrollX = TRUE,
                                   dom = "frtip"),
                rownames = FALSE,
                colnames = c("Session", "User", "Movie ID", "Event", "Time"))
    })

    # ── Event distribution ───────────────────────────────────
    output$event_dist_plot <- renderPlotly({
      input$run_event_dist

      summary_df <- sample_events %>%
        group_by(event) %>%
        summarise(count = n(), .groups = "drop") %>%
        mutate(
          pct   = round(count / sum(count) * 100, 1),
          label = paste0(event, "\n", pct, "%")
        ) %>%
        arrange(desc(count))

      plot_ly(summary_df,
              x     = ~reorder(event, -count),
              y     = ~count,
              type  = "bar",
              text  = ~paste0(count, " (", pct, "%)"),
              textposition = "outside",
              marker = list(color = c("#00A39A","#3b82f6","#f59e0b","#ef4444","#8b5cf6")),
              hovertemplate = "<b>%{x}</b><br>Count: %{y}<extra></extra>") %>%
        layout(
          title  = list(text = "Event Type Frequency",
                        font = list(color = "#d0f0ed", size = 13)),
          xaxis  = list(title = "Event Type", color = "#8a9bb0",
                        gridcolor = "rgba(255,255,255,0.08)"),
          yaxis  = list(title = "Count", color = "#8a9bb0",
                        gridcolor = "rgba(255,255,255,0.08)"),
          showlegend = FALSE
        ) %>%
        plotly_dark_theme()
    })

    # ── User activity ────────────────────────────────────────
    output$user_activity_plot <- renderPlotly({
      input$run_user_eng

      user_df <- sample_events %>%
        group_by(user_id) %>%
        summarise(
          total_events = n(),
          buy_count    = sum(event == "buy"),
          .groups      = "drop"
        ) %>%
        arrange(desc(total_events)) %>%
        head(20)

      plot_ly(user_df, x = ~reorder(paste0("U", user_id), total_events),
              y = ~total_events, type = "bar",
              name = "All Events",
              marker = list(color = "#008A82"),
              hovertemplate = "User %{x}: %{y} events<extra></extra>") %>%
        add_trace(y = ~buy_count, name = "Purchases",
                  marker = list(color = "#e8410a")) %>%
        layout(
          barmode = "overlay",
          title   = list(text = "Top 20 Users by Event Count",
                         font = list(color = "#d0f0ed", size = 13)),
          xaxis   = list(title = "User", color = "#8a9bb0",
                         gridcolor = "rgba(255,255,255,0.08)"),
          yaxis   = list(title = "Event Count", color = "#8a9bb0",
                         gridcolor = "rgba(255,255,255,0.08)"),
          legend  = list(font = list(color = "#8a9bb0"))
        ) %>%
        plotly_dark_theme()
    })

    # ── Session analysis ─────────────────────────────────────
    session_data <- eventReactive(input$run_sessions, {
      sample_events %>%
        group_by(session_id) %>%
        summarise(
          user_id  = first(user_id),
          n_events = n(),
          n_items  = n_distinct(content_id),
          has_buy  = any(event == "buy"),
          .groups  = "drop"
        )
    }, ignoreNULL = FALSE)

    output$session_stats <- renderUI({
      sd         <- session_data()
      conv_rate  <- round(mean(sd$has_buy) * 100, 1)
      avg_events <- round(mean(sd$n_events), 1)

      fluidRow(
        column(6, div(class = "metric-card",
                      span(class = "metric-value", paste0(conv_rate, "%")),
                      span(class = "metric-label", "Session Conversion Rate"))),
        column(6, div(class = "metric-card",
                      span(class = "metric-value", avg_events),
                      span(class = "metric-label", "Avg Events per Session")))
      )
    })

    output$session_table <- renderDT({
      sd <- session_data() %>%
        mutate(has_buy = ifelse(has_buy, "✅ Yes", "No")) %>%
        arrange(desc(n_events)) %>%
        head(50)
      datatable(sd, options = list(pageLength = 6, dom = "frtip"),
                rownames = FALSE,
                colnames = c("Session", "User", "Events", "Items", "Purchase"))
    })
  })
}
