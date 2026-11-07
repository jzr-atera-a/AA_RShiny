# ---- Sign-in by invited email (checked against the Users tab) ----------------------
# Auth is OFF by default (Settings > auth_required = false). When it is on, the
# full-screen gate is shown until the visitor's email matches an active user.

mod_auth_ui <- function(id) {
  ns <- NS(id)
  div(class = "gate",
    div(class = "gate-card",
      tags$img(src = "mark.png", class = "gate-logo", alt = ""),
      div(class = "eyebrow", "Invite-only workspace"),
      h2(APP_NAME),
      p(class = "lead", "Enter the email address you were invited with to join the team's grant shortlist."),
      textInput(ns("email"), NULL, placeholder = "you@organisation.com", width = "100%"),
      actionButton(ns("signin"), "Continue", class = "btn-brand w-100"),
      uiOutput(ns("msg")),
      hr(),
      p(class = "small muted", "Not on the list yet? Add your name and ask for an invite:"),
      layout_columns(col_widths = c(7, 5),
        textInput(ns("req_name"), NULL, placeholder = "Your name", width = "100%"),
        actionButton(ns("request"), "Request access", class = "btn-ghost w-100"))
    ))
}

mod_auth_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    msg <- reactiveVal(NULL)
    output$msg <- renderUI(msg())

    observeEvent(input$signin, {
      em <- tolower(trimws(input$email))
      u  <- ctx$data$users()
      row <- u[tolower(u$email) == em, , drop = FALSE]
      if (nzchar(em) && nrow(row) == 1 && toupper(row$active) %in% c("TRUE", "YES", "1", "")) {
        ctx$user$email  <- em
        ctx$user$name   <- row$name %||% sub("@.*", "", em)
        ctx$user$role   <- tolower(row$role %||% "member")
        ctx$user$authed <- TRUE
        log_change(em, "signin", "session", "")
        msg(NULL)
      } else if (nrow(row) == 1 && toupper(row$active) == "PENDING") {
        msg(div(class = "note warn", "Your request is waiting for an admin to approve it."))
      } else {
        msg(div(class = "note bad", "That email isn't on the invite list. You can request access below."))
      }
    })

    observeEvent(input$request, {
      em <- tolower(trimws(input$email))
      if (!grepl("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", em, perl = TRUE)) {
        msg(div(class = "note bad", "Type a valid email address above first.")); return()
      }
      u <- ctx$data$users()
      if (em %in% tolower(u$email)) {
        msg(div(class = "note warn", "That email is already known - try Continue.")); return()
      }
      store_append("Users", data.frame(email = em, name = input$req_name %||% "", role = "member",
                                       organisation = "", interests = "", active = "PENDING", invited_at = now_ts()))
      log_change(em, "access_request", "Users", input$req_name)
      ctx$bump()
      msg(div(class = "note ok", "Thanks - an admin will approve your request."))
    })

  })
}
