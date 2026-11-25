# ---- module ----------------------------------------------
# id:           programme_search
# name:         Live search
# icon:         globe
# description:  Find programmes on the live web with Claude, with a source link for each, and save the ones you want
# packages:     shiny
# -----------------------------------------------------------
# Ported from Funding Programmes modules/generate_programme (BOS modules/Funding Programmes/generate_programme.R).

programme_search_ui <- function(id) {
  ns <- NS(id)
  tagList(
    note("info", "Claude searches the web and lists programmes it found on live pages, each with the page it came from. ",
         "Programmes without a source link are saved as unverified. Always check the funder's page before applying."),
    card("What to look for",
      layout_columns(col_widths = c(3, 3, 3, 3),
        selectInput(ns("category"), "Category", CATEGORIES),
        textInput(ns("country"), "Country", "United Kingdom"),
        textInput(ns("region"), "City or region", "All"),
        sliderInput(ns("n"), "Number of results", 1, 8, 4, step = 1)),
      textAreaInput(ns("focus"), "Focus", rows = 2, width = "100%",
                    placeholder = "e.g. AI for energy networks, feasibility studies, SMEs, open in the next 3 months"),
      actionButton(ns("go"), "Search the web", class = "btn-brand", icon = icon("magnifying-glass"))),
    uiOutput(ns("results")))
}

programme_search_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    found <- reactiveVal(NULL); status <- reactiveVal(NULL)

    observeEvent(input$go, {
      if (!claude_ready()) return(status(note("bad", "No Claude API key is set. An admin can add one in Admin > Claude API.")))
      status(NULL); found(NULL)
      res <- withProgress(message = "Searching the web (this can take a minute)...", value = 0.3, tryCatch({
        r <- claude_call(programme_search_prompt(input$category, input$country, input$region, input$focus, input$n),
                         max_tokens = 6000, web_search = TRUE)
        parsed <- parse_programme_text(r$text)
        list(df = programmes_from_parsed(parsed, "Live search", "Claude web search"), urls = r$urls, searches = r$searches)
      }, error = function(e) { log_debug("[Live search] ", safe_error_text(e)); list(error = safe_error_text(e)) }))
      if (!is.null(res$error)) return(status(note("bad", res$error)))
      have <- programme_key(store_read("programmes"))
      res$df$already <- programme_key(res$df) %in% have
      found(res$df)
      status(note("ok", sprintf("Found %d programme(s) using %d web search(es).", nrow(res$df), res$searches)))
    })

    output$results <- renderUI({
      d <- found()
      tagList(status(), if (!is.null(d) && nrow(d)) card("Results",
        p(class = "small muted", "Tick the programmes to keep. Ones already in your list are marked and will be skipped."),
        lapply(seq_len(nrow(d)), function(i) {
          r <- d[i, ]
          links <- unique(unlist(strsplit(r$verified_urls, "[, ]+"))); links <- links[grepl("^https?://", links)]
          div(class = "res-card",
            checkboxInput(ns(paste0("pick_", i)), tags$b(r$programme_name), value = !r$already),
            if (r$already) span(class = "pill pill-off", "Already in the list"),
            if (!nzchar(r$verified_at)) span(class = "pill pill-warn", "No source link: will be saved as unverified"),
            tags$table(class = "kv",
              tags$tr(tags$th("Funder"), tags$td(r$funder)), tags$tr(tags$th("Amount"), tags$td(r$amount_text)),
              tags$tr(tags$th("Opens / closes"), tags$td(paste(r$opens_date %|% "-", "/", r$closes_date %|% r$deadline_text %|% "-"))),
              tags$tr(tags$th("Conditions"), tags$td(r$conditions)), tags$tr(tags$th("Summary"), tags$td(r$summary))),
            if (length(links)) p(lapply(links, function(u) tags$a(href = u, target = "_blank", rel = "noopener", class = "link-chip", u))))
        }),
        actionButton(ns("save"), "Save selected", class = "btn-brand", icon = icon("floppy-disk"))))
    })

    observeEvent(input$save, {
      d <- found(); req(d)
      keep <- vapply(seq_len(nrow(d)), function(i) isTRUE(input[[paste0("pick_", i)]]), TRUE)
      if (!any(keep)) return(showNotification("Tick at least one programme.", type = "warning"))
      r <- add_programmes(d[keep, setdiff(names(d), "already"), drop = FALSE], ctx$user())
      ctx$bump()
      d$already[keep] <- TRUE; found(d)
      status(note("ok", sprintf("Saved %d programme(s); skipped %d already in the list.", r$added, r$skipped)))
    })
  })
}
