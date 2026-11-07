# modules/yolo_detector.R
# YOLO Detector Module - ML Inference via Python Backend

# ============================================================================
# UI FUNCTION
# ============================================================================

yolo_detector_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "YOLO Python Backend",
        status = "primary",
        solidHeader = TRUE,
        width = 4,
        
        textInput(ns("model_path"),
                  "YOLO Model Path:",
                  value = "models/yolov8n.pt",
                  placeholder = "Path to .pt file"),
        
        sliderInput(ns("confidence_threshold"),
                    "Confidence Threshold:",
                    min = 0, max = 1, value = 0.5, step = 0.05),
        
        actionButton(ns("run_yolo_python"),
                     "Run YOLO Inference",
                     class = "btn-success btn-block",
                     icon = icon("brain")),
        
        br(), br(),
        uiOutput(ns("detection_status"))
      ),
      
      box(
        title = "Detection Summary",
        status = "info",
        solidHeader = TRUE,
        width = 8,
        
        tags$div(style = "background: #fce4ec; padding: 10px; border-radius: 5px;",
          tags$p(icon("robot"), strong(" ML Inference:"),
                "YOLOv8 model running on Street View images")
        ),
        
        fluidRow(
          column(3, valueBoxOutput(ns("total_detections"), width = NULL)),
          column(3, valueBoxOutput(ns("high_confidence"), width = NULL)),
          column(3, valueBoxOutput(ns("critical_detections"), width = NULL)),
          column(3, valueBoxOutput(ns("unique_classes"), width = NULL))
        )
      )
    ),
    
    fluidRow(
      box(
        title = "Detection Results",
        status = "success",
        solidHeader = TRUE,
        width = 12,
        DTOutput(ns("detections_table"))
      )
    ),
    
    fluidRow(
      box(title = "Class Distribution", status = "warning",
          solidHeader = TRUE, width = 6,
          plotOutput(ns("class_distribution"))),
      box(title = "Risk Distribution", status = "danger",
          solidHeader = TRUE, width = 6,
          plotOutput(ns("risk_distribution")))
    )
  )
}

# ============================================================================
# SERVER FUNCTION
# ============================================================================

yolo_detector_server <- function(id, api_manager = NULL) {
  
  moduleServer(id, function(input, output, session) {
    
    detections_data <- reactiveVal(NULL)
    detection_summary <- reactiveVal(NULL)
    
    observeEvent(input$run_yolo_python, {
      
      if (is.null(api_manager) || is.null(api_manager$cav_images)) {
        output$detection_status <- renderUI({
          tags$div(class = "alert alert-danger",
                  "No images. Download Street View images first.")
        })
        return()
      }
      
      if (!file.exists(input$model_path)) {
        output$detection_status <- renderUI({
          tags$div(class = "alert alert-danger",
                  "Model not found. Check path.")
        })
        return()
      }
      
      withProgress(message = 'Running YOLO...', value = 0, {
        
        tryCatch({
          
          incProgress(0.2, detail = "Loading YOLO model")
          
          image_dir <- "data/raw/images"
          output_csv <- "data/processed/detections/yolo_results.csv"
          dir.create(dirname(output_csv), showWarnings = FALSE, recursive = TRUE)
          
          incProgress(0.3, detail = "Running ML inference (may take time)")
          
          # PYTHON BACKEND CALL
          result <- run_yolo_python(
            model_path = input$model_path,
            image_dir = image_dir,
            confidence_threshold = input$confidence_threshold,
            output_csv = output_csv
          )
          
          if (!result$success) stop(result$error)
          
          incProgress(0.8, detail = "Processing detections")
          
          detections <- as.data.frame(do.call(rbind, result$detections))
          detections$detection_id <- paste0("DET_", sprintf("%04d", seq_len(nrow(detections))))
          
          summary <- list(
            total = nrow(detections),
            high_confidence = sum(detections$confidence >= 0.8),
            critical = sum(detections$risk_level == "CRITICAL"),
            medium = sum(detections$risk_level == "MEDIUM"),
            low = sum(detections$risk_level == "LOW"),
            unique_classes = length(unique(detections$feature_type))
          )
          
          detections_data(detections)
          detection_summary(summary)
          
          if (!is.null(api_manager)) {
            api_manager$cav_detections <- detections
          }
          
          output$detection_status <- renderUI({
            tags$div(class = "alert alert-success",
                    sprintf("Found %d detections (%d critical)",
                           summary$total, summary$critical))
          })
          
        }, error = function(e) {
          output$detection_status <- renderUI({
            tags$div(class = "alert alert-danger", e$message)
          })
        })
      })
    })
    
    output$total_detections <- renderValueBox({
      s <- detection_summary()
      valueBox(
        if (is.null(s)) "0" else s$total,
        "Detections", icon = icon("eye"), color = "blue"
      )
    })
    
    output$high_confidence <- renderValueBox({
      s <- detection_summary()
      valueBox(
        if (is.null(s)) "0" else s$high_confidence,
        "High Conf", icon = icon("check-double"), color = "green"
      )
    })
    
    output$critical_detections <- renderValueBox({
      s <- detection_summary()
      valueBox(
        if (is.null(s)) "0" else s$critical,
        "Critical", icon = icon("exclamation-triangle"), color = "red"
      )
    })
    
    output$unique_classes <- renderValueBox({
      s <- detection_summary()
      valueBox(
        if (is.null(s)) "0" else s$unique_classes,
        "Classes", icon = icon("list"), color = "orange"
      )
    })
    
    output$detections_table <- renderDT({
      detections <- detections_data()
      if (is.null(detections)) {
        return(datatable(data.frame(Message = "Run YOLO first")))
      }
      datatable(detections, options = list(pageLength = 10, scrollX = TRUE))
    })
    
    output$class_distribution <- renderPlot({
      detections <- detections_data()
      if (is.null(detections)) {
        plot.new()
        text(0.5, 0.5, "No data", cex = 1.5)
        return()
      }
      
      counts <- sort(table(detections$feature_type), decreasing = TRUE)
      par(mar = c(8, 4, 2, 2))
      barplot(counts, col = "#667eea", main = "Detected Features",
              ylab = "Count", las = 2, cex.names = 0.8)
    })
    
    output$risk_distribution <- renderPlot({
      detections <- detections_data()
      if (is.null(detections)) {
        plot.new()
        text(0.5, 0.5, "No data", cex = 1.5)
        return()
      }
      
      counts <- table(factor(detections$risk_level,
                            levels = c("CRITICAL", "MEDIUM", "LOW")))
      barplot(counts, col = c("#dc3545", "#ffc107", "#28a745"),
              main = "Risk Levels", ylab = "Count")
    })
  })
}
