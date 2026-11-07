# modules/chapter09.R  — Crafting Elegant Code with Stacks & Queues

CH09_FILES <- list(
  list(
    name = "stack.py",
    description = "<strong>stack.py</strong> — Stack (LIFO) backed by a Python list. push, pop, and read — all O(1).",
    code = 'class Stack:\n    def __init__(self):\n        self.data = []\n\n    def push(self, element):\n        self.data.append(element)\n\n    def pop(self):\n        if len(self.data) > 0:\n            return self.data.pop()\n        else:\n            return None\n\n    def read(self):\n        if len(self.data) > 0:\n            return self.data[-1]\n        else:\n            return None',
    demo = 'stack = Stack()\nstack.push("a")\nstack.push("b")\nstack.push("c")\nprint(f"After pushing a,b,c:")\nprint(f"  read()  = {stack.read()}")\nprint(f"  pop()   = {stack.pop()}")\nprint(f"  read()  = {stack.read()}")\nprint(f"  pop()   = {stack.pop()}")\nprint(f"  pop()   = {stack.pop()}")\nprint(f"  pop()   = {stack.pop()}  (empty)")'
  ),
  list(
    name = "queue.py",
    description = "<strong>queue.py</strong> — Queue (FIFO) backed by a Python list. enqueue, dequeue, and read. Note: dequeue uses pop(0) which is O(N) — a linked list implementation would be O(1).",
    code = 'class Queue:\n    def __init__(self):\n        self.data = []\n\n    def enqueue(self, element):\n        self.data.append(element)\n\n    def dequeue(self):\n        if len(self.data) > 0:\n            return self.data.pop(0)\n        else:\n            return None\n\n    def read(self):\n        if len(self.data) > 0:\n            return self.data[0]\n        else:\n            return None',
    demo = 'q = Queue()\nq.enqueue("a")\nq.enqueue("b")\nq.enqueue("c")\nprint("After enqueuing a,b,c:")\nprint(f"  read()    = {q.read()}")\nprint(f"  dequeue() = {q.dequeue()}")\nprint(f"  read()    = {q.read()}")\nprint(f"  dequeue() = {q.dequeue()}")\nprint(f"  dequeue() = {q.dequeue()}")\nprint(f"  dequeue() = {q.dequeue()}  (empty)")'
  ),
  list(
    name = "linter.py",
    description = "<strong>linter.py</strong> — JavaScript brace linter using a Stack. Pushes opening braces, pops and validates on closing braces. O(N).",
    code = 'import stack\n\nclass Linter:\n    def __init__(self):\n        self.stack = stack.Stack()\n\n    def lint(self, text):\n        while self.stack.read():\n            self.stack.pop()\n        matching_braces = {"(": ")", "[": "]", "{": "}"}\n        for char in text:\n            if char in matching_braces.keys():\n                self.stack.push(char)\n            elif char in matching_braces.values():\n                if not self.stack.read():\n                    return char + " does not have opening brace"\n                else:\n                    popped_opening_brace = self.stack.pop()\n                    if char != matching_braces.get(popped_opening_brace):\n                        return char + " has mismatched opening brace"\n        if self.stack.read():\n            return self.stack.read() + " does not have closing brace"\n        return True',
    demo = 'linter = Linter()\nprint(f"(var x = 2;       -> {linter.lint(\"(var x = 2;\")}")\nprint(f"var x = 2;)       -> {linter.lint(\"var x = 2;)\")}")\nprint(f"(var x = [1, 2, 3)]; -> {linter.lint(\"(var x = [1, 2, 3)];\")} ")\nprint(f"(var x = [1, 2, 3]) -> {linter.lint(\"(var x = [1, 2, 3])\")}")'
  ),
  list(
    name = "print_manager.py",
    description = "<strong>print_manager.py</strong> — Print queue simulation using the Queue class. Documents are printed in FIFO order.",
    code = 'import queue\n\nclass PrintManager:\n    def __init__(self):\n        self.queue = queue.Queue()\n\n    def queue_print_job(self, document):\n        self.queue.enqueue(document)\n\n    def run(self):\n        while self.queue.read():\n            self.print_document(self.queue.dequeue())\n\n    def print_document(self, document):\n        print(document)',
    demo = 'pm = PrintManager()\npm.queue_print_job("First Document")\npm.queue_print_job("Second Document")\npm.queue_print_job("Third Document")\nprint("Printing in FIFO order:")\npm.run()'
  ),
  list(
    name = "solution.py",
    description = "<strong>solution.py</strong> — Reverses a string using a Stack. Push each character, then pop them all into a new string. O(N).",
    code = 'import stack as stack_module\n\ndef reverse(string):\n    stack = stack_module.Stack()\n    new_string = ""\n    for char in string:\n        stack.push(char)\n    while stack.read():\n        new_string += stack.pop()\n    return new_string',
    demo = 'print(f"reverse(\\"abcde\\") = {reverse(\"abcde\")}")\nprint(f"reverse(\\"hello\\") = {reverse(\"hello\")}")\nprint(f"reverse(\\"a\\")     = {reverse(\"a\")}")\nprint(f"reverse(\\"\\")      = {reverse(\"\")}")'
  )
)

chapter9_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(9, "📚", "Crafting Elegant Code with Stacks & Queues",
      "Stacks and Queues are abstract data types built on top of arrays or linked lists. They restrict how data is accessed — and this constraint is exactly what makes them so powerful.",
      c("Stack (LIFO)", "Queue (FIFO)", "Call Stack", "Linter", "Print Manager")),
    stats_row(list("O(1)","Push / Pop"), list("O(1)","Enqueue"), list("O(N)","Dequeue (array)"),
              list("LIFO/FIFO","Access Pattern")),
    fluidRow(tabBox(width = 12, id = ns("tabs"),
      tabPanel(title = tagList(icon("book"), " Theory"),
        fluidRow(
          box(title = "📚 Stack — Last In, First Out", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card", tags$h5("LIFO Principle"),
                  tags$p("A stack only allows access to the top element. Think of a pile of plates — you can only add or remove from the top."),
                  tags$ul(tags$li(tags$code("push(x)"), " — add x to the top"),
                          tags$li(tags$code("pop()"), " — remove and return the top"),
                          tags$li(tags$code("read()"), " — peek at the top without removing"))),
              div(class = "framework-card", tags$h5("Real-world use cases"),
                  tags$ul(tags$li("Call stack (function call tracking)"),
                          tags$li("Undo/redo functionality"),
                          tags$li("Brace matching / linting"),
                          tags$li("Backtracking algorithms")))
          ),
          box(title = "🚌 Queue — First In, First Out", status = "warning", solidHeader = TRUE, width = 6,
              div(class = "framework-card", tags$h5("FIFO Principle"),
                  tags$p("A queue only allows adding to the back and removing from the front. Like a checkout line — first in, first served."),
                  tags$ul(tags$li(tags$code("enqueue(x)"), " — add x to the back"),
                          tags$li(tags$code("dequeue()"), " — remove and return the front"),
                          tags$li(tags$code("read()"), " — peek at the front"))),
              div(class = "framework-card", tags$h5("Real-world use cases"),
                  tags$ul(tags$li("Print spoolers"),
                          tags$li("Message queues"),
                          tags$li("BFS graph traversal (Ch 18)"),
                          tags$li("Task scheduling")))
          )
        ),
        fluidRow(
          box(title = "🔧 Stack as a Problem-Solving Tool", status = "success", solidHeader = TRUE, width = 12,
              fluidRow(
                column(6, div(class = "framework-card", tags$h5("Linter — Brace Matching"),
                              tags$p("Push opening braces. When a closing brace appears, pop and check it matches. If the stack is non-empty at the end, there's an unclosed brace."),
                              div(class = "success-box", HTML("<strong>✅ O(N)</strong> — single pass through the text.")))),
                column(6, div(class = "framework-card", tags$h5("String Reversal"),
                              tags$p("Push each character. Then pop them all into a new string — LIFO ordering naturally produces the reverse."),
                              div(class = "info-box-plain", HTML("<strong>ℹ Pattern:</strong> Any time order must be reversed, a stack is your tool."))))
              )
          )
        )
      ),
      tabPanel(title = tagList(icon("code"), " Code Lab"),
        code_lab_header("Chapter 9 Code Files", "Stack and Queue classes, JavaScript linter, print manager, and string reversal using a stack."),
        file_pills_ui(ns, CH09_FILES),
        py_code_display(ns),
        terminal_ui(ns)
      )
    ))
  )
}

chapter9_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH09_FILES)
  })
}
