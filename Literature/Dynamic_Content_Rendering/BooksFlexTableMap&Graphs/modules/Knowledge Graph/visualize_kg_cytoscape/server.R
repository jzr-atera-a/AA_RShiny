# modules/visualize_kg_cytoscape/server.R
#
# Same underlying data (build_cytoscape_elements()) as the D3 tab, but
# rendered through Cytoscape.js instead - a library purpose-built for
# network graphs, with a more polished built-in interaction model
# (tap-to-select, box-select, etc.) at the cost of a less customizable
# rendering pipeline than hand-rolled D3. Uses Cytoscape core's
# built-in 'cose' force-directed layout only (see global.R for why no
# extra layout extensions are pulled in).

visualize_kg_cytoscape_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    loaded_entities <- reactiveVal(NULL)
    loaded_relationships <- reactiveVal(NULL)

    # ------------------------------------------------------------
    # Category -> Domain -> Topic -> Graph Version cascade
    #
    # Uses observe() rather than observeEvent(input$viz_category, ...) at
    # every level: observeEvent isolates everything in its handler body
    # except the event expression itself, so a read of viz_taxonomy()
    # inside it is NOT a real dependency. That means if a graph is
    # uploaded under a Category/Domain string that happens to already be
    # selected (e.g. reusing a Domain string under a different Category
    # than before), the dropdown's value never changes, the observer never
    # re-fires, and Topic/Graph Version silently keep showing stale data.
    # observe() tracks every reactive read in its body, so it correctly
    # re-cascades whenever EITHER the taxonomy changes OR the relevant
    # parent selection changes.
    # ------------------------------------------------------------
    viz_taxonomy <- reactive({
      api_manager$state_trigger_kg()
      if (!api_manager$bq_authenticated) return(api_manager$empty_kg_taxonomy())
      tryCatch(api_manager$bq_get_kg_taxonomy(), error = function(e) api_manager$empty_kg_taxonomy())
    })

    observe({
      tax <- viz_taxonomy()
      categories <- sort(unique(tax$category[nchar(trimws(tax$category)) > 0]))
      if (length(categories) == 0) {
        updateSelectInput(session, "viz_category", choices = c("(no categories yet)" = ""))
      } else {
        current <- isolate(input$viz_category)
        selected <- if (!is.null(current) && current %in% categories) current else categories[1]
        updateSelectInput(session, "viz_category", choices = setNames(categories, categories), selected = selected)
      }
    })

    observe({
      tax <- viz_taxonomy()
      cat_val <- input$viz_category
      if (is.null(cat_val) || cat_val == "") {
        updateSelectInput(session, "viz_domain", choices = c("(select a category first)" = ""))
        return()
      }
      domains <- sort(unique(tax$domain[tax$category == cat_val & nchar(trimws(tax$domain)) > 0]))
      if (length(domains) == 0) {
        updateSelectInput(session, "viz_domain", choices = c("(no domains found)" = ""))
      } else {
        current <- isolate(input$viz_domain)
        selected <- if (!is.null(current) && current %in% domains) current else domains[1]
        updateSelectInput(session, "viz_domain", choices = setNames(domains, domains), selected = selected)
      }
    })

    observe({
      tax <- viz_taxonomy()
      cat_val <- input$viz_category
      dom_val <- input$viz_domain
      if (is.null(cat_val) || is.null(dom_val) || cat_val == "" || dom_val == "") {
        updateSelectInput(session, "viz_topic", choices = c("(select a domain first)" = ""))
        return()
      }
      topics <- sort(unique(tax$topic[tax$category == cat_val &
                                       tax$domain == dom_val &
                                       nchar(trimws(tax$topic)) > 0]))
      if (length(topics) == 0) {
        updateSelectInput(session, "viz_topic", choices = c("(no topics found)" = ""))
      } else {
        current <- isolate(input$viz_topic)
        selected <- if (!is.null(current) && current %in% topics) current else topics[1]
        updateSelectInput(session, "viz_topic", choices = setNames(topics, topics), selected = selected)
      }
    })

    observe({
      tax <- viz_taxonomy()
      cat_val <- input$viz_category
      dom_val <- input$viz_domain
      top_val <- input$viz_topic
      if (!api_manager$bq_authenticated || is.null(cat_val) || is.null(dom_val) ||
          is.null(top_val) || cat_val == "" || dom_val == "" || top_val == "") {
        updateSelectInput(session, "viz_graph_id", choices = c("(select a topic first)" = ""))
        return()
      }

      tryCatch({
        graphs <- api_manager$bq_get_graph_ids_for_topic(cat_val, dom_val, top_val)
        if (nrow(graphs) == 0) {
          updateSelectInput(session, "viz_graph_id", choices = c("(no graphs found)" = ""))
        } else {
          labels <- sprintf("%s (%s)", graphs$graph_title, graphs$graph_id)
          current <- isolate(input$viz_graph_id)
          choices <- setNames(graphs$graph_id, labels)
          selected <- if (!is.null(current) && current %in% graphs$graph_id) current else graphs$graph_id[1]
          updateSelectInput(session, "viz_graph_id", choices = choices, selected = selected)
        }
      }, error = function(e) {
        updateSelectInput(session, "viz_graph_id", choices = c("(error loading)" = ""))
      })
    })

    # ------------------------------------------------------------
    # Build and render the Cytoscape widget
    # ------------------------------------------------------------
    render_cytoscape_widget <- function() {
      entities_df <- loaded_entities()
      relationships_df <- loaded_relationships()
      req(entities_df)

      elements <- build_cytoscape_elements(entities_df, relationships_df)
      elements_json <- as.character(jsonlite::toJSON(elements, auto_unbox = TRUE, null = "null"))
      elements_json <- gsub("</script", "<\\/script", elements_json, fixed = TRUE)

      widget_id <- paste0("kgcy_", as.integer(Sys.time()), "_", sample(1000:9999, 1))
      shiny_input_id <- session$ns("node_selected")
      show_labels_js <- if (isTRUE(input$show_predicate_labels)) "true" else "false"

      js <- r"---(
(function() {
  var elements = __ELEMENTS_JSON__;
  var containerId = "__CONTAINER_ID__";
  var shinyInputId = "__SHINY_INPUT_ID__";
  var showLabels = __SHOW_LABELS__;

  var container = document.getElementById(containerId);
  if (!container) return;
  container.innerHTML = "";
  container.style.height = "620px";

  var palette = ["#008A82","#3498db","#9b59b6","#e67e22","#27ae60","#e74c3c","#16a085","#2980b9","#8e44ad","#d35400","#2c3e50","#f39c12"];
  var typeColor = new Map();
  var colorIdx = 0;
  elements.forEach(function(el) {
    if (el.data && el.data.type !== undefined && !typeColor.has(el.data.type)) {
      typeColor.set(el.data.type, palette[colorIdx % palette.length]);
      colorIdx++;
    }
  });

  var degree = new Map();
  elements.forEach(function(el) {
    if (el.data && el.data.source === undefined) degree.set(el.data.id, 0);
  });
  elements.forEach(function(el) {
    if (el.data && el.data.source !== undefined) {
      degree.set(el.data.source, (degree.get(el.data.source) || 0) + 1);
      degree.set(el.data.target, (degree.get(el.data.target) || 0) + 1);
    }
  });

  elements.forEach(function(el) {
    if (el.data && el.data.source === undefined) {
      el.data.color = typeColor.get(el.data.type) || "#008A82";
      el.data.nodeSize = 24 + Math.min(36, (degree.get(el.data.id) || 0) * 4);
    }
  });

  var cy = cytoscape({
    container: container,
    elements: elements,
    style: [
      {
        selector: "node",
        style: {
          "background-color": "data(color)",
          "label": "data(label)",
          "width": "data(nodeSize)",
          "height": "data(nodeSize)",
          "font-size": 11,
          "color": "#2c3e50",
          "text-valign": "bottom",
          "text-halign": "center",
          "text-margin-y": 4,
          "text-outline-width": 2,
          "text-outline-color": "#ffffff",
          "border-width": 1.5,
          "border-color": "#ffffff"
        }
      },
      {
        selector: "edge",
        style: {
          "width": 1.5,
          "line-color": "#aaaaaa",
          "target-arrow-color": "#aaaaaa",
          "target-arrow-shape": "triangle",
          "curve-style": "bezier",
          "label": showLabels ? "data(predicate)" : "",
          "font-size": 9,
          "color": "#666666",
          "text-outline-width": 2,
          "text-outline-color": "#ffffff",
          "text-rotation": "autorotate"
        }
      },
      {
        selector: "node:selected",
        style: { "border-width": 3, "border-color": "#002C3C" }
      }
    ],
    layout: {
      name: "cose",
      animate: false,
      nodeRepulsion: 8000,
      idealEdgeLength: 120,
      gravity: 0.3,
      numIter: 1500
    },
    wheelSensitivity: 0.3
  });

  cy.on("tap", "node", function(evt) {
    var d = evt.target.data();
    if (window.Shiny) Shiny.setInputValue(shinyInputId, d.id, {priority: "event"});
  });

  // ---- Legend ----
  var legend = document.createElement("div");
  legend.style.padding = "8px 4px 0 4px";
  legend.style.fontSize = "12px";
  typeColor.forEach(function(color, type) {
    var item = document.createElement("span");
    item.style.display = "inline-block";
    item.style.marginRight = "14px";
    item.style.marginBottom = "4px";
    var dot = document.createElement("span");
    dot.style.display = "inline-block";
    dot.style.width = "10px";
    dot.style.height = "10px";
    dot.style.borderRadius = "50%";
    dot.style.background = color;
    dot.style.marginRight = "4px";
    item.appendChild(dot);
    item.appendChild(document.createTextNode(type));
    legend.appendChild(item);
  });
  container.parentNode.insertBefore(legend, container.nextSibling);
})();
)---"

      js <- gsub("__ELEMENTS_JSON__", elements_json, js, fixed = TRUE)
      js <- gsub("__CONTAINER_ID__", widget_id, js, fixed = TRUE)
      js <- gsub("__SHINY_INPUT_ID__", shiny_input_id, js, fixed = TRUE)
      js <- gsub("__SHOW_LABELS__", show_labels_js, js, fixed = TRUE)

      output$network <- renderUI({
        tags$div(
          tags$div(id = widget_id, style = "width:100%; border-radius:8px; background:#fafcfc;"),
          tags$script(HTML(js))
        )
      })
    }

    observeEvent(input$load_graph, {

      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }
      if (is.null(input$viz_graph_id) || input$viz_graph_id == "") {
        showNotification("Please select a graph version to load!", type = "warning")
        return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Loading graph...")
      })

      tryCatch({
        state <- api_manager$get_current_graph_state(input$viz_graph_id)

        if (nrow(state$entities) == 0) {
          output$status <- renderUI({
            tags$div(class = "status-warning", tags$i(class = "fa fa-exclamation-triangle"), " No entities found for this graph")
          })
          return()
        }

        loaded_entities(state$entities)
        loaded_relationships(state$relationships)

        render_cytoscape_widget()

        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Loaded %d entit(y/ies), %d relationship(s)", nrow(state$entities), nrow(state$relationships)))
        })

        output$node_detail <- renderUI({
          tags$div(class = "status-info", "Click a node to see its full description here.")
        })

        showNotification("✓ Graph loaded!", type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    observeEvent(input$show_predicate_labels, {
      req(loaded_entities())
      render_cytoscape_widget()
    }, ignoreInit = TRUE)

    observeEvent(input$node_selected, {
      req(loaded_entities())
      entities_df <- loaded_entities()
      relationships_df <- loaded_relationships()

      if (is.null(input$node_selected)) {
        output$node_detail <- renderUI({
          tags$div(class = "status-info", "Click a node to see its full description here.")
        })
        return()
      }

      match_idx <- which(entities_df$entity_id == input$node_selected)
      if (length(match_idx) == 0) return()

      ent <- entities_df[match_idx[1], ]
      out_rels <- relationships_df[relationships_df$source_entity_id == ent$entity_id, ]
      in_rels <- relationships_df[relationships_df$target_entity_id == ent$entity_id, ]

      output$node_detail <- renderUI({
        tagList(
          tags$div(class = "viz-card",
            tags$div(class = "chapter-title", ent$entity_label),
            tags$span(class = "section-tag", ent$entity_type),
            tags$div(class = "details-text", ent$entity_description),
            if (nrow(out_rels) > 0) {
              tags$div(style = "margin-top: 12px; padding: 8px; background: #e8f5f4; border-radius: 6px;",
                       tags$strong("Outgoing relationships:"),
                       tags$ul(lapply(seq_len(nrow(out_rels)), function(i) {
                         tags$li(sprintf("--[%s]--> %s", out_rels$predicate[i], out_rels$target_entity_id[i]))
                       })))
            } else NULL,
            if (nrow(in_rels) > 0) {
              tags$div(style = "margin-top: 8px; padding: 8px; background: #fff3cd; border-radius: 6px;",
                       tags$strong("Incoming relationships:"),
                       tags$ul(lapply(seq_len(nrow(in_rels)), function(i) {
                         tags$li(sprintf("%s --[%s]-->", in_rels$source_entity_id[i], in_rels$predicate[i]))
                       })))
            } else NULL
          ),
          tags$script(HTML("if (typeof MathJax !== 'undefined') { MathJax.Hub.Queue(['Typeset', MathJax.Hub]); }"))
        )
      })
    })

    output$status <- renderUI({ tags$div() })
    output$network <- renderUI({
      tags$div(class = "status-info", "Select Category, Domain, Topic, and Graph Version above, then click 'Load Graph'.")
    })
    output$node_detail <- renderUI({ tags$div(class = "status-info", "Load a graph above to get started.") })

    session$onSessionEnded(function() {})
  })
}
