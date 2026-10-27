# MBA 2024-2025 Works & Essays - interactive edition

Companion to *Jose_Zubizarreta_MBA_Works_and_Essays*. Every work is shown as text and
boxes inside the app. There is no PDF viewer, browser extension or external service.

## Running it

Open R in this folder and run:

    shiny::runApp(".")

Packages: shiny, shinydashboard, plotly, DT, jsonlite. Google Fonts are used when online
and fall back to system fonts when offline.

## Layout

- **Sidebar**: Collection overview, then the four terms (Michaelmas, Lent, Easter, Summer),
  each opening to a term overview and one entry per work. Tools (Front matter, Analytics,
  Timeline & index, About and method) sit below.
- **Each work** has four sub-tabs:
  - **Summary**: central question, headline figure, summary, audience, themes, key arguments,
    conclusions, frameworks and a link to the original PDF.
  - **Analysis**: the work at a glance (who, for whom, what, when, where, why, how), a
    paraphrased discussion in boxed blocks, a table of the facts and figures the work states with
    their printed pages, a critical reading and links to the course.
  - **Insights**: headline figures and charts built from what the work says: valuations,
    allocations, stakeholder positions, risk registers, roadmaps, timelines, comparisons and
    argument chains, each with a "What it shows" takeaway and its page. Presentations also show
    their original slides.
  - **Sources**: author-year citations found in the text, with charts.
- **Collection tools**: theme map of all works, audiences, a searchable table of every fact and
  figure, a side-by-side comparison of two works, search across all texts, hand-in timeline and index.

## Files

- `app.R` - user interface and server.
- `R/data_works.R` - term and work metadata, page ranges, summaries, key arguments,
  conclusions and frameworks.
- `R/text_tools.R` - search, summaries, key passages, citations and text statistics.
- `R/plots.R` - interactive charts.
- `www/styles.css` - the visual theme.
- `www/slides/` and `data/slides.json` - the pages of the four presentations that carry charts, and their captions.
- `www/img/` - crest and logo. `www/pdf/` - the original PDFs, for download only.
- `R/analysis.R` - reads the Analysis tab for each work.
- `data/analysis/<ID>.txt` - the written analysis for each work. Blocks are marked
  `@OVERVIEW`, `@BLOCK heading|label`, `@CRITIQUE` and `@LINKS`; every other non-blank line is a paragraph.
  Edit these files to change the Analysis tab, then restart the app.
- `R/insights.R` and `data/insights/<ID>.json` - the profile, headline figures, facts (with
  printed pages), themes, audience and chart definitions for each work. Chart types: bar,
  grouped, donut, waterfall, diverging, gantt, milestones, range, cards, steps, versus, table.
  Edit a JSON file to change a work's Insights, then restart the app.
- `data/works_text_v2.json` - the extracted text of every page, with printed page numbers,
  OCR text from images and section outlines. Keep this file with the app.

## Notes

- Printed page numbers follow the collection: the cover, dedication and both introductions
  are unnumbered, and the index is page 4.
- Hand-in dates come from the index. Word counts are shown where the cover sheet states them.
- Summaries, key arguments and conclusions and the Analysis tab were written to help navigation
  and critical reading. Key passages, the topic and argument charts, and citations are computed
  from the text and can contain extraction artefacts such as joined words.
