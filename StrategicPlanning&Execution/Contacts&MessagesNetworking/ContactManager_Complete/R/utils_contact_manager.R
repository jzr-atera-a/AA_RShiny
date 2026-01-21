# R/utils_contact_manager.R
# ContactManager R6 Class - Manages API connections, BigQuery, SMTP, and app state
# Uses reactive triggers for cross-module state updates
# =================================================================================

library(R6)
library(httr)
library(jsonlite)
library(bigrquery)
library(DBI)
library(uuid)

ContactManager <- R6::R6Class(
  "ContactManager",
  
  public = list(
    # OpenAI API credentials
    api_key = NULL,
    gpt_model = "gpt-4",
    api_authenticated = FALSE,
    
    # BigQuery credentials
    bq_project = "atera-2",
    bq_dataset = "business_strategy",
    bq_table = "business_contacts",
    bq_comm_table = "contact_communications",
    bq_credentials = NULL,
    bq_authenticated = FALSE,
    
    # SMTP credentials
    smtp_host = "smtpout.secureserver.net",
    smtp_port = "465",
    smtp_username = NULL,
    smtp_password = NULL,
    smtp_connected = FALSE,
    
    # Data storage
    contacts_data = NULL,
    communications_data = NULL,
    extracted_data = NULL,
    selected_contact = NULL,
    selected_contact_email = NULL,
    recent_messages = NULL,
    communication_summary = NULL,
    generated_message = NULL,
    
    # Reactive trigger for cross-module updates
    state_trigger = NULL,
    
    # Initialize
    initialize = function() {
      self$state_trigger <- shiny::reactiveVal(0)
      cat("🔌 Contact Manager initialized with reactive trigger\n")
    },
    
    # Trigger state update
    trigger_state_update = function() {
      current <- self$state_trigger()
      self$state_trigger(current + 1)
      cat("🔔 State trigger fired:", current + 1, "\n")
    },
    
    # ============================================================
    # OpenAI API METHODS
    # ============================================================
    
    set_api_credentials = function(api_key, model = NULL) {
      self$api_key <- api_key
      if (!is.null(model)) self$gpt_model <- model
      self$api_authenticated <- TRUE
      self$trigger_state_update()
    },
    
    test_api_connection = function() {
      if (is.null(self$api_key)) {
        stop("API key not set")
      }
      
      tryCatch({
        response <- httr::POST(
          url = "https://api.openai.com/v1/chat/completions",
          httr::add_headers(
            "Authorization" = paste("Bearer", self$api_key),
            "Content-Type" = "application/json"
          ),
          body = jsonlite::toJSON(list(
            model = self$gpt_model,
            messages = list(
              list(role = "user", content = "Test")
            ),
            max_tokens = 10
          ), auto_unbox = TRUE),
          encode = "json",
          httr::timeout(60)
        )
        
        if (httr::status_code(response) == 200) {
          return(TRUE)
        } else {
          stop(paste("Status code:", httr::status_code(response)))
        }
      }, error = function(e) {
        stop(paste("Connection failed:", e$message))
      })
    },
    
    call_llm = function(prompt, max_tokens = 1000) {
      if (!self$api_authenticated) {
        stop("Not authenticated to OpenAI API")
      }
      
      response <- httr::POST(
        url = "https://api.openai.com/v1/chat/completions",
        httr::add_headers(
          "Authorization" = paste("Bearer", self$api_key),
          "Content-Type" = "application/json"
        ),
        body = jsonlite::toJSON(list(
          model = self$gpt_model,
          messages = list(
            list(role = "user", content = prompt)
          ),
          max_tokens = max_tokens,
          temperature = 0.3
        ), auto_unbox = TRUE),
        encode = "json",
        httr::timeout(120)
      )
      
      if (httr::status_code(response) == 200) {
        content_response <- httr::content(response, "parsed")
        return(content_response$choices[[1]]$message$content)
      } else {
        stop(paste("API Error:", httr::status_code(response)))
      }
    },
    
    # ============================================================
    # BigQuery METHODS
    # ============================================================
    
    set_bigquery_credentials = function(project, dataset, table, comm_table, credentials = NULL) {
      self$bq_project <- project
      self$bq_dataset <- dataset
      self$bq_table <- table
      self$bq_comm_table <- comm_table
      if (!is.null(credentials)) {
        self$bq_credentials <- credentials
      }
    },
    
    authenticate_bigquery = function(json_path = NULL) {
      if (!is.null(json_path)) {
        bigrquery::bq_auth(path = json_path)
        self$bq_credentials <- json_path
      }
      self$bq_authenticated <- TRUE
      self$trigger_state_update()
    },
    
    test_bigquery_connection = function() {
      con <- dbConnect(
        bigrquery::bigquery(),
        project = self$bq_project,
        dataset = self$bq_dataset,
        billing = self$bq_project
      )
      
      # Try to load contacts data
      contacts_query <- sprintf("SELECT * FROM `%s.%s.%s`", 
                                self$bq_project, self$bq_dataset, self$bq_table)
      
      tryCatch({
        self$contacts_data <- dbGetQuery(con, contacts_query)
      }, error = function(e) {
        self$contacts_data <- data.frame()
      })
      
      # Try to load communications data
      comm_query <- sprintf("SELECT * FROM `%s.%s.%s`", 
                            self$bq_project, self$bq_dataset, self$bq_comm_table)
      
      tryCatch({
        self$communications_data <- dbGetQuery(con, comm_query)
      }, error = function(e) {
        self$communications_data <- data.frame()
      })
      
      dbDisconnect(con)
      self$trigger_state_update()
    },
    
    create_bigquery_tables = function() {
      con <- dbConnect(
        bigrquery::bigquery(),
        project = self$bq_project,
        dataset = self$bq_dataset,
        billing = self$bq_project
      )
      
      # Create contacts table
      contacts_schema <- sprintf("
        CREATE TABLE IF NOT EXISTS `%s.%s.%s` (
          contact_id STRING,
          full_name STRING,
          industry STRING,
          company STRING,
          job_title STRING,
          location STRING,
          country STRING,
          email STRING,
          phone STRING,
          linkedin STRING,
          areas_of_interest STRING,
          university STRING,
          academic_background STRING,
          user_notes STRING,
          last_interaction_date DATE,
          created_at TIMESTAMP,
          updated_at TIMESTAMP
        )", self$bq_project, self$bq_dataset, self$bq_table)
      
      dbExecute(con, contacts_schema)
      
      # Create communications table
      comm_schema <- sprintf("
        CREATE TABLE IF NOT EXISTS `%s.%s.%s` (
          message_id STRING,
          contact_id STRING,
          channel_type STRING,
          communication_purpose STRING,
          language STRING,
          message_length STRING,
          message_content STRING,
          created_at TIMESTAMP
        )", self$bq_project, self$bq_dataset, self$bq_comm_table)
      
      dbExecute(con, comm_schema)
      
      dbDisconnect(con)
      
      # Initialize empty data
      self$contacts_data <- data.frame()
      self$communications_data <- data.frame()
      self$trigger_state_update()
    },
    
    insert_contact = function(record) {
      con <- dbConnect(
        bigrquery::bigquery(),
        project = self$bq_project,
        dataset = self$bq_dataset,
        billing = self$bq_project
      )
      
      dbWriteTable(
        conn = con,
        name = self$bq_table,
        value = record,
        append = TRUE,
        row.names = FALSE
      )
      
      dbDisconnect(con)
      
      # Update local cache
      if (is.null(self$contacts_data) || nrow(self$contacts_data) == 0) {
        self$contacts_data <- record
      } else {
        self$contacts_data <- rbind(self$contacts_data, record)
      }
      
      self$trigger_state_update()
    },
    
    insert_communication = function(record) {
      con <- dbConnect(
        bigrquery::bigquery(),
        project = self$bq_project,
        dataset = self$bq_dataset,
        billing = self$bq_project
      )
      
      dbWriteTable(
        conn = con,
        name = self$bq_comm_table,
        value = record,
        append = TRUE,
        row.names = FALSE
      )
      
      dbDisconnect(con)
      
      # Update local cache
      if (is.null(self$communications_data) || nrow(self$communications_data) == 0) {
        self$communications_data <- record
      } else {
        self$communications_data <- rbind(self$communications_data, record)
      }
      
      self$trigger_state_update()
    },
    
    delete_contact = function(contact_id) {
      # Delete from local cache
      self$contacts_data <- self$contacts_data[self$contacts_data$contact_id != contact_id, ]
      
      if (!is.null(self$communications_data) && nrow(self$communications_data) > 0) {
        self$communications_data <- self$communications_data[
          self$communications_data$contact_id != contact_id, 
        ]
      }
      
      self$trigger_state_update()
    },
    
    # ============================================================
    # SMTP METHODS
    # ============================================================
    
    set_smtp_credentials = function(host, port, username, password) {
      self$smtp_host <- host
      self$smtp_port <- port
      self$smtp_username <- username
      self$smtp_password <- password
      self$smtp_connected <- TRUE
      self$trigger_state_update()
    },
    
    # ============================================================
    # Helper functions
    # ============================================================
    
    set_selected_contact = function(contact) {
      self$selected_contact <- contact
      if (!is.null(contact$email) && contact$email != "" && contact$email != "Not specified") {
        self$selected_contact_email <- contact$email
      } else {
        self$selected_contact_email <- NULL
      }
      self$trigger_state_update()
    }
  )
)

`%||%` <- function(x, y) if (is.null(x) || x == "" || is.na(x)) y else x
