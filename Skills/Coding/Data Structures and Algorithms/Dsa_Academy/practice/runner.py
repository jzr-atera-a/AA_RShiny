"""
DSA Academy — local test runner.

Runs a candidate's Python solution against a problem's tests, LeetCode style.

Usage:  python runner.py <job.json>

The job file is written by the Shiny app (practice/engine.R). Progress is
streamed on stdout as protocol lines so that the app can still name the test
that was running if the whole process has to be killed for taking too long:

    @@START <index>        a test is about to run
    @@DONE <json>          final result object

Everything the candidate prints is captured per test and returned in the JSON.
"""

import contextlib
import copy
import io
import json
import math
import os
import random
import signal
import sys
import time
import traceback

sys.setrecursionlimit(20000)

PREAMBLE = '''
from typing import *
from collections import *
from heapq import *
from bisect import *
from functools import *
from itertools import *
from math import inf, gcd, sqrt, ceil, floor, log2
import collections, heapq, bisect, math, itertools, functools, string, re, random, operator   # after the star imports, so bisect is the module

class ListNode:
    def __init__(self, val=0, next=None):
        self.val = val
        self.next = next
    def __repr__(self):
        return "ListNode(%r)" % (self.val,)

class TreeNode:
    def __init__(self, val=0, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right
    def __repr__(self):
        return "TreeNode(%r)" % (self.val,)

class Node:
    """Generic node used by several problems (left/right, plus parent or next pointers)."""
    def __init__(self, val=0, left=None, right=None, parent=None, next=None):
        self.val = val
        self.left = left
        self.right = right
        self.parent = parent
        self.next = next
    def __repr__(self):
        return "Node(%r)" % (self.val,)

class NestedInteger:
    """LeetCode's NestedInteger interface: holds either a single integer or a list of NestedIntegers."""
    def __init__(self, value=None):
        self._int = value if isinstance(value, int) else None
        self._list = [] if not isinstance(value, int) else None
    def isInteger(self):
        return self._int is not None
    def getInteger(self):
        return self._int
    def getList(self):
        return self._list
    def setInteger(self, value):
        self._int, self._list = value, None
    def add(self, elem):
        if self._list is None:
            self._list, self._int = [], None
        self._list.append(elem)
    def __repr__(self):
        return repr(self._int) if self._int is not None else repr(self._list)
'''
PREAMBLE_LINES = PREAMBLE.count("\n")
OUT = sys.__stdout__

# Helpers available to test generators (problem "gens" code)
GEN_HELPERS = '''
def rand_tree(rng, n, lo=-1000, hi=1000, bst=False, distinct=True):
    """Random binary tree as a LeetCode level-order list. Shape comes from random BST
    insertion (expected depth O(log n)). With bst=True the values form a valid BST."""
    if n <= 0:
        return []
    keys = rng.sample(range(1, 10 * n + 1), n)
    left, right = {}, {}
    root = keys[0]
    for k in keys[1:]:
        cur = root
        while True:
            side = left if k < cur else right
            if cur in side:
                cur = side[cur]
            else:
                side[cur] = k
                break
    if bst:
        val = {k: k for k in keys}
    elif distinct and hi - lo + 1 >= n:
        val = dict(zip(keys, rng.sample(range(lo, hi + 1), n)))
    else:
        val = {k: rng.randint(lo, hi) for k in keys}
    out, q, head = [], [root], 0
    while head < len(q):
        k = q[head]
        head += 1
        if k is None:
            out.append(None)
            continue
        out.append(val[k])
        q.append(left.get(k))
        q.append(right.get(k))
    while out and out[-1] is None:
        out.pop()
    return out


def tree_values(level):
    return [v for v in level if v is not None]
'''


def emit(line):
    OUT.write(line + "\n")
    OUT.flush()


class TimeLimit(Exception):
    pass


HAS_ALARM = hasattr(signal, "SIGALRM") and hasattr(signal, "setitimer")


def _alarm(signum, frame):
    raise TimeLimit()


if HAS_ALARM:
    signal.signal(signal.SIGALRM, _alarm)


@contextlib.contextmanager
def time_limit(seconds):
    if HAS_ALARM:
        signal.setitimer(signal.ITIMER_REAL, seconds)
    try:
        yield
    finally:
        if HAS_ALARM:
            signal.setitimer(signal.ITIMER_REAL, 0)


# ── Conversions between JSON values and Python objects ─────────────────────────
def build_list(ns, values):
    dummy = ns["ListNode"]()
    tail = dummy
    for v in values or []:
        tail.next = ns["ListNode"](v)
        tail = tail.next
    return dummy.next


def build_tree(ns, values):
    if not values or values[0] is None:
        return None
    T = ns["TreeNode"]
    root = T(values[0])
    queue = [root]
    i, head = 1, 0
    while head < len(queue) and i < len(values):
        node = queue[head]
        head += 1
        if i < len(values) and values[i] is not None:
            node.left = T(values[i])
            queue.append(node.left)
        i += 1
        if i < len(values) and values[i] is not None:
            node.right = T(values[i])
            queue.append(node.right)
        i += 1
    return root


def list_to_json(node):
    out, seen = [], 0
    while node is not None:
        out.append(node.val)
        node = node.next
        seen += 1
        if seen > 2_000_000:
            raise ValueError("The returned linked list appears to contain a cycle.")
    return out


def tree_to_json(root):
    if root is None:
        return []
    out, queue, head = [], [root], 0
    while head < len(queue):
        node = queue[head]
        head += 1
        if node is None:
            out.append(None)
            continue
        out.append(node.val)
        queue.append(node.left)
        queue.append(node.right)
        if len(queue) > 4_000_000:
            raise ValueError("The returned tree is too large or contains a cycle.")
    while out and out[-1] is None:
        out.pop()
    return out


def find_node(root, val):
    stack = [root]
    while stack:
        n = stack.pop()
        if n is None:
            continue
        if n.val == val:
            return n
        stack.append(n.left)
        stack.append(n.right)
    return None


def build_nested(ns, value):
    NI = ns["NestedInteger"]
    if isinstance(value, int):
        return NI(value)
    ni = NI()
    for v in value:
        ni.add(build_nested(ns, v))
    return ni


def build_node_tree(ns, values, parents=False):
    t = build_tree(ns, values)
    N = ns["Node"]
    def conv(x, par):
        if x is None:
            return None
        n = N(x.val)
        if parents:
            n.parent = par
        n.left, n.right = conv(x.left, n), conv(x.right, n)
        return n
    return conv(t, None)


def to_py(ns, typ, value, converted):
    """JSON value -> argument object."""
    if typ == "NestedInteger[]":
        return [build_nested(ns, v) for v in value]
    if typ in ("NodeTree", "ParentTree"):
        return build_node_tree(ns, value, parents=(typ == "ParentTree"))
    if typ.startswith("ParentNode@") or typ.startswith("Node@"):
        return find_node(converted[int(typ.split("@")[1])], value)
    if typ == "ListNode":
        return build_list(ns, value)
    if typ == "ListNode[]":
        return [build_list(ns, v) for v in value]
    if typ == "TreeNode":
        return build_tree(ns, value)
    if typ.startswith("TreeNode@"):
        idx = int(typ.split("@")[1])
        return find_node(converted[idx], value)
    return copy.deepcopy(value)


def jsonable(x):
    if isinstance(x, (str, int, float, bool)) or x is None:
        if isinstance(x, float) and (math.isnan(x) or math.isinf(x)):
            return repr(x)
        return x
    if isinstance(x, (list, tuple)):
        return [jsonable(v) for v in x]
    if isinstance(x, (set, frozenset)):
        return sorted((jsonable(v) for v in x), key=lambda v: json.dumps(v))
    if isinstance(x, dict):
        return {str(k): jsonable(v) for k, v in x.items()}
    if hasattr(x, "__iter__") and not hasattr(x, "val"):
        return [jsonable(v) for v in x]
    return repr(x)


def to_json(typ, value):
    """Return value -> JSON value."""
    if typ == "ListNode":
        return list_to_json(value)
    if typ == "TreeNode":
        return tree_to_json(value)
    if typ in ("TreeNode.val", "Node.val"):
        return None if value is None else getattr(value, "val", repr(value))
    if typ == "CircularDLL":
        return circular_to_json(value)
    return jsonable(value)


def circular_to_json(head):
    """Values of a circular doubly linked list (via .right), checking every .left link is consistent."""
    if head is None:
        return []
    out, cur, seen = [], head, 0
    while True:
        out.append(cur.val)
        nxt = cur.right
        if nxt is None:
            return "invalid: the list is not circular (a right pointer is None)"
        if nxt.left is not cur:
            return "invalid: node %r.right.left does not point back to it" % (cur.val,)
        cur = nxt
        seen += 1
        if cur is head:
            return out
        if seen > 2_000_000:
            return "invalid: never returned to the head"


# ── Comparison ─────────────────────────────────────────────────────────────────
def key(v):
    return json.dumps(v, sort_keys=True)


def approx(a, b, tol=1e-5):
    if isinstance(a, bool) or isinstance(b, bool):
        return a is b or a == b and type(a) == type(b)
    if isinstance(a, (int, float)) and isinstance(b, (int, float)):
        return abs(a - b) <= tol * max(1.0, abs(b))
    if isinstance(a, list) and isinstance(b, list):
        return len(a) == len(b) and all(approx(x, y, tol) for x, y in zip(a, b))
    return a == b


def strict_equal(a, b):
    if isinstance(b, bool) or isinstance(a, bool):
        return type(a) == type(b) and a == b
    if isinstance(a, list) and isinstance(b, list):
        return len(a) == len(b) and all(strict_equal(x, y) for x, y in zip(a, b))
    if isinstance(a, float) or isinstance(b, float):
        return approx(a, b)
    return a == b


def compare(mode, got, exp, args, ref_ns):
    if mode == "custom":
        return bool(ref_ns["check"](copy.deepcopy(args), got, exp))
    if mode == "float":
        return approx(got, exp)
    if mode == "unordered":
        if not isinstance(got, list):
            return False
        return sorted(map(key, got)) == sorted(map(key, exp))
    if mode == "unordered_nested":
        if not isinstance(got, list) or not all(isinstance(g, list) for g in got):
            return False
        norm = lambda xs: sorted(key(sorted(map(key, inner))) for inner in xs)
        return norm(got) == norm(exp)
    return strict_equal(got, exp)


# ── Loading code ───────────────────────────────────────────────────────────────
def load(code, filename):
    ns = {"__name__": "__solution__"}
    exec(compile(PREAMBLE, "<preamble>", "exec"), ns)
    exec(compile(code, filename, "exec"), ns)
    return ns


def short_traceback(exc, filename="solution.py"):
    tb = traceback.extract_tb(exc.__traceback__)
    frames = [f for f in tb if f.filename == filename]
    line = frames[-1].lineno if frames else None
    lines = []
    for f in frames[-4:]:
        lines.append('  line %d, in %s\n    %s' % (f.lineno, f.name, (f.line or "").strip()))
    name = type(exc).__name__
    msg = str(exc)
    if isinstance(exc, RecursionError):
        msg = "maximum recursion depth exceeded — is a base case missing, or is the recursion too deep for this input?"
    text = ("Traceback (most recent call last):\n" + "\n".join(lines) + "\n" if lines else "") + "%s: %s" % (name, msg)
    return text, line


def display_args(params, args):
    out = []
    for p, a in zip(params, args):
        s = json.dumps(a)
        if len(s) > 240:
            n = len(a) if isinstance(a, (list, str)) else None
            s = s[:220] + " …" + (" (length %d)" % n if n is not None else "")
        out.append("%s = %s" % (p["name"], s))
    return out


def clip(v, n=600):
    s = json.dumps(v)
    return s if len(s) <= n else s[: n - 20] + " … (truncated)"


# ── Executing one test ─────────────────────────────────────────────────────────
def call(ns, prob, args):
    """Run one test against the solution namespace ns. Returns (json_output, seconds, stdout)."""
    buf = io.StringIO()
    if prob["kind"] == "design":
        ops, opargs = args["ops"], args["args"]
        cls = ns[prob["cls"]]
        out = []
        start = time.perf_counter()
        with contextlib.redirect_stdout(buf):
            obj = None
            for op, a in zip(ops, opargs):
                if obj is None:
                    ctor = prob.get("ctor_types")
                    if ctor:
                        conv = []
                        for t, v in zip(ctor, a):
                            conv.append(to_py(ns, t, v, conv))
                        obj = cls(*conv)
                    else:
                        obj = cls(*copy.deepcopy(a))
                    out.append(None)
                else:
                    out.append(jsonable(getattr(obj, op)(*copy.deepcopy(a))))
        return out, time.perf_counter() - start, buf.getvalue()
    params = prob["params"]
    converted = []
    for p, a in zip(params, args):
        converted.append(to_py(ns, p["type"], a, converted))
    method = getattr(ns[prob["cls"]](), prob["method"])
    passed = [c for p, c in zip(params, converted) if p.get("pass", True)]
    start = time.perf_counter()
    with contextlib.redirect_stdout(buf):
        ret = method(*passed)
    elapsed = time.perf_counter() - start
    if prob.get("inplace") is not None:
        i = prob["inplace"]
        result = to_json(params[i]["type"], converted[i])
    else:
        result = to_json(prob["returns"], ret)
    return result, elapsed, buf.getvalue()


def parse_custom(prob, text):
    lines = [ln for ln in (text or "").splitlines() if ln.strip()]
    per = 2 if prob["kind"] == "design" else len(prob["params"])
    if not lines:
        return [], None
    if len(lines) % per:
        return None, "Each custom test needs %d line(s) — one JSON value per %s. Got %d line(s)." % (
            per, "line: the operations list, then the arguments list" if prob["kind"] == "design" else "parameter", len(lines))
    cases = []
    for i in range(0, len(lines), per):
        try:
            vals = [json.loads(ln) for ln in lines[i:i + per]]
        except Exception as e:
            return None, "Custom input line %d is not valid JSON (%s). Strings need double quotes; use true/false/null." % (i + 1, e)
        cases.append({"ops": vals[0], "args": vals[1]} if prob["kind"] == "design" else vals)
    return cases, None


def main():
    job = json.load(open(sys.argv[1], encoding="utf-8"))
    mode = job.get("mode", "run")
    if "problem_id" in job:
        # The app only sends the problem id; tests come straight from the bank file.
        bank_path = job.get("bank") or os.path.join(os.path.dirname(os.path.abspath(__file__)), "problems.json")
        bank = {p["id"]: p for p in json.load(open(bank_path, encoding="utf-8"))}
        prob = bank[job["problem_id"]]
        job["tests"] = [t for t in prob["tests"] if mode == "submit" or not t["hidden"]]
        job["gens"] = prob.get("gens", []) if mode == "submit" else []
    else:
        prob = job["problem"]
    result = {"status": "ok", "cases": [], "mode": mode}

    # 1. Compile the candidate's code
    try:
        compile(job["code"], "solution.py", "exec")
    except SyntaxError as e:
        hint = ""
        if isinstance(e, (IndentationError, TabError)):
            hint = ("Python uses indentation as syntax. Inside class Solution the method line is indented 4 spaces "
                    "and its body 8 spaces; each nested block adds 4 more. Do not mix tabs and spaces.")
        result.update(status="compile_error", verdict="Compile Error",
                      error={"type": type(e).__name__, "msg": e.msg, "line": e.lineno, "offset": e.offset,
                             "text": (e.text or "").rstrip("\n"), "hint": hint})
        emit("@@DONE " + json.dumps(result))
        return

    try:
        ref_ns = load(prob["reference"], "reference.py")
    except Exception as e:
        result.update(status="setup_error", verdict="Internal Error", error={"msg": "Reference solution failed to load: %r" % e})
        emit("@@DONE " + json.dumps(result))
        return

    try:
        with contextlib.redirect_stdout(io.StringIO()):
            user_ns = load(job["code"], "solution.py")
    except Exception as e:
        text, line = short_traceback(e)
        result.update(status="compile_error", verdict="Runtime Error",
                      error={"type": type(e).__name__, "msg": text, "line": line, "hint": "The error happened while defining your code, before any test ran."})
        emit("@@DONE " + json.dumps(result))
        return

    need = prob["cls"]
    if need not in user_ns or not isinstance(user_ns[need], type):
        result.update(status="compile_error", verdict="Compile Error",
                      error={"type": "NameError", "msg": "Your code must define class %s." % need, "line": None,
                             "hint": "Keep the class and method names from the starter code."})
        emit("@@DONE " + json.dumps(result))
        return
    if prob["kind"] != "design" and not hasattr(user_ns[need], prob["method"]):
        result.update(status="compile_error", verdict="Compile Error",
                      error={"type": "AttributeError", "msg": "class %s has no method %s()." % (need, prob["method"]), "line": None,
                             "hint": "Check the method name and that it is indented inside the class (4 spaces)."})
        emit("@@DONE " + json.dumps(result))
        return

    # 2. Assemble the test list
    tests = []
    for t in job.get("tests", []):
        tests.append({"name": t.get("name", "Test"), "hidden": bool(t.get("hidden")), "args": t["args"],
                      "expected": t.get("expected"), "has_expected": "expected" in t, "gen": False})
    if mode == "run":
        custom, err = parse_custom(prob, job.get("custom", ""))
        if err:
            result.update(status="input_error", verdict="Invalid Input", error={"msg": err})
            emit("@@DONE " + json.dumps(result))
            return
        for i, c in enumerate(custom):
            tests.append({"name": "Custom %d" % (i + 1), "hidden": False, "args": c, "expected": None, "has_expected": False, "gen": False, "custom": True})
    else:
        for g in job.get("gens", []):
            gns = {}
            exec(GEN_HELPERS, gns)
            exec(g["code"], gns)
            for k in range(g.get("count", 1)):
                rng = random.Random(g.get("seed", 7) * 1000 + k)
                tests.append({"name": g.get("name", "Generated") + ("" if g.get("count", 1) == 1 else " %d" % (k + 1)),
                              "hidden": True, "args": gns["gen"](rng), "expected": None, "has_expected": False, "gen": True})

    total = len(tests)
    result["total"] = total
    passed = 0
    user_ms = ref_ms = 0.0
    verdict = "Accepted"

    for idx, t in enumerate(tests):
        case = {"name": t["name"], "hidden": t["hidden"], "index": idx}
        if prob["kind"] == "design":
            case["input"] = ["operations = " + clip(t["args"]["ops"], 300), "arguments = " + clip(t["args"]["args"], 300)]
        else:
            case["input"] = display_args(prob["params"], t["args"])

        # expected value (and reference timing) from the reference solution when not given
        ref_time = None
        if not t["has_expected"]:
            try:
                exp, ref_time, _ = call(ref_ns, prob, t["args"])
                t["expected"] = exp
            except Exception as e:
                if t.get("custom"):
                    case["expected"] = None
                    case["note"] = "The reference solution rejected this input (%s). Check that it satisfies the constraints." % type(e).__name__
                    t["expected"] = None
                else:
                    raise
        case["expected"] = clip(t["expected"]) if t["expected"] is not None else None

        limit = 2.0
        if ref_time is not None and t["gen"]:
            limit = max(prob.get("min_limit", 1.0), prob.get("time_factor", 8) * ref_time + 0.3)
        case["limit_ms"] = round(limit * 1000)

        emit("@@START %d" % idx)
        got = None
        try:
            with time_limit(limit + 0.05):
                got, secs, out = call(user_ns, prob, t["args"])
            case["ms"] = round(secs * 1000, 2)
            case["stdout"] = out[-2000:]
            case["output"] = clip(got)
            if secs > limit:
                case["verdict"] = "TLE"
            elif t["expected"] is None:
                case["verdict"] = "NA"
            else:
                case["verdict"] = "AC" if compare(prob.get("compare", "exact"), got, t["expected"], t["args"], ref_ns) else "WA"
        except TimeLimit:
            case["verdict"] = "TLE"
            case["ms"] = round(limit * 1000)
        except MemoryError:
            case["verdict"] = "MLE"
        except Exception as e:
            text, line = short_traceback(e)
            case["verdict"] = "RE"
            case["error"] = text
            case["line"] = line

        if ref_time is not None:
            case["ref_ms"] = round(ref_time * 1000, 2)
            if t["gen"] and case.get("ms") is not None:
                user_ms += case["ms"]
                ref_ms += case["ref_ms"]
        result["cases"].append(case)

        if case["verdict"] in ("AC", "NA"):
            passed += 1
        elif mode == "submit":
            verdict = {"WA": "Wrong Answer", "RE": "Runtime Error", "TLE": "Time Limit Exceeded", "MLE": "Memory Limit Exceeded"}[case["verdict"]]
            break
        else:
            verdict = "Wrong Answer" if verdict == "Accepted" else verdict

    if mode == "run":
        bad = [c for c in result["cases"] if c["verdict"] not in ("AC", "NA")]
        verdict = "Accepted" if not bad else {"WA": "Wrong Answer", "RE": "Runtime Error", "TLE": "Time Limit Exceeded", "MLE": "Memory Limit Exceeded"}[bad[0]["verdict"]]
    result.update(verdict=verdict, passed=passed, user_ms=round(user_ms, 1), ref_ms=round(ref_ms, 1))
    emit("@@DONE " + json.dumps(result))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # never leave the app without an answer
        emit("@@DONE " + json.dumps({"status": "setup_error", "verdict": "Internal Error",
                                     "error": {"msg": "".join(traceback.format_exception(type(e), e, e.__traceback__))[-1500:]}}))
