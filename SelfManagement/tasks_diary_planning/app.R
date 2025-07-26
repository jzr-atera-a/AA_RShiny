library(shiny)
library(shinydashboard)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Task Management Dashboard"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Tasks", tabName = "tasks", icon = icon("tasks")),
      menuItem("Diary", tabName = "diary", icon = icon("book"))
    )
  ),
  
  dashboardBody(
    # Custom CSS for ocean blue theme
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f0f8ff;
        }
        .box {
          border-top: 3px solid #1e6091;
          background-color: #ffffff;
        }
        .box-header {
          background-color: #2c5aa0;
          color: white;
        }
        .box-header h3 {
          color: white;
        }
        .btn-primary {
          background-color: #1e6091;
          border-color: #1e6091;
        }
        .btn-primary:hover {
          background-color: #154d7a;
          border-color: #154d7a;
        }
        .main-header .navbar {
          background-color: #1e6091;
        }
        .main-header .logo {
          background-color: #154d7a;
        }
        .main-header .logo:hover {
          background-color: #0f3a5c;
        }
        .sidebar {
          background-color: #2c5aa0;
        }
        .task-item {
          margin: 5px 0;
          padding: 5px;
          background-color: #e6f3ff;
          border-radius: 3px;
        }
      "))
    ),
    
    tabItems(
      tabItem(tabName = "tasks",
              # Download box at the top
              fluidRow(
                box(
                  title = "Export Tasks", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  div(style = "text-align: center; padding: 10px;",
                      p("Download all your tasks from all categories in a single file", 
                        style = "margin-bottom: 15px; color: #666;"),
                      div(style = "display: inline-block; margin-right: 10px;",
                          downloadButton("download_all_tasks", "Download All Tasks", 
                                         class = "btn btn-primary", 
                                         style = "background-color: #1e6091; border-color: #1e6091; font-size: 16px; padding: 10px 20px;")
                      ),
                      div(style = "display: inline-block; margin-left: 10px;",
                          actionButton("clear_all_tasks", "Clear All Tasks", 
                                       class = "btn btn-danger", 
                                       style = "background-color: #d9534f; border-color: #d43f3a; font-size: 16px; padding: 10px 20px;")
                      )
                  )
                )
              ),
              
              fluidRow(
                # Personal Tasks
                box(
                  title = "Personal", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  column(6,
                         textInput("personal_task", "Add Personal Task:", placeholder = "Enter task here...")
                  ),
                  column(6,
                         br(),
                         actionButton("submit_personal", "Submit", class = "btn-primary")
                  ),
                  br(),
                  div(id = "personal_display", style = "margin-top: 15px; min-height: 100px;",
                      uiOutput("personal_tasks"))
                )
              ),
              
              fluidRow(
                # Work Tasks
                box(
                  title = "Work", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  column(6,
                         textInput("work_task", "Add Work Task:", placeholder = "Enter task here...")
                  ),
                  column(6,
                         br(),
                         actionButton("submit_work", "Submit", class = "btn-primary")
                  ),
                  br(),
                  div(id = "work_display", style = "margin-top: 15px; min-height: 100px;",
                      uiOutput("work_tasks"))
                )
              ),
              
              fluidRow(
                # Study Tasks
                box(
                  title = "Study", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  column(6,
                         textInput("study_task", "Add Study Task:", placeholder = "Enter task here...")
                  ),
                  column(6,
                         br(),
                         actionButton("submit_study", "Submit", class = "btn-primary")
                  ),
                  br(),
                  div(id = "study_display", style = "margin-top: 15px; min-height: 100px;",
                      uiOutput("study_tasks"))
                )
              ),
              
              fluidRow(
                # Family Tasks
                box(
                  title = "Family", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  column(6,
                         textInput("family_task", "Add Family Task:", placeholder = "Enter task here...")
                  ),
                  column(6,
                         br(),
                         actionButton("submit_family", "Submit", class = "btn-primary")
                  ),
                  br(),
                  div(id = "family_display", style = "margin-top: 15px; min-height: 100px;",
                      uiOutput("family_tasks"))
                )
              ),
              
              fluidRow(
                # Health Tasks
                box(
                  title = "Health", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  column(6,
                         textInput("health_task", "Add Health Task:", placeholder = "Enter task here...")
                  ),
                  column(6,
                         br(),
                         actionButton("submit_health", "Submit", class = "btn-primary")
                  ),
                  br(),
                  div(id = "health_display", style = "margin-top: 15px; min-height: 100px;",
                      uiOutput("health_tasks"))
                )
              ),
              
              fluidRow(
                # Projects Management Tasks
                box(
                  title = "Projects Management", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  column(6,
                         textInput("projects_task", "Add Projects Management Task:", placeholder = "Enter task here...")
                  ),
                  column(6,
                         br(),
                         actionButton("submit_projects", "Submit", class = "btn-primary")
                  ),
                  br(),
                  div(id = "projects_display", style = "margin-top: 15px; min-height: 100px;",
                      uiOutput("projects_tasks"))
                )
              )
      ),
      
      # Diary Tab
      tabItem(tabName = "diary",
              # Today's Date Box
              fluidRow(
                box(
                  title = format(Sys.Date(), "%A, %d %B %Y"), 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  div(style = "text-align: center; padding: 20px; font-size: 18px; color: #2c5aa0;",
                      h4("Today's Date", style = "margin-bottom: 10px;"),
                      h3(format(Sys.Date(), "%d/%m/%Y"), style = "color: #1e6091; font-weight: bold;")
                  )
                )
              ),
              
              # Today's Events Box
              fluidRow(
                box(
                  title = "Today's Events", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  div(style = "padding: 10px;",
                      textAreaInput("todays_events", 
                                    label = NULL,
                                    placeholder = "Write about today's events, activities, meetings, and experiences...",
                                    rows = 8,
                                    width = "100%",
                                    resize = "vertical")
                  )
                )
              ),
              
              # Self Assessment, Learnings and Reflection Box
              fluidRow(
                box(
                  title = "Self Assessment, Learnings and Reflection", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  div(style = "padding: 10px;",
                      textAreaInput("self_reflection", 
                                    label = NULL,
                                    placeholder = "Reflect on today's learnings, self-assessment, achievements, challenges, and personal growth...",
                                    rows = 8,
                                    width = "100%",
                                    resize = "vertical")
                  )
                )
              ),
              
              # Save and Delete Diary Box
              fluidRow(
                box(
                  title = "Diary Management", 
                  status = "primary", 
                  solidHeader = TRUE,
                  width = 12,
                  div(style = "text-align: center; padding: 10px;",
                      p("Save, download, or delete today's diary entries", 
                        style = "margin-bottom: 15px; color: #666;"),
                      div(style = "display: inline-block; margin-right: 10px;",
                          actionButton("save_diary", "Save Today's Diary", 
                                       class = "btn btn-primary", 
                                       style = "background-color: #1e6091; border-color: #1e6091; font-size: 16px; padding: 10px 20px;")
                      ),
                      div(style = "display: inline-block; margin: 0 10px;",
                          downloadButton("download_diary", "Download Today's Diary", 
                                         class = "btn btn-success", 
                                         style = "background-color: #5cb85c; border-color: #4cae4c; font-size: 16px; padding: 10px 20px;")
                      ),
                      div(style = "display: inline-block; margin-left: 10px;",
                          actionButton("delete_diary", "Delete Today's Diary", 
                                       class = "btn btn-danger", 
                                       style = "background-color: #d9534f; border-color: #d43f3a; font-size: 16px; padding: 10px 20px;")
                      )
                  )
                )
              )
      )
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  
  # File paths for storing tasks
  task_files <- list(
    personal = "personal_tasks.txt",
    work = "work_tasks.txt",
    study = "study_tasks.txt",
    family = "family_tasks.txt",
    health = "health_tasks.txt",
    projects = "projects_tasks.txt"
  )
  
  # Reactive values to store current tasks in memory
  task_lists <- reactiveValues(
    personal = character(0),
    work = character(0),
    study = character(0),
    family = character(0),
    health = character(0),
    projects = character(0)
  )
  
  # Function to read tasks from file and get unique items
  read_tasks_from_file <- function(category) {
    file_path <- task_files[[category]]
    if (file.exists(file_path)) {
      tasks <- readLines(file_path, warn = FALSE)
      tasks <- tasks[nchar(tasks) > 0]  # Remove empty lines
      tasks <- unique(tasks)  # Get unique items only
      return(tasks)
    } else {
      return(character(0))
    }
  }
  
  # Function to write tasks to file (only unique items)
  write_tasks_to_file <- function(category, tasks) {
    file_path <- task_files[[category]]
    unique_tasks <- unique(tasks)
    writeLines(unique_tasks, file_path)
  }
  
  # Initialize task lists from files on startup
  observe({
    for (category in names(task_files)) {
      task_lists[[category]] <- read_tasks_from_file(category)
    }
  })
  
  # Function to add task
  add_task <- function(category, task) {
    if (nchar(trimws(task)) > 0) {
      current_tasks <- task_lists[[category]]
      if (!task %in% current_tasks) {
        new_tasks <- c(current_tasks, task)
        task_lists[[category]] <- new_tasks
        write_tasks_to_file(category, new_tasks)
      }
    }
  }
  
  # Function to remove task
  remove_task <- function(category, task_to_remove) {
    current_tasks <- task_lists[[category]]
    remaining_tasks <- current_tasks[current_tasks != task_to_remove]
    task_lists[[category]] <- remaining_tasks
    write_tasks_to_file(category, remaining_tasks)
  }
  
  # Render tasks with checkboxes for each category
  output$personal_tasks <- renderUI({
    tasks <- task_lists$personal
    if (length(tasks) > 0) {
      task_elements <- lapply(seq_along(tasks), function(i) {
        div(class = "task-item",
            checkboxInput(
              inputId = paste0("personal_check_", i),
              label = tasks[i],
              value = FALSE
            )
        )
      })
      do.call(tagList, task_elements)
    } else {
      p("No tasks yet. Add a task above!", style = "colour: #666; font-style: italic;")
    }
  })
  
  output$work_tasks <- renderUI({
    tasks <- task_lists$work
    if (length(tasks) > 0) {
      task_elements <- lapply(seq_along(tasks), function(i) {
        div(class = "task-item",
            checkboxInput(
              inputId = paste0("work_check_", i),
              label = tasks[i],
              value = FALSE
            )
        )
      })
      do.call(tagList, task_elements)
    } else {
      p("No tasks yet. Add a task above!", style = "colour: #666; font-style: italic;")
    }
  })
  
  output$study_tasks <- renderUI({
    tasks <- task_lists$study
    if (length(tasks) > 0) {
      task_elements <- lapply(seq_along(tasks), function(i) {
        div(class = "task-item",
            checkboxInput(
              inputId = paste0("study_check_", i),
              label = tasks[i],
              value = FALSE
            )
        )
      })
      do.call(tagList, task_elements)
    } else {
      p("No tasks yet. Add a task above!", style = "colour: #666; font-style: italic;")
    }
  })
  
  output$family_tasks <- renderUI({
    tasks <- task_lists$family
    if (length(tasks) > 0) {
      task_elements <- lapply(seq_along(tasks), function(i) {
        div(class = "task-item",
            checkboxInput(
              inputId = paste0("family_check_", i),
              label = tasks[i],
              value = FALSE
            )
        )
      })
      do.call(tagList, task_elements)
    } else {
      p("No tasks yet. Add a task above!", style = "colour: #666; font-style: italic;")
    }
  })
  
  output$health_tasks <- renderUI({
    tasks <- task_lists$health
    if (length(tasks) > 0) {
      task_elements <- lapply(seq_along(tasks), function(i) {
        div(class = "task-item",
            checkboxInput(
              inputId = paste0("health_check_", i),
              label = tasks[i],
              value = FALSE
            )
        )
      })
      do.call(tagList, task_elements)
    } else {
      p("No tasks yet. Add a task above!", style = "colour: #666; font-style: italic;")
    }
  })
  
  output$projects_tasks <- renderUI({
    tasks <- task_lists$projects
    if (length(tasks) > 0) {
      task_elements <- lapply(seq_along(tasks), function(i) {
        div(class = "task-item",
            checkboxInput(
              inputId = paste0("projects_check_", i),
              label = tasks[i],
              value = FALSE
            )
        )
      })
      do.call(tagList, task_elements)
    } else {
      p("No tasks yet. Add a task above!", style = "colour: #666; font-style: italic;")
    }
  })
  
  # Observe checkbox changes (no deletion, just maintain checkbox state)
  # Checkboxes now only serve as visual indicators, no deletion functionality
  
  # Submit button observers
  observeEvent(input$submit_personal, {
    if (!is.null(input$personal_task) && nchar(trimws(input$personal_task)) > 0) {
      add_task("personal", input$personal_task)
      updateTextInput(session, "personal_task", value = "")
    }
  })
  
  observeEvent(input$submit_work, {
    if (!is.null(input$work_task) && nchar(trimws(input$work_task)) > 0) {
      add_task("work", input$work_task)
      updateTextInput(session, "work_task", value = "")
    }
  })
  
  observeEvent(input$submit_study, {
    if (!is.null(input$study_task) && nchar(trimws(input$study_task)) > 0) {
      add_task("study", input$study_task)
      updateTextInput(session, "study_task", value = "")
    }
  })
  
  observeEvent(input$submit_family, {
    if (!is.null(input$family_task) && nchar(trimws(input$family_task)) > 0) {
      add_task("family", input$family_task)
      updateTextInput(session, "family_task", value = "")
    }
  })
  
  observeEvent(input$submit_health, {
    if (!is.null(input$health_task) && nchar(trimws(input$health_task)) > 0) {
      add_task("health", input$health_task)
      updateTextInput(session, "health_task", value = "")
    }
  })
  
  observeEvent(input$submit_projects, {
    if (!is.null(input$projects_task) && nchar(trimws(input$projects_task)) > 0) {
      add_task("projects", input$projects_task)
      updateTextInput(session, "projects_task", value = "")
    }
  })
  
  # Clear all tasks functionality
  observeEvent(input$clear_all_tasks, {
    # Show confirmation dialog
    showModal(modalDialog(
      title = "Clear All Tasks",
      "Are you sure you want to delete all tasks from all categories? This action cannot be undone.",
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_clear", "Yes, Clear All", class = "btn-danger")
      )
    ))
  })
  
  # Confirm clear all tasks
  observeEvent(input$confirm_clear, {
    # Clear all reactive values
    for (category in names(task_files)) {
      task_lists[[category]] <- character(0)
    }
    
    # Clear only the specific task files mentioned in this tab
    for (category in names(task_files)) {
      file_path <- task_files[[category]]
      if (file.exists(file_path)) {
        file.remove(file_path)
      }
    }
    
    # Close the modal
    removeModal()
    
    # Show success message
    showNotification("All task files have been cleared successfully!", type = "message")
  })
  
  # Diary functionality
  diary_filename <- reactive({
    paste0(Sys.Date(), "_Diary.txt")
  })
  
  # Load existing diary content on startup
  observe({
    diary_file <- diary_filename()
    if (file.exists(diary_file)) {
      content <- readLines(diary_file, warn = FALSE)
      if (length(content) > 0) {
        # Find the separator lines to split content
        events_start <- which(grepl("=== TODAY'S EVENTS ===", content))
        reflection_start <- which(grepl("=== SELF ASSESSMENT, LEARNINGS AND REFLECTION ===", content))
        
        if (length(events_start) > 0 && length(reflection_start) > 0) {
          # Extract events content
          if (events_start < reflection_start) {
            events_content <- content[(events_start + 2):(reflection_start - 2)]
            events_text <- paste(events_content, collapse = "\n")
            updateTextAreaInput(session, "todays_events", value = events_text)
          }
          
          # Extract reflection content
          reflection_content <- content[(reflection_start + 2):length(content)]
          reflection_text <- paste(reflection_content, collapse = "\n")
          updateTextAreaInput(session, "self_reflection", value = reflection_text)
        }
      }
    }
  })
  
  # Save diary functionality
  observeEvent(input$save_diary, {
    diary_file <- diary_filename()
    
    # Get content from text areas
    events_content <- input$todays_events %||% ""
    reflection_content <- input$self_reflection %||% ""
    
    # Create diary content
    diary_content <- c(
      paste("Diary Entry - ", format(Sys.Date(), "%A, %d %B %Y")),
      paste("Generated on", format(Sys.time(), "%d/%m/%Y at %H:%M")),
      paste(rep("=", 60), collapse = ""),
      "",
      "=== TODAY'S EVENTS ===",
      "",
      events_content,
      "",
      "=== SELF ASSESSMENT, LEARNINGS AND REFLECTION ===",
      "",
      reflection_content
    )
    
    # Write to file
    writeLines(diary_content, diary_file)
    
    # Show success message
    showNotification(paste("Diary saved successfully as", diary_file), type = "message")
  })
  
  # Delete diary functionality
  observeEvent(input$delete_diary, {
    diary_file <- diary_filename()
    
    if (file.exists(diary_file)) {
      # Show confirmation dialog
      showModal(modalDialog(
        title = "Delete Today's Diary",
        paste("Are you sure you want to delete the diary file:", diary_file, "? This action cannot be undone."),
        footer = tagList(
          modalButton("Cancel"),
          actionButton("confirm_delete_diary", "Yes, Delete", class = "btn-danger")
        )
      ))
    } else {
      showNotification("No diary file exists for today.", type = "warning")
    }
  })
  
  # Confirm delete diary
  observeEvent(input$confirm_delete_diary, {
    diary_file <- diary_filename()
    
    if (file.exists(diary_file)) {
      file.remove(diary_file)
      
      # Clear the text areas
      updateTextAreaInput(session, "todays_events", value = "")
      updateTextAreaInput(session, "self_reflection", value = "")
      
      # Close the modal
      removeModal()
      
      # Show success message
      showNotification(paste("Diary file", diary_file, "has been deleted successfully!"), type = "message")
    }
  })
  
  # Download diary functionality
  output$download_diary <- downloadHandler(
    filename = function() {
      diary_filename()
    },
    content = function(file) {
      diary_file <- diary_filename()
      
      if (file.exists(diary_file)) {
        # Copy the existing file
        file.copy(diary_file, file)
      } else {
        # Create file with current content from text areas
        events_content <- input$todays_events %||% ""
        reflection_content <- input$self_reflection %||% ""
        
        # Create diary content
        diary_content <- c(
          paste("Diary Entry - ", format(Sys.Date(), "%A, %d %B %Y")),
          paste("Generated on", format(Sys.time(), "%d/%m/%Y at %H:%M")),
          paste(rep("=", 60), collapse = ""),
          "",
          "=== TODAY'S EVENTS ===",
          "",
          events_content,
          "",
          "=== SELF ASSESSMENT, LEARNINGS AND REFLECTION ===",
          "",
          reflection_content
        )
        
        # Write to download file
        writeLines(diary_content, file)
      }
    }
  )
  
  # Download handler for all tasks
  output$download_all_tasks <- downloadHandler(
    filename = function() {
      paste0(Sys.Date(), "_Tasks.txt")
    },
    content = function(file) {
      # Read all tasks from all categories
      all_content <- c()
      
      for (category in names(task_files)) {
        # Read tasks from file
        tasks <- read_tasks_from_file(category)
        
        if (length(tasks) > 0) {
          # Add category header
          category_header <- paste("=== ", toupper(category), " TASKS ===")
          all_content <- c(all_content, "", category_header, "")
          
          # Add each task with a bullet point
          for (task in tasks) {
            all_content <- c(all_content, paste("• ", task))
          }
          
          all_content <- c(all_content, "")
        }
      }
      
      # If no tasks found, add a message
      if (length(all_content) == 0) {
        all_content <- "No tasks found in any category."
      } else {
        # Add header with date and time
        header <- c(
          paste("Task Summary - Generated on", Sys.Date(), "at", format(Sys.time(), "%H:%M")),
          paste(rep("=", 60), collapse = ""),
          ""
        )
        all_content <- c(header, all_content)
      }
      
      # Write to file
      writeLines(all_content, file)
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)