# Quick Start Guide

Get your Multi-Asset Analysis Dashboard running in 5 minutes!

## 1. Install Packages (2 minutes)

```r
# Run this once
packages <- c(
  "shiny", "shinydashboard", "plotly", "DT", 
  "dplyr", "lubridate", "quantmod", "TTR", 
  "tidyr", "zoo", "corrplot", "shinycssloaders",
  "R6", "yaml", "purrr"
)

install.packages(packages)
```

## 2. Run the Dashboard (30 seconds)

```r
# Navigate to the folder
setwd("path/to/asset_dashboard_modular")

# Launch!
shiny::runApp()
```

## 3. Start Analyzing (Immediate)

The dashboard will open in your browser. You can now:

1. **Select an Asset Class** - Choose from the sidebar:
   - Cryptocurrencies (Bitcoin, Ethereum, Cardano)
   - Private Equity (NVIDIA, Microsoft, Apple)
   - Commodities (Gold, Oil, Natural Gas)

2. **Pick a Specific Asset** - From the second dropdown

3. **Explore 8 Analysis Modules**:
   - 📊 **Market Overview** - Real-time prices and volume
   - 📈 **Price Analysis** - OHLC charts and trends
   - 📉 **Technical Indicators** - RSI, MACD, Bollinger Bands
   - 🌊 **Volatility Analysis** - Risk metrics and clustering
   - ⚠️ **Risk Metrics** - VaR, drawdowns, stress tests
   - ⭐ **Advanced Metrics** - Sharpe, Sortino, Calmar ratios
   - 🛡️ **Hedging Strategies** - Hedge analysis
   - 🔄 **Composite Analysis** - Multi-asset comparison

## 4. Customize (Optional)

Want to enable/disable modules?

Edit `modules/_module_registry.yml`:

```yaml
modules:
  market_overview:
    enabled: true      # Keep this one
  
  advanced_metrics:
    enabled: false     # Disable this one
```

Save and restart the app!

## Tips

- **Refresh Data**: Click the "Refresh Data" button for latest prices
- **Change Assets**: Use sidebar dropdowns - all charts update automatically
- **Compare Assets**: Use Composite Analysis to compare multiple assets
- **Performance**: Disable unused modules for faster loading

## Troubleshooting

**Dashboard won't start?**
```r
# Clear workspace and retry
rm(list=ls())
shiny::runApp()
```

**No data appearing?**
- Check internet connection
- Verify asset symbol (try Bitcoin - BTC-USD first)
- Look for error messages in R console

**Module not showing?**
- Check `modules/_module_registry.yml`
- Ensure `enabled: true`
- Restart the application

## Need More Help?

- 📖 See `README.md` for complete feature list
- 🏗️ See `ARCHITECTURE.md` for technical details
- 💿 See `INSTALLATION.md` for full installation guide

## What's Next?

1. **Try all 8 modules** - Each offers unique insights
2. **Compare different assets** - See how crypto vs stocks vs commodities perform
3. **Analyze risk metrics** - Understand volatility and drawdowns
4. **Test hedging strategies** - See how to reduce portfolio risk
5. **Customize modules** - Add your own analysis features

---

**Happy Analyzing! 📈**

The dashboard fetches real-time data from Yahoo Finance and updates automatically when you change assets.
