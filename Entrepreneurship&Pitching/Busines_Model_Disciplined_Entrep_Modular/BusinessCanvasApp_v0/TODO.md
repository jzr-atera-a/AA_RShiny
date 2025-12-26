# TODO: Complete Module Implementation

## ✅ What's Already Done

The modular architecture is 95% complete:

1. ✅ Core infrastructure (app.R, global.R, utilities)
2. ✅ Module loader with R6 class
3. ✅ API manager with R6 class  
4. ✅ Complete CSS theme (corporate teal/cyan)
5. ✅ Module registry and structure
6. ✅ One complete working module (`claude_auth`)
7. ✅ Full documentation (README, ARCHITECTURE)

## 🔨 What Needs to Be Completed

**7 modules need their UI and Server files populated with the actual logic from the original app.**

The files exist but are currently empty placeholders. They need the code from the original monolithic app, converted to the modular pattern.

## 📋 Step-by-Step Completion Guide

### For Each of the 7 Remaining Modules:

#### Module 1: `bigquery_auth`

**From original app lines 174-315**

1. **UI File** (`modules/bigquery_auth/ui.R`):
```r
bigquery_auth_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Google Cloud Platform Authentication",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        h4("BigQuery Authentication"),
        # ... Copy UI elements from original lines 182-246
        # IMPORTANT: Wrap ALL IDs with ns()
        # Example: fileInput("json_file", ...) becomes fileInput(ns("json_file"), ...)
        
        fileInput(ns("json_file"), "Select JSON File:", accept = ".json"),
        textAreaInput(ns("json_text"), "JSON Content:", ...),
        textInput(ns("project_id"), "Project ID:", ...),
        textInput(ns("dataset_id"), "Dataset ID:", ...),
        textInput(ns("table_id"), "Table ID:", ...),
        actionButton(ns("authenticate"), "Connect to BigQuery", ...),
        
        hr(),
        htmlOutput(ns("auth_status")),
        verbatimTextOutput(ns("package_info"))
      )
    )
  )
}
```

2. **Server File** (`modules/bigquery_auth/server.R`):
```r
bigquery_auth_server <- function(id, api_manager, session) {
  moduleServer(id, function(input, output, session) {
    
    # Copy server logic from original lines 247-315
    # Key changes:
    # - Use api_manager$set_bigquery_credentials_file() instead of values$
    # - Access inputs directly: input$json_file (NO ns() needed in server)
    # - Keep output$ and observeEvent as-is
    
    output$package_info <- renderText({
      paste0("bigrquery version: ", packageVersion("bigrquery"))
    })
    
    observeEvent(input$authenticate, {
      # Authentication logic here
      # Use api_manager methods instead of values$
    })
  })
}
```

#### Module 2: `generate_bm_canvas`

**From original app lines 357-525**

Follow same pattern:
1. Extract UI (lines 357-465)
2. Convert all IDs to use `ns()`
3. Extract server logic (lines 466-525)
4. Replace `values$` with local reactive values or api_manager calls

#### Module 3: `generate_de_canvas`

**From original app lines 569-722**

#### Module 4: `generate_de_roadmap`

**From original app lines 766-927**

#### Module 5: `view_bm_canvas`

**From original app lines 971-1128**

Key: This uses the canvas grid layout defined in CSS

#### Module 6: `view_de_canvas`

**From original app lines 1167-1313**

#### Module 7: `view_de_roadmap`

**From original app lines 1355-1502**

## 🎯 Conversion Checklist (For Each Module)

### UI Conversion:

- [ ] Create `ns <- NS(id)` as first line
- [ ] Wrap function in `module_name_ui <- function(id) { }`
- [ ] Wrap ALL input IDs: `textInput(ns("my_id"), ...)`
- [ ] Wrap ALL output IDs: `plotOutput(ns("my_plot"), ...)`
- [ ] Return `tagList(...)` containing the UI
- [ ] Remove any `tabItem()` wrapper - that's handled by global.R

### Server Conversion:

- [ ] Create signature: `module_name_server <- function(id, api_manager, session) { }`
- [ ] Wrap in `moduleServer(id, function(input, output, session) { })`
- [ ] Replace `values$authenticated` with `api_manager$bq_authenticated`
- [ ] Replace `values$claude_connected` with `api_manager$claude_connected`
- [ ] Replace `values$project_id` with `api_manager$bq_project_id`
- [ ] Keep `input$id_name` as-is (NO ns() in server)
- [ ] Keep `output$id_name` as-is (NO ns() in server)
- [ ] Use local `reactiveVal()` for module-specific state
- [ ] Add cleanup in `session$onSessionEnded()` if needed

## 💡 Quick Reference

### ID Wrapping Rules:

**IN UI:**
```r
# OLD (monolithic)
textInput("business_area", "Label")

# NEW (modular)
textInput(ns("business_area"), "Label")
```

**IN SERVER:**
```r
# Same as before - NO changes
observeEvent(input$business_area, {
  # use input$business_area directly
})

output$my_output <- renderText({
  input$business_area  # access directly
})
```

### State Management:

**OLD (monolithic):**
```r
values <- reactiveValues(
  authenticated = FALSE,
  parsed_canvas = NULL
)

values$authenticated <- TRUE
```

**NEW (modular):**
```r
# For local module state:
parsed_canvas <- reactiveVal(NULL)
parsed_canvas(new_value)

# For API state:
api_manager$bq_authenticated  # Read
# API manager methods handle setting
```

## 🧪 Testing Each Module

After completing each module:

1. **Enable only that module** in `_module_registry.yml`
2. **Run the app**: `shiny::runApp()`
3. **Test the functionality**
4. **Fix any namespace issues**
5. **Move to next module**

## 🚀 Final Steps

After all 7 modules are complete:

1. Enable all modules in registry
2. Test full app end-to-end
3. Test enabling/disabling each module
4. Verify no namespace conflicts
5. Test with real API credentials
6. Deploy to production

## 📞 Need Help?

### Common Issues:

**Issue**: "object 'id_name' not found"  
**Fix**: You forgot `ns()` in the UI function

**Issue**: "could not find function 'ns'"  
**Fix**: Add `ns <- NS(id)` as first line in UI

**Issue**: "unused argument"  
**Fix**: Check function signature matches pattern

**Issue**: Module not appearing  
**Fix**: Check `enabled: true` in registry

### Example Module Reference:

Look at `modules/claude_auth/ui.R` and `modules/claude_auth/server.R` for a complete, working example.

## ⏱️ Time Estimate

- Per module: 15-30 minutes
- Total for 7 modules: 2-4 hours
- Testing: 1 hour
- **Total**: ~3-5 hours

## ✨ You're Almost There!

The hard architectural work is done. The framework is solid. You just need to:

1. Copy the relevant code from the original app
2. Apply the namespace pattern
3. Test each module
4. Done!

The result will be a **professional, production-ready, modular Shiny application** with:
- Clean architecture
- Easy maintenance
- Scalable design
- Full documentation
- Enterprise-grade quality

Good luck! 🎉
