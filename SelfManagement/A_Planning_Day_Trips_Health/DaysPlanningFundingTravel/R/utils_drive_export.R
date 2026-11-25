# R/utils_drive_export.R
# =============================================================================
# "Save Diagrams to Google Drive" box, shared by every tab that draws a diagram.
#
# Each tab gives the box:
#   specs   : reactive returning a NAMED list of diagram specs (R/utils_diagram.R);
#             a NULL entry is skipped. Example: list(time_allocation = dg_bar(...))
#   subject : function returning the subject folder name (a date, a week, a filter)
#
# Files land in   <root>/<tab group>/<tab>/<subject>/<name>.<format>
# (see R/utils_gdrive.R). Each file is saved on its own, so one failure does
# not stop the rest; the result list says what was saved and what was not.
# =============================================================================

# UI: the collapsed box with format choices and one save button.
drive_export_ui <- function(ns, title = "Save Diagrams to Google Drive", formats = names(DG_FORMATS), selected = "png") {
  fluidRow(
    box(title = title, status = "info", solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE,
        p("Saves the diagram(s) of this view to the shared Google Drive folder, so other R Shiny apps can read them. ",
          "Folders are created as needed, and a file with the same name is replaced in place. ",
          "Set the folder up in API Configuration > Google Drive first."),
        checkboxGroupInput(ns("drive_formats"), "Formats to save:",
                           choices = stats::setNames(formats, unname(DG_FORMATS[formats])),
                           selected = selected, inline = TRUE),
        fluidRow(
          column(4, actionButton(ns("drive_save"), "Save to Google Drive", icon = icon("cloud-upload-alt"),
                                 class = "btn-success", style = "width: 100%;")),
          column(8, htmlOutput(ns("drive_where")))
        ),
        htmlOutput(ns("drive_status"))
    )
  )
}

# Shows the target folder, or that Drive is not connected yet. Refreshes every few seconds so a new connection shows up.
drive_export_server <- function(input, output, session, api, group, tab, specs, subject = function() "general") {
  output$drive_where <- renderUI({
    invalidateLater(4000, session)
    if (isTRUE(api$gdrive_authenticated)) {
      tags$div(class = "status-info", style = "margin-top: 6px;", tags$i(class = "fa fa-folder-open"),
               sprintf(" Saves to “%s / %s / %s / %s”", api$gdrive_root_name %||% "root", group, tab,
                       gdrive_safe_name(subject() %||% "general")))
    } else {
      tags$div(class = "status-warning", style = "margin-top: 6px;", tags$i(class = "fa fa-exclamation-triangle"),
               " Google Drive is not connected. Set it up in API Configuration > Google Drive.")
    }
  })

  observeEvent(input$drive_save, {
    if (!isTRUE(api$gdrive_authenticated)) {
      output$drive_status <- renderUI(tags$div(class = "status-error", "Not connected to Google Drive. Open API Configuration > Google Drive first."))
      showNotification("Google Drive is not connected yet.", type = "error")
      return()
    }
    formats <- input$drive_formats
    if (!length(formats)) { showNotification("Choose at least one format.", type = "warning"); return() }
    items <- specs()
    items <- items[!vapply(items, is.null, logical(1))]
    if (!length(items)) { showNotification("Load the view first, then save it.", type = "warning"); return() }

    parts <- c(group, tab, gdrive_safe_name(subject() %||% "general"))
    res <- withProgress(message = "Saving to Google Drive", value = 0, {
      drive_save_diagrams(api, parts, items, formats,
                          on_progress = function(k, n, f) incProgress(1 / n, detail = f))
    })
    ok <- vapply(res, function(r) isTRUE(r$ok), logical(1))
    output$drive_status <- renderUI(drive_result_html(res))
    showNotification(sprintf("Saved %d of %d file(s) to Google Drive", sum(ok), length(ok)),
                     type = if (all(ok)) "message" else "warning")
  })
}

# Renders every diagram in every requested format and saves each one under the folder path.
# Returns a list with one entry per file: ok, file, folder, link, action, msg.
drive_save_diagrams <- function(api, folder_parts, items, formats, on_progress = NULL) {
  key <- gdrive_key_for(api)
  if (is.null(key)) stop("No Google Drive key is available.", call. = FALSE)
  total <- length(items) * length(formats)
  folder_label <- paste(folder_parts, collapse = " / ")
  out <- list(); k <- 0L
  folder_id <- NULL
  for (fmt in formats) for (nm in names(items)) {
    k <- k + 1L
    fname <- paste0(gdrive_safe_name(nm), ".", fmt)
    tmp <- tempfile(fileext = paste0(".", fmt))
    res <- tryCatch({
      dg_render(items[[nm]], fmt, tmp)
      save_once <- function() {
        if (is.null(folder_id)) folder_id <<- gdrive_folder_path(key, api$gdrive_root_id, folder_parts)
        gdrive_save_file(key, folder_id, fname, tmp, DG_MIME[[fmt]])
      }
      up <- tryCatch(save_once(), error = function(e) {
        # a folder deleted in Drive since it was cached: forget the cache and try once more
        if (!grepl("HTTP 404", conditionMessage(e), fixed = TRUE)) stop(e)
        gdrive_clear_cache(); folder_id <<- NULL
        save_once()
      })
      list(ok = TRUE, file = fname, folder = folder_label, link = up$link, action = up$action, msg = "")
    }, error = function(e) {
      cat(sprintf("[Drive] could not save %s: %s\n", fname, conditionMessage(e)))
      list(ok = FALSE, file = fname, folder = folder_label, link = "", action = "", msg = conditionMessage(e))
    })
    unlink(tmp)
    out[[length(out) + 1L]] <- res
    if (!is.null(on_progress)) on_progress(k, total, fname)
  }
  out
}

drive_result_html <- function(res) {
  esc <- function(x) htmltools::htmlEscape(as.character(x %||% ""))
  rows <- vapply(res, function(r) {
    if (isTRUE(r$ok)) {
      link <- if (nzchar(r$link %||% "")) sprintf(' <a href="%s" target="_blank">open in Drive</a>', esc(r$link)) else ""
      sprintf('<li><i class="fa fa-check-circle" style="color:#27ae60"></i> %s / %s <small>(%s)</small>%s</li>',
              esc(r$folder), esc(r$file), esc(r$action), link)
    } else {
      sprintf('<li><i class="fa fa-times-circle" style="color:#c0392b"></i> %s: %s</li>', esc(r$file), esc(r$msg))
    }
  }, "")
  HTML(paste0('<ul style="margin: 8px 0 0 16px; padding: 0; list-style: none;">', paste(rows, collapse = ""), "</ul>"))
}
