# Machine Learning for Algorithmic Trading - Interactive Learning Platform

An interactive R Shiny application for learning Machine Learning for Algorithmic Trading based on Stefan Jansen's book "Machine Learning for Algorithmic Trading" (2nd Edition, Packt Publishing).

## Overview

This application provides an interactive learning experience for the first five chapters of the book, covering Part I: From Idea to Execution. Each chapter includes:

- **Concepts Tab**: Comprehensive theory with diagrams, tables, and visual explanations
- **Code Lab Tab**: Executable Python code examples with terminal output

## Structure

```
ML4TradingApp/
├── app.R                 # Main Shiny application
├── global.R              # Global functions and helpers
├── www/
│   └── css/
│       └── global.css    # Dark Scholar theme styling
└── modules/
    ├── overview.R        # Book overview and navigation
    ├── chapter01.R       # ML for Trading: From Idea to Execution
    ├── chapter02.R       # Market and Fundamental Data
    ├── chapter03.R       # Alternative Data for Finance
    ├── chapter04.R       # Financial Feature Engineering
    └── chapter05.R       # Portfolio Optimization and Performance
```

## Chapters Included

### Part I: From Idea to Execution

1. **Chapter 1: Machine Learning for Trading**
   - Rise of ML in investment industry
   - ML-driven strategy design workflow
   - Use cases and applications

2. **Chapter 2: Market and Fundamental Data**
   - Market microstructure and order books
   - Tick-to-bar conversion (time, volume, dollar bars)
   - XBRL automated processing

3. **Chapter 3: Alternative Data for Finance**
   - Alternative data revolution and categories
   - Evaluation criteria for data sources
   - Web scraping techniques (BeautifulSoup, Selenium)

4. **Chapter 4: Financial Feature Engineering**
   - Alpha factors (momentum, value, volatility, size, quality)
   - Technical indicators with TA-Lib
   - Factor validation with Alphalens

5. **Chapter 5: Portfolio Optimization and Performance**
   - Performance metrics (Sharpe, Information Ratio)
   - Mean-variance optimization
   - Kelly criterion and risk parity

## Installation

### Prerequisites

- R (≥ 4.0.0)
- Python 3 (for code execution)

### Required R Packages

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "shinyAce",
  "reticulate"
))
```

### Python Setup (Optional)

For executing code examples in the Code Lab:

```bash
pip install pandas numpy
```

## Running the Application

```r
# Navigate to the app directory
setwd("path/to/ML4TradingApp")

# Run the app
shiny::runApp()
```

The application will open in your default web browser.

## Features

### Dark Scholar Theme
- Professional dark theme optimized for reading and coding
- Gold accent colors for emphasis
- Syntax highlighting for Python code

### Interactive Code Lab
- Execute Python code directly in the browser
- View output in terminal-style display
- Copy code to clipboard
- Multiple code examples per chapter

### Modular Architecture
- Each chapter is a self-contained module
- Easy to extend with additional chapters
- Consistent structure across all chapters

## Customization

### Adding New Chapters

1. Create a new file in `modules/` (e.g., `chapter06.R`)
2. Follow the existing chapter structure:
   ```r
   CH06_FILES <- list(...)  # Python code examples
   chapter6_ui <- function(id) { ... }
   chapter6_server <- function(id) { ... }
   ```
3. Add the chapter to `app.R`:
   ```r
   menuSubItem("Ch 6 · Title", tabName = "ch6", ...)
   tabItem(tabName = "ch6", chapter6_ui("ch6"))
   chapter6_server("ch6")
   ```

### Styling

Edit `www/css/global.css` to modify:
- Color scheme (CSS variables at top of file)
- Typography (fonts, sizes)
- Layout and spacing

## Technologies Used

- **R Shiny**: Web application framework
- **shinydashboard**: Dashboard layout
- **reticulate**: Python integration
- **highlight.js**: Code syntax highlighting

## Credits

- **Book**: "Machine Learning for Algorithmic Trading" by Stefan Jansen (Packt Publishing, 2nd Edition)
- **Design**: Inspired by modern development tools and documentation sites
- **Theme**: Dark Scholar with gold accents

## License

This educational tool is created for learning purposes. All content is based on Stefan Jansen's book "Machine Learning for Algorithmic Trading."

## Future Development

Planned additions:
- Chapters 6-23 (Parts II-VI)
- More interactive visualizations
- Enhanced code examples with real market data
- Quiz questions and exercises
- Progress tracking

## Support

For issues or questions:
- Check the book for detailed explanations
- Review the Python code examples
- Consult the official book repository

---

**Note**: This is an educational tool designed to complement the book. For comprehensive coverage, please refer to the original text by Stefan Jansen.
