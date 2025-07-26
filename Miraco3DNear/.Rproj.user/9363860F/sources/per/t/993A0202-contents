# 3D PLY Viewer Shiny Dashboard
# Required packages installation (run once):
# install.packages(c("shiny", "shinydashboard", "rgl", "Rvcg", "DT"))

library(shiny)
library(shinydashboard)
library(rgl)
library(Rvcg)
library(DT)

# UI Definition
ui <- dashboardPage(
  dashboardHeader(title = "3D PLY Model Viewer"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("File Upload", tabName = "upload", icon = icon("upload")),
      menuItem("3D Viewer", tabName = "viewer", icon = icon("cube")),
      menuItem("Model Info", tabName = "info", icon = icon("info-circle"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f4f4f4;
        }
        .box {
          margin-bottom: 20px;
        }
        .rgl-widget {
          border: 2px solid #ddd;
          border-radius: 5px;
        }
      "))
    ),
    
    tabItems(
      # File Upload Tab
      tabItem(tabName = "upload",
              fluidRow(
                box(
                  title = "Upload PLY Files", status = "primary", solidHeader = TRUE,
                  width = 12, height = "500px",
                  
                  column(6,
                         h4("Point Cloud File (.ply)"),
                         fileInput("pointcloud_file", 
                                   label = "Choose Point Cloud PLY File",
                                   accept = c(".ply")),
                         
                         conditionalPanel(
                           condition = "output.pointcloud_uploaded",
                           h5("Point Cloud File Loaded!", style = "color: green;"),
                           verbatimTextOutput("pointcloud_summary")
                         )
                  ),
                  
                  column(6,
                         h4("Mesh File (.ply)"),
                         fileInput("mesh_file", 
                                   label = "Choose Mesh PLY File",
                                   accept = c(".ply")),
                         
                         conditionalPanel(
                           condition = "output.mesh_uploaded",
                           h5("Mesh File Loaded!", style = "color: green;"),
                           verbatimTextOutput("mesh_summary")
                         )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Visualization Controls", status = "info", solidHeader = TRUE,
                  width = 12,
                  
                  column(4,
                         selectInput("display_mode", "Display Mode:",
                                     choices = list(
                                       "Point Cloud Only" = "points",
                                       "Mesh Only" = "mesh",
                                       "Both" = "both"
                                     ),
                                     selected = "both")
                  ),
                  
                  column(4,
                         tags$div(
                           tags$label("Point Color:"),
                           tags$input(type = "color", id = "point_color", value = "#FF0000", style = "width: 100%; height: 34px;")
                         ),
                         numericInput("point_size", "Point Size:", value = 3, min = 1, max = 10)
                  ),
                  
                  column(4,
                         tags$div(
                           tags$label("Mesh Color:"),
                           tags$input(type = "color", id = "mesh_color", value = "#0080FF", style = "width: 100%; height: 34px;")
                         ),
                         numericInput("mesh_alpha", "Mesh Transparency:", value = 0.7, min = 0, max = 1, step = 0.1)
                  )
                )
              )
      ),
      
      # 3D Viewer Tab
      tabItem(tabName = "viewer",
              fluidRow(
                box(
                  title = "3D Model Viewer", status = "primary", solidHeader = TRUE,
                  width = 12, height = "600px",
                  
                  conditionalPanel(
                    condition = "output.files_ready",
                    rglwidgetOutput("rgl_plot", width = "100%", height = "550px")
                  ),
                  
                  conditionalPanel(
                    condition = "!output.files_ready",
                    div(
                      style = "text-align: center; padding: 100px;",
                      h3("Please upload PLY files in the File Upload tab", style = "color: #999;"),
                      icon("upload", "fa-3x", style = "color: #ccc;")
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "View Controls", status = "info", solidHeader = TRUE,
                  width = 12,
                  
                  column(3,
                         actionButton("reset_view", "Reset View", class = "btn-warning", width = "100%")
                  ),
                  
                  column(3,
                         actionButton("zoom_in", "Zoom In", class = "btn-info", width = "100%")
                  ),
                  
                  column(3,
                         actionButton("zoom_out", "Zoom Out", class = "btn-info", width = "100%")
                  ),
                  
                  column(3,
                         downloadButton("save_snapshot", "Save Snapshot", class = "btn-success", width = "100%")
                  )
                )
              )
      ),
      
      # Model Info Tab
      tabItem(tabName = "info",
              fluidRow(
                box(
                  title = "Point Cloud Information", status = "primary", solidHeader = TRUE,
                  width = 6,
                  
                  conditionalPanel(
                    condition = "output.pointcloud_uploaded",
                    DT::dataTableOutput("pointcloud_info")
                  ),
                  
                  conditionalPanel(
                    condition = "!output.pointcloud_uploaded",
                    div(
                      style = "text-align: center; padding: 50px;",
                      h4("No point cloud file uploaded", style = "color: #999;")
                    )
                  )
                ),
                
                box(
                  title = "Mesh Information", status = "success", solidHeader = TRUE,
                  width = 6,
                  
                  conditionalPanel(
                    condition = "output.mesh_uploaded",
                    DT::dataTableOutput("mesh_info")
                  ),
                  
                  conditionalPanel(
                    condition = "!output.mesh_uploaded",
                    div(
                      style = "text-align: center; padding: 50px;",
                      h4("No mesh file uploaded", style = "color: #999;")
                    )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Statistics", status = "warning", solidHeader = TRUE,
                  width = 12,
                  
                  conditionalPanel(
                    condition = "output.files_ready",
                    verbatimTextOutput("model_statistics")
                  )
                )
              )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Reactive values to store loaded data
  values <- reactiveValues(
    pointcloud = NULL,
    mesh = NULL,
    rgl_id = NULL
  )
  
  # Load Point Cloud File
  observeEvent(input$pointcloud_file, {
    req(input$pointcloud_file)
    
    tryCatch({
      # Read PLY file
      values$pointcloud <- vcgPlyRead(input$pointcloud_file$datapath)
      
      showNotification("Point cloud loaded successfully!", type = "message")
    }, error = function(e) {
      showNotification(paste("Error loading point cloud:", e$message), type = "error")
      values$pointcloud <- NULL
    })
  })
  
  # Load Mesh File
  observeEvent(input$mesh_file, {
    req(input$mesh_file)
    
    tryCatch({
      # Read PLY mesh file
      values$mesh <- vcgPlyRead(input$mesh_file$datapath)
      
      showNotification("Mesh loaded successfully!", type = "message")
    }, error = function(e) {
      showNotification(paste("Error loading mesh:", e$message), type = "error")
      values$mesh <- NULL
    })
  })
  
  # Check if files are uploaded
  output$pointcloud_uploaded <- reactive({
    return(!is.null(values$pointcloud))
  })
  
  output$mesh_uploaded <- reactive({
    return(!is.null(values$mesh))
  })
  
  output$files_ready <- reactive({
    pc_loaded <- !is.null(values$pointcloud)
    mesh_loaded <- !is.null(values$mesh)
    return(pc_loaded || mesh_loaded)
  })
  
  outputOptions(output, "pointcloud_uploaded", suspendWhenHidden = FALSE)
  outputOptions(output, "mesh_uploaded", suspendWhenHidden = FALSE)
  outputOptions(output, "files_ready", suspendWhenHidden = FALSE)
  
  # File summaries
  output$pointcloud_summary <- renderText({
    req(values$pointcloud)
    paste(
      "Vertices:", nrow(values$pointcloud$vb),
      "\nBounding Box:",
      "\n  X:", round(min(values$pointcloud$vb[1,]), 3), "to", round(max(values$pointcloud$vb[1,]), 3),
      "\n  Y:", round(min(values$pointcloud$vb[2,]), 3), "to", round(max(values$pointcloud$vb[2,]), 3),
      "\n  Z:", round(min(values$pointcloud$vb[3,]), 3), "to", round(max(values$pointcloud$vb[3,]), 3)
    )
  })
  
  output$mesh_summary <- renderText({
    req(values$mesh)
    paste(
      "Vertices:", nrow(values$mesh$vb),
      "\nFaces:", ncol(values$mesh$it),
      "\nBounding Box:",
      "\n  X:", round(min(values$mesh$vb[1,]), 3), "to", round(max(values$mesh$vb[1,]), 3),
      "\n  Y:", round(min(values$mesh$vb[2,]), 3), "to", round(max(values$mesh$vb[2,]), 3),
      "\n  Z:", round(min(values$mesh$vb[3,]), 3), "to", round(max(values$mesh$vb[3,]), 3)
    )
  })
  
  # 3D Plot
  output$rgl_plot <- renderRglwidget({
    # Check if we have at least one file loaded
    if (is.null(values$pointcloud) && is.null(values$mesh)) {
      return(NULL)
    }
    
    # Clear previous plot
    if (!is.null(values$rgl_id)) {
      try(rgl.close(values$rgl_id), silent = TRUE)
    }
    
    # Open new RGL device
    values$rgl_id <- rgl.open()
    rgl.clear()
    
    # Set up the scene
    rgl.bg(color = "white")
    
    # Plot based on display mode
    if (input$display_mode %in% c("points", "both") && !is.null(values$pointcloud)) {
      # Add point cloud
      points3d(
        t(values$pointcloud$vb[1:3, ]),
        col = input$point_color,
        size = input$point_size
      )
    }
    
    if (input$display_mode %in% c("mesh", "both") && !is.null(values$mesh)) {
      # Add mesh
      shade3d(
        values$mesh,
        col = input$mesh_color,
        alpha = input$mesh_alpha
      )
    }
    
    # Add axes and labels
    axes3d()
    title3d(main = "3D PLY Model Viewer", xlab = "X", ylab = "Y", zlab = "Z")
    
    # Return the widget
    rglwidget()
  })
  
  # View control buttons
  observeEvent(input$reset_view, {
    req(values$rgl_id)
    rgl.viewpoint(theta = 0, phi = 15, fov = 60, zoom = 1)
  })
  
  observeEvent(input$zoom_in, {
    req(values$rgl_id)
    rgl.viewpoint(zoom = 1.2)
  })
  
  observeEvent(input$zoom_out, {
    req(values$rgl_id)
    rgl.viewpoint(zoom = 0.8)
  })
  
  # Save snapshot
  output$save_snapshot <- downloadHandler(
    filename = function() {
      paste0("3d_model_snapshot_", Sys.Date(), ".png")
    },
    content = function(file) {
      req(values$rgl_id)
      rgl.snapshot(file, fmt = "png")
    }
  )
  
  # Model information tables
  output$pointcloud_info <- DT::renderDataTable({
    req(values$pointcloud)
    
    info_df <- data.frame(
      Property = c("Number of Vertices", "Min X", "Max X", "Min Y", "Max Y", "Min Z", "Max Z"),
      Value = c(
        nrow(values$pointcloud$vb),
        round(min(values$pointcloud$vb[1,]), 3),
        round(max(values$pointcloud$vb[1,]), 3),
        round(min(values$pointcloud$vb[2,]), 3),
        round(max(values$pointcloud$vb[2,]), 3),
        round(min(values$pointcloud$vb[3,]), 3),
        round(max(values$pointcloud$vb[3,]), 3)
      )
    )
    
    DT::datatable(info_df, options = list(dom = 't', pageLength = 10))
  })
  
  output$mesh_info <- DT::renderDataTable({
    req(values$mesh)
    
    info_df <- data.frame(
      Property = c("Number of Vertices", "Number of Faces", "Min X", "Max X", "Min Y", "Max Y", "Min Z", "Max Z"),
      Value = c(
        nrow(values$mesh$vb),
        ncol(values$mesh$it),
        round(min(values$mesh$vb[1,]), 3),
        round(max(values$mesh$vb[1,]), 3),
        round(min(values$mesh$vb[2,]), 3),
        round(max(values$mesh$vb[2,]), 3),
        round(min(values$mesh$vb[3,]), 3),
        round(max(values$mesh$vb[3,]), 3)
      )
    )
    
    DT::datatable(info_df, options = list(dom = 't', pageLength = 10))
  })
  
  # Model statistics
  output$model_statistics <- renderText({
    stats <- character(0)
    
    if (!is.null(values$pointcloud)) {
      pc_center <- apply(values$pointcloud$vb[1:3, ], 1, mean)
      stats <- c(stats, paste("Point Cloud Center:", 
                              paste(round(pc_center, 3), collapse = ", ")))
    }
    
    if (!is.null(values$mesh)) {
      mesh_center <- apply(values$mesh$vb[1:3, ], 1, mean)
      mesh_volume <- vcgVolume(values$mesh)
      stats <- c(stats, 
                 paste("Mesh Center:", paste(round(mesh_center, 3), collapse = ", ")),
                 paste("Mesh Volume:", round(mesh_volume, 3)))
    }
    
    if (length(stats) > 0) {
      paste(stats, collapse = "\n")
    } else {
      "No models loaded."
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)