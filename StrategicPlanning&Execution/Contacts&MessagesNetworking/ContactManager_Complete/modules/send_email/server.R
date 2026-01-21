# modules/send_email/server.R
send_email_server <- function(id, contact_manager) {
  moduleServer(id, function(input, output, session) {
    
    # Send email function using curl
    send_email_with_curl <- function(from, to, subject, body, host, port, username, password, attachments = NULL) {
      boundary <- paste0("----=_Part_", as.integer(as.numeric(Sys.time()) * 1000))
      
      email_content <- c(
        paste0("From: ", from),
        paste0("To: ", paste(to, collapse = ", ")),
        paste0("Subject: ", subject),
        "MIME-Version: 1.0"
      )
      
      if (!is.null(attachments) && length(attachments) > 0) {
        email_content <- c(
          email_content,
          paste0('Content-Type: multipart/mixed; boundary="', boundary, '"'),
          "",
          paste0("--", boundary),
          "Content-Type: text/plain; charset=UTF-8",
          "Content-Transfer-Encoding: 7bit",
          "",
          body,
          ""
        )
        
        for (att in attachments) {
          if (file.exists(att$path)) {
            file_raw <- readBin(att$path, "raw", file.info(att$path)$size)
            file_b64 <- base64enc::base64encode(file_raw)
            
            ext <- tolower(tools::file_ext(att$name))
            content_type <- switch(ext,
                                   "pdf" = "application/pdf",
                                   "docx" = "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                                   "xlsx" = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                                   "txt" = "text/plain",
                                   "csv" = "text/csv",
                                   "jpg" = "image/jpeg",
                                   "png" = "image/png",
                                   "application/octet-stream"
            )
            
            email_content <- c(
              email_content,
              paste0("--", boundary),
              paste0('Content-Type: ', content_type, '; name="', att$name, '"'),
              "Content-Transfer-Encoding: base64",
              paste0('Content-Disposition: attachment; filename="', att$name, '"'),
              "",
              file_b64,
              ""
            )
          }
        }
        
        email_content <- c(email_content, paste0("--", boundary, "--"))
        
      } else {
        email_content <- c(
          email_content,
          "Content-Type: text/plain; charset=UTF-8",
          "",
          body
        )
      }
      
      email_file <- tempfile(fileext = ".eml")
      writeLines(email_content, email_file, useBytes = TRUE)
      
      curl_cmd <- sprintf(
        'curl --url "smtps://%s:%s" --ssl-reqd --mail-from "%s" --user "%s:%s" --upload-file "%s"',
        host, port, from, username, password, email_file
      )
      
      for (recipient in to) {
        curl_cmd <- paste0(curl_cmd, sprintf(' --mail-rcpt "%s"', recipient))
      }
      
      result <- system(curl_cmd, intern = TRUE, ignore.stderr = FALSE)
      
      if (file.exists(email_file)) file.remove(email_file)
      
      return(TRUE)
    }
    
    # Send email button
    observeEvent(input$send_email_btn, {
      
      if (!contact_manager$smtp_connected) {
        showNotification("⚠ Open SMTP connection first!", type = "error", duration = 5)
        return()
      }
      
      if (input$email_to == "" || input$email_subject == "" || input$email_body == "") {
        showNotification("Fill To, Subject, Message", type = "error", duration = 5)
        return()
      }
      
      showNotification("📧 Sending...", type = "message", duration = NULL, id = "sending")
      
      tryCatch({
        to_addresses <- trimws(unlist(strsplit(input$email_to, ",")))
        
        attachments <- NULL
        if (!is.null(input$email_attachments)) {
          attachments <- lapply(1:nrow(input$email_attachments), function(i) {
            list(
              path = input$email_attachments$datapath[i],
              name = input$email_attachments$name[i]
            )
          })
        }
        
        send_email_with_curl(
          from = contact_manager$smtp_username,
          to = to_addresses,
          subject = input$email_subject,
          body = input$email_body,
          host = contact_manager$smtp_host,
          port = contact_manager$smtp_port,
          username = contact_manager$smtp_username,
          password = contact_manager$smtp_password,
          attachments = attachments
        )
        
        removeNotification(id = "sending")
        showNotification(paste0("✓ Sent to: ", paste(to_addresses, collapse = ", ")), 
                         type = "message", duration = 5)
        
        # Clear fields
        updateTextInput(session, "email_to", value = "")
        updateTextInput(session, "email_subject", value = "")
        updateTextAreaInput(session, "email_body", value = "")
        
      }, error = function(e) {
        removeNotification(id = "sending")
        showNotification(paste("✗ Failed:", e$message), type = "error", duration = 7)
      })
    })
  })
}
