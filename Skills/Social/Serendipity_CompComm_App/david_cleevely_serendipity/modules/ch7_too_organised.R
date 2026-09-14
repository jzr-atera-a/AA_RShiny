# modules/ch7_too_organised.R
# Chapter 7: Too Well Organised To Adapt

ch7_too_organised_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "aa-hero",
        tags$h1("Chapter 7"),
        tags$h2("Too Well Organised To Adapt"),
        div(
          span(class = "hero-badge", icon("sitemap"),   " Optimisation"),
          span(class = "hero-badge", icon("gauge-high"),  " Efficiency vs Resilience"),
          span(class = "hero-badge", icon("shield-halved"), " The Cost of Control")
        )
    ),

    fluidRow(
      box(title = "Chapter 7 - Overview", status = "primary", solidHeader = TRUE, width = 12,
          p("Cleevely turns his attention to organisations that have optimised themselves almost perfectly for ",
            "predictable, repeatable performance - and asks what they gave up to get there. Chapter 7's argument: ",
            "every process designed to remove variance and increase efficiency also removes some of the organisation's ",
            "capacity to notice and respond to something genuinely unexpected."),
          fluidRow(
            column(3, metric_card("\u2699\ufe0f", "Optimised for the Known")),
            column(3, metric_card("\U0001f9ee", "Variance Removal")),
            column(3, metric_card("\U0001f9f1", "Slack as an Asset")),
            column(3, metric_card("\u2696\ufe0f", "A Deliberate Trade-off"))
          )
      )
    ),

    fluidRow(
      box(title = NULL, status = "primary", solidHeader = FALSE, width = 12,
        tabsetPanel(
          id = ns("tabs"),

          tabPanel("\U0001f4da General Concepts",
            br(),
            fluidRow(
              column(6,
                sh("Optimised for the Known Problem"),
                concept_card("Every Efficiency Gain Has a Direction",
                  "An organisation that streamlines a process is, almost by definition, optimising for the problems it already knows how to solve. That's valuable - but it quietly narrows the organisation's attention and resources away from anything that doesn't fit the existing process."),
                concept_card("The Six Sigma Trap",
                  "Cleevely points to highly process-driven management philosophies as an extreme case: relentless variance reduction produces superb consistency on known metrics, while making an organisation structurally less able to recognise - let alone act on - an anomaly that falls outside the measured process entirely."),
                sh("Slack as an Asset, Not Waste"),
                concept_card("Why 'Inefficient' Slack Time Pays Off",
                  "Unallocated time, budget or attention looks like waste on a spreadsheet. Cleevely's argument is that this slack is exactly where serendipitous discovery has room to happen - a fully-booked organisation, in the name of efficiency, has removed the space in which an employee could notice and chase an unplanned opportunity.")
              ),
              column(6,
                sh("A Deliberate Trade-off, Not a Mistake"),
                concept_card("Efficiency and Adaptability Pull in Opposite Directions",
                  "Chapter 7 doesn't argue that optimisation is wrong - a hospital, an airline or a factory genuinely needs predictable, repeatable process. The point is that this is a real trade-off, not a free lunch: every unit of efficiency gained typically costs some unit of adaptive capacity, and most organisations make that trade unconsciously rather than deliberately."),
                concept_card("Knowing Where on the Curve You Want to Sit",
                  "The practical task for a leader, per Cleevely, isn't to abolish process - it's to consciously decide which parts of the organisation need to sit near the efficient end of the spectrum, and which parts need to be deliberately left looser, so the organisation retains some genuine capacity to notice and respond to the unexpected."),
                div(class = "success-box",
                    tags$strong("\u2705 Chapter 7 takeaway: "),
                    "Treat efficiency and adaptability as a dial to be set deliberately, not a scale to be maximised - ",
                    "over-optimising every part of an organisation quietly destroys its capacity for useful surprise.")
              )
            )
          ),

          tabPanel("\U0001f39b\ufe0f Interactive",
            br(),
            fluidRow(
              column(12,
                shg("The Efficiency \u2194 Adaptability Dial"),
                p(style = "font-size:12.5px;color:#546e7a;",
                  "Move the slider to explore the trade-off Chapter 7 describes. There's no 'correct' setting - the ",
                  "book's point is that most organisations drift toward one end without ever deciding to."),
                viz_box(ns("org-gauge"), height = 190,
                        controls = viz_slider(ns("org-slider"), "Organisational setting", 0, 100, 50,
                          sprintf("SerendipityGauge.update(this.value); document.getElementById('%s').textContent = this.value;", ns("org-slider-val")))),
                div(class = "gauge-readout",
                    span(class = "gr-label", "What this setting means"),
                    tags$p(id = ns("gauge-text"),
                           "A balanced organisation - some process, some deliberate looseness.")),
                d3_init(sprintf("
                  var gauge = SerendipityViz.gaugeDial('%s', {
                    min:0, max:100, startValue:50, leftLabel:'Adaptable / loose', rightLabel:'Efficient / rigid',
                    onUpdate: function(v) {
                      var el = document.getElementById('%s');
                      if (v < 25) el.textContent = 'Highly adaptable, low process - fast to notice the unexpected, but inconsistent and hard to scale.';
                      else if (v < 45) el.textContent = 'Loosely organised - good at spotting anomalies, some inefficiency in day-to-day delivery.';
                      else if (v < 65) el.textContent = 'A workable balance - enough process to deliver reliably, enough slack to still notice surprises.';
                      else if (v < 85) el.textContent = 'Highly optimised - excellent, predictable delivery, but anomalies increasingly get filtered out as noise.';
                      else el.textContent = 'Too well organised to adapt - every process is tuned for the known problem; the unexpected has nowhere to land.';
                    }
                  });
                  window.SerendipityGauge = gauge;
                ", ns("org-gauge"), ns("gauge-text")))
              )
            )
          ),

          tabPanel("\U0001f3e2 Applicability on Atera Analytics",
            br(),
            fluidRow(
              column(6,
                shg("The Risk as Atera Scales Toward Milestone Delivery"),
                app_card("Grant Reporting Pulls Toward Rigidity",
                  "Innovate UK milestone reporting rewards predictability: clear deliverables, fixed dates, quantified outcomes. That's appropriate for accountability - but Chapter 7's warning is that if this reporting discipline bleeds into how the whole engineering team works day to day, Atera risks optimising itself out of the ability to notice an unplanned pivot opportunity, the way its own founding conversations once produced."),
                app_card("Watching for the Early Signs",
                  "A warning sign worth tracking: if engineers stop mentioning unplanned observations in standups, or if every sprint is now fully allocated to milestone deliverables with zero slack, Atera has likely drifted further toward the rigid end of the dial than anyone consciously decided.")
              ),
              column(6,
                shg("Deliberately Setting the Dial, Not Drifting Into It"),
                app_card("Ring-Fencing Genuine Slack",
                  "A concrete, low-risk step: protect a fixed small percentage of engineering time (Chapter 7's 'slack') explicitly for exploring anomalies or side ideas that don't map to the current milestone plan - reviewed lightly, not micromanaged, so it retains its adaptive value."),
                app_card("Splitting the Organisation Deliberately",
                  "Rather than trying to keep the whole company loosely organised (which would hurt milestone delivery) or the whole company tightly optimised (which would hurt Atera's ability to spot the next opportunity), consciously split it: a disciplined delivery core for grant milestones, and a small, deliberately looser exploration function that reports in but isn't bound by the same process."),
                div(class = "success-box",
                    tags$strong("\u2705 Chapter 7 action point: "),
                    "At the next leadership review, explicitly set - and write down - where on the efficiency/adaptability ",
                    "dial each team should sit, rather than letting milestone pressure decide it by default.")
              )
            )
          )
        )
      )
    )
  )
}

ch7_too_organised_server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {})
}
