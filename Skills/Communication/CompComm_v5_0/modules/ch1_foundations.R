# modules/ch1_foundations.R

ch1_foundations_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero("1", "The Foundations of Effective Communication",
      "Before you write a word: find your Golden Thread, know your audience, commit to brevity, allow your voice through, and plan your one moment of surprise.",
      c("Golden Thread", "KISS", "Audience Audit", "Voice & Style", "Surprise")),

    fluidRow(
      column(2, stat_card("1",    "Golden Thread per Message")),
      column(2, stat_card("KISS", "Keep It Simple Always")),
      column(2, stat_card("\u2193",     "Always Edit Down")),
      column(2, stat_card("\u2605",     "Find Your Voice")),
      column(2, stat_card("!",    "Deploy Surprise")),
      column(2, stat_card("WHO",  "Know Your Audience"))
    ),

    fluidRow(
      tabBox(id = ns("tabs"), width = 12,
        tabPanel("\U0001f4da General Concepts", br(),
          fluidRow(
            column(6,
              sh("Clarity of Story"),
              framework_card("One Idea Rules All",
                "Every piece of communication must carry a single central idea. Before writing a word, ask: <em>what is the one thing I want my audience to take away?</em> If you cannot state it in one sentence, you are not ready to communicate it. Clarity is not simplification \u2014 it is precision."),
              sh("The Golden Thread"),
              framework_card("The Invisible Spine of Your Message",
                "The Golden Thread is the single idea running through every paragraph, every slide, every spoken word. It connects your opening to your close. Every sentence should serve it or be cut. When audiences feel a coherent thread, trust and comprehension both increase significantly."),
              framework_card("How to Find Your Golden Thread",
                "Ask: <em>\u2018If my audience could only remember one thing from this, what must it be?\u2019</em> Write it at the top of every document before you begin. Test every section against it ruthlessly before you finalise."),
              sh("The Beauty of a KISS"),
              framework_card("Keep It Simple \u2014 The Power of Plain Language",
                "KISS (Keep It Simple) is the most consistently violated rule in professional communication. Complexity signals insecurity; simplicity signals mastery. The test: can a smart non-expert understand your message in one reading? If not, it needs simplification \u2014 not the audience."),
              pull_quote("If I had more time, I would have written a shorter letter.", "Attributed to Mark Twain, Blaise Pascal and others")
            ),
            column(6,
              sh("Know Your Audience"),
              framework_card("The Audience Comes First \u2014 Always",
                "The foundation of all communication is audience empathy. Who are they? What do they already know? What do they care about? Effective communicators write for the reader\u2019s world, not their own. This single shift transforms technical writing into persuasive communication."),
              framework_card("The Audience Audit: Four Questions",
                "<b>(1)</b> What do they already know? <b>(2)</b> What do they currently feel? <b>(3)</b> What do they need from me? <b>(4)</b> What do I need from them? Only after answering all four should you write a single word."),
              sh("Less Is More"),
              framework_card("The Business of Brevity",
                "Every word you add dilutes the power of every other word. The instinct to add more \u2014 more detail, more caveats, more evidence \u2014 is the enemy of impact. Brevity is a sign of respect for the reader\u2019s time."),
              sh("Voice, Style & Surprise"),
              framework_card("Finding Yourself \u2014 Authentic Voice",
                "Voice is the personality that comes through in your writing. Generic corporate language has no voice and therefore no impact. The communicators people remember all have a distinctive way of expressing themselves that feels authentic and human."),
              framework_card("Surprise! \u2014 The Unexpected Is Unforgettable",
                "The human brain is wired to notice what is unexpected. A single unexpected fact, a counterintuitive opening, an unusual analogy \u2014 any of these can transform a forgettable message into one that is talked about long after delivery."),
              tip_box(tags$strong("Key test: "), "Read your work aloud. If it does not sound like a confident, intelligent human having a real conversation, it does not yet have a voice."),
              success_box(tags$strong("Chapter 1 Summary: "), "Golden Thread first. Audience audit always. Brevity as a discipline. Voice as authenticity. One moment of surprise. In that order.")
            )
          )
        ),
        tabPanel("\U0001f3e2 Applicability on Atera Analytics", br(),
          fluidRow(
            column(6,
              shg("Atera\u2019s Golden Thread per Audience"),
              insight_box("One Central Message for Each Stakeholder Group",
                "<b>Innovate UK / Zenzic:</b> \u2018We are delivering the UK\u2019s first AI-powered CAV infrastructure readiness platform, on schedule and with measurable impact.\u2019<br><br>
                 <b>UK Councils:</b> \u2018We give you a cost-effective, evidence-based framework to understand whether your roads are ready for autonomous vehicles.\u2019<br><br>
                 <b>AV Operators:</b> \u2018We eliminate route uncertainty for autonomous vehicle deployment through real-time infrastructure intelligence.\u2019<br><br>
                 <b>Investors:</b> \u2018We are building the data infrastructure layer that the entire UK CAV industry depends on \u2014 government-backed and commercially proven.\u2019"),
              shg("KISS in Practice at Atera"),
              insight_box("Simplifying Complex AI for Non-Technical Stakeholders",
                "Atera\u2019s platform involves BigQuery, Vertex AI, digital twins, YOLOv8 and 5G teleoperation. None of these should appear in a council presentation unless the audience is technical."),
              example_pair(
                bad_text  = "Our YOLOv8 computer vision pipeline processes OSM features to generate CAV risk scores via GCP-hosted API endpoints.",
                good_text = "Our platform scans roads using AI to score how ready they are for self-driving vehicles \u2014 like a sat-nav that also rates road quality."
              )
            ),
            column(6,
              shg("Audience Audit \u2014 Atera\u2019s Key Stakeholders"),
              insight_box("Innovate UK / Zenzic Monitoring Officers",
                "<b>Know:</b> Grant terms, milestone definitions, technical feasibility.<br>
                 <b>Feel:</b> Responsible for public money; need confidence in delivery.<br>
                 <b>Need:</b> Evidence of progress, milestone achievement, honest risk reporting.<br>
                 <b>Style:</b> Structured, evidence-led, quantified, pyramid structure."),
              insight_box("UK Local Authorities and Councils",
                "<b>Know:</b> Local road challenges, budget constraints, some CAV policy awareness.<br>
                 <b>Feel:</b> Cautious about new technology; want proven tools not prototypes.<br>
                 <b>Need:</b> Easy-to-use tools, clear ROI, credible endorsement.<br>
                 <b>Style:</b> Plain English, visual dashboards, outcomes not algorithms."),
              insight_box("Atera\u2019s Killer Facts \u2014 The Surprise Moments",
                "\u2018100+ UK councils have no standardised way to assess whether their roads are ready for autonomous vehicles.\u2019<br><br>
                 \u2018Our platform scores the AV readiness of any UK road segment in real time \u2014 work that previously required weeks of manual survey.\u2019<br><br>
                 \u2018\u00a3200M+ of government CAV investment could be better targeted using evidence-based infrastructure scoring.\u2019"),
              success_box(tags$strong("Action Points: "),
                tags$ol(
                  tags$li("Write a Golden Thread for each of your 4 audience groups"),
                  tags$li("Audit all current emails and reports for KISS compliance"),
                  tags$li("Define 3 killer facts for stakeholder surprise moments"),
                  tags$li("Write a 2-sentence Atera voice guide for all team communications")
                ))
            )
          )
        )
      )
    )
  )
}

ch1_foundations_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
