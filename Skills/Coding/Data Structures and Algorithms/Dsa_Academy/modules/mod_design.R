# modules/mod_design.R — Iterators & Class Design: BST iterator, nested iterator, RandomizedSet, peeking iterator.

design_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🧩", "Iterators & Class Design",
      "'Design a class that supports…' questions test whether you can choose the state a class keeps so that every method meets its complexity target. Meta asks them often.",
      c("BST Iterator", "Nested Iterator", "Peeking Iterator", "RandomizedSet", "Lazy evaluation", "Amortised O(1)")),

    topic_tabs(ns,
      visual = tagList(
        fluidRow(
          box(title = "BST Iterator (#173) — an in-order traversal you can pause", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(6, textInput(ns("bi_vals"), "Insert values into a BST:", "7, 3, 15, 9, 20, 1, 5, 12")),
              column(6, stepper_ui(ns, "bi"))
            ),
            plotlyOutput(ns("bi_plot"), height = "320px"),
            uiOutput(ns("bi_viz"))
          ),
          box(title = "State = a stack of 'left spines'", status = "info", solidHeader = TRUE, width = 4,
            pseudo(c("def __init__(root):", "    self.st = []; push_left(root)", "def next():", "    node = self.st.pop()",
                     "    push_left(node.right)", "    return node.val", "def hasNext(): return bool(self.st)",
                     "def push_left(n):", "    while n: st.append(n); n = n.left")),
            uiOutput(ns("bi_kpi")),
            callout("Every node is pushed and popped exactly once, so n calls to <code>next()</code> cost O(n) in total — <b>amortised O(1)</b> each — using O(h) memory instead of O(n).", "tip"))
        ),
        fluidRow(
          box(title = "Flatten Nested List Iterator (#341) — lazy, stack-based", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(6, textInput(ns("ni_txt"), "Nested list (JSON):", "[[1,[2]],3,[[],[4,[5,6]]],7]")),
              column(6, stepper_ui(ns, "ni"))
            ),
            uiOutput(ns("ni_viz"))
          ),
          box(title = "Why hasNext() does the work", status = "info", solidHeader = TRUE, width = 4,
            pseudo(c("__init__: stack = reversed(nestedList)", "hasNext():", "    while stack and not stack[-1].isInteger():",
                     "        lst = stack.pop().getList()", "        stack.extend(reversed(lst))", "    return bool(stack)",
                     "next(): return stack.pop().getInteger()")),
            callout("Flattening everything in the constructor is fine in an interview, but the lazy version uses memory proportional to depth + width and handles empty lists like <code>[[]]</code> correctly.", "info"),
            callout("Push children in <b>reverse</b> so the first child ends on top of the stack.", "warn"))
        ),
        fluidRow(
          box(title = "Insert Delete GetRandom O(1) (#380) — array + hash map", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(7, textInput(ns("rz_ops"), "Operations (+x insert, -x remove, ? getRandom):", "+5, +9, +2, +7, -9, ?, +4, -5, ?, +2")),
              column(5, stepper_ui(ns, "rz"))
            ),
            uiOutput(ns("rz_viz"))
          ),
          box(title = "The swap-with-last trick", status = "info", solidHeader = TRUE, width = 4,
            dsa_code(
'def remove(self, val):
    if val not in self.pos:
        return False
    i, last = self.pos[val], self.arr[-1]
    self.arr[i] = last          # move last into the hole
    self.pos[last] = i
    self.arr.pop()
    del self.pos[val]
    return True', "O(1) delete"),
            callout("Arrays give O(1) random access (for getRandom) but O(n) delete; hash maps give O(1) delete but no random access. Keeping <b>both</b> — and the index of each value — gives O(1) for all three.", "tip"))
        )
      ),

      learn = tagList(
        insight_cards(
          when = c("'Implement an iterator' → keep exactly the state needed to produce the next element (stack, index, buffered value).",
                   "'All operations in O(1)' → combine structures: hash map + array, hash map + doubly linked list (LRU).",
                   "'peek' or 'hasNext' must not consume → cache one element ahead.",
                   "Streams or huge inputs → lazy generation instead of precomputing everything."),
          pitfalls = c("Doing work in <code>next()</code> that <code>hasNext()</code> also needs, and calling it twice — make <code>hasNext()</code> idempotent.",
                       "Removing from the middle of a Python list (<code>list.remove</code>) — O(n).",
                       "Forgetting to update the moved element's index after swap-with-last.",
                       "Returning a shared mutable list from a getter, so callers can corrupt internal state."),
          tips = c("Start by listing the methods with their target complexity, then pick the state.",
                   "State the invariant of the class: 'the top of the stack is always the next value'.",
                   "Walk through a small sequence of calls on the whiteboard, including edge cases like an empty structure.")
        ),
        fluidRow(
          box(title = "Classic design problems", status = "info", solidHeader = TRUE, width = 7,
            cplx_table(data.frame(
              Problem = c("BST Iterator", "Nested List Iterator", "Peeking Iterator", "Zigzag Iterator", "RandomizedSet", "LRU Cache", "Min Stack", "Snapshot Array", "Time-based KV store"),
              State = c("stack of left spine", "stack of iterators / items", "one cached item", "queue of iterators", "array + value→index map", "hash map + DLL (OrderedDict)", "stack of (val, min)", "per-index list of (snap, val)", "map key → sorted (t, v) list"),
              Cost = c("amortised O(1), O(h) space", "amortised O(1)", "O(1)", "O(1)", "O(1) all", "O(1) get / put", "O(1) all", "O(log s) get", "O(log n) get"),
              stringsAsFactors = FALSE))),
          box(title = "Checklist before you code a class", status = "info", solidHeader = TRUE, width = 5,
            tags$ol(
              tags$li("Write each method signature with its required complexity."),
              tags$li("Ask: what's the input range? Duplicates allowed? Thread safety?"),
              tags$li("Choose state; say the invariant that links the fields."),
              tags$li("Trace 5–6 calls, including an empty or exhausted state."),
              tags$li("Mention extensions: generics, iterator protocol (__iter__/__next__), concurrency.")))
        ),
        fluidRow(
          box(title = "Templates worth memorising (Python)", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(4, dsa_code(
'class PeekingIterator:             # 284
    def __init__(self, it):
        self.it = it
        self.buf = it.next() if it.hasNext() else None
    def peek(self):
        return self.buf
    def next(self):
        v = self.buf
        self.buf = self.it.next() if self.it.hasNext() else None
        return v
    def hasNext(self):
        return self.buf is not None', "Peeking iterator (values never None)")),
              column(4, dsa_code(
'import collections

class ZigzagIterator:              # 281
    def __init__(self, v1, v2):
        self.q = collections.deque(
            (v, 0) for v in (v1, v2) if v)
    def next(self):
        v, i = self.q.popleft()
        if i + 1 < len(v):
            self.q.append((v, i + 1))
        return v[i]
    def hasNext(self):
        return bool(self.q)', "Round-robin iterator")),
              column(4, dsa_code(
'def inorder(root):                # Python generator —
    if root:                       # the iterator protocol
        yield from inorder(root.left)
        yield root.val
        yield from inorder(root.right)

class BSTIterator:
    def __init__(self, root):
        self.g = inorder(root)
        self.nxt = next(self.g, None)
    def next(self):
        v, self.nxt = self.nxt, next(self.g, None)
        return v
    def hasNext(self):
        return self.nxt is not None', "Generators as iterators")))
          )
        )
      ),

      practice = practice_tab(ns, "design",
        "Gamma, Helm, Johnson & Vlissides (1994). Design Patterns — the Iterator pattern. Addison-Wesley.",
        "Python Software Foundation (2024). Iterator types and generators. docs.python.org/3/library/stdtypes.html#iterator-types.",
        "Laakmann McDowell (2015). Cracking the Coding Interview (6th ed.) — object-oriented design.")
    )
  )
}

design_server <- function(id, progress = NULL) {
  moduleServer(id, function(input, output, session) {

    # ── BST iterator ─────────────────────────────────────────────────────────
    bi_tree <- reactive({
      v <- unique(parse_ints(input$bi_vals))
      validate(need(length(v) >= 2, "Enter at least two distinct integers."))
      bst_build(head(v, 15))
    })
    bi_steps <- reactive({
      t <- bi_tree(); st <- list(); out <- c(); steps <- list(); pushes <- 0
      push_left <- function(n) while (!is.null(n)) { st[[length(st) + 1]] <<- n; pushes <<- pushes + 1; n <- n$left }
      vals_of <- function() vapply(st, function(n) n$val, 0)
      push_left(t)
      steps[[1]] <- list(st = vals_of(), out = out, cur = NA, pushes = pushes, line = 1:2,
                         msg = sprintf("Constructor pushes the left spine from the root: %s. The top of the stack is the smallest value.", paste(vals_of(), collapse = " → ")))
      while (length(st)) {
        node <- st[[length(st)]]; st[[length(st)]] <- NULL
        out <- c(out, node$val); before <- pushes
        push_left(node$right)
        steps[[length(steps) + 1]] <- list(st = vals_of(), out = out, cur = node$val, pushes = pushes, line = 3:6,
          msg = sprintf("next(): pop <b>%g</b> and return it. %s", node$val,
                        if (pushes > before) sprintf("Its right subtree exists → push that subtree's left spine (%d node%s).", pushes - before, if (pushes - before > 1) "s" else "")
                        else "No right child → nothing to push."))
      }
      steps[[length(steps) + 1]] <- list(st = numeric(0), out = out, cur = NA, pushes = pushes, line = 7,
        msg = sprintf("hasNext() → False. %d calls to next() did %d pushes in total — exactly one per node.", length(out), pushes))
      steps
    })
    bi <- stepper_server(input, output, session, "bi", bi_steps, speed = 800)
    output$bi_plot <- renderPlotly({
      L <- tree_layout(bi_tree()); s <- bi$cur(); nd <- L$nodes
      stt <- ifelse(nd$label %in% s$out, "done", ifelse(nd$label %in% s$st, "frontier", "idle"))
      if (!is.na(s$cur)) stt[nd$label == s$cur] <- "active"
      net_plot(state_style(nd, stt), L$edges, size = 34, height = 320)
    })
    output$bi_viz <- renderUI({
      s <- bi$cur()
      tagList(lane("stack (top →)", s$st, "frontier", "empty"), lane("returned", s$out, "found", "none yet"), explain(s$msg))
    })
    output$bi_kpi <- renderUI({
      s <- bi$cur()
      kpi_row(kpi(length(s$st), "stack size now"), kpi(length(s$out), "next() calls", COL$ok), kpi(s$pushes, "total pushes", COL$warn))
    })

    # ── Nested iterator ──────────────────────────────────────────────────────
    ni_list <- reactive({
      x <- tryCatch(jsonlite::fromJSON(input$ni_txt %||% "[]", simplifyVector = FALSE), error = function(e) NULL)
      validate(need(is.list(x), "Enter a JSON list such as [[1,[2]],3]."))
      x
    })
    show_item <- function(x) if (is.list(x)) as.character(jsonlite::toJSON(x, auto_unbox = TRUE)) else as.character(x)
    ni_steps <- reactive({
      st <- rev(ni_list()); out <- c(); steps <- list(list(st = st, out = out, msg = "Constructor: push the top-level items in reverse so the first item is on top.", hl = "init"))
      guard <- 0
      repeat {
        guard <- guard + 1; if (guard > 200) break
        while (length(st) && is.list(st[[length(st)]])) {
          top <- st[[length(st)]]; st[[length(st)]] <- NULL
          st <- c(st, rev(top))
          steps[[length(steps) + 1]] <- list(st = st, out = out, hl = "expand",
            msg = sprintf("hasNext(): top is the list %s → pop it and push its %d element%s in reverse.", show_item(top), length(top), if (length(top) == 1) "" else "s"))
        }
        if (!length(st)) break
        v <- st[[length(st)]]; st[[length(st)]] <- NULL; out <- c(out, v)
        steps[[length(steps) + 1]] <- list(st = st, out = out, hl = "next", msg = sprintf("hasNext() → True (top is an integer). next() pops and returns <b>%s</b>.", v))
      }
      steps[[length(steps) + 1]] <- list(st = st, out = out, hl = "done", msg = sprintf("Stack empty → hasNext() is False. Flattened: [%s].", paste(out, collapse = ", ")))
      steps
    })
    ni <- stepper_server(input, output, session, "ni", ni_steps, speed = 800)
    output$ni_viz <- renderUI({
      s <- ni$cur(); labs <- vapply(s$st, show_item, "")
      cls <- ifelse(vapply(s$st, is.list, TRUE), "frontier", ""); if (length(cls)) cls[length(cls)] <- paste(cls[length(cls)], "active")
      tagList(tags$div(class = "code-title", "stack (bottom → top)"), vrow(labs, cls, idx = FALSE, wide = TRUE),
              lane("returned", s$out, "found", "none yet"), explain(s$msg))
    })

    # ── RandomizedSet ────────────────────────────────────────────────────────
    rz_steps <- reactive({
      tok <- trimws(strsplit(input$rz_ops %||% "", ",")[[1]]); tok <- tok[grepl("^([+-]-?\\d+|\\?)$", tok)]
      validate(need(length(tok) >= 1, "Enter operations like +5, -5, ?"))
      arr <- numeric(0); pos <- list(); set.seed(5)
      steps <- list(list(arr = arr, pos = pos, hi = NA, hole = NA, msg = "Empty set: arr = [], pos = {}.", ret = ""))
      for (t in head(tok, 20)) {
        if (t == "?") {
          if (!length(arr)) { steps[[length(steps) + 1]] <- list(arr = arr, pos = pos, hi = NA, hole = NA, ret = "—", msg = "getRandom() on an empty set (LeetCode guarantees this never happens)."); next }
          k <- sample.int(length(arr), 1)
          steps[[length(steps) + 1]] <- list(arr = arr, pos = pos, hi = k, hole = NA, ret = arr[k],
            msg = sprintf("getRandom(): pick index randint(0, %d) = %d → return <b>%g</b>. Each value has probability 1/%d.", length(arr) - 1, k - 1, arr[k], length(arr)))
        } else {
          x <- as.numeric(substring(t, 2)); key <- as.character(x)
          if (substr(t, 1, 1) == "+") {
            if (!is.null(pos[[key]])) { steps[[length(steps) + 1]] <- list(arr = arr, pos = pos, hi = pos[[key]], hole = NA, ret = "False", msg = sprintf("insert(%g): already in pos → return False, O(1).", x)); next }
            arr <- c(arr, x); pos[[key]] <- length(arr)
            steps[[length(steps) + 1]] <- list(arr = arr, pos = pos, hi = length(arr), hole = NA, ret = "True", msg = sprintf("insert(%g): append at index %d and record pos[%g] = %d → True.", x, length(arr) - 1, x, length(arr) - 1))
          } else {
            if (is.null(pos[[key]])) { steps[[length(steps) + 1]] <- list(arr = arr, pos = pos, hi = NA, hole = NA, ret = "False", msg = sprintf("remove(%g): not in pos → return False.", x)); next }
            i <- pos[[key]]; last <- arr[length(arr)]
            steps[[length(steps) + 1]] <- list(arr = arr, pos = pos, hi = length(arr), hole = i, ret = "",
              msg = sprintf("remove(%g): it sits at index %d. Move the last value %g into that slot…", x, i - 1, last))
            arr[i] <- last; pos[[as.character(last)]] <- i; arr <- arr[-length(arr)]; pos[[key]] <- NULL
            steps[[length(steps) + 1]] <- list(arr = arr, pos = pos, hi = if (i <= length(arr)) i else NA, hole = NA, ret = "True",
              msg = sprintf("…update pos[%g] = %d, pop the tail and delete pos[%g] → True. No shifting, O(1).", last, i - 1, x))
          }
        }
      }
      steps
    })
    rz <- stepper_server(input, output, session, "rz", rz_steps, speed = 900)
    output$rz_viz <- renderUI({
      s <- rz$cur(); n <- length(s$arr); cls <- rep("", n)
      if (!is.na(s$hole) && s$hole <= n) cls[s$hole] <- "bad"
      if (!is.na(s$hi) && s$hi <= n) cls[s$hi] <- "active"
      pm <- if (length(s$pos)) paste0(names(s$pos), " → ", vapply(s$pos, function(v) v - 1, 0)) else character(0)
      tagList(tags$div(class = "code-title", "arr"), vrow(s$arr, cls),
              lane("pos {value → index}", pm, "visited", "{}"),
              if (nzchar(s$ret)) lane("returned", s$ret, "found"),
              explain(s$msg))
    })

    quiz_server(input, output, session, topic = "design", progress = progress, questions = list(
      list(q = "BSTIterator.next() is O(1) amortised because…", opts = c("The tree is balanced", "Each node is pushed and popped exactly once over all calls", "It precomputes the whole traversal", "Stacks are O(1)"), ans = 2,
           why = "n calls do n pushes and n pops in total, even though one call may push h nodes."),
      list(q = "Extra memory used by the stack-based BST iterator is…", opts = c("O(1)", "O(h)", "O(n)", "O(n log n)"), ans = 2,
           why = "At any time the stack holds at most one root-to-leaf path."),
      list(q = "RandomizedSet.remove(x) is O(1) because…", opts = c("Python lists delete in O(1)", "x is swapped with the last element and the tail is popped", "Values are kept sorted", "The set is a linked list"), ans = 2,
           why = "Popping the last element is O(1); the hash map tells us where x is and is updated for the moved value."),
      list(q = "In the lazy nested iterator, where should the flattening of lists happen?", opts = c("In next() only", "In hasNext(), until an integer is on top", "In the constructor only", "Never"), ans = 2,
           why = "hasNext() must know whether another integer exists — [[]] contains none — so it expands lists until an integer is on top."),
      list(q = "A PeekingIterator must…", opts = c("Copy the whole input", "Cache the next element so peek() does not advance", "Call next() twice", "Use recursion"), ans = 2,
           why = "Buffering one element lets peek() return it repeatedly and next() return then refill it.")
    ))
  })
}
