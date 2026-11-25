# Practice bank — stacks and string parsing.

PROBLEMS = [
dict(
    id="lc1249", num=1249, title="Minimum Remove to Make Valid Parentheses", slug="minimum-remove-to-make-valid-parentheses",
    difficulty="Medium", topic="stacks", pattern="Stack of indices / two passes", companies=["Meta"],
    kind="function", cls="Solution", method="minRemoveToMakeValid",
    params=[{"name": "s", "type": "str"}], returns="str", compare="custom",
    statement="""`s` contains `'('`, `')'` and lowercase letters. Remove the **minimum number** of parentheses so that the result is a valid parentheses string, and return it.

A string is valid if every `')'` closes an earlier unmatched `'('` and nothing is left open. Letters are ignored for validity. Any valid result with the minimum number of removals is accepted.""",
    constraints=["1 ≤ s.length ≤ 10⁵", "s[i] is '(', ')' or a lowercase letter."],
    examples=[
        dict(args=["lee(t(c)o)de)"], expected="lee(t(c)o)de", explanation='"lee(t(co)de)" and "lee(t(c)ode)" are also accepted.'),
        dict(args=["a)b(c)d"], expected="ab(c)d"),
        dict(args=["))(("], expected=""),
    ],
    hidden=[dict(args=["(a(b(c)d)"]), dict(args=["abc"]), dict(args=["((("]), dict(args=[")("]), dict(args=["())()((("])],
    starter='''class Solution:
    def minRemoveToMakeValid(self, s: str) -> str:
        pass
''',
    reference='''class Solution:
    def minRemoveToMakeValid(self, s):
        chars = list(s)
        stack = []
        for i, c in enumerate(chars):
            if c == "(":
                stack.append(i)
            elif c == ")":
                if stack:
                    stack.pop()
                else:
                    chars[i] = ""
        for i in stack:
            chars[i] = ""
        return "".join(chars)

def check(args, got, expected):
    s = args[0]
    if not isinstance(got, str) or len(got) != len(expected):
        return False
    it = iter(s)
    if not all(c in it for c in got):          # got must be a subsequence of s
        return False
    if [c for c in got if c not in "()"] != [c for c in s if c not in "()"]:
        return False
    bal = 0
    for c in got:
        bal += (c == "(") - (c == ")")
        if bal < 0:
            return False
    return bal == 0
''',
    brute='''from itertools import combinations
class Solution:
    def minRemoveToMakeValid(self, s):
        def ok(t):
            b = 0
            for c in t:
                b += (c == "(") - (c == ")")
                if b < 0:
                    return False
            return b == 0
        idx = [i for i, c in enumerate(s) if c in "()"]
        for k in range(len(idx) + 1):
            for drop in combinations(idx, k):
                d = set(drop)
                t = "".join(c for i, c in enumerate(s) if i not in d)
                if ok(t):
                    return t
''',
    small_gen='''def gen(rng):
    return ["".join(rng.choice("()(a)") for _ in range(rng.randint(1, 9)))]
''',
    gens=[dict(name="Long string (n = 100,000)", code='''def gen(rng):
    return ["".join(rng.choice("(()a)") for _ in range(100000))]
''')],
    hints=["A ')' is invalid if there is no unmatched '(' before it.",
           "Push the index of each '(' on a stack; a ')' pops one or is marked for removal.",
           "Whatever indices are left on the stack at the end are unmatched '(' — remove them too."],
    approach="""**Stack of indices.** Scan left to right. Push the index of every `'('`. A `')'` pops a match, or is marked for deletion if the stack is empty. After the scan, the indices still on the stack are unmatched `'('` — delete them. Every deletion was forced, so the count is minimal.

O(1)-extra-space variant: a left-to-right pass drops unmatched `')'`, then a right-to-left pass drops the excess `'('`.""",
    complexity="O(n) time · O(n) space",
    followups=["Do it without a stack (two passes with counters).",
               "Return all valid strings with the minimum number of removals (#301, BFS / backtracking).",
               "Only return how many removals are needed (#921)."],
),

dict(
    id="lc227", num=227, title="Basic Calculator II", slug="basic-calculator-ii", difficulty="Medium", topic="stacks",
    pattern="Operator precedence with a stack", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="calculate",
    params=[{"name": "s", "type": "str"}], returns="int",
    statement="""Evaluate the expression `s`, which contains non-negative integers, the operators `+ - * /` and spaces. Integer division **truncates toward zero**. `*` and `/` bind tighter than `+` and `-`.

Do not use `eval()` or any built-in expression evaluator.""",
    constraints=["1 ≤ s.length ≤ 3 · 10⁵", "The expression is valid; all intermediate results fit in a 32-bit integer.", "No parentheses."],
    examples=[
        dict(args=["3+2*2"], expected=7),
        dict(args=[" 3/2 "], expected=1),
        dict(args=[" 3+5 / 2 "], expected=5),
    ],
    hidden=[dict(args=["14-3/2"], expected=13), dict(args=["0"], expected=0), dict(args=["1-1+1"], expected=1),
            dict(args=["2*3*4"], expected=24), dict(args=["100000000/1/2/3/4/5/6/7/8/9/10"], expected=27),
            dict(args=["1 - 2*3 + 10/4"], expected=-3), dict(args=["42"], expected=42)],
    starter='''class Solution:
    def calculate(self, s: str) -> int:
        pass
''',
    reference='''class Solution:
    def calculate(self, s):
        stack, num, op = [], 0, "+"
        s = s + "+"
        for c in s:
            if c.isdigit():
                num = num * 10 + int(c)
            elif c in "+-*/":
                if op == "+":
                    stack.append(num)
                elif op == "-":
                    stack.append(-num)
                elif op == "*":
                    stack.append(stack.pop() * num)
                else:
                    stack.append(int(stack.pop() / num))
                op, num = c, 0
        return sum(stack)
''',
    brute='''class Solution:
    def calculate(self, s):
        # terms are non-negative, so floor division equals truncation here
        return eval(s.replace("/", "//"))
''',
    small_gen='''def gen(rng):
    parts = [str(rng.randint(0, 20))]
    for _ in range(rng.randint(0, 6)):
        op = rng.choice("+-*/")
        parts.append(op)
        parts.append(str(rng.randint(1, 20)))
    sp = lambda: " " * rng.randint(0, 1)
    return [sp().join(parts)]
''',
    gens=[dict(name="Long expression", code='''def gen(rng):
    parts = [str(rng.randint(0, 9))]
    for _ in range(60000):
        op = rng.choice("+-*")
        parts.append(op); parts.append(str(rng.randint(0, 1) if op == "*" else rng.randint(0, 9)))
    return [" ".join(parts)]
''')],
    hints=["Read one number at a time and remember the operator that came before it.",
           "'+' and '-' can be deferred: push +num or −num on a stack.",
           "'*' and '/' must apply immediately to the top of the stack. The answer is the stack's sum."],
    approach="""Scan once, keeping the current `num` and the **previous operator** `op`. When an operator (or the end) arrives, apply `op` to `num`:

* `+` → push `num`; `-` → push `−num` (deferred addition);
* `*` / `/` → replace the top of the stack with `top * num` or `int(top / num)` (truncation toward zero).

The answer is the sum of the stack. Since `*` and `/` are resolved immediately, precedence comes for free. The stack can be replaced by a single 'last term' variable for O(1) space.""",
    complexity="O(n) time · O(n) space (O(1) with a last-term variable)",
    followups=["Add parentheses (Basic Calculator III, #772) — recursion or a stack of contexts.",
               "Support unary minus and parentheses (#224).", "Do it in O(1) extra space."],
),

dict(
    id="lc71", num=71, title="Simplify Path", slug="simplify-path", difficulty="Medium", topic="stacks",
    pattern="Stack of path components", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="simplifyPath",
    params=[{"name": "path", "type": "str"}], returns="str",
    statement="""Convert an absolute Unix-style `path` into its simplified **canonical** form:

* `.` means the current directory and `..` the parent directory (the parent of root is root);
* multiple consecutive slashes count as one;
* any other name — including `...` — is a regular directory name.

The canonical path starts with a single `/`, separates names with single slashes, and has no trailing slash (unless it is just `/`).""",
    constraints=["1 ≤ path.length ≤ 3000", "path is an absolute path made of letters, digits, '.', '/' and '_'."],
    examples=[
        dict(args=["/home/"], expected="/home"),
        dict(args=["/home//foo/"], expected="/home/foo"),
        dict(args=["/home/user/Documents/../Pictures"], expected="/home/user/Pictures"),
        dict(args=["/../"], expected="/"),
        dict(args=["/.../a/../b/c/../d/./"], expected="/.../b/d"),
    ],
    hidden=[dict(args=["/"]), dict(args=["/a/./b/../../c/"]), dict(args=["/a//b////c/d//././/.."]), dict(args=["/..hidden/."])],
    starter='''class Solution:
    def simplifyPath(self, path: str) -> str:
        pass
''',
    reference='''class Solution:
    def simplifyPath(self, path):
        stack = []
        for part in path.split("/"):
            if part == "..":
                if stack:
                    stack.pop()
            elif part and part != ".":
                stack.append(part)
        return "/" + "/".join(stack)
''',
    brute='''import posixpath, re
class Solution:
    def simplifyPath(self, path):
        p = posixpath.normpath(re.sub("/+", "/", path))
        return "/" if p in ("", "/", "//") else p
''',
    small_gen='''def gen(rng):
    parts = [rng.choice(["a", "b", ".", "..", "...", ""]) for _ in range(rng.randint(0, 7))]
    return ["/" + "/".join(parts)]
''',
    hints=["Split on '/' and handle each piece.",
           "Empty pieces and '.' do nothing; '..' undoes the last directory if there is one.",
           "A stack of directory names holds exactly the canonical path."],
    approach="""Split the path on `/`. Ignore empty pieces and `.`; on `..` pop the stack if it is not empty; push anything else. Join the stack with `/` and prefix a single `/`.""",
    complexity="O(n) time · O(n) space",
    followups=["Support a current working directory and relative paths (cd command simulation).",
               "Resolve symbolic links given as a mapping.", "Return the result as a list of components for a file-system tree lookup."],
),

dict(
    id="lc739", num=739, title="Daily Temperatures", slug="daily-temperatures", difficulty="Medium", topic="stacks",
    pattern="Monotonic stack", companies=["Meta", "Google"],
    kind="function", cls="Solution", method="dailyTemperatures",
    params=[{"name": "temperatures", "type": "int[]"}], returns="int[]",
    statement="""For each day `i`, return how many days you have to wait after day `i` for a **strictly warmer** temperature. If no warmer day follows, the answer for that day is `0`.""",
    constraints=["1 ≤ temperatures.length ≤ 10⁵", "30 ≤ temperatures[i] ≤ 100"],
    examples=[
        dict(args=[[73, 74, 75, 71, 69, 72, 76, 73]], expected=[1, 1, 4, 2, 1, 1, 0, 0]),
        dict(args=[[30, 40, 50, 60]], expected=[1, 1, 1, 0]),
        dict(args=[[30, 60, 90]], expected=[1, 1, 0]),
    ],
    hidden=[dict(args=[[50]]), dict(args=[[90, 80, 70]]), dict(args=[[55, 55, 56]])],
    starter='''class Solution:
    def dailyTemperatures(self, temperatures: List[int]) -> List[int]:
        pass
''',
    reference='''class Solution:
    def dailyTemperatures(self, temperatures):
        res = [0] * len(temperatures)
        stack = []
        for i, t in enumerate(temperatures):
            while stack and temperatures[stack[-1]] < t:
                j = stack.pop()
                res[j] = i - j
            stack.append(i)
        return res
''',
    brute='''class Solution:
    def dailyTemperatures(self, temperatures):
        n = len(temperatures); res = [0] * n
        for i in range(n):
            for j in range(i + 1, n):
                if temperatures[j] > temperatures[i]:
                    res[i] = j - i
                    break
        return res
''',
    small_gen='''def gen(rng):
    return [[rng.randint(30, 36) for _ in range(rng.randint(1, 10))]]
''',
    gens=[dict(name="Cooling trend (n = 100,000)", code='''def gen(rng):
    return [sorted((rng.randint(30, 100) for _ in range(100000)), reverse=True)]
''')],
    hints=["The brute force scans forward from every day: O(n²) on a cooling trend.",
           "Keep the days still waiting for a warmer day on a stack.",
           "A new day resolves every waiting day that is colder; each index is pushed and popped once."],
    approach="""**Monotonic decreasing stack of indices.** For each day `i`, pop every waiting day `j` with a lower temperature — day `i` is its answer, so `res[j] = i − j`. Then push `i`. Indices left on the stack never find a warmer day and keep 0.""",
    complexity="O(n) time · O(n) space",
    followups=["Previous warmer day instead of next.", "Next greater element in a circular array (#503).",
               "Use the 30–100 range to solve it scanning right-to-left with an array of next occurrences."],
),

dict(
    id="lc921", num=921, title="Minimum Add to Make Parentheses Valid", slug="minimum-add-to-make-parentheses-valid",
    difficulty="Medium", topic="stacks", pattern="Balance counter", companies=["Meta"],
    kind="function", cls="Solution", method="minAddToMakeValid",
    params=[{"name": "s", "type": "str"}], returns="int",
    statement="""`s` contains only `'('` and `')'`. In one move you can insert a parenthesis anywhere. Return the minimum number of moves to make `s` valid.""",
    constraints=["1 ≤ s.length ≤ 1000"],
    examples=[
        dict(args=["())"], expected=1),
        dict(args=["((("], expected=3),
    ],
    hidden=[dict(args=["()"]), dict(args=["()))(("]), dict(args=[")"]), dict(args=["(()())"])],
    starter='''class Solution:
    def minAddToMakeValid(self, s: str) -> int:
        pass
''',
    reference='''class Solution:
    def minAddToMakeValid(self, s):
        open_ = adds = 0
        for c in s:
            if c == "(":
                open_ += 1
            elif open_:
                open_ -= 1
            else:
                adds += 1
        return adds + open_
''',
    brute='''class Solution:
    def minAddToMakeValid(self, s):
        while "()" in s:
            s = s.replace("()", "")
        return len(s)
''',
    small_gen='''def gen(rng):
    return ["".join(rng.choice("()") for _ in range(rng.randint(1, 12)))]
''',
    hints=["Track how many '(' are currently unmatched.",
           "A ')' with nothing to match needs one inserted '(' before it.",
           "At the end, every unmatched '(' needs one ')'."],
    approach="""Keep `open_`, the number of unmatched `'('`. A `')'` either consumes one, or — if none is open — forces an insertion (`adds += 1`). The answer is the forced insertions plus whatever remains open at the end.""",
    complexity="O(n) time · O(1) space",
    followups=["Return one valid string after the minimum insertions.",
               "Each '(' must be matched by two consecutive '))' (#1541).", "Removal instead of insertion (#1249)."],
),
]
