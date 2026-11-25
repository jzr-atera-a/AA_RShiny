# core/ga4_api.R - talks to the GA4 Data API directly over HTTPS.
# No googleAnalyticsR needed: fewer moving parts, and Google's own error
# message is passed straight through with a plain-English fix.

GA_SCOPE     <- "https://www.googleapis.com/auth/analytics.readonly"
GA_DATA_URL  <- "https://analyticsdata.googleapis.com/v1beta"
GA_ADMIN_URL <- "https://analyticsadmin.googleapis.com/v1beta"

.ga_cache <- new.env(parent = emptyenv())
.ga_state <- new.env(parent = emptyenv())
.ga_state$quota <- NULL
.ga_state$requests <- 0
GA_CACHE_SECONDS <- 600

ga_cache_clear <- function() rm(list = ls(.ga_cache), envir = .ga_cache)

# ---- Authentication --------------------------------------------------------
ga_read_key <- function(json_path) {
  info <- tryCatch(jsonlite::fromJSON(json_path), error = function(e) NULL)
  if (is.null(info) || !is.list(info)) {
    stop("That file is not valid JSON. Upload the key file exactly as Google gave it to you.", call. = FALSE)
  }
  if (!identical(info$type, "service_account")) {
    stop("This is not a service account key (its type is '", info$type %||% "missing",
         "'). An OAuth client file will not work here. In Google Cloud go to IAM & Admin > ",
         "Service Accounts > your account > Keys > Add key > JSON.", call. = FALSE)
  }
  if (is.null(info$private_key) || is.null(info$client_email)) {
    stop("The key file is missing its private_key or client_email. Download a fresh key.", call. = FALSE)
  }
  info
}

# Access token for a service account key. `subject` = Workspace user to act as
# (domain-wide delegation); leave NULL for the service account itself.
sa_token <- function(json_path, scopes, subject = NULL) {
  tok <- NULL; err <- NULL
  if (requireNamespace("gargle", quietly = TRUE)) {
    tok <- tryCatch(
      gargle::credentials_service_account(scopes = scopes, path = json_path, subject = subject),
      error = function(e) { err <<- conditionMessage(e); NULL })
  }
  if (is.null(tok)) {
    tok <- tryCatch({
      secrets <- jsonlite::fromJSON(json_path)
      httr::oauth_service_token(httr::oauth_endpoints("google"), secrets, scope = scopes, sub = subject)
    }, error = function(e) { err <<- conditionMessage(e); NULL })
  }
  if (is.null(tok)) {
    stop("Google would not issue an access token for this key",
         if (!is.null(err)) paste0(" (", err, ")") else "",
         if (!is.null(subject)) paste0(". Acting as ", subject, " needs domain-wide delegation for this ",
                                       "service account's client ID in the Google Workspace admin console")
         else paste0(". The key may have been deleted or disabled in Google Cloud, or this computer's ",
                     "clock is wrong. Create a new key and try again"),
         ".", call. = FALSE)
  }
  tok
}

ga_make_token <- function(json_path) sa_token(json_path, GA_SCOPE)

ga_connect <- function(json_path) {
  info <- ga_read_key(json_path)
  list(token = ga_make_token(json_path), email = info$client_email,
       project = info$project_id %||% "", key_path = json_path)
}

# ---- Low-level request + error translation ---------------------------------
ga_explain_error <- function(status, parsed, raw, email = NULL) {
  msg <- NULL
  if (is.list(parsed) && is.list(parsed$error)) msg <- parsed$error$message
  if (is.null(msg)) msg <- substr(raw %||% "", 1, 300)
  who <- if (!is.null(email)) paste0(" (", email, ")") else ""
  hint <- if (grepl("has not been used in project|is disabled|SERVICE_DISABLED", msg)) {
    paste0("An API is switched off in your Google Cloud project. In Cloud Console > APIs & Services > ",
           "Library, enable 'Google Analytics Data API' (and 'Google Analytics Admin API' for the ",
           "property list), wait a minute, then retry.")
  } else if (status == 403) {
    paste0("The service account", who, " cannot read this property. In Google Analytics go to Admin > ",
           "Property access management, add that email as Viewer, and check the Property ID is right.")
  } else if (status == 404) {
    "That Property ID does not exist. Use the numeric ID from Admin > Property details (not the G- Measurement ID)."
  } else if (status == 429) {
    "The property's API quota is used up for now. Wait for the next hour/day or load fewer tabs."
  } else if (status == 401) {
    "The key was rejected. It may have been deleted in Google Cloud - create a new JSON key."
  } else if (status == 400) {
    "Google rejected the request: usually a wrong Property ID, or a dimension/metric pair GA4 does not allow together."
  } else ""
  paste0("GA4 API error ", status, ": ", msg, if (nzchar(hint)) paste0("\nFix: ", hint) else "")
}

ga_http <- function(conn, url, body = NULL) {
  auth <- httr::config(token = conn$token)
  resp <- tryCatch({
    if (is.null(body)) {
      httr::GET(url, auth, httr::timeout(60))
    } else {
      httr::POST(url, auth, httr::timeout(60), httr::content_type_json(),
                 body = jsonlite::toJSON(body, auto_unbox = TRUE, null = "null"))
    }
  }, error = function(e) {
    stop("Could not reach Google (", conditionMessage(e), "). Check the internet connection.", call. = FALSE)
  })
  .ga_state$requests <- .ga_state$requests + 1
  raw    <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- tryCatch(jsonlite::fromJSON(raw, simplifyVector = FALSE), error = function(e) NULL)
  status <- httr::status_code(resp)
  if (status >= 400) stop(ga_explain_error(status, parsed, raw, conn$email), call. = FALSE)
  parsed %||% list()
}

# ---- Response handling -----------------------------------------------------
ga_parse_report <- function(res) {
  dim_names <- vapply(res$dimensionHeaders %||% list(), function(h) h$name, character(1))
  met_names <- vapply(res$metricHeaders %||% list(), function(h) h$name, character(1))
  rows <- res$rows %||% list()
  out <- list()
  for (i in seq_along(dim_names)) {
    out[[dim_names[i]]] <- vapply(rows, function(r) {
      as.character(r$dimensionValues[[i]]$value %||% NA_character_)
    }, character(1))
  }
  for (j in seq_along(met_names)) {
    out[[met_names[j]]] <- suppressWarnings(as.numeric(vapply(rows, function(r) {
      as.character(r$metricValues[[j]]$value %||% NA_character_)
    }, character(1))))
  }
  as.data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
}

# Give special dimensions proper R types.
ga_postprocess <- function(df) {
  if (!is.null(df$date) && is.character(df$date)) {
    df$date <- as.Date(df$date, format = "%Y%m%d")
  }
  for (col in c("hour", "dayOfWeek", "minutesAgo")) {
    if (!is.null(df[[col]])) df[[col]] <- suppressWarnings(as.integer(df[[col]]))
  }
  df
}

ga_sort <- function(df, dims, mets, order_by = NULL, desc = TRUE) {
  if (nrow(df) < 2) return(df)
  key <- if (!is.null(order_by) && order_by %in% names(df)) order_by
         else if ("date" %in% dims) "date" else mets[1]
  decreasing <- if (key == "date" && is.null(order_by)) FALSE else desc
  df <- df[order(df[[key]], decreasing = decreasing), , drop = FALSE]
  rownames(df) <- NULL
  df
}

# ---- Reports ---------------------------------------------------------------
# filter = list(field = "pagePath", match = "CONTAINS", value = "contact")
ga_run_report <- function(conn, property_id, dims = character(0), mets, start, end,
                          limit = 10000, order_by = NULL, desc = TRUE, filter = NULL,
                          use_cache = TRUE) {
  body <- list(
    dateRanges = list(list(startDate = format(as.Date(start)), endDate = format(as.Date(end)))),
    dimensions = lapply(dims, function(d) list(name = d)),
    metrics    = lapply(mets, function(x) list(name = x)),
    limit      = as.character(as.integer(limit)),
    returnPropertyQuota = TRUE
  )
  ord <- if (!is.null(order_by)) order_by else if ("date" %in% dims) "date" else mets[1]
  body$orderBys <- list(
    if (ord %in% dims) list(dimension = list(dimensionName = ord),
                            desc = if (ord == "date" && is.null(order_by)) FALSE else desc)
    else list(metric = list(metricName = ord), desc = desc)
  )
  if (!is.null(filter) && nzchar(filter$value %||% "")) {
    body$dimensionFilter <- list(filter = list(
      fieldName = filter$field,
      stringFilter = list(matchType = filter$match %||% "CONTAINS",
                          value = filter$value, caseSensitive = FALSE)))
  }
  key <- paste(property_id, jsonlite::toJSON(body, auto_unbox = TRUE), sep = "|")
  if (use_cache) {
    hit <- .ga_cache[[key]]
    if (!is.null(hit) && difftime(Sys.time(), hit$at, units = "secs") < GA_CACHE_SECONDS) return(hit$df)
  }
  t0  <- Sys.time()
  res <- ga_http(conn, sprintf("%s/properties/%s:runReport", GA_DATA_URL, property_id), body)
  if (!is.null(res$propertyQuota)) .ga_state$quota <- res$propertyQuota
  df <- ga_sort(ga_postprocess(ga_parse_report(res)), dims, mets, order_by, desc)
  cat(sprintf("[GA4] %s | %s | %s to %s -> %d rows (%.1fs)\n",
              if (length(dims)) paste(dims, collapse = "+") else "(totals)",
              paste(mets, collapse = ","), format(as.Date(start)), format(as.Date(end)),
              nrow(df), as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  .ga_cache[[key]] <- list(df = df, at = Sys.time())
  df
}

ga_run_realtime <- function(conn, property_id, dims = character(0), mets = "activeUsers", limit = 50) {
  body <- list(
    dimensions = lapply(dims, function(d) list(name = d)),
    metrics    = lapply(mets, function(x) list(name = x)),
    limit      = as.character(as.integer(limit))
  )
  res <- ga_http(conn, sprintf("%s/properties/%s:runRealtimeReport", GA_DATA_URL, property_id), body)
  df  <- ga_postprocess(ga_parse_report(res))
  if (nrow(df) > 1 && !("minutesAgo" %in% dims)) df <- df[order(-df[[mets[1]]]), , drop = FALSE]
  df
}

# Properties this service account can see (needs the Admin API enabled).
ga_list_properties <- function(conn) {
  res <- ga_http(conn, paste0(GA_ADMIN_URL, "/accountSummaries?pageSize=200"))
  out <- data.frame(account = character(0), property = character(0),
                    property_id = character(0), stringsAsFactors = FALSE)
  for (a in res$accountSummaries %||% list()) {
    for (p in a$propertySummaries %||% list()) {
      out[nrow(out) + 1, ] <- list(a$displayName %||% "", p$displayName %||% "",
                                   sub("^properties/", "", p$property %||% ""))
    }
  }
  out
}

# Every dimension and metric the property supports (for the Data Explorer).
ga_metadata <- function(conn, property_id) {
  res <- ga_http(conn, sprintf("%s/properties/%s/metadata", GA_DATA_URL, property_id))
  tidy <- function(items) {
    items <- items %||% list()
    data.frame(
      apiName  = vapply(items, function(x) x$apiName %||% "", character(1)),
      uiName   = vapply(items, function(x) x$uiName %||% (x$apiName %||% ""), character(1)),
      category = vapply(items, function(x) x$category %||% "Other", character(1)),
      stringsAsFactors = FALSE)
  }
  list(dimensions = tidy(res$dimensions), metrics = tidy(res$metrics))
}

# ---- One entry point used by every tab -------------------------------------
# src = list(mode = "demo" | "live", conn = <connection>, property_id = "123")
ga_query <- function(src, dims = character(0), mets, start, end, limit = 10000,
                     order_by = NULL, desc = TRUE, filter = NULL) {
  if (identical(src$mode, "live")) {
    return(ga_run_report(src$conn, src$property_id, dims, mets, start, end,
                         limit, order_by, desc, filter))
  }
  if (!is.null(filter) && nzchar(filter$value %||% "")) {
    if (!(filter$field %in% dims)) {
      stop("In demo mode, add '", filter$field, "' as a dimension to filter on it.", call. = FALSE)
    }
    df <- demo_report(dims, mets, start, end, limit = 1e6, order_by, desc)
    hay <- tolower(as.character(df[[filter$field]])); needle <- tolower(filter$value)
    keep <- if (identical(filter$match, "EXACT")) hay == needle else grepl(needle, hay, fixed = TRUE)
    return(utils::head(df[keep, , drop = FALSE], limit))
  }
  demo_report(dims, mets, start, end, limit, order_by, desc)
}

ga_realtime <- function(src, dims = character(0), mets = "activeUsers") {
  if (identical(src$mode, "live")) ga_run_realtime(src$conn, src$property_id, dims, mets)
  else demo_realtime(dims, mets)
}

# ---- Property set-up (needs the edit scope; service account must be Editor/Administrator) ----
GA_EDIT_SCOPE <- "https://www.googleapis.com/auth/analytics.edit"

# Event parameters sent by the Atera WordPress theme (v5.3+) that need a custom dimension.
THEME_CUSTOM_DIMS <- data.frame(
  parameter = c("cta_location", "nav_location", "form_id", "faq_question",
                "architecture_component", "app_name", "percent_scrolled"),
  display   = c("CTA location", "Navigation location", "Form ID", "FAQ question",
                "Architecture component", "Live platform", "Scroll depth (%)"),
  description = c("Where on the page a call-to-action was clicked", "Header, footer or quick links",
                  "WPForms form ID", "FAQ question that was opened", "MLOps diagram box that was opened",
                  "Live analytics platform opened (shinyapps.io)", "Scroll depth reached: 25/50/75/100"),
  stringsAsFactors = FALSE)
THEME_KEY_EVENTS <- c("generate_lead")

ga_edit_conn <- function(conn) {
  if (is.null(conn$key_path)) stop("The key file is needed to request edit access. Reconnect in API Configuration > Google Analytics.", call. = FALSE)
  c2 <- conn
  c2$token <- sa_token(conn$key_path, GA_EDIT_SCOPE)
  c2
}

ga_list_custom_dims <- function(conn, property_id) {
  res <- ga_http(conn, sprintf("%s/properties/%s/customDimensions?pageSize=200", GA_ADMIN_URL, property_id))
  vapply(res$customDimensions %||% list(), function(x) x$parameterName %||% "", character(1))
}

ga_list_key_events <- function(conn, property_id) {
  res <- ga_http(conn, sprintf("%s/properties/%s/keyEvents?pageSize=200", GA_ADMIN_URL, property_id))
  vapply(res$keyEvents %||% list(), function(x) x$eventName %||% "", character(1))
}

# Creates whatever is missing. Returns a data frame describing each item.
ga_setup_theme_tracking <- function(conn, property_id) {
  ce <- ga_edit_conn(conn)
  have_dims <- ga_list_custom_dims(ce, property_id)
  out <- data.frame(item = character(0), status = character(0), stringsAsFactors = FALSE)
  for (i in seq_len(nrow(THEME_CUSTOM_DIMS))) {
    d <- THEME_CUSTOM_DIMS[i, ]
    status <- if (d$parameter %in% have_dims) "already registered" else tryCatch({
      ga_http(ce, sprintf("%s/properties/%s/customDimensions", GA_ADMIN_URL, property_id),
              list(parameterName = d$parameter, displayName = d$display,
                   description = d$description, scope = "EVENT"))
      "created"
    }, error = function(e) paste("failed:", conditionMessage(e)))
    out[nrow(out) + 1, ] <- list(paste0("Custom dimension: ", d$display, " (", d$parameter, ")"), status)
  }
  have_keys <- tryCatch(ga_list_key_events(ce, property_id), error = function(e) character(0))
  for (k in THEME_KEY_EVENTS) {
    status <- if (k %in% have_keys) "already a key event" else tryCatch({
      ga_http(ce, sprintf("%s/properties/%s/keyEvents", GA_ADMIN_URL, property_id),
              list(eventName = k, countingMethod = "ONCE_PER_EVENT"))
      "marked as key event"
    }, error = function(e) paste("failed:", conditionMessage(e)))
    out[nrow(out) + 1, ] <- list(paste0("Key event: ", k), status)
  }
  ga_cache_clear()
  out
}
