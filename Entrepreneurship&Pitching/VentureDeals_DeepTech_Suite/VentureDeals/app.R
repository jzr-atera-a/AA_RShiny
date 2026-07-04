# app.R — Venture Deals: DeepTech Fundraising Suite v4.8

library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(yaml)
library(R6)
library(dplyr)
library(httr)
library(jsonlite)
library(openssl)
library(base64enc)

if (file.exists(".Renviron")) readRenviron(".Renviron")

source("global.R",              local = TRUE)
source("R/module_loader.R",     local = TRUE)
source("R/sheets_backend.R",    local = TRUE)
source("R/auth.R",              local = TRUE)
source("R/analytics_tracker.R", local = TRUE)

for (f in list.files("modules", pattern = "\\.R$", full.names = TRUE)) {
  source(f, local = TRUE)
}

sheets_connect()

# ── UI ───────────────────────────────────────────────────────
ui <- dashboardPage(
  skin = "black",
  dashboardHeader(title = "Venture Deals · DeepTech"),
  dashboardSidebar(
    tags$div(class = "sidebar-book-badge",
             tags$div(class = "book-chip",    "VENTURE DEALS · DEEPTECH"),
             tags$div(class = "book-authors", "Brad Feld & Jason Mendelson"),
             tags$div(class = "book-pub",     "Applied to DeepTech Founders")),
    sidebarMenu(id = "tabs",
                menuItem("\U0001f9ed App Guide",     tabName = "guide",                icon = icon("compass")),
                menuItem("\U0001f30d Overview",       tabName = "overview",             icon = icon("home")),
                menuItem("1 \u00b7 The Players",     tabName = "players",              icon = icon("users")),
                menuItem("2 \u00b7 Term Sheet",      tabName = "term_sheet",           icon = icon("file-alt")),
                menuItem("3 \u00b7 Economic Terms",  tabName = "economic_terms",       icon = icon("chart-pie")),
                menuItem("4 \u00b7 Control Terms",   tabName = "control_terms",        icon = icon("chess-king")),
                menuItem("5 \u00b7 Cap Table",       tabName = "cap_table",            icon = icon("table")),
                menuItem("6 \u00b7 Convertible",     tabName = "convertible",          icon = icon("sync-alt")),
                menuItem("7 \u00b7 MC Valuation",    tabName = "montecarlo_valuation", icon = icon("dice")),
                menuItem("8 \u00b7 MC Runway",       tabName = "montecarlo_runway",    icon = icon("road")),
                menuItem("9 \u00b7 Negotiation",     tabName = "negotiation",          icon = icon("handshake")),
                menuItem("10 \u00b7 DeepTech Deals", tabName = "deeptech_deals",       icon = icon("microchip")),
                tags$div(id = "admin_menu_item",
                         menuItem("\u2605 Admin Analytics", tabName = "admin_reporting", icon = icon("chart-bar"))
                )
    )
  ),
  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet",
                href = "https://fonts.googleapis.com/css2?family=Syne:wght@700;800&family=Inter:wght@400;600;700&family=JetBrains+Mono:wght@400;700&display=swap"),
      tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"),
      tags$link(rel = "stylesheet", type = "text/css", href = "css/auth.css"),
      tags$style(HTML("
        /* Hide the div wrapping admin menuItem */
        #admin_menu_item { display: none !important; }
      ")),
      tags$script(HTML("
        Shiny.addCustomMessageHandler('authenticate_user', function(msg) {
          var overlay = document.getElementById('login_overlay');
          if (overlay) overlay.style.display = 'none';
          document.body.classList.add('authenticated');
        });
        Shiny.addCustomMessageHandler('show_admin_tab', function(msg) {
          // Show the wrapper div
          var wrapper = document.getElementById('admin_menu_item');
          if (wrapper) wrapper.style.setProperty('display', 'block', 'important');
        });
      ")),
      analytics_js()
    ),
    
    # Login overlay — always in DOM, hidden via JS on auth
    div(id = "login_overlay", class = "login-overlay", style = "display:flex;",
        div(class = "login-card",
            div(class = "login-badge", "\U0001f512 Restricted Access"),
            tags$h1(class = "login-title", "Venture Deals"),
            tags$p(class = "login-subtitle",
                   "DeepTech Fundraising Suite", tags$br(),
                   "Enter your registered email address to continue."),
            tags$label(class = "login-label", `for` = "login_email", "Email Address"),
            textInput("login_email", label = NULL, placeholder = "you@example.com"),
            actionButton("login_submit", "\U0001f510 Request Access", class = "login-btn"),
            uiOutput("login_error"),
            div(class = "login-footer",
                "Access restricted to authorised users only.", tags$br(),
                "Contact your administrator to request access.")
        )
    ),
    
    uiOutput("session_bar"),
    
    tabItems(
      tabItem(tabName = "guide",                guide_ui("guide")),
      tabItem(tabName = "overview",             overview_ui("overview")),
      tabItem(tabName = "players",              players_ui("players")),
      tabItem(tabName = "term_sheet",           term_sheet_ui("term_sheet")),
      tabItem(tabName = "economic_terms",       economic_terms_ui("economic_terms")),
      tabItem(tabName = "control_terms",        control_terms_ui("control_terms")),
      tabItem(tabName = "cap_table",            cap_table_ui("cap_table")),
      tabItem(tabName = "convertible",          convertible_ui("convertible")),
      tabItem(tabName = "montecarlo_valuation", montecarlo_valuation_ui("montecarlo_valuation")),
      tabItem(tabName = "montecarlo_runway",    montecarlo_runway_ui("montecarlo_runway")),
      tabItem(tabName = "negotiation",          negotiation_ui("negotiation")),
      tabItem(tabName = "deeptech_deals",       deeptech_deals_ui("deeptech_deals")),
      tabItem(tabName = "admin_reporting",      admin_reporting_ui("admin_reporting"))
    )
  )
)

# ── Server ───────────────────────────────────────────────────
server <- function(input, output, session) {
  
  state <- reactiveValues(
    authenticated = FALSE,
    email         = NULL,
    attempts      = 0,
    locked_until  = NULL,
    session_id    = paste0("s_", format(Sys.time(), "%Y%m%d%H%M%S"),
                           "_", sample(1000:9999, 1))
  )
  
  # Initialise all module servers at startup
  guide_server("guide")
  overview_server("overview")
  players_server("players")
  term_sheet_server("term_sheet")
  economic_terms_server("economic_terms")
  control_terms_server("control_terms")
  cap_table_server("cap_table")
  convertible_server("convertible")
  montecarlo_valuation_server("montecarlo_valuation")
  montecarlo_runway_server("montecarlo_runway")
  negotiation_server("negotiation")
  deeptech_deals_server("deeptech_deals")
  admin_reporting_server("admin_reporting",
                         email_reactive = reactive(state$email))
  
  # Tracker initialised at startup — gates on email being set
  # All JS inputs passed from parent server to bypass moduleServer namespacing
  cat("🔧 Initialising tracker module...\n")
  tryCatch({
    tracker_server(
      id                  = "tracker",
      email_reactive      = reactive({ state$email %||% "" }),
      session_id          = isolate(state$session_id),
      tab_reactive        = reactive(input$tabs),
      box_click_reactive  = reactive(input$`__tracker_box_click`),
      btn_click_reactive  = reactive(input$`__tracker_btn_click`),
      tab_change_reactive = reactive(input$`__tracker_tab_change`),
      plot_interact_reactive = reactive(input$`__tracker_plot_interact`),
      session_end_reactive   = reactive(input$`__tracker_session_end`),
      flush_secs          = 10
    )
    cat("✓ Tracker module initialised\n")
  }, error = function(e) cat("❌ Tracker init error:", e$message, "\n"))
  
  # ── Login logic ───────────────────────────────────────────
  observeEvent(input$login_submit, {
    email <- tolower(trimws(input$login_email))
    cat("🔑 Login attempt: '", email, "'\n", sep = "")
    if (!nzchar(email)) return()
    
    if (!is.null(state$locked_until) && Sys.time() < state$locked_until) {
      cat("⚠ Locked out\n"); return()
    }
    
    allowed <- tryCatch(
      sheets_get_allowed_emails(),
      error = function(e) { cat("⚠ Error:", e$message, "\n"); character(0) }
    )
    cat("📋 Checking against", length(allowed), "emails\n")
    
    if (email %in% allowed) {
      state$authenticated <- TRUE
      state$email         <- email
      # Hide overlay + reveal app via JS
      session$sendCustomMessage("authenticate_user", list())
      tryCatch(sheets_log_login(email, TRUE, state$session_id), error = function(e) invisible())
      cat("✓ Auth: granted for", email, "\n")
    } else {
      state$attempts <- state$attempts + 1
      tryCatch(sheets_log_login(email, FALSE, state$session_id), error = function(e) invisible())
      cat("✗ Auth: denied for '", email, "'\n", sep = "")
      if (state$attempts >= 5) state$locked_until <- Sys.time() + 300
    }
  }, ignoreNULL = TRUE, ignoreInit = TRUE)
  
  output$login_error <- renderUI({
    if (state$attempts > 0 && !state$authenticated)
      div(class = "login-error", icon("exclamation-circle"),
          " That email is not on the access list.",
          if (state$attempts > 1)
            span(class = "attempt-badge",
                 paste0(pmax(0, 5 - state$attempts), " attempt(s) left")))
  })
  
  output$session_bar <- renderUI({
    req(state$authenticated)
    session_bar_ui(state$email)
  })
  
  observeEvent(state$email, {
    req(state$email)
    if (is_admin(state$email)) {
      session$sendCustomMessage("show_admin_tab", list())
      cat("✓ Admin tab shown for:", state$email, "\n")
    }
  })
  
  observeEvent(state$authenticated, {
    req(state$authenticated)
    cat("✓ App loaded for:", state$email, "\n")
  }, once = TRUE)
}

shinyApp(ui, server)