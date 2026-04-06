# modules/ml_design_feedback_1.R
# FEEDBACK TAB
ml_design_feedback_1_ui <- function(id) {
  ns <- NS(id)
  tagList(

    div(class="feedback-hero",
        tags$h1("ML Design Interview I — Previous Round Feedback"),
        tags$h2("Solid Performance — One Clear Path to Stand Out"),
        div(
          span(class="hero-badge","Round: Design 1"),
          span(class="hero-badge","Rating: Good"),
          span(class="hero-badge","Gap: One Area to Excel"),
          span(class="hero-badge","Reuse This Performance")
        )
    ),
    fluidRow(
      box(title="What Went Well", status="success", solidHeader=TRUE, width=6,
        div(class="strength-card",
          tags$h4("Solid Performance Across All Focus Areas"),
          tags$p("The interviewer confirmed you demonstrated solid skills across all the assessed focus areas in this session."),
          tags$ul(
            tags$li(tags$b("Problem understanding:"), " You clearly grasped what was being asked and structured the problem correctly from the start."),
            tags$li(tags$b("Reasonable solutions:"), " Your proposed architecture was sound and defensible. The components were appropriate and the data flow made sense."),
            tags$li(tags$b("Coverage:"), " You addressed the main dimensions — data, features, model, serving — without major gaps.")
          )
        ),
        div(class="insight-card",
          tags$h5("This Is a Strong Baseline"),
          tags$p("Most candidates do not hit 'solid across all focus areas.' This is a genuine positive. The interviewer explicitly noted it. Do not change what you did here — build on it.")
        )
      ),
      box(title="The One Growth Area", status="warning", solidHeader=TRUE, width=6,
        div(class="growth-card",
          tags$h4("Did Not Stand Out in Any Single Area"),
          tags$p("The feedback: they were looking for you to excel or stand out in at least one focus area — significant creativity, innovation, or deep domain expertise."),
          tags$p(tags$b("What 'standing out' looks like:"),
            tags$ul(
              tags$li(tags$b("Creativity:"), " An unexpected approach that clearly works better than the obvious solution. E.g., using contrastive learning where others would use classification."),
              tags$li(tags$b("Innovation:"), " Referencing a recent paper or technique that directly applies and explaining why. E.g., 'DPO instead of RLHF reduces training instability here.'"),
              tags$li(tags$b("Deep expertise:"), " Going significantly deeper on one subsystem than expected. E.g., not just 'feature store' but exact Redis key schema, TTL strategy, and eviction policy.")
            )
          )
        ),
        div(class="action-card",
          tags$h5("How to Create a Standout Moment"),
          tags$p("Pick ONE area per design interview where you will go exceptionally deep. For your background:"),
          tags$ul(
            tags$li("On-device inference design — you have built this. Go 2x deeper than anyone expects."),
            tags$li("Sensor fusion architecture — cite your Atera/USyd experience with specific technical details."),
            tags$li("Feature store design — describe the offline/online dual-store pattern from memory, not textbook.")
          )
        )
      )
    ),
    fluidRow(
      box(title="Standout Moment Template", status="primary", solidHeader=TRUE, width=12,
        div(class="framework-card",
          tags$h5("How to Insert a Standout Moment Naturally"),
          tags$p("When you reach the component where you have deep expertise, signal it explicitly:"),
          div(class="insight-card",
            tags$p(tags$b("Example:"), " 'For the on-device inference layer, I have direct production experience with this on Meta Quest hardware at Atera. Let me go deeper here than the standard answer. We use INT8 quantisation with dynamic range calibration, which gives us a 4x memory reduction with less than 1% accuracy degradation on our benchmark. The key insight is that activation quantisation is more important than weight quantisation for latency on ARM NPU...'"),
            tags$p("This is a standout moment. The interviewer stops taking notes and leans in.")
          )
        )
      )
    )

  )
}
ml_design_feedback_1_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    prep_manager$update_progress("ml_design_feedback_1", 30)
  })
}
