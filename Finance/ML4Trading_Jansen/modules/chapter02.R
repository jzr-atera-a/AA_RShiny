# modules/chapter02.R — Market and Fundamental Data: Sources and Techniques

CH02_FILES <- list(
  list(
    name = "tick_to_bars.py",
    description = "<strong>tick_to_bars.py</strong> — Convert tick data to time-based, volume-based, or dollar-based bars for analysis.",
    code = '# Tick-to-Bar Conversion\nimport pandas as pd\nimport numpy as np\n\ndef time_bars(ticks, freq=\'1min\'):\n    """\n    Convert tick data to time-based bars\n    \n    Args:\n        ticks: DataFrame with columns [timestamp, price, volume]\n        freq: Time frequency (e.g., \'1min\', \'5min\', \'1H\')\n    \n    Returns:\n        OHLCV bars at specified frequency\n    """\n    bars = ticks.set_index(\'timestamp\').resample(freq).agg({\n        \'price\': [\'first\', \'max\', \'min\', \'last\'],\n        \'volume\': \'sum\'\n    })\n    bars.columns = [\'open\', \'high\', \'low\', \'close\', \'volume\']\n    return bars.dropna()\n\n# Example with simulated tick data\nnp.random.seed(42)\ntimestamps = pd.date_range(\'2024-01-01 09:30\', periods=1000, freq=\'1s\')\nticks = pd.DataFrame({\n    \'timestamp\': timestamps,\n    \'price\': 100 + np.random.randn(1000).cumsum() * 0.1,\n    \'volume\': np.random.randint(100, 1000, 1000)\n})\n\nminute_bars = time_bars(ticks, freq=\'1min\')\nprint("First 5 minute bars:")\nprint(minute_bars.head())',
    demo = 'np.random.seed(42)\ntimestamps = pd.date_range(\'2024-01-01 09:30\', periods=1000, freq=\'1s\')\nticks = pd.DataFrame({\n    \'timestamp\': timestamps,\n    \'price\': 100 + np.random.randn(1000).cumsum() * 0.1,\n    \'volume\': np.random.randint(100, 1000, 1000)\n})\nminute_bars = time_bars(ticks, freq=\'1min\')\nprint("First 5 minute bars:")\nprint(minute_bars.head())'
  ),
  list(
    name = "order_book_analysis.py",
    description = "<strong>order_book_analysis.py</strong> — Analyze order book depth and calculate bid-ask spread metrics.",
    code = '# Order Book Analysis\nimport pandas as pd\nimport numpy as np\n\nclass OrderBook:\n    """Simple order book analyzer"""\n    \n    def __init__(self, bids, asks):\n        """\n        Args:\n            bids: List of (price, size) tuples, sorted descending\n            asks: List of (price, size) tuples, sorted ascending\n        """\n        self.bids = sorted(bids, key=lambda x: x[0], reverse=True)\n        self.asks = sorted(asks, key=lambda x: x[0])\n    \n    def spread(self):\n        """Calculate bid-ask spread"""\n        best_bid = self.bids[0][0] if self.bids else 0\n        best_ask = self.asks[0][0] if self.asks else 0\n        return best_ask - best_bid\n    \n    def mid_price(self):\n        """Calculate mid price"""\n        best_bid = self.bids[0][0] if self.bids else 0\n        best_ask = self.asks[0][0] if self.asks else 0\n        return (best_bid + best_ask) / 2\n    \n    def depth(self, levels=5):\n        """Calculate order book depth"""\n        bid_depth = sum([size for _, size in self.bids[:levels]])\n        ask_depth = sum([size for _, size in self.asks[:levels]])\n        return {\'bid_depth\': bid_depth, \'ask_depth\': ask_depth}\n\n# Example order book\nbids = [(99.95, 500), (99.90, 1000), (99.85, 750)]\nasks = [(100.00, 600), (100.05, 800), (100.10, 1200)]\n\nbook = OrderBook(bids, asks)\nprint(f"Spread: ${book.spread():.2f}")\nprint(f"Mid Price: ${book.mid_price():.2f}")\nprint(f"Depth: {book.depth()}")',
    demo = 'bids = [(99.95, 500), (99.90, 1000), (99.85, 750)]\nasks = [(100.00, 600), (100.05, 800), (100.10, 1200)]\nbook = OrderBook(bids, asks)\nprint(f"Spread: ${book.spread():.2f}")\nprint(f"Mid Price: ${book.mid_price():.2f}")\nprint(f"Depth: {book.depth()}")'
  )
)

chapter2_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(2, "📊", "Market and Fundamental Data: Sources and Techniques",
      "Learn about market microstructure, high-frequency data, order books, tick-to-bar conversion, and fundamental data processing with XBRL automation.",
      c("Market Microstructure", "Order Book", "Tick Data", "XBRL", "Pandas")),

    stats_row(
      list("ITCH", "Nasdaq Protocol"),
      list("FIX", "Trading Protocol"),
      list("XBRL", "Financial Data"),
      list("HDF5", "Efficient Storage")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("maintabs"),
        
        tabPanel(title = tagList(icon("book"), " Concepts"),
          tabBox(width = 12, id = ns("concepttabs"),
            
            tabPanel(title = "🔬 Market Microstructure",
              fluidRow(
                box(title = "Understanding Market Microstructure", status = "info", solidHeader = TRUE, width = 6,
                    div(class = "framework-card",
                        tags$h5("What is Market Microstructure?"),
                        tags$p("The study of how orders are processed and prices are formed in financial markets. Critical for understanding transaction costs and designing trading strategies."),
                        tags$ul(
                          tags$li(tags$strong("Price Discovery:"), " How information becomes reflected in prices"),
                          tags$li(tags$strong("Liquidity:"), " Ability to trade without moving prices"),
                          tags$li(tags$strong("Transaction Costs:"), " Spread, slippage, market impact")
                        )
                    ),
                    div(class = "tip-box",
                        HTML("<strong>💡 Key Insight:</strong> Understanding microstructure helps minimize costs and optimize execution for algorithmic strategies.")
                    )
                ),
                box(title = "Order Book Dynamics", status = "primary", solidHeader = TRUE, width = 6,
                    tags$table(class = "algo-table",
                      tags$thead(tags$tr(
                        tags$th("Level"), 
                        tags$th("Bid Price"), 
                        tags$th("Bid Size"),
                        tags$th("Ask Price"),
                        tags$th("Ask Size")
                      )),
                      tags$tbody(
                        tags$tr(tags$td("1"), tags$td("$99.95"), tags$td("500"), tags$td("$100.00"), tags$td("600")),
                        tags$tr(tags$td("2"), tags$td("$99.90"), tags$td("1,000"), tags$td("$100.05"), tags$td("800")),
                        tags$tr(tags$td("3"), tags$td("$99.85"), tags$td("750"), tags$td("$100.10"), tags$td("1,200")),
                        tags$tr(tags$td("4"), tags$td("$99.80"), tags$td("1,500"), tags$td("$100.15"), tags$td("400")),
                        tags$tr(tags$td("5"), tags$td("$99.75"), tags$td("2,000"), tags$td("$100.20"), tags$td("900"))
                      )
                    ),
                    div(class = "info-box-plain",
                        HTML("<strong>Spread:</strong> $100.00 - $99.95 = $0.05 (5 cents)")
                    )
                )
              ),
              fluidRow(
                box(title = "High-Frequency Data Sources", status = "success", solidHeader = TRUE, width = 12,
                    div(class = "framework-card",
                        tags$h5("Tick Data"),
                        tags$p("Every individual trade or quote update. Highest resolution but massive volume."),
                        tags$ul(
                          tags$li("Trade ticks: Timestamp, price, volume, buy/sell indicator"),
                          tags$li("Quote ticks: Timestamp, bid price, bid size, ask price, ask size"),
                          tags$li("Storage: Compressed formats (HDF5, Parquet), tick databases")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Order Book Data"),
                        tags$p("Full depth of market showing all limit orders at each price level."),
                        tags$ul(
                          tags$li("Level 1: Best bid/ask only (top of book)"),
                          tags$li("Level 2: Multiple price levels (e.g., top 5 or 10)"),
                          tags$li("Level 3: Full order-by-order detail (market makers)")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Market Data Protocols"),
                        tags$ul(
                          tags$li(tags$strong("ITCH:"), " Nasdaq TotalView real-time feed"),
                          tags$li(tags$strong("FIX:"), " Financial Information eXchange protocol for order routing"),
                          tags$li(tags$strong("SIP:"), " Securities Information Processor consolidated feed")
                        )
                    )
                )
              )
            ),

            tabPanel(title = "📈 Tick-to-Bar Conversion",
              fluidRow(
                box(title = "Bar Construction Methods", status = "warning", solidHeader = TRUE, width = 12,
                    div(class = "framework-card",
                        tags$h5("Time Bars"),
                        tags$p("Traditional OHLCV candles at fixed time intervals."),
                        tags$ul(
                          tags$li(tags$strong("Pros:"), " Simple, widely understood, easy to visualize"),
                          tags$li(tags$strong("Cons:"), " Ignores varying market activity, gaps during low volume"),
                          tags$li(tags$strong("Typical Frequencies:"), " 1min, 5min, 15min, 1H, 1D")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Volume Bars"),
                        tags$p("Each bar represents a fixed number of shares/contracts traded."),
                        tags$ul(
                          tags$li(tags$strong("Pros:"), " Adapts to market activity, more bars during high volume"),
                          tags$li(tags$strong("Cons:"), " Variable time intervals, harder to interpret"),
                          tags$li(tags$strong("Example:"), " One bar = 10,000 shares traded")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Dollar Bars"),
                        tags$p("Each bar represents a fixed dollar value traded (price × volume)."),
                        tags$ul(
                          tags$li(tags$strong("Pros:"), " Normalizes for price level, better for cross-asset comparison"),
                          tags$li(tags$strong("Cons:"), " Complex calculation, less intuitive"),
                          tags$li(tags$strong("Example:"), " One bar = $1,000,000 traded")
                        )
                    ),
                    div(class = "success-box",
                        HTML("<strong>✅ Research Finding:</strong> Volume and dollar bars often produce more stationary returns than time bars, improving ML model performance.")
                    )
                )
              )
            ),

            tabPanel(title = "📑 Fundamental Data & XBRL",
              fluidRow(
                box(title = "Financial Statement Data", status = "info", solidHeader = TRUE, width = 6,
                    div(class = "framework-card",
                        tags$h5("Core Financial Statements"),
                        tags$ul(
                          tags$li(tags$strong("Income Statement:"), " Revenue, expenses, net income"),
                          tags$li(tags$strong("Balance Sheet:"), " Assets, liabilities, equity"),
                          tags$li(tags$strong("Cash Flow Statement:"), " Operating, investing, financing cash flows"),
                          tags$li(tags$strong("Footnotes:"), " Accounting policies, contingencies")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Key Fundamental Ratios"),
                        tags$ul(
                          tags$li("P/E Ratio = Price / Earnings"),
                          tags$li("P/B Ratio = Price / Book Value"),
                          tags$li("ROE = Net Income / Equity"),
                          tags$li("Debt-to-Equity = Total Debt / Equity")
                        )
                    )
                ),
                box(title = "XBRL Automated Processing", status = "success", solidHeader = TRUE, width = 6,
                    div(class = "framework-card",
                        tags$h5("What is XBRL?"),
                        tags$p("eXtensible Business Reporting Language — a standardized format for financial statements mandated by the SEC."),
                        tags$ul(
                          tags$li("Machine-readable financial data"),
                          tags$li("Standardized taxonomy for financial concepts"),
                          tags$li("Available via SEC EDGAR database")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Python XBRL Processing"),
                        tags$p("Key libraries and workflows:"),
                        tags$ul(
                          tags$li(tags$strong("SEC-API:"), " Download filings programmatically"),
                          tags$li(tags$strong("python-xbrl:"), " Parse XBRL documents"),
                          tags$li(tags$strong("pandas:"), " Structure data for analysis")
                        )
                    ),
                    div(class = "tip-box",
                        HTML("<strong>💡 Advantage:</strong> XBRL enables automated extraction of fundamental data for thousands of companies without manual data entry.")
                    )
                )
              ),
              fluidRow(
                box(title = "Data Storage & Management", status = "primary", solidHeader = TRUE, width = 12,
                    tags$table(class = "algo-table",
                      tags$thead(tags$tr(
                        tags$th("Format"), 
                        tags$th("Use Case"), 
                        tags$th("Pros"),
                        tags$th("Cons")
                      )),
                      tags$tbody(
                        tags$tr(
                          tags$td("CSV"), 
                          tags$td("Small datasets, sharing"), 
                          tags$td("Universal, human-readable"),
                          tags$td("Slow, large file size")
                        ),
                        tags$tr(
                          tags$td("HDF5"), 
                          tags$td("Large time series"), 
                          tags$td("Fast, compressed, hierarchical"),
                          tags$td("Binary (not human-readable)")
                        ),
                        tags$tr(
                          tags$td("Parquet"), 
                          tags$td("Columnar analytics"), 
                          tags$td("Excellent compression, fast queries"),
                          tags$td("Write-once (not appendable)")
                        ),
                        tags$tr(
                          tags$td("SQLite"), 
                          tags$td("Structured queries"), 
                          tags$td("SQL queries, lightweight"),
                          tags$td("Single-file limitations")
                        )
                      )
                    ),
                    div(class = "info-box-plain",
                        HTML("<strong>Recommendation:</strong> Use HDF5 with pandas HDFStore for tick/bar data. Use Parquet for feature matrices. Use PostgreSQL for production systems.")
                    )
                )
              )
            )
          )
        ),

        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header("Chapter 2 Code Examples", 
                         "Working with tick data, order books, and bar construction in Python."),
          file_pills_ui(ns, CH02_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter2_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH02_FILES)
  })
}
