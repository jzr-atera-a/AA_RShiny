"""
Runner for the AI-assisted round (multi-file projects) and the code-reading exercises.

    python project_runner.py job.json

job.json fields
  mode      "tests"   run the candidate's tests against the candidate's files
            "hidden"  run the project's hidden tests against the candidate's files
            "audit"   run the candidate's tests against the reference solution (must pass),
                      the AI suggestion (should fail) and every extra mutant (should fail)
            "exec"    run a single snippet and capture its output (code reading)
  project   path to the project folder (contains project.json, src/, ai/, reference/, mutants/)
  files     {filename: source} — the candidate's current files
  tests     source of the candidate's test file (test_solution.py)
  code      snippet for "exec"

Prints one line "@@DONE <json>" at the end. Each suite runs in a fresh Python process with a
time limit, inside a temporary folder, so modules never leak between runs.
"""

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

TIME_LIMIT = 12

HARNESS = r'''
import io, json, sys, traceback, unittest, contextlib
sys.path.insert(0, ".")
sys.setrecursionlimit(10000)
out = io.StringIO()
cases = []
class R(unittest.TestResult):
    def addSuccess(self, t):  cases.append({"name": t.id().split(".", 1)[-1], "status": "pass"})
    def addFailure(self, t, e): cases.append({"name": t.id().split(".", 1)[-1], "status": "fail", "msg": self._exc_info_to_string(e, t)[-1500:]})
    def addError(self, t, e):   cases.append({"name": t.id().split(".", 1)[-1], "status": "error", "msg": self._exc_info_to_string(e, t)[-1500:]})
    def addSkip(self, t, why):  cases.append({"name": t.id().split(".", 1)[-1], "status": "skip", "msg": str(why)})
    def addExpectedFailure(self, t, e): cases.append({"name": t.id().split(".", 1)[-1], "status": "pass"})
    def addUnexpectedSuccess(self, t):  cases.append({"name": t.id().split(".", 1)[-1], "status": "fail", "msg": "unexpected success"})
res = {"status": "ok"}
try:
    with contextlib.redirect_stdout(out):
        suite = unittest.defaultTestLoader.loadTestsFromName(MODULE)
        if suite.countTestCases() == 0:
            res = {"status": "no_tests"}
        else:
            suite.run(R())
except BaseException:
    res = {"status": "load_error", "msg": traceback.format_exc()[-2000:]}
res["cases"] = cases
res["stdout"] = out.getvalue()[-3000:]
print("@@SUITE " + json.dumps(res))
'''


def run_suite(files, test_name, test_src, limit=TIME_LIMIT):
    """Write files + test module into a temp dir and run the test module in a fresh interpreter."""
    d = tempfile.mkdtemp(prefix="dsa_proj_")
    try:
        for name, src in files.items():
            name = os.path.basename(name)
            with open(os.path.join(d, name), "w", encoding="utf-8") as f:
                f.write(src)
        with open(os.path.join(d, test_name + ".py"), "w", encoding="utf-8") as f:
            f.write(test_src)
        with open(os.path.join(d, "_harness.py"), "w", encoding="utf-8") as f:
            f.write("MODULE = %r\n" % test_name + HARNESS)
        try:
            p = subprocess.run([sys.executable, "_harness.py"], cwd=d, capture_output=True, text=True, timeout=limit,
                               env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1", PYTHONIOENCODING="utf-8"))
        except subprocess.TimeoutExpired:
            return {"status": "timeout", "cases": [], "msg": "The tests did not finish within %d seconds — look for an infinite loop." % limit}
        line = [l for l in p.stdout.splitlines() if l.startswith("@@SUITE ")]
        if not line:
            return {"status": "crash", "cases": [], "msg": (p.stderr or p.stdout)[-2000:]}
        res = json.loads(line[-1][8:])
        if p.stderr.strip():
            res["stderr"] = p.stderr[-1500:]
        return res
    finally:
        shutil.rmtree(d, ignore_errors=True)


def summarise(res):
    cases = res.get("cases", [])
    res["passed"] = sum(c["status"] == "pass" for c in cases)
    res["total"] = len(cases)
    res["all_pass"] = res.get("status") == "ok" and res["total"] > 0 and res["passed"] == res["total"]
    return res


def read_dir(path):
    out = {}
    if os.path.isdir(path):
        for n in sorted(os.listdir(path)):
            if n.endswith(".py"):
                with open(os.path.join(path, n), encoding="utf-8") as f:
                    out[n] = f.read()
    return out


def project_files(project, sub, base=None):
    """Files of a variant folder layered over the starting src/ files."""
    files = dict(base if base is not None else read_dir(os.path.join(project, "src")))
    files.update(read_dir(os.path.join(project, sub)))
    return files


def main(job_path):
    with open(job_path, encoding="utf-8") as f:
        job = json.load(f)
    mode = job["mode"]

    if mode == "exec":
        d = tempfile.mkdtemp(prefix="dsa_exec_")
        try:
            with open(os.path.join(d, "snippet.py"), "w", encoding="utf-8") as f:
                f.write(job["code"])
            try:
                p = subprocess.run([sys.executable, "snippet.py"], cwd=d, capture_output=True, text=True, timeout=8,
                                   env=dict(os.environ, PYTHONIOENCODING="utf-8"))
                out = {"status": "ok", "stdout": p.stdout[-4000:], "stderr": p.stderr[-2000:], "code": p.returncode}
            except subprocess.TimeoutExpired:
                out = {"status": "timeout", "stdout": "", "stderr": "Stopped after 8 seconds."}
        finally:
            shutil.rmtree(d, ignore_errors=True)
        print("@@DONE " + json.dumps(out))
        return

    project = job["project"]
    with open(os.path.join(project, "project.json"), encoding="utf-8") as f:
        meta = json.load(f)
    files = job.get("files") or read_dir(os.path.join(project, "src"))

    if mode == "tests":
        res = summarise(run_suite(files, "test_solution", job.get("tests", "")))
        print("@@DONE " + json.dumps({"mode": mode, "suite": res}))
    elif mode == "hidden":
        with open(os.path.join(project, "hidden_tests.py"), encoding="utf-8") as f:
            hidden = f.read()
        res = summarise(run_suite(files, "hidden_tests", hidden))
        # hide assertion details of hidden tests, keep the names and the first line of the error
        for c in res.get("cases", []):
            if c.get("msg"):
                lines = [l for l in c["msg"].strip().splitlines() if l.strip()]
                exc = [l for l in lines if re.match(r"^[A-Za-z_][\w.]*(Error|Exception|Exit)\b", l)]
                c["msg"] = (exc[-1] if exc else lines[-1] if lines else "")[:300]
        print("@@DONE " + json.dumps({"mode": mode, "suite": res}))
    elif mode == "audit":
        tests = job.get("tests", "")
        src = read_dir(os.path.join(project, "src"))
        targets = [("reference", "Reference solution", project_files(project, "reference", src), True),
                   ("ai", "AI suggestion", project_files(project, "ai", src), False)]
        mdir = os.path.join(project, "mutants")
        if os.path.isdir(mdir):
            for m in sorted(os.listdir(mdir)):
                if os.path.isdir(os.path.join(mdir, m)):
                    ref = project_files(project, "reference", src)
                    targets.append(("mutant:" + m, meta.get("mutants", {}).get(m, m), project_files(project, os.path.join("mutants", m), ref), False))
        rows = []
        for key, label, fl, should_pass in targets:
            r = summarise(run_suite(fl, "test_solution", tests))
            ok = r["all_pass"] if should_pass else (r.get("status") in ("ok", "timeout") and not r["all_pass"] and r.get("total", 0) > 0) or r.get("status") == "timeout"
            failing = [c["name"] for c in r.get("cases", []) if c["status"] != "pass"]
            rows.append({"key": key, "label": label, "should_pass": should_pass, "status": r.get("status"),
                         "passed": r.get("passed", 0), "total": r.get("total", 0), "ok": bool(ok), "failing": failing[:6],
                         "msg": r.get("msg", "")[-800:]})
        print("@@DONE " + json.dumps({"mode": mode, "rows": rows}))
    else:
        print("@@DONE " + json.dumps({"status": "error", "msg": "unknown mode " + mode}))


if __name__ == "__main__":
    main(sys.argv[1])
