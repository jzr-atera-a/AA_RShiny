# modules/app_guide.R
# App Guide - Purpose, navigation and tab descriptions

app_guide_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # Hero
    div(class = "aa-hero",
        div(class = "hero-chapter-num", "Compelling Communication - Simon Hall"),
        tags$h1(class = "hero-title", "\U0001f9ed App Guide"),
        tags$p(class = "hero-subtitle",
          "What this app is, how to use it, and what you will find in each tab."),
        div(class = "badge-row",
          span(class = "hero-badge", icon("book"),         " Simon Hall"),
          span(class = "hero-badge", icon("university"),   " Cambridge University Press"),
          span(class = "hero-badge", icon("car"),          " Atera Analytics"),
          span(class = "hero-badge", icon("layer-group"),  " 12 Tabs"),
          span(class = "hero-badge", icon("flag-checkered"), " v7.0")
        )
    ),

    # Purpose statement
    fluidRow(
      box(title = "\U0001f3af Purpose of This App", status = "primary",
          solidHeader = TRUE, width = 12,
          fluidRow(
            column(8,
              tags$p(
                "This interactive reference guide maps the communication frameworks from ",
                tags$em("Compelling Communication"),
                " by Simon Hall (Cambridge University Press) directly onto the real-world context of ",
                tags$b("Atera Analytics Ltd"),
                " - a deep-tech company delivering AI-powered infrastructure assessment platforms ",
                "for autonomous and connected vehicles (CAV/AV), Innovate UK funded."
              ),
              tags$p(
                "Every chapter tab contains two subtabs: ",
                tags$b("General Concepts"),
                " covering the core theory and frameworks from the book, and ",
                tags$b("Applicability on Atera Analytics"),
                " translating that theory into concrete, actionable guidance for Atera's ",
                "stakeholder communications, pitch materials, milestone reports and partner conversations."
              ),
              div(class = "tip-box",
                tags$strong("\U0001f4a1 How to navigate: "),
                "Use the left sidebar to move between tabs. Each chapter tab follows the same ",
                "two-subtab structure. The Conclusion tab brings everything together with a ",
                "complete action roadmap and a readiness tracker."
              )
            ),
            column(4,
              div(class = "stat-card", span(class = "stat-value", "10"), span(class = "stat-label", "Chapters Covered")),
              div(class = "stat-card", span(class = "stat-value", "2"), span(class = "stat-label", "Subtabs per Chapter")),
              div(class = "stat-card", span(class = "stat-value", "4"), span(class = "stat-label", "Atera Audience Groups")),
              div(class = "stat-card", span(class = "stat-value", "v7"), span(class = "stat-label", "Current Version"))
            )
          )
      )
    ),

    # Tab descriptions - row 1
    fluidRow(
      box(title = NULL, status = "primary", solidHeader = FALSE, width = 12,
        div(style = "padding: 10px 0 6px; font-size:11px; font-weight:800; color:#1a3a4a;
                     text-transform:uppercase; letter-spacing:1.5px; border-bottom:2px solid #E8A020;
                     margin-bottom:16px;",
          "\U0001f5fa\ufe0f Tab Guide - What You Will Find in Each Section"
        ),

        fluidRow(
          # Overview
          column(4,
            div(class = "framework-card",
              tags$h5(icon("home"), " Overview"),
              tags$p(
                "The starting point for new users. Introduces the book and its author, ",
                "explains the two-subtab structure used throughout, and sets the Atera Analytics ",
                "context: company background, key stakeholder groups, market opportunity, ",
                "and why communication excellence matters at every stage of the project."
              ),
              div(style = "margin-top:8px;",
                span(class = "topic-tag", "About the App"),
                span(class = "topic-tag", "Atera Context"),
                span(class = "topic-tag", "Stakeholders")
              )
            )
          ),
          # Ch1
          column(4,
            div(class = "framework-card",
              tags$h5(icon("lightbulb"), " Ch 1 - Foundations"),
              tags$p(
                "The non-negotiable foundations of all effective communication: the Golden Thread ",
                "principle (one clear idea per message), the KISS rule, audience empathy and the ",
                "Audience Audit framework, authentic voice and style, and the strategic use of ",
                "surprise to earn and hold attention. Applied to Atera's four audience groups."
              ),
              div(style = "margin-top:8px;",
                span(class = "topic-tag", "Golden Thread"),
                span(class = "topic-tag", "KISS"),
                span(class = "topic-tag", "Audience Audit")
              )
            )
          ),
          # Ch2
          column(4,
            div(class = "framework-card",
              tags$h5(icon("pen"), " Ch 2 - Writing to Wow"),
              tags$p(
                "The craft toolkit for compelling writing: striking openings, memorable closings, ",
                "the Rule of Threes, counterpoint, analogy for explaining complex ideas, ",
                "eliminating cliches, and writing titles that compel reading rather than merely ",
                "label content. Applied to Atera's milestone reports, pitches and emails."
              ),
              div(style = "margin-top:8px;",
                span(class = "topic-tag", "Rule of Threes"),
                span(class = "topic-tag", "Analogy"),
                span(class = "topic-tag", "Titles")
              )
            )
          )
        ),

        fluidRow(
          # Ch3
          column(4,
            div(class = "framework-card",
              tags$h5(icon("tools"), " Ch 3 - Trade Tricks"),
              tags$p(
                "Professional writing craft: smart structures (Pyramid, Problem-Solution, Narrative), ",
                "writing for screen rather than page, visual hierarchy, texture through sentence variety, ",
                "inclusive language for diverse audiences, Show Not Tell as the core rule of persuasion, ",
                "and the discipline of editing in five passes."
              ),
              div(style = "margin-top:8px;",
                span(class = "topic-tag", "Structure"),
                span(class = "topic-tag", "Show Not Tell"),
                span(class = "topic-tag", "Editing")
              )
            )
          ),
          # Ch4
          column(4,
            div(class = "framework-card",
              tags$h5(icon("book-open"), " Ch 4 - Storytelling"),
              tags$p(
                "The power and craft of storytelling: the four essential story ingredients, ",
                "the three-act structure, the Before-After-Bridge framework, pace and rhythm, ",
                "jeopardy as the engine of engagement, and character as the foundation of ",
                "credibility. Applied to Atera's founding story and stakeholder narratives."
              ),
              div(style = "margin-top:8px;",
                span(class = "topic-tag", "Story Structure"),
                span(class = "topic-tag", "Jeopardy"),
                span(class = "topic-tag", "Character")
              )
            )
          ),
          # Ch5
          column(4,
            div(class = "framework-card",
              tags$h5(icon("chess"), " Ch 5 - Strategic Stories"),
              tags$p(
                "Using stories with intention: matching story type to audience (sceptical, uninformed, ",
                "hostile), the six-stage story structure, pathos before logos in investor conversations, ",
                "Pat the Dog moments, building a story bank, and the art of telling stories through ",
                "the eyes of others. Applied to Atera's investor and council pitches."
              ),
              div(style = "margin-top:8px;",
                span(class = "topic-tag", "Story Bank"),
                span(class = "topic-tag", "Persuasion"),
                span(class = "topic-tag", "Audience Matching")
              )
            )
          )
        ),

        fluidRow(
          # Ch6
          column(4,
            div(class = "framework-card",
              tags$h5(icon("microphone"), " Ch 6 - Public Speaking"),
              tags$p(
                "The fundamentals of presenting: the 60-second elevator pitch, building presentations ",
                "around a single clear purpose, the slide design hierarchy (one idea per slide), ",
                "the dos and don'ts of data presentation, the Killer Fact technique, ",
                "and lifesaver responses for when things go wrong."
              ),
              div(style = "margin-top:8px;",
                span(class = "topic-tag", "Elevator Pitch"),
                span(class = "topic-tag", "Slides"),
                span(class = "topic-tag", "Killer Fact")
              )
            )
          ),
          # Ch7
          column(4,
            div(class = "framework-card",
              tags$h5(icon("comments"), " Ch 7 - Powerful Speaking"),
              tags$p(
                "Advanced presenting skills: deliberate audience interaction, signposting to guide ",
                "the audience through structure, creating planned Magic Moments, body language and ",
                "non-verbal credibility, managing nerves, removing verbal redundancies, timing, ",
                "online presenting standards, and Q&A mastery with the bridging formula."
              ),
              div(style = "margin-top:8px;",
                span(class = "topic-tag", "Interaction"),
                span(class = "topic-tag", "Body Language"),
                span(class = "topic-tag", "Q&A Mastery")
              )
            )
          ),
          # Ch8
          column(4,
            div(class = "framework-card",
              tags$h5(icon("globe"), " Ch 8 - Online World"),
              tags$p(
                "Professional digital communication: the Golden Rule of giving value before asking, ",
                "writing your bio in three lengths, choosing platforms strategically, ",
                "social media content strategy, photography and video standards, ",
                "using AI in content creation responsibly, handling trolls, ",
                "and the 24-hour rule for sensitive posts."
              ),
              div(style = "margin-top:8px;",
                span(class = "topic-tag", "LinkedIn"),
                span(class = "topic-tag", "Bio Writing"),
                span(class = "topic-tag", "Content Strategy")
              )
            )
          )
        ),

        fluidRow(
          # Ch9
          column(4,
            div(class = "framework-card",
              tags$h5(icon("newspaper"), " Ch 9 - Media"),
              tags$p(
                "Working with journalists: writing news releases that get published, timing strategy, ",
                "handling unexpected media enquiries, the Message House framework (roof, three rooms, ",
                "foundations), bridging to stay on-message, crafting sub-15-word soundbites, ",
                "dress and camera standards for video, and awareness of journalist tactics."
              ),
              div(style = "margin-top:8px;",
                span(class = "topic-tag", "News Release"),
                span(class = "topic-tag", "Message House"),
                span(class = "topic-tag", "Soundbites")
              )
            )
          ),
          # Ch10
          column(4,
            div(class = "framework-card",
              tags$h5(icon("chess-king"), " Ch 10 - Strategic Comms"),
              tags$p(
                "Communication as a strategic asset: setting SMART communication goals, the ",
                "seven-component strategic communication plan, the rule that bad news must travel ",
                "fast, kitchen sinking, proactive risk communication, the six-step crisis framework, ",
                "and the long game of reputation recovery through actions not announcements."
              ),
              div(style = "margin-top:8px;",
                span(class = "topic-tag", "SMART Goals"),
                span(class = "topic-tag", "Crisis Comms"),
                span(class = "topic-tag", "Reputation")
              )
            )
          ),
          # Conclusion
          column(4,
            div(class = "framework-card",
              tags$h5(icon("flag-checkered"), " Conclusion"),
              tags$p(
                "The synthesis of all 10 chapters: each chapter's core insight distilled to one line, ",
                "Atera's single unifying Golden Thread, a three-tier priority action roadmap ",
                "(This Week, This Month, This Quarter), a complete communication roadmap checklist ",
                "across four domains, and a self-assessment readiness tracker for all 10 dimensions."
              ),
              div(style = "margin-top:8px;",
                span(class = "topic-tag", "Master Summary"),
                span(class = "topic-tag", "Action Roadmap"),
                span(class = "topic-tag", "Readiness Tracker")
              )
            )
          )
        )
      )
    ),

    # Quick-start
    fluidRow(
      box(title = "\u26a1 Quick Start - Recommended Reading Order", status = "success",
          solidHeader = TRUE, width = 12,
          fluidRow(
            column(4,
              div(class = "insight-box",
                tags$h5(class = "ib-title", "\U0001f4dd If You Have 20 Minutes"),
                tags$p(style = "color:rgba(255,255,255,.82); font-size:12.5px;",
                  "Read the Applicability subtab in Ch 1 (Golden Thread per audience), ",
                  "Ch 6 (Elevator Pitch versions), and the Conclusion (Action Roadmap). ",
                  "These three tabs give you the highest-impact frameworks immediately actionable for Atera."
                )
              )
            ),
            column(4,
              div(class = "insight-box",
                tags$h5(class = "ib-title", "\U0001f4cb If You Have a Pitch This Week"),
                tags$p(style = "color:rgba(255,255,255,.82); font-size:12.5px;",
                  "Chapters 4, 5, 6 and 7 cover storytelling and presenting end-to-end. ",
                  "Read the Applicability subtabs for your specific audience type (council, investor, ",
                  "Innovate UK) and use the action points at the bottom of each chapter tab."
                )
              )
            ),
            column(4,
              div(class = "insight-box",
                tags$h5(class = "ib-title", "\U0001f4e3 If You Have a Press Enquiry"),
                tags$p(style = "color:rgba(255,255,255,.82); font-size:12.5px;",
                  "Go directly to Ch 9 (Media) Applicability subtab. It contains Atera's ",
                  "Message House, pre-written bridging phrases, a soundbite bank, and a ",
                  "complete media interview checklist ready to use before any journalist interaction."
                )
              )
            )
          )
      )
    )
  )
}

app_guide_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
    # Informational tab - no reactive logic required
  })
}
