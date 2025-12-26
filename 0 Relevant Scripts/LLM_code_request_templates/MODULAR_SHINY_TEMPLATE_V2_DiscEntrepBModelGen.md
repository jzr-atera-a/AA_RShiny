# COMPLETE MODULAR R SHINY TEMPLATE v2.0
## Production-Ready Architecture with External API Integration

---

## TABLE OF CONTENTS

1. [Core Architecture](#core-architecture)
2. [Directory Structure](#directory-structure)
3. [Critical Patterns](#critical-patterns)
4. [Module Creation Guide](#module-creation-guide)
5. [API Integration Patterns](#api-integration-patterns)
6. [Common Patterns Library](#common-patterns-library)
7. [Testing & Validation](#testing--validation)
8. [Quick Start Guide](#quick-start-guide)

---

## CORE ARCHITECTURE

### Design Principles

1. **Minimal Entry Point** - `app.R` under 20 lines
2. **Centralized Configuration** - `global.R` for setup
3. **Module Independence** - Each feature is self-contained
4. **Enable/Disable Control** - ONE line change in registry
5. **Zero Namespace Conflicts** - Proper use of `NS()` and `moduleServer()`
6. **Reactive State Sharing** - R6 classes with `reactiveVal()` triggers
7. **Centralized Styling** - ALL CSS in `www/css/global.css`

---

## DIRECTORY STRUCTURE

```
MyShinyApp/
├── app.R                          # Entry point (15 lines max)
├── global.R                       # Configuration & factories
├── config.yml                     # Optional app config
│
├── R/
│   ├── module_loader.R            # R6 ModuleLoader class
│   ├── utils_api.R                # R6 APIManager class (with reactive triggers!)
│   └── utils_common.R             # Shared utilities
│
├── modules/
│   ├── _module_registry.yml       # CONTROL CENTER - enable/disable
│   │
│   ├── [module_name]/
│   │   ├── manifest.yml           # Metadata & dependencies
│   │   ├── ui.R                   # Namespaced UI function
│   │   ├── server.R               # moduleServer function
│   │   ├── utils.R                # Module-specific helpers (optional)
│   │   ├── data/                  # Module-specific data (optional)
│   │   └── README.md              # Documentation
│   │
│   └── (repeat for each module)
│
├── www/                           # Static assets
│   ├── css/
│   │   ├── global.css            # ALL CSS HERE - centralized
│   │   └── modules/              # Optional module-specific CSS
│   ├── js/
│   │   └── custom.js             # Custom JavaScript
│   └── img/
│       └── logo.png
│
├── data/                          # Shared data
│   └── common/
│
└── tests/                         # Testing
    └── test_modules.R
```

---

## CRITICAL PATTERNS

### 1. REACTIVE STATE SHARING (R6 + reactiveVal)

**⚠️ CRITICAL:** Regular R6 fields are NOT reactive! Use `reactiveVal()` for cross-module communication.

```r
# R/utils_api.R
library(R6)

APIManager <- R6Class(
  "APIManager",
  public = list(
    # Regular fields for state
    authenticated = FALSE,
    api_key = NULL,
    
    # ⭐ CRITICAL: Reactive trigger for cross-module updates
    state_trigger = NULL,
    
    initialize = function() {
      # Initialize reactive trigger - MUST be inside a reactive context
      self$state_trigger <- shiny::reactiveVal(0)
      cat("🔌 API Manager initialized with reactive trigger\n")
    },
    
    # Method to trigger all watching modules
    trigger_state_update = function() {
      current <- self$state_trigger()
      self$state_trigger(current + 1)
      cat("🔔 State trigger fired:", current + 1, "\n")
    },
    
    # Example: Authentication method
    authenticate = function(credentials) {
      # ... authentication logic ...
      self$authenticated <- TRUE
      self$trigger_state_update()  # ⭐ TRIGGER ALL MODULES
    }
  )
)
```

**In Modules - Watching for State Changes:**

```r
# modules/my_module/server.R
my_module_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    # ⭐ WATCH the reactive trigger
    observe({
      api_manager$state_trigger()  # This makes the observer reactive
      
      if (api_manager$authenticated) {
        # React to authentication state change
        load_initial_data()
      }
    })
    
  })
}
```

---

### 2. CASCADING DROPDOWNS WITH EXTERNAL DATA

**Pattern:** Authentication → Level 1 → Level 2 → Level 3

```r
# modules/my_module/server.R
my_module_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    # ⭐ STEP 1: Populate first dropdown after authentication
    observe({
      api_manager$state_trigger()  # Watch for auth changes
      
      if (api_manager$authenticated) {
        update_level1_dropdown()
      }
    })
    
    # Helper function with guard clause
    update_level1_dropdown <- function() {
      if (!api_manager$authenticated) return()
      
      tryCatch({
        # Query data source
        query <- "SELECT DISTINCT category FROM table ORDER BY category"
        result <- query_database(query)
        
        if (nrow(result) > 0) {
          updateSelectInput(session, "level1", 
                            choices = c("Select..." = "", result$category))
        }
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error")
      })
    }
    
    # ⭐ STEP 2: Cascade to level 2 when level 1 changes
    observeEvent(input$level1, {
      # Reset downstream dropdowns when cleared
      if (input$level1 == "") {
        updateSelectInput(session, "level2", choices = c("Select..." = ""))
        updateSelectInput(session, "level3", choices = c("Select..." = ""))
        return()
      }
      
      # Populate level 2 based on level 1 selection
      tryCatch({
        # ⭐ SQL INJECTION PREVENTION
        safe_input <- gsub("'", "\\\\'", input$level1)
        
        query <- sprintf("SELECT DISTINCT subcategory FROM table WHERE category = '%s'", 
                         safe_input)
        result <- query_database(query)
        
        if (nrow(result) > 0) {
          updateSelectInput(session, "level2", 
                            choices = c("Select..." = "", result$subcategory))
        }
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
    
    # ⭐ STEP 3: Cascade to level 3
    observeEvent(input$level2, {
      if (input$level2 == "") {
        updateSelectInput(session, "level3", choices = c("Select..." = ""))
        return()
      }
      
      # ... populate level 3 based on level 1 + level 2 ...
    })
    
  })
}
```

---

### 3. BIGQUERY INTEGRATION PATTERN

**Complete Authentication → Query → Insert Flow**

```r
# R/utils_api.R - APIManager additions
APIManager <- R6Class(
  "APIManager",
  public = list(
    bq_authenticated = FALSE,
    bq_project_id = NULL,
    bq_dataset_id = NULL,
    bq_table_id = NULL,
    bq_full_table_id = NULL,
    state_trigger = NULL,
    
    initialize = function() {
      self$state_trigger <- shiny::reactiveVal(0)
    },
    
    # Set BigQuery credentials
    set_bigquery_credentials = function(project_id, dataset_id, table_id) {
      self$bq_project_id <- project_id
      self$bq_dataset_id <- dataset_id
      self$bq_table_id <- table_id
      self$bq_full_table_id <- paste0(project_id, ".", dataset_id, ".", table_id)
    },
    
    # Authenticate BigQuery
    authenticate_bigquery = function(json_path) {
      tryCatch({
        bigrquery::bq_auth(path = json_path, cache = FALSE)
        
        # Test connection
        datasets <- bigrquery::bq_project_datasets(self$bq_project_id)
        
        self$bq_authenticated <- TRUE
        self$trigger_state_update()  # ⭐ TRIGGER ALL MODULES
        
        return(TRUE)
      }, error = function(e) {
        self$bq_authenticated <- FALSE
        stop(paste("BigQuery authentication failed:", e$message))
      })
    },
    
    # Query with automatic error handling
    bq_query <- function(query) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      
      job <- bigrquery::bq_project_query(self$bq_project_id, query)
      return(bigrquery::bq_table_download(job))
    },
    
    # Insert data (SQL injection safe)
    bq_insert <- function(data_frame, table_name = NULL) {
      if (!self$bq_authenticated) stop("Not authenticated to BigQuery")
      
      table_name <- table_name %||% self$bq_table_id
      table_ref <- bigrquery::bq_table(self$bq_project_id, self$bq_dataset_id, table_name)
      
      bigrquery::bq_table_upload(table_ref, data_frame, 
                                  fields = NULL, 
                                  write_disposition = "WRITE_APPEND")
    }
  )
)

`%||%` <- function(x, y) if (is.null(x)) y else x
```

**BigQuery Authentication Module:**

```r
# modules/bigquery_auth/server.R
bigquery_auth_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(input$authenticate, {
      # Validate inputs
      if (trimws(input$project_id) == "" || 
          trimws(input$dataset_id) == "" ||
          trimws(input$table_id) == "") {
        showNotification("Fill in all fields", type = "error")
        return()
      }
      
      tryCatch({
        # Set credentials
        api_manager$set_bigquery_credentials(
          project_id = trimws(input$project_id),
          dataset_id = trimws(input$dataset_id),
          table_id = trimws(input$table_id)
        )
        
        # Authenticate (from file upload or JSON text)
        if (!is.null(input$json_file)) {
          api_manager$authenticate_bigquery(input$json_file$datapath)
        } else if (trimws(input$json_text) != "") {
          temp_file <- tempfile(fileext = ".json")
          writeLines(input$json_text, temp_file)
          api_manager$authenticate_bigquery(temp_file)
        } else {
          stop("Provide credentials")
        }
        
        showNotification("✓ BigQuery connected!", type = "message")
        
        output$status <- renderUI({
          tags$div(class = "status-success", 
                   "✓ Authenticated to ", api_manager$bq_full_table_id)
        })
        
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error")
        output$status <- renderUI({
          tags$div(class = "status-error", e$message)
        })
      })
    })
  })
}
```

---

### 4. CLAUDE API INTEGRATION WITH TOKEN LIMITS

**Pattern for Structured Content Generation**

```r
# R/utils_api.R - APIManager additions
APIManager <- R6Class(
  "APIManager",
  public = list(
    claude_api_key = NULL,
    claude_model = "claude-sonnet-4-20250514",
    claude_max_tokens = 4000,
    
    set_claude_credentials = function(api_key) {
      self$claude_api_key <- api_key
    },
    
    # Call Claude with automatic error handling
    call_claude = function(prompt, max_tokens = NULL) {
      if (is.null(self$claude_api_key)) stop("Claude API key not set")
      
      tokens <- max_tokens %||% self$claude_max_tokens
      
      response <- httr::POST(
        url = "https://api.anthropic.com/v1/messages",
        httr::add_headers(
          "x-api-key" = self$claude_api_key,
          "anthropic-version" = "2023-06-01",
          "content-type" = "application/json"
        ),
        body = jsonlite::toJSON(list(
          model = self$claude_model,
          max_tokens = tokens,
          messages = list(list(role = "user", content = prompt))
        ), auto_unbox = TRUE),
        encode = "json"
      )
      
      if (httr::status_code(response) != 200) {
        stop("API request failed: ", httr::content(response, "text"))
      }
      
      result <- httr::content(response, "parsed")
      return(result$content[[1]]$text)
    }
  )
)
```

**Module with Word Count Control:**

```r
# modules/generate_content/ui.R
generate_content_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      column(9, textAreaInput(ns("description"), "Description:", height = "100px")),
      column(3, 
        sliderInput(ns("words_per_section"), "Words per Section:", 
                    min = 10, max = 100, value = 30, step = 5),
        br(),
        actionButton(ns("generate"), "Generate", class = "btn-primary")
      )
    ),
    
    div(class = "alert alert-info",
        tags$strong("Tip:"), " Lower word counts ensure complete generation. ",
        "Recommended: 20-40 words per section."
    ),
    
    textAreaInput(ns("output"), "Generated Content:", height = "400px"),
    htmlOutput(ns("status"))
  )
}

# modules/generate_content/server.R
generate_content_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(input$generate, {
      if (trimws(input$description) == "") {
        showNotification("Enter description", type = "warning")
        return()
      }
      
      output$status <- renderUI({
        tags$div(class = "status-info", 
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Generating ", input$words_per_section, " words per section...")
      })
      
      tryCatch({
        # ⭐ EXPLICIT STRUCTURE with WORD LIMITS
        prompt <- paste0(
          "Generate content with EXACTLY 5 sections.\n\n",
          "Description: ", input$description, "\n\n",
          "CRITICAL REQUIREMENTS:\n",
          "1. Generate ALL 5 sections - DO NOT skip any\n",
          "2. Each section: MAXIMUM ", input$words_per_section, " words\n",
          "3. Use EXACT format below\n\n",
          "FORMAT:\n\n",
          "[Section 1: Introduction]\n",
          "(max ", input$words_per_section, " words)\n\n",
          "[Section 2: Main Content]\n",
          "(max ", input$words_per_step, " words)\n\n",
          "[Section 3: Details]\n",
          "(max ", input$words_per_step, " words)\n\n",
          "[Section 4: Examples]\n",
          "(max ", input$words_per_step, " words)\n\n",
          "[Section 5: Conclusion]\n",
          "(max ", input$words_per_step, " words)\n\n",
          "VERIFY: Ensure ALL 5 sections written before finishing."
        )
        
        generated <- api_manager$call_claude(prompt)
        
        # ⭐ VALIDATE COMPLETENESS
        section_count <- length(gregexpr("\\[Section \\d+:", generated)[[1]])
        
        if (section_count < 5) {
          output$status <- renderUI({
            tags$div(class = "status-warning",
                     tags$i(class = "fa fa-exclamation-triangle"),
                     sprintf(" Warning: Only %d of 5 sections generated. Try reducing words per section.", section_count))
          })
        } else {
          output$status <- renderUI({
            tags$div(class = "status-success",
                     tags$i(class = "fa fa-check-circle"),
                     " ✓ All 5 sections generated!")
          })
        }
        
        updateTextAreaInput(session, "output", value = generated)
        
      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error", "Error: ", e$message)
        })
      })
    })
  })
}
```

---

### 5. FLEXIBLE PARSING PATTERN

**Match Structure, Not Exact Text**

```r
# Parse Claude-generated content with flexible patterns
parse_sections <- function(text, num_sections = 5) {
  sections <- list()
  
  for (i in 1:num_sections) {
    # ⭐ FLEXIBLE: Match [Section X: ANYTHING]
    pattern <- sprintf("\\[Section\\s*%d:?\\s*[^\\]]+\\]\\s*\n([\\s\\S]*?)(?=\\n\\[Section|$)", i)
    match <- stringr::str_match(text, pattern)[,2]
    
    sections[[sprintf("section_%02d", i)]] <- if (!is.na(match)) {
      trimws(match)
    } else {
      NA
    }
  }
  
  # Validation with helpful error message
  missing <- which(is.na(unlist(sections)))
  found <- which(!is.na(unlist(sections)))
  
  if (length(missing) > 0) {
    stop(sprintf(
      "Missing sections: %s\nFound sections: %s\n\nEnsure all sections have [Section X: ...] headers.",
      paste(missing, collapse = ", "),
      paste(found, collapse = ", ")
    ))
  }
  
  return(sections)
}
```

---

### 6. MULTI-STATE RENDERING PATTERN

**Consistent UI Across States**

```r
# Shared rendering function for all display states
render_data_display <- function(data = NULL, state = "default") {
  
  if (state == "default") {
    content <- '<div class="alert alert-info">
                  <h4>Load data to view content</h4>
                </div>'
                
  } else if (state == "loaded" && !is.null(data)) {
    # Format data into consistent HTML structure
    content <- sprintf('
      <div class="data-grid">
        <h3>%s</h3>
        <div class="content">%s</div>
      </div>
    ', data$title, gsub("\n", "<br>", data$content))
    
  } else if (state == "error") {
    content <- '<div class="alert alert-danger">
                  <h4>Error loading data</h4>
                </div>'
  }
  
  return(HTML(content))
}

# Usage in module server
my_module_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    # Default state
    output$display <- renderUI({
      render_data_display(state = "default")
    })
    
    # Loaded state
    observeEvent(input$load, {
      tryCatch({
        data <- load_data()
        output$display <- renderUI({
          render_data_display(data, state = "loaded")
        })
      }, error = function(e) {
        output$display <- renderUI({
          render_data_display(state = "error")
        })
      })
    })
  })
}
```

---

## MODULE CREATION GUIDE

### Step-by-Step: Creating a New Module

#### 1. Create Module Structure

```bash
mkdir -p modules/my_module
touch modules/my_module/{manifest.yml,ui.R,server.R,README.md}
```

#### 2. Create manifest.yml

```yaml
module:
  id: "my_module"
  name: "My Feature Module"
  description: "Brief description of what this module does"
  version: "1.0.0"
  author: "Your Name"
  
  enabled: true
  
  menu:
    label: "My Feature"
    icon: "chart-line"          # FontAwesome icon name
    tabname: "my_module"         # Must match module ID
    badge:
      label: null                # Optional: "new", "beta"
      color: null                # Optional: "green", "red"
  
  dependencies:
    packages:
      - shiny
      - shinydashboard
      # Add all required packages
    
    package_versions:            # Optional
      ggplot2: ">= 3.1.0"
  
  api:
    required: []                 # e.g., ["bigquery", "claude"]
    optional: []
  
  data:
    required: []
    optional: []
```

#### 3. Create ui.R

```r
# modules/my_module/ui.R

my_module_ui <- function(id) {
  # ⭐ CRITICAL: Create namespace function
  ns <- NS(id)
  
  # Return UI wrapped in tagList
  tagList(
    fluidRow(
      box(
        title = "My Module Title",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        # ⭐ ALL IDs MUST be wrapped with ns()
        fluidRow(
          column(6, 
            selectInput(ns("dropdown1"), "Select Category:", 
                        choices = NULL),  # Populated in server
            selectInput(ns("dropdown2"), "Select Item:", 
                        choices = NULL)
          ),
          column(6,
            actionButton(ns("load_btn"), "Load Data", 
                        class = "btn-primary")
          )
        ),
        
        hr(),
        
        htmlOutput(ns("display")),
        htmlOutput(ns("status"))
      )
    )
  )
}
```

#### 4. Create server.R

```r
# modules/my_module/server.R

my_module_server <- function(id, api_manager) {
  # ⭐ Use moduleServer for proper namespacing
  moduleServer(id, function(input, output, session) {
    
    # Reactive values
    data <- reactiveVal(NULL)
    
    # ⭐ Watch for authentication state changes
    observe({
      api_manager$state_trigger()
      
      if (api_manager$authenticated) {
        update_dropdown1()
      }
    })
    
    # Update first dropdown
    update_dropdown1 <- function() {
      if (!api_manager$authenticated) return()
      
      tryCatch({
        result <- api_manager$query_data("SELECT DISTINCT category...")
        
        if (nrow(result) > 0) {
          updateSelectInput(session, "dropdown1",
                            choices = c("Select..." = "", result$category))
        }
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error")
      })
    }
    
    # Cascading dropdown
    observeEvent(input$dropdown1, {
      if (input$dropdown1 == "") {
        updateSelectInput(session, "dropdown2", choices = c("Select..." = ""))
        return()
      }
      
      # ⭐ SQL injection prevention
      safe_input <- gsub("'", "\\\\'", input$dropdown1)
      # ... query and update dropdown2 ...
    })
    
    # Load data button
    observeEvent(input$load_btn, {
      if (input$dropdown1 == "" || input$dropdown2 == "") {
        showNotification("Select all fields", type = "warning")
        return()
      }
      
      tryCatch({
        result <- load_data(input$dropdown1, input$dropdown2)
        data(result)
        
        output$display <- renderUI({
          render_data(result)
        })
        
        output$status <- renderUI({
          tags$div(class = "status-success", "✓ Data loaded!")
        })
        
      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error", "Error: ", e$message)
        })
      })
    })
    
    # Default display
    output$display <- renderUI({
      render_data(state = "default")
    })
    
    # Cleanup on session end
    session$onSessionEnded(function() {
      # Cleanup code here
    })
  })
}
```

#### 5. Register in _module_registry.yml

```yaml
# modules/_module_registry.yml

modules:
  my_module:
    enabled: true      # ⭐ Set to false to disable
    priority: 10       # Load order (lower = earlier)
    description: "My feature module"
```

#### 6. Create README.md

```markdown
# My Module

## Description
What this module does.

## Dependencies
- Package 1
- Package 2

## API Requirements
- BigQuery (if needed)
- Claude API (if needed)

## Inputs
- `dropdown1`: Category selection
- `dropdown2`: Item selection

## Outputs
- `display`: Data visualization
- `status`: Status messages

## Usage
1. Authenticate required APIs
2. Select category
3. Select item
4. Click "Load Data"

## Data
None / List data files required
```

---

## API INTEGRATION PATTERNS

### Complete BigQuery Module Example

```r
# modules/bigquery_auth/ui.R
bigquery_auth_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(
        title = "BigQuery Authentication",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        
        fluidRow(
          column(4, textInput(ns("project_id"), "Project ID:")),
          column(4, textInput(ns("dataset_id"), "Dataset ID:")),
          column(4, textInput(ns("table_id"), "Table ID:"))
        ),
        
        h5("Provide Credentials (choose one):"),
        
        tabsetPanel(
          tabPanel("JSON File Upload",
            br(),
            fileInput(ns("json_file"), "Upload Service Account JSON:",
                     accept = ".json")
          ),
          tabPanel("Paste JSON",
            br(),
            textAreaInput(ns("json_text"), "Paste JSON Content:", 
                         height = "200px")
          )
        ),
        
        br(),
        actionButton(ns("authenticate"), "Authenticate", 
                    class = "btn-success btn-lg"),
        
        br(), br(),
        htmlOutput(ns("status"))
      )
    )
  )
}

# modules/bigquery_auth/server.R
bigquery_auth_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(input$authenticate, {
      # Validation
      if (trimws(input$project_id) == "" || 
          trimws(input$dataset_id) == "" ||
          trimws(input$table_id) == "") {
        output$status <- renderUI({
          tags$div(class = "status-error", "Fill in all fields")
        })
        return()
      }
      
      tryCatch({
        # Set credentials
        api_manager$set_bigquery_credentials(
          project_id = trimws(input$project_id),
          dataset_id = trimws(input$dataset_id),
          table_id = trimws(input$table_id)
        )
        
        # Authenticate
        if (!is.null(input$json_file) && !is.null(input$json_file$datapath)) {
          # JSON file upload
          json_content <- jsonlite::fromJSON(input$json_file$datapath)
          
          # Validate JSON structure
          required_fields <- c("type", "project_id", "private_key", "client_email")
          missing <- setdiff(required_fields, names(json_content))
          if (length(missing) > 0) {
            stop("Missing JSON fields: ", paste(missing, collapse = ", "))
          }
          
          bigrquery::bq_auth(path = input$json_file$datapath, cache = FALSE)
          
        } else if (!is.null(input$json_text) && trimws(input$json_text) != "") {
          # JSON text paste
          json_content <- jsonlite::fromJSON(input$json_text)
          
          required_fields <- c("type", "project_id", "private_key", "client_email")
          missing <- setdiff(required_fields, names(json_content))
          if (length(missing) > 0) {
            stop("Missing JSON fields: ", paste(missing, collapse = ", "))
          }
          
          temp_file <- tempfile(fileext = ".json")
          writeLines(input$json_text, temp_file)
          bigrquery::bq_auth(path = temp_file, cache = FALSE)
          
        } else {
          stop("Provide credentials")
        }
        
        # Test connection
        datasets <- bigrquery::bq_project_datasets(api_manager$bq_project_id)
        
        # Mark as authenticated
        api_manager$bq_authenticated <- TRUE
        api_manager$trigger_state_update()  # ⭐ CRITICAL: Trigger modules
        
        output$status <- renderUI({
          tags$div(class = "status-success",
                   tags$i(class = "fa fa-check-circle"),
                   " ✓ Connected to BigQuery!",
                   br(),
                   tags$small("Table: ", api_manager$bq_full_table_id))
        })
        
        showNotification("✓ BigQuery connected!", type = "message")
        
      }, error = function(e) {
        api_manager$bq_authenticated <- FALSE
        
        output$status <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Authentication failed: ",
                   br(),
                   tags$small(e$message))
        })
        
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
  })
}
```

---

## COMMON PATTERNS LIBRARY

### SQL Injection Prevention

```r
# ALWAYS escape user input before using in SQL
safe_escape <- function(input_value) {
  gsub("'", "\\\\'", input_value)
}

# Usage
safe_category <- safe_escape(input$category)
query <- sprintf("SELECT * FROM table WHERE category = '%s'", safe_category)

# BETTER: Use parameterized data frames for INSERT/UPDATE
data_to_insert <- data.frame(
  id = generate_id(),
  category = input$category,  # No escaping needed!
  value = input$value,
  stringsAsFactors = FALSE
)
api_manager$bq_insert(data_to_insert)
```

### Error Handling Pattern

```r
# Standardized error handling with user notifications
safe_operation <- function(operation_name, func) {
  tryCatch({
    result <- func()
    showNotification(paste("✓", operation_name, "successful"), type = "message")
    return(result)
    
  }, error = function(e) {
    showNotification(paste(operation_name, "failed:", e$message), type = "error")
    return(NULL)
  })
}

# Usage
observeEvent(input$save, {
  result <- safe_operation("Save data", function() {
    api_manager$bq_insert(data_frame)
  })
  
  if (!is.null(result)) {
    # Success actions
  }
})
```

### Loading State Management

```r
# Show loading, execute, show result
with_loading <- function(output_id, message, func) {
  # Show loading
  output[[output_id]] <- renderUI({
    tags$div(class = "status-info",
             tags$i(class = "fa fa-spinner fa-spin"),
             " ", message)
  })
  
  # Execute
  result <- tryCatch({
    func()
  }, error = function(e) {
    output[[output_id]] <- renderUI({
      tags$div(class = "status-error", "Error: ", e$message)
    })
    return(NULL)
  })
  
  # Show success
  if (!is.null(result)) {
    output[[output_id]] <- renderUI({
      tags$div(class = "status-success", "✓ Complete!")
    })
  }
  
  return(result)
}

# Usage
observeEvent(input$load, {
  data <- with_loading("status", "Loading data...", function() {
    query_database()
  })
})
```

---

## TESTING & VALIDATION

### Module Validation Checklist

- [ ] `manifest.yml` includes all dependencies
- [ ] All UI IDs wrapped with `ns()`
- [ ] Server uses `moduleServer()`
- [ ] No library() calls in module files
- [ ] SQL input properly escaped
- [ ] Error handling with user notifications
- [ ] Default state displayed
- [ ] Cleanup in `session$onSessionEnded()`
- [ ] README.md documents usage
- [ ] Works when enabled/disabled in registry

### Testing New Module

```r
# tests/test_my_module.R

# 1. Test module loads
source("modules/my_module/ui.R")
source("modules/my_module/server.R")

# 2. Test UI function
ui_result <- my_module_ui("test")
stopifnot(!is.null(ui_result))

# 3. Test with mock api_manager
mock_api <- list(
  authenticated = TRUE,
  state_trigger = shiny::reactiveVal(0),
  trigger_state_update = function() {}
)

# 4. Run in test app
library(shiny)
ui <- fluidPage(my_module_ui("test"))
server <- function(input, output, session) {
  my_module_server("test", mock_api)
}
shinyApp(ui, server)
```

---

## QUICK START GUIDE

### Creating a New App from Scratch

```bash
# 1. Create directory structure
mkdir -p MyApp/{R,modules,www/css,www/js,www/img,data/common,tests}

# 2. Create core files
touch MyApp/{app.R,global.R}
touch MyApp/R/{module_loader.R,utils_api.R,utils_common.R}
touch MyApp/modules/_module_registry.yml
touch MyApp/www/css/global.css

# 3. Copy template files (provided in this guide)
# - app.R
# - global.R  
# - R/module_loader.R
# - R/utils_api.R
# - www/css/global.css

# 4. Create your first module
mkdir -p MyApp/modules/my_first_module
# Add manifest.yml, ui.R, server.R, README.md

# 5. Register module
# Edit modules/_module_registry.yml

# 6. Run
cd MyApp
R -e "shiny::runApp()"
```

### Converting Existing Monolithic App

1. **Identify Features** - List all distinct features/tabs
2. **Create Module Structure** - One folder per feature
3. **Extract UI** - Convert `tabItem()` to module UI function
4. **Extract Server** - Wrap in `moduleServer()`
5. **Extract Dependencies** - List packages in manifest
6. **Move CSS** - All styling to `global.css`
7. **Update IDs** - Wrap with `ns()` in UI
8. **Test Each Module** - Enable one at a time
9. **Add API Integration** - If needed
10. **Deploy** - Production-ready!

---

## COMPLETE FILE TEMPLATES

### app.R

```r
# app.R - Entry Point Only
# All configuration in global.R

source("global.R")

# Initialize module loader
module_loader <- ModuleLoader$new()
module_loader$print()
module_loader$load_packages()
module_loader$source_modules()

# Run application
shinyApp(
  ui = create_ui(module_loader),
  server = function(input, output, session) {
    create_server(module_loader, api_manager)
  }
)
```

### global.R

```r
# global.R - Global Configuration

cat("\n╔═══════════════════════════════════════╗\n")
cat("║  MODULAR SHINY APP - INITIALIZING    ║\n")
cat("╚═══════════════════════════════════════╝\n\n")

# Core packages (always required)
suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard)
  library(R6)
  library(yaml)
  library(purrr)
})

# Source utilities
source("R/module_loader.R")
source("R/utils_common.R")
if (file.exists("R/utils_api.R")) {
  source("R/utils_api.R")
}

# Initialize API manager
api_manager <- if (exists("APIManager")) {
  APIManager$new()
} else {
  NULL
}

# UI Factory Function
create_ui <- function(module_loader) {
  dashboardPage(
    dashboardHeader(
      title = module_loader$registry$app$name %||% "Dashboard"
    ),
    
    dashboardSidebar(
      sidebarMenu(
        id = "sidebar_menu",
        do.call(tagList, module_loader$generate_menu_items())
      )
    ),
    
    dashboardBody(
      tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "css/global.css"),
        tags$meta(charset = "UTF-8"),
        tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0")
      ),
      
      # Pass list directly to tabItems, not wrapped in tagList
      do.call(tabItems, module_loader$generate_tab_items())
    )
  )
}

# Server Factory Function
create_server <- function(module_loader, api_manager) {
  enabled_modules <- module_loader$get_enabled_modules()
  
  for (module in enabled_modules) {
    module_id <- module$module$id
    server_function_name <- paste0(module_id, "_server")
    
    if (exists(server_function_name, envir = .GlobalEnv)) {
      server_function <- get(server_function_name, envir = .GlobalEnv)
      server_function(module_id, api_manager)
    }
  }
}

`%||%` <- function(x, y) if (is.null(x)) y else x

cat("✓ Global configuration complete\n\n")
```

### R/module_loader.R

```r
# Module Loader R6 Class

library(R6)
library(yaml)
library(purrr)

ModuleLoader <- R6Class(
  "ModuleLoader",
  
  public = list(
    modules = list(),
    registry = NULL,
    loaded_packages = character(0),
    
    initialize = function() {
      self$load_registry()
      self$discover_modules()
    },
    
    load_registry = function() {
      registry_path <- "modules/_module_registry.yml"
      if (!file.exists(registry_path)) {
        stop("Module registry not found: ", registry_path)
      }
      self$registry <- yaml::read_yaml(registry_path)
    },
    
    discover_modules = function() {
      module_dirs <- list.dirs("modules", recursive = FALSE)
      module_dirs <- module_dirs[!grepl("^_", basename(module_dirs))]
      
      for (dir in module_dirs) {
        manifest_path <- file.path(dir, "manifest.yml")
        if (!file.exists(manifest_path)) next
        
        manifest <- yaml::read_yaml(manifest_path)
        module_id <- manifest$module$id
        
        # Check enabled status (registry overrides manifest)
        enabled <- if (!is.null(self$registry$modules[[module_id]]$enabled)) {
          self$registry$modules[[module_id]]$enabled
        } else {
          manifest$module$enabled %||% TRUE
        }
        
        manifest$module$enabled <- enabled
        manifest$module$path <- dir
        
        self$modules[[module_id]] <- manifest
      }
      
      # Sort by priority
      self$modules <- self$modules[order(sapply(self$modules, function(m) {
        self$registry$modules[[m$module$id]]$priority %||% 99
      }))]
    },
    
    get_enabled_modules = function() {
      purrr::keep(self$modules, ~ .x$module$enabled)
    },
    
    load_packages = function() {
      enabled_modules <- self$get_enabled_modules()
      
      all_packages <- unique(unlist(lapply(enabled_modules, function(m) {
        m$module$dependencies$packages
      })))
      
      for (pkg in all_packages) {
        if (!pkg %in% self$loaded_packages) {
          if (!requireNamespace(pkg, quietly = TRUE)) {
            warning("Package not installed: ", pkg)
          } else {
            suppressPackageStartupMessages(library(pkg, character.only = TRUE))
            self$loaded_packages <- c(self$loaded_packages, pkg)
          }
        }
      }
      
      cat("✓ Loaded packages:", paste(self$loaded_packages, collapse = ", "), "\n")
    },
    
    source_modules = function() {
      enabled_modules <- self$get_enabled_modules()
      
      for (module in enabled_modules) {
        ui_path <- file.path(module$module$path, "ui.R")
        server_path <- file.path(module$module$path, "server.R")
        
        if (file.exists(ui_path)) source(ui_path, local = .GlobalEnv)
        if (file.exists(server_path)) source(server_path, local = .GlobalEnv)
        
        cat("✓ Loaded module:", module$module$id, "\n")
      }
    },
    
    generate_menu_items = function() {
      enabled_modules <- self$get_enabled_modules()
      
      lapply(enabled_modules, function(module) {
        menu_info <- module$module$menu
        
        badge <- if (!is.null(menu_info$badge$label)) {
          tags$span(
            class = paste0("label label-", menu_info$badge$color %||% "primary"),
            menu_info$badge$label
          )
        } else {
          NULL
        }
        
        menuItem(
          menu_info$label,
          tabName = menu_info$tabname,
          icon = icon(menu_info$icon),
          badgeLabel = badge
        )
      })
    },
    
    generate_tab_items = function() {
      enabled_modules <- self$get_enabled_modules()
      
      lapply(enabled_modules, function(module) {
        ui_function_name <- paste0(module$module$id, "_ui")
        
        if (exists(ui_function_name, envir = .GlobalEnv)) {
          ui_function <- get(ui_function_name, envir = .GlobalEnv)
          
          tabItem(
            tabName = module$module$menu$tabname,
            ui_function(module$module$id)
          )
        } else {
          NULL  # Return NULL if UI function doesn't exist
        }
      })
    },
    
    print = function() {
      cat("\n📦 Module Loader Status:\n")
      cat("   Total modules:", length(self$modules), "\n")
      
      enabled <- self$get_enabled_modules()
      cat("   Enabled:", length(enabled), "\n")
      
      if (length(enabled) > 0) {
        cat("\n   Enabled modules:\n")
        for (m in enabled) {
          cat("   ✓", m$module$name, "\n")
        }
      }
      
      disabled <- purrr::keep(self$modules, ~ !.x$module$enabled)
      if (length(disabled) > 0) {
        cat("\n   Disabled modules:\n")
        for (m in disabled) {
          cat("   ✗", m$module$name, "\n")
        }
      }
      cat("\n")
    }
  )
)
```

### www/css/global.css

```css
/* Corporate Teal/Cyan Theme */

/* Main Backgrounds */
.content-wrapper, .right-side {
  background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
  min-height: 100vh;
}

.sidebar, .main-sidebar {
  background: linear-gradient(180deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
}

/* Sidebar Menu */
.sidebar .sidebar-menu > li > a {
  color: #ffffff !important;
  border-left: 3px solid transparent;
  transition: all 0.3s ease;
}

.sidebar .sidebar-menu > li.active > a,
.sidebar .sidebar-menu > li:hover > a {
  background: rgba(255, 255, 255, 0.15) !important;
  border-left: 3px solid #00A39A !important;
}

/* Header */
.main-header, .main-header .navbar {
  background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
}

.main-header .logo {
  background: linear-gradient(135deg, #002C3C 0%, #008A82 50%, #00A39A 100%) !important;
  color: #ffffff !important;
  font-weight: 600;
}

/* Boxes */
.box {
  background: rgba(255, 255, 255, 0.98) !important;
  border: none !important;
  border-radius: 12px !important;
  box-shadow: 0 8px 25px rgba(0, 44, 60, 0.2) !important;
  margin-bottom: 20px;
  transition: transform 0.2s ease;
}

.box:hover {
  transform: translateY(-2px);
  box-shadow: 0 12px 35px rgba(0, 44, 60, 0.3) !important;
}

.box-header {
  background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
  color: white !important;
  border-radius: 12px 12px 0 0 !important;
  padding: 15px 20px;
}

.box-title {
  color: #ffffff !important;
  font-weight: 600;
  font-size: 16px;
}

.box-body {
  background-color: #ffffff !important;
  padding: 20px;
}

/* Status Boxes */
.status-success {
  background: linear-gradient(135deg, #d4edda 0%, #c3e6cb 100%) !important;
  color: #155724 !important;
  padding: 15px;
  border-radius: 12px !important;
  border-left: 4px solid #00A39A !important;
  margin: 10px 0;
}

.status-error {
  background: linear-gradient(135deg, #f8d7da 0%, #f5c6cb 100%) !important;
  color: #721c24 !important;
  padding: 15px;
  border-radius: 12px !important;
  border-left: 4px solid #e74c3c !important;
  margin: 10px 0;
}

.status-info {
  background: linear-gradient(135deg, #d1ecf1 0%, #bee5eb 100%) !important;
  color: #0c5460 !important;
  padding: 15px;
  border-radius: 12px !important;
  border-left: 4px solid #17a2b8 !important;
  margin: 10px 0;
}

.status-warning {
  background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%) !important;
  color: #856404 !important;
  padding: 15px;
  border-radius: 12px !important;
  border-left: 4px solid #f39c12 !important;
  margin: 10px 0;
}

/* Form Controls */
.form-control {
  border-radius: 8px !important;
  border: 2px solid #ddd !important;
  transition: border-color 0.3s ease;
}

.form-control:focus {
  border-color: #008A82 !important;
  box-shadow: 0 0 0 3px rgba(0, 138, 130, 0.1) !important;
}

/* Buttons */
.btn-primary {
  background: linear-gradient(135deg, #008A82 0%, #00A39A 100%) !important;
  border: none !important;
  border-radius: 8px !important;
  color: white !important;
  font-weight: 600;
  transition: transform 0.2s ease;
}

.btn-primary:hover {
  background: linear-gradient(135deg, #006b63 0%, #007d75 100%) !important;
  transform: translateY(-1px);
}

.btn-success {
  background: linear-gradient(135deg, #00A39A 0%, #008A82 100%) !important;
  border: none !important;
  border-radius: 8px !important;
  color: white !important;
  font-weight: 600;
}

.btn-info {
  background: linear-gradient(135deg, #3498db 0%, #2980b9 100%) !important;
  border: none !important;
  border-radius: 8px !important;
  color: white !important;
  font-weight: 600;
}

.btn-danger {
  background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%) !important;
  border: none !important;
  border-radius: 8px !important;
  color: white !important;
}

.btn-warning {
  background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%) !important;
  border: none !important;
  border-radius: 8px !important;
  color: white !important;
}
```

---

## TROUBLESHOOTING GUIDE

### Module Not Appearing

1. Check `_module_registry.yml` - is `enabled: true`?
2. Check `manifest.yml` - is module ID correct?
3. Check function names - must be `{module_id}_ui` and `{module_id}_server`
4. Check console for errors during module loading

### Dropdowns Not Populating

1. Is authentication successful? Check `api_manager$authenticated`
2. Is reactive trigger being called? Add `cat()` statements
3. Check `observe()` block - is it watching `state_trigger()`?
4. Check query syntax - run directly in R console
5. Check for SQL injection - escape user input

### Namespace Conflicts

1. Are ALL IDs in UI wrapped with `ns()`?
2. Is server using `moduleServer()`?
3. Check for duplicate module IDs in registry

### API Calls Failing

1. Check credentials are set correctly
2. Test API calls outside of Shiny first
3. Check network access / firewall
4. Verify API quotas / rate limits
5. Check error messages from API

---

## VERSION HISTORY

- **v2.0** - Complete rewrite with API integration patterns, reactive triggers
- **v1.0** - Original modular template

---

## SUPPORT & RESOURCES

### Key Concepts to Understand

1. **Reactive Programming** - How Shiny updates UI based on state changes
2. **Namespacing** - How `NS()` prevents ID conflicts
3. **R6 Classes** - Object-oriented programming in R
4. **Module Pattern** - Self-contained UI + Server pairs

### Recommended Reading

- Mastering Shiny (Hadley Wickham)
- R6 Documentation
- BigQuery R Client Docs
- Anthropic API Documentation

---

**END OF TEMPLATE**

This template provides everything needed to build production-ready modular Shiny applications with external API integrations. Follow the patterns exactly for best results!
