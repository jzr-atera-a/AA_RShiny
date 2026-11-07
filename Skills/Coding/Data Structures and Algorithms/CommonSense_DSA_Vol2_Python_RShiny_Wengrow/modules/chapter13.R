# modules/chapter13.R — Cultivating a Bloom Filter

CH13_BV_PY <- 'class BitVector:
    def __init__(self, range_of_bits):
        integers_length = range_of_bits // 32
        if range_of_bits % 32 != 0:
            integers_length += 1
        self.integers = [0] * integers_length

    def read_bit(self, index):
        integer_index = index // 32
        bit_index     = index % 32
        mask = 1 << bit_index
        return (mask & self.integers[integer_index]) != 0

    def set_bit(self, index):
        integer_index = index // 32
        bit_index     = index % 32
        mask = 1 << bit_index
        self.integers[integer_index] |= mask

    def clear_bit(self, index):
        integer_index = index // 32
        bit_index     = index % 32
        mask = ~(1 << bit_index)
        self.integers[integer_index] &= mask

    def toggle_bit(self, index):
        integer_index = index // 32
        bit_index     = index % 32
        mask = 1 << bit_index
        self.integers[integer_index] ^= mask

    def values(self):
        result = []
        offset = 0
        for integer in self.integers:
            val = integer
            for index in range(32):
                if val & 1 != 0:
                    result.append(offset + index)
                val >>= 1
            offset += 32
        return result'

CH13_DIV_PY <- 'import random

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
                numeric = numeric * 53 + ord(char)
            return numeric % self.prime % self.array_length
        return key % self.prime % self.array_length

    def is_prime(self, number):
        for _ in range(100):
            a = random.randint(1, number - 1)
            if pow(a, number - 1, number) != 1:
                return False
        return True'

CH13_FILES <- list(

  list(
    name = "bloom_filter.py",
    description = "<strong>bloom_filter.py</strong> — Production Bloom Filter. Constructor takes n (expected items) and f (desired false positive rate) and automatically computes the optimal bit vector size m and number of hash functions k. Uses k independent randomized DivisionHashers on a single BitVector.",
    code = 'import bit_vector
import division_hasher
import math

class BloomFilter:
    def __init__(self, n, f):
        # Optimal m and k from desired false positive rate f and expected items n
        self.m = int(-math.log(f) * n / (math.log(2)**2))
        self.k = int(self.m * math.log(2) / n)

        self.hash_functions       = []
        self.hash_function_primes = {}

        for _ in range(self.k):
            hasher = division_hasher.DivisionHasher(self.m)
            # Ensure each hash function uses a distinct prime
            while hasher.prime in self.hash_function_primes:
                hasher = division_hasher.DivisionHasher(self.m)
            self.hash_function_primes[hasher.prime] = True
            self.hash_functions.append(hasher)

        self.bv = bit_vector.BitVector(self.m)

    def insert(self, value):
        for hash_function in self.hash_functions:
            hashcode = hash_function.hash(value)
            self.bv.set_bit(hashcode)

    def read(self, value):
        for hash_function in self.hash_functions:
            hashcode = hash_function.hash(value)
            if not self.bv.read_bit(hashcode):
                return False    # Definitely NOT in set
        return True             # Probably in set (may be false positive)',
    demo = 'import bit_vector, division_hasher, math, sys

# Build a Bloom filter for 100 items with 5% false positive rate
bf = BloomFilter(100, 0.05)
print(f"n=100 items, f=5% false positive rate:")
print(f"  m (bits): {bf.m}")
print(f"  k (hash functions): {bf.k}")
print(f"  Memory: {sys.getsizeof(bf.bv.integers)} bytes")
print(f"  vs dict: {sys.getsizeof({i:True for i in range(100)})} bytes")

# Insert and query
for word in ["apple", "banana", "carrot", "date", "elderberry"]:
    bf.insert(word)

print("\nInserted: apple, banana, carrot, date, elderberry")
for word in ["apple", "banana", "fig", "grape", "carrot", "xyz"]:
    result = bf.read(word)
    tag = "(inserted)" if word in ["apple","banana","carrot","date","elderberry"] else "(NOT inserted)"
    print(f"  read({word!r:12}) = {result}  {tag}")'
  ),

  list(
    name = "alt_bloom_filter.py",
    description = "<strong>alt_bloom_filter.py</strong> — Alternative Bloom Filter constructor: takes n (expected items) and m (desired bit vector size directly) instead of a false positive rate. Computes the optimal k and the resulting false positive rate f. Useful when you have a fixed memory budget.",
    code = 'import bit_vector
import division_hasher
import math

class BloomFilter:
    def __init__(self, n, m):
        self.m = m
        self.k = int(m * math.log(2) / n)
        # Compute resulting false positive rate
        self.f = (1 - math.e**((-self.k * n) / m))**self.k

        self.hash_functions       = []
        self.hash_function_primes = {}

        for _ in range(self.k):
            hasher = division_hasher.DivisionHasher(self.m)
            while hasher.prime in self.hash_function_primes:
                hasher = division_hasher.DivisionHasher(self.m)
            self.hash_function_primes[hasher.prime] = True
            self.hash_functions.append(hasher)

        self.bv = bit_vector.BitVector(self.m)

    def insert(self, value):
        for hash_function in self.hash_functions:
            hashcode = hash_function.hash(value)
            self.bv.set_bit(hashcode)

    def read(self, value):
        for hash_function in self.hash_functions:
            hashcode = hash_function.hash(value)
            if not self.bv.read_bit(hashcode):
                return False
        return True',
    demo = 'import bit_vector, division_hasher, math

# Use a fixed 623-bit vector for 100 items
bf = BloomFilter(100, 623)
print(f"n=100, m=623 bits:")
print(f"  k (hash functions): {bf.k}")
print(f"  f (false positive rate): {bf.f:.4f} ({bf.f*100:.2f}%)")

bf.insert("apple")
bf.insert("carrot")
print(f"\nread(apple):   {bf.read(\"apple\")}")
print(f"read(carrot):  {bf.read(\"carrot\")}")
print(f"read(banana):  {bf.read(\"banana\")}")
print(f"read(xyz):     {bf.read(\"xyz\")}")'
  ),

  list(
    name = "find_duplicates_bloom_filter.py",
    description = "<strong>find_duplicates_bloom_filter.py</strong> — Duplicate detection using a Bloom filter instead of a hash set. Uses far less memory than a dict for large datasets, at the cost of rare false positives (may report a duplicate that doesn't exist, but never misses a real duplicate).",
    code = 'import bloom_filter

def find_duplicates(array):
    seen = bloom_filter.BloomFilter(len(array), 0.01)

    for item in array:
        if seen.read(item):
            return True    # Probably a duplicate (may be false positive)
        seen.insert(item)

    return False',
    demo = 'import bloom_filter, sys

# Array with a duplicate
arr1 = list(range(100)) + [88]
# Array without duplicates
arr2 = list(range(100))

print(f"find_duplicates (with 88 twice):    {find_duplicates(arr1)}")
print(f"find_duplicates (no duplicates):    {find_duplicates(arr2)}")

# Space comparison
bf_mem  = sys.getsizeof(bloom_filter.BloomFilter(100, 0.01).bv.integers)
set_mem = sys.getsizeof({i: True for i in range(100)})
print(f"\nBloom filter memory: {bf_mem} bytes")
print(f"Dict set memory:     {set_mem} bytes")
print(f"Savings: {(1 - bf_mem/set_mem)*100:.0f}%")'
  )
)

chapter13_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(13, "\U0001f33c", "Cultivating a Bloom Filter",
      "A Bloom filter is a probabilistic space-efficient set. It can tell you with certainty when something is NOT in the set, but only probably when it IS. By using k independent hash functions on a single bit vector, it achieves dramatic space savings \u2014 ideal for massive datasets like URL blocklists, spell checkers, and database query optimization.",
      c("Bloom Filter", "False Positives", "k Hash Functions", "Optimal m & k", "Space Efficiency", "Probabilistic Set")),

    stats_row(
      list("O(k)",    "Insert / Lookup"),
      list("Never",   "False Negatives"),
      list("Tunable", "False Positive Rate"),
      list("10x+",    "Space vs hash set")
    ),

    fluidRow(tabBox(width = 12, id = ns("tabs"),

      tabPanel(title = tagList(icon("book"), " Theory"),
        fluidRow(
          box(title = "\U0001f33c What is a Bloom Filter?", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("Structure"),
                  tags$p("A Bloom filter consists of:"),
                  tags$ul(
                    tags$li("A", tags$strong("bit vector"), "of m bits (all initially 0)"),
                    tags$li("k", tags$strong("independent hash functions"), ", each mapping a value to [0, m-1]")
                  )),
              div(class = "framework-card",
                  tags$h5("Insert(value)"),
                  tags$p("Compute all k hash codes for value. Set those k bits in the bit vector to 1.")),
              div(class = "framework-card",
                  tags$h5("Read(value)"),
                  tags$p("Compute all k hash codes. Check if", tags$strong("all"), "those bits are 1."),
                  tags$ul(
                    tags$li("If", tags$strong("any bit is 0"), ": value is", tags$em("definitely NOT"), "in the set"),
                    tags$li("If", tags$strong("all bits are 1"), ": value is", tags$em("probably"), "in the set (may be false positive)")
                  )),
              div(class = "warn-box",
                  HTML("<strong>\u26a0 Bloom filters cannot delete:</strong> Clearing bits on delete
                        could break other values that share those bits.
                        Use Counting Bloom filters if deletion is needed."))),

          box(title = "\U0001f522 Optimal Parameters", status = "warning", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("Given n (expected items) and f (target false positive rate):"),
                  tags$p(tags$strong("Optimal m (bit vector size):")),
                  tags$p(tags$code("m = -n * ln(f) / (ln 2)^2")),
                  tags$p(tags$strong("Optimal k (number of hash functions):")),
                  tags$p(tags$code("k = (m/n) * ln 2")),
                  tags$p("Using these formulas, bloom_filter.py automatically computes the right parameters.")),
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("n"), tags$th("f"), tags$th("m (bits)"), tags$th("k"))),
                tags$tbody(
                  tags$tr(tags$td("100"),     tags$td("5%"),   tags$td("623"),       tags$td("4")),
                  tags$tr(tags$td("100"),     tags$td("1%"),   tags$td("959"),       tags$td("7")),
                  tags$tr(tags$td("1,000"),   tags$td("1%"),   tags$td("9,585"),     tags$td("7")),
                  tags$tr(tags$td("1,000,000"),tags$td("1%"),  tags$td("9,585,058"), tags$td("7"))
                )
              ),
              div(class = "success-box",
                  HTML("<strong>\u2705 Key insight:</strong> For 1% false positive rate, we need only
                        ~9.6 bits per element regardless of the size of elements being stored.
                        A hash set of strings uses hundreds of bytes per element.")))
        ),
        fluidRow(
          box(title = "\U0001f4ca Real-World Applications", status = "success", solidHeader = TRUE, width = 12,
              fluidRow(
                column(4,
                  div(class = "framework-card",
                      tags$h5("Web Browsers"),
                      tags$p("Google Chrome's Safe Browsing uses a Bloom filter to check URLs against a
                              list of millions of malicious sites locally, without storing the full list.")),
                  div(class = "framework-card",
                      tags$h5("Databases"),
                      tags$p("PostgreSQL and Cassandra use Bloom filters to avoid disk reads for keys that
                              don't exist. Before checking disk, check the filter \u2014 if it says 'no', skip the I/O."))),
                column(4,
                  div(class = "framework-card",
                      tags$h5("Spell Checkers"),
                      tags$p("A dictionary of 100,000 words needs ~1MB in a Bloom filter vs ~5MB as a
                              hash set. False positives (accepting misspelled words) are rare and acceptable.")),
                  div(class = "framework-card",
                      tags$h5("Distributed Systems"),
                      tags$p("Apache Hadoop uses Bloom filters to reduce network traffic: before sending a
                              data block to a node, check if that node's filter says it needs it."))),
                column(4,
                  div(class = "tip-box",
                      HTML("<strong>\U0001f4a1 The one-sided error guarantee:</strong><br>
                            A Bloom filter NEVER produces false negatives.<br>
                            If it says NO, the item is definitely absent.<br>
                            If it says YES, it is probably present.<br><br>
                            This is perfect for skip-list optimisations:<br>
                            avoid expensive work (disk read, network call) only when the filter says the work is needed.")),
                  div(class = "info-box-plain",
                      HTML("<strong>\u2139 Counting Bloom filter:</strong>
                            Replace each bit with a small counter.
                            Increment on insert, decrement on delete.
                            Supports deletion at the cost of more space.")))
              )
          )
        )
      ),

      tabPanel(title = tagList(icon("code"), " Code Lab"),
        code_lab_header("Chapter 13 \u2014 Bloom Filters",
          "Bloom filter with optimal parameter computation (n, f \u2192 m, k), alternative fixed-size constructor (n, m \u2192 k, f), and duplicate detection using a Bloom filter instead of a hash set."),
        file_pills_ui(ns, CH13_FILES),
        py_code_display(ns),
        terminal_ui(ns)
      )
    ))
  )
}

chapter13_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    extra <- list(
      list(name = "bit_vector.py",      code = CH13_BV_PY,  description = "", demo = ""),
      list(name = "division_hasher.py", code = CH13_DIV_PY, description = "", demo = "")
    )
    code_lab_server(input, output, session, c(CH13_FILES, extra))
  })
}
