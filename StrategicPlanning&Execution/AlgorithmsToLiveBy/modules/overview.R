# overview.R

overview_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="chapter-hero",
        div(class="hero-chapter-num","William Morrow \u00b7 2016"),
        tags$h1(class="hero-title","\u2699\ufe0f Algorithms to Live By"),
        tags$p(class="hero-subtitle","What does computer science have to teach us about the human mind? Brian Christian and Tom Griffiths
          show how the mathematical rules that govern our computers can illuminate what it means to be human.
          From optimal stopping to game theory, the same algorithms that computers use to solve hard problems
          can reveal new strategies for navigating the challenges of everyday life."),
        div(class="badge-row",
            span(class="hero-badge","11 Chapters"),
            span(class="hero-badge","Brian Christian & Tom Griffiths"),
            span(class="hero-badge","CS \u00d7 Human Decisions"),
            span(class="hero-badge","Popular Science"))
    ),

    fluidRow(
      box(title="\U0001f4d6 About This Book", status="info", solidHeader=TRUE, width=6,
          div(class="framework-card",
              tags$h5("The Central Thesis"),
              tags$p("Computers and humans face remarkably similar problems: how to allocate limited time,
                      how to sort information, when to stop searching for something better, how to predict the future.
                      The algorithms computer scientists have developed to solve these problems are not just
                      tools \u2014 they are",tags$strong("optimal strategies for living."))),
          div(class="framework-card",
              tags$h5("What You Will Find"),
              tags$ul(
                tags$li("Mathematical frameworks translated into actionable human wisdom"),
                tags$li("Research from computer science, cognitive science, and psychology"),
                tags$li("Real-world case studies from dating to medicine to parking lots"),
                tags$li("Permission to be less than perfect \u2014 often the optimal algorithm is approximate")
              )),
          pull_quote("The best algorithms are not just computational tools \u2014 they are insights into the nature of the problems we face.",
                     "Brian Christian & Tom Griffiths")
      ),
      box(title="\U0001f4ca The 11 Chapters at a Glance", status="warning", solidHeader=TRUE, width=6,
          algo_table(
            c("Ch","Title","Core Algorithm","Human Problem"),
            list(
              list("1","Optimal Stopping","37% Rule","When to stop searching"),
              list("2","Explore/Exploit","Multi-Armed Bandit","New vs familiar"),
              list("3","Sorting","Comparison Sorts","Making order"),
              list("4","Caching","LRU Eviction","What to remember"),
              list("5","Scheduling","Shortest Job First","Prioritising tasks"),
              list("6","Bayes' Rule","Bayesian Inference","Predicting the future"),
              list("7","Overfitting","Regularisation","When to generalise"),
              list("8","Relaxation","Constraint Relaxation","Solving hard problems"),
              list("9","Randomness","Simulated Annealing","When chance helps"),
              list("10","Networking","TCP/IP Protocols","Human communication"),
              list("11","Game Theory","Nash Equilibrium","The minds of others")
            )
          ))
    ),

    fluidRow(
      box(title="\U0001f9e0 All 11 Chapters", status="success", solidHeader=TRUE, width=12,
          fluidRow(
            column(3,
              lapply(list(
                list("1","Optimal Stopping","When to stop looking \u2014 the mathematical case for the 37% rule","37% Rule \u00b7 Secretary Problem"),
                list("2","Explore/Exploit","Balancing new experiences with proven favourites","Multi-Armed Bandit \u00b7 UCB"),
                list("3","Sorting","The hidden cost of ordering \u2014 and when not to sort","Comparisons \u00b7 O(N log N)")
              ), function(i) div(class="chapter-card",
                div(class="ch-num",paste("Chapter",i[[1]])),
                div(class="ch-title",i[[2]]),
                div(class="ch-desc",i[[3]]),
                div(class="ch-tags",lapply(strsplit(i[[4]]," \u00b7 ")[[1]],function(t) span(class="topic-tag",t)))))
            ),
            column(3,
              lapply(list(
                list("4","Caching","Forget about it \u2014 the optimal strategy for an imperfect memory","LRU \u00b7 Memory Hierarchy"),
                list("5","Scheduling","First things first \u2014 how to arrange what you have to do","SJF \u00b7 Preemption \u00b7 EDD"),
                list("6","Bayes' Rule","Predicting the future with imperfect information","Bayesian \u00b7 Priors \u00b7 Laplace")
              ), function(i) div(class="chapter-card",
                div(class="ch-num",paste("Chapter",i[[1]])),
                div(class="ch-title",i[[2]]),
                div(class="ch-desc",i[[3]]),
                div(class="ch-tags",lapply(strsplit(i[[4]]," \u00b7 ")[[1]],function(t) span(class="topic-tag",t)))))
            ),
            column(3,
              lapply(list(
                list("7","Overfitting","When to think less \u2014 the virtue of simple models","Bias-Variance \u00b7 Occam"),
                list("8","Relaxation","Let it slide \u2014 solving hard problems by loosening constraints","TSP \u00b7 Lagrangian"),
                list("9","Randomness","When to leave it to chance \u2014 the power of randomised algorithms","Monte Carlo \u00b7 Annealing")
              ), function(i) div(class="chapter-card",
                div(class="ch-num",paste("Chapter",i[[1]])),
                div(class="ch-title",i[[2]]),
                div(class="ch-desc",i[[3]]),
                div(class="ch-tags",lapply(strsplit(i[[4]]," \u00b7 ")[[1]],function(t) span(class="topic-tag",t)))))
            ),
            column(3,
              lapply(list(
                list("10","Networking","How we connect \u2014 protocols for human communication","TCP \u00b7 Backoff \u00b7 Buffers"),
                list("11","Game Theory","The minds of others \u2014 when the best move depends on everyone else","Nash \u00b7 Mechanism Design"),
                list("\u2605","Conclusion","Computational Kindness \u2014 making life easier for other minds","Design \u00b7 Simplicity")
              ), function(i) div(class="chapter-card",
                div(class="ch-num",paste("Chapter",i[[1]])),
                div(class="ch-title",i[[2]]),
                div(class="ch-desc",i[[3]]),
                div(class="ch-tags",lapply(strsplit(i[[4]]," \u00b7 ")[[1]],function(t) span(class="topic-tag",t)))))
            )
          )
      )
    )
  )
}
overview_server <- function(id) moduleServer(id, function(input,output,session){})
