# modules/chapter19.R — Dealing with Space Constraints

CH19_FILES <- list(
  list(
    name = "uppercase1.py",
    description = "<strong>uppercase1.py</strong> — New-array approach. O(N) time, O(N) extra space — allocates a second array.",
    code = 'def make_uppercase(array):
    new_array = []
    for string in array:
        new_array.append(string.upper())
    return new_array',
    demo = 'words = ["hello", "world", "python"]
print(f"Input:  {words}")
result = make_uppercase(words[:])
print(f"Output: {result}")
print(f"Original unchanged: {words}")'
  ),
  list(
    name = "uppercase2.py",
    description = "<strong>uppercase2.py</strong> — In-place approach. O(N) time, O(1) extra space — overwrites each element, no second array.",
    code = 'def make_uppercase(array):
    for index in range(len(array)):
        array[index] = array[index].upper()
    return array',
    demo = 'words = ["hello", "world", "python"]
print(f"Before: {words}")
make_uppercase(words)
print(f"After (in-place): {words}")'
  ),
  list(
    name = "duplicates1.py",
    description = "<strong>duplicates1.py</strong> — O(N²) time, O(1) space. Nested loops, no extra memory.",
    code = 'def has_duplicate_value(array):
    for i in range(len(array)):
        for j in range(len(array)):
            if (i != j) and (array[i] == array[j]):
                return True
    return False',
    demo = 'print(f"[1,2,3,4]   dup? {has_duplicate_value([1,2,3,4])}")
print(f"[1,2,2,3]   dup? {has_duplicate_value([1,2,2,3])}")
print(f"[1,2,3,4,1] dup? {has_duplicate_value([1,2,3,4,1])}")'
  ),
  list(
    name = "duplicates5.py",
    description = "<strong>duplicates5.py</strong> — O(N) time, O(N) space. Hash table for O(1) lookups — buys speed with memory.",
    code = 'def has_duplicate_value(array):
    existing_values = {}
    for value in array:
        if value not in existing_values:
            existing_values[value] = True
        else:
            return True
    return False',
    demo = 'print(f"[1,2,3,4]   dup? {has_duplicate_value([1,2,3,4])}")
print(f"[1,2,2,3]   dup? {has_duplicate_value([1,2,2,3])}")
print(f"[1,2,3,4,1] dup? {has_duplicate_value([1,2,3,4,1])}")'
  ),
  list(
    name = "duplicates6.py",
    description = "<strong>duplicates6.py</strong> — O(N log N) time, O(log N) space. Sort first, then scan adjacent pairs — middle ground between O(N²)/O(1) and O(N)/O(N).",
    code = 'def has_duplicate_value(array):
    array.sort()
    for i in range(len(array) - 1):
        if array[i] == array[i + 1]:
            return True
    return False',
    demo = 'print(f"[1,2,3,4]   dup? {has_duplicate_value([1,2,3,4])}")
print(f"[1,2,2,3]   dup? {has_duplicate_value([1,2,2,3])}")
print(f"[1,2,3,4,1] dup? {has_duplicate_value([1,2,3,4,1])}")'
  ),
  list(
    name = "solution3.py",
    description = "<strong>solution3.py</strong> — In-place array reversal using two pointers. O(N) time, O(1) space — swaps from outside in, no extra array.",
    code = 'def reverse(array):
    i = 0
    while i < len(array) // 2:
        mirror_of_i = len(array) - 1 - i
        array[i], array[mirror_of_i] = array[mirror_of_i], array[i]
        i += 1
    return array',
    demo = 'arr = [1, 3, 5, 7, 9]
print(f"Before: {arr}")
reverse(arr)
print(f"After:  {arr}")
arr2 = [1, 3, 5, 7]
print(f"\nBefore: {arr2}")
reverse(arr2)
print(f"After:  {arr2}")'
  ),
  list(
    name = "exercise4.py",
    description = "<strong>exercise4.py</strong> — Three versions of array doubling: (1) new array O(N) space, (2) in-place loop O(1) space, (3) recursive in-place O(N) call-stack space.",
    code = 'def double_array_1(array):
    """New array — O(N) space"""
    new_array = []
    for value in array:
        new_array.append(value * 2)
    return new_array

def double_array_2(array):
    """In-place loop — O(1) extra space"""
    for i in range(len(array)):
        array[i] *= 2
    return array

def double_array_3(array, index=0):
    """Recursive in-place — O(N) call-stack space"""
    if index >= len(array):
        return
    array[index] *= 2
    double_array_3(array, index + 1)
    return array',
    demo = 'original = [5, 4, 3, 2, 1]
print(f"double_array_1 (new array):  {double_array_1(original[:])}")
print(f"double_array_2 (in-place):   {double_array_2(original[:])}")
print(f"double_array_3 (recursive):  {double_array_3(original[:])}")'
  )
)

chapter19_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(19, "💾", "Dealing with Space Constraints",
      "Every algorithm uses both time and space. When time is the bottleneck we trade memory for speed; when memory is scarce we trade speed for space. This chapter formalises Big O space complexity and the time–space trade-off through concrete comparisons.",
      c("Space Complexity", "O(1) Extra Space", "O(N) Extra Space", "In-Place", "Time vs Space")),
    stats_row(
      list("O(1)",     "In-place extra space"),
      list("O(N)",     "Hash table space"),
      list("O(log N)", "Sort stack space"),
      list("3 axes",   "Time · Space · Clarity")
    ),
    fluidRow(
      tabBox(width = 12, id = ns("tabs"),
        tabPanel(title = tagList(icon("book"), " Theory"),
          fluidRow(
            box(title = "💾 Space Complexity", status = "info", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("What we measure"),
                    tags$p("Space complexity counts the", tags$strong("extra memory"), "an algorithm
                            allocates beyond its input. Input space is free — only additional
                            allocations count."),
                    tags$ul(
                      tags$li(tags$strong("O(1)"), " — a few variables; constant regardless of N"),
                      tags$li(tags$strong("O(log N)"), " — recursion depth of a balanced operation"),
                      tags$li(tags$strong("O(N)"), " — second array, hash table, N-deep recursion"),
                      tags$li(tags$strong("O(N²)"), " — adjacency matrix, pair comparison table")
                    )
                ),
                div(class = "tip-box",
                    HTML("<strong>💡 Recursion has hidden space cost:</strong> Each call frame is
                          pushed onto the call stack. A function that recurses N levels deep uses
                          O(N) space even if it declares no extra variables."))
            ),
            box(title = "⚖️ The Time–Space Trade-off", status = "warning", solidHeader = TRUE, width = 6,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Version"), tags$th("Time"), tags$th("Space"), tags$th("Strategy"))),
                  tags$tbody(
                    tags$tr(tags$td("duplicates1 (nested loops)"), tags$td("O(N²)"),     tags$td("O(1) ✅"), tags$td("No extra memory")),
                    tags$tr(tags$td("duplicates6 (sort+scan)"),    tags$td("O(N log N)"), tags$td("O(log N)"), tags$td("Balanced")),
                    tags$tr(tags$td("duplicates5 (hash table)"),   tags$td("O(N) ✅"),    tags$td("O(N)"),     tags$td("Buy speed with space"))
                  )
                ),
                div(class = "success-box",
                    HTML("<strong>✅ No universal winner:</strong> Choose based on your constraint.
                          Memory-limited embedded system? Pick O(N²)/O(1). Speed-critical server?
                          Pick O(N)/O(N). Medium data with sort available? O(N log N)/O(log N)."))
            )
          ),
          fluidRow(
            box(title = "🔄 In-Place vs Out-of-Place", status = "success", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("In-place: O(1) extra space"),
                    tags$ul(
                      tags$li(tags$code("uppercase2"), " — overwrite each element"),
                      tags$li(tags$code("solution3"), " — two-pointer swap from outside in"),
                      tags$li(tags$code("double_array_2"), " — multiply each index")
                    ),
                    tags$p("The input array is modified directly — destructive but memory-efficient.")
                ),
                div(class = "framework-card",
                    tags$h5("Out-of-place: O(N) extra space"),
                    tags$ul(
                      tags$li(tags$code("uppercase1"), " — allocates a new result array"),
                      tags$li(tags$code("double_array_1"), " — builds a doubled copy")
                    ),
                    tags$p("Preserves the original — safer but costs O(N) memory.")
                )
            ),
            box(title = "🌀 Recursion's Hidden Cost", status = "danger", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("double_array_3 vs double_array_2"),
                    tags$p("Both double an array in-place — identical output. But:"),
                    tags$ul(
                      tags$li(tags$code("double_array_2"), " — O(1) space, iterative"),
                      tags$li(tags$code("double_array_3"), " — O(N) space, N recursive frames")
                    ),
                    tags$p("The recursive version pushes N call frames onto the stack for an
                            array of size N.")
                ),
                div(class = "warn-box",
                    HTML("<strong>⚠ Rule of thumb:</strong> Prefer iteration over recursion when
                          space matters. A tail-call-optimised language can eliminate the overhead,
                          but Python does not perform tail-call optimisation."))
            )
          )
        ),
        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header(
            "Chapter 19 — Space Complexity",
            "Side-by-side comparisons: uppercase (new array vs in-place), duplicate detection (O(N²)/O(N log N)/O(N)), in-place reversal, and three array-doubling strategies."
          ),
          file_pills_ui(ns, CH19_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter19_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH19_FILES)
  })
}
