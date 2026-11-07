# modules/yolo_detector/ui.R

yolo_detector_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      box(
        title = "YOLO Detection Configuration",
        status = "primary",
        solidHeader = TRUE,
        width = 4,
        
        p(class = "text-muted",
          "Upload pre-processed YOLO detection results or configure Python integration."),
        
        br(),
        
        radioButtons(
          ns("detection_method"),
          "Detection Method:",
          choices = c(
            "Upload CSV Results" = "upload",
            "Python Integration (Future)" = "python"
          ),
          selected = "upload"
        ),
        
        conditionalPanel(
          condition = "input.detection_method == 'upload'",
          ns = ns,
          
          fileInput(
            ns("detections_csv"),
            "Upload Detection Results CSV:",
            accept = c(".csv", "text/csv")
          ),
          
          p(class = "text-muted small",
            "CSV should contain: image_path, class_id, confidence, bbox columns")
        ),
        
        br(),
        
        sliderInput(
          ns("confidence_threshold"),
          "Confidence Threshold:",
          min = 0,
          max = 1,
          value = 0.5,
          step = 0.05
        ),
        
        br(),
        
        actionButton(
          ns("process_detections"),
          "Process Detections",
          class = "btn-success",
          icon = icon("cogs"),
          width = "100%"
        ),
        
        br(), br(),
        
        uiOutput(ns("detection_status"))
      ),
      
      box(
        title = "Detection Summary",
        status = "info",
        solidHeader = TRUE,
        width = 8,
        
        h5("YOLO Object Detection:"),
        p("Machine learning model detects road features in Street View images."),
        
        tags$ul(
          tags$li("Model: YOLOv8 trained on road features"),
          tags$li("Classes: roundabout, tunnel, junction, curve, etc."),
          tags$li("Output: Class label + confidence score + bounding box"),
          tags$li("Risk level assigned based on detected feature type")
        ),
        
        br(),
        
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
        collapsible = TRUE,
        
        DTOutput(ns("detections_table"))
      )
    ),
    
    fluidRow(
      box(
        title = "Class Distribution",
        status = "warning",
        solidHeader = TRUE,
        width = 6,
        
        plotOutput(ns("class_distribution"))
      ),
      
      box(
        title = "Risk Level Summary",
        status = "danger",
        solidHeader = TRUE,
        width = 6,
        
        plotOutput(ns("risk_distribution"))
      )
    )
  )
}
