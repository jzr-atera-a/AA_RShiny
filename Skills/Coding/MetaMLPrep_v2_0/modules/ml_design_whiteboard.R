# modules/ml_design_whiteboard.R
# ML Design Interview Whiteboard
# Fabric.js v5 canvas — full-body tab, save as PNG/JPG/PDF to any Windows folder
#
# Research note:
#   Meta's CoderPad Whiteboard uses Excalidraw (hand-drawn style).
#   Google and Amazon use Miro or custom canvas tools.
#   This implementation mirrors the Excalidraw/CoderPad experience:
#   free-draw, shapes (rect/ellipse/diamond/arrow/line), text labels,
#   colour & stroke picker, undo/redo, and export to PNG, JPG, or PDF
#   with Windows "Save As" dialog (File System Access API — Chrome/Edge).
#   Falls back to auto-download for other browsers.

ml_design_whiteboard_ui <- function(id) {
  ns <- NS(id)

  # The entire tab body is the canvas — no box wrapper, no padding
  tagList(

    # ── Full-tab CSS ────────────────────────────────
    tags$style(HTML(paste0("
      /* Remove shinydashboard body padding for this tab only */
      body.sidebar-mini .content-wrapper { background: #f0f2f5; }

      #wb-shell {
        display: flex;
        flex-direction: column;
        height: calc(100vh - 102px);   /* full viewport minus header+sidebar chrome */
        background: #1e1e2e;
        border-radius: 12px;
        overflow: hidden;
        box-shadow: 0 8px 32px rgba(0,0,0,0.45);
        position: relative;
      }

      /* ── Toolbar ── */
      #wb-toolbar {
        display: flex;
        align-items: center;
        gap: 4px;
        padding: 8px 12px;
        background: #2a2a3e;
        border-bottom: 1px solid #3a3a5c;
        flex-wrap: wrap;
        z-index: 10;
        user-select: none;
      }
      .wb-group {
        display: flex;
        align-items: center;
        gap: 3px;
        padding: 0 6px;
        border-right: 1px solid #3a3a5c;
      }
      .wb-group:last-child { border-right: none; }
      .wb-btn {
        background: transparent;
        border: 1px solid transparent;
        border-radius: 7px;
        color: #c0c0d8;
        cursor: pointer;
        padding: 6px 10px;
        font-size: 16px;
        line-height: 1;
        transition: all 0.15s;
        display: flex; align-items: center; justify-content: center;
        min-width: 34px; min-height: 34px;
      }
      .wb-btn:hover      { background: #3a3a5c; color: #ffffff; border-color: #5a5a8c; }
      .wb-btn.active     { background: #1877F2; color: #fff; border-color: #1877F2; }
      .wb-btn.danger:hover { background: #dc2626; color: #fff; border-color: #dc2626; }
      .wb-label {
        font-size: 11px; font-weight: 600;
        color: #888; text-transform: uppercase; letter-spacing: 0.06em;
        padding: 0 4px;
      }
      input[type=color].wb-color {
        width: 34px; height: 34px;
        border: none; border-radius: 7px;
        cursor: pointer; padding: 2px;
        background: #3a3a5c;
      }
      input[type=range].wb-range {
        width: 80px; height: 4px; accent-color: #1877F2;
        cursor: pointer;
      }
      #wb-stroke-label { font-size: 11px; color: #aaa; min-width: 24px; }
      .wb-select {
        background: #3a3a5c; color: #c0c0d8;
        border: 1px solid #5a5a8c; border-radius: 7px;
        padding: 5px 8px; font-size: 12px; cursor: pointer;
      }

      /* ── Canvas area ── */
      #wb-canvas-wrap {
        flex: 1;
        position: relative;
        overflow: hidden;
        background: #ffffff;
        cursor: crosshair;
      }
      #wb-canvas-wrap canvas { display: block; }

      /* ── Status bar ── */
      #wb-statusbar {
        display: flex; align-items: center; gap: 16px;
        padding: 5px 14px;
        background: #2a2a3e;
        border-top: 1px solid #3a3a5c;
        font-size: 11px; color: #888;
        font-family: 'Fira Code', monospace;
      }
      #wb-statusbar span { white-space: nowrap; }

      /* ── Save panel ── */
      #wb-save-panel {
        display: flex; align-items: center; gap: 8px;
        padding: 7px 14px;
        background: #23233a;
        border-top: 1px solid #3a3a5c;
        flex-wrap: wrap;
      }
      #wb-save-panel label { font-size: 12px; color: #aaa; font-weight:600; margin:0; }
      #wb-filename {
        flex: 1; min-width: 160px; max-width: 280px;
        background: #3a3a5c; color: #e0e0f0;
        border: 1px solid #5a5a8c; border-radius: 7px;
        padding: 6px 10px; font-size: 13px;
        font-family: 'Fira Code', monospace;
      }
      #wb-filename:focus { outline: 2px solid #1877F2; }
      .wb-save-btn {
        padding: 7px 18px; border-radius: 8px; border: none;
        font-weight: 700; font-size: 13px; cursor: pointer;
        display: flex; align-items: center; gap: 6px;
        transition: filter 0.15s;
      }
      .wb-save-btn:hover { filter: brightness(1.15); }
      #wb-btn-png  { background: #16a34a; color: #fff; }
      #wb-btn-jpg  { background: #b45309; color: #fff; }
      #wb-btn-pdf  { background: #7c3aed; color: #fff; }
      #wb-btn-clear { background: #991b1b; color: #fff; }
      #wb-save-status { font-size: 12px; color: #4ade80; margin-left: 8px; }
    "))),

    # ── Shell ────────────────────────────────────────
    div(id = "wb-shell",

      # ── Toolbar ──
      div(id = "wb-toolbar",

        # Tool group
        div(class = "wb-group",
            span(class = "wb-label", "Tool"),
            tags$button(id = "wb-tool-select",   class = "wb-btn active",    title = "Select / Move (V)",     HTML("&#9654;")),
            tags$button(id = "wb-tool-pen",      class = "wb-btn",           title = "Freehand Draw (P)",     HTML("&#9998;")),
            tags$button(id = "wb-tool-rect",     class = "wb-btn",           title = "Rectangle (R)",         HTML("&#9645;")),
            tags$button(id = "wb-tool-ellipse",  class = "wb-btn",           title = "Ellipse / Circle (E)",  HTML("&#9711;")),
            tags$button(id = "wb-tool-diamond",  class = "wb-btn",           title = "Diamond (D)",           HTML("&#9670;")),
            tags$button(id = "wb-tool-arrow",    class = "wb-btn",           title = "Arrow (A)",             HTML("&#10145;")),
            tags$button(id = "wb-tool-line",     class = "wb-btn",           title = "Line (L)",              HTML("&#9135;")),
            tags$button(id = "wb-tool-text",     class = "wb-btn",           title = "Text (T)",              HTML("&#9000;"))
        ),

        # Style group
        div(class = "wb-group",
            span(class = "wb-label", "Fill"),
            tags$input(type = "color", id = "wb-fill-color", class = "wb-color",
                       value = "#ffffff", title = "Fill colour"),
            span(class = "wb-label", "Stroke"),
            tags$input(type = "color", id = "wb-stroke-color", class = "wb-color",
                       value = "#1877F2", title = "Stroke colour"),
            span(class = "wb-label", "Width"),
            tags$input(type = "range",  id = "wb-stroke-width", class = "wb-range",
                       min = "1", max = "20", value = "2", title = "Stroke width"),
            tags$span(id = "wb-stroke-label", "2px")
        ),

        # Font group
        div(class = "wb-group",
            span(class = "wb-label", "Font"),
            tags$select(id = "wb-font-size", class = "wb-select",
                        tags$option(value="14",  "14px"),
                        tags$option(value="16",  "16px", selected=NA),
                        tags$option(value="20",  "20px"),
                        tags$option(value="24",  "24px"),
                        tags$option(value="32",  "32px"),
                        tags$option(value="48",  "48px")
            ),
            tags$select(id = "wb-font-family", class = "wb-select",
                        tags$option(value="Arial",       "Arial"),
                        tags$option(value="Fira Code",   "Fira Code"),
                        tags$option(value="Georgia",     "Georgia"),
                        tags$option(value="Comic Sans MS","Comic Sans")
            )
        ),

        # Canvas controls
        div(class = "wb-group",
            span(class = "wb-label", "Canvas"),
            tags$select(id = "wb-bg-color", class = "wb-select",
                        tags$option(value="#ffffff", "White"),
                        tags$option(value="#f5f0e8", "Parchment"),
                        tags$option(value="#0d1117", "Dark"),
                        tags$option(value="#eef2ff", "Blueprint")
            )
        ),

        # History group
        div(class = "wb-group",
            tags$button(id = "wb-undo",   class = "wb-btn", title = "Undo (Ctrl+Z)",  HTML("&#8634;")),
            tags$button(id = "wb-redo",   class = "wb-btn", title = "Redo (Ctrl+Y)",  HTML("&#8635;")),
            tags$button(id = "wb-delete", class = "wb-btn danger", title = "Delete selected (Del)", HTML("&#128465;"))
        ),

        # Object order
        div(class = "wb-group",
            tags$button(id = "wb-bring-fwd",  class = "wb-btn", title = "Bring Forward",  HTML("&#8679;")),
            tags$button(id = "wb-send-bwd",   class = "wb-btn", title = "Send Backward",  HTML("&#8681;")),
            tags$button(id = "wb-group-sel",  class = "wb-btn", title = "Group selection", HTML("&#11188;"))
        ),

        # Zoom
        div(class = "wb-group",
            tags$button(id = "wb-zoom-in",  class = "wb-btn", title = "Zoom In (+)",  HTML("&#43;")),
            tags$button(id = "wb-zoom-out", class = "wb-btn", title = "Zoom Out (-)", HTML("&minus;")),
            tags$button(id = "wb-zoom-fit", class = "wb-btn", title = "Fit to screen", HTML("&#9635;"))
        )
      ), # end toolbar

      # ── Canvas ──
      div(id = "wb-canvas-wrap",
          tags$canvas(id = "wb-canvas")
      ),

      # ── Save Panel ──
      div(id = "wb-save-panel",
          tags$label(`for` = "wb-filename", "Filename:"),
          tags$input(type = "text", id = "wb-filename",
                     value = "ml_design_diagram",
                     placeholder = "ml_design_diagram"),
          tags$button(id = "wb-btn-png", class = "wb-save-btn",
                      HTML("&#128444; Save PNG")),
          tags$button(id = "wb-btn-jpg", class = "wb-save-btn",
                      HTML("&#128444; Save JPG")),
          tags$button(id = "wb-btn-pdf", class = "wb-save-btn",
                      HTML("&#128196; Save PDF")),
          tags$button(id = "wb-btn-clear", class = "wb-save-btn",
                      HTML("&#128465; Clear All")),
          tags$span(id = "wb-save-status", "")
      ),

      # ── Status bar ──
      div(id = "wb-statusbar",
          tags$span(id = "wb-status-tool",  "Tool: Select"),
          tags$span(id = "wb-status-zoom",  "Zoom: 100%"),
          tags$span(id = "wb-status-objs",  "Objects: 0"),
          tags$span(id = "wb-status-pos",   "x:0 y:0"),
          tags$span(style = "margin-left:auto; color:#555;",
                    "Meta ML Design Interview Whiteboard  ·  Ctrl+Z undo  ·  Del delete  ·  V select  ·  P draw  ·  R rect  ·  E ellipse  ·  A arrow  ·  T text")
      )
    ), # end wb-shell

    # ── Scripts ──────────────────────────────────────
    # Fabric.js v5 (last stable, full features)
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/fabric.js/5.3.1/fabric.min.js",
                integrity = "sha512-CeIsOAsgJnmevfCi2C6/3OhADQNKs97P7VKNvlBPMQJ5VJjqSo1+OlCv7Q7IHQcQSnKCcBHzGYQXPn0MdTXg==",
                crossorigin = "anonymous", referrerpolicy = "no-referrer"),
    # jsPDF for PDF export
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js",
                integrity = "sha512-qZvrmS2ekKPF2mSznTQsxqPgnpkI4DNTlrdUmTzrDgektczlKNRRhy5X5AAOnx5S09ydFYWWNSfcEqDTTHgtNA==",
                crossorigin = "anonymous", referrerpolicy = "no-referrer"),

    # ── Whiteboard Logic ─────────────────────────────
    tags$script(HTML("
(function() {
'use strict';

// ── Wait for both Fabric + jsPDF ────────────────────
function waitForLibs(cb) {
  if (typeof fabric !== 'undefined' && typeof jspdf !== 'undefined') { cb(); return; }
  if (typeof fabric !== 'undefined' && typeof window.jspdf === 'undefined') {
    // jsPDF may attach to window.jspdf.jsPDF
    setTimeout(function() { waitForLibs(cb); }, 80);
    return;
  }
  setTimeout(function() { waitForLibs(cb); }, 80);
}

waitForLibs(function() {

// ── Canvas init ──────────────────────────────────────
var wrap  = document.getElementById('wb-canvas-wrap');
var cvs   = document.getElementById('wb-canvas');

function setSize() {
  var r = wrap.getBoundingClientRect();
  canvas.setWidth(r.width);
  canvas.setHeight(r.height);
  canvas.renderAll();
}

var canvas = new fabric.Canvas('wb-canvas', {
  selection:       true,
  preserveObjectStacking: true,
  backgroundColor: '#ffffff'
});
setSize();
window.addEventListener('resize', function() { setTimeout(setSize, 60); });

// ── State ────────────────────────────────────────────
var currentTool   = 'select';
var isDrawing     = false;
var startX, startY, activeShape;
var undoStack     = [], redoStack = [];
var MAX_HIST      = 60;

// Save state for undo
function snapshot() {
  var json = JSON.stringify(canvas.toJSON());
  undoStack.push(json);
  if (undoStack.length > MAX_HIST) undoStack.shift();
  redoStack = [];
  updateStatus();
}

// ── Tool button activation ───────────────────────────
var toolBtns = {
  select:  document.getElementById('wb-tool-select'),
  pen:     document.getElementById('wb-tool-pen'),
  rect:    document.getElementById('wb-tool-rect'),
  ellipse: document.getElementById('wb-tool-ellipse'),
  diamond: document.getElementById('wb-tool-diamond'),
  arrow:   document.getElementById('wb-tool-arrow'),
  line:    document.getElementById('wb-tool-line'),
  text:    document.getElementById('wb-tool-text')
};

function setTool(t) {
  currentTool = t;
  Object.keys(toolBtns).forEach(function(k) {
    toolBtns[k].classList.toggle('active', k === t);
  });
  canvas.isDrawingMode = (t === 'pen');
  canvas.selection     = (t === 'select');
  canvas.defaultCursor = (t === 'select') ? 'default' : 'crosshair';
  document.getElementById('wb-status-tool').textContent = 'Tool: ' + t.charAt(0).toUpperCase() + t.slice(1);
  if (t === 'pen') {
    canvas.freeDrawingBrush.color = strokeColor();
    canvas.freeDrawingBrush.width = strokeWidth();
  }
}

Object.keys(toolBtns).forEach(function(k) {
  toolBtns[k].addEventListener('click', function() { setTool(k); });
});

// ── Style getters ────────────────────────────────────
function fillColor()   { return document.getElementById('wb-fill-color').value;   }
function strokeColor() { return document.getElementById('wb-stroke-color').value; }
function strokeWidth() { return parseInt(document.getElementById('wb-stroke-width').value, 10); }
function fontSize()    { return parseInt(document.getElementById('wb-font-size').value, 10);    }
function fontFamily()  { return document.getElementById('wb-font-family').value;  }

document.getElementById('wb-stroke-width').addEventListener('input', function() {
  document.getElementById('wb-stroke-label').textContent = this.value + 'px';
  if (canvas.isDrawingMode) {
    canvas.freeDrawingBrush.width = parseInt(this.value, 10);
  }
  var obj = canvas.getActiveObject();
  if (obj) { obj.set('strokeWidth', parseInt(this.value, 10)); canvas.renderAll(); }
});

document.getElementById('wb-stroke-color').addEventListener('input', function() {
  if (canvas.isDrawingMode) canvas.freeDrawingBrush.color = this.value;
  var obj = canvas.getActiveObject();
  if (obj) { obj.set('stroke', this.value); canvas.renderAll(); }
});

document.getElementById('wb-fill-color').addEventListener('input', function() {
  var obj = canvas.getActiveObject();
  if (obj) { obj.set('fill', this.value); canvas.renderAll(); }
});

document.getElementById('wb-bg-color').addEventListener('change', function() {
  canvas.setBackgroundColor(this.value, canvas.renderAll.bind(canvas));
});

// ── Shape drawing (mouse events) ────────────────────
canvas.on('mouse:down', function(opt) {
  if (currentTool === 'select' || currentTool === 'pen') return;
  var ptr = canvas.getPointer(opt.e);
  startX = ptr.x; startY = ptr.y;
  isDrawing = true;
  canvas.selection = false;

  var sc = strokeColor(), fc = fillColor(), sw = strokeWidth();

  if (currentTool === 'text') {
    var tb = new fabric.IText('Type here...', {
      left: ptr.x, top: ptr.y,
      fontSize: fontSize(), fontFamily: fontFamily(),
      fill: sc, editable: true
    });
    canvas.add(tb); canvas.setActiveObject(tb); tb.enterEditing();
    snapshot(); isDrawing = false; return;
  }

  if (currentTool === 'rect') {
    activeShape = new fabric.Rect({
      left: startX, top: startY, width: 0, height: 0,
      stroke: sc, fill: fc, strokeWidth: sw, selectable: false
    });
  } else if (currentTool === 'ellipse') {
    activeShape = new fabric.Ellipse({
      left: startX, top: startY, rx: 0, ry: 0,
      stroke: sc, fill: fc, strokeWidth: sw, selectable: false
    });
  } else if (currentTool === 'diamond') {
    activeShape = new fabric.Polygon(
      [{x:0,y:-40},{x:40,y:0},{x:0,y:40},{x:-40,y:0}],
      { left: startX, top: startY, scaleX: 1, scaleY: 1,
        stroke: sc, fill: fc, strokeWidth: sw, selectable: false }
    );
  } else if (currentTool === 'arrow' || currentTool === 'line') {
    activeShape = new fabric.Line([startX, startY, startX, startY], {
      stroke: sc, strokeWidth: sw,
      fill: sc, selectable: false
    });
  }

  if (activeShape) canvas.add(activeShape);
});

canvas.on('mouse:move', function(opt) {
  if (!isDrawing || !activeShape) return;
  var ptr = canvas.getPointer(opt.e);
  var w = ptr.x - startX, h = ptr.y - startY;

  if (currentTool === 'rect') {
    activeShape.set({
      width:  Math.abs(w), height: Math.abs(h),
      left:   w < 0 ? ptr.x : startX,
      top:    h < 0 ? ptr.y : startY
    });
  } else if (currentTool === 'ellipse') {
    activeShape.set({
      rx: Math.abs(w) / 2, ry: Math.abs(h) / 2,
      left: Math.min(startX, ptr.x), top: Math.min(startY, ptr.y)
    });
  } else if (currentTool === 'diamond') {
    var size = Math.max(Math.abs(w), Math.abs(h));
    activeShape.set({ scaleX: size / 80, scaleY: size / 80 });
  } else if (currentTool === 'arrow' || currentTool === 'line') {
    activeShape.set({ x2: ptr.x, y2: ptr.y });
  }
  canvas.renderAll();

  // Update cursor position in status bar
  document.getElementById('wb-status-pos').textContent =
    'x:' + Math.round(ptr.x) + ' y:' + Math.round(ptr.y);
});

canvas.on('mouse:up', function() {
  if (!isDrawing) return;
  isDrawing = false;
  if (activeShape) {
    activeShape.set('selectable', true);
    // Add arrowhead for arrow tool
    if (currentTool === 'arrow') {
      var x1 = activeShape.get('x1'), y1 = activeShape.get('y1');
      var x2 = activeShape.get('x2'), y2 = activeShape.get('y2');
      var angle = Math.atan2(y2 - y1, x2 - x1) * 180 / Math.PI;
      var head = new fabric.Triangle({
        left: x2, top: y2, width: 14, height: 14,
        fill: strokeColor(),
        angle: angle + 90,
        originX: 'center', originY: 'center',
        selectable: false
      });
      canvas.add(head);
    }
    canvas.setActiveObject(activeShape);
    activeShape = null;
    snapshot();
  }
  canvas.selection = (currentTool === 'select');
});

// After free drawing, snapshot
canvas.on('path:created', function() { snapshot(); });

// ── Undo / Redo ──────────────────────────────────────
document.getElementById('wb-undo').addEventListener('click', function() {
  if (undoStack.length === 0) return;
  redoStack.push(JSON.stringify(canvas.toJSON()));
  var prev = undoStack.pop();
  canvas.loadFromJSON(prev, function() { canvas.renderAll(); updateStatus(); });
});

document.getElementById('wb-redo').addEventListener('click', function() {
  if (redoStack.length === 0) return;
  undoStack.push(JSON.stringify(canvas.toJSON()));
  var next = redoStack.pop();
  canvas.loadFromJSON(next, function() { canvas.renderAll(); updateStatus(); });
});

// ── Delete ───────────────────────────────────────────
function deleteSelected() {
  var active = canvas.getActiveObjects();
  if (active.length === 0) return;
  canvas.discardActiveObject();
  active.forEach(function(o) { canvas.remove(o); });
  snapshot();
}
document.getElementById('wb-delete').addEventListener('click', deleteSelected);

// ── Object ordering ──────────────────────────────────
document.getElementById('wb-bring-fwd').addEventListener('click', function() {
  var o = canvas.getActiveObject(); if (o) { canvas.bringForward(o); snapshot(); }
});
document.getElementById('wb-send-bwd').addEventListener('click', function() {
  var o = canvas.getActiveObject(); if (o) { canvas.sendBackwards(o); snapshot(); }
});
document.getElementById('wb-group-sel').addEventListener('click', function() {
  if (canvas.getActiveObjects().length < 2) return;
  canvas.getActiveObject().toGroup();
  snapshot();
});

// ── Zoom ─────────────────────────────────────────────
var zoomLevel = 1;
function applyZoom(z) {
  zoomLevel = Math.max(0.2, Math.min(5, z));
  canvas.setZoom(zoomLevel);
  document.getElementById('wb-status-zoom').textContent =
    'Zoom: ' + Math.round(zoomLevel * 100) + '%';
}
document.getElementById('wb-zoom-in').addEventListener('click', function()  { applyZoom(zoomLevel * 1.2); });
document.getElementById('wb-zoom-out').addEventListener('click', function() { applyZoom(zoomLevel / 1.2); });
document.getElementById('wb-zoom-fit').addEventListener('click', function() { applyZoom(1); canvas.viewportTransform = [1,0,0,1,0,0]; canvas.renderAll(); });

// Mouse-wheel zoom
wrap.addEventListener('wheel', function(e) {
  e.preventDefault();
  applyZoom(zoomLevel * (e.deltaY < 0 ? 1.1 : 0.9));
}, { passive: false });

// ── Keyboard shortcuts ───────────────────────────────
document.addEventListener('keydown', function(e) {
  if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.tagName === 'SELECT') return;
  if (e.ctrlKey && e.key === 'z') { document.getElementById('wb-undo').click(); return; }
  if (e.ctrlKey && e.key === 'y') { document.getElementById('wb-redo').click(); return; }
  if (e.key === 'Delete' || e.key === 'Backspace') { deleteSelected(); return; }
  if (e.key === 'v' || e.key === 'V') { setTool('select'); }
  if (e.key === 'p' || e.key === 'P') { setTool('pen'); }
  if (e.key === 'r' || e.key === 'R') { setTool('rect'); }
  if (e.key === 'e' || e.key === 'E') { setTool('ellipse'); }
  if (e.key === 'd' || e.key === 'D') { setTool('diamond'); }
  if (e.key === 'a' || e.key === 'A') { setTool('arrow'); }
  if (e.key === 'l' || e.key === 'L') { setTool('line'); }
  if (e.key === 't' || e.key === 'T') { setTool('text'); }
});

// ── Status bar update ────────────────────────────────
function updateStatus() {
  document.getElementById('wb-status-objs').textContent =
    'Objects: ' + canvas.getObjects().length;
}
canvas.on('object:added',   updateStatus);
canvas.on('object:removed', updateStatus);

// ── Save helpers ─────────────────────────────────────
function getFilename() {
  var f = document.getElementById('wb-filename').value.trim();
  return f.length > 0 ? f : 'ml_design_diagram';
}

function showStatus(msg, color) {
  var el = document.getElementById('wb-save-status');
  el.textContent = msg;
  el.style.color  = color || '#4ade80';
  setTimeout(function() { el.textContent = ''; }, 4000);
}

// PNG — uses File System Access API (Chrome/Edge) with fallback
document.getElementById('wb-btn-png').addEventListener('click', async function() {
  var dataURL = canvas.toDataURL({ format: 'png', multiplier: 2 });
  var filename = getFilename() + '.png';
  await saveFile(dataURL, filename, 'image/png', 'png');
});

// JPG
document.getElementById('wb-btn-jpg').addEventListener('click', async function() {
  // Ensure white bg for JPG
  var orig = canvas.backgroundColor;
  canvas.setBackgroundColor('#ffffff', function() {});
  var dataURL = canvas.toDataURL({ format: 'jpeg', quality: 0.95, multiplier: 2 });
  canvas.setBackgroundColor(orig, canvas.renderAll.bind(canvas));
  var filename = getFilename() + '.jpg';
  await saveFile(dataURL, filename, 'image/jpeg', 'jpg');
});

// PDF via jsPDF
document.getElementById('wb-btn-pdf').addEventListener('click', async function() {
  try {
    var { jsPDF } = window.jspdf;
    var w = canvas.getWidth(), h = canvas.getHeight();
    var orientation = w > h ? 'landscape' : 'portrait';
    var doc = new jsPDF({ orientation: orientation, unit: 'px', format: [w, h] });
    var imgData = canvas.toDataURL({ format: 'jpeg', quality: 0.95, multiplier: 2 });
    doc.addImage(imgData, 'JPEG', 0, 0, w, h);
    var filename = getFilename() + '.pdf';
    await savePDF(doc, filename);
  } catch(err) {
    showStatus('PDF error: ' + err.message, '#f87171');
  }
});

// Save image using File System Access API (browse dialog) or fallback
async function saveFile(dataURL, filename, mimeType, ext) {
  try {
    if (window.showSaveFilePicker) {
      // Modern browsers (Chrome / Edge on Windows) — shows native Save As dialog
      var extMap = { png: [{description:'PNG Image',accept:{'image/png':['.png']}}],
                     jpg: [{description:'JPEG Image',accept:{'image/jpeg':['.jpg','.jpeg']}}] };
      var handle = await window.showSaveFilePicker({
        suggestedName: filename,
        types: extMap[ext] || extMap['png']
      });
      var writable = await handle.createWritable();
      var blob = dataURLtoBlob(dataURL, mimeType);
      await writable.write(blob);
      await writable.close();
      showStatus('Saved: ' + handle.name, '#4ade80');
    } else {
      // Fallback: trigger download
      var a = document.createElement('a');
      a.href = dataURL; a.download = filename; a.click();
      showStatus('Downloaded: ' + filename + ' (no folder picker in this browser)', '#fbbf24');
    }
  } catch(err) {
    if (err.name !== 'AbortError') {
      showStatus('Save error: ' + err.message, '#f87171');
    }
  }
}

async function savePDF(doc, filename) {
  try {
    if (window.showSaveFilePicker) {
      var handle = await window.showSaveFilePicker({
        suggestedName: filename,
        types: [{ description: 'PDF Document', accept: { 'application/pdf': ['.pdf'] } }]
      });
      var writable = await handle.createWritable();
      var blob = doc.output('blob');
      await writable.write(blob);
      await writable.close();
      showStatus('Saved: ' + handle.name, '#4ade80');
    } else {
      doc.save(filename);
      showStatus('Downloaded: ' + filename, '#fbbf24');
    }
  } catch(err) {
    if (err.name !== 'AbortError') showStatus('PDF save error: ' + err.message, '#f87171');
  }
}

function dataURLtoBlob(dataURL, mimeType) {
  var parts = dataURL.split(',');
  var byteString = atob(parts[1]);
  var arr = new Uint8Array(byteString.length);
  for (var i = 0; i < byteString.length; i++) arr[i] = byteString.charCodeAt(i);
  return new Blob([arr], { type: mimeType });
}

// ── Clear all ────────────────────────────────────────
document.getElementById('wb-btn-clear').addEventListener('click', function() {
  if (!confirm('Clear the entire canvas? This cannot be undone.')) return;
  snapshot();   // save before clearing (allow undo)
  canvas.clear();
  canvas.setBackgroundColor(
    document.getElementById('wb-bg-color').value,
    canvas.renderAll.bind(canvas)
  );
  updateStatus();
  showStatus('Canvas cleared.', '#aaa');
});

// ── Initial state ────────────────────────────────────
setTool('select');
snapshot();   // empty baseline for undo

}); // end waitForLibs
})(); // end IIFE
"))

  ) # end tagList
}

ml_design_whiteboard_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    prep_manager$update_progress("ml_design_whiteboard", 50)
  })
}
