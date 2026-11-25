# modules/mod_bits.R — Bit Manipulation

# One row of bit cells: label, value shown as `width` bits, optional highlighted bit positions (0 = LSB)
bit_row <- function(label, value, width = 8, hl = integer(0), show_val = TRUE) {
  bits <- as.integer(bitwAnd(bitwShiftR(as.integer(value), (width - 1):0), 1L))
  pos  <- (width - 1):0
  tags$div(class = "bit-row",
    tags$span(class = "bit-lab", label),
    lapply(seq_len(width), function(i)
      tags$span(class = paste("bit", if (bits[i] == 1) "on", if (pos[i] %in% hl) "hl", if (pos[i] %% 4 == 3 && i > 1) "gap"), bits[i])),
    if (show_val) tags$span(class = "bit-val", paste0("= ", value))
  )
}
bit_header <- function(width = 8) {
  pos <- (width - 1):0
  tags$div(class = "bit-row",
    tags$span(class = "bit-lab", style = "color:#94a3b8;", "bit index"),
    lapply(seq_len(width), function(i)
      tags$span(class = paste("bit", if (pos[i] %% 4 == 3 && i > 1) "gap"), style = "background:transparent; color:#94a3b8; font-size:9.5px;", pos[i]))
  )
}

bits_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("⚡", "Bit Manipulation",
      "Integers are arrays of bits, and the CPU can operate on all of them at once. A handful of identities — XOR cancels, n & (n−1) clears a bit, a mask is a set — solve a surprising number of problems in O(1) space.",
      c("AND / OR / XOR", "Shifts", "Masks", "XOR Cancellation", "n & (n − 1)", "Bitmask as Set")),

    topic_tabs(ns,
      visual = tagList(
        fluidRow(
          box(title = "Bitwise Operators — see every bit", status = "primary", solidHeader = TRUE, width = 7,
            fluidRow(
              column(6, sliderInput(ns("a"), "A:", min = 0, max = 255, value = 172, step = 1)),
              column(6, sliderInput(ns("b"), "B:", min = 0, max = 255, value = 58, step = 1))
            ),
            uiOutput(ns("ops_viz"))
          ),
          box(title = "Trick Lab", status = "primary", solidHeader = TRUE, width = 5,
            fluidRow(
              column(5, numericInput(ns("t_n"), "n (0–255):", 88, min = 0, max = 255)),
              column(7, selectInput(ns("trick"), "Trick:", c("Is n a power of two?" = "pow2", "Clear the lowest set bit" = "clear", "Isolate the lowest set bit" = "lowbit",
                                                              "Test bit k" = "test", "Set bit k" = "set", "Toggle bit k" = "toggle")))
            ),
            conditionalPanel(sprintf("['test','set','toggle'].indexOf(input['%s']) >= 0", ns("trick")),
              sliderInput(ns("t_k"), "k:", min = 0, max = 7, value = 2, step = 1)),
            uiOutput(ns("trick_viz"))
          )
        ),
        fluidRow(
          box(title = "Counting Set Bits — Brian Kernighan's loop", status = "primary", solidHeader = TRUE, width = 6,
            numericInput(ns("kn_n"), "n (0–255):", 181, min = 0, max = 255),
            stepper_ui(ns, "kn"),
            uiOutput(ns("kn_viz"))
          ),
          box(title = "XOR Cancellation — find the number without a pair", status = "primary", solidHeader = TRUE, width = 6,
            textInput(ns("xr_arr"), "Array (every value twice, except one):", "9,4,6,4,9"),
            stepper_ui(ns, "xr"),
            uiOutput(ns("xr_viz"))
          )
        ),
        fluidRow(
          box(title = "A Bitmask Is a Set", status = "primary", solidHeader = TRUE, width = 6,
            textInput(ns("bm_items"), "Items (2–4):", "A,B,C"),
            uiOutput(ns("bm_viz")),
            hint("Counting from 0 to 2ⁿ − 1 enumerates every subset: bit i of the counter says whether item i is in. This is the iterative alternative to backtracking and the basis of bitmask DP.")
          ),
          box(title = "Popcount has a pattern — Counting Bits (#338)", status = "primary", solidHeader = TRUE, width = 6,
            plotlyOutput(ns("pc_plot"), height = "260px"),
            hint("<code>bits[i] = bits[i >> 1] + (i & 1)</code>: dropping the last bit gives a number already solved. The self-similar staircase is that recurrence made visible — each block of 2ᵏ repeats the previous block, plus one.")
          )
        )
      ),

      learn = tagList(
        insight_cards(
          when = c("'Every element appears twice except one' / 'find the missing number' → XOR.",
                   "Power-of-two checks, counting 1-bits, lowest set bit → <code>n &amp; (n − 1)</code> and <code>n &amp; −n</code>.",
                   "Small sets (n ≤ 20) whose membership is part of the state → bitmask (subset enumeration, bitmask DP).",
                   "Flags and permissions packed into one integer."),
          pitfalls = c("Operator precedence: <code>==</code> binds tighter than <code>&amp;</code> in C / Java / Python — write <code>(n &amp; 1) == 0</code>.",
                       "Python integers are unbounded: negative numbers have infinitely many leading 1s. Mask with <code>&amp; 0xFFFFFFFF</code> to emulate 32 bits.",
                       "Arithmetic vs logical right shift on negatives (<code>&gt;&gt;</code> vs <code>&gt;&gt;&gt;</code> in Java).",
                       "<code>1 &lt;&lt; 31</code> overflows a signed 32-bit int in C / Java."),
          tips = c("Write out a 4-bit example on the whiteboard; bit tricks are easy to verify by hand.",
                   "Know the three XOR facts: <code>a ^ a = 0</code>, <code>a ^ 0 = a</code>, and order does not matter.",
                   "A bit solution is usually the follow-up: give the hash-set answer first, then offer O(1) space with XOR.")
        ),
        fluidRow(
          box(title = "Operators", status = "info", solidHeader = TRUE, width = 5,
            cplx_table(data.frame(
              Op = c("a &amp; b", "a | b", "a ^ b", "~a", "a &lt;&lt; k", "a &gt;&gt; k"),
              Name = c("AND", "OR", "XOR", "NOT", "Left shift", "Right shift"),
              Bit.is.1.when = c("both are 1", "either is 1", "they differ", "it was 0", "moves up k places (× 2ᵏ)", "moves down k places (÷ 2ᵏ, floor)"),
              Typical.use = c("mask / test bits", "set bits", "toggle, cancel pairs", "invert a mask", "build 1 &lt;&lt; k", "walk through bits"),
              stringsAsFactors = FALSE))
          ),
          box(title = "The identities to know cold", status = "info", solidHeader = TRUE, width = 7,
            cplx_table(data.frame(
              Expression = c("n &amp; (n − 1)", "n &amp; −n", "n &amp; (n − 1) == 0 and n &gt; 0", "(n &gt;&gt; k) &amp; 1", "n | (1 &lt;&lt; k)", "n &amp; ~(1 &lt;&lt; k)", "n ^ (1 &lt;&lt; k)", "a ^ b ^ a", "(1 &lt;&lt; n) − 1"),
              Effect = c("Clears the lowest set bit", "Isolates the lowest set bit", "n is a power of two", "Reads bit k", "Sets bit k", "Clears bit k", "Toggles bit k", "= b (pairs cancel)", "Mask of n ones — the 'full set'"),
              stringsAsFactors = FALSE)),
            callout("<b>Two's complement:</b> −n is stored as ~n + 1. That is why <code>n &amp; −n</code> keeps exactly the lowest set bit, and why −1 is all ones.", "info")
          )
        ),
        fluidRow(
          box(title = "Templates worth memorising (Python)", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(4,
                dsa_code(
'def singleNumber(nums):
    x = 0
    for n in nums:
        x ^= n            # pairs cancel to 0
    return x', "Single number — O(1) space"),
                dsa_code(
'def missingNumber(nums):     # 0..n with one missing
    x = len(nums)
    for i, v in enumerate(nums):
        x ^= i ^ v
    return x', "Missing number — XOR indices and values")
              ),
              column(4,
                dsa_code(
'def hammingWeight(n):
    count = 0
    while n:
        n &= n - 1        # drop lowest set bit
        count += 1
    return count', "Count set bits — one loop per 1-bit"),
                dsa_code(
'def countBits(n):
    bits = [0] * (n + 1)
    for i in range(1, n + 1):
        bits[i] = bits[i >> 1] + (i & 1)
    return bits', "Counting bits — DP")
              ),
              column(4,
                dsa_code(
'def subsets(nums):
    n = len(nums)
    return [[nums[i] for i in range(n) if mask >> i & 1]
            for mask in range(1 << n)]', "All subsets by counting"),
                dsa_code(
'def getSum(a, b):            # no + or -
    MASK = 0xFFFFFFFF
    while b & MASK:
        a, b = a ^ b, (a & b) << 1   # sum, carry
    return a & MASK if b > 0 else a', "Add with XOR and carry")
              )
            )
          )
        )
      ),

      practice = practice_tab(ns, "bits",
        "Warren, H. S. (2012). Hacker's Delight (2nd ed.). Addison-Wesley.",
        "Kernighan & Ritchie (1988). The C Programming Language (2nd ed.) — exercise 2-9, clearing the rightmost bit.",
        "Knuth, D. E. (2009). The Art of Computer Programming, Vol. 4 Fascicle 1: Bitwise Tricks & Techniques.")
    )
  )
}

bits_server <- function(id, progress = NULL) {
  moduleServer(id, function(input, output, session) {

    byte <- function(x) { x <- suppressWarnings(as.integer(x)); if (length(x) != 1 || is.na(x)) return(NA); max(0L, min(255L, x)) }

    output$ops_viz <- renderUI({
      a <- byte(input$a); b <- byte(input$b); req(!is.na(a), !is.na(b))
      tagList(
        bit_header(), bit_row("A", a), bit_row("B", b),
        tags$hr(style = "margin:8px 0;"),
        bit_row("A & B", bitwAnd(a, b)), bit_row("A | B", bitwOr(a, b)), bit_row("A ^ B", bitwXor(a, b)),
        tags$hr(style = "margin:8px 0;"),
        bit_row("~A (8-bit)", bitwAnd(bitwNot(a), 255L)), bit_row("A << 1", bitwAnd(bitwShiftL(a, 1L), 255L)), bit_row("A >> 1", bitwShiftR(a, 1L)),
        explain(sprintf("AND keeps the bits both share (%d in common). OR collects all bits from either. XOR marks the positions where they <b>differ</b> — %d bit(s), which is their Hamming distance. Shifting left doubles (the top bit falls off in 8 bits); shifting right halves.",
                        sum(bitwAnd(bitwShiftR(bitwAnd(a, b), 0:7), 1L)), sum(bitwAnd(bitwShiftR(bitwXor(a, b), 0:7), 1L))))
      )
    })

    output$trick_viz <- renderUI({
      n <- byte(input$t_n); k <- input$t_k %||% 0
      validate(need(!is.na(n), "Enter n between 0 and 255."))
      low <- if (n == 0) integer(0) else which(bitwAnd(bitwShiftR(n, 0:7), 1L) == 1)[1] - 1
      switch(input$trick,
        pow2 = { r <- bitwAnd(n, max(n - 1L, 0L)); yes <- n > 0 && r == 0
          tagList(bit_header(), bit_row("n", n, hl = low), bit_row("n − 1", max(n - 1L, 0L)), bit_row("n & (n−1)", r),
            explain(sprintf("A power of two has exactly one 1-bit. Subtracting 1 flips that bit and everything below it, so the AND is zero. Here the result is %d → n is %s a power of two.", r, if (yes) "<b>✓</b>" else "<b>not</b>"))) },
        clear = { r <- bitwAnd(n, max(n - 1L, 0L))
          tagList(bit_header(), bit_row("n", n, hl = low), bit_row("n − 1", max(n - 1L, 0L)), bit_row("n & (n−1)", r),
            explain("Subtracting 1 turns the lowest 1 into 0 and the zeros beneath it into ones; ANDing with the original wipes exactly that lowest 1 and leaves the rest untouched.")) },
        lowbit = { neg <- bitwAnd(bitwNot(n) + 1L, 255L); r <- bitwAnd(n, neg)
          tagList(bit_header(), bit_row("n", n, hl = low), bit_row("−n (8-bit)", neg), bit_row("n & −n", r, hl = low),
            explain(sprintf("In two's complement −n = ~n + 1, which agrees with n only at the lowest set bit. The AND isolates it: <b>%d</b>. This is the step size in a Fenwick (binary indexed) tree.", r))) },
        test = { m <- bitwShiftL(1L, k); r <- bitwAnd(n, m)
          tagList(bit_header(), bit_row("n", n, hl = k), bit_row(sprintf("1 << %d", k), m, hl = k), bit_row("n & mask", r, hl = k),
            explain(sprintf("A mask with a single 1 at position %d. AND is non-zero only if n has that bit → bit %d is <b>%s</b>.", k, k, if (r != 0) "set" else "clear"))) },
        set = { m <- bitwShiftL(1L, k); r <- bitwOr(n, m)
          tagList(bit_header(), bit_row("n", n, hl = k), bit_row(sprintf("1 << %d", k), m, hl = k), bit_row("n | mask", r, hl = k),
            explain(sprintf("OR with the mask forces bit %d to 1 and leaves every other bit alone: %d → <b>%d</b>.", k, n, r))) },
        toggle = { m <- bitwShiftL(1L, k); r <- bitwXor(n, m)
          tagList(bit_header(), bit_row("n", n, hl = k), bit_row(sprintf("1 << %d", k), m, hl = k), bit_row("n ^ mask", r, hl = k),
            explain(sprintf("XOR with 1 flips a bit; XOR with 0 keeps it. So only bit %d changes: %d → <b>%d</b>.", k, n, r))) })
    })

    # ── Kernighan ────────────────────────────────────────────────────────────
    kn_steps <- reactive({
      n <- byte(input$kn_n); validate(need(!is.na(n), "Enter n between 0 and 255."))
      steps <- list(list(n = n, prev = NA, cnt = 0, msg = sprintf("n = %d. Each pass removes exactly one 1-bit, so the loop runs once per set bit — not once per bit.", n)))
      cnt <- 0
      while (n > 0) {
        prev <- n; n <- bitwAnd(n, n - 1L); cnt <- cnt + 1
        steps[[length(steps) + 1]] <- list(n = n, prev = prev, cnt = cnt,
          msg = sprintf("%d &amp; %d = <b>%d</b> — the lowest set bit is gone. Count = %d.", prev, prev - 1L, n, cnt))
      }
      steps[[length(steps)]]$msg <- paste(steps[[length(steps)]]$msg, sprintf("<b>n is 0 → stop. Popcount = %d.</b>", cnt))
      steps
    })
    kn <- stepper_server(input, output, session, "kn", kn_steps)
    output$kn_viz <- renderUI({
      s <- kn$cur()
      tagList(bit_header(),
        if (!is.na(s$prev)) tagList(
          bit_row("n", s$prev, hl = which(bitwAnd(bitwShiftR(s$prev, 0:7), 1L) == 1)[1] - 1),
          bit_row("n − 1", s$prev - 1L),
          bit_row("n & (n−1)", s$n))
        else bit_row("n", s$n),
        kpi_row(kpi(s$cnt, "bits counted", COL$pri), kpi(sum(bitwAnd(bitwShiftR(s$n, 0:7), 1L)), "bits remaining", COL$warn)),
        explain(s$msg))
    })

    # ── XOR single number ────────────────────────────────────────────────────
    xr_arr <- reactive({
      v <- parse_ints(input$xr_arr, 12)
      validate(need(length(v) >= 1 && all(v >= 0 & v <= 255), "Enter integers between 0 and 255."))
      v
    })
    xr_steps <- reactive({
      a <- xr_arr(); acc <- 0L
      steps <- list(list(i = 0, acc = 0L, prev = 0L, msg = "Start with 0 (the identity for XOR) and fold every element in."))
      for (i in seq_along(a)) {
        prev <- acc; acc <- bitwXor(acc, a[i])
        again <- a[i] %in% a[seq_len(i - 1)]
        steps[[length(steps) + 1]] <- list(i = i, acc = acc, prev = prev,
          msg = sprintf("%d ^ %d = <b>%d</b>.%s", prev, a[i], acc, if (again) sprintf(" This is the second %d — its bits just cancelled out.", a[i]) else ""))
      }
      steps[[length(steps)]]$msg <- paste(steps[[length(steps)]]$msg, sprintf("<b>Everything paired has vanished; what remains is %d.</b>", acc))
      steps
    })
    xr <- stepper_server(input, output, session, "xr", xr_steps)
    output$xr_viz <- renderUI({
      a <- xr_arr(); s <- xr$cur()
      cls <- ifelse(seq_along(a) < s$i, "dim", ""); if (s$i >= 1) cls[s$i] <- "active"
      tagList(vrow(a, cls, idx = FALSE),
        tags$div(style = "margin-top:10px;", bit_header(),
          if (s$i >= 1) tagList(bit_row("running", s$prev), bit_row(paste0("^ ", a[s$i]), a[s$i], show_val = FALSE)),
          bit_row("result", s$acc)),
        explain(s$msg))
    })

    # ── Bitmask subsets ──────────────────────────────────────────────────────
    output$bm_viz <- renderUI({
      it <- trimws(strsplit(input$bm_items %||% "", ",")[[1]]); it <- head(unique(it[nzchar(it)]), 4)
      validate(need(length(it) >= 2, "Enter 2 to 4 items."))
      n <- length(it)
      df <- data.frame(Mask = 0:(2^n - 1), stringsAsFactors = FALSE)
      df$Binary <- vapply(df$Mask, function(m) paste(rev(as.integer(bitwAnd(bitwShiftR(m, 0:(n - 1)), 1L))), collapse = ""), "")
      df$Subset <- vapply(df$Mask, function(m) { on <- bitwAnd(bitwShiftR(m, 0:(n - 1)), 1L) == 1; if (any(on)) paste0("{", paste(it[on], collapse = ", "), "}") else "∅" }, "")
      df$Size <- vapply(df$Mask, function(m) sum(bitwAnd(bitwShiftR(m, 0:(n - 1)), 1L)), numeric(1))
      tagList(
        tags$div(style = "max-height:270px; overflow-y:auto;", cplx_table(df)),
        callout(sprintf("Bit 0 (rightmost) ↔ <b>%s</b>, bit %d (leftmost) ↔ <b>%s</b>. Set operations become single instructions: union <code>a | b</code>, intersection <code>a &amp; b</code>, membership <code>mask >> i &amp; 1</code>.", it[1], n - 1, it[n]), "tip"))
    })

    output$pc_plot <- renderPlotly({
      i <- 0:63; pc <- vapply(i, function(x) sum(bitwAnd(bitwShiftR(x, 0:6), 1L)), numeric(1))
      pal <- c("#e0e7ff", "#a5b4fc", "#818cf8", "#6366f1", "#4f46e5", "#4338ca", "#312e81")
      plot_ly(x = i, y = pc, type = "bar", height = 260, marker = list(color = pal[pc + 1]),
              hovertext = sprintf("%d = %s → %d set bit(s)", i, vapply(i, function(x) paste(rev(as.integer(bitwAnd(bitwShiftR(x, 0:5), 1L))), collapse = ""), ""), pc), hoverinfo = "text") %>%
        dsa_layout(xt = "i", yt = "number of 1-bits") %>% layout(xaxis = list(dtick = 8), bargap = 0.1)
    })

    quiz_server(input, output, session, topic = "bits", progress = progress, questions = list(
      list(q = "For a power of two n, <code>n &amp; (n − 1)</code> equals…",
           opts = c("0", "1", "n", "n − 1"), ans = 1,
           why = "A power of two has a single 1-bit; n − 1 has that bit clear and all lower bits set, so they share nothing."),
      list(q = "XOR-ing all of [4, 1, 2, 1, 2] gives…",
           opts = c("0", "4", "7", "10"), ans = 2,
           why = "1 ^ 1 = 0 and 2 ^ 2 = 0, leaving 4 ^ 0 = 4. Order does not matter."),
      list(q = "How many iterations does Kernighan's loop take for n = 0b10010000?",
           opts = c("8", "5", "2", "1"), ans = 3,
           why = "One iteration per set bit. There are two 1-bits, regardless of where they sit."),
      list(q = "Which expression sets bit k of n to 1?",
           opts = c("n &amp; (1 &lt;&lt; k)", "n | (1 &lt;&lt; k)", "n ^ (1 &lt;&lt; k)", "n &gt;&gt; k"), ans = 2,
           why = "OR with a single-bit mask forces that bit on. AND tests it, XOR toggles it."),
      list(q = "The loop <code>for mask in range(1 &lt;&lt; n)</code> is commonly used to…",
           opts = c("Sort n numbers", "Enumerate all 2ⁿ subsets of n items", "Compute n factorial", "Reverse the bits of n"), ans = 2,
           why = "Each value of mask is one membership pattern: bit i set means item i is included.")
    ))
  })
}
