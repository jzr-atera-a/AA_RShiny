# modules/ch6_public_speaking.R
# Chapter 6: Public Speaking, Presenting and Performing

ch6_public_speaking_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("Chapter 6"),
        tags$h2("Public Speaking, Presenting and Performing"),
        div(
          span(class = "hero-badge", icon("microphone"),    " Elevator Pitch"),
          span(class = "hero-badge", icon("film"),          " Slides Done Right"),
          span(class = "hero-badge", icon("chart-bar"),     " Dos & Don\u2019ts of Data"),
          span(class = "hero-badge", icon("bomb"),          " The Killer Fact"),
          span(class = "hero-badge", icon("life-ring"),     " A Lifesaver")
        )
    ),

    fluidRow(
      box(title = "Chapter 6 \u2014 Overview", status = "primary",
          solidHeader = TRUE, width = 12,
          p("Most professionals can write a decent email. Far fewer can stand in a room ",
            "and deliver a presentation that genuinely moves an audience. ",
            "Chapter 6 addresses the fundamentals of public speaking and presenting: ",
            "how to pitch in 60 seconds, how to build a presentation that serves the audience, ",
            "how to use \u2014 and not abuse \u2014 slides and data, and the lifesaving techniques ",
            "that rescue any presentation from difficulty."),
          fluidRow(
            column(2, metric_card("60s",   "Elevator Pitch Limit")),
            column(2, metric_card("1",     "Idea Per Slide Maximum")),
            column(2, metric_card("3",     "Data Points Max Per Chart")),
            column(2, metric_card("Killer","One Unmissable Fact")),
            column(2, metric_card("YOU",   "You Are the Presentation")),
            column(2, metric_card("Plan B","Always Have a Lifesaver"))
          )
      )
    ),

    fluidRow(
      box(title = NULL, status = "primary", solidHeader = FALSE, width = 12,
        tabsetPanel(
          id = ns("tabs"),

          # ── GENERAL CONCEPTS ──────────────────────────
          tabPanel("\U0001f4da General Concepts",
            br(),
            fluidRow(
              column(6,
                sh("The Elevator Pitch"),
                concept_card("60 Seconds to Earn the Next Conversation",
                  "The elevator pitch is not a summary of your organisation \u2014 it is a device 
                  for earning the right to a longer conversation. It must answer three questions 
                  in 60 seconds or less: who you help, what you help them do, 
                  and what makes you the right person or organisation to help them. 
                  Everything else is detail that belongs in the follow-up conversation, not the pitch."),

                concept_card("The Three Components of a Powerful Elevator Pitch",
                  "<b>Component 1 \u2014 The Hook:</b> One sentence that creates immediate interest. 
                  Usually a problem statement, a surprising fact, or a bold claim.<br><br>
                  <b>Component 2 \u2014 The Solution:</b> What you do, expressed in plain language 
                  the listener\u2019s grandmother could understand. No jargon. No qualifiers.<br><br>
                  <b>Component 3 \u2014 The Differentiation:</b> Why you, rather than anyone else. 
                  One specific credential, outcome or proof point that makes you credible and distinct."),

                sh("Building on the Basics"),
                concept_card("The Foundations of Effective Presenting",
                  "Every effective presentation shares five characteristics: 
                  a clear single purpose (what the audience should think, feel or do differently); 
                  an audience-first structure (built around their needs, not the presenter\u2019s knowledge); 
                  a memorable opening and closing; evidence in the form of stories and data combined; 
                  and delivery that is energised, clear and human. 
                  These fundamentals apply equally to a 5-minute pitch and a 45-minute keynote."),

                sh("The Slippery Slope of Slides"),
                concept_card("Slides Are a Visual Aid, Not the Presentation",
                  "The single most common failure in professional presenting is using slides 
                  as a script \u2014 filling them with bullet points and then reading them aloud. 
                  This destroys audience engagement, signals a lack of preparation, 
                  and means the slides and the presenter are competing for attention. 
                  The rule: if someone can understand your full message by reading your slides 
                  without you in the room, your slides have replaced you. That is not their job."),

                concept_card("The Slide Design Hierarchy",
                  "<b>Level 1 \u2014 The headline:</b> States the conclusion, not the topic. 
                  \u2018Revenue grew 40%\u2019 not \u2018Revenue Performance\u2019.<br><br>
                  <b>Level 2 \u2014 The visual:</b> One chart, image or diagram that supports the headline. 
                  The audience should understand it in under 5 seconds.<br><br>
                  <b>Level 3 \u2014 Supporting detail:</b> Maximum 3 bullet points if text is essential. 
                  Never full sentences. Never paragraphs.<br><br>
                  If any slide requires more than this, it should be two slides.")
              ),

              column(6,
                sh("Character in Slides"),
                concept_card("Let Personality Into Your Visual Design",
                  "Slides do not need to be corporate templates filled with logo-heavy headers 
                  and identical bullet point layouts. Personality in slide design \u2014 bold typography, 
                  unexpected imagery, whitespace, contrast \u2014 signals confidence and creativity. 
                  The audience forms an impression of the organisation\u2019s quality and culture 
                  partly from the aesthetic quality of its presentation materials. 
                  Generic slides suggest a generic organisation."),

                sh("The Dos and Don\u2019ts of Data"),
                concept_card("Data Needs a Story to Land",
                  "A chart or statistic presented without context is just a number. 
                  Data lands when it is: presented in the simplest possible visual form, 
                  anchored by a headline that states the conclusion (not the topic), 
                  connected to a human implication or consequence, 
                  and compared to something the audience already understands. 
                  The question to ask of every data point: \u2018So what does this mean for the audience?\u2019"),

                concept_card("Data Don\u2019ts \u2014 The Most Common Mistakes",
                  "<b>Too much data:</b> Three data points per chart maximum. 
                  If you have more, you are telling the audience everything and helping them understand nothing.<br><br>
                  <b>No conclusion:</b> Never show a chart without a headline that states what the chart proves.<br><br>
                  <b>Wrong chart type:</b> Use bar charts for comparison, line charts for change over time, 
                  pie charts sparingly and only for simple proportions. Avoid 3D charts entirely.<br><br>
                  <b>Tiny text:</b> Every number and label on a chart must be readable from the back of the room."),

                sh("The Killer Fact"),
                concept_card("One Number That Changes Everything",
                  "Every presentation benefits from one killer fact \u2014 a single statistic or finding 
                  so surprising, so significant or so counter to the audience\u2019s expectations 
                  that it reframes the entire conversation. The killer fact is not necessarily 
                  the most important data point; it is the one with the greatest emotional and 
                  intellectual impact. It should be delivered slowly, clearly and without qualification, 
                  and it should be given enough silence afterwards for the audience to absorb it.")
              )
            ),

            hr(class = "divider"),
            fluidRow(
              column(6,
                sh("A Lifesaver"),
                concept_card("What to Do When Things Go Wrong",
                  "Every experienced presenter has a lifesaver \u2014 a technique for recovering composure 
                  and control when something unexpected happens: technology fails, a question throws you, 
                  you lose your place, the audience goes cold. The core lifesaver technique is the pause: 
                  stop, breathe, smile, and take three seconds before continuing. 
                  In those three seconds, the audience will almost never perceive a problem. 
                  The presenter who remains calm and in control when things go wrong actually 
                  gains credibility rather than losing it."),

                concept_card("Preparing Lifesaver Responses for Difficult Moments",
                  "Prepare in advance for the three most likely things that could go wrong 
                  in any specific presentation: technology failure (know the presentation without slides); 
                  a hostile question (have a bridging phrase ready: \u2018That\u2019s an important point \u2014 
                  let me address that directly\u2019); and losing your thread 
                  (return to your Golden Thread: \u2018The key point I want to leave you with is...\u2019)")
              ),

              column(6,
                div(class = "tip-box",
                    tags$strong("\U0001f4a1 The Presenting Mindset: "),
                    "The audience wants you to succeed. They are not looking for you to fail. 
                    Every audience in every professional context begins on your side. 
                    Your job is simply to give them something worth their attention \u2014 
                    and to deliver it with enough energy and clarity to honour the time they have given you."),

                div(class = "success-box",
                    tags$strong("\u2705 Chapter 6 Summary: "),
                    "Know your 60-second pitch cold. Build every presentation around one clear purpose. 
                    Use slides as visual support, not as a script. Lead every data point with its conclusion. 
                    Place one killer fact where it will have maximum impact. 
                    And always have a lifesaver ready.")
              )
            )
          ), # end General Concepts

          # ── ATERA ANALYTICS APPLICATION ──────────────
          tabPanel("\U0001f3e2 Applicability on Atera Analytics",
            br(),
            fluidRow(
              column(6,
                shg("Atera\u2019s Elevator Pitch \u2014 Three Versions"),
                app_card("60-Second Pitches for Different Contexts",
                  "<b>For a networking event / general audience:</b><br>
                  <em>\u2018The UK is about to deploy autonomous vehicles onto roads that have never been 
                  properly assessed for readiness. We built the platform that does that assessment 
                  \u2014 using AI, GIS and real-time data. We\u2019re government-funded, and we\u2019re 
                  bringing it to market this year.\u2019</em><br><br>
                  <b>For a council officer:</b><br>
                  <em>\u2018Do you know which of your roads are ready for autonomous vehicles? 
                  Most councils don\u2019t \u2014 there\u2019s no standard way to assess it. 
                  Our platform scores any road segment in real time, so you have 
                  evidence-based infrastructure intelligence before you need it.\u2019</em><br><br>
                  <b>For an investor:</b><br>
                  <em>\u2018There\u2019s a \u00a32 billion UK smart mobility market with no infrastructure 
                  assessment layer. We\u2019re building it \u2014 Innovate UK-funded, technically validated, 
                  and entering the market in Q2 2026 across four revenue streams.\u2019</em>"),

                shg("Fixing Atera\u2019s Slide Decks"),
                app_card("Applying the Slide Design Hierarchy to Atera Materials",
                  "Atera\u2019s current slide decks contain strong content but typically use 
                  topic headings rather than conclusion headlines, and include more text 
                  per slide than ideal for live delivery. Suggested rewrites:<br><br>"),
                example_pair(
                  bad_text  = "Work Package 5: Data Integration and Architecture \u2014 Status Update \u2014 \u2022 CAM Operations Data Enablement \u2022 End-to-End Architecture Design \u2022 Validate EV CAM performance data \u2022 Digital Data Model Definition \u2022 Data Integration with External Sources \u2022 AI Data Enrichment \u2022 Visualisation of Route Navigation Data",
                  good_text = "All 7 WP5 Deliverables Complete \u2014 Milestone 5 Achieved (\u00a328,419) \n\nThe platform now integrates 50,000+ EV charging points, a validated digital twin of UK roads, and real-time route navigation visualisation."
                ),

                app_card("Character in Atera\u2019s Slides",
                  "Atera\u2019s brand \u2014 the circuit-style logo, the dark colour palette, the technical precision \u2014 
                  conveys a distinctive identity that should be reflected in slide design. 
                  Recommendations for presentation materials:<br><br>
                  Use full-bleed dark backgrounds for key statement slides (bold, high-contrast).<br>
                  Use dashboard screenshots as evidence slides \u2014 they are more compelling than bullet lists.<br>
                  Include one \u2018hero visual\u2019 per presentation: the route map showing AV readiness scoring 
                  in action is Atera\u2019s most powerful visual asset and should appear early in every deck.")
              ),

              column(6,
                shg("Atera\u2019s Killer Facts"),
                app_card("The Data Points That Reframe the Conversation",
                  "Atera has access to several potential killer facts \u2014 each suited to a different audience:<br><br>
                  <b>For councils:</b> \u2018More than 100 UK local authorities currently have no standardised 
                  framework to assess whether their roads are ready for autonomous vehicles \u2014 
                  yet AV trials are already taking place on public roads.\u2019<br><br>
                  <b>For investors:</b> \u2018The UK government has committed over \u00a3200 million to 
                  CAV infrastructure programmes without a national scoring system to determine 
                  where that investment should go.\u2019<br><br>
                  <b>For AV operators:</b> \u2018Our platform assessed a 4.12km Cambridge test route \u2014 
                  identifying risk zones, charging infrastructure and AV readiness score \u2014 
                  in real time. A traditional manual survey of the same route would take several days.\u2019<br><br>
                  Each of these should be delivered as a standalone statement, slowly, 
                  followed by a 3-second pause."),

                shg("Dos and Don\u2019ts of Data for Atera Presentations"),
                app_card("Applying the Data Rules to Atera\u2019s Technical Evidence",
                  "<b>DO:</b> Lead every chart with a conclusion headline 
                  (\u2018M1\u2013M5 delivered on schedule and on budget\u2019 not \u2018Milestone Summary\u2019).<br>
                  <b>DO:</b> Use the risk register heat map as a visual \u2014 it shows progress 
                  from risk factor 6 to 4 across all high-priority items, which is a strong story.<br>
                  <b>DO:</b> Show the dashboard route map screenshot as your primary data visual 
                  \u2014 it communicates more than any table of deliverables.<br><br>
                  <b>DON\u2019T:</b> Show the full work package deliverable table on a single slide.<br>
                  <b>DON\u2019T:</b> Use three-decimal-place figures in presentations 
                  (\u2018\u00a328,419.05\u2019 should be \u2018\u00a328,400\u2019 or \u2018nearly \u00a330,000\u2019 in a spoken context).<br>
                  <b>DON\u2019T:</b> Include a risk register table in a stakeholder presentation 
                  without a headline that summarises what it shows."),

                app_card("Lifesaver Preparation for Atera\u2019s Key Presentations",
                  "For each major presentation, prepare responses to the three most likely difficult moments:<br><br>
                  <b>Dashboard demo fails:</b> \u2018Let me walk you through what you would see \u2014 
                  and I\u2019ll send you a recorded demo immediately after this meeting.\u2019<br><br>
                  <b>Hostile question about commercial viability:</b> \u2018That\u2019s exactly the right question 
                  to ask \u2014 and it\u2019s one we\u2019ve thought hard about. Let me show you our four revenue streams.\u2019<br><br>
                  <b>Question you cannot answer:</b> \u2018I want to give you an accurate answer rather than 
                  an approximate one \u2014 let me come back to you on that specifically by end of week.\u2019"),

                div(class = "success-box",
                    tags$strong("\u2705 Chapter 6 Action Points for Atera: "),
                    tags$ol(
                      tags$li("Write and rehearse three versions of the elevator pitch (general, council, investor)"),
                      tags$li("Redesign the Q3 progression deck with conclusion headlines on every slide"),
                      tags$li("Identify one killer fact per audience and mark it in the presentation script"),
                      tags$li("Prepare three lifesaver responses for the next major stakeholder presentation"),
                      tags$li("Replace all deliverable tables with the dashboard screenshot as primary visual")
                    ))
              )
            )
          ) # end Atera tab
        ) # end tabsetPanel
      ) # end box
    ) # end fluidRow
  )
}

ch6_public_speaking_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
  })
}
