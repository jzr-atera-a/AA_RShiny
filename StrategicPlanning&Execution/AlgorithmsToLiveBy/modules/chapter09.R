# Chapter 9: Randomness — When to Leave It to Chance

chapter9_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(9,"\U0001f3b2","Randomness",
      "Randomness seems like the opposite of intelligence — but computer science has discovered that injecting randomness into algorithms often makes them faster, more robust, and provably near-optimal. From breaking deadlock to escaping local optima, chance is a powerful computational tool.",
      c("Simulated Annealing","Monte Carlo Methods","Randomised Algorithms","Local Search","Bloom Filters","Las Vegas vs Monte Carlo")),
    stats_row(list("SA","Global optimum finder"), list("Monte Carlo","Estimation by sampling"), list("~37%","Bloom filter collision rate"), list("Cooling","SA temperature schedule")),

    fluidRow(tabBox(width=12, id=ns("tabs"),
      tabPanel(title=tagList(icon("book")," Core Concepts"),
        fluidRow(
          box(title="\U0001f321\ufe0f Simulated Annealing", status="info", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("The Inspiration"),
                  tags$p("In metallurgy, annealing heats metal to a high temperature (allowing atoms to move freely),
                          then slowly cools it so atoms settle into a low-energy (near-optimal) crystal structure."),
                  tags$p("Simulated Annealing applies the same idea to optimisation:")),
              timeline_strip(
                list("High Temperature","Accept almost any move (explore widely)"),
                list("Cooling","Gradually reduce acceptance probability"),
                list("Medium Temp","Accept improvements; sometimes accept worse"),
                list("Low Temp","Only accept improvements (exploit local best)"),
                list("Frozen","Converge to near-global optimum")
              ),
              div(class="framework-card", tags$h5("The Key Formula"),
                  tags$p("At temperature T, accept a worse solution with probability:"),
                  tags$p(tags$code("P(accept worse) = exp(-\u0394E / T)")),
                  tags$p("Where \u0394E is how much worse the solution is. High T = accept almost anything.
                          Low T = almost never accept worse solutions.")),
              div(class="success-box", HTML("<strong>\u2705 Why it works:</strong> By occasionally accepting worse solutions,
                SA escapes local optima \u2014 the fundamental failure mode of greedy local search."))),
          box(title="\U0001f3b2 Monte Carlo Methods", status="warning", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("Estimation by Random Sampling"),
                  tags$p("Instead of computing exact answers, use random sampling to estimate them.
                          Accuracy improves as O(1/\u221aN) with N samples \u2014 slow but universal.")),
              algo_table(c("Application","Monte Carlo approach","Accuracy"),
                list(list("Estimating \u03c0","Random points in unit square; count inside unit circle","3.14... with N=10,000"),
                     list("Financial risk","Simulate thousands of market scenarios","VaR, expected shortfall"),
                     list("Drug trials","Random patient assignment","Unbiased treatment effect"),
                     list("Game tree search","Random playouts from a position (MCTS)","AlphaGo, modern chess engines"),
                     list("Physics simulation","Random walk for heat/fluid simulation","Faster than exact PDE"),
                     list("Integration","Evaluate integrand at random points","Handles high dimensions well"))),
              div(class="tip-box", HTML("<strong>\U0001f4a1 The power of sampling:</strong> Monte Carlo can estimate
                properties of distributions too complex to compute analytically. The error shrinks as
                1/\u221aN regardless of dimension \u2014 unlike numerical methods that degrade in high dimensions.")))
        ),
        fluidRow(
          box(title="\U0001f9e0 Why Randomness Beats Determinism (Sometimes)", status="success", solidHeader=TRUE, width=12,
              fluidRow(
                column(4, div(class="framework-card", tags$h5("Breaking Symmetry"),
                    tags$p("Two equally good options, deterministic tiebreaking: always picks the same one.
                            Random tiebreaking: distributes load evenly."),
                    tags$p("Application: distributed systems, load balancers, collision resolution in hash tables \u2014
                            randomness prevents systematic worst cases.")),
                  div(class="framework-card", tags$h5("Adversarial Resistance"),
                    tags$p("Deterministic algorithms can be exploited by adversaries who know the algorithm.
                            Randomised algorithms cannot be systematically attacked because their behaviour
                            is unpredictable (e.g. randomised hash functions, shuffled decks)."))),
                column(4, div(class="framework-card", tags$h5("Local vs Global Optima"),
                    tags$p("Greedy algorithms (always improve) get stuck in local optima.
                            Random restarts or simulated annealing escape by occasionally moving uphill."),
                    tags$p("Examples: protein folding, scheduling, TSP, neural network training
                            (stochastic gradient descent with random mini-batches).")),
                  div(class="framework-card", tags$h5("The Coupon Collector Problem"),
                    tags$p("To collect all N unique coupons by random selection takes O(N log N) draws on average.
                            This appears in sampling, coverage testing, and distributed coordination problems."))),
                column(4, div(class="insight-box",
                    tags$p(class="ib-title","LAS VEGAS vs MONTE CARLO"),
                    tags$p(tags$strong("Las Vegas:"), " always correct, randomly fast. (Randomised Quicksort: same result every time, but running time varies.)"),
                    tags$p(tags$strong("Monte Carlo:"), " always fast, randomly correct. (Fermat primality test: sometimes wrong, always quick.)"),
                    tags$p("Prefer Las Vegas when correctness is essential."),
                    tags$p("Use Monte Carlo when approximation is acceptable.")))
              )
          )
        )
      ),
      tabPanel(title=tagList(icon("users")," Human Applications"),
        fluidRow(
          box(title="\U0001f4b0 Financial & Decision Making", status="danger", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("Random Portfolios"),
                  tags$p("Research by DeMiguel et al. (2009) found that the", tags$strong("equally-weighted portfolio"),
                          "(1/N rule, essentially random allocation) outperformed sophisticated mean-variance
                          optimised portfolios in 14 out of 15 datasets.")),
              div(class="framework-card", tags$h5("Diversification as Randomness"),
                  tags$p("Not concentrating resources in your best-guess option is a form of randomisation.
                          It protects against model error (overfitting your predictions to past data).")),
              pull_quote("The stock market is hard enough that sometimes the smartest thing to do is to pick randomly.",
                         "Christian & Griffiths")),
          box(title="\U0001f9d8 Annealing Your Life", status="success", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("The Human Version"),
                  tags$p("Simulated annealing applied to life: when young (high temperature), explore wildly \u2014
                          take risks, try new things, accept worse outcomes for the sake of learning.
                          As you age (cooling), focus on what works and settle into a satisfying optimum.")),
              div(class="framework-card", tags$h5("Breaking Deadlock"),
                  tags$p("When two people (or teams) are stuck in negotiation, introducing randomness
                          (a coin flip, a random idea generator) can break symmetry and move the conversation forward.")),
              div(class="framework-card", tags$h5("Random Exploration"),
                  tags$p("The explore/exploit chapter (ch. 2) recommends exploration. Randomised exploration
                          (picking randomly among unfamiliar options) avoids the deterministic trap of always
                          picking the same familiar 'second choice'.")))
        )
      ),
      tabPanel(title=tagList(icon("lightbulb")," Key Insights"),
        fluidRow(
          box(title="\U0001f4a1 Core Takeaways", status="warning", solidHeader=TRUE, width=6,
              div(class="insight-box", tags$p(class="ib-title","RANDOMNESS ESCAPES LOCAL OPTIMA"),
                  tags$p("Deterministic improvement can only go downhill to a valley. Random moves
                          can go uphill to find the highest peak. In complex landscapes, this advantage
                          is decisive.")),
              div(class="insight-box", tags$p(class="ib-title","APPROXIMATE IS OFTEN OPTIMAL"),
                  tags$p("For complex real-world problems, exact solutions are computationally intractable.
                          Monte Carlo methods and simulated annealing find near-optimal solutions efficiently.
                          'Good enough fast' beats 'perfect eventually'.")),
              div(class="insight-box", tags$p(class="ib-title","HIGH TEMPERATURE = YOUTH"),
                  tags$p("The annealing metaphor is profound: explore broadly when young, exploit when mature.
                          But also: when stuck (local optimum in your career, relationship, project),
                          deliberately raise your 'temperature' \u2014 inject randomness to escape."))),
          box(title="\u2705 When to Use Randomness", status="success", solidHeader=TRUE, width=6,
              algo_table(c("Situation","Randomness strategy","Why"),
                list(list("Stuck in a local optimum","Simulated annealing restart","Escape local trap"),
                     list("Symmetric choices","Random tiebreaking","Prevent systematic bias"),
                     list("Complex estimation","Monte Carlo sampling","Easier than analytic solution"),
                     list("Adversarial setting","Randomise your algorithm","Prevent exploitation"),
                     list("Exploration need","Random choice among unknowns","Avoid systematic bias in exploration"),
                     list("Portfolio allocation","1/N diversification","Protection against model error"),
                     list("Breaking deadlock","Coin flip","Remove ego from tiebreaking"))))
        )
      )
    ))
  )
}
chapter9_server <- function(id) moduleServer(id, function(input,output,session){})
