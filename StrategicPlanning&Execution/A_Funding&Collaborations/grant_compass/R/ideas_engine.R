# ---- Idea generation: template engine (always works) + optional AI via API ----------

TEMPLATES <- list(
  batteries = list(
    c("Open interface profile for {g}", "Draft a minimal, vendor-neutral interface profile (electrical, thermal, data) that two suppliers could implement and test against within 3 months."),
    c("Duty-cycle benchmark pack for {g}", "Publish a small open benchmark of real duty cycles so cell and pack claims can be compared like-for-like.")),
  standards = list(
    c("Standards gap map for {g}", "Map which existing standards already cover the topic, where they conflict, and which gap is cheapest to close first."),
    c("Conformance checklist for {g}", "A one-page, testable checklist that buyers can attach to procurement and that suppliers can self-assess against.")),
  defence = list(
    c("Dual-use route-to-market for {g}", "Identify one civil and one defence buyer, and design the smallest pilot that proves the same product serves both.")),
  drones = list(
    c("Drone energy-use benchmark for {g}", "Use flight telemetry to build a repeatable energy-per-mission benchmark and a payload/endurance trade-off tool.")),
  ev = list(
    c("EV charging data insights for {g}", "Combine charge-point and vehicle sensor data to quantify cost and carbon savings from smarter charging.")),
  mobility = list(
    c("Fleet optimisation pilot for {g}", "Run an optimisation pilot on a partner fleet and report running-cost change against a fuel-based baseline.")),
  energy = list(
    c("Energy digital-twin for {g}", "Model demand, storage and generation for one site, then test three operating strategies before any hardware spend.")),
  `digital-twin` = list(
    c("Lightweight digital twin for {g}", "Stand up a twin from open and partner data in weeks, with a clear validation plan against measured performance.")),
  ai = list(
    c("Explainable AI assistant for {g}", "A decision-support tool that ranks options and shows why, with human sign-off kept in the loop.")),
  geospatial = list(
    c("Geospatial evidence layer for {g}", "Create a map-based evidence layer (coverage, constraints, opportunity) that partners can reuse across bids.")),
  `net-zero` = list(
    c("Net-zero impact calculator for {g}", "Quantify avoided emissions with a transparent method that funders and auditors can reproduce.")),
  data = list(
    c("Shared data model for {g}", "Agree a common data dictionary and sharing agreement so partners can pool data without exposing sensitive fields.")),
  manufacturing = list(
    c("Scale-up readiness review for {g}", "Assess yield, supply chain and test capacity so the first pilot line decisions are evidence-based.")),
  innovation = list(
    c("Fast-follow concept for {g}", "A 6-week concept test with 3 target users, ending in a go/no-go and a costed Phase 2 outline."))
)

GENERIC_TEMPLATE <- list(c("Partnership concept for {g}", "Pair our strongest capability with one complementary partner and define a small, measurable pilot."))

short_title <- function(x) {
  x <- sub("\\s*\\(check latest\\)", "", as.character(x))
  x[is.na(x)] <- ""
  ifelse(nchar(x) > 48, paste0(substr(x, 1, 45), "..."), x)
}

gen_ideas_rule <- function(grants, interests = character(), extra = character(), n_max = 8) {
  out <- list()
  kw <- tolower(c(interests, extra))
  for (i in seq_len(nrow(grants))) {
    g <- grants[i, ]
    themes <- tolower(split_tags(g$themes))
    # themes the user cares about come first
    themes <- c(intersect(themes, kw), setdiff(themes, kw))
    picked <- 0
    for (th in themes) {
      tpl <- TEMPLATES[[th]]
      if (is.null(tpl)) next
      for (t in tpl) {
        out[[length(out) + 1]] <- data.frame(
          title = gsub("\\{g\\}", short_title(g$title), t[1]),
          pitch = t[2], linked_grants = g$grant_id,
          themes = paste(head(themes, 3), collapse = "; "), origin = "template", stringsAsFactors = FALSE)
        picked <- picked + 1
        if (picked >= 2) break
      }
      if (picked >= 2) break
    }
    if (picked == 0) {
      t <- GENERIC_TEMPLATE[[1]]
      out[[length(out) + 1]] <- data.frame(
        title = gsub("\\{g\\}", short_title(g$title), t[1]), pitch = t[2], linked_grants = g$grant_id,
        themes = paste(head(themes, 3), collapse = "; "), origin = "template", stringsAsFactors = FALSE)
    }
  }
  # cross-grant idea if two or more grants share a theme
  if (nrow(grants) >= 2) {
    th <- table(unlist(lapply(grants$themes, split_tags)))
    th <- names(th[th >= 2])
    if (length(th) > 0) {
      out[[length(out) + 1]] <- data.frame(
        title = paste0("One consortium, two bids: ", th[1]),
        pitch = paste0("Several of the selected grants share the '", th[1],
                       "' theme. Build one reusable evidence pack and partner list, then tailor it to each call."),
        linked_grants = paste(grants$grant_id, collapse = "; "), themes = th[1], origin = "template",
        stringsAsFactors = FALSE)
    }
  }
  res <- if (length(out)) do.call(rbind, out) else data.frame()
  head(res, n_max)
}

gen_ideas_ai <- function(grants, interests, extra, api_key, model, n = 6) {
  stopifnot(nzchar(api_key))
  gtxt <- paste0("- [", grants$grant_id, "] ", grants$title, " (", grants$funder, "; themes: ", grants$themes, "). ", grants$summary,
                 collapse = "\n")
  prompt <- paste0(
    "You help a small UK analytics team decide which grants to pursue.\n",
    "Team interests: ", paste(interests, collapse = ", "), "\nExtra keywords: ", paste(extra, collapse = ", "), "\n",
    "Grants they scored highest:\n", gtxt, "\n\n",
    "Propose ", n, " concrete project ideas. Return ONLY a JSON array of objects with keys ",
    "title, pitch (max 40 words), linked_grants (array of grant ids from the list), themes (array of short lowercase tags). ",
    "Do not invent funding amounts or deadlines.")
  resp <- httr2::request("https://api.anthropic.com/v1/messages") |>
    httr2::req_headers(`x-api-key` = api_key, `anthropic-version` = "2023-06-01", `content-type` = "application/json") |>
    httr2::req_body_json(list(model = model, max_tokens = 1500,
                              messages = list(list(role = "user", content = prompt)))) |>
    httr2::req_timeout(60) |>
    httr2::req_perform()
  txt <- httr2::resp_body_json(resp)$content[[1]]$text
  js  <- sub("^[^\\[]*", "", txt); js <- sub("[^\\]]*$", "", js)
  df  <- jsonlite::fromJSON(js, simplifyDataFrame = TRUE)
  data.frame(
    title = df$title, pitch = df$pitch,
    linked_grants = vapply(df$linked_grants, function(x) paste(x, collapse = "; "), ""),
    themes = vapply(df$themes, function(x) paste(x, collapse = "; "), ""),
    origin = "ai", stringsAsFactors = FALSE)
}

api_ping <- function(api_key, model) {
  tryCatch({
    httr2::request("https://api.anthropic.com/v1/messages") |>
      httr2::req_headers(`x-api-key` = api_key, `anthropic-version` = "2023-06-01", `content-type` = "application/json") |>
      httr2::req_body_json(list(model = model, max_tokens = 8, messages = list(list(role = "user", content = "ping")))) |>
      httr2::req_timeout(20) |> httr2::req_perform()
    "OK - the API key works."
  }, error = function(e) paste("Failed:", conditionMessage(e)))
}

# ---- grant scraper for the Admin tab -------------------------------------------------
scrape_links <- function(url, selector = "a") {
  page <- rvest::read_html(httr2::request(url) |> httr2::req_user_agent("GrantCompass/1.0") |>
                             httr2::req_timeout(30) |> httr2::req_perform() |> httr2::resp_body_string())
  nodes <- rvest::html_elements(page, selector)
  txt  <- trimws(gsub("\\s+", " ", rvest::html_text2(nodes)))
  href <- rvest::html_attr(nodes, "href")
  keep <- nzchar(txt) & nchar(txt) >= 20 & !is.na(href)
  df <- data.frame(title = txt[keep], url = xml2::url_absolute(href[keep], url), stringsAsFactors = FALSE)
  df[!duplicated(df$url), , drop = FALSE]
}
