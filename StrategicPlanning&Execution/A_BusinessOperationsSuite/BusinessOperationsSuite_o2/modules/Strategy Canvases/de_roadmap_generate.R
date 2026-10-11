# modules/Strategy Canvases/de_roadmap_generate.R
# Subtab: Generate DE Roadmap (24 steps)
# (ROADMAP_STEP_TITLES / ROADMAP_STEP_FIELDS are defined in R/api_manager.R,
# shared with de_roadmap_view.R)

de_roadmap_generate_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Generate Disciplined Entrepreneurship Roadmap with Claude", status = "primary", solidHeader = TRUE, width = 12,
          h4("AI-Powered Disciplined Entrepreneurship Roadmap Generation"),
          p("Provide your business details and let Claude generate all 24 steps of the Disciplined Entrepreneurship Roadmap."),
          fluidRow(
            column(3, textInput(ns("roadmap_business_area"), "Business Area (max 32 chars):", placeholder = "e.g., Technology, Healthcare", width = "100%")),
            column(3, textInput(ns("roadmap_project"), "Project (max 32 chars):", placeholder = "e.g., Mobile App Development", width = "100%")),
            column(3, textInput(ns("roadmap_business_focus"), "Business Focus (max 32 chars):", placeholder = "e.g., B2B SaaS", width = "100%")),
            column(3, br(), actionButton(ns("generate_roadmap"), "Generate with Claude", class = "btn btn-warning btn-lg", icon = icon("magic"), width = "100%"))
          ),
          fluidRow(column(12, textAreaInput(ns("roadmap_business_description"), "Business Idea Description:", height = "150px", width = "100%",
                                             placeholder = "Describe your business idea in detail for the 24-step Disciplined Entrepreneurship Roadmap..."))),
          br(), htmlOutput(ns("roadmap_generate_status")),
          hr(),
          h5("Claude Generated Content:"),
          textAreaInput(ns("roadmap_claude_output"), "Generated Roadmap:", height = "300px", width = "100%",
                        placeholder = "Claude's generated content will appear here..."),
          hr(),
          div(class = "alert alert-info", tags$strong("Format Requirements:"),
              tags$ul(tags$li("Review the generated content above"), tags$li("You can edit it or paste your own content below"),
                      tags$li("All 24 steps required: [Step 1: Market Segmentation], [Step 2: Select a Beachhead Market], etc."))),
          textAreaInput(ns("roadmap_bulk_text"), "Paste or Edit Roadmap Content:", height = "300px", width = "100%",
                        placeholder = "[Step 1: Market Segmentation]\nYour content here...\n\n[Step 2: Select a Beachhead Market]\nYour content here..."),
          fluidRow(
            column(4, actionButton(ns("parseRoadmap"), "Parse Roadmap Data", class = "btn btn-info btn-lg", icon = icon("cogs"), width = "100%")),
            column(4, actionButton(ns("submitRoadmap"), "Submit to BigQuery", class = "btn btn-success btn-lg", icon = icon("cloud-upload-alt"), width = "100%")),
            column(4, actionButton(ns("clearRoadmap"), "Clear All", class = "btn btn-danger", icon = icon("trash"), width = "100%"))
          ),
          br(), htmlOutput(ns("roadmapBulkStatus")))
    ),
    fluidRow(
      box(title = "Parsed Roadmap Preview", status = "info", solidHeader = TRUE, width = 12,
          htmlOutput(ns("roadmapParseInfo")), br(),
          div(class = "preview-section", verbatimTextOutput(ns("roadmapParsedPreview"))))
    )
  )
}

de_roadmap_generate_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    parsed_roadmap <- reactiveVal(NULL)

    observeEvent(input$generate_roadmap, {
      if (!api_manager$claude_authenticated) {
        output$roadmap_generate_status <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                                                              " Please connect Claude first (API Settings > Claude API Config)"))
        return()
      }
      if (trimws(input$roadmap_business_area %||% "") == "" || trimws(input$roadmap_project %||% "") == "" ||
          trimws(input$roadmap_business_focus %||% "") == "" || trimws(input$roadmap_business_description %||% "") == "") {
        output$roadmap_generate_status <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"), " Please fill in all fields"))
        return()
      }

      output$roadmap_generate_status <- renderUI(tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"),
                                                            " Generating Disciplined Entrepreneurship Roadmap with Claude... This may take a moment."))

      step_lines <- paste(sprintf("[Step %d: %s]\n(Detailed content)\n", seq_along(ROADMAP_STEP_TITLES), ROADMAP_STEP_TITLES), collapse = "\n")

      prompt <- paste0(
        "You are a business strategy expert specializing in the Disciplined Entrepreneurship 24-step framework.\n\n",
        "Business Area: ", input$roadmap_business_area, "\nProject: ", input$roadmap_project,
        "\nBusiness Focus: ", input$roadmap_business_focus, "\nBusiness Description: ", input$roadmap_business_description, "\n\n",
        "Generate a detailed Disciplined Entrepreneurship Roadmap with ALL 24 steps. Format EXACTLY as follows:\n\n",
        step_lines, "\n",
        "Make each step specific and actionable for the business described."
      )

      tryCatch({
        result <- api_manager$call_claude(prompt, max_tokens = 6000)
        updateTextAreaInput(session, "roadmap_claude_output", value = result$text)
        updateTextAreaInput(session, "roadmap_bulk_text", value = result$text)
        output$roadmap_generate_status <- renderUI(tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                                                              " Roadmap generated successfully!", br(),
                                                              tags$small("Review the content above and click 'Parse Roadmap Data' when ready")))
        showNotification("✓ Roadmap generated successfully!", type = "message")
      }, error = function(e) {
        output$roadmap_generate_status <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Generation failed: ", br(), tags$small(e$message)))
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$parseRoadmap, {
      if (trimws(input$roadmap_bulk_text %||% "") == "") {
        output$roadmapBulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"), " Please paste roadmap content to parse"))
        return()
      }
      if (trimws(input$roadmap_business_area %||% "") == "") {
        output$roadmapBulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"), " Please provide Business Area"))
        return()
      }
      if (trimws(input$roadmap_project %||% "") == "") {
        output$roadmapBulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"), " Please provide Project name"))
        return()
      }
      if (trimws(input$roadmap_business_focus %||% "") == "") {
        output$roadmapBulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"), " Please provide Business Focus"))
        return()
      }

      output$roadmapBulkStatus <- renderUI(tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing roadmap data..."))

      tryCatch({
        text <- input$roadmap_bulk_text

        # Match by step NUMBER only (not exact title text) - robust against minor
        # title wording variance and avoids escaping steps 22/23's punctuation.
        step_values <- lapply(seq_along(ROADMAP_STEP_TITLES), function(i) {
          pat <- sprintf("(?i)\\[Step %d:?[^\\]]*\\]\\s*\n([\\s\\S]*?)(?=\n\\[Step|$)", i)
          str_match(text, pat)[, 2]
        })
        names(step_values) <- ROADMAP_STEP_FIELDS

        missing_idx <- which(vapply(step_values, is.na, logical(1)))
        if (length(missing_idx) > 0) {
          stop(paste("Missing steps:", paste(sprintf("Step %d: %s", missing_idx, ROADMAP_STEP_TITLES[missing_idx]), collapse = ", "),
                     "\n\nPlease ensure all 24 steps are included with proper [Step X: Title] headers."))
        }

        result <- c(
          list(business_area = substr(trimws(input$roadmap_business_area), 1, 32),
               project = substr(trimws(input$roadmap_project), 1, 32),
               business_focus = substr(trimws(input$roadmap_business_focus), 1, 32)),
          lapply(step_values, trimws)
        )
        parsed_roadmap(result)

        output$roadmapBulkStatus <- renderUI(tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                                                        " Successfully parsed Disciplined Entrepreneurship Roadmap!", br(),
                                                        tags$small("Business Area: ", result$business_area), br(),
                                                        tags$small("Project: ", result$project), br(),
                                                        tags$small("Business Focus: ", result$business_focus)))

        output$roadmapParseInfo <- renderUI(tags$p(tags$strong("Parsed Roadmap Summary:"), br(),
                                                    paste("Business Area:", result$business_area), br(),
                                                    paste("Project:", result$project), br(),
                                                    paste("Business Focus:", result$business_focus), br(),
                                                    "All 24 steps successfully parsed"))

        output$roadmapParsedPreview <- renderText({
          paste0("Business Area: ", result$business_area, "\nProject: ", result$project, "\nBusiness Focus: ", result$business_focus, "\n\n",
                 paste(sprintf("Step %d: %s...", seq_along(ROADMAP_STEP_TITLES), substr(unlist(result[ROADMAP_STEP_FIELDS]), 1, 80)), collapse = "\n"))
        })

        showNotification("✓ Roadmap parsed successfully!", type = "message")
      }, error = function(e) {
        output$roadmapBulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Parsing failed: ", br(), tags$small(e$message)))
        parsed_roadmap(NULL)
        output$roadmapParseInfo <- renderUI(NULL)
        output$roadmapParsedPreview <- renderText("")
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$submitRoadmap, {
      if (!api_manager$bq_authenticated) {
        output$roadmapBulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                                                        " Please authenticate first in API Settings > BigQuery Config"))
        return()
      }
      if (is.null(parsed_roadmap())) {
        output$roadmapBulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                                                        " Please parse the roadmap first by clicking 'Parse Roadmap Data'"))
        return()
      }

      output$roadmapBulkStatus <- renderUI(tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Submitting to BigQuery... Please wait."))

      tryCatch({
        roadmap_id <- api_manager$bq_insert_de_roadmap(parsed_roadmap())
        output$roadmapBulkStatus <- renderUI(tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                                                        " Successfully submitted Disciplined Entrepreneurship Roadmap to BigQuery!", br(),
                                                        tags$small("Roadmap ID: ", roadmap_id)))
        showNotification("✓ Roadmap submitted successfully!", type = "message")
      }, error = function(e) {
        output$roadmapBulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error submitting to BigQuery: ", br(), tags$small(e$message)))
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$clearRoadmap, {
      updateTextInput(session, "roadmap_business_area", value = "")
      updateTextInput(session, "roadmap_project", value = "")
      updateTextInput(session, "roadmap_business_focus", value = "")
      updateTextAreaInput(session, "roadmap_business_description", value = "")
      updateTextAreaInput(session, "roadmap_claude_output", value = "")
      updateTextAreaInput(session, "roadmap_bulk_text", value = "")
      parsed_roadmap(NULL)
      output$roadmapBulkStatus <- renderUI(tags$div(class = "status-info", tags$i(class = "fa fa-info-circle"), " All fields cleared. Ready for new input."))
      output$roadmapParseInfo <- renderUI(NULL)
      output$roadmapParsedPreview <- renderText("")
      output$roadmap_generate_status <- renderUI(NULL)
    })

    output$roadmap_generate_status <- renderUI({ tags$div() })
    output$roadmapBulkStatus <- renderUI({ tags$div() })
    output$roadmapParseInfo <- renderUI({ tags$div() })
    output$roadmapParsedPreview <- renderText("")
  })
}
