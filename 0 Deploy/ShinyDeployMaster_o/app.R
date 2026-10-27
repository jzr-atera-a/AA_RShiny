# app.R — Shiny Deploy Master
# Group 1: APIs  (BigQuery · Claude · Deploy Auth · Debug Console)
# Group 2: Deploy (Upload App · Deploy App)
# ─────────────────────────────────────────────────────────────────

source("global.R", local = TRUE)

for (f in list.files("modules/apis",   pattern = "\\.R$", full.names = TRUE)) source(f, local = TRUE)
for (f in list.files("modules/deploy", pattern = "\\.R$", full.names = TRUE)) source(f, local = TRUE)

cat("✓ All modules sourced\n\n")

# ══════════════════════════════════════════════════════════════════
# UI
# ══════════════════════════════════════════════════════════════════
ui <- dashboardPage(
  skin = "purple",

  dashboardHeader(
    title = tags$span(
      icon("rocket", style = "color:#A855F7;"),
      tags$b(" Deploy Master", style = "color:#ffffff;font-size:15px;")
    ),
    titleWidth = 240
  ),

  dashboardSidebar(
    width = 240,

    div(class = "sidebar-platform-badge",
        HTML("<div class='platform-chip'>\U0001f680 Shiny Deploy Master</div>
              <div class='platform-sub'>Posit \u00b7 shinyapps.io \u00b7 rsconnect</div>")),

    sidebarMenu(
      id = "sidebar_menu",

      # ══════════════════════════════════════════
      # GROUP 1 — APIS
      # ══════════════════════════════════════════
      menuItem("\U0001f511  APIs", icon = icon("key"),
        menuSubItem("BigQuery",        tabName = "api_bigquery",    icon = icon("database")),
        menuSubItem("Claude API",      tabName = "api_claude",      icon = icon("robot")),
        menuSubItem("Deploy Auth",     tabName = "api_deploy_auth", icon = icon("plug")),
        menuSubItem("Debug Console",   tabName = "api_debug",       icon = icon("bug"))
      ),

      # ══════════════════════════════════════════
      # GROUP 2 — R SHINY UPLOAD & DEPLOY
      # ══════════════════════════════════════════
      menuItem("\U0001f4e4  R Shiny Upload", icon = icon("cloud-upload-alt"),
        menuSubItem("Upload App",      tabName = "deploy_upload",   icon = icon("file-archive")),
        menuSubItem("Deploy App",      tabName = "deploy_app",      icon = icon("rocket"))
      )
    )
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

    tabItems(
      # GROUP 1: APIs
      tabItem(tabName = "api_bigquery",    econ_bigquery_auth_ui("api_bigquery")),
      tabItem(tabName = "api_claude",      econ_claude_config_ui("api_claude")),
      tabItem(tabName = "api_deploy_auth", deploy_auth_ui("api_deploy_auth")),
      tabItem(tabName = "api_debug",       debug_console_ui("api_debug")),

      # GROUP 2: Deploy
      tabItem(tabName = "deploy_upload",   upload_app_ui("deploy_upload")),
      tabItem(tabName = "deploy_app",      deploy_app_ui("deploy_app"))
    )
  )
)

# ══════════════════════════════════════════════════════════════════
# SERVER
# ══════════════════════════════════════════════════════════════════
server <- function(input, output, session) {

  # deploy_mgr is per-session (holds reactiveVal objects internally)
  deploy_mgr <- DeployManager$new()

  # ── GROUP 1: APIs ───────────────────────────────────────────
  econ_bigquery_auth_server("api_bigquery", api_manager)
  econ_claude_config_server("api_claude",   api_manager)
  deploy_auth_server("api_deploy_auth",     deploy_mgr)
  debug_console_server("api_debug",         deploy_mgr)

  # ── GROUP 2: Deploy ──────────────────────────────────────────
  upload_app_server("deploy_upload", deploy_mgr)
  deploy_app_server("deploy_app",    deploy_mgr)

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
