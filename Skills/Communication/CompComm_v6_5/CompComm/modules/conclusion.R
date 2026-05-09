# modules/conclusion.R
# A Compelling Conclusion (Hopefully)

conclusion_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("A Compelling Conclusion"),
        tags$h2("Bringing It All Together \u2014 The Complete Communication Framework"),
        div(
          span(class = "hero-badge", icon("check-double"),  " All 10 Chapters"),
          span(class = "hero-badge", icon("road"),          " Atera\u2019s Roadmap"),
          span(class = "hero-badge", icon("trophy"),        " Communication Excellence"),
          span(class = "hero-badge", icon("rocket"),        " Ready for Market")
        )
    ),

    fluidRow(
      box(title = "\U0001f3c1 The Book in One Page", status = "primary",
          solidHeader = TRUE, width = 12,
          p("Simon Hall\u2019s ", tags$em("Compelling Communication"), " can be distilled into a single principle: ",
            tags$b("say less, mean more, and make every word earn its place."),
            " Everything in the 10 chapters serves that principle \u2014 from the Golden Thread in Chapter 1 ",
            "to the crisis communication frameworks in Chapter 10. ",
            "Below is the master synthesis: every chapter\u2019s core insight in one line, ",
            "followed by the complete action roadmap for Atera Analytics."),
          hr(class = "divider"),
          fluidRow(
            column(6,
              div(class = "section-heading", "The 10 Core Insights"),
              timeline_entry("1",  "Foundations",
                "Find your Golden Thread, know your audience, commit to brevity, and deploy one moment of surprise."),
              timeline_entry("2",  "Writing to Wow",
                "Open with a strike, structure in threes, use analogy for complexity, and give every document a triumphant title."),
              timeline_entry("3",  "Trade Tricks",
                "Structure before writing, show evidence not claims, include every reader, and edit without mercy."),
              timeline_entry("4",  "Storytelling",
                "Build every story with four ingredients: protagonist, challenge, struggle, resolution \u2014 and add jeopardy."),
              timeline_entry("5",  "Strategic Stories",
                "Match story type to audience, build a story bank, include one emotional moment, ensure every story teaches."),
              timeline_entry("6",  "Public Speaking",
                "Know your 60-second pitch cold, design slides as visual support, use one killer fact, always have a lifesaver."),
              timeline_entry("7",  "Powerful Speaking",
                "Interact, signpost, create magic moments, project confident body language, prepare every Q&A answer."),
              timeline_entry("8",  "Online World",
                "Give value before you ask, write three bio lengths, choose platforms strategically, think before every post."),
              timeline_entry("9",  "Media",
                "Build a Message House, practise bridging, prepare soundbites, get your retaliation in first."),
              timeline_entry("10", "Strategic Comms",
                "Start with a measurable goal, communicate bad news fast and fully, plan for crisis before it arrives.")
            ),
            column(6,
              div(class = "section-heading", "Atera\u2019s Single Unifying Golden Thread"),
              quote_block(
                "Atera Analytics is making autonomous vehicle deployment safer and smarter 
                by giving operators and councils the infrastructure intelligence they need \u2014 
                government-validated, AI-powered, and commercially ready.",
                "Atera Analytics \u2014 Golden Thread, all audiences"
              ),
              br(),
              div(class = "section-heading", "The Three Priorities for Immediate Action"),
              div(class = "concept-card",
                  tags$h4("\U0001f947 Priority 1 \u2014 This Week"),
                  tags$p("Write the Golden Thread for all 4 audience groups. 
                  Rewrite the LinkedIn headline and About section. 
                  Prepare the 60-second elevator pitch in three versions. 
                  Remove all clich\u00e9s from the exploitation plan.")),
              div(class = "concept-card",
                  tags$h4("\U0001f948 Priority 2 \u2014 This Month"),
                  tags$p("Build the story bank (6 entries). 
                  Create the Message House for media interactions. 
                  Redesign the Q3 progression deck with conclusion headlines. 
                  Launch a 12-week LinkedIn content calendar.")),
              div(class = "concept-card",
                  tags$h4("\U0001f949 Priority 3 \u2014 This Quarter"),
                  tags$p("Write the full strategic communication plan. 
                  Produce a 90-second dashboard demo video. 
                  Prepare crisis communication response templates. 
                  Secure first trade press coverage ahead of Q2 2026 launch."))
            )
          )
      )
    ),

    fluidRow(
      box(title = "\U0001f5fa\ufe0f Atera\u2019s Complete Communication Roadmap", status = "success",
          solidHeader = TRUE, width = 12,
          fluidRow(
            column(3,
              div(class = "app-card",
                  tags$h4("\U0001f4dd Foundations (Ch 1\u20133)"),
                  tags$p(HTML(
                    "\u2705 Golden Thread per audience<br>
                     \u2705 KISS audit of all materials<br>
                     \u2705 Clich\u00e9 removal complete<br>
                     \u2705 Pyramid structure adopted<br>
                     \u2705 Evidence bank created<br>
                     \u2705 Plain-English glossary added"
                  )))
            ),
            column(3,
              div(class = "app-card",
                  tags$h4("\U0001f4d6 Storytelling (Ch 4\u20135)"),
                  tags$p(HTML(
                    "\u2705 Founding story written<br>
                     \u2705 Before-After-Bridge per audience<br>
                     \u2705 Story bank (6 entries)<br>
                     \u2705 Jeopardy statement in every pitch<br>
                     \u2705 3 \u2018Pat the Dog\u2019 moments identified<br>
                     \u2705 Investor pitch restructured (pathos first)"
                  )))
            ),
            column(3,
              div(class = "app-card",
                  tags$h4("\U0001f3a4 Speaking (Ch 6\u20137)"),
                  tags$p(HTML(
                    "\u2705 3 elevator pitch versions rehearsed<br>
                     \u2705 Slide deck redesigned<br>
                     \u2705 Killer fact per audience identified<br>
                     \u2705 Magic moment scripted (demo)<br>
                     \u2705 Q&A 10 questions prepared<br>
                     \u2705 Video presentation standards set"
                  )))
            ),
            column(3,
              div(class = "app-card",
                  tags$h4("\U0001f4e3 Strategic (Ch 8\u201310)"),
                  tags$p(HTML(
                    "\u2705 LinkedIn content calendar live<br>
                     \u2705 90s dashboard video produced<br>
                     \u2705 Message House built<br>
                     \u2705 Soundbite bank (5 soundbites)<br>
                     \u2705 Crisis templates prepared<br>
                     \u2705 SMART communication goals set"
                  )))
            )
          )
      )
    ),

    fluidRow(
      box(title = "\U0001f4ca Communication Readiness Tracker", status = "info",
          solidHeader = TRUE, width = 6,
          p(style = "font-size:13px; color:#555; margin-bottom:16px;",
            "Self-assessment: how ready is Atera\u2019s communication across all 10 dimensions?"),
          progress_bar_item("Ch 1 \u2014 Foundations & Golden Thread", 40),
          progress_bar_item("Ch 2 \u2014 Writing to Woo and Wow",       35),
          progress_bar_item("Ch 3 \u2014 Tricks of the Trade",          30),
          progress_bar_item("Ch 4 \u2014 Storytelling",                 25),
          progress_bar_item("Ch 5 \u2014 Strategic Stories",            20),
          progress_bar_item("Ch 6 \u2014 Public Speaking Basics",       45),
          progress_bar_item("Ch 7 \u2014 Powerful Presenting",          40),
          progress_bar_item("Ch 8 \u2014 Online World",                 30),
          progress_bar_item("Ch 9 \u2014 Media Relations",              15),
          progress_bar_item("Ch 10 \u2014 Strategic Communication",     20),
          div(class = "tip-box", style = "margin-top:16px;",
              tags$strong("\U0001f4a1 How to use this tracker: "),
              "Update each bar as you complete the action points for each chapter. 
              The goal is to reach 80%+ across all dimensions before the Q2 2026 commercial launch.")
      ),

      box(title = "\U0001f3af The Final Word", status = "primary",
          solidHeader = TRUE, width = 6,
          div(class = "concept-card",
              tags$h4("What Separates Good Communicators from Great Ones"),
              tags$p("The difference is not talent \u2014 it is discipline. 
              Great communicators know their audience before they write a word. 
              They find their Golden Thread and never let it go. 
              They edit until it hurts. They practise their stories until they feel lived. 
              They prepare for the worst questions. They post with purpose and pause before posting with anger. 
              And when things go wrong \u2014 as they always do \u2014 they communicate quickly, 
              honestly and with a plan.")),
          div(class = "concept-card",
              tags$h4("Atera\u2019s Communication Opportunity"),
              tags$p("Atera Analytics has a genuinely compelling story to tell: 
              a small team using rigorous science to solve a problem that matters, 
              backed by government investment, validated by independent bodies, 
              and ready for the market. That story, told well, 
              will open doors that technical capability alone cannot. 
              The platform is built. Now build the communication to match it.")),
          br(),
          div(class = "success-box",
              tags$strong("\u2728 The Golden Rule of Compelling Communication: "),
              tags$em("Say less, mean more, and make every word earn its place."),
              tags$br(), tags$br(),
              "Apply this to every email, every report, every pitch, every post, every conversation. 
              Do it consistently. The results will compound.")
      )
    )
  )
}

conclusion_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
  })
}
