# modules/ml_design_whiteboard.R
# ML Design Interview Whiteboard  v2.0 — FIXED
#
# ROOT CAUSE OF v1 FAILURE:
#   waitForLibs() required BOTH Fabric.js AND jsPDF CDN scripts to finish
#   loading before the canvas initialised. Either CDN call stalling inside
#   Shiny iframe silently blocked the entire whiteboard forever.
#
# FIX: Pure HTML5 Canvas 2D API — zero external dependencies.
#   jsPDF loaded async separately; PDF button only activates when ready.
#   All saves use blob download (showSaveFilePicker blocked in iframes).

ml_design_whiteboard_ui <- function(id) {
  ns <- NS(id)

  tagList(

    tags$style(HTML("
      #wb-shell {
        display: flex; flex-direction: column;
        height: calc(100vh - 102px);
        background: #1e1e2e; border-radius: 12px;
        overflow: hidden; box-shadow: 0 8px 32px rgba(0,0,0,0.45);
      }
      #wb-toolbar {
        display: flex; align-items: center; gap: 4px;
        padding: 7px 12px; background: #2a2a3e;
        border-bottom: 1px solid #3a3a5c;
        flex-wrap: wrap; flex-shrink: 0;
        user-select: none; z-index: 10;
      }
      .wb-group {
        display: flex; align-items: center; gap: 3px;
        padding-right: 10px; border-right: 1px solid #3a3a5c; margin-right: 2px;
      }
      .wb-group:last-child { border-right: none; }
      .wb-btn {
        background: transparent; border: 1px solid transparent; border-radius: 7px;
        color: #b0b0cc; cursor: pointer; padding: 5px 9px; font-size: 15px;
        line-height: 1; transition: all 0.13s;
        min-width: 32px; min-height: 32px;
        display: flex; align-items: center; justify-content: center;
      }
      .wb-btn:hover      { background:#3a3a5c; color:#fff; border-color:#5a5a8c; }
      .wb-btn.wb-active  { background:#1877F2; color:#fff; border-color:#1877F2; }
      .wb-btn.wb-danger:hover { background:#991b1b; color:#fff; border-color:#dc2626; }
      .wb-lbl {
        font-size:10px; font-weight:700; color:#666;
        text-transform:uppercase; letter-spacing:0.07em;
        white-space:nowrap; padding:0 3px;
      }
      input[type=color].wb-color {
        width:32px; height:32px; border:2px solid #3a3a5c; border-radius:7px;
        cursor:pointer; padding:1px; background:#3a3a5c;
      }
      input[type=range].wb-range {
        width:72px; height:4px; accent-color:#1877F2; cursor:pointer;
      }
      .wb-select {
        background:#3a3a5c; color:#c0c0d8; border:1px solid #5a5a8c;
        border-radius:6px; padding:4px 7px; font-size:12px; cursor:pointer;
      }
      #wb-sw-label { font-size:11px; color:#aaa; min-width:26px; }
      #wb-canvas-wrap {
        flex:1; position:relative; overflow:hidden;
      }
      #wb-canvas {
        display:block; position:absolute; top:0; left:0;
        cursor:crosshair; touch-action:none;
      }
      #wb-bottom {
        display:flex; align-items:center; gap:8px;
        padding:6px 12px; background:#23233a;
        border-top:1px solid #3a3a5c; flex-shrink:0; flex-wrap:wrap;
      }
      #wb-filename {
        background:#3a3a5c; color:#e0e0f0;
        border:1px solid #5a5a8c; border-radius:7px;
        padding:5px 10px; font-size:12px; width:200px; font-family:monospace;
      }
      #wb-filename:focus { outline:2px solid #1877F2; }
      .wb-save-btn {
        padding:6px 14px; border-radius:7px; border:none;
        font-weight:700; font-size:12px; cursor:pointer; transition:filter 0.13s;
      }
      .wb-save-btn:hover { filter:brightness(1.18); }
      .wb-save-btn:disabled { opacity:0.4; cursor:not-allowed; }
      #wb-s-png   { background:#16a34a; color:#fff; }
      #wb-s-jpg   { background:#b45309; color:#fff; }
      #wb-s-pdf   { background:#7c3aed; color:#fff; }
      #wb-s-clear { background:#991b1b; color:#fff; }
      #wb-msg { font-size:11px; color:#4ade80; margin-left:6px; }
      #wb-status {
        display:flex; gap:18px; padding:4px 14px;
        background:#2a2a3e; border-top:1px solid #3a3a5c;
        font-size:11px; color:#666; flex-shrink:0;
      }
    ")),

    div(id="wb-shell",

      div(id="wb-toolbar",
        div(class="wb-group",
          span(class="wb-lbl","Tool"),
          tags$button(id="wb-t-sel",  class="wb-btn wb-active", title="Select/Move (V)",   HTML("&#9654;")),
          tags$button(id="wb-t-pen",  class="wb-btn",           title="Freehand Draw (P)", HTML("&#9998;")),
          tags$button(id="wb-t-rect", class="wb-btn",           title="Rectangle (R)",     HTML("&#9645;")),
          tags$button(id="wb-t-ell",  class="wb-btn",           title="Ellipse (E)",       HTML("&#9711;")),
          tags$button(id="wb-t-dia",  class="wb-btn",           title="Diamond (D)",       HTML("&#9670;")),
          tags$button(id="wb-t-arr",  class="wb-btn",           title="Arrow (A)",         HTML("&#10145;")),
          tags$button(id="wb-t-line", class="wb-btn",           title="Line (L)",          HTML("&#9135;")),
          tags$button(id="wb-t-txt",  class="wb-btn",           title="Text (T)",          HTML("T")),
          tags$button(id="wb-t-img",  class="wb-btn",           title="Paste Image (Ctrl+V) — screenshot or copied image", HTML("&#128247;"))
        ),
        div(class="wb-group",
          span(class="wb-lbl","Fill"),
          tags$input(type="color", id="wb-fill",   class="wb-color", value="#ffffff"),
          span(class="wb-lbl","Stroke"),
          tags$input(type="color", id="wb-stroke", class="wb-color", value="#1877F2"),
          span(class="wb-lbl","W"),
          tags$input(type="range", id="wb-sw", class="wb-range", min="1", max="24", value="2"),
          tags$span(id="wb-sw-label","2px")
        ),
        div(class="wb-group",
          span(class="wb-lbl","Font"),
          tags$select(id="wb-fsize", class="wb-select",
            tags$option(value="14","14px"),
            tags$option(value="16","16px", selected=NA),
            tags$option(value="20","20px"),
            tags$option(value="24","24px"),
            tags$option(value="32","32px"),
            tags$option(value="48","48px")
          ),
          tags$select(id="wb-ffam", class="wb-select",
            tags$option(value="Arial","Arial"),
            tags$option(value="monospace","Mono"),
            tags$option(value="Georgia","Georgia"),
            tags$option(value="Comic Sans MS","Comic")
          )
        ),
        div(class="wb-group",
          span(class="wb-lbl","Canvas"),
          tags$select(id="wb-bg", class="wb-select",
            tags$option(value="#ffffff","White"),
            tags$option(value="#f5f0e8","Parchment"),
            tags$option(value="#0d1117","Dark"),
            tags$option(value="#eef2ff","Blueprint")
          )
        ),
        div(class="wb-group",
          tags$button(id="wb-undo",  class="wb-btn", title="Undo Ctrl+Z", HTML("&#8634;")),
          tags$button(id="wb-redo",  class="wb-btn", title="Redo Ctrl+Y", HTML("&#8635;")),
          tags$button(id="wb-del",   class="wb-btn wb-danger", title="Delete (Del)", HTML("&#128465;"))
        ),
        div(class="wb-group",
          tags$button(id="wb-zoom-in",  class="wb-btn", title="Zoom In",  HTML("&#43;")),
          tags$button(id="wb-zoom-out", class="wb-btn", title="Zoom Out", HTML("&minus;")),
          tags$button(id="wb-zoom-fit", class="wb-btn", title="Reset",    HTML("&#9635;"))
        )
      ),

      div(id="wb-canvas-wrap",
          tags$canvas(id="wb-canvas")
      ),

      div(id="wb-bottom",
        tags$label("for"="wb-filename", style="font-size:12px;color:#aaa;font-weight:700;","File:"),
        tags$input(type="text", id="wb-filename", value="ml_design_diagram",
                   placeholder="filename (no extension)"),
        tags$button(id="wb-s-png",   class="wb-save-btn", HTML("&#128444; PNG")),
        tags$button(id="wb-s-jpg",   class="wb-save-btn", HTML("&#128444; JPG")),
        tags$button(id="wb-s-pdf",   class="wb-save-btn", HTML("&#128196; PDF"), disabled=NA),
        tags$button(id="wb-s-clear", class="wb-save-btn", HTML("&#128465; Clear")),
        tags$span(id="wb-msg","")
      ),

      div(id="wb-status",
        tags$span(id="wb-st-tool","Tool: select"),
        tags$span(id="wb-st-zoom","Zoom: 100%"),
        tags$span(id="wb-st-objs","Objects: 0"),
        tags$span(id="wb-st-pos", "x:0 y:0"),
        tags$span(style="margin-left:auto;color:#444;",
          "V=select  P=pen  R=rect  E=ellipse  D=diamond  A=arrow  L=line  T=text  Ctrl+V=paste image  Ctrl+Z=undo  Del=delete")
      )
    ),

    tags$script(HTML("
(function(){
'use strict';

function boot(){
  var wrap=document.getElementById('wb-canvas-wrap');
  var cv=document.getElementById('wb-canvas');
  if(!wrap||!cv){setTimeout(boot,50);return;}

  /* size canvas to its container */
  function resize(){
    var r=wrap.getBoundingClientRect();
    var W=Math.floor(r.width)||900, H=Math.floor(r.height)||600;
    var tmp=document.createElement('canvas');
    tmp.width=cv.width; tmp.height=cv.height;
    tmp.getContext('2d').drawImage(cv,0,0);
    cv.width=W; cv.height=H;
    ctx.drawImage(tmp,0,0);
    renderAll();
  }
  cv.width=Math.floor(wrap.getBoundingClientRect().width)||900;
  cv.height=Math.floor(wrap.getBoundingClientRect().height)||600;
  var ctx=cv.getContext('2d');
  window.addEventListener('resize',function(){setTimeout(resize,80);});

  /* ── state ── */
  var tool='sel';
  var fillCol='#ffffff', strokeCol='#1877F2', strokeW=2;
  var fSize=16, fFam='Arial';
  var bgCol='#ffffff';
  var zoom=1, panX=0, panY=0;
  var objects=[], selected=-1;
  var undoStack=[], redoStack=[];
  var drawing=false, p0x=0, p0y=0;
  var penPts=[];
  var textEl=null;
  var dragging=false, dragObjIdx=-1, dragOffX=0, dragOffY=0, dragPrevX=0, dragPrevY=0;

  /* ── background ── */
  function fillBg(){
    ctx.save(); ctx.setTransform(1,0,0,1,0,0);
    ctx.fillStyle=bgCol; ctx.fillRect(0,0,cv.width,cv.height);
    ctx.restore();
  }

  /* ── undo snapshot ── */
  function snapshot(){
    undoStack.push(JSON.parse(JSON.stringify(safeSnapshot(objects))));
    if(undoStack.length>80) undoStack.shift();
    redoStack=[];
    document.getElementById('wb-st-objs').textContent='Objects: '+objects.length;
  }

  /* ── bounds of any object ── */
  function bounds(o){
    switch(o.type){
      case 'rect': case 'ell': case 'dia':
        return {x:o.x,y:o.y,w:Math.abs(o.w)||1,h:Math.abs(o.h)||1};
      case 'line': case 'arr':
        return {x:Math.min(o.x,o.x2),y:Math.min(o.y,o.y2),
                w:Math.abs(o.x2-o.x)||1,h:Math.abs(o.y2-o.y)||1};
      case 'pen':
        if(!o.pts||!o.pts.length) return {x:0,y:0,w:1,h:1};
        var xs=o.pts.map(function(p){return p[0];}),ys=o.pts.map(function(p){return p[1];});
        var mx=Math.min.apply(null,xs),my=Math.min.apply(null,ys);
        return {x:mx,y:my,w:Math.max.apply(null,xs)-mx||1,h:Math.max.apply(null,ys)-my||1};
      case 'txt':
        ctx.font='bold '+o.fs+'px '+o.ff;
        var tw=ctx.measureText(o.text).width;
        return {x:o.x,y:o.y-o.fs,w:tw||20,h:o.fs+4};
      case 'img':
        return {x:o.x,y:o.y,w:o.w||100,h:o.h||100};
      default: return {x:0,y:0,w:1,h:1};
    }
  }

  /* ── draw one object ── */
  function drawObj(o,sel){
    ctx.save();
    ctx.strokeStyle=o.stroke; ctx.fillStyle=o.fill;
    ctx.lineWidth=o.sw; ctx.lineCap='round'; ctx.lineJoin='round';
    switch(o.type){
      case 'rect':
        ctx.fillRect(o.x,o.y,o.w,o.h);
        ctx.strokeRect(o.x,o.y,o.w,o.h);
        break;
      case 'ell':
        ctx.beginPath();
        ctx.ellipse(o.x+o.w/2,o.y+o.h/2,Math.abs(o.w/2),Math.abs(o.h/2),0,0,Math.PI*2);
        ctx.fill(); ctx.stroke();
        break;
      case 'dia':
        var cx=o.x+o.w/2,cy=o.y+o.h/2;
        ctx.beginPath();
        ctx.moveTo(cx,o.y); ctx.lineTo(o.x+o.w,cy);
        ctx.lineTo(cx,o.y+o.h); ctx.lineTo(o.x,cy);
        ctx.closePath(); ctx.fill(); ctx.stroke();
        break;
      case 'line':
        ctx.beginPath(); ctx.moveTo(o.x,o.y); ctx.lineTo(o.x2,o.y2); ctx.stroke();
        break;
      case 'arr':
        ctx.beginPath(); ctx.moveTo(o.x,o.y); ctx.lineTo(o.x2,o.y2); ctx.stroke();
        var ang=Math.atan2(o.y2-o.y,o.x2-o.x), hl=Math.max(12,o.sw*4);
        ctx.beginPath();
        ctx.moveTo(o.x2,o.y2);
        ctx.lineTo(o.x2-hl*Math.cos(ang-0.42),o.y2-hl*Math.sin(ang-0.42));
        ctx.moveTo(o.x2,o.y2);
        ctx.lineTo(o.x2-hl*Math.cos(ang+0.42),o.y2-hl*Math.sin(ang+0.42));
        ctx.stroke();
        break;
      case 'pen':
        if(o.pts&&o.pts.length>1){
          ctx.beginPath();
          ctx.moveTo(o.pts[0][0],o.pts[0][1]);
          for(var i=1;i<o.pts.length;i++) ctx.lineTo(o.pts[i][0],o.pts[i][1]);
          ctx.stroke();
        }
        break;
      case 'txt':
        ctx.font='bold '+o.fs+'px '+o.ff;
        ctx.fillStyle=o.stroke;
        ctx.fillText(o.text,o.x,o.y);
        break;
      case 'img':
        /* lazy-create HTMLImageElement from stored dataURL if missing */
        if(!o._img){
          var im=new Image();
          im.src=o.src;
          o._img=im;
        }
        if(o._img.complete&&o._img.naturalWidth>0){
          ctx.drawImage(o._img,o.x,o.y,o.w,o.h);
          /* subtle border so image is visible on same-colour bg */
          ctx.strokeStyle='rgba(100,100,200,0.35)';
          ctx.lineWidth=1;
          ctx.strokeRect(o.x,o.y,o.w,o.h);
        } else {
          /* image still loading — draw placeholder */
          ctx.fillStyle='#2a2a3e';
          ctx.fillRect(o.x,o.y,o.w,o.h);
          ctx.fillStyle='#888';
          ctx.font='14px Arial';
          ctx.fillText('Loading image...',o.x+8,o.y+24);
          /* re-render when loaded */
          o._img.onload=function(){ renderAll(); };
        }
        break;
    }
    if(sel){
      var b=bounds(o);
      ctx.strokeStyle='#fbbf24'; ctx.lineWidth=1.5; ctx.setLineDash([5,3]);
      ctx.strokeRect(b.x-6,b.y-6,b.w+12,b.h+12);
      ctx.setLineDash([]);
      [[b.x-6,b.y-6],[b.x+b.w+6,b.y-6],[b.x-6,b.y+b.h+6],[b.x+b.w+6,b.y+b.h+6]].forEach(function(p){
        ctx.fillStyle='#fbbf24'; ctx.fillRect(p[0]-4,p[1]-4,8,8);
      });
    }
    ctx.restore();
  }

  /* ── render all ── */
  function renderAll(){
    ctx.save();
    ctx.setTransform(zoom,0,0,zoom,panX,panY);
    fillBg();
    objects.forEach(function(o,i){drawObj(o,i===selected);});
    ctx.restore();
  }

  /* ── hit test (screen coords) ── */
  function hitTest(sx,sy){
    var cx=(sx-panX)/zoom, cy=(sy-panY)/zoom;
    for(var i=objects.length-1;i>=0;i--){
      var b=bounds(objects[i]);
      if(cx>=b.x-8&&cx<=b.x+b.w+8&&cy>=b.y-8&&cy<=b.y+b.h+8) return i;
    }
    return -1;
  }

  /* ── canvas coords from event ── */
  function evC(e){
    var r=cv.getBoundingClientRect();
    var src=e.touches?e.touches[0]:e;
    return [(src.clientX-r.left-panX)/zoom,(src.clientY-r.top-panY)/zoom];
  }
  function evS(e){
    var r=cv.getBoundingClientRect();
    var src=e.touches?e.touches[0]:e;
    return [src.clientX-r.left,src.clientY-r.top];
  }

  /* ── text input overlay ── */
  function dismissText(){
    if(!textEl) return;
    var val=textEl.value.trim();
    if(val){
      snapshot();
      objects.push({type:'txt',x:textEl._cx,y:textEl._cy,
                    text:val,stroke:strokeCol,fill:'none',sw:1,fs:fSize,ff:fFam});
      renderAll();
    }
    textEl.remove(); textEl=null;
    document.getElementById('wb-st-objs').textContent='Objects: '+objects.length;
  }

  function placeText(sx,sy,cx,cy){
    dismissText();
    var inp=document.createElement('input');
    inp.type='text'; inp.placeholder='Type then Enter';
    inp.style.cssText='position:absolute;left:'+(sx-2)+'px;top:'+(sy-fSize-4)+'px;'+
      'background:rgba(20,20,40,0.95);border:1.5px dashed '+strokeCol+';border-radius:4px;'+
      'color:'+strokeCol+';font:bold '+fSize+'px '+fFam+';'+
      'outline:none;min-width:180px;padding:3px 6px;z-index:999;';
    inp._cx=cx; inp._cy=cy+4;
    wrap.appendChild(inp); inp.focus(); textEl=inp;
    inp.addEventListener('keydown',function(ev){
      if(ev.key==='Enter'||ev.key==='Escape') dismissText();
    });
  }

  /* ── mouse/touch handlers ── */
  cv.addEventListener('mousedown',onDown);
  cv.addEventListener('mousemove',onMove);
  cv.addEventListener('mouseup',onUp);
  cv.addEventListener('touchstart',onDown,{passive:false});
  cv.addEventListener('touchmove',onMove,{passive:false});
  cv.addEventListener('touchend',onUp,{passive:false});

  function onDown(e){
    e.preventDefault();
    dismissText();
    var s=evS(e), c=evC(e);

    if(tool==='sel'){
      var idx=hitTest(s[0],s[1]);
      selected=idx;
      if(idx>=0){
        dragging=true; dragObjIdx=idx;
        dragPrevX=c[0]; dragPrevY=c[1];
      }
      renderAll(); return;
    }
    if(tool==='txt'){ placeText(s[0],s[1],c[0],c[1]); return; }

    drawing=true; p0x=c[0]; p0y=c[1];
    if(tool==='pen') penPts=[[c[0],c[1]]];
  }

  function onMove(e){
    e.preventDefault();
    var s=evS(e), c=evC(e);
    document.getElementById('wb-st-pos').textContent='x:'+Math.round(c[0])+' y:'+Math.round(c[1]);

    if(tool==='sel'&&dragging&&dragObjIdx>=0){
      var o=objects[dragObjIdx];
      var dx=c[0]-dragPrevX, dy=c[1]-dragPrevY;
      if(o.type==='line'||o.type==='arr'){o.x+=dx;o.y+=dy;o.x2+=dx;o.y2+=dy;}
      else if(o.type==='pen'){o.pts=o.pts.map(function(p){return[p[0]+dx,p[1]+dy];});}
      else{o.x+=dx;o.y+=dy;}
      dragPrevX=c[0]; dragPrevY=c[1];
      renderAll(); return;
    }

    if(!drawing) return;

    if(tool==='pen'){
      penPts.push([c[0],c[1]]);
      ctx.save();
      ctx.setTransform(zoom,0,0,zoom,panX,panY);
      ctx.strokeStyle=strokeCol; ctx.lineWidth=strokeW;
      ctx.lineCap='round'; ctx.lineJoin='round';
      var n=penPts.length;
      if(n>1){
        ctx.beginPath();
        ctx.moveTo(penPts[n-2][0],penPts[n-2][1]);
        ctx.lineTo(penPts[n-1][0],penPts[n-1][1]);
        ctx.stroke();
      }
      ctx.restore(); return;
    }

    /* preview shape */
    renderAll();
    ctx.save();
    ctx.setTransform(zoom,0,0,zoom,panX,panY);
    ctx.strokeStyle=strokeCol; ctx.fillStyle=fillCol;
    ctx.lineWidth=strokeW; ctx.lineCap='round'; ctx.lineJoin='round';
    var w=c[0]-p0x, h=c[1]-p0y;
    switch(tool){
      case 'rect':
        ctx.fillRect(Math.min(p0x,c[0]),Math.min(p0y,c[1]),Math.abs(w),Math.abs(h));
        ctx.strokeRect(Math.min(p0x,c[0]),Math.min(p0y,c[1]),Math.abs(w),Math.abs(h));
        break;
      case 'ell':
        ctx.beginPath();
        ctx.ellipse(p0x+w/2,p0y+h/2,Math.abs(w/2),Math.abs(h/2),0,0,Math.PI*2);
        ctx.fill(); ctx.stroke(); break;
      case 'dia':
        var cx2=p0x+w/2,cy2=p0y+h/2;
        ctx.beginPath();
        ctx.moveTo(cx2,Math.min(p0y,c[1])); ctx.lineTo(Math.max(p0x,c[0]),cy2);
        ctx.lineTo(cx2,Math.max(p0y,c[1])); ctx.lineTo(Math.min(p0x,c[0]),cy2);
        ctx.closePath(); ctx.fill(); ctx.stroke(); break;
      case 'line':
        ctx.beginPath(); ctx.moveTo(p0x,p0y); ctx.lineTo(c[0],c[1]); ctx.stroke(); break;
      case 'arr':
        ctx.beginPath(); ctx.moveTo(p0x,p0y); ctx.lineTo(c[0],c[1]); ctx.stroke();
        var ang2=Math.atan2(c[1]-p0y,c[0]-p0x), hl2=Math.max(12,strokeW*4);
        ctx.beginPath();
        ctx.moveTo(c[0],c[1]);
        ctx.lineTo(c[0]-hl2*Math.cos(ang2-0.42),c[1]-hl2*Math.sin(ang2-0.42));
        ctx.moveTo(c[0],c[1]);
        ctx.lineTo(c[0]-hl2*Math.cos(ang2+0.42),c[1]-hl2*Math.sin(ang2+0.42));
        ctx.stroke(); break;
    }
    ctx.restore();
  }

  function onUp(e){
    if(dragging){ dragging=false; dragObjIdx=-1; snapshot(); renderAll(); return; }
    if(!drawing) return;
    drawing=false;
    var c=e.touches&&e.touches.length?evC(e):(e.changedTouches?
          [(e.changedTouches[0].clientX-cv.getBoundingClientRect().left-panX)/zoom,
           (e.changedTouches[0].clientY-cv.getBoundingClientRect().top-panY)/zoom]
          :evC(e));
    var w=c[0]-p0x, h=c[1]-p0y;

    if(tool==='pen'){
      if(penPts.length>2){
        snapshot();
        objects.push({type:'pen',pts:penPts.slice(),stroke:strokeCol,fill:'none',sw:strokeW});
      }
      penPts=[]; renderAll(); return;
    }

    var obj=null;
    switch(tool){
      case 'rect':
        if(Math.abs(w)<3&&Math.abs(h)<3) break;
        obj={type:'rect',x:Math.min(p0x,c[0]),y:Math.min(p0y,c[1]),
             w:Math.abs(w),h:Math.abs(h),stroke:strokeCol,fill:fillCol,sw:strokeW}; break;
      case 'ell':
        if(Math.abs(w)<3&&Math.abs(h)<3) break;
        obj={type:'ell',x:Math.min(p0x,c[0]),y:Math.min(p0y,c[1]),
             w:Math.abs(w),h:Math.abs(h),stroke:strokeCol,fill:fillCol,sw:strokeW}; break;
      case 'dia':
        if(Math.abs(w)<3&&Math.abs(h)<3) break;
        obj={type:'dia',x:Math.min(p0x,c[0]),y:Math.min(p0y,c[1]),
             w:Math.abs(w),h:Math.abs(h),stroke:strokeCol,fill:fillCol,sw:strokeW}; break;
      case 'line':
        if(Math.abs(w)<2&&Math.abs(h)<2) break;
        obj={type:'line',x:p0x,y:p0y,x2:c[0],y2:c[1],
             stroke:strokeCol,fill:strokeCol,sw:strokeW}; break;
      case 'arr':
        if(Math.abs(w)<2&&Math.abs(h)<2) break;
        obj={type:'arr',x:p0x,y:p0y,x2:c[0],y2:c[1],
             stroke:strokeCol,fill:strokeCol,sw:strokeW}; break;
    }
    if(obj){ snapshot(); objects.push(obj); }
    renderAll();
  }

  /* ── toolbar wiring ── */
  var toolMap={'wb-t-sel':'sel','wb-t-pen':'pen','wb-t-rect':'rect',
               'wb-t-ell':'ell','wb-t-dia':'dia','wb-t-arr':'arr',
               'wb-t-line':'line','wb-t-txt':'txt','wb-t-img':'img'};
  Object.keys(toolMap).forEach(function(id){
    var el=document.getElementById(id);
    if(!el) return;
    el.addEventListener('click',function(){
      tool=toolMap[id];
      cv.style.cursor=tool==='sel'?'default':tool==='txt'?'text':tool==='img'?'copy':'crosshair';
      Object.keys(toolMap).forEach(function(k){ document.getElementById(k).classList.remove('wb-active'); });
      this.classList.add('wb-active');
      document.getElementById('wb-st-tool').textContent='Tool: '+tool+(tool==='img'?' (press Ctrl+V to paste)':'');
      if(tool==='img') msg('Press Ctrl+V (or right-click > Paste) to paste a screenshot or image');
    });
  });

  /* ── Image paste via Clipboard API ────────────────────────────────────────
     Accepts: PNG (screenshots, Snipping Tool, Cmd+Shift+4, Ctrl+C from browser)
              JPEG (copied from image editors / some apps)
              WebP, GIF (browser converts to PNG internally)
     Does NOT work: raw file copy from Explorer/Finder (use drag-drop instead)
     Pastes at canvas centre, scaled to fit within 80% of canvas dimensions.
  ─────────────────────────────────────────────────────────────────────────── */
  function pasteImageFromClipboard(e) {
    var items = (e.clipboardData || window.clipboardData || {}).items;
    if (!items) return;

    var imageItem = null;
    for (var i = 0; i < items.length; i++) {
      if (items[i].type.indexOf('image') !== -1) {
        imageItem = items[i];
        break;
      }
    }
    if (!imageItem) {
      msg('No image found in clipboard. Copy a screenshot first (Snipping Tool / Ctrl+PrtSc)', '#fbbf24');
      return;
    }

    e.preventDefault();

    var file   = imageItem.getAsFile();
    var reader = new FileReader();
    reader.onload = function(ev) {
      var src = ev.target.result;
      var im  = new Image();
      im.onload = function() {
        /* scale to fit within 80% of canvas, preserving aspect ratio */
        var maxW = cv.width  * 0.8 / zoom;
        var maxH = cv.height * 0.8 / zoom;
        var scale = Math.min(1, maxW / im.naturalWidth, maxH / im.naturalHeight);
        var w = Math.round(im.naturalWidth  * scale);
        var h = Math.round(im.naturalHeight * scale);
        /* centre in visible canvas area */
        var x = Math.round((cv.width  / zoom - w) / 2 - panX / zoom);
        var y = Math.round((cv.height / zoom - h) / 2 - panY / zoom);
        snapshot();
        objects.push({type:'img', x:x, y:y, w:w, h:h, src:src, _img:im});
        selected = objects.length - 1;
        renderAll();
        document.getElementById('wb-st-objs').textContent = 'Objects: ' + objects.length;
        msg('Image pasted (' + im.naturalWidth + 'x' + im.naturalHeight + 'px) — drag to reposition');
        /* switch to select so user can immediately drag it */
        document.getElementById('wb-t-sel').click();
      };
      im.src = src;
    };
    reader.readAsDataURL(file);
  }

  /* Listen on both document (catches Ctrl+V anywhere) and canvas */
  document.addEventListener('paste', pasteImageFromClipboard);

  /* Snapshot serialisation: strip _img (HTMLImageElement can't be JSON'd).
     It gets recreated lazily in drawObj from the stored src dataURL.      */
  function safeSnapshot(arr) {
    return arr.map(function(o) {
      if (o.type !== 'img') return o;
      return {type:'img', x:o.x, y:o.y, w:o.w, h:o.h, src:o.src};
    });
  }

  document.getElementById('wb-fill').addEventListener('input',function(){
    fillCol=this.value;
    if(selected>=0&&objects[selected].fill!=='none'){ objects[selected].fill=this.value; renderAll(); }
  });
  document.getElementById('wb-stroke').addEventListener('input',function(){
    strokeCol=this.value;
    if(selected>=0){ objects[selected].stroke=this.value; renderAll(); }
  });
  document.getElementById('wb-sw').addEventListener('input',function(){
    strokeW=parseInt(this.value);
    document.getElementById('wb-sw-label').textContent=strokeW+'px';
    if(selected>=0){ objects[selected].sw=strokeW; renderAll(); }
  });
  document.getElementById('wb-fsize').addEventListener('change',function(){
    fSize=parseInt(this.value);
    if(selected>=0&&objects[selected].type==='txt'){ objects[selected].fs=fSize; renderAll(); }
  });
  document.getElementById('wb-ffam').addEventListener('change',function(){
    fFam=this.value;
    if(selected>=0&&objects[selected].type==='txt'){ objects[selected].ff=fFam; renderAll(); }
  });
  document.getElementById('wb-bg').addEventListener('change',function(){
    bgCol=this.value; renderAll();
  });

  document.getElementById('wb-undo').addEventListener('click',function(){
    if(!undoStack.length) return;
    redoStack.push(JSON.parse(JSON.stringify(objects)));
    objects=undoStack.pop(); selected=-1; renderAll();
    document.getElementById('wb-st-objs').textContent='Objects: '+objects.length;
  });
  document.getElementById('wb-redo').addEventListener('click',function(){
    if(!redoStack.length) return;
    undoStack.push(JSON.parse(JSON.stringify(objects)));
    objects=redoStack.pop(); selected=-1; renderAll();
    document.getElementById('wb-st-objs').textContent='Objects: '+objects.length;
  });
  document.getElementById('wb-del').addEventListener('click',function(){
    if(selected<0) return;
    snapshot(); objects.splice(selected,1); selected=-1; renderAll();
    document.getElementById('wb-st-objs').textContent='Objects: '+objects.length;
  });

  document.getElementById('wb-zoom-in').addEventListener('click',function(){
    zoom=Math.min(zoom*1.2,6); renderAll();
    document.getElementById('wb-st-zoom').textContent='Zoom: '+Math.round(zoom*100)+'%';
  });
  document.getElementById('wb-zoom-out').addEventListener('click',function(){
    zoom=Math.max(zoom/1.2,0.2); renderAll();
    document.getElementById('wb-st-zoom').textContent='Zoom: '+Math.round(zoom*100)+'%';
  });
  document.getElementById('wb-zoom-fit').addEventListener('click',function(){
    zoom=1; panX=0; panY=0; renderAll();
    document.getElementById('wb-st-zoom').textContent='Zoom: 100%';
  });

  cv.addEventListener('wheel',function(e){
    e.preventDefault();
    zoom=Math.max(0.2,Math.min(6,zoom*(e.deltaY<0?1.1:0.9)));
    renderAll();
    document.getElementById('wb-st-zoom').textContent='Zoom: '+Math.round(zoom*100)+'%';
  },{passive:false});

  document.addEventListener('keydown',function(e){
    if(e.target.tagName==='INPUT'||e.target.tagName==='TEXTAREA'||e.target.tagName==='SELECT') return;
    if((e.ctrlKey||e.metaKey)&&e.key==='z'){ document.getElementById('wb-undo').click(); return; }
    if((e.ctrlKey||e.metaKey)&&e.key==='y'){ document.getElementById('wb-redo').click(); return; }
    if(e.key==='Delete'||e.key==='Backspace'){ document.getElementById('wb-del').click(); return; }
    var km={v:'wb-t-sel',p:'wb-t-pen',r:'wb-t-rect',e:'wb-t-ell',
            d:'wb-t-dia',a:'wb-t-arr',l:'wb-t-line',t:'wb-t-txt'};
    var k=e.key.toLowerCase();
    if(km[k]&&!e.ctrlKey&&!e.metaKey) document.getElementById(km[k]).click();
  });

  /* ── save ── */
  function fname(ext){
    var f=(document.getElementById('wb-filename').value||'ml_design_diagram').trim();
    return f.replace(/\\.[^.]+$/,'')+'.'+ext;
  }
  function msg(t,c){
    var el=document.getElementById('wb-msg');
    el.textContent=t; el.style.color=c||'#4ade80';
    setTimeout(function(){el.textContent='';},3500);
  }

  document.getElementById('wb-s-png').addEventListener('click',function(){
    var a=document.createElement('a');
    a.href=cv.toDataURL('image/png'); a.download=fname('png');
    document.body.appendChild(a); a.click(); document.body.removeChild(a);
    msg('PNG saved OK');
  });

  document.getElementById('wb-s-jpg').addEventListener('click',function(){
    var tmp=document.createElement('canvas');
    tmp.width=cv.width; tmp.height=cv.height;
    var tc=tmp.getContext('2d');
    tc.fillStyle='#ffffff'; tc.fillRect(0,0,tmp.width,tmp.height);
    tc.drawImage(cv,0,0);
    var a=document.createElement('a');
    a.href=tmp.toDataURL('image/jpeg',0.95); a.download=fname('jpg');
    document.body.appendChild(a); a.click(); document.body.removeChild(a);
    msg('JPG saved OK');
  });

  /* load jsPDF async — PDF button activates only when loaded */
  (function(){
    var s=document.createElement('script');
    s.src='https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js';
    s.onload=function(){
      var btn=document.getElementById('wb-s-pdf');
      btn.removeAttribute('disabled');
      btn.addEventListener('click',function(){
        try{
          var jsPDF=(window.jspdf||window.jsPDF).jsPDF||(window.jspdf||window.jsPDF);
          var W=cv.width,H=cv.height;
          var doc=new jsPDF({orientation:W>H?'landscape':'portrait',unit:'px',format:[W,H]});
          doc.addImage(cv.toDataURL('image/jpeg',0.92),'JPEG',0,0,W,H);
          doc.save(fname('pdf'));
          msg('PDF saved OK');
        }catch(err){msg('PDF error: '+err.message,'#f87171');}
      });
    };
    s.onerror=function(){ document.getElementById('wb-s-pdf').title='PDF unavailable'; };
    document.head.appendChild(s);
  })();

  document.getElementById('wb-s-clear').addEventListener('click',function(){
    if(!confirm('Clear canvas? This cannot be undone.')) return;
    snapshot(); objects=[]; selected=-1; renderAll();
    document.getElementById('wb-st-objs').textContent='Objects: 0';
    msg('Cleared','#aaa');
  });

  /* ── first render ── */
  fillBg();
  renderAll();
  setTimeout(function(){ msg('Ready -- pick a tool and draw!'); }, 300);
}

if(document.readyState==='loading'){
  document.addEventListener('DOMContentLoaded',boot);
}else{
  setTimeout(boot,60);
}
})();
    "))
  )
}

ml_design_whiteboard_server <- function(id, prep_manager) {
  moduleServer(id, function(input, output, session) {
    prep_manager$update_progress("ml_design_whiteboard", 50)
  })
}
