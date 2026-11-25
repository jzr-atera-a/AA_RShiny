# Structure (build of 14 Nov 2026)

- `app.R`: entry point. Sources `global.R`, then every file in `modules/`, builds the sidebar and the server.
- `global.R`: packages and the one place where `R/` is sourced, in order. `R/_disable_autoload.R` stops Shiny sourcing `R/` a second time.
- `R/`: shared helpers (no UI). Capital.com side: `utils_cc_*.R` (api, catalog, patterns, chart, records + Trade Log, sheet, advice + evidence, plan + course checks).
- `modules/`: one file per screen or group of sub-tabs, each holding its `_ui` and `_server`:
  - `trading_desk.R`: the Trading Desk layout (A Morning Sheet, B Analyse & Place, C Review, D Trade Log, E-G, Setup). It arranges the pieces of `trading_records.R` (IG / Morning Sheet) and `cc_trading_records.R` (Capital.com).
  - `api_config.R`: BigQuery, Claude API, Capital.com, Trello & Jira configuration tabs.
  - `weekly_activities.R`: the six weekly activity sub-tabs used by `pattern_matrix.R`.
  - `unit3_workbench.R`: the workbench and its guides.
- `tests/`: `Rscript tests/test_*.R` with `R_LIBS` pointing at the stub libraries; `harness_cc_app.R` runs the Capital.com screen against a fake broker.

BigQuery: two stores, each reads a table once per session and appends its own writes to memory.
`cc_` tables: `R/utils_cc_records.R` (`cc_tables`); heavy JSON columns (`cc_heavy_cols`) are read one row at a time.
`trading_` tables: `R/utils_trading_records.R`.

To add a sub-tab: write `<id>_ui` and `<id>_server` in one file under `modules/`, add its `tabItem` and server call in `app.R`.
