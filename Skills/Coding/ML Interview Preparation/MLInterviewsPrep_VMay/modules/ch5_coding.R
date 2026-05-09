# modules/ch5_coding.R
# Ch.5: Technical Interview — Coding

ch5_coding_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(class = "meta-hero",
      tags$h1("Chapter 5 — Technical Interview: Coding"),
      tags$h2("Python, SQL, Brainteasers & Coding Interview Strategy — Susan Shu Chang"),
      div(
        span(class = "hero-badge", "Python Roadmap"),
        span(class = "hero-badge", "Coding Tips"),
        span(class = "hero-badge", "ML Python Questions"),
        span(class = "hero-badge", "SQL"),
        span(class = "hero-badge", "Brainteasers"),
        span(class = "hero-badge", "Roadmaps")
      )
    ),

    # ── Python Roadmap ────────────────────────────────────────────────────────
    fluidRow(
      box(title = "🐍 Starting from Scratch: Python Learning Roadmap (Ch.5)", status = "primary",
          solidHeader = TRUE, width = 6,

          div(class = "success-box",
            HTML("<strong>Chang's advice:</strong> You do not need to master computer science fundamentals
                 before starting ML. Learn Python in parallel with ML concepts — practical
                 coding beats theoretical completeness for interviews.")),
          br(),

          div(class = "framework-card",
            tags$h5("Step 1 — Pick Up a Book or Course That is Easy to Understand"),
            tags$ul(
              tags$li(tags$b("Recommended starts:"), " Python Crash Course, Automate the Boring Stuff, fast.ai"),
              tags$li(tags$b("Avoid:"), " starting with academic CS theory — it slows practical progress"),
              tags$li(tags$b("Focus on:"), " lists, dicts, loops, functions, classes, file I/O"),
              tags$li(tags$b("Time box:"), " spend no more than 2–4 weeks on pure Python basics before applying to ML problems")
            )),

          div(class = "framework-card",
            tags$h5("Step 2 — Start with Easy Questions on LeetCode / HackerRank"),
            tags$ul(
              tags$li(tags$b("Platform choice:"), " LeetCode, HackerRank, Codewars — pick one and stick to it"),
              tags$li(tags$b("Start at Easy:"), " build confidence before attempting Medium difficulty"),
              tags$li(tags$b("Pattern focus:"), " two pointers, hash maps, sliding window, BFS/DFS — these recur"),
              tags$li(tags$b("ML interviews:"), " rarely go beyond Medium LeetCode — data structures over algorithms")
            )),

          div(class = "framework-card",
            tags$h5("Step 3 — Set a Measurable Target and Practice, Practice, Practice"),
            tags$ul(
              tags$li(tags$b("Define the target:"), " e.g. solve 3 Easy + 1 Medium per day for 4 weeks"),
              tags$li(tags$b("Track progress:"), " spreadsheet of solved problems + time taken"),
              tags$li(tags$b("Review wrong answers:"), " more valuable than solving new problems"),
              tags$li(tags$b("Spaced repetition:"), " revisit problems after 3 days, 1 week, 2 weeks")
            )),

          div(class = "framework-card",
            tags$h5("Step 4 — Try Out ML-Related Python Packages"),
            tags$ul(
              tags$li(tags$b("numpy:"), " array operations, broadcasting, vectorised computation"),
              tags$li(tags$b("pandas:"), " DataFrame manipulation — groupby, merge, pivot, apply"),
              tags$li(tags$b("scikit-learn:"), " Pipeline, transformers, cross_val_score, GridSearchCV"),
              tags$li(tags$b("matplotlib / seaborn:"), " EDA visualisation"),
              tags$li(tags$b("PyTorch / TensorFlow:"), " tensor ops, autograd, model training loop")
            ))
      ),

      box(title = "🏆 Coding Interview Success Tips (Ch.5)", status = "info",
          solidHeader = TRUE, width = 6,

          div(class = "warn-box",
            HTML("<strong>⚠️ Chang's insight:</strong> Most candidates who fail coding interviews do so
                 not because they cannot solve the problem, but because they communicate poorly
                 during the attempt. These tips address that.")),
          br(),

          div(class = "framework-card",
            tags$h5("Think Out Loud"),
            tags$p("Narrate your thought process before and during coding."),
            tags$ul(
              tags$li("State your understanding of the problem before writing any code"),
              tags$li("Articulate the approach: 'I am thinking of using a hash map because...'"),
              tags$li("Name the time and space complexity as you design the solution"),
              tags$li("If stuck, say so out loud — interviewers can guide if they know where you are")
            )),

          div(class = "framework-card",
            tags$h5("Control the Flow"),
            tags$ul(
              tags$li(tags$b("Clarify edge cases first:"), " empty input, None, negative numbers, overflow"),
              tags$li(tags$b("Write pseudocode:"), " outline the algorithm before writing real code"),
              tags$li(tags$b("Solve simply first:"), " get a working solution before optimising"),
              tags$li(tags$b("Test with examples:"), " walk through your code with the given example"),
              tags$li(tags$b("Then optimise:"), " improve time/space complexity if time permits")
            )),

          div(class = "framework-card",
            tags$h5("Your Interviewer Can Help You Out"),
            tags$ul(
              tags$li("Interviewers want you to succeed — they are not adversarial"),
              tags$li("If stuck for more than 5 minutes, ask for a hint directly: 'Am I on the right track?'"),
              tags$li("Partial solutions with clear reasoning score better than silence")
            )),

          div(class = "framework-card",
            tags$h5("Optimise Your Environment"),
            tags$ul(
              tags$li(tags$b("CoderPad / LeetCode:"), " practice in the same environment used in interviews"),
              tags$li(tags$b("No autocomplete:"), " practice without IDE assistance — interviews often lack it"),
              tags$li(tags$b("Typing speed:"), " slow typing kills confidence — practice touch-typing code")
            )),

          div(class = "success-box",
            HTML("<strong>✅ Interviews Require Energy!</strong> Chang emphasises physical and mental
                 preparation: sleep well the night before, eat before the interview, schedule
                 your hardest interviews later in your pipeline when you are warmed up."))
      )
    ),

    # ── Python ML Questions ───────────────────────────────────────────────────
    fluidRow(
      box(title = "🔢 Python Coding Interview: Data- and ML-Related Questions (Ch.5)", status = "warning",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
              div(class = "framework-card",
                tags$h5("Sample Data- and ML-Related Questions"),
                tags$ul(
                  tags$li("Implement k-means clustering from scratch"),
                  tags$li("Write a function to compute precision and recall from predictions"),
                  tags$li("Implement a simple linear regression using gradient descent"),
                  tags$li("Given a dataset with missing values, impute with column mean"),
                  tags$li("Implement train/test split without using sklearn"),
                  tags$li("Compute the confusion matrix for a binary classifier"),
                  tags$li("Write a function to normalise features to [0, 1]"),
                  tags$li("Implement softmax from scratch using numpy")
                )
              )
            ),
            column(4,
              div(class = "framework-card",
                tags$h5("FAQs for Data- and ML-Focused Interviews"),
                tags$ul(
                  tags$li(tags$b("pandas vs numpy:"), " pandas for labelled, structured data; numpy for numerical arrays and math"),
                  tags$li(tags$b("How to read a CSV:"), " pd.read_csv() — always inspect head(), dtypes, isnull().sum()"),
                  tags$li(tags$b("GroupBy:"), " df.groupby('col').agg({'val': 'mean'}) — interviewer favourite"),
                  tags$li(tags$b("Merge types:"), " inner, left, right, outer — know the difference"),
                  tags$li(tags$b("Apply vs vectorise:"), " vectorised pandas ops (100x) faster than row-wise apply"),
                  tags$li(tags$b("List comprehension:"), " preferred Pythonic pattern — interviewers notice")
                )
              )
            ),
            column(4,
              div(class = "framework-card",
                tags$h5("Resources for Data and ML Interview Questions"),
                tags$ul(
                  tags$li(tags$b("LeetCode:"), " filter by 'Data Science' tag for relevant problems"),
                  tags$li(tags$b("StrataScratch:"), " SQL + Python questions from real companies"),
                  tags$li(tags$b("DataLemur:"), " curated SQL and stats questions"),
                  tags$li(tags$b("Kaggle notebooks:"), " practice pandas and sklearn pipelines on real data"),
                  tags$li(tags$b("ML from scratch:"), " implement logistic regression, decision tree, k-means in numpy")
                )
              ),
              div(class = "tip-box",
                HTML("<strong>💡 Key habit:</strong> For every sklearn function you use,
                     also implement it from scratch once. Interviewers often ask:
                     'How would you implement this without the library?'"))
            )
          )
      )
    ),

    # ── Brainteasers ──────────────────────────────────────────────────────────
    fluidRow(
      box(title = "🧩 Python Coding Interview: Brainteaser Questions (Ch.5)", status = "primary",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("Patterns for Brainteaser Programming Questions"),
            tags$p("Brainteasers test algorithmic thinking — pattern recognition matters more than memorising solutions."),
            tags$ul(
              tags$li(tags$b("Two pointers:"), " sorted arrays, palindrome detection, container with most water"),
              tags$li(tags$b("Sliding window:"), " max subarray sum, longest substring without repeats"),
              tags$li(tags$b("Hash map (dict):"), " two-sum, group anagrams, first unique character"),
              tags$li(tags$b("Binary search:"), " sorted array problems — O(log n) vs O(n) signal"),
              tags$li(tags$b("DFS / BFS:"), " tree traversal, connected components, shortest path"),
              tags$li(tags$b("Dynamic programming:"), " Fibonacci, coin change, longest common subsequence"),
              tags$li(tags$b("Stack / queue:"), " valid parentheses, next greater element, BFS level-order")
            )),

          div(class = "framework-card",
            tags$h5("Resources for Brainteaser Programming Questions"),
            tags$ul(
              tags$li(tags$b("LeetCode Top 75:"), " curated list covering all key patterns"),
              tags$li(tags$b("Cracking the Coding Interview:"), " classic for pattern-based learning"),
              tags$li(tags$b("NeetCode.io:"), " free YouTube solutions with pattern explanations"),
              tags$li(tags$b("AlgoExpert:"), " structured course with video explanations")
            )),

          div(class = "warn-box",
            HTML("<strong>⚠️ Chang's note:</strong> ML engineer interviews rarely go beyond LeetCode Medium.
                 Do not over-invest in Hard problems at the expense of ML depth and system design prep."))
      ),

      box(title = "🗃️ SQL Coding Interview: Data-Related Questions (Ch.5)", status = "info",
          solidHeader = TRUE, width = 6,

          div(class = "framework-card",
            tags$h5("Core SQL Patterns Tested in ML Interviews"),
            tags$ul(
              tags$li(tags$b("Aggregations:"), " GROUP BY, HAVING, COUNT, SUM, AVG, MAX, MIN"),
              tags$li(tags$b("Joins:"), " INNER, LEFT, RIGHT, FULL OUTER — and when each is appropriate"),
              tags$li(tags$b("Window functions:"), " ROW_NUMBER(), RANK(), LAG(), LEAD(), SUM() OVER(PARTITION BY ...)"),
              tags$li(tags$b("CTEs:"), " WITH clause — cleaner than nested subqueries, easier to reason about"),
              tags$li(tags$b("CASE WHEN:"), " conditional logic inside SELECT — used for binning, pivoting"),
              tags$li(tags$b("Date functions:"), " DATEADD, DATEDIFF, DATE_TRUNC — common in analytics queries"),
              tags$li(tags$b("Self joins:"), " comparing rows within the same table — e.g. find consecutive logins")
            )),

          div(class = "framework-card",
            tags$h5("Sample SQL Interview Questions"),
            tags$ul(
              tags$li("Find the top 3 products by revenue in each category"),
              tags$li("Calculate 7-day rolling average of daily active users"),
              tags$li("Identify users who logged in on consecutive days"),
              tags$li("Find the second highest salary in each department"),
              tags$li("Calculate retention rate: users active in month N who return in month N+1")
            )),

          div(class = "framework-card",
            tags$h5("Resources for SQL Coding Interview Questions"),
            tags$ul(
              tags$li(tags$b("Mode Analytics SQL Tutorial:"), " free, progressive, browser-based"),
              tags$li(tags$b("StrataScratch:"), " real company SQL problems with solutions"),
              tags$li(tags$b("DataLemur:"), " curated medium-difficulty analytics SQL"),
              tags$li(tags$b("LeetCode Database section:"), " classic problems (Consecutive Numbers, Nth Highest Salary)")
            ))
      )
    ),

    # ── Coding Roadmaps ───────────────────────────────────────────────────────
    fluidRow(
      box(title = "🗺️ Roadmaps for Preparing for Coding Interviews (Ch.5)", status = "success",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
              div(class = "framework-card",
                tags$h5("Roadmap: Four Weeks, University Student"),
                tags$p("For candidates who have limited ML work experience but strong coding fundamentals."),
                timeline_entry("Week 1", "Python & numpy foundations",
                  "Complete a Python refresher. Implement matrix ops, broadcasting, vectorised functions in numpy."),
                timeline_entry("Week 2", "pandas & sklearn fluency",
                  "GroupBy, merge, pivot, apply. Build a full sklearn Pipeline with cross-validation."),
                timeline_entry("Week 3", "LeetCode Easy + ML questions",
                  "Solve 15 LeetCode Easy problems. Implement linear regression and k-means from scratch."),
                timeline_entry("Week 4", "SQL + mock interviews",
                  "Complete 10 SQL problems (StrataScratch). Record yourself in two mock interview sessions.")
              )
            ),
            column(4,
              div(class = "framework-card",
                tags$h5("Roadmap: Six Months, Career Transition"),
                tags$p("For candidates transitioning from software engineering or data analysis."),
                timeline_entry("Month 1", "Python ML ecosystem",
                  "pandas, numpy, sklearn API. Build 3 end-to-end ML pipelines on Kaggle datasets."),
                timeline_entry("Month 2", "Algorithms & LeetCode",
                  "60 Easy + 30 Medium. Focus on hash maps, arrays, two pointers, binary search."),
                timeline_entry("Month 3", "ML algorithms depth",
                  "Study Ch.3 algorithms. Implement logistic regression, decision tree, k-means from scratch."),
                timeline_entry("Month 4", "Model training & eval",
                  "Study Ch.4. Practice evaluation plan design. Learn MLflow for experiment tracking."),
                timeline_entry("Month 5", "Deployment + System Design",
                  "Study Ch.6 and Ch.5 system design sections. Design 5 production ML systems."),
                timeline_entry("Month 6", "Mock interviews",
                  "2 mock sessions per week. Record and review. Focus on communication improvement.")
              )
            ),
            column(4,
              div(class = "framework-card",
                tags$h5("Roadmap: Create Your Own!"),
                tags$p("Chang provides a framework to build a personalised prep roadmap."),
                tags$ul(
                  tags$li(tags$b("Assess your starting point:"), " rate yourself 1–10 on Python, SQL, ML theory, system design"),
                  tags$li(tags$b("Define your target role:"), " MLE, DS, MLOps, Applied Scientist — each has different weightings"),
                  tags$li(tags$b("Set a timeline:"), " realistic given hours per week available for prep"),
                  tags$li(tags$b("Identify gaps:"), " biggest gap gets the most time — not your strengths"),
                  tags$li(tags$b("Weekly sprint:"), " define specific deliverables (X problems, Y chapters) per week"),
                  tags$li(tags$b("Mock interviews:"), " start after week 4 minimum — before that, you need base knowledge")
                )
              ),
              div(class = "success-box",
                HTML("<strong>✅ Chang's meta-advice:</strong> The roadmap is less important than
                     consistency. Showing up for 1 hour every day beats
                     10 hours on weekends for interview prep retention."))
            )
          )
      )
    ),

    fluidRow(
      box(title = "✍️ Practice: Code Your Own Solution", status = "success",
          solidHeader = TRUE, width = 12,

          fluidRow(
            column(4,
              selectInput(ns("code_topic"), "Choose a practice area:",
                choices = c(
                  "Implement precision and recall from scratch",
                  "Write a train/test split function",
                  "SQL: rolling 7-day DAU average",
                  "SQL: top N by group",
                  "Implement normalisation without sklearn",
                  "Python: groupby and aggregate with pandas",
                  "LeetCode pattern: two-sum with hash map",
                  "Implement softmax in numpy"
                )),
              sliderInput(ns("code_conf"), "Confidence in coding interviews (1–10):", 1, 10, 5),
              actionButton(ns("save_code"), "Save Assessment", class = "btn-meta", width = "100%")
            ),
            column(8,
              div(class = "practice-area",
                tags$b("Practice: Write your solution and self-assess against Chang's 4 criteria."),
                textAreaInput(ns("code_notes"), label = NULL, rows = 9, width = "100%",
                  placeholder = "## Your solution or pseudocode\n\n## Edge cases considered\n\n## Time complexity\n\n## Space complexity\n\n## How you would explain this out loud to an interviewer"),
                uiOutput(ns("code_feedback"))
              )
            )
          )
      )
    )
  )
}

ch5_coding_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$save_code, {
      notes <- input$code_notes
      conf  <- input$code_conf
      score <- 0
      if (grepl("def |function|solution|pseudocode|algorithm",    notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("edge|empty|null|none|negative|overflow|corner",  notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("O\\(|time complex|space complex|O\\(n|O\\(log",  notes, ignore.case = TRUE)) score <- score + 25
      if (grepl("explain|out loud|interviewer|said|would say",    notes, ignore.case = TRUE)) score <- score + 25

      prep_manager$update_progress("ch5_coding", min(score + conf * 3, 100))
      prep_manager$save_note("ch5_notes", notes)

      output$code_feedback <- renderUI({
        div(class = if (score >= 75) "success-box" else "tip-box",
          tags$h5(paste0("Coding Practice Score: ", score, "/100")),
          if (score < 25)  tags$p("⚠️ Missing: actual solution or pseudocode"),
          if (score < 50)  tags$p("⚠️ Missing: edge cases (empty input, null, negative numbers)"),
          if (score < 75)  tags$p("⚠️ Missing: time and space complexity analysis"),
          if (score < 100) tags$p("⚠️ Missing: how you would explain this out loud to an interviewer"),
          if (score >= 75) tags$p("✅ All 4 criteria met — strong coding interview structure!")
        )
      })
      showNotification("Ch.5 coding assessment saved!", type = "message")
    })
  })
}
