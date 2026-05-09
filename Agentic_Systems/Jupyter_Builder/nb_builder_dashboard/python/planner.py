"""
Standalone Planner — called synchronously from R's Task tab.
Reads --config JSON, prints a single JSON plan to stdout, then exits.
"""

import anthropic
import json
import sys
import argparse
import os
from pathlib import Path

INPUT_PRICE  = 15.00 / 1_000_000
OUTPUT_PRICE = 75.00 / 1_000_000

PLANNER_SYSTEM = """You are an expert Python data scientist.
Given a notebook specification and optional reference files, produce a concise task plan.

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
    if not context_dir or not os.path.isdir(context_dir):
        return ""
    parts = ["=== REFERENCE FILES ==="]
    for p in sorted(Path(context_dir).iterdir()):
        if p.is_file() and not p.name.startswith("."):
            try:
                content = p.read_text(encoding="utf-8", errors="replace")
                parts.append(f"\n--- {p.name} ---\n{content}")
            except Exception:
                pass
    return "\n".join(parts) if len(parts) > 1 else ""


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True, help="Path to JSON config file")
    args = parser.parse_args()

    cfg = json.loads(Path(args.config).read_text(encoding="utf-8"))
    spec        = cfg.get("spec", "")
    api_key     = cfg.get("api_key", "")
    model       = cfg.get("model", "claude-opus-4-5")
    context_dir = cfg.get("context_dir", "")

    if not spec:
        print(json.dumps({"error": "spec is empty"}))
        sys.exit(1)
    if not api_key:
        print(json.dumps({"error": "api_key is empty"}))
        sys.exit(1)

    ctx = load_context(context_dir)
    system = PLANNER_SYSTEM.format(ctx=ctx or "(no reference files provided)")

    client = anthropic.Anthropic(api_key=api_key)
    response = client.messages.create(
        model     = model,
        max_tokens= 1024,
        system    = system,
        messages  = [{"role": "user", "content": f"Spec:\n{spec}"}]
    )

    raw   = response.content[0].text
    clean = raw.strip().removeprefix("```json").removeprefix("```").removesuffix("```").strip()

    # Validate it's real JSON before printing
    plan = json.loads(clean)
    print(json.dumps(plan))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)
