# modules/Strategic Analysis/diagram_recommender.R
# ---- module --------------------------------------------------------------------------------------
# id:           diagram_recommender
# name:         Strategy Tool Recommender
# label:        Tool Recommender
# icon:         lightbulb
# description:  AI-powered framework recommender - describe a strategic problem, get the top N best-fit frameworks ranked with reasoning and drawbacks
# packages:     shiny, shinydashboard, DT
# api_required: claude
# --------------------------------------------------------------------------------------------------

# The tab itself is shared with other suites: see tool_recommender_ui / tool_recommender_server in R/utils_suite_tabs.R.

DIAGRAM_RECOMMENDER_CFG <- list(
  title = "Strategy Tool Recommender",
  how = tagList(" The Editing Tool sees the full catalog of all ", length(DIAGRAM_TYPES),
                " available frameworks (with a short description of each) and picks the ones that genuinely fit ",
                "YOUR problem best - not just the most famous ones. Click any recommended tool's name below to jump ",
                "straight to the Generate Diagram tab with it pre-selected."),
  problem_label = "Describe the strategic problem you need to solve or frame: *",
  placeholder = "e.g. We're a mid-size UK retailer deciding whether to expand into continental Europe over the next 18 months, but we're uncertain whether our brand and operations model will translate, and we have limited capital to fund a misstep.",
  slider_label = "Number of frameworks to recommend:",
  spinner_text = "Analysing your problem against the full framework catalog...",
  results_title = "Recommended Frameworks",
  tag = "Strategy Recommender", noun = "framework",
  types = DIAGRAM_TYPES, labels = DIAGRAM_TYPE_LABELS,
  prompt = generate_diagram_recommendation_prompt,
  parse = parse_diagram_recommendations,
  set_pending = "set_pending_diagram_selection",
  target_tab = "generate_diagram", target_label = "Generate Diagram"
)

diagram_recommender_ui <- function(id) tool_recommender_ui(id, DIAGRAM_RECOMMENDER_CFG)
diagram_recommender_server <- function(id, api_manager) tool_recommender_server(id, api_manager, DIAGRAM_RECOMMENDER_CFG)
