# ---- page ------------------------------------------------------------
# id:          settings
# tab label:   Google Analytics
# main group:  API Configuration   (sidebar; see modules/_module_registry.yml)
# description: connection, step-by-step diagnostics, saved key, quota, log
# functions:   settings_ui(id), settings_server(id, ...)
# --------------------------------------------------------------------

CRED_DIR  <- file.path(APP_DIR, "credentials")
CRED_KEY  <- file.path(CRED_DIR, "service-account.json")
CRED_CONF <- file.path(CRED_DIR, "config.json")

load_saved_config <- function() {
  if (!file.exists(CRED_KEY)) return(NULL)
  conf <- tryCatch(jsonlite::fromJSON(CRED_CONF), error = function(e) list())
  list(key_path = CRED_KEY, property_id = conf$property_id %||% "")
}

clean_property_id <- function(x) {
  x <- trimws(x %||% "")
  if (grepl("^G-", x, ignore.case = TRUE)) {
    stop("'", x, "' is a Measurement ID. The API needs the numeric Property ID from ",
         "Google Analytics > Admin > Property details (for this site: 515710306).", call. = FALSE)
  }
  id <- gsub("[^0-9]", "", x)
  if (!nzchar(id)) stop("Enter the numeric GA4 Property ID.", call. = FALSE)
  id
}

settings_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      column(6,
        card("Connect to Google Analytics",
          sub = "Upload the service account key once. The app tests each step and tells you exactly what to fix.",
          fileInput(ns("key"), "Service account key (.json)", accept = ".json",
                    buttonLabel = "Browse...", placeholder = "No file selected"),
          textInput(ns("property_id"), "GA4 Property ID (numbers only)", value = "515710306"),
          uiOutput(ns("property_picker")),
          checkboxInput(ns("remember"), "Remember this key on this computer (connects automatically next time)",
                        value = TRUE),
          div(class = "btn-row",
            actionButton(ns("connect"), "Connect & test", icon = icon("plug"), class = "btn-primary"),
            actionButton(ns("disconnect"), "Disconnect", icon = icon("power-off")),
            actionButton(ns("forget"), "Forget saved key", icon = icon("trash"))
          )
        )
      ),
      column(6,
        card("Connection check", sub = "Each step must pass before real data can load.",
             uiOutput(ns("diag")))
      )
    ),
    fluidRow(
      column(6,
        card("API usage", sub = "Google limits how much each property can be queried. Results are cached for 10 minutes to save quota.",
             uiOutput(ns("quota")),
             div(class = "btn-row", actionButton(ns("clear_cache"), "Clear cache & reload data", icon = icon("sync"))))
      ),
      column(6,
        card("First-time setup",
          tags$ol(class = "setup-steps",
            tags$li("Google Cloud Console > IAM & Admin > Service Accounts: create an account, then Keys > Add key > JSON."),
            tags$li("APIs & Services > Library: enable 'Google Analytics Data API' and 'Google Analytics Admin API'."),
            tags$li("Google Analytics > Admin > Property access management: add the service account email as Viewer."),
            tags$li("Upload the JSON key here and press Connect & test.")
          ),
          note_box(icon("lock"), " The key is a password. If you tick 'Remember', it is copied into this app's ",
                   tags$code("credentials"), " folder - never share or publish that folder.")
        )
      )
    ),
    card("Activity log", verbatimTextOutput(ns("log")))
  )
}

settings_server <- function(id, app) {
  moduleServer(id, function(input, output, session) {

    diag <- reactiveVal(list())
    log_lines <- reactiveVal(character(0))
    key_path <- reactiveVal(NULL)

    add_log <- function(msg) {
      line <- paste0("[", format(Sys.time(), "%H:%M:%S"), "] ", msg)
      log_lines(utils::tail(c(isolate(log_lines()), line), 80))
      cat("[SETTINGS]", msg, "\n")
    }
    step <- function(status, title, detail = NULL) {
      diag(c(isolate(diag()), list(list(status = status, title = title, detail = detail))))
      add_log(paste0(toupper(status), ": ", title, if (!is.null(detail)) paste0(" - ", detail) else ""))
    }

    do_connect <- function(path, property_raw, remember = FALSE) {
      diag(list())
      run <- function() {
        # 1. Key file
        info <- tryCatch(ga_read_key(path), error = function(e) {
          step("fail", "Key file", conditionMessage(e)); NULL })
        if (is.null(info)) return(FALSE)
        step("ok", "Key file is a valid service account key", info$client_email)

        # 2. Access token
        conn <- tryCatch(ga_connect(path), error = function(e) {
          step("fail", "Google sign-in", conditionMessage(e)); NULL })
        if (is.null(conn)) return(FALSE)
        step("ok", "Google accepted the key and issued an access token")

        # 3. Which properties can this account see? (not fatal)
        props <- tryCatch(ga_list_properties(conn), error = function(e) {
          step("warn", "Could not list properties (the app can still work)", conditionMessage(e)); NULL })
        if (!is.null(props)) {
          app$properties <- props
          if (nrow(props) == 0) {
            step("warn", "This service account has not been added to any GA4 property yet",
                 paste0("In Google Analytics > Admin > Property access management, add ", conn$email, " as Viewer."))
          } else {
            step("ok", sprintf("Can see %d GA4 propert%s", nrow(props), if (nrow(props) == 1) "y" else "ies"),
                 paste(sprintf("%s (%s)", props$property, props$property_id), collapse = ", "))
          }
        }

        # 4. Property ID
        pid <- tryCatch(clean_property_id(property_raw), error = function(e) {
          if (!is.null(props) && nrow(props) > 0) props$property_id[1]
          else { step("fail", "Property ID", conditionMessage(e)); NULL }
        })
        if (is.null(pid)) return(FALSE)
        if (!is.null(props) && nrow(props) > 0 && !(pid %in% props$property_id)) {
          step("warn", paste0("Property ", pid, " is not in the list this account can see"),
               paste0("Accessible: ", paste(props$property_id, collapse = ", ")))
        }

        # 5. Real data test
        test <- tryCatch(
          ga_run_report(conn, pid, "date", c("sessions", "totalUsers"),
                        Sys.Date() - 7, Sys.Date() - 1, use_cache = FALSE),
          error = function(e) { step("fail", paste0("Test report on property ", pid), conditionMessage(e)); NULL })
        if (is.null(test)) return(FALSE)
        if (nrow(test) == 0) {
          step("warn", "Connected, but the property has no visits in the last 7 days",
               "Check the GA tag is installed on the site (Site Kit > Analytics).")
        } else {
          step("ok", paste0("Test report on property ", pid, " returned data"),
               sprintf("%s sessions over the last 7 days", fmt_int(sum(test$sessions))))
        }

        conn$key_path <- path
        app$conn <- conn
        app$property_id <- pid
        app$mode <- "live"
        app$metadata <- NULL
        app$refresh <- isolate(app$refresh) + 1
        key_path(path)
        updateTextInput(session, "property_id", value = pid)

        if (remember) {
          saved <- tryCatch({
            dir.create(CRED_DIR, showWarnings = FALSE, recursive = TRUE)
            if (normalizePath(path, mustWork = FALSE) != normalizePath(CRED_KEY, mustWork = FALSE)) {
              file.copy(path, CRED_KEY, overwrite = TRUE)
            }
            writeLines(jsonlite::toJSON(list(property_id = pid), auto_unbox = TRUE), CRED_CONF)
            key_path(CRED_KEY)
            TRUE
          }, error = function(e) { add_log(paste("Could not save key:", conditionMessage(e))); FALSE })
          if (saved) step("ok", "Key saved on this computer - the app will connect automatically next time")
        }
        showNotification("Connected. Every tab now shows live Google Analytics data.", type = "message")
        TRUE
      }
      ok <- tryCatch(run(), error = function(e) {
        step("fail", "Unexpected error", conditionMessage(e)); FALSE
      })
      if (!ok) showNotification("Connection failed - see the Connection check panel.", type = "error", duration = 8)
      invisible(ok)
    }

    # Auto-connect at start-up if a key was remembered
    observe(isolate({
      saved <- load_saved_config()
      if (!is.null(saved)) {
        add_log("Saved key found - connecting automatically")
        if (nzchar(saved$property_id)) updateTextInput(session, "property_id", value = saved$property_id)
        do_connect(saved$key_path, saved$property_id, remember = FALSE)
      } else {
        add_log("No saved key. Showing demo data until you connect.")
      }
    }))

    observeEvent(input$key, {
      key_path(input$key$datapath)
      do_connect(input$key$datapath, input$property_id, remember = isTRUE(input$remember))
    })

    observeEvent(input$connect, {
      if (is.null(key_path())) {
        showNotification("Upload the service account key first.", type = "warning")
        return()
      }
      do_connect(key_path(), input$property_id, remember = isTRUE(input$remember))
    })

    observeEvent(input$disconnect, {
      app$conn <- NULL; app$mode <- "demo"; app$metadata <- NULL
      app$refresh <- isolate(app$refresh) + 1
      diag(list())
      add_log("Disconnected. Showing demo data.")
      showNotification("Disconnected - showing demo data.", type = "message")
    })

    observeEvent(input$forget, {
      removed <- suppressWarnings(file.remove(c(CRED_KEY, CRED_CONF)[file.exists(c(CRED_KEY, CRED_CONF))]))
      add_log(if (length(removed)) "Saved key deleted from this computer." else "There was no saved key.")
      showNotification("Saved key removed.", type = "message")
    })

    observeEvent(input$clear_cache, {
      ga_cache_clear()
      app$refresh <- isolate(app$refresh) + 1
      add_log("Cache cleared - data will be fetched again.")
    })

    observeEvent(input$pick_property, {
      if (nzchar(input$pick_property %||% "")) updateTextInput(session, "property_id", value = input$pick_property)
    }, ignoreInit = TRUE)

    output$property_picker <- renderUI({
      props <- app$properties
      if (is.null(props) || nrow(props) < 2) return(NULL)
      selectInput(session$ns("pick_property"), "Or pick a property this key can see",
                  choices = c("Choose..." = "", stats::setNames(props$property_id,
                              paste0(props$property, " (", props$property_id, ")"))))
    })

    output$diag <- renderUI({
      steps <- diag()
      if (length(steps) == 0) {
        return(note_box(icon("info-circle"),
          if (identical(app$mode, "live")) " Connected."
          else " Not connected - the dashboards are showing demo data. Upload your key to see real numbers."))
      }
      ico <- c(ok = "check-circle", warn = "exclamation-triangle", fail = "times-circle")
      tags$ul(class = "diag", lapply(steps, function(s) {
        tags$li(class = s$status, icon(ico[[s$status]]),
                div(div(class = "diag-title", s$title),
                    if (!is.null(s$detail)) div(class = "diag-detail", s$detail)))
      }))
    })

    output$quota <- renderUI({
      app$refresh; input$clear_cache
      invalidateLater(15000, session)
      q <- .ga_state$quota
      if (!identical(app$mode, "live") || is.null(q)) {
        return(note_box(icon("info-circle"), " Quota appears here after the first live request."))
      }
      row <- function(label, x) {
        if (is.null(x)) return(NULL)
        used <- x$consumed %||% 0; left <- x$remaining %||% 0
        total <- max(1, used + left)
        div(class = "quota-row",
          div(class = "quota-label", label, span(class = "quota-num",
              sprintf("%s of %s left", fmt_int(left), fmt_int(total)))),
          div(class = "meter", div(class = "meter-fill", style = sprintf("width:%.1f%%;", 100 * left / total))))
      }
      tagList(row("Tokens today", q$tokensPerDay), row("Tokens this hour", q$tokensPerHour),
              tags$p(class = "ga-card-sub", sprintf("%d request(s) sent this session.", .ga_state$requests)))
    })

    output$log <- renderText({
      l <- log_lines()
      if (length(l) == 0) "No activity yet." else paste(rev(l), collapse = "\n")
    })
  })
}
