# modules/visualize_mindmap/server.R
#
# Renders the mind map with D3.js directly (a "tidy tree" / collapsible
# tree layout, the same family of algorithm markmap itself uses) rather
# than vis.js's hierarchical layout, which does not reliably prevent
# overlap at deeper levels. D3's tree(nodeSize:) layout is a
# deterministic geometric algorithm - given enough vertical space per
# sibling slot, it MATHEMATICALLY guarantees no two nodes anywhere in
# the tree ever overlap, which is what was actually going wrong before.

visualize_mindmap_server <- function(id, api_manager) {
  moduleServer(id, function(input, output, session) {

    loaded_nodes <- reactiveVal(NULL)  # current_tree_state()$nodes, with level computed

    # ------------------------------------------------------------
    # Category -> Domain -> Topic -> Map Version cascade
    # ------------------------------------------------------------
    viz_taxonomy <- reactive({
      api_manager$state_trigger_mindmap()
      if (!api_manager$bq_authenticated) return(api_manager$empty_mindmap_taxonomy())
      tryCatch(api_manager$bq_get_mindmap_taxonomy(), error = function(e) api_manager$empty_mindmap_taxonomy())
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
        updateSelectInput(session, "viz_map_id", choices = c("(select a topic first)" = ""))
        return()
      }

      tryCatch({
        maps <- api_manager$bq_get_map_ids_for_topic(input$viz_category, input$viz_domain, input$viz_topic)
        if (nrow(maps) == 0) {
          updateSelectInput(session, "viz_map_id", choices = c("(no maps found)" = ""))
        } else {
          labels <- sprintf("%s (%s)", maps$map_title, maps$map_id)
          updateSelectInput(session, "viz_map_id", choices = setNames(maps$map_id, labels))
        }
      }, error = function(e) {
        updateSelectInput(session, "viz_map_id", choices = c("(error loading)" = ""))
      })
    }, ignoreInit = TRUE)

    # ------------------------------------------------------------
    # Build and render the D3 widget from whatever is currently in
    # loaded_nodes() - shared by both "Load Map" and the cross-links
    # toggle, so toggling doesn't require re-querying BigQuery.
    # ------------------------------------------------------------
    render_d3_widget <- function() {
      nodes_df <- loaded_nodes()
      req(nodes_df)

      tree <- build_d3_tree(nodes_df)
      if (is.null(tree)) {
        output$network <- renderUI({
          tags$div(class = "status-error",
                   tags$i(class = "fa fa-times-circle"),
                   " Could not build a tree - the current map does not have exactly one root node.")
        })
        return(invisible(NULL))
      }

      cross_links <- if (isTRUE(input$show_cross_links)) build_d3_cross_links(nodes_df) else list()

      tree_json <- as.character(jsonlite::toJSON(tree, auto_unbox = TRUE, null = "null"))
      cross_links_json <- as.character(jsonlite::toJSON(cross_links, auto_unbox = TRUE))

      # Defensive: a literal "</script" inside any node's content would
      # otherwise prematurely close our <script> tag in the browser's
      # HTML parser. Escaping the slash is a harmless, valid JS string
      # escape that neutralizes this without affecting the JSON value.
      tree_json <- gsub("</script", "<\\/script", tree_json, fixed = TRUE)
      cross_links_json <- gsub("</script", "<\\/script", cross_links_json, fixed = TRUE)

      widget_id <- paste0("mmviz_", as.integer(Sys.time()), "_", sample(1000:9999, 1))
      shiny_input_id <- session$ns("node_selected")

      js <- r"---(
(function() {
  var data = __TREE_JSON__;
  var crossLinks = __CROSSLINKS_JSON__;
  var containerId = "__CONTAINER_ID__";
  var shinyInputId = "__SHINY_INPUT_ID__";

  var container = document.getElementById(containerId);
  if (!container) return;
  container.innerHTML = "";

  var dx = 30;    // vertical spacing between sibling slots
  var dy = 210;   // horizontal spacing between depth levels
  var palette = ["#008A82","#3498db","#9b59b6","#e67e22","#27ae60","#e74c3c","#16a085","#2980b9","#8e44ad","#d35400"];

  var root = d3.hierarchy(data);
  root.x0 = 0;
  root.y0 = 0;

  // Assign a branch color per top-level (depth-1) subtree, propagated
  // down to every descendant, so each major branch reads as one color -
  // same visual language as the markmap reference.
  var colorIdx = 0;
  root.each(function(d) {
    if (d.depth === 0) {
      d.branchColor = "#002C3C";
    } else if (d.depth === 1) {
      d.branchColor = palette[colorIdx % palette.length];
      colorIdx++;
    } else {
      var a = d;
      while (a.depth > 1) a = a.parent;
      d.branchColor = a.branchColor;
    }
  });

  var treeLayout = d3.tree().nodeSize([dx, dy]);

  var svg = d3.select(container).append("svg")
      .style("font", "13px sans-serif")
      .style("user-select", "none")
      .style("display", "block");

  var g = svg.append("g");

  var gLink = g.append("g")
      .attr("fill", "none")
      .attr("stroke-opacity", 0.75)
      .attr("stroke-width", 2);

  var gCrossLink = g.append("g")
      .attr("fill", "none")
      .attr("stroke", "#f39c12")
      .attr("stroke-opacity", 0.65)
      .attr("stroke-width", 1.5)
      .attr("stroke-dasharray", "4,3");

  var gNode = g.append("g")
      .attr("cursor", "pointer");

  var linkGen = d3.linkHorizontal().x(function(d) { return d.y; }).y(function(d) { return d.x; });
  var nodeById = new Map();

  function update(source) {
    var nodes = root.descendants();
    var links = root.links();

    treeLayout(root);

    var left = root, right = root;
    root.eachBefore(function(node) {
      if (node.x < left.x) left = node;
      if (node.x > right.x) right = node;
    });
    var maxDepth = 0;
    root.eachBefore(function(node) { if (node.depth > maxDepth) maxDepth = node.depth; });

    var height = right.x - left.x + dx * 3;
    var width = (maxDepth + 1) * dy + 260;

    svg.attr("viewBox", [-40, left.x - dx * 1.5, width, height]);
    svg.attr("width", width);
    svg.attr("height", Math.max(height, 200));
    container.style.height = Math.min(height, 650) + "px";

    nodeById.clear();
    nodes.forEach(function(d) { nodeById.set(d.data.id, d); });

    // ---- NODES ----
    var node = gNode.selectAll("g.mm-node").data(nodes, function(d) { return d.data.id; });

    var nodeEnter = node.enter().append("g")
        .attr("class", "mm-node")
        .attr("transform", function() {
          return "translate(" + (source.y0 == null ? source.y : source.y0) + "," + (source.x0 == null ? source.x : source.x0) + ")";
        })
        .style("opacity", 0);

    nodeEnter.append("circle")
        .attr("r", 6)
        .attr("fill", function(d) { return d._children ? d.branchColor : "#fff"; })
        .attr("stroke", function(d) { return d.branchColor; })
        .attr("stroke-width", 2.5)
        .on("click", function(event, d) {
          event.stopPropagation();
          if (d.children) { d._children = d.children; d.children = null; }
          else if (d._children) { d.children = d._children; d._children = null; }
          else { return; } // leaf node, nothing to toggle
          update(d);
        });

    nodeEnter.append("text")
        .attr("dy", "0.32em")
        .attr("x", function(d) { return (d.children || d._children) ? -12 : 12; })
        .attr("text-anchor", function(d) { return (d.children || d._children) ? "end" : "start"; })
        .text(function(d) { return d.data.label; })
        .attr("fill", function(d) { return d.depth === 0 ? "#002C3C" : "#2c3e50"; })
        .style("font-weight", function(d) { return d.depth <= 1 ? "700" : "400"; })
        .style("paint-order", "stroke")
        .attr("stroke", "white")
        .attr("stroke-width", 3)
        .on("click", function(event, d) {
          event.stopPropagation();
          if (window.Shiny) Shiny.setInputValue(shinyInputId, d.data.id, {priority: "event"});
        });

    nodeEnter.append("title").text(function(d) {
      return (d.children || d._children) ? "Click circle to collapse/expand" : "";
    });

    var nodeMerge = node.merge(nodeEnter);
    nodeMerge.transition().duration(250)
        .attr("transform", function(d) { return "translate(" + d.y + "," + d.x + ")"; })
        .style("opacity", 1);

    nodeMerge.select("circle")
        .attr("fill", function(d) { return d._children ? d.branchColor : "#fff"; })
        .attr("r", function(d) { return (d._children || d.children) ? 7 : 5; })
        .attr("stroke", function(d) { return d.branchColor; });

    node.exit().transition().duration(250)
        .attr("transform", function() { return "translate(" + source.y + "," + source.x + ")"; })
        .style("opacity", 0)
        .remove();

    // ---- PRIMARY HIERARCHY LINKS ----
    var link = gLink.selectAll("path").data(links, function(d) { return d.target.data.id; });

    var linkEnter = link.enter().append("path")
        .attr("stroke", function(d) { return d.target.branchColor; })
        .attr("d", function() {
          var o = {x: source.x0 == null ? source.x : source.x0, y: source.y0 == null ? source.y : source.y0};
          return linkGen({source: o, target: o});
        });

    link.merge(linkEnter).transition().duration(250).attr("d", linkGen);

    link.exit().transition().duration(250)
        .attr("d", function() {
          var o = {x: source.x, y: source.y};
          return linkGen({source: o, target: o});
        })
        .remove();

    // ---- CROSS-LINKS (only where both endpoints are currently visible) ----
    var visibleCross = crossLinks.filter(function(cl) {
      return nodeById.has(cl.source) && nodeById.has(cl.target);
    });

    var cross = gCrossLink.selectAll("path").data(visibleCross, function(d) { return d.source + "->" + d.target; });
    cross.exit().remove();
    cross.enter().append("path")
      .merge(cross)
        .attr("d", function(d) {
          var s = nodeById.get(d.source), t = nodeById.get(d.target);
          return linkGen({source: {x: s.x, y: s.y}, target: {x: t.x, y: t.y}});
        });

    root.eachBefore(function(d) { d.x0 = d.x; d.y0 = d.y; });
  }

  update(root);

  svg.call(d3.zoom().scaleExtent([0.3, 3]).on("zoom", function(event) {
    g.attr("transform", event.transform);
  }));
})();
)---"

      js <- gsub("__TREE_JSON__", tree_json, js, fixed = TRUE)
      js <- gsub("__CROSSLINKS_JSON__", cross_links_json, js, fixed = TRUE)
      js <- gsub("__CONTAINER_ID__", widget_id, js, fixed = TRUE)
      js <- gsub("__SHINY_INPUT_ID__", shiny_input_id, js, fixed = TRUE)

      output$network <- renderUI({
        tags$div(
          tags$div(id = widget_id, style = "width:100%; overflow:auto; border-radius:8px; background:#fafcfc; min-height:200px;"),
          tags$script(HTML(js))
        )
      })
    }

    # ------------------------------------------------------------
    # Load: query BigQuery, then render
    # ------------------------------------------------------------
    observeEvent(input$load_map, {

      if (!api_manager$bq_authenticated) {
        showNotification("Please authenticate with BigQuery first!", type = "error")
        return()
      }
      if (is.null(input$viz_map_id) || input$viz_map_id == "") {
        showNotification("Please select a map version to load!", type = "warning")
        return()
      }

      output$status <- renderUI({
        tags$div(class = "status-info", tags$i(class = "fa fa-spinner fa-spin"), " Loading map...")
      })

      tryCatch({
        state <- api_manager$get_current_tree_state(input$viz_map_id)

        if (nrow(state$nodes) == 0) {
          output$status <- renderUI({
            tags$div(class = "status-warning", tags$i(class = "fa fa-exclamation-triangle"), " No nodes found for this map")
          })
          return()
        }

        nodes_with_levels <- compute_node_levels(state$nodes)
        loaded_nodes(nodes_with_levels)

        render_d3_widget()

        output$status <- renderUI({
          tags$div(class = "status-success", tags$i(class = "fa fa-check-circle"),
                   sprintf(" Loaded %d node(s)", nrow(state$nodes)))
        })

        output$node_detail <- renderUI({
          tags$div(class = "status-info", "Click a node's label to see its full content here.")
        })

        showNotification("✓ Map loaded!", type = "message")

      }, error = function(e) {
        output$status <- renderUI({
          tags$div(class = "status-error", tags$i(class = "fa fa-times-circle"), " Error: ", e$message)
        })
        showNotification(paste("Error:", e$message), type = "error")
      })
    })

    # Toggle cross-links visibility without a full reload
    observeEvent(input$show_cross_links, {
      req(loaded_nodes())
      render_d3_widget()
    }, ignoreInit = TRUE)

    observeEvent(input$node_selected, {
      req(loaded_nodes())
      nodes_df <- loaded_nodes()

      if (is.null(input$node_selected)) {
        output$node_detail <- renderUI({
          tags$div(class = "status-info", "Click a node's label to see its full content here.")
        })
        return()
      }

      match_idx <- which(nodes_df$node_id == input$node_selected)
      if (length(match_idx) == 0) return()

      node <- nodes_df[match_idx[1], ]
      cross_links <- parse_cross_links(node$cross_links)

      output$node_detail <- renderUI({
        tagList(
          tags$div(class = "viz-card",
            tags$div(class = "chapter-title", node$node_label),
            tags$span(class = "section-tag", sprintf("Level %d", node$level)),
            if (node$parent_node_id != ROOT_MARKER) {
              tags$span(class = "section-tag", sprintf("Parent: %s", node$parent_node_id))
            } else {
              tags$span(class = "section-tag", "ROOT")
            },
            tags$div(class = "details-text", node$node_content),
            if (nrow(cross_links) > 0) {
              tags$div(style = "margin-top: 12px; padding: 8px; background: #fff3cd; border-radius: 6px;",
                       tags$strong("Cross-links: "),
                       tags$ul(lapply(seq_len(nrow(cross_links)), function(i) {
                         tags$li(sprintf("%s (%s)", cross_links$target_node_id[i], cross_links$relationship_label[i]))
                       })))
            } else NULL
          ),
          tags$script(HTML("if (typeof MathJax !== 'undefined') { MathJax.Hub.Queue(['Typeset', MathJax.Hub]); }"))
        )
      })
    })

    output$status <- renderUI({ tags$div() })
    output$network <- renderUI({
      tags$div(class = "status-info", "Select Category, Domain, Topic, and Map Version above, then click 'Load Map'.")
    })
    output$node_detail <- renderUI({ tags$div(class = "status-info", "Load a map above to get started.") })

    session$onSessionEnded(function() {})
  })
}
