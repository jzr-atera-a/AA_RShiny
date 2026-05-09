# modules/ch5_strategic_stories.R

ch5_strategic_stories_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero("5", "Strategic Stories \u2014 Storytelling II",
      "If Chapter 4 explains what makes a story work, Chapter 5 explains how to deploy stories with intention \u2014 to persuade specific audiences, at specific moments, towards specific outcomes.",
      c("Story Bank", "Art of Persuasion", "Pat the Dog", "Teachers Tale", "Scene Setting")),

    fluidRow(
      column(2, stat_card("Strategic", "Every Story Has a Purpose")),
      column(2, stat_card("Bank",      "Curate Your Story Library")),
      column(2, stat_card("\u2764",         "Emotion Precedes Decision")),
      column(2, stat_card("7",         "Stages of a Successful Story")),
      column(2, stat_card("Scene",     "Context Primes the Story")),
      column(2, stat_card("Teach",     "The Gold Standard"))
    ),

    fluidRow(
      tabBox(id = ns("tabs"), width = 12,
        tabPanel("\U0001f4da General Concepts", br(),
          fluidRow(
            column(6,
              sh("Universal Stories, Specific Audiences"),
              framework_card("Match Story Type to Audience Need",
                "<b>Sceptical audiences</b> need stories that demonstrate proof \u2014 case studies, before-and-after accounts, peer examples.<br><br>
                 <b>Uninformed audiences</b> need stories that create understanding \u2014 analogies embedded in narrative.<br><br>
                 <b>Hostile audiences</b> need stories that build common ground \u2014 shared frustrations, shared goals, stories that acknowledge the legitimacy of their concern before presenting an alternative view."),
              sh("The Seven Stages of a Successful Story"),
              framework_card("A Story Has Seven Stages",
                "<b>1. Hook:</b> Capture attention immediately.<br>
                 <b>2. Context:</b> Brief background \u2014 just enough for the story to make sense.<br>
                 <b>3. Challenge:</b> The problem, obstacle or tension that creates stakes.<br>
                 <b>4. Struggle:</b> The attempt to overcome \u2014 where emotional engagement happens.<br>
                 <b>5. Turning point:</b> The moment things begin to change.<br>
                 <b>6. Resolution:</b> The outcome \u2014 what changed and why it matters.<br>
                 <b>7. Lesson:</b> The explicit or implicit meaning the audience is left with."),
              sh("The Art of Persuasion"),
              framework_card("Stories Are the Oldest Persuasion Technology",
                "Aristotle identified three pillars of persuasion: logos (logic), ethos (credibility) and pathos (emotion). Most business communicators rely almost entirely on logos \u2014 data and rational argument. But emotional resonance (pathos) is the primary driver of decision-making, with logic providing the justification afterwards. Story is the delivery mechanism for pathos."),
              sh("Setting the Scene"),
              framework_card("Context Primes the Audience to Receive the Story",
                "Before telling a story in any professional context, briefly set the scene: who the protagonist is, when and where this took place, and what the stakes are. This priming takes no more than two or three sentences, but dramatically increases the audience\u2019s engagement.")
            ),
            column(6,
              sh("Your Story Bank"),
              framework_card("Build and Maintain a Library of Stories",
                "The most effective communicators do not invent stories on the spot \u2014 they draw from a carefully curated bank of stories they have collected, refined and practised over time. A story bank contains stories organised by theme and purpose: stories that demonstrate competence, stories that build empathy, stories that handle a specific objection."),
              framework_card("What to Include in a Story Bank",
                "Founding stories and origin narratives; client or partner success stories with specific outcomes; stories of failure and what was learned; stories of unexpected discovery or insight; personal anecdotes that humanise the communicator; and industry stories that contextualise the work. Each entry should include a 30-second version and a 3-minute version."),
              sh("Pat the Dog, Stroke the Cat"),
              framework_card("Emotional Moments Anchor the Whole Story",
                "This principle refers to the small, human, emotionally resonant moment within a story that makes the audience feel something real. It does not have to be dramatic \u2014 it might be a detail about a person\u2019s reaction, a moment of hesitation, or a quiet admission of uncertainty. One genuine emotional detail is worth more than three additional data points."),
              sh("The Gold Standard: The Teachers\u2019 Tale"),
              framework_card("The Most Memorable Stories Teach Something",
                "The gold standard of storytelling is the story that teaches. The best teachers use stories not to entertain but to transfer understanding, shift perspective and change behaviour. A story that teaches the audience something genuinely useful about their world \u2014 something they did not know before, or did not feel before \u2014 creates a relationship of gratitude and trust that no amount of rational argument can replicate."),
              pull_quote("Good stories are well-structured and clearly told. Great stories change the way the audience thinks or feels about something. The difference is specificity.", "Simon Hall \u2014 Compelling Communication"),
              success_box(tags$strong("Chapter 5 Summary: "), "Build a story bank. Match story type to audience. Set the scene. Include one genuine emotional moment. Every story must teach something.")
            )
          )
        ),
        tabPanel("\U0001f3e2 Applicability on Atera Analytics", br(),
          fluidRow(
            column(6,
              shg("Atera\u2019s Strategic Story Bank"),
              insight_box("Building Atera\u2019s Story Library \u2014 6 Initial Entries",
                "<b>The Problem Discovery Story:</b> How the team first identified the gap in UK CAV infrastructure assessment.<br><br>
                 <b>The Technical Breakthrough Story:</b> The first time the dashboard visualised a real route with AV risk scores.<br><br>
                 <b>The Council Conversation Story:</b> A specific interaction with a local authority that illustrated the scale of the gap.<br><br>
                 <b>The Silverstone Story:</b> The Autonomous Vehicles event at Silverstone F1 Circuit \u2014 who Atera met, what they said, what it revealed about the market.<br><br>
                 <b>The Milestone Story:</b> What it felt like to deliver Milestone 5 on schedule \u2014 the human dimension of a \u00a328,419 technical achievement.<br><br>
                 <b>The Poland Story:</b> The Horizon Europe collaboration scheme \u2014 cross-sector connections and what they revealed about European CAV ambitions."),
              shg("Audience-Matched Story Types"),
              insight_box("Sceptical Audiences \u2014 Proof Stories",
                "For council officers or procurement teams who are cautious about new technology, Atera needs proof stories with quantifiable outcomes:<br><br>
                 \u2018We assessed a 4.12km route in Cambridge \u2014 from North Cambridge to Petersfield \u2014 identifying the nearest charging point (0.24km from start), route risk zones, and infrastructure readiness score in real time. The same assessment by traditional survey methods would take several days.\u2019")
            ),
            column(6,
              shg("Pat the Dog \u2014 Finding Atera\u2019s Human Moments"),
              insight_box("The Emotional Anchors in Atera\u2019s Technical Work",
                "Within Atera\u2019s project documentation are moments of genuine human significance currently described in purely technical language. These are the \u2018pat the dog\u2019 moments:<br><br>
                 The four individuals trained in GIS, Python and visualisation tools \u2014 who are they? What did they learn?<br><br>
                 The moment the dashboard first rendered a live Cambridge route \u2014 what did it feel like to see the route scored in real time for the first time?<br><br>
                 The House of Lords engagement \u2014 what was said? What was the reaction?<br><br>
                 These details cost nothing to include but make the story dramatically more memorable and persuasive."),
              shg("Through the Eyes of Others"),
              insight_box("Third-Person Stories for Atera",
                "<b>The council transport officer story:</b> Their experience discovering that a route they had approved for AV trials had significant unassessed infrastructure gaps, and how Atera\u2019s platform gave them the evidence they needed.<br><br>
                 <b>The logistics operator story:</b> A fleet manager who needed to verify whether a new distribution route was suitable for autonomous operation, and how the platform delivered a risk-scored assessment in minutes."),
              success_box(tags$strong("Action Points: "),
                tags$ol(
                  tags$li("Create a shared story bank document with 6 initial story entries"),
                  tags$li("Rewrite the investor pitch opening to lead with pathos before logos"),
                  tags$li("Identify the three \u2018pat the dog\u2019 moments in Atera\u2019s project history"),
                  tags$li("Develop one proof story for council audiences with specific metrics"),
                  tags$li("Develop one understanding story for AV-uninformed audiences")
                ))
            )
          )
        )
      )
    )
  )
}

ch5_strategic_stories_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
