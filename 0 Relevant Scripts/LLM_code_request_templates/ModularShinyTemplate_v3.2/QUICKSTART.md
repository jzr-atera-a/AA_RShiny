# QUICK START GUIDE

## Get Running in 3 Steps!

### Step 1: Install Dependencies

```r
install.packages(c(
  "shiny",
  "shinydashboard", 
  "R6",
  "yaml",
  "purrr",
  "ggplot2",
  "DT"
))
```

### Step 2: Run the App

```r
shiny::runApp()
```

### Step 3: Explore!

Click through the tabs:
- **Dashboard** - Overview and metrics
- **API Config** - Configuration form
- **Data Viewer** - Cascading dropdowns

---

## Add Your First Module

### 1. Create Module Files

```bash
mkdir -p modules/hello_world
cd modules/hello_world
```

### 2. Create manifest.yml

```yaml
module:
  id: "hello_world"
  name: "Hello World"
  enabled: true
  
  menu:
    label: "Hello"
    icon: "hand-wave"
    tabname: "hello_world"
  
  dependencies:
    packages:
      - shiny
      - shinydashboard
```

### 3. Create ui.R

```r
hello_world_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "Hello World!",
        status = "primary",
        width = 12,
        h4("My First Module"),
        textInput(ns("name"), "Your Name:"),
        actionButton(ns("greet"), "Greet Me!"),
        htmlOutput(ns("greeting"))
      )
    )
  )
}
```

### 4. Create server.R

```r
hello_world_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    observeEvent(input$greet, {
      output$greeting <- renderUI({
        tags$div(class = "status-success",
                 "Hello, ", input$name, "! 👋")
      })
    })
  })
}
```

### 5. Register Module

Edit `modules/_module_registry.yml`, add:

```yaml
modules:
  hello_world:
    enabled: true
    priority: 40
```

### 6. Restart App

```r
shiny::runApp()
```

Your new "Hello" tab appears automatically! 🎉

---

## Next Steps

- Copy an existing module and modify it
- Add database connections in `R/utils_api.R`
- Customize colors in `www/css/global.css`
- Build your amazing app! 🚀
