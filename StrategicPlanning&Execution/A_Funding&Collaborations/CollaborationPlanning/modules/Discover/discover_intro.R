# ---- module ----------------------------------------------
# id:           discover_intro
# name:         How to use this app
# icon:         circle-info
# description:  What each part of the app is for and how to use it, with examples and links to each tab
# packages:     shiny
# -----------------------------------------------------------
# Static guide. Links use cpGo() from www/app.js, so they open the tab in the same way as the sidebar.
# Keep the wording here in step with the registry when tabs are added or renamed.

INTRO_GROUPS <- list(
  list(g = "discover", title = "1 Discover: find opportunities", what = "Collect funding programmes and commercial ideas in one place.",
       tabs = list(
         c("programmes_browse", "Programmes", "Every funding programme we track, with its money, dates, conditions and a link to the funder. Select one to see it in full, re-check it against the funder's page, or move it to the next stage.",
           "Example: BridgeAI Deployment Catalyst: AI for Decision Critical Systems (Innovate UK), closing 8 December 2026."),
         c("collab_ideas", "General collaboration ideas", "Ideas for paid work that does not need a grant: a pilot for a client, a joint service with a university, a product for a new market. Everyone can add notes to build on an idea.",
           "Example: an AI decision-support pilot for a regional logistics firm, paid pilot then a yearly licence."),
         c("programme_search", "Live search", "Claude searches the web for current programmes by category, country and topic, and gives the page each one came from.",
           "Example: Grant, United Kingdom, focus \"AI for energy networks, SMEs\"."),
         c("programme_bulk_import", "Bulk import", "Paste several programmes at once in the [field]: value format.", "Example: a list copied from a newsletter."),
         c("programme_add", "Add entry", "Type in one programme by hand.", "Example: a programme a partner told you about by phone."),
         c("programme_charts", "Charts and calendar", "Counts by category and stage, and a calendar of deadlines you can add to Outlook or Google Calendar (.ics).",
           "Example: see which deadlines fall before Christmas."))),
  list(g = "qualify", title = "2 Qualify: decide if it is worth it", what = "Check we can apply, and how well each programme fits us.",
       tabs = list(
         c("eligibility_check", "Eligibility check", "Claude compares each condition with our company profile: met, unclear or not met. Any \"not met\" blocks the programme from going further.",
           "Example: \"minimum consortium of an SME and a UK deployer\": unclear until we have a deployer."),
         c("team_scoring", "Team scoring", "Each person scores alignment, interest and capability from 1 to 5 and picks lead, partner, watch or pass.", "Example: alignment 5, interest 4, capability 3 = fit 80."),
         c("team_ranking", "Team ranking", "All programmes ranked by the team's average fit, with a button to start the bid decision.", ""),
         c("go_no_go", "Go/no-go tree", "Is a bid worth the cost of writing it? Enter the cost, the chance of winning and the value.",
           "Example: GBP 6,000 to write, 25% chance, GBP 150,000 grant: expected value GBP 31,500, so bid."))),
  list(g = "teamup", title = "3 Team up: find and manage partners", what = "Build the consortium for each bid.",
       tabs = list(
         c("collaborators", "Collaborators", "Contacts and partners. Upload a CV or signature and Claude fills in the details.", ""),
         c("partner_match", "Partner match", "Ranks people by how well their interests and past projects fit a programme.", ""),
         c("outreach", "Outreach", "Claude drafts an email or LinkedIn message for a person and a bid; send it with a meeting invitation.", "Example: ask a deployer for a letter of support by 1 December."),
         c("inbox", "Process emails", "Paste a partner's reply: Claude finds who it is, which bid, whether they said yes, and what they sent.", ""),
         c("consortium", "Consortium", "Who is in each bid, their role, their share of the budget and the documents they still owe.", ""))),
  list(g = "decide", title = "4 Decide: decide in writing", what = "Most decisions are made in writing, in your own time.",
       tabs = list(
         c("decisions", "Decisions", "A question with options, a Driver and an Approver. Everyone adds support, concern or objection by the deadline.", "Example: Bid for BridgeAI, Go or No go?"),
         c("decision_log", "Decision log", "Every decision made, with the reason.", ""),
         c("ideas", "Ideas", "Quick ideas for a bid, with votes.", ""),
         c("meet_by_exception", "Meet by exception", "Lists only what needs a meeting: objections, split views, blockers, missed milestones.", ""))),
  list(g = "plan", title = "5 Plan: plan the project", what = "A Go decision creates a project here.",
       tabs = list(
         c("work_packages", "Work packages and Gantt", "Tasks by work package on a timeline (from a template or an Excel file).", ""),
         c("raci", "RACI", "Who is Responsible, Accountable, Consulted and Informed for each task.", ""),
         c("risk_register", "Risk register", "Risks scored likelihood x impact; Claude can suggest some.", ""),
         c("budget", "Budget by partner", "Costs by partner and category, checked against the programme's maximum.", ""))),
  list(g = "write", title = "6 Write: write the application", what = "Answer each question within its word limit.",
       tabs = list(
         c("section_drafts", "Section drafts", "One box per question with a live word count; Claude drafts from everything the app knows about the bid.", ""),
         c("question_sets", "Question sets", "The questions and word limits for each funder (three examples included).", ""),
         c("canvases_diagrams", "Canvases and diagrams", "Business model canvas, logic model and a project diagram.", ""),
         c("submit_checklist", "Submit checklist", "Answers within limits, budget, partner documents, eligibility and deadline, all checked before you submit.", ""))),
  list(g = "deliver", title = "7 Deliver: run the work", what = "Once a bid is won.",
       tabs = list(
         c("trello_board", "Trello board", "Sends the tasks to Trello and brings their status back.", ""),
         c("weekly_updates", "Weekly updates", "Done, next and blocked, once a week. A blocker raises a flag on Home.", ""),
         c("milestones", "Milestones and claims", "Milestones and grant claim dates; a missed one opens a decision.", ""),
         c("reminders", "Reminders", "Emails people about tasks, milestones and decisions coming up.", ""))),
  list(g = "learn", title = "8 Learn: get better at winning", what = "Record every result.",
       tabs = list(
         c("outcomes", "Outcomes and lessons", "Won, lost, withdrawn or not pursued, with the funder's feedback and our lessons.", ""),
         c("win_rate", "Win rate", "Win rate by funder, category and theme, and whether our fit score predicts wins.", ""))),
  list(g = "suggest", title = "Suggestions: ideas from anyone", what = "Anyone can suggest a programme or an idea; the owner has Claude analyse it.",
       tabs = list(
         c("my_suggestions", "My suggestions", "Suggest a programme or an idea with a description, a link and your ideas. Only you and the owner see it.", ""),
         c("analysis_library", "Analysis library", "Claude's analyses as tables, filed by country, category, topic and programme. You see the ones shared with you.",
           "Example: the BridgeAI analysis, shared with everyone."))))

discover_intro_ui <- function(id) {
  ns <- NS(id)
  link <- function(g, s, label) tags$a(href = "#", onclick = sprintf("cpGo('%s','%s'); return false;", g, s), label)
  tagList(
    div(class = "intro-hero",
      h3("Welcome to Collaboration Planning"),
      p("This app takes a funding programme or a commercial idea from the first find to a delivered project, in eight steps. ",
        "Work moves left to right on the ", link("home", "home_board", "Home board"), ": Discover, Qualify, Team up, Decide, Plan, Write, Deliver, Learn."),
      p(class = "small", tags$b("Examples are loaded"), " so you can see what good entries look like: two open Innovate UK AI competitions in ",
        link("discover", "programmes_browse", "Programmes"), ", three commercial ideas in ", link("discover", "collab_ideas", "General collaboration ideas"),
        ", and a Claude analysis in ", link("suggest", "analysis_library", "Analysis library"), ". They carry an ", example_badge(), " label; you can delete them.")),
    card("A typical journey, with a real example",
      tags$ol(class = "journey",
        tags$li(tags$b("Find it. "), "Open ", link("discover", "programmes_browse", "Programmes"), " and select ",
                tags$i("BridgeAI Deployment Catalyst: AI for Decision Critical Systems"), ". It offers GBP 100,000 to 200,000 per project and closes on 8 December 2026 at 11am."),
        tags$li(tags$b("Check we can apply. "), "In ", link("qualify", "eligibility_check", "Eligibility check"),
                ", Claude splits its conditions (UK SME lead, an existing AI product at TRL 5 or 6, a UK deployer as partner) and checks each one against our profile."),
        tags$li(tags$b("Score the fit. "), "Each person scores it in ", link("qualify", "team_scoring", "Team scoring"), "; ",
                link("qualify", "go_no_go", "Go/no-go tree"), " shows whether the bid is worth its cost."),
        tags$li(tags$b("Find the deployer. "), link("teamup", "partner_match", "Partner match"), " suggests contacts; ",
                link("teamup", "outreach", "Outreach"), " drafts the email; ", link("teamup", "consortium", "Consortium"), " tracks who said yes."),
        tags$li(tags$b("Decide. "), "Press \"Decide whether to bid\" on Home. Everyone weighs in by the deadline in ", link("decide", "decisions", "Decisions"),
                "; recording Go creates the project."),
        tags$li(tags$b("Plan and write. "), "Work packages, RACI, risks and budget in 5 Plan; answers within word limits in ", link("write", "section_drafts", "Section drafts"),
                "; then the ", link("write", "submit_checklist", "Submit checklist"), "."),
        tags$li(tags$b("Deliver and learn. "), "If we win, tasks go to Trello and the team writes weekly updates; whatever the result, record it in ",
                link("learn", "outcomes", "Outcomes and lessons"), ".")),
      p(class = "small muted", "Not every idea needs a grant: for paid work with a client, start in ",
        link("discover", "collab_ideas", "General collaboration ideas"), " instead.")),
    card("What each part is for",
      lapply(INTRO_GROUPS, function(gr) div(class = "intro-group",
        h5(gr$title), p(class = "small muted", gr$what),
        tags$table(class = "qs-table intro-table", tags$tbody(lapply(gr$tabs, function(t) tags$tr(
          tags$td(style = "width:210px", link(gr$g, t[1], t[2])),
          tags$td(t[3], if (nzchar(t[4])) div(class = "small muted", t[4]))))))))),
    layout_columns(col_widths = c(6, 6),
      card("Who can do what",
        tags$table(class = "kv",
          tags$tr(tags$th("Owner"), tags$td("Sees everything, including Admin (settings, users, tab setup, usage analytics, Google Drive) and the Claude analysis workbench.")),
          tags$tr(tags$th("Members"), tags$td("The team: every stage, their own suggestions, and the analyses shared with them.")),
          tags$tr(tags$th("Partners"), tags$td("Outside collaborators: only the bids they are part of. They can add their view to decisions and update their consortium entry.")))),
      card("Tips",
        tags$ul(
          tags$li("Use the ", icon("bars"), " button at the top left to hide the menu; the arrows next to each group fold its tabs."),
          tags$li("Dates are written YYYY-MM-DD, for example 2026-12-08."),
          tags$li("Anything from Claude is a draft: check it against the funder's own page before you rely on it."),
          tags$li("Nothing you type is lost by the automatic refresh, but press Save before you leave a tab.")))))
}

discover_intro_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) invisible(NULL))
}
