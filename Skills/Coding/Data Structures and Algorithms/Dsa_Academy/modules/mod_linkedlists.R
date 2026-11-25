# modules/mod_linkedlists.R — Linked Lists

linkedlists_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🔗", "Linked Lists",
      "Nodes joined by pointers: O(1) insert and delete once you hold the node, O(n) to get there. Interviews test pointer discipline — reversal, fast/slow pointers, and the dummy-head trick.",
      c("Pointer Reversal", "Fast / Slow", "Floyd's Cycle", "Dummy Head", "Merge")),

    topic_tabs(ns,
      visual = tagList(
        fluidRow(
          box(title = "In-place Reversal — watch the arrows flip", status = "primary", solidHeader = TRUE, width = 8,
            textInput(ns("rev_vals"), "Nodes (head first):", "1,2,3,4,5"),
            stepper_ui(ns, "rev"),
            plotlyOutput(ns("rev_plot"), height = "190px"),
            uiOutput(ns("rev_explain")),
            legend_row(c("prev" = COL$ok, "cur" = COL$pri, "nxt (saved)" = COL$warn))
          ),
          box(title = "What the code is doing", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("rev_code")),
            callout("Three pointers, one rule: <b>save <code>next</code> before you overwrite it</b>, otherwise the rest of the list is lost.", "tip")
          )
        ),
        fluidRow(
          box(title = "Floyd's Tortoise & Hare — detect a cycle and find its entry", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(6, sliderInput(ns("cy_n"), "Number of nodes:", min = 4, max = 12, value = 8, step = 1)),
              column(6, sliderInput(ns("cy_pos"), "Tail links back to index (−1 = no cycle):", min = -1, max = 10, value = 3, step = 1))
            ),
            stepper_ui(ns, "cy"),
            plotlyOutput(ns("cy_plot"), height = "300px"),
            uiOutput(ns("cy_explain")),
            legend_row(c("slow (+1)" = COL$ok, "fast (+2)" = COL$warn, "both on same node" = COL$pri, "cycle entry" = COL$pink))
          ),
          box(title = "Why phase 2 finds the entry", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("cy_kpi")),
            callout("Let <b>a</b> = head → entry, <b>b</b> = entry → meeting point, <b>c</b> = cycle length.<br>When they meet: slow walked <code>a + b</code>, fast walked <code>2(a + b)</code>, and fast is ahead by whole laps: <code>2(a+b) − (a+b) = k·c</code>.<br>So <code>a = k·c − b</code>: walking <b>a</b> steps from the meeting point lands exactly on the entry — the same distance as from the head. Move one pointer to head, step both by 1, and they collide at the entry.", "info")
          )
        ),
        fluidRow(
          box(title = "Merge Two Sorted Lists — dummy head in action", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(4, textInput(ns("mg_a"), "List A (sorted):", "1,4,7,10")),
              column(4, textInput(ns("mg_b"), "List B (sorted):", "2,3,8,9,12")),
              column(4, stepper_ui(ns, "mg"))
            ),
            uiOutput(ns("mg_viz"))
          )
        )
      ),

      learn = tagList(
        insight_cards(
          when = c("Frequent insert / delete at the ends or at a known node (queues, LRU caches).",
                   "You need to detect a loop or find the middle in <b>O(1) space</b> → fast / slow pointers.",
                   "'k-th from the end' → two pointers held k apart.",
                   "Any time the head itself may change → start with a <b>dummy node</b>."),
          pitfalls = c("Losing the rest of the list by overwriting <code>.next</code> before saving it.",
                       "Null dereference: check <code>fast and fast.next</code>, in that order.",
                       "Forgetting to terminate the new tail (<code>tail.next = None</code>) → accidental cycle.",
                       "Returning <code>head</code> after a reversal — the new head is <code>prev</code>."),
          tips = c("Draw boxes and arrows before coding; narrate each pointer move.",
                   "Test on length 0, 1 and 2 — nearly every linked-list bug shows up there.",
                   "Many 'hard' problems are compositions: find middle + reverse second half + merge (Reorder List, Palindrome).")
        ),
        fluidRow(
          box(title = "Array vs Linked List", status = "info", solidHeader = TRUE, width = 5,
            cplx_table(data.frame(
              Operation = c("Access k-th element", "Search", "Insert / delete at head", "Insert / delete at tail", "Insert / delete at known node", "Memory locality"),
              Array = c("O(1)", "O(n)", "O(n)", "O(1) amortised", "O(n)", "Excellent"),
              Linked.List = c("O(n)", "O(n)", "O(1)", "O(1) with tail ptr*", "O(1)", "Poor"),
              stringsAsFactors = FALSE)),
            hint("* Deleting the tail of a singly linked list is O(n) — you need the node before it. Doubly linked lists make it O(1).")
          ),
          box(title = "Pointer Patterns at a Glance", status = "info", solidHeader = TRUE, width = 7,
            cplx_table(data.frame(
              Pattern = c("Dummy head", "Fast / slow", "Gap of k", "Reverse in place", "Middle + reverse + merge"),
              Idea = c("Fake node before head so head needs no special case",
                       "Fast moves 2×; when it finishes, slow is at the middle",
                       "Advance one pointer k steps, then move both",
                       "prev / cur / nxt, flip one arrow per step",
                       "Split, reverse second half, weave or compare"),
              Solves = c("Merge, remove, partition", "Middle, cycle, cycle entry", "Remove n-th from end", "Reverse, reverse k-group", "Reorder list, palindrome"),
              stringsAsFactors = FALSE))
          )
        ),
        fluidRow(
          box(title = "Templates worth memorising (Python)", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(4,
                dsa_code(
'def reverseList(head):
    prev, cur = None, head
    while cur:
        nxt = cur.next     # 1. save
        cur.next = prev    # 2. flip
        prev = cur         # 3. advance prev
        cur = nxt          # 4. advance cur
    return prev', "Reverse — O(n) time, O(1) space"),
                dsa_code(
'def middleNode(head):
    slow = fast = head
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
    return slow', "Middle node")
              ),
              column(4,
                dsa_code(
'def detectCycle(head):
    slow = fast = head
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
        if slow is fast:           # phase 1: met
            slow = head
            while slow is not fast:   # phase 2
                slow = slow.next
                fast = fast.next
            return slow            # cycle entry
    return None', "Cycle entry — Floyd")
              ),
              column(4,
                dsa_code(
'def mergeTwoLists(a, b):
    dummy = tail = ListNode()
    while a and b:
        if a.val <= b.val:
            tail.next, a = a, a.next
        else:
            tail.next, b = b, b.next
        tail = tail.next
    tail.next = a or b      # attach leftover
    return dummy.next', "Merge with dummy head"),
                dsa_code(
'def removeNthFromEnd(head, n):
    dummy = ListNode(0, head)
    fast = slow = dummy
    for _ in range(n):
        fast = fast.next
    while fast.next:
        fast, slow = fast.next, slow.next
    slow.next = slow.next.next
    return dummy.next', "Remove n-th from end — gap of n")
              )
            )
          )
        )
      ),

      practice = practice_tab(ns, "linkedlists",
        "Knuth, D. E. (1997). The Art of Computer Programming, Vol. 1: Fundamental Algorithms (3rd ed.) — §2.2 linked allocation.",
        "Floyd, R. W. (1967). Nondeterministic Algorithms. JACM 14(4) — attributed origin of the tortoise-and-hare idea.",
        "Sedgewick & Wayne (2011). Algorithms (4th ed.). Addison-Wesley.")
    )
  )
}

linkedlists_server <- function(id, progress = NULL) {
  moduleServer(id, function(input, output, session) {

    # ── Reversal ─────────────────────────────────────────────────────────────
    rev_vals <- reactive({
      v <- parse_ints(input$rev_vals, 9)
      validate(need(length(v) >= 1, "Enter at least one node value."))
      v
    })
    # k = nodes already reversed. prev = node k, cur = node k+1.
    rev_steps <- reactive({
      v <- rev_vals(); n <- length(v)
      steps <- list(list(k = 0, nxt = FALSE, line = 1,
        msg = "Start: <code>prev = None</code>, <code>cur = head</code>. Every arrow still points right."))
      for (k in 0:(n - 1)) {
        steps[[length(steps) + 1]] <- list(k = k, nxt = TRUE, line = 3,
          msg = sprintf("Save <code>nxt = cur.next</code> (%s) so the remainder of the list is not lost.",
                        if (k + 2 <= n) v[k + 2] else "None"))
        steps[[length(steps) + 1]] <- list(k = k + 1, nxt = FALSE, line = 4:6,
          msg = sprintf("Flip: node <b>%d</b> now points back to %s. Then slide <code>prev</code> and <code>cur</code> one step right.",
                        v[k + 1], if (k >= 1) v[k] else "None"))
      }
      steps[[length(steps)]]$msg <- paste(steps[[length(steps)]]$msg,
        "<b><code>cur</code> is None → done. Return <code>prev</code>, the new head.</b>")
      steps[[length(steps)]]$line <- 7
      steps
    })
    rv <- stepper_server(input, output, session, "rev", rev_steps)

    output$rev_plot <- renderPlotly({
      v <- rev_vals(); n <- length(v); s <- rv$cur(); k <- s$k
      # positions: 0 = left None, 1..n nodes, n+1 = right None
      nodes <- data.frame(x = 0:(n + 1), y = 0, label = c("None", v, "None"), stringsAsFactors = FALSE)
      state <- rep("idle", n + 2); sub <- rep("", n + 2)
      state[k + 1] <- "done";   sub[k + 1] <- "prev"
      state[k + 2] <- "active"; sub[k + 2] <- "cur"
      if (s$nxt && k + 3 <= n + 2) { state[k + 3] <- "frontier"; sub[k + 3] <- "nxt" }
      nodes <- state_style(nodes, state); nodes$sub <- sub
      nodes$border[c(1, n + 2)] <- ifelse(state[c(1, n + 2)] == "idle", "#e2e8f0", nodes$border[c(1, n + 2)])
      from <- seq_len(n); to <- ifelse(from <= k, from - 1, from + 1)
      edges <- data.frame(x0 = from, y0 = 0, x1 = to, y1 = 0,
                          color = ifelse(from <= k, COL$ok, COL$mute), width = ifelse(from <= k, 3, 2))
      net_plot(nodes, edges, directed = TRUE, size = 40, height = 190)
    })
    output$rev_explain <- renderUI(explain(rv$cur()$msg))
    output$rev_code <- renderUI({
      pseudo(c("prev, cur = None, head", "while cur:", "    nxt = cur.next",
               "    cur.next = prev", "    prev = cur", "    cur = nxt", "return prev"),
             active = rv$cur()$line)
    })

    # ── Floyd's cycle detection ──────────────────────────────────────────────
    cy_cfg <- reactive({
      n <- input$cy_n; pos <- input$cy_pos
      req(n, !is.null(pos))
      has <- pos >= 0
      pos <- if (has) min(pos, n - 2) else NA      # keep cycle length >= 2
      list(n = n, has = has, entry = if (has) pos + 1 else NA)   # 1-based entry
    })
    cy_steps <- reactive({
      cfg <- cy_cfg(); n <- cfg$n
      nxt <- function(i) if (is.na(i)) NA else if (i < n) i + 1 else if (cfg$has) cfg$entry else NA
      slow <- 1; fast <- 1
      steps <- list(list(slow = 1, fast = 1, phase = 1, msg = "Phase 1 — both pointers start at the head. Slow moves 1 node per step, fast moves 2."))
      met <- FALSE
      for (iter in 1:(4 * n)) {
        slow <- nxt(slow); fast <- nxt(nxt(fast))
        if (is.na(fast)) {
          steps[[length(steps) + 1]] <- list(slow = slow, fast = NA, phase = 1, end = "none",
            msg = "<b>Fast ran off the end (reached None) → the list has no cycle.</b>")
          break
        }
        if (slow == fast) {
          met <- TRUE
          steps[[length(steps) + 1]] <- list(slow = slow, fast = fast, phase = 1,
            msg = sprintf("<b>They meet at index %d after %d steps → a cycle exists.</b> Fast gained one node per step until it lapped slow.", slow - 1, iter))
          break
        }
        steps[[length(steps) + 1]] <- list(slow = slow, fast = fast, phase = 1,
          msg = sprintf("Step %d: slow → index %d, fast → index %d.", iter, slow - 1, fast - 1))
      }
      if (met) {
        slow <- 1
        steps[[length(steps) + 1]] <- list(slow = slow, fast = fast, phase = 2,
          msg = "Phase 2 — move <b>slow back to the head</b>; leave fast at the meeting point. Now both move 1 node per step.")
        while (slow != fast) {
          slow <- nxt(slow); fast <- nxt(fast)
          steps[[length(steps) + 1]] <- list(slow = slow, fast = fast, phase = 2,
            msg = sprintf("slow → index %d, fast → index %d.", slow - 1, fast - 1))
        }
        steps[[length(steps)]]$end <- "entry"
        steps[[length(steps)]]$msg <- sprintf("<b>They collide at index %d — that is the cycle entry.</b>", slow - 1)
      }
      steps
    })
    cy <- stepper_server(input, output, session, "cy", cy_steps)

    output$cy_plot <- renderPlotly({
      cfg <- cy_cfg(); n <- cfg$n; s <- cy$cur()
      if (cfg$has) {
        e <- cfg$entry; m <- n - e + 1; R <- max(1, m / 5)
        x <- numeric(n); y <- numeric(n)
        if (e > 1) { x[1:(e - 1)] <- 1:(e - 1) }
        ang <- pi - 2 * pi * (0:(m - 1)) / m
        x[e:n] <- e + R + R * cos(ang); y[e:n] <- R * sin(ang)
        nodes <- data.frame(x = x, y = y, label = 0:(n - 1))
        from <- 1:n; to <- c(sq(2, n), e)
      } else {
        nodes <- data.frame(x = 1:(n + 1), y = 0, label = c(0:(n - 1), "None"), stringsAsFactors = FALSE)
        from <- 1:n; to <- 2:(n + 1)
      }
      state <- rep("idle", nrow(nodes)); sub <- rep("", nrow(nodes))
      fpos <- if (is.na(s$fast)) (if (!cfg$has) n + 1 else NA) else s$fast
      spos <- s$slow
      if (!is.na(spos)) { state[spos] <- "done"; sub[spos] <- "slow" }
      if (!is.na(fpos)) {
        if (!is.na(spos) && spos == fpos) { state[fpos] <- "active"; sub[fpos] <- "slow · fast" }
        else { state[fpos] <- "path"; sub[fpos] <- "fast" }
      }
      nodes <- state_style(nodes, state); nodes$sub <- sub
      if (cfg$has) { is_e <- seq_len(n) == cfg$entry & state == "idle"; nodes$border[is_e] <- COL$pink }
      edges <- data.frame(x0 = nodes$x[from], y0 = nodes$y[from], x1 = nodes$x[to], y1 = nodes$y[to])
      net_plot(nodes, edges, directed = TRUE, size = 34, height = 300)
    })
    output$cy_explain <- renderUI(explain(cy$cur()$msg))
    output$cy_kpi <- renderUI({
      cfg <- cy_cfg()
      if (!cfg$has) return(kpi_row(kpi("—", "no cycle", COL$mute), kpi(cfg$n, "nodes", COL$pri)))
      kpi_row(kpi(cfg$entry - 1, "a: head → entry", COL$pink),
              kpi(cfg$n - cfg$entry + 1, "c: cycle length", COL$pri),
              kpi("O(1)", "extra space", COL$ok))
    })

    # ── Merge ────────────────────────────────────────────────────────────────
    mg_in <- reactive({
      a <- sort(parse_ints(input$mg_a, 8)); b <- sort(parse_ints(input$mg_b, 8))
      validate(need(length(a) + length(b) >= 1, "Enter values for at least one list."))
      list(a = a, b = b)
    })
    mg_steps <- reactive({
      a <- mg_in()$a; b <- mg_in()$b; i <- 1; j <- 1; out <- integer(0)
      steps <- list(list(i = 1, j = 1, out = out, msg = "A <code>dummy</code> node stands in front of the result so the first append needs no special case. Compare the two heads."))
      while (i <= length(a) && j <= length(b)) {
        if (a[i] <= b[j]) { out <- c(out, a[i]); msg <- sprintf("%d ≤ %d → take from <b>A</b>.", a[i], b[j]); i <- i + 1 }
        else { out <- c(out, b[j]); msg <- sprintf("%d &gt; %d → take from <b>B</b>.", a[i], b[j]); j <- j + 1 }
        steps[[length(steps) + 1]] <- list(i = i, j = j, out = out, msg = msg)
      }
      rest <- c(if (i <= length(a)) a[i:length(a)], if (j <= length(b)) b[j:length(b)])
      if (length(rest)) {
        out <- c(out, rest)
        steps[[length(steps) + 1]] <- list(i = length(a) + 1, j = length(b) + 1, out = out,
          msg = sprintf("One list is exhausted → attach the remaining %d node(s) in a single pointer assignment: <code>tail.next = a or b</code>.", length(rest)))
      }
      steps[[length(steps)]]$msg <- paste(steps[[length(steps)]]$msg, "<b>Return <code>dummy.next</code>.</b>")
      steps
    })
    mg <- stepper_server(input, output, session, "mg", mg_steps)
    output$mg_viz <- renderUI({
      a <- mg_in()$a; b <- mg_in()$b; s <- mg$cur()
      ca <- ifelse(seq_along(a) < s$i, "dim", ""); if (s$i <= length(a)) ca[s$i] <- "active"
      cb <- ifelse(seq_along(b) < s$j, "dim", ""); if (s$j <= length(b)) cb[s$j] <- "active"
      tagList(
        fluidRow(
          column(6, tags$div(class = "code-title", "List A"), vrow(a, ca, ptr = list(a = s$i), idx = FALSE, arrows = TRUE)),
          column(6, tags$div(class = "code-title", "List B"), vrow(b, cb, ptr = list(b = s$j), idx = FALSE, arrows = TRUE))
        ),
        lane("dummy → merged", s$out, "found", "nothing merged yet"),
        explain(s$msg)
      )
    })

    quiz_server(input, output, session, topic = "linkedlists", progress = progress, questions = list(
      list(q = "In iterative reversal, what goes wrong if you run <code>cur.next = prev</code> before saving <code>cur.next</code>?",
           opts = c("Nothing — order does not matter", "You lose the reference to the rest of the list", "The list becomes doubly linked", "prev becomes None"), ans = 2,
           why = "Overwriting cur.next destroys the only pointer to the unreversed remainder. Save it in nxt first."),
      list(q = "Floyd's algorithm: slow and fast meet inside a cycle. How do you find where the cycle begins?",
           opts = c("Count the nodes in the cycle and subtract", "Reset one pointer to head and advance both one step at a time until they meet", "Keep running fast until it reaches None", "Use a hash set of visited nodes"), ans = 2,
           why = "Distance head→entry equals distance meeting-point→entry (mod cycle length), so equal-speed pointers collide at the entry. O(1) space."),
      list(q = "What does a dummy head node buy you?",
           opts = c("Faster traversal", "No special case when the real head is inserted, removed or replaced", "Automatic cycle detection", "O(1) access by index"), ans = 2,
           why = "Every real node then has a predecessor, so head changes are handled by the same code as any other node."),
      list(q = "To remove the n-th node from the end in one pass you…",
           opts = c("Reverse the list first", "Advance a lead pointer n steps, then move lead and trail together", "Count the length, then walk again", "Use a stack of all nodes"), ans = 2,
           why = "Keeping a gap of n means that when the lead hits the end, the trail sits just before the node to remove. Counting first works but is two passes."),
      list(q = "Which operation is O(1) on a singly linked list but O(n) on an array?",
           opts = c("Access the k-th element", "Insert at the front", "Binary search", "Find the maximum"), ans = 2,
           why = "A front insert only rewires one pointer; an array must shift every element.")
    ))
  })
}
