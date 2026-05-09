# Chapter 7: Overfitting — When to Think Less

chapter7_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(7,"\U0001f9e0","Overfitting",
      "The most sophisticated model is not always the best. Overfitting — learning the noise in your data instead of the signal — is the central failure mode of machine learning and human reasoning alike. The cure is not more data or more complexity, but principled simplification: regularisation, cross-validation, and Occam's Razor.",
      c("Bias-Variance Trade-off","Regularisation","Cross-Validation","Occam's Razor","Generalisation","Penalty for Complexity")),
    stats_row(list("Bias","Error from wrong assumptions"), list("Variance","Error from noise sensitivity"), list("Occam","Prefer simplest model"), list("CV","Honest evaluation method")),

    fluidRow(tabBox(width=12, id=ns("tabs"),
      tabPanel(title=tagList(icon("book")," Core Concepts"),
        fluidRow(
          box(title="\U0001f4c9 The Overfitting Problem", status="info", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("What is Overfitting?"),
                  tags$p("A model overfits when it learns the specific details of training data so well
                          that it fails to generalise to new data. It mistakes noise for signal.")),
              div(class="framework-card", tags$h5("The Classic Example"),
                  tags$p("Train a polynomial on 5 data points: a degree-4 polynomial perfectly fits all
                          5 points (zero training error) but oscillates wildly between them.
                          A simple linear fit has more training error but makes better predictions.")),
              div(class="framework-card", tags$h5("The Bias-Variance Dilemma"),
                  tags$p(tags$strong("Bias:")," systematic error from wrong model assumptions (too simple)"),
                  tags$p(tags$strong("Variance:")," error from sensitivity to noise in training data (too complex)"),
                  tags$p(tags$strong("Total error = Bias\u00b2 + Variance + Irreducible noise")),
                  tags$p("Increasing model complexity reduces bias but increases variance. There is an
                          optimal complexity that minimises total error.")),
              div(class="tip-box", HTML("<strong>\U0001f4a1 The key tension:</strong> A model complex enough to
                capture every training example will fail on new examples. The goal is not to remember
                the past perfectly, but to predict the future well."))),
          box(title="\u2696\ufe0f Solutions to Overfitting", status="warning", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("1. Regularisation"),
                  tags$p("Add a penalty for model complexity to the objective function:"),
                  tags$p(tags$code("Loss = Prediction Error + \u03bb \u00d7 Complexity")),
                  tags$p("Large \u03bb forces simplicity; small \u03bb allows complexity.
                          L1 (Lasso) regularisation drives small weights to zero (feature selection).
                          L2 (Ridge) shrinks all weights toward zero.")),
              div(class="framework-card", tags$h5("2. Cross-Validation"),
                  tags$p("Hold out some data for testing. Evaluate model on data it has NEVER seen.
                          K-fold CV: split data into K chunks; train on K-1, test on the remaining 1; repeat K times.")),
              div(class="framework-card", tags$h5("3. Early Stopping"),
                  tags$p("Stop training when validation error starts increasing, even if training error
                          is still decreasing. The gap between the two signals overfitting.")),
              div(class="framework-card", tags$h5("4. Occam's Razor"),
                  tags$p("Among models that explain the data equally well, prefer the simplest.
                          Formalised as Minimum Description Length (MDL): the best model is the one
                          that compresses the data most efficiently.")))
        ),
        fluidRow(
          box(title="\U0001f4ca Complexity vs Performance Trade-off", status="success", solidHeader=TRUE, width=12,
              fluidRow(
                column(6, algo_table(c("Model Complexity","Training Error","Test Error","Status"),
                  list(list("Too simple (high bias)","High","High","Underfitting"),
                       list("Just right","Low","Low","Good generalisation"),
                       list("Slightly too complex","Very low","Slightly higher","Mild overfitting"),
                       list("Too complex (high variance)","~0%","Very high","Severe overfitting"))),
                  div(class="info-box-plain", HTML("<strong>\u2139 The sweet spot:</strong> Optimal model complexity
                    is where validation error is minimised. This is NOT where training error is minimised."))),
                column(6, div(class="insight-box",
                    tags$p(class="ib-title","REGULARISATION INTUITION"),
                    tags$p("L1: pushes small weights to exactly 0 (sparse solutions, automatic feature selection)"),
                    tags$p("L2: pushes all weights toward 0 (smooth solutions, retains all features)"),
                    tags$p("Dropout: randomly disable neurons during training (ensemble of sub-networks)"),
                    tags$p("Early stopping: treat training epochs as the complexity parameter"),
                    tags$p("Data augmentation: create synthetic training examples to reduce variance"),
                    tags$p("Ensemble methods: average multiple models to reduce variance without increasing bias")))
              )
          )
        )
      ),
      tabPanel(title=tagList(icon("users")," Human Applications"),
        fluidRow(
          box(title="\U0001f9d0 Human Overfitting", status="danger", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("The Hot Hand Fallacy"),
                  tags$p("Basketball fans and players believe in 'hot hands': that a player who made
                          their last few shots is more likely to make the next one. Statistical analysis
                          (Gilovich et al.) found the pattern is consistent with pure chance."),
                  tags$p("We overfit to short runs of data, seeing patterns where there are none.")),
              div(class="framework-card", tags$h5("Superstitions as Overfitting"),
                  tags$p("Superstitions arise when we fit complex models (rituals, lucky charms) to
                          small datasets (a few coincidences). The model has many parameters (the specific
                          ritual) but very few data points (rare events).")),
              div(class="framework-card", tags$h5("Political / Social Generalisations"),
                  tags$p("Meeting 3 rude people from City X and concluding 'people from City X are rude'
                          is severe overfitting: 3 samples, millions of people.
                          The model complexity far exceeds what the data justifies."))),
          box(title="\U0001f3af When Simple Models Win", status="success", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("Gerd Gigerenzer's Fast and Frugal Heuristics"),
                  tags$p("Research shows that simple decision rules often outperform complex statistical
                          models in noisy real-world domains:"),
                  tags$ul(tags$li(tags$strong("Take the best:")," use the single most predictive cue, ignore others"),
                          tags$li(tags$strong("Recognition heuristic:")," prefer the recognised option"),
                          tags$li(tags$strong("Tallying:")," count the number of cues favouring each option"))),
              div(class="framework-card", tags$h5("Why Experts Use Rules of Thumb"),
                  tags$p("Experienced doctors, firefighters, and military officers often use simple
                          heuristics rather than systematic analysis. In complex, noisy environments,
                          these simple rules beat elaborate models because they're less sensitive to noise.")),
              pull_quote("Sometimes the right answer is to use less information, not more. The model that wins is often the simplest one that's consistent with the data.",
                         "Christian & Griffiths"))
        )
      ),
      tabPanel(title=tagList(icon("lightbulb")," Key Insights"),
        fluidRow(
          box(title="\U0001f4a1 Core Takeaways", status="warning", solidHeader=TRUE, width=6,
              div(class="insight-box", tags$p(class="ib-title","COMPLEXITY IS NOT ACCURACY"),
                  tags$p("More parameters, more features, more analysis does not guarantee better
                          predictions. In noisy environments, complexity often hurts. The optimal
                          model is the simplest one consistent with the evidence.")),
              div(class="insight-box", tags$p(class="ib-title","TRAINING IS NOT TESTING"),
                  tags$p("How well you perform in practice (test error) matters, not how well you
                          memorise past cases (training error). Ask: how does my policy perform
                          on situations I haven't encountered?")),
              div(class="insight-box", tags$p(class="ib-title","REGULARISE YOUR BELIEFS"),
                  tags$p("Add a penalty for elaborate explanations. When someone proposes a complex
                          conspiracy theory vs a simple explanation, the complexity itself is evidence
                          against it (Occam's Razor as Bayesian prior)."))),
          box(title="\u2705 Practical Anti-Overfitting", status="success", solidHeader=TRUE, width=6,
              algo_table(c("Domain","Overfitting risk","Remedy"),
                list(list("Investing","Curve-fitting past returns","Simple index funds outperform"),
                     list("Medical diagnosis","Over-investigation","Consider base rates; Occam first"),
                     list("Management","Complex processes","Simple rules often work better"),
                     list("Sports strategy","Over-coaching","Trust athlete instincts in the moment"),
                     list("Relationships","Over-analysis","Simple rules: honesty, consistency"),
                     list("Scientific research","p-hacking","Pre-registration; cross-validation"),
                     list("Machine learning","Deep overfitting","Regularisation; validation set"))))
        )
      )
    ))
  )
}
chapter7_server <- function(id) moduleServer(id, function(input,output,session){})
