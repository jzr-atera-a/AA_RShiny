# modules/Strategic Analysis/business_consulting/ui.R

business_consulting_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Business Consulting", status = "primary", solidHeader = TRUE, width = 12,
          p("Build a structured business consulting case from an existing Strategic Analysis diagram and/or ",
            "Six Sigma tool - either or both, plus your own context. Load whichever inputs are relevant below, ",
            "describe the problem, then generate. The result comes out in the same format as Flex Table's ",
            "Generate Table tab, ready to send straight to Flex Table's Bulk Import.")
      )
    ),

    # ---- Box 1: Strategy Diagram input (optional) ----
    fluidRow(
      box(title = "1. Strategy Diagram Input (optional)", status = "info", solidHeader = TRUE, width = 6,
          fluidRow(
            column(6, selectInput(ns("sd_category"), "Category:", choices = NULL)),
            column(6, selectInput(ns("sd_domain"), "Domain:", choices = NULL))
          ),
          fluidRow(
            column(6, selectInput(ns("sd_topic"), "Topic:", choices = NULL)),
            column(6, selectInput(ns("sd_diagram_id"), "Diagram:", choices = NULL))
          ),
          actionButton(ns("sd_load"), "Load Strategy Diagram", icon = icon("chess"),
                      class = "btn-info", style = "width: 100%;"),
          br(), br(),
          htmlOutput(ns("sd_status")),
          uiOutput(ns("sd_output"))
      ),

      # ---- Box 2: Six Sigma Tool input (optional) ----
      box(title = "2. Six Sigma Tool Input (optional)", status = "info", solidHeader = TRUE, width = 6,
          fluidRow(
            column(6, selectInput(ns("ss_category"), "Category:", choices = NULL)),
            column(6, selectInput(ns("ss_domain"), "Domain:", choices = NULL))
          ),
          fluidRow(
            column(6, selectInput(ns("ss_topic"), "Topic:", choices = NULL)),
            column(6, selectInput(ns("ss_diagram_id"), "Diagram:", choices = NULL))
          ),
          actionButton(ns("ss_load"), "Load Six Sigma Tool", icon = icon("microscope"),
                      class = "btn-info", style = "width: 100%;"),
          br(), br(),
          htmlOutput(ns("ss_status")),
          uiOutput(ns("ss_output"))
      )
    ),

    # ---- Box 3: Build the case ----
    fluidRow(
      box(title = "3. Build Business Consulting Case", status = "success", solidHeader = TRUE, width = 12,

          div(class = "alert alert-info",
              tags$strong("Inputs used: "), htmlOutput(ns("inputs_summary"), inline = TRUE)),

          fluidRow(
            column(9, textAreaInput(ns("user_context"), "Additional context about the problem: *", height = "110px",
                                    placeholder = "e.g. We need a 12-month plan to enter the German market while also addressing the sensor QC issue identified above.")),
            column(3, style = "padding-top: 25px;",
                   actionButton(ns("load_from_db"), "Load Additional Info from DB", icon = icon("database"),
                               class = "btn-default", style = "width: 100%;"),
                   p(style = "color: #7f8c8d; font-size: 11px; margin-top: 6px;",
                     "Not yet implemented - reserved for pulling supporting content from another table."))
          ),

          hr(),
          category_topic_dropdown_ui(ns),
          fluidRow(
            column(4, textInput(ns("table_title"), "Case Title:", value = "Business Consulting Case")),
            column(4, textInput(ns("row_dimension_label"), "What do the ROWS represent?", value = "Key Recommendations")),
            column(4, textInput(ns("column_dimension_label"), "What do the COLUMNS represent?", value = "Detail"))
          ),
          fluidRow(
            column(4, numericInput(ns("expected_rows"), "Expected Rows (approx.):", value = 5, min = 1, max = 30)),
            column(4, numericInput(ns("expected_columns"), "Expected Columns (approx.):", value = 4, min = 1, max = 15)),
            column(4, sliderInput(ns("words_per_cell"), "Max Words per Cell:", min = 10, max = 100, value = 40, step = 5))
          ),

          actionButton(ns("generate"), "Generate Business Consulting Case", icon = icon("magic"),
                      class = "btn-primary btn-lg", style = "width: 100%;"),

          br(), br(),
          div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
              icon("spinner", class = "fa-spin fa-3x"),
              h4("Building the case (this may take 20-60 seconds)...")),

          htmlOutput(ns("generate_status")),
          br(),

          uiOutput(ns("action_buttons")),

          h5("Review & Edit (re-parse after any manual fix):", style = "margin-top: 15px;"),
          textAreaInput(ns("case_text_edit"), NULL, height = "300px",
                       placeholder = "The generated case (in Flex Table format) will appear here - editable before sending."),

          br(),
          DT::dataTableOutput(ns("preview_table"))
      )
    )
  )
}
