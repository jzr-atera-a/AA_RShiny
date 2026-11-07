# Briefing for the Claude instance that writes our infographic instructions

**Purpose of this file.** You are a Claude instance working with us on a grant application. Our R Shiny app ("BooksNetworksStrategySixS", tab **Technical Designs -> Infographic Studio**) calls the Claude API to generate an infographic. Your job is **not** to draw the infographic and **not** to write the final slide text. Your job is to write the **brief** (the instructions and inputs) that we paste into the app, so that the API produces the best possible result.

**The deliverable we want drawn:** a **2-page appendix** for an **Innovate UK** technical grant application. It must convey our **core differentiation** and our **ideas for commercial projects** using **robotics, AI, ML and/or other deep tech**. The reader is an Innovate UK assessor who skims quickly and scores against stated criteria.

Read this whole file before replying. Then follow section 9 (what to return).

---

## 1. What you must know about the app (updated version with dashboard slides)

### 1.1 How the app works (so you can write for it)

1. In the Infographic Studio tab we type a **topic** (multi-line), optional **extra instructions** (one line), and, in the optional panel **"Facts, requirements and brand colours"**: a **Facts supplied by you** box, a **Requirements (one per line)** box and four **brand colours** (hex). We also choose page format, number of slides, layout, panels per slide, title cover, text size, theme and evidence mode.
2. **Call 1, the plan** (no web search): the API receives the topic, extra instructions, **the facts and the requirements**, and the layout. It returns title, subtitle, kicker, theme, a `slides` array (a title, kicker and subtitle per slide) and the **sections**. Each section has an id, one block type, heading, intro, the **slide number it sits on**, and a **brief**. The app tells the API to copy the relevant applicant facts word for word into each brief and to make sure every requirement is covered by at least one section.
3. **Call 2, per statistics section** (web search on; only `stat_row`, `donut`, `bar_chart`, `ranking`, `pictogram`, `region_map`, `quote_cards`, `compare_matrix`): the API sees the poster title, the section brief and (new) the facts block. It does NOT see the topic text, so facts still need to be in the brief. Figures about the applicant are taken from the facts (not searched); the web is used for outside facts such as competing technologies.
4. **Call 3, all other sections** in one call (diagram blocks and text blocks), also given the facts block.
5. The **app** checks every cited quote against the cited page and **draws everything itself** (SVG). The API never draws.

### 1.2 Page formats and layouts

Formats: long poster, 16:9, **A4 landscape** (print, one slide per sheet), **A5 landscape** (print two slides per A4 sheet), 4:3, 1:1, 4:5, 9:16 (LinkedIn/portrait), A4 portrait. Slides: 1 to 8. PDF export uses the real paper size for A4/A5 landscape, and there is a PDF option that puts two A5 slides on one A4 sheet.

**Visual style (new control):** `Illustrated flow` (connected, stylised shapes: one continuous path links the sections in reading order, ribbon headings with numbered beads, ghost numerals, icon orbs on a wavy path for flow/steps/timeline/icon_row, Sankey-style ribbons for `ranking`, big outline numerals for `stat_row`), `Dashboard` (grid of panels) or `Stacked` (classic). Flow works on posters as well as slides. **In flow style the ORDER of sections is the story**, so write the plan as a sequence where each section leads to the next, and keep headings to 4 words.

- **Layout "Dashboard" (recommended for rich appendices):** each slide is a grid of **2-6 panels**; each panel holds one section drawn at its own size. Sections = (slides minus cover) x panels. The app chooses the grid per slide so that wide blocks (flow, compare_matrix, timeline) get wide cells and compact blocks (gauges, donuts) get small ones. Each slide has a header band showing the slide title from the `slides` array.
- **Layout "Flow":** same grid sizes as Dashboard, but sections are read in a snake order (left to right, then right to left on the next row) along the connecting path; use it when the story is a process or journey.
- **Layout "Stacked":** one section per slide (older style, simple).
- **Cover:** automatic / yes / no. For a 2-slide appendix choose **No** (both slides carry content).
- **Text size:** normal (1440 px wide canvas) or large (1200 px: everything is about 20% bigger; use with 2-4 panels per slide).
- For a **2-slide 16:9 grant appendix** use: Dashboard, 3-4 panels per slide, cover No, text size Normal or Large. That means 6-8 sections.

### 1.3 Block types the API may use (each section uses exactly one)

Statistics blocks (web research and evidence fields):

| Block | Items | Best for |
|---|---|---|
| `stat_row` | 2-4 big numbers with label, note, optional bar | headline figures |
| `donut` | 3-6 parts of a whole | shares that add to 100% |
| `bar_chart` | 3-8 bars ("bars" or "pencils") | compare a measure across categories |
| `ranking` | 4-8 sorted bars | league tables |
| `pictogram` | 2-4 rows of 10 person icons | "X out of 10" |
| `region_map` | 3-8 world-region tiles | geographic spread |
| `quote_cards` | 2-4 real, sourced quotations | credible voices |
| `compare_matrix` | 2-4 option columns (one is ours), 3-8 criteria rows, rating balls 0-4 | an **honest** comparison with alternatives. The API is told we must NOT win every row. |

Diagram and text blocks:

| Block | Items | Best for |
|---|---|---|
| `icon_row` | 3-6 icon + label + sentence | differentiators, benefits |
| `steps` | 3-6 numbered steps | approach, route to market |
| `branch_tree` | a question and 2-4 items per side | benefits vs risks |
| `callout` | one sentence (max 22 words) | the message to remember |
| `flow` | 3-7 nodes joined by arrows; each node can carry a tag | pipelines such as camera -> detector -> tracker -> alert |
| `layers` | 2-5 tiers, each with up to 6 chips | architecture: sensing / compute / comms / interface |
| `radial_zones` | concentric zones around a protected asset, up to 6 sensor nodes with a field of view, up to 3 threats | perimeter or coverage diagrams |
| `requirements` | 3-8 rows: must-have, how it is met, status (met / partial / planned / gap) | "how we meet each must-have" |
| `readiness` | 3-8 components on a 1-9 scale against a threshold line (for example TRL 6) | readiness vs requirement |
| `gauge_row` | 2-4 gauges with value, optional target tick, note | accuracy, latency, performance targets |
| `timeline` | 3-7 dated milestones with done / next / planned state | path to build and trials |

Still not supported: photos, logos, free-form drawing, maps with real geography, editable chart objects.

### 1.4 Hard limits on text (anything longer is cut)

Title max ~8 words (90 chars). Subtitle one sentence. Kicker 2-4 words. Slide title max 9 words (70 chars). Section heading max 5 words. Intro one sentence. Item label 2-4 words (60 max). Item text one short sentence (110-220 max depending on block). Gauge display text max 20 chars. Plain ASCII only (write "GBP"). The app shrinks a panel if it is too full and warns when it is below about 60% size; the fix is fewer items, fewer panels per slide, or more slides.

### 1.5 Icons (names only; anything else becomes a star)

user, users, globe, chart_up, chart_bar, chart_pie, dollar, coin, bank, lightbulb, shield, lock, heart, pulse, medical, star, clock, hourglass, calendar, cloud, database, server, chip, phone, laptop, wifi, network, mail, building, factory, home, briefcase, graduation, book, leaf, droplet, bolt, sun, gear, search, eye, target, compass, flag, pin, trophy, check, cross, plus, minus, warning, scale, cart, car, truck, plane, **drone, camera, radar, robot, thermal, bell, antenna, tower, wall, brain, route, layers, handshake** (the last 13 are new).

### 1.6 Themes and brand colours

Built-in: `midnight`, `sky`, `sunrise`, `forest`, `berry`, `paper`. **Custom brand theme:** four hex colours (dark, teal, magenta, ochre in our case) entered in the app; the theme list then offers "Your brand colours". Accent order in the drawing follows the order of the four colours.

### 1.7 The evidence model

Every statistic item carries `confidence`: `sourced`, `partial`, `judgment`, or the new **`applicant`** (a figure copied from the facts we supplied).
- The app marks each item: **verified** (quote found on the cited page; green), **unverified** (amber), **contradicted** (red), **judgment** (hollow grey), **applicant** (navy diamond).
- `applicant` is checked: a number marked applicant that does not appear in our facts text is automatically downgraded to judgment with a warning. A number is only matched, not its meaning, so we must still read the result.
- **Tags** drawn as dashed chips on diagram items: **TARGET** (a design goal, not a result), **INSERT** (placeholder, shown as [INSERT], no value), **SELF-ASSESSED** (a level or score we propose, for example a TRL).
- "Verified" means the quote exists on the page, not that the page proves our claim. PPTX slides are pictures (not editable text). Real API and BigQuery have not yet been exercised by the app's author; the first real run needs human checking.

### 1.8 Writing the facts and requirements boxes (new, the most important inputs)

- **Facts box:** plain sentences with every number we will stand behind, and an explicit statement of what is NOT done (for example "Drone field tests: not done. SAPIENT validation: not done."). Anything not done becomes [INSERT]. Do not put aspirations here unless worded as targets.
- **Requirements box:** one must-have per line, copied from the competition brief. The plan must cover each one.
- Do not ask the API to invent results. State dates (for example "Build February 2027, independent trials March 2027") so the timeline uses only those.

---

## 2. What the assessor wants (you must fill the gaps)

We will paste the **competition brief and scoring criteria** below the line "COMPETITION BRIEF" at the end of this file (or in our first message). Innovate UK criteria and appendix rules differ by competition, so **do not assume them**: read what we paste, and if it is missing, ask for it before drafting. Typical themes assessors score are: the need or market opportunity, the innovation and how it differs from existing approaches, the team and delivery plan, the route to market and commercial outcomes, the wider benefits, and the risks. Map each of our 4 sections to the criteria it serves, and say which.

---

## 3. The story to convey (default 4-section plan; adapt it)

| # | Section | Suggested block | Job it does |
|---|---|---|---|
| 1 | The commercial need | `stat_row` (or `bar_chart`) | 2-4 **sourced** figures on market size or cost of the problem |
| 2 | Our core differentiation | `icon_row` or `branch_tree` | 3-5 **specific** differences from how the problem is solved today |
| 3 | From technology to market | `steps` | Development path to a paying customer, with realistic stages |
| 4 | Impact and risk | `stat_row`, `branch_tree` or `callout` | Outcomes, plus main risks and mitigations |

Rules for the differentiation section (the most important one):
- Specific, checkable claims beat adjectives. "Cuts inspection time by X in our pilot" beats "revolutionary".
- State the alternative being displaced (the status quo or a named class of competitor) so the difference is clear.
- No unsupported superlatives ("world-leading", "first of its kind") unless we supply evidence.
- One idea per item. If we have several commercial project ideas, show them as separate items (for example one per sector), not as one blur.

---

## 4. How to write the **topic** text (the main input)

The topic box is passed to the plan call. Write it as a structured brief of about **150-300 words**, in this order:

1. **Audience and purpose:** "An Innovate UK assessor reading a 2-page appendix to a grant application. Purpose: show our core differentiation and the commercial potential of [short description]."
2. **The one message** (a single sentence).
3. **Tone:** factual, specific, no hype, UK English spelling is fine but keep text plain ASCII.
4. **The number of sections that matches the format in 1.2 (for example 6-8 for a 2-slide dashboard)**, each with: the block type to use, the job it does, and the figures or claims needed.
5. **Applicant-supplied facts**, in a labelled list, with the instruction: *"Carry these into the relevant section brief word for word; they are provided by the applicant and cannot be found on the web."* (This matters because the research call sees only the section brief, not the full topic.)
6. **What to research on the web** for each section (see section 5).
7. **What not to do:** invent statistics, claim verification, use unsourced superlatives.

The **extra instructions** line is a single line; keep it under about 200 characters, for example: `Assessor audience; factual, no hype; emphasise differentiation vs current methods; every number sourced or marked as our claim.`

---

## 5. Research questions (this decides the quality of the numbers)

For each data section, write 2-4 **precise** research questions the API can answer with a web search and a quotable sentence. Good questions name the metric, geography, period and source type, for example:

- "UK market size for [sector] in [year], from an industry body, regulator or government statistic."
- "Annual cost of [the problem] to UK [sector], from an official or peer-reviewed source."
- "Share of UK [sector] firms that have adopted [technology], from a government survey."

Avoid vague questions ("how big is AI?"). Prefer primary or authoritative sources (ONS, government departments, regulators, standards bodies, peer-reviewed papers, major consultancies' published reports). The API may choose up to 1-8 searches per section (we default to 4).

---

## 6. Handling our own claims honestly

Two kinds of numbers will appear:
1. **External figures** (market size, costs, adoption): researched, sourced, quote-checked.
2. **Our own figures** (pilot results, performance, TRL, costs saved): supplied by us. The app cannot verify them; they are displayed as applicant data (navy diamond) when they appear in the Facts box.

Your instructions must therefore:
- Ask us to supply the second kind explicitly, and list exactly which ones are needed (the **claims register**, section 9, item 6).
- Tell the API to present our own figures as applicant claims, for example in the note ("measured in our 2025 pilot"), never as externally sourced facts.
- Never let a placeholder look like real data. If we have no real figure, the section should use a qualitative block (`icon_row`, `steps`) instead of inventing a number.

(We may later add an "applicant-provided" evidence status and an option to hide evidence markers for print. Mention in your reply if you think this is needed.)

---

## 7. Quality checklist you must apply to your own draft

- [ ] Section count matches the chosen format (dashboard: slides x panels).
- [ ] Every section maps to at least one assessment criterion (listed).
- [ ] The differentiation section contains specific, checkable claims and names the alternative.
- [ ] No block type outside section 1.3; no more items than the caps in 1.3.
- [ ] Every number has either a research question (external) or a named supplier (us).
- [ ] No superlative without evidence; no invented statistic; no claim of "verified".
- [ ] All text short, plain ASCII, GBP not the pound sign.
- [ ] Block mix is varied (no block type more than twice), and a `callout` or strong closing line states the single message.
- [ ] Icons chosen only from the list in 1.5.

---

## 8. Review loop after the first run

We will run the infographic in the app and paste back two things: the **Data JSON** and the **Facts and Evidence table** (each statistic with status, metric, date, quote, sources). Review them as a sceptical assessor would and report:

- claims that are vague, unsupported or sit in the wrong section;
- numbers marked unverified, contradicted or judgment, and what to do about each;
- sources that look weak (blogs, vendor marketing) where an authoritative source should be sought;
- text that is too long or too generic;
- what is missing against the scoring criteria.

Then give us (a) a revised brief **or** (b) direct edits to the JSON. The app can re-draw edited JSON without another API call ("Re-Parse & Draw"), so small wording changes are free. Important: you cannot verify web facts yourself unless you have search tools; say so when you are unsure, and flag every figure we must check against the original page.

---

## 9. What to return (use this exact structure)

1. **Format settings:** page format (for example 16:9), number of slides, layout (Dashboard), panels per slide, cover (No), text size, brand colours or theme, evidence mode (web research), searches per section. Also return the exact text for the **Facts** box and the **Requirements** box.
2. **Topic text** (150-300 words, ready to paste into the topic box).
3. **Extra instructions line** (one line).
4. **Allowed block types** (the subset to tick in the app) with one line of reasoning.
5. **Section plan table** (4 rows): section number, heading (max 5 words), block type, assessment criterion served, intended message.
6. **Claims register:** a table of facts **we** must supply, each with a short description, the unit/format and which section needs it.
7. **Research questions** per section (2-4 each).
8. **Risks and gaps:** anything in the brief that the app cannot do (see 1.3), anything unverifiable, and any question you need answered before we run it.

Return it as Markdown with clear headings, with the topic text and extra-instructions line in code blocks so they copy cleanly.

---

## 10. Inputs we will provide (fill in before running)

**COMPETITION BRIEF** (paste the competition name, scoring questions and any appendix rules):

> [paste here]

**OUR COMPANY AND TECHNOLOGY** (core differentiation in one sentence, what the status quo is, technology readiness level, IP position, pilot or benchmark results, team credentials, target sectors, partners):

> [paste here]

**OUR COMMERCIAL PROJECT IDEAS** (robotics / AI / ML / other deep tech; for each: customer, problem, our approach, why now):

> [paste here]

**STYLE REFERENCES** (optional: examples of appendices we admire):

> [paste here]

---

## 11. Known limits and honesty rules (do not paper over these)

- The real Claude API, the web search tool and BigQuery have **not yet been run live against this app**; only mock tests have. The first live run may need prompt tuning, so expect one iteration.
- Web search must be enabled for our organisation in the Anthropic Console.
- The app cannot draw photos or logos or real-geography maps; it can draw pipelines, architecture layers, zone diagrams, readiness scales, gauges, timelines and comparison matrices (see 1.3).
- "Verified" means the quote was found on the cited page. It does not mean the claim is true or relevant. Every claim in a grant application must be checked by a person before submission.
- Do not invent facts about our company. If something is missing, ask us for it.
