# modules/API Settings/bq_config.R
# Subtab: BigQuery Config (under the "API Settings" main tab)
# Configures the ONE project/dataset shared by all three suites, and the
# three table names (contacts, communications, funding programmes).

bq_config_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Google Cloud BigQuery Configuration",
        status = "primary", solidHeader = TRUE, width = 12,

        p("Configure the Google Cloud BigQuery connection shared by Communications and Funding Programmes."),
        br(),

        fluidRow(
          column(6, textInput(ns("bq_project"), "Project ID:", value = "atera-2", width = "100%")),
          column(6, textInput(ns("bq_dataset"), "Dataset Name:", value = "business_strategy", width = "100%"))
        ),

        h4("Table Names:"),
        fluidRow(
          column(4, textInput(ns("bq_table_contacts"), "Contacts Table:", value = "business_contacts", width = "100%")),
          column(4, textInput(ns("bq_table_comm"), "Communications Table:", value = "contact_communications", width = "100%")),
          column(4, textInput(ns("bq_table_funding"), "Funding Programmes Table:", value = "funding_programmes", width = "100%"))
        ),
        fluidRow(
          column(4, textInput(ns("bq_table_bm_canvas"), "BM Canvas Table:", value = "business_model_canvas", width = "100%")),
          column(4, textInput(ns("bq_table_de_canvas"), "DE Canvas Table:", value = "disciplined_entrepreneurship_canvas", width = "100%")),
          column(4, textInput(ns("bq_table_de_roadmap"), "DE Roadmap Table:", value = "disciplined_entrepreneurship_roadmap", width = "100%"))
        ),

        br(),
        h4("Authentication Method:"),
        radioButtons(ns("bq_auth_method"), NULL,
                     choices = c("Service Account JSON Key File" = "json_key",
                                 "Application Default Credentials" = "adc"),
                     selected = "json_key", inline = TRUE),

        conditionalPanel(
          condition = sprintf("input['%s'] == 'json_key'", ns("bq_auth_method")),
          fileInput(ns("bq_key_file"), "Upload Service Account JSON Key:", accept = ".json", width = "100%")
        ),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'adc'", ns("bq_auth_method")),
          p(tags$small("Using Application Default Credentials. Make sure you have run:"),
            tags$br(), tags$code("gcloud auth application-default login"))
        ),

        br(),
        actionButton(ns("save_bq"), "Save BigQuery Settings", class = "btn-success", icon = icon("save")),
        actionButton(ns("test_bq"), "Test Connection & Load Data", class = "btn-info", icon = icon("database")),
        actionButton(ns("create_table_bq"), "Create Empty Tables", class = "btn-warning", icon = icon("plus")),
        br(), br(),
        uiOutput(ns("bq_status_ui")),

        br(),
        div(class = "schema-info",
            h5("business_contacts"),
            p("contact_id, full_name, industry, company, job_title, location, country, email, phone, ",
              "linkedin, areas_of_interest, university, academic_background, user_notes, ",
              "last_interaction_date, created_at, updated_at"),
            h5("contact_communications"),
            p("message_id, contact_id, channel_type, communication_purpose, language, message_length, ",
              "message_content, created_at"),
            h5("funding_programmes"),
            p("id, created_at, category, country, city_region, programme_name, amount_of_money, conditions, ",
              "key_sponsors, key_organiser_profiles, areas_of_application, start_date_for_applying, deadline, ",
              "recommendations_for_applying, verified_urls"),
            h5("business_model_canvas"),
            p("canvas_id, created_at, updated_at, business_area, project, business_focus, key_partners, ",
              "key_activities, key_resources, value_propositions, customer_relationships, channels, ",
              "customer_segments, cost_structure, revenue_streams"),
            h5("disciplined_entrepreneurship_canvas"),
            p("canvas_id, created_at, updated_at, business_area, project, business_focus, raison_detre, ",
              "initial_market, value_creation, competitive_advantage, customer_acquisition, ",
              "product_unit_economics, sales, overall_economics, design_build, scaling"),
            h5("disciplined_entrepreneurship_roadmap"),
            p("roadmap_id, created_at, updated_at, business_area, project, business_focus, and 24 ",
              "step_NN_<name> STRING columns (one per Disciplined Entrepreneurship roadmap step)")
        )
      )
    )
  )
}

bq_config_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    output$bq_status_ui <- renderUI({ tags$div() })

    observeEvent(input$save_bq, {
      api_manager$bq_project_id <- trimws(input$bq_project)
      api_manager$bq_dataset_id <- trimws(input$bq_dataset)
      api_manager$bq_table_contacts <- trimws(input$bq_table_contacts)
      api_manager$bq_table_communications <- trimws(input$bq_table_comm)
      api_manager$bq_table_funding <- trimws(input$bq_table_funding)
      api_manager$bq_table_bm_canvas <- trimws(input$bq_table_bm_canvas)
      api_manager$bq_table_de_canvas <- trimws(input$bq_table_de_canvas)
      api_manager$bq_table_de_roadmap <- trimws(input$bq_table_de_roadmap)
      api_manager$recompute_full_table_ids()

      if (input$bq_auth_method == "json_key" && !is.null(input$bq_key_file)) {
        api_manager$bq_credentials_path <- input$bq_key_file$datapath
      }

      output$bq_status_ui <- renderUI({
        div(class = "api-status-success", icon("check-circle"), " BigQuery settings saved!",
            tags$br(), tags$small("Project: ", api_manager$bq_project_id, " | Dataset: ", api_manager$bq_dataset_id),
            tags$br(), tags$small("Contacts: ", api_manager$bq_table_contacts,
                                   " | Communications: ", api_manager$bq_table_communications,
                                   " | Funding: ", api_manager$bq_table_funding),
            tags$br(), tags$small("BM Canvas: ", api_manager$bq_table_bm_canvas,
                                   " | DE Canvas: ", api_manager$bq_table_de_canvas,
                                   " | DE Roadmap: ", api_manager$bq_table_de_roadmap))
      })
      showNotification("BigQuery settings saved!", type = "message", duration = 3)
    })

    observeEvent(input$test_bq, {
      showNotification("Testing BigQuery connection and loading data...", type = "message", duration = NULL, id = "test_bq")

      tryCatch({
        api_manager$authenticate_bigquery(
          credentials_path = if (input$bq_auth_method == "json_key") api_manager$bq_credentials_path else NULL
        )
        contacts <- api_manager$bq_load_contacts()

        removeNotification(id = "test_bq")
        output$bq_status_ui <- renderUI({
          div(class = "api-status-success", icon("check-circle"), " BigQuery connection successful!",
              tags$br(), tags$small(nrow(contacts), " contacts loaded from ", api_manager$bq_full_table_contacts))
        })
        showNotification(paste("BigQuery connected!", nrow(contacts), "contacts loaded."), type = "message", duration = 5)

      }, error = function(e) {
        removeNotification(id = "test_bq")
        output$bq_status_ui <- renderUI({
          div(class = "api-status-error", icon("exclamation-circle"), " Connection failed: ", e$message)
        })
        showNotification(paste("BigQuery Error:", e$message), type = "error", duration = 10)
      })
    })

    observeEvent(input$create_table_bq, {
      if (!api_manager$bq_authenticated) {
        showNotification("Please test/authenticate the connection first!", type = "error", duration = 3)
        return()
      }

      showNotification("Creating BigQuery tables...", type = "message", duration = NULL, id = "create_bq")

      results <- api_manager$create_all_tables()
      removeNotification(id = "create_bq")

      output$bq_status_ui <- renderUI({
        div(class = "api-status-success", icon("check-circle"), " Table check complete:",
            tags$br(), lapply(results, function(r) tagList(tags$small(r), tags$br())))
      })
      showNotification("BigQuery tables ready!", type = "message", duration = 5)
    })
  })
}
