# modules/ch9_road_travelled.R
# Chapter 9: The Road Most Travelled

ch9_road_travelled_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("Chapter 9"),
        tags$h2("The Road Most Travelled"),
        div(
          span(class = "hero-badge", icon("route"),        " Familiar Paths"),
          span(class = "hero-badge", icon("compass"),      " Deliberate Exposure"),
          span(class = "hero-badge", icon("shuffle"),      " Breaking the Routine")
        )
    ),

    fluidRow(
      box(title = "Chapter 9 - Overview", status = "primary", solidHeader = TRUE, width = 12,
          p("Cleevely examines a quieter obstacle to serendipity: habit. Individuals and organisations both settle ",
            "into familiar routines - the same conferences, the same contacts, the same sources - because familiar ",
            "routes feel efficient and low-risk. Chapter 9 argues that this comfort is precisely what caps the rate ",
            "of useful accident, and makes the case for deliberately, repeatedly stepping off the well-trodden road."),
          fluidRow(
            column(3, metric_card("\U0001f6b6", "The Comfort of Routine")),
            column(3, metric_card("\U0001f9ed", "Novel Environments")),
            column(3, metric_card("\U0001f501", "Diminishing Returns of the Familiar")),
            column(3, metric_card("\U0001f9ec", "Deliberate Detours"))
          )
      )
    ),

    fluidRow(
      box(title = NULL, status = "primary", solidHeader = FALSE, width = 12,
        tabsetPanel(
          id = ns("tabs"),

          tabPanel("\U0001f4da General Concepts",
            br(),
            fluidRow(
              column(6,
                sh("The Comfort of Routine"),
                concept_card("Why We Default to the Familiar Path",
                  "Repeating a known route - the same industry events, the same handful of trusted contacts, the same publications - genuinely is efficient in the short run: lower risk, predictable value, less cognitive effort. Cleevely's point isn't that routine is bad, but that it has a hidden cost that compounds silently over time."),
                concept_card("Diminishing Returns of the Well-Travelled Road",
                  "Each additional visit to the same conference, the same familiar network, delivers less genuinely new information than the one before - you've already met the people, already heard the arguments. The marginal value of the familiar path keeps falling exactly as its comfort keeps rising."),
                sh("Deliberate Exposure to the Unfamiliar"),
                concept_card("Why Different Beats More",
                  "Cleevely argues that seeking out genuinely different people, ideas and environments - even at real short-term cost in efficiency or comfort - reliably outperforms simply doing more of the familiar thing, because it's the <em>difference</em> itself that creates the conditions for an unexpected, valuable connection.")
              ),
              column(6,
                sh("Making the Detour a Habit"),
                concept_card("Small, Repeatable Acts of Deliberate Exposure",
                  "The chapter isn't asking for a dramatic reinvention - it recommends small, sustainable habits: attending one conference a year clearly outside your field, reading one source you'd normally dismiss, taking a meeting you'd usually decline. None of these guarantee a breakthrough; together, over years, they reliably raise the odds of one."),
                concept_card("Organisations Can Institutionalise the Detour",
                  "Individually this is a discipline; at an organisational level, Cleevely suggests it can be built into policy - budget lines for cross-sector events, rotation programmes that move people between teams, or simply permission to spend time outside the immediate job description."),
                div(class = "success-box",
                    tags$strong("\u2705 Chapter 9 takeaway: "),
                    "The road most travelled feels efficient precisely because it has stopped surprising you - treat ",
                    "the discomfort of a deliberate detour as a leading indicator of useful exposure, not wasted time.")
              )
            )
          ),

          tabPanel("\U0001f6e4\ufe0f Interactive",
            br(),
            fluidRow(
              column(12,
                shg("The Well-Travelled Road vs. the Deliberate Detour"),
                p(style = "font-size:12.5px;color:#546e7a;",
                  "The tight gold cluster is a familiar, well-connected routine - efficient, comfortable, and almost ",
                  "fully explored. Each red 'detour' node sits off the main road, reachable only via a single ",
                  "deliberate weak tie. Drag the detour nodes to see how disconnected they'd be without that one link."),
                viz_box(ns("road-net"), height = 460,
                        controls = tags$label(
                          tags$input(type = "checkbox", id = ns("road-toggle"),
                                     onclick = sprintf("SerendipityViz.toggleWeakTies('%s', this.checked);", ns("road-net"))),
                          " Highlight the deliberate detours"
                        ),
                        caption = "Force-directed graph \u00b7 drag nodes \u00b7 toggle to spotlight the off-road links"),
                viz_legend(c("Familiar routine" = "#E8A020", "Deliberate detour" = "#e74c3c")),
                d3_init(sprintf("
                  var nodes = [
                    {id:'R1', label:'Usual Conference', r:16, color:'#E8A020'},
                    {id:'R2', label:'Regular Contact A', r:14, color:'#E8A020'},
                    {id:'R3', label:'Regular Contact B', r:14, color:'#E8A020'},
                    {id:'R4', label:'Trade Publication', r:14, color:'#E8A020'},
                    {id:'R5', label:'Familiar Supplier', r:14, color:'#E8A020'},
                    {id:'R6', label:'Usual Meetup', r:14, color:'#E8A020'},
                    {id:'D1', label:'Unrelated Industry Event', r:15, color:'#e74c3c', tooltip:'Reached only via one deliberate detour.'},
                    {id:'D2', label:'Cross-discipline Reading', r:15, color:'#e74c3c', tooltip:'Outside the usual professional diet.'},
                    {id:'D3', label:'New Contact, Different Field', r:15, color:'#e74c3c', tooltip:'A meeting most people would decline.'}
                  ];
                  var links = [
                    {source:'R1', target:'R2'}, {source:'R1', target:'R3'}, {source:'R2', target:'R3'},
                    {source:'R2', target:'R4'}, {source:'R3', target:'R5'}, {source:'R4', target:'R6'},
                    {source:'R5', target:'R6'}, {source:'R1', target:'R6'},
                    {source:'R2', target:'D1', weak:true}, {source:'R4', target:'D2', weak:true},
                    {source:'R6', target:'D3', weak:true}
                  ];
                  SerendipityViz.forceNetwork('%s', nodes, links, {height:460, registerAs:'%s', charge:-240});
                ", ns("road-net"), ns("road-net")))
              )
            )
          ),

          tabPanel("\U0001f3e2 Applicability on Atera Analytics",
            br(),
            fluidRow(
              column(6,
                shg("Atera's Well-Travelled Road"),
                app_card("The Comfortable, Well-Mapped CAV Circuit",
                  "Atera's team already knows the CAV/AV circuit well: the same handful of Innovate UK events, the same council transport conferences, the same familiar competitor and partner names. That circuit is useful and worth continuing to attend - but Chapter 9's warning is that its marginal value to Atera keeps falling the more times the same people attend it."),
                app_card("Where Atera's Real Detours Have Already Paid Off",
                  "Atera's most valuable connections so far - the initial Cambridge academic tie-up, the first logistics-sector conversation - both came from stepping outside the CAV circuit specifically. The pattern is already visible in the company's own history; Chapter 9 argues for making it deliberate rather than accidental.")
              ),
              column(6,
                shg("Institutionalising the Detour at Atera"),
                app_card("A Standing 'Outside the Circuit' Budget Line",
                  "A concrete step: ring-fence a small annual budget specifically for one conference or event clearly outside CAV/AV each year - logistics, insurance, urban planning, even unrelated deep-tech sectors - treated as a deliberate detour, not a discretionary extra to be cut first when budgets tighten."),
                app_card("Rotating Who Takes the Detour",
                  "Rather than sending the same business-development lead to every event, Atera can rotate which team member takes the 'outside the circuit' trip each time - spreading the chance of a useful unplanned connection across more of the organisation's collective network, not just one person's."),
                div(class = "success-box",
                    tags$strong("\u2705 Chapter 9 action point: "),
                    "Book one clearly out-of-circuit event for the next two quarters, and send someone who wouldn't ",
                    "normally go.")
              )
            )
          )
        )
      )
    )
  )
}

ch9_road_travelled_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
