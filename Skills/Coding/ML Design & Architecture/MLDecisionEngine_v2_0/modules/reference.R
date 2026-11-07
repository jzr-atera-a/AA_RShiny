# modules/reference.R — Full ML Methods Reference

reference_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="meta-hero",
      tags$h1("ML Methods Reference Library"),
      tags$h2("All 52 methods across 12 groups — filterable by industry, latency, interpretability, and streaming fit"),
      div(lapply(names(GROUPS_META), function(g) {
        gm <- GROUPS_META[[g]]
        span(class="hero-badge",
          style=paste0("background:", gm$colour, "44;border:1px solid ", gm$colour, "88;color:#fff;"),
          gm$label)
      }))
    ),

    fluidRow(
      box(title="🔍 Filter Methods", status="primary", solidHeader=TRUE, width=12,
        fluidRow(
          column(3,
            selectInput(ns("f_group"), "Method Group:",
              choices=c("All Groups"="all",
                setNames(names(GROUPS_META), sapply(GROUPS_META, function(g) g$label))),
              width="100%")
          ),
          column(3,
            selectInput(ns("f_industry"), "Industry:",
              choices=c("All Industries"="all",
                setNames(names(INDUSTRIES), names(INDUSTRIES))),
              width="100%")
          ),
          column(3,
            selectInput(ns("f_latency"), "Latency:",
              choices=c("Any Latency"="all",
                "Real-time (<10ms)"="realtime",
                "Near-real-time (<1s)"="nearrealtime",
                "Batch"="batch",
                "Streaming"="streaming"),
              width="100%")
          ),
          column(3,
            selectInput(ns("f_streaming"), "Streaming Fit:",
              choices=c("Any"="all", "Excellent"="excellent", "Good"="good",
                        "Moderate"="moderate", "Poor"="poor"),
              width="100%")
          )
        )
      )
    ),

    fluidRow(
      box(title="📊 Method Library", status="info", solidHeader=TRUE, width=12,
        uiOutput(ns("method_cards"))
      )
    )
  )
}

reference_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    filtered_methods <- reactive({
      methods <- ML_MODELS

      if(!is.null(input$f_group) && input$f_group != "all")
        methods <- Filter(function(m) m$group == input$f_group, methods)

      if(!is.null(input$f_industry) && input$f_industry != "all") {
        ind_val <- INDUSTRIES[input$f_industry]
        methods <- Filter(function(m) ind_val %in% m$industries, methods)
      }

      if(!is.null(input$f_latency) && input$f_latency != "all")
        methods <- Filter(function(m) input$f_latency %in% m$latency, methods)

      if(!is.null(input$f_streaming) && input$f_streaming != "all")
        methods <- Filter(function(m) m$streaming_fit == input$f_streaming, methods)

      methods
    })

    output$method_cards <- renderUI({
      methods <- filtered_methods()
      if(length(methods) == 0) {
        return(div(class="info-box-plain",
          tags$h4("No methods match the current filters."),
          tags$p("Try widening your filter criteria.")))
      }

      tagList(
        tags$p(style="color:#546e7a;font-size:12px;margin-bottom:16px;",
          paste0("Showing ", length(methods), " of ", length(ML_MODELS), " methods")),

        fluidRow(
          lapply(methods, function(m) {
            gm <- GROUPS_META[[m$group]]
            group_colour <- if(!is.null(gm)) gm$colour else "#546e7a"
            stream_col <- STREAMING_FIT_COLOUR(m$streaming_fit)

            column(4,
              div(class="framework-card",
                style=paste0("border-left:4px solid ", group_colour, ";min-height:240px;"),

                # Name + group badge
                tags$h5(style=paste0("color:", group_colour, ";margin:0 0 2px;"), m$name),
                tags$p(style="font-size:10px;color:#546e7a;font-family:'JetBrains Mono',monospace;margin:0 0 6px;",
                  m$aliases),
                span(class="stage-pill",
                  style=paste0("background:", group_colour, "22;color:", group_colour, ";border-color:", group_colour, "55;font-size:9px;"),
                  m$group_label),
                br(), br(),

                # Industries
                div(lapply(m$industries, function(ind)
                  span(class="badge-blue", style="margin:2px;font-size:9px;", ind)
                )),
                br(),

                # Latency + streaming
                fluidRow(
                  column(6,
                    tags$p(style="font-size:10px;margin:0;color:#546e7a;", "Latency:"),
                    tags$p(style="font-size:11px;font-weight:700;margin:0;",
                      paste(m$latency, collapse=", "))
                  ),
                  column(6,
                    tags$p(style="font-size:10px;margin:0;color:#546e7a;", "Streaming:"),
                    tags$p(style=paste0("font-size:11px;font-weight:700;margin:0;color:", stream_col, ";"),
                      toupper(m$streaming_fit))
                  )
                ),
                br(),

                # Book references
                div(
                  span(class="badge-green", style="font-size:9px;",
                    paste("Huyen:", paste(m$huyen_ch, collapse=", "))),
                  span(class="badge-amber", style="font-size:9px;margin-left:4px;",
                    paste("K&B:", paste(m$kb_ch, collapse=", ")))
                ),
                br(),

                # First use case
                div(class="info-box-plain", style="padding:6px 10px;margin:0;",
                  tags$p(style="font-size:11px;margin:0;", m$use_cases[[1]])
                )
              )
            )
          })
        )
      )
    })
  })
}
