# modules/Strategy Canvases/bm_canvas_generate.R
# Subtab: Generate BM Canvas
# (BM_CANVAS_FIELDS / BM_CANVAS_LABELS are defined in R/api_manager.R, shared
# with bm_canvas_view.R)

bm_canvas_generate_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Generate Business Model Canvas with Claude", status = "primary", solidHeader = TRUE, width = 12,
          h4("AI-Powered Business Model Canvas Generation"),
          p("Provide your business details and let Claude generate a comprehensive Business Model Canvas ",
            "based on Alexander Osterwalder's framework."),
          fluidRow(
            column(3, textInput(ns("business_area"), "Business Area (max 32 chars):", placeholder = "e.g., Technology, Healthcare", width = "100%")),
            column(3, textInput(ns("project"), "Project (max 32 chars):", placeholder = "e.g., Mobile App Development", width = "100%")),
            column(3, textInput(ns("business_focus"), "Business Focus (max 32 chars):", placeholder = "e.g., B2B SaaS", width = "100%")),
            column(3, br(), actionButton(ns("generate_bm_canvas"), "Generate with Claude", class = "btn btn-warning btn-lg", icon = icon("magic"), width = "100%"))
          ),
          fluidRow(column(12, textAreaInput(ns("business_description"), "Business Idea Description:", height = "150px", width = "100%",
                                             placeholder = "Describe your business idea in detail. Include information about your target customers, the problem you're solving, your solution, competitive advantages, revenue model, and any other relevant details..."))),
          br(), htmlOutput(ns("generate_status")),
          hr(),
          h5("Claude Generated Content:"),
          textAreaInput(ns("claude_output"), "Generated Business Model Canvas:", height = "300px", width = "100%",
                        placeholder = "Claude's generated content will appear here..."),
          hr(),
          div(class = "alert alert-info", tags$strong("Format Requirements:"),
              tags$ul(tags$li("Review the generated content above"), tags$li("You can edit it or paste your own content below"),
                      tags$li("Content must follow the format: [Key Partners], [Key Activities], etc."))),
          textAreaInput(ns("bulk_text"), "Paste or Edit Business Model Canvas Content:", height = "300px", width = "100%",
                        placeholder = "[Key Partners]\nYour key partners content here...\n\n[Key Activities]\nYour key activities content here..."),
          fluidRow(
            column(4, actionButton(ns("parseCanvas"), "Parse Canvas Data", class = "btn btn-info btn-lg", icon = icon("cogs"), width = "100%")),
            column(4, actionButton(ns("submitCanvas"), "Submit to BigQuery", class = "btn btn-success btn-lg", icon = icon("cloud-upload-alt"), width = "100%")),
            column(4, actionButton(ns("clearCanvas"), "Clear All", class = "btn btn-danger", icon = icon("trash"), width = "100%"))
          ),
          br(), htmlOutput(ns("bulkStatus")))
    ),
    fluidRow(
      box(title = "Parsed Canvas Preview", status = "info", solidHeader = TRUE, width = 12,
          htmlOutput(ns("parseInfo")), br(),
          div(class = "preview-section", verbatimTextOutput(ns("parsedPreview"))))
    )
  )
}

bm_canvas_generate_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    parsed_canvas <- reactiveVal(NULL)

    observeEvent(input$generate_bm_canvas, {
      if (!api_manager$claude_authenticated) {
        output$generate_status <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                                                      " Please connect Claude first (API Settings > Claude API Config)"))
        return()
      }
      if (trimws(input$business_area %||% "") == "" || trimws(input$project %||% "") == "" ||
          trimws(input$business_focus %||% "") == "" || trimws(input$business_description %||% "") == "") {
        output$generate_status <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                                                      " Please fill in all fields (Business Area, Project, Business Focus, and Description)"))
        return()
      }

      output$generate_status <- renderUI(tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"),
                                                    " Generating Business Model Canvas with Claude... Please wait."))

      prompt <- paste0(
        "You are a business strategy expert specializing in the Business Model Canvas framework by Alexander Osterwalder.\n\n",
        "Business Area: ", input$business_area, "\nProject: ", input$project, "\nBusiness Focus: ", input$business_focus,
        "\nBusiness Description: ", input$business_description, "\n\n",
        "Based on the information above, generate a comprehensive Business Model Canvas with all 9 building blocks. ",
        "Format your response EXACTLY as follows, with each section starting with its title in square brackets:\n\n",
        "[Key Partners]\n(Provide detailed content about key partners, suppliers, strategic alliances)\n\n",
        "[Key Activities]\n(Provide detailed content about key activities needed to deliver value proposition)\n\n",
        "[Key Resources]\n(Provide detailed content about key resources required)\n\n",
        "[Value Propositions]\n(Provide detailed content about value propositions and what makes this business unique)\n\n",
        "[Customer Relationships]\n(Provide detailed content about how to build and maintain customer relationships)\n\n",
        "[Channels]\n(Provide detailed content about channels to reach customers)\n\n",
        "[Customer Segments]\n(Provide detailed content about target customer segments)\n\n",
        "[Cost Structure]\n(Provide detailed content about major costs)\n\n",
        "[Revenue Streams]\n(Provide detailed content about revenue sources)\n\n",
        "Make the content specific, actionable, and tailored to the business description provided. ",
        "Include relevant details, examples, and strategic considerations for each section."
      )

      tryCatch({
        result <- api_manager$call_claude(prompt, max_tokens = 4000)
        updateTextAreaInput(session, "claude_output", value = result$text)
        updateTextAreaInput(session, "bulk_text", value = result$text)
        output$generate_status <- renderUI(tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                                                      " Business Model Canvas generated successfully!", br(),
                                                      tags$small("Review the content above and click 'Parse Canvas Data' when ready")))
        showNotification("✓ Canvas generated successfully!", type = "message")
      }, error = function(e) {
        output$generate_status <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
                                                      " Generation failed: ", br(), tags$small(e$message)))
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$parseCanvas, {
      if (trimws(input$bulk_text %||% "") == "") {
        output$bulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"), " Please paste canvas content to parse"))
        return()
      }
      if (trimws(input$business_area %||% "") == "") {
        output$bulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"), " Please provide Business Area"))
        return()
      }
      if (trimws(input$project %||% "") == "") {
        output$bulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"), " Please provide Project name"))
        return()
      }
      if (trimws(input$business_focus %||% "") == "") {
        output$bulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"), " Please provide Business Focus"))
        return()
      }

      output$bulkStatus <- renderUI(tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing canvas data..."))

      tryCatch({
        text <- input$bulk_text
        values_list <- setNames(lapply(BM_CANVAS_LABELS, function(label) {
          str_match(text, paste0("(?i)\\[", label, "\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)"))[, 2]
        }), BM_CANVAS_FIELDS)

        missing <- BM_CANVAS_LABELS[vapply(values_list, is.na, logical(1))]
        if (length(missing) > 0) {
          stop(paste("Missing sections:", paste(missing, collapse = ", "),
                     "\n\nPlease ensure all 9 sections are included with proper [Section Name] headers."))
        }

        result <- c(
          list(business_area = substr(trimws(input$business_area), 1, 32),
               project = substr(trimws(input$project), 1, 32),
               business_focus = substr(trimws(input$business_focus), 1, 32)),
          lapply(values_list, trimws)
        )
        parsed_canvas(result)

        output$bulkStatus <- renderUI(tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                                                " Successfully parsed Business Model Canvas!", br(),
                                                tags$small("Business Area: ", result$business_area), br(),
                                                tags$small("Project: ", result$project), br(),
                                                tags$small("Business Focus: ", result$business_focus)))

        output$parseInfo <- renderUI(tags$p(tags$strong("Parsed Canvas Summary:"), br(),
                                             paste("Business Area:", result$business_area), br(),
                                             paste("Project:", result$project), br(),
                                             paste("Business Focus:", result$business_focus), br(),
                                             "All 9 building blocks successfully parsed"))

        output$parsedPreview <- renderText({
          paste0("Business Area: ", result$business_area, "\nProject: ", result$project, "\nBusiness Focus: ", result$business_focus, "\n\n",
                 paste(sprintf("%s: %s...", BM_CANVAS_LABELS, substr(unlist(result[BM_CANVAS_FIELDS]), 1, 100)), collapse = "\n\n"))
        })

        showNotification("✓ Canvas parsed successfully!", type = "message")
      }, error = function(e) {
        output$bulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Parsing failed: ", br(), tags$small(e$message)))
        parsed_canvas(NULL)
        output$parseInfo <- renderUI(NULL)
        output$parsedPreview <- renderText("")
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$submitCanvas, {
      if (!api_manager$bq_authenticated) {
        output$bulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                                                " Please authenticate first in API Settings > BigQuery Config"))
        return()
      }
      if (is.null(parsed_canvas())) {
        output$bulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                                                " Please parse the canvas first by clicking 'Parse Canvas Data'"))
        return()
      }

      output$bulkStatus <- renderUI(tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Submitting to BigQuery... Please wait."))

      tryCatch({
        canvas_id <- api_manager$bq_insert_bm_canvas(parsed_canvas())
        output$bulkStatus <- renderUI(tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                                                " Successfully submitted Business Model Canvas to BigQuery!", br(),
                                                tags$small("Canvas ID: ", canvas_id)))
        showNotification("✓ Canvas submitted successfully!", type = "message")
      }, error = function(e) {
        output$bulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error submitting to BigQuery: ", br(), tags$small(e$message)))
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$clearCanvas, {
      updateTextInput(session, "business_area", value = "")
      updateTextInput(session, "project", value = "")
      updateTextInput(session, "business_focus", value = "")
      updateTextAreaInput(session, "business_description", value = "")
      updateTextAreaInput(session, "claude_output", value = "")
      updateTextAreaInput(session, "bulk_text", value = "")
      parsed_canvas(NULL)
      output$bulkStatus <- renderUI(tags$div(class = "status-info", tags$i(class = "fa fa-info-circle"), " All fields cleared. Ready for new input."))
      output$parseInfo <- renderUI(NULL)
      output$parsedPreview <- renderText("")
      output$generate_status <- renderUI(NULL)
    })

    output$generate_status <- renderUI({ tags$div() })
    output$bulkStatus <- renderUI({ tags$div() })
    output$parseInfo <- renderUI({ tags$div() })
    output$parsedPreview <- renderText("")
  })
}
