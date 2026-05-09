# Chapter 5: Scheduling — First Things First

chapter5_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(5,"\U0001f4cb","Scheduling",
      "You are a single-processor computer. Every day you must choose which tasks to run, in what order, and for how long. Computer science has developed provably optimal scheduling algorithms for every objective — minimise lateness, minimise incomplete tasks, maximise value — and they translate directly into human productivity.",
      c("Earliest Due Date","Shortest Job First","Moore's Algorithm","Weighted Scheduling","Preemption","Context Switching")),
    stats_row(list("EDD","Min max lateness"), list("SJF","Min average wait"), list("Moore's Alg","Min # late tasks"), list("0","Ideal context switches")),

    fluidRow(tabBox(width=12, id=ns("tabs"),
      tabPanel(title=tagList(icon("book")," Core Concepts"),
        fluidRow(
          box(title="\U0001f4ca Scheduling Objectives & Algorithms", status="info", solidHeader=TRUE, width=7,
              algo_table(c("Objective","Algorithm","Complexity","Rule"),
                list(list("Minimise maximum lateness","Earliest Due Date (EDD)","O(N log N)","Sort by deadline ascending"),
                     list("Minimise average completion time","Shortest Job First (SJF)","O(N log N)","Sort by duration ascending"),
                     list("Minimise # of late jobs","Moore's Algorithm","O(N log N)","EDD; drop longest job from overdue tasks"),
                     list("Maximise weighted value","Weighted Job Scheduling","O(N log N) + DP","Dynamic programming on intervals"),
                     list("Minimise weighted completion","WSPT Rule","O(N log N)","Sort by weight/time ratio descending"),
                     list("Preemptive minimise lateness","Earliest Deadline First (EDF)","O(N log N)","Always run nearest deadline"))),
              div(class="info-box-plain", HTML("<strong>\u2139 Key insight:</strong> Each objective has a <em>different</em>
                optimal algorithm. Before optimising your schedule, clarify what you are actually optimising for.
                Minimising lateness is not the same as minimising the number of late items."))),
          box(title="\U0001f522 The Three Core Rules", status="warning", solidHeader=TRUE, width=5,
              div(class="framework-card", tags$h5("1. Earliest Due Date (EDD)"),
                  tags$p("Sort all tasks by deadline (earliest first). Execute in that order."),
                  tags$p(tags$strong("Guarantees:"), " the latest any task finishes beyond its deadline is minimised.
                          No other ordering can reduce the worst-case lateness."),
                  div(class="tip-box", HTML("<strong>Use when:</strong> missing any deadline has serious consequences
                    and you want to spread lateness as evenly as possible."))),
              div(class="framework-card", tags$h5("2. Shortest Job First (SJF)"),
                  tags$p("Execute shortest tasks first. This minimises average waiting time across all tasks."),
                  div(class="tip-box", HTML("<strong>Use when:</strong> serving many people/requests fairly
                    \u2014 minimise the average time everyone spends waiting."))),
              div(class="framework-card", tags$h5("3. Moore's Algorithm"),
                  tags$p("To maximise number of on-time tasks: schedule by EDD, and whenever a task
                          would be late, discard the longest task so far in your schedule.")))
        ),
        fluidRow(
          box(title="\u26a1 Context Switching", status="danger", solidHeader=TRUE, width=12,
              fluidRow(
                column(4, div(class="framework-card", tags$h5("The Hidden Cost"),
                    tags$p("Every time a CPU switches from one task to another, it must save the current
                            state and load the new one. This overhead is called",tags$strong("context switching cost.")),
                    tags$p("In computers: microseconds. In humans:",tags$strong("23 minutes"),"to fully
                            regain deep focus after an interruption (Gloria Mark, UC Irvine)."))),
                column(4, div(class="framework-card", tags$h5("Thrashing"),
                    tags$p("When context switching overhead exceeds productive work, you get",
                           tags$strong("thrashing"),": the system appears busy but accomplishes nothing."),
                    tags$p("Signs of human thrashing: constantly switching tasks, perpetually busy but nothing gets finished,
                            perpetual inbox-zero anxiety.")),
                    div(class="warn-box", HTML("<strong>\u26a0 Interruption tax:</strong> If each task switch costs 23 minutes,
                      and you have 8 interruptions per day, that's 3 hours of lost deep work daily."))),
                column(4, div(class="insight-box",
                    tags$p(class="ib-title","AVOIDING THRASHING"),
                    tags$p("Batch similar tasks together (like grouped queries)."),
                    tags$p("Protect contiguous blocks of deep work time."),
                    tags$p("Turn off notifications (reduce interrupt rate)."),
                    tags$p("Use time-blocking: schedule task, not to-do lists."),
                    tags$p("Preempt low-priority tasks, not high-priority ones.")))
              )
          )
        )
      ),
      tabPanel(title=tagList(icon("users")," Human Applications"),
        fluidRow(
          box(title="\U0001f4c5 Personal Productivity", status="success", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("Your Daily Schedule as a CPU"),
                  tags$p("You have a finite number of working hours. Each task has a duration and possibly a deadline.
                          The question: in what order do you tackle them?")),
              algo_table(c("Your goal","Algorithm to use","Practical rule"),
                list(list("Don't miss any deadlines","EDD","Do deadlines first"),
                     list("Get most tasks done","Moore's","EDD; drop longest when behind"),
                     list("Serve others quickly","SJF","Do quickest tasks first"),
                     list("Maximise important work","WSPT","Do (importance/time) ratio first"),
                     list("Do deep work","Minimise preemption","Block time, batch interruptions"))),
              div(class="tip-box", HTML("<strong>\U0001f4a1 The 2-Minute Rule (David Allen):</strong>
                If a task takes less than 2 minutes, do it now. This is SJF \u2014 knock off the tiny
                tasks immediately to minimise average completion time."))),
          box(title="\U0001f3e5 Surgery Scheduling & Emergency Rooms", status="danger", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("Triage as Scheduling"),
                  tags$p("Emergency room triage is exactly scheduling theory: limited resources (doctors),
                          multiple tasks (patients) with different priorities and durations. The triage nurse
                          implements a priority queue.")),
              div(class="framework-card", tags$h5("Operating Theatre Scheduling"),
                  tags$p("Hospital operating theatres use weighted scheduling: each surgery has a duration,
                          a priority (urgency), and a value. Scheduling algorithms must balance:"),
                  tags$ul(tags$li("Emergency cases (high priority, must preempt)"),
                          tags$li("Elective cases (optimise throughput)"),
                          tags$li("Room utilisation (minimise idle time)"))),
              pull_quote("The goal is not to get everything done. The goal is to get the right things done in the right order.",
                         "Christian & Griffiths"))
        ),
        fluidRow(
          box(title="\U0001f4c8 Scheduling in Organisations", status="primary", solidHeader=TRUE, width=12,
              algo_table(c("Domain","Scheduling problem","Optimal algorithm","Key insight"),
                list(list("Call centre","Route calls to agents","Shortest expected service time first","Match task duration to agent skill"),
                     list("Agile sprint","Choose backlog items","Weighted by value/effort","WSPT maximises delivered value"),
                     list("Manufacturing","Job shop scheduling","NP-hard in general","Approximate with priority rules"),
                     list("Email triage","Reply to messages","SJF for quick replies, EDD for urgent","Batch by length"),
                     list("Legal billing","Order cases by court date","EDD for court dates","SJF for client satisfaction"),
                     list("Research","Order experiments","Shortest feasible experiment first","Build momentum, reduce bottlenecks")))
          )
        )
      ),
      tabPanel(title=tagList(icon("lightbulb")," Key Insights"),
        fluidRow(
          box(title="\U0001f4a1 Core Takeaways", status="warning", solidHeader=TRUE, width=6,
              div(class="insight-box", tags$p(class="ib-title","CLARIFY YOUR OBJECTIVE FIRST"),
                  tags$p("SJF and EDD are both optimal \u2014 for different objectives. Before any scheduling
                          decision, ask: what am I optimising? Lateness? Completion rate? Waiting time?
                          Value delivered? The answer changes the algorithm.")),
              div(class="insight-box", tags$p(class="ib-title","PREEMPTION IS EXPENSIVE"),
                  tags$p("Interrupting a task mid-flight and resuming later costs context-switching overhead.
                          In humans, this overhead is enormous. Batch your interruptions; protect contiguous
                          work blocks.")),
              div(class="insight-box", tags$p(class="ib-title","DROPPING TASKS IS SOMETIMES OPTIMAL"),
                  tags$p("Moore's Algorithm proves that the optimal strategy sometimes involves",
                         tags$em("deliberately not doing"), "certain tasks. When behind schedule,
                         dropping the longest remaining task may be the best choice."))),
          box(title="\u2705 Practical Scheduling Wisdom", status="success", solidHeader=TRUE, width=6,
              div(class="framework-card", tags$h5("The Scheduling Hierarchy"),
                  tags$ol(tags$li(tags$strong("Hard deadlines first"), " \u2014 EDD for anything with real consequences"),
                          tags$li(tags$strong("Quick tasks second"), " \u2014 SJF clears backlog quickly"),
                          tags$li(tags$strong("Important tasks third"), " \u2014 WSPT for high-value deep work"),
                          tags$li(tags$strong("Batch interruptions last"), " \u2014 protect focus blocks"))),
              div(class="framework-card", tags$h5("When You're Overwhelmed"),
                  tags$p("Moore's Algorithm gives you permission to drop tasks: when more is due than possible,
                          ruthlessly cut the longest task from your overdue list and reschedule or delegate it.")),
              div(class="framework-card", tags$h5("The Meta-Lesson"),
                  tags$p("No scheduling algorithm makes more time. They only improve how you use what you have.
                          Sometimes the right answer is to reduce the number of tasks, not to optimise their order.")))
        )
      )
    ))
  )
}
chapter5_server <- function(id) moduleServer(id, function(input,output,session){})
