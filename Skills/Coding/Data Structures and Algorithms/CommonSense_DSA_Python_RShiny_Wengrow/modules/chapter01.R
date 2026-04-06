# modules/chapter01.R  — Why Data Structures Matter

CH01_FILES <- list(
  list(
    name = "hello.py",
    description = "<strong>hello.py</strong> — The book's very first function. A minimal example confirming the Python runtime works.",
    code = 'def say_hello():
    return "hello"',
    demo = 'result = say_hello()
print(f"say_hello() -> {result!r}")'
  ),
  list(
    name = "print_numbers.py",
    description = "<strong>print_numbers.py</strong> — Two versions of printing even numbers. Version 1 checks every number (N steps); Version 2 skips to even numbers (~N/2 steps). Same output, different efficiency.",
    code = 'def print_numbers_version_one():
    number = 2
    while number <= 100:
        if number % 2 == 0:
            print(number)
        number += 1

def print_numbers_version_two():
    number = 2
    while number <= 100:
        print(number)
        number += 2',
    demo = 'print("=== Version 1 (even numbers 2-20) ===")
number = 2
while number <= 20:
    if number % 2 == 0:
        print(number)
    number += 1
print("\\n=== Version 2 (even numbers 2-20) ===")
number = 2
while number <= 20:
    print(number)
    number += 2'
  )
)

chapter1_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(1, "\U0001f4e6", "Why Data Structures Matter",
      "Data structures organise information so it can be used effectively. The choice of structure determines the speed of your four fundamental operations: Read, Search, Insert, Delete.",
      c("Arrays", "Sets", "Read \u00b7 Search \u00b7 Insert \u00b7 Delete", "O(1) vs O(N)")),
    stats_row(list("4","Core Operations"), list("O(1)","Array Read"),
              list("O(N)","Array Search"), list("O(N)","Insert / Delete")),
    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory"),
          fluidRow(
            box(title = "\U0001f4e6 What is a Data Structure?", status = "info", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("Definition"),
                    tags$p("A data structure is a way of organising data in a computer so it can be used efficiently. Different structures offer different trade-offs for the four core operations.")),
                div(class = "tip-box", HTML("<strong>\U0001f4a1 Key Insight:</strong> The choice of data structure is the single biggest factor in how fast your program runs for a given task.")),
                div(class = "framework-card",
                    tags$h5("Common Data Structures"),
                    tags$ul(
                      tags$li(tags$strong("Array"), " \u2014 contiguous block of memory, indexed"),
                      tags$li(tags$strong("Set"), " \u2014 like array, but no duplicates allowed"),
                      tags$li(tags$strong("Hash Table"), " \u2014 key/value pairs (Ch 8)"),
                      tags$li(tags$strong("Linked List, Tree, Graph"), " \u2014 later chapters")
                    ))
            ),
            box(title = "\u2699\ufe0f The Four Operations", status = "warning", solidHeader = TRUE, width = 6,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Operation"), tags$th("Array"), tags$th("Set"), tags$th("Why?"))),
                  tags$tbody(
                    tags$tr(tags$td("Read (by index)"),  tags$td("1 step"),    tags$td("1 step"),    tags$td("Direct memory address")),
                    tags$tr(tags$td("Search (by value)"),tags$td("Up to N"),   tags$td("Up to N"),   tags$td("Must check each element")),
                    tags$tr(tags$td("Insert"),           tags$td("Up to N+1"), tags$td("Up to 2N+1"),tags$td("Set must search first")),
                    tags$tr(tags$td("Delete"),           tags$td("Up to N"),   tags$td("Up to N"),   tags$td("Shift elements left"))
                  )
                ),
                div(class = "info-box-plain", HTML("<strong>\u2139 Sets:</strong> Prevents duplicates \u2014 before inserting, must search the whole structure. Insertion is twice as expensive as for arrays."))
            )
          ),
          fluidRow(
            box(title = "\U0001f3af Insertion Position Matters", status = "success", solidHeader = TRUE, width = 6,
                div(class = "framework-card", tags$h5("Inserting at end"),    tags$p("Just 1 step \u2014 add the value.")),
                div(class = "framework-card", tags$h5("Inserting at index 0"),tags$p("Shift ALL N elements right, then insert \u2192 N+1 steps.")),
                div(class = "framework-card", tags$h5("Inserting in the middle"), tags$p("Shift half the elements on average \u2192 ~N/2 steps."))
            ),
            box(title = "\U0001f5d1 Deletion", status = "danger", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("Why deletion is slow"),
                    tags$p("Deletion creates a gap in memory. Arrays fill gaps by shifting subsequent elements left \u2014 up to N shifts for deletion at index 0.")),
                div(class = "success-box", HTML("<strong>\u2705 Rule of Thumb:</strong> When you need fast random access (reads), arrays excel. For frequent insertions/deletions at arbitrary positions, linked lists or other structures may be better."))
            )
          )
        ),

        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header("Chapter 1 Code Files", "The book's opening Python examples \u2014 function basics and printing even numbers with two different algorithmic approaches."),
          file_pills_ui(ns, CH01_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter1_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH01_FILES)
  })
}
