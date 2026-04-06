# modules/chapter6.R
# Chapter 6: The Cold-Start Problem
# Theory + Code Lab: Association rules from scratch
# Mirrors: builder/association_rules_calculator.py

chapter6_ui <- function(id) {
  ns <- NS(id)
  tagList(

    div(class = "meta-hero",
        tags$h1("Chapter 6: The Cold-Start Problem"),
        tags$h2("Association Rules, Support, Confidence, and Bootstrapping"),
        div(
          span(class = "hero-badge", "Cold-Start"),
          span(class = "hero-badge", "Association Rules"),
          span(class = "hero-badge", "Support & Confidence"),
          span(class = "hero-badge", "association_rules_calculator.py")
        )
    ),

    fluidRow(
      box(title = "🎯 Chapter Overview", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, div(class = "metric-card", span(class = "metric-value", "3"),
                          span(class = "metric-label", "Cold-Start Types"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "2"),
                          span(class = "metric-label", "Rule Metrics"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "Apriori"),
                          span(class = "metric-label", "Algorithm Family"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "Basket"),
                          span(class = "metric-label", "Key Data Structure")))
          )
      )
    ),

    fluidRow(
      tabBox(width = 12, id = ns("ch6_tabs"),

        # ── THEORY ─────────────────────────────────────────
        tabPanel(title = tagList(icon("book"), " Theory"),
          fluidRow(
            box(title = "🥶 The Cold-Start Problem", status = "info",
                solidHeader = TRUE, width = 6,
                div(class = "warn-box",
                    HTML("<strong>⚠️ Core Problem:</strong> CF and MF require interaction history.
                    New users and new items have none. The system can't personalise without data,
                    but users won't engage without good recommendations.")),
                br(),
                div(class = "framework-card",
                    tags$h5("Three Types of Cold-Start"),
                    tags$p(HTML("<strong>1. New User:</strong> Just registered, zero ratings")),
                    tags$p(HTML("<strong>2. New Item:</strong> Just added to catalogue")),
                    tags$p(HTML("<strong>3. New System:</strong> No data at all (launch day)"))
                ),
                br(),
                div(class = "framework-card",
                    tags$h5("Solutions"),
                    tags$p(HTML("<strong>New user:</strong> Popularity recs (Ch 5), ask for preferences, demographics")),
                    tags$p(HTML("<strong>New item:</strong> Content-based bootstrap (Ch 10), editorial picks")),
                    tags$p(HTML("<strong>Both:</strong> Association rules from session co-occurrence"))
                )
            ),
            box(title = "🔗 Association Rules", status = "warning",
                solidHeader = TRUE, width = 6,
                div(class = "section-heading-dark", "If A → then B"),
                div(class = "framework-card",
                    tags$h5("Support"),
                    tags$p(HTML("<strong>Formula:</strong> P(A ∩ B) = sessions containing both A and B / total sessions")),
                    tags$p("How frequently does this combination appear? Low support = rare rule.")
                ),
                div(class = "framework-card",
                    tags$h5("Confidence"),
                    tags$p(HTML("<strong>Formula:</strong> P(B|A) = sessions with both / sessions with A")),
                    tags$p("Given the user has item A, how likely are they to want B?")
                ),
                br(),
                div(class = "tip-box",
                    HTML("<strong>💡 MovieGEEK:</strong> association_rules_calculator.py reads buy events
                    from the Log table, groups by session_id to form transactions,
                    then mines rules with configurable min_support threshold.")),
                br(),
                div(class = "framework-card",
                    tags$h5("Apriori Principle"),
                    tags$p("If an itemset is infrequent, all its supersets are also infrequent.
                           This lets us prune the search space efficiently."),
                    tags$p(HTML("<strong>Step 1:</strong> Find all frequent 1-itemsets (items with support ≥ min_sup)")),
                    tags$p(HTML("<strong>Step 2:</strong> Find all frequent 2-itemsets from pairs of frequent 1-itemsets")),
                    tags$p(HTML("<strong>Step 3:</strong> Generate rules from frequent 2-itemsets"))
                )
            )
          ),
          fluidRow(
            box(title = "📐 Example: Session Transactions", status = "success",
                solidHeader = TRUE, width = 12,
                div(class = "info-box-plain",
                    HTML("<strong>Worked Example:</strong> 5 sessions, each containing movies watched (bought).")),
                fluidRow(
                  column(4,
                    tags$table(class="algo-table",
                      tags$thead(tags$tr(tags$th("Session"),tags$th("Items"))),
                      tags$tbody(
                        tags$tr(tags$td("S1"),tags$td("Matrix, Inception")),
                        tags$tr(tags$td("S2"),tags$td("Matrix, Interstellar, Inception")),
                        tags$tr(tags$td("S3"),tags$td("Interstellar, Inception")),
                        tags$tr(tags$td("S4"),tags$td("Matrix, Die Hard")),
                        tags$tr(tags$td("S5"),tags$td("Matrix, Inception, Die Hard"))
                      ))
                  ),
                  column(4,
                    div(class="framework-card",
                        tags$h5("Support Calculations"),
                        tags$p(HTML("<strong>{Matrix}:</strong> 4/5 = 0.80")),
                        tags$p(HTML("<strong>{Inception}:</strong> 4/5 = 0.80")),
                        tags$p(HTML("<strong>{Matrix, Inception}:</strong> 3/5 = 0.60")),
                        tags$p(HTML("<strong>{Interstellar, Inception}:</strong> 2/5 = 0.40"))
                    )
                  ),
                  column(4,
                    div(class="framework-card",
                        tags$h5("Rule: Matrix → Inception"),
                        tags$p(HTML("<strong>Support:</strong> 3/5 = 0.60")),
                        tags$p(HTML("<strong>Confidence:</strong> 3/4 = 0.75")),
                        tags$p("Interpretation: 75% of sessions that included Matrix also included Inception.")
                    )
                  )
                )
            )
          )
        ), # end Theory

        # ── CODE LAB ───────────────────────────────────────
        tabPanel(title = tagList(icon("code"), " Code Lab"),

          code_lab_header(
            title    = "Association Rules Calculator — R Implementation",
            subtitle = "Full mirror of association_rules_calculator.py. Mine rules from the built-in session event log. Adjust support/confidence thresholds and inspect the rule table.",
            badges   = c("R", "dplyr", "mirrors: association_rules_calculator.py")
          ),

          fluidRow(
            box(title = "⚙️ Mining Configuration", status = "primary",
                solidHeader = TRUE, width = 4,
                div(class = "control-panel",
                    div(class = "section-heading-dark", "Apriori Thresholds"),
                    sliderInput(ns("min_sup"),  "Minimum Support",
                                min = 0.01, max = 0.30, value = 0.05, step = 0.01),
                    sliderInput(ns("min_conf"), "Minimum Confidence",
                                min = 0.10, max = 0.90, value = 0.30, step = 0.05),
                    br(),
                    div(class = "section-heading-dark", "Event Filter"),
                    checkboxGroupInput(ns("events_to_use"),
                                       "Include these event types in transactions:",
                                       choices  = c("buy","addtocart","details","view"),
                                       selected = c("buy","addtocart")),
                    br(),
                    run_button(ns("run_rules"), "▶  Mine Association Rules")
                ),
                br(),
                r_code_block(
'# association_rules_calculator.py in R

# Step 1: Build transaction baskets
transactions <- sample_events %>%
  filter(event %in% events_to_use) %>%
  group_by(session_id) %>%
  summarise(
    items = list(unique(content_id))
  )

N <- nrow(transactions)

# Step 2: Count 1-itemsets
one_counts <- unlist(transactions$items) %>%
  table() %>% as.data.frame()

# Filter by min_support
freq_1 <- one_counts %>%
  filter(Freq / N >= min_sup)

# Step 3: Count 2-itemsets
# Step 4: Calculate rules'
                )
            ),

            box(title = "📊 Rule Discovery Results", status = "success",
                solidHeader = TRUE, width = 8,
                fluidRow(
                  column(3, div(class = "metric-card",
                                span(class = "metric-value",
                                     textOutput(ns("n_transactions"), inline = TRUE)),
                                span(class = "metric-label", "Transactions"))),
                  column(3, div(class = "metric-card",
                                span(class = "metric-value",
                                     textOutput(ns("n_freq_items"), inline = TRUE)),
                                span(class = "metric-label", "Frequent Items"))),
                  column(3, div(class = "metric-card",
                                span(class = "metric-value",
                                     textOutput(ns("n_rules"), inline = TRUE)),
                                span(class = "metric-label", "Rules Found"))),
                  column(3, div(class = "metric-card",
                                span(class = "metric-value",
                                     textOutput(ns("avg_conf"), inline = TRUE)),
                                span(class = "metric-label", "Avg Confidence")))
                ),
                br(),
                uiOutput(ns("rules_status")),
                br(),
                DTOutput(ns("rules_table"))
            )
          ),

          fluidRow(
            box(title = "📈 Support vs Confidence Scatter", status = "warning",
                solidHeader = TRUE, width = 6,
                div(class = "tip-box",
                    HTML("<strong>Reading the chart:</strong> Top-right = high support AND high confidence.
                    These are the most reliable rules. Bottom-left = rare, uncertain rules.")),
                plotlyOutput(ns("rules_scatter"))
            ),

            box(title = "🗺️ Item Co-occurrence Heatmap", status = "info",
                solidHeader = TRUE, width = 6,
                div(class = "info-box-plain",
                    HTML("<strong>Co-occurrence matrix:</strong> How often do pairs of items
                    appear in the same session? This is the raw material for both association
                    rules and item-item collaborative filtering.")),
                plotlyOutput(ns("cooccurrence_heatmap"))
            )
          ),

          fluidRow(
            box(title = "🔍 Rule Inspector: Seeded Recommendations", status = "primary",
                solidHeader = TRUE, width = 12,
                div(class = "section-heading-dark",
                    "Given a source item, what does the rule engine recommend?"),
                div(class = "control-panel",
                    fluidRow(
                      column(4, uiOutput(ns("source_item_picker"))),
                      column(4, sliderInput(ns("n_recs_rules"), "Top-N rules to show",
                                            min=1, max=10, value=5)),
                      column(4, br(), run_button(ns("run_inspect"), "▶  Show Recommendations"))
                    )
                ),
                uiOutput(ns("rule_inspect_result"))
            )
          )
        ) # end Code Lab
      )
    )
  )
}

chapter6_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # ── Core association rules computation ───────────────────
    rules_data <- eventReactive(input$run_rules, {
      events_ok <- input$events_to_use
      if (length(events_ok) == 0) events_ok <- "buy"
      min_sup   <- input$min_sup
      min_conf  <- input$min_conf

      # Build transaction baskets
      transactions <- sample_events %>%
        filter(event %in% events_ok) %>%
        group_by(session_id) %>%
        summarise(items = list(unique(content_id)), .groups = "drop") %>%
        filter(lengths(items) >= 2)

      N <- nrow(transactions)
      if (N == 0) return(list(rules = data.frame(), N = 0, freq1 = c()))

      # Frequent 1-itemsets
      all_items  <- unlist(transactions$items)
      item_counts <- table(all_items)
      freq_1      <- names(item_counts[item_counts / N >= min_sup])

      # Frequent 2-itemsets
      two_counts <- list()
      for (sess_items in transactions$items) {
        filtered <- intersect(sess_items, freq_1)
        if (length(filtered) < 2) next
        pairs <- combn(sort(filtered), 2, simplify = FALSE)
        for (p in pairs) {
          key <- paste(p, collapse = "_|_")
          two_counts[[key]] <- (two_counts[[key]] %||% 0) + 1
        }
      }

      if (length(two_counts) == 0)
        return(list(rules = data.frame(), N = N, freq1 = freq_1))

      # Generate rules
      rules <- lapply(names(two_counts), function(key) {
        parts    <- strsplit(key, "_\\|_")[[1]]
        src      <- parts[1]; tgt <- parts[2]
        pair_cnt <- two_counts[[key]]
        src_cnt  <- item_counts[src]
        tgt_cnt  <- item_counts[tgt]
        support    <- pair_cnt / N
        conf_st    <- pair_cnt / src_cnt
        conf_ts    <- pair_cnt / tgt_cnt

        rbind(
          data.frame(source = src, target = tgt,
                     support = support, confidence = conf_st,
                     pair_count = pair_cnt, src_count = src_cnt,
                     stringsAsFactors = FALSE),
          data.frame(source = tgt, target = src,
                     support = support, confidence = conf_ts,
                     pair_count = pair_cnt, src_count = tgt_cnt,
                     stringsAsFactors = FALSE)
        )
      })

      rules_df <- do.call(rbind, rules) %>%
        filter(support >= min_sup, confidence >= min_conf) %>%
        mutate(
          support    = round(support, 4),
          confidence = round(confidence, 4)
        ) %>%
        left_join(sample_movies %>% select(movie_id, title),
                  by = c("source" = "movie_id")) %>%
        rename(source_title = title) %>%
        left_join(sample_movies %>% select(movie_id, title),
                  by = c("target" = "movie_id")) %>%
        rename(target_title = title) %>%
        arrange(desc(confidence), desc(support))

      list(rules = rules_df, N = N, freq1 = freq_1,
           item_counts = item_counts, transactions = transactions)
    }, ignoreNULL = FALSE)

    # Null coalescing helper
    `%||%` <- function(a, b) if (!is.null(a)) a else b

    output$n_transactions <- renderText(rules_data()$N)
    output$n_freq_items   <- renderText(length(rules_data()$freq1))
    output$n_rules        <- renderText(nrow(rules_data()$rules))
    output$avg_conf       <- renderText({
      r <- rules_data()$rules
      if (nrow(r) == 0) return("—")
      round(mean(r$confidence), 3)
    })

    output$rules_status <- renderUI({
      r <- rules_data()$rules
      if (nrow(r) == 0)
        return(div(class="warn-box",
                   HTML("<strong>No rules found.</strong> Try lowering min_support or min_confidence, or including more event types.")))
      div(class="success-box",
          HTML(paste0("<strong>✅ ", nrow(r), " rules mined</strong> from ",
                      rules_data()$N, " transactions (sessions with ≥2 items).")))
    })

    output$rules_table <- renderDT({
      r <- rules_data()$rules
      if (nrow(r) == 0) return(datatable(data.frame(Message = "No rules found")))
      display <- r %>%
        select(`Source Movie` = source_title, `→ Target Movie` = target_title,
               Support = support, Confidence = confidence,
               `Pair Count` = pair_count)
      datatable(display, options = list(pageLength=10, scrollX=TRUE, dom="frtip"),
                rownames = FALSE) %>%
        formatStyle("Confidence",
                    background = styleColorBar(c(0,1), "#00A39A"),
                    backgroundSize="95% 55%", backgroundRepeat="no-repeat",
                    backgroundPosition="center") %>%
        formatStyle("Support",
                    background = styleColorBar(c(0, max(r$support, na.rm=TRUE)), "#3b82f6"),
                    backgroundSize="95% 55%", backgroundRepeat="no-repeat",
                    backgroundPosition="center")
    })

    output$rules_scatter <- renderPlotly({
      r <- rules_data()$rules
      if (nrow(r) == 0)
        return(plot_ly() %>% layout(title=list(text="No rules to plot",
                                               font=list(color="#d0f0ed"))) %>%
                 plotly_dark_theme())

      r_plot <- r %>% left_join(
        sample_movies %>% select(movie_id, genre),
        by = c("source" = "movie_id"))

      plot_ly(r_plot, x=~support, y=~confidence,
              text=~paste0(source_title,"→",target_title),
              color=~genre, type="scatter", mode="markers",
              marker=list(size=9, opacity=0.8),
              hovertemplate="<b>%{text}</b><br>Sup: %{x:.3f}<br>Conf: %{y:.3f}<extra></extra>") %>%
        layout(title=list(text="Rules: Support vs Confidence",
                          font=list(color="#d0f0ed",size=13)),
               xaxis=list(title="Support",color="#8a9bb0",gridcolor="rgba(255,255,255,0.08)"),
               yaxis=list(title="Confidence",color="#8a9bb0",gridcolor="rgba(255,255,255,0.08)"),
               legend=list(font=list(color="#8a9bb0"))) %>%
        plotly_dark_theme()
    })

    output$cooccurrence_heatmap <- renderPlotly({
      rd <- rules_data()
      if (is.null(rd$transactions) || nrow(rd$transactions) == 0)
        return(plot_ly() %>% plotly_dark_theme())

      top_items <- names(sort(rd$item_counts, decreasing=TRUE))[1:min(15,length(rd$item_counts))]
      mat  <- matrix(0L, length(top_items), length(top_items),
                     dimnames=list(top_items, top_items))

      for (sess in rd$transactions$items) {
        overlap <- intersect(as.character(sess), top_items)
        if (length(overlap) < 2) next
        pairs <- combn(overlap, 2)
        for (k in seq_len(ncol(pairs))) {
          a <- pairs[1,k]; b <- pairs[2,k]
          mat[a,b] <- mat[a,b] + 1L
          mat[b,a] <- mat[b,a] + 1L
        }
      }

      labels <- sample_movies$title[match(as.integer(top_items), sample_movies$movie_id)]
      labels[is.na(labels)] <- paste0("M",top_items[is.na(labels)])

      plot_ly(z=mat, x=labels, y=labels, type="heatmap",
              colorscale=list(c(0,"#e0f4f2"),c(1,"#008A82")),
              colorbar=list(title="Co-occur",tickfont=list(color="#8a9bb0")),
              hovertemplate="%{y} × %{x}: %{z}<extra></extra>") %>%
        layout(title=list(text="Item Co-occurrence Matrix",
                          font=list(color="#d0f0ed",size=13)),
               xaxis=list(title="",color="#8a9bb0",tickangle=-35),
               yaxis=list(title="",color="#8a9bb0")) %>%
        plotly_dark_theme()
    })

    output$source_item_picker <- renderUI({
      r <- rules_data()$rules
      if (nrow(r) == 0) return(tags$p("Run mining first"))
      choices <- setNames(unique(r$source),
                          sample_movies$title[match(unique(r$source), sample_movies$movie_id)])
      choices <- choices[!is.na(names(choices))]
      selectInput(ns("source_item"), "Source item (user has this):", choices=choices)
    })

    rule_inspect <- eventReactive(input$run_inspect, {
      r   <- rules_data()$rules
      src <- input$source_item
      if (is.null(src) || nrow(r)==0) return(NULL)
      r %>% filter(source==src) %>%
        arrange(desc(confidence)) %>%
        head(input$n_recs_rules)
    }, ignoreNULL=FALSE)

    output$rule_inspect_result <- renderUI({
      ri <- rule_inspect()
      if (is.null(ri) || nrow(ri)==0)
        return(div(class="warn-box",HTML("<strong>No rules available for this item.</strong>")))
      src_title <- ri$source_title[1]
      rows <- lapply(seq_len(nrow(ri)), function(i)
        tags$tr(tags$td(paste0("#",i)),
                tags$td(ri$target_title[i]),
                tags$td(ri$support[i]),
                tags$td(paste0(round(ri$confidence[i]*100,1),"%")),
                tags$td(ri$pair_count[i])))
      div(class="result-card",
          tags$h5(paste0("Rules: '",src_title,"' → ...")),
          tags$p(style="font-size:11.5px;color:#546e7a;margin-bottom:10px;",
                 paste0("Users who interacted with '",src_title,"' also interacted with:")),
          tags$table(class="algo-table",
                     tags$thead(tags$tr(tags$th("#"),tags$th("Recommended Movie"),
                                        tags$th("Support"),tags$th("Confidence"),
                                        tags$th("Co-occurrences"))),
                     tags$tbody(rows)))
    })
  })
}
