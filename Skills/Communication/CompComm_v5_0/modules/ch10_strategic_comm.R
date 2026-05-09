# modules/ch10_strategic_comm.R

ch10_strategic_comm_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero("10", "Strategic Communication",
      "Communication is most powerful when it is deliberate. Setting goals, building plans, handling bad news, managing crises and protecting reputation under pressure.",
      c("Setting Your Goal", "Communication Plans", "Bad News", "Crisis Comms", "Recovery Plans")),

    fluidRow(
      column(2, stat_card("Goal",   "Start with the Outcome")),
      column(2, stat_card("Plan",   "Map Every Audience")),
      column(2, stat_card("Fast",   "Bad News Travels Faster")),
      column(2, stat_card("Own It", "First and Fully")),
      column(2, stat_card("6",      "Crisis Communication Steps")),
      column(2, stat_card("Long",   "Recovery Is a Long Game"))
    ),

    fluidRow(
      tabBox(id = ns("tabs"), width = 12,
        tabPanel("\U0001f4da General Concepts", br(),
          fluidRow(
            column(6,
              sh("Setting Your Goal"),
              framework_card("Begin With the Outcome, Not the Activity",
                "The most common failure in strategic communication planning is beginning with the activity \u2014 \u2018we need a press release\u2019 \u2014 rather than the outcome. A communication goal should be expressed as a specific, measurable change in an audience\u2019s knowledge, attitude or behaviour. Not \u2018increase our profile\u2019 but \u2018ensure that 80% of UK logistics operators with AV programmes are aware of our platform by Q3 2026.\u2019"),
              sh("What a Communication Plan Contains"),
              framework_card("Seven Components of a Strategic Communication Plan",
                "<b>1. Situation analysis:</b> Where are we now? What do key audiences currently know, think and feel?<br>
                 <b>2. Communication goals:</b> What specific changes in knowledge, attitude or behaviour do we want to achieve?<br>
                 <b>3. Audience mapping:</b> Who are our priority audiences?<br>
                 <b>4. Key messages:</b> Golden Thread and three supporting messages per audience.<br>
                 <b>5. Channel strategy:</b> Which channels reach each audience most effectively?<br>
                 <b>6. Activity calendar:</b> What specific content will be delivered, by whom, and when?<br>
                 <b>7. Evaluation:</b> How will success be measured?"),
              sh("Bad News"),
              framework_card("Bad News Does Not Improve With Age",
                "The most reliable rule in crisis communication is the most consistently violated: bad news must be communicated quickly, fully and honestly. Every hour of delay allows the story to grow, speculation to fill the gap, and trust to erode. The organisation that communicates its own bad news \u2014 clearly, calmly and with a plan for resolution \u2014 controls the narrative."),
              sh("Getting Your Retaliation in First"),
              framework_card("Proactive Communication of Difficult News",
                "Getting your retaliation in first means communicating difficult information proactively, before it is discovered or reported by others. This places the organisation in control of the framing, demonstrates honesty, allows context and resolution to be presented simultaneously, and dramatically reduces the duration and intensity of negative coverage."),
              sh("Kitchen Sinking & The Dead Cat"),
              framework_card("Release All Bad News at Once",
                "<b>Kitchen sinking:</b> Release all negative information in a single, well-managed communication rather than allowing it to emerge in a series of damaging instalments. A succession of negative revelations each creates a new news cycle.<br><br>
                 <b>Dead Cat Drop:</b> A deliberately controversial announcement made to draw attention away from a more damaging story. Understanding it is important both for those who might face it and those considering whether the risk is ever worth taking. The consensus: it rarely is.")
            ),
            column(6,
              sh("Crisis Communication"),
              framework_card("The Six Steps of Crisis Communication",
                "<b>Step 1 \u2014 Acknowledge:</b> Recognise the situation exists. Do not minimise, dismiss or go silent.<br>
                 <b>Step 2 \u2014 Express concern:</b> Show that you understand the human impact, not just the organisational consequences.<br>
                 <b>Step 3 \u2014 State what you know:</b> Be factually precise. Do not speculate about what is not yet confirmed.<br>
                 <b>Step 4 \u2014 State what you are doing:</b> Describe the immediate actions you are taking.<br>
                 <b>Step 5 \u2014 State what happens next:</b> Set clear expectations for when and how you will communicate further.<br>
                 <b>Step 6 \u2014 Follow through:</b> Do exactly what you said you would do, when you said you would do it."),
              sh("Recovery Plans"),
              framework_card("Reputation Recovery Is a Long Game",
                "Recovering from a reputational crisis requires a sustained, evidence-led communication programme that demonstrates \u2014 through actions, not just words \u2014 that the organisation has changed or improved. Recovery communications should lead with what has changed; allow third-party voices to validate the recovery narrative; and continue long after the organisation feels the crisis has passed, because audiences remember negative events far longer than organisations think they do."),
              sh("Burying Bad News"),
              framework_card("The Ethical and Practical Limits of Timing Strategy",
                "Releasing bad news alongside more positive announcements or timing it for low-media periods is a recognised tactic. It is also increasingly ineffective: digital journalism means no day is genuinely low-news, and audiences who discover that bad news was deliberately timed to minimise attention tend to react more negatively than they would have to the original news."),
              pull_quote("Start with a specific, measurable communication goal. Communicate bad news fast, fully and honestly. Plan for crisis before it arrives. Recovery is earned through actions, not announcements.", "Simon Hall \u2014 Chapter 10"),
              success_box(tags$strong("Chapter 10 Summary: "), "Begin with measurable goals. Build a 7-component plan. Communicate bad news fast. Get your retaliation in first. In a crisis: acknowledge, empathise, state facts, state actions, set expectations, follow through.")
            )
          )
        ),
        tabPanel("\U0001f3e2 Applicability on Atera Analytics", br(),
          fluidRow(
            column(6,
              shg("Atera\u2019s Strategic Communication Goals for 2026"),
              insight_box("Four SMART Communication Objectives",
                "<b>Goal 1 \u2014 Awareness (Government):</b><br>
                 Ensure Atera\u2019s platform is known to the CCAV policy team and at least 5 Innovate UK programme directors by end of Q2 2026.<br><br>
                 <b>Goal 2 \u2014 Belief (Councils):</b><br>
                 Secure at least 3 UK council pilot agreements by end of Q3 2026.<br><br>
                 <b>Goal 3 \u2014 Behaviour (AV Operators):</b><br>
                 Convert at least 5 AV operator conversations into SaaS trial agreements by end of Q4 2026.<br><br>
                 <b>Goal 4 \u2014 Thought Leadership:</b><br>
                 Achieve coverage in at least 3 relevant trade publications by Q3 2026."),
              shg("Handling Bad News at Atera"),
              insight_box("Proactive Communication of Project Risks",
                "Atera\u2019s risk register identifies 6 high-priority risks (RF > 4) in WP5 and WP6. Strategic communication guidance:<br><br>
                 <b>If a deliverable is delayed:</b> Communicate proactively to Innovate UK before the deadline, not after. Frame with the technical reason, revised timeline and mitigation actions already underway.<br><br>
                 <b>If a technical risk materialises:</b> Apply kitchen sinking \u2014 disclose the full picture in one clear, well-framed communication rather than allowing monitoring officers to discover it incrementally.<br><br>
                 <b>If a commercial conversation falls through:</b> Communicate to internal stakeholders immediately and pivot to the next target on the council pipeline.")
            ),
            column(6,
              shg("Crisis Communication for Atera"),
              insight_box("The Six Steps Applied to Atera\u2019s Three Highest-Probability Scenarios",
                "<b>Scenario 1: A deliverable is significantly delayed</b><br>
                 Acknowledge immediately to Innovate UK; express concern for programme timeline; state what is known (specific deliverable, root cause, impact); state what is being done (mitigation actions with owners); state next update timing; follow through on every commitment made.<br><br>
                 <b>Scenario 2: IP dispute with a consortium partner</b><br>
                 Seek legal guidance immediately (Marks & Clerk); do not communicate publicly until legal position is clear; communicate to Innovate UK factually and without prejudice; maintain professional external tone throughout.<br><br>
                 <b>Scenario 3: Platform security or data breach</b><br>
                 Follow GDPR mandatory reporting requirements first (72-hour window); acknowledge to affected parties immediately; state precisely what data was affected; state actions taken and next steps with timeline."),
              insight_box("Atera\u2019s Long-Term Reputation-Building Plan",
                "Atera\u2019s reputational strength will be built through consistent demonstration of:<br><br>
                 <b>Technical credibility:</b> Validated outputs, published methodology, conference presentations.<br>
                 <b>Commercial credibility:</b> Paying clients, growing pipeline, case studies, testimonials.<br>
                 <b>Policy influence:</b> House of Lords engagement, BSI/ISO standards participation, thought leadership.<br>
                 <b>Human impact:</b> Jobs created, researchers trained, Net Zero contribution, community benefits."),
              success_box(tags$strong("Action Points: "),
                tags$ol(
                  tags$li("Write 4 SMART communication goals for 2026 with named owners"),
                  tags$li("Complete a full strategic communication plan using the 7-component framework"),
                  tags$li("Build a proactive risk communication protocol for each high-priority project risk"),
                  tags$li("Create a crisis communication response template for the 3 most likely scenarios"),
                  tags$li("Design a 12-month reputation-building calendar across all 5 audience groups")
                ))
            )
          )
        )
      )
    )
  )
}

ch10_strategic_comm_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
