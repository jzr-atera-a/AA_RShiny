# modules/overview.R
# Overview - "A Chance Encounter?" + Atera Analytics context

overview_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "aa-hero",
        tags$h1("Serendipity"),
        tags$h2("David Cleevely \u00b7 Cambridge University Press - Applied at Atera Analytics"),
        div(
          span(class = "hero-badge", icon("book"),      " 10 Chapters"),
          span(class = "hero-badge", icon("building"),  " Atera Analytics"),
          span(class = "hero-badge", icon("car"),       " CAV / AV Industry"),
          span(class = "hero-badge", icon("globe"),     " UK Market Entry 2026")
        )
    ),

    fluidRow(
      box(title = "\U0001f340 A Chance Encounter?", status = "primary",
          solidHeader = TRUE, width = 12,
          p("David Cleevely's central argument is deceptively simple: ",
            tags$b("serendipity is not simply luck."),
            " Fortunate discoveries and breakthroughs happen far more often to some people, teams and places ",
            "than to others - and the difference isn't chance, it's ", tags$em("conditions"), ". ",
            tags$em("Serendipity"), " sets out to ask whether those conditions - the right networks, the right ",
            "mindset, the right kind of loosely-organised environment - can be deliberately built, rather than ",
            "simply hoped for."),
          div(class = "insight-box",
              tags$h5(class = "ib-title", "The book's wager"),
              tags$p("If serendipity really is systemic rather than random, then organisations that understand ",
                     "how networks, places, mindsets and institutions either encourage or suppress lucky ",
                     "accidents can tilt the odds in their favour - without ever being able to plan the specific ",
                     "breakthrough itself.")),
          quote_block(
            "Serendipity is not about luck. It's about the conditions that make luck more likely.",
            "The central claim of Serendipity, David Cleevely"
          )
      )
    ),

    fluidRow(
      box(title = "\U0001f4d6 About This App", status = "primary",
          solidHeader = TRUE, width = 6,
          p("This interactive guide maps Cleevely's ten chapters onto the real-world context of ",
            tags$b("Atera Analytics Ltd"), " - a deep-tech company delivering AI-powered infrastructure ",
            "assessment platforms for autonomous and connected vehicles (CAV/AV), funded by Innovate UK."),
          hr(class = "divider"),
          p("Each chapter tab contains three subtabs:"),
          tags$ul(
            tags$li(tags$b("General Concepts"), " - the core theory and argument from the book"),
            tags$li(tags$b("Interactive"), " - a D3-powered graph, network, dial or self-assessment built around that chapter's idea"),
            tags$li(tags$b("Applicability on Atera Analytics"), " - what the chapter means for Atera's grant reporting, pilot partnerships and stakeholder network")
          ),
          div(class = "tip-box",
              tags$strong("\U0001f4a1 How to use: "),
              "Navigate chapters using the left sidebar. Inside each chapter, switch between the three subtabs to ",
              "move from theory, to play, to practice.")
      ),

      box(title = "\U0001f5fa\ufe0f Chapters Covered", status = "info",
          solidHeader = TRUE, width = 6,
          toc_item("1", HTML("<b>The Entangled Bank</b> - complexity, interconnectedness, and innovation as a property of systems rather than individuals")),
          toc_item("2", HTML("<b>Mad About The Moon</b> - historical breakthroughs and the improbable circumstances behind them")),
          toc_item("3", HTML("<b>How Networks Work</b> - network theory, weak ties, and the brokers who connect separate groups")),
          toc_item("4", HTML("<b>Closer To Home</b> - place, local ecosystems, and Cambridge as a case study in geographic clustering")),
          toc_item("5", HTML("<b>The Prepared Mind</b> - curiosity, experience and the individual capacity to recognise an opportunity")),
          toc_item("6", HTML("<b>Technology May Not Save Us</b> - questioning whether more data and connectivity really produce more innovation")),
          toc_item("7", HTML("<b>Too Well Organised To Adapt</b> - how efficiency and control can crowd out the capacity to seize the unexpected")),
          toc_item("8", HTML("<b>The Ministry Of Predictable Outcomes</b> - how targets and bureaucracy can suppress the uncertainty innovation needs")),
          toc_item("9", HTML("<b>The Road Most Travelled</b> - familiar paths, conventional thinking, and the case for deliberate exposure")),
          toc_item("10", HTML("<b>The Edge Of Chaos</b> - why the most fertile systems sit between complete order and complete disorder"))
      )
    ),

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
            "Atera Analytics delivers the CAM Infrastructure Assessment Platform - combining GIS, machine ",
            "learning, digital twins and AR/VR to help local authorities, logistics operators and AV companies ",
            "assess UK road readiness for autonomous vehicles. It grew out of - and still depends on - a dense, ",
            "partly accidental network of relationships: Innovate UK monitoring officers, Cambridge academic ",
            "collaborators, council pilot partners and AV operators. ", tags$em("Serendipity"),
            " gives Atera a framework for understanding which of those useful accidents can be repeated on purpose."),
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
                  tags$h5(icon("flag"), " The Serendipity Question for Atera"),
                  tags$p("Atera's biggest opportunities so far - the first council pilot, the Cambridge ",
                         "academic tie-up, the Innovate UK introduction - all began as chance conversations. ",
                         "Can that rate of useful accident be deliberately increased as the company scales?"))
            ),
            column(4,
              div(class = "framework-card",
                  tags$h5(icon("bullseye"), " What This App Delivers"),
                  tags$p("A chapter-by-chapter guide to designing Atera's networks, workspace, culture and ",
                         "reporting rhythms so that useful accidents become more likely - without pretending ",
                         "any specific breakthrough can be planned in advance."))
            )
          )
      )
    )
  )
}

overview_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
