# modules/overview.R

overview_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "chapter-hero",
        div(class = "hero-chapter-num", "Manning Publications · 2nd Edition"),
        tags$h1(class = "hero-title", "📚 A Common-Sense Guide to Data Structures & Algorithms"),
        tags$p(class = "hero-subtitle",
               "An interactive code lab for Jay Wengrow's bestselling book. Each chapter pairs ",
               "clear theoretical explanations with the book's original Python code — runnable ",
               "live in your browser via R Shiny + reticulate."),
        div(class = "badge-row",
            span(class = "hero-badge", "12 Chapters"),
            span(class = "hero-badge", "Python 3"),
            span(class = "hero-badge", "Live Execution"),
            span(class = "hero-badge", "Big O Analysis"),
            span(class = "hero-badge", "Sorting · Hashing · Recursion")
        )
    ),

    fluidRow(
      box(title = "📖 About This App", status = "primary", solidHeader = TRUE, width = 6,
          div(class = "framework-card",
              tags$h5("What is this?"),
              tags$p("An interactive companion to Jay Wengrow's", tags$em("A Common-Sense Guide to Data Structures and Algorithms"),
                     "(Manning, 2nd Ed). Each chapter tab contains:"),
              tags$ul(
                tags$li(tags$strong("Theory tab"), " — Core concepts, complexity tables, visual examples"),
                tags$li(tags$strong("Code Lab tab"), " — Every Python file from the book's source code"),
                tags$li(tags$strong("▶ Run button"), " — Executes code live via reticulate (Python 3 required)")
              )
          ),
          div(class = "tip-box",
              HTML("<strong>💡 Tip:</strong> Python 3 must be installed on your system.
              The app uses <code>reticulate</code> to run code. Run <code>install.packages('reticulate')</code>
              then <code>reticulate::install_python()</code> if needed.")
          )
      ),
      box(title = "🗺️ Book Structure", status = "warning", solidHeader = TRUE, width = 6,
          div(class = "framework-card",
              tags$h5("Volume 1 Coverage (Chapters 1–12)"),
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Ch"), tags$th("Topic"), tags$th("Key Concept"))),
                tags$tbody(
                  tags$tr(tags$td("1"), tags$td("Why Data Structures Matter"), tags$td("Arrays & Operations")),
                  tags$tr(tags$td("2"), tags$td("Why Algorithms Matter"),       tags$td("Binary Search")),
                  tags$tr(tags$td("3"), tags$td("Big O Notation"),              tags$td("O(1) O(N) O(N²)")),
                  tags$tr(tags$td("4"), tags$td("Speeding Up with Big O"),      tags$td("Bubble Sort")),
                  tags$tr(tags$td("5"), tags$td("Optimising Code"),             tags$td("Selection Sort")),
                  tags$tr(tags$td("6"), tags$td("Optimistic Scenarios"),        tags$td("Insertion Sort")),
                  tags$tr(tags$td("7"), tags$td("Big O in Everyday Code"),      tags$td("Nested Loops")),
                  tags$tr(tags$td("8"), tags$td("Blazing Fast Lookup"),         tags$td("Hash Tables")),
                  tags$tr(tags$td("9"), tags$td("Crafting Elegant Code"),       tags$td("Stacks & Queues")),
                  tags$tr(tags$td("10"), tags$td("Recursively Recurse"),        tags$td("Base Cases")),
                  tags$tr(tags$td("11"), tags$td("Learning to Write Recursion"),tags$td("Subproblems")),
                  tags$tr(tags$td("12"), tags$td("Dynamic Programming"),        tags$td("Memoization")),
                  tags$tr(tags$td("13"), tags$td("Quicksort"),                   tags$td("Partition · Quickselect")),
                  tags$tr(tags$td("14"), tags$td("Linked Lists"),                tags$td("Nodes · Doubly LL · O(1) Queue")),
                  tags$tr(tags$td("15"), tags$td("Binary Search Trees"),         tags$td("BST · Traversals · Delete")),
                  tags$tr(tags$td("16"), tags$td("Heaps"),                       tags$td("Max-Heap · Priority Queue")),
                  tags$tr(tags$td("17"), tags$td("Tries"),                       tags$td("Prefix Tree · Autocomplete")),
                  tags$tr(tags$td("18"), tags$td("Graphs"),                      tags$td("DFS · BFS · Dijkstra")),
                  tags$tr(tags$td("19"), tags$td("Space Constraints"),           tags$td("Space-Time Trade-off")),
                  tags$tr(tags$td("20"), tags$td("Code Optimisation"),           tags$td("Kadane · Counting Sort · O(N) patterns"))
                )
              )
          )
      )
    ),

    fluidRow(
      box(title = "📚 Chapter Overview", status = "success", solidHeader = TRUE, width = 12,
          fluidRow(
            column(4,
              lapply(1:4, function(i) {
                info <- list(
                  list("1", "Why Data Structures Matter",    "Arrays, read/search/insert/delete, Sets", c("Arrays","Sets","O(1)","O(N)")),
                  list("2", "Why Algorithms Matter",         "Ordered arrays, linear vs binary search",  c("Binary Search","O(log N)")),
                  list("3", "Oh Yes! Big O Notation",        "Formal complexity classes and analysis",   c("Big O","O(N²)","Complexity")),
                  list("4", "Speeding Up Your Code",         "Bubble Sort and duplicate detection",      c("Bubble Sort","Optimisation"))
                )[[i]]
                div(class = "chapter-card",
                    div(class = "ch-num",   paste("Chapter", info[[1]])),
                    div(class = "ch-title", info[[2]]),
                    div(class = "ch-desc",  info[[3]]),
                    div(class = "ch-tags",  lapply(info[[4]], function(t) span(class="topic-tag", t)))
                )
              })
            ),
            column(4,
              lapply(5:8, function(i) {
                info <- list(
                  list("5", "Optimizing Code With & Without Big O","Selection Sort, constant factors",   c("Selection Sort","Write Ops")),
                  list("6", "Optimizing for Optimistic Scenarios", "Insertion Sort best/avg/worst cases",c("Insertion Sort","Best Case")),
                  list("7", "Big O in Everyday Code",              "Multi-dimension complexity analysis", c("O(N³)","Patterns")),
                  list("8", "Blazing Fast Lookup with Hash Tables","Hashing, collisions, sets",          c("Hash Tables","O(1)","Sets"))
                )[[i-4]]
                div(class = "chapter-card",
                    div(class = "ch-num",   paste("Chapter", info[[1]])),
                    div(class = "ch-title", info[[2]]),
                    div(class = "ch-desc",  info[[3]]),
                    div(class = "ch-tags",  lapply(info[[4]], function(t) span(class="topic-tag", t)))
                )
              })
            ),
            column(4,
              lapply(9:12, function(i) {
                info <- list(
                  list("9",  "Crafting Elegant Code with Stacks & Queues","LIFO/FIFO, linter, print manager", c("Stack","Queue","LIFO","FIFO")),
                  list("10", "Recursively Recurse",                        "Base cases, call stack, filesystem",c("Recursion","Base Case")),
                  list("11", "Learning to Write Recursion",                "Subproblems, anagrams, staircase",  c("Top-Down","Anagrams")),
                  list("12", "Dynamic Programming",                        "Memoization, Fibonacci, Golomb",    c("Memoization","DP","Fib"))
                )[[i-8]]
                div(class = "chapter-card",
                    div(class = "ch-num",   paste("Chapter", info[[1]])),
                    div(class = "ch-title", info[[2]]),
                    div(class = "ch-desc",  info[[3]]),
                    div(class = "ch-tags",  lapply(info[[4]], function(t) span(class="topic-tag", t)))
                )
              })
            )
          ),
          fluidRow(
            column(4,
              lapply(13:14, function(i) {
                info <- list(
                  list("13", "Quicksort",           "Partition, quicksort O(N log N), quickselect O(N)", c("Quicksort","Quickselect","Pivot","O(N log N)")),
                  list("14", "Linked Lists",         "Nodes, singly/doubly linked lists, O(1) queue",     c("Linked List","Node","Doubly","O(1) front"))
                )[[i-12]]
                div(class = "chapter-card",
                    div(class = "ch-num",   paste("Chapter", info[[1]])),
                    div(class = "ch-title", info[[2]]),
                    div(class = "ch-desc",  info[[3]]),
                    div(class = "ch-tags",  lapply(info[[4]], function(t) span(class="topic-tag", t)))
                )
              })
            ),
            column(4,
              lapply(15:16, function(i) {
                info <- list(
                  list("15", "Binary Search Trees",  "BST search/insert/delete, three traversals", c("BST","O(log N)","Traversal","Successor")),
                  list("16", "Heaps",                "Max-heap, trickle-up/down, priority queue",   c("Heap","Priority Queue","O(log N)","Heap Sort"))
                )[[i-14]]
                div(class = "chapter-card",
                    div(class = "ch-num",   paste("Chapter", info[[1]])),
                    div(class = "ch-title", info[[2]]),
                    div(class = "ch-desc",  info[[3]]),
                    div(class = "ch-tags",  lapply(info[[4]], function(t) span(class="topic-tag", t)))
                )
              })
            ),
            column(4,
              lapply(17:20, function(i) {
                info <- list(
                  list("17", "It Doesn't Hurt to Trie",         "Prefix tree, insert/search O(K), autocomplete, autocorrect", c("Trie","O(K)","Autocomplete","Autocorrect")),
                  list("18", "Connecting Everything with Graphs","DFS, BFS, shortest path, Dijkstra weighted graphs",         c("Graphs","DFS","BFS","Dijkstra")),
                  list("19", "Dealing with Space Constraints",   "Space-time trade-offs, in-place mutation, stack space",      c("Space","O(1)","In-place","Trade-off")),
                  list("20", "Techniques for Code Optimisation", "Kadane's, counting sort, mathematical insights, O(N)",       c("Kadane","O(N)","Counting Sort","Greedy"))
                )[[i-16]]
                div(class = "chapter-card",
                    div(class = "ch-num",   paste("Chapter", info[[1]])),
                    div(class = "ch-title", info[[2]]),
                    div(class = "ch-desc",  info[[3]]),
                    div(class = "ch-tags",  lapply(info[[4]], function(t) span(class="topic-tag", t)))
                )
              })
            )
          )
      )
    )
  )
}

overview_server <- function(id) {
  moduleServer(id, function(input, output, session) {})
}
