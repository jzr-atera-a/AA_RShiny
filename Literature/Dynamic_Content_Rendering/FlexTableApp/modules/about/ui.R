# modules/about/ui.R

about_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Flexible Comparison Table Suite",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        h4("What this app does"),
        p("Generates and stores comparison tables via the Claude API where the ",
          "NUMBER OF COLUMNS is decided by Claude at generation time and can be ",
          "different every time - e.g. 12 ML models for one query, 8 markets for another - ",
          "without changing the BigQuery table schema."),

        h4("BigQuery Schema"),
        tags$pre(
"id                      INTEGER   auto-generated, sequential
created_at              TIMESTAMP auto-generated
source                  STRING    'claude' or 'manual'
category                STRING    top-level domain, e.g. 'Finance'
topic                   STRING    specific comparison, e.g. 'ML Models for Asset Class Price Forecasting'
table_title             STRING    display title for the table
row_dimension_label     STRING    what the ROWS represent, e.g. 'Financial Asset Class'
column_dimension_label  STRING    what the COLUMNS represent, e.g. 'Machine Learning Model'
row_index               STRING    the specific row label, e.g. 'Equities'
columns_data            STRING    delimited text holding an EVER-CHANGING number of columns for this row
notes                   STRING    optional free-text note about the row"
        ),

        h4("The columns_data delimiter contract"),
        p("One physical BigQuery row = one row of the rendered table. All of that row's columns are ",
          "packed into a single STRING using two literal separator tokens that Claude is instructed ",
          "never to use elsewhere:"),
        tags$ul(
          tags$li(tags$code("|||COL|||"), " separates one column entry from the next"),
          tags$li(tags$code("|||KV|||"), " separates a column's header from its value")
        ),
        tags$pre(
"Model A|||KV|||Fast to train but sensitive to regime shifts|||COL|||Model B|||KV|||Slower, more stable across regimes"
        ),
        p("The Table Viewer tab requires four cascading, compulsory filters - Category, Topic, ",
          "Row, and Columns Data (the specific column header, e.g. one ML Model) - and renders ",
          "exactly ONE combination at a time: the single stored value at that row/column ",
          "intersection, parsed out of that row's ", tags$code("columns_data"), " on the fly."),

        h4("LaTeX / MathJax"),
        p("Any cell value may contain inline ($...$) or display ($$...$$) LaTeX. MathJax is loaded ",
          "globally and re-typeset after every table render."),

        h4("Category / Topic taxonomy"),
        p("Category is the broad domain (e.g. Finance, Healthcare, Marketing). Topic is the specific ",
          "table instance within that domain. Selecting an existing Topic in Generate Table or Add ",
          "Single Entry auto-fills the Row/Column dimension labels so a topic's meaning stays consistent ",
          "across multiple generation runs."),

        h4("Tabs"),
        tags$ul(
          tags$li(tags$strong("BigQuery Setup"), " - connect to your dataset (auto-creates the table)"),
          tags$li(tags$strong("Claude API Config"), " - credentials, model, timeout"),
          tags$li(tags$strong("Generate Table"), " - describe the comparison, Claude decides the column count"),
          tags$li(tags$strong("Bulk Import"), " - paste/parse/upload raw generated text"),
          tags$li(tags$strong("Add Single Entry"), " - manually add or correct one row"),
          tags$li(tags$strong("Browse Data"), " - raw backup view + CSV export"),
          tags$li(tags$strong("Table Viewer"), " - look up one Category+Topic+Row+Columns Data combination and view its value (LaTeX-aware)")
        )
      )
    )
  )
}
