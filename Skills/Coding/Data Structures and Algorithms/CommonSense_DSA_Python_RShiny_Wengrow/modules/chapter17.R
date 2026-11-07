# modules/chapter17.R
# Chapter 17: It Doesn't Hurt to Trie

CH17_TRIE_NODE_PY <- 'class TrieNode:
    def __init__(self):
        self.children = {}'

CH17_FILES <- list(

  list(
    name        = "trie_node.py",
    description = "<strong>trie_node.py</strong> — The building block of a Trie. Each node holds a
                   <code>children</code> dictionary mapping characters to child nodes. The special
                   key <code>\"*\"</code> (mapped to <code>None</code>) marks the end of a complete word.",
    code = 'class TrieNode:
    def __init__(self):
        self.children = {}',
    demo = 'node = TrieNode()
node.children["a"] = TrieNode()   # path: ...c-a
node.children["o"] = TrieNode()   # path: ...c-o
print(f"children keys: {list(node.children.keys())}")
print(f"each child is a TrieNode: {type(list(node.children.values())[0]).__name__}")'
  ),

  list(
    name        = "trie.py",
    description = "<strong>trie.py</strong> — Complete Trie with <code>insert</code>,
                   <code>search</code>, <code>collect_all_words</code>,
                   <code>autocomplete</code>, <code>autocorrect</code>, and
                   <code>traverse</code>. All core operations are O(K) — the length
                   of the key — completely independent of the total number of words stored.",
    code = 'import trie_node

class Trie:

    def __init__(self):
        self.root = trie_node.TrieNode()

    def search(self, word):
        current_node = self.root
        for char in word:
            if current_node.children.get(char):
                current_node = current_node.children[char]
            else:
                return None
        return current_node

    def insert(self, word):
        current_node = self.root
        for char in word:
            if current_node.children.get(char):
                current_node = current_node.children[char]
            else:
                new_node = trie_node.TrieNode()
                current_node.children[char] = new_node
                current_node = new_node
        current_node.children["*"] = None

    def collect_all_words(self, words=None, node=None, word=""):
        if words is None:
            words = []
        current_node = node or self.root
        for key, child_node in current_node.children.items():
            if key == "*":
                words.append(word)
            else:
                self.collect_all_words(words, child_node, word + key)
        return words

    def autocomplete(self, prefix):
        current_node = self.search(prefix)
        if not current_node:
            return None
        return self.collect_all_words([], current_node)

    def autocorrect(self, word):
        current_node = self.root
        word_found_so_far = ""
        for char in word:
            if current_node.children.get(char):
                word_found_so_far += char
                current_node = current_node.children[char]
            else:
                return word_found_so_far + self.collect_all_words([], current_node)[0]
        return word

    def traverse(self, node=None):
        current_node = node or self.root
        for key, child_node in current_node.children.items():
            print(key)
            if key != "*":
                self.traverse(child_node)',
    demo = 'import trie_node

t = Trie()
for word in ["cat", "dog", "catnip", "catnap", "category"]:
    t.insert(word)

print("=== Search ===")
node = t.search("catnap")
print(f"search(\\"catnap\\") end-node keys: {list(node.children.keys())}")
print(f"search(\\"catnax\\") -> {t.search(\\"catnax\\")}")

print("\\n=== All words (sorted) ===")
print(sorted(t.collect_all_words()))

print("\\n=== Autocomplete \\"ca\\" ===")
print(sorted(t.autocomplete("ca")))

print("\\n=== Autocorrect ===")
print(f"  autocorrect(\\"catnar\\")    -> {t.autocorrect(\\"catnar\\")}")
print(f"  autocorrect(\\"caxasfdij\\") -> {t.autocorrect(\\"caxasfdij\\")}")
print(f"  autocorrect(\\"cat\\")       -> {t.autocorrect(\\"cat\\")}")'
  )
)

chapter17_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(17, "🌿", "It Doesn't Hurt to Trie",
      "A Trie (from re-TRIE-val) is a tree optimised for storing and searching strings. It enables autocomplete, autocorrect, and prefix lookups in O(K) time — where K is the key length — completely independent of how many words are stored.",
      c("Trie", "O(K) Search", "Autocomplete", "Autocorrect", "Prefix Tree", "End-of-Word Marker")),

    stats_row(
      list("O(K)",   "Search / Insert"),
      list("O(K)",   "Autocomplete"),
      list("O(K)",   "Autocorrect"),
      list("*",      "End-of-word marker")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory"),
          fluidRow(
            box(title = "🌿 Trie Structure", status = "info", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("How a Trie works"),
                    tags$p("A Trie is a tree where each node represents a single character.
                            Paths from root to a", tags$code("\"*\""), "node spell out complete words.
                            Nodes", tags$strong("share common prefixes"), "— the word 'cat' and 'catnip'
                            share the 'c', 'a', 't' nodes."),
                    tags$pre(style = "font-family: monospace; font-size: 11.5px;
                              color: #8B949E; background: #0D1117;
                              padding: 10px; border-radius: 6px;",
                    "root\n ├── c\n │    └── a\n │         └── t ── * (cat)\n │              └── n\n │                   ├── i─p──* (catnip)\n │                   └── a─p──* (catnap)\n └── d\n      └── o\n           └── g ── * (dog)")
                ),
                div(class = "tip-box",
                    HTML("<strong>💡 N vs K:</strong> N = total words stored. K = length of the search key.
                          Trie operations are O(K) — independent of N. A dictionary of 1,000,000 words
                          still finds a 5-letter word in exactly 5 steps."))
            ),
            box(title = "⚡ Performance vs Other Structures", status = "warning", solidHeader = TRUE, width = 6,
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Structure"), tags$th("Exact search"), tags$th("Prefix search"), tags$th("Autocomplete"))),
                  tags$tbody(
                    tags$tr(tags$td("Sorted Array"),  tags$td("O(log N)"), tags$td("O(log N) + scan"), tags$td("Possible but slow")),
                    tags$tr(tags$td("Hash Table"),    tags$td("O(1)"),     tags$td("O(N) ❌"),         tags$td("Very hard")),
                    tags$tr(tags$td(tags$strong("Trie")), tags$td(tags$strong("O(K)")), tags$td(tags$strong("O(K) ✅")), tags$td(tags$strong("Natural ✅")))
                  )
                ),
                div(class = "success-box",
                    HTML("<strong>✅ Trie's unique power:</strong> Hash tables are faster for exact lookup,
                          but tries are unbeatable for <em>prefix-based</em> operations. Autocomplete,
                          autocorrect, and spell-checkers are all trie territory.")),
                div(class = "framework-card",
                    tags$h5("Memory trade-off"),
                    tags$p("Tries use more memory than hash tables — each node is a dictionary of
                            children. But memory is cheap; the O(K) prefix operations are worth it
                            for any application that needs them."))
            )
          ),
          fluidRow(
            box(title = "🔍 Operations In Detail", status = "success", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("Insert — O(K)"),
                    tags$ol(
                      tags$li("Start at root. Walk one character at a time"),
                      tags$li("If the child node for this char exists, follow it"),
                      tags$li("If it doesn't, create a new TrieNode and link it"),
                      tags$li("After the last char, add", tags$code("\"*\": None"), "as an end marker")
                    )
                ),
                div(class = "framework-card",
                    tags$h5("Search — O(K)"),
                    tags$p("Walk the trie one character at a time. If any character isn't found in
                            the current node's children, return", tags$code("None"), ". If we exhaust
                            the word, return the final node. Check for", tags$code("\"*\""), "to confirm
                            a complete-word match vs just a prefix match.")
                )
            ),
            box(title = "💬 Autocomplete & Autocorrect", status = "danger", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("Autocomplete"),
                    tags$ol(
                      tags$li("Use", tags$code("search(prefix)"), "to reach the prefix's end node — O(K)"),
                      tags$li("From that node, DFS-collect", tags$strong("all words in the subtree below")),
                      tags$li("Return the list of completions")
                    )
                ),
                div(class = "framework-card",
                    tags$h5("Autocorrect"),
                    tags$p("Follow the typed word through the trie. The moment an unknown character
                            is encountered, branch off and autocomplete from whatever valid prefix
                            was found. Even 'caxasfdij' will be corrected to a real word starting
                            with 'ca'."),
                    div(class = "info-box-plain",
                        HTML("<strong>ℹ Real systems</strong> rank completions by word frequency, but
                              the trie mechanics are the same."))
                )
            )
          )
        ),

        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header(
            "Chapter 17 — Tries",
            "TrieNode building block, then the full Trie class: insert, search, collect_all_words, autocomplete, autocorrect, and traverse — all running in O(K)."
          ),
          file_pills_ui(ns, CH17_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter17_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    extra <- list(
      list(name = "trie_node.py", code = CH17_TRIE_NODE_PY, description = "", demo = "")
    )
    code_lab_server(input, output, session, c(CH17_FILES, extra))
  })
}
