# modules/Strategy Canvases/de_canvas_generate.R
# Subtab: Generate DE Canvas
# (DE_CANVAS_FIELDS / DE_CANVAS_LABELS are defined in R/api_manager.R, shared
# with de_canvas_view.R)

de_canvas_generate_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Generate Disciplined Entrepreneurship Canvas with Claude", status = "primary", solidHeader = TRUE, width = 12,
          h4("AI-Powered Disciplined Entrepreneurship Canvas Generation"),
          p("Provide your business details and let Claude generate a comprehensive Disciplined Entrepreneurship Canvas."),
          fluidRow(
            column(3, textInput(ns("de_business_area"), "Business Area (max 32 chars):", placeholder = "e.g., Technology, Healthcare", width = "100%")),
            column(3, textInput(ns("de_project"), "Project (max 32 chars):", placeholder = "e.g., Mobile App Development", width = "100%")),
            column(3, textInput(ns("de_business_focus"), "Business Focus (max 32 chars):", placeholder = "e.g., B2B SaaS", width = "100%")),
            column(3, br(), actionButton(ns("generate_de_canvas"), "Generate with Claude", class = "btn btn-warning btn-lg", icon = icon("magic"), width = "100%"))
          ),
          fluidRow(column(12, textAreaInput(ns("de_business_description"), "Business Idea Description:", height = "150px", width = "100%",
                                             placeholder = "Describe your business idea in detail for the Disciplined Entrepreneurship Canvas..."))),
          br(), htmlOutput(ns("de_generate_status")),
          hr(),
          h5("Claude Generated Content:"),
          textAreaInput(ns("de_claude_output"), "Generated DE Canvas:", height = "300px", width = "100%",
                        placeholder = "Claude's generated content will appear here..."),
          hr(),
          div(class = "alert alert-info", tags$strong("Format Requirements:"),
              tags$ul(tags$li("Review the generated content above"), tags$li("You can edit it or paste your own content below"),
                      tags$li("Required sections: [Raison d'Être], [Initial Market], etc."))),
          textAreaInput(ns("de_bulk_text"), "Paste or Edit DE Canvas Content:", height = "300px", width = "100%",
                        placeholder = "[Raison d'Être]\nMission: ...\nPassion: ...\nValues: ...\n\n[Initial Market]\nBeachhead: ...\nEnd User Profile: ..."),
          fluidRow(
            column(4, actionButton(ns("parseDECanvas"), "Parse Canvas Data", class = "btn btn-info btn-lg", icon = icon("cogs"), width = "100%")),
            column(4, actionButton(ns("submitDECanvas"), "Submit to BigQuery", class = "btn btn-success btn-lg", icon = icon("cloud-upload-alt"), width = "100%")),
            column(4, actionButton(ns("clearDECanvas"), "Clear All", class = "btn btn-danger", icon = icon("trash"), width = "100%"))
          ),
          br(), htmlOutput(ns("deBulkStatus")))
    ),
    fluidRow(
      box(title = "Parsed DE Canvas Preview", status = "info", solidHeader = TRUE, width = 12,
          htmlOutput(ns("deParseInfo")), br(),
          div(class = "preview-section", verbatimTextOutput(ns("deParsedPreview"))))
    )
  )
}

de_canvas_generate_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    parsed_de_canvas <- reactiveVal(NULL)

    observeEvent(input$generate_de_canvas, {
      if (!api_manager$claude_authenticated) {
        output$de_generate_status <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                                                         " Please connect Claude first (API Settings > Claude API Config)"))
        return()
      }
      if (trimws(input$de_business_area %||% "") == "" || trimws(input$de_project %||% "") == "" ||
          trimws(input$de_business_focus %||% "") == "" || trimws(input$de_business_description %||% "") == "") {
        output$de_generate_status <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"), " Please fill in all fields"))
        return()
      }

      output$de_generate_status <- renderUI(tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"),
                                                       " Generating Disciplined Entrepreneurship Canvas with Claude... Please wait."))

      prompt <- paste0(
        "You are a business strategy expert specializing in the Disciplined Entrepreneurship framework.\n\n",
        "Business Area: ", input$de_business_area, "\nProject: ", input$de_project, "\nBusiness Focus: ", input$de_business_focus,
        "\nBusiness Description: ", input$de_business_description, "\n\n",
        "Based on the information above, generate a comprehensive Disciplined Entrepreneurship Canvas with all 10 sections. ",
        "Format your response EXACTLY as follows:\n\n",
        "[Raison d'Être]\nMission: (describe mission)\nPassion: (describe passion)\nValues: (describe core values)\n\n",
        "[Initial Market]\nBeachhead: (describe beachhead market)\nEnd User Profile: (describe end user)\n\n",
        "[Value Creation]\nUse Case: (describe use case)\nProduct Description: (describe product)\n\n",
        "[Competitive Advantage]\nMoats: (describe competitive moats)\nCore: (describe core competencies)\n\n",
        "[Customer Acquisition]\nDMU: (describe decision-making unit)\nProcess to Acquire Customer: (describe process)\n\n",
        "[Product Unit Economics]\nBusiness Model: (describe business model)\nEstimated Pricing: (describe pricing strategy)\n\n",
        "[Sales]\nPreferred Sales Channel: (describe sales channel)\nSales Funnel: (describe sales funnel)\n\n",
        "[Overall Economics]\nEstimated R&D Expenses: (describe R&D costs)\nEstimated G&A Expenses: (describe G&A costs)\n\n",
        "[Design & Build]\nIdentify Key Assumptions: (list assumptions)\nTest Key Assumptions: (describe testing approach)\n\n",
        "[Scaling]\nProduct Plan for Beachhead: (describe initial plan)\nNext Market: (describe expansion strategy)\n\n",
        "Make the content specific, actionable, and tailored to the business description provided."
      )

      tryCatch({
        result <- api_manager$call_claude(prompt, max_tokens = 4000)
        updateTextAreaInput(session, "de_claude_output", value = result$text)
        updateTextAreaInput(session, "de_bulk_text", value = result$text)
        output$de_generate_status <- renderUI(tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                                                         " DE Canvas generated successfully!", br(),
                                                         tags$small("Review the content above and click 'Parse Canvas Data' when ready")))
        showNotification("✓ DE Canvas generated successfully!", type = "message")
      }, error = function(e) {
        output$de_generate_status <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Generation failed: ", br(), tags$small(e$message)))
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$parseDECanvas, {
      if (trimws(input$de_bulk_text %||% "") == "") {
        output$deBulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"), " Please paste canvas content to parse"))
        return()
      }
      if (trimws(input$de_business_area %||% "") == "") {
        output$deBulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"), " Please provide Business Area"))
        return()
      }
      if (trimws(input$de_project %||% "") == "") {
        output$deBulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"), " Please provide Project name"))
        return()
      }
      if (trimws(input$de_business_focus %||% "") == "") {
        output$deBulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"), " Please provide Business Focus"))
        return()
      }

      output$deBulkStatus <- renderUI(tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Parsing canvas data..."))

      tryCatch({
        text <- input$de_bulk_text
        values_list <- setNames(lapply(DE_CANVAS_LABELS, function(label) {
          str_match(text, paste0("(?i)\\[", label, "\\]\\s*\n([\\s\\S]*?)(?=\n\\[|$)"))[, 2]
        }), DE_CANVAS_FIELDS)

        missing <- DE_CANVAS_LABELS[vapply(values_list, is.na, logical(1))]
        if (length(missing) > 0) {
          stop(paste("Missing sections:", paste(missing, collapse = ", "),
                     "\n\nPlease ensure all 10 sections are included with proper [Section Name] headers."))
        }

        result <- c(
          list(business_area = substr(trimws(input$de_business_area), 1, 32),
               project = substr(trimws(input$de_project), 1, 32),
               business_focus = substr(trimws(input$de_business_focus), 1, 32)),
          lapply(values_list, trimws)
        )
        parsed_de_canvas(result)

        output$deBulkStatus <- renderUI(tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                                                  " Successfully parsed Disciplined Entrepreneurship Canvas!", br(),
                                                  tags$small("Business Area: ", result$business_area), br(),
                                                  tags$small("Project: ", result$project), br(),
                                                  tags$small("Business Focus: ", result$business_focus)))

        output$deParseInfo <- renderUI(tags$p(tags$strong("Parsed DE Canvas Summary:"), br(),
                                               paste("Business Area:", result$business_area), br(),
                                               paste("Project:", result$project), br(),
                                               paste("Business Focus:", result$business_focus), br(),
                                               "All 10 sections successfully parsed"))

        output$deParsedPreview <- renderText({
          paste0("Business Area: ", result$business_area, "\nProject: ", result$project, "\nBusiness Focus: ", result$business_focus, "\n\n",
                 paste(sprintf("%s: %s...", DE_CANVAS_LABELS, substr(unlist(result[DE_CANVAS_FIELDS]), 1, 100)), collapse = "\n\n"))
        })

        showNotification("✓ DE Canvas parsed successfully!", type = "message")
      }, error = function(e) {
        output$deBulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Parsing failed: ", br(), tags$small(e$message)))
        parsed_de_canvas(NULL)
        output$deParseInfo <- renderUI(NULL)
        output$deParsedPreview <- renderText("")
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$submitDECanvas, {
      if (!api_manager$bq_authenticated) {
        output$deBulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                                                  " Please authenticate first in API Settings > BigQuery Config"))
        return()
      }
      if (is.null(parsed_de_canvas())) {
        output$deBulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                                                  " Please parse the canvas first by clicking 'Parse Canvas Data'"))
        return()
      }

      output$deBulkStatus <- renderUI(tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Submitting to BigQuery... Please wait."))

      tryCatch({
        canvas_id <- api_manager$bq_insert_de_canvas(parsed_de_canvas())
        output$deBulkStatus <- renderUI(tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                                                  " Successfully submitted Disciplined Entrepreneurship Canvas to BigQuery!", br(),
                                                  tags$small("Canvas ID: ", canvas_id)))
        showNotification("✓ DE Canvas submitted successfully!", type = "message")
      }, error = function(e) {
        output$deBulkStatus <- renderUI(tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error submitting to BigQuery: ", br(), tags$small(e$message)))
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$clearDECanvas, {
      updateTextInput(session, "de_business_area", value = "")
      updateTextInput(session, "de_project", value = "")
      updateTextInput(session, "de_business_focus", value = "")
      updateTextAreaInput(session, "de_business_description", value = "")
      updateTextAreaInput(session, "de_claude_output", value = "")
      updateTextAreaInput(session, "de_bulk_text", value = "")
      parsed_de_canvas(NULL)
      output$deBulkStatus <- renderUI(tags$div(class = "status-info", tags$i(class = "fa fa-info-circle"), " All fields cleared. Ready for new input."))
      output$deParseInfo <- renderUI(NULL)
      output$deParsedPreview <- renderText("")
      output$de_generate_status <- renderUI(NULL)
    })

    output$de_generate_status <- renderUI({ tags$div() })
    output$deBulkStatus <- renderUI({ tags$div() })
    output$deParseInfo <- renderUI({ tags$div() })
    output$deParsedPreview <- renderText("")
  })
}
