# R/utils_contact_manager.R
# ContactManager R6 Class + Email Utilities
# =================================================================================

library(R6)
library(httr)
library(jsonlite)
library(bigrquery)
library(DBI)
library(uuid)
library(pdftools)
library(readtext)
library(base64enc)

# Email sending function using curl
send_email_with_curl <- function(from, to, subject, body, host, port, username, password, attachments = NULL) {
  
  # Generate boundary for MIME multipart
  boundary <- paste0("----=_Part_", as.integer(as.numeric(Sys.time()) * 1000))
  
  # Start building email content with MIME headers
  email_content <- c(
    paste0("From: ", from),
    paste0("To: ", paste(to, collapse = ", ")),
    paste0("Subject: ", subject),
    "MIME-Version: 1.0"
  )
  
  # Check if we have attachments
  if (!is.null(attachments) && length(attachments) > 0) {
    # Multipart email with attachments
    email_content <- c(
      email_content,
      paste0('Content-Type: multipart/mixed; boundary="', boundary, '"'),
      "",
      paste0("--", boundary),
      "Content-Type: text/plain; charset=UTF-8",
      "Content-Transfer-Encoding: 7bit",
      "",
      body,
      ""
    )
    
    # Add each attachment
    for (att in attachments) {
      if (file.exists(att$path)) {
        # Read file and encode to base64
        file_raw <- readBin(att$path, "raw", file.info(att$path)$size)
        file_b64 <- base64enc::base64encode(file_raw)
        
        # Determine content type
        ext <- tolower(tools::file_ext(att$name))
        content_type <- switch(ext,
                               "pdf" = "application/pdf",
                               "doc" = "application/msword",
                               "docx" = "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                               "xls" = "application/vnd.ms-excel",
                               "xlsx" = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                               "txt" = "text/plain",
                               "csv" = "text/csv",
                               "jpg" = "image/jpeg",
                               "jpeg" = "image/jpeg",
                               "png" = "image/png",
                               "gif" = "image/gif",
                               "zip" = "application/zip",
                               "application/octet-stream"
        )
        
        email_content <- c(
          email_content,
          paste0("--", boundary),
          paste0('Content-Type: ', content_type, '; name="', att$name, '"'),
          "Content-Transfer-Encoding: base64",
          paste0('Content-Disposition: attachment; filename="', att$name, '"'),
          "",
          file_b64,
          ""
        )
      }
    }
    
    # Close multipart boundary
    email_content <- c(email_content, paste0("--", boundary, "--"))
    
  } else {
    # Simple email without attachments
    email_content <- c(
      email_content,
      "Content-Type: text/plain; charset=UTF-8",
      "",
      body
    )
  }
  
  # Write to temporary file
  email_file <- tempfile(fileext = ".eml")
  writeLines(email_content, email_file, useBytes = TRUE)
  
  # Build curl command
  curl_cmd <- sprintf(
    'curl --url "smtps://%s:%s" --ssl-reqd --mail-from "%s" --user "%s:%s" --upload-file "%s"',
    host,
    port,
    from,
    username,
    password,
    email_file
  )
  
  # Add recipients
  for (recipient in to) {
    curl_cmd <- paste0(curl_cmd, sprintf(' --mail-rcpt "%s"', recipient))
  }
  
  # Execute curl command
  result <- system(curl_cmd, intern = TRUE, ignore.stderr = FALSE)
  
  # Clean up
  if (file.exists(email_file)) file.remove(email_file)
  
  return(TRUE)
}

# Extract text from files
extract_text_from_file <- function(file_path, file_type) {
  tryCatch({
    if (grepl("\\.pdf$", file_type, ignore.case = TRUE)) {
      text <- paste(pdftools::pdf_text(file_path), collapse = "\n")
    } else if (grepl("\\.(docx?|pptx?)$", file_type, ignore.case = TRUE)) {
      result <- readtext::readtext(file_path)
      text <- result$text
    } else if (grepl("\\.txt$", file_type, ignore.case = TRUE)) {
      text <- paste(readLines(file_path, warn = FALSE), collapse = "\n")
    } else {
      text <- paste(readLines(file_path, warn = FALSE), collapse = "\n")
    }
    return(text)
  }, error = function(e) {
    return(paste("Error extracting text:", e$message))
  })
}

# ContactManager R6 Class
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
    
    call_llm = function(prompt, system_message = NULL, max_tokens = 1000, temperature = 0.3) {
      if (!self$api_authenticated) {
        stop("Not authenticated to OpenAI API")
      }
      
      messages <- list()
      if (!is.null(system_message)) {
        messages[[1]] <- list(role = "system", content = system_message)
        messages[[2]] <- list(role = "user", content = prompt)
      } else {
        messages[[1]] <- list(role = "user", content = prompt)
      }
      
      response <- httr::POST(
        url = "https://api.openai.com/v1/chat/completions",
        httr::add_headers(
          "Authorization" = paste("Bearer", self$api_key),
          "Content-Type" = "application/json"
        ),
        body = jsonlite::toJSON(list(
          model = self$gpt_model,
          messages = messages,
          max_tokens = max_tokens,
          temperature = temperature
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
    
    load_recent_communications = function(contact_id, limit = 3) {
      con <- dbConnect(
        bigrquery::bigquery(),
        project = self$bq_project,
        dataset = self$bq_dataset,
        billing = self$bq_project
      )
      
      query <- sprintf("
        SELECT *
        FROM `%s.%s.%s`
        WHERE contact_id = '%s'
        ORDER BY created_at DESC
        LIMIT %d
      ", self$bq_project, self$bq_dataset, self$bq_comm_table, contact_id, limit)
      
      messages_data <- dbGetQuery(con, query)
      dbDisconnect(con)
      
      return(messages_data)
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
