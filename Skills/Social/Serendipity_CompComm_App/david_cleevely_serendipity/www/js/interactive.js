/* ============================================================
   Serendipity — David Cleevely
   SerendipityViz — shared D3 v7 component library
   One generic implementation per chart type; every chapter module
   calls these with its own data, so all interactivity here is
   maintained in a single place (mirrors the reuse of global.css).
   ============================================================ */

window.SerendipityViz = (function () {
  "use strict";

  var GOLD = "#E8A020", GOLD_L = "#F5C842", NAVY = "#0D1117",
      TEAL = "#1e5a5a", NAVY2 = "#1a3a4a", SLATE = "#546e7a",
      GREEN = "#27ae60", RED = "#e74c3c", BLUE = "#3498db";

  var _sims = {};   // containerId -> live force simulation (for slider control)
  var _tip  = null; // shared tooltip element

  function tooltip() {
    if (_tip) return _tip;
    _tip = d3.select("body").append("div").attr("class", "d3-tooltip");
    return _tip;
  }
  function showTip(html, event) {
    tooltip().style("opacity", 1).html(html)
      .style("left", (event.pageX + 14) + "px")
      .style("top",  (event.pageY - 10) + "px");
  }
  function hideTip() { if (_tip) _tip.style("opacity", 0); }

  function base(containerId, vbW, vbH) {
    var el = document.getElementById(containerId);
    if (!el) return null;
    el.innerHTML = "";
    return d3.select(el).append("svg")
      .attr("viewBox", "0 0 " + vbW + " " + vbH)
      .attr("preserveAspectRatio", "xMidYMid meet")
      .style("width", "100%").style("height", "100%")
      .style("font-family", "Nunito, sans-serif");
  }

  function drag(sim) {
    function started(e, d) { if (!e.active) sim.alphaTarget(0.25).restart(); d.fx = d.x; d.fy = d.y; }
    function dragged(e, d) { d.fx = e.x; d.fy = e.y; }
    function ended(e, d)   { if (!e.active) sim.alphaTarget(0); d.fx = null; d.fy = null; }
    return d3.drag().on("start", started).on("drag", dragged).on("end", ended);
  }

  /* ── 1. Force-directed network graph ────────────────────────
     nodes: [{id, label, r, color, group, tooltip}]
     links: [{source, target, weak(bool)}]
     opts:  {width, height, charge, linkDistance, chaosKey}
     chaosKey: if set, registers sim under that key for updateChaos() */
  function forceNetwork(containerId, nodes, links, opts) {
    opts = opts || {};
    var W = opts.width || 700, H = opts.height || 420;
    var svg = base(containerId, W, H);
    if (!svg) return;

    var sim = d3.forceSimulation(nodes)
      .force("link", d3.forceLink(links).id(function (d) { return d.id; })
        .distance(opts.linkDistance || 85)
        .strength(function (l) { return l.weak ? 0.12 : 0.55; }))
      .force("charge", d3.forceManyBody().strength(opts.charge || -230))
      .force("center", d3.forceCenter(W / 2, H / 2))
      .force("collide", d3.forceCollide().radius(function (d) { return (d.r || 15) + 8; }));

    var link = svg.append("g").selectAll("line").data(links).join("line")
      .attr("stroke", function (l) { return l.weak ? "rgba(232,160,32,0.38)" : GOLD; })
      .attr("stroke-width", function (l) { return l.weak ? 1.3 : 2.4; })
      .attr("stroke-dasharray", function (l) { return l.weak ? "4,3" : null; });

    var node = svg.append("g").selectAll("g").data(nodes).join("g")
      .attr("cursor", "pointer")
      .call(drag(sim));

    node.append("circle")
      .attr("r", function (d) { return d.r || 15; })
      .attr("fill", function (d) { return d.color || TEAL; })
      .attr("stroke", "#fff").attr("stroke-width", 2)
      .on("mouseover", function (e, d) { showTip("<b>" + d.label + "</b>" + (d.tooltip ? "<br>" + d.tooltip : ""), e); })
      .on("mousemove", function (e) { showTip(tooltip().html(), e); })
      .on("mouseout", hideTip);

    node.append("text")
      .text(function (d) { return d.label; })
      .attr("text-anchor", "middle")
      .attr("dy", function (d) { return (d.r || 15) + 13; })
      .attr("font-size", 10).attr("font-weight", 700)
      .attr("fill", NAVY);

    sim.on("tick", function () {
      link.attr("x1", function (d) { return d.source.x; }).attr("y1", function (d) { return d.source.y; })
          .attr("x2", function (d) { return d.target.x; }).attr("y2", function (d) { return d.target.y; });
      node.attr("transform", function (d) { return "translate(" + d.x + "," + d.y + ")"; });
    });

    if (opts.registerAs) _sims[opts.registerAs] = { sim: sim, W: W, H: H, nodes: nodes, link: link, node: node };
    return sim;
  }

  /* Toggle emphasis of weak ties on a network registered via opts.registerAs */
  function toggleWeakTies(key, emphasise) {
    var rec = _sims[key];
    if (!rec) return;
    rec.link
      .attr("stroke-width", function (l) {
        if (!l.weak) return 2.4;
        return emphasise ? 3.2 : 1.3;
      })
      .attr("stroke", function (l) {
        if (!l.weak) return emphasise ? "rgba(232,160,32,0.25)" : GOLD;
        return emphasise ? GOLD : "rgba(232,160,32,0.38)";
      })
      .attr("stroke-dasharray", function (l) { return l.weak ? null : (emphasise ? "3,3" : null); });
  }

  /* Rebind a registered forceNetwork's forces to a 0(order)-100(chaos) slider value */
  function updateChaos(key, value) {
    var rec = _sims[key];
    if (!rec) return;
    var t = value / 100; // 0 = rigid order, 1 = full chaos
    rec.sim.force("charge").strength(-120 - t * 260);
    rec.sim.force("link").strength(function (l) { return l.weak ? 0.5 - t * 0.4 : 0.85 - t * 0.55; });
    rec.sim.alpha(0.7).restart();
    var readout = document.getElementById(key + "-readout");
    if (readout) {
      var label = t < 0.28 ? "Rigid order — efficient, but brittle"
                 : t > 0.72 ? "Pure chaos — no structure to build on"
                 : "The edge of chaos — structured enough to connect, loose enough to surprise";
      readout.textContent = label;
    }
  }

  /* ── 2. Interactive horizontal timeline (click to reveal detail) ──
     items: [{year, title, detail}] */
  function timeline(containerId, items) {
    var el = document.getElementById(containerId);
    if (!el) return;
    el.innerHTML = "";
    var track = document.createElement("div"); track.className = "itl-track";
    var detail = document.createElement("div"); detail.className = "itl-detail";

    function select(i) {
      Array.prototype.forEach.call(track.children, function (c, ix) {
        c.classList.toggle("active", ix === i);
      });
      detail.innerHTML = "<b>" + items[i].year + " — " + items[i].title + ".</b> " + items[i].detail;
    }
    items.forEach(function (it, i) {
      var n = document.createElement("div");
      n.className = "itl-node";
      n.innerHTML = '<div class="itl-year">' + it.year + '</div><div class="itl-title">' + it.title + '</div>';
      n.addEventListener("click", function () { select(i); });
      track.appendChild(n);
    });
    el.appendChild(track); el.appendChild(detail);
    select(0);
  }

  /* ── 3. Bar chart with tooltips ─────────────────────────────
     data: [{label, value, color}] */
  function barChart(containerId, data, opts) {
    opts = opts || {};
    var W = opts.width || 640, H = opts.height || 320;
    var margin = { top: 20, right: 20, bottom: 60, left: 50 };
    var svg = base(containerId, W, H);
    if (!svg) return;
    var iw = W - margin.left - margin.right, ih = H - margin.top - margin.bottom;
    var g = svg.append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    var x = d3.scaleBand().domain(data.map(function (d) { return d.label; })).range([0, iw]).padding(0.35);
    var y = d3.scaleLinear().domain([0, d3.max(data, function (d) { return d.value; }) * 1.15]).range([ih, 0]);

    g.append("g").attr("transform", "translate(0," + ih + ")")
      .call(d3.axisBottom(x).tickSize(0)).selectAll("text")
      .attr("font-size", 10).attr("fill", SLATE)
      .attr("transform", "rotate(-18)").style("text-anchor", "end");
    g.selectAll(".domain,.tick line").attr("stroke", "#e0e0e0");
    g.append("g").call(d3.axisLeft(y).ticks(5)).selectAll("text").attr("font-size", 10).attr("fill", SLATE);
    g.selectAll(".domain,.tick line").attr("stroke", "#e0e0e0");

    g.selectAll("rect").data(data).join("rect")
      .attr("x", function (d) { return x(d.label); })
      .attr("width", x.bandwidth())
      .attr("y", ih).attr("height", 0)
      .attr("rx", 5)
      .attr("fill", function (d) { return d.color || GOLD; })
      .on("mouseover", function (e, d) { showTip("<b>" + d.label + "</b><br>" + d.value + (opts.unit || ""), e); })
      .on("mousemove", function (e) { showTip(tooltip().html(), e); })
      .on("mouseout", hideTip)
      .transition().duration(650)
      .attr("y", function (d) { return y(d.value); })
      .attr("height", function (d) { return ih - y(d.value); });
  }

  /* ── 4. Gauge / slider-driven dial ──────────────────────────
     opts: {min,max,startValue,leftLabel,rightLabel,onUpdate(value)} */
  function gaugeDial(containerId, opts) {
    opts = opts || {};
    var W = opts.width || 640, H = opts.height || 170;
    var svg = base(containerId, W, H);
    if (!svg) return;
    var cx = W / 2, cy = H - 20, r = Math.min(W / 2 - 30, 210);

    var arcBg = d3.arc().innerRadius(r - 18).outerRadius(r).startAngle(-Math.PI / 2).endAngle(Math.PI / 2);
    svg.append("path").attr("d", arcBg).attr("transform", "translate(" + cx + "," + cy + ")").attr("fill", "#eef1f4");

    var scale = d3.scaleLinear().domain([opts.min || 0, opts.max || 100]).range([-Math.PI / 2, Math.PI / 2]);
    var needleGroup = svg.append("g").attr("transform", "translate(" + cx + "," + cy + ")");
    var arcFill = d3.arc().innerRadius(r - 18).outerRadius(r).startAngle(-Math.PI / 2);

    var fillPath = svg.append("path").attr("transform", "translate(" + cx + "," + cy + ")")
      .attr("fill", "url(#gaugeGrad)");

    var defs = svg.append("defs");
    var grad = defs.append("linearGradient").attr("id", "gaugeGrad").attr("x1", "0%").attr("x2", "100%");
    grad.append("stop").attr("offset", "0%").attr("stop-color", TEAL);
    grad.append("stop").attr("offset", "100%").attr("stop-color", GOLD);

    var needle = needleGroup.append("line")
      .attr("x1", 0).attr("y1", 0).attr("y2", -(r - 8))
      .attr("stroke", NAVY).attr("stroke-width", 3).attr("stroke-linecap", "round");
    needleGroup.append("circle").attr("r", 6).attr("fill", NAVY);

    svg.append("text").attr("x", cx - r + 4).attr("y", cy + 14).attr("font-size", 10)
      .attr("fill", SLATE).attr("font-weight", 700).text(opts.leftLabel || "");
    svg.append("text").attr("x", cx + r - 4).attr("y", cy + 14).attr("font-size", 10)
      .attr("text-anchor", "end").attr("fill", SLATE).attr("font-weight", 700).text(opts.rightLabel || "");

    function update(v) {
      var ang = scale(v);
      fillPath.attr("d", arcFill.endAngle(ang));
      needle.transition().duration(250).attr("transform", "rotate(" + (ang * 180 / Math.PI) + ")");
      if (opts.onUpdate) opts.onUpdate(v);
    }
    update(opts.startValue != null ? opts.startValue : (opts.min || 0));
    return { update: update };
  }

  /* ── 5. Quadrant scatter (click points for detail) ─────────
     data: [{label, x, y, r, color, detail}] axes 0-100 */
  function quadrantScatter(containerId, data, opts) {
    opts = opts || {};
    var W = opts.width || 640, H = opts.height || 420;
    var margin = { top: 20, right: 20, bottom: 40, left: 40 };
    var svg = base(containerId, W, H);
    if (!svg) return;
    var iw = W - margin.left - margin.right, ih = H - margin.top - margin.bottom;
    var g = svg.append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    var x = d3.scaleLinear().domain([0, 100]).range([0, iw]);
    var y = d3.scaleLinear().domain([0, 100]).range([ih, 0]);

    g.append("line").attr("x1", iw / 2).attr("x2", iw / 2).attr("y1", 0).attr("y2", ih).attr("stroke", "#e3e8ee");
    g.append("line").attr("x1", 0).attr("x2", iw).attr("y1", ih / 2).attr("y2", ih / 2).attr("stroke", "#e3e8ee");

    if (opts.quadrantLabels) {
      var ql = opts.quadrantLabels; // [topLeft, topRight, bottomLeft, bottomRight]
      g.append("text").attr("x", 6).attr("y", 14).attr("class", "quadrant-label").text(ql[0]);
      g.append("text").attr("x", iw - 6).attr("y", 14).attr("text-anchor", "end").attr("class", "quadrant-label").text(ql[1]);
      g.append("text").attr("x", 6).attr("y", ih - 8).attr("class", "quadrant-label").text(ql[2]);
      g.append("text").attr("x", iw - 6).attr("y", ih - 8).attr("text-anchor", "end").attr("class", "quadrant-label").text(ql[3]);
    }

    var detailBox = document.getElementById(containerId + "-detail");

    g.selectAll("circle").data(data).join("circle")
      .attr("cx", function (d) { return x(d.x); })
      .attr("cy", function (d) { return y(d.y); })
      .attr("r", function (d) { return d.r || 9; })
      .attr("fill", function (d) { return d.color || GOLD; })
      .attr("stroke", "#fff").attr("stroke-width", 1.5)
      .attr("cursor", "pointer")
      .on("mouseover", function (e, d) { showTip("<b>" + d.label + "</b>", e); })
      .on("mousemove", function (e) { showTip(tooltip().html(), e); })
      .on("mouseout", hideTip)
      .on("click", function (e, d) {
        if (detailBox) detailBox.innerHTML = "<b>" + d.label + ".</b> " + (d.detail || "");
      });

    g.selectAll("text.pt-label").data(data).join("text").attr("class", "pt-label")
      .attr("x", function (d) { return x(d.x); }).attr("y", function (d) { return y(d.y) - (d.r || 9) - 5; })
      .attr("text-anchor", "middle").attr("font-size", 9.5).attr("font-weight", 700).attr("fill", NAVY)
      .text(function (d) { return d.label; });

    if (data.length && detailBox) detailBox.innerHTML = "<b>" + data[0].label + ".</b> " + (data[0].detail || "");
  }

  /* ── 6. Radar chart (Prepared Mind self-assessment) ─────────
     axes: [label,...]; values: [0-10,...] */
  function radarChart(containerId, axes, values, opts) {
    opts = opts || {};
    var W = opts.width || 420, H = opts.height || 380;
    var svg = base(containerId, W, H);
    if (!svg) return;
    var cx = W / 2, cy = H / 2 + 6, r = Math.min(W, H) / 2 - 46;
    var n = axes.length;
    var angle = function (i) { return (Math.PI * 2 * i) / n - Math.PI / 2; };
    var rScale = d3.scaleLinear().domain([0, 10]).range([0, r]);

    for (var ring = 2; ring <= 10; ring += 2) {
      var pts = d3.range(n).map(function (i) {
        var rr = rScale(ring);
        return [cx + rr * Math.cos(angle(i)), cy + rr * Math.sin(angle(i))];
      });
      svg.append("polygon").attr("points", pts.map(function (p) { return p.join(","); }).join(" "))
        .attr("fill", "none").attr("stroke", "#eef1f4").attr("stroke-width", 1);
    }
    d3.range(n).forEach(function (i) {
      svg.append("line").attr("x1", cx).attr("y1", cy)
        .attr("x2", cx + r * Math.cos(angle(i))).attr("y2", cy + r * Math.sin(angle(i)))
        .attr("stroke", "#eef1f4");
      var lx = cx + (r + 26) * Math.cos(angle(i)), ly = cy + (r + 26) * Math.sin(angle(i));
      svg.append("text").attr("x", lx).attr("y", ly).attr("text-anchor", "middle")
        .attr("font-size", 10).attr("font-weight", 700).attr("fill", SLATE)
        .text(axes[i]);
    });

    var poly = svg.append("polygon").attr("fill", "rgba(232,160,32,0.28)")
      .attr("stroke", GOLD).attr("stroke-width", 2.2);
    var dots = svg.selectAll("circle.rdot").data(values).join("circle").attr("class", "rdot")
      .attr("r", 4).attr("fill", GOLD_L).attr("stroke", NAVY).attr("stroke-width", 1);

    function render(vals) {
      var pts = vals.map(function (v, i) {
        var rr = rScale(v);
        return [cx + rr * Math.cos(angle(i)), cy + rr * Math.sin(angle(i))];
      });
      poly.attr("points", pts.map(function (p) { return p.join(","); }).join(" "));
      dots.data(pts).attr("cx", function (p) { return p[0]; }).attr("cy", function (p) { return p[1]; });
    }
    render(values);
    return { render: render };
  }

  return {
    forceNetwork: forceNetwork,
    updateChaos: updateChaos,
    timeline: timeline,
    barChart: barChart,
    gaugeDial: gaugeDial,
    quadrantScatter: quadrantScatter,
    radarChart: radarChart
  };
})();
