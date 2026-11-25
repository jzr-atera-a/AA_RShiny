# modules/mod_advanced.R — Tries & Union-Find (+ Kruskal's MST)

advanced_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🧬", "Tries & Union-Find",
      "Two specialised structures that turn hard-looking problems into a few lines: a trie answers prefix questions in time proportional to the word, and union-find tracks connected groups in near-constant time.",
      c("Prefix Tree", "Autocomplete", "Disjoint Sets", "Path Compression", "Union by Rank", "Kruskal's MST")),

    topic_tabs(ns,
      visual = tagList(
        fluidRow(
          box(title = "Trie — words that share a prefix share a path", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(7, textInput(ns("words"), "Insert these words in order:", "car,card,care,cat,dog,dot,do")),
              column(5, stepper_ui(ns, "tri"))
            ),
            plotlyOutput(ns("tri_plot"), height = "340px"),
            uiOutput(ns("tri_explain")),
            legend_row(c("new node for this word" = COL$pri, "reused prefix" = "#fef3c7", "end of a word" = COL$ok, "existing node" = COL$soft))
          ),
          box(title = "Prefix search and autocomplete", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("tri_kpi")),
            textInput(ns("prefix"), "Type a prefix:", "ca"),
            uiOutput(ns("prefix_out")),
            callout("Lookup cost depends on the <b>length of the query</b>, not on how many words are stored. A hash set can tell you if <i>car</i> exists, but not which words <i>start with</i> car.", "tip")
          )
        ),
        fluidRow(
          box(title = "Union-Find — merging groups", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(3, sliderInput(ns("uf_n"), "Elements:", min = 5, max = 10, value = 8, step = 1)),
              column(5, textInput(ns("uf_ops"), "Unions (a-b):", "0-1,1-2,2-3,3-4,5-6,6-7,4-7,0-7")),
              column(4, checkboxGroupInput(ns("uf_opt"), "Optimisations:", c("Union by rank" = "rank", "Path compression" = "pc"), selected = character(0)))
            ),
            stepper_ui(ns, "uf"),
            plotlyOutput(ns("uf_plot"), height = "300px"),
            uiOutput(ns("uf_explain")),
            legend_row(c("elements being united" = COL$pri, "root (set representative)" = COL$ok, "member" = COL$soft))
          ),
          box(title = "Flat trees are fast trees", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("uf_kpi")),
            callout("Arrows point from a child to its parent; follow them to reach the <b>root</b>, which names the set. Two elements are connected exactly when they have the same root.", "info"),
            callout("Run the default unions with both boxes unticked: the tree becomes a tall chain and <code>find</code> is O(n). Tick <b>union by rank</b> and the height stays logarithmic. Add <b>path compression</b> and every node visited is re-pointed straight at the root.", "tip")
          )
        ),
        fluidRow(
          box(title = "Kruskal's Minimum Spanning Tree — union-find at work", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(6, textInput(ns("ks_edges"), "Weighted edges (u-v:w):", "A-B:7,A-D:5,B-C:8,B-D:9,B-E:7,C-E:5,D-E:15,D-F:6,E-F:8,E-G:9,F-G:11")),
              column(6, stepper_ui(ns, "ks"))
            ),
            fluidRow(
              column(7, plotlyOutput(ns("ks_plot"), height = "340px")),
              column(5, uiOutput(ns("ks_kpi")), uiOutput(ns("ks_list")), uiOutput(ns("ks_explain")))
            )
          )
        )
      ),

      learn = tagList(
        insight_cards(
          when = c("Prefix queries, autocomplete, spell-check, 'does any word start with…' → trie.",
                   "Searching a board for many words at once (Word Search II) → trie + backtracking.",
                   "'Are these two connected?', counting groups, or merging accounts as edges arrive → union-find.",
                   "Detecting the edge that closes a cycle in an undirected graph; building an MST → union-find."),
          pitfalls = c("Trie: forgetting the end-of-word flag — <code>car</code> must not match just because <code>card</code> was inserted.",
                       "Trie memory: one node per character; a fixed 26-slot array per node wastes space on sparse data — use a dict.",
                       "Union-find: comparing <code>parent[a] == parent[b]</code> instead of <code>find(a) == find(b)</code>.",
                       "Union-find cannot <b>split</b> sets. If edges are removed, process the queries in reverse or use another structure."),
          tips = c("Union-find is ~15 lines; practise until you can write it from memory with both optimisations.",
                   "Quote the complexity as 'amortised O(α(n)), effectively constant' — α is the inverse Ackermann function, below 5 for any real input.",
                   "If the graph is static, DFS / BFS is simpler for components. Union-find shines when connections arrive incrementally.")
        ),
        fluidRow(
          box(title = "Trie costs (L = word length)", status = "info", solidHeader = TRUE, width = 4,
            cplx_table(data.frame(
              Operation = c("Insert", "Search word", "Starts with prefix", "List all with prefix", "Space"),
              Cost = c("O(L)", "O(L)", "O(L)", "O(L + matches)", "O(total characters)"),
              stringsAsFactors = FALSE))
          ),
          box(title = "Union-Find costs", status = "info", solidHeader = TRUE, width = 4,
            cplx_table(data.frame(
              Variant = c("Naive linking", "Union by rank only", "Path compression only", "Both"),
              find.and.union = c("O(n)", "O(log n)", "O(log n) amortised", "O(α(n)) ≈ O(1)"),
              stringsAsFactors = FALSE))
          ),
          box(title = "Other specialised structures", status = "info", solidHeader = TRUE, width = 4,
            cplx_table(data.frame(
              Structure = c("Fenwick tree (BIT)", "Segment tree", "Monotonic deque", "LRU cache"),
              Answers = c("Prefix sums with updates, O(log n)", "Range min / max / sum with updates, O(log n)", "Sliding-window extremes, O(1) amortised", "Recency-bounded cache, O(1)"),
              stringsAsFactors = FALSE))
          )
        ),
        fluidRow(
          box(title = "Templates worth memorising (Python)", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(4, dsa_code(
'class Trie:
    def __init__(self):
        self.children = {}
        self.end = False

    def insert(self, word):
        node = self
        for ch in word:
            node = node.children.setdefault(ch, Trie())
        node.end = True

    def _walk(self, s):
        node = self
        for ch in s:
            node = node.children.get(ch)
            if node is None: return None
        return node

    def search(self, word):
        node = self._walk(word)
        return node is not None and node.end

    def startsWith(self, prefix):
        return self._walk(prefix) is not None', "Trie")),
              column(4, dsa_code(
'class UnionFind:
    def __init__(self, n):
        self.parent = list(range(n))
        self.rank = [0] * n
        self.count = n               # number of sets

    def find(self, x):
        if self.parent[x] != x:
            self.parent[x] = self.find(self.parent[x])  # compress
        return self.parent[x]

    def union(self, a, b):
        ra, rb = self.find(a), self.find(b)
        if ra == rb:
            return False             # already joined
        if self.rank[ra] < self.rank[rb]:
            ra, rb = rb, ra
        self.parent[rb] = ra         # shorter under taller
        if self.rank[ra] == self.rank[rb]:
            self.rank[ra] += 1
        self.count -= 1
        return True', "Union-Find with both optimisations")),
              column(4,
                dsa_code(
'def kruskal(n, edges):           # edges: (w, u, v)
    uf, total, used = UnionFind(n), 0, []
    for w, u, v in sorted(edges):
        if uf.union(u, v):       # joins two components
            total += w
            used.append((u, v, w))
    return total, used', "Kruskal's MST — O(E log E)"),
                dsa_code(
'def findRedundantConnection(edges):
    uf = UnionFind(len(edges) + 1)
    for u, v in edges:
        if not uf.union(u, v):   # same set already
            return [u, v]        # this edge closes a cycle', "#684 Redundant connection"))
            )
          )
        )
      ),

      practice = practice_tab(ns, "advanced",
        "Fredkin, E. (1960). Trie memory. CACM 3(9).",
        "Tarjan, R. E. (1975). Efficiency of a good but not linear set union algorithm. JACM 22(2) — the α(n) bound.",
        "Kruskal, J. B. (1956). On the shortest spanning subtree of a graph. Proc. AMS 7(1).")
    )
  )
}

advanced_server <- function(id, progress = NULL) {
  moduleServer(id, function(input, output, session) {

    # ── Trie ─────────────────────────────────────────────────────────────────
    trie <- reactive({
      w <- tolower(trimws(strsplit(input$words %||% "", ",")[[1]])); w <- unique(w[grepl("^[a-z]+$", w)])
      validate(need(length(w) >= 1, "Enter words made of letters, separated by commas."))
      w <- head(substr(w, 1, 8), 10)
      ch <- "•"; parent <- NA_integer_; endw <- 0L; born <- 0L; kids <- list(integer(0))
      touched <- list()
      for (k in seq_along(w)) {
        node <- 1L; path <- 1L
        for (c1 in strsplit(w[k], "")[[1]]) {
          hit <- kids[[node]][ch[kids[[node]]] == c1]
          if (length(hit) == 0) {
            ch <- c(ch, c1); parent <- c(parent, node); endw <- c(endw, 0L); born <- c(born, k)
            kids[[length(ch)]] <- integer(0); kids[[node]] <- c(kids[[node]], length(ch)); hit <- length(ch)
          }
          node <- hit[1]; path <- c(path, node)
        }
        endw[node] <- if (endw[node] == 0L) k else endw[node]
        touched[[k]] <- path
      }
      N <- length(ch); x <- rep(NA_real_, N); y <- rep(0, N); leafx <- 0
      walk <- function(i, d) {
        y[i] <<- -d; kk <- kids[[i]][order(ch[kids[[i]]])]
        if (length(kk) == 0) { leafx <<- leafx + 1; x[i] <<- leafx }
        else { for (j in kk) walk(j, d + 1); x[i] <<- mean(x[kk]) }
      }
      walk(1L, 0)
      list(w = w, ch = ch, parent = parent, endw = endw, born = born, kids = kids, x = x, y = y, touched = touched, N = N)
    })
    tri_steps <- reactive({
      t <- trie()
      steps <- list(list(k = 0, msg = "An empty trie is just a root. Each edge down the tree spells one more character."))
      for (k in seq_along(t$w)) {
        new <- sum(t$born == k); L <- nchar(t$w[k])
        steps[[length(steps) + 1]] <- list(k = k, msg = sprintf("Insert <b>%s</b>: %s Mark the last node as end-of-word.", t$w[k],
          if (new == L) sprintf("no existing prefix to reuse, so create %d node(s).", new)
          else if (new == 0) "every character already exists — no new nodes at all."
          else sprintf("the first %d character(s) are already there (reuse), then create %d new node(s).", L - new, new)))
      }
      steps
    })
    tri <- stepper_server(input, output, session, "tri", tri_steps)
    trie_plot <- function(t, k, hl_new = integer(0), hl_path = integer(0), hl_found = integer(0)) {
      vis <- t$born <= k
      nd <- data.frame(x = t$x, y = t$y, label = ifelse(vis, t$ch, ""), stringsAsFactors = FALSE)
      state <- ifelse(vis, "visited", "idle")
      state[vis & t$endw > 0 & t$endw <= k] <- "done"
      state[hl_path] <- "frontier"; state[hl_new] <- "active"; state[hl_found] <- "path"
      nd <- state_style(nd, state); nd$border[!vis] <- "#eef2f7"
      ch <- sq(2, t$N)
      ed <- if (length(ch)) data.frame(x0 = t$x[t$parent[ch]], y0 = t$y[t$parent[ch]], x1 = t$x[ch], y1 = t$y[ch],
                                       color = ifelse(vis[ch], COL$mute, "#eef2f7"), width = 2, stringsAsFactors = FALSE) else NULL
      net_plot(nd, ed, size = 32, height = 340)
    }
    output$tri_plot <- renderPlotly({
      t <- trie(); s <- tri$cur(); k <- s$k
      if (k == 0) return(trie_plot(t, 0))
      path <- t$touched[[k]]
      trie_plot(t, k, hl_new = path[t$born[path] == k], hl_path = path[t$born[path] < k])
    })
    output$tri_explain <- renderUI(explain(tri$cur()$msg))
    output$tri_kpi <- renderUI({
      t <- trie(); chars <- sum(nchar(t$w))
      kpi_row(kpi(length(t$w), "words", COL$pri), kpi(chars, "characters", COL$warn), kpi(t$N - 1, "trie nodes", COL$ok))
    })
    output$prefix_out <- renderUI({
      t <- trie(); p <- tolower(gsub("[^A-Za-z]", "", input$prefix %||% ""))
      node <- 1L; ok <- TRUE
      for (c1 in strsplit(p, "")[[1]]) {
        hit <- t$kids[[node]][t$ch[t$kids[[node]]] == c1]
        if (length(hit) == 0) { ok <- FALSE; break }
        node <- hit[1]
      }
      if (!ok) return(callout(sprintf("No stored word starts with <b>%s</b> — the walk fell off the trie after %d step(s).", p, nchar(p)), "warn"))
      found <- character(0)
      collect <- function(i, acc) { if (t$endw[i] > 0) found <<- c(found, acc); for (j in t$kids[[i]][order(t$ch[t$kids[[i]]])]) collect(j, paste0(acc, t$ch[j])) }
      collect(node, p)
      tagList(lane("matches", found, "found", "none"),
              hint(sprintf("Walked %d node(s) for the prefix, then collected the subtree beneath: %d completion(s).%s", nchar(p), length(found),
                           if (nzchar(p) && t$endw[node] > 0) sprintf(" <b>%s</b> is itself a stored word.", p) else if (nzchar(p)) sprintf(" <b>%s</b> is a prefix only, not a stored word.", p) else "")))
    })

    # ── Union-Find ───────────────────────────────────────────────────────────
    uf_steps <- reactive({
      n <- input$uf_n; req(n)
      e <- parse_edges(input$uf_ops)
      validate(need(!is.null(e) && nrow(e) >= 1, "Enter unions like 0-1,2-3."))
      a <- suppressWarnings(as.integer(e$from)); b <- suppressWarnings(as.integer(e$to))
      validate(need(!anyNA(c(a, b)) && all(c(a, b) >= 0 & c(a, b) < n), sprintf("Elements must be integers from 0 to %d.", n - 1)))
      use_rank <- "rank" %in% input$uf_opt; use_pc <- "pc" %in% input$uf_opt
      parent <- seq_len(n); rank <- rep(0, n)
      find <- function(x) {
        path <- integer(0)
        while (parent[x] != x) { path <- c(path, x); x <- parent[x] }
        if (use_pc) for (p in path) parent[p] <<- x
        list(root = x, hops = length(path))
      }
      steps <- list(list(parent = parent, hl = integer(0), msg = sprintf("%d elements, each its own set: every node is its own parent (a root).", n)))
      for (k in seq_along(a)) {
        fa <- find(a[k] + 1); fb <- find(b[k] + 1); ra <- fa$root; rb <- fb$root
        if (ra == rb) msg <- sprintf("union(%d, %d): both lead to root %d → <b>already in the same set</b>. In a graph, this edge would close a cycle.", a[k], b[k], ra - 1)
        else {
          if (use_rank) {
            if (rank[ra] < rank[rb]) { t <- ra; ra <- rb; rb <- t }
            parent[rb] <- ra; if (rank[ra] == rank[rb]) rank[ra] <- rank[ra] + 1
            msg <- sprintf("union(%d, %d): roots are %d and %d. Hang the <b>shorter</b> tree (root %d) under the taller (root %d).", a[k], b[k], fa$root - 1, fb$root - 1, rb - 1, ra - 1)
          } else {
            parent[ra] <- rb
            msg <- sprintf("union(%d, %d): roots are %d and %d. Naive rule: point the first root (%d) at the second (%d).", a[k], b[k], ra - 1, rb - 1, ra - 1, rb - 1)
          }
        }
        msg <- paste0(msg, sprintf(" The two finds walked %d hop(s).%s", fa$hops + fb$hops, if (use_pc && fa$hops + fb$hops > 1) " Path compression re-pointed the visited nodes at their root." else ""))
        steps[[length(steps) + 1]] <- list(parent = parent, hl = c(a[k], b[k]) + 1, msg = msg)
      }
      steps
    })
    uf <- stepper_server(input, output, session, "uf", uf_steps)
    uf_depth <- function(parent) vapply(seq_along(parent), function(x) { d <- 0; while (parent[x] != x) { x <- parent[x]; d <- d + 1 }; d }, numeric(1))
    output$uf_plot <- renderPlotly({
      s <- uf$cur(); p <- s$parent; n <- length(p)
      d <- uf_depth(p); x <- rep(NA_real_, n); leafx <- 0
      place <- function(i) {
        kk <- which(p == i & seq_len(n) != i)
        if (length(kk) == 0) { leafx <<- leafx + 1; x[i] <<- leafx } else { for (j in kk) place(j); x[i] <<- mean(x[kk]) }
      }
      for (r in which(p == seq_len(n))) { place(r); leafx <- leafx + 0.5 }
      nd <- data.frame(x = x, y = -d, label = seq_len(n) - 1)
      state <- ifelse(p == seq_len(n), "done", "visited"); state[s$hl] <- "active"
      nd <- state_style(nd, state)
      ch <- which(p != seq_len(n))
      ed <- if (length(ch)) data.frame(x0 = x[ch], y0 = -d[ch], x1 = x[p[ch]], y1 = -d[p[ch]]) else NULL
      net_plot(nd, ed, directed = TRUE, size = 36, height = 300)
    })
    output$uf_explain <- renderUI(explain(uf$cur()$msg))
    output$uf_kpi <- renderUI({
      p <- uf$cur()$parent; d <- uf_depth(p)
      kpi_row(kpi(sum(p == seq_along(p)), "disjoint sets", COL$ok), kpi(max(d), "tallest tree", if (max(d) > 3) COL$err else COL$pri), kpi(sprintf("%.1f", mean(d)), "avg hops to root", COL$acc))
    })

    # ── Kruskal ──────────────────────────────────────────────────────────────
    ks_graph <- reactive({
      e <- parse_edges(input$ks_edges)
      validate(need(!is.null(e) && nrow(e) >= 1, "Enter edges like A-B:4,B-C:2."))
      v <- graph_nodes(e); validate(need(length(v) <= 12, "Use at most 12 nodes."))
      e <- e[order(e$w), ]; rownames(e) <- NULL
      list(e = e, v = v, nodes = circle_layout(v))
    })
    ks_steps <- reactive({
      g <- ks_graph(); comp <- setNames(seq_along(g$v), g$v)
      status <- rep("todo", nrow(g$e)); total <- 0
      steps <- list(list(status = status, cur = NA, total = 0, comp = comp, msg = "Sort all edges by weight. Take them cheapest first; keep an edge only if it joins two different components."))
      for (i in seq_len(nrow(g$e))) {
        u <- g$e$from[i]; v <- g$e$to[i]
        if (comp[u] != comp[v]) {
          comp[comp == comp[v]] <- comp[u]; status[i] <- "take"; total <- total + g$e$w[i]
          msg <- sprintf("%s–%s (weight %s): <code>find(%s) ≠ find(%s)</code> → <b>accept</b> and union them. Running total %s.", u, v, g$e$w[i], u, v, total)
        } else {
          status[i] <- "skip"
          msg <- sprintf("%s–%s (weight %s): both ends are already in the same component → <b>reject</b>, it would form a cycle.", u, v, g$e$w[i])
        }
        steps[[length(steps) + 1]] <- list(status = status, cur = i, total = total, comp = comp, msg = msg)
        if (sum(status == "take") == length(g$v) - 1) break
      }
      done <- length(unique(comp)) == 1
      steps[[length(steps)]]$msg <- paste(steps[[length(steps)]]$msg, if (done) sprintf("<b>%d edges chosen = V − 1 → spanning tree complete, total weight %s.</b>", length(g$v) - 1, total) else "<b>Edges exhausted; the graph is not connected, so this is a spanning forest.</b>")
      steps
    })
    ks <- stepper_server(input, output, session, "ks", ks_steps)
    output$ks_plot <- renderPlotly({
      g <- ks_graph(); s <- ks$cur()
      pal <- c("#4f46e5", "#06b6d4", "#f59e0b", "#ec4899", "#10b981", "#7c3aed", "#ef4444", "#0ea5e9", "#84cc16", "#f97316", "#64748b", "#14b8a6")
      nd <- g$nodes; nd$color <- pal[(s$comp[nd$label] - 1) %% length(pal) + 1]; nd$border <- nd$color; nd$tcol <- "#ffffff"
      ec <- edge_coords(g$e, nd); ec$label <- g$e$w
      ec$color <- ifelse(s$status == "take", COL$ok, ifelse(s$status == "skip", "#fca5a5", COL$idle))
      ec$width <- ifelse(s$status == "take", 5, 2)
      if (!is.na(s$cur)) { ec$width[s$cur] <- 6; if (s$status[s$cur] == "take") ec$color[s$cur] <- COL$pri }
      net_plot(nd, ec, size = 38, height = 340)
    })
    output$ks_kpi <- renderUI({
      g <- ks_graph(); s <- ks$cur()
      kpi_row(kpi(s$total, "tree weight", COL$ok), kpi(sprintf("%d / %d", sum(s$status == "take"), length(g$v) - 1), "edges chosen", COL$pri), kpi(length(unique(s$comp)), "components", COL$warn))
    })
    output$ks_list <- renderUI({
      g <- ks_graph(); s <- ks$cur()
      tags$div(class = "lane", tags$span(class = "lane-lab", "sorted edges"),
        lapply(seq_len(nrow(g$e)), function(i)
          tags$span(class = paste("vnode sm", switch(s$status[i], take = "found", skip = "bad", todo = if (!is.na(s$cur) && i == s$cur) "active" else "")),
                    sprintf("%s%s:%s", g$e$from[i], g$e$to[i], g$e$w[i]))))
    })
    output$ks_explain <- renderUI(tagList(explain(ks$cur()$msg), hint("Node colour = current component. Watch the colours merge as edges are accepted.")))

    quiz_server(input, output, session, topic = "advanced", progress = progress, questions = list(
      list(q = "Searching a trie holding one million words for a 6-letter word takes roughly…",
           opts = c("1,000,000 steps", "20 steps (log₂ n)", "6 steps", "It depends on the hash function"), ans = 3,
           why = "A trie lookup follows one edge per character: O(L), independent of how many words are stored."),
      list(q = "Why does each trie node need an end-of-word flag?",
           opts = c("To save memory", "To distinguish a stored word from a mere prefix of a longer word", "To sort the children", "To count nodes"), ans = 2,
           why = "After inserting 'card', the path c-a-r exists. Without a flag, search('car') would wrongly return true."),
      list(q = "In union-find, two elements belong to the same set exactly when…",
           opts = c("They have the same parent", "They have the same root", "They have the same rank", "They were united directly"), ans = 2,
           why = "Parents can differ inside one tree. Only the root — reached by following parents — identifies the set."),
      list(q = "With union by rank and path compression, a sequence of m operations costs…",
           opts = c("O(m · n)", "O(m log n)", "O(m · α(n)), effectively linear", "O(m²)"), ans = 3,
           why = "α is the inverse Ackermann function, at most 4 for any input that fits in the universe — each operation is practically constant."),
      list(q = "Kruskal's algorithm rejects an edge when…",
           opts = c("Its weight is above average", "Its endpoints are already in the same component", "It touches the starting vertex", "The heap is empty"), ans = 2,
           why = "Such an edge would create a cycle and cannot improve a spanning tree. Union-find answers that test in near-constant time.")
    ))
  })
}
