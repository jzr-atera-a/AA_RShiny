"""
Notebook Builder — R Shiny subprocess version
Reads launch_config.json, writes progress.json + run.log
Reads control.json for pause/stop/checkpoint commands from R
"""

import anthropic
import jupyter_client
import json
import os
import sys
import queue
import time
import re
import argparse
from datetime import datetime
from pathlib import Path

# ── Config ─────────────────────────────────────────────────────────────────

INPUT_PRICE  = 15.00 / 1_000_000
OUTPUT_PRICE = 75.00 / 1_000_000

# ── Logging ────────────────────────────────────────────────────────────────

log_file = None

def log(msg, level="INFO"):
    prefix = {"INFO":"ℹ","SUCCESS":"✓","WARNING":"⚠","ERROR":"✗","AGENT1":"Agent 1","AGENT2":"Agent 2","KERNEL":"⚙"}.get(level, level)
    line = f"[{datetime.now().strftime('%H:%M:%S')}] {prefix}  {msg}"
    print(line, flush=True)
    if log_file:
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(line + "\n")

# ── Progress writer ─────────────────────────────────────────────────────────

def write_progress(run_dir, cell_num, plan_total, status, message,
                   current_agent="idle", stats=None, checkpoint=None):
    data = {
        "cell_current":  cell_num,
        "plan_total":    plan_total,
        "status":        status,
        "message":       message,
        "current_agent": current_agent,
        "timestamp":     datetime.now().isoformat(),
        "stats":         stats or {},
        "checkpoint":    checkpoint,
    }
    path = Path(run_dir) / "progress.json"
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")

# ── Control file reader ─────────────────────────────────────────────────────

def read_control(run_dir):
    path = Path(run_dir) / "control.json"
    if not path.exists():
        return "run"
    try:
        return json.loads(path.read_text())["command"]
    except Exception:
        return "run"

def wait_for_checkpoint_response(run_dir, timeout=300):
    """Returns 'accept', 'skip', or 'stop'."""
    start = time.time()
    while time.time() - start < timeout:
        cmd = read_control(run_dir)
        if cmd == "checkpoint_accept":
            return "accept"
        if cmd == "checkpoint_skip":
            return "skip"
        if cmd == "stop":
            return "stop"
        time.sleep(1)
    return "skip"  # timeout → auto-skip

def reset_control(run_dir):
    """Write 'run' to control.json — clears any stale checkpoint/pause command."""
    Path(run_dir, "control.json").write_text(json.dumps({"command": "run"}))

def check_pause_stop(run_dir, run_dir_obj, cell_num, plan_total, stats):
    """Block if paused; return True if should stop."""
    while True:
        cmd = read_control(run_dir)
        if cmd == "stop":
            log("Stop command received.", "WARNING")
            write_progress(run_dir, cell_num, plan_total, "stopped", "Stopped by user.", stats=stats)
            return True
        # "run", "continue", empty, OR leftover checkpoint commands → all mean continue
        if cmd in ("run", "continue", "", "checkpoint_accept", "checkpoint_skip", "awaiting_checkpoint"):
            return False
        # Only truly "pause" if the command is literally "pause"
        if cmd == "pause":
            write_progress(run_dir, cell_num, plan_total, "paused", "Paused — click Continue to resume.", stats=stats)
            time.sleep(2)
        else:
            # Unknown command — treat as run to avoid getting stuck
            return False

# ── Stats ───────────────────────────────────────────────────────────────────

class Stats:
    def __init__(self):
        self.total_input_tokens  = 0
        self.total_output_tokens = 0
        self.total_cost_usd      = 0.0
        self.cells_approved      = 0
        self.cells_skipped       = 0
        self.retries_total       = 0
        self.consecutive_fails   = 0

    def add(self, usage):
        self.total_input_tokens  += usage.input_tokens
        self.total_output_tokens += usage.output_tokens
        self.total_cost_usd      += (usage.input_tokens  * INPUT_PRICE +
                                     usage.output_tokens * OUTPUT_PRICE)

    def to_dict(self):
        return self.__dict__.copy()

    def check_budget(self, max_cost, max_tokens, max_consec):
        if self.total_cost_usd >= max_cost:
            return f"Cost limit ${self.total_cost_usd:.4f} >= ${max_cost}"
        total = self.total_input_tokens + self.total_output_tokens
        if total >= max_tokens:
            return f"Token limit {total:,} >= {max_tokens:,}"
        if self.consecutive_fails >= max_consec:
            return f"{self.consecutive_fails} consecutive failures"
        return None

# ── Rate-limit retry wrapper ─────────────────────────────────────────────────

def api_with_retry(fn, run_dir="", max_attempts=6):
    """Retry an Anthropic API call on RateLimitError with exponential backoff."""
    for attempt in range(max_attempts):
        try:
            return fn()
        except anthropic.RateLimitError as e:
            if attempt == max_attempts - 1:
                log(f"Rate limit: max retries reached. Aborting.", "ERROR")
                raise
            wait = min(60 * (2 ** attempt), 300)   # 60s, 120s, 240s, 300s cap
            log(f"Rate limit (429) — waiting {wait}s before retry {attempt+2}/{max_attempts}...", "WARNING")
            # Write paused-style progress so R dashboard shows waiting state
            if run_dir:
                try:
                    prog_path = Path(run_dir) / "progress.json"
                    if prog_path.exists():
                        prog = json.loads(prog_path.read_text())
                        prog["message"] = f"Rate limit — retrying in {wait}s ({attempt+2}/{max_attempts})"
                        prog_path.write_text(json.dumps(prog, indent=2))
                except Exception:
                    pass
            time.sleep(wait)
        except Exception:
            raise

# ── Kernel ──────────────────────────────────────────────────────────────────

class Kernel:
    def __init__(self, kernel_name="python3"):
        try:
            self.km = jupyter_client.KernelManager(kernel_name=kernel_name)
            self.km.start_kernel()
        except Exception as e:
            if kernel_name != "python3":
                log(f"Kernel '{kernel_name}' not found ({e}), falling back to python3", "WARNING")
                self.km = jupyter_client.KernelManager(kernel_name="python3")
                self.km.start_kernel()
                kernel_name = "python3"
            else:
                raise
        self.kc = self.km.client()
        self.kc.start_channels()
        self.kc.wait_for_ready(timeout=30)

    def execute(self, code, timeout=60):
        self.kc.execute(code)
        outputs, error = [], None
        while True:
            try:
                msg = self.kc.get_iopub_msg(timeout=timeout)
            except queue.Empty:
                break
            mt, ct = msg["msg_type"], msg["content"]
            if mt == "stream":            outputs.append(ct["text"])
            elif mt == "execute_result":  outputs.append(str(ct["data"].get("text/plain","")))
            elif mt == "display_data":    outputs.append("[display output]")
            elif mt == "error":
                error = f"{ct['ename']}: {ct['evalue']}"
                break
            elif mt == "status" and ct["execution_state"] == "idle":
                break
        return {"success": error is None, "output": "\n".join(outputs), "error": error}

    def shutdown(self):
        try: self.kc.stop_channels(); self.km.shutdown_kernel()
        except: pass

# ── Context loader ──────────────────────────────────────────────────────────

def load_context(context_dir):
    """Load ALL reference files in full — do NOT truncate."""
    if not context_dir or not os.path.isdir(context_dir):
        return {}
    files = {}
    for p in sorted(Path(context_dir).iterdir()):
        if p.is_file() and not p.name.startswith("."):
            try:
                content = p.read_text(encoding="utf-8", errors="replace")
                files[p.name] = content
                log(f"Context file loaded: {p.name} ({len(content):,} chars)")
            except Exception as e:
                log(f"Could not read {p.name}: {e}", "WARNING")
    total = sum(len(v) for v in files.values())
    log(f"Total context: {total:,} chars (~{total//4:,} tokens) — ensure token budget is set accordingly")
    return files

def context_block(files):
    if not files: return ""
    parts = ["=== REFERENCE FILES ==="]
    for name, content in files.items():
        parts.append(f"\n--- {name} ---\n{content}")
    return "\n".join(parts)

# ── Session state ────────────────────────────────────────────────────────────

def load_session(run_dir):
    path = Path(run_dir) / "session.json"
    if path.exists():
        try: return json.loads(path.read_text(encoding="utf-8"))
        except: pass
    return None

def save_session(run_dir, state):
    Path(run_dir / "session.json").write_text(
        json.dumps(state, indent=2, ensure_ascii=False), encoding="utf-8"
    )

# ── Output saver ─────────────────────────────────────────────────────────────

def save_cell_output(run_dir, cell_num, cell, result):
    slug = re.sub(r"[^a-z0-9]+", "-", cell["explanation"].lower())[:40].strip("-")
    cell_dir = Path(run_dir) / f"cell_{cell_num:02d}_{slug}"
    cell_dir.mkdir(exist_ok=True)
    (cell_dir / "code.py").write_text(cell["code"], encoding="utf-8")
    lines = [
        f"Cell {cell_num}: {cell['explanation']}",
        f"Executed: {datetime.now().isoformat()}",
        f"Success: {result['success']}",
        "--- output ---",
        result["output"] or "(no output)",
    ]
    if result["error"]: lines += ["--- error ---", result["error"]]
    (cell_dir / "output.txt").write_text("\n".join(lines), encoding="utf-8")

def save_notebook(run_dir, cells):
    nb = {
        "nbformat": 4, "nbformat_minor": 5,
        "metadata": {"kernelspec": {"display_name":"Python 3","language":"python","name":"python3"}},
        "cells": []
    }
    for c in cells:
        nb["cells"].append({"cell_type":"markdown","metadata":{},"source":f"### {c['explanation']}"})
        nb["cells"].append({"cell_type":"code","execution_count":None,"metadata":{},"outputs":[],"source":c["code"]})
    (Path(run_dir) / "notebook.ipynb").write_text(json.dumps(nb, indent=2), encoding="utf-8")

# ── Agent helpers ─────────────────────────────────────────────────────────────

def parse_json(text):
    clean = text.strip().removeprefix("```json").removeprefix("```").removesuffix("```").strip()
    return json.loads(clean)

# ── Planner ──────────────────────────────────────────────────────────────────

PLANNER_SYSTEM = """You are an expert Python data scientist.
Given a notebook specification and reference files, produce a task plan.

{ctx}

Respond ONLY with valid JSON (no markdown fences):
{{
  "total_cells_estimate": <int>,
  "outline": [{{"cell":1,"title":"...","packages":["..."],"complexity":"low|medium|high"}}, ...],
  "context_notes": "..."
}}"""

def plan_task(client, model, spec, ctx_block, stats):
    log("Planning task...", "AGENT1")
    system = PLANNER_SYSTEM.format(ctx=ctx_block or "(no reference files)")
    response = api_with_retry(
        lambda: client.messages.create(
            model=model, max_tokens=1024,
            system=system,
            messages=[{"role":"user","content":f"Spec:\n{spec}"}]
        )
    )
    stats.add(response.usage)
    plan = parse_json(response.content[0].text)
    log(f"Plan: {plan['total_cells_estimate']} cells", "SUCCESS")
    return plan

# ── Writer ────────────────────────────────────────────────────────────────────

WRITER_SYSTEM = """You are an expert Python data scientist building a Jupyter notebook one cell at a time.

{ctx}

Task plan:
{plan}

Respond ONLY with valid JSON (no markdown fences):
{{"explanation":"...","code":"..."}}

Rules: one cell per response; fix current cell on error feedback; stand by on approval."""

def writer_call(client, model, history, prompt, ctx_block, plan, stats):
    system = WRITER_SYSTEM.format(ctx=ctx_block or "(context in session)", plan=json.dumps(plan, indent=2))
    history.append({"role":"user","content":prompt})
    response = api_with_retry(
        lambda: client.messages.create(model=model, max_tokens=2048, system=system, messages=history)
    )
    stats.add(response.usage)
    raw = response.content[0].text
    history.append({"role":"assistant","content":raw})
    return parse_json(raw)

# ── Verifier ──────────────────────────────────────────────────────────────────

VERIFIER_SYSTEM = """You are a senior code reviewer for Jupyter notebooks.
Respond ONLY with valid JSON:
{{"approved":true|false,"feedback":"...","risk":"low|medium|high"}}
risk=high if: installs packages, makes network requests, writes files, or has irreversible side-effects."""

def verifier_call(client, model, history, cell, result, stats):
    msg = (f"Explanation: {cell['explanation']}\n\nCode:\n```python\n{cell['code']}\n```\n\n"
           f"Success: {result['success']}\nOutput: {result['output'][:600] or '(none)'}\nError: {result['error'] or '(none)'}")
    history.append({"role":"user","content":msg})
    response = api_with_retry(
        lambda: client.messages.create(model=model, max_tokens=512, system=VERIFIER_SYSTEM, messages=history)
    )
    stats.add(response.usage)
    raw = response.content[0].text
    history.append({"role":"assistant","content":raw})
    return parse_json(raw)

# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--launch-config", required=True)
    parser.add_argument("--resume", action="store_true")
    args = parser.parse_args()

    cfg = json.loads(Path(args.launch_config).read_text(encoding="utf-8"))

    run_dir     = Path(cfg["run_dir"])
    spec        = cfg["spec"]
    api_key     = cfg["api_key"]
    model       = cfg.get("model", "claude-opus-4-5")
    context_dir = cfg.get("context_dir", "")
    max_cost    = float(cfg.get("max_cost_usd", 2.0))
    max_tokens  = int(cfg.get("max_tokens", 200000))
    max_retries = int(cfg.get("max_retries", 3))
    max_consec  = int(cfg.get("max_consec_fails", 3))
    review_every= bool(cfg.get("review_every", False))

    global log_file
    log_file = str(run_dir / "run.log")
    run_dir.mkdir(parents=True, exist_ok=True)

    log("=" * 55)
    log("NOTEBOOK BUILDER STARTED")
    log(f"Run dir: {run_dir}")
    log(f"Model:   {model}")
    log("=" * 55)

    client = anthropic.Anthropic(api_key=api_key)
    stats  = Stats()

    # ── Load or create session ─────────────────────────────────────────────
    existing = load_session(run_dir) if args.resume else None

    if existing and args.resume:
        log("Resuming session...", "SUCCESS")
        ctx_files      = existing.get("reference_files", {})
        plan           = existing.get("task_plan", {})
        writer_hist    = existing.get("writer_history", [])
        verifier_hist  = existing.get("verifier_history", [])
        approved_cells = existing.get("approved_cells", [])
        # Restore stats
        for k, v in (existing.get("stats") or {}).items():
            if hasattr(stats, k): setattr(stats, k, v)
        log(f"Resumed: {len(approved_cells)} cells already approved")
    else:
        log("Loading context files...")
        ctx_files = load_context(context_dir)
        plan = {}
        writer_hist = []
        verifier_hist = []
        approved_cells = []

    ctx = context_block(ctx_files)

    # ── Planning phase ─────────────────────────────────────────────────────
    if not plan:
        write_progress(run_dir, 0, 1, "running", "Planning task...", "writer", stats.to_dict())
        plan = plan_task(client, model, spec, ctx, stats)
        # Save initial session
        session_state = {
            "session_id":      run_dir.name,
            "created_at":      datetime.now().isoformat(),
            "spec":            spec,
            "task_plan":       plan,
            "reference_files": ctx_files,
            "approved_cells":  [],
            "writer_history":  [],
            "verifier_history":[],
            "stats":           stats.to_dict(),
        }
        save_session(run_dir, session_state)
    else:
        log(f"Using existing plan ({plan.get('total_cells_estimate','?')} cells)", "SUCCESS")

    plan_total   = plan.get("total_cells_estimate", 5)
    outline      = plan.get("outline", [])
    cells_done   = len(approved_cells)

    # ── Budget check after planning (planning itself costs tokens) ──────────
    post_plan_budget = stats.check_budget(max_cost, max_tokens, max_consec)
    if post_plan_budget:
        log(f"Budget exhausted during planning: {post_plan_budget}", "ERROR")
        log(f"Planning alone cost ${stats.total_cost_usd:.4f} / budget ${max_cost:.2f}", "WARNING")
        log("Increase Max Spend in Settings Tab 1 and try again.", "WARNING")
        write_progress(run_dir, 0, plan_total, "stopped",
                       f"Budget hit during planning: ${stats.total_cost_usd:.4f} >= ${max_cost:.2f}",
                       "idle", stats.to_dict())
        save_session(run_dir, {
            "session_id": run_dir.name, "spec": spec,
            "task_plan": plan, "reference_files": ctx_files,
            "approved_cells": [], "writer_history": [],
            "verifier_history": [], "stats": stats.to_dict(),
        })
        sys.exit(0)

    # Register the kernel name (use same one as R configured, default python3)
    kernel_name = cfg.get("kernel_name", "python3")
    log(f"Starting kernel: {kernel_name}", "SUCCESS")
    kernel = Kernel(kernel_name)
    log(f"Kernel ready: {kernel_name}", "SUCCESS")

    # ── Cell loop ──────────────────────────────────────────────────────────
    for cell_num in range(cells_done + 1, plan_total + 1):
        log(f"{'─'*40}")
        log(f"CELL {cell_num} / {plan_total}")
        log(f"{'─'*40}")

        # Budget check
        stop_reason = stats.check_budget(max_cost, max_tokens, max_consec)
        if stop_reason:
            log(f"Budget/limit hit: {stop_reason}", "WARNING")
            break

        # Control check
        if check_pause_stop(run_dir, run_dir, cell_num, plan_total, stats.to_dict()):
            break

        # Cell title from plan
        cell_title = ""
        if cell_num <= len(outline):
            cell_title = outline[cell_num - 1].get("title", "")

        prompt = (f"Generate the FIRST cell now." if cell_num == 1
                  else f"Generate cell {cell_num}: {cell_title}.")

        retries = 0
        cell_approved = False

        while retries <= max_retries:
            # ── Writer ─────────────────────────────────────────────────────
            write_progress(run_dir, cell_num, plan_total, "running",
                           f"Writer generating cell {cell_num}...", "writer", stats.to_dict())
            log("Writer generating...", "AGENT1")
            try:
                cell = writer_call(client, model, writer_hist, prompt, ctx if not writer_hist else "", plan, stats)
            except (json.JSONDecodeError, KeyError) as e:
                log(f"Writer JSON error: {e}", "ERROR")
                prompt = "Your response was not valid JSON. Retry with exactly the specified format."
                retries += 1; stats.retries_total += 1
                continue

            log(f"→ {cell['explanation']}", "AGENT1")

            # ── Kernel ─────────────────────────────────────────────────────
            write_progress(run_dir, cell_num, plan_total, "running",
                           f"Executing cell {cell_num}...", "kernel", stats.to_dict())
            log("Executing...", "KERNEL")
            result = kernel.execute(cell["code"])
            if result["success"]:
                output_preview = (result['output'] or '(no output)')[:300]
                log(f"✓ Execution OK — output: {output_preview}", "SUCCESS")
            else:
                log(f"✗ Execution FAILED: {result['error'][:400]}", "ERROR")

            # ── Verifier ───────────────────────────────────────────────────
            write_progress(run_dir, cell_num, plan_total, "running",
                           f"Verifier reviewing cell {cell_num}...", "verifier", stats.to_dict())
            log("Verifier reviewing...", "AGENT2")
            try:
                verdict = verifier_call(client, model, verifier_hist, cell, result, stats)
            except (json.JSONDecodeError, KeyError) as e:
                log(f"Verifier JSON error: {e}", "ERROR")
                retries += 1; stats.retries_total += 1
                continue

            verifier_feedback = verdict.get("feedback", "")
            verifier_risk     = verdict.get("risk", "?")
            if verdict["approved"]:
                log(f"✅ Agent 2 APPROVED — {verifier_feedback}  [risk={verifier_risk}]", "SUCCESS")

                # ── Human checkpoint ────────────────────────────────────────
                risk = verdict.get("risk", "low")
                needs_human = risk == "high" or review_every
                if needs_human:
                    log("⏸ Waiting for human checkpoint...", "WARNING")
                    write_progress(run_dir, cell_num, plan_total, "checkpoint",
                                   "Awaiting human review...", "human", stats.to_dict(),
                                   checkpoint={
                                       "waiting":     True,
                                       "explanation": cell["explanation"],
                                       "code":        cell["code"],
                                       "risk":        risk,
                                   })
                    # Reset control to avoid stale state
                    ctrl_path = run_dir / "control.json"
                    ctrl_path.write_text(json.dumps({"command":"awaiting_checkpoint"}))

                    action = wait_for_checkpoint_response(str(run_dir))
                    log(f"Human decision: {action}", "WARNING")
                    # CRITICAL: reset control.json so the next cell's check_pause_stop
                    # doesn't misread "checkpoint_accept" as a pause command
                    reset_control(str(run_dir))

                    if action == "stop":
                        write_progress(run_dir, cell_num, plan_total, "stopped",
                                       "Aborted by user.", stats=stats.to_dict())
                        kernel.shutdown()
                        sys.exit(0)

                    if action == "skip":
                        stats.cells_skipped += 1
                        stats.consecutive_fails += 1
                        break

                # ── Accepted ────────────────────────────────────────────────
                save_cell_output(run_dir, cell_num, cell, result)
                approved_cells.append(cell)
                save_notebook(run_dir, approved_cells)
                stats.cells_approved += 1
                stats.consecutive_fails = 0
                cell_approved = True

                # Persist session
                session_state = {
                    "session_id":      run_dir.name,
                    "created_at":      datetime.now().isoformat() if cells_done == 0 else existing.get("created_at",""),
                    "spec":            spec,
                    "task_plan":       plan,
                    "reference_files": ctx_files,
                    "approved_cells":  approved_cells,
                    "writer_history":  writer_hist,
                    "verifier_history":verifier_hist,
                    "stats":           stats.to_dict(),
                }
                save_session(run_dir, session_state)

                writer_hist += [
                    {"role":"user","content":"Cell approved. Stand by for next cell."},
                    {"role":"assistant","content":"Ready."},
                ]
                write_progress(run_dir, cell_num, plan_total, "running",
                               f"Cell {cell_num} approved.", "idle", stats.to_dict())
                break

            else:
                log(f"❌ Agent 2 REJECTED — {verifier_feedback}", "ERROR")
                retries += 1; stats.retries_total += 1
                prompt = f"Rejected. Fix it.\n\nFeedback: {verifier_feedback}"
                log(f"Retry {retries}/{max_retries}", "WARNING")

            # Check control between retries
            if check_pause_stop(run_dir, run_dir, cell_num, plan_total, stats.to_dict()):
                kernel.shutdown(); sys.exit(0)

        if not cell_approved and retries > max_retries:
            log(f"Cell {cell_num} failed after {max_retries} retries — skipping.", "WARNING")
            stats.cells_skipped     += 1
            stats.consecutive_fails += 1

        # Save stats after every cell
        session_state = load_session(run_dir) or {}
        session_state["stats"] = stats.to_dict()
        save_session(run_dir, session_state)

    # ── Done ───────────────────────────────────────────────────────────────
    kernel.shutdown()
    save_notebook(run_dir, approved_cells)

    session_state = load_session(run_dir) or {}
    session_state["stats"] = stats.to_dict()
    save_session(run_dir, session_state)

    log("=" * 55)
    log(f"COMPLETE — {stats.cells_approved}/{plan_total} cells approved")
    log(f"Cost: ${stats.total_cost_usd:.4f}  |  Tokens: {stats.total_input_tokens + stats.total_output_tokens:,}")
    log(f"Notebook: {run_dir / 'notebook.ipynb'}")
    log("=" * 55)

    write_progress(run_dir, plan_total, plan_total, "done",
                   f"Complete — {stats.cells_approved}/{plan_total} approved",
                   "idle", stats.to_dict())

if __name__ == "__main__":
    main()
