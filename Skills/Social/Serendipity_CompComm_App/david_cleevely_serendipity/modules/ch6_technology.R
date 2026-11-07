# modules/ch6_technology.R
# Chapter 6: Technology May Not Save Us

ch6_technology_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("Chapter 6"),
        tags$h2("Technology May Not Save Us"),
        div(
          span(class = "hero-badge", icon("microchip"),   " Digital Connectivity"),
          span(class = "hero-badge", icon("filter"),      " Filter Bubbles"),
          span(class = "hero-badge", icon("triangle-exclamation")," A Counterintuitive Warning")
        )
    ),

    fluidRow(
      box(title = "Chapter 6 - Overview", status = "primary", solidHeader = TRUE, width = 12,
          p("Chapter 6 pushes back on a comfortable assumption: that more technology, more data and more digital ",
            "connectivity automatically produce more serendipity. Cleevely argues the opposite can also be true - ",
            "algorithmic curation, in particular, is often explicitly optimised to show you more of what you already ",
            "engage with, which is close to the opposite of a chance encounter with the unexpected."),
          fluidRow(
            column(3, metric_card("\U0001f4f1", "More Connected \u2260 More Serendipitous")),
            column(3, metric_card("\U0001f3af", "Optimised for Engagement, Not Discovery")),
            column(3, metric_card("\U0001f6b6", "Friction Isn't Always the Enemy")),
            column(3, metric_card("\u2696\ufe0f", "Design Choice, Not Fate"))
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
                sh("The Comfortable Assumption"),
                concept_card("Why We Expect Technology to Increase Serendipity",
                  "It's intuitive to think that connecting more people, faster, with more data, should mechanically increase the number of useful chance encounters - more nodes, more edges, more opportunity for a weak tie to fire. Cleevely doesn't dismiss this outright, but argues it depends entirely on <em>how</em> the technology is designed, not on connectivity alone."),
                sh("Optimised for Engagement, Not Discovery"),
                concept_card("Recommendation Systems Show You More of the Same",
                  "Most consumer algorithms are explicitly optimised to maximise engagement - which usually means showing content statistically similar to what you've already liked. That's the opposite of a structural hole: it narrows your exposure to your existing cluster rather than bridging you to a new one.")
              ),
              column(6,
                sh("Friction Isn't Always the Enemy"),
                concept_card("Some 'Inefficiency' Was Doing Useful Work",
                  "The old inefficiencies of pre-digital life - a shared physical mailroom, a limited number of TV channels everyone watched, a corridor everyone had to walk down - forced a certain amount of shared, unchosen exposure. Removing that friction in the name of efficiency also removed the accidental common ground it produced."),
                concept_card("A Design Choice, Not an Inevitability",
                  "Cleevely's actual conclusion is more hopeful than the chapter title suggests: technology isn't doomed to reduce serendipity, but it won't automatically increase it either. Whether a given tool helps or hurts depends on deliberate design decisions - and those decisions are usually made to optimise something else entirely (attention, revenue, efficiency)."),
                div(class = "success-box",
                    tags$strong("\u2705 Chapter 6 takeaway: "),
                    "Don't assume a new tool or dashboard increases serendipity by default - check whether it was ",
                    "actually designed to broaden exposure, or just to make existing patterns more efficient.")
              )
            )
          ),

          tabPanel("\U0001f4ca Interactive",
            br(),
            fluidRow(
              column(12,
                shg("How Much 'New' Does Each Channel Actually Deliver?"),
                p(style = "font-size:12.5px;color:#546e7a;",
                  "A rough, illustrative comparison of how much genuinely new (not just more of the same) information ",
                  "different channels tend to surface, based on the patterns Cleevely describes. Hover each bar for ",
                  "detail."),
                viz_box(ns("channel-bar"), height = 360,
                        caption = "Illustrative comparison, not a measured statistic"),
                d3_init(sprintf("
                  var data = [
                    {label:'Unplanned hallway chat', value:78, color:'#E8A020'},
                    {label:'Conference coffee break', value:71, color:'#E8A020'},
                    {label:'Curated newsletter', value:54, color:'#3498db'},
                    {label:'Scheduled video call', value:38, color:'#3498db'},
                    {label:'Algorithmic news feed', value:24, color:'#e74c3c'},
                    {label:'Social \"For You\" feed scroll', value:18, color:'#e74c3c'}
                  ];
                  SerendipityViz.barChart('%s', data, {height:360, unit:'%% novel exposure (illustrative)'});
                ", ns("channel-bar"))),
                div(class = "insight-box",
                    tags$h5(class = "ib-title", "Reading the pattern"),
                    tags$p("The channels that score highest share one property: nobody is optimising them for your ",
                           "engagement. They're unfiltered by design - which is precisely why they carry more ",
                           "genuinely unexpected information, even though they feel far less 'efficient'."))
              )
            )
          ),

          tabPanel("\U0001f3e2 Applicability on Atera Analytics",
            br(),
            fluidRow(
              column(6,
                shg("Atera's Own Filter-Bubble Risk"),
                app_card("The Dashboard Can Narrow as Well as Inform",
                  "Atera's platform surfaces AI-scored road-readiness data to councils and AV operators. Chapter 6's warning applies directly: if the dashboard only ever highlights the metrics it was built to optimise, users may stop noticing anomalies or edge cases the model wasn't designed to flag - the same narrowing effect as a social media feed, just wearing a B2B interface."),
                app_card("Designing for Noticing, Not Just Reporting",
                  "A deliberate counter-measure: build a lightweight 'unexpected pattern' panel into the platform - not another optimised KPI, but a genuinely unfiltered view of outliers, so council users retain some of the friction that lets them notice what the model didn't anticipate.")
              ),
              column(6,
                shg("Protecting Unstructured Contact Internally"),
                app_card("Don't Let Slack and Video Calls Replace All Hallway Contact",
                  "As Atera's team grows and becomes more distributed, scheduled video calls will naturally replace some proportion of unplanned contact. Per Chapter 6, that's not a neutral substitution - scheduled calls are efficient but structurally poor at producing new information, because they only happen when someone already knows they need to talk to someone else."),
                app_card("A Small, Deliberate Counter-Measure",
                  "Keep at least one recurring, genuinely unstructured internal session - no agenda, cross-team, in person where possible - specifically because it reintroduces the useful friction that pure efficiency would otherwise remove."),
                div(class = "success-box",
                    tags$strong("\u2705 Chapter 6 action point: "),
                    "Before adopting a new internal tool or dashboard, explicitly ask whether it broadens what people ",
                    "see, or just makes the existing pattern more efficient - and budget for the former.")
              )
            )
          )
        )
      )
    )
  )
}

ch6_technology_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
