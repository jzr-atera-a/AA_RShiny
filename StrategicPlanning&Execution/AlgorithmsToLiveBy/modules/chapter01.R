# Chapter 1: Optimal Stopping — When to Stop Looking

chapter1_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(1,"\u23f9\ufe0f","Optimal Stopping",
      "How long should you look before you leap? Whether you're searching for a home, a partner, or a parking space, mathematics gives a surprisingly precise answer: look at 37% of your options, then commit to the next one that beats everything you've seen.",
      c("37% Rule","Secretary Problem","Look Then Leap","Optimal Search","Threshold Strategies")),
    stats_row(
      list("37%","Optimal look phase"),
      list("1/e","Mathematical basis"),
      list("~63%","Success probability"),
      list("\u221e","Options considered")
    ),

    fluidRow(tabBox(width=12, id=ns("tabs"),

      tabPanel(title=tagList(icon("book")," The Problem"),
        fluidRow(
          box(title="\U0001f9e9 The Secretary Problem", status="info", solidHeader=TRUE, width=6,
              div(class="framework-card",
                  tags$h5("The Classic Setup"),
                  tags$p("Imagine you must hire a secretary from a pool of N candidates. You interview them
                          one at a time in random order. After each interview you must",
                          tags$strong("immediately decide"), "to hire or pass. You cannot go back. What strategy
                          maximises your chance of hiring the best candidate?")),
              timeline_strip(
                list("Look Phase","Interview candidates — collect information only. Never hire."),
                list("Threshold Set","The best seen so far becomes your benchmark."),
                list("Leap Phase","Hire the first candidate who beats your benchmark."),
                list("Outcome","~37% chance of finding the absolute best.")
              ),
              div(class="tip-box",
                  HTML("<strong>\U0001f4a1 The 37% Rule:</strong> Look at the first N/e \u2248 37% of candidates without
                        committing. Then hire the next one who beats everyone seen so far."))),

          box(title="\U0001f4ca The Mathematics", status="warning", solidHeader=TRUE, width=6,
              div(class="framework-card",
                  tags$h5("Why 37%? The Maths"),
                  tags$p("The optimal stopping point is N/e, where e \u2248 2.718 (Euler's number).
                          The probability of success is also exactly 1/e \u2248 37%."),
                  tags$p("As N grows large, the optimal strategy converges to this ratio.
                          The exact threshold for small N is calculated by finding the value r
                          that maximises P(best | stop after r) = (r/N) \u00d7 \u03a3 1/(i-1) for i = r+1 to N.")),
              algo_table(
                c("N (candidates)","Optimal look at","Success probability"),
                list(
                  list("3",  "1",  "50.0%"),
                  list("4",  "1",  "45.8%"),
                  list("5",  "2",  "43.3%"),
                  list("10", "3",  "39.9%"),
                  list("20", "7",  "38.4%"),
                  list("100","37", "37.1%"),
                  list("\u221e","37%","36.79% (1/e)")
                )
              ),
              div(class="info-box-plain",
                  HTML("<strong>\u2139 Key insight:</strong> The optimal look fraction converges to 37%
                        regardless of N. Even with only 5 candidates, stopping at 2 is already near-optimal.")))
        ),
        fluidRow(
          box(title="\u2696\ufe0f Variants & Extensions", status="success", solidHeader=TRUE, width=12,
              fluidRow(
                column(4,
                  div(class="framework-card",
                      tags$h5("No-Information Problem"),
                      tags$p("Classic version: you only know relative rank (better or worse than previous).
                              Solution: 37% rule with success probability 1/e \u2248 37%.")),
                  div(class="framework-card",
                      tags$h5("Full-Information Problem"),
                      tags$p("You know the actual value (e.g. salary, apartment price). Now you can set
                              an absolute threshold. Success probability rises to ~58% using threshold strategies."))),
                column(4,
                  div(class="framework-card",
                      tags$h5("The Postdoc Problem (Recall Allowed)"),
                      tags$p("If rejected candidates can be recalled with some probability p, the optimal
                              look phase shrinks. With perfect recall, you could look at more and still
                              hire the best.")),
                  div(class="framework-card",
                      tags$h5("The Parking Problem"),
                      tags$p("Approaching a parking lot: too early and you walk far; too late and you
                              overshoot. The 37% rule applies \u2014 drive past the first 37% of spaces
                              then take the next acceptable spot."))),
                column(4,
                  div(class="framework-card",
                      tags$h5("Satisficing vs Optimising"),
                      tags$p("Herbert Simon coined 'satisficing': accept the first option above a
                              threshold. This is computationally cheaper than full optimisation and
                              performs surprisingly well in practice.")),
                  div(class="insight-box",
                      tags$p(class="ib-title","\U0001f3af Real-world calibration"),
                      tags$p("If you'll date for 10 years before settling down, spend the first 3.7 years
                              (37%) playing the field. Then commit to the next person who exceeds everyone
                              you've dated.")))
              )
          )
        )
      ),

      tabPanel(title=tagList(icon("users")," Human Applications"),
        fluidRow(
          box(title="\U0001f3e0 House Hunting", status="danger", solidHeader=TRUE, width=6,
              div(class="framework-card",
                  tags$h5("The Classic Application"),
                  tags$p("House hunters face the secretary problem exactly: view homes sequentially,
                          decide immediately (the market won't wait), can rarely return to a rejected option.")),
              div(class="framework-card",
                  tags$h5("Optimal Strategy"),
                  tags$ol(
                    tags$li("Decide your viewing horizon (e.g. 12 weekends = 12 homes)"),
                    tags$li("View the first 4-5 homes (37%) to calibrate your expectations"),
                    tags$li("Identify the best seen so far \u2014 this is your benchmark"),
                    tags$li("Make an offer on the next home that beats the benchmark")
                  )),
              div(class="tip-box",
                  HTML("<strong>\U0001f4a1 Why people fail:</strong> Most house hunters either decide
                        too early (fear of missing out) or too late (paralysed by indecision).
                        The 37% rule tells you exactly where to draw the line."))),

          box(title="\U0001f48d Dating & Partners", status="success", solidHeader=TRUE, width=6,
              div(class="framework-card",
                  tags$h5("The Marriage Problem"),
                  tags$p("The secretary problem was originally called the marriage problem. The maths is
                          the same: a finite number of potential partners, reviewed sequentially, with
                          no going back to exes.")),
              div(class="framework-card",
                  tags$h5("Age-Based Calibration"),
                  tags$p("If you start dating at 18 and want to settle down by 40 (22 years):"),
                  tags$ul(
                    tags$li("Look phase: 18 to 18 + (22 \u00d7 0.37) \u2248 ",tags$strong("26 years old")),
                    tags$li("From 26, commit to the next partner who beats everyone so far"),
                    tags$li("Success probability: ~37% of finding your optimal partner")
                  )),
              pull_quote("The math says look for about a third of your dating window, then settle down with the first person who beats everyone you've seen so far.",
                         "Christian & Griffiths"))
        ),
        fluidRow(
          box(title="\U0001f4ca Optimal Stopping in Everyday Life", status="primary", solidHeader=TRUE, width=12,
              algo_table(
                c("Domain","N (options)","Look phase","Decision trigger"),
                list(
                  list("House hunting","20 viewings","7 homes","First home better than all 7"),
                  list("Hiring","50 applicants","18 interviews","First candidate better than all 18"),
                  list("Parking","100m of spaces","37m","First available spot past 37m mark"),
                  list("Restaurant choice","10 options","3-4 reviews","First restaurant rated above all 3-4"),
                  list("Online dating","100 profiles","37 dates","Commit to next person better than all 37"),
                  list("Taxi waiting","15-min window","5.5 min","Take next taxi after 5.5 min"),
                  list("Apartment search","Season of viewings","37% of season","First apartment that beats all prior")
                )
              ),
              div(class="success-box",
                  HTML("<strong>\u2705 The universal lesson:</strong> In any sequential search with a cost of looking
                        and no recall, the 37% threshold is mathematically optimal. The rule works whether
                        you have 5 options or 5,000."))
          )
        )
      ),

      tabPanel(title=tagList(icon("lightbulb")," Key Insights"),
        fluidRow(
          box(title="\U0001f4a1 Core Takeaways", status="warning", solidHeader=TRUE, width=6,
              div(class="insight-box",
                  tags$p(class="ib-title","THE LOOK-THEN-LEAP PRINCIPLE"),
                  tags$p("Never make a commitment during the look phase. Information gathering and
                          decision-making are separate activities. Conflating them \u2014 committing
                          prematurely out of fear \u2014 is the most common error.")),
              div(class="insight-box",
                  tags$p(class="ib-title","KNOWING WHEN TO STOP IS A SKILL"),
                  tags$p("The hardest part isn't finding good options \u2014 it's recognising when
                          you've found one worth keeping. The 37% rule tells you exactly when
                          your sample is large enough to make an informed choice.")),
              div(class="insight-box",
                  tags$p(class="ib-title","REGRET IS MATHEMATICALLY INEVITABLE"),
                  tags$p("Even with the optimal algorithm, you fail 63% of the time. This is the
                          fundamental cost of irreversible decisions under uncertainty.
                          Accepting this is freeing: you didn't fail because you chose wrong;
                          you failed because the problem is hard."))),
          box(title="\U0001f914 The Deeper Philosophy", status="info", solidHeader=TRUE, width=6,
              div(class="framework-card",
                  tags$h5("Optimal Stopping vs Full Optimisation"),
                  tags$p("Fully optimising (reviewing ALL candidates) costs infinite time. The 37% rule
                          trades some probability of success for a dramatic reduction in search cost.
                          In the real world, time spent searching is time not spent enjoying the result.")),
              div(class="framework-card",
                  tags$h5("The Role of Thresholds"),
                  tags$p("Threshold strategies \u2014 accept the next option above a certain bar \u2014 are
                          computationally simple and near-optimal. Setting the right threshold is
                          the key skill, not evaluating every option exhaustively.")),
              div(class="framework-card",
                  tags$h5("When the Rule Breaks Down"),
                  tags$ul(
                    tags$li("When options can be recalled (recall allowed \u2192 look longer)"),
                    tags$li("When new options keep appearing (no fixed N \u2192 use threshold on absolute value)"),
                    tags$li("When the cost of waiting exceeds the cost of a bad choice")
                  )),
              pull_quote("Sometimes the world will only give you one chance. When it does, 37% is your best friend.",
                         "Christian & Griffiths"))
        )
      )
    ))
  )
}
chapter1_server <- function(id) moduleServer(id, function(input,output,session){})
