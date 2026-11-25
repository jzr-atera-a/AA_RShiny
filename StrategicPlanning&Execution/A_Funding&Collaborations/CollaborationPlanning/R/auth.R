# R/auth.R - sign-in (VentureDeals style) and the Admin code lock
#
# Sign-in: the email must be in the "allowed_emails" tab of the Google Sheet (local CSV when the
# Sheet is not set up) and active. Five wrong attempts lock the form for five minutes.
# Every attempt, good or bad, is written to "login_log".
# Note: this is an approved-email list, not a password. On shinyapps.io you can also turn on the
# host's own authentication for stronger protection.
#
# Admin lock: admins see the Admin group, but opening it asks for the admin code (CP_ADMIN_CODE,
# default 7818) unless the app is running on Windows (your own computer).

login_ui <- function(error = NULL, locked = FALSE, attempts_left = cfg$max_attempts) {
  div(class = "gate",
    div(class = "gate-card",
      tags$img(src = "mark.png", class = "gate-logo", alt = ""),
      div(class = "eyebrow", "Restricted access"),
      h2(class = "gate-title", APP_NAME),
      p(class = "muted", APP_TAGLINE, tags$br(), "Enter your approved email address to continue."),
      textInput("login_email", NULL, placeholder = "you@company.com", width = "100%"),
      actionButton("login_submit", "Sign in", class = "btn-brand", icon = icon("right-to-bracket")),
      if (locked) note("bad", icon("lock"), " Too many attempts. Try again in 5 minutes.")
      else if (!is.null(error)) note("bad", error,
                                     if (attempts_left < cfg$max_attempts) span(class = "small muted", sprintf(" (%d attempt(s) left)", attempts_left))),
      p(class = "small muted mt", "Not on the list? Ask an administrator to add your email."),
      tags$script(HTML("$(document).on('keyup', '#login_email', function(e){ if(e.key === 'Enter'){ $('#login_submit').click(); } });"))))
}

auth_server <- function(input, output, session) {
  st <- reactiveValues(authed = FALSE, email = NULL, name = NULL, role = NULL, attempts = 0,
                       locked_until = NULL, error = NULL,
                       session_id = paste0("s_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample(1000:9999, 1)))

  log_login <- function(email, success, detail = "") {
    tryCatch(store_append("login_log", data.frame(timestamp = now_ts(), email = email, success = as.character(success),
                                                  session_id = st$session_id, detail = detail, stringsAsFactors = FALSE),
                          user = email, log = FALSE),
             error = function(e) log_debug("[Auth] could not log sign-in: ", safe_error_text(e)))
  }

  observeEvent(input$login_submit, {
    if (!is.null(st$locked_until) && Sys.time() < st$locked_until) {
      st$error <- paste("Locked until", format(st$locked_until, "%H:%M:%S")); return()
    }
    if (!is.null(st$locked_until)) { st$locked_until <- NULL; st$attempts <- 0 }
    email <- tolower(trimws(input$login_email %||% ""))
    if (!nzchar(email) || !grepl("@", email)) { st$error <- "Please enter a valid email address."; return() }
    rec <- user_record(email)
    if (!is.null(rec) || email %in% cfg$admin_emails) {
      st$authed <- TRUE; st$email <- email
      st$name <- if (!is.null(rec) && nzchar(rec$name)) rec$name else sub("@.*", "", email)
      st$role <- if (is_admin_email(email)) "admin" else (if (!is.null(rec) && nzchar(rec$role)) rec$role else "member")
      st$error <- NULL
      log_login(email, TRUE, st$role)
      log_debug("[Auth] signed in: ", email, " (", st$role, ")")
    } else {
      st$attempts <- st$attempts + 1
      st$error <- "This email is not on the approved list."
      log_login(email, FALSE, "not approved")
      log_debug("[Auth] denied: ", email, " (", st$attempts, "/", cfg$max_attempts, ")")
      if (st$attempts >= cfg$max_attempts) st$locked_until <- Sys.time() + cfg$lockout_secs
    }
  })

  sign_out <- function() {
    st$authed <- FALSE; st$email <- NULL; st$role <- NULL; st$name <- NULL
  }

  list(
    state = st,
    authed = reactive(isTRUE(st$authed)),
    email = reactive(st$email %||% ""),
    name = reactive(st$name %||% ""),
    role = reactive(st$role %||% "member"),
    is_admin = reactive(isTRUE(st$authed) && identical(st$role, "admin")),
    # the owner (emails in ADMIN_EMAILS, joseph.zr by default): the only person who sees Admin, tab setup,
    # Claude analysis and Drive
    is_owner = reactive(isTRUE(st$authed) && is_admin_email(st$email %||% "")),
    locked = reactive(!is.null(st$locked_until) && Sys.time() < st$locked_until),
    attempts_left = reactive(max(0, cfg$max_attempts - st$attempts)),
    error = reactive(st$error),
    sign_out = sign_out
  )
}

# ---- Admin code lock -----------------------------------------------------------------------
admin_code_needed <- function() !IS_WINDOWS

admin_lock_ui <- function(error = NULL, locked = FALSE) {
  div(class = "wrap",
    div(class = "lock-card",
      div(class = "eyebrow", "Admin"),
      h3(icon("lock"), " Enter the admin code"),
      p(class = "muted", "The settings hold API keys and storage details, so they need the admin code on the hosted app. ",
        "On a Windows computer running the app locally, no code is asked for."),
      passwordInput("admin_code", NULL, placeholder = "Admin code", width = "260px"),
      actionButton("admin_unlock", "Unlock settings", class = "btn-brand", icon = icon("unlock")),
      if (locked) note("bad", "Too many wrong codes. Try again in 5 minutes.")
      else if (!is.null(error)) note("bad", error),
      tags$script(HTML("$(document).on('keyup', '#admin_code', function(e){ if(e.key === 'Enter'){ $('#admin_unlock').click(); } });"))))
}

admin_lock_server <- function(input, auth) {
  st <- reactiveValues(unlocked = !admin_code_needed(), attempts = 0, locked_until = NULL, error = NULL)
  observeEvent(input$admin_unlock, {
    req(auth$is_owner())
    if (!is.null(st$locked_until) && Sys.time() < st$locked_until) {
      st$error <- paste("Locked until", format(st$locked_until, "%H:%M:%S")); return()
    }
    if (!is.null(st$locked_until)) { st$locked_until <- NULL; st$attempts <- 0 }
    if (identical(trimws(input$admin_code %||% ""), cfg$admin_code)) {
      st$unlocked <- TRUE; st$error <- NULL
      log_change(auth$email(), "unlock", "admin", "admin settings unlocked with code")
    } else {
      st$attempts <- st$attempts + 1
      st$error <- sprintf("Wrong code (%d of %d attempts).", st$attempts, cfg$max_attempts)
      log_change(auth$email(), "unlock-failed", "admin", "wrong admin code")
      if (st$attempts >= cfg$max_attempts) st$locked_until <- Sys.time() + cfg$lockout_secs
    }
  })
  # signing out locks the settings again
  observeEvent(auth$authed(), { if (!auth$authed()) st$unlocked <- !admin_code_needed() }, ignoreInit = TRUE)
  list(
    unlocked = reactive(isTRUE(auth$is_owner()) && isTRUE(st$unlocked)),
    locked = reactive(!is.null(st$locked_until) && Sys.time() < st$locked_until),
    error = reactive(st$error),
    lock = function() st$unlocked <- !admin_code_needed()
  )
}
