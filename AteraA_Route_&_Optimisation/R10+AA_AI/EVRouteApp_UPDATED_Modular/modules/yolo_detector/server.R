# modules/yolo_detector/server.R

yolo_detector_server <- function(id, api_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    detections_data <- reactiveVal(NULL)
    detection_summary <- reactiveVal(NULL)
    
    # Class mapping (example - adjust based on your model)
    class_map <- c(
      "0" = "roundabout",
      "1" = "tunnel",
      "2" = "junction",
      "3" = "lane_merge",
      "4" = "curve",
      "5" = "pedestrian_crossing",
      "6" = "construction_zone",
      "7" = "traffic_signals",
      "8" = "bus_stop",
      "9" = "signage"
    )
    
    observeEvent(input$process_detections, {
      
      if (input$detection_method == "upload") {
        
        if (is.null(input$detections_csv)) {
          output$detection_status <- renderUI({
            div(class = "status-error",
                h5("✗ No File Selected"),
                p("Please upload a detection results CSV file."))
          })
          return()
        }
        
        withProgress(message = 'Processing detections...', value = 0, {
          
          tryCatch({
            
            incProgress(0.2, detail = "Reading CSV")
            
            # Read CSV
            detections <- read.csv(input$detections_csv$datapath, stringsAsFactors = FALSE)
            
            incProgress(0.4, detail = "Validating data")
            
            # Validate required columns
            required_cols <- c("class_id", "confidence")
            missing_cols <- setdiff(required_cols, names(detections))
            
            if (length(missing_cols) > 0) {
              stop(paste("Missing required columns:", paste(missing_cols, collapse = ", ")))
            }
            
            incProgress(0.6, detail = "Processing detections")
            
            # Filter by confidence threshold
            detections <- detections %>%
              filter(confidence >= input$confidence_threshold)
            
            # Map class IDs to names
            detections$feature_type <- class_map[as.character(detections$class_id)]
            
            # Handle unmapped classes
            detections$feature_type[is.na(detections$feature_type)] <- paste0("class_", detections$class_id[is.na(detections$feature_type)])
            
            # Assign risk levels
            detections$risk_level <- sapply(detections$feature_type, classify_risk)
            
            # Add detection IDs
            detections$detection_id <- paste0("DET_", sprintf("%04d", seq_len(nrow(detections))))
            
            incProgress(0.8, detail = "Calculating summary")
            
            # Calculate summary statistics
            summary <- list(
              total = nrow(detections),
              high_confidence = sum(detections$confidence >= 0.8),
              critical = sum(detections$risk_level == "CRITICAL"),
              medium = sum(detections$risk_level == "MEDIUM"),
              low = sum(detections$risk_level == "LOW"),
              unique_classes = length(unique(detections$feature_type))
            )
            
            # Store results
            detections_data(detections)
            detection_summary(summary)
            
            if (!is.null(api_manager)) {
              api_manager$cav_detections <- detections
            }
            
            output$detection_status <- renderUI({
              div(class = "status-success",
                  h5("✓ Processing Complete"),
                  p(strong("Detections:"), summary$total),
                  p(strong("High confidence (>0.8):"), summary$high_confidence),
                  p(strong("Risk breakdown:"),
                    "Critical:", summary$critical, "|",
                    "Medium:", summary$medium, "|",
                    "Low:", summary$low))
            })
            
            showNotification(
              paste("Processed", summary$total, "detections!"),
              type = "message",
              duration = 3
            )
            
          }, error = function(e) {
            output$detection_status <- renderUI({
              div(class = "status-error",
                  h5("✗ Processing Failed"),
                  p(as.character(e$message)))
            })
            showNotification(paste("Error:", e$message), type = "error", duration = 10)
          })
        })
        
      } else {
        # Python integration (future implementation)
        output$detection_status <- renderUI({
          div(class = "status-warning",
              h5("⚠ Not Implemented"),
              p("Python integration coming in Phase 4. Use CSV upload for now."))
        })
      }
    })
    
    # Value boxes
    output$total_detections <- renderValueBox({
      summary <- detection_summary()
      valueBox(
        if (is.null(summary)) "0" else format(summary$total, big.mark = ","),
        "Total Detections",
        icon = icon("eye"),
        color = "blue"
      )
    })
    
    output$high_confidence <- renderValueBox({
      summary <- detection_summary()
      valueBox(
        if (is.null(summary)) "0" else format(summary$high_confidence, big.mark = ","),
        "High Confidence",
        icon = icon("check-double"),
        color = "green"
      )
    })
    
    output$critical_detections <- renderValueBox({
      summary <- detection_summary()
      valueBox(
        if (is.null(summary)) "0" else format(summary$critical, big.mark = ","),
        "Critical Risk",
        icon = icon("exclamation-triangle"),
        color = "red"
      )
    })
    
    output$unique_classes <- renderValueBox({
      summary <- detection_summary()
      valueBox(
        if (is.null(summary)) "0" else summary$unique_classes,
        "Feature Types",
        icon = icon("list"),
        color = "orange"
      )
    })
    
    # Detections table
    output$detections_table <- renderDT({
      detections <- detections_data()
      if (is.null(detections)) {
        return(datatable(
          data.frame(Message = "No detections processed yet"),
          options = list(dom = 't')
        ))
      }
      
      display_cols <- c("detection_id", "feature_type", "confidence", "risk_level")
      display_data <- detections[, intersect(display_cols, names(detections))]
      
      if ("confidence" %in% names(display_data)) {
        display_data$confidence <- round(display_data$confidence, 3)
      }
      
      datatable(
        display_data,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv', 'excel')
        ),
        rownames = FALSE
      ) %>%
        formatStyle(
          'risk_level',
          backgroundColor = styleEqual(
            c('CRITICAL', 'MEDIUM', 'LOW'),
            c('#f8d7da', '#fff3cd', '#d4edda')
          )
        ) %>%
        formatStyle(columns = colnames(display_data), fontSize = '12px')
    })
    
    # Class distribution plot
    output$class_distribution <- renderPlot({
      detections <- detections_data()
      if (is.null(detections)) {
        plot.new()
        text(0.5, 0.5, "No data available", cex = 1.5)
        return()
      }
      
      class_counts <- table(detections$feature_type)
      class_counts <- sort(class_counts, decreasing = TRUE)
      
      par(mar = c(8, 4, 2, 2))
      barplot(
        class_counts,
        col = "#667eea",
        main = "Detected Features by Class",
        ylab = "Count",
        las = 2,
        cex.names = 0.8
      )
    })
    
    # Risk distribution plot
    output$risk_distribution <- renderPlot({
      detections <- detections_data()
      if (is.null(detections)) {
        plot.new()
        text(0.5, 0.5, "No data available", cex = 1.5)
        return()
      }
      
      risk_counts <- table(factor(detections$risk_level, levels = c("CRITICAL", "MEDIUM", "LOW")))
      
      par(mar = c(5, 4, 2, 2))
      barplot(
        risk_counts,
        col = c("#dc3545", "#ffc107", "#28a745"),
        main = "Detections by Risk Level",
        ylab = "Count",
        las = 1
      )
    })
  })
}
