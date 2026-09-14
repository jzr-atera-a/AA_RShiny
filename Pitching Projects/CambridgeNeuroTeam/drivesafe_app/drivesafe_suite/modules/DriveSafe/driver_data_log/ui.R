# modules/DriveSafe/driver_data_log/ui.R
# DriveSafe - Driver Data Log
# Subtabs: Generate and Upload | Browse Records

driver_data_log_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      column(12,
        div(class = "book-header",
          tags$h2(icon("database"), " DriveSafe - Driver Data Log"),
          tags$p(class = "author",
            "Simulate and log driver health condition records to BigQuery. ",
            "Use generated data for framework testing, A/B analysis and stakeholder reporting.")
        )
      )
    ),

    fluidRow(
      column(12, htmlOutput(ns("bq_status_banner")))
    ),

    fluidRow(
      box(title = NULL, status = "primary", solidHeader = FALSE, width = 12,

        tabsetPanel(id = ns("log_tabs"),

          # ── SUBTAB 1: GENERATE AND UPLOAD ─────────────────────────────────
          tabPanel(
            title = tagList(icon("upload"), " Generate and Upload"),
            br(),

            fluidRow(
              box(title = "Simulation Parameters",
                  status = "primary", solidHeader = TRUE, width = 4,

                selectInput(ns("gen_drivers"), "Select Drivers to Include:",
                  choices = c(
                    "Adams, J"    = "D001", "Patel, R"     = "D002",
                    "Okafor, C"   = "D003", "Williams, S"  = "D004",
                    "Hassan, M"   = "D005", "Chen, L"      = "D006",
                    "Thompson, K" = "D007", "Singh, P"     = "D008"
                  ),
                  multiple = TRUE,
                  selected = c("D001","D002","D003","D004"),
                  width = "100%"
                ),

                sliderInput(ns("gen_journeys"), "Journeys Per Driver:",
                  min = 1, max = 50, value = 10, step = 1),

                sliderInput(ns("gen_journey_hours"), "Max Journey Duration (hours):",
                  min = 1, max = 12, value = 8, step = 0.5),

                checkboxGroupInput(ns("gen_groups"), "Include Groups:",
                  choices  = c("OSA Group (untreated)"   = "osa_untreated",
                               "OSA Group (CPAP treated)" = "osa_treated",
                               "Control Group"            = "control"),
                  selected = c("osa_untreated", "osa_treated", "control")
                ),

                numericInput(ns("gen_seed"), "Random Seed (reproducibility):",
                  value = 42, min = 1, max = 9999),

                br(),
                actionButton(ns("btn_generate"), "Generate Simulated Data",
                  class = "btn-info btn-block", icon = icon("cogs")),
                br(),
                actionButton(ns("btn_upload"), "Upload to BigQuery",
                  class = "btn-success btn-block", icon = icon("cloud-upload-alt")),
                br(),
                htmlOutput(ns("upload_status"))
              ),

              box(title = "Preview of Generated Records",
                  status = "info", solidHeader = TRUE, width = 8,

                fluidRow(
                  column(3, valueBoxOutput(ns("prev_total_rows"),   width = 12)),
                  column(3, valueBoxOutput(ns("prev_drivers"),      width = 12)),
                  column(3, valueBoxOutput(ns("prev_osa_pct"),      width = 12)),
                  column(3, valueBoxOutput(ns("prev_mean_kss"),     width = 12))
                ),
                br(),
                DT::dataTableOutput(ns("preview_table"))
              )
            )
          ),

          # ── SUBTAB 2: BROWSE RECORDS ────────────────────────────────────
          tabPanel(
            title = tagList(icon("table"), " Browse Records"),
            br(),

            fluidRow(
              box(title = "Filters", status = "primary", solidHeader = TRUE, width = 12,
                fluidRow(
                  column(3,
                    selectInput(ns("browse_driver"), "Driver:",
                      choices = c("All" = ""), width = "100%")
                  ),
                  column(3,
                    selectInput(ns("browse_group"), "OSA Group:",
                      choices = c("All" = "", "OSA Untreated" = "osa_untreated",
                                  "OSA Treated" = "osa_treated",
                                  "Control" = "control"),
                      width = "100%")
                  ),
                  column(3,
                    numericInput(ns("browse_max"), "Max Rows:", value = 200,
                      min = 10, max = 2000, step = 50)
                  ),
                  column(3,
                    br(),
                    fluidRow(
                      column(6, actionButton(ns("btn_refresh"), "Refresh",
                        class = "btn-primary", icon = icon("sync"), style = "width:100%")),
                      column(6, downloadButton(ns("btn_download"), "CSV",
                        class = "btn-info", style = "width:100%"))
                    )
                  )
                )
              )
            ),

            fluidRow(
              column(12, htmlOutput(ns("browse_status")))
            ),
            br(),
            fluidRow(
              box(title = "Stored Driver Condition Records",
                  status = "info", solidHeader = TRUE, width = 12,
                DT::dataTableOutput(ns("browse_table"))
              )
            )
          )

        ) # end tabsetPanel
      )
    )
  )
}
