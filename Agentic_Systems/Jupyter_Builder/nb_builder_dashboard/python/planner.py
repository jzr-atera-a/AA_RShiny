"""
Standalone Planner — called synchronously from R's Task tab.
Reads --config JSON, prints a single JSON plan to stdout, then exits.
Includes rate-limit retry with exponential backoff.
"""

import anthropic
import json
import sys
import time
import argparse
import os
from pathlib import Path

PLANNER_SYSTEM = """You are an expert Python data scientist.
Given a notebook specification and reference files, produce a task plan.

{ctx}

Respond ONLY with valid JSON — no markdown fences, no preamble:
{{
  "total_cells_estimate": <integer>,
  "outline": [
    {{"cell": 1, "title": "short title", "packages": ["pkg1"], "complexity": "low|medium|high"}},
    ...
  ],
  "context_notes": "brief notes about reference files or environment, or empty string"
}}"""


def load_context(context_dir: str) -> str:
    """Load ALL reference files in full — no truncation."""
    if not context_dir or not os.path.isdir(context_dir):
        return ""
    parts = ["=== REFERENCE FILES ==="]
    for p in sorted(Path(context_dir).iterdir()):
        if p.is_file() and not p.name.startswith("."):
            try:
                content = p.read_text(encoding="utf-8", errors="replace")
                parts.append(f"\n--- {p.name} ---\n{content}")
                eprint(f"Loaded: {p.name} ({len(content):,} chars)")
            except Exception as e:
                eprint(f"Could not read {p.name}: {e}")
    return "\n".join(parts) if len(parts) > 1 else ""


def eprint(*args):
    """Print to stderr so R can capture it separately from the JSON stdout."""
    print(*args, file=sys.stderr, flush=True)


def call_with_retry(fn, max_attempts=6):
    """Retry on RateLimitError with exponential backoff."""
    for attempt in range(max_attempts):
        try:
            return fn()
        except anthropic.RateLimitError:
            if attempt == max_attempts - 1:
                raise
            wait = min(60 * (2 ** attempt), 300)
            eprint(f"Rate limit (429) — waiting {wait}s before retry {attempt+2}/{max_attempts}...")
            time.sleep(wait)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    args = parser.parse_args()

    cfg     = json.loads(Path(args.config).read_text(encoding="utf-8"))
    spec    = cfg.get("spec", "")
    api_key = cfg.get("api_key", "")
    model   = cfg.get("model", "claude-opus-4-5")
    ctx_dir = cfg.get("context_dir", "")

    if not spec:
        print(json.dumps({"error": "spec is empty"})); sys.exit(1)
    if not api_key:
        print(json.dumps({"error": "api_key is empty"})); sys.exit(1)

    ctx    = load_context(ctx_dir)
    system = PLANNER_SYSTEM.format(ctx=ctx or "(no reference files)")

    client   = anthropic.Anthropic(api_key=api_key)
    response = call_with_retry(lambda: client.messages.create(
        model=model, max_tokens=1024,
        system=system,
        messages=[{"role": "user", "content": f"Spec:\n{spec}"}]
    ))

    raw   = response.content[0].text
    clean = raw.strip().removeprefix("```json").removeprefix("```").removesuffix("```").strip()
    plan  = json.loads(clean)
    # Print ONLY the JSON plan to stdout — R parses this
    print(json.dumps(plan))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        eprint(f"FATAL: {e}")
        print(json.dumps({"error": str(e)}))
        sys.exit(1)
