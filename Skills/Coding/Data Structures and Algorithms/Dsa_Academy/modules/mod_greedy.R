# modules/mod_greedy.R — Greedy Algorithms

greedy_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("💰", "Greedy Algorithms",
      "Make the locally optimal choice at each step. Fast O(n log n) solutions — but only correct when the greedy choice property holds.",
      c("Activity Selection", "Huffman", "Interval Scheduling", "Dijkstra", "Kruskal")),

    fluidRow(
      box(title = "Interval Scheduling (Activity Selection)", status = "primary", solidHeader = TRUE, width = 5,
        tags$p("Given intervals [start, end], find the maximum number of non-overlapping intervals.",
               style = "font-size:12px; color:#555;"),
        tags$p("Edit as 'start-end' pairs:", style = "font-size:12px; color:#555;"),
        textInput(ns("intervals"), "Intervals:", value = "1-4,2-6,5-7,8-9,5-9,6-10,8-11,2-13,11-14"),
        actionButton(ns("btn_schedule"), "Schedule", class = "btn btn-dsa")
      ),
      box(title = "Greedy Result", status = "info", solidHeader = TRUE, width = 7,
        uiOutput(ns("schedule_viz")),
        uiOutput(ns("schedule_explain"))
      )
    ),

    fluidRow(
      box(title = "Jump Game Simulator", status = "primary", solidHeader = TRUE, width = 5,
        tags$p("Can you reach the last index? Greedy: track the farthest reachable position.",
               style = "font-size:12px; color:#555;"),
        textInput(ns("jump_vals"), "Max-jump values:", value = "2,3,1,1,4"),
        actionButton(ns("btn_jump"), "Check", class = "btn btn-dsa"),
        tags$br(), tags$br(),
        uiOutput(ns("jump_result"))
      ),
      box(title = "Complexity Reference", status = "info", solidHeader = TRUE, width = 3,
        cplx_table(data.frame(
          Problem             = c("Activity Selection", "Jump Game", "Gas Station", "Huffman Coding", "Kruskal MST"),
          Time                = c("O(n log n)", "O(n)", "O(n)", "O(n log n)", "O(E log E)"),
          stringsAsFactors    = FALSE
        )),
        callout("Greedy is <em>not always correct</em>. Verify the <strong>greedy choice property</strong> (local → global optimum) and <strong>optimal substructure</strong>.", "warn")
      ),
      box(title = "Quick Quiz", status = "warning", solidHeader = TRUE, width = 4,
        uiOutput(ns("quiz_ui"))
      )
    ),

    fluidRow(
      box(title = "Key Algorithms (Python)", status = "primary", solidHeader = TRUE, width = 6,
        tags$p(tags$strong("Non-Overlapping Intervals — O(n log n)"), style = "font-size:12px;"),
        dsa_code(
'def eraseOverlapIntervals(intervals):
    intervals.sort(key=lambda x: x[1])  # sort by end
    count = 0
    end   = float("-inf")
    for s, e in intervals:
        if s >= end:
            end = e        # take this interval
        else:
            count += 1     # must remove this one
    return count'),
        tags$p(tags$strong("Jump Game II (min jumps) — O(n)"), style = "font-size:12px; margin-top:10px;"),
        dsa_code(
'def jump(nums):
    jumps = cur_end = farthest = 0
    for i in range(len(nums) - 1):
        farthest = max(farthest, i + nums[i])
        if i == cur_end:
            jumps   += 1
            cur_end  = farthest
    return jumps'),
        tags$p(tags$strong("Gas Station (circular tour) — O(n)"), style = "font-size:12px; margin-top:10px;"),
        dsa_code(
'def canCompleteCircuit(gas, cost):
    total = tank = start = 0
    for i in range(len(gas)):
        diff   = gas[i] - cost[i]
        total += diff
        tank  += diff
        if tank < 0:
            start = i + 1
            tank  = 0
    return start if total >= 0 else -1')
      ),
      box(title = "LeetCode Problems", status = "success", solidHeader = TRUE, width = 6,
        fluidRow(
          column(6,
            prob_row(55,  "Jump Game",                   "Medium", "https://leetcode.com/problems/jump-game/"),
            prob_row(45,  "Jump Game II",                "Medium", "https://leetcode.com/problems/jump-game-ii/"),
            prob_row(435, "Non-Overlapping Intervals",   "Medium", "https://leetcode.com/problems/non-overlapping-intervals/"),
            prob_row(452, "Min Arrows to Burst Balloons","Medium", "https://leetcode.com/problems/minimum-number-of-arrows-to-burst-balloons/")
          ),
          column(6,
            prob_row(134, "Gas Station",                 "Medium", "https://leetcode.com/problems/gas-station/"),
            prob_row(135, "Candy",                       "Hard",   "https://leetcode.com/problems/candy/"),
            prob_row(406, "Queue Reconstruction",        "Medium", "https://leetcode.com/problems/queue-reconstruction-by-height/"),
            prob_row(763, "Partition Labels",            "Medium", "https://leetcode.com/problems/partition-labels/")
          )
        )
      )
    ),

    ref_block(
      "Cormen et al. (2009). Introduction to Algorithms (3rd ed.). MIT Press.",
      "Kleinberg & Tardos (2005). Algorithm Design. Addison-Wesley.",
      "Skiena, S. S. (2020). The Algorithm Design Manual (3rd ed.). Springer."
    )
  )
}

greedy_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    parse_intervals <- function(s) {
      pairs <- trimws(strsplit(s, ",")[[1]])
      res <- list()
      for (p in pairs) {
        parts <- strsplit(p, "-")[[1]]
        if (length(parts) != 2) next
        a <- suppressWarnings(as.integer(trimws(parts[1])))
        b <- suppressWarnings(as.integer(trimws(parts[2])))
        if (!is.na(a) && !is.na(b) && a < b) res <- c(res, list(c(a, b)))
      }
      res
    }

    sched_result <- eventReactive(input$btn_schedule, {
      ivs <- parse_intervals(input$intervals)
      req(length(ivs) > 0)
      # sort by end time
      ivs   <- ivs[order(sapply(ivs, `[`, 2))]
      sel   <- logical(length(ivs))
      end   <- -Inf
      for (i in seq_along(ivs)) {
        if (ivs[[i]][1] >= end) { sel[i] <- TRUE; end <- ivs[[i]][2] }
      }
      list(ivs = ivs, sel = sel)
    }, ignoreNULL = FALSE)

    output$schedule_viz <- renderUI({
      res <- sched_result(); req(!is.null(res))
      ivs <- res$ivs; sel <- res$sel
      max_t <- max(sapply(ivs, `[`, 2))
      scale <- 300 / max_t
      rows <- lapply(seq_along(ivs), function(i) {
        iv  <- ivs[[i]]
        cls <- if (sel[i]) "background:#10b981;" else "background:#e2e8f0;"
        tags$div(style="display:flex; align-items:center; gap:8px; margin:3px 0;",
          tags$span(style="font-size:10px; color:#94a3b8; min-width:40px;",
                    paste0("[",iv[1],",",iv[2],"]")),
          tags$div(style=paste0(
            "height:14px; border-radius:3px; margin-left:", round(iv[1]*scale), "px;",
            "width:", round((iv[2]-iv[1])*scale), "px;", cls)),
          if (sel[i]) tags$span(style="font-size:11px; color:#10b981;","✓")
        )
      })
      tags$div(style="overflow-x:auto;", rows)
    })

    output$schedule_explain <- renderUI({
      res <- sched_result()
      if (is.null(res)) return(tags$div(class="viz-explain","Press Schedule."))
      n_sel <- sum(res$sel)
      callout(paste0("<strong>", n_sel, " non-overlapping intervals</strong> selected (✓) out of ",
                     length(res$ivs), ". Greedy: sort by end time, always pick the earliest-ending compatible interval."),
              "success")
    })

    # ── Jump Game ─────────────────────────────────────────────────────────────
    output$jump_result <- renderUI({
      input$btn_jump
      vals <- suppressWarnings(as.integer(trimws(strsplit(isolate(input$jump_vals),",")[[1]])))
      vals <- vals[!is.na(vals)]
      req(length(vals) > 0)
      n <- length(vals); farthest <- 0
      reachable <- logical(n)
      for (i in seq_len(n)) {
        if (i-1 > farthest) break
        farthest <- max(farthest, i-1 + vals[i])
        reachable[i] <- TRUE
      }
      can <- farthest >= n-1
      nodes <- lapply(seq_along(vals), function(i)
        tags$div(class=paste("vnode", if(reachable[i])"visited" else ""),
                 style=if(i==n && can)"border-color:#10b981; color:#10b981;" else "",
                 vals[i])
      )
      tagList(
        tags$div(class="viz-canvas", nodes),
        tags$br(),
        callout(paste0(if(can)"<strong>✅ Can reach the end!</strong>" else "<strong>❌ Cannot reach the end.</strong>",
                       " Farthest reachable index: ", min(farthest, n-1)), if(can)"success" else "warn")
      )
    })

    # ── Quiz ─────────────────────────────────────────────────────────────────
    q_ans <- reactiveVal(NULL)
    output$quiz_ui <- renderUI({
      ans <- q_ans()
      tagList(
        tags$p(class="quiz-q","Activity selection greedy: sort intervals by which criterion?"),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="a")"wrong" else ""),
          "Start time", onclick=sprintf("Shiny.setInputValue('%s','a',{priority:'event'})",ns("qa"))),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="b")"right" else ""),
          "End time", onclick=sprintf("Shiny.setInputValue('%s','b',{priority:'event'})",ns("qa"))),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="c")"wrong" else ""),
          "Duration (end - start)", onclick=sprintf("Shiny.setInputValue('%s','c',{priority:'event'})",ns("qa"))),
        if (!is.null(ans)) {
          if (ans=="b") tags$div(class="qfeedback right","✅ Correct! Sorting by earliest end time maximises the number of activities that can fit. This is provably optimal.")
          else tags$div(class="qfeedback wrong","❌ Sort by earliest end time. This leaves the most room for future intervals and provably maximises the count.")
        }
      )
    })
    observeEvent(input$qa, q_ans(input$qa))
  })
}
