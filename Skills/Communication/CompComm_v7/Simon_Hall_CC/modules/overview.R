# modules/overview.R
# Overview Tab - Compelling Communication @ Atera Analytics

overview_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # ── Hero Banner ──────────────────────────────────
    div(class = "aa-hero",
        tags$h1("Compelling Communication"),
        tags$h2("Simon Hall \u00b7 Cambridge University Press - Applied at Atera Analytics"),
        div(
          span(class = "hero-badge", icon("book"),      " 10 Chapters"),
          span(class = "hero-badge", icon("building"),  " Atera Analytics"),
          span(class = "hero-badge", icon("car"),       " CAV / AV Industry"),
          span(class = "hero-badge", icon("globe"),     " UK Market Entry 2026")
        )
    ),

    # ── About + Chapters ─────────────────────────────
    fluidRow(
      box(title = "\U0001f4d6 About This App", status = "primary",
          solidHeader = TRUE, width = 6,
          p("This interactive guide maps the communication frameworks from ",
            tags$em("Compelling Communication"), " by Simon Hall (Cambridge University Press) ",
            "directly to the context of ", tags$b("Atera Analytics Ltd"), " - ",
            "a deep-tech company delivering AI-powered infrastructure assessment platforms ",
            "for autonomous and connected vehicles (CAV/AV), funded by Innovate UK."),
          hr(class = "divider"),
          p("Each chapter tab contains two subtabs:"),
          tags$ul(
            tags$li(tags$b("General Concepts"),
                    " - the core communication theory and principles from the book"),
            tags$li(tags$b("Applicability on Atera Analytics"),
                    " - direct application to Atera\u2019s stakeholder communications, ",
                    "pitch materials, milestone reports and partner conversations")
          ),
          div(class = "tip-box",
              tags$strong("\U0001f4a1 How to use: "),
              "Navigate chapters using the left sidebar. Inside each chapter, ",
              "switch between the two subtabs to move from theory to practice.")
      ),

      box(title = "\U0001f5fa\ufe0f Chapters Covered", status = "info",
          solidHeader = TRUE, width = 6,
          toc_item("1", HTML("<b>Foundations of Effective Communication</b> - Clarity of Story, the Golden Thread, KISS, audience audit, voice, style and the power of surprise")),
          toc_item("2", HTML("<b>Writing to Woo and Wow</b> - Striking starts, memorable messages, the Rule of Threes, counterpoint, analogy, clich\u00e9s and triumphant titles")),
          toc_item("3", HTML("<b>The Tricks of the Writing Trade</b> - Smart structures, modern styles, inclusive writing, show not tell, texture and editing for impact")),
          toc_item("4", HTML("<b>The Splendour of Storytelling</b> - The power of story, ingredients, three-act structure, pace, jeopardy and character")),
          toc_item("5", HTML("<b>Strategic Stories (Storytelling II)</b> - Story bank, stages of a successful story, persuasion, Pat the Dog, gold standard storytelling")),
          toc_item("6", HTML("<b>Public Speaking, Presenting and Performing</b> - The elevator pitch, slides, data, the killer fact and lifesaver preparation")),
          toc_item("7", HTML("<b>Powerful Public Speaking and Presentations</b> - Interactions, signposting, magic moments, body language, nerves, online presenting and Q&amp;A")),
          toc_item("8\u201310", HTML("<em>Coming soon:</em> The Online World \u00b7 Mixing It with the Media \u00b7 Strategic Communication"))
      )
    ),

    # ── Atera Context ─────────────────────────────────
    fluidRow(
      box(title = "\U0001f3e2 Atera Analytics - Project Context", status = "success",
          solidHeader = TRUE, width = 12,
          fluidRow(
            column(3, metric_card("\u00a32B",     "UK Smart Mobility Market")),
            column(3, metric_card("7",        "Work Packages Delivered")),
            column(3, metric_card("Q2 \u201926", "Target Market Entry")),
            column(3, metric_card("100+",     "UK Councils Addressable"))
          ),
          br(),
          p(style = "color:#555; font-size:14px;",
            "Atera Analytics is delivering the CAM Infrastructure Assessment Platform - ",
            "combining GIS, machine learning, digital twins, and AR/VR to help local authorities, ",
            "logistics operators and AV companies assess UK road infrastructure readiness for ",
            "autonomous vehicles. The platform targets UK government (40%), AV operators (30%), ",
            "infrastructure developers (20%) and international markets (10%). ",
            "Communication excellence is critical at every stage: from Innovate UK milestone ",
            "reporting to council presentations and investor pitches."),
          fluidRow(
            column(4,
              div(class = "framework-card",
                  tags$h5(icon("users"), " Key Stakeholders"),
                  tags$p("Innovate UK / Zenzic monitoring officers, UK local authorities and councils, ",
                         "AV operators and logistics companies, infrastructure investors and VC funds, ",
                         "academic partners (Cambridge, Oxford, Sydney), and international collaborators ",
                         "(Horizon Europe, Poland programme)."))
            ),
            column(4,
              div(class = "framework-card",
                  tags$h5(icon("flag"), " Communication Challenges"),
                  tags$p("Translating complex AI/ML concepts to non-technical audiences, ",
                         "demonstrating ROI to risk-averse public sector partners, ",
                         "building credibility with government funders, and competing for ",
                         "attention in the crowded UK smart mobility space."))
            ),
            column(4,
              div(class = "framework-card",
                  tags$h5(icon("bullseye"), " What This App Delivers"),
                  tags$p("A structured guide to improving every type of Atera communication - ",
                         "milestone reports, investor pitches, council presentations, partner emails, ",
                         "LinkedIn content and media responses - using proven frameworks from ",
                         "one of the UK\u2019s leading communication textbooks."))
            )
          )
      )
    )
  )
}

overview_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
    # Informational overview - no reactive logic required
  })
}
