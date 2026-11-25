# app.R — DSA Interactive Academy
# Modular R Shiny app: one module per topic in modules/, shared helpers in global.R.
# Run with:  shiny::runApp()

source("global.R", local = TRUE, keep.source = TRUE)
options(shiny.fullstacktrace = TRUE)   # if anything fails, the console shows the full call stack with file and line   # keep.source: error messages name the file and line

# Topic catalogue: drives the sidebar, the overview cards and the progress chart
CATALOGUE <- list(
  list(group = "Practice", icon = "laptop-code", items = list(
    list(tab = "workspace",  label = "Problem Workspace",      blurb = "Write Python, run it on examples and your own tests, submit against hidden tests."),
    list(tab = "interview",  label = "Mock Interview",         blurb = "Timed Meta- and Google-style rounds, no code execution, graded and self-scored."),
    list(tab = "airound",    label = "AI-Assisted Round",      blurb = "Multi-file project, a flawed AI suggestion to review, your tests audited against mutants."),
    list(tab = "reading",    label = "Code Reading",           blurb = "Predict output, spot the bug, state the complexity, explain unfamiliar code."),
    list(tab = "behavioural", label = "Behavioural",           blurb = "STAR story bank, competency coverage, timed questions with self-scoring."),
    list(tab = "designprac", label = "Design Interview",       blurb = "Worked system designs step by step, then timed mocks with a coverage checklist."),
    list(tab = "myprogress", label = "My Progress",            blurb = "Saved history, streaks, time on task, weak topics and spaced reviews."))),
  list(group = "Foundations", icon = "compass", items = list(
    list(tab = "bigo",     label = "Big-O & Complexity",       blurb = "Growth rates, constraints → target complexity, amortised cost."),
    list(tab = "patterns", label = "Pattern Finder",           blurb = "Clue → pattern guide, searchable problem bank, study plan."))),
  list(group = "Linear Structures", icon = "layer-group", items = list(
    list(tab = "arrays",      label = "Arrays & Strings",      blurb = "Binary search, two pointers, sliding window, prefix sums, Kadane."),
    list(tab = "linkedlists", label = "Linked Lists",          blurb = "Pointer reversal, Floyd's cycle detection, merging."),
    list(tab = "stacks",      label = "Stacks & Queues",       blurb = "Bracket matching, monotonic stack, postfix evaluation."),
    list(tab = "hashing",     label = "Hash Tables",           blurb = "Collisions, load factor, complement lookup, grouping keys."),
    list(tab = "matrix",      label = "Matrices & Intervals",  blurb = "Spiral / diagonal / rotate, sweep line, interval two pointers."))),
  list(group = "Trees & Graphs", icon = "sitemap", items = list(
    list(tab = "trees",    label = "Trees & BSTs",             blurb = "Four traversals, search, LCA, why balance matters."),
    list(tab = "heaps",    label = "Heaps",                    blurb = "Heapify, sift up / down, top-K, running median."),
    list(tab = "graphs",   label = "Graphs",                   blurb = "BFS, DFS, Dijkstra, topological sort, grid search."),
    list(tab = "advanced", label = "Tries & Union-Find",       blurb = "Prefix trees, disjoint sets, Kruskal's MST."),
    list(tab = "rangeq",   label = "Range Queries",            blurb = "Fenwick tree lowbit walks, segment-tree queries, which structure when."))),
  list(group = "Algorithm Paradigms", icon = "gears", items = list(
    list(tab = "sorting",   label = "Sorting & Searching",     blurb = "Six sorts animated, the race chart, stability, search on answer."),
    list(tab = "recursion", label = "Recursion & Backtracking", blurb = "Decision trees, N-Queens with pruning, generators."),
    list(tab = "dp",        label = "Dynamic Programming",     blurb = "Call trees, table filling for LCS / edit distance / knapsack."),
    list(tab = "greedy",    label = "Greedy",                  blurb = "Interval scheduling, where greedy fails, Huffman coding."),
    list(tab = "bits",      label = "Bit Manipulation",        blurb = "Operators bit by bit, XOR cancellation, masks as sets."),
    list(tab = "random",    label = "Randomised Algorithms",   blurb = "Weighted pick, reservoir sampling, Fisher–Yates, rejection sampling — with experiments."))),
  list(group = "Beyond Code", icon = "server", items = list(
    list(tab = "systemdesign", label = "System Design",        blurb = "Capacity maths, consistent hashing, LRU, rate limiting."),
    list(tab = "design",       label = "Iterators & Class Design", blurb = "BST / nested iterators, RandomizedSet, amortised O(1) state."))),
  list(group = "APIs", icon = "plug", items = list(
    list(tab = "bigquery", label = "BigQuery",                 blurb = "Service-account connection, the tables every record is stored in, sync status and log."),
    list(tab = "drive", label = "Google Drive",                blurb = "Where diagram exports are saved, the folder scheme, and how other apps read them.")))
)
ALL_ITEMS <- unlist(lapply(CATALOGUE, function(g) g$items), recursive = FALSE)
TAB_LABEL <- setNames(vapply(ALL_ITEMS, function(i) i$label, ""), vapply(ALL_ITEMS, function(i) i$tab, ""))

# ── UI ────────────────────────────────────────────────────────────────────────
sidebar_groups <- lapply(CATALOGUE, function(g) {
  do.call(menuItem, c(list(text = g$group, icon = icon(g$icon), startExpanded = g$group != "Beyond Code"),
    lapply(g$items, function(i) menuSubItem(i$label, tabName = i$tab))))
})

module_tabs <- lapply(names(TAB_LABEL), function(tab) {
  tabItem(tabName = tab, get(paste0(tab, "_ui"))(tab))
})

overview_tab <- tabItem(tabName = "overview",
  topic_hero("🎓", "DSA Interactive Academy",
    "Learn data structures and algorithms by watching them run. Every topic has step-through visualisers you control, the reasoning behind the technique, code templates to memorise, a quiz, and curated practice problems.",
    c(paste(length(PRACTICE_IDS), "problems with a built-in judge"), "Mock interviews", "AI-assisted round", "Behavioural & design practice",
      "Progress saved between sessions", paste(sum(vapply(CATALOGUE, function(g) if (g$group %in% c("Practice", "APIs")) 0L else length(g$items), 1L)), "topic modules"),
      "70+ visualisers", "Diagram export to Google Drive")),
  fluidRow(
    box(title = "Practice dashboard", status = "success", solidHeader = TRUE, width = 12,
      uiOutput("practice_summary"))
  ),
  fluidRow(
    box(title = "Choose a topic", status = "primary", solidHeader = TRUE, width = 8,
      lapply(CATALOGUE, function(g) tagList(
        tags$div(class = "code-title", style = "margin:6px 0 8px; text-transform:uppercase; letter-spacing:.06em; font-size:11px; color:#64748b;", g$group),
        tags$div(class = "topic-grid", style = "margin-bottom:14px;",
          lapply(g$items, function(i)
            tags$div(class = "topic-card", onclick = js_set("goto_tab", sprintf("'%s'", i$tab)), tags$h5(i$label), tags$p(i$blurb))))
      ))
    ),
    box(title = "How each topic is organised", status = "info", solidHeader = TRUE, width = 4,
      callout("<b>🎬 Visualise</b> — edit the inputs, then step, rewind or press Play. Coloured states, pointer labels and highlighted pseudocode show exactly what the algorithm is doing and why.", "info"),
      callout("<b>💡 Understand</b> — when to reach for the technique, the pitfalls that cost people offers, complexity tables and Python templates.", "tip"),
      callout("<b>📝 Practise</b> — a scored quiz and LeetCode problems ordered easy → hard, each tagged with the pattern that solves it.", "success"),
      hint("New here? Start with <b>Big-O</b>, then <b>Pattern Finder</b>, then work down the sidebar.")
    )
  ),
  fluidRow(
    box(title = "Quiz progress (best saved score per topic)", status = "warning", solidHeader = TRUE, width = 8,
      uiOutput("prog_kpi"), plotlyOutput("prog_plot", height = "470px")),
    box(title = "Suggested learning path", status = "success", solidHeader = TRUE, width = 4,
      cplx_table(data.frame(
        Stage = c("1", "2", "3", "4", "5", "6", "7"),
        Topics = c("Big-O → Arrays → Hash Tables", "Linked Lists → Stacks & Queues → Sorting", "Trees → Heaps", "Graphs → Tries & Union-Find",
                   "Recursion → Dynamic Programming", "Greedy → Bits → System Design", "Mock interviews every few days; keep reviews at zero"),
        stringsAsFactors = FALSE)),
      hint("Each stage builds on the one before: trees need recursion-style thinking, graphs reuse queues and heaps, DP grows out of backtracking."))
  )
)

ui <- dashboardPage(
  skin = "blue", title = "DSA Interactive Academy",
  dashboardHeader(
    title = tags$span(tags$span(style = "color:#a5b4fc; font-weight:800;", "DSA"), tags$span(style = "font-weight:400;", " Academy")),
    titleWidth = 240),
  dashboardSidebar(width = 240,
    do.call(sidebarMenu, c(list(id = "sidebar_menu",
      menuItem("Overview", tabName = "overview", icon = icon("house"), selected = TRUE)), sidebar_groups)),
    bq_status_box()),
  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", href = "css/global.css"),
      tags$script(src = "ace/ace.js"),
      tags$script(HTML("ace.config.set('basePath', 'ace');")),
      tags$script(src = "ace/ext-language_tools.js"),
      tags$script(src = "js/practice.js"),
      tags$script(src = "vendor/html-to-image.js"),
      tags$script(src = "vendor/jspdf.umd.min.js"),
      tags$script(src = "vendor/gifenc.js"),
      tags$script(src = "js/export.js"),
      # Plotly charts inside tabs need a resize nudge when their tab becomes visible
      tags$script(HTML("$(document).on('shown.bs.tab', function() { setTimeout(function() { $(window).trigger('resize'); }, 60); });"))
    ),
    do.call(tabItems, c(list(overview_tab), module_tabs))
  )
)

# ── Server ───────────────────────────────────────────────────────────────────
server <- function(input, output, session) {
  progress <- reactiveValues()          # topic -> c(correct, answered, total), filled by each module's quiz
  bus <- reactiveValues(open_problem = NULL, ws_problem = NULL, db_tick = 0)   # cross-module messages

  for (tab in names(TAB_LABEL)) {
    fn <- get(paste0(tab, "_server"))
    if ("bus" %in% names(formals(fn))) fn(tab, progress, bus) else fn(tab, progress)
  }

  # Diagram export (⤓ Save buttons on every diagram)
  GROUP_OF <- unlist(lapply(CATALOGUE, function(g) setNames(rep(g$group, length(g$items)), vapply(g$items, function(i) i$tab, ""))))
  export_server(input, output, session, bus = bus,
                topic_info = function(tab) list(label = if (tab %in% names(TAB_LABEL)) TAB_LABEL[[tab]] else if (tab == "overview") "Overview" else tab,
                                                group = if (tab %in% names(GROUP_OF)) GROUP_OF[[tab]] else "General"))

  observeEvent(input$goto_tab, {
    updateTabItems(session, "sidebar_menu", input$goto_tab)
  })

  # "Solve here" buttons anywhere in the app
  observeEvent(input$open_problem, {
    bus$open_problem <- list(id = input$open_problem, nonce = Sys.time())
    updateTabItems(session, "sidebar_menu", "workspace")
  })

  # Time on task: the browser pings every 15 s while the window is active
  observeEvent(input$dsa_heartbeat, {
    if (identical(input$sidebar_menu, "workspace") && !is.null(bus$ws_problem)) db_add_time(bus$ws_problem, 15)
  })

  # Save each completed topic quiz
  quiz_done <- new.env()
  observe({
    p <- reactiveValuesToList(progress)
    for (t in names(p)) {
      v <- p[[t]]
      if (v[["answered"]] == 0) quiz_done[[t]] <- FALSE
      if (v[["answered"]] == v[["total"]] && v[["total"]] > 0 && !isTRUE(quiz_done[[t]])) {
        quiz_done[[t]] <- TRUE
        db_quiz_attempt(t, v[["correct"]], v[["total"]])
        isolate(bus$db_tick <- bus$db_tick + 1)
      }
    }
  })

  output$practice_summary <- renderUI({
    bus$db_tick
    s <- db_problem_status(); iv <- db_interviews()
    nxt <- s[!s$solved, ]; nxt <- nxt[order(match(nxt$difficulty, c("Easy", "Medium", "Hard")), nxt$num), ]
    tagList(
      kpi_row(kpi(sprintf("%d / %d", sum(s$solved), nrow(s)), "problems solved", COL$ok),
              kpi(sum(s$due), "reviews due today", if (sum(s$due)) COL$err else COL$ok),
              kpi(db_streak(), "day streak", COL$warn),
              kpi(if (nrow(iv)) sprintf("%.0f", iv$total[1]) else "—", "last mock interview score", COL$acc)),
      tags$div(class = "stepper-btns",
        tags$button(class = "btn btn-dsa", onclick = js_set("goto_tab", "'workspace'"), "💻 Open the workspace"),
        if (sum(s$due)) tags$button(class = "btn btn-dsa", onclick = js_set("open_problem", sprintf("'%s'", s$id[s$due][1])), sprintf("🔁 Start reviews (%d due)", sum(s$due))),
        if (nrow(nxt)) tags$button(class = "btn btn-dsa-outline", onclick = js_set("open_problem", sprintf("'%s'", nxt$id[1])), sprintf("▶ Next unsolved: %s", nxt$title[1])),
        tags$button(class = "btn btn-dsa-outline", onclick = js_set("goto_tab", "'interview'"), "⏱️ Mock interview"),
        tags$button(class = "btn btn-dsa-outline", onclick = js_set("goto_tab", "'myprogress'"), "📈 My progress")),
      python_banner())
  })

  # Quiz progress: best saved score per topic (all sessions), plus this session's answers
  prog_df <- reactive({
    bus$db_tick
    p <- reactiveValuesToList(progress)
    q <- db_quiz_best()
    tabs <- intersect(names(TAB_LABEL), names(p))
    req(length(tabs) > 0)
    total <- vapply(tabs, function(t) p[[t]][["total"]], numeric(1))
    best <- q$best[match(tabs, q$topic)]
    data.frame(tab = tabs, label = unname(TAB_LABEL[tabs]), total = total,
               answered = vapply(tabs, function(t) p[[t]][["answered"]], numeric(1)),
               correct = vapply(tabs, function(t) p[[t]][["correct"]], numeric(1)),
               best = ifelse(is.na(best), NA, round(best * total)), stringsAsFactors = FALSE)
  })
  output$prog_kpi <- renderUI({
    d <- prog_df(); done <- !is.na(d$best)
    kpi_row(kpi(sprintf("%d / %d", sum(done), nrow(d)), "topic quizzes completed", COL$pri),
            kpi(sum(done & d$best == d$total), "perfect scores", COL$ok),
            kpi(if (any(done)) sprintf("%.0f%%", 100 * sum(d$best[done]) / sum(d$total[done])) else "—", "average best score", COL$acc),
            kpi(sprintf("%d", sum(d$answered)), "answered this session", COL$warn))
  })
  output$prog_plot <- renderPlotly({
    d <- prog_df(); lev <- rev(d$label); b <- ifelse(is.na(d$best), 0, d$best)
    plot_ly(height = 470) %>%
      add_bars(y = factor(d$label, levels = lev), x = b, orientation = "h", name = "best saved score", marker = list(color = COL$ok)) %>%
      add_bars(y = factor(d$label, levels = lev), x = d$total - b, orientation = "h", name = "remaining", marker = list(color = COL$idle)) %>%
      dsa_layout(xt = "questions", legend = TRUE) %>%
      layout(barmode = "stack", yaxis = list(title = "", categoryorder = "array", categoryarray = lev, dtick = 1, tickfont = list(size = 11.5)), xaxis = list(dtick = 1), bargap = 0.3, margin = list(l = 170))
  })

  # ── BigQuery: connect once the first page is on screen, keep the sidebar light current, write on exit ──
  session$onFlushed(function() {
    if (!isTRUE(.bq$startup_done)) { bq_startup(); isolate(bus$db_tick <- bus$db_tick + 1) }
  }, once = TRUE)
  output$bq_light <- renderUI({ bus$db_tick; invalidateLater(if (length(.bq$queue) || !isTRUE(.bq$startup_done)) 1500 else 5000); bq_status_light() })
  session$onSessionEnded(function() bq_flush("session ended"))
}

onStop(function() try(bq_flush("app stopped"), silent = TRUE))

shinyApp(ui, server)
