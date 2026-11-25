# ---- module ----------------------------------------------
# id:           programme_bulk_import
# name:         Bulk import
# icon:         file-import
# description:  Paste programmes in the bracket-tag text format, preview them, and save
# packages:     shiny, DT
# -----------------------------------------------------------
# Ported from Funding Programmes modules/bulk_import. The CSV upload stays in Programmes.

programme_bulk_import_ui <- function(id) {
  ns <- NS(id)
  tagList(
    note("info", "Paste one or more programmes in the format below (the format the Funding Programmes app and Live search use). ",
         "Each programme starts with ", tags$code("[programme_name]:"), ". Fields you leave out stay blank."),
    card("Paste programmes",
      textAreaInput(ns("txt"), NULL, rows = 12, width = "100%", placeholder = paste(
        "[programme_name]: Smart Grants", "[funder]: Innovate UK", "[category]: Grant", "[country]: United Kingdom",
        "[amount_of_money]: GBP 25,000 to GBP 2 million", "[conditions]: UK registered business; must lead the project",
        "[areas_of_application]: any sector", "[deadline]: 2027-01-14", "[verified_urls]: https://apply-for-innovation-funding.service.gov.uk",
        sep = "\n")),
      div(class = "btn-row",
          actionButton(ns("parse"), "Preview", class = "btn-ghost", icon = icon("eye")),
          actionButton(ns("save"), "Save all", class = "btn-brand", icon = icon("floppy-disk")))),
    uiOutput(ns("status")),
    card("Preview", DTOutput(ns("preview"))))
}

programme_bulk_import_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    parsed <- reactiveVal(NULL); status <- reactiveVal(NULL)
    do_parse <- function() {
      tryCatch({
        d <- programmes_from_parsed(parse_programme_text(input$txt), "Bulk import")
        d$already <- programme_key(d) %in% programme_key(store_read("programmes"))
        parsed(d); status(NULL); d
      }, error = function(e) { parsed(NULL); status(note("bad", safe_error_text(e))); NULL })
    }
    observeEvent(input$parse, do_parse())
    observeEvent(input$save, {
      d <- do_parse(); req(d)
      r <- add_programmes(d[, setdiff(names(d), "already"), drop = FALSE], ctx$user())
      ctx$bump()
      status(note("ok", sprintf("Saved %d programme(s); skipped %d already in the list.", r$added, r$skipped)))
      updateTextAreaInput(session, "txt", value = "")
    })
    output$status <- renderUI(status())
    output$preview <- renderDT({
      d <- parsed(); req(d)
      d <- d[, c("programme_name", "funder", "category", "country", "amount_text", "max_gbp", "closes_date", "deadline_text", "source_url", "already")]
      names(d) <- c("Programme", "Funder", "Category", "Country", "Amount", "Max GBP", "Closes", "Deadline note", "Source", "Already here")
      datatable(d, rownames = FALSE, options = list(dom = "tip", scrollX = TRUE, pageLength = 10))
    })
  })
}
