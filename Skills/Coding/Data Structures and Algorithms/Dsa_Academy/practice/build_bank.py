"""
Build and validate the practice problem bank.

    python build_bank.py

Reads every practice/bank/*.py file (each defines PROBLEMS = [...]), checks each
problem thoroughly, and writes practice/problems.json, which the app loads.

Checks performed for every problem:
  * the starter code compiles;
  * the reference solution reproduces every example's expected output;
  * the reference agrees with an independent brute-force solution on hundreds
    of small random inputs (when a brute force is provided);
  * expected outputs of hidden tests are filled in from the reference;
  * generated large tests run and are timed with the reference.

To add a problem, append a dict to one of the bank files and re-run this script.
"""

import glob
import importlib.util
import json
import os
import random
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import runner  # noqa: E402

REQUIRED = ["id", "num", "title", "slug", "difficulty", "topic", "pattern", "companies", "kind", "cls",
            "statement", "constraints", "examples", "starter", "reference", "hints", "approach", "complexity", "followups"]
PUBLIC_DROP = {"brute", "small_gen", "small_n"}


def fail(pid, msg):
    raise SystemExit("\n[%s] %s" % (pid, msg))


def check_pair(p, ref_ns, args, a, b):
    mode = p.get("compare", "exact")
    if mode == "custom":
        return ref_ns["check"](args, a, b) and ref_ns["check"](args, b, a)
    return runner.compare(mode, a, b, args, ref_ns)


def validate(p):
    pid = p.get("id", "?")
    for k in REQUIRED:
        if k not in p:
            fail(pid, "missing field %r" % k)
    if p["kind"] == "function":
        for k in ("method", "params", "returns"):
            if k not in p:
                fail(pid, "function problem missing %r" % k)
    try:
        compile(p["starter"], "starter.py", "exec")
    except SyntaxError as e:
        fail(pid, "starter does not compile: %s" % e)
    ref_ns = runner.load(p["reference"], "reference.py")
    if p.get("compare") == "custom" and "check" not in ref_ns:
        fail(pid, "compare=custom needs def check(args, got, expected) in the reference")

    # examples
    for i, ex in enumerate(p["examples"]):
        got, _, _ = runner.call(ref_ns, p, ex["args"])
        if not runner.compare(p.get("compare", "exact"), got, ex["expected"], ex["args"], ref_ns):
            fail(pid, "example %d: reference returned %r, expected %r" % (i + 1, got, ex["expected"]))

    # hidden tests: fill expected from the reference
    for t in p.get("hidden", []):
        got, _, _ = runner.call(ref_ns, p, t["args"])
        if "expected" in t:
            if not runner.compare(p.get("compare", "exact"), got, t["expected"], t["args"], ref_ns):
                fail(pid, "hidden test %r: reference returned %r, expected %r" % (t["args"], got, t["expected"]))
        else:
            t["expected"] = got

    # brute-force cross-check
    checked = 0
    if p.get("brute") and p.get("small_gen"):
        brute_ns = runner.load(p["brute"], "brute.py")
        gns = {}
        exec(runner.GEN_HELPERS, gns)
        exec(p["small_gen"], gns)
        rng = random.Random(12345)
        for _ in range(p.get("small_n", 300)):
            args = gns["gen"](rng)
            a, _, _ = runner.call(ref_ns, p, args)
            b, _, _ = runner.call(brute_ns, p, args)
            if not check_pair(p, ref_ns, args, a, b):
                fail(pid, "reference and brute force disagree on %s\n  reference: %r\n  brute:     %r" % (json.dumps(args)[:400], a, b))
            checked += 1

    # generated large tests
    timings = []
    for g in p.get("gens", []):
        gns = {}
        exec(runner.GEN_HELPERS, gns)
        exec(g["code"], gns)
        for k in range(g.get("count", 1)):
            args = gns["gen"](random.Random(g.get("seed", 7) * 1000 + k))
            t0 = time.perf_counter()
            runner.call(ref_ns, p, args)
            timings.append(time.perf_counter() - t0)
    return checked, timings


def main():
    problems = []
    for path in sorted(glob.glob(os.path.join(HERE, "bank", "*.py"))):
        spec = importlib.util.spec_from_file_location(os.path.basename(path)[:-3], path)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        problems.extend(mod.PROBLEMS)

    ids = [p["id"] for p in problems]
    dup = {i for i in ids if ids.count(i) > 1}
    if dup:
        raise SystemExit("duplicate ids: %s" % dup)

    out = []
    for p in problems:
        checked, timings = validate(p)
        print("  ok  %-7s %-48s brute-checked %4d  large tests: %s" % (
            p["id"], p["title"][:48], checked, ", ".join("%.0fms" % (t * 1000) for t in timings) or "—"))
        tests = [{"name": "Example %d" % (i + 1), "hidden": False, "args": ex["args"], "expected": ex["expected"]}
                 for i, ex in enumerate(p["examples"])]
        tests += [{"name": "Hidden test %d" % (i + 1), "hidden": True, "args": t["args"], "expected": t["expected"]}
                  for i, t in enumerate(p.get("hidden", []))]
        pub = {k: v for k, v in p.items() if k not in PUBLIC_DROP and k not in ("hidden",)}
        pub["tests"] = tests
        pub.setdefault("compare", "exact")
        pub.setdefault("inplace", None)
        pub.setdefault("gens", [])
        pub.setdefault("time_factor", 8)
        pub.setdefault("min_limit", 1.0)
        out.append(pub)

    order = {"Easy": 0, "Medium": 1, "Hard": 2}
    out.sort(key=lambda p: (order[p["difficulty"]], p["num"]))
    with open(os.path.join(HERE, "problems.json"), "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    print("\nWrote %d problems to problems.json" % len(out))


if __name__ == "__main__":
    main()
