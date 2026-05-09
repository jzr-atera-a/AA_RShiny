# modules/ch2_writing.R

ch2_writing_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero("2", "Writing to Woo and Wow",
      "Knowing what to communicate is only half the challenge. The other half is how to write it so people actually read, absorb and act on it.",
      c("Striking Starts", "Rule of Threes", "Counterpoint", "Analogy", "Triumphant Titles")),

    fluidRow(
      column(2, stat_card("3s",   "To Hook a Reader")),
      column(2, stat_card("3\u00d7",  "Rule of Threes Power")),
      column(2, stat_card("\u2260",   "Counterpoint Builds Trust")),
      column(2, stat_card("\u2248",   "Analogy = Clarity")),
      column(2, stat_card("\u2717",   "Ban All Clich\u00e9s")),
      column(2, stat_card("1st",  "Title Is Always Read First"))
    ),

    fluidRow(
      tabBox(id = ns("tabs"), width = 12,
        tabPanel("\U0001f4da General Concepts", br(),
          fluidRow(
            column(6,
              sh("Striking Starts"),
              framework_card("The Opening Is Everything",
                "Readers decide whether to continue within the first three seconds. A striking start can be: a bold statement, a surprising statistic, a provocative question, a vivid anecdote, or a counterintuitive claim. What it must never be: a lengthy preamble, a statement of the obvious, or \u2018I am writing to you today regarding...\u2019"),
              framework_card("Five Types of Powerful Openings",
                "<b>1. The Bold Statement:</b> State your conclusion first, then support it.<br>
                 <b>2. The Killer Statistic:</b> One surprising number that reframes the problem.<br>
                 <b>3. The Question:</b> A question the reader cannot answer \u2014 but needs you to.<br>
                 <b>4. The Anecdote:</b> A one-sentence scene that puts the reader in the story.<br>
                 <b>5. The Counterintuitive:</b> Something that directly contradicts a common assumption."),
              sh("Enduring Endings"),
              framework_card("Your Last Word Is Your Lasting Impression",
                "The closing of any communication is the second most remembered section after the opening. It should reinforce the Golden Thread, leave a clear impression, and state a precise call to action. Vague endings waste the most powerful real estate in your communication."),
              sh("The Rule of Threes"),
              framework_card("Three Is the Magic Number of Communication",
                "The brain processes information most efficiently in groups of three. Three-part structures feel complete, rhythmic and authoritative: \u2018fast, reliable, and affordable\u2019; \u2018we plan, we build, we deliver.\u2019 The Rule of Threes is the single most powerful structural device in persuasive writing."),
              sh("Counterpoint"),
              framework_card("Acknowledge the Other Side \u2014 Then Defeat It",
                "Raising and then answering an objection is one of the most powerful persuasion techniques available. It signals confidence, honesty and intellectual rigour. Audiences trust communicators who proactively address weaknesses far more than those who present only strengths.")
            ),
            column(6,
              sh("Analogy"),
              framework_card("Make the Complex Instantly Understandable",
                "Analogy is the most powerful tool for explaining technical or abstract ideas to non-expert audiences. A well-chosen analogy does in one sentence what three paragraphs of explanation cannot: it gives the reader an immediate mental model they can hold and use."),
              sh("The Voice"),
              framework_card("Write As You Would Speak at Your Best",
                "Voice in writing is the sense that a real, thoughtful person is behind the words. Writing that sounds like a committee or a press release has lost its voice. The test: read it aloud. If it sounds stiff or robotic, rewrite until it sounds like a confident, warm, knowledgeable human being."),
              sh("Clich\u00e9s \u2014 The Enemy of Impact"),
              framework_card("Ban These From Your Writing",
                "\u2018Cutting-edge\u2019, \u2018world-class\u2019, \u2018innovative\u2019, \u2018game-changing\u2019, \u2018synergy\u2019, \u2018leverage\u2019, \u2018paradigm shift\u2019, \u2018going forward\u2019, \u2018circle back\u2019, \u2018low-hanging fruit\u2019. Every clich\u00e9 signals that the writer stopped thinking. Replace each one with a specific, concrete, original phrase."),
              sh("Triumphant Titles"),
              framework_card("The Title Is Read First \u2014 Make It Work",
                "A strong title states the benefit or outcome, creates curiosity, uses active language, and is specific rather than generic. \u2018Q3 Project Report\u2019 is a filing label. \u2018Milestone 5 Achieved: Platform Ready for Commercial Deployment\u2019 is a title."),
              framework_card("Title Formulas That Work",
                "<b>Outcome-first:</b> How [Solution] Achieves [Specific Result]<br>
                 <b>Question:</b> Are UK Roads Ready for Autonomous Vehicles?<br>
                 <b>The Number:</b> 5 Reasons the CAV Market Needs Infrastructure Intelligence Now<br>
                 <b>The Contrast:</b> From Manual Survey to Real-Time AI"),
              success_box(tags$strong("Chapter 2 Summary: "), "Strike with your opening. Structure in threes. Use analogy for complexity. Acknowledge objections. Kill every clich\u00e9. Give every document a triumphant title.")
            )
          )
        ),
        tabPanel("\U0001f3e2 Applicability on Atera Analytics", br(),
          fluidRow(
            column(6,
              shg("Striking Starts for Atera"),
              insight_box("Opening Lines for Key Documents",
                "<b>Innovate UK Report:</b> \u2018Milestone 5 is complete. Atera Analytics has delivered all seven data architecture deliverables on schedule, establishing the UK\u2019s first AI-powered CAV infrastructure assessment pipeline.\u2019<br><br>
                 <b>Council Pitch:</b> \u2018Over 100 UK councils have no standardised way to assess whether their roads are ready for autonomous vehicles. This platform changes that \u2014 in real time.\u2019<br><br>
                 <b>Investor Pitch:</b> \u2018The UK is committing \u00a3200M+ to CAV infrastructure \u2014 but has no national framework to decide where to spend it. We built one.\u2019"),
              example_pair(
                bad_text  = "My name is Joseph from Atera Analytics, an AI company based in the UK that has been working on a feasibility study funded by Innovate UK...",
                good_text = "Your roads may not be ready for autonomous vehicles. Our platform tells you exactly which ones \u2014 and why. We work with Innovate UK and Zenzic."
              ),
              shg("Rule of Threes \u2014 Atera\u2019s Core Messages"),
              insight_box("Three-Part Value Propositions per Audience",
                "<b>Councils:</b> \u2018Cost-effective. Evidence-based. Immediately deployable.\u2019<br>
                 <b>AV Operators:</b> \u2018Real-time route intelligence. Reduced deployment risk. Scalable across the UK.\u2019<br>
                 <b>Innovate UK:</b> \u2018On schedule. On budget. Commercially validated.\u2019<br>
                 <b>Investors:</b> \u2018Government-backed. Technically proven. Market-ready.\u2019")
            ),
            column(6,
              shg("Analogies for Atera\u2019s Technology"),
              insight_box("Making the Platform Understandable to All Audiences",
                "<b>Overall platform:</b> \u2018Think of our platform as a TripAdvisor for roads \u2014 except instead of rating restaurants, it rates how ready each road segment is for autonomous vehicles, based on real infrastructure data.\u2019<br><br>
                 <b>Digital twin:</b> \u2018A digital twin is like a flight simulator for roads \u2014 engineers can test how a vehicle will perform on a specific route before any vehicle drives it for real.\u2019<br><br>
                 <b>AI route scoring:</b> \u2018Our AI works like a very experienced road safety inspector who never sleeps and can assess every road in the country simultaneously.\u2019"),
              shg("Triumphant Titles \u2014 Atera Document Audit"),
              insight_box("Rewriting Atera\u2019s Key Document Titles",
                "<b>Reports:</b><br>\u274c Q3 Project Progression Update<br>\u2705 Five Milestones Complete: Atera\u2019s CAV Platform Enters Final Phase<br><br>
                 <b>Presentations:</b><br>\u274c Opt Tech 4 \u2014 Project Overview<br>\u2705 From Feasibility to Market: How AI Is Making UK Roads AV-Ready<br><br>
                 <b>Email subjects:</b><br>\u274c Follow up from our meeting<br>\u2705 Platform demonstration \u2014 30 minutes to see AV readiness scoring live"),
              success_box(tags$strong("Action Points: "),
                tags$ol(
                  tags$li("Rewrite the opening paragraph of the next Innovate UK report"),
                  tags$li("Build a three-part value proposition for each of the 4 audiences"),
                  tags$li("Create an analogy library: 5 analogies for core platform technologies"),
                  tags$li("Audit all document titles against the Triumphant Title criteria"),
                  tags$li("Remove all clich\u00e9s from the exploitation plan and pitch deck")
                ))
            )
          )
        )
      )
    )
  )
}

ch2_writing_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
