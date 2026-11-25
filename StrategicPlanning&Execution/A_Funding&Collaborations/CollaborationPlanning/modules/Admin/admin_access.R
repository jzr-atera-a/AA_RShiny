# ---- module ----------------------------------------------
# id:           admin_access
# name:         Users and access
# icon:         user-shield
# description:  The approved email list (Google Sheet tab allowed_emails), roles, and the sign-in log
# packages:     shiny, DT
# -----------------------------------------------------------

ROLES <- c("Admin" = "admin", "Team member" = "member", "Partner" = "partner")

admin_access_ui <- function(id) {
  ns <- NS(id)
  tagList(
    note("info", "Sign-in works like the VentureDeals app: people type their email, and it must be on this list and active. ",
         "With the Google Sheet connected, the list is the ", tags$code("allowed_emails"), " tab, so you can also edit it there; ",
         "changes reach the app within ", cfg$cache_secs, " seconds. Roles: ", tags$b("admin"), " (everything, Admin needs the code), ",
         tags$b("member"), " (all stages), ", tags$b("partner"), " (outside collaborators; later phases limit them to their own bids)."),
    card("Add or update a person",
      layout_columns(col_widths = c(4, 2, 3, 3),
        textInput(ns("email"), "Email"),
        selectInput(ns("role"), "Role", ROLES, selected = "member"),
        textInput(ns("name"), "Name"),
        textInput(ns("org"), "Organisation")),
      textInput(ns("interests"), "Interests (separate with ;)", width = "100%"),
      div(class = "btn-row",
          actionButton(ns("add"), "Save person", class = "btn-brand"),
          actionButton(ns("deactivate"), "Deactivate selected", class = "btn-ghost"))),
    card("Approved people", DTOutput(ns("users"))),
    card("Recent sign-ins", DTOutput(ns("log"))),
    card("Admin code",
      p(if (IS_WINDOWS) "This app is running on Windows, so Admin opens without a code."
        else "This app is not running on Windows, so Admin asks for the code."),
      p(class = "small muted", "The code comes from the environment variable CP_ADMIN_CODE (default 7818). ",
        "To change it on shinyapps.io: app Settings > Variables, then restart the app.")))
}

admin_access_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    users <- reactive({ ctx$tick(); u <- store_read("allowed_emails"); u[order(u$role, u$email), , drop = FALSE] })

    output$users <- renderDT({
      req(ctx$admin_ok())
      d <- users()[, c("email", "role", "name", "organisation", "active", "added_by", "added_date")]
      datatable(d, rownames = FALSE, selection = "single", options = list(pageLength = 10, dom = "ftip"))
    })

    output$log <- renderDT({
      req(ctx$admin_ok())
      l <- ctx$data$login_log()
      l <- l[order(l$timestamp, decreasing = TRUE), c("timestamp", "email", "success", "detail"), drop = FALSE]
      datatable(utils::head(l, 200), rownames = FALSE, options = list(pageLength = 10, dom = "tip"))
    })

    observeEvent(input$add, {
      req(ctx$admin_ok())
      email <- tolower(trimws(input$email %||% ""))
      if (!grepl("^[^@ ]+@[^@ ]+\\.[^@ ]+$", email)) return(showNotification("Enter a valid email.", type = "warning"))
      all <- store_read("allowed_emails", fresh = TRUE)
      row <- data.frame(email = email, role = input$role, name = input$name %||% "", organisation = input$org %||% "",
                        interests = input$interests %||% "", active = "TRUE", added_by = ctx$user(),
                        added_date = format(Sys.Date()), notes = "", stringsAsFactors = FALSE)
      if (email %in% tolower(all$email)) {
        all <- all[tolower(all$email) != email, , drop = FALSE]
        store_replace("allowed_emails", rbind(all, row), user = ctx$user(), detail = paste("updated", email))
      } else store_append("allowed_emails", row, user = ctx$user())
      ctx$bump()
      showNotification(paste("Saved", email), type = "message")
    })

    observeEvent(input$deactivate, {
      req(ctx$admin_ok())
      i <- input$users_rows_selected
      if (!length(i)) return(showNotification("Select a person in the table first.", type = "warning"))
      email <- users()$email[i]
      if (identical(tolower(email), tolower(ctx$user()))) return(showNotification("You can't deactivate yourself.", type = "warning"))
      all <- store_read("allowed_emails", fresh = TRUE)
      all$active[tolower(all$email) == tolower(email)] <- "FALSE"
      store_replace("allowed_emails", all, user = ctx$user(), detail = paste("deactivated", email))
      ctx$bump()
      showNotification(paste("Deactivated", email), type = "message")
    })
  })
}
