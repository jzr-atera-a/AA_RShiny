# modules/chapter16.R
# Chapter 16: Keeping Your Priorities Straight with Heaps

CH16_FILES <- list(

  list(
    name        = "heap.py",
    description = "<strong>heap.py</strong> — A max-heap backed by a plain Python list. Provides
                   O(log N) <code>insert</code> (with trickle-up) and O(log N) <code>pop</code>
                   (with trickle-down). Supports O(1) access to the maximum element at the root.
                   The complete-binary-tree structure stored in an array makes index arithmetic
                   the only navigation tool needed — no pointers required.",
    code = 'class Heap:

    def __init__(self):
        self.data = []

    # ── Access helpers ──────────────────────────────────────
    def root_node(self):
        return self.data[0]

    def last_node(self):
        return self.data[-1]

    def left_child_index(self, index):
        return (index * 2) + 1

    def right_child_index(self, index):
        return (index * 2) + 2

    def parent_index(self, index):
        return (index - 1) // 2

    # ── Insert with trickle-up ──────────────────────────────
    def insert(self, value):
        self.data.append(value)              # 1. Place at end
        new_node_index = len(self.data) - 1

        # 2. Trickle up while greater than parent
        while (new_node_index > 0 and
               self.data[new_node_index] >
               self.data[self.parent_index(new_node_index)]):

            parent_index = self.parent_index(new_node_index)
            self.data[parent_index], self.data[new_node_index] = \
                self.data[new_node_index], self.data[parent_index]
            new_node_index = parent_index

    # ── Pop root with trickle-down ──────────────────────────
    def pop(self):
        value_to_delete   = self.root_node()
        self.data[0]      = self.data.pop()  # Move last to root
        trickle_node_index = 0

        # Trickle down while smaller than a child
        while self.has_greater_child(trickle_node_index):
            larger_child_index = self.find_larger_child_index(trickle_node_index)
            self.data[trickle_node_index], self.data[larger_child_index] = \
                self.data[larger_child_index], self.data[trickle_node_index]
            trickle_node_index = larger_child_index

        return value_to_delete

    # ── Helpers ─────────────────────────────────────────────
    def has_greater_child(self, index):
        left  = self.left_child_index(index)
        right = self.right_child_index(index)
        return ((left < len(self.data) and self.data[left]  > self.data[index]) or
                (right < len(self.data) and self.data[right] > self.data[index]))

    def find_larger_child_index(self, index):
        right = self.right_child_index(index)
        left  = self.left_child_index(index)
        if right >= len(self.data):
            return left
        if self.data[right] > self.data[left]:
            return right
        return left',
    demo = '# ── Build a heap ──────────────────────────────────────
h = Heap()
for v in [55, 22, 34, 10, 2, 99, 68]:
    h.insert(v)

print("Heap internal array (NOT sorted, but max at index 0):")
print(h.data)
print(f"\nroot_node() = {h.root_node()}   <- always the maximum")
print(f"last_node() = {h.last_node()}")

# ── Pop sorts by priority ──────────────────────────────────
print("\nPopping in descending order (heap sort):")
result = []
tmp = Heap()
for v in [55, 22, 34, 10, 2, 99, 68]:
    tmp.insert(v)
while tmp.data:
    result.append(tmp.pop())
print(result)

# ── Index arithmetic demo ──────────────────────────────────
print("\nIndex arithmetic for node at index 3:")
print(f"  parent_index(3)       = {h.parent_index(3)}")
print(f"  left_child_index(3)   = {h.left_child_index(3)}")
print(f"  right_child_index(3)  = {h.right_child_index(3)}")'
  )
)

chapter16_ui <- function(id) {
  ns <- NS(id)
  tagList(

    chapter_hero(16, "🏔️", "Keeping Your Priorities Straight with Heaps",
      "A heap is a tree-based data structure that satisfies the heap property: every parent is greater (max-heap) or smaller (min-heap) than its children. It gives you O(1) access to the highest-priority element and O(log N) insertions and deletions — making it the engine behind priority queues.",
      c("Max-Heap", "Priority Queue", "Trickle-Up", "Trickle-Down", "O(log N)", "Array-backed Tree")),

    stats_row(
      list("O(1)",     "Read max (root)"),
      list("O(log N)", "Insert"),
      list("O(log N)", "Delete (pop)"),
      list("O(N log N)", "Heap Sort")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        # ── THEORY ───────────────────────────────────────────
        tabPanel(title = tagList(icon("book"), " Theory"),

          fluidRow(
            box(title = "🏔️ Heap Structure & Properties", status = "info", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("What is a heap?"),
                    tags$p("A heap is a", tags$strong("complete binary tree"),
                           "that satisfies the", tags$strong("heap property:"),
                           "each node is greater than (max-heap) or less than (min-heap)
                           all of its descendants."),
                    tags$ul(
                      tags$li(tags$strong("Complete:"), " every level is fully filled except possibly
                               the last, which is filled left to right"),
                      tags$li(tags$strong("Max-heap:"), " root = largest element"),
                      tags$li(tags$strong("Min-heap:"), " root = smallest element")
                    )
                ),
                div(class = "framework-card",
                    tags$h5("Array representation — no pointers needed!"),
                    tags$p("Because the tree is complete, it can be stored in a flat array with
                            simple index arithmetic:"),
                    tags$ul(
                      tags$li(tags$code("left_child(i)  = 2i + 1")),
                      tags$li(tags$code("right_child(i) = 2i + 2")),
                      tags$li(tags$code("parent(i)      = (i − 1) // 2"))
                    )
                ),
                div(class = "tip-box",
                    HTML("<strong>💡 Not fully sorted!</strong> A heap only guarantees that the
                          root is the max. The rest of the array is NOT in sorted order —
                          the heap property is weaker than full sort order."))
            ),

            box(title = "⬆️ Insert — Trickle Up", status = "warning", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("Algorithm"),
                    tags$ol(
                      tags$li("Append the new value at the end of the array"),
                      tags$li("Compare with its parent"),
                      tags$li("If new value > parent, swap them"),
                      tags$li("Repeat steps 2–3 until the new value is ≤ its parent,
                               or it becomes the root")
                    ),
                    div(class = "info-box-plain",
                        HTML("<strong>ℹ O(log N):</strong> The tree has height log₂(N), so the
                              new value can trickle up at most log₂(N) levels."))
                ),
                div(class = "framework-card",
                    tags$h5("Example — inserting 40 into a heap:"),
                    tags$p("[100, 88, 25, 87, 16, 8, 12, 86, 50, 2, 15, 3]"),
                    tags$p("→ append 40 at end"),
                    tags$p("→ 40 > 8 (parent) → swap"),
                    tags$p("→ 40 > 25 (parent) → swap"),
                    tags$p("→ 40 < 100 (parent) → stop"),
                    tags$p("Result: heap property restored ✓")
                )
            )
          ),

          fluidRow(
            box(title = "⬇️ Pop (Delete Root) — Trickle Down", status = "danger", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("Algorithm"),
                    tags$ol(
                      tags$li("Save the root value (maximum) to return"),
                      tags$li("Move the", tags$strong("last node"), "to the root position"),
                      tags$li("Remove the last element"),
                      tags$li("Compare root with its two children"),
                      tags$li("Swap root with the", tags$strong("larger"), "child if any child is larger"),
                      tags$li("Repeat steps 4–5 until node ≥ both children (or becomes a leaf)")
                    )
                ),
                div(class = "warn-box",
                    HTML("<strong>⚠ Why move the last node?</strong> Removing the root would break
                          the 'complete tree' property. Moving the last node preserves completeness;
                          trickle-down then restores the heap property."))
            ),

            box(title = "📋 Priority Queue & Heap Sort", status = "success", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("Priority Queue"),
                    tags$p("A priority queue is an", tags$strong("abstract data type"),
                           "where each element has a priority, and the highest-priority element
                           is always dequeued first."),
                    tags$p("A heap is the classic", tags$em("implementation"), "of a priority queue.")
                ),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Operation"), tags$th("Array (unsorted)"), tags$th("Array (sorted)"), tags$th("Heap"))),
                  tags$tbody(
                    tags$tr(tags$td("Insert"),     tags$td("O(1)"),   tags$td("O(N)"),   tags$td("O(log N) ✅")),
                    tags$tr(tags$td("Delete max"), tags$td("O(N)"),   tags$td("O(1)"),   tags$td("O(log N) ✅")),
                    tags$tr(tags$td("Read max"),   tags$td("O(N)"),   tags$td("O(1)"),   tags$td("O(1) ✅"))
                  )
                ),
                div(class = "success-box",
                    HTML("<strong>✅ Heap Sort:</strong> Insert all N elements into a heap — O(N log N).
                          Then pop all N elements — O(N log N). Result: sorted descending, overall
                          O(N log N) with O(1) extra space (in-place variant)."))
            )
          )
        ), # end Theory

        # ── CODE LAB ─────────────────────────────────────────
        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header(
            "Chapter 16 — Heaps",
            "Complete max-heap implementation: array storage, index arithmetic helpers, O(log N) insert with trickle-up, and O(log N) pop with trickle-down."
          ),
          file_pills_ui(ns, CH16_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter16_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH16_FILES)
  })
}
