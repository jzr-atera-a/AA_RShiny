# modules/chapter10.R
# Chapter 10: Content-Based Filtering
# Theory + Code Lab: TF-IDF, genre feature vectors, ContentBasedRecs
# Mirrors: builder/lda_model_calculator.py, recs/content_based_recommender.py

chapter10_ui <- function(id) {
  ns <- NS(id)
  tagList(

    div(class = "meta-hero",
        tags$h1("Chapter 10: Content-Based Filtering"),
        tags$h2("TF-IDF, Feature Vectors, and the ContentBasedRecs Pipeline"),
        div(
          span(class = "hero-badge", "TF-IDF"),
          span(class = "hero-badge", "Genre Vectors"),
          span(class = "hero-badge", "User Profile"),
          span(class = "hero-badge", "content_based_recommender.py")
        )
    ),

    fluidRow(
      box(title = "🎯 Chapter Overview", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, div(class = "metric-card", span(class = "metric-value", "No CF"),   span(class = "metric-label", "No User-User Data"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "Profile"), span(class = "metric-label", "Built Per User"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "TF-IDF"), span(class = "metric-label", "Feature Extraction"))),
            column(3, div(class = "metric-card", span(class = "metric-value", "Cold"),    span(class = "metric-label", "Solves New Item")))
          )
      )
    ),

    fluidRow(
      tabBox(width = 12, id = ns("ch10_tabs"),

        # ── THEORY ─────────────────────────────────────────
        tabPanel(title = tagList(icon("book"), " Theory"),
          fluidRow(
            box(title = "📝 What is Content-Based Filtering?", status = "info",
                solidHeader = TRUE, width = 6,
                div(class = "success-box",
                    HTML("<strong>✅ Core Idea:</strong> Recommend items with features similar to
                    items the user already liked. Item metadata drives recommendations — no other
                    users' data required.")),
                br(),
                div(class = "framework-card",
                    tags$h5("How It Works"),
                    tags$p(HTML("<strong>1. Extract features:</strong> Genre, keywords, year, actors")),
                    tags$p(HTML("<strong>2. Build item vectors:</strong> Each movie = feature vector")),
                    tags$p(HTML("<strong>3. Build user profile:</strong> Weighted avg of liked-item vectors")),
                    tags$p(HTML("<strong>4. Score candidates:</strong> Cosine similarity of profile vs item"))
                ),
                br(),
                div(class = "framework-card",
                    tags$h5("Advantages vs CF"),
                    tags$ul(
                      tags$li(HTML("<strong>No cold-start for items:</strong> New item → compute features immediately")),
                      tags$li(HTML("<strong>Explainable:</strong> 'Because you liked Sci-Fi / Nolan films'")),
                      tags$li(HTML("<strong>No sparsity:</strong> Uses metadata, not ratings"))
                    )
                ),
                br(),
                div(class = "warn-box",
                    HTML("<strong>⚠️ Filter Bubble Risk:</strong> Content-based can over-specialise.
                    User who likes action films gets only action films. No serendipity.
                    Hybrid systems (Ch 12) address this."))
            ),
            box(title = "🐍 MovieGEEK: lda_model_calculator.py", status = "warning",
                solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("MovieGEEK Uses LDA for Content Similarity"),
                    tags$p("Trains a Latent Dirichlet Allocation model on movie descriptions.
                    Each movie is represented as a topic distribution vector.
                    Cosine similarity between topic vectors → LdaSimilarity table."),
                    tags$p(HTML("<strong>Python:</strong> gensim LdaModel, ~20 topics, saved to DB as LdaSimilarity objects."))
                ),
                div(class = "framework-card",
                    tags$h5("content_based_recommender.py"),
                    tags$p(HTML("<strong>recommend_items_by_ratings():</strong> Same weighted-sum formula as CF but uses LdaSimilarity instead of item-item cosine.")),
                    tags$p(HTML("<strong>predict_score():</strong> r̂(u,i) = r̄_u + Σ[lda_sim(i,j)·(r_uj − r̄_u)] / Σlda_sim(i,j)")),
                    tags$p("The formula is structurally identical to Ch 8 CF — only the similarity source changes.")
                ),
                br(),
                div(class = "tip-box",
                    HTML("<strong>💡 This Code Lab:</strong> We use genre + year feature vectors
                    instead of LDA (no text corpus available). The mechanics — feature vectors,
                    cosine similarity, weighted-sum prediction — are identical."))
            )
          ),
          fluidRow(
            box(title = "🔤 TF-IDF Explained", status = "success", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("Formula"),
                    tags$p(HTML("<strong>TF(t,d)</strong> = count(t in d) / total_terms(d)")),
                    tags$p(HTML("<strong>IDF(t)</strong> = log(N / docs_containing_t)")),
                    tags$p(HTML("<strong>TF-IDF(t,d)</strong> = TF × IDF")),
                    tags$p("High TF-IDF = term is frequent in this doc but rare across all docs → distinctive.")
                ),
                br(),
                div(class = "framework-card",
                    tags$h5("Movie Example"),
                    tags$p(HTML("'The Matrix' description: <em>'hacker dystopia artificial intelligence simulation'</em>")),
                    tags$p(HTML("<strong>High TF-IDF:</strong> 'hacker', 'simulation', 'dystopia'")),
                    tags$p(HTML("<strong>Low TF-IDF:</strong> 'the', 'is', 'a' (appear everywhere)"))
                )
            ),
            box(title = "📐 User Profile Construction", status = "primary", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("Weighted Average of Liked Item Vectors"),
                    tags$p(HTML("<strong>profile(u) = Σ rating(u,i) × feature_vector(i) / Σ rating(u,i)</strong>")),
                    tags$p("Items rated higher contribute more to the profile.
                    Profile changes as user rates more items.")
                ),
                div(class = "framework-card",
                    tags$h5("Scoring Candidates"),
                    tags$p(HTML("<strong>score(i) = cosine(profile(u), feature_vector(i))</strong>")),
                    tags$p("Items most similar to the user's feature-weighted profile rank highest.")
                ),
                div(class = "tip-box",
                    HTML("<strong>💡 MovieGEEK Equivalent:</strong> ContentBasedRecs uses
                    LdaSimilarity directly rather than computing a profile vector.
                    Both approaches produce the same weighted-sum prediction."))
            )
          )
        ), # end Theory

        # ── CODE LAB ───────────────────────────────────────
        tabPanel(title = tagList(icon("code"), " Code Lab"),

          code_lab_header(
            title    = "ContentBasedRecs — R Implementation",
            subtitle = "Genre + year feature vectors, TF-IDF on synthetic descriptions, cosine similarity matrix, user profile builder, and weighted-sum predictions. Mirrors content_based_recommender.py.",
            badges   = c("R", "dplyr", "mirrors: content_based_recommender.py")
          ),

          # ── Section 1: Feature Matrix ───────────────────
          fluidRow(
            box(title = "🏗️ Step 1 · Build Item Feature Matrix", status = "primary",
                solidHeader = TRUE, width = 4,
                div(class = "section-heading-dark", "Encode genres + year decade into feature vectors"),
                div(class = "control-panel",
                    checkboxGroupInput(ns("feature_types"), "Include feature types:",
                                       choices  = c("Genre (one-hot)"  = "genre",
                                                    "Year decade"      = "year",
                                                    "TF-IDF keywords"  = "tfidf"),
                                       selected = c("genre", "year", "tfidf")),
                    br(),
                    div(class = "section-heading-dark", "Similarity Threshold"),
                    sliderInput(ns("cb_min_sim"), "Min content similarity",
                                min = 0.0, max = 0.8, value = 0.1, step = 0.05),
                    run_button(ns("run_features"), "▶  Build Feature Matrix")
                ),
                br(),
                fluidRow(
                  column(6, div(class = "metric-card",
                                span(class = "metric-value", textOutput(ns("n_features"), inline = TRUE)),
                                span(class = "metric-label", "Feature Dimensions"))),
                  column(6, div(class = "metric-card",
                                span(class = "metric-value", textOutput(ns("n_sim_pairs"), inline = TRUE)),
                                span(class = "metric-label", "Similar Pairs")))
                ),
                br(),
                r_code_block(
'# Build genre feature vectors
# (replaces LDA topic vectors in MovieGEEK)

genres <- unique(sample_movies$genre)

genre_mat <- sapply(genres, function(g)
  as.integer(sample_movies$genre == g))
rownames(genre_mat) <- sample_movies$movie_id

# Year decade encoding
decade_mat <- model.matrix(
  ~ factor(floor(year/10)*10) - 1,
  data = sample_movies)

# Stack feature types
feat_mat <- cbind(genre_mat, decade_mat)

# Cosine similarity → content similarity
sim_mat <- cosine_sim(feat_mat)'
                )
            ),

            box(title = "🗺️ Content Similarity Heatmap", status = "success",
                solidHeader = TRUE, width = 8,
                div(class = "tip-box",
                    HTML("<strong>Reading the map:</strong> Dark teal = high content similarity
                    (same genre + similar era). Items cluster by genre and decade.")),
                plotlyOutput(ns("content_sim_heatmap"), height = "420px")
            )
          ),

          # ── Section 2: TF-IDF explorer ──────────────────
          fluidRow(
            box(title = "🔤 TF-IDF Feature Explorer", status = "warning",
                solidHeader = TRUE, width = 5,
                div(class = "section-heading-dark", "Synthetic movie keywords → TF-IDF weights"),
                div(class = "info-box-plain",
                    HTML("<strong>Note:</strong> We generate synthetic keyword bags from genre + title
                    since no text corpus is available. In MovieGEEK the real plot descriptions
                    from MovieTweetings are used.")),
                div(class = "control-panel",
                    uiOutput(ns("tfidf_movie_picker")),
                    run_button(ns("run_tfidf"), "▶  Show TF-IDF")
                ),
                plotlyOutput(ns("tfidf_plot"), height = "300px"),
                br(),
                r_code_block(
'# TF-IDF from synthetic keywords

# Each movie gets a "description" from
# genre + title words
compute_tfidf <- function(docs) {
  # TF: term freq per document
  # IDF: log(N / df)
  # TF-IDF = TF * IDF
  N  <- length(docs)
  tf <- lapply(docs, function(d) {
    words <- strsplit(d," ")[[1]]
    table(words)/length(words)
  })
  all_terms <- unique(unlist(lapply(tf,names)))
  df <- sapply(all_terms, function(t)
    sum(sapply(tf, function(d) t %in% names(d))))
  idf <- log(N / df)
  # Return tfidf matrix
}'
                )
            ),

            box(title = "👤 Step 2 · User Taste Profile", status = "info",
                solidHeader = TRUE, width = 7,
                div(class = "section-heading-dark",
                    "Build a weighted feature profile from the user's ratings"),
                div(class = "control-panel",
                    fluidRow(
                      column(6, numericInput(ns("profile_user"), "User ID",
                                             value = 1, min = 1, max = 50)),
                      column(6, br(), run_button(ns("run_profile"), "▶  Build Profile"))
                    )
                ),
                uiOutput(ns("profile_summary")),
                br(),
                plotlyOutput(ns("profile_radar"), height = "280px"),
                br(),
                r_code_block(
'# User profile = rating-weighted avg
# of feature vectors for rated items

build_profile <- function(user_id, feat_mat,
                           ratings) {
  user_r <- ratings %>%
    filter(user_id == !!user_id)

  # Rows in feat_mat for rated movies
  ids    <- as.character(user_r$movie_id)
  rows   <- feat_mat[ids, , drop=FALSE]
  wts    <- user_r$rating

  # Weighted average
  profile <- colSums(rows * wts) / sum(wts)
  profile
}'
                )
            )
          ),

          # ── Section 3: Recommendations ──────────────────
          fluidRow(
            box(title = "🎬 Step 3 · Content-Based Recommendations", status = "primary",
                solidHeader = TRUE, width = 6,
                div(class = "section-heading-dark",
                    "Mirrors recommend_items_by_ratings() using content similarity"),
                div(class = "control-panel",
                    fluidRow(
                      column(6, numericInput(ns("cb_user_id"), "User ID",
                                             value = 1, min = 1, max = 50)),
                      column(6, sliderInput(ns("cb_top_n"), "Top-N",
                                            min = 3, max = 15, value = 8))
                    ),
                    run_button(ns("run_cb_recs"), "▶  Recommend")
                ),
                uiOutput(ns("cb_rec_result"))
            ),

            box(title = "🔄 CB vs CF Comparison", status = "success",
                solidHeader = TRUE, width = 6,
                div(class = "section-heading-dark",
                    "Same user, different recommendation logic"),
                div(class = "info-box-plain",
                    HTML("<strong>Content-Based:</strong> Recommends movies in the same genres as
                    what the user rated highly.<br><strong>CF (Ch 8):</strong> Recommends movies
                    that similar users liked — can cross genres (serendipity).")),
                div(class = "control-panel",
                    run_button(ns("run_compare"), "▶  Compare CB vs Popularity")
                ),
                plotlyOutput(ns("cb_vs_pop_plot"), height = "320px")
            )
          )
        ) # end Code Lab
      )
    )
  )
}

chapter10_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    cosine_sm <- function(mat) {
      n <- sqrt(rowSums(mat^2)); n[n < 1e-10] <- 1e-10
      tcrossprod(mat / n)
    }

    # ── Synthetic keyword generator ──────────────────────────
    genre_keywords <- list(
      "Sci-Fi"    = c("space","future","technology","alien","robot","science","universe","planet","cyber","quantum"),
      "Action"    = c("fight","chase","explosion","hero","battle","mission","weapon","danger","escape","combat"),
      "Drama"     = c("family","love","life","struggle","emotion","journey","relationship","hope","truth","loss"),
      "Crime"     = c("murder","detective","suspect","investigation","crime","police","gangster","trial","evidence","heist"),
      "Thriller"  = c("suspense","mystery","danger","twist","secret","tension","chase","fear","escape","unknown"),
      "Romance"   = c("love","heart","relationship","passion","couple","wedding","fate","romance","kiss","desire"),
      "Adventure" = c("quest","treasure","exploration","journey","discover","hero","map","ancient","legend","escape"),
      "Family"    = c("children","magic","friendship","adventure","home","heart","dream","animals","fun","toys"),
      "Horror"    = c("ghost","fear","monster","dark","evil","night","haunt","blood","terror","supernatural"),
      "Comedy"    = c("funny","laugh","humor","silly","prank","misunderstanding","chaos","wit","joke","party")
    )

    make_desc <- function(genre, title) {
      kws <- genre_keywords[[genre]]
      if (is.null(kws)) kws <- c("movie","story","film")
      title_words <- tolower(gsub("[^a-zA-Z ]", "", title))
      title_words <- strsplit(title_words, "\\s+")[[1]]
      title_words <- title_words[nchar(title_words) > 3]
      sample_kws  <- sample(kws, min(6, length(kws)))
      paste(c(sample_kws, title_words), collapse = " ")
    }

    compute_tfidf_mat <- function(docs, movie_ids) {
      doc_words <- lapply(docs, function(d) strsplit(d, "\\s+")[[1]])
      all_terms  <- sort(unique(unlist(doc_words)))
      N          <- length(docs)

      mat <- sapply(all_terms, function(t) {
        tf_vals <- sapply(doc_words, function(w) sum(w == t) / length(w))
        df      <- sum(tf_vals > 0)
        idf     <- log(N / max(df, 1))
        tf_vals * idf
      })
      rownames(mat) <- as.character(movie_ids)
      mat
    }

    # ── Feature matrix ───────────────────────────────────────
    feature_data <- eventReactive(input$run_features, {
      types <- input$feature_types
      mats  <- list()

      if ("genre" %in% types) {
        genres    <- sort(unique(sample_movies$genre))
        genre_mat <- sapply(genres, function(g)
          as.integer(sample_movies$genre == g))
        rownames(genre_mat) <- as.character(sample_movies$movie_id)
        mats[["genre"]] <- genre_mat
      }
      if ("year" %in% types) {
        decades <- sort(unique(floor(sample_movies$year / 10) * 10))
        year_mat <- sapply(decades, function(d)
          as.integer(floor(sample_movies$year / 10) * 10 == d))
        rownames(year_mat) <- as.character(sample_movies$movie_id)
        mats[["year"]] <- year_mat * 0.5   # downweight relative to genre
      }
      if ("tfidf" %in% types) {
        set.seed(42)
        docs <- mapply(make_desc, sample_movies$genre, sample_movies$title)
        tfidf_mat <- compute_tfidf_mat(docs, sample_movies$movie_id)
        # Normalise to 0-1 range
        mx <- max(tfidf_mat); if (mx > 0) tfidf_mat <- tfidf_mat / mx
        mats[["tfidf"]] <- tfidf_mat * 0.5
      }

      if (length(mats) == 0) return(NULL)

      # Align rows
      all_ids <- as.character(sample_movies$movie_id)
      for (nm in names(mats)) {
        m <- mats[[nm]]
        aligned <- matrix(0, nrow = length(all_ids), ncol = ncol(m),
                          dimnames = list(all_ids, colnames(m)))
        common <- intersect(rownames(m), all_ids)
        aligned[common, ] <- m[common, ]
        mats[[nm]] <- aligned
      }

      feat_mat <- do.call(cbind, mats)
      sim_mat  <- cosine_sm(feat_mat)
      diag(sim_mat) <- 0
      sim_mat[sim_mat < input$cb_min_sim] <- 0

      list(feat = feat_mat, sim = sim_mat)
    }, ignoreNULL = FALSE)

    output$n_features  <- renderText(if(!is.null(feature_data())) ncol(feature_data()$feat) else 0)
    output$n_sim_pairs <- renderText(if(!is.null(feature_data())) sum(feature_data()$sim > 0) else 0)

    output$content_sim_heatmap <- renderPlotly({
      fd <- feature_data(); if (is.null(fd)) return(plot_ly() %>% plotly_dark_theme())
      sm <- fd$sim

      # Sort by genre for cleaner clusters
      ord <- order(sample_movies$genre[match(as.integer(rownames(sm)), sample_movies$movie_id)])
      sm_ord <- sm[ord, ord]
      labels <- sample_movies$title[match(as.integer(rownames(sm_ord)), sample_movies$movie_id)]

      plot_ly(z = sm_ord, x = labels, y = labels, type = "heatmap",
              colorscale = list(c(0,"#001f2b"), c(0.5,"#008A82"), c(1,"#00e5d9")),
              colorbar = list(title="Content\nSim", tickfont=list(color="#8a9bb0")),
              hovertemplate = "%{y} ↔ %{x}<br>Sim: %{z:.3f}<extra></extra>") %>%
        layout(title = list(text="Content Similarity Matrix (sorted by genre)",
                            font=list(color="#d0f0ed",size=13)),
               xaxis = list(title="",color="#8a9bb0",tickangle=-45,tickfont=list(size=8)),
               yaxis = list(title="",color="#8a9bb0",tickfont=list(size=8))) %>%
        plotly_dark_theme()
    })

    # ── TF-IDF explorer ──────────────────────────────────────
    output$tfidf_movie_picker <- renderUI({
      selectInput(ns("tfidf_movie"), "Select movie:",
                  choices = setNames(sample_movies$movie_id, sample_movies$title))
    })

    output$tfidf_plot <- renderPlotly({
      input$run_tfidf
      mid   <- as.integer(input$tfidf_movie)
      movie <- sample_movies[sample_movies$movie_id == mid, ]
      set.seed(42)
      desc  <- make_desc(movie$genre, movie$title)
      words <- strsplit(desc, "\\s+")[[1]]
      all_docs <- mapply(make_desc, sample_movies$genre, sample_movies$title)

      tf_doc <- table(words) / length(words)
      df_val <- sapply(names(tf_doc), function(t)
        sum(sapply(all_docs, function(d) t %in% strsplit(d,"\\s+")[[1]])))
      idf_val <- log(length(all_docs) / pmax(df_val, 1))
      tfidf_scores <- as.numeric(tf_doc) * idf_val
      names(tfidf_scores) <- names(tf_doc)
      top_terms <- sort(tfidf_scores, decreasing = TRUE)[1:min(12, length(tfidf_scores))]

      plot_ly(x = names(top_terms), y = top_terms, type = "bar",
              marker = list(color = top_terms,
                            colorscale = list(c(0,"#b2dfdb"),c(1,"#008A82"))),
              hovertemplate = "<b>%{x}</b>: %{y:.4f}<extra></extra>") %>%
        layout(title = list(text = paste0("TF-IDF: ", movie$title),
                            font = list(color="#d0f0ed",size=12)),
               xaxis = list(title="",color="#8a9bb0",tickangle=-30),
               yaxis = list(title="TF-IDF Weight",color="#8a9bb0",
                            gridcolor="rgba(255,255,255,0.08)")) %>%
        plotly_dark_theme()
    })

    # ── User profile ─────────────────────────────────────────
    profile_data <- eventReactive(input$run_profile, {
      uid  <- input$profile_user
      fd   <- feature_data()
      if (is.null(fd)) return(NULL)

      user_r <- sample_ratings %>% filter(user_id == uid)
      if (nrow(user_r) == 0) return(NULL)

      ids  <- as.character(user_r$movie_id)
      avail <- intersect(ids, rownames(fd$feat))
      if (length(avail) == 0) return(NULL)

      rows <- fd$feat[avail, , drop = FALSE]
      wts  <- user_r$rating[match(as.integer(avail), user_r$movie_id)]
      profile <- colSums(rows * wts) / sum(wts)

      # Genre totals for radar
      genres <- sort(unique(sample_movies$genre))
      genre_scores <- sapply(genres, function(g) {
        cols <- grep(paste0("^genre\\.", g, "$"), names(profile), value=TRUE)
        if (length(cols)==0) {
          cols2 <- grep(g, names(profile), fixed=TRUE, value=TRUE)
          if (length(cols2)==0) return(0)
          sum(profile[cols2])
        } else sum(profile[cols])
      })
      names(genre_scores) <- genres

      list(profile=profile, genre_scores=genre_scores, uid=uid,
           n_rated=nrow(user_r), user_r=user_r)
    }, ignoreNULL=FALSE)

    output$profile_summary <- renderUI({
      pd <- profile_data(); if (is.null(pd)) return(NULL)
      top_genre <- names(sort(pd$genre_scores, decreasing=TRUE))[1]
      div(class="result-card",
          tags$h5(paste0("User ", pd$uid, " — Content Profile")),
          fluidRow(
            column(6, div(class="metric-card",
                          span(class="metric-value", pd$n_rated),
                          span(class="metric-label","Rated Items"))),
            column(6, div(class="metric-card",
                          span(class="metric-value", top_genre),
                          span(class="metric-label","Top Genre")))
          )
      )
    })

    output$profile_radar <- renderPlotly({
      pd <- feature_data()
      if (is.null(pd)) return(plot_ly() %>% plotly_dark_theme())
      uid  <- input$profile_user
      user_r <- sample_ratings %>% filter(user_id == uid)
      if (nrow(user_r) == 0) return(plot_ly() %>% plotly_dark_theme())

      # Genre rating averages
      genre_avgs <- user_r %>%
        left_join(sample_movies %>% select(movie_id,genre), by="movie_id") %>%
        group_by(genre) %>%
        summarise(avg_rating=mean(rating), n=n(), .groups="drop") %>%
        arrange(desc(avg_rating))

      plot_ly(genre_avgs, x=~reorder(genre,avg_rating), y=~avg_rating,
              type="bar", marker=list(color=~avg_rating,
                                       colorscale=list(c(0,"#b2dfdb"),c(1,"#008A82"))),
              hovertemplate="<b>%{x}</b>: %{y:.2f} avg<extra></extra>") %>%
        layout(title=list(text=paste0("User ",uid," Genre Preferences (avg rating)"),
                          font=list(color="#d0f0ed",size=12)),
               xaxis=list(title="",color="#8a9bb0",tickangle=-30),
               yaxis=list(title="Avg Rating",color="#8a9bb0",range=c(0,5.5),
                          gridcolor="rgba(255,255,255,0.08)")) %>%
        plotly_dark_theme()
    })

    # ── Content-Based Recommendations ────────────────────────
    cb_recs <- eventReactive(input$run_cb_recs, {
      uid  <- input$cb_user_id
      topn <- input$cb_top_n
      fd   <- feature_data()
      if (is.null(fd)) return(NULL)

      user_r    <- sample_ratings %>% filter(user_id == uid)
      if (nrow(user_r)==0) return(NULL)
      user_mean <- mean(user_r$rating)
      rated_ids <- as.character(user_r$movie_id)

      avail_ids <- setdiff(rownames(fd$sim), rated_ids)
      if (length(avail_ids)==0) return(NULL)

      preds <- sapply(avail_ids, function(cid) {
        sims <- fd$sim[cid, intersect(colnames(fd$sim), rated_ids)]
        sims <- sims[sims > 0]
        if (length(sims)==0) return(NA_real_)
        r_j  <- user_r$rating[match(as.integer(names(sims)), user_r$movie_id)]
        vld  <- !is.na(r_j)
        if (sum(vld)==0) return(NA_real_)
        num  <- sum(sims[vld] * (r_j[vld] - user_mean))
        den  <- sum(abs(sims[vld]))
        if (den==0) return(NA_real_) else user_mean + num/den
      })

      preds <- preds[!is.na(preds)]
      recs  <- data.frame(movie_id=as.integer(names(sort(preds,decreasing=TRUE)[1:min(topn,length(preds))])),
                          prediction=round(sort(preds,decreasing=TRUE)[1:min(topn,length(preds))],3)) %>%
        left_join(sample_movies %>% select(movie_id,title,genre,year), by="movie_id")

      list(recs=recs, uid=uid, user_mean=round(user_mean,2))
    }, ignoreNULL=FALSE)

    output$cb_rec_result <- renderUI({
      r <- cb_recs()
      if (is.null(r) || nrow(r$recs)==0)
        return(div(class="warn-box",HTML("<strong>No recommendations.</strong> Build feature matrix first.")))

      rows <- lapply(seq_len(nrow(r$recs)), function(i)
        tags$tr(tags$td(paste0("#",i)),
                tags$td(r$recs$title[i]),
                tags$td(r$recs$genre[i]),
                tags$td(r$recs$year[i]),
                tags$td(r$recs$prediction[i])))

      div(class="result-card",
          tags$h5(paste0("Content-Based Recs — User ",r$uid,
                         "  (user mean: ",r$user_mean,")")),
          tags$table(class="algo-table",
                     tags$thead(tags$tr(tags$th("#"),tags$th("Movie"),
                                        tags$th("Genre"),tags$th("Year"),
                                        tags$th("Pred."))),
                     tags$tbody(rows)))
    })

    # ── CB vs Popularity comparison ──────────────────────────
    output$cb_vs_pop_plot <- renderPlotly({
      input$run_compare
      uid  <- input$cb_user_id
      fd   <- feature_data()
      if (is.null(fd)) return(plot_ly() %>% plotly_dark_theme())

      user_r    <- sample_ratings %>% filter(user_id==uid)
      user_mean <- if(nrow(user_r)>0) mean(user_r$rating) else 3
      rated_ids <- as.character(user_r$movie_id)
      m         <- mean(sample_ratings$rating); C <- 10

      pop_df <- sample_ratings %>%
        filter(!movie_id %in% as.integer(rated_ids)) %>%
        group_by(movie_id) %>%
        summarise(n=n(),avg=mean(rating),.groups="drop") %>%
        mutate(bayes=(C*m+avg*n)/(C+n)) %>%
        arrange(desc(bayes)) %>% head(10)

      avail_ids <- setdiff(rownames(fd$sim), rated_ids)
      preds_cb  <- sapply(avail_ids, function(cid) {
        sv <- fd$sim[cid, intersect(colnames(fd$sim),rated_ids)]
        sv <- sv[sv>0]; if(length(sv)==0) return(NA_real_)
        r_j <- user_r$rating[match(as.integer(names(sv)),user_r$movie_id)]
        vld <- !is.na(r_j); if(sum(vld)==0) return(NA_real_)
        num<-sum(sv[vld]*(r_j[vld]-user_mean)); den<-sum(abs(sv[vld]))
        if(den==0) NA_real_ else user_mean+num/den
      })
      cb_df <- data.frame(movie_id=as.integer(names(preds_cb)),cb_score=preds_cb) %>%
        filter(!is.na(cb_score)) %>%
        arrange(desc(cb_score)) %>% head(10) %>%
        left_join(sample_movies %>% select(movie_id,title), by="movie_id")

      pop_plot_df <- pop_df %>%
        left_join(sample_movies %>% select(movie_id,title), by="movie_id") %>%
        mutate(strategy="Popularity")

      cb_plot_df <- cb_df %>%
        rename(bayes=cb_score) %>%
        mutate(strategy="Content-Based")

      all_df <- bind_rows(
        pop_plot_df %>% select(title,bayes,strategy),
        cb_plot_df  %>% select(title,bayes,strategy)
      )

      plot_ly(all_df, x=~bayes, y=~reorder(paste0(title," (",strategy,")"),bayes),
              color=~strategy, colors=c("Popularity"="#3b82f6","Content-Based"="#00A39A"),
              type="bar", orientation="h",
              hovertemplate="<b>%{y}</b>: %{x:.3f}<extra></extra>") %>%
        layout(title=list(text=paste0("Top-10: Popularity vs Content-Based (User ",uid,")"),
                          font=list(color="#d0f0ed",size=12)),
               xaxis=list(title="Score",color="#8a9bb0",gridcolor="rgba(255,255,255,0.08)"),
               yaxis=list(title="",color="#8a9bb0",tickfont=list(size=9)),
               legend=list(font=list(color="#8a9bb0")),
               barmode="group") %>%
        plotly_dark_theme()
    })
  })
}
