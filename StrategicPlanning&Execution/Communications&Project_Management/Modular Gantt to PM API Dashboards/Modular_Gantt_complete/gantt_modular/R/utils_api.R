# R/utils_api.R
# APIManager R6 Class - Manages Trello, Jira, and Email connections
# Uses reactive triggers for cross-module state updates
# ==================================================================

library(R6)
library(httr)
library(jsonlite)
library(blastula)

APIManager <- R6::R6Class(
  "APIManager",
  
  public = list(
    # Trello API credentials
    trello_key = NULL,
    trello_token = NULL,
    trello_board_id = NULL,
    trello_connected = FALSE,
    
    # Jira API credentials
    jira_url = NULL,
    jira_email = NULL,
    jira_token = NULL,
    jira_project_key = NULL,
    jira_connected = FALSE,
    
    # Email SMTP credentials
    smtp_config = list(),
    email_connected = FALSE,
    
    # Data storage
    gantt_data = NULL,
    contacts_data = NULL,
    contacts_file = "contacts_database.xlsx",
    
    # ⭐ CRITICAL: Reactive trigger for cross-module updates
    state_trigger = NULL,
    
    # Initialize
    initialize = function() {
      # Initialize reactive trigger - MUST be inside a reactive context
      self$state_trigger <- shiny::reactiveVal(0)
      
      # Load contacts if file exists
      if (file.exists(self$contacts_file)) {
        tryCatch({
          self$contacts_data <- readxl::read_excel(self$contacts_file)
        }, error = function(e) {
          self$contacts_data <- data.frame(
            Country = character(),
            City = character(),
            Organization = character(),
            Full_Name = character(),
            LinkedIn = character(),
            Email = character(),
            Phone = character(),
            Date_Added = character(),
            stringsAsFactors = FALSE
          )
        })
      } else {
        self$contacts_data <- data.frame(
          Country = character(),
          City = character(),
          Organization = character(),
          Full_Name = character(),
          LinkedIn = character(),
          Email = character(),
          Phone = character(),
          Date_Added = character(),
          stringsAsFactors = FALSE
        )
      }
      
      cat("🔌 API Manager initialized with reactive trigger\n")
    },
    
    # Trigger state update - fires reactive observers in all modules
    trigger_state_update = function() {
      current <- self$state_trigger()
      self$state_trigger(current + 1)
      cat("🔔 State trigger fired:", current + 1, "\n")
    },
    
    # ============================================================
    # TRELLO API METHODS
    # ============================================================
    
    set_trello_credentials = function(key, token, board_id = NULL) {
      self$trello_key <- key
      self$trello_token <- token
      self$trello_board_id <- board_id
    },
    
    test_trello_connection = function() {
      if (is.null(self$trello_key) || is.null(self$trello_token)) {
        stop("Trello credentials not set")
      }
      
      tryCatch({
        response <- GET(
          url = "https://api.trello.com/1/members/me",
          query = list(
            key = self$trello_key,
            token = self$trello_token
          )
        )
        
        if (status_code(response) == 200) {
          self$trello_connected <- TRUE
          self$trigger_state_update()
          user_data <- content(response)
          return(list(success = TRUE, name = user_data$fullName))
        } else {
          self$trello_connected <- FALSE
          stop(paste("Connection failed:", status_code(response)))
        }
      }, error = function(e) {
        self$trello_connected <- FALSE
        stop(paste("Error:", e$message))
      })
    },
    
    get_trello_lists = function() {
      if (is.null(self$trello_board_id)) {
        stop("Trello board ID not set")
      }
      
      response <- GET(
        url = paste0("https://api.trello.com/1/boards/", self$trello_board_id, "/lists"),
        query = list(
          key = self$trello_key,
          token = self$trello_token
        )
      )
      
      if (status_code(response) == 200) {
        lists <- content(response)
        return(lists)
      } else {
        stop(paste("Failed to load lists:", status_code(response)))
      }
    },
    
    create_trello_card = function(list_id, name, description) {
      response <- POST(
        url = "https://api.trello.com/1/cards",
        query = list(
          key = self$trello_key,
          token = self$trello_token,
          idList = list_id,
          name = name,
          desc = description
        )
      )
      
      return(status_code(response) == 200)
    },
    
    # ============================================================
    # JIRA API METHODS
    # ============================================================
    
    set_jira_credentials = function(url, email, token, project_key) {
      self$jira_url <- url
      self$jira_email <- email
      self$jira_token <- token
      self$jira_project_key <- project_key
    },
    
    test_jira_connection = function() {
      if (is.null(self$jira_url) || is.null(self$jira_email) || is.null(self$jira_token)) {
        stop("Jira credentials not set")
      }
      
      tryCatch({
        auth_string <- paste0(self$jira_email, ":", self$jira_token)
        auth_encoded <- openssl::base64_encode(charToRaw(auth_string))
        
        response <- GET(
          url = paste0(self$jira_url, "/rest/api/3/myself"),
          add_headers(
            Authorization = paste("Basic", auth_encoded),
            "Content-Type" = "application/json"
          )
        )
        
        if (status_code(response) == 200) {
          self$jira_connected <- TRUE
          self$trigger_state_update()
          user_data <- content(response)
          return(list(success = TRUE, name = user_data$displayName))
        } else {
          self$jira_connected <- FALSE
          stop(paste("Connection failed:", status_code(response)))
        }
      }, error = function(e) {
        self$jira_connected <- FALSE
        stop(paste("Error:", e$message))
      })
    },
    
    create_jira_issue = function(summary, description, issue_type, priority = NULL, labels = NULL) {
      auth_string <- paste0(self$jira_email, ":", self$jira_token)
      auth_encoded <- openssl::base64_encode(charToRaw(auth_string))
      
      issue_data <- list(
        fields = list(
          project = list(key = self$jira_project_key),
          summary = summary,
          description = description,
          issuetype = list(name = issue_type)
        )
      )
      
      if (!is.null(priority)) {
        issue_data$fields$priority <- list(name = priority)
      }
      
      if (!is.null(labels) && length(labels) > 0) {
        issue_data$fields$labels <- labels
      }
      
      response <- POST(
        url = paste0(self$jira_url, "/rest/api/3/issue"),
        add_headers(
          Authorization = paste("Basic", auth_encoded),
          "Content-Type" = "application/json"
        ),
        body = toJSON(issue_data, auto_unbox = TRUE),
        encode = "json"
      )
      
      if (status_code(response) == 201) {
        issue_key <- content(response)$key
        return(list(success = TRUE, key = issue_key))
      } else {
        return(list(success = FALSE, error = status_code(response)))
      }
    },
    
    # ============================================================
    # EMAIL SMTP METHODS
    # ============================================================
    
    set_smtp_config = function(host, port, user, password, use_ssl) {
      self$smtp_config <- list(
        host = host,
        port = port,
        user = user,
        password = password,
        ssl = use_ssl
      )
    },
    
    test_email_connection = function() {
      if (length(self$smtp_config) == 0) {
        stop("Email configuration not set")
      }
      
      tryCatch({
        smtp_creds <- creds(
          user = self$smtp_config$user,
          password = self$smtp_config$password,
          host = self$smtp_config$host,
          port = self$smtp_config$port,
          use_ssl = self$smtp_config$ssl
        )
        
        test_email <- compose_email(
          body = md("# Test Email\n\nThis is a test email from the Gantt to Tickets Converter app.\nYour email configuration is working correctly!")
        )
        
        test_email %>%
          smtp_send(
            to = self$smtp_config$user,
            from = self$smtp_config$user,
            subject = "Test Email - Gantt to Tickets App",
            credentials = smtp_creds
          )
        
        self$email_connected <- TRUE
        self$trigger_state_update()
        return(TRUE)
        
      }, error = function(e) {
        self$email_connected <- FALSE
        stop(paste("Email test failed:", e$message))
      })
    },
    
    send_email = function(to, subject, body, cc = NULL) {
      if (!self$email_connected) {
        stop("Email not configured")
      }
      
      smtp_creds <- creds(
        user = self$smtp_config$user,
        password = self$smtp_config$password,
        host = self$smtp_config$host,
        port = self$smtp_config$port,
        use_ssl = self$smtp_config$ssl
      )
      
      email <- compose_email(body = md(body))
      
      email %>%
        smtp_send(
          to = to,
          from = self$smtp_config$user,
          subject = subject,
          credentials = smtp_creds
        )
      
      return(TRUE)
    }
  )
)

`%||%` <- function(x, y) if (is.null(x)) y else x
