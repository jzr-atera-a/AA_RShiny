# modules/chapter02.R
# Chapter 2: Benchmarking Code

CH02_MERGESORT1_PY <- 'def merge(copy_of_left_half, copy_of_right_half, original_array):
    left_pointer = 0; right_pointer = 0; array_pointer = 0
    while left_pointer < len(copy_of_left_half) and right_pointer < len(copy_of_right_half):
        if copy_of_left_half[left_pointer] <= copy_of_right_half[right_pointer]:
            original_array[array_pointer] = copy_of_left_half[left_pointer]
            left_pointer += 1
        else:
            original_array[array_pointer] = copy_of_right_half[right_pointer]
            right_pointer += 1
        array_pointer += 1
    while left_pointer < len(copy_of_left_half):
        original_array[array_pointer] = copy_of_left_half[left_pointer]
        left_pointer += 1; array_pointer += 1
    while right_pointer < len(copy_of_right_half):
        original_array[array_pointer] = copy_of_right_half[right_pointer]
        right_pointer += 1; array_pointer += 1

def mergesort(array):
    if len(array) <= 1: return
    midpoint = len(array) // 2
    left = array[:midpoint]; right = array[midpoint:]
    mergesort(left); mergesort(right)
    merge(left, right, array)'

CH02_INSERTION_PY <- 'def sort(array):
    for i in range(1, len(array)):
        key_item = array[i]
        j = i - 1
        while j >= 0 and array[j] > key_item:
            array[j + 1] = array[j]
            j -= 1
        array[j + 1] = key_item
    return array'

CH02_FILES <- list(

  list(
    name = "bench_first_example.py",
    description = "<strong>bench_first_example.py</strong> — The book's very first benchmark. Uses <code>timeit.timeit()</code> with <code>number=1</code> to time building an array of 1,000,000 elements. Introduces the basic timeit API.",
    code = 'import timeit

test_code = """
array = []
for i in range(1_000_000):
    array.append(i)
"""

result = timeit.timeit(stmt=test_code, number=1)
print(f"Time to build 1,000,000-element array: {result:.4f} seconds")',
    demo = ''
  ),

  list(
    name = "bench_bad.py",
    description = "<strong>bench_bad.py</strong> — Example of a <em>bad</em> benchmark: the setup re-sorts an already-sorted array on every repeat, so it times the best case rather than the average. Demonstrates why setup matters.",
    code = 'import timeit

# BAD: setup creates an already-sorted array.
# sort() on a sorted array is O(N) not O(N log N)!
setup_code = """
array = []
for i in range(100_000):
    array.append(i)
"""

test_code = """
array.sort()
"""

# This times best-case, not average-case!
results = timeit.repeat(stmt=test_code, setup=setup_code, repeat=3, number=1)
print("Sorted-input sort times:", [f"{r:.6f}s" for r in results])
print("WARNING: This is best-case, not average-case!")',
    demo = ''
  ),

  list(
    name = "bench_bad_3.py",
    description = "<strong>bench_bad_3.py</strong> — Another common gotcha: benchmarking something so fast (binary search) that the loop overhead dominates. Shows why <code>number</code> parameter matters for micro-benchmarks.",
    code = 'import timeit

setup_code = """
def binary_search(array, search_value):
    lower_bound = 0
    upper_bound = len(array) - 1
    while lower_bound <= upper_bound:
        midpoint = (upper_bound + lower_bound) // 2
        value_at_midpoint = array[midpoint]
        if search_value == value_at_midpoint:
            return midpoint
        elif search_value < value_at_midpoint:
            upper_bound = midpoint - 1
        elif search_value > value_at_midpoint:
            lower_bound = midpoint + 1
    return None

array = list(range(1_000_000))
"""

test_code = """
binary_search(array, 89124)
"""

results = timeit.repeat(stmt=test_code, setup=setup_code, repeat=5, number=1000)
print("Binary search x1000 times:", [f"{r:.6f}s" for r in results])
print(f"Per-call average: {min(results)/1000*1e6:.2f} microseconds")',
    demo = ''
  ),

  list(
    name = "mergesort_1.py",
    description = "<strong>mergesort_1.py</strong> — Standard in-place Mergesort used as the benchmarking target throughout Chapter 2. Compare its empirical timing against insertion_sort.py and Python's built-in sort.",
    code = 'def merge(copy_of_left_half, copy_of_right_half, original_array):
    left_pointer  = 0
    right_pointer = 0
    array_pointer = 0

    while left_pointer < len(copy_of_left_half) and right_pointer < len(copy_of_right_half):
        if copy_of_left_half[left_pointer] <= copy_of_right_half[right_pointer]:
            original_array[array_pointer] = copy_of_left_half[left_pointer]
            left_pointer += 1
        else:
            original_array[array_pointer] = copy_of_right_half[right_pointer]
            right_pointer += 1
        array_pointer += 1

    while left_pointer < len(copy_of_left_half):
        original_array[array_pointer] = copy_of_left_half[left_pointer]
        left_pointer += 1; array_pointer += 1

    while right_pointer < len(copy_of_right_half):
        original_array[array_pointer] = copy_of_right_half[right_pointer]
        right_pointer += 1; array_pointer += 1


def mergesort(array):
    if len(array) <= 1:
        return
    midpoint          = len(array) // 2
    copy_of_left_half  = array[:midpoint]
    copy_of_right_half = array[midpoint:]
    mergesort(copy_of_left_half)
    mergesort(copy_of_right_half)
    merge(copy_of_left_half, copy_of_right_half, array)',
    demo = 'import random, time

sizes = [100, 1000, 10000]
for n in sizes:
    arr = [random.randint(1, n) for _ in range(n)]
    t = time.time()
    mergesort(arr)
    ms = (time.time() - t) * 1000
    print(f"mergesort(N={n:6,}) -> {ms:.3f} ms")'
  ),

  list(
    name = "insertion_sort.py",
    description = "<strong>insertion_sort.py</strong> — Insertion Sort implementation used for benchmarking comparison. O(N\u00b2) average, but often faster than Mergesort for very small arrays due to lower overhead.",
    code = 'def sort(array):
    for i in range(1, len(array)):
        key_item = array[i]
        j = i - 1
        while j >= 0 and array[j] > key_item:
            array[j + 1] = array[j]
            j -= 1
        array[j + 1] = key_item
    return array',
    demo = 'import random, time

sizes = [10, 100, 1000, 5000]
for n in sizes:
    arr = [random.randint(1, n) for _ in range(n)]
    t = time.time()
    sort(arr)
    ms = (time.time() - t) * 1000
    print(f"insertion_sort(N={n:5,}) -> {ms:.3f} ms")'
  ),

  list(
    name = "merge_plus_insertion.py",
    description = "<strong>merge_plus_insertion.py</strong> — Hybrid Mergesort: falls back to Insertion Sort for sub-arrays of size 10 or fewer. A real-world optimisation that beats pure Mergesort for many inputs (Timsort uses a similar idea).",
    code = 'def insertion_sort(array):
    for i in range(1, len(array)):
        key_item = array[i]
        j = i - 1
        while j >= 0 and array[j] > key_item:
            array[j + 1] = array[j]
            j -= 1
        array[j + 1] = key_item
    return array


def merge(copy_of_left_half, copy_of_right_half, original_array):
    left_pointer  = 0
    right_pointer = 0
    array_pointer = 0

    while left_pointer < len(copy_of_left_half) and right_pointer < len(copy_of_right_half):
        if copy_of_left_half[left_pointer] <= copy_of_right_half[right_pointer]:
            original_array[array_pointer] = copy_of_left_half[left_pointer]
            left_pointer += 1
        else:
            original_array[array_pointer] = copy_of_right_half[right_pointer]
            right_pointer += 1
        array_pointer += 1

    while left_pointer < len(copy_of_left_half):
        original_array[array_pointer] = copy_of_left_half[left_pointer]
        left_pointer += 1; array_pointer += 1

    while right_pointer < len(copy_of_right_half):
        original_array[array_pointer] = copy_of_right_half[right_pointer]
        right_pointer += 1; array_pointer += 1


def mergesort(array):
    if len(array) <= 10:         # use Insertion Sort for small arrays
        insertion_sort(array)
        return

    midpoint          = len(array) // 2
    copy_of_left_half  = array[:midpoint]
    copy_of_right_half = array[midpoint:]

    mergesort(copy_of_left_half)
    mergesort(copy_of_right_half)
    merge(copy_of_left_half, copy_of_right_half, array)',
    demo = 'import random, time

n = 100000
arr1 = [random.randint(1, n) for _ in range(n)]
arr2 = arr1[:]

# Pure mergesort
import mergesort_1
t = time.time()
mergesort_1.mergesort(arr1)
t1 = (time.time() - t) * 1000

# Hybrid
t = time.time()
mergesort(arr2)
t2 = (time.time() - t) * 1000

print(f"Pure mergesort (N={n:,}):   {t1:.2f} ms")
print(f"Hybrid merge+insertion:    {t2:.2f} ms")
print(f"Speedup: {t1/t2:.2f}x" if t2 > 0 else "Hybrid faster!")'
  ),

  list(
    name = "exercise_1a.py",
    description = "<strong>exercise_1a.py</strong> — Exercise: find the minimum of an array in a single O(N) pass, tracking the smallest value seen so far.",
    code = 'def minimum(array):
    smallest_item_so_far = float("inf")

    for item in array:
        if item < smallest_item_so_far:
            smallest_item_so_far = item

    return smallest_item_so_far',
    demo = 'import random
arr = [random.randint(1, 1000) for _ in range(20)]
print("Array:", arr)
print("Minimum:", minimum(arr))'
  ),

  list(
    name = "exercise_2a.py",
    description = "<strong>exercise_2a.py</strong> — Exercise: sum all integers from 0 to 999,999 using a for loop. Used in benchmarking comparisons.",
    code = 'def sum_up_to_one_million():
    total = 0
    for i in range(1_000_000):
        total += i
    return total',
    demo = 'import time
t = time.time()
result = sum_up_to_one_million()
ms = (time.time() - t) * 1000
print(f"sum_up_to_one_million() = {result}")
print(f"Time: {ms:.2f} ms")'
  )
)

chapter2_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(2, "\u23f1\ufe0f", "Benchmarking Code",
      "Big O tells you the theoretical growth rate of an algorithm \u2014 but benchmarking tells you what actually happens on your machine, with real data. This chapter teaches you to measure correctly using Python's timeit module and avoid the common pitfalls that make benchmarks misleading.",
      c("timeit", "Benchmarking Gotchas", "Mergesort vs Insertion Sort", "Mergesort vs Quicksort", "Hybrid Algorithms")),

    stats_row(
      list("timeit", "Python's Tool"),
      list("3",      "Key Gotchas"),
      list("repeat=5","Repeats Recommended"),
      list("10",     "Hybrid Threshold")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory"),
          fluidRow(
            box(title = "\u23f1\ufe0f Using timeit Correctly", status = "info", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("The timeit API"),
                    tags$p(tags$code("timeit.timeit(stmt, setup, number)"), " \u2014 runs stmt number times and returns total elapsed seconds."),
                    tags$p(tags$code("timeit.repeat(stmt, setup, repeat, number)"), " \u2014 calls timeit repeat times and returns a list of results."),
                    tags$p("Use", tags$code("min()"), "of the repeat results \u2014 the minimum is the most reliable estimate of true performance, as it suffers least from system interference.")
                ),
                div(class = "tip-box",
                    HTML("<strong>\U0001f4a1 Rule:</strong> Always set <code>repeat=5</code> or more and take <code>min()</code>.
                          High values indicate noise, not algorithm slowness.")),
                div(class = "framework-card",
                    tags$h5("setup vs stmt"),
                    tags$p("Code in", tags$code("setup"), "runs once before timing begins.
                            Code in", tags$code("stmt"), "is what gets timed.
                            Always prepare your test data in setup \u2014 never in stmt."))
            ),

            box(title = "\u26a0\ufe0f Benchmarking Gotchas", status = "danger", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("Gotcha 1: Sorted Input"),
                    tags$p("Sorting an already-sorted array with many algorithms triggers best-case performance.
                            Always generate", tags$strong("random"), "input in setup for fair comparisons.")),
                div(class = "framework-card",
                    tags$h5("Gotcha 2: In-place Mutation"),
                    tags$p("If your stmt sorts the array in-place, subsequent repeats sort an already-sorted array.
                            Re-generate or copy the array in setup.")),
                div(class = "framework-card",
                    tags$h5("Gotcha 3: Micro-benchmark Noise"),
                    tags$p("Operations faster than ~1ms are dominated by loop overhead and OS interrupts.
                            Use a large", tags$code("number"), "parameter (e.g. 1000) to amortise noise for fast operations.")),
                div(class = "warn-box",
                    HTML("<strong>\u26a0 Golden rule:</strong> If your benchmark result surprises you, check for gotchas before concluding your algorithm is fast or slow."))
            )
          ),

          fluidRow(
            box(title = "\U0001f4ca Benchmarking Results: Sorting Algorithms", status = "success", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("Mergesort vs Insertion Sort"),
                    tags$p("For small N (e.g. N=10), Insertion Sort often beats Mergesort due to lower overhead \u2014
                            no recursion, no array copying."),
                    tags$p("For large N (e.g. N=100,000), Mergesort's O(N log N) dominates Insertion Sort's O(N\u00b2) by orders of magnitude.")),
                div(class = "framework-card",
                    tags$h5("Mergesort vs Quicksort"),
                    tags$p("On random data: Quicksort typically beats Mergesort by 20\u201340% due to better cache behavior."),
                    tags$p("On sorted data: Quicksort with a fixed pivot degrades to O(N\u00b2). Mergesort stays O(N log N)."))
            ),

            box(title = "\U0001f9ea The Hybrid Approach", status = "warning", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("merge_plus_insertion.py"),
                    tags$p("The hybrid mergesort uses Insertion Sort for sub-arrays of size \u226410 and Mergesort for larger ones."),
                    tags$p("This exploits Insertion Sort's efficiency for tiny arrays (lower constant factor) while maintaining
                            O(N log N) overall complexity.")),
                div(class = "success-box",
                    HTML("<strong>\u2705 This is Timsort!</strong> Python's built-in <code>list.sort()</code>
                          uses Timsort, a sophisticated version of this hybrid strategy with a min-run size of 32-64 elements.
                          It's why Python's sort is so fast in practice.")),
                div(class = "info-box-plain",
                    HTML("<strong>\u2139 Benchmark takeaway:</strong> The hybrid is measurably faster than pure Mergesort
                          on most real-world inputs. Always benchmark your optimizations \u2014 Big O alone won't tell you this."))
            )
          )
        ),

        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header(
            "Chapter 2 \u2014 Benchmarking Code",
            "timeit examples, benchmarking gotchas, mergesort vs insertion sort vs Quicksort comparisons, and the hybrid merge+insertion sort."
          ),
          file_pills_ui(ns, CH02_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter2_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    extra <- list(
      list(name = "mergesort_1.py",   code = CH02_MERGESORT1_PY, description = "", demo = ""),
      list(name = "insertion_sort.py", code = CH02_INSERTION_PY,  description = "", demo = "")
    )
    code_lab_server(input, output, session, c(CH02_FILES, extra))
  })
}
