# modules/Mind Map/message_hierarchy.R
# ---- module --------------------------------------------------------------------------------------
# id:           message_hierarchy
# name:         Message Hierarchy
# icon:         sitemap
# description:  Build a pyramid-principle message structure for talks and presentations (core message on top, supporting points and evidence below). Stored in the Mind Map table under the reserved category MessageHierarchy.
# packages:     shiny, shinydashboard, shinyjs, jsonlite
# api_required: claude
# api_optional: bigquery
# --------------------------------------------------------------------------------------------------

# ==== UI ===========================================================================================

# Variation of the Mind Map tab: same table, category locked to "MessageHierarchy".

message_hierarchy_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Message Hierarchy Definition",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        p("Design how to deliver a critical message in a talk or presentation. The Editing Tool builds a pyramid: ",
          "your core message at the top, the supporting points that prove it below, and evidence under each point. ",
          "Saved in the Mind Map table with the reserved category 'MessageHierarchy' (it does not appear in the regular Mind Map tabs)."),

        fluidRow(
          column(6, category_domain_topic_dropdown_ui(ns)),
          column(6, textInput(ns("map_title"), "Title of this talk / structure:",
                              placeholder = "e.g., Q3 Strategy Keynote"))
        ),

        textAreaInput(ns("core_message"), "Core message (the one thing the audience must remember): *",
                      rows = 2, width = "100%",
                      placeholder = "e.g., We must move to a subscription model this year."),
        textAreaInput(ns("outcome"), "Critical outcome wanted from the audience: *",
                      rows = 2, width = "100%",
                      placeholder = "e.g., The board approves the budget before the end of the meeting."),

        fluidRow(
          column(4, sliderInput(ns("n_points"), "Number of supporting points:",
                                min = 2, max = 8, value = 3, step = 1)),
          column(4, sliderInput(ns("evidence_per_point"), "Evidence items per point:",
                                min = 1, max = 4, value = 2, step = 1)),
          column(4, sliderInput(ns("words_per_node"), "Max words per node:",
                                min = 20, max = 120, value = 40, step = 20))
        ),

        fluidRow(
          column(6, textInput(ns("audience"), "Audience (optional):",
                              placeholder = "e.g., Board of directors, sceptical CFO")),
          column(6, textInput(ns("reference"), "Book or online resource to follow (optional):",
                              placeholder = "e.g., The Pyramid Principle by Barbara Minto, or a URL"))
        ),
        textAreaInput(ns("extra"), "Extra guidance (optional):", rows = 2, width = "100%"),

        hr(),
        fluidRow(
          column(4, actionButton(ns("generate"), "Generate Message Hierarchy", icon = icon("magic"),
                                 class = "btn-primary btn-lg", style = "width: 100%;")),
          column(4, actionButton(ns("parse_and_upload"), "Parse & Upload Direct", icon = icon("cloud-upload-alt"),
                                 class = "btn-success btn-lg", style = "width: 100%;")),
          column(4, downloadButton(ns("download"), "Download Text", class = "btn-warning", style = "width: 100%;"))
        )
      )
    ),

    fluidRow(
      box(
        title = "Generated Structure (raw delimited text - editable)",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,

        div(id = ns("loading_spinner"), style = "display: none; text-align: center; padding: 20px;",
            icon("spinner", class = "fa-spin fa-3x"),
            h4("Generating message hierarchy...")),

        textAreaInput(ns("generated_text_edit"), NULL, rows = 14, width = "100%",
                      placeholder = "Generated text will appear here. You can edit it before uploading."),
        actionButton(ns("reparse_preview"), "Re-Parse & Update Preview", icon = icon("sync"),
                     class = "btn-info", style = "width: 100%;"),
        br(), br(),
        htmlOutput(ns("gen_status")),
        htmlOutput(ns("preview_html"))
      )
    ),

    fluidRow(
      box(
        title = "View a Saved Message Hierarchy",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        fluidRow(
          column(3, selectInput(ns("viz_category"), "Category: *", choices = NULL)),
          column(3, selectInput(ns("viz_domain"), "Domain: *", choices = NULL)),
          column(3, selectInput(ns("viz_topic"), "Topic: *", choices = NULL)),
          column(3, selectInput(ns("viz_map_id"), "Version: *", choices = NULL))
        ),
        fluidRow(
          column(6, checkboxInput(ns("show_cross_links"), "Show call-back links (dashed orange)", value = TRUE)),
          column(6, actionButton(ns("load_map"), "Load Hierarchy", class = "btn-success btn-lg",
                                 icon = icon("project-diagram"), style = "width: 100%;"))
        ),
        htmlOutput(ns("status"))
      )
    ),

    fluidRow(
      box(
        title = "Message Hierarchy",
        status = "success",
        solidHeader = TRUE,
        width = 8,
        collapsible = TRUE,
        p(style = "color: #7f8c8d; font-size: 12px;",
          "The core message is the root on the left; each branch is a supporting point, then its evidence. ",
          "Click a circle to collapse/expand, click a label to read it on the right."),
        export_controls_ui(ns, ns("export_target"), "message_hierarchy"),
        uiOutput(ns("network"))
      ),
      box(
        title = "Selected Node",
        status = "info",
        solidHeader = TRUE,
        width = 4,
        collapsible = TRUE,
        htmlOutput(ns("node_detail"))
      )
    )
  )
}

# ==== Server =======================================================================================

message_hierarchy_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    # Category is locked to the reserved MessageHierarchy value.
    cat_dom_topic <- setup_category_domain_topic_cascade(
      input, output, session, api_manager,
      "bq_get_mindmap_taxonomy_messages", "empty_mindmap_taxonomy", "state_trigger_mindmap",
      fixed_category = MESSAGE_HIERARCHY_CATEGORY
    )
    observe({ shinyjs::disable("category_select") })

    # Viewer (shared with the regular Mind Map viewer) - messages only
    mindmap_viewer_logic(input, output, session, api_manager, "bq_get_mindmap_taxonomy_messages")

    observeEvent(input$generate, {

      if (!api_manager$claude_authenticated) {
        showNotification("Please configure and save Editing Tool API credentials first!", type = "error", duration = 10)
        return()
      }
      cdt <- cat_dom_topic()
      if (nchar(cdt$domain) == 0 || nchar(cdt$topic) == 0) {
        showNotification("Please select or enter a Domain and Topic!", type = "error")
        return()
      }
      if (nchar(trimws(input$core_message)) == 0 || nchar(trimws(input$outcome)) == 0) {
        showNotification("Please enter the core message and the critical outcome!", type = "error")
        return()
      }

      n_points <- input$n_points %||% 3
      ev <- input$evidence_per_point %||% 2
      words_per_node <- input$words_per_node %||% 40
      total_nodes <- 1 + n_points + n_points * ev
      map_title <- if (nchar(trimws(input$map_title)) > 0) trimws(input$map_title) else cdt$topic

      request <- build_message_hierarchy_request(
        core_message = trimws(input$core_message), n_points = n_points,
        outcome = trimws(input$outcome), audience = input$audience %||% "",
        reference = input$reference %||% "", evidence_per_point = ev,
        extra = input$extra %||% ""
      )
      prompt <- generate_mindmap_prompt(
        category = MESSAGE_HIERARCHY_CATEGORY, domain = cdt$domain, topic = cdt$topic,
        map_title = map_title, request_description = request,
        include_latex = FALSE, words_per_node = words_per_node,
        max_nodes = total_nodes, max_depth = 2,
        max_root_children = n_points, max_children_per_node = max(ev, 1)
      )
      max_tokens <- estimate_mindmap_max_tokens(total_nodes, words_per_node, FALSE)

      shinyjs::show("loading_spinner")
      updateTextAreaInput(session, "generated_text_edit", value = "")
      progress_msg <- reactiveVal("Sending request...")
      output$gen_status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " ", progress_msg())
      })

      tryCatch({
        response_text <- api_manager$call_claude(
          prompt = prompt, max_tokens = max_tokens,
          progress_callback = function(msg) progress_msg(msg)
        )
        truncated <- identical(attr(response_text, "claude_stop_reason"), "max_tokens")
        updateTextAreaInput(session, "generated_text_edit", value = response_text)
        output$preview_html <- renderUI({
          render_mindmap_preview(response_text, max_root_children = n_points,
                                 max_children_per_node = max(ev, 1))
        })
        output$gen_status <- renderUI({
          if (truncated) {
            tags$div(class = "status-error", tags$i(class = "fa fa-exclamation-triangle"),
                     " Response was cut off by the token limit. Reduce the points/evidence or words per node and regenerate.")
          } else {
            tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                     sprintf(" Generated (%d characters). Review, then 'Parse & Upload Direct'.", nchar(response_text)))
          }
        })
        shinyjs::hide("loading_spinner")
      }, error = function(e) {
        shinyjs::hide("loading_spinner")
        output$gen_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Generation failed: ", app_err_text(e))
        })
        showNotification(paste("Error:", app_err_text(e)), type = "error", duration = 15)
      })
    })

    observeEvent(input$reparse_preview, {
      if (nchar(trimws(input$generated_text_edit)) == 0) {
        showNotification("Nothing to re-parse - the text box is empty.", type = "warning")
        return()
      }
      output$preview_html <- renderUI({
        render_mindmap_preview(input$generated_text_edit,
                               max_root_children = input$n_points %||% 3,
                               max_children_per_node = max(input$evidence_per_point %||% 2, 1))
      })
    })

    observeEvent(input$parse_and_upload, {
      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }
      if (nchar(trimws(input$generated_text_edit)) == 0) {
        showNotification("Nothing to upload. Generate first.", type = "warning")
        return()
      }
      cdt <- cat_dom_topic()
      if (nchar(cdt$domain) == 0 || nchar(cdt$topic) == 0) {
        showNotification("Please select or enter a Domain and Topic!", type = "error")
        return()
      }

      tryCatch({
        parsed <- parse_mindmap_creation_text(input$generated_text_edit)
        pruned <- prune_empty_disconnected_nodes(parsed$nodes)
        parsed$nodes <- pruned$nodes

        validation <- validate_tree_structure(
          parsed$nodes,
          max_root_children = input$n_points %||% 3,
          max_children_per_node = max(input$evidence_per_point %||% 2, 1)
        )
        if (!validation$valid) {
          output$gen_status <- renderUI({
            tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"),
                     " Structural problems - NOT uploaded:", tags$ul(lapply(validation$issues, tags$li)))
          })
          return()
        }

        title <- if (nchar(trimws(input$map_title)) > 0) trimws(input$map_title) else parsed$map_title
        map_id <- generate_new_map_id(title)

        upload_df <- parsed$nodes
        upload_df$change_type <- "create"
        # Category/domain/topic are enforced from the dropdowns, never trusted from Claude's echo.
        upload_df$category <- MESSAGE_HIERARCHY_CATEGORY
        upload_df$domain <- cdt$domain
        upload_df$topic <- cdt$topic
        upload_df$map_id <- map_id
        upload_df$map_title <- title

        n <- api_manager$bq_insert_mindmap(upload_df, source = "claude")
        api_manager$trigger_state_update_mindmap()

        output$gen_status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Uploaded %d node(s) as '%s' (map_id: %s). Select it in 'View a Saved Message Hierarchy' below.",
                           n, title, map_id))
        })
        showNotification(sprintf("✓ Uploaded %d node(s)!", n), type = "message")
      }, error = function(e) {
        output$gen_status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", app_err_text(e))
        })
        showNotification(paste("Error:", app_err_text(e)), type = "error")
      })
    })

    output$download <- downloadHandler(
      filename = function() paste0("message_hierarchy_", format(Sys.Date(), "%Y%m%d"), ".txt"),
      content = function(file) writeLines(input$generated_text_edit %||% "", file)
    )

  })
}
