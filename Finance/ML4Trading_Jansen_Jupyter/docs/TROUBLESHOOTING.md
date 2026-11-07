# Troubleshooting Guide

Common issues and how to fix them.

## 🔴 App Won't Start

### Error: "Could not find function 'chapter1_ui'"

**Symptoms**:
```
Error in chapter1_ui("ch1") : could not find function "chapter1_ui"
```

**Causes**:
1. Module file not in correct location
2. Module file has wrong name
3. Module not being sourced properly
4. Function name mismatch

**Solutions**:

```bash
# Check module location
ls modules/
# Should show: overview.R, chapter01.R, chapter02.R, chapter03.R

# Check file names match pattern
# Correct: chapter01.R, chapter02.R, chapter03.R
# Wrong: chapter1.R, chap01.R, ch01.R
```

If files are correct, check function names in the module:

```r
# In chapter01.R, functions must be named:
chapter1_ui <- function(id) { ... }
chapter1_server <- function(id) { ... }

# NOT chapterone_ui or chap1_ui or chapter01_ui
```

**Quick Fix**:
```r
# Restart R session
.rs.restartR()  # in RStudio

# Or manually source
source("global.R")
source("modules/chapter01.R")
```

---

### Error: "Cannot find 'global.R'"

**Symptoms**:
```
Error in source("global.R", local = TRUE) : cannot open file 'global.R'
```

**Cause**: Running app from wrong directory

**Solution**:
```r
# Check current directory
getwd()

# Should end with "/MLTradingApp"
# If not, navigate to correct folder:
setwd("path/to/MLTradingApp")

# Then run
shiny::runApp()
```

---

### Error: "Package 'plotly' not found"

**Symptoms**:
```
Error: package or namespace load failed for 'plotly'
```

**Solution**:
```r
# Run setup script
source("setup.R")

# Or install manually
install.packages(c("shiny", "shinydashboard", "plotly", "DT", "dplyr", "ggplot2"))
```

---

## 📊 Visualization Issues

### Plots Not Rendering

**Symptoms**: Empty boxes where charts should be

**Causes & Solutions**:

**1. Missing dark theme styling**
```r
# WRONG - will not show in dark theme
plot_ly(data, x = ~x, y = ~y)

# CORRECT - includes dark theme
plot_ly(data, x = ~x, y = ~y) %>%
  layout(
    plot_bgcolor = 'rgba(0,0,0,0)',
    paper_bgcolor = 'rgba(0,0,0,0)',
    font = list(color = "#E6EDF3")
  )
```

**2. Data is NULL or empty**
```r
# Add this check
output$my_chart <- renderPlotly({
  req(my_data)  # Ensures data exists
  
  # Create plot...
})
```

**3. Output ID mismatch**
```r
# UI must match server
plotlyOutput(ns("viz_main"))  # in UI

output$viz_main <- renderPlotly({ ... })  # in server
# Names must match exactly!
```

---

### Charts Display But Wrong Colors

**Symptoms**: Charts show but colors are wrong/invisible

**Solution**: Always use theme colors
```r
# Use theme colors
marker = list(color = ml_colors$primary)

# Or generate palette
colors = generate_palette(n)

# Dark theme text color
font = list(color = "#E6EDF3")

# Grid color for dark theme
gridcolor = "#30363D"
```

---

### Browser Shows Blank Page

**Symptoms**: App loads but page is completely blank

**Solutions**:

1. **Clear browser cache**: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)

2. **Check browser console** (F12):
```
Look for JavaScript errors
Common: "Uncaught ReferenceError" means JS library didn't load
```

3. **Try different browser**: Chrome, Firefox, or Edge

4. **Check CSS loaded**:
```r
# In app.R, verify this line exists:
tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css")

# Check file exists:
file.exists("www/css/global.css")  # Should return TRUE
```

---

## 🎨 Styling Issues

### Custom CSS Not Applied

**Symptoms**: Components look unstyled or default

**Checklist**:

```bash
# 1. File exists
ls www/css/global.css

# 2. File is in correct location
# Correct: www/css/global.css
# Wrong: css/global.css or www/global.css

# 3. Referenced correctly in app.R
# Look for: href = "css/global.css" (NOT "www/css/global.css")
```

**Solution**:
```r
# In app.R, dashboardBody section should have:
tags$head(
  tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css")
)

# Shiny automatically looks in www/ folder
# So path is relative: "css/global.css" not "www/css/global.css"
```

---

### Framework Cards Not Styled

**Symptoms**: Cards are plain, no border/background

**Cause**: Wrong class name

**Solution**:
```r
# CORRECT
div(class = "framework-card", ...)

# WRONG
div(class = "framework_card", ...)  # underscore instead of hyphen
div(class = "frameworkCard", ...)   # camelCase
```

---

## 🔧 Module Issues

### New Chapter Not Appearing in Sidebar

**Symptoms**: Added chapter but don't see it in menu

**Checklist**:

```r
# 1. Added to sidebarMenu?
menuItem("Ch 4 · Your Title", tabName = "ch4", icon = icon("flask"))

# 2. tabName matches in tabItem?
tabItem(tabName = "ch4", ...)  # Must match "ch4" above

# 3. Server function called?
chapter4_server("ch4")
```

**Quick Test**:
```r
# Search for your chapter number in app.R
# Should appear in 3 places:
# 1. menuItem(..., tabName = "ch4", ...)
# 2. tabItem(tabName = "ch4", ...)
# 3. chapter4_server("ch4")
```

---

### Chapter Tab Empty

**Symptoms**: Click chapter, page is blank

**Cause**: UI function not returning content

**Solution**:
```r
# UI function must wrap content in tagList()
chapter4_ui <- function(id) {
  ns <- NS(id)
  tagList(  # <-- MUST have this
    chapter_hero(...),
    fluidRow(...)
  )
}
```

---

## 💾 Data Issues

### "Object not found" in Reactive

**Symptoms**:
```
Error: object 'my_data' not found
```

**Cause**: Trying to use non-reactive data in reactive context

**Solution**:
```r
# WRONG
output$chart <- renderPlotly({
  plot_ly(my_data, ...)  # my_data doesn't exist
})

# CORRECT - create the data
output$chart <- renderPlotly({
  my_data <- data.frame(x = 1:10, y = rnorm(10))
  plot_ly(my_data, ...)
})
```

---

## 🌐 Deployment Issues

### App Works Locally But Not on Server

**Common causes**:

1. **Case-sensitive filenames**: 
   ```bash
   # Local (Windows): chapter01.R works
   # Server (Linux): Chapter01.R fails
   # Solution: Use lowercase consistently
   ```

2. **Missing packages**:
   ```r
   # Run on server
   source("setup.R")
   ```

3. **File paths wrong**:
   ```r
   # WRONG - absolute path
   source("/Users/me/app/global.R")
   
   # CORRECT - relative path
   source("global.R")
   ```

---

## 🔍 Debugging Tips

### Enable Detailed Errors

```r
# Add to top of app.R
options(shiny.error = browser)

# Now when error occurs, R will pause and let you inspect
```

---

### Check What's Loaded

```r
# In R console while app is running
ls()  # See all objects

# Check if functions exist
exists("chapter1_ui")  # Should return TRUE
exists("ml_colors")    # Should return TRUE
```

---

### Print Debugging

```r
# In server function
output$chart <- renderPlotly({
  cat("Creating chart\n")  # Prints to R console
  print(dim(my_data))      # Show data dimensions
  
  # ... your plot code
})
```

---

### Browser DevTools

```
F12 in browser → Console tab
Look for:
- Red errors (JavaScript issues)
- 404 errors (missing files)
- CORS errors (security issues)
```

---

## 📱 Performance Issues

### App is Slow

**Solutions**:

1. **Reduce data size**:
   ```r
   # Sample large datasets
   data_sample <- data[sample(nrow(data), 1000), ]
   ```

2. **Use reactive caching**:
   ```r
   # Cache expensive computations
   cached_data <- reactive({
     # Expensive operation
   }) %>% bindCache(input$parameter)
   ```

3. **Simplify plots**:
   ```r
   # Reduce number of points
   # Use webgl for large datasets
   plot_ly(..., type = "scattergl")  # Instead of "scatter"
   ```

---

## 🆘 Getting More Help

If issue persists:

1. **Check R console** for error messages
2. **Check browser console** (F12) for JavaScript errors  
3. **Restart R session**: `.rs.restartR()`
4. **Restart app**: Stop and re-run `shiny::runApp()`
5. **Compare to working chapters**: Look at chapter01.R, chapter02.R, chapter03.R
6. **Check README.md** for setup instructions

---

## 📋 Pre-Flight Checklist

Before reporting an issue, verify:

- [ ] R version >= 4.0
- [ ] All packages installed (`source("setup.R")`)
- [ ] Running from correct directory (`getwd()` shows MLTradingApp)
- [ ] Files in correct locations (modules/, www/css/)
- [ ] No typos in function names
- [ ] Browser cache cleared
- [ ] Tried in different browser

---

**Still stuck?** Check the existing chapters for working examples.
