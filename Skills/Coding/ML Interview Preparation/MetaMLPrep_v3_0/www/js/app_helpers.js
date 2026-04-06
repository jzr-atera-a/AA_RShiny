/* www/js/app_helpers.js
   Helpers for Python Runner (CodeMirror) + Whiteboard
*/

// ── Utility: get CodeMirror instance for a given Shiny input id ──────────
function getCM(id) {
  return window._cmEditors && window._cmEditors[id];
}

// ── Set editor content (used by template loader & problem bank) ──────────
Shiny.addCustomMessageHandler("setCodeEditor", function(msg) {
  var cm = getCM(msg.id);
  if (cm) {
    cm.setValue(msg.value);
    cm.focus();
    return;
  }
  // Fallback: plain textarea (other modules)
  var el = document.getElementById(msg.id);
  if (el) {
    el.value = msg.value;
    el.dispatchEvent(new Event("input",  { bubbles: true }));
    el.dispatchEvent(new Event("change", { bubbles: true }));
    el.focus();
  }
});

// ── Append to editor content (timeit / assertion helpers) ────────────────
Shiny.addCustomMessageHandler("appendCodeEditor", function(msg) {
  var cm = getCM(msg.id);
  if (cm) {
    var cur = cm.getValue();
    cm.setValue(cur + msg.value);
    cm.setCursor(cm.lineCount(), 0);  // move cursor to end
    cm.focus();
    return;
  }
  // Fallback: plain textarea
  var el = document.getElementById(msg.id);
  if (el) {
    el.value += msg.value;
    el.dispatchEvent(new Event("input",  { bubbles: true }));
    el.dispatchEvent(new Event("change", { bubbles: true }));
    el.scrollTop = el.scrollHeight;
  }
});

// ── Sync plain textareas (non-CodeMirror editors) to Shiny ───────────────
document.addEventListener("input", function(e) {
  if (e.target && e.target.classList.contains("code-editor")) {
    try { Shiny.setInputValue(e.target.id, e.target.value, { priority: "event" }); } catch(err) {}
  }
});

// ── Whiteboard save bridge ────────────────────────────────────────────────
Shiny.addCustomMessageHandler("wbSaveResult", function(msg) {
  if (msg.success) console.log("[Whiteboard] Saved:", msg.filename);
});
