# modules/chapter8.R
# Chapter 8: Collaborative Filtering in the Neighbourhood
# Theory + Code Lab: Full NeighborhoodBasedRecs in R
# Mirrors: recs/neighborhood_based_recommender.py + builder/item_similarity_calculator.py

chapter8_ui <- function(id) {
  ns <- NS(id)
  tagList(

    div(class="meta-hero",
        tags$h1("Chapter 8: Collaborative Filtering"),
        tags$h2("User-Based and Item-Based CF — The Core Algorithm"),
        div(span(class="hero-badge","Item-Based CF"),
            span(class="hero-badge","User-Based CF"),
            span(class="hero-badge","Weighted-Sum Prediction"),
            span(class="hero-badge","neighborhood_based_recommender.py"))
    ),

    fluidRow(
      box(title="🎯 Chapter Overview", status="primary", solidHeader=TRUE, width=12,
          fluidRow(
            column(3,div(class="metric-card",span(class="metric-value","35%"),span(class="metric-label","Amazon Revenue"))),
            column(3,div(class="metric-card",span(class="metric-value","Item"),span(class="metric-label","Preferred in Production"))),
            column(3,div(class="metric-card",span(class="metric-value","K=15"),span(class="metric-label","MovieGEEK Default Neighbourhood"))),
            column(3,div(class="metric-card",span(class="metric-value","Sparse"),span(class="metric-label","Challenge to Overcome")))
          )
      )
    ),

    fluidRow(
      tabBox(width=12, id=ns("ch8_tabs"),

        # ── THEORY ─────────────────────────────────────────
        tabPanel(title=tagList(icon("book")," Theory"),
          fluidRow(
            box(title="👥 User-Based CF", status="warning", solidHeader=TRUE, width=6,
                div(class="framework-card",
                    tags$h5("Algorithm Steps"),
                    tags$p(HTML("<strong>1.</strong> Compute similarity between target user and all others")),
                    tags$p(HTML("<strong>2.</strong> Select K most similar users (the neighbourhood)")),
                    tags$p(HTML("<strong>3.</strong> Aggregate their ratings for unseen items")),
                    tags$p(HTML("<strong>4.</strong> Return top-N items by predicted score"))
                ),
                div(class="warn-box",
                    HTML("<strong>⚠️ Scaling Problem:</strong> With 1M users you must compare against
                    all 1M every time a recommendation is needed. User preferences also change daily,
                    requiring constant recomputation.")),
                br(),
                div(class="framework-card",
                    tags$h5("Prediction Formula (User-Based)"),
                    tags$p(HTML("<strong>r̂(u,i) = r̄_u + Σ[sim(u,v)·(r_vi - r̄_v)] / Σ|sim(u,v)|</strong>")),
                    tags$p("Adjusts for user bias by using mean-centred ratings. Users who rate everything highly are normalised.")
                )
            ),
            box(title="📦 Item-Based CF (MovieGEEK Standard)", status="success",
                solidHeader=TRUE, width=6,
                div(class="framework-card",
                    tags$h5("Algorithm Steps"),
                    tags$p(HTML("<strong>1.</strong> Pre-compute item-item similarity matrix (offline)")),
                    tags$p(HTML("<strong>2.</strong> For items user rated, retrieve K most similar items")),
                    tags$p(HTML("<strong>3.</strong> Weighted-sum prediction for candidate items")),
                    tags$p(HTML("<strong>4.</strong> Return top-N candidates"))
                ),
                div(class="success-box",
                    HTML("<strong>✅ Why Item-Based Wins:</strong>
                    <ul>
                      <li><strong>Stable:</strong> Item relationships change slowly → pre-compute once</li>
                      <li><strong>Scalable:</strong> Similarity matrix updated nightly, recs served instantly</li>
                      <li><strong>Explainable:</strong> 'Because you watched The Matrix'</li>
                      <li><strong>Amazon:</strong> 35% of sales from item-based CF</li>
                    </ul>")),
                br(),
                div(class="framework-card",
                    tags$h5("Prediction Formula (Item-Based — MovieGEEK)"),
                    tags$p(HTML("<strong>r̂(u,i) = r̄_u + Σ[sim(i,j)·(r_uj - r̄_u)] / Σsim(i,j)</strong>")),
                    tags$p("j ∈ neighbourhood N(i) — items rated by user u that are similar to target item i")
                )
            )
          ),
          fluidRow(
            box(title="🏗️ NeighborhoodBasedRecs Architecture", status="primary",
                solidHeader=TRUE, width=12,
                div(class="info-box-plain",
                    HTML("<strong>MovieGEEK uses item-based CF.</strong> The Similarity table is pre-computed
                    offline by ItemSimilarityMatrixBuilder, then read by NeighborhoodBasedRecs at inference time.")),
                fluidRow(
                  column(4, div(class="framework-card",
                                tags$h5("recommend_items(user_id)"),
                                tags$p("Fetches top-100 ratings for user. Calls recommend_items_by_ratings()."),
                                tags$p("Returns sorted list of (movie_id, prediction_dict) tuples."))),
                  column(4, div(class="framework-card",
                                tags$h5("recommend_items_by_ratings(user_id, ratings)"),
                                tags$p("Core method. Looks up Similarity table for candidates."),
                                tags$p("Applies weighted-sum formula. Returns top-N sorted by predicted rating."))),
                  column(4, div(class="framework-card",
                                tags$h5("predict_score(user_id, item_id)"),
                                tags$p("Predicts a single rating. Used by the evaluator (Ch 9)."),
                                tags$p("Returns 0 if no similar items found for this user.")))
                )
            )
          )
        ), # end Theory

        # ── CODE LAB ───────────────────────────────────────
        tabPanel(title=tagList(icon("code")," Code Lab"),

          code_lab_header(
            title    = "NeighborhoodBasedRecs — R Implementation",
            subtitle = "Full item-based CF pipeline. Build the similarity matrix, generate top-N recommendations, predict individual ratings — all mirroring MovieGEEK exactly.",
            badges   = c("R", "Matrix", "mirrors: neighborhood_based_recommender.py")
          ),

          # ── Step 1: Build model ─────────────────────────
          fluidRow(
            box(title="Step 1 · Build Item Similarity", status="primary",
                solidHeader=TRUE, width=4,
                div(class="section-heading-dark","Mirrors ItemSimilarityMatrixBuilder"),
                div(class="control-panel",
                    sliderInput(ns("cf_min_overlap"), "Min co-raters",
                                min=1, max=10, value=3, step=1),
                    sliderInput(ns("cf_min_sim"),     "Min similarity",
                                min=0.0, max=0.5, value=0.0, step=0.05),
                    checkboxInput(ns("cf_adjusted"),
                                  "Adjusted cosine (normalize per user)", value=TRUE),
                    run_button(ns("run_cf_build"), "▶  Build Model")
                ),
                br(),
                fluidRow(
                  column(6, div(class="metric-card",
                                span(class="metric-value",textOutput(ns("cf_n_items"),inline=TRUE)),
                                span(class="metric-label","Items in Matrix"))),
                  column(6, div(class="metric-card",
                                span(class="metric-value",textOutput(ns("cf_n_pairs"),inline=TRUE)),
                                span(class="metric-label","Similar Pairs")))
                ),
                br(),
                r_code_block(
'# Step 1: Build item similarity
# (offline, run once)

sim_matrix <- build_item_similarity(
  sample_ratings,
  min_overlap = 3,
  min_sim     = 0.0,
  adjusted    = TRUE
)
# Returns: item × item similarity matrix'
                )
            ),

            # ── Step 2: Recommend ─────────────────────────
            box(title="Step 2 · Recommend Items", status="success",
                solidHeader=TRUE, width=8,
                div(class="section-heading-dark","Mirrors recommend_items_by_ratings()"),
                div(class="control-panel",
                    fluidRow(
                      column(4, numericInput(ns("cf_user_id"), "Target User ID",
                                             value=1, min=1, max=50)),
                      column(4, sliderInput(ns("cf_k_neighbours"), "Neighbourhood size (K)",
                                            min=3, max=20, value=15, step=1)),
                      column(4, sliderInput(ns("cf_top_n"), "Top-N recommendations",
                                            min=3, max=15, value=8, step=1))
                    ),
                    run_button(ns("run_cf_recs"), "▶  Generate Recommendations")
                ),
                uiOutput(ns("cf_rec_result"))
            )
          ),

          # ── Step 3: Prediction trace ─────────────────────
          fluidRow(
            box(title="Step 3 · Predict a Single Rating", status="warning",
                solidHeader=TRUE, width=5,
                div(class="section-heading-dark","Mirrors predict_score(user_id, item_id)"),
                div(class="info-box-plain",
                    HTML("<strong>Formula:</strong> r̂(u,i) = r̄_u + Σ[sim(i,j)·(r_uj − r̄_u)] / Σsim(i,j)")),
                div(class="control-panel",
                    fluidRow(
                      column(6, numericInput(ns("pred_user"), "User ID", value=1, min=1, max=50)),
                      column(6, uiOutput(ns("pred_item_picker")))
                    ),
                    run_button(ns("run_predict"), "▶  Predict Rating")
                ),
                uiOutput(ns("prediction_trace")),
                br(),
                r_code_block(
'# predict_score() in R

predict_cf <- function(user_id, item_id,
    ratings, sim_mat, K=15) {

  user_ratings <- ratings %>%
    filter(user_id==!!user_id,
           movie_id!=item_id)
  user_mean <- mean(user_ratings$rating)

  # Get K most similar items
  if (!as.char(item_id) %in%
       rownames(sim_mat)) return(0)

  sims <- sim_mat[as.char(item_id),
    as.char(user_ratings$movie_id)]
  top_k <- sort(sims,dec=TRUE)[1:K]

  r_j <- user_ratings$rating[
    match(as.int(names(top_k)),
          user_ratings$movie_id)]
  num <- sum(top_k * (r_j - user_mean),
             na.rm=TRUE)
  den <- sum(abs(top_k), na.rm=TRUE)
  if (den == 0) return(user_mean)
  user_mean + num/den
}'
                )
            ),

            box(title="📊 User Rating Profile", status="info",
                solidHeader=TRUE, width=7,
                div(class="section-heading-dark","What the target user has already rated"),
                plotlyOutput(ns("user_profile_plot"), height="300px"),
                br(),
                DTOutput(ns("user_ratings_table"))
            )
          )
        ) # end Code Lab
      )
    )
  )
}

chapter8_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # ── Shared helpers ───────────────────────────────────────
    normalize_ratings <- function(x) {
      valid <- !is.na(x)
      if (sum(valid) <= 1) return(rep(0, length(x)))
      xm <- mean(x[valid]); xr <- max(x[valid]) - min(x[valid])
      if (xr == 0) return(rep(0, length(x)))
      res <- (x - xm) / xr; res[!valid] <- 0; res
    }

    cosine_sim_mat <- function(mat) {
      norms <- sqrt(rowSums(mat^2)); norms[norms < 1e-10] <- 1e-10
      mn <- mat / norms; tcrossprod(mn)
    }

    build_sim <- function(ratings, min_ov, min_sim, adj) {
      if (adj) {
        ratings <- ratings %>%
          group_by(user_id) %>%
          mutate(r = normalize_ratings(rating)) %>%
          ungroup()
      } else {
        ratings <- ratings %>% mutate(r = as.numeric(rating))
      }

      # Overlap matrix
      ov_wide <- sample_ratings %>%
        mutate(rated=1L) %>%
        pivot_wider(id_cols=movie_id, names_from=user_id,
                    values_from=rated, values_fill=0L)
      mid_ov <- ov_wide$movie_id
      ov_mat <- as.matrix(ov_wide[,-1])
      ov_sim <- tcrossprod(ov_mat)
      rownames(ov_sim) <- colnames(ov_sim) <- as.character(mid_ov)

      r_wide <- ratings %>%
        select(movie_id, user_id, r) %>%
        pivot_wider(id_cols=movie_id, names_from=user_id,
                    values_from=r, values_fill=0)
      mid_r  <- r_wide$movie_id
      r_mat  <- as.matrix(r_wide[,-1])
      sim_m  <- cosine_sim_mat(r_mat)
      rownames(sim_m) <- colnames(sim_m) <- as.character(mid_r)
      diag(sim_m) <- 0

      common <- intersect(rownames(sim_m), rownames(ov_sim))
      s2 <- sim_m[common, common]; o2 <- ov_sim[common, common]
      s2[o2 < min_ov] <- 0; s2[s2 < min_sim] <- 0; diag(s2) <- 0
      s2
    }

    cf_model <- eventReactive(input$run_cf_build, {
      sm <- build_sim(sample_ratings, input$cf_min_overlap,
                      input$cf_min_sim, input$cf_adjusted)
      sm
    }, ignoreNULL = FALSE)

    output$cf_n_items <- renderText(nrow(cf_model()))
    output$cf_n_pairs <- renderText(sum(cf_model() > 0))

    # ── Recommendations ──────────────────────────────────────
    cf_recs <- eventReactive(input$run_cf_recs, {
      uid  <- input$cf_user_id
      K    <- input$cf_k_neighbours
      topn <- input$cf_top_n
      sm   <- cf_model()

      user_r <- sample_ratings %>%
        filter(user_id == uid) %>%
        arrange(desc(rating))
      if (nrow(user_r) == 0) return(list(recs=data.frame(), user_r=user_r, uid=uid))

      user_mean   <- mean(user_r$rating)
      rated_ids   <- as.character(user_r$movie_id)
      all_item_ids<- rownames(sm)
      candidate_ids <- setdiff(all_item_ids, rated_ids)

      recs <- lapply(candidate_ids, function(cid) {
        sims <- sm[cid, rated_ids]
        sims <- sims[sims > 0]
        if (length(sims) == 0) return(NULL)
        top_sims <- sort(sims, decreasing=TRUE)[1:min(K,length(sims))]
        nbr_ids  <- names(top_sims)
        r_j      <- user_r$rating[match(as.integer(nbr_ids), user_r$movie_id)]
        valid    <- !is.na(r_j)
        if (sum(valid) == 0) return(NULL)
        num <- sum(top_sims[valid] * (r_j[valid] - user_mean))
        den <- sum(abs(top_sims[valid]))
        if (den == 0) return(NULL)
        pred <- user_mean + num / den
        data.frame(movie_id   = as.integer(cid),
                   prediction = round(pred, 3),
                   n_similar  = sum(valid),
                   avg_sim    = round(mean(top_sims[valid]), 4),
                   stringsAsFactors = FALSE)
      })

      recs_df <- do.call(rbind, Filter(Negate(is.null), recs)) %>%
        left_join(sample_movies %>% select(movie_id,title,genre), by="movie_id") %>%
        arrange(desc(prediction)) %>%
        head(topn)

      list(recs=recs_df, user_r=user_r, uid=uid, user_mean=user_mean)
    }, ignoreNULL=FALSE)

    output$cf_rec_result <- renderUI({
      r <- cf_recs()
      if (nrow(r$recs) == 0)
        return(div(class="warn-box",
                   HTML("<strong>No recommendations found.</strong> User may have too few ratings or build the model first.")))

      rows <- lapply(seq_len(nrow(r$recs)), function(i) {
        stars <- paste(rep("⭐", min(5, round(r$recs$prediction[i]))), collapse="")
        tags$tr(tags$td(paste0("#",i)),
                tags$td(r$recs$title[i]),
                tags$td(r$recs$genre[i]),
                tags$td(stars),
                tags$td(r$recs$prediction[i]),
                tags$td(r$recs$n_similar[i]))
      })

      div(class="result-card",
          tags$h5(paste0("Top-",nrow(r$recs)," Recommendations for User ",r$uid,
                         "  (mean rating: ",round(r$user_mean,2),")")),
          tags$table(class="algo-table",
                     tags$thead(tags$tr(tags$th("#"),tags$th("Movie"),tags$th("Genre"),
                                        tags$th("Stars"),tags$th("Pred. Rating"),
                                        tags$th("# Neighbours"))),
                     tags$tbody(rows)))
    })

    # ── Prediction trace ─────────────────────────────────────
    output$pred_item_picker <- renderUI({
      uid  <- input$pred_user
      sm   <- cf_model()
      rated <- sample_ratings %>% filter(user_id==uid) %>% pull(movie_id)
      unseen <- setdiff(as.integer(rownames(sm)), rated)
      choices <- setNames(unseen,
                          sample_movies$title[match(unseen, sample_movies$movie_id)])
      choices <- choices[!is.na(names(choices))]
      if (length(choices)==0) return(tags$p("No unseen items."))
      selectInput(ns("pred_item"), "Target movie:", choices=choices)
    })

    pred_trace <- eventReactive(input$run_predict, {
      uid  <- input$pred_user
      iid  <- as.integer(input$pred_item)
      K    <- 15
      sm   <- cf_model()
      ciid <- as.character(iid)

      user_r    <- sample_ratings %>% filter(user_id==uid, movie_id!=iid)
      user_mean <- mean(user_r$rating)
      if (!ciid %in% rownames(sm)) return(list(pred=0, details=data.frame(), user_mean=user_mean))

      rated_ids <- as.character(user_r$movie_id)
      sims      <- sm[ciid, rated_ids]
      sims      <- sims[sims > 0]
      if (length(sims)==0) return(list(pred=0, details=data.frame(), user_mean=user_mean))

      top_sims <- sort(sims, decreasing=TRUE)[1:min(K, length(sims))]
      nbr_ids  <- as.integer(names(top_sims))
      r_j      <- user_r$rating[match(nbr_ids, user_r$movie_id)]
      r_titles <- sample_movies$title[match(nbr_ids, sample_movies$movie_id)]

      details <- data.frame(
        movie_id   = nbr_ids,
        title      = r_titles,
        similarity = round(top_sims, 4),
        rating     = r_j,
        contribution = round(top_sims * (r_j - user_mean), 4),
        stringsAsFactors=FALSE
      ) %>% filter(!is.na(rating))

      num  <- sum(details$contribution, na.rm=TRUE)
      den  <- sum(abs(details$similarity), na.rm=TRUE)
      pred <- if (den==0) user_mean else user_mean + num/den

      list(pred=round(pred,3), details=details,
           user_mean=round(user_mean,3),
           num=round(num,4), den=round(den,4))
    }, ignoreNULL=FALSE)

    output$prediction_trace <- renderUI({
      r     <- pred_trace()
      iid   <- input$pred_item
      ititle <- sample_movies$title[sample_movies$movie_id==as.integer(iid)]
      ititle <- if(length(ititle)==0) paste0("Movie ",iid) else ititle

      if (nrow(r$details)==0)
        return(div(class="warn-box",
                   HTML("<strong>Cannot predict:</strong> No similar rated items found.")))

      rows <- lapply(seq_len(nrow(r$details)), function(i)
        tags$tr(tags$td(r$details$title[i]),
                tags$td(r$details$similarity[i]),
                tags$td(r$details$rating[i]),
                tags$td(r$details$contribution[i])))

      div(class="result-card",
          tags$h5(paste0("Rating Prediction: User ",input$pred_user," × '",ititle,"'")),
          fluidRow(
            column(4, div(class="metric-card",
                          span(class="metric-value",r$pred),
                          span(class="metric-label","Predicted Rating"))),
            column(4, div(class="metric-card",
                          span(class="metric-value",r$user_mean),
                          span(class="metric-label","User Mean"))),
            column(4, div(class="metric-card",
                          span(class="metric-value",nrow(r$details)),
                          span(class="metric-label","Neighbours Used")))
          ),
          br(),
          div(class="info-box-plain",
              HTML(paste0("<strong>Formula:</strong> ", r$user_mean,
                          " + ", r$num, " / ", r$den,
                          " = <strong>", r$pred, "</strong>"))),
          tags$table(class="algo-table",
                     tags$thead(tags$tr(tags$th("Neighbour"),tags$th("Similarity"),
                                        tags$th("User Rating"),tags$th("Contribution"))),
                     tags$tbody(rows)))
    })

    # ── User profile ─────────────────────────────────────────
    output$user_profile_plot <- renderPlotly({
      uid  <- input$cf_user_id
      user_r <- sample_ratings %>%
        filter(user_id==uid) %>%
        left_join(sample_movies %>% select(movie_id,title,genre), by="movie_id") %>%
        arrange(desc(rating))

      if (nrow(user_r)==0)
        return(plot_ly() %>% plotly_dark_theme())

      plot_ly(user_r, x=~reorder(title,rating), y=~rating,
              color=~genre, type="bar",
              hovertemplate="<b>%{x}</b><br>Rating: %{y}<extra></extra>") %>%
        layout(title=list(text=paste0("User ",uid," — Rated Items"),
                          font=list(color="#d0f0ed",size=12)),
               xaxis=list(title="",color="#8a9bb0",tickangle=-35,tickfont=list(size=9)),
               yaxis=list(title="Rating",color="#8a9bb0",range=c(0,5.5),
                          gridcolor="rgba(255,255,255,0.08)"),
               legend=list(font=list(color="#8a9bb0")),
               showlegend=TRUE) %>%
        plotly_dark_theme()
    })

    output$user_ratings_table <- renderDT({
      uid  <- input$cf_user_id
      user_r <- sample_ratings %>%
        filter(user_id==uid) %>%
        left_join(sample_movies %>% select(movie_id,title,genre), by="movie_id") %>%
        arrange(desc(rating)) %>%
        select(Movie=title, Genre=genre, Rating=rating)
      datatable(user_r, options=list(pageLength=5, dom="frtip"), rownames=FALSE) %>%
        formatStyle("Rating",
                    background=styleColorBar(c(1,5),"#00A39A"),
                    backgroundSize="90% 60%",backgroundRepeat="no-repeat",
                    backgroundPosition="center")
    })
  })
}
