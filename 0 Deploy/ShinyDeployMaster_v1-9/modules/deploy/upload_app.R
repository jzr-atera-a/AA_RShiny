# modules/deploy/upload_app.R
# Upload App — accepts a zip file, unzips to a timestamped temp directory,
# detects the app root (folder containing app.R or server.R), shows a
# directory tree, and stores all paths in deploy_mgr.

# ── Directory tree helper ─────────────────────────────────────
build_dir_tree <- function(path, prefix = "", max_depth = 4, depth = 0) {
  if (depth >= max_depth) return(character(0))
  items <- tryCatch(list.files(path, all.files = FALSE), error = function(e) character(0))
  if (length(items) == 0) return(character(0))
  result <- character(0)
  for (i in seq_along(items)) {
    is_last    <- (i == length(items))
    connector  <- if (is_last) "\u2514\u2500 " else "\u251c\u2500 "
    item_path  <- file.path(path, items[i])
    is_dir     <- dir.exists(item_path)
    icon_chr   <- if (is_dir) "\U0001f4c1 " else "\U0001f4c4 "
    result     <- c(result, paste0(prefix, connector, icon_chr, items[i]))
    if (is_dir) {
      new_prefix <- paste0(prefix, if (is_last) "   " else "\u2502  ")
      result <- c(result, build_dir_tree(item_path, new_prefix, max_depth, depth + 1))
    }
  }
  result
}

upload_app_ui <- function(id) {
  ns <- NS(id)
  tagList(
    div(class = "meta-hero",
        tags$h1("\U0001f4e4 Upload App"),
        tags$h2("Upload a zip file containing your Shiny app \u2014 it will be extracted to a secure temp location"),
        div(
          span(class = "hero-badge", "Zip Upload"),
          span(class = "hero-badge", "Auto Extract"),
          span(class = "hero-badge", "Auto Detect app.R"),
          span(class = "hero-badge", "Secure Temp")
        )
    ),

    fluidRow(
      # ── Upload panel ─────────────────────────────────────────
      box(title = "\U0001f4e6 Select & Upload Zip", status = "primary",
          solidHeader = TRUE, width = 5,

          ua_callout(paste0(
            "Upload a .zip file containing your Shiny app. The zip is extracted to a ",
            "secure temporary directory on this server. After successful deployment the ",
            "zip and extracted files are automatically deleted. Files are kept on failure ",
            "so you can retry without re-uploading."
          )),
          br(),

          fileInput(ns("zip_file"),
                    "Select zip file:",
                    accept = ".zip",
                    buttonLabel = tagList(icon("folder-open"), " Browse"),
                    placeholder = "No file selected"),

          uiOutput(ns("upload_size_info")),
          br(),

          actionButton(ns("btn_extract"),
                       tagList(icon("file-archive"), " Extract Zip"),
                       class = "btn-primary btn-lg btn-block"),
          br(),
          uiOutput(ns("extract_status")),
          br(),

          # Manual app dir override
          div(class = "section-heading-dark", "Manual app directory override (optional)"),
          uiOutput(ns("app_dir_override_ui")),
          uiOutput(ns("override_status"))
      ),

      # ── Preview panel ─────────────────────────────────────────
      box(title = "\U0001f9fe Extracted Contents", status = "info",
          solidHeader = TRUE, width = 7,

          uiOutput(ns("extract_summary")),
          br(),
          div(
            style = paste0(
              "background:#060D18;border-radius:10px;padding:14px 16px;",
              "min-height:340px;max-height:480px;overflow-y:auto;",
              "font-family:'JetBrains Mono',monospace;font-size:12px;color:#94A3B8;"
            ),
            uiOutput(ns("dir_tree_output"))
          )
      )
    )
  )
}

upload_app_server <- function(id, deploy_mgr) {
  moduleServer(id, function(input, output, session) {

    ns <- session$ns

    # ── Show zip file info before extraction ─────────────────
    output$upload_size_info <- renderUI({
      req(input$zip_file)
      size_mb <- round(input$zip_file$size / 1024^2, 2)
      div(class = "tip-box",
          HTML(paste0(
            "\U0001f4ce <strong>", input$zip_file$name, "</strong>",
            " \u2014 ", size_mb, " MB"
          )))
    })

    # ── Extract button ────────────────────────────────────────
    observeEvent(input$btn_extract, {
      req(input$zip_file)

      deploy_mgr$log("UPLOAD", paste("Starting extraction of:", input$zip_file$name), "info")

      tryCatch({
        # Create a timestamped temp subdirectory
        ts       <- format(Sys.time(), "%Y%m%d_%H%M%S")
        temp_dir <- file.path(tempdir(), paste0("shiny_deploy_", ts))
        dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)

        # Copy zip to temp location (upload path may be cleared by Shiny)
        zip_dest <- file.path(temp_dir, input$zip_file$name)
        file.copy(input$zip_file$datapath, zip_dest)

        deploy_mgr$log("UPLOAD",
                        paste("Zip copied to:", zip_dest),
                        "info")

        # Unzip
        unzip_dir <- file.path(temp_dir, "extracted")
        dir.create(unzip_dir, showWarnings = FALSE)
        utils::unzip(zip_dest, exdir = unzip_dir)

        deploy_mgr$log("UPLOAD",
                        paste("Extracted to:", unzip_dir),
                        "success")

        # Auto-detect app root (first directory containing app.R or server.R)
        all_r_files <- list.files(unzip_dir, pattern = "^(app|server)\\.R$",
                                   recursive = TRUE, full.names = TRUE)

        detected_app_dir <- if (length(all_r_files) > 0) {
          d <- dirname(all_r_files[1])
          deploy_mgr$log("UPLOAD",
                          paste("App root detected:", d),
                          "success")
          d
        } else {
          deploy_mgr$log("UPLOAD",
                          "No app.R/server.R found — using top-level extraction dir.",
                          "warn")
          unzip_dir
        }

        # Store in deploy_mgr
        deploy_mgr$zip_temp_path    <- zip_dest
        deploy_mgr$unzip_temp_dir   <- temp_dir
        deploy_mgr$detected_app_dir <- detected_app_dir

        showNotification("\u2713 Zip extracted successfully", type = "message")

      }, error = function(e) {
        deploy_mgr$log("UPLOAD", paste("Extraction failed:", e$message), "error")
        showNotification(paste("Extraction error:", e$message), type = "error")
      })
    })

    # ── Extract status message ────────────────────────────────
    output$extract_status <- renderUI({
      deploy_mgr$debug_trigger()

      if (!is.null(deploy_mgr$detected_app_dir)) {
        div(class = "success-box",
            HTML(paste0(
              "\u2705 <strong>Extraction complete.</strong><br>",
              "App root: <code>", deploy_mgr$detected_app_dir, "</code>"
            )))
      } else if (!is.null(input$zip_file)) {
        div(class = "tip-box", "Click \u2018Extract Zip\u2019 to proceed.")
      } else {
        div()
      }
    })

    # ── Manual override input (shown after extraction) ────────
    output$app_dir_override_ui <- renderUI({
      deploy_mgr$debug_trigger()
      req(!is.null(deploy_mgr$detected_app_dir))
      textInput(ns("manual_app_dir"),
                NULL,
                value = deploy_mgr$detected_app_dir,
                placeholder = "Override detected app directory if needed")
    })

    output$override_status <- renderUI({
      req(input$manual_app_dir)
      deploy_mgr$debug_trigger()
      if (nchar(trimws(input$manual_app_dir)) > 0 &&
          input$manual_app_dir != deploy_mgr$detected_app_dir) {
        if (dir.exists(input$manual_app_dir)) {
          deploy_mgr$detected_app_dir <- trimws(input$manual_app_dir)
          div(class = "success-box",
              HTML(paste0("\u2705 App directory overridden to: <code>",
                           input$manual_app_dir, "</code>")))
        } else {
          div(class = "warn-box",
              HTML(paste0("\u26a0 Directory does not exist: <code>",
                           input$manual_app_dir, "</code>")))
        }
      } else {
        div()
      }
    })

    # ── Extraction summary metrics ────────────────────────────
    output$extract_summary <- renderUI({
      deploy_mgr$debug_trigger()
      req(!is.null(deploy_mgr$detected_app_dir))

      app_dir <- deploy_mgr$detected_app_dir
      if (!dir.exists(app_dir)) return(div())

      all_files <- list.files(app_dir, recursive = TRUE)
      r_files   <- all_files[grepl("\\.R$", all_files, ignore.case = TRUE)]
      has_app   <- any(grepl("^app\\.R$", basename(all_files)))
      has_srv   <- any(grepl("^server\\.R$", basename(all_files)))

      fluidRow(
        column(3, div(class = "metric-card",
                      span(class = "metric-value", length(all_files)),
                      span(class = "metric-label", "Total Files"))),
        column(3, div(class = "metric-card",
                      span(class = "metric-value", length(r_files)),
                      span(class = "metric-label", ".R Files"))),
        column(3, div(class = "metric-card",
                      style = if (has_app || has_srv)
                        "background:linear-gradient(135deg,#166534,#22c55e);"
                      else
                        "background:linear-gradient(135deg,#991b1b,#ef4444);",
                      span(class = "metric-value",
                           if (has_app) "app.R" else if (has_srv) "server.R" else "?"),
                      span(class = "metric-label", "Entry Point"))),
        column(3, div(class = "metric-card",
                      span(class = "metric-value",
                           paste0(round(
                             sum(file.info(
                               list.files(app_dir, recursive = TRUE, full.names = TRUE)
                             )$size, na.rm = TRUE) / 1024^2, 1), " MB")),
                      span(class = "metric-label", "Total Size")))
      )
    })

    # ── Directory tree ────────────────────────────────────────
    output$dir_tree_output <- renderUI({
      deploy_mgr$debug_trigger()

      if (is.null(deploy_mgr$detected_app_dir) ||
          !dir.exists(deploy_mgr$detected_app_dir)) {
        return(div(style = "color:#4B5563;padding:10px;",
                   "Extract a zip file to see its structure here."))
      }

      tree_lines <- tryCatch(
        build_dir_tree(deploy_mgr$detected_app_dir),
        error = function(e) paste("Error building tree:", e$message)
      )

      if (length(tree_lines) == 0) {
        return(div(style = "color:#4B5563;", "Empty directory."))
      }

      root_name <- basename(deploy_mgr$detected_app_dir)
      all_lines <- c(
        paste0("\U0001f4c2 ", root_name, "/  ",
               tags$span(style = "color:#A78BFA;font-size:10px;",
                         "[app root]")),
        tree_lines
      )

      tags$div(
        lapply(all_lines, function(l) {
          # Colour .R files differently
          col <- if (grepl("\\.R$", l))        "#A5D8FF"
                 else if (grepl("\\.yaml$|\\.yml$", l)) "#FCD34D"
                 else if (grepl("\\.css$",  l)) "#F9A8D4"
                 else if (grepl("^\U0001f4c2", l)) "#C4B5FD"
                 else "#6B7280"
          div(style = paste0("color:", col, ";line-height:1.65;white-space:pre;"), l)
        })
      )
    })
  })
}
