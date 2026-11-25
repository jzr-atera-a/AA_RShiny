# modules/Communications/collab_contacts.R
# Subtab: From CollaborationPlanning - bring the people and outreach messages of the CollaborationPlanning app (the app
# other people use to explore funding and collaboration) into Communications.
#   its people   -> business_contacts       (contact_id cp_<person_id>; repeated = TRUE when already ours)
#   its messages -> contact_communications  (message_id cp_<message_id>; linked to our contact when the email matches)
# Read with that app's own storage code (R/suite_cp.R); mapping in R/utils_collab_sync.R. Nothing is written back.

collab_contacts_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(title = "People and Messages from CollaborationPlanning", status = "primary", solidHeader = TRUE, width = 12,
          p("Reads CollaborationPlanning's ", tags$b("People"), " list (Team up > Collaborators) and its ", tags$b("messages"),
            " (Team up > Outreach and Inbox) from its tables. Set where they are in ", tags$b("API Settings > Google Drive > CollaborationPlanning"), "."),
          fluidRow(
            column(4, actionButton(ns("read"), "Read", icon = icon("cloud-download-alt"), class = "btn-primary", style = "width:100%")),
            column(4, checkboxInput(ns("with_messages"), "Also import their messages into communication history", value = TRUE)),
            column(4, checkboxInput(ns("include_repeated"), "Also add people already in our list (marked as repeated)", value = TRUE))),
          uiOutput(ns("read_status")),
          DT::dataTableOutput(ns("preview")),
          br(),
          actionButton(ns("import"), "Import into Contacts", icon = icon("database"), class = "btn-success"),
          tags$p(class = "help-block",
                 tags$b("New"), ": not in our contacts. ",
                 tags$b("Repeated"), ": same email, or same name and organisation, as one of our contacts (or earlier in this list); added with ",
                 tags$code("repeated = TRUE"), " and highlighted in Explore Contacts. ",
                 tags$b("Already imported"), ": this person was brought in before; left out. Their messages are linked to our own contact ",
                 "when the email matches."),
          uiOutput(ns("import_status")))
    )
  )
}

collab_contacts_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    got <- reactiveVal(NULL)
    note <- function(cls, ...) tags$div(class = cls, ...)

    observeEvent(input$read, {
      r <- withProgress(message = "Reading CollaborationPlanning...", tryCatch({
        st <- cp_connect(api_manager)
        people <- cp_people(); msgs <- cp_messages()
        ex <- api_manager$bq_load_contacts(strict = TRUE)
        list(m = collab_mark_contact_repeats(collab_people_to_contacts(people), ex), msgs = msgs, from = st$read_from)
      }, error = function(e) e))
      if (inherits(r, "error")) { got(NULL); return(output$read_status <- renderUI(note("status-error", conditionMessage(r)))) }
      got(r)
      n <- function(s) sum(r$m$status == s)
      output$read_status <- renderUI(note("status-info", sprintf("%d people and %d message(s) read (from its %s). ", nrow(r$m), nrow(r$msgs), r$from),
        tags$b(sprintf("New: %d, Repeated: %d, Already imported: %d.", n("New"), n("Repeated"), n("Already imported")))))
    })

    output$preview <- DT::renderDataTable({
      r <- got(); req(r, nrow(r$m))
      show <- r$m[, c("status", "full_name", "email", "company", "job_title", "country", "industry", "same_as_id")]
      names(show) <- c("Status", "Name", "Email", "Organisation", "Role", "Country", "Type", "Same as our contact")
      DT::formatStyle(DT::datatable(show, rownames = FALSE, options = list(pageLength = 10, scrollX = TRUE)), "Status",
                      backgroundColor = DT::styleEqual(c("New", "Repeated", "Already imported"), c("#d4edda", "#fff3cd", "#e2e3e5")), fontWeight = "bold")
    })

    observeEvent(input$import, {
      r <- got()
      if (is.null(r)) return(output$import_status <- renderUI(note("status-warning", "Read first.")))
      res <- withProgress(message = "Importing...", tryCatch({
        cols_ok <- api_manager$bq_ensure_contact_source_columns()
        m <- r$m[r$m$status == "New" | (isTRUE(input$include_repeated) & r$m$status == "Repeated"), , drop = FALSE]
        rows <- m; rows$repeated <- ifelse(rows$status == "Repeated", "TRUE", "FALSE"); rows$status <- NULL; rows$same_as_id <- NULL
        if (!cols_ok) rows <- rows[, setdiff(names(rows), c("source", "source_ref", "repeated")), drop = FALSE]
        if (nrow(rows)) api_manager$bq_insert_contact(rows)
        incProgress(0.5)
        nm <- 0L
        if (isTRUE(input$with_messages) && nrow(r$msgs)) {
          ex_comm <- api_manager$bq_load_communications()
          contacts <- api_manager$contacts_cache %||% rows
          comms <- collab_messages_to_comms(r$msgs, contacts, collab_chr(ex_comm$message_id %|g|% character(0)))
          if (!cols_ok) comms <- comms[, setdiff(names(comms), c("source", "source_ref")), drop = FALSE]
          if (nrow(comms)) api_manager$bq_insert_communication(comms)
          nm <- nrow(comms)
        }
        list(people = nrow(rows), repeated = sum(m$status == "Repeated"), messages = nm)
      }, error = function(e) e))
      if (inherits(res, "error")) return(output$import_status <- renderUI(note("status-error", "Not imported: ", conditionMessage(res))))
      api_manager$trigger_state_update_contacts()
      cat(sprintf("[CollaborationPlanning] imported %d people (%d repeated) and %d message(s)\n", res$people, res$repeated, res$messages))
      output$import_status <- renderUI(note("status-success", sprintf("✓ Imported %d people (%d marked as repeated) and %d message(s). ",
                                                                       res$people, res$repeated, res$messages), "See Explore Contacts."))
      got(NULL)
    })
  })
}
