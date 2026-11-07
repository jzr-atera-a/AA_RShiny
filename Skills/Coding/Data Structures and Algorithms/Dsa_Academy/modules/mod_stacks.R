# modules/mod_stacks.R — Stacks & Queues

stacks_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("📚", "Stacks & Queues",
      "LIFO and FIFO structures powering expression parsing, BFS, and the powerful monotonic stack pattern.",
      c("LIFO", "FIFO", "Monotonic Stack", "Deque")),

    fluidRow(
      box(title = "Interactive Stack / Queue", status = "primary", solidHeader = TRUE, width = 4,
        radioButtons(ns("ds_type"), "Structure:", choices = c("Stack (LIFO)" = "stack", "Queue (FIFO)" = "queue"), inline = TRUE),
        textInput(ns("push_val"), "Value to push/enqueue:", value = "42"),
        fluidRow(
          column(6, actionButton(ns("btn_push"), "Push / Enqueue", class = "btn btn-dsa btn-sm", width = "100%")),
          column(6, actionButton(ns("btn_pop"),  "Pop / Dequeue",  class = "btn btn-dsa-outline btn-sm", width = "100%"))
        ),
        tags$br(),
        actionButton(ns("btn_clear"), "Clear", class = "btn btn-dsa-outline btn-sm"),
        tags$br(), tags$br(),
        uiOutput(ns("op_result"))
      ),
      box(title = "Visualisation", status = "info", solidHeader = TRUE, width = 8,
        uiOutput(ns("viz_ds"))
      )
    ),

    fluidRow(
      box(title = "Parentheses Validator", status = "primary", solidHeader = TRUE, width = 5,
        tags$p("Enter a string — the visualiser shows the stack trace to validate balanced brackets.", style = "font-size:12px; color:#555;"),
        textInput(ns("paren_str"), "Input:", value = "{[()]}"),
        actionButton(ns("btn_validate"), "Validate", class = "btn btn-dsa"),
        tags$br(), tags$br(),
        uiOutput(ns("paren_result"))
      ),
      box(title = "Complexity Reference", status = "info", solidHeader = TRUE, width = 3,
        cplx_table(data.frame(
          Operation = c("Push", "Pop", "Peek", "Search"),
          Stack     = c("O(1)", "O(1)", "O(1)", "O(n)"),
          Queue     = c("O(1)", "O(1)", "O(1)", "O(n)"),
          stringsAsFactors = FALSE
        )),
        tags$br(),
        callout("<strong>Monotonic stack:</strong> maintain increasing or decreasing order → O(n) for Next Greater Element, Histogram, Trapping Rain.", "tip")
      ),
      box(title = "Quick Quiz", status = "warning", solidHeader = TRUE, width = 4,
        uiOutput(ns("quiz_ui"))
      )
    ),

    fluidRow(
      box(title = "Key Algorithms (Python)", status = "primary", solidHeader = TRUE, width = 6,
        tags$p(tags$strong("Valid Parentheses — Stack O(n)"), style = "font-size:12px;"),
        dsa_code(
'def isValid(s):
    stack = []
    mapping = {")":"(", "}":"{", "]":"["}
    for ch in s:
        if ch in mapping:
            top = stack.pop() if stack else "#"
            if mapping[ch] != top: return False
        else:
            stack.append(ch)
    return not stack'),
        tags$p(tags$strong("Daily Temperatures — Monotonic Stack O(n)"), style = "font-size:12px; margin-top:10px;"),
        dsa_code(
'def dailyTemperatures(temps):
    stack, res = [], [0]*len(temps)
    for i, t in enumerate(temps):
        while stack and temps[stack[-1]] < t:
            j = stack.pop()
            res[j] = i - j
        stack.append(i)
    return res')
      ),
      box(title = "LeetCode Problems", status = "success", solidHeader = TRUE, width = 6,
        fluidRow(
          column(6,
            prob_row(20,  "Valid Parentheses",           "Easy",   "https://leetcode.com/problems/valid-parentheses/"),
            prob_row(155, "Min Stack",                   "Medium", "https://leetcode.com/problems/min-stack/"),
            prob_row(739, "Daily Temperatures",          "Medium", "https://leetcode.com/problems/daily-temperatures/"),
            prob_row(496, "Next Greater Element I",      "Easy",   "https://leetcode.com/problems/next-greater-element-i/")
          ),
          column(6,
            prob_row(84,  "Largest Rectangle Histogram", "Hard",   "https://leetcode.com/problems/largest-rectangle-in-histogram/"),
            prob_row(239, "Sliding Window Maximum",      "Hard",   "https://leetcode.com/problems/sliding-window-maximum/"),
            prob_row(232, "Implement Queue Using Stacks","Easy",   "https://leetcode.com/problems/implement-queue-using-stacks/"),
            prob_row(150, "Evaluate RPN",                "Medium", "https://leetcode.com/problems/evaluate-reverse-polish-notation/")
          )
        )
      )
    ),

    ref_block(
      "Cormen et al. (2009). Introduction to Algorithms (3rd ed.). MIT Press.",
      "Weiss, M. A. (2011). Data Structures and Algorithm Analysis in Java (3rd ed.). Pearson."
    )
  )
}

stacks_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    ds_state <- reactiveValues(items = character(0), last_op = NULL)

    observeEvent(input$btn_push, {
      v <- trimws(input$push_val); req(nchar(v) > 0)
      ds_state$items <- c(ds_state$items, v)
      ds_state$last_op <- paste0("Pushed '", v, "'")
    })
    observeEvent(input$btn_pop, {
      req(length(ds_state$items) > 0)
      n <- length(ds_state$items)
      if (input$ds_type == "stack") {
        val <- ds_state$items[n]; ds_state$items <- ds_state$items[-n]
        ds_state$last_op <- paste0("Popped '", val, "' from top")
      } else {
        val <- ds_state$items[1]; ds_state$items <- ds_state$items[-1]
        ds_state$last_op <- paste0("Dequeued '", val, "' from front")
      }
    })
    observeEvent(input$btn_clear, { ds_state$items <- character(0); ds_state$last_op <- "Cleared" })

    output$op_result <- renderUI({
      if (!is.null(ds_state$last_op)) callout(paste0("<strong>", ds_state$last_op, "</strong>"), "info")
    })

    output$viz_ds <- renderUI({
      items <- ds_state$items
      if (length(items) == 0) return(tags$div(class="viz-canvas", tags$span(style="color:#94a3b8; font-size:13px;","Empty — push some values")))
      is_stack <- input$ds_type == "stack"
      display <- if (is_stack) rev(items) else items
      labels  <- if (is_stack) c("TOP", rep("", length(display)-1)) else c("FRONT", rep("", length(display)-1))
      nodes <- lapply(seq_along(display), function(i) {
        cls <- if (i == 1) "vnode active" else "vnode"
        tags$div(style = "display:flex; align-items:center; gap:8px; margin:4px 0;",
          tags$div(style = "font-size:10px; font-weight:700; color:#4f46e5; min-width:40px;", labels[i]),
          tags$div(class = cls, display[i])
        )
      })
      if (!is_stack) nodes <- c(nodes, list(tags$div(style="font-size:10px; font-weight:700; color:#94a3b8; margin-left:48px;","BACK")))
      tags$div(class = "viz-canvas", style = "flex-direction:column; align-items:flex-start;",
        tags$p(style="font-size:12px; font-weight:700; color:#4f46e5; margin:0 0 8px;",
               paste0(if(is_stack) "Stack" else "Queue", " (", length(items), " items)")),
        nodes
      )
    })

    # ── Parentheses validator ─────────────────────────────────────────────────
    output$paren_result <- renderUI({
      input$btn_validate
      s <- isolate(input$paren_str)
      mapping <- list(")" = "(", "}" = "{", "]" = "[")
      stk <- character(0); trace <- character(0)
      valid <- TRUE
      for (ch in strsplit(s, "")[[1]]) {
        if (ch %in% names(mapping)) {
          top <- if (length(stk)) stk[length(stk)] else "#"
          if (is.null(mapping[[ch]]) || mapping[[ch]] != top) { valid <- FALSE; break }
          stk <- stk[-length(stk)]
          trace <- c(trace, paste0("Match '", ch, "' → pop '", top, "'"))
        } else if (ch %in% c("(","[","{")) {
          stk <- c(stk, ch)
          trace <- c(trace, paste0("Open '", ch, "' → push"))
        }
      }
      if (valid && length(stk) == 0) {
        callout(paste0("<strong>✅ Valid!</strong> Trace: ", paste(trace, collapse = " | ")), "success")
      } else {
        callout(paste0("<strong>❌ Invalid!</strong> ", if(!valid)"Mismatched bracket." else "Unclosed brackets."), "warn")
      }
    })

    # ── Quiz ─────────────────────────────────────────────────────────────────
    q_ans <- reactiveVal(NULL)
    output$quiz_ui <- renderUI({
      ans <- q_ans()
      tagList(
        tags$p(class = "quiz-q", "Which structure is best for implementing BFS (level-order tree traversal)?"),
        tags$button(class = paste("qopt", if(!is.null(ans)&&ans=="a")"wrong" else ""),
          "Stack (LIFO)", onclick=sprintf("Shiny.setInputValue('%s','a',{priority:'event'})", ns("qa"))),
        tags$button(class = paste("qopt", if(!is.null(ans)&&ans=="b")"right" else ""),
          "Queue (FIFO)", onclick=sprintf("Shiny.setInputValue('%s','b',{priority:'event'})", ns("qa"))),
        tags$button(class = paste("qopt", if(!is.null(ans)&&ans=="c")"wrong" else ""),
          "Priority Queue", onclick=sprintf("Shiny.setInputValue('%s','c',{priority:'event'})", ns("qa"))),
        if (!is.null(ans)) {
          if (ans=="b") tags$div(class="qfeedback right","✅ Correct! BFS processes nodes level-by-level, which requires FIFO ordering — exactly what a queue provides.")
          else tags$div(class="qfeedback wrong","❌ BFS needs FIFO ordering. A stack gives DFS. A priority queue gives Dijkstra's.")
        }
      )
    })
    observeEvent(input$qa, q_ans(input$qa))
  })
}
