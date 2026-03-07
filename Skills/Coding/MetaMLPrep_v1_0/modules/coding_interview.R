# modules/coding_interview.R
# Tab 3: Coding Interview (PDF page 8)

coding_interview_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    div(class="meta-hero",
        tags$h1("Coding Interview"),
        tags$h2("One 45-Minute Session — Algorithms & Data Structures"),
        div(
          span(class="hero-badge", "CoderPad"),
          span(class="hero-badge", "45 Minutes"),
          span(class="hero-badge", "1-2 Problems"),
          span(class="hero-badge", "Execution Disabled")
        )
    ),
    
    fluidRow(
      # ── Interview Overview ───────────────────────────
      box(title = "📋 What the Coding Interview Covers", status="primary",
          solidHeader=TRUE, width=6,
          
          div(class="success-box",
              HTML("<strong>✅ The goal:</strong> Meta wants to see how you apply CS principles to solve concrete problems — not whether you can write syntactically perfect code.")),
          br(),
          
          div(class="section-heading-dark", "Topic Areas"),
          fluidRow(
            column(6, 
                   div(class="framework-card",
                       tags$h5(icon("sort-amount-up"), " Algorithms"),
                       tags$ul(style="font-size:12px;margin:0;",
                               tags$li("Sorting & searching"),
                               tags$li("Graph traversal (BFS/DFS)"),
                               tags$li("Dynamic programming"),
                               tags$li("Divide & conquer"),
                               tags$li("Two pointers / sliding window"),
                               tags$li("Binary search variants"))),
                   div(class="framework-card",
                       tags$h5(icon("database"), " Data Structures"),
                       tags$ul(style="font-size:12px;margin:0;",
                               tags$li("Arrays, strings, matrices"),
                               tags$li("Linked lists, trees, tries"),
                               tags$li("Stacks, queues, heaps"),
                               tags$li("Hash maps / hash sets"),
                               tags$li("Graphs (adjacency list/matrix)"),
                               tags$li("Segment trees, union-find")))
            ),
            column(6,
                   div(class="framework-card",
                       tags$h5(icon("drafting-compass"), " Design Patterns"),
                       tags$ul(style="font-size:12px;margin:0;",
                               tags$li("Memoisation / caching"),
                               tags$li("Iterator / generator patterns"),
                               tags$li("OOP: encapsulation, inheritance"),
                               tags$li("State machines"),
                               tags$li("Producer-consumer"))),
                   div(class="framework-card",
                       tags$h5(icon("chart-line"), " Complexity"),
                       tags$ul(style="font-size:12px;margin:0;",
                               tags$li("Always state time complexity"),
                               tags$li("Always state space complexity"),
                               tags$li("Know O(1), O(log n), O(n), O(n log n), O(n²)"),
                               tags$li("Understand when to trade space for time")))
            )
          )
      ),
      
      # ── Assessment Criteria ──────────────────────────
      box(title = "🎯 Assessment Criteria & Scoring", status="info",
          solidHeader=TRUE, width=6,
          
          div(class="section-heading-dark", "5 Dimensions Meta Evaluates"),
          
          div(class="framework-card",
              tags$h5("1. Communication"),
              tags$p("Think out loud. Explain your approach BEFORE writing code. Ask clarifying questions. 'Before I start — can I assume the input array is sorted?'")),
          
          div(class="framework-card",
              tags$h5("2. Problem Solving"),
              tags$p("Break down the problem. Map it to a known pattern. State your approach before coding. Don't immediately jump to the most complex solution.")),
          
          div(class="framework-card",
              tags$h5("3. Coding"),
              tags$p("Write clean, readable code. Use meaningful variable names. Avoid over-engineering. Check edge cases before submitting.")),
          
          div(class="framework-card",
              tags$h5("4. Complexity Analysis"),
              tags$p("State time and space complexity proactively. Discuss trade-offs. Know when O(n log n) is acceptable vs O(n) is required at Meta's scale.")),
          
          div(class="framework-card",
              tags$h5("5. Debugging"),
              tags$p("Trace through your code with a small example. Identify bugs proactively before the interviewer points them out. Show systematic debugging.")),
          
          div(class="warn-box",
              HTML("<strong>⚠️ Do NOT:</strong> Use a language you've never practised. Assume silence is fine. Skip edge cases. Try to immediately jump to the O(n) solution before explaining the brute force."))
      )
    ),
    
    # ── Meta-Specific High-Frequency Problems ─────────
    fluidRow(
      box(title = "🔥 Meta High-Frequency LeetCode Problems (2024-2026)",
          status="warning", solidHeader=TRUE, width=8,
          
          div(class="section-heading-dark", "Must-Know Problems (Appeared in Meta Loops)"),
          
          DT::dataTableOutput(ns("lc_table"))
      ),
      
      column(4,
             box(title = "⏱️ Time Management Guide", status="success",
                 solidHeader=TRUE, width=12,
                 
                 div(class="section-heading-dark", "45-Minute Structure"),
                 timeline_entry("1-3", "Clarify the problem",
                                "Confirm input/output format, constraints, edge cases, examples."),
                 timeline_entry("4-10", "Discuss approach",
                                "Talk through brute force first, then optimise. Get buy-in before coding."),
                 timeline_entry("11-35", "Write & explain code",
                                "Code while narrating. Use clean variable names. Handle edge cases."),
                 timeline_entry("36-40", "Test with examples",
                                "Walk through your code with the sample input and a custom edge case."),
                 timeline_entry("41-45", "Complexity + optimise",
                                "State O() complexity. Discuss how you'd improve further with more time.")
             ),
             box(title = "Progress Tracker", status="primary",
                 solidHeader=TRUE, width=12,
                 sliderInput(ns("problems_done"), "LeetCode Problems Solved",
                             min=0, max=150, value=0, step=5),
                 sliderInput(ns("mock_done"), "Mock Interviews Done",
                             min=0, max=10, value=0, step=1),
                 actionButton(ns("save_coding_progress"), "Update Progress",
                              class="btn-meta", width="100%"),
                 br(), br(),
                 uiOutput(ns("coding_progress_ui"))
             )
      )
    ),
    
    # ── Practice Problem ─────────────────────────────
    fluidRow(
      box(title = "💻 Practice Session — Simulate CoderPad",
          status="primary", solidHeader=TRUE, width=12,
          
          tabsetPanel(
            tabPanel("Practice Problem",
                     br(),
                     fluidRow(
                       column(6,
                              selectInput(ns("problem_select"), "Select a problem:",
                                          choices = c(
                                            "Minimum Window Substring (Hard)",
                                            "Meeting Rooms II (Medium)",
                                            "LRU Cache (Medium)",
                                            "Word Break (Medium)",
                                            "Number of Islands (Medium)",
                                            "Merge K Sorted Lists (Hard)",
                                            "Trapping Rain Water (Hard)",
                                            "Longest Consecutive Sequence (Medium)"
                                          )),
                              uiOutput(ns("problem_statement"))
                       ),
                       column(6,
                              div(class="practice-area",
                                  p(tags$b("Your Solution:")),
                                  textAreaInput(ns("code_solution"), label=NULL,
                                                placeholder="# Write your solution here\n# Remember: think out loud, state complexity\n\ndef solution(...):\n    pass",
                                                rows=12, width="100%"),
                                  textAreaInput(ns("complexity_note"), "Complexity Analysis:",
                                                placeholder="Time: O(?)\nSpace: O(?)\nJustification: ...",
                                                rows=3, width="100%"),
                                  actionButton(ns("submit_solution"), "Submit & Score",
                                               class="btn-meta")
                              ),
                              uiOutput(ns("solution_feedback"))
                       )
                     )
            ),
            tabPanel("Key Patterns Cheat Sheet",
                     br(),
                     fluidRow(
                       column(4, div(class="framework-card",
                                     tags$h5("Sliding Window"),
                                     tags$p("Use when: contiguous subarray/substring with a constraint."),
                                     tags$code("l, r = 0, 0\nwhile r < n:\n  # expand right\n  # shrink left if violated"))),
                       column(4, div(class="framework-card",
                                     tags$h5("Two Pointers"),
                                     tags$p("Use when: sorted array, finding pairs, palindromes."),
                                     tags$code("l, r = 0, n-1\nwhile l < r:\n  if condition: l += 1\n  else: r -= 1"))),
                       column(4, div(class="framework-card",
                                     tags$h5("BFS (Level-order)"),
                                     tags$p("Use when: shortest path, level-by-level processing."),
                                     tags$code("from collections import deque\nq = deque([start])\nwhile q:\n  node = q.popleft()")))
                     ),
                     fluidRow(
                       column(4, div(class="framework-card",
                                     tags$h5("DFS + Backtracking"),
                                     tags$p("Use when: permutations, subsets, N-Queens style."),
                                     tags$code("def dfs(state, start):\n  if base_case: result.append(...)\n  for i in range(start, n):\n    dfs(state + [i], i+1)"))),
                       column(4, div(class="framework-card",
                                     tags$h5("Dynamic Programming"),
                                     tags$p("Use when: overlapping subproblems, optimal substructure."),
                                     tags$code("dp = [0] * (n+1)\ndp[0] = base\nfor i in range(1, n+1):\n  dp[i] = f(dp[i-1])"))),
                       column(4, div(class="framework-card",
                                     tags$h5("Heap / Priority Queue"),
                                     tags$p("Use when: top-K, merge sorted, scheduling."),
                                     tags$code("import heapq\nheap = []\nheapq.heappush(heap, val)\nheapq.heappop(heap)")))
                     )
            )
          )
      )
    )
  )
}

coding_interview_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    
    # LeetCode problem table
    output$lc_table <- DT::renderDataTable({
      df <- data.frame(
        `#`        = c(76,295,146,23,124,239,297,863,269,301,10,140,212,84,312,
                       236,41,32,127,65),
        Problem    = c("Minimum Window Substring","Find Median from Data Stream",
                       "LRU Cache","Merge K Sorted Lists",
                       "Binary Tree Max Path Sum","Sliding Window Maximum",
                       "Serialize/Deserialize Binary Tree","All Nodes Distance K",
                       "Alien Dictionary","Remove Invalid Parentheses",
                       "Regular Expression Matching","Word Break II",
                       "Word Search II","Largest Rectangle in Histogram",
                       "Burst Balloons","Lowest Common Ancestor",
                       "First Missing Positive","Longest Valid Parentheses",
                       "Word Ladder","Valid Number"),
        Difficulty = c("Hard","Hard","Medium","Hard","Hard","Hard","Hard","Hard",
                       "Hard","Hard","Hard","Hard","Hard","Hard","Hard",
                       "Medium","Hard","Hard","Hard","Hard"),
        Category   = c("Sliding Window","Heap/Design","Design","Heap",
                       "Tree DP","Sliding Window","Tree/Design","BFS",
                       "Graph/Topo","Backtracking","DP","DP+Backtrack",
                       "Trie+Backtrack","Stack","DP","Tree","Array","Stack",
                       "BFS","Parsing"),
        Frequency  = c("⭐⭐⭐⭐⭐","⭐⭐⭐⭐⭐","⭐⭐⭐⭐⭐","⭐⭐⭐⭐⭐","⭐⭐⭐⭐",
                       "⭐⭐⭐⭐","⭐⭐⭐⭐","⭐⭐⭐","⭐⭐⭐⭐","⭐⭐⭐",
                       "⭐⭐⭐⭐","⭐⭐⭐","⭐⭐⭐","⭐⭐⭐⭐","⭐⭐⭐",
                       "⭐⭐⭐⭐⭐","⭐⭐⭐⭐","⭐⭐⭐","⭐⭐⭐","⭐⭐"),
        check.names = FALSE
      )
      DT::datatable(df, options=list(pageLength=10, scrollX=TRUE),
                    rownames=FALSE, class="compact stripe hover")
    })
    
    # Problem statement
    output$problem_statement <- renderUI({
      problems <- list(
        "Minimum Window Substring (Hard)" = list(
          desc="Given strings s and t, return the minimum window in s that contains all characters of t. If no such window exists, return ''.",
          hint="Sliding window with character frequency map. Two pointers l and r. Shrink left when window is valid.",
          tc="O(|s| + |t|)", sc="O(|s| + |t|)"),
        "LRU Cache (Medium)" = list(
          desc="Design an LRU (Least Recently Used) cache with get(key) and put(key, value) operations, both in O(1).",
          hint="Combine a doubly-linked list (for O(1) remove/add at head/tail) with a hash map (for O(1) lookup).",
          tc="O(1)", sc="O(capacity)"),
        "Meeting Rooms II (Medium)" = list(
          desc="Given an array of meeting time intervals, find the minimum number of conference rooms required.",
          hint="Sort by start time. Use a min-heap of end times. If current start >= heap[0], reuse the room.",
          tc="O(n log n)", sc="O(n)"),
        "Number of Islands (Medium)" = list(
          desc="Given a 2D grid of '1's (land) and '0's (water), count the number of islands.",
          hint="DFS from every unvisited '1'. Mark visited cells. Count how many times you start a DFS.",
          tc="O(m*n)", sc="O(m*n) recursion stack"),
        "Trapping Rain Water (Hard)" = list(
          desc="Given elevation heights, compute how much water can be trapped after rain.",
          hint="Two-pointer approach: track left_max and right_max. Water trapped at i = min(left_max,right_max) - height[i].",
          tc="O(n)", sc="O(1)")
      )
      
      sel <- input$problem_select
      if (!sel %in% names(problems)) return(div(p("Select a problem to see the description.")))
      
      p_info <- problems[[sel]]
      div(
        div(class="framework-card",
            tags$h5("Problem Statement"),
            tags$p(p_info$desc)),
        div(class="tip-box",
            HTML(paste0("<strong>💡 Hint:</strong> ", p_info$hint))),
        div(class="success-box",
            HTML(paste0("<strong>Target Complexity:</strong> Time: ", p_info$tc,
                        " | Space: ", p_info$sc)))
      )
    })
    
    # Solution feedback
    observeEvent(input$submit_solution, {
      code <- input$code_solution
      complexity <- input$complexity_note
      
      score <- 0
      feedback <- c()
      
      if (nchar(code) > 50)  { score <- score + 30; feedback <- c(feedback, "✅ Solution written") }
      if (nchar(code) > 200) { score <- score + 20; feedback <- c(feedback, "✅ Detailed solution") }
      if (grepl("def |class |//|#", code)) { score <- score + 10; feedback <- c(feedback, "✅ Code structure present") }
      if (nchar(complexity) > 10) { score <- score + 20; feedback <- c(feedback, "✅ Complexity stated") }
      if (grepl("O\\(", complexity)) { score <- score + 20; feedback <- c(feedback, "✅ Big-O notation used") }
      
      prep_manager$add_practice_score("coding_interview", score, input$problem_select)
      prep_manager$update_progress("coding_interview", min(score + 20, 100))
      
      output$solution_feedback <- renderUI({
        div(class = if(score >= 70) "success-box" else "tip-box",
            tags$h5(paste0("Score: ", score, "/100")),
            tags$ul(lapply(feedback, tags$li)),
            tags$small("Keep practising! Aim for solutions you can code in < 20 minutes."))
      })
    })
    
    # Progress update
    observeEvent(input$save_coding_progress, {
      pct <- round((input$problems_done / 150 * 60) + (input$mock_done / 10 * 40))
      prep_manager$update_progress("coding_interview", min(pct, 100))
      output$coding_progress_ui <- renderUI({
        div(class="success-box",
            tags$b(paste0("Progress: ", pct, "%")), tags$br(),
            tags$small(paste0(input$problems_done, " problems | ",
                              input$mock_done, " mocks")))
      })
    })
  })
}
