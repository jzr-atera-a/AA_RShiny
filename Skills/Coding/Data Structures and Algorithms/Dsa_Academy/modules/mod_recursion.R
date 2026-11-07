# modules/mod_recursion.R — Recursion & Backtracking

recursion_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🔄", "Recursion & Backtracking",
      "Divide and conquer. Explore all possibilities with pruning. Master the template for permutations, subsets, and N-Queens.",
      c("Base Case", "Backtrack", "Pruning", "State Space", "DFS Tree")),

    fluidRow(
      box(title = "Subsets / Permutations Generator", status = "primary", solidHeader = TRUE, width = 5,
        tags$p("Generate all subsets or permutations for a small set of numbers.",
               style = "font-size:12px; color:#555;"),
        textInput(ns("perm_vals"), "Values (up to 4, comma-separated):", value = "1,2,3"),
        radioButtons(ns("perm_type"), "Generate:",
          choices = c("All Subsets (Power Set)" = "subsets",
                      "All Permutations"         = "perms",
                      "Combinations (choose k)"  = "combos"),
          selected = "subsets"),
        conditionalPanel(condition = sprintf("input['%s'] == 'combos'", ns("perm_type")),
          numericInput(ns("combo_k"), "k:", value = 2, min = 1, max = 4)
        ),
        actionButton(ns("btn_gen"), "Generate", class = "btn btn-dsa")
      ),
      box(title = "Results", status = "info", solidHeader = TRUE, width = 7,
        uiOutput(ns("gen_result"))
      )
    ),

    fluidRow(
      box(title = "N-Queens Solver", status = "primary", solidHeader = TRUE, width = 4,
        tags$p("Count (and display) all solutions to the N-Queens problem.", style = "font-size:12px; color:#555;"),
        sliderInput(ns("nq_n"), "N:", min = 4, max = 8, value = 4, step = 1),
        actionButton(ns("btn_nq"), "Solve", class = "btn btn-dsa"),
        tags$br(), tags$br(),
        uiOutput(ns("nq_count"))
      ),
      box(title = "First N-Queens Solution", status = "info", solidHeader = TRUE, width = 4,
        uiOutput(ns("nq_board"))
      ),
      box(title = "Complexity Reference", status = "info", solidHeader = TRUE, width = 4,
        cplx_table(data.frame(
          Problem        = c("Subsets", "Permutations", "Combinations(n,k)", "N-Queens"),
          Results        = c("2ⁿ", "n!", "C(n,k)", "varies"),
          Time           = c("O(2ⁿ)", "O(n·n!)", "O(C(n,k)·k)", "O(n!)"),
          stringsAsFactors = FALSE
        )),
        callout("<strong>Pruning</strong> is what makes backtracking practical — skip branches that can't lead to valid solutions early.", "tip")
      )
    ),

    fluidRow(
      box(title = "Key Algorithms (Python)", status = "primary", solidHeader = TRUE, width = 6,
        tags$p(tags$strong("Subsets — O(2ⁿ)"), style = "font-size:12px;"),
        dsa_code(
'def subsets(nums):
    res = []
    def bt(start, path):
        res.append(path[:])
        for i in range(start, len(nums)):
            path.append(nums[i])
            bt(i + 1, path)
            path.pop()
    bt(0, [])
    return res'),
        tags$p(tags$strong("Permutations — O(n·n!)"), style = "font-size:12px; margin-top:10px;"),
        dsa_code(
'def permute(nums):
    res = []
    def bt(path, remaining):
        if not remaining:
            res.append(path[:]); return
        for i in range(len(remaining)):
            path.append(remaining[i])
            bt(path, remaining[:i] + remaining[i+1:])
            path.pop()
    bt([], nums)
    return res'),
        tags$p(tags$strong("Word Search (2D backtrack) — O(m·n·4^L)"), style = "font-size:12px; margin-top:10px;"),
        dsa_code(
'def exist(board, word):
    R, C = len(board), len(board[0])
    def dfs(r, c, i):
        if i == len(word): return True
        if not (0<=r<R and 0<=c<C): return False
        if board[r][c] != word[i]: return False
        tmp, board[r][c] = board[r][c], "#"
        found = any(dfs(r+dr,c+dc,i+1) for dr,dc in [(1,0),(-1,0),(0,1),(0,-1)])
        board[r][c] = tmp
        return found
    return any(dfs(r,c,0) for r in range(R) for c in range(C))')
      ),
      box(title = "LeetCode Problems", status = "success", solidHeader = TRUE, width = 3,
        prob_row(78,  "Subsets",                      "Medium", "https://leetcode.com/problems/subsets/"),
        prob_row(46,  "Permutations",                 "Medium", "https://leetcode.com/problems/permutations/"),
        prob_row(77,  "Combinations",                 "Medium", "https://leetcode.com/problems/combinations/"),
        prob_row(39,  "Combination Sum",              "Medium", "https://leetcode.com/problems/combination-sum/"),
        prob_row(79,  "Word Search",                  "Medium", "https://leetcode.com/problems/word-search/"),
        prob_row(51,  "N-Queens",                     "Hard",   "https://leetcode.com/problems/n-queens/"),
        prob_row(37,  "Sudoku Solver",                "Hard",   "https://leetcode.com/problems/sudoku-solver/")
      ),
      box(title = "Quick Quiz", status = "warning", solidHeader = TRUE, width = 3,
        uiOutput(ns("quiz_ui"))
      )
    ),

    ref_block(
      "Cormen et al. (2009). Introduction to Algorithms (3rd ed.). MIT Press.",
      "Laakmann McDowell (2015). Cracking the Coding Interview (6th ed.). CareerCup.",
      "Skiena, S. S. (2020). The Algorithm Design Manual (3rd ed.). Springer."
    )
  )
}

recursion_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    output$gen_result <- renderUI({
      input$btn_gen
      vals <- suppressWarnings(as.integer(trimws(strsplit(isolate(input$perm_vals),",")[[1]])))
      vals <- vals[!is.na(vals)][1:min(4, length(vals[!is.na(vals)]))]
      req(length(vals) > 0)
      type <- isolate(input$perm_type)
      k    <- isolate(input$combo_k)

      results <- switch(type,
        subsets = {
          res <- list()
          bt <- function(start, path) {
            res[[length(res)+1]] <<- path
            if (start > length(vals)) return()
            for (i in seq(start, length(vals))) { bt(i+1, c(path, vals[i])) }
          }
          bt(1, integer(0))
          res
        },
        perms = {
          res <- list()
          bt <- function(path, rem) {
            if (length(rem) == 0) { res[[length(res)+1]] <<- path; return() }
            for (i in seq_along(rem)) bt(c(path, rem[i]), rem[-i])
          }
          bt(integer(0), vals)
          res
        },
        combos = {
          res <- list()
          k2  <- max(1, min(k, length(vals)))
          bt <- function(start, path) {
            if (length(path) == k2) { res[[length(res)+1]] <<- path; return() }
            for (i in seq(start, length(vals))) bt(i+1, c(path, vals[i]))
          }
          bt(1, integer(0))
          res
        }
      )

      label <- switch(type, subsets="Subsets", perms="Permutations", combos=paste0("C(",length(vals),",",k,")"))
      tags$div(
        tags$p(style="font-size:12px; font-weight:700; color:#4f46e5;",
               paste0(label, ": ", length(results), " results")),
        tags$div(style="display:flex; flex-wrap:wrap; gap:6px;",
          lapply(results, function(r)
            tags$span(class="vnode visited",
                      style="font-size:11px; padding:4px 8px;",
                      if(length(r)==0) "∅" else paste0("{",paste(r,collapse=","),"}"))
          )
        )
      )
    })

    # ── N-Queens ──────────────────────────────────────────────────────────────
    nq_solutions <- eventReactive(input$btn_nq, {
      n <- input$nq_n
      solutions <- list()
      cols <- diag1 <- diag2 <- integer(0)
      board <- rep(0L, n)

      bt <- function(row) {
        if (row > n) { solutions[[length(solutions)+1]] <<- board; return() }
        for (col in seq_len(n)) {
          d1 <- row - col; d2 <- row + col
          if (col %in% cols || d1 %in% diag1 || d2 %in% diag2) next
          board[row] <<- col
          cols  <<- c(cols,  col)
          diag1 <<- c(diag1, d1)
          diag2 <<- c(diag2, d2)
          bt(row + 1)
          cols  <<- setdiff(cols,  col)
          diag1 <<- setdiff(diag1, d1)
          diag2 <<- setdiff(diag2, d2)
        }
      }
      bt(1)
      solutions
    }, ignoreNULL = FALSE)

    output$nq_count <- renderUI({
      sols <- nq_solutions()
      callout(paste0("<strong>", length(sols), " solutions</strong> for N=", input$nq_n,
                     ". Each row places exactly one queen."), "success")
    })

    output$nq_board <- renderUI({
      sols <- nq_solutions(); req(length(sols) > 0)
      n    <- input$nq_n
      sol  <- sols[[1]]
      rows <- lapply(seq_len(n), function(r)
        tags$div(style="display:flex; gap:2px; margin:1px 0;",
          lapply(seq_len(n), function(c)
            tags$div(style=paste0(
              "width:28px; height:28px; display:flex; align-items:center; justify-content:center;",
              "font-size:16px; border-radius:4px;",
              if ((r+c)%%2==0) " background:#e2e8f0;" else " background:#f8fafc;",
              if (sol[r]==c) " background:#4f46e5; color:white;" else ""
            ), if(sol[r]==c) "♛" else "")
          )
        )
      )
      tags$div(style="display:inline-block; border:2px solid #e2e8f0; border-radius:6px; padding:6px;",
        rows)
    })

    # ── Quiz ─────────────────────────────────────────────────────────────────
    q_ans <- reactiveVal(NULL)
    output$quiz_ui <- renderUI({
      ans <- q_ans()
      tagList(
        tags$p(class="quiz-q","How many subsets does a set of n elements have?"),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="a")"wrong" else ""),
          "n!", onclick=sprintf("Shiny.setInputValue('%s','a',{priority:'event'})",ns("qa"))),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="b")"wrong" else ""),
          "n²", onclick=sprintf("Shiny.setInputValue('%s','b',{priority:'event'})",ns("qa"))),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="c")"right" else ""),
          "2ⁿ", onclick=sprintf("Shiny.setInputValue('%s','c',{priority:'event'})",ns("qa"))),
        if (!is.null(ans)) {
          if (ans=="c") tags$div(class="qfeedback right","✅ Correct! Each element is either included or not → 2 choices per element → 2ⁿ subsets total.")
          else tags$div(class="qfeedback wrong","❌ Each element has 2 choices (in or out), so the power set has 2ⁿ subsets.")
        }
      )
    })
    observeEvent(input$qa, q_ans(input$qa))
  })
}
