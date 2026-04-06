# modules/ch10_strategic_comm.R
# Chapter 10: Strategic Communication

ch10_strategic_comm_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("Chapter 10"),
        tags$h2("Strategic Communication"),
        div(
          span(class = "hero-badge", icon("bullseye"),      " Setting Your Goal"),
          span(class = "hero-badge", icon("map"),           " Communication Plans"),
          span(class = "hero-badge", icon("exclamation"),   " Bad News"),
          span(class = "hero-badge", icon("shield-alt"),    " Crisis Communication"),
          span(class = "hero-badge", icon("redo"),          " Recovery Plans"),
          span(class = "hero-badge", icon("chess-king"),    " Kitchen Sinking")
        )
    ),

    fluidRow(
      box(title = "Chapter 10 \u2014 Overview", status = "primary",
          solidHeader = TRUE, width = 12,
          p("Communication is most powerful when it is deliberate. ",
            "Chapter 10 brings together everything in the book to show how communication ",
            "can be planned, managed and deployed as a genuine strategic asset \u2014 ",
            "not just in good times but especially in difficult ones. ",
            "Setting goals, building plans, handling bad news, managing crises ",
            "and protecting reputation under pressure: these are the skills that ",
            "define the most capable communicators in any field."),
          fluidRow(
            column(2, metric_card("Goal",     "Start with the Outcome")),
            column(2, metric_card("Plan",     "Map Every Audience")),
            column(2, metric_card("Fast",     "Bad News Travels Faster")),
            column(2, metric_card("Own It",   "First and Fully")),
            column(2, metric_card("Recover",  "Plan Before the Crisis")),
            column(2, metric_card("Strategic","Every Word Has Purpose"))
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
                sh("Setting Your Goal"),
                concept_card("Begin With the Outcome, Not the Activity",
                  "The most common failure in strategic communication planning is beginning 
                  with the activity \u2014 \u2018we need a press release\u2019; \u2018we should post more on LinkedIn\u2019 \u2014 
                  rather than the outcome. A communication goal should be expressed as 
                  a specific, measurable change in an audience\u2019s knowledge, attitude or behaviour. 
                  Not \u2018increase our profile\u2019 but \u2018ensure that 80% of UK logistics operators 
                  with AV programmes are aware of our platform by Q3 2026.\u2019 
                  The goal determines the strategy; the strategy determines the tactics."),

                concept_card("SMART Communication Goals",
                  "Effective communication goals are specific, measurable, achievable, 
                  relevant and time-bound. They name the audience precisely, 
                  define what change is sought (awareness, belief, behaviour), 
                  set a measurable indicator of success, 
                  and attach a realistic timeframe. 
                  A goal without a measurable outcome is a wish, not a plan."),

                sh("Strategic Communication Plans"),
                concept_card("What a Communication Plan Contains",
                  "A complete strategic communication plan includes:<br><br>
                  <b>1. Situation analysis:</b> Where are we now? What do our key audiences currently 
                  know, think and feel about us?<br><br>
                  <b>2. Communication goals:</b> What specific changes in knowledge, attitude 
                  or behaviour do we want to achieve, by when?<br><br>
                  <b>3. Audience mapping:</b> Who are our priority audiences? What do they need 
                  from us and what do we need from them?<br><br>
                  <b>4. Key messages:</b> What is the Golden Thread and three supporting messages 
                  for each audience group?<br><br>
                  <b>5. Channel strategy:</b> Which channels reach each audience most effectively?<br><br>
                  <b>6. Activity calendar:</b> What specific content and activity will be delivered, 
                  by whom, and when?<br><br>
                  <b>7. Evaluation:</b> How will success be measured?"),

                sh("The Elements of a Strategic Communication Plan"),
                concept_card("Audiences, Messages, Channels, Timing",
                  "Strategic communication is the deliberate alignment of four elements: 
                  the right audience, the right message, the right channel, at the right time. 
                  A compelling message delivered to the wrong audience achieves nothing. 
                  The right message on the wrong channel is never seen. 
                  Perfect timing with the wrong message is a missed opportunity. 
                  Strategic communication plans succeed when all four elements align.")
              ),

              column(6,
                sh("Bad News"),
                concept_card("Bad News Does Not Improve With Age",
                  "The most reliable rule in crisis communication is also the most consistently violated: 
                  bad news must be communicated quickly, fully and honestly. 
                  Every hour of delay allows the story to grow, speculation to fill the gap, 
                  and trust to erode. The organisation that communicates its own bad news 
                  \u2014 clearly, calmly and with a plan for resolution \u2014 
                  controls the narrative and limits the damage. 
                  The organisation that waits for the story to break through other channels 
                  loses control of the narrative and the trust of its audiences simultaneously."),

                sh("Getting Your Retaliation in First"),
                concept_card("Proactive Communication of Difficult News",
                  "Getting your retaliation in first means communicating difficult or 
                  potentially embarrassing information proactively, before it is discovered 
                  or reported by others. This approach: places the organisation in control 
                  of the framing; demonstrates honesty and transparency; 
                  allows the organisation to simultaneously present the context and resolution plan; 
                  and dramatically reduces the duration and intensity of negative coverage. 
                  The alternative \u2014 waiting to be asked \u2014 always produces worse outcomes."),

                sh("Kitchen Sinking"),
                concept_card("Release All the Bad News at Once",
                  "Kitchen sinking is the practice of releasing all negative information 
                  in a single, well-managed communication rather than allowing it to emerge 
                  in a series of damaging instalments. A succession of negative revelations 
                  each creates a new news cycle, extending the damage over weeks or months. 
                  A single, comprehensive disclosure \u2014 honestly framed with context and resolution 
                  \u2014 creates one difficult news cycle that passes and is replaced by the recovery narrative."),

                sh("The Dead Cat Drop"),
                concept_card("Distraction as a Communication Tactic",
                  "The Dead Cat Drop is a political communication tactic in which 
                  a deliberately controversial or distracting announcement is made 
                  to draw attention away from a more damaging story. 
                  This is a short-term tactical tool with significant ethical and reputational risks. 
                  Understanding it is important both for those who might face it 
                  and for those considering whether the risk is ever worth taking. 
                  The consensus in professional communications is that it rarely is: 
                  the distraction typically generates its own controversy, 
                  and the original story rarely disappears as intended.")
              )
            ),

            hr(class = "divider"),
            fluidRow(
              column(6,
                sh("Burying Bad News"),
                concept_card("The Ethical and Practical Limits of Timing Strategy",
                  "Burying bad news \u2014 releasing it alongside more positive or attention-grabbing 
                  announcements, or timing it for low-media periods \u2014 is a recognised 
                  communication tactic. It is legal and widely practised. 
                  It is also increasingly ineffective: digital journalism means no day 
                  is genuinely low-news, and audiences who discover that bad news 
                  was deliberately timed to minimise attention tend to react more negatively 
                  than they would have to the original news. 
                  Transparency builds more durable trust than tactical timing."),

                sh("Crisis Communication"),
                concept_card("The Six Steps of Crisis Communication",
                  "<b>Step 1 \u2014 Acknowledge:</b> Recognise the situation exists. 
                  Do not minimise, dismiss or go silent.<br><br>
                  <b>Step 2 \u2014 Express concern:</b> Show that you understand the human impact, 
                  not just the organisational consequences.<br><br>
                  <b>Step 3 \u2014 State what you know:</b> Be factually precise about what is known. 
                  Do not speculate about what is not yet confirmed.<br><br>
                  <b>Step 4 \u2014 State what you are doing:</b> Describe the immediate actions 
                  you are taking to address the situation.<br><br>
                  <b>Step 5 \u2014 State what happens next:</b> Set clear expectations for when 
                  and how you will communicate further.<br><br>
                  <b>Step 6 \u2014 Follow through:</b> Do exactly what you said you would do, 
                  when you said you would do it. Credibility in a crisis is earned 
                  entirely through the gap between promise and action.")
              ),

              column(6,
                sh("Recovery Plans"),
                concept_card("Reputation Recovery Is a Long Game",
                  "Recovering from a reputational crisis requires a sustained, 
                  evidence-led communication programme that demonstrates \u2014 through actions, 
                  not just words \u2014 that the organisation has changed or improved. 
                  Recovery communications should: lead with what has changed and what is being done; 
                  allow third-party voices to validate the recovery narrative; 
                  resist the temptation to declare victory prematurely; 
                  and continue long after the organisation feels the crisis has passed, 
                  because audiences tend to remember negative events far longer 
                  than organisations think they do."),

                div(class = "success-box",
                    tags$strong("\u2705 Chapter 10 Summary: "),
                    "Start with a specific, measurable communication goal. 
                    Build a plan that maps audience, message, channel and timing. 
                    Communicate bad news fast, fully and honestly. 
                    Get your retaliation in first. 
                    In a crisis: acknowledge, empathise, state facts, state actions, 
                    set expectations and follow through. 
                    Recovery is earned through actions, not announcements.")
              )
            )
          ), # end General Concepts

          tabPanel("\U0001f3e2 Applicability on Atera Analytics",
            br(),
            fluidRow(
              column(6,
                shg("Atera\u2019s Strategic Communication Goal"),
                app_card("Setting Measurable Communication Objectives for 2026",
                  "Atera\u2019s 2026 communication goals, expressed as SMART objectives:<br><br>
                  <b>Goal 1 \u2014 Awareness (Government):</b><br>
                  Ensure Atera\u2019s platform is known to the CCAV policy team and at least 
                  5 Innovate UK programme directors by end of Q2 2026.<br><br>
                  <b>Goal 2 \u2014 Belief (Councils):</b><br>
                  Secure at least 3 UK council pilot agreements by end of Q3 2026, 
                  demonstrating that councils believe the platform delivers practical value.<br><br>
                  <b>Goal 3 \u2014 Behaviour (AV Operators):</b><br>
                  Convert at least 5 AV operator conversations into SaaS trial agreements 
                  by end of Q4 2026.<br><br>
                  <b>Goal 4 \u2014 Thought Leadership:</b><br>
                  Achieve coverage in at least 3 relevant trade publications 
                  (Fleet News, Transport Network, Smart Transport) by Q3 2026."),

                app_card("Atera\u2019s Full Strategic Communication Plan \u2014 Framework",
                  "<b>Situation analysis:</b> Atera is known within the Innovate UK/Zenzic ecosystem 
                  but has minimal awareness among its commercial target audiences (councils, AV operators, investors).<br><br>
                  <b>Priority audiences (ranked):</b><br>
                  1. UK local authorities (primary commercial target)<br>
                  2. AV operators and logistics companies (primary revenue)<br>
                  3. Institutional investors and VC (growth capital)<br>
                  4. Policy community \u2014 CCAV, DfT, Parliament (regulatory influence)<br>
                  5. Media and thought leadership (amplification)<br><br>
                  <b>Channel strategy:</b><br>
                  LinkedIn (primary organic channel), trade press (credibility), 
                  events (Silverstone AV, smart mobility conferences), 
                  direct outreach (councils and operators), Zenzic network (warm introductions)."),

                shg("Handling Bad News at Atera"),
                app_card("Proactive Communication of Project Risks",
                  "Atera\u2019s current risk register identifies 6 high-priority risks (RF \u003e 4) 
                  in WP5 and WP6 \u2014 including ML model accuracy, API integration challenges, 
                  NVidia Digital Twin compatibility and real-time update latency. 
                  Strategic communication guidance for each:<br><br>
                  <b>If a deliverable is delayed:</b> Communicate proactively to Innovate UK 
                  before the deadline, not after. Frame with context (the technical reason), 
                  revised timeline and mitigation actions already underway.<br><br>
                  <b>If a technical risk materialises:</b> Apply kitchen sinking \u2014 
                  disclose the full picture in one clear, well-framed communication 
                  rather than allowing monitoring officers to discover it incrementally 
                  through progress reports.<br><br>
                  <b>If a commercial conversation falls through:</b> 
                  Communicate to relevant internal stakeholders immediately 
                  and pivot to the next target on the council pipeline.")
              ),

              column(6,
                shg("Crisis Communication for Atera"),
                app_card("Atera\u2019s Most Likely Risk Scenarios",
                  "Applying the six-step crisis framework to Atera\u2019s three highest-probability 
                  risk scenarios:<br><br>
                  <b>Scenario 1: A deliverable is significantly delayed</b><br>
                  Acknowledge (immediately, to Innovate UK); express concern (for programme timeline); 
                  state what is known (specific deliverable, root cause, impact); 
                  state what is being done (mitigation actions with owners); 
                  state next update timing; follow through on every commitment made.<br><br>
                  <b>Scenario 2: IP dispute with a consortium partner</b><br>
                  Acknowledge internally; seek legal guidance immediately (Marks & Clerk); 
                  do not communicate publicly until legal position is clear; 
                  communicate to Innovate UK factually and without prejudice; 
                  maintain professional external tone throughout.<br><br>
                  <b>Scenario 3: Platform security or data breach</b><br>
                  Follow GDPR mandatory reporting requirements first (72-hour window); 
                  acknowledge to affected parties immediately; 
                  state precisely what data was affected and what was not; 
                  state actions taken and next steps with timeline."),

                app_card("Atera\u2019s Recovery Communication \u2014 Building Long-Term Trust",
                  "Atera\u2019s long-term reputational strength will be built not through 
                  a single announcement but through consistent demonstration of: 
                  technical capability (validated outputs, published methodology), 
                  commercial credibility (paying clients, growing pipeline), 
                  policy influence (House of Lords engagement, BSI/ISO standards participation), 
                  and human impact (jobs created, researchers trained, Net Zero contribution).<br><br>
                  Each of these dimensions requires its own communication strand: 
                  technical credibility through academic publications and conference presentations; 
                  commercial credibility through case studies and client testimonials; 
                  policy influence through thought leadership and direct engagement; 
                  human impact through team stories and training narratives."),

                div(class = "success-box",
                    tags$strong("\u2705 Chapter 10 Action Points for Atera: "),
                    tags$ol(
                      tags$li("Write 4 SMART communication goals for 2026 with named owners"),
                      tags$li("Complete a full strategic communication plan using the 7-component framework"),
                      tags$li("Build a proactive risk communication protocol for each high-priority project risk"),
                      tags$li("Create a crisis communication response template for the 3 most likely scenarios"),
                      tags$li("Design a 12-month reputation-building calendar across all 5 audience groups")
                    ))
              )
            )
          ) # end Atera tab
        ) # end tabsetPanel
      ) # end box
    ) # end fluidRow
  )
}

ch10_strategic_comm_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
  })
}
