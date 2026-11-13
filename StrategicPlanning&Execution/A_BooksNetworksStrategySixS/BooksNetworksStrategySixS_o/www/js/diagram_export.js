// www/js/diagram_export.js
//
// Shared "download this rendered visualization" mechanism for Strategic
// Analysis, Six Sigma Analysis, and Flex Table's Visualizations tabs.
//
// Deliberately entirely client-side, mirroring the reasoning behind the
// Travel Planning reference app's own export approach (avoid depending on
// tools that may not exist on the deployment server - there it was
// rmarkdown/tinytex and a headless browser; here it would be a server-side
// screenshot tool like webshot2/chromote). Since every diagram in this app
// is already rendered as real DOM content in the browser (HTML/CSS grid,
// hand-built SVG, or a Plotly chart), the browser itself can capture
// exactly what's on screen via html2canvas - one mechanism that works
// uniformly across all of this app's rendering technologies, present and
// future, without needing a bespoke re-implementation of every diagram
// shape in a second rendering system just for export purposes.
//
// HTML export bypasses html2canvas entirely and grabs the real rendered
// markup directly, since that's strictly more faithful (real DOM, not a
// rasterized copy) and simpler.

(function () {

  function sanitizeFilename(name) {
    var safe = (name || "diagram").replace(/[^a-z0-9_\- ]+/gi, "").trim().replace(/\s+/g, "_");
    if (safe.length === 0) safe = "diagram";
    return safe.substring(0, 80);
  }

  function downloadBlob(blob, filename) {
    var url = URL.createObjectURL(blob);
    var a = document.createElement("a");
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    setTimeout(function () {
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    }, 150);
  }

  function showPreparingIndicator(label) {
    var el = document.createElement("div");
    el.className = "export-preparing-indicator";
    el.innerText = label;
    document.body.appendChild(el);
    return el;
  }

  function hidePreparingIndicator(el) {
    if (el && el.parentNode) el.parentNode.removeChild(el);
  }

  // Collects every readable stylesheet rule currently on the page, so an
  // HTML export looks right when opened standalone/offline rather than
  // relying on <link> tags pointing back at this running app. Rules from
  // a cross-origin stylesheet (a CDN font, say) can't be read this way and
  // are silently skipped - those assets simply won't be present in the
  // offline copy, a reasonable, honest limitation of a pure client-side
  // export with no server round trip.
  function collectPageCss() {
    var cssText = "";
    for (var i = 0; i < document.styleSheets.length; i++) {
      try {
        var rules = document.styleSheets[i].cssRules || document.styleSheets[i].rules;
        if (!rules) continue;
        for (var j = 0; j < rules.length; j++) cssText += rules[j].cssText + "\n";
      } catch (e) {
        // cross-origin stylesheet - can't read its rules from JS, skip it
      }
    }
    return cssText;
  }

  function exportAsHTML(targetEl, safeTitle) {
    var css = collectPageCss();
    var html =
      "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><title>" + safeTitle + "</title>" +
      "<style>body{font-family:Arial,Helvetica,sans-serif;padding:24px;background:#ffffff;}" +
      css + "</style></head><body>" + targetEl.outerHTML + "</body></html>";
    var blob = new Blob([html], { type: "text/html" });
    downloadBlob(blob, safeTitle + ".html");
  }

  function exportAsJPEG(canvas, safeTitle) {
    canvas.toBlob(function (blob) {
      downloadBlob(blob, safeTitle + ".jpg");
    }, "image/jpeg", 0.92);
  }

  // Fits a canvas of arbitrary pixel dimensions into a bounding box
  // (in whatever unit the box is expressed in - points for jsPDF, inches
  // for pptxgenjs) while preserving its aspect ratio. A single scale
  // factor works regardless of the two different unit systems here,
  // since it's simply "shrink the pixel dimensions down until both fit,"
  // not a literal pixels-to-points/inches conversion.
  function fitToBox(canvasW, canvasH, maxW, maxH) {
    var ratio = Math.min(maxW / canvasW, maxH / canvasH);
    return { w: canvasW * ratio, h: canvasH * ratio };
  }

  function exportAsPDF(canvas, safeTitle) {
    var JsPdfCtor = (window.jspdf && window.jspdf.jsPDF) ? window.jspdf.jsPDF : window.jsPDF;
    if (!JsPdfCtor) { alert("PDF export library failed to load - please refresh and try again."); return; }

    var orientation = canvas.width >= canvas.height ? "landscape" : "portrait";
    var pdf = new JsPdfCtor({ orientation: orientation, unit: "pt", format: "a4" });
    var pageWidth = pdf.internal.pageSize.getWidth();
    var pageHeight = pdf.internal.pageSize.getHeight();
    var margin = 24;
    var fitted = fitToBox(canvas.width, canvas.height, pageWidth - margin * 2, pageHeight - margin * 2);
    var x = (pageWidth - fitted.w) / 2;
    var y = (pageHeight - fitted.h) / 2;

    var imgData = canvas.toDataURL("image/jpeg", 0.95);
    pdf.addImage(imgData, "JPEG", x, y, fitted.w, fitted.h);
    pdf.save(safeTitle + ".pdf");
  }

  function exportAsPPTX(canvas, safeTitle) {
    if (typeof PptxGenJS === "undefined") { alert("PowerPoint export library failed to load - please refresh and try again."); return; }

    var pptx = new PptxGenJS();
    pptx.defineLayout({ name: "WIDE", width: 13.33, height: 7.5 });
    pptx.layout = "WIDE";
    var slide = pptx.addSlide();

    var margin = 0.4;
    var fitted = fitToBox(canvas.width, canvas.height, 13.33 - margin * 2, 7.5 - margin * 2);
    var x = (13.33 - fitted.w) / 2;
    var y = (7.5 - fitted.h) / 2;

    var imgData = canvas.toDataURL("image/png");
    slide.addImage({ data: imgData, x: x, y: y, w: fitted.w, h: fitted.h });
    pptx.writeFile({ fileName: safeTitle + ".pptx" });
  }

  // Main entry point, called directly from each Visualizations tab's
  // Download button.
  //   targetId    - the DOM id of the element to export (the rendered
  //                 diagram/table container only, never the surrounding
  //                 controls - so the dropdown/button themselves never
  //                 end up inside the exported file).
  //   formatSelectId - the DOM id of the <select> holding the chosen
  //                 format ("html" | "jpeg" | "pdf" | "pptx").
  //   fallbackName - used as the filename if the target has no
  //                 data-export-title attribute set.
  window.exportVisualization = function (targetId, formatSelectId, fallbackName) {
    var el = document.getElementById(targetId);
    if (!el || el.children.length === 0) {
      alert("Nothing to export yet - render a diagram first.");
      return;
    }
    var formatEl = document.getElementById(formatSelectId);
    var format = formatEl ? formatEl.value : "pdf";
    var title = el.getAttribute("data-export-title") || fallbackName || "diagram";
    var safeTitle = sanitizeFilename(title);

    if (format === "html") {
      exportAsHTML(el, safeTitle);
      return;
    }

    var indicator = showPreparingIndicator("Preparing " + format.toUpperCase() + " export...");

    // A small delay lets the "preparing" indicator actually paint before
    // html2canvas's own (synchronous, potentially slow) capture work
    // blocks the main thread.
    setTimeout(function () {
      html2canvas(el, { scale: 2, backgroundColor: "#ffffff", useCORS: true, logging: false })
        .then(function (canvas) {
          if (format === "jpeg") exportAsJPEG(canvas, safeTitle);
          else if (format === "pdf") exportAsPDF(canvas, safeTitle);
          else if (format === "pptx") exportAsPPTX(canvas, safeTitle);
          hidePreparingIndicator(indicator);
        })
        .catch(function (err) {
          hidePreparingIndicator(indicator);
          alert("Export failed: " + err.message);
          console.error("[diagram_export] html2canvas failed:", err);
        });
    }, 50);
  };

})();
