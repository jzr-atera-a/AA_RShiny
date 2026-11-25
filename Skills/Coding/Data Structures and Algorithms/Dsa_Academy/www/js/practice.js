/* DSA Academy — code editor, stopwatch, countdown and activity heartbeat.
 * Ace editors are created automatically for every element with class "dsa-ace",
 * including ones inserted later by renderUI.
 */
(function () {
  "use strict";
  var DSA = window.DSA = window.DSA || {};
  DSA.editors = {};
  var lastActivity = Date.now();

  function send(id, value) {
    if (window.Shiny && Shiny.setInputValue) Shiny.setInputValue(id, value, { priority: "event" });
  }

  // ── Editors ────────────────────────────────────────────────────────────────
  function initEditor(el) {
    if (el.getAttribute("data-init") === "1" || !window.ace) return;
    el.setAttribute("data-init", "1");
    var id = el.id;
    var plain = el.getAttribute("data-plain") === "1";
    var initial = el.textContent;
    el.textContent = "";
    var ed = ace.edit(el);
    ed.session.setValue(initial);
    ed.setTheme(plain ? "ace/theme/github" : "ace/theme/one_dark");
    ed.session.setMode(plain ? "ace/mode/text" : "ace/mode/python");
    ed.session.setTabSize(4);
    ed.session.setUseSoftTabs(true);
    ed.setOptions({
      fontSize: (localStorageGet("dsa_font") || 14) + "px",
      showPrintMargin: false,
      highlightActiveLine: !plain,
      showGutter: true,
      displayIndentGuides: !plain,
      enableBasicAutocompletion: !plain && el.getAttribute("data-autocomplete") !== "0",
      enableLiveAutocompletion: !plain && el.getAttribute("data-autocomplete") !== "0",
      behavioursEnabled: !plain,
      readOnly: el.getAttribute("data-readonly") === "1",
      scrollPastEnd: 0.3
    });
    var kb = localStorageGet("dsa_keys");
    if (kb && kb !== "default") ed.setKeyboardHandler("ace/keyboard/" + kb);
    DSA.editors[id] = ed;

    // Debounced code input: <id>_code
    var timer = null;
    ed.session.on("change", function () {
      lastActivity = Date.now();
      clearTimeout(timer);
      timer = setTimeout(function () { send(id + "_code", { code: ed.getValue(), token: ed.dsaToken || null }); }, 500);
    });
    send(id + "_code", { code: ed.getValue(), token: ed.dsaToken || null });

    var action = el.getAttribute("data-action");
    if (action) {
      ed.commands.addCommand({ name: "dsaRun", bindKey: { win: "Ctrl-Enter", mac: "Command-Enter" },
        exec: function () { DSA.action(id, action, "run"); } });
      ed.commands.addCommand({ name: "dsaSubmit", bindKey: { win: "Ctrl-Shift-Enter", mac: "Command-Shift-Enter" },
        exec: function () { DSA.action(id, action, "submit"); } });
    }
    if (window.ResizeObserver) new ResizeObserver(function () { ed.resize(); }).observe(el);
  }

  function scan(root) {
    (root || document).querySelectorAll(".dsa-ace").forEach(initEditor);
  }

  function localStorageGet(k) { try { return window.localStorage.getItem(k); } catch (e) { return null; } }
  function localStorageSet(k, v) { try { window.localStorage.setItem(k, v); } catch (e) {} }

  // Send the editor's current code together with an action, so the server never sees stale code.
  DSA.action = function (editorId, inputId, type) {
    var ed = DSA.editors[editorId];
    if (!ed) return;
    var res = document.getElementById(editorId + "-running");
    if (res) res.style.display = "flex";
    send(inputId, { type: type, code: ed.getValue(), token: ed.dsaToken || null, nonce: Date.now() });
  };

  // Collect the code of every editor in a group (used when a mock interview ends).
  DSA.collect = function (group) {
    var out = {};
    document.querySelectorAll('.dsa-ace[data-group="' + group + '"]').forEach(function (el) {
      if (DSA.editors[el.id]) out[el.id] = DSA.editors[el.id].getValue();
    });
    return out;
  };
  DSA.finish = function (inputId, group, reason) {
    send(inputId, { codes: DSA.collect(group), reason: reason || "manual", nonce: Date.now() });
  };

  DSA.setFont = function (px) {
    localStorageSet("dsa_font", px);
    Object.keys(DSA.editors).forEach(function (k) { DSA.editors[k].setFontSize(px + "px"); });
  };
  DSA.setKeys = function (kb) {
    localStorageSet("dsa_keys", kb);
    Object.keys(DSA.editors).forEach(function (k) {
      DSA.editors[k].setKeyboardHandler(kb === "default" ? null : "ace/keyboard/" + kb);
    });
  };

  // ── Messages from the server ───────────────────────────────────────────────
  function onShiny() {
    Shiny.addCustomMessageHandler("dsa-set-code", function (m) {
      var ed = DSA.editors[m.id];
      if (!ed) return;
      ed.dsaToken = m.token || null;
      ed.session.setValue(m.code || "");
      ed.session.getUndoManager().reset();
      ed.session.clearAnnotations();
      ed.gotoLine(1, 0, false);
      send(m.id + "_code", { code: ed.getValue(), token: ed.dsaToken });
    });
    Shiny.addCustomMessageHandler("dsa-annotate", function (m) {
      var ed = DSA.editors[m.id];
      if (!ed) return;
      if (!m.line) { ed.session.clearAnnotations(); return; }
      ed.session.setAnnotations([{ row: m.line - 1, column: 0, text: m.text || "Error", type: "error" }]);
      ed.scrollToLine(m.line - 1, true, true, function () {});
    });
    Shiny.addCustomMessageHandler("dsa-readonly", function (m) {
      (m.ids || []).forEach(function (id) { if (DSA.editors[id]) DSA.editors[id].setReadOnly(!!m.value); });
    });
    Shiny.addCustomMessageHandler("dsa-running", function (m) {
      var el = document.getElementById(m.id + "-running");
      if (el) el.style.display = m.on ? "flex" : "none";
    });
    Shiny.addCustomMessageHandler("dsa-finish", function (m) { DSA.finish(m.input, m.group, m.reason); });
  }
  if (window.Shiny && Shiny.addCustomMessageHandler) onShiny();
  else document.addEventListener("shiny:connected", onShiny, { once: true });

  // ── Clocks ─────────────────────────────────────────────────────────────────
  function fmt(sec) {
    sec = Math.max(0, Math.floor(sec));
    var h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60), s = sec % 60;
    var mm = (h ? String(m).padStart(2, "0") : String(m)), ss = String(s).padStart(2, "0");
    return (h ? h + ":" : "") + mm + ":" + ss;
  }
  setInterval(function () {
    var now = Date.now();
    document.querySelectorAll(".dsa-stopwatch[data-start]").forEach(function (el) {
      el.textContent = "⏱ " + fmt((now - Number(el.getAttribute("data-start"))) / 1000);
    });
    document.querySelectorAll(".dsa-countdown[data-end]").forEach(function (el) {
      var left = (Number(el.getAttribute("data-end")) - now) / 1000;
      el.textContent = fmt(left);
      var total = Number(el.getAttribute("data-total")) || 1;
      el.classList.toggle("warn", left < total * 0.25);
      el.classList.toggle("late", left < 120);
      if (left <= 0 && el.getAttribute("data-fired") !== "1") {
        el.setAttribute("data-fired", "1");
        DSA.finish(el.getAttribute("data-input"), el.getAttribute("data-group"), "time");
      }
    });
  }, 1000);

  // ── Activity heartbeat (time-on-task) ─────────────────────────────────────
  ["keydown", "mousemove", "mousedown", "wheel"].forEach(function (ev) {
    document.addEventListener(ev, function () { lastActivity = Date.now(); }, { passive: true });
  });
  setInterval(function () {
    if (document.visibilityState === "visible" && Date.now() - lastActivity < 90000) send("dsa_heartbeat", Date.now());
  }, 15000);

  // ── Wire up ────────────────────────────────────────────────────────────────
  function start() {
    scan();
    new MutationObserver(function (muts) {
      muts.forEach(function (m) {
        m.addedNodes.forEach(function (n) {
          if (n.nodeType !== 1) return;
          if (n.classList && n.classList.contains("dsa-ace")) initEditor(n);
          else if (n.querySelectorAll) scan(n);
        });
      });
    }).observe(document.body, { childList: true, subtree: true });
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", start);
  else start();
})();
