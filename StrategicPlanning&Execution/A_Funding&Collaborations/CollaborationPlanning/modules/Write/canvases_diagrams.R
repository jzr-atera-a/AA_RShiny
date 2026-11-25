# ---- module ----------------------------------------------
# id:           canvases_diagrams
# name:         Canvases and diagrams
# icon:         shapes
# description:  Business model canvas, logic model, value proposition and a project diagram, drafted by Claude per project
# packages:     shiny
# -----------------------------------------------------------
# Ported from BOS Strategy Canvases (bm_canvas_generate.R, bm_canvas_view.R, de_canvas_generate.R) and
# Project Application (diagram_generator.R, claude_diagrams.R), keyed to project_id. Saved to canvases.

CANVAS_KINDS <- list(
  "Business model canvas" = c("Key partners", "Key activities", "Key resources", "Value propositions", "Customer relationships",
                              "Channels", "Customer segments", "Cost structure", "Revenue streams"),
  "Logic model (theory of change)" = c("Inputs", "Activities", "Outputs", "Outcomes", "Impact"),
  "Value proposition canvas" = c("Customer jobs", "Pains", "Gains", "Products and services", "Pain relievers", "Gain creators"),
  "Project diagram" = "mermaid")

canvases_diagrams_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tags$script(src = "https://cdn.jsdelivr.net/npm/mermaid@10.9.3/dist/mermaid.min.js"),   # loaded from the CDN, only this tab needs it
    tags$script(HTML("Shiny.addCustomMessageHandler('cp-mermaid', function(id){ setTimeout(function(){ try { mermaid.initialize({startOnLoad:false, theme:'neutral'}); mermaid.run({nodes: document.querySelectorAll('#' + id + ' .mermaid')}); } catch(e) { console.log(e); } }, 80); });")),
    card(NULL, layout_columns(col_widths = c(5, 4, 3),
      selectInput(ns("proj"), "Project", NULL, width = "100%"),
      selectInput(ns("kind"), "Canvas", names(CANVAS_KINDS)),
      div(class = "align-bottom", actionButton(ns("gen"), "Draft with Claude", class = "btn-brand", icon = icon("robot"))))),
    textAreaInput(ns("extra"), "Anything Claude should take into account (optional)", rows = 2, width = "100%"),
    uiOutput(ns("status")),
    uiOutput(ns("view")),
    uiOutput(ns("editor")))
}

canvases_diagrams_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    observe({ ch <- project_picker_choices(ctx); updateSelectInput(session, "proj", choices = ch, selected = pick_sel(isolate(input$proj), ch, ctx$handoff$project)) })
    proj <- reactive({ pr <- ctx$data$projects(); pr[pr$project_id == (input$proj %||% ""), , drop = FALSE] })
    saved <- reactive({ c <- ctx$table("canvases")(); c <- c[c$project_id == (input$proj %||% "") & c$kind == input$kind, , drop = FALSE]
                        c[order(c$created_at), , drop = FALSE] })
    current <- reactive({ s <- saved(); if (nrow(s)) s$content[nrow(s)] else "" })
    is_diagram <- reactive(identical(CANVAS_KINDS[[input$kind]], "mermaid"))

    output$status <- renderUI(if (!length(project_picker_choices(ctx))) project_empty_note())
    output$view <- renderUI({
      txt <- current(); if (!nzchar(txt)) return(p(class = "small muted", "Nothing saved for this canvas yet. Press Draft with Claude, or write it below."))
      if (is_diagram()) { session$sendCustomMessage("cp-mermaid", ns("view")); return(card(input$kind, div(class = "mermaid", txt))) }
      boxes <- tryCatch(jsonlite::fromJSON(txt), error = function(e) NULL)
      if (is.null(boxes)) return(note("warn", "The saved canvas could not be read; edit it below."))
      labs <- CANVAS_KINDS[[input$kind]]
      card(input$kind, div(class = "canvas-grid", style = if (length(labs) != 9) sprintf("grid-template-columns:repeat(%d,1fr)", min(length(labs), 6)),
        lapply(labs, function(l) div(class = "canvas-box", tags$b(l), paste(unlist(boxes[[l]] %||% ""), collapse = "\n")))),
        p(class = "small muted", "Version ", nrow(saved()), ", saved ", saved()$created_at[nrow(saved())], " by ", saved()$created_by[nrow(saved())]))
    })
    output$editor <- renderUI({
      txt <- current()
      card("Edit",
        p(class = "small muted", if (is_diagram()) "Mermaid flowchart code (see mermaid.js.org)." else "One line per point inside each box, as JSON."),
        textAreaInput(ns("txt"), NULL, value = if (nzchar(txt) && !is_diagram()) jsonlite::toJSON(jsonlite::fromJSON(txt), pretty = TRUE, auto_unbox = TRUE) else txt,
                      rows = 10, width = "100%"),
        div(class = "btn-row", actionButton(ns("save"), "Save as a new version", class = "btn-ghost"),
            downloadButton(ns("dl"), "Download (.html)", class = "btn-ghost sm")))
    })
    observeEvent(input$gen, {
      r <- proj(); req(nrow(r) > 0); if (!claude_ready()) return(showNotification("No Claude API key is set.", type = "error"))
      p <- ctx$programmes(); pr <- p[p$programme_id == r$programme_id, , drop = FALSE]
      t <- ctx$data$tasks(); t <- t[t$project_id == r$project_id, , drop = FALSE]
      c <- ctx$data$consortium(); c <- c[c$programme_id == r$programme_id & c$status != "declined", , drop = FALSE]
      facts <- paste0("Project: ", r$title, ". Programme: ", pr$programme_name[1] %||% "", " - ", pr$summary[1] %||% "",
                      "\nOur company: ", ctx$settings()$company_profile, "\nPartners: ", paste(c$organisation %|% c$email, collapse = ", "),
                      "\nWork: ", paste(unique(paste(t$work_package, t$task, sep = ": ")), collapse = "; "), "\nNotes: ", input$extra %||% "")
      prompt <- if (is_diagram()) paste0("Draw this project as a Mermaid flowchart (flowchart LR). Show work packages as subgraphs, main tasks as nodes, ",
                                         "and partners linked to what they deliver. Reply with the Mermaid code only, no fences.\n\n", facts)
        else paste0("Fill in a ", input$kind, " for this project. Reply with JSON only: an object whose keys are exactly ",
                    jsonlite::toJSON(CANVAS_KINDS[[input$kind]]), " and whose values are arrays of 2 to 5 short points. Use only these facts:\n\n", facts)
      res <- withProgress(message = "Drafting...", tryCatch(claude_call(prompt, max_tokens = 2500)$text, error = function(e) structure(safe_error_text(e), class = "err")))
      if (inherits(res, "err")) return(showNotification(res, type = "error", duration = 10))
      content <- if (is_diagram()) trimws(gsub("```(mermaid)?", "", res)) else as.character(jsonlite::toJSON(parse_json_loose(res, simplify = FALSE), auto_unbox = TRUE))
      store_append("canvases", data.frame(canvas_id = new_id("cv"), project_id = r$project_id, kind = input$kind, content = content,
                                          created_by = ctx$user(), created_at = now_ts(), stringsAsFactors = FALSE), user = ctx$user())
      ctx$bump(); showNotification("Draft saved as a new version.", type = "message")
    })
    observeEvent(input$save, {
      r <- proj(); req(nrow(r) > 0); txt <- input$txt %||% ""
      if (!is_diagram()) { ok <- tryCatch({ jsonlite::fromJSON(txt); TRUE }, error = function(e) FALSE)
        if (!ok) return(showNotification("That is not valid JSON. Check quotes and commas.", type = "error"))
        txt <- as.character(jsonlite::toJSON(jsonlite::fromJSON(txt, simplifyVector = FALSE), auto_unbox = TRUE)) }
      store_append("canvases", data.frame(canvas_id = new_id("cv"), project_id = r$project_id, kind = input$kind, content = txt,
                                          created_by = ctx$user(), created_at = now_ts(), stringsAsFactors = FALSE), user = ctx$user())
      ctx$bump(); showNotification("Saved.", type = "message")
    })
    output$dl <- downloadHandler(filename = function() paste0(gsub("[^A-Za-z0-9]+", "_", input$kind), ".html"), content = function(file) {
      txt <- current(); title <- paste(proj()$title, "-", input$kind)
      body <- if (is_diagram()) paste0('<pre class="mermaid">', htmltools::htmlEscape(txt), '</pre><script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script><script>mermaid.initialize({startOnLoad:true});</script>')
        else { b <- jsonlite::fromJSON(txt); paste0('<div style="display:grid;grid-template-columns:repeat(3,1fr);gap:8px">',
               paste(vapply(names(b), function(k) paste0('<div style="border:1px solid #cfdde3;border-radius:8px;padding:8px"><b>', htmltools::htmlEscape(k), '</b><ul>',
                     paste0("<li>", htmltools::htmlEscape(unlist(b[[k]])), "</li>", collapse = ""), '</ul></div>'), ""), collapse = ""), '</div>') }
      writeLines(paste0('<!DOCTYPE html><html><head><meta charset="utf-8"><title>', htmltools::htmlEscape(title), '</title></head><body style="font-family:sans-serif"><h2>',
                        htmltools::htmlEscape(title), '</h2>', body, '</body></html>'), file, useBytes = TRUE)
    })
  })
}
