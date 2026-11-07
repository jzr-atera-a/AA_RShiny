# R/auth.R: Authentication Module (Google Sheets backend)

library(shiny)

AUTH_CONFIG <- list(
  max_attempts  = 5,
  lockout_secs  = 300
)

# ── Login UI ─────────────────────────────────────────────────
login_screen_ui <- function(error_msg = NULL, attempts_left = 5, locked = FALSE) {
  error_block <- if (locked) {
    div(class = "login-error", icon("lock"),
        " Temporarily locked after too many failed attempts. Try again in 5 minutes.")
  } else if (!is.null(error_msg)) {
    div(class = "login-error", icon("exclamation-circle"), " ", error_msg,
        if (attempts_left < AUTH_CONFIG$max_attempts)
          span(class = "attempt-badge", paste0(attempts_left, " attempt(s) left")))
  }
  
  div(class = "login-overlay",
      div(class = "login-card",
          div(class = "login-badge", "\U0001f512 Restricted Access"),
          tags$h1(class = "login-title", "Venture Analysis"),
          tags$p(class = "login-subtitle",
                 "DeepTech Fundraising Suite", tags$br(),
                 "Enter your registered email address to continue."),
          tags$label(class = "login-label", `for` = "login_email_box", "Email Address"),
          div(style = "margin-bottom:0;",
              tags$input(
                id           = "login_email_box",
                type         = "email",
                class        = "login-input",
                placeholder  = "you@example.com",
                autocomplete = "email",
                disabled     = if (locked) "disabled" else NULL
              )
          ),
          tags$div(style = "margin-top:20px;",
                   actionButton(
                     "login_submit",
                     label = "\U0001f510 Request Access",
                     class = "login-btn",
                     disabled = if (locked) "disabled" else NULL
                   )
          ),
          if (!is.null(error_block)) error_block,
          div(class = "login-footer",
              "Access restricted to authorised users only.", tags$br(),
              "Contact your administrator to request access.")
      ),
      tags$script(HTML("
      // Wait for Shiny to be ready then bind everything
      $(document).ready(function() {

        // Re-bind Shiny inputs after uiOutput render
        setTimeout(function() {
          Shiny.initializeInputs(document.getElementById('login_email_box').parentElement);
          Shiny.bindAll(document.body);
          document.getElementById('login_email_box').focus();
        }, 200);

        // When button clicked, push email value into Shiny then trigger button
        $(document).off('click.loginbtn').on('click.loginbtn', '#login_submit', function() {
          var email = document.getElementById('login_email_box').value;
          Shiny.setInputValue('login_email_box', email, {priority: 'event'});
        });

        // Enter key on email field
        $(document).off('keypress.loginform').on('keypress.loginform', '#login_email_box', function(e) {
          if (e.which === 13) {
            e.preventDefault();
            var email = document.getElementById('login_email_box').value;
            Shiny.setInputValue('login_email_box', email, {priority: 'event'});
            $('#login_submit').click();
          }
        });
      });
    "))
  )
}

session_bar_ui <- function(email) {
  div(class = "session-bar",
      icon("circle", style = "color:#00aa55;font-size:8px;"),
      span("\U0001f4e7 Logged in as:"),
      span(class = "session-email", email),
      span(class = "session-dot", "|"),
      span(format(Sys.time(), "%d %b %Y %H:%M")),
      if (is_admin(email))
        span(class = "attempt-badge",
             style = "background:rgba(0,191,255,0.15);color:#00e5ff;",
             "\u2605 ADMIN")
  )
}

# ── Auth Module ───────────────────────────────────────────────
auth_server <- function(id = "auth") {
  moduleServer(id, function(input, output, session) {
    
    state <- reactiveValues(
      authenticated = FALSE,
      email         = NULL,
      attempts      = 0,
      locked_until  = NULL,
      session_id    = paste0("s_", format(Sys.time(), "%Y%m%d%H%M%S"),
                             "_", sample(1000:9999, 1))
    )
    
    # Watch both the button AND the email value being set
    observeEvent(input$login_submit, {
      email <- tolower(trimws(input$login_email_box %||% ""))
      cat("🔑 Login attempt for: '", email, "'\n", sep = "")
      do_login(email, state)
    }, ignoreNULL = TRUE, ignoreInit = TRUE)
    
    do_login <- function(email, state) {
      # Lockout check
      if (!is.null(state$locked_until) && Sys.time() < state$locked_until) {
        cat("⚠ Locked out\n")
        return()
      }
      if (!is.null(state$locked_until) && Sys.time() >= state$locked_until) {
        state$locked_until <- NULL
        state$attempts     <- 0
      }
      
      if (!nzchar(email)) {
        cat("⚠ Empty email\n")
        return()
      }
      
      allowed <- tryCatch(
        sheets_get_allowed_emails(),
        error = function(e) {
          cat("⚠ Could not read emails:", e$message, "\n")
          character(0)
        }
      )
      
      cat("📋 Checking against", length(allowed), "allowed emails\n")
      
      if (email %in% allowed) {
        state$authenticated <- TRUE
        state$email         <- email
        tryCatch(sheets_log_login(email, TRUE,  state$session_id),
                 error = function(e) invisible())
        cat("✓ Auth: granted for", email, "\n")
      } else {
        state$attempts <- state$attempts + 1
        tryCatch(sheets_log_login(email, FALSE, state$session_id),
                 error = function(e) invisible())
        cat("✗ Auth: denied for '", email, "' (",
            state$attempts, "/", AUTH_CONFIG$max_attempts, ")\n", sep = "")
        if (state$attempts >= AUTH_CONFIG$max_attempts) {
          state$locked_until <- Sys.time() + AUTH_CONFIG$lockout_secs
          cat("⚠ Locked out for", AUTH_CONFIG$lockout_secs, "seconds\n")
        }
      }
    }
    
    list(
      authenticated = reactive(state$authenticated),
      email         = reactive(state$email),
      session_id    = reactive(state$session_id),
      attempts      = reactive(state$attempts),
      locked        = reactive(!is.null(state$locked_until) &&
                                 Sys.time() < state$locked_until),
      attempts_left = reactive(pmax(0, AUTH_CONFIG$max_attempts - state$attempts))
    )
  })
}