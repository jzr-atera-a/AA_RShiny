# modules/mod_matrix.R — Matrices & Intervals: traversal orders, sweep lines, interval two-pointers.

matrix_ui <- function(id) {
  ns <- NS(id)
  tagList(
    topic_hero("🧮", "Matrices & Intervals",
      "Two families that interviews love because they punish off-by-one errors: walking a grid in an unusual order, and reasoning about intervals with sort-then-sweep.",
      c("Spiral", "Diagonal", "Rotate in place", "Sweep Line", "Difference Array", "Interval Two Pointers")),

    topic_tabs(ns,
      visual = tagList(
        fluidRow(
          box(title = "Matrix Traversals — see the visiting order", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(4, selectInput(ns("mt_kind"), "Pattern:", c("Spiral order (#54)" = "spiral", "Diagonal zig-zag (#498)" = "diag", "Rotate 90° in place (#48)" = "rotate"))),
              column(2, numericInput(ns("mt_r"), "Rows:", 4, min = 1, max = 7)),
              column(2, numericInput(ns("mt_c"), "Cols:", 5, min = 1, max = 7)),
              column(4, stepper_ui(ns, "mt"))
            ),
            uiOutput(ns("mt_grid")),
            legend_row(c("current" = COL$pri, "visited (order shown)" = "#c7d2fe", "not yet" = "#f1f5f9"))
          ),
          box(title = "What the code is doing", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("mt_code")),
            uiOutput(ns("mt_note")))
        ),
        fluidRow(
          box(title = "Sweep Line — the car-pooling / meeting-rooms pattern", status = "primary", solidHeader = TRUE, width = 8,
            fluidRow(
              column(6, textInput(ns("sw_trips"), "Trips (passengers@from-to):", "2@1-5, 3@3-7, 1@6-9, 4@8-12, 2@10-13")),
              column(2, numericInput(ns("sw_cap"), "Capacity:", 5, min = 1)),
              column(4, stepper_ui(ns, "sw"))
            ),
            plotlyOutput(ns("sw_plot"), height = "330px"),
            uiOutput(ns("sw_viz"))
          ),
          box(title = "Why events beat simulation", status = "info", solidHeader = TRUE, width = 4,
            uiOutput(ns("sw_kpi")),
            callout("Only the moments where something <b>starts or ends</b> can change the load. Turn each interval into two events (+n, −n), sort them, and keep a running total — O(n log n) no matter how long the timeline is.", "tip"),
            callout("Tie-breaking matters: if one trip ends at km 5 and another starts at km 5, process the <b>drop-off first</b> — half-open intervals <code>[from, to)</code>.", "warn"))
        ),
        fluidRow(
          box(title = "Interval List Intersections — two pointers (#986)", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(4, textInput(ns("ii_a"), "List A (sorted, disjoint):", "0-2, 5-10, 13-23, 24-25")),
              column(4, textInput(ns("ii_b"), "List B (sorted, disjoint):", "1-5, 8-12, 15-24, 25-26")),
              column(4, stepper_ui(ns, "ii"))
            ),
            plotlyOutput(ns("ii_plot"), height = "260px"),
            uiOutput(ns("ii_viz")))
        )
      ),

      learn = tagList(
        insight_cards(
          when = c("'Return the elements in spiral / diagonal / snake order' → boundaries or the r + c / r − c invariant.",
                   "'In place' matrix transforms → decompose (rotate = transpose + reverse rows).",
                   "Max overlap, rooms, capacity, busiest time → <b>sweep line</b> over sorted start / end events.",
                   "Two sorted interval lists → two pointers, advancing whichever interval ends first."),
          pitfalls = c("Visiting the last remaining row or column twice in spiral order — guard with <code>top &lt; bottom</code> and <code>left &lt; right</code>.",
                       "Confusing <code>matrix[r][c]</code> with <code>matrix[x][y]</code>: rows are y, columns are x.",
                       "Closed vs half-open intervals: decide whether touching intervals overlap, then sort ties accordingly.",
                       "Mutating the matrix while you still need the original values (set-zeroes) — use markers or a copy."),
          tips = c("Say the invariant: 'cells on one anti-diagonal share r + c'.",
                   "Draw a 3×4 example — non-square matrices expose most bugs.",
                   "For intervals, always ask: sorted? disjoint? closed or half-open? can they be empty?")
        ),
        fluidRow(
          box(title = "Patterns at a glance", status = "info", solidHeader = TRUE, width = 6,
            cplx_table(data.frame(
              Problem = c("Spiral order", "Diagonal traverse", "Rotate image", "Set matrix zeroes", "Merge intervals", "Insert interval", "Meeting rooms / car pooling", "Skyline"),
              Key.idea = c("4 shrinking boundaries", "group by r + c, alternate", "transpose + reverse rows", "first row / col as flags", "sort by start, extend", "before / overlapping / after", "+n / −n events, running sum", "sweep + max-heap of heights"),
              Time = c("O(mn)", "O(mn)", "O(n²)", "O(mn)", "O(n log n)", "O(n)", "O(n log n)", "O(n log n)"),
              Space = c("O(1)", "O(1)", "O(1)", "O(1)", "O(n)", "O(n)", "O(n)", "O(n)"),
              stringsAsFactors = FALSE))),
          box(title = "Coordinates cheat-sheet", status = "info", solidHeader = TRUE, width = 6,
            cplx_table(data.frame(
              Fact = c("Main diagonal", "Anti-diagonal", "Rotate 90° clockwise", "Rotate 90° counter-clockwise", "4 neighbours", "8 neighbours", "Flatten index"),
              Formula = c("r − c constant", "r + c constant", "(r, c) → (c, n−1−r)", "(r, c) → (n−1−c, r)", "(±1, 0), (0, ±1)", "dr, dc ∈ {−1, 0, 1}, not both 0", "i = r · C + c,  r = i // C,  c = i % C"),
              stringsAsFactors = FALSE)))
        ),
        fluidRow(
          box(title = "Templates worth memorising (Python)", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(4, dsa_code(
'def rotate(matrix):                # 90° clockwise, in place
    n = len(matrix)
    for i in range(n):              # transpose
        for j in range(i + 1, n):
            matrix[i][j], matrix[j][i] = matrix[j][i], matrix[i][j]
    for row in matrix:              # reverse each row
        row.reverse()', "Rotate image"),
                dsa_code(
'def setZeroes(m):
    R, C = len(m), len(m[0])
    rows = {r for r in range(R) for c in range(C) if m[r][c] == 0}
    cols = {c for r in range(R) for c in range(C) if m[r][c] == 0}
    for r in range(R):
        for c in range(C):
            if r in rows or c in cols:
                m[r][c] = 0', "Set matrix zeroes (O(R + C) space)")),
              column(4, dsa_code(
'def insert(intervals, new):
    out, i, n = [], 0, len(intervals)
    while i < n and intervals[i][1] < new[0]:     # before
        out.append(intervals[i]); i += 1
    while i < n and intervals[i][0] <= new[1]:    # overlapping
        new = [min(new[0], intervals[i][0]), max(new[1], intervals[i][1])]
        i += 1
    out.append(new)
    return out + intervals[i:]                    # after', "Insert interval")),
              column(4, dsa_code(
'def max_overlap(intervals):        # half-open [s, e)
    events = []
    for s, e in intervals:
        events += [(s, 1), (e, -1)]
    best = cur = 0
    for _, d in sorted(events):     # -1 sorts before +1 at a tie
        cur += d
        best = max(best, cur)
    return best', "Sweep line"),
                dsa_code(
'diff = [0] * (MAX + 1)             # difference array
for n, a, b in trips:
    diff[a] += n
    diff[b] -= n
load = 0
for x in diff:
    load += x                       # prefix sum = load at each point', "Difference array")))
          )
        )
      ),

      practice = practice_tab(ns, "matrix",
        "Cormen, Leiserson, Rivest & Stein (2022). Introduction to Algorithms (4th ed.) — ch. 33, sweep-line techniques.",
        "de Berg, Cheong, van Kreveld & Overmars (2008). Computational Geometry (3rd ed.) — plane sweep.",
        "Laakmann McDowell (2015). Cracking the Coding Interview (6th ed.) — matrix problems.")
    )
  )
}

matrix_server <- function(id, progress = NULL) {
  moduleServer(id, function(input, output, session) {

    # ── Matrix traversals ────────────────────────────────────────────────────
    mt_dims <- reactive({
      R <- max(1, min(7, as.integer(input$mt_r %||% 4))); C <- max(1, min(7, as.integer(input$mt_c %||% 5)))
      if (input$mt_kind == "rotate") C <- R
      validate(need(!is.na(R) && !is.na(C), "Enter rows and columns."))
      list(R = R, C = C)
    })
    mt_steps <- reactive({
      d <- mt_dims(); R <- d$R; C <- d$C; M <- matrix(seq_len(R * C), R, C, byrow = TRUE)
      steps <- list()
      if (input$mt_kind == "spiral") {
        top <- 1; bottom <- R; left <- 1; right <- C; order <- list(); side <- character(0)
        while (top <= bottom && left <= right) {
          for (c in left:right) { order[[length(order) + 1]] <- c(top, c); side <- c(side, "top row, left → right") }
          if (top < bottom) for (r in (top + 1):bottom) { order[[length(order) + 1]] <- c(r, right); side <- c(side, "right column, downwards") }
          if (top < bottom && left < right) for (c in (right - 1):left) { order[[length(order) + 1]] <- c(bottom, c); side <- c(side, "bottom row, right → left") }
          if (left < right && bottom - 1 >= top + 1) for (r in (bottom - 1):(top + 1)) { order[[length(order) + 1]] <- c(r, left); side <- c(side, "left column, upwards") }
          top <- top + 1; bottom <- bottom - 1; left <- left + 1; right <- right - 1
        }
        for (k in seq_along(order)) steps[[k]] <- list(M = M, cur = order[[k]], visited = order[seq_len(k)], line = 2:5,
          msg = sprintf("Visit (%d, %d) = <b>%d</b> — walking the %s. Output so far has %d of %d values.", order[[k]][1] - 1, order[[k]][2] - 1, M[order[[k]][1], order[[k]][2]], side[k], k, R * C))
      } else if (input$mt_kind == "diag") {
        order <- list(); dd <- integer(0)
        for (s in 0:(R + C - 2)) {
          rows <- max(0, s - C + 1):min(R - 1, s)
          cells <- lapply(rows, function(r) c(r + 1, s - r + 1))
          if (s %% 2 == 0) cells <- rev(cells)
          order <- c(order, cells); dd <- c(dd, rep(s, length(cells)))
        }
        for (k in seq_along(order)) steps[[k]] <- list(M = M, cur = order[[k]], visited = order[seq_len(k)], line = if (dd[k] %% 2 == 0) 3:4 else 3,
          msg = sprintf("Anti-diagonal r + c = <b>%d</b> (%s): visit (%d, %d) = %d.", dd[k], if (dd[k] %% 2 == 0) "even → walk up-right" else "odd → walk down-left",
                        order[[k]][1] - 1, order[[k]][2] - 1, M[order[[k]][1], order[[k]][2]]))
      } else {
        n <- R; A <- M
        steps[[1]] <- list(M = A, cur = NULL, visited = list(), line = 1, msg = "Rotate clockwise in place = <b>transpose</b> (swap across the main diagonal) then <b>reverse each row</b>.")
        for (i in seq_len(n)) for (j in seq_len(n)) if (j > i) {
          t <- A[i, j]; A[i, j] <- A[j, i]; A[j, i] <- t
          steps[[length(steps) + 1]] <- list(M = A, cur = c(i, j), cur2 = c(j, i), visited = list(), line = 2:4,
                                             msg = sprintf("Transpose: swap (%d, %d) ↔ (%d, %d).", i - 1, j - 1, j - 1, i - 1))
        }
        for (i in seq_len(n)) {
          A[i, ] <- rev(A[i, ])
          steps[[length(steps) + 1]] <- list(M = A, cur = NULL, row = i, visited = list(), line = 5:6, msg = sprintf("Reverse row %d.", i - 1))
        }
        steps[[length(steps)]]$msg <- paste(steps[[length(steps)]]$msg, "<b>Done — the matrix is rotated 90° clockwise using O(1) extra space.</b>")
      }
      steps
    })
    mt <- stepper_server(input, output, session, "mt", mt_steps, speed = 450)
    output$mt_grid <- renderUI({
      s <- mt$cur(); M <- s$M; R <- nrow(M); C <- ncol(M)
      show <- M; cls <- matrix("g-todo", R, C)
      if (input$mt_kind == "rotate") { cls[] <- ""; if (!is.null(s$row)) cls[s$row, ] <- "g-path" }
      for (k in seq_along(s$visited)) { v <- s$visited[[k]]; cls[v[1], v[2]] <- ""; show[v[1], v[2]] <- paste0(M[v[1], v[2]], "·", k) }
      if (!is.null(s$cur)) cls[s$cur[1], s$cur[2]] <- "g-cur"
      if (!is.null(s$cur2)) cls[s$cur2[1], s$cur2[2]] <- "g-dep"
      if (input$mt_kind != "rotate") show <- ifelse(cls == "g-todo", M, show)
      out <- vapply(s$visited, function(v) M[v[1], v[2]], numeric(1))
      tagList(dp_grid(show, 0:(R - 1), 0:(C - 1), cls),
              if (input$mt_kind != "rotate") lane("output", out, "visited", "—"),
              explain(s$msg))
    })
    output$mt_code <- renderUI({
      pseudo(switch(input$mt_kind,
        spiral = c("while top <= bottom and left <= right:", "    walk top row (left → right)", "    walk right column (down)",
                   "    if top < bottom: walk bottom row (right → left)", "    if left < right: walk left column (up)", "    shrink all four boundaries"),
        diag = c("for d in range(R + C - 1):", "    cells = [(r, d - r) for valid r]   # r ascending", "    if d % 2 == 0:", "        cells.reverse()          # up-right", "    output.extend(cells)"),
        rotate = c("# clockwise = transpose, then mirror", "for i in range(n):", "    for j in range(i + 1, n):", "        swap m[i][j], m[j][i]", "for row in m:", "    row.reverse()")),
        active = mt$cur()$line)
    })
    output$mt_note <- renderUI({
      callout(switch(input$mt_kind,
        spiral = "The boundaries shrink after each lap. The two guards stop a single middle row or column being walked twice — try 1 × 5 and 5 × 1.",
        diag = "Every cell on an anti-diagonal has the same <code>r + c</code>, so the diagonal number decides both membership and direction.",
        rotate = "Clockwise = transpose + reverse rows. Counter-clockwise = transpose + reverse columns. Rotating 180° = reverse rows + reverse each row."), "info")
    })

    # ── Sweep line ───────────────────────────────────────────────────────────
    sw_data <- reactive({
      tok <- trimws(strsplit(input$sw_trips %||% "", ",")[[1]])
      m <- regmatches(tok, regexec("^(\\d+)\\s*@\\s*(\\d+)\\s*-\\s*(\\d+)$", tok)); m <- m[vapply(m, length, 1L) == 4]
      validate(need(length(m) >= 1, "Enter trips like 2@1-5 (2 passengers from km 1 to km 5)."))
      d <- data.frame(n = as.numeric(vapply(m, `[`, "", 2)), a = as.numeric(vapply(m, `[`, "", 3)), b = as.numeric(vapply(m, `[`, "", 4)))
      d <- head(d[d$b > d$a, , drop = FALSE], 10)
      validate(need(nrow(d) >= 1, "Each trip needs from < to."))
      d$id <- seq_len(nrow(d)); d
    })
    sw_steps <- reactive({
      d <- sw_data(); cap <- input$sw_cap %||% 5
      ev <- rbind(data.frame(x = d$a, delta = d$n, id = d$id, kind = "board"), data.frame(x = d$b, delta = -d$n, id = d$id, kind = "leave"))
      ev <- ev[order(ev$x, ev$delta), ]
      load <- 0; peak <- 0; steps <- list(list(k = 0, load = 0, x = min(ev$x) - 0.5, peak = 0, over = FALSE, ev = ev,
        msg = sprintf("Turn %d trips into %d events and sort by position (drop-offs before pick-ups at the same km).", nrow(d), nrow(ev))))
      for (k in seq_len(nrow(ev))) {
        load <- load + ev$delta[k]; peak <- max(peak, load)
        steps[[length(steps) + 1]] <- list(k = k, load = load, x = ev$x[k], peak = peak, over = load > cap, ev = ev,
          msg = sprintf("km %g: trip %d %s %d → load <b>%g</b>%s", ev$x[k], ev$id[k], if (ev$kind[k] == "board") "picks up" else "drops off", abs(ev$delta[k]), load,
                        if (load > cap) sprintf(" &gt; capacity %g — <b>impossible</b>.", cap) else sprintf(" (capacity %g).", cap)))
      }
      steps
    })
    sw <- stepper_server(input, output, session, "sw", sw_steps, speed = 700)
    output$sw_plot <- renderPlotly({
      d <- sw_data(); s <- sw$cur(); ev <- s$ev; cap <- input$sw_cap %||% 5
      done <- ev[seq_len(s$k), ]
      active <- vapply(d$id, function(i) any(done$id == i & done$kind == "board") && !any(done$id == i & done$kind == "leave"), logical(1))
      finished <- vapply(d$id, function(i) any(done$id == i & done$kind == "leave"), logical(1))
      cols <- ifelse(active, COL$pri, ifelse(finished, COL$idle, "#e0e7ff"))
      xs <- c(min(ev$x) - 1, ev$x[seq_len(s$k)]); ys <- c(0, cumsum(ev$delta[seq_len(s$k)]))
      p1 <- plot_ly(height = 330) %>%
        add_bars(y = paste("trip", d$id), x = d$b - d$a, base = d$a, orientation = "h", marker = list(color = cols),
                 text = paste0(d$n, " pax"), textposition = "inside", insidetextfont = list(color = "#fff"), hoverinfo = "text",
                 hovertext = sprintf("trip %d: %g passengers, km %g–%g", d$id, d$n, d$a, d$b), showlegend = FALSE) %>%
        layout(yaxis = list(autorange = "reversed", title = ""), xaxis = list(range = c(min(ev$x) - 1, max(ev$x) + 1)))
      p2 <- plot_ly(height = 330) %>%
        add_trace(x = xs, y = ys, type = "scatter", mode = "lines+markers", line = list(shape = "hv", color = if (s$over) COL$err else COL$ok, width = 3),
                  marker = list(color = if (s$over) COL$err else COL$ok), showlegend = FALSE, hoverinfo = "x+y") %>%
        layout(yaxis = list(title = "load", range = c(0, max(cap, max(cumsum(ev$delta))) * 1.2)),
               shapes = list(list(type = "line", x0 = min(ev$x) - 1, x1 = max(ev$x) + 1, y0 = cap, y1 = cap, line = list(color = COL$err, dash = "dash"))))
      subplot(p1, p2, nrows = 2, shareX = TRUE, heights = c(0.55, 0.45), titleY = TRUE) %>%
        dsa_layout(xt = "kilometre") %>%
        layout(shapes = list(list(type = "line", xref = "x", yref = "paper", x0 = s$x, x1 = s$x, y0 = 0, y1 = 1, line = list(color = COL$warn, width = 2, dash = "dot")),
                             list(type = "line", xref = "x2", yref = "y2", x0 = min(ev$x) - 1, x1 = max(ev$x) + 1, y0 = cap, y1 = cap, line = list(color = COL$err, dash = "dash"))))
    })
    output$sw_viz <- renderUI({
      s <- sw$cur(); ev <- s$ev
      lab <- sprintf("%g:%s%g", ev$x, ifelse(ev$delta > 0, "+", "−"), abs(ev$delta))
      cls <- ifelse(seq_len(nrow(ev)) <= s$k, "visited", ""); if (s$k > 0) cls[s$k] <- if (s$over) "bad" else "active"
      tagList(tags$div(class = "code-title", "Sorted events (km : change)"), vrow(lab, cls, idx = FALSE, wide = TRUE), explain(s$msg))
    })
    output$sw_kpi <- renderUI({
      s <- sw$cur(); cap <- input$sw_cap %||% 5; ok <- max(cumsum(s$ev$delta)) <= cap
      kpi_row(kpi(s$load, "current load", if (s$over) COL$err else COL$pri), kpi(s$peak, "peak so far", COL$warn),
              kpi(if (ok) "true" else "false", "can finish all trips?", if (ok) COL$ok else COL$err))
    })

    # ── Interval intersections ───────────────────────────────────────────────
    parse_iv <- function(txt) {
      tok <- trimws(strsplit(txt %||% "", ",")[[1]])
      m <- regmatches(tok, regexec("^(\\d+)\\s*-\\s*(\\d+)$", tok)); m <- m[vapply(m, length, 1L) == 3]
      if (!length(m)) return(matrix(numeric(0), 0, 2))
      x <- cbind(as.numeric(vapply(m, `[`, "", 2)), as.numeric(vapply(m, `[`, "", 3)))
      x <- x[x[, 2] >= x[, 1], , drop = FALSE]; x[order(x[, 1]), , drop = FALSE]
    }
    ii_steps <- reactive({
      A <- parse_iv(input$ii_a); B <- parse_iv(input$ii_b)
      validate(need(nrow(A) + nrow(B) > 0, "Enter intervals like 1-3, 5-9."))
      i <- 1; j <- 1; out <- matrix(numeric(0), 0, 2)
      steps <- list(list(i = 1, j = 1, out = out, hit = NULL, A = A, B = B, msg = "Pointer i walks list A, j walks list B. Compare the two current intervals."))
      while (i <= nrow(A) && j <= nrow(B)) {
        lo <- max(A[i, 1], B[j, 1]); hi <- min(A[i, 2], B[j, 2]); hit <- NULL
        if (lo <= hi) { out <- rbind(out, c(lo, hi)); hit <- c(lo, hi) }
        adv <- if (A[i, 2] < B[j, 2]) "i" else "j"
        steps[[length(steps) + 1]] <- list(i = i, j = j, out = out, hit = hit, A = A, B = B,
          msg = sprintf("A[%d] = [%g, %g], B[%d] = [%g, %g] → overlap [max starts, min ends] = [%g, %g] %s. %s ends first → advance <b>%s</b>.",
                        i - 1, A[i, 1], A[i, 2], j - 1, B[j, 1], B[j, 2], lo, hi, if (is.null(hit)) "is empty" else "→ <b>record it</b>",
                        if (adv == "i") "A's interval" else "B's interval", adv))
        if (adv == "i") i <- i + 1 else j <- j + 1
      }
      steps[[length(steps) + 1]] <- list(i = i, j = j, out = out, hit = NULL, A = A, B = B,
        msg = sprintf("One list is exhausted → nothing else can overlap. <b>%d intersection(s)</b> in O(m + n).", nrow(out)))
      steps
    })
    ii <- stepper_server(input, output, session, "ii", ii_steps)
    output$ii_plot <- renderPlotly({
      s <- ii$cur(); A <- s$A; B <- s$B
      ca <- ifelse(seq_len(nrow(A)) < s$i, COL$idle, ifelse(seq_len(nrow(A)) == s$i, COL$pri, "#c7d2fe"))
      cb <- ifelse(seq_len(nrow(B)) < s$j, COL$idle, ifelse(seq_len(nrow(B)) == s$j, COL$sec, "#ddd6fe"))
      p <- plot_ly(height = 260)
      if (nrow(A)) p <- add_bars(p, y = rep("A", nrow(A)), x = A[, 2] - A[, 1] + 0.001, base = A[, 1], orientation = "h", marker = list(color = ca, line = list(color = "#fff", width = 2)), name = "A",
                                 text = sprintf("[%g,%g]", A[, 1], A[, 2]), textposition = "inside", hoverinfo = "text", hovertext = sprintf("A: [%g, %g]", A[, 1], A[, 2]))
      if (nrow(B)) p <- add_bars(p, y = rep("B", nrow(B)), x = B[, 2] - B[, 1] + 0.001, base = B[, 1], orientation = "h", marker = list(color = cb, line = list(color = "#fff", width = 2)), name = "B",
                                 text = sprintf("[%g,%g]", B[, 1], B[, 2]), textposition = "inside", hoverinfo = "text", hovertext = sprintf("B: [%g, %g]", B[, 1], B[, 2]))
      if (nrow(s$out)) p <- add_bars(p, y = rep("A ∩ B", nrow(s$out)), x = s$out[, 2] - s$out[, 1] + 0.15, base = s$out[, 1] - 0.075, orientation = "h",
                                     marker = list(color = COL$ok), name = "intersection", hoverinfo = "text", hovertext = sprintf("[%g, %g]", s$out[, 1], s$out[, 2]))
      p %>% dsa_layout(xt = "position") %>% layout(barmode = "overlay", yaxis = list(categoryorder = "array", categoryarray = c("A ∩ B", "B", "A"), title = ""))
    })
    output$ii_viz <- renderUI({
      s <- ii$cur()
      tagList(lane("output", if (nrow(s$out)) sprintf("[%g,%g]", s$out[, 1], s$out[, 2]) else character(0), "found", "none yet"), explain(s$msg))
    })

    quiz_server(input, output, session, topic = "matrix", progress = progress, questions = list(
      list(q = "Which pair of operations rotates a square matrix 90° clockwise in place?",
           opts = c("Reverse rows, then reverse columns", "Transpose, then reverse each row", "Transpose twice", "Reverse each row, then transpose the anti-diagonal"), ans = 2,
           why = "After transposing, cell (r, c) holds (c, r); mirroring each row moves it to (c, n−1−r), the clockwise position."),
      list(q = "In diagonal traversal, two cells are on the same anti-diagonal exactly when…",
           opts = c("r − c is equal", "r + c is equal", "r · c is equal", "r = c"), ans = 2,
           why = "Moving down-left increases r and decreases c by one, keeping r + c constant."),
      list(q = "Meeting [1, 5) ends and [5, 8) starts at time 5. In the sweep, which event comes first?",
           opts = c("The start at 5", "The end at 5", "Either — it does not matter", "Neither; merge them"), ans = 2,
           why = "With half-open intervals the room is free at 5; processing the end first avoids counting a false overlap."),
      list(q = "Two sorted lists of disjoint intervals: which pointer do you advance after comparing A[i] and B[j]?",
           opts = c("Always i", "The one whose interval starts first", "The one whose interval ends first", "Both"), ans = 3,
           why = "The interval that ends first cannot overlap any later interval of the other list, so it is finished."),
      list(q = "Car pooling with stops at most 1000: the fastest simple approach is…",
           opts = c("Simulate every km for every trip, O(n · 1000)", "A difference array of size 1001 then a prefix sum, O(n + 1000)", "Sort trips by passengers", "A heap of capacities"), ans = 2,
           why = "Add +n at from and −n at to; one prefix pass gives the load at every km.")
    ))
  })
}
