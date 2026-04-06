# modules/results.R — Results Dashboard

results_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
      tags$h1("ML System Design Recommendations"),
      tags$h2("Ranked shortlist based on your scenario — with book references, pros/cons, and architecture guidance"),
      div(
        span(class="hero-badge", uiOutput(ns("hero_scenario")))
      )
    ),
    uiOutput(ns("not_run_msg")),
    uiOutput(ns("results_body"))
  )
}

results_server <- function(id, wizard_inputs) {
  moduleServer(id, function(input, output, session) {

    output$hero_scenario <- renderUI({
      if(is.null(wizard_inputs$run_count) || wizard_inputs$run_count == 0)
        return(tags$span("Run the wizard first"))
      tags$span(paste(wizard_inputs$industry_label, "·", wizard_inputs$problem_label))
    })

    output$not_run_msg <- renderUI({
      if(!is.null(wizard_inputs$run_count) && wizard_inputs$run_count > 0) return(NULL)
      div(style="padding:40px;text-align:center;",
        div(class="info-box-plain",
          tags$h4("No scenario selected yet"),
          tags$p("Complete the Decision Wizard on the previous tab and click 'Find My ML System Design' to see recommendations here.")
        )
      )
    })

    results_data <- reactive({
      req(wizard_inputs$run_count, wizard_inputs$run_count > 0)
      score_methods(
        industry        = wizard_inputs$industry,
        problem_type    = wizard_inputs$problem_type,
        data_type       = wizard_inputs$data_type,
        data_volume     = wizard_inputs$data_volume,
        latency         = wizard_inputs$latency,
        serving         = wizard_inputs$serving,
        interpretability= wizard_inputs$interpretability,
        team_maturity   = wizard_inputs$team_maturity
      )
    })

    output$results_body <- renderUI({
      req(wizard_inputs$run_count, wizard_inputs$run_count > 0)
      res <- results_data()
      top3 <- res$top3
      all_methods <- res$all
      scores <- res$scores

      make_method_card <- function(m, rank, score) {
        gm <- GROUPS_META[[m$group]]
        group_colour <- if(!is.null(gm)) gm$colour else "#546e7a"
        stream_col <- STREAMING_FIT_COLOUR(m$streaming_fit)

        div(class="framework-card",
          style=paste0("border-left:5px solid ", group_colour, ";margin-bottom:18px;"),

          # Header row
          fluidRow(
            column(8,
              tags$h4(style=paste0("color:", group_colour, ";margin:0;"),
                paste0("#", rank, "  ", m$name)),
              tags$p(style="font-size:11px;color:#546e7a;margin:2px 0 4px;font-family:'JetBrains Mono',monospace;",
                m$aliases),
              span(class="stage-pill", style=paste0("background:", group_colour, "22;color:", group_colour, ";border-color:", group_colour, "55;"),
                m$group_label)
            ),
            column(4, style="text-align:right;",
              div(class="av-kpi-card", style="display:inline-block;min-width:100px;",
                span(style="font-size:1.6em;font-weight:800;display:block;font-family:'JetBrains Mono',monospace;",
                  paste0(score, " pts")),
                span(style="font-size:10px;text-transform:uppercase;letter-spacing:1px;opacity:0.75;",
                  "Match Score")
              )
            )
          ),
          br(),

          # Real-world use cases
          fluidRow(
            column(12,
              div(class="section-heading-dark", "Real-World Use Cases"),
              div(
                lapply(head(m$use_cases, 4), function(uc)
                  span(class="badge-blue", style="margin:2px;display:inline-block;", uc)
                )
              )
            )
          ),
          br(),

          # Pros / Cons / Architecture
          fluidRow(
            column(4,
              div(class="success-box",
                tags$b("Advantages"),
                tags$ul(lapply(m$pros, tags$li))
              )
            ),
            column(4,
              div(class="warn-box",
                tags$b("Disadvantages"),
                tags$ul(lapply(m$cons, tags$li))
              )
            ),
            column(4,
              div(class="tip-box",
                tags$b(style="color:#008A82;", "Architecture Note"),
                tags$p(m$arch_note),
                br(),
                tags$b("Streaming Fit: "),
                span(style=paste0("font-weight:700;color:", stream_col), toupper(m$streaming_fit))
              )
            )
          ),
          br(),

          # Book references
          fluidRow(
            column(6,
              div(style=paste0("background:#cffafe22;border:1px solid #a5f3fc;border-left:4px solid #0e7490;border-radius:8px;padding:10px;"),
                tags$b(style="color:#0e7490;", "📘 Huyen Chapters: "),
                paste(m$huyen_ch, collapse=", ")
              )
            ),
            column(6,
              div(style="background:#fef3c722;border:1px solid #fde68a;border-left:4px solid #b45309;border-radius:8px;padding:10px;",
                tags$b(style="color:#b45309;", "📙 K&B Chapters: "),
                paste(m$kb_ch, collapse=", ")
              )
            )
          )
        )
      }

      # Compliance warnings
      compliance_note <- NULL
      if(!is.null(wizard_inputs$compliance) && !"none" %in% wizard_inputs$compliance) {
        regs <- wizard_inputs$compliance
        msgs <- c()
        if("gdpr" %in% regs)  msgs <- c(msgs, "GDPR: automated decisions require explainability (Article 22). Prefer logistic regression or SHAP-backed GBT as baseline.")
        if("fca"  %in% regs)  msgs <- c(msgs, "FCA/Basel III: model risk management (MRM) validation required. Independent validation and champion-challenger A/B testing mandatory.")
        if("hipaa" %in% regs) msgs <- c(msgs, "HIPAA: patient data cannot be used without consent. Consider Federated Learning for cross-silo training.")
        if("avact" %in% regs) msgs <- c(msgs, "AV Act 2024: ODD declaration required. Calibration is mandatory. Model cards and sliced evaluation are regulatory artefacts.")
        compliance_note <- div(class="warn-box",
          tags$b("Regulatory Requirements Detected: "),
          tags$ul(lapply(msgs, tags$li))
        )
      }

      # Huyen vs K&B emphasis for this scenario
      book_panel <- div(
        fluidRow(
          column(6,
            div(style="background:#f0f9ff;border:1px solid #a5f3fc;border-left:4px solid #0e7490;border-radius:10px;padding:16px;",
              tags$h5(style="color:#0e7490;", "📘 What Huyen Emphasises"),
              tags$ul(
                tags$li(tags$b("Baseline hierarchy:"), " always start with simplest model (Tier 1-4 before complex DL)"),
                tags$li(tags$b("Train-serve skew:"), " #1 production failure — feature store must be consistent between training and serving"),
                tags$li(tags$b("Offline-online gap:"), " backtest metrics will not match live performance — always deploy with shadow/canary first"),
                tags$li(tags$b("Sliced evaluation:"), " aggregate metrics are not enough — always evaluate by subgroup before deployment"),
                tags$li(tags$b("Degenerate feedback loops:"), " especially relevant for recommenders — model actions affect future training data")
              )
            )
          ),
          column(6,
            div(style="background:#fffbeb;border:1px solid #fde68a;border-left:4px solid #b45309;border-radius:10px;padding:16px;",
              tags$h5(style="color:#b45309;", "📙 What K&B Emphasises"),
              tags$ul(
                tags$li(tags$b("Formal SLO specification:"), " define functional AND non-functional requirements explicitly before modelling"),
                tags$li(tags$b("Data architecture:"), " Lambda vs Kappa vs Delta — choose streaming architecture based on latency need"),
                tags$li(tags$b("Point-in-time joins:"), " feature store must prevent lookahead bias via correct temporal joins"),
                tags$li(tags$b("Model server selection:"), " Triton (NVIDIA GPU), TorchServe, vLLM (LLMs), BentoML — match server to model type"),
                tags$li(tags$b("4-layer monitoring:"), " infra metrics → data quality → prediction quality → ground truth (ordered by delay)")
              )
            )
          )
        )
      )

      # Full candidate table
      all_df <- do.call(rbind, lapply(seq_along(all_methods), function(i) {
        m <- all_methods[[i]]
        data.frame(
          Rank       = i,
          Method     = paste0(m$name),
          Group      = m$group_label,
          Score      = scores[i],
          Latency    = paste(m$latency, collapse=", "),
          Streaming  = m$streaming_fit,
          Interpretable = paste(m$interpretability, collapse=", "),
          Huyen_Ch   = paste(m$huyen_ch, collapse=", "),
          KB_Ch      = paste(m$kb_ch, collapse=", "),
          stringsAsFactors=FALSE
        )
      }))

      tagList(
        br(),
        if(!is.null(compliance_note)) fluidRow(column(12, compliance_note)),

        fluidRow(
          column(12,
            div(class="section-heading", "🥇 Top 3 Recommended Methods"),
            tags$p(style="color:#546e7a;font-size:12px;margin-bottom:16px;",
              paste0("Based on your selection: ", wizard_inputs$industry_label,
                     " · ", wizard_inputs$problem_label,
                     " · ", wizard_inputs$data_label))
          )
        ),

        # Top 3 cards
        fluidRow(column(12,
          lapply(seq_along(top3), function(i) make_method_card(top3[[i]], i, scores[i]))
        )),

        # Book emphasis panel
        fluidRow(column(12,
          div(class="section-heading", "📚 Book Guidance for This Scenario"),
          book_panel
        )),
        br(),

        # Full ranked table
        fluidRow(
          box(title="📋 Full Ranked Candidate List (all 52 methods scored)",
              status="info", solidHeader=TRUE, width=12,
            DTOutput("results_full_table")
          )
        )
      )
    })

    output$results_full_table <- renderDT({
      req(wizard_inputs$run_count, wizard_inputs$run_count > 0)
      res <- results_data()
      all_methods <- res$all
      scores <- res$scores

      df <- do.call(rbind, lapply(seq_along(all_methods), function(i) {
        m <- all_methods[[i]]
        data.frame(
          Rank      = i,
          Method    = m$name,
          Aliases   = m$aliases,
          Group     = m$group_label,
          Score     = scores[i],
          Streaming = m$streaming_fit,
          Latency   = paste(m$latency, collapse=", "),
          Interp    = paste(m$interpretability, collapse=", "),
          Huyen     = paste(m$huyen_ch, collapse=", "),
          KB        = paste(m$kb_ch, collapse=", "),
          stringsAsFactors=FALSE
        )
      }))

      datatable(df,
        options=list(pageLength=15, scrollX=TRUE,
          columnDefs=list(list(width="180px", targets=1), list(width="140px", targets=2))),
        rownames=FALSE, class="table-hover table-striped table-sm"
      ) %>%
        formatStyle("Score",
          background=styleColorBar(c(0, max(df$Score)), "#e0f4f2"),
          backgroundSize="100% 80%", backgroundRepeat="no-repeat", backgroundPosition="center"
        ) %>%
        formatStyle("Streaming",
          color=styleEqual(c("excellent","good","moderate","poor"),
                           c("#27ae60","#2980b9","#e67e22","#c0392b")),
          fontWeight="bold"
        ) %>%
        formatStyle("Rank", fontFamily="JetBrains Mono, monospace", fontWeight="700")
    }, server=FALSE)
  })
}
