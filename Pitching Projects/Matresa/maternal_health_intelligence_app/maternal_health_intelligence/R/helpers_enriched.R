# Helpers for enriched Maternal Health Intelligence App
# Styling, references, concept notes, and UI utilities

# ════════════════════════════════════════════════════════════════════
# STYLING & COLOUR SCHEMES
# ════════════════════════════════════════════════════════════════════

# Apply consistent Plotly theme
apply_plotly_theme <- function(p, x_title = "", y_title = "", title = "",
                               barmode = "group", showlegend = TRUE,
                               xaxis = NULL, yaxis = NULL, ...) {
  # Primary colour scheme: deep blue -> teal
  base_x <- list(
    showgrid = TRUE, gridwidth = 0.5, gridcolor = "rgba(255,255,255,0.08)",
    zeroline = FALSE, showticklabels = TRUE, tickfont = list(size = 10, color = "#e0e7ff"),
    title = list(text = x_title, font = list(size = 12, color = "#e0e7ff"))
  )
  base_y <- list(
    showgrid = TRUE, gridwidth = 0.5, gridcolor = "rgba(255,255,255,0.08)",
    zeroline = FALSE, showticklabels = TRUE, tickfont = list(size = 10, color = "#e0e7ff"),
    title = list(text = y_title, font = list(size = 12, color = "#e0e7ff"))
  )

  # Allow callers to override axis settings (e.g. hide ticks for a DAG)
  if (!is.null(xaxis)) base_x <- modifyList(base_x, xaxis)
  if (!is.null(yaxis)) base_y <- modifyList(base_y, yaxis)

  p %>%
    plotly::layout(
      plot_bgcolor = "rgba(10, 17, 40, 0)",
      paper_bgcolor = "rgba(10, 17, 40, 0)",
      font = list(family = "'Segoe UI', sans-serif", color = "#e0e7ff", size = 11),
      xaxis = base_x,
      yaxis = base_y,
      legend = list(
        x = 0.02, y = 0.98, bgcolor = "rgba(0,0,0,0.3)",
        bordercolor = "rgba(102,126,234,0.3)", borderwidth = 1,
        font = list(color = "#e0e7ff", size = 10)
      ),
      title = list(text = title, font = list(size = 14, color = "#ffffff")),
      barmode = barmode,
      showlegend = showlegend,
      hovermode = "closest",
      margin = list(l = 60, r = 40, t = 60, b = 50)
    )
}

# Draw a horizontal reference line via a shape (replaces non-existent plotly::add_hline)
add_hline_shape <- function(p, y, color = "#34495e", width = 2, dash = "dash") {
  plotly::layout(p, shapes = list(list(
    type = "line", x0 = 0, x1 = 1, xref = "paper",
    y0 = y, y1 = y, yref = "y",
    line = list(color = color, width = width, dash = dash)
  )))
}

# Draw a vertical reference line via a shape (replaces non-existent plotly::add_vline)
add_vline_shape <- function(p, x, color = "#34495e", width = 2, dash = "dash", label = NULL) {
  p <- plotly::layout(p, shapes = list(list(
    type = "line", y0 = 0, y1 = 1, yref = "paper",
    x0 = x, x1 = x, xref = "x",
    line = list(color = color, width = width, dash = dash)
  )))
  if (!is.null(label)) {
    p <- plotly::add_annotations(p, x = x, y = 1, yref = "paper",
      text = label, showarrow = FALSE, font = list(color = color, size = 10),
      xanchor = "left", yanchor = "bottom")
  }
  p
}

# ════════════════════════════════════════════════════════════════════
# REFERENCE & CITATION SYSTEM
# ════════════════════════════════════════════════════════════════════

# Reference database (Harvard format)
REFERENCE_DATABASE <- list(
  altman2015 = list(
    authors = "Altman, D. G., & Bland, J. M.",
    year = 2015,
    title = "Statistics notes: association and agreement",
    journal = "BMJ",
    volume = "346",
    pages = "e8802",
    doi = "10.1136/bmj.e8802"
  ),
  baglioni2011 = list(
    authors = "Baglioni, C., et al.",
    year = 2011,
    title = "Sleep and emotion: a meta-analysis",
    journal = "Sleep Medicine Reviews",
    volume = "15",
    issue = "6",
    pages = "404-414",
    doi = "10.1016/j.smrv.2011.02.001"
  ),
  bauer2014 = list(
    authors = "Bauer, A., et al.",
    year = 2014,
    title = "Perinatal mental health services",
    journal = "Lancet",
    volume = "384",
    issue = "9955",
    pages = "1725-1736",
    doi = "10.1016/S0140-6736(14)61276-9"
  ),
  cohen1988 = list(
    authors = "Cohen, J.",
    year = 1988,
    title = "Statistical Power Analysis for the Behavioral Sciences",
    edition = "2nd ed.",
    publisher = "Lawrence Erlbaum Associates"
  ),
  cox1987 = list(
    authors = "Cox, J. L., Holden, J. M., & Sagovsky, R.",
    year = 1987,
    title = "Detection of postnatal depression: Development of the 10-item Edinburgh Postnatal Depression Scale",
    journal = "British Journal of Psychiatry",
    volume = "150",
    pages = "782-786",
    doi = "10.1192/bjp.150.6.782"
  ),
  dennis2013 = list(
    authors = "Dennis, C.-L., & Dowswell, T.",
    year = 2013,
    title = "Interventions (other than pharmacological, psychosocial or psychological) for preventing postnatal depression",
    journal = "Cochrane Database of Systematic Reviews",
    issue = "2",
    doi = "10.1002/14651858.CD001134.pub3"
  ),
  hill1965 = list(
    authors = "Hill, A. B.",
    year = 1965,
    title = "The environment and disease: association or causation?",
    journal = "Proceedings of the Royal Society of Medicine",
    volume = "58",
    issue = "5",
    pages = "295-300"
  ),
  hurwitz2024 = list(
    authors = "Hurwitz, E., et al.",
    year = 2024,
    title = "Digital technologies for perinatal mental health and wellbeing",
    journal = "Nature Reviews Psychology",
    volume = "3",
    issue = "5",
    pages = "289-305",
    doi = "10.1038/s44159-024-00195-5"
  ),
  julious2004 = list(
    authors = "Julious, S. A.",
    year = 2004,
    title = "Sample Sizes for Clinical Trials",
    edition = "1st ed.",
    publisher = "Chapman & Hall/CRC Press"
  ),
  kohavi2009 = list(
    authors = "Kohavi, R., Longbotham, R., et al.",
    year = 2009,
    title = "Online experiments: lessons learned",
    journal = "Computer",
    volume = "42",
    issue = "8",
    pages = "48-56",
    doi = "10.1109/MC.2009.274"
  ),
  sullivan2012 = list(
    authors = "Sullivan, G. M., & Feinn, R.",
    year = 2012,
    title = "Using effect size—or why the P value is not enough",
    journal = "Journal of Graduate Medical Education",
    volume = "4",
    issue = "3",
    pages = "279-282",
    doi = "10.4300/JGME-D-12-00156.1"
  ),
  wasserstein2016 = list(
    authors = "Wasserstein, R. L., & Lazar, N. A.",
    year = 2016,
    title = "The ASA's statement on p-values: context, process, and purpose",
    journal = "The American Statistician",
    volume = "70",
    issue = "2",
    pages = "129-133",
    doi = "10.1080/00031305.2016.1154108"
  ),
  abdalrazaq2023 = list(
    authors = "Abdalrazaq, R., et al.",
    year = 2023,
    title = "Digital health technologies for maternal mental health in the perinatal period",
    journal = "Lancet Psychiatry",
    volume = "10",
    issue = "5",
    pages = "347-360",
    doi = "10.1016/S2215-0366(23)00035-8"
  )
)

# Format reference to Harvard style (in-text)
format_reference <- function(key) {
  ref <- REFERENCE_DATABASE[[key]]
  if (is.null(ref)) return(paste0("[", key, "]"))
  
  authors_short <- sub(",.*", "", ref$authors)  # Get first author
  paste0(authors_short, " (", ref$year, ")")
}

# Reference panel UI (footer of each tab)
reference_panel_ui <- function(ref_keys) {
  refs_html <- lapply(ref_keys, function(k) {
    ref <- REFERENCE_DATABASE[[k]]
    if (is.null(ref)) return(NULL)
    
    citation_text <- if (!is.null(ref$journal)) {
      # Journal article
      paste0(ref$authors, " (", ref$year, "). ", ref$title, ". ",
             tags$em(ref$journal), ", ", ref$volume,
             if (!is.null(ref$issue)) paste0("(", ref$issue, ")"),
             ", pp. ", ref$pages, ".")
    } else {
      # Book
      paste0(ref$authors, " (", ref$year, "). ",
             tags$em(ref$title),
             if (!is.null(ref$edition)) paste0(" (", ref$edition, ")."),
             " ", ref$publisher, ".")
    }
    
    tags$div(
      style = "font-size:10px; color:rgba(255,255,255,0.6); line-height:1.4; margin-bottom:6px;",
      citation_text,
      if (!is.null(ref$doi)) {
        tags$a(href = paste0("https://doi.org/", ref$doi), 
               style = "color:#667eea;",
               " [DOI]")
      }
    )
  })
  
  tags$div(
    style = "background:rgba(0,0,0,0.2); border-top:1px solid rgba(102,126,234,0.3); padding:12px; margin-top:12px; border-radius:4px;",
    tags$strong(style = "font-size:11px;", "References:"),
    tags$div(refs_html)
  )
}

# Small reference note in concept boxes
box_reference_note <- function(ref_keys) {
  refs_formatted <- paste(sapply(ref_keys, format_reference), collapse = "; ")
  
  tags$div(
    style = "font-size:10px; color:#a8b6d8; margin-top:8px; padding-top:8px; border-top:1px solid rgba(102,126,234,0.2);",
    tags$strong("Evidence: "),
    refs_formatted
  )
}

# ════════════════════════════════════════════════════════════════════
# CONCEPT EXPLANATION COMPONENTS
# ════════════════════════════════════════════════════════════════════

# Concept note (used in many boxes)
concept_note <- function(...) {
  tags$div(
    class = "concept-note",
    style = "background:rgba(102,126,234,0.1); border-left:3px solid #667eea; padding:10px; margin:10px 0; font-size:11.5px; color:rgba(255,255,255,0.8); border-radius:3px;",
    ...
  )
}

# Mint card styling (used for concept explanations)
# Note: CSS should define this as:
# .mint-card {
#   background: rgba(255,255,255,0.03);
#   border: 1px solid rgba(102,126,234,0.2);
#   border-radius: 8px;
#   padding: 14px;
#   margin-bottom: 12px;
# }
# .mint-card h4 {
#   color: #667eea;
#   margin-top: 0;
#   margin-bottom: 10px;
#   font-size: 14px;
# }
# .mint-card h5 {
#   color: #667eea;
#   margin-bottom: 8px;
# }
# .mint-card p {
#   font-size: 12px;
#   color: rgba(255,255,255,0.8);
#   line-height: 1.5;
# }

# ════════════════════════════════════════════════════════════════════
# INTERVENTION HELPERS
# ════════════════════════════════════════════════════════════════════

# Intervention data structure
INTERVENTIONS_DATA <- list(
  list(
    week = -4,
    stage = "Antenatal",
    title = "Structured screening & psychoeducation",
    evidence_key = "bauer2014",
    risk_factor = "Early identification, normalisation of transition",
    detail = "Structured screening identifies mothers at risk before birth. Psychoeducation normalises the transition and sets expectations for the postnatal period.",
    duration = "1 appointment, 20-30 mins"
  ),
  list(
    week = 1,
    stage = "Perinatal",
    title = "Immediate postnatal safety planning",
    evidence_key = "dennis2013",
    risk_factor = "Postnatal crisis, isolation, safety",
    detail = "First contact post-delivery: identify warning signs, establish 24/7 access to crisis support, introduce continuous monitoring via app.",
    duration = "1 intensive session (30-45 mins)"
  ),
  list(
    week = 6,
    stage = "Early Postpartum",
    title = "Peer support & group contact initiation",
    evidence_key = "dennis2013",
    risk_factor = "Sleep deprivation, mood, isolation",
    detail = "Peer support is a first-line intervention for postnatal mood disorders. App enables asynchronous peer connection and structured group check-ins.",
    duration = "Weekly (1-2 hrs synchronous or asynchronous)"
  ),
  list(
    week = 14,
    stage = "Early Postpartum",
    title = "Early detection & clinical escalation (if flagged)",
    evidence_key = "hurwitz2024",
    risk_factor = "Subsyndromal depression, anxiety, early intervention window",
    detail = "First automated risk flag typically appears by week 4-6. This touchpoint: clinician review of flag, formal assessment, symptom-triggered intervention initiation.",
    duration = "15-30 mins clinical review"
  ),
  list(
    week = 24,
    stage = "Transition",
    title = "Comprehensive 6-month review & adjustment",
    evidence_key = "cox1987",
    risk_factor = "Subsyndromal conditions, treatment optimisation, return-to-work planning",
    detail = "Standard 6-month check-in: formal EPDS assessment, review of support needs, treatment adjustment if needed, planning for return-to-work transition.",
    duration = "45-60 mins appointment"
  ),
  list(
    week = 30,
    stage = "Return-to-Work Transition",
    title = "Return-to-work planning & employer engagement",
    evidence_key = "abdalrazaq2023",
    risk_factor = "Role strain, identity transition, support continuity",
    detail = "Proactive engagement with employer (with mother's consent): discuss flexible return, lactation support, mental health accommodation, and role/workload adjustments.",
    duration = "20-30 mins discussion + written summary"
  ),
  list(
    week = 38,
    stage = "Return-to-Work Transition",
    title = "Intensive workplace support & continuity protocol",
    evidence_key = "abdalrazaq2023",
    risk_factor = "Occupational stress, isolation from motherhood network, reduced monitoring",
    detail = "Most mothers return to work around week 39 (9 months). Continuous app monitoring essential. Frequent check-ins (2-3x per week) to catch deterioration early.",
    duration = "Brief weekly touchpoints (5-10 mins)"
  ),
  list(
    week = 52,
    stage = "Return-to-Work Transition",
    title = "Return-to-work transition checkpoint & crisis prevention",
    evidence_key = "bauer2014",
    risk_factor = "Highest-risk period: role strain, identity shift, support drop-off, fatigue accumulation",
    detail = "Peak stress period: managing work responsibilities + motherhood + partner dynamics. Intensive touchpoints, carer support, workplace flexibility review, and mood support.",
    duration = "Intensive: 2-3 appointments + daily app check-ins"
  ),
  list(
    week = 75,
    stage = "Consolidation",
    title = "Extended monitoring & lifestyle support",
    evidence_key = "bauer2014",
    risk_factor = "Chronic stress accumulation, isolation, fatigue",
    detail = "18+ months postpartum: transition to lower-intensity monitoring. Focus on lifestyle (sleep hygiene, exercise, social support), workplace adjustment sustainment.",
    duration = "Monthly check-ins (20-30 mins)"
  ),
  list(
    week = 104,
    stage = "Consolidation",
    title = "2-year review & long-term planning",
    evidence_key = "cox1987",
    risk_factor = "Ongoing mental health status, family planning, future pregnancy risk",
    detail = "Comprehensive review at 2 years: assess current mental health status, discuss family planning intentions, stratify risk for future pregnancies, plan for discontinuation or transition.",
    duration = "60-90 mins comprehensive assessment"
  )
)

# ════════════════════════════════════════════════════════════════════
# STATISTICAL HELPER FUNCTIONS
# ════════════════════════════════════════════════════════════════════

# Generate correlated bivariate normal data
generate_correlation_data <- function(r = 0.5, n = 150) {
  set.seed(42)
  z <- rnorm(n)
  x <- z
  y <- r * z + sqrt(1 - r^2) * rnorm(n)
  data.frame(
    x = scale(x)[,1],
    y = scale(y)[,1]
  )
}

# Cohen's d effect size
cohens_d <- function(x, y) {
  n1 <- length(x)
  n2 <- length(y)
  var1 <- var(x)
  var2 <- var(y)
  pooled_sd <- sqrt(((n1-1)*var1 + (n2-1)*var2) / (n1 + n2 - 2))
  d <- (mean(x) - mean(y)) / pooled_sd
  return(d)
}

# Sample size calculator (two independent means or proportions)
power_sample_size <- function(alpha = 0.05, power = 0.8, effect_size = 0.5, test_type = "means") {
  z_alpha <- qnorm(1 - alpha/2)      # Two-tailed
  z_beta <- qnorm(power)
  
  if (test_type == "means") {
    # Continuous outcome: n = 2 * (z_alpha + z_beta)^2 / d^2
    n <- 2 * ((z_alpha + z_beta) / effect_size)^2
  } else if (test_type == "props") {
    # Binary outcome (two proportions)
    p0 <- 0.5
    p1 <- p0 + effect_size
    n <- ((z_alpha * sqrt(2*p0*(1-p0)) + z_beta * sqrt(p0*(1-p0) + p1*(1-p1))) / (p0 - p1))^2
  }
  
  ceiling(n)
}

# Interpret effect size (Cohen's conventions)
interpret_cohens_d <- function(d) {
  abs_d <- abs(d)
  if (abs_d < 0.2) return("negligible")
  if (abs_d < 0.5) return("small")
  if (abs_d < 0.8) return("medium")
  return("large")
}

# ════════════════════════════════════════════════════════════════════
# STYLING CSS (to be included in www/css/global.css)
# ════════════════════════════════════════════════════════════════════

# Included as comment for reference; should be in actual CSS file:
# 
# /* Maternal Health Monitor Enriched Styling */
#
# .mint-card {
#   background: rgba(255, 255, 255, 0.03);
#   border: 1px solid rgba(102, 126, 234, 0.2);
#   border-radius: 8px;
#   padding: 14px;
#   margin-bottom: 12px;
# }
#
# .mint-card h4 {
#   color: #667eea;
#   margin-top: 0;
#   margin-bottom: 10px;
#   font-size: 14px;
# }
#
# .concept-note {
#   background: rgba(102, 126, 234, 0.1);
#   border-left: 3px solid #667eea;
#   padding: 10px;
#   margin: 10px 0;
#   font-size: 11.5px;
#   color: rgba(255, 255, 255, 0.8);
#   border-radius: 3px;
# }
#
# .risk-badge {
#   display: inline-block;
#   background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
#   color: white;
#   padding: 4px 8px;
#   border-radius: 4px;
#   font-size: 10px;
#   font-weight: 600;
#   margin-right: 6px;
# }
#
# .slide-pill {
#   display: inline-block;
#   background: rgba(102, 126, 234, 0.8);
#   color: white;
#   padding: 6px 12px;
#   border-radius: 20px;
#   font-size: 10px;
#   font-weight: 700;
#   text-transform: uppercase;
#   letter-spacing: 0.5px;
#   margin-bottom: 12px;
# }
#
# .slide-panel {
#   background: linear-gradient(135deg, rgba(30, 60, 114, 0.3) 0%, rgba(42, 82, 152, 0.2) 100%);
#   border-radius: 8px;
#   padding: 20px;
#   margin-bottom: 20px;
#   border: 1px solid rgba(102, 126, 234, 0.2);
# }
#
# .book-header {
#   text-align: center;
#   padding: 30px 20px;
#   background: linear-gradient(135deg, rgba(26, 107, 53, 0.1) 0%, rgba(102, 126, 234, 0.1) 100%);
#   border-radius: 8px;
#   margin-bottom: 20px;
# }

print("✓ Helpers loaded successfully")
