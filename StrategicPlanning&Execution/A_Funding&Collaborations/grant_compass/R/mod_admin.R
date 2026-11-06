# ---- Admin: access, users, grants, scoring weights, integrations (Sheets + API), audit log ----

mod_admin_ui <- function(id) {
  ns <- NS(id)
  uiOutput(ns("page"))
}

admin_panel_ui <- function(ns, s) {
  tagList(
    div(class = "page-head",
      div(class = "eyebrow", "Admin"),
      h2("Settings & integrations"),
      p(class = "lead", "Every change here is saved to the shared Google Sheet and recorded in the change log.")),
    uiOutput(ns("testbanner")),
    navset_card_tab(id = ns("tabs"),
      nav_panel("Access", icon = NULL,
        div(class = "admin-block",
          h4("Sign-in"),
          p(class = "muted", "When on, visitors must enter an invited email that is listed and active in the Users tab. Sign-in is off by default while testing."),
          input_switch(ns("auth_required"), "Require sign-in with invited email", value = identical(s$auth_required, "true")),
          div(class = "note warn", "Before switching on, check your own email is in the Users table with role 'admin' (and active = TRUE), otherwise you will lock yourself out."),
          hr(),
          h4("Scoring weights"),
          p(class = "muted", "How much each question counts toward the 0-100 fit score."),
          layout_columns(col_widths = c(4, 4, 4),
            sliderInput(ns("w_alignment"), "Alignment", 0, 3, num(s$w_alignment, 1.5), step = 0.5, width = "100%"),
            sliderInput(ns("w_interest"), "Interest", 0, 3, num(s$w_interest, 1), step = 0.5, width = "100%"),
            sliderInput(ns("w_capability"), "Capability", 0, 3, num(s$w_capability, 1.5), step = 0.5, width = "100%")),
          hr(),
          h4("Collaboration rules"),
          p(class = "muted", "How the Collaboration Lab behaves for everyone."),
          layout_columns(col_widths = c(4, 4, 4),
            sliderInput(ns("decision_days"), "Days to weigh in (default)", 1, 10, num(s$decision_days, 3), step = 1, width = "100%"),
            div(input_switch(ns("blind_input"), "Hide others' views until you add yours", value = identical(s$blind_input, "true")),
                div(class = "small muted", "Reduces anchoring. Recommended.")),
            div(input_switch(ns("silence_agrees"), "No objection by the deadline = recommendation stands", value = identical(s$silence_agrees, "true")),
                div(class = "small muted", "Lazy consensus."))),
          actionButton(ns("save_access"), "Save access, weights & rules", class = "btn-brand"))),
      nav_panel("Users",
        div(class = "admin-block",
          p(class = "muted", "Double-click a cell to edit. Set active to TRUE to approve a pending request, FALSE to switch someone off."),
          DT::DTOutput(ns("users_tbl")),
          div(class = "btn-row", actionButton(ns("save_users"), "Save user changes", class = "btn-brand")),
          hr(),
          h4("Invite someone"),
          layout_columns(col_widths = c(4, 3, 2, 3),
            textInput(ns("n_email"), "Email", width = "100%"), textInput(ns("n_name"), "Name", width = "100%"),
            selectInput(ns("n_role"), "Role", c("member", "admin"), width = "100%"),
            textInput(ns("n_org"), "Organisation", width = "100%")),
          textInput(ns("n_int"), "Interests (separate with ;)", placeholder = "AI; batteries; drones", width = "100%"),
          actionButton(ns("add_user"), "Add to invite list", class = "btn-ghost"),
          uiOutput(ns("invite_text")))),
      nav_panel("Grants",
        div(class = "admin-block",
          h4("Edit the grant list"),
          p(class = "muted", "Set status to open, upcoming, closed or archived. Archived grants are hidden from everyone."),
          DT::DTOutput(ns("grants_tbl")),
          div(class = "btn-row", actionButton(ns("save_grants"), "Save grant changes", class = "btn-brand")),
          hr(),
          h4("Add a grant"),
          layout_columns(col_widths = c(6, 3, 3),
            textInput(ns("g_title"), "Title", width = "100%"), textInput(ns("g_funder"), "Funder", width = "100%"),
            textInput(ns("g_closes"), "Closes (YYYY-MM-DD)", placeholder = "2027-01-31", width = "100%")),
          textAreaInput(ns("g_summary"), "Summary", rows = 2, width = "100%"),
          layout_columns(col_widths = c(4, 2, 2, 4),
            textInput(ns("g_themes"), "Themes (separate with ;)", width = "100%"),
            numericInput(ns("g_min"), "Min £", NA, width = "100%"), numericInput(ns("g_max"), "Max £", NA, width = "100%"),
            textInput(ns("g_url"), "Link", width = "100%")),
          actionButton(ns("add_grant"), "Add grant", class = "btn-ghost"),
          hr(),
          h4("Pull grants from a website"),
          p(class = "muted", "Paste a funding listing page and a CSS selector for the links (default 'a'). Review the candidates, tick the ones you want, and add them."),
          layout_columns(col_widths = c(7, 3, 2),
            textInput(ns("scrape_url"), "Page URL", width = "100%"),
            textInput(ns("scrape_sel"), "CSS selector", value = "a", width = "100%"),
            div(class = "align-bottom", actionButton(ns("scrape"), "Fetch", class = "btn-ghost w-100"))),
          uiOutput(ns("scrape_msg")),
          DT::DTOutput(ns("scrape_tbl")),
          actionButton(ns("scrape_add"), "Add selected as grants", class = "btn-brand"))),
      nav_panel("Integrations",
        div(class = "admin-block",
          h4("Google Sheet storage"),
          uiOutput(ns("store_status")),
          p(class = "muted", "The sheet id is set outside the app with GH_SHEET_ID so it never sits in a shared file. See README.md for the 5-minute setup."),
          div(class = "btn-row",
            actionButton(ns("test_store"), "Re-read all tabs", class = "btn-ghost"),
            selectInput(ns("dl_tab"), NULL, names(SCHEMAS), width = "180px"),
            downloadButton(ns("dl"), "Download tab as CSV", class = "btn-ghost")),
          hr(),
          h4("AI idea generation (Anthropic API)"),
          p(class = "muted", "Optional. Without a key the app uses its built-in idea templates. The key is kept in server memory only and is never written to the sheet - use the ANTHROPIC_API_KEY environment variable to make it permanent."),
          layout_columns(col_widths = c(6, 4, 2),
            passwordInput(ns("api_key"), "API key", placeholder = "sk-ant-...", width = "100%"),
            textInput(ns("llm_model"), "Model", value = s$llm_model, width = "100%"),
            div(class = "align-bottom", input_switch(ns("llm_enabled"), "Enabled", value = identical(s$llm_enabled, "true")))),
          div(class = "btn-row",
            actionButton(ns("save_api"), "Save API settings", class = "btn-brand"),
            actionButton(ns("test_api"), "Test key", class = "btn-ghost")),
          uiOutput(ns("api_msg")))),
      nav_panel("Change log",
        div(class = "admin-block",
          p(class = "muted", "Latest 200 changes across the whole workspace."),
          DT::DTOutput(ns("log_tbl"))))
    )
  )
}

mod_admin_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    is_admin <- reactive(isTRUE(ctx$user$authed) && (!ctx$auth_required() || identical(ctx$user$role, "admin")))

    output$page <- renderUI({
      if (!is_admin()) return(div(class = "empty", "This area is for admins. Ask the workspace owner for the admin role."))
      admin_panel_ui(ns, isolate(ctx$settings()))
    })

    output$testbanner <- renderUI({
      if (!ctx$auth_required()) div(class = "note warn", "Test mode: sign-in is off, so everyone who opens the app can see this tab.")
    })

    who <- reactive(ctx$user$email)

    observeEvent(input$save_access, {
      req(is_admin())
      set_setting("auth_required", tolower(isTRUE(input$auth_required)), who())
      for (k in c("w_alignment", "w_interest", "w_capability", "decision_days")) set_setting(k, input[[k]], who())
      set_setting("blind_input", tolower(isTRUE(input$blind_input)), who())
      set_setting("silence_agrees", tolower(isTRUE(input$silence_agrees)), who())
      ctx$bump(); showNotification("Access, weights and collaboration rules saved.", type = "message")
    })

    # ---- users
    users_df <- reactiveVal(NULL)
    observe(users_df(isolate(ctx$data$users()))) |> bindEvent(ctx$data$users())
    output$users_tbl <- DT::renderDT({
      req(is_admin()); DT::datatable(users_df(), editable = "cell", rownames = FALSE, selection = "none",
        options = list(pageLength = 8, dom = "tip", scrollX = TRUE))
    })
    observeEvent(input$users_tbl_cell_edit, {
      info <- input$users_tbl_cell_edit
      users_df(DT::editData(users_df(), info, proxy = NULL, rownames = FALSE))
    })
    observeEvent(input$save_users, {
      req(is_admin()); store_replace("Users", users_df())
      log_change(who(), "edit_users", "Users", paste(nrow(users_df()), "rows")); ctx$bump()
      showNotification("Users saved.", type = "message")
    })
    observeEvent(input$add_user, {
      req(is_admin()); em <- tolower(trimws(input$n_email))
      if (!grepl("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", em, perl = TRUE)) { showNotification("Enter a valid email.", type = "warning"); return() }
      store_append("Users", data.frame(email = em, name = input$n_name, role = input$n_role, organisation = input$n_org,
                                       interests = input$n_int, active = "TRUE", invited_at = now_ts()))
      log_change(who(), "invite", em, input$n_role); ctx$bump()
      showNotification(paste("Added", em), type = "message")
    })
    output$invite_text <- renderUI({
      div(class = "invite-box",
        div(class = "small muted", "Message you can paste to new contributors:"),
        tags$pre(paste0("Hi - we're choosing which grants to chase and I'd love your input. It takes about 2 minutes:\n",
                        "1) open the Grant Compass link, 2) enter this email, 3) score the grants that fit you and vote on ideas.\n",
                        "Your scores shape what we bid for. Thank you!")))
    })

    # ---- grants
    grants_df <- reactiveVal(NULL)
    observe(grants_df(isolate(ctx$data$grants()))) |> bindEvent(ctx$data$grants())
    output$grants_tbl <- DT::renderDT({
      req(is_admin()); DT::datatable(grants_df(), editable = "cell", rownames = FALSE, selection = "none",
        options = list(pageLength = 6, dom = "tip", scrollX = TRUE))
    })
    observeEvent(input$grants_tbl_cell_edit, {
      info <- input$grants_tbl_cell_edit
      grants_df(DT::editData(grants_df(), info, proxy = NULL, rownames = FALSE))
    })
    observeEvent(input$save_grants, {
      req(is_admin()); store_replace("Grants", grants_df())
      log_change(who(), "edit_grants", "Grants", paste(nrow(grants_df()), "rows")); ctx$bump()
      showNotification("Grants saved.", type = "message")
    })
    observeEvent(input$add_grant, {
      req(is_admin(), nzchar(trimws(input$g_title)))
      store_append("Grants", data.frame(
        grant_id = new_id("g"), title = input$g_title, funder = input$g_funder, summary = input$g_summary,
        themes = input$g_themes, min_gbp = input$g_min, max_gbp = input$g_max,
        closes = trimws(input$g_closes %||% ""), url = input$g_url,
        status = "open", source = "manual", added_by = who(), added_at = now_ts()))
      log_change(who(), "add_grant", input$g_title, ""); ctx$bump()
      showNotification("Grant added.", type = "message")
    })

    scraped <- reactiveVal(NULL); smsg <- reactiveVal(NULL)
    observeEvent(input$scrape, {
      req(is_admin(), nzchar(input$scrape_url))
      smsg(NULL)
      res <- tryCatch(scrape_links(input$scrape_url, input$scrape_sel %||% "a"),
                      error = function(e) { smsg(div(class = "note bad", paste("Could not fetch that page:", conditionMessage(e)))); NULL })
      scraped(res)
      if (!is.null(res)) smsg(div(class = "note ok", paste(nrow(res), "candidate links found. Tick the real grants.")))
      set_setting("grants_url", input$scrape_url, who()); set_setting("grants_selector", input$scrape_sel, who())
    })
    output$scrape_msg <- renderUI(smsg())
    output$scrape_tbl <- DT::renderDT({
      req(scraped()); DT::datatable(scraped(), rownames = FALSE, options = list(pageLength = 8, dom = "tip", scrollX = TRUE))
    })
    observeEvent(input$scrape_add, {
      req(is_admin(), scraped()); idx <- input$scrape_tbl_rows_selected; req(length(idx) > 0)
      s <- scraped()[idx, , drop = FALSE]
      store_append("Grants", data.frame(
        grant_id = paste0(new_id("g"), sprintf("%02d", seq_len(nrow(s)))), title = s$title, funder = "", summary = "Imported from website - add summary and value.",
        themes = "", min_gbp = "", max_gbp = "", closes = "", url = s$url, status = "upcoming",
        source = input$scrape_url, added_by = who(), added_at = now_ts()))
      log_change(who(), "import_grants", input$scrape_url, paste(nrow(s), "links")); ctx$bump()
      showNotification(paste(nrow(s), "grants added - edit details in the table above."), type = "message")
    })

    # ---- integrations
    output$store_status <- renderUI({
      ok <- .store$backend == "sheets"
      div(class = paste("note", if (ok) "ok" else "warn"),
          strong(if (ok) "Google Sheets: " else "Local test store: "), .store$status,
          if (!ok) div(class = "small", "Data is saved to CSV files in the app's data/ folder until GH_SHEET_ID is set."))
    })
    observeEvent(input$test_store, {
      for (t in names(SCHEMAS)) store_read(t, force = TRUE)
      ctx$bump(); showNotification("All tabs re-read from storage.", type = "message")
    })
    output$dl <- downloadHandler(
      filename = function() paste0(input$dl_tab, "-", format(Sys.Date()), ".csv"),
      content = function(file) utils::write.csv(store_read(input$dl_tab, force = TRUE), file, row.names = FALSE))

    amsg <- reactiveVal(NULL); output$api_msg <- renderUI(amsg())
    observeEvent(input$save_api, {
      req(is_admin())
      if (nzchar(input$api_key)) .store$api_key <- input$api_key
      set_setting("llm_enabled", tolower(isTRUE(input$llm_enabled)), who())
      set_setting("llm_model", input$llm_model, who())
      ctx$bump(); amsg(div(class = "note ok", "API settings saved (key held in memory only)."))
    })
    observeEvent(input$test_api, {
      key <- if (nzchar(input$api_key)) input$api_key else .store$api_key
      if (!nzchar(key)) { amsg(div(class = "note bad", "Enter a key first.")); return() }
      r <- api_ping(key, input$llm_model)
      amsg(div(class = paste("note", if (grepl("^OK", r)) "ok" else "bad"), r))
    })

    output$log_tbl <- DT::renderDT({
      req(is_admin()); ctx$tick()
      l <- store_read("ChangeLog"); l <- l[order(l$timestamp, decreasing = TRUE), ]
      DT::datatable(head(l, 200), rownames = FALSE, selection = "none", options = list(pageLength = 10, dom = "ftip", scrollX = TRUE))
    })
  })
}
