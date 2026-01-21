# Application Structure and Architecture

## Overview

This Receipt Processor application follows a modular Shiny architecture, separating concerns into distinct modules, utilities, and UI components. This approach provides:

- **Maintainability**: Each module is self-contained and easier to update
- **Reusability**: Modules can be reused across different applications
- **Scalability**: New features can be added as new modules
- **Testing**: Individual modules can be tested independently
- **Collaboration**: Multiple developers can work on different modules simultaneously

## Directory Structure

```
receipt-processor/
│
├── app.R                          # Main application entry point
│
├── modules/                       # Shiny modules (UI + Server logic)
│   ├── settings_module.R
│   ├── pdf_converter_module.R
│   ├── to_pdf_converter_module.R
│   ├── upload_module.R
│   ├── data_view_module.R
│   └── categorize_module.R
│
├── utils/                         # Utility functions
│   ├── api_utils.R               # OpenAI API interactions
│   └── file_utils.R              # File handling operations
│
├── ui/                           # UI components
│   └── styles.R                  # CSS styling
│
├── receipts/                     # Created at runtime - stores receipt files
├── categorized_receipts/         # Created by user - organized receipts
├── converted_images/             # Created by user - PDF to JPG outputs
├── receipt_data.xlsx            # Created at runtime - data storage
│
├── README.md                     # Usage documentation
└── STRUCTURE.md                  # This file - architecture documentation
```

## Main Application (app.R)

The `app.R` file serves as the orchestrator:

```r
# Sources all dependencies
source("modules/*.R")
source("utils/*.R")
source("ui/styles.R")

# Defines UI using modules
ui <- dashboardPage(...)

# Coordinates server logic
server <- function(input, output, session) {
  # Shared reactive values
  shared_rv <- reactiveValues(...)
  
  # Initialize application
  observe({...})
  
  # Call module servers
  settingsServer("settings", shared_rv)
  pdfConverterServer("pdf_converter", shared_rv)
  # ... other modules
}
```

## Module Pattern

Each module follows the standard Shiny module pattern with UI and Server functions:

### Module UI Function
```r
moduleUI <- function(id) {
  ns <- NS(id)  # Namespace function
  
  # Return UI elements with namespaced IDs
  tagList(
    box(
      title = "Module Title",
      # UI elements with ns() wrapper
      actionButton(ns("button_id"), "Click Me")
    )
  )
}
```

### Module Server Function
```r
moduleServer <- function(id, shared_rv) {
  moduleServer(id, function(input, output, session) {
    # Local reactive values
    rv <- reactiveValues(...)
    
    # Observers and outputs
    observeEvent(input$button_id, {
      # Access shared state: shared_rv$api_key
      # Modify local state: rv$local_var
    })
  })
}
```

## Modules Description

### 1. Settings Module (`settings_module.R`)
**Purpose**: Configuration management and API setup

**UI Elements:**
- API key input (password field)
- Receipts folder path
- Excel filename configuration
- Save/Test buttons

**Server Logic:**
- Saves configuration to shared reactive values
- Validates API key format
- Tests OpenAI API connection
- Creates necessary folders

**Shared State Access:**
- Writes: `shared_rv$api_key`, `shared_rv$receipts_folder`, `shared_rv$excel_filename`

### 2. PDF Converter Module (`pdf_converter_module.R`)
**Purpose**: Convert PDF files to JPG images

**UI Elements:**
- File upload input (multiple PDFs)
- DPI quality selector
- Output path configuration
- Conversion results table

**Server Logic:**
- Validates required packages (pdftools, magick)
- Creates output directory
- Converts each PDF page to JPG
- Displays conversion results

**Local State:**
- `rv$conversion_results`: Stores conversion outcomes

### 3. To PDF Converter Module (`to_pdf_converter_module.R`)
**Purpose**: Convert image files to PDF format

**UI Elements:**
- Input type selector (files/folder)
- File browser for input folder
- Page size selector (A4/Letter)
- File browser for output folder
- Conversion results table

**Server Logic:**
- Initializes folder browsers with proper volumes
- Handles folder selection
- Validates image files in folder
- Converts images to PDF at 300 DPI
- Maintains aspect ratio

**Local State:**
- `rv$selected_input_folder`: Selected input folder path
- `rv$selected_output_folder`: Selected output folder path
- `rv$pdf_conversion_results`: Conversion results

### 4. Upload Module (`upload_module.R`)
**Purpose**: Upload and process receipts using AI

**UI Elements:**
- File upload (max 5 JPG/JPEG files)
- Process button
- Status display
- Results table

**Server Logic:**
- Validates API key presence
- Limits file uploads to 5
- Calls OpenAI Vision API for each receipt
- Extracts structured data (provider, amount, date, description)
- Generates smart filenames
- Appends to Excel file

**Shared State Access:**
- Reads: `shared_rv$api_key`, `shared_rv$receipts_folder`, `shared_rv$excel_filename`

**Local State:**
- `rv$current_results`: Current processing batch results

**Key Features:**
- Smart description extraction for trains (origin to destination)
- Smart description extraction for accommodation (city name)
- Numeric amount extraction (removes currency symbols)
- Descriptive filename generation

### 5. Data View Module (`data_view_module.R`)
**Purpose**: View and export all processed data

**UI Elements:**
- Refresh button
- Download Excel button
- Interactive data table with filters

**Server Logic:**
- Loads data from Excel file
- Provides sorting and filtering
- Exports data with timestamp

**Shared State Access:**
- Reads: `shared_rv$excel_filename`

**Local State:**
- `rv$all_data`: Cached Excel data

### 6. Categorize Module (`categorize_module.R`)
**Purpose**: Categorize receipts and organize files

**UI Elements:**
- Category path configuration
- Editable data table
- Save/Copy/Refresh buttons
- Category totals display

**Server Logic:**
- Auto-loads data if not present
- Implements radio button behavior (one category per receipt)
- Calculates category totals in real-time
- Saves categories to Excel
- Copies files to category folders

**Shared State Access:**
- Reads: `shared_rv$excel_filename`, `shared_rv$receipts_folder`

**Local State:**
- `rv$categorize_data`: Data with categories
- `rv$category_totals`: Calculated totals per category

**Category Columns:**
- Labour
- Overheads
- Materials
- Capital_Usage
- TS (Travel & Subsistence)
- Contractor

## Utility Functions

### API Utils (`utils/api_utils.R`)

**Functions:**
- `encode_file(file_path)`: Base64 encoding for API transmission
- `get_media_type(filename)`: Determines MIME type from extension
- `call_openai_api(file_path, filename, api_key)`: Main API call function
- `test_api_connection(api_key)`: Validates API connectivity

**API Request Structure:**
```json
{
  "model": "gpt-4o",
  "messages": [
    {
      "role": "user",
      "content": [
        {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,..."}},
        {"type": "text", "text": "Analyze this receipt..."}
      ]
    }
  ],
  "max_tokens": 500
}
```

**API Response Handling:**
- Status 200: Success, parse JSON response
- Status 401: Invalid API key
- Status 429: Rate limit exceeded
- Status 400: Bad request
- Other: Generic error

### File Utils (`utils/file_utils.R`)

**Functions:**
- `create_safe_filename(text, max_length)`: Sanitizes filenames
- `create_renamed_filename(provider, description, date, amount, ext)`: Generates descriptive names
- `get_smart_description(provider, description, api_key)`: Extracts contextual descriptions
- `get_folder_volumes()`: Platform-specific folder browser setup

**Filename Generation Logic:**
1. Clean provider name (max 50 chars)
2. Clean description (max 40 chars)
3. Format date as YYYYMMDD
4. Format amount as decimal
5. Combine: `Provider_Description_Date_Amount.ext`

## UI Components

### Styles (`ui/styles.R`)

**CSS Theme:**
- Color palette: Deep blue gradient with purple accents
- Gradient backgrounds for all components
- Hover effects and transitions
- Custom scrollbar styling
- Responsive box shadows

**Color Variables:**
```css
--deep-blue: #0a1128
--dark-blue: #1e3c72
--medium-blue: #2a5298
--bright-blue: #4a90e2
--light-blue: #7ec8e3
--purple-light: #764ba2
```

## Data Flow

### Receipt Processing Flow

```
1. User uploads receipt (Upload Module)
   ↓
2. Generate temporary filename
   ↓
3. Call OpenAI Vision API (API Utils)
   ↓
4. Extract structured data
   ↓
5. Generate smart description (File Utils)
   ↓
6. Create descriptive filename (File Utils)
   ↓
7. Save file with new name (receipts folder)
   ↓
8. Append to Excel file
   ↓
9. Display results in table
```

### Categorization Flow

```
1. Load data from Excel (Categorize Module)
   ↓
2. Display in editable table
   ↓
3. User edits categories
   ↓
4. Calculate totals in real-time
   ↓
5. Save to Excel
   ↓
6. Copy files to category folders
```

## Shared State Management

### Shared Reactive Values (`shared_rv`)

```r
shared_rv <- reactiveValues(
  api_key = NULL,              # OpenAI API key
  receipts_folder = "receipts", # Receipts storage path
  excel_filename = "receipt_data.xlsx"  # Data file name
)
```

**Access Pattern:**
- Settings Module: Writes all values
- Upload Module: Reads all values
- Data View Module: Reads `excel_filename`
- Categorize Module: Reads `excel_filename` and `receipts_folder`

### Module-Local State

Each module maintains its own reactive values for:
- UI state (selections, inputs)
- Processing results
- Temporary data
- Display data

## Error Handling

### API Errors
- Connection failures: Wrapped in `tryCatch`
- HTTP status codes: Specific error messages
- JSON parsing: Fallback error handling

### File Operations
- Folder creation: `dir.create(recursive = TRUE)`
- File existence checks: `file.exists()`, `dir.exists()`
- Path validation: Platform-specific handling

### User Feedback
- `showNotification()`: Success/error messages
- `showModal()`: Critical errors requiring user action
- Progress bars: `withProgress()` for long operations
- Status displays: `renderUI()` for detailed status

## Testing Approach

### Module Testing
Each module can be tested independently:

```r
# Test individual module
library(shiny)

# Create test shared_rv
test_shared_rv <- reactiveValues(
  api_key = "test-key",
  receipts_folder = "test_receipts",
  excel_filename = "test_data.xlsx"
)

# Create minimal UI
ui <- fluidPage(
  settingsUI("test")
)

# Test server
server <- function(input, output, session) {
  settingsServer("test", test_shared_rv)
}

shinyApp(ui, server)
```

### Integration Testing
Test module interactions through shared state:

```r
# Test that Settings module affects Upload module
# 1. Set API key in Settings
# 2. Verify Upload module can access it
# 3. Test receipt processing
```

## Extension Points

### Adding New Modules

1. Create module file in `modules/` directory
2. Define `moduleUI()` and `moduleServer()` functions
3. Add menu item in `app.R` sidebar
4. Add `tabItem` in `app.R` dashboard body
5. Call module server in `app.R` server function

### Adding New Utilities

1. Create utility file in `utils/` directory
2. Define standalone functions
3. Source in `app.R`
4. Use in modules as needed

### Adding New Styles

1. Update `ui/styles.R`
2. Add CSS rules inside `tags$style(HTML(...))`
3. Use consistent color palette

## Performance Considerations

### API Calls
- Batch processing with progress bars
- Rate limiting awareness (429 errors)
- Timeout settings (60 seconds)

### File Operations
- Async file copies where possible
- Progress feedback for large batches
- Lazy loading of data tables

### Data Management
- Excel file grows with each receipt
- Consider periodic archiving
- Index-based row identification

## Security Notes

### API Key Storage
- Stored in reactive value (memory only)
- Not persisted to disk
- Password input field (masked)

### File Access
- User-controlled paths
- No arbitrary system access
- Folder creation with validation

### Data Privacy
- Local processing only
- OpenAI API: Review their data usage policy
- Excel file contains sensitive financial data

## Future Enhancements

### Potential Modules
- **Analytics Module**: Spending analytics and charts
- **Export Module**: Multiple format exports (CSV, JSON, PDF reports)
- **Batch Import Module**: Import from email, cloud storage
- **OCR Module**: Alternative to API for offline processing
- **Template Module**: Custom receipt templates and fields

### Potential Features
- Multi-user support with authentication
- Database backend (SQLite, PostgreSQL)
- Real-time collaboration
- Mobile app integration
- Automated backups
- Email notifications
- Receipt image quality checking
- Duplicate detection
- Currency conversion
- Multi-language support

## Maintenance Guidelines

### Code Style
- Use consistent indentation (2 spaces)
- Comment complex logic
- Use descriptive variable names
- Follow Shiny module conventions

### Version Control
- Commit atomic changes
- Write descriptive commit messages
- Tag releases with version numbers
- Maintain CHANGELOG.md

### Documentation
- Update README.md for user-facing changes
- Update STRUCTURE.md for architecture changes
- Comment complex functions
- Maintain inline documentation

## Troubleshooting Guide

### Module Not Loading
- Check `source()` statement in app.R
- Verify file path
- Check for syntax errors

### Shared State Issues
- Verify `shared_rv` is passed to module
- Check reactive value names
- Use `isolate()` for non-reactive access

### UI Not Updating
- Verify output is rendered
- Check namespace usage: `ns()`
- Ensure reactive dependencies

### Module Communication
- Use shared reactive values
- Consider reactive events
- Implement proper isolation

This architecture provides a solid foundation for maintaining and extending the Receipt Processor application while keeping code organized, testable, and maintainable.
