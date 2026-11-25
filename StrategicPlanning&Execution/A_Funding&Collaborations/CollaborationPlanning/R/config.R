# R/config.R - central configuration for Collaboration Planning
# Everything here can be overridden with environment variables (.Renviron locally,
# Settings > Environment Variables on shinyapps.io). See README.md.

APP_NAME    <- "Collaboration Planning"
APP_TAGLINE <- "Choose the right funding, team up, and deliver."
APP_VERSION <- "0.8.0"

env_or <- function(name, default = "") {
  v <- Sys.getenv(name, "")
  if (nzchar(v)) v else default
}

cfg <- list(
  # Google service account (one key serves both Google Sheets and BigQuery)
  sa_key_path   = env_or("GOOGLE_SA_KEY_PATH", "auth/google_service_account.json"),
  # Google Sheet: approved users, sign-in log, team tables
  sheet_id      = env_or("GOOGLE_SHEETS_ID", ""),
  # BigQuery: full history and programme data
  bq_project    = env_or("CP_BQ_PROJECT", ""),
  bq_dataset    = env_or("CP_BQ_DATASET", "business_strategy"),
  bq_prefix     = env_or("CP_BQ_PREFIX", "cp_"),
  # local CSV store, used when neither Google service is set up (testing)
  data_dir      = env_or("CP_DATA_DIR", "data"),
  # people who are always admins, even before the Sheet is set up
  admin_emails  = tolower(trimws(strsplit(env_or("ADMIN_EMAILS", "joseph.zr@atera-analytics.co.uk"), ",")[[1]])),
  # people registered as members (not admins) on first start; added once if missing, never re-added after removal
  seed_members  = tolower(trimws(strsplit(env_or("CP_SEED_MEMBERS", "ali.jboloori@gmail.com"), ",")[[1]])),
  # code that unlocks the Admin settings when the app does NOT run on Windows
  admin_code    = env_or("CP_ADMIN_CODE", "7818"),
  # AI and task board keys (admins can also paste them for the running session)
  anthropic_key = env_or("ANTHROPIC_API_KEY", ""),
  trello_key    = env_or("TRELLO_KEY", ""),
  trello_token  = env_or("TRELLO_TOKEN", ""),
  smtp_password = env_or("SMTP_PASSWORD", ""),
  # Claude server web search tool version (check docs.claude.com when it changes)
  web_tool      = env_or("CP_WEB_SEARCH_TOOL", "web_search_20250305"),
  cache_secs    = as.numeric(env_or("CP_CACHE_SECS", "30")),
  max_attempts  = 5,
  lockout_secs  = 300
)

# Running on Windows = the app is on your own computer, so Admin needs no code.
# shinyapps.io runs on Linux, so the code is always asked for there.
IS_WINDOWS <- identical(.Platform$OS.type, "windows")

CLAUDE_MODELS <- c("claude-sonnet-5-5", "claude-opus-5-5", "claude-haiku-5-5")

# Defaults for settings that admins change in the app (stored in the "settings" table)
SETTING_DEFAULTS <- list(
  claude_model     = env_or("CP_CLAUDE_MODEL", "claude-sonnet-5-5"),
  claude_web_search = "true",
  trello_board_id  = env_or("TRELLO_BOARD_ID", ""),
  w_alignment      = "1.5",
  w_interest       = "1",
  w_capability     = "1.5",
  decision_days    = "3",
  blind_input      = "true",
  silence_agrees   = "true",
  verify_days      = "30",
  company_profile  = "",
  # email (outreach, reminders). The password is never stored here: SMTP_PASSWORD or Admin > Email.
  smtp_host        = env_or("SMTP_HOST", "smtp.titan.email"),
  smtp_port        = env_or("SMTP_PORT", "465"),
  smtp_user        = env_or("SMTP_USER", ""),
  smtp_always_cc   = env_or("SMTP_ALWAYS_CC", ""),
  reminder_days    = "7",
  # owner's tab setup (Admin > Tabs and groups), JSON; empty = registry defaults
  tab_config       = "",
  examples_loaded  = "",          # "1" once the example programmes, ideas and analysis have been loaded
  # Google Drive copies of the analysis tables (Admin > Google Drive)
  drive_mode       = env_or("CP_DRIVE_MODE", "off"),          # off | api | folder
  drive_folder_id  = env_or("CP_DRIVE_FOLDER_ID", ""),        # api: a folder in a Shared Drive, shared with the service account
  drive_local_path = env_or("CP_DRIVE_LOCAL_PATH", ""),       # folder: e.g. G:/My Drive/Collaboration Planning (Drive for desktop)
  drive_auto_backup = "TRUE",                                  # copy every table to Drive once a day, when the owner signs in
  drive_last_backup = "",
  analysis_instructions = paste(
    "Analyse this funding or collaboration programme for our company.",
    "Cover: what it funds, who can apply, money and dates, fit with our work, partners we would need, risks, and next steps.",
    "Check the programme's web page if a link is given.")
)

# The eight stages a programme moves through (see the design doc)
STAGES <- c("Discover", "Qualify", "Team up", "Decide", "Plan", "Write", "Deliver", "Learn")

# Table layouts: one Google Sheet tab and one BigQuery table per entry, header = these columns.
# Phase 1 uses the CORE tables; the rest are created on first use by later phases.
SCHEMAS <- list(
  allowed_emails = c("email", "role", "name", "organisation", "interests", "active",
                     "added_by", "added_date", "notes"),
  login_log      = c("timestamp", "email", "success", "session_id", "detail"),
  settings       = c("key", "value", "updated_by", "updated_at"),
  changelog      = c("timestamp", "user", "action", "entity", "detail"),
  programmes     = c("programme_id", "programme_name", "funder", "category", "country", "city_region",
                     "summary", "themes", "conditions", "key_sponsors", "key_organiser_profiles",
                     "amount_text", "min_gbp", "max_gbp", "funding_rate_pct",
                     "opens_date", "closes_date", "deadline_text", "rolling",
                     "recommendations", "verified_urls", "source_url", "verified_at", "verified_by",
                     "stage", "owner", "source", "is_example", "added_by", "added_at", "updated_at"),
  question_sets  = c("set_id", "set_name", "funder", "question_no", "question", "guidance",
                     "word_limit", "is_example", "source_note", "added_by", "added_at"),
  # ---- later phases (created when first used). New columns only ever go at the END. ----
  priorities     = c("email", "programme_id", "alignment", "interest", "capability", "stance", "note", "updated_at"),
  eligibility    = c("programme_id", "condition", "result", "evidence", "checked_by", "checked_at"),
  consortium     = c("programme_id", "email", "role", "status", "budget_share_pct", "documents_owed", "updated_at",
                     "documents_received", "name", "organisation", "updated_by"),
  messages       = c("message_id", "email", "programme_id", "channel", "purpose", "content", "created_by", "created_at",
                     "subject", "direction", "status", "detail"),
  decisions      = c("decision_id", "programme_id", "title", "context", "recommended_option", "driver", "approver",
                     "contributors", "deadline", "status", "outcome_option", "outcome_rationale", "revisit_if",
                     "decided_by", "decided_at", "created_by", "created_at", "updated_at", "kind", "tree_inputs"),
  projects       = c("project_id", "programme_id", "title", "start_date", "end_date", "budget_gbp", "status",
                     "created_by", "created_at", "updated_at", "lead_email"),
  tasks          = c("task_id", "project_id", "work_package", "task", "start_date", "end_date", "owner_email",
                     "partner", "status", "trello_card_id", "updated_at", "description", "trello_url", "deleted", "updated_by"),
  weekly         = c("email", "project_id", "week", "done", "next", "blockers", "shoutout", "updated_at"),
  outcomes       = c("programme_id", "result", "score", "feedback", "lessons", "recorded_by", "recorded_at"),
  # ---- new tables (phases 3 to 5) ----
  people         = c("person_id", "email", "name", "organisation", "role_title", "type", "interests", "past_projects",
                     "phone", "linkedin", "notes", "source", "added_by", "added_at", "updated_at", "country", "deleted"),
  decision_options = c("decision_id", "option_id", "label", "detail", "created_at"),
  decision_inputs  = c("decision_id", "email", "option_id", "stance", "comment", "updated_at"),
  ideas          = c("idea_id", "programme_id", "title", "detail", "status", "created_by", "created_at", "updated_at"),
  idea_votes     = c("idea_id", "email", "vote", "updated_at"),
  gonogo         = c("programme_id", "bid_cost_gbp", "win_prob_pct", "win_value_gbp", "ev_bid_gbp", "note",
                     "updated_by", "updated_at"),
  raci           = c("project_id", "task_id", "email", "letter", "updated_at"),
  risks          = c("risk_id", "project_id", "risk", "cause", "effect", "likelihood", "impact", "owner_email",
                     "mitigation", "status", "updated_at", "updated_by"),
  budget         = c("project_id", "partner", "category", "amount_gbp", "funded_pct", "note", "updated_at", "updated_by"),
  answers        = c("project_id", "set_id", "question_no", "version", "text", "words", "updated_by", "updated_at"),
  canvases       = c("canvas_id", "project_id", "kind", "content", "created_by", "created_at"),
  milestones     = c("milestone_id", "project_id", "title", "kind", "due_date", "amount_gbp", "owner_email",
                     "status", "decision_id", "note", "updated_by", "updated_at"),
  reminders_log  = c("sent_at", "to_email", "subject", "items", "ok", "detail", "sent_by"),
  # ---- suggestions and Claude analyses (0.6.0) ----
  suggestions    = c("suggestion_id", "kind", "title", "description", "url", "ideas", "country", "category", "topic",
                     "funder", "amount_text", "deadline", "contact", "notes", "status", "created_by", "created_at",
                     "updated_at", "deleted"),
  # ---- general collaboration ideas (0.8.0): commercial ideas with clients and partners, not funding ----
  collab_ideas   = c("idea_id", "title", "client", "sector", "country", "summary", "value_proposition", "target_customers",
                     "revenue_model", "est_value_gbp", "effort", "status", "next_step", "owner_email", "related_programme_id",
                     "url", "tags", "is_example", "created_by", "created_at", "updated_at", "deleted"),
  collab_notes   = c("note_id", "idea_id", "email", "note", "created_at"),
  analyses       = c("analysis_id", "suggestion_id", "title", "instructions", "model", "result_raw", "tables_json",
                     "summary", "country", "category", "topic", "programme", "access_emails", "status", "created_by",
                     "created_at", "updated_at", "drive_id", "drive_path", "drive_synced_at", "deleted")
)
CORE_TABLES <- c("allowed_emails", "login_log", "settings", "changelog", "programmes", "question_sets")

# Values used across tabs
CATEGORIES      <- c("Grant", "Incubator", "Accelerator", "Competition", "Loan", "Prize", "Other")
CONSORTIUM_ROLES  <- c("lead", "partner", "subcontractor")
CONSORTIUM_STATUS <- c("asked", "interested", "committed", "declined")
STANCES         <- c("lead", "partner", "watch", "pass")
COLLAB_STATUS   <- c("idea", "exploring", "talking to client", "proposal sent", "won", "parked")
COLLAB_EFFORT   <- c("low", "medium", "high")
OUTCOME_RESULTS <- c("won", "lost", "withdrawn", "not pursued")
BUDGET_CATEGORIES <- c("Labour", "Overheads", "Materials", "Capital equipment", "Subcontracting", "Travel and subsistence", "Other")
