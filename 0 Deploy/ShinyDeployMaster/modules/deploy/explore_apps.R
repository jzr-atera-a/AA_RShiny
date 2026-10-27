# modules/deploy/explore_apps.R
# Explore Apps: the deploy registry as a table. Shows the local text file by
# default and switches to the BigQuery table once connected. The Status column
# (ticked = Active, unticked = Archived) can be changed per row. A "Save the
# Changes" button appears only when something differs from the saved state.

explore_apps_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "meta-hero",
        tags$h1("\U0001f9ed Explore Apps"),
        tags$h2("Every shinyapps.io app in the deploy registry: live link, last deployment date and status"),
        div(span(class = "hero-badge", "BigQuery - deploy_apps"),
            span(class = "hero-badge", "Local text backup"),
            span(class = "hero-badge", "Active / Archived"))
    ),
    fluidRow(
      box(title = "App Registry", status = "primary", solidHeader = TRUE, width = 12,
          uiOutput(ns("source_info")),
          uiOutput(ns("apps_table")),
          br(),
          fluidRow(
            column(7, uiOutput(ns("save_bar"))),
            column(5, div(style = "text-align:right;",
                          actionButton(ns("btn_reload"), tagList(icon("sync"), " Reload"))))
          )
      )
    )
  )
}

explore_apps_server <- function(id, apps_state, api_manager, refresh_apps) {
  moduleServer(id, function(input, output, session) {

    ns <- session$ns

    # Saved state of the table (changes whenever refresh_apps() runs)
    apps_df <- reactive({
      apps_state$stamp
      apps_state$df
    })

    output$source_info <- renderUI({
      apps_state$stamp
      note <- apps_state$note
      div(class = "tip-box", HTML(paste0(
        "<strong>Showing:</strong> ", htmltools::htmlEscape(apps_state$source %||% "-"),
        if (!is.null(note))
          paste0("<br><span style='color:#B45309;'>", htmltools::htmlEscape(note), "</span>")
        else ""
      )))
    })

    output$apps_table <- renderUI({
      d <- apps_df()
      if (is.null(d) || !nrow(d))
        return(div(class = "warn-box", "No apps in the registry yet. Deploy one from the Deploy App tab."))

      rows <- lapply(seq_len(nrow(d)), function(i) {
        tags$tr(
          tags$td(tags$code(d$title_of_app[i])),
          tags$td(tags$a(href = d$active_url[i], target = "_blank", d$active_url[i])),
          tags$td(d$Updated_Date[i]),
          tags$td(class = "status-cell",
                  checkboxInput(ns(paste0("st_", i)), label = NULL,
                                value = identical(d$status[i], "Active")))
        )
      })

      tags$div(class = "apps-table-wrap",
        tags$table(class = "apps-table",
          tags$thead(tags$tr(
            tags$th("title_of_app"), tags$th("active_url"),
            tags$th("Updated_Date"), tags$th("Status (ticked = Active)")
          )),
          tags$tbody(rows)
        ))
    })

    # Current ticks compared with the saved statuses
    pending <- reactive({
      d <- apps_df()
      if (is.null(d) || !nrow(d)) return(NULL)
      cur <- vapply(seq_len(nrow(d)), function(i) {
        v <- input[[paste0("st_", i)]]
        if (is.null(v)) NA else isTRUE(v)
      }, logical(1))
      was_active <- d$status == "Active"
      list(d = d, cur = cur, changed = which(!is.na(cur) & cur != was_active))
    })

    output$save_bar <- renderUI({
      p <- pending()
      n <- if (is.null(p)) 0L else length(p$changed)
      if (n == 0L)
        return(div(class = "tip-box",
                   "Untick an app to archive it, tick it to reactivate it. The Save button appears when something changes."))
      tagList(
        div(class = "tip-box", HTML(sprintf("<strong>%d unsaved change(s)</strong>", n))),
        if (isTRUE(api_manager$bq_authenticated))
          actionButton(ns("btn_save"), tagList(icon("save"), " Save the Changes"), class = "btn-success")
        else
          div(class = "warn-box",
              "BigQuery is not connected, so changes cannot be saved. Connect under APIs -> BigQuery.")
      )
    })

    observeEvent(input$btn_save, {
      p <- pending()
      if (is.null(p) || !length(p$changed)) return()
      if (!isTRUE(api_manager$bq_authenticated)) {
        showNotification("BigQuery is not connected. Nothing was saved.", type = "error")
        return()
      }
      idx <- p$changed
      res <- registry_save_status(api_manager,
                                  p$d$title_of_app[idx],
                                  ifelse(p$cur[idx], "Active", "Archived"))
      if (isTRUE(res$ok)) {
        refresh_apps()
        showNotification(res$msg, type = "message", duration = 8)
      } else {
        showNotification(paste("Save failed:", res$msg), type = "error", duration = 12)
      }
    })

    observeEvent(input$btn_reload, refresh_apps())
  })
}
