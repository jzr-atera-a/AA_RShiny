# modules/ch6_public_speaking.R

ch6_public_speaking_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero("6", "Public Speaking, Presenting and Performing",
      "Know your 60-second pitch cold. Use slides as visual support, not a script. Lead every data point with its conclusion. Always have a lifesaver ready.",
      c("Elevator Pitch", "Slide Design", "Dos & Don'ts of Data", "Killer Fact", "Lifesaver")),

    fluidRow(
      column(2, stat_card("60s",    "Elevator Pitch Limit")),
      column(2, stat_card("1",      "Idea Per Slide Max")),
      column(2, stat_card("3",      "Data Points Per Chart Max")),
      column(2, stat_card("Killer", "One Unmissable Fact")),
      column(2, stat_card("YOU",    "You Are the Presentation")),
      column(2, stat_card("Plan B", "Always Have a Lifesaver"))
    ),

    fluidRow(
      tabBox(id = ns("tabs"), width = 12,
        tabPanel("\U0001f4da General Concepts", br(),
          fluidRow(
            column(6,
              sh("The Elevator Pitch"),
              framework_card("60 Seconds to Earn the Next Conversation",
                "The elevator pitch is not a summary of your organisation \u2014 it is a device for earning the right to a longer conversation. It must answer three questions in 60 seconds: who you help, what you help them do, and what makes you the right person to help them. Everything else is detail for the follow-up."),
              framework_card("Three Components of a Powerful Elevator Pitch",
                "<b>Component 1 \u2014 The Hook:</b> One sentence that creates immediate interest. Usually a problem statement, a surprising fact, or a bold claim.<br><br>
                 <b>Component 2 \u2014 The Solution:</b> What you do, expressed in plain language. No jargon. No qualifiers.<br><br>
                 <b>Component 3 \u2014 The Differentiation:</b> Why you, rather than anyone else. One specific credential or proof point."),
              sh("The Slippery Slope of Slides"),
              framework_card("Slides Are a Visual Aid, Not the Presentation",
                "The most common failure in professional presenting is using slides as a script \u2014 filling them with bullet points and reading them aloud. This destroys engagement, signals a lack of preparation, and means the slides and presenter are competing for attention. If someone can understand your full message by reading your slides without you present, your slides have replaced you."),
              framework_card("The Slide Design Hierarchy",
                "<b>Level 1 \u2014 The headline:</b> States the conclusion, not the topic. \u2018Revenue grew 40%\u2019 not \u2018Revenue Performance\u2019.<br>
                 <b>Level 2 \u2014 The visual:</b> One chart or image the audience understands in 5 seconds.<br>
                 <b>Level 3 \u2014 Supporting detail:</b> Maximum 3 bullet points if text is essential. Never full sentences."),
              sh("Character in Slides"),
              framework_card("Let Personality Into Your Visual Design",
                "Slides do not need to be corporate templates with identical bullet layouts. Personality in slide design \u2014 bold typography, unexpected imagery, whitespace, contrast \u2014 signals confidence and creativity. The audience forms an impression of the organisation\u2019s quality and culture partly from the aesthetic quality of its presentation materials.")
            ),
            column(6,
              sh("The Dos and Don\u2019ts of Data"),
              framework_card("Data Needs a Story to Land",
                "A chart without context is just a number. Data lands when it is: presented in the simplest possible visual form, anchored by a headline that states the conclusion, connected to a human implication, and compared to something the audience already understands."),
              algo_table(
                headers = c("Do", "Don\u2019t"),
                rows = list(
                  c("Lead every chart with a conclusion headline", "Show a chart with a topic label instead"),
                  c("Use 3 data points per chart maximum", "Cram every metric into one slide"),
                  c("Use bar charts for comparison, line charts for change", "Use 3D charts ever"),
                  c("Make every number readable from the back of the room", "Use font size under 18pt in slides")
                )
              ),
              sh("The Killer Fact"),
              framework_card("One Number That Changes Everything",
                "Every presentation benefits from one killer fact \u2014 a single statistic so surprising, so significant or so counter to expectations that it reframes the entire conversation. Deliver it slowly, clearly and without qualification, and give it enough silence afterwards for the audience to absorb it."),
              sh("A Lifesaver"),
              framework_card("What to Do When Things Go Wrong",
                "Every experienced presenter has a lifesaver \u2014 a technique for recovering composure when something unexpected happens: technology fails, a question throws you, the audience goes cold. The core lifesaver technique is the pause: stop, breathe, smile, and take three seconds before continuing. The presenter who remains calm when things go wrong actually gains credibility."),
              tip_box(tags$strong("The Presenting Mindset: "), "The audience wants you to succeed. They are not looking for you to fail. Every audience in every professional context begins on your side."),
              success_box(tags$strong("Chapter 6 Summary: "), "Know your 60-second pitch cold. Slides are visual support. Lead data with its conclusion. One killer fact per presentation. Always have a lifesaver.")
            )
          )
        ),
        tabPanel("\U0001f3e2 Applicability on Atera Analytics", br(),
          fluidRow(
            column(6,
              shg("Atera\u2019s Elevator Pitch \u2014 Three Versions"),
              insight_box("For a General Networking Event",
                "\u2018The UK is about to deploy autonomous vehicles onto roads that have never been properly assessed for readiness. We built the platform that does that assessment \u2014 using AI, GIS and real-time data. We\u2019re government-funded, and we\u2019re bringing it to market this year.\u2019"),
              insight_box("For a Council Officer",
                "\u2018Do you know which of your roads are ready for autonomous vehicles? Most councils don\u2019t \u2014 there\u2019s no standard way to assess it. Our platform scores any road segment in real time, so you have evidence-based intelligence before you need it.\u2019"),
              insight_box("For an Investor",
                "\u2018There\u2019s a \u00a32 billion UK smart mobility market with no infrastructure assessment layer. We\u2019re building it \u2014 Innovate UK-funded, technically validated, and entering the market in Q2 2026 across four revenue streams.\u2019"),
              shg("Atera\u2019s Killer Facts"),
              insight_box("The Data Points That Reframe the Conversation",
                "<b>For councils:</b> \u2018More than 100 UK local authorities currently have no standardised framework to assess whether their roads are ready for autonomous vehicles \u2014 yet AV trials are already taking place on public roads.\u2019<br><br>
                 <b>For investors:</b> \u2018The UK government has committed over \u00a3200 million to CAV infrastructure programmes without a national scoring system to determine where that investment should go.\u2019<br><br>
                 <b>For AV operators:</b> \u2018Our platform assessed a 4.12km Cambridge test route \u2014 identifying risk zones, charging infrastructure and AV readiness score \u2014 in real time. A traditional manual survey would take several days.\u2019")
            ),
            column(6,
              shg("Fixing Atera\u2019s Slide Decks"),
              example_pair(
                bad_text = "Work Package 5: Data Integration and Architecture \u2014 Status \u2014 \u2022 CAM Operations Data Enablement \u2022 End-to-End Architecture Design \u2022 Validate EV CAM performance data \u2022 Digital Data Model Definition \u2022 Data Integration \u2022 AI Data Enrichment \u2022 Route Navigation Visualisation",
                good_text = "All 7 WP5 Deliverables Complete \u2014 Milestone 5 Achieved (\u00a328,419)\n\nThe platform now integrates 50,000+ EV charging points, a validated digital twin of UK roads, and real-time route navigation visualisation."
              ),
              shg("Lifesaver Preparation for Atera"),
              insight_box("Pre-Prepared Responses for Difficult Moments",
                "<b>Dashboard demo fails:</b> \u2018Let me walk you through what you would see \u2014 and I\u2019ll send you a recorded demo immediately after this meeting.\u2019<br><br>
                 <b>Hostile question about viability:</b> \u2018That\u2019s exactly the right question \u2014 and it\u2019s one we\u2019ve thought hard about. Let me show you our four revenue streams.\u2019<br><br>
                 <b>Question you cannot answer:</b> \u2018I want to give you an accurate answer rather than an approximate one \u2014 let me come back to you on that specifically by end of week.\u2019"),
              success_box(tags$strong("Action Points: "),
                tags$ol(
                  tags$li("Write and rehearse three versions of the elevator pitch"),
                  tags$li("Redesign the Q3 deck with conclusion headlines on every slide"),
                  tags$li("Identify one killer fact per audience and mark it in the script"),
                  tags$li("Prepare three lifesaver responses for the next major presentation"),
                  tags$li("Replace deliverable tables with the dashboard screenshot as primary visual")
                ))
            )
          )
        )
      )
    )
  )
}

ch6_public_speaking_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
