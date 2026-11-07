# Installation Guide - Book Summary Complete Suite v3.0

## Prerequisites

### System Requirements
- R (>= 4.0.0)
- RStudio (optional but recommended)
- Internet connection (for API calls and BigQuery)

### Required R Packages

Run the following command in R to install all required packages:

```r
# Core packages
install.packages(c(
  "shiny",
  "shinydashboard",
  "R6",
  "yaml",
  "purrr"
))

# API and database packages
install.packages(c(
  "httr",
  "jsonlite",
  "bigrquery"
))

# UI and visualization packages
install.packages(c(
  "DT",
  "plotly",
  "shinyjs"
))

# Data manipulation packages
install.packages(c(
  "dplyr",
  "stringr",
  "tidyr"
))
```

Or install all at once:

```r
install.packages(c(
  "shiny", "shinydashboard", "R6", "yaml", "purrr",
  "httr", "jsonlite", "bigrquery",
  "DT", "plotly", "shinyjs",
  "dplyr", "stringr", "tidyr"
))
```

## Quick Start

### 1. Extract the Application

```bash
# Extract the zip file
unzip BookSummaryApp.zip

# Navigate to the directory
cd BookSummaryApp
```

### 2. Verify Structure

Your directory should look like this:

```
BookSummaryApp/
├── app.R
├── global.R
├── README.md
├── ARCHITECTURE.md
├── INSTALLATION.md
├── R/
│   ├── module_loader.R
│   ├── utils_api.R
│   └── utils_common.R
├── modules/
│   ├── _module_registry.yml
│   └── (8 module directories)
└── www/
    └── css/
        └── global.css
```

### 3. Run the Application

**Option A: Using RStudio**
1. Open `app.R` in RStudio
2. Click the "Run App" button in the top right
3. The app will open in a new window or browser tab

**Option B: Using R Console**
```r
# Set working directory
setwd("path/to/BookSummaryApp")

# Run the app
shiny::runApp()
```

**Option C: Using Command Line**
```r
R -e "shiny::runApp('path/to/BookSummaryApp')"
```

## Configuration

### BigQuery Setup

#### 1. Create a Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Note your Project ID

#### 2. Enable BigQuery API
1. In Cloud Console, go to "APIs & Services" > "Enable APIs and Services"
2. Search for "BigQuery API"
3. Click "Enable"

#### 3. Create Service Account
1. Go to "IAM & Admin" > "Service Accounts"
2. Click "Create Service Account"
3. Give it a name (e.g., "book-summary-app")
4. Grant role: "BigQuery Admin"
5. Click "Done"

#### 4. Create JSON Key
1. Click on the service account you just created
2. Go to "Keys" tab
3. Click "Add Key" > "Create new key"
4. Choose "JSON"
5. Save the downloaded JSON file securely

#### 5. Configure in App
1. Launch the app
2. Go to "BigQuery Setup" tab
3. Either:
   - Upload the JSON file, OR
   - Paste the JSON content
4. Enter your Project ID, Dataset ID, and Table ID
5. Click "Connect to BigQuery"

**Default Configuration:**
- Project: `atera-2`
- Dataset: `Wonderfulp_March`
- Table: `book_summaries_test3`

(Change these to your own values)

### Claude API Setup

#### 1. Get API Key
1. Go to [Anthropic Console](https://console.anthropic.com/)
2. Sign up or log in
3. Go to "API Keys"
4. Create a new API key
5. Copy the key (starts with `sk-ant-api03-`)

#### 2. Configure in App
1. Launch the app
2. Go to "Claude API Config" tab
3. Paste your API key
4. Select model (Claude Sonnet 4.5 recommended)
5. Set max tokens (16,000 default)
6. Click "Test Connection" to verify
7. Click "Save Credentials"

## Customization

### Enable/Disable Modules

Edit `modules/_module_registry.yml`:

```yaml
modules:
  visualizations:
    enabled: false  # ← Change to true/false
    priority: 14
    description: "Rich data visualizations"
```

Changes take effect on next app restart.

### Modify Theme Colors

Edit `www/css/global.css` to change colors, gradients, and styles.

### Add New Modules

See `ARCHITECTURE.md` for detailed instructions on creating new modules.

## Troubleshooting

### Package Installation Issues

If a package fails to install:

```r
# Check R version
R.version.string

# Update all packages
update.packages(ask = FALSE)

# Install specific package with dependencies
install.packages("package_name", dependencies = TRUE)
```

### BigQuery Connection Issues

**Error: "Authentication failed"**
- Verify JSON file is valid
- Check service account has BigQuery permissions
- Ensure BigQuery API is enabled

**Error: "Table not found"**
- App will create table automatically on first use
- Verify project ID, dataset ID, and table ID are correct

### Claude API Issues

**Error: "Invalid API key"**
- Verify key is copied correctly (starts with `sk-ant-api03-`)
- Check for extra spaces or characters
- Ensure API key is active in Anthropic Console

**Error: "Rate limit exceeded"**
- Wait a few minutes before trying again
- Check your API usage limits

### Module Not Appearing

1. Check `modules/_module_registry.yml` - is `enabled: true`?
2. Check console for error messages
3. Verify module files exist (manifest.yml, ui.R, server.R)
4. Restart the app

### Performance Issues

**Slow loading:**
- Disable unused modules in `_module_registry.yml`
- Reduce `max_browse_rows` in Browse Data tab
- Check internet connection

**High memory usage:**
- Close browser tabs not in use
- Restart R session
- Reduce number of enabled modules

## Deployment Options

### Local Deployment
Already covered in Quick Start section.

### Shiny Server (Linux)
```bash
# Install Shiny Server (Ubuntu/Debian)
sudo apt-get install gdebi-core
wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.20.1002-amd64.deb
sudo gdebi shiny-server-1.5.20.1002-amd64.deb

# Copy app to shiny-server directory
sudo cp -r BookSummaryApp /srv/shiny-server/

# Restart service
sudo systemctl restart shiny-server

# Access at http://your-server:3838/BookSummaryApp/
```

### shinyapps.io (Cloud)
```r
# Install rsconnect
install.packages("rsconnect")

# Configure account (get token from shinyapps.io)
library(rsconnect)
setAccountInfo(name="your-account",
               token="your-token",
               secret="your-secret")

# Deploy
setwd("BookSummaryApp")
deployApp()
```

### Docker
```dockerfile
# Dockerfile
FROM rocker/shiny:latest

RUN R -e "install.packages(c('shinydashboard', 'R6', 'yaml', 'purrr', 'httr', 'jsonlite', 'bigrquery', 'DT', 'plotly', 'shinyjs', 'dplyr', 'stringr', 'tidyr'))"

COPY BookSummaryApp /srv/shiny-server/BookSummaryApp

EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
```

```bash
# Build and run
docker build -t book-summary-app .
docker run -p 3838:3838 book-summary-app
```

## Security Considerations

### Production Deployment

1. **Never commit API keys to version control**
   - Use environment variables
   - Use .Renviron file (gitignored)

2. **Secure BigQuery credentials**
   - Use service account JSON securely
   - Limit service account permissions
   - Rotate keys regularly

3. **HTTPS only**
   - Use SSL certificate
   - Redirect HTTP to HTTPS

4. **Input validation**
   - App includes SQL injection prevention
   - Validate all user inputs

## Getting Help

### Documentation
- `README.md` - Overview and quick start
- `ARCHITECTURE.md` - Detailed architecture
- `INSTALLATION.md` - This file
- `modules/*/README.md` - Module-specific docs

### Common Issues
1. Check console for error messages
2. Verify all packages are installed
3. Ensure API credentials are configured
4. Check `_module_registry.yml` for enabled modules

## Next Steps

After installation:

1. **Configure BigQuery** - Connect to your cloud database
2. **Configure Claude API** - Set up AI summary generation
3. **Test Generation** - Generate a test book summary
4. **Explore Visualizations** - View interactive charts
5. **Customize** - Enable/disable modules as needed

## Support

For issues or questions, refer to:
- `ARCHITECTURE.md` for architecture details
- Module READMEs for specific features
- Error messages in R console

---

**Congratulations! Your Book Summary Complete Suite is ready to use! 🎉**
