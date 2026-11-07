my_selection_server <- function(id, photo_manager, session) {
  moduleServer(id, function(input, output, session) {
    pm <- photo_manager
    ns <- session$ns

    summary_data <- reactive({
      pm$cfg_trigger(); pm$sel_trigger()
      pm$country_summary()
    })

    output$summary <- renderUI({
      cs <- summary_data()
      if (nrow(cs) == 0) return(p("Todavía no se han escaneado fotos."))
      rows <- lapply(seq_len(nrow(cs)), function(i) {
        tags$tr(
          tags$td(cs$country[i]),
          tags$td(class = "num", sprintf("%s / %s", cs$chosen[i], cs$country_limit[i])),
          tags$td(class = "num", fmt_money(cs$cost[i], pm$currency()))
        )
      })
      tags$table(
        class = "summary-table",
        tags$thead(tags$tr(tags$th("País"), tags$th(class = "num", "Elegidas"), tags$th(class = "num", "Costo"))),
        tags$tbody(
          rows,
          tags$tr(class = "total",
                  tags$td("TOTAL"),
                  tags$td(class = "num", sum(cs$chosen)),
                  tags$td(class = "num", fmt_money(sum(cs$cost), pm$currency())))
        )
      )
    })

    observe({
      cs <- summary_data()
      if (nrow(cs) == 0) {
        updateSelectInput(session, "country", choices = c(" " = ""))
        return()
      }
      choices <- setNames(cs$country, sprintf("%s   (%s elegidas)", cs$country, cs$chosen))
      cur <- isolate(input$country)
      if (is.null(cur) || !(cur %in% cs$country)) {
        with_sel <- cs$country[cs$chosen > 0]
        cur <- if (length(with_sel)) with_sel[1] else cs$country[1]
      }
      updateSelectInput(session, "country", choices = choices, selected = cur)
    })

    chosen_photos <- reactive({
      pm$cfg_trigger(); pm$sel_trigger()
      req(input$country)
      df <- pm$photos_in(input$country, active_only = FALSE)
      df[df$rel_path %in% pm$selected_paths(), , drop = FALSE]
    })

    output$gallery <- renderUI({
      df <- chosen_photos()
      if (nrow(df) == 0) {
        return(div(class = "empty-state", "Todavía no ha elegido fotos de este país."))
      }
      urls <- withProgress(message = "Preparando las fotos…", value = 0, {
        vapply(seq_len(nrow(df)), function(i) {
          incProgress(1 / nrow(df))
          pm$image_url(df$rel_path[i], "thumb")
        }, character(1))
      })
      places <- unique(df$subfolder)
      tagList(lapply(places, function(pl) {
        idx <- which(df$subfolder == pl)
        tagList(
          div(class = "place-heading", sprintf("%s  ·  %s foto(s)", pl, length(idx))),
          photo_grid(
            lapply(idx, function(i) photo_tile(df$photo_id[i], urls[i], df$file_name[i], TRUE)),
            "3x3", ns("toggle"), ns("zoom")
          )
        )
      }))
    })

    observeEvent(input$toggle, handle_photo_toggle(pm, input$toggle$id, session))

    zoom <- setup_zoom(input, output, session, pm)
    observeEvent(input$zoom, zoom$open(input$zoom$id, isolate(chosen_photos()$photo_id)))

    output$downloadList <- downloadHandler(
      filename = function() paste0("mis_fotos_para_imprimir_", format(Sys.Date(), "%Y%m%d"), ".csv"),
      content = function(file) {
        write_csv_utf8(pm$selection_table_es(), file)
      }
    )
  })
}
