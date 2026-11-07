# R/utils_techdesign_social_handbook.R
# ============================================================
# Social Dynamics Handbook: scenarios + Harvard-style references for the 36 algorithms.
# All text is written in plain words (no quotations). References were typed from memory of the
# standard editions: check edition, publisher and year against your own copy before academic use.
# ============================================================

SOC_REFS <- list(
  berne = list(cite = "Berne, 1964", full = "Berne, E. (1964) Games People Play: The Psychology of Human Relationships. New York: Grove Press."),
  carnegie = list(cite = "Carnegie, 1936", full = "Carnegie, D. (1936) How to Win Friends and Influence People. New York: Simon and Schuster."),
  cial = list(cite = "Cialdini, 2021", full = "Cialdini, R.B. (2021) Influence, New and Expanded: The Psychology of Persuasion. New York: Harper Business."),
  presu = list(cite = "Cialdini, 2016", full = "Cialdini, R.B. (2016) Pre-Suasion: A Revolutionary Way to Influence and Persuade. New York: Simon and Schuster."),
  gty = list(cite = "Fisher, Ury and Patton, 2011", full = "Fisher, R., Ury, W. and Patton, B. (2011) Getting to Yes: Negotiating Agreement Without Giving In. 3rd edn. New York: Penguin."),
  duke = list(cite = "Duke, 2018", full = "Duke, A. (2018) Thinking in Bets: Making Smarter Decisions When You Don't Have All the Facts. New York: Portfolio."),
  atlb = list(cite = "Christian and Griffiths, 2016", full = "Christian, B. and Griffiths, T. (2016) Algorithms to Live By: The Computer Science of Human Decisions. New York: Henry Holt."),
  axel = list(cite = "Axelrod, 1984", full = "Axelrod, R. (1984) The Evolution of Cooperation. New York: Basic Books."),
  kasp = list(cite = "Kasparov, 2007", full = "Kasparov, G. (2007) How Life Imitates Chess. London: Heinemann."),
  ve = list(cite = "Van Edwards, 2017", full = "Van Edwards, V. (2017) Captivate: The Science of Succeeding with People. New York: Portfolio."),
  tom = list(cite = "Tomassi, 2013", full = "Tomassi, R. (2013) The Rational Male. Scotts Valley, CA: CreateSpace."),
  strauss = list(cite = "Strauss, 2005", full = "Strauss, N. (2005) The Game: Penetrating the Secret Society of Pickup Artists. New York: ReganBooks."),
  thiel = list(cite = "Thiel and Masters, 2014", full = "Thiel, P. and Masters, B. (2014) Zero to One: Notes on Startups, or How to Build the Future. New York: Crown Business."),
  ries = list(cite = "Ries, 2011", full = "Ries, E. (2011) The Lean Startup: How Today's Entrepreneurs Use Continuous Innovation to Create Radically Successful Businesses. New York: Crown Business."),
  limitless = list(cite = "Burger, 2011", full = "Burger, N. (dir.) (2011) Limitless [Film]. Los Angeles: Relativity Media."),
  elem = list(cite = "Doherty, 2012-2019", full = "Doherty, R. (creator) (2012-2019) Elementary [Television series]. New York: CBS.")
)

# id -> refs, scenarios (by audience letter), combines-with
SOC_HB <- list(
  reciprocity_loop = list(refs = "cial", combo = c("liking_engine", "commitment_ladder"), sc = c(
    I = "You need a senior colleague to back your proposal. Two weeks earlier you send them a report that helps their own project, with no request attached. Later you ask for ten minutes; if they decline, you ask for a single introduction instead.",
    V = "Before a raise you send an investor a short market teardown and an introduction to a customer. When you later ask for a meeting, the first conversation starts warm and specific.",
    B = "A supplier gives you a free pilot week. You return a structured review within days, which sets a fair, cooperative tone for the volume discussion.")),
  commitment_ladder = list(refs = "cial", combo = c("reciprocity_loop", "traction_proof_ladder"), sc = c(
    B = "A prospective partner will not sign a contract. You agree a two-week joint pilot with written success metrics, then a scoped paid project, then the framework deal.",
    V = "An investor takes an intro call, then asks for your metrics, then joins a second meeting with their partner, then discusses terms. Each step is small and consistent with the previous one.")),
  social_proof_calibration = list(refs = "cial", combo = c("authority_signal", "honest_scarcity"), sc = c(
    B = "A hospital group hesitates over your software. You show two real, comparable hospital groups that adopted it, with their measured results and permission to call them.",
    V = "In a pitch you name two credible angel investors who have already committed, with their agreement to be named, and a customer reference.")),
  liking_engine = list(refs = c("cial", "carnegie"), combo = c("carnegie_interest_loop", "unity_identity"), sc = c(
    I = "Before asking a neighbour to support a street project you find a real shared interest (gardening), give a specific compliment about their garden and work on a small task together.",
    R = "On a first date you look for real overlap in what you both enjoy and give a sincere, specific appreciation, rather than rehearsed lines.",
    C = "You start a joint project by pairing with a new collaborator on a small task, so working together builds liking before the harder decisions.")),
  authority_signal = list(refs = "cial", combo = c("social_proof_calibration", "liking_engine"), sc = c(
    B = "In a consulting pitch you open with one relevant result and the number behind it, name one limit of your approach, then give a clear recommendation.",
    V = "A founder shows a track record in the sector, states the biggest risk herself, then asks the investor to test the claims.")),
  honest_scarcity = list(refs = "cial", combo = c("fundraise_competitive_tension", "social_proof_calibration"), sc = c(
    B = "A consultant truly has two project slots left this quarter and says so, with the reason, and what a later start would delay.",
    V = "A founder states a real closing date for the round and the true size of the allocation, and holds to it.")),
  unity_identity = list(refs = "cial", combo = c("liking_engine", "stroke_economy"), sc = c(
    C = "A new team writes a short mission and shared norms together, uses we language and ends each sprint with a shared ritual.",
    R = "A couple builds shared stories and rituals, such as a regular trip or project, so the relationship has its own we identity.")),
  carnegie_interest_loop = list(refs = "carnegie", combo = c("liking_engine", "captivate_warmth_competence"), sc = c(
    I = "At a conference you ask a stranger what they are working on, remember their name and one detail, and follow up later with an article on that detail.",
    V = "Before pitching you read what an investor has backed and why, then start by asking what they look for in a founder.")),
  arouse_want = list(refs = "carnegie", combo = c("interests_not_positions", "options_mutual_gain"), sc = c(
    B = "You want a distributor to stock your product. You first learn that their problem is returns, so you open with your lower return rate and then the margin.",
    C = "To recruit a collaborator you ask what they want to learn this year and show how the project provides it.")),
  save_face_disagree = list(refs = "carnegie", combo = c("ego_state_match", "separate_people_problem"), sc = c(
    B = "A partner has quoted a wrong figure in a meeting. You say you may have misunderstood, check the source together, and let them present the correction.",
    R = "After an argument you start by owning your part, say what you agree on, and then ask a question about what they need.")),
  ego_state_match = list(refs = "berne", combo = c("game_formula_exit", "save_face_disagree"), sc = c(
    B = "A client speaks like a critical parent about a delay. You answer as an adult with facts, options and a date, rather than defending like an anxious child.",
    R = "A partner says you never help, a parental accusation. You reply as an adult: you ask which tasks matter most this week and propose a split.")),
  game_formula_exit = list(refs = "berne", combo = c("ego_state_match", "stroke_economy"), sc = c(
    C = "In a team a member always asks for help and then rejects every suggestion. You stop offering solutions and ask what they will try first.",
    R = "Every conflict ends with one person feeling guilty. You name the pattern kindly at a calm time and agree a different first response.")),
  stroke_economy = list(refs = "berne", combo = c("unity_identity", "carnegie_interest_loop"), sc = c(
    C = "A distributed team adds a weekly slot where members thank each other for specific contributions.",
    R = "You tell your partner specifically what you appreciated that week, and ask for the recognition you need.")),
  holmes_observation_read = list(refs = "elem", combo = c("limitless_prep_loop", "captivate_warmth_competence"), sc = c(
    V = "In a pitch you notice which slide the investor returns to and which questions they ask, form a hypothesis about their worry, and test it with a question.",
    B = "In a first meeting you notice who the others look at before answering and check, gently, who the real decision maker is.")),
  limitless_prep_loop = list(refs = c("limitless", "presu"), combo = c("holmes_observation_read", "investor_fit_warm_intro"), sc = c(
    V = "You study the fund's thesis, last five deals and partner's public talks, then open with the shared theme that appears in all of them.",
    B = "Before a negotiation you learn the other firm's quarter pressures from public filings and plan a first topic that is in their interest.")),
  separate_people_problem = list(refs = "gty", combo = c("ego_state_match", "interests_not_positions"), sc = c(
    B = "A supplier is angry about late payment. You acknowledge the frustration, restate their point, and then work on the cash-flow problem together.",
    C = "Two co-founders disagree about priorities. They write the problem on a page and each attacks the page, not the other person.")),
  interests_not_positions = list(refs = "gty", combo = c("options_mutual_gain", "arouse_want"), sc = c(
    V = "An investor demands a board seat. Asking why reveals they want visibility of risks, so you offer monthly reporting and an observer seat.",
    B = "A buyer insists on a lower price. Asking why shows their budget is annual; you agree a phased price that fits their cycle.")),
  options_mutual_gain = list(refs = "gty", combo = c("interests_not_positions", "objective_criteria"), sc = c(
    V = "You brainstorm term options: tranches tied to milestones, an option pool top-up, information rights. You then pick a package that costs you little and gives the investor comfort.",
    C = "Two collaborators split the work by strengths and swap tasks each values differently.")),
  objective_criteria = list(refs = "gty", combo = c("options_mutual_gain", "batna_walkaway"), sc = c(
    V = "On valuation you agree to look at comparable rounds and a neutral data source before arguing about numbers.",
    B = "A fee dispute is settled by referring to published market rates for similar work.")),
  batna_walkaway = list(refs = "gty", combo = c("fundraise_competitive_tension", "objective_criteria"), sc = c(
    V = "Before a lead term sheet you line up two other conversations and a smaller angel round, and set the lowest terms you would accept.",
    B = "You find a second supplier before renegotiating, which lets you stay calm and walk away if needed.")),
  decision_journal_resulting = list(refs = "duke", combo = c("bet_expected_value", "postmortem_centaur"), sc = c(
    V = "At investment you write the thesis, the odds of success and what would change your mind. At exit you grade the process, separating luck from skill.",
    C = "A team records the reasoning of each key decision, and reviews it when the outcome is known.")),
  bet_expected_value = list(refs = "duke", combo = c("decision_journal_resulting", "premortem_backcast"), sc = c(
    V = "You size a position by listing three outcomes with probabilities and payoffs, and check that the downside is survivable.",
    B = "You compare two partnership options by scenarios and the cost of being wrong.")),
  premortem_backcast = list(refs = "duke", combo = c("truthseeking_pact", "bet_expected_value"), sc = c(
    V = "Before closing a deal each partner writes why it failed a year later, independently, and the group ranks the reasons.",
    C = "At kickoff a project team lists how the project could fall apart and agrees tripwires.")),
  truthseeking_pact = list(refs = "duke", combo = c("premortem_backcast", "postmortem_centaur"), sc = c(
    C = "Collaborators agree to reward whoever finds a flaw in the plan, and to review decisions without blame.",
    V = "An investment committee appoints a rotating devil's advocate for each deal.")),
  optimal_stopping_37 = list(refs = "atlb", combo = c("explore_exploit", "batna_walkaway"), sc = c(
    B = "To choose among about twenty vendors who respond one at a time, you look at the first seven or eight without committing, then pick the first one better than all of those.",
    R = "As a framework only: you decide how long you will explore before committing, so the search does not go on forever. It is not a rule about people.")),
  explore_exploit = list(refs = "atlb", combo = c("optimal_stopping_37", "tit_for_tat"), sc = c(
    B = "You keep most business with the best partners but reserve a fixed share for trying new ones.",
    V = "A fund keeps a part of its capital for new, uncertain bets.")),
  tit_for_tat = list(refs = c("axel", "atlb"), combo = c("reciprocity_loop", "truthseeking_pact"), sc = c(
    B = "You honour terms first, respond in kind once if the other side breaches, then return to cooperation if they do.",
    C = "In a shared repository you contribute first, match their effort and forgive one lapse.")),
  kasparov_dynamic_eval = list(refs = "kasp", combo = c("bet_expected_value", "postmortem_centaur"), sc = c(
    B = "A competitor is faster. You judge your resources, time and quality of position, and decide to give up a minor market to gain time for a key launch.",
    V = "A deal is contested; you decide whether speed is worth a higher price after calculating the downside.")),
  postmortem_centaur = list(refs = "kasp", combo = c("decision_journal_resulting", "truthseeking_pact"), sc = c(
    V = "After an exit you analyse the decision points with data and an experienced colleague, then write one rule for next time.",
    C = "After a project the team holds a blameless review and turns findings into a checklist.")),
  captivate_warmth_competence = list(refs = "ve", combo = c("carnegie_interest_loop", "liking_engine"), sc = c(
    R = "On a first date you open with a question that invites a story, listen, and show warmth first, then competence in what you share.",
    V = "In a pitch you open warmly, ask what the investor is excited about, and show competence with specific results.")),
  game_attraction_funnel = list(refs = "strauss", combo = c("captivate_warmth_competence", "tomassi_frame_audit"), sc = c(
    R = "At a social event you approach openly, hold an honest conversation, move at their comfort level, say clearly that you would like to meet again, and accept either answer.")),
  tomassi_frame_audit = list(refs = "tom", combo = c("game_attraction_funnel", "captivate_warmth_competence"), sc = c(
    R = "You audit your health, skills, finances and friendships, set boundaries you can keep, and act from calm rather than need. You do not use it to control anyone.",
    I = "When challenged in a meeting you stay composed and restate your position without escalating.")),
  funding_narrative_arc = list(refs = c("thiel", "presu"), combo = c("traction_proof_ladder", "investor_fit_warm_intro"), sc = c(
    V = "You write the story in seven beats: problem, insight, why now, proof, team, market, ask. A friend retells it in two sentences; if they cannot, you cut.",
    B = "For a strategic partner you swap the ask for a joint plan with shared upside and a first step.")),
  traction_proof_ladder = list(refs = "ries", combo = c("commitment_ladder", "funding_narrative_arc"), sc = c(
    V = "At pre-seed you list assumptions, run tests on the riskiest (will customers pay?), and raise only enough to prove the next one.",
    C = "A founding team agrees what to prove in six months before taking on more people.")),
  fundraise_competitive_tension = list(refs = c("gty", "cial"), combo = c("batna_walkaway", "investor_fit_warm_intro"), sc = c(
    V = "You book first meetings within two weeks, share honest progress updates, ask the most interested investor to lead, and give a date. You never invent offers.")),
  investor_fit_warm_intro = list(refs = c("cial", "carnegie"), combo = c("limitless_prep_loop", "reciprocity_loop"), sc = c(
    V = "Six months before a raise you list ten funds that fit your stage and sector, ask mutual contacts for introductions, and send a short update each month.",
    I = "To reach a hard-to-contact leader you find a trusted mutual contact and ask for a specific introduction with a two-line summary."))
)

# which moment -> algorithms
SOC_MOMENTS <- list(
  "First meeting or first impression" = c("carnegie_interest_loop", "captivate_warmth_competence", "liking_engine", "holmes_observation_read", "limitless_prep_loop"),
  "Asking for a yes (influence)" = c("reciprocity_loop", "commitment_ladder", "social_proof_calibration", "authority_signal", "honest_scarcity", "arouse_want"),
  "Conflict or a stuck conversation" = c("ego_state_match", "game_formula_exit", "save_face_disagree", "separate_people_problem", "stroke_economy"),
  "Negotiation" = c("interests_not_positions", "options_mutual_gain", "objective_criteria", "batna_walkaway"),
  "Raising money or pitching" = c("funding_narrative_arc", "traction_proof_ladder", "fundraise_competitive_tension", "investor_fit_warm_intro"),
  "Deciding under uncertainty" = c("decision_journal_resulting", "bet_expected_value", "premortem_backcast", "optimal_stopping_37", "explore_exploit"),
  "Building trust over time" = c("tit_for_tat", "unity_identity", "truthseeking_pact", "postmortem_centaur", "kasparov_dynamic_eval"),
  "Dating and self-development" = c("captivate_warmth_competence", "game_attraction_funnel", "tomassi_frame_audit"))

hb_cite <- function(keys) paste0("(", paste(vapply(keys, function(k) SOC_REFS[[k]]$cite, ""), collapse = "; "), ")")

hb_refs_used <- function(ids = vapply(SOC_SPECS, function(s) s$id, "")) {
  keys <- unique(unlist(lapply(ids, function(i) SOC_HB[[i]]$refs)))
  full <- vapply(keys, function(k) SOC_REFS[[k]]$full, "")
  full[order(tolower(full))]
}
hb_label <- function(id) { s <- social_spec(id); sprintf("#%d %s", social_rank(id), s$label) }

social_handbook_md <- function(ids = vapply(SOC_SPECS, function(s) s$id, "")) {
  out <- c("# Social Dynamics Handbook: 36 Algorithms", "",
           "How to use: find the moment you are in, open the algorithm, follow the procedure, run the check, then use the scenario for your audience. All algorithms assume honest intent, mutual benefit and consent.", "",
           "Audiences: influencing people, romantic partners, business partners, investors, collaborators.", "")
  for (id in ids) {
    s <- social_spec(id); h <- SOC_HB[[id]]
    out <- c(out, sprintf("## %d. %s %s", social_rank(id), s$label, hb_cite(h$refs)), "", s$summary, "",
             sprintf("**Use when:** %s  \n**Avoid when:** %s", s$when, s$avoid), "", "**Procedure:**", paste0(seq_along(s$steps), ". ", s$steps), "",
             sprintf("**Check:** %s If not: %s.  \n**Outcome:** %s", s$check, tolower(s$fix), s$out), "", "**Scenarios:**")
    for (a in names(h$sc)) out <- c(out, sprintf("- *%s:* %s", SOC_AUDIENCES[[a]], h$sc[[a]]))
    rest <- setdiff(names(s$app), names(h$sc))
    if (length(rest)) out <- c(out, paste0("- *", SOC_AUDIENCES[rest], " (in brief):* ", unname(s$app[rest])))
    out <- c(out, "", sprintf("**Common mistake:** %s  \n**Guardrail:** %s", s$pitfall, s$guard),
             sprintf("\n**Combine with:** %s", paste(vapply(h$combo, hb_label, ""), collapse = "; ")), "")
  }
  out <- c(out, "## References (Harvard style)", "", paste0("- ", hb_refs_used(ids)), "",
    "Note: references were prepared from memory of the standard editions; check edition, publisher and year against your copy before academic use. The summaries are paraphrased concepts, not quotations, and no page numbers are given.")
  paste(out, collapse = "\n")
}

social_handbook_ui <- function(id) {
  ns <- NS(id)
  tagList(fluidRow(box(title = "Social Dynamics Handbook", status = "danger", solidHeader = TRUE, width = 12,
    p(style = "color:#0c4a5a;", "A handbook of the 36 social dynamics algorithms: what each is, when to use it, the procedure, worked scenarios per audience, common mistakes, the ethical guardrail and which algorithms to combine it with. Harvard-style references at the end."),
    fluidRow(
      column(3, selectInput(ns("aud"), "Audience:", choices = c("All" = "", setNames(names(SOC_AUDIENCES), unlist(SOC_AUDIENCES))))),
      column(4, selectInput(ns("moment"), "Moment:", choices = c("All" = "", names(SOC_MOMENTS)))),
      column(3, textInput(ns("q"), "Search:", placeholder = "e.g., BATNA, pitch, conflict")),
      column(2, br(), downloadButton(ns("dl"), "Download (Markdown)", class = "btn-warning", style = "width:100%;"))),
    uiOutput(ns("count")))),
    uiOutput(ns("cards")),
    fluidRow(box(title = "References (Harvard style)", status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE,
                 uiOutput(ns("refs")),
                 p(style = "color:#7f8c8d;font-size:12px;", "Prepared from memory of the standard editions: please check edition, publisher and year against your own copy before academic use. Summaries are paraphrased, not quoted."))))
}

social_handbook_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    ids <- reactive({
      all <- vapply(SOC_SPECS, function(s) s$id, "")
      keep <- all
      a <- input$aud %||% ""; if (nzchar(a)) keep <- keep[vapply(keep, function(i) a %in% social_spec(i)$aud, TRUE)]
      m <- input$moment %||% ""; if (nzchar(m)) keep <- intersect(keep, SOC_MOMENTS[[m]])
      q <- tolower(trimws(input$q %||% ""))
      if (nzchar(q)) keep <- keep[vapply(keep, function(i) { s <- social_spec(i); grepl(q, tolower(paste(s$label, s$src, s$summary, paste(s$steps, collapse = " "), paste(unlist(SOC_HB[[i]]$sc), collapse = " "))), fixed = TRUE) }, TRUE)]
      keep
    })
    output$count <- renderUI(p(style = "margin-top:6px;color:#7f8c8d;", sprintf("%d algorithm(s) shown.", length(ids()))))
    open_btn <- function(i, a) {
      tags$a(href = "#", class = "btn btn-xs btn-default", style = "margin:2px;", icon("project-diagram"), paste(" Diagram:", SOC_AUDIENCES[[a]]),
             onclick = sprintf("Shiny.setInputValue('%s', {id:'%s', aud:'%s', n:Math.random()}, {priority:'event'}); return false;", session$ns("open"), i, a))
    }
    aud_col <- c(I = "#8E44AD", R = "#C2185B", B = "#2874A6", V = "#1E8449", C = "#B9770E")
    MOMENT_TEXT <- c(
      "First meeting or first impression" = "The first minutes decide how much people trust and like you: be curious, warm and prepared.",
      "Asking for a yes (influence)" = "Honest persuasion: the levers that make a request easy to accept.",
      "Conflict or a stuck conversation" = "Patterns that repeat and escalate, and how to step out of them.",
      "Negotiation" = "Agreements that both sides can defend: interests, options, criteria and your alternative.",
      "Raising money or pitching" = "Start-up funding: the story, the proof, the process and the relationships.",
      "Deciding under uncertainty" = "Better bets, better searches: decisions you can learn from.",
      "Building trust over time" = "Cooperation, shared identity and honest review in long relationships and teams.",
      "Dating and self-development" = "Connection, confidence and boundaries, with consent and honesty first.")
    card <- function(i, a) {
      s <- social_spec(i); h <- SOC_HB[[i]]
      rest <- setdiff(names(s$app), names(h$sc))
      first_aud <- if (nzchar(a) && a %in% names(h$sc)) a else names(h$sc)[1]
      box(title = sprintf("#%d  %s", social_rank(i), s$label), status = "danger", solidHeader = TRUE, width = 6, class = "hb-card",
        div(lapply(s$aud, function(x) tags$span(class = "hb-chip", style = sprintf("background:%s;", aud_col[[x]]), SOC_AUDIENCES[[x]]))),
        p(style = "margin-top:6px;", s$summary),
        p(tags$strong("Use it when: "), s$when),
        p(tags$strong("Avoid it when: "), s$avoid),
        tags$strong("Procedure"), tags$ol(lapply(s$steps, tags$li)),
        p(tags$strong("Check: "), s$check, " If not: ", tolower(s$fix), ".  ", tags$strong("Outcome: "), s$out),
        div(class = "example-box", h4(paste0("Scenario - ", SOC_AUDIENCES[[first_aud]], ":")), p(tags$em(h$sc[[first_aud]]))),
        tags$details(tags$summary("More scenarios, common mistake, guardrail and combinations"),
          tags$ul(lapply(setdiff(names(h$sc), first_aud), function(x) tags$li(tags$i(SOC_AUDIENCES[[x]], ": "), h$sc[[x]])),
                  lapply(rest, function(x) tags$li(tags$i(SOC_AUDIENCES[[x]], " (in brief): "), unname(s$app[x])))),
          p(tags$strong("Common mistake: "), s$pitfall), p(tags$strong("Guardrail: "), s$guard),
          p(tags$strong("Combine with: "), paste(vapply(h$combo, hb_label, ""), collapse = "; "))),
        div(class = "hb-cite", icon("book"), " ", paste(vapply(h$refs, function(k) SOC_REFS[[k]]$full, ""), collapse = "  |  ")),
        div(style = "margin-top:8px;", lapply(s$aud, function(x) open_btn(i, x))))
    }
    output$cards <- renderUI({
      keep <- ids(); a <- input$aud %||% ""; m <- input$moment %||% ""
      if (length(keep) == 0) return(fluidRow(box(width = 12, status = "warning", p("No algorithm matches the filters."))))
      seen <- character(0); sections <- list()
      for (mn in names(SOC_MOMENTS)) {
        if (nzchar(m) && mn != m) next
        mine <- intersect(SOC_MOMENTS[[mn]], keep); if (!nzchar(m)) mine <- setdiff(mine, seen)
        seen <- c(seen, mine)
        if (length(mine)) sections[[length(sections) + 1]] <- tagList(div(class = "hb-phase", h4(toupper(mn)), p(MOMENT_TEXT[[mn]])), do.call(fluidRow, lapply(mine, card, a = a)))
      }
      do.call(tagList, sections)
    })
    output$refs <- renderUI(tags$ul(lapply(hb_refs_used(), tags$li)))
    output$dl <- downloadHandler(filename = function() paste0("social_dynamics_handbook_", format(Sys.Date(), "%Y%m%d"), ".md"),
                                 content = function(file) writeLines(social_handbook_md(ids()), file, useBytes = TRUE))
    observeEvent(input$open, {
      o <- input$open; tab <- c(I = "techdesign_soc_influence", R = "techdesign_soc_romantic", B = "techdesign_soc_business", V = "techdesign_soc_investors", C = "techdesign_soc_collab")[[o$aud]]
      td_nav(session, tab)
      updateSelectInput(session$rootScope(), paste0(tab, "-algo"), selected = o$id)
    })
    session$onSessionEnded(function() {})
  })
}
