/* dg_engine.js v3 — robust Shiny tab rendering
   Key fix: initDiag() retries until canvas has real pixel width.
   ResizeObserver redraws when tab becomes visible.
   Sidebar click listener re-triggers init for any unrendered canvases.
*/
window.DG = window.DG || {};

function dgDrawObj(ctx, o, sel) {
  ctx.save();
  ctx.strokeStyle = o.stroke || '#000';
  ctx.fillStyle   = o.fill   || '#fff';
  ctx.lineWidth   = o.sw     || 1;
  ctx.lineCap = 'round'; ctx.lineJoin = 'round';
  switch (o.type) {
    case 'rect':
      ctx.fillRect(o.x,o.y,o.w,o.h);
      ctx.strokeRect(o.x,o.y,o.w,o.h); break;
    case 'ell':
      ctx.beginPath();
      ctx.ellipse(o.x+o.w/2,o.y+o.h/2,Math.abs(o.w/2),Math.abs(o.h/2),0,0,Math.PI*2);
      ctx.fill(); ctx.stroke(); break;
    case 'dia':
      var cx=o.x+o.w/2,cy=o.y+o.h/2;
      ctx.beginPath();
      ctx.moveTo(cx,o.y); ctx.lineTo(o.x+o.w,cy);
      ctx.lineTo(cx,o.y+o.h); ctx.lineTo(o.x,cy);
      ctx.closePath(); ctx.fill(); ctx.stroke(); break;
    case 'line':
      ctx.beginPath(); ctx.moveTo(o.x,o.y); ctx.lineTo(o.x2,o.y2); ctx.stroke(); break;
    case 'arr':
      ctx.beginPath(); ctx.moveTo(o.x,o.y); ctx.lineTo(o.x2,o.y2); ctx.stroke();
      var ang=Math.atan2(o.y2-o.y,o.x2-o.x), hl=Math.max(10,(o.sw||1)*4);
      ctx.beginPath();
      ctx.moveTo(o.x2,o.y2);
      ctx.lineTo(o.x2-hl*Math.cos(ang-0.42),o.y2-hl*Math.sin(ang-0.42));
      ctx.moveTo(o.x2,o.y2);
      ctx.lineTo(o.x2-hl*Math.cos(ang+0.42),o.y2-hl*Math.sin(ang+0.42));
      ctx.stroke(); break;
    case 'pen':
      if(o.pts&&o.pts.length>1){
        ctx.beginPath(); ctx.moveTo(o.pts[0][0],o.pts[0][1]);
        for(var i=1;i<o.pts.length;i++) ctx.lineTo(o.pts[i][0],o.pts[i][1]);
        ctx.stroke();
      } break;
    case 'txt':
      ctx.font='bold '+(o.fs||11)+'px '+(o.ff||'Arial');
      ctx.fillStyle=o.stroke||'#000';
      ctx.fillText(o.text,o.x,o.y); break;
  }
  if(sel){
    var b=dgBounds(ctx,o);
    ctx.strokeStyle='#f59e0b'; ctx.lineWidth=1.5; ctx.setLineDash([4,3]);
    ctx.strokeRect(b.x-5,b.y-5,b.w+10,b.h+10); ctx.setLineDash([]);
    [[b.x-5,b.y-5],[b.x+b.w+5,b.y-5],[b.x-5,b.y+b.h+5],[b.x+b.w+5,b.y+b.h+5]].forEach(function(p){
      ctx.fillStyle='#f59e0b'; ctx.fillRect(p[0]-3,p[1]-3,7,7);
    });
  }
  ctx.restore();
}

function dgBounds(ctx,o){
  if(o.type==='rect'||o.type==='ell'||o.type==='dia')
    return{x:o.x,y:o.y,w:Math.abs(o.w)||1,h:Math.abs(o.h)||1};
  if(o.type==='line'||o.type==='arr')
    return{x:Math.min(o.x,o.x2),y:Math.min(o.y,o.y2),
           w:Math.abs(o.x2-o.x)||1,h:Math.abs(o.y2-o.y)||1};
  if(o.type==='pen'){
    if(!o.pts||!o.pts.length) return{x:0,y:0,w:1,h:1};
    var xs=o.pts.map(function(p){return p[0];}),ys=o.pts.map(function(p){return p[1];});
    var mx=Math.min.apply(null,xs),my=Math.min.apply(null,ys);
    return{x:mx,y:my,w:Math.max.apply(null,xs)-mx||1,h:Math.max.apply(null,ys)-my||1};
  }
  if(o.type==='txt'){
    ctx.font='bold '+(o.fs||11)+'px '+(o.ff||'Arial');
    return{x:o.x,y:o.y-(o.fs||11),w:ctx.measureText(o.text).width||20,h:(o.fs||11)+4};
  }
  return{x:0,y:0,w:1,h:1};
}

function dgRenderAll(s){
  var ctx=s.ctx, cv=s.cv;
  ctx.save(); ctx.setTransform(1,0,0,1,0,0);
  ctx.fillStyle='#ffffff'; ctx.fillRect(0,0,cv.width,cv.height);
  ctx.restore();
  s.objects.forEach(function(o,i){ dgDrawObj(ctx,o,i===s.selected); });
  var el=document.getElementById('st-'+s.id);
  if(el) el.textContent=s.objects.length+' objects';
}

window.initDiag = function(id){
  /* already ready: just re-render (handles tab revisit) */
  if(window.DG[id]&&window.DG[id]._ready){ dgRenderAll(window.DG[id]); return; }

  var wrap=document.getElementById('wrap-'+id);
  var cv=document.getElementById(id);
  if(!wrap||!cv){ setTimeout(function(){window.initDiag(id);},120); return; }

  /* retry until tab is visible and canvas has real width */
  var W=Math.floor(wrap.getBoundingClientRect().width);
  if(W<10){ setTimeout(function(){window.initDiag(id);},200); return; }

  cv.width=W; cv.height=320;
  cv.style.width=W+'px'; cv.style.height='320px';
  wrap.style.minHeight='320px';

  var ctx=cv.getContext('2d');
  var seed=(window.DIAGRAMS&&window.DIAGRAMS[id])
    ?JSON.parse(JSON.stringify(window.DIAGRAMS[id])):[];

  var s={
    id:id, ctx:ctx, cv:cv, wrap:wrap,
    tool:'sel', strokeCol:'#000000', fillCol:'#ffffff', strokeW:1.5,
    fSize:11, fFam:'Arial',
    objects:JSON.parse(JSON.stringify(seed)), seed:seed,
    selected:-1, undoStack:[], redoStack:[],
    drawing:false, p0x:0, p0y:0,
    dragging:false, dragObjIdx:-1, dragPrevX:0, dragPrevY:0,
    penPts:[], _ready:true
  };
  window.DG[id]=s;

  function renderAll(){ dgRenderAll(s); }
  function snapshot(){
    s.undoStack.push(JSON.parse(JSON.stringify(s.objects)));
    if(s.undoStack.length>60) s.undoStack.shift();
    s.redoStack=[];
  }
  function hitTest(x,y){
    for(var i=s.objects.length-1;i>=0;i--){
      var b=dgBounds(ctx,s.objects[i]);
      if(x>=b.x-6&&x<=b.x+b.w+6&&y>=b.y-6&&y<=b.y+b.h+6) return i;
    }
    return -1;
  }
  function evC(e){
    var r=cv.getBoundingClientRect(),src=e.touches?e.touches[0]:e;
    return[src.clientX-r.left,src.clientY-r.top];
  }

  /* toolbar */
  var toolMap={'tb-sel-'+id:'sel','tb-pen-'+id:'pen','tb-rect-'+id:'rect',
               'tb-ell-'+id:'ell','tb-arr-'+id:'arr','tb-line-'+id:'line','tb-txt-'+id:'txt'};
  Object.keys(toolMap).forEach(function(btnId){
    var el=document.getElementById(btnId); if(!el) return;
    el.addEventListener('click',function(){
      s.tool=toolMap[btnId];
      cv.style.cursor=s.tool==='sel'?'default':s.tool==='txt'?'text':'crosshair';
      Object.keys(toolMap).forEach(function(k){var b=document.getElementById(k);if(b)b.classList.remove('dg-active');});
      el.classList.add('dg-active');
    });
  });
  var undoBtn=document.getElementById('tb-undo-'+id);
  var redoBtn=document.getElementById('tb-redo-'+id);
  var delBtn =document.getElementById('tb-del-'+id);
  var saveBtn=document.getElementById('tb-save-'+id);
  if(undoBtn) undoBtn.addEventListener('click',function(){
    if(!s.undoStack.length) return;
    s.redoStack.push(JSON.parse(JSON.stringify(s.objects)));
    s.objects=s.undoStack.pop(); s.selected=-1; renderAll();
  });
  if(redoBtn) redoBtn.addEventListener('click',function(){
    if(!s.redoStack.length) return;
    s.undoStack.push(JSON.parse(JSON.stringify(s.objects)));
    s.objects=s.redoStack.pop(); s.selected=-1; renderAll();
  });
  if(delBtn) delBtn.addEventListener('click',function(){
    if(s.selected<0) return;
    snapshot(); s.objects.splice(s.selected,1); s.selected=-1; renderAll();
  });
  if(saveBtn) saveBtn.addEventListener('click',function(){
    var a=document.createElement('a');
    a.href=cv.toDataURL('image/png'); a.download=id+'.png';
    document.body.appendChild(a); a.click(); document.body.removeChild(a);
  });

  /* text overlay */
  var textEl=null;
  function dismissText(){
    if(!textEl) return;
    var v=textEl.value.trim();
    if(v){snapshot();s.objects.push({type:'txt',x:textEl._cx,y:textEl._cy,
      text:v,stroke:s.strokeCol,fill:'none',sw:1,fs:s.fSize,ff:s.fFam});renderAll();}
    textEl.remove(); textEl=null;
  }

  /* mouse/touch */
  cv.addEventListener('mousedown',onDown);
  cv.addEventListener('mousemove',onMove);
  cv.addEventListener('mouseup',  onUp);
  cv.addEventListener('touchstart',onDown,{passive:false});
  cv.addEventListener('touchmove', onMove,{passive:false});
  cv.addEventListener('touchend',  onUp,  {passive:false});

  function onDown(e){
    e.preventDefault(); dismissText();
    var c=evC(e);
    if(s.tool==='sel'){
      var idx=hitTest(c[0],c[1]); s.selected=idx;
      if(idx>=0){s.dragging=true;s.dragObjIdx=idx;s.dragPrevX=c[0];s.dragPrevY=c[1];}
      renderAll(); return;
    }
    if(s.tool==='txt'){
      var r2=cv.getBoundingClientRect(),src2=e.touches?e.touches[0]:e;
      var inp=document.createElement('input');
      inp.type='text'; inp.placeholder='Type then Enter';
      inp.style.cssText='position:absolute;left:'+(src2.clientX-r2.left-2)+'px;top:'+(src2.clientY-r2.top-s.fSize-4)+'px;'+
        'background:rgba(255,255,255,0.96);border:1.5px dashed #008A82;border-radius:4px;'+
        'color:#000;font:bold '+s.fSize+'px '+s.fFam+';outline:none;min-width:160px;padding:3px 6px;z-index:999;';
      inp._cx=c[0]; inp._cy=c[1]+4;
      wrap.appendChild(inp); inp.focus(); textEl=inp;
      inp.addEventListener('keydown',function(ev){if(ev.key==='Enter'||ev.key==='Escape')dismissText();});
      return;
    }
    s.drawing=true; s.p0x=c[0]; s.p0y=c[1];
    if(s.tool==='pen') s.penPts=[[c[0],c[1]]];
  }

  function onMove(e){
    e.preventDefault();
    var c=evC(e);
    if(s.tool==='sel'&&s.dragging&&s.dragObjIdx>=0){
      var o=s.objects[s.dragObjIdx],dx=c[0]-s.dragPrevX,dy=c[1]-s.dragPrevY;
      if(o.type==='line'||o.type==='arr'){o.x+=dx;o.y+=dy;o.x2+=dx;o.y2+=dy;}
      else if(o.type==='pen'){o.pts=o.pts.map(function(p){return[p[0]+dx,p[1]+dy];});}
      else{o.x+=dx;o.y+=dy;}
      s.dragPrevX=c[0]; s.dragPrevY=c[1]; renderAll(); return;
    }
    if(!s.drawing) return;
    if(s.tool==='pen'){
      s.penPts.push([c[0],c[1]]);
      ctx.strokeStyle=s.strokeCol; ctx.lineWidth=s.strokeW; ctx.lineCap='round';
      var n=s.penPts.length;
      if(n>1){ctx.beginPath();ctx.moveTo(s.penPts[n-2][0],s.penPts[n-2][1]);ctx.lineTo(s.penPts[n-1][0],s.penPts[n-1][1]);ctx.stroke();}
      return;
    }
    renderAll();
    ctx.save();
    ctx.strokeStyle=s.strokeCol; ctx.fillStyle=s.fillCol;
    ctx.lineWidth=s.strokeW; ctx.lineCap='round'; ctx.lineJoin='round';
    var w=c[0]-s.p0x,h=c[1]-s.p0y;
    switch(s.tool){
      case 'rect':
        ctx.fillRect(Math.min(s.p0x,c[0]),Math.min(s.p0y,c[1]),Math.abs(w),Math.abs(h));
        ctx.strokeRect(Math.min(s.p0x,c[0]),Math.min(s.p0y,c[1]),Math.abs(w),Math.abs(h)); break;
      case 'ell':
        ctx.beginPath();ctx.ellipse(s.p0x+w/2,s.p0y+h/2,Math.abs(w/2),Math.abs(h/2),0,0,Math.PI*2);
        ctx.fill();ctx.stroke(); break;
      case 'dia':
        ctx.beginPath();ctx.moveTo(s.p0x+w/2,Math.min(s.p0y,c[1]));
        ctx.lineTo(Math.max(s.p0x,c[0]),s.p0y+h/2);ctx.lineTo(s.p0x+w/2,Math.max(s.p0y,c[1]));
        ctx.lineTo(Math.min(s.p0x,c[0]),s.p0y+h/2);ctx.closePath();ctx.fill();ctx.stroke(); break;
      case 'line':
        ctx.beginPath();ctx.moveTo(s.p0x,s.p0y);ctx.lineTo(c[0],c[1]);ctx.stroke(); break;
      case 'arr':
        ctx.beginPath();ctx.moveTo(s.p0x,s.p0y);ctx.lineTo(c[0],c[1]);ctx.stroke();
        var a2=Math.atan2(c[1]-s.p0y,c[0]-s.p0x),hl2=Math.max(10,s.strokeW*4);
        ctx.beginPath();ctx.moveTo(c[0],c[1]);
        ctx.lineTo(c[0]-hl2*Math.cos(a2-0.42),c[1]-hl2*Math.sin(a2-0.42));
        ctx.moveTo(c[0],c[1]);
        ctx.lineTo(c[0]-hl2*Math.cos(a2+0.42),c[1]-hl2*Math.sin(a2+0.42));
        ctx.stroke(); break;
    }
    ctx.restore();
  }

  function onUp(e){
    if(s.dragging){s.dragging=false;s.dragObjIdx=-1;snapshot();renderAll();return;}
    if(!s.drawing) return;
    s.drawing=false;
    var src=e.changedTouches?e.changedTouches[0]:e;
    var r=cv.getBoundingClientRect();
    var c=[src.clientX-r.left,src.clientY-r.top];
    var w=c[0]-s.p0x,h=c[1]-s.p0y;
    if(s.tool==='pen'){
      if(s.penPts.length>2){snapshot();s.objects.push({type:'pen',pts:s.penPts.slice(),stroke:s.strokeCol,fill:'none',sw:s.strokeW});}
      s.penPts=[]; renderAll(); return;
    }
    var obj=null;
    switch(s.tool){
      case 'rect': if(Math.abs(w)<3&&Math.abs(h)<3) break;
        obj={type:'rect',x:Math.min(s.p0x,c[0]),y:Math.min(s.p0y,c[1]),w:Math.abs(w),h:Math.abs(h),stroke:s.strokeCol,fill:s.fillCol,sw:s.strokeW}; break;
      case 'ell':  if(Math.abs(w)<3&&Math.abs(h)<3) break;
        obj={type:'ell',x:Math.min(s.p0x,c[0]),y:Math.min(s.p0y,c[1]),w:Math.abs(w),h:Math.abs(h),stroke:s.strokeCol,fill:s.fillCol,sw:s.strokeW}; break;
      case 'dia':  if(Math.abs(w)<3&&Math.abs(h)<3) break;
        obj={type:'dia',x:Math.min(s.p0x,c[0]),y:Math.min(s.p0y,c[1]),w:Math.abs(w),h:Math.abs(h),stroke:s.strokeCol,fill:s.fillCol,sw:s.strokeW}; break;
      case 'line': if(Math.abs(w)<2&&Math.abs(h)<2) break;
        obj={type:'line',x:s.p0x,y:s.p0y,x2:c[0],y2:c[1],stroke:s.strokeCol,fill:s.strokeCol,sw:s.strokeW}; break;
      case 'arr':  if(Math.abs(w)<2&&Math.abs(h)<2) break;
        obj={type:'arr',x:s.p0x,y:s.p0y,x2:c[0],y2:c[1],stroke:s.strokeCol,fill:s.strokeCol,sw:s.strokeW}; break;
    }
    if(obj){snapshot();s.objects.push(obj);}
    renderAll();
  }

  /* ResizeObserver: re-render when wrap changes size (tab show/hide) */
  if(window.ResizeObserver){
    var ro=new ResizeObserver(function(entries){
      var newW=Math.floor(entries[0].contentRect.width);
      if(newW>10&&newW!==cv.width){cv.width=newW;}
      if(newW>10) renderAll();
    });
    ro.observe(wrap);
  }

  renderAll();
};

window.resetDiag=function(id){
  var s=window.DG[id];
  if(!s){window.initDiag(id);return;}
  s.objects=JSON.parse(JSON.stringify(s.seed));
  s.selected=-1;s.undoStack=[];s.redoStack=[];
  dgRenderAll(s);
};

window.copyToWB=function(id){
  var s=window.DG[id]; if(!s) return;
  try{sessionStorage.setItem('dg_paste_objects',JSON.stringify(s.objects));
      sessionStorage.setItem('dg_paste_source',id);}catch(e){}
  var btn=event&&event.target;
  if(btn){var orig=btn.innerHTML;btn.innerHTML='&#10003; Copied!';btn.style.background='#1a9b6b';
    setTimeout(function(){btn.innerHTML=orig;btn.style.background='';},1800);}
};

/* Re-init all canvases whenever the sidebar is clicked */
(function(){
  function tryInitAll(){
    if(!window.DIAGRAMS) return;
    Object.keys(window.DIAGRAMS).forEach(function(id){
      var cv=document.getElementById(id);
      if(cv&&Math.floor(cv.getBoundingClientRect().width)>10){
        window.initDiag(id);
      }
    });
  }
  document.addEventListener('click',function(e){
    var t=e.target;
    if(t&&(t.closest&&(t.closest('.sidebar-menu')||t.closest('.nav-tabs')))){
      setTimeout(tryInitAll,250);
      setTimeout(tryInitAll,600);
    }
  });
  window.addEventListener('load',function(){
    setTimeout(tryInitAll,400);
    setTimeout(tryInitAll,1200);
    setTimeout(tryInitAll,2500);
  });
})();
