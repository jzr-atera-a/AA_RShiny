# modules/chapter08.R — M/B-Way Mergesort (External Sorting)

CH08_HEAP_PY <- 'class Heap:
    def __init__(self):
        self.data = []

    def root_node(self):        return self.data[0]
    def last_node(self):        return self.data[-1]
    def not_empty(self):        return len(self.data) > 0
    def left_child_index(self, i):  return (i * 2) + 1
    def right_child_index(self, i): return (i * 2) + 2
    def parent_index(self, i):      return (i - 1) // 2

    def insert(self, value):
        self.data.append(value)
        idx = len(self.data) - 1
        while idx > 0 and self.data[idx] < self.data[self.parent_index(idx)]:
            parent = self.parent_index(idx)
            self.data[parent], self.data[idx] = self.data[idx], self.data[parent]
            idx = parent

    def pop(self):
        if len(self.data) == 1:
            v = self.data[0]; self.data = []; return v
        v = self.root_node()
        self.data[0] = self.data.pop()
        idx = 0
        while self.has_smaller_child(idx):
            smaller = self.find_smaller_child_index(idx)
            self.data[idx], self.data[smaller] = self.data[smaller], self.data[idx]
            idx = smaller
        return v

    def has_smaller_child(self, index):
        left  = self.left_child_index(index)
        right = self.right_child_index(index)
        return ((left  < len(self.data) and self.data[left]  < self.data[index]) or
                (right < len(self.data) and self.data[right] < self.data[index]))

    def find_smaller_child_index(self, index):
        right = self.right_child_index(index)
        left  = self.left_child_index(index)
        if right >= len(self.data):
            return left
        return right if self.data[right] < self.data[left] else left'

CH08_FILES <- list(

  list(
    name = "heap.py",
    description = "<strong>heap.py</strong> — Min-Heap (note: this is a <em>min</em>-heap, unlike the max-heap in Vol.1 Ch.16). The root is always the smallest element. Used by merge_k_sorted_lists to always extract the globally smallest remaining element in O(log k) time.",
    code = 'class Heap:
    def __init__(self):
        self.data = []

    def root_node(self):
        return self.data[0]

    def last_node(self):
        return self.data[-1]

    def not_empty(self):
        return len(self.data) > 0

    def left_child_index(self, index):
        return (index * 2) + 1

    def right_child_index(self, index):
        return (index * 2) + 2

    def parent_index(self, index):
        return (index - 1) // 2

    def insert(self, value):
        self.data.append(value)
        new_node_index = len(self.data) - 1
        # Trickle UP (min-heap: bubble toward root if smaller than parent)
        while (new_node_index > 0 and
               self.data[new_node_index] <
               self.data[self.parent_index(new_node_index)]):
            parent_index = self.parent_index(new_node_index)
            self.data[parent_index], self.data[new_node_index] = \
                self.data[new_node_index], self.data[parent_index]
            new_node_index = parent_index

    def pop(self):
        if len(self.data) == 1:
            value = self.data[0]
            self.data = []
            return value
        value_to_delete = self.root_node()
        self.data[0] = self.data.pop()
        trickle_node_index = 0
        # Trickle DOWN (swap with smaller child)
        while self.has_smaller_child(trickle_node_index):
            smaller_child_index = self.find_smaller_child_index(trickle_node_index)
            self.data[trickle_node_index], self.data[smaller_child_index] = \
                self.data[smaller_child_index], self.data[trickle_node_index]
            trickle_node_index = smaller_child_index
        return value_to_delete

    def has_smaller_child(self, index):
        return ((self.left_child_index(index) < len(self.data) and
                self.data[self.left_child_index(index)] < self.data[index]) or
                (self.right_child_index(index) < len(self.data) and
                self.data[self.right_child_index(index)] < self.data[index]))

    def find_smaller_child_index(self, index):
        if self.right_child_index(index) >= len(self.data):
            return self.left_child_index(index)
        if self.data[self.right_child_index(index)] < self.data[self.left_child_index(index)]:
            return self.right_child_index(index)
        return self.left_child_index(index)',
    demo = '# Min-heap demo
h = Heap()
for v in [5, 3, 9, 0, 6, 2, 8]:
    h.insert(v)

print("Inserted: [5, 3, 9, 0, 6, 2, 8]")
print("Min-heap internal array:", h.data)
print("Root (minimum):", h.root_node())

result = []
while h.not_empty():
    result.append(h.pop())
print("Popped in order (ascending):", result)'
  ),

  list(
    name = "merge_k_sorted_lists.py",
    description = "<strong>merge_k_sorted_lists.py</strong> — Merges K sorted lists into one sorted list using a min-heap. This is the core primitive of M/B-Way Mergesort: each of the K sorted runs contributes its current minimum to the heap; we always pop the global minimum and advance the pointer for that run. O(N log K) time.",
    code = 'import heap as h

def merge_k_sorted_lists(lists):
    sorted_list = []
    pointers    = []
    heap        = h.Heap()

    # Seed the heap with the first element from each list
    for index, lst in enumerate(lists):
        heap.insert([lst[0], index])   # [value, list_index]
        pointers.append(1)             # pointer starts at 1 (0 already inserted)

    while heap.not_empty():
        popped_item  = heap.pop()
        popped_value = popped_item[0]
        sorted_list.append(popped_value)

        # current_list: which of the K lists did this value come from?
        current_list = popped_item[1]
        if pointers[current_list] < len(lists[current_list]):
            next_val = lists[current_list][pointers[current_list]]
            heap.insert([next_val, current_list])
            pointers[current_list] += 1

    return sorted_list',
    demo = 'import heap as h

# Merge 4 sorted lists
lists = [
    [0,  3,  6,  9, 14],
    [4,  5, 20, 33],
    [1,  2, 10, 50, 54, 89],
    [8, 15, 21, 25]
]
result = merge_k_sorted_lists(lists)
print("Input lists:")
for i, lst in enumerate(lists):
    print(f"  List {i}: {lst}")
print(f"Merged:  {result}")
print(f"Sorted:  {result == sorted(result)}")

# Larger example
import random
k = 10
big_lists = [sorted([random.randint(1, 10000) for _ in range(500)]) for _ in range(k)]
merged = merge_k_sorted_lists(big_lists)
total = sum(len(l) for l in big_lists)
print(f"\\nMerged {k} lists of 500 = {total} items total")
print(f"Result sorted: {merged == sorted(merged)}")'
  )
)

chapter8_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(8, "\U0001f4e6\u2192\U0001f4e6", "Wrangling Big Data with M/B-Way Mergesort",
      "When sorting data too large for RAM, we sort chunks in memory and then merge them from disk. This chapter builds from two-way external mergesort to M/B-Way Mergesort \u2014 the algorithm that can sort terabytes of data on a machine with only gigabytes of RAM.",
      c("External Sorting", "K-Way Merge", "Min-Heap", "M/B-Way Mergesort", "O(N log N / B)")),

    stats_row(
      list("O(N log K)", "Merge K lists"),
      list("O(log K)",   "Heap operations"),
      list("M/B",        "Merge factor"),
      list("O(N/B log\u2099 N/B)", "Total I/Os")
    ),

    fluidRow(tabBox(width = 12, id = ns("tabs"),

      tabPanel(title = tagList(icon("book"), " Theory"),
        fluidRow(
          box(title = "\U0001f4be External-Memory Sorting", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("The Challenge"),
                  tags$p("We have N records to sort, but only M records fit in RAM at a time.
                          We must read/write data to disk, and each I/O is very expensive."),
                  tags$p("Goal: minimize the number of disk reads and writes.")),
              div(class = "framework-card",
                  tags$h5("Phase 1: Create sorted runs"),
                  tags$p("Read M records at a time, sort them in RAM, write the sorted run back to disk.
                          This gives us N/M sorted runs, each of size M."),
                  tags$p("Cost: 2 \u00d7 N/B I/Os (read all data once, write all sorted runs once).")),
              div(class = "framework-card",
                  tags$h5("Phase 2: Merge sorted runs"),
                  tags$p("Use a K-way merge (with a min-heap) to combine the sorted runs into one sorted file.
                          Read from K input buffers, write to one output buffer.")),
              div(class = "tip-box",
                  HTML("<strong>\U0001f4a1 Key insight:</strong> Instead of sorting the whole dataset at once
                        (impossible if it doesn't fit in RAM), we sort pieces and merge them.
                        This is exactly the external-memory version of Mergesort."))
          ),

          box(title = "\u2934\ufe0f K-Way Merge with a Min-Heap", status = "warning", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("merge_k_sorted_lists algorithm"),
                  tags$ol(
                    tags$li("Insert the first element from each of K lists into a min-heap, tagged with its list index"),
                    tags$li("Pop the minimum from the heap \u2014 this is the globally smallest remaining element"),
                    tags$li("Append it to the output"),
                    tags$li("Insert the next element from the same list (advance pointer)"),
                    tags$li("Repeat until heap is empty")
                  )),
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Approach"), tags$th("Time"), tags$th("Space"))),
                tags$tbody(
                  tags$tr(tags$td("Naive: sort all"),      tags$td("O(N log N)"),   tags$td("O(N)")),
                  tags$tr(tags$td("K-way min-heap merge"), tags$td("O(N log K) \u2705"), tags$td("O(K)"))
                )
              ),
              div(class = "success-box",
                  HTML("<strong>\u2705 Why O(N log K)?</strong> Each of N elements is inserted into and
                        popped from the heap exactly once. Each heap operation is O(log K).
                        K can be much smaller than N."))
          )
        ),

        fluidRow(
          box(title = "\U0001f504 M/B-Way Mergesort", status = "success", solidHeader = TRUE, width = 12,
              fluidRow(
                column(6,
                  div(class = "framework-card",
                      tags$h5("Two-Way External Mergesort (naive)"),
                      tags$p("Merge pairs of runs. If we have 1000 runs, we need log\u2082(1000) = 10 passes
                              over all the data. Each pass = 2N/B I/Os."),
                      tags$p(tags$strong("Total: 2N/B \u00d7 log\u2082(N/M) I/Os"))),
                  div(class = "framework-card",
                      tags$h5("M/B-Way Mergesort (optimal)"),
                      tags$p("We have M bytes of RAM. If each input buffer is B bytes (one disk page),
                              we can merge M/B \u2212 1 runs simultaneously."),
                      tags$p("This reduces the number of passes from log\u2082 to log\u2098\u2080\u2091(N/M) \u2014
                              dramatically fewer for large M/B."),
                      tags$p(tags$strong("Total: 2N/B \u00d7 log\u2098/\u2099(N/M) I/Os")))
                ),
                column(6,
                  div(class = "info-box-plain",
                      HTML("<strong>\u2139 Concrete example:</strong><br>
                            N = 1TB, M = 8GB, B = 4KB page size.<br>
                            M/B = 2,000,000 \u2014 we can merge 2 million runs at once!<br>
                            log\u2098/\u2099(N/M) \u2248 log\u2082,000,000(128) \u2248 <strong>1 pass</strong> (vs 17 passes two-way).<br>
                            This is why terabyte sorts finish overnight instead of taking weeks.")),
                  div(class = "tip-box",
                      HTML("<strong>\U0001f4a1 Real usage:</strong> MapReduce, Apache Spark, and database
                            systems all use variants of external Mergesort for their sort-based operations
                            (ORDER BY, GROUP BY, sort-merge join)."))
                )
              )
          )
        )
      ),

      tabPanel(title = tagList(icon("code"), " Code Lab"),
        code_lab_header("Chapter 8 \u2014 M/B-Way Mergesort",
          "Min-heap implementation and K-way merge of sorted lists \u2014 the core building blocks of external-memory sorting."),
        file_pills_ui(ns, CH08_FILES),
        py_code_display(ns),
        terminal_ui(ns)
      )
    ))
  )
}

chapter8_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    extra <- list(
      list(name = "heap.py", code = CH08_HEAP_PY, description = "", demo = "")
    )
    code_lab_server(input, output, session, c(CH08_FILES, extra))
  })
}
