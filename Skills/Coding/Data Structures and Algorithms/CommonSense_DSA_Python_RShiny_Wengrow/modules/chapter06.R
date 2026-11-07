# modules/chapter06.R  — Optimizing for Optimistic Scenarios

CH06_FILES <- list(
  list(
    name = "insertion_sort.py",
    description = "<strong>insertion_sort.py</strong> — O(N) best case (sorted), O(N\u00b2) worst case (reversed). Ideal for nearly-sorted data.",
    code = 'def insertion_sort(array):
    for index in range(1, len(array)):
        temp_value = array[index]
        position = index - 1
        while position >= 0:
            if array[position] > temp_value:
                array[position + 1] = array[position]
                position = position - 1
            else:
                break
        array[position + 1] = temp_value
    return array',
    demo = 'print("insertion_sort([5,3,4,2,1]) =", insertion_sort([5,3,4,2,1]))
print("insertion_sort([1,2,3,4,5]) =", insertion_sort([1,2,3,4,5]), " <- best case")
print("insertion_sort([5,4,3,2,1]) =", insertion_sort([5,4,3,2,1]), " <- worst case")'
  ),
  list(
    name = "intersection1.py",
    description = "<strong>intersection1.py</strong> — Finds common elements using nested loops. O(N\u00b7M). Checks all pairs.",
    code = 'def intersection(first_array, second_array):
    result = []
    for i in first_array:
        for j in second_array:
            if i == j:
                result.append(i)
    return result',
    demo = 'print("intersection([3,1,4,2],[4,5,3,6]) =", intersection([3,1,4,2],[4,5,3,6]))
print("intersection([1,2,3],[4,5,6])   =", intersection([1,2,3],[4,5,6]))'
  ),
  list(
    name = "intersection2.py",
    description = "<strong>intersection2.py</strong> — Same as intersection1 but adds <code>break</code> after finding a match. Same Big O worst case, better average-case performance.",
    code = 'def intersection(first_array, second_array):
    result = []
    for i in first_array:
        for j in second_array:
            if i == j:
                result.append(i)
                break  # No need to keep searching
    return result',
    demo = 'print("intersection([3,1,4,2],[4,5,3,6]) =", intersection([3,1,4,2],[4,5,3,6]))
print("intersection([1,2,3],[4,5,6])   =", intersection([1,2,3],[4,5,6]))'
  ),
  list(
    name = "two_sum.py",
    description = "<strong>two_sum.py</strong> — Checks if any two elements sum to 10. O(N\u00b2) nested loops.",
    code = 'def two_sum(array):
    for index_i, i in enumerate(array):
        for index_j, j in enumerate(array):
            if (index_i != index_j) and (i + j == 10):
                return True
    return False',
    demo = 'print(f"two_sum([1,2,3,8]) = {two_sum([1,2,3,8])}  # 2+8=10")
print(f"two_sum([1,2,3,4]) = {two_sum([1,2,3,4])}  # no pair sums to 10")
print(f"two_sum([1,2,3,9]) = {two_sum([1,2,3,9])}  # 1+9=10")'
  ),
  list(
    name = "contains_x.py",
    description = "<strong>contains_x.py</strong> — Exercise version. Sets a flag when 'X' is found but continues scanning the full string. Always N iterations.",
    code = 'def contains_X(string):
    found_X = False
    for char in string:
        if char == "X":
            found_X = True
    return found_X',
    demo = 'tests = ["", " ", "ABCDx", "xxxxx", "X", "ADSFXPODFO", "hello"]
for s in tests:
    print(f"contains_X({s!r:15}) = {contains_X(s)}")'
  ),
  list(
    name = "contains_x_solution.py",
    description = "<strong>contains_x_solution.py</strong> — Solution version. Returns immediately on finding 'X'. Best case O(1) if 'X' is first, worst case O(N).",
    code = 'def contains_X(string):
    for char in string:
        if char == "X":
            return True
    return False',
    demo = 'tests = ["", " ", "ABCDx", "xxxxx", "X", "ADSFXPODFO", "hello"]
for s in tests:
    print(f"contains_X({s!r:15}) = {contains_X(s)}")'
  )
)

chapter6_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(6, "\U0001f31f", "Optimizing for Optimistic Scenarios",
      "A complete analysis considers best, average, and worst cases. Insertion Sort reveals that even O(N\u00b2) algorithms can shine under the right conditions.",
      c("Insertion Sort", "Best / Average / Worst Case", "O(N) Best Case", "Early Exit")),
    stats_row(list("O(N)","Best Case"), list("O(N\u00b2)","Worst Case"),
              list("O(N\u00b2)","Average Case"), list("\u2248O(N)","Nearly Sorted")),
    fluidRow(tabBox(width = 12, id = ns("tabs"),
      tabPanel(title = tagList(icon("book"), " Theory"),
        fluidRow(
          box(title = "\U0001f524 Insertion Sort", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card", tags$h5("Algorithm"),
                  tags$p("Builds a sorted sub-array one element at a time. For each new element, shifts larger elements right until the correct position is found."),
                  tags$ol(tags$li("Take element at index i (temp_value)"),
                          tags$li("Compare with each element to its left"),
                          tags$li("Shift larger elements right"),
                          tags$li("Insert temp_value in the gap"),
                          tags$li("Repeat for i = 1, 2, ... N-1"))),
              div(class = "tip-box", HTML("<strong>Key difference:</strong> Does fewer operations when data is already nearly sorted. This is what gives it the O(N) best case."))
          ),
          box(title = "\U0001f4ca Three Cases", status = "warning", solidHeader = TRUE, width = 6,
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Scenario"), tags$th("Steps"), tags$th("Big O"))),
                tags$tbody(
                  tags$tr(tags$td("Already sorted"), tags$td("N-1 comparisons, 0 shifts"), tags$td("O(N) \u2705")),
                  tags$tr(tags$td("Reversed"),       tags$td("N\u00b2/2 compares + N\u00b2/2 shifts"), tags$td("O(N\u00b2) \u274c")),
                  tags$tr(tags$td("Random (avg)"),   tags$td("~N\u00b2/4 + ~N\u00b2/4"), tags$td("O(N\u00b2)"))
                )
              ),
              div(class = "success-box", HTML("<strong>\u2705 Use Insertion Sort when:</strong> Data is already partially sorted, array is small (N &lt; 20), or as a final pass in hybrid algorithms like Timsort."))
          )
        ),
        fluidRow(
          box(title = "\u2696\ufe0f Three Sorting Algorithms Compared", status = "success", solidHeader = TRUE, width = 12,
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Algorithm"), tags$th("Best Case"), tags$th("Average"), tags$th("Worst Case"), tags$th("Swaps"))),
                tags$tbody(
                  tags$tr(tags$td("Bubble Sort"),    tags$td("O(N)*"),      tags$td("O(N\u00b2)"), tags$td("O(N\u00b2)"), tags$td("O(N\u00b2)")),
                  tags$tr(tags$td("Selection Sort"), tags$td("O(N\u00b2)"), tags$td("O(N\u00b2)"), tags$td("O(N\u00b2)"), tags$td("O(N) \u2705")),
                  tags$tr(tags$td("Insertion Sort"), tags$td("O(N) \u2705"), tags$td("O(N\u00b2)"), tags$td("O(N\u00b2)"), tags$td("O(N\u00b2)"))
                )
              ),
              div(class = "info-box-plain", HTML("<strong>\u2139 Practical advice:</strong> For nearly-sorted data, Insertion Sort dominates. For random data of any significant size, prefer O(N log N) algorithms. All three O(N\u00b2) sorts are fine for N &lt; ~20."))
          )
        )
      ),
      tabPanel(title = tagList(icon("code"), " Code Lab"),
        code_lab_header("Chapter 6 Code Files", "Insertion Sort, array intersection (with/without early exit), two-sum, and contains_X (exercise vs solution version)."),
        file_pills_ui(ns, CH06_FILES),
        py_code_display(ns),
        terminal_ui(ns)
      )
    ))
  )
}

chapter6_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH06_FILES)
  })
}
