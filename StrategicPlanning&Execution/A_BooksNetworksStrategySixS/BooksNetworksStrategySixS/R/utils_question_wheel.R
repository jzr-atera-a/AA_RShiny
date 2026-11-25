# R/utils_question_wheel.R
# ==================================================================================================
# HARD DECISION QUESTIONS WHEEL (Strategic Analysis framework id: decision_questions_wheel)
#
# A round "pizza" of 20 questions in 4 angles of analysis, asked before a hard decision:
#   Problem & Purpose (top left)  Facts & Options (top right)
#   People & Action (bottom left) Risks & Costs (bottom right)
# The 20 questions are FIXED by this catalogue (the Editing Tool never rewrites them); the Editing Tool
# only answers each one for the user's decision, marks how well it is answered (clear / partial /
# open) and adds evidence to gather or next steps. The renderer draws the wheel itself as SVG, and a
# click on any slice, any of the 4 hub sections or the centre opens a pop-up box with more context
# (www/js/question_wheel.js). Stored rows (strategy_diagrams table, no new columns):
#   title          component_type = title,          sub_text = the decision in one sentence
#   4 x angle      component_type = region_quadrant, layout_role = quadrant_region, quadrant_position,
#                  sub_text = what this angle shows for the decision, items_packed = key takeaways
#   20 x question  component_type = wheel_slice,     layout_role = node, quadrant_position,
#                  sequence_order = 1..20, label_text = the question, sub_text = the answer,
#                  items_packed = evidence to gather / next steps, color_hint = clear|partial|open
#   1 x verdict    component_type = text_label,      layout_role = annotation, label_text = Verdict,
#                  sub_text = recommendation, items_packed = next steps
# Sources: Andy Grove's 1985 question to Gordon Moore at Intel ("If we got kicked out and the board
# brought in a new CEO, what do you think he would do?"), condensed to "What would my replacement
# do?", and a 20-question pre-decision checklist shared by CEO coach Eric Partaker (2026).
# ==================================================================================================

QW_QUADRANTS <- list(
  top_left = list(name = "Problem & Purpose", short = c("Problem &", "Purpose"), icon = "target",
                  fill = "#FCE3D2", strong = "#F6BE98", line = "#E07B39",
                  angle = "Pin down the decision itself before looking at answers: what is being decided, why now, who decides, and what a good result looks like.",
                  ask = "Is this the right problem, framed the right way, decided by the right person?"),
  top_right = list(name = "Facts & Options", short = c("Facts &", "Options"), icon = "search",
                   fill = "#DDE8F8", strong = "#A9C6EF", line = "#2F6FD6",
                   angle = "Separate what is known from what is assumed, widen the set of options, and test the choice from an outsider's point of view.",
                   ask = "Are we choosing from the full set of options on evidence rather than habit?"),
  bottom_right = list(name = "Risks & Costs", short = c("Risks &", "Costs"), icon = "shield",
                      fill = "#E9E2F6", strong = "#C7B4EC", line = "#6C3FC5",
                      angle = "Size the downside, the reversibility and the cost of delay, and imagine the failure before it happens.",
                      ask = "Do we understand what we could lose, and can we live with it?"),
  bottom_left = list(name = "People & Action", short = c("People &", "Action"), icon = "people",
                     fill = "#D8EFF2", strong = "#A3D9E0", line = "#1A9AA8",
                     angle = "Turn the choice into action: who is affected, who must be heard, how it is explained, who owns it and when it is reviewed.",
                     ask = "Will people understand, accept and carry out the decision?")
)
# Drawing order, clockwise from 9 o'clock: Problem -> Facts -> Risks -> People (questions 1..20 in that order)
QW_QUADRANT_ORDER <- c("top_left", "top_right", "bottom_right", "bottom_left")

.qw <- function(q, quad, why, how, flag) list(q = q, quad = quad, why = why, how = how, flag = flag)
QW_QUESTIONS <- list(
  .qw("What exactly are we deciding?", "top_left",
      "Many hard decisions are hard because nobody has written down the actual choice. A vague question produces a vague answer and endless debate.",
      "State the decision in one sentence that starts with \"Should we...\" or \"Which of...\", with the scope and the deadline.",
      "People describe the decision differently, or the sentence contains two decisions."),
  .qw("Why does this matter now?", "top_left",
      "Urgency and importance are different things. Knowing what triggered the decision tells you how much time and effort it deserves.",
      "Name the trigger (a deadline, a competitor move, a lost customer) and what changes if it is decided this month rather than next quarter.",
      "Nobody can say what made it urgent, or the urgency is only someone's impatience."),
  .qw("What happens if we do nothing?", "top_left",
      "Waiting is also a choice, and it has a price. Making the do-nothing path explicit stops it from winning by default.",
      "Describe the status quo 6 and 12 months out: costs, lost revenue, morale, competitive position.",
      "Doing nothing is assumed to be free or safe."),
  .qw("Who should make this call?", "top_left",
      "A decision with an unclear decider gets re-opened, escalated or quietly ignored.",
      "Name one decider, the people who give input and the people who must approve; agree whether it is a consensus or a consult-then-decide call.",
      "Several people believe they have the final say, or no one does."),
  .qw("What would success look like?", "top_left",
      "Without a picture of success you cannot compare options or know later whether the decision worked.",
      "Write 2-3 measurable outcomes with a date, and the minimum result you would still call a success.",
      "Success is described only in feelings, or every option could be called a success."),
  .qw("What do we know for sure?", "top_right",
      "Hard facts anchor the discussion and expose how much of the debate rests on opinion.",
      "List the verified facts with their source and date; keep opinions and forecasts in a separate list.",
      "The list of facts is short, old or comes from a single source."),
  .qw("What are we assuming?", "top_right",
      "Every plan rests on assumptions; the dangerous ones are those nobody noticed were assumptions.",
      "List the assumptions, mark how confident you are in each and which one would hurt most if wrong. Test that one first.",
      "Key numbers in the plan have never been checked against reality."),
  .qw("What are all our options?", "top_right",
      "Teams often frame a choice as yes or no. Adding even one more option improves decisions markedly.",
      "Generate at least three real options, including a hybrid, a smaller pilot and the do-nothing option.",
      "Only one option is on the table, or the alternatives are straw men."),
  .qw("What would change my mind?", "top_right",
      "Deciding up front which new facts would make you change course protects you from confirmation bias and sunk costs.",
      "Write down the specific evidence or thresholds (a price, a churn rate, a test result) that would make you reverse the choice.",
      "Nothing anyone could show you would change your view."),
  .qw("What would my replacement do?", "top_right",
      "A new leader arrives with no history and no attachment to the old plan. In 1985 Andy Grove asked Gordon Moore what a new CEO would do about Intel's memory business; the answer, leave memories, led Intel to bet on microprocessors.",
      "Imagine you were replaced tomorrow by a capable outsider. What would they stop, keep and start? Then ask why you are not doing it.",
      "The answer is obvious but the plan still protects a legacy product, team or past decision."),
  .qw("What's the worst that could happen?", "bottom_right",
      "Sizing the realistic worst case tells you whether a failure is survivable and how much protection to buy.",
      "Describe the worst plausible outcome, its probability and its cost, and whether the organisation (or you) could absorb it.",
      "The worst case would be fatal, or nobody has looked at it."),
  .qw("Can we undo this later?", "bottom_right",
      "Reversible (two-way door) decisions should be made fast; irreversible (one-way door) decisions deserve slower thinking and a test first.",
      "Classify the decision as reversible, partly reversible or irreversible, and what it would cost to reverse.",
      "An irreversible decision is being rushed, or a reversible one is being over-analysed."),
  .qw("What does it cost us to wait?", "bottom_right",
      "Delay has a price: missed revenue, rising costs, lost talent or a closing window. Waiting for perfect information is rarely free.",
      "Estimate the cost per week or month of delay and compare it with the value of the information you would gain by waiting.",
      "The team keeps asking for more data without saying what it would change."),
  .qw("What could we be missing?", "bottom_right",
      "Blind spots come from the people, data and perspectives not in the room.",
      "Ask someone outside the team, a sceptic or a customer to attack the plan; look for second-order effects.",
      "Everyone in the room agrees and nobody has argued the other side."),
  .qw("If this fails, why did it fail?", "bottom_right",
      "A pre-mortem (Gary Klein) imagines the decision has already failed and asks why. It surfaces risks people are reluctant to raise.",
      "Imagine it is a year later and the decision failed. Write the three most likely reasons, then add a safeguard for each.",
      "The failure reasons are easy to list but the plan has no safeguard for them."),
  .qw("Who does this affect most?", "bottom_left",
      "The people most affected carry the consequences and often hold the knowledge that makes the plan work.",
      "Map the affected groups (customers, staff, partners, investors) and how strongly each is affected.",
      "The most affected group has not been considered or consulted."),
  .qw("Who needs to be heard first?", "bottom_left",
      "Order matters: people who hear about a decision second-hand are more likely to resist it.",
      "Decide who must be consulted before the decision and who must be told first after it, and in what order.",
      "Key people will learn about the decision from rumour or the press."),
  .qw("How will we explain the decision?", "bottom_left",
      "If you cannot explain the decision simply, you may not understand it well enough, and others will not support it.",
      "Draft the explanation in three sentences: what we decided, why, and what it means for the listener.",
      "The explanation needs a long slide deck, or it sounds different for each audience."),
  .qw("Who owns it once it's made?", "bottom_left",
      "Without one clear owner, the same decision comes back next month.",
      "Name one accountable owner, the resources they have and the first milestones.",
      "Ownership is shared by a committee, or the owner lacks the authority or budget."),
  .qw("When will we review the result?", "bottom_left",
      "A planned review turns the decision into a learning loop and catches problems before they grow.",
      "Set a review date, the measures you will look at and the thresholds that would trigger a change of course (link to question 9).",
      "No date is set, so the decision is only reviewed when it is already failing.")
)

QW_STATUS <- list(
  clear = list(label = "Clear answer", color = "#2E9D5B"),
  partial = list(label = "Partly answered", color = "#E3A21A"),
  open = list(label = "Open / red flag", color = "#D64541"),
  none = list(label = "Not answered yet", color = "#A7A9AC")
)
qw_status_key <- function(x) {
  x <- tolower(trimws(as.character(x %||% "")))
  if (is.na(x) || !nzchar(x)) return("none")
  if (grepl("clear|green|done|answered|yes", x) && !grepl("partial|part", x)) return("clear")
  if (grepl("partial|part|amber|yellow|some", x)) return("partial")
  if (grepl("open|red|flag|no|unknown|gap|risk", x)) return("open")
  "none"
}

# ---- Prompt pieces (used by framework_specific_guidance / diagram_type_instructions) ------------------
qw_framework_guidance <- function() {
  qs <- vapply(seq_along(QW_QUESTIONS), function(i) {
    q <- QW_QUESTIONS[[i]]
    sprintf("  %d. [%s] %s", i, q$quad, q$q)
  }, "")
  paste0(
    'FRAMEWORK = Hard Decision Questions Wheel: 20 questions to ask before a hard decision, in 4 angles of ',
    'analysis. The angles and their FIXED quadrant_position values are: Problem & Purpose = top_left; ',
    'Facts & Options = top_right; Risks & Costs = bottom_right; People & Action = bottom_left. The 20 questions ',
    'are FIXED - copy each one exactly as label_text with its number as sequence_order and its quadrant_position:\n',
    paste(qs, collapse = "\n"), '\n',
    'Answer EVERY question for the specific decision in the user request (sub_text, 2-3 concrete sentences; ',
    'if the request does not give enough information, say plainly what is unknown and how to find out - never ',
    'invent facts, figures or quotes). Question 10 ("What would my replacement do?") must answer as a capable ',
    'outsider with no attachment to past choices. Question 15 is a pre-mortem: assume the decision failed and ',
    'give the most likely reasons. Mark each answer with color_hint = clear (well answered from the request), ',
    'partial (partly answered) or open (unanswered or a red flag that needs work before deciding).\n\n'
  )
}

qw_shape_block <- function(sep) {
  paste0(
    'Output these blocks in this order.\n\n',
    'Title block (exactly one):\n[component_type]: title\n[layout_role]: title\n[label_text]: <diagram title>\n',
    '[sub_text]: <the decision being made, in one sentence>\n\n',
    'Angle blocks (exactly 4, one per quadrant_position given above):\n',
    '[component_type]: region_quadrant\n[layout_role]: quadrant_region\n',
    '[quadrant_position]: <top_left|top_right|bottom_right|bottom_left>\n',
    '[label_text]: <angle name exactly as given above>\n',
    '[sub_text]: <1-2 sentences: what this angle reveals about THIS decision>\n',
    '[items_packed]: <key takeaway 1>', sep, '<key takeaway 2>', sep, '<key takeaway 3>\n\n',
    'Question blocks (exactly 20, sequence_order 1..20):\n',
    '[component_type]: wheel_slice\n[layout_role]: node\n',
    '[quadrant_position]: <the quadrant_position of this question as given above>\n',
    '[sequence_order]: <question number 1..20>\n',
    '[label_text]: <the question exactly as given above>\n',
    '[sub_text]: <the answer for this decision, 2-3 sentences>\n',
    '[items_packed]: <evidence to gather or next step 1>', sep, '<next step 2> (N/A if none)\n',
    '[color_hint]: <clear|partial|open>\n\n',
    'Verdict block (exactly one, last):\n[component_type]: text_label\n[layout_role]: annotation\n',
    '[label_text]: Verdict\n',
    '[sub_text]: <2-3 sentences: decide now, test first, or wait for named information - and why, based on the answers>\n',
    '[items_packed]: <next step 1>', sep, '<next step 2>', sep, '<next step 3>\n'
  )
}

# Extra settings from the Generate tab, folded into the request text
qw_settings_request <- function(options_text = "", deadline = "", decider = "") {
  parts <- character(0)
  if (nzchar(trimws(options_text %||% ""))) parts <- c(parts, paste0("Options being considered: ", trimws(options_text), "."))
  if (nzchar(trimws(deadline %||% ""))) parts <- c(parts, paste0("Decision deadline: ", trimws(deadline), "."))
  if (nzchar(trimws(decider %||% ""))) parts <- c(parts, paste0("Who is deciding: ", trimws(decider), "."))
  if (length(parts) == 0) "" else paste0(" ", paste(parts, collapse = " "))
}

# ---- Text helpers --------------------------------------------------------------------------------------
qw_wrap <- function(text, width = 20, max_lines = 3) {
  words <- strsplit(trimws(text), "\\s+")[[1]]
  lines <- character(0); cur <- ""
  for (w in words) {
    cand <- if (nzchar(cur)) paste(cur, w) else w
    if (nchar(cand) > width && nzchar(cur)) { lines <- c(lines, cur); cur <- w } else cur <- cand
  }
  if (nzchar(cur)) lines <- c(lines, cur)
  if (length(lines) > max_lines) {
    lines <- c(lines[seq_len(max_lines - 1)], paste(lines[max_lines:length(lines)], collapse = " "))
  }
  lines
}
qw_esc <- function(x) htmltools::htmlEscape(as.character(x %||% ""))

# Point on the wheel: angle in degrees clockwise from 12 o'clock
qw_pt <- function(cx, cy, r, deg) { a <- deg * pi / 180; c(cx + r * sin(a), cy - r * cos(a)) }
qw_sector_path <- function(cx, cy, r0, r1, a0, a1) {
  p1 <- qw_pt(cx, cy, r1, a0); p2 <- qw_pt(cx, cy, r1, a1)
  large <- if ((a1 - a0) > 180) 1 else 0
  if (r0 <= 0) {
    return(sprintf("M %.2f %.2f L %.2f %.2f A %.2f %.2f 0 %d 1 %.2f %.2f Z", cx, cy, p1[1], p1[2], r1, r1, large, p2[1], p2[2]))
  }
  p3 <- qw_pt(cx, cy, r0, a1); p4 <- qw_pt(cx, cy, r0, a0)
  sprintf("M %.2f %.2f A %.2f %.2f 0 %d 1 %.2f %.2f L %.2f %.2f A %.2f %.2f 0 %d 0 %.2f %.2f Z",
          p1[1], p1[2], r1, r1, large, p2[1], p2[2], p3[1], p3[2], r0, r0, large, p4[1], p4[2])
}

# Simple line icons for the hub (no icon font needed, so exports keep them)
qw_icon_svg <- function(icon, x, y, color) {
  s <- function(...) sprintf(...)
  switch(icon,
    target = s('<g stroke="%s" stroke-width="3" fill="none"><circle cx="%.1f" cy="%.1f" r="17"/><circle cx="%.1f" cy="%.1f" r="10"/><circle cx="%.1f" cy="%.1f" r="3" fill="%s"/><line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f"/></g>',
               color, x, y, x, y, x, y, color, x, y, x + 15, y - 15),
    search = s('<g stroke="%s" stroke-width="3" fill="none"><circle cx="%.1f" cy="%.1f" r="12"/><line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f"/><line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f"/><line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f"/></g>',
               color, x - 3, y - 3, x + 6, y + 6, x + 16, y + 16, x - 9, y - 3, x + 3, y - 3, x - 3, y - 9, x - 3, y + 3),
    shield = s('<g stroke="%s" stroke-width="3" fill="none"><path d="M %.1f %.1f L %.1f %.1f L %.1f %.1f Q %.1f %.1f %.1f %.1f Q %.1f %.1f %.1f %.1f L %.1f %.1f Z"/><line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f"/><circle cx="%.1f" cy="%.1f" r="1.5" fill="%s"/></g>',
               color, x, y - 18, x + 15, y - 12, x + 15, y, x + 15, y + 12, x, y + 19, x - 15, y + 12, x - 15, y, x - 15, y - 12,
               x, y - 9, x, y + 3, x, y + 9, color),
    people = s('<g stroke="%s" stroke-width="3" fill="none"><circle cx="%.1f" cy="%.1f" r="7"/><path d="M %.1f %.1f Q %.1f %.1f %.1f %.1f"/><circle cx="%.1f" cy="%.1f" r="6"/><path d="M %.1f %.1f Q %.1f %.1f %.1f %.1f"/></g>',
               color, x - 7, y - 8, x - 20, y + 15, x - 7, y - 3, x + 6, y + 15, x + 9, y - 9, x + 3, y + 7, x + 12, y - 2, x + 21, y + 13),
    ""
  )
}

# ---- Rows -> wheel model -----------------------------------------------------------------------------
# components_df may be NULL (blank template, used by the Tool Guide): the fixed questions are drawn
# with no answers and the pop-ups show the built-in context only.
qw_model <- function(components_df) {
  df <- components_df
  get_rows <- function(type) {
    if (is.null(df) || nrow(df) == 0) return(df[0, , drop = FALSE])
    df[!is.na(df$component_type) & df$component_type == type, , drop = FALSE]
  }
  title_row <- get_rows("title")
  title <- if (!is.null(title_row) && nrow(title_row) > 0 && has_real_value(title_row$label_text[1])) title_row$label_text[1] else
    if (!is.null(df) && nrow(df) > 0 && has_real_value(df$title[1])) df$title[1] else "Hard Decision Questions Wheel"
  decision <- if (!is.null(title_row) && nrow(title_row) > 0 && has_real_value(title_row$sub_text[1])) title_row$sub_text[1] else ""

  slices <- get_rows("wheel_slice")
  answers <- vector("list", length(QW_QUESTIONS))
  norm <- function(s) gsub("[^a-z]", "", tolower(s %||% ""))
  qnorm <- vapply(QW_QUESTIONS, function(q) norm(q$q), "")
  if (!is.null(slices) && nrow(slices) > 0) {
    for (i in seq_len(nrow(slices))) {
      k <- suppressWarnings(as.integer(slices$sequence_order[i]))
      if (is.na(k) || k < 1 || k > 20) k <- match(norm(slices$label_text[i]), qnorm)
      if (is.na(k)) next
      answers[[k]] <- list(answer = if (has_real_value(slices$sub_text[i])) slices$sub_text[i] else "",
                           items = diagram_unpack_items(slices$items_packed[i] %||% ""),
                           status = qw_status_key(slices$color_hint[i]))
      # an answer without a status is shown as partly answered rather than "not answered yet"
      if (nzchar(answers[[k]]$answer) && identical(answers[[k]]$status, "none")) answers[[k]]$status <- "partial"
    }
  }
  quads <- get_rows("region_quadrant")
  quad_ans <- list()
  if (!is.null(quads) && nrow(quads) > 0) {
    for (i in seq_len(nrow(quads))) {
      p <- quads$quadrant_position[i]
      if (is.na(p) || !p %in% QW_QUADRANT_ORDER) {
        p <- names(QW_QUADRANTS)[match(norm(quads$label_text[i]), vapply(QW_QUADRANTS, function(q) norm(q$name), ""))]
      }
      if (length(p) == 0 || is.na(p)) next
      quad_ans[[p]] <- list(summary = if (has_real_value(quads$sub_text[i])) quads$sub_text[i] else "",
                            items = diagram_unpack_items(quads$items_packed[i] %||% ""))
    }
  }
  verdict_rows <- get_rows("text_label")
  verdict <- NULL
  if (!is.null(verdict_rows) && nrow(verdict_rows) > 0) {
    v <- verdict_rows[1, ]
    verdict <- list(text = if (has_real_value(v$sub_text)) v$sub_text else "", items = diagram_unpack_items(v$items_packed %||% ""))
  }
  list(title = title, decision = decision, answers = answers, quads = quad_ans, verdict = verdict)
}

# ---- Pop-up content (JSON read by www/js/question_wheel.js) ---------------------------------------------
qw_popups <- function(m) {
  pops <- list()
  n_ans <- sum(vapply(m$answers, function(a) !is.null(a) && nzchar(a$answer), TRUE))
  for (i in seq_along(QW_QUESTIONS)) {
    q <- QW_QUESTIONS[[i]]; qd <- QW_QUADRANTS[[q$quad]]; a <- m$answers[[i]]
    st <- QW_STATUS[[if (is.null(a)) "none" else a$status]]
    secs <- list(
      list(h = "Why this question matters", p = q$why),
      list(h = "How to answer it well", p = q$how),
      list(h = "Warning sign", p = q$flag)
    )
    if (!is.null(a) && nzchar(a$answer)) secs <- c(list(list(h = "For this decision", p = a$answer, accent = TRUE)), secs)
    if (!is.null(a) && length(a$items)) secs <- append(secs, list(list(h = "Evidence to gather / next steps", li = as.list(a$items))), after = 1)
    pops[[paste0("q", i)]] <- list(
      kicker = sprintf("%s  -  question %d of 20", qd$name, i), title = q$q, color = qd$line,
      badge = st$label, badge_color = st$color, angle = qd$angle, sections = secs,
      prev = if (i > 1) paste0("q", i - 1) else NULL, nxt = if (i < 20) paste0("q", i + 1) else "verdict")
  }
  for (p in QW_QUADRANT_ORDER) {
    qd <- QW_QUADRANTS[[p]]; qa <- m$quads[[p]]
    idx <- which(vapply(QW_QUESTIONS, function(q) q$quad == p, TRUE))
    secs <- list(list(h = "What this angle looks at", p = qd$angle), list(h = "The test", p = qd$ask))
    if (!is.null(qa) && nzchar(qa$summary)) secs <- c(list(list(h = "For this decision", p = qa$summary, accent = TRUE)), secs)
    if (!is.null(qa) && length(qa$items)) secs <- append(secs, list(list(h = "Key takeaways", li = as.list(qa$items))), after = 1)
    secs <- c(secs, list(list(h = "Questions in this angle (click one to open it)",
      links = lapply(idx, function(i) list(key = paste0("q", i), text = sprintf("%d. %s", i, QW_QUESTIONS[[i]]$q),
                                           color = QW_STATUS[[if (is.null(m$answers[[i]])) "none" else m$answers[[i]]$status]]$color)))))
    pops[[paste0("quad_", p)]] <- list(kicker = "Angle of analysis", title = qd$name, color = qd$line, sections = secs)
  }
  vsecs <- list()
  if (nzchar(m$decision)) vsecs <- c(vsecs, list(list(h = "The decision", p = m$decision)))
  if (!is.null(m$verdict) && nzchar(m$verdict$text)) vsecs <- c(vsecs, list(list(h = "Verdict", p = m$verdict$text, accent = TRUE)))
  if (!is.null(m$verdict) && length(m$verdict$items)) vsecs <- c(vsecs, list(list(h = "Next steps", li = as.list(m$verdict$items))))
  cnt <- table(factor(vapply(m$answers, function(a) if (is.null(a)) "none" else a$status, ""), levels = names(QW_STATUS)))
  vsecs <- c(vsecs, list(list(h = "Readiness", p = sprintf("%d of 20 questions answered: %d clear, %d partly answered, %d open or red flags.",
                                                            n_ans, cnt[["clear"]], cnt[["partial"]], cnt[["open"]]))),
             list(list(h = "How to use the wheel", p = paste(
               "Work round the four angles: frame the problem, check facts and options, size risks and costs, then plan the people and the action.",
               "Open questions (red) are where to spend effort before deciding. If the decision can be undone (question 12), decide fast; if not, slow down and test it first."))))
  pops[["verdict"]] <- list(kicker = "Centre of the wheel", title = if (nzchar(m$decision)) "Verdict and readiness" else "About this wheel",
                            color = "#2B3A4A", sections = vsecs, prev = "q20", nxt = "q1")
  pops
}

# ---- Renderer -------------------------------------------------------------------------------------------
render_question_wheel <- function(components_df = NULL, show_list = TRUE) {
  m <- qw_model(components_df)
  W <- 1000; cx <- 500; cy <- 500; R <- 460; r_hub <- 190; r_core <- 62
  slice_deg <- 18
  start <- 270   # 9 o'clock, then clockwise

  parts <- character(0)
  # 20 slices
  for (i in seq_along(QW_QUESTIONS)) {
    q <- QW_QUESTIONS[[i]]; qd <- QW_QUADRANTS[[q$quad]]; a <- m$answers[[i]]
    a0 <- start + (i - 1) * slice_deg; a1 <- a0 + slice_deg; mid <- (a0 + a1) / 2
    st_key <- if (is.null(a)) "none" else a$status
    fill <- if (st_key %in% c("clear")) qd$strong else qd$fill
    parts <- c(parts, sprintf(
      '<path class="qw-hit qw-slice" data-qw="q%d" tabindex="0" role="button" aria-label="%s" d="%s" fill="%s" stroke="%s" stroke-width="2"><title>%s</title></path>',
      i, qw_esc(q$q), qw_sector_path(cx, cy, r_hub, R, a0, a1), fill, qd$line, qw_esc(q$q)))
    # rotated label along the radius; flip on the left half so it stays readable
    md <- mid %% 360
    rot <- if (md < 180) md - 90 else md + 90
    lines <- qw_wrap(q$q, 19, 3)
    rm <- (r_hub + R) / 2 + 6
    p <- qw_pt(cx, cy, rm, mid)
    lh <- 17
    y0 <- -((length(lines) - 1) * lh) / 2
    tsp <- paste(vapply(seq_along(lines), function(j) sprintf('<tspan x="0" y="%.1f">%s</tspan>', y0 + (j - 1) * lh, qw_esc(lines[j])), ""), collapse = "")
    parts <- c(parts, sprintf(
      '<g transform="translate(%.2f %.2f) rotate(%.2f)" pointer-events="none"><text text-anchor="middle" dominant-baseline="middle" font-size="15" font-weight="600" fill="#26323D" font-family="Helvetica, Arial, sans-serif">%s</text></g>',
      p[1], p[2], rot, tsp))
    # number + status dot near the rim
    pd <- qw_pt(cx, cy, R - 20, mid)
    parts <- c(parts, sprintf(
      '<g pointer-events="none"><circle cx="%.2f" cy="%.2f" r="11" fill="%s" stroke="white" stroke-width="2"/><text x="%.2f" y="%.2f" text-anchor="middle" dominant-baseline="central" font-size="10.5" font-weight="700" fill="white" font-family="Helvetica, Arial, sans-serif">%d</text></g>',
      pd[1], pd[2], QW_STATUS[[st_key]]$color, pd[1], pd[2] + 0.5, i))
  }
  # hub: 4 quadrant sectors
  for (k in seq_along(QW_QUADRANT_ORDER)) {
    p <- QW_QUADRANT_ORDER[k]; qd <- QW_QUADRANTS[[p]]
    a0 <- start + (k - 1) * 90; a1 <- a0 + 90; mid <- a0 + 45
    parts <- c(parts, sprintf(
      '<path class="qw-hit qw-quad" data-qw="quad_%s" tabindex="0" role="button" aria-label="%s" d="%s" fill="%s" stroke="#26323D" stroke-width="2.5"><title>%s</title></path>',
      p, qw_esc(qd$name), qw_sector_path(cx, cy, r_core, r_hub, a0, a1), qd$fill, qw_esc(qd$name)))
    pc <- qw_pt(cx, cy, (r_core + r_hub) / 2 + 8, mid)
    up <- p %in% c("top_left", "top_right")
    icon_y <- if (up) pc[2] - 38 else pc[2] + 38
    text_y <- if (up) pc[2] + 2 else pc[2] - 30
    parts <- c(parts, sprintf('<g pointer-events="none">%s<text text-anchor="middle" font-size="21" font-weight="800" fill="#1F2A36" font-family="Helvetica, Arial, sans-serif"><tspan x="%.1f" y="%.1f">%s</tspan><tspan x="%.1f" y="%.1f">%s</tspan></text></g>',
      qw_icon_svg(qd$icon, pc[1], icon_y, qd$line), pc[1], text_y, qw_esc(qd$short[1]), pc[1], text_y + 25, qw_esc(qd$short[2])))
  }
  # outer rim + quadrant dividers
  parts <- c(parts, sprintf('<circle cx="%d" cy="%d" r="%d" fill="none" stroke="#26323D" stroke-width="3" pointer-events="none"/>', cx, cy, R))
  for (deg in c(0, 90, 180, 270)) {
    p1 <- qw_pt(cx, cy, r_core, deg); p2 <- qw_pt(cx, cy, R, deg)
    parts <- c(parts, sprintf('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#26323D" stroke-width="3" pointer-events="none"/>', p1[1], p1[2], p2[1], p2[2]))
  }
  parts <- c(parts, sprintf('<circle cx="%d" cy="%d" r="%d" fill="none" stroke="#26323D" stroke-width="3" pointer-events="none"/>', cx, cy, r_hub))
  # centre: readiness / verdict
  n_ans <- sum(vapply(m$answers, function(a) !is.null(a) && nzchar(a$answer), TRUE))
  n_clear <- sum(vapply(m$answers, function(a) !is.null(a) && identical(a$status, "clear"), TRUE))
  core_main <- if (n_ans > 0) sprintf("%d/20", n_clear) else "20"
  core_sub <- if (n_ans > 0) "clear" else "questions"
  parts <- c(parts, sprintf(
    '<g class="qw-hit qw-core" data-qw="verdict" tabindex="0" role="button" aria-label="Verdict and readiness"><title>Verdict and readiness</title><circle cx="%d" cy="%d" r="%d" fill="#2B3A4A" stroke="white" stroke-width="3"/><text x="%d" y="%d" text-anchor="middle" font-size="24" font-weight="800" fill="white" font-family="Helvetica, Arial, sans-serif">%s</text><text x="%d" y="%d" text-anchor="middle" font-size="13" fill="#D7E1EA" font-family="Helvetica, Arial, sans-serif">%s</text></g>',
    cx, cy, r_core, cx, cy + 2, core_main, cx, cy + 22, core_sub))

  svg <- sprintf('<svg class="qw-svg" viewBox="0 0 %d %d" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="%s">%s</svg>',
                 W, W, qw_esc(m$title), paste(parts, collapse = ""))

  legend <- paste(vapply(names(QW_STATUS), function(k) sprintf('<span class="qw-legend-item"><span class="qw-dot" style="background:%s"></span>%s</span>',
                                                                QW_STATUS[[k]]$color, QW_STATUS[[k]]$label), ""), collapse = "")

  json <- jsonlite::toJSON(qw_popups(m), auto_unbox = TRUE, null = "null")
  json <- gsub("</", "<\\/", json, fixed = TRUE)

  list_html <- ""
  if (show_list) {
    blocks <- vapply(QW_QUADRANT_ORDER, function(p) {
      qd <- QW_QUADRANTS[[p]]
      idx <- which(vapply(QW_QUESTIONS, function(q) q$quad == p, TRUE))
      qa <- m$quads[[p]]
      items <- paste(vapply(idx, function(i) {
        a <- m$answers[[i]]; st <- QW_STATUS[[if (is.null(a)) "none" else a$status]]
        ans <- if (!is.null(a) && nzchar(a$answer)) sprintf('<div class="qw-list-ans">%s</div>', qw_esc(a$answer)) else ""
        sprintf('<li><button type="button" class="qw-link" data-qw="q%d"><span class="qw-dot" style="background:%s"></span>%d. %s</button>%s</li>',
                i, st$color, i, qw_esc(QW_QUESTIONS[[i]]$q), ans)
      }, ""), collapse = "")
      summ <- if (!is.null(qa) && nzchar(qa$summary)) sprintf('<p class="qw-list-sum">%s</p>', qw_esc(qa$summary)) else ""
      sprintf('<div class="qw-list-block" style="border-top-color:%s"><button type="button" class="qw-link qw-list-head" data-qw="quad_%s" style="color:%s">%s</button>%s<ul>%s</ul></div>',
              qd$line, p, qd$line, qw_esc(qd$name), summ, items)
    }, "")
    verdict_html <- if (!is.null(m$verdict) && nzchar(m$verdict$text)) {
      sprintf('<div class="qw-verdict"><strong>Verdict:</strong> %s%s</div>', qw_esc(m$verdict$text),
              if (length(m$verdict$items)) paste0('<ul>', paste(sprintf('<li>%s</li>', qw_esc(m$verdict$items)), collapse = ""), '</ul>') else "")
    } else ""
    list_html <- sprintf('%s<details class="qw-details"%s><summary>All 20 questions%s</summary><div class="qw-list">%s</div></details>',
                         verdict_html, if (n_ans > 0) "" else "", if (n_ans > 0) " with answers" else "", paste(blocks, collapse = ""))
  }

  HTML(sprintf(
    '<div class="diagram-card qw-card"><div class="chapter-title"><i class="fa fa-chart-pie"></i> %s</div>%s<p class="qw-hint"><i class="fa fa-hand-pointer"></i> Click any slice, any of the four centre sections or the middle of the wheel for more context.</p><div class="qw-wrap">%s</div><div class="qw-legend">%s</div>%s<script type="application/json" class="qw-data">%s</script></div>',
    qw_esc(m$title),
    if (nzchar(m$decision)) sprintf('<p class="qw-decision"><strong>Decision:</strong> %s</p>', qw_esc(m$decision)) else "",
    svg, legend, list_html, json))
}

# Text block for the Add Single / Bulk Import starting point: the 20 fixed questions as rows to fill in
qw_template_text <- function(category = "Business", domain = "Leadership", topic = "Hard decisions", title = "Hard Decision Questions Wheel") {
  sep <- DIAG_ITEM_SEP
  out <- c("[decision_questions_wheel]", "[decision_making_process]", sprintf("[%s]", category), sprintf("[%s]", domain),
           sprintf("[%s]", topic), sprintf("[%s]", title), "",
           "[component_type]: title", "[layout_role]: title", sprintf("[label_text]: %s", title), "[sub_text]: <the decision in one sentence>", "")
  for (p in QW_QUADRANT_ORDER) {
    out <- c(out, "[component_type]: region_quadrant", "[layout_role]: quadrant_region", sprintf("[quadrant_position]: %s", p),
             sprintf("[label_text]: %s", QW_QUADRANTS[[p]]$name), "[sub_text]: N/A", "[items_packed]: N/A", "")
  }
  for (i in seq_along(QW_QUESTIONS)) {
    q <- QW_QUESTIONS[[i]]
    out <- c(out, "[component_type]: wheel_slice", "[layout_role]: node", sprintf("[quadrant_position]: %s", q$quad),
             sprintf("[sequence_order]: %d", i), sprintf("[label_text]: %s", q$q), "[sub_text]: N/A", "[items_packed]: N/A",
             "[color_hint]: N/A", "")
  }
  out <- c(out, "[component_type]: text_label", "[layout_role]: annotation", "[label_text]: Verdict", "[sub_text]: N/A", "[items_packed]: N/A")
  paste(out, collapse = "\n")
}
