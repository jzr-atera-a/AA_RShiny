# modules/chapter03.R — Alternative Data for Finance: Categories and Use Cases

CH03_FILES <- list(
  list(
    name = "web_scraping_example.py",
    description = "<strong>web_scraping_example.py</strong> — Web scraping example using BeautifulSoup to extract structured data from HTML.",
    code = '# Web Scraping Example (Placeholder - actual scraping requires libraries)\nimport re\n\ndef parse_restaurant_data(html_sample):\n    """\n    Simulate parsing restaurant data from HTML\n    In practice, use BeautifulSoup or Scrapy\n    """\n    # Simulated data extraction\n    restaurants = [\n        {\'name\': \'Tech Cafe\', \'reservations\': 45, \'rating\': 4.5},\n        {\'name\': \'Silicon Bistro\', \'reservations\': 32, \'rating\': 4.2},\n        {\'name\': \'Data Diner\', \'reservations\': 28, \'rating\': 4.7}\n    ]\n    \n    print("Parsed Restaurant Data:")\n    print("=" * 50)\n    for r in restaurants:\n        print(f"{r[\'name\']:20} | Reservations: {r[\'reservations\']:3} | Rating: {r[\'rating\']}")\n    \n    # Calculate aggregate metrics\n    total_reservations = sum(r[\'reservations\'] for r in restaurants)\n    avg_rating = sum(r[\'rating\'] for r in restaurants) / len(restaurants)\n    \n    print("=" * 50)\n    print(f"Total Reservations: {total_reservations}")\n    print(f"Average Rating: {avg_rating:.2f}")\n    \n    return restaurants\n\n# Example usage\ndata = parse_restaurant_data("sample_html")\nprint(f"\\nExtracted {len(data)} restaurants")',
    demo = 'data = parse_restaurant_data("sample_html")\nprint(f"\\nExtracted {len(data)} restaurants")'
  ),
  list(
    name = "sentiment_analysis.py",
    description = "<strong>sentiment_analysis.py</strong> — Simple sentiment analysis on text data to extract trading signals.",
    code = '# Sentiment Analysis Example\nimport re\n\ndef simple_sentiment(text):\n    """\n    Basic sentiment analysis using keyword matching\n    In practice, use VADER, TextBlob, or transformer models\n    """\n    positive_words = [\'growth\', \'profit\', \'gain\', \'up\', \'strong\', \'beat\', \'exceed\']\n    negative_words = [\'loss\', \'decline\', \'down\', \'weak\', \'miss\', \'below\']\n    \n    text_lower = text.lower()\n    pos_count = sum(1 for word in positive_words if word in text_lower)\n    neg_count = sum(1 for word in negative_words if word in text_lower)\n    \n    sentiment_score = (pos_count - neg_count) / max(pos_count + neg_count, 1)\n    \n    if sentiment_score > 0.2:\n        label = "POSITIVE"\n    elif sentiment_score < -0.2:\n        label = "NEGATIVE"\n    else:\n        label = "NEUTRAL"\n    \n    return {\'score\': sentiment_score, \'label\': label}\n\n# Example earnings call excerpts\ntexts = [\n    "Strong growth in revenue, profit exceeded expectations",\n    "Decline in sales, weak performance below forecast",\n    "Steady operations with moderate results"\n]\n\nprint("Sentiment Analysis Results:")\nprint("=" * 60)\nfor i, text in enumerate(texts, 1):\n    result = simple_sentiment(text)\n    print(f"Text {i}: {result[\'label\']:8} (Score: {result[\'score\']:+.2f})")\n    print(f"  \\"{text[:50]}...\\"\\n")',
    demo = 'texts = [\n    "Strong growth in revenue, profit exceeded expectations",\n    "Decline in sales, weak performance below forecast",\n    "Steady operations with moderate results"\n]\nprint("Sentiment Analysis Results:")\nprint("=" * 60)\nfor i, text in enumerate(texts, 1):\n    result = simple_sentiment(text)\n    print(f"Text {i}: {result[\'label\']:8} (Score: {result[\'score\']:+.2f})")\n    print(f"  \\"{text[:50]}...\\"\\n")'
  )
)

chapter3_ui <- function(id) {
  ns <- NS(id)
  tagList(
    chapter_hero(3, "🛰", "Alternative Data for Finance: Categories and Use Cases",
      "Explore the alternative data revolution: from satellite imagery to social media sentiment. Learn to evaluate, source, and integrate non-traditional data for trading signals.",
      c("Alternative Data", "Web Scraping", "Satellite Data", "Sentiment Analysis")),

    stats_row(
      list("$1.7B", "Alt Data Market 2020"),
      list("400+", "Data Providers"),
      list("5 Types", "Data Categories"),
      list("Edge", "Information Advantage")
    ),

    fluidRow(
      tabBox(width = 12, id = ns("maintabs"),
        
        tabPanel(title = tagList(icon("book"), " Concepts"),
          tabBox(width = 12, id = ns("concepttabs"),
            
            tabPanel(title = "🌍 Alternative Data Revolution",
              fluidRow(
                box(title = "What is Alternative Data?", status = "info", solidHeader = TRUE, width = 6,
                    div(class = "framework-card",
                        tags$h5("Definition"),
                        tags$p("Non-traditional data sources beyond standard financial statements and market prices. Provides unique insights into economic activity, consumer behavior, and company performance."),
                        tags$ul(
                          tags$li(tags$strong("Traditional:"), " Financial statements, price/volume, analyst reports"),
                          tags$li(tags$strong("Alternative:"), " Satellite imagery, credit card transactions, web traffic, social media")
                        )
                    ),
                    div(class = "tip-box",
                        HTML("<strong>💡 Key Value:</strong> Alternative data can provide early signals about company performance before it appears in official financial reports.")
                    )
                ),
                box(title = "Market Growth", status = "primary", solidHeader = TRUE, width = 6,
                    div(class = "framework-card",
                        tags$h5("Industry Trends"),
                        tags$ul(
                          tags$li("2016: ~$200M annual spend"),
                          tags$li("2020: ~$1.7B annual spend"),
                          tags$li("2025: Projected $7B+ annual spend"),
                          tags$li("400+ specialized data vendors")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Adoption by Fund Type"),
                        tags$ul(
                          tags$li(tags$strong("Hedge Funds:"), " 75% use alt data (2023)"),
                          tags$li(tags$strong("Quant Funds:"), " 90%+ integration"),
                          tags$li(tags$strong("Long-Only:"), " Growing adoption")
                        )
                    )
                )
              ),
              fluidRow(
                box(title = "Five Categories of Alternative Data", status = "success", solidHeader = TRUE, width = 12,
                    div(class = "framework-card",
                        tags$h5("1. Individual-Generated Data"),
                        tags$p("Data created by individuals through online and mobile activity."),
                        tags$ul(
                          tags$li(tags$strong("Social Media:"), " Twitter sentiment, Reddit discussion volume"),
                          tags$li(tags$strong("Product Reviews:"), " Amazon reviews, app store ratings"),
                          tags$li(tags$strong("Search Trends:"), " Google Trends for brand interest")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("2. Business Process Data"),
                        tags$p("Data generated as byproduct of company operations."),
                        tags$ul(
                          tags$li(tags$strong("Credit Card Transactions:"), " Anonymized spending patterns"),
                          tags$li(tags$strong("Email Receipts:"), " Purchase confirmations"),
                          tags$li(tags$strong("Web Traffic:"), " Site visits, time on page")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("3. Sensor Data"),
                        tags$p("Automated data collection from physical devices."),
                        tags$ul(
                          tags$li(tags$strong("IoT Devices:"), " Supply chain tracking, inventory monitoring"),
                          tags$li(tags$strong("Weather Sensors:"), " Temperature, precipitation impact"),
                          tags$li(tags$strong("Mobile Location:"), " Foot traffic patterns")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("4. Satellite & Geospatial"),
                        tags$p("Imagery and location data from space and mapping services."),
                        tags$ul(
                          tags$li(tags$strong("Parking Lots:"), " Retail foot traffic estimation"),
                          tags$li(tags$strong("Oil Storage:"), " Crude inventory levels"),
                          tags$li(tags$strong("Agriculture:"), " Crop yields, farmland area")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("5. Public Data Aggregation"),
                        tags$p("Organized collection of publicly available information."),
                        tags$ul(
                          tags$li(tags$strong("Job Postings:"), " Hiring trends → company growth"),
                          tags$li(tags$strong("Patents:"), " Innovation activity"),
                          tags$li(tags$strong("Regulatory Filings:"), " SEC, FDA submissions")
                        )
                    )
                )
              )
            ),

            tabPanel(title = "📊 Evaluation Criteria",
              fluidRow(
                box(title = "Assessing Alternative Data Quality", status = "warning", solidHeader = TRUE, width = 12,
                    tags$table(class = "algo-table",
                      tags$thead(tags$tr(
                        tags$th("Criterion"), 
                        tags$th("Key Questions"), 
                        tags$th("Red Flags")
                      )),
                      tags$tbody(
                        tags$tr(
                          tags$td(tags$strong("Legal & Compliance")),
                          tags$td("Is data collection legal? Privacy compliant?"),
                          tags$td("Unclear sourcing, PII exposure, Terms of Service violations")
                        ),
                        tags$tr(
                          tags$td(tags$strong("Exclusivity")),
                          tags$td("How many others have access? First-mover advantage?"),
                          tags$td("Widely available, no differentiation")
                        ),
                        tags$tr(
                          tags$td(tags$strong("History")),
                          tags$td("How much historical data? Consistent over time?"),
                          tags$td("< 2 years history, frequent gaps or changes")
                        ),
                        tags$tr(
                          tags$td(tags$strong("Frequency")),
                          tags$td("Update cadence? Latency to actionable signal?"),
                          tags$td("Stale updates, high latency")
                        ),
                        tags$tr(
                          tags$td(tags$strong("Coverage")),
                          tags$td("Breadth of assets/sectors covered? Geographic scope?"),
                          tags$td("Narrow coverage, limited to few stocks")
                        ),
                        tags$tr(
                          tags$td(tags$strong("Actionability")),
                          tags$td("Clear link to fundamentals or prices? Tradeable alpha?"),
                          tags$td("Weak correlation, unclear economic mechanism")
                        )
                      )
                    ),
                    div(class = "success-box",
                        HTML("<strong>✅ Best Practice:</strong> Always conduct rigorous backtesting and out-of-sample validation before allocating capital to alternative data signals.")
                    )
                )
              )
            ),

            tabPanel(title = "🔧 Data Sources & Techniques",
              fluidRow(
                box(title = "Web Scraping Approaches", status = "info", solidHeader = TRUE, width = 6,
                    div(class = "framework-card",
                        tags$h5("Static HTML Scraping"),
                        tags$p("Parsing simple HTML pages with BeautifulSoup or lxml."),
                        tags$ul(
                          tags$li("Best for: Static content, simple structures"),
                          tags$li("Tools: BeautifulSoup, lxml, requests"),
                          tags$li("Limits: Cannot handle JavaScript-rendered content")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Dynamic Content (Selenium)"),
                        tags$p("Browser automation for JavaScript-heavy sites."),
                        tags$ul(
                          tags$li("Best for: Single-page apps, dynamic loading"),
                          tags$li("Tools: Selenium, Playwright, Puppeteer"),
                          tags$li("Trade-off: Slower but handles complex sites")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("API-Based Collection"),
                        tags$p("Official or unofficial APIs for structured data."),
                        tags$ul(
                          tags$li("Best for: Rate-limited, structured access"),
                          tags$li("Examples: Twitter API, Reddit API, Google Trends"),
                          tags$li("Advantage: Clean data, less fragile than scraping")
                        )
                    )
                ),
                box(title = "Practical Use Cases", status = "success", solidHeader = TRUE, width = 6,
                    div(class = "framework-card",
                        tags$h5("Restaurant Reservations → Retail Sales"),
                        tags$p("OpenTable reservation volume predicts restaurant chain earnings."),
                        tags$ul(
                          tags$li("Scrape reservation counts by location"),
                          tags$li("Aggregate to chain level"),
                          tags$li("Lead indicator for quarterly revenue")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Earnings Call Transcripts → Sentiment"),
                        tags$p("Management tone predicts future stock performance."),
                        tags$ul(
                          tags$li("Download transcripts (SEC filings or vendors)"),
                          tags$li("NLP sentiment analysis"),
                          tags$li("Negative tone → short signal")
                        )
                    ),
                    div(class = "framework-card",
                        tags$h5("Job Postings → Company Growth"),
                        tags$p("Hiring trends signal expansion or contraction."),
                        tags$ul(
                          tags$li("Scrape LinkedIn, Indeed, Glassdoor"),
                          tags$li("Track new job postings by company"),
                          tags$li("Spike in tech roles → growth signal")
                        )
                    )
                )
              ),
              fluidRow(
                box(title = "Legal & Ethical Considerations", status = "danger", solidHeader = TRUE, width = 12,
                    div(class = "tip-box",
                        HTML("<strong>⚠️ Critical:</strong> Always review website Terms of Service. Aggressive scraping can violate TOS, CFAA (Computer Fraud and Abuse Act), or GDPR/privacy laws.")
                    ),
                    div(class = "info-box-plain",
                        HTML("<strong>Best Practices:</strong> (1) Use official APIs when available, (2) Respect robots.txt, (3) Rate-limit requests, (4) Avoid scraping personal data, (5) Consult legal counsel.")
                    )
                )
              )
            )
          )
        ),

        tabPanel(title = tagList(icon("code"), " Code Lab"),
          code_lab_header("Chapter 3 Code Examples", 
                         "Web scraping and sentiment analysis techniques for alternative data."),
          file_pills_ui(ns, CH03_FILES),
          py_code_display(ns),
          terminal_ui(ns)
        )
      )
    )
  )
}

chapter3_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    code_lab_server(input, output, session, CH03_FILES)
  })
}
