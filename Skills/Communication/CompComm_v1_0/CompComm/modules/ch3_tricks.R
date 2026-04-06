# modules/ch3_tricks.R
# Chapter 3: The Tricks of the Writing Trade

ch3_tricks_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("Chapter 3"),
        tags$h2("The Tricks of the Writing Trade"),
        div(
          span(class = "hero-badge", icon("sitemap"),    " Smart Structures"),
          span(class = "hero-badge", icon("mobile-alt"), " Screen-First Writing"),
          span(class = "hero-badge", icon("eye"),        " Show Not Tell"),
          span(class = "hero-badge", icon("users"),      " Inclusive Writing"),
          span(class = "hero-badge", icon("cut"),        " Edit Without Mercy")
        )
    ),

    fluidRow(
      box(title = "Chapter 3 \u2014 Overview", status = "primary",
          solidHeader = TRUE, width = 12,
          p("Chapter 3 moves from principles to craft \u2014 the specific, learnable techniques that ",
            "separate professional communicators from amateur ones. Structure, layout, texture, ",
            "inclusive language, showing rather than telling, and the discipline of editing: ",
            "these are the tools that make good writing great."),
          fluidRow(
            column(2, metric_card("+30%",  "Comprehension via Structure")),
            column(2, metric_card("\u2205",      "Zero Jargon Rule")),
            column(2, metric_card("Show",  "Evidence Over Claims")),
            column(2, metric_card("All",   "Inclusive Language")),
            column(2, metric_card("\u221230%",   "Edit to Reduce by 30%")),
            column(2, metric_card("\u2713",      "Texture Aids Reading"))
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
                sh("Smart Structures"),
                concept_card("Structure Is a Service to the Reader",
                  "Good structure makes complex ideas navigable. 
                  It signals to the reader: \u2018I have thought this through and I am guiding you.\u2019 
                  The most effective structures for professional writing are: 
                  <b>Pyramid</b> (conclusion first, then evidence), 
                  <b>Problem-Solution</b> (state the challenge, then resolve it), 
                  and <b>Narrative</b> (beginning, middle, end with tension and resolution). 
                  Choose the structure before you write the first sentence."),

                concept_card("The Pyramid Structure",
                  "Start with your most important point. Then support it with evidence. 
                  Then provide context. This is the opposite of how most people are taught to write \u2014 
                  but it is how professional readers want to read. 
                  Busy decision-makers read the first paragraph and skim everything else. 
                  If your conclusion is buried in paragraph five, they will miss it entirely."),

                concept_card("The Problem-Solution Structure",
                  "<b>Step 1:</b> State the problem in terms the reader recognises and feels.<br>
                  <b>Step 2:</b> Quantify the cost or consequence of not solving it.<br>
                  <b>Step 3:</b> Introduce your solution as the logical response.<br>
                  <b>Step 4:</b> Provide evidence the solution works.<br>
                  <b>Step 5:</b> State clearly what you need the reader to do."),

                sh("Modern Writing Styles"),
                concept_card("Write for the Screen, Not the Page",
                  "Modern professional readers consume most writing on screens \u2014 
                  mobile, tablet or desktop. This changes everything: 
                  shorter paragraphs (3\u20134 lines maximum), more white space, 
                  frequent subheadings, scannable structure. 
                  A document that reads well on a printed page often fails completely on a screen. 
                  Test all important documents by reading them on a smartphone.")
              ),

              column(6,
                sh("Lovely Layouts"),
                concept_card("Visual Hierarchy Guides the Eye",
                  "Layout is not decoration \u2014 it is communication architecture. 
                  The eye moves through a page in predictable patterns: 
                  headings first, then bold words, then the first lines of paragraphs. 
                  Professional layout uses this deliberately: every heading should be 
                  informative enough to stand alone, bold text should only appear on genuinely 
                  important words, and white space should be generous enough to prevent cognitive overload."),

                sh("Texture"),
                concept_card("Vary Sentence Length to Create Rhythm",
                  "Texture in writing refers to variety \u2014 in sentence length, paragraph length, 
                  and the balance between lists and prose. Writing where every sentence is the 
                  same length becomes monotonous and loses the reader. 
                  Mix short sentences (for impact) with longer ones (for nuance). 
                  After three or four longer sentences, a single short one lands hard. Like this."),

                sh("Inclusive Writing"),
                concept_card("Language That Includes Every Reader",
                  "Inclusive writing ensures no reader feels excluded or othered by the language used. 
                  In professional contexts this means: gender-neutral language (\u2018they\u2019 not \u2018he/she\u2019), 
                  plain English accessible to non-native speakers, avoiding cultural assumptions 
                  or idioms that may not translate, and being conscious of technical vocabulary 
                  that excludes non-specialists. Inclusive writing reaches more readers and builds broader trust."),

                concept_card("Accessible Language in Technical Documents",
                  "Technical documents aimed at mixed audiences must work at multiple levels: 
                  the executive summary must be readable by non-specialists; 
                  the technical appendices can use specialist language. 
                  Never assume all readers share the writer\u2019s technical background. 
                  A document that requires a PhD to understand has failed as communication 
                  even if it succeeds as scholarship.")
              )
            ),

            hr(class = "divider"),
            fluidRow(
              column(6,
                sh("Show Not Tell \u2014 The Fundamental Rule of Persuasion"),
                concept_card("Evidence Persuades. Claims Do Not.",
                  "The most important craft rule in persuasive writing: 
                  show the reader what is true; do not tell them what to conclude. 
                  Every claim must be supported by specific evidence \u2014 
                  a number, a case study, a demonstration, a quote. 
                  Unsupported claims (\u2018we are the market leader\u2019; \u2018our platform is exceptional\u2019) 
                  trigger scepticism. Specific evidence builds belief."),

                concept_card("Show Not Sell \u2014 The Commercial Application",
                  "In commercial writing \u2014 proposals, pitches, sales emails \u2014 
                  \u2018showing not selling\u2019 means replacing superlatives with specifics: 
                  not \u2018we deliver outstanding results\u2019 but \u2018we delivered X result in Y timeframe.\u2019 
                  The reader draws the conclusion themselves. This is far more persuasive 
                  than the writer stating it, because readers trust what they have reasoned 
                  more than what they have been told."),

                div(class = "tip-box",
                    tags$strong("\U0001f4a1 The Show-Not-Tell test: "),
                    "Read each paragraph and ask: \u2018Have I shown evidence, or made a claim?\u2019 
                    Every claim without evidence is a missed persuasion opportunity.")
              ),

              column(6,
                sh("Editing \u2014 The Final Craft"),
                concept_card("First Drafts Are Not Finished Writing",
                  "Professional writers know that the first draft is only the beginning. 
                  The real work is in editing \u2014 cutting what is not essential, 
                  sharpening what remains, and restructuring where the logic has gaps. 
                  The goal: reduce every draft by at least 30% without losing any of its meaning."),

                concept_card("A Practical Editing Checklist \u2014 Five Passes",
                  "<b>Pass 1 \u2014 Structure:</b> Does the argument flow? Is the conclusion first?<br>
                  <b>Pass 2 \u2014 Sentences:</b> Is every sentence earning its place? Cut repetition.<br>
                  <b>Pass 3 \u2014 Words:</b> Replace every clich\u00e9, every passive verb where active works, 
                  every three-word phrase where one will do.<br>
                  <b>Pass 4 \u2014 Voice:</b> Read aloud. Does it sound like a confident human?<br>
                  <b>Pass 5 \u2014 Cut:</b> Remove the bottom 30%. If the message survives, it was never needed."),

                div(class = "success-box",
                    tags$strong("\u2705 Chapter 3 Summary: "),
                    "Structure before you write. Design for the screen. Vary your texture. 
                    Include every reader. Show with evidence. Then edit without mercy \u2014 five passes minimum.")
              )
            )
          ), # end General Concepts

          # ── ATERA ANALYTICS APPLICATION ──────────────
          tabPanel("\U0001f3e2 Applicability on Atera Analytics",
            br(),
            fluidRow(
              column(6,
                shg("Smart Structures for Atera\u2019s Document Types"),
                app_card("Milestone Reports \u2014 Pyramid Structure",
                  "Every Atera milestone report should follow the Pyramid:<br><br>
                  <b>Para 1 (Conclusion first):</b> Milestone X achieved. Core outcome in 2 sentences.<br>
                  <b>Para 2 (Evidence):</b> Deliverables completed with dates and brief descriptions.<br>
                  <b>Para 3 (Context):</b> How this milestone connects to the overall project objective.<br>
                  <b>Para 4 (Next steps):</b> What comes next, by when, with any dependencies.<br>
                  <b>Risks section:</b> Risk factors, scores, and mitigation actions.<br><br>
                  This structure lets a monitoring officer assess progress in 60 seconds 
                  and use the rest for supporting detail."),

                app_card("Council Pitch Decks \u2014 Problem-Solution Structure",
                  "<b>Slide 1:</b> The hook \u2014 one provocative question or statistic about AV readiness.<br>
                  <b>Slides 2\u20133:</b> The problem \u2014 what councils currently lack and the cost of that gap.<br>
                  <b>Slide 4:</b> The solution \u2014 what Atera\u2019s platform does, in plain English, with a visual.<br>
                  <b>Slide 5:</b> The proof \u2014 Innovate UK validation, milestones completed, early results.<br>
                  <b>Slide 6:</b> The ask \u2014 a specific, low-friction next step.<br><br>
                  Six slides. No more. The rest is conversation."),

                shg("Show Not Tell \u2014 Atera\u2019s Evidence Arsenal"),
                app_card("Converting Claims Into Evidence",
                  "Atera has strong evidence. The challenge is consistently using it instead of claims:<br><br>"),
                example_pair(
                  bad_text  = "Our platform delivers impressive results and we have significant 
                  expertise in AI and GIS, making us well-positioned for market entry.",
                  good_text = "Our platform scored road segments across a 4.12km Cambridge test route 
                  in real time, identifying charging point proximity and infrastructure risk zones. 
                  All 7 WP5 deliverables were completed on schedule by 31 January 2026 (M5: \u00a328,419)."
                ),

                app_card("Atera\u2019s Evidence Bank \u2014 What to Record and Use",
                  "<b>Technical:</b> Processing speeds, accuracy rates, data volumes (50,000+ EV charging points), 
                  model validation results, milestone values (M5: \u00a328,419).<br>
                  <b>Commercial:</b> \u00a32B market, target revenue split, Q2 2026 entry date, 100+ councils addressable.<br>
                  <b>Credibility:</b> IUK No. 10153306, Zenzic validation, Marks & Clerk IP roadmap, 
                  House of Lords engagement, Horizon Europe Poland collaboration.<br>
                  <b>Impact:</b> Jobs created, individuals trained, Net Zero routing contribution, 
                  \u00a3200M+ government spend better targeted.")
              ),

              column(6,
                shg("Inclusive Writing at Atera"),
                app_card("Communicating Across Atera\u2019s Diverse Stakeholder Base",
                  "Atera\u2019s stakeholders range from AI specialists at Innovate UK 
                  to transport officers at local councils and logistics managers at 
                  distribution companies \u2014 each with very different technical backgrounds.<br><br>
                  <b>Rules for inclusive technical communication:</b><br>
                  Define every acronym on first use: CAV, CAM, GIS, ETL, API, AV.<br>
                  Never assume familiarity with AI or ML concepts in council-facing materials.<br>
                  Include a plain-English glossary in all technical reports over 10 pages.<br>
                  Use gender-neutral language throughout all communications.<br>
                  Avoid idioms that may not translate for international partners \u2014 
                  e.g. \u2018hit the ground running\u2019 or \u2018move the needle\u2019."),

                shg("Texture \u2014 Improving Atera\u2019s Writing Rhythm"),
                app_card("Applying Sentence Variety to Technical Reports",
                  "Atera\u2019s technical reports tend toward long, complex sentences 
                  packed with qualifying clauses. Introducing sentence variety creates clarity and emphasis.<br><br>"),
                example_pair(
                  bad_text  = "The platform, which was developed across Work Packages 3, 5 and 6 
                  utilising Shiny, Plotly, Vertex AI and Google Cloud Platform, and which integrates 
                  route data from multiple external sources including OpenStreetMap and BigQuery-hosted 
                  EV charging infrastructure databases, is now fully operational.",
                  good_text = "The platform is live. It integrates route data from OpenStreetMap 
                  and 50,000+ UK EV charging points hosted in BigQuery. Built across three work packages 
                  using Shiny, Plotly and Google Cloud, it is fully operational and ready for 
                  stakeholder demonstration."
                ),

                shg("Editing \u2014 Atera\u2019s Document Quality Standard"),
                app_card("Layout Standards for Atera External Documents",
                  "<b>Reports:</b> Pyramid structure. Executive summary on page 1 (max half a page). 
                  Subheadings every 150\u2013200 words. One chart or table per key claim.<br><br>
                  <b>Presentations:</b> Max 1 idea per slide. Headline states the conclusion, not the topic. 
                  3 bullets maximum per slide \u2014 use visuals instead of more text.<br><br>
                  <b>Emails:</b> Subject line states the outcome or ask. 5 lines maximum for first contact. 
                  One clear call to action in the final line. No attachments in first contact emails."),

                div(class = "success-box",
                    tags$strong("\u2705 Chapter 3 Action Points for Atera: "),
                    tags$ol(
                      tags$li("Adopt the Pyramid Structure as default for all milestone reports"),
                      tags$li("Create a 6-slide council pitch deck using Problem-Solution structure"),
                      tags$li("Build a shared evidence bank with quantified proof points"),
                      tags$li("Add a plain-English glossary to all technical reports over 10 pages"),
                      tags$li("Apply the 5-pass editing process to the next external document"),
                      tags$li("Test all new documents on mobile before distribution")
                    ))
              )
            )
          ) # end Atera tab
        ) # end tabsetPanel
      ) # end box
    ) # end fluidRow
  )
}

ch3_tricks_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
  })
}
