# modules/Diet Planner/diet_add_single/ui.R

diet_add_single_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Log a Single Meal Entry",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        dateInput(ns("log_date"), "Date:", value = Sys.Date()),
        diet_type_dropdown_ui(ns),
        textInput(ns("dietary_restrictions"), "Dietary Restrictions (optional):", placeholder = "e.g., Gluten-free"),

        hr(),

        selectInput(ns("row_type"), "Row Type:", choices = c("Meal", "Summary")),
        textInput(ns("meal_name"), "Meal Name:", placeholder = "e.g., Breakfast - Oatmeal with Berries"),
        textInput(ns("meal_details"), "Details:", placeholder = "e.g., Ingredients and preparation notes"),
        textInput(ns("meal_time"), "Meal Time (Meal rows only):", placeholder = "e.g., 7:30 AM, or N/A"),
        textInput(ns("calories_macros"), "Calories / Macros:", placeholder = "e.g., 420 kcal (P:32g / C:38g / F:14g)"),
        textAreaInput(ns("observations"), "Observations:", rows = 4, placeholder = "Tips, substitutions, or day-level insights..."),

        br(),
        actionButton(ns("submit"), "Submit Entry", class = "btn-success btn-lg", icon = icon("save"), style = "width: 100%;"),
        br(), br(),
        htmlOutput(ns("status"))
      )
    )
  )
}
