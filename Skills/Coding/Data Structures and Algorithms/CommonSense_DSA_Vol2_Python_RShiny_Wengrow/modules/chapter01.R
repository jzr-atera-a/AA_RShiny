# modules/chapter01.R
# Chapter 1: Getting Things in Order with Mergesort

CH01_FILES <- list(

  list(
    name = "mergesort.py",
    description = "<strong>mergesort.py</strong> — The book's primary in-place Mergesort. <code>merge()</code> takes two pre-copied halves and writes them back into the original array using three pointers. <code>mergesort()</code> recursively splits, sorts each half, then merges. O(N log N) time, O(N) space.",
    code = 'def merge(copy_of_left_half, copy_of_right_half, original_array):
    left_pointer  = 0
    right_pointer = 0
    array_pointer = 0

    while left_pointer < len(copy_of_left_half) \
      and right_pointer < len(copy_of_right_half):
        if copy_of_left_half[left_pointer] <= copy_of_right_half[right_pointer]:
            original_array[array_pointer] = copy_of_left_half[left_pointer]
            left_pointer += 1
        else:
            original_array[array_pointer] = copy_of_right_half[right_pointer]
            right_pointer += 1
        array_pointer += 1

    if left_pointer < len(copy_of_left_half):
        original_array[array_pointer:] = copy_of_left_half[left_pointer:]
    if right_pointer < len(copy_of_right_half):
        original_array[array_pointer:] = copy_of_right_half[right_pointer:]


def mergesort(array):
    if len(array) <= 1:
        return

    midpoint          = len(array) // 2
    copy_of_left_half = array[:midpoint]
    copy_of_right_half = array[midpoint:]

    mergesort(copy_of_left_half)
    mergesort(copy_of_right_half)
    merge(copy_of_left_half, copy_of_right_half, array)',
    demo = 'import time

array = [5, 6, 0, 2, 9, -1, 6, 7]
print("Before:", array)
mergesort(array)
print("After: ", array)

# Merge step demo
arr = [0, 2, 5, 6, -1, 6, 7, 9]
mid = len(arr) // 2
left  = arr[:mid]
right = arr[mid:]
print("\\nMerge demo:")
print("  left: ", left)
print("  right:", right)
merge(left, right, arr)
print("  merged:", arr)

# Performance
import random
big = [random.randint(1, 1000000) for _ in range(100000)]
t = time.time()
mergesort(big)
ms = (time.time() - t) * 1000
print(f"\\nMergesort 100,000 random items: {ms:.1f} ms")'
  ),

  list(
    name = "new_array_mergesort.py",
    description = "<strong>new_array_mergesort.py</strong> — Alternative Mergesort that returns a new sorted array instead of sorting in-place. <code>merge()</code> appends to a fresh <code>merged_array</code>. Simpler to understand, but uses more memory.",
    code = 'def merge(left_array, right_array):
    merged_array  = []
    left_pointer  = 0
    right_pointer = 0

    while left_pointer < len(left_array) and right_pointer < len(right_array):
        if left_array[left_pointer] <= right_array[right_pointer]:
            merged_array.append(left_array[left_pointer])
            left_pointer += 1
        else:
            merged_array.append(right_array[right_pointer])
            right_pointer += 1

    while right_pointer < len(right_array):
        merged_array.append(right_array[right_pointer])
        right_pointer += 1

    while left_pointer < len(left_array):
        merged_array.append(left_array[left_pointer])
        left_pointer += 1

    return merged_array


def mergesort(array, lo, hi):
    if lo == hi:
        return [array[lo]]

    midpoint   = (lo + hi) // 2
    left_array  = mergesort(array, lo, midpoint)
    right_array = mergesort(array, midpoint + 1, hi)
    return merge(left_array, right_array)',
    demo = 'array = [5, 6, 0, 2, 9, -1, 6, 7]
print("Input: ", array)
result = mergesort(array, 0, len(array) - 1)
print("Output:", result)

# Merge two sorted halves
left  = [0, 2, 5, 6]
right = [-1, 6, 7, 9]
print("\\nmerge([0,2,5,6], [-1,6,7,9]) =", merge(left, right))'
  ),

  list(
    name = "count_to_ten_1.py",
    description = "<strong>count_to_ten_1.py</strong> — Counts 1-10 using a <code>for</code> loop. Used in Chapter 1 to introduce Python bytecode and show that language constructs compile to different machine instructions.",
    code = 'for i in range(1, 11):
    print(i)',
    demo = 'for i in range(1, 11):
    print(i)'
  ),

  list(
    name = "count_to_ten_2.py",
    description = "<strong>count_to_ten_2.py</strong> — Counts 1-10 using a <code>while</code> loop. The book uses both versions to illustrate how Python bytecode differs between loop constructs, motivating the benchmarking chapter.",
    code = 'x = 1
while x < 11:
    print(x)
    x += 1',
    demo = 'x = 1
while x < 11:
    print(x)
    x += 1'
  ),

  list(
    name = "byte_code_example.py",
    description = "<strong>byte_code_example.py</strong> — Minimal Python snippet used to demonstrate bytecode inspection with Python's <code>dis</code> module. Shows how simple assignment and addition compile to LOAD/STORE instructions.",
    code = 'x = 1
x += 3',
    demo = 'import dis
code = """
x = 1
x += 3
"""
print("Bytecode for: x = 1; x += 3")
print("-" * 40)
dis.dis(code)'
  )
)

chapter1_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(1, "\U0001f500", "Getting Things in Order with Mergesort",
      "Mergesort is the first truly efficient general-purpose sorting algorithm in this volume. By recursively splitting arrays and merging sorted halves, it achieves O(N log N) in all cases \u2014 a dramatic improvement over the O(N\u00b2) sorts from Volume 1.",
      c("Mergesort", "Merge Operation", "O(N log N)", "Divide & Conquer", "In-place vs New Array")),

    stats_row(
      list("O(N log N)", "All Cases"),
      list("O(N)",       "Extra Space"),
      list("log N",      "Recursion Depth"),
      list("Stable",     "Sort Property")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory"),
          fluidRow(
            box(title = "\U0001f500 The Merge Operation", status = "info", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("How merge() works"),
                    tags$p("Given two already-sorted arrays, merge combines them into one sorted result by comparing
                            the front elements of each and always taking the smaller one."),
                    tags$ol(
                      tags$li("Set a pointer at the start of each sorted half"),
                      tags$li("Compare the two pointed-to values"),
                      tags$li("Copy the smaller one into the result, advance that pointer"),
                      tags$li("Repeat until one half is exhausted"),
                      tags$li("Copy any remaining elements from the other half")
                    )
                ),
                div(class = "tip-box",
                    HTML("<strong>\U0001f4a1 Key insight:</strong> Merging two sorted arrays of total size N
                          only takes <strong>N steps</strong>. Each element is written to the output exactly once.")),
                div(class = "framework-card",
                    tags$h5("Merge efficiency: O(N)"),
                    tags$p("Each of the N elements is compared at most once and written once.
                            No element is ever moved back \u2014 the pointers only move forward."))
            ),

            box(title = "\U0001f4ca Mergesort Algorithm", status = "warning", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("Divide and Conquer"),
                    tags$ol(
                      tags$li(tags$strong("Base case:"), " array of length 0 or 1 is already sorted \u2014 return"),
                      tags$li(tags$strong("Divide:"), " find midpoint, copy left and right halves"),
                      tags$li(tags$strong("Recurse:"), " mergesort the left half, then the right half"),
                      tags$li(tags$strong("Conquer:"), " merge the two sorted halves back into the original")
                    )
                ),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Level"), tags$th("Sub-arrays"), tags$th("Work per level"))),
                  tags$tbody(
                    tags$tr(tags$td("0 (root)"), tags$td("1 of size N"),   tags$td("O(N)")),
                    tags$tr(tags$td("1"),        tags$td("2 of size N/2"), tags$td("O(N)")),
                    tags$tr(tags$td("2"),        tags$td("4 of size N/4"), tags$td("O(N)")),
                    tags$tr(tags$td("..."),      tags$td("..."),           tags$td("O(N)")),
                    tags$tr(tags$td("log N"),    tags$td("N of size 1"),   tags$td("O(N)"))
                  )
                ),
                div(class = "success-box",
                    HTML("<strong>\u2705 Total:</strong> log N levels \u00d7 O(N) work per level = <strong>O(N log N)</strong>"))
            )
          ),

          fluidRow(
            box(title = "\u2696\ufe0f Mergesort vs Quicksort \u2014 Lessons Learned", status = "success", solidHeader = TRUE, width = 6,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Property"), tags$th("Mergesort"), tags$th("Quicksort"))),
                  tags$tbody(
                    tags$tr(tags$td("Best case"),    tags$td("O(N log N)"), tags$td("O(N log N)")),
                    tags$tr(tags$td("Average case"), tags$td("O(N log N)"), tags$td("O(N log N)")),
                    tags$tr(tags$td("Worst case"),   tags$td("O(N log N) \u2705"), tags$td("O(N\u00b2) \u274c")),
                    tags$tr(tags$td("Extra space"),  tags$td("O(N)"),       tags$td("O(log N)")),
                    tags$tr(tags$td("Stable?"),      tags$td("Yes \u2705"), tags$td("No")),
                    tags$tr(tags$td("Cache-friendly?"), tags$td("Somewhat"), tags$td("Yes \u2705"))
                  )
                ),
                div(class = "info-box-plain",
                    HTML("<strong>\u2139 Practical reality:</strong> Despite Mergesort's guaranteed O(N log N),
                          Quicksort is often faster in practice due to better cache behavior and lower constant factors.
                          Python's built-in <code>sort()</code> uses Timsort \u2014 a hybrid of Mergesort + Insertion Sort."))
            ),

            box(title = "\U0001f4bb Python Bytecode & Loop Performance", status = "danger", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("Why does this matter for sorting?"),
                    tags$p("Python executes bytecode \u2014 an intermediate representation compiled from your source code.
                            Each bytecode instruction takes time. The book uses the two count-to-ten examples to show
                            that even simple loops have measurable differences at the bytecode level.")),
                div(class = "framework-card",
                    tags$h5("for loop vs while loop"),
                    tags$p(tags$code("for i in range(1,11)"), " uses the", tags$code("GET_ITER"),
                           "/", tags$code("FOR_ITER"), "instructions \u2014 optimised C code under the hood."),
                    tags$p(tags$code("while x < 11"), " uses explicit comparison and increment bytecodes,
                           which can be slightly slower for large N.")),
                div(class = "success-box",
                    HTML("<strong>\u2705 Chapter lesson:</strong> Understanding bytecode is why we <em>measure</em>
                          performance empirically (Chapter 2) rather than relying purely on Big O."))
            )
          )
        ),

        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header(
            "Chapter 1 \u2014 Mergesort",
            "In-place mergesort, new-array mergesort, the merge operation, count-to-ten loops, and bytecode inspection with dis."
          ),
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
