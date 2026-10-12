# modules/Events Scheduling/zoom_schedule/server.R

zoom_schedule_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    last <- reactiveVal(NULL)       # list(ok, invite, warnings, raw_ics, raw_text, image_uri) of the latest read
    msg <- reactiveVal(NULL)        # list(ok, text)

    output$claude_note <- renderUI({
      if (!isTRUE(api_manager$claude_authenticated)) {
        div(class = "status-warning", icon("exclamation-triangle"), " Claude is not connected. Open ",
            tags$strong("API Configuration > Claude API Config"), " first.")
      }
    })

    hand_off <- function(res) {
      inv <- res$invite
      inv$stamp <- Sys.time()
      inv$raw_ics <- res$raw_ics
      api_manager$zoom_invite(inv)
      api_manager$titan_goto("new")
      tryCatch(updateTabItems(session$rootScope(), "sidebar_menu", selected = "events_to_calendar"),
               error = function(e) cat("[Zoom] could not switch tab:", conditionMessage(e), "\n"))
    }

    observeEvent(input$read_invite, {
      f <- input$invite_image
      if (is.null(f) || nrow(f) == 0) { msg(list(ok = FALSE, text = "Choose at least one invite image first.")); return() }
      if (!isTRUE(api_manager$claude_authenticated)) {
        msg(list(ok = FALSE, text = "Claude is not connected (API Configuration > Claude API Config).")); return()
      }
      if (nrow(f) > ZOOM_MAX_IMAGES) {
        msg(list(ok = FALSE, text = sprintf("Please upload at most %d images at a time (you chose %d).", ZOOM_MAX_IMAGES, nrow(f)))); return()
      }
      imgs <- list(); uris <- character(0)
      for (k in seq_len(nrow(f))) {
        nm <- f$name[k]; dp <- f$datapath[k]
        ext <- tolower(tools::file_ext(nm))
        mt <- ZOOM_IMAGE_TYPES[ext]
        if (is.na(mt)) { msg(list(ok = FALSE, text = sprintf("%s: use a PNG, JPG, GIF or WebP image.", nm))); return() }
        size <- file.info(dp)$size
        if (is.na(size) || size == 0) { msg(list(ok = FALSE, text = sprintf("%s: the image file is empty.", nm))); return() }
        if (size > ZOOM_MAX_IMAGE_BYTES) {
          msg(list(ok = FALSE, text = sprintf("%s is %.1f MB; Claude accepts up to 5 MB per image. Crop or shrink it and try again.", nm, size / 1048576))); return()
        }
        raw <- readBin(dp, "raw", size)
        sig_ok <- switch(unname(mt),
          "image/png"  = identical(raw[1:4], as.raw(c(0x89, 0x50, 0x4e, 0x47))),
          "image/jpeg" = identical(raw[1:2], as.raw(c(0xff, 0xd8))),
          "image/gif"  = identical(raw[1:3], as.raw(c(0x47, 0x49, 0x46))),
          "image/webp" = identical(raw[1:4], as.raw(c(0x52, 0x49, 0x46, 0x46))),
          FALSE)
        if (!isTRUE(sig_ok)) { msg(list(ok = FALSE, text = sprintf("%s is not really a %s image (its contents do not match).", nm, ext))); return() }
        b64 <- gsub("\n", "", base64enc::base64encode(raw))
        imgs[[k]] <- list(media_type = unname(mt), data = b64)
        uris[k] <- paste0("data:", mt, ";base64,", b64)
      }

      tz_default <- bos_tz_value(input$time_zone)
      prompt <- zoom_read_prompt(tz_default, Sys.Date(), input$extra %||% "", n_images = length(imgs))
      msg(NULL)
      ans <- tryCatch(
        withProgress(message = "Claude is reading the invite...", value = 0.5, {
          api_manager$call_claude(prompt, max_tokens = 4000,
                                  images = imgs)
        }), error = function(e) e)
      if (inherits(ans, "error")) {
        msg(list(ok = FALSE, text = paste0("Claude could not be reached: ", conditionMessage(ans)))); return()
      }
      txt <- if (is.list(ans)) ans$text else as.character(ans)
      res <- zoom_parse_response(txt, tz_default)
      res$raw_text <- txt; res$image_uri <- uris
      last(res)
      if (!isTRUE(res$ok)) { msg(list(ok = FALSE, text = res$error)); return() }
      msg(list(ok = TRUE, text = "Invite read. Opening Events to Calendar with the details filled in..."))
      hand_off(res)
    })

    output$status <- renderUI({
      m <- msg(); if (is.null(m)) return(NULL)
      div(class = if (isTRUE(m$ok)) "status-success" else "status-error", style = "margin-top: 10px;",
          icon(if (isTRUE(m$ok)) "check-circle" else "exclamation-triangle"), " ", m$text)
    })

    output$preview <- renderUI({
      r <- last()
      if (is.null(r)) return(p(class = "text-muted", "The images appear here after they are read."))
      tagList(lapply(r$image_uri, function(u) tags$img(src = u, style = "max-width: 100%; border: 1px solid #ddd; margin-bottom: 8px;")))
    })

    output$result <- renderUI({
      r <- last()
      if (is.null(r)) return(p(class = "text-muted", "Nothing read yet."))
      if (!isTRUE(r$ok)) return(div(class = "status-error", icon("exclamation-triangle"), " ", r$error))
      i <- r$invite
      row <- function(k, v) tags$tr(tags$th(style = "padding-right: 14px; vertical-align: top;", k), tags$td(v))
      tagList(
        tags$table(
          row("Subject", i$subject),
          row("Date", format(i$date, "%A %d %B %Y")),
          row("Start", paste0(i$start, "  (", i$tz, if (isTRUE(i$tz_from_image)) ", from the image" else ", default", ")")),
          row("Length", paste(i$duration, "minutes")),
          row("To", if (length(i$attendees)) paste(i$attendees, collapse = ", ") else "(none found)"),
          row("Zoom link", if (nzchar(i$zoom_link)) i$zoom_link else "(none found)"),
          row("Meeting ID / passcode", paste(zoom_or(if (nzchar(i$meeting_id)) i$meeting_id, "-"), "/", zoom_or(if (nzchar(i$passcode)) i$passcode, "-")))
        ),
        if (length(r$warnings)) div(class = "status-warning", style = "margin-top: 10px;", icon("exclamation-triangle"),
                                    tags$ul(lapply(r$warnings, tags$li))),
        if (length(i$notes)) p(tags$small(tags$strong("Claude's notes: "), paste(i$notes, collapse = " | ")))
      )
    })

    output$continue_ui <- renderUI({
      r <- last(); if (is.null(r) || !isTRUE(r$ok)) return(NULL)
      actionButton(session$ns("send_again"), "Open in Events to Calendar again", icon = icon("calendar-plus"),
                   class = "btn-success", style = "margin-top: 10px;")
    })
    observeEvent(input$send_again, { r <- last(); if (!is.null(r) && isTRUE(r$ok)) hand_off(r) })

    output$raw_answer <- renderText({ r <- last(); if (is.null(r)) "(nothing yet)" else r$raw_text })
    output$raw_ics <- renderText({
      r <- last()
      if (is.null(r) || !nzchar(zoom_or(r$raw_ics, ""))) "(none)" else gsub("\\\\n", "\n", r$raw_ics)
    })
  })
}
