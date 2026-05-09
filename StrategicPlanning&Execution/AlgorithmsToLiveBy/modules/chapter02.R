# Chapter 2: Explore/Exploit — The Latest vs. the Greatest

chapter2_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(2,"\U0001f3b0","Explore/Exploit",
      "Should you try the new restaurant or return to your favourite? Should a doctor try a new treatment or stick with the proven one? Computer science frames this as the multi-armed bandit problem — and the answers are both mathematically precise and deeply counterintuitive.",
      c("Multi-Armed Bandit","Explore vs Exploit","Upper Confidence Bound","Gittins Index","Regret Minimisation")),
    stats_row(
      list("UCB","Optimal strategy"),
      list("Win-Stay","Lose-Shift rule"),
      list("\u221e","Arms in the wild"),
      list("Youth","Time to explore")
    ),

    fluidRow(tabBox(width=12, id=ns("tabs"),

      tabPanel(title=tagList(icon("book")," The Problem"),
        fluidRow(
          box(title="\U0001f3b0 The Multi-Armed Bandit", status="info", solidHeader=TRUE, width=6,
              div(class="framework-card",
                  tags$h5("The Classic Setup"),
                  tags$p("Imagine a row of slot machines (one-armed bandits), each with a different
                          unknown payout rate. You have a fixed number of pulls. How do you maximise
                          your total winnings?"),
                  tags$ul(
                    tags$li(tags$strong("Explore:")," Pull a new or uncertain machine to learn its payout rate"),
                    tags$li(tags$strong("Exploit:")," Pull the machine you currently believe is best")
                  )),
              div(class="framework-card",
                  tags$h5("The Fundamental Tension"),
                  tags$p("Every pull spent exploring is a pull NOT spent earning from your best-known machine.
                          Every pull spent exploiting is a pull NOT spent discovering a potentially better machine."),
                  tags$p("This dilemma appears everywhere: clinical trials, A/B testing, job hunting,
                          restaurant choice, investment portfolios.")),
              div(class="warn-box",
                  HTML("<strong>\u26a0 The exploration penalty:</strong> If you explore too little, you may
                        exploit a sub-optimal option forever. If you explore too much, you waste pulls on
                        bad options when you already know a good one."))),

          box(title="\U0001f4ca Strategies Compared", status="warning", solidHeader=TRUE, width=6,
              algo_table(
                c("Strategy","How it works","Strength","Weakness"),
                list(
                  list("Greedy","Always exploit current best","Zero wasted pulls","May never find global best"),
                  list("\u03b5-Greedy","Explore \u03b5% of time randomly","Simple, tunable","Wastes pulls even when confident"),
                  list("Win-Stay Lose-Shift","If last pull paid, repeat; else switch","Intuitive","Slow convergence"),
                  list("UCB","Explore options whose uncertainty is high","Principled, regret-optimal","More complex"),
                  list("Thompson Sampling","Sample from probability beliefs","Bayesian, natural","Requires probability model"),
                  list("Gittins Index","Optimal for discounted rewards","Provably optimal","Computationally expensive")
                )
              ),
              div(class="success-box",
                  HTML("<strong>\u2705 Upper Confidence Bound (UCB):</strong> Pull the arm with the highest
                        <em>potential</em> payoff (current estimate + confidence bonus for uncertainty).
                        This naturally balances exploration and exploitation.")))
        ),
        fluidRow(
          box(title="\U0001f9ea The UCB Algorithm in Detail", status="success", solidHeader=TRUE, width=12,
              fluidRow(
                column(6,
                  div(class="framework-card",
                      tags$h5("UCB Formula"),
                      tags$p("For each arm i, compute:"),
                      tags$p(tags$code("score(i) = estimated_value(i) + C \u00d7 \u221a(log(total_pulls) / pulls_on_i)")),
                      tags$p("The second term is the",tags$strong("exploration bonus"),": it's large when an arm has
                              been pulled rarely (high uncertainty) and shrinks as confidence grows.")),
                  div(class="framework-card",
                      tags$h5("Why It Works"),
                      tags$ul(
                        tags$li("Arms pulled rarely get a", tags$em("large bonus"), "\u2014 uncertainty pushes them up the rankings"),
                        tags$li("Arms pulled often get a", tags$em("small bonus"), "\u2014 estimate is trusted"),
                        tags$li("UCB is guaranteed to minimise cumulative regret (O(log T) regret)")
                      ))),
                column(6,
                  div(class="framework-card",
                      tags$h5("The Gittins Index"),
                      tags$p("For geometrically discounted rewards (each future pull is worth \u03b3 \u00d7 the previous),
                              the provably optimal strategy assigns each arm a",tags$strong("Gittins Index"),
                              "\u2014 a single number summarising its option value."),
                      tags$p("Intuition: the Gittins Index is the fixed payoff that makes you indifferent between
                              exploiting this arm forever vs pulling it once more.")),
                  div(class="insight-box",
                      tags$p(class="ib-title","\U0001f4d0 KEY EQUATION"),
                      tags$p("Regret of UCB after T pulls:"),
                      tags$p(tags$code("Regret \u2264 8 \u00d7 \u03a3 log(T)/\u0394i + (1 + \u03c0\u00b2/3) \u00d7 \u03a3 \u0394i")),
                      tags$p("where \u0394i is the gap between arm i and the best arm. UCB regret grows only logarithmically \u2014 the best possible rate.")))
              )
          )
        )
      ),

      tabPanel(title=tagList(icon("users")," Human Applications"),
        fluidRow(
          box(title="\U0001f3e5 Clinical Trials", status="danger", solidHeader=TRUE, width=6,
              div(class="framework-card",
                  tags$h5("The Life-or-Death Bandit"),
                  tags$p("A clinical trial is a multi-armed bandit: each treatment is an arm,
                          each patient assignment is a pull. Traditional trials use fixed exploration
                          (50/50 split), then pure exploitation."),
                  tags$p(tags$strong("Problem:")," If treatment A is clearly better mid-trial,
                          you are still assigning 50% of patients to the worse treatment.")),
              div(class="framework-card",
                  tags$h5("Adaptive Clinical Trials"),
                  tags$p("Using bandit algorithms (Thompson Sampling), trials can adapt: promising
                          treatments get more patients, poor treatments fewer. This is ethically superior
                          and reaches correct conclusions faster.")),
              div(class="tip-box",
                  HTML("<strong>\U0001f4a1 Real impact:</strong> The REMAP-CAP COVID-19 trial used
                        adaptive design to test multiple treatments simultaneously, identifying effective
                        therapies faster than traditional fixed-design trials."))),

          box(title="\U0001f4f1 A/B Testing & Tech", status="success", solidHeader=TRUE, width=6,
              div(class="framework-card",
                  tags$h5("Website Optimisation"),
                  tags$p("Every A/B test is a bandit problem. Traditional A/B testing:"),
                  tags$ol(
                    tags$li("Run A and B equally for a fixed period"),
                    tags$li("Declare a winner"),
                    tags$li("Serve winner to 100% of users")
                  ),
                  tags$p(tags$strong("Problem:"), " During the test, half the users see the worse option.")),
              div(class="framework-card",
                  tags$h5("Multi-Armed Bandit A/B Testing"),
                  tags$p("Companies like Google, Netflix, and Microsoft use bandit algorithms to
                          continuously shift traffic toward better-performing variants without a
                          fixed test phase. This eliminates the test/deploy boundary entirely.")),
              div(class="info-box-plain",
                  HTML("<strong>\u2139 The explore/exploit lesson for careers:</strong> Early in your career,
                        explore widely \u2014 this is when your future rewards are highest and uncertainty
                        greatest. As you age, exploit your best-known options more.")))
        ),
        fluidRow(
          box(title="\U0001f37d\ufe0f Restaurants, Travel & Everyday Life", status="primary", solidHeader=TRUE, width=12,
              fluidRow(
                column(4,
                  div(class="framework-card",
                      tags$h5("The Restaurant Dilemma"),
                      tags$p("Your city has 1,000 restaurants. You've been to 50. Should you return to your
                              best-known favourite or try somewhere new?"),
                      tags$p("UCB says: try the restaurant with the highest",tags$em("potential"),", not just the
                              highest known quality. A restaurant you've never tried has enormous upside uncertainty."),
                      div(class="tip-box",
                          HTML("<strong>\U0001f4a1 Rule of thumb:</strong> If you're new to a city, explore heavily.
                                If you're leaving next week, exploit your favourite.")))),
                column(4,
                  div(class="framework-card",
                      tags$h5("Exploring New Cities"),
                      tags$p("On holiday in a new city: pure exploration is optimal (you have no baseline yet
                              and may never return). The UCB framework explains why tourists try many restaurants
                              while locals settle into habits."),
                      div(class="framework-card",
                          tags$h5("Career Exploration"),
                          tags$p("Early careers should explore widely: take diverse roles, industries, locations.
                                  The Gittins Index implies that the option value of exploring is highest when
                                  you have the most time left to exploit the findings.")))),
                column(4,
                  div(class="insight-box",
                      tags$p(class="ib-title","\u23f3 WHEN TO EXPLORE VS EXPLOIT"),
                      tags$p("More time remaining \u2192 explore more"),
                      tags$p("Less time remaining \u2192 exploit more"),
                      tags$p("High uncertainty about option \u2192 explore it"),
                      tags$p("High confidence in option \u2192 exploit it"),
                      tags$p("Many options unknown \u2192 explore"),
                      tags$p("Options well-characterised \u2192 exploit")),
                  pull_quote("Be an explorer when you're young, an exploiter when you're old. The math says so.",
                             "Christian & Griffiths"))
              )
          )
        )
      ),

      tabPanel(title=tagList(icon("lightbulb")," Key Insights"),
        fluidRow(
          box(title="\U0001f4a1 Core Takeaways", status="warning", solidHeader=TRUE, width=6,
              div(class="insight-box",
                  tags$p(class="ib-title","REGRET IS THE METRIC"),
                  tags$p("The goal isn't to make the best choice every time \u2014 it's to minimise
                          cumulative regret over all pulls. This reframes failure: a bad pull in an
                          uncertain situation may be exactly the right decision.")),
              div(class="insight-box",
                  tags$p(class="ib-title","EXPLORATION IS AN INVESTMENT"),
                  tags$p("Trying new things isn't irrational or indulgent \u2014 it's systematically
                          reducing uncertainty. The UCB algorithm frames every exploration as building
                          information capital that enables better future exploitation.")),
              div(class="insight-box",
                  tags$p(class="ib-title","AGE-APPROPRIATE STRATEGY"),
                  tags$p("Children try everything. Teenagers explore identities. Adults settle into patterns.
                          Retirees return to proven favourites. This is not irrationality \u2014 it's
                          the optimal bandit algorithm with a shrinking time horizon."))),
          box(title="\u2696\ufe0f Explore vs Exploit Trade-off Summary", status="info", solidHeader=TRUE, width=6,
              algo_table(
                c("Situation","Optimal Bias","Example"),
                list(
                  list("New to a city",          "Heavy explore", "Try 20 new restaurants"),
                  list("Leaving tomorrow",        "Heavy exploit", "Return to your favourite"),
                  list("Young career",            "Explore",       "Try different industries"),
                  list("Near retirement",         "Exploit",       "Deepen proven expertise"),
                  list("Clinical trial, early",   "Balanced",      "Equal allocation"),
                  list("Clinical trial, late",    "Exploit winner","Allocate to best arm"),
                  list("A/B test, clear winner",  "Exploit now",   "Stop test early"),
                  list("Many unknown options",    "Explore first", "UCB with high bonus")
                )
              ),
              div(class="success-box",
                  HTML("<strong>\u2705 The win-stay lose-shift rule:</strong> A surprisingly good
                        and simple strategy \u2014 if your last choice was satisfying, repeat it.
                        If not, switch. Pigeons and bees use this; so do humans intuitively.")))
        )
      )
    ))
  )
}
chapter2_server <- function(id) moduleServer(id, function(input,output,session){})
