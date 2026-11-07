# modules/chapter10.R  — Recursively Recurse

CH10_FILES <- list(
  list(
    name = "factorial.py",
    description = "<strong>factorial.py</strong> — Classic recursive factorial. Base case: factorial(0) or factorial(1) = 1. Recursive case: n * factorial(n-1).",
    code = 'def factorial(number):\n    if number <= 1:\n        return 1\n    else:\n        return number * factorial(number - 1)',
    demo = 'for n in [0, 1, 2, 3, 5, 6, 10]:\n    print(f"factorial({n:2}) = {factorial(n)}")'
  ),
  list(
    name = "countdown_1.py",
    description = "<strong>countdown_1.py</strong> — Iterative countdown using a while loop.",
    code = 'def countdown(number):\n    while number >= 0:\n        print(number)\n        number -= 1',
    demo = 'print("Countdown from 5:")\ncountdown(5)'
  ),
  list(
    name = "countdown_3.py",
    description = "<strong>countdown_3.py</strong> — Recursive countdown. Base case: number == 0 (return). Recursive case: print then recurse with number-1.",
    code = 'def countdown(number):\n    print(number)\n    if number == 0:\n        return\n    else:\n        countdown(number - 1)',
    demo = 'print("Recursive countdown from 5:")\ncountdown(5)'
  ),
  list(
    name = "solution_3.py",
    description = "<strong>solution_3.py</strong> — Recursive sum from low to high. Base case: low == high. Recursive case: high + sum(low, high-1).",
    code = 'def sum(low, high):\n    if high == low:\n        return low\n    return high + sum(low, high - 1)',
    demo = 'print(f"sum(1, 10) = {sum(1, 10)}")\nprint(f"sum(1, 2)  = {sum(1, 2)}")\nprint(f"sum(5, 5)  = {sum(5, 5)}")'
  ),
  list(
    name = "solution_4.py",
    description = "<strong>solution_4.py</strong> — Recursively prints all items in a (possibly nested) array. Handles arbitrary depth of nesting.",
    code = 'def print_all_items(array):\n    for value in array:\n        if isinstance(value, list):\n            print_all_items(value)\n        else:\n            print(value)',
    demo = 'nested = [1, 2, [3, 4, [5, 6]], 7, [8, [9, 10]]]\nprint("Flat output of nested array:")\nprint_all_items(nested)'
  ),
  list(
    name = "exercise_1.py",
    description = "<strong>exercise_1.py</strong> — Recursively prints every other number from low to high (step 2).",
    code = 'def print_every_other(low, high):\n    if low > high:\n        return\n    print(low)\n    print_every_other(low + 2, high)',
    demo = 'print("Every other number 0 to 10:")\nprint_every_other(0, 10)'
  )
)

chapter10_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(10, "🔄", "Recursively Recurse",
      "Recursion is when a function calls itself. Mastering it requires understanding two things: the base case (when to stop) and how each call delegates work to a smaller version of itself.",
      c("Base Case", "Recursive Case", "Call Stack", "Factorial", "Filesystem Traversal")),
    stats_row(list("2","Parts of Recursion"), list("Base Case","Stop Condition"),
              list("O(N)","Most Recursive Fns"), list("Stack","Call Mechanism")),
    fluidRow(tabBox(width = 12, id = ns("tabs"),
      tabPanel(title = tagList(icon("book"), " Theory"),
        fluidRow(
          box(title = "🔄 The Two Parts of Recursion", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card", tags$h5("1. Base Case"),
                  tags$p("The condition under which the function stops calling itself. Without it, recursion is infinite."),
                  tags$p(tags$strong("Example:"), tags$code("if number <= 1: return 1"))),
              div(class = "framework-card", tags$h5("2. Recursive Case"),
                  tags$p("The function calls itself with a modified argument, moving toward the base case."),
                  tags$p(tags$strong("Example:"), tags$code("return number * factorial(number - 1)"))),
              div(class = "warn-box", HTML("<strong>⚠ Missing base case = infinite loop</strong> → stack overflow. Every recursive call uses call stack memory."))
          ),
          box(title = "📞 The Call Stack", status = "warning", solidHeader = TRUE, width = 6,
              div(class = "framework-card", tags$h5("How Recursion Uses the Stack"),
                  tags$p("Each recursive call pushes a new frame onto the call stack. When the base case is hit, frames start popping and returning values up the chain."),
                  tags$p(tags$strong("factorial(5) call chain:")),
                  tags$p(tags$code("factorial(5)"), " → calls factorial(4)"),
                  tags$p(tags$code("factorial(4)"), " → calls factorial(3)"),
                  tags$p("... (5 frames on the stack)"),
                  tags$p(tags$code("factorial(1)"), " → returns 1 (base case)"),
                  tags$p("All frames unwind and multiply: 5×4×3×2×1 = 120")),
              div(class = "info-box-plain", HTML("<strong>ℹ Stack depth:</strong> Deep recursion can overflow the call stack. Python's default limit is 1000 frames."))
          )
        ),
        fluidRow(
          box(title = "🌳 Recursion for Tree Structures", status = "success", solidHeader = TRUE, width = 12,
              fluidRow(
                column(6, div(class = "framework-card", tags$h5("Filesystem Traversal"),
                              tags$p("filesystem3.py uses recursion to walk arbitrarily deep directory trees. An iterative solution would need to manually manage a stack of paths."),
                              div(class = "success-box", HTML("<strong>✅ When recursion shines:</strong> Tree-shaped data structures where the depth is unknown.")))),
                column(6, div(class = "framework-card", tags$h5("Nested Array Flatten"),
                              tags$p("solution_4.py recursively prints all items from an array of arbitrary nesting depth. The recursive solution is cleaner and simpler than an iterative equivalent.")))
              )
          )
        )
      ),
      tabPanel(title = tagList(icon("code"), " Code Lab"),
        code_lab_header("Chapter 10 Code Files", "Iterative vs recursive countdown, factorial, recursive sum, nested array flattener, and every-other number."),
        file_pills_ui(ns, CH10_FILES),
        py_code_display(ns),
        terminal_ui(ns)
      )
    ))
  )
}

chapter10_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH10_FILES)
  })
}
