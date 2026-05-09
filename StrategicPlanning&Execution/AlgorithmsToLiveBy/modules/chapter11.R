# Chapter 11: Game Theory — The Minds of Others

chapter11_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(11,"\u265e","Game Theory",
      "When the best strategy depends on what others do, we enter the domain of game theory. From the prisoner's dilemma to mechanism design, computer science and economics have developed rigorous tools for reasoning about strategic interaction — revealing when cooperation emerges, when it breaks down, and how institutions can be designed to produce better outcomes.",
      c("Nash Equilibrium","Prisoner's Dilemma","Dominant Strategy","Mechanism Design","Price of Anarchy","Cooperation")),
    stats_row(list("Nash","Equilibrium concept"), list("Dominant","Strategy always best"), list("PoA","Efficiency loss metric"), list("Mechanism","Design changes incentives")),

    fluidRow(tabBox(width=12, id=ns("tabs"),
      tabPanel(title=tagList(icon("book")," Core Concepts"),
        fluidRow(
          box(title="\u265e The Prisoner's Dilemma", status="info", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("The Setup"),
                  tags$p("Two prisoners, separately interrogated. Each can cooperate (stay silent)
                          or defect (betray). Neither knows what the other will do."),
                  tags$p("Payoff matrix (years in prison):"),
                  algo_table(c("","B Cooperates","B Defects"),
                    list(list("A Cooperates","A:1, B:1","A:10, B:0"),
                         list("A Defects","A:0, B:10","A:5, B:5")))),
              div(class="framework-card", tags$h5("The Nash Equilibrium"),
                  tags$p(tags$strong("Both defect"), "is the Nash Equilibrium: if A defects, B's best response is to defect.
                          If B defects, A's best response is to defect."),
                  tags$p(tags$strong("Problem:"), " both defecting gives (5,5) \u2014 far worse than the cooperate outcome (1,1)."),
                  tags$p("The individually rational choice leads to a collectively worse outcome.
                          This is the tragedy of the commons.")),
              div(class="warn-box", HTML("<strong>\u26a0 The social trap:</strong> Many real-world tragedies are prisoner's dilemmas:
                tax evasion (if others evade, I should too), overfishing, arms races, pollution.
                Individual rationality produces collective irrationality."))),
          box(title="\U0001f4ca The Landscape of Games", status="warning", solidHeader=TRUE, width=6,
              algo_table(c("Game type","Description","Example","Key result"),
                list(list("Zero-sum","One player's gain = other's loss","Chess, poker","Always a Nash equilibrium; min-max"),
                     list("Coordination","Players prefer matching strategies","Driving side of road","Multiple equilibria; need focal point"),
                     list("Prisoner's Dilemma","Defection dominates; cooperation optimal","Arms race, pollution","Defection is NE, but costly"),
                     list("Stag Hunt","Risky cooperation vs safe individual","Teamwork","Two NE: (cooperate,cooperate) or (defect,defect)"),
                     list("Chicken","One must back down","Nuclear standoff","Two NE: (yield,hold) or (hold,yield)"),
                     list("Battle of Sexes","Must coordinate; prefer different options","Joint decisions","Multiple NE; need communication"))),
              div(class="framework-card", tags$h5("Dominant Strategy"),
                  tags$p("A strategy is",tags$strong("dominant")," if it's the best response regardless of what others do.
                          When you have a dominant strategy, use it.
                          When everyone has a dominant strategy, the outcome is the Nash Equilibrium.")))
        ),
        fluidRow(
          box(title="\U0001f3db\ufe0f Mechanism Design", status="success", solidHeader=TRUE, width=12,
              fluidRow(
                column(4, div(class="framework-card", tags$h5("Game Theory in Reverse"),
                    tags$p("Game theory asks: given the rules, what will rational players do?"),
                    tags$p(tags$strong("Mechanism design"), "asks: given the outcome we want, what rules will make
                            rational players produce it?"),
                    tags$p("This is 'reverse game theory' \u2014 designing institutions, incentives, and rules
                            to align individual rationality with collective good."))),
                column(4, div(class="framework-card", tags$h5("Examples of Good Mechanism Design"),
                    tags$ul(tags$li(tags$strong("Vickrey auction (second-price):"), " bid truthfully is a dominant strategy"),
                            tags$li(tags$strong("Matching markets (Gale-Shapley):"), " stable matching with truthful reporting"),
                            tags$li(tags$strong("Spectrum auctions:"), " simultaneously auctioning complementary goods"),
                            tags$li(tags$strong("Peer review:"), " incentivising honest evaluation"),
                            tags$li(tags$strong("Carbon tax:"), " making externalities internal to the price")))),
                column(4, div(class="insight-box",
                    tags$p(class="ib-title","PRICE OF ANARCHY"),
                    tags$p("The Price of Anarchy (PoA) measures how much worse a Nash Equilibrium is
                            compared to the social optimum."),
                    tags$p("Traffic routing: drivers independently choosing fastest routes can be 33% slower
                            than optimal (Braess's paradox \u2014 adding a road can slow everyone down)."),
                    tags$p("PoA = Social Optimum / Nash Equilibrium quality"),
                    tags$p("Good mechanism design minimises the Price of Anarchy.")))
              )
          )
        )
      ),
      tabPanel(title=tagList(icon("users")," Human Applications"),
        fluidRow(
          box(title="\U0001f91d When Cooperation Emerges", status="success", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("Iterated Games"),
                  tags$p("In a", tags$strong("one-shot"), "prisoner's dilemma, defection is dominant.
                          In a", tags$strong("repeated"), "game (same players, multiple rounds), cooperation can emerge."),
                  tags$p("Axelrod's famous tournaments showed that",tags$strong("Tit-for-Tat")," \u2014 cooperate first,
                          then mirror the other's last move \u2014 is the most successful strategy in repeated games.")),
              div(class="framework-card", tags$h5("Why Tit-for-Tat Wins"),
                  tags$ul(tags$li(tags$strong("Nice:")," starts with cooperation"),
                          tags$li(tags$strong("Retaliatory:")," punishes defection immediately"),
                          tags$li(tags$strong("Forgiving:")," returns to cooperation after punishment"),
                          tags$li(tags$strong("Clear:")," opponent can understand the strategy"))),
              div(class="tip-box", HTML("<strong>\U0001f4a1 Life lesson:</strong> Be nice first. Respond to defection
                with defection. Forgive quickly. Be predictable. This is Tit-for-Tat in human relationships."))),
          box(title="\U0001f4b0 Auctions & Markets", status="danger", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("The Vickrey Auction"),
                  tags$p("In a standard (first-price) auction, you should bid", tags$em("less"), "than your true value
                          (because you pay what you bid if you win)."),
                  tags$p("In a second-price (Vickrey) auction, you pay the second-highest bid.
                          Remarkably, bidding your true value is now a dominant strategy \u2014 you can't
                          do better by misrepresenting your value.")),
              div(class="framework-card", tags$h5("Mechanism Design in Practice"),
                  algo_table(c("Problem","Bad mechanism","Better mechanism"),
                    list(list("Fund public goods","Voluntary contribution","Pigouvian tax/subsidy"),
                         list("Allocate kidneys","Queue","Matching market (Roth)"),
                         list("Reduce emissions","Regulation","Cap and trade"),
                         list("Buy goods","First-price auction","Second-price auction"),
                         list("Assign students to schools","Proximity rule","Gale-Shapley matching")))),
              pull_quote("The key insight of mechanism design: you can't change people. But you can change the rules they play by.",
                         "Christian & Griffiths"))
        )
      ),
      tabPanel(title=tagList(icon("lightbulb")," Key Insights"),
        fluidRow(
          box(title="\U0001f4a1 Core Takeaways", status="warning", solidHeader=TRUE, width=6,
              div(class="insight-box", tags$p(class="ib-title","GAMES ARE EVERYWHERE"),
                  tags$p("Any situation where your optimal choice depends on others' choices is a game.
                          Recognising this is the first step to playing it well.")),
              div(class="insight-box", tags$p(class="ib-title","STRUCTURE MATTERS MORE THAN PEOPLE"),
                  tags$p("Individual rationality produces collective irrationality in bad games (Prisoner's Dilemma).
                          The same people in a well-designed game produce collective good.
                          Focus on redesigning the game, not reforming the players.")),
              div(class="insight-box", tags$p(class="ib-title","COOPERATION REQUIRES REPETITION"),
                  tags$p("Cooperation is sustained by the shadow of the future: the prospect of future
                          interaction makes defection costly. When interactions are one-shot or anonymous,
                          cooperation breaks down. Institutions create the repeated structure that enables trust."))),
          box(title="\u2705 Strategic Wisdom", status="success", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("Personal Game Theory"),
                  tags$ul(tags$li("When you have a dominant strategy, use it regardless of what others do"),
                          tags$li("In repeated interactions, start by cooperating (be nice first)"),
                          tags$li("Retaliate swiftly but proportionally to defection"),
                          tags$li("Forgive and return to cooperation after punishment"),
                          tags$li("Be transparent about your strategy \u2014 predictability enables coordination"))),
              div(class="framework-card", tags$h5("Organisational Design"),
                  tags$ul(tags$li("Design incentives before hoping for cooperation"),
                          tags$li("Identify what game employees are actually playing"),
                          tags$li("Use second-price mechanisms where possible (truthful revelation)"),
                          tags$li("Create repeated games: long-term relationships beat one-off transactions"),
                          tags$li("Measure the Price of Anarchy in your systems: how far are individual incentives from collective optimum?"))))
        )
      )
    ))
  )
}
chapter11_server <- function(id) moduleServer(id, function(input,output,session){})
