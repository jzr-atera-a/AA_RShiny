# modules/ch1_foundations.R
# Chapter 1: The Foundations of Effective Communication

ch1_foundations_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("Chapter 1"),
        tags$h2("The Foundations of Effective Communication"),
        div(
          span(class = "hero-badge", icon("lightbulb"),     " Golden Thread"),
          span(class = "hero-badge", icon("compress-alt"),  " KISS Principle"),
          span(class = "hero-badge", icon("user-circle"),   " Voice & Style"),
          span(class = "hero-badge", icon("bolt"),          " Surprise Factor")
        )
    ),

    fluidRow(
      box(title = "Chapter 1 - Overview", status = "primary",
          solidHeader = TRUE, width = 12,
          p("Every piece of communication - an email, a pitch deck, a technical report, a stakeholder presentation - ",
            "lives or dies on one question: does the audience receive one clear, compelling idea? ",
            "Chapter 1 establishes the non-negotiable foundations: clarity of story, brevity, audience empathy, ",
            "authentic voice, and the strategic use of the unexpected."),
          fluidRow(
            column(2, metric_card("1",    "Golden Thread per Message")),
            column(2, metric_card("KISS", "Keep It Simple")),
            column(2, metric_card("\u2193",     "Always Edit Down")),
            column(2, metric_card("\u2605",     "Find Your Voice")),
            column(2, metric_card("!",    "Deploy Surprise")),
            column(2, metric_card("WHO",  "Know Your Audience"))
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
                sh("Clarity of Story"),
                concept_card("One Idea Rules All",
                  "Every piece of communication must carry a single central idea - nothing more. 
                  Before writing a word, ask: <em>what is the one thing I want my audience to take away?</em> 
                  If you cannot state it in one sentence, you are not ready to communicate it. 
                  Clarity is not simplification; it is precision."),

                sh("The Golden Thread"),
                concept_card("The Invisible Spine of Your Message",
                  "The Golden Thread is the single idea that runs through every paragraph, every slide, every spoken word. 
                  It connects your opening to your close. Every sentence should either serve it or be cut. 
                  When audiences feel a coherent thread running through a communication, both trust and 
                  comprehension increase significantly."),

                concept_card("How to Find Your Golden Thread",
                  "Ask: <em>\u2018If my audience could only remember one thing from this, what must it be?\u2019</em> 
                  That is your thread. Write it at the top of every document before you begin, 
                  and test every section against it ruthlessly before you finalise."),

                sh("The Beauty of a KISS"),
                concept_card("Keep It Simple - The Power of Plain Language",
                  "KISS (Keep It Simple) is the most consistently violated rule in professional communication. 
                  Complexity signals insecurity; simplicity signals mastery. 
                  The test: can a smart non-expert understand your message in one reading? 
                  If not, it needs simplification - not the audience."),

                quote_block(
                  "If I had more time, I would have written a shorter letter.",
                  "Attributed to Mark Twain, Blaise Pascal and others"
                )
              ),

              column(6,
                sh("A Magical Miracle - Know Your Audience"),
                concept_card("The Audience Comes First - Always",
                  "The foundation of all communication is audience empathy. Who are they? 
                  What do they already know? What do they care about? What will move them to act? 
                  Effective communicators write for the reader\u2019s world, not their own. 
                  This single shift transforms technical writing into persuasive communication."),

                concept_card("The Audience Audit: Four Questions",
                  "Before every communication, answer four questions: 
                  <b>(1)</b> What do they already know? 
                  <b>(2)</b> What do they currently feel about this topic? 
                  <b>(3)</b> What do they need from me? 
                  <b>(4)</b> What do I need from them? 
                  Only after answering all four should you write a single word."),

                sh("Less Is More"),
                concept_card("The Business of Brevity",
                  "In professional contexts, shorter consistently outperforms longer. 
                  Every word you add dilutes the power of every other word. 
                  The instinct to add more - more detail, more caveats, more evidence - 
                  is the enemy of impact. Brevity is a sign of respect for the reader\u2019s time, 
                  and the most persuasive writers are the most ruthless editors of their own work."),

                concept_card("Making Yourself Popular Through Concision",
                  "Communicators who write briefly and clearly are perceived as more intelligent, 
                  more confident, and more trustworthy than those who write at length. 
                  Brevity is a leadership signal. In email culture especially, 
                  the person who writes three sentences when others write three paragraphs 
                  is more read, more replied to, and more respected.")
              )
            ),

            hr(class = "divider"),
            fluidRow(
              column(6,
                sh("Finding Yourself - Voice and Style"),
                concept_card("Every Communicator Has a Distinctive Voice",
                  "Voice is the personality that comes through in your writing and speaking. 
                  It is made of word choice, sentence rhythm, warmth and conviction. 
                  Generic corporate language has no voice and therefore no impact. 
                  The communicators people remember, trust and follow all have a distinctive way 
                  of expressing themselves that feels authentic and human."),

                concept_card("Strutting Your Style",
                  "Style is not about decoration - it is about clarity plus personality. 
                  The goal is to communicate your ideas in a way only you could, 
                  while remaining utterly clear to your audience. Style must serve the message, never obscure it."),

                div(class = "tip-box",
                    tags$strong("\U0001f4a1 Key test: "),
                    "Read your work aloud. If it does not sound like a confident, intelligent human 
                    having a real conversation, it does not yet have a voice.")
              ),

              column(6,
                sh("Surprise!"),
                concept_card("The Unexpected Is Unforgettable",
                  "The human brain is wired to notice what is unexpected. 
                  Surprise triggers engagement, memory and sharing. 
                  A single unexpected fact, a counterintuitive opening, 
                  an unusual analogy - any of these can transform a forgettable message 
                  into one that is talked about long after delivery."),

                concept_card("Where to Deploy Surprise",
                  "The most powerful locations for surprise are: 
                  <b>(1)</b> the opening line of any document or presentation; 
                  <b>(2)</b> the transition from problem to solution; 
                  <b>(3)</b> the headline or email subject line. 
                  A single surprising data point at the start earns the audience\u2019s full 
                  attention for everything that follows."),

                div(class = "success-box",
                    tags$strong("\u2705 Chapter 1 Summary: "),
                    "Before you write anything: find your Golden Thread, audit your audience, 
                    commit to brevity, allow your voice through, and plan your one moment of surprise.")
              )
            )
          ), # end General Concepts

          # ── ATERA ANALYTICS APPLICATION ──────────────
          tabPanel("\U0001f3e2 Applicability on Atera Analytics",
            br(),
            fluidRow(
              column(6,
                shg("Atera\u2019s Golden Thread per Audience"),
                app_card("One Central Message for Each Stakeholder Group",
                  "Atera must define and use a single Golden Thread consistently for each audience:<br><br>
                  <b>Innovate UK / Zenzic:</b> <em>\u2018We are delivering the UK\u2019s first AI-powered CAV 
                  infrastructure readiness platform, on schedule and with measurable impact.\u2019</em><br><br>
                  <b>UK Councils:</b> <em>\u2018We give you a cost-effective, evidence-based framework 
                  to understand whether your roads are ready for autonomous vehicles.\u2019</em><br><br>
                  <b>AV Operators:</b> <em>\u2018We eliminate route uncertainty for autonomous vehicle 
                  deployment through real-time infrastructure intelligence.\u2019</em><br><br>
                  <b>Investors:</b> <em>\u2018We are building the data infrastructure layer that the 
                  entire UK CAV industry depends on - government-backed and commercially proven.\u2019</em>"),

                app_card("Applying the Thread to Milestone Reports",
                  "Every quarterly report to Innovate UK should open with a one-paragraph executive 
                  summary that restates the Golden Thread: the core value delivered this quarter. 
                  Technical detail follows this anchor - never precedes it. 
                  Reports that lead with outcomes before methodology are consistently rated higher 
                  by monitoring officers and demonstrate project confidence."),

                shg("KISS in Practice at Atera"),
                app_card("Simplifying Complex AI for Non-Technical Stakeholders",
                  "Atera\u2019s platform involves BigQuery, Vertex AI, digital twins, YOLOv8, 
                  reinforcement learning and 5G teleoperation. None of these should appear 
                  in a council presentation or investor pitch unless the audience is technical.<br><br>"),
                example_pair(
                  bad_text  = "Our YOLOv8 computer vision pipeline processes OSM features to generate 
                  CAV risk scores via GCP-hosted API endpoints with low-latency BigQuery integration.",
                  good_text = "Our platform scans roads using AI to score how ready they are for 
                  self-driving vehicles - like a sat-nav that also rates road quality and safety."
                )
              ),

              column(6,
                shg("Audience Audit - Atera\u2019s Key Stakeholders"),
                app_card("Innovate UK / Zenzic Monitoring Officers",
                  "<b>Know:</b> Grant terms, milestone definitions, technical feasibility concepts.<br>
                  <b>Feel:</b> Responsible for public money; need confidence in delivery.<br>
                  <b>Need from Atera:</b> Evidence of progress, milestone achievement, honest risk reporting.<br>
                  <b>Atera needs:</b> Milestone payment sign-off, continued programme support.<br><br>
                  <b>Communication style:</b> Structured, evidence-led, quantified, pyramid structure."),

                app_card("UK Local Authorities and Councils",
                  "<b>Know:</b> Local road challenges, budget constraints, some CAV policy awareness.<br>
                  <b>Feel:</b> Cautious about new technology; want proven tools not prototypes.<br>
                  <b>Need from Atera:</b> Easy-to-use tools, clear ROI, credible endorsement.<br>
                  <b>Atera needs:</b> Pilot agreements, data sharing, case study partnerships.<br><br>
                  <b>Communication style:</b> Plain English, visual dashboards, outcomes not algorithms."),

                app_card("AV Operators and Logistics Companies",
                  "<b>Know:</b> Route planning complexity, operational costs, AV deployment challenges.<br>
                  <b>Feel:</b> Under commercial pressure; want competitive advantage.<br>
                  <b>Need from Atera:</b> Reliable route intelligence that reduces operational risk.<br>
                  <b>Atera needs:</b> SaaS contracts, usage data, co-development partnerships.<br><br>
                  <b>Communication style:</b> Commercial, ROI-focused, demonstration-led."),

                app_card("Atera\u2019s Surprise / Killer Facts",
                  "Every Atera pitch should contain one surprising statistic that reframes the problem:<br><br>
                  \u2018100+ UK councils currently have no standardised way to assess whether their 
                  roads are ready for autonomous vehicles.\u2019<br><br>
                  \u2018Our platform scores the AV readiness of any UK road segment in real time - 
                  work that previously required weeks of manual survey.\u2019<br><br>
                  \u2018\u00a3200M+ of government CAV investment could be better targeted using 
                  evidence-based infrastructure scoring.\u2019"),

                div(class = "success-box",
                    tags$strong("\u2705 Chapter 1 Action Points for Atera: "),
                    tags$ol(
                      tags$li("Write a Golden Thread for each of your 4 audience groups and pin it above your desk"),
                      tags$li("Audit all current emails and reports for KISS - flag any that fail"),
                      tags$li("Define 3 killer facts for stakeholder surprise moments"),
                      tags$li("Write a 2-sentence Atera voice guide for all team communications")
                    ))
              )
            )
          ) # end Atera tab
        ) # end tabsetPanel
      ) # end box
    ) # end fluidRow
  )
}

ch1_foundations_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
  })
}
