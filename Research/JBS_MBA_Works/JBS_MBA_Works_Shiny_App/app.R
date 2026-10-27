# =============================================================================
# MBA 2024-2025 Works & Essays - interactive text edition
# Jose Francisco Zubizarreta Rodriguez - Cambridge Judge Business School
#
# Run:      shiny::runApp("JBS_MBA_Works_App")
# Packages: shiny, shinydashboard, plotly, DT, jsonlite
# Everything is shown as text and boxes inside the app. No PDF viewer,
# browser extension, font service or CDN is needed (Google Fonts are optional).
# =============================================================================

library(shiny)
library(shinydashboard)

source(file.path("R", "data_works.R"), local = TRUE, encoding = "UTF-8")
source(file.path("R", "text_tools.R"), local = TRUE, encoding = "UTF-8")
source(file.path("R", "plots.R"), local = TRUE, encoding = "UTF-8")
source(file.path("R", "analysis.R"), local = TRUE, encoding = "UTF-8")
source(file.path("R", "insights.R"), local = TRUE, encoding = "UTF-8")

SLIDE_INDEX <- jsonlite::fromJSON(file.path("data", "slides.json"), simplifyVector = FALSE)
term_col <- function(k) TERM_COL[[k]]
click_data <- function(src) tryCatch(plotly::event_data("plotly_click", source = src), warning = function(w) NULL)
ALL_IDS <- vapply(WORKS, `[[`, character(1), "id")
ID_CHOICES <- setNames(ALL_IDS, vapply(WORKS, function(w) paste0(w$code, " \u00b7 ", w$short), character(1)))
TERM_ORDER <- vapply(TERMS, `[[`, character(1), "key")
INSIGHTS <- setNames(lapply(ALL_IDS, read_insights), ALL_IDS)
N_FACTS <- sum(vapply(INSIGHTS, function(x) length(x$facts), integer(1)))

# ---- UI building blocks ----------------------------------------------------
fmt_date  <- function(d) if (is.na(d)) "Undated" else format(d, "%d %B %Y")
fmt_words <- function(n) if (is.na(n)) "\u2014" else format(n, big.mark = ",")
fmt_num   <- function(n) format(n, big.mark = ",")

# Stat card (navy gradient, gold figure). The icon argument is kept for compatibility.
kpi <- function(value, label, icon_name = NULL, colour = NULL) {
  div(class = "stat-card", span(class = "stat-value", value), span(class = "stat-label", label))
}

hero <- function(kicker, title, subtitle, colour = "#1D4E89", badges = NULL) {
  div(class = "chapter-hero",
      div(class = "hero-chapter-num", kicker),
      tags$h1(class = "hero-title", title),
      tags$p(class = "hero-subtitle", subtitle),
      if (!is.null(badges)) div(class = "badge-row", lapply(badges, function(b) span(class = "hero-badge", b))))
}

pull_quote <- function(text, source = NULL) {
  div(class = "pull-quote",
      tags$p(class = "pq-text", paste0("\u201c", text, "\u201d")),
      if (!is.null(source)) tags$p(class = "pq-source", source))
}

insight_box <- function(title, ...) div(class = "insight-box", tags$h5(class = "ib-title", title), ...)

framework_card <- function(num, heading = NULL, body) {
  div(class = "framework-card",
      if (!is.null(num)) div(class = "fw-num", num),
      if (!is.null(heading)) tags$h5(heading),
      tags$p(body))
}

pager <- function(i) {
  n <- length(WORKS)
  div(class = "pager",
      if (i > 1) actionButton(paste0("prev_", WORKS[[i]]$id), paste0(" Previous: ", WORKS[[i - 1]]$code),
                              icon = icon("chevron-left"), class = "btn-pager"),
      if (i < n) actionButton(paste0("next_", WORKS[[i]]$id), paste0("Next: ", WORKS[[i + 1]]$code, " "),
                              icon = icon("chevron-right"), class = "btn-pager btn-pager-next"))
}

works_table <- function(works) {
  df <- data.frame(
    Term = vapply(works, function(w) sub(" Term.*", "", w$term_label), character(1)),
    Code = vapply(works, `[[`, character(1), "code"),
    Work = vapply(works, `[[`, character(1), "title"),
    Type = vapply(works, `[[`, character(1), "type"),
    `Hand-in` = vapply(works, function(w) fmt_date(w$hand_in), character(1)),
    Pages = vapply(works, `[[`, character(1), "pages_label"),
    Words = vapply(works, function(w) fmt_words(w$words), character(1)),
    check.names = FALSE, stringsAsFactors = FALSE)
  DT::datatable(df, rownames = FALSE, escape = TRUE, class = "cell-border stripe hover compact",
                options = list(pageLength = 25, dom = "ft", ordering = FALSE, scrollX = TRUE,
                               language = list(search = "Filter:", zeroRecords = "No matching works")))
}

# ---- Full-text reader pieces ----------------------------------------------
page_block <- function(n, title, text, ocr, q, whole) {
  h <- if (nzchar(trimws(q))) nrow(find_spans(text, q, whole)) + nrow(find_spans(ocr, q, whole)) else 0
  label <- if (nzchar(title)) title else paste("Page", n)
  div(class = "page-block",
      div(class = "page-head",
          span(class = "page-no", paste0("p. ", n, " \u00b7 ", label)),
          span(class = "page-tags",
               if (nzchar(ocr)) span(class = "page-ocr", "includes text read from images"),
               if (h > 0) span(class = "page-hits", paste(h, if (h == 1) "match" else "matches")))),
      div(class = "reader-text", HTML(hl_html(paste0(text, if (nzchar(ocr)) paste0("\n\n[Text inside an image, read by OCR]\n", ocr) else ""), q, whole))))
}

reader_tools <- function(id, search_label) {
  div(class = "reader-tools",
      div(class = "rt-search",
          textInput(paste0("q_", id), search_label, value = "",
                    placeholder = "Type a word or phrase, e.g. Rumelt or IRR")),
      div(class = "rt-opts",
          checkboxInput(paste0("whole_", id), "Whole words only", value = TRUE),
          radioButtons(paste0("mode_", id), "Show",
                       choices = c("Whole text" = "all", "Pages with matches only" = "hits"),
                       selected = "all", inline = TRUE)))
}

# ---- Work sub-tabs ----------------------------------------------------------
summary_panel <- function(w) {
  ins <- INSIGHTS[[w$id]]
  hl <- if (!is.null(ins$headline)) ins$headline[[1]] else list(value = fmt_date(w$hand_in), label = "Hand-in date")
  tagList(
    fluidRow(
      column(3, kpi(w$pages_label, "Printed pages")),
      column(3, kpi(fmt_words(w$words), "Word count (cover sheet)")),
      column(3, kpi(fmt_date(w$hand_in), "Hand-in date")),
      column(3, kpi(hl$value, hl$label))),
    pull_quote(w$subtitle, "Central question of the work"),
    fluidRow(
      column(7,
             insight_box("Summary", p(w$summary))),
      column(5,
             div(class = "info-box-plain",
                 tags$strong("Lecturer: "), if (is.null(w$lecturer)) "not stated" else w$lecturer, tags$br(),
                 tags$strong("Term: "), TERMS[[which(TERM_ORDER == w$term)]]$label, tags$br(),
                 tags$strong("Type: "), w$type, tags$br(),
                 tags$strong("Written for: "), ins$audience %||% "not stated", tags$br(),
                 tags$strong("Themes: "), paste(uv(ins$themes), collapse = ", "), tags$br(),
                 tags$a(href = w$file, download = paste0("Zubizarreta_", w$id, ".pdf"), target = "_blank",
                        class = "btn btn-default btn-sm pdf-link", icon("file-pdf"), " Original PDF")))),
    h4(class = "sub-h", "Key arguments"),
    fluidRow(tagList(lapply(seq_along(w$key), function(k)
      column(6, framework_card(sprintf("Argument %02d", k), NULL, w$key[k]))))),
    h4(class = "sub-h", "Conclusions and recommendations"),
    fluidRow(tagList(lapply(seq_along(w$conclusions), function(k)
      column(4, div(class = "success-box", tags$strong(sprintf("Conclusion %d", k)), tags$br(), w$conclusions[k]))))),
    h4(class = "sub-h", "Frameworks and concepts"),
    div(class = "tags", lapply(w$frameworks, function(f) span(class = "tag", f)))
  )
}

analysis_panel <- function(w) analysis_view(w$id, INSIGHTS[[w$id]])

insights_panel <- function(w) {
  is_pres <- grepl("presentation|slides", w$type, ignore.case = TRUE)
  ins <- INSIGHTS[[w$id]]
  if (is.null(ins)) return(div(class = "tip-box", "Insights for this work are not available yet."))
  tagList(
    headline_view(ins),
    p(class = "note", "Every chart and figure below comes from what the work itself states: its numbers, positions, ratings, plans and timelines. Values read from a chart in the original are marked as approximate, and any calculated figure says so."),
    div(class = "chart-grid", lapply(seq_along(ins$charts), function(k) chart_box(w$id, k, ins$charts[[k]]))),
    if (is_pres) tagList(
      h4(class = "sub-h", "Graphs and figures from the presentation"),
      p(class = "note", "Printed pages of the deck that carry charts, diagrams or tables, shown as they were presented."),
      uiOutput(paste0("slides_", w$id)))
  )
}

sources_panel <- function(w) {
  tagList(
    uiOutput(paste0("sources_", w$id)),
    fluidRow(
      column(6, plotly::plotlyOutput(paste0("ca_", w$id), height = "300px")),
      column(6, plotly::plotlyOutput(paste0("cy_", w$id), height = "300px")))
  )
}

work_tab <- function(i) {
  w <- WORKS[[i]]
  term <- TERMS[[which(TERM_ORDER == w$term)]]
  tabItem(
    tabName = w$tab,
    hero(paste(term$label, "\u00b7", w$type), w$title, w$subtitle, term$colour,
         badges = c(w$code, w$pages_label, paste(fmt_words(w$words), "words"), fmt_date(w$hand_in))),
    div(class = "subtab-wrap",
        tabsetPanel(id = paste0("sub_", w$id), selected = "summary",
                    tabPanel("Summary",   value = "summary",   br(), summary_panel(w)),
                    tabPanel("Analysis",  value = "analysis",  br(), analysis_panel(w)),
                    tabPanel("Insights",  value = "insights",  br(), insights_panel(w)),
                    tabPanel("Sources",   value = "sources",   br(), sources_panel(w)))),
    pager(i)
  )
}

# ---- Front matter, term, overview, tools ----------------------------------
front_tab <- function() {
  tabItem(
    tabName = "front",
    hero("Collection tools", "Cover, dedication, introductions and index",
         "Every page of the front matter, with its full text and any text read from images.", "#0B2545"),
    fluidRow(
      column(3, kpi("5", "Front pages")),
      column(3, kpi(fmt_num(sum(vapply(printed_pages("FRONT"), words_in, integer(1)))), "Words in front matter")),
      column(3, kpi("EN + ES", "Introductions")),
      column(3, kpi("Index p. 4", "Contents and hand-in dates"))),
    div(class = "subtab-wrap", div(style = "padding:22px 24px;",
      reader_tools("FRONT", "Search the front matter"),
      downloadButton("dl_FRONT", "Download text (.txt)", class = "btn-sm"),
      uiOutput("reader_FRONT")))
  )
}

term_tab <- function(t) {
  works <- works_in(t$key)
  pages <- sum(vapply(works, function(w) w$pages[2] - w$pages[1] + 1, numeric(1)))
  words <- sum(vapply(works, function(w) if (is.na(w$words)) 0 else w$words, numeric(1)))
  dates <- do.call(c, lapply(works, function(w) w$hand_in))
  range_txt <- if (all(is.na(dates))) "Undated" else
    paste(format(min(dates, na.rm = TRUE), "%d %b"), "\u2013", format(max(dates, na.rm = TRUE), "%d %b %Y"))
  tabItem(
    tabName = t$tab,
    hero(paste("Term \u00b7", length(works), "works"), t$label, t$intro, t$colour),
    fluidRow(
      column(3, kpi(length(works), "Works in this term")),
      column(3, kpi(pages, "Printed pages")),
      column(3, kpi(fmt_num(words), "Words (where stated)")),
      column(3, kpi(range_txt, "Hand-in range"))),
    h4(class = "sub-h", "Works in this term"),
    fluidRow(tagList(lapply(works, function(w)
      column(4, div(class = "chapter-card",
                    div(class = "ch-num", paste(w$code, "\u00b7", w$type, "\u00b7", fmt_date(w$hand_in))),
                    div(class = "ch-title", w$title),
                    div(class = "ch-desc", w$summary),
                    div(class = "ch-tags", lapply(w$frameworks, function(f) span(class = "topic-tag", f)))))))),
    fluidRow(
      box(width = 7, title = "What this term's works are about", status = "primary", solidHeader = TRUE,
          plotly::plotlyOutput(paste0("tw_", t$key), height = "360px"),
          p(class = "note", "Number of works in the term that treat each theme as central.")),
      box(width = 5, title = "Index of works", status = "primary", solidHeader = TRUE,
          DT::DTOutput(paste0("tbl_", t$key))))
  )
}

overview_tab <- function() {
  tabItem(
    tabName = "overview",
    hero("MBA 2024\u20132025 \u00b7 Cambridge Judge Business School",
         "Works & Essays",
         "Main submitted work completed by Jose Francisco Zubizarreta Rodriguez across the Michaelmas, Lent, Easter and Summer terms.",
         badges = c("20 works", "4 terms", "200 numbered pages")),
    fluidRow(
      column(3, kpi(length(WORKS), "Works and deliveries")),
      column(3, kpi(4, "Terms")),
      column(3, kpi("200", "Numbered pages")),
      column(3, kpi(N_FACTS, "Facts and figures documented"))),
    h4(class = "sub-h", "The four terms"),
    fluidRow(tagList(lapply(TERMS, function(t) {
      ws <- works_in(t$key)
      column(3, div(class = "chapter-card",
                    div(class = "ch-num", paste(length(ws), "works")),
                    div(class = "ch-title", t$label),
                    div(class = "ch-desc", t$intro)))
    }))),
    fluidRow(
      box(width = 12, title = "Search the whole collection", status = "primary", solidHeader = TRUE,
          fluidRow(
            column(6, textInput("q_all", "Search all 20 works", value = "",
                                placeholder = "Type a word or phrase, e.g. Blue Ocean, DMADV, pollution")),
            column(3, checkboxInput("whole_all", "Whole words only", value = TRUE)),
            column(3, div(style = "padding-top:28px", uiOutput("hits_summary")))),
          DT::DTOutput("hits_all"))),
    fluidRow(
      box(width = 6, title = "Themes across the four terms", status = "primary", solidHeader = TRUE,
          plotly::plotlyOutput("plot_pie", height = "380px"),
          p(class = "note", "How many works treat each theme as central, coloured by term.")),
      box(width = 6, title = "About this collection", status = "primary", solidHeader = TRUE,
          p(class = "lead", "This document brings together the main submitted essays, presentations and projects completed during the MBA 2024\u20132025 at the University of Cambridge Judge Business School."),
          p("Some subjects did not require an essay, presentation or project: for these, the main grading criterion was a final examination, so no written work from those subjects appears here."),
          p("For the full curriculum, see ",
            tags$a(href = "https://www.jbs.cam.ac.uk/masters-degrees/mba/curriculum/", target = "_blank",
                   "jbs.cam.ac.uk \u2014 MBA curriculum"), "."))),
    fluidRow(
      box(width = 12, title = "Contents", status = "info", solidHeader = TRUE, DT::DTOutput("tbl_all")))
  )
}

analytics_tab <- function() {
  tabItem(
    tabName = "analytics",
    hero("Collection tools", "Analytics",
         "What the twenty works are about, who they are written for, every fact and figure they state, and a side-by-side comparison of any two works.",
         badges = c("Theme map", "Audiences", "Facts explorer", "Compare two works")),
    fluidRow(
      box(width = 12, title = "Theme map: what each work is about", status = "primary", solidHeader = TRUE,
          plotly::plotlyOutput("plot_theme_map", height = "760px"),
          p(class = "note", "A dark cell means the theme is central to the work. Works run in hand-in order from Michaelmas at the top to Summer at the bottom: read across a row for a work's subjects, or down a column to see where a theme recurs through the year."))),
    fluidRow(
      box(width = 6, title = "Who the works are written for", status = "primary", solidHeader = TRUE,
          plotly::plotlyOutput("plot_audience", height = "300px")),
      box(width = 6, title = "About these views", status = "primary", solidHeader = TRUE,
          p(class = "note", "The main reader each work addresses: boards and executives, investors, a client organisation, the public and policy makers, or the course assessors."),
          div(class = "info-box-plain", tags$strong(N_FACTS), " facts and figures are documented across the collection, each with its printed page. Explore them below."))),
    fluidRow(
      box(width = 12, title = "Every fact and figure in the collection", status = "primary", solidHeader = TRUE,
          DT::DTOutput("facts_all"))),
    fluidRow(
      box(width = 12, title = "Compare two works", status = "primary", solidHeader = TRUE,
          fluidRow(
            column(6, selectInput("cmp_a", "First work", choices = ID_CHOICES, selected = "MBA130")),
            column(6, selectInput("cmp_b", "Second work", choices = ID_CHOICES, selected = "MBA98"))),
          uiOutput("cmp_profiles")))
  )
}

timeline_tab <- function() {
  tabItem(
    tabName = "timeline",
    hero("Collection tools", "Timeline & index",
         "Hand-in dates across the four terms, word counts where the cover sheets state them, and a searchable index of every work.",
         badges = c("Hand-in dates", "Word counts", "Index")),
    fluidRow(
      box(width = 12, title = "Hand-in timeline", status = "primary", solidHeader = TRUE,
          plotly::plotlyOutput("plot_timeline", height = "660px"),
          p(class = "note", "The Cambridge Venture Project presentation is undated and is not shown on the timeline."))),
    fluidRow(
      box(width = 12, title = "Index of works and page numbers", status = "info", solidHeader = TRUE,
          DT::DTOutput("tbl_index")))
  )
}

about_tab <- function() {
  tabItem(
    tabName = "about",
    hero("Notes", "About and method", "How this edition was built and how to read it.",
         badges = c("Printed text", "OCR", "Text analysis")),
    fluidRow(
      box(width = 6, title = "Source and page numbers", status = "primary", solidHeader = TRUE,
          p("All text comes from the printed collection, Jose_Zubizarreta_MBA_Works_and_Essays. Page numbers are the printed numbers: the cover, dedication and both introductions are unnumbered, and the index is page 4."),
          p("Hand-in dates are taken from the index. Word counts are shown only where the cover sheet states them.")),
      box(width = 6, title = "Text and analysis", status = "primary", solidHeader = TRUE,
          p("Printed text is extracted page by page. Pages that contain images are also read with OCR, and any text not already in the printed text is added and labelled."),
          p("The Summary, Analysis and Insights tabs were written from a close reading of each work, including the charts and tables inside slide images. Every figure in them is stated in the work and carries its printed page; values read from a chart are marked as approximate and calculated values are labelled. The Sources tab is computed from the text."))),
    fluidRow(
      box(width = 12, title = "Credits", status = "info", solidHeader = TRUE,
          div(class = "credits",
              tags$img(src = "img/crest.png", alt = "Crest", class = "credit-crest"),
              div(p(tags$strong("Jose Francisco Zubizarreta Rodriguez"), " \u00b7 MBA 2024\u20132025 \u00b7 Cambridge Judge Business School"),
                  p("Master of Business Administration \u00b7 Finance Concentration \u00b7 Graduate of the Spark 1.0 Programme at King's College Entrepreneurship Lab."),
                  tags$img(src = "img/jbs_logo.jpg", alt = "Cambridge Judge Business School", class = "credit-logo")))))
  )
}

# ---- Sidebar ---------------------------------------------------------------
term_menu <- function(t) {
  works <- works_in(t$key)
  subs <- c(
    list(menuSubItem("Term overview", tabName = t$tab, icon = icon("info-circle"))),
    lapply(works, function(w) menuSubItem(paste0(w$code, " \u00b7 ", w$short), tabName = w$tab)))
  do.call(menuItem, c(list(text = t$label, icon = icon(t$icon), startExpanded = FALSE), subs))
}

ui <- dashboardPage(
  title = "Works & Essays \u00b7 MBA 2024\u20132025",
  skin = "black",
  dashboardHeader(title = span(icon("graduation-cap"), " Works & Essays"), titleWidth = 280),
  dashboardSidebar(
    width = 280,
    div(class = "sidebar-brand",
        tags$img(src = "img/crest.png", alt = "Crest"),
        div(class = "sidebar-name", "Jose F. Zubizarreta Rodriguez",
            span(class = "sidebar-sub", "MBA 2024\u20132025"))),
    sidebarMenu(
      id = "menu",
      menuItem("Collection overview", tabName = "overview", icon = icon("home")),
      tags$li(class = "header", "TERMS"),
      lapply(TERMS, term_menu),
      tags$li(class = "header", "TOOLS"),
      menuItem("Front matter", tabName = "front", icon = icon("book-open")),
      menuItem("Analytics", tabName = "analytics", icon = icon("chart-bar")),
      menuItem("Timeline & index", tabName = "timeline", icon = icon("calendar-alt")),
      menuItem("About and method", tabName = "about", icon = icon("info-circle")))
  ),
  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
      tags$meta(name = "viewport", content = "width=device-width, initial-scale=1")),
    do.call(tabItems, c(list(overview_tab()),
                        lapply(TERMS, term_tab),
                        lapply(seq_along(WORKS), work_tab),
                        list(front_tab(), analytics_tab(), timeline_tab(), about_tab()))))
)

# ---- Server ------------------------------------------------------------------
server <- function(input, output, session) {

  # Term and index tables
  for (t in TERMS) local({
    key <- t$key
    output[[paste0("tbl_", key)]] <- DT::renderDT(works_table(works_in(key)))
    output[[paste0("tw_", key)]] <- plotly::renderPlotly(plot_term_themes(INSIGHTS, works_in(key), term_col(key)))
  })
  output$tbl_all <- DT::renderDT(works_table(WORKS))
  output$tbl_index <- DT::renderDT(works_table(WORKS))

  # Overview and timeline charts
  output$plot_pie <- plotly::renderPlotly(plot_theme_counts(INSIGHTS, WORKS, TERMS, term_col))
  output$plot_timeline <- plotly::renderPlotly(plot_timeline(WORKS, term_col))

  # Collection-wide search
  all_hits <- reactive({
    q <- trimws(input$q_all %||% "")
    whole <- isTRUE(input$whole_all)
    if (!nzchar(q)) return(NULL)
    rows <- list()
    for (w in WORKS) {
      txs <- page_texts(w$id); nums <- page_nums(w$id)
      for (k in seq_along(txs)) {
        if (nrow(find_spans(txs[k], q, whole)) == 0) next
        for (s in snippets(txs[k], q, max_n = 2, whole = whole)) {
          rows[[length(rows) + 1]] <- data.frame(
            Work = as.character(htmltools::htmlEscape(paste0(w$code, " \u00b7 ", w$short))),
            Page = nums[k], Passage = s, stringsAsFactors = FALSE)
        }
      }
    }
    if (length(rows) == 0) return(data.frame(Work = character(), Page = integer(), Passage = character()))
    do.call(rbind, rows)
  })

  output$hits_summary <- renderUI({
    h <- all_hits()
    if (is.null(h)) return(span(class = "note", "Type a word to search."))
    span(class = "hits-count", strong(fmt_num(nrow(h))), " passages in ", length(unique(h$Work)), " works")
  })

  output$hits_all <- DT::renderDT({
    h <- all_hits()
    if (is.null(h)) h <- data.frame(Work = character(), Page = integer(), Passage = character())
    DT::datatable(head(h, 300), rownames = FALSE, escape = FALSE, class = "cell-border stripe hover compact",
                  options = list(pageLength = 10, dom = "tip", ordering = FALSE, scrollX = TRUE,
                                 language = list(search = "Filter:", info = "Showing _START_\u2013_END_ of _TOTAL_",
                                                 zeroRecords = "Type a word above to search the collection",
                                                 emptyTable = "Type a word above to search the collection")))
  })

  # Analytics: themes, audiences, facts and profile comparison
  output$plot_theme_map <- plotly::renderPlotly(plot_theme_map(INSIGHTS, WORKS))
  output$plot_audience <- plotly::renderPlotly(plot_audience(INSIGHTS, WORKS))
  output$facts_all <- DT::renderDT({
    DT::datatable(all_facts_table(INSIGHTS, WORKS), rownames = FALSE, class = "cell-border stripe hover compact",
                  filter = "top",
                  options = list(pageLength = 15, dom = "ftip", scrollX = TRUE,
                                 language = list(search = "Search the facts:")))
  })
  output$cmp_profiles <- renderUI(compare_profiles(INSIGHTS, WORK_BY_ID, input$cmp_a %||% "MBA130", input$cmp_b %||% "MBA98"))

  # Per-work outputs
  for (w in WORKS) local({
    id <- w$id
    colr <- term_col(w$term)

    # Insights tab: one plotly output per chart defined for the work
    ins <- INSIGHTS[[id]]
    for (k in seq_along(ins$charts)) local({
      ch <- ins$charts[[k]]
      if (ch$type %in% PLOTLY_TYPES)
        output[[paste0("ich_", id, "_", k)]] <- plotly::renderPlotly(build_chart(ch))
    })

    # Sources tab: citation table
    output[[paste0("sources_", id)]] <- renderUI({
      cs <- citation_summary(id)
      if (nrow(cs) == 0) return(div(class = "tip-box", "No in-text author-date citations were detected in this work."))
      rows <- lapply(seq_len(min(nrow(cs), 40)), function(k)
        tags$tr(tags$td(cs$author[k]), tags$td(cs$year[k]), tags$td(cs$count[k])))
      tagList(
        p(class = "note", paste(nrow(cs), "distinct author-year citations, most frequent first.")),
        tags$table(class = "algo-table",
                   tags$thead(tags$tr(tags$th("Author or organisation"), tags$th("Year"), tags$th("Mentions"))),
                   tags$tbody(rows)))
    })

    output[[paste0("slides_", id)]] <- renderUI({
      items <- SLIDE_INDEX[[id]]
      if (is.null(items) || length(items) == 0) return(NULL)
      div(class = "slide-grid",
          lapply(items, function(s)
            div(class = "slide-card",
                tags$a(href = s$file, target = "_blank", title = "Open full size",
                       tags$img(src = s$file, alt = s$caption, class = "slide-img", loading = "lazy")),
                div(class = "slide-cap", tags$strong(paste0("Printed page ", s$page)), tags$br(), s$caption))))
    })
    output[[paste0("cy_", id)]] <- plotly::renderPlotly(plot_cite_years(id, colr))
    output[[paste0("ca_", id)]] <- plotly::renderPlotly(plot_cite_authors(id, colr))
  })

  # Front matter reader
  output$reader_FRONT <- renderUI({
    q <- trimws(input$q_FRONT %||% "")
    whole <- isTRUE(input$whole_FRONT)
    pgs <- TEXT_DB$FRONT$pages
    ttls <- page_titles("FRONT"); nums <- page_nums("FRONT")
    txts <- vapply(pgs, function(p) p$text, character(1)); ocrs <- page_ocr("FRONT")
    blocks <- lapply(seq_along(pgs), function(k) page_block(nums[k], ttls[k], txts[k], ocrs[k], q, whole))
    bar <- NULL
    if (nzchar(q)) {
      total <- sum(vapply(seq_along(pgs), function(k) nrow(find_spans(txts[k], q, whole)) + nrow(find_spans(ocrs[k], q, whole)), integer(1)))
      bar <- div(class = "match-bar", strong(total), if (total == 1) " match" else " matches", " in the front matter")
    }
    div(class = "reader", bar, blocks)
  })
  output$dl_FRONT <- downloadHandler(
    filename = function() "Zubizarreta_front_matter_text.txt",
    content = function(file) writeLines(full_text("FRONT"), file, useBytes = TRUE))

  # Previous / Next buttons move through the collection in order
  invisible(lapply(seq_along(WORKS), function(i) {
    id <- WORKS[[i]]$id
    if (i > 1) observeEvent(input[[paste0("prev_", id)]], updateTabItems(session, "menu", WORKS[[i - 1]]$tab))
    if (i < length(WORKS)) observeEvent(input[[paste0("next_", id)]], updateTabItems(session, "menu", WORKS[[i + 1]]$tab))
  }))
}

shinyApp(ui = ui, server = server)
