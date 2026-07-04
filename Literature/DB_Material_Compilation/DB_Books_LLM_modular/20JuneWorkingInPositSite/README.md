# Book Summary Complete Suite v3.0 - Modular Architecture

A production-ready R Shiny application for AI-powered book summary generation with cloud database storage and rich data visualization.

## 🌟 Features

- **AI Summary Generation**: Claude AI (Sonnet 4.5) for automatic structured book summaries
- **Cloud Database**: BigQuery integration for scalable data storage
- **Mathematical Formulas**: LaTeX/MathJax rendering for technical content
- **Reference Resources**: URL integration with descriptions
- **Rich Visualizations**: Interactive dashboards with Plotly charts
- **Modular Architecture**: Enable/disable features by changing ONE line

## 📁 Project Structure

```
BookSummaryApp/
├── app.R                          # Entry point (15 lines)
├── global.R                       # Configuration & UI/server factories
├── R/
│   ├── module_loader.R            # R6 ModuleLoader class
│   ├── utils_api.R                # R6 APIManager class
│   └── utils_common.R             # Shared utilities
├── modules/
│   ├── _module_registry.yml       # CONTROL CENTER - enable/disable HERE
│   ├── bigquery_auth/             # BigQuery authentication
│   ├── claude_api_config/         # Claude API configuration
│   ├── generate_summary/          # AI summary generation
│   ├── bulk_import/               # Bulk data upload
│   ├── add_single/                # Single entry addition
│   ├── browse_data/               # Data browsing
│   ├── visualizations/            # Rich visualizations
│   └── about/                     # Application info
├── www/
│   └── css/
│       └── global.css             # ALL CSS centralized here
└── README.md                      # This file
```

## 🚀 Quick Start

### Prerequisites

Install required R packages:

```r
install.packages(c(
  "shiny", "shinydashboard", "R6", "yaml", "purrr",
  "httr", "jsonlite", "bigrquery", "DT", "plotly",
  "dplyr", "stringr", "tidyr", "shinyjs"
))
```

### Running the App

```r
# Navigate to app directory
setwd("BookSummaryApp")

# Run the app
shiny::runApp()
```

Or use RStudio: Open `app.R` and click "Run App"

## 🔧 Configuration

### BigQuery Setup

1. Click "BigQuery Setup" in the sidebar
2. Enter your GCP project details (defaults provided)
3. Upload service account JSON or paste JSON content
4. Click "Connect to BigQuery"

**Default Configuration:**
- Project: `atera-2`
- Dataset: `Wonderfulp_March`
- Table: `book_summaries_test3`

### Claude API Setup

1. Click "Claude API Config" in the sidebar
2. Enter your Anthropic API key
3. Select model (Claude Sonnet 4.5 recommended)
4. Click "Save Credentials"

## 📊 Data Schema

Table: `atera-2.Wonderfulp_March.book_summaries_test3`

| Field | Type | Description |
|-------|------|-------------|
| id | INTEGER | Auto-generated unique ID |
| created_at | TIMESTAMP | Creation timestamp |
| book_name | STRING | Book title |
| author | STRING | Author name |
| genre | STRING | Book category |
| topic | STRING | Book subject |
| chapter | STRING | Chapter identifier |
| section | STRING | Section identifier |
| main_details | STRING | Summary content |
| formula | STRING | LaTeX mathematical expression |
| formula_explanation | STRING | Formula explanation |
| reference_url | STRING | Resource URL |
| reference_description | STRING | URL description |
| numeric_data | STRING | Comma-separated metrics |
| numeric_data_description | STRING | Metrics explanation |

## 🎛️ Enable/Disable Modules

To enable or disable any module, edit `modules/_module_registry.yml`:

```yaml
modules:
  visualizations:
    enabled: false  # ← Change this line to disable
    priority: 14
    description: "Rich data visualizations"
```

**When `enabled: false`:**
- ✅ Module NOT loaded (zero performance overhead)
- ✅ NOT in sidebar menu
- ✅ NOT in dashboard
- ✅ Packages NOT loaded
- ✅ Acts as if module doesn't exist

## 📝 Usage Workflow

1. **Setup APIs**: Configure BigQuery and Claude API credentials
2. **Generate Summary**: Use AI to create structured book summaries
3. **Import Data**: Upload summaries to BigQuery
4. **Visualize**: View interactive charts and formulas
5. **Browse**: Search and download data

## 🏗️ Adding New Modules

1. Create module directory: `modules/my_module/`
2. Add required files:
   - `manifest.yml` - Module metadata
   - `ui.R` - Namespaced UI function
   - `server.R` - moduleServer function
   - `README.md` - Documentation
3. Register in `modules/_module_registry.yml`

See `ARCHITECTURE.md` for detailed module creation guide.

## 🎨 Theme

Corporate teal/cyan gradient theme with:
- Modern card-based layout
- Hover effects
- Status indicators (success, error, info, warning)
- Formula rendering with MathJax
- Responsive design

## 📦 Dependencies

### Core Packages
- shiny
- shinydashboard
- R6
- yaml
- purrr

### Feature Packages
- httr, jsonlite (API)
- bigrquery (Database)
- DT (Tables)
- plotly (Charts)
- dplyr, stringr, tidyr (Data)
- shinyjs (UI)

## 🔒 Security

- API keys stored in memory only (not persisted)
- SQL injection prevention (all queries use parameterization)
- BigQuery authentication via service account JSON
- No sensitive data in version control

## 📚 Documentation

- `ARCHITECTURE.md` - Detailed architecture overview
- `modules/*/README.md` - Module-specific documentation
- Inline code comments throughout

## 🐛 Troubleshooting

### Module Not Appearing
1. Check `_module_registry.yml` - is `enabled: true`?
2. Check `manifest.yml` - is module ID correct?
3. Check console for errors during loading

### BigQuery Connection Failed
1. Verify service account has BigQuery permissions
2. Check JSON format (must include: type, project_id, private_key, client_email)
3. Verify table exists or app will create it

### Claude API Errors
1. Verify API key is valid
2. Check token limits (16,000 default)
3. Monitor rate limits

## 📄 License

This project is provided as-is for educational and commercial use.

## 👥 Authors

Book Summary Suite Team

## 📧 Support

For issues or questions:
1. Check `ARCHITECTURE.md` for detailed patterns
2. Review module READMEs
3. Check module-specific documentation

## 🎯 Version

**v3.0.0** - Modular Architecture  
Enhanced schema with formulas, references, and modular design

---

**Built with ❤️ using R Shiny and Modern Modular Architecture**
