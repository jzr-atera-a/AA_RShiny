# modules/overview.R — Vol.2 Overview (complete 13 chapters)

overview_ui <- function(id) {
  ns <- NS(id)

  ch_info <- list(
    list("1",  "Getting Things in Order",     "Merge, in-place vs new-array, O(N log N) proof, bytecode",        c("Mergesort","O(N log N)","Divide & Conquer")),
    list("2",  "Benchmarking Code",           "timeit module, 3 gotchas, hybrid merge+insertion (Timsort)",       c("timeit","Benchmarking","Hybrid Sort")),
    list("3",  "How Random Is That?",         "PRNGs, LCG, Fisher-Yates, Power of Two Choices",                   c("PRNGs","Fisher-Yates","Load Balancing")),
    list("4",  "Cache Is King",               "LRU cache, DLL+hash table, randomized eviction, spatial locality", c("LRU Cache","Eviction","Cache-Friendly")),
    list("5",  "Red-Black Trees",             "5 RB rules, rotations, insert/delete fix-up, O(log N) guarantee",  c("Self-Balancing","Rotations","O(log N)")),
    list("6",  "Randomized Treaps",           "BST + min-heap, random priorities = self-balancing",               c("Treap","Random Priorities","Simple RBT")),
    list("7",  "B-Trees",                     "External memory, file-backed nodes, insertion & splitting",        c("B-Tree","External Memory","Database")),
    list("8",  "M/B-Way Mergesort",           "External sorting, min-heap K-way merge, optimal I/O",              c("K-Way Merge","Min-Heap","External Sort")),
    list("9",  "Monte Carlo Algorithms",      "Fermat primality test, Monte Carlo vs Las Vegas, random sampling",  c("Monte Carlo","FPT","Primality")),
    list("10", "Hash Tables + Randomization", "Division method, random prime, separate chaining",                  c("Division Method","Random Prime","Chaining")),
    list("11", "Rabin-Karp Substring Search", "Sliding window, rolling hash, base-26 mod prime, Las Vegas check", c("Rolling Hash","Rabin-Karp","O(N+M)")),
    list("12", "Saving Space with Bit Vectors","BitVector ops, 32x savings, counting sort, XOR tricks",           c("Bit Vector","Bitwise Ops","Counting Sort")),
    list("13", "Cultivating a Bloom Filter",  "Probabilistic set, k hash functions, optimal m & k, false positives",c("Bloom Filter","Probabilistic","Space Efficient"))
  )

  tagList(
    div(class = "chapter-hero",
        div(class = "hero-chapter-num", "Pragmatic Programmers \u00b7 2025"),
        tags$h1(class = "hero-title", "\U0001f4da A Common-Sense Guide to Data Structures & Algorithms in Python \u00b7 Volume 2"),
        tags$p(class = "hero-subtitle",
               "13 chapters covering advanced sorting, benchmarking, randomized algorithms, caching, ",
               "self-balancing trees, external-memory structures, Monte Carlo methods, advanced hashing, ",
               "substring search, bit vectors, and Bloom filters. All with runnable Python examples."),
        div(class = "badge-row",
            span(class="hero-badge","13 Chapters"),
            span(class="hero-badge","Python 3"),
            span(class="hero-badge","Live Execution"),
            span(class="hero-badge","Complete Coverage"))
    ),

    fluidRow(
      box(title="\U0001f4d6 About This App", status="info", solidHeader=TRUE, width=6,
          div(class="framework-card",
              tags$h5("Interactive Code Lab"),
              tags$p("Each chapter tab has a Theory tab and a Code Lab tab with every Python
                      file from the book's source code, runnable live via reticulate."),
              tags$ul(
                tags$li(tags$strong("Theory"), " \u2014 concepts, complexity analysis, comparison tables"),
                tags$li(tags$strong("Code Lab"), " \u2014 select any file, read the code, click Run"),
                tags$li(tags$strong("\u25b6 Run"), " \u2014 executes via Python 3 + reticulate")
              )),
          div(class="tip-box",
              HTML("<strong>\U0001f4a1 Setup:</strong> <code>install.packages('reticulate')</code>
                   then <code>reticulate::install_python()</code>"))),

      box(title="\U0001f5fa\ufe0f Full Book Structure", status="warning", solidHeader=TRUE, width=6,
          tags$table(class="algo-table",
            tags$thead(tags$tr(tags$th("Ch"), tags$th("Topic"), tags$th("Key Concept"))),
            tags$tbody(
              tags$tr(tags$td("1"),  tags$td("Mergesort"),              tags$td("O(N log N) \u00b7 Merge")),
              tags$tr(tags$td("2"),  tags$td("Benchmarking"),           tags$td("timeit \u00b7 Gotchas")),
              tags$tr(tags$td("3"),  tags$td("Randomization"),          tags$td("PRNGs \u00b7 Fisher-Yates")),
              tags$tr(tags$td("4"),  tags$td("Caching"),                tags$td("LRU \u00b7 Locality")),
              tags$tr(tags$td("5"),  tags$td("Red-Black Trees"),        tags$td("Self-balancing BST")),
              tags$tr(tags$td("6"),  tags$td("Treaps"),                 tags$td("BST + Heap")),
              tags$tr(tags$td("7"),  tags$td("B-Trees"),                tags$td("External memory")),
              tags$tr(tags$td("8"),  tags$td("M/B-Way Mergesort"),      tags$td("K-way merge")),
              tags$tr(tags$td("9"),  tags$td("Monte Carlo"),            tags$td("Primality \u00b7 Sampling")),
              tags$tr(tags$td("10"), tags$td("Hash + Randomization"),   tags$td("Division method")),
              tags$tr(tags$td("11"), tags$td("Rabin-Karp"),             tags$td("Rolling hash")),
              tags$tr(tags$td("12"), tags$td("Bit Vectors"),            tags$td("32x space saving")),
              tags$tr(tags$td("13"), tags$td("Bloom Filters"),          tags$td("Probabilistic sets"))
            )
          ))
    ),

    fluidRow(
      box(title="\U0001f4da All 13 Chapters", status="success", solidHeader=TRUE, width=12,
          fluidRow(
            column(3, lapply(ch_info[1:4],  function(i) div(class="chapter-card", div(class="ch-num",paste("Chapter",i[[1]])), div(class="ch-title",i[[2]]), div(class="ch-desc",i[[3]]), div(class="ch-tags",lapply(i[[4]],function(t) span(class="topic-tag",t)))))),
            column(3, lapply(ch_info[5:8],  function(i) div(class="chapter-card", div(class="ch-num",paste("Chapter",i[[1]])), div(class="ch-title",i[[2]]), div(class="ch-desc",i[[3]]), div(class="ch-tags",lapply(i[[4]],function(t) span(class="topic-tag",t)))))),
            column(3, lapply(ch_info[9:11], function(i) div(class="chapter-card", div(class="ch-num",paste("Chapter",i[[1]])), div(class="ch-title",i[[2]]), div(class="ch-desc",i[[3]]), div(class="ch-tags",lapply(i[[4]],function(t) span(class="topic-tag",t)))))),
            column(3, lapply(ch_info[12:13],function(i) div(class="chapter-card", div(class="ch-num",paste("Chapter",i[[1]])), div(class="ch-title",i[[2]]), div(class="ch-desc",i[[3]]), div(class="ch-tags",lapply(i[[4]],function(t) span(class="topic-tag",t))))))
          )
      )
    )
  )
}

overview_server <- function(id) {
  moduleServer(id, function(input, output, session) {})
}
