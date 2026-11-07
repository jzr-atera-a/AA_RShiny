photo_explorer_server <- function(id, photo_manager, session) {
  moduleServer(id, function(input, output, session) {
    pm <- photo_manager
    ns <- session$ns
    page <- reactiveVal(1)

    LAYOUTS <- c("2x2" = 4L, "3x2" = 6L, "3x3" = 9L)
    valid_layout <- function(x) if (!is.null(x) && x %in% names(LAYOUTS)) x else "2x2"

    # What the photo matrix shows: only changes when the user presses "Ver fotos"
    applied <- reactiveValues(
      country = pm$config$last_country %||% "",
      subfolder = pm$config$last_subfolder %||% "",
      layout = valid_layout(pm$config$grid_layout),
      filter = "all"
    )
    updateRadioButtons(session, "layout", selected = isolate(applied$layout))

    # ----------------------------------------------- photo size (60–100 %)
    # Saved value if there is one; otherwise 80 % inside the RStudio window, 100 % in a browser.
    skip_save <- reactiveVal(FALSE)
    saved_size <- suppressWarnings(as.integer(pm$config$photo_scale %||% NA))
    if (!is.na(saved_size)) {
      updateSliderInput(session, "photoSize", value = max(60, min(100, saved_size)))
    } else {
      observeEvent(session$rootScope()$input$client_is_rstudio, {
        if (isTRUE(session$rootScope()$input$client_is_rstudio)) {
          skip_save(TRUE)
          updateSliderInput(session, "photoSize", value = 80)
        }
      }, once = TRUE)
    }
    observeEvent(input$photoSize, {
      if (isTRUE(skip_save())) { skip_save(FALSE); return() }
      pm$set_preference("photo_scale", as.integer(input$photoSize))
    }, ignoreInit = TRUE)

    # ---------------------------------------------------------- dropdowns
    countries_now <- reactive({
      pm$cfg_trigger()
      cs <- pm$country_summary()
      cs[cs$photos > 0, , drop = FALSE]      # countries with at least one active place
    })

    observe({
      cs <- countries_now()
      if (nrow(cs) == 0) {
        updateSelectInput(session, "country", choices = c("Todavía no hay fotos – pídale al administrador que las escanee" = ""))
        updateSelectInput(session, "subfolder", choices = c(" " = ""))
        return()
      }
      choices <- setNames(cs$country, sprintf("%s   (%s fotos)", cs$country, fmt_int(cs$photos)))
      cur <- isolate(input$country)
      if (is.null(cur) || !(cur %in% cs$country)) cur <- isolate(applied$country)
      if (is.null(cur) || !(cur %in% cs$country)) cur <- cs$country[1]
      updateSelectInput(session, "country", choices = choices, selected = cur)
    })

    observeEvent(list(input$country, pm$cfg_trigger()), {
      req(input$country)
      ss <- pm$subfolder_summary(input$country)
      if (nrow(ss) == 0) { updateSelectInput(session, "subfolder", choices = c(" " = "")); return() }
      choices <- setNames(ss$subfolder, sprintf("%s  (%s fotos)", ss$subfolder, fmt_int(ss$photos)))
      if (nrow(ss) > 1) choices <- c(choices, setNames(ALL_PLACES, "Todos los lugares de este país juntos"))
      cur <- isolate(input$subfolder)
      if (is.null(cur) || !(cur %in% choices)) {
        cur <- if (identical(input$country, isolate(applied$country))) isolate(applied$subfolder) else ""
      }
      if (is.null(cur) || !(cur %in% choices)) cur <- choices[[1]]
      updateSelectInput(session, "subfolder", choices = choices, selected = cur)
    })

    # Clicking a row of the guide table selects that place
    observeEvent(input$goto, updateSelectInput(session, "subfolder", selected = input$goto))

    # ------------------------------------------------- "Ver fotos" button
    observeEvent(input$apply, {
      if (!isTruthy(input$country) || !isTruthy(input$subfolder)) {
        showNotification("Primero elija un país y un lugar.", type = "warning"); return()
      }
      applied$country <- input$country
      applied$subfolder <- input$subfolder
      applied$layout <- valid_layout(input$layout)
      applied$filter <- input$filter %||% "all"
      page(1)
      pm$set_preference("last_country", input$country)
      pm$set_preference("last_subfolder", input$subfolder)
      pm$set_preference("grid_layout", applied$layout)
      updateTabsetPanel(session, "subtabs", selected = "fotos")
      session$sendCustomMessage("collapse-sidebar", list())   # more room, focus on the photos
      session$sendCustomMessage("scroll-top", list())
    })

    # ------------------------------------------ sub-tab 1: info and guide
    country_info <- reactive({
      pm$cfg_trigger(); pm$sel_trigger()
      cs <- pm$country_summary()
      list(all = cs, row = cs[cs$country == (input$country %||% ""), , drop = FALSE])
    })

    place_info <- reactive({
      pm$cfg_trigger(); pm$sel_trigger()
      req(input$country)
      pm$subfolder_summary(input$country)
    })

    output$stats <- renderUI({
      ci <- country_info()
      if (nrow(ci$row) == 0) {
        return(div(class = "stat-row", div(class = "stat-tile",
          div(class = "stat-label", "¡Bienvenido!"),
          div(class = "stat-value", style = "font-size: 24px;", "Todavía no hay fotos para mostrar."),
          div(class = "stat-note", "Pídale al administrador que elija la carpeta de fotos y presione “Escanear”."))))
      }
      r <- ci$row
      lim <- r$country_limit
      pct <- if (r$limit > 0) min(100, round(100 * r$chosen / r$limit)) else 0
      over <- r$chosen > lim
      left <- max(0, r$limit - r$chosen)
      div(
        class = "stat-row",
        div(class = "stat-tile",
            div(class = "stat-label", sprintf("📷 Fotos de %s", r$country)),
            div(class = "stat-value", fmt_int(r$photos)),
            div(class = "stat-note", sprintf("en %s lugar(es)", nrow(isolate(place_info()))))),
        div(class = paste("stat-tile", if (over) "red" else "green"),
            div(class = "stat-label", "✅ Fotos que ya eligió"),
            div(class = "stat-value", r$chosen, tags$small(sprintf(" de %s", lim))),
            div(class = "stat-bar", div(style = sprintf("width:%s%%;", pct))),
            div(class = "stat-note",
                if (over) sprintf("Son %s más de lo permitido – por favor quite algunas.", r$chosen - lim)
                else if (left == 0) "Ya eligió todas las fotos de este país. 🎉"
                else sprintf("Todavía puede elegir %s más.", left))),
        div(class = "stat-tile purple",
            div(class = "stat-label", sprintf("💰 Costo aproximado de %s", r$country)),
            div(class = "stat-value", style = "font-size: 30px;", fmt_money(r$cost, pm$currency())),
            div(class = "stat-note", sprintf("%s por foto · todos los países: %s",
                                             fmt_money(pm$cost(), pm$currency()),
                                             fmt_money(sum(ci$all$cost), pm$currency()))))
      )
    })

    output$suggestBanner <- renderUI({
      ss <- place_info()
      req(nrow(ss) > 0, input$subfolder)
      if (identical(input$subfolder, ALL_PLACES)) {
        return(div(class = "suggest-banner", HTML(sprintf(
          "Verá <b>las %s fotos</b> de %s. En la tabla de la derecha está cuántas le sugerimos por lugar.",
          fmt_int(sum(ss$photos)), htmltools::htmlEscape(input$country)))))
      }
      r <- ss[ss$subfolder == input$subfolder, , drop = FALSE]
      req(nrow(r) == 1)
      status <- if (r$chosen >= r$suggested && r$suggested > 0) " ✅" else ""
      extra <- if (isTRUE(r$special)) sprintf(" (museos, galerías y vuelos: máximo recomendado %s)", r$cap) else ""
      div(class = "suggest-banner", HTML(sprintf(
        "<b>%s</b> tiene %s fotos. Le sugerimos elegir unas <b>%s</b>%s. Lleva <b>%s</b>.%s",
        htmltools::htmlEscape(r$subfolder), fmt_int(r$photos), r$suggested, extra, r$chosen, status)))
    })

    output$placeGuide <- renderUI({
      ss <- place_info()
      if (nrow(ss) == 0) return(p("Primero elija un país."))
      rows <- lapply(seq_len(nrow(ss)), function(i) {
        done <- ss$chosen[i] >= ss$suggested[i] && ss$suggested[i] > 0
        tags$tr(
          class = paste("goto-row", if (identical(ss$subfolder[i], input$subfolder)) "current"),
          `data-value` = ss$subfolder[i],
          tags$td(ss$subfolder[i], if (isTRUE(ss$special[i])) span(class = "special-tag", "🏛")),
          tags$td(class = "num", fmt_int(ss$photos[i])),
          tags$td(class = "num", tags$b(ss$suggested[i])),
          tags$td(class = "num", ss$chosen[i]),
          tags$td(if (done) "✅" else if (ss$chosen[i] > 0) "⏳" else "")
        )
      })
      ci <- isolate(country_info())
      tagList(
        tags$table(
          class = "place-table", `data-input` = ns("goto"),
          tags$thead(tags$tr(tags$th("Lugar"), tags$th(class = "num", "Fotos"),
                             tags$th(class = "num", "Sugeridas"), tags$th(class = "num", "Elegidas"), tags$th(""))),
          tags$tbody(rows)
        ),
        p(style = "font-size: 15px; color: #5a6475; margin-top: 8px;",
          sprintf("Las sugerencias reparten el límite de %s fotos según cuántas fotos hay en cada lugar (🏛 museos, galerías y vuelos: máximo %s). Haga clic en un renglón para elegir ese lugar.",
                  if (nrow(ci$row)) ci$row$country_limit else pm$limit(), pm$special_cap()))
      )
    })

    # --------------------------------------------- sub-tab 2: the matrix
    per_page <- reactive(LAYOUTS[[valid_layout(applied$layout)]])

    photo_list <- reactive({
      pm$cfg_trigger()
      req(nzchar(applied$country), nzchar(applied$subfolder))
      df <- pm$photos_in(applied$country, applied$subfolder)
      if (!identical(applied$filter, "all")) {
        sel <- isolate(pm$selected_paths())
        df <- if (identical(applied$filter, "chosen")) df[df$rel_path %in% sel, , drop = FALSE]
              else df[!(df$rel_path %in% sel), , drop = FALSE]
      }
      df
    })

    n_pages <- reactive(max(1L, ceiling(nrow(photo_list()) / per_page())))

    page_photos <- reactive({
      df <- photo_list()
      p <- min(page(), n_pages())
      if (nrow(df) == 0) return(df)
      idx <- ((p - 1) * per_page() + 1):min(p * per_page(), nrow(df))
      df[idx, , drop = FALSE]
    })

    # The only information above the matrix: chosen vs recommended for this place
    output$matrixHeader <- renderUI({
      pm$cfg_trigger(); pm$sel_trigger()
      if (!nzchar(applied$country) || !nzchar(applied$subfolder)) return(NULL)
      ss <- pm$subfolder_summary(applied$country)
      if (identical(applied$subfolder, ALL_PLACES)) {
        place <- sprintf("%s – todos los lugares", applied$country)
        chosen <- sum(ss$chosen); sug <- sum(ss$suggested)
      } else {
        r <- ss[ss$subfolder == applied$subfolder, , drop = FALSE]
        if (nrow(r) == 0) return(NULL)
        place <- sprintf("%s – %s", applied$country, applied$subfolder)
        chosen <- r$chosen; sug <- r$suggested
      }
      pct <- if (sug > 0) min(100, round(100 * chosen / sug)) else 100
      div(class = paste("matrix-header", if (chosen >= sug && sug > 0) "done"),
          span(class = "mh-place", place),
          span(class = "mh-count", HTML(sprintf("Elegidas <b>%s</b> de <b>%s</b> recomendadas%s",
                                                chosen, sug, if (chosen >= sug && sug > 0) " ✅" else ""))),
          span(class = "mh-bar", span(style = sprintf("width:%s%%;", pct))))
    })

    output$grid <- renderUI({
      if (!nzchar(applied$country) || !nzchar(applied$subfolder)) {
        return(div(class = "empty-state",
                   HTML("Elija el país y el lugar en la pestaña <b>1. Elegir viaje</b> y presione <b>Ver fotos</b>.")))
      }
      df <- page_photos()
      all_df <- photo_list()
      if (nrow(df) == 0) {
        msg <- if (identical(applied$filter, "chosen")) "Todavía no ha elegido fotos de aquí."
               else if (identical(applied$filter, "not")) "Ya eligió todas las fotos de aquí."
               else if (!identical(applied$subfolder, ALL_PLACES) && !pm$is_active(applied$country, applied$subfolder))
                 "Este lugar ya no está disponible. Elija otro en la pestaña 1. Elegir viaje."
               else "No hay fotos en este lugar."
        return(div(class = "empty-state", msg))
      }
      sel <- isolate(pm$selected_paths())
      start <- (min(page(), n_pages()) - 1) * per_page()
      urls <- withProgress(message = "Preparando las fotos…", value = 0, {
        vapply(seq_len(nrow(df)), function(i) {
          incProgress(1 / nrow(df))
          pm$image_url(df$rel_path[i], "thumb")
        }, character(1))
      })
      tiles <- lapply(seq_len(nrow(df)), function(i) {
        photo_tile(df$photo_id[i], urls[i],
                   caption = sprintf("Foto %s de %s", start + i, nrow(all_df)),
                   selected = df$rel_path[i] %in% sel,
                   sub_caption = if (identical(applied$subfolder, ALL_PLACES)) df$subfolder[i] else df$file_name[i])
      })
      photo_grid(tiles, applied$layout, ns("toggle"), ns("zoom"))
    })

    output$pager <- renderUI({
      req(nzchar(applied$country), nrow(photo_list()) > 0)
      np <- n_pages(); p <- min(page(), np)
      div(class = "pager",
          actionButton(ns("prev"), HTML("&#9664; Anterior"), class = "btn-primary",
                       disabled = if (p <= 1) "disabled" else NULL),
          span(class = "pager-label", sprintf("Página %s de %s", p, np)),
          actionButton(ns("nxt"), HTML("Siguiente &#9654;"), class = "btn-primary",
                       disabled = if (p >= np) "disabled" else NULL))
    })

    observeEvent(input$prev, { if (page() > 1) { page(page() - 1); session$sendCustomMessage("scroll-top", list()) } })
    observeEvent(input$nxt, { if (page() < n_pages()) { page(page() + 1); session$sendCustomMessage("scroll-top", list()) } })

    # ---------------------------------------------------- ticking photos
    observeEvent(input$toggle, handle_photo_toggle(pm, input$toggle$id, session))

    zoom <- setup_zoom(input, output, session, pm)
    observeEvent(input$zoom, zoom$open(input$zoom$id, isolate(photo_list()$photo_id)))
  })
}
