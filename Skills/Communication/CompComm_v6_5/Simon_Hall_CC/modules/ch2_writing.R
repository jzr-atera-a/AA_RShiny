# modules/ch2_writing.R
# Chapter 2: Writing to Woo and Wow

ch2_writing_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("Chapter 2"),
        tags$h2("Writing to Woo and Wow"),
        div(
          span(class = "hero-badge", icon("rocket"),         " Striking Starts"),
          span(class = "hero-badge", icon("trophy"),         " Enduring Endings"),
          span(class = "hero-badge", icon("list-ol"),        " Rule of Threes"),
          span(class = "hero-badge", icon("balance-scale"),  " Counterpoint"),
          span(class = "hero-badge", icon("tags"),           " Triumphant Titles")
        )
    ),

    fluidRow(
      box(title = "Chapter 2 \u2014 Overview", status = "primary",
          solidHeader = TRUE, width = 12,
          p("Knowing ", tags$em("what"), " to communicate is only half the challenge. ",
            "The other half is ", tags$em("how"), " to write it so that people actually read, ",
            "absorb and act on it. Chapter 2 provides a toolkit of specific craft techniques: ",
            "how to open with impact, close memorably, structure for retention, ",
            "and choose words that work hard."),
          fluidRow(
            column(2, metric_card("3s",  "Avg. Time to Hook a Reader")),
            column(2, metric_card("3\u00d7", "Rule of Threes Power")),
            column(2, metric_card("\u2260",  "Counterpoint Builds Trust")),
            column(2, metric_card("\u2248",  "Analogy = Instant Clarity")),
            column(2, metric_card("\u2717",  "Ban All Clich\u00e9s")),
            column(2, metric_card("1st", "Title Is Always Read First"))
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
                sh("Striking Starts"),
                concept_card("The Opening Is Everything",
                  "Readers decide whether to continue within the first three seconds. 
                  A striking start can be: a bold statement, a surprising statistic, 
                  a provocative question, a vivid anecdote, or a counterintuitive claim. 
                  What it must never be: a lengthy context-setting preamble, 
                  a statement of the obvious, or \u2018I am writing to you today regarding...\u2019"),

                concept_card("Five Types of Powerful Openings",
                  "<b>1. The Bold Statement:</b> State your conclusion first, then support it.<br>
                  <b>2. The Killer Statistic:</b> One surprising number that reframes the problem.<br>
                  <b>3. The Question:</b> A question the reader cannot answer \u2014 but needs you to.<br>
                  <b>4. The Anecdote:</b> A one-sentence scene that puts the reader inside the story.<br>
                  <b>5. The Counterintuitive:</b> Something that directly contradicts a common assumption."),

                sh("Enduring Endings"),
                concept_card("Your Last Word Is Your Lasting Impression",
                  "The closing of any communication is the second most remembered section 
                  after the opening. It should reinforce the Golden Thread, 
                  leave a clear emotional or intellectual impression, 
                  and \u2014 where appropriate \u2014 state a precise call to action. 
                  Vague endings (\u2018please feel free to get in touch\u2019) waste the most 
                  powerful real estate in your communication."),

                sh("Clever Content"),
                concept_card("Earn Every Sentence",
                  "Every sentence in your writing must earn its place by doing at least one of three things: 
                  adding new information, advancing the argument, or creating momentum. 
                  Sentences that merely repeat what has been said, hedge unnecessarily, 
                  or add detail the reader does not need should be cut without mercy.")
              ),

              column(6,
                sh("The Rule of Threes"),
                concept_card("Three Is the Magic Number of Communication",
                  "The brain processes information most efficiently in groups of three. 
                  Three-part structures feel complete, rhythmic and authoritative: 
                  \u2018fast, reliable, and affordable\u2019; \u2018we plan, we build, we deliver\u2019; 
                  \u2018reduce costs, increase efficiency, gain advantage.\u2019 
                  The Rule of Threes is the single most powerful structural device in persuasive writing."),

                concept_card("How to Apply the Rule of Threes",
                  "Use three-part structures for: key benefits in proposals, 
                  headline messages in presentations, email openers and verbal pitches. 
                  If you have four points, cut one. If you have two, either find a third 
                  or reframe them as a deliberate contrast pair."),

                sh("Counterpoint"),
                concept_card("Acknowledge the Other Side \u2014 Then Defeat It",
                  "Raising and then answering an objection is one of the most powerful persuasion 
                  techniques available. It signals confidence, honesty and intellectual rigour. 
                  Audiences trust communicators who proactively address weaknesses far more than 
                  those who present only strengths. 
                  The formula: \u2018One might argue that X\u2026 however, the evidence shows Y.\u2019"),

                sh("Analogy"),
                concept_card("Make the Complex Instantly Understandable",
                  "Analogy is the most powerful tool for explaining technical or abstract ideas 
                  to non-expert audiences. A well-chosen analogy does in one sentence 
                  what three paragraphs of explanation cannot: it gives the reader 
                  an immediate mental model they can hold and use. 
                  The best analogies come from the audience\u2019s own world, not the writer\u2019s.")
              )
            ),

            hr(class = "divider"),
            fluidRow(
              column(6,
                sh("The Voice \u2014 Authenticity in Writing"),
                concept_card("Write As You Would Speak at Your Best",
                  "Voice in writing is the sense that a real, thoughtful person is behind the words. 
                  Writing that sounds like a committee, a legal document or a press release has lost its voice. 
                  The test: read your writing aloud. If it sounds stiff, formal or robotic, 
                  rewrite it until it sounds like a confident, warm, knowledgeable human being."),

                sh("Clich\u00e9s \u2014 The Enemy of Impact"),
                concept_card("Ban These Words From Your Writing",
                  "Clich\u00e9s are phrases so overused they have lost all meaning: 
                  \u2018cutting-edge\u2019, \u2018world-class\u2019, \u2018innovative\u2019, \u2018game-changing\u2019, 
                  \u2018synergy\u2019, \u2018leverage\u2019, \u2018paradigm shift\u2019, \u2018going forward\u2019, 
                  \u2018circle back\u2019, \u2018low-hanging fruit\u2019. 
                  Every clich\u00e9 signals that the writer stopped thinking. 
                  Replace each one with a specific, concrete, original phrase.")
              ),

              column(6,
                sh("Triumphant Titles"),
                concept_card("The Title Is Read First \u2014 Make It Work",
                  "The title of any document, report, presentation or email subject line 
                  is the first and sometimes only thing your audience reads. 
                  A strong title states the benefit or outcome, creates curiosity, 
                  uses active language, and is specific rather than generic. 
                  \u2018Q3 Project Report\u2019 is a filing label. 
                  \u2018Milestone 5 Achieved: Platform Ready for Commercial Deployment\u2019 is a title."),

                concept_card("Title Formulas That Work",
                  "<b>Outcome-first:</b> How [Solution] Achieves [Specific Result]<br>
                  <b>Question:</b> Are UK Roads Ready for Autonomous Vehicles? A Data Assessment<br>
                  <b>The Number:</b> 5 Reasons the CAV Market Needs Infrastructure Intelligence Now<br>
                  <b>The Contrast:</b> From Manual Survey to Real-Time AI: The Future of Road Assessment"),

                div(class = "success-box",
                    tags$strong("\u2705 Chapter 2 Summary: "),
                    "Every piece of writing needs: a striking opening, a clear Rule of Threes structure, 
                    at least one analogy for complex ideas, one moment of counterpoint, 
                    zero clich\u00e9s, and a title that compels reading rather than merely labelling content.")
              )
            )
          ), # end General Concepts

          # ── ATERA ANALYTICS APPLICATION ──────────────
          tabPanel("\U0001f3e2 Applicability on Atera Analytics",
            br(),
            fluidRow(
              column(6,
                shg("Striking Starts \u2014 Atera in Practice"),
                app_card("Opening Lines for Key Atera Documents",
                  "<b>Innovate UK Milestone Report:</b><br>
                  <em>\u2018Milestone 5 is complete. Atera Analytics has delivered all seven data architecture 
                  deliverables on schedule, establishing the UK\u2019s first AI-powered CAV infrastructure 
                  assessment pipeline with a validated digital twin of UK road infrastructure.\u2019</em><br><br>
                  <b>Council Presentation:</b><br>
                  <em>\u2018Over 100 UK councils have no standardised way to assess whether their roads 
                  are ready for autonomous vehicles. This platform changes that \u2014 in real time, 
                  at the cost of a short report.\u2019</em><br><br>
                  <b>Investor Pitch:</b><br>
                  <em>\u2018The UK is committing \u00a3200M+ to CAV infrastructure \u2014 but has no national 
                  framework to decide where to spend it. We built one.\u2019</em>"),

                app_card("Striking Starts for Atera Partner Emails",
                  "Every cold outreach email must open with impact \u2014 not a company introduction. 
                  Context comes after the hook, never before it.<br><br>"),
                example_pair(
                  bad_text  = "My name is Joseph from Atera Analytics, an AI company based in the UK 
                  that has been working on a feasibility study funded by Innovate UK...",
                  good_text = "Your roads may not be ready for autonomous vehicles. Our platform can 
                  tell you exactly which ones \u2014 and why. We\u2019re working with Innovate UK and 
                  Zenzic to make this accessible to every UK council."
                ),

                shg("Rule of Threes \u2014 Atera\u2019s Core Messages"),
                app_card("Three-Part Value Propositions per Audience",
                  "<b>For Councils:</b> \u2018Cost-effective. Evidence-based. Immediately deployable.\u2019<br><br>
                  <b>For AV Operators:</b> \u2018Real-time route intelligence. Reduced deployment risk. Scalable across the UK.\u2019<br><br>
                  <b>For Innovate UK:</b> \u2018On schedule. On budget. Commercially validated.\u2019<br><br>
                  <b>For Investors:</b> \u2018Government-backed. Technically proven. Market-ready.\u2019")
              ),

              column(6,
                shg("Analogies for Atera\u2019s Complex Technology"),
                app_card("Making the Platform Understandable to All Audiences",
                  "<b>For the overall platform:</b><br>
                  <em>\u2018Think of our platform as a TripAdvisor for roads \u2014 except instead of rating 
                  restaurants, it rates how ready each road segment is for autonomous vehicles, 
                  based on real infrastructure data.\u2019</em><br><br>
                  <b>For the digital twin:</b><br>
                  <em>\u2018A digital twin is like a flight simulator for roads \u2014 engineers can test 
                  how a vehicle will perform on a specific route before any vehicle drives it for real.\u2019</em><br><br>
                  <b>For AI route scoring:</b><br>
                  <em>\u2018Our AI works like a very experienced road safety inspector who never sleeps, 
                  never gets tired, and can assess every road in the country simultaneously.\u2019</em>"),

                shg("Counterpoint \u2014 Handling Atera\u2019s Toughest Objections"),
                app_card("Preempt and Answer Stakeholder Concerns Proactively",
                  "<b>Council: \u2018We don\u2019t have budget for new technology.\u2019</b><br>
                  \u2018That\u2019s exactly why we designed this as a SaaS platform \u2014 accessible 
                  for the cost of a single manual survey, with no infrastructure investment required.\u2019<br><br>
                  <b>Investor: \u2018AI in transport is a crowded space.\u2019</b><br>
                  \u2018Most competitors focus on vehicles \u2014 we focus on infrastructure. 
                  No other platform currently combines GIS, ML and real-time data to score 
                  CAV readiness at national scale.\u2019<br><br>
                  <b>Innovate UK: \u2018How will this survive commercially post-grant?\u2019</b><br>
                  \u2018We have four revenue streams: SaaS licensing, API data access, route 
                  consultancy, and Data-as-a-Service, with market entry confirmed for Q2 2026.\u2019"),

                shg("Triumphant Titles \u2014 Atera Document Audit"),
                app_card("Rewriting Atera\u2019s Key Document Titles",
                  "<b>Reports:</b><br>
                  \u274c \u2018Q3 Project Progression Update\u2019<br>
                  \u2705 \u2018Five Milestones Complete: Atera\u2019s CAV Platform Enters Final Phase\u2019<br><br>
                  <b>Presentations:</b><br>
                  \u274c \u2018Opt Tech 4 \u2014 Project Overview\u2019<br>
                  \u2705 \u2018From Feasibility to Market: How AI Is Making UK Roads AV-Ready\u2019<br><br>
                  <b>Email subject lines:</b><br>
                  \u274c \u2018Follow up from our meeting\u2019<br>
                  \u2705 \u2018Platform demonstration \u2014 30 minutes to see AV readiness scoring live\u2019"),

                div(class = "success-box",
                    tags$strong("\u2705 Chapter 2 Action Points for Atera: "),
                    tags$ol(
                      tags$li("Rewrite the opening paragraph of the next Innovate UK milestone report"),
                      tags$li("Build a three-part value proposition for each of the 4 audience groups"),
                      tags$li("Create an analogy library: 5 analogies for core platform technologies"),
                      tags$li("Audit all document titles and email subject lines against Triumphant Title criteria"),
                      tags$li("Remove all identified clich\u00e9s from the exploitation plan and pitch deck")
                    ))
              )
            )
          ) # end Atera tab
        ) # end tabsetPanel
      ) # end box
    ) # end fluidRow
  )
}

ch2_writing_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
  })
}
