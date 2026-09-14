# modules/ch5_strategic_stories.R
# Chapter 5: Strategic Stories (Storytelling II, the Sequel)

ch5_strategic_stories_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("Chapter 5"),
        tags$h2("Strategic Stories - Storytelling II, the Sequel"),
        div(
          span(class = "hero-badge", icon("globe"),       " Stories for All"),
          span(class = "hero-badge", icon("chess"),       " Art of Persuasion"),
          span(class = "hero-badge", icon("database"),    " Your Story Bank"),
          span(class = "hero-badge", icon("heart"),       " Pat the Dog"),
          span(class = "hero-badge", icon("graduation-cap"), " The Teachers\u2019 Tale")
        )
    ),

    fluidRow(
      box(title = "Chapter 5 - Overview", status = "primary",
          solidHeader = TRUE, width = 12,
          p("Chapter 5 moves storytelling from a communication technique into a deliberate strategic tool. ",
            "If Chapter 4 explains what makes a story work, Chapter 5 explains how to deploy stories ",
            "with intention - to persuade specific audiences, at specific moments, towards specific outcomes. ",
            "It introduces the story bank, the art of emotional resonance, and the gold standard of storytelling."),
          fluidRow(
            column(2, metric_card("Strategic", "Every Story Has a Purpose")),
            column(2, metric_card("Bank",      "Curate Your Story Library")),
            column(2, metric_card("\u2764",          "Emotion Precedes Decision")),
            column(2, metric_card("Scene",     "Context Primes the Story")),
            column(2, metric_card("Wisdom",    "One Lesson Per Story")),
            column(2, metric_card("Teachers",  "The Gold Standard")  )
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
                sh("(Stories) for All Mankind"),
                concept_card("Universal Stories, Specific Audiences",
                  "The most powerful stories share universal human themes - overcoming adversity, 
                  finding clarity in confusion, creating something meaningful from limited resources. 
                  These themes resonate across cultures, industries and seniority levels. 
                  The skill of the strategic storyteller is to find a universally resonant theme 
                  and make it specific enough to feel directly relevant to the particular audience 
                  sitting in front of them right now."),

                concept_card("Matching Story Type to Audience Need",
                  "Different audiences in different moments need different types of stories:<br><br>
                  <b>Sceptical audiences</b> need stories that demonstrate proof - case studies, 
                  before-and-after accounts, peer examples.<br><br>
                  <b>Uninformed audiences</b> need stories that create understanding - analogies 
                  embedded in narrative, \u2018what it felt like to have the problem\u2019 accounts.<br><br>
                  <b>Hostile audiences</b> need stories that build common ground - shared frustrations, 
                  shared goals, stories that acknowledge the legitimacy of their concern before 
                  presenting an alternative view."),

                sh("The Stages of a Successful Story"),
                concept_card("A Story Has Seven Stages",
                  "<b>1. Hook:</b> Capture attention immediately - a question, image or surprising fact.<br>
                  <b>2. Context:</b> Brief background - just enough for the story to make sense.<br>
                  <b>3. Challenge:</b> The problem, obstacle or tension that creates stakes.<br>
                  <b>4. Struggle:</b> The attempt to overcome - where the emotional engagement happens.<br>
                  <b>5. Turning point:</b> The moment things begin to change.<br>
                  <b>6. Resolution:</b> The outcome - what changed and why it matters.<br>
                  <b>7. Lesson:</b> The explicit or implicit meaning the audience is left with."),

                sh("The Art of Persuasion"),
                concept_card("Stories Are the Oldest Persuasion Technology",
                  "Aristotle identified three pillars of persuasion: logos (logic), ethos (credibility) 
                  and pathos (emotion). Most business communicators rely almost entirely on logos 
                  - data, evidence, rational argument. But research consistently shows that 
                  emotional resonance (pathos) is the primary driver of decision-making, 
                  with logic and credibility providing the justification afterwards. 
                  Story is the delivery mechanism for pathos.")
              ),

              column(6,
                sh("Setting the Scene for Storytelling"),
                concept_card("Context Primes the Audience to Receive the Story",
                  "Before telling a story in any professional context, briefly set the scene: 
                  who the protagonist is, when and where this took place, and what the stakes are. 
                  This priming takes no more than two or three sentences, but it dramatically 
                  increases the audience\u2019s engagement with what follows. 
                  A story dropped into a presentation without any scene-setting context 
                  takes several seconds to land - seconds in which the audience is confused 
                  rather than engaged."),

                sh("Your Story Bank of Appealing Anecdotes"),
                concept_card("Build and Maintain a Library of Stories",
                  "The most effective communicators do not invent stories on the spot - 
                  they draw from a carefully curated bank of stories they have collected, 
                  refined and practised over time. A story bank contains stories organised 
                  by theme and purpose: stories that demonstrate competence, stories that build 
                  empathy, stories that illustrate a specific point, stories that handle 
                  a specific objection. The goal is to have the right story ready 
                  for any communication moment."),

                concept_card("What to Include in a Story Bank",
                  "A professional story bank typically contains: 
                  founding stories and origin narratives; 
                  client or partner success stories with specific outcomes; 
                  stories of failure and what was learned; 
                  stories of unexpected discovery or insight; 
                  personal anecdotes that humanise the communicator; 
                  and industry stories that contextualise the organisation\u2019s work. 
                  Each entry should include a 30-second version and a 3-minute version."),

                sh("Pat the Dog, Stroke the Cat"),
                concept_card("Emotional Moments Anchor the Whole Story",
                  "This principle refers to the small, human, emotionally resonant moment 
                  within a story that makes the audience feel something real. 
                  It does not have to be dramatic - it might be a detail about a person\u2019s reaction, 
                  a moment of hesitation, an unexpected kindness, or a quiet admission of uncertainty. 
                  These human moments are what the audience remembers long after the facts have faded. 
                  One genuine emotional detail is worth more than three additional data points.")
              )
            ),

            hr(class = "divider"),
            fluidRow(
              column(6,
                sh("A Word of Wisdom"),
                concept_card("Every Story Must Carry a Lesson",
                  "A story without a lesson is entertainment. A story with a clear lesson is persuasion. 
                  The lesson does not always need to be stated explicitly - in fact, allowing the 
                  audience to draw the lesson themselves is often more powerful than spelling it out. 
                  But the storyteller must know exactly what lesson they intend before they begin, 
                  and every element of the story should serve that lesson."),

                sh("Through the Eyes of Others"),
                concept_card("Third-Person Stories Build Credibility",
                  "Stories told through the eyes of another person - a client, a partner, a user - 
                  are often more persuasive than first-person accounts because they avoid the 
                  appearance of self-promotion. When a customer\u2019s story is used to demonstrate 
                  the value of a product or platform, the audience hears an independent voice 
                  making the case. This is why case studies, testimonials and user stories 
                  are among the most persuasive formats in commercial communication.")
              ),

              column(6,
                sh("The Gold Standard of Storytelling: The Teachers\u2019 Tale"),
                concept_card("The Most Memorable Stories Teach Something",
                  "The gold standard of storytelling is the story that teaches. 
                  The best teachers throughout history have used stories not to entertain 
                  but to transfer understanding, shift perspective and change behaviour. 
                  In professional communication, a story that teaches the audience 
                  something genuinely useful about their world - something they did not know 
                  before, or did not feel before - creates a relationship of gratitude and trust 
                  that no amount of rational argument can replicate."),

                concept_card("What Separates Good Stories from Great Ones",
                  "Good stories are well-structured and clearly told. 
                  Great stories change the way the audience thinks or feels about something. 
                  The difference is specificity: great stories have precise, vivid, 
                  unexpected details that make the audience feel present. 
                  The name of the road. The exact number. The expression on someone\u2019s face. 
                  Specific details create the sensation of truth - and truth is what great stories feel like."),

                div(class = "success-box",
                    tags$strong("\u2705 Chapter 5 Summary: "),
                    "Build a story bank. Match story type to audience need. 
                    Set the scene before every story. Include one genuine emotional moment. 
                    Ensure every story teaches something. 
                    The gold standard: a story the audience is still thinking about tomorrow.")
              )
            )
          ), # end General Concepts

          # ── ATERA ANALYTICS APPLICATION ──────────────
          tabPanel("\U0001f3e2 Applicability on Atera Analytics",
            br(),
            fluidRow(
              column(6,
                shg("Atera\u2019s Strategic Story Bank"),
                app_card("Building Atera\u2019s Story Library",
                  "Atera should maintain a shared story bank document with entries organised 
                  by audience and purpose. Suggested initial entries:<br><br>
                  <b>The Problem Discovery Story:</b> How the team first identified the gap in UK 
                  CAV infrastructure assessment - the moment the problem became real.<br><br>
                  <b>The Technical Breakthrough Story:</b> A specific moment during development when 
                  something clicked - perhaps the first time the dashboard visualised 
                  a real route with AV risk scores, or the first validation of the ML path-planning algorithm.<br><br>
                  <b>The Council Conversation Story:</b> A specific interaction with a local authority 
                  representative that illustrated the scale of the gap and the appetite for a solution.<br><br>
                  <b>The Silverstone Story:</b> What happened at the Autonomous Vehicles event 
                  at Silverstone F1 Circuit - who Atera met, what they said, what it revealed 
                  about the market.<br><br>
                  <b>The Milestone Story:</b> What it felt like to deliver Milestone 5 on schedule 
                  - the human dimension of a \u00a328,419 technical achievement."),

                app_card("The Art of Persuasion in Atera\u2019s Investor Conversations",
                  "Investor conversations are won on pathos first, logos second. 
                  Atera\u2019s typical approach leads with technical capability and financial projections. 
                  A more persuasive structure leads with a story that makes the investor feel 
                  the scale and urgency of the problem, before presenting the solution and the numbers.<br><br>
                  Recommended structure for investor conversations:<br>
                  <b>1.</b> The problem story (2 minutes) - make them feel it<br>
                  <b>2.</b> The discovery story (1 minute) - how Atera came to exist<br>
                  <b>3.</b> The solution demonstration (3 minutes) - show, not tell<br>
                  <b>4.</b> The evidence story (2 minutes) - what Innovate UK validation means<br>
                  <b>5.</b> The market story (2 minutes) - the \u00a32B opportunity and Atera\u2019s position"),

                shg("Pat the Dog - Emotional Moments for Atera"),
                app_card("Finding the Human Details in Atera\u2019s Technical Work",
                  "Within Atera\u2019s project documentation are moments of genuine human significance 
                  that are currently described in purely technical language. These are the \u2018pat the dog\u2019 
                  moments - the emotional anchors that make the story real:<br><br>
                  The four individuals trained in GIS, Python and visualisation tools during the project 
                  - who are they? What did they learn? What can they now do that they could not before?<br><br>
                  The moment the dashboard first rendered a live Cambridge route - what did it feel like 
                  to see the route scored in real time for the first time?<br><br>
                  The House of Lords engagement - what was said? What was the reaction?<br><br>
                  These details cost nothing to include but make the story 
                  dramatically more memorable and persuasive.")
              ),

              column(6,
                shg("Matching Story Type to Atera\u2019s Audiences"),
                app_card("Sceptical Audiences - Proof Stories",
                  "For council officers or procurement teams who are cautious about new technology, 
                  Atera needs proof stories: specific, named case studies with quantifiable outcomes. 
                  Even within the current feasibility study, there are proof stories available:<br><br>
                  \u2018We assessed a 4.12km route in Cambridge - from North Cambridge to Petersfield - 
                  identifying the nearest charging point (0.24km from start), route risk zones, 
                  and infrastructure readiness score in real time. 
                  The same assessment by traditional survey methods would take several days.\u2019"),

                app_card("Uninformed Audiences - Understanding Stories",
                  "For audiences new to autonomous vehicles or CAV infrastructure, 
                  Atera needs stories that create understanding rather than demonstrate expertise. 
                  The most effective approach: tell the story of a problem the audience already 
                  knows from their own experience, then connect it to the AV context.<br><br>
                  Example: \u2018Think about the last time you drove on a road with poor signage, 
                  an unexpected tight bend, or a junction that caught you off guard. 
                  For a human driver, that\u2019s a moment of mild stress. 
                  For an autonomous vehicle relying entirely on infrastructure data, 
                  it is a potential failure point. Our platform identifies every one of those 
                  points before a vehicle is ever deployed.\u2019"),

                app_card("Through the Eyes of Others - Atera\u2019s Third-Person Stories",
                  "Atera should develop third-person stories that place stakeholders at the centre:<br><br>
                  <b>The council transport officer story:</b> their experience discovering that 
                  a route they had approved for AV trials had significant unassessed infrastructure gaps, 
                  and how Atera\u2019s platform gave them the evidence they needed.<br><br>
                  <b>The logistics operator story:</b> a fleet manager who needed to verify whether 
                  a new distribution route was suitable for autonomous operation, 
                  and how the platform delivered a risk-scored assessment in minutes rather than weeks.<br><br>
                  These do not need to be real yet - they can be composite scenarios based on 
                  research and stakeholder conversations, clearly presented as illustrative."),

                div(class = "success-box",
                    tags$strong("\u2705 Chapter 5 Action Points for Atera: "),
                    tags$ol(
                      tags$li("Create a shared story bank document with 6 initial story entries"),
                      tags$li("Rewrite the investor pitch opening to lead with pathos before logos"),
                      tags$li("Identify the three \u2018pat the dog\u2019 moments in Atera\u2019s project history"),
                      tags$li("Develop one third-person proof story for council audiences"),
                      tags$li("Develop one understanding story for AV-uninformed audiences")
                    ))
              )
            )
          ) # end Atera tab
        ) # end tabsetPanel
      ) # end box
    ) # end fluidRow
  )
}

ch5_strategic_stories_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
  })
}
