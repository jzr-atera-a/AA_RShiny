# modules/ig_login.R


ig_login_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        width = 12, solidHeader = TRUE, status = "primary",
        title = NULL,
        div(
          style = paste0(
            "background: linear-gradient(135deg, #002C3C 0%, #005f5a 60%, #00A39A 100%);",
            "border-radius: 10px; padding: 26px 32px; color: #ffffff;"
          ),
          fluidRow(
            column(9,
              tags$h2(HTML(paste0(icon("key"), " IG Trading API — Login & Credentials")),
                      style = "font-size:24px; font-weight:700; margin:0 0 8px 0; color:#ffffff;"),
              tags$p(HTML(paste0(
                "Authenticate against IG's REST API to pull live CFD market data (indices, FX, commodities) ",
                "directly into this dashboard alongside the existing Yahoo Finance-sourced assets. Once ",
                "logged in here, select <strong>IG (CFDs)</strong> as the Asset Class in the sidebar to feed ",
                "IG-sourced OHLC data into every other tab — Market Overview, Price Analysis, and Technical ",
                "Indicators, all of it."
              )), style = "font-size:13.5px; line-height:1.7; color:#e8f8f6; margin:0;")
            ),
            column(3,
              div(style = "text-align:center; padding-top:6px;",
                  icon("shield-halved", style = "font-size:40px; color:#7fffd4;"),
                  tags$p("Session held in memory only", style = "font-size:11px; color:#b2e0db; margin-top:8px;")
              )
            )
          )
        )
      )
    ),
    
    fluidRow(
      box(
        width = 12, solidHeader = FALSE, status = "warning",
        div(style = "display:flex; align-items:flex-start; gap:14px;",
          icon("circle-info", style = "font-size:22px; color:#e67e22; margin-top:2px; flex-shrink:0;"),
          div(
            tags$strong("Before you start:", style = "color:#7d4a00; font-size:14px;"),
            tags$p(HTML(paste0(
              "You need an IG <strong>live</strong> account to generate an API key (a standalone demo account ",
              "cannot create one) &mdash; go to <em>My Account &gt; Settings &gt; API Keys</em> on IG's web ",
              "platform, generate a key, then switch the account selector to Demo and generate a second key ",
              "for safe testing. This tab talks to <code>demo-api.ig.com</code> or <code>api.ig.com</code> ",
              "depending on the Environment selected below."
            )), style = "font-size:13px; color:#5a3500; margin:4px 0 0 0; line-height:1.6;")
          )
        )
      )
    ),
    
    fluidRow(
      box(
        title = "IG API Credentials", status = "primary", solidHeader = TRUE, width = 5,
        radioButtons(ns("igEnv"), "Environment:",
                     choices = c("Demo" = "DEMO", "Live" = "LIVE"),
                     selected = "DEMO", inline = TRUE),
        passwordInput(ns("igApiKey"), "API Key:", value = Sys.getenv("IG_SERVICE_API_KEY"), width = "100%"),
        textInput(ns("igUsername"), "Username:", value = Sys.getenv("IG_SERVICE_USERNAME"), width = "100%"),
        passwordInput(ns("igPassword"), "Password:", value = Sys.getenv("IG_SERVICE_PASSWORD"), width = "100%"),
        textInput(ns("igAccNumber"), "Account Number (optional):",
                  value = Sys.getenv("IG_SERVICE_ACC_NUMBER"), width = "100%"),
        div(style = "display:flex; gap:10px; margin-top:6px;",
          actionButton(ns("igLoginBtn"),  "Login",  icon = icon("right-to-bracket"), class = "btn-primary", width = "50%"),
          actionButton(ns("igLogoutBtn"), "Logout", icon = icon("right-from-bracket"), width = "50%")
        ),
        tags$p(HTML(paste0(
          "If the <code>IG_SERVICE_USERNAME</code>, <code>IG_SERVICE_PASSWORD</code>, ",
          "<code>IG_SERVICE_API_KEY</code>, and <code>IG_SERVICE_ACC_NUMBER</code> environment variables ",
          "are set on the server (e.g. via <code>.Renviron</code> on shinyapps.io), this form pre-fills from ",
          "them automatically. Credentials are held only in this session's server-side memory for the ",
          "duration of your session and are never written to disk or logged."
        )), style = "font-size:11px; color:#888; font-style:italic; margin-top:12px; line-height:1.5;")
      ),
      box(
        title = "Session Status", status = "info", solidHeader = TRUE, width = 7,
        uiOutput(ns("igStatusUI")),
        tags$hr(),
        actionButton(ns("igTestConnection"), "Test Connection (Fetch Accounts)",
                     icon = icon("plug"), class = "btn-primary"),
        br(), br(),
        withSpinner(DT::dataTableOutput(ns("igAccountsTable")))
      )
    ),
    
    fluidRow(
      box(
        title = "Find an EPIC (Market Search)", status = "primary", solidHeader = TRUE, width = 12,
        fluidRow(
          column(8, textInput(ns("igSearchTerm"), "Search term:", value = "",
                               placeholder = "e.g. 'FTSE', 'EUR/USD', 'Gold'", width = "100%")),
          column(4, div(style = "padding-top:24px;",
                        actionButton(ns("igSearchBtn"), "Search Markets", icon = icon("magnifying-glass"),
                                     class = "btn-primary", width = "100%")))
        ),
        withSpinner(DT::dataTableOutput(ns("igSearchResultsTable"))),
        tags$p(paste0(
          "Use this to find the correct EPIC code for any instrument available on your account, then paste ",
          "it into the 'Or enter a custom EPIC' field under the IG (CFDs) asset selector in the sidebar."
        ), style = "font-size:12px; color:#666; margin:10px 0 0 0; line-height:1.5;")
      )
    ),
    
    fluidRow(
      box(
        title = "How the Authentication Flow Works", status = "info", solidHeader = TRUE, width = 12,
        fluidRow(
          column(3,
            div(style = "text-align:center; padding:12px;",
                tags$div("1", style = "background:#008A82; color:#fff; border-radius:50%; width:32px; height:32px; line-height:32px; margin:0 auto 8px auto; font-weight:700;"),
                tags$strong("POST /session", style = "display:block; color:#002C3C; font-size:13px;"),
                tags$p("API key + username + password sent to the demo or live gateway.", style = "font-size:11.5px; color:#666; margin-top:4px;")
            )
          ),
          column(3,
            div(style = "text-align:center; padding:12px;",
                tags$div("2", style = "background:#008A82; color:#fff; border-radius:50%; width:32px; height:32px; line-height:32px; margin:0 auto 8px auto; font-weight:700;"),
                tags$strong("CST + X-SECURITY-TOKEN", style = "display:block; color:#002C3C; font-size:13px;"),
                tags$p("Returned in response headers and identify the client and current account.", style = "font-size:11.5px; color:#666; margin-top:4px;")
            )
          ),
          column(3,
            div(style = "text-align:center; padding:12px;",
                tags$div("3", style = "background:#008A82; color:#fff; border-radius:50%; width:32px; height:32px; line-height:32px; margin:0 auto 8px auto; font-weight:700;"),
                tags$strong("Tokens on every request", style = "display:block; color:#002C3C; font-size:13px;"),
                tags$p("Passed as headers on subsequent calls, alongside X-IG-API-KEY.", style = "font-size:11.5px; color:#666; margin-top:4px;")
            )
          ),
          column(3,
            div(style = "text-align:center; padding:12px;",
                tags$div("4", style = "background:#008A82; color:#fff; border-radius:50%; width:32px; height:32px; line-height:32px; margin:0 auto 8px auto; font-weight:700;"),
                tags$strong("Auto-extending session", style = "display:block; color:#002C3C; font-size:13px;"),
                tags$p("Tokens stay valid while in active use; re-login if a call is rejected.", style = "font-size:11.5px; color:#666; margin-top:4px;")
            )
          )
        ),
        tags$hr(),
        tags$p(HTML(paste0(
          "This app authenticates via the <strong>igfetchr</strong> R package (CRAN), which implements this ",
          "exact CST / X-SECURITY-TOKEN flow against IG's REST gateway. Default rate limits: <strong>60</strong> ",
          "non-trading requests/minute per app, <strong>30</strong> non-trading requests/minute per account, ",
          "and <strong>10,000</strong> historical price datapoints/week &mdash; keep this in mind if you wire up ",
          "auto-refresh timers against IG data."
        )), style = "font-size:12px; color:#666; line-height:1.6; margin:0;")
      )
    )
  )
}

# Note: keeps the same server_function(id, data_manager) signature as every other
# module (so global.R's generic module-init loop needs no special-casing), and
# reaches IG-specific state/methods via data_manager$ig — the linked
# IGSessionManager instance (see R/utils_ig.R), assigned once in global.R.

ig_login_server <- function(id, data_manager) {
  moduleServer(id, function(input, output, session) {
    
    ig <- data_manager$ig
    
    observeEvent(input$igLoginBtn, {
      req(input$igApiKey, input$igUsername, input$igPassword)
      ig$login(
        username   = input$igUsername,
        password   = input$igPassword,
        api_key    = input$igApiKey,
        env        = input$igEnv,
        acc_number = input$igAccNumber
      )
    })
    
    observeEvent(input$igLogoutBtn, {
      req(ig$is_logged_in())
      ig$logout()
    })
    
    output$igStatusUI <- renderUI({
      ig$state_trigger()  # reactive dependency — re-renders on login/logout
      
      if (!ig$is_logged_in()) {
        div(style = "text-align:center; padding:20px;",
            icon("circle-xmark", style = "font-size:32px; color:#e74c3c;"),
            tags$h4("Not connected", style = "color:#e74c3c; margin-top:10px;"),
            tags$p("Enter your credentials on the left and click Login.", style = "color:#888; font-size:12px;")
        )
      } else {
        div(style = "text-align:center; padding:20px;",
            icon("circle-check", style = "font-size:32px; color:#27ae60;"),
            tags$h4("Connected", style = "color:#27ae60; margin-top:10px;"),
            tags$p(paste("Environment:", ig$env), style = "font-size:12px; color:#444; margin:2px 0;"),
            tags$p(paste("Logged in at:", format(ig$login_time, "%Y-%m-%d %H:%M:%S")),
                   style = "font-size:12px; color:#444; margin:2px 0;")
        )
      }
    })
    
    ig_accounts_data <- eventReactive(input$igTestConnection, {
      req(ig$is_logged_in())
      ig$get_accounts()
    })
    
    output$igAccountsTable <- renderDT({
      req(ig_accounts_data())
      datatable(as.data.frame(ig_accounts_data()), options = list(dom = 't', scrollX = TRUE), rownames = FALSE)
    })
    
    ig_search_data <- eventReactive(input$igSearchBtn, {
      req(ig$is_logged_in(), input$igSearchTerm)
      ig$search_markets(input$igSearchTerm)
    })
    
    output$igSearchResultsTable <- renderDT({
      req(ig_search_data())
      datatable(as.data.frame(ig_search_data()),
                options = list(dom = 'tp', scrollX = TRUE, pageLength = 10), rownames = FALSE)
    })
    
    session$onSessionEnded(function() {})
  })
}
