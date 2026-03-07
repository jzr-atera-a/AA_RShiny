/* www/js/app_helpers.js
   Custom message handlers for Python Runner + Whiteboard modules
   Loaded via global.R tags$head injection
*/

// ── Code Editor helpers ───────────────────────────────────────────────────
// Set textarea content from R server (template loader)
Shiny.addCustomMessageHandler("setCodeEditor", function(msg) {
  var el = document.getElementById(msg.id);
  if (el) {
    el.value = msg.value;
    // Trigger Shiny input binding to update reactive value
    el.dispatchEvent(new Event("input", { bubbles: true }));
    el.dispatchEvent(new Event("change", { bubbles: true }));
    el.focus();
  }
});

// Append text to existing textarea content
Shiny.addCustomMessageHandler("appendCodeEditor", function(msg) {
  var el = document.getElementById(msg.id);
  if (el) {
    el.value = el.value + msg.value;
    el.dispatchEvent(new Event("input",  { bubbles: true }));
    el.dispatchEvent(new Event("change", { bubbles: true }));
    el.scrollTop = el.scrollHeight;
  }
});

// Sync textarea value to Shiny on every keystroke
document.addEventListener("input", function(e) {
  if (e.target && e.target.classList.contains("code-editor")) {
    Shiny.setInputValue(e.target.id, e.target.value, { priority: "event" });
  }
});

// ── Whiteboard save bridge ────────────────────────────────────────────────
// Called by whiteboard JS to trigger R notification after save
Shiny.addCustomMessageHandler("wbSaveResult", function(msg) {
  // msg: { success: true/false, filename: "...", format: "png/jpg/pdf" }
  if (msg.success) {
    console.log("[Whiteboard] Saved:", msg.filename);
  }
});
