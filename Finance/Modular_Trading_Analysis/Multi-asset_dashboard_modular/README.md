# Multi-Asset Analysis Dashboard - Modular Architecture

A professional financial analysis dashboard for cryptocurrencies, private equity, and commodities with real-time data fetching and advanced analytics.

## Features

### Core Capabilities
- **Real-time Data**: Fetches live data from Yahoo Finance using quantmod
- **Multi-Asset Support**: Cryptocurrencies, Private Equity stocks, Commodities
- **8 Analysis Modules**: Market Overview, Price Analysis, Technical Indicators, Volatility, Risk Metrics, Advanced Metrics, Hedging, Composite Analysis
- **Modular Architecture**: Enable/disable any module with one line change
- **Professional UI**: Corporate teal/cyan theme with gradients and animations

### Asset Classes

**Cryptocurrencies**
- Bitcoin (BTC-USD)
- Ethereum (ETH-USD)
- Cardano (ADA-USD)

**Private Equity**
- NVIDIA (NVDA)
- Microsoft (MSFT)
- Apple (AAPL)

**Commodities**
- Gold (GC=F)
- Crude Oil (CL=F)
- Natural Gas (NG=F)

## Quick Start

### Installation

```r
# Install required packages
install.packages(c(
  "shiny", "shinydashboard", "plotly", "DT", 
  "dplyr", "lubridate", "quantmod", "TTR", 
  "tidyr", "zoo", "corrplot", "shinycssloaders",
  "R6", "yaml", "purrr"
))
```

### Running the App

```r
# Navigate to app directory
setwd("path/to/asset_dashboard_modular")

# Run the application
shiny::runApp()
```

## Architecture

### Directory Structure

```
asset_dashboard_modular/
├── app.R                      # Entry point (15 lines)
├── global.R                   # Global configuration
├── R/
│   ├── module_loader.R        # R6 module management
│   ├── utils_common.R         # Shared utilities
│   └── utils_data.R           # Data fetching & management
├── modules/
│   ├── _module_registry.yml   # CONTROL CENTER
│   ├── market_overview/
│   │   ├── manifest.yml
│   │   ├── ui.R
│   │   ├── server.R
│   │   └── README.md
│   ├── price_analysis/
│   ├── technical_indicators/
│   ├── volatility_analysis/
│   ├── risk_metrics/
│   ├── advanced_metrics/
│   ├── hedging_strategies/
│   └── composite_analysis/
└── www/
    └── css/
        └── global.css         # All styling

```

### Key Principles

1. **Zero Namespace Conflicts**: Proper use of `NS()` and `moduleServer()`
2. **Clean Separation**: Each module is completely independent
3. **Reactive State**: DataManager with reactive triggers for cross-module communication
4. **No Inline CSS**: All styling in global.css
5. **Enable/Disable**: Control modules via registry with zero overhead when disabled

## Module System

### Enabling/Disabling Modules

Edit `modules/_module_registry.yml`:

```yaml
modules:
  market_overview:
    enabled: true      # ← Change to false to disable
    priority: 1
    description: "Market overview with price and volume"
```

When `enabled: false`:
- Module files NOT sourced
- NOT in sidebar menu
- NOT in dashboard tabs
- ZERO performance overhead

### Adding a New Module

1. **Create directory structure:**
```bash
mkdir -p modules/my_module
```

2. **Create manifest.yml** (see any existing module)

3. **Create ui.R** with `my_module_ui()` function

4. **Create server.R** with `my_module_server()` function

5. **Register in `_module_registry.yml`**

6. **Restart app**

## Data Management

### DataManager Class

The `DataManager` R6 class handles all data operations:

```r
# Reactive state
data_manager$state_trigger()  # Watch for changes
data_manager$get_data()       # Get current asset data
data_manager$get_summary()    # Get data summary

# Operations
data_manager$set_current_asset(symbol, asset_class)
data_manager$trigger_refresh()
data_manager$fetch_hedge_data(symbol)
data_manager$fetch_composite_data(symbols, start, end)
```

### Module Pattern

```r
# In module server
observe({
  data_manager$state_trigger()  # Makes observer reactive
  
  data <- data_manager$get_data()
  if (is.null(data)) return()
  
  # Use data...
})
```

## Analysis Features

### 1. Market Overview
- Real-time price and volume charts
- Moving averages (5-200 days)
- Market statistics
- Returns and price distributions

### 2. Price Analysis
- OHLC candlestick charts
- High/Low/Open/Close analysis
- Bollinger Bands
- Cumulative returns

### 3. Technical Indicators
- Simple Moving Average (SMA)
- Exponential Moving Average (EMA)
- Relative Strength Index (RSI)
- MACD
- Bollinger Bands
- Stochastic Oscillator

### 4. Volatility Analysis
- Realized volatility
- Parkinson (High-Low)
- Garman-Klass (OHLC)
- Volatility clustering
- Regime analysis

### 5. Risk Metrics
- Value at Risk (VaR)
- Expected Shortfall (ES)
- Drawdown analysis
- Stress testing scenarios

### 6. Advanced Metrics
- Sharpe Ratio
- Sortino Ratio
- Calmar Ratio
- Omega Ratio
- Upside/Downside capture
- Recovery period analysis

### 7. Hedging Strategies
- Static hedge
- Dynamic (correlation-based)
- Beta-adjusted
- Minimum variance
- Hedge effectiveness metrics
- Cost-benefit analysis

### 8. Composite Analysis
- Multi-asset comparison
- Correlation heatmaps
- Risk-return scatter plots
- Rolling correlations
- Asset class summaries

## Configuration

### Global Settings

In `modules/_module_registry.yml`:

```yaml
settings:
  auto_install: false       # Don't auto-install packages
  check_versions: true
  verbose: true             # Show loading messages
  dev_mode: false

app:
  name: "Multi-Asset Analysis Dashboard"
  version: "1.0.0"
```

### Asset Configuration

Asset selection is global - changes in the sidebar affect all modules automatically through the DataManager's reactive state system.

## Performance

- **Disabled modules** = Zero overhead (not loaded)
- **Reactive triggers** = Minimal performance impact
- **Conditional rendering** = Only active tab rendered
- **Efficient data fetching** = Cached until refresh

## Customization

### Styling

All CSS is in `www/css/global.css`:
- Corporate teal/cyan theme
- Gradient backgrounds
- Modern shadows and hover effects
- Status boxes (success, error, info, warning)
- Value boxes with color coding

### Adding Assets

Edit `global.R` to add new assets to the dropdown menus.

### Changing Themes

Modify color variables in `global.css`:
- Primary: `#008A82` (teal)
- Secondary: `#00A39A` (cyan)
- Background: Gradient from `#002C3C` to `#00A39A`

## Deployment

### Local Development
```r
shiny::runApp()
```

### Shiny Server
```bash
cp -r asset_dashboard_modular /srv/shiny-server/
sudo systemctl restart shiny-server
```

### shinyapps.io
```r
library(rsconnect)
deployApp()
```

## Troubleshooting

### Module Not Appearing
1. Check `enabled: true` in `_module_registry.yml`
2. Verify ui.R and server.R exist
3. Check function names match: `{module_id}_ui` and `{module_id}_server`
4. Restart the app

### Data Not Loading
1. Check internet connection (Yahoo Finance access)
2. Verify asset symbol is correct
3. Check date range (some assets have limited history)
4. Look for error messages in R console

### Performance Issues
1. Disable unused modules in registry
2. Reduce MA periods in technical indicators
3. Limit date ranges in analysis
4. Use fewer assets in composite analysis

## Support

For issues, questions, or contributions:
1. Check the module README files
2. Review ARCHITECTURE.md for detailed technical docs
3. See individual module documentation

## License

This project is provided as-is for educational and analytical purposes.

## Credits

- Built with Shiny, shinydashboard, and plotly
- Data from Yahoo Finance via quantmod
- Modular architecture inspired by modern software design patterns

---

**Version 1.0.0** | Multi-Asset Analysis Dashboard | Modular Architecture
