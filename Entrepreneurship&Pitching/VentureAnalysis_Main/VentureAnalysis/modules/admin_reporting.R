# modules/admin_reporting.R: Admin Analytics Dashboard
# Only visible to admin emails defined in SHEETS_CONFIG$admin_emails

admin_reporting_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero("", "\U0001f4ca", "Admin: Usage Analytics",
                 "Live user activity data pulled from Google Sheets. Track who is using the app, which tabs drive the most engagement, and what interactions users are making with interactive elements.",
                 c("LIVE DATA", "USER MANAGEMENT", "TAB ANALYTICS", "INTERACTION HEATMAP")),
    
    # ── User Management ───────────────────────────────────────
    fluidRow(
      box(title = "\U0001f465 User Management", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(5,
                   sh("Add New User"),
                   div(style = "display:flex;gap:8px;align-items:flex-end;",
                       div(style = "flex:1;",
                           tags$label(class = "login-label", "Email Address"),
                           tags$input(id = ns("new_email"), type = "email",
                                      class = "login-input", placeholder = "newuser@example.com",
                                      style = "width:100%;")
                       ),
                       div(
                         tags$label(class = "login-label", "Role"),
                         selectInput(ns("new_role"), NULL,
                                     choices = c("user", "admin", "viewer"),
                                     width = "110px")
                       ),
                       actionButton(ns("add_user"), "Add",
                                    style = "background:linear-gradient(135deg,#006633,#00aa55);color:#fff;border:none;border-radius:8px;padding:8px 18px;font-weight:700;height:38px;margin-bottom:0;")
                   ),
                   uiOutput(ns("add_result")),
                   br(),
                   sh("Remove User"),
                   div(style = "display:flex;gap:8px;align-items:center;",
                       div(style = "flex:1;",
                           tags$input(id = ns("rem_email"), type = "email",
                                      class = "login-input", placeholder = "user@example.com",
                                      style = "width:100%;")
                       ),
                       actionButton(ns("rem_user"), "Remove",
                                    style = "background:linear-gradient(135deg,#6b0f1a,#c0392b);color:#fff;border:none;border-radius:8px;padding:8px 18px;font-weight:700;height:38px;")
                   ),
                   uiOutput(ns("rem_result"))
            ),
            column(7,
                   sh("Current Allowed Users"),
                   actionButton(ns("refresh_users"), "\u21ba Refresh",
                                style = "background:rgba(0,191,255,0.15);color:#00e5ff;border:1px solid rgba(0,191,255,0.30);border-radius:6px;padding:4px 14px;font-size:12px;margin-bottom:10px;"),
                   DT::dataTableOutput(ns("users_table"))
            )
          )
      )
    ),
    
    # ── Login Stats ───────────────────────────────────────────
    fluidRow(
      box(title = "\U0001f512 Login Activity", status = "info", solidHeader = TRUE, width = 5,
          actionButton(ns("refresh_logins"), "\u21ba Refresh",
                       style = "background:rgba(0,191,255,0.15);color:#00e5ff;border:1px solid rgba(0,191,255,0.30);border-radius:6px;padding:4px 14px;font-size:12px;margin-bottom:10px;"),
          fluidRow(
            column(6, uiOutput(ns("stat_total_logins"))),
            column(6, uiOutput(ns("stat_unique_users")))
          ),
          fluidRow(
            column(6, uiOutput(ns("stat_today_logins"))),
            column(6, uiOutput(ns("stat_denied")))
          ),
          br(),
          DT::dataTableOutput(ns("login_table"))
      ),
      box(title = "\U0001f4c5 Logins Over Time", status = "warning", solidHeader = TRUE, width = 7,
          p(class = "info-box-plain", HTML("\U0001f4ca Daily login counts by user. Each bar = one calendar day. Colour = user email.")),
          plotlyOutput(ns("login_timeline"), height = "320px")
      )
    ),
    
    # ── Analytics Filter ──────────────────────────────────────
    fluidRow(
      box(title = "\U0001f50d Analytics Filter", status = "primary", solidHeader = TRUE, width = 12,
          fluidRow(
            column(5,
                   sh("Filter by User"),
                   p(style = "color:#8fb0d8;font-size:12px;margin-bottom:8px;",
                     "Select a user to filter all analytics visualisations below. Select All Users to see aggregate data across everyone."),
                   div(style = "display:flex;gap:10px;align-items:center;",
                       div(style = "flex:1;",
                           # Plain HTML select: does not re-render on reactive updates
                           uiOutput(ns("email_filter_ui"))
                       ),
                       actionButton(ns("refresh_analytics"), "\u21ba Refresh Analytics",
                                    style = "background:rgba(0,191,255,0.15);color:#00e5ff;border:1px solid rgba(0,191,255,0.30);border-radius:6px;padding:8px 14px;font-size:12px;white-space:nowrap;")
                   )
            ),
            column(7,
                   sh("Active Filter Summary"),
                   uiOutput(ns("filter_summary"))
            )
          )
      )
    ),
    
    # ── Tab Analytics ─────────────────────────────────────────
    fluidRow(
      box(title = "\U0001f5f9 Tab Engagement", status = "success", solidHeader = TRUE, width = 6,
          p(class = "info-box-plain", HTML("\U0001f4ca Total tab views and average time-on-tab (seconds) across all sessions.")),
          plotlyOutput(ns("tab_engagement"), height = "340px")
      ),
      box(title = "\U0001f5b1\ufe0f Interaction Heatmap", status = "danger", solidHeader = TRUE, width = 6,
          p(class = "info-box-plain", HTML("\U0001f4ca Events per user per tab: shows which users are most active on which tabs. Darker = more interactions.")),
          plotlyOutput(ns("interaction_heatmap"), height = "340px")
      )
    ),
    
    # ── Top Elements ──────────────────────────────────────────
    fluidRow(
      box(title = "\U0001f3af Most Interacted Elements", status = "primary", solidHeader = TRUE, width = 6,
          p(class = "info-box-plain", HTML("\U0001f4ca Buttons, sliders and boxes ranked by click/change count.")),
          plotlyOutput(ns("top_elements"), height = "300px")
      ),
      box(title = "\U0001f4cb Raw Analytics Log", status = "info", solidHeader = TRUE, width = 6,
          DT::dataTableOutput(ns("analytics_table"))
      )
    )
  )
}

admin_reporting_server <- function(id, email_reactive, ...) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns  # define ns for use inside moduleServer
    
    # ── Data refreshers ───────────────────────────────────────
    users_data     <- reactiveVal(NULL)
    logins_data    <- reactiveVal(NULL)
    analytics_data <- reactiveVal(NULL)
    
    load_all <- function() {
      users_data(sheets_get_users_df())
      logins_data(sheets_get_login_log())
      analytics_data(sheets_get_analytics())
    }
    
    observe({ load_all() })
    observeEvent(input$refresh_users,    { users_data(sheets_get_users_df()) })
    observeEvent(input$refresh_logins,   { logins_data(sheets_get_login_log()) })
    observeEvent(input$refresh_analytics, {
      analytics_data(sheets_get_analytics())
    })
    
    # ── Email list derived from analytics data ─────────────────
    available_emails <- reactive({
      df <- analytics_data()
      if (is.null(df) || !is.data.frame(df) || nrow(df) == 0) return(character(0))
      sort(unique(df$email[!is.na(df$email) & nchar(df$email) > 0]))
    })
    
    # ── Render stable plain HTML select ───────────────────────
    # uiOutput only re-renders when email list changes, not on every flush
    output$email_filter_ui <- renderUI({
      emails <- available_emails()
      # Build <option> tags
      opts <- c(
        tags$option(value = "__all__", "All Users"),
        lapply(emails, function(e) tags$option(value = e, e))
      )
      tagList(
        tags$select(
          id    = session$ns("email_filter"),
          class = "admin-email-select",
          style = paste0(
            "width:100%;background:rgba(4,13,33,0.90);",
            "border:1px solid rgba(0,191,255,0.30);border-radius:8px;",
            "color:#cdd9f5;font-family:Inter,sans-serif;font-size:13px;",
            "padding:8px 12px;outline:none;cursor:pointer;",
            "appearance:auto;-webkit-appearance:auto;"
          ),
          tagList(opts)
        ),
        # JS: listen for change and set Shiny input value
        tags$script(HTML(sprintf("
          (function() {
            var sel = document.getElementById('%s');
            if (!sel) return;
            sel.addEventListener('change', function() {
              Shiny.setInputValue('%s', this.value, {priority: 'event'});
            });
            Shiny.setInputValue('%s', sel.value, {priority: 'event'});
          })();
        ", session$ns("email_filter"), session$ns("email_filter"), session$ns("email_filter"))))
      )
    })
    
    # ── Filtered analytics reactive ────────────────────────────
    filtered_analytics <- reactive({
      df  <- analytics_data()
      sel <- input$email_filter %||% "__all__"
      if (is.null(df) || !is.data.frame(df) || nrow(df) == 0) return(df)
      if (is.null(sel) || sel == "__all__") return(df)
      df[!is.na(df$email) & df$email == sel, ]
    })
    
    # Helper to get current selection label
    current_filter_label <- reactive({
      sel <- input$email_filter %||% "__all__"
      if (is.null(sel) || sel == "__all__") "__all__" else sel
    })
    
    # ── Filter summary ─────────────────────────────────────────
    output$filter_summary <- renderUI({
      df  <- analytics_data()
      fdf <- filtered_analytics()
      sel <- current_filter_label()
      
      if (is.null(df) || !is.data.frame(df) || nrow(df) == 0) {
        return(info_box(tags$strong("No data yet: "), "Navigate the app and click Refresh Analytics."))
      }
      
      total_users  <- length(unique(df$email[!is.na(df$email)]))
      total_events <- nrow(df)
      filt_events  <- if (is.null(fdf)) 0 else nrow(fdf)
      filt_label   <- if (sel == "__all__") "All Users" else sel
      
      fluidRow(
        column(4, mc_stat(filt_label,   "Showing Data For")),
        column(4, mc_stat(filt_events,  "Events in View")),
        column(4, mc_stat(total_users,  "Total Users in Dataset"))
      )
    })
    
    # ── Add user ──────────────────────────────────────────────
    observeEvent(input$add_user, {
      email <- trimws(input$new_email)
      if (!nzchar(email)) {
        output$add_result <- renderUI(warn_box("\u26a0 Please enter an email address."))
        return()
      }
      result <- sheets_add_user(email, role = input$new_role, added_by = email_reactive())
      if (result$ok) {
        output$add_result <- renderUI(success_box(tags$strong("\u2713 "), result$msg))
        users_data(sheets_get_users_df())
      } else {
        output$add_result <- renderUI(warn_box(tags$strong("\u274c "), result$msg))
      }
    })
    
    # ── Remove user ───────────────────────────────────────────
    observeEvent(input$rem_user, {
      email <- trimws(input$rem_email)
      if (!nzchar(email)) return()
      result <- sheets_remove_user(email)
      if (result$ok) {
        output$rem_result <- renderUI(success_box(tags$strong("\u2713 "), result$msg))
        users_data(sheets_get_users_df())
      } else {
        output$rem_result <- renderUI(warn_box(tags$strong("\u274c "), result$msg))
      }
    })
    
    # ── Users table ───────────────────────────────────────────
    output$users_table <- DT::renderDataTable({
      df <- users_data()
      req(!is.null(df))
      df <- df[!grepl("^REMOVED_", df$email, ignore.case = TRUE), ]
      DT::datatable(df, rownames = FALSE, options = list(pageLength = 10, dom = "ftp"),
                    class = "cell-border compact") %>%
        DT::formatStyle(names(df), backgroundColor = "rgba(7,26,62,0.60)", color = "#8fb0d8") %>%
        DT::formatStyle("email", fontWeight = "bold", color = "#00e5ff")
    })
    
    # ── Login stats ───────────────────────────────────────────
    output$stat_total_logins <- renderUI({
      df <- logins_data()
      if (is.null(df) || nrow(df) == 0) return(mc_stat(0, "Total Logins"))
      mc_stat(nrow(df[df$success == "TRUE", ]), "Total Logins")
    })
    output$stat_unique_users <- renderUI({
      df <- logins_data()
      if (is.null(df) || nrow(df) == 0) return(mc_stat(0, "Unique Users"))
      mc_stat(length(unique(df$email[df$success == "TRUE"])), "Unique Users")
    })
    output$stat_today_logins <- renderUI({
      df <- logins_data()
      if (is.null(df) || nrow(df) == 0 || !"timestamp" %in% names(df))
        return(mc_stat(0, "Logins Today"))
      today <- format(Sys.Date(), "%Y-%m-%d")
      mc_stat(sum(startsWith(as.character(df$timestamp), today) & df$success == "TRUE"), "Logins Today")
    })
    output$stat_denied <- renderUI({
      df <- logins_data()
      if (is.null(df) || nrow(df) == 0) return(mc_stat(0, "Denied Attempts"))
      mc_stat(nrow(df[df$success == "FALSE", ]), "Denied Attempts")
    })
    
    output$login_table <- DT::renderDataTable({
      df <- logins_data()
      if (is.null(df) || !is.data.frame(df) || nrow(df) == 0)
        return(DT::datatable(data.frame(Message = "No login data yet"), rownames = FALSE))
      df <- tail(df[order(as.character(df$timestamp), decreasing = TRUE), ], 50)
      dt <- DT::datatable(df, rownames = FALSE, options = list(pageLength = 8, dom = "ftp"),
                          class = "cell-border compact")
      if ("success" %in% names(df))
        dt <- dt %>% DT::formatStyle("success",
                                     color = DT::styleEqual(c("TRUE","FALSE"), c("#00aa55","#e74c3c")),
                                     fontWeight = "bold")
      dt %>% DT::formatStyle(names(df), backgroundColor = "rgba(7,26,62,0.60)", color = "#8fb0d8")
    })
    
    # ── Login timeline ────────────────────────────────────────
    output$login_timeline <- renderPlotly({
      df <- logins_data()
      if (is.null(df) || !is.data.frame(df) || nrow(df) == 0)
        return(plot_ly() %>% layout(title = list(text = "No login data yet", font = list(color="#cdd9f5"))) %>% dt_theme())
      df <- df[!is.na(df$success) & df$success == "TRUE", ]
      if (nrow(df) == 0)
        return(plot_ly() %>% layout(title = list(text = "No successful logins yet", font = list(color="#cdd9f5"))) %>% dt_theme())
      df$date <- substr(df$timestamp, 1, 10)
      agg <- df %>% dplyr::group_by(date, email) %>% dplyr::summarise(n = n(), .groups = "drop")
      plot_ly(agg, x = ~date, y = ~n, color = ~email, type = "bar") %>%
        layout(barmode = "stack",
               title = list(text = "Daily Login Counts by User", font = list(color = "#cdd9f5")),
               xaxis = list(title = "Date"),
               yaxis = list(title = "Logins")) %>% dt_theme()
    })
    
    # ── Tab engagement ─────────────────────────────────────────
    # Uses filtered_analytics()
    output$tab_engagement <- renderPlotly({
      df <- filtered_analytics()
      sel <- current_filter_label()
      title_suffix <- if (sel == "__all__") ": All Users" else paste0(": ", sel)
      
      if (is.null(df) || !is.data.frame(df) || nrow(df) == 0)
        return(plot_ly() %>% layout(title = list(text = paste("No analytics data yet", title_suffix), font = list(color="#cdd9f5"))) %>% dt_theme())
      
      views <- df[!is.na(df$event_type) & df$event_type == "tab_view", ]
      exits <- df[!is.na(df$event_type) & df$event_type == "tab_exit" &
                    !is.na(df$duration_secs) & nchar(as.character(df$duration_secs)) > 0, ]
      
      if (nrow(views) == 0)
        return(plot_ly() %>% layout(title = list(text = paste("No tab view data yet", title_suffix), font = list(color="#cdd9f5"))) %>% dt_theme())
      
      tab_counts <- views %>% dplyr::group_by(tab) %>% dplyr::summarise(views = n(), .groups = "drop")
      
      if (nrow(exits) > 0) {
        exits$dur <- suppressWarnings(as.numeric(exits$duration_secs))
        avg_dur   <- exits %>% dplyr::group_by(tab) %>%
          dplyr::summarise(avg_secs = mean(dur, na.rm = TRUE), .groups = "drop")
        tab_counts <- dplyr::left_join(tab_counts, avg_dur, by = "tab")
      } else {
        tab_counts$avg_secs <- NA
      }
      
      tab_counts <- tab_counts[order(tab_counts$views, decreasing = TRUE), ]
      
      plot_ly(tab_counts) %>%
        add_trace(x = ~tab, y = ~views, type = "bar", name = "Tab Views",
                  marker = list(color = "#0066cc")) %>%
        add_trace(x = ~tab, y = ~round(tab_counts$avg_secs, 0), type = "scatter",
                  mode = "markers", yaxis = "y2", name = "Avg Time (secs)",
                  marker = list(color = "#00e5ff", size = 10)) %>%
        layout(
          title = list(text = paste("Tab Views & Avg Time", title_suffix), font = list(color = "#cdd9f5")),
          xaxis = list(title = "", tickangle = -30),
          yaxis  = list(title = "Views"),
          yaxis2 = list(title = "Avg seconds", overlaying = "y", side = "right", color = "#00e5ff"),
          barmode = "group"
        ) %>% dt_theme()
    })
    
    # ── Interaction heatmap ────────────────────────────────────
    # Uses filtered_analytics()
    output$interaction_heatmap <- renderPlotly({
      df <- filtered_analytics()
      sel <- current_filter_label()
      title_suffix <- if (sel == "__all__") ": All Users" else paste0(": ", sel)
      
      if (is.null(df) || !is.data.frame(df) || nrow(df) == 0)
        return(plot_ly() %>% layout(title = list(text = paste("No interaction data yet", title_suffix), font = list(color="#cdd9f5"))) %>% dt_theme())
      
      df <- df[!is.na(df$event_type) & df$event_type %in%
                 c("tab_view","box_click","button_click","input_change","plot_interact"), ]
      
      if (nrow(df) == 0)
        return(plot_ly() %>% layout(title = list(text = paste("No interaction data yet", title_suffix), font = list(color="#cdd9f5"))) %>% dt_theme())
      
      heat  <- df %>% dplyr::group_by(email, tab) %>% dplyr::summarise(events = n(), .groups = "drop")
      users <- sort(unique(heat$email))
      tabs  <- sort(unique(heat$tab))
      grid  <- expand.grid(email = users, tab = tabs, stringsAsFactors = FALSE)
      grid  <- dplyr::left_join(grid, heat, by = c("email","tab"))
      grid$events[is.na(grid$events)] <- 0
      z_mat <- matrix(grid$events, nrow = length(users), ncol = length(tabs),
                      byrow = FALSE, dimnames = list(users, tabs))
      
      plot_ly(x = tabs, y = users, z = z_mat, type = "heatmap",
              colorscale = list(c(0,"#020a1a"), c(0.3,"#003d99"), c(0.6,"#0066cc"), c(1,"#00e5ff")),
              text = outer(users, tabs, function(u, t) {
                v <- grid$events[grid$email == u & grid$tab == t]
                if (length(v) == 0) v <- 0
                paste0(u, "\n", t, "\n", v, " events")
              }),
              hoverinfo = "text") %>%
        layout(
          title = list(text = paste("User \u00d7 Tab Interaction Heatmap", title_suffix), font = list(color = "#cdd9f5")),
          xaxis = list(title = "Tab", tickangle = -30),
          yaxis = list(title = "User")
        ) %>% dt_theme()
    })
    
    # ── Top elements ───────────────────────────────────────────
    # Uses filtered_analytics()
    output$top_elements <- renderPlotly({
      df <- filtered_analytics()
      sel <- current_filter_label()
      title_suffix <- if (sel == "__all__") ": All Users" else paste0(": ", sel)
      
      if (is.null(df) || !is.data.frame(df) || nrow(df) == 0)
        return(plot_ly() %>% layout(title = list(text = paste("No interaction data yet", title_suffix), font = list(color="#cdd9f5"))) %>% dt_theme())
      
      df <- df[!is.na(df$event_type) & df$event_type %in%
                 c("box_click","button_click","input_change","plot_interact") &
                 !is.na(df$element) & nchar(as.character(df$element)) > 0, ]
      
      if (nrow(df) == 0)
        return(plot_ly() %>% layout(title = list(text = paste("No element data yet", title_suffix), font = list(color="#cdd9f5"))) %>% dt_theme())
      
      top <- df %>%
        dplyr::group_by(element, event_type) %>%
        dplyr::summarise(n = n(), .groups = "drop") %>%
        dplyr::arrange(dplyr::desc(n)) %>%
        head(15)
      
      colors <- c(button_click = "#00aa55", input_change = "#0066cc",
                  box_click = "#f39c12", plot_interact = "#9b59b6")
      
      plot_ly(top, x = ~n, y = ~reorder(element, n), type = "bar", orientation = "h",
              color = ~event_type,
              colors = unname(colors[names(colors) %in% unique(top$event_type)])) %>%
        layout(
          title = list(text = paste("Top Interacted Elements", title_suffix), font = list(color = "#cdd9f5")),
          xaxis = list(title = "Event Count"),
          yaxis = list(title = ""),
          barmode = "stack"
        ) %>% dt_theme()
    })
    
    # ── Raw analytics table ────────────────────────────────────
    # Uses filtered_analytics()
    output$analytics_table <- DT::renderDataTable({
      df <- filtered_analytics()
      if (is.null(df) || !is.data.frame(df) || nrow(df) == 0)
        return(DT::datatable(data.frame(Message = "No analytics data yet"), rownames = FALSE))
      df <- tail(df[order(as.character(df$timestamp), decreasing = TRUE), ], 100)
      dt <- DT::datatable(df, rownames = FALSE,
                          options = list(pageLength = 8, dom = "ftp"),
                          class = "cell-border compact") %>%
        DT::formatStyle(names(df), backgroundColor = "rgba(7,26,62,0.60)", color = "#8fb0d8")
      if ("event_type" %in% names(df))
        dt <- dt %>% DT::formatStyle("event_type",
                                     color = DT::styleEqual(
                                       c("tab_view","button_click","box_click","session_start","session_end","input_change"),
                                       c("#00e5ff","#00aa55","#f39c12","#adc8ff","#e74c3c","#0099ff")))
      dt
    })
  })
}