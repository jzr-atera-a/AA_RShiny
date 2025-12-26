# Validation Checklist - Book Summary Complete Suite v3.0

Run through this checklist to ensure the application is properly configured and working.

## ✅ File Structure Validation

- [ ] `app.R` exists and is under 20 lines
- [ ] `global.R` exists
- [ ] `R/module_loader.R` exists
- [ ] `R/utils_api.R` exists
- [ ] `R/utils_common.R` exists
- [ ] `modules/_module_registry.yml` exists
- [ ] `www/css/global.css` exists
- [ ] All 8 modules have manifest.yml, ui.R, server.R, README.md

## ✅ Module Validation

### BigQuery Auth Module
- [ ] Files exist: manifest.yml, ui.R, server.R, README.md
- [ ] UI function name: `bigquery_auth_ui`
- [ ] Server function name: `bigquery_auth_server`
- [ ] All UI IDs wrapped with `ns()`
- [ ] Server uses `moduleServer()`

### Claude API Config Module
- [ ] Files exist: manifest.yml, ui.R, server.R, README.md
- [ ] UI function name: `claude_api_config_ui`
- [ ] Server function name: `claude_api_config_server`
- [ ] All UI IDs wrapped with `ns()`
- [ ] Server uses `moduleServer()`

### Generate Summary Module
- [ ] Files exist: manifest.yml, ui.R, server.R, README.md
- [ ] UI function name: `generate_summary_ui`
- [ ] Server function name: `generate_summary_server`
- [ ] All UI IDs wrapped with `ns()`
- [ ] Server uses `moduleServer()`

### Bulk Import Module
- [ ] Files exist: manifest.yml, ui.R, server.R, README.md
- [ ] UI function name: `bulk_import_ui`
- [ ] Server function name: `bulk_import_server`
- [ ] All UI IDs wrapped with `ns()`
- [ ] Server uses `moduleServer()`

### Add Single Module
- [ ] Files exist: manifest.yml, ui.R, server.R, README.md
- [ ] UI function name: `add_single_ui`
- [ ] Server function name: `add_single_server`
- [ ] All UI IDs wrapped with `ns()`
- [ ] Server uses `moduleServer()`

### Browse Data Module
- [ ] Files exist: manifest.yml, ui.R, server.R, README.md
- [ ] UI function name: `browse_data_ui`
- [ ] Server function name: `browse_data_server`
- [ ] All UI IDs wrapped with `ns()`
- [ ] Server uses `moduleServer()`

### Visualizations Module
- [ ] Files exist: manifest.yml, ui.R, server.R, README.md
- [ ] UI function name: `visualizations_ui`
- [ ] Server function name: `visualizations_server`
- [ ] All UI IDs wrapped with `ns()`
- [ ] Server uses `moduleServer()`

### About Module
- [ ] Files exist: manifest.yml, ui.R, server.R, README.md
- [ ] UI function name: `about_ui`
- [ ] Server function name: `about_server`
- [ ] All UI IDs wrapped with `ns()`
- [ ] Server uses `moduleServer()`

## ✅ Code Quality Validation

### No Inline CSS
- [ ] No `style` attributes in R files
- [ ] No CSS in `tags$style()` in modules
- [ ] All CSS in `www/css/global.css`

### No Library Calls in Modules
- [ ] No `library()` or `require()` in module ui.R files
- [ ] No `library()` or `require()` in module server.R files
- [ ] All dependencies in manifest.yml

### Proper Namespacing
- [ ] All UI IDs use `ns()` wrapper
- [ ] All server functions use `moduleServer()`
- [ ] No hardcoded IDs without ns()

### R6 Classes
- [ ] ModuleLoader is R6 class
- [ ] APIManager is R6 class
- [ ] Both have `initialize` method
- [ ] APIManager has `state_trigger` reactiveVal

## ✅ Functional Validation

### Module Registry
- [ ] Can enable/disable modules by changing `enabled` field
- [ ] Priority field affects load order
- [ ] Disabled modules don't appear in sidebar
- [ ] Disabled modules don't load packages

### API Manager
- [ ] `state_trigger` is reactiveVal
- [ ] `trigger_state_update()` increments trigger
- [ ] BigQuery methods check authentication
- [ ] Claude methods check authentication
- [ ] SQL injection prevention in queries

### Module Loader
- [ ] `get_enabled_modules()` filters by enabled status
- [ ] `load_packages()` only loads for enabled modules
- [ ] `source_modules()` only sources enabled modules
- [ ] `generate_menu_items()` only for enabled modules
- [ ] `generate_tab_items()` only for enabled modules

## ✅ Documentation Validation

- [ ] README.md exists with overview
- [ ] ARCHITECTURE.md exists with detailed docs
- [ ] INSTALLATION.md exists with setup guide
- [ ] Each module has README.md
- [ ] Code comments throughout

## ✅ Runtime Validation

### App Startup
```r
# Run these checks:
source("global.R")
module_loader <- ModuleLoader$new()

# Should print module status
module_loader$print()

# Should show enabled modules
enabled <- module_loader$get_enabled_modules()
length(enabled)  # Should equal number of enabled modules
```

### Test Module Enable/Disable
1. Edit `modules/_module_registry.yml`
2. Set `visualizations: enabled: false`
3. Restart app
4. Verify "Rich Visualizations" NOT in sidebar
5. Re-enable and verify it appears

### Test BigQuery Module
1. Launch app
2. Go to "BigQuery Setup"
3. Enter credentials
4. Click "Connect to BigQuery"
5. Should see success message
6. Click "Test Query"
7. Should retrieve data (or show empty table)

### Test Claude API Module
1. Launch app
2. Go to "Claude API Config"
3. Enter API key
4. Click "Test Connection"
5. Should see success message
6. Click "Save Credentials"

### Test Generate Summary
1. Configure Claude API first
2. Go to "Generate Summary"
3. Enter book title and author
4. Click "Generate Summary"
5. Should generate formatted summary
6. Test "Parse & Upload Direct"
7. Should upload to BigQuery

### Test Bulk Import
1. Go to "Bulk Import"
2. Paste a formatted summary
3. Click "Parse Summary"
4. Should show parsed data in table
5. Click "Upload to BigQuery"
6. Should upload successfully

### Test Visualizations
1. Go to "Rich Visualizations"
2. Select a book from dropdown
3. Click "Load Visualizations"
4. Should show:
   - Book header
   - Chapter cards with formulas
   - Reference links
   - Plotly charts

## ✅ Performance Validation

- [ ] App loads in < 5 seconds
- [ ] Disabled modules don't impact startup
- [ ] No memory leaks after 10 tab switches
- [ ] BigQuery queries complete in reasonable time
- [ ] Claude API calls complete in < 3 minutes

## ✅ Error Handling Validation

### Invalid Inputs
- [ ] Empty book title shows error
- [ ] Invalid BigQuery JSON shows error
- [ ] Invalid Claude API key shows error
- [ ] Empty summary text shows error

### Authentication Errors
- [ ] BigQuery auth failure shows clear error
- [ ] Claude API auth failure shows clear error
- [ ] Operations fail gracefully when not authenticated

### Status Messages
- [ ] Success messages use green status box
- [ ] Error messages use red status box
- [ ] Info messages use blue status box
- [ ] Loading messages show spinner

## ✅ Security Validation

### SQL Injection Prevention
- [ ] User inputs are escaped before SQL queries
- [ ] Parameterized queries used for INSERT/UPDATE
- [ ] No direct string concatenation in SQL

### API Key Storage
- [ ] Keys not in version control
- [ ] Keys not in logs
- [ ] Keys stored in memory only
- [ ] Keys cleared on session end

## 🎉 Final Validation

- [ ] All above checks passed
- [ ] App runs without errors
- [ ] All modules work as expected
- [ ] Documentation is complete
- [ ] Ready for deployment

---

**Pass Rate Required: 100%**

If any check fails, refer to:
- `ARCHITECTURE.md` for implementation details
- Module README files for specific guidance
- Error messages in R console
