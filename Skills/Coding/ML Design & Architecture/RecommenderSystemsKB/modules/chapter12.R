# modules/chapter12.R
# Chapter 12: Hybrid Recommenders — FWLS
# Mirrors: builder/fwls_calculator.py, recs/fwls_recommender.py

chapter12_ui <- function(id) {
  ns <- NS(id)
  tagList(

    div(class="meta-hero",
        tags$h1("Chapter 12: Hybrid Recommenders"),
        tags$h2("Combining CF and Content-Based with Feature-Weighted Linear Stacking"),
        div(span(class="hero-badge","Weighted Blend"),
            span(class="hero-badge","Switching"),
            span(class="hero-badge","FWLS"),
            span(class="hero-badge","fwls_calculator.py"))),

    fluidRow(
      box(title="🎯 Chapter Overview", status="primary", solidHeader=TRUE, width=12,
          fluidRow(
            column(3,div(class="metric-card",span(class="metric-value","Best"), span(class="metric-label","Of All Worlds"))),
            column(3,div(class="metric-card",span(class="metric-value","3"),    span(class="metric-label","Strategies Built"))),
            column(3,div(class="metric-card",span(class="metric-value","FWLS"),span(class="metric-label","Learned Blend"))),
            column(3,div(class="metric-card",span(class="metric-value","glm"), span(class="metric-label","Blend Method")))))),

    fluidRow(
      tabBox(width=12, id=ns("ch12_tabs"),

        tabPanel(title=tagList(icon("book")," Theory"),
          fluidRow(
            box(title="Why Hybrid?", status="info", solidHeader=TRUE, width=6,
                div(class="success-box",HTML("<strong>Core Insight:</strong> Each algorithm has
                strengths and weaknesses. Hybrids combine strengths while mitigating weaknesses.")),
                br(),
                div(class="framework-card",
                    tags$h5("CF Strengths and Weaknesses"),
                    tags$p(HTML("<strong>+ Serendipity:</strong> Finds cross-genre surprises")),
                    tags$p(HTML("<strong>+ No metadata needed:</strong> Pure behaviour")),
                    tags$p(HTML("<strong>- Cold-start:</strong> Fails for new users/items")),
                    tags$p(HTML("<strong>- Sparsity:</strong> Breaks with few ratings"))),
                div(class="framework-card",
                    tags$h5("Content-Based Strengths and Weaknesses"),
                    tags$p(HTML("<strong>+ New items:</strong> Recommend from day 1")),
                    tags$p(HTML("<strong>+ Explainable:</strong> 'Because you like Sci-Fi'")),
                    tags$p(HTML("<strong>- Filter bubble:</strong> Only recommends same genre")),
                    tags$p(HTML("<strong>- Feature quality:</strong> Garbage in = garbage out")))),
            box(title="Hybrid Design Patterns", status="warning", solidHeader=TRUE, width=6,
                tags$table(class="algo-table",
                  tags$thead(tags$tr(tags$th("Type"),tags$th("Method"),tags$th("Complexity"))),
                  tags$tbody(
                    tags$tr(tags$td(tags$strong("Weighted")),  tags$td("α×CF + (1-α)×CB"),            tags$td("Low")),
                    tags$tr(tags$td(tags$strong("Switching")), tags$td("CF if >N ratings, else CB"),  tags$td("Low")),
                    tags$tr(tags$td(tags$strong("Mixed")),     tags$td("Show both lists together"),   tags$td("Low")),
                    tags$tr(tags$td(tags$strong("Cascade")),   tags$td("CB narrows, CF ranks"),       tags$td("Medium")),
                    tags$tr(tags$td(tags$strong("FWLS")),      tags$td("Learned weights per feature"),tags$td("High")),
                    tags$tr(tags$td(tags$strong("Ensemble")),  tags$td("Stack multiple models"),      tags$td("High")))),
                br(),
                div(class="tip-box",HTML("<strong>Production Reality:</strong> Netflix uses cascade:
                candidate generation (CF), then re-ranking (content + context). Always a learned blend.")),
                br(),
                div(class="framework-card",
                    tags$h5("FWLS Formula (fwls_calculator.py)"),
                    tags$p(HTML("<strong>score = b1*(cb*1) + b2*(cb*n_ratings) + b3*(cf*1) + b4*(cf*n_ratings)</strong>")),
                    tags$p("n_ratings = user activity. Active users get higher CF weight automatically.")))),
          fluidRow(
            box(title="FWLS Architecture", status="success", solidHeader=TRUE, width=12,
                fluidRow(
                  column(4,div(class="framework-card",
                    tags$h5("Step 1: Get base predictions"),
                    tags$p("Run ContentBasedRecs -> r_CB"),
                    tags$p("Run NeighborhoodBasedRecs -> r_CF"))),
                  column(4,div(class="framework-card",
                    tags$h5("Step 2: Build feature matrix X"),
                    tags$p("cb1 = r_CB * 1   (global content weight)"),
                    tags$p("cb2 = r_CB * n_u  (user-weighted content)"),
                    tags$p("cf1 = r_CF * 1   (global CF weight)"),
                    tags$p("cf2 = r_CF * n_u  (user-weighted CF)"))),
                  column(4,div(class="framework-card",
                    tags$h5("Step 3: Learn weights via GLM"),
                    tags$p("lm(actual ~ cb1+cb2+cf1+cf2 - 1)"),
                    tags$p("Coefficients b1..b4 learned from training data"),
                    tags$p("Predict on new items using learned weights"))))))),

        tabPanel(title=tagList(icon("code")," Code Lab"),

          code_lab_header(
            title="Hybrid Recommenders: Weighted Blend, Switching, FWLS",
            subtitle="Three hybrid strategies mirroring fwls_calculator.py. The correlation chart shows on load using item/genre mean ratings as CF/CB proxies, then updates with real model predictions after clicking Run.",
            badges=c("R","lm()","mirrors: fwls_calculator.py")),

          fluidRow(
            box(title="Step 1: Run Base Predictors", status="primary", solidHeader=TRUE, width=4,
                div(class="control-panel",
                    div(class="section-heading-dark","CF Settings"),
                    sliderInput(ns("hyb_cf_k"),"CF neighbourhood K",min=3,max=15,value=8),
                    br(),
                    div(class="section-heading-dark","Content Features"),
                    checkboxGroupInput(ns("hyb_feat"),NULL,
                                       choices=c("Genre"="genre","Year"="year"),
                                       selected=c("genre","year")),
                    br(),
                    div(class="section-heading-dark","Train / Test Split"),
                    sliderInput(ns("hyb_train_pct"),"Training set %",min=50,max=80,value=70,step=10),
                    br(),
                    run_button(ns("run_base_preds"),"Run Base Predictors")),
                br(),
                uiOutput(ns("base_pred_status"))),

            box(title="Prediction Correlation: CF vs Content", status="success", solidHeader=TRUE, width=8,
                div(class="tip-box",HTML("<strong>Why this matters:</strong> Low correlation between
                CF and Content predictions = complementary signals = blending adds real value.
                <em>Chart shows on load. Click Run for real model predictions.</em>")),
                br(),
                plotlyOutput(ns("pred_correlation"), height="320px"))),

          fluidRow(
            box(title="Step 2A: Weighted Blend", status="warning", solidHeader=TRUE, width=4,
                div(class="control-panel",
                    sliderInput(ns("blend_alpha"),"CF weight (alpha)",min=0,max=1,value=0.5,step=0.05),
                    numericInput(ns("blend_user"),"User ID",value=1,min=1,max=50),
                    run_button(ns("run_weighted"),"Get Blended Recs")),
                uiOutput(ns("weighted_result")),
                br(),
                r_code_block(
'# Weighted blend
blend <- function(cf, cb, alpha)
  alpha * cf + (1 - alpha) * cb')),

            box(title="Step 2B: Switching Hybrid", status="info", solidHeader=TRUE, width=4,
                div(class="control-panel",
                    sliderInput(ns("switch_threshold"),"Min ratings threshold",min=2,max=20,value=8),
                    run_button(ns("run_switching"),"Show User Distribution")),
                plotlyOutput(ns("switching_plot"), height="220px"),
                br(),
                r_code_block(
'# Switching strategy
strategy <- ifelse(
  n_ratings >= threshold,
  cf_pred, cb_pred)')),

            box(title="Step 2C: FWLS", status="success", solidHeader=TRUE, width=4,
                div(class="control-panel",
                    numericInput(ns("fwls_user"),"User ID",value=1,min=1,max=50),
                    run_button(ns("run_fwls"),"Train FWLS & Recommend")),
                uiOutput(ns("fwls_coefs")),
                br(),
                r_code_block(
'# FWLS: fwls_calculator.py in R
X <- preds %>% mutate(
  f_cb1=cb*1,  f_cb2=cb*n_u,
  f_cf1=cf*1,  f_cf2=cf*n_u)
m <- lm(actual ~
  f_cb1+f_cb2+f_cf1+f_cf2-1,
  data=X)'))),

          fluidRow(
            box(title="Step 3: All Strategies Compared", status="primary", solidHeader=TRUE, width=12,
                uiOutput(ns("comparison_status")),
                br(),
                DTOutput(ns("hybrid_comparison_table"))))
        )
      )
    )
  )
}

chapter12_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # ── Helpers ─────────────────────────────────────────────────
    norm_r <- function(x) {
      v <- !is.na(x)
      if (sum(v) <= 1) return(rep(0, length(x)))
      xm <- mean(x[v]); xr <- max(x[v]) - min(x[v])
      if (xr == 0) return(rep(0, length(x)))
      res <- (x - xm) / xr; res[!v] <- 0; res
    }

    cos_sm <- function(mat) {
      n <- sqrt(rowSums(mat^2)); n[n < 1e-10] <- 1e-10
      tcrossprod(mat / n)
    }

    build_cf_sim <- function(ratings) {
      adj <- ratings %>%
        group_by(user_id) %>% mutate(r = norm_r(rating)) %>% ungroup()
      ov_wide <- ratings %>% mutate(v=1L) %>%
        pivot_wider(id_cols=movie_id, names_from=user_id, values_from=v, values_fill=0L)
      ov_mat <- tcrossprod(as.matrix(ov_wide[,-1]))
      rownames(ov_mat) <- colnames(ov_mat) <- as.character(ov_wide$movie_id)
      r_wide <- adj %>% select(movie_id,user_id,r) %>%
        pivot_wider(id_cols=movie_id, names_from=user_id, values_from=r, values_fill=0)
      sm <- cos_sm(as.matrix(r_wide[,-1]))
      rownames(sm) <- colnames(sm) <- as.character(r_wide$movie_id); diag(sm) <- 0
      common <- intersect(rownames(sm), rownames(ov_mat))
      sm2 <- sm[common, common]
      sm2[ov_mat[common, common] < 2] <- 0; diag(sm2) <- 0; sm2
    }

    build_cb_sim <- function(feats) {
      if (is.null(feats) || length(feats) == 0) feats <- "genre"
      mats <- list()
      if ("genre" %in% feats) {
        gs <- sort(unique(sample_movies$genre))
        gm <- matrix(0L, nrow(sample_movies), length(gs),
                     dimnames=list(as.character(sample_movies$movie_id), gs))
        for (g in gs) gm[sample_movies$genre == g, g] <- 1L
        mats[["genre"]] <- gm
      }
      if ("year" %in% feats) {
        dec <- sort(unique(floor(sample_movies$year/10)*10))
        ym  <- matrix(0, nrow(sample_movies), length(dec),
                      dimnames=list(as.character(sample_movies$movie_id), as.character(dec)))
        for (d in dec) ym[floor(sample_movies$year/10)*10==d, as.character(d)] <- 0.5
        mats[["year"]] <- ym
      }
      fm <- do.call(cbind, mats)
      sm <- cos_sm(fm); rownames(sm) <- colnames(sm) <- rownames(fm); diag(sm) <- 0; sm
    }

    pred_ws <- function(iid, sim_mat, user_r) {
      tid <- as.character(iid); um <- mean(user_r$rating)
      if (!tid %in% rownames(sim_mat)) return(um)
      rid <- as.character(user_r$movie_id)
      sv  <- sim_mat[tid, intersect(colnames(sim_mat), rid)]; sv <- sv[sv > 0]
      if (length(sv) == 0) return(um)
      r_j <- user_r$rating[match(as.integer(names(sv)), user_r$movie_id)]
      vld <- !is.na(r_j); if (sum(vld) == 0) return(um)
      num <- sum(sv[vld]*(r_j[vld]-um)); den <- sum(abs(sv[vld]))
      if (den == 0) um else um + num/den
    }

    # ── DEMO DATA computed once at startup ──────────────────────
    # Item mean rating = CF proxy (popular items rated highly by many)
    # Genre mean rating = CB proxy (genre quality signal)
    # Simple joins — guaranteed to produce data, no complex matrix ops
    demo_df <- local({
      item_avg  <- sample_ratings %>%
        group_by(movie_id) %>%
        summarise(item_mean = round(mean(rating), 3), .groups="drop")
      genre_avg <- sample_movies %>%
        left_join(sample_ratings, by="movie_id") %>%
        group_by(genre) %>%
        summarise(genre_mean = round(mean(rating, na.rm=TRUE), 3), .groups="drop")
      sample_ratings %>%
        left_join(sample_movies %>% select(movie_id, genre, title), by="movie_id") %>%
        left_join(item_avg,  by="movie_id") %>%
        left_join(genre_avg, by="genre") %>%
        filter(!is.na(item_mean), !is.na(genre_mean)) %>%
        mutate(hover = paste0(title, " | Actual: ", rating,
                              " | Item avg: ", item_mean,
                              " | Genre avg: ", genre_mean))
    })

    # ── Base predictors ──────────────────────────────────────────
    base_data <- eventReactive(input$run_base_preds, {
      set.seed(42)
      tp      <- input$hyb_train_pct / 100
      all_u   <- unique(sample_ratings$user_id)
      train_u <- sample(all_u, round(length(all_u)*tp))
      test_u  <- setdiff(all_u, train_u)
      train_r <- sample_ratings[sample_ratings$user_id %in% train_u, ]
      test_r  <- sample_ratings[sample_ratings$user_id %in% test_u,  ]
      cf_sim  <- build_cf_sim(train_r)
      cb_sim  <- build_cb_sim(input$hyb_feat)

      preds <- lapply(test_u, function(uid) {
        utest  <- test_r[test_r$user_id==uid, ]
        utrain <- train_r[train_r$user_id==uid, ]
        if (nrow(utest)==0 || nrow(utrain)==0) return(NULL)
        n_tr <- nrow(utrain)
        lapply(seq_len(nrow(utest)), function(j) {
          iid  <- utest$movie_id[j]; act <- utest$rating[j]
          cf_p <- pred_ws(iid, cf_sim, utrain)
          cb_p <- pred_ws(iid, cb_sim, utrain)
          data.frame(user_id=uid, movie_id=iid, actual=act,
                     cf_pred=round(cf_p,3), cb_pred=round(cb_p,3), n_train=n_tr)
        }) %>% do.call(rbind, .)
      })
      preds_df <- do.call(rbind, Filter(Negate(is.null), preds))
      if (is.null(preds_df) || nrow(preds_df)==0) return(NULL)
      list(preds=preds_df, cf_sim=cf_sim, cb_sim=cb_sim, train_r=train_r, test_r=test_r)
    }, ignoreNULL=TRUE)

    output$base_pred_status <- renderUI({
      bd <- base_data()
      if (is.null(bd))
        return(div(class="info-box-plain",
                   HTML("Click <strong>Run Base Predictors</strong> above to compute
                   real CF and Content scores.")))
      p      <- bd$preds
      mae_cf <- round(mean(abs(p$actual-p$cf_pred), na.rm=TRUE), 4)
      mae_cb <- round(mean(abs(p$actual-p$cb_pred), na.rm=TRUE), 4)
      tagList(
        fluidRow(
          column(6, div(class="metric-card",
                        span(class="metric-value",mae_cf),
                        span(class="metric-label","CF MAE"))),
          column(6, div(class="metric-card",
                        span(class="metric-value",mae_cb),
                        span(class="metric-label","Content MAE")))),
        br(),
        div(class="success-box",
            HTML(paste0("<strong>Ready.</strong> ", nrow(p),
                        " predictions from ", length(unique(p$user_id)), " test users."))))
    })

    # ── CORRELATION CHART ────────────────────────────────────────
    # Two branches:
    #   A) Before button clicked  -> demo_df (item mean vs genre mean) — always has data
    #   B) After button clicked   -> real CF vs Content predictions from base_data()
    output$pred_correlation <- renderPlotly({

      bd <- base_data()

      if (!is.null(bd) && nrow(bd$preds) > 0) {

        # Branch A: real model predictions
        p <- bd$preds
        p$grp <- cut(p$n_train, breaks=c(0,4,9,Inf),
                     labels=c("New < 5","Mid 5-9","Active 10+"), right=TRUE)
        r_val <- tryCatch(
          round(cor(p$cf_pred, p$cb_pred, use="complete.obs"), 3),
          error=function(e) NA_real_, warning=function(w) NA_real_)
        r_lbl <- if (is.na(r_val)) "N/A" else as.character(r_val)

        plot_ly(p,
                x=~cf_pred, y=~cb_pred,
                type="scatter", mode="markers",
                color=~grp,
                colors=c("New < 5"="#f59e0b","Mid 5-9"="#3b82f6","Active 10+"="#00A39A"),
                marker=list(size=8, opacity=0.75),
                text=~paste0("User ",user_id,
                             " | CF: ",cf_pred," | CB: ",cb_pred,
                             " | Actual: ",actual),
                hovertemplate="%{text}<extra></extra>") %>%
          add_trace(x=c(1,5), y=c(1,5),
                    type="scatter", mode="lines", name="y = x",
                    inherit=FALSE,
                    line=list(color="#fbbf24",dash="dash",width=2),
                    hoverinfo="skip") %>%
          layout(
            title=list(text=paste0("Real CF vs Content (r = ",r_lbl,")"),
                       font=list(color="#d0f0ed",size=13)),
            xaxis=list(title="CF Predicted Rating",color="#8a9bb0",
                       range=c(0.5,5.5),gridcolor="rgba(255,255,255,0.08)"),
            yaxis=list(title="Content Predicted Rating",color="#8a9bb0",
                       range=c(0.5,5.5),gridcolor="rgba(255,255,255,0.08)"),
            annotations=list(list(x=4.5,y=1.3,
                                  text=paste0("<b>r = ",r_lbl,"</b>"),
                                  showarrow=FALSE,
                                  font=list(color="#fbbf24",size=16))),
            legend=list(font=list(color="#8a9bb0"),
                        title=list(text="User activity")),
            height=320) %>%
          plotly_dark_theme()

      } else {

        # Branch B: demo data — item mean vs genre mean, coloured by genre
        p     <- demo_df
        r_val <- tryCatch(
          round(cor(p$item_mean, p$genre_mean, use="complete.obs"), 3),
          error=function(e) NA_real_, warning=function(w) NA_real_)
        r_lbl <- if (is.na(r_val)) "N/A" else as.character(r_val)

        plot_ly(p,
                x=~item_mean, y=~genre_mean,
                type="scatter", mode="markers",
                color=~genre,
                marker=list(size=7, opacity=0.7),
                text=~hover,
                hovertemplate="%{text}<extra></extra>") %>%
          add_trace(x=c(1,5), y=c(1,5),
                    type="scatter", mode="lines", name="y = x",
                    inherit=FALSE,
                    line=list(color="#fbbf24",dash="dash",width=2),
                    hoverinfo="skip") %>%
          layout(
            title=list(
              text=paste0("Demo: Item mean vs Genre mean (r = ",r_lbl,
                          ") — click Run Base Predictors for real CF/CB"),
              font=list(color="#d0f0ed",size=11)),
            xaxis=list(title="Item Mean Rating (CF proxy)",color="#8a9bb0",
                       gridcolor="rgba(255,255,255,0.08)"),
            yaxis=list(title="Genre Mean Rating (Content proxy)",color="#8a9bb0",
                       gridcolor="rgba(255,255,255,0.08)"),
            annotations=list(list(x=4.5,y=min(p$genre_mean)+0.05,
                                  text=paste0("<b>r = ",r_lbl,"</b>"),
                                  showarrow=FALSE,
                                  font=list(color="#fbbf24",size=16))),
            legend=list(font=list(color="#8a9bb0")),
            height=320) %>%
          plotly_dark_theme()
      }
    })

    # ── Weighted blend ───────────────────────────────────────────
    weighted_recs <- eventReactive(input$run_weighted, {
      bd <- base_data(); if (is.null(bd)) return(NULL)
      uid   <- input$blend_user; alpha <- input$blend_alpha
      user_r <- bd$train_r[bd$train_r$user_id==uid, ]
      cands  <- setdiff(sample_movies$movie_id, user_r$movie_id)
      res    <- lapply(cands, function(iid) {
        cf_p <- pred_ws(iid, bd$cf_sim, user_r)
        cb_p <- pred_ws(iid, bd$cb_sim, user_r)
        data.frame(movie_id=iid, CF=round(cf_p,3), CB=round(cb_p,3),
                   Blend=round(alpha*cf_p+(1-alpha)*cb_p,3))
      })
      do.call(rbind, res) %>%
        left_join(sample_movies %>% select(movie_id,title,genre), by="movie_id") %>%
        arrange(desc(Blend)) %>% head(8)
    }, ignoreNULL=FALSE)

    output$weighted_result <- renderUI({
      r <- weighted_recs()
      if (is.null(r) || nrow(r)==0)
        return(div(class="warn-box",HTML("<strong>Run base predictors first.</strong>")))
      rows <- lapply(seq_len(nrow(r)), function(i)
        tags$tr(tags$td(paste0("#",i)), tags$td(r$title[i]),
                tags$td(r$CF[i]), tags$td(r$CB[i]), tags$td(tags$strong(r$Blend[i]))))
      div(class="result-card",
          tags$h5(paste0("Weighted Blend (alpha = ",input$blend_alpha,")")),
          tags$table(class="algo-table",
                     tags$thead(tags$tr(tags$th("#"),tags$th("Movie"),
                                        tags$th("CF"),tags$th("CB"),tags$th("Blend"))),
                     tags$tbody(rows)))
    })

    # ── Switching pie chart ──────────────────────────────────────
    output$switching_plot <- renderPlotly({
      input$run_switching
      thresh <- input$switch_threshold
      uc <- sample_ratings %>% count(user_id) %>%
        mutate(strategy=ifelse(n>=thresh,"CF","Content")) %>% count(strategy)
      plot_ly(uc, labels=~strategy, values=~n, type="pie",
              marker=list(colors=c("#00A39A","#3b82f6")),
              textinfo="label+percent",
              hovertemplate="%{label}: %{value} users<extra></extra>") %>%
        layout(
          title=list(text=paste0("CF vs Content (threshold = ",thresh," ratings)"),
                     font=list(color="#d0f0ed",size=11)),
          legend=list(font=list(color="#8a9bb0")),
          paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)") %>%
        plotly_dark_theme()
    })

    # ── FWLS ─────────────────────────────────────────────────────
    fwls_result <- eventReactive(input$run_fwls, {
      bd <- base_data(); if (is.null(bd)) return(NULL)
      p  <- bd$preds %>% filter(!is.na(cf_pred), !is.na(cb_pred))
      if (nrow(p) < 10) return(NULL)
      p  <- p %>% mutate(f_cb1=cb_pred*1, f_cb2=cb_pred*n_train,
                         f_cf1=cf_pred*1, f_cf2=cf_pred*n_train)
      m  <- tryCatch(lm(actual~f_cb1+f_cb2+f_cf1+f_cf2-1, data=p), error=function(e) NULL)
      if (is.null(m)) return(NULL)
      uid    <- input$fwls_user
      user_r <- bd$train_r[bd$train_r$user_id==uid, ]; n_tr <- nrow(user_r)
      cands  <- setdiff(sample_movies$movie_id, user_r$movie_id)
      recs   <- lapply(cands, function(iid) {
        cf_p <- pred_ws(iid, bd$cf_sim, user_r)
        cb_p <- pred_ws(iid, bd$cb_sim, user_r)
        nd   <- data.frame(f_cb1=cb_p, f_cb2=cb_p*n_tr, f_cf1=cf_p, f_cf2=cf_p*n_tr)
        data.frame(movie_id=iid, CF=round(cf_p,3), CB=round(cb_p,3),
                   FWLS=round(predict(m, newdata=nd),3))
      })
      recs_df <- do.call(rbind, recs) %>%
        left_join(sample_movies %>% select(movie_id,title,genre), by="movie_id") %>%
        arrange(desc(FWLS)) %>% head(8)
      list(recs=recs_df, coefs=round(coef(m),5),
           mae_fwls=round(mean(abs(p$actual-predict(m,p)),na.rm=TRUE),4),
           mae_cf=round(mean(abs(p$actual-p$cf_pred),na.rm=TRUE),4))
    }, ignoreNULL=FALSE)

    output$fwls_coefs <- renderUI({
      r <- fwls_result()
      if (is.null(r))
        return(div(class="info-box-plain",
                   HTML("Run base predictors, then click <strong>Train FWLS</strong>.")))
      cs <- r$coefs
      rows <- lapply(names(cs), function(n)
        tags$tr(tags$td(n), tags$td(tags$strong(cs[n]))))
      tagList(div(class="result-card",
                  tags$h5("FWLS GLM Coefficients"),
                  tags$table(class="algo-table",
                             tags$thead(tags$tr(tags$th("Feature"),tags$th("Weight"))),
                             tags$tbody(rows)),
                  br(),
                  fluidRow(
                    column(6,div(class="metric-card",
                                 span(class="metric-value",r$mae_fwls),
                                 span(class="metric-label","FWLS MAE"))),
                    column(6,div(class="metric-card",
                                 span(class="metric-value",r$mae_cf),
                                 span(class="metric-label","CF MAE")))),
                  br(),
                  div(class=if(r$mae_fwls<r$mae_cf)"success-box" else "warn-box",
                      HTML(if(r$mae_fwls<r$mae_cf)"<strong>FWLS beats CF.</strong>"
                           else "<strong>CF still better — try more data.</strong>"))))
    })

    output$comparison_status <- renderUI({
      bd <- base_data()
      if (is.null(bd))
        return(div(class="warn-box",HTML("<strong>Run base predictors first.</strong>")))
      div(class="success-box",
          HTML("<strong>All strategies ready.</strong> Top 15 candidates shown."))
    })

    output$hybrid_comparison_table <- renderDT({
      bd <- base_data(); if (is.null(bd)) return(datatable(data.frame()))
      uid    <- input$blend_user; alpha <- input$blend_alpha
      thresh <- input$switch_threshold
      user_r <- bd$train_r[bd$train_r$user_id==uid, ]; n_tr <- nrow(user_r)
      cands  <- setdiff(sample_movies$movie_id, user_r$movie_id)
      fm     <- fwls_result()
      m_fwls <- if (!is.null(fm)) {
        p <- bd$preds %>% filter(!is.na(cf_pred),!is.na(cb_pred)) %>%
          mutate(f_cb1=cb_pred, f_cb2=cb_pred*n_train,
                 f_cf1=cf_pred, f_cf2=cf_pred*n_train)
        tryCatch(lm(actual~f_cb1+f_cb2+f_cf1+f_cf2-1, data=p), error=function(e) NULL)
      } else NULL
      rows <- lapply(cands, function(iid) {
        cf_p  <- pred_ws(iid, bd$cf_sim, user_r)
        cb_p  <- pred_ws(iid, bd$cb_sim, user_r)
        sw_p  <- if (n_tr >= thresh) cf_p else cb_p
        fw_p  <- if (!is.null(m_fwls)) {
          nd <- data.frame(f_cb1=cb_p, f_cb2=cb_p*n_tr, f_cf1=cf_p, f_cf2=cf_p*n_tr)
          tryCatch(round(predict(m_fwls, newdata=nd),3), error=function(e) NA_real_)
        } else NA_real_
        data.frame(movie_id=iid, CF=round(cf_p,3), Content=round(cb_p,3),
                   Weighted=round(alpha*cf_p+(1-alpha)*cb_p,3),
                   Switching=round(sw_p,3), FWLS=round(fw_p,3))
      })
      all_df <- do.call(rbind, rows) %>%
        left_join(sample_movies %>% select(movie_id,title,genre), by="movie_id") %>%
        arrange(desc(Weighted)) %>% head(15) %>%
        select(Movie=title, Genre=genre, CF, Content, Weighted, Switching, FWLS)
      datatable(all_df, options=list(pageLength=15,scrollX=TRUE,dom="t"), rownames=FALSE)
    })

  })
}
