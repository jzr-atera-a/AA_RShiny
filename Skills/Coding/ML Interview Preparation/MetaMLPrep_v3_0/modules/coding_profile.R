# modules/coding_profile.R
# Profile Tab 3: Your Coding Interview — Profile-Specific Preparation
# Gaps, CV-derived examples, priority problem sets for this candidate

coding_profile_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
        tags$h1("Your Coding Interview Preparation"),
        tags$h2("Bridging Systems-Level CV Work → LeetCode-Style Interview Performance"),
        div(
          span(class = "hero-badge", "Python Primary"),
          span(class = "hero-badge", "Rust · C++"),
          span(class = "hero-badge", "Algorithmic Gap → 6 Weeks"),
          span(class = "hero-badge", "Computer Vision Algorithms")
        )
    ),

    # ── Honest Assessment ────────────────────────────
    fluidRow(
      box(title = "🔍 Honest Assessment: Your Coding Interview Starting Point",
          status = "warning", solidHeader = TRUE, width = 12,

          fluidRow(
            column(6,
                   div(class = "warn-box",
                       HTML("<strong>⚠️ The hard truth:</strong> Your CV demonstrates exceptional <em>systems-level</em> engineering — sensor fusion, distributed ML, real-time inference. However, Meta's coding interview tests <em>algorithmic problem-solving in isolation</em> (LeetCode style), which is a distinct skill that requires deliberate practice even for experienced engineers with strong CS foundations.")),
                   br(),
                   div(class = "framework-card",
                       tags$h5("Your Advantages Going In"),
                       tags$ul(
                         tags$li(tags$b("BSc CS + Mechanical Engineering (High Distinction, GPA 4.6):"), " You have the mathematical foundations — graph theory, algorithmic complexity, data structures."),
                         tags$li(tags$b("SLAM algorithms:"), " Kalman filtering, graph-based SLAM, A* search — you've implemented real algorithms, not toy examples."),
                         tags$li(tags$b("Sensor fusion = probabilistic reasoning:"), " Bayes, particle filters, occupancy grids — this is algorithmic thinking applied to real systems."),
                         tags$li(tags$b("Python + PyTorch daily:"), " Don't need to learn a language. Focus 100% on algorithmic patterns.")
                       )),
                   div(class = "framework-card",
                       tags$h5("Your Risks"),
                       tags$ul(
                         tags$li("May over-engineer solutions — your instinct is to build complete systems, Meta wants clean 30-line functions"),
                         tags$li("May jump to complex solutions when the interviewer expects you to start with brute force and iterate"),
                         tags$li("String manipulation / parsing problems may feel unfamiliar — less relevant to CV/ML work"),
                         tags$li("Dynamic programming: requires pattern recognition built through repetition, not intuition alone")
                       ))
            ),
            column(6,
                   div(class = "section-heading-dark", "CV-Derived Algorithm Knowledge"),
                   div(class = "framework-card",
                       tags$h5("Algorithms You've ACTUALLY Implemented"),
                       tags$ul(
                         tags$li(tags$b("Graph algorithms:"), " Pose graph optimisation (SLAM) = weighted graph shortest path + optimisation"),
                         tags$li(tags$b("Kalman filtering:"), " Dynamic programming on state sequences"),
                         tags$li(tags$b("ICP (Iterative Closest Point):"), " Iterative convergence algorithms — maps to gradient descent patterns"),
                         tags$li(tags$b("Voxel grids / octrees:"), " Spatial data structures, prefix sums, range queries"),
                         tags$li(tags$b("Sensor timestamp alignment:"), " Sliding window, interval merging"),
                         tags$li(tags$b("Multi-camera epipolar geometry:"), " Matrix operations, geometric algorithms"),
                         tags$li(tags$b("MinHash LSH (entity matching):"), " Hashing, approximate algorithms, space-time trade-offs")
                       )),
                   div(class = "tip-box",
                       HTML("<strong>💡 Bridge language for interviews:</strong> When you get a graph problem, you can say: 'I've implemented pose-graph optimisation for SLAM systems, so this is familiar territory — let me apply BFS here...' This shows real-world algorithmic depth, not just pattern matching."))
            )
          )
      )
    ),

    # ── Priority Problem List ────────────────────────
    fluidRow(
      box(title = "🎯 Your Priority LeetCode Plan (6 Weeks → Interview Ready)",
          status = "primary", solidHeader = TRUE, width = 8,

          div(class = "section-heading-dark", "Week-by-Week Priority (tailored to your CV background)"),

          tabsetPanel(
            tabPanel("Weeks 1–2: Foundations",
                     br(),
                     div(class = "framework-card",
                         tags$h5("Arrays & Sliding Window (highest-frequency at Meta)"),
                         tags$p("Relevance to you: sensor timestamp windowing, signal processing buffers. These patterns are familiar in principle — formalise them in code."),
                         tags$ul(
                           tags$li("LeetCode 76 — Minimum Window Substring ⭐⭐⭐⭐⭐"),
                           tags$li("LeetCode 239 — Sliding Window Maximum ⭐⭐⭐⭐"),
                           tags$li("LeetCode 3 — Longest Substring Without Repeating ⭐⭐⭐⭐"),
                           tags$li("LeetCode 424 — Longest Repeating Character Replacement ⭐⭐⭐")
                         )),
                     div(class = "framework-card",
                         tags$h5("Hash Maps & Sets (bread and butter)"),
                         tags$ul(
                           tags$li("LeetCode 1 — Two Sum (warm-up)"),
                           tags$li("LeetCode 49 — Group Anagrams"),
                           tags$li("LeetCode 146 — LRU Cache ⭐⭐⭐⭐⭐ (Design + HashMap + DLL)"),
                           tags$li("LeetCode 380 — Insert/Delete/GetRandom O(1)")
                         ))
            ),
            tabPanel("Weeks 3–4: Trees & Graphs",
                     br(),
                     div(class = "framework-card",
                         tags$h5("Graph Problems (your strongest area — SLAM background)"),
                         tags$p("Your SLAM pose-graph work = graph traversal + optimisation. Use this background explicitly in interviews."),
                         tags$ul(
                           tags$li("LeetCode 269 — Alien Dictionary (topo sort) ⭐⭐⭐⭐"),
                           tags$li("LeetCode 127 — Word Ladder (BFS)"),
                           tags$li("LeetCode 200 — Number of Islands (DFS/BFS)"),
                           tags$li("LeetCode 323 — Connected Components"),
                           tags$li("LeetCode 1197 — Minimum Knight Moves (BFS + bidirectional)")
                         )),
                     div(class = "framework-card",
                         tags$h5("Tree Problems"),
                         tags$ul(
                           tags$li("LeetCode 236 — Lowest Common Ancestor ⭐⭐⭐⭐⭐"),
                           tags$li("LeetCode 297 — Serialize/Deserialize Binary Tree ⭐⭐⭐⭐"),
                           tags$li("LeetCode 124 — Binary Tree Max Path Sum ⭐⭐⭐⭐"),
                           tags$li("LeetCode 863 — All Nodes Distance K in Tree")
                         ))
            ),
            tabPanel("Weeks 5–6: DP & Hard",
                     br(),
                     div(class = "framework-card",
                         tags$h5("Dynamic Programming"),
                         tags$p("Connection to your work: trajectory optimisation, path planning, sequence modelling. The mental model exists — formalise the DP pattern."),
                         tags$ul(
                           tags$li("LeetCode 1143 — Longest Common Subsequence"),
                           tags$li("LeetCode 312 — Burst Balloons ⭐⭐⭐"),
                           tags$li("LeetCode 140 — Word Break II ⭐⭐⭐"),
                           tags$li("LeetCode 10 — Regular Expression Matching ⭐⭐⭐⭐")
                         )),
                     div(class = "framework-card",
                         tags$h5("Hard Meta Favourites"),
                         tags$ul(
                           tags$li("LeetCode 295 — Find Median from Data Stream ⭐⭐⭐⭐⭐"),
                           tags$li("LeetCode 23 — Merge K Sorted Lists ⭐⭐⭐⭐⭐"),
                           tags$li("LeetCode 84 — Largest Rectangle in Histogram"),
                           tags$li("LeetCode 41 — First Missing Positive")
                         )),
                     div(class = "tip-box",
                         HTML("<strong>💡 Day before interview:</strong> Solve LeetCode 76 (Minimum Window Substring) and LeetCode 146 (LRU Cache) as a warm-up. These are the two most frequently reported Meta coding questions."))
            )
          )
      ),

      column(4,
             box(title = "⏱️ Interview Delivery — Your Specific Risks",
                 status = "danger", solidHeader = TRUE, width = 12,

                 div(class = "warn-box",
                     HTML("<strong>Risk 1 — Over-engineering:</strong> Your instinct will be to design a full system. The interviewer wants a clean 20-30 line function. Practice stopping yourself from adding complexity.")),

                 div(class = "warn-box",
                     HTML("<strong>Risk 2 — Jargon mismatch:</strong> Don't say 'This is like ICP convergence' if the interviewer expects 'This is a two-pointer problem'. Use LeetCode language in the interview.")),

                 div(class = "tip-box",
                     HTML("<strong>✅ Risk 3 — actually a strength:</strong> When asked about complexity, you can bring in real-world context: 'At Atera, this sort of O(n²) pairwise comparison was a bottleneck in our entity matching — we solved it with LSH to bring it to O(n log n)'. This shows applied algorithmic thinking.")),

                 br(),
                 div(class = "section-heading-dark", "Practice Tracker"),
                 sliderInput(ns("lc_done"), "LeetCode problems solved:", 0, 150, 0, step = 5),
                 sliderInput(ns("timed_done"), "Timed (< 25 min) solutions:", 0, 50, 0, step = 2),
                 actionButton(ns("save_progress"), "Save", class = "btn-meta", width = "100%"),
                 br(), br(),
                 uiOutput(ns("coding_status"))
             ),

             box(title = "📝 Coding Interview Simulation",
                 status = "success", solidHeader = TRUE, width = 12,
                 div(class = "practice-area",
                     p(tags$b("Practice problem (timed):")),
                     p(tags$i("Given a list of sensor timestamp intervals [start, end], merge all overlapping intervals. Return the merged list.")),
                     p(tags$small("(This is LeetCode 56 — Merge Intervals — linked to your sensor fusion work)")),
                     textAreaInput(ns("practice_code"), label = NULL, rows = 8,
                                   placeholder = "def merge(intervals):\n    # sort by start time\n    # iterate and merge overlapping\n    pass",
                                   width = "100%"),
                     actionButton(ns("submit"), "Check Solution", class = "btn-meta")
                 ),
                 uiOutput(ns("code_feedback"))
             )
      )
    )
  )
}

coding_profile_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$save_progress, {
      pct <- round((input$lc_done / 150) * 70 + (input$timed_done / 50) * 30)
      prep_manager$update_progress("coding_profile", min(pct, 100))
      output$coding_status <- renderUI({
        div(class = "success-box",
            tags$b(paste0(pct, "% ready")), tags$br(),
            tags$small(paste0(input$lc_done, " problems | ", input$timed_done, " timed"))
        )
      })
    })

    observeEvent(input$submit, {
      code <- input$practice_code
      feedback <- list()
      score <- 0

      if (grepl("sort", code, ignore.case = TRUE))    { score <- score + 30; feedback[[length(feedback)+1]] <- "✅ Sorting applied" }
      if (grepl("for |while ", code))                  { score <- score + 20; feedback[[length(feedback)+1]] <- "✅ Iteration present" }
      if (grepl("append|extend|\\+\\=", code))         { score <- score + 20; feedback[[length(feedback)+1]] <- "✅ Result construction" }
      if (grepl("def merge", code))                     { score <- score + 10; feedback[[length(feedback)+1]] <- "✅ Function signature correct" }
      if (grepl("O\\(|complex|log n", code, ignore.case=TRUE)) { score <- score + 20; feedback[[length(feedback)+1]] <- "✅ Complexity mentioned" }

      output$code_feedback <- renderUI({
        div(class = if (score >= 60) "success-box" else "tip-box",
            tags$b(paste0("Score: ", score, "/100")),
            tags$ul(lapply(feedback, tags$li)),
            if (score < 50) div(class = "warn-box",
                HTML("💡 Key insight: sort intervals by start time, then iterate comparing current end to next start. Time: O(n log n), Space: O(n). This exact pattern appears in sensor fusion timestamp alignment."))
        )
      })
    })
  })
}
