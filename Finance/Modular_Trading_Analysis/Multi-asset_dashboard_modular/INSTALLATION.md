# Installation Guide - Multi-Asset Analysis Dashboard

## Prerequisites

- R version 4.0.0 or higher
- RStudio (recommended) or R console
- Internet connection (for data fetching from Yahoo Finance)

## Step-by-Step Installation

### 1. Install R (if not already installed)

**Windows:**
1. Download R from https://cran.r-project.org/bin/windows/base/
2. Run the installer
3. Follow the installation wizard

**macOS:**
1. Download R from https://cran.r-project.org/bin/macosx/
2. Run the .pkg installer
3. Follow the installation wizard

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install r-base r-base-dev
```

### 2. Install RStudio (Optional but Recommended)

Download from https://www.rstudio.com/products/rstudio/download/

### 3. Install Required R Packages

Open R or RStudio and run:

```r
# Core Shiny packages
install.packages(c(
  "shiny",
  "shinydashboard",
  "shinycssloaders"
))

# Data manipulation
install.packages(c(
  "dplyr",
  "tidyr",
  "lubridate"
))

# Financial data and analysis
install.packages(c(
  "quantmod",
  "TTR",
  "zoo"
))

# Visualization
install.packages(c(
  "plotly",
  "DT",
  "corrplot"
))

# Infrastructure
install.packages(c(
  "R6",
  "yaml",
  "purrr"
))
```

**Or install all at once:**

```r
packages <- c(
  "shiny", "shinydashboard", "plotly", "DT", 
  "dplyr", "lubridate", "quantmod", "TTR", 
  "tidyr", "zoo", "corrplot", "shinycssloaders",
  "R6", "yaml", "purrr"
)

install.packages(packages)
```

### 4. Download the Dashboard

Extract the `asset_dashboard_modular` folder to your desired location.

### 5. Verify Installation

Open R/RStudio and check that all packages load correctly:

```r
# Test package loading
library(shiny)
library(shinydashboard)
library(plotly)
library(quantmod)

# If all load without errors, you're ready!
```

### 6. Run the Dashboard

```r
# Set working directory to the dashboard folder
setwd("path/to/asset_dashboard_modular")

# Run the application
shiny::runApp()
```

The dashboard should open in your default web browser.

## Troubleshooting

### Package Installation Errors

**Error: package 'XXX' is not available**
- Update R to the latest version
- Try: `install.packages("XXX", repos = "https://cran.rstudio.com/")`

**Error: compilation failed**
- Install development tools:
  - **Windows**: Install Rtools from https://cran.r-project.org/bin/windows/Rtools/
  - **macOS**: Install Xcode Command Line Tools: `xcode-select --install`
  - **Linux**: `sudo apt-get install r-base-dev`

**Error: unable to load shared object**
- Restart R/RStudio
- Reinstall the problematic package: `install.packages("package_name", type = "source")`

### Data Fetching Issues

**Error: unable to connect to Yahoo Finance**
- Check internet connection
- Verify firewall settings
- Some networks block financial data APIs

**Error: no data available**
- Try a different asset symbol
- Check if the market is open
- Verify the asset exists on Yahoo Finance

### Dashboard Won't Start

**Error: cannot find function 'create_ui'**
- Verify all R files are present in the correct locations
- Check that global.R is being sourced properly
- Restart R and try again

**Error: object 'data_manager' not found**
- Ensure R/utils_data.R exists and is being sourced
- Check for syntax errors in global.R

### Module Issues

**Module not appearing in sidebar**
- Check `modules/_module_registry.yml` - ensure `enabled: true`
- Verify the module folder contains ui.R and server.R
- Check function names match: `{module_id}_ui` and `{module_id}_server`

**Module shows placeholder content**
- The module stub needs full implementation
- See the market_overview module for a complete example
- Refer to the original dashboard code for detailed implementations

## Network Configuration

### Corporate Firewalls

If behind a corporate firewall, you may need to configure R to use a proxy:

```r
# Set proxy (replace with your details)
Sys.setenv(http_proxy = "http://proxy.company.com:8080")
Sys.setenv(https_proxy = "https://proxy.company.com:8080")
```

### Yahoo Finance Access

The dashboard requires access to:
- `finance.yahoo.com`
- `query1.finance.yahoo.com`
- `query2.finance.yahoo.com`

Ensure these domains are not blocked by your network.

## System Requirements

### Minimum Requirements
- **RAM**: 4 GB
- **Storage**: 500 MB
- **Processor**: Dual-core 2.0 GHz

### Recommended Requirements
- **RAM**: 8 GB or more
- **Storage**: 1 GB
- **Processor**: Quad-core 2.5 GHz or better
- **Display**: 1920x1080 or higher

## Performance Optimization

### Disable Unused Modules

Edit `modules/_module_registry.yml`:

```yaml
modules:
  market_overview:
    enabled: true
  advanced_metrics:
    enabled: false  # Disable if not needed
```

Disabled modules have zero performance overhead.

### Adjust Data Fetch Parameters

In module code, reduce the lookback period:

```r
# Fetch less historical data (faster)
data_manager$fetch_data(months_back = 6)  # Instead of 24
```

### Limit Asset Count

In composite analysis, analyze fewer assets simultaneously.

## Updating

To update the dashboard:

1. **Backup your customizations** (if any)
2. **Download the new version**
3. **Replace files** (keeping your custom modules)
4. **Restart the application**

## Getting Help

### Documentation
- `README.md` - Overview and features
- `ARCHITECTURE.md` - Technical details
- Individual module `README.md` files

### Common Solutions

**"The app is slow"**
- Disable unused modules
- Clear R workspace: `rm(list=ls())`
- Restart R session

**"Data is outdated"**
- Click "Refresh Data" button in Market Overview
- Or restart the application

**"Chart is not displaying"**
- Check browser console for JavaScript errors
- Try a different web browser
- Ensure plotly package is up to date

## Production Deployment

### Shiny Server (Linux)

```bash
# Install Shiny Server
# See: https://www.rstudio.com/products/shiny/download-server/

# Copy app
sudo cp -r asset_dashboard_modular /srv/shiny-server/

# Set permissions
sudo chown -R shiny:shiny /srv/shiny-server/asset_dashboard_modular

# Restart server
sudo systemctl restart shiny-server
```

### shinyapps.io (Cloud)

```r
# Install deployment package
install.packages("rsconnect")

# Configure account
library(rsconnect)
rsconnect::setAccountInfo(
  name='your-account',
  token='your-token',
  secret='your-secret'
)

# Deploy
setwd("path/to/asset_dashboard_modular")
rsconnect::deployApp()
```

### Docker (Optional)

Create a `Dockerfile`:

```dockerfile
FROM rocker/shiny:latest

RUN R -e "install.packages(c('shinydashboard', 'plotly', 'DT', 'dplyr', 'quantmod', 'TTR', 'tidyr', 'zoo', 'corrplot', 'R6', 'yaml', 'purrr'))"

COPY asset_dashboard_modular /srv/shiny-server/asset_dashboard_modular

EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
```

Build and run:
```bash
docker build -t asset-dashboard .
docker run -p 3838:3838 asset-dashboard
```

## Support

For additional help:
1. Check the troubleshooting section above
2. Review module documentation
3. Consult ARCHITECTURE.md for technical details
4. Review R and Shiny documentation

## Next Steps

After installation:
1. Explore the Market Overview module
2. Try different assets (crypto, equity, commodities)
3. Customize modules in `modules/_module_registry.yml`
4. Review ARCHITECTURE.md to understand the code structure
5. Add custom analysis modules as needed

---

**Installation Complete!** You're ready to analyze financial markets with your modular dashboard.
