# modules/ch4_closer_to_home.R
# Chapter 4: Closer To Home

ch4_closer_to_home_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("Chapter 4"),
        tags$h2("Closer To Home"),
        div(
          span(class = "hero-badge", icon("map-location-dot"), " Place & Proximity"),
          span(class = "hero-badge", icon("city"),              " Local Ecosystems"),
          span(class = "hero-badge", icon("graduation-cap"),    " The Cambridge Cluster")
        )
    ),

    fluidRow(
      box(title = "Chapter 4 - Overview", status = "primary", solidHeader = TRUE, width = 12,
          p("Cleevely - himself a serial Cambridge entrepreneur - brings the argument down to earth: place still ",
            "matters, even in a digitally connected world. Chapter 4 examines how a relatively small geographic ",
            "area, Cambridge, has generated a wildly disproportionate concentration of spinout companies, investors ",
            "and technical talent, and asks what specifically about physical proximity makes that possible."),
          fluidRow(
            column(3, metric_card("\U0001f4cd", "Geography Still Matters")),
            column(3, metric_card("\U0001f3eb", "University Anchor")),
            column(3, metric_card("\u2615", "Informal Meeting Places")),
            column(3, metric_card("\U0001f504", "Repeat Founders & Investors"))
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
                sh("Why Geography Still Matters"),
                concept_card("Digital Connection Hasn't Replaced Physical Proximity",
                  "Despite decades of predictions that remote communication would flatten geography, innovation clusters have if anything become more concentrated, not less. Cleevely argues this is because physical proximity produces a specific kind of low-cost, low-friction, unplanned contact that scheduled video calls simply can't replicate."),
                concept_card("The Cambridge Case",
                  "A university city of roughly 150,000 people has produced one of the highest concentrations of spinout companies and deep-tech investment per capita in the world. Cleevely's explanation isn't one factor but a stack of reinforcing ones: a world-class university supplying talent and IP, a small enough geography that people bump into each other repeatedly, and decades of accumulated trust between founders and investors who know each other's track records."),
                sh("The Role of Informal Space"),
                concept_card("Pubs, Cafes and Corridors as Infrastructure",
                  "Some of Cambridge's most consequential deals and hires reportedly began in informal settings - a pub, a college dining hall, a chance corridor meeting - not in a scheduled pitch meeting. Cleevely treats these informal venues as genuine infrastructure for innovation, not incidental colour.")
              ),
              column(6,
                sh("Concentration Compounds"),
                concept_card("Why Clusters Get Stronger, Not Weaker, Over Time",
                  "Once a cluster reaches a critical mass of successful founders and investors, it becomes self-reinforcing: successful founders become angel investors and mentors, failed founders often stay local and join the next venture, and each new success attracts more talent to the same small geography rather than dispersing it."),
                concept_card("The Limits of the Cluster Model",
                  "Cleevely doesn't claim clusters can simply be manufactured anywhere by copying Cambridge's surface features. A cluster needs a genuine anchor institution, enough time for trust to accumulate, and - crucially - enough physical density that unplanned contact actually happens often enough to matter."),
                div(class = "success-box",
                    tags$strong("\u2705 Chapter 4 takeaway: "),
                    "Deliberately engineering physical density - shared space, recurring informal events, a genuine ",
                    "local anchor - is one of the most reliable ways to manufacture the conditions for serendipity.")
              )
            )
          ),

          tabPanel("\U0001f3f0 Interactive",
            br(),
            fluidRow(
              column(12,
                shg("The Cambridge Cluster - Mapped as a Network"),
                p(style = "font-size:12.5px;color:#546e7a;",
                  "A simplified map of how a place-based cluster actually connects: one anchor institution, a ring ",
                  "of companies and investors, and informal venues acting as unplanned meeting points between them. ",
                  "Drag the venue nodes (red) and watch how many otherwise-separate parts of the cluster route ",
                  "through them."),
                viz_box(ns("cambridge-net"), height = 460,
                        caption = "Force-directed graph \u00b7 red nodes are informal venues acting as connective tissue"),
                viz_legend(c("University" = "#3498db", "Spinout / company" = "#E8A020",
                             "Investor" = "#1e5a5a", "Informal venue" = "#e74c3c")),
                d3_init(sprintf("
                  var nodes = [
                    {id:'UNI', label:'University', r:22, color:'#3498db'},
                    {id:'C1', label:'Spinout A', r:14, color:'#E8A020'},
                    {id:'C2', label:'Spinout B', r:14, color:'#E8A020'},
                    {id:'C3', label:'Spinout C', r:14, color:'#E8A020'},
                    {id:'C4', label:'Deep-tech Co.', r:15, color:'#E8A020'},
                    {id:'V1', label:'VC Fund A', r:15, color:'#1e5a5a'},
                    {id:'V2', label:'Angel Investor', r:13, color:'#1e5a5a'},
                    {id:'V3', label:'VC Fund B', r:15, color:'#1e5a5a'},
                    {id:'PUB', label:'The Local Pub', r:16, color:'#e74c3c', tooltip:'Where three of these deals reportedly started.'},
                    {id:'CAFE', label:'Innovation Cafe', r:15, color:'#e74c3c', tooltip:'Informal weekly meetup spot.'},
                    {id:'INCU', label:'Incubator Space', r:16, color:'#e74c3c', tooltip:'Shared desks - the classic proximity engine.'}
                  ];
                  var links = [
                    {source:'UNI', target:'C1'}, {source:'UNI', target:'C2'}, {source:'UNI', target:'C4'},
                    {source:'C1', target:'INCU'}, {source:'C2', target:'INCU'}, {source:'C3', target:'INCU'},
                    {source:'V1', target:'PUB', weak:true}, {source:'C1', target:'PUB', weak:true},
                    {source:'C4', target:'CAFE', weak:true}, {source:'V2', target:'CAFE', weak:true},
                    {source:'V3', target:'PUB', weak:true}, {source:'C3', target:'CAFE', weak:true},
                    {source:'V1', target:'C1'}, {source:'V2', target:'C2'}, {source:'V3', target:'C4'},
                    {source:'INCU', target:'CAFE', weak:true}
                  ];
                  SerendipityViz.forceNetwork('%s', nodes, links, {height:460, charge:-250});
                ", ns("cambridge-net")))
              )
            )
          ),

          tabPanel("\U0001f3e2 Applicability on Atera Analytics",
            br(),
            fluidRow(
              column(6,
                shg("Atera's Own Local Anchor"),
                app_card("Being Embedded in the Cambridge Ecosystem, Literally",
                  "Atera's academic partnerships with Cambridge are not just a research convenience - per Chapter 4, they place the company inside one of the highest-density innovation clusters in the world. Physical proximity to that university, and to the deep-tech investors who already trust it, is a structural advantage that a purely remote-first competitor would struggle to replicate."),
                app_card("Choosing Where Atera's People Actually Sit",
                  "Chapter 4 suggests a concrete, low-cost decision: prioritising physical desk space near the Cambridge cluster - even partially - over a fully remote setup, specifically for the roles most responsible for partnership and business development, where unplanned contact has the highest payoff.")
              ),
              column(6,
                shg("Manufacturing Informal Venues on Purpose"),
                app_card("Atera Doesn't Need to Wait for a Pub Conversation",
                  "If informal venues are genuine infrastructure, Atera can build its own: a recurring open coffee hour for anyone in the Cambridge CAV/mobility space, a stand at relevant local meetups, or hosting a small quarterly demo evening - deliberately manufacturing the low-stakes, low-friction encounters that a formal pitch meeting can't replace."),
                app_card("Extending the Cluster Logic to Council Relationships",
                  "The same logic applies beyond Cambridge: Atera's UK council relationships benefit from genuine site visits and in-person pilot kick-offs, not just video calls - proximity builds the same kind of accumulated trust locally that Cambridge's cluster built over decades."),
                div(class = "success-box",
                    tags$strong("\u2705 Chapter 4 action point: "),
                    "Launch a recurring, low-cost in-person meetup in Cambridge for the CAV/mobility community - ",
                    "treat it as cluster infrastructure, not marketing spend.")
              )
            )
          )
        )
      )
    )
  )
}

ch4_closer_to_home_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
