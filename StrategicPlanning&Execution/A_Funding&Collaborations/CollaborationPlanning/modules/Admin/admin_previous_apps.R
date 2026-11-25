# ---- module ----------------------------------------------
# id:           admin_previous_apps
# name:         Previous apps
# icon:         clock-rotate-left
# description:  The earlier apps this one grew from, what each gave it, and where they still run
# packages:     shiny
# -----------------------------------------------------------

PREVIOUS_APPS <- list(
  list(name = "Funding Programmes Suite", url = "https://atera-analytics.shinyapps.io/funding_programmes/",
       what = "Standalone app that asks Claude to find grants, incubators, accelerators and competitions by category, country and region, and saves them to the BigQuery table funding_programmes.",
       gave = "The programme fields (conditions, sponsors, organisers, tips, links), bulk import and the filtered charts. Becomes 1 Discover, with live web search added so dates and amounts are checked at source.",
       stages = "1 Discover"),
  list(name = "Grant Compass", url = "",
       what = "Collaborative app for a team to review grants, score how well each fits (alignment, interest, capability), vote on ideas, and decide in writing in the Collaboration Lab.",
       gave = "The look (navy and teal), email allow-list sign-in, fit scoring and stances, ideas, decisions with Driver and Approver, the decision log, weekly updates and meet by exception.",
       stages = "2 Qualify, 4 Decide, 7 Deliver (weekly updates)"),
  list(name = "Business Operations Suite", url = "",
       what = "Modular app with many tab groups: Communications, Funding Programmes, Project Application, Strategy Canvases, Gantt to Tickets, Audio Transcription, Receipt Processor and Visual Media.",
       gave = "The code layout (one file per sub-tab, a registry, tables loaded only when needed), contacts and outreach, application sections with word limits, canvases, and sending a Gantt to Trello.",
       stages = "3 Team up, 5 Plan, 6 Write, 7 Deliver"),
  list(name = "BooksNetworks StrategySixS", url = "",
       what = "Large modular app for book summaries, knowledge graphs, Sankey diagrams, strategy frameworks, Six Sigma tools and technical designs.",
       gave = "Decision trees with expected value (for go/no-go), RACI, FMEA and risk tables, stakeholder analysis, and the lessons in the Modular RShiny improvement guide (safe SQL escaping, sourcing once).",
       stages = "2 Qualify (go/no-go), 5 Plan"),
  list(name = "VentureDeals", url = "https://atera-analytics.shinyapps.io/venturedeals/",
       what = "DeepTech fundraising suite with sign-in for invited partners.",
       gave = "The sign-in pattern: approved emails in a Google Sheet tab with roles, five attempts then a lock, every sign-in logged, and Google Sheets reached through a service account without extra packages.",
       stages = "Sign-in and Admin > Users and access"),
  list(name = "DaysPlanningFundingTravel", url = "",
       what = "Day planner suite with Contact Manager, Gantt to Tickets, events, travel and funding tabs, and Titan mail and calendar.",
       gave = "The newer email code: sending over SMTP with curl (attachments, calendar invitations with Yes / No / Maybe, retrying one recipient at a time), contact extraction from documents, and the Trello submission flow.",
       stages = "3 Team up (outreach, process emails), 4 Decide (meeting invitations), 7 Deliver (reminders, Trello)")
)

admin_previous_apps_ui <- function(id) {
  tagList(
    p(class = "lead", "Collaboration Planning was built from five earlier apps. They are not retired: each still runs on its own ",
      "and keeps its own data. This app took the parts that serve one job, choosing funding, teaming up and delivering, ",
      "and joined them around a single programme record."),
    div(class = "prev-grid", lapply(PREVIOUS_APPS, function(a) {
      card(a$name,
        p(a$what),
        p(tags$b("What it gave this app: "), a$gave),
        p(class = "small", tags$b("Used in: "), a$stages),
        if (nzchar(a$url)) tags$a(href = a$url, target = "_blank", rel = "noopener", class = "link-chip", icon("arrow-up-right-from-square"), " Open the app"),
        class = "prev-card")
    })),
    card("What stays in the older apps",
      p("Audio Transcription, Receipt Processor, Visual Media, Book Summary, Mind Map, Knowledge Graph, Sankey and the Six Sigma learning tabs ",
        "are not about funding, so they stay where they are.")))
}

admin_previous_apps_server <- function(id, ctx) moduleServer(id, function(input, output, session) {})
