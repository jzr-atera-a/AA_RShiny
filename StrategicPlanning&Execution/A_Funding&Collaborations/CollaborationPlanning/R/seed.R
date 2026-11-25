# R/seed.R - first-run data: the first admin user and the example question sets
# Seeding only happens when a table is empty, so it never overwrites your data.

EXAMPLE_NOTE <- "Example only. Check every question and word limit against the current competition brief before writing."

example_question_sets <- function() {
  mk <- function(set_id, set_name, funder, q, limits, guidance = "", note = "") {
    n <- length(q)
    data.frame(set_id = set_id, set_name = set_name, funder = funder,
               question_no = as.character(seq_len(n)), question = q,
               guidance = rep_len(guidance, n), word_limit = as.character(rep_len(limits, n)),
               is_example = "TRUE", source_note = trimws(paste(EXAMPLE_NOTE, note)),
               added_by = "seed", added_at = now_ts(), stringsAsFactors = FALSE)
  }
  smart <- mk("qs_innovate_uk_smart", "Innovate UK Smart (example)", "Innovate UK",
    c("Project summary", "Public description", "Scope",
      "Need or challenge", "Approach and innovation", "Team and resources", "Market awareness",
      "Outcomes and route to market", "Wider impacts", "Project management", "Risks",
      "Additionality", "Costs and value for money"),
    400,
    c("What the project does and why it matters", "Plain-English summary that may be published",
      "Why the project fits the competition scope", "The business need or challenge the project answers",
      "How the project will meet the need and what is new about it", "Who will do the work and why they can",
      "The market, its size and the competition", "What the project will produce and how it will reach customers",
      "Economic, social and environmental effects beyond your company", "How the work will be planned and managed",
      "Main risks and how they will be reduced", "What the funding makes possible that would not happen otherwise",
      "How the costs are justified"))
  cam <- mk("qs_cam_pathfinder", "CAM Pathfinder feasibility (example)", "Innovate UK / CCAV",
    c("1. Project Summary", "2. Public Description", "3. Scope",
      "9. Problem, Opportunity and Market Potential", "10. Proposed CAM Service",
      "11. Readiness, Stakeholders and Regulatory", "12. Feasibility Study Plan",
      "13. Commercialisation Roadmap", "14. Team and Capability", "15. Finance and Risk Management",
      "16. Impact on UK Economy and Society", "17. Costs and Value for Money"),
    c(400, 400, 400, 500, 500, 500, 500, 400, 400, 400, 500, 400),
    note = "Questions and limits taken from the Project Application tabs of Business Operations Suite.")
  frontier <- mk("qs_frontier_ai", "Frontier AI: SME Champions (example)", "Innovate UK",
    c("Project summary", "Public description", "Scope", "Need or challenge", "Approach and innovation",
      "Team and resources", "Market awareness", "Outcomes and route to market",
      "Intellectual property, licensing and freedom to operate", "Risks", "Wider impacts",
      "Costs and value for money"),
    400, note = "Structure used when drafting the Frontier AI bids.")
  rbind(smart, cam, frontier)
}

seed_defaults <- function() {
  # first admin, so someone can always sign in and add the others
  u <- store_read("allowed_emails", fresh = TRUE)
  if (!nrow(u)) {
    admins <- cfg$admin_emails[nzchar(cfg$admin_emails)]
    if (length(admins)) {
      store_append("allowed_emails", data.frame(email = admins, role = "admin", name = "", organisation = "",
                                                interests = "", active = "TRUE", added_by = "seed",
                                                added_date = format(Sys.Date()), notes = "First admin, from ADMIN_EMAILS",
                                                stringsAsFactors = FALSE), user = "seed")
      log_debug("[Seed] added first admin(s): ", paste(admins, collapse = ", "))
    }
  }
  # registered members (CP_SEED_MEMBERS): added when their email is not on the list at all
  u <- store_read("allowed_emails", fresh = TRUE)
  new_m <- setdiff(cfg$seed_members[nzchar(cfg$seed_members) & !cfg$seed_members %in% cfg$admin_emails], tolower(trimws(u$email)))
  if (length(new_m)) {
    store_append("allowed_emails", data.frame(email = new_m, role = "member", name = "", organisation = "", interests = "",
                                              active = "TRUE", added_by = "seed", added_date = format(Sys.Date()),
                                              notes = "Registered member, from CP_SEED_MEMBERS", stringsAsFactors = FALSE), user = "seed")
    log_debug("[Seed] registered member(s): ", paste(new_m, collapse = ", "))
  }
  q <- store_read("question_sets", fresh = TRUE)
  if (!nrow(q)) {
    store_append("question_sets", example_question_sets(), user = "seed")
    log_debug("[Seed] loaded 3 example question sets")
  }
  tryCatch(seed_examples(), error = function(e) log_debug("[Seed] examples not loaded: ", safe_error_text(e)))
}

# ---- example content (0.8.0) ---------------------------------------------------------------------
# Loaded once (setting examples_loaded), so deleting an example does not bring it back. Everything is marked
# is_example = TRUE (Example badge). The two programmes are real Innovate UK competitions, checked on
# 23 November 2026 against Innovate UK Business Connect; check the funder's page again before applying.
EXAMPLES_VERSION <- "1"

example_programmes <- function() {
  base <- function(...) { r <- list(...); df <- as.data.frame(r, stringsAsFactors = FALSE); df$programme_id <- new_id("prog"); conform(df, "programmes") }
  common <- list(funder = "Innovate UK (BridgeAI)", category = "Grant", country = "United Kingdom", city_region = "All",
                 amount_text = "GBP 100,000 to GBP 200,000 grant per project (share of up to GBP 5 million)", min_gbp = "100000", max_gbp = "200000",
                 opens_date = "2026-10-21", closes_date = "2026-12-08", deadline_text = "11am UK time", rolling = "FALSE",
                 key_sponsors = "Innovate UK, part of UK Research and Innovation (UKRI)", key_organiser_profiles = "Innovate UK BridgeAI programme",
                 verified_at = "2026-11-23 21:40:00", verified_by = "Claude web search (Innovate UK Business Connect)",
                 stage = "Discover", owner = "", source = "Example", is_example = "TRUE", added_by = "seed",
                 added_at = now_ts(), updated_at = now_ts())
  dcs <- do.call(base, c(common, list(
    programme_name = "BridgeAI Deployment Catalyst: AI for Decision Critical Systems",
    summary = paste("Funds UK SMEs to deploy an existing AI or machine learning product with a real deployer, where the AI helps people make",
                    "consequential judgements, recommendations or decisions. Phase 1 of up to three phases (up to GBP 52 million expected across all phases)."),
    themes = "artificial intelligence; machine learning; decision support; agentic AI; multimodal AI; foundation models; deployment",
    conditions = paste("Lead must be a UK registered SME; Existing AI or ML solution at TRL 5 or 6 with a working minimum viable product;",
                       "Product not already deployed commercially in the proposed use case; At least two organisations: the SME and an eligible UK registered deployer (three at most);",
                       "Academic institutions cannot lead; Project lasts 3 to 5 months, starts by 1 April 2027 and ends by 31 August 2027;",
                       "Results exploited in or from the UK"),
    recommendations = paste("Line up the deployer early: a letter of support and a clear decision-critical use case matter most.",
                            "Excluded: early-stage research, generic productivity tools, back-office automation, AI peripheral to the deployer's core work.",
                            "Applicants hear on 1 February 2027."),
    verified_urls = "https://iuk-business-connect.org.uk/opportunities/bridgeai-deployment-catalyst-ai-for-decision-critical-systems/, https://apply-for-innovation-funding.service.gov.uk/competition/2598/overview/cfb35198-55fc-4aad-afa1-86a260bfaddf",
    source_url = "https://iuk-business-connect.org.uk/opportunities/bridgeai-deployment-catalyst-ai-for-decision-critical-systems/")))
  ac <- do.call(base, c(common, list(
    programme_name = "BridgeAI Deployment Catalyst: AI for Assurance and Compliance",
    summary = paste("Funds UK SMEs to deploy AI and machine learning that monitors, tests, verifies, validates or evidences compliance with",
                    "requirements, standards or controls. One of three BridgeAI Deployment Catalyst strands."),
    themes = "artificial intelligence; assurance; compliance; testing; verification; deployment",
    conditions = paste("Lead must be a UK registered SME; At least two organisations: the SME and an eligible UK registered deployer;",
                       "Academic institutions cannot lead; Grant request between GBP 100,000 and GBP 200,000"),
    recommendations = "Read the competition brief on the Innovation Funding Service before applying; same deadline as the Decision Critical Systems strand.",
    verified_urls = "https://iuk-business-connect.org.uk/opportunities/bridgeai-deployment-catalyst-ai-for-assurance-and-compliance/",
    source_url = "https://iuk-business-connect.org.uk/opportunities/bridgeai-deployment-catalyst-ai-for-assurance-and-compliance/")))
  rbind(dcs, ac)
}

example_collab_ideas <- function(dcs_id = "") {
  mk <- function(title, client, sector, summary, value, customers, revenue, gbp, effort, status, next_step, tags, prog = "") conform(data.frame(
    idea_id = new_id("cid"), title = title, client = client, sector = sector, country = "United Kingdom", summary = summary,
    value_proposition = value, target_customers = customers, revenue_model = revenue, est_value_gbp = gbp, effort = effort, status = status,
    next_step = next_step, owner_email = "", related_programme_id = prog, url = "", tags = tags, is_example = "TRUE", created_by = "seed",
    created_at = now_ts(), updated_at = now_ts(), deleted = "FALSE", stringsAsFactors = FALSE), "collab_ideas")
  rbind(
    mk("AI delivery-exception triage for a regional logistics firm", "A mid-sized UK logistics company (example)", "Logistics",
       "An AI assistant that ranks late or failed deliveries each morning and recommends the action to take for each one.",
       "Fewer missed delivery windows and less time spent by planners on manual checks.",
       "Operations directors at logistics firms with 50 to 500 vehicles.",
       "Paid eight-week pilot, then a yearly licence per depot.", "60000", "medium", "exploring",
       "Ask the operations director for three months of anonymised delivery data.", "AI; decision support; pilot", dcs_id),
    mk("White-label reporting dashboard for accountancy firms", "Two local accountancy practices (example)", "Professional services",
       "A dashboard the accountants give to their small-business clients, showing cash flow and simple forecasts.",
       "Accountants offer a premium service without building software themselves.",
       "Accountancy practices with 5 to 50 staff.", "Set-up fee per firm plus a monthly fee per client business.", "45000", "low", "idea",
       "Show a mock-up to one practice partner and ask what they would pay.", "dashboard; SaaS; partners"),
    mk("Joint energy-forecasting service with a university lab", "A university energy systems group (example)", "Energy",
       "Combine the lab's forecasting models with our software to sell short-term demand forecasts to housing associations.",
       "Housing associations plan heating and maintenance better and cut energy bills.",
       "Housing associations and local councils.", "Annual subscription; the university earns a royalty.", "120000", "high", "talking to client",
       "Agree who owns what with the university's technology transfer office.", "energy; university; forecasting"))
}

example_analysis <- function() {
  tabs <- list(
    list(title = "Key facts", data = data.frame(Item = c("Funder", "Grant per project", "Opens", "Closes", "Project length", "Decision"),
      Detail = c("Innovate UK (BridgeAI)", "GBP 100,000 to 200,000", "21 October 2026", "8 December 2026, 11am", "3 to 5 months, start by 1 April 2027", "1 February 2027"),
      Source = "Innovate UK Business Connect", check.names = FALSE, stringsAsFactors = FALSE)),
    list(title = "Fit with our work", data = data.frame(Question = c("Do we have an AI product at TRL 5 or 6?", "Is there a decision-critical use case?", "Do we have a UK deployer?"),
      Answer = c("To confirm: needs a working minimum viable product", "Yes, if the deployer's staff act on its recommendations", "Not yet: the main gap"),
      check.names = FALSE, stringsAsFactors = FALSE)),
    list(title = "Next steps", data = data.frame(Step = c("Choose the use case and deployer", "Get a letter of support", "Draft the application"),
      Who = c("Lead", "Deployer", "Bid team"), `By when` = c("2026-11-28", "2026-12-02", "2026-12-05"), check.names = FALSE, stringsAsFactors = FALSE)))
  conform(data.frame(analysis_id = new_id("an"), suggestion_id = "", title = "BridgeAI Deployment Catalyst: AI for Decision Critical Systems (example)",
    instructions = "Example analysis, written by hand to show what Claude returns.", model = "", result_raw = "", tables_json = tables_to_json(tabs),
    summary = "Example. A strong fit if we can bring a UK deployer and an existing AI product at TRL 5 or 6. The deployer is the main gap.",
    country = "United Kingdom", category = "Grant", topic = "Artificial intelligence", programme = "BridgeAI Deployment Catalyst",
    access_emails = "everyone", status = "example", created_by = "seed", created_at = now_ts(), updated_at = now_ts(),
    drive_id = "", drive_path = "", drive_synced_at = "", deleted = "FALSE", stringsAsFactors = FALSE), "analyses")
}

seed_examples <- function() {
  if (identical(get_settings()$examples_loaded %||% "", EXAMPLES_VERSION)) return(invisible(FALSE))
  r <- add_programmes(example_programmes(), "seed")
  p <- store_read("programmes", fresh = TRUE)
  dcs <- p$programme_id[p$programme_name == "BridgeAI Deployment Catalyst: AI for Decision Critical Systems"][1] %||% ""
  store_append("collab_ideas", example_collab_ideas(if (is.na(dcs)) "" else dcs), user = "seed")
  store_append("analyses", example_analysis(), user = "seed")
  set_setting("examples_loaded", EXAMPLES_VERSION, "seed")
  log_debug(sprintf("[Seed] examples loaded: %d programme(s), 3 collaboration ideas, 1 analysis", r$added))
  invisible(TRUE)
}
