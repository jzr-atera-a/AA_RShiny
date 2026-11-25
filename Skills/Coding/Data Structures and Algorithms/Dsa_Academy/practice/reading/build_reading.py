"""
Build and validate practice/reading/reading.json (code-reading exercises).

    python build_reading.py

For 'output' exercises the snippet is executed and the printed output must equal the
correct option exactly, so the answer key can never drift from the code.
"""
import json, os, subprocess, sys, textwrap

HERE = os.path.dirname(os.path.abspath(__file__))

def ex(**k):
    k["code"] = textwrap.dedent(k["code"]).strip("\n") + "\n"
    return k

EX = [
ex(id="r01", title="Mutable default argument", kind="output", level="Easy", tags=["python gotchas"],
   code='''
def add(item, bucket=[]):
    bucket.append(item)
    return bucket

add(1)
add(2)
print(add(3))
''', question="What does this print?",
   options=["[3]", "[1, 2, 3]", "[1, 3]", "TypeError"], answer=2,
   explanation="The default list is created once, when the function is defined, and shared by every call that omits <code>bucket</code>. Use <code>bucket=None</code> and create the list inside.",
   model="It appends to one shared default list, so state leaks between calls; the third call sees the two earlier items."),
ex(id="r02", title="Closures capture variables, not values", kind="output", level="Medium", tags=["python gotchas", "closures"],
   code='''
fs = [lambda: i * i for i in range(4)]
print([f() for f in fs])
''', question="What does this print?",
   options=["[0, 1, 4, 9]", "[9, 9, 9, 9]", "[0, 0, 0, 0]", "[16, 16, 16, 16]"], answer=2,
   explanation="Each lambda looks up <code>i</code> when it is called; by then the comprehension has finished with <code>i = 3</code>. Bind the value with <code>lambda i=i: i * i</code>.",
   model="Builds four functions that all read the same loop variable late, so they all return 3 squared."),
ex(id="r03", title="What does this function compute?", kind="explain", level="Medium", tags=["binary search"],
   code='''
def mystery(a, x):
    lo, hi = 0, len(a)
    while lo < hi:
        mid = (lo + hi) // 2
        if a[mid] <= x:
            lo = mid + 1
        else:
            hi = mid
    return lo
''', question="Given a sorted list <code>a</code>, what does <code>mystery(a, x)</code> return?",
   options=["The index of x, or -1", "The first index whose value is ≥ x (bisect_left)", "The first index whose value is > x (bisect_right)", "The number of elements smaller than x"], answer=3,
   explanation="Every element ≤ x pushes <code>lo</code> to the right, so <code>lo</code> stops at the first element strictly greater than x — the same as <code>bisect.bisect_right</code>. It also equals the count of elements ≤ x.",
   model="Binary search for the insertion point after any existing copies of x: the number of elements ≤ x, i.e. bisect_right. O(log n)."),
ex(id="r04", title="Hidden quadratic", kind="complexity", level="Medium", tags=["complexity", "strings"],
   code='''
def build(words):
    s = ""
    for w in words:
        if w not in s.split(","):
            s += w + ","
    return s
''', question="With n words of bounded length, what is the worst-case time complexity?",
   options=["O(n)", "O(n log n)", "O(n²)", "O(n³)"], answer=3,
   explanation="Each iteration splits the whole string built so far (O(n) work) and scans the resulting list (O(n)), so n iterations cost O(n²). A set of seen words plus <code>','.join</code> makes it O(n).",
   model="Deduplicates words into a comma-separated string, but re-splits the growing string each time, so it is quadratic."),
ex(id="r05", title="Find the bug: sliding window", kind="bug", level="Medium", tags=["sliding window"],
   code='''
def longest_unique(s):
    seen = {}
    best = start = 0
    for i, ch in enumerate(s):
        if ch in seen:
            start = seen[ch] + 1
        seen[ch] = i
        best = max(best, i - start + 1)
    return best
''', question="<code>longest_unique(\"abba\")</code> should be 2. Which line is wrong?",
   options=["line 2", "line 5", "line 6", "line 8"], answer=3, bug_line=6,
   explanation="When the last 'a' is seen, its previous index 0 lies <b>before</b> the window start (2); setting <code>start = 1</code> moves the window backwards and the function returns 3. Use <code>start = max(start, seen[ch] + 1)</code>.",
   model="Longest substring without repeating characters with a last-seen map; the start pointer must never move left."),
ex(id="r06", title="Generator laziness", kind="output", level="Medium", tags=["generators"],
   code='''
def gen():
    print("start")
    yield 1
    print("middle")
    yield 2

g = gen()
print("created")
print(next(g))
''', question="What does this print?",
   options=["start\ncreated\n1", "created\nstart\n1", "created\nstart\n1\nmiddle", "start\n1\ncreated"], answer=2,
   explanation="Calling a generator function only creates the generator; its body runs up to the first <code>yield</code> when <code>next</code> is called.",
   model="Shows that generator bodies run lazily, one yield at a time."),
ex(id="r07", title="Aliasing in a 2-D grid", kind="output", level="Easy", tags=["python gotchas", "matrices"],
   code='''
grid = [[0] * 3] * 2
grid[0][1] = 5
print(grid)
''', question="What does this print?",
   options=["[[0, 5, 0], [0, 0, 0]]", "[[0, 5, 0], [0, 5, 0]]", "[[5, 5, 5], [0, 0, 0]]", "IndexError"], answer=2,
   explanation="<code>[row] * 2</code> repeats a reference to the same inner list. Build rows independently: <code>[[0] * 3 for _ in range(2)]</code>.",
   model="Creates a grid whose rows are the same list object, so writing one row writes both."),
ex(id="r08", title="What does this function compute?", kind="explain", level="Medium", tags=["bit manipulation"],
   code='''
def f(n):
    c = 0
    while n:
        n &= n - 1
        c += 1
    return c
''', question="For a non-negative integer n, <code>f(n)</code> returns…",
   options=["⌊log₂ n⌋", "The number of 1 bits in n", "The number of trailing zeros", "n with its bits reversed"], answer=2,
   explanation="<code>n &amp; (n − 1)</code> clears the lowest set bit, so the loop runs once per 1 bit (Kernighan's popcount) — O(number of set bits).",
   model="Counts set bits by repeatedly clearing the lowest one."),
ex(id="r09", title="Recursion depth and cost", kind="complexity", level="Medium", tags=["recursion", "complexity"],
   code='''
def f(a):
    if len(a) <= 1:
        return a
    mid = len(a) // 2
    return f(a[:mid]) + f(a[mid:])
''', question="Time complexity for a list of length n?",
   options=["O(log n)", "O(n)", "O(n log n)", "O(n²)"], answer=3,
   explanation="Each level of recursion copies O(n) elements in slices and concatenations, and there are log n levels: T(n) = 2T(n/2) + O(n) = O(n log n). It returns a copy of the list.",
   model="Splits the list in halves recursively and glues it back together — merge-sort shape without the sorting, so O(n log n) from copying."),
ex(id="r10", title="Find the bug: BFS on a grid", kind="bug", level="Medium", tags=["graphs", "bfs"],
   code='''
from collections import deque

def steps(grid, start, goal):
    q = deque([(start, 0)])
    seen = set()
    while q:
        (r, c), d = q.popleft()
        if (r, c) == goal:
            return d
        seen.add((r, c))
        for nr, nc in ((r+1, c), (r-1, c), (r, c+1), (r, c-1)):
            if 0 <= nr < len(grid) and 0 <= nc < len(grid[0]) and grid[nr][nc] == 0 and (nr, nc) not in seen:
                q.append(((nr, nc), d + 1))
    return -1
''', question="It returns correct answers but is very slow on large open grids. Which line causes it?",
   options=["line 4", "line 7", "line 10", "line 13"], answer=3, bug_line=10,
   explanation="Cells are marked visited when <b>popped</b>, so the same cell can be enqueued many times before it is processed — exponential-looking blow-up on open grids. Mark <code>seen</code> when you <b>enqueue</b> (and add <code>start</code> initially).",
   model="Shortest path in an unweighted grid with BFS; correctness holds but duplicates explode the queue."),
ex(id="r11", title="Sorting with keys", kind="output", level="Easy", tags=["sorting"],
   code='''
people = [("ann", 31), ("bob", 25), ("cid", 31), ("dee", 25)]
people.sort(key=lambda p: -p[1])
print([name for name, _ in people])
''', question="What does this print?",
   options=["['ann', 'cid', 'bob', 'dee']", "['cid', 'ann', 'dee', 'bob']", "['ann', 'bob', 'cid', 'dee']", "['dee', 'bob', 'cid', 'ann']"], answer=1,
   explanation="Python's sort is stable: people with equal ages keep their original relative order.",
   model="Sorts by age descending; ties stay in input order because Timsort is stable."),
ex(id="r12", title="Dictionary iteration while mutating", kind="output", level="Medium", tags=["python gotchas", "hashing"],
   code='''
d = {"a": 1, "b": 2, "c": 3}
try:
    for k in d:
        if d[k] % 2:
            del d[k]
except RuntimeError as e:
    print("error:", e)
print(sorted(d))
''', question="What does this print?",
   options=["['b']", "error: dictionary changed size during iteration\n['b', 'c']", "['a', 'b', 'c']", "error: dictionary changed size during iteration\n['b']"], answer=2,
   explanation="Deleting a key changes the dict's size; the iterator detects it on the next step and raises. Only 'a' was deleted. Iterate over <code>list(d)</code> instead.",
   model="Attempts to drop odd values in place but the iteration aborts after the first deletion."),
ex(id="r13", title="What does this class do?", kind="explain", level="Medium", tags=["design", "stacks"],
   code='''
class S:
    def __init__(self):
        self.a, self.b = [], []
    def push(self, x):
        self.a.append(x)
    def pop(self):
        if not self.b:
            while self.a:
                self.b.append(self.a.pop())
        return self.b.pop()
''', question="What data structure does <code>S</code> implement, and what is the cost of <code>pop</code>?",
   options=["A stack; O(1) worst case", "A queue; O(1) amortised", "A queue; O(n) every call", "A deque; O(log n)"], answer=2,
   explanation="Two stacks reverse the order once: elements leave in insertion order (FIFO). Each element moves from <code>a</code> to <code>b</code> at most once, so pops are O(1) amortised (#232).",
   model="A FIFO queue built from two stacks; the transfer happens only when the out-stack is empty."),
ex(id="r14", title="Integer division and negatives", kind="output", level="Easy", tags=["python gotchas", "math"],
   code='''
print(-7 // 2, int(-7 / 2), -7 % 2)
''', question="What does this print?",
   options=["-3 -3 1", "-4 -3 1", "-4 -4 -1", "-3 -4 -1"], answer=2,
   explanation="<code>//</code> floors towards −∞ (−4), <code>int()</code> truncates towards 0 (−3), and <code>%</code> takes the sign of the divisor (1). This matters in Basic Calculator and Evaluate RPN.",
   model="Contrasts floor division, truncation and Python's modulo sign rule."),
ex(id="r15", title="Memoised recursion", kind="complexity", level="Medium", tags=["dynamic programming"],
   code='''
from functools import lru_cache

@lru_cache(maxsize=None)
def ways(i, j):
    if i == 0 or j == 0:
        return 1
    return ways(i - 1, j) + ways(i, j - 1)
''', question="Time complexity of <code>ways(m, n)</code> with the cache?",
   options=["O(2^(m+n))", "O(m + n)", "O(m · n)", "O(m · n · log(mn))"], answer=3,
   explanation="There are (m+1)(n+1) distinct (i, j) states, each computed once with O(1) work. Without the cache it would be exponential.",
   model="Counts lattice paths in a grid (Unique Paths) with top-down DP."),
ex(id="r16", title="Find the bug: heap of tuples", kind="bug", level="Hard", tags=["heaps"],
   code='''
import heapq

def merge_lists(lists):
    h = []
    for lst in lists:
        if lst:
            heapq.heappush(h, (lst.val, lst))
    out = []
    while h:
        val, node = heapq.heappop(h)
        out.append(val)
        if node.next:
            heapq.heappush(h, (node.next.val, node.next))
    return out
''', question="Merging linked lists sometimes crashes with <code>TypeError: '&lt;' not supported between instances of 'ListNode'</code>. Which line needs to change?",
   options=["line 3", "line 7", "line 10", "line 12"], answer=2, bug_line=7,
   explanation="When two values are equal, tuple comparison falls through to the nodes, which are not orderable. Add a unique tie-breaker: <code>(lst.val, i, lst)</code> with a counter (and the same on line 13).",
   model="K-way merge with a min-heap; ties on value compare the node objects."),
]

def run(code):
    p = subprocess.run([sys.executable, "-c", code], capture_output=True, text=True, timeout=10)
    return p.stdout

ids = set()
for e in EX:
    assert e["id"] not in ids; ids.add(e["id"])
    assert 1 <= e["answer"] <= len(e["options"]), e["id"]
    compile(e["code"], e["id"], "exec")
    e["runnable"] = e["kind"] != "explain" or True
    if e["kind"] == "output":
        got = run(e["code"]).rstrip("\n")
        want = e["options"][e["answer"] - 1]
        if got != want:
            raise SystemExit("[%s] output %r != answer %r" % (e["id"], got, want))
    if e["kind"] == "bug":
        lines = e["code"].splitlines()
        assert 1 <= e["bug_line"] <= len(lines), e["id"]
        assert e["options"][e["answer"] - 1] == "line %d" % e["bug_line"], e["id"]
# behavioural checks for explain / bug snippets
ns = {}; exec(EX[2]["code"], ns); import bisect
for a in ([1, 2, 2, 3], [], [5]):
    for x in range(-1, 7):
        assert ns["mystery"](a, x) == bisect.bisect_right(a, x)
ns = {}; exec(EX[4]["code"], ns); assert ns["longest_unique"]("abba") == 3   # demonstrates the bug
ns = {}; exec(EX[7]["code"], ns); assert all(ns["f"](n) == bin(n).count("1") for n in range(500))
json.dump(EX, open(os.path.join(HERE, "reading.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
print("wrote reading.json with %d exercises" % len(EX))
