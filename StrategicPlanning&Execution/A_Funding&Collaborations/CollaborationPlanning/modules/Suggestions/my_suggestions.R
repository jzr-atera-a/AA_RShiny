# ---- module ----------------------------------------------
# id:           my_suggestions
# name:         My suggestions
# icon:         lightbulb
# description:  Suggest a funding programme or an idea to work together; only you (and the owner) can see what you add
# packages:     shiny, DT
# -----------------------------------------------------------
# Saved to the suggestions table (latest row per suggestion wins). Each person sees only their own suggestions;
# the owner sees everyone's in the Analysis workbench. Analyses of a suggestion appear in Analysis library
# for the person who made it.

my_suggestions_ui <- function(id) {
  ns <- NS(id)
  tagList(
    note("info", "Suggest a funding programme or an idea for us to work on together. Only you and the owner can see what you add here. ",
         "When the owner has analysed it, the results appear in Analysis library."),
    layout_columns(col_widths = c(7, 5),
      card(textOutput(ns("form_title"), inline = TRUE),
        layout_columns(col_widths = c(4, 8),
          radioButtons(ns("kind"), "This is a", SUGGESTION_KINDS),
          textInput(ns("title"), "Name of the programme or idea", width = "100%")),
        textAreaInput(ns("description"), "Description", rows = 4, width = "100%",
                      placeholder = "What it is, who runs it, what it funds or what the collaboration would do"),
        textInput(ns("url"), "Link for more information (URL)", width = "100%", placeholder = "https://"),
        textAreaInput(ns("ideas"), "Your ideas: how we could work on it together", rows = 4, width = "100%"),
        layout_columns(col_widths = c(4, 4, 4),
          textInput(ns("country"), "Country", width = "100%"),
          textInput(ns("category"), "Category", width = "100%", placeholder = "e.g. Grant, Accelerator"),
          textInput(ns("topic"), "Topic", width = "100%", placeholder = "e.g. Energy AI")),
        layout_columns(col_widths = c(4, 4, 4),
          textInput(ns("funder"), "Funder (if known)", width = "100%"),
          textInput(ns("amount"), "Amount (if known)", width = "100%"),
          textInput(ns("deadline"), "Deadline (if known)", width = "100%")),
        layout_columns(col_widths = c(6, 6),
          textInput(ns("contact"), "Contact person (optional)", width = "100%"),
          textInput(ns("notes"), "Anything else", width = "100%")),
        div(class = "btn-row",
            actionButton(ns("save"), "Save suggestion", class = "btn-brand", icon = icon("floppy-disk")),
            actionButton(ns("clear"), "New suggestion", class = "btn-ghost"))),
      card("Your suggestions",
        uiOutput(ns("owner_switch")),
        DTOutput(ns("list")),
        uiOutput(ns("row_btns")))))
}

my_suggestions_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    editing <- reactiveVal("")
    fields <- c(title = "title", description = "description", url = "url", ideas = "ideas", country = "country", category = "category",
                topic = "topic", funder = "funder", amount_text = "amount", deadline = "deadline", contact = "contact", notes = "notes")
    output$form_title <- renderText(if (nzchar(editing())) "Edit your suggestion" else "New suggestion")
    output$owner_switch <- renderUI(if (ctx$is_owner()) checkboxInput(ns("all"), "Show everyone's suggestions (owner)", FALSE))
    mine <- reactive({
      d <- latest_suggestions(ctx$table("suggestions")())
      if (!(ctx$is_owner() && isTRUE(input$all))) d <- d[tolower(d$created_by) == tolower(ctx$user()), , drop = FALSE]
      d[order(d$updated_at, decreasing = TRUE), , drop = FALSE]
    })
    output$list <- renderDT({
      d <- mine(); a <- latest_analyses(ctx$table("analyses")())
      n <- vapply(d$suggestion_id, function(i) sum(a$suggestion_id == i), 1L)
      out <- data.frame(Name = d$title, Kind = names(SUGGESTION_KINDS)[match(d$kind, SUGGESTION_KINDS)], Status = d$status,
                        Analyses = n, Added = substr(d$created_at, 1, 10))
      if (ctx$is_owner() && isTRUE(input$all)) out$By <- d$created_by
      datatable(out, rownames = FALSE, selection = "single", options = list(dom = "tip", pageLength = 8))
    })
    sel <- reactive({ i <- input$list_rows_selected; if (length(i)) mine()[i, , drop = FALSE] else NULL })
    output$row_btns <- renderUI({ r <- sel(); req(r)
      own <- tolower(r$created_by) == tolower(ctx$user())
      div(class = "btn-row",
          if (own) actionButton(ns("edit"), "Edit", class = "btn-ghost sm", icon = icon("pen")),
          if (own) actionButton(ns("del"), "Delete", class = "btn-ghost sm", icon = icon("trash")),
          if (ctx$is_owner()) actionButton(ns("analyse"), "Analyse with Claude", class = "btn-brand sm", icon = icon("robot"))) })
    clear <- function() { editing(""); for (f in fields) updateTextInput(session, f, value = "") }
    observeEvent(input$clear, clear())
    observeEvent(input$edit, { r <- sel(); req(r); editing(r$suggestion_id); updateRadioButtons(session, "kind", selected = r$kind)
      for (k in names(fields)) updateTextInput(session, fields[[k]], value = r[[k]]) })
    observeEvent(input$save, {
      if (blank(input$title) || blank(input$description)) return(showNotification("Add at least a name and a description.", type = "warning"))
      url <- trimws(input$url %||% "")
      if (nzchar(url) && !grepl("^https?://", url)) url <- paste0("https://", url)
      old <- if (nzchar(editing())) { d <- latest_suggestions(ctx$table("suggestions")()); d[d$suggestion_id == editing(), , drop = FALSE] } else NULL
      if (!is.null(old) && nrow(old) && tolower(old$created_by) != tolower(ctx$user())) return(showNotification("You can only change your own suggestions.", type = "error"))
      row <- data.frame(suggestion_id = editing() %|% new_id("sug"), kind = input$kind, stringsAsFactors = FALSE)
      for (k in names(fields)) row[[k]] <- trimws(input[[fields[[k]]]] %||% "")
      row$url <- url
      row$status <- if (!is.null(old) && nrow(old)) old$status else "new"
      row$created_by <- if (!is.null(old) && nrow(old)) old$created_by else tolower(ctx$user())
      row$created_at <- if (!is.null(old) && nrow(old)) old$created_at else now_ts()
      row$updated_at <- now_ts(); row$deleted <- "FALSE"
      store_append("suggestions", row, user = ctx$user()); ctx$bump(); clear()
      showNotification("Suggestion saved. Thank you!", type = "message")
    })
    observeEvent(input$del, { r <- sel(); req(r, tolower(r$created_by) == tolower(ctx$user()))
      r$deleted <- "TRUE"; r$updated_at <- now_ts(); store_append("suggestions", r, user = ctx$user()); ctx$bump() })
    observeEvent(input$analyse, { r <- sel(); req(r, ctx$is_owner()); ctx$handoff$suggestion <- r$suggestion_id; ctx$nav("suggest", "analysis_workbench") })
  })
}
