# modules/long_hedge_concept.R

long_hedge_concept_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Long Hedge \u2014 Protecting Against a Price Rise", status = "primary", solidHeader = TRUE, width = 12,
        tags$p(HTML(paste0(
          "A <strong>long hedge</strong> removes the uncertainty of <em>not</em> owning an asset yet needing ",
          "to buy it later \u2014 the mirror image of a short hedge. The manual's example: a chocolate manufacturer ",
          "needs to buy cocoa in three months but is worried the price will rise. Being effectively ",
          "\u201cshort the underlying\u201d (they need to buy, but don't own it yet), they hedge by <strong>going long ",
          "futures</strong> today. If cocoa prices do rise, the profit on the long futures position offsets ",
          "the higher price paid for the physical cocoa, fixing their effective purchase price in advance."
        )), style = "font-size:13px; color:#444; line-height:1.7;"),
        tags$hr(),
        fluidRow(
          column(6,
            div(style = "background:#fdebd0; border-radius:8px; padding:14px; text-align:center;",
                tags$h5("Long Underlying (owns the asset)", style = "color:#7d4a00;"),
                tags$p("Concern: prices may fall", style = "font-size:12.5px; margin:4px 0;"),
                tags$strong("Strategy: Short Hedge (sell futures)", style = "color:#e67e22; font-size:13px;")
            )
          ),
          column(6,
            div(style = "background:#d5f5e3; border-radius:8px; padding:14px; text-align:center;",
                tags$h5("Short Underlying (needs to buy later)", style = "color:#1e7e46;"),
                tags$p("Concern: prices may rise", style = "font-size:12.5px; margin:4px 0;"),
                tags$strong("Strategy: Long Hedge (buy futures)", style = "color:#27ae60; font-size:13px;")
            )
          )
        ),
        tags$p(paste0(
          "The manual doesn't give a numeric worked example for the long hedge case (unlike the short hedge ",
          "examples on the other two Hedging Strategies tabs) \u2014 the mechanics mirror the short hedge exactly, ",
          "just with the position and concern reversed."
        ), style = "font-size:11px; color:#888; font-style:italic; margin-top:14px;")
      )
    )
  )
}

long_hedge_concept_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    # Fully static content — no server-side outputs needed.
    session$onSessionEnded(function() {})
  })
}
