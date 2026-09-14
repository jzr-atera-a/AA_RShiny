# modules/add_entry/ui.R

add_entry_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Add a Single Row Manually",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        p("Use this to add or correct one row by hand. You can enter as many columns as you like - ",
          "one per line, in the form ", tags$code("Column Header: Value"), ". ",
          "Values may include LaTeX (", tags$code("$...$"), " or ", tags$code("$$...$$"), ")."),

        category_topic_dropdown_ui(ns),

        fluidRow(
          column(6, textInput(ns("table_title"), "Table Title:", placeholder = "e.g., ML Models for Forecasting Asset Class Prices")),
          column(3, textInput(ns("row_dimension_label"), "Row Dimension Label:", placeholder = "e.g., Financial Asset Class")),
          column(3, textInput(ns("column_dimension_label"), "Column Dimension Label:", placeholder = "e.g., Machine Learning Model"))
        ),

        textInput(ns("row_index"), "Row Label (row_index): *", placeholder = "e.g., Equities"),

        textAreaInput(ns("columns_text"), "Columns (one 'Header: Value' per line): *", rows = 8, width = "100%",
                      placeholder = "Random Forest: Handles nonlinearity well; needs regular retraining as regime shifts.\nLSTM: Captures long-range dependencies; data-hungry and slow to train.\nARIMA: Simple, interpretable baseline; struggles with structural breaks."),

        textInput(ns("notes"), "Notes (optional):", placeholder = "One-sentence note about this row as a whole"),

        br(),
        actionButton(ns("submit"), "Submit Entry", class = "btn-success btn-lg",
                    icon = icon("save"), style = "width: 100%;"),
        br(), br(),
        htmlOutput(ns("status"))
      )
    )
  )
}
