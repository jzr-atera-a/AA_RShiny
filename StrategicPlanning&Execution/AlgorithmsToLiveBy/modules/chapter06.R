# Chapter 6: Bayes' Rule — Predicting the Future

chapter6_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(6,"\U0001f52e","Bayes' Rule",
      "Every prediction we make combines what we already believe with new evidence. Bayes' Rule is the mathematically correct way to do this — and it reveals why human intuition is systematically wrong in predictable ways. From medical diagnosis to life expectancy to judging strangers, Bayesian reasoning changes everything.",
      c("Prior & Posterior","Laplace's Law","Copernican Principle","Base Rate Neglect","Bayesian Updating")),
    stats_row(list("P(A|B)","Posterior probability"), list("Prior","Belief before evidence"), list("Likelihood","Evidence strength"), list("1/(N+2)","Laplace estimate")),

    fluidRow(tabBox(width=12, id=ns("tabs"),
      tabPanel(title=tagList(icon("book")," Core Concepts"),
        fluidRow(
          box(title="\U0001f9ea Bayes' Rule Explained", status="info", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("The Formula"),
                  tags$p(tags$code("P(hypothesis | evidence) = P(evidence | hypothesis) \u00d7 P(hypothesis) / P(evidence)")),
                  tags$ul(tags$li(tags$strong("Prior P(H):")," probability of hypothesis before seeing evidence"),
                          tags$li(tags$strong("Likelihood P(E|H):")," how probable the evidence is IF hypothesis is true"),
                          tags$li(tags$strong("Evidence P(E):")," overall probability of seeing this evidence"),
                          tags$li(tags$strong("Posterior P(H|E):")," updated belief after seeing evidence"))),
              div(class="framework-card", tags$h5("The Medical Diagnosis Example"),
                  tags$p("A test for a rare disease (1 in 1000 prevalence) has 99% accuracy.
                          You test positive. What's the probability you have the disease?"),
                  tags$p(tags$strong("Most people say: 99%")),
                  tags$p(tags$strong("Bayes says: ~9%")),
                  tags$p("Why? In 100,000 people: 100 have the disease (99 test positive), 99,900 don't
                          (999 test false-positive). Out of 1,098 positive tests, only 99 are true positives: 99/1098 \u2248 9%.")),
              div(class="warn-box", HTML("<strong>\u26a0 Base rate neglect:</strong> The most common error in
                probabilistic reasoning. We focus on the accuracy of the test (99%) and ignore the rarity
                of the condition (0.1%). The prior dominates when evidence is weak."))),
          box(title="\U0001f4ca Prior Distributions & Predictions", status="warning", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("Laplace's Rule of Succession"),
                  tags$p("If something has happened k times out of n trials, your best estimate of
                          future probability is:"),
                  tags$p(tags$code("P(success) = (k + 1) / (n + 2)")),
                  tags$p("This is the Bayesian answer with a uniform prior. It gracefully handles
                          both 0 observations (predicts 50%) and many observations.")),
              algo_table(c("Observation","Laplace Estimate","Intuitive Estimate"),
                list(list("0 successes from 0 trials","1/2 = 50%","Undefined"),
                     list("1 success from 1 trial","2/3 = 67%","100%"),
                     list("1 success from 2 trials","2/4 = 50%","50%"),
                     list("9 successes from 10 trials","10/12 = 83%","90%"),
                     list("99 successes from 100 trials","100/102 = 98%","99%"),
                     list("999 successes from 1000 trials","1000/1002 \u2248 99.8%","99.9%"))),
              div(class="info-box-plain", HTML("<strong>\u2139 Why Laplace?</strong>
                A new airline with 1 perfect flight shouldn't be trusted as much as one with 1000.
                Laplace automatically weights by sample size.")))
        ),
        fluidRow(
          box(title="\U0001f30e The Copernican Principle", status="success", solidHeader=TRUE, width=12,
              fluidRow(
                column(4, div(class="framework-card", tags$h5("The Principle"),
                    tags$p("Nicolaus Copernicus argued that Earth is not at a special place in the universe.
                            Applied to time: if you observe something at a random moment of its existence,
                            you are probably near the middle, not the beginning or end."),
                    tags$p("Mathematically: if something has existed for T years, its expected total lifespan is
                            between T and 4T (with 95% confidence)."))),
                column(4, algo_table(c("How long running","Predicted remaining","Total lifespan"),
                  list(list("1 day","1 to 4 days","2 to 5 days"),
                       list("1 month","1 to 4 months","2 to 5 months"),
                       list("1 year","1 to 4 years","2 to 5 years"),
                       list("10 years","10 to 40 years","20 to 50 years"),
                       list("100 years","100 to 400 years","200 to 500 years")))),
                column(4, div(class="framework-card", tags$h5("Applications"),
                    tags$ul(tags$li("A play that has been running for 2 months will likely run 1\u20138 more months"),
                            tags$li("A company that has existed for 20 years will likely exist 20+ more"),
                            tags$li("A relationship of 5 years is more likely to last than one of 5 months"),
                            tags$li("A meeting scheduled for 1 hour that started 30 min ago will likely end in 15-60 min"))),
                    div(class="tip-box", HTML("<strong>\U0001f4a1 Caution:</strong> The Copernican Principle assumes
                      you are a random observer. If you specifically selected the thing at its beginning, the analysis changes.")))
              )
          )
        )
      ),
      tabPanel(title=tagList(icon("users")," Human Applications"),
        fluidRow(
          box(title="\U0001f3e5 Medical Reasoning", status="danger", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("Why Doctors Must Think Bayesian"),
                  tags$p("Symptoms have many possible causes. The probability of a rare disease causing
                          a common symptom is very different from the probability of a common disease
                          causing the same symptom.")),
              div(class="framework-card", tags$h5("The Screening Paradox"),
                  tags$p("Screening healthy populations for rare diseases produces mostly false positives.
                          This is mathematically inevitable \u2014 not a failure of the test."),
                  tags$p("Solution: test high-risk populations where the prior is higher, or use
                          sequential testing (each positive test updates the prior for the next test).")),
              pull_quote("In medicine as in law, you must think about the prior before evaluating the evidence.",
                         "Christian & Griffiths")),
          box(title="\U0001f4ac Everyday Bayesian Reasoning", status="success", solidHeader=TRUE, width=6,
              algo_table(c("Situation","Prior","Evidence","Updated belief"),
                list(list("Will meeting overrun?","Past meetings run 10% over","It's already 5 min over","Increase probability significantly"),
                     list("Is restaurant good?","Yelp: 4.2 stars (200 reviews)","Friend says 'meh'","Slight downward adjustment"),
                     list("Project timeline","Historical 30% delay rate","Early tasks are on time","Modest improvement in confidence"),
                     list("Interview candidate","Base rate: 10% hire rate","Strong CV","Update to perhaps 25-30%"),
                     list("Traffic jam","Rush hour = likely jam","App says 20 min delay","High confidence delay is real"))),
              div(class="info-box-plain", HTML("<strong>\u2139 The rule for updating beliefs:</strong>
                New evidence should <em>move</em> your beliefs, not <em>replace</em> them.
                The stronger your prior, the more evidence needed to change it significantly.")))
        )
      ),
      tabPanel(title=tagList(icon("lightbulb")," Key Insights"),
        fluidRow(
          box(title="\U0001f4a1 Core Takeaways", status="warning", solidHeader=TRUE, width=6,
              div(class="insight-box", tags$p(class="ib-title","START WITH THE BASE RATE"),
                  tags$p("Before evaluating any specific evidence, ask: how common is this in general?
                          The prior probability often overwhelms even strong evidence when the base
                          rate is very low (or very high).")),
              div(class="insight-box", tags$p(class="ib-title","SMALL SAMPLES MISLEAD"),
                  tags$p("After 3 positive experiences, your 'evidence' is weak. Laplace's rule
                          automatically gives small samples low weight. Resist updating beliefs
                          strongly on single observations.")),
              div(class="insight-box", tags$p(class="ib-title","PRIORS ARE NOT PREJUDICE"),
                  tags$p("Using prior probabilities is rational, not biased. The error is using
                          wrong priors (stereotypes, false base rates) or refusing to update them
                          when evidence arrives."))),
          box(title="\u2705 Bayesian Life Rules", status="success", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("Good Bayesian Habits"),
                  tags$ol(tags$li("Always ask: what's the base rate?"),
                          tags$li("Weight evidence by sample size (Laplace)"),
                          tags$li("Update beliefs proportionally to evidence strength"),
                          tags$li("Don't overcorrect on single dramatic events"),
                          tags$li("Remember: absence of evidence is weak evidence of absence"),
                          tags$li("When predicting duration, start with the Copernican prior"))),
              div(class="framework-card", tags$h5("When Bayesian Reasoning Breaks Down"),
                  tags$ul(tags$li("Wrong prior: if your starting beliefs are very wrong, evidence may not be enough"),
                          tags$li("Misestimated likelihood: overconfident in test accuracy"),
                          tags$li("Confirmation bias: selectively seeking confirming evidence"),
                          tags$li("Anchoring: first evidence dominates; subsequent evidence under-weighted"))))
        )
      )
    ))
  )
}
chapter6_server <- function(id) moduleServer(id, function(input,output,session){})
