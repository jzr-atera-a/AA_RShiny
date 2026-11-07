# R/utils_ppd_risk.R
# ===============================================================================
# Shared data + scoring layer for the "Maternal Health Monitor" module.
# Single source of truth for: the simulated longitudinal maternal cohort,
# the composite early-warning risk score + paired breakdown, colour scale,
# cohort labels, and the verified Harvard-style reference list shown on
# every subtab.
#
# CLINICAL SAFETY NOTE: epds_self_harm_flag() is a deterministic hard
# trigger. It is never blended into the weighted composite score, never
# smoothed, and never passed through an LLM.
#
# All cohort/mother-level data in this file is SIMULATED. The five academic
# references below are real, verifiable, published sources used to ground
# the app's design choices - they are not claims about the simulated data.
# ===============================================================================

`%||%` <- function(x, y) if (is.null(x)) y else x

# ── Cohorts ─────────────────────────────────────────────────────────────────
COHORT_LABELS <- c(
  app_supported = "App-Supported",
  standard_care = "Standard NHS Care",
  no_support    = "No Structured Support (Control)"
)

# Shorter aliases for chart axes, where the full labels above overlap
COHORT_LABELS_SHORT <- c(
  app_supported = "App-Supported",
  standard_care = "Standard Care",
  no_support    = "No Support"
)

COHORT_COLOURS <- c(
  app_supported = "#667eea",  # brand purple-blue (best outcome)
  standard_care = "#4a90e2",  # bright-blue
  no_support    = "#e74c3c"   # red
)

# ── Shared plotly styling helper ─────────────────────────────────────────────
# Applies one consistent look (navy/teal DriveSafe palette, unified hover,
# light gridlines, Segoe/Helvetica font stack) to every chart in the module,
# the same way the reference app kept one shared theme across all of its
# plotly figures.
apply_plotly_theme <- function(p, title = NULL, x_title = NULL, y_title = NULL,
                                legend = TRUE, hovermode = "closest",
                                x_range = NULL, y_range = NULL, barmode = NULL) {
  # Light text/gridlines, because every chart sits on this app's dark
  # navy/blue glass-card box-body (see www/css/global.css), not a white one.
  xaxis <- list(title = x_title, gridcolor = "rgba(255,255,255,0.12)", zerolinecolor = "rgba(255,255,255,0.25)",
                showline = TRUE, linecolor = "rgba(255,255,255,0.25)", tickfont = list(color = "#e0e7ff"),
                titlefont = list(color = "#c7d2fe"))
  yaxis <- list(title = y_title, gridcolor = "rgba(255,255,255,0.12)", zerolinecolor = "rgba(255,255,255,0.25)",
                showline = TRUE, linecolor = "rgba(255,255,255,0.25)", tickfont = list(color = "#e0e7ff"),
                titlefont = list(color = "#c7d2fe"))
  if (!is.null(x_range)) xaxis$range <- x_range
  if (!is.null(y_range)) yaxis$range <- y_range

  p <- p %>% plotly::layout(
    title = if (!is.null(title)) list(text = title, font = list(size = 14, color = "#ffffff")) else NULL,
    paper_bgcolor = "rgba(0,0,0,0)",
    plot_bgcolor  = "rgba(0,0,0,0)",
    font = list(family = "Helvetica Neue, Arial, sans-serif", size = 12, color = "#e0e7ff"),
    hovermode = hovermode,
    hoverlabel = list(bgcolor = "#0a1128", font = list(color = "#ffffff", size = 12),
                       bordercolor = "#4a90e2"),
    xaxis = xaxis,
    yaxis = yaxis,
    barmode = barmode,
    legend = if (legend) list(orientation = "h", y = -0.22, font = list(size = 11, color = "#e0e7ff")) else list(),
    margin = list(t = if (!is.null(title)) 40 else 10, b = 40, l = 50, r = 20)
  ) %>% plotly::config(displaylogo = FALSE,
                        modeBarButtonsToRemove = c("select2d", "lasso2d", "autoScale2d"))
  p
}

# ── Risk score colour scale (4-band convention) ──────────────────────────────
risk_colour <- function(score) {
  score <- as.numeric(score)
  out <- rep("#1a6b35", length(score))
  out[score >= 25 & score < 50] <- "#d4ac0d"
  out[score >= 50 & score < 75] <- "#e67e22"
  out[score >= 75]              <- "#c0392b"
  out[is.na(score)]             <- "#999999"
  out
}

risk_category <- function(score) {
  score <- as.numeric(score)
  out <- rep("Low", length(score))
  out[score >= 25 & score < 50] <- "Moderate"
  out[score >= 50 & score < 75] <- "High"
  out[score >= 75]              <- "Critical"
  out
}

RISK_SCALE_LABELS  <- c("Low (0-25)", "Moderate (25-50)", "High (50-75)", "Critical (75-100)")
RISK_SCALE_COLOURS <- c("#1a6b35", "#d4ac0d", "#e67e22", "#c0392b")

# ── EPDS (Edinburgh Postnatal Depression Scale) handling ────────────────────
EPDS_ITEM_LABELS <- c(
  "Able to laugh and see the funny side of things",
  "Looked forward with enjoyment to things",
  "Blamed myself unnecessarily when things went wrong",
  "Been anxious or worried for no good reason",
  "Felt scared or panicky for no very good reason",
  "Things have been getting on top of me",
  "Been so unhappy that I have had difficulty sleeping",
  "Felt sad or miserable",
  "Been so unhappy that I have been crying",
  "The thought of harming myself has occurred to me"
)

epds_total <- function(item_scores) sum(item_scores)

epds_band <- function(total) {
  out <- rep("Low likelihood of depression", length(total))
  out[total >= 10 & total < 13] <- "Possible depression - review"
  out[total >= 13]              <- "Probable depression - clinical review indicated"
  out
}

epds_self_harm_flag <- function(item_10_score) as.numeric(item_10_score) > 0

# ── Composite behavioural early-warning score ────────────────────────────────
PPD_RISK_WEIGHTS <- c(
  sleep_fragmentation      = 0.89,
  mood_variance_14d        = 0.74,
  checkin_engagement_drop  = 0.61,
  support_content_change   = 0.49,
  resting_hrv_delta        = 0.39
)

ppd_risk_score <- function(sleep_fragmentation, mood_variance_14d,
                            checkin_engagement_drop, support_content_change,
                            resting_hrv_delta) {
  w <- PPD_RISK_WEIGHTS
  wsum <- sum(w)
  raw <- (sleep_fragmentation     * w["sleep_fragmentation"] +
          mood_variance_14d       * w["mood_variance_14d"] +
          checkin_engagement_drop * w["checkin_engagement_drop"] +
          support_content_change  * w["support_content_change"] +
          resting_hrv_delta       * w["resting_hrv_delta"]) / wsum
  as.numeric(pmin(100, pmax(0, raw * 100)))
}

ppd_risk_breakdown <- function(sleep_fragmentation, mood_variance_14d,
                                checkin_engagement_drop, support_content_change,
                                resting_hrv_delta) {
  w <- PPD_RISK_WEIGHTS
  contributions <- c(
    "Sleep fragmentation"         = sleep_fragmentation     * w["sleep_fragmentation"],
    "Mood variance (14-day)"      = mood_variance_14d        * w["mood_variance_14d"],
    "Check-in engagement drop"    = checkin_engagement_drop  * w["checkin_engagement_drop"],
    "Support content change"      = support_content_change   * w["support_content_change"],
    "Resting HRV vs own baseline" = resting_hrv_delta         * w["resting_hrv_delta"]
  )
  list(
    contributions = sort(contributions, decreasing = TRUE),
    total_score = ppd_risk_score(sleep_fragmentation, mood_variance_14d,
                                  checkin_engagement_drop, support_content_change,
                                  resting_hrv_delta)
  )
}

# ── Simulated longitudinal cohort data ───────────────────────────────────────
generate_ppd_cohort_data <- function(n_per_cohort = 20, weeks = 24, seed = 42) {
  set.seed(seed)
  cohorts <- names(COHORT_LABELS)
  rows <- list()
  mother_counter <- 1

  for (cohort in cohorts) {
    divergence_mult <- switch(cohort,
      app_supported = 0.55,
      standard_care  = 0.80,
      no_support     = 1.15
    )

    for (i in seq_len(n_per_cohort)) {
      mother_id <- sprintf("M%03d", mother_counter)
      mother_counter <- mother_counter + 1

      diverges <- runif(1) < (0.30 * divergence_mult)
      onset_week <- if (diverges) sample(3:14, 1) else NA
      severity <- if (diverges) runif(1, 0.5, 1.0) * divergence_mult else runif(1, 0, 0.15)
      # Support reduces recovery time as well as onset severity
      recovers <- diverges && cohort != "no_support" && runif(1) < ifelse(cohort == "app_supported", 0.7, 0.4)
      recovery_week <- if (recovers) onset_week + sample(6:10, 1) else NA

      for (wk in 0:weeks) {
        base_noise <- rnorm(1, 0, 0.05)

        if (diverges && wk >= onset_week) {
          if (recovers && wk >= recovery_week) {
            progress <- pmax(0, severity * (1 - (wk - recovery_week) / 8))
          } else {
            progress <- pmin(1, (wk - onset_week) / 8)
          }
          drift <- if (recovers && wk >= recovery_week) progress else severity * progress
        } else {
          drift <- 0
        }

        sleep_frag   <- pmin(1, pmax(0, drift * 0.9 + base_noise + rnorm(1, 0, 0.05)))
        mood_var     <- pmin(1, pmax(0, drift * 0.8 + base_noise + rnorm(1, 0, 0.05)))
        engage_drop  <- pmin(1, pmax(0, drift * 0.7 + base_noise + rnorm(1, 0, 0.05)))
        support_chg  <- pmin(1, pmax(0, drift * 0.5 + base_noise + rnorm(1, 0, 0.05)))
        hrv_delta    <- pmin(1, pmax(0, drift * 0.4 + base_noise + rnorm(1, 0, 0.05)))

        score <- ppd_risk_score(sleep_frag, mood_var, engage_drop, support_chg, hrv_delta)

        epds_weeks <- c(0, 6, 12, 18, 24)
        if (wk %in% epds_weeks) {
          item_base <- pmin(3, pmax(0, round(drift * 2.5 + rnorm(1, 0.3, 0.4))))
          items <- pmin(3, pmax(0, round(item_base + rnorm(10, 0, 0.6))))
          item10 <- if (diverges && severity > 0.85 && wk >= onset_week + 4 &&
                        !(recovers && wk >= recovery_week)) {
            sample(0:1, 1, prob = c(0.7, 0.3))
          } else 0
          items[10] <- item10
          epds_tot <- epds_total(items)
        } else {
          items <- rep(NA_real_, 10)
          epds_tot <- NA_real_
        }

        rows[[length(rows) + 1]] <- data.frame(
          mother_id = mother_id,
          cohort = cohort,
          weeks_postpartum = wk,
          sleep_fragmentation = round(sleep_frag, 3),
          mood_variance_14d = round(mood_var, 3),
          checkin_engagement_drop = round(engage_drop, 3),
          support_content_change = round(support_chg, 3),
          resting_hrv_delta = round(hrv_delta, 3),
          composite_risk_score = round(score, 1),
          epds_total = epds_tot,
          self_harm_flag = if (!is.na(epds_tot)) epds_self_harm_flag(items[10]) else NA,
          diverges = diverges,
          onset_week = onset_week,
          recovery_week = recovery_week,
          stringsAsFactors = FALSE
        )
      }
    }
  }
  do.call(rbind, rows)
}

# ── Sample-size / power calculations ─────────────────────────────────────────
# Closed-form Normal-approximation formulas (Julious, 2004), the standard
# textbook approach for two-independent-group comparisons - avoids depending
# on the {pwr} package so the calculation always works offline.
#
# Two independent means (continuous outcome, e.g. composite risk score, EPDS):
#   n per group = 2 * (z_alpha + z_beta)^2 / d^2      (Cohen, 1988; Julious, 2004)
sample_size_two_means <- function(d, alpha = 0.05, power = 0.8, two_sided = TRUE) {
  z_alpha <- stats::qnorm(1 - alpha / (if (two_sided) 2 else 1))
  z_beta  <- stats::qnorm(power)
  n <- 2 * ((z_alpha + z_beta)^2) / d^2
  ceiling(n)
}

# Two independent proportions (binary outcome, e.g. self-harm item flagged):
#   n per group = (z_alpha*sqrt(2*pbar*(1-pbar)) + z_beta*sqrt(p1(1-p1)+p2(1-p2)))^2 / (p1-p2)^2
sample_size_two_proportions <- function(p1, p2, alpha = 0.05, power = 0.8, two_sided = TRUE) {
  z_alpha <- stats::qnorm(1 - alpha / (if (two_sided) 2 else 1))
  z_beta  <- stats::qnorm(power)
  pbar <- (p1 + p2) / 2
  n <- (z_alpha * sqrt(2 * pbar * (1 - pbar)) + z_beta * sqrt(p1 * (1 - p1) + p2 * (1 - p2)))^2 / (p1 - p2)^2
  ceiling(n)
}

# Cohen's (1988) conventional effect-size benchmarks for a standardised
# mean difference (d): small = 0.2, medium = 0.5, large = 0.8.
COHEN_D_BENCHMARKS <- c(Small = 0.2, Medium = 0.5, Large = 0.8)

# ── Verified, Harvard-style reference library ────────────────────────────────
# Every entry below is a real, published, independently verifiable source.
# Used to ground app design choices (screening instrument, cost rationale,
# digital-biomarker evidence base, intervention evidence base) - not to
# make claims about the app's own (simulated) data.
REFERENCES <- list(
  bauer2014 = list(
    key = "Bauer et al. (2014)",
    text = "Bauer, A., Parsonage, M., Knapp, M., Iemmi, V. and Adelaja, B. (2014) The Costs of Perinatal Mental Health Problems. London: Centre for Mental Health and London School of Economics and Political Science."
  ),
  cox1987 = list(
    key = "Cox, Holden and Sagovsky (1987)",
    text = "Cox, J.L., Holden, J.M. and Sagovsky, R. (1987) 'Detection of postnatal depression: development of the 10-item Edinburgh Postnatal Depression Scale', British Journal of Psychiatry, 150(6), pp. 782\u2013786."
  ),
  hurwitz2024 = list(
    key = "Hurwitz et al. (2024)",
    text = "Hurwitz, E., Butzin-Dozier, Z., Master, H., O'Neil, S.T., Walden, A., Holko, M., Patel, R.C. and Haendel, M.A. (2024) 'Harnessing consumer wearable digital biomarkers for individualized recognition of postpartum depression using the All of Us Research Program data set: cross-sectional study', JMIR mHealth and uHealth, 12, e54622."
  ),
  abdalrazaq2023 = list(
    key = "Abd-Alrazaq et al. (2023)",
    text = "Abd-Alrazaq, A., AlSaad, R., Shuweihdi, F., Ahmed, A., Aziz, S. and Sheikh, J. (2023) 'Systematic review and meta-analysis of performance of wearable artificial intelligence in detecting and predicting depression', npj Digital Medicine, 6, 84."
  ),
  dennis2013 = list(
    key = "Dennis and Dowswell (2013)",
    text = "Dennis, C.-L. and Dowswell, T. (2013) 'Psychosocial and psychological interventions for preventing postpartum depression', Cochrane Database of Systematic Reviews, Issue 2, Art. No. CD001134."
  ),
  cohen1988 = list(
    key = "Cohen (1988)",
    text = "Cohen, J. (1988) Statistical Power Analysis for the Behavioral Sciences. 2nd edn. Hillsdale, NJ: Lawrence Erlbaum Associates."
  ),
  julious2004 = list(
    key = "Julious (2004)",
    text = "Julious, S.A. (2004) 'Tutorial in biostatistics: sample sizes for clinical trials with Normal data', Statistics in Medicine, 23(12), pp. 1921\u20131986."
  )
)

# Small, consistently-styled "what this shows" explainer, dropped under a
# box title or chart to describe the concept/metric in plain language.
concept_note <- function(...) {
  div(class = "concept-note", icon("info-circle"), " ", ...)
}

# Renders a small, consistently-styled reference panel at the foot of a
# subtab. `ids` is a character vector of REFERENCES names, e.g.
# reference_panel_ui(c("bauer2014", "cox1987")).
reference_panel_ui <- function(ids) {
  items <- lapply(ids, function(id) {
    ref <- REFERENCES[[id]]
    tags$li(style = "margin-bottom:4px;", ref$text)
  })
  div(class = "reference-panel",
    tags$span(class = "reference-panel-title", icon("book"), " References"),
    tags$ol(style = "margin:6px 0 0 0; padding-left:18px; font-size:11.5px; color:rgba(255,255,255,0.85);",
      items)
  )
}
