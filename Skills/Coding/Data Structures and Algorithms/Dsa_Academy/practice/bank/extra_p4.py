# Practice bank — matrices, sweep lines, randomised algorithms, range queries, iterators and
# more Meta / Google-reported problems.

PROBLEMS = [
dict(
    id="lc54", num=54, title="Spiral Matrix", slug="spiral-matrix", difficulty="Medium", topic="matrix",
    pattern="Shrinking boundaries", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="spiralOrder",
    params=[{"name": "matrix", "type": "int[][]"}], returns="int[]",
    statement="""Return all elements of the `m × n` matrix in **spiral order**: along the top row left to right, down the right column, along the bottom row right to left, up the left column, then continue inwards.""",
    constraints=["1 ≤ m, n ≤ 10", "−100 ≤ matrix[i][j] ≤ 100"],
    examples=[
        dict(args=[[[1, 2, 3], [4, 5, 6], [7, 8, 9]]], expected=[1, 2, 3, 6, 9, 8, 7, 4, 5]),
        dict(args=[[[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11, 12]]], expected=[1, 2, 3, 4, 8, 12, 11, 10, 9, 5, 6, 7]),
    ],
    hidden=[dict(args=[[[1]]]), dict(args=[[[1, 2, 3]]]), dict(args=[[[1], [2], [3]]]), dict(args=[[[1, 2], [3, 4], [5, 6]]])],
    starter='''class Solution:
    def spiralOrder(self, matrix: List[List[int]]) -> List[int]:
        pass
''',
    reference='''class Solution:
    def spiralOrder(self, matrix):
        out = []
        top, bottom, left, right = 0, len(matrix) - 1, 0, len(matrix[0]) - 1
        while top <= bottom and left <= right:
            for c in range(left, right + 1):
                out.append(matrix[top][c])
            for r in range(top + 1, bottom + 1):
                out.append(matrix[r][right])
            if top < bottom:
                for c in range(right - 1, left - 1, -1):
                    out.append(matrix[bottom][c])
            if left < right:
                for r in range(bottom - 1, top, -1):
                    out.append(matrix[r][left])
            top, bottom, left, right = top + 1, bottom - 1, left + 1, right - 1
        return out
''',
    brute='''class Solution:
    def spiralOrder(self, matrix):
        R, C = len(matrix), len(matrix[0])
        seen = [[False] * C for _ in range(R)]
        dr, dc = [0, 1, 0, -1], [1, 0, -1, 0]
        r = c = d = 0
        out = []
        for _ in range(R * C):
            out.append(matrix[r][c]); seen[r][c] = True
            nr, nc = r + dr[d], c + dc[d]
            if not (0 <= nr < R and 0 <= nc < C) or seen[nr][nc]:
                d = (d + 1) % 4
                nr, nc = r + dr[d], c + dc[d]
            r, c = nr, nc
        return out
''',
    small_gen='''def gen(rng):
    R, C = rng.randint(1, 6), rng.randint(1, 6)
    return [[[rng.randint(-9, 9) for _ in range(C)] for _ in range(R)]]
''',
    hints=["Keep four boundaries: top, bottom, left, right.",
           "Walk one side, then move that boundary inwards.",
           "Single remaining rows or columns are where off-by-one bugs live — guard the bottom and left walks."],
    approach="""Maintain `top, bottom, left, right`. Each lap walks the top row, the right column, the bottom row (only if `top < bottom`) and the left column (only if `left < right`), then shrinks all four boundaries. The two guards stop a single leftover row or column from being read twice.""",
    complexity="O(m · n) time · O(1) extra space",
    followups=["Generate an n × n spiral matrix (#59).", "Spiral from the centre outwards.", "Rotate the matrix 90° in place (#48)."],
),

dict(
    id="lc498", num=498, title="Diagonal Traverse", slug="diagonal-traverse", difficulty="Medium", topic="matrix",
    pattern="Group by i + j, alternate direction", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="findDiagonalOrder",
    params=[{"name": "mat", "type": "int[][]"}], returns="int[]",
    statement="""Return all elements of `mat` in **zig-zag diagonal order**: the first anti-diagonal goes up-right, the next goes down-left, and so on, alternating.""",
    constraints=["1 ≤ m, n ≤ 10⁴", "1 ≤ m · n ≤ 10⁴"],
    examples=[
        dict(args=[[[1, 2, 3], [4, 5, 6], [7, 8, 9]]], expected=[1, 2, 4, 7, 5, 3, 6, 8, 9]),
        dict(args=[[[1, 2], [3, 4]]], expected=[1, 2, 3, 4]),
    ],
    hidden=[dict(args=[[[5]]]), dict(args=[[[1, 2, 3, 4]]]), dict(args=[[[1], [2], [3]]]), dict(args=[[[1, 2, 3], [4, 5, 6]]])],
    starter='''class Solution:
    def findDiagonalOrder(self, mat: List[List[int]]) -> List[int]:
        pass
''',
    reference='''class Solution:
    def findDiagonalOrder(self, mat):
        R, C = len(mat), len(mat[0])
        out = []
        for d in range(R + C - 1):
            # cells with r + c == d, listed with r increasing
            r0, r1 = max(0, d - C + 1), min(R - 1, d)
            diag = [mat[r][d - r] for r in range(r0, r1 + 1)]
            out.extend(diag[::-1] if d % 2 == 0 else diag)
        return out
''',
    brute='''class Solution:
    def findDiagonalOrder(self, mat):
        R, C = len(mat), len(mat[0])
        r = c = 0
        up = True
        out = []
        while len(out) < R * C:
            out.append(mat[r][c])
            if up:
                if c == C - 1: r += 1; up = False
                elif r == 0: c += 1; up = False
                else: r -= 1; c += 1
            else:
                if r == R - 1: c += 1; up = True
                elif c == 0: r += 1; up = True
                else: r += 1; c -= 1
        return out
''',
    small_gen='''def gen(rng):
    R, C = rng.randint(1, 6), rng.randint(1, 6)
    return [[[rng.randint(0, 9) for _ in range(C)] for _ in range(R)]]
''',
    hints=["All cells on one anti-diagonal share the same r + c.",
           "Collect each diagonal top-to-bottom, then reverse every other one.",
           "Or simulate: moving up-right until you hit a wall, then turn — the walls decide whether r or c advances."],
    approach="""Every anti-diagonal has a constant `d = r + c`, from 0 to `m + n − 2`. For each `d`, list its cells with `r` increasing (which is the down-left direction) and reverse the list when `d` is even, giving the up-right direction. Concatenate.""",
    complexity="O(m · n) time · O(min(m, n)) extra space",
    followups=["Diagonal Traverse II (#1424) with ragged rows.", "Do it with O(1) extra space by simulating the walk.",
               "Sort each diagonal of a matrix (#1329)."],
),

dict(
    id="lc153", num=153, title="Find Minimum in Rotated Sorted Array", slug="find-minimum-in-rotated-sorted-array",
    difficulty="Medium", topic="sorting", pattern="Binary search against the right end", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="findMin",
    params=[{"name": "nums", "type": "int[]"}], returns="int",
    statement="""A sorted array of **distinct** integers has been rotated between 1 and n times. Return its minimum element in O(log n) time.""",
    constraints=["1 ≤ n ≤ 5000", "All values are distinct."],
    examples=[
        dict(args=[[3, 4, 5, 1, 2]], expected=1),
        dict(args=[[4, 5, 6, 7, 0, 1, 2]], expected=0),
        dict(args=[[11, 13, 15, 17]], expected=11, explanation="Rotated n times — back to sorted."),
    ],
    hidden=[dict(args=[[1]]), dict(args=[[2, 1]]), dict(args=[[1, 2]]), dict(args=[[5, 1, 2, 3, 4]])],
    starter='''class Solution:
    def findMin(self, nums: List[int]) -> int:
        pass
''',
    reference='''class Solution:
    def findMin(self, nums):
        lo, hi = 0, len(nums) - 1
        while lo < hi:
            mid = (lo + hi) // 2
            if nums[mid] > nums[hi]:
                lo = mid + 1          # minimum is to the right of mid
            else:
                hi = mid              # mid could be the minimum
        return nums[lo]
''',
    brute='''class Solution:
    def findMin(self, nums):
        return min(nums)
''',
    small_gen='''def gen(rng):
    a = sorted(rng.sample(range(-20, 20), rng.randint(1, 9)))
    k = rng.randrange(len(a))
    return [a[k:] + a[:k]]
''',
    hints=["Compare nums[mid] with nums[hi], not nums[lo].",
           "If nums[mid] > nums[hi], the drop (and the minimum) is strictly to the right of mid.",
           "Otherwise mid..hi is sorted, so the minimum is at mid or to its left — keep mid."],
    approach="""Binary search for the **rotation point**. If `nums[mid] > nums[hi]`, the array drops somewhere after `mid`, so `lo = mid + 1`. Otherwise `[mid, hi]` is sorted and the minimum is at or before `mid`, so `hi = mid`. When `lo == hi` it points at the minimum.""",
    complexity="O(log n) time · O(1) space",
    followups=["Duplicates allowed (#154) — worst case becomes O(n). Why?", "Return the number of rotations.",
               "Use the rotation point to search for a target (#33)."],
),

dict(
    id="lc528", num=528, title="Random Pick with Weight", slug="random-pick-with-weight", difficulty="Medium",
    topic="random", pattern="Prefix sums + binary search", companies=["Meta", "Google"],
    kind="design", cls="Solution", ctor_types=["int[]"], compare="custom", time_factor=8,
    statement="""You are given positive weights `w`. Implement `pickIndex()`, which returns index `i` with probability `w[i] / sum(w)`.

* `Solution(w)` stores the weights.
* `pickIndex()` returns a random index according to the weights.

Outputs are random, so the judge checks that every index is valid and — on large tests — that the observed frequencies match the weights.""",
    constraints=["1 ≤ w.length ≤ 10⁴", "1 ≤ w[i] ≤ 10⁵", "pickIndex is called at most 10⁴ times per test (more on the large statistical tests)."],
    examples=[
        dict(args={"ops": ["Solution", "pickIndex"], "args": [[[1]], []]}, expected=[None, 0]),
        dict(args={"ops": ["Solution", "pickIndex", "pickIndex", "pickIndex", "pickIndex", "pickIndex"], "args": [[[1, 3]], [], [], [], [], []]},
             expected=[None, 1, 1, 1, 1, 0], explanation="Index 1 should come up about 75% of the time; any sequence of valid indices is accepted here."),
    ],
    hidden=[dict(args={"ops": ["Solution"] + ["pickIndex"] * 6000, "args": [[[1, 9]]] + [[]] * 6000}),
            dict(args={"ops": ["Solution"] + ["pickIndex"] * 6000, "args": [[[5, 1, 1, 3]]] + [[]] * 6000})],
    starter='''class Solution:

    def __init__(self, w: List[int]):
        pass

    def pickIndex(self) -> int:
        pass
''',
    reference='''class Solution:
    def __init__(self, w):
        self.prefix = list(itertools.accumulate(w))
        self.total = self.prefix[-1]

    def pickIndex(self):
        target = random.random() * self.total
        return bisect.bisect_right(self.prefix, target)

def check(args, got, expected):
    w = args["args"][0][0]
    if not isinstance(got, list) or len(got) != len(args["ops"]):
        return False
    picks = got[1:]
    for x in picks:
        if not isinstance(x, int) or isinstance(x, bool) or not 0 <= x < len(w):
            return False
    n = len(picks)
    if n >= 2000:
        tot, c = sum(w), Counter(picks)
        for i, wi in enumerate(w):
            p = wi / tot
            if abs(c[i] / n - p) > 5 * math.sqrt(p * (1 - p) / n) + 0.002:
                return False
    return True
''',
    brute='''class Solution:
    def __init__(self, w):
        self.w = w
    def pickIndex(self):
        return random.choices(range(len(self.w)), weights=self.w)[0]
''',
    small_gen='''def gen(rng):
    w = [rng.randint(1, 5) for _ in range(rng.randint(1, 5))]
    k = rng.randint(1, 8)
    return {"ops": ["Solution"] + ["pickIndex"] * k, "args": [[w]] + [[]] * k}
''',
    small_n=100,
    gens=[dict(name="10,000 weights, 30,000 picks", code='''def gen(rng):
    w = [rng.randint(1, 100) for _ in range(10000)]
    return {"ops": ["Solution"] + ["pickIndex"] * 30000, "args": [[w]] + [[]] * 30000}
''')],
    hints=["Imagine laying the weights end to end on a number line of length sum(w).",
           "Pick a random point on that line; the segment it falls into is the index.",
           "Prefix sums mark segment ends; binary search finds the segment in O(log n)."],
    approach="""Build **prefix sums** once: `prefix[i]` is the end of segment `i` on a line of length `total`. For each pick draw `t = random() · total` and return the first index whose prefix exceeds `t` — `bisect_right(prefix, t)`. Index `i` owns an interval of length `w[i]`, so it is chosen with probability `w[i] / total`.

A linear scan per pick is correct but O(n) per call; with 10⁴ weights and 3 · 10⁴ picks it is too slow.""",
    complexity="O(n) build · O(log n) per pick · O(n) space",
    followups=["Weights change between picks — use a Fenwick tree for O(log n) updates.", "O(1) per pick: the alias method.",
               "Pick k distinct indices without replacement."],
),

dict(
    id="lc398", num=398, title="Random Pick Index", slug="random-pick-index", difficulty="Medium", topic="random",
    pattern="Hash map of positions / reservoir sampling", companies=["Meta"],
    kind="design", cls="Solution", ctor_types=["int[]"], compare="custom",
    statement="""`nums` may contain duplicates. Implement `pick(target)`, which returns a uniformly random index `i` with `nums[i] == target`. The target always exists.

* `Solution(nums)` stores the array.
* `pick(target)` returns a random matching index; each matching index must be equally likely.""",
    constraints=["1 ≤ nums.length ≤ 2 · 10⁴", "−2³¹ ≤ nums[i] ≤ 2³¹ − 1", "target is in nums", "At most 10⁴ calls to pick."],
    examples=[
        dict(args={"ops": ["Solution", "pick", "pick", "pick"], "args": [[[1, 2, 3, 3, 3]], [3], [1], [3]]},
             expected=[None, 4, 0, 2], explanation="pick(3) may return 2, 3 or 4, each with probability 1/3."),
    ],
    hidden=[dict(args={"ops": ["Solution"] + ["pick"] * 4000, "args": [[[5, 5, 1, 5]]] + [[5]] * 4000})],
    starter='''class Solution:

    def __init__(self, nums: List[int]):
        pass

    def pick(self, target: int) -> int:
        pass
''',
    reference='''class Solution:
    def __init__(self, nums):
        self.pos = defaultdict(list)
        for i, x in enumerate(nums):
            self.pos[x].append(i)

    def pick(self, target):
        return random.choice(self.pos[target])

def check(args, got, expected):
    nums = args["args"][0][0]
    if not isinstance(got, list) or len(got) != len(args["ops"]):
        return False
    by_target = defaultdict(list)
    for a, x in zip(args["args"][1:], got[1:]):
        t = a[0]
        if not isinstance(x, int) or isinstance(x, bool) or not 0 <= x < len(nums) or nums[x] != t:
            return False
        by_target[t].append(x)
    for t, xs in by_target.items():
        cand = [i for i, v in enumerate(nums) if v == t]
        n = len(xs)
        if n >= 2000 and len(cand) > 1:
            p, c = 1 / len(cand), Counter(xs)
            for i in cand:
                if abs(c[i] / n - p) > 5 * math.sqrt(p * (1 - p) / n) + 0.002:
                    return False
    return True
''',
    brute='''class Solution:
    def __init__(self, nums):
        self.nums = nums
    def pick(self, target):
        chosen, seen = -1, 0
        for i, x in enumerate(self.nums):          # reservoir sampling, O(1) extra space
            if x == target:
                seen += 1
                if random.randrange(seen) == 0:
                    chosen = i
        return chosen
''',
    small_gen='''def gen(rng):
    nums = [rng.randint(0, 3) for _ in range(rng.randint(1, 8))]
    k = rng.randint(1, 6)
    return {"ops": ["Solution"] + ["pick"] * k, "args": [[nums]] + [[rng.choice(nums)] for _ in range(k)]}
''',
    small_n=100,
    gens=[dict(name="20,000 numbers, 200 picks", code='''def gen(rng):
    nums = [rng.randint(0, 50) for _ in range(20000)]
    return {"ops": ["Solution"] + ["pick"] * 200, "args": [[nums]] + [[rng.choice(nums)] for _ in range(200)]}
''')],
    hints=["Simplest: map each value to the list of its indices, then choose uniformly from that list.",
           "That uses O(n) extra memory. The follow-up asks for O(1) extra space.",
           "Reservoir sampling: scan, and when you see the k-th match, keep it with probability 1/k."],
    approach="""**Hash map of positions**: precompute `value → [indices]`, then `random.choice` — O(1) per pick, O(n) memory.

**Reservoir sampling** (O(1) extra space): scan the array; on the k-th occurrence of `target`, replace the current choice with probability `1/k`. Each of the m matches ends up chosen with probability exactly `1/m`, but every pick costs O(n).""",
    complexity="Hash map: O(n) build, O(1) per pick · Reservoir: O(n) per pick, O(1) space",
    followups=["Prove that reservoir sampling is uniform.", "Pick k indices uniformly from a stream of unknown length (reservoir of size k).",
               "Linked List Random Node (#382)."],
),

dict(
    id="lc986", num=986, title="Interval List Intersections", slug="interval-list-intersections", difficulty="Medium",
    topic="matrix", pattern="Two pointers over sorted intervals", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="intervalIntersection",
    params=[{"name": "firstList", "type": "int[][]"}, {"name": "secondList", "type": "int[][]"}], returns="int[][]",
    statement="""Each list holds closed intervals `[start, end]` that are **sorted and pairwise disjoint**. Return the intersection of the two lists — every interval where both lists overlap — in sorted order.""",
    constraints=["0 ≤ firstList.length, secondList.length ≤ 1000", "0 ≤ start ≤ end ≤ 10⁹"],
    examples=[
        dict(args=[[[0, 2], [5, 10], [13, 23], [24, 25]], [[1, 5], [8, 12], [15, 24], [25, 26]]],
             expected=[[1, 2], [5, 5], [8, 10], [15, 23], [24, 24], [25, 25]]),
        dict(args=[[[1, 3], [5, 9]], []], expected=[]),
    ],
    hidden=[dict(args=[[[1, 7]], [[3, 10]]]), dict(args=[[[3, 5], [9, 20]], [[4, 5], [7, 10], [11, 12], [14, 15], [16, 20]]]), dict(args=[[], []])],
    starter='''class Solution:
    def intervalIntersection(self, firstList: List[List[int]], secondList: List[List[int]]) -> List[List[int]]:
        pass
''',
    reference='''class Solution:
    def intervalIntersection(self, A, B):
        i = j = 0
        out = []
        while i < len(A) and j < len(B):
            lo, hi = max(A[i][0], B[j][0]), min(A[i][1], B[j][1])
            if lo <= hi:
                out.append([lo, hi])
            if A[i][1] < B[j][1]:          # the interval that ends first can't overlap anything else
                i += 1
            else:
                j += 1
        return out
''',
    brute='''class Solution:
    def intervalIntersection(self, A, B):
        out = []
        for a in A:
            for b in B:
                lo, hi = max(a[0], b[0]), min(a[1], b[1])
                if lo <= hi:
                    out.append([lo, hi])
        return sorted(out)
''',
    small_gen='''def gen(rng):
    def lst():
        out, x = [], rng.randint(0, 3)
        for _ in range(rng.randint(0, 4)):
            a = x + rng.randint(0, 2); b = a + rng.randint(0, 3)
            out.append([a, b]); x = b + 1
        return out
    return [lst(), lst()]
''',
    hints=["Use one pointer per list.",
           "The overlap of two intervals is [max(starts), min(ends)] when that is non-empty.",
           "Advance the pointer whose interval ends first — it cannot overlap anything further in the other list."],
    approach="""Two pointers. For the current pair, the intersection is `[max(a₀, b₀), min(a₁, b₁)]` if non-empty. Then drop whichever interval **ends first**: every later interval in the other list starts after the current one, so it cannot meet the finished interval again.""",
    complexity="O(m + n) time · O(1) extra space",
    followups=["Union of the two lists instead.", "k lists at once (use a heap).", "Free time common to all employees (#759)."],
),

dict(
    id="lc1094", num=1094, title="Car Pooling", slug="car-pooling", difficulty="Medium", topic="matrix",
    pattern="Sweep line / difference array", companies=["Google", "Meta"],
    kind="function", cls="Solution", method="carPooling",
    params=[{"name": "trips", "type": "int[][]"}, {"name": "capacity", "type": "int"}], returns="bool",
    statement="""A car drives only east and has `capacity` empty seats. `trips[i] = [numPassengers, from, to]`: that many passengers board at kilometre `from` and leave at kilometre `to`.

Return `true` if every trip can be completed without ever exceeding the capacity.""",
    constraints=["1 ≤ trips.length ≤ 1000", "1 ≤ numPassengers ≤ 100", "0 ≤ from < to ≤ 1000", "1 ≤ capacity ≤ 10⁵"],
    examples=[
        dict(args=[[[2, 1, 5], [3, 3, 7]], 4], expected=False),
        dict(args=[[[2, 1, 5], [3, 3, 7]], 5], expected=True),
    ],
    hidden=[dict(args=[[[2, 1, 5], [3, 5, 7]], 3], expected=True), dict(args=[[[3, 2, 7], [3, 7, 9], [8, 3, 9]], 11], expected=True),
            dict(args=[[[9, 0, 1], [3, 3, 7]], 4], expected=False)],
    starter='''class Solution:
    def carPooling(self, trips: List[List[int]], capacity: int) -> bool:
        pass
''',
    reference='''class Solution:
    def carPooling(self, trips, capacity):
        events = []
        for n, a, b in trips:
            events.append((a, n))
            events.append((b, -n))
        load = 0
        for _, d in sorted(events):        # drop-offs sort before pick-ups at the same km
            load += d
            if load > capacity:
                return False
        return True
''',
    brute='''class Solution:
    def carPooling(self, trips, capacity):
        for km in range(1001):
            if sum(n for n, a, b in trips if a <= km < b) > capacity:
                return False
        return True
''',
    small_gen='''def gen(rng):
    trips = []
    for _ in range(rng.randint(1, 5)):
        a = rng.randint(0, 8); trips.append([rng.randint(1, 5), a, a + rng.randint(1, 4)])
    return [trips, rng.randint(1, 12)]
''',
    hints=["Only the kilometres where someone boards or leaves matter.",
           "Turn each trip into two events: +n at `from`, −n at `to`.",
           "Sort the events and keep a running load; at equal positions, process drop-offs first."],
    approach="""**Sweep line.** Each trip adds `+n` at `from` and `−n` at `to`. Sort the events by position — tuples sort `(km, −n)` before `(km, +n)`, so passengers leave before new ones board at the same stop — and keep a running total; it must never exceed `capacity`.

Because positions are at most 1000, a **difference array** of size 1001 gives O(n + 1000) without sorting.""",
    complexity="O(n log n) with sorting, O(n + K) with a difference array · O(n) space",
    followups=["Return the busiest stretch of road.", "Meeting Rooms II (#253) is the same sweep.", "Multiple cars — minimum number needed."],
),

dict(
    id="lc307", num=307, title="Range Sum Query - Mutable", slug="range-sum-query-mutable", difficulty="Medium",
    topic="rangeq", pattern="Fenwick tree (binary indexed tree)", companies=["Google", "Meta"],
    kind="design", cls="NumArray", ctor_types=["int[]"], time_factor=4,
    statement="""Support point updates and range-sum queries on an array.

* `NumArray(nums)` initialises the structure.
* `update(index, val)` sets `nums[index] = val`.
* `sumRange(left, right)` returns `nums[left] + … + nums[right]` (inclusive).

Both operations should take O(log n).""",
    constraints=["1 ≤ nums.length ≤ 10⁵", "−100 ≤ nums[i], val ≤ 100", "At most 5 · 10⁴ calls in total."],
    examples=[
        dict(args={"ops": ["NumArray", "sumRange", "update", "sumRange"], "args": [[[1, 3, 5]], [0, 2], [1, 2], [0, 2]]},
             expected=[None, 9, None, 8]),
    ],
    hidden=[dict(args={"ops": ["NumArray", "sumRange", "update", "update", "sumRange", "sumRange"], "args": [[[-1]], [0, 0], [0, 1], [0, 5], [0, 0], [0, 0]]})],
    starter='''class NumArray:

    def __init__(self, nums: List[int]):
        pass

    def update(self, index: int, val: int) -> None:
        pass

    def sumRange(self, left: int, right: int) -> int:
        pass
''',
    reference='''class NumArray:
    def __init__(self, nums):
        self.n = len(nums)
        self.a = list(nums)
        self.t = [0] * (self.n + 1)
        for i, x in enumerate(nums):          # O(n) build
            j = i + 1
            self.t[j] += x
            k = j + (j & -j)
            if k <= self.n:
                self.t[k] += self.t[j]

    def _prefix(self, i):                      # sum of first i values
        s = 0
        while i > 0:
            s += self.t[i]
            i -= i & -i
        return s

    def update(self, index, val):
        d = val - self.a[index]
        self.a[index] = val
        i = index + 1
        while i <= self.n:
            self.t[i] += d
            i += i & -i

    def sumRange(self, left, right):
        return self._prefix(right + 1) - self._prefix(left)
''',
    brute='''class NumArray:
    def __init__(self, nums):
        self.a = list(nums)
    def update(self, index, val):
        self.a[index] = val
    def sumRange(self, left, right):
        return sum(self.a[left:right + 1])
''',
    small_gen='''def gen(rng):
    n = rng.randint(1, 8)
    nums = [rng.randint(-5, 5) for _ in range(n)]
    ops, args = ["NumArray"], [[nums]]
    for _ in range(rng.randint(1, 12)):
        if rng.random() < 0.5:
            ops.append("update"); args.append([rng.randrange(n), rng.randint(-5, 5)])
        else:
            l = rng.randrange(n); ops.append("sumRange"); args.append([l, rng.randint(l, n - 1)])
    return {"ops": ops, "args": args}
''',
    gens=[dict(name="n = 100,000 with 50,000 operations", code='''def gen(rng):
    n = 100000
    nums = [rng.randint(-100, 100) for _ in range(n)]
    ops, args = ["NumArray"], [[nums]]
    for _ in range(50000):
        if rng.random() < 0.5:
            ops.append("update"); args.append([rng.randrange(n), rng.randint(-100, 100)])
        else:
            l = rng.randrange(n // 4); ops.append("sumRange"); args.append([l, rng.randint(n // 2, n - 1)])
    return {"ops": ops, "args": args}
''')],
    hints=["Prefix sums make queries O(1) but updates O(n); a plain array is the reverse.",
           "A Fenwick tree stores partial sums so that both cost O(log n).",
           "i & -i is the lowest set bit: add it to climb for updates, subtract it to descend for prefix sums."],
    approach="""**Fenwick tree (binary indexed tree).** Cell `t[i]` (1-based) stores the sum of the `i & −i` values ending at `i`.

* `prefix(i)`: add `t[i]` and jump `i −= i & −i` until 0 — O(log n) cells.
* `update(i, Δ)`: add `Δ` to `t[i]` and jump `i += i & −i` until past n.

`sumRange(l, r) = prefix(r + 1) − prefix(l)`. A segment tree is the more general alternative (min / max queries, lazy range updates).""",
    complexity="O(n) build · O(log n) per update and query · O(n) space",
    followups=["Range minimum with updates — segment tree.", "Add a value to a whole range (range update, point query).",
               "2D version (#308).", "Count of smaller numbers after self (#315) using a Fenwick tree."],
),

dict(
    id="lc339", num=339, title="Nested List Weight Sum", slug="nested-list-weight-sum", difficulty="Medium",
    topic="design", pattern="DFS / BFS by depth", companies=["Meta"],
    kind="function", cls="Solution", method="depthSum",
    params=[{"name": "nestedList", "type": "NestedInteger[]"}], returns="int",
    statement="""Each element of `nestedList` is either an integer or a list whose elements may themselves be integers or lists. The **depth** of an integer is the number of lists it is inside of (top level = 1).

Return the sum of every integer multiplied by its depth.

You receive LeetCode's `NestedInteger` objects: use `isInteger()`, `getInteger()` and `getList()`. Tests are written as plain nested JSON lists.""",
    constraints=["1 ≤ nestedList.length ≤ 50", "Values are in [−100, 100]", "Maximum depth ≤ 50"],
    examples=[
        dict(args=[[[1, 1], 2, [1, 1]]], expected=10, explanation="Four 1s at depth 2, one 2 at depth 1: 4·2 + 2 = 10."),
        dict(args=[[1, [4, [6]]]], expected=27, explanation="1·1 + 4·2 + 6·3 = 27."),
        dict(args=[[0]], expected=0),
    ],
    hidden=[dict(args=[[[], [[]], 5]]), dict(args=[[-1, [-2, [-3]]]])],
    starter='''# """
# This is the interface that allows for creating nested lists.
# class NestedInteger:
#    def isInteger(self) -> bool:
#        """True if this NestedInteger holds a single integer, rather than a nested list."""
#    def getInteger(self) -> int:
#        """The single integer, or None if this holds a nested list."""
#    def getList(self) -> [NestedInteger]:
#        """The nested list, or None if this holds a single integer."""
# """
class Solution:
    def depthSum(self, nestedList: List[NestedInteger]) -> int:
        pass
''',
    reference='''class Solution:
    def depthSum(self, nestedList):
        total, depth, level = 0, 1, nestedList
        while level:                               # BFS one depth at a time
            nxt = []
            for ni in level:
                if ni.isInteger():
                    total += ni.getInteger() * depth
                else:
                    nxt.extend(ni.getList())
            level, depth = nxt, depth + 1
        return total
''',
    brute='''class Solution:
    def depthSum(self, nestedList):
        def dfs(lst, d):
            return sum(x.getInteger() * d if x.isInteger() else dfs(x.getList(), d + 1) for x in lst)
        return dfs(nestedList, 1)
''',
    small_gen='''def gen(rng):
    def make(d):
        out = []
        for _ in range(rng.randint(0, 3)):
            out.append(make(d + 1) if d < 4 and rng.random() < 0.35 else rng.randint(-5, 5))
        return out
    return [make(1) or [1]]
''',
    hints=["Recursion mirrors the structure: pass the depth down.",
           "Or BFS: process one level of nesting at a time, multiplying by the current depth.",
           "Lists contribute nothing themselves — only their integers do."],
    approach="""DFS with a depth parameter: integers add `value × depth`; lists recurse with `depth + 1`. The BFS version (reference) processes one nesting level at a time, which avoids recursion entirely.""",
    complexity="O(N) time (N = integers + lists) · O(D) space for DFS",
    followups=["Inverse depth weights — deepest level weighs 1 (#364).", "Flatten the structure lazily (#341).", "Parse the nested list from a string (#385)."],
),

dict(
    id="lc341", num=341, title="Flatten Nested List Iterator", slug="flatten-nested-list-iterator", difficulty="Medium",
    topic="design", pattern="Stack of iterators (lazy)", companies=["Meta", "Google"],
    kind="design", cls="NestedIterator", ctor_types=["NestedInteger[]"],
    statement="""Implement an iterator over a nested list of integers that yields the integers in order.

* `NestedIterator(nestedList)` initialises it with LeetCode's `NestedInteger` objects.
* `next()` returns the next integer.
* `hasNext()` returns `true` if integers remain.

The judge calls `hasNext()` before each `next()`, as in `while it.hasNext(): it.next()`. Tests are written as plain nested JSON lists.""",
    constraints=["1 ≤ nestedList.length ≤ 500", "Values are in [−10⁶, 10⁶]", "Lists may be empty."],
    examples=[
        dict(args={"ops": ["NestedIterator", "hasNext", "next", "hasNext", "next", "hasNext", "next", "hasNext", "next", "hasNext", "next", "hasNext"],
                   "args": [[[[1, 1], 2, [1, 1]]], [], [], [], [], [], [], [], [], [], [], []]},
             expected=[None, True, 1, True, 1, True, 2, True, 1, True, 1, False]),
        dict(args={"ops": ["NestedIterator", "hasNext", "next", "hasNext", "next", "hasNext", "next", "hasNext"],
                   "args": [[[1, [4, [6]]]], [], [], [], [], [], [], []]},
             expected=[None, True, 1, True, 4, True, 6, False]),
    ],
    hidden=[dict(args={"ops": ["NestedIterator", "hasNext"], "args": [[[[], [[]]]], []]}),
            dict(args={"ops": ["NestedIterator", "hasNext", "next", "hasNext"], "args": [[[[], [[3]], []]], [], [], []]})],
    starter='''# """
# class NestedInteger:
#    def isInteger(self) -> bool:
#    def getInteger(self) -> int:
#    def getList(self) -> [NestedInteger]:
# """
class NestedIterator:
    def __init__(self, nestedList: [NestedInteger]):
        pass

    def next(self) -> int:
        pass

    def hasNext(self) -> bool:
        pass
''',
    reference='''class NestedIterator:
    def __init__(self, nestedList):
        self.stack = [[nestedList, 0]]          # (list, next position)

    def _advance(self):
        while self.stack:
            lst, i = self.stack[-1]
            if i == len(lst):
                self.stack.pop()
            elif lst[i].isInteger():
                return True
            else:
                self.stack[-1][1] += 1
                self.stack.append([lst[i].getList(), 0])
        return False

    def next(self):
        self._advance()
        lst, i = self.stack[-1]
        self.stack[-1][1] += 1
        return lst[i].getInteger()

    def hasNext(self):
        return self._advance()
''',
    brute='''class NestedIterator:
    def __init__(self, nestedList):
        self.vals = []
        def walk(lst):
            for x in lst:
                if x.isInteger():
                    self.vals.append(x.getInteger())
                else:
                    walk(x.getList())
        walk(nestedList)
        self.i = 0
    def next(self):
        self.i += 1
        return self.vals[self.i - 1]
    def hasNext(self):
        return self.i < len(self.vals)
''',
    small_gen='''def gen(rng):
    def make(d):
        return [make(d + 1) if d < 3 and rng.random() < 0.4 else rng.randint(0, 9) for _ in range(rng.randint(0, 3))]
    nl = make(1)
    def count(x):
        return sum(count(v) if isinstance(v, list) else 1 for v in x)
    k = count(nl)
    ops = ["NestedIterator"] + ["hasNext", "next"] * k + ["hasNext"]
    return {"ops": ops, "args": [[nl]] + [[]] * (len(ops) - 1)}
''',
    hints=["Flattening everything in the constructor works and is a fine first answer — say its memory cost.",
           "Lazy version: keep a stack of (list, position) pairs.",
           "hasNext() should do the work of skipping empty lists and descending until an integer is on top."],
    approach="""**Lazy stack of positions.** The stack holds `(list, next index)` frames. `hasNext()` normalises the top: pop finished lists, descend into sub-lists, and stop when the top points at an integer. `next()` returns that integer and advances. Empty lists are skipped naturally.

Eager flattening in the constructor is simpler but uses O(N) memory up front.""",
    complexity="O(1) amortised per call · O(depth) space (lazy)",
    followups=["Support remove() for the last returned element.", "Peeking Iterator (#284).", "Zigzag iterator over k lists (#281)."],
),

dict(
    id="lc173", num=173, title="Binary Search Tree Iterator", slug="binary-search-tree-iterator", difficulty="Medium",
    topic="design", pattern="Controlled inorder with a stack", companies=["Meta", "Google"],
    kind="design", cls="BSTIterator", ctor_types=["TreeNode"],
    statement="""Implement an iterator over a BST that returns values in ascending order (an inorder traversal).

* `BSTIterator(root)` initialises it.
* `next()` returns the next smallest value.
* `hasNext()` returns `true` if values remain.

Aim for O(1) average time per call and O(h) memory, where h is the tree height.""",
    constraints=["1 ≤ number of nodes ≤ 10⁵", "0 ≤ Node.val ≤ 10⁶", "next() is only called when hasNext() is true."],
    examples=[
        dict(args={"ops": ["BSTIterator", "next", "next", "hasNext", "next", "hasNext", "next", "hasNext", "next", "hasNext"],
                   "args": [[[7, 3, 15, None, None, 9, 20]], [], [], [], [], [], [], [], [], []]},
             expected=[None, 3, 7, True, 9, True, 15, True, 20, False]),
    ],
    hidden=[dict(args={"ops": ["BSTIterator", "hasNext", "next", "hasNext"], "args": [[[1]], [], [], []]})],
    starter='''# Definition for a binary tree node.
# class TreeNode:
#     def __init__(self, val=0, left=None, right=None):
#         self.val = val
#         self.left = left
#         self.right = right
class BSTIterator:

    def __init__(self, root: Optional[TreeNode]):
        pass

    def next(self) -> int:
        pass

    def hasNext(self) -> bool:
        pass
''',
    reference='''class BSTIterator:
    def __init__(self, root):
        self.stack = []
        self._push_left(root)

    def _push_left(self, node):
        while node:
            self.stack.append(node)
            node = node.left

    def next(self):
        node = self.stack.pop()
        self._push_left(node.right)
        return node.val

    def hasNext(self):
        return bool(self.stack)
''',
    brute='''class BSTIterator:
    def __init__(self, root):
        self.vals = []
        def walk(n):
            if n:
                walk(n.left); self.vals.append(n.val); walk(n.right)
        walk(root)
        self.i = 0
    def next(self):
        self.i += 1
        return self.vals[self.i - 1]
    def hasNext(self):
        return self.i < len(self.vals)
''',
    small_gen='''def gen(rng):
    n = rng.randint(1, 9)
    t = rand_tree(rng, n, bst=True)
    ops = ["BSTIterator"] + ["hasNext", "next"] * n + ["hasNext"]
    return {"ops": ops, "args": [[t]] + [[]] * (len(ops) - 1)}
''',
    gens=[dict(name="BST with 50,000 nodes", code='''def gen(rng):
    n = 50000
    t = rand_tree(rng, n, bst=True)
    ops = ["BSTIterator"] + ["hasNext", "next"] * n + ["hasNext"]
    return {"ops": ops, "args": [[t]] + [[]] * (len(ops) - 1)}
''')],
    hints=["Storing the full inorder list works but uses O(n) memory.",
           "Iterative inorder keeps a stack of the left spine — pause it between calls.",
           "next(): pop a node, then push the left spine of its right child. Each node is pushed and popped once."],
    approach="""**Paused iterative inorder.** The stack always holds the path of unvisited ancestors. Start by pushing the left spine of the root. `next()` pops the smallest node and pushes the left spine of its right subtree. Every node is pushed and popped exactly once, so calls are O(1) amortised, and the stack never exceeds the tree height.""",
    complexity="O(1) amortised per call · O(h) space",
    followups=["Add a prev() / hasPrev() (#1586).", "Two iterators to solve Two Sum IV on a BST in O(h) space.", "Iterate in descending order."],
),

dict(
    id="lc1650", num=1650, title="Lowest Common Ancestor of a Binary Tree III", slug="lowest-common-ancestor-of-a-binary-tree-iii",
    difficulty="Medium", topic="trees", pattern="Two pointers on parent links", companies=["Meta"],
    kind="function", cls="Solution", method="lowestCommonAncestor",
    params=[{"name": "root", "type": "ParentTree", "pass": False}, {"name": "p", "type": "ParentNode@0"}, {"name": "q", "type": "ParentNode@0"}],
    returns="Node.val",
    statement="""Every node has a `parent` pointer (the root's parent is `None`). Given **only two nodes** `p` and `q` — not the root — return their lowest common ancestor.

In the tests the whole tree is written as a level-order list (first line) so you can see it; your method receives only `p` and `q`, and the judge reads `.val` from the node you return.""",
    constraints=["2 ≤ number of nodes ≤ 10⁵", "All values are unique.", "p ≠ q, and both are in the tree."],
    examples=[
        dict(args=[[3, 5, 1, 6, 2, 0, 8, None, None, 7, 4], 5, 1], expected=3),
        dict(args=[[3, 5, 1, 6, 2, 0, 8, None, None, 7, 4], 5, 4], expected=5),
        dict(args=[[1, 2], 1, 2], expected=1),
    ],
    hidden=[dict(args=[[3, 5, 1, 6, 2, 0, 8, None, None, 7, 4], 7, 8]), dict(args=[[1, 2, 3, None, 4], 4, 3])],
    starter='''"""
# Definition for a Node.
class Node:
    def __init__(self, val):
        self.val = val
        self.left = None
        self.right = None
        self.parent = None
"""
class Solution:
    def lowestCommonAncestor(self, p: 'Node', q: 'Node') -> 'Node':
        pass
''',
    reference='''class Solution:
    def lowestCommonAncestor(self, p, q):
        a, b = p, q
        while a is not b:                 # each walks its own path then the other's: lengths equalise
            a = a.parent if a else q
            b = b.parent if b else p
        return a
''',
    brute='''class Solution:
    def lowestCommonAncestor(self, p, q):
        seen = set()
        while p:
            seen.add(p); p = p.parent
        while q not in seen:
            q = q.parent
        return q
''',
    small_gen='''def gen(rng):
    t = rand_tree(rng, rng.randint(2, 10), -20, 20)
    p, q = rng.sample(tree_values(t), 2)
    return [t, p, q]
''',
    gens=[dict(name="Tree with 100,000 nodes", code='''def gen(rng):
    t = rand_tree(rng, 100000, -10**6, 10**6)
    v = tree_values(t)
    return [t, v[-1], v[-2]]
''')],
    hints=["With parent pointers this is the 'intersection of two linked lists' problem.",
           "A set of p's ancestors works in O(h) time and O(h) space.",
           "For O(1) space: walk two pointers up; when one reaches None, restart it at the other node. They meet at the LCA."],
    approach="""Each node's ancestor chain is a linked list ending at the root, so the LCA is where the two lists **intersect**. Walk pointer `a` from `p` and `b` from `q`; when a pointer falls off the root, restart it at the *other* start node. After at most `depth(p) + depth(q)` steps both have walked the same total distance and meet at the intersection.""",
    complexity="O(h) time · O(1) space",
    followups=["Without parent pointers (#236).", "LCA of many nodes (#1676).", "Answer many LCA queries quickly (binary lifting)."],
),

dict(
    id="lc426", num=426, title="Convert Binary Search Tree to Sorted Doubly Linked List", slug="convert-binary-search-tree-to-sorted-doubly-linked-list",
    difficulty="Medium", topic="trees", pattern="Inorder with a prev pointer", companies=["Meta"],
    kind="function", cls="Solution", method="treeToDoublyList",
    params=[{"name": "root", "type": "NodeTree"}], returns="CircularDLL",
    statement="""Convert a BST **in place** into a sorted **circular doubly linked list**: reuse each node's `left` as *previous* and `right` as *next*. The smallest node's `left` points to the largest node and the largest node's `right` points back to the smallest. Return the smallest node.

The judge walks `right` pointers from your returned node and checks every `left` pointer is consistent.""",
    constraints=["0 ≤ number of nodes ≤ 2000", "−1000 ≤ Node.val ≤ 1000", "All values are unique."],
    examples=[
        dict(args=[[4, 2, 5, 1, 3]], expected=[1, 2, 3, 4, 5]),
        dict(args=[[2, 1, 3]], expected=[1, 2, 3]),
        dict(args=[[]], expected=[]),
    ],
    hidden=[dict(args=[[1]], expected=[1]), dict(args=[[5, 3, 6, 2, 4, None, None, 1]])],
    starter='''"""
# Definition for a Node.
class Node:
    def __init__(self, val, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right
"""
class Solution:
    def treeToDoublyList(self, root: 'Optional[Node]') -> 'Optional[Node]':
        pass
''',
    reference='''class Solution:
    def treeToDoublyList(self, root):
        if not root:
            return None
        first = prev = None
        stack, node = [], root
        while stack or node:                  # iterative inorder
            while node:
                stack.append(node)
                node = node.left
            node = stack.pop()
            if prev:
                prev.right, node.left = node, prev
            else:
                first = node
            prev = node
            node = node.right
        prev.right, first.left = first, prev  # close the circle
        return first
''',
    brute='''class Solution:
    def treeToDoublyList(self, root):
        vals = []
        def walk(n):
            if n:
                walk(n.left); vals.append(n.val); walk(n.right)
        walk(root)
        if not vals:
            return None
        nodes = [Node(v) for v in vals]
        for i, n in enumerate(nodes):
            n.right = nodes[(i + 1) % len(nodes)]
            n.left = nodes[i - 1]
        return nodes[0]
''',
    small_gen='''def gen(rng):
    return [rand_tree(rng, rng.randint(0, 9), bst=True)]
''',
    gens=[dict(name="BST with 20,000 nodes", code='''def gen(rng):
    return [rand_tree(rng, 20000, bst=True)]
''')],
    hints=["An inorder traversal visits BST nodes in sorted order.",
           "Keep a pointer to the previously visited node and link prev.right = node, node.left = prev.",
           "After the traversal, connect the last node to the first to close the circle."],
    approach="""Do an inorder traversal while remembering `prev`. Each visited node is linked behind `prev` (`prev.right = node`, `node.left = prev`); the first node visited is the head. Finally connect the tail and head. Rewiring is safe because inorder never revisits a node's left subtree after visiting the node.""",
    complexity="O(n) time · O(h) space",
    followups=["Convert back to a balanced BST (#109-style).", "Flatten a binary tree to a singly linked list in preorder (#114).", "Do it with Morris traversal in O(1) extra space."],
),

dict(
    id="lc2013", num=2013, title="Detect Squares", slug="detect-squares", difficulty="Medium", topic="hashing",
    pattern="Hash map of point counts", companies=["Google"],
    kind="design", cls="DetectSquares",
    statement="""Points are added to the plane one at a time (duplicates allowed). For a query point, count the ways to choose **three stored points** that form an **axis-aligned square with positive area** together with the query point.

* `DetectSquares()` creates an empty structure.
* `add(point)` adds `[x, y]`.
* `count(point)` returns the number of such squares.""",
    constraints=["0 ≤ x, y ≤ 1000", "At most 3000 calls in total."],
    examples=[
        dict(args={"ops": ["DetectSquares", "add", "add", "add", "count", "count", "add", "count"],
                   "args": [[], [[3, 10]], [[11, 2]], [[3, 2]], [[11, 10]], [[14, 8]], [[11, 2]], [[11, 10]]]},
             expected=[None, None, None, None, 1, 0, None, 2], explanation="After [11,2] is added twice, two squares share the same corners."),
    ],
    hidden=[dict(args={"ops": ["DetectSquares", "add", "add", "count"], "args": [[], [[1, 1]], [[1, 1]], [[1, 1]]]})],
    starter='''class DetectSquares:

    def __init__(self):
        pass

    def add(self, point: List[int]) -> None:
        pass

    def count(self, point: List[int]) -> int:
        pass
''',
    reference='''class DetectSquares:
    def __init__(self):
        self.cnt = Counter()

    def add(self, point):
        self.cnt[tuple(point)] += 1

    def count(self, point):
        x, y = point
        total = 0
        for (px, py), c in self.cnt.items():
            if abs(px - x) == abs(py - y) and px != x:      # (px, py) is the diagonal corner
                total += c * self.cnt[(px, y)] * self.cnt[(x, py)]
        return total
''',
    brute='''class DetectSquares:
    def __init__(self):
        self.pts = []
    def add(self, point):
        self.pts.append(tuple(point))
    def count(self, point):
        x, y = point
        c = Counter(self.pts)
        total = 0
        for d in range(1, 1001):
            for dx, dy in ((d, d), (d, -d), (-d, d), (-d, -d)):
                total += c[(x + dx, y)] * c[(x, y + dy)] * c[(x + dx, y + dy)]
        return total
''',
    small_gen='''def gen(rng):
    ops, args = ["DetectSquares"], [[]]
    for _ in range(rng.randint(1, 14)):
        p = [rng.randint(0, 3), rng.randint(0, 3)]
        if rng.random() < 0.65:
            ops.append("add")
        else:
            ops.append("count")
        args.append([p])
    return {"ops": ops, "args": args}
''',
    small_n=120,
    hints=["Store how many times each point was added.",
           "Fix the query point; a square is determined by its diagonal corner (px, py) with |px − x| = |py − y| ≠ 0.",
           "Multiply the counts of the three other corners — duplicates multiply."],
    approach="""Keep a counter of points. For `count(x, y)`, iterate over stored points `(px, py)` that could be the **opposite diagonal corner** (`|px − x| == |py − y| > 0`); the other corners are then fixed at `(px, y)` and `(x, py)`. Add the product of the three counts.""",
    complexity="O(1) add · O(P) count (P distinct points) · O(P) space",
    followups=["Only iterate points sharing the query's x column — keep a per-column index.", "Count rectangles instead of squares.",
               "Squares need not be axis-aligned."],
),

dict(
    id="lc1004", num=1004, title="Max Consecutive Ones III", slug="max-consecutive-ones-iii", difficulty="Medium", topic="arrays",
    pattern="Sliding window with a budget", companies=["Meta"],
    kind="function", cls="Solution", method="longestOnes",
    params=[{"name": "nums", "type": "int[]"}, {"name": "k", "type": "int"}], returns="int",
    statement="""`nums` contains only 0s and 1s. You may flip **at most `k`** zeros to ones. Return the length of the longest run of consecutive 1s you can obtain.""",
    constraints=["1 ≤ nums.length ≤ 10⁵", "0 ≤ k ≤ nums.length"],
    examples=[
        dict(args=[[1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0], 2], expected=6),
        dict(args=[[0, 0, 1, 1, 0, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1], 3], expected=10),
    ],
    hidden=[dict(args=[[0], 0]), dict(args=[[0, 0, 0], 3]), dict(args=[[1, 1, 1], 0])],
    starter='''class Solution:
    def longestOnes(self, nums: List[int], k: int) -> int:
        pass
''',
    reference='''class Solution:
    def longestOnes(self, nums, k):
        left = zeros = best = 0
        for right, x in enumerate(nums):
            zeros += x == 0
            while zeros > k:
                zeros -= nums[left] == 0
                left += 1
            best = max(best, right - left + 1)
        return best
''',
    brute='''class Solution:
    def longestOnes(self, nums, k):
        best = 0
        for i in range(len(nums)):
            z = 0
            for j in range(i, len(nums)):
                z += nums[j] == 0
                if z > k:
                    break
                best = max(best, j - i + 1)
        return best
''',
    small_gen='''def gen(rng):
    n = rng.randint(1, 12)
    return [[rng.randint(0, 1) for _ in range(n)], rng.randint(0, 3)]
''',
    gens=[dict(name="n = 100,000", code='''def gen(rng):
    return [[1 if rng.random() < 0.97 else 0 for _ in range(100000)], 2000]
''')],
    hints=["Rephrase: the longest window containing at most k zeros.",
           "Grow the window to the right, counting zeros.",
           "When the count exceeds k, shrink from the left until it is back to k."],
    approach="""**Sliding window with a zero budget.** Expand `right`; when the window holds more than `k` zeros, advance `left` until it holds `k`. The window then always describes a run achievable with ≤ k flips; track its maximum width. Each index enters and leaves once.""",
    complexity="O(n) time · O(1) space",
    followups=["k = 1 with a stream of bits (#487) — store only the last zero's position.", "Longest repeating character replacement (#424).",
               "Return the positions to flip."],
),

dict(
    id="lc1091", num=1091, title="Shortest Path in Binary Matrix", slug="shortest-path-in-binary-matrix", difficulty="Medium",
    topic="graphs", pattern="BFS with 8 directions", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="shortestPathBinaryMatrix",
    params=[{"name": "grid", "type": "int[][]"}], returns="int",
    statement="""In an `n × n` grid of 0s (open) and 1s (blocked), find the length of the shortest **clear path** from the top-left to the bottom-right cell. Moves go to any of the **8** neighbouring cells. The length counts cells visited, including both ends. Return `-1` if there is no such path.""",
    constraints=["1 ≤ n ≤ 100", "grid[i][j] is 0 or 1"],
    examples=[
        dict(args=[[[0, 1], [1, 0]]], expected=2),
        dict(args=[[[0, 0, 0], [1, 1, 0], [1, 1, 0]]], expected=4),
        dict(args=[[[1, 0, 0], [1, 1, 0], [1, 1, 0]]], expected=-1),
    ],
    hidden=[dict(args=[[[0]]], expected=1), dict(args=[[[1]]], expected=-1), dict(args=[[[0, 0], [0, 1]]], expected=-1)],
    starter='''class Solution:
    def shortestPathBinaryMatrix(self, grid: List[List[int]]) -> int:
        pass
''',
    reference='''class Solution:
    def shortestPathBinaryMatrix(self, grid):
        n = len(grid)
        if grid[0][0] or grid[n - 1][n - 1]:
            return -1
        dist = [[0] * n for _ in range(n)]
        dist[0][0] = 1
        q = deque([(0, 0)])
        while q:
            r, c = q.popleft()
            if r == n - 1 and c == n - 1:
                return dist[r][c]
            for dr in (-1, 0, 1):
                for dc in (-1, 0, 1):
                    a, b = r + dr, c + dc
                    if 0 <= a < n and 0 <= b < n and not grid[a][b] and not dist[a][b]:
                        dist[a][b] = dist[r][c] + 1
                        q.append((a, b))
        return -1
''',
    brute='''class Solution:
    def shortestPathBinaryMatrix(self, grid):
        n = len(grid); INF = float("inf")
        if grid[0][0] or grid[n - 1][n - 1]:
            return -1
        d = [[INF] * n for _ in range(n)]; d[0][0] = 1
        changed = True
        while changed:                       # relax until nothing improves
            changed = False
            for r in range(n):
                for c in range(n):
                    if grid[r][c] or d[r][c] == INF:
                        continue
                    for dr in (-1, 0, 1):
                        for dc in (-1, 0, 1):
                            a, b = r + dr, c + dc
                            if 0 <= a < n and 0 <= b < n and not grid[a][b] and d[r][c] + 1 < d[a][b]:
                                d[a][b] = d[r][c] + 1; changed = True
        return -1 if d[n - 1][n - 1] == INF else d[n - 1][n - 1]
''',
    small_gen='''def gen(rng):
    n = rng.randint(1, 5)
    return [[[1 if rng.random() < 0.3 else 0 for _ in range(n)] for _ in range(n)]]
''',
    gens=[dict(name="100 × 100 grid", code='''def gen(rng):
    g = [[1 if rng.random() < 0.25 else 0 for _ in range(100)] for _ in range(100)]
    g[0][0] = g[99][99] = 0
    return [g]
''')],
    hints=["Every move costs the same, so BFS gives the shortest path.",
           "Neighbours are the 8 surrounding cells.",
           "Check the start and end cells first; mark cells visited when you enqueue them."],
    approach="""Plain **BFS** from `(0, 0)` over open cells with 8-directional moves, storing the path length (in cells) for each visited cell. The first time the bottom-right cell is dequeued, its distance is the answer. Blocked start or end → −1.

A* with the Chebyshev distance as heuristic is a common follow-up optimisation.""",
    complexity="O(n²) time and space",
    followups=["Use A* — what heuristic is admissible with diagonal moves?", "Return the path itself.",
               "Allow removing up to k obstacles (#1293)."],
),
]
