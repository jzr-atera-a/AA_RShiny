# core/demo_data.R - coherent synthetic GA4-shaped data.
# Answers the same (dimensions, metrics, date range) questions as the real
# API, so every tab works before a connection exists. Deterministic: the same
# date always yields the same numbers.

.norm <- function(w) w / sum(w)

DEMO_DIMS <- list(
  sessionDefaultChannelGroup = list(
    values = c("Organic Search", "Direct", "Organic Social", "Referral", "Email", "Paid Search"),
    w = .norm(c(42, 26, 12, 9, 6, 5))),
  sessionSourceMedium = list(
    values = c("google / organic", "(direct) / (none)", "linkedin.com / referral",
               "bing / organic", "newsletter / email", "google / cpc",
               "t.co / referral", "github.com / referral", "duckduckgo / organic"),
    w = .norm(c(36, 26, 10, 5, 6, 5, 4, 4, 4))),
  country = list(
    values = c("United Kingdom", "United States", "Germany", "France", "Spain",
               "Netherlands", "Ireland", "India", "Canada", "Australia"),
    w = .norm(c(52, 16, 7, 5, 4, 4, 4, 3, 3, 2))),
  city = list(
    values = c("London", "Manchester", "Birmingham", "Leeds", "Glasgow", "Bristol",
               "New York", "Berlin", "Paris", "Dublin", "Edinburgh", "Madrid"),
    w = .norm(c(28, 9, 7, 6, 6, 5, 9, 6, 6, 6, 6, 6))),
  deviceCategory = list(
    values = c("desktop", "mobile", "tablet"), w = .norm(c(56, 39, 5))),
  browser = list(
    values = c("Chrome", "Safari", "Edge", "Firefox", "Samsung Internet"),
    w = .norm(c(58, 22, 10, 6, 4))),
  operatingSystem = list(
    values = c("Windows", "iOS", "Macintosh", "Android", "Linux"),
    w = .norm(c(38, 22, 18, 17, 5))),
  pagePath = list(
    values = c("/", "/services/", "/about/", "/blog/", "/contact/", "/pricing/",
               "/blog/shiny-dashboards/", "/blog/forecasting-in-r/", "/case-studies/",
               "/services/data-engineering/", "/services/analytics/", "/privacy-policy/"),
    w = .norm(c(30, 14, 9, 8, 7, 6, 7, 6, 5, 3, 3, 2))),
  landingPage = list(
    values = c("/", "/blog/shiny-dashboards/", "/blog/forecasting-in-r/", "/services/",
               "/about/", "/contact/", "/pricing/", "/case-studies/"),
    w = .norm(c(44, 14, 12, 10, 6, 5, 5, 4))),
  newVsReturning = list(values = c("new", "returning"), w = .norm(c(62, 38))),
  # eventName weights are events per session (not normalised); `u` = users per session
  eventName = list(
    values = c("page_view", "session_start", "user_engagement", "first_visit", "scroll",
               "click", "form_start", "form_submit", "file_download",
               # events sent by the Atera theme (v5.3+)
               "cta_click", "navigation_click", "contact_form_start", "generate_lead", "form_error",
               "faq_open", "scroll_depth", "architecture_view", "architecture_select",
               "architecture_open_full", "app_open"),
    w = c(2.2, 1.0, 1.4, 0.60, 0.90, 0.25, 0.060, 0.022, 0.030,
          0.14, 0.45, 0.035, 0.012, 0.002, 0.030, 1.30, 0.060, 0.050, 0.008, 0.020),
    u = c(0.84, 0.84, 0.62, 0.60, 0.38, 0.12, 0.050, 0.019, 0.025,
          0.10, 0.30, 0.030, 0.011, 0.002, 0.020, 0.55, 0.050, 0.020, 0.007, 0.016)),
  # Custom parameters sent by the theme (registered as custom dimensions in GA4)
  "customEvent:cta_location" = list(
    values = c("header", "hero", "section_services", "cta_band", "platform_links", "footer"),
    w = .norm(c(30, 25, 15, 18, 7, 5))),
  linkText = list(
    values = c("Let's Talk", "Speak to Us", "Our Capabilities", "Explore Our Capabilities",
               "View All Projects", "Send Us a Message", "View Live Platform \u2192"),
    w = .norm(c(30, 18, 14, 12, 10, 9, 7))),
  "customEvent:nav_location" = list(values = c("header", "footer", "quick_links"), w = .norm(c(70, 20, 10))),
  "customEvent:faq_question" = list(
    values = c("What types of organizations do you work with?", "How long does implementation take?",
               "Do you offer training and support?", "Can you work with existing systems?"),
    w = .norm(c(38, 30, 14, 18))),
  "customEvent:architecture_component" = list(
    values = c("Model Analysis", "Feature Store", "CI: Build, Test & Package", "Orchestrated Exp.",
               "Source Repo", "Packages", "Source Code"),
    w = .norm(c(24, 20, 16, 14, 10, 9, 7))),
  "customEvent:app_name" = list(values = c("Commodities for Mobility", "AA Mobility E"), w = .norm(c(65, 35))),
  "customEvent:percent_scrolled" = list(values = c("25", "50", "75", "100"), w = .norm(c(40, 28, 19, 13))),
  "customEvent:form_id" = list(values = "41", w = 1),
  linkUrl = list(
    values = c("", "https://www.linkedin.com/company/atera-analytics",
               "https://github.com/atera-analytics", "https://calendly.com/atera-analytics",
               "mailto:hello@atera-analytics.co.uk"),
    w = .norm(c(80, 8, 5, 4, 3))),
  dayOfWeek = list(values = as.character(0:6), w = .norm(c(0.62, 1.08, 1.16, 1.14, 1.10, 0.98, 0.66))),
  hour = list(values = as.character(0:23),
    w = .norm(c(1, 0.7, 0.5, 0.5, 0.6, 1, 1.8, 3.2, 5.2, 6.4, 6.8, 6.9,
                6.3, 6.4, 6.6, 6.3, 5.8, 5.0, 4.4, 4.0, 3.5, 2.8, 2.0, 1.4)))
)

DEMO_CITY_COUNTRY <- c(London = "United Kingdom", Manchester = "United Kingdom",
  Birmingham = "United Kingdom", Leeds = "United Kingdom", Glasgow = "United Kingdom",
  Bristol = "United Kingdom", Edinburgh = "United Kingdom", "New York" = "United States",
  Berlin = "Germany", Paris = "France", Dublin = "Ireland", Madrid = "Spain")

DEMO_METRICS <- c("sessions", "totalUsers", "activeUsers", "newUsers", "engagedSessions",
                  "engagementRate", "bounceRate", "screenPageViews", "averageSessionDuration",
                  "userEngagementDuration", "eventCount", "keyEvents")

# Daily session volume: gentle growth, weekday pattern, noise, rare spikes/dips.
demo_daily_base <- function(days) {
  dn    <- as.numeric(days)
  wk    <- c(0.62, 1.08, 1.16, 1.14, 1.10, 0.98, 0.66)[as.POSIXlt(days)$wday + 1]
  trend <- pmax(0.3, 1 + 0.0011 * (dn - 20089))
  seas  <- 1 + 0.08 * sin(2 * pi * as.POSIXlt(days)$yday / 365)
  noise <- 0.85 + 0.30 * hnoise(dn)
  spike <- ifelse(hnoise(dn * 1.7 + 3) > 0.985, 1.9,
           ifelse(hnoise(dn * 2.3 + 11) < 0.012, 0.45, 1))
  150 * trend * wk * seas * noise * spike
}

demo_report <- function(dims = character(0), mets, start, end, limit = 10000,
                        order_by = NULL, desc = TRUE) {
  start <- as.Date(start); end <- as.Date(end)
  if (end < start) end <- start
  bad_m <- setdiff(mets, DEMO_METRICS)
  if (length(bad_m)) stop("Demo data has no metric: ", paste(bad_m, collapse = ", "), call. = FALSE)
  other <- setdiff(dims, "date")
  bad_d <- setdiff(other, names(DEMO_DIMS))
  if (length(bad_d)) stop("Demo data has no dimension: ", paste(bad_d, collapse = ", "), call. = FALSE)

  days <- seq(start, end, by = "day")
  dn   <- as.numeric(days)
  base <- demo_daily_base(days)

  # Combinations of the non-date dimensions
  if (length(other)) {
    idx  <- expand.grid(lapply(other, function(d) seq_along(DEMO_DIMS[[d]]$values)),
                        KEEP.OUT.ATTRS = FALSE)
    names(idx) <- other
    w <- rep(1, nrow(idx)); h <- rep(0, nrow(idx))
    grid <- list()
    for (d in other) {
      vals <- DEMO_DIMS[[d]]$values[idx[[d]]]
      w <- w * DEMO_DIMS[[d]]$w[idx[[d]]]
      h <- h + str_hash(vals) + nchar(d)
      grid[[d]] <- vals
    }
  } else {
    w <- 1; h <- 7; grid <- list()
  }
  nc <- length(w)

  if ("date" %in% dims) {
    nd <- length(days)
    di <- rep(seq_len(nd), each = nc); ci <- rep(seq_len(nc), times = nd)
    jit <- if (length(other)) 0.8 + 0.4 * hnoise(dn[di] * 0.37 + h[ci]) else 1
    s   <- base[di] * w[ci] * jit
    day_wobble <- 0.04 * (hnoise(dn[di] * 0.91 + 5) - 0.5)
  } else {
    ci <- seq_len(nc)
    jit <- if (length(other)) 0.92 + 0.16 * hnoise(h + dn[1] * 0.013) else 1
    s   <- sum(base) * w * jit
    day_wobble <- 0.02 * (hnoise(dn[1] * 0.91 + 5) - 0.5)
  }
  hk <- h[ci]
  e1 <- hnoise(hk + 1); e2 <- hnoise(hk + 2); e3 <- hnoise(hk + 3); e4 <- hnoise(hk + 4)
  er <- pmin(0.92, pmax(0.15, 0.48 + 0.28 * e1 + day_wobble))

  m <- list(
    sessions               = round(s),
    totalUsers             = round(s * 0.84),
    activeUsers            = round(s * 0.82),
    newUsers               = round(s * 0.60),
    engagedSessions        = round(s * er),
    engagementRate         = er,
    bounceRate             = 1 - er,
    screenPageViews        = round(s * (1.7 + 1.0 * e2)),
    averageSessionDuration = 45 + 150 * e3,
    userEngagementDuration = round(s * 0.84 * (25 + 80 * e3)),
    eventCount             = round(s * (5.5 + 3 * e2)),
    keyEvents              = round(s * 0.03 * (0.3 + 1.7 * e4))
  )

  # Dimension-specific realism
  if ("eventName" %in% other) {
    ev   <- grid$eventName[ci]
    k    <- match(ev, DEMO_DIMS$eventName$values)
    m$eventCount <- round(s)
    m$totalUsers <- round(s / DEMO_DIMS$eventName$w[k] * DEMO_DIMS$eventName$u[k])
    m$activeUsers <- m$totalUsers
    m$keyEvents  <- ifelse(ev %in% c("generate_lead"), round(s), 0)
  }
  if ("newVsReturning" %in% other) {
    m$newUsers <- ifelse(grid$newVsReturning[ci] == "new", m$totalUsers, 0)
  }
  if ("pagePath" %in% other) m$screenPageViews <- round(s * 2.2)

  out <- list()
  if ("date" %in% dims) out$date <- days[di]
  for (d in other) out[[d]] <- grid[[d]][ci]
  out <- out[dims]                       # keep the requested column order
  for (x in mets) out[[x]] <- m[[x]]
  df <- as.data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)

  if (length(other)) {
    keep <- rowSums(as.matrix(df[mets]) > 0) > 0 & (m$sessions > 0 | m$eventCount > 0)
    # Only combinations that can really happen
    if (all(c("city", "country") %in% other)) {
      keep <- keep & unname(DEMO_CITY_COUNTRY[grid$city[ci]]) == grid$country[ci]
    }
    if (all(c("eventName", "linkUrl") %in% other)) {
      keep <- keep & ((grid$eventName[ci] == "click") == nzchar(grid$linkUrl[ci]))
    }
    df <- df[keep, , drop = FALSE]
  }
  df <- ga_postprocess(df)
  df <- ga_sort(df, dims, mets, order_by, desc)
  utils::head(df, limit)
}

# Simulated "right now" numbers for the Real-time tab in demo mode.
demo_realtime <- function(dims = character(0), mets = "activeUsers") {
  now  <- Sys.time()
  hr   <- as.POSIXlt(now)$hour
  lvl  <- 2 + 14 * DEMO_DIMS$hour$w[hr + 1] / max(DEMO_DIMS$hour$w)
  tick <- floor(as.numeric(now) / 60)
  mk <- function(n_active) {
    v <- list(activeUsers = round(n_active), screenPageViews = round(n_active * 2.4),
              eventCount = round(n_active * 7.5), keyEvents = round(n_active * 0.05))
    v[mets]
  }
  if (length(dims) == 0) {
    return(as.data.frame(mk(lvl * (0.8 + 0.4 * hnoise(tick))), check.names = FALSE))
  }
  d <- dims[1]
  if (d == "minutesAgo") {
    mins <- 0:29
    act  <- lvl * 0.22 * (0.5 + hnoise(tick - mins))
    df <- data.frame(minutesAgo = mins)
  } else {
    key <- switch(d, unifiedScreenName = "pagePath", d)
    if (is.null(DEMO_DIMS[[key]])) stop("Demo data has no real-time dimension: ", d, call. = FALSE)
    vals <- DEMO_DIMS[[key]]$values
    act  <- lvl * DEMO_DIMS[[key]]$w * (0.7 + 0.6 * hnoise(tick + seq_along(vals)))
    df <- data.frame(x = vals, stringsAsFactors = FALSE); names(df) <- d
  }
  vals <- mk(act)
  for (x in names(vals)) df[[x]] <- vals[[x]]
  df <- df[df[[mets[1]]] > 0 | d == "minutesAgo", , drop = FALSE]
  if (d != "minutesAgo") df <- df[order(-df[[mets[1]]]), , drop = FALSE]
  df
}
