# ---- Grant Compass: central configuration -----------------------------------
# Everything here can be overridden with environment variables (see README.md).
# Runtime settings that admins change in the app live in the "Settings" tab of
# the Google Sheet, so they survive restarts and are shared by all users.

APP_NAME <- "Grant Compass"
APP_TAGLINE <- "Find the funding that fits us, together."

env_bool <- function(name, default = FALSE) {
  v <- tolower(Sys.getenv(name, ""))
  if (!nzchar(v)) return(default)
  v %in% c("true", "1", "yes", "y")
}

cfg <- list(
  sheet_id      = Sys.getenv("GH_SHEET_ID", ""),             # Google Sheet id or URL
  sa_json       = Sys.getenv("GH_SERVICE_ACCOUNT_JSON", ""), # service-account key file
  google_email  = Sys.getenv("GH_GOOGLE_EMAIL", ""),         # or a cached user token
  data_dir      = Sys.getenv("GH_DATA_DIR", "data"),         # local fallback store
  admin_email   = Sys.getenv("GH_ADMIN_EMAIL", "admin@atera-analytics.co.uk"),
  anthropic_key = Sys.getenv("ANTHROPIC_API_KEY", ""),
  poll_ms       = as.numeric(Sys.getenv("GH_POLL_SECONDS", "20")) * 1000,
  cache_ttl     = as.numeric(Sys.getenv("GH_CACHE_TTL", "15"))
)

# Defaults for runtime settings. AUTH IS OFF BY DEFAULT while testing:
# set GH_AUTH_REQUIRED=true or flip the switch in Admin > Access.
SETTING_DEFAULTS <- list(
  auth_required = if (env_bool("GH_AUTH_REQUIRED", FALSE)) "true" else "false",
  w_alignment   = "1.5",
  w_interest    = "1",
  w_capability  = "1.5",
  grants_url    = "",
  grants_selector = "a",
  llm_enabled   = "false",
  llm_model     = Sys.getenv("GH_LLM_MODEL", "claude-sonnet-5-5"),
  # Collaboration Lab rules (editable in Admin > Access)
  decision_days = "3",        # default window for weighing in
  blind_input   = "true",     # hide others' views until you have added yours
  silence_agrees = "true"     # no objection by the deadline = recommendation stands
)

# Sheet layout: one tab per table, header row = these column names.
SCHEMAS <- list(
  Users      = c("email", "name", "role", "organisation", "interests", "active", "invited_at"),
  Grants     = c("grant_id", "title", "funder", "summary", "themes", "min_gbp", "max_gbp",
                 "closes", "url", "status", "source", "added_by", "added_at"),
  Priorities = c("email", "grant_id", "alignment", "interest", "capability", "stance", "note", "updated_at"),
  Ideas      = c("idea_id", "title", "pitch", "linked_grants", "themes", "origin", "author",
                 "created_at", "status"),
  IdeaVotes  = c("idea_id", "voter", "vote", "updated_at"),
  Settings   = c("key", "value", "updated_by", "updated_at"),
  ChangeLog  = c("timestamp", "user", "action", "entity", "detail"),
  # ---- Collaboration Lab ----
  Decisions  = c("decision_id", "title", "category", "context", "recommended_option", "driver", "approver",
                 "contributors", "informed", "deadline", "status", "linked_grant", "linked_idea", "created_by",
                 "created_at", "outcome_option", "outcome_rationale", "revisit_if", "decided_by", "decided_at",
                 "reopen_count", "updated_at"),
  DecisionOptions = c("option_id", "decision_id", "label", "details", "position"),
  DecisionInputs  = c("decision_id", "email", "option_id", "stance", "comment", "updated_at"),
  WeeklyUpdates   = c("email", "week", "done", "next", "blockers", "shoutout", "updated_at"),
  SyncRequests    = c("req_id", "decision_id", "topic", "reason", "requested_by", "proposed_times",
                      "duration_min", "status", "outcome", "created_at", "updated_at")
)

STANCES <- c("Lead it" = "lead", "Partner" = "partner", "Watch" = "watch", "Pass" = "pass")
