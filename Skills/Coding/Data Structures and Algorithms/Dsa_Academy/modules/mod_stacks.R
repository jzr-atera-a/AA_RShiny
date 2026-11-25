# modules/mod_stacks.R — Stacks & Queues

stacks_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("📚", "Stacks & Queues",
      "Two restricted lists: a stack serves the newest item first (LIFO), a queue the oldest (FIFO). Stacks power parsing, undo and DFS; queues power BFS and scheduling. The monotonic stack turns many O(n²) scans into O(n).",
      c("LIFO", "FIFO", "Matching Brackets", "Monotonic Stack", "Postfix Evaluation")),

    topic_tabs(ns,
      visual = tagList(
        fluidRow(
          box(title = "Playground — push and pop yourself", status = "primary", solidHeader = TRUE, width = 4,
            radioButtons(ns("ds_type"), NULL, choices = c("Stack (LIFO)" = "stack", "Queue (FIFO)" = "queue"), inline = TRUE),
            textInput(ns("push_val"), "Value:", "42"),
            tags$div(class = "stepper-btns",
              actionButton(ns("btn_push"), "Push / Enqueue", class = "btn btn-dsa btn-sm"),
              actionButton(ns("btn_pop"), "Pop / Dequeue", class = "btn btn-dsa-outline btn-sm"),
              actionButton(ns("btn_clear"), "Clear", class = "btn btn-dsa-outline btn-sm")),
            uiOutput(ns("ds_viz")),
            uiOutput(ns("ds_log"))
          ),
          box(title = "Bracket Matching — the classic stack problem", status = "primary", solidHeader = TRUE, width = 8,
            textInput(ns("par_str"), "Expression:", "{[(a+b)*c]-(d/e)}"),
            stepper_ui(ns, "par"),
            uiOutput(ns("par_viz")),
            legend_row(c("current character" = COL$pri, "processed" = "#e2e8f0", "mismatch" = COL$err))
          )
        ),
        fluidRow(
          box(title = "Monotonic Stack — next greater element in O(n)", status = "primary", solidHeader = TRUE, width = 8,
            textInput(ns("mono_arr"), "Values (e.g. daily temperatures):", "73,74,75,71,69,72,76,73"),
            stepper_ui(ns, "mono"),
            plotlyOutput(ns("mono_plot"), height = "240px"),
            uiOutput(ns("mono_viz")),
            legend_row(c("current" = COL$pri, "waiting on stack" = COL$warn, "answer found" = COL$ok, "not reached" = COL$idle))
          ),
          box(title = "Why it is O(n)", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("mono_kpi")),
            callout("The stack holds indices still <b>waiting</b> for a bigger value, in decreasing order of value. A new value resolves every smaller item on top in one sweep.<br><br>The nested <code>while</code> looks quadratic, but each index is pushed once and popped at most once → at most <b>2n</b> stack operations in total.", "tip"),
            uiOutput(ns("mono_code"))
          )
        ),
        fluidRow(
          box(title = "Postfix (RPN) Evaluator", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(5, textInput(ns("rpn_str"), "Tokens (space separated):", "3 4 + 2 * 7 -")),
              column(7, stepper_ui(ns, "rpn"))
            ),
            uiOutput(ns("rpn_viz"))
          )
        ),
        fluidRow(
          box(title = "Basic Calculator II (#227) — one stack, operator precedence without parentheses", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(5, textInput(ns("calc_str"), "Expression (+ − * /, integers):", "3+2*2 - 14/3*2 + 7")),
              column(7, stepper_ui(ns, "calc"))
            ),
            uiOutput(ns("calc_viz"))
          ),
          box(title = "The trick: apply * and / immediately", status = "info", solidHeader = TRUE, width = 4,
            dsa_code(
'def calculate(s):
    st, num, op = [], 0, "+"
    for i, ch in enumerate(s + "+"):
        if ch.isdigit():
            num = num * 10 + int(ch)
        elif ch in "+-*/":
            if op == "+": st.append(num)
            elif op == "-": st.append(-num)
            elif op == "*": st.append(st.pop() * num)
            else: st.append(int(st.pop() / num))  # truncate to 0
            num, op = 0, ch
    return sum(st)', "Basic Calculator II"),
            callout("Each number is pushed with the operator <b>before</b> it. + and − just push (signed); * and / combine with the top right away, so the stack only ever holds terms to be added at the end.", "tip"),
            callout("Python's <code>//</code> floors (−7 // 2 = −4) but the problem truncates towards zero: use <code>int(a / b)</code>.", "warn"))
        )
      ),

      learn = tagList(
        insight_cards(
          when = c("Something must be matched with its <b>most recent</b> unmatched partner → stack.",
                   "'Next greater / smaller', 'days until warmer', histogram areas → monotonic stack.",
                   "Process things in arrival order or <b>level by level</b> → queue (BFS).",
                   "Sliding-window maximum / minimum → monotonic deque."),
          pitfalls = c("Popping from an empty stack — always check before <code>pop()</code> or <code>stack[-1]</code>.",
                       "Using a Python list as a queue: <code>pop(0)</code> is O(n). Use <code>collections.deque</code>.",
                       "Storing values on a monotonic stack when you need distances — store <b>indices</b>.",
                       "Forgetting leftovers: unmatched openers still on the stack mean 'invalid'."),
          tips = c("Say the invariant: 'the stack is always decreasing from bottom to top'.",
                   "Recursion uses the call stack — any recursive DFS can be rewritten with an explicit stack.",
                   "Justify O(n) with the amortised argument: every element is pushed and popped at most once.")
        ),
        fluidRow(
          box(title = "Operation Costs", status = "info", solidHeader = TRUE, width = 5,
            cplx_table(data.frame(
              Operation = c("Push / enqueue", "Pop / dequeue", "Peek", "Search", "Min in O(1)?"),
              Stack = c("O(1)", "O(1)", "O(1)", "O(n)", "Yes — keep a second stack of minima"),
              Queue = c("O(1)", "O(1)", "O(1)", "O(n)", "Yes — monotonic deque"),
              stringsAsFactors = FALSE)),
            callout("<b>Queue from two stacks:</b> push to <code>in</code>; when <code>out</code> is empty, pour everything from <code>in</code> to <code>out</code>. Each element moves at most twice → O(1) amortised.", "info")
          ),
          box(title = "Where each structure shows up", status = "info", solidHeader = TRUE, width = 7,
            cplx_table(data.frame(
              Structure = c("Stack", "Stack", "Monotonic stack", "Queue", "Deque", "Priority queue"),
              Use = c("Function calls, undo, backtracking, DFS", "Expression parsing and evaluation",
                      "Next greater element, largest rectangle, trapping rain water",
                      "BFS, task scheduling, rate limiting", "Sliding window max, 0-1 BFS", "Dijkstra, top-K, event simulation"),
              Python = c("list", "list", "list of indices", "collections.deque", "collections.deque", "heapq"),
              stringsAsFactors = FALSE))
          )
        ),
        fluidRow(
          box(title = "Templates worth memorising (Python)", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(4, dsa_code(
'def isValid(s):
    pairs = {")": "(", "]": "[", "}": "{"}
    stack = []
    for ch in s:
        if ch in pairs:                  # closer
            if not stack or stack.pop() != pairs[ch]:
                return False
        else:                            # opener
            stack.append(ch)
    return not stack', "Valid parentheses — O(n)")),
              column(4, dsa_code(
'def dailyTemperatures(t):
    res = [0] * len(t)
    stack = []                 # indices, temps decreasing
    for i, x in enumerate(t):
        while stack and t[stack[-1]] < x:
            j = stack.pop()
            res[j] = i - j     # days waited
        stack.append(i)
    return res', "Monotonic stack — O(n)")),
              column(4, dsa_code(
'class MinStack:
    def __init__(self):
        self.st, self.mins = [], []
    def push(self, x):
        self.st.append(x)
        m = x if not self.mins else min(x, self.mins[-1])
        self.mins.append(m)
    def pop(self):
        self.st.pop(); self.mins.pop()
    def getMin(self):
        return self.mins[-1]', "Min stack — every op O(1)"))
            )
          )
        )
      ),

      practice = practice_tab(ns, "stacks",
        "Cormen, Leiserson, Rivest & Stein (2022). Introduction to Algorithms (4th ed.) — §10.1 stacks and queues.",
        "Dijkstra, E. W. (1961). The shunting-yard algorithm — converting infix to postfix with a stack.",
        "Weiss, M. A. (2011). Data Structures and Algorithm Analysis in Java (3rd ed.). Pearson.")
    )
  )
}

stacks_server <- function(id, progress = NULL) {
  moduleServer(id, function(input, output, session) {

    # ── Playground ───────────────────────────────────────────────────────────
    ds <- reactiveValues(items = c("7", "19", "3"), log = "Three items preloaded — try Pop.")
    observeEvent(input$btn_push, {
      v <- trimws(input$push_val); req(nzchar(v))
      if (length(ds$items) >= 8) { ds$log <- "Capacity reached for this demo (8 items)."; return() }
      ds$items <- c(ds$items, v)
      ds$log <- sprintf("Added <b>%s</b> at the %s.", v, if (input$ds_type == "stack") "top" else "back")
    })
    observeEvent(input$btn_pop, {
      n <- length(ds$items)
      if (n == 0) { ds$log <- "Nothing to remove — the structure is empty (underflow)."; return() }
      if (input$ds_type == "stack") {
        ds$log <- sprintf("Popped <b>%s</b> — the <b>most recently</b> added item leaves first.", ds$items[n])
        ds$items <- ds$items[-n]
      } else {
        ds$log <- sprintf("Dequeued <b>%s</b> — the <b>oldest</b> item leaves first.", ds$items[1])
        ds$items <- ds$items[-1]
      }
    })
    observeEvent(input$btn_clear, { ds$items <- character(0); ds$log <- "Cleared." })
    output$ds_viz <- renderUI({
      items <- ds$items; n <- length(items); stack <- input$ds_type == "stack"
      if (n == 0) return(tags$div(class = "vrow", style = "margin-top:10px;", tags$span(class = "vempty", "empty")))
      if (stack) {
        tags$div(class = "vrow", style = "flex-direction:column; align-items:center; margin-top:10px; gap:3px;",
          lapply(rev(seq_len(n)), function(i)
            tags$div(style = "display:flex; align-items:center; gap:8px;",
              tags$span(class = "vptr", style = "min-width:44px; text-align:right;", if (i == n) "top →" else ""),
              tags$div(class = paste("vnode wide", if (i == n) "active"), style = "min-width:90px;", items[i]))))
      } else {
        tags$div(style = "margin-top:10px;",
          vrow(items, c("active", rep("", n - 1)), ptr = setNames(list(1, n), c("front", "back")), idx = FALSE, arrows = TRUE, wide = TRUE))
      }
    })
    output$ds_log <- renderUI(explain(ds$log))

    # ── Bracket matching ─────────────────────────────────────────────────────
    par_steps <- reactive({
      s <- input$par_str %||% ""
      validate(need(nzchar(s), "Type an expression containing brackets."), need(nchar(s) <= 28, "Keep it to 28 characters or fewer."))
      ch <- strsplit(s, "")[[1]]
      open <- c("(", "[", "{"); close <- c(")" = "(", "]" = "[", "}" = "{")
      stk <- character(0)
      steps <- list(list(i = 0, stack = stk, bad = FALSE, msg = "Scan left to right. Openers are pushed; each closer must match the opener on <b>top</b> of the stack."))
      ok <- TRUE
      for (i in seq_along(ch)) {
        c1 <- ch[i]
        if (c1 %in% open) {
          stk <- c(stk, c1)
          steps[[length(steps) + 1]] <- list(i = i, stack = stk, bad = FALSE, msg = sprintf("<code>%s</code> is an opener → <b>push</b>.", c1))
        } else if (c1 %in% names(close)) {
          if (length(stk) == 0) {
            steps[[length(steps) + 1]] <- list(i = i, stack = stk, bad = TRUE, msg = sprintf("<code>%s</code> closes nothing — the stack is empty. <b>Invalid.</b>", c1)); ok <- FALSE; break
          } else if (stk[length(stk)] != close[[c1]]) {
            steps[[length(steps) + 1]] <- list(i = i, stack = stk, bad = TRUE, msg = sprintf("<code>%s</code> expects <code>%s</code> on top but found <code>%s</code>. <b>Invalid.</b>", c1, close[[c1]], stk[length(stk)])); ok <- FALSE; break
          } else {
            top <- stk[length(stk)]; stk <- stk[-length(stk)]
            steps[[length(steps) + 1]] <- list(i = i, stack = stk, bad = FALSE, msg = sprintf("<code>%s</code> matches <code>%s</code> on top → <b>pop</b>.", c1, top))
          }
        } else {
          steps[[length(steps) + 1]] <- list(i = i, stack = stk, bad = FALSE, msg = sprintf("<code>%s</code> is not a bracket → skip.", c1))
        }
      }
      if (ok) steps[[length(steps) + 1]] <- list(i = length(ch) + 1, stack = stk, bad = length(stk) > 0,
        msg = if (length(stk) == 0) "End of input and the stack is empty → <b>every bracket was matched. Valid ✅</b>"
              else sprintf("End of input but %d opener(s) are still waiting on the stack → <b>Invalid.</b>", length(stk)))
      list(ch = ch, steps = steps)
    })
    par <- stepper_server(input, output, session, "par", reactive(par_steps()$steps))
    output$par_viz <- renderUI({
      ch <- par_steps()$ch; s <- par$cur()
      cls <- ifelse(seq_along(ch) < s$i, "dim", "")
      if (s$i >= 1 && s$i <= length(ch)) cls[s$i] <- if (s$bad) "bad" else "active"
      tagList(vrow(ch, cls, idx = FALSE),
              lane("stack (top →)", s$stack, if (s$bad) "bad" else "frontier", "empty"),
              explain(s$msg))
    })

    # ── Monotonic stack ──────────────────────────────────────────────────────
    mono_arr <- reactive({
      v <- parse_ints(input$mono_arr, 16)
      validate(need(length(v) >= 2, "Enter at least two integers."))
      v
    })
    mono_steps <- reactive({
      a <- mono_arr(); n <- length(a); res <- rep(0L, n); stk <- integer(0); ops <- 0
      steps <- list(list(i = 0, stack = stk, res = res, done = logical(n), ops = 0, line = 1,
        msg = "The stack will hold <b>indices whose answer is still unknown</b>. Their values always decrease from bottom to top."))
      done <- logical(n)
      for (i in seq_len(n)) {
        while (length(stk) > 0 && a[stk[length(stk)]] < a[i]) {
          j <- stk[length(stk)]; stk <- stk[-length(stk)]; res[j] <- i - j; done[j] <- TRUE; ops <- ops + 1
          steps[[length(steps) + 1]] <- list(i = i, stack = stk, res = res, done = done, ops = ops, line = 4:6,
            msg = sprintf("%d (index %d) is bigger than %d on top (index %d) → <b>pop</b>. Answer for index %d = %d − %d = <b>%d</b>.",
                          a[i], i - 1, a[j], j - 1, j - 1, i - 1, j - 1, i - j))
        }
        stk <- c(stk, i); ops <- ops + 1
        steps[[length(steps) + 1]] <- list(i = i, stack = stk, res = res, done = done, ops = ops, line = 7,
          msg = sprintf("Nothing smaller left on top → <b>push</b> index %d (value %d). It now waits for a bigger value.", i - 1, a[i]))
      }
      steps[[length(steps) + 1]] <- list(i = n + 1, stack = stk, res = res, done = done, ops = ops, line = 8,
        msg = sprintf("Input exhausted. %d index(es) left on the stack never saw a bigger value → their answer stays <b>0</b>.", length(stk)))
      steps
    })
    mono <- stepper_server(input, output, session, "mono", mono_steps)
    output$mono_plot <- renderPlotly({
      a <- mono_arr(); s <- mono$cur(); n <- length(a)
      cols <- rep(COL$idle, n)
      cols[s$done] <- COL$ok
      cols[s$stack] <- COL$warn
      if (s$i >= 1 && s$i <= n) cols[s$i] <- COL$pri
      bar_state(a, cols, height = 240) %>% layout(yaxis = list(range = c(min(a) - 3, max(a) + 2)))
    })
    output$mono_viz <- renderUI({
      a <- mono_arr(); s <- mono$cur()
      tagList(
        lane("stack (idx:val)", if (length(s$stack)) paste0(s$stack - 1, ":", a[s$stack]) else character(0), "frontier", "empty"),
        lane("answer", s$res, "found"),
        explain(s$msg))
    })
    output$mono_kpi <- renderUI({
      n <- length(mono_arr()); s <- mono$cur()
      kpi_row(kpi(s$ops, "stack ops so far", COL$pri), kpi(2 * n, "upper bound 2n", COL$ok), kpi(n * (n - 1) / 2, "brute-force pairs", COL$err))
    })
    output$mono_code <- renderUI({
      pseudo(c("res, stack = [0]*n, []", "for i, x in enumerate(a):", "    # resolve everything smaller",
               "    while stack and a[stack[-1]] < x:", "        j = stack.pop()", "        res[j] = i - j",
               "    stack.append(i)", "return res"), active = mono$cur()$line)
    })

    # ── RPN ──────────────────────────────────────────────────────────────────
    rpn_steps <- reactive({
      tok <- strsplit(trimws(input$rpn_str %||% ""), "\\s+")[[1]]
      tok <- tok[nzchar(tok)]
      validate(need(length(tok) >= 1, "Enter tokens such as: 3 4 + 2 *"), need(length(tok) <= 20, "Use at most 20 tokens."))
      stk <- numeric(0)
      steps <- list(list(i = 0, stack = stk, bad = FALSE, msg = "Numbers are pushed. An operator pops the top two values, applies itself, and pushes the result."))
      for (i in seq_along(tok)) {
        t <- tok[i]
        if (t %in% c("+", "-", "*", "/")) {
          if (length(stk) < 2) {
            steps[[length(steps) + 1]] <- list(i = i, stack = stk, bad = TRUE, msg = sprintf("Operator <code>%s</code> needs two operands but the stack has %d. <b>Malformed expression.</b>", t, length(stk)))
            return(list(tok = tok, steps = steps))
          }
          b <- stk[length(stk)]; a <- stk[length(stk) - 1]; stk <- stk[seq_len(length(stk) - 2)]
          r <- switch(t, "+" = a + b, "-" = a - b, "*" = a * b, "/" = if (b == 0) NA else trunc(a / b))
          if (is.na(r)) {
            steps[[length(steps) + 1]] <- list(i = i, stack = stk, bad = TRUE, msg = "Division by zero.")
            return(list(tok = tok, steps = steps))
          }
          stk <- c(stk, r)
          steps[[length(steps) + 1]] <- list(i = i, stack = stk, bad = FALSE,
            msg = sprintf("Operator <code>%s</code>: pop %s and %s, compute %s %s %s = <b>%s</b>, push it. Note the order — the <b>second</b> pop is the left operand.", t, b, a, a, t, b, r))
        } else {
          v <- suppressWarnings(as.numeric(t))
          if (is.na(v)) {
            steps[[length(steps) + 1]] <- list(i = i, stack = stk, bad = TRUE, msg = sprintf("<code>%s</code> is neither a number nor one of + - * /.", t))
            return(list(tok = tok, steps = steps))
          }
          stk <- c(stk, v)
          steps[[length(steps) + 1]] <- list(i = i, stack = stk, bad = FALSE, msg = sprintf("<code>%s</code> is a number → push.", t))
        }
      }
      steps[[length(steps) + 1]] <- list(i = length(tok) + 1, stack = stk, bad = length(stk) != 1,
        msg = if (length(stk) == 1) sprintf("All tokens consumed; one value remains → <b>result = %s</b>.", stk) else "Tokens consumed but the stack does not hold exactly one value → <b>malformed expression.</b>")
      list(tok = tok, steps = steps)
    })
    rpn <- stepper_server(input, output, session, "rpn", reactive(rpn_steps()$steps))
    output$rpn_viz <- renderUI({
      tok <- rpn_steps()$tok; s <- rpn$cur()
      cls <- ifelse(seq_along(tok) < s$i, "dim", "")
      if (s$i >= 1 && s$i <= length(tok)) cls[s$i] <- if (s$bad) "bad" else "active"
      tagList(vrow(tok, cls, idx = FALSE, wide = TRUE),
              lane("stack (top →)", s$stack, if (s$bad) "bad" else "frontier", "empty"),
              explain(s$msg))
    })

    # ── Basic Calculator II ──────────────────────────────────────────────────
    calc_steps <- reactive({
      txt <- gsub("\\s+", "", input$calc_str %||% "")
      validate(need(grepl("^[0-9+*/-]+$", txt) && grepl("^[0-9]", txt) && grepl("[0-9]$", txt),
                    "Use non-negative integers and + - * / only, e.g. 3+2*2."))
      tok <- regmatches(txt, gregexpr("[0-9]+|[+*/-]", txt))[[1]]
      tok <- head(tok, 25)
      if (!grepl("^[0-9]+$", tok[length(tok)])) tok <- tok[-length(tok)]
      st <- numeric(0); op <- "+"; steps <- list(list(st = st, k = 0, op = op, msg = "Start with an empty stack and a pretend '+' in front of the first number.", tok = tok))
      for (k in seq_along(tok)) {
        t <- tok[k]
        if (grepl("^[0-9]+$", t)) {
          num <- as.numeric(t)
          msg <- switch(op,
            "+" = { st <- c(st, num); sprintf("Number %g after '+' → push %g.", num, num) },
            "-" = { st <- c(st, -num); sprintf("Number %g after '−' → push −%g (subtraction = adding a negative).", num, num) },
            "*" = { top <- st[length(st)]; st[length(st)] <- top * num; sprintf("Number %g after '*' → pop %g, push %g × %g = <b>%g</b> (higher precedence, done now).", num, top, top, num, top * num) },
            "/" = { top <- st[length(st)]; validate(need(num != 0, "Division by zero.")); v <- trunc(top / num); st[length(st)] <- v
                    sprintf("Number %g after '/' → pop %g, push trunc(%g / %g) = <b>%g</b>.", num, top, top, num, v) })
        } else { op <- t; msg <- sprintf("Operator '%s' — remember it for the next number.", t) }
        steps[[length(steps) + 1]] <- list(st = st, k = k, op = op, msg = msg, tok = tok)
      }
      steps[[length(steps) + 1]] <- list(st = st, k = length(tok) + 1, op = op, tok = tok, done = TRUE,
        msg = sprintf("End of input → answer = sum(stack) = %s = <b>%g</b>.", paste(st, collapse = " + "), sum(st)))
      steps
    })
    calc <- stepper_server(input, output, session, "calc", calc_steps, speed = 750)
    output$calc_viz <- renderUI({
      s <- calc$cur(); tok <- s$tok
      cls <- ifelse(seq_along(tok) < s$k, "visited", ""); if (s$k >= 1 && s$k <= length(tok)) cls[s$k] <- "active"
      tagList(tags$div(class = "code-title", "tokens"), vrow(tok, cls, idx = FALSE),
              lane("stack (terms to add)", s$st, if (isTRUE(s$done)) "found" else "frontier", "empty"),
              lane("pending operator", s$op, "visited"),
              explain(s$msg))
    })

    quiz_server(input, output, session, topic = "stacks", progress = progress, questions = list(
      list(q = "Which structure processes a tree level by level?",
           opts = c("Stack", "Queue", "Min-heap", "Hash set"), ans = 2,
           why = "BFS needs first-in-first-out order so that all nodes at depth d are handled before depth d+1."),
      list(q = "The monotonic-stack solution to 'next greater element' has a nested while loop. Its total running time is…",
           opts = c("O(n²)", "O(n log n)", "O(n)", "O(log n)"), ans = 3,
           why = "Each index is pushed once and popped at most once, so the inner loop runs at most n times across the whole scan."),
      list(q = "After scanning <code>(()</code> with the bracket algorithm, what is the state and verdict?",
           opts = c("Stack empty → valid", "Stack holds one <code>(</code> → invalid", "Error on the last character", "Stack holds <code>)</code> → invalid"), ans = 2,
           why = "No closer ever fails, but one opener is left unmatched. You must check the stack is empty at the end."),
      list(q = "In Python, which is the right structure for a FIFO queue?",
           opts = c("list with pop(0)", "collections.deque with popleft()", "set", "tuple"), ans = 2,
           why = "list.pop(0) shifts every remaining element (O(n)); deque.popleft() is O(1)."),
      list(q = "Evaluating <code>5 1 2 + 4 * + 3 -</code> in postfix gives…",
           opts = c("14", "9", "17", "20"), ans = 1,
           why = "1+2 = 3; 3*4 = 12; 5+12 = 17; 17−3 = 14.")
    ))
  })
}
