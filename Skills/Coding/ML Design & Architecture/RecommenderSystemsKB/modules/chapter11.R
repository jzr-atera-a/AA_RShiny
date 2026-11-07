# modules/chapter11.R
# Chapter 11: Matrix Factorization — FunkSVD
# Theory + Code Lab: Full SGD training loop in R
# Mirrors: builder/matrix_factorization_calculator.py, recs/funksvd_recommender.py

chapter11_ui <- function(id) {
  ns <- NS(id)
  tagList(

    div(class = "meta-hero",
        tags$h1("Chapter 11: Matrix Factorization"),
        tags$h2("FunkSVD — Latent Factors, SGD, and the Netflix Prize Algorithm"),
        div(
          span(class = "hero-badge", "Funk SVD"),
          span(class = "hero-badge", "SGD"),
          span(class = "hero-badge", "Latent Factors"),
          span(class = "hero-badge", "matrix_factorization_calculator.py")
        )
    ),

    fluidRow(
      box(title = "🎯 Chapter Overview", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, div(class="metric-card",span(class="metric-value","Netflix"),span(class="metric-label","Prize Winner"))),
            column(3, div(class="metric-card",span(class="metric-value","R ≈ PQᵀ"),span(class="metric-label","Core Decomposition"))),
            column(3, div(class="metric-card",span(class="metric-value","SGD"),    span(class="metric-label","Training Method"))),
            column(3, div(class="metric-card",span(class="metric-value","Biases"), span(class="metric-label","μ + b_u + b_i")))
          )
      )
    ),

    fluidRow(
      tabBox(width = 12, id = ns("ch11_tabs"),

        # ── THEORY ─────────────────────────────────────────
        tabPanel(title = tagList(icon("book"), " Theory"),
          fluidRow(
            box(title = "🧮 The Core Idea", status = "info", solidHeader = TRUE, width = 6,
                div(class = "success-box",
                    HTML("<strong>✅ Breakthrough:</strong> Decompose the sparse ratings matrix R
                    (users × movies) into two dense matrices P (users × k) and Q (movies × k).
                    Predict any rating as r̂(u,i) = P[u] · Q[i].")),
                br(),
                div(class = "framework-card",
                    tags$h5("The Problem with CF at Scale"),
                    tags$p(HTML("<strong>1M users × 100K items</strong> = 100B potential ratings")),
                    tags$p(HTML("<strong>Sparsity:</strong> Only 0.01% observed")),
                    tags$p("Neighborhood CF requires computing cosine similarity over this sparse matrix.
                    Matrix Factorization compresses it into learned dense representations.")
                ),
                br(),
                div(class = "framework-card",
                    tags$h5("Prediction Formula (with biases)"),
                    tags$p(HTML("<strong>r̂(u,i) = μ + b_u + b_i + P[u] · Q[i]</strong>")),
                    tags$p(HTML("<strong>μ:</strong> Global mean rating")),
                    tags$p(HTML("<strong>b_u:</strong> User bias (generous/harsh rater)")),
                    tags$p(HTML("<strong>b_i:</strong> Item bias (universally liked/disliked)")),
                    tags$p(HTML("<strong>P[u]·Q[i]:</strong> Personalised latent factor interaction"))
                )
            ),
            box(title = "⚙️ Stochastic Gradient Descent", status = "warning",
                solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("The SGD Update Rule"),
                    tags$p(HTML("<strong>err = r_ui − r̂(u,i)</strong>")),
                    tags$p(HTML("<strong>b_u += lr × (err − λ × b_u)</strong>")),
                    tags$p(HTML("<strong>b_i += lr × (err − λ × b_i)</strong>")),
                    tags$p(HTML("<strong>P[u] += lr × (err × Q[i] − λ × P[u])</strong>")),
                    tags$p(HTML("<strong>Q[i] += lr × (err × P[u] − λ × Q[i])</strong>"))
                ),
                div(class = "framework-card",
                    tags$h5("Key Hyperparameters"),
                    tags$p(HTML("<strong>k:</strong> Number of latent factors (50–200 in production)")),
                    tags$p(HTML("<strong>lr:</strong> Learning rate — how fast to update (0.001–0.01)")),
                    tags$p(HTML("<strong>λ:</strong> Regularisation — prevents overfitting (0.001–0.1)")),
                    tags$p(HTML("<strong>epochs:</strong> Passes through all ratings (10–50)"))
                ),
                br(),
                div(class = "tip-box",
                    HTML("<strong>💡 Simon Funk's Innovation:</strong> Train one factor at a time
                    using only observed ratings. No matrix inversion needed. Scales to billions."))
            )
          ),
          fluidRow(
            box(title = "🏗️ MovieGEEK: matrix_factorization_calculator.py", status = "success",
                solidHeader = TRUE, width = 12,
                fluidRow(
                  column(4, div(class="framework-card",
                                tags$h5("initialize_factors()"),
                                tags$p("Creates P (users×k) and Q (items×k) filled with 0.1."),
                                tags$p("Computes global mean. Initialises user_bias and item_bias dicts.")
                  )),
                  column(4, div(class="framework-card",
                                tags$h5("stochastic_gradient_descent()"),
                                tags$p("Iterates over randomised rating indices. Computes error."),
                                tags$p("Updates biases and factor row for each (user, item) pair.")
                  )),
                  column(4, div(class="framework-card",
                                tags$h5("Bug in the book code ⚠️"),
                                tags$p(HTML("<code>elif prediction < 1: prediction = 10</code>")),
                                tags$p("Should be prediction = 1. Our R implementation corrects this.")
                  ))
                )
            )
          )
        ), # end Theory

        # ── CODE LAB ───────────────────────────────────────
        tabPanel(title = tagList(icon("code"), " Code Lab"),

          code_lab_header(
            title    = "FunkSVD — R Implementation",
            subtitle = "Full SGD training loop with user/item biases. Watch the loss curve converge. Explore latent factors. Mirrors matrix_factorization_calculator.py exactly (with the bias bug fixed).",
            badges   = c("R", "matrix", "mirrors: matrix_factorization_calculator.py")
          ),

          # ── Training controls ───────────────────────────
          fluidRow(
            box(title = "⚙️ Training Configuration", status = "primary",
                solidHeader = TRUE, width = 4,
                div(class = "control-panel",
                    div(class="section-heading-dark","Hyperparameters"),
                    sliderInput(ns("mf_k"),      "Latent factors (k)",
                                min=2, max=20, value=5, step=1),
                    sliderInput(ns("mf_lr"),     "Learning rate",
                                min=0.001, max=0.05, value=0.005, step=0.001),
                    sliderInput(ns("mf_reg"),    "Regularisation (λ)",
                                min=0.001, max=0.05, value=0.002, step=0.001),
                    sliderInput(ns("mf_epochs"), "Epochs (passes through data)",
                                min=5, max=40, value=15, step=5),
                    br(),
                    run_button(ns("run_mf_train"), "▶  Train FunkSVD Model")
                ),
                br(),
                uiOutput(ns("mf_train_stats")),
                br(),
                r_code_block(
'# FunkSVD core (mirrors MovieGEEK)
predict_mf <- function(u, i) {
  pq <- sum(P[u,] * Q[i,])
  r  <- global_mean +
        user_bias[u] + item_bias[i] + pq
  pmin(pmax(r, 1), 5)  # clamp (fixed bug)
}

sgd_step <- function(u, i, rating) {
  err <- rating - predict_mf(u, i)
  # Update biases
  user_bias[u] <<- user_bias[u] +
    lr*(err - reg*user_bias[u])
  item_bias[i] <<- item_bias[i] +
    lr*(err - reg*item_bias[i])
  # Update latent factors
  pu <- P[u,]; qi <- Q[i,]
  P[u,] <<- pu + lr*(err*qi - reg*pu)
  Q[i,] <<- qi + lr*(err*pu - reg*qi)
}'
                )
            ),

            box(title = "📈 Training Loss Curve", status = "success",
                solidHeader = TRUE, width = 8,
                div(class = "section-heading-dark",
                    "RMSE per epoch — watch it converge"),
                plotlyOutput(ns("loss_curve"), height = "300px"),
                br(),
                div(class = "info-box-plain",
                    HTML("<strong>What to watch:</strong> Training RMSE should decrease each epoch.
                    If it flattens early → increase epochs. If it oscillates → reduce learning rate.
                    The MovieGEEK code uses early-stopping when improvement < 0.01."))
            )
          ),

          # ── Latent factor visualisation ─────────────────
          fluidRow(
            box(title = "🔍 Latent Factor Explorer", status = "warning",
                solidHeader = TRUE, width = 6,
                div(class = "section-heading-dark",
                    "PCA projection of learned item factors — similar movies cluster together"),
                plotlyOutput(ns("factor_scatter"), height = "350px"),
                br(),
                r_code_block(
'# Visualise latent space with PCA
# Q = item factor matrix (items × k)
pca  <- prcomp(Q_mat, scale.=TRUE)
df   <- data.frame(
  PC1   = pca$x[,1],
  PC2   = pca$x[,2],
  title = movie_titles,
  genre = movie_genres
)
# Items close in factor space →
# similar latent taste profile'
                )
            ),

            box(title = "🗺️ Predicted Rating Heatmap", status = "info",
                solidHeader = TRUE, width = 6,
                div(class = "section-heading-dark",
                    "Full predicted rating matrix — including unobserved cells"),
                div(class = "tip-box",
                    HTML("<strong>This is the power of MF:</strong> We can predict any
                    user-item rating, even ones never observed in training.")),
                plotlyOutput(ns("pred_heatmap"), height = "350px")
            )
          ),

          # ── Recommendations ─────────────────────────────
          fluidRow(
            box(title = "🎬 FunkSVD Recommendations", status = "primary",
                solidHeader = TRUE, width = 6,
                div(class = "section-heading-dark", "Mirrors FunkSVDRecs.recommend_items_by_ratings()"),
                div(class = "control-panel",
                    fluidRow(
                      column(6, numericInput(ns("mf_rec_user"), "User ID",
                                             value=1, min=1, max=50)),
                      column(6, sliderInput(ns("mf_rec_n"), "Top-N",
                                            min=3, max=15, value=8))
                    ),
                    run_button(ns("run_mf_recs"), "▶  Get Recommendations")
                ),
                uiOutput(ns("mf_rec_result"))
            ),

            box(title = "⚖️ Bias Analysis", status = "success",
                solidHeader = TRUE, width = 6,
                div(class = "section-heading-dark",
                    "Learned user and item biases from training"),
                plotlyOutput(ns("bias_plot"), height="320px"),
                br(),
                r_code_block(
'# Biases capture systematic effects:
# Positive b_u → generous rater
# Negative b_u → harsh rater
# Positive b_i → universally loved film
# Negative b_i → universally disliked

# After subtracting biases, latent
# factors capture RELATIVE preferences'
                )
            )
          )
        ) # end Code Lab
      )
    )
  )
}

chapter11_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # ── FunkSVD training ─────────────────────────────────────
    mf_model <- eventReactive(input$run_mf_train, {
      set.seed(42)
      ratings   <- sample_ratings
      k         <- input$mf_k
      lr        <- input$mf_lr
      reg       <- input$mf_reg
      n_epochs  <- input$mf_epochs

      user_ids  <- sort(unique(ratings$user_id))
      item_ids  <- sort(unique(ratings$movie_id))
      u_inx     <- setNames(seq_along(user_ids), as.character(user_ids))
      i_inx     <- setNames(seq_along(item_ids), as.character(item_ids))
      global_mean <- mean(ratings$rating)

      # Initialise (mirrors MovieGEEK: fill with 0.1)
      P <- matrix(0.1, nrow=length(user_ids), ncol=k)
      Q <- matrix(0.1, nrow=length(item_ids), ncol=k)
      user_bias <- rep(0, length(user_ids))
      item_bias <- rep(0, length(item_ids))

      r_mat <- as.matrix(ratings[, c("user_id","movie_id","rating")])
      idx   <- sample(nrow(r_mat))
      loss_history <- numeric(n_epochs)

      for (epoch in seq_len(n_epochs)) {
        for (j in idx) {
          uid  <- r_mat[j,1]; iid <- r_mat[j,2]; rui <- r_mat[j,3]
          u    <- u_inx[as.character(uid)]
          i    <- i_inx[as.character(iid)]
          pq   <- sum(P[u,] * Q[i,])
          pred <- global_mean + user_bias[u] + item_bias[i] + pq
          pred <- max(1, min(5, pred))   # corrected clamp
          err  <- rui - pred

          user_bias[u] <- user_bias[u] + lr*(err - reg*user_bias[u])
          item_bias[i] <- item_bias[i] + lr*(err - reg*item_bias[i])
          pu <- P[u,]; qi <- Q[i,]
          P[u,] <- pu + lr*(err*qi - reg*pu)
          Q[i,] <- qi + lr*(err*pu - reg*qi)
        }

        # Compute RMSE for this epoch
        sq_err <- sapply(seq_len(nrow(r_mat)), function(j) {
          uid <- r_mat[j,1]; iid <- r_mat[j,2]; rui <- r_mat[j,3]
          u <- u_inx[as.character(uid)]; i <- i_inx[as.character(iid)]
          pq <- sum(P[u,]*Q[i,])
          p  <- max(1,min(5, global_mean+user_bias[u]+item_bias[i]+pq))
          (rui - p)^2
        })
        loss_history[epoch] <- sqrt(mean(sq_err))
      }

      rownames(P) <- as.character(user_ids)
      rownames(Q) <- as.character(item_ids)
      names(user_bias) <- as.character(user_ids)
      names(item_bias) <- as.character(item_ids)

      list(P=P, Q=Q, user_bias=user_bias, item_bias=item_bias,
           global_mean=global_mean, loss=loss_history,
           user_ids=user_ids, item_ids=item_ids,
           u_inx=u_inx, i_inx=i_inx, k=k)
    }, ignoreNULL=FALSE)

    output$mf_train_stats <- renderUI({
      m <- mf_model()
      final_rmse <- round(tail(m$loss, 1), 4)
      first_rmse <- round(m$loss[1], 4)
      improvement <- round((first_rmse - final_rmse)/first_rmse*100, 1)
      div(class="result-card",
          tags$h5("Training Complete"),
          fluidRow(
            column(6, div(class="metric-card",
                          span(class="metric-value", final_rmse),
                          span(class="metric-label","Final RMSE"))),
            column(6, div(class="metric-card",
                          span(class="metric-value", paste0(improvement,"%")),
                          span(class="metric-label","RMSE Improvement")))
          )
      )
    })

    output$loss_curve <- renderPlotly({
      m <- mf_model()
      df <- data.frame(epoch=seq_along(m$loss), rmse=m$loss)
      plot_ly(df, x=~epoch, y=~rmse, type="scatter", mode="lines+markers",
              line=list(color="#00A39A",width=2.5),
              marker=list(size=5,color="#00A39A"),
              hovertemplate="Epoch %{x}: RMSE=%{y:.4f}<extra></extra>") %>%
        layout(title=list(text=paste0("FunkSVD Training Loss (k=",m$k,")"),
                          font=list(color="#d0f0ed",size=13)),
               xaxis=list(title="Epoch",color="#8a9bb0",gridcolor="rgba(255,255,255,0.08)"),
               yaxis=list(title="RMSE",color="#8a9bb0",gridcolor="rgba(255,255,255,0.08)")) %>%
        plotly_dark_theme()
    })

    output$factor_scatter <- renderPlotly({
      m <- mf_model()
      Q <- m$Q
      if (ncol(Q) < 2) return(plot_ly() %>% plotly_dark_theme())
      pca <- tryCatch(prcomp(Q, scale.=TRUE), error=function(e) NULL)
      if (is.null(pca)) return(plot_ly() %>% plotly_dark_theme())

      movie_ids_q <- as.integer(rownames(Q))
      genres <- sample_movies$genre[match(movie_ids_q, sample_movies$movie_id)]
      titles <- sample_movies$title[match(movie_ids_q, sample_movies$movie_id)]
      df <- data.frame(PC1=pca$x[,1], PC2=pca$x[,2],
                       genre=genres, title=titles,
                       stringsAsFactors=FALSE)

      plot_ly(df, x=~PC1, y=~PC2, color=~genre, text=~title,
              type="scatter", mode="markers",
              marker=list(size=9,opacity=0.8),
              hovertemplate="<b>%{text}</b><br>PC1:%{x:.2f} PC2:%{y:.2f}<extra></extra>") %>%
        layout(title=list(text="Item Latent Factors (PCA projection)",
                          font=list(color="#d0f0ed",size=12)),
               xaxis=list(title="PC1",color="#8a9bb0",gridcolor="rgba(255,255,255,0.08)"),
               yaxis=list(title="PC2",color="#8a9bb0",gridcolor="rgba(255,255,255,0.08)"),
               legend=list(font=list(color="#8a9bb0"))) %>%
        plotly_dark_theme()
    })

    output$pred_heatmap <- renderPlotly({
      m <- mf_model()
      top_users <- sample_ratings %>% count(user_id,sort=TRUE) %>% head(12) %>% pull(user_id)
      top_items <- sample_ratings %>% count(movie_id,sort=TRUE) %>% head(15) %>% pull(movie_id)

      mat <- matrix(NA_real_, length(top_users), length(top_items))
      for (ui in seq_along(top_users)) {
        for (ii in seq_along(top_items)) {
          uid <- as.character(top_users[ui]); iid <- as.character(top_items[ii])
          if (uid %in% names(m$u_inx) && iid %in% names(m$i_inx)) {
            u <- m$u_inx[uid]; i <- m$i_inx[iid]
            pq   <- sum(m$P[u,]*m$Q[i,])
            pred <- m$global_mean + m$user_bias[u] + m$item_bias[i] + pq
            mat[ui,ii] <- round(max(1,min(5,pred)), 2)
          }
        }
      }

      row_labels <- paste0("U",top_users)
      col_labels <- sample_movies$title[match(top_items, sample_movies$movie_id)]

      plot_ly(z=mat, x=col_labels, y=row_labels, type="heatmap",
              colorscale=list(c(0,"#001f2b"),c(0.5,"#008A82"),c(1,"#00e5d9")),
              zmin=1, zmax=5,
              colorbar=list(title="Pred\nRating",tickfont=list(color="#8a9bb0")),
              hovertemplate="%{y} × %{x}<br>Pred: %{z:.2f}<extra></extra>") %>%
        layout(title=list(text="Predicted Ratings (FunkSVD)",
                          font=list(color="#d0f0ed",size=12)),
               xaxis=list(title="",color="#8a9bb0",tickangle=-40,tickfont=list(size=9)),
               yaxis=list(title="",color="#8a9bb0",tickfont=list(size=10))) %>%
        plotly_dark_theme()
    })

    mf_recs <- eventReactive(input$run_mf_recs, {
      m   <- mf_model()
      uid <- as.character(input$mf_rec_user)
      topn <- input$mf_rec_n
      if (!uid %in% names(m$u_inx)) return(NULL)
      u <- m$u_inx[uid]

      rated <- sample_ratings %>% filter(user_id==as.integer(uid)) %>% pull(movie_id)
      unseen <- setdiff(m$item_ids, rated)

      preds <- sapply(as.character(unseen), function(iid) {
        if (!iid %in% names(m$i_inx)) return(NA_real_)
        i    <- m$i_inx[iid]
        pq   <- sum(m$P[u,]*m$Q[i,])
        pred <- m$global_mean + m$user_bias[u] + m$item_bias[i] + pq
        max(1, min(5, pred))
      })
      preds <- preds[!is.na(preds)]
      top_ids <- as.integer(names(sort(preds,decreasing=TRUE)[1:min(topn,length(preds))]))
      top_preds <- round(sort(preds,decreasing=TRUE)[1:min(topn,length(preds))], 3)

      data.frame(movie_id=top_ids, prediction=top_preds) %>%
        left_join(sample_movies %>% select(movie_id,title,genre), by="movie_id")
    }, ignoreNULL=FALSE)

    output$mf_rec_result <- renderUI({
      r <- mf_recs()
      if (is.null(r) || nrow(r)==0)
        return(div(class="warn-box",HTML("<strong>Train model first.</strong>")))
      rows <- lapply(seq_len(nrow(r)), function(i)
        tags$tr(tags$td(paste0("#",i)), tags$td(r$title[i]),
                tags$td(r$genre[i]), tags$td(r$prediction[i])))
      div(class="result-card",
          tags$h5(paste0("FunkSVD Recs — User ",input$mf_rec_user)),
          tags$table(class="algo-table",
                     tags$thead(tags$tr(tags$th("#"),tags$th("Movie"),
                                        tags$th("Genre"),tags$th("Predicted"))),
                     tags$tbody(rows)))
    })

    output$bias_plot <- renderPlotly({
      m <- mf_model()
      n_show <- min(20, length(m$item_bias))
      ib <- sort(m$item_bias, decreasing=TRUE)
      top_items <- as.integer(names(ib)[c(1:5, (length(ib)-4):length(ib))])
      labels <- sample_movies$title[match(top_items, sample_movies$movie_id)]
      biases <- ib[as.character(top_items)]
      df <- data.frame(title=labels, bias=round(biases,4))

      plot_ly(df, x=~bias, y=~reorder(title,bias), type="bar", orientation="h",
              marker=list(color=~bias,
                          colorscale=list(c(0,"#e74c3c"),c(0.5,"#8a9bb0"),c(1,"#00A39A"))),
              hovertemplate="<b>%{y}</b>: %{x:.4f}<extra></extra>") %>%
        layout(title=list(text="Item Biases (top 5 + bottom 5)",
                          font=list(color="#d0f0ed",size=12)),
               xaxis=list(title="Bias",color="#8a9bb0",gridcolor="rgba(255,255,255,0.08)"),
               yaxis=list(title="",color="#8a9bb0",tickfont=list(size=10)),
               shapes=list(list(type="line",x0=0,x1=0,y0=0,y1=1,yref="paper",
                                line=list(color="#fbbf24",dash="dash",width=1.5)))) %>%
        plotly_dark_theme()
    })
  })
}
