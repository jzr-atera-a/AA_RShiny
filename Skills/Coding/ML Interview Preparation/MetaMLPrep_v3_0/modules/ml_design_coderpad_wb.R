# modules/ml_design_coderpad_wb.R
# CoderPad-style clean professional whiteboard for ML Design interviews
# Clean geometric shapes, grid background, ML system component templates
# Fabric.js v5 + jsPDF — save PNG/JPG/PDF via blob download

ml_design_coderpad_wb_ui <- function(id) {
  ns <- NS(id)

  tagList(

    # ── CDN libs ─────────────────────────────────────────────────────────────
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/fabric.js/5.3.1/fabric.min.js"),
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"),

    # ── CSS ───────────────────────────────────────────────────────────────────
    tags$style(HTML("
      #cpwb-shell {
        display: flex;
        flex-direction: column;
        height: calc(100vh - 102px);
        background: #0f172a;
        border-radius: 12px;
        overflow: hidden;
        box-shadow: 0 8px 32px rgba(0,0,0,0.5);
        font-family: 'Segoe UI', -apple-system, sans-serif;
      }
      #cpwb-topbar {
        background: #1e293b;
        border-bottom: 1px solid #334155;
        padding: 0 12px;
        height: 42px;
        display: flex;
        align-items: center;
        gap: 4px;
        flex-shrink: 0;
      }
      .cpwb-btn {
        background: transparent;
        border: 1px solid transparent;
        border-radius: 6px;
        color: #94a3b8;
        padding: 5px 10px;
        cursor: pointer;
        font-size: 12px;
        font-weight: 600;
        white-space: nowrap;
        transition: all 0.12s;
        user-select: none;
      }
      .cpwb-btn:hover  { background: #334155; color: #e2e8f0; border-color: #475569; }
      .cpwb-btn.active { background: #1d4ed8; color: #fff;    border-color: #3b82f6; }
      .cpwb-btn.danger { color: #f87171; }
      .cpwb-btn.danger:hover { background:#450a0a; border-color:#f87171; }
      .cpwb-btn.save  { background:#065f46; color:#4ade80; border-color:#4ade80; }
      .cpwb-btn.save:hover { background:#047857; }
      .cpwb-sep { width:1px; height:24px; background:#334155; margin:0 3px; flex-shrink:0; }
      .cpwb-label { font-size:11px; color:#64748b; white-space:nowrap; margin:0 2px; }

      #cpwb-body {
        display: flex;
        flex: 1;
        overflow: hidden;
      }
      #cpwb-sidebar {
        width: 200px;
        background: #1e293b;
        border-right: 1px solid #334155;
        overflow-y: auto;
        flex-shrink: 0;
        padding: 10px 8px;
      }
      .cpwb-side-heading {
        font-size: 10px;
        font-weight: 700;
        letter-spacing: 0.1em;
        text-transform: uppercase;
        color: #475569;
        margin: 10px 4px 6px;
      }
      .cpwb-component-btn {
        display: block;
        width: 100%;
        background: #0f172a;
        border: 1px solid #334155;
        border-radius: 6px;
        color: #94a3b8;
        padding: 7px 10px;
        margin-bottom: 4px;
        cursor: pointer;
        font-size: 11px;
        font-weight: 600;
        text-align: left;
        transition: all 0.12s;
      }
      .cpwb-component-btn:hover { background:#1d4ed8; color:#fff; border-color:#3b82f6; }
      .cpwb-color-row { display:flex; gap:5px; flex-wrap:wrap; padding:4px 0; }
      .cpwb-color-dot {
        width:20px; height:20px; border-radius:50%;
        border:2px solid #334155; cursor:pointer;
        transition: border-color 0.12s;
      }
      .cpwb-color-dot.active { border-color:#3b82f6; }
      .cpwb-range { width:100%; accent-color:#3b82f6; margin:4px 0; }

      #cpwb-canvas-wrap {
        flex: 1;
        position: relative;
        overflow: hidden;
      }
      #cpwb-canvas {
        position: absolute;
        top: 0; left: 0;
      }
      #cpwb-statusbar {
        background: #1e293b;
        border-top: 1px solid #334155;
        padding: 4px 14px;
        font-size: 11px;
        color: #64748b;
        display: flex;
        gap: 20px;
        flex-shrink: 0;
      }
      .cpwb-fname {
        background: #0f172a;
        border: 1px solid #334155;
        border-radius: 5px;
        color: #e2e8f0;
        padding: 3px 8px;
        font-size: 11px;
        width: 130px;
      }
    ")),

    div(id = "cpwb-shell",

      # ── Top toolbar ────────────────────────────────────────────────────────
      div(id = "cpwb-topbar",

        # Tools
        tags$button(id="cpwb-btn-select",  class="cpwb-btn active",  "⬆ Select"),
        tags$button(id="cpwb-btn-pen",     class="cpwb-btn",         "✏ Pen"),
        tags$button(id="cpwb-btn-rect",    class="cpwb-btn",         "▭ Rect"),
        tags$button(id="cpwb-btn-ellipse", class="cpwb-btn",         "◯ Ellipse"),
        tags$button(id="cpwb-btn-diamond", class="cpwb-btn",         "◇ Diamond"),
        tags$button(id="cpwb-btn-arrow",   class="cpwb-btn",         "→ Arrow"),
        tags$button(id="cpwb-btn-text",    class="cpwb-btn",         "T Text"),

        div(class="cpwb-sep"),

        # Edit
        tags$button(id="cpwb-btn-undo",   class="cpwb-btn",          "↩ Undo"),
        tags$button(id="cpwb-btn-redo",   class="cpwb-btn",          "↪ Redo"),
        tags$button(id="cpwb-btn-delete", class="cpwb-btn danger",   "🗑 Del"),
        tags$button(id="cpwb-btn-clear",  class="cpwb-btn danger",   "✕ Clear"),

        div(class="cpwb-sep"),

        # Zoom
        tags$button(id="cpwb-zoom-in",  class="cpwb-btn", "＋"),
        tags$button(id="cpwb-zoom-out", class="cpwb-btn", "－"),
        tags$button(id="cpwb-zoom-fit", class="cpwb-btn", "⊡ Fit"),

        div(class="cpwb-sep"),

        # Background
        span(class="cpwb-label", "BG:"),
        tags$button(id="cpwb-bg-grid",  class="cpwb-btn active", "Grid"),
        tags$button(id="cpwb-bg-dark",  class="cpwb-btn",        "Dark"),
        tags$button(id="cpwb-bg-white", class="cpwb-btn",        "White"),

        div(class="cpwb-sep"),

        # Save controls
        tags$input(type="text", id="cpwb-filename", class="cpwb-fname",
                   placeholder="diagram", value="ml_system"),
        tags$button(id="cpwb-save-png", class="cpwb-btn save", "⬇ PNG"),
        tags$button(id="cpwb-save-jpg", class="cpwb-btn save", "⬇ JPG"),
        tags$button(id="cpwb-save-pdf", class="cpwb-btn save", "⬇ PDF")
      ),

      # ── Body: sidebar + canvas ─────────────────────────────────────────────
      div(id = "cpwb-body",

        # Left panel — component library + style controls
        div(id = "cpwb-sidebar",

          div(class="cpwb-side-heading", "ML Components"),
          tags$button(class="cpwb-component-btn", id="cmp-feature-store",  "🗄 Feature Store"),
          tags$button(class="cpwb-component-btn", id="cmp-model-server",   "⚙ Model Server"),
          tags$button(class="cpwb-component-btn", id="cmp-data-pipeline",  "→ Data Pipeline"),
          tags$button(class="cpwb-component-btn", id="cmp-embedding",      "◉ Embedding Layer"),
          tags$button(class="cpwb-component-btn", id="cmp-candidate-gen",  "⬡ Candidate Gen"),
          tags$button(class="cpwb-component-btn", id="cmp-ranker",         "↑ Ranker"),
          tags$button(class="cpwb-component-btn", id="cmp-database",       "⬛ Database"),
          tags$button(class="cpwb-component-btn", id="cmp-user-client",    "👤 User / Client"),
          tags$button(class="cpwb-component-btn", id="cmp-api-gateway",    "◈ API Gateway"),
          tags$button(class="cpwb-component-btn", id="cmp-cache",          "⚡ Cache"),
          tags$button(class="cpwb-component-btn", id="cmp-message-queue",  "≡ Message Queue"),
          tags$button(class="cpwb-component-btn", id="cmp-monitoring",     "📊 Monitoring"),
          tags$button(class="cpwb-component-btn", id="cmp-offline-store",  "💾 Offline Store"),
          tags$button(class="cpwb-component-btn", id="cmp-online-store",   "⚡ Online Store"),
          tags$button(class="cpwb-component-btn", id="cmp-training",       "🧠 Training Job"),
          tags$button(class="cpwb-component-btn", id="cmp-eval",           "✓ Eval / A-B Test"),

          div(class="cpwb-side-heading", "Stroke Colour"),
          div(class="cpwb-color-row",
            tags$div(id="cc-white",  class="cpwb-color-dot active", style="background:#e2e8f0;"),
            tags$div(id="cc-blue",   class="cpwb-color-dot",        style="background:#3b82f6;"),
            tags$div(id="cc-green",  class="cpwb-color-dot",        style="background:#4ade80;"),
            tags$div(id="cc-red",    class="cpwb-color-dot",        style="background:#f87171;"),
            tags$div(id="cc-amber",  class="cpwb-color-dot",        style="background:#fbbf24;"),
            tags$div(id="cc-purple", class="cpwb-color-dot",        style="background:#a78bfa;"),
            tags$div(id="cc-cyan",   class="cpwb-color-dot",        style="background:#67e8f9;")
          ),

          div(class="cpwb-side-heading", "Fill Colour"),
          div(class="cpwb-color-row",
            tags$div(id="cf-none",   class="cpwb-color-dot active", style="background:transparent;border-style:dashed;", title="No fill"),
            tags$div(id="cf-blue",   class="cpwb-color-dot",        style="background:rgba(59,130,246,0.2);"),
            tags$div(id="cf-green",  class="cpwb-color-dot",        style="background:rgba(74,222,128,0.2);"),
            tags$div(id="cf-red",    class="cpwb-color-dot",        style="background:rgba(248,113,113,0.2);"),
            tags$div(id="cf-amber",  class="cpwb-color-dot",        style="background:rgba(251,191,36,0.2);"),
            tags$div(id="cf-purple", class="cpwb-color-dot",        style="background:rgba(167,139,250,0.2);")
          ),

          div(class="cpwb-side-heading", "Stroke Width"),
          tags$input(type="range", id="cpwb-stroke-w", class="cpwb-range",
                     min="1", max="8", value="2"),

          div(class="cpwb-side-heading", "Font Size"),
          tags$input(type="range", id="cpwb-font-size", class="cpwb-range",
                     min="10", max="36", value="14")
        ),

        # Canvas
        div(id = "cpwb-canvas-wrap",
            tags$canvas(id = "cpwb-canvas")
        )
      ),

      # ── Status bar ──────────────────────────────────────────────────────────
      div(id = "cpwb-statusbar",
          tags$span(id="cpwb-status-tool",    "Tool: select"),
          tags$span(id="cpwb-status-zoom",    "Zoom: 100%"),
          tags$span(id="cpwb-status-objects", "Objects: 0"),
          tags$span(id="cpwb-status-cursor",  "x: 0  y: 0"),
          tags$span(style="margin-left:auto;color:#3b82f6;font-weight:700;",
                    "CoderPad-style ML Design Whiteboard")
      )
    ),

    # ── Fabric.js + logic ────────────────────────────────────────────────────
    tags$script(HTML("
(function() {

var fc;          // Fabric canvas
var tool        = 'select';
var strokeColor = '#e2e8f0';
var fillColor   = 'transparent';
var strokeWidth = 2;
var fontSize    = 14;
var bgStyle     = 'grid';
var zoom        = 1;
var isDown      = false;
var origX, origY;
var activeShape = null;
var drawingLine = null;

var COMPONENT_COLORS = {
  'Feature Store':   '#3b82f6', 'Model Server': '#4ade80',
  'Data Pipeline':   '#fbbf24', 'Embedding Layer':'#a78bfa',
  'Candidate Gen':   '#67e8f9', 'Ranker':        '#f87171',
  'Database':        '#94a3b8', 'User / Client': '#4ade80',
  'API Gateway':     '#3b82f6', 'Cache':         '#fbbf24',
  'Message Queue':   '#a78bfa', 'Monitoring':    '#67e8f9',
  'Offline Store':   '#94a3b8', 'Online Store':  '#fbbf24',
  'Training Job':    '#4ade80', 'Eval / A-B Test':'#f87171'
};

// ── Init ─────────────────────────────────────────────────────────────────
function init() {
  if (typeof fabric === 'undefined') return setTimeout(init, 100);
  var wrap = document.getElementById('cpwb-canvas-wrap');
  if (!wrap) return setTimeout(init, 100);

  var W = wrap.clientWidth  || 1000;
  var H = wrap.clientHeight || 650;

  var el = document.getElementById('cpwb-canvas');
  el.width = W; el.height = H;

  fc = new fabric.Canvas('cpwb-canvas', {
    width: W, height: H,
    backgroundColor: '#0f172a',
    selection: true,
    preserveObjectStacking: true
  });

  drawGridBg();
  bindFabricEvents();
  bindToolbar();
  updateStatus();

  window.addEventListener('resize', function() {
    var W2 = wrap.clientWidth, H2 = wrap.clientHeight;
    fc.setWidth(W2); fc.setHeight(H2);
    drawGridBg(); fc.renderAll();
  });
}

// ── Grid background ───────────────────────────────────────────────────────
function drawGridBg() {
  if (bgStyle === 'grid') {
    var W=fc.width, H=fc.height, step=28;
    var lines=[];
    for(var x=0;x<W;x+=step) lines.push('M '+x+' 0 L '+x+' '+H);
    for(var y=0;y<H;y+=step) lines.push('M 0 '+y+' L '+W+' '+y);
    fc.backgroundColor = new fabric.Pattern({
      source: (function(){
        var c2=document.createElement('canvas'); c2.width=step; c2.height=step;
        var ctx2=c2.getContext('2d');
        ctx2.strokeStyle='rgba(51,65,85,0.6)'; ctx2.lineWidth=0.5;
        ctx2.beginPath(); ctx2.moveTo(step,0); ctx2.lineTo(step,step); ctx2.stroke();
        ctx2.beginPath(); ctx2.moveTo(0,step); ctx2.lineTo(step,step); ctx2.stroke();
        return c2;
      })(),
      repeat: 'repeat'
    });
  } else if (bgStyle === 'dark') {
    fc.backgroundColor = '#0f172a';
  } else {
    fc.backgroundColor = '#f8fafc';
  }
  fc.renderAll();
}

// ── Tool switching ────────────────────────────────────────────────────────
function setTool(t) {
  tool = t;
  fc.isDrawingMode = (t === 'pen');
  fc.selection     = (t === 'select');
  fc.defaultCursor = t === 'select' ? 'default' : 'crosshair';
  if (t === 'pen') {
    fc.freeDrawingBrush.color = strokeColor;
    fc.freeDrawingBrush.width = strokeWidth;
  }
  document.querySelectorAll('.cpwb-btn').forEach(function(b){
    if (['cpwb-btn-select','cpwb-btn-pen','cpwb-btn-rect',
         'cpwb-btn-ellipse','cpwb-btn-diamond','cpwb-btn-arrow',
         'cpwb-btn-text'].includes(b.id)) b.classList.remove('active');
  });
  var m = {select:'cpwb-btn-select',pen:'cpwb-btn-pen',rect:'cpwb-btn-rect',
            ellipse:'cpwb-btn-ellipse',diamond:'cpwb-btn-diamond',
            arrow:'cpwb-btn-arrow',text:'cpwb-btn-text'};
  if (m[t]) document.getElementById(m[t]).classList.add('active');
  document.getElementById('cpwb-status-tool').textContent = 'Tool: '+t;
}

// ── Fabric mouse events ───────────────────────────────────────────────────
function bindFabricEvents() {

  fc.on('mouse:down', function(opt) {
    if (tool==='select'||tool==='pen') return;
    var p = fc.getPointer(opt.e);
    isDown=true; origX=p.x; origY=p.y;

    if (tool==='text') {
      var txt = new fabric.IText('Label', {
        left: p.x, top: p.y,
        fill: strokeColor, fontSize: fontSize,
        fontFamily: 'Segoe UI, monospace',
        fontWeight: '600',
        selectable: true, editable: true
      });
      fc.add(txt); fc.setActiveObject(txt);
      txt.enterEditing(); txt.selectAll();
      isDown=false; return;
    }

    if (tool==='arrow') {
      drawingLine = new fabric.Line([p.x,p.y,p.x,p.y],{
        stroke:strokeColor, strokeWidth:strokeWidth,
        selectable:false, evented:false
      });
      fc.add(drawingLine); return;
    }

    if (tool==='rect') {
      activeShape = new fabric.Rect({
        left:p.x, top:p.y, width:0, height:0,
        stroke:strokeColor, strokeWidth:strokeWidth,
        fill:fillColor, selectable:false, evented:false
      });
    } else if (tool==='ellipse') {
      activeShape = new fabric.Ellipse({
        left:p.x, top:p.y, rx:0, ry:0,
        stroke:strokeColor, strokeWidth:strokeWidth,
        fill:fillColor, selectable:false, evented:false
      });
    } else if (tool==='diamond') {
      activeShape = new fabric.Polygon(
        [{x:0,y:-1},{x:1,y:0},{x:0,y:1},{x:-1,y:0}],
        { left:p.x, top:p.y, scaleX:0, scaleY:0,
          stroke:strokeColor, strokeWidth:strokeWidth,
          fill:fillColor, selectable:false, evented:false }
      );
    }
    if (activeShape) fc.add(activeShape);
  });

  fc.on('mouse:move', function(opt) {
    if (!isDown) {
      var p2 = fc.getPointer(opt.e);
      document.getElementById('cpwb-status-cursor').textContent =
        'x: '+Math.round(p2.x)+'  y: '+Math.round(p2.y);
      return;
    }
    var p = fc.getPointer(opt.e);
    var w = Math.abs(p.x-origX), h = Math.abs(p.y-origY);
    var l = Math.min(p.x,origX), t = Math.min(p.y,origY);

    if (tool==='arrow' && drawingLine) {
      drawingLine.set({x2:p.x, y2:p.y}); fc.renderAll(); return;
    }
    if (!activeShape) return;

    if (tool==='rect') {
      activeShape.set({left:l,top:t,width:w,height:h});
    } else if (tool==='ellipse') {
      activeShape.set({left:l,top:t,rx:w/2,ry:h/2});
    } else if (tool==='diamond') {
      activeShape.set({left:origX,top:origY,scaleX:w/2,scaleY:h/2});
    }
    activeShape.setCoords(); fc.renderAll();
  });

  fc.on('mouse:up', function(opt) {
    if (!isDown) return;
    isDown = false;
    var p = fc.getPointer(opt.e);

    if (tool==='arrow' && drawingLine) {
      // Add proper arrow with triangle head
      var x1=drawingLine.x1,y1=drawingLine.y1,x2=drawingLine.x2,y2=drawingLine.y2;
      fc.remove(drawingLine); drawingLine=null;
      var angle=Math.atan2(y2-y1,x2-x1)*180/Math.PI;
      var line=new fabric.Line([x1,y1,x2,y2],{
        stroke:strokeColor,strokeWidth:strokeWidth,selectable:true
      });
      var head=new fabric.Triangle({
        width:12+strokeWidth*2, height:14+strokeWidth*2,
        fill:strokeColor, left:x2, top:y2,
        angle:angle+90, originX:'center', originY:'center',
        selectable:true
      });
      var grp=new fabric.Group([line,head],{selectable:true});
      fc.add(grp);
    }

    if (activeShape) {
      activeShape.set({selectable:true,evented:true});
      fc.setActiveObject(activeShape);
      activeShape=null;
    }
    setTool('select');
    updateStatus();
  });

  fc.on('path:created', function() { updateStatus(); });
  fc.on('object:added',   function() { updateStatus(); });
  fc.on('object:removed', function() { updateStatus(); });
}

function updateStatus() {
  document.getElementById('cpwb-status-objects').textContent =
    'Objects: '+fc.getObjects().length;
  document.getElementById('cpwb-status-zoom').textContent =
    'Zoom: '+Math.round(zoom*100)+'%';
}

// ── Component library ─────────────────────────────────────────────────────
function addComponent(label) {
  var color = COMPONENT_COLORS[label] || '#e2e8f0';
  var W=160, H=50;
  var rect = new fabric.Rect({width:W,height:H,
    fill:'rgba(15,23,42,0.8)',stroke:color,strokeWidth:2,
    rx:8,ry:8, originX:'center', originY:'center'});
  var text = new fabric.Text(label,{
    fill:color, fontSize:12, fontWeight:'700',
    fontFamily:'Segoe UI, monospace',
    originX:'center', originY:'center'});
  var grp = new fabric.Group([rect,text],{
    left: 60 + Math.random()*200,
    top:  60 + Math.random()*150,
    selectable:true
  });
  fc.add(grp); fc.setActiveObject(grp); fc.renderAll();
  updateStatus();
}

// ── Toolbar bindings ─────────────────────────────────────────────────────
function bindToolbar() {

  // Tools
  ['select','pen','rect','ellipse','diamond','arrow','text'].forEach(function(t){
    var el=document.getElementById('cpwb-btn-'+t);
    if(el) el.onclick=function(){setTool(t);};
  });

  // Edit
  document.getElementById('cpwb-btn-undo').onclick = function() { fc.undo && fc.undo(); };
  document.getElementById('cpwb-btn-redo').onclick = function() { fc.redo && fc.redo(); };
  document.getElementById('cpwb-btn-delete').onclick = function() {
    var obj=fc.getActiveObject();
    if(obj){ fc.remove(obj); if(obj._objects) obj._objects.forEach(function(o){fc.remove(o);}); fc.discardActiveObject(); fc.renderAll(); updateStatus(); }
  };
  document.getElementById('cpwb-btn-clear').onclick = function() {
    if(confirm('Clear all objects?')){ fc.clear(); drawGridBg(); updateStatus(); }
  };

  // Zoom
  document.getElementById('cpwb-zoom-in').onclick  = function(){ zoom=Math.min(zoom*1.2,5); fc.setZoom(zoom); updateStatus(); };
  document.getElementById('cpwb-zoom-out').onclick = function(){ zoom=Math.max(zoom/1.2,0.2); fc.setZoom(zoom); updateStatus(); };
  document.getElementById('cpwb-zoom-fit').onclick = function(){ zoom=1; fc.setZoom(1); fc.viewportTransform=[1,0,0,1,0,0]; fc.renderAll(); updateStatus(); };

  // Background
  ['grid','dark','white'].forEach(function(bg){
    var el=document.getElementById('cpwb-bg-'+bg);
    if(el) el.onclick=function(){
      bgStyle=bg;
      document.querySelectorAll('#cpwb-topbar .cpwb-btn').forEach(function(b){
        if(['cpwb-bg-grid','cpwb-bg-dark','cpwb-bg-white'].includes(b.id)) b.classList.remove('active');
      });
      this.classList.add('active');
      drawGridBg();
    };
  });

  // Stroke colours
  var sMap={'cc-white':'#e2e8f0','cc-blue':'#3b82f6','cc-green':'#4ade80',
            'cc-red':'#f87171','cc-amber':'#fbbf24','cc-purple':'#a78bfa','cc-cyan':'#67e8f9'};
  Object.keys(sMap).forEach(function(id){
    var el=document.getElementById(id);
    if(!el) return;
    el.onclick=function(){
      strokeColor=sMap[id];
      document.querySelectorAll('.cpwb-color-row .cpwb-color-dot').forEach(function(d){
        if(d.id.startsWith('cc')) d.classList.remove('active');
      });
      this.classList.add('active');
      if(fc.isDrawingMode){ fc.freeDrawingBrush.color=strokeColor; }
      // Update selected object
      var o=fc.getActiveObject();
      if(o){ o.set({stroke:strokeColor}); fc.renderAll(); }
    };
  });

  // Fill colours
  var fMap={'cf-none':'transparent','cf-blue':'rgba(59,130,246,0.2)',
            'cf-green':'rgba(74,222,128,0.2)','cf-red':'rgba(248,113,113,0.2)',
            'cf-amber':'rgba(251,191,36,0.2)','cf-purple':'rgba(167,139,250,0.2)'};
  Object.keys(fMap).forEach(function(id){
    var el=document.getElementById(id);
    if(!el) return;
    el.onclick=function(){
      fillColor=fMap[id];
      document.querySelectorAll('.cpwb-color-row .cpwb-color-dot').forEach(function(d){
        if(d.id.startsWith('cf')) d.classList.remove('active');
      });
      this.classList.add('active');
      var o=fc.getActiveObject();
      if(o){ o.set({fill:fillColor}); fc.renderAll(); }
    };
  });

  // Stroke width
  document.getElementById('cpwb-stroke-w').oninput=function(){
    strokeWidth=parseInt(this.value);
    if(fc.isDrawingMode) fc.freeDrawingBrush.width=strokeWidth;
    var o=fc.getActiveObject();
    if(o){ o.set({strokeWidth:strokeWidth}); fc.renderAll(); }
  };

  // Font size
  document.getElementById('cpwb-font-size').oninput=function(){
    fontSize=parseInt(this.value);
    var o=fc.getActiveObject();
    if(o&&(o.type==='i-text'||o.type==='text')){ o.set({fontSize:fontSize}); fc.renderAll(); }
  };

  // Component buttons
  var compMap={
    'cmp-feature-store':'Feature Store','cmp-model-server':'Model Server',
    'cmp-data-pipeline':'Data Pipeline','cmp-embedding':'Embedding Layer',
    'cmp-candidate-gen':'Candidate Gen','cmp-ranker':'Ranker',
    'cmp-database':'Database','cmp-user-client':'User / Client',
    'cmp-api-gateway':'API Gateway','cmp-cache':'Cache',
    'cmp-message-queue':'Message Queue','cmp-monitoring':'Monitoring',
    'cmp-offline-store':'Offline Store','cmp-online-store':'Online Store',
    'cmp-training':'Training Job','cmp-eval':'Eval / A-B Test'
  };
  Object.keys(compMap).forEach(function(id){
    var el=document.getElementById(id);
    if(el) el.onclick=function(){ addComponent(compMap[id]); };
  });

  // Keyboard shortcuts
  document.addEventListener('keydown', function(e) {
    if(e.target.tagName==='INPUT'||e.target.tagName==='TEXTAREA') return;
    var k=e.key.toLowerCase();
    var m={s:'select',p:'pen',r:'rect',e:'ellipse',d:'diamond',a:'arrow',t:'text'};
    if(m[k]&&!e.ctrlKey&&!e.metaKey) setTool(m[k]);
    if((e.ctrlKey||e.metaKey)&&k==='z') { /* fabric undo not built-in, skip */ }
    if((k==='delete'||k==='backspace')&&document.activeElement===document.body){
      var obj=fc.getActiveObject();
      if(obj){ fc.remove(obj); fc.discardActiveObject(); fc.renderAll(); updateStatus(); }
    }
    if(k==='+'||k==='='){ zoom=Math.min(zoom*1.15,5); fc.setZoom(zoom); updateStatus(); }
    if(k==='-'){           zoom=Math.max(zoom/1.15,0.2); fc.setZoom(zoom); updateStatus(); }
  });

  // Mouse wheel zoom
  fc.on('mouse:wheel', function(opt){
    opt.e.preventDefault();
    var delta=opt.e.deltaY>0?0.9:1.1;
    zoom=Math.min(Math.max(zoom*delta,0.2),5);
    fc.setZoom(zoom); updateStatus();
  });

  // Save
  document.getElementById('cpwb-save-png').onclick=function(){saveImg('png');};
  document.getElementById('cpwb-save-jpg').onclick=function(){saveImg('jpg');};
  document.getElementById('cpwb-save-pdf').onclick=function(){savePDF();};
}

function getFilename(ext){
  var f=(document.getElementById('cpwb-filename').value||'ml_system').trim();
  return f+'.'+ext;
}

function saveImg(fmt){
  var mime=fmt==='jpg'?'image/jpeg':'image/png';
  var dataURL=fc.toDataURL({format:fmt,quality:0.95,multiplier:1});
  var a=document.createElement('a');
  a.href=dataURL; a.download=getFilename(fmt);
  document.body.appendChild(a); a.click(); document.body.removeChild(a);
}

function savePDF(){
  if(!window.jspdf&&!window.jsPDF){ alert('jsPDF not loaded yet.'); return; }
  var jsPDF=(window.jspdf||window.jsPDF).jsPDF||(window.jspdf||window.jsPDF);
  var W=fc.width, H=fc.height;
  var doc=new jsPDF({orientation:W>H?'landscape':'portrait',unit:'px',format:[W,H]});
  doc.addImage(fc.toDataURL({format:'jpeg',quality:0.92}),'JPEG',0,0,W,H);
  doc.save(getFilename('pdf'));
}

// Boot
if(document.readyState==='loading'){
  document.addEventListener('DOMContentLoaded', init);
} else {
  setTimeout(init, 120);
}

})();
    "))

  ) # end tagList
}

ml_design_coderpad_wb_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    prep_manager$update_progress("ml_design_coderpad_wb", 10)
  })
}
