# Notebook Builder Dashboard

A four-tab R Shiny dashboard that orchestrates two Claude agents to collaboratively build a Jupyter notebook — one verified cell at a time.

```
┌─────────────────────────────────────────────────────────┐
│  Tab 1 · Settings     Tab 2 · Task     Tab 3 · Monitor  │
│  Tab 4 · Outputs                                        │
└─────────────────────────────────────────────────────────┘
         ↕ R reads/writes control files
         ↕ processx spawns Python subprocess
┌─────────────────────────────────────────────────────────┐
│  notebook_builder.py                                    │
│    Agent 1 (Writer) → Kernel → Agent 2 (Verifier)      │
│    writes: progress.json  session.json  run.log         │
└─────────────────────────────────────────────────────────┘
```

---

## Quick start

```bash
# 1. Install R packages
Rscript setup.R

# 2. Install Python packages into your target env
/path/to/your/env/bin/pip install anthropic jupyter_client ipykernel -q

# 3. Launch the app
Rscript -e "shiny::runApp()"
```

Then open **http://localhost:XXXX** in your browser.

---

## Folder layout

```
nb_builder/
├── app.R                        ← entry point
├── global.R                     ← UI/server factories, shared config
├── setup.R                      ← one-shot installer
├── nb_session_config.json        ← persisted settings (auto-created)
│
├── R/
│   ├── module_loader.R           ← R6 registry reader (same as reference app)
│   ├── utils_session.R           ← R6 session / config persistence
│   └── utils_python.R            ← R6 processx bridge
│
├── modules/
│   ├── _module_registry.yml      ← enable/disable tabs here
│   ├── settings/   ui.R server.R
│   ├── task/       ui.R server.R
│   ├── monitor/    ui.R server.R
│   └── outputs/    ui.R server.R
│
├── python/
│   ├── notebook_builder.py       ← full agent loop (subprocess)
│   └── planner.py                ← plan-only helper (called inline)
│
├── www/css/global.css            ← purple-gradient theme
│
├── context/                      ← drop reference files here
│   └── (api_docs.md, schema.json, sample.py …)
│
└── runs/                         ← auto-created per run
    └── 2026-05-09_143022_iris/
        ├── launch_config.json
        ├── session.json           ← full resumable state
        ├── progress.json          ← R polls this every 2 s
        ├── control.json           ← R writes commands here
        ├── run.log                ← streamed to Monitor tab
        ├── notebook.ipynb         ← updated after every cell
        ├── cell_01_load-data/
        │   ├── code.py
        │   └── output.txt
        └── cell_02_statistics/ …
```

---

## Tab 1 · Settings

| Field | What it does |
|-------|-------------|
| **Anthropic API Key** | Stored in `nb_session_config.json` — persists across restarts |
| **Claude Model** | Opus, Sonnet, or Haiku |
| **Python executable path** | Full path to env's Python — venv or conda |
| **Context folder** | Files here are read once and embedded in `session.json` |
| **Runs folder** | Where timestamped run folders are created |
| **Budget / circuit breakers** | Cost cap, token cap, retries per cell, consecutive fail limit |

Click **Save All Settings** — everything persists to `nb_session_config.json`.

---

## Tab 2 · Task

1. Type (or upload) a notebook specification.
2. Click **Plan Task** — Agent 1 analyses the spec + context files and returns a cell-by-cell plan with complexity ratings.
3. Review the plan table.
4. Click **Run — Build Notebook** to start.

To resume an interrupted run, select it from the **Resume an existing run** dropdown.

---

## Tab 3 · Monitor

- **Live log** — streamed from `run.log`, colour-coded by agent.
- **Stats cards** — approved / planned / retries / cost / tokens / skipped, live.
- **Progress bar** — `cell_current / plan_total`.
- **Agent badge** — shows which component is active right now.
- **Pause / Continue / Stop** — write to `control.json`; Python checks between steps.
- **Human checkpoint panel** — appears automatically when Agent 2 flags `risk: high` (or when *Review every cell* is on in Settings). Buttons: Accept · Skip · Abort.

---

## Tab 4 · Outputs

- All approved cells with explanation, collapsible code, and captured stdout.
- Auto-refreshes every 5 s while a run is active.
- **Download .ipynb** button — serves the latest `notebook.ipynb`.

---

## Session persistence

Reference files in `context/` are read **once** at the start of a new run and stored inside `session.json`. On resume:

- Python reads `session.json` → no disk re-reads.
- Full conversation histories for both agents are restored.
- Stats (cost, tokens, retries) accumulate correctly from the last checkpoint.
- R reads the same `session.json` to populate the Outputs tab and the resume dropdown.

This mirrors the Claude Projects behaviour: files and prior chat outcomes stay available without re-uploading or re-processing.

---

## Python environment

The Python path is stored in `nb_session_config.json`. Examples:

```
/opt/conda/envs/data-science/bin/python   # conda env
./venv/bin/python                          # local venv
python3                                    # system Python (auto-detected)
```

Use **Validate Python** in Settings to confirm the path resolves before starting a run.

---

## R → Python control protocol

| R writes to `control.json` | Python does |
|---------------------------|------------|
| `{"command":"run"}`        | Normal execution |
| `{"command":"pause"}`      | Blocks at next cell boundary |
| `{"command":"stop"}`       | Saves state, exits cleanly |
| `{"command":"checkpoint_accept"}` | Marks cell approved, continues |
| `{"command":"checkpoint_skip"}`   | Skips cell, increments fail counter |

---

## Adding a new module

1. Add an entry to `modules/_module_registry.yml`.
2. Create `modules/<id>/ui.R` with a `<id>_ui(id)` function.
3. Create `modules/<id>/server.R` with a `<id>_server(id, ...)` function.
4. Add the server signature to the dispatch block in `global.R → create_server()`.

No other changes needed — the module loader and UI factory handle the rest.
