# Practice bank — binary search, sorting, heaps and intervals.

PROBLEMS = [
dict(
    id="lc162", num=162, title="Find Peak Element", slug="find-peak-element", difficulty="Medium", topic="sorting",
    pattern="Binary search on the slope", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="findPeakElement",
    params=[{"name": "nums", "type": "int[]"}], returns="int", compare="custom",
    statement="""A **peak** is an element strictly greater than its neighbours. Imagine `nums[-1] = nums[n] = −∞`. Neighbouring elements are never equal.

Return the index of **any** peak. Aim for O(log n) time.""",
    constraints=["1 ≤ nums.length ≤ 10⁵", "−2³¹ ≤ nums[i] ≤ 2³¹ − 1", "nums[i] ≠ nums[i + 1]"],
    examples=[
        dict(args=[[1, 2, 3, 1]], expected=2),
        dict(args=[[1, 2, 1, 3, 5, 6, 4]], expected=5, explanation="Index 1 is also a peak and is accepted."),
    ],
    hidden=[dict(args=[[1]]), dict(args=[[2, 1]]), dict(args=[[1, 2]]), dict(args=[[3, 4, 3, 2, 1]])],
    starter='''class Solution:
    def findPeakElement(self, nums: List[int]) -> int:
        pass
''',
    reference='''class Solution:
    def findPeakElement(self, nums):
        lo, hi = 0, len(nums) - 1
        while lo < hi:
            mid = (lo + hi) // 2
            if nums[mid] < nums[mid + 1]:
                lo = mid + 1          # uphill to the right: a peak exists there
            else:
                hi = mid
        return lo

def check(args, got, expected):
    nums = args[0]
    if not isinstance(got, int) or isinstance(got, bool) or not 0 <= got < len(nums):
        return False
    left = nums[got - 1] if got > 0 else float("-inf")
    right = nums[got + 1] if got + 1 < len(nums) else float("-inf")
    return nums[got] > left and nums[got] > right
''',
    brute='''class Solution:
    def findPeakElement(self, nums):
        return nums.index(max(nums))
''',
    small_gen='''def gen(rng):
    n = rng.randint(1, 9)
    a = [rng.randint(0, 5)]
    while len(a) < n:
        v = rng.randint(0, 5)
        if v != a[-1]:
            a.append(v)
    return [a]
''',
    gens=[dict(name="Large input (n = 100,000)", code='''def gen(rng):
    a = list(range(100000))
    a[-1] = -1
    return [a]
''')],
    hints=["Compare nums[mid] with nums[mid + 1].",
           "If the right neighbour is larger you are walking uphill — a peak must exist to the right.",
           "Otherwise a peak exists at mid or to its left. Halve the range each time."],
    approach="""**Binary search on the slope.** If `nums[mid] < nums[mid+1]`, the sequence rises to the right and, because `nums[n] = −∞`, must come down again — so a peak lies in `(mid, hi]`. Otherwise one lies in `[lo, mid]`. The range always contains a peak and shrinks by half each step.""",
    complexity="O(log n) time · O(1) space",
    followups=["Find a peak in a 2D grid (#1901).", "Why does the argument fail if neighbours can be equal?",
               "Return all peaks — what is the best possible time then?"],
),

dict(
    id="lc33", num=33, title="Search in Rotated Sorted Array", slug="search-in-rotated-sorted-array", difficulty="Medium",
    topic="sorting", pattern="Binary search — find the sorted half", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="search",
    params=[{"name": "nums", "type": "int[]"}, {"name": "target", "type": "int"}], returns="int",
    statement="""A sorted array of **distinct** integers was rotated at an unknown pivot (for example `[0,1,2,4,5,6,7]` → `[4,5,6,7,0,1,2]`). Return the index of `target`, or `-1` if it is absent.

Your algorithm must run in O(log n) time.""",
    constraints=["1 ≤ nums.length ≤ 5000", "All values are distinct."],
    examples=[
        dict(args=[[4, 5, 6, 7, 0, 1, 2], 0], expected=4),
        dict(args=[[4, 5, 6, 7, 0, 1, 2], 3], expected=-1),
        dict(args=[[1], 0], expected=-1),
    ],
    hidden=[dict(args=[[1, 3], 3]), dict(args=[[3, 1], 1]), dict(args=[[5, 1, 3], 5]), dict(args=[[1, 2, 3, 4, 5], 4])],
    starter='''class Solution:
    def search(self, nums: List[int], target: int) -> int:
        pass
''',
    reference='''class Solution:
    def search(self, nums, target):
        lo, hi = 0, len(nums) - 1
        while lo <= hi:
            mid = (lo + hi) // 2
            if nums[mid] == target:
                return mid
            if nums[lo] <= nums[mid]:               # left half sorted
                if nums[lo] <= target < nums[mid]:
                    hi = mid - 1
                else:
                    lo = mid + 1
            else:                                   # right half sorted
                if nums[mid] < target <= nums[hi]:
                    lo = mid + 1
                else:
                    hi = mid - 1
        return -1
''',
    brute='''class Solution:
    def search(self, nums, target):
        return nums.index(target) if target in nums else -1
''',
    small_gen='''def gen(rng):
    a = sorted(rng.sample(range(-10, 10), rng.randint(1, 8)))
    k = rng.randrange(len(a))
    a = a[k:] + a[:k]
    return [a, rng.choice(a) if rng.random() < 0.7 else rng.randint(-11, 11)]
''',
    hints=["At any mid, at least one half — [lo, mid] or [mid, hi] — is sorted.",
           "Check whether the target lies inside the sorted half's range.",
           "If it does, search that half; otherwise search the other half."],
    approach="""Ordinary binary search plus one question per step: **which half is sorted?** If `nums[lo] ≤ nums[mid]`, the left half is sorted and you can test `nums[lo] ≤ target < nums[mid]` directly; otherwise the right half is sorted. Discard the half that cannot contain the target.""",
    complexity="O(log n) time · O(1) space",
    followups=["Duplicates allowed (#81) — what is the worst case now?", "Find the rotation point / minimum (#153).",
               "Return the first and last index of the target in a rotated array with duplicates."],
),

dict(
    id="lc50", num=50, title="Pow(x, n)", slug="powx-n", difficulty="Medium", topic="recursion",
    pattern="Fast exponentiation", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="myPow",
    params=[{"name": "x", "type": "float"}, {"name": "n", "type": "int"}], returns="float", compare="float",
    statement="""Compute `x` raised to the integer power `n`, without using `**` or `pow()`.

Results are compared with a relative tolerance of 10⁻⁵.""",
    constraints=["−100 < x < 100", "−2³¹ ≤ n ≤ 2³¹ − 1", "x ≠ 0 or n > 0", "−10⁴ ≤ xⁿ ≤ 10⁴"],
    examples=[
        dict(args=[2.0, 10], expected=1024.0),
        dict(args=[2.1, 3], expected=9.261),
        dict(args=[2.0, -2], expected=0.25),
    ],
    hidden=[dict(args=[1.0, 2147483647], expected=1.0), dict(args=[-1.0, -2147483648], expected=1.0),
            dict(args=[2.0, -2147483648], expected=0.0), dict(args=[0.00001, 2147483647], expected=0.0),
            dict(args=[-2.0, 3], expected=-8.0), dict(args=[5.0, 0], expected=1.0), dict(args=[0.0, 5], expected=0.0)],
    starter='''class Solution:
    def myPow(self, x: float, n: int) -> float:
        pass
''',
    reference='''class Solution:
    def myPow(self, x, n):
        if n < 0:
            x, n = 1 / x, -n
        result = 1.0
        while n:
            if n & 1:
                result *= x
            x *= x
            n >>= 1
        return result
''',
    brute='''class Solution:
    def myPow(self, x, n):
        return float(x ** n)
''',
    small_gen='''def gen(rng):
    x = round(rng.uniform(-3, 3), 2) or 1.5
    return [x, rng.randint(-6, 6)]
''',
    hints=["Multiplying n times is far too slow when n is about two billion.",
           "x^n = (x^(n/2))² when n is even, and x · x^(n−1) when n is odd.",
           "For negative n, compute (1/x)^(−n)."],
    approach="""**Exponentiation by squaring.** Look at the bits of `n`: square `x` at every step, and multiply it into the result when the current bit is 1. That needs about log₂n multiplications. Handle a negative exponent by inverting `x` first (in Python `-n` cannot overflow; in Java / C++ use a 64-bit copy of `n`).""",
    complexity="O(log |n|) time · O(1) space (iterative)",
    followups=["Compute (xⁿ) mod m for huge n (modular exponentiation).", "Raise a 2×2 matrix to the n-th power to get Fibonacci in O(log n).",
               "Write the recursive version — what is its space complexity?"],
),

dict(
    id="lc215", num=215, title="Kth Largest Element in an Array", slug="kth-largest-element-in-an-array", difficulty="Medium",
    topic="heaps", pattern="Min-heap of size k / quickselect", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="findKthLargest",
    params=[{"name": "nums", "type": "int[]"}, {"name": "k", "type": "int"}], returns="int",
    statement="""Return the `k`-th largest element of `nums` — the element that would sit at position `k` if the array were sorted in **descending** order (duplicates count separately).

Can you do better than sorting?""",
    constraints=["1 ≤ k ≤ nums.length ≤ 10⁵", "−10⁴ ≤ nums[i] ≤ 10⁴"],
    examples=[
        dict(args=[[3, 2, 1, 5, 6, 4], 2], expected=5),
        dict(args=[[3, 2, 3, 1, 2, 4, 5, 5, 6], 4], expected=4),
    ],
    hidden=[dict(args=[[1], 1]), dict(args=[[2, 1], 2]), dict(args=[[7, 7, 7, 7], 3]), dict(args=[[-1, -5, 3], 1])],
    starter='''class Solution:
    def findKthLargest(self, nums: List[int], k: int) -> int:
        pass
''',
    reference='''class Solution:
    def findKthLargest(self, nums, k):
        heap = nums[:k]
        heapq.heapify(heap)
        for x in nums[k:]:
            if x > heap[0]:
                heapq.heapreplace(heap, x)
        return heap[0]
''',
    brute='''class Solution:
    def findKthLargest(self, nums, k):
        return sorted(nums, reverse=True)[k - 1]
''',
    small_gen='''def gen(rng):
    a = [rng.randint(-5, 5) for _ in range(rng.randint(1, 9))]
    return [a, rng.randint(1, len(a))]
''',
    gens=[dict(name="Large input (n = 100,000)", code='''def gen(rng):
    return [[rng.randint(-10000, 10000) for _ in range(100000)], 50000]
''')],
    hints=["Sorting works in O(n log n) — say it, then improve.",
           "Keep only the k largest seen so far in a min-heap; its root is the answer.",
           "Quickselect partitions like quicksort but recurses into one side only: O(n) on average."],
    approach="""**Min-heap of size k.** Keep the `k` largest values seen so far; the root is the smallest of them, i.e. the current k-th largest. A new value replaces the root only if it is larger. O(n log k) time, O(k) space.

**Quickselect** gives O(n) average: partition around a random pivot and recurse only into the side that contains position `n − k`.""",
    complexity="O(n log k) with a heap · O(n) average with quickselect",
    followups=["The numbers arrive as a stream (#703).", "Values are small integers — counting sort gives O(n + range).",
               "Why does quickselect degrade to O(n²), and how does randomisation help?"],
),

dict(
    id="lc973", num=973, title="K Closest Points to Origin", slug="k-closest-points-to-origin", difficulty="Medium",
    topic="heaps", pattern="Heap of size k", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="kClosest",
    params=[{"name": "points", "type": "int[][]"}, {"name": "k", "type": "int"}], returns="int[][]", compare="custom",
    statement="""Given points on the plane, return the `k` points closest to the origin `(0, 0)` by Euclidean distance, in any order.

If several points tie for the k-th place, any valid choice is accepted.""",
    constraints=["1 ≤ k ≤ points.length ≤ 10⁴", "−10⁴ ≤ xᵢ, yᵢ ≤ 10⁴"],
    examples=[
        dict(args=[[[1, 3], [-2, 2]], 1], expected=[[-2, 2]], explanation="Distances √10 and √8."),
        dict(args=[[[3, 3], [5, -1], [-2, 4]], 2], expected=[[3, 3], [-2, 4]]),
    ],
    hidden=[dict(args=[[[0, 1], [1, 0]], 2]), dict(args=[[[1, 1], [1, 1], [2, 2]], 2]), dict(args=[[[5, 5]], 1])],
    starter='''class Solution:
    def kClosest(self, points: List[List[int]], k: int) -> List[List[int]]:
        pass
''',
    reference='''class Solution:
    def kClosest(self, points, k):
        heap = []                                  # max-heap via negated distance
        for x, y in points:
            d = -(x * x + y * y)
            if len(heap) < k:
                heapq.heappush(heap, (d, x, y))
            elif d > heap[0][0]:
                heapq.heapreplace(heap, (d, x, y))
        return [[x, y] for _, x, y in heap]

def check(args, got, expected):
    points, k = args
    if not isinstance(got, list) or len(got) != k:
        return False
    pool = Counter(tuple(p) for p in points)
    for p in got:
        if not isinstance(p, list) or len(p) != 2 or pool[tuple(p)] == 0:
            return False
        pool[tuple(p)] -= 1
    dist = lambda p: p[0] * p[0] + p[1] * p[1]
    return sorted(map(dist, got)) == sorted(map(dist, points))[:k]
''',
    brute='''class Solution:
    def kClosest(self, points, k):
        return sorted(points, key=lambda p: p[0] * p[0] + p[1] * p[1])[:k]
''',
    small_gen='''def gen(rng):
    pts = [[rng.randint(-3, 3), rng.randint(-3, 3)] for _ in range(rng.randint(1, 8))]
    return [pts, rng.randint(1, len(pts))]
''',
    gens=[dict(name="10,000 points", code='''def gen(rng):
    return [[[rng.randint(-10000, 10000), rng.randint(-10000, 10000)] for _ in range(10000)], 100]
''')],
    hints=["Compare squared distances — no square root needed.",
           "Sorting all points is O(n log n). A max-heap holding k points is O(n log k).",
           "Quickselect on distance gives O(n) on average."],
    approach="""Keep a **max-heap of the k closest points** (Python: push negated squared distances). A new point enters only if it is closer than the farthest point in the heap, which it then replaces.""",
    complexity="O(n log k) time · O(k) space",
    followups=["Points arrive as a stream.", "k closest to an arbitrary point (x₀, y₀).", "Solve in O(n) average with quickselect."],
),

dict(
    id="lc347", num=347, title="Top K Frequent Elements", slug="top-k-frequent-elements", difficulty="Medium", topic="heaps",
    pattern="Counter + bucket sort / heap", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="topKFrequent",
    params=[{"name": "nums", "type": "int[]"}, {"name": "k", "type": "int"}], returns="int[]", compare="custom",
    statement="""Return the `k` most frequent elements of `nums`, in any order. If several elements tie for the last place, any of them may be chosen.

Your algorithm should be better than O(n log n).""",
    constraints=["1 ≤ nums.length ≤ 10⁵", "1 ≤ k ≤ number of distinct elements"],
    examples=[
        dict(args=[[1, 1, 1, 2, 2, 3], 2], expected=[1, 2]),
        dict(args=[[1], 1], expected=[1]),
    ],
    hidden=[dict(args=[[4, 4, 4, 5, 5, 6, 6], 2]), dict(args=[[-1, -1, 2], 1]), dict(args=[[1, 2, 3, 4], 4])],
    starter='''class Solution:
    def topKFrequent(self, nums: List[int], k: int) -> List[int]:
        pass
''',
    reference='''class Solution:
    def topKFrequent(self, nums, k):
        count = Counter(nums)
        buckets = [[] for _ in range(len(nums) + 1)]
        for x, c in count.items():
            buckets[c].append(x)
        out = []
        for c in range(len(buckets) - 1, 0, -1):
            for x in buckets[c]:
                out.append(x)
                if len(out) == k:
                    return out
        return out

def check(args, got, expected):
    nums, k = args
    if not isinstance(got, list) or len(got) != k or len(set(got)) != k:
        return False
    c = Counter(nums)
    if any(x not in c for x in got):
        return False
    return sorted((c[x] for x in got), reverse=True) == sorted(c.values(), reverse=True)[:k]
''',
    brute='''class Solution:
    def topKFrequent(self, nums, k):
        return [x for x, _ in Counter(nums).most_common(k)]
''',
    small_gen='''def gen(rng):
    a = [rng.randint(0, 4) for _ in range(rng.randint(1, 10))]
    return [a, rng.randint(1, len(set(a)))]
''',
    gens=[dict(name="Large input (n = 100,000)", code='''def gen(rng):
    return [[int(rng.paretovariate(1.2)) for _ in range(100000)], 5]
''')],
    hints=["First count frequencies with a hash map.",
           "A heap of size k over (frequency, value) gives O(n log k).",
           "Frequencies are between 1 and n — bucket the values by frequency for O(n)."],
    approach="""Count with a hash map, then **bucket by frequency**: `buckets[f]` lists values that occur exactly `f` times. Walk buckets from high to low frequency until `k` values are collected. A size-k min-heap keyed on frequency is the common alternative (O(n log k)).""",
    complexity="O(n) time · O(n) space",
    followups=["Top k frequent words, ties broken alphabetically (#692).", "The data is a stream too large for memory (Count-Min sketch).",
               "Return the elements sorted by frequency."],
),

dict(
    id="lc56", num=56, title="Merge Intervals", slug="merge-intervals", difficulty="Medium", topic="sorting",
    pattern="Sort by start, then sweep", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="merge",
    params=[{"name": "intervals", "type": "int[][]"}], returns="int[][]", compare="unordered",
    statement="""Merge all overlapping intervals `[start, end]` and return the non-overlapping intervals that cover exactly the same ranges. Intervals that touch (`[1,4]` and `[4,5]`) overlap.""",
    constraints=["1 ≤ intervals.length ≤ 10⁴", "0 ≤ start ≤ end ≤ 10⁴"],
    examples=[
        dict(args=[[[1, 3], [2, 6], [8, 10], [15, 18]]], expected=[[1, 6], [8, 10], [15, 18]]),
        dict(args=[[[1, 4], [4, 5]]], expected=[[1, 5]]),
    ],
    hidden=[dict(args=[[[1, 4], [0, 4]]]), dict(args=[[[1, 4], [2, 3]]]), dict(args=[[[5, 5], [1, 2]]]), dict(args=[[[1, 10], [2, 3], [4, 5], [11, 12]]])],
    starter='''class Solution:
    def merge(self, intervals: List[List[int]]) -> List[List[int]]:
        pass
''',
    reference='''class Solution:
    def merge(self, intervals):
        intervals = sorted(intervals)
        out = [list(intervals[0])]
        for s, e in intervals[1:]:
            if s <= out[-1][1]:
                out[-1][1] = max(out[-1][1], e)
            else:
                out.append([s, e])
        return out
''',
    brute='''class Solution:
    def merge(self, intervals):
        items = [list(x) for x in intervals]
        changed = True
        while changed:
            changed = False
            for i in range(len(items)):
                for j in range(i + 1, len(items)):
                    a, b = items[i], items[j]
                    if a[0] <= b[1] and b[0] <= a[1]:
                        items[i] = [min(a[0], b[0]), max(a[1], b[1])]
                        items.pop(j)
                        changed = True
                        break
                if changed:
                    break
        return items
''',
    small_gen='''def gen(rng):
    out = []
    for _ in range(rng.randint(1, 7)):
        s = rng.randint(0, 10); out.append([s, s + rng.randint(0, 4)])
    return [out]
''',
    gens=[dict(name="10,000 intervals", code='''def gen(rng):
    out = []
    for _ in range(10000):
        s = rng.randint(0, 10000); out.append([s, min(10000, s + rng.randint(0, 3))])
    return [out]
''')],
    hints=["Sort by start time first.", "Then every interval can only overlap the last merged one.",
           "Overlap test after sorting: start ≤ last end. Extend the end with max()."],
    approach="""**Sort by start, then sweep.** After sorting, an interval either overlaps the last interval in the output (`start ≤ last.end`) — extend it with `max` — or starts a new one.""",
    complexity="O(n log n) time · O(n) space",
    followups=["Insert one new interval into an already merged list (#57) in O(n).", "Intervals arrive as a stream (#352).",
               "Return the total length covered."],
),

dict(
    id="lc253", num=253, title="Meeting Rooms II", slug="meeting-rooms-ii", difficulty="Medium", topic="heaps",
    pattern="Sort + min-heap of end times (or sweep line)", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="minMeetingRooms",
    params=[{"name": "intervals", "type": "int[][]"}], returns="int",
    statement="""Each meeting is `[start, end)`: it occupies a room from `start` up to, but not including, `end` — so a meeting ending at 10 and one starting at 10 can share a room.

Return the minimum number of rooms needed to hold all meetings.""",
    constraints=["1 ≤ intervals.length ≤ 10⁴", "0 ≤ start < end ≤ 10⁶"],
    examples=[
        dict(args=[[[0, 30], [5, 10], [15, 20]]], expected=2),
        dict(args=[[[7, 10], [2, 4]]], expected=1),
    ],
    hidden=[dict(args=[[[1, 5], [5, 10]]]), dict(args=[[[1, 10], [2, 9], [3, 8]]]), dict(args=[[[9, 10], [4, 9], [4, 17]]])],
    starter='''class Solution:
    def minMeetingRooms(self, intervals: List[List[int]]) -> int:
        pass
''',
    reference='''class Solution:
    def minMeetingRooms(self, intervals):
        intervals = sorted(intervals)
        ends = []
        for s, e in intervals:
            if ends and ends[0] <= s:
                heapq.heapreplace(ends, e)
            else:
                heapq.heappush(ends, e)
        return len(ends)
''',
    brute='''class Solution:
    def minMeetingRooms(self, intervals):
        best = 0
        for t in set(x for iv in intervals for x in iv):
            best = max(best, sum(1 for s, e in intervals if s <= t < e))
        return best
''',
    small_gen='''def gen(rng):
    out = []
    for _ in range(rng.randint(1, 7)):
        s = rng.randint(0, 10); out.append([s, s + rng.randint(1, 5)])
    return [out]
''',
    gens=[dict(name="10,000 meetings", code='''def gen(rng):
    out = []
    for _ in range(10000):
        s = rng.randint(0, 10**6 - 1000); out.append([s, s + rng.randint(1, 1000)])
    return [out]
''')],
    hints=["Process meetings in order of start time.",
           "Keep the end times of meetings currently in progress in a min-heap.",
           "If the earliest-ending room is free by the new start time, reuse it; otherwise open a room. Heap size = answer."],
    approach="""Sort by start. A **min-heap of end times** holds the rooms in use. For each meeting, if the room that frees up first is available (`ends[0] ≤ start`) reuse it, else add a room. The heap's final size is the peak number of simultaneous meetings.

**Sweep line** alternative: sort all starts and all ends separately and walk them with two pointers.""",
    complexity="O(n log n) time · O(n) space",
    followups=["Return which room each meeting goes to.", "Can one person attend all meetings? (#252)",
               "Rooms have capacities and meetings have sizes."],
),
]
