# Practice bank — design-a-class problems (LeetCode "operations" format).
# Each test is {"ops": [...], "args": [[...], ...]}; the first op constructs the object.

PROBLEMS = [
dict(
    id="lc146", num=146, title="LRU Cache", slug="lru-cache", difficulty="Medium", topic="systemdesign",
    pattern="Hash map + doubly linked list", companies=["Meta", "Google"],
    kind="design", cls="LRUCache", time_factor=10,
    statement="""Design a **least-recently-used cache** with a fixed capacity.

* `LRUCache(capacity)` creates the cache.
* `get(key)` returns the value for `key`, or `-1` if it is absent. A successful `get` counts as a use.
* `put(key, value)` inserts or updates `key`. If this pushes the cache over capacity, evict the least recently used key first.

Both `get` and `put` must run in **O(1)** average time.""",
    constraints=["1 ≤ capacity ≤ 3000", "0 ≤ key ≤ 10⁴", "0 ≤ value ≤ 10⁵", "At most 2 · 10⁵ calls."],
    examples=[
        dict(args={"ops": ["LRUCache", "put", "put", "get", "put", "get", "put", "get", "get", "get"],
                   "args": [[2], [1, 1], [2, 2], [1], [3, 3], [2], [4, 4], [1], [3], [4]]},
             expected=[None, None, None, 1, None, -1, None, -1, 3, 4],
             explanation="put(3,3) evicts key 2 (key 1 was just used); put(4,4) evicts key 1."),
    ],
    hidden=[dict(args={"ops": ["LRUCache", "put", "get", "put", "get", "get"], "args": [[1], [2, 1], [2], [3, 2], [2], [3]]}),
            dict(args={"ops": ["LRUCache", "put", "put", "put", "get"], "args": [[2], [1, 1], [1, 5], [2, 2], [1]]})],
    starter='''class LRUCache:

    def __init__(self, capacity: int):
        pass

    def get(self, key: int) -> int:
        pass

    def put(self, key: int, value: int) -> None:
        pass
''',
    reference='''class LRUCache:
    def __init__(self, capacity):
        self.cap = capacity
        self.d = OrderedDict()

    def get(self, key):
        if key not in self.d:
            return -1
        self.d.move_to_end(key)
        return self.d[key]

    def put(self, key, value):
        self.d[key] = value
        self.d.move_to_end(key)
        if len(self.d) > self.cap:
            self.d.popitem(last=False)
''',
    brute='''class LRUCache:
    def __init__(self, capacity):
        self.cap = capacity
        self.items = []                # [key, value], most recent last

    def _find(self, key):
        for i, (k, _) in enumerate(self.items):
            if k == key:
                return i
        return -1

    def get(self, key):
        i = self._find(key)
        if i < 0:
            return -1
        kv = self.items.pop(i); self.items.append(kv)
        return kv[1]

    def put(self, key, value):
        i = self._find(key)
        if i >= 0:
            self.items.pop(i)
        self.items.append([key, value])
        if len(self.items) > self.cap:
            self.items.pop(0)
''',
    small_gen='''def gen(rng):
    ops, args = ["LRUCache"], [[rng.randint(1, 3)]]
    for _ in range(rng.randint(1, 15)):
        if rng.random() < 0.5:
            ops.append("put"); args.append([rng.randint(0, 4), rng.randint(0, 9)])
        else:
            ops.append("get"); args.append([rng.randint(0, 4)])
    return {"ops": ops, "args": args}
''',
    gens=[dict(name="100,000 operations, capacity 3,000", code='''def gen(rng):
    ops, args = ["LRUCache"], [[3000]]
    for _ in range(100000):
        if rng.random() < 0.5:
            ops.append("put"); args.append([rng.randint(0, 10000), rng.randint(0, 10**5)])
        else:
            ops.append("get"); args.append([rng.randint(0, 10000)])
    return {"ops": ops, "args": args}
''')],
    hints=["A hash map gives O(1) lookup, but not 'which key is least recently used'.",
           "A doubly linked list ordered by recency can move a node to the front and drop the tail in O(1).",
           "Combine them: the map stores key → list node. (In Python, OrderedDict does exactly this.)"],
    approach="""Pair a **hash map** (key → node) with a **doubly linked list** ordered by recency. `get` looks the node up and moves it to the most-recent end; `put` updates or inserts at that end and, when over capacity, removes the node at the least-recent end and deletes its key from the map. Sentinel head and tail nodes remove all edge cases.

Python's `OrderedDict` (`move_to_end`, `popitem(last=False)`) is the same structure; interviewers often ask you to build the linked list yourself.""",
    complexity="O(1) average per operation · O(capacity) space",
    followups=["Implement the doubly linked list yourself, without OrderedDict.", "LFU cache (#460).",
               "Make it thread-safe.", "Add a time-to-live per entry."],
),

dict(
    id="lc359", num=359, title="Logger Rate Limiter", slug="logger-rate-limiter", difficulty="Easy", topic="hashing",
    pattern="Hash map of next allowed time", companies=["Google"],
    kind="design", cls="Logger",
    statement="""Design a logger that receives a stream of messages with timestamps (in seconds, non-decreasing). Each **unique message** may be printed at most once every 10 seconds: if `message` is printed at time `t`, the same message is suppressed until time `t + 10`.

* `Logger()` initialises the logger.
* `shouldPrintMessage(timestamp, message)` returns `true` if the message should be printed now (and records that it was), otherwise `false`.""",
    constraints=["0 ≤ timestamp ≤ 10⁹", "Timestamps are non-decreasing.", "At most 10⁴ calls."],
    examples=[
        dict(args={"ops": ["Logger", "shouldPrintMessage", "shouldPrintMessage", "shouldPrintMessage", "shouldPrintMessage", "shouldPrintMessage", "shouldPrintMessage"],
                   "args": [[], [1, "foo"], [2, "bar"], [3, "foo"], [8, "bar"], [10, "foo"], [11, "foo"]]},
             expected=[None, True, True, False, False, False, True]),
    ],
    hidden=[dict(args={"ops": ["Logger", "shouldPrintMessage", "shouldPrintMessage"], "args": [[], [0, "a"], [10, "a"]]})],
    starter='''class Logger:

    def __init__(self):
        pass

    def shouldPrintMessage(self, timestamp: int, message: str) -> bool:
        pass
''',
    reference='''class Logger:
    def __init__(self):
        self.next_ok = {}

    def shouldPrintMessage(self, timestamp, message):
        if timestamp >= self.next_ok.get(message, 0):
            self.next_ok[message] = timestamp + 10
            return True
        return False
''',
    brute='''class Logger:
    def __init__(self):
        self.printed = []

    def shouldPrintMessage(self, timestamp, message):
        for t, m in self.printed:
            if m == message and timestamp - t < 10:
                return False
        self.printed.append((timestamp, message))
        return True
''',
    small_gen='''def gen(rng):
    ops, args, t = ["Logger"], [[]], 0
    for _ in range(rng.randint(1, 12)):
        t += rng.randint(0, 6)
        ops.append("shouldPrintMessage"); args.append([t, rng.choice(["a", "b", "c"])])
    return {"ops": ops, "args": args}
''',
    hints=["For each message you only need to know when it may next be printed.",
           "Store message → timestamp + 10 when it is printed.",
           "Follow-up: memory grows with every distinct message. How would you clean up old entries?"],
    approach="""Keep a hash map `message → earliest time it may print again`. A call prints (and updates the map) if `timestamp ≥ next_ok[message]`.

Memory grows with distinct messages; a common follow-up keeps a queue of the last 10 seconds of printed messages and evicts expired ones, bounding memory by the recent traffic.""",
    complexity="O(1) average per call · O(distinct messages) space",
    followups=["Bound memory to messages seen in the last 10 seconds.", "Allow at most N prints per window (sliding-window rate limiter).",
               "Timestamps can arrive out of order by up to 2 seconds.", "Many servers share one limiter — what changes?"],
),

dict(
    id="lc2034", num=2034, title="Stock Price Fluctuation", slug="stock-price-fluctuation", difficulty="Medium", topic="heaps",
    pattern="Hash map + lazy-deletion heaps", companies=["Google"],
    kind="design", cls="StockPrice", time_factor=10,
    statement="""Records of a stock's price arrive **out of order**, and a record may **correct** an earlier price for the same timestamp.

* `StockPrice()` creates an empty tracker.
* `update(timestamp, price)` sets the price at `timestamp` (overwriting any earlier value for that timestamp).
* `current()` returns the price at the **latest** timestamp seen.
* `maximum()` / `minimum()` return the highest / lowest price over all **current** records.

`current`, `maximum` and `minimum` are only called after at least one update.""",
    constraints=["1 ≤ timestamp, price ≤ 10⁹", "At most 10⁵ calls in total."],
    examples=[
        dict(args={"ops": ["StockPrice", "update", "update", "current", "maximum", "update", "maximum", "update", "minimum"],
                   "args": [[], [1, 10], [2, 5], [], [], [1, 3], [], [4, 2], []]},
             expected=[None, None, None, 5, 10, None, 5, None, 2],
             explanation="update(1, 3) corrects the price at time 1, so the maximum drops from 10 to 5."),
    ],
    hidden=[dict(args={"ops": ["StockPrice", "update", "update", "update", "current", "minimum", "maximum"], "args": [[], [5, 7], [3, 9], [5, 1], [], [], []]})],
    starter='''class StockPrice:

    def __init__(self):
        pass

    def update(self, timestamp: int, price: int) -> None:
        pass

    def current(self) -> int:
        pass

    def maximum(self) -> int:
        pass

    def minimum(self) -> int:
        pass
''',
    reference='''class StockPrice:
    def __init__(self):
        self.price = {}
        self.latest = 0
        self.maxh, self.minh = [], []

    def update(self, timestamp, price):
        self.price[timestamp] = price
        self.latest = max(self.latest, timestamp)
        heapq.heappush(self.maxh, (-price, timestamp))
        heapq.heappush(self.minh, (price, timestamp))

    def current(self):
        return self.price[self.latest]

    def maximum(self):
        while self.price[self.maxh[0][1]] != -self.maxh[0][0]:   # stale entry
            heapq.heappop(self.maxh)
        return -self.maxh[0][0]

    def minimum(self):
        while self.price[self.minh[0][1]] != self.minh[0][0]:
            heapq.heappop(self.minh)
        return self.minh[0][0]
''',
    brute='''class StockPrice:
    def __init__(self):
        self.p = {}

    def update(self, timestamp, price):
        self.p[timestamp] = price

    def current(self):
        return self.p[max(self.p)]

    def maximum(self):
        return max(self.p.values())

    def minimum(self):
        return min(self.p.values())
''',
    small_gen='''def gen(rng):
    ops, args = ["StockPrice", "update"], [[], [rng.randint(1, 5), rng.randint(1, 9)]]
    for _ in range(rng.randint(1, 14)):
        op = rng.choice(["update", "update", "current", "maximum", "minimum"])
        ops.append(op); args.append([rng.randint(1, 5), rng.randint(1, 9)] if op == "update" else [])
    return {"ops": ops, "args": args}
''',
    gens=[dict(name="100,000 operations", code='''def gen(rng):
    ops, args = ["StockPrice"], [[]]
    for i in range(100000):
        if i < 10 or rng.random() < 0.5:
            ops.append("update"); args.append([rng.randint(1, 50000), rng.randint(1, 10**9)])
        else:
            op = rng.choice(["current", "maximum", "minimum"]); ops.append(op); args.append([])
    return {"ops": ops, "args": args}
''')],
    hints=["A hash map timestamp → price handles corrections and current().",
           "Scanning all prices for max / min is O(n) per call — too slow for 10⁵ calls.",
           "Push every (price, timestamp) into a max-heap and a min-heap; when the top no longer matches the map, it is stale — pop it (lazy deletion)."],
    approach="""Map `timestamp → price`, plus the latest timestamp for `current()`. For `maximum()` / `minimum()` keep a max-heap and a min-heap of `(price, timestamp)` pairs. Corrections are not removed eagerly: when the top of a heap disagrees with the map, it is **stale**, so pop it and look again. Each pushed entry is popped at most once.

A sorted container (balanced BST / `SortedList`) keyed on price with counts is the other standard answer.""",
    complexity="O(log n) amortised per operation · O(n) space",
    followups=["Also report the average price.", "Maximum over the last T seconds only.",
               "Implement it with a balanced BST / sorted map instead of heaps."],
),

dict(
    id="lc295", num=295, title="Find Median from Data Stream", slug="find-median-from-data-stream", difficulty="Hard",
    topic="heaps", pattern="Two heaps", companies=["Google", "Meta"],
    kind="design", cls="MedianFinder", compare="float",
    statement="""Design a structure that receives integers one at a time and can report the **median** of everything received so far. With an even count, the median is the mean of the two middle values.

* `MedianFinder()` creates the structure.
* `addNum(num)` adds an integer.
* `findMedian()` returns the median (answers within 10⁻⁵ are accepted).""",
    constraints=["−10⁵ ≤ num ≤ 10⁵", "findMedian is only called after at least one addNum.", "At most 5 · 10⁴ calls."],
    examples=[
        dict(args={"ops": ["MedianFinder", "addNum", "addNum", "findMedian", "addNum", "findMedian"], "args": [[], [1], [2], [], [3], []]},
             expected=[None, None, None, 1.5, None, 2.0]),
    ],
    hidden=[dict(args={"ops": ["MedianFinder", "addNum", "findMedian", "addNum", "findMedian", "addNum", "findMedian"], "args": [[], [-1], [], [-2], [], [-3], []]})],
    starter='''class MedianFinder:

    def __init__(self):
        pass

    def addNum(self, num: int) -> None:
        pass

    def findMedian(self) -> float:
        pass
''',
    reference='''class MedianFinder:
    def __init__(self):
        self.lo = []          # max-heap (negated): smaller half
        self.hi = []          # min-heap: larger half

    def addNum(self, num):
        heapq.heappush(self.lo, -num)
        heapq.heappush(self.hi, -heapq.heappop(self.lo))
        if len(self.hi) > len(self.lo):
            heapq.heappush(self.lo, -heapq.heappop(self.hi))

    def findMedian(self):
        if len(self.lo) > len(self.hi):
            return float(-self.lo[0])
        return (-self.lo[0] + self.hi[0]) / 2
''',
    brute='''class MedianFinder:
    def __init__(self):
        self.a = []

    def addNum(self, num):
        self.a.append(num)

    def findMedian(self):
        b = sorted(self.a); n = len(b)
        return float(b[n // 2]) if n % 2 else (b[n // 2 - 1] + b[n // 2]) / 2
''',
    small_gen='''def gen(rng):
    ops, args = ["MedianFinder", "addNum"], [[], [rng.randint(-5, 5)]]
    for _ in range(rng.randint(1, 14)):
        if rng.random() < 0.6:
            ops.append("addNum"); args.append([rng.randint(-5, 5)])
        else:
            ops.append("findMedian"); args.append([])
    return {"ops": ops, "args": args}
''',
    gens=[dict(name="50,000 operations", code='''def gen(rng):
    ops, args = ["MedianFinder"], [[]]
    for i in range(50000):
        if i % 2 == 0:
            ops.append("addNum"); args.append([rng.randint(-10**5, 10**5)])
        else:
            ops.append("findMedian"); args.append([])
    return {"ops": ops, "args": args}
''')],
    hints=["Sorting on every findMedian is O(n log n) per query.",
           "Split the numbers into a lower half and an upper half.",
           "A max-heap for the lower half and a min-heap for the upper half expose both middle values at their roots. Keep sizes within one."],
    approach="""**Two heaps**: `lo` (max-heap) holds the smaller half and `hi` (min-heap) the larger half, with `len(lo)` equal to `len(hi)` or one more. To add, push into `lo`, move `lo`'s maximum to `hi` (so every low ≤ every high), and move one back if `hi` grew larger. The median is `lo`'s root, or the mean of both roots.""",
    complexity="O(log n) per addNum · O(1) per findMedian · O(n) space",
    followups=["All numbers are in [0, 100] — O(1) with counting.", "99% of numbers are in [0, 100].",
               "Median of a sliding window (#480) — deletions are now needed."],
),
]
