# TEMPLATE: Copy this file to modules/ folder as chapterXX.R
# modules/chapterXX.R — Chapter Title

# ============================================================================
# CUSTOMIZATION GUIDE
# ============================================================================
# 1. Update CHAPTER_NUM, CHAPTER_ICON, CHAPTER_TITLE, CHAPTER_SUBTITLE, CHAPTER_BADGES
# 2. Rename function from chapter4_ui to chapterX_ui (change number)
# 3. Rename function from chapter4_server to chapterX_server (change number)
# 4. Add content to Theory tab
# 5. Add visualizations in server section
# 6. Update app.R to include this chapter
#
# CRITICAL: framework_card() takes ONLY 2 arguments: framework_card(title, content)
#           If you need multiple elements, wrap them in tagList():
#           framework_card("Title", tagList(tags$p(...), tags$h5(...), tags$ul(...)))
# ============================================================================

CHAPTER_NUM <- 4  # Change this to your chapter number
CHAPTER_ICON <- "🎯"  # Change emoji
CHAPTER_TITLE <- "Your Chapter Title"
CHAPTER_SUBTITLE <- "Brief description of what this chapter covers and why it matters"
CHAPTER_BADGES <- c("Badge1", "Badge2", "Badge3", "Badge4")

# UI Function - change the number in the function name to match your chapter
chapter4_ui <- function(id) {
  ns <- NS(id)
  tagList(
    # Hero banner
    chapter_hero(
      CHAPTER_NUM, 
      CHAPTER_ICON, 
      CHAPTER_TITLE,
      CHAPTER_SUBTITLE,
      CHAPTER_BADGES
    ),

    # Statistics cards (4 metrics in a row)
    stats_row(
      list("Value1", "Metric 1 Label"),
      list("Value2", "Metric 2 Label"), 
      list("Value3", "Metric 3 Label"),
      list("Value4", "Metric 4 Label")
    ),

    # Main content area with tabs
    fluidRow(
      tabBox(width = 12, id = ns("tabs"),

        # ==================================================================
        # THEORY TAB
        # ==================================================================
        tabPanel(title = tagList(icon("book"), " Theory & Concepts"),
          
          # ROW 1: Two boxes side by side
          fluidRow(
            box(
              title = "📊 First Section Title", 
              status = "info",  # info = teal, warning = orange, success = turquoise, danger = red
              solidHeader = TRUE, 
              width = 6,
              
              framework_card(
                "Subsection 1.1 Title",
                "Your content here. Can include HTML tags, bullet lists, paragraphs, etc."
              ),
              
              framework_card(
                "Subsection 1.2 Title",
                tags$ul(
                  tags$li(tags$strong("Point 1:"), " Explanation"),
                  tags$li(tags$strong("Point 2:"), " Explanation"),
                  tags$li(tags$strong("Point 3:"), " Explanation")
                )
              ),
              
              tip_box(
                "Key Insight", 
                "Important takeaway, best practice, or critical concept to remember"
              )
            ),
            
            box(
              title = "⚡ Second Section Title", 
              status = "warning",
              solidHeader = TRUE, 
              width = 6,
              
              framework_card(
                "Subsection 2.1 Title",
                tagList(
                  tags$p("Your content here. You can use multiple paragraphs."),
                  tags$p("Another paragraph with more details.")
                )
              ),
              
              info_box(
                "<strong>💡 Note:</strong> Additional information, clarification, or context"
              )
            )
          ),
          
          # ROW 2: Full-width visualization
          fluidRow(
            box(
              title = "📈 Main Visualization Title", 
              status = "success",
              solidHeader = TRUE, 
              width = 12,
              plotlyOutput(ns("viz_main"), height = "400px")
            )
          ),
          
          # ROW 3: Comparison table
          fluidRow(
            box(
              title = "📋 Comparison or Summary Table", 
              status = "info",
              solidHeader = TRUE, 
              width = 12,
              tags$table(class = "algo-table",
                tags$thead(tags$tr(
                  tags$th("Column 1 Header"), 
                  tags$th("Column 2 Header"), 
                  tags$th("Column 3 Header"),
                  tags$th("Column 4 Header")
                )),
                tags$tbody(
                  tags$tr(
                    tags$td(tags$strong("Row 1 Label")),
                    tags$td("Data 1"),
                    tags$td("Data 2"),
                    tags$td("Data 3")
                  ),
                  tags$tr(
                    tags$td(tags$strong("Row 2 Label")),
                    tags$td("Data 1"),
                    tags$td("Data 2"),
                    tags$td("Data 3")
                  ),
                  tags$tr(
                    tags$td(tags$strong("Row 3 Label")),
                    tags$td("Data 1"),
                    tags$td("Data 2"),
                    tags$td("Data 3")
                  )
                )
              ),
              tip_box("Table Context", "Explain what this table shows and why it matters")
            )
          ),
          
          # ROW 4: Two more boxes with detailed content
          fluidRow(
            box(
              title = "🔍 Deep Dive / Technical Details", 
              status = "warning",
              solidHeader = TRUE, 
              width = 6,
              
              framework_card(
                "Implementation Steps",
                tags$ol(
                  tags$li(tags$strong("Step 1:"), " Description"),
                  tags$li(tags$strong("Step 2:"), " Description"),
                  tags$li(tags$strong("Step 3:"), " Description"),
                  tags$li(tags$strong("Step 4:"), " Description")
                )
              ),
              
              framework_card(
                "Best Practices",
                tags$ul(
                  tags$li("Best practice 1"),
                  tags$li("Best practice 2"),
                  tags$li("Best practice 3")
                )
              )
            ),
            
            box(
              title = "🎯 Practical Applications / Use Cases", 
              status = "success",
              solidHeader = TRUE, 
              width = 6,
              
              framework_card(
                "Real-World Example 1",
                "Describe a practical application or use case"
              ),
              
              framework_card(
                "Real-World Example 2",
                "Another practical application"
              ),
              
              info_box(
                "<strong>💼 Industry Context:</strong> How this is used in actual trading systems"
              )
            )
          ),
          
          # ROW 5: Additional visualization
          fluidRow(
            box(
              title = "📊 Secondary Visualization", 
              status = "info",
              solidHeader = TRUE, 
              width = 12,
              plotlyOutput(ns("viz_secondary"), height = "350px")
            )
          )
        ), # end Theory tab

        # ==================================================================
        # PYTHON CODE TAB
        # ==================================================================
        tabPanel(title = tagList(icon("code"), " Python Code"),
          python_code_tab()
        )
      )
    )
  )
}

# Server Function - change the number in the function name to match your chapter
chapter4_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    # ==================================================================
    # VISUALIZATION 1: Main Chart
    # ==================================================================
    output$viz_main <- renderPlotly({
      # Prepare your data
      df <- data.frame(
        x = 1:10,
        y = rnorm(10, mean = 50, sd = 10),
        category = rep(c("A", "B"), each = 5)
      )
      
      # Create the plot
      p <- plot_ly(
        data = df,
        x = ~x,
        y = ~y,
        type = "scatter",
        mode = "lines+markers",
        color = ~category,
        colors = c(ml_colors$primary, ml_colors$accent1),
        line = list(width = 3),
        marker = list(size = 10)
      ) %>%
        layout(
          title = list(
            text = "Your Chart Title", 
            font = list(color = "#E6EDF3")
          ),
          xaxis = list(
            title = "X Axis Label",
            color = "#8B949E",
            gridcolor = "#30363D"
          ),
          yaxis = list(
            title = "Y Axis Label",
            color = "#8B949E",
            gridcolor = "#30363D"
          ),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3"),
          legend = list(
            font = list(color = "#E6EDF3"),
            bgcolor = "rgba(28, 33, 40, 0.8)"
          )
        )
      
      p
    })
    
    # ==================================================================
    # VISUALIZATION 2: Secondary Chart
    # ==================================================================
    output$viz_secondary <- renderPlotly({
      # Example: Bar chart
      categories <- c("Category A", "Category B", "Category C", "Category D", "Category E")
      values <- c(23, 45, 32, 51, 38)
      
      p <- plot_ly(
        x = categories,
        y = values,
        type = "bar",
        marker = list(
          color = generate_palette(length(categories)),
          line = list(color = "white", width = 1.5)
        ),
        text = values,
        textposition = "outside",
        hovertemplate = "<b>%{x}</b><br>Value: %{y}<extra></extra>"
      ) %>%
        layout(
          title = list(
            text = "Bar Chart Example", 
            font = list(color = "#E6EDF3")
          ),
          xaxis = list(
            title = "Categories",
            color = "#8B949E"
          ),
          yaxis = list(
            title = "Values",
            color = "#8B949E",
            gridcolor = "#30363D"
          ),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)',
          font = list(color = "#E6EDF3")
        )
      
      p
    })
    
  })
}

# ============================================================================
# INTEGRATION CHECKLIST
# ============================================================================
# 
# After creating this chapter module, update app.R:
#
# 1. Add to sidebarMenu:
#    menuItem("Ch 4 · Your Title", tabName = "ch4", icon = icon("target"))
#
# 2. Add to tabItems:
#    tabItem(tabName = "ch4", chapter4_ui("ch4"))
#
# 3. Add to server function:
#    chapter4_server("ch4")
#
# The module will automatically load via the source() loop in app.R
# ============================================================================
