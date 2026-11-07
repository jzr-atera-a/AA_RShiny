# Quick Start Guide

## ⚡ Fastest Way to Run

```r
# 1. Install dependencies (first time only)
source("setup.R")

# 2. Run the app
shiny::runApp()
```

## 📁 What's Where

```
MLTradingApp/
├── app.R              ← Main app (start here)
├── global.R           ← Helper functions
├── setup.R            ← Dependency installer
│
├── modules/           ← Chapter modules
│   ├── chapter01.R
│   ├── chapter02.R
│   └── chapter03.R
│
├── www/css/           ← Styling
│   └── global.css
│
└── templates/         ← Templates for new chapters
    └── chapter_template.R
```

## 🔧 Adding a New Chapter (3 Steps)

### Step 1: Create Module File
```bash
cp templates/chapter_template.R modules/chapter04.R
```

### Step 2: Customize Content
Edit `modules/chapter04.R`:
- Change chapter number from 4 to your chapter
- Update title, subtitle, badges
- Add your content

### Step 3: Register in app.R
Add 3 lines to `app.R`:

```r
# In sidebarMenu (~line 30):
menuItem("Ch 4 · Your Title", tabName = "ch4", icon = icon("lightbulb"))

# In tabItems (~line 120):
tabItem(tabName = "ch4", chapter4_ui("ch4"))

# In server (~line 140):
chapter4_server("ch4")
```

Done! Refresh and your chapter appears.

## 🎨 Available Components

### Hero Banner
```r
chapter_hero(num, icon, title, subtitle, badges)
```

### Stats Row
```r
stats_row(
  list("100+", "Data Sources"),
  list("5", "Categories"),
  list("$1B", "Market Size"),
  list("10x", "Growth")
)
```

### Content Cards
```r
framework_card("Title", "Content here")
tip_box("Key Point", "Explanation")
info_box("<strong>Note:</strong> Details")
```

### Tables
```r
tags$table(class = "algo-table",
  tags$thead(tags$tr(tags$th("Col1"), tags$th("Col2"))),
  tags$tbody(
    tags$tr(tags$td("Data1"), tags$td("Data2"))
  )
)
```

### Charts
```r
output$my_chart <- renderPlotly({
  plot_ly(data, x = ~x, y = ~y) %>%
    layout(
      plot_bgcolor = 'rgba(0,0,0,0)',
      paper_bgcolor = 'rgba(0,0,0,0)'
    )
})
```

## 🎨 Color Palette

From `ml_colors` in `global.R`:
- `primary`: #008A82 (Teal)
- `secondary`: #00A39A (Turquoise)
- `accent1`: #FF6B35 (Orange)
- `accent2`: #F7931E (Gold)
- `dark`: #002C3C (Navy)

Or use: `generate_palette(n)` for n colors

## 📊 Current Chapters

✅ Chapter 1: ML for Trading - From Idea to Execution  
✅ Chapter 2: Market and Fundamental Data  
✅ Chapter 3: Alternative Data for Finance  
⬜ Chapter 4-25: Use template to add more

## 🐛 Common Issues

**"Could not find function chapter1_ui"**
- Check: Is `chapter01.R` in `modules/` folder?
- Check: Does filename match pattern `chapter##.R`?
- Fix: Restart R session

**Plots not showing**
- Update plotly: `install.packages("plotly")`
- Clear browser cache (Ctrl+Shift+R)

**CSS not loading**
- Check: `www/css/global.css` exists
- Check: File path in app.R is correct
- Fix: Restart app

## 📞 Need Help?

1. Check `README.md` for detailed docs
2. Look at `templates/chapter_template.R` for examples
3. Compare your module to existing chapters

---

Ready to run? → `shiny::runApp()`
