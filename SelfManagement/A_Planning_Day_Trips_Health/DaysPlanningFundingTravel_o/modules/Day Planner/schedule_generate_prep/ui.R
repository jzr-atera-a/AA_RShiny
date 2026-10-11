# modules/Day Planner/schedule_generate_prep/ui.R
# "Night-before" motivational prep checklist for a day already planned in
# Generate Schedule / day_scheduler. Different concept from the itinerary
# itself: this is what to DO BEFOREHAND to be ready for it.

schedule_generate_prep_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Select a Planned Day",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        p("Pick a date you've already planned in Generate Schedule - Claude will read that day's plan ",
          "and build a motivational preparation checklist for the night before."),

        fluidRow(
          column(6, selectInput(ns("select_date"), "Planned Date:", choices = c("Loading..." = ""))),
          column(3, prep_category_dropdown_ui(ns)),
          column(3, prep_location_dropdown_ui(ns))
        ),

        textAreaInput(ns("additional_context"), "Additional Details (optional):", height = "100px",
                      placeholder = "e.g., Important presentation, need confidence; or running low on energy this week"),

        fluidRow(
          column(6,
                 h5("Plan Preview:"),
                 htmlOutput(ns("plan_preview"))
          ),
          column(6,
                 h5("Schedule Preview:"),
                 htmlOutput(ns("schedule_preview"))
          )
        )
      )
    ),

    fluidRow(
      box(width = 12, align = "center",
          actionButton(ns("btn_generate"), "Generate Prep Steps", class = "btn-success btn-lg", icon = icon("magic")),
          actionButton(ns("btn_reset"), "Reset", class = "btn-default")
      )
    ),

    fluidRow(
      box(
        title = "Generated Preparation Steps",
        status = "success",
        solidHeader = TRUE,
        width = 12,

        div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
            icon("spinner", class = "fa-spin fa-3x"),
            h4("Claude is generating your personalized prep steps...")),

        htmlOutput(ns("generated_steps_display")),
        br(),
        htmlOutput(ns("status")),
        br(),
        fluidRow(
          column(6, actionButton(ns("btn_save"), "Save Steps", class = "btn-success btn-block", icon = icon("save"))),
          column(6, actionButton(ns("btn_regenerate"), "Regenerate", class = "btn-info btn-block", icon = icon("sync")))
        )
      )
    )
  )
}
