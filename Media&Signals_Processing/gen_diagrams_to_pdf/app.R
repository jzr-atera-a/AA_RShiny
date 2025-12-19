library(shiny)
library(shinydashboard)
library(shinyFiles)
library(pagedown)
library(httr)
library(jsonlite)
library(base64enc)

# Instructions for Claude to generate professional diagrams
DIAGRAM_INSTRUCTIONS <- "
# Professional HTML Diagram Generation Instructions

Generate a complete, standalone HTML document with the following specifications:

## CRITICAL PAGE BOUNDARY REQUIREMENTS (MUST FOLLOW):

### Step 1: Calculate Safe Content Area BEFORE generating content
- User will specify: [PAGE_SIZE] with [ORIENTATION]
- Calculate exact content area dimensions AFTER accounting for all margins/padding
- Example for A4 Portrait: If page is 210mm × 297mm and you use 15mm margins, content area = 180mm × 267mm
- ALL content must fit within this calculated safe area - NO EXCEPTIONS

### Step 2: Page Container Setup (MANDATORY)
```css
body {
  margin: 0;
  padding: 0;
  width: [EXACT_PAGE_WIDTH];
  height: [EXACT_PAGE_HEIGHT];
  overflow: hidden; /* CRITICAL: Prevents content from exceeding page */
  box-sizing: border-box;
}

.page-container {
  width: 100%;
  height: 100%;
  padding: 15mm; /* Adjust based on page size */
  box-sizing: border-box;
  overflow: hidden; /* CRITICAL: Hard boundary */
  display: flex;
  flex-direction: column;
}
```

### Step 3: Content Distribution Strategy
- Calculate how many content sections you have
- Divide available height proportionally: available_height / number_of_sections
- Use max-height on each section to enforce boundaries
- Use overflow: hidden or overflow: auto on sections if needed
- Leave NO empty space - utilize 95-98% of available area

### Step 4: Validation Checklist (Complete BEFORE finalizing)
✅ Calculate exact page dimensions from user input
✅ Calculate safe content area (page dimensions minus margins)
✅ Count all content sections and calculate height allocation
✅ Verify total content height ≤ safe content height
✅ Add overflow: hidden to body and container
✅ Test that no element has position: absolute that could escape boundaries
✅ Ensure no margins collapse beyond container
✅ Verify grid/flex layouts don't expand beyond container

## Document Structure:
- Complete HTML5 document with <!DOCTYPE html>
- Include viewport meta tag: <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
- Single-file output (all CSS inline in <style> tags)
- No external dependencies except standard web fonts

## Page Dimensions (Reference):
- For A4: width: 210mm, height: 297mm
- For Letter: width: 8.5in, height: 11in
- For 16:9 PPT: width: 10in, height: 5.625in
- For 4:3 PPT: width: 10in, height: 7.5in
- For Legal: width: 8.5in, height: 14in
- For Tabloid: width: 11in, height: 17in

## CSS Template (MUST USE):
```css
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  width: [PAGE_WIDTH];
  height: [PAGE_HEIGHT];
  margin: 0;
  padding: 0;
  overflow: hidden;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  background: white;
}

.page-container {
  width: 100%;
  height: 100%;
  padding: 12mm; /* Adjust based on page size */
  display: flex;
  flex-direction: column;
  gap: 6mm;
  overflow: hidden;
}

.header {
  flex-shrink: 0;
  /* Fixed height calculated based on content */
}

.content-area {
  flex: 1;
  min-height: 0; /* Important for flex child */
  overflow: hidden;
  display: flex;
  flex-direction: column;
  gap: 4mm;
}

.section {
  flex: 1;
  min-height: 0;
  overflow: auto; /* Allow scroll if content is dense */
  border-radius: 6px;
  padding: 6mm;
}
```

## Professional Styling:
1. **Typography**: Use 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif
2. **Color Schemes**: Use gradients and complementary colors
   - Headers: linear-gradient(135deg, #667eea 0%, #764ba2 100%)
   - Sections: Use color-coded boxes with border-left: 4px solid
   - Background: white with colored section backgrounds
3. **Spacing**: Proper padding (6-12mm), margins (3-6mm between elements)
4. **Modern Design**: 
   - border-radius: 6-8px for boxes
   - box-shadow: 0 2px 5px rgba(0,0,0,0.1)
   - Smooth transitions and hover effects

## Content Boxes:
- Use colored gradient backgrounds for different sections
- Green gradients: #e8f5e9 to #c8e6c9 (success/completion)
- Blue gradients: #e3f2fd to #bbdefb (information)
- Orange gradients: #fff3e0 to #ffe0b2 (highlights)
- Purple gradients: #f3e5f5 to #e1bee7 (special)

## Typography Hierarchy (Scale based on page size):
- Main title: 16-20px (portrait) or 14-18px (landscape), bold, centered
- Section titles: 12-14px, bold, colored
- Body text: 9-10px, normal weight
- Small text: 7-8px for fine details
- Adjust font sizes DOWN if page is landscape or PPT format

## Space Utilization Strategy:
1. **NO empty space**: Aim for 95-98% utilization of available area
2. **Distribute evenly**: Use CSS flexbox with flex: 1 for equal distribution
3. **Dense layouts**: Use CSS Grid with auto-fit for maximum space usage
4. **Compact spacing**: Reduce gaps/padding for landscape/PPT formats
5. **Multi-column**: Use 2-3 columns for wide layouts to maximize space

## Layout Patterns:
- Grid layouts: display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr))
- Flexbox for horizontal arrangements: display: flex; gap: 8px;
- Proper spacing with gap property instead of margins
- Use flex: 1 to distribute space evenly among sections

## Tables (if needed):
- border-collapse: collapse
- Colored headers with white text
- Compact padding: 4-6px in cells
- Font-size: 8-9px for table content
- Border styling: 1px solid #ddd

## Icons:
- Use emoji icons for visual appeal (✅ 📊 💰 🎯 etc.)
- Or use text-based icons in colored circles

## Print Optimization:
```css
@media print {
  body {
    margin: 0;
    padding: 0;
  }
  .page-container {
    page-break-inside: avoid;
  }
  .section {
    page-break-inside: avoid;
  }
}
```

## Footer:
- Include centered footer with project name
- Small font (8-9px)
- Subtle color (#666)
- Fixed at bottom: position: absolute; bottom: 8mm;

## MANDATORY Pre-Generation Checklist:
1. ✅ Read user's page size and orientation
2. ✅ Calculate exact page dimensions
3. ✅ Calculate safe content area (page - margins)
4. ✅ Count content sections needed
5. ✅ Calculate height per section (safe_height / sections)
6. ✅ Apply overflow: hidden to body and container
7. ✅ Use flexbox with flex: 1 for space distribution
8. ✅ Set max-height constraints on all sections
9. ✅ Verify no content can escape boundaries
10. ✅ Ensure 95%+ space utilization, no large empty areas

## Final Validation Before Responding:
- Does body have overflow: hidden? 
- Does page-container have overflow: hidden?
- Are all sections using flex: 1 or calculated heights?
- Is there a max-height on each section?
- Will all content fit within the safe area?
- Is the space >95% utilized?

Generate complete, valid HTML that STAYS WITHIN the specified page boundaries with NO content overflow and NO wasted empty space.
"

ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = "HTML Diagram & PDF Tool"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Claude API Setup", tabName = "api_setup", icon = icon("key")),
      menuItem("Generate Diagram", tabName = "generate", icon = icon("magic")),
      menuItem("Convert to PDF", tabName = "converter", icon = icon("file-pdf")),
      menuItem("Help", tabName = "help", icon = icon("question-circle"))
    )
  ),
  dashboardBody(
    tags$head(
      tags$style(HTML("
      .skin-blue .main-header .navbar {
        background-color: #008A82 !important;
      }
      .skin-blue .main-header .logo {
        background-color: #002C3C !important;
      }
      .skin-blue .main-header .logo:hover {
        background-color: #008A82 !important;
      }
      .skin-blue .main-sidebar {
        background-color: #00A39A !important;
      }
      .skin-blue .sidebar-menu > li.header {
        background: #008A82 !important;
        color: white !important;
      }
      .skin-blue .sidebar-menu > li > a {
        color: white !important;
      }
      .skin-blue .sidebar-menu > li:hover > a,
      .skin-blue .sidebar-menu > li.active > a {
        background-color: #008A82 !important;
        color: white !important;
      }
      .content-wrapper, .right-side {
        background-color: #002C3C !important;
      }
      .box {
        background: #00A39A !important;
        border-top: none !important;
        color: white !important;
      }
      .box-header {
        background: #00A39A !important;
        color: white !important;
      }
      .box-body {
        background: white !important;
        color: #2c3e50 !important;
      }
      .box-title {
        color: white !important;
      }
      .metric-box {
        background: white;
        border-radius: 8px;
        padding: 15px;
        margin: 10px 0;
        border-left: 4px solid #00A39A;
        box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        color: #2c3e50 !important;
      }
      .form-control {
        background-color: rgba(255,255,255,0.9) !important;
        border: 1px solid #bdc3c7 !important;
        color: #2c3e50 !important;
      }
      .form-control:focus {
        border-color: #008A82 !important;
        box-shadow: 0 0 0 0.2rem rgba(0, 163, 154, 0.25) !important;
      }
      .info-box {
        background: #f8f9fa;
        border: 1px solid #dee2e6;
        border-radius: 8px;
        padding: 15px;
        margin: 20px 0;
        font-size: 0.9em;
        color: #495057;
      }
      .info-box h5 {
        color: #00A39A;
        margin-bottom: 10px;
        font-weight: bold;
      }
      .btn-primary {
        background-color: #008A82 !important;
        border-color: #008A82 !important;
      }
      .btn-primary:hover {
        background-color: #00A39A !important;
        border-color: #00A39A !important;
      }
      .btn-success {
        background-color: #4CAF50 !important;
        border-color: #4CAF50 !important;
      }
      .btn-success:hover {
        background-color: #45a049 !important;
        border-color: #45a049 !important;
      }
      .btn-warning {
        background-color: #ff9800 !important;
        border-color: #ff9800 !important;
        color: white !important;
      }
      .btn-warning:hover {
        background-color: #e68900 !important;
        border-color: #e68900 !important;
      }
      .directory-display {
        background-color: #f8f9fa;
        border: 1px solid #dee2e6;
        border-radius: 4px;
        padding: 10px;
        min-height: 40px;
        font-family: monospace;
        color: #495057;
        word-break: break-all;
      }
      .file-list-item {
        background: #f8f9fa;
        border-left: 3px solid #00A39A;
        padding: 10px;
        margin: 5px 0;
        border-radius: 4px;
      }
      .transferred-file-item {
        background: #e3f2fd;
        border-left: 3px solid #2196F3;
        padding: 10px;
        margin: 5px 0;
        border-radius: 4px;
      }
      .alert-success {
        background: #d4edda;
        color: #155724;
        border: 1px solid #c3e6cb;
        border-radius: 4px;
        padding: 12px;
        margin: 10px 0;
      }
      .alert-danger {
        background: #f8d7da;
        color: #721c24;
        border: 1px solid #f5c6cb;
        border-radius: 4px;
        padding: 12px;
        margin: 10px 0;
      }
      .alert-info {
        background: #d1ecf1;
        color: #0c5460;
        border: 1px solid #bee5eb;
        border-radius: 4px;
        padding: 12px;
        margin: 10px 0;
      }
      .alert-warning {
        background: #fff3cd;
        color: #856404;
        border: 1px solid #ffeaa7;
        border-radius: 4px;
        padding: 12px;
        margin: 10px 0;
      }
      .file-input-box {
        border: 2px dashed #cbd5e0;
        border-radius: 8px;
        padding: 20px;
        text-align: center;
        background: #f8f9fa;
        transition: all 0.3s ease;
      }
      .file-input-box:hover {
        border-color: #00A39A;
        background: #fff;
      }
      h4.box-title {
        font-weight: 600;
      }
      .help-section {
        background: white;
        border-radius: 8px;
        padding: 20px;
        margin-bottom: 20px;
        color: #2c3e50;
      }
      .help-section h3 {
        color: #00A39A;
        margin-bottom: 15px;
      }
      .help-section ul {
        margin-left: 20px;
      }
      .help-section li {
        margin-bottom: 8px;
      }
      .page-range-group {
        display: flex;
        align-items: center;
        gap: 10px;
      }
      .page-range-group label {
        margin: 0;
        font-weight: 600;
        color: #2c3e50;
      }
      .page-range-group select {
        width: 80px;
      }
      .api-status-connected {
        background: #d4edda;
        color: #155724;
        border: 1px solid #c3e6cb;
        border-radius: 4px;
        padding: 10px;
        margin: 10px 0;
        font-weight: 600;
      }
      .api-status-disconnected {
        background: #f8d7da;
        color: #721c24;
        border: 1px solid #f5c6cb;
        border-radius: 4px;
        padding: 10px;
        margin: 10px 0;
        font-weight: 600;
      }
      .html-preview {
        border: 2px solid #dee2e6;
        border-radius: 8px;
        min-height: 500px;
        max-height: 800px;
        overflow: auto;
        background: white;
        padding: 0;
      }
      .html-preview iframe {
        width: 100%;
        min-height: 500px;
        border: none;
      }
      .code-display {
        background: #f8f9fa;
        border: 1px solid #dee2e6;
        border-radius: 4px;
        padding: 15px;
        font-family: 'Courier New', monospace;
        font-size: 12px;
        max-height: 400px;
        overflow: auto;
        white-space: pre-wrap;
        word-wrap: break-word;
      }
      .status-badge {
        display: inline-block;
        padding: 5px 12px;
        border-radius: 12px;
        font-size: 11px;
        font-weight: 600;
        margin-left: 10px;
      }
      .status-badge-success {
        background: #d4edda;
        color: #155724;
      }
      .status-badge-danger {
        background: #f8d7da;
        color: #721c24;
      }
      .instruction-box {
        background: #e3f2fd;
        border-left: 4px solid #2196F3;
        padding: 15px;
        border-radius: 4px;
        margin: 15px 0;
      }
      .instruction-box h5 {
        color: #1976D2;
        margin-bottom: 10px;
      }
      textarea.custom-instructions {
        min-height: 150px;
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      }
      .source-indicator {
        display: inline-block;
        padding: 3px 8px;
        border-radius: 10px;
        font-size: 10px;
        font-weight: 600;
        margin-left: 8px;
      }
      .source-generated {
        background: #e3f2fd;
        color: #1976D2;
      }
      .source-uploaded {
        background: #f3e5f5;
        color: #7b1fa2;
      }
    "))
    ),
    tabItems(
      # API Setup Tab
      tabItem(
        tabName = "api_setup",
        fluidRow(
          box(
            title = "Anthropic Claude API Configuration",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "info-box",
                tags$h5("About API Keys"),
                HTML("To use this diagram generation feature, you need an Anthropic Claude API key. 
                     <br>Get your API key from: <a href='https://console.anthropic.com/' target='_blank'>https://console.anthropic.com/</a>
                     <br><br>Your API key will be stored only for the current session and is not saved to disk.")
            ),
            fluidRow(
              column(8,
                     textInput("api_key", 
                               label = tags$label("Claude API Key:", style = "font-weight: 600; color: #2c3e50;"),
                               value = "",
                               placeholder = "sk-ant-api03-...",
                               width = "100%")
              ),
              column(4,
                     br(),
                     actionButton("test_api", "Test Connection", 
                                  class = "btn btn-primary", 
                                  icon = icon("plug"),
                                  style = "margin-top: 5px;"),
                     actionButton("save_api", "Save API Key", 
                                  class = "btn btn-success", 
                                  icon = icon("save"),
                                  style = "margin-top: 5px; margin-left: 10px;")
              )
            ),
            uiOutput("api_status_ui"),
            hr(style = "border-color: #dee2e6;"),
            fluidRow(
              column(6,
                     selectInput("claude_model",
                                 label = tags$label("Claude Model:", style = "font-weight: 600; color: #2c3e50;"),
                                 choices = c(
                                   "Claude Sonnet 4 (Recommended)" = "claude-sonnet-4-20250514",
                                   "Claude Sonnet 3.5" = "claude-3-5-sonnet-20241022",
                                   "Claude Opus 3" = "claude-3-opus-20240229"
                                 ),
                                 selected = "claude-sonnet-4-20250514"
                     )
              ),
              column(6,
                     numericInput("max_tokens",
                                  label = tags$label("Max Tokens:", style = "font-weight: 600; color: #2c3e50;"),
                                  value = 4096,
                                  min = 1024,
                                  max = 8192,
                                  step = 512
                     )
              )
            )
          )
        )
      ),
      
      # Generate Diagram Tab
      tabItem(
        tabName = "generate",
        fluidRow(
          box(
            title = "Generate HTML Diagram with Claude",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            fluidRow(
              column(6,
                     selectInput("diagram_page_size",
                                 label = tags$label("Page Size:", style = "font-weight: 600; color: #2c3e50;"),
                                 choices = c(
                                   "A4 (210×297mm)" = "A4",
                                   "Letter (8.5×11in)" = "Letter",
                                   "16:9 Widescreen (PPT)" = "16:9",
                                   "4:3 Standard (PPT)" = "4:3",
                                   "Legal (8.5×14in)" = "Legal",
                                   "Tabloid (11×17in)" = "Tabloid"
                                 ),
                                 selected = "A4"
                     )
              ),
              column(6,
                     selectInput("diagram_orientation",
                                 label = tags$label("Orientation:", style = "font-weight: 600; color: #2c3e50;"),
                                 choices = c("Portrait" = "portrait", "Landscape" = "landscape"),
                                 selected = "portrait"
                     )
              )
            ),
            div(class = "instruction-box",
                tags$h5("What diagram would you like to create?"),
                HTML("<small>Describe the diagram you want Claude to generate. Be specific about the content, 
                     data, structure, and any visual preferences.</small>")
            ),
            textAreaInput("user_instructions",
                          label = tags$label("Diagram Instructions:", style = "font-weight: 600; color: #2c3e50;"),
                          value = "",
                          placeholder = "Example: Create a project timeline Gantt chart showing 5 work packages over 12 months, 
with color-coded bars for different teams. Include milestones and a legend.",
                          width = "100%",
                          height = "180px",
                          resize = "vertical"
            ),
            div(class = "file-input-box",
                fileInput("context_files", 
                          label = NULL,
                          multiple = TRUE, 
                          accept = c(".pdf", ".docx", ".doc", ".xlsx", ".xls", ".pptx", ".ppt", 
                                     ".txt", ".csv", ".jpg", ".jpeg", ".png", ".gif"),
                          width = "100%", 
                          buttonLabel = "Add Context Files (Optional)", 
                          placeholder = "Upload files to provide context (max 10 files)"
                )
            ),
            uiOutput("context_files_display"),
            hr(style = "border-color: #dee2e6;"),
            div(style = "text-align: center; padding: 15px;",
                actionButton("generate_diagram", "Generate Diagram with Claude", 
                             class = "btn btn-primary btn-lg",
                             icon = icon("magic"), 
                             style = "font-size: 18px; padding: 12px 40px;")
            ),
            uiOutput("generation_status")
          )
        ),
        fluidRow(
          box(
            title = "Generated HTML Preview",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            collapsed = FALSE,
            div(class = "html-preview",
                uiOutput("html_preview")
            ),
            hr(style = "border-color: #dee2e6;"),
            fluidRow(
              column(4,
                     downloadButton("download_html", "Download HTML File", 
                                    class = "btn btn-success",
                                    icon = icon("download"))
              ),
              column(4,
                     actionButton("copy_to_converter", "Send to PDF Converter", 
                                  class = "btn btn-primary",
                                  icon = icon("arrow-right"),
                                  style = "width: 100%;")
              ),
              column(4,
                     actionButton("clear_generated", "Clear Generated HTML", 
                                  class = "btn btn-warning",
                                  icon = icon("trash"),
                                  style = "width: 100%;")
              )
            )
          )
        )
      ),
      
      # Convert to PDF Tab
      tabItem(
        tabName = "converter",
        fluidRow(
          box(
            title = "HTML Files to Convert",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            # Transferred HTML from Generate tab
            uiOutput("transferred_html_display"),
            hr(style = "border-color: #dee2e6;"),
            # Upload HTML files
            div(class = "file-input-box",
                fileInput("html_files", NULL, multiple = TRUE, accept = c(".html", ".htm"),
                          width = "100%", buttonLabel = "Browse Files", 
                          placeholder = "Upload additional HTML files (optional)")
            ),
            uiOutput("uploaded_files_display"),
            hr(style = "border-color: #dee2e6;"),
            # Combined file list
            uiOutput("all_files_summary")
          )
        ),
        fluidRow(
          box(
            title = "PDF Conversion Settings",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            fluidRow(
              column(4,
                     tags$label("Output Folder:", style = "font-weight: 600; color: #2c3e50;"),
                     br(),
                     shinyDirButton("output_dir", "Select Folder", "Choose output directory",
                                    class = "btn btn-primary", icon = icon("folder-open"), style = "margin-top: 10px;"),
                     br(), br(),
                     div(class = "directory-display", textOutput("selected_dir_display"))
              ),
              column(4,
                     selectInput("page_size",
                                 label = tags$label("Page Size:", style = "font-weight: 600; color: #2c3e50;"),
                                 choices = c(
                                   "A4 (210×297mm)" = "A4",
                                   "Letter (8.5×11in)" = "Letter",
                                   "16:9 Widescreen" = "16:9",
                                   "4:3 Standard" = "4:3"
                                 ),
                                 selected = "A4"
                     ),
                     selectInput("orientation",
                                 label = tags$label("Orientation:", style = "font-weight: 600; color: #2c3e50;"),
                                 choices = c("Portrait (Vertical)" = "portrait", "Landscape (Horizontal)" = "landscape"),
                                 selected = "portrait"
                     )
              ),
              column(4,
                     div(class = "info-box",
                         tags$h5("Page Dimensions:"),
                         uiOutput("page_dimensions_info")
                     )
              )
            ),
            hr(style = "border-color: #dee2e6;"),
            fluidRow(
              column(4,
                     tags$label("Page Range:", style = "font-weight: 600; color: #2c3e50; display: block; margin-bottom: 10px;"),
                     div(class = "page-range-group",
                         tags$span("From page", style = "color: #2c3e50;"),
                         selectInput("page_from", NULL, choices = 1:20, selected = 1, width = "80px"),
                         tags$span("to page", style = "color: #2c3e50;"),
                         selectInput("page_to", NULL, choices = 1:20, selected = 1, width = "80px")
                     )
              ),
              column(4,
                     numericInput("scale_percent",
                                  label = tags$label("Scale (%):", style = "font-weight: 600; color: #2c3e50;"),
                                  value = 100,
                                  min = 10,
                                  max = 200,
                                  step = 5
                     )
              ),
              column(4,
                     div(class = "info-box", style = "margin-top: 0;",
                         tags$h5("Tips:"),
                         HTML("<small>Set page range to 1-1 to save only the first page and avoid blank pages.<br>
                        Scale 100% maintains original size.</small>")
                     )
              )
            )
          )
        ),
        fluidRow(
          box(
            title = "Convert to PDF",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            div(style = "text-align: center; padding: 20px;",
                actionButton("convert_btn", "Convert All to PDF", class = "btn btn-primary btn-lg",
                             icon = icon("file-pdf"), style = "font-size: 18px; padding: 12px 40px;"),
                br(), br(),
                actionButton("clear_all_files", "Clear All Files", class = "btn btn-warning",
                             icon = icon("times-circle"))
            ),
            uiOutput("progress_ui"),
            uiOutput("status_message")
          )
        )
      ),
      
      # Help Tab
      tabItem(
        tabName = "help",
        fluidRow(
          box(
            title = "User Guide",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            div(class = "help-section",
                h3("Getting Started with Claude API"),
                tags$ol(
                  tags$li(tags$strong("Get API Key:"), " Visit ", tags$a("Anthropic Console", href = "https://console.anthropic.com/", target = "_blank"), " to get your Claude API key."),
                  tags$li(tags$strong("Configure API:"), " Go to 'Claude API Setup' tab and enter your API key."),
                  tags$li(tags$strong("Test Connection:"), " Click 'Test Connection' to verify your API key works."),
                  tags$li(tags$strong("Save Settings:"), " Click 'Save API Key' to store it for the session.")
                )
            ),
            div(class = "help-section",
                h3("Generating Diagrams with Claude"),
                tags$ol(
                  tags$li(tags$strong("Select Page Size:"), " Choose the output format (A4, Letter, PPT formats, etc.)."),
                  tags$li(tags$strong("Describe Your Diagram:"), " Write clear instructions about what you want to create."),
                  tags$li(tags$strong("Add Context (Optional):"), " Upload files (Word, PDF, Excel, images) to provide additional context."),
                  tags$li(tags$strong("Generate:"), " Click 'Generate Diagram with Claude' and wait for the result."),
                  tags$li(tags$strong("Preview & Download:"), " View the generated HTML in the preview box and download it.")
                )
            ),
            div(class = "help-section",
                h3("Converting HTML to PDF - Two Ways"),
                tags$h4("Method 1: Transfer from Generate Tab", style = "color: #00A39A; margin-top: 15px;"),
                tags$ol(
                  tags$li("Generate a diagram in the 'Generate Diagram' tab"),
                  tags$li("Click 'Send to PDF Converter' button"),
                  tags$li("The HTML will be automatically loaded in the 'Convert to PDF' tab"),
                  tags$li("Configure PDF settings and convert")
                ),
                tags$h4("Method 2: Upload HTML Files", style = "color: #00A39A; margin-top: 15px;"),
                tags$ol(
                  tags$li("Go to 'Convert to PDF' tab"),
                  tags$li("Click 'Browse Files' to upload HTML files (up to 8 files)"),
                  tags$li("Configure PDF settings"),
                  tags$li("Convert to PDF")
                ),
                tags$h4("You can also combine both methods:", style = "color: #7b1fa2; margin-top: 15px;"),
                tags$ul(
                  tags$li("Transfer generated HTML from Generate tab"),
                  tags$li("Upload additional HTML files"),
                  tags$li("Convert all files together with the same settings")
                )
            ),
            div(class = "help-section",
                h3("Example Diagram Requests"),
                tags$ul(
                  tags$li(tags$strong("Gantt Chart:"), " 'Create a project Gantt chart with 8 work packages over 18 months, color-coded by partner organization'"),
                  tags$li(tags$strong("Budget Breakdown:"), " 'Generate a budget allocation diagram showing costs for 6 partners with percentages and visual breakdown'"),
                  tags$li(tags$strong("Risk Register:"), " 'Create a risk matrix showing 20 project risks categorized by likelihood and impact'"),
                  tags$li(tags$strong("Timeline:"), " 'Design a project timeline showing key milestones, deliverables, and dependencies'"),
                  tags$li(tags$strong("Org Chart:"), " 'Create an organizational structure diagram showing roles and reporting lines'")
                )
            ),
            div(class = "help-section",
                h3("Supported File Formats"),
                tags$ul(
                  tags$li(tags$strong("Context Files:"), " PDF, Word (docx/doc), Excel (xlsx/xls), PowerPoint (pptx/ppt), Text (txt/csv), Images (jpg/jpeg/png/gif)"),
                  tags$li(tags$strong("Output:"), " HTML files and PDF conversions"),
                  tags$li(tags$strong("Page Sizes:"), " A4, Letter, Legal, Tabloid, PowerPoint (16:9, 4:3)")
                )
            ),
            div(class = "help-section",
                h3("Tips for Best Results"),
                tags$ul(
                  tags$li("Be specific and detailed in your diagram instructions"),
                  tags$li("Include data, structure, and visual preferences in your request"),
                  tags$li("Upload relevant context files to help Claude understand your needs"),
                  tags$li("Use A4 or Letter for documents, 16:9 or 4:3 for presentations"),
                  tags$li("Preview the generated HTML before converting to PDF"),
                  tags$li("Set page range to 1-1 in PDF converter to avoid blank pages"),
                  tags$li("Use 'Send to PDF Converter' for seamless workflow from generation to PDF"),
                  tags$li("Clear generated HTML when done to start fresh")
                )
            )
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  rv <- reactiveValues(
    output_dir = NULL, 
    converting = FALSE,
    api_key = NULL,
    api_connected = FALSE,
    generated_html = NULL,
    generated_html_file = NULL,
    transferred_html_file = NULL,
    transferred_html_name = NULL
  )
  
  volumes <- c(Home = fs::path_home(), getVolumes()())
  if (.Platform$OS.type == "windows") {
    drive_letters <- LETTERS[3:26]
    for (letter in drive_letters) {
      drive_path <- paste0(letter, ":/")
      if (dir.exists(drive_path)) {
        volumes[[paste0(letter, ":")]] <- drive_path
      }
    }
  }
  
  shinyDirChoose(input, "output_dir", roots = volumes, session = session,
                 restrictions = system.file(package = "base"))
  
  observeEvent(input$output_dir, {
    if (!is.null(input$output_dir) && !is.integer(input$output_dir)) {
      dir_path <- parseDirPath(volumes, input$output_dir)
      if (length(dir_path) > 0) {
        rv$output_dir <- dir_path
      }
    }
  })
  
  # API Testing
  observeEvent(input$test_api, {
    if (is.null(input$api_key) || input$api_key == "") {
      showNotification("Please enter an API key", type = "error", duration = 5)
      return()
    }
    
    withProgress(message = 'Testing API connection...', value = 0.5, {
      tryCatch({
        response <- POST(
          url = "https://api.anthropic.com/v1/messages",
          add_headers(
            "x-api-key" = input$api_key,
            "anthropic-version" = "2023-06-01",
            "content-type" = "application/json"
          ),
          body = toJSON(list(
            model = input$claude_model,
            max_tokens = 100,
            messages = list(list(
              role = "user",
              content = "Say 'Hello' if you can read this."
            ))
          ), auto_unbox = TRUE),
          encode = "json"
        )
        
        if (status_code(response) == 200) {
          rv$api_connected <- TRUE
          showNotification("✓ API connection successful!", type = "message", duration = 5)
        } else {
          rv$api_connected <- FALSE
          error_content <- content(response, "text", encoding = "UTF-8")
          showNotification(paste("API test failed:", error_content), type = "error", duration = 10)
        }
      }, error = function(e) {
        rv$api_connected <- FALSE
        showNotification(paste("Connection error:", e$message), type = "error", duration = 10)
      })
    })
  })
  
  # Save API Key
  observeEvent(input$save_api, {
    if (is.null(input$api_key) || input$api_key == "") {
      showNotification("Please enter an API key", type = "error", duration = 5)
      return()
    }
    rv$api_key <- input$api_key
    showNotification("✓ API key saved for this session", type = "message", duration = 5)
  })
  
  # Generate Diagram with Claude
  observeEvent(input$generate_diagram, {
    if (is.null(rv$api_key) || rv$api_key == "") {
      showNotification("Please configure and save your API key first", type = "error", duration = 5)
      return()
    }
    if (is.null(input$user_instructions) || input$user_instructions == "") {
      showNotification("Please provide instructions for the diagram", type = "error", duration = 5)
      return()
    }
    
    withProgress(message = 'Generating diagram with Claude...', value = 0, {
      tryCatch({
        # Build the prompt
        page_dims <- get_page_dimensions_text(input$diagram_page_size, input$diagram_orientation)
        exact_dims <- get_exact_page_dimensions(input$diagram_page_size, input$diagram_orientation)
        
        user_prompt <- paste0(
          DIAGRAM_INSTRUCTIONS,
          "\n\n## SPECIFIC REQUIREMENTS FOR THIS DIAGRAM:\n",
          "Page Size: ", input$diagram_page_size, " (", input$diagram_orientation, ")\n",
          "Exact Page Dimensions: width: ", exact_dims$width, ", height: ", exact_dims$height, "\n",
          page_dims, "\n\n",
          "## MANDATORY STEPS BEFORE GENERATING:\n",
          "1. Set body width to ", exact_dims$width, " and height to ", exact_dims$height, "\n",
          "2. Set body overflow: hidden and margin: 0; padding: 0;\n",
          "3. Create .page-container with width: 100%; height: 100%; padding: 12mm; overflow: hidden;\n",
          "4. Use flexbox layout with flex: 1 for content sections\n",
          "5. Calculate: Available height = ", exact_dims$height, " - 24mm (top/bottom padding)\n",
          "6. Distribute content evenly to use 95-98% of available space\n",
          "7. Add overflow: auto to individual sections if content is dense\n",
          "8. VERIFY: No content exceeds page boundaries\n",
          "9. VERIFY: No large empty spaces remain\n\n",
          "User's Diagram Requirements:\n", input$user_instructions, "\n\n",
          "Generate a complete, professional HTML document that:\n",
          "- FITS PERFECTLY within ", exact_dims$width, " × ", exact_dims$height, "\n",
          "- Has NO content overflow beyond page boundaries\n",
          "- Utilizes 95-98% of available space with NO large empty areas\n",
          "- Uses the CSS template and validation checklist provided above"
        )
        
        # Prepare content array
        content_parts <- list(list(type = "text", text = user_prompt))
        
        # Add context files if provided
        if (!is.null(input$context_files) && nrow(input$context_files) > 0) {
          incProgress(0.1, detail = "Processing context files...")
          
          for (i in 1:min(nrow(input$context_files), 10)) {
            file_path <- input$context_files$datapath[i]
            file_ext <- tolower(tools::file_ext(input$context_files$name[i]))
            
            if (file_ext %in% c("jpg", "jpeg", "png", "gif")) {
              img_base64 <- base64encode(file_path)
              media_type <- paste0("image/", ifelse(file_ext == "jpg", "jpeg", file_ext))
              content_parts <- c(content_parts, list(list(
                type = "image",
                source = list(
                  type = "base64",
                  media_type = media_type,
                  data = img_base64
                )
              )))
            } else if (file_ext == "pdf") {
              pdf_base64 <- base64encode(file_path)
              content_parts <- c(content_parts, list(list(
                type = "document",
                source = list(
                  type = "base64",
                  media_type = "application/pdf",
                  data = pdf_base64
                )
              )))
            } else if (file_ext %in% c("txt", "csv")) {
              text_content <- readLines(file_path, warn = FALSE)
              text_content <- paste(text_content, collapse = "\n")
              content_parts <- c(content_parts, list(list(
                type = "text",
                text = paste0("\n\nContext from ", input$context_files$name[i], ":\n", text_content)
              )))
            }
          }
        }
        
        incProgress(0.3, detail = "Sending request to Claude...")
        
        # Call Claude API
        response <- POST(
          url = "https://api.anthropic.com/v1/messages",
          add_headers(
            "x-api-key" = rv$api_key,
            "anthropic-version" = "2023-06-01",
            "content-type" = "application/json"
          ),
          body = toJSON(list(
            model = input$claude_model,
            max_tokens = as.integer(input$max_tokens),
            messages = list(list(
              role = "user",
              content = content_parts
            ))
          ), auto_unbox = TRUE),
          encode = "json",
          timeout(120)
        )
        
        incProgress(0.7, detail = "Processing response...")
        
        if (status_code(response) == 200) {
          result <- content(response, "parsed")
          
          # Extract HTML from response
          html_content <- ""
          if (!is.null(result$content)) {
            for (block in result$content) {
              if (block$type == "text") {
                html_content <- paste0(html_content, block$text)
              }
            }
          }
          
          # Clean up HTML content
          html_content <- gsub("```html\n?", "", html_content)
          html_content <- gsub("```\n?$", "", html_content)
          html_content <- trimws(html_content)
          
          # Save to temp file
          temp_file <- tempfile(fileext = ".html")
          writeLines(html_content, temp_file)
          
          rv$generated_html <- html_content
          rv$generated_html_file <- temp_file
          
          incProgress(1, detail = "Complete!")
          showNotification("✓ Diagram generated successfully! Content is fitted to page boundaries.", type = "message", duration = 5)
        } else {
          error_content <- content(response, "text", encoding = "UTF-8")
          showNotification(paste("Generation failed:", error_content), type = "error", duration = 10)
        }
      }, error = function(e) {
        showNotification(paste("Error generating diagram:", e$message), type = "error", duration = 10)
      })
    })
  })
  
  # Copy to PDF Converter
  observeEvent(input$copy_to_converter, {
    req(rv$generated_html_file)
    
    # Create a permanent temp file for the converter
    transfer_file <- tempfile(fileext = ".html")
    file.copy(rv$generated_html_file, transfer_file, overwrite = TRUE)
    
    rv$transferred_html_file <- transfer_file
    rv$transferred_html_name <- paste0("generated_diagram_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".html")
    
    updateTabItems(session, "sidebar", "converter")
    showNotification("✓ HTML transferred to PDF Converter tab", type = "message", duration = 5)
  })
  
  # Clear generated HTML
  observeEvent(input$clear_generated, {
    rv$generated_html <- NULL
    rv$generated_html_file <- NULL
    showNotification("Generated HTML cleared", type = "message", duration = 3)
  })
  
  # Clear all files in converter
  observeEvent(input$clear_all_files, {
    rv$transferred_html_file <- NULL
    rv$transferred_html_name <- NULL
    # Reset file input
    shinyjs::reset("html_files")
    showNotification("All files cleared from converter", type = "message", duration = 3)
  })
  
  # Helper functions
  get_exact_page_dimensions <- function(size, orientation) {
    dims <- switch(size,
                   "A4" = list(width = "210mm", height = "297mm"),
                   "Letter" = list(width = "8.5in", height = "11in"),
                   "16:9" = list(width = "10in", height = "5.625in"),
                   "4:3" = list(width = "10in", height = "7.5in"),
                   "Legal" = list(width = "8.5in", height = "14in"),
                   "Tabloid" = list(width = "11in", height = "17in"),
                   list(width = "210mm", height = "297mm")
    )
    
    if (orientation == "landscape") {
      list(width = dims$height, height = dims$width)
    } else {
      dims
    }
  }
  
  get_page_dimensions_text <- function(size, orientation) {
    dims <- switch(size,
                   "A4" = "For body CSS: width: 210mm; height: 297mm;",
                   "Letter" = "For body CSS: width: 8.5in; height: 11in;",
                   "16:9" = "For body CSS: width: 10in; height: 5.625in;",
                   "4:3" = "For body CSS: width: 10in; height: 7.5in;",
                   "Legal" = "For body CSS: width: 8.5in; height: 14in;",
                   "Tabloid" = "For body CSS: width: 11in; height: 17in;",
                   "For body CSS: width: 210mm; height: 297mm;"
    )
    
    if (orientation == "landscape") {
      paste0(dims, " (swap width and height for landscape)")
    } else {
      dims
    }
  }
  
  # Display API Status
  output$api_status_ui <- renderUI({
    if (!is.null(rv$api_key) && rv$api_connected) {
      div(class = "api-status-connected",
          icon("check-circle"), " Connected",
          span(class = "status-badge status-badge-success", "ACTIVE")
      )
    } else if (!is.null(rv$api_key)) {
      div(class = "api-status-disconnected",
          icon("times-circle"), " Not tested - Click 'Test Connection'",
          span(class = "status-badge status-badge-danger", "UNTESTED")
      )
    } else {
      div(class = "alert-info",
          icon("info-circle"), " Enter your API key and test the connection to get started."
      )
    }
  })
  
  # Display context files
  output$context_files_display <- renderUI({
    req(input$context_files)
    if (nrow(input$context_files) > 10) {
      div(class = "alert-warning", icon("exclamation-triangle"),
          " Please select a maximum of 10 files. You have selected ", nrow(input$context_files), " files.")
    } else {
      div(
        tags$h5("Context Files:", style = "color: #2c3e50; font-weight: 600; margin-top: 15px;"),
        lapply(1:nrow(input$context_files), function(i) {
          div(class = "file-list-item", icon("file", style = "color: #00A39A;"),
              paste0(" ", input$context_files$name[i], " (", 
                     round(input$context_files$size[i]/1024, 1), " KB)"))
        })
      )
    }
  })
  
  # HTML Preview
  output$html_preview <- renderUI({
    req(rv$generated_html_file)
    tags$iframe(src = base64enc::dataURI(file = rv$generated_html_file, mime = "text/html"),
                style = "width: 100%; height: 600px; border: none;")
  })
  
  # Download HTML
  output$download_html <- downloadHandler(
    filename = function() {
      paste0("generated_diagram_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".html")
    },
    content = function(file) {
      req(rv$generated_html)
      writeLines(rv$generated_html, file)
    }
  )
  
  # Generation status
  output$generation_status <- renderUI({
    if (!is.null(rv$generated_html)) {
      div(class = "alert-success", style = "margin-top: 15px;",
          icon("check-circle"), " Diagram generated successfully! Content fitted to page boundaries. Preview below and download if satisfied.")
    }
  })
  
  # Display transferred HTML in converter tab
  output$transferred_html_display <- renderUI({
    if (!is.null(rv$transferred_html_file)) {
      div(
        div(class = "alert-info", 
            icon("info-circle"), 
            tags$strong(" HTML from Generate Tab"),
            span(class = "source-indicator source-generated", "GENERATED")
        ),
        div(class = "transferred-file-item", 
            icon("file-code", style = "color: #2196F3;"),
            paste0(" ", rv$transferred_html_name),
            actionButton("remove_transferred", "Remove", 
                         class = "btn btn-sm btn-warning", 
                         icon = icon("times"),
                         style = "float: right; margin-top: -5px;")
        )
      )
    } else {
      div(class = "alert-info",
          icon("info-circle"), 
          " No HTML transferred from Generate tab. Generate a diagram first, then click 'Send to PDF Converter'."
      )
    }
  })
  
  # Remove transferred HTML
  observeEvent(input$remove_transferred, {
    rv$transferred_html_file <- NULL
    rv$transferred_html_name <- NULL
    showNotification("Transferred HTML removed", type = "message", duration = 3)
  })
  
  # Display uploaded files
  output$uploaded_files_display <- renderUI({
    if (!is.null(input$html_files) && nrow(input$html_files) > 0) {
      if (nrow(input$html_files) > 8) {
        div(class = "alert-danger", icon("exclamation-triangle"),
            " Please select a maximum of 8 files. You have selected ", nrow(input$html_files), " files.")
      } else {
        div(
          tags$h5("Uploaded HTML Files:", 
                  style = "color: #2c3e50; font-weight: 600; margin-top: 15px;",
                  span(class = "source-indicator source-uploaded", "UPLOADED")),
          lapply(1:nrow(input$html_files), function(i) {
            div(class = "file-list-item", icon("file-alt", style = "color: #00A39A;"),
                paste0(" ", input$html_files$name[i]))
          })
        )
      }
    }
  })
  
  # Summary of all files
  output$all_files_summary <- renderUI({
    transferred_count <- if (!is.null(rv$transferred_html_file)) 1 else 0
    uploaded_count <- if (!is.null(input$html_files)) nrow(input$html_files) else 0
    total_count <- transferred_count + uploaded_count
    
    if (total_count > 0) {
      div(class = "alert-success",
          icon("check-circle"),
          tags$strong(paste0(" Total files ready for conversion: ", total_count)),
          tags$ul(style = "margin-top: 10px; margin-bottom: 0;",
                  if (transferred_count > 0) tags$li(paste0(transferred_count, " transferred from Generate tab")),
                  if (uploaded_count > 0) tags$li(paste0(uploaded_count, " uploaded file(s)"))
          )
      )
    }
  })
  
  # PDF Converter functions
  output$selected_dir_display <- renderText({
    if (!is.null(rv$output_dir) && length(rv$output_dir) > 0) {
      as.character(rv$output_dir)
    } else {
      "No folder selected"
    }
  })
  
  output$page_dimensions_info <- renderUI({
    page_dims <- get_page_dimensions(input$page_size, input$orientation)
    HTML(paste0(
      "<strong>Width:</strong> ", page_dims$width, " in<br>",
      "<strong>Height:</strong> ", page_dims$height, " in<br>",
      "<strong>Orientation:</strong> ", ifelse(input$orientation == "portrait", "Portrait", "Landscape")
    ))
  })
  
  get_page_dimensions <- function(size, orientation) {
    dims <- switch(size,
                   "A4" = list(width = 8.27, height = 11.69),
                   "Letter" = list(width = 8.5, height = 11),
                   "16:9" = list(width = 10, height = 5.625),
                   "4:3" = list(width = 10, height = 7.5),
                   list(width = 8.27, height = 11.69)
    )
    
    if (orientation == "landscape") {
      list(width = dims$height, height = dims$width)
    } else {
      dims
    }
  }
  
  # Convert to PDF
  observeEvent(input$convert_btn, {
    # Check if we have any files to convert
    has_transferred <- !is.null(rv$transferred_html_file)
    has_uploaded <- !is.null(input$html_files) && nrow(input$html_files) > 0
    
    if (!has_transferred && !has_uploaded) {
      showNotification("No files to convert. Please transfer HTML from Generate tab or upload files.", 
                       type = "error", duration = 5)
      return()
    }
    
    if (has_uploaded && nrow(input$html_files) > 8) {
      showNotification("Please select a maximum of 8 uploaded files.", type = "error", duration = 5)
      return()
    }
    
    if (is.null(rv$output_dir) || length(rv$output_dir) == 0) {
      showNotification("Please select an output folder.", type = "error", duration = 5)
      return()
    }
    
    if (as.numeric(input$page_from) > as.numeric(input$page_to)) {
      showNotification("'From page' must be less than or equal to 'To page'.", type = "error", duration = 5)
      return()
    }
    
    rv$converting <- TRUE
    tryCatch({
      # Build list of files to convert
      files_to_convert <- list()
      
      # Add transferred file
      if (has_transferred) {
        files_to_convert[[length(files_to_convert) + 1]] <- list(
          path = rv$transferred_html_file,
          name = rv$transferred_html_name,
          source = "transferred"
        )
      }
      
      # Add uploaded files
      if (has_uploaded) {
        for (i in 1:nrow(input$html_files)) {
          files_to_convert[[length(files_to_convert) + 1]] <- list(
            path = input$html_files$datapath[i],
            name = input$html_files$name[i],
            source = "uploaded"
          )
        }
      }
      
      n_files <- length(files_to_convert)
      success_count <- 0
      
      withProgress(message = 'Converting files to PDF...', value = 0, {
        for (i in 1:n_files) {
          file_info <- files_to_convert[[i]]
          incProgress(1/n_files, detail = paste("Processing", file_info$name))
          
          input_file <- file_info$path
          output_name <- tools::file_path_sans_ext(file_info$name)
          output_file <- file.path(rv$output_dir, paste0(output_name, ".pdf"))
          
          page_dims <- get_page_dimensions(input$page_size, input$orientation)
          scale_factor <- as.numeric(input$scale_percent) / 100
          page_ranges <- paste0(input$page_from, "-", input$page_to)
          
          tryCatch({
            pagedown::chrome_print(
              input = input_file,
              output = output_file,
              options = list(
                paperWidth = page_dims$width,
                paperHeight = page_dims$height,
                printBackground = TRUE,
                preferCSSPageSize = FALSE,
                landscape = (input$orientation == "landscape"),
                scale = scale_factor,
                displayHeaderFooter = FALSE,
                marginTop = 0,
                marginBottom = 0,
                marginLeft = 0,
                marginRight = 0,
                pageRanges = page_ranges
              ),
              verbose = FALSE,
              timeout = 60
            )
            success_count <- success_count + 1
          }, error = function(e) {
            showNotification(paste("Error converting", file_info$name, ":", e$message),
                             type = "warning", duration = 10)
          })
        }
      })
      
      if (success_count > 0) {
        showNotification(paste("✓ Successfully converted", success_count, "of", n_files, "file(s) to PDF!"),
                         type = "message", duration = 5)
      }
    }, error = function(e) {
      showNotification(paste("Error during conversion:", e$message), type = "error", duration = 10)
    }, finally = {
      rv$converting <- FALSE
    })
  })
  
  output$progress_ui <- renderUI({
    if (rv$converting) {
      div(style = "margin-top: 20px;",
          div(class = "alert-info", icon("spinner", class = "fa-spin"), " Converting files... Please wait.")
      )
    }
  })
  
  output$status_message <- renderUI({
    has_transferred <- !is.null(rv$transferred_html_file)
    has_uploaded <- !is.null(input$html_files) && nrow(input$html_files) > 0
    has_output_dir <- !is.null(rv$output_dir) && length(rv$output_dir) > 0
    
    if (!rv$converting && (has_transferred || has_uploaded) && has_output_dir) {
      total_files <- (if (has_transferred) 1 else 0) + (if (has_uploaded) nrow(input$html_files) else 0)
      div(class = "alert-info", style = "margin-top: 15px;",
          icon("info-circle"), 
          paste0(" Ready to convert ", total_files, " file(s). Click the button above to start."))
    }
  })
}

shinyApp(ui = ui, server = server)