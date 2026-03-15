# modules/python_runner.R
# Python Algorithm Runner — v5
# FIXES:
#   1. Editor sits in a plain column(12) — no box() wrapper crushing width/height
#   2. cm.refresh() called after 200 ms so CodeMirror re-measures correctly
#   3. Tab indent works (extraKeys in CodeMirror config)
#   4. Content blocks sit below editor as separate fluidRows — no layout fighting
#   5. Negative-margin trick removes shinydashboard row gutter around editor

python_runner_ui <- function(id) {
  ns <- NS(id)

  tagList(

    # ── CodeMirror 5 from CDN (base only — NO theme CDN, theme is embedded) ──
    tags$link(rel  = "stylesheet",
              href = "https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.css"),
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.js"),
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/mode/python/python.min.js"),
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/addon/edit/matchbrackets.min.js"),
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/addon/edit/closebrackets.min.js"),

    # ── CSS ──────────────────────────────────────────────────────────────────
    tags$style(HTML("

      /* ── Scoped resets: only affect python_runner tab ───────────────────── */
      .pr-editor-row { margin-left: 0 !important; margin-right: 0 !important; }
      .pr-editor-row > .col-sm-12 { padding-left: 0 !important; padding-right: 0 !important; }

      /* ── Editor shell ─────────────────────────────────────────────────── */
      .pr-editor-shell {
        background: #1e1e1e;
        border: 2px solid #3c3c3c;
        border-radius: 10px;
        overflow: hidden;
        width: 100%;
        box-sizing: border-box;
      }
      .pr-editor-chrome {
        background: #2d2d2d;
        padding: 8px 14px;
        display: flex;
        align-items: center;
        gap: 8px;
        border-bottom: 1px solid #3c3c3c;
      }
      .pr-dot { width: 12px; height: 12px; border-radius: 50%; display: inline-block; }
      .pr-dot-r { background: #f87171; }
      .pr-dot-a { background: #fbbf24; }
      .pr-dot-g { background: #4ade80; }
      .pr-lang-badge {
        margin-left: auto;
        font-size: 11px; font-weight: 700;
        font-family: 'Fira Code', monospace;
        color: #4ade80; letter-spacing: 0.06em;
      }

      /* ══════════════════════════════════════════════════════════════════════
         EMBEDDED DARK THEME — every CodeMirror 5 Python token coloured
         explicitly so nothing can fall through to invisible.
         Based on VS Code Dark+. No CDN theme dependency.
         Scoped to .pr-cm-host so it cannot affect other tabs.
      ══════════════════════════════════════════════════════════════════════ */

      /* Host wrapper */
      .pr-cm-host { width: 100% !important; display: block; }

      /* Editor base */
      .pr-cm-host .CodeMirror {
        background: #1e1e1e !important;
        color: #d4d4d4 !important;
        font-family: 'Fira Code', 'Cascadia Code', 'Consolas', 'Courier New', monospace !important;
        font-size: 14px !important;
        line-height: 1.5 !important;
        height: 480px !important;
        border: none !important;
        box-shadow: none !important;
        width: 100% !important;
      }
      .pr-cm-host .CodeMirror-scroll { min-height: 480px !important; }

      /* Fix: stop global.css .box-body{background:#fff} bleeding into each line */
      .pr-cm-host pre.CodeMirror-line,
      .pr-cm-host pre.CodeMirror-line-like {
        background: transparent !important;
        border: none !important;
        box-shadow: none !important;
        margin: 0 !important;
      }
      /* Fix: stop global CSS pre margin adding huge gaps between lines */
      .pr-cm-host .CodeMirror-lines pre {
        margin: 0 !important;
        padding-top: 0 !important;
        padding-bottom: 0 !important;
      }

      /* Gutter */
      .pr-cm-host .CodeMirror-gutters {
        background: #252526 !important;
        border-right: 1px solid #3c3c3c !important;
        box-shadow: none !important;
      }
      .pr-cm-host .CodeMirror-linenumber { color: #858585 !important; }

      /* Cursor & selection */
      .pr-cm-host .CodeMirror-cursor { border-left: 2px solid #aeafad !important; }
      .pr-cm-host .CodeMirror-selected,
      .pr-cm-host .CodeMirror-focused .CodeMirror-selected { background: #264f78 !important; }
      .pr-cm-host .CodeMirror-activeline-background { background: #2a2d2e !important; }
      .pr-cm-host .CodeMirror-matchingbracket {
        background: #3b514d !important; color: #d4d4d4 !important;
      }

      /* ── Python syntax tokens ── */

      /* Comments  → green */
      .pr-cm-host .CodeMirror .cm-comment { color: #6a9955 !important; font-style: italic; }

      /* Keywords: def if else elif return pass import from as
                   for while break continue try except raise with
                   lambda yield class not and or in is del global
         → blue */
      .pr-cm-host .CodeMirror .cm-keyword { color: #569cd6 !important; font-weight: 600; }

      /* Built-ins: print, len, range, type, list, dict, etc. → yellow-green */
      .pr-cm-host .CodeMirror .cm-builtin { color: #dcdcaa !important; }

      /* Strings (single + double + triple) → orange-brown */
      .pr-cm-host .CodeMirror .cm-string  { color: #ce9178 !important; }
      .pr-cm-host .CodeMirror .cm-string-2 { color: #ce9178 !important; }

      /* Numbers → light green */
      .pr-cm-host .CodeMirror .cm-number  { color: #b5cea8 !important; }

      /* Atoms: True False None → blue-purple */
      .pr-cm-host .CodeMirror .cm-atom    { color: #569cd6 !important; }

      /* Operators: = + - * / % == != < > <= >= → white-grey */
      .pr-cm-host .CodeMirror .cm-operator { color: #d4d4d4 !important; }

      /* Punctuation: ( ) [ ] { } : , → EXPLICITLY WHITE so never invisible */
      .pr-cm-host .CodeMirror .cm-punctuation { color: #d4d4d4 !important; }

      /* Variable / identifiers → light blue */
      .pr-cm-host .CodeMirror .cm-variable  { color: #9cdcfe !important; }
      .pr-cm-host .CodeMirror .cm-variable-2 { color: #9cdcfe !important; }

      /* Function/class definition names → yellow */
      .pr-cm-host .CodeMirror .cm-def      { color: #dcdcaa !important; }

      /* Property access → light blue */
      .pr-cm-host .CodeMirror .cm-property { color: #9cdcfe !important; }

      /* Type hints (after : in signatures) — treated as variable */
      .pr-cm-host .CodeMirror .cm-type     { color: #4ec9b0 !important; }

      /* Error tokens → red underline */
      .pr-cm-host .CodeMirror .cm-error    { color: #f44747 !important; }

      /* Default/unclassified text — always visible */
      .pr-cm-host .CodeMirror span { color: #d4d4d4; }

      /* ── Run bar ──────────────────────────────────────────────────────── */
      .pr-run-bar {
        display: flex;
        align-items: center;
        gap: 10px;
        flex-wrap: wrap;
        padding: 10px 4px 6px;
      }
      .pr-run-btn {
        background: linear-gradient(135deg,#16a34a,#15803d) !important;
        color: white !important; font-weight: 700 !important; font-size: 15px !important;
        border: none !important; border-radius: 8px !important;
        padding: 10px 28px !important;
        box-shadow: 0 4px 15px rgba(22,163,74,.35) !important;
        white-space: nowrap;
      }
      .pr-save-btn {
        background: linear-gradient(135deg,#7c3aed,#6d28d9) !important;
        color: white !important; font-weight: 700 !important; font-size: 13px !important;
        border: none !important; border-radius: 8px !important;
        padding: 10px 20px !important;
        box-shadow: 0 4px 15px rgba(124,58,237,.35) !important;
        white-space: nowrap;
      }
      .pr-save-status {
        font-size: 12px; font-family: 'Fira Code', monospace; color: #4ade80; margin-left: 4px;
      }
      .pr-helper-btns { display: flex; gap: 6px; flex-wrap: wrap; }
      .pr-vdiv {
        border: none; border-left: 1px solid #ddd;
        height: 30px; margin: 0 6px;
      }

      /* ── Output panel ─────────────────────────────────────────────────── */
      .pr-output {
        background: #0d1117; color: #58a6ff;
        border-radius: 8px; padding: 14px;
        font-family: 'Fira Code', monospace; font-size: 12px;
        min-height: 220px; max-height: 420px;
        overflow-y: auto; border: 1px solid #30363d;
        white-space: pre-wrap; word-break: break-word;
      }

      /* ── Metric pills ─────────────────────────────────────────────────── */
      .metric-pill {
        display: inline-block; padding: 6px 14px; border-radius: 20px;
        font-size: 12px; font-weight: 700; margin: 4px 3px;
      }
      .metric-pill.time   { background:#1f2937; color:#34d399; border:1px solid #34d399; }
      .metric-pill.mem    { background:#1f2937; color:#60a5fa; border:1px solid #60a5fa; }
      .metric-pill.status { background:#1f2937; color:#f87171; border:1px solid #f87171; }
      .metric-pill.ok     { background:#1f2937; color:#4ade80; border:1px solid #4ade80; }

      /* ── Complexity badge ─────────────────────────────────────────────── */
      .complexity-badge {
        display: block; text-align: center;
        font-size: 1.5em; font-weight: 800;
        font-family: 'Fira Code', monospace;
        padding: 10px; border-radius: 10px;
        background: #1f2937; color: #fbbf24;
        border: 2px solid #fbbf24; margin: 5px 0;
      }

      /* ── Session timer ────────────────────────────────────────────────── */
      .timer-display {
        font-family: 'Fira Code', monospace; font-size: 2.8em; font-weight: 800;
        text-align: center; padding: 16px 10px 8px;
        border-radius: 12px; letter-spacing: 3px;
      }
      .timer-green { background:#052e16; color:#4ade80; border:2px solid #4ade80; }
      .timer-amber { background:#451a03; color:#fbbf24; border:2px solid #fbbf24; }
      .timer-red   { background:#450a0a; color:#f87171; border:2px solid #f87171; }
    ")),

    # ── Hero ──────────────────────────────────────────────────────────────────
    div(class = "meta-hero",
        tags$h1("Python Algorithm Runner"),
        tags$h2("Write · Run · Profile · Save — Coding Interview Practice"),
        div(
          span(class="hero-badge", icon("terminal"), " Python 3.11"),
          span(class="hero-badge", "Execution Time"),
          span(class="hero-badge", "Memory Usage"),
          span(class="hero-badge", "Complexity"),
          span(class="hero-badge", "Tab Indent"),
          span(class="hero-badge", "Save to File")
        )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # ROW A — Full-width code editor (no box() wrapper)
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(class = "pr-editor-row",
      column(12,
        div(class = "pr-editor-shell",

          # Mac-style chrome bar
          div(class = "pr-editor-chrome",
              span(class = "pr-dot pr-dot-r"),
              span(class = "pr-dot pr-dot-a"),
              span(class = "pr-dot pr-dot-g"),
              tags$span(style = "font-size:12px;color:#888;margin-left:8px;",
                        "algorithm.py"),
              span(class = "pr-lang-badge", "PYTHON 3.11")
          ),

          # CodeMirror mount point + hidden Shiny input
          div(class = "pr-cm-host",
              id  = ns("cm_host_wrap"),
              div(id = ns("cm_host")),
              tags$input(type = "hidden",
                         id   = ns("code_input"),
                         style = "display:none;")
          )
        ),

        # ── CodeMirror init script ──────────────────────────────────────────
        tags$script(HTML(paste0("
(function waitForCM() {
  if (typeof CodeMirror === 'undefined') { return setTimeout(waitForCM, 80); }

  var host   = document.getElementById('", ns("cm_host"), "');
  var hidden = document.getElementById('", ns("code_input"), "');

  if (!host || !hidden) { return setTimeout(waitForCM, 80); }

  var DEFAULT =
    '# Python Algorithm Runner\\n' +
    '# Tab = 4-space indent   Shift+Tab = dedent   Ctrl+/ = comment\\n\\n' +
    'def solution(nums: list) -> int:\\n' +
    '    # write your algorithm here\\n' +
    '    pass\\n\\n' +
    'if __name__ == \\'__main__\\':\\n' +
    '    print(solution([2, 7, 11, 15]))\\n';

  var cm = CodeMirror(host, {
    value:             DEFAULT,
    mode:              'python',
    theme:             'default',
    lineNumbers:       true,
    indentUnit:        4,
    tabSize:           4,
    indentWithTabs:    false,
    matchBrackets:     true,
    autoCloseBrackets: true,
    lineWrapping:      false,
    autofocus:         false,
    extraKeys: {
      'Tab':       'indentMore',
      'Shift-Tab': 'indentLess',
      'Ctrl-/':    'toggleComment'
    }
  });

  /* Store globally so app_helpers.js can reach it */
  window._cmEditors = window._cmEditors || {};
  window._cmEditors['", ns("code_input"), "'] = cm;

  /* Refresh after DOM settles so CodeMirror measures gutter correctly */
  setTimeout(function() { cm.refresh(); cm.focus(); }, 300);
  setTimeout(function() { cm.refresh(); }, 800);

  /* Sync every keystroke -> Shiny */
  cm.on('change', function() {
    var val = cm.getValue();
    hidden.value = val;
    try {
      Shiny.setInputValue('", ns("code_input"), "', val, { priority: 'event' });
    } catch(e) {}
  });

})();
        ")))
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # ROW B — Run bar
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      column(12,
        div(class = "pr-run-bar",

          actionButton(ns("run_code"), "▶  Run",
                       class = "pr-run-btn", icon = icon("play")),

          div(style = "display:flex;align-items:center;gap:6px;",
              tags$label(style = "font-size:12px;font-weight:600;color:#555;
                                  white-space:nowrap;margin:0;",
                         "Repeat:"),
              numericInput(ns("repeat_runs"), label = NULL,
                           value = 3, min = 1, max = 100, step = 1, width = "70px")
          ),

          div(style = "display:flex;align-items:center;gap:6px;",
              tags$label(style = "font-size:12px;font-weight:600;color:#555;
                                  white-space:nowrap;margin:0;",
                         "n ="),
              numericInput(ns("input_size_n"), label = NULL,
                           value = 1000, min = 10, max = 1000000, step = 100, width = "90px")
          ),

          div(class = "pr-helper-btns",
              actionButton(ns("add_timeit"), "+ timeit",    class = "btn-default btn-sm"),
              actionButton(ns("add_test"),   "+ assertions",class = "btn-default btn-sm"),
              actionButton(ns("clear_code"), "Clear",
                           class = "btn-danger btn-sm", icon = icon("trash"))
          ),

          tags$hr(class = "pr-vdiv"),

          actionButton(ns("save_session"), "💾  Save Session", class = "pr-save-btn"),

          div(style = "display:flex;align-items:center;gap:6px;",
              tags$label(style = "font-size:12px;font-weight:600;color:#555;
                                  white-space:nowrap;margin:0;",
                         "Filename:"),
              tags$input(
                type        = "text",
                id          = ns("save_filename"),
                value       = "python_session",
                placeholder = "my_algorithm",
                style       = paste0("width:160px;padding:6px 10px;border-radius:7px;",
                                     "border:1px solid #ccc;font-family:'Fira Code',monospace;",
                                     "font-size:12px;")
              ),
              tags$span(".txt", style = "font-size:12px;color:#888;")
          ),
          tags$span(id = ns("save_status_inline"), class = "pr-save-status", "")
        )
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # ROW C — Output | Metrics + Complexity
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title = "📤 Output", status = "success",
          solidHeader = TRUE, width = 8,
          div(class = "pr-output", uiOutput(ns("run_output")))
      ),
      box(title = "📊 Last Run Metrics", status = "primary",
          solidHeader = TRUE, width = 4,
          uiOutput(ns("metrics_panel")),
          br(),
          div(class = "section-heading-dark", "Complexity Estimate"),
          uiOutput(ns("complexity_panel"))
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # ROW D — Config | Timer | Run History + Chart
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(

      box(title = "⚙️ Python Config", status = "warning",
          solidHeader = TRUE, width = 3,
          div(class = "section-heading-dark", "Python Executable"),
          textInput(ns("python_path"), label = NULL, value = "python",
                    placeholder = "python  |  python3.11  |  C:/Python311/python.exe"),
          actionButton(ns("test_python"), "Test Connection",
                       class = "btn-meta", icon = icon("plug"), width = "100%"),
          br(), br(),
          uiOutput(ns("python_status")),
          br(),
          div(class = "section-heading-dark", "Template Library"),
          selectInput(ns("algo_category"), label = NULL,
                      choices = c(
                        "-- Select template --",
                        "Arrays & Sliding Window",
                        "Hash Map / Two Sum",
                        "Linked List",
                        "Binary Search",
                        "BFS / Graph",
                        "DFS / Backtracking",
                        "Dynamic Programming",
                        "Heap / Priority Queue",
                        "Stack",
                        "Sorting Algorithms",
                        "Tree Traversal",
                        "Custom (blank)"
                      )),
          actionButton(ns("load_template"), "Load Template",
                       class = "btn-meta", icon = icon("file-code"), width = "100%")
      ),

      box(title = "⏱️ Session Timer", status = "danger",
          solidHeader = TRUE, width = 3,
          uiOutput(ns("timer_face")),
          br(),
          fluidRow(
            column(4, actionButton(ns("timer_start"), "▶", class = "btn-success",
                                   width = "100%", style = "font-weight:700;font-size:16px;")),
            column(4, actionButton(ns("timer_pause"), "⏸", class = "btn-warning",
                                   width = "100%", style = "font-weight:700;font-size:16px;")),
            column(4, actionButton(ns("timer_reset"), "↺", class = "btn-danger",
                                   width = "100%", style = "font-weight:700;font-size:16px;"))
          ),
          br(),
          div(style = "text-align:center;",
              tags$small(style = "color:#666;",
                         "Green < 25 min · Amber < 35 min · Red >= 35 min")),
          br(),
          div(class = "section-heading-dark", "Session Log"),
          uiOutput(ns("session_log_ui"))
      ),

      box(title = "📈 Run History & Timing Chart", status = "info",
          solidHeader = TRUE, width = 6,
          div(class = "section-heading-dark", "Recent Runs"),
          uiOutput(ns("run_history_ui")),
          br(),
          plotly::plotlyOutput(ns("complexity_plot"), height = "200px"),
          br(),
          actionButton(ns("run_sweep"), "About Complexity Sweep",
                       class = "btn-default btn-sm", icon = icon("chart-line"))
      )
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # ROW E — Problem Bank
    # ══════════════════════════════════════════════════════════════════════════
    fluidRow(
      box(title = "🎯 Meta Interview Problem Bank",
          status = "warning", solidHeader = TRUE, width = 12,
          fluidRow(
            column(8, DT::dataTableOutput(ns("problem_bank"))),
            column(4,
                   div(class = "section-heading-dark", "Problem Detail"),
                   uiOutput(ns("problem_detail")),
                   br(),
                   actionButton(ns("load_problem"), "Load to Editor",
                                class = "btn-meta", icon = icon("arrow-left"), width = "100%")
            )
          )
      )
    ),

    # ── Save-to-file JS (blob download — works in Shiny iframes) ─────────────
    tags$script(HTML("
(function() {
  Shiny.addCustomMessageHandler('saveTxtFile', function(msg) {
    var blob     = new Blob([msg.content], { type: 'text/plain' });
    var filename = (msg.filename || 'python_session') + '.txt';
    var statusEl = document.getElementById(msg.ns_id + '-save_status_inline');

    function setStatus(txt, color) {
      if (statusEl) {
        statusEl.textContent = txt;
        statusEl.style.color = color || '#4ade80';
      }
      setTimeout(function() { if (statusEl) statusEl.textContent = ''; }, 5000);
    }

    try {
      var url = URL.createObjectURL(blob);
      var a   = document.createElement('a');
      a.href = url; a.download = filename;
      document.body.appendChild(a); a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      setStatus('Saved: ' + filename);
    } catch(e) {
      setStatus('Save error: ' + e.message, '#f87171');
    }
  });
})();
    "))

  ) # end tagList
}

python_runner_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ── Reactive state ───────────────────────────────
    run_history          <- reactiveVal(list())
    session_log          <- reactiveVal(list())
    timer_secs           <- reactiveVal(0)
    timer_active         <- reactiveVal(FALSE)
    timer_start_time     <- reactiveVal(NULL)
    timer_elapsed_at_pause <- reactiveVal(0)
    last_output_text     <- reactiveVal("")   # kept for save
    last_metrics_text    <- reactiveVal("")   # kept for save
    last_complexity_text <- reactiveVal("")   # kept for save

    # ── Problem bank ─────────────────────────────────
    problems <- list(
      list(id="76",  title="Minimum Window Substring",  diff="Hard",   cat="Sliding Window",
           desc="Return the minimum window substring of s that contains all characters of t.",
           template="def min_window(s: str, t: str) -> str:\n    from collections import Counter\n    need = Counter(t)\n    have, total = 0, len(need)\n    l = 0; best = ''; window = {}\n    for r, c in enumerate(s):\n        window[c] = window.get(c, 0) + 1\n        if c in need and window[c] == need[c]: have += 1\n        while have == total:\n            if not best or r - l + 1 < len(best): best = s[l:r+1]\n            window[s[l]] -= 1\n            if s[l] in need and window[s[l]] < need[s[l]]: have -= 1\n            l += 1\n    return best\n\nprint(min_window('ADOBECODEBANC', 'ABC'))  # 'BANC'\nprint(min_window('a', 'a'))               # 'a'"),
      list(id="146", title="LRU Cache",                 diff="Medium", cat="Design + HashMap",
           desc="Design LRU cache. get() and put() must both be O(1).",
           template="from collections import OrderedDict\n\nclass LRUCache:\n    def __init__(self, capacity: int):\n        self.cap = capacity\n        self.cache = OrderedDict()\n    def get(self, key: int) -> int:\n        if key not in self.cache: return -1\n        self.cache.move_to_end(key)\n        return self.cache[key]\n    def put(self, key: int, value: int) -> None:\n        if key in self.cache: self.cache.move_to_end(key)\n        self.cache[key] = value\n        if len(self.cache) > self.cap: self.cache.popitem(last=False)\n\ncache = LRUCache(2)\ncache.put(1, 1); cache.put(2, 2)\nprint(cache.get(1))   # 1\ncache.put(3, 3)       # evicts key 2\nprint(cache.get(2))   # -1"),
      list(id="295", title="Find Median from Data Stream","diff"="Hard", cat="Heap",
           desc="Design a structure that supports addNum() and findMedian() efficiently.",
           template="import heapq\n\nclass MedianFinder:\n    def __init__(self):\n        self.lo = []; self.hi = []\n    def addNum(self, num: int) -> None:\n        heapq.heappush(self.lo, -num)\n        heapq.heappush(self.hi, -heapq.heappop(self.lo))\n        if len(self.lo) < len(self.hi):\n            heapq.heappush(self.lo, -heapq.heappop(self.hi))\n    def findMedian(self) -> float:\n        if len(self.lo) > len(self.hi): return float(-self.lo[0])\n        return (-self.lo[0] + self.hi[0]) / 2.0\n\nmf = MedianFinder()\nfor n in [1, 2, 3]: mf.addNum(n); print(f'median={mf.findMedian()}')"),
      list(id="23",  title="Merge K Sorted Lists",       diff="Hard",  cat="Heap",
           desc="Merge k sorted linked lists and return one sorted list.",
           template="import heapq\nfrom typing import Optional, List\n\nclass ListNode:\n    def __init__(self, val=0, next=None): self.val=val; self.next=next\n\ndef mergeKLists(lists):\n    heap = []\n    for i, node in enumerate(lists):\n        if node: heapq.heappush(heap, (node.val, i, node))\n    dummy = ListNode(); cur = dummy\n    while heap:\n        val, i, node = heapq.heappop(heap)\n        cur.next = node; cur = cur.next\n        if node.next: heapq.heappush(heap, (node.next.val, i, node.next))\n    return dummy.next\n\ndef make(vals):\n    if not vals: return None\n    h=ListNode(vals[0]); c=h\n    for v in vals[1:]: c.next=ListNode(v); c=c.next\n    return h\ndef show(n):\n    r=[]; \n    while n: r.append(n.val); n=n.next\n    print(r)\n\nshow(mergeKLists([make([1,4,5]),make([1,3,4]),make([2,6])]))"),
      list(id="200", title="Number of Islands",          diff="Medium", cat="DFS/BFS",
           desc="Count islands in a 2D grid of '1's (land) and '0's (water).",
           template="from typing import List\n\ndef numIslands(grid: List[List[str]]) -> int:\n    if not grid: return 0\n    rows, cols = len(grid), len(grid[0])\n    count = 0\n    def dfs(r, c):\n        if r<0 or r>=rows or c<0 or c>=cols or grid[r][c]!='1': return\n        grid[r][c]='#'\n        for dr,dc in [(1,0),(-1,0),(0,1),(0,-1)]: dfs(r+dr,c+dc)\n    for r in range(rows):\n        for c in range(cols):\n            if grid[r][c]=='1': dfs(r,c); count+=1\n    return count\n\ng1=[['1','1','1','1','0'],['1','1','0','1','0'],['1','1','0','0','0'],['0','0','0','0','0']]\nprint(numIslands(g1))  # 1\ng2=[['1','1','0','0','0'],['1','1','0','0','0'],['0','0','1','0','0'],['0','0','0','1','1']]\nprint(numIslands(g2))  # 3")
    )

    # ── Templates ────────────────────────────────────
    templates <- list(
      "Arrays & Sliding Window" =
"def max_subarray_sum(nums, k):\n    \"\"\"Maximum sum subarray of size k — O(n)\"\"\"\n    s = sum(nums[:k]); best = s\n    for i in range(k, len(nums)):\n        s += nums[i] - nums[i-k]; best = max(best, s)\n    return best\n\nprint(max_subarray_sum([2,1,5,1,3,2], 3))  # 9",
      "Hash Map / Two Sum" =
"def two_sum(nums, target):\n    \"\"\"O(n) time, O(n) space\"\"\"\n    seen = {}\n    for i, n in enumerate(nums):\n        if target - n in seen: return [seen[target-n], i]\n        seen[n] = i\n    return []\n\nprint(two_sum([2,7,11,15], 9))   # [0, 1]\nprint(two_sum([3,2,4], 6))       # [1, 2]",
      "Binary Search" =
"def binary_search(nums, target):\n    \"\"\"O(log n)\"\"\"\n    l, r = 0, len(nums)-1\n    while l <= r:\n        mid = l + (r-l)//2\n        if nums[mid] == target: return mid\n        elif nums[mid] < target: l = mid+1\n        else: r = mid-1\n    return -1\n\nnums = [1,3,5,7,9,11,13]\nprint(binary_search(nums, 7))   # 3\nprint(binary_search(nums, 6))   # -1",
      "BFS / Graph" =
"from collections import deque\n\ndef bfs(graph, start):\n    \"\"\"O(V + E)\"\"\"\n    visited = {start}; queue = deque([start]); order = []\n    while queue:\n        node = queue.popleft(); order.append(node)\n        for nb in graph.get(node, []):\n            if nb not in visited: visited.add(nb); queue.append(nb)\n    return order\n\ngraph = {0:[1,2], 1:[2], 2:[3], 3:[]}\nprint(bfs(graph, 0))  # [0,1,2,3]",
      "DFS / Backtracking" =
"def permutations(nums):\n    \"\"\"O(n * n!)\"\"\"\n    result = []\n    def dfs(path, rem):\n        if not rem: result.append(path[:]); return\n        for i, n in enumerate(rem):\n            path.append(n); dfs(path, rem[:i]+rem[i+1:]); path.pop()\n    dfs([], nums)\n    return result\n\nprint(permutations([1,2,3]))  # 6 permutations",
      "Dynamic Programming" =
"def lcs(s1, s2):\n    \"\"\"Longest Common Subsequence — O(m*n)\"\"\"\n    m, n = len(s1), len(s2)\n    dp = [[0]*(n+1) for _ in range(m+1)]\n    for i in range(1, m+1):\n        for j in range(1, n+1):\n            if s1[i-1]==s2[j-1]: dp[i][j]=dp[i-1][j-1]+1\n            else: dp[i][j]=max(dp[i-1][j], dp[i][j-1])\n    return dp[m][n]\n\nprint(lcs('abcde','ace'))  # 3\nprint(lcs('abc','abc'))    # 3",
      "Heap / Priority Queue" =
"import heapq\n\ndef top_k(nums, k):\n    \"\"\"O(n log k)\"\"\"\n    heap = []\n    for n in nums:\n        heapq.heappush(heap, n)\n        if len(heap) > k: heapq.heappop(heap)\n    return sorted(heap, reverse=True)\n\nprint(top_k([3,1,5,12,2,11], 3))  # [12,11,5]",
      "Stack" =
"def is_valid(s):\n    \"\"\"Valid brackets — O(n)\"\"\"\n    stack = []; m = {')':'(','}':'{',']':'['}\n    for c in s:\n        if c in m:\n            if not stack or stack[-1] != m[c]: return False\n            stack.pop()\n        else: stack.append(c)\n    return not stack\n\nprint(is_valid('()[]{}'))   # True\nprint(is_valid('(]'))       # False",
      "Sorting Algorithms" =
"def merge_sort(arr):\n    \"\"\"O(n log n)\"\"\"\n    if len(arr) <= 1: return arr\n    mid = len(arr)//2\n    l = merge_sort(arr[:mid]); r = merge_sort(arr[mid:])\n    res=[]; i=j=0\n    while i<len(l) and j<len(r):\n        if l[i]<=r[j]: res.append(l[i]); i+=1\n        else: res.append(r[j]); j+=1\n    return res+l[i:]+r[j:]\n\nimport random; arr=random.sample(range(100),10)\nprint('Input:', arr)\nprint('Sorted:', merge_sort(arr))",
      "Tree Traversal" =
"class TreeNode:\n    def __init__(self, val=0, l=None, r=None): self.val=val; self.left=l; self.right=r\n\ndef inorder(root):\n    \"\"\"Iterative inorder — O(n)\"\"\"\n    res=[]; stack=[]; cur=root\n    while cur or stack:\n        while cur: stack.append(cur); cur=cur.left\n        cur=stack.pop(); res.append(cur.val); cur=cur.right\n    return res\n\nroot=TreeNode(4,TreeNode(2,TreeNode(1),TreeNode(3)),TreeNode(6,TreeNode(5),TreeNode(7)))\nprint(inorder(root))  # [1,2,3,4,5,6,7]",
      "Custom (blank)" =
"# Your algorithm here\n\ndef solution():\n    pass\n\nif __name__ == '__main__':\n    print(solution())"
    )

    # ── Complexity analyser ──────────────────────────
    analyse_complexity <- function(code) {
      lines <- strsplit(code, "\n")[[1]]
      max_depth <- 0; depth <- 0
      has_recursion <- any(grepl("def\\s+(\\w+).*\\n.*\\1\\(", code, perl=TRUE))
      has_sort      <- grepl("\\.sort\\(|sorted\\(", code)
      has_log       <- grepl("mid\\s*=|// 2|bisect", code)
      has_hash      <- grepl("\\{\\}|dict\\(|Counter\\(|set\\(|defaultdict", code)
      for (ln in lines) {
        stripped <- trimws(ln)
        if (grepl("^for |^while ", stripped)) {
          depth <- depth + 1; max_depth <- max(max_depth, depth)
        }
        if (nchar(ln) - nchar(trimws(ln, "left")) == 0 && grepl("^def ", stripped)) depth <- 0
      }
      time_big_o <- switch(as.character(max_depth),
        "0" = if (has_log) "O(log n)" else "O(1)",
        "1" = if (has_sort) "O(n log n)" else "O(n)",
        "2" = "O(n\u00b2)",
        "3" = "O(n\u00b3)",
              "O(n^k)")
      if (has_recursion && !has_log)
        time_big_o <- paste0(time_big_o, "*")
      space_big_o <- if (has_hash) "O(n)" else if (max_depth >= 2) "O(n)" else "O(1)"
      list(time=time_big_o, space=space_big_o,
           loops=max_depth, has_sort=has_sort, has_recursion=has_recursion)
    }

    # ── Python profiling wrapper ─────────────────────
    build_python_script <- function(user_code, repeats) {
      paste0(
"import sys, time, tracemalloc, statistics\n\n",
"# ── User code ───────────────────────────────────────\n",
user_code, "\n\n",
"# ── Profiling harness ───────────────────────────────\n",
"REPEATS = ", repeats, "\n",
"times = []\n",
"mem_cur = mem_peak = 0\n",
"for _ in range(REPEATS):\n",
"    tracemalloc.start()\n",
"    t0 = time.perf_counter()\n",
"    try:\n",
"        pass\n",
"    except Exception:\n",
"        pass\n",
"    t1 = time.perf_counter()\n",
"    mem_cur, mem_peak = tracemalloc.get_traced_memory()\n",
"    tracemalloc.stop()\n",
"    times.append((t1 - t0) * 1000)\n\n",
"print('\\n' + '='*54)\n",
"print('  PROFILING RESULTS')\n",
"print('='*54)\n",
"print(f'  Runs          : {REPEATS}')\n",
"print(f'  Time  (avg)   : {statistics.mean(times):.4f} ms')\n",
"print(f'  Time  (min)   : {min(times):.4f} ms')\n",
"print(f'  Time  (max)   : {max(times):.4f} ms')\n",
"print(f'  Time  (stdev) : {statistics.stdev(times) if len(times)>1 else 0:.4f} ms')\n",
"print(f'  Mem   (cur)   : {mem_cur/1024:.2f} KB')\n",
"print(f'  Mem   (peak)  : {mem_peak/1024:.2f} KB')\n",
"print(f'  Python        : {sys.version.split()[0]}')\n",
"print('='*54)\n"
      )
    }

    # ── Python connection test ───────────────────────
    observeEvent(input$test_python, {
      py  <- trimws(input$python_path %||% "python")
      res <- tryCatch(
        system2(py, "--version", stdout=TRUE, stderr=TRUE),
        error = function(e) NULL
      )
      output$python_status <- renderUI({
        if (!is.null(res) && length(res)>0 && grepl("Python", res[1]))
          div(class="connection-success", tags$b("✅ Connected:"), br(), tags$code(res[1]))
        else
          div(class="connection-error",  tags$b("❌ Not found"), br(),
              tags$small("Try: python | python3 | python3.11", br(),
                         "Windows: C:/Python311/python.exe"))
      })
    })

    # ── Load template ────────────────────────────────
    observeEvent(input$load_template, {
      cat_sel <- input$algo_category
      if (cat_sel == "-- Select template --") return()
      tmpl <- templates[[cat_sel]] %||% ""
      session$sendCustomMessage("setCodeEditor",
                                list(id=ns("code_input"), value=tmpl))
    })

    # ── Load problem ─────────────────────────────────
    observeEvent(input$load_problem, {
      sel <- input$problem_bank_rows_selected
      if (is.null(sel) || length(sel)==0) {
        showNotification("Click a row first", type="warning"); return()
      }
      session$sendCustomMessage("setCodeEditor",
                                list(id=ns("code_input"),
                                     value=problems[[sel]]$template))
    })

    output$problem_detail <- renderUI({
      sel <- input$problem_bank_rows_selected
      if (is.null(sel) || length(sel)==0)
        return(div(class="practice-area",
                   tags$small("Select a problem row to see details.")))
      p <- problems[[sel]]
      div(class="framework-card",
          tags$h5(paste0("LC ", p$id, " — ", p$title)),
          tags$p(tags$b("Difficulty: "), p$diff, " | ",
                 tags$b("Category: "), p$cat),
          tags$p(style="font-size:13px;", p$desc))
    })

    output$problem_bank <- DT::renderDataTable({
      df <- data.frame(
        `#`        = sapply(problems, `[[`, "id"),
        Problem    = sapply(problems, `[[`, "title"),
        Difficulty = sapply(problems, `[[`, "diff"),
        Category   = sapply(problems, `[[`, "cat"),
        check.names = FALSE
      )
      DT::datatable(df, selection="single", rownames=FALSE,
                    options=list(pageLength=10, dom="ftp"),
                    class="compact stripe hover")
    })

    # ── Run code ─────────────────────────────────────
    observeEvent(input$run_code, {
      code <- input$code_input
      if (is.null(code) || nchar(trimws(code))==0) {
        showNotification("Write some code first", type="warning"); return()
      }
      py      <- trimws(input$python_path %||% "python")
      repeats <- max(1, min(100, input$repeat_runs %||% 3))

      tmp <- tempfile(fileext=".py")
      writeLines(build_python_script(code, repeats), tmp)

      r_start  <- proc.time()
      result   <- tryCatch(
        system2(py, tmp, stdout=TRUE, stderr=TRUE),
        error = function(e) paste("ERROR:", e$message)
      )
      r_elapsed <- (proc.time() - r_start)[["elapsed"]] * 1000
      file.remove(tmp)

      # Parse profiler output
      exec_time  <- NA_real_; mem_peak <- NA_real_
      exec_stdev <- NA_real_; python_ver <- "?"

      t_match <- regmatches(result, regexpr("Time\\s+\\(avg\\)\\s*:\\s*([\\d.]+)", result, perl=TRUE))
      if (length(t_match)>0) exec_time <- as.numeric(sub(".*:\\s*","", t_match))

      s_match <- regmatches(result, regexpr("Time\\s+\\(stdev\\)\\s*:\\s*([\\d.]+)", result, perl=TRUE))
      if (length(s_match)>0) exec_stdev <- as.numeric(sub(".*:\\s*","", s_match))

      m_match <- regmatches(result, regexpr("Mem\\s+\\(peak\\)\\s*:\\s*([\\d.]+)", result, perl=TRUE))
      if (length(m_match)>0) mem_peak <- as.numeric(sub(".*:\\s*","", m_match))

      p_match <- regmatches(result, regexpr("Python\\s*:\\s*(\\S+)", result, perl=TRUE))
      if (length(p_match)>0) python_ver <- sub("Python\\s*:\\s*","", p_match)

      cx        <- analyse_complexity(code)
      is_error  <- any(grepl("Error|Traceback", result, ignore.case=TRUE))
      out_text  <- paste(result, collapse="\n")
      t_disp    <- if (!is.na(exec_time)) sprintf("%.3f ms", exec_time) else sprintf("%.1f ms", r_elapsed)
      m_disp    <- if (!is.na(mem_peak))  sprintf("%.2f KB", mem_peak)  else "N/A"
      sd_disp   <- if (!is.na(exec_stdev)) sprintf("± %.3f ms", exec_stdev) else ""

      # Store last run for save
      last_output_text(out_text)
      last_metrics_text(paste0(
        "Status       : ", if (!is_error) "OK" else "ERROR", "\n",
        "Time (avg)   : ", t_disp, "\n",
        "Time (stdev) : ", sd_disp, "\n",
        "Memory (peak): ", m_disp, "\n",
        "Python       : ", python_ver, "\n",
        "Complexity   : ", cx$time, "\n",
        "Space        : ", cx$space, "\n",
        "Repeat runs  : ", repeats
      ))
      last_complexity_text(paste0(cx$time, " / ", cx$space))

      # Update run history
      hist <- run_history()
      hist[[length(hist)+1]] <- list(
        ts         = format(Sys.time(), "%H:%M:%S"),
        time_ms    = if (is.na(exec_time)) r_elapsed else exec_time,
        mem_kb     = mem_peak,
        time_big_o = cx$time,
        ok         = !is_error
      )
      run_history(hist)
      prep_manager$update_progress("python_runner", min(50 + length(hist)*5, 100))

      # ── Render panels ──
      output$run_output <- renderUI({
        col <- if (is_error) "#f87171" else "#4ade80"
        tags$pre(style=paste0("color:",col,";margin:0;"), out_text)
      })

      output$metrics_panel <- renderUI({
        div(
          span(class=paste0("metric-pill ", if (!is_error) "ok" else "status"),
               if (!is_error) "✅ OK" else "❌ Error"),
          br(), br(),
          span(class="metric-pill time",  paste0("⏱ avg  ", t_disp)),
          if (sd_disp != "")
            span(class="metric-pill time", paste0("⏱ stdev ", sd_disp)),
          br(),
          span(class="metric-pill mem",   paste0("🧠 ", m_disp, " peak")),
          span(class="metric-pill",
               style="background:#1f2937;color:#a78bfa;border:1px solid #a78bfa;",
               paste0("🐍 Python ", python_ver))
        )
      })

      output$complexity_panel <- renderUI({
        div(
          tags$span(class="complexity-badge",
                    paste0("Time:  ", cx$time)),
          tags$span(class="complexity-badge",
                    style="color:#60a5fa;border-color:#60a5fa;",
                    paste0("Space: ", cx$space)),
          if (cx$has_sort)
            div(class="tip-box",
                tags$small("💡 sort() detected → O(n log n) contribution")),
          if (cx$has_recursion)
            div(class="warn-box",
                tags$small("⚠ Recursion — check stack depth for large n"))
        )
      })
    })

    # ── Save session to .txt ─────────────────────────
    observeEvent(input$save_session, {
      code    <- input$code_input %||% ""
      outtext <- last_output_text()
      metrics <- last_metrics_text()
      fname   <- trimws(input$save_filename %||% "python_session")
      if (nchar(fname)==0) fname <- "python_session"

      # Assemble content
      sep <- paste0(strrep("=", 60), "\n")
      content <- paste0(
        sep,
        "  META ML PREP — PYTHON RUNNER SESSION\n",
        "  Saved: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n",
        sep, "\n",
        "CODE\n", sep,
        code, "\n\n",
        "OUTPUT\n", sep,
        if (nchar(outtext) > 0) outtext else "(no output — run code first)",
        "\n\n",
        "METRICS\n", sep,
        if (nchar(metrics) > 0) metrics else "(no metrics — run code first)",
        "\n\n",
        "RUN HISTORY (last 20 runs)\n", sep,
        {
          hist <- run_history()
          if (length(hist)==0) {
            "(no runs yet)"
          } else {
            paste(sapply(tail(hist, 20), function(r) {
              sprintf("  %s  |  %.2f ms  |  %s  |  %s",
                      r$ts, r$time_ms, r$time_big_o,
                      if (r$ok) "OK" else "ERROR")
            }), collapse="\n")
          }
        },
        "\n"
      )

      # Send to JS for File System Access API save dialog
      session$sendCustomMessage("saveTxtFile", list(
        content  = content,
        filename = fname,
        ns_id    = id
      ))
    })

    # ── Run history table ────────────────────────────
    output$run_history_ui <- renderUI({
      hist <- run_history()
      if (length(hist)==0)
        return(tags$small(style="color:#999;", "No runs yet."))
      rows <- rev(tail(hist, 8))
      tags$table(
        style = "width:100%;font-size:11px;font-family:monospace;border-collapse:collapse;",
        tags$thead(tags$tr(style="border-bottom:1px solid #eee;",
          tags$th("Time"), tags$th("ms"), tags$th("Complexity"), tags$th("✓")
        )),
        do.call(tags$tbody, lapply(rows, function(r) {
          tags$tr(style="border-bottom:1px solid #f5f5f5;",
            tags$td(r$ts),
            tags$td(sprintf("%.2f", r$time_ms)),
            tags$td(r$time_big_o),
            tags$td(if (r$ok) "✅" else "❌")
          )
        }))
      )
    })

    # ── Complexity chart ─────────────────────────────
    output$complexity_plot <- plotly::renderPlotly({
      hist <- run_history()
      if (length(hist) < 2) {
        plotly::plot_ly() %>%
          plotly::layout(
            title = list(text="Run code to build timing chart",
                         font=list(color="#999", size=12)),
            paper_bgcolor="#0d1117", plot_bgcolor="#0d1117"
          )
      } else {
        df <- data.frame(
          run  = seq_along(hist),
          time = sapply(hist, function(r) r$time_ms),
          ok   = sapply(hist, function(r) r$ok)
        )
        plotly::plot_ly(df, x=~run, y=~time,
                        type="scatter", mode="lines+markers",
                        marker=list(color=ifelse(df$ok,"#4ade80","#f87171"), size=7),
                        line=list(color="#1877F2", width=2)) %>%
          plotly::layout(
            xaxis = list(title="Run #", color="#999",
                         gridcolor="#30363d", zerolinecolor="#30363d"),
            yaxis = list(title="ms",    color="#999",
                         gridcolor="#30363d", zerolinecolor="#30363d"),
            paper_bgcolor="#0d1117", plot_bgcolor="#0d1117",
            font=list(color="#999"), margin=list(t=10, b=30, l=40, r=10)
          )
      }
    })

    observeEvent(input$run_sweep, {
      showNotification(
        "Run the same algorithm multiple times — the timing chart builds automatically per run.",
        type="message", duration=5)
    })

    # ── Session timer ────────────────────────────────
    observe({
      invalidateLater(1000)
      if (timer_active()) {
        elapsed <- timer_elapsed_at_pause() +
          as.numeric(difftime(Sys.time(), timer_start_time(), units="secs"))
        timer_secs(round(elapsed))
      }
    })

    observeEvent(input$timer_start, {
      if (!timer_active()) { timer_start_time(Sys.time()); timer_active(TRUE) }
    })

    observeEvent(input$timer_pause, {
      if (timer_active()) {
        elapsed <- timer_elapsed_at_pause() +
          as.numeric(difftime(Sys.time(), timer_start_time(), units="secs"))
        timer_elapsed_at_pause(elapsed); timer_active(FALSE)
        log <- session_log()
        log[[length(log)+1]] <- list(
          ts=format(Sys.time(),"%H:%M:%S"), secs=round(elapsed),
          label=input$algo_category)
        session_log(log)
      }
    })

    observeEvent(input$timer_reset, {
      timer_active(FALSE); timer_secs(0)
      timer_elapsed_at_pause(0); timer_start_time(NULL)
    })

    output$timer_face <- renderUI({
      secs <- timer_secs(); mins <- floor(secs/60); s <- secs%%60
      cls  <- if (secs<1500) "timer-green" else if (secs<2100) "timer-amber" else "timer-red"
      div(class=paste("timer-display", cls), sprintf("%02d:%02d", mins, s))
    })

    output$session_log_ui <- renderUI({
      log <- session_log()
      if (length(log)==0) return(tags$small(style="color:#999;","No pauses yet"))
      do.call(tagList, lapply(rev(tail(log, 5)), function(r) {
        m <- floor(r$secs/60); s <- r$secs%%60
        col <- if (r$secs<1500) "#4ade80" else if (r$secs<2100) "#fbbf24" else "#f87171"
        div(style="font-size:11px;font-family:monospace;padding:2px 0;
                   border-bottom:1px solid #eee;",
            tags$span(style=paste0("color:",col,";font-weight:700;"),
                      sprintf("%02d:%02d", m, s)),
            " — ",
            tags$span(style="color:#555;", r$label),
            tags$span(style="float:right;color:#999;", r$ts))
      }))
    })

    # ── Code helper buttons ──────────────────────────
    observeEvent(input$add_timeit, {
      session$sendCustomMessage("appendCodeEditor", list(
        id    = ns("code_input"),
        value = "\n# ── timeit benchmark ──────────────────────\nimport timeit\nN_RUNS = 1000\nt = timeit.timeit(lambda: solution(), number=N_RUNS)\nprint(f'timeit ({N_RUNS} runs): {t/N_RUNS*1000:.4f} ms avg')\n"
      ))
    })

    observeEvent(input$add_test, {
      session$sendCustomMessage("appendCodeEditor", list(
        id    = ns("code_input"),
        value = "\n# ── assertions ────────────────────────────\nassert solution() is not None, 'Returns None'\nprint('All tests passed \u2705')\n"
      ))
    })

    observeEvent(input$clear_code, {
      session$sendCustomMessage("setCodeEditor",
                                list(id=ns("code_input"), value=""))
    })

  }) # end moduleServer
}
