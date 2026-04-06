# modules/chapter7.R
# Chapter 7: Finding Similarities Among Users and Content
# Theory + Code Lab: All metrics + item-item similarity matrix
# Mirrors: builder/item_similarity_calculator.py (normalize + cosine)

chapter7_ui <- function(id) {
  ns <- NS(id)
  tagList(

    div(class = "meta-hero",
        tags$h1("Chapter 7: Finding Similarities"),
        tags$h2("Cosine, Euclidean, Pearson, Jaccard, Adjusted Cosine"),
        div(
          span(class = "hero-badge", "Cosine"),
          span(class = "hero-badge", "Pearson"),
          span(class = "hero-badge", "Adjusted Cosine"),
          span(class = "hero-badge", "item_similarity_calculator.py")
        )
    ),

    fluidRow(
      box(title = "🎯 Chapter Overview", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, div(class="metric-card",span(class="metric-value","5"),  span(class="metric-label","Metrics"))),
            column(3, div(class="metric-card",span(class="metric-value","0–1"),span(class="metric-label","Score Range"))),
            column(3, div(class="metric-card",span(class="metric-value","Core"),span(class="metric-label","CF Foundation"))),
            column(3, div(class="metric-card",span(class="metric-value","Sparse"),span(class="metric-label","Designed for Sparse Data")))
          )
      )
    ),

    fluidRow(
      tabBox(width=12, id=ns("ch7_tabs"),

        # ── THEORY ─────────────────────────────────────────
        tabPanel(title=tagList(icon("book")," Theory"),
          fluidRow(
            box(title="📐 Cosine Similarity", status="success", solidHeader=TRUE, width=6,
                div(class="framework-card",
                    tags$h5("Formula"),
                    tags$p(HTML("<strong>sim(A,B) = (A · B) / (||A|| × ||B||)</strong>")),
                    tags$p(HTML("<strong>Range:</strong> -1 to 1 (typically 0 to 1 for ratings)")),
                    tags$p(HTML("<strong>Interpretation:</strong> Cosine of the angle between vectors"))
                ),
                div(class="tip-box",
                    HTML("<strong>💡 Key Property:</strong> Magnitude-invariant. A harsh rater (1–3) and a
                    generous rater (3–5) who agree on relative ranking will have high cosine similarity.")),
                br(),
                div(class="framework-card",
                    tags$h5("MovieGEEK: normalize() then cosine"),
                    tags$p("item_similarity_calculator.py applies normalize() per user BEFORE cosine."),
                    tags$p(HTML("<code>ratings['avg'] = ratings.groupby('user_id')['rating'].transform(normalize)</code>")),
                    tags$p("This is the Adjusted Cosine similarity — the standard for item-based CF.")
                )
            ),
            box(title="📏 Other Similarity Metrics", status="warning", solidHeader=TRUE, width=6,
                div(class="framework-card",
                    tags$h5("Euclidean Distance → Similarity"),
                    tags$p(HTML("<strong>dist(A,B) = √Σ(Aᵢ - Bᵢ)²</strong>")),
                    tags$p(HTML("<strong>sim = 1 / (1 + dist)</strong>")),
                    tags$p("Sensitive to rating scale. Generous vs harsh raters appear far apart.")
                ),
                div(class="framework-card",
                    tags$h5("Pearson Correlation"),
                    tags$p(HTML("<strong>r = Σ(Aᵢ-Ā)(Bᵢ-B̄) / (σ_A × σ_B)</strong>")),
                    tags$p("Mean-centres before computing. Handles rating bias automatically."),
                    tags$p(HTML("<strong>Range:</strong> -1 to 1"))
                ),
                div(class="framework-card",
                    tags$h5("Jaccard Similarity"),
                    tags$p(HTML("<strong>J(A,B) = |A ∩ B| / |A ∪ B|</strong>")),
                    tags$p("Based on sets — ignores rating values, only cares whether item was rated."),
                    tags$p(HTML("<strong>Best for:</strong> Implicit feedback (click/no-click)"))
                ),
                div(class="framework-card",
                    tags$h5("Adjusted Cosine (MovieGEEK standard)"),
                    tags$p("Subtract each user's mean before computing cosine. Captures relative preference."),
                    tags$p(HTML("<strong>Best for:</strong> Item-based CF on explicit ratings"))
                )
            )
          ),
          fluidRow(
            box(title="🏗️ The normalize() Function from MovieGEEK", status="primary",
                solidHeader=TRUE, width=12,
                div(class="info-box-plain",
                    HTML("<strong>item_similarity_calculator.py uses this normalize function applied per-user
                    before the cosine similarity matrix is computed. This is what makes it 'adjusted cosine'.</strong>")),
                fluidRow(
                  column(6, r_code_block(
'# Python: item_similarity_calculator.py
def normalize(x):
    x = x.astype(float)
    x_sum = x.sum()
    x_num = x.astype(bool).sum()
    x_mean = x_sum / x_num

    if x_num == 1 or x.std() == 0:
        return 0.0
    return (x - x_mean) / (x.max() - x.min())

# Applied per user:
ratings["avg"] = ratings.groupby("user_id")[
    "rating"].transform(normalize)'
                  )),
                  column(6, r_code_block(
'# R equivalent:
normalize_ratings <- function(x) {
  x <- as.numeric(x)
  x_mean <- mean(x, na.rm=TRUE)
  x_range <- max(x,na.rm=TRUE) -
             min(x,na.rm=TRUE)
  if (sum(!is.na(x)) <= 1 || x_range==0)
    return(rep(0, length(x)))
  (x - x_mean) / x_range
}

# Applied per user:
ratings %>%
  group_by(user_id) %>%
  mutate(norm_rating =
           normalize_ratings(rating))'
                  ))
                )
            )
          )
        ), # end Theory

        # ── CODE LAB ───────────────────────────────────────
        tabPanel(title=tagList(icon("code")," Code Lab"),

          code_lab_header(
            title    = "Similarity Calculator & Item-Item Matrix Builder",
            subtitle = "Live metric calculator on editable vectors. Full item-item similarity matrix mirroring ItemSimilarityMatrixBuilder from MovieGEEK.",
            badges   = c("R", "Matrix", "mirrors: item_similarity_calculator.py")
          ),

          # ── Section 1: Live vector calculator ─────────────
          fluidRow(
            box(title="🔢 Live Similarity Calculator", status="primary",
                solidHeader=TRUE, width=5,
                div(class="section-heading-dark","Enter two user rating vectors"),
                div(class="info-box-plain",
                    HTML("Enter comma-separated ratings (1–5). Use <strong>NA</strong> for unseen items.")),
                div(class="control-panel",
                    textInput(ns("vec_a"), "User A ratings:",
                              value="5,4,NA,2,3,NA,5,1"),
                    textInput(ns("vec_b"), "User B ratings:",
                              value="4,5,3,NA,2,NA,4,2"),
                    selectInput(ns("sim_metric"), "Metric:",
                                choices=c("Cosine"="cosine",
                                          "Adjusted Cosine"="adj_cosine",
                                          "Pearson Correlation"="pearson",
                                          "Euclidean → Similarity"="euclidean",
                                          "Jaccard (sets)"="jaccard")),
                    run_button(ns("run_sim_calc"), "▶  Calculate Similarity")
                ),
                uiOutput(ns("sim_calc_result"))
            ),

            box(title="📊 All Metrics Compared", status="success",
                solidHeader=TRUE, width=7,
                div(class="section-heading-dark","Same vectors, all five metrics simultaneously"),
                plotlyOutput(ns("all_metrics_plot"), height="260px"),
                br(),
                DTOutput(ns("all_metrics_table"))
            )
          ),

          # ── Section 2: Full similarity matrix ─────────────
          fluidRow(
            box(title="🏗️ Item-Item Similarity Matrix Builder", status="warning",
                solidHeader=TRUE, width=4,
                div(class="section-heading-dark",
                    "Mirrors ItemSimilarityMatrixBuilder"),
                div(class="control-panel",
                    sliderInput(ns("min_overlap"), "Min co-raters (min_overlap)",
                                min=1, max=15, value=3, step=1),
                    sliderInput(ns("min_sim"),     "Min similarity threshold",
                                min=0.0, max=0.8, value=0.1, step=0.05),
                    checkboxInput(ns("use_adjusted"),
                                  "Use Adjusted Cosine (normalize per user)",
                                  value=TRUE),
                    run_button(ns("run_matrix"), "▶  Build Similarity Matrix")
                ),
                br(),
                fluidRow(
                  column(6, div(class="metric-card",
                                span(class="metric-value",textOutput(ns("m_nonzero"),inline=TRUE)),
                                span(class="metric-label","Non-zero Pairs"))),
                  column(6, div(class="metric-card",
                                span(class="metric-value",textOutput(ns("m_density"),inline=TRUE)),
                                span(class="metric-label","Matrix Density")))
                ),
                br(),
                r_code_block(
'# ItemSimilarityMatrixBuilder in R
# mirrors item_similarity_calculator.py

build_similarity <- function(ratings,
    min_overlap=3, min_sim=0.1,
    adjusted=TRUE) {

  if (adjusted) {
    # normalize() per user
    ratings <- ratings %>%
      group_by(user_id) %>%
      mutate(r = normalize_ratings(rating)) %>%
      ungroup()
  } else {
    ratings <- ratings %>%
      mutate(r = rating)
  }

  # Pivot to item × user matrix
  mat <- ratings %>%
    select(movie_id, user_id, r) %>%
    pivot_wider(names_from=user_id,
                values_from=r,
                values_fill=0) %>%
    column_to_rownames("movie_id") %>%
    as.matrix()

  # Cosine similarity
  sim <- cosine_sim(mat)
  sim[overlap_mat < min_overlap] <- 0
  sim[sim < min_sim] <- 0
  sim
}'
                )
            ),

            box(title="🗺️ Similarity Heatmap", status="info",
                solidHeader=TRUE, width=8,
                plotlyOutput(ns("sim_heatmap"), height="450px")
            )
          ),

          # ── Section 3: Most similar items explorer ─────────
          fluidRow(
            box(title="🔍 Find Most Similar Items", status="primary",
                solidHeader=TRUE, width=12,
                div(class="section-heading-dark",
                    "For any movie, see its K nearest neighbours by similarity"),
                div(class="control-panel",
                    fluidRow(
                      column(4, uiOutput(ns("item_picker"))),
                      column(4, sliderInput(ns("k_neighbours"), "K neighbours",
                                            min=3, max=15, value=8)),
                      column(4, br(), run_button(ns("run_nn"), "▶  Find Neighbours"))
                    )
                ),
                uiOutput(ns("nn_result"))
            )
          )
        ) # end Code Lab
      )
    )
  )
}

chapter7_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # ── Helper functions ─────────────────────────────────────
    normalize_ratings <- function(x) {
      x     <- as.numeric(x)
      valid <- !is.na(x)
      if (sum(valid) <= 1) return(rep(0, length(x)))
      x_mean  <- mean(x[valid])
      x_range <- max(x[valid]) - min(x[valid])
      if (x_range == 0) return(rep(0, length(x)))
      result <- (x - x_mean) / x_range
      result[!valid] <- 0
      result
    }

    parse_vec <- function(s) {
      parts <- strsplit(trimws(s), ",")[[1]]
      suppressWarnings(as.numeric(trimws(parts)))
    }

    compute_sim <- function(a, b, metric) {
      both <- !is.na(a) & !is.na(b)
      if (sum(both) == 0) return(NA_real_)
      av <- a[both]; bv <- b[both]

      if (metric == "cosine") {
        d <- sum(av*bv) / (sqrt(sum(av^2)) * sqrt(sum(bv^2)))
        if (is.nan(d)) return(0); return(round(d, 4))
      }
      if (metric == "adj_cosine") {
        av2 <- av - mean(av); bv2 <- bv - mean(bv)
        d   <- sum(av2*bv2) / (sqrt(sum(av2^2)) * sqrt(sum(bv2^2)))
        if (is.nan(d)) return(0); return(round(d, 4))
      }
      if (metric == "pearson") {
        if (sd(av)==0 || sd(bv)==0) return(0)
        return(round(cor(av, bv, method="pearson"), 4))
      }
      if (metric == "euclidean") {
        dist_val <- sqrt(sum((av-bv)^2))
        return(round(1 / (1 + dist_val), 4))
      }
      if (metric == "jaccard") {
        a_set <- which(!is.na(a)); b_set <- which(!is.na(b))
        intersect_n <- length(intersect(a_set, b_set))
        union_n     <- length(union(a_set, b_set))
        if (union_n == 0) return(0)
        return(round(intersect_n / union_n, 4))
      }
      NA_real_
    }

    cosine_sim_matrix <- function(mat) {
      norms <- sqrt(rowSums(mat^2))
      norms[norms == 0] <- 1e-10
      mat_norm <- mat / norms
      tcrossprod(mat_norm)
    }

    # ── Live similarity calculator ───────────────────────────
    sim_result <- eventReactive(input$run_sim_calc, {
      a <- parse_vec(input$vec_a)
      b <- parse_vec(input$vec_b)
      n <- max(length(a), length(b))
      if (length(a) < n) a <- c(a, rep(NA, n-length(a)))
      if (length(b) < n) b <- c(b, rep(NA, n-length(b)))
      val <- compute_sim(a, b, input$sim_metric)
      list(val=val, a=a, b=b, metric=input$sim_metric,
           overlap=sum(!is.na(a) & !is.na(b)))
    }, ignoreNULL=FALSE)

    output$sim_calc_result <- renderUI({
      r   <- sim_result()
      col <- if (!is.na(r$val) && r$val > 0.5) "#008A82"
             else if (!is.na(r$val) && r$val > 0.2) "#e67e22"
             else "#e74c3c"
      div(class="result-card",
          tags$h5(paste0("Similarity: ", r$metric)),
          fluidRow(
            column(6,div(class="metric-card",style=paste0("background:",col),
                         span(class="metric-value", if(is.na(r$val)) "NA" else r$val),
                         span(class="metric-label","Similarity Score"))),
            column(6,div(class="metric-card",
                         span(class="metric-value",r$overlap),
                         span(class="metric-label","Overlapping Items")))
          ),
          br(),
          div(class=if(!is.na(r$val)&&r$val>0.5)"success-box" else "warn-box",
              HTML(paste0("<strong>Interpretation:</strong> ",
                          if(is.na(r$val)) "Not enough overlap to compute."
                          else if(r$val>0.7) "High similarity — strong neighbourhood candidate."
                          else if(r$val>0.4) "Moderate similarity — candidate with caution."
                          else "Low similarity — likely not a good neighbour.")))
      )
    })

    output$all_metrics_plot <- renderPlotly({
      a <- parse_vec(input$vec_a); b <- parse_vec(input$vec_b)
      n <- max(length(a),length(b))
      if (length(a)<n) a <- c(a,rep(NA,n-length(a)))
      if (length(b)<n) b <- c(b,rep(NA,n-length(b)))

      metrics <- c("cosine","adj_cosine","pearson","euclidean","jaccard")
      vals    <- sapply(metrics, function(m) {v<-compute_sim(a,b,m); if(is.na(v)) 0 else v})
      labels  <- c("Cosine","Adj Cosine","Pearson","Euclidean\n→Sim","Jaccard")

      plot_ly(x=labels, y=vals, type="bar",
              marker=list(color=c("#00A39A","#008A82","#3b82f6","#f59e0b","#8b5cf6")),
              text=round(vals,3), textposition="outside",
              hovertemplate="%{x}: %{y:.4f}<extra></extra>") %>%
        layout(yaxis=list(range=c(-0.1,1.15),title="Score",
                          color="#8a9bb0",gridcolor="rgba(255,255,255,0.08)"),
               xaxis=list(color="#8a9bb0"),
               title=list(text="All Metrics on Same Vectors",
                          font=list(color="#d0f0ed",size=12)),
               showlegend=FALSE) %>%
        plotly_dark_theme()
    })

    output$all_metrics_table <- renderDT({
      a <- parse_vec(input$vec_a); b <- parse_vec(input$vec_b)
      n <- max(length(a),length(b))
      if (length(a)<n) a<-c(a,rep(NA,n-length(a)))
      if (length(b)<n) b<-c(b,rep(NA,n-length(b)))
      metrics <- c("cosine","adj_cosine","pearson","euclidean","jaccard")
      labels  <- c("Cosine","Adjusted Cosine","Pearson","Euclidean → Sim","Jaccard")
      vals    <- sapply(metrics, function(m) {v<-compute_sim(a,b,m);if(is.na(v))NA else v})
      use_case <- c("Item-based CF","Item-based CF (standard)","User-based CF","Dense data","Implicit feedback")
      df <- data.frame(Metric=labels, Score=round(vals,4),`Best For`=use_case,
                       check.names=FALSE)
      datatable(df, options=list(dom="t",pageLength=5), rownames=FALSE)
    })

    # ── Similarity matrix builder ────────────────────────────
    sim_matrix_data <- eventReactive(input$run_matrix, {
      min_ov  <- input$min_overlap
      min_sim <- input$min_sim
      adj     <- input$use_adjusted

      ratings_use <- sample_ratings
      if (adj) {
        ratings_use <- ratings_use %>%
          group_by(user_id) %>%
          mutate(r_norm = normalize_ratings(rating)) %>%
          ungroup()
      } else {
        ratings_use <- ratings_use %>% mutate(r_norm = rating)
      }

      # Overlap matrix
      overlap_wide <- sample_ratings %>%
        mutate(rated=1L) %>%
        pivot_wider(id_cols=movie_id, names_from=user_id,
                    values_from=rated, values_fill=0L)
      movie_ids_ov <- overlap_wide$movie_id
      ov_mat       <- as.matrix(overlap_wide[,-1])
      ov_sim       <- tcrossprod(ov_mat)
      rownames(ov_sim) <- colnames(ov_sim) <- movie_ids_ov

      # Rating matrix (normalised)
      r_wide <- ratings_use %>%
        select(movie_id, user_id, r_norm) %>%
        pivot_wider(id_cols=movie_id, names_from=user_id,
                    values_from=r_norm, values_fill=0)
      movie_ids_r <- r_wide$movie_id
      r_mat        <- as.matrix(r_wide[,-1])
      sim_mat      <- cosine_sim_matrix(r_mat)
      rownames(sim_mat) <- colnames(sim_mat) <- movie_ids_r

      # Apply overlap and min_sim filters
      common_ids <- intersect(as.character(movie_ids_r), as.character(movie_ids_ov))
      sim_filtered <- sim_mat[common_ids, common_ids]
      ov_filtered  <- ov_sim[common_ids, common_ids]
      sim_filtered[ov_filtered < min_ov] <- 0
      sim_filtered[sim_filtered < min_sim] <- 0
      diag(sim_filtered) <- 0

      list(sim=sim_filtered, movie_ids=as.integer(common_ids))
    }, ignoreNULL=FALSE)

    output$m_nonzero <- renderText({
      m <- sim_matrix_data()$sim
      sum(m > 0)
    })
    output$m_density <- renderText({
      m <- sim_matrix_data()$sim
      n <- nrow(m)
      if(n<=1) return("—")
      paste0(round(sum(m>0)/(n*(n-1))*100, 1), "%")
    })

    output$sim_heatmap <- renderPlotly({
      sm <- sim_matrix_data()
      m  <- sm$sim
      ids <- sm$movie_ids

      # Top 20 most connected items
      connectivity <- rowSums(m > 0)
      top_idx      <- order(connectivity, decreasing=TRUE)[1:min(20,nrow(m))]
      m_plot       <- m[top_idx, top_idx]
      labels       <- sample_movies$title[match(ids[top_idx], sample_movies$movie_id)]
      labels[is.na(labels)] <- paste0("M",ids[top_idx][is.na(labels)])

      plot_ly(z=m_plot, x=labels, y=labels, type="heatmap",
              colorscale=list(c(0,"#001f2b"),c(0.5,"#008A82"),c(1,"#00e5d9")),
              colorbar=list(title="Similarity",tickfont=list(color="#8a9bb0")),
              hovertemplate="%{y} ↔ %{x}<br>Sim: %{z:.4f}<extra></extra>") %>%
        layout(title=list(text="Item-Item Similarity Matrix (Top 20 Most Connected)",
                          font=list(color="#d0f0ed",size=13)),
               xaxis=list(title="",color="#8a9bb0",tickangle=-40,tickfont=list(size=10)),
               yaxis=list(title="",color="#8a9bb0",tickfont=list(size=10))) %>%
        plotly_dark_theme()
    })

    output$item_picker <- renderUI({
      sm <- sim_matrix_data()
      choices <- setNames(sm$movie_ids,
                          sample_movies$title[match(sm$movie_ids, sample_movies$movie_id)])
      choices <- choices[!is.na(names(choices))]
      selectInput(ns("selected_item"), "Select movie:", choices=choices)
    })

    nn_result <- eventReactive(input$run_nn, {
      sm  <- sim_matrix_data()
      mid <- as.character(input$selected_item)
      if (is.null(mid) || !mid %in% rownames(sm$sim)) return(NULL)
      row    <- sm$sim[mid, ]
      row[mid] <- 0
      top_k  <- sort(row, decreasing=TRUE)[1:min(input$k_neighbours, sum(row>0))]
      data.frame(
        movie_id  = as.integer(names(top_k)),
        similarity = round(top_k, 4)
      ) %>%
        left_join(sample_movies %>% select(movie_id,title,genre), by="movie_id")
    }, ignoreNULL=FALSE)

    output$nn_result <- renderUI({
      r <- nn_result()
      if (is.null(r) || nrow(r)==0)
        return(div(class="warn-box",
                   HTML("<strong>No neighbours found.</strong> Lower min_overlap or min_sim threshold.")))
      sel_title <- sample_movies$title[sample_movies$movie_id==as.integer(input$selected_item)]
      sel_title <- if(length(sel_title)==0) paste0("Movie ",input$selected_item) else sel_title

      rows <- lapply(seq_len(nrow(r)), function(i)
        tags$tr(tags$td(paste0("#",i)),
                tags$td(r$title[i]), tags$td(r$genre[i]),
                tags$td(tags$strong(r$similarity[i]))))

      plot_df <- r
      p <- plot_ly(plot_df, x=~reorder(title, similarity), y=~similarity,
                   type="bar",
                   marker=list(color=~similarity,
                               colorscale=list(c(0,"#b2dfdb"),c(1,"#008A82"))),
                   hovertemplate="%{x}: %{y:.4f}<extra></extra>") %>%
        layout(title=list(text=paste0("K Nearest Neighbours: ",sel_title),
                          font=list(color="#d0f0ed",size=12)),
               xaxis=list(title="",color="#8a9bb0",tickangle=-30),
               yaxis=list(title="Similarity",color="#8a9bb0",
                          gridcolor="rgba(255,255,255,0.08)"),
               showlegend=FALSE) %>%
        plotly_dark_theme()

      tagList(
        div(class="result-card",
            tags$h5(paste0(nrow(r)," nearest neighbours for '",sel_title,"'")),
            fluidRow(
              column(5,
                     tags$table(class="algo-table",
                                tags$thead(tags$tr(tags$th("#"),tags$th("Movie"),
                                                   tags$th("Genre"),tags$th("Similarity"))),
                                tags$tbody(rows))),
              column(7, renderPlotly(p))
            )
        )
      )
    })
  })
}
