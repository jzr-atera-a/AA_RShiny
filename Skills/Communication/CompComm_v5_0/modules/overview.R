# modules/overview.R

overview_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero("", "Compelling Communication",
      "Simon Hall \u00b7 Cambridge University Press \u2014 Applied at Atera Analytics",
      c("10 Chapters", "Writing", "Public Speaking", "Storytelling", "Strategy")
    ),

    fluidRow(
      column(3, stat_card("\u00a32B",   "UK Smart Mobility Market")),
      column(3, stat_card("10",     "Book Chapters Covered")),
      column(3, stat_card("Q2 '26", "Atera Market Entry")),
      column(3, stat_card("100+",   "UK Councils Addressable"))
    ),

    fluidRow(
      box(title = "About This App", status = "primary", solidHeader = TRUE, width = 6,
        tags$p("This interactive guide maps the communication frameworks from ",
          tags$em("Compelling Communication"), " by Simon Hall (Cambridge University Press) ",
          "to the real-world context of ", tags$strong("Atera Analytics Ltd"), " \u2014 ",
          "a deep-tech company delivering AI-powered infrastructure assessment platforms ",
          "for autonomous and connected vehicles (CAV/AV), funded by Innovate UK."),
        tags$hr(),
        tags$p("Each chapter tab contains two views:"),
        tags$ul(
          tags$li(tags$strong("General Concepts"), " \u2014 the core communication theory from the book"),
          tags$li(tags$strong("Applicability on Atera Analytics"), " \u2014 direct application to Atera\u2019s reports, pitches and partnerships")
        ),
        tip_box(tags$strong("How to use: "), "Navigate chapters via the left sidebar. Switch between the two subtabs to move from theory to practice.")
      ),
      box(title = "Chapters Covered", status = "info", solidHeader = TRUE, width = 6,
        chapter_card("1", "Foundations of Effective Communication",
          "Golden Thread, KISS, audience audit, voice, style and the power of surprise.",
          c("Golden Thread", "KISS", "Audience", "Voice")),
        chapter_card("2", "Writing to Woo and Wow",
          "Striking starts, Rule of Threes, analogy, counterpoint and triumphant titles.",
          c("Openings", "Rule of 3", "Analogy", "Titles")),
        chapter_card("3", "The Tricks of the Writing Trade",
          "Smart structures, show not tell, inclusive writing and editing for impact.",
          c("Pyramid", "Show Not Tell", "Editing")),
        chapter_card("4\u201310", "Storytelling, Speaking, Online, Media & Strategy",
          "Complete framework from narrative to crisis communication.",
          c("Story", "Presenting", "Media", "Crisis"))
      )
    ),

    fluidRow(
      box(title = "Atera Analytics \u2014 Project Context", status = "success", solidHeader = TRUE, width = 12,
        tags$p(style="font-size:13px;color:#2c3e50;",
          "Atera Analytics is delivering the CAM Infrastructure Assessment Platform \u2014 combining GIS, machine learning, digital twins and AR/VR to help local authorities, logistics operators and AV companies assess UK road infrastructure readiness for autonomous vehicles. The platform targets UK government (40%), AV operators (30%), infrastructure developers (20%) and international markets (10%). Communication excellence is critical at every stage: from Innovate UK milestone reporting to council presentations and investor pitches."),
        fluidRow(
          column(4,
            div(class="framework-card",
              tags$h5(icon("users"), " Key Stakeholders"),
              tags$p("Innovate UK/Zenzic monitoring officers, UK local authorities, AV operators, logistics companies, investors, academic partners and international collaborators (Horizon Europe)."))),
          column(4,
            div(class="framework-card",
              tags$h5(icon("flag"), " Communication Challenges"),
              tags$p("Translating complex AI/ML to non-technical audiences, demonstrating ROI to risk-averse public sector partners, building credibility with government funders."))),
          column(4,
            div(class="framework-card",
              tags$h5(icon("bullseye"), " What This App Delivers"),
              tags$p("A structured guide improving every Atera communication \u2014 milestone reports, investor pitches, council presentations, partner emails, LinkedIn content and media responses.")))
        )
      )
    )
  )
}

overview_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
