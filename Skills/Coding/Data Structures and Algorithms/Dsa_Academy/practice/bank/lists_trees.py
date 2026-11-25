# Practice bank — linked lists and binary trees.
# Trees are written in LeetCode level order: [3,9,20,null,null,15,7].

PROBLEMS = [
dict(
    id="lc2", num=2, title="Add Two Numbers", slug="add-two-numbers", difficulty="Medium", topic="linkedlists",
    pattern="Dummy head + carry", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="addTwoNumbers",
    params=[{"name": "l1", "type": "ListNode"}, {"name": "l2", "type": "ListNode"}], returns="ListNode",
    statement="""Two non-negative integers are stored as linked lists with their digits in **reverse order** (the head is the ones digit). Return their sum as a linked list in the same format.

Lists are shown as arrays: `[2,4,3]` is 2 → 4 → 3, i.e. the number 342.""",
    constraints=["1 ≤ number of nodes ≤ 100 per list", "0 ≤ Node.val ≤ 9", "No leading zeros except the number 0 itself."],
    examples=[
        dict(args=[[2, 4, 3], [5, 6, 4]], expected=[7, 0, 8], explanation="342 + 465 = 807."),
        dict(args=[[0], [0]], expected=[0]),
        dict(args=[[9, 9, 9, 9, 9, 9, 9], [9, 9, 9, 9]], expected=[8, 9, 9, 9, 0, 0, 0, 1]),
    ],
    hidden=[dict(args=[[5], [5]]), dict(args=[[1, 8], [0]]), dict(args=[[9], [1, 9, 9]])],
    starter='''# Definition for singly-linked list.
# class ListNode:
#     def __init__(self, val=0, next=None):
#         self.val = val
#         self.next = next
class Solution:
    def addTwoNumbers(self, l1: Optional[ListNode], l2: Optional[ListNode]) -> Optional[ListNode]:
        pass
''',
    reference='''class Solution:
    def addTwoNumbers(self, l1, l2):
        dummy = tail = ListNode()
        carry = 0
        while l1 or l2 or carry:
            s = carry + (l1.val if l1 else 0) + (l2.val if l2 else 0)
            carry, digit = divmod(s, 10)
            tail.next = ListNode(digit)
            tail = tail.next
            l1 = l1.next if l1 else None
            l2 = l2.next if l2 else None
        return dummy.next
''',
    brute='''class Solution:
    def addTwoNumbers(self, l1, l2):
        def num(l):
            d, p = 0, 1
            while l:
                d += l.val * p; p *= 10; l = l.next
            return d
        s = str(num(l1) + num(l2))[::-1]
        dummy = t = ListNode()
        for ch in s:
            t.next = ListNode(int(ch)); t = t.next
        return dummy.next
''',
    small_gen='''def gen(rng):
    def number():
        n = rng.randint(1, 6)
        d = [rng.randint(0, 9) for _ in range(n)]
        if n > 1 and d[-1] == 0:
            d[-1] = rng.randint(1, 9)
        return d
    return [number(), number()]
''',
    hints=["Add digit by digit like on paper — the lists are already least-significant first.",
           "Carry the overflow into the next position.",
           "A dummy head node avoids special-casing the first digit. Keep going while either list or the carry remains."],
    approach="""Walk both lists together, adding the two digits plus `carry`; write `sum % 10` into a new node and carry `sum // 10`. Continue while either list has nodes **or** a carry remains (that is what produces the extra leading 1 in 999 + 1). A dummy head keeps the code uniform.""",
    complexity="O(max(m, n)) time · O(1) extra space (output excluded)",
    followups=["Digits stored most-significant first (#445) — use stacks or reverse.", "Subtract or multiply instead of add.",
               "Why does converting to an integer fail in Java or C++ for 100-digit numbers?"],
),

dict(
    id="lc23", num=23, title="Merge k Sorted Lists", slug="merge-k-sorted-lists", difficulty="Hard", topic="heaps",
    pattern="Min-heap of list heads", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="mergeKLists",
    params=[{"name": "lists", "type": "ListNode[]"}], returns="ListNode", time_factor=12,
    statement="""You are given `k` linked lists, each sorted in ascending order. Merge them into one sorted linked list and return it.""",
    constraints=["0 ≤ k ≤ 10⁴", "0 ≤ each list's length ≤ 500", "−10⁴ ≤ Node.val ≤ 10⁴", "Total nodes ≤ 10⁴"],
    examples=[
        dict(args=[[[1, 4, 5], [1, 3, 4], [2, 6]]], expected=[1, 1, 2, 3, 4, 4, 5, 6]),
        dict(args=[[]], expected=[]),
        dict(args=[[[]]], expected=[]),
    ],
    hidden=[dict(args=[[[], [1]]]), dict(args=[[[2], [], [-1]]]), dict(args=[[[1, 1, 1], [1, 1]]])],
    starter='''# Definition for singly-linked list.
# class ListNode:
#     def __init__(self, val=0, next=None):
#         self.val = val
#         self.next = next
class Solution:
    def mergeKLists(self, lists: List[Optional[ListNode]]) -> Optional[ListNode]:
        pass
''',
    reference='''class Solution:
    def mergeKLists(self, lists):
        heap = [(node.val, i, node) for i, node in enumerate(lists) if node]
        heapq.heapify(heap)
        dummy = tail = ListNode()
        while heap:
            _, i, node = heapq.heappop(heap)
            tail.next = node
            tail = node
            if node.next:
                heapq.heappush(heap, (node.next.val, i, node.next))
        return dummy.next
''',
    brute='''class Solution:
    def mergeKLists(self, lists):
        vals = []
        for l in lists:
            while l:
                vals.append(l.val); l = l.next
        dummy = t = ListNode()
        for v in sorted(vals):
            t.next = ListNode(v); t = t.next
        return dummy.next
''',
    small_gen='''def gen(rng):
    return [[sorted(rng.randint(-5, 5) for _ in range(rng.randint(0, 4))) for _ in range(rng.randint(0, 4))]]
''',
    gens=[dict(name="1,000 lists of 10 nodes", code='''def gen(rng):
    return [[sorted(rng.randint(-10000, 10000) for _ in range(10)) for _ in range(1000)]]
''')],
    hints=["Merging lists one after another re-walks the growing result k times: O(k · N).",
           "At every step the next node is the smallest current head — a min-heap finds it in O(log k).",
           "Python cannot compare ListNode objects: push (val, index, node) so ties are broken by index."],
    approach="""Put the head of each list in a **min-heap** keyed by value. Repeatedly pop the smallest node, append it to the result, and push its successor. Each of the N nodes passes through a heap of size ≤ k.

**Divide and conquer** (merge lists in pairs, halving k each round) also gives O(N log k) without a heap.""",
    complexity="O(N log k) time · O(k) space",
    followups=["Merge k sorted arrays — and the k-way merge step of external sorting.", "Find the k-th smallest element across k sorted lists.",
               "Smallest range covering an element from each of k lists (#632)."],
),

dict(
    id="lc199", num=199, title="Binary Tree Right Side View", slug="binary-tree-right-side-view", difficulty="Medium",
    topic="trees", pattern="BFS by level (last node) / DFS right-first", companies=["Meta"],
    kind="function", cls="Solution", method="rightSideView",
    params=[{"name": "root", "type": "TreeNode"}], returns="int[]",
    statement="""Imagine standing on the right side of a binary tree. Return the values of the nodes you can see, ordered from top to bottom — the **rightmost node of each level**.""",
    constraints=["0 ≤ number of nodes ≤ 10⁵", "−100 ≤ Node.val ≤ 100"],
    examples=[
        dict(args=[[1, 2, 3, None, 5, None, 4]], expected=[1, 3, 4]),
        dict(args=[[1, None, 3]], expected=[1, 3]),
        dict(args=[[]], expected=[]),
    ],
    hidden=[dict(args=[[1, 2, 3, 4]], expected=[1, 3, 4]), dict(args=[[1, 2]], expected=[1, 2]), dict(args=[[1, 2, 3, None, 5]])],
    starter='''# Definition for a binary tree node.
# class TreeNode:
#     def __init__(self, val=0, left=None, right=None):
#         self.val = val
#         self.left = left
#         self.right = right
class Solution:
    def rightSideView(self, root: Optional[TreeNode]) -> List[int]:
        pass
''',
    reference='''class Solution:
    def rightSideView(self, root):
        out, level = [], [root] if root else []
        while level:
            out.append(level[-1].val)
            level = [c for n in level for c in (n.left, n.right) if c]
        return out
''',
    brute='''class Solution:
    def rightSideView(self, root):
        seen = {}
        def dfs(n, d):
            if not n:
                return
            seen[d] = n.val          # later (more right) nodes overwrite
            dfs(n.left, d + 1)
            dfs(n.right, d + 1)
        dfs(root, 0)
        return [seen[d] for d in range(len(seen))]
''',
    small_gen='''def gen(rng):
    return [rand_tree(rng, rng.randint(0, 9), -9, 9, distinct=False)]
''',
    gens=[dict(name="Tree with 100,000 nodes", code='''def gen(rng):
    return [rand_tree(rng, 100000, -100, 100, distinct=False)]
''')],
    hints=["Process the tree level by level.", "The last node of each level is visible from the right.",
           "Alternatively, DFS visiting the right child first; the first node reached at each depth is visible."],
    approach="""**Level-order traversal**: for each level, record its last node. Equivalent DFS: visit right before left and record a node the first time its depth is reached.""",
    complexity="O(n) time · O(w) space (w = widest level)",
    followups=["Left side view.", "Return the boundary of the tree (#545).", "View from the top or bottom — needs column indices (see #314)."],
),

dict(
    id="lc314", num=314, title="Binary Tree Vertical Order Traversal", slug="binary-tree-vertical-order-traversal",
    difficulty="Medium", topic="trees", pattern="BFS with column index", companies=["Meta"],
    kind="function", cls="Solution", method="verticalOrder",
    params=[{"name": "root", "type": "TreeNode"}], returns="int[][]",
    statement="""Give every node a column: the root is column 0, a left child is `column − 1` and a right child is `column + 1`.

Return the node values grouped by column, from the leftmost column to the rightmost. Within a column, list nodes **top to bottom**; nodes in the same row and column are listed **left to right**.""",
    constraints=["0 ≤ number of nodes ≤ 10⁴", "−100 ≤ Node.val ≤ 100"],
    examples=[
        dict(args=[[3, 9, 20, None, None, 15, 7]], expected=[[9], [3, 15], [20], [7]]),
        dict(args=[[3, 9, 8, 4, 0, 1, 7]], expected=[[4], [9], [3, 0, 1], [8], [7]]),
        dict(args=[[3, 9, 8, 4, 0, 1, 7, None, None, None, 2, 5]], expected=[[4], [9, 5], [3, 0, 1], [8, 2], [7]]),
    ],
    hidden=[dict(args=[[]], expected=[]), dict(args=[[1]], expected=[[1]]), dict(args=[[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]])],
    starter='''# Definition for a binary tree node.
# class TreeNode:
#     def __init__(self, val=0, left=None, right=None):
#         self.val = val
#         self.left = left
#         self.right = right
class Solution:
    def verticalOrder(self, root: Optional[TreeNode]) -> List[List[int]]:
        pass
''',
    reference='''class Solution:
    def verticalOrder(self, root):
        if not root:
            return []
        cols = defaultdict(list)
        q = deque([(root, 0)])
        lo = hi = 0
        while q:
            node, c = q.popleft()
            cols[c].append(node.val)
            lo, hi = min(lo, c), max(hi, c)
            if node.left:
                q.append((node.left, c - 1))
            if node.right:
                q.append((node.right, c + 1))
        return [cols[c] for c in range(lo, hi + 1)]
''',
    brute='''class Solution:
    def verticalOrder(self, root):
        if not root:
            return []
        order = {}
        q = [root]
        for n in q:                       # BFS index gives top-to-bottom, left-to-right
            order[id(n)] = len(order)
            q.extend(c for c in (n.left, n.right) if c)
        items = []
        def dfs(n, col, depth):
            if not n:
                return
            items.append((col, depth, order[id(n)], n.val))
            dfs(n.left, col - 1, depth + 1)
            dfs(n.right, col + 1, depth + 1)
        dfs(root, 0, 0)
        items.sort()
        out = []
        for col, _, _, v in items:
            if not out or out[-1][0] != col:
                out.append((col, []))
            out[-1][1].append(v)
        return [vals for _, vals in out]
''',
    small_gen='''def gen(rng):
    return [rand_tree(rng, rng.randint(0, 10), -9, 9, distinct=False)]
''',
    gens=[dict(name="Tree with 10,000 nodes", code='''def gen(rng):
    return [rand_tree(rng, 10000, -100, 100, distinct=False)]
''')],
    hints=["Track (node, column) pairs as you traverse.",
           "BFS naturally produces top-to-bottom, left-to-right order within each column; DFS does not.",
           "Remember the minimum and maximum column so you can output columns in order without sorting."],
    approach="""**BFS carrying a column index.** Append each node's value to `cols[column]` as it is dequeued; BFS order already satisfies the top-to-bottom, left-to-right rule. Track the smallest and largest column and read the groups out in order.

A DFS would visit a deep left node before a shallow right node in the same column, which breaks the ordering unless you also record depth and sort.""",
    complexity="O(n) time · O(n) space",
    followups=["Vertical Order Traversal (#987): ties in the same row and column sorted by value.",
               "Return only the top view or bottom view.", "Do it with DFS — what extra data do you need?"],
),

dict(
    id="lc236", num=236, title="Lowest Common Ancestor of a Binary Tree", slug="lowest-common-ancestor-of-a-binary-tree",
    difficulty="Medium", topic="trees", pattern="Postorder: report what each subtree contains", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="lowestCommonAncestor",
    params=[{"name": "root", "type": "TreeNode"}, {"name": "p", "type": "TreeNode@0"}, {"name": "q", "type": "TreeNode@0"}],
    returns="TreeNode.val",
    statement="""Given a binary tree (not necessarily a search tree) and two of its nodes `p` and `q`, return their **lowest common ancestor** — the deepest node that has both `p` and `q` as descendants. A node counts as a descendant of itself.

In the tests, `p` and `q` are given by value; the judge passes you the actual node objects and reads `.val` from the node you return.""",
    constraints=["2 ≤ number of nodes ≤ 10⁵", "All values are unique.", "p ≠ q, and both exist in the tree."],
    examples=[
        dict(args=[[3, 5, 1, 6, 2, 0, 8, None, None, 7, 4], 5, 1], expected=3),
        dict(args=[[3, 5, 1, 6, 2, 0, 8, None, None, 7, 4], 5, 4], expected=5, explanation="A node is its own descendant."),
        dict(args=[[1, 2], 1, 2], expected=1),
    ],
    hidden=[dict(args=[[3, 5, 1, 6, 2, 0, 8, None, None, 7, 4], 7, 8]), dict(args=[[1, 2, 3, None, 4], 4, 3])],
    starter='''# Definition for a binary tree node.
# class TreeNode:
#     def __init__(self, x):
#         self.val = x
#         self.left = None
#         self.right = None
class Solution:
    def lowestCommonAncestor(self, root: 'TreeNode', p: 'TreeNode', q: 'TreeNode') -> 'TreeNode':
        pass
''',
    reference='''class Solution:
    def lowestCommonAncestor(self, root, p, q):
        # iterative to stay safe on deep trees: record parents, then walk up
        parent = {root: None}
        stack = [root]
        while p not in parent or q not in parent:
            node = stack.pop()
            for c in (node.left, node.right):
                if c:
                    parent[c] = node
                    stack.append(c)
        ancestors = set()
        while p:
            ancestors.add(p)
            p = parent[p]
        while q not in ancestors:
            q = parent[q]
        return q
''',
    brute='''class Solution:
    def lowestCommonAncestor(self, root, p, q):
        def path(n, target, acc):
            if not n:
                return None
            acc = acc + [n]
            if n is target:
                return acc
            return path(n.left, target, acc) or path(n.right, target, acc)
        a, b = path(root, p, []), path(root, q, [])
        last = None
        for x, y in zip(a, b):
            if x is y:
                last = x
        return last
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
    hints=["Ask each subtree: does it contain p, q, both, or neither?",
           "If p is found in the left subtree and q in the right, the current node is the answer.",
           "Recursive version: return the node if it is p or q; otherwise return whichever child result is non-null, or the node itself if both are."],
    approach="""**Postorder search.** `lca(node)` returns `node` if it is `p` or `q`; otherwise it recurses into both children. If both sides return non-null, `p` and `q` are split across this node, so it is the LCA. If only one side is non-null, pass that result upward.

```
def lca(node):
    if not node or node is p or node is q: return node
    L, R = lca(node.left), lca(node.right)
    return node if L and R else L or R
```
The reference solution uses parent pointers instead, which avoids deep recursion.""",
    complexity="O(n) time · O(h) space",
    followups=["Nodes have parent pointers (#1650) — O(h) time and O(1) space with the two-pointer trick.",
               "p or q may be missing from the tree (#1644).", "The tree is a BST (#235) — use values to choose a side."],
),

dict(
    id="lc938", num=938, title="Range Sum of BST", slug="range-sum-of-bst", difficulty="Easy", topic="trees",
    pattern="DFS with BST pruning", companies=["Meta"],
    kind="function", cls="Solution", method="rangeSumBST",
    params=[{"name": "root", "type": "TreeNode"}, {"name": "low", "type": "int"}, {"name": "high", "type": "int"}], returns="int",
    statement="""Given the root of a **binary search tree** and a range `[low, high]`, return the sum of all node values inside the range (inclusive). Use the BST property to skip subtrees that cannot contribute.""",
    constraints=["1 ≤ number of nodes ≤ 2 · 10⁴", "All values are unique.", "1 ≤ low ≤ high ≤ 10⁶"],
    examples=[
        dict(args=[[10, 5, 15, 3, 7, None, 18], 7, 15], expected=32, explanation="7 + 10 + 15."),
        dict(args=[[10, 5, 15, 3, 7, 13, 18, 1, None, 6], 6, 10], expected=23),
    ],
    hidden=[dict(args=[[5], 1, 4]), dict(args=[[5], 5, 5]), dict(args=[[10, 5, 15], 1, 100])],
    starter='''# Definition for a binary tree node.
# class TreeNode:
#     def __init__(self, val=0, left=None, right=None):
#         self.val = val
#         self.left = left
#         self.right = right
class Solution:
    def rangeSumBST(self, root: Optional[TreeNode], low: int, high: int) -> int:
        pass
''',
    reference='''class Solution:
    def rangeSumBST(self, root, low, high):
        total, stack = 0, [root]
        while stack:
            node = stack.pop()
            if not node:
                continue
            if low <= node.val <= high:
                total += node.val
            if node.val > low:
                stack.append(node.left)
            if node.val < high:
                stack.append(node.right)
        return total
''',
    brute='''class Solution:
    def rangeSumBST(self, root, low, high):
        def walk(n):
            return 0 if not n else walk(n.left) + walk(n.right) + (n.val if low <= n.val <= high else 0)
        return walk(root)
''',
    small_gen='''def gen(rng):
    t = rand_tree(rng, rng.randint(1, 10), bst=True)
    a, b = sorted(rng.randint(1, 100) for _ in range(2))
    return [t, a, b]
''',
    gens=[dict(name="BST with 20,000 nodes", code='''def gen(rng):
    return [rand_tree(rng, 20000, bst=True), 1000, 3000]
''')],
    hints=["A plain traversal adding values in range already works in O(n).",
           "If node.val < low, nothing in its left subtree can be in range — skip it.",
           "Symmetrically, if node.val > high, skip the right subtree."],
    approach="""DFS, adding values within `[low, high]`, but only descend left when `node.val > low` and right when `node.val < high`. The pruning keeps the work proportional to the nodes in (and bordering) the range.""",
    complexity="O(n) worst case, O(h + k) with pruning (k nodes in range) · O(h) space",
    followups=["Many range queries on a static BST — precompute prefix sums over the inorder sequence.",
               "Count the nodes in range instead.", "The tree is not a BST — what changes?"],
),

dict(
    id="lc543", num=543, title="Diameter of Binary Tree", slug="diameter-of-binary-tree", difficulty="Easy", topic="trees",
    pattern="Postorder heights", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="diameterOfBinaryTree",
    params=[{"name": "root", "type": "TreeNode"}], returns="int",
    statement="""The **diameter** of a binary tree is the number of **edges** on the longest path between any two nodes. The path does not have to pass through the root. Return the diameter.""",
    constraints=["1 ≤ number of nodes ≤ 10⁴", "−100 ≤ Node.val ≤ 100"],
    examples=[
        dict(args=[[1, 2, 3, 4, 5]], expected=3, explanation="Path 4 → 2 → 1 → 3 (or 5 → 2 → 1 → 3)."),
        dict(args=[[1, 2]], expected=1),
    ],
    hidden=[dict(args=[[1]], expected=0), dict(args=[[1, 2, None, 3, 4, 5, None, None, 6]])],
    starter='''# Definition for a binary tree node.
# class TreeNode:
#     def __init__(self, val=0, left=None, right=None):
#         self.val = val
#         self.left = left
#         self.right = right
class Solution:
    def diameterOfBinaryTree(self, root: Optional[TreeNode]) -> int:
        pass
''',
    reference='''class Solution:
    def diameterOfBinaryTree(self, root):
        best = 0
        def height(n):
            nonlocal best
            if not n:
                return 0
            L, R = height(n.left), height(n.right)
            best = max(best, L + R)
            return 1 + max(L, R)
        height(root)
        return best
''',
    brute='''class Solution:
    def diameterOfBinaryTree(self, root):
        adj = defaultdict(list); nodes = []
        def walk(n):
            nodes.append(n)
            for c in (n.left, n.right):
                if c:
                    adj[n].append(c); adj[c].append(n); walk(c)
        walk(root)
        best = 0
        for s in nodes:
            dist = {s: 0}; q = [s]
            for u in q:
                for v in adj[u]:
                    if v not in dist:
                        dist[v] = dist[u] + 1; q.append(v)
            best = max(best, max(dist.values()))
        return best
''',
    small_gen='''def gen(rng):
    return [rand_tree(rng, rng.randint(1, 10), distinct=False)]
''',
    gens=[dict(name="Tree with 10,000 nodes", code='''def gen(rng):
    return [rand_tree(rng, 10000, distinct=False)]
''')],
    hints=["The longest path through a node = height(left) + height(right).",
           "Compute heights bottom-up (postorder) and update a global best on the way.",
           "Calling a separate height() for every node is O(n²) on a skewed tree."],
    approach="""One **postorder** pass returns each subtree's height (in nodes). At each node, `height(left) + height(right)` is the longest path bending there; keep the maximum. Each node is processed once.""",
    complexity="O(n) time · O(h) space",
    followups=["Diameter of an n-ary tree (#1522).", "Diameter of a general tree / graph — two BFS passes.",
               "Return the path, not just its length."],
),

dict(
    id="lc124", num=124, title="Binary Tree Maximum Path Sum", slug="binary-tree-maximum-path-sum", difficulty="Hard",
    topic="trees", pattern="Postorder gain with clipping at zero", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="maxPathSum",
    params=[{"name": "root", "type": "TreeNode"}], returns="int",
    statement="""A **path** is a sequence of nodes where consecutive nodes are connected by an edge; each node appears at most once and the path need not pass through the root. A path contains at least one node.

Return the maximum sum of node values over all paths.""",
    constraints=["1 ≤ number of nodes ≤ 3 · 10⁴", "−1000 ≤ Node.val ≤ 1000"],
    examples=[
        dict(args=[[1, 2, 3]], expected=6),
        dict(args=[[-10, 9, 20, None, None, 15, 7]], expected=42, explanation="15 → 20 → 7."),
    ],
    hidden=[dict(args=[[-3]], expected=-3), dict(args=[[2, -1]], expected=2), dict(args=[[-2, -1]], expected=-1), dict(args=[[5, 4, 8, 11, None, 13, 4, 7, 2, None, None, None, 1]])],
    starter='''# Definition for a binary tree node.
# class TreeNode:
#     def __init__(self, val=0, left=None, right=None):
#         self.val = val
#         self.left = left
#         self.right = right
class Solution:
    def maxPathSum(self, root: Optional[TreeNode]) -> int:
        pass
''',
    reference='''class Solution:
    def maxPathSum(self, root):
        best = float("-inf")
        def gain(n):
            nonlocal best
            if not n:
                return 0
            L = max(gain(n.left), 0)
            R = max(gain(n.right), 0)
            best = max(best, n.val + L + R)
            return n.val + max(L, R)
        gain(root)
        return best
''',
    brute='''class Solution:
    def maxPathSum(self, root):
        adj = defaultdict(list); nodes = []
        def walk(n):
            nodes.append(n)
            for c in (n.left, n.right):
                if c:
                    adj[n].append(c); adj[c].append(n); walk(c)
        walk(root)
        best = float("-inf")
        for s in nodes:                      # every simple path in a tree = DFS from every start
            stack = [(s, None, s.val)]
            while stack:
                u, par, tot = stack.pop()
                best = max(best, tot)
                for v in adj[u]:
                    if v is not par:
                        stack.append((v, u, tot + v.val))
        return best
''',
    small_gen='''def gen(rng):
    return [rand_tree(rng, rng.randint(1, 9), -10, 10, distinct=False)]
''',
    gens=[dict(name="Tree with 30,000 nodes", code='''def gen(rng):
    return [rand_tree(rng, 30000, -1000, 1000, distinct=False)]
''')],
    hints=["Every path has a single highest node where it bends.",
           "For each node, compute the best downward 'gain' starting there: val + max(left gain, right gain, 0).",
           "The best path bending at node = val + max(left gain, 0) + max(right gain, 0). Track the global maximum."],
    approach="""Postorder. `gain(n)` = best sum of a path that **starts at n and goes down** one side: `n.val + max(gain(left), gain(right), 0)` — negative branches are clipped to 0. While computing it, the best path **bending at n** is `n.val + max(gainL, 0) + max(gainR, 0)`; keep the maximum over all nodes.

Initialise the answer to −∞, not 0: all values may be negative.""",
    complexity="O(n) time · O(h) space",
    followups=["Return the path itself.", "Maximum path sum between two leaves.", "Same question on a general tree / DAG."],
),
]
