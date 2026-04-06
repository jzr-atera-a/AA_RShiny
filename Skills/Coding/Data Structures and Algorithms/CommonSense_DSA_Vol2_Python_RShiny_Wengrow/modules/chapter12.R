# modules/chapter12.R — Saving Space with Bit Vectors

CH12_BV_PY <- 'class BitVector:
    def __init__(self, range_of_bits):
        self.range_of_bits = range_of_bits
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
        for number in range(self.range_of_bits):
            if self.read_bit(number):
                result.append(number)
        return result

    def union(self, other):
        bv = BitVector(self.range_of_bits)
        for i in range(len(self.integers)):
            bv.integers[i] = self.integers[i] | other.integers[i]
        return bv

    def intersection(self, other):
        bv = BitVector(self.range_of_bits)
        for i in range(len(self.integers)):
            bv.integers[i] = self.integers[i] & other.integers[i]
        return bv

    def difference(self, other):
        bv = BitVector(self.range_of_bits)
        for i in range(len(self.integers)):
            bv.integers[i] = self.integers[i] & ~other.integers[i]
        return bv'

CH12_FILES <- list(

  list(
    name = "bit_vector.py",
    description = "<strong>bit_vector.py</strong> — Full BitVector implementation. Packs N bits into N/32 integers, using bitwise operations (AND, OR, XOR, shift) to read, set, clear, and toggle individual bits. Supports set operations: union (OR), intersection (AND), difference (AND NOT). Uses 32x less memory than a boolean array.",
    code = 'class BitVector:
    def __init__(self, range_of_bits):
        self.range_of_bits = range_of_bits
        integers_length    = range_of_bits // 32
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
        for number in range(self.range_of_bits):
            if self.read_bit(number):
                result.append(number)
        return result

    def union(self, other):
        bv = BitVector(self.range_of_bits)
        for i in range(len(self.integers)):
            bv.integers[i] = self.integers[i] | other.integers[i]
        return bv

    def intersection(self, other):
        bv = BitVector(self.range_of_bits)
        for i in range(len(self.integers)):
            bv.integers[i] = self.integers[i] & other.integers[i]
        return bv

    def difference(self, other):
        bv = BitVector(self.range_of_bits)
        for i in range(len(self.integers)):
            bv.integers[i] = self.integers[i] & ~other.integers[i]
        return bv',
    demo = 'import sys

bv = BitVector(1024)
for idx in [20, 31, 100, 191, 312, 613, 1002]:
    bv.set_bit(idx)

print(f"set bits: {bv.values()}")
print(f"Memory: {sys.getsizeof(bv.integers)} bytes for 1024 bits")
print(f"vs boolean list: {sys.getsizeof([False]*1024)} bytes")
print(f"Ratio: {sys.getsizeof([False]*1024) / sys.getsizeof(bv.integers):.1f}x savings")

bv2 = BitVector(1024)
for idx in [10, 31, 120, 191, 312, 1003]:
    bv2.set_bit(idx)

print(f"\nUnion:        {bv.union(bv2).values()}")
print(f"Intersection: {bv.intersection(bv2).values()}")
print(f"Difference:   {bv.difference(bv2).values()}")'
  ),

  list(
    name = "find_duplicates.py",
    description = "<strong>find_duplicates.py</strong> — Duplicate detection using a Python dict (hash table). O(N) time, O(N) space. Baseline for comparison with boolean array and bit vector approaches.",
    code = 'def has_duplicates(array):
    seen = {}
    for item in array:
        if seen.get(item):
            return True
        seen[item] = True
    return False',
    demo = 'import sys
arr1 = list(range(1000))
arr2 = list(range(999)) + [42]
print(f"No duplicates:    {has_duplicates(arr1)}")
print(f"Has duplicate 42: {has_duplicates(arr2)}")
seen = {}
for i in range(1000): seen[i] = True
print(f"Dict space for 1000 items: {sys.getsizeof(seen)} bytes")'
  ),

  list(
    name = "find_duplicates_boolean.py",
    description = "<strong>find_duplicates_boolean.py</strong> — Duplicate detection using a boolean array (list of False/True). O(N) time, O(range) space. Faster lookup than a dict (no hashing), but requires knowing the value range in advance.",
    code = 'def has_duplicates(array):
    seen = [False] * 1000
    for item in array:
        if seen[item]:
            return True
        seen[item] = True
    return False',
    demo = 'import sys
arr1 = list(range(999))
arr2 = list(range(999)) + [42]
print(f"No duplicates:    {has_duplicates(arr1)}")
print(f"Has duplicate 42: {has_duplicates(arr2)}")
print(f"Boolean array space: {sys.getsizeof([False]*1000)} bytes")'
  ),

  list(
    name = "find_duplicates_bit_vector.py",
    description = "<strong>find_duplicates_bit_vector.py</strong> — Duplicate detection using a BitVector. Same logic as the boolean version but 32x smaller: 1024 bits packed into 32 integers instead of 1024 separate Python booleans.",
    code = 'import bit_vector

def has_duplicates(array):
    seen = bit_vector.BitVector(1024)
    for item in array:
        if seen.read_bit(item):
            return True
        seen.set_bit(item)
    return False',
    demo = 'import bit_vector, sys
arr1 = list(range(999))
arr2 = list(range(999)) + [42]
print(f"No duplicates:    {has_duplicates(arr1)}")
print(f"Has duplicate 42: {has_duplicates(arr2)}")
bv = bit_vector.BitVector(1024)
print(f"BitVector space: {sys.getsizeof(bv.integers)} bytes vs {sys.getsizeof([False]*1024)} bytes (boolean)")'
  ),

  list(
    name = "counting_sort.py",
    description = "<strong>counting_sort.py</strong> — Counting sort using a dict. Marks which values exist, then reads them back in ascending order. O(N + range) time, O(range) space. Beats comparison-sort's O(N log N) for small integer ranges.",
    code = 'def counting_sort(array):
    sorted_array = []
    seen = {}
    for value in array:
        seen[value] = True
    for number in range(10000):
        if seen.get(number):
            sorted_array.append(number)
    return sorted_array',
    demo = 'import random, time
arr = random.sample(range(1000), 500)
result = counting_sort(arr)
print(f"Sorted {len(arr)} items: {result[:10]}...")
print(f"Correctly sorted: {result == sorted(arr)}")'
  ),

  list(
    name = "counting_sort_boolean.py",
    description = "<strong>counting_sort_boolean.py</strong> — Counting sort using a boolean list. Same algorithm as hash-based version but uses a fixed-size boolean array for O(1) lookup. More memory-efficient than a dict for dense integer sets.",
    code = 'def counting_sort(array):
    seen         = [False] * 10000
    sorted_array = []
    for value in array:
        seen[value] = True
    for number in range(10000):
        if seen[number]:
            sorted_array.append(number)
    return sorted_array',
    demo = 'arr = [1000, 235, 9, 1, 666]
print(f"Input:  {arr}")
print(f"Sorted: {counting_sort(arr)}")'
  ),

  list(
    name = "counting_sort_bit_vector.py",
    description = "<strong>counting_sort_bit_vector.py</strong> — Counting sort using a BitVector. Same output as boolean version, but the seen-set uses 32x less memory. Best of all worlds: O(N) time, minimal space.",
    code = 'import bit_vector

def counting_sort(array):
    seen = bit_vector.BitVector(10000)
    for value in array:
        seen.set_bit(value)
    return seen.values()',
    demo = 'arr = [1000, 235, 9, 1, 666]
print(f"Input:  {arr}")
print(f"Sorted: {counting_sort(arr)}")'
  ),

  list(
    name = "add_binary.py",
    description = "<strong>add_binary.py</strong> — Add two integers using only bitwise operations \u2014 no + operator. XOR gives the sum-without-carry, AND+shift gives the carry. Repeat until carry is zero.",
    code = 'def add(first_number, second_number):
    while second_number != 0:
        sum_without_carry = first_number  ^ second_number
        carry_number      = (first_number & second_number) << 1
        first_number      = sum_without_carry
        second_number     = carry_number
    return first_number',
    demo = 'tests = [(13, 20, 33), (0, 1, 1), (1, 0, 1), (255, 1, 256), (100, 200, 300)]
for a, b, expected in tests:
    result = add(a, b)
    status = "OK" if result == expected else "FAIL"
    print(f"  [{status}] add({a}, {b}) = {result}  (binary: {bin(a)} + {bin(b)} = {bin(result)})")'
  ),

  list(
    name = "solution_4.py",
    description = "<strong>solution_4.py</strong> — Hamming distance: count the number of differing bits between two integers. XOR the values (1s where they differ), then count the 1-bits.",
    code = 'def hamming_distance(x, y):
    difference = x ^ y
    bit_count  = 0
    for n in range(32):
        mask = 1 << n
        if mask & difference != 0:
            bit_count += 1
    return bit_count',
    demo = 'tests = [(1, 8, 2), (7, 8, 4), (8, 8, 0)]
for x, y, expected in tests:
    result = hamming_distance(x, y)
    status = "OK" if result == expected else "FAIL"
    print(f"  [{status}] hamming({x}, {y}) = {result}  (XOR={bin(x^y)})")'
  ),

  list(
    name = "solution_5.py",
    description = "<strong>solution_5.py</strong> — Find the single number in an array where every other number appears exactly twice. XOR all numbers together: pairs cancel out (x XOR x = 0), leaving only the unique value.",
    code = 'def single_number(array):
    running_total = 0
    for num in array:
        running_total ^= num
    return running_total',
    demo = 'tests = [([5, 9, 9, 3, 5], 3), ([1, 2, 1, 3, 2], 3), ([7], 7)]
for arr, expected in tests:
    result = single_number(arr)
    status = "OK" if result == expected else "FAIL"
    print(f"  [{status}] single_number({arr}) = {result}")'
  )
)

chapter12_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(12, "\U0001f9e9", "Saving Space with Bit Vectors",
      "A bit vector packs N boolean values into N/32 integers, using bitwise operations to read and write individual bits. This achieves 32x memory savings over boolean arrays and enables O(1) set operations (union, intersection, difference) on the packed integers.",
      c("Bit Vectors", "Bitwise Operations", "AND OR XOR", "Set Operations", "Counting Sort", "32x Space Saving")),

    stats_row(
      list("32x",     "Space vs boolean array"),
      list("O(1)",    "Bit read/set/toggle"),
      list("O(N/32)", "Set union/intersection"),
      list("O(N)",    "Counting sort")
    ),

    fluidRow(tabBox(width = 12, id = ns("tabs"),

      tabPanel(title = tagList(icon("book"), " Theory"),
        fluidRow(
          box(title = "\U0001f9e9 Sets & Space", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("The Space Problem with Sets"),
                  tags$p("Storing a set of integers using a Python dict or list of booleans uses
                          much more memory than necessary. Each Python bool is ~28 bytes \u2014
                          a set of 1 million items uses 28 MB just for the booleans.")),
              div(class = "framework-card",
                  tags$h5("Bit Vectors to the Rescue"),
                  tags$p("Pack 32 boolean values into one 32-bit integer. A set of 1 million integers
                          needs only 1,000,000/32 = 31,250 integers = ~125 KB."),
                  tags$p(tags$strong("Reading bit i:"), " integer_index = i // 32; bit_index = i % 32"),
                  tags$p(tags$strong("Mask:"), tags$code("1 << bit_index")),
                  tags$p(tags$strong("Set:"), tags$code("integers[k] |= mask")),
                  tags$p(tags$strong("Read:"), tags$code("(integers[k] & mask) != 0"))
              ),
              div(class = "tip-box",
                  HTML("<strong>\U0001f4a1 Used in:</strong> Java's BitSet, Python's bitarray library,
                        database bitmap indexes, Bloom filters (next chapter), and Linux scheduling bitmaps."))),

          box(title = "\u2699\ufe0f Bitwise Operations", status = "warning", solidHeader = TRUE, width = 6,
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Op"), tags$th("Symbol"), tags$th("Meaning"), tags$th("Set Use"))),
                tags$tbody(
                  tags$tr(tags$td("AND"),  tags$td(tags$code("&")),  tags$td("1 only if both 1"),     tags$td("Intersection")),
                  tags$tr(tags$td("OR"),   tags$td(tags$code("|")),  tags$td("1 if either is 1"),     tags$td("Union")),
                  tags$tr(tags$td("XOR"),  tags$td(tags$code("^")),  tags$td("1 if exactly one is 1"),tags$td("Symmetric diff")),
                  tags$tr(tags$td("NOT"),  tags$td(tags$code("~")),  tags$td("Flip all bits"),         tags$td("Complement")),
                  tags$tr(tags$td("Shift"),tags$td(tags$code("<<")), tags$td("Shift bits left"),        tags$td("Position mask"))
                )
              ),
              div(class = "framework-card",
                  tags$h5("O(N/32) set operations"),
                  tags$p("Union, intersection, and difference operate on whole 32-bit integers at once.
                          For a set of 1 million elements: 1,000,000/32 = 31,250 operations vs
                          1,000,000 dict lookups. 32x fewer operations.")))
        ),
        fluidRow(
          box(title = "\U0001f4ca Counting Sort \u2014 All Three Versions", status = "success", solidHeader = TRUE, width = 6,
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Version"), tags$th("Space"), tags$th("Speed"), tags$th("Flexibility"))),
                tags$tbody(
                  tags$tr(tags$td("Hash table"),    tags$td("O(distinct vals)"), tags$td("Medium"), tags$td("Any key type")),
                  tags$tr(tags$td("Boolean array"), tags$td("O(range)"),         tags$td("Fast"),   tags$td("Integer range")),
                  tags$tr(tags$td("Bit vector"),    tags$td("O(range/32)"),      tags$td("Fastest"),tags$td("Integer range"))
                )
              ),
              div(class = "info-box-plain",
                  HTML("<strong>\u2139 All three are O(N + range) time</strong> \u2014 linear, not comparison-based.
                        The difference is purely in the space used for the seen-set, which also affects
                        cache behavior (smaller = more cache hits = faster in practice)."))),

          box(title = "\U0001f9ee XOR Tricks", status = "danger", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("add_binary.py: Add without +"),
                  tags$p(tags$code("x XOR y"), "= sum without carry"),
                  tags$p(tags$code("(x AND y) << 1"), "= carry bits"),
                  tags$p("Repeat until carry = 0. This is exactly how hardware adders work.")),
              div(class = "framework-card",
                  tags$h5("solution_5.py: Find the single number"),
                  tags$p("All pairs XOR to 0:", tags$code("x XOR x = 0")),
                  tags$p("0 XOR x = x"),
                  tags$p("So XOR of all elements = the unique element. O(N) time, O(1) space \u2014
                          no hash table needed.")),
              div(class = "success-box",
                  HTML("<strong>\u2705 solution_4.py: Hamming distance</strong><br>
                        XOR gives a 1-bit for every position where x and y differ.
                        Count those 1-bits with a loop \u2014 or use Python's
                        <code>bin(x^y).count('1')</code>.")))
        )
      ),

      tabPanel(title = tagList(icon("code"), " Code Lab"),
        code_lab_header("Chapter 12 \u2014 Saving Space with Bit Vectors",
          "Full BitVector class with set operations, three duplicate-detection approaches (dict/boolean/bitvector), three counting sort versions, binary addition with XOR, Hamming distance, and single-number XOR trick."),
        file_pills_ui(ns, CH12_FILES),
        py_code_display(ns),
        terminal_ui(ns)
      )
    ))
  )
}

chapter12_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    extra <- list(
      list(name = "bit_vector.py", code = CH12_BV_PY, description = "", demo = "")
    )
    code_lab_server(input, output, session, c(CH12_FILES, extra))
  })
}
