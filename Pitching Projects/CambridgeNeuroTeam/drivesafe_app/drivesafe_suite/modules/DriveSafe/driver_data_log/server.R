# modules/DriveSafe/driver_data_log/server.R
# DriveSafe - Driver Data Log Server
# BigQuery table: atera-2.business_strategy.driver_health_log

driver_data_log_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    teal_mid   <- "#008A82"
    teal_light <- "#00A39A"
    amber      <- "#f39c12"
    red_alert  <- "#e74c3c"
    green_ok   <- "#27ae60"

    driver_names <- c(
      "D001" = "Adams, J",     "D002" = "Patel, R",
      "D003" = "Okafor, C",   "D004" = "Williams, S",
      "D005" = "Hassan, M",   "D006" = "Chen, L",
      "D007" = "Thompson, K", "D008" = "Singh, P"
    )

    # OSA/treatment assignment
    osa_drivers     <- c("D002","D004","D007")
    treated_drivers <- c("D002","D007")

    # ── BigQuery status banner ────────────────────────────────────────────────
    output$bq_status_banner <- renderUI({
      if (isTRUE(api_manager$bq_authenticated)) {
        div(class = "status-success",
          icon("check-circle"),
          tags$strong(" BigQuery connected. "),
          "Records will be written to: ",
          tags$code("atera-2.business_strategy.driver_health_log")
        )
      } else {
        div(class = "status-warning",
          icon("exclamation-triangle"),
          tags$strong(" BigQuery not connected. "),
          "Please authenticate in BigQuery Setup before uploading records. ",
          "Data preview and generation work offline."
        )
      }
    })

    # ── Simulate driver records ───────────────────────────────────────────────
    make_driver_data <- function(drivers, journeys_per, max_hours, groups, seed) {
      set.seed(seed)
      rows <- list()

      for (did in drivers) {
        is_osa     <- did %in% osa_drivers
        is_treated <- did %in% treated_drivers

        group_label <- if (!is_osa) "control" else if (is_treated) "osa_treated" else "osa_untreated"
        if (!group_label %in% groups) next

        for (j in seq_len(journeys_per)) {
          journey_dur  <- round(runif(1, 1, max_hours), 1)
          n_obs        <- max(3, round(journey_dur * 3))
          obs_hours    <- sort(runif(n_obs, 0, journey_dur))
          journey_date <- Sys.Date() - sample(0:30, 1)

          kss  <- pmax(1, pmin(9,
            3 + obs_hours * 0.6 +
            ifelse(is_osa & !is_treated, 1.8, ifelse(is_osa, 0.7, 0)) +
            rnorm(n_obs, 0, 0.6)
          ))
          rt   <- pmax(180, 320 + obs_hours * 18 +
            ifelse(is_osa & !is_treated, 70, ifelse(is_osa, 20, 0)) +
            rnorm(n_obs, 0, 28)
          )
          mw   <- pmax(0, pmin(100,
            18 + obs_hours * 7 +
            ifelse(is_osa & !is_treated, 22, ifelse(is_osa, 8, 0)) +
            rnorm(n_obs, 0, 7)
          ))
          osa_comp <- pmax(0, pmin(100,
            (kss / 9) * 30 + (rt - 200) / 700 * 35 +
            ifelse(is_osa & !is_treated, 18, ifelse(is_osa, 7, 0)) +
            rnorm(n_obs, 0, 3)
          ))
          sleep_q <- pmax(1, pmin(10,
            7 - ifelse(is_osa & !is_treated, 2.5, ifelse(is_osa, 1.0, 0)) +
            rnorm(n_obs, 0, 0.8)
          ))
          speed_var  <- pmax(0, 8 + obs_hours * 1.1 +
            ifelse(is_osa & !is_treated, 4, 0) + rnorm(n_obs, 0, 1.5))
          hard_brake <- pmax(0, round(0.4 + obs_hours * 0.35 +
            ifelse(is_osa & !is_treated, 0.7, 0) + rnorm(n_obs, 0, 0.4)))
          lane_events<- pmax(0, round(0.15 + obs_hours * 0.25 +
            ifelse(is_osa & !is_treated, 0.5, 0) + rnorm(n_obs, 0, 0.25)))
          pvt_lapses <- pmax(0, round(0.2 + obs_hours * 0.5 +
            ifelse(is_osa & !is_treated, 1.2, 0) + rnorm(n_obs, 0, 0.3)))

          for (k in seq_len(n_obs)) {
            rows[[length(rows) + 1]] <- data.frame(
              driver_id       = did,
              driver_name     = driver_names[did],
              osa_group       = group_label,
              cpap_treated    = is_treated,
              journey_id      = paste0(did, "_J", sprintf("%03d", j)),
              journey_date    = as.character(journey_date),
              journey_hour    = round(obs_hours[k], 2),
              journey_duration_h = journey_dur,
              kss_score       = round(kss[k], 2),
              reaction_time_ms= round(rt[k]),
              mind_wander_idx = round(mw[k], 1),
              osa_risk_score  = round(osa_comp[k], 1),
              sleep_quality   = round(sleep_q[k], 2),
              speed_variance  = round(speed_var[k], 2),
              hard_braking_n  = hard_brake[k],
              lane_events_n   = lane_events[k],
              pvt_lapses_n    = pvt_lapses[k],
              recorded_at     = as.character(Sys.time()),
              stringsAsFactors = FALSE
            )
          }
        }
      }

      if (length(rows) == 0) return(NULL)
      do.call(rbind, rows)
    }

    generated_data <- reactiveVal(NULL)

    observeEvent(input$btn_generate, {
      drivers  <- input$gen_drivers
      journeys <- input$gen_journeys %||% 10
      max_h    <- input$gen_journey_hours %||% 8
      groups   <- input$gen_groups
      seed     <- input$gen_seed %||% 42

      if (is.null(drivers) || length(drivers) == 0) {
        showNotification("Please select at least one driver.", type = "warning")
        return()
      }
      if (is.null(groups) || length(groups) == 0) {
        showNotification("Please select at least one group.", type = "warning")
        return()
      }

      withProgress(message = "Generating driver condition data...", value = 0.3, {
        df <- make_driver_data(drivers, journeys, max_h, groups, seed)
        setProgress(0.9)
        generated_data(df)
        setProgress(1.0)
      })

      if (!is.null(generated_data())) {
        showNotification(
          paste0(nrow(generated_data()), " records generated for ",
                 length(drivers), " driver(s)."),
          type = "message", duration = 4
        )
      }
    })

    # ── Preview Value Boxes ───────────────────────────────────────────────────
    output$prev_total_rows <- renderValueBox({
      d <- generated_data()
      valueBox(if (is.null(d)) 0 else nrow(d),
        "Total Records", icon = icon("list"), color = "aqua")
    })

    output$prev_drivers <- renderValueBox({
      d <- generated_data()
      valueBox(if (is.null(d)) 0 else length(unique(d$driver_id)),
        "Drivers", icon = icon("users"), color = "blue")
    })

    output$prev_osa_pct <- renderValueBox({
      d <- generated_data()
      if (is.null(d)) return(valueBox("N/A", "OSA %", icon = icon("bed"), color = "yellow"))
      pct <- round(mean(d$osa_group %in% c("osa_untreated","osa_treated")) * 100)
      valueBox(paste0(pct, "%"), "Records in OSA Groups",
        icon = icon("bed"), color = if (pct > 50) "red" else "yellow")
    })

    output$prev_mean_kss <- renderValueBox({
      d <- generated_data()
      if (is.null(d)) return(valueBox("N/A", "Mean KSS", icon = icon("eye"), color = "green"))
      val <- round(mean(d$kss_score, na.rm = TRUE), 2)
      valueBox(val, "Mean KSS Score",
        icon = icon("eye"), color = if (val > 6) "red" else if (val > 4) "yellow" else "green")
    })

    output$preview_table <- DT::renderDataTable({
      d <- generated_data()
      if (is.null(d)) {
        return(DT::datatable(
          data.frame(Info = "Click 'Generate Simulated Data' to preview records."),
          options = list(dom = "t"), rownames = FALSE
        ))
      }
      DT::datatable(d,
        options = list(
          pageLength = 10, scrollX = TRUE,
          columnDefs = list(list(className = "dt-left", targets = "_all"))
        ),
        rownames = FALSE,
        class = "table table-striped table-hover"
      ) |>
        DT::formatStyle("kss_score",
          backgroundColor = DT::styleInterval(c(4, 7),
            c("#d4edda","#fff3cd","#f8d7da"))
        ) |>
        DT::formatStyle("osa_risk_score",
          backgroundColor = DT::styleInterval(c(30, 55),
            c("#d4edda","#fff3cd","#f8d7da"))
        )
    })

    # ── BigQuery upload ───────────────────────────────────────────────────────
    observeEvent(input$btn_upload, {
      d <- generated_data()
      if (is.null(d)) {
        showNotification("Generate data first before uploading.", type = "warning")
        return()
      }
      if (!isTRUE(api_manager$bq_authenticated)) {
        showNotification("BigQuery not connected. Please authenticate first.", type = "error")
        return()
      }

      withProgress(message = "Uploading to BigQuery...", value = 0.2, {
        tryCatch({
          setProgress(0.4, detail = "Connecting...")

          # Add sequential IDs
          start_id <- tryCatch({
            res <- api_manager$bq_query(
              "SELECT COALESCE(MAX(id), 0) as max_id FROM `atera-2.business_strategy.driver_health_log`"
            )
            as.integer(res$max_id) + 1L
          }, error = function(e) 1L)

          d$id         <- seq(start_id, start_id + nrow(d) - 1L)
          d$created_at <- Sys.time()
          d$cpap_treated <- as.character(d$cpap_treated)

          setProgress(0.6, detail = "Writing rows...")

          table_ref <- bigrquery::bq_table(
            "atera-2", "business_strategy", "driver_health_log"
          )
          bigrquery::bq_table_upload(table_ref, d,
            create_disposition = "CREATE_IF_NEEDED",
            write_disposition  = "WRITE_APPEND"
          )

          api_manager$trigger_state_update_driver()
          setProgress(1.0, detail = "Done")

          showNotification(
            paste0(nrow(d), " records uploaded to driver_health_log."),
            type = "message", duration = 5
          )
        }, error = function(e) {
          showNotification(paste0("Upload failed: ", e$message), type = "error", duration = 8)
        })
      })
    })

    output$upload_status <- renderUI({ NULL })

    # ── Browse: load from BigQuery ────────────────────────────────────────────
    browse_data <- reactiveVal(NULL)

    observeEvent(input$btn_refresh, {
      if (!isTRUE(api_manager$bq_authenticated)) {
        browse_data(NULL)
        showNotification("BigQuery not connected.", type = "warning")
        return()
      }
      max_r  <- input$browse_max %||% 200
      drv    <- input$browse_driver
      grp    <- input$browse_group

      withProgress(message = "Loading records from BigQuery...", value = 0.4, {
        tryCatch({
          where_clauses <- character(0)
          if (!is.null(drv) && nchar(drv) > 0)
            where_clauses <- c(where_clauses, paste0("driver_id = '", drv, "'"))
          if (!is.null(grp) && nchar(grp) > 0)
            where_clauses <- c(where_clauses, paste0("osa_group = '", grp, "'"))

          where_sql <- if (length(where_clauses) > 0)
            paste0("WHERE ", paste(where_clauses, collapse = " AND "))
          else ""

          q <- sprintf(
            "SELECT * FROM `atera-2.business_strategy.driver_health_log` %s ORDER BY created_at DESC LIMIT %d",
            where_sql, max_r
          )
          df <- api_manager$bq_query(q)
          browse_data(df)
          setProgress(1.0)
          showNotification(paste0(nrow(df), " records loaded."),
            type = "message", duration = 3)
        }, error = function(e) {
          browse_data(NULL)
          showNotification(paste0("Query failed: ", e$message), type = "error", duration = 6)
        })
      })
    })

    output$browse_status <- renderUI({
      d <- browse_data()
      if (!isTRUE(api_manager$bq_authenticated)) {
        div(class = "status-warning",
          icon("exclamation-triangle"),
          " Connect to BigQuery first, then click Refresh to load records.")
      } else if (is.null(d)) {
        div(class = "status-info",
          icon("info-circle"),
          " Click Refresh to load records from BigQuery.")
      } else {
        div(class = "status-success",
          icon("check-circle"),
          paste0(" Showing ", nrow(d), " records from driver_health_log."))
      }
    })

    output$browse_table <- DT::renderDataTable({
      d <- browse_data()
      if (is.null(d) || nrow(d) == 0) {
        return(DT::datatable(
          data.frame(Info = "No records loaded. Click Refresh."),
          options = list(dom = "t"), rownames = FALSE
        ))
      }
      DT::datatable(d,
        options  = list(pageLength = 15, scrollX = TRUE),
        rownames = FALSE,
        class    = "table table-striped table-hover"
      ) |>
        DT::formatStyle("kss_score",
          backgroundColor = DT::styleInterval(c(4, 7),
            c("#d4edda","#fff3cd","#f8d7da"))
        )
    })

    output$btn_download <- downloadHandler(
      filename = function() {
        paste0("driver_health_log_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        d <- browse_data()
        if (is.null(d)) d <- data.frame()
        write.csv(d, file, row.names = FALSE)
      }
    )

    # Populate browse driver dropdown from generated data
    observe({
      d <- generated_data()
      if (!is.null(d)) {
        drvs <- sort(unique(d$driver_id))
        drvs_named <- setNames(drvs, paste0(drvs, " - ", driver_names[drvs]))
        updateSelectInput(session, "browse_driver",
          choices  = c("All" = "", drvs_named),
          selected = ""
        )
      }
    })

  })
}

`%||%` <- function(x, y) if (is.null(x)) y else x
