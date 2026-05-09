# Chapter 3: Sorting — Making Order

chapter3_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(3,"\U0001f4c2","Sorting",
      "Sorting is one of the most studied problems in computer science, consuming vast amounts of human and machine time. But the deepest insight isn't how to sort — it's knowing when not to sort at all, and understanding that comparison itself is the fundamental currency of order.",
      c("Comparison Sorts","O(N log N)","Mergesort","Card Sorting","Search vs Sort","Rankings")),
    stats_row(
      list("O(N log N)","Lower bound for comparison sort"),
      list("O(N\u00b2)","Naive approach"),
      list("N log N","Comparisons needed"),
      list("Stable","Mergesort property")
    ),

    fluidRow(tabBox(width=12, id=ns("tabs"),

      tabPanel(title=tagList(icon("book")," Core Concepts"),
        fluidRow(
          box(title="\U0001f4ca The Sorting Algorithms", status="info", solidHeader=TRUE, width=7,
              algo_table(
                c("Algorithm","Time","Space","Stable?","Best for"),
                list(
                  list("Bubble Sort",    "O(N\u00b2)",     "O(1)",     "Yes", "Teaching, very small N"),
                  list("Insertion Sort", "O(N\u00b2)",     "O(1)",     "Yes", "Nearly-sorted data"),
                  list("Selection Sort", "O(N\u00b2)",     "O(1)",     "No",  "Minimising swaps"),
                  list("Mergesort",      "O(N log N)",  "O(N)",     "Yes", "Linked lists, stable sort needed"),
                  list("Quicksort",      "O(N log N)*", "O(log N)", "No",  "General purpose, cache-friendly"),
                  list("Heapsort",       "O(N log N)",  "O(1)",     "No",  "Memory-constrained environments"),
                  list("Timsort",        "O(N log N)",  "O(N)",     "Yes", "Python/Java built-in, real data"),
                  list("Counting Sort",  "O(N+k)",      "O(k)",     "Yes", "Integer data with small range"),
                  list("Radix Sort",     "O(Nk)",       "O(N+k)",   "Yes", "Fixed-length integers or strings")
                )
              ),
              div(class="info-box-plain",
                  HTML("<strong>\u2139 The information-theoretic lower bound:</strong> Any comparison-based sort
                        requires at least N\u00d7log\u2082(N) comparisons in the worst case. This is provable because
                        you must distinguish between N! possible orderings, and each comparison halves
                        the possibilities: log\u2082(N!) \u2248 N log N."))),

          box(title="\U0001f4a1 The Key Insight", status="warning", solidHeader=TRUE, width=5,
              div(class="framework-card",
                  tags$h5("Comparison is the Currency"),
                  tags$p("Every sorting algorithm, however clever, must ultimately make comparisons.
                          The number of comparisons is the true cost of sorting. Minimising comparisons
                          is the same as minimising time.")),
              div(class="framework-card",
                  tags$h5("The Decision Tree Model"),
                  tags$p("Any comparison sort corresponds to a binary decision tree. Each internal node
                          is a comparison; each leaf is a sorted order. There are N! leaves.
                          The minimum tree height (= minimum comparisons) is log\u2082(N!) \u2248 N log N.")),
              div(class="framework-card",
                  tags$h5("Bucket Sort Exception"),
                  tags$p("Non-comparison sorts (counting, radix, bucket) bypass this lower bound by using
                          information about the", tags$em("values"), "themselves, not just their relative order.
                          But they only work for restricted data types.")),
              div(class="tip-box",
                  HTML("<strong>\U0001f4a1 Quicksort's secret:</strong> Its expected O(N log N) with low
                        constant factors and excellent cache behaviour make it faster in practice than
                        algorithms with the same asymptotic complexity.")))
        ),
        fluidRow(
          box(title="\U0001f501 Why We Sort (and Why Not To)", status="success", solidHeader=TRUE, width=12,
              fluidRow(
                column(4,
                  div(class="framework-card",
                      tags$h5("Sorting for Search"),
                      tags$p("Binary search on a sorted array takes O(log N). Linear search on an unsorted
                              array takes O(N). If you search K times:"),
                      tags$p(tags$code("Sort + K binary searches: O(N log N + K log N)")),
                      tags$p(tags$code("K linear searches: O(KN)")),
                      tags$p("Sorting is worth it when K is large (many searches).")),
                  div(class="tip-box",
                      HTML("<strong>\U0001f4a1 Break-even point:</strong> Sorting pays off after approximately
                            log N searches. If you'll search the collection only once, linear search is better."))),
                column(4,
                  div(class="framework-card",
                      tags$h5("The Sports Ranking Problem"),
                      tags$p("Sorting teams by performance requires comparing them \u2014 but sports teams
                              don't play each other in a round-robin. This creates the",
                              tags$strong("intransitivity problem"),": A beats B, B beats C, but C beats A.")),
                  div(class="framework-card",
                      tags$h5("Elo Ratings"),
                      tags$p("Chess, tennis, and esports use Elo ratings to create a total order from
                              partial comparison data. Each match updates ratings based on expected vs
                              actual outcome. This is essentially online sorting under uncertainty."))),
                column(4,
                  div(class="insight-box",
                      tags$p(class="ib-title","WHEN NOT TO SORT"),
                      tags$p("If you only need the maximum or minimum: O(N) scan beats O(N log N) sort."),
                      tags$p("If you need the top-k: heapq.nlargest() is O(N log k), not O(N log N)."),
                      tags$p("If data arrives in a stream: online algorithms beat batch sorting."),
                      tags$p("If data is already nearly sorted: Insertion Sort's O(N) best case wins.")))
              )
          )
        )
      ),

      tabPanel(title=tagList(icon("users")," Human Applications"),
        fluidRow(
          box(title="\U0001f0cf Card Sorting", status="danger", solidHeader=TRUE, width=6,
              div(class="framework-card",
                  tags$h5("How Humans Sort Cards"),
                  tags$p("Watch how people sort playing cards. Most people instinctively use",
                          tags$strong("Insertion Sort"),": pick up each card and insert it into the correct
                          position in the growing sorted hand.")),
              div(class="framework-card",
                  tags$h5("Why Insertion Sort is Human-Optimal"),
                  tags$ul(
                    tags$li("Minimal movement: each card is placed once"),
                    tags$li("Works in a single pass through unsorted cards"),
                    tags$li("Excellent performance on nearly-sorted data"),
                    tags$li("O(N) on already-sorted input (rare in algorithms, common in practice)")
                  )),
              div(class="framework-card",
                  tags$h5("Merge Sort in Libraries"),
                  tags$p("Libraries sort returned books using Mergesort: sort small batches in-hand,
                          then merge the sorted batches onto the shelf. This is exactly the
                          merge phase of Mergesort."))),

          box(title="\U0001f3c6 Rankings & Tournaments", status="success", solidHeader=TRUE, width=6,
              div(class="framework-card",
                  tags$h5("Tournament Brackets as Sort"),
                  tags$p("A single-elimination tournament is a sorting algorithm. Each game is a comparison.
                          The tournament correctly identifies the best team (the winner), but",
                          tags$strong("not"), "the second-best: the runner-up may have lost only to the champion.")),
              div(class="framework-card",
                  tags$h5("Finding the Second Best"),
                  tags$p("To guarantee finding the second-best player:"),
                  tags$ol(
                    tags$li("Run the full tournament: N-1 comparisons, finds the best"),
                    tags$li("Run a secondary tournament among all", tags$em("players who lost to the champion")),
                    tags$li("Winner of secondary = second-best overall"),
                    tags$li("Extra comparisons needed:", tags$code("log\u2082 N - 1"))
                  )),
              pull_quote("A tournament tells you who's best. It takes much more work to know who's second.",
                         "Christian & Griffiths"))
        ),
        fluidRow(
          box(title="\U0001f4c8 Sorting in Everyday Life", status="primary", solidHeader=TRUE, width=12,
              algo_table(
                c("Domain","Human activity","Algorithm analogy","Key insight"),
                list(
                  list("Filing","Alphabetical file cabinets","Bucket sort by first letter","Pre-sort by category first"),
                  list("Email","Inbox sorting by sender/date","Radix sort","Multiple keys applied sequentially"),
                  list("Grocery shopping","Organising by aisle","Bucket sort","Group by location before sequence"),
                  list("Scheduling","Prioritising tasks","Comparison sort by urgency/importance","Each choice is a comparison"),
                  list("Sports","League tables","Merge sort of match results","Accumulate evidence progressively"),
                  list("Search","Google results ranking","Approximate sort","Good enough order, fast enough"),
                  list("Memory","Retrieving old memories","LRU approximation","Recently accessed = easier to find")
                )
              ))
        )
      ),

      tabPanel(title=tagList(icon("lightbulb")," Key Insights"),
        fluidRow(
          box(title="\U0001f914 The Philosophy of Order", status="info", solidHeader=TRUE, width=6,
              div(class="insight-box",
                  tags$p(class="ib-title","COMPARISON IS EXPENSIVE"),
                  tags$p("Every comparison you make \u2014 better/worse, more/less, prefer A or B \u2014
                          costs cognitive resources. The N log N lower bound applies to human decision-making
                          too. Don't sort when you don't need to.")),
              div(class="insight-box",
                  tags$p(class="ib-title","INTRANSITIVITY IS REAL"),
                  tags$p("Preferences are often non-transitive: A > B, B > C, C > A.
                          This isn't irrational \u2014 it's a fundamental feature of multi-attribute
                          comparison. Voting paradoxes, sports tournaments, and consumer choices
                          all exhibit this.")),
              div(class="insight-box",
                  tags$p(class="ib-title","THE BEST IS THE ENEMY OF THE SORTED"),
                  tags$p("Full sorting is usually overkill. Most real-world needs are satisfied by:
                          the top 5, the minimum, or a good-enough ordering. Use the right algorithm
                          for the actual need, not the most complete solution."))),
          box(title="\u2705 Practical Wisdom from Sorting", status="success", solidHeader=TRUE, width=6,
              div(class="framework-card",
                  tags$h5("For Individuals"),
                  tags$ul(
                    tags$li("You don't need to rank all your priorities \u2014 just know your top few"),
                    tags$li("Bubble sort your to-do list: pairwise compare, bubble the most urgent up"),
                    tags$li("Insertion sort new information: fit it into existing knowledge structure"),
                    tags$li("Group (bucket sort) before ordering: sort emails by project before by date")
                  )),
              div(class="framework-card",
                  tags$h5("For Organisations"),
                  tags$ul(
                    tags$li("Tournament-style reviews find the best candidate but miss #2 systematically"),
                    tags$li("Ranking employees is expensive and fragile \u2014 group into tiers instead"),
                    tags$li("League tables only work with enough head-to-head data \u2014 sparse data misleads"),
                    tags$li("When comparing options, make pair-wise choices rather than global rankings")
                  )),
              div(class="tip-box",
                  HTML("<strong>\U0001f4a1 The key lesson:</strong> Understand the cost of your comparisons
                        before sorting anything. Sometimes linear scan beats sort + search.
                        Always ask: how often will I search this?")))
        )
      )
    ))
  )
}
chapter3_server <- function(id) moduleServer(id, function(input,output,session){})
