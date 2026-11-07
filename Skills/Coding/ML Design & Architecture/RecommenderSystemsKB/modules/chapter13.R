# modules/chapter13.R
# Chapter 13: Learning to Rank — Bayesian Personalized Ranking (BPR)
# Theory + Code Lab: Full BPR training loop in R
# Mirrors: builder/bpr_calculator.py, recs/bpr_recommender.py

chapter13_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
        tags$h1("Chapter 13: Learning to Rank"),
        tags$h2("BPR — Pairwise Ranking from Implicit Feedback"),
        div(span(class="hero-badge","BPR"),
            span(class="hero-badge","Pairwise"),
            span(class="hero-badge","Implicit Feedback"),
            span(class="hero-badge","bpr_calculator.py"))
    ),
    fluidRow(
      box(title="🎯 Chapter Overview", status="primary", solidHeader=TRUE, width=12,
          fluidRow(
            column(3,div(class="metric-card",span(class="metric-value","Order"),span(class="metric-label","Matters More Than Score"))),
            column(3,div(class="metric-card",span(class="metric-value","Triples"),span(class="metric-label","(u, i+, i-)"))),
            column(3,div(class="metric-card",span(class="metric-value","AUC"),span(class="metric-label","Optimisation Target"))),
            column(3,div(class="metric-card",span(class="metric-value","Implicit"),span(class="metric-label","No Ratings Needed")))
          )
      )
    ),
    fluidRow(
      tabBox(width=12, id=ns("ch13_tabs"),
        tabPanel(title=tagList(icon("book")," Theory"),
          fluidRow(
            box(title="📊 Why Ranking > Rating Prediction", status="info",
                solidHeader=TRUE, width=6,
                div(class="success-box",HTML("<strong>Key Insight:</strong> The user sees a ranked list, not predicted ratings. Whether item is rank 1 vs rank 2 matters more than predicted score difference.")),
                br(),
                div(class="framework-card",
                    tags$h5("Position Bias in Practice"),
                    tags$p(HTML("<strong>Position 1:</strong> ~30% CTR")),
                    tags$p(HTML("<strong>Position 2:</strong> ~15% CTR")),
                    tags$p(HTML("<strong>Position 5:</strong> ~3% CTR")),
                    tags$p("Optimising RMSE doesn't capture this. BPR does.")),
                br(),
                div(class="framework-card",
                    tags$h5("Implicit Feedback Reality"),
                    tags$p("Most platforms have clicks/views, not star ratings."),
                    tags$p(HTML("<strong>BPR assumption:</strong> item i was interacted with means user prefers i over random unobserved item j")))
            ),
            box(title="🎯 BPR: The Algorithm", status="warning", solidHeader=TRUE, width=6,
                div(class="framework-card",
                    tags$h5("BPR Criterion (Rendle et al., 2009)"),
                    tags$p(HTML("<strong>Maximize:</strong> Σ ln σ(x̂_uij) − λ||Θ||²")),
                    tags$p(HTML("<strong>x̂_uij = r̂_ui − r̂_uj</strong> — score difference")),
                    tags$p(HTML("<strong>σ:</strong> sigmoid function"))),
                div(class="framework-card",
                    tags$h5("SGD Update for Triple (u, i+, i-)"),
                    tags$p(HTML("<strong>z = σ(−x̂_uij)</strong> — gradient weight")),
                    tags$p(HTML("<strong>P[u] += lr·(Q[i+]−Q[i−])·z − λ_u·P[u]</strong>")),
                    tags$p(HTML("<strong>Q[i+] += lr·P[u]·z − λ_i·Q[i+]</strong>")),
                    tags$p(HTML("<strong>Q[i−] += lr·(−P[u]·z) − λ_i·Q[i−]</strong>"))),
                div(class="tip-box",
                    HTML("<strong>Key Difference from MF (Ch 11):</strong> MF minimises squared rating error. BPR maximises probability of correct pairwise orderings."))
            )
          ),
          fluidRow(
            box(title="🏗️ MovieGEEK: bpr_calculator.py", status="success",
                solidHeader=TRUE, width=12,
                fluidRow(
                  column(3,div(class="framework-card",tags$h5("initialize_factors()"),
                               tags$p("Random init P (users×k) and Q (items×k). Builds user_movies dict."))),
                  column(3,div(class="framework-card",tags$h5("draw(n)"),
                               tags$p("Yields (u, i+, i−) triples. Samples negative from all unobserved items."))),
                  column(3,div(class="framework-card",tags$h5("step(u, i, j)"),
                               tags$p("One SGD step. Computes sigmoid of score diff. Updates P, Q_i, Q_j, biases."))),
                  column(3,div(class="framework-card",tags$h5("loss()"),
                               tags$p("BPR-Opt: Σ log(σ(x_uij)) + regularisation.")))
                )
            )
          )
        ),
        tabPanel(title=tagList(icon("code")," Code Lab"),
          code_lab_header(
            title="BPR — R Implementation",
            subtitle="Full pairwise training loop. Samples (u, i+, i−) triples from implicit feedback. Tracks BPR loss and AUC. Compares BPR vs popularity ranking.",
            badges=c("R","matrix","mirrors: bpr_calculator.py")
          ),
          fluidRow(
            box(title="⚙️ Training Configuration", status="primary",
                solidHeader=TRUE, width=4,
                div(class="control-panel",
                    div(class="section-heading-dark","BPR Hyperparameters"),
                    sliderInput(ns("bpr_k"),   "Latent factors (k)", min=2, max=15, value=5),
                    sliderInput(ns("bpr_lr"),  "Learning rate",      min=0.005, max=0.1, value=0.05, step=0.005),
                    sliderInput(ns("bpr_reg"), "Regularisation (λ)", min=0.001, max=0.02, value=0.004, step=0.001),
                    sliderInput(ns("bpr_iter"),"Training iterations", min=100, max=2000, value=500, step=100),
                    br(),
                    div(class="section-heading-dark","Implicit Events"),
                    checkboxGroupInput(ns("bpr_events"),"Event types = positive:",
                                       choices=c("buy","addtocart","details","view"),
                                       selected=c("buy","addtocart")),
                    br(),
                    run_button(ns("run_bpr"),"▶  Train BPR Model")
                ),
                br(),
                r_code_block(
'# BPR core (mirrors bpr_calculator.py)
sigmoid <- function(x)
  1/(1+exp(-pmax(-500,pmin(500,x))))

bpr_step <- function(u, i_pos, i_neg) {
  diff <- sum(P[u,]*(Q[i_pos,]-Q[i_neg,]))
        + b[i_pos] - b[i_neg]
  z    <- sigmoid(-diff)

  P[u,]     <<- P[u,] +
    lr*(z*(Q[i_pos,]-Q[i_neg,]) - reg*P[u,])
  Q[i_pos,] <<- Q[i_pos,] +
    lr*(z*P[u,]  - reg*Q[i_pos,])
  Q[i_neg,] <<- Q[i_neg,] +
    lr*(-z*P[u,] - reg*Q[i_neg,])
  b[i_pos] <<- b[i_pos]+lr*(z  -0.002*b[i_pos])
  b[i_neg] <<- b[i_neg]+lr*(-z -0.002*b[i_neg])
}'
                )
            ),
            box(title="📈 Training Curves", status="success", solidHeader=TRUE, width=8,
                plotlyOutput(ns("bpr_loss_plot"), height="180px"),
                br(),
                plotlyOutput(ns("bpr_auc_plot"),  height="180px"),
                br(),
                div(class="info-box-plain",
                    HTML("<strong>AUC interpretation:</strong> 0.5 = random ranking. 1.0 = perfect. BPR typically reaches 0.70–0.85 on movie data."))
            )
          ),
          fluidRow(
            box(title="📡 Implicit Interaction Matrix", status="warning",
                solidHeader=TRUE, width=5,
                plotlyOutput(ns("implicit_matrix_plot"), height="300px"),
                br(),
                uiOutput(ns("implicit_stats"))
            ),
            box(title="🎬 BPR Recommendations", status="info",
                solidHeader=TRUE, width=7,
                div(class="section-heading-dark","Mirrors bpr_recommender.py"),
                div(class="control-panel",
                    fluidRow(
                      column(5, numericInput(ns("bpr_rec_user"),"User ID",value=1,min=1,max=50)),
                      column(4, sliderInput(ns("bpr_rec_n"),"Top-N",min=3,max=15,value=8)),
                      column(3, br(), run_button(ns("run_bpr_recs"),"▶  Recs"))
                    )
                ),
                uiOutput(ns("bpr_rec_result"))
            )
          ),
          fluidRow(
            box(title="📊 BPR vs Popularity: Rank Comparison", status="primary",
                solidHeader=TRUE, width=12,
                div(class="section-heading-dark","Bump chart: how do BPR and popularity rankings differ?"),
                div(class="control-panel",
                    fluidRow(
                      column(4, numericInput(ns("bpr_cmp_user"),"User ID",value=1,min=1,max=50)),
                      column(4, sliderInput(ns("bpr_cmp_n"),"Candidate items",min=10,max=25,value=15)),
                      column(4, br(), run_button(ns("run_bpr_cmp"),"▶  Compare"))
                    )
                ),
                plotlyOutput(ns("rank_comparison_plot"), height="380px")
            )
          )
        )
      )
    )
  )
}

chapter13_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    sigmoid <- function(x) 1/(1+exp(-pmax(-500,pmin(500,x))))

    implicit_matrix <- reactive({
      events <- input$bpr_events
      if(length(events)==0) events <- "buy"
      sample_events %>% filter(event %in% events) %>%
        distinct(user_id, content_id) %>% mutate(interacted=1L)
    })

    output$implicit_matrix_plot <- renderPlotly({
      im <- implicit_matrix()
      top_u <- im %>% count(user_id,sort=TRUE) %>% head(12) %>% pull(user_id)
      top_i <- im %>% count(content_id,sort=TRUE) %>% head(15) %>% pull(content_id)
      mat   <- matrix(0L, length(top_u), length(top_i),
                      dimnames=list(paste0("U",top_u), paste0("M",top_i)))
      for(k in seq_len(nrow(im))) {
        r<-paste0("U",im$user_id[k]); c<-paste0("M",im$content_id[k])
        if(r %in% rownames(mat) && c %in% colnames(mat)) mat[r,c]<-1L
      }
      labels <- sample_movies$title[match(top_i, sample_movies$movie_id)]
      labels[is.na(labels)] <- paste0("M",top_i[is.na(labels)])
      plot_ly(z=mat, x=labels, y=rownames(mat), type="heatmap",
              colorscale=list(c(0,"#001f2b"),c(1,"#00A39A")), showscale=FALSE,
              hovertemplate="%{y}x%{x}: %{z}<extra></extra>") %>%
        layout(title=list(text="Implicit Interactions (1=observed)",
                          font=list(color="#d0f0ed",size=11)),
               xaxis=list(title="",color="#8a9bb0",tickangle=-45,tickfont=list(size=8)),
               yaxis=list(title="",color="#8a9bb0",tickfont=list(size=9))) %>%
        plotly_dark_theme()
    })

    output$implicit_stats <- renderUI({
      im <- implicit_matrix()
      fluidRow(
        column(6,div(class="metric-card",
                     span(class="metric-value",nrow(im)),
                     span(class="metric-label","Positive Pairs"))),
        column(6,div(class="metric-card",
                     span(class="metric-value",paste0(round(nrow(im)/(N_USERS*N_MOVIES)*100,1),"%")),
                     span(class="metric-label","Density")))
      )
    })

    bpr_model <- eventReactive(input$run_bpr, {
      set.seed(42)
      k <- input$bpr_k; lr <- input$bpr_lr; reg <- input$bpr_reg; n_iter <- input$bpr_iter
      im <- implicit_matrix()
      user_ids <- sort(unique(im$user_id)); item_ids <- sort(unique(im$content_id))
      if(length(user_ids)==0||length(item_ids)==0) return(NULL)
      u_inx <- setNames(seq_along(user_ids),as.character(user_ids))
      i_inx <- setNames(seq_along(item_ids),as.character(item_ids))
      user_pos <- split(im$content_id, im$user_id)
      P <- matrix(runif(length(user_ids)*k,0,0.1),length(user_ids),k)
      Q <- matrix(runif(length(item_ids)*k,0,0.1),length(item_ids),k)
      b <- rep(0,length(item_ids)); names(b) <- as.character(item_ids)
      cpts <- round(unique(c(seq(1,n_iter,length.out=min(20,n_iter)),n_iter)))
      loss_log <- numeric(length(cpts)); auc_log <- numeric(length(cpts)); ck<-1L
      for(it in seq_len(n_iter)) {
        uid <- sample(user_ids,1); pp <- user_pos[[as.character(uid)]]
        i_pos <- sample(pp,1); i_neg <- i_pos
        while(i_neg %in% pp) i_neg <- sample(item_ids,1)
        u<-u_inx[as.character(uid)]; ip<-i_inx[as.character(i_pos)]; in_<-i_inx[as.character(i_neg)]
        xij <- sum(P[u,]*(Q[ip,]-Q[in_,]))+b[as.character(i_pos)]-b[as.character(i_neg)]
        z <- sigmoid(-xij)
        P[u,]   <- P[u,]   + lr*(z*(Q[ip,]-Q[in_,]) - reg*P[u,])
        Q[ip,]  <- Q[ip,]  + lr*(z*P[u,]  - reg*Q[ip,])
        Q[in_,] <- Q[in_,] + lr*(-z*P[u,] - reg*Q[in_,])
        b[as.character(i_pos)] <- b[as.character(i_pos)] + lr*(z   - 0.002*b[as.character(i_pos)])
        b[as.character(i_neg)] <- b[as.character(i_neg)] + lr*(-z  - 0.002*b[as.character(i_neg)])
        if(it == cpts[ck]) {
          n_ev <- min(150,length(user_ids)*3)
          xv <- sapply(seq_len(n_ev), function(jj) {
            uu<-sample(user_ids,1); pp2<-user_pos[[as.character(uu)]]
            ip2<-sample(pp2,1); in2<-sample(item_ids,1)
            sum(P[u_inx[as.character(uu)],]*(Q[i_inx[as.character(ip2)],]-Q[i_inx[as.character(in2)],]))
          })
          loss_log[ck] <- -mean(log(sigmoid(xv)+1e-10))+0.5*reg*(mean(P^2)+mean(Q^2))
          auc_log[ck]  <- mean(xv>0)
          ck <- min(ck+1L,length(cpts))
        }
      }
      rownames(P)<-as.character(user_ids); rownames(Q)<-as.character(item_ids)
      list(P=P,Q=Q,b=b,u_inx=u_inx,i_inx=i_inx,
           user_ids=user_ids,item_ids=item_ids,user_pos=user_pos,k=k,
           cpts=cpts[1:ck],loss=loss_log[1:ck],auc=auc_log[1:ck])
    }, ignoreNULL=FALSE)

    output$bpr_loss_plot <- renderPlotly({
      m<-bpr_model(); if(is.null(m)) return(plot_ly()%>%plotly_dark_theme())
      df<-data.frame(it=m$cpts,loss=m$loss)
      plot_ly(df,x=~it,y=~loss,type="scatter",mode="lines",
              line=list(color="#e8410a",width=2),
              hovertemplate="Iter %{x}: Loss=%{y:.4f}<extra></extra>") %>%
        layout(title=list(text="BPR-Opt Loss",font=list(color="#d0f0ed",size=11)),
               xaxis=list(title="Iteration",color="#8a9bb0",gridcolor="rgba(255,255,255,0.08)"),
               yaxis=list(title="Loss",color="#8a9bb0",gridcolor="rgba(255,255,255,0.08)")) %>%
        plotly_dark_theme()
    })

    output$bpr_auc_plot <- renderPlotly({
      m<-bpr_model(); if(is.null(m)) return(plot_ly()%>%plotly_dark_theme())
      df<-data.frame(it=m$cpts,auc=m$auc)
      plot_ly(df,x=~it,y=~auc,type="scatter",mode="lines",
              line=list(color="#00A39A",width=2),
              hovertemplate="Iter %{x}: AUC~%{y:.3f}<extra></extra>") %>%
        add_trace(x=range(df$it),y=c(0.5,0.5),type="scatter",mode="lines",
                  line=list(color="#fbbf24",dash="dash",width=1.5),showlegend=FALSE) %>%
        layout(title=list(text="Sample AUC (fraction correct pairwise rankings)",
                          font=list(color="#d0f0ed",size=11)),
               xaxis=list(title="Iteration",color="#8a9bb0",gridcolor="rgba(255,255,255,0.08)"),
               yaxis=list(title="AUC",color="#8a9bb0",range=c(0.3,1.05),
                          gridcolor="rgba(255,255,255,0.08)"),showlegend=FALSE) %>%
        plotly_dark_theme()
    })

    bpr_recs_data <- eventReactive(input$run_bpr_recs, {
      m<-bpr_model(); if(is.null(m)) return(NULL)
      uid<-as.character(input$bpr_rec_user); n<-input$bpr_rec_n
      if(!uid %in% names(m$u_inx)) return(NULL)
      u<-m$u_inx[uid]; pos<-m$user_pos[[uid]]; unseen<-setdiff(m$item_ids,pos)
      sc<-sapply(as.character(unseen), function(iid) {
        if(!iid %in% names(m$i_inx)) return(-Inf)
        i<-m$i_inx[iid]; sum(m$P[u,]*m$Q[i,])+m$b[iid]
      })
      top<-as.integer(names(sort(sc,decreasing=TRUE)[1:min(n,length(sc))]))
      tsc<-round(sort(sc,decreasing=TRUE)[1:min(n,length(sc))],4)
      data.frame(movie_id=top,bpr_score=tsc) %>%
        left_join(sample_movies %>% select(movie_id,title,genre),by="movie_id")
    }, ignoreNULL=FALSE)

    output$bpr_rec_result <- renderUI({
      r<-bpr_recs_data()
      if(is.null(r)||nrow(r)==0)
        return(div(class="warn-box",HTML("<strong>Train model first.</strong>")))
      rows<-lapply(seq_len(nrow(r)),function(i)
        tags$tr(tags$td(paste0("#",i)),tags$td(r$title[i]),
                tags$td(r$genre[i]),tags$td(r$bpr_score[i])))
      div(class="result-card",
          tags$h5(paste0("BPR Recs — User ",input$bpr_rec_user)),
          tags$table(class="algo-table",
                     tags$thead(tags$tr(tags$th("#"),tags$th("Movie"),tags$th("Genre"),tags$th("Score"))),
                     tags$tbody(rows)))
    })

    rank_cmp <- eventReactive(input$run_bpr_cmp, {
      m<-bpr_model(); if(is.null(m)) return(NULL)
      uid<-as.character(input$bpr_cmp_user); n<-input$bpr_cmp_n
      pos<-m$user_pos[[uid]]; unseen<-setdiff(m$item_ids,pos)
      cands<-head(unseen,n)
      u<-if(uid %in% names(m$u_inx)) m$u_inx[uid] else NULL
      bpr_sc<-if(!is.null(u)) sapply(as.character(cands),function(iid) {
        if(!iid %in% names(m$i_inx)) return(-Inf)
        i<-m$i_inx[iid]; sum(m$P[u,]*m$Q[i,])+m$b[iid]
      }) else rep(0,length(cands))
      pop_sc<-sample_ratings %>% filter(movie_id %in% cands) %>%
        group_by(movie_id) %>% summarise(pop=n(),.groups="drop")
      df<-data.frame(movie_id=cands,bpr=bpr_sc[as.character(cands)]) %>%
        left_join(pop_sc,by="movie_id") %>%
        left_join(sample_movies %>% select(movie_id,title,genre),by="movie_id") %>%
        mutate(pop=ifelse(is.na(pop),0L,pop),
               bpr_rank=rank(-bpr,ties.method="first"),
               pop_rank=rank(-pop,ties.method="first"),
               rank_diff=abs(bpr_rank-pop_rank))
      df
    }, ignoreNULL=FALSE)

    output$rank_comparison_plot <- renderPlotly({
      df<-rank_cmp(); if(is.null(df)) return(plot_ly()%>%plotly_dark_theme())
      fig<-plot_ly()
      for(i in seq_len(nrow(df))) {
        col<-if(df$bpr_rank[i]<df$pop_rank[i])"#00A39A" else if(df$bpr_rank[i]>df$pop_rank[i])"#e8410a" else "#8a9bb0"
        fig<-fig%>%add_trace(x=c(1,2),y=c(df$pop_rank[i],df$bpr_rank[i]),type="scatter",mode="lines",
                             showlegend=FALSE,line=list(color=col,width=1.5,opacity=0.7),
                             hovertemplate=paste0("<b>",df$title[i],"</b><br>Pop:",df$pop_rank[i]," BPR:",df$bpr_rank[i],"<extra></extra>"))
      }
      movers<-df%>%filter(rank_diff>=3)
      for(i in seq_len(nrow(movers)))
        fig<-fig%>%add_trace(x=c(1,2),y=c(movers$pop_rank[i],movers$bpr_rank[i]),
                             type="scatter",mode="lines+markers",name=movers$title[i],
                             line=list(width=3),marker=list(size=8),
                             hovertemplate=paste0("<b>",movers$title[i],"</b> Pop:",movers$pop_rank[i],"->BPR:",movers$bpr_rank[i],"<extra></extra>"))
      fig%>%layout(
        title=list(text=paste0("Rank Shift: Popularity -> BPR (User ",input$bpr_cmp_user,")"),
                   font=list(color="#d0f0ed",size=12)),
        xaxis=list(tickvals=c(1,2),ticktext=c("Popularity Rank","BPR Rank"),
                   color="#8a9bb0",zeroline=FALSE,showgrid=FALSE),
        yaxis=list(title="Rank (lower=higher)",color="#8a9bb0",autorange="reversed",
                   gridcolor="rgba(255,255,255,0.08)"),
        legend=list(font=list(color="#8a9bb0",size=9))) %>%
        plotly_dark_theme()
    })
  })
}
