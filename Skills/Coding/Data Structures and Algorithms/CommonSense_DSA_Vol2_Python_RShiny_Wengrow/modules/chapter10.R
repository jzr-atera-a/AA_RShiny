# modules/chapter10.R — Designing Great Hash Tables with Randomization

CH10_DIVISION_PY <- 'import random

class DivisionHasher:
    def __init__(self, array_length):
        self.array_length = array_length
        p = random.randint(1000, 10000)
        while not self.is_prime(p):
            p = random.randint(1000, 10000)
        self.prime = p

    def hash(self, key):
        return key % self.prime % self.array_length

    def is_prime(self, number):
        for _ in range(100):
            a = random.randint(1, number - 1)
            if pow(a, number - 1, number) != 1:
                return False
        return True'

CH10_FILES <- list(

  list(
    name = "first_division_hasher.py",
    description = "<strong>first_division_hasher.py</strong> — The Division Method hash function. Picks a random prime p in [10007, 99991] using Fermat's test, then hashes keys as <code>key % p % array_length</code>. The random prime prevents adversaries from crafting collision-heavy inputs.",
    code = 'import random

class DivisionHasher:
    def __init__(self, array_length):
        self.array_length = array_length

        # Choose a random prime:
        p = random.randint(10007, 99991)
        while not self.is_prime(p):
            p = random.randint(10007, 99991)
        self.prime = p

    def hash(self, key):
        return key % self.prime % self.array_length

    # Fermat Primality Test
    def is_prime(self, number):
        for _ in range(100):
            a = random.randint(1, number - 1)
            if pow(a, number - 1, number) != 1:
                return False
        return True',
    demo = 'hasher = DivisionHasher(89)
print(f"Random prime chosen: {hasher.prime}")
print(f"hash(412341439) = {hasher.hash(412341439)}")
print(f"hash(100)       = {hasher.hash(100)}")
print(f"hash(1)         = {hasher.hash(1)}")

# Show that two instances use different primes (randomized)
h2 = DivisionHasher(89)
print(f"\nSecond instance prime: {h2.prime}")
print(f"Same prime? {hasher.prime == h2.prime} (almost certainly different)")'
  ),

  list(
    name = "division_hasher.py",
    description = "<strong>division_hasher.py</strong> — Extended Division Hasher that also supports string keys. Converts strings to a numeric value (multiplicative hash over characters), then applies the division method.",
    code = 'import random

class DivisionHasher:
    def __init__(self, array_length):
        self.array_length = array_length
        p = random.randint(1000, 10000)
        while not self.is_prime(p):
            p = random.randint(1000, 10000)
        self.prime = p

    def hash(self, key):
        if isinstance(key, str):
            numeric = 1
            for char in key:
                numeric *= ord(char)
            return numeric % self.prime % self.array_length
        return key % self.prime % self.array_length

    def is_prime(self, number):
        for _ in range(100):
            a = random.randint(1, number - 1)
            if pow(a, number - 1, number) != 1:
                return False
        return True',
    demo = 'hasher = DivisionHasher(100)
print("Integer keys:")
for k in [42, 999, 12345]:
    print(f"  hash({k}) = {hasher.hash(k)}")
print("String keys:")
for s in ["hello", "world", "python", "cache"]:
    print(f"  hash({s!r}) = {hasher.hash(s)}")'
  ),

  list(
    name = "hash_table1.py",
    description = "<strong>hash_table1.py</strong> — Basic hash table (open addressing, no collision handling). Insert overwrites any existing value at the hash location. Demonstrates the core hash table structure.",
    code = 'import division_hasher

class HashTable:
    def __init__(self, array_length):
        self.array        = [None] * array_length
        self.array_length = array_length
        self.hasher       = division_hasher.DivisionHasher(array_length)

    def insert(self, key, value):
        hashcode         = self.hasher.hash(key)
        self.array[hashcode] = value

    def search(self, key):
        hashcode = self.hasher.hash(key)
        return self.array[hashcode]',
    demo = 'import division_hasher

ht = HashTable(89)
ht.insert(757667547, "hello")
ht.insert(100,       "world")
print(f"search(757667547) = {ht.search(757667547)}")
print(f"search(100)       = {ht.search(100)}")
print(f"search(999)       = {ht.search(999)}")'
  ),

  list(
    name = "hash_table2.py",
    description = "<strong>hash_table2.py</strong> — Hash table with separate chaining for collision handling. Each slot holds a list of [key, value] pairs. Insert updates existing key or appends. Supports delete. This is how Python's dict works under the hood.",
    code = 'import division_hasher

class HashTable:
    def __init__(self, array_length):
        self.array_length = array_length
        self.array        = [[] for _ in range(self.array_length)]
        self.hasher       = division_hasher.DivisionHasher(self.array_length)

    def insert(self, key, value):
        hashcode = self.hasher.hash(key)
        for pair in self.array[hashcode]:
            if pair[0] == key:
                pair[1] = value
                return
        self.array[hashcode].append([key, value])

    def search(self, key):
        hashcode = self.hasher.hash(key)
        for pair in self.array[hashcode]:
            if pair[0] == key:
                return pair[1]
        return None

    def delete(self, key):
        hashcode = self.hasher.hash(key)
        for i, pair in enumerate(self.array[hashcode]):
            if pair[0] == key:
                del self.array[hashcode][i]
                return',
    demo = 'import division_hasher

ht = HashTable(89)
ht.insert(42, "apple")
ht.insert(42, "updated apple")   # update existing
ht.insert(99, "banana")
print(f"search(42) = {ht.search(42)}")
print(f"search(99) = {ht.search(99)}")
ht.delete(42)
print(f"search(42) after delete = {ht.search(42)}")'
  ),

  list(
    name = "solution_2.py",
    description = "<strong>solution_2.py</strong> — Extended Division Hasher that handles both integer and string keys using Horner's method for strings: builds the hash incrementally as <code>(result * base + char_code) % prime</code>, avoiding huge intermediate numbers.",
    code = 'import random

class DivisionHasher:
    def __init__(self, array_length):
        self.array_length = array_length
        p = random.randint(1000, 10000)
        while not self.is_prime(p):
            p = random.randint(1000, 10000)
        self.prime = p

    def hash(self, key):
        if isinstance(key, str):
            numeric = 1
            for char in key:
                numeric *= ord(char)
            return numeric % self.prime % self.array_length
        return key % self.prime % self.array_length

    def is_prime(self, number):
        for _ in range(100):
            a = random.randint(1, number - 1)
            if pow(a, number - 1, number) != 1:
                return False
        return True',
    demo = 'hasher = DivisionHasher(89)
print(f"hash(\"abc\")  = {hasher.hash(\"abc\")}")
print(f"hash(\"cba\")  = {hasher.hash(\"cba\")}")
print(f"hash(5000)  = {hasher.hash(5000)}")'
  )
)

chapter10_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(10, "#\ufe0f\u20e3", "Designing Great Hash Tables with Randomization",
      "A hash table is only as good as its hash function. This chapter shows how randomization \u2014 choosing a random prime at construction time \u2014 makes hash tables resistant to adversarial inputs that would cause O(N) worst-case performance on deterministic hash functions.",
      c("Division Method", "Scalable Hash Functions", "Randomized Hashing", "Separate Chaining", "Fermat Primes")),

    stats_row(
      list("O(1)", "Avg insert/search"),
      list("O(N)", "Worst case (bad hash)"),
      list("O(1)", "Avg with random hash"),
      list("2",    "Hash formula steps")
    ),

    fluidRow(tabBox(width = 12, id = ns("tabs"),

      tabPanel(title = tagList(icon("book"), " Theory"),
        fluidRow(
          box(title = "#\ufe0f\u20e3 Hash Functions: A Quick Review", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("The Hash Function's Job"),
                  tags$p("Map any key to an integer index in [0, array_length-1]. Good hash functions:"),
                  tags$ul(
                    tags$li("Distribute keys", tags$strong("uniformly"), "across all buckets"),
                    tags$li("Are", tags$strong("fast"), "to compute"),
                    tags$li("Are", tags$strong("deterministic"), "(same key \u2192 same hash)")
                  )),
              div(class = "warn-box",
                  HTML("<strong>\u26a0 The adversarial problem:</strong> If the hash function is public and
                        deterministic, an attacker can craft inputs that all hash to the same bucket,
                        degrading performance from O(1) to O(N). This is a real attack on web servers
                        (Hash DoS attacks)."))),
          box(title = "\U0001f3b2 The Division Method", status = "warning", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("Formula: key % prime % array_length"),
                  tags$p("Using a prime as an intermediate modulus distributes keys more uniformly
                          than a direct modulo. Why two steps?"),
                  tags$ul(
                    tags$li(tags$code("key % array_length"), " alone clusters keys that share a factor with array_length"),
                    tags$li(tags$code("key % prime"), " first breaks those patterns"),
                    tags$li(tags$code("... % array_length"), " then maps to the valid index range")
                  )),
              div(class = "success-box",
                  HTML("<strong>\u2705 Randomized:</strong> Pick the prime randomly at construction time.
                        An adversary who doesn't know your prime can't craft collision inputs.
                        Use Fermat's test to find the prime quickly.")))
        ),
        fluidRow(
          box(title = "\U0001f517 Scalable Hash Functions", status = "success", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("Hashing strings"),
                  tags$p("Strings need to be converted to numbers first. Naive approach: multiply all
                          character codes together. Problem: multiplication of many large numbers
                          produces astronomically large intermediates."),
                  tags$p("Better: Horner's method \u2014 process one character at a time, reducing modulo
                          prime at each step:"),
                  tags$p(tags$code("result = (result * base + char_code) % prime"))),
              div(class = "framework-card",
                  tags$h5("Anagram collision problem"),
                  tags$p("Multiplicative hash: 'abc' and 'cba' hash to the same value (multiplication is commutative)."),
                  tags$p("Polynomial hash (solution_2): different orderings get different hashes because the
                          base exponents are positional."))),
          box(title = "\U0001f9f1 Collision Handling", status = "danger", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("Separate Chaining (hash_table2.py)"),
                  tags$p("Each bucket holds a list of (key, value) pairs. Multiple keys can share a bucket.
                          Lookup scans the chain linearly."),
                  tags$p("With a good hash: average chain length = load factor \u03b1 = N/M"),
                  tags$p("Average lookup: O(1 + \u03b1)")),
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Approach"), tags$th("Pro"), tags$th("Con"))),
                tags$tbody(
                  tags$tr(tags$td("Separate chaining"), tags$td("Simple, handles high load"), tags$td("Extra pointer overhead")),
                  tags$tr(tags$td("Open addressing"),   tags$td("Cache-friendly"), tags$td("Complex deletion, load sensitive"))
                )
              ))
        )
      ),

      tabPanel(title = tagList(icon("code"), " Code Lab"),
        code_lab_header("Chapter 10 \u2014 Hash Tables with Randomization",
          "Division method hasher (integer and string keys), basic hash table (open addressing), chaining hash table with delete, and the polynomial Horner's method hasher."),
        file_pills_ui(ns, CH10_FILES),
        py_code_display(ns),
        terminal_ui(ns)
      )
    ))
  )
}

chapter10_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    extra <- list(
      list(name = "division_hasher.py", code = CH10_DIVISION_PY, description = "", demo = "")
    )
    code_lab_server(input, output, session, c(CH10_FILES, extra))
  })
}
