# modules/visualizations_events/server.R

visualizations_events_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    viz_data <- reactiveVal(NULL)

    # Category colour palette
    category_colors <- c(
      "Music"    = "#e74c3c", "Tech"     = "#3498db", "Art"      = "#9b59b6",
      "Food"     = "#e67e22", "Sports"   = "#27ae60", "Family"   = "#f39c12",
      "Business" = "#1abc9c", "Health"   = "#2ecc71", "Film"     = "#34495e",
      "Comedy"   = "#f1c40f", "Other"    = "#95a5a6"
    )
    get_color <- function(cat) {
      if (!is.null(cat) && cat %in% names(category_colors)) category_colors[[cat]] else "#95a5a6"
    }

    # ── Cascade: Country → City → Category → Subcategory + Scan Date ──
    viz_taxonomy <- reactive({
      api_manager$state_trigger()
      if (!api_manager$bq_authenticated) {
        return(data.frame(category  = character(), subcategory = character(),
                           city      = character(), country     = character(),
                           scan_date = character(), stringsAsFactors = FALSE))
      }
      tryCatch(api_manager$bq_get_taxonomy(), error = function(e) {
        data.frame(category  = character(), subcategory = character(),
                   city      = character(), country     = character(),
                   scan_date = character(), stringsAsFactors = FALSE)
      })
    })

    observeEvent(viz_taxonomy(), {
      tax       <- viz_taxonomy()
      countries <- sort(unique(tax$country[nchar(trimws(tax$country)) > 0]))
      updateSelectInput(session, "viz_country",
                        choices = c("All" = "", setNames(countries, countries)), selected = "")
      scan_dates <- sort(unique(tax$scan_date[nchar(trimws(tax$scan_date)) > 0]), decreasing = TRUE)
      updateSelectInput(session, "viz_scan_date",
                        choices = c("All" = "", setNames(scan_dates, scan_dates)), selected = "")
    }, ignoreNULL = FALSE)

    observeEvent(input$viz_country, {
      tax <- viz_taxonomy()
      cities <- if (is.null(input$viz_country) || input$viz_country == "") {
        sort(unique(tax$city[nchar(trimws(tax$city)) > 0]))
      } else {
        sort(unique(tax$city[tax$country == input$viz_country & nchar(trimws(tax$city)) > 0]))
      }
      updateSelectInput(session, "viz_city",
                        choices = c("All" = "", setNames(cities, cities)), selected = "")
    }, ignoreInit = TRUE)

    observeEvent(input$viz_city, {
      tax <- viz_taxonomy()
      sub <- tax
      if (!is.null(input$viz_country) && input$viz_country != "") sub <- sub[sub$country == input$viz_country, ]
      if (!is.null(input$viz_city)    && input$viz_city    != "") sub <- sub[sub$city    == input$viz_city,    ]
      cats <- sort(unique(sub$category[nchar(trimws(sub$category)) > 0]))
      updateSelectInput(session, "viz_category",
                        choices = c("All" = "", setNames(cats, cats)), selected = "")
    }, ignoreInit = TRUE)

    observeEvent(input$viz_category, {
      tax <- viz_taxonomy()
      sub <- tax
      if (!is.null(input$viz_country)  && input$viz_country  != "") sub <- sub[sub$country  == input$viz_country,  ]
      if (!is.null(input$viz_city)     && input$viz_city     != "") sub <- sub[sub$city     == input$viz_city,     ]
      if (!is.null(input$viz_category) && input$viz_category != "") sub <- sub[sub$category == input$viz_category, ]
      subs <- sort(unique(sub$subcategory[nchar(trimws(sub$subcategory)) > 0]))
      updateSelectInput(session, "viz_subcategory",
                        choices = c("All" = "", setNames(subs, subs)), selected = "")
    }, ignoreInit = TRUE)

    # ── Load Visualizations ───────────────────────────────────
    observeEvent(input$load_viz, {
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Loading events...")
      })

      tryCatch({
        where_clauses <- c()
        if (!is.null(input$viz_country)     && input$viz_country     != "")
          where_clauses <- c(where_clauses, sprintf("country = '%s'",     safe_sql_escape(input$viz_country)))
        if (!is.null(input$viz_city)        && input$viz_city        != "")
          where_clauses <- c(where_clauses, sprintf("city = '%s'",        safe_sql_escape(input$viz_city)))
        if (!is.null(input$viz_category)    && input$viz_category    != "")
          where_clauses <- c(where_clauses, sprintf("category = '%s'",    safe_sql_escape(input$viz_category)))
        if (!is.null(input$viz_subcategory) && input$viz_subcategory != "")
          where_clauses <- c(where_clauses, sprintf("subcategory = '%s'", safe_sql_escape(input$viz_subcategory)))
        if (!is.null(input$viz_scan_date)   && input$viz_scan_date   != "")
          where_clauses <- c(where_clauses, sprintf("scan_date = '%s'",   safe_sql_escape(input$viz_scan_date)))

        if (is.null(input$viz_scan_date) || input$viz_scan_date == "") {
          date_from <- as.character(input$date_range[1])
          date_to   <- as.character(input$date_range[2])
          where_clauses <- c(where_clauses,
                             sprintf("event_date >= '%s'", date_from),
                             sprintf("event_date <= '%s'", date_to))
        }

        where_sql <- if (length(where_clauses) > 0)
          paste("WHERE", paste(where_clauses, collapse = " AND ")) else ""

        query <- sprintf("SELECT * FROM `%s` %s ORDER BY event_date ASC",
                         api_manager$bq_full_table_id, where_sql)
        data  <- api_manager$bq_query(query)

        if (nrow(data) == 0) {
          output$status <- renderUI({
            tags$div(class = "status-warning",
                     tags$i(class = "fa fa-exclamation-triangle"), " No events found with these filters")
          })
          return()
        }

        viz_data(data)

        # ── Summary value boxes ──────────────────────────────
        output$total_events <- renderValueBox({
          valueBox(nrow(data), "Total Events", icon = icon("calendar"), color = "aqua")
        })
        output$total_cities <- renderValueBox({
          valueBox(length(unique(data$city)), "Cities", icon = icon("city"), color = "blue")
        })
        output$total_categories <- renderValueBox({
          valueBox(length(unique(data$category)), "Categories", icon = icon("tags"), color = "green")
        })
        upcoming <- sum(as.Date(data$event_date) >= Sys.Date(), na.rm = TRUE)
        output$upcoming_events <- renderValueBox({
          valueBox(upcoming, "Upcoming", icon = icon("clock"), color = "yellow")
        })

        # ── TAB 1: EVENT CARDS ───────────────────────────────
        output$event_cards <- renderUI({
          cards <- lapply(seq_len(nrow(data)), function(i) {
            ev  <- data[i, ]
            col <- get_color(as.character(ev$category))

            # Build each metadata line only if value exists
            val <- function(x) {
              v <- as.character(x)
              !is.na(v) && nchar(trimws(v)) > 0 && tolower(trimws(v)) != "n/a"
            }

            date_str <- if (val(ev$event_date)) {
              paste0("📅 ", ev$event_date,
                     if (val(ev$event_time)) paste0(" at ", ev$event_time) else "")
            } else ""

            venue_str <- if (val(ev$venue_name)) paste0("📍 ", ev$venue_name) else ""

            # Address with Google Maps hyperlink
            addr_ui <- if (val(ev$address)) {
              maps_url <- paste0(
                "https://www.google.com/maps/search/?api=1&query=",
                utils::URLencode(as.character(ev$address), reserved = TRUE)
              )
              tags$p(style = "color:#666; font-size:0.85em; margin:2px 0;",
                     "🗺 ",
                     tags$a(href = maps_url, target = "_blank",
                            style = "color:#008A82; text-decoration:underline;",
                            as.character(ev$address)))
            } else NULL
            price_str <- if (val(ev$price_range)) paste0("💰 ", ev$price_range) else ""
            org_str   <- if (val(ev$organiser))   paste0("🏢 Organiser: ", ev$organiser) else ""

            # Ticket URL
            ticket_ui <- if (val(ev$ticket_url)) {
              tags$a(href = as.character(ev$ticket_url), target = "_blank",
                     class = "btn btn-sm btn-info",
                     style = "margin-right:6px; margin-top:6px;",
                     icon("ticket-alt"), " Buy Tickets")
            } else NULL

            # Source URL
            source_ui <- if (val(ev$source_url)) {
              tags$a(href = as.character(ev$source_url), target = "_blank",
                     class = "btn btn-sm btn-default",
                     style = "margin-top:6px;",
                     icon("external-link-alt"), " Event Source")
            } else NULL

            # Extra info
            extra_ui <- if (val(ev$extra_info)) {
              tags$div(style = "margin-top:8px; padding:8px; background:#f8f9fa;
                                border-left:3px solid #aaa; border-radius:4px;
                                font-size:0.85em; color:#555;",
                       tags$strong("ℹ️ Notes: "), as.character(ev$extra_info))
            } else NULL

            # City / country tag
            location_tag <- paste(
              c(if (val(ev$city))    as.character(ev$city)    else NULL,
                if (val(ev$country)) as.character(ev$country) else NULL),
              collapse = ", "
            )

            div(
              style = paste0(
                "background:white; border-radius:10px; padding:18px 20px; margin-bottom:16px;",
                "box-shadow:0 3px 12px rgba(0,0,0,0.1); border-left:5px solid ", col, ";"
              ),

              # Header row: title + category badge
              fluidRow(
                column(9,
                       tags$h4(style = "margin:0 0 6px 0; color:#002C3C; font-weight:700;",
                               as.character(ev$event_name))
                ),
                column(3, style = "text-align:right;",
                       tags$span(
                         style = paste0("background:", col, "; color:white; padding:3px 10px;",
                                        "border-radius:12px; font-size:0.8em; font-weight:600;"),
                         as.character(ev$category)
                       ),
                       if (val(ev$subcategory)) {
                         tags$span(
                           style = "color:#777; font-size:0.8em; display:block; margin-top:3px;",
                           as.character(ev$subcategory)
                         )
                       }
                )
              ),

              # Location tag
              if (nchar(location_tag) > 0) {
                tags$p(style = "color:#008A82; font-size:0.85em; margin:2px 0 8px 0; font-weight:600;",
                       icon("globe"), " ", location_tag)
              },

              tags$hr(style = "margin:8px 0;"),

              # Metadata
              tags$p(style = "color:#444; font-size:0.9em; margin:4px 0;", date_str),
              if (nchar(venue_str) > 0) tags$p(style = "color:#444; font-size:0.9em; margin:4px 0;", venue_str),
              addr_ui,
              if (nchar(price_str) > 0) tags$p(style = "color:#27ae60; font-size:0.9em; margin:4px 0; font-weight:600;", price_str),
              if (nchar(org_str)   > 0) tags$p(style = "color:#666; font-size:0.85em; margin:4px 0;", org_str),

              tags$hr(style = "margin:8px 0;"),

              # Description
              tags$p(style = "color:#333; font-size:0.95em; line-height:1.65; margin:6px 0;",
                     as.character(ev$description)),

              # Extra info
              extra_ui,

              # Action buttons
              if (!is.null(ticket_ui) || !is.null(source_ui)) {
                div(style = "margin-top:6px;", ticket_ui, source_ui)
              }
            )
          })

          tagList(
            tags$p(style = "color:#666; font-size:0.85em; margin-bottom:12px;",
                   sprintf("Showing %d events — scroll to browse all", nrow(data))),
            do.call(tagList, cards)
          )
        })

        # ── TAB 2: CALENDAR ──────────────────────────────────
        output$calendar_html <- renderUI({
          selected_month <- input$cal_month
          if (is.null(selected_month) || nchar(selected_month) == 0)
            selected_month <- format(Sys.Date(), "%Y-%m")

          year      <- as.integer(substr(selected_month, 1, 4))
          month_num <- as.integer(substr(selected_month, 6, 7))
          first_day <- as.Date(paste0(year, "-", sprintf("%02d", month_num), "-01"))
          last_day  <- as.Date(format(first_day + 31, "%Y-%m-01")) - 1
          days_in_month <- as.integer(last_day - first_day) + 1

          month_events <- data[!is.na(data$event_date) &
                                 as.Date(data$event_date) >= first_day &
                                 as.Date(data$event_date) <= last_day, ]

          html <- '<style>
            .cal-grid{display:grid;grid-template-columns:repeat(7,1fr);gap:4px;}
            .cal-header{font-weight:bold;text-align:center;padding:8px 0;background:#002C3C;color:white;border-radius:4px;font-size:.85em;}
            .cal-day{min-height:90px;background:#f8f9fa;border-radius:6px;padding:6px;border:1px solid #e0e0e0;}
            .cal-day.today{border:2px solid #008A82;background:#e8f5f4;}
            .cal-day.empty{background:#eee;opacity:.4;}
            .cal-day-num{font-weight:bold;font-size:.9em;color:#002C3C;margin-bottom:4px;}
            .cal-event{color:white;border-radius:4px;padding:2px 5px;margin:2px 0;
                       font-size:.75em;overflow:hidden;white-space:nowrap;text-overflow:ellipsis;}
          </style>'
          html <- paste0(html, '<div style="font-size:1.4em;font-weight:bold;color:#002C3C;margin-bottom:12px;text-align:center;">',
                         format(first_day, "%B %Y"), '</div><div class="cal-grid">')

          for (d in c("Mon","Tue","Wed","Thu","Fri","Sat","Sun"))
            html <- paste0(html, '<div class="cal-header">', d, '</div>')

          start_dow <- as.integer(format(first_day, "%u"))
          for (i in seq_len(start_dow - 1)) html <- paste0(html, '<div class="cal-day empty"></div>')

          for (d in seq_len(days_in_month)) {
            this_date  <- first_day + (d - 1)
            is_today   <- this_date == Sys.Date()
            day_events <- month_events[!is.na(month_events$event_date) &
                                         as.Date(month_events$event_date) == this_date, ]
            html <- paste0(html, '<div class="cal-day', if (is_today) ' today' else '', '">',
                           '<div class="cal-day-num">', d, '</div>')
            if (nrow(day_events) > 0) {
              for (j in seq_len(min(nrow(day_events), 3))) {
                ev  <- day_events[j, ]
                col <- get_color(as.character(ev$category))
                html <- paste0(html, '<div class="cal-event" style="background:', col, ';" title="',
                               htmltools::htmlEscape(as.character(ev$event_name)), '">',
                               htmltools::htmlEscape(substr(as.character(ev$event_name), 1, 22)), '</div>')
              }
              if (nrow(day_events) > 3)
                html <- paste0(html, '<div style="font-size:.7em;color:#666;">+', nrow(day_events)-3, ' more</div>')
            }
            html <- paste0(html, '</div>')
          }
          end_dow <- as.integer(format(last_day, "%u"))
          if (end_dow < 7)
            for (i in seq_len(7 - end_dow)) html <- paste0(html, '<div class="cal-day empty"></div>')
          HTML(paste0(html, '</div>'))
        })

        # ── TAB 3: CHARTS ────────────────────────────────────
        output$category_chart <- plotly::renderPlotly({
          cat_counts <- table(data$category)
          df_cats    <- data.frame(category = names(cat_counts),
                                    count    = as.integer(cat_counts),
                                    stringsAsFactors = FALSE)
          df_cats <- df_cats[order(df_cats$count, decreasing = TRUE), ]
          colors  <- sapply(df_cats$category, get_color)
          plotly::plot_ly(df_cats, x = ~count, y = ~reorder(category, count),
                          type = "bar", orientation = "h",
                          marker = list(color = colors)) %>%
            plotly::layout(
              title  = list(text = "Events by Category", font = list(size = 14)),
              xaxis  = list(title = "Number of Events"),
              yaxis  = list(title = ""),
              margin = list(l = 100),
              plot_bgcolor  = "rgba(0,0,0,0)",
              paper_bgcolor = "rgba(0,0,0,0)"
            )
        })

        output$timeline_chart <- plotly::renderPlotly({
          date_data <- data[!is.na(data$event_date) & nchar(as.character(data$event_date)) >= 7, ]
          if (nrow(date_data) == 0)
            return(plotly::plot_ly() %>% plotly::layout(title = "No dated events"))
          date_data$week <- format(as.Date(date_data$event_date), "%Y-%W")
          weekly <- aggregate(event_name ~ week + category, data = date_data, FUN = length)
          names(weekly)[3] <- "count"
          weekly$week_date <- as.Date(paste0(weekly$week, "-1"), format = "%Y-%W-%u")
          plotly::plot_ly(weekly, x = ~week_date, y = ~count, color = ~category,
                          colors = unlist(category_colors[unique(weekly$category)]),
                          type = "bar") %>%
            plotly::layout(
              barmode = "stack",
              title   = list(text = "Events by Week", font = list(size = 14)),
              xaxis   = list(title = "Week", type = "date"),
              yaxis   = list(title = "Count"),
              legend  = list(orientation = "h", y = -0.2),
              plot_bgcolor  = "rgba(0,0,0,0)",
              paper_bgcolor = "rgba(0,0,0,0)"
            )
        })


        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   sprintf(" Loaded %d events across %d cities",
                           nrow(data), length(unique(data$city))))
        })
        showNotification("✓ Visualizations loaded!", type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    # Calendar refresh on month change
    observeEvent(input$cal_month, {
      data <- viz_data()
      if (is.null(data)) return()
      selected_month <- input$cal_month
      if (is.null(selected_month) || nchar(selected_month) == 0) return()

      year      <- as.integer(substr(selected_month, 1, 4))
      month_num <- as.integer(substr(selected_month, 6, 7))
      first_day <- as.Date(paste0(year, "-", sprintf("%02d", month_num), "-01"))
      last_day  <- as.Date(format(first_day + 31, "%Y-%m-01")) - 1

      month_events <- data[!is.na(data$event_date) &
                             as.Date(data$event_date) >= first_day &
                             as.Date(data$event_date) <= last_day, ]

      output$calendar_html <- renderUI({
        days_in_month <- as.integer(last_day - first_day) + 1
        html <- paste0('<div style="font-size:1.4em;font-weight:bold;color:#002C3C;margin-bottom:12px;text-align:center;">',
                       format(first_day, "%B %Y"), '</div>')
        html <- paste0(html, '<style>
          .cal-grid{display:grid;grid-template-columns:repeat(7,1fr);gap:4px;}
          .cal-header{font-weight:bold;text-align:center;padding:8px 0;background:#002C3C;color:white;border-radius:4px;font-size:.85em;}
          .cal-day{min-height:90px;background:#f8f9fa;border-radius:6px;padding:6px;border:1px solid #e0e0e0;}
          .cal-day.today{border:2px solid #008A82;background:#e8f5f4;}
          .cal-day.empty{background:#eee;opacity:.4;}
          .cal-day-num{font-weight:bold;font-size:.9em;color:#002C3C;margin-bottom:4px;}
          .cal-event{color:white;border-radius:4px;padding:2px 5px;margin:2px 0;
                     font-size:.75em;overflow:hidden;white-space:nowrap;text-overflow:ellipsis;}
        </style><div class="cal-grid">')

        for (d in c("Mon","Tue","Wed","Thu","Fri","Sat","Sun"))
          html <- paste0(html, '<div class="cal-header">', d, '</div>')
        start_dow <- as.integer(format(first_day, "%u"))
        for (i in seq_len(start_dow - 1)) html <- paste0(html, '<div class="cal-day empty"></div>')
        for (d in seq_len(days_in_month)) {
          this_date  <- first_day + (d - 1)
          is_today   <- this_date == Sys.Date()
          day_events <- month_events[!is.na(month_events$event_date) &
                                       as.Date(month_events$event_date) == this_date, ]
          html <- paste0(html, '<div class="cal-day', if (is_today) ' today' else '', '">',
                         '<div class="cal-day-num">', d, '</div>')
          if (nrow(day_events) > 0) {
            for (j in seq_len(min(nrow(day_events), 3))) {
              ev  <- day_events[j, ]
              col <- get_color(as.character(ev$category))
              html <- paste0(html, '<div class="cal-event" style="background:', col, ';">',
                             htmltools::htmlEscape(substr(as.character(ev$event_name), 1, 22)), '</div>')
            }
            if (nrow(day_events) > 3)
              html <- paste0(html, '<div style="font-size:.7em;color:#666;">+', nrow(day_events)-3, ' more</div>')
          }
          html <- paste0(html, '</div>')
        }
        end_dow <- as.integer(format(last_day, "%u"))
        if (end_dow < 7)
          for (i in seq_len(7 - end_dow)) html <- paste0(html, '<div class="cal-day empty"></div>')
        HTML(paste0(html, '</div>'))
      })
    }, ignoreInit = TRUE)

    # ── Default outputs ───────────────────────────────────────
    output$status          <- renderUI({ tags$div() })
    output$event_cards     <- renderUI({
      tags$div(style = "color:#999; padding:20px; text-align:center;",
               tags$i(class = "fa fa-calendar fa-2x", style = "margin-bottom:10px; display:block;"),
               "Set your filters and click Load Visualizations to see events here.")
    })
    output$calendar_html   <- renderUI({
      tags$div(style = "color:#999; padding:20px;", "Load visualizations to see the calendar.")
    })

    output$category_chart  <- plotly::renderPlotly({ plotly::plot_ly() })
    output$timeline_chart  <- plotly::renderPlotly({ plotly::plot_ly() })
    output$total_events    <- renderValueBox({ valueBox(0, "Total Events",    icon = icon("calendar"),  color = "aqua")   })
    output$total_cities    <- renderValueBox({ valueBox(0, "Cities",          icon = icon("city"),      color = "blue")   })
    output$total_categories<- renderValueBox({ valueBox(0, "Categories",      icon = icon("tags"),      color = "green")  })
    output$upcoming_events <- renderValueBox({ valueBox(0, "Upcoming",        icon = icon("clock"),     color = "yellow") })

    session$onSessionEnded(function() {})
  })
}
