# modules/chapter14.R
# Chapter 14: Linked Lists — Nodes, singly/doubly linked lists, O(1) front operations

# ── Helper node source files (injected as siblings at run time) ──────────────
CH14_NODE_PY <- 'class Node:
    def __init__(self, data):
        self.data      = data
        self.next_node = None'

CH14_DBL_NODE_PY <- 'class Node:
    def __init__(self, data):
        self.data          = data
        self.next_node     = None
        self.previous_node = None'

CH14_FILES <- list(

  list(
    name        = "node.py",
    description = "<strong>node.py</strong> — The fundamental building block of a linked list.
                   Each <code>Node</code> holds a <code>data</code> value and a
                   <code>next_node</code> pointer. Nodes are stored anywhere in memory —
                   unlike arrays, they need not be contiguous.",
    code = 'class Node:
    def __init__(self, data):
        self.data      = data
        self.next_node = None',
    demo = '# Build a mini linked list by hand
node1 = Node("once")
node2 = Node("upon")
node3 = Node("a")
node4 = Node("time")
node1.next_node = node2
node2.next_node = node3
node3.next_node = node4

# Walk the chain
current = node1
while current:
    print(current.data)
    current = current.next_node'
  ),

  list(
    name        = "linked_list.py",
    description = "<strong>linked_list.py</strong> — Singly linked list with <code>read</code>,
                   <code>search</code>, <code>append</code>, <code>insert</code>,
                   <code>delete</code>, <code>last</code>, and <code>reverse</code>.
                   Reads/searches are O(N); insert/delete at the front are O(1).",
    code = 'import node

class LinkedList:

    def __init__(self, first_node=None):
        self.first_node = first_node

    def read(self, index):
        current_node  = self.first_node
        current_index = 0
        while current_index < index:
            current_node  = current_node.next_node
            current_index += 1
            if not current_node:
                return None
        return current_node.data

    def search(self, value):
        current_node  = self.first_node
        current_index = 0
        while True:
            if current_node.data == value:
                return current_index
            current_node = current_node.next_node
            if not current_node:
                break
            current_index += 1
        return None

    def append(self, value):
        new_node = node.Node(value)
        if not self.first_node:
            self.first_node = new_node
            return
        current_node = self.first_node
        while current_node.next_node:
            current_node = current_node.next_node
        current_node.next_node = new_node

    def insert(self, index, value):
        new_node = node.Node(value)
        if index == 0:
            new_node.next_node = self.first_node
            self.first_node    = new_node
            return
        current_node  = self.first_node
        current_index = 0
        while current_index < (index - 1):
            current_node  = current_node.next_node
            current_index += 1
        new_node.next_node     = current_node.next_node
        current_node.next_node = new_node

    def delete(self, index):
        if index == 0:
            self.first_node = self.first_node.next_node
            return
        current_node  = self.first_node
        current_index = 0
        while current_index < (index - 1):
            current_node  = current_node.next_node
            current_index += 1
        current_node.next_node = current_node.next_node.next_node

    def print_list(self):
        current_node = self.first_node
        while current_node:
            print(current_node.data)
            current_node = current_node.next_node

    def last(self):
        current_node = self.first_node
        while current_node.next_node:
            current_node = current_node.next_node
        return current_node.data

    def reverse(self):
        previous_node = None
        current_node  = self.first_node
        while current_node:
            next_node              = current_node.next_node
            current_node.next_node = previous_node
            previous_node          = current_node
            current_node           = next_node
        self.first_node = previous_node',
    demo = 'import node as node_module

# Build list
ll = LinkedList()
for word in ["once", "upon", "a", "time"]:
    ll.append(word)

print("Original list:")
ll.print_list()

print(f"\nread(2)       = {ll.read(2)}")
print(f"search(a)     = {ll.search(chr(97))}")

ll.insert(0, "Hello!")
print(f"\nAfter insert(0, Hello!):")
ll.print_list()

ll.delete(0)
print(f"\nAfter delete(0):")
ll.print_list()

ll.reverse()
print(f"\nAfter reverse():")
ll.print_list()'
  ),

  list(
    name        = "doubly_linked_list.py",
    description = "<strong>doubly_linked_list.py</strong> — Each node has both <code>next_node</code>
                   and <code>previous_node</code> pointers, enabling O(1) operations at
                   <em>both</em> ends. Used to build the efficient Queue in this chapter.",
    code = 'import double_ended_node

class DoublyLinkedList:

    def __init__(self, first_node=None, last_node=None):
        self.first_node = first_node
        self.last_node  = last_node

    def append(self, value):
        new_node = double_ended_node.Node(value)
        if not self.first_node:
            self.first_node = new_node
            self.last_node  = new_node
        else:
            new_node.previous_node      = self.last_node
            self.last_node.next_node    = new_node
            self.last_node              = new_node

    def pop_head(self):
        popped_node                     = self.first_node
        self.first_node                 = self.first_node.next_node
        self.first_node.previous_node   = None
        return popped_node

    def reverse_print(self):
        current_node = self.last_node
        while current_node:
            print(current_node.data)
            current_node = current_node.previous_node',
    demo = 'import double_ended_node

dll = DoublyLinkedList()
for v in ["A", "B", "C", "D"]:
    dll.append(v)

print(f"first_node = {dll.first_node.data}")
print(f"last_node  = {dll.last_node.data}")

print("\nReverse print (last -> first):")
dll.reverse_print()

popped = dll.pop_head()
print(f"\npopped head = {popped.data}")
print(f"new first   = {dll.first_node.data}")'
  ),

  list(
    name        = "queue.py",
    description = "<strong>queue.py</strong> — Queue backed by a <code>DoublyLinkedList</code>.
                   Because the doubly linked list has O(1) access to both ends,
                   <code>enqueue</code> (append to tail) and <code>dequeue</code>
                   (pop from head) are both O(1) — fixing the O(N) weakness of the
                   array-backed queue from Chapter 9.",
    code = 'import doubly_linked_list

class Queue:

    def __init__(self):
        self.data = doubly_linked_list.DoublyLinkedList()

    def enqueue(self, element):
        self.data.append(element)        # O(1) — add to tail

    def dequeue(self):
        dequeued_node = self.data.pop_head()  # O(1) — remove from head
        return dequeued_node.data

    def read(self):
        if not self.data.first_node:
            return None
        return self.data.first_node.data',
    demo = 'import doubly_linked_list
import double_ended_node

q = Queue()
q.enqueue("Task 1")
q.enqueue("Task 2")
q.enqueue("Task 3")

print(f"read()    = {q.read()}")
print(f"dequeue() = {q.dequeue()}")
print(f"read()    = {q.read()}")
print(f"dequeue() = {q.dequeue()}")
print(f"dequeue() = {q.dequeue()}")'
  ),

  list(
    name        = "solution5.py",
    description = "<strong>solution5.py</strong> — Deletes a node from a linked list when you only
                   have a reference to that node (not its predecessor). The trick: copy the
                   <em>next</em> node's data into this node, then skip the next node.",
    code = 'def delete_node(node):
    # Copy next node data into current node
    node.data      = node.next_node.data
    # Skip the next node
    node.next_node = node.next_node.next_node',
    demo = 'import node as node_module
import linked_list as ll_module

ll = ll_module.LinkedList()
for w in ["once", "upon", "a", "time"]:
    ll.append(w)

print("Before delete_node on the third node (a):")
ll.print_list()

# Get reference to the "a" node (index 2)
current = ll.first_node
for _ in range(2):
    current = current.next_node

delete_node(current)

print("\nAfter delete_node:")
ll.print_list()'
  )
)

chapter14_ui <- function(id) {
  ns <- NS(id)
  tagList(

    chapter_hero(14, "🔗", "Dealing with Space Constraints — Linked Lists",
      "Linked lists store elements anywhere in memory and connect them with pointers. They excel at O(1) insertion and deletion at the front — operations that cost O(N) for arrays.",
      c("Singly Linked List", "Doubly Linked List", "Nodes & Pointers", "O(1) Front Ops", "Queue via DLL")),

    stats_row(
      list("O(1)", "Insert at front"),
      list("O(N)", "Read by index"),
      list("O(1)", "DLL enqueue/dequeue"),
      list("O(N)", "Search")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        # ── THEORY ───────────────────────────────────────────
        tabPanel(title = tagList(icon("book"), " Theory"),

          fluidRow(
            box(title = "🔗 Singly Linked List", status = "info", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("Structure"),
                    tags$p("A linked list is a chain of", tags$strong("nodes."), "Each node contains a
                            data value and a pointer to the next node. The list holds a reference only
                            to the first node (the", tags$em("head"), ")."),
                    tags$p(tags$code("Node(data) → next_node → next_node → … → None"))
                ),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Operation"), tags$th("Array"), tags$th("Linked List"), tags$th("Notes"))),
                  tags$tbody(
                    tags$tr(tags$td("Read by index"), tags$td("O(1) ✅"), tags$td("O(N) ❌"), tags$td("LL must walk chain")),
                    tags$tr(tags$td("Search"),        tags$td("O(N)"),    tags$td("O(N)"),    tags$td("Both scan linearly")),
                    tags$tr(tags$td("Insert front"),  tags$td("O(N) ❌"), tags$td("O(1) ✅"), tags$td("LL just rewires head")),
                    tags$tr(tags$td("Delete front"),  tags$td("O(N) ❌"), tags$td("O(1) ✅"), tags$td("LL just moves head ptr"))
                  )
                ),
                div(class = "tip-box",
                    HTML("<strong>💡 When to prefer a linked list:</strong> When you need many
                          insertions/deletions at the front or middle, and rarely need random access by index."))
            ),

            box(title = "↔️ Doubly Linked List", status = "warning", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("Each node has TWO pointers"),
                    tags$p("A doubly linked list adds a", tags$code("previous_node"), "pointer alongside
                            the standard", tags$code("next_node"), "pointer. This enables O(1) operations
                            at", tags$strong("both ends"), "of the list."),
                    tags$ul(
                      tags$li("Access head or tail in O(1)"),
                      tags$li("Traverse forwards", tags$em("or"), "backwards"),
                      tags$li("Cost: 1 extra pointer per node (more memory)")
                    )
                ),
                div(class = "framework-card",
                    tags$h5("Why it fixes the Queue problem"),
                    tags$p("The Chapter 9 array-backed Queue used", tags$code("pop(0)"),
                           "for dequeue — O(N) because it shifts every element."),
                    tags$p("With a doubly linked list, we maintain", tags$code("first_node"),
                           "and", tags$code("last_node"), "pointers. Both enqueue (add to tail)
                           and dequeue (remove head) are", tags$strong("O(1).")),
                    div(class = "success-box",
                        HTML("<strong>✅ Result:</strong> The linked-list-backed Queue in this chapter
                              is a true O(1) queue — the standard production implementation."))
                )
            )
          ),

          fluidRow(
            box(title = "🔄 Reverse a Linked List — In-Place O(N)", status = "success", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("Three-pointer technique"),
                    tags$p("Walk the list once, reversing each pointer as you go. Uses three variables:
                            previous_node, current_node, and next_node (to save the link before overwriting it)."),
                    tags$ol(
                      tags$li("Save", tags$code("next = current.next_node")),
                      tags$li("Reverse:", tags$code("current.next_node = previous")),
                      tags$li("Advance:", tags$code("previous = current; current = next")),
                      tags$li("Repeat until", tags$code("current is None")),
                      tags$li("Set", tags$code("first_node = previous"))
                    )
                )
            ),
            box(title = "🗑️ Delete Without Predecessor", status = "danger", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("solution5 — The clever trick"),
                    tags$p("Normally deleting a node requires its predecessor's pointer. But if you only
                            have a reference to the node itself, you can:"),
                    tags$ol(
                      tags$li("Copy the", tags$strong("next"), "node's data into the current node"),
                      tags$li("Skip the next node by re-routing the pointer")
                    ),
                    tags$p("Effect: the node 'becomes' its successor, and the successor disappears."),
                    div(class = "warn-box",
                        HTML("<strong>⚠ Limitation:</strong> Doesn't work if the node is the last in the list
                              (no successor to copy from)."))
                )
            )
          )
        ), # end Theory

        # ── CODE LAB ─────────────────────────────────────────
        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header(
            "Chapter 14 — Linked Lists",
            "Node class, full singly linked list (read/search/insert/delete/reverse), doubly linked list, O(1) queue, and the predecessor-free delete trick."
          ),
          file_pills_ui(ns, CH14_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter14_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # Inject the helper node modules as sibling files
    files_with_helpers <- CH14_FILES
    # Add node.py and double_ended_node.py as extra siblings for import resolution
    extra_helpers <- list(
      list(name = "node.py",              code = CH14_NODE_PY,    description = "", demo = ""),
      list(name = "double_ended_node.py", code = CH14_DBL_NODE_PY, description = "", demo = "")
    )
    all_files <- c(files_with_helpers, extra_helpers)
    code_lab_server(input, output, session, all_files)
  })
}
