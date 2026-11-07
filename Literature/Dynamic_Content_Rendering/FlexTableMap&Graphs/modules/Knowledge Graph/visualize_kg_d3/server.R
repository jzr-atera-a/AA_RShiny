# modules/visualize_kg_d3/server.R
#
# Renders the knowledge graph with D3's force-directed layout
# (d3-force): nodes repel each other, edges pull connected ones
# together, settling into an organic equilibrium with no hierarchy
# assumption - the standard, correct tool for this shape of data
# (unlike a tree layout, which would be wrong here since a knowledge
# graph has no root).

visualize_kg_d3_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    loaded_entities <- reactiveVal(NULL)
    loaded_relationships <- reactiveVal(NULL)

    # ------------------------------------------------------------
    # Category -> Domain -> Topic -> Graph Version cascade
    # ------------------------------------------------------------
    viz_taxonomy <- reactive({
      api_manager$state_trigger_kg()
      if (!api_manager$bq_authenticated) return(api_manager$empty_kg_taxonomy())
      tryCatch(api_manager$bq_get_kg_taxonomy(), error = function(e) api_manager$empty_kg_taxonomy())
    })

    observeEvent(viz_taxonomy(), {
      tax <- viz_taxonomy()
      categories <- sort(unique(tax$category[nchar(trimws(tax$category)) > 0]))
      if (length(categories) == 0) {
        updateSelectInput(session, "viz_category", choices = c("(no categories yet)" = ""))
      } else {
        current <- isolate(input$viz_category)
        selected <- if (!is.null(current) && current %in% categories) current else categories[1]
        updateSelectInput(session, "viz_category", choices = setNames(categories, categories), selected = selected)
      }
    }, ignoreNULL = FALSE)

    observeEvent(input$viz_category, {
      tax <- viz_taxonomy()
      if (is.null(input$viz_category) || input$viz_category == "") {
        updateSelectInput(session, "viz_domain", choices = c("(select a category first)" = ""))
        return()
      }
      domains <- sort(unique(tax$domain[tax$category == input$viz_category & nchar(trimws(tax$domain)) > 0]))
      if (length(domains) == 0) {
        updateSelectInput(session, "viz_domain", choices = c("(no domains found)" = ""))
      } else {
        updateSelectInput(session, "viz_domain", choices = setNames(domains, domains))
      }
    }, ignoreInit = TRUE)

    observeEvent(input$viz_domain, {
      tax <- viz_taxonomy()
      if (is.null(input$viz_category) || is.null(input$viz_domain) ||
          input$viz_category == "" || input$viz_domain == "") {
        updateSelectInput(session, "viz_topic", choices = c("(select a domain first)" = ""))
        return()
      }
      topics <- sort(unique(tax$topic[tax$category == input$viz_category &
                                       tax$domain == input$viz_domain &
                                       nchar(trimws(tax$topic)) > 0]))
      if (length(topics) == 0) {
        updateSelectInput(session, "viz_topic", choices = c("(no topics found)" = ""))
      } else {
        updateSelectInput(session, "viz_topic", choices = setNames(topics, topics))
      }
    }, ignoreInit = TRUE)

    observeEvent(input$viz_topic, {
      if (!api_manager$bq_authenticated || is.null(input$viz_category) || is.null(input$viz_domain) ||
          is.null(input$viz_topic) || input$viz_category == "" || input$viz_domain == "" ||
          input$viz_topic == "") {
        updateSelectInput(session, "viz_graph_id", choices = c("(select a topic first)" = ""))
        return()
      }

      tryCatch({
        graphs <- api_manager$bq_get_graph_ids_for_topic(input$viz_category, input$viz_domain, input$viz_topic)
        if (nrow(graphs) == 0) {
          updateSelectInput(session, "viz_graph_id", choices = c("(no graphs found)" = ""))
        } else {
          labels <- sprintf("%s (%s)", graphs$graph_title, graphs$graph_id)
          updateSelectInput(session, "viz_graph_id", choices = setNames(graphs$graph_id, labels))
        }
      }, error = function(e) {
        updateSelectInput(session, "viz_graph_id", choices = c("(error loading)" = ""))
      })
    }, ignoreInit = TRUE)

    # ------------------------------------------------------------
    # Build and render the D3 force-directed widget
    # ------------------------------------------------------------
    render_d3_widget <- function() {
      entities_df <- loaded_entities()
      relationships_df <- loaded_relationships()
      req(entities_df)

      graph_data <- build_d3_graph_data(entities_df, relationships_df)

      nodes_json <- as.character(jsonlite::toJSON(graph_data$nodes, auto_unbox = TRUE, null = "null"))
      links_json <- as.character(jsonlite::toJSON(graph_data$links, auto_unbox = TRUE, null = "null"))
      nodes_json <- gsub("</script", "<\\/script", nodes_json, fixed = TRUE)
      links_json <- gsub("</script", "<\\/script", links_json, fixed = TRUE)

      widget_id <- paste0("kgd3_", as.integer(Sys.time()), "_", sample(1000:9999, 1))
      shiny_input_id <- session$ns("node_selected")
      show_labels_js <- if (isTRUE(input$show_predicate_labels)) "true" else "false"

      js <- r"---(
(function() {
  var nodesData = __NODES_JSON__;
  var linksData = __LINKS_JSON__;
  var containerId = "__CONTAINER_ID__";
  var shinyInputId = "__SHINY_INPUT_ID__";
  var showLabels = __SHOW_LABELS__;

  var container = document.getElementById(containerId);
  if (!container) return;
  container.innerHTML = "";

  var width = container.clientWidth || 900;
  var height = 620;
  var palette = ["#008A82","#3498db","#9b59b6","#e67e22","#27ae60","#e74c3c","#16a085","#2980b9","#8e44ad","#d35400","#2c3e50","#f39c12"];

  var typeColor = new Map();
  var colorIdx = 0;
  nodesData.forEach(function(n) {
    if (!typeColor.has(n.type)) { typeColor.set(n.type, palette[colorIdx % palette.length]); colorIdx++; }
  });

  var degree = new Map();
  nodesData.forEach(function(n) { degree.set(n.id, 0); });
  linksData.forEach(function(l) {
    degree.set(l.source, (degree.get(l.source) || 0) + 1);
    degree.set(l.target, (degree.get(l.target) || 0) + 1);
  });
  function radiusFor(d) { return 8 + Math.min(18, (degree.get(d.id) || 0) * 2); }

  var svg = d3.select(container).append("svg")
      .attr("viewBox", [0, 0, width, height])
      .style("width", "100%")
      .style("height", height + "px")
      .style("font", "12px sans-serif")
      .style("user-select", "none");

  var g = svg.append("g");

  svg.call(d3.zoom().scaleExtent([0.2, 4]).on("zoom", function(event) {
    g.attr("transform", event.transform);
  }));

  var linkForce = d3.forceLink(linksData).id(function(d) { return d.id; }).distance(130).strength(0.6);

  var simulation = d3.forceSimulation(nodesData)
      .force("link", linkForce)
      .force("charge", d3.forceManyBody().strength(-320))
      .force("center", d3.forceCenter(width / 2, height / 2))
      .force("collide", d3.forceCollide().radius(function(d) { return radiusFor(d) + 14; }));

  var link = g.append("g")
      .attr("stroke", "#999")
      .attr("stroke-opacity", 0.6)
    .selectAll("line")
    .data(linksData)
    .join("line")
      .attr("stroke-width", 1.5)
      .attr("marker-end", "url(#kg-arrow)");

  svg.append("defs").append("marker")
      .attr("id", "kg-arrow")
      .attr("viewBox", "0 -5 10 10")
      .attr("refX", 22)
      .attr("refY", 0)
      .attr("markerWidth", 6)
      .attr("markerHeight", 6)
      .attr("orient", "auto")
    .append("path")
      .attr("d", "M0,-5L10,0L0,5")
      .attr("fill", "#999");

  var linkLabel = g.append("g")
    .selectAll("text")
    .data(showLabels ? linksData : [])
    .join("text")
      .text(function(d) { return d.predicate; })
      .attr("fill", "#666")
      .attr("font-size", 10)
      .style("paint-order", "stroke")
      .attr("stroke", "white")
      .attr("stroke-width", 3);

  var node = g.append("g")
    .selectAll("circle")
    .data(nodesData)
    .join("circle")
      .attr("r", radiusFor)
      .attr("fill", function(d) { return typeColor.get(d.type); })
      .attr("stroke", "#fff")
      .attr("stroke-width", 1.5)
      .attr("cursor", "pointer")
      .on("click", function(event, d) {
        event.stopPropagation();
        if (window.Shiny) Shiny.setInputValue(shinyInputId, d.id, {priority: "event"});
      })
      .call(d3.drag()
        .on("start", function(event, d) {
          if (!event.active) simulation.alphaTarget(0.3).restart();
          d.fx = d.x; d.fy = d.y;
        })
        .on("drag", function(event, d) { d.fx = event.x; d.fy = event.y; })
        .on("end", function(event, d) {
          if (!event.active) simulation.alphaTarget(0);
          d.fx = null; d.fy = null;
        }));

  node.append("title").text(function(d) { return d.label + " (" + d.type + ")"; });

  var label = g.append("g")
    .selectAll("text")
    .data(nodesData)
    .join("text")
      .text(function(d) { return d.label; })
      .attr("font-size", 11)
      .attr("dx", function(d) { return radiusFor(d) + 4; })
      .attr("dy", 4)
      .attr("fill", "#2c3e50")
      .style("paint-order", "stroke")
      .attr("stroke", "white")
      .attr("stroke-width", 3)
      .attr("pointer-events", "none");

  simulation.on("tick", function() {
    link
      .attr("x1", function(d) { return d.source.x; })
      .attr("y1", function(d) { return d.source.y; })
      .attr("x2", function(d) { return d.target.x; })
      .attr("y2", function(d) { return d.target.y; });

    linkLabel
      .attr("x", function(d) { return (d.source.x + d.target.x) / 2; })
      .attr("y", function(d) { return (d.source.y + d.target.y) / 2; });

    node
      .attr("cx", function(d) { return d.x; })
      .attr("cy", function(d) { return d.y; });

    label
      .attr("x", function(d) { return d.x; })
      .attr("y", function(d) { return d.y; });
  });

  // ---- Legend ----
  var legend = d3.select(container).append("div")
      .style("padding", "8px 4px 0 4px")
      .style("font-size", "12px");
  typeColor.forEach(function(color, type) {
    var item = legend.append("span")
        .style("display", "inline-block")
        .style("margin-right", "14px")
        .style("margin-bottom", "4px");
    item.append("span")
        .style("display", "inline-block")
        .style("width", "10px")
        .style("height", "10px")
        .style("border-radius", "50%")
        .style("background", color)
        .style("margin-right", "4px");
    item.append("span").text(type);
  });
})();
)---"

      js <- gsub("__NODES_JSON__", nodes_json, js, fixed = TRUE)
      js <- gsub("__LINKS_JSON__", links_json, js, fixed = TRUE)
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

        render_d3_widget()

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
      render_d3_widget()
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
