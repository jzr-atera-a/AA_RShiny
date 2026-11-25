# =============================================================================
# R/utils_muscle.R - Muscle-building programme engine (male hypertrophy plan)
#
#   * muscle catalogue (26 trackable muscles) + weekly set targets (MEV..MRV)
#   * week-over-week progression: volume ramp, RIR ramp, deload, load progression
#   * three equipment options per day: gym / no equipment / home kit
#   * Claude prompt + strict JSON parsing -> rows that fit the BigQuery tables
#   * diagram SPEC (JSON) <-> SVG renderer (original artwork in utils_muscle_body.R)
#
# Claude never draws: it returns muscle IDs, sets, reps and short callouts; the
# app draws the body from the stored spec, so every diagram can be regenerated.
# Helper names must not end in _ui / _server (module loader rule).
# =============================================================================

# ---- catalogue ---------------------------------------------------------------
# mev / mrv = minimum effective / maximum recoverable weekly sets (hypertrophy
# evidence: roughly 10-20 hard sets per muscle per week for the big muscles).
MUSCLE_CAT <- data.frame(
  id = c("neck", "traps_upper", "traps_mid_lower", "upper_back", "lats", "erector_spinae",
         "chest_upper", "chest_lower", "serratus",
         "deltoid_front", "deltoid_side", "deltoid_rear",
         "biceps", "triceps", "forearms",
         "abs", "obliques", "hip_flexors",
         "glutes", "glutes_med", "quads", "hamstrings", "adductors", "calves", "soleus", "tibialis"),
  name = c("Neck", "Upper trapezius", "Mid / lower trapezius", "Rhomboids & rotator cuff", "Latissimus dorsi", "Erector spinae (lower back)",
           "Upper chest", "Lower / mid chest", "Serratus anterior",
           "Front deltoid", "Side deltoid", "Rear deltoid",
           "Biceps & brachialis", "Triceps", "Forearms",
           "Abdominals", "Obliques", "Hip flexors",
           "Glutes (max)", "Glutes (medius)", "Quadriceps", "Hamstrings", "Adductors", "Calves (gastrocnemius)", "Soleus", "Tibialis anterior"),
  group = c("Neck", "Back", "Back", "Back", "Back", "Back",
            "Chest", "Chest", "Chest",
            "Shoulders", "Shoulders", "Shoulders",
            "Arms", "Arms", "Arms",
            "Core", "Core", "Core",
            "Legs", "Legs", "Legs", "Legs", "Legs", "Legs", "Legs", "Legs"),
  mev = c(2, 6, 6, 8, 10, 4,   10, 10, 2,   4, 8, 8,   8, 8, 4,   6, 4, 2,   8, 4, 10, 8, 4, 8, 4, 2),
  mrv = c(6, 14, 14, 16, 18, 10,   18, 18, 8,   10, 18, 16,   16, 16, 10,   14, 10, 6,   16, 10, 18, 16, 10, 16, 10, 6),
  color = c("#d9a066", "#e8944a", "#c9822f", "#a78bd0", "#8a63c7", "#6f4fb0",
            "#d9507a", "#c23b6a", "#e7a0b8",
            "#f0a050", "#e58a3a", "#d9762c",
            "#e86f8f", "#cf5a7a", "#e3a089",
            "#e0607f", "#c8a2e0", "#d98aa8",
            "#d04a6b", "#b985d6", "#9a74d6", "#8f62cc", "#c9a0e6", "#c46a8f", "#e08aa6", "#e29a7c"),
  stringsAsFactors = FALSE)
MUSCLE_IDS <- MUSCLE_CAT$id

muscle_name <- function(id) { i <- match(id, MUSCLE_CAT$id); ifelse(is.na(i), id, MUSCLE_CAT$name[i]) }
muscle_catalogue_text <- function() paste0("  ", MUSCLE_CAT$id, " = ", MUSCLE_CAT$name, " (", MUSCLE_CAT$group, ")", collapse = "\n")

MUSCLE_OPTIONS <- c(gym = "Gym (machines & free weights)", bodyweight = "No equipment (home / travelling)", home = "Home kit (bands, light dumbbells, bench)")
MUSCLE_OPTION_SHORT <- c(gym = "Gym", bodyweight = "No equipment", home = "Home kit")

# status colours for the gap view
MUSCLE_STATUS <- c(none = "#c4c9cf", low = "#ffc233", on = "#4caf50", high = "#1fa6a0")
MUSCLE_STATUS_LABEL <- c(none = "Not trained", low = "Under target", on = "On target", high = "At / above target")
MUSCLE_ROLE_COLOR <- c(primary = "#d81b60", secondary = "#ffb300")

# ---- small utilities ---------------------------------------------------------
muscle_split_ids <- function(x) {
  x <- unlist(strsplit(as.character(x %||% ""), "[,;|[:space:]]+"))
  x <- tolower(trimws(x)); x[nzchar(x)]
}
muscle_num <- function(x, default = NA_real_) {
  v <- suppressWarnings(as.numeric(gsub("[^0-9.\\-]", "", as.character(x %||% ""))))
  if (length(v) == 0 || is.na(v[1])) default else v[1]
}
muscle_monday <- function(d = Sys.Date()) { d <- as.Date(d); d - ((as.integer(format(d, "%u")) - 1L) %% 7L) }

# ---- week-over-week structure ------------------------------------------------
# A block is 5 weeks: 4 build weeks (volume up, RIR down) then a deload. The
# programme start date is stored with every saved row, week_no counts on.
muscle_week_no <- function(date, start) max(1L, as.integer(floor(as.numeric(as.Date(date) - as.Date(start)) / 7)) + 1L)
muscle_block_week <- function(week_no) ((as.integer(week_no) - 1L) %% 5L) + 1L
muscle_phase <- function(week_no) { bw <- muscle_block_week(week_no); if (bw == 5L) "Deload" else paste0("Build ", bw) }
muscle_rir_for <- function(week_no) c(4L, 3L, 2L, 1L, 4L)[muscle_block_week(week_no)]
muscle_block_no <- function(week_no) (as.integer(week_no) - 1L) %/% 5L + 1L

muscle_week_targets <- function(week_no, cat = MUSCLE_CAT) {
  bw <- muscle_block_week(week_no)
  t <- if (bw == 5L) round(cat$mev * 0.5) else round(cat$mev + (cat$mrv - cat$mev) * (bw - 1L) / 3)
  # each new 5-week block starts about one set above the previous one (capped by MRV)
  if (bw < 5L) t <- pmin(cat$mrv, t + pmin(1L, muscle_block_no(week_no) - 1L))
  stats::setNames(as.integer(t), cat$id)
}

# user-edited targets (muscle_targets table) override the catalogue defaults
muscle_apply_targets <- function(overrides) {
  cat <- MUSCLE_CAT
  if (is.data.frame(overrides) && nrow(overrides)) {
    ov <- overrides[order(overrides$id), ]
    ov <- ov[!duplicated(ov$muscle_id, fromLast = TRUE), ]
    i <- match(ov$muscle_id, cat$id)
    k <- !is.na(i)
    cat$mev[i[k]] <- as.numeric(ov$mev[k]); cat$mrv[i[k]] <- as.numeric(ov$mrv[k])
  }
  cat
}

# ---- weekly splits -----------------------------------------------------------
.MP <- c("chest_upper", "chest_lower", "deltoid_front", "deltoid_side", "triceps", "serratus")
.MB <- c("lats", "upper_back", "traps_mid_lower", "traps_upper", "deltoid_rear", "biceps", "forearms", "neck")
.ML <- c("quads", "hamstrings", "glutes", "glutes_med", "adductors", "calves", "soleus", "tibialis", "hip_flexors")
.MC <- c("abs", "obliques", "erector_spinae")

MUSCLE_SPLITS <- list(
  `3` = list(
    list(label = "Full body A", muscles = c("chest_upper", "chest_lower", "deltoid_side", "triceps", "lats", "upper_back", "biceps", "quads", "hamstrings", "abs", "calves", "serratus")),
    list(label = "Full body B", muscles = c("chest_lower", "chest_upper", "deltoid_rear", "deltoid_side", "traps_mid_lower", "lats", "triceps", "biceps", "glutes", "hamstrings", "quads", "obliques", "soleus", "forearms", "hip_flexors")),
    list(label = "Full body C", muscles = c("chest_upper", "deltoid_side", "deltoid_front", "deltoid_rear", "upper_back", "lats", "traps_upper", "biceps", "triceps", "quads", "glutes", "glutes_med", "adductors", "calves", "abs", "erector_spinae", "neck", "tibialis"))),
  `4` = list(
    list(label = "Upper A (push focus)", muscles = c(.MP, .MB)),
    list(label = "Lower A (quads focus)", muscles = c(.ML, .MC)),
    list(label = "Upper B (pull focus)", muscles = c(.MB, .MP)),
    list(label = "Lower B (hamstrings & glutes focus)", muscles = c(.ML, .MC))),
  `5` = list(
    list(label = "Push", muscles = .MP), list(label = "Pull", muscles = .MB),
    list(label = "Legs", muscles = c(.ML, "abs")),
    list(label = "Upper", muscles = c(.MP, .MB)), list(label = "Lower & core", muscles = c(.ML, .MC))),
  `6` = list(
    list(label = "Push A", muscles = .MP), list(label = "Pull A", muscles = .MB), list(label = "Legs A", muscles = c(.ML, "abs")),
    list(label = "Push B", muscles = .MP), list(label = "Pull B", muscles = .MB), list(label = "Legs B", muscles = c(.ML, .MC))))

muscle_split <- function(days) MUSCLE_SPLITS[[as.character(min(6L, max(3L, as.integer(days))))]]

# Sets needed on day `day_idx`: remaining weekly deficit shared over the remaining
# days of the week that train the muscle (so a missed day is made up automatically).
muscle_day_targets <- function(split, day_idx, week_targets, done = NULL, days_done = integer(0)) {
  today <- split[[day_idx]]$muscles
  done <- done %||% stats::setNames(numeric(0), character(0))
  out <- integer(0)
  for (m in today) {
    remaining_days <- Filter(function(i) !(i %in% days_done) && i >= day_idx && m %in% split[[i]]$muscles, seq_along(split))
    n_rem <- max(1L, length(remaining_days))
    need <- max(0, week_targets[[m]] - (done[m] %||% 0)); if (is.na(need)) need <- week_targets[[m]]
    out[m] <- as.integer(max(if (week_targets[[m]] > 0) 1L else 0L, min(10L, ceiling(need / n_rem))))
  }
  out
}

# ---- Claude prompt -----------------------------------------------------------
muscle_equipment_text <- function(option, home_db_kg = 20, gym_notes = "", home_notes = "") {
  switch(option,
    gym = paste0("A properly equipped commercial gym: barbells, dumbbells to 50 kg+, cable stations, plate-loaded and selectorised machines, smith machine, pull-up bars. ",
                 "NAME the specific machine or implement for every exercise (e.g. 'Seated chest-press machine', 'Lat pulldown with wide neutral grip', 'Hack squat machine', 'Cable rope pushdown'). ",
                 "Give a starting target_load_kg (a realistic working load for an intermediate lifter) for every weighted exercise.",
                 if (nzchar(trimws(gym_notes))) paste0(" Notes about this gym: ", gym_notes) else ""),
    bodyweight = paste0("NO equipment at all (hotel room, park or travelling). Only bodyweight plus everyday objects (chair, table, towel, backpack with books, door frame, stairs, wall). ",
                        "target_load_kg must be null for bodyweight moves (use tempo, pauses, single-limb and elevated variations for progression; say it in 'cues'). ",
                        "Put the progression idea (slower tempo, extra pause, harder variation) in 'cues'."),
    home = paste0("Simple home kit: a flat/adjustable bench, light dumbbells up to ", home_db_kg, " kg each, and resistance bands (light, medium, heavy; loops and tube with handles). ",
                  "Never prescribe a load above ", home_db_kg, " kg per dumbbell; for harder moves use tempo, pauses, single-limb versions, higher reps or heavier bands. ",
                  "State the band strength when a band is used. target_load_kg = dumbbell kg per hand (null for bands/bodyweight).",
                  if (nzchar(trimws(home_notes))) paste0(" Notes about this kit: ", home_notes) else ""))
}

muscle_day_prompt <- function(day_label, day_no, week_no, targets_today, rir, phase, injuries = "", level = "Intermediate",
                              prev_plan = NULL, perf = NULL, home_db_kg = 20, gym_notes = "", home_notes = "", date = Sys.Date()) {
  tt <- paste0("  ", names(targets_today), " (", muscle_name(names(targets_today)), "): ", targets_today, " sets", collapse = "\n")
  prev <- if (is.data.frame(prev_plan) && nrow(prev_plan)) paste0(
    "LAST WEEK'S PLAN FOR THIS SAME DAY (keep the same exercises unless one is unsuitable - progress through load, reps and sets, not by swapping):\n",
    paste(vapply(split(prev_plan, prev_plan$option_key), function(p) paste0("  [", p$option_key[1], "] ",
          paste(sprintf("%s %dx%d-%d%s", p$exercise_name, as.integer(p$sets), as.integer(p$rep_min), as.integer(p$rep_max),
                        ifelse(is.na(p$target_load_kg), "", paste0(" @", p$target_load_kg, "kg"))), collapse = "; ")), ""), collapse = "\n"), "\n\n") else ""
  pf <- if (is.data.frame(perf) && nrow(perf)) paste0(
    "RECENT PERFORMANCE (best recent working set per exercise - use it so the loads you suggest progress):\n",
    paste(sprintf("  %s: %s kg x %s reps", perf$exercise_name, perf$load_kg, perf$reps), collapse = "\n"), "\n\n") else ""
  paste0(
    "You are an expert strength and hypertrophy coach (evidence-based, in the spirit of the DK 'Science of Strength Training' and 'Science of HIIT' anatomy books and ",
    "current volume research). Plan ONE training day of a MALE MUSCLE-BUILDING programme (", level, " lifter).\n\n",
    "Date: ", format(as.Date(date), "%A %Y-%m-%d"), ". Programme week ", week_no, " (", phase, "). Day ", day_no, ": ", day_label, ".\n",
    "Target proximity to failure this week: ", rir, " reps in reserve (RIR) on working sets", if (phase == "Deload") " (DELOAD week: easy, reduced volume)" else "", ".\n\n",
    "WEEKLY-SET TARGETS TO COVER TODAY (a set counts 1 for each PRIMARY muscle and 0.5 for each SECONDARY muscle; hit these within +/-1 set):\n", tt, "\n\n",
    if (nzchar(trimws(injuries))) paste0("RECENT INJURY / ISSUE (must be respected in all three options - avoid or modify aggravating movements and say so in 'cues'): ", injuries, "\n\n") else "",
    prev, pf,
    "Return THREE complete options for the SAME day and the SAME muscle targets:\n",
    "  gym        - ", muscle_equipment_text("gym", gym_notes = gym_notes), "\n",
    "  bodyweight - ", muscle_equipment_text("bodyweight"), "\n",
    "  home       - ", muscle_equipment_text("home", home_db_kg, home_notes = home_notes), "\n\n",
    "RULES: 5 to 9 exercises per option; compounds first (6-10 reps), isolation later (10-15 reps; calves/abs 12-20). 2 to 5 sets per exercise. ",
    "Order for fatigue management. rir = ", rir, " for every exercise (1 higher for the first heavy compound is fine). rest_sec 60-180. ",
    "Use ONLY these muscle ids in primary / secondary:\n", muscle_catalogue_text(), "\n\n",
    "Return ONLY one JSON object (no markdown fences, no commentary) with exactly this shape:\n",
    '{"day_label":"...","options":[{"key":"gym","title":"short title","summary":"one sentence","exercises":[{"order":1,"name":"exercise name","equipment":"e.g. barbell / Hammer Strength incline press / light band","machine_or_load":"machine name or implement detail","primary":["chest_upper"],"secondary":["triceps"],"sets":4,"rep_min":6,"rep_max":10,"rir":2,"target_load_kg":60,"rest_sec":120,"cues":"1-2 short coaching cues"}],"diagram":{"view":"front|back|both","callouts":[{"muscle":"chest_upper","text":"max 24 characters"}]},"notes":"optional"},{"key":"bodyweight",...},{"key":"home",...}]}\n',
    "Callouts: 3 to 6 per option, only for the main working muscles. Weights are in kg.")
}

# ---- parsing Claude's answer -------------------------------------------------
muscle_extract_json <- function(text) {
  text <- gsub("^\\s*```[A-Za-z]*\\s*|\\s*```\\s*$", "", as.character(text %||% ""))
  s <- regexpr("\\{", text); if (s < 0) return(NULL)
  chars <- strsplit(substring(text, s), "")[[1]]
  depth <- 0L; in_str <- FALSE; esc <- FALSE; end <- NA_integer_
  for (i in seq_along(chars)) {
    ch <- chars[i]
    if (in_str) { if (esc) esc <- FALSE else if (ch == "\\") esc <- TRUE else if (ch == '"') in_str <- FALSE }
    else if (ch == '"') in_str <- TRUE
    else if (ch == "{") depth <- depth + 1L
    else if (ch == "}") { depth <- depth - 1L; if (depth == 0L) { end <- i; break } }
  }
  if (is.na(end)) return(NULL)
  tryCatch(jsonlite::fromJSON(paste(chars[seq_len(end)], collapse = ""), simplifyVector = FALSE), error = function(e) NULL)
}

muscle_clean_ids <- function(x, warn_env = NULL) {
  ids <- tolower(trimws(unlist(x))); ids <- ids[nzchar(ids)]
  bad <- setdiff(ids, MUSCLE_IDS)
  if (length(bad) && !is.null(warn_env)) warn_env$w <- c(warn_env$w, paste("Unknown muscle id(s) ignored:", paste(unique(bad), collapse = ", ")))
  unique(intersect(ids, MUSCLE_IDS))
}

# -> list(ok, error, options = list(gym=list(title, summary, exercises=df, diagram=list, notes), ...), warnings)
muscle_parse_plan <- function(text, home_db_kg = 20) {
  j <- muscle_extract_json(text)
  if (is.null(j) || is.null(j$options)) return(list(ok = FALSE, error = "Claude's answer was not the JSON plan the app expects. Try again (or raise Max Tokens in Claude API Config).", warnings = character(0)))
  we <- new.env(); we$w <- character(0)
  opts <- list()
  for (o in j$options) {
    key <- tolower(trimws(as.character(o$key %||% "")))
    if (!key %in% names(MUSCLE_OPTIONS)) { we$w <- c(we$w, paste("Option with unknown key ignored:", key)); next }
    ex <- list()
    for (e in o$exercises %||% list()) {
      nm <- trimws(as.character(e$name %||% "")); if (!nzchar(nm)) next
      prim <- muscle_clean_ids(e$primary, we); sec <- setdiff(muscle_clean_ids(e$secondary, we), prim)
      if (!length(prim)) { we$w <- c(we$w, paste0("'", nm, "' has no valid primary muscle and was skipped.")); next }
      rmin <- as.integer(max(1, min(60, muscle_num(e$rep_min, 8)))); rmax <- as.integer(max(rmin, min(60, muscle_num(e$rep_max, rmin + 4))))
      ld <- muscle_num(e$target_load_kg, NA_real_)
      if (key == "bodyweight") ld <- NA_real_
      if (key == "home" && !is.na(ld) && ld > home_db_kg) { we$w <- c(we$w, sprintf("'%s': load %s kg is above your %s kg dumbbells - capped.", nm, ld, home_db_kg)); ld <- home_db_kg }
      ex[[length(ex) + 1L]] <- data.frame(
        exercise_order = length(ex) + 1L, exercise_name = nm,
        equipment = as.character(e$equipment %||% ""), machine_or_load = as.character(e$machine_or_load %||% ""),
        primary_muscles = paste(prim, collapse = ","), secondary_muscles = paste(sec, collapse = ","),
        sets = as.integer(max(1, min(8, muscle_num(e$sets, 3)))), rep_min = rmin, rep_max = rmax,
        target_rir = as.integer(max(0, min(6, muscle_num(e$rir, 2)))), target_load_kg = ld,
        load_source = if (is.na(ld)) "none" else "claude",
        rest_sec = as.integer(max(0, min(600, muscle_num(e$rest_sec, 90)))), cues = as.character(e$cues %||% ""), stringsAsFactors = FALSE)
    }
    if (!length(ex)) { we$w <- c(we$w, paste("Option", key, "had no usable exercises.")); next }
    df <- do.call(rbind, ex)
    co <- list()
    for (cc in o$diagram$callouts %||% list()) {
      m <- tolower(trimws(as.character(cc$muscle %||% ""))); if (m %in% MUSCLE_IDS) co[[length(co) + 1L]] <- list(m = m, t = substr(as.character(cc$text %||% ""), 1, 40))
    }
    opts[[key]] <- list(key = key, title = as.character(o$title %||% MUSCLE_OPTION_SHORT[[key]]), summary = as.character(o$summary %||% ""),
                        exercises = df, callouts = co, view = as.character(o$diagram$view %||% "both"), notes = as.character(o$notes %||% ""))
  }
  if (!length(opts)) return(list(ok = FALSE, error = "The plan contained no usable options.", warnings = we$w))
  missing <- setdiff(names(MUSCLE_OPTIONS), names(opts))
  if (length(missing)) we$w <- c(we$w, paste("Claude did not return option(s):", paste(missing, collapse = ", ")))
  list(ok = TRUE, options = opts, day_label = as.character(j$day_label %||% ""), warnings = unique(we$w))
}

# ---- credited sets -----------------------------------------------------------
# sets: data.frame(primary_muscles, secondary_muscles, n) -> named numeric by muscle
muscle_credit_sets <- function(primary, secondary, n) {
  out <- stats::setNames(numeric(length(MUSCLE_IDS)), MUSCLE_IDS)
  for (i in seq_along(n)) {
    p <- muscle_split_ids(primary[i]); s <- setdiff(muscle_split_ids(secondary[i]), p)
    p <- intersect(p, MUSCLE_IDS); s <- intersect(s, MUSCLE_IDS)
    out[p] <- out[p] + n[i]; out[s] <- out[s] + 0.5 * n[i]
  }
  out
}
muscle_plan_sets <- function(df) muscle_credit_sets(df$primary_muscles, df$secondary_muscles, df$sets)

muscle_status <- function(done, target) {
  r <- ifelse(target <= 0, 1, done / target)
  ifelse(done <= 0, "none", ifelse(r < 0.7, "low", ifelse(r < 1.2, "on", "high")))
}

# ---- load progression (double progression) -----------------------------------
# hist: set-log rows of ONE exercise (workout_date, load_kg, reps, rir). Returns the
# load/reps goal for the next session. lower = TRUE -> bigger jumps for leg work.
muscle_next_load <- function(hist, rep_min, rep_max, target_rir = 2L, lower = FALSE, deload = FALSE) {
  hist <- hist[!is.na(hist$load_kg) & !is.na(hist$reps) & hist$reps > 0, , drop = FALSE]
  if (!nrow(hist)) return(NULL)
  last_day <- max(as.character(hist$workout_date)); h <- hist[as.character(hist$workout_date) == last_day, , drop = FALSE]
  load <- max(h$load_kg); top <- h[h$load_kg >= load - 1e-9, , drop = FALSE]
  inc <- if (load >= 40) (if (lower) 5 else 2.5) else if (load >= 15) 2.5 else 1.25
  if (deload) return(list(load = round(load * 0.9 / 1.25) * 1.25, reps = rep_max, reason = "deload: about 90% of last load"))
  if (all(top$reps >= rep_max)) list(load = load + inc, reps = rep_min, reason = sprintf("all sets hit %d reps: +%s kg", rep_max, inc))
  else if (all(top$reps >= rep_min)) list(load = load, reps = min(rep_max, min(top$reps) + 1L), reason = sprintf("same load, aim for %d reps", min(rep_max, min(top$reps) + 1L)))
  else list(load = load, reps = rep_min, reason = sprintf("below %d reps: repeat the load", rep_min))
}
muscle_e1rm <- function(load, reps) ifelse(is.na(load) | is.na(reps) | reps <= 0, NA_real_, load * (1 + pmin(reps, 30) / 30))

# applies history-driven load suggestions to a parsed option's exercises
muscle_apply_progression <- function(ex, log, deload = FALSE) {
  if (!is.data.frame(log) || !nrow(log)) return(ex)
  for (i in seq_len(nrow(ex))) {
    h <- log[tolower(log$exercise_name) == tolower(ex$exercise_name[i]), , drop = FALSE]
    if (!nrow(h)) next
    lower <- any(muscle_split_ids(ex$primary_muscles[i]) %in% c("quads", "hamstrings", "glutes", "calves", "soleus", "adductors"))
    nl <- muscle_next_load(h, ex$rep_min[i], ex$rep_max[i], ex$target_rir[i], lower, deload)
    if (is.null(nl)) next
    ex$target_load_kg[i] <- nl$load; ex$load_source[i] <- "progression"
    ex$cues[i] <- trimws(paste0(ex$cues[i], " [", nl$reason, "]"))
  }
  ex
}

# ---- diagram spec (what is stored in BigQuery) -------------------------------
muscle_make_spec <- function(ex, title = "", view = "both", callouts = list(), note = "") {
  sets <- muscle_plan_sets(ex); sets <- sets[sets > 0]
  # a single-view diagram must show every worked muscle; otherwise show both sides
  if (view %in% c("front", "back")) {
    shown <- MUSCLE_BODY_PARTS$muscle[MUSCLE_BODY_PARTS$view == view]
    if (!all(names(sets) %in% shown)) view <- "both"
  } else view <- "both"
  prim <- unique(unlist(lapply(ex$primary_muscles, muscle_split_ids)))
  hl <- lapply(names(sets), function(m) list(m = m, role = if (m %in% prim) "primary" else "secondary", sets = unname(sets[[m]])))
  list(v = 1L, title = title, view = view, highlights = hl, callouts = callouts, note = note)
}
muscle_spec_json <- function(spec) as.character(jsonlite::toJSON(spec, auto_unbox = TRUE, null = "null", digits = 4))
muscle_spec_read <- function(json) tryCatch(jsonlite::fromJSON(json, simplifyVector = FALSE), error = function(e) NULL)
muscle_spec_fills <- function(spec) {
  f <- list(); for (h in spec$highlights %||% list()) f[[h$m]] <- MUSCLE_ROLE_COLOR[[h$role %||% "primary"]]
  f
}
muscle_spec_svg <- function(spec, ...) muscle_svg(fills = muscle_spec_fills(spec), view = spec$view %||% "both", callouts = spec$callouts, title = spec$title, dim_others = TRUE, ...)

# ---- SVG renderer ------------------------------------------------------------
muscle_hex_shift <- function(hex, amt) {
  v <- grDevices::col2rgb(hex)[, 1] / 255
  v <- if (amt >= 0) v + (1 - v) * amt else v * (1 + amt)
  grDevices::rgb(v[1], v[2], v[3])
}
muscle_esc <- function(x) htmltools::htmlEscape(as.character(x %||% ""))

# fills: named list id -> colour. dim_others: draw unlisted muscles pale.
# click_input: full Shiny input id to receive the clicked muscle id.
muscle_svg <- function(fills = list(), view = "both", selected = NULL, click_input = NULL, callouts = NULL,
                       title = NULL, dim_others = FALSE, show_names = FALSE, uid = NULL) {
  uid <- uid %||% sprintf("%05d", sample.int(99999L, 1))
  views <- if (view %in% c("front", "back")) view else c("front", "back")
  has_co <- length(callouts) > 0
  fig_w <- 220; pad <- if (has_co) 100 else 10
  step <- fig_w + pad
  total_w <- step * length(views); top <- if (nzchar(title %||% "")) 18 else 0
  base_col <- function(id) { c <- MUSCLE_CAT$color[match(id, MUSCLE_CAT$id)]; if (is.na(c)) "#cccccc" else c }
  col_of <- function(id) { c <- fills[[id]]; if (!is.null(c)) c else if (dim_others) "#eadfd6" else base_col(id) }
  cols <- unique(unlist(lapply(MUSCLE_IDS, col_of)))
  grad_id <- function(c) paste0("mg", uid, gsub("[^0-9A-Za-z]", "", c))
  defs <- paste(vapply(cols, function(c) sprintf(
    '<linearGradient id="%s" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="%s"/><stop offset=".55" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>',
    grad_id(c), muscle_hex_shift(c, .25), c, muscle_hex_shift(c, -.2)), ""), collapse = "")
  css <- sprintf('<style>.mm%1$s .mp path{stroke:#fff;stroke-opacity:.75;stroke-width:.8;transition:filter .12s}.mm%1$s .mp:hover path{filter:brightness(1.12) drop-shadow(0 0 2px rgba(0,0,0,.55));stroke:#222;stroke-width:1.1}.mm%1$s .mp.sel path{stroke:#111;stroke-width:1.6;stroke-dasharray:3 1.5}.mm%1$s text{font-family:Segoe UI,Helvetica,Arial,sans-serif}%2$s</style>',
                 uid, if (!is.null(click_input)) sprintf('.mm%s .mp{cursor:pointer}', uid) else "")
  body <- character(0)
  for (vi in seq_along(views)) {
    v <- views[vi]; ox <- (vi - 1) * step + (pad / 2) * (if (has_co) 0 else 1)
    parts <- MUSCLE_BODY_PARTS[MUSCLE_BODY_PARTS$view == v, , drop = FALSE]
    g <- sprintf('<g transform="translate(%s,%s)">', ox, top)
    g <- paste0(g, sprintf('<g fill="#fbe7d8" stroke="#e8c9b4" stroke-width="1"><path d="%s"/><g transform="translate(220,0) scale(-1,1)"><path d="%s"/></g>%s</g>',
                           MUSCLE_BODY_SILHOUETTE, MUSCLE_BODY_SILHOUETTE, MUSCLE_BODY_HEAD))
    for (id in MUSCLE_IDS) {
      p <- parts[parts$muscle == id, , drop = FALSE]; if (!nrow(p)) next
      c <- col_of(id)
      attrs <- sprintf('class="mp%s" data-muscle="%s"%s', if (id %in% selected) " sel" else "", id,
                       if (!is.null(click_input)) sprintf(' onclick="Shiny.setInputValue(\'%s\',\'%s\',{priority:\'event\'})"', click_input, id) else "")
      inner <- vapply(seq_len(nrow(p)), function(i) {
        el <- sprintf('<path d="%s" fill="url(#%s)" fill-opacity="%s"><title>%s</title></path>', p$d[i], grad_id(c),
                      if (p$shade[i] == 1) ".82" else ".95", muscle_esc(paste0(p$part[i], " - ", muscle_name(id))))
        if (isTRUE(p$mirror[i])) paste0(el, sprintf('<g transform="translate(220,0) scale(-1,1)">%s</g>', el)) else el
      }, "")
      g <- paste0(g, sprintf('<g %s>%s</g>', attrs, paste(inner, collapse = "")))
    }
    det <- MUSCLE_BODY_DETAIL[MUSCLE_BODY_DETAIL$view == v, , drop = FALSE]
    for (i in seq_len(nrow(det))) {
      el <- sprintf('<path d="%s" fill="none" stroke="#fff" stroke-opacity=".5" stroke-width=".8" stroke-linecap="round" pointer-events="none"/>', det$d[i])
      g <- paste0(g, el, sprintf('<g transform="translate(220,0) scale(-1,1)">%s</g>', el))
    }
    if (isTRUE(show_names)) {
      a <- MUSCLE_BODY_ANCHORS[MUSCLE_BODY_ANCHORS$view == v, , drop = FALSE]
      for (i in seq_len(nrow(a))) g <- paste0(g, sprintf('<text x="%s" y="%s" font-size="5.5" text-anchor="middle" fill="#fff" stroke="#0006" stroke-width=".25" pointer-events="none">%s</text>',
                                                      a$x[i], a$y[i], muscle_esc(muscle_name(a$muscle[i]))))
    }
    if (has_co) {
      used <- character(0); co <- list()
      for (c0 in callouts) {
        m <- c0$m %||% c0$muscle; t <- c0$t %||% c0$text
        a <- MUSCLE_BODY_ANCHORS[MUSCLE_BODY_ANCHORS$muscle == m, , drop = FALSE]; if (!nrow(a)) next
        first_view <- if (any(a$view == views[1])) views[1] else a$view[1]
        if (first_view != v || m %in% used) next
        used <- c(used, m); aa <- a[a$view == v, ][1, ]
        co[[length(co) + 1L]] <- list(x = aa$x, y = aa$y, t = t, m = m)
      }
      if (length(co)) {
        co <- co[order(vapply(co, function(z) z$y, 0))]
        ly <- vapply(co, function(z) z$y, 0)
        for (k in seq_along(ly)[-1]) if (ly[k] < ly[k - 1] + 13) ly[k] <- ly[k - 1] + 13
        for (k in seq_along(co)) {
          z <- co[[k]]; lx <- 214
          g <- paste0(g, sprintf('<polyline points="%s,%s %s,%s %s,%s" fill="none" stroke="#37474f" stroke-width=".8"/><circle cx="%s" cy="%s" r="1.8" fill="#37474f"/><text x="%s" y="%s" font-size="7.2" fill="#263238"><title>%s</title>%s</text>',
                                 z$x, z$y, lx - 6, ly[k], lx, ly[k], z$x, z$y, lx + 3, ly[k] + 2.6, muscle_esc(z$t),
                                 muscle_esc(if (nchar(z$t) > 24) paste0(substr(z$t, 1, 23), "...") else z$t)))
        }
      }
    }
    body <- c(body, paste0(g, "</g>"))
  }
  ttl <- if (top > 0) sprintf('<text x="%s" y="12" font-size="11" font-weight="700" text-anchor="middle" fill="#1b2a36">%s</text>', total_w / 2, muscle_esc(title)) else ""
  sprintf('<svg class="mm%s" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %s %s" style="width:100%%;max-width:%spx;height:auto;display:block;margin:auto">%s<defs>%s</defs>%s%s</svg>',
          uid, total_w, 478 + top, if (length(views) == 1) 360 + (if (has_co) 120 else 0) else 760, css, defs, ttl, paste(body, collapse = ""))
}

# ---- BigQuery table definitions (new tables only; no existing table is touched) ----
MUSCLE_TABLES <- c(programmes = "muscle_programmes", diagrams = "muscle_diagrams", log = "muscle_set_log", targets = "muscle_targets")
MUSCLE_SCHEMAS <- list(
  programmes = c(id = "INTEGER", created_at = "TIMESTAMP", programme_id = "STRING", programme_start = "STRING", week_no = "INTEGER",
                 block_week = "INTEGER", phase = "STRING", day_no = "INTEGER", day_label = "STRING", planned_date = "STRING",
                 option_key = "STRING", option_title = "STRING", exercise_order = "INTEGER", exercise_name = "STRING",
                 equipment = "STRING", machine_or_load = "STRING", primary_muscles = "STRING", secondary_muscles = "STRING",
                 sets = "INTEGER", rep_min = "INTEGER", rep_max = "INTEGER", target_rir = "INTEGER", target_load_kg = "FLOAT",
                 load_source = "STRING", rest_sec = "INTEGER", cues = "STRING", injury_note = "STRING", status = "STRING"),
  diagrams = c(id = "INTEGER", created_at = "TIMESTAMP", diagram_id = "STRING", programme_id = "STRING", week_no = "INTEGER",
               day_no = "INTEGER", option_key = "STRING", title = "STRING", view = "STRING", spec_json = "STRING", source = "STRING", notes = "STRING"),
  log = c(id = "INTEGER", created_at = "TIMESTAMP", workout_date = "STRING", programme_id = "STRING", week_no = "INTEGER", day_no = "INTEGER",
          option_key = "STRING", exercise_name = "STRING", primary_muscles = "STRING", secondary_muscles = "STRING",
          set_no = "INTEGER", load_kg = "FLOAT", reps = "INTEGER", rir = "INTEGER", notes = "STRING"),
  targets = c(id = "INTEGER", created_at = "TIMESTAMP", muscle_id = "STRING", mev = "INTEGER", mrv = "INTEGER"))

# Schemas use short R-side type names; BigQuery GoogleSQL DDL needs INT64 / FLOAT64
# (plain FLOAT is NOT a valid DDL type and fails with "Type not found: FLOAT").
MUSCLE_SQL_TYPES <- c(INTEGER = "INT64", FLOAT = "FLOAT64", STRING = "STRING", TIMESTAMP = "TIMESTAMP")
muscle_ddl <- function(full_name, schema) sprintf("CREATE TABLE IF NOT EXISTS `%s` (\n  %s\n)", full_name,
  paste(names(schema), unname(MUSCLE_SQL_TYPES[schema]), collapse = ",\n  "))

# coerce a data.frame to the column types of a table (adds missing columns, drops extras)
muscle_empty <- function(key) as.data.frame(lapply(MUSCLE_SCHEMAS[[key]], function(t) switch(t, INTEGER = integer(0), FLOAT = numeric(0),
                                      TIMESTAMP = as.POSIXct(character(0), tz = "UTC"), character(0))), stringsAsFactors = FALSE)
muscle_conform <- function(df, schema) {
  n <- nrow(df)
  for (nm in names(schema)) {
    if (!nm %in% names(df)) df[[nm]] <- switch(schema[[nm]], INTEGER = rep(NA_integer_, n), FLOAT = rep(NA_real_, n), TIMESTAMP = rep(Sys.time(), n), rep(NA_character_, n))
    df[[nm]] <- switch(schema[[nm]], INTEGER = as.integer(df[[nm]]), FLOAT = as.numeric(df[[nm]]),
                       TIMESTAMP = if (inherits(df[[nm]], "POSIXct")) df[[nm]] else as.POSIXct(df[[nm]], tz = "UTC"),
                       { x <- as.character(df[[nm]]); x[is.na(x)] <- ""; x })
  }
  df[, names(schema), drop = FALSE]
}

# ---- shared data helpers used by the four muscle modules ----------------------
muscle_programme_start <- function(prog) {
  if (!is.data.frame(prog) || !nrow(prog)) return(NULL)
  s <- tail(prog$programme_start[nzchar(prog$programme_start)], 1)
  d <- suppressWarnings(as.Date(s)); if (length(d) == 0 || is.na(d)) NULL else d
}
muscle_week_rows <- function(df, week_no) if (is.data.frame(df) && nrow(df)) df[!is.na(df$week_no) & df$week_no == week_no, , drop = FALSE] else df
muscle_done_sets <- function(log_rows) {
  if (!is.data.frame(log_rows) || !nrow(log_rows)) return(stats::setNames(numeric(length(MUSCLE_IDS)), MUSCLE_IDS))
  ok <- !is.na(log_rows$reps) & log_rows$reps > 0
  muscle_credit_sets(log_rows$primary_muscles[ok], log_rows$secondary_muscles[ok], rep(1, sum(ok)))
}
muscle_week_status_df <- function(cat, week_no, done) {
  tg <- muscle_week_targets(week_no, cat)
  d <- done[cat$id]
  data.frame(id = cat$id, name = cat$name, group = cat$group, target = as.numeric(tg[cat$id]), done = as.numeric(d),
             status = muscle_status(as.numeric(d), as.numeric(tg[cat$id])), stringsAsFactors = FALSE)
}
# best (heaviest, then most reps) set of each exercise's most recent session
muscle_last_perf <- function(log, max_rows = 40) {
  if (!is.data.frame(log) || !nrow(log)) return(NULL)
  l <- log[!is.na(log$reps) & log$reps > 0 & !is.na(log$load_kg), , drop = FALSE]; if (!nrow(l)) return(NULL)
  out <- lapply(split(l, tolower(l$exercise_name)), function(h) {
    h <- h[as.character(h$workout_date) == max(as.character(h$workout_date)), , drop = FALSE]
    h <- h[order(-h$load_kg, -h$reps), , drop = FALSE]; h[1, c("exercise_name", "load_kg", "reps")]
  })
  out <- do.call(rbind, out); rownames(out) <- NULL
  utils::head(out[order(out$exercise_name), ], max_rows)
}
muscle_legend_html <- function(mode) {
  items <- switch(mode,
    gaps = lapply(names(MUSCLE_STATUS), function(k) c(MUSCLE_STATUS[[k]], MUSCLE_STATUS_LABEL[[k]])),
    session = list(c(MUSCLE_ROLE_COLOR[["primary"]], "Primary muscle"), c(MUSCLE_ROLE_COLOR[["secondary"]], "Secondary muscle"), c("#eadfd6", "Not used")),
    NULL)
  if (is.null(items)) return("")
  paste0('<div style="display:flex;flex-wrap:wrap;gap:12px;font-size:12px;margin:6px 0">',
         paste(vapply(items, function(i) sprintf('<span><span style="display:inline-block;width:12px;height:12px;border-radius:3px;background:%s;margin-right:5px;vertical-align:-2px"></span>%s</span>', i[1], i[2]), ""), collapse = ""), '</div>')
}
