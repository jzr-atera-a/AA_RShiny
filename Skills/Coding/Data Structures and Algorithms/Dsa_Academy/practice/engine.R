# practice/engine.R — problem bank, Python detection and the code runner bridge.
# Sourced by global.R.

PRACTICE_DIR <- normalizePath("practice", mustWork = TRUE)

# ── Problem bank ─────────────────────────────────────────────────────────────
PRACTICE <- local({
  raw <- jsonlite::fromJSON(file.path(PRACTICE_DIR, "problems.json"), simplifyVector = FALSE)
  setNames(raw, vapply(raw, function(p) p$id, ""))
})
PRACTICE_IDS <- names(PRACTICE)

PRACTICE_DF <- data.frame(
  id         = PRACTICE_IDS,
  num        = vapply(PRACTICE, function(p) as.integer(p$num), integer(1)),
  title      = vapply(PRACTICE, function(p) p$title, ""),
  difficulty = vapply(PRACTICE, function(p) p$difficulty, ""),
  topic      = vapply(PRACTICE, function(p) p$topic, ""),
  pattern    = vapply(PRACTICE, function(p) p$pattern, ""),
  meta       = vapply(PRACTICE, function(p) "Meta" %in% unlist(p$companies), logical(1)),
  google     = vapply(PRACTICE, function(p) "Google" %in% unlist(p$companies), logical(1)),
  kind       = vapply(PRACTICE, function(p) p$kind, ""),
  stringsAsFactors = FALSE)
PRACTICE_DF$companies <- ifelse(PRACTICE_DF$meta & PRACTICE_DF$google, "Meta · Google", ifelse(PRACTICE_DF$meta, "Meta", "Google"))

# ── Python detection ─────────────────────────────────────────────────────────
# Set the environment variable DSA_PYTHON to force a specific interpreter.
.python <- new.env()
python_info <- function() {
  if (!is.null(.python$info)) return(.python$info)
  cands <- list()
  env <- Sys.getenv("DSA_PYTHON", "")
  if (nzchar(env)) cands[[length(cands) + 1]] <- list(cmd = env, pre = character(0))
  for (nm in c("python3", "python")) {
    p <- Sys.which(nm)
    if (nzchar(p)) cands[[length(cands) + 1]] <- list(cmd = unname(p), pre = character(0))
  }
  if (.Platform$OS.type == "windows" && nzchar(Sys.which("py"))) cands[[length(cands) + 1]] <- list(cmd = unname(Sys.which("py")), pre = "-3")
  info <- list(ok = FALSE, cmd = NA, pre = character(0), version = NA)
  for (c in cands) {
    out <- tryCatch(suppressWarnings(system2(c$cmd, c(c$pre, "-c", shQuote("import sys; print('%d.%d.%d' % sys.version_info[:3])")),
                                             stdout = TRUE, stderr = TRUE, timeout = 10)), error = function(e) NULL)
    v <- if (length(out)) trimws(out[length(out)]) else ""
    if (grepl("^3\\.([89]|1[0-9])\\.", v)) { info <- list(ok = TRUE, cmd = c$cmd, pre = c$pre, version = v); break }
  }
  .python$info <- info
  info
}

python_banner <- function() {
  info <- python_info()
  if (info$ok) return(NULL)
  callout(paste0("<b>Python 3.8+ was not found</b>, so code cannot be run or judged. Install Python from <a href='https://www.python.org/downloads/' target='_blank'>python.org</a> ",
                 "(tick “Add python.exe to PATH” on Windows) and restart the app, or set the environment variable <code>DSA_PYTHON</code> to the full path of your interpreter ",
                 "before launching, e.g. <code>Sys.setenv(DSA_PYTHON = 'C:/Python312/python.exe')</code>."), "warn")
}

# ── Run a solution ───────────────────────────────────────────────────────────
# mode: "run" (examples + custom input) or "submit" (all tests incl. hidden and generated)
run_solution <- function(pid, code, mode = c("run", "submit"), custom = "") {
  mode <- match.arg(mode)
  info <- python_info()
  if (!info$ok) return(list(status = "setup_error", verdict = "Python not found",
                            error = list(msg = "Python 3.8 or newer is required to run code. See the banner at the top of the page.")))
  job <- tempfile(fileext = ".json")
  on.exit(unlink(job), add = TRUE)
  writeLines(jsonlite::toJSON(list(mode = mode, problem_id = pid, code = code, custom = custom,
                                   bank = file.path(PRACTICE_DIR, "problems.json")), auto_unbox = TRUE),
             job, useBytes = TRUE)
  limit <- if (mode == "submit") 30 else 15
  t0 <- Sys.time()
  out <- tryCatch(suppressWarnings(system2(info$cmd, c(info$pre, shQuote(file.path(PRACTICE_DIR, "runner.py")), shQuote(job)),
                                           stdout = TRUE, stderr = TRUE, timeout = limit)),
                  error = function(e) structure(conditionMessage(e), status = 1))
  wall <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  done <- grep("^@@DONE ", out, value = TRUE)
  if (length(done)) {
    res <- jsonlite::fromJSON(sub("^@@DONE ", "", done[length(done)]), simplifyVector = FALSE)
    res$wall <- wall
    return(res)
  }
  starts <- suppressWarnings(as.integer(sub("^@@START ", "", grep("^@@START ", out, value = TRUE))))
  status <- attr(out, "status") %||% 0
  if (length(starts) || identical(as.integer(status), 124L) || wall >= limit - 0.5) {
    idx <- if (length(starts)) max(starts) else 0
    return(list(status = "ok", verdict = "Time Limit Exceeded", passed = idx, total = NA, wall = wall, killed = TRUE,
                cases = list(list(name = sprintf("Test %d", idx + 1), verdict = "TLE", input = list(),
                                  error = sprintf("The run was stopped after %.0f seconds. Look for an infinite loop or an algorithm that is too slow for the largest inputs.", wall)))))
  }
  list(status = "setup_error", verdict = "Internal Error", wall = wall,
       error = list(msg = paste(tail(out, 15), collapse = "\n")))
}

# ── Display helpers ──────────────────────────────────────────────────────────
VERDICT_COL <- c("Accepted" = "#059669", "Wrong Answer" = "#dc2626", "Time Limit Exceeded" = "#d97706",
                 "Runtime Error" = "#dc2626", "Compile Error" = "#dc2626", "Memory Limit Exceeded" = "#d97706",
                 "Invalid Input" = "#d97706", "Internal Error" = "#64748b", "Python not found" = "#64748b")

json_str <- function(x) as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", digits = NA))

# Example args -> one JSON value per line (the custom-input format)
example_lines <- function(p, ex) {
  if (p$kind == "design") return(paste(json_str(ex$args$ops), json_str(ex$args$args), sep = "\n"))
  paste(vapply(ex$args, json_str, ""), collapse = "\n")
}

format_example <- function(p, ex, i) {
  inp <- if (p$kind == "design") {
    tagList(tags$div(class = "ex-line", tags$b("Operations: "), json_str(ex$args$ops)),
            tags$div(class = "ex-line", tags$b("Arguments: "), json_str(ex$args$args)))
  } else {
    tags$div(class = "ex-line", tags$b("Input: "),
             paste(mapply(function(pr, a) paste0(pr$name, " = ", json_str(a)), p$params, ex$args), collapse = ", "))
  }
  tags$div(class = "ex-box",
    tags$div(class = "ex-title", sprintf("Example %d", i)),
    inp,
    tags$div(class = "ex-line", tags$b("Output: "), json_str(ex$expected)),
    if (!is.null(ex$explanation)) tags$div(class = "ex-line ex-expl", tags$b("Explanation: "), ex$explanation))
}

company_badges <- function(p) {
  lapply(unlist(p$companies), function(c) tags$span(class = paste("co-badge", tolower(c)), c))
}

problem_statement <- function(p, show_meta = TRUE) {
  tagList(
    tags$div(class = "ps-head",
      tags$h4(class = "ps-title", sprintf("%d. %s", p$num, p$title)),
      if (show_meta) tags$div(class = "ps-badges", lc_badge(p$difficulty), company_badges(p),
                              tags$span(class = "prob-pattern", TOPICS[[p$topic]] %||% p$topic),
                              tags$a(class = "ps-link", href = paste0("https://leetcode.com/problems/", p$slug, "/"), target = "_blank", "LeetCode ↗"))),
    tags$div(class = "ps-body", HTML(as.character(shiny::markdown(p$statement)))),
    lapply(seq_along(p$examples), function(i) format_example(p, p$examples[[i]], i)),
    tags$div(class = "ps-constraints", tags$b("Constraints"),
             tags$ul(lapply(unlist(p$constraints), function(x) tags$li(tags$code(x)))))
  )
}

# Verdict panel for a runner result
result_panel <- function(res, mode = "run") {
  if (is.null(res)) return(tags$div(class = "res-empty", "Run your code to see results here.  Ctrl/Cmd + Enter runs, Ctrl/Cmd + Shift + Enter submits."))
  v <- res$verdict %||% "Internal Error"
  col <- VERDICT_COL[[v]] %||% "#64748b"
  head <- tags$div(class = "res-head",
    tags$span(class = "res-verdict", style = paste0("color:", col, ";"), v),
    if (!is.null(res$total) && !is.na(res$total) && res$status == "ok")
      tags$span(class = "res-sub", sprintf("%s / %s test cases passed", res$passed %||% 0, res$total)),
    if (!is.null(res$wall)) tags$span(class = "res-sub", sprintf("· judged in %.1fs", res$wall)))
  if (res$status %in% c("compile_error", "setup_error", "input_error")) {
    e <- res$error %||% list()
    return(tagList(head,
      tags$div(class = "res-error",
        if (!is.null(e$line)) tags$div(class = "res-err-line", sprintf("Line %s", e$line)),
        tags$pre(paste0(if (!is.null(e$type)) paste0(e$type, ": ") else "", e$msg %||% "",
                        if (!is.null(e$text) && nzchar(e$text)) paste0("\n\n  ", e$text, "\n  ", strrep(" ", max(0, (e$offset %||% 1) - 1)), "^") else ""))),
      if (!is.null(e$hint) && nzchar(e$hint)) callout(paste0("<b>Tip.</b> ", e$hint), "tip")))
  }
  cases <- res$cases %||% list()
  perf <- NULL
  if (identical(v, "Accepted") && mode == "submit" && isTRUE((res$ref_ms %||% 0) > 0)) {
    ratio <- (res$user_ms %||% 0) / max(res$ref_ms, 0.01)
    perf <- kpi_row(kpi(sprintf("%.0f ms", res$user_ms), "your time on large tests", COL$pri),
                    kpi(sprintf("%.0f ms", res$ref_ms), "reference solution", COL$ok),
                    kpi(sprintf("%.1f×", ratio), "relative speed", if (ratio <= 2) COL$ok else if (ratio <= 5) COL$warn else COL$err))
  }
  show <- if (mode == "submit") Filter(function(c) !(c$verdict %in% c("AC", "NA")), cases) else cases
  tagList(head, perf,
    if (mode == "submit" && identical(v, "Accepted"))
      callout("All tests passed, including the hidden edge cases and the large inputs that catch slow solutions.", "success"),
    if (mode == "submit" && !identical(v, "Accepted") && length(show)) tags$div(class = "res-note", "First failing test:"),
    lapply(show, case_card))
}

case_card <- function(cs) {
  ok <- cs$verdict %in% c("AC", "NA")
  lab <- switch(cs$verdict %||% "NA", AC = "✓ Passed", "NA" = "Ran (no expected value)", WA = "✗ Wrong answer", RE = "✗ Runtime error",
                TLE = "✗ Time limit exceeded", MLE = "✗ Memory limit exceeded", cs$verdict)
  field <- function(name, val, cls = "") if (!is.null(val) && length(val) && nzchar(paste(val, collapse = "")))
    tags$div(class = "case-field", tags$div(class = "case-lab", name), tags$pre(class = cls, paste(unlist(val), collapse = "\n")))
  tags$div(class = paste("case-card", if (ok) "ok" else "bad"),
    tags$div(class = "case-head", tags$span(class = "case-name", cs$name %||% ""), tags$span(class = "case-verdict", lab),
             if (!is.null(cs$ms)) tags$span(class = "case-ms", sprintf("%s ms", cs$ms)),
             if (!is.null(cs$limit_ms) && identical(cs$verdict, "TLE")) tags$span(class = "case-ms", sprintf("limit %s ms", cs$limit_ms))),
    field("Input", cs$input),
    field("Your output", cs$output, if (!ok && identical(cs$verdict, "WA")) "diff-bad"),
    field("Expected", cs$expected, if (!ok && identical(cs$verdict, "WA")) "diff-ok"),
    field("Stdout", cs$stdout),
    field("Error", cs$error, "diff-bad"),
    if (!is.null(cs$note)) tags$div(class = "hint", cs$note))
}

# First solution-file line number reported by a result (for editor annotations)
result_error_line <- function(res) {
  if (is.null(res)) return(NULL)
  if (!is.null(res$error$line)) return(list(line = res$error$line, text = paste(res$error$type %||% "Error", res$error$msg %||% "", sep = ": ")))
  for (cs in res$cases %||% list()) if (!is.null(cs$line)) return(list(line = cs$line, text = sub("(?s)^.*\\n", "", cs$error %||% "", perl = TRUE)))
  NULL
}

# Ace editor container (initialised by www/js/practice.js)
ace_editor <- function(id, value = "", height = "420px", action_input = NULL, group = NULL,
                       readonly = FALSE, plain = FALSE, autocomplete = TRUE) {
  tags$div(id = id, class = "dsa-ace", style = paste0("height:", height, ";"),
           `data-input` = id, `data-action` = action_input, `data-group` = group,
           `data-readonly` = if (readonly) "1" else "0", `data-plain` = if (plain) "1" else "0",
           `data-autocomplete` = if (autocomplete) "1" else "0", value)
}

# Add practice problems that are missing from the topic problem lists, so every in-app problem
# also appears (with a "Solve here" button) on its topic page and in the Pattern Finder bank.
local({
  miss <- PRACTICE_DF[!(PRACTICE_DF$num %in% PROBLEMS$num), ]
  if (nrow(miss)) {
    add <- data.frame(topic = miss$topic, num = miss$num, title = miss$title, level = miss$difficulty, pattern = miss$pattern,
                      slug = vapply(PRACTICE[miss$id], function(p) p$slug, ""), stringsAsFactors = FALSE)
    add$url <- paste0("https://leetcode.com/problems/", add$slug, "/")
    PROBLEMS <<- rbind(PROBLEMS, add[, names(PROBLEMS)])
  }
  # company tags: community-reported lists, plus the tags on in-app problems
  co <- problem_companies(PROBLEMS$num)
  inapp <- PRACTICE_DF$companies[match(PROBLEMS$num, PRACTICE_DF$num)]
  merge_co <- function(a, b) { x <- unique(c(strsplit(a %||% "", " · ")[[1]], if (!is.na(b)) strsplit(b, " · ")[[1]])); paste(x[nzchar(x)], collapse = " · ") }
  PROBLEMS$companies <<- mapply(merge_co, co, inapp, USE.NAMES = FALSE)
})

# ── AI-assisted round projects and code-reading exercises ───────────────────
PROJECTS <- local({
  f <- file.path(PRACTICE_DIR, "projects", "index.json")
  if (!file.exists(f)) list() else {
    raw <- jsonlite::fromJSON(f, simplifyVector = FALSE)
    setNames(raw, vapply(raw, function(p) p$id, ""))
  }
})
READING <- local({
  f <- file.path(PRACTICE_DIR, "reading", "reading.json")
  if (!file.exists(f)) list() else {
    raw <- jsonlite::fromJSON(f, simplifyVector = FALSE)
    setNames(raw, vapply(raw, function(p) p$id, ""))
  }
})

# Run practice/project_runner.py. mode: tests | hidden | audit | exec
run_project <- function(mode, project_id = NULL, files = NULL, tests = NULL, code = NULL, limit = 60) {
  info <- python_info()
  if (!info$ok) return(list(status = "setup_error", msg = "Python 3.8 or newer is required to run code."))
  job <- tempfile(fileext = ".json"); on.exit(unlink(job), add = TRUE)
  body <- list(mode = mode)
  if (!is.null(project_id)) body$project <- file.path(PRACTICE_DIR, "projects", project_id)
  if (!is.null(files)) body$files <- files
  if (!is.null(tests)) body$tests <- tests
  if (!is.null(code)) body$code <- code
  writeLines(jsonlite::toJSON(body, auto_unbox = TRUE), job, useBytes = TRUE)
  t0 <- Sys.time()
  out <- tryCatch(suppressWarnings(system2(info$cmd, c(info$pre, shQuote(file.path(PRACTICE_DIR, "project_runner.py")), shQuote(job)),
                                           stdout = TRUE, stderr = TRUE, timeout = limit)),
                  error = function(e) structure(conditionMessage(e), status = 1))
  done <- grep("^@@DONE ", out, value = TRUE)
  if (!length(done)) return(list(status = "setup_error", msg = paste(tail(out, 15), collapse = "\n")))
  res <- jsonlite::fromJSON(sub("^@@DONE ", "", done[length(done)]), simplifyVector = FALSE)
  res$wall <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  res
}

# Render a unified diff with coloured lines
diff_view <- function(txt) {
  lines <- strsplit(txt %||% "", "\n", fixed = TRUE)[[1]]
  cls <- ifelse(startsWith(lines, "+++") | startsWith(lines, "---"), "df-file",
         ifelse(startsWith(lines, "@@"), "df-hunk", ifelse(startsWith(lines, "+"), "df-add", ifelse(startsWith(lines, "-"), "df-del", ""))))
  tags$pre(class = "diff-view", lapply(seq_along(lines), function(i) tags$span(class = paste("df-line", cls[i]), lines[i])))
}

# One unittest suite result (from project_runner.py) as a compact card list
suite_view <- function(s, title = NULL, hide_msgs = FALSE) {
  if (is.null(s)) return(NULL)
  st <- s$status %||% "ok"
  head <- tags$div(class = "res-head",
    tags$span(class = "res-verdict", style = paste0("color:", if (isTRUE(s$all_pass)) "#059669" else "#dc2626", ";"),
              title %||% if (isTRUE(s$all_pass)) "All tests passed" else if (st == "ok") "Some tests failed" else switch(st,
                timeout = "Time limit exceeded", load_error = "Could not import / load the tests", no_tests = "No tests found", crash = "Crashed", st)),
    if (st == "ok") tags$span(class = "res-sub", sprintf("%s / %s passed", s$passed %||% 0, s$total %||% 0)))
  msg <- s$msg %||% ""
  tagList(head,
    if (nzchar(msg)) tags$pre(class = "res-error", msg),
    if (nzchar(s$stderr %||% "")) tags$details(tags$summary("stderr"), tags$pre(s$stderr)),
    tags$div(class = "suite-list", lapply(s$cases %||% list(), function(c) {
      ok <- identical(c$status, "pass")
      tags$div(class = paste("suite-case", if (ok) "ok" else "bad"),
        tags$span(class = "suite-mark", if (ok) "✓" else if (identical(c$status, "error")) "!" else "✗"),
        tags$span(class = "suite-name", c$name),
        if (!ok && !hide_msgs && nzchar(c$msg %||% "")) tags$details(tags$summary("details"), tags$pre(c$msg)),
        if (!ok && hide_msgs && nzchar(c$msg %||% "")) tags$span(class = "suite-msg", c$msg))
    })))
}
