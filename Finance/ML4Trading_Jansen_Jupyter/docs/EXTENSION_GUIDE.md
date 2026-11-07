# Extension Guide: Adding New Chapters

This guide explains how to add new chapters to the ML Trading App following the established modular pattern.

## 📁 File Structure Overview

```
MLTradingApp/
├── app.R                    # Main app - register new chapters here
├── global.R                 # Helper functions (don't modify)
├── modules/                 # All chapter modules go here
│   ├── overview.R          # Landing page module
│   ├── chapter01.R         # Chapter 1 module
│   ├── chapter02.R         # Chapter 2 module
│   ├── chapter03.R         # Chapter 3 module
│   └── chapterXX.R         # Your new chapter
└── templates/
    └── chapter_template.R  # Copy this to create new chapters
```

## 🚀 Step-by-Step: Adding a New Chapter

### Step 1: Create the Module File

```bash
# Copy the template
cp templates/chapter_template.R modules/chapter04.R
```

### Step 2: Customize the Module

Open `modules/chapter04.R` and update:

```r
# Update these variables at the top
CHAPTER_NUM <- 4  # Your chapter number
CHAPTER_ICON <- "🎯"  # Choose an emoji
CHAPTER_TITLE <- "Financial Feature Engineering"
CHAPTER_SUBTITLE <- "How to Research Alpha Factors"
CHAPTER_BADGES <- c("Alpha Factors", "Feature Engineering", "Backtesting", "Zipline")
```

**Important**: Change the function names:
- `chapter4_ui` → use your chapter number
- `chapter4_server` → use your chapter number

### Step 3: Add Content

Fill in the Theory tab with your content:

```r
fluidRow(
  box(title = "📊 Your Section Title", 
      status = "info",  # or "warning", "success", "danger"
      solidHeader = TRUE, 
      width = 6,
      
      framework_card(
        "Subsection Title",
        "Your content here..."
      )
  )
)
```

### Step 4: Add Visualizations

In the server function:

```r
output$your_viz <- renderPlotly({
  # Create your data
  data <- data.frame(x = 1:10, y = rnorm(10))
  
  # Create plot
  plot_ly(data, x = ~x, y = ~y, type = "scatter") %>%
    layout(
      plot_bgcolor = 'rgba(0,0,0,0)',
      paper_bgcolor = 'rgba(0,0,0,0)',
      font = list(color = "#E6EDF3")
    )
})
```

### Step 5: Register in app.R

Add **3 lines** to `app.R`:

```r
# 1. In sidebarMenu (around line 30):
menuItem("Ch 4 · Financial Feature Engineering", tabName = "ch4", icon = icon("flask"))

# 2. In tabItems (around line 50):
tabItem(tabName = "ch4", chapter4_ui("ch4"))

# 3. In server function (around line 145):
chapter4_server("ch4")
```

### Step 6: Test

```r
# Restart R session
.rs.restartR()  # in RStudio

# Or just restart the app
shiny::runApp()
```

## 🎨 Content Components

### Hero Banner
Already created with your chapter variables - no code needed!

### Statistics Cards
```r
stats_row(
  list("100", "Alpha Factors"),
  list("5", "Categories"), 
  list("O(N²)", "Complexity"),
  list("50%", "Accuracy")
)
```

### Framework Cards
```r
framework_card(
  "Card Title",
  "Your content. Can include HTML, lists, paragraphs."
)

framework_card(
  "Another Card",
  tags$ul(
    tags$li("Point 1"),
    tags$li("Point 2"),
    tags$li("Point 3")
  )
)
```

### Tip Boxes
```r
tip_box("Key Insight", "Important information to highlight")
```

### Info Boxes
```r
info_box("<strong>Note:</strong> Additional context or clarification")
```

### Tables
```r
tags$table(class = "algo-table",
  tags$thead(tags$tr(
    tags$th("Column 1"), 
    tags$th("Column 2")
  )),
  tags$tbody(
    tags$tr(tags$td("Data 1"), tags$td("Data 2")),
    tags$tr(tags$td("Data 3"), tags$td("Data 4"))
  )
)
```

## 📊 Visualization Patterns

### Line Chart
```r
output$line_chart <- renderPlotly({
  plot_ly(data, x = ~date, y = ~value, type = "scatter", mode = "lines") %>%
    layout(
      title = list(text = "Title", font = list(color = "#E6EDF3")),
      xaxis = list(title = "X", color = "#8B949E", gridcolor = "#30363D"),
      yaxis = list(title = "Y", color = "#8B949E", gridcolor = "#30363D"),
      plot_bgcolor = 'rgba(0,0,0,0)',
      paper_bgcolor = 'rgba(0,0,0,0)',
      font = list(color = "#E6EDF3")
    )
})
```

### Bar Chart
```r
output$bar_chart <- renderPlotly({
  plot_ly(x = ~categories, y = ~values, type = "bar",
          marker = list(color = generate_palette(n))) %>%
    layout(
      plot_bgcolor = 'rgba(0,0,0,0)',
      paper_bgcolor = 'rgba(0,0,0,0)',
      font = list(color = "#E6EDF3")
    )
})
```

### Scatter Plot
```r
output$scatter <- renderPlotly({
  plot_ly(data, x = ~x, y = ~y, type = "scatter", mode = "markers",
          marker = list(size = 10, color = ml_colors$primary)) %>%
    layout(
      plot_bgcolor = 'rgba(0,0,0,0)',
      paper_bgcolor = 'rgba(0,0,0,0)',
      font = list(color = "#E6EDF3")
    )
})
```

## 🎨 Using Colors

### Available Colors
```r
ml_colors$primary    # #008A82 (Teal)
ml_colors$secondary  # #00A39A (Turquoise)
ml_colors$dark       # #002C3C (Navy)
ml_colors$accent1    # #FF6B35 (Orange)
ml_colors$accent2    # #F7931E (Gold)
ml_colors$success    # #28A745 (Green)
ml_colors$warning    # #FFC107 (Yellow)
ml_colors$danger     # #DC3545 (Red)
ml_colors$info       # #17A2B8 (Cyan)
```

### Generate Color Palette
```r
# For n categories
colors <- generate_palette(n)

# Use in plot
marker = list(color = generate_palette(5))
```

## 🔧 Box Status Colors

- `status = "info"` → Teal header
- `status = "warning"` → Orange header
- `status = "success"` → Turquoise header
- `status = "danger"` → Red header

## ✅ Testing Checklist

Before committing your new chapter:

- [ ] Module file is in `modules/` folder
- [ ] Function names match chapter number (`chapterN_ui`, `chapterN_server`)
- [ ] All 3 lines added to `app.R`
- [ ] App runs without errors
- [ ] Chapter appears in sidebar
- [ ] All visualizations display correctly
- [ ] Both tabs (Theory & Python Code) work
- [ ] Content is accurate and complete
- [ ] No console errors or warnings

## 🐛 Common Issues

### "Could not find function chapterN_ui"

**Cause**: Module not loading or function name mismatch

**Fix**:
1. Check file is in `modules/` folder
2. Check filename is `chapterNN.R` (two digits)
3. Verify function names match: `chapter4_ui`, `chapter4_server`
4. Restart R session

### Visualizations not rendering

**Cause**: Missing dark theme styling or data issues

**Fix**:
1. Always include:
   ```r
   plot_bgcolor = 'rgba(0,0,0,0)',
   paper_bgcolor = 'rgba(0,0,0,0)',
   font = list(color = "#E6EDF3")
   ```
2. Check data is not empty/NULL
3. Verify output ID matches in UI and server

### CSS not applying

**Cause**: CSS class names incorrect

**Fix**:
1. Use exact class names: `algo-table`, `framework-card`, `tip-box`
2. Check `www/css/global.css` exists
3. Clear browser cache (Ctrl+Shift+R)

### Module not appearing in sidebar

**Cause**: Missing menuItem in app.R

**Fix**:
1. Add to `sidebarMenu` in `app.R`
2. Verify `tabName` matches in both menuItem and tabItem
3. Check icon exists: `icon("chart-line")` etc.

## 📝 Best Practices

1. **Consistency**: Follow the existing pattern exactly
2. **Content**: Focus on book content, not your opinions
3. **Visualizations**: Use 2-3 per chapter minimum
4. **Testing**: Test each visualization individually
5. **Comments**: Add comments explaining complex code
6. **Data**: Use realistic sample data for examples
7. **Performance**: Keep datasets reasonable size (<10k rows)

## 🎯 Chapter Development Workflow

```
1. Copy template → modules/chapterNN.R
2. Update chapter metadata (number, title, etc.)
3. Write Theory tab content
4. Add 2-3 visualizations
5. Test locally
6. Update app.R (3 lines)
7. Final test
8. Commit!
```

## 📚 Resources

- **Template**: `templates/chapter_template.R`
- **Examples**: `modules/chapter01.R`, `chapter02.R`, `chapter03.R`
- **Styling**: `www/css/global.css`
- **Helpers**: `global.R`
- **Book**: "Machine Learning for Algorithmic Trading" by Stefan Jansen

---

**Questions?** Check existing chapters for examples or consult the README.md
