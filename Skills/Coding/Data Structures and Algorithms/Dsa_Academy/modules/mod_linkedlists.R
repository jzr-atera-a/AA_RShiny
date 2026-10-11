# modules/mod_linkedlists.R — Linked Lists

linkedlists_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🔗", "Linked Lists",
      "Dynamic pointer-based structures. Master reversal, cycle detection (Floyd's), and the fast/slow pointer technique.",
      c("Singly Linked", "Doubly Linked", "Floyd's Algorithm", "Dummy Head")),

    fluidRow(
      box(title = "List Reversal Visualiser", status = "primary", solidHeader = TRUE, width = 5,
        tags$p("Enter node values, then step through iterative reversal.", style = "font-size:12px; color:#555;"),
        textInput(ns("ll_vals"), "Nodes (comma-separated):", value = "1,2,3,4,5"),
        fluidRow(
          column(6, actionButton(ns("ll_prev"), "◀ Prev", class = "btn btn-dsa-outline btn-sm", width = "100%")),
          column(6, actionButton(ns("ll_next"), "▶ Next", class = "btn btn-dsa btn-sm", width = "100%"))
        ),
        tags$br(),
        actionButton(ns("ll_reset"), "↺ Reset", class = "btn btn-dsa-outline btn-sm")
      ),
      box(title = "Visualisation", status = "info", solidHeader = TRUE, width = 7,
        uiOutput(ns("viz_ll")),
        uiOutput(ns("viz_ll_explain"))
      )
    ),

    fluidRow(
      box(title = "Floyd's Cycle Detection", status = "primary", solidHeader = TRUE, width = 6,
        tags$p("Simulate a linked list with an optional cycle. Watch slow/fast pointers meet.", style = "font-size:12px; color:#555;"),
        sliderInput(ns("cycle_len"), "List length:", min = 4, max = 12, value = 7, step = 1),
        sliderInput(ns("cycle_pos"), "Cycle starts at index (0 = no cycle):", min = 0, max = 10, value = 3, step = 1),
        actionButton(ns("btn_run_cycle"), "Run Detection", class = "btn btn-dsa"),
        tags$br(), tags$br(),
        uiOutput(ns("cycle_result"))
      ),
      box(title = "Complexity Reference", status = "info", solidHeader = TRUE, width = 3,
        cplx_table(data.frame(
          Operation      = c("Access", "Search", "Insert at head", "Insert at tail", "Delete"),
          Time           = c("O(n)", "O(n)", "O(1)", "O(n) / O(1)*", "O(1) at ptr"),
          stringsAsFactors = FALSE
        )),
        tags$p("* O(1) tail insert if tail pointer maintained.", style = "font-size:10.5px; color:#888;"),
        callout("Use a <strong>dummy head node</strong> to eliminate edge-case code for empty lists and head deletions.", "tip")
      ),
      box(title = "Quick Quiz", status = "warning", solidHeader = TRUE, width = 3,
        uiOutput(ns("quiz_ui"))
      )
    ),

    fluidRow(
      box(title = "Key Algorithms (Python)", status = "primary", solidHeader = TRUE, width = 6,
        tags$p(tags$strong("Reverse List — Iterative O(n)"), style = "font-size:12px;"),
        dsa_code(
'def reverseList(head):
    prev, cur = None, head
    while cur:
        nxt = cur.next
        cur.next = prev
        prev = cur
        cur = nxt
    return prev'),
        tags$p(tags$strong("Detect Cycle — Floyd's O(n) time, O(1) space"), style = "font-size:12px; margin-top:10px;"),
        dsa_code(
'def hasCycle(head):
    slow = fast = head
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
        if slow is fast:
            return True
    return False'),
        tags$p(tags$strong("Find Cycle Entry Node"), style = "font-size:12px; margin-top:10px;"),
        dsa_code(
'def detectCycle(head):
    slow = fast = head
    while fast and fast.next:
        slow, fast = slow.next, fast.next.next
        if slow is fast:
            slow = head
            while slow is not fast:
                slow, fast = slow.next, fast.next
            return slow  # cycle entry
    return None')
      ),
      box(title = "LeetCode Problems", status = "success", solidHeader = TRUE, width = 6,
        fluidRow(
          column(6,
            prob_row(206, "Reverse Linked List",         "Easy",   "https://leetcode.com/problems/reverse-linked-list/"),
            prob_row(21,  "Merge Two Sorted Lists",      "Easy",   "https://leetcode.com/problems/merge-two-sorted-lists/"),
            prob_row(141, "Linked List Cycle",           "Easy",   "https://leetcode.com/problems/linked-list-cycle/"),
            prob_row(876, "Middle of Linked List",       "Easy",   "https://leetcode.com/problems/middle-of-the-linked-list/")
          ),
          column(6,
            prob_row(2,   "Add Two Numbers",             "Medium", "https://leetcode.com/problems/add-two-numbers/"),
            prob_row(19,  "Remove Nth From End",         "Medium", "https://leetcode.com/problems/remove-nth-node-from-end-of-list/"),
            prob_row(142, "Linked List Cycle II",        "Medium", "https://leetcode.com/problems/linked-list-cycle-ii/"),
            prob_row(23,  "Merge k Sorted Lists",        "Hard",   "https://leetcode.com/problems/merge-k-sorted-lists/")
          )
        )
      )
    ),

    ref_block(
      "Knuth, D. E. (1997). The Art of Computer Programming, Vol. 1: Fundamental Algorithms.",
      "Skiena, S. S. (2020). The Algorithm Design Manual (3rd ed.). Springer.",
      "Sedgewick & Wayne (2011). Algorithms (4th ed.). Addison-Wesley."
    )
  )
}

linkedlists_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ── Reversal step-through ────────────────────────────────────────────────
    rv <- reactiveValues(step = 0, nodes = integer(0))

    parsed_nodes <- reactive({
      vals <- suppressWarnings(as.integer(trimws(strsplit(input$ll_vals, ",")[[1]])))
      vals[!is.na(vals)]
    })

    observeEvent(list(input$ll_reset, input$ll_vals), { rv$step <- 0 })
    observeEvent(input$ll_next, { n <- length(parsed_nodes()); if (rv$step < n) rv$step <- rv$step + 1 })
    observeEvent(input$ll_prev, { if (rv$step > 0) rv$step <- rv$step - 1 })

    output$viz_ll <- renderUI({
      nodes <- parsed_nodes(); req(length(nodes) > 0)
      n <- length(nodes); s <- rv$step
      # After s steps, first s nodes are reversed
      rev_part  <- if (s > 0) rev(nodes[1:s])    else integer(0)
      rem_part  <- if (s < n) nodes[(s+1):n]     else integer(0)

      make_row <- function(vals, colour) {
        lapply(seq_along(vals), function(i) {
          tagList(
            tags$div(class = "vnode", style = paste0("border-color:", colour, "; color:", colour),
                     vals[i]),
            if (i < length(vals)) tags$span(class = "varrow", "→")
          )
        })
      }
      tags$div(class = "viz-canvas", style = "flex-direction:column; align-items:flex-start; gap:10px;",
        if (length(rev_part) > 0) tags$div(style = "display:flex; align-items:center; gap:4px;",
          tags$span(style = "font-size:11px; font-weight:700; color:#10b981; min-width:70px;", "Reversed:"),
          make_row(rev_part, "#10b981")
        ),
        if (length(rem_part) > 0) tags$div(style = "display:flex; align-items:center; gap:4px;",
          tags$span(style = "font-size:11px; font-weight:700; color:#4f46e5; min-width:70px;", "Remaining:"),
          make_row(rem_part, "#4f46e5")
        )
      )
    })

    output$viz_ll_explain <- renderUI({
      nodes <- parsed_nodes(); n <- length(nodes); s <- rv$step
      txt <- if (s == 0) "Press ▶ Next to start reversing. prev=NULL, cur=head."
             else if (s == n) paste0("✅ Done! Full list reversed in ", n, " pointer swaps.")
             else sprintf("Step %d/%d: node(%d) reversed. prev=%d, cur=%d → next iteration.",
                          s, n, nodes[s], nodes[s], if(s<n) nodes[s+1] else 0)
      tags$div(class = "viz-explain", txt)
    })

    # ── Cycle detection simulation ───────────────────────────────────────────
    output$cycle_result <- renderUI({
      input$btn_run_cycle
      len <- isolate(input$cycle_len)
      cyc <- isolate(input$cycle_pos)
      has_cycle <- cyc > 0 && cyc < len

      if (!has_cycle) {
        callout("<strong>No cycle detected.</strong> fast pointer reached NULL → list is acyclic.", "success")
      } else {
        # Simulate
        pos <- seq_len(len) - 1
        slow <- 0; fast <- 0; steps <- 0
        repeat {
          slow <- slow + 1; if (slow >= len) slow <- cyc
          fast <- fast + 2; fast <- if (fast >= len) (fast - len + cyc) else fast
          if (fast >= len) fast <- (fast - len + cyc)
          steps <- steps + 1
          if (slow == fast || steps > 100) break
        }
        callout(paste0("<strong>Cycle detected!</strong> slow and fast pointers met at node index <code>",
                       slow, "</code> after <code>", steps, "</code> steps. Cycle entry at index <code>",
                       cyc, "</code>."), "warn")
      }
    })

    # ── Quiz ────────────────────────────────────────────────────────────────
    q_ans <- reactiveVal(NULL)
    output$quiz_ui <- renderUI({
      ans <- q_ans()
      tagList(
        tags$p(class = "quiz-q", "Floyd's cycle detection uses two pointers. What are their speeds?"),
        tags$button(class = paste("qopt", if (!is.null(ans) && ans=="a") "right" else ""),
          "slow=1 step, fast=2 steps",
          onclick = sprintf("Shiny.setInputValue('%s','a',{priority:'event'})", ns("quiz_a"))),
        tags$button(class = paste("qopt", if (!is.null(ans) && ans=="b") "wrong" else ""),
          "slow=1 step, fast=3 steps",
          onclick = sprintf("Shiny.setInputValue('%s','b',{priority:'event'})", ns("quiz_a"))),
        tags$button(class = paste("qopt", if (!is.null(ans) && ans=="c") "wrong" else ""),
          "slow=2 steps, fast=4 steps",
          onclick = sprintf("Shiny.setInputValue('%s','c',{priority:'event'})", ns("quiz_a"))),
        if (!is.null(ans)) {
          if (ans == "a") tags$div(class = "qfeedback right",
            "✅ Correct! The classic tortoise-and-hare: slow moves 1 node, fast moves 2. They're guaranteed to meet inside any cycle.")
          else tags$div(class = "qfeedback wrong",
            "❌ The classic ratio is 1:2. Any ratio > 1 works in theory, but 1:2 is standard and simplest to prove.")
        }
      )
    })
    observeEvent(input$quiz_a, { q_ans(input$quiz_a) })
  })
}
