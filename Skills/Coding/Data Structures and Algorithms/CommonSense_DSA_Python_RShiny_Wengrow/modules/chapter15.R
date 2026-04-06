# modules/chapter15.R
# Chapter 15: Binary Search Trees — search/insert/delete/traversals in O(log N)

CH15_TREE_NODE_PY <- 'class TreeNode:
    def __init__(self, value, left=None, right=None):
        self.value       = value
        self.left_child  = left
        self.right_child = right'

CH15_INSERT_PY <- 'import tree_node

def insert(value, node):
    if value < node.value:
        if not node.left_child:
            node.left_child = tree_node.TreeNode(value)
        else:
            insert(value, node.left_child)
    elif value > node.value:
        if not node.right_child:
            node.right_child = tree_node.TreeNode(value)
        else:
            insert(value, node.right_child)'

CH15_SEARCH_PY <- 'def search(search_value, node):
    if not node or node.value == search_value:
        return node
    elif search_value < node.value:
        return search(search_value, node.left_child)
    else:
        return search(search_value, node.right_child)'

CH15_FILES <- list(

  list(
    name        = "tree_node.py",
    description = "<strong>tree_node.py</strong> — The building block of a binary tree. Each
                   <code>TreeNode</code> stores a <code>value</code> and optional
                   <code>left_child</code> / <code>right_child</code> pointers.",
    code = 'class TreeNode:
    def __init__(self, value, left=None, right=None):
        self.value       = value
        self.left_child  = left
        self.right_child = right',
    demo = '# Build a tiny BST by hand
root  = TreeNode(50)
left  = TreeNode(25)
right = TreeNode(75)
root.left_child  = left
root.right_child = right

print(f"root.value              = {root.value}")
print(f"root.left_child.value   = {root.left_child.value}")
print(f"root.right_child.value  = {root.right_child.value}")'
  ),

  list(
    name        = "search.py",
    description = "<strong>search.py</strong> — Recursive BST search. At each node, compare the target
                   with the current value: if smaller go left, if larger go right. O(log N) for
                   a balanced tree — O(N) worst case (completely skewed tree).",
    code = 'def search(search_value, node):
    # Base cases: not found (None) or found
    if not node or node.value == search_value:
        return node
    elif search_value < node.value:
        return search(search_value, node.left_child)   # go left
    else:
        return search(search_value, node.right_child)  # go right',
    demo = 'import tree_node, insert as ins

root = tree_node.TreeNode(50)
for v in [25, 75, 10, 33, 56, 89]:
    ins.insert(v, root)

found = search(33, root)
print(f"search(33)  -> found node with value {found.value}")
print(f"search(100) -> {search(100, root)}")'
  ),

  list(
    name        = "insert.py",
    description = "<strong>insert.py</strong> — Recursive BST insert. Walks down the tree following
                   the same left/right rule as search, then attaches a new node at the first
                   empty child slot. O(log N) balanced, O(N) worst case.",
    code = 'import tree_node

def insert(value, node):
    if value < node.value:
        if not node.left_child:
            node.left_child = tree_node.TreeNode(value)  # insert here
        else:
            insert(value, node.left_child)               # recurse left
    elif value > node.value:
        if not node.right_child:
            node.right_child = tree_node.TreeNode(value) # insert here
        else:
            insert(value, node.right_child)              # recurse right',
    demo = 'import tree_node, search as srch

root = tree_node.TreeNode(50)
for v in [25, 75, 10, 33, 60, 89, 4, 11, 30, 40]:
    insert(v, root)

# Verify a few
for v in [50, 4, 89, 40, 99]:
    node = srch.search(v, root)
    print(f"search({v:3}) -> {node.value if node else None}")'
  ),

  list(
    name        = "in_order_traversal.py",
    description = "<strong>in_order_traversal.py</strong> — Visits nodes left → root → right.
                   For a BST, this always produces values in", tags$strong("ascending sorted order"),
                   " — a free sort!",
    code = 'def traverse_and_print(node):
    if not node:
        return
    traverse_and_print(node.left_child)   # left subtree first
    print(node.value)                     # then this node
    traverse_and_print(node.right_child)  # then right subtree',
    demo = 'import tree_node, insert as ins

root = tree_node.TreeNode(50)
for v in [25, 75, 10, 33, 60, 89]:
    ins.insert(v, root)

print("In-order traversal (ascending order):")
traverse_and_print(root)'
  ),

  list(
    name        = "preorder_traversal.py",
    description = "<strong>preorder_traversal.py</strong> — Visits root → left → right.
                   Useful for copying a tree or generating prefix expressions.",
    code = 'def traverse_and_print(node):
    if not node:
        return
    print(node.value)                     # root first
    traverse_and_print(node.left_child)
    traverse_and_print(node.right_child)',
    demo = 'import tree_node, insert as ins

root = tree_node.TreeNode(5)
for v in [2, 7, 1, 3, 6, 8]:
    ins.insert(v, root)

print("Pre-order traversal:")
traverse_and_print(root)'
  ),

  list(
    name        = "postorder_traversal.py",
    description = "<strong>postorder_traversal.py</strong> — Visits left → right → root.
                   Useful for deleting a tree (children before parent) or evaluating
                   postfix expressions.",
    code = 'def traverse_and_print(node):
    if not node:
        return
    traverse_and_print(node.left_child)
    traverse_and_print(node.right_child)
    print(node.value)                     # root last',
    demo = 'import tree_node, insert as ins

root = tree_node.TreeNode(5)
for v in [2, 7, 1, 3, 6, 8]:
    ins.insert(v, root)

print("Post-order traversal:")
traverse_and_print(root)'
  ),

  list(
    name        = "solution3.py",
    description = "<strong>solution3.py</strong> — Finds the maximum value in a BST recursively.
                   In a BST, the maximum is always the rightmost node. Recursively follows
                   right children until there are none. O(log N) balanced, O(N) worst.",
    code = 'def max(node):
    if node.right_child:
        return max(node.right_child)   # always go right
    else:
        return node.value              # rightmost node = max',
    demo = 'import tree_node, insert as ins

root = tree_node.TreeNode(50)
for v in [25, 75, 10, 33, 60, 89, 4, 11, 30, 40, 56, 82, 95]:
    ins.insert(v, root)

print(f"max(root) = {max(root)}")'
  )
)

chapter15_ui <- function(id) {
  ns <- NS(id)
  tagList(

    chapter_hero(15, "🌳", "Binary Search Trees",
      "Binary search trees combine the O(1) insert elegance of linked lists with the O(log N) search speed of binary search. Understanding BSTs unlocks a whole family of balanced tree structures used throughout computer science.",
      c("BST", "Search O(log N)", "Insert O(log N)", "Delete", "In/Pre/Post-order", "Successor Node")),

    stats_row(
      list("O(log N)", "Search (balanced)"),
      list("O(log N)", "Insert (balanced)"),
      list("O(N)",     "Worst case (skewed)"),
      list("3",        "Traversal orders")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        # ── THEORY ───────────────────────────────────────────
        tabPanel(title = tagList(icon("book"), " Theory"),

          fluidRow(
            box(title = "🌳 BST Structure & Rules", status = "info", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("The BST Property"),
                    tags$p("For every node N in a BST:"),
                    tags$ul(
                      tags$li("All values in the", tags$strong("left"), "subtree are", tags$strong("less than"), "N"),
                      tags$li("All values in the", tags$strong("right"), "subtree are", tags$strong("greater than"), "N"),
                      tags$li("Both subtrees are also BSTs (recursive definition)")
                    )
                ),
                div(class = "framework-card",
                    tags$h5("Why O(log N)?"),
                    tags$p("At each step of search or insert, we discard", tags$strong("half"), "the
                            remaining nodes by choosing left or right. This is binary search applied
                            to a tree structure."),
                    tags$p("A perfectly balanced BST of N nodes has height ≈ log₂(N). Each
                            operation takes at most", tags$em("height"), "steps.")
                ),
                div(class = "tip-box",
                    HTML("<strong>💡 Balanced matters:</strong> A skewed BST (nodes inserted in sorted
                          order) degenerates into a linked list — O(N) operations. Self-balancing trees
                          (AVL, Red-Black) maintain balance automatically."))
            ),

            box(title = "🔍 Search & Insert", status = "warning", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("Search Algorithm"),
                    tags$ol(
                      tags$li("Start at root"),
                      tags$li("If target = current node → found!"),
                      tags$li("If target < current → go left"),
                      tags$li("If target > current → go right"),
                      tags$li("If reach None → not in tree")
                    )
                ),
                div(class = "framework-card",
                    tags$h5("Insert Algorithm"),
                    tags$p("Identical walk to search — but when you reach a None child where the
                            value would go, create a new node there instead.")
                ),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Operation"), tags$th("Ordered Array"), tags$th("BST (balanced)"))),
                  tags$tbody(
                    tags$tr(tags$td("Search"), tags$td("O(log N)"), tags$td("O(log N)")),
                    tags$tr(tags$td("Insert"), tags$td("O(N)"),     tags$td("O(log N) ✅")),
                    tags$tr(tags$td("Delete"), tags$td("O(N)"),     tags$td("O(log N) ✅"))
                  )
                )
            )
          ),

          fluidRow(
            box(title = "🗑️ Deletion — The Tricky Case", status = "danger", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("Three deletion scenarios"),
                    tags$ul(
                      tags$li(tags$strong("No children (leaf)"), " — simply remove the node."),
                      tags$li(tags$strong("One child"), " — replace the node with its child."),
                      tags$li(tags$strong("Two children"), " — must find the", tags$strong("in-order successor"),
                              "(leftmost node in the right subtree) and use it to replace the deleted node.")
                    )
                ),
                div(class = "info-box-plain",
                    HTML("<strong>ℹ In-order successor:</strong> The smallest value greater than the deleted
                          node. After the swap, the BST property is maintained because the successor is
                          larger than everything in the left subtree and smaller than everything else
                          in the right subtree."))
            ),

            box(title = "🌿 Tree Traversals", status = "success", solidHeader = TRUE, width = 6,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Order"), tags$th("Pattern"), tags$th("Use Case"))),
                  tags$tbody(
                    tags$tr(tags$td("In-order"),   tags$td("Left → Root → Right"), tags$td("Sorted output from BST")),
                    tags$tr(tags$td("Pre-order"),  tags$td("Root → Left → Right"), tags$td("Copy/serialise tree")),
                    tags$tr(tags$td("Post-order"), tags$td("Left → Right → Root"), tags$td("Delete tree; postfix eval"))
                  )
                ),
                div(class = "success-box",
                    HTML("<strong>✅ In-order magic:</strong> Running in-order traversal on any BST
                          outputs all values in ascending sorted order — for free!")),
                div(class = "framework-card",
                    tags$h5("Finding the Maximum"),
                    tags$p("In a BST, the maximum value is always the", tags$strong("rightmost node."),
                           "Follow right children until you can't go further."))
            )
          )
        ), # end Theory

        # ── CODE LAB ─────────────────────────────────────────
        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header(
            "Chapter 15 — Binary Search Trees",
            "TreeNode class, recursive search, recursive insert, all three traversal orders, BST max finder, and the complex deletion algorithm."
          ),
          file_pills_ui(ns, CH15_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter15_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # Inject helper siblings: tree_node, insert, search needed by multiple files
    extra <- list(
      list(name = "tree_node.py", code = CH15_TREE_NODE_PY, description = "", demo = ""),
      list(name = "insert.py",    code = CH15_INSERT_PY,    description = "", demo = ""),
      list(name = "search.py",    code = CH15_SEARCH_PY,    description = "", demo = "")
    )
    code_lab_server(input, output, session, c(CH15_FILES, extra))
  })
}
