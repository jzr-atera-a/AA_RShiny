# modules/patterns.R — Design Patterns Recommendation Tab

patterns_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
      tags$h1("Recommended ML Design Patterns"),
      tags$h2("Patterns from Lakshmanan, Robinson & Munn — matched to your ML system recommendations"),
      div(
        span(class="hero-badge","30 Patterns"),
        span(class="hero-badge","6 Pattern Groups"),
        span(class="hero-badge","O'Reilly 2020"),
        span(class="hero-badge","Directly Linked to Results Tab")
      ),
      tags$p(style="color:rgba(255,255,255,0.75);font-size:12px;margin-top:10px;",
        "Every pattern shown is directly relevant to your selected ML systems. Patterns are ranked by how strongly they address your specific scenario, compliance requirements, and data challenges.")
    ),
    uiOutput(ns("not_run_msg")),
    uiOutput(ns("patterns_body"))
  )
}

patterns_server <- function(id, wizard_inputs) {
  moduleServer(id, function(input, output, session) {

    output$not_run_msg <- renderUI({
      if(!is.null(wizard_inputs$run_count) && wizard_inputs$run_count > 0) return(NULL)
      div(style="padding:40px;text-align:center;",
        div(class="info-box-plain",
          tags$h4("No scenario selected yet"),
          tags$p("Complete the Decision Wizard and click 'Find Optimal ML System + Design Patterns' to see pattern recommendations here.")
        )
      )
    })

    ml_results <- reactive({
      req(wizard_inputs$run_count, wizard_inputs$run_count > 0)
      score_methods(
        industry=wizard_inputs$industry, problem_type=wizard_inputs$problem_type,
        data_type=wizard_inputs$data_type, data_volume=wizard_inputs$data_volume,
        latency=wizard_inputs$latency, serving=wizard_inputs$serving,
        interpretability=wizard_inputs$interpretability, team_maturity=wizard_inputs$team_maturity
      )
    })

    pattern_results <- reactive({
      req(wizard_inputs$run_count, wizard_inputs$run_count > 0)
      top_ml_ids <- sapply(ml_results()$top3, function(m) m$id)
      score_patterns(
        ml_system_ids  = top_ml_ids,
        problem_type   = wizard_inputs$problem_type,
        data_type      = wizard_inputs$data_type,
        latency        = wizard_inputs$latency,
        team_maturity  = wizard_inputs$team_maturity,
        compliance     = wizard_inputs$compliance
      )
    })

    output$patterns_body <- renderUI({
      req(wizard_inputs$run_count, wizard_inputs$run_count > 0)
      res_ml  <- ml_results()
      res_pat <- pattern_results()
      top3_ml <- res_ml$top3
      top3_pat <- res_pat$top3
      all_pat  <- res_pat$all
      pat_scores <- res_pat$scores

      make_pattern_card <- function(p, rank, score) {
        gc <- p$group_colour

        # Find which of the top ML systems this pattern directly supports
        top_ml_ids <- sapply(top3_ml, function(m) m$id)
        top_ml_names <- sapply(top3_ml, function(m) m$name)
        linked_systems <- top_ml_names[top_ml_ids %in% p$ml_system_ids]

        div(class="framework-card",
          style=paste0("border-left:5px solid ", gc, ";margin-bottom:18px;"),

          # Header
          fluidRow(
            column(8,
              tags$h4(style=paste0("color:", gc, ";margin:0;"),
                paste0("#", rank, "  ", p$name)),
              tags$p(style="font-size:10px;color:#546e7a;font-family:'JetBrains Mono',monospace;margin:2px 0 4px;",
                paste0(p$id, "  ·  ", p$group_label)),
              span(class="stage-pill",
                style=paste0("background:", gc, "22;color:", gc, ";border-color:", gc, "55;"),
                p$group_label),
              span(class="badge-blue", style="margin-left:6px;",
                paste0("Complexity: ", p$complexity))
            ),
            column(4, style="text-align:right;",
              div(class="av-kpi-card", style="display:inline-block;min-width:110px;",
                span(style="font-size:1.6em;font-weight:800;display:block;font-family:'JetBrains Mono',monospace;",
                  paste0(score, " pts")),
                span(style="font-size:10px;text-transform:uppercase;letter-spacing:1px;opacity:0.75;",
                  "Pattern Score")
              )
            )
          ),
          br(),

          # Problem it solves
          fluidRow(
            column(12,
              div(class="info-box-plain", style="padding:10px;",
                tags$b("Problem this pattern solves: "),
                tags$span(style="font-size:12px;", p$problem)
              )
            )
          ),
          br(),

          # When to use (scenario-specific)
          fluidRow(
            column(12,
              div(class="success-box", style="padding:10px;",
                tags$b(style="color:#008A82;", "When to use in your scenario: "),
                tags$span(style="font-size:12px;", p$when_to_use)
              )
            )
          ),
          br(),

          # Link to recommended ML systems
          if(length(linked_systems) > 0) {
            fluidRow(column(12,
              div(style=paste0("background:", gc, "11;border:1px solid ", gc, "33;border-left:4px solid ", gc, ";border-radius:8px;padding:10px;margin-bottom:10px;"),
                tags$b(style=paste0("color:", gc, ";"), "Directly linked to your top ML systems: "),
                tags$span(paste(linked_systems, collapse=" · "))
              )
            ))
          },

          # Use cases + models
          fluidRow(
            column(6,
              div(class="section-heading-dark", "Real-World Use Cases"),
              div(lapply(p$use_cases, function(uc)
                span(class="badge-blue", style="margin:2px;display:inline-block;", uc)
              ))
            ),
            column(6,
              div(class="section-heading-dark", "Tools & Models"),
              div(lapply(p$models, function(m)
                span(class="badge-green", style="margin:2px;display:inline-block;", m)
              ))
            )
          ),
          br(),

          # Pros/cons + related patterns
          fluidRow(
            column(4,
              div(class="success-box",
                tags$b("Advantages"),
                tags$ul(lapply(p$pros, tags$li))
              )
            ),
            column(4,
              div(class="warn-box",
                tags$b("Disadvantages"),
                tags$ul(lapply(p$cons, tags$li))
              )
            ),
            column(4,
              div(class="tip-box",
                tags$b("Related Patterns"),
                tags$ul(lapply(p$related, tags$li)),
                br(),
                tags$b("Applies to:"),
                tags$p(style="font-size:11px;", paste(p$problem_types, collapse=", "))
              )
            )
          )
        )
      }

      # Mandatory patterns from compliance
      mandatory_patterns <- list()
      compliance <- wizard_inputs$compliance
      if(!is.null(compliance) && !"none" %in% compliance) {
        mandatory_ids <- c()
        if("gdpr" %in% compliance || "fca" %in% compliance) mandatory_ids <- c(mandatory_ids, "RA-02", "RE-07", "RA-01")
        if("fca"  %in% compliance) mandatory_ids <- c(mandatory_ids, "RS-03", "RE-07")
        if("avact" %in% compliance) mandatory_ids <- c(mandatory_ids, "RA-03", "RS-03", "PR-05")
        if(length(mandatory_ids) > 0) {
          mandatory_ids <- unique(mandatory_ids)
          mandatory_patterns <- Filter(function(p) p$id %in% mandatory_ids, DESIGN_PATTERNS)
        }
      }

      # Data challenge patterns
      challenge_patterns <- list()
      challenges <- wizard_inputs$data_challenges
      if(!is.null(challenges) && length(challenges) > 0) {
        challenge_map <- list(
          imbalance  = "PR-06", high_card = "DP-01", multimodal = "DP-04",
          schema_evo = "RE-03", streaming = "RE-04", federated = "TL-04",
          cold_start = "DP-02", small_data = "TL-01"
        )
        challenge_ids <- unlist(challenge_map[names(challenge_map) %in% challenges])
        challenge_patterns <- Filter(function(p) p$id %in% challenge_ids, DESIGN_PATTERNS)
      }

      # Full ranked table
      all_df <- do.call(rbind, lapply(seq_along(all_pat), function(i) {
        p <- all_pat[[i]]
        data.frame(
          Rank=i, Pattern=p$name, ID=p$id, Group=p$group_label,
          Score=pat_scores[i], Complexity=p$complexity,
          Latency=paste(p$latency, collapse=", "),
          stringsAsFactors=FALSE
        )
      }))

      tagList(
        br(),
        # Mandatory patterns banner
        if(length(mandatory_patterns) > 0)
          fluidRow(column(12,
            div(class="warn-box",
              tags$b("⚠️ Mandatory Patterns Based on Your Compliance Requirements: "),
              tags$span(paste(sapply(mandatory_patterns, function(p) paste0(p$id, " ", p$name)), collapse=" · "))
            )
          )),

        # Section heading
        fluidRow(column(12,
          div(class="section-heading", "🥇 Top 3 Recommended Design Patterns"),
          tags$p(style="color:#546e7a;font-size:12px;margin-bottom:16px;",
            paste0("Scored against your top ML systems: ",
              paste(sapply(top3_ml, function(m) m$name), collapse=" · ")))
        )),

        # Top 3 pattern cards
        fluidRow(column(12,
          lapply(seq_along(top3_pat), function(i)
            make_pattern_card(top3_pat[[i]], i, pat_scores[i])
          )
        )),

        # Data challenge patterns
        if(length(challenge_patterns) > 0) {
          fluidRow(column(12,
            div(class="section-heading", "🔧 Patterns for Your Data Challenges"),
            lapply(challenge_patterns, function(p) {
              idx <- which(sapply(all_pat, function(ap) ap$id) == p$id)
              make_pattern_card(p, "★", if(length(idx)>0) pat_scores[idx[1]] else 0)
            })
          ))
        },

        # Pattern group summary
        fluidRow(
          box(title="📊 Pattern Coverage by Group", status="info", solidHeader=TRUE, width=12,
            fluidRow(
              lapply(names(PATTERN_GROUPS), function(gid) {
                gm <- PATTERN_GROUPS[[gid]]
                group_patterns <- Filter(function(p) p$group == gid, top3_pat)
                count <- length(Filter(function(p) p$group == gid,
                  all_pat[1:min(10, length(all_pat))]))
                column(2,
                  div(style=paste0("background:", gm$colour, "15;border:2px solid ", gm$colour,
                    "55;border-radius:10px;padding:12px;text-align:center;margin:4px;"),
                    tags$h6(style=paste0("color:", gm$colour, ";font-size:10px;font-weight:700;"), gm$label),
                    div(style=paste0("font-size:2em;font-weight:800;color:", gm$colour, ";font-family:'JetBrains Mono',monospace;"), count),
                    tags$p(style="font-size:9px;color:#546e7a;", "in top 10")
                  )
                )
              })
            )
          )
        ),

        # Full ranked table
        fluidRow(
          box(title="📋 All 30 Patterns Scored for Your Scenario",
              status="primary", solidHeader=TRUE, width=12,
            DT::DTOutput("patterns_full_table")
          )
        )
      )
    })

    output$patterns_full_table <- DT::renderDT({
      req(wizard_inputs$run_count, wizard_inputs$run_count > 0)
      res <- pattern_results()
      all_pat  <- res$all
      pat_scores <- res$scores

      df <- do.call(rbind, lapply(seq_along(all_pat), function(i) {
        p <- all_pat[[i]]
        data.frame(
          Rank=i, Pattern=p$name, ID=p$id, Group=p$group_label,
          Score=pat_scores[i], Complexity=p$complexity,
          Problem=substr(p$problem, 1, 80),
          WhenToUse=substr(p$when_to_use, 1, 80),
          stringsAsFactors=FALSE
        )
      }))

      DT::datatable(df,
        options=list(pageLength=15, scrollX=TRUE,
          columnDefs=list(list(width="160px", targets=1), list(width="60px", targets=2))),
        rownames=FALSE, class="table-hover table-striped table-sm"
      ) %>%
        DT::formatStyle("Score",
          background=DT::styleColorBar(c(0, max(df$Score)), "#e0f4f2"),
          backgroundSize="100% 80%", backgroundRepeat="no-repeat", backgroundPosition="center"
        ) %>%
        DT::formatStyle("ID",
          fontFamily="JetBrains Mono, monospace", fontWeight="700"
        ) %>%
        DT::formatStyle("Group",
          color=DT::styleEqual(
            sapply(PATTERN_GROUPS, function(g) g$label),
            sapply(PATTERN_GROUPS, function(g) g$colour)
          ), fontWeight="bold"
        )
    }, server=FALSE)
  })
}
