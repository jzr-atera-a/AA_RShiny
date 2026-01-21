# 🚀 DEPLOYMENT GUIDE
## Greenwich AV Data Extractor

This guide covers deploying the Shiny app for team use.

---

## Local Deployment (Single User)

### Method 1: RStudio
```r
# Open app.R in RStudio
# Click "Run App" button in top-right

# OR run from console:
shiny::runApp()
```

### Method 2: R Console
```r
setwd("path/to/GreenwichAVApp")
shiny::runApp(port = 3838, host = "127.0.0.1")
```

---

## Network Deployment (Team Access)

### Option 1: Shiny Server (Open Source)

**Install Shiny Server:**
```bash
# Ubuntu/Debian
sudo apt-get install gdebi-core
wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.20.1002-amd64.deb
sudo gdebi shiny-server-1.5.20.1002-amd64.deb
```

**Deploy App:**
```bash
# Copy app to Shiny Server directory
sudo cp -R GreenwichAVApp /srv/shiny-server/

# Set permissions
sudo chown -R shiny:shiny /srv/shiny-server/GreenwichAVApp

# Restart server
sudo systemctl restart shiny-server
```

**Access:** http://your-server-ip:3838/GreenwichAVApp/

---

### Option 2: RStudio Connect (Professional)

1. **Publish from RStudio:**
   - Open app.R
   - Click "Publish" button
   - Select RStudio Connect
   - Follow prompts

2. **Configure Access:**
   - Set user permissions
   - Configure API keys as environment variables
   - Enable scheduled refreshes if needed

---

### Option 3: shinyapps.io (Cloud)

**Setup:**
```r
# Install rsconnect
install.packages("rsconnect")

# Configure account
rsconnect::setAccountInfo(
  name = "your-account",
  token = "your-token",
  secret = "your-secret"
)
```

**Deploy:**
```r
# From app directory
rsconnect::deployApp()
```

**Note:** Free tier has usage limits. Check shinyapps.io pricing.

---

## Docker Deployment

### Dockerfile
```dockerfile
FROM rocker/shiny:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libgdal-dev \
    libudunits2-dev \
    libgeos-dev \
    libproj-dev

# Install R packages
RUN R -e "install.packages(c('shiny', 'shinydashboard', 'R6', 'yaml', \
    'purrr', 'magrittr', 'dplyr', 'sf', 'osmdata', 'leaflet', \
    'htmltools', 'httr', 'jsonlite', 'raster', 'tmaptools'))"

# Copy app
COPY GreenwichAVApp /srv/shiny-server/GreenwichAVApp

# Expose port
EXPOSE 3838

# Run
CMD ["/usr/bin/shiny-server"]
```

### Build and Run
```bash
# Build image
docker build -t greenwich-av-app .

# Run container
docker run -d -p 3838:3838 greenwich-av-app
```

**Access:** http://localhost:3838/GreenwichAVApp/

---

## Environment Configuration

### API Keys (Production)

Create `.Renviron` file:
```r
GOOGLE_MAPS_API_KEY=your_google_key_here
ARCGIS_API_KEY=your_arcgis_key_here
BING_MAPS_API_KEY=your_bing_key_here
```

Load in app:
```r
# In global.R
readRenviron(".Renviron")
google_key <- Sys.getenv("GOOGLE_MAPS_API_KEY")
```

---

## Performance Optimization

### 1. Caching
```r
# In global.R or server.R
cache_dir <- "cache"
if (!dir.exists(cache_dir)) dir.create(cache_dir)

# Cache OSM data
cache_osm_data <- function(location, data) {
  saveRDS(data, file.path(cache_dir, paste0(location, ".rds")))
}
```

### 2. Connection Pooling
```r
# For database connections
pool <- pool::dbPool(...)
```

### 3. Async Processing
```r
# For long-running tasks
library(promises)
library(future)
plan(multisession)
```

---

## Security Best Practices

### 1. Never Commit API Keys
Add to `.gitignore`:
```
.Renviron
.env
*.key
```

### 2. Input Validation
```r
# Validate user inputs
validate_bbox <- function(bbox) {
  # Check bounds, format, etc.
}
```

### 3. Rate Limiting
```r
# Limit API calls per user
library(ratelimitr)
rate_limited_function <- limit_rate(
  original_function,
  rate(n = 10, period = "1 min")
)
```

---

## Monitoring & Logging

### Enable Logging
```r
# In app.R
log_file <- "app.log"

log_message <- function(msg) {
  write(paste(Sys.time(), msg), log_file, append = TRUE)
}
```

### Monitor Usage
```r
# Track user sessions
session_log <- data.frame(
  session_id = character(),
  timestamp = numeric(),
  user = character()
)
```

---

## Backup & Maintenance

### Automated Backups
```bash
# Cron job (daily backup)
0 2 * * * tar -czf /backups/greenwich-app-$(date +\%Y\%m\%d).tar.gz /srv/shiny-server/GreenwichAVApp
```

### Update Dependencies
```r
# Check for updates
update.packages(ask = FALSE)

# Or use renv for reproducibility
renv::init()
renv::snapshot()
```

---

## Troubleshooting Deployment

### Port Already in Use
```r
# Use different port
shiny::runApp(port = 8080)
```

### Permission Issues
```bash
# Fix ownership
sudo chown -R shiny:shiny /srv/shiny-server/GreenwichAVApp
```

### Package Not Found
```r
# Check package installation
installed.packages()

# Reinstall if needed
install.packages("package_name")
```

---

## Load Testing

### Test with shinyloadtest
```r
# Install
install.packages("shinyloadtest")

# Record session
shinyloadtest::record_session("http://localhost:3838/GreenwichAVApp/")

# Run load test
shinyloadtest::load_runs("recording.log", workers = 10)
```

---

## Production Checklist

- [ ] All dependencies installed
- [ ] API keys configured as environment variables
- [ ] Caching implemented for expensive operations
- [ ] Error logging enabled
- [ ] Backups configured
- [ ] Security review completed
- [ ] Load testing performed
- [ ] Documentation updated
- [ ] User training completed

---

## Support & Maintenance

**Regular Tasks:**
- Weekly: Check error logs
- Monthly: Update packages
- Quarterly: Review usage statistics
- Annually: Security audit

**For issues:**
1. Check application logs
2. Review R console output
3. Test in local environment
4. Contact R Shiny community

---

**Happy Deploying! 🚀**
