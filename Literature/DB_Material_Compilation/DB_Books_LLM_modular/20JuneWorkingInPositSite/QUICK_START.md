# Quick Start Guide - Book Summary Complete Suite v3.0

## 🚀 Get Started in 5 Minutes

### Step 1: Extract and Install Packages (2 minutes)

```r
# Install all required packages
install.packages(c(
  "shiny", "shinydashboard", "R6", "yaml", "purrr",
  "httr", "jsonlite", "bigrquery",
  "DT", "plotly", "shinyjs",
  "dplyr", "stringr", "tidyr"
))
```

### Step 2: Run the App (30 seconds)

```r
# Navigate to the app directory
setwd("path/to/BookSummaryApp")

# Run the app
shiny::runApp()
```

Or in RStudio: Open `app.R` → Click "Run App"

### Step 3: Configure BigQuery (1 minute)

1. Go to "BigQuery Setup" tab
2. Enter your project details:
   - Project ID: `atera-2` (or yours)
   - Dataset ID: `Wonderfulp_March` (or yours)
   - Table ID: `book_summaries_test3` (or yours)
3. Upload JSON credentials OR paste JSON content
4. Click "Connect to BigQuery"

### Step 4: Configure Claude API (1 minute)

1. Go to "Claude API Config" tab
2. Enter your Anthropic API key
3. Select "Claude Sonnet 4.5"
4. Click "Test Connection"
5. Click "Save Credentials"

### Step 5: Generate Your First Summary (30 seconds)

1. Go to "Generate Summary" tab
2. Enter:
   - Book Title: "Super Founders"
   - Author: "Ali Tamaseb"
3. Click "Generate Summary"
4. Wait 1-2 minutes for AI generation
5. Click "Parse & Upload Direct"

## ✅ You're Done!

Your Book Summary Suite is now fully operational!

## 📚 Next Steps

- **Browse Data**: View all summaries in a table
- **Visualizations**: See interactive charts and formulas
- **Bulk Import**: Upload multiple summaries at once
- **Add Single**: Manually add individual entries

## 🎛️ Customize

### Enable/Disable Features

Edit `modules/_module_registry.yml`:

```yaml
modules:
  visualizations:
    enabled: false  # ← Change to disable feature
```

### Change Theme

Edit `www/css/global.css` to customize colors and styles.

## 📖 Full Documentation

- `README.md` - Overview and features
- `INSTALLATION.md` - Detailed setup instructions
- `ARCHITECTURE.md` - Technical architecture
- `VALIDATION_CHECKLIST.md` - Testing guide

## 🆘 Need Help?

### Common Issues

**Packages won't install:**
```r
update.packages(ask = FALSE)
install.packages("package_name", dependencies = TRUE)
```

**BigQuery connection fails:**
- Verify JSON credentials are valid
- Check service account has BigQuery Admin role
- Ensure BigQuery API is enabled in GCP

**Claude API fails:**
- Verify API key starts with `sk-ant-api03-`
- Check no extra spaces in key
- Ensure key is active in Anthropic Console

**Module not showing:**
- Check `modules/_module_registry.yml`
- Ensure `enabled: true`
- Restart the app

## 🎯 Features at a Glance

- ✅ **AI Generation**: Claude Sonnet 4.5 for book summaries
- ✅ **Cloud Database**: BigQuery for scalable storage
- ✅ **Math Formulas**: LaTeX/MathJax rendering
- ✅ **References**: URL integration with descriptions
- ✅ **Visualizations**: Interactive Plotly charts
- ✅ **Modular Design**: Enable/disable any feature

## 📊 Data Schema

Your summaries are stored with these fields:
- Book metadata (title, author, genre, topic)
- Chapter and section details
- Main content
- Mathematical formulas with explanations
- Reference URLs with descriptions
- Numeric metrics with descriptions

## 🔒 Security

- API keys stored in memory only
- SQL injection prevention built-in
- No sensitive data in logs
- Secure BigQuery authentication

---

**Congratulations! You're ready to generate AI-powered book summaries! 🎉**

For detailed documentation, see:
- `INSTALLATION.md`
- `ARCHITECTURE.md`
- Module-specific README files
