# modules/mod_graphs.R — Graphs: BFS, DFS, Dijkstra, Topological sort

# Parse "A-B, B-C:4, C>D" into an edge table. sep "-" undirected, ">" directed.
parse_edges <- function(txt, max_edges = 30) {
  tok <- trimws(strsplit(txt %||% "", ",")[[1]])
  tok <- tok[nzchar(tok)]
  rows <- lapply(tok, function(t) {
    m <- regmatches(t, regexec("^\\s*([A-Za-z0-9]+)\\s*([->])\\s*([A-Za-z0-9]+)\\s*(?::\\s*([0-9.]+))?\\s*$", t, perl = TRUE))[[1]]
    if (length(m) == 0) return(NULL)
    data.frame(from = m[2], to = m[4], w = if (nzchar(m[5])) as.numeric(m[5]) else 1, stringsAsFactors = FALSE)
  })
  e <- do.call(rbind, rows)
  if (is.null(e)) return(NULL)
  e <- e[e$from != e$to, , drop = FALSE]
  head(e, max_edges)
}

graph_nodes <- function(e) {
  v <- unique(c(e$from, e$to))
  num <- suppressWarnings(as.numeric(v))
  if (!anyNA(num)) v[order(num)] else sort(v)
}

circle_layout <- function(v) {
  n <- length(v); ang <- pi / 2 - 2 * pi * (seq_len(n) - 1) / n
  data.frame(label = v, x = cos(ang), y = sin(ang), stringsAsFactors = FALSE)
}

edge_coords <- function(e, nodes) {
  a <- match(e$from, nodes$label); b <- match(e$to, nodes$label)
  data.frame(x0 = nodes$x[a], y0 = nodes$y[a], x1 = nodes$x[b], y1 = nodes$y[b], stringsAsFactors = FALSE)
}

graphs_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🕸️", "Graphs",
      "Nodes and edges model anything connected: maps, dependencies, networks, state spaces. Four algorithms cover most interviews — BFS, DFS, Dijkstra and topological sort.",
      c("BFS", "DFS", "Dijkstra", "Topological Sort", "Grid Search", "Cycle Detection")),

    topic_tabs(ns,
      visual = tagList(
        fluidRow(
          box(title = "BFS vs DFS — same graph, different order", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(6, textInput(ns("edges"), "Undirected edges (u-v):", "0-1,0-2,1-3,1-4,2-5,2-6,4-7,5-7")),
              column(3, textInput(ns("start"), "Start node:", "0")),
              column(3, radioButtons(ns("algo"), "Algorithm:", c("BFS", "DFS"), inline = TRUE))
            ),
            stepper_ui(ns, "tr"),
            plotlyOutput(ns("tr_plot"), height = "330px"),
            uiOutput(ns("tr_viz")),
            legend_row(c("processing" = COL$pri, "finished" = COL$soft, "discovered, waiting" = "#fef3c7", "undiscovered" = "#ffffff", "tree edge" = COL$pri))
          ),
          box(title = "What to notice", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("tr_note")),
            uiOutput(ns("tr_code"))
          )
        ),
        fluidRow(
          box(title = "Dijkstra — cheapest path with weighted edges", status = "primary", solidHeader = TRUE, width = 7,
            fluidRow(
              column(8, textInput(ns("dj_edges"), "Weighted edges (u-v:w):", "A-B:4,A-C:2,B-C:1,B-D:5,C-D:8,C-E:10,D-E:2,D-F:6,E-F:3")),
              column(4, textInput(ns("dj_start"), "Source:", "A"))
            ),
            stepper_ui(ns, "dj"),
            plotlyOutput(ns("dj_plot"), height = "330px"),
            uiOutput(ns("dj_viz")),
            legend_row(c("just settled" = COL$pri, "settled (final)" = COL$ok, "tentative distance" = "#fef3c7", "unreached (∞)" = "#ffffff"))
          ),
          box(title = "Topological Sort — Kahn's algorithm", status = "primary", solidHeader = TRUE, width = 5,
            textInput(ns("tp_edges"), "Directed edges (before>after):", "Math>Algo,Prog>Algo,Prog>DB,Algo>ML,DB>ML,ML>AI"),
            stepper_ui(ns, "tp"),
            plotlyOutput(ns("tp_plot"), height = "290px"),
            uiOutput(ns("tp_viz")),
            hint("The number under each node is its remaining in-degree (unmet prerequisites). Add <code>AI>Math</code> to create a cycle and watch it get stuck.")
          )
        ),
        fluidRow(
          box(title = "Grid BFS — the wavefront that guarantees the shortest path", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(3, sliderInput(ns("gr_walls"), "Wall density:", min = 0, max = 0.4, value = 0.22, step = 0.02)),
              column(2, tags$div(style = "margin-top:25px;", actionButton(ns("gr_new"), "🎲 New maze", class = "btn btn-dsa btn-sm"))),
              column(7, stepper_ui(ns, "gr"))
            ),
            uiOutput(ns("gr_viz"))
          )
        )
      ),

      learn = tagList(
        insight_cards(
          when = c("<b>Fewest edges</b> / minimum moves in an unweighted graph or grid → BFS.",
                   "Explore everything, count components, detect cycles, enumerate paths → DFS.",
                   "Non-negative <b>weights</b> → Dijkstra. Negative weights → Bellman-Ford.",
                   "'A must come before B' / prerequisites / build order → topological sort."),
          pitfalls = c("Marking a node visited when it is <b>popped</b> instead of when it is <b>pushed</b> → duplicates in the queue and blown-up runtime.",
                       "Running Dijkstra with negative edges — a settled node may later be improved, so the result is wrong.",
                       "Forgetting disconnected components: loop over every node as a possible start.",
                       "Recursion depth: DFS on a 10⁵-node path overflows Python's default stack; go iterative."),
          tips = c("Say what the nodes and edges are first. Many problems are graphs in disguise (words, board states, courses).",
                   "Grids are graphs: neighbours are the 4 (or 8) adjacent cells — no adjacency list needed.",
                   "Complexity is O(V + E) for BFS / DFS / topo, O((V + E) log V) for heap Dijkstra — state both V and E.")
        ),
        fluidRow(
          box(title = "Choose the algorithm", status = "info", solidHeader = TRUE, width = 7,
            cplx_table(data.frame(
              Goal = c("Shortest path, unweighted", "Shortest path, weights ≥ 0", "Shortest path, negative weights", "All-pairs shortest paths",
                       "Ordering with dependencies", "Connected components", "Cycle in directed graph", "Minimum spanning tree"),
              Algorithm = c("BFS", "Dijkstra (min-heap)", "Bellman-Ford", "Floyd-Warshall", "Topological sort (Kahn / DFS)", "DFS / BFS / Union-Find", "DFS 3-colour or Kahn", "Kruskal (Union-Find) / Prim (heap)"),
              Time = c("O(V + E)", "O((V + E) log V)", "O(V · E)", "O(V³)", "O(V + E)", "O(V + E)", "O(V + E)", "O(E log E)"),
              stringsAsFactors = FALSE))
          ),
          box(title = "Representing a graph", status = "info", solidHeader = TRUE, width = 5,
            cplx_table(data.frame(
              Question = c("Space", "Is (u, v) an edge?", "Iterate neighbours of u", "Best for"),
              Adjacency.list = c("O(V + E)", "O(deg u)", "O(deg u)", "Sparse graphs (most problems)"),
              Adjacency.matrix = c("O(V²)", "O(1)", "O(V)", "Dense graphs, Floyd-Warshall"),
              stringsAsFactors = FALSE)),
            callout("In Python: <code>graph = defaultdict(list)</code>, then <code>graph[u].append(v)</code> (and the reverse for undirected).", "tip")
          )
        ),
        fluidRow(
          box(title = "Templates worth memorising (Python)", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(4,
                dsa_code(
'def bfs(graph, start):
    dist = {start: 0}            # doubles as visited
    q = deque([start])
    while q:
        u = q.popleft()
        for v in graph[u]:
            if v not in dist:    # mark on push
                dist[v] = dist[u] + 1
                q.append(v)
    return dist', "BFS shortest distances"),
                dsa_code(
'def numIslands(grid):
    R, C = len(grid), len(grid[0])
    def sink(r, c):
        if not (0 <= r < R and 0 <= c < C): return
        if grid[r][c] != "1": return
        grid[r][c] = "0"          # visited
        for dr, dc in ((1,0),(-1,0),(0,1),(0,-1)):
            sink(r + dr, c + dc)
    count = 0
    for r in range(R):
        for c in range(C):
            if grid[r][c] == "1":
                count += 1; sink(r, c)
    return count', "Grid DFS — count components")
              ),
              column(4,
                dsa_code(
'def dijkstra(graph, src):
    dist = {src: 0}
    heap = [(0, src)]
    while heap:
        d, u = heapq.heappop(heap)
        if d > dist.get(u, inf):
            continue             # stale entry
        for v, w in graph[u]:
            nd = d + w
            if nd < dist.get(v, inf):
                dist[v] = nd
                heapq.heappush(heap, (nd, v))
    return dist', "Dijkstra with lazy deletion"),
                dsa_code(
'def hasCycle(graph, n):      # directed
    color = [0] * n          # 0 new, 1 on stack, 2 done
    def dfs(u):
        color[u] = 1
        for v in graph[u]:
            if color[v] == 1: return True   # back edge
            if color[v] == 0 and dfs(v): return True
        color[u] = 2
        return False
    return any(color[u] == 0 and dfs(u) for u in range(n))', "Directed cycle — 3 colours")
              ),
              column(4,
                dsa_code(
'def topoSort(n, edges):
    graph = [[] for _ in range(n)]
    indeg = [0] * n
    for u, v in edges:
        graph[u].append(v)
        indeg[v] += 1
    q = deque(i for i in range(n) if indeg[i] == 0)
    order = []
    while q:
        u = q.popleft()
        order.append(u)
        for v in graph[u]:
            indeg[v] -= 1
            if indeg[v] == 0:
                q.append(v)
    return order if len(order) == n else []   # [] = cycle', "Topological sort — Kahn"),
                callout("<b>Multi-source BFS:</b> put <i>all</i> sources in the queue at distance 0 (Rotting Oranges, 01-Matrix). One pass gives the distance to the nearest source.", "info")
              )
            )
          )
        )
      ),

      practice = practice_tab(ns, "graphs",
        "Cormen, Leiserson, Rivest & Stein (2022). Introduction to Algorithms (4th ed.) — ch. 20–23.",
        "Dijkstra, E. W. (1959). A note on two problems in connexion with graphs. Numerische Mathematik 1.",
        "Kahn, A. B. (1962). Topological sorting of large networks. CACM 5(11).")
    )
  )
}

graphs_server <- function(id, progress = NULL) {
  moduleServer(id, function(input, output, session) {

    # ── BFS / DFS ────────────────────────────────────────────────────────────
    tr_graph <- reactive({
      e <- parse_edges(input$edges)
      validate(need(!is.null(e) && nrow(e) >= 1, "Enter edges like 0-1,1-2."))
      v <- graph_nodes(e)
      validate(need(length(v) <= 14, "Use at most 14 nodes so the drawing stays readable."))
      adj <- lapply(setNames(v, v), function(u) { nb <- unique(c(e$to[e$from == u], e$from[e$to == u])); v[v %in% nb] })
      list(e = e, v = v, adj = adj, nodes = circle_layout(v))
    })
    tr_steps <- reactive({
      g <- tr_graph(); s <- trimws(input$start %||% "")
      validate(need(s %in% g$v, sprintf("Start node must be one of: %s", paste(g$v, collapse = ", "))))
      parent <- setNames(rep(NA_character_, length(g$v)), g$v)
      steps <- list(); done <- character(0)
      if (input$algo == "BFS") {
        dist <- setNames(rep(NA_real_, length(g$v)), g$v); dist[s] <- 0
        q <- s
        steps[[1]] <- list(cur = NA, done = done, aux = q, parent = parent, dist = dist,
          msg = sprintf("Enqueue the start node <b>%s</b> at distance 0.", s))
        while (length(q) > 0) {
          u <- q[1]; q <- q[-1]; new <- character(0)
          for (w in g$adj[[u]]) if (is.na(dist[w])) { dist[w] <- dist[u] + 1; parent[w] <- u; q <- c(q, w); new <- c(new, w) }
          steps[[length(steps) + 1]] <- list(cur = u, done = done, aux = q, parent = parent, dist = dist,
            msg = sprintf("Dequeue <b>%s</b> (distance %d). %s", u, dist[u],
                          if (length(new)) sprintf("Newly discovered: %s → marked and enqueued at distance %d.", paste(new, collapse = ", "), dist[u] + 1)
                          else "All its neighbours were already discovered."))
          done <- c(done, u)
        }
        left <- sum(is.na(dist))
        steps[[length(steps) + 1]] <- list(cur = NA, done = done, aux = character(0), parent = parent, dist = dist,
          msg = sprintf("<b>Queue empty — BFS complete.</b> The number under each node is its shortest distance (in edges) from %s.%s", s,
                        if (left) sprintf(" %d node(s) are unreachable.", left) else ""))
      } else {
        seen <- character(0); dist <- setNames(rep(NA_real_, length(g$v)), g$v)
        steps[[1]] <- list(cur = NA, done = done, aux = character(0), parent = parent, dist = dist,
          msg = sprintf("Call <code>dfs(%s)</code>. DFS dives as deep as it can before backing up.", s))
        dfs <- function(u, path) {
          seen <<- c(seen, u); path <- c(path, u)
          steps[[length(steps) + 1]] <<- list(cur = u, done = done, aux = path, parent = parent, dist = dist, order = seen,
            msg = sprintf("Enter <b>%s</b> (recursion depth %d). Try its neighbours in order: %s.", u, length(path), paste(g$adj[[u]], collapse = ", ")))
          for (w in g$adj[[u]]) if (!(w %in% seen)) { parent[w] <<- u; dfs(w, path) }
          done <<- c(done, u)
        }
        dfs(s, character(0))
        steps[[length(steps) + 1]] <- list(cur = NA, done = done, aux = character(0), parent = parent, dist = dist, order = seen,
          msg = sprintf("<b>DFS complete.</b> Discovery order: %s. Compare with BFS — same nodes, very different order.", paste(seen, collapse = " → ")))
      }
      steps
    })
    tr <- stepper_server(input, output, session, "tr", tr_steps)

    output$tr_plot <- renderPlotly({
      g <- tr_graph(); s <- tr$cur(); nodes <- g$nodes
      state <- rep("idle", nrow(nodes))
      state[nodes$label %in% s$aux]  <- "frontier"
      state[nodes$label %in% s$done] <- "visited"
      if (!is.na(s$cur)) state[nodes$label == s$cur] <- "active"
      nodes <- state_style(nodes, state)
      if (input$algo == "BFS") nodes$sub <- ifelse(is.na(s$dist[nodes$label]), "", paste0("d=", s$dist[nodes$label]))
      ec <- edge_coords(g$e, nodes)
      tree <- (!is.na(s$parent[g$e$to]) & s$parent[g$e$to] == g$e$from) | (!is.na(s$parent[g$e$from]) & s$parent[g$e$from] == g$e$to)
      ec$color <- ifelse(tree, COL$pri, COL$idle); ec$width <- ifelse(tree, 4, 2)
      net_plot(nodes, ec, size = 38, height = 330)
    })
    output$tr_viz <- renderUI({
      s <- tr$cur(); bfs <- input$algo == "BFS"
      out <- if (bfs) c(s$done, if (!is.na(s$cur)) s$cur) else (s$order %||% character(0))
      tagList(
        lane(if (bfs) "queue (front →)" else "call stack", s$aux, "frontier", "empty"),
        lane("visit order", out, "visited", "—"),
        explain(s$msg))
    })
    output$tr_note <- renderUI({
      if (input$algo == "BFS") callout("<b>BFS expands in rings.</b> Everything at distance 1 is processed before anything at distance 2. That is why the first time BFS reaches a node, it has found a shortest path to it — and why the purple tree edges form a shortest-path tree.", "info")
      else callout("<b>DFS commits to a path.</b> It follows one neighbour all the way down, and only backtracks when stuck. The call stack is exactly the path from the start to the current node. Great for exploring everything; useless for shortest paths.", "info")
    })
    output$tr_code <- renderUI({
      if (input$algo == "BFS")
        pseudo(c("seen = {start}; q = deque([start])", "while q:", "    u = q.popleft()", "    for v in graph[u]:", "        if v not in seen:", "            seen.add(v)", "            q.append(v)"),
               active = if (is.na(tr$cur()$cur)) 1 else 3:7)
      else
        pseudo(c("def dfs(u):", "    seen.add(u)", "    for v in graph[u]:", "        if v not in seen:", "            dfs(v)"),
               active = if (is.na(tr$cur()$cur)) 1 else 2:5)
    })

    # ── Dijkstra ─────────────────────────────────────────────────────────────
    dj_graph <- reactive({
      e <- parse_edges(input$dj_edges)
      validate(need(!is.null(e) && nrow(e) >= 1, "Enter edges like A-B:4,B-C:2."))
      v <- graph_nodes(e)
      validate(need(length(v) <= 12, "Use at most 12 nodes."))
      list(e = e, v = v, nodes = circle_layout(v))
    })
    dj_steps <- reactive({
      g <- dj_graph(); s <- trimws(input$dj_start %||% "")
      validate(need(s %in% g$v, sprintf("Source must be one of: %s", paste(g$v, collapse = ", "))))
      dist <- setNames(rep(Inf, length(g$v)), g$v); dist[s] <- 0
      parent <- setNames(rep(NA_character_, length(g$v)), g$v)
      settled <- character(0)
      steps <- list(list(cur = NA, settled = settled, dist = dist, parent = parent,
        msg = sprintf("Every distance starts at ∞ except the source <b>%s</b> = 0. Repeatedly settle the closest unsettled node.", s)))
      repeat {
        cand <- setdiff(g$v[is.finite(dist)], settled)
        if (length(cand) == 0) break
        u <- cand[which.min(dist[cand])]
        upd <- character(0)
        for (i in seq_len(nrow(g$e))) {
          w <- if (g$e$from[i] == u) g$e$to[i] else if (g$e$to[i] == u) g$e$from[i] else next
          if (w %in% settled) next
          nd <- dist[u] + g$e$w[i]
          if (nd < dist[w]) {
            upd <- c(upd, sprintf("%s: %s → <b>%s</b>", w, if (is.finite(dist[w])) dist[w] else "∞", nd))
            dist[w] <- nd; parent[w] <- u
          }
        }
        settled <- c(settled, u)
        steps[[length(steps) + 1]] <- list(cur = u, settled = settled, dist = dist, parent = parent,
          msg = sprintf("Pop <b>%s</b> from the heap — smallest tentative distance (%s), so it is now <b>final</b>. %s", u, dist[u],
                        if (length(upd)) paste0("Relax its edges: ", paste(upd, collapse = "; "), ".") else "No neighbour improves."))
      }
      steps[[length(steps) + 1]] <- list(cur = NA, settled = settled, dist = dist, parent = parent,
        msg = "<b>Done.</b> Green edges form the shortest-path tree: follow them back from any node to recover its cheapest route.")
      steps
    })
    dj <- stepper_server(input, output, session, "dj", dj_steps)
    output$dj_plot <- renderPlotly({
      g <- dj_graph(); s <- dj$cur(); nodes <- g$nodes
      state <- rep("idle", nrow(nodes))
      state[is.finite(s$dist[nodes$label])] <- "frontier"
      state[nodes$label %in% s$settled] <- "done"
      if (!is.na(s$cur)) state[nodes$label == s$cur] <- "active"
      nodes <- state_style(nodes, state)
      nodes$sub <- ifelse(is.finite(s$dist[nodes$label]), as.character(s$dist[nodes$label]), "∞")
      ec <- edge_coords(g$e, nodes); ec$label <- g$e$w
      tree <- (!is.na(s$parent[g$e$to]) & s$parent[g$e$to] == g$e$from) | (!is.na(s$parent[g$e$from]) & s$parent[g$e$from] == g$e$to)
      ec$color <- ifelse(tree, COL$ok, COL$idle); ec$width <- ifelse(tree, 4, 2)
      net_plot(nodes, ec, size = 38, height = 330)
    })
    output$dj_viz <- renderUI({
      g <- dj_graph(); s <- dj$cur()
      pend <- setdiff(g$v[is.finite(s$dist)], s$settled)
      pend <- pend[order(s$dist[pend])]
      tagList(
        lane("heap (min first)", if (length(pend)) paste0(pend, ":", s$dist[pend]) else character(0), "frontier", "empty"),
        lane("settled", s$settled, "found", "none yet"),
        explain(s$msg))
    })

    # ── Topological sort ─────────────────────────────────────────────────────
    tp_graph <- reactive({
      e <- parse_edges(input$tp_edges)
      validate(need(!is.null(e) && nrow(e) >= 1, "Enter directed edges like A>B,B>C."))
      v <- unique(c(e$from, e$to))
      validate(need(length(v) <= 12, "Use at most 12 nodes."))
      list(e = e, v = v, nodes = circle_layout(v))
    })
    tp_steps <- reactive({
      g <- tp_graph()
      indeg <- setNames(vapply(g$v, function(u) sum(g$e$to == u), numeric(1)), g$v)
      q <- g$v[indeg == 0]; order <- character(0)
      steps <- list(list(cur = NA, indeg = indeg, q = q, order = order, stuck = FALSE,
        msg = sprintf("Count incoming edges. Nodes with in-degree 0 have no prerequisites and can go first: %s.",
                      if (length(q)) paste(q, collapse = ", ") else "none")))
      while (length(q) > 0) {
        u <- q[1]; q <- q[-1]; order <- c(order, u); freed <- character(0)
        for (w in g$e$to[g$e$from == u]) { indeg[w] <- indeg[w] - 1; if (indeg[w] == 0) { q <- c(q, w); freed <- c(freed, w) } }
        steps[[length(steps) + 1]] <- list(cur = u, indeg = indeg, q = q, order = order, stuck = FALSE,
          msg = sprintf("Output <b>%s</b> and delete its outgoing edges. %s", u,
                        if (length(freed)) sprintf("%s now has in-degree 0 → enqueue.", paste(freed, collapse = ", ")) else "No new node is freed."))
      }
      stuck <- length(order) < length(g$v)
      steps[[length(steps) + 1]] <- list(cur = NA, indeg = indeg, q = q, order = order, stuck = stuck,
        msg = if (stuck) sprintf("<b>Queue is empty but %d node(s) remain, each waiting on another → the graph has a cycle.</b> No valid ordering exists.", length(g$v) - length(order))
              else sprintf("<b>Valid order:</b> %s. Every edge points forward in this sequence.", paste(order, collapse = " → ")))
      steps
    })
    tp <- stepper_server(input, output, session, "tp", tp_steps)
    output$tp_plot <- renderPlotly({
      g <- tp_graph(); s <- tp$cur(); nodes <- g$nodes
      state <- rep("idle", nrow(nodes))
      state[nodes$label %in% s$q] <- "frontier"
      state[nodes$label %in% s$order] <- "visited"
      if (!is.na(s$cur)) state[nodes$label == s$cur] <- "active"
      if (s$stuck) state[!(nodes$label %in% s$order)] <- "bad"
      nodes <- state_style(nodes, state)
      nodes$sub <- ifelse(nodes$label %in% s$order, "", paste0("in=", s$indeg[nodes$label]))
      ec <- edge_coords(g$e, nodes)
      gone <- g$e$from %in% s$order
      ec$color <- ifelse(gone, "#e2e8f0", COL$mute); ec$width <- 2
      net_plot(nodes, ec, directed = TRUE, size = 42, height = 290)
    })
    output$tp_viz <- renderUI({
      s <- tp$cur()
      tagList(lane("ready queue", s$q, "frontier", "empty"), lane("order", s$order, "visited", "—"), explain(s$msg))
    })

    # ── Grid BFS ─────────────────────────────────────────────────────────────
    gr_grid <- reactive({
      input$gr_new
      R <- 9; C <- 18
      for (attempt in 1:40) {
        wall <- matrix(runif(R * C) < (input$gr_walls %||% 0.2), R, C)
        wall[1, 1] <- FALSE; wall[R, C] <- FALSE
        dist <- matrix(NA_integer_, R, C); dist[1, 1] <- 0L
        pr <- matrix(NA_integer_, R, C); q <- 1L; head <- 1
        while (head <= length(q)) {
          cell <- q[head]; head <- head + 1
          r <- (cell - 1) %% R + 1; cc <- (cell - 1) %/% R + 1
          for (d in list(c(1, 0), c(-1, 0), c(0, 1), c(0, -1))) {
            nr <- r + d[1]; nc <- cc + d[2]
            if (nr < 1 || nr > R || nc < 1 || nc > C || wall[nr, nc] || !is.na(dist[nr, nc])) next
            dist[nr, nc] <- dist[r, cc] + 1L; pr[nr, nc] <- cell; q <- c(q, (nc - 1L) * R + nr)
          }
        }
        if (!is.na(dist[R, C])) break
      }
      path <- integer(0)
      if (!is.na(dist[R, C])) { cell <- (C - 1L) * R + R; while (!is.na(cell)) { path <- c(path, cell); cell <- pr[cell] } }
      list(R = R, C = C, wall = wall, dist = dist, path = path)
    })
    gr_steps <- reactive({
      g <- gr_grid(); maxd <- max(g$dist, na.rm = TRUE)
      steps <- lapply(0:maxd, function(d) list(d = d, final = FALSE,
        msg = sprintf("Wave <b>%d</b>: %d cell(s) are exactly %d step(s) from the start. Each wave is built only from the previous one.", d, sum(g$dist == d, na.rm = TRUE), d)))
      reach <- !is.na(g$dist[g$R, g$C])
      steps[[length(steps) + 1]] <- list(d = maxd, final = TRUE,
        msg = if (reach) sprintf("<b>Target reached in %d moves.</b> Follow parent pointers back from the target to recover the green path. Any other route is at least as long, because BFS explored every shorter distance first.", g$dist[g$R, g$C])
              else "<b>The target is walled off</b> — BFS exhausted every reachable cell without finding it.")
      steps
    })
    gr <- stepper_server(input, output, session, "gr", gr_steps, speed = 350)
    output$gr_viz <- renderUI({
      g <- gr_grid(); s <- gr$cur(); maxd <- max(1, max(g$dist, na.rm = TRUE))
      rows <- lapply(seq_len(g$R), function(r) tags$div(class = "board-row", lapply(seq_len(g$C), function(cc) {
        cell <- (cc - 1L) * g$R + r; d <- g$dist[r, cc]
        style <- "background:#f1f5f9; color:#cbd5e1;"; txt <- ""
        if (g$wall[r, cc]) style <- "background:#1e293b;"
        else if (!is.na(d) && d <= s$d) {
          if (s$final && cell %in% g$path) style <- "background:#10b981; color:#fff;"
          else if (d == s$d && !s$final) style <- "background:#f59e0b; color:#fff;"
          else style <- sprintf("background:rgba(79,70,229,%.2f); color:#fff;", 0.25 + 0.6 * d / maxd)
          txt <- d
        }
        if (r == 1 && cc == 1) txt <- "S"
        if (r == g$R && cc == g$C) txt <- "T"
        tags$div(class = "sq", style = paste0(style, "font-size:11px; font-weight:700; font-family:'JetBrains Mono',monospace; margin:1px; border-radius:4px;"), txt)
      })))
      tagList(
        tags$div(style = "text-align:center; overflow-x:auto;", tags$div(class = "board", rows)),
        legend_row(c("current wave" = COL$warn, "explored (darker = farther)" = COL$pri, "shortest path" = COL$ok, "wall" = "#1e293b")),
        explain(s$msg))
    })

    quiz_server(input, output, session, topic = "graphs", progress = progress, questions = list(
      list(q = "Fewest moves for a knight to reach a square on a chessboard. Which algorithm?",
           opts = c("DFS", "BFS", "Dijkstra", "Topological sort"), ans = 2,
           why = "Every move costs the same, so it is an unweighted shortest-path problem on board states — BFS."),
      list(q = "In BFS, when should a node be marked as visited?",
           opts = c("When it is dequeued", "When it is enqueued", "After all neighbours are processed", "It does not matter"), ans = 2,
           why = "Marking on enqueue stops the same node from being added many times by different neighbours."),
      list(q = "Why can Dijkstra fail with a negative edge?",
           opts = c("Heaps cannot store negative keys", "A node already settled as final could later be reached more cheaply", "It would loop forever", "It only works on trees"), ans = 2,
           why = "Dijkstra's greedy step assumes extending a path never makes it cheaper. A negative edge breaks that assumption."),
      list(q = "Kahn's algorithm finishes with fewer nodes in the output than in the graph. That means…",
           opts = c("The graph is disconnected", "The graph contains a cycle", "Some nodes had no edges", "The queue overflowed"), ans = 2,
           why = "Nodes on a cycle never reach in-degree 0, so they are never emitted."),
      list(q = "BFS and DFS on an adjacency list both run in…",
           opts = c("O(V²)", "O(V + E)", "O(E log V)", "O(V · E)"), ans = 2,
           why = "Each vertex is processed once and each edge is examined a constant number of times.")
    ))
  })
}
