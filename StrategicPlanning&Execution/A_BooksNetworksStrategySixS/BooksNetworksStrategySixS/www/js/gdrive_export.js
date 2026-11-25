// www/js/gdrive_export.js
// Where an exported file goes: a normal browser download, or Google Drive.
// diagram_export.js and infographic_export.js build the file (HTML, PDF, PNG, JPEG, GIF, PPTX or ZIP) and hand the
// finished Blob to window.__exportDeliver(blob, filename). When the export was started with the "Save to Google Drive"
// button, the Blob is sent to the R server through the hidden Shiny file input #gdrive_upload (an ordinary HTTP
// upload, so large PDFs are fine), together with the export target's data-drive-* attributes (main group, sub-tab,
// category, domain, topic, title). The server (R/utils_gdrive.R) files it into the folder hierarchy on Drive.
(function () {
  "use strict";
  var driveState = { configured: false, state: "none", msg: "Google Drive is not set up yet." };

  function download(blob, filename) {
    var url = URL.createObjectURL(blob), a = document.createElement("a");
    a.href = url; a.download = filename; document.body.appendChild(a); a.click();
    setTimeout(function () { document.body.removeChild(a); URL.revokeObjectURL(url); }, 200);
  }
  function nonce() { return Date.now().toString(36) + Math.random().toString(36).slice(2, 8); }
  function attr(el, k) { return el ? (el.getAttribute(k) || "") : ""; }

  function sendToDrive(blob, filename, ctx) {
    var el = document.getElementById(ctx.targetId);
    // the attributes sit on the export target, or on its closest wrapper that has them
    var holder = el && el.closest ? (el.closest("[data-drive-group]") || el) : el;
    var input = document.getElementById("gdrive_upload");
    if (!window.Shiny || !Shiny.setInputValue || !input) { alert("The page is not connected to the app server; reload and try again."); return; }
    var n = nonce();
    Shiny.setInputValue("gdrive_meta", {
      nonce: n, group: attr(holder, "data-drive-group"), tab: attr(holder, "data-drive-tab"),
      category: attr(holder, "data-drive-category"), domain: attr(holder, "data-drive-domain"), topic: attr(holder, "data-drive-topic"),
      source_id: attr(holder, "data-drive-source"), title: attr(el, "data-export-title") || ctx.fallbackName || "diagram",
      format: (filename.split(".").pop() || "").toLowerCase(), size: blob.size
    }, { priority: "event" });
    var file;
    try { file = new File([blob], n + "__" + filename, { type: blob.type || "application/octet-stream" }); }
    catch (e) { file = blob; file.name = n + "__" + filename; }
    var dt = new DataTransfer(); dt.items.add(file);
    input.files = dt.files;
    input.dispatchEvent(new Event("change", { bubbles: true }));
  }

  // Each export takes the context once, when it starts (so a failed Drive export never turns the next download into
  // a Drive upload), and gives it back here with the finished file.
  window.__exportCtx = null;
  window.__exportTakeCtx = function () { var c = window.__exportCtx || { mode: "download" }; window.__exportCtx = null; return c; };
  window.__exportDeliver = function (ctx, blob, filename) {
    if (ctx && ctx.mode === "drive") return sendToDrive(blob, filename, ctx);
    download(blob, filename);
  };

  // Called by the "Save to Google Drive" buttons: checks Drive is ready, then runs the normal export in drive mode.
  window.saveToDrive = function (kind, targetId, formatSelectId, fallbackName) {
    if (!driveState.configured) {
      alert("Google Drive is not set up yet. Open API Configuration > Google Drive, choose how to sign in and the folder, then try again.");
      return;
    }
    if (driveState.state === "error" && !confirm("The last Google Drive check failed:\n\n" + driveState.msg + "\n\nTry to save anyway?")) return;
    window.__exportCtx = { mode: "drive", targetId: targetId, fallbackName: fallbackName };
    if (kind === "infographic") window.exportInfographic(targetId, formatSelectId, fallbackName);
    else window.exportVisualization(targetId, formatSelectId, fallbackName);
  };

  (function reg() {
    if (window.Shiny && Shiny.addCustomMessageHandler) {
      Shiny.addCustomMessageHandler("gdrive_status", function (m) {
        driveState = m || driveState;
        var on = !!(m && m.configured);
        document.querySelectorAll(".gdrive-save-btn").forEach(function (b) {
          b.classList.toggle("gdrive-off", !on);
          b.title = on ? "Save this file into the Google Drive folder hierarchy (" + (m.msg || "") + ")" : "Set up Google Drive first: API Configuration > Google Drive";
        });
      });
    } else setTimeout(reg, 200);
  })();
})();
