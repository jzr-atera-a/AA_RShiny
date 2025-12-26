# modules/data_viewer/server.R
# Data Viewer Module Server - Connected to BigQuery

data_viewer_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    
    # Reactive data storage
    current_data <- reactiveVal(NULL)
    categories_list <- reactiveVal(NULL)
    
    # ⭐ Watch for BigQuery authentication
    observe({
      api_manager$state_trigger()  # Watch for auth changes
      
      if (api_manager$bq_authenticated) {
        load_categories()
      } else {
        # Clear if not authenticated
        updateSelectInput(session, "category", choices = c("Select..." = ""))
        updateSelectInput(session, "subcategory", choices = c("Select..." = ""))
      }
    })
    
    # Load categories from BigQuery
    load_categories <- function() {
      if (!api_manager$bq_authenticated) return()
      
      tryCatch({
        # Query distinct categories from BigQuery table
        query <- sprintf(
          "SELECT DISTINCT category FROM `%s` WHERE category IS NOT NULL ORDER BY category",
          api_manager$bq_full_table_id
        )
        
        result <- api_manager$bq_query(query)
        
        if (nrow(result) > 0) {
          categories_list(result$category)
          updateSelectInput(session, "category",
                           choices = c("Select..." = "", result$category))
          
          cat("📊 Loaded", nrow(result), "categories from BigQuery\n")
        } else {
          # If no data, use sample categories
          categories_list(c("Type A", "Type B", "Type C"))
          updateSelectInput(session, "category",
                           choices = c("Select..." = "", "Type A", "Type B", "Type C"))
        }
        
      }, error = function(e) {
        cat("⚠ Error loading categories:", e$message, "\n")
        
        # Fallback to sample data
        categories_list(c("Type A", "Type B", "Type C"))
        updateSelectInput(session, "category",
                         choices = c("Select..." = "", "Type A", "Type B", "Type C"))
        
        output$filter_status <- renderUI({
          tags$div(class = "status-warning",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Using sample data. Connect to BigQuery in API Config for real data.",
                   br(),
                   tags$small("Error: ", e$message))
        })
      })
    }
    
    # ⭐ Cascading dropdown: Level 2 depends on Level 1
    observeEvent(input$category, {
      if (input$category == "") {
        updateSelectInput(session, "subcategory", choices = c("Select..." = ""))
        return()
      }
      
      if (api_manager$bq_authenticated) {
        # Load subcategories from BigQuery
        tryCatch({
          # SQL injection prevention
          safe_category <- gsub("'", "''", input$category)
          
          query <- sprintf(
            "SELECT DISTINCT subcategory FROM `%s` WHERE category = '%s' AND subcategory IS NOT NULL ORDER BY subcategory",
            api_manager$bq_full_table_id,
            safe_category
          )
          
          result <- api_manager$bq_query(query)
          
          if (nrow(result) > 0) {
            updateSelectInput(session, "subcategory",
                             choices = c("Select..." = "", result$subcategory))
          } else {
            # No subcategories found
            updateSelectInput(session, "subcategory",
                             choices = c("Select..." = "", "(No subcategories)"))
          }
          
          output$filter_status <- renderUI({
            tags$div(class = "alert alert-info",
                     tags$i(class = "fa fa-info-circle"),
                     " Category selected: ", input$category,
                     ". Found ", nrow(result), " subcategories. Select one to continue.")
          })
          
        }, error = function(e) {
          cat("⚠ Error loading subcategories:", e$message, "\n")
          
          # Fallback to sample subcategories
          subcategories <- switch(input$category,
            "Type A" = c("Select..." = "", "A1", "A2", "A3"),
            "Type B" = c("Select..." = "", "B1", "B2"),
            "Type C" = c("Select..." = "", "C1", "C2", "C3", "C4"),
            c("Select..." = "")
          )
          
          updateSelectInput(session, "subcategory", choices = subcategories)
        })
      } else {
        # Not authenticated - use sample data
        subcategories <- switch(input$category,
          "Type A" = c("Select..." = "", "A1", "A2", "A3"),
          "Type B" = c("Select..." = "", "B1", "B2"),
          "Type C" = c("Select..." = "", "C1", "C2", "C3", "C4"),
          c("Select..." = "")
        )
        
        updateSelectInput(session, "subcategory", choices = subcategories)
        
        output$filter_status <- renderUI({
          tags$div(class = "alert alert-info",
                   tags$i(class = "fa fa-info-circle"),
                   " Category selected: ", input$category,
                   " (using sample data - connect BigQuery for real data)")
        })
      }
    })
    
    # Load data button
    observeEvent(input$load, {
      req(input$category, input$subcategory)
      
      if (input$category == "" || input$subcategory == "") {
        output$filter_status <- renderUI({
          tags$div(class = "status-warning",
                   tags$i(class = "fa fa-exclamation-triangle"),
                   " Please select both category and subcategory")
        })
        return()
      }
      
      output$filter_status <- renderUI({
        tags$div(class = "status-info",
                 tags$i(class = "fa fa-spinner fa-spin"),
                 " Loading data from BigQuery...")
      })
      
      if (api_manager$bq_authenticated) {
        # Load from BigQuery
        tryCatch({
          # SQL injection prevention
          safe_category <- gsub("'", "''", input$category)
          safe_subcategory <- gsub("'", "''", input$subcategory)
          
          query <- sprintf(
            "SELECT * FROM `%s` WHERE category = '%s' AND subcategory = '%s' LIMIT 100",
            api_manager$bq_full_table_id,
            safe_category,
            safe_subcategory
          )
          
          result <- api_manager$bq_query(query)
          
          if (nrow(result) > 0) {
            current_data(result)
            
            output$filter_status <- renderUI({
              tags$div(class = "status-success",
                       tags$i(class = "fa fa-check-circle"),
                       " ✓ Loaded ", nrow(result), " records from BigQuery for ",
                       input$category, " / ", input$subcategory)
            })
          } else {
            output$filter_status <- renderUI({
              tags$div(class = "status-warning",
                       tags$i(class = "fa fa-exclamation-triangle"),
                       " No data found for ", input$category, " / ", input$subcategory)
            })
            
            current_data(NULL)
          }
          
        }, error = function(e) {
          output$filter_status <- renderUI({
            tags$div(class = "status-error",
                     tags$i(class = "fa fa-times-circle"),
                     " Error loading data: ", e$message,
                     br(), br(),
                     tags$strong("💡 Try:"),
                     tags$ul(
                       tags$li("Verify BigQuery connection in API Config"),
                       tags$li("Check table structure matches expected columns"),
                       tags$li("Ensure service account has read permissions")
                     ))
          })
          
          # Fallback to sample data
          load_sample_data()
        })
      } else {
        # Not authenticated - use sample data
        load_sample_data()
      }
    })
    
    # Load sample data (fallback)
    load_sample_data <- function() {
      sample_data <- data.frame(
        ID = 1:20,
        Category = rep(input$category, 20),
        Subcategory = rep(input$subcategory, 20),
        Value = round(rnorm(20, mean = 100, sd = 20), 2),
        Date = seq(Sys.Date() - 19, Sys.Date(), by = "day"),
        Status = sample(c("Active", "Pending", "Complete"), 20, replace = TRUE),
        stringsAsFactors = FALSE
      )
      
      current_data(sample_data)
      
      output$filter_status <- renderUI({
        tags$div(class = "status-warning",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " Using sample data (", nrow(sample_data), " records). ",
                 "Connect to BigQuery in API Config tab for real data.")
      })
    }
    
    # Data table
    output$data_table <- DT::renderDataTable({
      req(current_data())
      
      DT::datatable(
        current_data(),
        options = list(
          pageLength = 10,
          searching = TRUE,
          ordering = TRUE,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv', 'excel')
        ),
        class = 'cell-border stripe',
        rownames = FALSE
      )
    })
    
    # Data summary
    output$data_summary <- renderUI({
      if (is.null(current_data())) {
        return(tags$p("No data loaded. Select filters and click 'Load Data'."))
      }
      
      data <- current_data()
      
      # Try to calculate summary statistics
      numeric_cols <- names(data)[sapply(data, is.numeric)]
      
      if (length(numeric_cols) > 0) {
        first_numeric <- numeric_cols[1]
        
        tags$div(
          tags$h5("Summary Statistics:"),
          fluidRow(
            column(3,
              div(class = "metric-box",
                  div(class = "metric-label", "TOTAL ROWS"),
                  div(class = "metric-value", nrow(data)))
            ),
            column(3,
              div(class = "metric-box",
                  div(class = "metric-label", "AVG VALUE"),
                  div(class = "metric-value", round(mean(data[[first_numeric]], na.rm = TRUE), 2)))
            ),
            column(3,
              div(class = "metric-box",
                  div(class = "metric-label", "MAX VALUE"),
                  div(class = "metric-value", round(max(data[[first_numeric]], na.rm = TRUE), 2)))
            ),
            column(3,
              div(class = "metric-box",
                  div(class = "metric-label", "MIN VALUE"),
                  div(class = "metric-value", round(min(data[[first_numeric]], na.rm = TRUE), 2)))
            )
          ),
          tags$hr(),
          tags$p(tags$strong("Columns in dataset: "), paste(names(data), collapse = ", "))
        )
      } else {
        tags$div(
          tags$h5("Data Summary:"),
          tags$p(tags$strong("Total Rows:"), " ", nrow(data)),
          tags$p(tags$strong("Columns:"), " ", paste(names(data), collapse = ", "))
        )
      }
    })
    
    # Default outputs
    output$filter_status <- renderUI({
      if (api_manager$bq_authenticated) {
        tags$div(class = "alert alert-success",
                 tags$i(class = "fa fa-check-circle"),
                 " Connected to BigQuery! Select category and subcategory, then click Load Data.")
      } else {
        tags$div(class = "alert alert-warning",
                 tags$i(class = "fa fa-exclamation-triangle"),
                 " BigQuery not connected. Using sample data. ",
                 "Go to ", tags$strong("API Config"), " tab to connect.")
      }
    })
    
    output$data_table <- DT::renderDataTable({
      DT::datatable(
        data.frame(Message = "No data loaded yet. Configure BigQuery and select filters above."),
        options = list(dom = 't'),
        rownames = FALSE
      )
    })
  })
}
