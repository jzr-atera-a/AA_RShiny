# modules/mod_trees.R — Trees & BSTs

trees_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🌳", "Trees & Binary Search Trees",
      "Hierarchies where each node owns its subtrees. Almost every tree problem is a traversal plus a small decision at each node — pick the right traversal order and the solution falls out.",
      c("Inorder", "Preorder", "Postorder", "Level Order (BFS)", "BST Property", "LCA")),

    topic_tabs(ns,
      visual = tagList(
        fluidRow(
          box(title = "Build a BST and walk it", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(6, textInput(ns("vals"), "Insert in this order:", "8,3,10,1,6,14,4,7,13")),
              column(6, radioButtons(ns("trav"), "Traversal:", inline = TRUE,
                choices = c("Inorder" = "inorder", "Preorder" = "preorder", "Postorder" = "postorder", "Level order" = "level")))
            ),
            stepper_ui(ns, "tr"),
            plotlyOutput(ns("tree_plot"), height = "320px"),
            uiOutput(ns("tr_viz")),
            legend_row(c("visiting now" = COL$pri, "already visited" = COL$soft, "on the path / in the queue" = "#fef3c7", "not yet seen" = "#ffffff"))
          ),
          box(title = "Tree Health", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("stats")),
            uiOutput(ns("trav_note")),
            uiOutput(ns("trav_code"))
          )
        ),
        fluidRow(
          box(title = "Search and Lowest Common Ancestor", status = "primary", solidHeader = TRUE, width = 7,
            hint("Uses the tree above. Each comparison throws away an entire subtree — that is where O(log n) comes from."),
            tabsetPanel(
              tabPanel("Search",
                numericInput(ns("find"), "Look for:", 7),
                plotlyOutput(ns("find_plot"), height = "290px"),
                uiOutput(ns("find_explain"))),
              tabPanel("Lowest common ancestor",
                fluidRow(column(6, numericInput(ns("lca_p"), "Node p:", 4)), column(6, numericInput(ns("lca_q"), "Node q:", 7))),
                plotlyOutput(ns("lca_plot"), height = "290px"),
                uiOutput(ns("lca_explain")))
            )
          ),
          box(title = "Insertion order decides the height", status = "info", solidHeader = TRUE, width = 5,
            plotlyOutput(ns("height_plot"), height = "300px"),
            callout("Insert sorted data into a plain BST and it degenerates into a linked list: height n, every operation O(n). Self-balancing trees (AVL, red-black) rotate on insert to keep height ≈ log₂n. Try <code>1,2,3,4,5,6,7</code> above, then <code>4,2,6,1,3,5,7</code>.", "warn")
          )
        )
      ),

      learn = tagList(
        insight_cards(
          when = c("Need values of a BST <b>in sorted order</b> (k-th smallest, validate) → inorder.",
                   "Copy / serialise a tree, or decide at the parent before the children → preorder.",
                   "A node's answer <b>depends on its children's answers</b> (height, diameter, max path sum) → postorder.",
                   "Anything 'per level', shortest depth, right-side view → level order with a queue."),
          pitfalls = c("Validating a BST by comparing only parent and child — the constraint is on the whole subtree; carry (low, high) bounds.",
                       "Forgetting the base case <code>if not node: return</code>.",
                       "Confusing depth (from the root down) with height (from the leaves up).",
                       "Assuming O(log n): only true if the tree is balanced. Skewed trees are O(n) and can overflow the recursion stack."),
          tips = c("Start every tree answer with: 'what do I need back from each child, and what do I pass down?'",
                   "Return a tuple from the helper when you need two facts (e.g. height and is-balanced).",
                   "State complexity as O(n) time, O(h) space — h is the height, between log n and n.")
        ),
        fluidRow(
          box(title = "BST Operation Costs", status = "info", solidHeader = TRUE, width = 5,
            cplx_table(data.frame(
              Operation = c("Search", "Insert", "Delete", "Min / max", "Inorder successor", "Full traversal"),
              Balanced = c("O(log n)", "O(log n)", "O(log n)", "O(log n)", "O(log n)", "O(n)"),
              Skewed = c("O(n)", "O(n)", "O(n)", "O(n)", "O(n)", "O(n)"),
              stringsAsFactors = FALSE)),
            hint("A perfect binary tree of height h holds 2ʰ − 1 nodes, so n nodes need height ≥ ⌈log₂(n+1)⌉.")
          ),
          box(title = "Which traversal for which job", status = "info", solidHeader = TRUE, width = 7,
            cplx_table(data.frame(
              Traversal = c("Inorder (L · node · R)", "Preorder (node · L · R)", "Postorder (L · R · node)", "Level order (BFS)"),
              Signature.use = c("Sorted output from a BST", "Serialise, clone, path-from-root problems", "Bottom-up aggregation, safe deletion", "Levels, minimum depth, connect next pointers"),
              Example.problems = c("#98, #230", "#297, #105, #114", "#543, #124, #104", "#102, #117, #199"),
              stringsAsFactors = FALSE)),
            callout("<b>Reconstruction rule:</b> inorder + preorder, or inorder + postorder, determine a unique tree (distinct values). The pre/post order gives you the root; inorder tells you what is left and right of it.", "tip")
          )
        ),
        fluidRow(
          box(title = "Templates worth memorising (Python)", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(4,
                dsa_code(
'def levelOrder(root):
    if not root: return []
    res, q = [], deque([root])
    while q:
        level = []
        for _ in range(len(q)):      # one level
            node = q.popleft()
            level.append(node.val)
            if node.left:  q.append(node.left)
            if node.right: q.append(node.right)
        res.append(level)
    return res', "Level order — BFS"),
                dsa_code(
'def isValidBST(root, lo=float("-inf"), hi=float("inf")):
    if not root: return True
    if not (lo < root.val < hi): return False
    return (isValidBST(root.left, lo, root.val) and
            isValidBST(root.right, root.val, hi))', "Validate BST — bounds")
              ),
              column(4,
                dsa_code(
'def diameter(root):
    best = 0
    def height(node):               # postorder
        nonlocal best
        if not node: return 0
        L, R = height(node.left), height(node.right)
        best = max(best, L + R)     # path through node
        return 1 + max(L, R)
    height(root)
    return best', "Diameter — postorder pattern"),
                dsa_code(
'def lowestCommonAncestor(root, p, q):
    while root:
        if p.val < root.val and q.val < root.val:
            root = root.left
        elif p.val > root.val and q.val > root.val:
            root = root.right
        else:
            return root              # split point', "LCA in a BST — O(h)")
              ),
              column(4,
                dsa_code(
'def buildTree(inorder, postorder):
    idx = {v: i for i, v in enumerate(inorder)}
    def build(lo, hi):
        if lo > hi: return None
        root = TreeNode(postorder.pop())   # last = root
        mid = idx[root.val]
        root.right = build(mid + 1, hi)    # right first!
        root.left  = build(lo, mid - 1)
        return root
    return build(0, len(inorder) - 1)', "#106 Build from inorder + postorder"),
                dsa_code(
'def flatten(root):                 # O(1) extra space
    cur = root
    while cur:
        if cur.left:
            pre = cur.left
            while pre.right:           # rightmost of left
                pre = pre.right
            pre.right = cur.right
            cur.right, cur.left = cur.left, None
        cur = cur.right', "#114 Flatten to linked list — Morris-style")
              )
            )
          )
        )
      ),

      practice = practice_tab(ns, "trees",
        "Cormen, Leiserson, Rivest & Stein (2022). Introduction to Algorithms (4th ed.) — ch. 12–13.",
        "Adelson-Velsky & Landis (1962). An algorithm for the organization of information — the AVL tree.",
        "Morris, J. H. (1979). Traversing binary trees simply and cheaply. Information Processing Letters 9(5).")
    )
  )
}

trees_server <- function(id, progress = NULL) {
  moduleServer(id, function(input, output, session) {

    vals <- reactive({
      v <- unique(parse_ints(input$vals, 20))
      validate(need(length(v) >= 1, "Enter at least one integer."))
      v
    })
    tree <- reactive(bst_build(vals()))
    lay  <- reactive(tree_layout(tree()))

    path_to <- function(t, v) {            # search path (values) from the root
      p <- integer(0)
      while (!is.null(t)) {
        p <- c(p, t$val)
        if (v == t$val) break
        t <- if (v < t$val) t$left else t$right
      }
      p
    }

    # ── Traversal steps ──────────────────────────────────────────────────────
    tr_steps <- reactive({
      t <- tree(); kind <- input$trav
      steps <- list(list(cur = NA, done = integer(0), aux = integer(0),
        msg = switch(kind,
          inorder   = "Inorder: finish the <b>left</b> subtree, visit the node, then the right subtree.",
          preorder  = "Preorder: visit the node <b>first</b>, then its left subtree, then its right.",
          postorder = "Postorder: finish <b>both</b> subtrees before visiting the node itself.",
          level     = "Level order: visit by distance from the root, using a FIFO queue.")))
      done <- integer(0)
      if (kind == "level") {
        q <- list(t)
        while (length(q) > 0) {
          node <- q[[1]]; q <- q[-1]
          if (!is.null(node$left))  q <- c(q, list(node$left))
          if (!is.null(node$right)) q <- c(q, list(node$right))
          qv <- vapply(q, function(z) z$val, numeric(1))
          steps[[length(steps) + 1]] <- list(cur = node$val, done = done, aux = qv,
            msg = sprintf("Dequeue <b>%s</b>, visit it, enqueue its children. Queue is now [%s].", node$val, paste(qv, collapse = ", ")))
          done <- c(done, node$val)
        }
      } else {
        add <- function(node, why) {
          steps[[length(steps) + 1]] <<- list(cur = node$val, done = done, aux = path_to(t, node$val), msg = why)
          done <<- c(done, node$val)
        }
        walk <- function(node) {
          if (is.null(node)) return(invisible())
          if (kind == "preorder") add(node, sprintf("Visit <b>%s</b> before descending into its children.", node$val))
          walk(node$left)
          if (kind == "inorder") add(node, sprintf("Left subtree of %s is finished → visit <b>%s</b>, then go right.", node$val, node$val))
          walk(node$right)
          if (kind == "postorder") add(node, sprintf("Both subtrees of %s are finished → visit <b>%s</b>.", node$val, node$val))
        }
        walk(t)
      }
      steps[[length(steps) + 1]] <- list(cur = NA, done = done, aux = integer(0),
        msg = sprintf("<b>Done.</b> %s", switch(kind,
          inorder = "Inorder on a BST always comes out sorted.",
          preorder = "The root is first — this order can rebuild the same tree by re-inserting.",
          postorder = "The root is last — children are always processed before parents.",
          level = "Nodes appear grouped by depth.")))
      steps
    })
    tr <- stepper_server(input, output, session, "tr", tr_steps)

    output$tree_plot <- renderPlotly({
      L <- lay(); s <- tr$cur(); nodes <- L$nodes
      state <- rep("idle", nrow(nodes))
      state[nodes$label %in% s$aux]  <- "frontier"
      state[nodes$label %in% s$done] <- "visited"
      if (!is.na(s$cur)) state[nodes$label == s$cur] <- "active"
      net_plot(state_style(nodes, state), L$edges, size = 36, height = 320)
    })
    output$tr_viz <- renderUI({
      s <- tr$cur()
      out <- c(s$done, if (!is.na(s$cur)) s$cur)
      tagList(
        lane(if (input$trav == "level") "queue" else "call stack", s$aux, "frontier", "empty"),
        lane("output", out, "visited", "nothing visited yet"),
        explain(s$msg))
    })
    output$stats <- renderUI({
      n <- length(vals()); h <- tree_height(tree()); best <- ceiling(log2(n + 1))
      ratio <- h / best
      verdict <- if (h == best) c("Perfectly compact", COL$ok) else if (ratio <= 1.5) c("Reasonably balanced", COL$acc) else if (h == n) c("Degenerate (a list)", COL$err) else c("Skewed", COL$warn)
      tagList(
        kpi_row(kpi(n, "nodes", COL$pri), kpi(h, "height", verdict[2]), kpi(best, "minimum possible", COL$ok)),
        callout(sprintf("<b>%s.</b> Worst-case search touches %d node(s); a balanced tree with %d nodes would need at most %d.", verdict[1], h, n, best),
                if (ratio <= 1.5) "success" else "warn"))
    })
    output$trav_note <- renderUI({
      callout(switch(input$trav,
        inorder   = "<b>Inorder</b> is how you read a BST in ascending order. Reverse it (R · node · L) for descending.",
        preorder  = "<b>Preorder</b> output, re-inserted in order, rebuilds the identical BST — that is why it is used to serialise trees.",
        postorder = "<b>Postorder</b> guarantees both children are complete first: the natural order for computing heights, sizes and sums.",
        level     = "<b>Level order</b> is BFS. Capture <code>len(queue)</code> at the start of each round to know where one level ends."), "info")
    })
    output$trav_code <- renderUI({
      pseudo(switch(input$trav,
        inorder   = c("def dfs(node):", "    if not node: return", "    dfs(node.left)", "    visit(node)", "    dfs(node.right)"),
        preorder  = c("def dfs(node):", "    if not node: return", "    visit(node)", "    dfs(node.left)", "    dfs(node.right)"),
        postorder = c("def dfs(node):", "    if not node: return", "    dfs(node.left)", "    dfs(node.right)", "    visit(node)"),
        level     = c("q = deque([root])", "while q:", "    node = q.popleft()", "    visit(node)", "    q.extend(children(node))")),
        active = switch(input$trav, inorder = 4, preorder = 3, postorder = 5, level = 4))
    })

    # ── Search ───────────────────────────────────────────────────────────────
    output$find_plot <- renderPlotly({
      L <- lay(); v <- input$find; req(!is.null(v), !is.na(v))
      p <- path_to(tree(), v); nodes <- L$nodes
      state <- rep("idle", nrow(nodes))
      state[nodes$label %in% p] <- "path"
      if (v %in% nodes$label) state[nodes$label == v] <- "done"
      e <- L$edges
      if (!is.null(e)) { on <- e$from %in% p & e$to %in% p; e$color <- ifelse(on, COL$warn, COL$idle); e$width <- ifelse(on, 4, 2) }
      net_plot(state_style(nodes, state), e, size = 34, height = 290)
    })
    output$find_explain <- renderUI({
      v <- input$find; req(!is.null(v), !is.na(v))
      p <- path_to(tree(), v); n <- length(vals()); found <- v %in% vals()
      moves <- vapply(seq_along(p), function(i) {
        if (p[i] == v) sprintf("%s ✓", p[i]) else sprintf("%s (%s → go %s)", p[i], if (v < p[i]) "smaller" else "larger", if (v < p[i]) "left" else "right")
      }, character(1))
      explain(sprintf("%s after <b>%d comparison(s)</b> out of %d nodes: %s%s", if (found) "<b>Found</b>" else "<b>Not present</b>", length(p), n,
                      paste(moves, collapse = " → "), if (found) "" else " → fell off the tree; this is exactly where it would be inserted."))
    })

    # ── LCA ──────────────────────────────────────────────────────────────────
    lca_calc <- reactive({
      p <- input$lca_p; q <- input$lca_q
      validate(need(!is.null(p) && !is.na(p) && !is.null(q) && !is.na(q), "Enter two node values."),
               need(p %in% vals() && q %in% vals(), "Both values must exist in the tree above."))
      pp <- path_to(tree(), p); pq <- path_to(tree(), q)
      k <- 0; while (k < min(length(pp), length(pq)) && pp[k + 1] == pq[k + 1]) k <- k + 1
      list(p = p, q = q, pp = pp, pq = pq, lca = pp[k], shared = pp[seq_len(k)])
    })
    output$lca_plot <- renderPlotly({
      L <- lay(); r <- lca_calc(); nodes <- L$nodes
      state <- rep("idle", nrow(nodes))
      state[nodes$label %in% c(r$pp, r$pq)] <- "frontier"
      state[nodes$label %in% c(r$p, r$q)] <- "active"
      state[nodes$label == r$lca] <- "done"
      e <- L$edges
      if (!is.null(e)) {
        on <- (e$from %in% r$pp & e$to %in% r$pp) | (e$from %in% r$pq & e$to %in% r$pq)
        e$color <- ifelse(on, COL$warn, COL$idle); e$width <- ifelse(on, 4, 2)
      }
      net_plot(state_style(nodes, state), e, size = 34, height = 290)
    })
    output$lca_explain <- renderUI({
      r <- lca_calc()
      explain(sprintf("Walk down from the root while <b>both</b> targets lie on the same side. At <b>%s</b> they split (%s) — that node is the lowest common ancestor. No parent pointers and no extra memory needed.",
                      r$lca, if (r$lca %in% c(r$p, r$q)) "one target is the node itself" else sprintf("%s goes left, %s goes right", min(r$p, r$q), max(r$p, r$q))))
    })

    # ── Height vs insertion order ────────────────────────────────────────────
    output$height_plot <- renderPlotly({
      ns_ <- c(1, 2, 4, 8, 16, 32, 64, 128)
      set.seed(42)
      rand_h <- vapply(ns_, function(n) mean(replicate(8, tree_height(bst_build(sample(n))))), numeric(1))
      plot_ly(x = ns_, height = 300) %>%
        add_trace(y = ns_, type = "scatter", mode = "lines+markers", name = "Sorted insert (degenerate)", line = list(color = COL$err, width = 3), marker = list(color = COL$err)) %>%
        add_trace(y = rand_h, type = "scatter", mode = "lines+markers", name = "Random insert (average)", line = list(color = COL$warn, width = 3), marker = list(color = COL$warn)) %>%
        add_trace(y = ceiling(log2(ns_ + 1)), type = "scatter", mode = "lines+markers", name = "Balanced (optimal)", line = list(color = COL$ok, width = 3), marker = list(color = COL$ok)) %>%
        dsa_layout(xt = "nodes inserted", yt = "tree height", legend = TRUE) %>%
        layout(yaxis = list(type = "log"), xaxis = list(type = "log"))
    })

    quiz_server(input, output, session, topic = "trees", progress = progress, questions = list(
      list(q = "Inorder traversal of a valid BST yields the values in…",
           opts = c("Insertion order", "Ascending order", "Level order", "Descending order"), ans = 2,
           why = "Everything in the left subtree is smaller and is visited first; everything in the right is larger and visited after."),
      list(q = "You must compute the height of every subtree. Which traversal fits naturally?",
           opts = c("Preorder", "Inorder", "Postorder", "Level order"), ans = 3,
           why = "A node's height needs both children's heights first — children before parent is postorder."),
      list(q = "Inserting 1, 2, 3, …, n into a plain BST gives height…",
           opts = c("log₂ n", "√n", "n", "2"), ans = 3,
           why = "Each new value is the largest so far and becomes the right child of the previous one — a linked list of height n."),
      list(q = "Why is 'node.left.val &lt; node.val &lt; node.right.val at every node' not enough to validate a BST?",
           opts = c("It is enough", "A deeper descendant can violate an ancestor's bound", "It ignores duplicates", "It fails only on empty trees"), ans = 2,
           why = "Example: root 5, right child 8, whose left child is 3. Every local check passes, yet 3 sits in the right subtree of 5."),
      list(q = "For the LCA of p and q in a BST, you stop descending when…",
           opts = c("You reach a leaf", "p and q fall on different sides of the current node (or one equals it)", "The current node is larger than both", "You have visited log n nodes"), ans = 2,
           why = "While both are smaller go left, both larger go right. The first node where they diverge is the lowest common ancestor.")
    ))
  })
}
