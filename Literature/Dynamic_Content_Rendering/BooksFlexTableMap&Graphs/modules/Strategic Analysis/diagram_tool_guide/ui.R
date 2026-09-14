# modules/Strategic Analysis/diagram_tool_guide/ui.R

# Small local helper - not exported, just keeps the 11 cards below
# consistent without repeating the same box/layout markup 11 times.
.strategy_tool_card <- function(name, when_to_use, examples, sample_request) {
  box(
    title = name, status = "primary", solidHeader = TRUE, width = 6,
    p(tags$strong("Use it when: "), when_to_use),
    p(tags$strong("Frameworks that fit this shape: "), examples),
    div(class = "example-box",
        h4("Try asking for it like this:"),
        p(tags$em(sample_request))
    )
  )
}

diagram_tool_guide_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Which Strategic Analysis diagram should I ask for?", status = "primary", solidHeader = TRUE, width = 12,
          p("Each entry below is one value of the ", tags$strong("Diagram Type"), " dropdown on the Generate ",
            "Diagram tab. Pick the one whose shape matches how the framework you have in mind is normally drawn - ",
            "Claude fills in the content, but the diagram's structure (how many cells, whether it has axes, ",
            "whether it's cyclic) comes from this choice, not from Claude guessing.")
      )
    ),

    fluidRow(
      .strategy_tool_card(
        "Grid (2D Framework)",
        "your framework divides into a small number of labeled cells arranged in a true rectangle of rows and columns.",
        "SWOT (2x2), PESTEL (2x3), a 3x3 canvas-style framework.",
        "\"Build a SWOT for whether we should enter the Brazilian market\" \u2192 Diagram Type = Grid"
      ),
      .strategy_tool_card(
        "2x2 Quadrant (with axes)",
        "two continuous dimensions position four labeled regions - unlike Grid, a Quadrant carries real axis meaning (an x-axis and a y-axis question), not just four independent boxes.",
        "BCG Growth-Share Matrix, Ansoff Matrix, Eisenhower Urgent/Important Matrix, VUCA.",
        "\"Map our product portfolio on a BCG growth-share matrix\" \u2192 Diagram Type = Quadrant"
      )
    ),
    fluidRow(
      .strategy_tool_card(
        "Matrix Table",
        "you need a genuine 2D matrix with BOTH row headers and column headers, not just a grid of independent cells.",
        "TOWS Matrix, VRIO Analysis, a RACI chart.",
        "\"Build a VRIO analysis of our core manufacturing technology\" \u2192 Diagram Type = Table"
      ),
      .strategy_tool_card(
        "Stacked / Ranked List",
        "you have a small ordered set of sequential or ranked items with no 2D structure needed.",
        "A prioritized initiatives list, the Purpose-of-Strategy pyramid, a ranked list of strategic options.",
        "\"List our top 5 strategic priorities for next year in priority order\" \u2192 Diagram Type = Stacked List"
      )
    ),
    fluidRow(
      .strategy_tool_card(
        "Linear Flow (process sequence)",
        "you need a left-to-right sequence of steps or stages - the emphasis is on ORDER, not on categorization.",
        "The Frame-Diagnose-Choose-Act decision process, a customer journey, the Ansoff growth path.",
        "\"Show the steps of our new product launch process\" \u2192 Diagram Type = Linear Flow"
      ),
      .strategy_tool_card(
        "Radial / Cyclic Wheel",
        "the framework is genuinely cyclic (it repeats) or has one central concept surrounded by elements arranged in a circle.",
        "A Strategic Planning Wheel, a PDCA-style continuous cycle, a stakeholder wheel.",
        "\"Build a strategic planning wheel with our 6 planning phases\" \u2192 Diagram Type = Radial"
      )
    ),
    fluidRow(
      .strategy_tool_card(
        "Hub-and-Spoke Network",
        "one central concept is affected by several surrounding factors that aren't purely sequential or cyclic.",
        "Porter's Five Forces (the industry is the hub, the five forces are the spokes), a stakeholder map, a force-field analysis.",
        "\"Build a Five Forces analysis of the airline industry\" \u2192 Diagram Type = Network"
      ),
      .strategy_tool_card(
        "Line Chart (trend over time)",
        "you need one or more continuous trends plotted against time or another continuous axis.",
        "The Disruptive Innovation curve (incumbent vs. disruptor performance over time), a market-share trend, an S-curve.",
        "\"Chart the disruptive innovation trajectory of streaming vs. cable TV\" \u2192 Diagram Type = Line Chart"
      )
    ),
    fluidRow(
      .strategy_tool_card(
        "Bar Chart (categorical comparison)",
        "you're comparing a metric across discrete categories or competitors, not tracking it over time.",
        "The Trend to Commoditization (price erosion by product generation), a competitor market-share comparison.",
        "\"Compare market share of the top 5 competitors in cloud computing\" \u2192 Diagram Type = Bar Chart"
      ),
      .strategy_tool_card(
        "Funnel (sequential drop-off)",
        "you're modelling a process where the population shrinks at each successive stage.",
        "The Economic Profit Mobility funnel, a sales or customer-acquisition funnel.",
        "\"Show our customer acquisition funnel from awareness to purchase\" \u2192 Diagram Type = Funnel"
      )
    ),
    fluidRow(
      .strategy_tool_card(
        "Dual-Axis Timeseries (diverging trends)",
        "you need two related but diverging series plotted over time - e.g. an opportunity trend against a risk/threat trend.",
        "The Active Waiting framework (opportunity window vs. risk window over time), strategic timing charts.",
        "\"Chart the opportunity and threat trajectory of entering autonomous vehicles now vs. later\" \u2192 Diagram Type = Dual-Axis Timeseries"
      ),
      box(title = "Still not sure?", status = "info", solidHeader = TRUE, width = 6,
          p("If your framework has a well-known conventional shape (most named business frameworks do), just tell ",
            "Claude the framework's name in your request - e.g. \"Build a SWOT for...\" or \"Build a Five Forces ",
            "analysis of...\" - and pick the Diagram Type from the table above that matches how that framework is ",
            "normally drawn. Claude fills in the content; the Diagram Type you pick fixes the shape.")
      )
    )
  )
}
