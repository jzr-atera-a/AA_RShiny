# modules/Six Sigma Analysis/sixsigma_recommender.R
# ---- module --------------------------------------------------------------------------------------
# id:           sixsigma_recommender
# name:         Six Sigma Tool Recommender
# label:        Tool Recommender
# icon:         lightbulb
# description:  AI-powered tool recommender - describe a Six Sigma problem, get the top N best-fit tools ranked with reasoning and drawbacks
# packages:     shiny, shinydashboard, DT
# api_required: claude
# --------------------------------------------------------------------------------------------------

# The tab itself is shared with other suites: see tool_recommender_ui / tool_recommender_server in R/utils_suite_tabs.R.

SIXSIGMA_RECOMMENDER_CFG <- list(
  title = "Six Sigma Tool Recommender",
  how = tagList(" The Editing Tool sees the full catalog of all ", length(SIXSIGMA_ALL_TYPES),
                " available Six Sigma tools (with a short description of each) and picks the ones that genuinely ",
                "fit YOUR problem best - not just whichever tool is most famous. Click any recommended tool's name ",
                "below to jump straight to the Generate Diagram tab with it pre-selected."),
  problem_label = "Describe the Six Sigma problem you need to solve or frame: *",
  placeholder = "e.g. Our injection moulding line has a 12% scrap rate and changeovers between product runs take over 90 minutes, cutting into available production time.",
  slider_label = "Number of tools to recommend:",
  spinner_text = "Analysing your problem against the full tool catalog...",
  results_title = "Recommended Tools",
  tag = "Six Sigma Recommender", noun = "tool",
  types = SIXSIGMA_ALL_TYPES, labels = SIXSIGMA_TYPE_LABELS,
  prompt = generate_sixsigma_recommendation_prompt,
  parse = parse_sixsigma_recommendations,
  set_pending = "set_pending_sixsigma_selection",
  target_tab = "generate_sixsigma", target_label = "Generate Six Sigma Diagram"
)

sixsigma_recommender_ui <- function(id) tool_recommender_ui(id, SIXSIGMA_RECOMMENDER_CFG)
sixsigma_recommender_server <- function(id, api_manager) tool_recommender_server(id, api_manager, SIXSIGMA_RECOMMENDER_CFG)
