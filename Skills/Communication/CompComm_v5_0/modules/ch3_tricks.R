# modules/ch3_tricks.R

ch3_tricks_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero("3", "The Tricks of the Writing Trade",
      "Structure before you write. Design for the screen. Show with evidence. Then edit without mercy \u2014 five passes minimum.",
      c("Smart Structures", "Screen-First", "Show Not Tell", "Inclusive Writing", "Edit Without Mercy")),

    fluidRow(
      column(2, stat_card("+30%",  "Comprehension via Structure")),
      column(2, stat_card("\u2205",      "Zero Jargon Rule")),
      column(2, stat_card("Show",  "Evidence Over Claims")),
      column(2, stat_card("All",   "Inclusive Language")),
      column(2, stat_card("\u221230%",   "Edit to Reduce")),
      column(2, stat_card("5",     "Editing Passes Minimum"))
    ),

    fluidRow(
      tabBox(id = ns("tabs"), width = 12,
        tabPanel("\U0001f4da General Concepts", br(),
          fluidRow(
            column(6,
              sh("Smart Structures"),
              framework_card("The Pyramid Structure",
                "Start with your most important point. Then support it with evidence. Then provide context. This is the opposite of how most people are taught to write \u2014 but it is how professional readers want to read. Busy decision-makers read the first paragraph and skim everything else."),
              framework_card("The Problem-Solution Structure",
                "<b>Step 1:</b> State the problem in terms the reader recognises.<br>
                 <b>Step 2:</b> Quantify the cost or consequence of not solving it.<br>
                 <b>Step 3:</b> Introduce your solution as the logical response.<br>
                 <b>Step 4:</b> Provide evidence the solution works.<br>
                 <b>Step 5:</b> State clearly what you need the reader to do."),
              sh("Modern Writing Styles"),
              framework_card("Write for the Screen, Not the Page",
                "Modern professional readers consume most writing on screens. This changes everything: shorter paragraphs (3\u20134 lines maximum), more white space, frequent subheadings, scannable structure. Test all important documents by reading them on a smartphone."),
              sh("Texture"),
              framework_card("Vary Sentence Length to Create Rhythm",
                "Mix short sentences (for impact) with longer ones (for nuance). After three or four longer sentences, a single short one lands hard. Like this."),
              sh("Inclusive Writing"),
              framework_card("Language That Includes Every Reader",
                "Gender-neutral language (\u2018they\u2019 not \u2018he/she\u2019), plain English accessible to non-native speakers, avoiding cultural assumptions or idioms that may not translate, and being conscious of technical vocabulary that excludes non-specialists.")
            ),
            column(6,
              sh("Show Not Tell \u2014 The Fundamental Rule of Persuasion"),
              framework_card("Evidence Persuades. Claims Do Not.",
                "Show the reader what is true; do not tell them what to conclude. Every claim must be supported by specific evidence \u2014 a number, a case study, a demonstration, a quote. Unsupported claims trigger scepticism. Specific evidence builds belief."),
              pull_quote("Don\u2019t tell me the moon is shining; show me the glint of light on broken glass.", "Anton Chekhov \u2014 the Show Not Tell principle"),
              sh("Lovely Layouts"),
              framework_card("Visual Hierarchy Guides the Eye",
                "Every heading should be informative enough to stand alone. Bold text should only appear on genuinely important words. White space should be generous enough to prevent cognitive overload."),
              sh("Editing \u2014 The Final Craft"),
              framework_card("A Practical Five-Pass Editing Checklist",
                "<b>Pass 1 \u2014 Structure:</b> Does the argument flow? Is the conclusion first?<br>
                 <b>Pass 2 \u2014 Sentences:</b> Is every sentence earning its place? Cut repetition.<br>
                 <b>Pass 3 \u2014 Words:</b> Replace every clich\u00e9 and passive construction.<br>
                 <b>Pass 4 \u2014 Voice:</b> Read aloud. Does it sound like a confident human?<br>
                 <b>Pass 5 \u2014 Cut:</b> Remove the bottom 30%. If the message survives, it was never needed."),
              tip_box(tags$strong("The Show-Not-Tell test: "), "Read each paragraph and ask: \u2018Have I shown evidence, or made a claim?\u2019 Every claim without evidence is a missed persuasion opportunity."),
              success_box(tags$strong("Chapter 3 Summary: "), "Structure before writing. Design for screen. Vary texture. Include every reader. Show with evidence. Then edit without mercy.")
            )
          )
        ),
        tabPanel("\U0001f3e2 Applicability on Atera Analytics", br(),
          fluidRow(
            column(6,
              shg("Smart Structures for Atera\u2019s Documents"),
              insight_box("Milestone Reports \u2014 Pyramid Structure",
                "<b>Para 1 (Conclusion first):</b> Milestone X achieved. Core outcome in 2 sentences.<br>
                 <b>Para 2 (Evidence):</b> Deliverables completed with dates and descriptions.<br>
                 <b>Para 3 (Context):</b> How this milestone connects to the overall objective.<br>
                 <b>Para 4 (Next steps):</b> What comes next, by when, with any dependencies.<br>
                 <b>Risks section:</b> Risk factors, scores, and mitigation actions."),
              insight_box("Council Pitch Decks \u2014 Problem-Solution",
                "<b>Slide 1:</b> Hook \u2014 one provocative question about AV readiness.<br>
                 <b>Slides 2\u20133:</b> Problem \u2014 what councils lack and the cost of that gap.<br>
                 <b>Slide 4:</b> Solution \u2014 what Atera\u2019s platform does, in plain English.<br>
                 <b>Slide 5:</b> Proof \u2014 Innovate UK validation, completed milestones.<br>
                 <b>Slide 6:</b> The ask \u2014 a specific, low-friction next step. Six slides. No more."),
              shg("Show Not Tell \u2014 Atera\u2019s Evidence Arsenal"),
              example_pair(
                bad_text  = "Our platform delivers impressive results and we have significant expertise in AI and GIS, making us well-positioned for market entry.",
                good_text = "Our platform scored a 4.12km Cambridge test route in real time, identifying charging points and risk zones. All 7 WP5 deliverables completed by 31 Jan 2026 (M5: \u00a328,419)."
              )
            ),
            column(6,
              shg("Inclusive Writing at Atera"),
              insight_box("Communicating Across a Diverse Stakeholder Base",
                "Atera\u2019s stakeholders range from AI specialists at Innovate UK to transport officers at local councils. Rules for inclusive technical communication:<br><br>
                 \u2022 Define every acronym on first use: CAV, CAM, GIS, ETL, API, AV<br>
                 \u2022 Never assume familiarity with AI/ML in council-facing materials<br>
                 \u2022 Include a plain-English glossary in technical reports over 10 pages<br>
                 \u2022 Use gender-neutral language throughout all communications<br>
                 \u2022 Avoid idioms that may not translate for international partners"),
              shg("Texture \u2014 Improving Atera\u2019s Writing Rhythm"),
              example_pair(
                bad_text  = "The platform, which was developed across Work Packages 3, 5 and 6 utilising Shiny, Plotly, Vertex AI and Google Cloud Platform, and which integrates route data from multiple external sources, is now fully operational.",
                good_text = "The platform is live. It integrates route data from OpenStreetMap and 50,000+ UK EV charging points. Built across three work packages using Shiny, Plotly and Google Cloud, it is ready for stakeholder demonstration."
              ),
              insight_box("Layout Standards for Atera External Documents",
                "<b>Reports:</b> Executive summary on page 1 (max half a page). Subheadings every 150\u2013200 words. One chart per key claim.<br>
                 <b>Presentations:</b> Max 1 idea per slide. Headline states the conclusion. 3 bullets maximum. Use visuals instead of more text.<br>
                 <b>Emails:</b> Subject line states the outcome or ask. 5 lines maximum for first contact. One clear call to action in the final line."),
              success_box(tags$strong("Action Points: "),
                tags$ol(
                  tags$li("Adopt Pyramid Structure as default for all milestone reports"),
                  tags$li("Create a 6-slide council pitch deck using Problem-Solution"),
                  tags$li("Build a shared evidence bank with quantified proof points"),
                  tags$li("Add a plain-English glossary to all technical reports"),
                  tags$li("Apply the 5-pass editing process to the next external document")
                ))
            )
          )
        )
      )
    )
  )
}

ch3_tricks_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
