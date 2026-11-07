# modules/mod_dp.R — Dynamic Programming

dp_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🧩", "Dynamic Programming",
      "Break problems into overlapping subproblems. Master memoisation, tabulation, and the DP table build-up.",
      c("Memoisation", "Tabulation", "1D DP", "2D DP", "Knapsack")),

    fluidRow(
      box(title = "Longest Common Subsequence (LCS)", status = "primary", solidHeader = TRUE, width = 5,
        tags$p("Enter two strings to build the DP table and find the LCS.", style = "font-size:12px; color:#555;"),
        textInput(ns("str_a"), "String A:", value = "ABCBDAB"),
        textInput(ns("str_b"), "String B:", value = "BDCAB"),
        actionButton(ns("btn_lcs"), "Compute LCS", class = "btn btn-dsa")
      ),
      box(title = "LCS DP Table", status = "info", solidHeader = TRUE, width = 7,
        uiOutput(ns("lcs_table")),
        uiOutput(ns("lcs_result"))
      )
    ),

    fluidRow(
      box(title = "Knapsack 0/1 Explorer", status = "primary", solidHeader = TRUE, width = 5,
        tags$p("Add items with weight and value. Set capacity to compute max value.", style = "font-size:12px; color:#555;"),
        fluidRow(
          column(4, textInput(ns("ks_weights"), "Weights:", value = "2,3,4,5")),
          column(4, textInput(ns("ks_values"),  "Values:",  value = "3,4,5,6")),
          column(4, numericInput(ns("ks_cap"),  "Capacity:", value = 8, min = 1))
        ),
        actionButton(ns("btn_knapsack"), "Solve", class = "btn btn-dsa")
      ),
      box(title = "Knapsack Result", status = "info", solidHeader = TRUE, width = 4,
        uiOutput(ns("ks_result"))
      ),
      box(title = "Complexity Reference", status = "info", solidHeader = TRUE, width = 3,
        cplx_table(data.frame(
          Problem    = c("Fibonacci", "LCS", "Knapsack", "Coin Change", "Edit Distance"),
          Time       = c("O(n)", "O(m·n)", "O(n·W)", "O(n·amount)", "O(m·n)"),
          Space      = c("O(1)*", "O(m·n)", "O(n·W)", "O(amount)", "O(m·n)"),
          stringsAsFactors = FALSE
        )),
        tags$p("* Space-optimised with two variables.", style = "font-size:10.5px; color:#888;")
      )
    ),

    fluidRow(
      box(title = "Key Algorithms (Python)", status = "primary", solidHeader = TRUE, width = 6,
        tags$p(tags$strong("Coin Change — Tabulation O(n·amount)"), style = "font-size:12px;"),
        dsa_code(
'def coinChange(coins, amount):
    dp = [float("inf")] * (amount + 1)
    dp[0] = 0
    for a in range(1, amount + 1):
        for c in coins:
            if c <= a:
                dp[a] = min(dp[a], dp[a - c] + 1)
    return dp[amount] if dp[amount] != float("inf") else -1'),
        tags$p(tags$strong("Longest Increasing Subsequence — O(n log n)"), style = "font-size:12px; margin-top:10px;"),
        dsa_code(
'import bisect
def lengthOfLIS(nums):
    tails = []
    for n in nums:
        pos = bisect.bisect_left(tails, n)
        if pos == len(tails):
            tails.append(n)
        else:
            tails[pos] = n
    return len(tails)'),
        tags$p(tags$strong("Edit Distance — 2D DP O(m·n)"), style = "font-size:12px; margin-top:10px;"),
        dsa_code(
'def minDistance(word1, word2):
    m, n = len(word1), len(word2)
    dp = [[0]*(n+1) for _ in range(m+1)]
    for i in range(m+1): dp[i][0] = i
    for j in range(n+1): dp[0][j] = j
    for i in range(1,m+1):
        for j in range(1,n+1):
            if word1[i-1]==word2[j-1]:
                dp[i][j] = dp[i-1][j-1]
            else:
                dp[i][j] = 1+min(dp[i-1][j],dp[i][j-1],dp[i-1][j-1])
    return dp[m][n]')
      ),
      box(title = "LeetCode Problems", status = "success", solidHeader = TRUE, width = 3,
        prob_row(70,  "Climbing Stairs",             "Easy",   "https://leetcode.com/problems/climbing-stairs/"),
        prob_row(322, "Coin Change",                 "Medium", "https://leetcode.com/problems/coin-change/"),
        prob_row(300, "Longest Increasing Subseq.",  "Medium", "https://leetcode.com/problems/longest-increasing-subsequence/"),
        prob_row(1143,"Longest Common Subsequence",  "Medium", "https://leetcode.com/problems/longest-common-subsequence/"),
        prob_row(72,  "Edit Distance",               "Medium", "https://leetcode.com/problems/edit-distance/"),
        prob_row(416, "Partition Equal Subset Sum",  "Medium", "https://leetcode.com/problems/partition-equal-subset-sum/"),
        prob_row(312, "Burst Balloons",              "Hard",   "https://leetcode.com/problems/burst-balloons/")
      ),
      box(title = "Quick Quiz", status = "warning", solidHeader = TRUE, width = 3,
        uiOutput(ns("quiz_ui"))
      )
    ),

    ref_block(
      "Cormen et al. (2009). Introduction to Algorithms (3rd ed.). MIT Press.",
      "Bellman, R. (1957). Dynamic Programming. Princeton University Press.",
      "Aziz, Lee & Prakash (2018). Elements of Programming Interviews in Python."
    )
  )
}

dp_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ── LCS ─────────────────────────────────────────────────────────────────
    lcs_data <- eventReactive(input$btn_lcs, {
      a <- toupper(trimws(input$str_a))
      b <- toupper(trimws(input$str_b))
      req(nchar(a) > 0, nchar(b) > 0, nchar(a) <= 12, nchar(b) <= 12)
      m <- nchar(a); n <- nchar(b)
      dp <- matrix(0, nrow = m+1, ncol = n+1)
      for (i in seq_len(m))
        for (j in seq_len(n))
          if (substr(a,i,i) == substr(b,j,j)) dp[i+1,j+1] <- dp[i,j]+1
          else dp[i+1,j+1] <- max(dp[i,j+1], dp[i+1,j])
      # backtrack
      lcs_str <- ""
      i <- m; j <- n
      while (i > 0 && j > 0) {
        if (substr(a,i,i) == substr(b,j,j)) { lcs_str <- paste0(substr(a,i,i), lcs_str); i <- i-1; j <- j-1 }
        else if (dp[i,j+1] > dp[i+1,j]) i <- i-1
        else j <- j-1
      }
      list(dp=dp, a=a, b=b, lcs=lcs_str, len=dp[m+1,n+1])
    }, ignoreNULL = FALSE)

    output$lcs_table <- renderUI({
      d <- lcs_data(); req(!is.null(d))
      a_chars <- c("", strsplit(d$a,"")[[1]])
      b_chars <- c("", strsplit(d$b,"")[[1]])
      header_row <- tags$tr(lapply(c("", b_chars), function(ch) tags$th(ch, style="min-width:28px; text-align:center; font-size:11px;")))
      body_rows  <- lapply(seq_len(nrow(d$dp)), function(i)
        tags$tr(
          tags$th(a_chars[i], style="font-size:11px; text-align:center;"),
          lapply(seq_len(ncol(d$dp)), function(j)
            tags$td(d$dp[i,j], style=paste0(
              "text-align:center; font-size:11px; padding:3px 5px;",
              if (d$dp[i,j] == d$len && i > 1 && j > 1) " background:#c7d2fe; font-weight:700;" else ""
            ))
          )
        )
      )
      tags$div(style="overflow-x:auto;",
        tags$table(class="cplx-tbl", style="font-size:11px;",
          tags$thead(header_row),
          tags$tbody(body_rows)
        )
      )
    })

    output$lcs_result <- renderUI({
      d <- lcs_data()
      if (is.null(d)) return(tags$div(class="viz-explain","Press Compute LCS."))
      callout(paste0("<strong>LCS = \"", d$lcs, "\"</strong> (length ", d$len,
                     "). Highlighted cells show where matches occur."), "success")
    })

    # ── Knapsack ─────────────────────────────────────────────────────────────
    output$ks_result <- renderUI({
      input$btn_knapsack
      ws <- suppressWarnings(as.integer(trimws(strsplit(isolate(input$ks_weights),",")[[1]])))
      vs <- suppressWarnings(as.integer(trimws(strsplit(isolate(input$ks_values), ",")[[1]])))
      cap <- isolate(input$ks_cap)
      ws <- ws[!is.na(ws)]; vs <- vs[!is.na(vs)]
      n <- min(length(ws), length(vs))
      req(n > 0)
      ws <- ws[1:n]; vs <- vs[1:n]
      dp <- matrix(0, nrow = n+1, ncol = cap+1)
      for (i in seq_len(n))
        for (w in seq_len(cap)) {
          dp[i+1,w+1] <- dp[i,w+1]
          if (ws[i] <= w) dp[i+1,w+1] <- max(dp[i+1,w+1], dp[i, w-ws[i]+1] + vs[i])
        }
      best <- dp[n+1, cap+1]
      # trace selected items
      sel <- character(0); i <- n; w <- cap
      while (i > 0 && w > 0) {
        if (dp[i+1,w+1] != dp[i,w+1]) { sel <- c(sel, paste0("item",i,"(w=",ws[i],",v=",vs[i],")")); w <- w-ws[i] }
        i <- i-1
      }
      callout(paste0("<strong>Max value = ", best, "</strong> with capacity ", cap, ".<br>",
                     "Selected: ", if(length(sel)>0) paste(sel,collapse=", ") else "none"), "success")
    })

    # ── Quiz ─────────────────────────────────────────────────────────────────
    q_ans <- reactiveVal(NULL)
    output$quiz_ui <- renderUI({
      ans <- q_ans()
      tagList(
        tags$p(class="quiz-q","What defines a DP problem vs plain recursion?"),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="a")"wrong" else ""),
          "It uses loops instead of recursion",
          onclick=sprintf("Shiny.setInputValue('%s','a',{priority:'event'})",ns("qa"))),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="b")"right" else ""),
          "Overlapping subproblems + optimal substructure",
          onclick=sprintf("Shiny.setInputValue('%s','b',{priority:'event'})",ns("qa"))),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="c")"wrong" else ""),
          "It always requires a 2D table",
          onclick=sprintf("Shiny.setInputValue('%s','c',{priority:'event'})",ns("qa"))),
        if (!is.null(ans)) {
          if (ans=="b") tags$div(class="qfeedback right","✅ Correct! DP applies when subproblems repeat (overlapping) and the global optimum is built from local optima (optimal substructure).")
          else tags$div(class="qfeedback wrong","❌ DP is defined by overlapping subproblems + optimal substructure — not by implementation style or table dimensions.")
        }
      )
    })
    observeEvent(input$qa, q_ans(input$qa))
  })
}
