# Chapter 8: Relaxation — Let It Slide

chapter8_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(8,"\U0001f9d8","Relaxation",
      "Some problems are provably intractable — no algorithm can solve them efficiently. But there is a principled approach: relax the constraints, solve the easier version, then tighten back up. This mathematical technique yields surprisingly good approximate solutions and has profound implications for how we handle real-world complexity.",
      c("Constraint Relaxation","Lagrangian Relaxation","TSP Approximation","NP-Hard Problems","Local Search","Continuous Relaxation")),
    stats_row(list("NP-Hard","TSP complexity"), list("1.5\u00d7","Christofides guarantee"), list("Relax \u2192 Solve \u2192 Tighten","The method"), list("~10%","Typical optimality gap")),

    fluidRow(tabBox(width=12, id=ns("tabs"),
      tabPanel(title=tagList(icon("book")," Core Concepts"),
        fluidRow(
          box(title="\U0001f9e9 What is Relaxation?", status="info", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("The Core Idea"),
                  tags$p("Many hard problems become easy when you remove (relax) one or more constraints.
                          Solve the easy version, then use that solution as a starting point or bound
                          for the hard version.")),
              div(class="framework-card", tags$h5("Types of Relaxation"),
                  tags$ul(tags$li(tags$strong("Continuous relaxation:")," allow integer decisions to be fractional"),
                          tags$li(tags$strong("Lagrangian relaxation:")," move hard constraints into the objective with a penalty"),
                          tags$li(tags$strong("Constraint relaxation:")," remove some constraints entirely"),
                          tags$li(tags$strong("Problem relaxation:")," solve a simpler version of the same problem"))),
              div(class="framework-card", tags$h5("The Travelling Salesman Problem (TSP)"),
                  tags$p("Given N cities, find the shortest route that visits each city exactly once and returns to the start."),
                  tags$p(tags$strong("Complexity:"), " O(N!) exact \u2014 with 20 cities, that's 2.4 quintillion routes."),
                  tags$p(tags$strong("Best known exact:"), " O(2^N \u00d7 N\u00b2) dynamic programming \u2014 still exponential."))),
          box(title="\U0001f4ca Approximation Algorithms for TSP", status="warning", solidHeader=TRUE, width=6,
              algo_table(c("Algorithm","Guarantee","Speed","How"),
                list(list("Nearest Neighbour","Can be 25% worse than optimal","O(N\u00b2)","Always go to closest unvisited city"),
                     list("2-Opt","Near-optimal in practice","O(N\u00b2) per iteration","Remove 2 edges, reconnect better"),
                     list("3-Opt","Slightly better than 2-Opt","O(N\u00b3) per iteration","Remove 3 edges, reconnect best"),
                     list("Christofides","Within 1.5\u00d7 optimal","O(N\u00b3)","Minimum spanning tree + matching"),
                     list("LKH (Lin-Kernighan)","Optimal in practice","Heuristic","Adaptive k-opt moves"),
                     list("Held-Karp (exact)","Optimal","O(2^N \u00d7 N\u00b2)","DP on subsets (exact but exponential)"))),
              div(class="success-box", HTML("<strong>\u2705 The practical lesson:</strong> For N > 20, exact TSP is infeasible.
                2-Opt or LKH find solutions within 1-2% of optimal in seconds. A near-optimal solution
                arrived at quickly beats a perfect solution that arrives too late.")))
        ),
        fluidRow(
          box(title="\U0001f504 Lagrangian Relaxation", status="success", solidHeader=TRUE, width=12,
              fluidRow(
                column(4, div(class="framework-card", tags$h5("The Method"),
                    tags$p("Take a hard constraint that makes the problem difficult. Move it into the objective
                            function with a", tags$strong("Lagrange multiplier"), "\u03bb (a penalty for violating it)."),
                    tags$p("Solve the relaxed problem (now easier). Adjust \u03bb and repeat until the constraint
                            is approximately satisfied."))),
                column(4, div(class="framework-card", tags$h5("Intuition"),
                    tags$p("Instead of requiring 'you MUST visit every city', relax to 'you SHOULD visit
                            every city, and there's a cost for each one you skip'."),
                    tags$p("By adjusting the penalty (\u03bb), you trade between constraint satisfaction and
                            objective optimisation."))),
                column(4, div(class="insight-box",
                    tags$p(class="ib-title","REAL-WORLD RELAXATIONS"),
                    tags$p("A budget is a constraint. Relaxing it (borrowing) lets you find the optimal solution,
                            then you figure out financing."),
                    tags$p("A deadline is a constraint. Relaxing it (asking for extension) lets you solve the
                            quality problem first."),
                    tags$p("A rule is a constraint. Sometimes breaking it reveals a better solution; then you
                            formalise the exception.")))
              )
          )
        )
      ),
      tabPanel(title=tagList(icon("users")," Human Applications"),
        fluidRow(
          box(title="\U0001f3e1 Route Planning & Logistics", status="danger", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("The Real TSP: Delivery Routes"),
                  tags$p("UPS, FedEx, and Amazon solve thousands of TSP instances daily. They use sophisticated
                          heuristics (2-Opt, LKH) because exact solutions are computationally impossible."),
                  tags$p("UPS's ORION routing system saves 100 million miles per year \u2014 using approximate algorithms,
                          not optimal ones.")),
              div(class="framework-card", tags$h5("Satisficing in Route Planning"),
                  tags$p("You don't need the optimal route from A to B. You need a route that arrives in time.
                          Satisficing (finding 'good enough') is the human equivalent of approximation algorithms.")),
              pull_quote("The perfect is the enemy of the good. Approximate solutions to hard problems are not compromises — they are the rational response to intractability.",
                         "Christian & Griffiths")),
          box(title="\U0001f4bc Life as a Constraint Problem", status="success", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("When to Relax Constraints"),
                  tags$p("Many life decisions are hard because we treat soft constraints as hard ones."),
                  algo_table(c("Hard constraint (assumed)","Relaxation","What it enables"),
                    list(list("Must finish degree in 4 years","Allow 5 years","Take better internships"),
                         list("Must live in current city","Consider remote work","Access global opportunities"),
                         list("Budget is exactly X","Allow slight overspend","Better quality decision"),
                         list("Must decide by today","Ask for 1 more day","Better information")))),
              div(class="framework-card", tags$h5("The Lagrangian Life"),
                  tags$p("When you can't satisfy all constraints simultaneously, convert some to soft penalties.
                          The question becomes: how much is satisfying this constraint worth to you?
                          This reframes trade-offs as explicit value judgements.")))
        )
      ),
      tabPanel(title=tagList(icon("lightbulb")," Key Insights"),
        fluidRow(
          box(title="\U0001f4a1 Core Takeaways", status="warning", solidHeader=TRUE, width=6,
              div(class="insight-box", tags$p(class="ib-title","INTRACTABILITY IS REAL"),
                  tags$p("Some problems genuinely cannot be solved optimally in reasonable time.
                          This is not a failure of effort or intelligence. It is a mathematical fact.
                          Accepting this is freeing: the goal shifts from perfect to near-optimal.")),
              div(class="insight-box", tags$p(class="ib-title","GOOD ENOUGH IS OFTEN OPTIMAL"),
                  tags$p("In a world of hard problems, the right strategy is often: find a quick
                          approximate solution, then refine iteratively. This is better than searching
                          indefinitely for perfection.")),
              div(class="insight-box", tags$p(class="ib-title","IDENTIFY YOUR HARD CONSTRAINTS"),
                  tags$p("Before labelling all constraints 'hard', ask: which ones truly cannot be violated?
                          Often, softening constraints (converting them to penalties) reveals solutions
                          that satisfy everything approximately but nothing perfectly."))),
          box(title="\u2705 Relaxation in Practice", status="success", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("The Algorithm for Hard Problems"),
                  tags$ol(tags$li("Identify which constraints make the problem hard"),
                          tags$li("Relax the hard constraints"),
                          tags$li("Solve the relaxed (easier) problem"),
                          tags$li("Check if the solution satisfies the original constraints"),
                          tags$li("If not, tighten constraints and repeat"),
                          tags$li("Accept 'good enough' when further refinement is too costly"))),
              div(class="framework-card", tags$h5("Everyday Relaxation"),
                  tags$ul(tags$li("Budgets: plan with soft ceilings, not hard limits"),
                          tags$li("Schedules: build in slack; hard schedules thrash"),
                          tags$li("Rules: treat most rules as defaults with justified exceptions"),
                          tags$li("Goals: aim for satisfactory progress, not perfect achievement"))))
        )
      )
    ))
  )
}
chapter8_server <- function(id) moduleServer(id, function(input,output,session){})
