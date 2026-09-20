# modules/Travel Planning/travel_itinerary_planner/ui.R
# Travel Itinerary Planner Module - Interactive UI

travel_itinerary_planner_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # ====================
    # TAB 1: DESTINATION & PLACES
    # ====================
    fluidRow(
      box(
        title = "Step 1: Destination & Place Discovery",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        h4("Enter Your Destination"),
        p("Tell Claude which city or location you want to visit, and how many top attractions to discover."),

        fluidRow(
          column(6,
                 textInput(ns("destination"), 
                          "City / Location:",
                          placeholder = "e.g., Toronto, Paris, Tokyo, Barcelona..."),
                 p(class = "text-muted", style = "font-size: 0.9em;",
                   "Enter the name of the city or region you want to explore.")
          ),
          column(3,
                 sliderInput(ns("num_places"), 
                            "Number of Places:",
                            min = 20, max = 50, value = 30, step = 5),
                 p(class = "text-muted", style = "font-size: 0.85em;",
                   "Select 20-50 attractions to discover.")
          ),
          column(3,
                 h5("Actions:"),
                 actionButton(ns("discover_places"), "Discover Places", icon = icon("compass"),
                             class = "btn-info btn-lg", style = "width: 100%; margin-bottom: 10px;"),
                 actionButton(ns("reset_discovery"), "Reset", icon = icon("redo"),
                             class = "btn-default", style = "width: 100%;")
          )
        ),

        hr(),

        # Loading spinner
        div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
            icon("spinner", class = "fa-spin fa-3x"),
            h4("Discovering attractions... This may take 30-60 seconds.")),

        # Status message
        htmlOutput(ns("discovery_status")),

        # Places selection area
        h5(style = "margin-top: 20px;", "Select Attractions You Want to Visit:"),
        p(class = "text-muted", "Check the boxes for places you're interested in, then proceed to the next step."),
        
        div(id = ns("places_list_container"),
            style = "max-height: 400px; overflow-y: auto; border: 1px solid #ddd; padding: 15px; border-radius: 4px; background-color: #f9f9f9;",
            htmlOutput(ns("places_checkboxes"))
        ),

        br(),
        fluidRow(
          column(6, h6(htmlOutput(ns("places_counter")))),
          column(6, align = "right",
                 actionButton(ns("select_all_places"), "Select All", icon = icon("check-square"),
                             class = "btn-sm btn-default"),
                 actionButton(ns("deselect_all_places"), "Deselect All", icon = icon("square"),
                             class = "btn-sm btn-default")
          )
        )
      )
    ),

    br(),

    # ====================
    # TAB 2: ITINERARY SETTINGS
    # ====================
    fluidRow(
      box(
        title = "Step 2: Itinerary Settings & Constraints",
        status = "info",
        solidHeader = TRUE,
        width = 12,

        h4("Configure Your Trip"),

        h5("📅 Trip Dates:"),
        fluidRow(
          column(6,
                 dateInput(ns("trip_start_date"),
                          "Trip Start Date:",
                          value = Sys.Date() + 7,  # Default: one week from now
                          min = Sys.Date(),
                          format = "yyyy-mm-dd"),
                 p(class = "text-muted", style = "font-size: 0.85em;",
                   "Select the first day of your trip.")
          ),
          column(6,
                 dateInput(ns("trip_end_date"),
                          "Trip End Date:",
                          value = Sys.Date() + 10,  # Default: one week + 3 days
                          min = Sys.Date(),
                          format = "yyyy-mm-dd"),
                 p(class = "text-muted", style = "font-size: 0.85em;",
                   "Select the last day of your trip.")
          )
        ),

        hr(),

        h5("⏰ Daily Schedule:"),
        fluidRow(
          column(6,
                 h5("Trip Duration (auto-calculated):",
                    textOutput(ns("duration_display"), inline = TRUE)),
                 sliderInput(ns("num_days"), 
                            "OR manually set days:",
                            min = 1, max = 7, value = 3, step = 1),
                 p(class = "text-muted", style = "font-size: 0.9em;",
                   "Will be updated based on your date selection above.")
          ),
          column(6,
                 h5("Daily Schedule Times:"),
                 selectInput(ns("start_time"), "Start Time:",
                            choices = c("7:00 AM" = "07:00", "8:00 AM" = "08:00", "9:00 AM" = "09:00", 
                                       "10:00 AM" = "10:00", "11:00 AM" = "11:00"),
                            selected = "09:00"),
                 selectInput(ns("end_time"), "End Time:",
                            choices = c("3:00 PM" = "15:00", "4:00 PM" = "16:00", "5:00 PM" = "17:00",
                                       "6:00 PM" = "18:00", "7:00 PM" = "19:00"),
                            selected = "16:00")
          )
        ),

        hr(),

        h5("Trip Constraints & Preferences:"),
        p(class = "text-muted", style = "font-size: 0.9em;",
          "Add any special requirements, preferences, or constraints. Claude will take these into account."),
        
        textAreaInput(ns("constraints"), 
                     NULL,
                     height = "150px",
                     placeholder = paste(
                       "Examples:",
                       "- Avoid rainy areas on Day 2",
                       "- Must visit museums in afternoon (cooler)",
                       "- Minimize travel time between attractions",
                       "- Prefer walking over public transit",
                       "- Include lunch breaks near attractions",
                       "- Budget $100/day for food",
                       "- Wheelchair accessible routes only",
                       sep = "\n"
                     )),

        hr(),

        fluidRow(
          column(4,
                 actionButton(ns("generate_itinerary"), "Generate Itinerary", icon = icon("route"),
                             class = "btn-success btn-lg", style = "width: 100%;")
          ),
          column(4,
                 downloadButton(ns("download_itinerary"), "Download Plan", icon = icon("download"),
                               class = "btn-warning", style = "width: 100%;")
          ),
          column(4,
                 actionButton(ns("start_over"), "Start Over", icon = icon("redo"),
                             class = "btn-default", style = "width: 100%;")
          )
        )
      )
    ),

    br(),

    # ====================
    # TAB 3: GENERATED ITINERARY
    # ====================
    fluidRow(
      box(
        title = "Step 3: Your Generated Itinerary",
        status = "success",
        solidHeader = TRUE,
        width = 12,

        # Loading spinner
        div(id = ns("itinerary_loading_spinner"), style = "display: none; text-align: center; padding: 40px;",
            icon("spinner", class = "fa-spin fa-5x", style = "color: #27ae60;"),
            h3("Planning your perfect trip..."),
            p("Claude is creating a customized itinerary. This may take 60-120 seconds.")),

        # Itinerary content
        div(id = ns("itinerary_content"), style = "display: none;",
            htmlOutput(ns("itinerary_html")),
            br()
        ),

        hr(),

        # Interactive Plotly Map Section
        h4("Interactive Trip Map"),
        p(class = "text-muted",
          "Click on any numbered marker to see the attraction name, expected visit time, and description."),
        
        fluidRow(
          column(8,
                 plotly::plotlyOutput(ns("trip_map"), height = "550px")
          ),
          column(4,
                 box(title = "Attraction Details", status = "info", solidHeader = TRUE, width = 12,
                     uiOutput(ns("attraction_detail"))
                 )
          )
        ),

        br(),

        # Status and actions
        htmlOutput(ns("itinerary_status")),

        h5("Export Your Itinerary:"),
        fluidRow(
          column(4,
                 downloadButton(ns("download_html"), "📄 HTML + Map", 
                               class = "btn-primary", style = "width: 100%;")
          ),
          column(4,
                 downloadButton(ns("download_pdf"), "📕 PDF (Mobile)", 
                               class = "btn-warning", style = "width: 100%;")
          ),
          column(4,
                 downloadButton(ns("download_calendar"), "📅 Calendar (.ics)", 
                               class = "btn-success", style = "width: 100%;")
          )
        ),

        hr(),

        fluidRow(
          column(6,
                 actionButton(ns("share_itinerary"), "Share Itinerary", icon = icon("share-alt"),
                             class = "btn-info", style = "width: 100%;")
          ),
          column(6,
                 actionButton(ns("refine_itinerary"), "Refine Plan", icon = icon("edit"),
                             class = "btn-primary", style = "width: 100%;")
          )
        )
      )
    )
  )
}
