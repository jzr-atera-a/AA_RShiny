# modules/conclusion.R

conclusion_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero("", "A Compelling Conclusion",
      "Bringing it all together \u2014 the complete communication framework applied to Atera Analytics.",
      c("All 10 Chapters", "Atera Roadmap", "Communication Excellence", "Ready for Market")),

    fluidRow(
      box(title = "The Book in One Page \u2014 10 Core Insights", status = "primary", solidHeader = TRUE, width = 12,
        tags$p(style="font-size:13px;color:#2c3e50;margin-bottom:18px;",
          "Simon Hall\u2019s ", tags$em("Compelling Communication"), " can be distilled into a single principle: ",
          tags$strong("say less, mean more, and make every word earn its place."),
          " Everything in the 10 chapters serves that principle."),
        div(class = "timeline-strip",
          tl_cell("1",  "Foundations",    "Find your Golden Thread, audit your audience, commit to brevity and deploy one moment of surprise."),
          tl_cell("2",  "Writing",        "Open with a strike, structure in threes, use analogy for complexity and give every document a triumphant title."),
          tl_cell("3",  "Trade Tricks",   "Structure before writing, show evidence not claims, include every reader and edit without mercy."),
          tl_cell("4",  "Storytelling",   "Build every story with four ingredients: protagonist, challenge, struggle and resolution."),
          tl_cell("5",  "Str. Stories",   "Match story type to audience, build a story bank, include one emotional moment, ensure every story teaches."),
          tl_cell("6",  "Speaking I",     "Know your 60-second pitch cold. Slides are visual support. One killer fact. Always have a lifesaver."),
          tl_cell("7",  "Speaking II",    "Interact, signpost, create magic moments, project confident body language, prepare every Q&A answer."),
          tl_cell("8",  "Online World",   "Give value before you ask, write three bio lengths, choose platforms strategically, think before every post."),
          tl_cell("9",  "Media",          "Build a Message House, practise bridging, prepare soundbites, get your retaliation in first."),
          tl_cell("10", "Strategy",       "Start with a measurable goal, communicate bad news fast and fully, plan for crisis before it arrives.")
        )
      )
    ),

    fluidRow(
      box(title = "Atera\u2019s Unifying Golden Thread", status = "warning", solidHeader = TRUE, width = 6,
        pull_quote(
          "Atera Analytics is making autonomous vehicle deployment safer and smarter by giving operators and councils the infrastructure intelligence they need \u2014 government-validated, AI-powered, and commercially ready.",
          "Atera Analytics \u2014 Golden Thread, all audiences"
        ),
        tags$br(),
        framework_card("The Three Priorities for Immediate Action",
          "<b>\U0001f947 This Week:</b> Write the Golden Thread for all 4 audience groups. Rewrite the LinkedIn headline and About section. Prepare the 60-second elevator pitch in three versions. Remove all clich\u00e9s from the exploitation plan.<br><br>
           <b>\U0001f948 This Month:</b> Build the story bank (6 entries). Create the Message House for media interactions. Redesign the Q3 progression deck with conclusion headlines. Launch a 12-week LinkedIn content calendar.<br><br>
           <b>\U0001f949 This Quarter:</b> Write the full strategic communication plan. Produce a 90-second dashboard demo video. Prepare crisis communication response templates. Secure first trade press coverage ahead of Q2 2026 launch.")
      ),

      box(title = "Communication Readiness Tracker", status = "info", solidHeader = TRUE, width = 6,
        tags$p(style="font-size:12px;color:#546e7a;margin-bottom:14px;",
          "Self-assessment: how ready is Atera\u2019s communication across all 10 dimensions? Update as you complete each chapter\u2019s action points."),
        pct_bar("Ch 1 \u2014 Foundations & Golden Thread", 40),
        pct_bar("Ch 2 \u2014 Writing to Woo and Wow",      35),
        pct_bar("Ch 3 \u2014 Tricks of the Trade",         30),
        pct_bar("Ch 4 \u2014 Storytelling",                25),
        pct_bar("Ch 5 \u2014 Strategic Stories",           20),
        pct_bar("Ch 6 \u2014 Public Speaking Basics",      45),
        pct_bar("Ch 7 \u2014 Powerful Presenting",         40),
        pct_bar("Ch 8 \u2014 Online World",                30),
        pct_bar("Ch 9 \u2014 Media Relations",             15),
        pct_bar("Ch 10 \u2014 Strategic Communication",    20)
      )
    ),

    fluidRow(
      box(title = "Atera\u2019s Complete Communication Roadmap", status = "success", solidHeader = TRUE, width = 12,
        fluidRow(
          column(3,
            div(class="framework-card",
              tags$h5("\U0001f4dd Foundations (Ch 1\u20133)"),
              tags$p(HTML(
                "\u2705 Golden Thread per audience<br>
                 \u2705 KISS audit of all materials<br>
                 \u2705 Clich\u00e9 removal complete<br>
                 \u2705 Pyramid structure adopted<br>
                 \u2705 Evidence bank created<br>
                 \u2705 Plain-English glossary added")))),
          column(3,
            div(class="framework-card",
              tags$h5("\U0001f4d6 Storytelling (Ch 4\u20135)"),
              tags$p(HTML(
                "\u2705 Founding story written<br>
                 \u2705 Before-After-Bridge per audience<br>
                 \u2705 Story bank (6 entries)<br>
                 \u2705 Jeopardy statement in every pitch<br>
                 \u2705 3 \u2018Pat the Dog\u2019 moments identified<br>
                 \u2705 Investor pitch restructured")))),
          column(3,
            div(class="framework-card",
              tags$h5("\U0001f3a4 Speaking (Ch 6\u20137)"),
              tags$p(HTML(
                "\u2705 3 elevator pitch versions rehearsed<br>
                 \u2705 Slide deck redesigned<br>
                 \u2705 Killer fact per audience identified<br>
                 \u2705 Magic moment scripted (demo)<br>
                 \u2705 Q&A 10 questions prepared<br>
                 \u2705 Video presentation standards set")))),
          column(3,
            div(class="framework-card",
              tags$h5("\U0001f4e3 Strategic (Ch 8\u201310)"),
              tags$p(HTML(
                "\u2705 LinkedIn content calendar live<br>
                 \u2705 90s dashboard video produced<br>
                 \u2705 Message House built<br>
                 \u2705 Soundbite bank (5 soundbites)<br>
                 \u2705 Crisis templates prepared<br>
                 \u2705 SMART communication goals set"))))
        ),
        tags$br(),
        success_box(
          tags$strong("\u2728 The Golden Rule of Compelling Communication: "),
          tags$em("Say less, mean more, and make every word earn its place."),
          tags$br(), tags$br(),
          "Apply this to every email, every report, every pitch, every post, every conversation. Do it consistently. The results will compound."
        )
      )
    )
  )
}

conclusion_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
