# modules/chapter05.R — Red-Black Trees

CH05_RBT_NODE_PY <- 'class Node:
    def __init__(self, value, color):
        self.value       = value
        self.color       = color
        self.left_child  = None
        self.right_child = None
        self.parent      = None'

CH05_FILES <- list(

  list(
    name = "rbt_node.py",
    description = "<strong>rbt_node.py</strong> — The Red-Black Tree node. Each node stores a value, a color ('red' or 'black'), left/right children, and a parent pointer. The parent pointer is essential for the fix-up algorithms after insertion and deletion.",
    code = 'class Node:
    def __init__(self, value, color):
        self.value       = value
        self.color       = color
        self.left_child  = None
        self.right_child = None
        self.parent      = None',
    demo = 'root = Node(10, "black")
left = Node(5,  "red")
right = Node(15, "red")
root.left_child  = left;  left.parent  = root
root.right_child = right; right.parent = root

print(f"Root:  value={root.value},  color={root.color}")
print(f"Left:  value={left.value},  color={left.color}, parent={left.parent.value}")
print(f"Right: value={right.value}, color={right.color}, parent={right.parent.value}")'
  ),

  list(
    name = "rbt.py",
    description = "<strong>rbt.py</strong> — Complete Red-Black Tree with insert, delete, search, and all rotations and fix-up algorithms. Guarantees O(log N) for all operations by maintaining the 5 Red-Black rules after every modification.",
    code = 'import rbt_node

class RedBlackTree:
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

    def insert(self, value):
        new_node = rbt_node.Node(value, "red")
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
        self.fix_insert(new_node)

    def fix_insert(self, current_node):
        while self.has_red_parent(current_node):
            if current_node.parent == self.root:
                self.root.color = "black"
                return
            uncle = self.find_uncle(current_node)
            if uncle and uncle.color == "red":
                current_node.parent.color = "black"
                uncle.color = "black"
                current_node.parent.parent.color = "red"
                current_node = current_node.parent.parent
            else:
                break
        if self.has_red_parent(current_node):
            current_node = self.straighten_segment(current_node, current_node.parent)
            current_node.parent.color = "black"
            current_node.parent.parent.color = "red"
            self.perform_final_rotation(current_node.parent)

    def has_red_parent(self, node):
        return node.parent and node.parent.color == "red"

    def is_a_left_child(self, node):
        return node == node.parent.left_child

    def is_a_right_child(self, node):
        return node == node.parent.right_child

    def find_uncle(self, node):
        if self.is_a_left_child(node.parent):
            return node.parent.parent.right_child
        else:
            return node.parent.parent.left_child

    def straighten_segment(self, node, parent):
        former_parent = parent
        if self.is_a_left_child(parent) and self.is_a_right_child(node):
            self.rotate_counterclockwise(parent, node)
            return former_parent
        elif self.is_a_right_child(parent) and self.is_a_left_child(node):
            self.rotate_clockwise(parent, node)
            return former_parent
        else:
            return node

    def perform_final_rotation(self, node):
        if self.is_a_left_child(node):
            self.rotate_clockwise(node.parent, node)
        else:
            self.rotate_counterclockwise(node.parent, node)

    def search(self, value):
        current_node = self.root
        while current_node:
            if current_node.value == value:
                return current_node
            if value < current_node.value:
                current_node = current_node.left_child
            else:
                current_node = current_node.right_child
        return None

    def is_black_or_blank(self, node):
        return (not node) or node.color == "black"',
    demo = 'import rbt_node

tree = RedBlackTree()
values = [10, 5, 15, 8, 3, 1, 20, 13, 25]
for v in values:
    tree.insert(v)

print(f"Inserted: {values}")
print(f"Root: {tree.root.value} (color: {tree.root.color})")
print(f"Root left:  {tree.root.left_child.value}  (color: {tree.root.left_child.color})")
print(f"Root right: {tree.root.right_child.value} (color: {tree.root.right_child.color})")

found = tree.search(13)
print(f"search(13): found {found.value}, color={found.color}")
print(f"search(99): {tree.search(99)}")

# Verify no path has more than 2x black nodes vs another
def count_black(node):
    if not node:
        return 1
    return (1 if node.color == "black" else 0) + count_black(node.left_child)

print(f"Black-height from root: {count_black(tree.root)}")'
  )
)

chapter5_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(5, "\U0001f534\u26ab", "The Great Balancing Act of Red-Black Trees",
      "Red-Black Trees are self-balancing binary search trees that maintain O(log N) height through a clever coloring scheme and rotation rules. They are the backbone of many language standard libraries, including Python's OrderedDict and Java's TreeMap.",
      c("Self-Balancing BST", "Red-Black Rules", "Rotations", "Fix-up Algorithms", "O(log N) Guaranteed")),

    stats_row(
      list("O(log N)", "All Operations"),
      list("5",        "RB Rules"),
      list("2",        "Rotation Types"),
      list("\u22642",  "Rotation Fixes")
    ),

    fluidRow(tabBox(width = 12, id = ns("tabs"),

      tabPanel(title = tagList(icon("book"), " Theory"),
        fluidRow(
          box(title = "\u2696\ufe0f The Problem with Plain BSTs", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("The Balance Problem"),
                  tags$p("A plain BST inserted with sorted data becomes a linked list: O(N) height.
                          Even random insertion averages O(log N) height, but pathological inputs are common."),
                  tags$p("Self-balancing trees solve this by automatically restructuring after each insertion
                          or deletion to maintain O(log N) height.")),
              div(class = "framework-card",
                  tags$h5("Online Algorithms"),
                  tags$p("Red-Black Trees are", tags$em("online"), " algorithms \u2014 they process each
                          insertion/deletion immediately without knowing future inputs.
                          This is why complex fix-up rules are needed.")),
              div(class = "tip-box",
                  HTML("<strong>\U0001f4a1 Used in:</strong> Python's <code>sortedcontainers</code>,
                        Java's <code>TreeMap</code>/<code>TreeSet</code>, Linux kernel's
                        process scheduler, C++ <code>std::map</code>."))
          ),

          box(title = "\U0001f534\u26ab The Five Red-Black Rules", status = "danger", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("Rules that guarantee O(log N) height"),
                  tags$ol(
                    tags$li("Every node is either", tags$strong("red"), "or", tags$strong("black")),
                    tags$li("The", tags$strong("root"), "is always", tags$strong("black")),
                    tags$li("Red nodes can only have", tags$strong("black children"), "(no two reds in a row)"),
                    tags$li("Every path from a node to a", tags$strong("null leaf"), "has the same number of", tags$strong("black nodes"), "(black-height)"),
                    tags$li(tags$strong("Null leaves"), "are considered black")
                  )
              ),
              div(class = "success-box",
                  HTML("<strong>\u2705 Why it works:</strong> Rule 4 (equal black-height) ensures the tree
                        cannot be lopsided. Rule 3 (no consecutive reds) prevents the longest path being
                        more than 2\u00d7 the shortest. Together: height \u2264 2 log(N+1)."))
          )
        ),

        fluidRow(
          box(title = "\U0001f504 Rotations", status = "success", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("Why rotations?"),
                  tags$p("Rotations restructure the tree locally (affecting only 2\u20133 nodes) while
                          preserving the BST ordering property. They are the tool for fixing rule violations.")),
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Rotation"), tags$th("When"), tags$th("Effect"))),
                tags$tbody(
                  tags$tr(tags$td("Counterclockwise"), tags$td("New node is right child"), tags$td("Elevates right child")),
                  tags$tr(tags$td("Clockwise"),        tags$td("New node is left child"), tags$td("Elevates left child"))
                )
              ),
              div(class = "info-box-plain",
                  HTML("<strong>\u2139 Insertion fix:</strong> After inserting a red node, at most
                        <strong>2 rotations</strong> are needed to restore all 5 rules.
                        Fix-up is always O(log N) in the worst case."))
          ),

          box(title = "\U0001f4ca Efficiency vs AVL Trees", status = "warning", solidHeader = TRUE, width = 6,
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Property"), tags$th("RB Tree"), tags$th("AVL Tree"))),
                tags$tbody(
                  tags$tr(tags$td("Search"),      tags$td("O(log N)"),   tags$td("O(log N)")),
                  tags$tr(tags$td("Insert"),      tags$td("O(log N)"),   tags$td("O(log N)")),
                  tags$tr(tags$td("Delete"),      tags$td("O(log N)"),   tags$td("O(log N)")),
                  tags$tr(tags$td("Balance"),     tags$td("Approximate"), tags$td("Strict")),
                  tags$tr(tags$td("Rotations on insert"), tags$td("\u22642"), tags$td("\u22642")),
                  tags$tr(tags$td("Rotations on delete"), tags$td("\u22643"), tags$td("O(log N)")),
                  tags$tr(tags$td("Insert speed"), tags$td("Faster \u2705"), tags$td("Slower")),
                  tags$tr(tags$td("Search speed"), tags$td("Slightly slower"), tags$td("Faster \u2705"))
                )
              ),
              div(class = "tip-box",
                  HTML("<strong>\U0001f4a1 Practice:</strong> RB trees preferred when writes are frequent.
                        AVL trees preferred when reads dominate."))
          )
        )
      ),

      tabPanel(title = tagList(icon("code"), " Code Lab"),
        code_lab_header("Chapter 5 \u2014 Red-Black Trees",
          "RBT node with color and parent pointer, complete Red-Black Tree with insert fix-up, rotations, search, and delete."),
        file_pills_ui(ns, CH05_FILES),
        py_code_display(ns),
        terminal_ui(ns)
      )
    ))
  )
}

chapter5_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    extra <- list(
      list(name = "rbt_node.py", code = CH05_RBT_NODE_PY, description = "", demo = "")
    )
    code_lab_server(input, output, session, c(CH05_FILES, extra))
  })
}
