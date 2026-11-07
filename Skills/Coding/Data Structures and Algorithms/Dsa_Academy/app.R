# app.R — DSA Interactive Academy
# Modular R Shiny app covering all major DSA topics for interview preparation

source("global.R", local = TRUE)

# ── UI ────────────────────────────────────────────────────────────────────────
ui <- dashboardPage(
  skin = "black",

  dashboardHeader(
    title = tags$span(
      tags$span(style = "color:#818cf8; font-weight:800; font-size:16px;", "DSA"),
      tags$span(style = "color:#e2e8f0; font-weight:400; font-size:14px;", " Academy")
    ),
    titleWidth = 220
  ),

  dashboardSidebar(
    width = 220,
    tags$div(style = "padding:10px 15px 6px; font-size:10px; font-weight:700; color:#64748b; letter-spacing:.08em; text-transform:uppercase;",
             "Interview Prep"),
    sidebarMenu(
      id = "sidebar_menu",

      menuItem("🏠 Overview",      tabName = "overview",      icon = NULL),

      menuItem("📐 Arrays & Strings",   tabName = "arrays",   icon = NULL),
      menuItem("🔗 Linked Lists",       tabName = "linkedlists", icon = NULL),
      menuItem("📚 Stacks & Queues",    tabName = "stacks",   icon = NULL),
      menuItem("🌳 Trees & BSTs",       tabName = "trees",    icon = NULL),
      menuItem("🕸️ Graphs",             tabName = "graphs",   icon = NULL),
      menuItem("🧩 Dynamic Programming",tabName = "dp",       icon = NULL),
      menuItem("🔢 Sorting & Searching",tabName = "sorting",  icon = NULL),
      menuItem("🗂️ Hash Tables",        tabName = "hashing",  icon = NULL),
      menuItem("🏔️ Heaps",              tabName = "heaps",    icon = NULL),
      menuItem("🔄 Recursion & Backtracking", tabName = "recursion", icon = NULL),
      menuItem("💰 Greedy",             tabName = "greedy",   icon = NULL),
      menuItem("⚡ Bit Manipulation",   tabName = "bits",     icon = NULL),
      menuItem("🏗️ System Design",      tabName = "systemdesign", icon = NULL)
    )
  ),

  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", href = "css/global.css")
    ),

    tabItems(

      # ── Overview ─────────────────────────────────────────────────────────────
      tabItem(tabName = "overview",
        tags$div(class = "topic-hero",
          tags$div(class = "hero-icon", "🎓"),
          tags$div(
            tags$h3("DSA Interactive Academy"),
            tags$p("Master Data Structures & Algorithms for technical interviews. Each topic includes interactive visualisers, step-through animations, complexity references, Python code templates, and LeetCode problem lists."),
            tags$div(
              lapply(c("Arrays","Linked Lists","Stacks","Trees","Graphs","DP",
                       "Sorting","Hashing","Heaps","Recursion","Greedy","Bits","System Design"),
                     function(p) tags$span(class = "hero-pill", p))
            )
          )
        ),
        fluidRow(
          box(title = "How to Use This App", status = "primary", solidHeader = TRUE, width = 6,
            tags$ol(style = "font-size:13px; color:#475569; line-height:1.8;",
              tags$li("Pick a topic from the left sidebar"),
              tags$li("Read the concept summary at the top"),
              tags$li("Use the interactive visualiser to build intuition"),
              tags$li("Study the Python algorithm templates"),
              tags$li("Test yourself with the Quick Quiz"),
              tags$li("Practice on the curated LeetCode problems"),
              tags$li("Check the complexity table before your interview")
            )
          ),
          box(title = "Topics Covered", status = "info", solidHeader = TRUE, width = 6,
            cplx_table(data.frame(
              Topic         = c("Arrays & Strings","Linked Lists","Stacks & Queues","Trees & BSTs",
                                "Graphs","Dynamic Programming","Sorting","Hash Tables",
                                "Heaps","Recursion/Backtracking","Greedy","Bit Manipulation","System Design"),
              `Key Pattern` = c("Two-pointer, Sliding window","Floyd's, Dummy head","Monotonic stack","DFS/BFS traversals",
                                "BFS/DFS, Topo sort","Memoisation, Tabulation","Divide & conquer","Frequency map",
                                "Top-K, Median","Backtrack + prune","Local → global opt.","XOR, Bitmask","CAP, Sharding"),
              stringsAsFactors = FALSE
            ))
          )
        )
      ),

      # ── Topic tabs ──────────────────────────────────────────────────────────
      tabItem(tabName = "arrays",       arrays_ui("arrays")),
      tabItem(tabName = "linkedlists",  linkedlists_ui("linkedlists")),
      tabItem(tabName = "stacks",       stacks_ui("stacks")),
      tabItem(tabName = "trees",        trees_ui("trees")),
      tabItem(tabName = "graphs",       graphs_ui("graphs")),
      tabItem(tabName = "dp",           dp_ui("dp")),
      tabItem(tabName = "sorting",      sorting_ui("sorting")),
      tabItem(tabName = "hashing",      hashing_ui("hashing")),
      tabItem(tabName = "heaps",        heaps_ui("heaps")),
      tabItem(tabName = "recursion",    recursion_ui("recursion")),
      tabItem(tabName = "greedy",       greedy_ui("greedy")),
      tabItem(tabName = "bits",         bits_ui("bits")),
      tabItem(tabName = "systemdesign", systemdesign_ui("systemdesign"))
    )
  )
)

# ── Server ───────────────────────────────────────────────────────────────────
server <- function(input, output, session) {
  arrays_server("arrays")
  linkedlists_server("linkedlists")
  stacks_server("stacks")
  trees_server("trees")
  graphs_server("graphs")
  dp_server("dp")
  sorting_server("sorting")
  hashing_server("hashing")
  heaps_server("heaps")
  recursion_server("recursion")
  greedy_server("greedy")
  bits_server("bits")
  systemdesign_server("systemdesign")
}

shinyApp(ui, server)
