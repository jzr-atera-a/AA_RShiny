# modules/Technical Designs/techdesign_infographic/ui.R

techdesign_infographic_ui <- function(id) {
  ns <- NS(id)
  seeds <- ig_seed_files()
  tagList(
    fluidRow(
      box(
        title = "Infographic Studio: rich visual posters from a topic", status = "primary", solidHeader = TRUE, width = 12,
        div(class = "alert alert-info",
            tags$strong("How this works:"),
            " describe a topic. The Editing Tool plans the story and picks a block type for each section (big numbers, donut, pencil or bar chart, people pictogram, region tile map, quote cards, branching tree, steps, icon rows and more). ",
            "It researches the figures on the web with quotes and source URLs, the app checks each quote against the cited page, and then draws the whole poster itself from a fixed library of icons and themes. ",
            "Choose a long poster or a deck of slides (16:9, 4:3, 1:1, 4:5, 9:16, A4) and download it as PowerPoint, PDF, HTML, JPEG, PNG or GIF. Each version is stored as one row in the Technical Designs table."),
        textAreaInput(ns("topic"), "What is the infographic about? *", rows = 3, width = "100%",
                      placeholder = "e.g., The future of big data: where it comes from, why it matters, the risks and the opportunities."),
        textInput(ns("extra"), "Extra instructions (optional):", width = "100%", placeholder = "e.g., aimed at city managers; focus on Europe; keep it positive but balanced"),
        fluidRow(
          column(4, selectInput(ns("format"), "Page format:", choices = IG_FORMAT_CHOICES, selected = "poster")),
          column(4, conditionalPanel("input.format == 'poster'", ns = ns, sliderInput(ns("n_sections"), "Number of sections:", min = 4, max = 10, value = 8, step = 1)),
                    conditionalPanel("input.format != 'poster'", ns = ns, sliderInput(ns("n_slides"), "Number of slides / pages:", min = 1, max = 8, value = 4, step = 1))),
          column(4, selectInput(ns("theme"), "Colour theme:", choices = c("Let the Editing Tool choose" = "auto", IG_THEME_CHOICES[IG_THEME_CHOICES != "custom"]), selected = "auto"))
        ),
        fluidRow(
          column(6, radioButtons(ns("research"), "Evidence:", choices = c("Research the web (sourced)" = "web", "Knowledge only (illustrative)" = "knowledge"), selected = "web", inline = TRUE)),
          column(6, numericInput(ns("max_uses"), "Max web searches per section:", value = 4, min = 1, max = 8, step = 1))
        ),
        fluidRow(
          column(4, selectInput(ns("layout"), "Visual style / layout:", choices = c("Illustrated flow: connected, stylised shapes" = "flow", "Dashboard: several panels per slide" = "dashboard", "Stacked: one section per slide or band (classic)" = "stacked"), selected = "flow")),
          column(8, p(style = "color:#7f8c8d;font-size:12px;margin-top:26px;", "Illustrated flow links the sections with one continuous path, ribbon headings, icon orbs and ribbons. Dashboard shows panels on a grid. Stacked is the classic poster / one block per page. (On a long poster, Dashboard behaves like Stacked.)"))),
        conditionalPanel("input.format != 'poster'", ns = ns,
          fluidRow(
            column(3, conditionalPanel("input.layout != 'stacked'", ns = ns, sliderInput(ns("panels"), "Sections per slide:", min = 2, max = 6, value = 4, step = 1))),
            column(3, selectInput(ns("cover"), "Title cover slide:", choices = c("Automatic" = "auto", "Yes (first slide is a cover)" = "yes", "No (content only)" = "no"), selected = "auto")),
            column(3, selectInput(ns("text_size"), "Text size:", choices = c("Small (finer print, room for more detail)" = "small", "Normal" = "normal", "Large (bigger canvas text, fewer details)" = "large"), selected = "normal"))
          )),
        tags$details(style = "margin-bottom:10px;",
          tags$summary(style = "cursor:pointer;font-weight:600;", "Facts, requirements and brand colours (optional, recommended for grant applications)"),
          textAreaInput(ns("facts"), "Facts supplied by you (the Editing Tool may use these numbers as your data and will not invent others):", rows = 5, width = "100%",
                        placeholder = "e.g., Detector mAP 0.87 and precision 0.91 on road imagery (CCAV CAM Pathfinder). Telemetry latency under 200 ms. Kalman tracker proven on Jetson. Drone field tests: not done. SAPIENT validation: not done. Build February 2027, independent trials March 2027."),
          textAreaInput(ns("requirements"), "Requirements the infographic must address (one per line):", rows = 4, width = "100%",
                        placeholder = "e.g., Detect and track two or more drones at once\nPassive sensing, no RF emissions\nSAPIENT (BSI Flex 335) output\nTRL 6 by the end of the project"),
          fluidRow(
            column(3, textInput(ns("pal_navy"), "Brand colour 1 (dark, hex):", placeholder = "#0B2545")),
            column(3, textInput(ns("pal_teal"), "Brand colour 2 (hex):", placeholder = "#13A0AF")),
            column(3, textInput(ns("pal_magenta"), "Brand colour 3 (hex):", placeholder = "#C2185B")),
            column(3, textInput(ns("pal_ochre"), "Brand colour 4 (hex):", placeholder = "#DB9A22"))
          ),
          uiOutput(ns("pal_swatch")),
          p(style = "color:#7f8c8d;font-size:12px;", "Enter all four colours to use them (the theme list then offers 'Your brand colours'). Items taken from your facts show a navy diamond; things the Editing Tool proposes itself are labelled TARGET or SELF-ASSESSED; anything not yet done is shown as [INSERT]. Nothing is invented.")),
        p(style = "color:#7f8c8d;font-size:12px;margin-top:-6px;", "Slide formats (16:9, 4:3, 1:1, 4:5, 9:16, A4) draw each slide as a fixed-size page: a title cover (landscape and square formats, when you ask for 2 or more slides), one section per slide, and the sources on the last slide. ",
          "Dashboard layout puts 2-6 panels (pipelines, zone diagrams, gauges, comparison matrices, readiness scales, timelines, charts) on each slide. You can switch format, layout, panels or slide count at any time without calling the Editing Tool again; the sections are simply re-flowed onto the pages."),
        checkboxGroupInput(ns("types"), "Block types the Editing Tool may use:", choiceNames = unname(IG_TYPE_LABELS[IG_ALL_TYPES]), choiceValues = IG_ALL_TYPES, selected = IG_ALL_TYPES, inline = TRUE),
        checkboxInput(ns("verify"), "Fetch cited pages and check the quotes", value = TRUE),
        p(style = "color:#7f8c8d;font-size:12px;", "Web research makes one call per statistics section (about 20-60 seconds each), plus one to plan and one to write the text sections. Web search must be enabled for your organisation in the Anthropic Console."),
        hr(),
        fluidRow(
          column(3, actionButton(ns("generate"), "Generate Infographic", icon = icon("magic"), class = "btn-primary btn-lg", style = "width: 100%;")),
          column(3, actionButton(ns("preview"), "Re-Parse & Draw", icon = icon("sync"), class = "btn-info btn-lg", style = "width: 100%;")),
          column(3, actionButton(ns("save"), "Save to BigQuery", icon = icon("cloud-upload-alt"), class = "btn-success btn-lg", style = "width: 100%;")),
          column(3, downloadButton(ns("dl_json"), "Download JSON", class = "btn-warning btn-lg", style = "width: 100%;"))
        ),
        br(),
        fluidRow(
          column(6, selectInput(ns("seed"), "Example:", choices = if (length(seeds) > 0) seeds else c("(none)" = ""))),
          column(3, br(), actionButton(ns("load_seed"), "Load Example", icon = icon("folder-open"), style = "width:100%;"))
        ),
        htmlOutput(ns("status"))
      )
    ),
    fluidRow(
      box(title = "Infographic", status = "info", solidHeader = TRUE, width = 12,
          ig_export_ui(ns, ns("export_target"), "infographic"),
          uiOutput(ns("diagram")))
    ),
    fluidRow(
      box(title = "Facts and Evidence", status = "warning", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE,
          p(style = "color:#7f8c8d;font-size:12px;", "Every statistic with its evidence status, metric, date, quote and source ids."),
          DT::dataTableOutput(ns("facts")))
    ),
    fluidRow(
      box(title = "Data (editable JSON)", status = "success", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE,
          p(style = "color:#7f8c8d;font-size:12px;", "Edit any heading, number, label, icon name or theme, then click 'Re-Parse & Draw'. 'Save' stores exactly what is in this box; if you loaded a saved infographic, saving adds a NEW VERSION of it. ",
            "Icon names must come from the built-in library (", paste(IG_ICON_NAMES, collapse = ", "), "); unknown names fall back to a star."),
          textAreaInput(ns("gen_text"), NULL, rows = 18, width = "100%", placeholder = "The infographic JSON will appear here."))
    ),
    fluidRow(
      box(title = "Saved Infographics", status = "primary", solidHeader = TRUE, width = 12, collapsible = TRUE,
          fluidRow(column(12, selectInput(ns("saved_id"), "Saved infographic:", choices = c("(none saved yet)" = ""), width = "100%"))),
          fluidRow(
            column(3, actionButton(ns("load_view"), "Show Infographic", icon = icon("eye"), class = "btn-primary", style = "width: 100%;")),
            column(3, actionButton(ns("load_edit"), "Load into Editor", icon = icon("edit"), class = "btn-info", style = "width: 100%;")),
            column(3, actionButton(ns("delete"), "Delete", icon = icon("trash"), class = "btn-danger", style = "width: 100%;")),
            column(3, actionButton(ns("refresh"), "Refresh List", icon = icon("sync"), class = "btn-default", style = "width: 100%;"))
          ))
    )
  )
}
