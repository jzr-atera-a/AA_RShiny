# modules/Strategic Analysis/diagram_tool_guide/ui.R

# Small local helper - not exported, just keeps the ~29 cards below
# consistent. Adds a "Learn more" link to a verified, reputable external
# source for each framework, with a one-line note on what that page covers.
.strategy_tool_card <- function(name, when_to_use, shape_note, sample_request, learn_url, learn_note) {
  box(
    title = name, status = "primary", solidHeader = TRUE, width = 6,
    p(tags$strong("Use it when: "), when_to_use),
    p(tags$strong("How it's drawn: "), shape_note),
    div(class = "example-box",
        h4("Try asking for it like this:"),
        p(tags$em(sample_request))
    ),
    p(style = "margin-top: 10px; font-size: 0.9em;",
      tags$i(class = "fa fa-external-link-alt"), " ",
      tags$a(href = learn_url, target = "_blank", rel = "noopener noreferrer", "Learn more"),
      " - ", learn_note)
  )
}

.strategy_group_header <- function(group_label, group_description) {
  fluidRow(
    box(width = 12, status = "warning", solidHeader = FALSE,
        style = "background-color: #FFFACD; border-left: 5px solid #FF8C00;",
        h4(group_label, style = "margin-top: 0;"),
        p(group_description, style = "margin-bottom: 0;")
    )
  )
}

diagram_tool_guide_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Which strategy framework should I ask for?", status = "primary", solidHeader = TRUE, width = 12,
          p("Each entry below is one value of the ", tags$strong("Framework"), " dropdown on the Generate ",
            "Diagram tab, organized by which ", tags$strong("Diagram Group"), " (strategic lens) it belongs ",
            "to. Pick the Group first, then the specific Framework. Claude fills in the content, but the ",
            "framework's exact structure - its named quadrants, axes, cells, or stages - is fixed by this ",
            "choice, not left to Claude to guess. Each card also links to a reputable external source if you ",
            "want to read more about the framework itself before using it.")
      )
    ),

    .strategy_group_header("SITUATIONAL ANALYSIS", "Understanding the current internal and external situation before deciding anything."),
    fluidRow(
      .strategy_tool_card(
        "SWOT Analysis",
        "you need a broad first-pass assessment of internal strengths/weaknesses and external opportunities/threats.",
        "a true 2x2 grid (Strengths, Weaknesses, Opportunities, Threats).",
        "\"Build a SWOT for whether we should enter the Brazilian market\"",
        "https://www.mindtools.com/your-toolkit/strategy-analysis/swot/",
        "MindTools' full walkthrough with a worked example and downloadable template."
      ),
      .strategy_tool_card(
        "PESTEL Analysis",
        "you need to scan the macro-environment across political, economic, social, technological, environmental, and legal factors.",
        "a 2-row x 3-column grid, in that fixed order.",
        "\"Run a PESTEL analysis on expanding our fintech product into the EU\"",
        "https://www.mindtools.com/aqa3q37/pest-analysis/",
        "MindTools' guide (covers the PEST/PESTEL/PESTLE family of variants and their origin)."
      )
    ),
    fluidRow(
      .strategy_tool_card(
        "Porter's Five Forces",
        "you need to assess the competitive intensity and attractiveness of an industry.",
        "a hub-and-spoke network - the industry is the hub, the five forces are the spokes.",
        "\"Build a Five Forces analysis of the airline industry\"",
        "https://www.mindtools.com/at7k8my/porter-s-five-forces/",
        "MindTools' guide to Porter's original 1979 model, with a template."
      ),
      .strategy_tool_card(
        "VRIO Analysis",
        "you need to assess whether a specific resource or capability is a genuine source of sustained competitive advantage.",
        "a data table: one row per resource, columns for Valuable/Rare/Inimitable/Organized and the resulting competitive implication.",
        "\"Run a VRIO analysis on our proprietary logistics network\"",
        "https://www.mindtools.com/your-toolkit/strategy-analysis/vrio-analysis/",
        "MindTools' guide to Jay Barney's resource-based-view framework."
      )
    ),
    fluidRow(
      .strategy_tool_card(
        "Porter's Value Chain",
        "you need to map where value is created (or lost) across a firm's primary and support activities.",
        "a dedicated diagram: 4 support-activity bars along the top, 5 primary-activity arrow segments along the bottom, plus a margin wedge.",
        "\"Map the value chain of our furniture manufacturing business\"",
        "https://www.mindtools.com/alph8wv/what-is-porters-value-chain/",
        "MindTools' explanation of Porter's 1985 \"Competitive Advantage\" concept."
      ),
      box(title = "Moving to Competitive Positioning", status = "info", solidHeader = TRUE, width = 6,
          p("Once you understand the situation, the Competitive Positioning frameworks below help you decide ",
            "where and how to compete.")
      )
    ),

    .strategy_group_header("COMPETITIVE POSITIONING", "Deciding where to compete and how to win against competitors."),
    fluidRow(
      .strategy_tool_card(
        "BCG Growth-Share Matrix",
        "you need to prioritize investment across a portfolio of products or business units based on market growth and relative share.",
        "a 2x2 quadrant: Stars, Question Marks, Cash Cows, Dogs.",
        "\"Map our product portfolio on a BCG growth-share matrix\"",
        "https://www.bcg.com/about/overview/our-history/growth-share-matrix",
        "The Boston Consulting Group's own page on the matrix they created in 1968."
      ),
      .strategy_tool_card(
        "GE-McKinsey Nine-Box Matrix",
        "you need a more nuanced portfolio view than BCG's simple 2x2, weighing industry attractiveness against business unit strength.",
        "a 3x3 grid with two labeled axes.",
        "\"Build a GE-McKinsey matrix for our three regional business units\"",
        "https://www.mindtools.com/a1lzwol/ge-mckinsey-matrix/",
        "MindTools' guide, with a free downloadable template."
      )
    ),
    fluidRow(
      .strategy_tool_card(
        "Ansoff Matrix",
        "you're deciding a growth strategy along the products/markets dimensions.",
        "a 2x2 quadrant: Market Penetration, Product Development, Market Development, Diversification.",
        "\"Build an Ansoff matrix for our growth options in the next 3 years\"",
        "https://www.mindtools.com/a2gy5ya/the-ansoff-matrix/",
        "MindTools' guide to Igor Ansoff's original 1957 HBR framework."
      ),
      .strategy_tool_card(
        "Porter's Generic Strategies",
        "you're deciding the basis of competitive advantage: cost or differentiation, broad or narrow scope.",
        "a 2x2 quadrant: Cost Leadership, Differentiation, Cost Focus, Differentiation Focus.",
        "\"Which generic strategy fits our boutique coffee brand?\"",
        "https://www.mindtools.com/azb8kpl/porters-generic-strategies/",
        "MindTools' guide to Porter's three (four, with Focus split) generic strategies."
      )
    ),
    fluidRow(
      .strategy_tool_card(
        "TOWS Matrix",
        "you want to move from SWOT's raw analysis to concrete action strategies (the follow-up to a SWOT).",
        "a 3x3 grid where the 4 interior cells hold SO/WO/ST/WT strategy combinations.",
        "\"Turn our SWOT into a TOWS matrix with concrete strategies\"",
        "https://www.mindtools.com/auqstul/the-tows-matrix/",
        "MindTools' explanation of how TOWS extends and differs from SWOT."
      ),
      .strategy_tool_card(
        "Blue Ocean ERRC Grid",
        "you want to break from head-to-head competition by rethinking which factors of competition to change.",
        "a single row of 4 cells: Eliminate, Reduce, Raise, Create.",
        "\"Build a Blue Ocean ERRC grid for reinventing budget air travel\"",
        "https://www.blueoceanstrategy.com/tools/errc-grid/",
        "The official Blue Ocean Strategy site (Kim & Mauborgne) explaining the grid and its benefits."
      )
    ),
    fluidRow(
      .strategy_tool_card(
        "Blue Ocean Value Curve",
        "you want to visually compare your strategic profile against competitors across the industry's key factors of competition.",
        "a line chart - each competitor is a series, industry factors are the shared x-axis.",
        "\"Chart our value curve against traditional airlines for a budget carrier strategy\"",
        "https://www.blueoceanstrategy.com/tools/strategy-canvas/",
        "The official Blue Ocean Strategy site's page on the Strategy Canvas / value curve tool."
      ),
      box(title = "Moving to Business Model & Design", status = "info", solidHeader = TRUE, width = 6,
          p("Once you've picked a competitive position, the Business Model frameworks below help you design ",
            "how the business actually captures value.")
      )
    ),

    .strategy_group_header("BUSINESS MODEL & DESIGN", "Designing how the business creates, delivers, and captures value."),
    fluidRow(
      .strategy_tool_card(
        "Business Model Canvas",
        "you need a complete, one-page view of how a business creates and captures value.",
        "the classic 9-block canvas in its standard fixed layout.",
        "\"Build a Business Model Canvas for a subscription meal-kit startup\"",
        "https://www.strategyzer.com/library/the-business-model-canvas",
        "Strategyzer's official page (Alex Osterwalder's own company) with the downloadable template."
      ),
      .strategy_tool_card(
        "Lean Canvas",
        "you're validating an early-stage startup idea and need to focus on problem/solution fit over infrastructure.",
        "the same 9-block canvas layout, with Lean Canvas's problem/solution-focused blocks instead of BMC's.",
        "\"Build a Lean Canvas for a B2B SaaS idea in freight logistics\"",
        "https://www.leanfoundry.com/tools/lean-canvas",
        "Ash Maurya's own site (creator of the Lean Canvas) explaining the tool and its blocks."
      )
    ),

    .strategy_group_header("DECISION-MAKING & PROCESS", "Structuring how a decision or process actually gets made."),
    fluidRow(
      .strategy_tool_card(
        "Frame-Diagnose-Choose-Act",
        "you need to structure a specific strategic decision process step by step.",
        "a 4-box left-to-right sequence.",
        "\"Walk through Frame-Diagnose-Choose-Act for whether to acquire a competitor\"",
        "https://www.argumentree.com/blog/decision-quality-chain/",
        "An overview of the Decision Quality tradition (Howard, Spetzler) this framing/diagnosis approach descends from."
      ),
      .strategy_tool_card(
        "PDCA Cycle",
        "you're running a continuous improvement loop and want to show its cyclical nature.",
        "a radial wheel with 4 segments: Plan, Do, Check, Act.",
        "\"Show our quality improvement process as a PDCA cycle\"",
        "https://asq.org/quality-resources/pdca-cycle",
        "ASQ's official explanation of the Shewhart/Deming Plan-Do-Check-Act cycle."
      )
    ),
    fluidRow(
      .strategy_tool_card(
        "Weighted Decision Matrix",
        "you're comparing several options against multiple weighted criteria and want the raw scores laid out clearly.",
        "a data table: criteria (with weights) as rows, options as columns.",
        "\"Compare 3 office locations using a weighted decision matrix\"",
        "https://www.mindtools.com/aksic2i/decision-matrix-analysis/",
        "MindTools' guide to Decision Matrix Analysis (a form of Multi-Criteria Decision Analysis)."
      ),
      box(title = "Moving to Organizational Alignment", status = "info", solidHeader = TRUE, width = 6,
          p("Once a decision is made, the Organizational frameworks below help align the people and structure ",
            "needed to execute it.")
      )
    ),

    .strategy_group_header("ORGANIZATIONAL ALIGNMENT", "Aligning structure, systems, and people around the strategy."),
    fluidRow(
      .strategy_tool_card(
        "McKinsey 7S Framework",
        "you need to assess whether an organization's structure, systems, and culture are aligned with its strategy.",
        "a hub-and-spoke network - Shared Values is the hub, the other 6 S's are the spokes.",
        "\"Assess organizational alignment for our post-merger integration using the 7S framework\"",
        "https://www.mckinsey.com/capabilities/strategy-and-corporate-finance/our-insights/enduring-ideas-the-7-s-framework",
        "McKinsey's own \"Enduring Ideas\" page on the framework it originated."
      ),
      .strategy_tool_card(
        "RACI Matrix",
        "you need to clarify who is Responsible, Accountable, Consulted, and Informed across a set of tasks.",
        "a data table: tasks as rows, roles as columns, one letter per cell.",
        "\"Build a RACI matrix for our product launch project\"",
        "https://www.mindtools.com/agn584l/the-raci-matrix/",
        "MindTools' guide to building and using a RACI matrix."
      )
    ),

    .strategy_group_header("TIMING & LIFECYCLE", "Understanding how markets, products, and decisions evolve over time."),
    fluidRow(
      .strategy_tool_card(
        "Disruptive Innovation Curve",
        "you want to show how a disruptor's performance trajectory could overtake an incumbent's.",
        "a line chart with 2-3 series (Incumbent, Disruptor, optionally Mainstream Needs) over time.",
        "\"Chart the disruptive innovation trajectory of streaming vs. cable TV\"",
        "https://hbr.org/2015/12/what-is-disruptive-innovation",
        "Clayton Christensen's own HBR article clarifying what disruption theory does and doesn't mean."
      ),
      .strategy_tool_card(
        "Product Lifecycle Curve",
        "you want to show where a product sits in its Introduction/Growth/Maturity/Decline journey.",
        "a single S-curve line chart with the 4 stages labeled.",
        "\"Show the product lifecycle stage of our flagship smartphone line\"",
        "https://www.mindtools.com/ac1f1zt/the-product-life-cycle/",
        "MindTools' explanation of the 4 stages and how to extend the profitable ones."
      )
    ),
    fluidRow(
      .strategy_tool_card(
        "Technology Adoption Lifecycle",
        "you need to segment your market by adoption behavior (Innovators through Laggards).",
        "a 5-bar bell-curve-shaped bar chart in fixed order.",
        "\"Segment our EV charging network customers by technology adoption lifecycle\"",
        "https://www.britannica.com/topic/diffusion-of-innovations",
        "Encyclopedia Britannica's overview of Everett Rogers' Diffusion of Innovations theory."
      ),
      .strategy_tool_card(
        "Trend to Commoditization",
        "you want to show how price or margin erodes across successive product generations.",
        "a bar chart with decreasing values across generations/periods.",
        "\"Chart the commoditization trend across three generations of our hardware product\"",
        "https://www.library.hbs.edu/working-knowledge/when-your-product-becomes-a-commodity",
        "Harvard Business School Working Knowledge on recognizing and responding to commoditization."
      )
    ),
    fluidRow(
      .strategy_tool_card(
        "Active Waiting",
        "you're deciding whether to commit now or wait, and want to weigh the opportunity of waiting against the threat of delay.",
        "a dual-axis timeseries with two diverging series (Opportunity, Threat).",
        "\"Chart the active waiting trade-off for entering the autonomous vehicle market now vs. later\"",
        "https://hbr.org/2005/09/strategy-as-active-waiting",
        "Donald Sull's original 2005 HBR article that coined this framework."
      ),
      .strategy_tool_card(
        "Economic Profit Mobility",
        "you want to show how few companies sustain top-tier economic performance over time.",
        "a funnel narrowing through performance tiers.",
        "\"Show economic profit mobility for companies in the retail banking sector\"",
        "https://www.mckinsey.com/capabilities/strategy-and-corporate-finance/our-insights/the-strategic-yardstick-you-cant-afford-to-ignore",
        "McKinsey's original research on the economic-profit \"power curve\" this framework is based on."
      )
    ),
    fluidRow(
      .strategy_tool_card(
        "Kano Model",
        "you need to classify features by how they drive customer satisfaction (basic, performance, or delighter).",
        "a line chart with 3 differently-shaped curves (flat, linear, exponential).",
        "\"Apply the Kano model to prioritize features for our ride-sharing app\"",
        "https://asq.org/quality-resources/kano-model",
        "ASQ's explanation of Dr. Noriaki Kano's model and its three levels of customer expectation."
      ),
      box(title = "Moving to Foundational", status = "info", solidHeader = TRUE, width = 6,
          p("The Foundational frameworks below sit underneath everything else - they frame the purpose and ",
            "overall shape of a strategy itself.")
      )
    ),

    .strategy_group_header("FOUNDATIONAL", "The most fundamental framing tools - purpose, planning cadence, and the shape of a strategy itself."),
    fluidRow(
      .strategy_tool_card(
        "Purpose of Strategy Pyramid",
        "you want to show how a company's fundamental purpose cascades down into concrete initiatives.",
        "a small ordered vertical stack, most abstract at top.",
        "\"Show how our company purpose cascades down to this quarter's initiatives\"",
        "https://www.mindtools.com/ayh8f1j/pyramid-of-purpose/",
        "MindTools' explanation of the Pyramid of Purpose technique."
      ),
      .strategy_tool_card(
        "Strategic Planning Wheel",
        "you want to show the phases of a recurring strategic planning cycle.",
        "a radial wheel with 5-8 segments in clockwise order.",
        "\"Build a strategic planning wheel with our 6 annual planning phases\"",
        "https://www.thestrategyinstitute.org/insights/6-key-phases-of-the-strategic-planning-process",
        "The Strategy Institute's overview of the recurring phases in a strategic planning cycle."
      )
    ),
    fluidRow(
      .strategy_tool_card(
        "Strategy Diamond",
        "you want a complete, five-element view of a strategy: where to play, how to get there, how to win, sequencing, and returns.",
        "a radial wheel with exactly 5 fixed segments (Arenas, Vehicles, Differentiators, Staging, Economic Logic).",
        "\"Build a Strategy Diamond for our international expansion plan\"",
        "https://www.mindtools.com/a4gs53f/hambrick-and-fredricksons-strategy-diamond/",
        "MindTools' guide to Hambrick and Fredrickson's original 2001 model."
      ),
      box(title = "Still not sure?", status = "info", solidHeader = TRUE, width = 6,
          p("If you know the framework's name, just say it in your request - e.g. \"Build a SWOT for...\" - and ",
            "pick the matching Group + Framework from the dropdowns above. Claude fills in the content; the ",
            "Framework you pick fixes the exact structure.")
      )
    )
  )
}
