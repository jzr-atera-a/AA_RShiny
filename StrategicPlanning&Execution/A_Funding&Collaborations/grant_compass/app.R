# Grant Compass - collaborative grant prioritisation + Collaboration Lab (R Shiny)
# Run locally:  shiny::runApp()     See README.md for Google Sheet setup.
#
# Navigation is two-level, like the Six Sigma dashboard's grouped tabs:
#   Grants Hub        -> Welcome | Grants | Prioritise | Ideas
#   Collaboration Lab -> Workspace | Decisions | Decision log | Weekly updates | Meet by exception | Playbook & invites
#   Admin

library(shiny)
library(bslib)
library(DT)

# Files in ./R are sourced automatically by Shiny (config, store, helpers, modules).
store_init()   # connect to Google Sheets if configured, otherwise use local CSV test store

theme <- bs_theme(
  version = 5, primary = "#1a9aa8", secondary = "#0f4a5c", success = "#2f9e6e",
  warning = "#e3a21a", danger = "#d6336c", "body-bg" = "#eef5f7", "body-color" = "#1d2b36",
  "navbar-bg" = "#0b2a3c")

# where each sub-tab lives, so any module can jump to it with ctx$nav("Decisions")
NAV_MAP <- list(
  Welcome = c("grants", "grants_sub"), Grants = c("grants", "grants_sub"), Prioritise = c("grants", "grants_sub"), Ideas = c("grants", "grants_sub"),
  Workspace = c("collab", "collab_sub"), Decisions = c("collab", "collab_sub"), Log = c("collab", "collab_sub"),
  Weekly = c("collab", "collab_sub"), Meet = c("collab", "collab_sub"), Playbook = c("collab", "collab_sub"))

sub_title <- function(icon, text) tagList(ico(icon, 15), span(text))
group_band <- function(cls, icon, title, blurb) div(class = paste("group-band", cls),
  span(class = "gb-ico", ico(icon, 22)), div(div(class = "gb-t", title), div(class = "gb-b", blurb)))

ui <- page_navbar(
  id = "main", title = div(class = "brand", tags$img(src = "mark.png", alt = ""), span(APP_NAME)),
  theme = theme, window_title = APP_NAME, fillable = FALSE, lang = "en",
  header = tagList(
    tags$head(
      tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
      tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;800&family=Poppins:wght@600;700&display=swap"),
      tags$link(rel = "stylesheet", href = "styles.css"),
      tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
      # remember the tester's display name in this browser (test mode, sign-in off)
      tags$script(HTML("
        $(document).on('shiny:connected', function() {
          try { var n = localStorage.getItem('gc_name'); if (n) Shiny.setInputValue('stored_name', n, {priority: 'event'}); } catch(e) {}
        });
        Shiny.addCustomMessageHandler('gc_save_name', function(n) { try { localStorage.setItem('gc_name', n); } catch(e) {} });
      "))),
    conditionalPanel("output.gate", mod_auth_ui("auth"))),

  nav_panel(title = sub_title("grid", "Grants Hub"), value = "grants",
    div(class = "grp grp-grants",
      group_band("g", "grid", "Grants Hub", "Find the funding that fits us: browse, score, and spark ideas."),
      navset_pill(id = "grants_sub",
        nav_panel(sub_title("home", "Welcome"),    value = "Welcome",    div(class = "wrap", mod_welcome_ui("welcome"))),
        nav_panel(sub_title("grid", "Grants"),     value = "Grants",     div(class = "wrap", mod_grants_ui("grants"))),
        nav_panel(sub_title("target", "Prioritise"), value = "Prioritise", div(class = "wrap", mod_prio_ui("prio"))),
        nav_panel(sub_title("bulb", "Ideas"),      value = "Ideas",      div(class = "wrap", mod_ideas_ui("ideas")))))),

  nav_panel(title = sub_title("compass", "Collaboration Lab"), value = "collab",
    div(class = "grp grp-collab",
      group_band("c", "compass", "Collaboration Lab", "Decide how we work on projects, tools and capabilities, in writing and in your own time."),
      navset_pill(id = "collab_sub",
        nav_panel(sub_title("home", "Workspace"),      value = "Workspace", div(class = "wrap", mod_chome_ui("chome"))),
        nav_panel(sub_title("check", "Decisions"),     value = "Decisions", div(class = "wrap", mod_dec_ui("dec"))),
        nav_panel(sub_title("book", "Decision log"),   value = "Log",       div(class = "wrap", mod_log_ui("log"))),
        nav_panel(sub_title("pencil", "Weekly updates"), value = "Weekly",  div(class = "wrap", mod_weekly_ui("weekly"))),
        nav_panel(sub_title("calendar", "Meet by exception"), value = "Meet", div(class = "wrap", mod_meet_ui("meet"))),
        nav_panel(sub_title("bookopen", "Playbook & invites"), value = "Playbook", div(class = "wrap", mod_play_ui("play")))))),

  nav_panel(title = sub_title("sliders", "Admin"), value = "admin", div(class = "wrap", mod_admin_ui("admin"))),
  nav_spacer(),
  nav_item(uiOutput("needs_chip", inline = TRUE)),
  nav_item(uiOutput("whoami", inline = TRUE)),
  footer = div(class = "app-foot", paste(APP_NAME, "-", APP_TAGLINE))
)

server <- function(input, output, session) {
  # ---- shared reactive data layer: one poll drives every table (reads are cached) ----
  tick <- reactiveVal(0)
  observe({ invalidateLater(cfg$poll_ms, session); tick(isolate(tick()) + 1) })
  bump <- function() { tick(isolate(tick()) + 1) }
  rd <- function(tab) reactive({ tick(); store_read(tab) })

  settings <- reactive({ tick(); get_settings() })
  auth_required <- reactive(identical(settings()$auth_required, "true"))

  user <- reactiveValues(email = "guest@test.local", name = "Guest", role = "admin",
                         authed = !identical(isolate(settings())$auth_required, "true"))

  ctx <- list(
    user = user, settings = settings, auth_required = auth_required, bump = bump, tick = tick,
    data = list(users = rd("Users"), grants = rd("Grants"), prio = rd("Priorities"), ideas = rd("Ideas"), votes = rd("IdeaVotes"),
                decisions = rd("Decisions"), dopts = rd("DecisionOptions"), dinputs = rd("DecisionInputs"),
                weekly = rd("WeeklyUpdates"), syncs = rd("SyncRequests")),
    pick = reactiveVal(NULL),        # grant to preselect in Prioritise
    dec_pick = reactiveVal(NULL),    # decision to preselect in Decisions
    sync_pick = reactiveVal(NULL),   # decision to preselect in Meet
    draft = reactiveVal(NULL),       # prefilled new-decision modal (e.g. promoted from an idea)
    nav = function(tab) {
      if (tab == "admin") return(nav_select("main", "admin", session = session))
      m <- NAV_MAP[[tab]]; req(m)
      nav_select("main", m[1], session = session)
      nav_select(m[2], tab, session = session)
    }
  )

  set_guest <- function(nm) {
    nm <- trimws(nm)
    if (!auth_required() && nzchar(nm)) {
      user$name  <- nm
      user$email <- paste0(tolower(gsub("[^A-Za-z0-9]+", ".", nm)), "@test.local")
    }
  }
  observeEvent(input$stored_name, {
    set_guest(input$stored_name)
    updateTextInput(session, "welcome-guest_name", value = input$stored_name)
  })

  # switching sign-in on/off while the app is running
  observeEvent(auth_required(), {
    if (auth_required() && grepl("@test.local$", user$email)) { user$authed <- FALSE; user$role <- "member" }
    if (!auth_required() && !isTRUE(user$authed)) { user$authed <- TRUE; user$role <- "admin" }
  }, ignoreInit = TRUE)

  output$gate <- reactive(auth_required() && !isTRUE(user$authed))
  outputOptions(output, "gate", suspendWhenHidden = FALSE)

  observe({
    if (auth_required() && !identical(user$role, "admin")) nav_hide("main", "admin") else nav_show("main", "admin")
  })

  output$whoami <- renderUI({
    req(user$authed)
    div(class = "whoami",
      span(class = "avatar", toupper(substr(user$name %||% "G", 1, 1))),
      span(class = "wn", user$name),
      if (auth_required()) actionLink("signout", "Sign out", class = "so"))
  })
  observeEvent(input$signout, { user$authed <- FALSE; user$email <- ""; user$role <- "member" })

  # "N decisions need you" chip, always visible
  output$needs_chip <- renderUI({
    req(user$authed)
    n <- nrow(needs_you(ctx$data$decisions(), ctx$data$dinputs(), user$email))
    if (n > 0) actionLink("go_needs", span(class = "needs-chip", ico("clock", 13), paste(n, if (n == 1) "decision needs you" else "decisions need you")))
  })
  observeEvent(input$go_needs, ctx$nav("Decisions"))

  mod_auth_server("auth", ctx)
  mod_welcome_server("welcome", ctx)
  mod_grants_server("grants", ctx)
  mod_prio_server("prio", ctx)
  mod_ideas_server("ideas", ctx)
  mod_chome_server("chome", ctx)
  mod_dec_server("dec", ctx)
  mod_log_server("log", ctx)
  mod_weekly_server("weekly", ctx)
  mod_meet_server("meet", ctx)
  mod_play_server("play", ctx)
  mod_admin_server("admin", ctx)
}

shinyApp(ui, server)
