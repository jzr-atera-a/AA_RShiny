# modules/conclusion.R
# The Edge Of Chaos, Revisited - Bringing It All Together

conclusion_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("A Compelling Conclusion"),
        tags$h2("Bringing It All Together - Designing Atera's Conditions for Serendipity"),
        div(
          span(class = "hero-badge", icon("check-double"),  " All 10 Chapters"),
          span(class = "hero-badge", icon("road"),          " Atera's Roadmap"),
          span(class = "hero-badge", icon("dice"),          " Deliberate Luck"),
          span(class = "hero-badge", icon("rocket"),        " Ready for Market")
        )
    ),

    fluidRow(
      box(title = "\U0001f3c1 The Book in One Page", status = "primary", solidHeader = TRUE, width = 12,
          p("David Cleevely's ", tags$em("Serendipity"), " can be distilled into a single principle: ",
            tags$b("luck is not random - it's a property of the conditions you build."),
            " Every chapter serves that principle - from the entangled web of Chapter 1 to the fertile ",
            "edge-of-chaos balance of Chapter 10. Below is the master synthesis: each chapter's core insight in ",
            "one line, followed by the complete roadmap for Atera Analytics."),
          hr(class = "divider"),
          fluidRow(
            column(6,
              sh("The 10 Core Insights"),
              timeline_entry("1",  "The Entangled Bank",
                "Innovation is a property of interconnected systems, not isolated individuals - map the web, don't just credit the person."),
              timeline_entry("2",  "Mad About The Moon",
                "Famous breakthroughs are messier and more improbable than their tidied-up histories suggest - study the circumstances, not just the genius."),
              timeline_entry("3",  "How Networks Work",
                "Weak ties and structural-hole brokers carry far more novel opportunity than your close, dense network ever will."),
              timeline_entry("4",  "Closer To Home",
                "Physical proximity and a genuine local anchor still matter - the Cambridge cluster is compounding density, not accident."),
              timeline_entry("5",  "The Prepared Mind",
                "Chance favours the mind that's broad, attentive to anomalies, and willing to act on a hunch before it's proven."),
              timeline_entry("6",  "Technology May Not Save Us",
                "More connectivity doesn't automatically mean more serendipity - most algorithms are optimised for engagement, not discovery."),
              timeline_entry("7",  "Too Well Organised To Adapt",
                "Every efficiency gain trades away some adaptive capacity - protect deliberate slack on purpose."),
              timeline_entry("8",  "The Ministry Of Predictable Outcomes",
                "Rigid targets and bureaucracy quietly punish the productive pivots that real breakthroughs require."),
              timeline_entry("9",  "The Road Most Travelled",
                "The familiar path has diminishing returns - deliberate exposure to different people and places compounds instead."),
              timeline_entry("10", "The Edge Of Chaos",
                "The most fertile systems sit between rigid order and pure disorder - and need constant, deliberate re-tuning.")
            ),
            column(6,
              sh("Atera's Single Unifying Question"),
              quote_block(
                "Can Atera Analytics deliberately design the conditions that produced its best breaks so far - rather than simply hoping the next one arrives on schedule?",
                "Atera Analytics - the Serendipity question, restated"
              ),
              br(),
              sh("The Three Priorities for Immediate Action"),
              concept_card("\U0001f947 Priority 1 - This Week",
                  "Log the real, unpolished origin story of Atera's three best partnerships (Ch.2). Add a 'source of first contact' field to the CRM (Ch.3). Ring-fence one recurring unstructured team session (Ch.6)."),
              concept_card("\U0001f948 Priority 2 - This Month",
                  "Launch a recurring in-person Cambridge meetup for the CAV/mobility community (Ch.4). Add a standing 'anomaly of the week' agenda slot (Ch.5). Book one clearly out-of-circuit conference for next quarter (Ch.9)."),
              concept_card("\U0001f949 Priority 3 - This Quarter",
                  "Ring-fence a fixed slice of engineering time as genuine slack (Ch.7). Add a 'what changed and why' section to the next Innovate UK milestone report (Ch.8). Run the first quarterly 'edge-of-chaos check-in' (Ch.10).")
            )
          )
      )
    ),

    fluidRow(
      box(title = "\U0001f5fa\ufe0f Atera's Complete Serendipity Roadmap", status = "success", solidHeader = TRUE, width = 12,
          fluidRow(
            column(3,
              app_card("\U0001f9e9 Systems & History (Ch 1\u20132)",
                    "\u2705 Entangled-bank dependency map drawn<br>
                     \u2705 Real founding sequence documented<br>
                     \u2705 'Near-miss opportunity' log started<br>
                     \u2705 Circumstances behind past wins reviewed<br>
                     \u2705 Simplification risks flagged before cuts<br>
                     \u2705 Timing windows tracked, not just talent")
            ),
            column(3,
              app_card("\U0001f578\ufe0f Networks & Place (Ch 3\u20134)",
                    "\u2705 Weak-tie sources tracked in CRM<br>
                     \u2705 Broker role between clusters protected<br>
                     \u2705 Cambridge desk presence prioritised<br>
                     \u2705 Recurring informal meetup launched<br>
                     \u2705 In-person council site visits kept<br>
                     \u2705 Cross-cluster time explicitly funded")
            ),
            column(3,
              app_card("\U0001f9e0 Mindset & Technology (Ch 5\u20136)",
                    "\u2705 Prepared-mind hiring criteria widened<br>
                     \u2705 'Anomaly of the week' slot running<br>
                     \u2705 Protected exploration time in sprints<br>
                     \u2705 Unfiltered outlier panel added to platform<br>
                     \u2705 One unstructured cross-team session kept<br>
                     \u2705 New tools checked for 'broadens vs narrows'")
            ),
            column(3,
              app_card("\u2696\ufe0f Structure & Balance (Ch 7\u201310)",
                    "\u2705 Efficiency/adaptability dial set on purpose<br>
                     \u2705 Pivots reported honestly, not reframed<br>
                     \u2705 DARPA-style internal funding pool trialled<br>
                     \u2705 Out-of-circuit event booked and rotated<br>
                     \u2705 Edge-of-chaos check-in on the agenda<br>
                     \u2705 Quarterly drift review scheduled")
            )
          )
      )
    ),

    fluidRow(
      box(title = "\U0001f4ca Serendipity Readiness Tracker", status = "info", solidHeader = TRUE, width = 6,
          p(style = "font-size:13px; color:#555; margin-bottom:16px;",
            "Self-assessment: how deliberately is Atera designing the conditions for useful accidents, across all 10 chapters?"),
          progress_bar_item("Ch 1 - Mapping the Entangled Bank",       35),
          progress_bar_item("Ch 2 - Learning From Real Circumstances", 30),
          progress_bar_item("Ch 3 - Cultivating Weak Ties",            45),
          progress_bar_item("Ch 4 - Cambridge Cluster Presence",       55),
          progress_bar_item("Ch 5 - Prepared-Mind Culture",            25),
          progress_bar_item("Ch 6 - Technology Serving Discovery",     20),
          progress_bar_item("Ch 7 - Protected Slack",                  15),
          progress_bar_item("Ch 8 - Honest Pivot Reporting",           30),
          progress_bar_item("Ch 9 - Deliberate Detours",               20),
          progress_bar_item("Ch 10 - Edge-of-Chaos Discipline",        15),
          div(class = "tip-box", style = "margin-top:16px;",
              tags$strong("\U0001f4a1 How to use this tracker: "),
              "Update each bar as Atera completes the action points for each chapter. The goal is a deliberately ",
              "maintained balance across all ten dimensions - not a maximum score on any single one.")
      ),

      box(title = "\U0001f3af The Final Word", status = "primary", solidHeader = TRUE, width = 6,
          concept_card("What Separates Lucky Organisations From Deliberately Fortunate Ones",
                  "The difference is not luck itself - it is design. Deliberately fortunate organisations build wide, loosely-connected networks. They stay physically close to the places where trust and talent already concentrate. They protect curious, attentive people and give them room to act on a hunch. They resist the pull toward total efficiency, and they resist the pull toward total chaos. And when a genuine accident does pay off, they notice it, name it, and build the conditions to make the next one more likely."),
          concept_card("Atera's Serendipity Opportunity",
                  "Atera Analytics already has a track record of turning chance encounters - a Cambridge introduction, a council conversation, a redirected grant call - into real commercial traction. Serendipity's argument is that this is repeatable: not by planning the next breakthrough directly, but by deliberately building the network density, physical presence, prepared people and organisational slack that keep producing them."),
          br(),
          div(class = "success-box",
              tags$strong("\u2728 The Golden Rule of Serendipity: "),
              tags$em("You can't plan the breakthrough - but you can absolutely plan the conditions that make it more likely."),
              tags$br(), tags$br(),
              "Apply this to Atera's hiring, its calendar, its office location, its funding structure and its next ",
              "milestone report. Do it deliberately. The luck will compound.")
      )
    )
  )
}

conclusion_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
