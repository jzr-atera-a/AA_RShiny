# modules/ml_design_excalidraw.R
# Excalidraw-style hand-drawn whiteboard for ML Design interview practice
# Uses Rough.js (sketchy rendering) + perfect-freehand + jsPDF
# Save as PNG / JPG / PDF via blob download (works inside Shiny iframes)

ml_design_excalidraw_ui <- function(id) {
  ns <- NS(id)

  tagList(

    # ── CDN libs ────────────────────────────────────────────────────────────
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/roughjs/4.6.6/rough.min.js"),
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"),

    # ── CSS ──────────────────────────────────────────────────────────────────
    tags$style(HTML("
      #exc-shell {
        display: flex;
        flex-direction: column;
        height: calc(100vh - 102px);
        background: #1e1e2e;
        border-radius: 12px;
        overflow: hidden;
        box-shadow: 0 8px 32px rgba(0,0,0,0.4);
        font-family: 'Segoe UI', sans-serif;
      }
      #exc-toolbar {
        background: #2a2a3e;
        border-bottom: 1px solid #3d3d5c;
        padding: 8px 14px;
        display: flex;
        align-items: center;
        gap: 6px;
        flex-wrap: wrap;
        flex-shrink: 0;
      }
      .exc-tool-btn {
        background: #3d3d5c;
        border: 1.5px solid transparent;
        border-radius: 8px;
        color: #c9d1d9;
        padding: 6px 11px;
        cursor: pointer;
        font-size: 13px;
        transition: all 0.15s;
        user-select: none;
      }
      .exc-tool-btn:hover  { background: #4f4f72; color: #fff; }
      .exc-tool-btn.active { background: #6c63ff; border-color: #a89dff; color: #fff; }
      .exc-sep {
        width: 1px; height: 26px;
        background: #3d3d5c;
        margin: 0 4px;
        flex-shrink: 0;
      }
      .exc-label {
        font-size: 11px;
        color: #888;
        white-space: nowrap;
      }
      .exc-color-btn {
        width: 24px; height: 24px;
        border-radius: 50%;
        border: 2px solid #3d3d5c;
        cursor: pointer;
        transition: border-color 0.15s;
        flex-shrink: 0;
      }
      .exc-color-btn.active { border-color: #6c63ff; }
      #exc-canvas-wrap {
        flex: 1;
        position: relative;
        overflow: hidden;
        cursor: crosshair;
      }
      #exc-canvas {
        position: absolute;
        top: 0; left: 0;
        touch-action: none;
      }
      #exc-statusbar {
        background: #2a2a3e;
        border-top: 1px solid #3d3d5c;
        padding: 5px 14px;
        font-size: 11px;
        color: #888;
        display: flex;
        gap: 20px;
        flex-shrink: 0;
      }
      .exc-save-name {
        background: #1e1e2e;
        border: 1px solid #3d3d5c;
        border-radius: 6px;
        color: #e6edf3;
        padding: 4px 8px;
        font-size: 12px;
        width: 130px;
      }
      .exc-stroke-range {
        width: 60px;
        accent-color: #6c63ff;
      }
    ")),

    div(id = "exc-shell",

      # ── Toolbar ──────────────────────────────────────────────────────────
      div(id = "exc-toolbar",

        # Tools
        tags$button(id="exc-btn-select", class="exc-tool-btn active",      title="Select (S)",    "⬆ Select"),
        tags$button(id="exc-btn-pen",    class="exc-tool-btn",             title="Freehand (P)",  "✏ Pen"),
        tags$button(id="exc-btn-rect",   class="exc-tool-btn",             title="Rectangle (R)", "▭ Rect"),
        tags$button(id="exc-btn-ellipse",class="exc-tool-btn",             title="Ellipse (E)",   "◯ Ellipse"),
        tags$button(id="exc-btn-diamond",class="exc-tool-btn",             title="Diamond (D)",   "◇ Diamond"),
        tags$button(id="exc-btn-arrow",  class="exc-tool-btn",             title="Arrow (A)",     "→ Arrow"),
        tags$button(id="exc-btn-line",   class="exc-tool-btn",             title="Line (L)",      "╱ Line"),
        tags$button(id="exc-btn-text",   class="exc-tool-btn",             title="Text (T)",      "T Text"),

        div(class="exc-sep"),

        # Stroke colours
        span(class="exc-label", "Stroke:"),
        tags$div(id="exc-col-black",  class="exc-color-btn active", style="background:#e6edf3;", title="White/Light"),
        tags$div(id="exc-col-blue",   class="exc-color-btn",        style="background:#6c63ff;", title="Purple"),
        tags$div(id="exc-col-green",  class="exc-color-btn",        style="background:#4ade80;", title="Green"),
        tags$div(id="exc-col-red",    class="exc-color-btn",        style="background:#f87171;", title="Red"),
        tags$div(id="exc-col-amber",  class="exc-color-btn",        style="background:#fbbf24;", title="Amber"),
        tags$div(id="exc-col-cyan",   class="exc-color-btn",        style="background:#67e8f9;", title="Cyan"),

        div(class="exc-sep"),

        # Stroke width
        span(class="exc-label", "Width:"),
        tags$input(type="range", id="exc-stroke-width",
                   class="exc-stroke-range",
                   min="1", max="8", value="2"),

        # Fill toggle
        tags$button(id="exc-btn-fill", class="exc-tool-btn", "Fill: Off"),

        # Background
        span(class="exc-label", "BG:"),
        tags$button(id="exc-bg-dark",   class="exc-tool-btn active", "Dark"),
        tags$button(id="exc-bg-white",  class="exc-tool-btn",        "White"),
        tags$button(id="exc-bg-grid",   class="exc-tool-btn",        "Grid"),

        div(class="exc-sep"),

        # Edit
        tags$button(id="exc-btn-undo",  class="exc-tool-btn", title="Undo Ctrl+Z", "↩ Undo"),
        tags$button(id="exc-btn-redo",  class="exc-tool-btn", title="Redo Ctrl+Y", "↪ Redo"),
        tags$button(id="exc-btn-delete",class="exc-tool-btn", title="Delete",      "🗑 Del"),
        tags$button(id="exc-btn-clear", class="exc-tool-btn", style="color:#f87171;", "✕ Clear"),

        div(class="exc-sep"),

        # Save
        tags$input(type="text", id="exc-filename", class="exc-save-name",
                   placeholder="diagram", value="ml_design"),
        tags$button(id="exc-save-png", class="exc-tool-btn", "⬇ PNG"),
        tags$button(id="exc-save-jpg", class="exc-tool-btn", "⬇ JPG"),
        tags$button(id="exc-save-pdf", class="exc-tool-btn", "⬇ PDF")
      ),

      # ── Canvas ────────────────────────────────────────────────────────────
      div(id = "exc-canvas-wrap",
          tags$canvas(id = "exc-canvas")
      ),

      # ── Status bar ───────────────────────────────────────────────────────
      div(id = "exc-statusbar",
          tags$span(id="exc-status-tool",    "Tool: Select"),
          tags$span(id="exc-status-objects", "Objects: 0"),
          tags$span(id="exc-status-cursor",  "x: 0  y: 0"),
          tags$span(style="margin-left:auto;color:#6c63ff;font-weight:700;",
                    "✏ Excalidraw-style — Hand-drawn ML Design Board")
      )
    ),

    # ── Main canvas logic ─────────────────────────────────────────────────
    tags$script(HTML("
(function() {

// ── State ────────────────────────────────────────────────────────────────
var canvas, ctx, rc;
var tool     = 'select';
var strokeColor = '#e6edf3';
var strokeWidth = 2;
var fillEnabled = false;
var fillColor   = 'rgba(108,99,255,0.15)';
var bgColor     = '#1e1e2e';
var isDrawing   = false;
var startX, startY;
var freePoints  = [];

// Object store + undo stack
var objects = [];
var undoStack = [];
var MAX_UNDO = 60;

// Selected object
var selectedIdx = -1;
var dragStartX, dragStartY;
var dragging = false;

// Text input
var activeTextEl = null;

// ── Rough.js seed (gives consistent sketchy appearance per object) ────────
function seedFrom(x,y,w,h){ return Math.abs(Math.round(x*31+y*17+w*7+h*3)) % 9999 + 1; }

// ── Init ─────────────────────────────────────────────────────────────────
function init() {
  canvas = document.getElementById('exc-canvas');
  if (!canvas) return setTimeout(init, 100);
  var wrap = document.getElementById('exc-canvas-wrap');
  canvas.width  = wrap.clientWidth  || 1200;
  canvas.height = wrap.clientHeight || 700;
  ctx = canvas.getContext('2d');
  if (window.rough) rc = rough.canvas(canvas);
  bindEvents();
  bindToolbar();
  render();
  window.addEventListener('resize', function() {
    canvas.width  = wrap.clientWidth;
    canvas.height = wrap.clientHeight;
    if (window.rough) rc = rough.canvas(canvas);
    render();
  });
}

// ── Snapshot for undo ────────────────────────────────────────────────────
function snapshot() {
  undoStack.push(JSON.parse(JSON.stringify(objects)));
  if (undoStack.length > MAX_UNDO) undoStack.shift();
}

// ── Render ───────────────────────────────────────────────────────────────
function render() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  // Background
  ctx.fillStyle = bgColor;
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  if (bgColor === '#f8f9fa') drawGrid();

  objects.forEach(function(obj, i) { drawObject(obj, i === selectedIdx); });
  updateStatus();
}

function drawGrid() {
  ctx.strokeStyle = 'rgba(108,99,255,0.15)';
  ctx.lineWidth   = 0.5;
  var step = 24;
  for (var x=0; x<canvas.width;  x+=step) { ctx.beginPath(); ctx.moveTo(x,0); ctx.lineTo(x,canvas.height); ctx.stroke(); }
  for (var y=0; y<canvas.height; y+=step) { ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(canvas.width,y); ctx.stroke(); }
}

function drawObject(obj, selected) {
  if (!rc) { drawFallback(obj); return; }
  var opts = {
    stroke: obj.color,
    strokeWidth: obj.strokeWidth || 2,
    roughness: 1.8,
    seed: obj.seed || 1,
    fill: obj.fill || 'none',
    fillStyle: 'hachure',
    fillWeight: 1.5,
    hachureGap: 8
  };

  if (obj.type === 'rect') {
    rc.rectangle(obj.x, obj.y, obj.w, obj.h, opts);
  } else if (obj.type === 'ellipse') {
    rc.ellipse(obj.x + obj.w/2, obj.y + obj.h/2, Math.abs(obj.w), Math.abs(obj.h), opts);
  } else if (obj.type === 'diamond') {
    var cx=obj.x+obj.w/2, cy=obj.y+obj.h/2, hw=Math.abs(obj.w/2), hh=Math.abs(obj.h/2);
    rc.polygon([[cx,cy-hh],[cx+hw,cy],[cx,cy+hh],[cx-hw,cy]], opts);
  } else if (obj.type === 'arrow' || obj.type === 'line') {
    rc.line(obj.x, obj.y, obj.x2, obj.y2, opts);
    if (obj.type === 'arrow') drawArrowHead(obj.x, obj.y, obj.x2, obj.y2, obj.color, obj.strokeWidth||2);
  } else if (obj.type === 'freehand') {
    if (obj.points && obj.points.length > 1) {
      ctx.beginPath();
      ctx.strokeStyle = obj.color;
      ctx.lineWidth   = obj.strokeWidth || 2;
      ctx.lineCap     = 'round';
      ctx.lineJoin    = 'round';
      ctx.moveTo(obj.points[0][0], obj.points[0][1]);
      obj.points.forEach(function(p){ ctx.lineTo(p[0],p[1]); });
      ctx.stroke();
    }
  } else if (obj.type === 'text') {
    ctx.fillStyle   = obj.color;
    ctx.font        = 'bold ' + (obj.fontSize||18) + 'px \"Segoe UI\", Caveat, cursive';
    ctx.fillText(obj.text || '', obj.x, obj.y);
  }

  if (selected) {
    var bounds = getBounds(obj);
    ctx.strokeStyle = '#6c63ff';
    ctx.lineWidth   = 1.5;
    ctx.setLineDash([5,3]);
    ctx.strokeRect(bounds.x-6, bounds.y-6, bounds.w+12, bounds.h+12);
    ctx.setLineDash([]);
  }
}

function drawArrowHead(x1,y1,x2,y2,color,w) {
  var angle = Math.atan2(y2-y1, x2-x1);
  var len   = 14 + w*2;
  ctx.beginPath();
  ctx.strokeStyle = color;
  ctx.lineWidth   = w;
  ctx.lineCap     = 'round';
  ctx.moveTo(x2, y2);
  ctx.lineTo(x2 - len*Math.cos(angle-0.4), y2 - len*Math.sin(angle-0.4));
  ctx.moveTo(x2, y2);
  ctx.lineTo(x2 - len*Math.cos(angle+0.4), y2 - len*Math.sin(angle+0.4));
  ctx.stroke();
}

function drawFallback(obj) {
  ctx.strokeStyle = obj.color; ctx.lineWidth = obj.strokeWidth || 2;
  if (obj.type==='rect')    { ctx.strokeRect(obj.x,obj.y,obj.w,obj.h); }
  else if (obj.type==='line'||obj.type==='arrow') {
    ctx.beginPath(); ctx.moveTo(obj.x,obj.y); ctx.lineTo(obj.x2,obj.y2); ctx.stroke();
  }
}

function getBounds(obj) {
  if (obj.type==='text')   return {x:obj.x,     y:obj.y-20,  w:120, h:30};
  if (obj.type==='arrow'||obj.type==='line')
                            return {x:Math.min(obj.x,obj.x2),y:Math.min(obj.y,obj.y2),
                                    w:Math.abs(obj.x2-obj.x),h:Math.abs(obj.y2-obj.y)};
  if (obj.type==='freehand') {
    if (!obj.points||!obj.points.length) return {x:0,y:0,w:0,h:0};
    var xs=obj.points.map(function(p){return p[0];}),ys=obj.points.map(function(p){return p[1];});
    var x=Math.min.apply(null,xs),y=Math.min.apply(null,ys);
    return {x:x,y:y,w:Math.max.apply(null,xs)-x,h:Math.max.apply(null,ys)-y};
  }
  return {x:obj.x, y:obj.y, w:obj.w||0, h:obj.h||0};
}

function hitTest(mx, my) {
  for (var i=objects.length-1; i>=0; i--) {
    var b = getBounds(objects[i]);
    if (mx>=b.x-8 && mx<=b.x+b.w+8 && my>=b.y-8 && my<=b.y+b.h+8) return i;
  }
  return -1;
}

// ── Pointer events ──────────────────────────────────────────────────────
function getXY(e) {
  var r = canvas.getBoundingClientRect();
  var src = e.touches ? e.touches[0] : e;
  return [src.clientX - r.left, src.clientY - r.top];
}

function onDown(e) {
  e.preventDefault();
  var xy = getXY(e); var mx=xy[0], my=xy[1];
  isDrawing = true; startX=mx; startY=my;

  if (tool==='select') {
    selectedIdx = hitTest(mx, my);
    dragging = selectedIdx >= 0;
    dragStartX=mx; dragStartY=my;
    render(); return;
  }
  if (tool==='text') { placeText(mx,my); isDrawing=false; return; }
  if (tool==='pen')  { freePoints=[[mx,my]]; return; }
  snapshot();
  objects.push(makeObj(tool, mx, my, mx, my));
}

function onMove(e) {
  e.preventDefault();
  var xy=getXY(e); var mx=xy[0], my=xy[1];
  document.getElementById('exc-status-cursor').textContent = 'x: '+Math.round(mx)+'  y: '+Math.round(my);
  if (!isDrawing) return;

  if (tool==='select' && dragging && selectedIdx>=0) {
    var obj=objects[selectedIdx], dx=mx-dragStartX, dy=my-dragStartY;
    obj.x+=dx; obj.y+=dy;
    if (obj.x2!==undefined){obj.x2+=dx; obj.y2+=dy;}
    if (obj.points) obj.points=obj.points.map(function(p){return [p[0]+dx,p[1]+dy];});
    dragStartX=mx; dragStartY=my;
    render(); return;
  }
  if (tool==='pen') { freePoints.push([mx,my]); renderLive(null); return; }

  var obj=objects[objects.length-1];
  updateObj(obj, startX, startY, mx, my);
  render();
}

function onUp(e) {
  if (!isDrawing) return;
  isDrawing=false;
  if (tool==='pen' && freePoints.length>1) {
    snapshot();
    objects.push({type:'freehand',points:freePoints.slice(),
                  color:strokeColor,strokeWidth:strokeWidth});
    freePoints=[];
  }
  if (tool!=='select') {
    var obj=objects[objects.length-1];
    if (obj && (obj.w===0||obj.h===0) && obj.type!=='arrow'&&obj.type!=='line') objects.pop();
  }
  render();
}

function renderLive(obj) {
  render();
  if (tool==='pen' && freePoints.length>1) {
    ctx.beginPath(); ctx.strokeStyle=strokeColor; ctx.lineWidth=strokeWidth;
    ctx.lineCap='round'; ctx.lineJoin='round';
    ctx.moveTo(freePoints[0][0],freePoints[0][1]);
    freePoints.forEach(function(p){ctx.lineTo(p[0],p[1]);});
    ctx.stroke();
  }
}

function makeObj(t,x1,y1,x2,y2) {
  var base={type:t,color:strokeColor,strokeWidth:strokeWidth,
            fill:fillEnabled?fillColor:'none',seed:seedFrom(x1,y1,x2-x1,y2-y1)};
  if (t==='arrow'||t==='line') return Object.assign(base,{x:x1,y:y1,x2:x2,y2:y2});
  return Object.assign(base,{x:x1,y:y1,w:x2-x1,h:y2-y1});
}
function updateObj(obj,x1,y1,x2,y2) {
  if (obj.type==='arrow'||obj.type==='line'){obj.x2=x2;obj.y2=y2;}
  else {obj.w=x2-x1;obj.h=y2-y1;}
}

function placeText(x,y) {
  if (activeTextEl) { activeTextEl.remove(); activeTextEl=null; }
  var inp=document.createElement('input');
  inp.type='text'; inp.placeholder='Type and Enter…';
  inp.style.cssText='position:absolute;left:'+(x-2)+'px;top:'+(y-20)+'px;'+
    'background:transparent;border:none;border-bottom:2px dashed '+strokeColor+';'+
    'color:'+strokeColor+';font:bold 18px \"Segoe UI\",cursive;'+
    'outline:none;min-width:160px;z-index:99;';
  document.getElementById('exc-canvas-wrap').appendChild(inp);
  inp.focus(); activeTextEl=inp;
  inp.addEventListener('keydown',function(e){
    if (e.key==='Enter'||e.key==='Escape') {
      if (e.key==='Enter' && inp.value.trim()) {
        snapshot();
        objects.push({type:'text',x:x,y:y,text:inp.value,
                      color:strokeColor,fontSize:18});
      }
      inp.remove(); activeTextEl=null; render();
    }
  });
}

function updateStatus() {
  document.getElementById('exc-status-tool').textContent    = 'Tool: '+tool;
  document.getElementById('exc-status-objects').textContent = 'Objects: '+objects.length;
}

// ── Toolbar bindings ────────────────────────────────────────────────────
function setTool(t) {
  tool=t;
  document.querySelectorAll('.exc-tool-btn').forEach(function(b){ b.classList.remove('active'); });
  var m={'select':'exc-btn-select','pen':'exc-btn-pen','rect':'exc-btn-rect',
         'ellipse':'exc-btn-ellipse','diamond':'exc-btn-diamond',
         'arrow':'exc-btn-arrow','line':'exc-btn-line','text':'exc-btn-text'};
  if (m[t]) document.getElementById(m[t]).classList.add('active');
  updateStatus();
}

function setColor(c) {
  strokeColor=c;
  document.querySelectorAll('.exc-color-btn').forEach(function(b){b.classList.remove('active');});
  var colorBtns={'#e6edf3':'exc-col-black','#6c63ff':'exc-col-blue','#4ade80':'exc-col-green',
                 '#f87171':'exc-col-red','#fbbf24':'exc-col-amber','#67e8f9':'exc-col-cyan'};
  if (colorBtns[c]) document.getElementById(colorBtns[c]).classList.add('active');
}

function bindToolbar() {
  var toolMap={
    'exc-btn-select':'select','exc-btn-pen':'pen','exc-btn-rect':'rect',
    'exc-btn-ellipse':'ellipse','exc-btn-diamond':'diamond',
    'exc-btn-arrow':'arrow','exc-btn-line':'line','exc-btn-text':'text'
  };
  Object.keys(toolMap).forEach(function(id){
    var el=document.getElementById(id);
    if(el) el.onclick=function(){setTool(toolMap[id]);};
  });

  var colorMap={
    'exc-col-black':'#e6edf3','exc-col-blue':'#6c63ff','exc-col-green':'#4ade80',
    'exc-col-red':'#f87171','exc-col-amber':'#fbbf24','exc-col-cyan':'#67e8f9'
  };
  Object.keys(colorMap).forEach(function(id){
    var el=document.getElementById(id);
    if(el) el.onclick=function(){setColor(colorMap[id]);};
  });

  var sw=document.getElementById('exc-stroke-width');
  if(sw) sw.oninput=function(){strokeWidth=parseInt(this.value);};

  var fb=document.getElementById('exc-btn-fill');
  if(fb) fb.onclick=function(){
    fillEnabled=!fillEnabled;
    this.textContent='Fill: '+(fillEnabled?'On':'Off');
    this.classList.toggle('active',fillEnabled);
  };

  // Backgrounds
  var bgMap={'exc-bg-dark':'#1e1e2e','exc-bg-white':'#f8f9fa','exc-bg-grid':'#f8f9fa'};
  Object.keys(bgMap).forEach(function(id){
    var el=document.getElementById(id);
    if(el) el.onclick=function(){
      bgColor=bgMap[id];
      document.querySelectorAll('#exc-toolbar .exc-tool-btn').forEach(function(b){
        if(['exc-bg-dark','exc-bg-white','exc-bg-grid'].includes(b.id)) b.classList.remove('active');
      });
      this.classList.add('active');
      render();
    };
  });

  var undo=document.getElementById('exc-btn-undo');
  if(undo) undo.onclick=function(){
    if(undoStack.length) { objects=undoStack.pop(); selectedIdx=-1; render(); }
  };
  var redo=document.getElementById('exc-btn-redo');
  if(redo) redo.onclick=function(){ /* simple undo only */ };

  var del=document.getElementById('exc-btn-delete');
  if(del) del.onclick=function(){
    if(selectedIdx>=0){ snapshot(); objects.splice(selectedIdx,1); selectedIdx=-1; render(); }
  };

  var clr=document.getElementById('exc-btn-clear');
  if(clr) clr.onclick=function(){
    if(confirm('Clear all objects?')){ snapshot(); objects=[]; selectedIdx=-1; render(); }
  };

  // Save
  document.getElementById('exc-save-png').onclick=function(){saveCanvas('png');};
  document.getElementById('exc-save-jpg').onclick=function(){saveCanvas('jpg');};
  document.getElementById('exc-save-pdf').onclick=function(){savePDF();};
}

function bindEvents() {
  canvas.addEventListener('mousedown',  onDown);
  canvas.addEventListener('mousemove',  onMove);
  canvas.addEventListener('mouseup',    onUp);
  canvas.addEventListener('touchstart', onDown, {passive:false});
  canvas.addEventListener('touchmove',  onMove, {passive:false});
  canvas.addEventListener('touchend',   onUp);

  document.addEventListener('keydown', function(e) {
    if (e.target.tagName==='INPUT'||e.target.tagName==='TEXTAREA') return;
    var k=e.key.toLowerCase();
    var map={s:'select',p:'pen',r:'rect',e:'ellipse',d:'diamond',a:'arrow',l:'line',t:'text'};
    if (map[k]) setTool(map[k]);
    if ((e.ctrlKey||e.metaKey) && k==='z') {
      if(undoStack.length){ objects=undoStack.pop(); selectedIdx=-1; render(); }
    }
    if (k==='delete'||k==='backspace') {
      if(selectedIdx>=0&&document.activeElement===document.body){
        snapshot(); objects.splice(selectedIdx,1); selectedIdx=-1; render();
      }
    }
  });
}

// ── Save ─────────────────────────────────────────────────────────────────
function getFilename(ext) {
  var f=(document.getElementById('exc-filename').value||'ml_design').trim();
  return f+'.'+ext;
}

function saveCanvas(fmt) {
  var mime=fmt==='jpg'?'image/jpeg':'image/png';
  var data=canvas.toDataURL(mime, 0.95);
  var a=document.createElement('a');
  a.href=data; a.download=getFilename(fmt);
  document.body.appendChild(a); a.click(); document.body.removeChild(a);
}

function savePDF() {
  if (!window.jspdf && !window.jsPDF) { alert('jsPDF not loaded yet, try again.'); return; }
  var jsPDF = (window.jspdf||window.jsPDF).jsPDF || (window.jspdf||window.jsPDF);
  var isLandscape = canvas.width > canvas.height;
  var doc = new jsPDF({ orientation: isLandscape?'landscape':'portrait', unit:'px',
                        format:[canvas.width, canvas.height] });
  var imgData = canvas.toDataURL('image/jpeg', 0.92);
  doc.addImage(imgData, 'JPEG', 0, 0, canvas.width, canvas.height);
  doc.save(getFilename('pdf'));
}

// Boot
if (document.readyState==='loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  setTimeout(init, 120);
}

})();
    "))

  ) # end tagList
}

ml_design_excalidraw_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    # All logic is client-side — nothing to do server-side
    prep_manager$update_progress("ml_design_excalidraw", 10)
  })
}
