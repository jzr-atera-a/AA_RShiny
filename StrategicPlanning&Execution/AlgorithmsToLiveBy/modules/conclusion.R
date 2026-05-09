# Conclusion: Computational Kindness

conclusion_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class="chapter-hero",
        div(class="hero-chapter-num","Conclusion"),
        tags$h1(class="hero-title","\u2764\ufe0f Computational Kindness"),
        tags$p(class="hero-subtitle","The deepest lesson of Algorithms to Live By is not how to think more like a computer.
          It is how to design interactions that are kind to other minds \u2014 human or machine.
          When we understand the cognitive and computational costs of decision-making, we can build
          institutions, systems, and conversations that make good decisions easier for everyone."),
        div(class="badge-row",
            span(class="hero-badge","Computational Kindness"),
            span(class="hero-badge","Cognitive Load"),
            span(class="hero-badge","Mechanism Design"),
            span(class="hero-badge","The Full Picture"))
    ),

    fluidRow(
      box(title="\U0001f9e0 What Computational Kindness Means", status="info", solidHeader=TRUE, width=6,
          div(class="framework-card", tags$h5("The Central Idea"),
              tags$p("Every decision costs something. Every form, every menu, every policy asks others
                      to spend cognitive resources. Computational kindness is designing interactions
                      so these costs are minimised."),
              tags$p("When you understand that",tags$strong("computation is expensive"),"\u2014 that deciding is hard,
                      sorting is costly, predicting requires priors \u2014 you become kinder to the minds around you.")),
          div(class="framework-card", tags$h5("Concretely"),
              tags$ul(tags$li("Give fewer, better options (reducing the sorting problem)"),
                      tags$li("State your constraints explicitly (reducing the search problem)"),
                      tags$li("Signal your preferences clearly (enabling coordination)"),
                      tags$li("Acknowledge when the problem is genuinely hard (reducing blame for slow decisions)"),
                      tags$li("Design defaults wisely (most people use defaults \u2014 they're the important choice)"))),
          pull_quote("Asking someone to pick a restaurant by saying 'wherever you want' is not being kind. It is giving them a computationally hard problem with no information.",
                     "Christian & Griffiths")),

      box(title="\U0001f4cb The 11 Algorithms Summarised", status="warning", solidHeader=TRUE, width=6,
          algo_table(c("Algorithm","Life lesson","When to apply"),
            list(list("Optimal Stopping","Look 37%, then leap","House hunting, hiring, dating"),
                 list("Explore/Exploit","Explore when young, exploit when mature","Career, restaurants, relationships"),
                 list("Sorting","Don't sort if you won't search","Organisation, prioritisation"),
                 list("Caching","Forgetting is rational (LRU)","Filing, email, desk organisation"),
                 list("Scheduling","Clarify objective; avoid context switching","To-do lists, daily planning"),
                 list("Bayes' Rule","Start with the base rate; update proportionally","Predictions, medical decisions"),
                 list("Overfitting","Simple beats complex in noisy worlds","Beliefs, policies, models"),
                 list("Relaxation","Approximate the hard problem","Life planning, negotiations"),
                 list("Randomness","Inject randomness to escape local optima","Decisions under symmetry, annealing life"),
                 list("Networking","ACK often; backoff exponentially","Communication, email, social"),
                 list("Game Theory","Design better games; play Tit-for-Tat","Cooperation, negotiations, incentives"))))
    ),

    fluidRow(
      box(title="\U0001f30e Permission to Be Less Than Perfect", status="success", solidHeader=TRUE, width=12,
          fluidRow(
            column(4, div(class="framework-card", tags$h5("The Permission"),
                tags$p("The deepest comfort of this book is that the algorithms say:"),
                tags$ul(tags$li("It's OK not to review every option (37% rule says stop at 37%)"),
                        tags$li("It's OK to forget things (LRU says this is optimal)"),
                        tags$li("It's OK to use simple rules (overfitting says simpler is often better)"),
                        tags$li("It's OK to approximate (relaxation says exact solutions are sometimes impossible)"),
                        tags$li("It's OK to feel overwhelmed (NP-hardness says some problems are genuinely hard)"))),
              div(class="success-box", HTML("<strong>\u2705 You are not failing at decision-making.
                You are solving hard computational problems with limited resources."))),
            column(4, div(class="insight-box",
                tags$p(class="ib-title","THE ALGORITHMS IN ORDER"),
                tags$p("1. Optimal Stopping \u2014 when to decide"),
                tags$p("2. Explore/Exploit \u2014 when to try new things"),
                tags$p("3. Sorting \u2014 how to create order"),
                tags$p("4. Caching \u2014 what to remember"),
                tags$p("5. Scheduling \u2014 what to do first"),
                tags$p("6. Bayes' Rule \u2014 how to predict"),
                tags$p("7. Overfitting \u2014 when to stop refining"),
                tags$p("8. Relaxation \u2014 how to handle hard problems"),
                tags$p("9. Randomness \u2014 when chance helps"),
                tags$p("10. Networking \u2014 how to communicate"),
                tags$p("11. Game Theory \u2014 how to cooperate")),
              pull_quote("Computer science is not about machines. It is about the nature of problems and the nature of solutions.",
                         "Brian Christian & Tom Griffiths")),
            column(4,
              div(class="framework-card", tags$h5("Computational Kindness in Practice"),
                  tags$ul(tags$li(tags$strong("At work:")," reduce unnecessary decisions in forms, menus, processes"),
                          tags$li(tags$strong("At home:")," agree on defaults for recurring choices"),
                          tags$li(tags$strong("In communication:")," state your constraints early ('I can only do Tuesday')"),
                          tags$li(tags$strong("In design:")," defaults should be the best option for most people"),
                          tags$li(tags$strong("In leadership:")," make decisions so others don't have to"),
                          tags$li(tags$strong("In parenting:")," give limited choices, not unlimited freedom"))),
              div(class="tip-box", HTML("<strong>\U0001f4a1 The final word:</strong> The best algorithms for computers
                \u2014 and the best strategies for humans \u2014 are those that make good use of limited
                resources while being kind to the minds that must execute them.")))
          )
      )
    )
  )
}
conclusion_server <- function(id) moduleServer(id, function(input,output,session){})
