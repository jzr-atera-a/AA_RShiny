# app.R — Shiny Deploy Master
# Group 1: APIs  (BigQuery · Claude · Deploy Auth · Debug Console)
# Group 2: R Shiny Upload (Explore Apps · Upload App · Deploy App)
# ─────────────────────────────────────────────────────────────────

source("global.R", local = TRUE)

for (f in list.files("modules/apis",   pattern = "\\.R$", full.names = TRUE)) source(f, local = TRUE)
for (f in list.files("modules/deploy", pattern = "\\.R$", full.names = TRUE)) source(f, local = TRUE)

cat("✓ All modules sourced\n\n")

# ══════════════════════════════════════════════════════════════════
# LOGIN (basic password gate — see SDM_PASSWORD in global.R)
# ══════════════════════════════════════════════════════════════════
login_ui <- function(failed = FALSE) {
  div(class = "sdm-login",
    div(class = "sdm-login-card",
      tags$h2(icon("rocket", style = "color:#E8A020;"), " Deploy Master"),
      tags$p("Enter the access password to continue."),
      passwordInput("login_pw", NULL, placeholder = "Password"),
      actionButton("login_btn", "Enter", class = "btn-primary btn-block"),
      if (failed) div(class = "warn-box", style = "margin-top:10px;", "Incorrect password.")
    )
  )
}

# ══════════════════════════════════════════════════════════════════
# UI
# ══════════════════════════════════════════════════════════════════
ui <- dashboardPage(
  skin = "black",

  dashboardHeader(
    title = tags$span(
      icon("rocket", style = "color:#E8A020;"),
      tags$b(" Deploy Master", style = "color:#F5C842;font-size:15px;")
    ),
    titleWidth = 240
  ),

  dashboardSidebar(
    width = 240,

    tags$div(class = "sidebar-platform-badge",
      tags$div(class = "platform-chip", "SHINY DEPLOY MASTER"),
      tags$div(class = "platform-sub",  "Posit \u00b7 shinyapps.io \u00b7 rsconnect")),

    # Menu is rendered after login (see server)
    sidebarMenuOutput("sdm_menu")
  ),

  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"),
      tags$meta(charset = "UTF-8"),
      tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0"),
      # Ensure JetBrains Mono is available for console panels
      tags$link(rel = "stylesheet",
                href = "https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600&display=swap")
    ),

    # Login screen, then the tabs (see server)
    uiOutput("sdm_body")
  )
)

# ══════════════════════════════════════════════════════════════════
# SERVER
# ══════════════════════════════════════════════════════════════════
server <- function(input, output, session) {

  # deploy_mgr is per-session (holds reactiveVal objects internally)
  deploy_mgr <- DeployManager$new()

  # Optional: sign in to shinyapps.io from server start, so every session can
  # deploy without uploading the setAccountInfo() file. Set
  # SDM_SHINYAPPS_ACCOUNT_FILE to that file's path on the server.
  local({
    f <- Sys.getenv("SDM_SHINYAPPS_ACCOUNT_FILE", "")
    if (nzchar(f)) {
      a <- tryCatch(read_account_info(f), error = function(e) NULL)
      if (!is.null(a) && !anyNA(c(a$name, a$token, a$secret)) &&
          grepl("^[A-Za-z0-9_-]{1,63}$", a$name)) {
        deploy_mgr$set_auth(a$name, a$token, a$secret)
      } else {
        deploy_mgr$log("AUTH", "SDM_SHINYAPPS_ACCOUNT_FILE could not be read (name, token or secret missing)", "error")
      }
    }
  })

  authed     <- reactiveVal(FALSE)
  login_fail <- reactiveVal(FALSE)

  # Shared app registry state (table shown in Explore Apps, dropdown in Deploy App)
  apps_state <- reactiveValues(df = NULL, source = NULL, note = NULL, stamp = 0L)

  refresh_apps <- function() {
    res <- load_apps(api_manager)
    apps_state$df     <- res$data
    apps_state$source <- res$source
    apps_state$note   <- res$note
    apps_state$stamp  <- isolate(apps_state$stamp) + 1L
  }

  # ── Login ───────────────────────────────────────────────────────
  observeEvent(input$login_btn, {
    if (identical(input$login_pw, SDM_PASSWORD)) {
      authed(TRUE)
      login_fail(FALSE)
      # Open on Explore Apps once the menu exists in the browser
      session$onFlushed(function() {
        updateTabItems(session, "sidebar_menu", selected = "deploy_explore")
      }, once = TRUE)
    } else {
      login_fail(TRUE)
    }
  })

  output$sdm_menu <- renderMenu({
    if (!authed()) return(sidebarMenu(id = "sidebar_menu"))
    sidebarMenu(
      id = "sidebar_menu",
      selected = "deploy_explore",

      # ══════════════════════════════════════════
      # GROUP 1 — APIS
      # ══════════════════════════════════════════
      menuItem("APIs", icon = icon("key"),
        menuSubItem("BigQuery",        tabName = "api_bigquery",    icon = icon("database")),
        menuSubItem("Claude API",      tabName = "api_claude",      icon = icon("robot")),
        menuSubItem("Deploy Auth",     tabName = "api_deploy_auth", icon = icon("plug")),
        menuSubItem("Debug Console",   tabName = "api_debug",       icon = icon("bug"))
      ),

      # ══════════════════════════════════════════
      # GROUP 2 — R SHINY UPLOAD & DEPLOY
      # ══════════════════════════════════════════
      menuItem("R Shiny Upload", icon = icon("cloud-upload-alt"), startExpanded = TRUE,
        menuSubItem("Explore Apps",    tabName = "deploy_explore",  icon = icon("compass")),
        menuSubItem("Upload App",      tabName = "deploy_upload",   icon = icon("file-archive")),
        menuSubItem("Deploy App",      tabName = "deploy_app",      icon = icon("rocket"))
      )
    )
  })

  output$sdm_body <- renderUI({
    if (!authed()) return(login_ui(login_fail()))
    tabItems(
      # Explore Apps first: it is the default tab
      tabItem(tabName = "deploy_explore",  explore_apps_ui("deploy_explore")),

      # GROUP 1: APIs
      tabItem(tabName = "api_bigquery",    econ_bigquery_auth_ui("api_bigquery")),
      tabItem(tabName = "api_claude",      econ_claude_config_ui("api_claude")),
      tabItem(tabName = "api_deploy_auth", deploy_auth_ui("api_deploy_auth")),
      tabItem(tabName = "api_debug",       debug_console_ui("api_debug")),

      # GROUP 2: Deploy
      tabItem(tabName = "deploy_upload",   upload_app_ui("deploy_upload")),
      tabItem(tabName = "deploy_app",      deploy_app_ui("deploy_app"))
    )
  })

  # ── GROUP 1: APIs ───────────────────────────────────────────
  econ_bigquery_auth_server("api_bigquery", api_manager)
  econ_claude_config_server("api_claude",   api_manager)
  deploy_auth_server("api_deploy_auth",     deploy_mgr)
  debug_console_server("api_debug",         deploy_mgr)

  # ── GROUP 2: Deploy ──────────────────────────────────────────
  explore_apps_server("deploy_explore", apps_state, api_manager, refresh_apps)
  upload_app_server("deploy_upload", deploy_mgr)
  deploy_app_server("deploy_app", deploy_mgr, api_manager, apps_state, refresh_apps)

  # ── Registry: load on login, and reload whenever the BigQuery
  #    connection is made or dropped (checked every 2 s) ─────────
  bq_last <- reactiveVal(NULL)
  observe({
    req(authed())
    invalidateLater(2000, session)
    now <- isTRUE(api_manager$bq_authenticated)
    if (!identical(now, isolate(bq_last()))) {
      bq_last(now)
      refresh_apps()
    }
  })

  session$onSessionEnded(function() {
    # Best-effort cleanup of any remaining temp files on session end
    tryCatch({
      if (!is.null(deploy_mgr$unzip_temp_dir) &&
          dir.exists(deploy_mgr$unzip_temp_dir))
        unlink(deploy_mgr$unzip_temp_dir, recursive = TRUE)
    }, error = function(e) {})
    cat("✓ Session ended:", format(Sys.time()), "\n")
  })

  cat("✓ Server initialised\n")
}

shinyApp(ui, server)
