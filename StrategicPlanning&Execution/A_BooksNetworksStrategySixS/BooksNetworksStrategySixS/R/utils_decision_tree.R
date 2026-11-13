# R/utils_decision_tree.R
# ============================================================
# DECISION TREES (Strategic Analysis > Decision-Making & Process)
# ------------------------------------------------------------
# Stored in strategy_diagrams like every other framework: one row per node,
# diagram_type = "decision_tree", diagram_group = "decision_making_process".
#
#   component_type : decision_node | chance_node | end_node | title
#   node_id        : unique id inside the tree (D1, C1, E1 ...)
#   parent_id      : node_id of the parent (empty for the root)
#   branch_label   : label of the branch that leads INTO this node
#   probability    : chance of that branch (only for children of a chance node)
#   cash_flow      : money paid (-) or received (+) when that branch is taken
#   value_numeric  : final payoff of an end node, EXCLUDING the cash flows above it
#   expected_value : expected value at the node when the tree was saved (a snapshot -
#                    always recalculated when the tree is loaded)
#   color_hint     : "best" on the nodes of the recommended plan when saved
#   items_packed   : assumptions behind the numbers (DIAG_ITEM_SEP separated)
#   sequence_order : order among siblings (top to bottom)
#   title row      : label_text = title, sub_text = decision question,
#                    unit_label = currency, metric_name = maximise | minimise
#
# Every number is calculated here in R. The Editing Tool only drafts the
# structure, the wording and (when asked) estimates; it never does the maths.
#
# Value convention (matches the textbook examples): the value of an end node
# is its NET payoff = every cash flow on the path from the root + its final
# payoff. A chance node is worth the probability-weighted average of its
# branches, and a decision node takes its best branch (highest value, or
# lowest when the objective is to minimise cost).
# ============================================================

DT_TYPES <- c("decision", "chance", "end")
DT_TYPE_LABELS <- c(decision = "Decision", chance = "Chance (outcome)", end = "End (payoff)")
DT_PROB_TOL <- 0.001

`%dt||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a

# ---- small helpers -------------------------------------------------------------------------
dt_blank <- function(x) {
  if (is.null(x) || length(x) == 0) return(TRUE)
  x <- x[1]
  if (is.na(x)) return(TRUE)
  tolower(trimws(as.character(x))) %in% c("", "n/a", "na", "none", "null", "-")
}

# Reads a number the way people type it: "2.5m", "-800k", "40%", "\u00a31,200", "(300)" -> -300.
dt_num <- function(x) {
  vapply(as.list(x %dt||% NA), function(v) {
    if (dt_blank(v)) return(NA_real_)
    if (is.numeric(v)) return(as.numeric(v))
    s <- tolower(trimws(as.character(v)))
    neg <- grepl("^\\(.*\\)$", s)
    s <- gsub("[()]", "", s)
    s <- gsub("[\u00a3$\u20ac\u20b9\u00a5,\\s]|usd|gbp|eur|inr", "", s, perl = TRUE)
    s <- gsub("\u2212", "-", s)
    mult <- 1
    if (grepl("%$", s)) { mult <- 0.01; s <- sub("%$", "", s) }
    else if (grepl("(bn|b)$", s)) { mult <- 1e9; s <- sub("(bn|b)$", "", s) }
    else if (grepl("(mm|m)$", s)) { mult <- 1e6; s <- sub("(mm|m)$", "", s) }
    else if (grepl("k$", s)) { mult <- 1e3; s <- sub("k$", "", s) }
    n <- suppressWarnings(as.numeric(s))
    if (is.na(n)) return(NA_real_)
    n <- n * mult
    if (neg) -abs(n) else n
  }, numeric(1), USE.NAMES = FALSE)
}

dt_norm_type <- function(x) {
  s <- tolower(trimws(as.character(x %dt||% "")))
  s <- sub("_node$", "", s)
  ifelse(s %in% c("d", "decision", "choice", "square"), "decision",
  ifelse(s %in% c("c", "chance", "outcome", "event", "uncertainty", "circle"), "chance",
  ifelse(s %in% c("e", "end", "terminal", "payoff", "leaf", "triangle"), "end", s)))
}

DT_CURRENCY_SYMBOL <- c(GBP = "\u00a3", USD = "$", EUR = "\u20ac", INR = "\u20b9", JPY = "\u00a5", CNY = "\u00a5", AUD = "A$", CAD = "C$", CHF = "CHF ")

# Short money format: 2.5M, 520k, 1,250, 12.5. Currency symbol in front when known.
dt_fmt <- function(x, currency = "", digits = 3, sign = FALSE) {
  vapply(x, function(v) {
    if (is.na(v)) return("\u2013")
    a <- abs(v)
    body <- if (a >= 1e9) paste0(signif(a / 1e9, digits), "bn") else if (a >= 1e6) paste0(signif(a / 1e6, digits), "M")
            else if (a >= 1e4) paste0(signif(a / 1e3, digits), "k") else format(round(a, 2), big.mark = ",", trim = TRUE, nsmall = 0)
    cur <- toupper(trimws(currency %dt||% ""))
    sym <- if (cur %in% names(DT_CURRENCY_SYMBOL)) DT_CURRENCY_SYMBOL[[cur]] else if (nzchar(cur)) paste0(cur, " ") else ""
    pre <- if (v < 0) "\u2212" else if (sign && v > 0) "+" else ""
    paste0(pre, sym, body)
  }, character(1), USE.NAMES = FALSE)
}
dt_pct <- function(p) vapply(p, function(v) if (is.na(v)) "\u2013" else paste0(formatC(100 * v, format = "f", digits = if (abs(100 * v - round(100 * v)) < 1e-9) 0 else 1), "%"), "")
dt_p <- function(p) ifelse(is.na(p), "\u2013", sub("\\.?0+$", "", formatC(p, format = "f", digits = 3)))

dt_empty_nodes <- function() data.frame(node_id = character(), parent_id = character(), type = character(), label = character(),
                                        branch = character(), probability = numeric(), cash_flow = numeric(), payoff = numeric(),
                                        notes = character(), stringsAsFactors = FALSE)

dt_new_meta <- function(title = "", question = "", currency = "GBP", objective = "maximise") {
  list(title = title, question = question, currency = currency, objective = objective)
}

# Cleans a node table typed or edited by a person.
# The Editing Tool sometimes repeats an end node's payoff in its cash_flow too; that would count the amount twice.
# Returns the indices of end nodes whose cash flow equals the payoff (those cash flows are then set to 0).
dt_double_counted <- function(type, cash_flow, payoff) {
  type <- dt_norm_type(type); cf <- dt_num(cash_flow); po <- dt_num(payoff)
  which(type == "end" & !is.na(cf) & !is.na(po) & cf != 0 & abs(cf - po) < 1e-9)
}

dt_clean_nodes <- function(nodes) {
  if (is.null(nodes) || nrow(nodes) == 0) return(dt_empty_nodes())
  for (col in names(dt_empty_nodes())) if (!col %in% names(nodes)) nodes[[col]] <- NA
  n <- data.frame(
    node_id = trimws(as.character(nodes$node_id)),
    parent_id = vapply(nodes$parent_id, function(v) if (dt_blank(v)) "" else trimws(as.character(v)), ""),
    type = dt_norm_type(nodes$type),
    label = vapply(nodes$label, function(v) if (dt_blank(v)) "" else as.character(v), ""),
    branch = vapply(nodes$branch, function(v) if (dt_blank(v)) "" else as.character(v), ""),
    probability = dt_num(nodes$probability), cash_flow = dt_num(nodes$cash_flow), payoff = dt_num(nodes$payoff),
    notes = vapply(nodes$notes, function(v) if (dt_blank(v)) "" else as.character(v), ""),
    stringsAsFactors = FALSE)
  n$node_id[is.na(n$node_id)] <- ""
  rownames(n) <- NULL
  n
}

# Next free id with a prefix: D3, C4, E9 ...
dt_next_id <- function(nodes, type) {
  pre <- switch(type, decision = "D", chance = "C", "E")
  used <- nodes$node_id[grepl(paste0("^", pre, "[0-9]+$"), nodes$node_id)]
  k <- if (length(used)) max(as.integer(sub("^.", "", used))) + 1L else 1L
  paste0(pre, k)
}

# ---- validation ----------------------------------------------------------------------------
dt_validate <- function(nodes) {
  err <- character(0); warn <- character(0)
  if (is.null(nodes) || nrow(nodes) == 0) return(list(errors = "The tree is empty: add a decision node to start.", warnings = character(0)))
  nm <- function(i) { l <- nodes$label[i]; if (nzchar(l)) sprintf("%s '%s'", nodes$node_id[i], l) else nodes$node_id[i] }
  if (any(!nzchar(nodes$node_id))) err <- c(err, "Every node needs a Node ID.")
  d <- unique(nodes$node_id[duplicated(nodes$node_id) & nzchar(nodes$node_id)])
  if (length(d)) err <- c(err, sprintf("Node ID used more than once: %s.", paste(d, collapse = ", ")))
  bad <- which(!nodes$type %in% DT_TYPES)
  for (i in bad) err <- c(err, sprintf("%s has an unknown type '%s' (use decision, chance or end).", nm(i), nodes$type[i]))
  roots <- which(!nzchar(nodes$parent_id))
  if (length(roots) == 0) err <- c(err, "No starting node: leave Parent ID empty on the first decision.")
  if (length(roots) > 1) err <- c(err, sprintf("Only one node can have no parent; these have none: %s.", paste(nodes$node_id[roots], collapse = ", ")))
  miss <- which(nzchar(nodes$parent_id) & !nodes$parent_id %in% nodes$node_id)
  for (i in miss) err <- c(err, sprintf("%s points to parent '%s', which does not exist.", nm(i), nodes$parent_id[i]))
  self <- which(nzchar(nodes$parent_id) & nodes$parent_id == nodes$node_id)
  for (i in self) err <- c(err, sprintf("%s is its own parent.", nm(i)))
  if (length(err)) return(list(errors = err, warnings = warn))
  # cycles: every node must reach the root
  par <- setNames(nodes$parent_id, nodes$node_id)
  for (id in nodes$node_id) {
    seen <- character(0); cur <- id
    while (nzchar(cur)) { if (cur %in% seen) { err <- c(err, sprintf("The branches around %s loop back on themselves.", id)); break }; seen <- c(seen, cur); cur <- par[[cur]] }
  }
  if (length(err)) return(list(errors = unique(err), warnings = warn))
  for (i in seq_len(nrow(nodes))) {
    kids <- which(nodes$parent_id == nodes$node_id[i])
    t <- nodes$type[i]
    if (t == "end" && length(kids)) err <- c(err, sprintf("%s is an end node but has branches after it: make it a decision or chance node.", nm(i)))
    if (t != "end" && !length(kids)) err <- c(err, sprintf("%s has no branches: add at least one, or make it an end node.", nm(i)))
    if (t == "decision" && length(kids) == 1) warn <- c(warn, sprintf("%s offers only one option, so there is nothing to choose.", nm(i)))
    if (t == "chance" && length(kids) == 1) warn <- c(warn, sprintf("%s has only one outcome: a chance node normally has two or more.", nm(i)))
    if (t == "chance" && length(kids)) {
      p <- nodes$probability[kids]
      if (any(is.na(p))) err <- c(err, sprintf("Every branch after %s needs a probability (missing on %s).", nm(i), paste(nodes$node_id[kids][is.na(p)], collapse = ", ")))
      else if (any(p < 0 | p > 1)) err <- c(err, sprintf("Probabilities after %s must be between 0 and 1 (e.g. 0.4 or 40%%).", nm(i)))
      else if (abs(sum(p) - 1) > DT_PROB_TOL) err <- c(err, sprintf("Probabilities after %s add up to %s, not 1. Fix them or press 'Normalise probabilities'.", nm(i), dt_p(sum(p))))
    }
    if (t == "decision" && length(kids) && any(!is.na(nodes$probability[kids])))
      warn <- c(warn, sprintf("Probabilities on the options of %s are ignored: the decision maker chooses, chance does not.", nm(i)))
    if (t == "end" && is.na(nodes$payoff[i])) warn <- c(warn, sprintf("%s has no payoff: 0 is used.", nm(i)))
  }
  r <- roots[1]
  if (!is.na(nodes$probability[r])) warn <- c(warn, "The starting node has a probability: it is ignored.")
  if (nodes$type[r] != "decision") warn <- c(warn, "The tree starts with a chance node, so there is no first decision to recommend: only its expected value is shown.")
  list(errors = unique(err), warnings = unique(warn))
}

# Rescales the probabilities after every chance node so they add up to 1.
dt_normalise <- function(nodes) {
  for (i in which(nodes$type == "chance")) {
    kids <- which(nodes$parent_id == nodes$node_id[i])
    if (!length(kids)) next
    p <- nodes$probability[kids]
    if (all(is.na(p))) p[] <- 1 / length(kids)
    else { p[is.na(p)] <- 0; s <- sum(p); p <- if (s > 0) p / s else rep(1 / length(kids), length(kids)) }
    nodes$probability[kids] <- round(p, 6)
  }
  nodes
}

# ---- solver ----------------------------------------------------------------------------------
# Index-based structure, prepared once and re-used by the many evaluations of the sensitivity analysis.
dt_prepare <- function(nodes) {
  n <- nrow(nodes); ids <- nodes$node_id
  par <- match(nodes$parent_id, ids)
  kids <- lapply(seq_len(n), function(i) which(par == i))
  root <- which(is.na(par))[1]
  post <- integer(0)
  visit <- function(i) { for (k in kids[[i]]) visit(k); post <<- c(post, i) }
  visit(root)
  depth <- integer(n); for (i in rev(post)) depth[i] <- if (is.na(par[i])) 0L else depth[par[i]] + 1L
  list(n = n, ids = ids, type = nodes$type, par = par, kids = kids, root = root, post = post, pre = rev(post), depth = depth,
       p = ifelse(is.na(nodes$probability), 0, nodes$probability),
       cf = ifelse(is.na(nodes$cash_flow), 0, nodes$cash_flow),
       payoff = ifelse(is.na(nodes$payoff), 0, nodes$payoff),
       label = nodes$label, branch = nodes$branch)
}

# Rolls the tree back. force = list(node index -> chosen child index) overrides decisions (used for risk profiles).
dt_eval <- function(pr, objective = "maximise", p = pr$p, cf = pr$cf, payoff = pr$payoff, force = NULL) {
  n <- pr$n; V <- numeric(n); best <- rep(NA_integer_, n); cum <- numeric(n)
  for (i in pr$pre) cum[i] <- (if (is.na(pr$par[i])) 0 else cum[pr$par[i]]) + cf[i]
  minimise <- identical(objective, "minimise")
  for (i in pr$post) {
    k <- pr$kids[[i]]
    t <- pr$type[i]
    if (!length(k) || t == "end") { V[i] <- cum[i] + payoff[i]; next }
    if (t == "chance") { V[i] <- sum(p[k] * V[k]); next }
    f <- if (!is.null(force)) force[[as.character(i)]] else NULL
    j <- if (!is.null(f)) f else if (minimise) k[which.min(V[k])] else k[which.max(V[k])]
    best[i] <- j; V[i] <- V[j]
  }
  reach <- numeric(n); reach[pr$root] <- 1
  for (i in pr$pre) {
    if (i == pr$root) next
    pi <- pr$par[i]; t <- pr$type[pi]
    reach[i] <- if (t == "chance") reach[pi] * p[i] else if (t == "decision") reach[pi] * as.numeric(identical(best[pi], i)) else reach[pi]
  }
  list(V = V, best = best, cum = cum, reach = reach)
}

# The plan as a string: the choice at every decision node the plan actually reaches.
dt_policy <- function(pr, ev) {
  d <- which(pr$type == "decision" & ev$reach > 0 & !is.na(ev$best))
  if (!length(d)) return("")
  paste(pr$ids[d], pr$ids[ev$best[d]], sep = "=", collapse = ";")
}

dt_node_name <- function(pr, i) { l <- pr$label[i]; if (nzchar(l)) l else pr$ids[i] }
# "Go ahead \u203a Success \u203a Build large plant \u203a High" - the branches leading to node i (last `keep` of them)
dt_path_name <- function(pr, i, keep = 4) {
  b <- character(0); j <- i
  while (!is.na(pr$par[j])) { b <- c(if (nzchar(pr$branch[j])) pr$branch[j] else pr$ids[j], b); j <- pr$par[j] }
  if (!length(b)) return(dt_node_name(pr, i))
  if (length(b) > keep) b <- c("\u2026", tail(b, keep))
  paste(b, collapse = " \u203a ")
}
# A chance node named by what it is and where it sits: "Market demand (after Build large plant)"
dt_chance_name <- function(pr, i) { p <- pr$par[i]; if (is.na(p)) dt_node_name(pr, i) else sprintf("%s (after %s)", dt_node_name(pr, i), if (nzchar(pr$branch[i])) pr$branch[i] else pr$ids[i]) }
dt_branch_name <- function(pr, i) { b <- pr$branch[i]; if (nzchar(b)) b else dt_node_name(pr, i) }

# Plain-English description of how the plan changed between two evaluations.
dt_policy_change <- function(pr, base, new) {
  d <- which(pr$type == "decision" & (base$reach > 0 | new$reach > 0))
  ch <- d[!is.na(base$best[d]) & !is.na(new$best[d]) & base$best[d] != new$best[d] & new$reach[d] > 0]
  if (!length(ch)) return("")
  paste(vapply(ch, function(i) sprintf("at '%s': %s \u2192 %s", dt_node_name(pr, i), dt_branch_name(pr, base$best[i]), dt_branch_name(pr, new$best[i])), ""), collapse = "; ")
}

# Full analysis of a valid tree.
dt_solve <- function(nodes, meta) {
  objective <- meta$objective %dt||% "maximise"; cur <- meta$currency %dt||% ""
  pr <- dt_prepare(nodes); ev <- dt_eval(pr, objective)
  f <- function(x) dt_fmt(x, cur)
  # calculation steps, bottom-up, in a readable order (parents after children)
  steps <- character(0)
  for (i in pr$post) {
    k <- pr$kids[[i]]; t <- pr$type[i]
    if (t == "end" || !length(k)) {
      parts <- character(0); j <- i; path <- integer(0)
      while (!is.na(j)) { path <- c(j, path); j <- pr$par[j] }
      cfs <- pr$cf[path]; cfs <- cfs[cfs != 0]
      if (length(cfs)) steps <- c(steps, sprintf("%s %s: net = %s%s = %s", pr$ids[i], dt_node_name(pr, i),
                                                 paste(dt_fmt(cfs, cur, sign = TRUE), collapse = " "), if (pr$payoff[i] != 0) paste0(" ", dt_fmt(pr$payoff[i], cur, sign = TRUE)) else "", f(ev$V[i])))
      next
    }
    if (t == "chance") steps <- c(steps, sprintf("%s %s (chance): %s = %s", pr$ids[i], dt_node_name(pr, i),
                                                 paste(sprintf("%s \u00d7 %s", dt_p(pr$p[k]), ifelse(ev$V[k] < 0, paste0("(", f(ev$V[k]), ")"), f(ev$V[k]))), collapse = " + "), f(ev$V[i])))
    if (t == "decision") steps <- c(steps, sprintf("%s %s (decision): %s of {%s} = %s \u2192 choose '%s'", pr$ids[i], dt_node_name(pr, i),
                                                   if (identical(objective, "minimise")) "lowest" else "highest",
                                                   paste(sprintf("%s: %s", vapply(k, function(j) dt_branch_name(pr, j), ""), f(ev$V[k])), collapse = ", "),
                                                   f(ev$V[i]), dt_branch_name(pr, ev$best[i])))
  }
  # the plan, read from the root down
  plan <- character(0)
  for (i in pr$pre) if (pr$type[i] == "decision" && ev$reach[i] > 0 && !is.na(ev$best[i])) {
    cond <- character(0); j <- i
    while (!is.na(pr$par[j])) { pj <- pr$par[j]; if (pr$type[pj] == "chance") cond <- c(dt_branch_name(pr, j), cond); j <- pj }
    plan <- c(plan, sprintf("%s%s: choose '%s' (expected %s)", if (length(cond)) paste0("If ", paste(cond, collapse = " and "), ", at ") else "At ",
                            sprintf("'%s'", dt_node_name(pr, i)), dt_branch_name(pr, ev$best[i]), f(ev$V[i])))
  }
  list(pr = pr, ev = ev, objective = objective, currency = cur, root = pr$root, root_value = ev$V[pr$root],
       recommended = if (pr$type[pr$root] == "decision") ev$best[pr$root] else NA_integer_, steps = steps, plan = plan,
       policy = dt_policy(pr, ev))
}

# Outcome distribution when the first decision is forced to option j (later decisions stay optimal).
dt_outcomes <- function(pr, objective, force = NULL, p = pr$p, cf = pr$cf, payoff = pr$payoff) {
  ev <- dt_eval(pr, objective, p, cf, payoff, force)
  ends <- which((pr$type == "end" | lengths(pr$kids) == 0) & ev$reach > 0)
  list(v = ev$V[ends], w = ev$reach[ends], ids = ends, ev = ev)
}

dt_risk_profile <- function(sol) {
  pr <- sol$pr; r <- pr$root
  opts <- if (pr$type[r] == "decision") pr$kids[[r]] else NA_integer_
  rows <- lapply(opts, function(j) {
    o <- dt_outcomes(pr, sol$objective, force = if (is.na(j)) NULL else setNames(list(j), as.character(r)))
    m <- sum(o$w * o$v); sdv <- sqrt(max(0, sum(o$w * (o$v - m)^2)))
    mini <- identical(sol$objective, "minimise")   # values are costs: lower is better and "loss" has no meaning
    data.frame(option_index = if (is.na(j)) NA_integer_ else j, Option = if (is.na(j)) "Whole tree" else dt_branch_name(pr, j),
               EV = m, Best = if (mini) min(o$v) else max(o$v), Worst = if (mini) max(o$v) else min(o$v),
               PLoss = if (mini) NA_real_ else sum(o$w[o$v < 0]), SD = sdv, Outcomes = length(o$v),
               Recommended = !is.na(j) && identical(j, sol$recommended), stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

# Expected value of each first-decision option, given the probabilities / values passed in.
dt_option_values <- function(pr, objective, p = pr$p, cf = pr$cf, payoff = pr$payoff) {
  ev <- dt_eval(pr, objective, p, cf, payoff)
  r <- pr$root
  if (pr$type[r] != "decision") return(setNames(ev$V[r], "Whole tree"))
  setNames(ev$V[pr$kids[[r]]], vapply(pr$kids[[r]], function(j) dt_branch_name(pr, j), ""))
}

# New probability vector when branch j (a child of chance node c) is set to q; the others keep their proportions.
dt_shift_p <- function(pr, c, j, q) {
  p <- pr$p; k <- pr$kids[[c]]; others <- setdiff(k, j)
  rest <- sum(p[others])
  p[j] <- q
  if (length(others)) p[others] <- if (rest > 0) p[others] * (1 - q) / rest else (1 - q) / length(others)
  p
}

# Bisection between two points whose plans differ; returns the switch point.
dt_bisect <- function(g, a, b, sa, iters = 40) {
  for (it in seq_len(iters)) { m <- (a + b) / 2; if (identical(g(m), sa)) a <- m else b <- m }
  (a + b) / 2
}

# Probability sensitivity: for each chance branch, the probability at which the plan would change (critical chance value).
dt_sensitivity_prob <- function(sol) {
  pr <- sol$pr; obj <- sol$objective; base_pol <- sol$policy; base_ev <- sol$ev
  out <- list()
  for (c in which(pr$type == "chance")) {
    k <- pr$kids[[c]]; if (length(k) < 2) next
    for (j in if (length(k) == 2) k[1] else k) {
      g <- function(q) dt_policy(pr, dt_eval(pr, obj, p = dt_shift_p(pr, c, j, q)))
      base <- pr$p[j]; grid <- sort(unique(c(seq(0, 1, by = 0.005), base)))
      pols <- vapply(grid, g, "")
      sw <- which(pols[-1] != pols[-length(pols)])
      crit <- round(vapply(sw, function(s) dt_bisect(g, grid[s], grid[s + 1], pols[s]), 0), 6)
      below <- crit[crit < base - 1e-9]; above <- crit[crit > base + 1e-9]
      lo <- if (length(below)) max(below) else NA_real_; hi <- if (length(above)) min(above) else NA_real_
      what <- function(q) if (is.na(q)) "" else dt_policy_change(pr, base_ev, dt_eval(pr, obj, p = dt_shift_p(pr, c, j, q)))
      margin <- min(c(if (!is.na(lo)) base - lo, if (!is.na(hi)) hi - base, Inf))
      out[[length(out) + 1]] <- data.frame(chance_index = c, branch_index = j,
        Chance = dt_chance_name(pr, c), Branch = dt_branch_name(pr, j), Current = base,
        SwitchBelow = lo, SwitchAbove = hi,
        Change = paste(c(if (!is.na(lo)) paste0("below ", dt_p(lo), ": ", what(max(0, lo - 0.002))), if (!is.na(hi)) paste0("above ", dt_p(hi), ": ", what(min(1, hi + 0.002)))), collapse = " | "),
        Margin = margin, stringsAsFactors = FALSE)
    }
  }
  if (!length(out)) return(NULL)
  d <- do.call(rbind, out); d[order(d$Margin), , drop = FALSE]
}

# Value sensitivity: for each payoff and each branch cash flow, how far it can move before the plan changes.
dt_sensitivity_values <- function(sol) {
  pr <- sol$pr; obj <- sol$objective; base_pol <- sol$policy; base_ev <- sol$ev
  nums <- c(pr$payoff[pr$type == "end"], pr$cf)
  span <- max(abs(nums), 1) * 4
  params <- c(lapply(which(pr$type == "end"), function(i) list(kind = "payoff", i = i)),
              lapply(which(pr$cf != 0), function(i) list(kind = "cf", i = i)))
  out <- list()
  for (pa in params) {
    i <- pa$i
    base <- if (pa$kind == "payoff") pr$payoff[i] else pr$cf[i]
    mk <- function(x) { if (pa$kind == "payoff") { v <- pr$payoff; v[i] <- x; dt_eval(pr, obj, payoff = v) } else { v <- pr$cf; v[i] <- x; dt_eval(pr, obj, cf = v) } }
    g <- function(x) dt_policy(pr, mk(x))
    find <- function(dir) {
      xs <- base + dir * span * (seq_len(160) / 160)^2
      prev <- base_pol; px <- base
      for (x in xs) { s <- g(x); if (!identical(s, prev)) return(dt_bisect(g, px, x, prev)); px <- x }
      NA_real_
    }
    snap <- function(x) { if (is.na(x)) return(x); x <- signif(x, 7); if (abs(x) < max(abs(base), 1) * 1e-6) 0 else x }
    lo <- snap(find(-1)); hi <- snap(find(1))
    if (is.na(lo) && is.na(hi)) next
    what <- function(x) if (is.na(x)) "" else dt_policy_change(pr, base_ev, mk(x))
    eps <- max(abs(base), 1) * 1e-6
    margin <- min(c(if (!is.na(lo)) base - lo, if (!is.na(hi)) hi - base, Inf))
    out[[length(out) + 1]] <- data.frame(node_index = i, Kind = if (pa$kind == "payoff") "Payoff" else "Branch cash flow",
      Item = if (pa$kind == "payoff") sprintf("%s: %s", dt_node_name(pr, i), dt_path_name(pr, i)) else dt_path_name(pr, i),
      Current = base, SwitchBelow = lo, SwitchAbove = hi,
      Change = paste(c(if (!is.na(lo)) paste0("below ", dt_fmt(lo, sol$currency), ": ", what(lo - eps)), if (!is.na(hi)) paste0("above ", dt_fmt(hi, sol$currency), ": ", what(hi + eps))), collapse = " | "),
      Margin = margin, MarginPct = if (abs(base) > 0) margin / abs(base) else NA_real_, stringsAsFactors = FALSE)
  }
  if (!length(out)) return(NULL)
  d <- do.call(rbind, out)
  key <- ifelse(is.na(d$MarginPct), d$Margin / span, d$MarginPct)
  d[order(key), , drop = FALSE]
}

# Curve for the "critical chance value" chart: EV of every first-decision option as one probability moves 0 -> 1.
dt_prob_curve <- function(sol, chance_index, branch_index) {
  pr <- sol$pr; qs <- seq(0, 1, by = 0.01)
  m <- t(vapply(qs, function(q) dt_option_values(pr, sol$objective, p = dt_shift_p(pr, chance_index, branch_index, q)), numeric(if (pr$type[pr$root] == "decision") length(pr$kids[[pr$root]]) else 1)))
  if (is.null(dim(m))) m <- matrix(m, ncol = 1)
  colnames(m) <- names(dt_option_values(pr, sol$objective))
  list(q = qs, values = m)
}

# ---- conversion: stored rows <-> node table <-> text ----------------------------------------
dt_rows_to_nodes <- function(df) {
  if (is.null(df) || nrow(df) == 0) return(list(nodes = dt_empty_nodes(), meta = dt_new_meta()))
  g <- function(col) if (col %in% names(df)) df[[col]] else rep(NA, nrow(df))
  ct <- tolower(as.character(g("component_type")))
  t <- which(ct == "title")[1]
  meta <- dt_new_meta(
    title = if (!is.na(t) && !dt_blank(df$label_text[t])) df$label_text[t] else if (!dt_blank(g("title")[1])) g("title")[1] else "",
    question = if (!is.na(t) && !dt_blank(g("sub_text")[t])) g("sub_text")[t] else "",
    currency = if (!is.na(t) && !dt_blank(g("unit_label")[t])) toupper(trimws(g("unit_label")[t])) else {
      u <- g("unit_label"); u <- u[!vapply(u, dt_blank, TRUE)]; if (length(u)) toupper(trimws(u[1])) else "GBP" },
    objective = if (!is.na(t) && grepl("^min", tolower(g("metric_name")[t] %dt||% ""))) "minimise" else "maximise")
  meta$diagram_id <- g("diagram_id")[1]; meta$category <- g("category")[1]; meta$domain <- g("domain")[1]; meta$topic <- g("topic")[1]
  keep <- which(ct %in% c("decision_node", "chance_node", "end_node", "decision", "chance", "end"))
  if (!length(keep)) return(list(nodes = dt_empty_nodes(), meta = meta))
  so <- suppressWarnings(as.integer(g("sequence_order")))
  ord <- keep[order(seq_along(keep))]   # keep the stored order (parents are written before children)
  items <- vapply(ord, function(i) { v <- g("items_packed")[i]; if (dt_blank(v)) "" else paste(diagram_unpack_items(v), collapse = "; ") }, "")
  nodes <- data.frame(node_id = as.character(g("node_id")[ord]), parent_id = as.character(g("parent_id")[ord]), type = ct[ord],
                      label = as.character(g("label_text")[ord]), branch = as.character(g("branch_label")[ord]),
                      probability = g("probability")[ord], cash_flow = g("cash_flow")[ord], payoff = g("value_numeric")[ord],
                      notes = items, seq = so[ord], stringsAsFactors = FALSE)
  # children in their sequence order, parents before children
  nodes <- dt_clean_nodes(nodes)
  dbl <- dt_double_counted(nodes$type, nodes$cash_flow, nodes$payoff)
  if (length(dbl)) {
    nodes$cash_flow[dbl] <- 0
    nodes$notes[dbl] <- trimws(paste0(nodes$notes[dbl], ifelse(nzchar(nodes$notes[dbl]), "; ", ""), "Cash flow repeated the payoff, so it is counted once"))
  }
  nodes$seq <- so[ord]
  nodes <- dt_sort_nodes(nodes)
  nodes$seq <- NULL
  list(nodes = nodes, meta = meta)
}

# Depth-first order (parent, then its children in sibling order) - the order the table and the text use.
dt_sort_nodes <- function(nodes) {
  if (nrow(nodes) < 2) return(nodes)
  sq <- if ("seq" %in% names(nodes)) nodes$seq else seq_len(nrow(nodes))
  sq[is.na(sq)] <- 1e6
  out <- integer(0); seen <- logical(nrow(nodes))
  walk <- function(i) {
    if (seen[i]) return(); seen[i] <<- TRUE; out <<- c(out, i)
    k <- which(nodes$parent_id == nodes$node_id[i]); k <- k[order(sq[k], k)]
    for (j in k) walk(j)
  }
  for (r in which(!nzchar(nodes$parent_id) | !nodes$parent_id %in% nodes$node_id)) walk(r)
  out <- c(out, which(!seen))
  nodes[out, , drop = FALSE]
}

dt_sibling_order <- function(nodes) {
  vapply(seq_len(nrow(nodes)), function(i) { s <- which(nodes$parent_id == nodes$parent_id[i]); match(i, s) }, 1L)
}

# Builds the strategy_diagrams rows for saving. sol may be NULL (tree not valid yet).
dt_nodes_to_rows <- function(nodes, meta, diagram_id, category, domain, topic, created_by = "generate_diagram", source_diagram_id = NA) {
  nodes <- dt_sort_nodes(dt_clean_nodes(nodes))
  v <- dt_validate(nodes)
  sol <- if (!length(v$errors)) dt_solve(nodes, meta) else NULL
  title <- if (nzchar(trimws(meta$title %dt||% ""))) meta$title else topic
  base <- function(k) data.frame(diagram_id = rep(diagram_id, k), diagram_name = rep(DIAGRAM_TYPE_LABELS[["decision_tree"]], k),
                                 diagram_type = "decision_tree", diagram_group = "decision_making_process",
                                 category = category, domain = domain, topic = topic, title = title, is_template = FALSE,
                                 source_diagram_id = as.character(source_diagram_id %dt||% NA), stringsAsFactors = FALSE)
  n <- nrow(nodes); sib <- dt_sibling_order(nodes)
  depth <- if (!is.null(sol)) sol$pr$depth else rep(NA_integer_, n)
  ev <- if (!is.null(sol)) sol$ev$V else rep(NA_real_, n)
  best <- if (!is.null(sol)) sol$ev$reach > 0 else rep(FALSE, n)
  tr <- cbind(base(1), data.frame(component_type = "title", layout_role = "title", grid_row = NA_integer_, grid_col = NA_integer_,
              quadrant_position = NA_character_, sequence_order = 0L, z_index = NA_integer_, pos_x = NA_real_, pos_y = NA_real_, width = NA_real_, height = NA_real_,
              label_text = title, sub_text = meta$question %dt||% "", items_packed = NA_character_,
              value_numeric = if (!is.null(sol)) sol$root_value else NA_real_, value_axis = NA_character_, series_name = NA_character_,
              unit_label = meta$currency %dt||% "", axis_type = NA_character_, axis_min = NA_real_, axis_max = NA_real_,
              metric_name = meta$objective %dt||% "maximise", color_hint = NA_character_, icon_name = NA_character_,
              node_id = NA_character_, parent_id = NA_character_, branch_label = NA_character_, probability = NA_real_, cash_flow = NA_real_,
              expected_value = if (!is.null(sol)) sol$root_value else NA_real_, created_by = created_by, stringsAsFactors = FALSE))
  if (!n) return(tr)
  nr <- cbind(base(n), data.frame(component_type = paste0(nodes$type, "_node"), layout_role = "node",
              grid_row = as.integer(depth + 1L), grid_col = NA_integer_, quadrant_position = NA_character_,
              sequence_order = as.integer(sib), z_index = NA_integer_, pos_x = NA_real_, pos_y = NA_real_, width = NA_real_, height = NA_real_,
              label_text = nodes$label, sub_text = NA_character_,
              items_packed = ifelse(nzchar(nodes$notes), gsub("\\s*;\\s*", DIAG_ITEM_SEP, nodes$notes), NA_character_),
              value_numeric = ifelse(nodes$type == "end", nodes$payoff, NA_real_), value_axis = NA_character_, series_name = NA_character_,
              unit_label = meta$currency %dt||% "", axis_type = NA_character_, axis_min = NA_real_, axis_max = NA_real_, metric_name = NA_character_,
              color_hint = ifelse(best, "best", NA_character_), icon_name = NA_character_,
              node_id = nodes$node_id, parent_id = ifelse(nzchar(nodes$parent_id), nodes$parent_id, NA_character_),
              branch_label = ifelse(nzchar(nodes$branch), nodes$branch, NA_character_),
              probability = nodes$probability, cash_flow = nodes$cash_flow, expected_value = ev,
              created_by = created_by, stringsAsFactors = FALSE))
  rbind(tr, nr)
}

# Adds the calculated expected values (and "best" on the recommended plan) to parsed rows - a snapshot for BigQuery.
dt_snapshot_values <- function(df) {
  x <- dt_rows_to_nodes(df)
  if (!nrow(x$nodes) || length(dt_validate(x$nodes)$errors)) return(df)
  sol <- dt_solve(x$nodes, x$meta)
  if (!"expected_value" %in% names(df)) df$expected_value <- NA_real_
  m <- match(df$node_id, sol$pr$ids)
  ok <- !is.na(m)
  df$expected_value[ok] <- sol$ev$V[m[ok]]
  df$color_hint[ok] <- ifelse(sol$ev$reach[m[ok]] > 0, "best", NA_character_)
  t <- which(tolower(df$component_type) == "title")
  if (length(t)) df$expected_value[t] <- sol$root_value
  df
}

# The bracket text format (Bulk Import / download / the Editing Tool's output use the same format).
dt_nodes_to_text <- function(nodes, meta, category = "", domain = "", topic = "") {
  nodes <- dt_sort_nodes(dt_clean_nodes(nodes)); sib <- dt_sibling_order(nodes)
  na <- function(x) if (is.null(x) || length(x) == 0 || is.na(x) || !nzchar(trimws(as.character(x)))) "N/A" else as.character(x)
  num <- function(x) if (is.na(x)) "N/A" else format(x, scientific = FALSE, trim = TRUE, digits = 15)
  head <- paste0("[decision_tree]\n[decision_making_process]\n[", na(category), "]\n[", na(domain), "]\n[", na(topic), "]\n[", na(meta$title), "]\n\n",
                 "[component_type]: title\n[layout_role]: title\n[label_text]: ", na(meta$title), "\n[sub_text]: ", na(meta$question),
                 "\n[unit_label]: ", na(meta$currency), "\n[metric_name]: ", na(meta$objective), "\n")
  blocks <- vapply(seq_len(nrow(nodes)), function(i) paste0(
    "[component_type]: ", nodes$type[i], "_node\n[layout_role]: node\n[node_id]: ", nodes$node_id[i],
    "\n[parent_id]: ", na(nodes$parent_id[i]), "\n[branch_label]: ", na(nodes$branch[i]),
    "\n[probability]: ", num(nodes$probability[i]), "\n[cash_flow]: ", num(nodes$cash_flow[i]),
    "\n[sequence_order]: ", sib[i], "\n[label_text]: ", na(nodes$label[i]), "\n[sub_text]: N/A",
    "\n[value_numeric]: ", if (nodes$type[i] == "end") num(nodes$payoff[i]) else "N/A",
    "\n[items_packed]: ", if (nzchar(nodes$notes[i])) gsub("\\s*;\\s*", DIAG_ITEM_SEP, nodes$notes[i]) else "N/A", "\n"), "")
  paste(c(head, blocks), collapse = "\n")
}

# ---- worked examples (the two classic textbook trees) ---------------------------------------
dt_example_abc <- function() list(
  meta = dt_new_meta("ABC Ltd: where to grow next", "Should ABC Ltd expand its business unit, launch a new shower gel line, or do nothing?", "INR", "maximise"),
  nodes = dt_clean_nodes(data.frame(
    node_id   = c("D1", "C1", "E1", "E2", "C2", "E3", "E4", "C3", "E5", "E6"),
    parent_id = c("", "D1", "C1", "C1", "D1", "C2", "C2", "D1", "C3", "C3"),
    type      = c("decision", "chance", "end", "end", "chance", "end", "end", "chance", "end", "end"),
    label     = c("Choose the growth route", "Competitor response", "Profit", "Loss", "Product launch", "Profit", "Loss", "Market drift", "Profit", "Loss"),
    branch    = c("", "Expansion of business unit", "Market share increases", "Threat from competitors", "New shower gel line", "Success", "Failure", "Do nothing", "Market share increases", "Threat from competitors"),
    probability = c(NA, NA, 0.4, 0.6, NA, 0.5, 0.5, NA, 0.4, 0.6),
    cash_flow = c(NA, 0, 0, 0, 0, 0, 0, 0, 0, 0),
    payoff    = c(NA, NA, 2500000, -800000, NA, 1800000, -600000, NA, 1000000, -400000),
    notes = "", stringsAsFactors = FALSE)))

dt_example_automaker <- function() list(
  meta = dt_new_meta("Automaker: invest USD 130,000 in a one-year R&D project?", "Should the automaker fund the R&D project, and if it succeeds, build a large or a small plant?", "USD", "maximise"),
  nodes = dt_clean_nodes(data.frame(
    node_id   = c("A", "X", "B", "Y", "E1", "E2", "E3", "Z", "E4", "E5", "E6", "E7", "E8"),
    parent_id = c("", "A", "X", "B", "Y", "Y", "Y", "B", "Z", "Z", "Z", "X", "A"),
    type      = c("decision", "chance", "decision", "chance", "end", "end", "end", "chance", "end", "end", "end", "end", "end"),
    label     = c("Fund the R&D project?", "R&D result", "Which plant?", "Market demand", "High market", "Medium market", "Low market",
                  "Market demand", "High market", "Medium market", "Low market", "R&D fails", "No project"),
    branch    = c("", "Go ahead with R&D", "Success", "Build large plant", "High", "Medium", "Low", "Build small plant", "High", "Medium", "Low", "No success", "Do not go ahead"),
    probability = c(NA, NA, 0.6, NA, 0.5, 0.3, 0.2, NA, 0.5, 0.3, 0.2, 0.4, NA),
    cash_flow = c(NA, -130000, 0, -400000, 0, 0, 0, -200000, 0, 0, 0, 0, 0),
    payoff    = c(NA, NA, NA, NA, 1000000, 500000, 250000, NA, 500000, 500000, 250000, 0, 0),
    notes = c("", "R&D cost is sunk once spent", "", "Plant cost USD 400k", "PV of net cash flows over the plant's life", "", "",
              "Plant cost USD 200k; a small plant caps sales at the medium level", "", "", "", "", ""),
    stringsAsFactors = FALSE)))

# ---- SVG drawing ------------------------------------------------------------------------------
dt_wrap <- function(s, width = 26, lines = 2) {
  s <- trimws(s %dt||% ""); if (!nzchar(s)) return(character(0))
  w <- strwrap(s, width = width)
  if (length(w) > lines) { w <- w[seq_len(lines)]; w[lines] <- paste0(sub("\\s*\\S*$", "", substr(w[lines], 1, width - 1)), "\u2026") }
  w
}
dt_esc <- function(s) htmltools::htmlEscape(s %dt||% "")

DT_COL <- list(teal = "#00897b", teal_bg = "#e0f2f1", grey = "#a7b4c2", ink = "#12303a", sub = "#4b6470", pos = "#00796b", neg = "#c62828",
               dec_fill = "#004d5a", dec_line = "#002c3c", ch_fill = "#f6b93b", ch_line = "#b7791f", end_fill = "#e0f2f1", end_line = "#00897b")

dt_svg <- function(nodes, meta, sol = NULL) {
  nodes <- dt_sort_nodes(dt_clean_nodes(nodes))
  n <- nrow(nodes)
  if (n == 0) return(htmltools::HTML("<div class='dt-empty'>Add nodes to see the tree.</div>"))
  cur <- meta$currency %dt||% ""
  pr <- dt_prepare(nodes)
  if (is.na(pr$root)) return(htmltools::HTML("<div class='dt-empty'>The tree has no starting node yet.</div>"))
  # layout: leaves evenly spaced top to bottom, parents centred on their children, end nodes aligned in the last column
  y <- rep(NA_real_, n); leaf <- 0
  lay <- function(i) {
    k <- pr$kids[[i]]
    if (!length(k)) { leaf <<- leaf + 1; y[i] <<- leaf; return(invisible()) }
    for (j in k) lay(j)
    y[i] <<- (min(y[k]) + max(y[k])) / 2
  }
  lay(pr$root)
  reached <- !is.na(y)
  maxd <- max(pr$depth[reached])
  col_w <- 250; row_h <- 92; left <- 190; top <- 130
  isend <- lengths(pr$kids) == 0
  colx <- function(i) left + (if (isend[i]) maxd else pr$depth[i]) * col_w
  X <- vapply(seq_len(n), colx, 0); Y <- top + (y - 1) * row_h
  W <- left + maxd * col_w + 300; H <- top + max(1, leaf) * row_h + 10
  ev <- if (!is.null(sol)) sol$ev else NULL
  onplan <- if (!is.null(ev)) ev$reach > 0 else rep(FALSE, n)
  rejected <- if (!is.null(ev)) vapply(seq_len(n), function(i) { p <- pr$par[i]; !is.na(p) && pr$type[p] == "decision" && !is.na(ev$best[p]) && ev$best[p] != i }, TRUE) else rep(FALSE, n)
  half <- function(i) if (isend[i] && pr$type[i] == "end") 12 else 13
  parts <- character(0); add <- function(...) parts <<- c(parts, paste0(...))
  add(sprintf("<svg xmlns='http://www.w3.org/2000/svg' class='dt-svg' width='%d' height='%d' viewBox='0 0 %d %d' style='width:100%%;max-width:%dpx;height:auto' font-family='Segoe UI, Helvetica, Arial, sans-serif'>", W, H, W, H, W))
  add(sprintf("<rect x='0' y='0' width='%d' height='%d' fill='#ffffff'/>", W, H))
  add(sprintf("<text x='16' y='28' font-size='18' font-weight='700' fill='%s'>%s</text>", DT_COL$ink, dt_esc(meta$title %dt||% "Decision tree")))
  q <- dt_wrap(meta$question, 120, 1)
  if (length(q)) add(sprintf("<text x='16' y='48' font-size='12.5' fill='%s'>%s</text>", DT_COL$sub, dt_esc(q)))
  # legend
  lx <- 16; ly <- 72
  add(sprintf("<rect x='%d' y='%d' width='14' height='14' fill='%s' stroke='%s'/><text x='%d' y='%d' font-size='11.5' fill='%s'>Decision</text>", lx, ly - 11, DT_COL$dec_fill, DT_COL$dec_line, lx + 20, ly, DT_COL$ink))
  add(sprintf("<circle cx='%d' cy='%d' r='7.5' fill='%s' stroke='%s'/><text x='%d' y='%d' font-size='11.5' fill='%s'>Chance</text>", lx + 92, ly - 4, DT_COL$ch_fill, DT_COL$ch_line, lx + 104, ly, DT_COL$ink))
  add(sprintf("<polygon points='%d,%d %d,%d %d,%d' fill='%s' stroke='%s'/><text x='%d' y='%d' font-size='11.5' fill='%s'>End (net payoff)</text>", lx + 170, ly - 4, lx + 184, ly - 12, lx + 184, ly + 4, DT_COL$end_fill, DT_COL$end_line, lx + 190, ly, DT_COL$ink))
  if (!is.null(sol)) {
    add(sprintf("<line x1='%d' y1='%d' x2='%d' y2='%d' stroke='%s' stroke-width='4'/><text x='%d' y='%d' font-size='11.5' fill='%s'>Recommended plan</text>", lx + 300, ly - 4, lx + 330, ly - 4, DT_COL$teal, lx + 336, ly, DT_COL$ink))
    add(sprintf("<line x1='%d' y1='%d' x2='%d' y2='%d' stroke='%s' stroke-width='1.6' stroke-dasharray='6 4'/><text x='%d' y='%d' font-size='11.5' fill='%s'>// rejected option</text>", lx + 450, ly - 4, lx + 480, ly - 4, DT_COL$grey, lx + 486, ly, DT_COL$ink))
    add(sprintf("<text x='%d' y='%d' font-size='11.5' fill='%s'>EV = expected value (probability \u00d7 value, summed)</text>", lx + 600, ly, DT_COL$sub))
  }
  # branches
  for (i in seq_len(n)) {
    p <- pr$par[i]; if (is.na(p) || !reached[i]) next
    x0 <- X[p] + half(p); xm <- X[p] + half(p) + 18; x1 <- X[i] - half(i); y0 <- Y[p]; y1 <- Y[i]
    col <- if (onplan[i]) DT_COL$teal else DT_COL$grey
    sw <- if (onplan[i]) 3.5 else 1.6
    dash <- if (rejected[i]) " stroke-dasharray='6 4'" else ""
    add(sprintf("<path d='M%.1f,%.1f H%.1f V%.1f H%.1f' fill='none' stroke='%s' stroke-width='%.1f'%s/>", x0, y0, xm, y1, x1, col, sw, dash))
    add(sprintf("<polygon points='%.1f,%.1f %.1f,%.1f %.1f,%.1f' fill='%s'/>", x1, y1, x1 - 8, y1 - 4, x1 - 8, y1 + 4, col))
    if (rejected[i]) for (o in c(0, 6)) add(sprintf("<line x1='%.1f' y1='%.1f' x2='%.1f' y2='%.1f' stroke='%s' stroke-width='2'/>", xm + 22 + o, y1 + 7, xm + 28 + o, y1 - 7, DT_COL$neg))
    bl <- dt_wrap(pr$branch[i], 30, 2)
    tx <- xm + (if (rejected[i]) 40 else 10)
    for (k in seq_along(bl)) add(sprintf("<text x='%.1f' y='%.1f' font-size='12' font-weight='600' fill='%s'>%s</text>", tx, y1 - 7 - (length(bl) - k) * 14, if (onplan[i]) DT_COL$ink else DT_COL$sub, dt_esc(bl[k])))
    info <- character(0)
    if (pr$type[p] == "chance") info <- c(info, paste0("p = ", dt_p(nodes$probability[i])))
    if (!is.na(nodes$cash_flow[i]) && nodes$cash_flow[i] != 0) info <- c(info, paste0(if (nodes$cash_flow[i] < 0) "cost " else "cash ", dt_fmt(nodes$cash_flow[i], cur, sign = TRUE)))
    if (length(info)) add(sprintf("<text x='%.1f' y='%.1f' font-size='11.5' fill='%s'>%s</text>", tx, y1 + 16, if (is.na(nodes$cash_flow[i]) || nodes$cash_flow[i] >= 0) DT_COL$sub else DT_COL$neg, dt_esc(paste(info, collapse = "   \u00b7   "))))
  }
  # nodes
  for (i in seq_len(n)) {
    if (!reached[i]) next
    x <- X[i]; yy <- Y[i]; t <- pr$type[i]
    tip <- sprintf("<title>%s%s</title>", dt_esc(paste0(pr$ids[i], ": ", dt_node_name(pr, i))), if (nzchar(nodes$notes[i])) dt_esc(paste0(" \u2014 ", nodes$notes[i])) else "")
    if (t == "decision" && !isend[i]) add(sprintf("<g>%s<rect x='%.1f' y='%.1f' width='26' height='26' rx='2' fill='%s' stroke='%s' stroke-width='2'/></g>", tip, x - 13, yy - 13, DT_COL$dec_fill, DT_COL$dec_line))
    else if (t == "chance" && !isend[i]) add(sprintf("<g>%s<circle cx='%.1f' cy='%.1f' r='13' fill='%s' stroke='%s' stroke-width='2'/></g>", tip, x, yy, DT_COL$ch_fill, DT_COL$ch_line))
    else add(sprintf("<g>%s<polygon points='%.1f,%.1f %.1f,%.1f %.1f,%.1f' fill='%s' stroke='%s' stroke-width='2'/></g>", tip, x - 12, yy, x + 12, yy - 14, x + 12, yy + 14, DT_COL$end_fill, DT_COL$end_line))
    if (!isend[i]) {
      # node name above-left of the node (clear of the outgoing branch labels, which start right of the node)
      nl <- dt_wrap(dt_node_name(pr, i), 24, 2)
      # sit above the (one- or two-line) label of the branch coming into this node, so they never overlap
      nb <- if (is.na(pr$par[i])) 0L else length(dt_wrap(pr$branch[i], 30, 2))
      base <- yy - max(27, 13 + nb * 14)
      for (k in seq_along(nl)) add(sprintf("<text x='%.1f' y='%.1f' font-size='11.5' font-weight='700' text-anchor='end' fill='%s'>%s</text>", x + 12, base - (length(nl) - k) * 13, DT_COL$ink, dt_esc(nl[k])))
      if (!is.null(ev)) {
        lab <- paste0("EV ", dt_fmt(ev$V[i], cur))
        wpx <- 8 + nchar(lab) * 6.6
        add(sprintf("<rect x='%.1f' y='%.1f' width='%.1f' height='18' rx='9' fill='%s' stroke='%s'/><text x='%.1f' y='%.1f' font-size='11.5' font-weight='700' text-anchor='middle' fill='%s'>%s</text>",
                    x + 22 - wpx, yy + 19, wpx, if (onplan[i]) DT_COL$teal_bg else "#f1f5f9", if (onplan[i]) DT_COL$teal else "#cbd5e1", x + 22 - wpx / 2, yy + 32, if (onplan[i]) "#004d40" else DT_COL$sub, dt_esc(lab)))
      }
    } else {
      tx <- x + 20
      add(sprintf("<text x='%.1f' y='%.1f' font-size='12' font-weight='700' fill='%s'>%s</text>", tx, yy - 6, DT_COL$ink, dt_esc(dt_wrap(dt_node_name(pr, i), 34, 1))))
      if (!is.null(ev)) {
        v <- ev$V[i]
        add(sprintf("<text x='%.1f' y='%.1f' font-size='14' font-weight='800' fill='%s'>%s</text>", tx, yy + 12, if (v < 0) DT_COL$neg else DT_COL$pos, dt_esc(dt_fmt(v, cur))))
        j <- i; path <- integer(0); while (!is.na(j)) { path <- c(j, path); j <- pr$par[j] }
        cfs <- pr$cf[path]; cfs <- cfs[cfs != 0]
        extra <- character(0)
        if (length(cfs)) extra <- c(extra, paste0("= ", paste(dt_fmt(cfs, cur, sign = TRUE), collapse = " "), if (pr$payoff[i] != 0) paste0(" ", dt_fmt(pr$payoff[i], cur, sign = TRUE)) else ""))
        if (onplan[i]) extra <- c(extra, paste0("chance ", dt_pct(ev$reach[i])))
        if (length(extra)) add(sprintf("<text x='%.1f' y='%.1f' font-size='10.5' fill='%s'>%s</text>", tx, yy + 27, DT_COL$sub, dt_esc(paste(extra, collapse = "  \u00b7  "))))
      } else if (!is.na(nodes$payoff[i])) add(sprintf("<text x='%.1f' y='%.1f' font-size='13' font-weight='700' fill='%s'>%s</text>", tx, yy + 12, DT_COL$sub, dt_esc(dt_fmt(nodes$payoff[i], cur))))
    }
  }
  add("</svg>")
  htmltools::HTML(paste(parts, collapse = "\n"))
}

# Line chart (SVG) for the critical chance value: EV of each first-decision option against one probability.
dt_curve_svg <- function(curve, base_p, crit = numeric(0), currency = "", xlab = "probability") {
  W <- 760; H <- 330; L <- 78; R <- 190; T <- 20; B <- 46
  m <- curve$values; qs <- curve$q
  yr <- range(m, na.rm = TRUE); if (diff(yr) == 0) yr <- yr + c(-1, 1)
  yr <- yr + c(-1, 1) * diff(yr) * 0.06
  sx <- function(q) L + q * (W - L - R); sy <- function(v) T + (1 - (v - yr[1]) / diff(yr)) * (H - T - B)
  pal <- c("#00897b", "#e08e45", "#3b6fb6", "#8e5ea2", "#c0392b", "#5d7b89", "#2bb3a3", "#b7791f")
  parts <- c(sprintf("<svg xmlns='http://www.w3.org/2000/svg' width='%d' height='%d' viewBox='0 0 %d %d' font-family='Segoe UI, Helvetica, Arial, sans-serif' style='max-width:100%%;height:auto'>", W, H, W, H),
             sprintf("<rect width='%d' height='%d' fill='#fff'/>", W, H))
  ticks <- pretty(yr, 5); ticks <- ticks[ticks >= yr[1] & ticks <= yr[2]]
  for (tk in ticks) parts <- c(parts, sprintf("<line x1='%d' x2='%d' y1='%.1f' y2='%.1f' stroke='#e5e7eb'/><text x='%d' y='%.1f' font-size='11' text-anchor='end' fill='#475569'>%s</text>", L, W - R, sy(tk), sy(tk), L - 6, sy(tk) + 4, dt_esc(dt_fmt(tk, currency))))
  for (qq in seq(0, 1, 0.2)) parts <- c(parts, sprintf("<text x='%.1f' y='%d' font-size='11' text-anchor='middle' fill='#475569'>%s</text>", sx(qq), H - B + 16, dt_p(qq)))
  parts <- c(parts, sprintf("<text x='%.1f' y='%d' font-size='11.5' text-anchor='middle' fill='#1f2937'>%s</text>", (L + W - R) / 2, H - 8, dt_esc(xlab)),
             sprintf("<line x1='%d' x2='%d' y1='%d' y2='%d' stroke='#94a3b8'/>", L, W - R, H - B, H - B))
  if (yr[1] < 0 && yr[2] > 0) parts <- c(parts, sprintf("<line x1='%d' x2='%d' y1='%.1f' y2='%.1f' stroke='#64748b' stroke-dasharray='3 3'/>", L, W - R, sy(0), sy(0)))
  for (k in seq_len(ncol(m))) {
    pts <- paste(sprintf("%.1f,%.1f", sx(qs), sy(m[, k])), collapse = " ")
    parts <- c(parts, sprintf("<polyline points='%s' fill='none' stroke='%s' stroke-width='2.6'/>", pts, pal[(k - 1) %% length(pal) + 1]),
               sprintf("<rect x='%d' y='%d' width='12' height='12' fill='%s'/><text x='%d' y='%d' font-size='11.5' fill='#1f2937'>%s</text>", W - R + 14, T + 6 + (k - 1) * 20, pal[(k - 1) %% length(pal) + 1], W - R + 32, T + 16 + (k - 1) * 20, dt_esc(dt_wrap(colnames(m)[k], 24, 1))))
  }
  parts <- c(parts, sprintf("<line x1='%.1f' x2='%.1f' y1='%d' y2='%d' stroke='#1f2937' stroke-width='1.5'/><text x='%.1f' y='%d' font-size='11' fill='#1f2937'>now %s</text>", sx(base_p), sx(base_p), T, H - B, sx(base_p) + 4, T + 12, dt_p(base_p)))
  for (cv in crit) parts <- c(parts, sprintf("<line x1='%.1f' x2='%.1f' y1='%d' y2='%d' stroke='#b91c1c' stroke-dasharray='5 4' stroke-width='1.5'/><text x='%.1f' y='%d' font-size='11' fill='#b91c1c'>switch %s</text>", sx(cv), sx(cv), T, H - B, sx(cv) + 4, T + 28, dt_p(cv)))
  htmltools::HTML(paste(c(parts, "</svg>"), collapse = "\n"))
}

# ---- report pieces (HTML) shared by the builder and the Visualisations tab ----------------------
dt_table_html <- function(df, header, cls = "dt-table") {
  if (is.null(df) || nrow(df) == 0) return(htmltools::HTML(""))
  h <- paste0("<tr>", paste0("<th>", dt_esc(header), "</th>", collapse = ""), "</tr>")
  b <- vapply(seq_len(nrow(df)), function(i) paste0("<tr", if (isTRUE(attr(df, "hl")[i])) " class='dt-hl'" else "", ">", paste0("<td>", vapply(df[i, ], function(v) dt_esc(as.character(v)), ""), "</td>", collapse = ""), "</tr>"), "")
  htmltools::HTML(sprintf("<div class='dt-table-wrap'><table class='%s'><thead>%s</thead><tbody>%s</tbody></table></div>", cls, h, paste(b, collapse = "")))
}

dt_risk_table <- function(sol) {
  rp <- dt_risk_profile(sol); cur <- sol$currency
  d <- data.frame(Option = ifelse(rp$Recommended, paste0("\u2605 ", rp$Option), rp$Option), `Expected value` = dt_fmt(rp$EV, cur),
                  `Best case` = dt_fmt(rp$Best, cur), `Worst case` = dt_fmt(rp$Worst, cur), `Chance of a loss` = dt_pct(rp$PLoss),
                  `Spread (std dev)` = dt_fmt(rp$SD, cur), check.names = FALSE, stringsAsFactors = FALSE)
  if (identical(sol$objective, "minimise")) { names(d)[2:4] <- c("Expected cost", "Lowest cost", "Highest cost"); d[["Chance of a loss"]] <- NULL }
  attr(d, "hl") <- rp$Recommended
  dt_table_html(d, names(d))
}

# Every outcome each first option can lead to (later decisions taken as recommended), with its probability.
dt_outcome_table <- function(sol) {
  pr <- sol$pr; r <- pr$root; cur <- sol$currency
  opts <- if (pr$type[r] == "decision") pr$kids[[r]] else NA_integer_
  rows <- do.call(rbind, lapply(opts, function(j) {
    o <- dt_outcomes(pr, sol$objective, force = if (is.na(j)) NULL else setNames(list(j), as.character(r)))
    ord <- order(-o$v)
    data.frame(Option = if (is.na(j)) "Whole tree" else dt_branch_name(pr, j),
               Outcome = vapply(o$ids[ord], function(i) dt_node_name(pr, i), ""),
               Path = vapply(o$ids[ord], function(i) dt_path_name(pr, i, keep = 6), ""),
               `Net payoff` = dt_fmt(o$v[ord], cur), Probability = dt_pct(o$w[ord]),
               `Contribution to EV` = dt_fmt(o$v[ord] * o$w[ord], cur, sign = TRUE),
               rec = !is.na(j) && identical(j, sol$recommended), check.names = FALSE, stringsAsFactors = FALSE)
  }))
  hl <- rows$rec; rows$rec <- NULL
  rows$Option[duplicated(rows$Option)] <- ""
  attr(rows, "hl") <- hl
  dt_table_html(rows, names(rows))
}

dt_prob_table <- function(sp, top = 50) {
  if (is.null(sp) || !nrow(sp)) return(htmltools::HTML("<p class='dt-muted'>No chance node with two or more outcomes.</p>"))
  sp <- head(sp, top)
  d <- data.frame(`Chance node` = sp$Chance, Branch = sp$Branch, `Probability now` = dt_p(sp$Current),
                  `Plan changes if it falls below` = ifelse(is.na(sp$SwitchBelow), "never", dt_p(sp$SwitchBelow)),
                  `Plan changes if it rises above` = ifelse(is.na(sp$SwitchAbove), "never", dt_p(sp$SwitchAbove)),
                  `What changes` = ifelse(nzchar(sp$Change), sp$Change, "the plan holds for any probability 0-1"), check.names = FALSE, stringsAsFactors = FALSE)
  attr(d, "hl") <- is.finite(sp$Margin) & sp$Margin < 0.1
  dt_table_html(d, names(d))
}

dt_value_table <- function(sv, currency, top = 50) {
  if (is.null(sv) || !nrow(sv)) return(htmltools::HTML("<p class='dt-muted'>No single payoff or cost can change the plan within a wide range: the recommendation is robust to the numbers.</p>"))
  sv <- head(sv, top)
  d <- data.frame(Number = sv$Kind, Item = sv$Item, `Value now` = dt_fmt(sv$Current, currency),
                  `Plan changes below` = ifelse(is.na(sv$SwitchBelow), "\u2013", dt_fmt(sv$SwitchBelow, currency)),
                  `Plan changes above` = ifelse(is.na(sv$SwitchAbove), "\u2013", dt_fmt(sv$SwitchAbove, currency)),
                  `Room before it changes` = ifelse(is.na(sv$MarginPct), dt_fmt(sv$Margin, currency), paste0(dt_fmt(sv$Margin, currency), " (", dt_pct(sv$MarginPct), ")")),
                  `What changes` = sv$Change, check.names = FALSE, stringsAsFactors = FALSE)
  attr(d, "hl") <- !is.na(sv$MarginPct) & sv$MarginPct < 0.25
  dt_table_html(d, names(d))
}

dt_recommendation_ui <- function(sol, meta) {
  pr <- sol$pr; cur <- sol$currency
  rp <- dt_risk_profile(sol)
  head <- if (!is.na(sol$recommended)) {
    others <- rp[!rp$Recommended, , drop = FALSE]
    gap <- if (nrow(others)) { o <- if (identical(sol$objective, "minimise")) others[which.min(others$EV), ] else others[which.max(others$EV), ]; abs(sol$root_value - o$EV) } else NA
    tags$div(class = "dt-reco",
      tags$div(class = "dt-reco-label", if (identical(sol$objective, "minimise")) "Lowest expected cost" else "Recommended first decision"),
      tags$div(class = "dt-reco-main", dt_branch_name(pr, sol$recommended)),
      tags$div(class = "dt-reco-sub", sprintf("Expected value %s%s", dt_fmt(sol$root_value, cur),
               if (!is.na(gap)) sprintf(" \u00b7 %s ahead of the next best option", dt_fmt(gap, cur)) else "")))
  } else tags$div(class = "dt-reco", tags$div(class = "dt-reco-label", "Expected value of the tree"), tags$div(class = "dt-reco-main", dt_fmt(sol$root_value, cur)))
  rec <- rp[rp$Recommended | is.na(rp$option_index), , drop = FALSE][1, ]
  kpis <- tags$div(class = "dt-kpis",
    tags$div(class = "dt-kpi", tags$span("Best case"), tags$b(dt_fmt(rec$Best, cur))),
    tags$div(class = "dt-kpi", tags$span("Worst case"), tags$b(class = if (identical(sol$objective, "minimise") || rec$Worst < 0) "neg" else "", dt_fmt(rec$Worst, cur))),
    if (!identical(sol$objective, "minimise")) tags$div(class = "dt-kpi", tags$span("Chance of a loss"), tags$b(dt_pct(rec$PLoss))),
    tags$div(class = "dt-kpi", tags$span("Outcomes on the plan"), tags$b(rec$Outcomes)))
  tagList(tags$div(class = "dt-reco-row", head, kpis),
          if (length(sol$plan)) tags$div(class = "dt-plan", tags$b("The plan: "), tags$ol(lapply(sol$plan, tags$li))))
}

dt_checks_ui <- function(v) {
  if (!length(v$errors) && !length(v$warnings)) return(tags$div(class = "dt-ok", icon("check-circle"), " The tree is complete: every chance node's probabilities add up to 1 and every path ends in a payoff."))
  tagList(lapply(v$errors, function(e) tags$div(class = "dt-err", icon("times-circle"), " ", e)),
          lapply(v$warnings, function(w) tags$div(class = "dt-warn", icon("exclamation-triangle"), " ", w)))
}

# Full report used by render_diagram() for a stored decision tree (Visualisations tab, exports).
render_decision_tree <- function(components_df) {
  x <- dt_rows_to_nodes(components_df)
  v <- dt_validate(x$nodes)
  sol <- if (!length(v$errors)) dt_solve(x$nodes, x$meta) else NULL
  tagList(
    tags$div(class = "dt-svg-wrap", dt_svg(x$nodes, x$meta, sol)),
    if (!is.null(sol)) tagList(
      dt_recommendation_ui(sol, x$meta),
      tags$h4(class = "dt-h", "Risk profile of each first option"),
      tags$p(class = "dt-muted", "Expected value ignores attitude to risk: compare the worst case and the chance of a loss before deciding."),
      dt_risk_table(sol),
      tags$h4(class = "dt-h", "How sure must we be? (critical probabilities)"),
      dt_prob_table(dt_sensitivity_prob(sol), top = 8),
      tags$h4(class = "dt-h", "How wrong can the numbers be?"),
      dt_value_table(dt_sensitivity_values(sol), sol$currency, top = 8),
      tags$details(class = "dt-steps", tags$summary("Calculation steps"), tags$pre(paste(sol$steps, collapse = "\n")))
    ) else dt_checks_ui(v)
  )
}

# Short plain-text summary (Business Consulting context and the Editing Tool's explanation).
dt_summary_text <- function(nodes, meta, sol = NULL) {
  if (is.null(sol)) { v <- dt_validate(nodes); if (length(v$errors)) return(paste("Decision tree (incomplete):", paste(v$errors, collapse = " "))); sol <- dt_solve(nodes, meta) }
  cur <- sol$currency; rp <- dt_risk_profile(sol)
  sp <- dt_sensitivity_prob(sol); sv <- dt_sensitivity_values(sol)
  lines <- c(sprintf("DECISION TREE: \"%s\". Question: %s", meta$title %dt||% "", meta$question %dt||% ""),
    sprintf("Objective: %s expected value. Currency: %s.", meta$objective %dt||% "maximise", cur),
    if (!is.na(sol$recommended)) sprintf("Recommended first decision: %s (expected value %s).", dt_branch_name(sol$pr, sol$recommended), dt_fmt(sol$root_value, cur))
    else sprintf("Expected value of the tree: %s.", dt_fmt(sol$root_value, cur)),
    "Options:", sprintf("  - %s: EV %s, best %s, worst %s, chance of a loss %s", rp$Option, dt_fmt(rp$EV, cur), dt_fmt(rp$Best, cur), dt_fmt(rp$Worst, cur), dt_pct(rp$PLoss)),
    if (length(sol$plan)) c("Plan:", paste0("  - ", sol$plan)),
    if (!is.null(sp) && nrow(sp)) c("Most sensitive probabilities:", paste0("  - ", head(sprintf("%s / %s (now %s): %s", sp$Chance, sp$Branch, dt_p(sp$Current), ifelse(nzchar(sp$Change), sp$Change, "never changes the plan")), 3))),
    if (!is.null(sv) && nrow(sv)) c("Most sensitive numbers:", paste0("  - ", head(sprintf("%s (now %s): %s", sv$Item, dt_fmt(sv$Current, cur), sv$Change), 3))),
    "Assumptions:", paste0("  - ", nodes$node_id[nzchar(nodes$notes)], ": ", nodes$notes[nzchar(nodes$notes)]))
  paste(lines, collapse = "\n")
}

dt_explain_prompt <- function(summary_text) paste0(
  "You are a strategy consultant. Below is a decision tree that the app has already calculated (all numbers are correct; do not recalculate them).\n\n",
  summary_text, "\n\n",
  "Write a short briefing for a busy manager, 180-260 words, in plain English, as 4 short paragraphs with these bold lead-ins: ",
  "**Recommendation**, **Why**, **Main risks**, **Check before deciding**. Mention the worst case and the chance of a loss, ",
  "explain which probability or number would change the decision (use the sensitivity lines), note that expected value ignores ",
  "attitude to risk, and list the two or three assumptions most worth verifying. No headings, no tables, no preamble.")
