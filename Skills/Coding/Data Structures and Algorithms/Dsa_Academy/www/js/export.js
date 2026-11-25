/* DSA Academy — diagram export.
 *
 * Adds a "Save" button to every box that shows a diagram (plotly charts, array rows, grids,
 * boards, bit rows…). The server shows the export dialog; this file does the capturing:
 *   PNG / SVG  — html-to-image snapshot of the whole box
 *   PDF        — jsPDF page with a caption and the snapshot
 *   HTML       — self-contained page: snapshot, every animation frame, and interactive charts
 *   GIF        — steps the box's step-player through every step and encodes the frames (gifenc)
 *   JSON       — chart data/layout of every plotly chart in the box plus the explanation text
 * The captured files are sent back to the server, which saves them to Google Drive or a folder.
 */
(function () {
  "use strict";
  var EX = window.DSA_EXPORT = { boxes: {}, seq: 0 };
  var DIAGRAM_SEL = ".js-plotly-plot, .plotly.html-widget, .vrow, .dp-grid, .board, .lane, .bit-row, .viz-canvas";

  function send(id, v) { if (window.Shiny && Shiny.setInputValue) Shiny.setInputValue(id, v, { priority: "event" }); }
  function sleep(ms) { return new Promise(function (r) { setTimeout(r, ms); }); }
  function text(el) { return el ? (el.innerText || el.textContent || "").trim() : ""; }

  // ── Find diagram boxes and add the button ──────────────────────────────────
  function scan() {
    document.querySelectorAll(".box").forEach(function (box) {
      if (box.getAttribute("data-exp")) return;
      var header = box.querySelector(":scope > .box-header");
      var body = box.querySelector(":scope > .box-body");
      if (!header || !body) return;
      if (body.querySelector(".dsa-ace")) { box.setAttribute("data-exp", "no"); return; }
      if (!body.querySelector(DIAGRAM_SEL)) return;          // may gain a diagram later; re-check next scan
      var id = "exbox-" + (++EX.seq);
      box.setAttribute("data-exp", id);
      EX.boxes[id] = box;
      var btn = document.createElement("button");
      btn.className = "dsa-save-btn";
      btn.type = "button";
      btn.title = "Save this diagram (PNG, SVG, PDF, HTML, GIF, JSON) to Google Drive, a folder, or your computer";
      btn.innerHTML = "⤓ Save";
      btn.addEventListener("click", function (e) { e.stopPropagation(); request(id); });
      header.appendChild(btn);
    });
  }

  function context(box) {
    var page = box.closest(".tab-pane[id^='shiny-tab-']");
    var topic = page ? page.id.replace("shiny-tab-", "") : "app";
    var section = "";
    var pane = box.closest(".topic-tabs .tab-pane");
    if (pane) {
      var link = document.querySelector(".topic-tabs a[data-value='" + pane.getAttribute("data-value") + "']");
      section = text(link) || pane.getAttribute("data-value") || "";
    }
    var title = text(box.querySelector(".box-title")) || "diagram";
    var stepper = null, steps = 0, step = 0;
    var nextBtn = box.querySelector(".stepper-btns button[id$='_next']");
    if (nextBtn) {
      stepper = nextBtn.id.replace(/_next$/, "");
      var cnt = text(box.querySelector(".stepper-count"));
      var m = cnt.match(/Step\s+(\d+)\s*\/\s*(\d+)/);
      if (m) { step = Number(m[1]); steps = Number(m[2]); }
    }
    var plots = box.querySelectorAll(".js-plotly-plot").length;
    return { topic: topic, section: section, title: title, stepper: stepper, step: step, steps: steps, plots: plots };
  }

  function request(id) {
    var c = context(EX.boxes[id]);
    c.box = id; c.nonce = Date.now();
    send("dsa_export_req", c);
  }

  // ── Capture helpers ────────────────────────────────────────────────────────
  var CAPTURE_OPTS = {
    backgroundColor: "#ffffff",
    skipFonts: true,
    cacheBust: false,
    filter: function (node) {
      if (!node.classList) return true;
      return !(node.classList.contains("dsa-save-btn") || node.classList.contains("modebar-container") || node.classList.contains("box-tools"));
    }
  };

  function isBusy(box) {
    return document.documentElement.classList.contains("shiny-busy") || box.querySelector(".recalculating") !== null;
  }

  async function waitIdle(box, maxMs) {
    var t0 = Date.now();
    await sleep(60);
    while (isBusy(box) && Date.now() - t0 < (maxMs || 8000)) await sleep(60);
    await sleep(160);                                         // let plotly finish drawing
  }

  async function gotoStep(box, stepper, i) {
    send(stepper + "_goto", { i: i, nonce: Date.now() + Math.random() });
    var t0 = Date.now();
    while (Date.now() - t0 < 8000) {
      var m = text(box.querySelector(".stepper-count")).match(/Step\s+(\d+)/);
      if (m && Number(m[1]) === i) break;
      await sleep(50);
    }
    await waitIdle(box, 8000);
  }

  function b64(dataUrl) { return dataUrl.slice(dataUrl.indexOf(",") + 1); }

  function bytesToB64(u8) {
    var s = "", CH = 0x8000;
    for (var i = 0; i < u8.length; i += CH) s += String.fromCharCode.apply(null, u8.subarray(i, i + CH));
    return btoa(s);
  }

  function explainText(box) {
    return Array.prototype.map.call(box.querySelectorAll(".viz-explain, .callout"), text).filter(Boolean).join("\n\n");
  }

  function plotlyData(box) {
    return Array.prototype.map.call(box.querySelectorAll(".js-plotly-plot"), function (gd) {
      return { data: gd.data || [], layout: gd.layout || {} };
    });
  }

  function escapeHtml(s) {
    return String(s).replace(/[&<>"]/g, function (c) { return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]; });
  }

  function htmlDoc(meta, png, frames, charts, explain) {
    var safeJson = JSON.stringify(charts).replace(/</g, "\\u003c");
    var frameJson = JSON.stringify(frames || []);
    return "<!doctype html>\n<html lang='en'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'>" +
      "<title>" + escapeHtml(meta.title) + "</title>" +
      "<meta name='dsa:topic' content='" + escapeHtml(meta.topic_label || meta.topic) + "'>" +
      "<meta name='dsa:diagram' content='" + escapeHtml(meta.title) + "'>" +
      "<meta name='dsa:created' content='" + new Date().toISOString() + "'>" +
      "<style>body{font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;margin:0;background:#f1f5f9;color:#1e293b}" +
      "header{background:linear-gradient(135deg,#4f46e5,#7c3aed);color:#fff;padding:18px 24px}header h1{margin:0;font-size:20px}" +
      "header p{margin:4px 0 0;opacity:.85;font-size:13px}main{max-width:1200px;margin:0 auto;padding:18px}" +
      "section{background:#fff;border-radius:10px;padding:16px;margin-bottom:16px;box-shadow:0 2px 10px rgba(0,0,0,.08)}" +
      "h2{font-size:15px;margin:0 0 10px}img{max-width:100%;border:1px solid #e2e8f0;border-radius:8px}" +
      "pre{white-space:pre-wrap;background:#f8fafc;border-radius:8px;padding:10px;font-size:13px}" +
      ".ctl{display:flex;gap:8px;align-items:center;margin-bottom:10px}button{border:1px solid #4f46e5;background:#fff;color:#4f46e5;border-radius:6px;padding:5px 12px;cursor:pointer}" +
      ".chart{width:100%;height:420px}</style></head><body>" +
      "<header><h1>" + escapeHtml(meta.title) + "</h1><p>" + escapeHtml((meta.topic_label || meta.topic) + (meta.section ? " · " + meta.section : "") +
      (meta.steps ? " · step " + meta.step + " of " + meta.steps : "") + " · exported " + new Date().toLocaleString()) + "</p></header><main>" +
      (frames && frames.length > 1 ?
        "<section><h2>Step-through (" + frames.length + " frames)</h2><div class='ctl'><button onclick='go(-1)'>◀ Prev</button>" +
        "<button onclick='play()' id='pb'>▶ Play</button><button onclick='go(1)'>Next ▶</button><span id='fc'></span></div><img id='fr' alt='frame'></section>" : "") +
      "<section><h2>Snapshot</h2><img alt='diagram snapshot' src='data:image/png;base64," + png + "'></section>" +
      (explain ? "<section><h2>Explanation</h2><pre>" + escapeHtml(explain) + "</pre></section>" : "") +
      (charts.length ? "<section><h2>Interactive chart" + (charts.length > 1 ? "s" : "") + "</h2><p style='font-size:12px;color:#64748b'>Needs an internet connection to load plotly.js; the snapshot above works offline.</p>" +
        charts.map(function (_, i) { return "<div class='chart' id='c" + i + "'></div>"; }).join("") + "</section>" : "") +
      "</main><script>var FR=" + frameJson + ",k=0,t=null;function show(){var e=document.getElementById('fr');if(!e)return;e.src='data:image/png;base64,'+FR[k];" +
      "document.getElementById('fc').textContent='Frame '+(k+1)+' / '+FR.length;}function go(d){k=(k+d+FR.length)%FR.length;show();}" +
      "function play(){var b=document.getElementById('pb');if(t){clearInterval(t);t=null;b.textContent='▶ Play';}else{t=setInterval(function(){go(1);},900);b.textContent='⏸ Pause';}}if(FR.length)show();</script>" +
      (charts.length ? "<script src='https://cdn.plot.ly/plotly-2.35.2.min.js'></script><script>var CH=" + safeJson + ";if(window.Plotly)CH.forEach(function(c,i){Plotly.newPlot('c'+i,c.data,c.layout,{displaylogo:false,responsive:true});});</script>" : "") +
      "</body></html>";
  }

  function pdfDoc(meta, canvas, explain) {
    var J = window.jspdf.jsPDF;
    var land = canvas.width > canvas.height;
    var pdf = new J({ orientation: land ? "landscape" : "portrait", unit: "pt", format: "a4" });
    var W = pdf.internal.pageSize.getWidth(), H = pdf.internal.pageSize.getHeight(), M = 36;
    pdf.setFont("helvetica", "bold"); pdf.setFontSize(15);
    pdf.text(meta.title.slice(0, 90), M, M + 6);
    pdf.setFont("helvetica", "normal"); pdf.setFontSize(9.5); pdf.setTextColor(100);
    pdf.text(((meta.topic_label || meta.topic) + (meta.section ? " · " + meta.section : "") + (meta.steps ? " · step " + meta.step + " of " + meta.steps : "") +
              " · " + new Date().toLocaleString()).slice(0, 140), M, M + 22);
    var top = M + 34, availH = H - top - M - (explain ? 60 : 0), availW = W - 2 * M;
    var s = Math.min(availW / canvas.width, availH / canvas.height);
    pdf.addImage(canvas.toDataURL("image/jpeg", 0.92), "JPEG", M, top, canvas.width * s, canvas.height * s);
    if (explain) {
      pdf.setTextColor(40); pdf.setFontSize(9);
      var lines = pdf.splitTextToSize(explain.replace(/[^\x20-\x7E\n]/g, " "), availW).slice(0, 6);
      pdf.text(lines, M, top + canvas.height * s + 16);
    }
    return pdf.output("datauristring");
  }

  async function makeGif(box, ctx, opts, collectFrames) {
    var G = window.gifenc, enc = G.GIFEncoder();
    var maxFrames = Math.max(2, Math.min(opts.gif_max || 60, ctx.steps));
    var start = ctx.step || 1, W = 0, H = 0, frames = [];
    var stride = ctx.steps > maxFrames ? ctx.steps / maxFrames : 1;
    var idx = [];
    for (var f = 0; f < maxFrames; f++) idx.push(Math.min(ctx.steps, Math.round(1 + f * stride)));
    idx = idx.filter(function (v, i, a) { return a.indexOf(v) === i; });
    var canvas = document.createElement("canvas"), g = canvas.getContext("2d");
    for (var n = 0; n < idx.length; n++) {
      status("Capturing frame " + (n + 1) + " of " + idx.length + "…");
      await gotoStep(box, ctx.stepper, idx[n]);
      var shot = await window.htmlToImage.toCanvas(box, Object.assign({ pixelRatio: 1 }, CAPTURE_OPTS));
      if (!W) {
        var sc = Math.min(1, 900 / shot.width);
        W = Math.round(shot.width * sc); H = Math.round(shot.height * sc * 1.12);
        canvas.width = W; canvas.height = H;
      }
      g.fillStyle = "#ffffff"; g.fillRect(0, 0, W, H);
      var k = Math.min(W / shot.width, H / shot.height);
      g.drawImage(shot, 0, 0, shot.width * k, shot.height * k);
      var px = g.getImageData(0, 0, W, H).data;
      var pal = G.quantize(px, 256);
      enc.writeFrame(G.applyPalette(px, pal), W, H, { palette: pal, delay: opts.gif_delay || 900 });
      if (collectFrames && frames.length < 40) frames.push(b64(canvas.toDataURL("image/png")));
    }
    enc.finish();
    status("Restoring the diagram…");
    await gotoStep(box, ctx.stepper, start);
    return { gif: bytesToB64(enc.bytes()), frames: frames };
  }

  // ── Run an export (triggered by the server after the dialog) ──────────────
  var statusEl = null;
  function status(msg) {
    if (!statusEl) {
      statusEl = document.createElement("div");
      statusEl.className = "dsa-export-status";
      document.body.appendChild(statusEl);
    }
    statusEl.textContent = msg;
    statusEl.style.display = msg ? "block" : "none";
  }

  function download(name, b64data, mime) {
    var a = document.createElement("a");
    a.href = "data:" + mime + ";base64," + b64data;
    a.download = name;
    document.body.appendChild(a); a.click(); a.remove();
  }

  async function run(m) {
    var box = EX.boxes[m.box];
    if (!box) { send("dsa_export_payload", { nonce: m.nonce, error: "The diagram is no longer on the page." }); return; }
    var ctx = context(box), fmts = m.formats || [], files = [], explain = explainText(box);
    var meta = { title: ctx.title, topic: ctx.topic, topic_label: m.topic_label, section: ctx.section, step: ctx.step, steps: ctx.steps };
    try {
      status("Capturing the diagram…");
      await waitIdle(box, 4000);
      var canvas = await window.htmlToImage.toCanvas(box, Object.assign({ pixelRatio: 2 }, CAPTURE_OPTS));
      var png = b64(canvas.toDataURL("image/png"));
      if (fmts.indexOf("png") >= 0) files.push({ ext: "png", mime: "image/png", data: png });
      if (fmts.indexOf("svg") >= 0) {
        status("Building SVG…");
        var svg = await window.htmlToImage.toSvg(box, CAPTURE_OPTS);
        files.push({ ext: "svg", mime: "image/svg+xml", data: btoa(unescape(encodeURIComponent(decodeURIComponent(svg.slice(svg.indexOf(",") + 1))))) });
      }
      if (fmts.indexOf("pdf") >= 0) { status("Building PDF…"); files.push({ ext: "pdf", mime: "application/pdf", data: b64(pdfDoc(meta, canvas, explain)) }); }
      var gifRes = null;
      if (ctx.stepper && ctx.steps > 1 && (fmts.indexOf("gif") >= 0 || fmts.indexOf("html") >= 0)) {
        gifRes = await makeGif(box, ctx, m, fmts.indexOf("html") >= 0);
        if (fmts.indexOf("gif") >= 0) files.push({ ext: "gif", mime: "image/gif", data: gifRes.gif });
      }
      var charts = plotlyData(box);
      if (fmts.indexOf("html") >= 0) {
        status("Building HTML…");
        var html = htmlDoc(meta, png, gifRes ? gifRes.frames : [], charts, explain);
        files.push({ ext: "html", mime: "text/html", data: btoa(unescape(encodeURIComponent(html))) });
      }
      if (fmts.indexOf("json") >= 0) {
        var js = JSON.stringify({ diagram: meta, exported: new Date().toISOString(), explanation: explain, charts: charts }, null, 1);
        files.push({ ext: "json", mime: "application/json", data: btoa(unescape(encodeURIComponent(js))) });
      }
      if (m.destination === "download") {
        files.forEach(function (f) { download(m.stem + "." + f.ext, f.data, f.mime); });
        send("dsa_export_payload", { nonce: m.nonce, downloaded: true, files: files.map(function (f) { return { ext: f.ext, mime: f.mime, bytes: Math.round(f.data.length * 0.75) }; }), meta: ctx });
      } else {
        status("Sending " + files.length + " file(s) to be saved…");
        send("dsa_export_payload", { nonce: m.nonce, files: files, meta: ctx });
      }
    } catch (err) {
      send("dsa_export_payload", { nonce: m.nonce, error: String(err && err.message || err) });
    } finally {
      status("");
    }
  }

  function onShiny() {
    Shiny.addCustomMessageHandler("dsa-export-run", function (m) { run(m); });
    Shiny.addCustomMessageHandler("dsa-export-status", function (m) { status(m.text || ""); });
  }
  if (window.Shiny && Shiny.addCustomMessageHandler) onShiny();
  else document.addEventListener("shiny:connected", onShiny, { once: true });

  setInterval(scan, 1500);
  document.addEventListener("DOMContentLoaded", scan);
})();
