# Flexible Comparison Table Suite — App Overview & Query Guide

This document explains what the app does, how data is stored, and — most
importantly — how to write a **solid generation query** so Claude API produces
a clean, parseable comparison table that uploads correctly into BigQuery.

It's written to be handed to a *fresh* Claude conversation as context: paste
this whole file in, describe the new table you want, and ask Claude to draft
the query fields below.

---

## 1. What the app does

The app is an R Shiny suite that:

1. **Generates comparison tables via the Claude API** — you describe two axes
   (what the ROWS represent, what the COLUMNS represent) and a request; Claude
   decides how many rows and columns are actually relevant and returns them in
   a strict, machine-parseable text format.
2. **Stores them in a single flexible BigQuery table** — the number of
   columns is NOT fixed in the schema. Every table, no matter how many
   columns it has, fits into the same handful of BigQuery columns because the
   columns themselves are packed into one delimited-text field
   (`columns_data`).
3. **Renders them back as a scrollable, Excel-like grid** — with frozen
   header row + frozen first column, checkerboard shading, adjustable column
   width, and optional LaTeX/MathJax rendering.

### Why this matters for writing queries
Because the number of columns is decided by Claude at generation time (not
by the database schema), the **query you write is the only thing controlling
table shape, size, and content quality**. A well-built query is the
difference between a clean, consistent 5×5 grid and a mess of inconsistent
columns that fails to parse.

---

## 2. BigQuery schema (flexible-column design)

```
id                      INTEGER    auto-generated, sequential
created_at              TIMESTAMP  auto-generated
source                  STRING     'claude' or 'manual'
category                STRING     top-level domain, e.g. 'Finance'
topic                   STRING     specific comparison, e.g. 'ML Models for Asset Class Price Forecasting'
table_title             STRING     display title for the table
row_dimension_label     STRING     what the ROWS represent, e.g. 'Financial Asset Class'
column_dimension_label  STRING     what the COLUMNS represent, e.g. 'Machine Learning Model'
row_index               STRING     the specific row label, e.g. 'Equities'
columns_data            STRING     delimited text holding an EVER-CHANGING number of columns for this row
notes                   STRING     optional free-text note about the row
```

**One physical BigQuery row = one row of the rendered table.** All of that
row's columns are packed into `columns_data` using two literal delimiter
tokens Claude is instructed never to use elsewhere:

| Token | Meaning |
|---|---|
| `\|\|\|COL\|\|\|` | separates one column entry from the next |
| `\|\|\|KV\|\|\|`  | separates a column's HEADER from its VALUE |

Example `columns_data` value:
```
Random Forest|||KV|||Handles nonlinearity well; needs regular retraining as regimes shift.|||COL|||LSTM|||KV|||Captures long-range dependencies; data-hungry and slow to train.
```

### Why Category + Topic isn't always enough
A single `Category` + `Topic` pair can contain **several distinct subtables**.
Example: Category = `Fitness & Sport`, Topic = `Muscle Building` could hold
both a "Top Arm Exercises" subtable AND a "Top Leg Exercises" subtable. The
combination that uniquely identifies one specific table is:

```
Category + Topic + Rows Label (row_dimension_label) + Columns Label (column_dimension_label)
```

The **Table Viewer** tab requires all four of these to load and render a
grid — that's intentional, not a limitation.

---

## 3. The Generate Table form — field by field

| Field | Purpose | Notes |
|---|---|---|
| **Category** | Broad domain | dropdown + "add new"; e.g. `Finance`, `Fitness & Sport` |
| **Topic** | Specific comparison subject | dropdown + "add new"; selecting an existing topic auto-fills the labels below |
| **Table Title** | Display title | free text |
| **What do the ROWS represent?** | Row axis label | e.g. `Financial Asset Class`, `Exercises for Muscle Build` |
| **What do the COLUMNS represent?** | Column axis label | e.g. `Machine Learning Model`, `Arm Section` |
| **Describe what you want compared** | The actual instruction sent to Claude | see §4 below — this is the field that matters most |
| **Expected Rows / Expected Columns** | Used ONLY to budget the response size (token estimate) | your description's wording, e.g. "top 5", still decides the real count |
| **Include LaTeX in cell values?** | Radio, default **No** | turn on only if you actually want formulas rendered |
| **Max Words per Cell** | Slider, 20–200, default 40 | hard per-cell length cap sent to Claude |

---

## 4. How to write a solid "Describe what you want compared" query

This is the single highest-leverage field. A good query has five ingredients:

1. **An explicit count on both axes** — "top 5", "the 4 major...", "3 leading...".
   Don't leave row/column count open-ended; Claude will happily generate 12
   columns if you don't cap it, which both bloats the response and makes the
   grid unwieldy.
2. **Concrete example names for both axes**, in parentheses. This anchors
   Claude to a standard, well-known set instead of an idiosyncratic one, and
   keeps column headers consistent row-to-row.
3. **A clear statement of what each cell should contain** — technique, trade-
   off, formula, whatever it is. Vague requests ("compare them") produce
   vague, generic cells that don't actually differ across rows.
4. **An explicit instruction to be specific to the row/column intersection,
   not generic.** This is the single most common failure mode: Claude
   describing a column technique in the abstract instead of how it applies
   to *that particular row*.
5. **Size discipline** — keep it to what actually fits your Expected
   Rows × Expected Columns × Words-per-Cell budget. A 12×12 request with
   200 words/cell is a very large generation and more likely to hit
   network/timeout issues than a 5×5 with 40 words/cell.

### Template

```
Identify the top {N} {ROW_SUBJECT} (e.g. {example1}, {example2}, {example3})
and the top {M} {COLUMN_SUBJECT} (e.g. {exampleA}, {exampleB}, {exampleC}).
For each {ROW_SUBJECT} / {COLUMN_SUBJECT} pair, explain: {what should be in
each cell — 2-4 specific things to cover}. Be specific to the row/column
intersection, not generic.
```

---

## 5. Worked examples used in this project

### Example A — Finance / ML forecasting (5×5)

| Field | Value |
|---|---|
| Category | `Finance` |
| Topic | `ML Models for Asset Class Price Forecasting` |
| Table Title | `Top 5 Asset Classes vs Top 5 ML Forecasting Techniques` |
| Rows represent | `Financial Asset Class` |
| Columns represent | `Machine Learning Forecasting Technique` |
| Expected Rows / Columns | 5 / 5 |
| Words per Cell | 40 |
| LaTeX | No |

**Description:**
```
Identify the top 5 major financial asset classes traded in the markets (e.g.
Equities, Fixed Income, Commodities, Currencies/FX, Cryptocurrencies) and the
top 5 machine learning techniques commonly used to forecast their prices for
trading purposes (e.g. LSTM/RNN, Random Forest, Gradient Boosting like
XGBoost, ARIMA/statistical hybrids, Transformer-based models). For each asset
class / ML technique pair, explain: how well-suited that technique is to that
asset class's specific characteristics (volatility, liquidity, seasonality,
noise), typical forecasting accuracy trade-offs, data requirements, and any
known pitfalls specific to trading that asset class with that technique. Be
specific to the row/column intersection, not generic.
```

### Example B — Fitness / Muscle Building (4×3, deliberately small)

| Field | Value |
|---|---|
| Category | `Fitness & Sport` |
| Topic | `Muscle Building` |
| Table Title | `Top Gym Exercises for Muscle - Arms` |
| Rows represent | `Exercises for Muscle Build` |
| Columns represent | `Arm Section Top 3` |
| Expected Rows / Columns | 4 / 3 |
| Words per Cell | 40 |
| LaTeX | No |

**Description:**
```
For each of the top 3 arm sections (Biceps, Triceps, Forearms), represented
as columns, list the top 4 exercises we can do in the gym to tone and
strengthen that muscle. The exercises are the rows - so there should be 4
rows total, one per exercise, and each row should have a value for each of
the 3 arm sections it's relevant to. For each exercise/section, briefly
describe technique, repetitions, and machine or weights involved.
```

> This smaller example is a good "first test" template whenever setting up a
> brand-new Category/Topic — confirm the pipeline works end-to-end on a small
> table before generating something larger like Example A.

### Example C — Larger original attempt (12×n — use with caution)

This was our first (larger) finance query, kept here as a caution example.
It generates a wider table and takes noticeably longer:

```
For each main arm part section, that will be represented as a column in the
table, generate a summary of the top 12 exercises we can do in the gym to
tone and strength that muscle. The exercises need to be represented as rows.
So we will have 12 rows representing the exercises and n arm body parts.
Describe the technique, repetitions, machine or weights involved and so on.
```

Lesson learned: this hit a network-layer issue (see §7) because a
non-streaming generation with ~12 rows and no explicit column cap took over
60 seconds with zero bytes flowing back, which some corporate proxies/VPNs/
antivirus HTTPS-inspection layers interpret as a dead connection and kill.
The app now streams responses (§7), which largely solves this, but it's
still good practice to keep first attempts on a new topic small (§5 Example B)
before scaling up.

---

## 6. Sizing guidance (rows × columns × words-per-cell)

The app estimates a token budget as roughly:

```
total_words ≈ (rows × columns × words_per_cell × latex_factor)
            + (rows × per_row_overhead)
max_tokens  ≈ total_words × 1.5   [clamped between 1,500 and 64,000]
```

Practical guidance when choosing Expected Rows / Expected Columns / Words per
Cell for a new query:

| Table size | Rows × Cols | Words/cell | Relative generation time |
|---|---|---|---|
| Small / test | 4×3 to 5×5 | 40 | fast, ~15-30s |
| Medium | 6×6 to 8×6 | 40-60 | moderate, ~30-90s |
| Large | 10×8+ | 60+ | slow, more prone to network issues — consider splitting into two Topics instead (e.g. "Arms Top 3" and "Legs Top 3" as separate subtables under the same Topic, loaded separately in Table Viewer) |

When in doubt, prefer **more, smaller subtables** (same Category/Topic,
different Row/Column Dimension Labels) over one very large table. This also
matches how the app is designed to browse data — Table Viewer already expects
multiple subtables per Topic.

---

## 7. Known issue & fix: long-running requests over restrictive networks

**Symptom:** `TLS connection closed abruptly ... schannel: server closed
abruptly (missing close_notify)`, consistently at a fixed elapsed time (e.g.
exactly ~60s) regardless of the configured request timeout.

**Cause:** a non-streaming API call sends zero bytes back while Claude
generates the full response. Corporate proxies, VPNs, and antivirus HTTPS-
inspection layers often kill a connection that looks "idle" for ~60 seconds,
even though nothing is actually wrong.

**Fix already implemented in the app:** `call_claude()` uses Server-Sent
Events streaming (`"stream": true`), so small chunks of text arrive
continuously as Claude generates them — the connection never looks idle. The
R console also logs a heartbeat every ~5 seconds during generation
(`[call_claude] Streaming... N chunks, N bytes, N chars ...`) so you can see
data flowing live and confirm the fix is working, plus a "Run Network
Diagnostics" button on the Claude API Config tab for a quick pre-flight
connectivity check.

If you're extending this app or building a similar one, replicate this
pattern for any Claude API call expected to run more than ~30-45 seconds.

---

## 8. Loading generated content into BigQuery

Once Claude returns table text in the correct format, it goes into BigQuery
via one of:

- **Generate Table → Parse & Upload Direct** (one click, same tab)
- **Generate Table → Copy to Bulk Import**, then review/parse/upload on the
  Bulk Import tab (useful if you want to eyeball or hand-edit the raw text
  first)
- **Add Single Entry** — manually add or correct one row by hand, one
  `Header: Value` per line

All three ultimately call `APIManager$bq_insert()`, which auto-assigns the
next `id`, stamps `created_at`, and appends to the table
(`atera-2.Wonderfulp_March.flex_comparison_tables` by default).

---

## 9. Viewing what's been loaded

**Table Viewer** requires, in order:
1. **Category**
2. **Topic** (cascades from Category)
3. **Rows Label** (`row_dimension_label` — cascades from Category+Topic)
4. **Columns Label** (`column_dimension_label` — cascades from the above three)

Once all four are picked, **Load Table** renders the full grid: every row,
every column (union of headers across rows), with the stored Rows/Columns
Label text as the axis headings — frozen header row, frozen first column,
checkerboard shading, adjustable column width (30-110 characters), and
LaTeX/MathJax rendering if any cell contains `$...$` or `$$...$$`.

---

## 10. Quick checklist before generating a new table

- [ ] Pick (or reuse) a **Category** and **Topic**
- [ ] Give ROWS and COLUMNS clear, specific dimension labels
- [ ] State an explicit count on both axes in the description ("top N", "the M leading...")
- [ ] Give 2-3 concrete example names per axis
- [ ] Say exactly what should be in each cell
- [ ] Add "be specific to the row/column intersection, not generic"
- [ ] Set Expected Rows / Expected Columns to match what you asked for
- [ ] Leave LaTeX off unless you actually need formulas
- [ ] Start small (4×3 to 5×5) when testing a brand-new Category/Topic
