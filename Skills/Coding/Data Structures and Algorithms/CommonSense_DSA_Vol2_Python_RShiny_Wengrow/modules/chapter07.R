# modules/chapter07.R — B-Trees (External Memory)

CH07_FILES <- list(

  list(
    name = "btree.py",
    description = "<strong>btree.py</strong> — B-Tree implementation backed by CSV files on disk. Each node is a file. <code>search()</code> reads node files following child pointers. <code>insert()</code> finds the correct leaf, adds the value, and splits nodes when they overflow (more than 4 values). Demonstrates the key B-Tree invariants: all leaves at the same depth, nodes always at least half-full.",
    code = 'import os

class BTree:
    def __init__(self, root=None):
        self.root          = root
        self.max_node_size = 4

    def search(self, search_value, node=None):
        node_file = node or self.root
        node_data = self.read_node_file(node_file)
        values    = node_data.get("values")
        children  = node_data.get("children")
        index = 0
        while index < len(values):
            current_value = values[index]
            if current_value == search_value:
                return [True, node_file, index]
            if search_value < current_value:
                if children:
                    child_to_follow = children[index]
                    break
                else:
                    return [False, node_file, index]
            index += 1
        if search_value > current_value:
            if children:
                child_to_follow = children[len(children) - 1]
            else:
                return [False, node_file, index]
        return self.search(search_value, child_to_follow)

    def read_node_file(self, node_file):
        with open(node_file, "r") as reader:
            parent   = reader.readline().rstrip("\\n")
            values   = reader.readline().rstrip(",\\n").split(",")
            values   = list(map(lambda x: int(x), values))
            children = reader.readline().rstrip(",\\n").split(",")
            if children[0] == "":
                children = None
        return {"parent": parent, "values": values, "children": children}

    def insert(self, value):
        if not self.root:
            self.create_root(value)
            return
        search_result = self.search(value)
        if search_result[0]:
            return
        node_file = search_result[1]
        self.insert_into_node(node_file, value)

    def insert_into_node(self, node_file, value):
        node_data = self.read_node_file(node_file)
        values    = node_data.get("values")
        children  = node_data.get("children")
        parent    = node_data.get("parent")
        values.append(value)
        values.sort()
        if len(values) > self.max_node_size:
            self.split_node(node_file, parent, values, children)
        else:
            self.write_to_node_file(node_file, parent, values, children)

    def split_node(self, node_file, parent, values, children=None):
        os.remove(node_file)
        median_index       = self.max_node_size // 2
        left_node_filename  = str(values[0]) + ".csv"
        right_node_filename = str(values[median_index + 1]) + ".csv"
        if parent == "None":
            parent_node_filename = str(values[median_index]) + ".csv"
        else:
            parent_node_filename = parent
        if children:
            left_children  = children[:median_index + 1]
            right_children = children[median_index + 1:]
        else:
            left_children  = None
            right_children = None
        self.write_to_node_file(left_node_filename,  parent_node_filename,
                                values[:median_index],        left_children)
        self.write_to_node_file(right_node_filename, parent_node_filename,
                                values[median_index + 1:],    right_children)
        if parent == "None":
            new_parent = self.write_to_node_file(parent_node_filename,
              "None", [values[median_index]],
              [left_node_filename, right_node_filename])
            self.root = new_parent
        else:
            parent_data = self.read_node_file(parent_node_filename)
            idx = parent_data.get("children").index(node_file)
            updated_children = (parent_data.get("children")[:idx] +
                                [left_node_filename, right_node_filename] +
                                parent_data.get("children")[idx + 1:])
            self.write_to_node_file(parent_node_filename,
              parent_data.get("parent"),
              parent_data.get("values"),
              updated_children)
            self.insert_into_node(parent_node_filename, values[median_index])
        for child_list, new_parent_file in [(left_children, left_node_filename),
                                            (right_children, right_node_filename)]:
            if child_list:
                for child in child_list:
                    child_data = self.read_node_file(child)
                    self.write_to_node_file(child, new_parent_file,
                      child_data.get("values"), child_data.get("children"))

    def write_to_node_file(self, node_file, parent, values, children=None):
        values_string = "".join(str(v) + "," for v in values)
        with open(node_file, "w") as writer:
            writer.write(parent + "\\n")
            writer.write(values_string)
            if children:
                children_string = "".join(str(c) + "," for c in children)
                writer.write("\\n" + children_string)
        return node_file

    def create_root(self, value):
        filename = "root.csv"
        with open(filename, "w") as writer:
            writer.write("None\\n")
            writer.write(str(value) + ",")
        self.root = filename',
    demo = 'import os, glob

# Clean up any leftover csv files from previous runs
for f in glob.glob("*.csv"):
    os.remove(f)

# Build a B-Tree and insert values
b = BTree()
for v in [100, 50, 25, 75, 60, 10, 55, 5, 110, 120, 130, 140, 150]:
    b.insert(v)

print(f"Root file: {b.root}")
print(f"search(50): found={b.search(50)[0]}, in file={b.search(50)[1]}")
print(f"search(75): found={b.search(75)[0]}, in file={b.search(75)[1]}")
print(f"search(99): found={b.search(99)[0]}")

# Show the node files created
csv_files = sorted(glob.glob("*.csv"))
print(f"\\nNode files on disk ({len(csv_files)} nodes):")
for f in csv_files[:6]:
    with open(f) as fh:
        lines = [l.rstrip() for l in fh.readlines()]
    print(f"  {f}: {lines}")

# Clean up
for f in glob.glob("*.csv"):
    os.remove(f)'
  ),

  list(
    name = "read1.py",
    description = "<strong>read1.py</strong> — Reads a large text file line-by-line using a for loop. This is the streaming/I/O-efficient approach: reads one line at a time into memory.",
    code = 'import timeit

test_code = """
with open("text.txt", "r") as reader:
    x = 0
    for line in reader:
        x += 1
"""

print("Reading text.txt line-by-line:")
print(timeit.timeit(stmt=test_code, number=1), "seconds")',
    demo = 'import os, time

# Create a sample text file
sample = "This is a line of text in our sample file.\\n" * 1000
with open("sample_text.txt", "w") as f:
    f.write(sample)

# Read line by line (streaming - cache-friendly)
t = time.time()
with open("sample_text.txt", "r") as reader:
    count = sum(1 for _ in reader)
t1 = (time.time() - t) * 1000
print(f"Line-by-line: {count} lines in {t1:.2f} ms")

# Read all at once
t = time.time()
with open("sample_text.txt", "r") as reader:
    lines = reader.readlines()
    count2 = len(lines)
t2 = (time.time() - t) * 1000
print(f"readlines():  {count2} lines in {t2:.2f} ms")

os.remove("sample_text.txt")'
  )
)

chapter7_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(7, "\U0001f4c2", "To B-Tree or Not to B-Tree: External-Memory Algorithms",
      "When data is too large to fit in RAM, we must store it on disk. The rules change completely: each disk I/O costs thousands of times more than a RAM access, so we must minimize I/O operations rather than CPU steps. B-Trees are the dominant data structure for database indexes and file systems.",
      c("External Memory", "Count I/Os Not Steps", "B-Trees", "B-Tree Insertion", "Node Splitting", "Database Indexes")),

    stats_row(
      list("O(log\u2099 N)", "B-Tree Search"),
      list("10,000x",        "Disk vs RAM"),
      list("4",              "Max Values/Node"),
      list("Always Equal",   "Leaf Depth")
    ),

    fluidRow(tabBox(width = 12, id = ns("tabs"),

      tabPanel(title = tagList(icon("book"), " Theory"),
        fluidRow(
          box(title = "\U0001f4be External Memory", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("When data doesn't fit in RAM"),
                  tags$p("For very large datasets (databases, file systems), data lives on disk.
                          The cost model changes completely:"),
                  tags$ul(
                    tags$li("RAM access: ~100 nanoseconds"),
                    tags$li("SSD access: ~100 microseconds (1,000x slower)"),
                    tags$li("HDD access: ~10 milliseconds (100,000x slower)")
                  )),
              div(class = "framework-card",
                  tags$h5("Count I/Os, Not Steps"),
                  tags$p("In external-memory algorithms, we measure performance in",
                         tags$strong("disk I/O operations"), "rather than CPU steps.
                         Reading one disk block brings ~4KB into memory at once (a page)."),
                  tags$p("A binary search tree would need O(log N) disk reads just to search.
                          B-Trees exploit the page size to load many values per I/O.")),
              div(class = "warn-box",
                  HTML("<strong>\u26a0 This is why BSTs fail for databases:</strong>
                        Even a 1-billion node BST with O(log N)=30 levels means 30 separate
                        disk seeks just to find one record."))
          ),

          box(title = "\U0001f4c1 B-Tree Structure", status = "warning", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("Multi-way search tree"),
                  tags$p("A B-Tree node holds multiple values (up to the node order) and multiple children.
                          This allows each node to represent one disk page, reading many keys per I/O."),
                  tags$ul(
                    tags$li(tags$strong("Each leaf"), " is at the same depth (perfectly balanced)"),
                    tags$li(tags$strong("Each node"), " (except root) is at least half-full"),
                    tags$li(tags$strong("Fan-out"), ": a node with k values has k+1 children")
                  )),
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Operation"), tags$th("B-Tree I/Os"), tags$th("BST I/Os (disk)"))),
                tags$tbody(
                  tags$tr(tags$td("Search"),  tags$td("O(log\u2099 N) \u2705"), tags$td("O(log N) \u274c")),
                  tags$tr(tags$td("Insert"),  tags$td("O(log\u2099 N)"),        tags$td("O(log N)")),
                  tags$tr(tags$td("Traversal"),tags$td("O(N/B)"),              tags$td("O(N)"))
                )
              ),
              div(class = "info-box-plain",
                  HTML("<strong>\u2139 B is the branching factor</strong> (node capacity).
                        With B=1000, log\u2099(1 billion) = 3 I/Os to search any record!"))
          )
        ),

        fluidRow(
          box(title = "\u2702\ufe0f B-Tree Insertion & Splitting", status = "success", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("Insert algorithm"),
                  tags$ol(
                    tags$li("Search for the leaf where the new value belongs"),
                    tags$li("Insert the value into that leaf (maintaining sorted order)"),
                    tags$li("If the node overflows (has > max values): split it"),
                    tags$li("Push the median value up to the parent, recurse if parent overflows")
                  )),
              div(class = "framework-card",
                  tags$h5("Node splitting"),
                  tags$p("When a node has max+1 values, split into two nodes containing the lower
                          and upper halves. The median value rises to the parent.
                          This maintains both the full-but-not-overfull and equal-leaf-depth properties.")),
              div(class = "success-box",
                  HTML("<strong>\u2705 The book's implementation:</strong> Each node is a CSV file on disk.
                        <code>split_node()</code> deletes the old file and creates two new ones."))
          ),

          box(title = "\U0001f4ca B-Trees as Database Indexes", status = "danger", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("Why every database uses B-Trees"),
                  tags$p("MySQL's InnoDB, PostgreSQL, SQLite, MongoDB \u2014 all use B-Tree variants for their indexes."),
                  tags$ul(
                    tags$li("Fast point lookups: find any row in O(log\u2099 N) disk reads"),
                    tags$li("Efficient range queries: B-Tree in-order traversal reads sequentially"),
                    tags$li("Optimal for disk page size"),
                    tags$li("Self-balancing: stays efficient as data grows")
                  )),
              div(class = "tip-box",
                  HTML("<strong>\U0001f4a1 External Binary Search:</strong>
                        If we store a sorted array on disk, binary search would need O(log N) random
                        seeks. A B-Tree with branching factor B reduces this to O(log\u2099 N) \u2014
                        dramatically fewer I/Os."))
          )
        )
      ),

      tabPanel(title = tagList(icon("code"), " Code Lab"),
        code_lab_header("Chapter 7 \u2014 B-Trees",
          "File-backed B-Tree with search, insert, and node splitting. Each node is stored as a CSV file on disk, simulating the external-memory model."),
        file_pills_ui(ns, CH07_FILES),
        py_code_display(ns),
        terminal_ui(ns)
      )
    ))
  )
}

chapter7_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH07_FILES)
  })
}
