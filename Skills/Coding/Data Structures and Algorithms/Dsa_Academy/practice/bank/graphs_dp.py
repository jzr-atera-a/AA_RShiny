# Practice bank — graphs, grids, dynamic programming and backtracking.

PROBLEMS = [
dict(
    id="lc200", num=200, title="Number of Islands", slug="number-of-islands", difficulty="Medium", topic="graphs",
    pattern="Grid BFS / DFS flood fill", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="numIslands",
    params=[{"name": "grid", "type": "str[][]"}], returns="int",
    statement="""`grid` is a map of `"1"` (land) and `"0"` (water). An **island** is a group of land cells connected horizontally or vertically. Return the number of islands. Everything outside the grid is water.""",
    constraints=["1 ≤ rows, cols ≤ 300", 'grid[i][j] is "0" or "1".'],
    examples=[
        dict(args=[[["1", "1", "1", "1", "0"], ["1", "1", "0", "1", "0"], ["1", "1", "0", "0", "0"], ["0", "0", "0", "0", "0"]]], expected=1),
        dict(args=[[["1", "1", "0", "0", "0"], ["1", "1", "0", "0", "0"], ["0", "0", "1", "0", "0"], ["0", "0", "0", "1", "1"]]], expected=3),
    ],
    hidden=[dict(args=[[["0"]]]), dict(args=[[["1"]]]), dict(args=[[["1", "0", "1"], ["0", "1", "0"], ["1", "0", "1"]]])],
    starter='''class Solution:
    def numIslands(self, grid: List[List[str]]) -> int:
        pass
''',
    reference='''class Solution:
    def numIslands(self, grid):
        R, C = len(grid), len(grid[0])
        seen = [[False] * C for _ in range(R)]
        count = 0
        for r in range(R):
            for c in range(C):
                if grid[r][c] == "1" and not seen[r][c]:
                    count += 1
                    seen[r][c] = True
                    q = deque([(r, c)])
                    while q:
                        i, j = q.popleft()
                        for a, b in ((i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)):
                            if 0 <= a < R and 0 <= b < C and grid[a][b] == "1" and not seen[a][b]:
                                seen[a][b] = True
                                q.append((a, b))
        return count
''',
    brute='''class Solution:
    def numIslands(self, grid):
        R, C = len(grid), len(grid[0])
        parent = {(r, c): (r, c) for r in range(R) for c in range(C) if grid[r][c] == "1"}
        def find(x):
            while parent[x] != x:
                x = parent[x]
            return x
        for (r, c) in list(parent):
            for nb in ((r + 1, c), (r, c + 1)):
                if nb in parent:
                    parent[find(nb)] = find((r, c))
        return len({find(x) for x in parent})
''',
    small_gen='''def gen(rng):
    R, C = rng.randint(1, 5), rng.randint(1, 5)
    return [[[rng.choice("01") for _ in range(C)] for _ in range(R)]]
''',
    gens=[dict(name="300 × 300 grid", code='''def gen(rng):
    return [[[("1" if rng.random() < 0.45 else "0") for _ in range(300)] for _ in range(300)]]
''')],
    hints=["Every unvisited land cell you meet starts a new island.",
           "From it, flood-fill (BFS or DFS) to mark the entire island as visited.",
           "The number of flood fills you start is the answer."],
    approach="""Scan every cell. When an unvisited `"1"` is found, increment the count and **flood fill** its island with BFS or DFS, marking cells visited (or overwriting them with `"0"` if mutating the input is acceptable — say so in an interview).

Recursive DFS can hit Python's recursion limit on a 300 × 300 snake-shaped island; BFS or an explicit stack avoids that.""",
    complexity="O(R · C) time · O(R · C) space worst case",
    followups=["Count distinct island shapes (#694).", "Cells turn into land one at a time; report the count after each (#305, Union-Find).",
               "Max area of an island (#695).", "The grid is too large for memory — process it row by row."],
),

dict(
    id="lc207", num=207, title="Course Schedule", slug="course-schedule", difficulty="Medium", topic="graphs",
    pattern="Topological sort / cycle detection", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="canFinish",
    params=[{"name": "numCourses", "type": "int"}, {"name": "prerequisites", "type": "int[][]"}], returns="bool",
    statement="""There are `numCourses` courses labelled `0 … numCourses − 1`. Each pair `[a, b]` in `prerequisites` means course `b` must be taken before course `a`.

Return `true` if it is possible to finish every course.""",
    constraints=["1 ≤ numCourses ≤ 2000", "0 ≤ prerequisites.length ≤ 5000", "All pairs are distinct."],
    examples=[
        dict(args=[2, [[1, 0]]], expected=True),
        dict(args=[2, [[1, 0], [0, 1]]], expected=False, explanation="Each course needs the other first — a cycle."),
    ],
    hidden=[dict(args=[1, []]), dict(args=[3, [[0, 1], [1, 2], [2, 0]]]), dict(args=[4, [[1, 0], [2, 1], [3, 2], [1, 3]]]), dict(args=[5, [[1, 0], [2, 0], [3, 1], [3, 2], [4, 3]]])],
    starter='''class Solution:
    def canFinish(self, numCourses: int, prerequisites: List[List[int]]) -> bool:
        pass
''',
    reference='''class Solution:
    def canFinish(self, numCourses, prerequisites):
        graph = [[] for _ in range(numCourses)]
        indeg = [0] * numCourses
        for a, b in prerequisites:
            graph[b].append(a)
            indeg[a] += 1
        q = deque(i for i in range(numCourses) if indeg[i] == 0)
        done = 0
        while q:
            u = q.popleft()
            done += 1
            for v in graph[u]:
                indeg[v] -= 1
                if indeg[v] == 0:
                    q.append(v)
        return done == numCourses
''',
    brute='''class Solution:
    def canFinish(self, n, pre):
        reach = [[False] * n for _ in range(n)]
        for a, b in pre:
            reach[b][a] = True
        for k in range(n):
            for i in range(n):
                if reach[i][k]:
                    for j in range(n):
                        if reach[k][j]:
                            reach[i][j] = True
        return not any(reach[i][i] for i in range(n))
''',
    small_gen='''def gen(rng):
    n = rng.randint(1, 6)
    pairs = {(rng.randrange(n), rng.randrange(n)) for _ in range(rng.randint(0, 7))}
    return [n, [[a, b] for a, b in pairs if a != b]]
''',
    gens=[dict(name="2,000 courses, 5,000 prerequisites", code='''def gen(rng):
    n = 2000
    order = list(range(n)); rng.shuffle(order)
    pairs = set()
    while len(pairs) < 5000:
        i, j = sorted(rng.sample(range(n), 2))
        pairs.add((order[j], order[i]))
    return [n, [list(p) for p in pairs]]
''')],
    hints=["Model courses as nodes and prerequisites as directed edges b → a.",
           "All courses can be finished exactly when this graph has no cycle.",
           "Kahn's algorithm: repeatedly take a course with no remaining prerequisites. Or DFS with three colours."],
    approach="""Build the graph `b → a` and the in-degree of each course. **Kahn's algorithm**: start from courses with in-degree 0, 'take' them and decrement their dependants; a dependant whose in-degree reaches 0 becomes available. If every course is eventually taken there is no cycle.

DFS alternative: colour nodes white / grey / black; reaching a grey node means a back edge, i.e. a cycle.""",
    complexity="O(V + E) time · O(V + E) space",
    followups=["Return a valid order (#210).", "Minimum number of semesters if any number of courses can be taken at once (#1136).",
               "Which single prerequisite would you remove to break the cycle?"],
),

dict(
    id="lc743", num=743, title="Network Delay Time", slug="network-delay-time", difficulty="Medium", topic="graphs",
    pattern="Dijkstra", companies=["Google", "Meta"],
    kind="function", cls="Solution", method="networkDelayTime",
    params=[{"name": "times", "type": "int[][]"}, {"name": "n", "type": "int"}, {"name": "k", "type": "int"}], returns="int",
    statement="""A network has `n` nodes labelled `1 … n`. `times[i] = [u, v, w]` is a **directed** edge from `u` to `v` that takes `w` time to traverse.

A signal is sent from node `k`. Return the time it takes for **every** node to receive it, or `-1` if some node never does.""",
    constraints=["1 ≤ k ≤ n ≤ 100", "1 ≤ times.length ≤ 6000", "0 ≤ w ≤ 100", "No duplicate (u, v) edges."],
    examples=[
        dict(args=[[[2, 1, 1], [2, 3, 1], [3, 4, 1]], 4, 2], expected=2),
        dict(args=[[[1, 2, 1]], 2, 1], expected=1),
        dict(args=[[[1, 2, 1]], 2, 2], expected=-1),
    ],
    hidden=[dict(args=[[[1, 2, 1], [2, 3, 2], [1, 3, 4]], 3, 1]), dict(args=[[[1, 2, 0]], 2, 1]), dict(args=[[[1, 2, 5]], 1, 1])],
    starter='''class Solution:
    def networkDelayTime(self, times: List[List[int]], n: int, k: int) -> int:
        pass
''',
    reference='''class Solution:
    def networkDelayTime(self, times, n, k):
        graph = defaultdict(list)
        for u, v, w in times:
            graph[u].append((v, w))
        dist = {}
        heap = [(0, k)]
        while heap:
            d, u = heapq.heappop(heap)
            if u in dist:
                continue
            dist[u] = d
            for v, w in graph[u]:
                if v not in dist:
                    heapq.heappush(heap, (d + w, v))
        return max(dist.values()) if len(dist) == n else -1
''',
    brute='''class Solution:
    def networkDelayTime(self, times, n, k):
        INF = float("inf")
        dist = [INF] * (n + 1); dist[k] = 0
        for _ in range(n - 1):
            for u, v, w in times:
                if dist[u] + w < dist[v]:
                    dist[v] = dist[u] + w
        m = max(dist[1:])
        return -1 if m == INF else m
''',
    small_gen='''def gen(rng):
    n = rng.randint(1, 6)
    edges = {}
    for _ in range(rng.randint(0, 12)):
        u, v = rng.randint(1, n), rng.randint(1, n)
        if u != v:
            edges[(u, v)] = rng.randint(0, 9)
    times = [[u, v, w] for (u, v), w in edges.items()]
    if not times:
        times = [[1, n, 1]] if n > 1 else []
    return [times, n, rng.randint(1, n)]
''',
    gens=[dict(name="100 nodes, 6,000 edges", code='''def gen(rng):
    n = 100
    pairs = set()
    while len(pairs) < 6000:
        u, v = rng.randint(1, n), rng.randint(1, n)
        if u != v:
            pairs.add((u, v))
    return [[[u, v, rng.randint(0, 100)] for u, v in pairs], n, 1]
''')],
    hints=["Every node receives the signal at its shortest-path distance from k.",
           "Weights are non-negative, so Dijkstra's algorithm applies.",
           "The answer is the largest shortest distance — or −1 if a node is unreachable."],
    approach="""Run **Dijkstra** from `k` with a min-heap of `(distance, node)`; a node's distance is final the first time it is popped. The answer is the maximum final distance, or −1 if fewer than `n` nodes were reached.""",
    complexity="O(E log V) time · O(V + E) space",
    followups=["Edges can have negative weights (Bellman-Ford).", "Limit the number of hops (#787, Cheapest Flights Within K Stops).",
               "Return the path to the last node reached."],
),

dict(
    id="lc329", num=329, title="Longest Increasing Path in a Matrix", slug="longest-increasing-path-in-a-matrix",
    difficulty="Hard", topic="dp", pattern="DFS + memoisation on a DAG", companies=["Google", "Meta"],
    kind="function", cls="Solution", method="longestIncreasingPath",
    params=[{"name": "matrix", "type": "int[][]"}], returns="int",
    statement="""From each cell you may move up, down, left or right, but only to a cell with a **strictly larger** value. Return the length (number of cells) of the longest increasing path in `matrix`.""",
    constraints=["1 ≤ rows, cols ≤ 200", "0 ≤ matrix[i][j] ≤ 2³¹ − 1"],
    examples=[
        dict(args=[[[9, 9, 4], [6, 6, 8], [2, 1, 1]]], expected=4, explanation="1 → 2 → 6 → 9."),
        dict(args=[[[3, 4, 5], [3, 2, 6], [2, 2, 1]]], expected=4, explanation="3 → 4 → 5 → 6."),
        dict(args=[[[1]]], expected=1),
    ],
    hidden=[dict(args=[[[7, 7], [7, 7]]]), dict(args=[[[1, 2, 3], [6, 5, 4], [7, 8, 9]]], expected=9)],
    starter='''class Solution:
    def longestIncreasingPath(self, matrix: List[List[int]]) -> int:
        pass
''',
    reference='''class Solution:
    def longestIncreasingPath(self, matrix):
        R, C = len(matrix), len(matrix[0])
        cells = sorted(((matrix[r][c], r, c) for r in range(R) for c in range(C)), reverse=True)
        best = [[1] * C for _ in range(R)]
        for v, r, c in cells:                       # process from largest to smallest value
            for a, b in ((r + 1, c), (r - 1, c), (r, c + 1), (r, c - 1)):
                if 0 <= a < R and 0 <= b < C and matrix[a][b] > v:
                    best[r][c] = max(best[r][c], 1 + best[a][b])
        return max(map(max, best))
''',
    brute='''class Solution:
    def longestIncreasingPath(self, matrix):
        R, C = len(matrix), len(matrix[0])
        def dfs(r, c):
            out = 1
            for a, b in ((r + 1, c), (r - 1, c), (r, c + 1), (r, c - 1)):
                if 0 <= a < R and 0 <= b < C and matrix[a][b] > matrix[r][c]:
                    out = max(out, 1 + dfs(a, b))
            return out
        return max(dfs(r, c) for r in range(R) for c in range(C))
''',
    small_gen='''def gen(rng):
    R, C = rng.randint(1, 4), rng.randint(1, 4)
    return [[[rng.randint(0, 6) for _ in range(C)] for _ in range(R)]]
''',
    gens=[dict(name="200 × 200 matrix", code='''def gen(rng):
    return [[[rng.randint(0, 10**4) for _ in range(200)] for _ in range(200)]]
'''), dict(name="Smooth 60 × 60 matrix (long paths)", code='''def gen(rng):
    return [[[r * 60 + c + rng.randint(0, 2) for c in range(60)] for r in range(60)]]
''')],
    hints=["Plain DFS from every cell re-explores the same paths: exponential.",
           "The longest path starting at a cell never changes — memoise it.",
           "'Strictly increasing' means the moves form a DAG, so there are no cycles to worry about."],
    approach="""Because moves are strictly increasing, the cells form a **DAG**. Let `best(r, c)` be the longest path starting at `(r, c)`: `1 + max(best(neighbour))` over larger neighbours. Compute it with **DFS + memoisation**, or — as the reference does — iterate cells from largest value to smallest so each neighbour's answer is ready (a topological order).""",
    complexity="O(R · C · log(R · C)) with sorting, O(R · C) with memoised DFS · O(R · C) space",
    followups=["Return the path itself.", "Allow moves to cells that are equal or larger (cycles appear — what changes?).",
               "Diagonal moves allowed."],
),

dict(
    id="lc1293", num=1293, title="Shortest Path in a Grid with Obstacles Elimination", slug="shortest-path-in-a-grid-with-obstacles-elimination",
    difficulty="Hard", topic="graphs", pattern="BFS over (cell, eliminations left)", companies=["Google"],
    kind="function", cls="Solution", method="shortestPath",
    params=[{"name": "grid", "type": "int[][]"}, {"name": "k", "type": "int"}], returns="int",
    statement="""`grid` contains `0` (empty) and `1` (obstacle). Moving up, down, left or right costs one step. You may **eliminate at most `k` obstacles** along the way.

Return the minimum number of steps from the top-left to the bottom-right cell, or `-1` if impossible. Both corners are empty.""",
    constraints=["1 ≤ rows, cols ≤ 40", "1 ≤ k ≤ rows · cols", "grid[0][0] == grid[rows−1][cols−1] == 0"],
    examples=[
        dict(args=[[[0, 0, 0], [1, 1, 0], [0, 0, 0], [0, 1, 1], [0, 0, 0]], 1], expected=6),
        dict(args=[[[0, 1, 1], [1, 1, 1], [1, 0, 0]], 1], expected=-1),
    ],
    hidden=[dict(args=[[[0]], 1], expected=0), dict(args=[[[0, 1, 0, 0, 0, 1, 0, 0], [0, 1, 0, 1, 0, 1, 0, 1], [0, 0, 0, 1, 0, 0, 1, 0]], 1])],
    starter='''class Solution:
    def shortestPath(self, grid: List[List[int]], k: int) -> int:
        pass
''',
    reference='''class Solution:
    def shortestPath(self, grid, k):
        R, C = len(grid), len(grid[0])
        if k >= R + C - 2:                        # enough to walk straight through
            return R + C - 2
        best = [[-1] * C for _ in range(R)]       # most eliminations left when reaching a cell
        best[0][0] = k
        q = deque([(0, 0, k)])
        steps = 0
        while q:
            for _ in range(len(q)):
                r, c, left = q.popleft()
                if r == R - 1 and c == C - 1:
                    return steps
                for a, b in ((r + 1, c), (r - 1, c), (r, c + 1), (r, c - 1)):
                    if 0 <= a < R and 0 <= b < C:
                        nl = left - grid[a][b]
                        if nl > best[a][b]:
                            best[a][b] = nl
                            q.append((a, b, nl))
            steps += 1
        return -1
''',
    brute='''from itertools import combinations
class Solution:
    def shortestPath(self, grid, k):
        R, C = len(grid), len(grid[0])
        obs = [(r, c) for r in range(R) for c in range(C) if grid[r][c]]
        best = -1
        for m in range(min(k, len(obs)) + 1):
            for gone in combinations(obs, m):
                g = set(gone)
                dist = {(0, 0): 0}; q = [(0, 0)]
                for r, c in q:
                    for a, b in ((r + 1, c), (r - 1, c), (r, c + 1), (r, c - 1)):
                        if 0 <= a < R and 0 <= b < C and (a, b) not in dist and (grid[a][b] == 0 or (a, b) in g):
                            dist[(a, b)] = dist[(r, c)] + 1; q.append((a, b))
                d = dist.get((R - 1, C - 1), -1)
                if d != -1 and (best == -1 or d < best):
                    best = d
        return best
''',
    small_gen='''def gen(rng):
    R, C = rng.randint(1, 4), rng.randint(1, 4)
    g = [[1 if rng.random() < 0.45 else 0 for _ in range(C)] for _ in range(R)]
    g[0][0] = g[R - 1][C - 1] = 0
    return [g, rng.randint(1, 3)]
''',
    small_n=200,
    gens=[dict(name="40 × 40 grid, k = 20", code='''def gen(rng):
    g = [[1 if rng.random() < 0.4 else 0 for _ in range(40)] for _ in range(40)]
    g[0][0] = g[39][39] = 0
    return [g, 20]
''')],
    hints=["Plain BFS finds shortest paths, but the state must include how many eliminations you have left.",
           "BFS over (row, col, remaining) — at most R · C · (k + 1) states.",
           "Prune: if you reach a cell with fewer eliminations left than a previous visit, it cannot do better."],
    approach="""**BFS on an expanded state** `(row, col, eliminations left)`. Stepping onto an obstacle costs one elimination. BFS explores by number of steps, so the first time the target is dequeued gives the answer.

Two prunings: if `k ≥ R + C − 2` you can walk the Manhattan path straight through; and keep, per cell, the most eliminations left on any visit so far — a later visit with fewer left is dominated.""",
    complexity="O(R · C · k) time and space",
    followups=["Each obstacle has a different removal cost (Dijkstra).", "Minimise eliminations instead of steps (0-1 BFS, #2290).",
               "Return the path."],
),

dict(
    id="lc778", num=778, title="Swim in Rising Water", slug="swim-in-rising-water", difficulty="Hard", topic="graphs",
    pattern="Minimax path: Dijkstra / binary search + BFS / Union-Find", companies=["Google"],
    kind="function", cls="Solution", method="swimInWater",
    params=[{"name": "grid", "type": "int[][]"}], returns="int",
    statement="""`grid` is an `n × n` elevation map containing each value `0 … n² − 1` exactly once. At time `t` the water level is `t`, and you can swim between adjacent cells (4 directions) if **both** elevations are at most `t`. Swimming takes no time.

Return the minimum time at which you can reach the bottom-right cell starting from the top-left.""",
    constraints=["1 ≤ n ≤ 50", "grid is a permutation of 0 … n² − 1"],
    examples=[
        dict(args=[[[0, 2], [1, 3]]], expected=3),
        dict(args=[[[0, 1, 2, 3, 4], [24, 23, 22, 21, 5], [12, 13, 14, 15, 16], [11, 17, 18, 19, 20], [10, 9, 8, 7, 6]]], expected=16),
    ],
    hidden=[dict(args=[[[0]]], expected=0), dict(args=[[[3, 2], [0, 1]]])],
    starter='''class Solution:
    def swimInWater(self, grid: List[List[int]]) -> int:
        pass
''',
    reference='''class Solution:
    def swimInWater(self, grid):
        n = len(grid)
        heap = [(grid[0][0], 0, 0)]
        seen = {(0, 0)}
        while heap:
            t, r, c = heapq.heappop(heap)
            if r == n - 1 and c == n - 1:
                return t
            for a, b in ((r + 1, c), (r - 1, c), (r, c + 1), (r, c - 1)):
                if 0 <= a < n and 0 <= b < n and (a, b) not in seen:
                    seen.add((a, b))
                    heapq.heappush(heap, (max(t, grid[a][b]), a, b))
''',
    brute='''class Solution:
    def swimInWater(self, grid):
        n = len(grid)
        for t in range(n * n):
            if grid[0][0] > t:
                continue
            seen = {(0, 0)}; q = [(0, 0)]
            for r, c in q:
                for a, b in ((r + 1, c), (r - 1, c), (r, c + 1), (r, c - 1)):
                    if 0 <= a < n and 0 <= b < n and (a, b) not in seen and grid[a][b] <= t:
                        seen.add((a, b)); q.append((a, b))
            if (n - 1, n - 1) in seen:
                return t
''',
    small_gen='''def gen(rng):
    n = rng.randint(1, 5)
    v = list(range(n * n)); rng.shuffle(v)
    return [[v[i * n:(i + 1) * n] for i in range(n)]]
''',
    gens=[dict(name="50 × 50 grid", code='''def gen(rng):
    v = list(range(2500)); rng.shuffle(v)
    return [[v[i * 50:(i + 1) * 50] for i in range(50)]]
''')],
    hints=["The time needed along a path is the maximum elevation on it; you want the path minimising that maximum.",
           "Dijkstra works if a path's 'cost' is max(...) instead of a sum.",
           "Alternative: binary search on t and check reachability with BFS — O(n² log n)."],
    approach="""This is a **minimax path** problem: a path's cost is its largest elevation. Dijkstra still works with `cost = max(current, next elevation)` because that cost never decreases along a path. Pop the cell with the lowest cost; the first time the target is popped, its cost is the answer.

Equivalent: binary-search the time `t` with a BFS feasibility check, or add cells in increasing elevation into a Union-Find until the corners connect.""",
    complexity="O(n² log n) time · O(n²) space",
    followups=["Path With Minimum Effort (#1631) — cost is the largest height difference.", "Return the actual path.",
               "Elevations are not distinct — anything change?"],
),

dict(
    id="lc139", num=139, title="Word Break", slug="word-break", difficulty="Medium", topic="dp",
    pattern="1D DP over prefixes", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="wordBreak",
    params=[{"name": "s", "type": "str"}, {"name": "wordDict", "type": "str[]"}], returns="bool",
    statement="""Return `true` if `s` can be split into a sequence of one or more words from `wordDict`. A dictionary word may be used any number of times.""",
    constraints=["1 ≤ s.length ≤ 300", "1 ≤ wordDict.length ≤ 1000", "1 ≤ wordDict[i].length ≤ 20", "All words are distinct and lowercase."],
    examples=[
        dict(args=["leetcode", ["leet", "code"]], expected=True),
        dict(args=["applepenapple", ["apple", "pen"]], expected=True, explanation="Words may be reused."),
        dict(args=["catsandog", ["cats", "dog", "sand", "and", "cat"]], expected=False),
    ],
    hidden=[dict(args=["a" * 150 + "b", ["a", "aa", "aaa", "aaaa", "aaaaa", "aaaaaa", "aaaaaaa", "aaaaaaaa", "aaaaaaaaa", "aaaaaaaaaa"]], expected=False),
            dict(args=["cars", ["car", "ca", "rs"]], expected=True), dict(args=["a", ["b"]], expected=False)],
    starter='''class Solution:
    def wordBreak(self, s: str, wordDict: List[str]) -> bool:
        pass
''',
    reference='''class Solution:
    def wordBreak(self, s, wordDict):
        words = set(wordDict)
        lengths = sorted({len(w) for w in words})
        ok = [False] * (len(s) + 1)
        ok[0] = True
        for i in range(1, len(s) + 1):
            for L in lengths:
                if L > i:
                    break
                if ok[i - L] and s[i - L:i] in words:
                    ok[i] = True
                    break
        return ok[-1]
''',
    brute='''class Solution:
    def wordBreak(self, s, wordDict):
        if not s:
            return True
        return any(s.startswith(w) and self.wordBreak(s[len(w):], wordDict) for w in wordDict)
''',
    small_gen='''def gen(rng):
    words = list({"".join(rng.choice("ab") for _ in range(rng.randint(1, 3))) for _ in range(rng.randint(1, 4))})
    if rng.random() < 0.6:
        s = "".join(rng.choice(words) for _ in range(rng.randint(1, 4)))
    else:
        s = "".join(rng.choice("ab") for _ in range(rng.randint(1, 8)))
    return [s, words]
''',
    hints=["Plain recursion re-solves the same suffix many times — 'aaaa…ab' takes exponential time.",
           "Let ok[i] mean 'the first i characters can be segmented'.",
           "ok[i] is true if some word w ends at i and ok[i − len(w)] is true."],
    approach="""`ok[i]` = can `s[:i]` be segmented? `ok[0] = True`. For each `i`, try each dictionary word length `L`: if `ok[i − L]` and `s[i−L:i]` is a word, then `ok[i] = True`. The answer is `ok[n]`. Top-down recursion with `@lru_cache` on the start index is the same idea.""",
    complexity="O(n · m · L) time (m distinct word lengths, L for slicing) · O(n) space",
    followups=["Return every possible sentence (#140).", "The dictionary is huge — store it in a trie and walk forward from each ok position.",
               "Minimum number of words in a segmentation."],
),

dict(
    id="lc322", num=322, title="Coin Change", slug="coin-change", difficulty="Medium", topic="dp",
    pattern="Unbounded knapsack", companies=["Google", "Meta"],
    kind="function", cls="Solution", method="coinChange",
    params=[{"name": "coins", "type": "int[]"}, {"name": "amount", "type": "int"}], returns="int",
    statement="""Return the **fewest coins** needed to make up `amount` using unlimited coins of the given denominations, or `-1` if it cannot be done.""",
    constraints=["1 ≤ coins.length ≤ 12", "1 ≤ coins[i] ≤ 2³¹ − 1", "0 ≤ amount ≤ 10⁴"],
    examples=[
        dict(args=[[1, 2, 5], 11], expected=3, explanation="5 + 5 + 1."),
        dict(args=[[2], 3], expected=-1),
        dict(args=[[1], 0], expected=0),
    ],
    hidden=[dict(args=[[1, 3, 4], 6], expected=2), dict(args=[[186, 419, 83, 408], 6249], expected=20), dict(args=[[2147483647], 2], expected=-1)],
    starter='''class Solution:
    def coinChange(self, coins: List[int], amount: int) -> int:
        pass
''',
    reference='''class Solution:
    def coinChange(self, coins, amount):
        INF = amount + 1
        dp = [0] + [INF] * amount
        for a in range(1, amount + 1):
            for c in coins:
                if c <= a and dp[a - c] + 1 < dp[a]:
                    dp[a] = dp[a - c] + 1
        return dp[amount] if dp[amount] <= amount else -1
''',
    brute='''class Solution:
    def coinChange(self, coins, amount):
        dist = {0: 0}; q = [0]
        for x in q:
            if x == amount:
                return dist[x]
            for c in coins:
                if x + c <= amount and x + c not in dist:
                    dist[x + c] = dist[x] + 1; q.append(x + c)
        return -1
''',
    small_gen='''def gen(rng):
    return [rng.sample(range(1, 12), rng.randint(1, 4)), rng.randint(0, 40)]
''',
    gens=[dict(name="amount = 10,000 with 12 coins", code='''def gen(rng):
    return [rng.sample(range(5, 500), 12), 10000]
''')],
    hints=["Greedy (largest coin first) fails: coins [1, 3, 4], amount 6.",
           "dp[a] = fewest coins for amount a. Try each coin as the last coin used.",
           "dp[a] = 1 + min(dp[a − c]) over coins c ≤ a, with dp[0] = 0."],
    approach="""**Bottom-up DP.** `dp[a]` is the fewest coins summing to `a`; `dp[0] = 0`. For each amount, try every coin as the last one: `dp[a] = min(dp[a], dp[a − c] + 1)`. Use a sentinel larger than any real answer to mark 'impossible'.

BFS over amounts (each coin is an edge of cost 1) is an equivalent view.""",
    complexity="O(amount · coins) time · O(amount) space",
    followups=["Count the number of ways instead (#518) — loop order now matters.", "Return the coins used.",
               "Each coin may be used at most once (0/1 knapsack)."],
),

dict(
    id="lc22", num=22, title="Generate Parentheses", slug="generate-parentheses", difficulty="Medium", topic="recursion",
    pattern="Backtracking with counts", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="generateParenthesis",
    params=[{"name": "n", "type": "int"}], returns="str[]", compare="unordered",
    statement="""Return **all** combinations of `n` pairs of well-formed parentheses, in any order.""",
    constraints=["1 ≤ n ≤ 8"],
    examples=[
        dict(args=[3], expected=["((()))", "(()())", "(())()", "()(())", "()()()"]),
        dict(args=[1], expected=["()"]),
    ],
    hidden=[dict(args=[2]), dict(args=[5]), dict(args=[8])],
    starter='''class Solution:
    def generateParenthesis(self, n: int) -> List[str]:
        pass
''',
    reference='''class Solution:
    def generateParenthesis(self, n):
        out = []
        def bt(s, open_, close):
            if len(s) == 2 * n:
                out.append(s)
                return
            if open_ < n:
                bt(s + "(", open_ + 1, close)
            if close < open_:
                bt(s + ")", open_, close + 1)
        bt("", 0, 0)
        return out
''',
    brute='''from itertools import product
class Solution:
    def generateParenthesis(self, n):
        def ok(t):
            b = 0
            for c in t:
                b += 1 if c == "(" else -1
                if b < 0:
                    return False
            return b == 0
        return ["".join(p) for p in product("()", repeat=2 * n) if ok(p)]
''',
    small_gen='''def gen(rng):
    return [rng.randint(1, 5)]
''',
    small_n=40,
    hints=["Build the string one character at a time.",
           "You may add '(' while fewer than n are open; you may add ')' only while it would close something.",
           "Those two rules prune every invalid prefix, so every leaf is a valid answer."],
    approach="""**Backtracking with two counters.** Extend the current string with `'('` if `open < n`, and with `')'` if `close < open`. When the length reaches `2n`, record it. Because invalid prefixes are never created, the work is proportional to the output (the n-th Catalan number).""",
    complexity="O(4ⁿ / √n) time and space (Catalan number of results)",
    followups=["Only count them (Catalan numbers, DP).", "Generate them in lexicographic order.",
               "Three bracket types with correct nesting."],
),
]
