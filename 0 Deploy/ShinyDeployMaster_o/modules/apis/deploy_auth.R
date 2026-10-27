# modules/apis/deploy_auth.R
# Deployment Authentication — uploads a .R credentials file and PARSES
# (never executes) the name/token/secret from its setAccountInfo() call.
# Credentials stay in this session's memory only and are handed to the
# deploy worker as environment variables. Token/secret are masked on screen.

deploy_auth_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "meta-hero",
        tags$h1("\U0001f511 Deployment Authentication"),
        tags$h2("Upload your rsconnect credentials .R file to authenticate with shinyapps.io"),
        div(
          span(class = "hero-badge", "rsconnect"),
          span(class = "hero-badge", "shinyapps.io"),
          span(class = "hero-badge", "Session-Persistent Auth")
        )
    ),

    fluidRow(
      # ── Left: upload + authenticate ──────────────────────────
      box(title = "\U0001f4c4 Credentials File", status = "primary",
          solidHeader = TRUE, width = 6,

          ua_callout(paste0(
            "Upload the .R file containing your rsconnect::setAccountInfo() call. ",
            "The file is only read, never executed. Token and secret are masked below, ",
            "kept in this browser session's memory only, and verified with shinyapps.io ",
            "at deploy time."
          )),
          br(),

          fileInput(ns("auth_file"),
                    "Select credentials .R file:",
                    accept = c(".R", "text/plain"),
                    buttonLabel = icon("folder-open"),
                    placeholder = "No file selected"),

          uiOutput(ns("file_preview")),
          br(),

          actionButton(ns("btn_authenticate"),
                       tagList(icon("plug"), " Authenticate"),
                       class = "btn-primary btn-lg btn-block"),
          br(),
          actionButton(ns("btn_clear_auth"),
                       tagList(icon("times-circle"), " Clear / Re-authenticate"),
                       class = "btn-warning btn-block"),
          br(),
          uiOutput(ns("auth_status_msg"))
      ),

      # ── Right: status + format guide ─────────────────────────
      box(title = "\U0001f4f6 Connection Status", status = "info",
          solidHeader = TRUE, width = 6,

          uiOutput(ns("connection_status_panel")),
          br(),

          div(class = "section-heading-dark", "Expected .R file format"),
          div(class = "code-box", HTML(
            '<span style="color:#C4B5FD">library</span>(rsconnect)<br>
             <span style="color:#FCD34D">rsconnect</span><span style="color:#E9D5FF">::</span>setAccountInfo(<br>
             &nbsp;&nbsp;name=<span style="color:#FCD34D">\'atera-analytics\'</span>,<br>
             &nbsp;&nbsp;token=<span style="color:#FCD34D">\'YOUR_TOKEN_HERE\'</span>,<br>
             &nbsp;&nbsp;secret=<span style="color:#FCD34D">\'YOUR_SECRET_HERE\'</span>)'
          )),
          br(),

          div(class = "tip-box", HTML(
            "<strong>\U0001f4a1 Where to find credentials:</strong><br>",
            "shinyapps.io dashboard &rarr; <strong>Account</strong> &rarr; ",
            "<strong>Tokens</strong> &rarr; click <strong>Show</strong> next to any token &rarr; ",
            "<strong>Show secret</strong> &rarr; copy the full <code>setAccountInfo()</code> block."
          )),

          div(class = "warn-box", HTML(
            "<strong>\u26a0 Security note:</strong> The file is parsed, not run. ",
            "Credentials are never written to disk or logs and are forgotten when you close the tab."
          ))
      )
    )
  )
}

deploy_auth_server <- function(id, deploy_mgr) {
  moduleServer(id, function(input, output, session) {

    # ── Parsed credential values from the uploaded file ───────
    creds <- reactiveValues(
      display = NULL, token_masked = NULL, secret_masked = NULL,
      raw    = NULL,
      name   = NULL,
      token  = NULL,
      secret = NULL
    )

    # ── Helper: extract a named param from R source text ─────
    extract_param <- function(text, param) {
      # lookbehind: match name= only as a whole argument, not e.g. appName=
      pat <- paste0("(?<![A-Za-z0-9_.])", param, "\\s*=\\s*['\"]([^'\"]+)['\"]")
      m   <- regmatches(text, regexpr(pat, text, perl = TRUE))
      if (length(m) == 0 || nchar(m) == 0) return(NA_character_)
      sub(paste0(".*", param, "\\s*=\\s*['\"]"), "", m, perl = TRUE) |>
        gsub(pattern = "['\"].*$", replacement = "", perl = TRUE)
    }

    # ── Parse file on upload ─────────────────────────────────
    observeEvent(input$auth_file, {
      req(input$auth_file)
      tryCatch({
        raw <- paste(readLines(input$auth_file$datapath, warn = FALSE),
                     collapse = "\n")
        mask <- function(v) if (is.na(v) || nchar(v) < 8) "\u2022\u2022\u2022\u2022"
                            else paste0(substr(v, 1, 4), strrep("\u2022", 8), substr(v, nchar(v) - 3, nchar(v)))
        creds$raw    <- raw
        creds$name   <- extract_param(raw, "name")
        creds$token  <- extract_param(raw, "token")
        creds$secret <- extract_param(raw, "secret")
        # Masked copy of the file for display
        disp <- raw
        for (v in c(creds$token, creds$secret)) if (!is.na(v) && nchar(v) > 0) disp <- gsub(v, mask(v), disp, fixed = TRUE)
        creds$display <- disp
        creds$token_masked  <- mask(creds$token)
        creds$secret_masked <- mask(creds$secret)

        deploy_mgr$log("AUTH", paste("Credentials file loaded. Detected account:",
                                      creds$name %||% "<not found>"), "info")
      }, error = function(e) {
        deploy_mgr$log("AUTH", paste("Failed to read credentials file:", e$message), "error")
        showNotification(paste("File read error:", e$message), type = "error")
      })
    })

    # ── File preview (full contents shown) ───────────────────
    output$file_preview <- renderUI({
      req(creds$raw)
      div(
        br(),
        div(class = "section-heading-dark", "\U0001f4cb File Contents (secrets masked)"),
        div(class = "code-box",
            style = "max-height:220px;overflow-y:auto;",
            tags$pre(
              style = "background:transparent;border:none;color:#E9D5FF;margin:0;padding:0;font-size:11.5px;",
              creds$display
            )),
        br(),
        fluidRow(
          column(4, div(class = "gl-item",
                        div(class = "gl-term", "Account"),
                        div(class = "gl-def", creds$name %||% tags$em("not detected")))),
          column(4, div(class = "gl-item",
                        div(class = "gl-term", "Token"),
                        div(class = "gl-def",
                            style = "word-break:break-all;font-size:11px;font-family:'JetBrains Mono',monospace;",
                            creds$token_masked %||% tags$em("not detected")))),
          column(4, div(class = "gl-item",
                        div(class = "gl-term", "Secret"),
                        div(class = "gl-def",
                            style = "word-break:break-all;font-size:11px;font-family:'JetBrains Mono',monospace;",
                            creds$secret_masked %||% tags$em("not detected"))))
        )
      )
    })

    # ── Authenticate ─────────────────────────────────────────
    observeEvent(input$btn_authenticate, {
      req(input$auth_file, creds$raw)

      if (is.na(creds$name) || is.na(creds$token) || is.na(creds$secret)) {
        output$auth_status_msg <- renderUI({
          div(class = "warn-box",
              HTML("\u26a0 Could not parse name/token/secret from the file. ",
                   "Ensure the file uses the exact <code>setAccountInfo(name=...,token=...,secret=...)</code> format."))
        })
        return()
      }

      tryCatch({
        # Never source()/execute the uploaded file. Validate the parsed values
        # and keep them in this session only; the deploy worker verifies them
        # against shinyapps.io when it runs.
        if (!grepl("^[A-Za-z0-9_-]{1,63}$", creds$name))
          stop("Account name contains unexpected characters.")
        if (!grepl("^[A-Za-z0-9+/=_-]{8,}$", creds$token) || !grepl("^[A-Za-z0-9+/=_-]{8,}$", creds$secret))
          stop("Token or secret doesn't look like a shinyapps.io credential.")
        deploy_mgr$set_auth(creds$name, creds$token, creds$secret)

        output$auth_status_msg <- renderUI({
          div(class = "success-box",
              HTML(paste0(
                "\u2705 <strong>Authenticated successfully.</strong> ",
                "Account: <code>", creds$name, "</code>. ",
                "Credentials are held in this session only and checked with shinyapps.io at deploy time."
              )))
        })
        showNotification("\u2713 rsconnect authentication successful", type = "message")

      }, error = function(e) {
        deploy_mgr$log("AUTH", paste("Authentication error:", e$message), "error")
        output$auth_status_msg <- renderUI({
          div(class = "warn-box",
              HTML(paste0("\u2717 <strong>Authentication failed:</strong> ", e$message)))
        })
        showNotification(paste("Auth failed:", e$message), type = "error")
      })
    })

    # ── Clear auth ────────────────────────────────────────────
    observeEvent(input$btn_clear_auth, {
      deploy_mgr$clear_auth()
      creds$raw <- creds$name <- creds$token <- creds$secret <- NULL
      creds$display <- creds$token_masked <- creds$secret_masked <- NULL
      output$auth_status_msg <- renderUI({
        div(class = "tip-box", "Credentials cleared. Upload a new file to re-authenticate.")
      })
      showNotification("Credentials cleared", type = "warning")
    })

    # ── Status panel (reactive to deploy_mgr changes) ─────────
    output$connection_status_panel <- renderUI({
      deploy_mgr$debug_trigger()

      if (isTRUE(deploy_mgr$authenticated)) {
        div(
          div(style = paste0(
                "text-align:center;padding:22px;margin-bottom:14px;",
                "background:linear-gradient(135deg,#166534,#22c55e);",
                "border-radius:12px;color:white;"),
              tags$div(style = "font-size:2.4em;", "\u2705"),
              tags$p(style = "margin:6px 0 2px;font-weight:700;font-size:15px;",
                     "Authenticated"),
              tags$p(style = "margin:0;font-size:12px;opacity:.85;",
                     paste("Account:", deploy_mgr$account_name)),
              tags$p(style = "margin:4px 0 0;font-size:11px;opacity:.7;",
                     "Session-persistent \u2022 Active until session ends")
          )
        )
      } else {
        div(
          div(style = paste0(
                "text-align:center;padding:22px;margin-bottom:14px;",
                "background:#1F2937;border-radius:12px;color:#9CA3AF;"),
              tags$div(style = "font-size:2.4em;color:#4B5563;", "\u25cb"),
              tags$p(style = "margin:6px 0 2px;font-weight:600;", "Not authenticated"),
              tags$p(style = "margin:0;font-size:12px;",
                     "Upload a .R credentials file to begin")
          )
        )
      }
    })

    output$auth_status_msg <- renderUI({ div() })
  })
}
