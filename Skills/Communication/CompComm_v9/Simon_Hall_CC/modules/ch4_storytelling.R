# modules/ch4_storytelling.R
# Chapter 4: The Splendour of Storytelling

ch4_storytelling_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("Chapter 4"),
        tags$h2("The Splendour of Storytelling"),
        div(
          span(class = "hero-badge", icon("book-open"),   " Power of Story"),
          span(class = "hero-badge", icon("layer-group"), " Story Structure"),
          span(class = "hero-badge", icon("tachometer-alt"), " Pace"),
          span(class = "hero-badge", icon("exclamation-triangle"), " Jeopardy"),
          span(class = "hero-badge", icon("user-friends"), " Character")
        )
    ),

    fluidRow(
      box(title = "Chapter 4 - Overview", status = "primary",
          solidHeader = TRUE, width = 12,
          p("Data informs. Stories compel. Chapter 4 makes the case that storytelling is not a ",
            "soft skill but the single most powerful persuasion technology available to any communicator. ",
            "It covers what makes a story work, how to structure one for maximum impact, ",
            "and how to deploy pace, jeopardy and character to keep any audience fully engaged."),
          fluidRow(
            column(2, metric_card("22\u00d7",  "Stories More Memorable Than Facts")),
            column(2, metric_card("3",      "Act Story Structure")),
            column(2, metric_card("Pace",   "Controls Audience Tension")),
            column(2, metric_card("!",      "Jeopardy Creates Engagement")),
            column(2, metric_card("Human",  "Character Builds Connection")),
            column(2, metric_card("1",      "Core Story Per Message"))
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
                sh("The Power of a Story"),
                concept_card("Why Stories Beat Statistics Every Time",
                  "Research consistently shows that people remember stories up to 22 times more readily 
                  than they remember facts alone. Stories bypass the sceptical, analytical part of the 
                  brain and speak directly to the part that feels, empathises and decides. 
                  A well-told story does not just inform - it changes how the listener sees the world. 
                  This is why the most persuasive communicators - in business, politics, science - 
                  all lead with story, not data."),

                concept_card("Stories as the Primary Vehicle for Change",
                  "Every significant change in human history has been driven by a story someone told. 
                  In business communication, the story is the argument. 
                  When you want a council to adopt a new platform, an investor to commit capital, 
                  or a partner to change their behaviour, the data alone will rarely be sufficient. 
                  The story that wraps the data is what moves people to act."),

                sh("The Ingredients of a Story"),
                concept_card("What Every Compelling Story Contains",
                  "A complete story requires four essential ingredients: 
                  <b>(1) A protagonist</b> - someone the audience can identify with or care about; 
                  <b>(2) A challenge or obstacle</b> - something that creates tension and raises stakes; 
                  <b>(3) A journey or struggle</b> - the attempt to overcome the challenge; 
                  <b>(4) A resolution</b> - an outcome that delivers meaning or learning. 
                  Without all four, a story is merely an anecdote."),

                concept_card("The Human Element Is Non-Negotiable",
                  "Even in technical or commercial communication, the most powerful stories 
                  feature a human being at their centre - not a company, not a platform, 
                  not a technology. The protagonist might be a logistics manager whose routes 
                  are unreliable, a council officer overwhelmed by the complexity of AV policy, 
                  or an engineer who spent months on a problem your solution solves in seconds. 
                  Audiences connect to people, not products.")
              ),

              column(6,
                sh("Storytelling Structure"),
                concept_card("The Three-Act Structure",
                  "<b>Act One - The Setup:</b> Introduce the world as it is. 
                  Establish the protagonist and the stakes. Make the audience care.<br><br>
                  <b>Act Two - The Confrontation:</b> The problem emerges in full force. 
                  Things get worse before they get better. Tension builds. 
                  This is where most business stories are too short - they skip the struggle 
                  and lose all the emotional power.<br><br>
                  <b>Act Three - The Resolution:</b> The challenge is overcome. 
                  The protagonist has changed, learned something, or achieved something meaningful. 
                  The audience is left with a clear emotional takeaway."),

                concept_card("The Before-After-Bridge Framework",
                  "A practical shorthand for business storytelling:<br><br>
                  <b>Before:</b> Here is the world as it was - the problem, the pain, the gap.<br>
                  <b>After:</b> Here is the world as it could be - the outcome, the improvement, the benefit.<br>
                  <b>Bridge:</b> Here is how to get from Before to After - your solution, your service, your platform.<br><br>
                  This structure works for pitches, proposals, case studies and presentations 
                  because it puts the audience\u2019s problem at the centre, not the product."),

                sh("The Long and Short of Storytelling"),
                concept_card("Match Story Length to Context",
                  "A story told in 60 seconds in a networking conversation must have a different 
                  shape than a story told over 10 minutes in a boardroom presentation. 
                  Both need all four ingredients, but the 60-second version must compress ruthlessly: 
                  one sentence of setup, one sentence of tension, one sentence of resolution, 
                  one sentence of meaning. Knowing the length before you start is as important 
                  as knowing the story.")
              )
            ),

            hr(class = "divider"),
            fluidRow(
              column(6,
                sh("Pace"),
                concept_card("Pace Is the Storyteller\u2019s Most Powerful Tool",
                  "Pace - the speed and rhythm at which a story is told - controls the emotional 
                  experience of the audience. Slow down at the moments of greatest tension or 
                  emotional significance: these are the moments the audience needs to feel, 
                  not rush through. Speed up at transitions and background material. 
                  The contrast between fast and slow creates emphasis more powerfully than 
                  any amount of additional content."),

                concept_card("Pacing in Written and Spoken Communication",
                  "In written stories, pace is controlled by sentence length and paragraph breaks. 
                  Very short sentences slow the reader down and signal importance. 
                  In spoken stories, pace is controlled by pauses, volume and delivery speed. 
                  The pause before a key revelation is one of the most powerful devices 
                  in live communication - it signals to the audience that something important is coming."),

                sh("A Cautionary Tale"),
                concept_card("What Happens When Stories Go Wrong",
                  "A story that lacks tension becomes a sequence of pleasant events with no dramatic 
                  interest. A story without a clear point becomes self-indulgent and loses the audience. 
                  A story that is too long becomes painful regardless of its quality. 
                  The most common storytelling failure in business communication is the absence 
                  of genuine conflict - communicators who want to appear positive edit out 
                  all the difficulty, and in doing so destroy the entire emotional architecture of the story.")
              ),

              column(6,
                sh("Jeopardy"),
                concept_card("No Jeopardy, No Story",
                  "Jeopardy is the element of risk, stakes or uncertainty that makes an audience 
                  lean forward. Without jeopardy - without the genuine possibility that things 
                  could go wrong, that the protagonist might fail, that the problem might not be solved - 
                  there is no story, only a report. 
                  In business communication, jeopardy is often the cost of inaction: 
                  what happens if this problem is never solved, this investment never made, 
                  this change never adopted?"),

                concept_card("How to Build Jeopardy Into Business Stories",
                  "Jeopardy does not require drama or crisis - it requires stakes. 
                  Frame the challenge in terms of what is at risk: money, time, safety, 
                  competitive position, public trust, people\u2019s lives. 
                  Make the audience feel that the outcome matters before you deliver the resolution. 
                  A story about solving a problem nobody cares about will always fail, 
                  regardless of how well it is told."),

                sh("The Character of Your Storytelling"),
                concept_card("Character Determines Credibility",
                  "The character of the storyteller - their perceived honesty, expertise, 
                  warmth and authenticity - determines whether the audience believes the story. 
                  Audiences can detect inauthenticity instantly. A story told by someone 
                  who clearly believes it, has lived it or has been genuinely affected by it 
                  will always be more persuasive than a polished story delivered without conviction."),

                div(class = "success-box",
                    tags$strong("\u2705 Chapter 4 Summary: "),
                    "Every business communication deserves a story. Build it with four ingredients: 
                    a protagonist, a challenge, a struggle and a resolution. 
                    Control the pace, inject jeopardy, and deliver it with authentic character.")
              )
            )
          ), # end General Concepts

          # ── ATERA ANALYTICS APPLICATION ──────────────
          tabPanel("\U0001f3e2 Applicability on Atera Analytics",
            br(),
            fluidRow(
              column(6,
                shg("Atera\u2019s Core Story"),
                app_card("The Founding Story of Atera Analytics",
                  "Every company has a founding story - and that story is one of the most persuasive 
                  assets available in investor meetings, partner conversations and media appearances. 
                  Atera\u2019s story contains all the ingredients of a compelling narrative:<br><br>
                  <b>Protagonist:</b> A team of data scientists and engineers who saw that the UK was 
                  preparing to deploy autonomous vehicles onto roads it had never properly assessed.<br><br>
                  <b>Challenge:</b> No standardised, scalable method existed to evaluate road infrastructure 
                  readiness for CAVs. Government was committing hundreds of millions of pounds 
                  without an evidence base.<br><br>
                  <b>Journey:</b> Securing Innovate UK funding, building the technical infrastructure 
                  from scratch, navigating the complexity of GIS, ML and digital twin integration 
                  across 7 work packages, all while validating against real route data.<br><br>
                  <b>Resolution:</b> A production-ready platform that can assess any UK road segment 
                  in real time - government-validated, commercially deployable, and built to scale."),

                app_card("The Before-After-Bridge for Each Audience",
                  "<b>For UK Councils:</b><br>
                  Before: Road assessment for AV readiness requires expensive manual surveys taking weeks.<br>
                  After: Any council officer can generate a real-time AV readiness score for any route.<br>
                  Bridge: Atera\u2019s GIS-based platform, accessible via SaaS subscription.<br><br>
                  <b>For AV Operators:</b><br>
                  Before: Operators deploy vehicles onto routes with incomplete infrastructure intelligence, 
                  creating safety risk and operational uncertainty.<br>
                  After: Every deployment decision is backed by real-time route scoring and risk analysis.<br>
                  Bridge: Atera\u2019s API-accessible route intelligence platform."),

                shg("Jeopardy in Atera\u2019s Communications"),
                app_card("Making the Cost of Inaction Vivid",
                  "Atera\u2019s communications often underplay jeopardy - presenting the platform as 
                  a helpful tool rather than a necessary response to genuine risk. 
                  Introducing jeopardy makes the story more compelling:<br><br>
                  \u2018Without infrastructure intelligence, the first serious AV incident on 
                  an inadequately assessed UK road will set back public trust in autonomous 
                  vehicles by a decade - and the liability question will fall on the operators 
                  who deployed without proper due diligence.\u2019<br><br>
                  \u2018Every month without a standardised assessment framework means another round 
                  of government CAV investment allocated without evidence - and another set of 
                  roads that may not perform as expected when vehicles are deployed.\u2019")
              ),

              column(6,
                shg("Pace in Atera\u2019s Presentations"),
                app_card("Slowing Down at the Right Moments",
                  "Atera\u2019s presentations tend to move at a uniform pace - methodical and thorough. 
                  Introducing pace variation creates emphasis and engagement:<br><br>
                  <b>Slow down when:</b> describing the human cost of the problem (the council officer 
                  who has no idea if their roads are AV-ready); revealing a surprising metric 
                  (the number of roads currently unassessed); or delivering the platform demonstration 
                  so the audience can absorb what they are seeing.<br><br>
                  <b>Speed up when:</b> covering technical background the audience already understands; 
                  listing work package completions; or moving through historical context."),

                app_card("Using Pause in Live Presentations",
                  "In every Atera stakeholder presentation or demo, identify two or three moments 
                  in advance where a deliberate pause will add impact:<br><br>
                  After stating the number of UK roads currently without AV assessment: pause.<br>
                  After the dashboard scores a live route for the first time in a demonstration: pause.<br>
                  After stating the milestone value delivered: pause.<br><br>
                  The pause gives the audience time to feel the significance of what they have just heard. 
                  It is one of the most underused tools in live communication."),

                shg("Character - Atera\u2019s Storytelling Credibility"),
                app_card("Who Tells Atera\u2019s Story, and How",
                  "The credibility of Atera\u2019s story depends heavily on who tells it and how authentically 
                  it is delivered. The most powerful spokesperson is not necessarily the most senior person 
                  - it is the person who is most genuinely connected to the problem being solved.<br><br>
                  When presenting to councils, lead with the operational challenge in their language. 
                  When presenting to investors, lead with the market gap and the evidence of need. 
                  When presenting to Innovate UK, lead with the scientific rigour and the validated outputs.<br><br>
                  In each case, the story should feel lived, not performed."),

                div(class = "success-box",
                    tags$strong("\u2705 Chapter 4 Action Points for Atera: "),
                    tags$ol(
                      tags$li("Write Atera\u2019s founding story in full - all four ingredients"),
                      tags$li("Create a Before-After-Bridge version for each of the 4 audience groups"),
                      tags$li("Add a jeopardy statement to every pitch deck and proposal"),
                      tags$li("Mark three pause moments in the next live presentation script"),
                      tags$li("Identify the right story spokesperson for each audience type")
                    ))
              )
            )
          ) # end Atera tab
        ) # end tabsetPanel
      ) # end box
    ) # end fluidRow
  )
}

ch4_storytelling_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
  })
}
