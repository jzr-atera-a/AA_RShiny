# modules/mod_bits.R — Bit Manipulation

bits_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("⚡", "Bit Manipulation",
      "Direct binary operations. Master XOR tricks, power-of-two checks, and single/missing number patterns for O(1) space solutions.",
      c("XOR", "Bitmask", "Hamming Weight", "Power of 2", "Bit Shift")),

    fluidRow(
      box(title = "Binary Explorer", status = "primary", solidHeader = TRUE, width = 5,
        tags$p("Enter two integers to explore all bitwise operations.", style = "font-size:12px; color:#555;"),
        fluidRow(
          column(6, numericInput(ns("bit_a"), "A:", value = 60, step = 1)),
          column(6, numericInput(ns("bit_b"), "B:", value = 13, step = 1))
        ),
        actionButton(ns("btn_bits"), "Compute", class = "btn btn-dsa")
      ),
      box(title = "Bitwise Results", status = "info", solidHeader = TRUE, width = 7,
        uiOutput(ns("bits_result"))
      )
    ),

    fluidRow(
      box(title = "XOR Patterns", status = "primary", solidHeader = TRUE, width = 5,
        tags$p("XOR is the workhorse of bit tricks. Enter an array to find the single non-duplicate.",
               style = "font-size:12px; color:#555;"),
        textInput(ns("xor_arr"), "Array (one unique element):", value = "4,1,2,1,2"),
        actionButton(ns("btn_xor"), "Find Single Number", class = "btn btn-dsa"),
        tags$br(), tags$br(),
        uiOutput(ns("xor_result"))
      ),
      box(title = "Bit Tricks Reference", status = "info", solidHeader = TRUE, width = 4,
        cplx_table(data.frame(
          Trick             = c("n & (n-1)", "n & (-n)", "n ^ n", "n ^ 0", "Count bits"),
          Effect            = c("Clear lowest set bit", "Isolate lowest set bit", "= 0 (cancel)", "= n (identity)", "Kernighan: O(k)"),
          stringsAsFactors  = FALSE
        )),
        callout("<strong>Power of 2 check:</strong> n > 0 && (n & (n-1)) == 0 → O(1). The only set bit clears itself.", "tip"),
        callout("<strong>XOR property:</strong> a ^ a = 0, a ^ 0 = a. XOR of an array where every element appears twice yields 0 — the odd one out remains.", "info")
      ),
      box(title = "Quick Quiz", status = "warning", solidHeader = TRUE, width = 3,
        uiOutput(ns("quiz_ui"))
      )
    ),

    fluidRow(
      box(title = "Key Algorithms (Python)", status = "primary", solidHeader = TRUE, width = 6,
        tags$p(tags$strong("Single Number — XOR O(n) time O(1) space"), style = "font-size:12px;"),
        dsa_code(
'def singleNumber(nums):
    res = 0
    for n in nums:
        res ^= n
    return res'),
        tags$p(tags$strong("Count Set Bits (Kernighan) — O(k)"), style = "font-size:12px; margin-top:10px;"),
        dsa_code(
'def hammingWeight(n):
    count = 0
    while n:
        n &= n - 1   # clear lowest set bit
        count += 1
    return count'),
        tags$p(tags$strong("Subsets via Bitmask — O(2ⁿ·n)"), style = "font-size:12px; margin-top:10px;"),
        dsa_code(
'def subsets(nums):
    n, res = len(nums), []
    for mask in range(1 << n):       # 0 to 2^n - 1
        subset = []
        for i in range(n):
            if mask & (1 << i):      # bit i is set
                subset.append(nums[i])
        res.append(subset)
    return res'),
        tags$p(tags$strong("Missing Number — XOR O(n)"), style = "font-size:12px; margin-top:10px;"),
        dsa_code(
'def missingNumber(nums):
    res = len(nums)
    for i, n in enumerate(nums):
        res ^= i ^ n   # XOR with both index and value
    return res')
      ),
      box(title = "LeetCode Problems", status = "success", solidHeader = TRUE, width = 6,
        fluidRow(
          column(6,
            prob_row(136, "Single Number",               "Easy",   "https://leetcode.com/problems/single-number/"),
            prob_row(191, "Number of 1 Bits",            "Easy",   "https://leetcode.com/problems/number-of-1-bits/"),
            prob_row(231, "Power of Two",                "Easy",   "https://leetcode.com/problems/power-of-two/"),
            prob_row(268, "Missing Number",              "Easy",   "https://leetcode.com/problems/missing-number/")
          ),
          column(6,
            prob_row(190, "Reverse Bits",                "Easy",   "https://leetcode.com/problems/reverse-bits/"),
            prob_row(338, "Counting Bits",               "Easy",   "https://leetcode.com/problems/counting-bits/"),
            prob_row(137, "Single Number II",            "Medium", "https://leetcode.com/problems/single-number-ii/"),
            prob_row(201, "Bitwise AND of Num Range",    "Medium", "https://leetcode.com/problems/bitwise-and-of-numbers-range/")
          )
        )
      )
    ),

    ref_block(
      "Warren, H. S. (2012). Hacker's Delight (2nd ed.). Addison-Wesley.",
      "Cormen et al. (2009). Introduction to Algorithms (3rd ed.). MIT Press.",
      "Laakmann McDowell (2015). Cracking the Coding Interview (6th ed.). CareerCup."
    )
  )
}

bits_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    to_bin <- function(x, bits=16) {
      x <- bitwAnd(x, 0xFFFF)
      paste(rev(as.integer(intToBits(x)[1:bits])), collapse="")
    }

    bits_data <- eventReactive(input$btn_bits, {
      a <- as.integer(input$bit_a)
      b <- as.integer(input$bit_b)
      list(
        a    = a, b = b,
        AND  = bitwAnd(a, b),
        OR   = bitwOr(a, b),
        XOR  = bitwXor(a, b),
        NOT_a= bitwNot(a),
        SHL  = bitwShiftL(a, 1L),
        SHR  = bitwShiftR(a, 1L),
        bin_a = to_bin(a), bin_b = to_bin(b)
      )
    }, ignoreNULL = FALSE)

    output$bits_result <- renderUI({
      d <- bits_data(); req(!is.null(d))
      ops <- list(
        list(op="A",           val=d$a,   bin=d$bin_a),
        list(op="B",           val=d$b,   bin=d$bin_b),
        list(op="A AND B",     val=d$AND, bin=to_bin(d$AND)),
        list(op="A OR B",      val=d$OR,  bin=to_bin(d$OR)),
        list(op="A XOR B",     val=d$XOR, bin=to_bin(d$XOR)),
        list(op="NOT A",       val=d$NOT_a,bin=to_bin(d$NOT_a)),
        list(op="A << 1",      val=d$SHL, bin=to_bin(d$SHL)),
        list(op="A >> 1",      val=d$SHR, bin=to_bin(d$SHR))
      )
      rows <- lapply(ops, function(r)
        tags$div(style="display:flex; align-items:center; gap:12px; margin:3px 0; font-size:12px;",
          tags$span(style="min-width:80px; font-weight:700; color:#4f46e5;", r$op),
          tags$span(style="font-family:monospace; color:#64748b; min-width:180px; font-size:11px;", r$bin),
          tags$span(class="vnode visited", style="font-size:11px; padding:3px 8px;", r$val)
        )
      )
      tags$div(class="viz-canvas", style="flex-direction:column; align-items:flex-start;", rows)
    })

    # ── XOR single number ─────────────────────────────────────────────────────
    output$xor_result <- renderUI({
      input$btn_xor
      vals <- suppressWarnings(as.integer(trimws(strsplit(isolate(input$xor_arr),",")[[1]])))
      vals <- vals[!is.na(vals)]
      req(length(vals) > 0)
      res <- Reduce(bitwXor, vals, 0L)
      # show XOR trace
      trace <- integer(length(vals)+1); trace[1] <- 0L
      for (i in seq_along(vals)) trace[i+1] <- bitwXor(trace[i], vals[i])
      nodes <- lapply(seq_along(vals), function(i)
        tagList(
          tags$span(style="font-size:12px; color:#94a3b8;", paste0("^", vals[i]," = ")),
          tags$span(class="vnode visited", style="font-size:11px; padding:3px 6px;", trace[i+1]),
          tags$span(class="varrow","")
        )
      )
      tagList(
        tags$div(class="viz-canvas", style="flex-wrap:wrap;", nodes),
        tags$br(),
        callout(paste0("<strong>Single number = ", res, "</strong>. All other XOR pairs cancelled to 0."), "success")
      )
    })

    # ── Quiz ─────────────────────────────────────────────────────────────────
    q_ans <- reactiveVal(NULL)
    output$quiz_ui <- renderUI({
      ans <- q_ans()
      tagList(
        tags$p(class="quiz-q","What does (n & (n-1)) evaluate to when n is a power of 2?"),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="a")"right" else ""),
          "0", onclick=sprintf("Shiny.setInputValue('%s','a',{priority:'event'})",ns("qa"))),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="b")"wrong" else ""),
          "1", onclick=sprintf("Shiny.setInputValue('%s','b',{priority:'event'})",ns("qa"))),
        tags$button(class=paste("qopt",if(!is.null(ans)&&ans=="c")"wrong" else ""),
          "n-1", onclick=sprintf("Shiny.setInputValue('%s','c',{priority:'event'})",ns("qa"))),
        if (!is.null(ans)) {
          if (ans=="a") tags$div(class="qfeedback right","✅ Correct! Powers of 2 have exactly one set bit. n-1 flips all lower bits, so n & (n-1) = 0. Use this to check power-of-2 in O(1).")
          else tags$div(class="qfeedback wrong","❌ n & (n-1) clears the lowest set bit. For a power of 2 (one set bit), the result is 0.")
        }
      )
    })
    observeEvent(input$qa, q_ans(input$qa))
  })
}
