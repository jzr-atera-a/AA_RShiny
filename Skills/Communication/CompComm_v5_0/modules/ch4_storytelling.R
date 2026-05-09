# modules/ch4_storytelling.R

ch4_storytelling_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero("4", "The Splendour of Storytelling",
      "Data informs. Stories compel. Every business communication deserves a story with four ingredients: a protagonist, a challenge, a struggle and a resolution.",
      c("Power of Story", "Story Structure", "Pace", "Jeopardy", "Character")),

    fluidRow(
      column(2, stat_card("22\u00d7",  "Stories More Memorable Than Facts")),
      column(2, stat_card("4",     "Story Ingredients Required")),
      column(2, stat_card("3",     "Act Story Structure")),
      column(2, stat_card("Pace",  "Controls Audience Tension")),
      column(2, stat_card("!",     "Jeopardy Creates Engagement")),
      column(2, stat_card("Human", "Character Builds Connection"))
    ),

    fluidRow(
      tabBox(id = ns("tabs"), width = 12,
        tabPanel("\U0001f4da General Concepts", br(),
          fluidRow(
            column(6,
              sh("The Power of a Story"),
              framework_card("Why Stories Beat Statistics Every Time",
                "People remember stories up to 22 times more readily than facts alone. Stories bypass the sceptical, analytical part of the brain and speak directly to the part that feels, empathises and decides. A well-told story does not just inform \u2014 it changes how the listener sees the world."),
              sh("The Ingredients of a Story"),
              framework_card("What Every Compelling Story Contains",
                "A complete story requires four essential ingredients:<br>
                 <b>(1) A protagonist</b> \u2014 someone the audience can identify with or care about;<br>
                 <b>(2) A challenge or obstacle</b> \u2014 something that creates tension and raises stakes;<br>
                 <b>(3) A journey or struggle</b> \u2014 the attempt to overcome the challenge;<br>
                 <b>(4) A resolution</b> \u2014 an outcome that delivers meaning or learning."),
              framework_card("The Human Element Is Non-Negotiable",
                "Even in technical or commercial communication, the most powerful stories feature a human being at their centre. The protagonist might be a logistics manager whose routes are unreliable, or a council officer overwhelmed by the complexity of AV policy. Audiences connect to people, not products."),
              sh("Storytelling Structure"),
              framework_card("The Three-Act Structure",
                "<b>Act 1 \u2014 The Setup:</b> Introduce the world as it is. Establish the protagonist and the stakes. Make the audience care.<br><br>
                 <b>Act 2 \u2014 The Confrontation:</b> The problem emerges in full. Things get worse before they get better. This is where most business stories are too short \u2014 they skip the struggle and lose all emotional power.<br><br>
                 <b>Act 3 \u2014 The Resolution:</b> The challenge is overcome. The protagonist has changed or achieved something meaningful."),
              framework_card("The Before-After-Bridge Framework",
                "<b>Before:</b> Here is the world as it was \u2014 the problem, the pain, the gap.<br>
                 <b>After:</b> Here is the world as it could be \u2014 the outcome, the improvement, the benefit.<br>
                 <b>Bridge:</b> Here is how to get from Before to After \u2014 your solution, your service, your platform.")
            ),
            column(6,
              sh("Pace"),
              framework_card("Pace Is the Storyteller\u2019s Most Powerful Tool",
                "Slow down at moments of greatest tension or emotional significance. Speed up at transitions and background material. The contrast between fast and slow creates emphasis more powerfully than any amount of additional content."),
              framework_card("Pacing in Written and Spoken Communication",
                "In written stories, pace is controlled by sentence length and paragraph breaks. Very short sentences slow the reader down and signal importance. In spoken stories, the pause before a key revelation is one of the most powerful devices in live communication."),
              sh("Jeopardy"),
              framework_card("No Jeopardy, No Story",
                "Jeopardy is the element of risk, stakes or uncertainty that makes an audience lean forward. Without it, there is no story \u2014 only a report. In business communication, jeopardy is often the cost of inaction: what happens if this problem is never solved?"),
              sh("Character"),
              framework_card("Character Determines Credibility",
                "The character of the storyteller \u2014 their perceived honesty, expertise, warmth and authenticity \u2014 determines whether the audience believes the story. A story told by someone who clearly believes it and has lived it will always be more persuasive than a polished story delivered without conviction."),
              sh("A Cautionary Tale"),
              framework_card("What Happens When Stories Go Wrong",
                "A story that lacks tension becomes a sequence of pleasant events with no dramatic interest. The most common storytelling failure in business communication is the absence of genuine conflict \u2014 communicators who edit out all the difficulty destroy the entire emotional architecture of the story."),
              success_box(tags$strong("Chapter 4 Summary: "), "Build it with four ingredients. Control the pace. Inject jeopardy. Deliver it with authentic character. And never skip the struggle.")
            )
          )
        ),
        tabPanel("\U0001f3e2 Applicability on Atera Analytics", br(),
          fluidRow(
            column(6,
              shg("Atera\u2019s Core Founding Story"),
              insight_box("All Four Ingredients in Place",
                "<b>Protagonist:</b> A team of data scientists and engineers who saw that the UK was preparing to deploy autonomous vehicles onto roads it had never properly assessed.<br><br>
                 <b>Challenge:</b> No standardised, scalable method existed to evaluate road infrastructure readiness for CAVs. Government was committing hundreds of millions without an evidence base.<br><br>
                 <b>Journey:</b> Securing Innovate UK funding, building the technical infrastructure from scratch, navigating the complexity of GIS, ML and digital twin integration across 7 work packages.<br><br>
                 <b>Resolution:</b> A production-ready platform that can assess any UK road segment in real time \u2014 government-validated, commercially deployable, and built to scale."),
              shg("The Before-After-Bridge per Audience"),
              insight_box("Council Audience",
                "<b>Before:</b> Road assessment for AV readiness requires expensive manual surveys taking weeks.<br>
                 <b>After:</b> Any council officer can generate a real-time AV readiness score for any route.<br>
                 <b>Bridge:</b> Atera\u2019s GIS-based platform, accessible via SaaS subscription."),
              insight_box("AV Operator Audience",
                "<b>Before:</b> Operators deploy vehicles onto routes with incomplete infrastructure intelligence, creating safety risk and operational uncertainty.<br>
                 <b>After:</b> Every deployment decision is backed by real-time route scoring and risk analysis.<br>
                 <b>Bridge:</b> Atera\u2019s API-accessible route intelligence platform.")
            ),
            column(6,
              shg("Jeopardy in Atera\u2019s Communications"),
              insight_box("Making the Cost of Inaction Vivid",
                "\u2018Without infrastructure intelligence, the first serious AV incident on an inadequately assessed UK road will set back public trust in autonomous vehicles by a decade \u2014 and the liability question will fall on the operators who deployed without proper due diligence.\u2019<br><br>
                 \u2018Every month without a standardised assessment framework means another round of government CAV investment allocated without evidence.\u2019"),
              shg("Pace in Atera\u2019s Presentations"),
              insight_box("Slow Down at the Right Moments",
                "<b>Slow down when:</b> describing the human cost of the problem; revealing a surprising metric (number of roads currently unassessed); or delivering the platform demonstration so the audience can absorb what they are seeing.<br><br>
                 <b>Speed up when:</b> covering technical background the audience already understands; listing work package completions; or moving through historical context."),
              insight_box("Using Pause in Live Presentations",
                "Identify two or three moments in advance where a deliberate pause will add impact:<br><br>
                 After stating the number of UK roads without AV assessment: <em>pause.</em><br>
                 After the dashboard scores a live route for the first time: <em>pause.</em><br>
                 After stating the milestone value delivered: <em>pause.</em><br><br>
                 The pause gives the audience time to feel the significance of what they just heard."),
              success_box(tags$strong("Action Points: "),
                tags$ol(
                  tags$li("Write Atera\u2019s founding story in full \u2014 all four ingredients"),
                  tags$li("Create a Before-After-Bridge version for each of the 4 audiences"),
                  tags$li("Add a jeopardy statement to every pitch deck and proposal"),
                  tags$li("Mark three pause moments in the next live presentation script")
                ))
            )
          )
        )
      )
    )
  )
}

ch4_storytelling_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
