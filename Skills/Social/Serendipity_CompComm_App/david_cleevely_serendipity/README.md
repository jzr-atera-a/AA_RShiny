# Serendipity — David Cleevely (Interactive App)

Applied to **Atera Analytics Ltd** (the same case-study company used in the Compelling Communication app).

## Running it
Requires R with `shiny` and `shinydashboard` installed:
```r
install.packages(c("shiny", "shinydashboard"))
shiny::runApp(".")
```
Requires an internet connection at runtime (loads D3 v7 from `https://d3js.org` and Google Fonts).

## Structure (mirrors the Compelling Communication template)
```
├── app.R                      # Entry point — sidebar, tabs, server wiring
├── global.R                   # Reused UI helpers + new viz-embedding helpers
├── modules/                   # One file per tab, each exporting <id>_ui() / <id>_server()
│   ├── app_guide.R
│   ├── overview.R
│   ├── ch1_entangled_bank.R … ch10_edge_of_chaos.R
│   └── conclusion.R
└── www/
    ├── css/global.css         # Base design system reused verbatim + new component styles appended
    └── js/interactive.js      # SerendipityViz — shared D3 v7 component library
```

## What's reused vs. new from the Compelling Communication template
- **Reused unchanged:** the entire base `global.css` (palette, typography, hero/box/card styling), the
  `sidebarMenu`/`tabItems`/module-wiring pattern in `app.R`, and every text-content helper in `global.R`
  (`sh`, `shg`, `concept_card`/`app_card`, `quote_block`, `example_pair`, `tip_box`/`success_box`/`warn_box`,
  `metric_card`, `toc_item`, `chapter_card`, `progress_bar_item`, `timeline_entry`).
- **New (appended, not overriding anything):** `.viz-box`/`.viz-canvas`/`.viz-controls` etc. in `global.css`,
  `viz_box()`/`d3_init()`/`viz_legend()`/`viz_slider()` in `global.R`, and the whole `www/js/interactive.js`
  component library.
- **Not carried over:** the unused `R/module_loader.R` + `_module_registry.yml` config-driven scaffold from
  the original zip — it was never actually wired into `app.R` there, so this build uses the flat, manual
  module pattern that was the *real* working structure.

## Chapter tab pattern
Every chapter has **three** subtabs (one more than the Compelling Communication template's two, to make room
for the requested interactivity):
1. **General Concepts** — the book's theory
2. **Interactive** — a D3 visualisation built specifically for that chapter's core idea
3. **Applicability on Atera Analytics** — what it means for Atera's actual grant, pilot and partnership work

## The D3 component library (`SerendipityViz`)
One generic implementation per chart type, reused across chapters with different data:

| Component | Used in |
|---|---|
| `forceNetwork()` | Ch 1, 3, 4, 9, 10 — draggable force-directed network graphs |
| `updateChaos()` / `toggleWeakTies()` | Ch 3, 9, 10 — live slider/toggle control over a registered network |
| `timeline()` | Ch 2 — clickable horizontal timeline |
| `barChart()` | Ch 6 — hoverable bar chart |
| `gaugeDial()` | Ch 7 — slider-driven dial with live commentary |
| `quadrantScatter()` | Ch 8 — click-for-detail scatter plot |
| `radarChart()` | Ch 5 — live self-assessment radar, driven by five range sliders |

Chapter 10's network is the flagship interactive piece: the same graph responds live to an order↔chaos slider,
which rebinds the D3 force simulation's charge and link-strength parameters in real time.

## Known limitation
This was authored as source files (no R runtime was available to execute/test in this environment) — review
in a real Shiny session before deploying, the same way you would with any hand-authored Shiny app.
