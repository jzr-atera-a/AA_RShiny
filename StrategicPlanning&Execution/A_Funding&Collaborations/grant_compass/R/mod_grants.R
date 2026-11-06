# ---- Grants: browsable cards (seeded, scraped from a website, or added by admins) ----------

mod_grants_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "page-head",
      div(class = "eyebrow", "Opportunities"),
      h2("Grants on our radar"),
      p(class = "lead", "Click Prioritise on any card to score it. Admins can add grants or pull them from a website in the Admin tab.")),
    div(class = "filters",
      textInput(ns("q"), NULL, placeholder = "Search title, funder or theme", width = "100%"),
      selectInput(ns("theme"), NULL, choices = c("All themes" = ""), width = "100%"),
      selectInput(ns("status"), NULL, choices = c("Open & upcoming" = "live", "Open" = "open", "Upcoming" = "upcoming", "Closed" = "closed", "All" = "all"), width = "100%")),
    uiOutput(ns("cards"))
  )
}

mod_grants_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    observe({
      g <- ctx$data$grants()
      th <- sort(unique(tolower(unlist(lapply(g$themes, split_tags)))))
      updateSelectInput(session, "theme", choices = c("All themes" = "", stats::setNames(th, th)), selected = isolate(input$theme))
    })

    filtered <- reactive({
      req(ctx$user$authed)
      g <- ctx$data$grants()
      g <- g[g$status != "archived", , drop = FALSE]
      st <- input$status %||% "live"
      g <- switch(st, live = g[g$status %in% c("open", "upcoming", ""), ], all = g, g[g$status == st, ])
      if (nzchar(input$theme %||% "")) g <- g[grepl(input$theme, tolower(g$themes), fixed = TRUE), ]
      q <- tolower(trimws(input$q %||% ""))
      if (nzchar(q)) g <- g[grepl(q, tolower(paste(g$title, g$funder, g$themes, g$summary)), fixed = TRUE), ]
      g
    })

    output$cards <- renderUI({
      g <- filtered()
      if (nrow(g) == 0) return(div(class = "empty", "No grants match those filters."))
      prio <- latest_by(ctx$data$prio(), c("email", "grant_id"))
      div(class = "card-grid", lapply(seq_len(nrow(g)), function(k) {
        r <- g[k, ]
        dl <- days_left(r$closes)
        urgency <- if (is.na(dl)) NULL else if (dl < 0) chip("Closed", "grey") else if (dl <= 14) chip(paste0(dl, " days left"), "mag") else chip(paste0(dl, " days left"), "teal")
        n_scored <- length(unique(prio$email[prio$grant_id == r$grant_id]))
        mine <- any(prio$grant_id == r$grant_id & prio$email == ctx$user$email)
        div(class = "gcard",
          div(class = "gtop", span(class = "funder", r$funder), urgency),
          h3(r$title),
          p(class = "gsum", r$summary),
          div(class = "gmeta",
              span(class = "money", fmt_gbp(r$min_gbp, r$max_gbp)),
              if (nzchar(r$closes)) span(class = "muted", paste("Closes", r$closes))),
          div(class = "chips", chips(r$themes)),
          div(class = "gfoot",
              span(class = "small muted", if (mine) "You've scored this" else paste(n_scored, "scored")),
              div(
                if (nzchar(r$url)) tags$a(href = r$url, target = "_blank", rel = "noopener", class = "btn-ghost sm", HTML("Source &#8599;")),
                tags$button(class = "btn-brand sm", onclick = onclick_input(ns("prioritise"), r$grant_id),
                            if (mine) "Edit score" else "Prioritise"))))
      }))
    })

    observeEvent(input$prioritise, {
      ctx$pick(input$prioritise)
      ctx$nav("Prioritise")
    })
  })
}
