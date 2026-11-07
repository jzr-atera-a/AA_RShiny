# Chapter 4: Caching — Forget About It

chapter4_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(4,"\U0001f4be","Caching",
      "Memory is expensive. Whether in computers or in minds, we can't keep everything readily accessible. The question isn't what to remember — it's what to forget. Mathematics shows that the Least Recently Used strategy is provably optimal, and it illuminates why human forgetting is a feature, not a flaw.",
      c("LRU Cache","Memory Hierarchy","Eviction Policies","Noguchi Filing","Cognitive Load","Forgetting Curve")),
    stats_row(list("LRU","Optimal eviction"), list("L1→L3→RAM→Disk","Memory hierarchy"), list("100x","Speed gap per level"), list("Forgetting","= Feature")),

    fluidRow(tabBox(width=12, id=ns("tabs"),
      tabPanel(title=tagList(icon("book")," Core Concepts"),
        fluidRow(
          box(title="\U0001f5c4\ufe0f The Memory Hierarchy", status="info", solidHeader=TRUE, width=6,
              algo_table(c("Level","Size","Access Time","Analogy"),
                list(list("CPU Register","~1 KB","< 1 ns","Things in hand"),
                     list("L1 Cache","64 KB","~1 ns","Desk surface"),
                     list("L2 Cache","256 KB","~4 ns","Desktop drawer"),
                     list("L3 Cache","8 MB","~10 ns","Filing cabinet"),
                     list("RAM","16 GB","~100 ns","Office bookshelf"),
                     list("SSD","1 TB","~0.1 ms","Office storage room"),
                     list("HDD","4 TB","~10 ms","Warehouse"),
                     list("Tape/Cloud","Unlimited","seconds","Off-site archive"))),
              div(class="tip-box", HTML("<strong>\U0001f4a1 The principle:</strong> Caching works because programs
                exhibit <em>temporal locality</em> \u2014 recently accessed data is likely to be accessed again soon.
                This is true of computers AND human memory."))),
          box(title="\U0001f504 Eviction Policies", status="warning", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("The Cache Full Problem"),
                  tags$p("When the cache is full and a new item must be loaded, something must be evicted.
                          Which item should go?")),
              algo_table(c("Policy","Rule","Optimal?","Why"),
                list(list("LRU","Evict least recently used","Near-optimal","Temporal locality assumption"),
                     list("MRU","Evict most recently used","No","Rarely useful"),
                     list("FIFO","Evict oldest inserted","No","Ignores recency"),
                     list("LFU","Evict least frequently used","No","Ignores recency"),
                     list("Random","Evict random item","Surprisingly OK","Simple, no state needed"),
                     list("Optimal (Bélády)","Evict item used furthest in future","Yes (oracle)","Requires future knowledge"))),
              div(class="success-box", HTML("<strong>\u2705 LRU wins:</strong> Proven to be the best eviction strategy
                without knowledge of the future, achieving performance close to the optimal (Bélády's) algorithm.")))
        ),
        fluidRow(
          box(title="\U0001f9e0 The Noguchi Filing System", status="success", solidHeader=TRUE, width=12,
              fluidRow(
                column(4, div(class="framework-card", tags$h5("The System"),
                    tags$p("Japanese economist Noguchi devised a filing system: store all papers in uniform envelopes,
                            arranged in a single row. Whenever you use a file, put it back at the LEFT end."),
                    tags$p("Result: recently used files cluster at the left; rarely used files drift right.
                            This is a physical implementation of LRU."))),
                column(4, div(class="framework-card", tags$h5("Why It Works"),
                    tags$ul(tags$li("No categorisation needed \u2014 the algorithm self-organises"),
                            tags$li("Frequently used files are always near the front (fast access)"),
                            tags$li("Old files drift to the back and are effectively 'evicted' from active memory"),
                            tags$li("No decision-making required \u2014 the rule is simple and automatic")),
                    div(class="tip-box", HTML("<strong>\U0001f4a1 Apply this:</strong> Stack your paper inbox the same way.
                      Files you touch often stay on top naturally.")))),
                column(4, div(class="insight-box",
                    tags$p(class="ib-title","LRU IN YOUR LIFE"),
                    tags$p("Your browser history uses LRU."),
                    tags$p("Your phone's recent apps use LRU."),
                    tags$p("Your brain uses something like LRU."),
                    tags$p("The Noguchi method makes LRU physical."),
                    tags$p("Email clients default to recency sort."),
                    tags$p("All of these exploit temporal locality.")))
              )
          )
        )
      ),
      tabPanel(title=tagList(icon("users")," Human Applications"),
        fluidRow(
          box(title="\U0001f9e0 Human Memory as Cache", status="danger", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("The Three-Level Human Cache"),
                  tags$ul(tags$li(tags$strong("Working memory (L1):")," ~7 items, milliseconds, the 'magic number seven'"),
                          tags$li(tags$strong("Short-term memory (L2):")," Hours-days, recently experienced events"),
                          tags$li(tags$strong("Long-term memory (RAM/Disk):")," Lifetime, vast capacity, slow retrieval"))),
              div(class="framework-card", tags$h5("Forgetting as Feature"),
                  tags$p("Ebbinghaus's forgetting curve shows memory decays exponentially.
                          But this isn't a bug \u2014 it's LRU eviction. Items not recently accessed are
                          moved to slower storage (or evicted)."),
                  tags$p("The brain is optimising for retrieval speed of useful information,
                          not total storage.")),
              pull_quote("Forgetting is not a failure of memory. It is memory doing its job.",
                         "Christian & Griffiths")),
          box(title="\U0001f4da Practical Caching Strategies", status="success", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("For Physical Spaces"),
                  tags$ul(tags$li("Always return used items to the same front/top position"),
                          tags$li("Let rarely used items drift to the back naturally"),
                          tags$li("Don't fight the LRU pattern \u2014 it's optimal"))),
              div(class="framework-card", tags$h5("For Digital Information"),
                  tags$ul(tags$li("Don't obsessively file emails \u2014 search is O(log N), filing is O(N)"),
                          tags$li("Let recency sort do the work; your inbox IS your cache"),
                          tags$li("Bookmarks are a cache: keep only what you actually use"))),
              div(class="framework-card", tags$h5("For Knowledge Work"),
                  tags$ul(tags$li("Keep active project materials on your desk (L1 cache)"),
                          tags$li("Archive completed work to shelves or cloud (L3/disk)"),
                          tags$li("Don't fight context switches \u2014 they're cache misses; minimise them"))),
              div(class="info-box-plain", HTML("<strong>\u2139 The cognitive overhead of filing:</strong>
                  Every time you file something in a category, you must decide: which category?
                  LRU filing (recency order) eliminates this decision.")))
        )
      ),
      tabPanel(title=tagList(icon("lightbulb")," Key Insights"),
        fluidRow(
          box(title="\U0001f4a1 Core Takeaways", status="warning", solidHeader=TRUE, width=6,
              div(class="insight-box", tags$p(class="ib-title","FORGETTING IS RATIONAL"),
                  tags$p("Human forgetting follows the same logic as LRU eviction. The things you
                          forget are, by definition, the things you haven't needed recently.
                          Worrying about forgetting is like worrying that your cache is working.")),
              div(class="insight-box", tags$p(class="ib-title","RECENCY IS THE BEST SIGNAL"),
                  tags$p("If you don't know what you'll need next, assume you'll need what you
                          needed most recently. This is the temporal locality assumption, and
                          it's true for computer programs, human tasks, and everyday objects.")),
              div(class="insight-box", tags$p(class="ib-title","FILING IS OFTEN WRONG"),
                  tags$p("Traditional filing (alphabetical, categorical) ignores temporal locality.
                          Recency-based storage (the Noguchi method, a single inbox) is often
                          faster in practice because it matches how you actually look for things."))),
          box(title="\u2696\ufe0f Cache Performance Summary", status="info", solidHeader=TRUE, width=6,
              algo_table(c("Situation","Best approach","Why"),
                list(list("Small collection (N < 20)","Any order","All fits in working memory"),
                     list("Large static collection","Alphabetical","Binary search O(log N)"),
                     list("Large dynamic collection","LRU (recency)","Temporal locality"),
                     list("Email/documents","Single inbox, search","LRU + fast search"),
                     list("Physical files","Noguchi (recency row)","Physical LRU"),
                     list("Knowledge retention","Spaced repetition","Controlled cache eviction"),
                     list("Projects on desk","Active on surface","L1 cache principle"))),
              div(class="success-box", HTML("<strong>\u2705 Spaced repetition = explicit cache management:</strong>
                Anki and similar tools artificially re-access memories before they're evicted, keeping
                them in 'fast storage'. This is cache pre-fetching for the human brain.")))
        )
      )
    ))
  )
}
chapter4_server <- function(id) moduleServer(id, function(input,output,session){})
