# modules/chapter9.R
# Chapter 9: Evaluating and Testing Your Recommender
# Theory + Code Lab: MAE, RMSE, Precision@K, Recall@K, MAP, Coverage
# Mirrors: evaluator/algorithm_evaluator.py, evaluator/coverage.py, evaluator/evaluation_runner.py

chapter9_ui <- function(id) {
  ns <- NS(id)
  tagList(

    div(class="meta-hero",
        tags$h1("Chapter 9: Evaluating and Testing"),
        tags$h2("MAE, RMSE, Precision@K, Recall@K, MAP, and Coverage"),
        div(span(class="hero-badge","MAE"),
            span(class="hero-badge","Precision@K"),
            span(class="hero-badge","MAP"),
            span(class="hero-badge","algorithm_evaluator.py"))
    ),

    fluidRow(
      box(title="🎯 Chapter Overview", status="primary", solidHeader=TRUE, width=12,
          fluidRow(
            column(3,div(class="metric-card",span(class="metric-value","2"),
                         span(class="metric-label","Metric Categories"))),
            column(3,div(class="metric-card",span(class="metric-value","MAE"),
                         span(class="metric-label","Rating Accuracy"))),
            column(3,div(class="metric-card",span(class="metric-value","MAP"),
                         span(class="metric-label","Ranking Quality"))),
            column(3,div(class="metric-card",span(class="metric-value","Coverage"),
                         span(class="metric-label","Catalogue Reach")))
          )
      )
    ),

    fluidRow(
      tabBox(width=12, id=ns("ch9_tabs"),

        # ── THEORY ─────────────────────────────────────────
        tabPanel(title=tagList(icon("book")," Theory"),
          fluidRow(
            box(title="📏 Rating Accuracy Metrics", status="info",
                solidHeader=TRUE, width=6,
                div(class="success-box",
                    HTML("<strong>✅ Question:</strong> How close is the predicted rating to the actual rating?")),
                br(),
                div(class="framework-card",
                    tags$h5("MAE — Mean Absolute Error"),
                    tags$p(HTML("<strong>MAE = (1/n) Σ|r̂_ui − r_ui|</strong>")),
                    tags$p("Interpretable: 'predictions are off by X stars on average.'"),
                    tags$p(HTML("<strong>Used by:</strong> MeanAverageError class in algorithm_evaluator.py"))
                ),
                div(class="framework-card",
                    tags$h5("RMSE — Root Mean Squared Error"),
                    tags$p(HTML("<strong>RMSE = √[(1/n) Σ(r̂_ui − r_ui)²]</strong>")),
                    tags$p("Penalises large errors more than MAE. Used by Netflix Prize."),
                    tags$p(HTML("<strong>RMSE ≥ MAE</strong> always. Large gap = a few big errors."))
                ),
                br(),
                div(class="warn-box",
                    HTML("<strong>⚠️ Critical Limitation:</strong> MAE and RMSE measure whether you
                    <em>predict</em> ratings well, not whether you <em>recommend</em> the right items.
                    Kim Falk emphasises: offline rating metrics often don't correlate with online success."))
            ),
            box(title="🏆 Ranking Quality Metrics", status="warning",
                solidHeader=TRUE, width=6,
                div(class="success-box",
                    HTML("<strong>✅ Question:</strong> Are the RIGHT items at the TOP of the ranked list?")),
                br(),
                div(class="framework-card",
                    tags$h5("Precision@K"),
                    tags$p(HTML("<strong>P@K = |relevant items in top-K| / K</strong>")),
                    tags$p("Of the K items recommended, what fraction were relevant?")
                ),
                div(class="framework-card",
                    tags$h5("Recall@K"),
                    tags$p(HTML("<strong>R@K = |relevant items in top-K| / |all relevant items|</strong>")),
                    tags$p("Of all items the user liked, what fraction were in the top-K list?")
                ),
                div(class="framework-card",
                    tags$h5("Average Precision@K (AP@K)"),
                    tags$p("Precision computed at each position a relevant item appears, then averaged."),
                    tags$p("Rewards systems that place relevant items early in the list.")
                ),
                div(class="framework-card",
                    tags$h5("MAP — Mean Average Precision"),
                    tags$p(HTML("<strong>MAP = (1/|U|) Σ AP@K(u)</strong>")),
                    tags$p("AP@K averaged over all users. The standard ranking metric in RecSys.")
                )
            )
          ),
          fluidRow(
            box(title="📊 Coverage", status="success", solidHeader=TRUE, width=6,
                div(class="framework-card",
                    tags$h5("Catalogue Coverage"),
                    tags$p(HTML("<strong>Coverage = |recommended items| / |all items|</strong>")),
                    tags$p("What percentage of the catalogue gets recommended to at least one user?"),
                    tags$p("Low coverage = popularity bias. High coverage = long tail is reached.")
                ),
                div(class="tip-box",
                    HTML("<strong>💡 The Accuracy–Coverage Trade-off:</strong>
                    A perfect popularity recommender (recommend only hits) can have high
                    Precision@K but terrible coverage. Good RecSys balance both."))
            ),
            box(title="🏗️ Evaluation Runner Architecture", status="primary",
                solidHeader=TRUE, width=6,
                div(class="framework-card",
                    tags$h5("evaluation_runner.py Flow"),
                    tags$p(HTML("<strong>1.</strong> Load all ratings")),
                    tags$p(HTML("<strong>2.</strong> 70/30 train/test split (by user)")),
                    tags$p(HTML("<strong>3.</strong> Train recommender on training set")),
                    tags$p(HTML("<strong>4.</strong> For each test user: predict ratings or generate top-K recs")),
                    tags$p(HTML("<strong>5.</strong> Compare predictions to held-out test ratings")),
                    tags$p(HTML("<strong>6.</strong> Compute and report metrics"))
                ),
                div(class="warn-box",
                    HTML("<strong>⚠️ Never evaluate on training data.</strong> Algorithms memorise
                    training ratings and will score perfectly. Always use a held-out test set."))
            )
          )
        ), # end Theory

        # ── CODE LAB ───────────────────────────────────────
        tabPanel(title=tagList(icon("code")," Code Lab"),

          code_lab_header(
            title    = "Full Evaluation Suite — R Implementation",
            subtitle = "MAE, RMSE, Precision@K, Recall@K, MAP, and Coverage. Mirrors algorithm_evaluator.py, coverage.py, and evaluation_runner.py. Evaluate any of three recommenders.",
            badges   = c("R", "dplyr", "mirrors: algorithm_evaluator.py + coverage.py")
          ),

          # ── Experiment setup ─────────────────────────────
          fluidRow(
            box(title="⚙️ Evaluation Setup", status="primary",
                solidHeader=TRUE, width=4,
                div(class="control-panel",
                    div(class="section-heading-dark","Train / Test Split"),
                    sliderInput(ns("train_pct"), "Training set size (%)",
                                min=50, max=90, value=70, step=5),
                    br(),
                    div(class="section-heading-dark","Recommender Under Test"),
                    radioButtons(ns("algo_choice"), NULL,
                                 choices=c(
                                   "Popularity (baseline)"        = "popularity",
                                   "Item-Based CF (K neighbours)" = "cf",
                                   "Random (sanity check)"        = "random"
                                 ), selected="cf"),
                    br(),
                    div(class="section-heading-dark","Ranking Metrics"),
                    sliderInput(ns("eval_k"), "K for Precision/Recall@K",
                                min=3, max=20, value=10, step=1),
                    numericInput(ns("min_test_ratings"),
                                 "Min test ratings per user",
                                 value=2, min=1, max=10),
                    br(),
                    div(class="section-heading-dark","CF Settings (if using CF)"),
                    sliderInput(ns("eval_cf_k"), "CF neighbourhood size",
                                min=3, max=20, value=10, step=1),
                    br(),
                    run_button(ns("run_eval"), "▶  Run Evaluation")
                )
            ),

            box(title="📊 Evaluation Results", status="success",
                solidHeader=TRUE, width=8,
                div(class="section-heading-dark","Metric Summary"),
                uiOutput(ns("eval_status")),
                br(),
                uiOutput(ns("eval_metrics_cards")),
                br(),
                div(class="section-heading-dark","Per-User Distribution"),
                plotlyOutput(ns("per_user_plot"), height="280px")
            )
          ),

          # ── Detailed results ─────────────────────────────
          fluidRow(
            box(title="📋 Per-User Breakdown", status="warning",
                solidHeader=TRUE, width=7,
                DTOutput(ns("per_user_table"))
            ),
            box(title="🗂️ Catalogue Coverage", status="info",
                solidHeader=TRUE, width=5,
                div(class="section-heading-dark","Mirrors coverage.py"),
                uiOutput(ns("coverage_result")),
                br(),
                plotlyOutput(ns("coverage_plot"), height="280px"),
                br(),
                r_code_block(
'# coverage.py in R

coverage <- function(recs_list, all_items) {
  recommended <- unique(
    unlist(lapply(recs_list,
      function(r) r$movie_id))
  )
  length(recommended) / length(all_items)
}

# User coverage
user_coverage <- function(recs_list) {
  n_with_recs <- sum(
    sapply(recs_list, nrow) > 0)
  n_with_recs / length(recs_list)
}'
                )
            )
          ),

          # ── Metric explainers ─────────────────────────────
          fluidRow(
            box(title="🔬 Worked Example: AP@K Calculation", status="primary",
                solidHeader=TRUE, width=12,
                div(class="section-heading-dark","Step through Average Precision@K for one user"),
                div(class="control-panel",
                    fluidRow(
                      column(4, uiOutput(ns("apk_user_picker"))),
                      column(4, sliderInput(ns("apk_k"), "K", min=3, max=15, value=10)),
                      column(4, br(), run_button(ns("run_apk"), "▶  Calculate AP@K"))
                    )
                ),
                uiOutput(ns("apk_trace")),
                br(),
                r_code_block(
'# AP@K from algorithm_evaluator.py in R

average_precision_k <- function(recs, actual, K) {
  # recs   = ordered vector of recommended movie_ids
  # actual = vector of relevant (test) movie_ids
  recs <- head(recs, K)
  score <- 0; hits <- 0
  for (i in seq_along(recs)) {
    if (recs[i] %in% actual) {
      hits  <- hits + 1
      score <- score + hits / i  # precision at i
    }
  }
  # Normalise by min(K, |relevant|)
  if (score > 0)
    score / min(K, length(actual))
  else 0
}'
                )
            )
          )
        ) # end Code Lab
      )
    )
  )
}

chapter9_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # ── Helpers ──────────────────────────────────────────────
    normalize_ratings <- function(x) {
      valid <- !is.na(x)
      if (sum(valid)<=1) return(rep(0,length(x)))
      xm <- mean(x[valid]); xr <- max(x[valid])-min(x[valid])
      if (xr==0) return(rep(0,length(x)))
      res <- (x-xm)/xr; res[!valid]<-0; res
    }
    cosine_sm <- function(mat) {
      n <- sqrt(rowSums(mat^2)); n[n<1e-10]<-1e-10; tcrossprod(mat/n)
    }

    ap_at_k <- function(recs, actual, K) {
      recs <- head(recs, K)
      if (length(actual)==0) return(0)
      score <- 0; hits <- 0
      for (i in seq_along(recs)) {
        if (recs[i] %in% actual) { hits <- hits+1; score <- score+hits/i }
      }
      if (score>0) score/min(K,length(actual)) else 0
    }
    recall_at_k <- function(recs, actual, K) {
      if (length(actual)==0) return(0)
      hits <- sum(head(recs,K) %in% actual)
      hits/length(actual)
    }
    precision_at_k <- function(recs, actual, K) {
      if (K==0) return(0)
      sum(head(recs,K) %in% actual)/K
    }

    # ── Main evaluation runner ───────────────────────────────
    eval_results <- eventReactive(input$run_eval, {
      set.seed(42)
      algo       <- input$algo_choice
      train_pct  <- input$train_pct/100
      K          <- input$eval_k
      min_test_r <- input$min_test_ratings
      cf_K       <- input$eval_cf_k

      all_users <- unique(sample_ratings$user_id)
      n_train   <- round(length(all_users)*train_pct)
      train_users <- sample(all_users, n_train)
      test_users  <- setdiff(all_users, train_users)

      train_r <- sample_ratings[sample_ratings$user_id %in% train_users, ]
      test_r  <- sample_ratings[sample_ratings$user_id %in% test_users, ]

      # Build model on training data
      sim_mat <- NULL
      if (algo == "cf") {
        tr_adj <- train_r %>%
          group_by(user_id) %>%
          mutate(r=normalize_ratings(rating)) %>% ungroup()
        ov_wide <- train_r %>% mutate(rated=1L) %>%
          pivot_wider(id_cols=movie_id, names_from=user_id,
                      values_from=rated, values_fill=0L)
        mid_ov  <- ov_wide$movie_id
        ov_m    <- tcrossprod(as.matrix(ov_wide[,-1]))
        rownames(ov_m)<-colnames(ov_m)<-as.character(mid_ov)

        r_wide <- tr_adj %>% select(movie_id,user_id,r) %>%
          pivot_wider(id_cols=movie_id, names_from=user_id,
                      values_from=r, values_fill=0)
        mid_r <- r_wide$movie_id
        r_m   <- as.matrix(r_wide[,-1])
        sm    <- cosine_sm(r_m)
        rownames(sm)<-colnames(sm)<-as.character(mid_r)
        diag(sm)<-0
        common <- intersect(rownames(sm),rownames(ov_m))
        sm2 <- sm[common,common]; ov2 <- ov_m[common,common]
        sm2[ov2<2]<-0; diag(sm2)<-0
        sim_mat <- sm2
      }

      # Popularity baseline built on training data
      pop_recs_base <- train_r %>%
        group_by(movie_id) %>%
        summarise(n=n(), avg=mean(rating), .groups="drop") %>%
        mutate(bayes=(10*mean(train_r$rating)+avg*n)/(10+n)) %>%
        arrange(desc(bayes))

      per_user <- lapply(test_users, function(uid) {
        user_test  <- test_r[test_r$user_id==uid, ]
        user_train <- train_r[train_r$user_id==uid, ]

        if (nrow(user_test) < min_test_r) return(NULL)

        rated_train <- user_test$movie_id  # items in test set = "relevant"
        train_ids   <- user_train$movie_id

        # Generate recs
        if (algo == "popularity") {
          recs_ordered <- pop_recs_base %>%
            filter(!movie_id %in% train_ids) %>%
            pull(movie_id)

        } else if (algo=="cf" && !is.null(sim_mat)) {
          user_mean <- if(nrow(user_train)>0) mean(user_train$rating) else 3
          train_str <- as.character(train_ids)
          avail     <- intersect(rownames(sim_mat), as.character(setdiff(sample_movies$movie_id, train_ids)))
          if (length(avail)==0) return(NULL)

          preds <- sapply(avail, function(cid) {
            sv <- sim_mat[cid, intersect(colnames(sim_mat), train_str)]
            sv <- sv[sv>0]
            if (length(sv)==0) return(user_mean)
            top_k <- sort(sv,dec=TRUE)[1:min(cf_K,length(sv))]
            nms   <- as.integer(names(top_k))
            r_j   <- user_train$rating[match(nms, user_train$movie_id)]
            vld   <- !is.na(r_j)
            if (sum(vld)==0) return(user_mean)
            num <- sum(top_k[vld]*(r_j[vld]-user_mean))
            den <- sum(abs(top_k[vld]))
            if (den==0) return(user_mean) else user_mean+num/den
          })
          recs_ordered <- as.integer(names(sort(preds, decreasing=TRUE)))

        } else {
          # Random
          recs_ordered <- sample(setdiff(sample_movies$movie_id, train_ids))
        }

        # Predict scores for MAE/RMSE (using training ratings or popularity)
        mae_vals <- sapply(seq_len(nrow(user_test)), function(j) {
          iid   <- user_test$movie_id[j]
          act   <- user_test$rating[j]
          if (algo=="popularity") {
            item_row <- pop_recs_base[pop_recs_base$movie_id==iid, ]
            pred <- if(nrow(item_row)>0) item_row$bayes[1] else mean(train_r$rating)
          } else if (algo=="cf" && !is.null(sim_mat)) {
            ciid <- as.character(iid)
            um   <- if(nrow(user_train)>0) mean(user_train$rating) else 3
            if (!ciid %in% rownames(sim_mat)) return(abs(act - um))
            sv   <- sim_mat[ciid, intersect(colnames(sim_mat), as.character(train_ids))]
            sv   <- sv[sv>0]
            if (length(sv)==0) return(abs(act - um))
            top_k<- sort(sv,dec=TRUE)[1:min(cf_K,length(sv))]
            nms  <- as.integer(names(top_k))
            r_j  <- user_train$rating[match(nms, user_train$movie_id)]
            vld  <- !is.na(r_j)
            if (sum(vld)==0) return(abs(act-um))
            num  <- sum(top_k[vld]*(r_j[vld]-um))
            den  <- sum(abs(top_k[vld]))
            pred <- if(den==0) um else um+num/den
          } else {
            pred <- mean(train_r$rating)
          }
          abs(act - pred)
        })

        ap  <- ap_at_k(recs_ordered, rated_train, K)
        rec <- recall_at_k(recs_ordered, rated_train, K)
        pre <- precision_at_k(recs_ordered, rated_train, K)
        mae_user <- mean(mae_vals, na.rm=TRUE)

        list(
          uid         = uid,
          ap          = ap,
          recall      = rec,
          precision   = pre,
          mae         = mae_user,
          rmse_sq     = mean(mae_vals^2, na.rm=TRUE),
          n_test      = nrow(user_test),
          recs_movie_ids = recs_ordered
        )
      })

      per_user <- Filter(Negate(is.null), per_user)
      if (length(per_user)==0) return(NULL)

      df <- data.frame(
        user_id   = sapply(per_user, `[[`, "uid"),
        ap        = sapply(per_user, `[[`, "ap"),
        recall    = sapply(per_user, `[[`, "recall"),
        precision = sapply(per_user, `[[`, "precision"),
        mae       = sapply(per_user, `[[`, "mae"),
        rmse_sq   = sapply(per_user, `[[`, "rmse_sq"),
        n_test    = sapply(per_user, `[[`, "n_test")
      )

      # Coverage
      all_recs       <- unlist(lapply(per_user, `[[`, "recs_movie_ids"))
      item_coverage  <- length(unique(all_recs)) / nrow(sample_movies)
      user_coverage  <- mean(sapply(per_user, function(x) length(x$recs_movie_ids)>0))

      list(df=df, item_cov=item_coverage, user_cov=user_coverage,
           algo=algo, K=K,
           train_n=nrow(train_r), test_n=nrow(test_r),
           n_test_users=length(per_user),
           per_user_raw=per_user,
           pop_recs=pop_recs_base)
    }, ignoreNULL=FALSE)

    output$eval_status <- renderUI({
      r <- eval_results()
      if (is.null(r))
        return(div(class="warn-box",HTML("<strong>No results.</strong> Not enough data for split.")))
      div(class="success-box",
          HTML(paste0("<strong>✅ Evaluation complete.</strong> Train: ", r$train_n,
                      " ratings | Test: ", r$test_n, " ratings | ",
                      r$n_test_users, " test users evaluated | Algorithm: ",
                      toupper(r$algo))))
    })

    output$eval_metrics_cards <- renderUI({
      r <- eval_results(); if(is.null(r)) return(NULL)
      df <- r$df
      map  <- round(mean(df$ap,na.rm=TRUE),4)
      mrec <- round(mean(df$recall,na.rm=TRUE),4)
      mpre <- round(mean(df$precision,na.rm=TRUE),4)
      mae  <- round(mean(df$mae,na.rm=TRUE),4)
      rmse <- round(sqrt(mean(df$rmse_sq,na.rm=TRUE)),4)
      fluidRow(
        column(2,div(class="metric-card",span(class="metric-value",map),
                     span(class="metric-label",paste0("MAP@",r$K)))),
        column(2,div(class="metric-card",span(class="metric-value",mpre),
                     span(class="metric-label",paste0("Precision@",r$K)))),
        column(2,div(class="metric-card",span(class="metric-value",mrec),
                     span(class="metric-label",paste0("Recall@",r$K)))),
        column(2,div(class="metric-card",span(class="metric-value",mae),
                     span(class="metric-label","MAE"))),
        column(2,div(class="metric-card",span(class="metric-value",rmse),
                     span(class="metric-label","RMSE"))),
        column(2,div(class="metric-card",
                     span(class="metric-value",paste0(round(r$item_cov*100,1),"%")),
                     span(class="metric-label","Item Coverage")))
      )
    })

    output$per_user_plot <- renderPlotly({
      r <- eval_results(); if(is.null(r)) return(plot_ly() %>% plotly_dark_theme())
      df <- r$df
      plot_ly(df, x=~ap, type="histogram", nbinsx=20,
              marker=list(color="#00A39A",line=list(color="#007a72",width=1)),
              hovertemplate="AP@K %{x:.3f}: %{y} users<extra></extra>") %>%
        layout(title=list(text=paste0("Distribution of AP@",r$K," Across Users"),
                          font=list(color="#d0f0ed",size=12)),
               xaxis=list(title=paste0("AP@",r$K),color="#8a9bb0",
                          gridcolor="rgba(255,255,255,0.08)"),
               yaxis=list(title="Users",color="#8a9bb0",
                          gridcolor="rgba(255,255,255,0.08)")) %>%
        plotly_dark_theme()
    })

    output$per_user_table <- renderDT({
      r <- eval_results(); if(is.null(r)) return(datatable(data.frame()))
      display <- r$df %>%
        mutate(rmse=round(sqrt(rmse_sq),4)) %>%
        select(User=user_id,`AP@K`=ap,`P@K`=precision,`R@K`=recall,
               MAE=mae,RMSE=rmse,`Test Ratings`=n_test) %>%
        arrange(desc(`AP@K`))
      datatable(display, options=list(pageLength=10,scrollX=TRUE,dom="frtip"),
                rownames=FALSE) %>%
        formatStyle("AP@K",
                    background=styleColorBar(c(0,1),"#00A39A"),
                    backgroundSize="95% 55%",backgroundRepeat="no-repeat",
                    backgroundPosition="center")
    })

    output$coverage_result <- renderUI({
      r <- eval_results(); if(is.null(r)) return(NULL)
      tagList(
        fluidRow(
          column(6,div(class="metric-card",
                       span(class="metric-value",paste0(round(r$item_cov*100,1),"%")),
                       span(class="metric-label","Item Coverage"))),
          column(6,div(class="metric-card",
                       span(class="metric-value",paste0(round(r$user_cov*100,1),"%")),
                       span(class="metric-label","User Coverage")))
        ),
        br(),
        div(class=if(r$item_cov>0.3)"success-box" else "warn-box",
            HTML(paste0(if(r$item_cov>0.3)"<strong>✅ Reasonable coverage.</strong>"
                        else "<strong>⚠️ Low coverage — popularity bias likely.</strong>",
                        " Recommending ",round(r$item_cov*nrow(sample_movies)),
                        " of ",nrow(sample_movies)," items.")))
      )
    })

    output$coverage_plot <- renderPlotly({
      r <- eval_results(); if(is.null(r)) return(plot_ly() %>% plotly_dark_theme())
      all_recs <- unlist(lapply(r$per_user_raw, `[[`, "recs_movie_ids"))
      rec_counts <- table(factor(all_recs, levels=sample_movies$movie_id))
      df_cov <- data.frame(
        movie_id = as.integer(names(rec_counts)),
        times_rec = as.integer(rec_counts)
      ) %>%
        left_join(sample_movies %>% select(movie_id,title), by="movie_id") %>%
        arrange(desc(times_rec))

      plot_ly(df_cov, x=~times_rec, type="histogram", nbinsx=20,
              marker=list(color=~times_rec,
                          colorscale=list(c(0,"#b2dfdb"),c(1,"#008A82"))),
              hovertemplate="Rec'd %{x} times: %{y} movies<extra></extra>") %>%
        layout(title=list(text="How Often Each Item is Recommended",
                          font=list(color="#d0f0ed",size=12)),
               xaxis=list(title="Times Recommended",color="#8a9bb0",
                          gridcolor="rgba(255,255,255,0.08)"),
               yaxis=list(title="# Movies",color="#8a9bb0",
                          gridcolor="rgba(255,255,255,0.08)")) %>%
        plotly_dark_theme()
    })

    output$apk_user_picker <- renderUI({
      r <- eval_results()
      if (is.null(r)) return(tags$p("Run evaluation first."))
      choices <- setNames(r$df$user_id, paste0("User ", r$df$user_id,
                                                " (AP@K=", round(r$df$ap,3),")"))
      selectInput(ns("apk_user"), "Select a test user:", choices=choices)
    })

    apk_trace <- eventReactive(input$run_apk, {
      r   <- eval_results(); if(is.null(r)) return(NULL)
      uid <- as.integer(input$apk_user)
      K   <- input$apk_k

      user_raw  <- Filter(function(x) x$uid==uid, r$per_user_raw)
      if(length(user_raw)==0) return(NULL)
      user_raw  <- user_raw[[1]]

      relevant  <- sample_ratings %>%
        filter(user_id==uid) %>% pull(movie_id)
      recs_k    <- head(user_raw$recs_movie_ids, K)
      hits      <- recs_k %in% relevant
      cum_prec  <- cumsum(hits) / seq_along(hits)
      score     <- 0; running <- 0
      for (i in seq_along(recs_k)) {
        if (hits[i]) { running<-running+1; score<-score+running/i }
      }
      ap_final <- if(score>0) score/min(K,length(relevant)) else 0

      titles <- sample_movies$title[match(recs_k, sample_movies$movie_id)]
      titles[is.na(titles)] <- paste0("Movie ",recs_k[is.na(titles)])

      list(uid=uid, K=K, recs=recs_k, titles=titles,
           hits=hits, cum_prec=cum_prec, ap=round(ap_final,4),
           n_relevant=length(relevant))
    }, ignoreNULL=FALSE)

    output$apk_trace <- renderUI({
      tr <- apk_trace(); if(is.null(tr)) return(NULL)

      rows <- lapply(seq_along(tr$recs), function(i)
        tags$tr(
          style=if(tr$hits[i])"background:#e8f5e9;" else "",
          tags$td(paste0("#",i)),
          tags$td(tr$titles[i]),
          tags$td(if(tr$hits[i]) "✅ Relevant" else "❌ Not relevant"),
          tags$td(round(tr$cum_prec[i],4)),
          tags$td(if(tr$hits[i]) paste0(sum(tr$hits[1:i]),"/",i) else "—")
        ))

      tagList(
        fluidRow(
          column(7,
            div(class="result-card",
                tags$h5(paste0("AP@",tr$K," trace for User ",tr$uid)),
                tags$p(style="font-size:11.5px;color:#546e7a;",
                       paste0("User has ",tr$n_relevant," relevant items. ",
                              "Showing top-",tr$K," recommendations.")),
                tags$table(class="algo-table",
                           tags$thead(tags$tr(tags$th("Pos"),tags$th("Movie"),
                                              tags$th("Relevant?"),tags$th("Precision@i"),
                                              tags$th("Hits/i"))),
                           tags$tbody(rows)),
                br(),
                div(class="success-box",
                    HTML(paste0("<strong>AP@",tr$K," = ",tr$ap,"</strong>")))
            )
          ),
          column(5,
            renderPlotly({
              plot_ly(x=seq_along(tr$cum_prec), y=tr$cum_prec,
                      type="scatter", mode="lines+markers",
                      line=list(color="#00A39A",width=2.5),
                      marker=list(color=ifelse(tr$hits,"#00A39A","#546e7a"),size=8),
                      hovertemplate="Position %{x}: P = %{y:.4f}<extra></extra>") %>%
                layout(title=list(text="Precision at Each Position",
                                  font=list(color="#d0f0ed",size=11)),
                       xaxis=list(title="Position",color="#8a9bb0",
                                  gridcolor="rgba(255,255,255,0.08)"),
                       yaxis=list(title="Precision",color="#8a9bb0",range=c(0,1.05),
                                  gridcolor="rgba(255,255,255,0.08)")) %>%
                plotly_dark_theme()
            })
          )
        )
      )
    })
  })
}
