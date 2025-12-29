# FX Analysis Dashboard

Modular R Shiny application for FX market analysis with MySQL integration.

Built using the EXACT working pattern from db_books_llm_modular_v2.

## Quick Start

```r
# Install packages
install.packages(c("shiny", "shinydashboard", "R6", "yaml", "purrr", 
                   "shinycssloaders", "plotly", "DT", "dplyr", "lubridate",
                   "DBI", "RMySQL", "tidyr", "TTR", "zoo"))

# Run app
shiny::runApp()
```

## Features

- Modular architecture (based on proven working pattern)
- Enable/disable modules via registry
- MySQL database connectivity
- Professional teal/cyan theme

## Database Setup

1. Go to "Database Connection" tab
2. Configure credentials
3. Test connection
4. Load data
5. Navigate to other tabs

## Enable/Disable Modules

Edit `modules/_module_registry.yml`:

```yaml
modules:
  market_overview:
    enabled: false  # Disable module
```

Version: 2.0.0
