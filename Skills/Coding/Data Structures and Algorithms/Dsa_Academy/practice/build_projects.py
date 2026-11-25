"""
Validate the AI-assisted-round projects and write practice/projects/index.json.

    python build_projects.py

For every folder in practice/projects/ this checks that
  * the hidden tests pass on reference/, and fail on src/ (task not done) and on ai/ (flawed);
  * the starter tests pass on reference/ and on ai/ (so they do NOT already expose the flaw);
  * the model test suite passes on reference/ and fails on ai/ and on every mutant.
It also stores the unified diff of the AI suggestion for display in the app.
"""

import difflib
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import project_runner as pr  # noqa: E402

ROOT = os.path.join(HERE, "projects")


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def check(cond, pid, msg):
    if not cond:
        raise SystemExit("[%s] %s" % (pid, msg))


def main():
    out = []
    for pid in sorted(os.listdir(ROOT)):
        d = os.path.join(ROOT, pid)
        if not os.path.isfile(os.path.join(d, "project.json")):
            continue
        meta = json.loads(read(os.path.join(d, "project.json")))
        src = pr.read_dir(os.path.join(d, "src"))
        ref = pr.project_files(d, "reference", src)
        ai = pr.project_files(d, "ai", src)
        hidden, starter, model = read(os.path.join(d, "hidden_tests.py")), read(os.path.join(d, "tests_starter.py")), read(os.path.join(d, "model_tests.py"))

        h_ref = pr.summarise(pr.run_suite(ref, "hidden_tests", hidden))
        check(h_ref["all_pass"], pid, "hidden tests fail on reference: %s" % h_ref)
        h_src = pr.summarise(pr.run_suite(src, "hidden_tests", hidden))
        check(not h_src["all_pass"], pid, "hidden tests already pass on src")
        h_ai = pr.summarise(pr.run_suite(ai, "hidden_tests", hidden))
        check(not h_ai["all_pass"], pid, "hidden tests pass on the AI suggestion")
        for name, files in (("reference", ref), ("ai", ai)):
            s = pr.summarise(pr.run_suite(files, "test_solution", starter))
            check(s["all_pass"], pid, "starter tests fail on %s: %s" % (name, s))
        m_ref = pr.summarise(pr.run_suite(ref, "test_solution", model))
        check(m_ref["all_pass"], pid, "model tests fail on reference: %s" % m_ref)
        m_ai = pr.summarise(pr.run_suite(ai, "test_solution", model))
        check(not m_ai["all_pass"], pid, "model tests miss the AI flaw")
        mdir = os.path.join(d, "mutants")
        for m in sorted(os.listdir(mdir)):
            mf = pr.project_files(d, os.path.join("mutants", m), ref)
            r = pr.summarise(pr.run_suite(mf, "test_solution", model))
            check(not r["all_pass"], pid, "model tests miss mutant %s" % m)
            check(m in meta.get("mutants", {}), pid, "mutant %s has no description" % m)

        changed = sorted(n for n in ai if ai[n] != src.get(n))
        diff = "".join("".join(difflib.unified_diff(src.get(n, "").splitlines(True), ai[n].splitlines(True),
                                                    "a/" + n, "b/" + n)) for n in changed)
        meta.update({
            "src": {n: src[n] for n in meta["files"]},
            "reference": {n: ref[n] for n in meta["files"]},
            "ai_files": {n: ai[n] for n in changed},
            "ai_diff": diff,
            "tests_starter": starter,
            "model_tests": model,
            "hidden_names": [c["name"] for c in h_ref["cases"]],
            "src_hidden_passed": h_src["passed"], "ai_hidden_passed": h_ai["passed"], "hidden_total": h_ref["total"],
        })
        out.append(meta)
        print("  ok  %-9s hidden %d tests (src %d, AI %d)  mutants %d" % (pid, h_ref["total"], h_src["passed"], h_ai["passed"], len(meta["mutants"])))
    with open(os.path.join(ROOT, "index.json"), "w", encoding="utf-8") as f:
        json.dump(out, f, indent=1, ensure_ascii=False)
    print("wrote projects/index.json with %d projects" % len(out))


if __name__ == "__main__":
    main()
