# modules/ch9_media.R
# Chapter 9: Mixing It with the Media

ch9_media_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("Chapter 9"),
        tags$h2("Mixing It with the Media"),
        div(
          span(class = "hero-badge", icon("newspaper"),    " News Release"),
          span(class = "hero-badge", icon("clock"),        " Timing"),
          span(class = "hero-badge", icon("phone"),        " Journalist Calls"),
          span(class = "hero-badge", icon("home"),         " Message House"),
          span(class = "hero-badge", icon("random"),       " Bridging"),
          span(class = "hero-badge", icon("quote-left"),   " Soundbites")
        )
    ),

    fluidRow(
      box(title = "Chapter 9 - Overview", status = "primary",
          solidHeader = TRUE, width = 12,
          p("Media coverage can transform the trajectory of an organisation. ",
            "A single well-placed news story reaches audiences that years of direct marketing cannot. ",
            "Chapter 9 covers the full spectrum of media communication: ",
            "writing news releases that actually get published, handling journalist calls with confidence, ",
            "building a message house, using bridging to stay on-message, ",
            "crafting soundbites, and navigating the tactics journalists use to get the story they want."),
          fluidRow(
            column(2, metric_card("News",    "Must Be Genuinely New")),
            column(2, metric_card("Timing",  "Is a Strategic Decision")),
            column(2, metric_card("House",   "3 Core Messages Maximum")),
            column(2, metric_card("Bridge",  "Always Return to Thread")),
            column(2, metric_card("Bite",    "Under 15 Words")),
            column(2, metric_card("Dress",   "Camera Reads Everything"))
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
                sh("The News Release"),
                concept_card("What Makes a Story Newsworthy",
                  "Journalists are not in the business of promoting organisations - 
                  they are in the business of serving readers with content that is new, 
                  significant, relevant or surprising. A news release will only generate 
                  coverage if it contains genuine news: something that did not exist yesterday, 
                  something that affects the reader\u2019s world, or something that challenges 
                  a widely held assumption. Company milestone announcements without external 
                  relevance, product launches without genuine benefit to readers, 
                  and self-congratulatory achievement announcements almost never generate coverage."),

                concept_card("The Anatomy of an Effective News Release",
                  "<b>Headline:</b> States the news in under 12 words. Active voice. Specific. 
                  No exclamation marks. No puns unless the publication is tabloid.<br><br>
                  <b>Opening paragraph:</b> Answers all five Ws in 40 words or fewer: 
                  Who, What, When, Where, Why. A journalist should be able to write 
                  a short story from this paragraph alone.<br><br>
                  <b>Second paragraph:</b> The most significant supporting fact or context.<br><br>
                  <b>Quote:</b> One short, punchy quote from a named spokesperson that adds 
                  perspective - not a restatement of the facts already given.<br><br>
                  <b>Notes to editors:</b> Background information the journalist may need 
                  but that is not part of the news story itself."),

                sh("The Timing of a Release"),
                concept_card("When You Release Is As Important As What You Release",
                  "News releases sent on a Friday afternoon rarely generate coverage 
                  - newsrooms are at minimum staffing and journalists are looking 
                  at the following week. Tuesday to Thursday mornings are typically optimal 
                  for B2B and trade press. Timing also means watching the news agenda: 
                  releasing news that aligns with a current policy debate, 
                  a relevant government announcement or an industry event 
                  dramatically increases the chance of coverage."),

                sh("Eek! (A Journalist Calls)"),
                concept_card("How to Handle an Unexpected Media Enquiry",
                  "When a journalist calls unexpectedly, the correct initial response 
                  is never to answer the questions immediately. Instead: 
                  take the journalist\u2019s name, publication and deadline; 
                  establish what they are working on; 
                  tell them you will call back within the hour; 
                  use that time to prepare your message house, identify your key messages 
                  and prepare for the most challenging questions. 
                  Journalists are experienced interviewers. 
                  Spontaneous responses to sensitive questions rarely end well."),

                sh("Predicting Questions and Preparing Answers"),
                concept_card("There Are No Unexpected Questions - Only Unprepared Ones",
                  "Before any media interaction - planned or unplanned - write down 
                  the ten questions you most hope the journalist will not ask. 
                  Then prepare honest, well-framed, on-message answers to all ten. 
                  A spokesperson who has prepared for the worst-case questions 
                  will handle any actual question with composure. 
                  A spokesperson who has only prepared for comfortable questions 
                  will be visibly unsettled by the first challenge.")
              ),

              column(6,
                sh("The Message House"),
                concept_card("Building Your Three-Roomed Message House",
                  "The Message House is a preparation framework for any media or stakeholder interaction. 
                  It has three components:<br><br>
                  <b>The roof (your Golden Thread):</b> The single overarching message 
                  that everything else serves. One sentence.<br><br>
                  <b>The three rooms (your supporting messages):</b> Three specific points 
                  that support and expand the Golden Thread. Each one should be capable 
                  of standing alone as a soundbite.<br><br>
                  <b>The foundations (your evidence):</b> The specific facts, figures and examples 
                  that support each of the three rooms. Never used unprompted - 
                  deployed in response to questions that invite them."),

                sh("Bridging"),
                concept_card("The Art of Returning to Your Message",
                  "Bridging is the technique of acknowledging a question or challenge 
                  and then moving the conversation back to your prepared messages. 
                  It is not evasion - it is message discipline. 
                  Bridging phrases: \u2018That\u2019s an important point, and what I\u2019d add is...\u2019; 
                  \u2018The context for that is...\u2019; \u2018What I think is really significant here is...\u2019; 
                  \u2018Let me put that in a broader perspective...\u2019. 
                  The bridge acknowledges, then moves. It never dismisses or evades."),

                sh("Tone"),
                concept_card("Tone Determines How Your Message Is Received",
                  "In media communication, the emotional register you project is as important 
                  as the content of what you say. Defensive tone signals that you have something 
                  to hide. Overconfident tone signals that you are not listening. 
                  The optimal tone for most professional media interactions is 
                  calm authority: measured, factual, confident and human. 
                  This tone is achieved through preparation, not performance - 
                  you cannot fake calmness you have not earned through thorough preparation."),

                sh("Soundbites"),
                concept_card("The Quotable Sentence Is a Craft Skill",
                  "A soundbite is a short, memorable phrase that encapsulates a larger point. 
                  It should be under 15 words, contain one clear idea, 
                  use active rather than passive voice, and be specific enough to be vivid 
                  but broad enough to be quotable out of context. 
                  Soundbites are not spontaneous - they are prepared in advance 
                  and delivered at the right moment. 
                  Every media-trained spokesperson has a bank of tested soundbites 
                  for their three key messages.")
              )
            ),

            hr(class = "divider"),
            fluidRow(
              column(6,
                sh("Online Interviews"),
                concept_card("Video Media Requires Different Skills",
                  "Online interviews and podcast appearances require the same preparation 
                  as broadcast media but with additional technical considerations. 
                  Camera placement, background, lighting and audio quality 
                  all affect how credible the spokesperson appears. 
                  A poorly lit, badly framed video interview in front of a cluttered background 
                  undermines the credibility of even the most carefully prepared content. 
                  Technical quality signals organisational quality."),

                sh("Dress to Impress"),
                concept_card("What You Wear Communicates Before You Speak",
                  "In broadcast and video media, the camera reads everything. 
                  Avoid: fine stripes or checks (create moir\u00e9 patterns on camera); 
                  very bright white (creates exposure problems); 
                  clothing with prominent logos (distracting). 
                  Wear: solid mid-tones (blues, greys, greens) that complement skin tones; 
                  simple, clean lines; nothing that will distract attention from your face and words.")
              ),

              column(6,
                sh("Dirty Tricks"),
                concept_card("Know What Journalists May Do",
                  "Ethical journalism is the overwhelming norm, but it helps to be aware 
                  of techniques that can be used to elicit unguarded responses: 
                  the long silence after you have finished speaking (designed to prompt you to fill it -  
                  resist; silence is their problem, not yours); 
                  the friendly off-the-record chat before the formal interview begins 
                  (nothing is truly off the record until you have agreed it explicitly); 
                  the hypothetical question (\u2018If X happened, would you...\u2019 - decline hypotheticals); 
                  and the final question as you are walking away 
                  (the most unguarded responses come when people think they are done)."),

                div(class = "success-box",
                    tags$strong("\u2705 Chapter 9 Summary: "),
                    "Send news releases only when you have genuine news. 
                    Never answer unexpectedly without preparation time. 
                    Build your Message House before every media interaction. 
                    Practise bridging until it is instinctive. 
                    Prepare your soundbites. Know the dirty tricks. 
                    And remember: everything is on the record unless explicitly agreed otherwise.")
              )
            )
          ), # end General Concepts

          tabPanel("\U0001f3e2 Applicability on Atera Analytics",
            br(),
            fluidRow(
              column(6,
                shg("Atera\u2019s News Release Opportunities"),
                app_card("When Atera Has Genuine News Worth Releasing",
                  "Not every milestone warrants a press release, but several of Atera\u2019s 
                  upcoming moments do - if framed with external relevance:<br><br>
                  <b>Platform commercial launch (Q2 2026):</b> 
                  \u2018UK\u2019s First Real-Time AV Infrastructure Assessment Platform Launches - 
                  Built on Innovate UK-Funded Research\u2019. 
                  Target: trade press (Autocar, Fleet News, Transport Network, Smart Transport), 
                  tech press (TechCrunch UK, WIRED UK), regional press (Cambridge).<br><br>
                  <b>First pilot council agreement:</b> 
                  \u2018[Council Name] Becomes First UK Authority to Assess Roads for Autonomous Vehicle Readiness\u2019. 
                  Target: local government press (Local Government Chronicle, Municipal Journal).<br><br>
                  <b>Innovate UK programme completion:</b> 
                  Frame around the policy implication - not the grant - for broadest coverage."),

                app_card("Writing Atera\u2019s First News Release - Template Structure",
                  "<b>Headline:</b> UK Platform Scores Road Infrastructure for Autonomous Vehicles in Real Time<br><br>
                  <b>Para 1 (the five Ws):</b> Atera Analytics (who) has launched (what) a platform (what) 
                  that assesses UK road infrastructure readiness for autonomous vehicles in real time (why/what), 
                  becoming the first organisation to commercialise AI-powered CAV route scoring in the UK (significance).<br><br>
                  <b>Para 2 (supporting fact):</b> The platform, developed with Innovate UK funding as part 
                  of the Cam Pathfinder One programme, has completed 5 of 7 technical milestones 
                  and is entering commercial deployment targeting UK local authorities, 
                  logistics operators and autonomous vehicle companies.<br><br>
                  <b>Quote:</b> [Joseph Zubizarreta, 12 words or fewer that add perspective not already given.]<br><br>
                  <b>Notes to editors:</b> Atera Analytics background, Innovate UK reference number, contact."),

                shg("Atera\u2019s Message House"),
                app_card("The Three-Roomed Message House for Media",
                  "<b>The Roof (Golden Thread):</b><br>
                  \u2018Atera Analytics is making autonomous vehicle deployment safer and smarter 
                  by giving operators and councils the infrastructure intelligence they need.\u2019<br><br>
                  <b>Room 1 - The Problem:</b><br>
                  \u2018The UK has no standardised framework for assessing whether road infrastructure 
                  is ready for autonomous vehicles, despite growing public and commercial investment.\u2019<br><br>
                  <b>Room 2 - The Solution:</b><br>
                  \u2018Our AI-powered platform scores any UK road segment for AV readiness in real time, 
                  using GIS data, machine learning and validated digital twin technology.\u2019<br><br>
                  <b>Room 3 - The Credibility:</b><br>
                  \u2018Government-funded through Innovate UK, validated through the Zenzic Cam Pathfinder 
                  programme, and commercially deploying in Q2 2026.\u2019<br><br>
                  <b>The Foundations (deploy when asked):</b><br>
                  Specific milestone values, route assessment times, council addressable market (100+), 
                  comparison with manual survey costs, Marks & Clerk IP roadmap.")
              ),

              column(6,
                shg("Bridging and Soundbites for Atera"),
                app_card("Atera\u2019s Bridging Phrases for Challenging Questions",
                  "<b>Q: Isn\u2019t this just another AI startup that won\u2019t survive without grants?</b><br>
                  Bridge: \u2018That\u2019s the right question to ask of any deep-tech company - 
                  and what I\u2019d point to is our four commercial revenue streams already identified, 
                  with pilot conversations active before we\u2019ve even completed the funded phase.\u2019<br><br>
                  <b>Q: Is the platform actually ready, or is this still a research project?</b><br>
                  Bridge: \u2018It\u2019s a fair distinction to make. Five of seven technical milestones 
                  are complete, the dashboard is operational, and we have a confirmed 
                  Q2 2026 commercial launch. This is a platform, not a paper.\u2019<br><br>
                  <b>Q: Who are your competitors?</b><br>
                  Bridge: \u2018Most organisations in the AV space focus on vehicle technology. 
                  We focus on infrastructure - which is the gap nobody else has addressed 
                  at national scale in the UK.\u2019"),

                app_card("Atera\u2019s Soundbite Bank",
                  "Prepare and practise these soundbites until they feel natural:<br><br>
                  \u2018You can\u2019t safely deploy autonomous vehicles onto roads you haven\u2019t assessed.\u2019<br><br>
                  \u2018We built the infrastructure intelligence layer that the whole CAV industry needs.\u2019<br><br>
                  \u2018Government is investing hundreds of millions in CAV. We make sure it goes to the right roads.\u2019<br><br>
                  \u2018Our platform does in real time what currently takes weeks of manual survey.\u2019<br><br>
                  \u2018Every road that gets an AV before it gets assessed is a risk that could have been avoided.\u2019<br><br>
                  Each soundbite is under 15 words. Each contains one clear, quotable idea. 
                  Each supports one of the three rooms in the Message House."),

                app_card("Interview Checklist for Atera Spokespeople",
                  "Before every media interaction - print, broadcast or online - complete this checklist:<br><br>
                  \u2610 Message House prepared (roof + 3 rooms + foundations)<br>
                  \u2610 10 most challenging questions anticipated and answered<br>
                  \u2610 3 soundbites prepared and practised<br>
                  \u2610 3 bridging phrases ready<br>
                  \u2610 Technical background simplified for non-specialist journalist<br>
                  \u2610 Camera/lighting/background checked if online<br>
                  \u2610 Clothing chosen (no stripes, no bright white)<br>
                  \u2610 Duration confirmed and respected<br>
                  \u2610 Confirmed what is on/off the record (default: everything is on the record)"),

                div(class = "success-box",
                    tags$strong("\u2705 Chapter 9 Action Points for Atera: "),
                    tags$ol(
                      tags$li("Build Atera\u2019s Message House and circulate to all spokespeople"),
                      tags$li("Write and practise 5 soundbites across the three message rooms"),
                      tags$li("Prepare a news release template for the Q2 2026 commercial launch"),
                      tags$li("Identify 10 target media titles for each of Atera\u2019s audience segments"),
                      tags$li("Create an interview checklist for all team media appearances")
                    ))
              )
            )
          ) # end Atera tab
        ) # end tabsetPanel
      ) # end box
    ) # end fluidRow
  )
}

ch9_media_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
  })
}
