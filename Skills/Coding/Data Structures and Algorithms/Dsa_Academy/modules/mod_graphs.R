# modules/mod_graphs.R — Graphs & BFS/DFS

graphs_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🕸️", "Graphs & BFS / DFS",
      "Model relationships. Master BFS for shortest paths, DFS for cycle detection and topological sort.",
      c("BFS", "DFS", "Topological Sort", "Union-Find", "Dijkstra")),

    fluidRow(
      box(title = "Graph BFS / DFS Explorer", status = "primary", solidHeader = TRUE, width = 5,
        tags$p("Define edges as pairs (e.g. 0-1,0-2,1-3,2-3,3-4). Choose a start node and algorithm.",
               style = "font-size:12px; color:#555;"),
        textInput(ns("edges_input"), "Edges (u-v comma-separated):", value = "0-1,0-2,1-3,2-3,3-4,4-5"),
        fluidRow(
          column(6, numericInput(ns("start_node"), "Start node:", value = 0, min = 0, step = 1)),
          column(6, radioButtons(ns("algo"), "Algorithm:", choices = c("BFS","DFS"), inline = TRUE))
        ),
        actionButton(ns("btn_run"), "Run", class = "btn btn-dsa")
      ),
      box(title = "Visit Order", status = "info", solidHeader = TRUE, width = 7,
        uiOutput(ns("viz_graph")),
        uiOutput(ns("graph_explain"))
      )
    ),

    fluidRow(
      box(title = "Complexity Reference", status = "info", solidHeader = TRUE, width = 4,
        cplx_table(data.frame(
          Algorithm  = c("BFS", "DFS", "Dijkstra (heap)", "Topo Sort (Kahn)", "Union-Find"),
          Time       = c("O(V+E)", "O(V+E)", "O((V+E) log V)", "O(V+E)", "O(α(n)) ≈ O(1)"),
          Space      = c("O(V)", "O(V)", "O(V)", "O(V)", "O(V)"),
          stringsAsFactors = FALSE
        )),
        tags$br(),
        callout("<strong>BFS</strong> gives the shortest path (fewest edges) in an unweighted graph. <strong>DFS</strong> explores depth-first — useful for cycle detection, SCCs, and topological ordering.", "tip")
      ),
      box(title = "Key Algorithms (Python)", status = "primary", solidHeader = TRUE, width = 5,
        tags$p(tags$strong("BFS Shortest Path — O(V+E)"), style = "font-size:12px;"),
        dsa_code(
'from collections import deque
def bfs(graph, start):
    visited = {start}
    queue   = deque([start])
    order   = []
    while queue:
        node = queue.popleft()
        order.append(node)
        for nei in graph[node]:
            if nei not in visited:
                visited.add(nei)
                queue.append(nei)
    return order'),
        tags$p(tags$strong("DFS Iterative — O(V+E)"), style = "font-size:12px; margin-top:10px;"),
        dsa_code(
'def dfs(graph, start):
    visited = set()
    stack   = [start]
    order   = []
    while stack:
        node = stack.pop()
        if node in visited: continue
        visited.add(node)
        order.append(node)
        for nei in reversed(graph[node]):
            if nei not in visited:
                stack.append(nei)
    return order'),
        tags$p(tags$strong("Topological Sort (Kahn's) — O(V+E)"), style = "font-size:12px; margin-top:10px;"),
        dsa_code(
'from collections import deque
def topoSort(n, edges):
    graph  = [[] for _ in range(n)]
    indeg  = [0] * n
    for u, v in edges:
        graph[u].append(v); indeg[v] += 1
    q = deque(i for i in range(n) if indeg[i]==0)
    order = []
    while q:
        u = q.popleft(); order.append(u)
        for v in graph[u]:
            indeg[v] -= 1
            if indeg[v] == 0: q.append(v)
    return order if len(order)==n else []  # [] = cycle')
      ),
      box(title = "Quick Quiz", status = "warning", solidHeader = TRUE, width = 3,
        uiOutput(ns("quiz_ui"))
      )
    ),

    fluidRow(
      box(title = "LeetCode Problems", status = "success", solidHeader = TRUE, width = 6,
        fluidRow(
          column(6,
            prob_row(200, "Number of Islands",            "Medium", "https://leetcode.com/problems/number-of-islands/"),
            prob_row(133, "Clone Graph",                  "Medium", "https://leetcode.com/problems/clone-graph/"),
            prob_row(207, "Course Schedule",              "Medium", "https://leetcode.com/problems/course-schedule/"),
            prob_row(210, "Course Schedule II",           "Medium", "https://leetcode.com/problems/course-schedule-ii/")
          ),
          column(6,
            prob_row(994, "Rotting Oranges",              "Medium", "https://leetcode.com/problems/rotting-oranges/"),
            prob_row(127, "Word Ladder",                  "Hard",   "https://leetcode.com/problems/word-ladder/"),
            prob_row(743, "Network Delay Time",           "Medium", "https://leetcode.com/problems/network-delay-time/"),
            prob_row(787, "Cheapest Flights (K stops)",   "Medium", "https://leetcode.com/problems/cheapest-flights-within-k-stops/")
          )
        )
      ),
      box(title = "Traversal Cheatsheet", status = "info", solidHeader = TRUE, width = 6,
        callout("<strong>When to use BFS:</strong> shortest path in unweighted graph, level-order, spreading problems (islands, oranges).", "info"),
        callout("<strong>When to use DFS:</strong> cycle detection, topological sort, strongly connected components, maze solving.", "tip"),
        callout("<strong>Union-Find:</strong> dynamic connectivity, Kruskal's MST. Path compression + union by rank → near O(1) per op.", "info"),
        callout("<strong>Dijkstra:</strong> single-source shortest path with non-negative weights. Use a min-heap.", "info")
      )
    ),

    ref_block(
      "Cormen et al. (2009). Introduction to Algorithms (3rd ed.). MIT Press.",
      "Kleinberg & Tardos (2005). Algorithm Design. Addison-Wesley.",
      "Sedgewick & Wayne (2011). Algorithms (4th ed.). Addison-Wesley."
    )
  )
}

graphs_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    parse_graph <- function(edge_str) {
      pairs <- trimws(strsplit(edge_str, ",")[[1]])
      g <- list()
      for (p in pairs) {
        parts <- strsplit(p, "-")[[1]]
        if (length(parts) != 2) next
        u <- suppressWarnings(as.integer(trimws(parts[1])))
        v <- suppressWarnings(as.integer(trimws(parts[2])))
        if (is.na(u) || is.na(v)) next
        u1 <- as.character(u); v1 <- as.character(v)
        if (is.null(g[[u1]])) g[[u1]] <- integer(0)
        if (is.null(g[[v1]])) g[[v1]] <- integer(0)
        g[[u1]] <- c(g[[u1]], v)
        g[[v1]] <- c(g[[v1]], u)
      }
      g
    }

    run_result <- eventReactive(input$btn_run, {
      g     <- parse_graph(input$edges_input)
      start <- as.character(input$start_node)
      req(!is.null(g[[start]]) || length(g) > 0)

      visited <- character(0)
      order   <- integer(0)

      if (input$algo == "BFS") {
        queue <- list(input$start_node)
        visited <- c(visited, start)
        while (length(queue) > 0) {
          node <- queue[[1]]; queue <- queue[-1]
          order <- c(order, node)
          key  <- as.character(node)
          for (nei in sort(if (!is.null(g[[key]])) g[[key]] else integer(0))) {
            nk <- as.character(nei)
            if (!nk %in% visited) { visited <- c(visited, nk); queue <- c(queue, list(nei)) }
          }
        }
      } else {
        stack <- list(input$start_node)
        while (length(stack) > 0) {
          node <- stack[[length(stack)]]; stack <- stack[-length(stack)]
          nk <- as.character(node)
          if (nk %in% visited) next
          visited <- c(visited, nk)
          order   <- c(order, node)
          for (nei in sort(if (!is.null(g[[nk]])) g[[nk]] else integer(0), decreasing = TRUE)) {
            if (!as.character(nei) %in% visited) stack <- c(stack, list(nei))
          }
        }
      }
      list(order = order, algo = input$algo, start = input$start_node)
    }, ignoreNULL = FALSE)

    output$viz_graph <- renderUI({
      res <- run_result(); req(!is.null(res) && length(res$order) > 0)
      nodes <- lapply(seq_along(res$order), function(i)
        tagList(
          tags$div(class = "vnode visited",
                   style = paste0("animation-delay:", i*0.07, "s"), res$order[i]),
          if (i < length(res$order)) tags$span(class = "varrow", "→")
        )
      )
      tags$div(class = "viz-canvas", style = "flex-wrap:wrap;", nodes)
    })

    output$graph_explain <- renderUI({
      res <- run_result()
      if (is.null(res)) return(tags$div(class="viz-explain","Press Run to execute the traversal."))
      tags$div(class = "viz-explain",
        paste0(res$algo, " from node ", res$start, ": [",
               paste(res$order, collapse = ", "), "]"))
    })

    # ── Quiz ─────────────────────────────────────────────────────────────────
    q_ans <- reactiveVal(NULL)
    output$quiz_ui <- renderUI({
      ans <- q_ans()
      tagList(
        tags$p(class = "quiz-q", "Which algorithm guarantees the shortest path (min edges) in an unweighted graph?"),
        tags$button(class = paste("qopt", if(!is.null(ans)&&ans=="a")"wrong" else ""),
          "DFS", onclick = sprintf("Shiny.setInputValue('%s','a',{priority:'event'})", ns("qa"))),
        tags$button(class = paste("qopt", if(!is.null(ans)&&ans=="b")"right" else ""),
          "BFS", onclick = sprintf("Shiny.setInputValue('%s','b',{priority:'event'})", ns("qa"))),
        tags$button(class = paste("qopt", if(!is.null(ans)&&ans=="c")"wrong" else ""),
          "Dijkstra", onclick = sprintf("Shiny.setInputValue('%s','c',{priority:'event'})", ns("qa"))),
        if (!is.null(ans)) {
          if (ans == "b") tags$div(class="qfeedback right","✅ Correct! BFS explores level by level, so the first time it reaches a node is via the fewest edges.")
          else tags$div(class="qfeedback wrong","❌ BFS guarantees shortest path (fewest edges). DFS may find a longer path first; Dijkstra handles weighted graphs.")
        }
      )
    })
    observeEvent(input$qa, q_ans(input$qa))
  })
}
