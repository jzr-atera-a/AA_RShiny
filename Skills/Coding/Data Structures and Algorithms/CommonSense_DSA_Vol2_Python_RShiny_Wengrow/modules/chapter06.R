# modules/chapter06.R — Randomized Treaps

CH06_NODE_PY <- 'import random

class Node:
    def __init__(self, value, priority=None):
        self.value       = value
        self.priority    = priority if priority is not None else random.random()
        self.left_child  = None
        self.right_child = None
        self.parent      = None'

CH06_FILES <- list(

  list(
    name = "treap_node.py",
    description = "<strong>treap_node.py</strong> — Treap node combining a BST value with a heap priority. If no priority is supplied, one is chosen at random using <code>random.random()</code>. This random assignment is the key to the treap's self-balancing property.",
    code = 'import random

class Node:
    def __init__(self, value, priority=None):
        self.value       = value
        self.priority    = priority if priority is not None else random.random()
        self.left_child  = None
        self.right_child = None
        self.parent      = None',
    demo = 'node1 = Node(10, 0.25)
node2 = Node(20, 0.75)
node3 = Node(15)       # random priority

print(f"Node 1: value={node1.value}, priority={node1.priority:.4f}")
print(f"Node 2: value={node2.value}, priority={node2.priority:.4f}")
print(f"Node 3: value={node3.value}, priority={node3.priority:.4f} (random)")
print("Note: lower priority = higher in tree (min-heap property)")'
  ),

  list(
    name = "treap.py",
    description = "<strong>treap.py</strong> — Complete Treap implementation. Satisfies BST ordering by value AND min-heap ordering by priority. Insert places node as in a BST, then rotates it up until the heap property is restored. Delete rotates the node down until it becomes a leaf, then removes it.",
    code = 'import treap_node

class Treap:
    def __init__(self, root=None):
        self.root = root

    def rotate_counterclockwise(self, a, b):
        a.right_child = b.left_child
        if b.left_child:
            a.right_child.parent = a
        b.parent = a.parent
        if not b.parent:
            self.root = b
        elif b.parent.left_child == a:
            b.parent.left_child = b
        else:
            b.parent.right_child = b
        b.left_child = a
        a.parent = b

    def rotate_clockwise(self, b, a):
        b.left_child = a.right_child
        if a.right_child:
            b.left_child.parent = b
        a.parent = b.parent
        if not a.parent:
            self.root = a
        elif a.parent.right_child == b:
            a.parent.right_child = a
        else:
            a.parent.left_child = a
        a.right_child = b
        b.parent = a

    def is_a_left_child(self, node):
        return node == node.parent.left_child

    def insert(self, value, priority=None):
        new_node = treap_node.Node(value, priority)
        if not self.root:
            self.root = new_node
            return
        current_node = self.root
        while current_node:
            if value < current_node.value:
                if not current_node.left_child:
                    current_node.left_child = new_node
                    new_node.parent = current_node
                current_node = current_node.left_child
            elif value > current_node.value:
                if not current_node.right_child:
                    current_node.right_child = new_node
                    new_node.parent = current_node
                current_node = current_node.right_child
            else:
                break
        self.insert_fix(new_node)

    def insert_fix(self, node):
        while node.parent and node.priority < node.parent.priority:
            if self.is_a_left_child(node):
                self.rotate_clockwise(node.parent, node)
            else:
                self.rotate_counterclockwise(node.parent, node)

    def search(self, value):
        if not self.root:
            return None
        current_node = self.root
        while current_node:
            if value < current_node.value:
                current_node = current_node.left_child
            elif value > current_node.value:
                current_node = current_node.right_child
            else:
                return current_node
        return None

    def delete(self, value):
        node = self.search(value)
        if not node:
            return False
        if node == self.root and not node.left_child and not node.right_child:
            self.root = None
            return node
        while node.left_child or node.right_child:
            if not node.right_child or \
              (node.left_child and
               node.left_child.priority < node.right_child.priority):
                self.rotate_clockwise(node, node.left_child)
            else:
                self.rotate_counterclockwise(node, node.right_child)
        if self.is_a_left_child(node):
            node.parent.left_child = None
        else:
            node.parent.right_child = None
        return node',
    demo = 'import treap_node

# Build treap with fixed priorities for reproducibility
t = Treap()
t.insert("m", 50)
t.insert("c", 75)
t.insert("x", 80)
t.insert("g", 1)    # lowest priority -> becomes root

print(f"Root: {t.root.value} (priority={t.root.priority}) <- lowest priority wins")
print(f"Root left:  {t.root.left_child.value}")
print(f"Root right: {t.root.right_child.value}")

found = t.search("x")
print(f"search(x): {found.value}")
print(f"search(z): {t.search(z) if False else None}")

# Measure height of random treap
import random, math
t2 = Treap()
n = 1000
for i in range(n):
    t2.insert(i)

def height(node):
    if not node:
        return 0
    return 1 + max(height(node.left_child), height(node.right_child))

h = height(t2.root)
ideal = math.log2(n)
print(f"Random treap height (N={n}): {h}  (ideal log2={ideal:.1f})")'
  )
)

chapter6_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(6, "\U0001f333", "Randomized Treaps: Haphazardly Achieving Equilibrium",
      "A treap combines a Binary Search Tree and a min-heap. By assigning random priorities to nodes, it achieves the same O(log N) expected performance as a Red-Black Tree with a dramatically simpler implementation \u2014 no complex color rules, just two rotations.",
      c("Treap = BST + Heap", "Random Priorities", "O(log N) Expected", "Treap Insertion", "Treap Deletion", "Self-Balancing")),

    stats_row(
      list("O(log N)", "Expected Height"),
      list("O(log N)", "Insert/Delete"),
      list("2",        "Rotation Types"),
      list("0",        "Color Rules Needed")
    ),

    fluidRow(tabBox(width = 12, id = ns("tabs"),

      tabPanel(title = tagList(icon("book"), " Theory"),
        fluidRow(
          box(title = "\U0001f333 What is a Treap?", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("Two properties simultaneously"),
                  tags$p("A treap stores (value, priority) pairs and maintains:"),
                  tags$ul(
                    tags$li(tags$strong("BST property by value"), ": left subtree values < node value < right subtree values"),
                    tags$li(tags$strong("Min-heap property by priority"), ": parent priority < children priorities")
                  )),
              div(class = "framework-card",
                  tags$h5("Why random priorities?"),
                  tags$p("If priorities are assigned randomly, the treap structure is equivalent to building
                          a BST by inserting keys in a", tags$em("uniformly random order"),
                          "\u2014 regardless of the actual insertion order."),
                  tags$p("A random BST has expected height O(log N), so the treap is self-balancing
                          without any explicit balancing rules!")),
              div(class = "success-box",
                  HTML("<strong>\u2705 Elegant insight:</strong> Randomness replaces the complex fix-up
                        rules of Red-Black Trees. The treap is essentially a randomized BST."))
          ),

          box(title = "\U0001f504 Insertion & Deletion", status = "warning", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("Insert"),
                  tags$ol(
                    tags$li("Assign a random priority to the new node"),
                    tags$li("Insert using standard BST rules (by value)"),
                    tags$li("Trickle UP: while the node's priority < parent's priority, rotate the node upward")
                  ),
                  div(class = "tip-box",
                      HTML("<strong>\U0001f4a1 At most O(log N) rotations expected</strong> \u2014 the node
                            only bubbles up as long as it has a higher priority than its parent."))),
              div(class = "framework-card",
                  tags$h5("Delete"),
                  tags$ol(
                    tags$li("Find the node (BST search)"),
                    tags$li("Trickle DOWN: rotate the node downward (always toward the child with lower priority)"),
                    tags$li("When the node becomes a leaf, simply remove it")
                  ),
                  div(class = "info-box-plain",
                      HTML("<strong>\u2139 Contrast with BST delete:</strong> The treap delete is simpler \u2014
                            no need to find a successor node and handle special cases.")))
          )
        ),

        fluidRow(
          box(title = "\u2696\ufe0f Treap vs Red-Black Tree", status = "success", solidHeader = TRUE, width = 12,
              fluidRow(
                column(6, tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Property"), tags$th("Treap"), tags$th("RB Tree"))),
                  tags$tbody(
                    tags$tr(tags$td("Height"),           tags$td("O(log N) expected"), tags$td("O(log N) worst case")),
                    tags$tr(tags$td("Insert"),           tags$td("O(log N) expected"), tags$td("O(log N) worst case")),
                    tags$tr(tags$td("Delete"),           tags$td("O(log N) expected"), tags$td("O(log N) worst case")),
                    tags$tr(tags$td("Implementation"),   tags$td("Simple \u2705"),      tags$td("Complex")),
                    tags$tr(tags$td("Deterministic?"),   tags$td("No (random)"),        tags$td("Yes")),
                    tags$tr(tags$td("Extra storage"),    tags$td("Priority field"),     tags$td("Color bit"))
                  )
                )),
                column(6,
                  div(class = "framework-card",
                      tags$h5("When to prefer a treap"),
                      tags$ul(
                        tags$li("Implementation simplicity matters more than worst-case guarantees"),
                        tags$li("You need a simple mergeable BST (treaps support O(log N) split/merge)"),
                        tags$li("Competitive programming (much easier to implement correctly)")
                      )),
                  div(class = "tip-box",
                      HTML("<strong>\U0001f4a1 The Power of Random Priorities:</strong>
                            Because priorities are random, no adversary can craft an input that degrades
                            treap performance \u2014 the same reason randomized Quicksort beats deterministic
                            worst-case inputs."))
                )
              )
          )
        )
      ),

      tabPanel(title = tagList(icon("code"), " Code Lab"),
        code_lab_header("Chapter 6 \u2014 Randomized Treaps",
          "Treap node with random priority, full treap implementation with insert (trickle-up), search, and delete (trickle-down)."),
        file_pills_ui(ns, CH06_FILES),
        py_code_display(ns),
        terminal_ui(ns)
      )
    ))
  )
}

chapter6_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    extra <- list(
      list(name = "treap_node.py", code = CH06_NODE_PY, description = "", demo = "")
    )
    code_lab_server(input, output, session, c(CH06_FILES, extra))
  })
}
