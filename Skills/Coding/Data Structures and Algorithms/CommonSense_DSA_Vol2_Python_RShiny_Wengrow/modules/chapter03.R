# modules/chapter03.R
# Chapter 3: How Random Is That?

CH03_TREE_NODE_PY <- 'import random

class TreeNode:
    def __init__(self, value, left=None, right=None):
        self.value = value
        self.left_child = left
        self.right_child = right

def insert(value, node):
    if value < node.value:
        if not node.left_child:
            node.left_child = TreeNode(value)
        else:
            insert(value, node.left_child)
    elif value > node.value:
        if not node.right_child:
            node.right_child = TreeNode(value)
        else:
            insert(value, node.right_child)

def tree_size(node):
    level_size = 1; total_size = 1
    current_node = node.left_child
    while current_node:
        level_size *= 2; total_size += level_size
        current_node = current_node.left_child
    return total_size

def sample(node):
    subtree_size = tree_size(node)
    current_node = node
    while current_node:
        roll = random.randint(1, subtree_size)
        if roll == 1:
            return current_node.value
        subtree_size //= 2
        roll = random.randint(1, 2)
        if roll == 1:
            current_node = current_node.left_child
        else:
            current_node = current_node.right_child'

CH03_FILES <- list(

  list(
    name = "lcg.py",
    description = "<strong>lcg.py</strong> — Linear Congruential Generator (LCG): a classic PRNG formula. Generates a sequence using <code>next = (previous + 12549) % 211</code>. Demonstrates how all PRNGs are deterministic \u2014 given the same seed, the same sequence is always produced.",
    code = 'def generate_random_sequence(seed):
    sequence = []
    previous_number = seed

    while True:
        next_number = (previous_number + 12549) % 211
        if next_number in sequence:
            break
        else:
            sequence.append(next_number)
            previous_number = next_number

    return sequence',
    demo = 'seq1 = generate_random_sequence(42)
seq2 = generate_random_sequence(42)
seq3 = generate_random_sequence(99)

print(f"Sequence length (seed=42): {len(seq1)}")
print(f"Same seed gives same sequence: {seq1 == seq2}")
print(f"First 10 (seed=42): {seq1[:10]}")
print(f"First 10 (seed=99): {seq3[:10]}")
print(f"Sequences identical? {seq1 == seq3}")'
  ),

  list(
    name = "fisher_yates.py",
    description = "<strong>fisher_yates.py</strong> — The Fisher-Yates shuffle: the correct, unbiased algorithm for shuffling an array. For each position i from 0 to N-2, swap arr[i] with a random element from arr[i..N-1]. Produces all N! permutations with equal probability.",
    code = 'import random


def fisher_yates(array):
    for i in range(0, len(array) - 1):
        j = random.randint(i, len(array) - 1)
        array[i], array[j] = array[j], array[i]',
    demo = 'import random
from collections import Counter

# Demo 1: basic shuffle
array = [1, 2, 3, 4, 5, 6, 7, 8]
fisher_yates(array)
print("Shuffled:", array)

# Demo 2: verify uniformity - count how often each permutation of [1,2,3] occurs
results = Counter()
for _ in range(6000):
    arr = [1, 2, 3]
    fisher_yates(arr)
    results[tuple(arr)] += 1

print("\\nPermutation frequency (should be ~1000 each for 6000 trials):")
for perm, count in sorted(results.items()):
    bar = "#" * (count // 50)
    print(f"  {perm}: {count} {bar}")'
  ),

  list(
    name = "naive_shuffle.py",
    description = "<strong>naive_shuffle.py</strong> — The WRONG way to shuffle. Picks a random index from the FULL array on every iteration (including already-placed positions). This produces a biased distribution \u2014 not all N! permutations are equally likely.",
    code = 'import random


def naive_shuffle(array):
    for i in range(0, len(array) - 1):
        j = random.randint(0, len(array) - 1)  # BUG: should be randint(i, len-1)
        array[i], array[j] = array[j], array[i]',
    demo = 'from collections import Counter

def fisher_yates(array):
    for i in range(len(array) - 1):
        j = __import__("random").randint(i, len(array) - 1)
        array[i], array[j] = array[j], array[i]

# Compare bias
naive_counts = Counter()
fair_counts  = Counter()
N = 30000

for _ in range(N):
    arr = [1, 2, 3]
    naive_shuffle(arr)
    naive_counts[tuple(arr)] += 1

for _ in range(N):
    arr = [1, 2, 3]
    fisher_yates(arr)
    fair_counts[tuple(arr)] += 1

print("Naive shuffle (BIASED):")
for perm, count in sorted(naive_counts.items()):
    print(f"  {perm}: {count} ({count/N*100:.1f}%)")

print("\\nFisher-Yates (UNBIASED):")
for perm, count in sorted(fair_counts.items()):
    print(f"  {perm}: {count} ({count/N*100:.1f}%)")'
  ),

  list(
    name = "balls_in_bins.py",
    description = "<strong>balls_in_bins.py</strong> — Simulates throwing 1000 balls into 10 bins uniformly at random. Demonstrates the birthday problem \u2014 even with uniform random choice, some bins get many more balls than others (imbalance).",
    code = 'import random


bins = [[], [], [], [], [], [], [], [], [], []]

for ball in range(1000):
    chosen_bin = bins[random.randint(0, 9)]
    chosen_bin.append(ball)

for i, b in enumerate(bins):
    bar = "#" * len(b)
    print(f"Bin {i}: {len(b):4} balls  {bar}")',
    demo = ''
  ),

  list(
    name = "power_of_two.py",
    description = "<strong>power_of_two.py</strong> — The Power of Two Choices: instead of placing each ball in a random bin, pick TWO random bins and place the ball in the less-loaded one. This simple trick dramatically reduces the maximum load from O(log N / log log N) to O(log log N).",
    code = 'import random


bins = [[], [], [], [], [], [], [], [], [], []]

for ball in range(1000):
    bin_1 = bins[random.randint(0, 9)]
    bin_2 = bins[random.randint(0, 9)]

    # Place ball in the less-loaded bin
    if len(bin_1) < len(bin_2):
        bin_1.append(ball)
    else:
        bin_2.append(ball)',
    demo = 'import random
from copy import deepcopy

def run_random(n_balls, n_bins):
    bins = [[] for _ in range(n_bins)]
    for ball in range(n_balls):
        bins[random.randint(0, n_bins-1)].append(ball)
    return max(len(b) for b in bins)

def run_power_of_two(n_balls, n_bins):
    bins = [[] for _ in range(n_bins)]
    for ball in range(n_balls):
        b1 = bins[random.randint(0, n_bins-1)]
        b2 = bins[random.randint(0, n_bins-1)]
        (b1 if len(b1) < len(b2) else b2).append(ball)
    return max(len(b) for b in bins)

trials = 20
r_max = sum(run_random(1000, 10) for _ in range(trials)) / trials
p_max = sum(run_power_of_two(1000, 10) for _ in range(trials)) / trials

print(f"1000 balls, 10 bins ({trials} trials avg):")
print(f"  Random placement max load:        {r_max:.1f}")
print(f"  Power of Two Choices max load:    {p_max:.1f}")
print(f"  Improvement: {r_max/p_max:.2f}x less imbalance")'
  ),

  list(
    name = "solution_1.py",
    description = "<strong>solution_1.py</strong> — Exercise solution: pick 3 distinct random elements from an array, returned in their original order. Uses rejection sampling to avoid index repeats.",
    code = 'import random


def pick_3(array):
    chosen_indexes = []

    for _ in range(3):
        random_index = random.randint(0, len(array) - 1)
        while random_index in chosen_indexes:
            random_index = random.randint(0, len(array) - 1)
        chosen_indexes.append(random_index)

    chosen_indexes.sort()    # preserve original order

    return [array[index] for index in chosen_indexes]',
    demo = 'array = ["apple", "banana", "cherry", "date", "elderberry", "fig", "grape"]
print("Array:", array)
for _ in range(5):
    print("pick_3():", pick_3(array))'
  ),

  list(
    name = "solution_2.py",
    description = "<strong>solution_2.py</strong> — Exercise solution: sample a uniformly random key from a hash table (dict). Since Python dicts don't support O(1) random access, converts keys to a list and uses random.choice().",
    code = 'import random


def sample(hash_table):
    return random.choice(list(hash_table.keys()))',
    demo = 'ht = {"apple": 1, "banana": 2, "cherry": 3, "date": 4, "elderberry": 5}
counts = {k: 0 for k in ht}
for _ in range(5000):
    counts[sample(ht)] += 1

print("Sample frequency from hash table (5000 trials):")
for key, count in sorted(counts.items()):
    pct = count / 5000 * 100
    bar = "#" * (count // 100)
    print(f"  {key:12}: {count} ({pct:.1f}%) {bar}")'
  ),

  list(
    name = "solution_3.py",
    description = "<strong>solution_3.py</strong> — Exercise solution: sample uniformly from an array in a single pass without converting to another structure. Uses a probabilistic trick: at each position, decide with probability 1/remaining whether to return that element.",
    code = 'import random


def sample(array):
    denominator = len(array)

    for value in array[:-1]:
        roll = random.randint(1, denominator)
        if roll == 1:
            return value
        denominator -= 1

    return array[-1]',
    demo = 'from collections import Counter
array = ["A", "B", "C", "D", "E"]
counts = Counter()
for _ in range(10000):
    counts[sample(array)] += 1

print("sample() frequency (10000 trials, should be ~2000 each):")
for k in sorted(counts):
    bar = "#" * (counts[k] // 100)
    print(f"  {k}: {counts[k]} {bar}")'
  ),

  list(
    name = "tree_node.py",
    description = "<strong>tree_node.py</strong> — BST with a randomized <code>sample()</code> method. Uses the tree structure to sample approximately uniformly \u2014 at each node, with probability 1/subtree_size return that node, otherwise descend left or right randomly.",
    code = 'import random


class TreeNode:
    def __init__(self, value, left=None, right=None):
        self.value = value
        self.left_child = left
        self.right_child = right


def insert(value, node):
    if value < node.value:
        if not node.left_child:
            node.left_child = TreeNode(value)
        else:
            insert(value, node.left_child)
    elif value > node.value:
        if not node.right_child:
            node.right_child = TreeNode(value)
        else:
            insert(value, node.right_child)


def tree_size(node):
    level_size = 1
    total_size = 1
    current_node = node.left_child
    while current_node:
        level_size *= 2
        total_size += level_size
        current_node = current_node.left_child
    return total_size


def sample(node):
    subtree_size = tree_size(node)
    current_node = node

    while current_node:
        roll = random.randint(1, subtree_size)
        if roll == 1:
            return current_node.value
        subtree_size //= 2
        roll = random.randint(1, 2)
        if roll == 1:
            current_node = current_node.left_child
        else:
            current_node = current_node.right_child',
    demo = 'from collections import Counter

root = TreeNode(50)
for v in [25, 75, 60, 100, 5, 40]:
    insert(v, root)

values = [5, 25, 40, 50, 60, 75, 100]
print("BST values:", values)

counts = Counter()
for _ in range(7000):
    counts[sample(root)] += 1

print("\\nSample distribution (7000 trials):")
for v in values:
    bar = "#" * (counts.get(v, 0) // 70)
    print(f"  {v:4}: {counts.get(v,0):5} {bar}")'
  )
)

chapter3_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(3, "\U0001f3b2", "How Random Is That?",
      "Randomized algorithms use deliberate randomness to achieve better average-case performance, resist adversarial inputs, and solve problems that deterministic algorithms handle poorly. This chapter covers PRNGs, the Fisher-Yates shuffle, BST randomization, and the Power of Two Choices for load balancing.",
      c("PRNGs", "TRNGs vs PRNGs", "Fisher-Yates Shuffle", "LCG", "BST Randomization", "Power of Two Choices", "Load Balancing")),

    stats_row(
      list("O(N)",    "Fisher-Yates"),
      list("N!",      "Equal Permutations"),
      list("O(log log N)", "Power of Two Choices"),
      list("Biased",  "Naive Shuffle Problem")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        tabPanel(title = tagList(icon("book"), " Theory"),
          fluidRow(
            box(title = "\U0001f3b2 TRNGs vs PRNGs", status = "info", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("True Random Number Generators (TRNGs)"),
                    tags$p("Based on physical entropy: radioactive decay, thermal noise, mouse movements.
                            Genuinely unpredictable but slow and hardware-dependent."),
                    tags$p(tags$strong("Used for:"), " cryptography, security keys, casino games.")),
                div(class = "framework-card",
                    tags$h5("Pseudo-Random Number Generators (PRNGs)"),
                    tags$p("Deterministic algorithms that produce sequences that appear random.
                            Given the same seed, always produce the same sequence."),
                    tags$p(tags$strong("Used for:"), " simulations, games, algorithms, testing."),
                    tags$p(tags$code("random.seed(42)"), " \u2014 makes results reproducible.")),
                div(class = "framework-card",
                    tags$h5("Linear Congruential Generator (LCG)"),
                    tags$p("The simplest PRNG: next = (prev + c) mod m. The book's example uses c=12549, m=211.
                            Period = m (the sequence repeats after m distinct values)."))
            ),

            box(title = "\U0001f500 The Fisher-Yates Shuffle", status = "warning", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("The Correct Shuffle"),
                    tags$ol(
                      tags$li("For i from 0 to N-2:"),
                      tags$li("Pick j = random integer in [i, N-1]"),
                      tags$li("Swap arr[i] with arr[j]")
                    ),
                    tags$p("Each of the N! possible permutations is equally likely. Proof: at step i, there are N-i choices for
                            what goes into position i. Multiply: N \u00d7 (N-1) \u00d7 ... \u00d7 2 = N! equally likely outcomes.")
                ),
                div(class = "framework-card",
                    tags$h5("The Naive (WRONG) Shuffle"),
                    tags$p(tags$code("j = random.randint(0, N-1)"), " \u2014 picks from the FULL range every time."),
                    tags$p("This produces N\u1d4f total branches but N! permutations are not equally divisible into N\u1d4f outcomes
                            when N > 2. Result: biased distribution."),
                    tags$p(tags$strong("For N=3:"), " N\u1d4f=27, N!=6 \u2014 27 is not divisible by 6.")
                ),
                div(class = "warn-box",
                    HTML("<strong>\u26a0 Never use the naive shuffle</strong> for anything requiring fairness
                          (card games, A/B test assignment, random sampling)."))
            )
          ),

          fluidRow(
            box(title = "\U0001f333 BST Randomization", status = "success", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("The Problem"),
                    tags$p("A standard BST built from sorted input degenerates to a linked list \u2014 O(N) height.
                            Randomizing the insertion order gives O(log N) expected height."),
                    tags$p("But what if you need to", tags$em("sample"), "a random node from an existing BST
                            without traversing all N nodes?")),
                div(class = "framework-card",
                    tags$h5("Probabilistic BST Sampling (tree_node.py)"),
                    tags$p("At each node: with probability 1/subtree_size, return this node.
                            Otherwise, descend left or right with probability 1/2 each."),
                    tags$p("Each node of a balanced BST gets selected with approximately equal probability
                            \u2014 O(log N) time instead of O(N).")),
                div(class = "info-box-plain",
                    HTML("<strong>\u2139 Distribution:</strong> The approximation improves with tree balance.
                          The distribution shown in tree_node.py demo is close to uniform for a balanced BST."))
            ),

            box(title = "\u2696\ufe0f Power of Two Choices", status = "danger", solidHeader = TRUE, width = 6,
                div(class = "framework-card",
                    tags$h5("The Problem: Load Balancing"),
                    tags$p("N balls into N bins uniformly at random \u2014 the most loaded bin has",
                           tags$strong("O(log N / log log N)"), "balls in expectation.")),
                div(class = "framework-card",
                    tags$h5("The Solution: Two Choices"),
                    tags$p("Pick TWO random bins for each ball. Place the ball in the", tags$strong("less loaded"), "one."),
                    tags$p("Maximum load drops to", tags$strong("O(log log N)"), "\u2014 an exponential improvement
                            from a single extra random choice.")),
                tags$table(class = "algo-table",
                  tags$thead(tags$tr(tags$th("Strategy"), tags$th("Max Load"), tags$th("N=1000"))),
                  tags$tbody(
                    tags$tr(tags$td("Random (1 choice)"),    tags$td("O(log N / log log N)"), tags$td("~4\u20135")),
                    tags$tr(tags$td("Power of Two Choices"), tags$td("O(log log N) \u2705"),  tags$td("~2\u20133"))
                  )
                ),
                div(class = "success-box",
                    HTML("<strong>\u2705 Used in:</strong> Google's Maglev load balancer, distributed hash tables,
                          and many real-world load balancing systems."))
            )
          )
        ),

        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header(
            "Chapter 3 \u2014 How Random Is That?",
            "LCG pseudo-random generator, Fisher-Yates (correct) shuffle, naive (biased) shuffle comparison, balls-in-bins simulation, Power of Two Choices, and three exercise solutions."
          ),
          file_pills_ui(ns, CH03_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter3_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    extra <- list(
      list(name = "tree_node.py", code = CH03_TREE_NODE_PY, description = "", demo = "")
    )
    code_lab_server(input, output, session, c(CH03_FILES, extra))
  })
}
