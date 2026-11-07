# modules/chapter04.R — Cache Is King

CH04_DLL_PY <- 'import double_ended_node

class DoublyLinkedList:
    def __init__(self, first_node=None, last_node=None):
        self.first_node = first_node
        self.last_node  = last_node

    def append(self, data):
        new_node = double_ended_node.Node(data)
        if not self.first_node:
            self.first_node = new_node
            self.last_node  = new_node
        else:
            new_node.previous_node      = self.last_node
            self.last_node.next_node    = new_node
            self.last_node              = new_node
        return new_node

    def insert_head(self, data):
        new_node = double_ended_node.Node(data)
        if not self.first_node:
            self.first_node = new_node
            self.last_node  = new_node
        else:
            new_node.next_node              = self.first_node
            self.first_node.previous_node   = new_node
            self.first_node                 = new_node
        return new_node

    def pop_head(self):
        popped_node = self.first_node
        self.first_node = self.first_node.next_node
        self.first_node.previous_node = None
        return popped_node

    def pop_tail(self):
        popped_node = self.last_node
        self.last_node = self.last_node.previous_node
        self.last_node.next_node = None
        return popped_node

    def move_to_head(self, node):
        if node == self.first_node:
            return
        if node.next_node:
            node.previous_node.next_node = node.next_node
            node.next_node.previous_node = node.previous_node
        else:
            node.previous_node.next_node = None
            self.last_node = node.previous_node
        node.next_node = self.first_node
        node.next_node.previous_node = node
        node.previous_node = None
        self.first_node = node

    def pop_index(self, index):
        if index == 0:
            return self.pop_head()
        current_node = self.first_node
        for _ in range(index):
            current_node = current_node.next_node
        if current_node == self.last_node:
            return self.pop_tail()
        current_node.previous_node.next_node = current_node.next_node
        current_node.next_node.previous_node = current_node.previous_node
        return current_node'

CH04_NODE_PY <- 'class Node:
    def __init__(self, data):
        self.data           = data
        self.next_node      = None
        self.previous_node  = None
        if isinstance(data, dict):
            self.product = data.get("key")
            self.price   = data.get("data")'

CH04_FILES <- list(

  list(
    name = "hash_cache.py",
    description = "<strong>hash_cache.py</strong> — Simplest caching pattern: a plain Python dict as a cache. On each call to <code>lowest_price(product)</code>, check the dict first. Cache hit = O(1) return; cache miss = slow web fetch then store. No eviction policy.",
    code = 'import time

cache = {}

def lowest_price(product):
    if product in cache:
        return cache.get(product)
    else:
        return search_web_for(product)

def search_web_for(product):
    # Mock data - in reality this hits the web
    data_from_web = [799, "Jupiter Electronics"]
    time.sleep(0.1)          # simulate network latency
    cache[product] = data_from_web
    return data_from_web',
    demo = 'import time

# First calls: cache misses (slow)
t = time.time()
r1 = lowest_price("laptop")
t1 = (time.time() - t) * 1000
print(f"First  call (cache miss):  {t1:.0f}ms -> {r1}")

t = time.time()
r2 = lowest_price("laptop")
t2 = (time.time() - t) * 1000
print(f"Second call (cache hit):   {t2:.1f}ms -> {r2}")
print(f"Speedup: {t1/max(t2,0.01):.0f}x faster")'
  ),

  list(
    name = "doubly_linked_list.py",
    description = "<strong>doubly_linked_list.py</strong> — Full doubly linked list with O(1) insert/remove at both ends, and <code>move_to_head()</code> to bring any node to the front in O(1). This is the core data structure powering the LRU Cache.",
    code = 'import double_ended_node

class DoublyLinkedList:
    def __init__(self, first_node=None, last_node=None):
        self.first_node = first_node
        self.last_node  = last_node

    def append(self, data):
        new_node = double_ended_node.Node(data)
        if not self.first_node:
            self.first_node = new_node
            self.last_node  = new_node
        else:
            new_node.previous_node    = self.last_node
            self.last_node.next_node  = new_node
            self.last_node            = new_node
        return new_node

    def insert_head(self, data):
        new_node = double_ended_node.Node(data)
        if not self.first_node:
            self.first_node = new_node
            self.last_node  = new_node
        else:
            new_node.next_node            = self.first_node
            self.first_node.previous_node = new_node
            self.first_node               = new_node
        return new_node

    def pop_tail(self):
        popped_node    = self.last_node
        self.last_node = self.last_node.previous_node
        self.last_node.next_node = None
        return popped_node

    def move_to_head(self, node):
        if node == self.first_node:
            return
        if node.next_node:
            node.previous_node.next_node = node.next_node
            node.next_node.previous_node = node.previous_node
        else:
            node.previous_node.next_node = None
            self.last_node = node.previous_node
        node.next_node            = self.first_node
        node.next_node.previous_node = node
        node.previous_node        = None
        self.first_node           = node

    def pop_index(self, index):
        current = self.first_node
        for _ in range(index):
            current = current.next_node
        if current == self.last_node:
            return self.pop_tail()
        current.previous_node.next_node = current.next_node
        current.next_node.previous_node = current.previous_node
        return current',
    demo = 'import double_ended_node

dll = DoublyLinkedList()
a = dll.append("A")
b = dll.append("B")
c = dll.append("C")
d = dll.append("D")
print("List: A <-> B <-> C <-> D")
print(f"Head: {dll.first_node.data}, Tail: {dll.last_node.data}")

dll.move_to_head(c)
print(f"After move_to_head(C):")
node = dll.first_node
while node:
    print(f"  {node.data}")
    node = node.next_node'
  ),

  list(
    name = "lru_cache.py",
    description = "<strong>lru_cache.py</strong> — Full LRU (Least Recently Used) Cache. Uses a doubly linked list (recency order) + hash table (O(1) lookup) together. Most-recently-used item is at the head; eviction removes the tail. Both operations are O(1).",
    code = 'import doubly_linked_list
import time

class LruCache:
    def __init__(self):
        self.hash_table  = {}
        self.linked_list = doubly_linked_list.DoublyLinkedList()
        self.max_size    = 4

    def read(self, key):
        if key in self.hash_table:       # Cache hit
            return self.freshen(key)
        return None                      # Cache miss

    def freshen(self, key):
        node = self.hash_table.get(key)
        self.linked_list.move_to_head(node)
        return node

    def cache(self, key, data):
        if len(self.hash_table) >= self.max_size:
            self.evict()
        new_node = self.linked_list.insert_head({"key": key, "data": data})
        self.hash_table[key] = new_node

    def evict(self):
        evicted_node = self.linked_list.pop_tail()
        del self.hash_table[evicted_node.data["key"]]',
    demo = 'import doubly_linked_list
import double_ended_node

cache = LruCache()
for item in ["a", "b", "c", "d"]:
    cache.cache(item, ord(item))

print("Cache after inserting a,b,c,d (head=most recent):")
node = cache.linked_list.first_node
while node:
    print(f"  {node.data}")
    node = node.next_node

# Access "a" - moves it to head
cache.freshen("a")
print("After freshen(a):")
node = cache.linked_list.first_node
while node:
    print(f"  {node.data}")
    node = node.next_node

# Insert "e" - evicts LRU item from tail
cache.cache("e", ord("e"))
print(f"After caching e (b evicted): keys = {list(cache.hash_table.keys())}")'
  ),

  list(
    name = "lru_cache_random.py",
    description = "<strong>lru_cache_random.py</strong> — Randomized LRU Cache. Instead of always evicting the least recently used item, picks the older of two randomly chosen positions. Fixes LRU worst-case adversarial access patterns at the cost of slightly suboptimal average evictions.",
    code = 'import doubly_linked_list
import random

class RandomizedLruCache:
    def __init__(self):
        self.hash_table  = {}
        self.linked_list = doubly_linked_list.DoublyLinkedList()
        self.max_size    = 4

    def read(self, key):
        if key in self.hash_table:
            return self.freshen(key)
        return None

    def freshen(self, key):
        node = self.hash_table.get(key)
        self.linked_list.move_to_head(node)
        return node

    def cache(self, key, data):
        if len(self.hash_table) >= self.max_size:
            self.evict()
        new_node = self.linked_list.insert_head({"key": key, "data": data})
        self.hash_table[key] = new_node

    def evict(self):
        # Pick two random positions; evict the one further back (older)
        r1 = random.randint(0, self.max_size - 1)
        r2 = random.randint(0, self.max_size - 1)
        node_index_to_evict = max(r1, r2)
        evicted_node = self.linked_list.pop_index(node_index_to_evict)
        del self.hash_table[evicted_node.data["key"]]',
    demo = 'import doubly_linked_list
import double_ended_node

cache = RandomizedLruCache()
for item in ["a", "b", "c", "d"]:
    cache.cache(item, ord(item))

print("Randomized LRU cache (4 items: a,b,c,d)")
print("Adding e - random eviction of older item:")
cache.cache("e", ord("e"))
print(f"  Remaining keys: {list(cache.hash_table.keys())}")'
  ),

  list(
    name = "row_col.py",
    description = "<strong>row_col.py</strong> — Sums a 2D array by iterating row-by-row (row index changes slowly, column index changes fast). This is <strong>cache-friendly</strong> because Python lists are stored row-first in memory, so consecutive accesses hit the same cache line.",
    code = 'def compute_sum(array):
    size = len(array)
    total = 0
    for row_index in range(size):
        for col_index in range(size):
            total += array[row_index][col_index]
    return total',
    demo = 'import time

size = 1000
arr = [[1] * size for _ in range(size)]

t = time.time()
result = compute_sum(arr)
ms = (time.time() - t) * 1000
print(f"row-first sum of {size}x{size} matrix: {ms:.2f} ms")
print(f"Sum = {result}")'
  ),

  list(
    name = "col_row.py",
    description = "<strong>col_row.py</strong> — Sums the same 2D array but column-by-column (column index changes slowly). This is <strong>cache-unfriendly</strong>: each access jumps to a different row, causing cache misses. Same result, measurably slower.",
    code = 'def compute_sum(array):
    size = len(array)
    total = 0
    for col_index in range(size):
        for row_index in range(size):
            total += array[row_index][col_index]
    return total',
    demo = 'import time

size = 1000
arr = [[1] * size for _ in range(size)]

t = time.time()
result = compute_sum(arr)
ms = (time.time() - t) * 1000
print(f"col-first sum of {size}x{size} matrix: {ms:.2f} ms")
print(f"Sum = {result}")
print("(Compare to row_col.py for cache-friendliness demo)")'
  )
)

chapter4_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(4, "\U0001f4be", "Cache Is King",
      "Caching is one of the most impactful optimizations in real systems. This chapter covers the LRU cache (a doubly linked list + hash table), eviction policies, randomized eviction to defeat adversarial access patterns, and how CPU cache behavior affects algorithm speed.",
      c("LRU Cache", "Eviction Policies", "Doubly Linked List + Hash Table", "Memory Hierarchy", "Spatial Locality", "Cache-Friendly Code")),

    stats_row(
      list("O(1)", "LRU read/write"),
      list("O(1)", "Eviction"),
      list("100x", "Cache vs RAM speed"),
      list("Spatial", "Key Locality Type")
    ),

    fluidRow(tabBox(width = 12, id = ns("tabs"),

      tabPanel(title = tagList(icon("book"), " Theory"),
        fluidRow(
          box(title = "\U0001f4be Caching", status = "info", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("What is a Cache?"),
                  tags$p("A cache stores the results of expensive operations so future requests for the same
                          data are served faster. The key insight: if you repeatedly fetch the same resource,
                          store it locally and skip the slow fetch on subsequent calls."),
                  tags$ul(
                    tags$li(tags$strong("Cache hit"), " \u2014 data is in cache, return immediately O(1)"),
                    tags$li(tags$strong("Cache miss"), " \u2014 data not in cache, fetch it, then store it")
                  )),
              div(class = "framework-card",
                  tags$h5("Eviction Policies"),
                  tags$p("When the cache is full and a new item arrives, something must go. Common policies:"),
                  tags$ul(
                    tags$li(tags$strong("LRU"), " \u2014 evict the Least Recently Used item"),
                    tags$li(tags$strong("LFU"), " \u2014 evict the Least Frequently Used item"),
                    tags$li(tags$strong("FIFO"), " \u2014 evict the oldest item"),
                    tags$li(tags$strong("Random"), " \u2014 evict a random item (surprisingly competitive)")
                  )),
              div(class = "tip-box",
                  HTML("<strong>\U0001f4a1 LRU Insight:</strong> Items accessed recently are likely to be accessed
                        again soon (temporal locality). LRU exploits this to maximise hit rate."))
          ),

          box(title = "\U0001f517 The LRU Data Structure", status = "warning", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("Why two data structures?"),
                  tags$p("LRU requires both fast lookup and fast recency tracking:"),
                  tags$ul(
                    tags$li(tags$strong("Hash table"), " \u2014 O(1) lookup: is item X in cache?"),
                    tags$li(tags$strong("Doubly linked list"), " \u2014 O(1) move-to-head and evict-tail")
                  )),
              tags$table(class = "algo-table",
                tags$thead(tags$tr(tags$th("Operation"), tags$th("Data Structure"), tags$th("Time"))),
                tags$tbody(
                  tags$tr(tags$td("Read (cache hit)"),  tags$td("Hash table + DLL move_to_head"), tags$td("O(1)")),
                  tags$tr(tags$td("Cache new item"),    tags$td("Hash table insert + DLL insert_head"), tags$td("O(1)")),
                  tags$tr(tags$td("Evict LRU"),         tags$td("DLL pop_tail + hash table delete"), tags$td("O(1)"))
                )
              ),
              div(class = "success-box",
                  HTML("<strong>\u2705 All operations O(1)</strong> \u2014 The combination of a hash table (for fast lookup)
                        and doubly linked list (for fast recency order maintenance) achieves this."))
          )
        ),

        fluidRow(
          box(title = "\U0001f9e0 Memory Hierarchy & Cache-Friendly Code", status = "success", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("The Memory Hierarchy"),
                  tags$p("Modern CPUs access memory at very different speeds:"),
                  tags$ul(
                    tags$li(tags$strong("L1 cache"), ": ~1 ns, a few KB"),
                    tags$li(tags$strong("L2 cache"), ": ~4 ns, 256 KB"),
                    tags$li(tags$strong("RAM"), ": ~100 ns, GBs"),
                    tags$li(tags$strong("SSD"), ": ~100 \u00b5s"),
                    tags$li(tags$strong("HDD"), ": ~10 ms")
                  )),
              div(class = "framework-card",
                  tags$h5("Spatial Locality"),
                  tags$p("When you access one memory location, the CPU pre-fetches nearby locations into cache.
                          Code that accesses data sequentially exploits this \u2014 code that jumps around defeats it."),
                  tags$p("row_col.py vs col_row.py: same computation, same Big O, but row-first is measurably
                          faster because Python stores list rows contiguously.")),
              div(class = "info-box-plain",
                  HTML("<strong>\u2139 Benchmark in book:</strong> The col-first version can be 2-10x slower on
                        large matrices, purely due to cache misses."))
          ),

          box(title = "\U0001f3b2 Randomized LRU", status = "danger", solidHeader = TRUE, width = 6,
              div(class = "framework-card",
                  tags$h5("The LRU Worst Case"),
                  tags$p("An adversary who knows your eviction policy can force 100% cache misses:
                          cycle through exactly cache_size+1 items in order. LRU evicts exactly
                          the item you need next, every time.")),
              div(class = "framework-card",
                  tags$h5("Randomized Eviction Fix"),
                  tags$p("Pick", tags$strong("two random positions"), "in the cache; evict the
                          older one (higher index). An adversary cannot predict which item will be evicted."),
                  tags$p("This is the same Power of Two Choices idea from Chapter 3 \u2014
                          one extra random draw dramatically improves the worst case.")),
              div(class = "success-box",
                  HTML("<strong>\u2705 Real-world use:</strong> Redis and Memcached both offer randomized
                        eviction variants for exactly this reason."))
          )
        )
      ),

      tabPanel(title = tagList(icon("code"), " Code Lab"),
        code_lab_header("Chapter 4 \u2014 Cache Is King",
          "Hash-based cache, doubly linked list, LRU cache, randomized LRU cache, and row-vs-column 2D array traversal."),
        file_pills_ui(ns, CH04_FILES),
        py_code_display(ns),
        terminal_ui(ns)
      )
    ))
  )
}

chapter4_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    extra <- list(
      list(name = "doubly_linked_list.py", code = CH04_DLL_PY,  description = "", demo = ""),
      list(name = "double_ended_node.py",  code = CH04_NODE_PY, description = "", demo = "")
    )
    code_lab_server(input, output, session, c(CH04_FILES, extra))
  })
}
