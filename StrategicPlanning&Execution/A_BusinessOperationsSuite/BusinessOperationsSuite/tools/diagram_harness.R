# tools/diagram_harness.R - a one-page app with each kind of diagram the "Save diagram" bar handles
# (plotly chart, SVG, Mermaid, HTML in an iframe). Used by the browser test; run from the app folder:
#   Rscript -e 'shiny::runApp("tools/diagram_harness.R", port = 3901)'
suppressMessages({ library(shiny); library(plotly) })
if (basename(getwd()) == "tools") setwd("..")
source("R/utils_gdrive.R"); source("R/utils_diagram_export.R")
# stand-ins for what global.R provides, defined globally like there (runApp evaluates this file in its own environment)
assign("cred_local", function(...) list(json_path = NA), envir = globalenv())
assign("cred_dir", function() Sys.getenv("LAT_CRED_DIR", ""), envir = globalenv())        # the keys folder (R/utils_local_creds.R)
assign("loader", list(registry = yaml::read_yaml("modules/_module_registry.yml")), envir = globalenv())   # real Group/Section/Tab names
addResourcePath("js", file.path(getwd(), "www/js"))
svg_code <- '<svg xmlns="http://www.w3.org/2000/svg" width="360" height="160"><rect x="10" y="10" width="140" height="60" fill="#2a5298"/><text x="30" y="47" fill="white">Order</text><line x1="150" y1="40" x2="210" y2="40" stroke="black"/><rect x="210" y="10" width="140" height="60" fill="#11998e"/><text x="235" y="47" fill="white">Delivery</text></svg>'
html_code <- '<!doctype html><html><body style="margin:0;font-family:sans-serif"><div style="padding:30px;background:#ffe9a8;width:420px"><h3>HTML diagram</h3><p>Step 1 &rarr; Step 2</p></div></body></html>'
df <- data.frame(file = 1:4, words = c(120, 340, 90, 410))
ui <- fluidPage(tags$head(diagram_export_head()),
  h3("plotly"), plotlyOutput("chart", height = "300px"), diagram_save_ui("s1", formats = c("html", DIAGRAM_IMAGE_FORMATS, "csv")),
  h3("svg"), tags$div(id = "svgbox", style = "background:white;padding:10px", HTML(svg_code)), diagram_save_ui("s2", formats = c("html", DIAGRAM_IMAGE_FORMATS)),
  h3("mermaid"), tags$div(id = "merbox", diagram_mermaid_ui("graph TD; A[Idea] --> B[Prototype]; B --> C[Launch]")), diagram_save_ui("s3", formats = c("html", DIAGRAM_IMAGE_FORMATS, "source")),
  h3("iframe"), tags$div(id = "framebox", tags$iframe(srcdoc = html_code, width = "100%", height = "200px")), diagram_save_ui("s4", formats = c("html", DIAGRAM_IMAGE_FORMATS)))
server <- function(input, output, session) {
  p <- plot_ly(df, x = ~file, y = ~words, type = "bar")
  output$chart <- renderPlotly(p)
  diagram_save_server("s1", "analytics", "chart", "plotly", function() list(title = "Word Count Distribution", plot = p, data = df))
  diagram_save_server("s2", "diagram_generator", "svgbox", "html", function() diagram_code_spec(svg_code, "svg", "Flowchart", "order to delivery", "ChatGPT"))
  diagram_save_server("s3", "claude_diagrams", "merbox", "html", function() diagram_code_spec("graph TD; A[Idea] --> B[Prototype]; B --> C[Launch]", "mermaid", "Flowchart", "idea to launch", "Claude"))
  diagram_save_server("s4", "claude_diagrams", "framebox", "html", function() diagram_code_spec(html_code, "html", "Process", "two steps", "Claude"))
}
shinyApp(ui, server)
