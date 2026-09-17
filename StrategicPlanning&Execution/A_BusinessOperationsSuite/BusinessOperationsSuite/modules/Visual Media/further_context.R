# modules/Visual Media/further_context.R
# Subtab: Further Context - ChatGPT text enrichment, using the shared
# api_manager$call_openai() (same as Project Application's generation
# buttons) rather than a separate chatgpt_complete() method.

further_context_ui <- function(id) {
  ns <- NS(id)

  fluidRow(
    column(width = 8,
           box(title = "Text Enrichment with ChatGPT", status = "primary", solidHeader = TRUE, width = NULL,
               textAreaInput(ns("contextText"), "Edit and Enrich Your Context:",
                            placeholder = "Transfer text from Image Generation tab or write your own content here...", rows = 18, width = "100%"),
               fluidRow(
                 column(6, selectInput(ns("wordCount"), "Target Word Count:",
                                       choices = c("10 words" = "10", "20 words" = "20", "30 words" = "30", "50 words" = "50",
                                                   "80 words" = "80", "130 words" = "130", "210 words" = "210", "340 words" = "340"),
                                       selected = "80")),
                 column(6, selectInput(ns("textStyle"), "Target Style:",
                                       choices = c("Professional" = "professional", "Casual" = "casual", "Creative" = "creative",
                                                   "Technical" = "technical", "Pitch Deck" = "pitch deck", "Email Like" = "email like"),
                                       selected = "pitch deck"))
               ),
               br(),
               actionButton(ns("enrichBtn"), "Enrich with ChatGPT", class = "btn-success", style = "width: 100%; font-size: 16px; padding: 12px;", icon = icon("magic")),
               br(), br(),
               div(class = "info-box", h5(style = "margin-top: 0;", "ℹ️ How it works:"),
                   p("Your text will be sent to ChatGPT with instructions to rewrite it in the selected style and word count. The enriched version will appear in the output box below.")))
    ),
    column(width = 4,
           box(title = "Enriched Output", status = "success", solidHeader = TRUE, width = NULL,
               verbatimTextOutput(ns("enrichedText")),
               br(),
               conditionalPanel(condition = "output.hasEnrichedText", ns = ns,
                                 actionButton(ns("copyBtn"), "Copy to Clipboard", class = "btn-info", style = "width: 100%;", icon = icon("copy")),
                                 br(), br(),
                                 actionButton(ns("replaceBtn"), "Replace Input with This", class = "btn-warning", style = "width: 100%;", icon = icon("exchange-alt")))
           ),
           box(title = "Processing Log", status = "info", solidHeader = TRUE, width = NULL, collapsible = TRUE, collapsed = TRUE,
               verbatimTextOutput(ns("log")))
    )
  )
}

further_context_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    values <- reactiveValues(enriched_output = NULL)

    # Pick up text transferred from the Image Generation tab
    observeEvent(api_manager$pending_prompt_visual_media(), {
      pending <- api_manager$pending_prompt_visual_media()
      if (!is.null(pending) && nchar(pending) > 0) {
        updateTextAreaInput(session, "contextText", value = pending)
        api_manager$set_pending_prompt_visual_media("")
      }
    }, ignoreInit = TRUE)

    observeEvent(input$enrichBtn, {
      req(input$contextText)
      if (nchar(trimws(input$contextText)) == 0) { showNotification("Please enter some text to enrich", type = "error"); return() }
      if (!api_manager$openai_authenticated) {
        showNotification("Please configure your ChatGPT/OpenAI API key first (API Settings > ChatGPT API Config)!", type = "error", duration = 5)
        return()
      }

      notification_id <- showNotification("Enriching text with ChatGPT... Please wait.", duration = NULL, type = "message")

      tryCatch({
        word_count <- input$wordCount
        style <- input$textStyle

        instruction <- paste0(
          "Rewrite the following text in a ", style, " style with approximately ", word_count, " words. ",
          "Maintain the core message but enhance clarity, professionalism, and impact.\n\nText to rewrite:\n", input$contextText
        )

        log_message <- paste0("=== ENRICHMENT REQUEST ===\nWord Count: ", word_count, " words\nStyle: ", style,
                              "\nInput length: ", nchar(input$contextText), " characters\n========================\n")
        output$log <- renderText(log_message)

        result <- api_manager$call_openai(instruction, max_tokens = as.integer(word_count) * 2)

        if (!is.null(result$text) && nchar(result$text) > 0) {
          values$enriched_output <- result$text

          output$log <- renderText(paste0(log_message, "\n=== ENRICHMENT RESULT ===\nOutput length: ", nchar(result$text), " characters\n",
                                          "Word count: ~", length(strsplit(result$text, "\\s+")[[1]]), " words\nStatus: SUCCESS\n========================\n"))

          removeNotification(notification_id)
          showNotification("Text enriched successfully!", type = "message", duration = 5)
        }
      }, error = function(e) {
        removeNotification(notification_id)
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
        output$log <- renderText(paste0("=== ERROR ===\n", e$message, "\n============\n"))
      })
    })

    output$enrichedText <- renderText({
      if (!is.null(values$enriched_output)) values$enriched_output else "No enriched text yet. Click 'Enrich with ChatGPT' to generate."
    })

    output$hasEnrichedText <- reactive({ !is.null(values$enriched_output) && nchar(values$enriched_output) > 0 })
    outputOptions(output, "hasEnrichedText", suspendWhenHidden = FALSE)

    observeEvent(input$copyBtn, {
      if (!is.null(values$enriched_output)) {
        shinyjs::runjs(paste0("navigator.clipboard.writeText(`", gsub("`", "\\`", values$enriched_output), "`);"))
        showNotification("Copied to clipboard!", type = "message", duration = 2)
      }
    })

    observeEvent(input$replaceBtn, {
      if (!is.null(values$enriched_output)) {
        updateTextAreaInput(session, "contextText", value = values$enriched_output)
        showNotification("Input replaced with enriched text", type = "message", duration = 3)
      }
    })
  })
}
