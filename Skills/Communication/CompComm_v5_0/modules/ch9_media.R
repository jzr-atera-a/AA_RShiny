# modules/ch9_media.R

ch9_media_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero("9", "Mixing It with the Media",
      "Build a Message House before every media interaction. Practise bridging until it is instinctive. Prepare your soundbites. And remember: everything is on the record unless explicitly agreed otherwise.",
      c("News Release", "Message House", "Bridging", "Soundbites", "Dirty Tricks")),

    fluidRow(
      column(2, stat_card("News",    "Must Be Genuinely New")),
      column(2, stat_card("Timing",  "Is a Strategic Decision")),
      column(2, stat_card("3",       "Core Messages Maximum")),
      column(2, stat_card("Bridge",  "Always Return to Thread")),
      column(2, stat_card("<15",     "Words Per Soundbite")),
      column(2, stat_card("On",      "Record Unless Agreed Otherwise"))
    ),

    fluidRow(
      tabBox(id = ns("tabs"), width = 12,
        tabPanel("\U0001f4da General Concepts", br(),
          fluidRow(
            column(6,
              sh("The News Release"),
              framework_card("What Makes a Story Newsworthy",
                "Journalists serve readers with content that is new, significant, relevant or surprising. A news release will only generate coverage if it contains genuine news: something that did not exist yesterday, something that affects the reader\u2019s world, or something that challenges a widely held assumption."),
              framework_card("The Anatomy of an Effective News Release",
                "<b>Headline:</b> States the news in under 12 words. Active voice. Specific.<br>
                 <b>Opening paragraph:</b> Answers the five Ws in 40 words: Who, What, When, Where, Why.<br>
                 <b>Second paragraph:</b> The most significant supporting fact or context.<br>
                 <b>Quote:</b> One short, punchy quote from a named spokesperson that adds perspective \u2014 not a restatement of the facts already given.<br>
                 <b>Notes to editors:</b> Background information the journalist may need."),
              sh("Handling a Journalist Call"),
              framework_card("Eek! \u2014 How to Handle an Unexpected Media Enquiry",
                "When a journalist calls unexpectedly, never answer the questions immediately. Instead: take the journalist\u2019s name, publication and deadline; establish what they are working on; tell them you will call back within the hour; use that time to prepare your message house and anticipate the most challenging questions."),
              framework_card("Predicting Questions \u2014 There Are No Unexpected Ones",
                "Before any media interaction, write down the ten questions you most hope the journalist will not ask. Then prepare honest, well-framed, on-message answers to all ten. A spokesperson who has prepared for the worst-case questions will handle any actual question with composure."),
              sh("The Message House"),
              framework_card("Building Your Three-Roomed Message House",
                "<b>The Roof (Golden Thread):</b> The single overarching message \u2014 one sentence.<br>
                 <b>The Three Rooms:</b> Three specific points that support and expand the Golden Thread. Each should stand alone as a soundbite.<br>
                 <b>The Foundations (Evidence):</b> Specific facts and figures that support each room. Deployed in response to questions \u2014 never unprompted.")
            ),
            column(6,
              sh("Bridging"),
              framework_card("The Art of Returning to Your Message",
                "Bridging is acknowledging a question and then moving the conversation back to your prepared messages. It is not evasion \u2014 it is message discipline. Bridging phrases: \u2018That\u2019s an important point, and what I\u2019d add is...\u2019; \u2018The context for that is...\u2019; \u2018What I think is really significant here is...\u2019"),
              sh("Soundbites"),
              framework_card("The Quotable Sentence Is a Craft Skill",
                "A soundbite is a short, memorable phrase that encapsulates a larger point. It should be under 15 words, contain one clear idea, use active rather than passive voice, and be specific enough to be vivid but broad enough to be quotable out of context. Soundbites are not spontaneous \u2014 they are prepared in advance."),
              sh("Tone & Online Interviews"),
              framework_card("Tone Determines How Your Message Is Received",
                "In media communication, the emotional register you project is as important as the content. Defensive tone signals that you have something to hide. Overconfident tone signals that you are not listening. The optimal tone for most professional media interactions is calm authority: measured, factual, confident and human."),
              framework_card("Online Interviews Require Additional Attention",
                "Camera placement, background, lighting and audio quality all affect how credible the spokesperson appears. A poorly lit, badly framed video interview in front of a cluttered background undermines even the most carefully prepared content."),
              sh("Dirty Tricks"),
              framework_card("Know What Journalists May Do",
                "<b>The long silence:</b> Designed to prompt you to fill it \u2014 resist; silence is their problem, not yours.<br>
                 <b>The off-the-record chat:</b> Nothing is off the record until you have agreed it explicitly.<br>
                 <b>The hypothetical:</b> \u2018If X happened, would you...\u2019 \u2014 decline hypotheticals.<br>
                 <b>The walking-away question:</b> The most unguarded responses come when people think they are done."),
              success_box(tags$strong("Chapter 9 Summary: "), "Send news releases only when you have genuine news. Build your Message House before every interaction. Practise bridging. Prepare your soundbites. Know the dirty tricks.")
            )
          )
        ),
        tabPanel("\U0001f3e2 Applicability on Atera Analytics", br(),
          fluidRow(
            column(6,
              shg("Atera\u2019s News Release Opportunities"),
              insight_box("When Atera Has Genuine News Worth Releasing",
                "<b>Platform commercial launch (Q2 2026):</b><br>
                 Headline: \u2018UK\u2019s First Real-Time AV Infrastructure Assessment Platform Launches\u2019.<br>
                 Target: trade press (Fleet News, Transport Network, Smart Transport), tech press (WIRED UK), regional press (Cambridge).<br><br>
                 <b>First pilot council agreement:</b><br>
                 Headline: \u2018[Council Name] Becomes First UK Authority to Assess Roads for Autonomous Vehicle Readiness\u2019.<br>
                 Target: Local Government Chronicle, Municipal Journal.<br><br>
                 <b>Innovate UK programme completion:</b><br>
                 Frame around the policy implication \u2014 not the grant \u2014 for broadest coverage."),
              shg("Atera\u2019s Message House"),
              insight_box("The Three-Roomed House for Media Interactions",
                "<b>The Roof (Golden Thread):</b><br>
                 \u2018Atera Analytics is making autonomous vehicle deployment safer and smarter by giving operators and councils the infrastructure intelligence they need.\u2019<br><br>
                 <b>Room 1 \u2014 The Problem:</b><br>
                 \u2018The UK has no standardised framework for assessing whether road infrastructure is ready for autonomous vehicles, despite growing public and commercial investment.\u2019<br><br>
                 <b>Room 2 \u2014 The Solution:</b><br>
                 \u2018Our AI-powered platform scores any UK road segment for AV readiness in real time, using GIS data, machine learning and validated digital twin technology.\u2019<br><br>
                 <b>Room 3 \u2014 The Credibility:</b><br>
                 \u2018Government-funded through Innovate UK, validated through the Zenzic Cam Pathfinder programme, and commercially deploying in Q2 2026.\u2019")
            ),
            column(6,
              shg("Bridging and Soundbites for Atera"),
              insight_box("Atera\u2019s Bridging Phrases for Challenging Questions",
                "<b>Q: Isn\u2019t this just another AI startup that won\u2019t survive without grants?</b><br>
                 Bridge: \u2018That\u2019s the right question to ask of any deep-tech company \u2014 and what I\u2019d point to is our four commercial revenue streams already identified, with pilot conversations active before we\u2019ve even completed the funded phase.\u2019<br><br>
                 <b>Q: Is the platform actually ready, or is this still research?</b><br>
                 Bridge: \u2018Five of seven technical milestones are complete, the dashboard is operational, and we have a confirmed Q2 2026 commercial launch. This is a platform, not a paper.\u2019<br><br>
                 <b>Q: Who are your competitors?</b><br>
                 Bridge: \u2018Most organisations in the AV space focus on vehicle technology. We focus on infrastructure \u2014 which is the gap nobody else has addressed at national scale in the UK.\u2019"),
              insight_box("Atera\u2019s Soundbite Bank",
                "\u2018You can\u2019t safely deploy autonomous vehicles onto roads you haven\u2019t assessed.\u2019<br><br>
                 \u2018We built the infrastructure intelligence layer that the whole CAV industry needs.\u2019<br><br>
                 \u2018Government is investing hundreds of millions in CAV. We make sure it goes to the right roads.\u2019<br><br>
                 \u2018Our platform does in real time what currently takes weeks of manual survey.\u2019<br><br>
                 \u2018Every road that gets an AV before it gets assessed is a risk that could have been avoided.\u2019"),
              success_box(tags$strong("Action Points: "),
                tags$ol(
                  tags$li("Build Atera\u2019s Message House and circulate to all spokespeople"),
                  tags$li("Write and practise 5 soundbites across the three message rooms"),
                  tags$li("Prepare a news release template for the Q2 2026 commercial launch"),
                  tags$li("Identify 10 target media titles for each of Atera\u2019s audience segments"),
                  tags$li("Create an interview checklist for all team media appearances")
                ))
            )
          )
        )
      )
    )
  )
}

ch9_media_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
