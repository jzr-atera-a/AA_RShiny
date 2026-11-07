# modules/chapter13.R
# Chapter 13: Quicksort — O(N log N) average, divide-and-conquer sorting

CH13_FILES <- list(

  list(
    name        = "sortable_array.py",
    description = "<strong>sortable_array.py</strong> — The centrepiece of this chapter.
                   Implements <code>partition()</code>, <code>quicksort()</code>, and
                   <code>quickselect()</code> as methods on a <code>SortableArray</code> class.
                   Partition rearranges elements around a pivot in O(N); quicksort applies it
                   recursively for O(N log N) average; quickselect finds the k-th smallest
                   value in O(N) average.",
    code = 'class SortableArray:

    def __init__(self, array):
        self.array = array

    def partition(self, left_pointer, right_pointer):
        pivot_index  = right_pointer
        pivot        = self.array[pivot_index]
        right_pointer -= 1

        while True:
            while self.array[left_pointer] < pivot:
                left_pointer += 1
            while self.array[right_pointer] > pivot:
                right_pointer -= 1

            if left_pointer >= right_pointer:
                break
            else:
                self.array[left_pointer], self.array[right_pointer] = \
                    self.array[right_pointer], self.array[left_pointer]
                left_pointer += 1

        self.array[left_pointer], self.array[pivot_index] = \
            self.array[pivot_index], self.array[left_pointer]
        return left_pointer

    def quicksort(self, left_index, right_index):
        if right_index - left_index <= 0:
            return
        pivot_index = self.partition(left_index, right_index)
        self.quicksort(left_index,       pivot_index - 1)
        self.quicksort(pivot_index + 1,  right_index)

    def quickselect(self, kth_lowest_value, left_index, right_index):
        if right_index - left_index <= 0:
            return self.array[left_index]
        pivot_index = self.partition(left_index, right_index)
        if kth_lowest_value < pivot_index:
            return self.quickselect(kth_lowest_value, left_index, pivot_index - 1)
        elif kth_lowest_value > pivot_index:
            return self.quickselect(kth_lowest_value, pivot_index + 1, right_index)
        else:
            return self.array[pivot_index]',
    demo = '# --- Quicksort demo ---
arr = SortableArray([7, 8, 1, 9, 0, 4])
arr.quicksort(0, len(arr.array) - 1)
print("Quicksort [7,8,1,9,0,4]  ->", arr.array)

arr2 = SortableArray([12, 11, 10, 7, 8, 1, 9, 0, 4, 15, 3, 6, 5])
arr2.quicksort(0, len(arr2.array) - 1)
print("Quicksort 13 elements    ->", arr2.array)

# --- Quickselect demo ---
arr3 = SortableArray([0, 50, 20, 10, 60, 30])
result = arr3.quickselect(1, 0, len(arr3.array) - 1)
print("Quickselect 2nd-lowest in [0,50,20,10,60,30] ->", result)  # 10

# Step count comparison
import time
import random

n = 10000
data = list(range(n, 0, -1))   # worst case for naive sorts
sa = SortableArray(data[:])
t = time.time()
sa.quicksort(0, len(sa.array) - 1)
ms = (time.time() - t) * 1000
print(f"\nQuicksort {n:,} reversed items: {ms:.2f} ms")'
  ),

  list(
    name        = "duplicate.py",
    description = "<strong>duplicate.py</strong> — Detects duplicates by sorting first, then scanning adjacent pairs.
                   Sorting is O(N log N); the scan is O(N) — overall O(N log N), much better
                   than the naive O(N²) nested-loop approach.",
    code = 'def has_duplicate_value(array):
    array.sort()                          # O(N log N)

    for index in range(len(array) - 1):  # O(N)
        if array[index] == array[index + 1]:
            return True

    return False',
    demo = 'print(f"has_duplicate_value([5,9,3,2,4,5,6]) = {has_duplicate_value([5,9,3,2,4,5,6])}")
print(f"has_duplicate_value([9,3,2,4,5,6])   = {has_duplicate_value([9,3,2,4,5,6])}")
print(f"has_duplicate_value([])              = {has_duplicate_value([])}")'
  ),

  list(
    name        = "solution1.py",
    description = "<strong>solution1.py</strong> — Finds the greatest product of any 3 numbers by sorting first.
                   After sorting, the 3 largest are the last 3 elements — O(N log N) total.",
    code = 'def greatest_product_of_3(array):
    array.sort()                    # Sort ascending — O(N log N)
    return array[-1] * array[-2] * array[-3]   # Last 3 are the largest',
    demo = 'print(f"greatest_product_of_3([9,3,5,1,0,4]) = {greatest_product_of_3([9,3,5,1,0,4])}")
print(f"greatest_product_of_3([1,2,3,4,5])   = {greatest_product_of_3([1,2,3,4,5])}")'
  ),

  list(
    name        = "solution2.py",
    description = "<strong>solution2.py</strong> — Finds a missing number from 0..N by sorting the array,
                   then checking whether each index matches its value. O(N log N).",
    code = 'def find_missing_number(array):
    array.sort()

    for index, num in enumerate(array):
        if num != index:
            return index

    return None',
    demo = 'print(f"find_missing_number([9,3,2,5,6,7,1,0,4]) = {find_missing_number([9,3,2,5,6,7,1,0,4])}")
print(f"find_missing_number([1,2,3,4,5])        = {find_missing_number([1,2,3,4,5])}")'
  ),

  list(
    name        = "solution3c.py",
    description = "<strong>solution3c.py</strong> — Finds the max value in a single O(N) pass, tracking
                   the greatest seen so far. Contrast with solution3a (O(N²)) and solution3b
                   (O(N log N) via sort) — this is the optimal approach.",
    code = 'def max(array):
    if not array:
        return None

    greatest_number_so_far = array[0]

    for number in array:               # O(N)
        if number > greatest_number_so_far:
            greatest_number_so_far = number

    return greatest_number_so_far',
    demo = 'print(f"max([9,3,2,5,6,7,11,0,4]) = {max([9,3,2,5,6,7,11,0,4])}")
print(f"max([5])                   = {max([5])}")
print(f"max([])                    = {max([])}")'
  )
)

chapter13_ui <- function(id) {
  ns <- NS(id)
  tagList(

    chapter_hero(13, "⚡", "Quicksort",
      "Quicksort is one of the most widely used sorting algorithms in practice. By cleverly choosing a pivot and partitioning around it, it achieves O(N log N) average-case performance — and its cousin Quickselect finds the k-th smallest element in O(N) average.",
      c("Quicksort", "Quickselect", "Partition", "O(N log N) avg", "O(N²) worst", "Pivot Strategy")),

    stats_row(
      list("O(N log N)", "Avg Sort"),
      list("O(N²)",      "Worst Sort"),
      list("O(N)",       "Quickselect avg"),
      list("O(log N)",   "Stack depth")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        # ── THEORY ───────────────────────────────────────────
        tabPanel(title = tagList(icon("book"), " Theory"),

          fluidRow(
            box(title = "🔪 The Partition Step", status = "info", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("What partition does"),
                    tags$p("Given an array sub-range and a pivot (rightmost element), partition rearranges
                            values so that everything", tags$strong("left of the pivot is smaller"),
                            "and everything", tags$strong("right is larger."),
                            "The pivot ends up in its final sorted position."),
                    tags$ol(
                      tags$li("Left pointer starts at the left end; right pointer just left of pivot"),
                      tags$li("Move left pointer right until it finds a value", tags$strong("≥ pivot")),
                      tags$li("Move right pointer left until it finds a value", tags$strong("≤ pivot")),
                      tags$li("Swap the two values; advance left pointer"),
                      tags$li("When pointers cross, swap left pointer with pivot — done")
                    )
                ),
                div(class = "tip-box",
                    HTML("<strong>💡 Key insight:</strong> After partitioning, the pivot is in its
                          <em>exact</em> final sorted position. We never need to move it again."))
            ),

            box(title = "🔄 Quicksort Recursion", status = "warning", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("The full algorithm"),
                    tags$ol(
                      tags$li("Partition the array around a pivot"),
                      tags$li("Recursively quicksort the", tags$strong("left sub-array"), "(values < pivot)"),
                      tags$li("Recursively quicksort the", tags$strong("right sub-array"), "(values > pivot)"),
                      tags$li("Base case: sub-array of size ≤ 1 — already sorted")
                    )
                ),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Case"), tags$th("Big O"), tags$th("When?"))),
                  tags$tbody(
                    tags$tr(tags$td("Average"), tags$td("O(N log N)"), tags$td("Pivot near middle each time")),
                    tags$tr(tags$td("Best"),    tags$td("O(N log N)"), tags$td("Perfectly balanced splits")),
                    tags$tr(tags$td("Worst"),   tags$td("O(N²)"),      tags$td("Already sorted, pivot = max"))
                  )
                ),
                div(class = "info-box-plain",
                    HTML("<strong>ℹ Worst case:</strong> Occurs when the pivot is always the min or max of the
                          sub-array (e.g. sorted input with rightmost-element pivot). Random pivot selection
                          or median-of-three avoids this."))
            )
          ),

          fluidRow(
            box(title = "🎯 Quickselect — O(N) k-th Smallest", status = "success", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("The insight"),
                    tags$p("After partitioning, the pivot is at its sorted position", tags$em("p"),
                           ". If you want the k-th smallest element:"),
                    tags$ul(
                      tags$li("k = p → the pivot", tags$strong("is"), "the answer"),
                      tags$li("k < p → recurse into the", tags$strong("left"), "sub-array only"),
                      tags$li("k > p → recurse into the", tags$strong("right"), "sub-array only")
                    )
                ),
                div(class = "success-box",
                    HTML("<strong>✅ Why O(N) average?</strong> Each step eliminates roughly half the remaining
                          elements — just like binary search. N + N/2 + N/4 + … = 2N = O(N)."))
            ),

            box(title = "📊 Sorting Algorithm Summary", status = "danger", solidHeader = TRUE, width = 6,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Algorithm"), tags$th("Best"), tags$th("Average"), tags$th("Worst"), tags$th("Space"))),
                  tags$tbody(
                    tags$tr(tags$td("Bubble Sort"),    tags$td("O(N)"),      tags$td("O(N²)"),     tags$td("O(N²)"),     tags$td("O(1)")),
                    tags$tr(tags$td("Selection Sort"), tags$td("O(N²)"),     tags$td("O(N²)"),     tags$td("O(N²)"),     tags$td("O(1)")),
                    tags$tr(tags$td("Insertion Sort"), tags$td("O(N)"),      tags$td("O(N²)"),     tags$td("O(N²)"),     tags$td("O(1)")),
                    tags$tr(tags$td(tags$strong("Quicksort")), tags$td("O(N log N)"), tags$td(tags$strong("O(N log N)")), tags$td("O(N²)"), tags$td("O(log N)")),
                    tags$tr(tags$td("Merge Sort"),     tags$td("O(N log N)"), tags$td("O(N log N)"), tags$td("O(N log N)"), tags$td("O(N)"))
                  )
                ),
                div(class = "tip-box",
                    HTML("<strong>💡 Practice:</strong> Python's built-in <code>sort()</code> uses Timsort —
                          a hybrid of Merge Sort + Insertion Sort — guaranteed O(N log N)."))
            )
          )
        ), # end Theory

        # ── CODE LAB ─────────────────────────────────────────
        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header(
            "Chapter 13 — Quicksort & Quickselect",
            "Partition, recursive quicksort, quickselect for k-th smallest, sorting-based duplicate detection, and O(N log N) solutions to classic problems."
          ),
          file_pills_ui(ns, CH13_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter13_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH13_FILES)
  })
}
