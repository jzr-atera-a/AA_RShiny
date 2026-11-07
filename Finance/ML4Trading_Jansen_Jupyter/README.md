# Machine Learning for Algorithmic Trading - Interactive Learning Platform

An interactive R Shiny application based on **"Machine Learning for Algorithmic Trading (Second Edition)"** by Stefan Jansen.

## 📁 Project Structure

```
MLTradingApp/
├── app.R                      # Main application file
├── global.R                   # Shared utilities and helper functions
├── README.md                  # This file
├── modules/                   # Chapter modules
│   ├── chapter01.R           # Chapter 1: ML for Trading
│   ├── chapter02.R           # Chapter 2: Market Data
│   └── chapter03.R           # Chapter 3: Alternative Data
├── www/                       # Static web assets
│   └── css/
│       └── global.css        # Application styling
├── templates/                 # Templates for creating new chapters
│   └── chapter_template.R    # Template for new chapter modules
└── docs/                      # Additional documentation
```

## 🚀 Quick Start

### 1. Install Dependencies

```r
# Required packages
install.packages(c(
  "shiny",
  "shinydashboard",
  "plotly",
  "DT",
  "dplyr",
  "ggplot2"
))
```

### 2. Run the Application

```r
# Navigate to app directory
setwd("path/to/MLTradingApp")

# Run the app
shiny::runApp()
```

Or in RStudio: Open `app.R` and click "Run App"

## 📖 Current Content

### Part 1: From Data to Strategy

✅ **Chapter 1: Machine Learning for Trading**
- ML industry landscape and evolution
- Strategy development workflow
- Use cases and applications
- Visualizations: Workflow diagram, strategy evolution

✅ **Chapter 2: Market and Fundamental Data**
- Market microstructure fundamentals
- High-frequency data processing
- Bar types (tick, time, volume, dollar)
- Data storage strategies
- Visualizations: Bar comparison, storage formats

✅ **Chapter 3: Alternative Data for Finance**
- Data source categories
- Evaluation criteria
- Market landscape
- Web scraping techniques
- Visualizations: Market growth, use case analysis

## 🎨 Features

- **Professional dark theme** with teal/turquoise color scheme
- **Interactive Plotly visualizations** in every chapter
- **Modular architecture** for easy extension
- **Comprehensive theory coverage** based on the book
- **Python code placeholders** for future integration
- **Responsive design** for different screen sizes

## 🔧 Adding New Chapters

1. **Copy the template**:
   ```bash
   cp templates/chapter_template.R modules/chapter04.R
   ```

2. **Customize the chapter**:
   - Update chapter number, title, subtitle
   - Add your content to the Theory tab
   - Create visualizations in the server function

3. **Update app.R** (add 3 lines):
   ```r
   # In sidebarMenu:
   menuItem("Ch 4 · Your Title", tabName = "ch4", icon = icon("icon-name"))
   
   # In tabItems:
   tabItem(tabName = "ch4", chapter4_ui("ch4"))
   
   # In server:
   chapter4_server("ch4")
   ```

That's it! The module will auto-load.

## 📊 Visualization Guide

All chapters use Plotly for interactive charts. See `templates/chapter_template.R` for examples of:
- Line charts
- Bar charts
- Scatter plots
- And more

Colors are pre-configured using the `ml_colors` palette from `global.R`.

## 🎯 Helper Functions

Available from `global.R`:

- `chapter_hero()` - Chapter header banner
- `stats_row()` - Statistics cards
- `framework_card()` - Content cards
- `tip_box()` - Highlighted tips
- `info_box()` - Information blocks
- `python_code_tab()` - Python placeholder
- `generate_palette()` - Color palettes

## 📚 Book Information

**Title**: Machine Learning for Algorithmic Trading (Second Edition)  
**Author**: Stefan Jansen  
**Publisher**: Packt Publishing  
**Release**: July 2020  
**Pages**: 600+  
**Total Chapters**: 25

## 🛠️ Troubleshooting

### App won't start
- Verify all required packages are installed
- Check that you're in the correct directory
- Ensure R version >= 4.0

### Modules not loading
- Check that module files are in `modules/` folder
- Verify file names match pattern `chapter##.R`
- Ensure functions are named correctly (`chapterN_ui`, `chapterN_server`)

### Visualizations not showing
- Update plotly: `install.packages("plotly")`
- Clear browser cache
- Check browser console for errors

## 📝 License

This educational tool is created for learning purposes based on Stefan Jansen's book.

## 🤝 Contributing

To extend this app:
1. Follow the existing modular pattern
2. Use the provided template
3. Maintain consistent styling
4. Test thoroughly

---

**Current Version**: 1.0  
**Chapters Implemented**: 3 of 25 (12%)  
**Last Updated**: March 2026
