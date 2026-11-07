# modules/ch2_mad_about_moon.R
# Chapter 2: Mad About The Moon

ch2_mad_about_moon_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("Chapter 2"),
        tags$h2("Mad About The Moon"),
        div(
          span(class = "hero-badge", icon("moon"),        " Historical Discovery"),
          span(class = "hero-badge", icon("rocket"),      " Improbable Breakthroughs"),
          span(class = "hero-badge", icon("clock-rotate-left"), " Circumstance Over Genius")
        )
    ),

    fluidRow(
      box(title = "Chapter 2 - Overview", status = "primary", solidHeader = TRUE, width = 12,
          p("Cleevely turns to history - from Newton to the space race and beyond - to ask a pointed question: ",
            "when a breakthrough looks, in hindsight, almost inevitable, how improbable was it really at the time? ",
            "Chapter 2 argues that the popular, tidy version of most discovery stories hides the mess of failed ",
            "attempts, shelved ideas and pure accident that actually produced them."),
          fluidRow(
            column(3, metric_card("\U0001f9ea", "Improbable, Not Impossible")),
            column(3, metric_card("\U0001f4dc", "The Tidied-Up Story")),
            column(3, metric_card("\u23f3", "Timing Over Talent")),
            column(3, metric_card("\U0001f501", "Repeatable Circumstances"))
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
                sh("The Tidied-Up Story of Discovery"),
                concept_card("History Rewrites Itself Backwards",
                  "Once a discovery is famous, the story around it gets edited for a clean narrative arc: a single flash of insight, a heroic individual, an obvious next step. Cleevely's point is that almost none of the famous breakthroughs actually happened that way - the mess gets quietly removed once the result looks important."),
                concept_card("Fleming and the Mould That Almost Got Thrown Away",
                  "Alexander Fleming didn't set out to discover penicillin. He returned from holiday to find a contaminated petri dish that most researchers would have washed and discarded. What made the difference wasn't a stroke of unique genius - it was that Fleming happened to notice, and happened to already know enough microbiology to recognise what he was looking at."),
                sh("Timing Over Talent"),
                concept_card("Being Ready Beats Being Brilliant",
                  "Many breakthroughs became possible only once an unrelated piece of technology or material became cheap or available - the idea itself had often existed for years, waiting for the world to catch up. Cleevely uses this to argue that timing and circumstance frequently outweigh raw individual talent in determining who gets credit for a discovery.")
              ),
              column(6,
                sh("Repeatable Circumstances, Not Repeatable Genius"),
                concept_card("What Can Actually Be Learned From These Stories",
                  "If the common thread across improbable breakthroughs is circumstance rather than individual brilliance, then the useful lesson isn't \u2018find more geniuses\u2019 - it's \u2018identify which circumstances keep recurring across these stories\u2019: cross-disciplinary contact, tolerance for mess, and someone paying attention at the right moment."),
                concept_card("The Space Race as a Case Study",
                  "The drive to reach the Moon absorbed huge, deliberately organised effort - yet many of its most useful spin-offs (materials, miniaturised electronics, new management techniques) were unplanned by-products, not the mission objective. Even a hugely funded, tightly managed programme still produced most of its lasting value through unplanned adjacency."),
                div(class = "success-box",
                    tags$strong("\u2705 Chapter 2 takeaway: "),
                    "Study the circumstances around a breakthrough, not just the person credited with it - the ",
                    "circumstances are what you can actually try to reproduce.")
              )
            )
          ),

          tabPanel("\U0001f680 Interactive",
            br(),
            fluidRow(
              column(12,
                shg("A Timeline of Improbable Breakthroughs"),
                p(style = "font-size:12.5px;color:#546e7a;",
                  "Click through eight moments where the tidy version of history hides a much stranger true story. ",
                  "Notice how often the real cause was proximity, accident or timing rather than deliberate design."),
                div(id = ns("moon-timeline")),
                d3_init(sprintf("
                  var items = [
                    {year:'1666', title:'Newton and the Apple', detail:'The falling-apple story was likely embellished decades later - what mattered more was Newton isolating himself during plague closures, with unusual uninterrupted time to think.'},
                    {year:'1928', title:'Fleming\\'s Mould', detail:'A contaminated, nearly-discarded petri dish became penicillin only because Fleming happened to already understand what he was seeing.'},
                    {year:'1945', title:'The Melting Chocolate Bar', detail:'Percy Spencer noticed a chocolate bar melting near a radar magnetron - a stray observation that led directly to the microwave oven.'},
                    {year:'1957', title:'Sputnik\\'s Shock', detail:'A single satellite launch reorganised entire national science budgets overnight, showing how one event can suddenly change what an organised system is willing to fund.'},
                    {year:'1968', title:'Earthrise', detail:'A photograph never planned in the Apollo 8 mission brief became one of the most influential images in the environmental movement.'},
                    {year:'1969', title:'The Moon Landing\\'s Hidden Network', detail:'Landing on the Moon depended on thousands of contractors, near-failures and last-minute fixes - a triumph of a loosely coordinated system, not a single command.'},
                    {year:'1974', title:'The Post-it Note', detail:'A 3M chemist\\'s \\'failed\\' weak adhesive sat unused for five years until a colleague needed a bookmark that wouldn\\'t fall out of a hymn book.'},
                    {year:'2020', title:'mRNA\\'s Moment', detail:'Decades of underfunded mRNA research suddenly became the fastest vaccine platform in history - not because the science was new, but because circumstance made it urgent.'}
                  ];
                  SerendipityViz.timeline('%s', items);
                ", ns("moon-timeline")))
              )
            )
          ),

          tabPanel("\U0001f3e2 Applicability on Atera Analytics",
            br(),
            fluidRow(
              column(6,
                shg("Atera's Own 'Tidied-Up' Origin Story"),
                app_card("The Version in the Investor Deck vs. What Actually Happened",
                  "Atera's pitch deck understandably tells a clean story: a clear market gap in CAV infrastructure assessment, met by a purpose-built AI platform. The real sequence - a chance conversation about OpenStreetMap data quality, a Cambridge academic who happened to work on digital twins, an Innovate UK call that almost didn't fit the company's original pitch - is far messier, and far more instructive for what to do next."),
                app_card("Writing Down the Real Sequence",
                  "It's worth Atera's founders documenting the actual, unpolished sequence of decisions and accidents that led to the current platform - not for the pitch deck, but as an internal record of which kinds of circumstance produced the company's best pivots, so the team can recognise them happening again.")
              ),
              column(6,
                shg("Timing Over Talent, Applied to Grant Cycles"),
                app_card("Why the Innovate UK Timing Mattered as Much as the Technology",
                  "Atera's YOLOv8-based computer vision pipeline existed as an approach before the specific Innovate UK CAV funding round opened. The technology being ready when a compatible funding window appeared mattered as much as the underlying research quality - a direct parallel to Fleming's readiness to recognise his contaminated dish."),
                app_card("Building In Slack for the Next Unplanned Window",
                  "Because funding and partnership windows open unpredictably, Atera benefits from keeping one or two speculative technical threads (a promising but unfunded pilot idea, an early conversation with a logistics operator) alive at low cost - so that when the right window opens, the company is Fleming, not the researcher who already washed the dish."),
                div(class = "success-box",
                    tags$strong("\u2705 Chapter 2 action point: "),
                    "Keep a lightweight internal log of 'near-miss' opportunities Atera wasn't ready for - and ",
                    "review it whenever a new funding call or partner conversation opens.")
              )
            )
          )
        )
      )
    )
  )
}

ch2_mad_about_moon_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
