# modules/Visual Media/image_to_pdf.R
# Subtab: Image to PDF

IMG_TO_PDF_DPI <- 300
STANDARD_PAGE_SIZES <- list(
  "Letter (8.5 x 11 in)"  = c(8.5, 11),
  "Legal (8.5 x 14 in)"   = c(8.5, 14),
  "Tabloid (11 x 17 in)"  = c(11, 17),
  "A3 (11.69 x 16.54 in)" = c(11.69, 16.54),
  "A4 (8.27 x 11.69 in)"  = c(8.27, 11.69),
  "A5 (5.83 x 8.27 in)"   = c(5.83, 8.27),
  "A6 (4.13 x 5.83 in)"   = c(4.13, 5.83),
  "B5 (6.93 x 9.84 in)"   = c(6.93, 9.84)
)

image_to_pdf_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(title = "Image to PDF Configuration", status = "primary", solidHeader = TRUE, width = 12,
          h4("Select Image Files"),
          p("Select several JPEG, PNG, or GIF images (ideally of similar size) to combine into a single multi-page PDF, one image per page. Files are automatically ordered by their timestamp (oldest first) - handy for screenshot sequences regardless of the order they were selected in. Animated GIFs use only their first frame. PNG screenshots with transparent backgrounds are flattened onto a white background so they display correctly.",
            style = "color: #6c757d; font-style: italic;"),
          fileInput(ns("img_files"), "Select Image Files (JPEG / PNG / GIF):", accept = c(".jpg", ".jpeg", ".png", ".gif"),
                    multiple = TRUE, placeholder = "No files selected"),

          # Capture each file's original last-modified timestamp via the browser's
          # File API (not exposed by fileInput by default), namespaced to this module.
          tags$script(HTML(sprintf("
            $(document).on('change', '#%s', function(evt) {
              var files = evt.target.files;
              var timestamps = [];
              for (var i = 0; i < files.length; i++) {
                timestamps.push(files[i].lastModified);
              }
              Shiny.setInputValue('%s', timestamps, {priority: 'event'});
            });
          ", ns("img_files"), ns("img_files_timestamps")))),

          hr(),
          fluidRow(
            column(4, h4("Page Size"), selectInput(ns("img_page_size"), "Standard Page Size:", choices = names(STANDARD_PAGE_SIZES), selected = "Letter (8.5 x 11 in)")),
            column(4, h4("Page Orientation"), selectInput(ns("img_orientation"), "Orientation:",
                                                           choices = c("Portrait (Vertical)" = "Portrait", "Landscape (Horizontal)" = "Landscape"), selected = "Portrait")),
            column(4, h4("Image Rotation"), selectInput(ns("img_rotation"), "Rotate Each Image:",
                                                         choices = c("0 degrees" = "0", "90 degrees" = "90", "180 degrees" = "180", "270 degrees" = "270"), selected = "0"))
          ),
          hr(),
          fluidRow(column(12,
                          h4("Page Background / Gap Fill Color"),
                          p("If an image's proportions don't perfectly match the selected page size, the leftover space around it can be filled with a color instead of white. Optionally select a sample JPEG, PNG, or GIF below to extract its 5 most dominant colors, then check one swatch to use it as the fill for every page. Leave none checked to keep the gaps white (default).",
                            style = "color: #6c757d; font-style: italic; margin-bottom: 10px;"),
                          fileInput(ns("color_sample_file"), "Select Sample Image for Color Palette (optional):", accept = c(".jpg", ".jpeg", ".png", ".gif"),
                                    multiple = FALSE, placeholder = "No sample image selected"),
                          uiOutput(ns("color_palette_ui")))),
          hr(),
          fluidRow(
            column(6, h4("Output File"), textInput(ns("img_pdf_filename"), "PDF Filename:", placeholder = "combined_images.pdf", value = "combined_images.pdf")),
            column(6, h4("Output Directory"),
                   fluidRow(
                     column(9, div(class = "directory-display", textOutput(ns("selected_img_pdf_dir")))),
                     column(3, br(), shinyDirButton(ns("img_pdf_dir_select"), "Browse", "Select output directory", class = "btn-primary", style = "width: 100%;"))
                   ))
          ),
          br(),
          fluidRow(column(12, actionButton(ns("create_img_pdf_btn"), "Create PDF from Images", class = "btn-primary btn-lg", style = "width: 100%;"))))
    ),
    fluidRow(box(title = "Selected Images Summary", status = "info", solidHeader = TRUE, width = 12,
                 div(class = "info-box", verbatimTextOutput(ns("img_files_summary"))))),
    fluidRow(box(title = "PDF Creation Status", status = "info", solidHeader = TRUE, width = 12,
                 div(class = "info-box", verbatimTextOutput(ns("img_pdf_status")))))
  )
}

image_to_pdf_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {
    volumes <- get_volume_roots()
    shinyDirChoose(input, "img_pdf_dir_select", roots = volumes, session = session, restrictions = system.file(package = "base"))

    values <- reactiveValues(img_pdf_directory = NULL,
                              img_pdf_status_text = "Select image files, page size, orientation, rotation, and output path, then click 'Create PDF from Images'.",
                              color_palette = character(0))

    observe({
      if (!is.null(input$img_pdf_dir_select) && !is.integer(input$img_pdf_dir_select)) {
        tryCatch({
          selected_path <- parseDirPath(volumes, input$img_pdf_dir_select)
          if (length(selected_path) > 0 && selected_path != "") {
            values$img_pdf_directory <- as.character(selected_path)
            showNotification("Output directory selected successfully!", type = "message", duration = 2)
          }
        }, error = function(e) showNotification(paste("Error selecting directory:", e$message), type = "warning"))
      }
    })

    output$selected_img_pdf_dir <- renderText({
      if (is.null(values$img_pdf_directory) || length(values$img_pdf_directory) == 0) "No directory selected - Click 'Browse' to select"
      else values$img_pdf_directory
    })

    img_files_sorted <- reactive({
      req(input$img_files)
      files_df <- input$img_files
      ts <- input$img_files_timestamps

      if (!is.null(ts) && length(ts) == nrow(files_df)) {
        files_df$timestamp_ms <- as.numeric(ts)
        files_df <- files_df[order(files_df$timestamp_ms), ]
        rownames(files_df) <- NULL
      } else {
        files_df$timestamp_ms <- NA_real_
      }
      files_df
    })

    output$img_files_summary <- renderText({
      if (is.null(input$img_files)) {
        "No image files selected yet. Please select JPEG, PNG, or GIF images to combine."
      } else {
        files_df <- img_files_sorted()
        n_files <- nrow(files_df)
        timestamps_available <- !all(is.na(files_df$timestamp_ms))

        summary_text <- paste0("Selected Images (", n_files, ") - ",
                               if (timestamps_available) "sorted oldest to newest, this is the order they'll appear in the PDF:\n\n"
                               else "timestamps unavailable, using browser selection order:\n\n")
        for (i in 1:n_files) {
          file_size_mb <- round(files_df$size[i] / 1024 / 1024, 2)
          timestamp_str <- if (!is.na(files_df$timestamp_ms[i])) {
            paste0(" - ", format(as.POSIXct(files_df$timestamp_ms[i] / 1000, origin = "1970-01-01", tz = Sys.timezone()), "%Y-%m-%d %H:%M:%S"))
          } else ""
          summary_text <- paste0(summary_text, i, ". ", files_df$name[i], " (", file_size_mb, " MB)", timestamp_str, "\n")
        }
        summary_text
      }
    })

    observeEvent(input$color_sample_file, {
      req(input$color_sample_file)
      showNotification("Extracting dominant colors from sample image...", type = "message", duration = 2, id = "extracting_palette")

      palette <- get_top_colors(input$color_sample_file$datapath, n = 5)
      removeNotification("extracting_palette")

      if (length(palette) == 0) {
        values$color_palette <- character(0)
        showNotification("Could not extract colors from that image.", type = "warning", duration = 5)
      } else {
        values$color_palette <- palette
        updateCheckboxGroupInput(session, "fill_color_checkboxes", selected = character(0))
      }
    })

    output$color_palette_ui <- renderUI({
      if (length(values$color_palette) == 0) {
        return(p("No sample image processed yet - gaps will be filled with white.", style = "color: #6c757d; font-style: italic;"))
      }

      choice_names <- lapply(values$color_palette, function(hex) {
        tagList(
          span(style = paste0("display:inline-block; width:24px; height:24px; background-color:", hex,
                              "; border:1px solid #333; vertical-align:middle; margin-right:8px; border-radius:4px;")),
          span(hex, style = "vertical-align:middle; font-family: monospace;")
        )
      })

      tagList(checkboxGroupInput(session$ns("fill_color_checkboxes"), "Select one color to use for page gaps:",
                                  choiceNames = choice_names, choiceValues = as.list(values$color_palette),
                                  selected = character(0), inline = TRUE))
    })

    observeEvent(input$fill_color_checkboxes, {
      if (length(input$fill_color_checkboxes) > 1) {
        newest <- tail(input$fill_color_checkboxes, 1)
        updateCheckboxGroupInput(session, "fill_color_checkboxes", selected = newest)
      }
    }, ignoreNULL = FALSE)

    observeEvent(input$create_img_pdf_btn, {
      req(input$img_files)

      if (is.null(values$img_pdf_directory) || length(values$img_pdf_directory) == 0 || values$img_pdf_directory == "") {
        showNotification("Please select an output directory first.", type = "warning", duration = 5)
        values$img_pdf_status_text <- "❌ Error: No output directory selected. Click 'Browse' to select one."
        return()
      }
      if (is.null(input$img_pdf_filename) || trimws(input$img_pdf_filename) == "") {
        showNotification("Please specify an output filename.", type = "warning", duration = 5)
        values$img_pdf_status_text <- "❌ Error: No output filename specified."
        return()
      }

      showNotification("Building PDF from images... This may take a while for large/many files.", type = "message", duration = NULL, id = "processing_img_pdf")

      files_df <- img_files_sorted()
      n_files <- nrow(files_df)
      values$img_pdf_status_text <- paste0("Processing ", n_files, " image(s)...")

      tryCatch({
        dims_in <- STANDARD_PAGE_SIZES[[input$img_page_size]]
        page_w_in <- dims_in[1]; page_h_in <- dims_in[2]

        if (input$img_orientation == "Landscape") {
          if (page_w_in < page_h_in) { tmp <- page_w_in; page_w_in <- page_h_in; page_h_in <- tmp }
        } else {
          if (page_h_in < page_w_in) { tmp <- page_w_in; page_w_in <- page_h_in; page_h_in <- tmp }
        }

        page_w_px <- round(page_w_in * IMG_TO_PDF_DPI)
        page_h_px <- round(page_h_in * IMG_TO_PDF_DPI)
        page_geometry <- paste0(page_w_px, "x", page_h_px)

        rotation_deg <- as.numeric(input$img_rotation)

        fill_color <- if (!is.null(input$fill_color_checkboxes) && length(input$fill_color_checkboxes) > 0) input$fill_color_checkboxes[1] else "white"

        output_filename <- trimws(input$img_pdf_filename)
        if (!grepl("\\.pdf$", output_filename, ignore.case = TRUE)) output_filename <- paste0(output_filename, ".pdf")
        output_path <- file.path(values$img_pdf_directory, output_filename)

        if (!dir.exists(values$img_pdf_directory)) dir.create(values$img_pdf_directory, recursive = TRUE)
        if (file.exists(output_path)) showNotification("Warning: Output file already exists and will be overwritten.", type = "warning", duration = 3)

        processed_images <- list()
        skipped_files <- character(0)

        withProgress(message = "Building PDF from images", value = 0, {
          for (i in 1:n_files) {
            file_name <- files_df$name[i]
            file_path <- files_df$datapath[i]

            incProgress(1 / n_files, detail = paste("Processing", file_name))

            img_result <- tryCatch({
              if (!file.exists(file_path)) stop("File does not exist or cannot be accessed")

              img <- magick::image_read(file_path)
              if (length(img) > 1) img <- img[1]

              img <- magick::image_background(img, fill_color, flatten = TRUE)
              if (rotation_deg != 0) img <- magick::image_rotate(img, rotation_deg)
              img <- magick::image_resize(img, paste0(page_geometry, ">"))

              info <- magick::image_info(img)
              if (is.null(info) || nrow(info) == 0 || info$width[1] <= 0 || info$height[1] <= 0) stop("Image has invalid or zero dimensions after processing")

              list(raster = grDevices::as.raster(img), aspect_ratio = info$width[1] / info$height[1])
            }, error = function(e) {
              skipped_files <<- c(skipped_files, paste0(file_name, " (error: ", e$message, ")"))
              NULL
            })

            if (!is.null(img_result)) processed_images[[length(processed_images) + 1]] <- img_result
          }
        })

        if (length(processed_images) == 0) stop("No images could be processed. All files were skipped due to errors.")

        page_aspect_ratio <- page_w_in / page_h_in

        grDevices::pdf(file = output_path, width = page_w_in, height = page_h_in, onefile = TRUE)
        tryCatch({
          for (item in processed_images) {
            grid::grid.newpage()
            grid::grid.rect(gp = grid::gpar(fill = fill_color, col = NA))

            img_ar <- item$aspect_ratio
            if (img_ar > page_aspect_ratio) {
              draw_width_npc <- 1
              draw_height_npc <- page_aspect_ratio / img_ar
            } else {
              draw_height_npc <- 1
              draw_width_npc <- img_ar / page_aspect_ratio
            }

            grid::grid.raster(item$raster, x = 0.5, y = 0.5,
                              width = grid::unit(draw_width_npc, "npc"), height = grid::unit(draw_height_npc, "npc"), just = "center")
          }
        }, finally = { grDevices::dev.off() })

        if (!file.exists(output_path) || file.size(output_path) == 0) stop("PDF creation appeared to complete but output file was not created or is empty")

        output_size <- round(file.size(output_path) / 1024 / 1024, 2)
        removeNotification("processing_img_pdf")

        status_msg <- paste0("✅ Successfully created a ", length(processed_images), "-page PDF from ", length(processed_images), " of ", n_files, " image(s)!\n\n",
                             "Output: ", basename(output_path), " (", output_size, " MB)\nLocation: ", values$img_pdf_directory, "\n",
                             "Page Size: ", input$img_page_size, " (", input$img_orientation, ")\nImage Rotation: ", rotation_deg, " degrees\n",
                             "Gap Fill Color: ", if (fill_color != "white") paste0(fill_color, " (from sample image palette)") else "White (default)")

        if (length(skipped_files) > 0) status_msg <- paste0(status_msg, "\n\n⚠ Skipped files:\n", paste0("- ", skipped_files, collapse = "\n"))

        values$img_pdf_status_text <- status_msg
        showNotification(paste("PDF successfully created:", basename(output_path)), type = "message", duration = 5)
      }, error = function(e) {
        removeNotification("processing_img_pdf")
        values$img_pdf_status_text <- paste0("❌ Error creating PDF from images:\n", e$message)
        showNotification(paste("Error creating PDF:", e$message), type = "error", duration = 10)
      })
    })

    output$img_pdf_status <- renderText({ values$img_pdf_status_text })
  })
}
