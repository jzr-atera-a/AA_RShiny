# modules/ch8_ministry.R
# Chapter 8: The Ministry Of Predictable Outcomes

ch8_ministry_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("Chapter 8"),
        tags$h2("The Ministry Of Predictable Outcomes"),
        div(
          span(class = "hero-badge", icon("landmark"),  " Institutions"),
          span(class = "hero-badge", icon("bullseye"),  " Targets & Bureaucracy"),
          span(class = "hero-badge", icon("scale-balanced"), " Suppressed Uncertainty")
        )
    ),

    fluidRow(
      box(title = "Chapter 8 - Overview", status = "primary", solidHeader = TRUE, width = 12,
          p("Chapter 8 widens the lens from organisations to institutions and government. Cleevely's target: the ",
            "well-meaning machinery of targets, KPIs and pre-defined outcomes that funding bodies and ministries use ",
            "to manage innovation programmes - a machinery that, almost by design, penalises the uncertainty and ",
            "off-plan experimentation that breakthroughs actually require."),
          fluidRow(
            column(3, metric_card("\U0001f3af", "Targets Reward the Predictable")),
            column(3, metric_card("\U0001f4cb", "Bureaucracy as Filter")),
            column(3, metric_card("\U0001f6ab", "Punishing 'Failed' Experiments")),
            column(3, metric_card("\U0001f331", "Funding the Conditions, Not the Outcome"))
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
                sh("Targets Reward the Predictable"),
                concept_card("Measuring What's Easy to Measure",
                  "Funding bodies need accountability, so they specify measurable milestones in advance. The problem, per Cleevely, is that genuine breakthroughs are - by definition - not the thing you specified in advance. A programme funded against pre-set milestones structurally rewards teams for delivering exactly what was predicted, and quietly punishes the pivot that would have delivered something far more valuable."),
                concept_card("Bureaucracy as an Unintentional Filter",
                  "Layers of approval, reporting and process aren't usually designed to suppress serendipity - they're designed to prevent waste and ensure fairness. But each additional layer adds friction to anything that doesn't fit the pre-approved plan, filtering out exactly the kind of off-plan idea that produces genuine breakthroughs."),
                sh("Punishing 'Failed' Experiments"),
                concept_card("A Missed Milestone Looks Identical to a Bad Idea",
                  "In a target-driven system, a team that pivots away from a stated milestone because they found something more promising looks, on paper, exactly like a team that simply failed to deliver. Cleevely argues that most institutional reporting has no way to distinguish 'productive deviation' from 'underperformance' - so both get discouraged equally.")
              ),
              column(6,
                sh("Funding the Conditions, Not Just the Outcome"),
                concept_card("A Different Model: Fund the Capacity to Discover",
                  "Cleevely points to a handful of funding models - DARPA-style programmes, some university block grants - that explicitly fund broad capability and talented people rather than a narrow pre-defined outcome, precisely because the funders accept they can't predict where the value will come from."),
                concept_card("What a 'Ministry of Predictable Outcomes' Would Need to Change",
                  "The chapter's proposed fix isn't to abandon accountability - it's to build reporting structures that explicitly reward well-reasoned pivots as a legitimate outcome, alongside milestone delivery, so institutions stop accidentally selecting against the very experimentation they claim to want."),
                div(class = "success-box",
                    tags$strong("\u2705 Chapter 8 takeaway: "),
                    "Any institution funding innovation should ask whether its own reporting structure rewards ",
                    "predictability at the expense of the uncertainty that real breakthroughs require.")
              )
            )
          ),

          tabPanel("\U0001f4cb Interactive",
            br(),
            fluidRow(
              column(7,
                shg("Control vs. Innovation Capacity - Mapping Institutions"),
                p(style = "font-size:12.5px;color:#546e7a;",
                  "Each point represents a type of institution, plotted by how tightly it controls outcomes in ",
                  "advance (x-axis) against how much genuine innovation capacity it retains (y-axis). Click a point ",
                  "for detail."),
                viz_box(ns("quad"), height = 420,
                        caption = "Illustrative placements, based on Chapter 8's examples"),
                d3_init(sprintf("
                  var data = [
                    {label:'DARPA-style Programme', x:35, y:85, color:'#27ae60', detail:'Funds capable people and broad problem areas rather than fixed deliverables - retains high innovation capacity despite real accountability.'},
                    {label:'University Block Grant', x:25, y:78, color:'#27ae60', detail:'Long-horizon, low-milestone funding - high tolerance for pivots and dead ends.'},
                    {label:'Startup (early stage)', x:20, y:90, color:'#E8A020', detail:'Minimal external control, maximum freedom to pivot - but also minimal accountability.'},
                    {label:'Grant Body (milestone-based)', x:70, y:45, color:'#3498db', detail:'Clear reporting and accountability, but milestone rigidity discourages productive pivots.'},
                    {label:'Regulated Utility', x:90, y:15, color:'#e74c3c', detail:'Extremely tight control for good reason (safety, service continuity) - almost no room for experimentation.'},
                    {label:'Central Ministry Programme', x:85, y:20, color:'#e74c3c', detail:'Detailed pre-set KPIs and heavy reporting - the chapter\\'s namesake pattern.'},
                    {label:'Corporate Skunkworks', x:30, y:70, color:'#27ae60', detail:'Deliberately shielded from the parent company\\'s normal control processes.'}
                  ];
                  SerendipityViz.quadrantScatter('%s', data, {height:420, quadrantLabels:['High freedom, low control','Innovative & controlled','Low freedom, low innovation','Controlled, low innovation']});
                ", ns("quad")))
              ),
              column(5,
                shg("Selected institution"),
                div(id = ns("quad-detail"), class = "framework-card", "Click a point on the chart to see detail here."),
                div(class = "tip-box",
                    tags$strong("\U0001f4a1 Notice: "),
                    "The highest-innovation points aren't the least accountable - they're the ones that fund broad ",
                    "capability rather than narrow, pre-specified deliverables.")
              )
            )
          ),

          tabPanel("\U0001f3e2 Applicability on Atera Analytics",
            br(),
            fluidRow(
              column(6,
                shg("Atera's Own Position on the Chart"),
                app_card("Sitting Uncomfortably Close to the Milestone Trap",
                  "As an Innovate UK-funded programme, Atera reports against defined milestones and work packages - placing it closer to the 'controlled' side of Chapter 8's map than a pure startup would sit. That's a reasonable trade for the funding it provides, but it's worth being deliberate about, rather than letting reporting discipline creep further than it needs to."),
                app_card("Distinguishing Pivots From Underperformance in Atera's Own Reports",
                  "When Atera's roadmap shifts - a work package redirected because a better opportunity emerged - the milestone report should say so explicitly and make the case for the pivot, rather than quietly reframing the new work as if it were always the plan. Being transparent about productive deviation protects the practice for next time.")
              ),
              column(6,
                shg("Applying the Chapter's Lesson Upward and Downward"),
                app_card("Advocating for Better-Designed Funding Conditions",
                  "Where Atera has a voice with Innovate UK or Zenzic monitoring officers, Chapter 8 suggests a constructive ask: reporting formats that have an explicit, non-penalised field for 'what we learned that changed the plan', not just 'what we delivered against the original plan'."),
                app_card("Running Atera's Own Internal Funding the Same Way",
                  "Internally, Atera can apply the same lesson to its own R&D allocation: fund a small pool of engineering capacity against broad capability ('improve model robustness') rather than only against narrow pre-specified features, mirroring the DARPA-style pattern the chapter praises."),
                div(class = "success-box",
                    tags$strong("\u2705 Chapter 8 action point: "),
                    "Add an explicit 'what changed and why' section to Atera's next Innovate UK milestone report, ",
                    "distinct from the delivered-vs-planned table.")
              )
            )
          )
        )
      )
    )
  )
}

ch8_ministry_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
