# Collaboration Planning - choose funding programmes, team up with collaborators, and deliver.
# Run locally:   shiny::runApp()        Setup: see README.md
# Layout: sidebar groups (Home, 1 Discover ... 8 Learn, Admin), each with horizontal sub-tabs.

# Always load this version's code, even when another version (or another app) ran earlier in the same R session:
# skipping global.R when `loader` already existed kept the old functions in memory. Only the test harness
# sets option cp.keep_global (it replaces some functions with stand-ins before starting).
if (!isTRUE(getOption("cp.keep_global"))) source("global.R", local = globalenv())

theme <- bs_theme(
  version = 5, primary = "#1a9aa8", secondary = "#0f4a5c", success = "#2f9e6e",
  warning = "#e3a21a", danger = "#d6336c", "body-bg" = "#eef5f7", "body-color" = "#1d2b36",
  base_font = font_collection("Inter", "system-ui", "sans-serif"))

ui <- page(
  theme = theme, title = APP_NAME, lang = "en",
  tags$head(
    tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
    tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;800&family=Poppins:wght@600;700&display=swap"),
    tags$link(rel = "stylesheet", href = "styles.css"),
    tags$script(src = "app.js"),
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1")),
  div(class = "topbar",
      div(class = "brand-wrap",
          tags$button(type = "button", class = "burger", title = "Hide or show the menu", `aria-label` = "Hide or show the menu",
                      onclick = "cpToggleSide()", icon("bars")),
          div(class = "brand", tags$img(src = "mark.png", alt = ""), span(APP_NAME))),
      uiOutput("whoami", inline = TRUE)),
  uiOutput("shell"),
  div(class = "app-foot", paste(APP_NAME, "-", APP_TAGLINE)))

server <- function(input, output, session) {
  auth  <- auth_server(input, output, session)
  admin <- admin_lock_server(input, auth)

  # one poll drives every table; reads are cached in the store
  tick <- reactiveVal(0)
  observe({ invalidateLater(30000, session); tick(isolate(tick()) + 1) })
  bump <- function() tick(isolate(tick()) + 1)
  # A table as a reactive that only signals a change when its content changes (reactiveVal ignores identical
  # values), so a 30-second poll never rebuilds a form someone is typing in. One per table per session, made on first use.
  # Each read also depends on shell_v, which goes up once the app has been drawn after sign-in, so every
  # dropdown and table refreshes into the freshly drawn inputs (tab code starts before sign-in).
  shell_v <- reactiveVal(0)
  stable <- function(fn) { rv <- reactiveVal(isolate(fn())); observe({ tick(); rv(fn()) }); function() { shell_v(); rv() } }
  tables <- new.env(parent = emptyenv())
  rd <- function(tab) {
    if (is.null(tables[[tab]])) tables[[tab]] <- stable(function() store_read(tab))
    tables[[tab]]
  }

  settings <- stable(function() get_settings())
  for (t in c("consortium", "people", "decisions", "tasks")) rd(t)   # make these before any reactive uses them
  data <- list(programmes = rd("programmes"), question_sets = rd("question_sets"),
               users = rd("allowed_emails"), login_log = rd("login_log"), changelog = rd("changelog"),
               # used by three or more tabs (latest row per key already applied)
               consortium = reactive(latest_consortium(rd("consortium")())),
               people = reactive(latest_people(rd("people")())),
               eligibility = rd("eligibility"), priorities = rd("priorities"),
               decisions = reactive(latest_by(rd("decisions")(), "decision_id")),
               projects = rd("projects"),
               tasks = reactive(latest_tasks(rd("tasks")())))
  is_partner <- reactive(identical(auth$role(), "partner"))

  ctx <- list(
    auth = auth, admin = admin, tick = tick, bump = bump,
    rebuild_shell = function(group = NULL, sub = NULL) {
      rebuild(isolate(rebuild()) + 1)
      if (!is.null(group)) session$onFlushed(function() ctx$nav(group, sub), once = TRUE)
    },
    handoff = reactiveValues(person = NULL, programme = NULL, project = NULL, suggestion = NULL, analysis = NULL),   # one tab passing a choice to another
    user = auth$email, is_admin = auth$is_admin, is_partner = is_partner,
    is_owner = auth$is_owner,          # ADMIN_EMAILS (joseph.zr): Admin, tab setup, Claude analysis, Drive
    admin_ok = admin$unlocked,                    # admin AND unlocked (code, or Windows)
    settings = settings,
    data = data,
    table = rd,          # ctx$table("risks")() : any other table, same change-only behaviour
    # programmes this person may see: partners only see bids where they are in the consortium
    programmes = reactive({
      p <- data$programmes(); p$stage[!p$stage %in% STAGES] <- "Discover"
      if (is_partner()) p <- p[p$programme_id %in% partner_programme_ids(auth$email(), data$consortium()), , drop = FALSE]
      p
    }),
    # fit score and eligibility per programme (for badges and the stage gate)
    status = reactive({
      es <- eligibility_summary(data$eligibility()); fs <- fit_summary(data$priorities(), settings())
      list(elig = es, fit = fs)
    }),
    nav = function(group, sub = NULL) {
      nav_select("grp", group, session = session)
      if (!is.null(sub)) nav_select(paste0("sub_", group), sub, session = session)
      session$sendCustomMessage("cp-active", list(group = group, sub = sub))
    }
  )

  # ---- shell: sign-in page, or the app ---------------------------------------------------
  rebuild <- reactiveVal(0)   # Admin > Tabs and groups redraws the app in place (no reload, so no new sign-in)
  output$shell <- renderUI({
    rebuild()
    if (!auth$authed()) return(login_ui(auth$error(), auth$locked(), auth$attempts_left()))
    session$onFlushed(function() shell_v(isolate(shell_v()) + 1), once = TRUE)
    # the owner's tab setup is read once per sign-in; Admin > Tabs and groups reloads the page after saving
    app_shell(loader, auth$is_owner(), auth$role(), tab_config(get_settings()))
  })
  # once a day, when the owner signs in, every table is copied to Google Drive (Admin > Google Drive)
  observeEvent(auth$authed(), {
    if (auth$authed() && auth$is_owner()) session$onFlushed(function() drive_backup_if_due(auth$email()), once = TRUE)
  })
  # sidebar tab links (cpGo in www/app.js); the Admin group's tabs live inside admin_area
  observeEvent(input$nav_to, {
    g <- input$nav_to$group; s <- input$nav_to$sub
    if (identical(g, "admin") && !auth$is_owner()) return()
    ctx$nav(g, s)
  })

  output$whoami <- renderUI({
    req(auth$authed())
    div(class = "whoami",
        span(class = "avatar", toupper(substr(auth$name(), 1, 1))),
        span(class = "wn", auth$name()),
        if (auth$is_owner()) span(class = "pill pill-admin", "Owner") else if (auth$is_admin()) span(class = "pill pill-admin", "Admin"),
        actionLink("signout", "Sign out", class = "so"))
  })
  observeEvent(input$signout, { auth$sign_out(); admin$lock() })

  # sidebar links -> group pages
  for (g in loader$registry$groups) local({
    gid <- g$id
    observeEvent(input[[paste0("go_", gid)]], ctx$nav(gid), ignoreInit = TRUE)
  })

  # ---- Admin group: the owner only, and locked by the admin code unless on Windows ------------
  admin_group <- Filter(function(g) isTRUE(g$admin), loader$registry$groups)[[1]]
  output$admin_area <- renderUI({
    if (!auth$is_owner()) return(note("bad", "Only the owner can open this group."))
    if (!admin$unlocked()) return(admin_lock_ui(admin$error(), admin$locked()))
    session$onFlushed(function() shell_v(isolate(shell_v()) + 1), once = TRUE)   # fill the admin forms once drawn
    tagList(
      div(class = "admin-strip",
          if (IS_WINDOWS) span(icon("desktop"), " Running on Windows: no admin code needed.")
          else span(icon("unlock"), " Settings unlocked for this session."),
          if (!IS_WINDOWS) actionLink("admin_relock", tagList(icon("lock"), " Lock again"), class = "relock")),
      group_tabs(admin_group, loader, auth$role(), TRUE, tab_config(get_settings())))
  })
  observeEvent(input$admin_relock, admin$lock())

  # ---- module servers -------------------------------------------------------------------
  for (id in loader$enabled_ids()) get(paste0(id, "_server"), envir = .GlobalEnv)(id, ctx)
}

shinyApp(ui, server)
