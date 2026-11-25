# R/programmes.R - one programme record, built from any of the older apps' columns
#
#   Funding Programmes (BigQuery funding_programmes)   ->  programmes
#     amount_of_money -> amount_text, areas_of_application -> themes,
#     start_date_for_applying -> opens_date (when a date), deadline -> closes_date (when a date)
#     or deadline_text, recommendations_for_applying -> recommendations, key_sponsors -> funder
#   Grant Compass (Grants tab)                         ->  programmes
#     title -> programme_name, closes -> closes_date, url -> source_url and verified_urls,
#     min_gbp / max_gbp kept, amount_text built from them

iso_date_or_blank <- function(x) {
  x <- trimws(as.character(x))
  ok <- grepl("^\\d{4}-\\d{2}-\\d{2}", x)
  out <- ifelse(ok, substr(x, 1, 10), "")
  out[is.na(out)] <- ""
  out
}

col_or <- function(df, ..., default = "") {
  for (n in c(...)) if (n %in% names(df)) { v <- as.character(df[[n]]); v[is.na(v)] <- ""; return(v) }
  rep(default, nrow(df))
}

map_programme_columns <- function(raw, source = "import") {
  names(raw) <- tolower(trimws(names(raw)))
  n <- nrow(raw)
  if (!n) return(empty_table("programmes"))
  deadline_raw <- col_or(raw, "deadline", "deadline_text", "closes")
  closes <- col_or(raw, "closes_date")
  closes[!nzchar(closes)] <- iso_date_or_blank(deadline_raw)[!nzchar(closes)]
  opens <- col_or(raw, "opens_date")
  opens[!nzchar(opens)] <- iso_date_or_blank(col_or(raw, "start_date_for_applying"))[!nzchar(opens)]
  min_g <- col_or(raw, "min_gbp"); max_g <- col_or(raw, "max_gbp")
  amount <- col_or(raw, "amount_text", "amount_of_money", "amount")
  built <- ifelse(nzchar(max_g), paste0("GBP ", ifelse(nzchar(min_g), paste0(min_g, " to "), "up to "), max_g), "")
  amount[!nzchar(amount)] <- built[!nzchar(amount)]
  url <- col_or(raw, "verified_urls", "url", "source_url")
  funder <- col_or(raw, "funder")
  sponsors <- col_or(raw, "key_sponsors")
  funder[!nzchar(funder)] <- sponsors[!nzchar(funder)]
  stage <- col_or(raw, "stage")
  stage[!stage %in% STAGES] <- "Discover"
  deadline_text <- ifelse(nzchar(iso_date_or_blank(deadline_raw)), "", deadline_raw)
  df <- data.frame(
    programme_id = vapply(seq_len(n), function(i) new_id("prog"), ""),
    programme_name = col_or(raw, "programme_name", "title", "name"),
    funder = funder,
    category = col_or(raw, "category", default = "Grant"),
    country = col_or(raw, "country"),
    city_region = col_or(raw, "city_region", default = "All"),
    summary = col_or(raw, "summary"),
    themes = col_or(raw, "themes", "areas_of_application"),
    conditions = col_or(raw, "conditions"),
    key_sponsors = sponsors,
    key_organiser_profiles = col_or(raw, "key_organiser_profiles"),
    amount_text = amount, min_gbp = min_g, max_gbp = max_g,
    funding_rate_pct = col_or(raw, "funding_rate_pct"),
    opens_date = opens, closes_date = closes, deadline_text = deadline_text,
    rolling = ifelse(grepl("rolling", tolower(deadline_raw)), "TRUE", col_or(raw, "rolling", default = "FALSE")),
    recommendations = col_or(raw, "recommendations", "recommendations_for_applying"),
    verified_urls = url, source_url = col_or(raw, "source_url", "url"),
    verified_at = col_or(raw, "verified_at"), verified_by = col_or(raw, "verified_by"),
    stage = stage, owner = col_or(raw, "owner"),
    source = source, is_example = col_or(raw, "is_example", default = "FALSE"),
    added_by = col_or(raw, "added_by"), added_at = col_or(raw, "added_at", "created_at", default = now_ts()),
    updated_at = now_ts(), stringsAsFactors = FALSE)
  df[nzchar(trimws(df$programme_name)), , drop = FALSE]
}

programme_key <- function(df) tolower(gsub("[^a-z0-9]+", "", tolower(paste(df$funder, df$programme_name))))

# Add programmes, skipping any whose funder + name is already in the list
add_programmes <- function(df, user) {
  if (!nrow(df)) return(list(added = 0, skipped = 0))
  have <- programme_key(store_read("programmes", fresh = TRUE))
  k <- programme_key(df)
  new <- df[!(k %in% have) & !duplicated(k), , drop = FALSE]
  if (nrow(new)) {
    new$added_by[!nzchar(new$added_by)] <- user
    store_append("programmes", new, user = user)
  }
  list(added = nrow(new), skipped = nrow(df) - nrow(new))
}

# ---- bracket-tag text (Funding Programmes / BOS format), used by Live search and Bulk import ----------
# Ported from BOS R/api_manager.R parse_programme_text(), with three more tags for sources:
# [source_url] (the page the programme was found on), [amount_source_url], [dates_source_url].
PROGRAMME_TAGS <- c("programme_name", "funder", "category", "country", "city_region", "amount_of_money", "conditions",
                    "key_sponsors", "key_organiser_profiles", "areas_of_application", "start_date_for_applying",
                    "deadline", "recommendations_for_applying", "verified_urls", "summary", "funding_rate_pct",
                    "source_url", "amount_source_url", "dates_source_url")

parse_programme_text <- function(text) {
  lines <- strsplit(gsub("\r", "", text %||% ""), "\n")[[1]]
  entries <- list(); cur <- list(); last <- NULL
  flush <- function() if (length(cur) && !is.null(cur$programme_name)) entries[[length(entries) + 1]] <<- cur
  pat_any <- paste0("^\\s*\\**\\[(", paste(PROGRAMME_TAGS, collapse = "|"), ")\\]\\**:\\s*(.*)$")
  for (line in lines) {
    line <- trimws(line); if (!nzchar(line)) next
    m <- regmatches(line, regexec(pat_any, line, ignore.case = TRUE))[[1]]
    if (length(m) == 3) {
      f <- tolower(m[2]); v <- trimws(m[3])
      if (f == "programme_name") { flush(); cur <- list() }
      cur[[f]] <- v; last <- f
    } else if (length(cur) && !is.null(last) && !grepl("^\\[", line)) cur[[last]] <- paste(cur[[last]], line)
  }
  flush()
  if (!length(entries)) stop("No programmes found. Each one must start with a line like [programme_name]: ...")
  g <- function(e, f) { v <- e[[f]] %||% ""; if (grepl("^not confirmed|^unknown|^n/?a$", v, ignore.case = TRUE)) "" else v }
  do.call(rbind, lapply(entries, function(e) {
    urls <- unlist(strsplit(paste(g(e, "verified_urls"), g(e, "source_url"), g(e, "amount_source_url"), g(e, "dates_source_url")), "[,; ]+"))
    urls <- unique(urls[grepl("^https?://", urls)])
    data.frame(programme_name = e$programme_name, funder = g(e, "funder"), category = g(e, "category"),
               country = g(e, "country"), city_region = g(e, "city_region") %|% "All",
               amount_of_money = e$amount_of_money %||% "", conditions = g(e, "conditions"),
               key_sponsors = g(e, "key_sponsors"), key_organiser_profiles = g(e, "key_organiser_profiles"),
               areas_of_application = g(e, "areas_of_application"), start_date_for_applying = g(e, "start_date_for_applying"),
               deadline = e$deadline %||% "", recommendations_for_applying = g(e, "recommendations_for_applying"),
               summary = g(e, "summary"), funding_rate_pct = gsub("[^0-9.]", "", g(e, "funding_rate_pct")),
               verified_urls = paste(urls, collapse = ", "),
               source_url = { s <- g(e, "source_url"); if (grepl("^https?://", s)) s else (urls[1] %||% "") },
               amount_source_url = g(e, "amount_source_url"), dates_source_url = g(e, "dates_source_url"),
               stringsAsFactors = FALSE)
  }))
}

# Amounts like "Up to GBP 500,000" or "£25k - £100k" -> min/max in GBP (only when the currency is GBP or £)
parse_gbp_range <- function(x) {
  x <- tolower(x %||% "")
  if (!grepl("gbp|£|pound", x)) return(c("", ""))
  nums <- regmatches(x, gregexpr("[0-9][0-9,.]*\\s*(k|m|million|thousand)?", x))[[1]]
  v <- vapply(nums, function(n) {
    b <- suppressWarnings(as.numeric(gsub("[^0-9.]", "", n)))
    if (grepl("m|million", n)) b * 1e6 else if (grepl("k|thousand", n)) b * 1e3 else b
  }, 1)
  v <- v[!is.na(v) & v >= 100]
  if (!length(v)) return(c("", ""))
  if (length(v) == 1) return(c("", format(v, scientific = FALSE)))
  c(format(min(v), scientific = FALSE), format(max(v), scientific = FALSE))
}

# Parsed text -> programme records ready for add_programmes()
programmes_from_parsed <- function(parsed, source, verified_by = "") {
  df <- map_programme_columns(parsed, source = source)
  for (i in seq_len(nrow(df))) {
    r <- parse_gbp_range(df$amount_text[i])
    if (!nzchar(df$min_gbp[i])) df$min_gbp[i] <- r[1]
    if (!nzchar(df$max_gbp[i])) df$max_gbp[i] <- r[2]
    if (!nzchar(df$funder[i])) df$funder[i] <- df$key_sponsors[i]
  }
  has_src <- grepl("^https?://", df$source_url)
  if (nzchar(verified_by)) { df$verified_at <- ifelse(has_src, now_ts(), ""); df$verified_by <- ifelse(has_src, verified_by, "") }
  df
}

programme_search_prompt <- function(category, country, region, focus, n) {
  where <- if (identical(region, "All") || !nzchar(trimws(region))) country else paste0(region, ", ", country)
  paste0(
    "You are a research assistant for business funding programmes. Use web search to find up to ", n, " ",
    category, " programmes for organisations in ", where, " that are open now or open again soon.\n",
    "Focus: ", if (nzchar(trimws(focus))) focus else "none given; choose the most relevant current programmes.", "\n\n",
    "RULES\n",
    "- Only include a programme that you found on a live web page during this search. Never add one from memory.\n",
    "- Give the URL of the page you found each programme on, and the URL of the page that states its amount and its dates.\n",
    "- If a date or amount is not stated on a page you found, write 'Not confirmed' for it. Do not guess.\n",
    "- Dates as YYYY-MM-DD when the page gives a date.\n\n",
    "For EACH programme output exactly these lines (no markdown, no other words), with a blank line between programmes:\n",
    "[programme_name]: official name\n[funder]: organisation that pays\n[category]: ", category, "\n",
    "[country]: ", country, "\n[city_region]: ", region, "\n",
    "[amount_of_money]: amount or range with currency\n[funding_rate_pct]: share of costs funded, number only, if stated\n",
    "[conditions]: eligibility conditions, separated by semicolons\n[key_sponsors]: sponsors or partners\n",
    "[key_organiser_profiles]: people or teams who run it, if named\n[areas_of_application]: sectors and themes, separated by semicolons\n",
    "[summary]: two plain sentences on what it funds\n[start_date_for_applying]: opening date\n",
    "[deadline]: closing date, or 'Rolling'\n[recommendations_for_applying]: practical tips from the funder's guidance\n",
    "[source_url]: page where you found this programme\n[amount_source_url]: page that states the amount\n",
    "[dates_source_url]: page that states the dates\n[verified_urls]: any other official pages, comma-separated\n")
}
