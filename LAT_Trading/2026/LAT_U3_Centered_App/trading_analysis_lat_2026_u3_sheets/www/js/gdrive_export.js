// www/js/gdrive_export.js
// A small "save to Google Drive" button on every chart (Plotly), diagram (SVG), picture and table of the app, shown once
// Google Drive is connected (API Configuration > Google Drive). The button captures the item in the browser and sends it
// to the app, which asks which formats to save and puts the files in the folder of the menu group / tab / sub-tab.
(function () {
  var kinds = { plotly: true, svg: true, img: true, table: true }, on = false, seq = 0, store = {}, batch = null;
  function txt(el) { return el ? (el.textContent || '').replace(/\s+/g, ' ').trim() : ''; }
  function visible(el) { return !!(el && el.offsetParent !== null && el.offsetWidth > 0 && el.offsetHeight > 0); }

  // menu group / tab / sub-tabs of an element
  function pathOf(el) {
    var parts = [], pane = el.closest('.tab-pane[id^="shiny-tab-"]');
    if (pane) {
      var tn = pane.id.replace('shiny-tab-', ''), a = document.querySelector('.sidebar-menu a[data-value="' + tn + '"]');
      var tab = txt(a) || tn, tv = a ? a.closest('li.treeview') : null, grp = tab;
      if (tv) { var g = tv.querySelector(':scope > a > span') || tv.querySelector(':scope > a'); grp = txt(g) || tab; }
      parts.push(grp, tab);
    } else parts.push('General');
    var sub = [], p = el.parentElement;
    while (p && p !== pane && p !== document.body) {
      if (p.classList && p.classList.contains('tab-pane') && p.id) {
        var l = document.querySelector('a[data-toggle="tab"][href="#' + p.id + '"], a[data-bs-toggle="tab"][href="#' + p.id + '"]');
        if (l && txt(l)) sub.unshift(txt(l));
      }
      p = p.parentElement;
    }
    return parts.concat(sub);
  }
  function titleOf(el, kind) {
    var t = '';
    if (kind === 'plotly' && el.layout) { var lt = el.layout.title; t = typeof lt === 'string' ? lt : ((lt && lt.text) || ''); t = t.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim(); }
    if (!t) { var c = el.closest('details'); if (c) t = txt(c.querySelector('summary')); }
    if (!t) { var b = el.closest('.box'); if (b) t = txt(b.querySelector('.box-title')); }
    if (!t) {
      var s = el;
      for (var i = 0; i < 4 && s && !t; i++) {
        var q = s.previousElementSibling;
        while (q && !t) { var x = txt(q); if (/^(H[1-6]|B|STRONG|DIV|P|LABEL)$/.test(q.tagName) && x.length > 2 && x.length < 120 && !q.querySelector('svg,table,.js-plotly-plot,img')) t = x; q = q.previousElementSibling; }
        s = s.parentElement;
      }
    }
    if (!t) { var o = el.closest('[id]'); t = o ? o.id.replace(/^.*-/, '') : ''; }
    return (t || kind).slice(0, 90);
  }

  // every item that can be saved, inside root
  function targets(root) {
    var out = [];
    root.querySelectorAll('.js-plotly-plot').forEach(function (el) { out.push({ el: el, host: el, kind: 'plotly' }); });
    root.querySelectorAll('svg').forEach(function (el) {
      if (el.closest('.js-plotly-plot, .gdx-btn, button, a, .modal, .sidebar, .main-header, .leaflet-container') || el.classList.contains('main-svg')) return;
      var r = el.getBoundingClientRect(); if (r.width < 180 || r.height < 90) return;
      out.push({ el: el, host: el.parentElement, kind: 'svg' });
    });
    root.querySelectorAll('.shiny-image-output img, .shiny-plot-output img, .box-body img[src^="data:image"], .gdx-img').forEach(function (el) {
      if (el.closest('.modal, .gdx-btn')) return; if ((el.naturalWidth || 0) < 300) return;
      out.push({ el: el, host: el.parentElement, kind: 'img' });
    });
    root.querySelectorAll('.dataTables_wrapper').forEach(function (el) {
      if (el.closest('.modal')) return; var t = el.querySelector('.dataTables_scrollBody table') || el.querySelector('table.dataTable');
      if (t) out.push({ el: t, host: el, kind: 'table', wrap: el });
    });
    return out.filter(function (t) { return kinds[t.kind] && t.host && !t.host.closest('#shiny-tab-gdrive_config'); });
  }

  // ---- capture -------------------------------------------------------------------------------------------
  function svgText(el) {
    var c = el.cloneNode(true), r = el.getBoundingClientRect();
    c.setAttribute('xmlns', 'http://www.w3.org/2000/svg'); c.setAttribute('xmlns:xlink', 'http://www.w3.org/1999/xlink');
    if (!c.getAttribute('width')) c.setAttribute('width', Math.round(r.width)); if (!c.getAttribute('height')) c.setAttribute('height', Math.round(r.height));
    // copy the styles the page gives the shapes and text, so the file looks the same outside the app
    var a = el.querySelectorAll('*'), b = c.querySelectorAll('*'), keys = ['fill', 'stroke', 'stroke-width', 'stroke-dasharray', 'font-size', 'font-weight', 'font-family', 'opacity', 'text-anchor'];
    for (var i = 0; i < a.length && i < 4000; i++) { var cs = getComputedStyle(a[i]), st = ''; keys.forEach(function (k) { var v = cs.getPropertyValue(k); if (v) st += k + ':' + v + ';'; }); if (st) b[i].setAttribute('style', st + (b[i].getAttribute('style') || '')); }
    return new XMLSerializer().serializeToString(c);
  }
  function svgPng(s, w, h) {
    return new Promise(function (ok) {
      var im = new Image(); im.onload = function () { var cv = document.createElement('canvas'); cv.width = w * 2; cv.height = h * 2; var x = cv.getContext('2d'); x.fillStyle = '#fff'; x.fillRect(0, 0, cv.width, cv.height); x.drawImage(im, 0, 0, cv.width, cv.height); try { ok(cv.toDataURL('image/png')); } catch (e) { ok(''); } };
      im.onerror = function () { ok(''); }; im.src = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(s);
    });
  }
  function imgPng(el) {
    return new Promise(function (ok) { try { var cv = document.createElement('canvas'); cv.width = el.naturalWidth; cv.height = el.naturalHeight; cv.getContext('2d').drawImage(el, 0, 0); ok(cv.toDataURL('image/png')); } catch (e) { ok(''); } });
  }
  function csvOf(t) {
    var q = function (s) { s = (s || '').replace(/\s+/g, ' ').trim(); return /[",\n]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s; };
    var w = t.closest('.dataTables_wrapper'), hd = w ? (w.querySelector('.dataTables_scrollHead thead') || t.querySelector('thead')) : t.querySelector('thead');
    var rows = [];
    if (hd) hd.querySelectorAll('tr').forEach(function (tr) { rows.push(Array.prototype.map.call(tr.children, function (c) { return q(c.innerText); }).join(',')); });
    t.querySelectorAll('tbody tr').forEach(function (tr) { if (tr.querySelector('.dataTables_empty')) return; rows.push(Array.prototype.map.call(tr.children, function (c) { return q(c.innerText); }).join(',')); });
    return rows.join('\n');
  }
  function capture(t) {
    var el = t.el, w = Math.round(el.getBoundingClientRect().width) || 900, h = Math.round(el.getBoundingClientRect().height) || 500;
    var p = { kind: t.kind, title: titleOf(el, t.kind), path: pathOf(el), w: w, h: h };
    if (t.kind === 'plotly') {
      return Promise.all([
        window.Plotly.toImage(el, { format: 'png', width: w, height: h, scale: 2 }).catch(function () { return ''; }),
        window.Plotly.toImage(el, { format: 'svg', width: w, height: h }).catch(function () { return ''; })
      ]).then(function (r) {
        p.png = r[0]; var s = r[1] || '';
        if (s.indexOf(';base64,') > 0) s = atob(s.split(';base64,')[1]); else if (s) s = decodeURIComponent(s.replace(/^data:image\/svg\+xml[^,]*,/, ''));
        p.svg = s;
        try { p.fig = (window.Plotly.Plots && window.Plotly.Plots.graphJson) ? window.Plotly.Plots.graphJson(el, false, 'keepdata') : JSON.stringify({ data: el.data, layout: el.layout }); } catch (e) { p.fig = ''; }
        return p;
      });
    }
    if (t.kind === 'svg') { p.svg = svgText(el); return svgPng(p.svg, w, h).then(function (png) { p.png = png; return p; }); }
    if (t.kind === 'img') return imgPng(el).then(function (png) { p.png = png || (el.src.indexOf('data:image/png') === 0 ? el.src : ''); return p; });
    var c = el.cloneNode(true); c.removeAttribute('style'); c.querySelectorAll('[style]').forEach(function (x) { x.removeAttribute('style'); });
    var w2 = el.closest('.dataTables_wrapper'), hd = w2 ? w2.querySelector('.dataTables_scrollHead thead') : null;
    if (hd && !c.querySelector('thead th')) { var old = c.querySelector('thead'); if (old) old.remove(); c.insertBefore(hd.cloneNode(true), c.firstChild); }
    var info = w2 ? txt(w2.querySelector('.dataTables_info')) : '';
    p.html = c.outerHTML; p.csv = csvOf(el); p.note = info ? '<div class="m">' + info.replace(/[<>&]/g, '') + ' (the rows shown on screen)</div>' : '';
    return Promise.resolve(p);
  }

  // ---- buttons -------------------------------------------------------------------------------------------
  var ICON = '<svg viewBox="0 0 24 24" width="14" height="14" aria-hidden="true"><path fill="currentColor" d="M19.35 10.04A7.49 7.49 0 0 0 12 4C9.11 4 6.6 5.64 5.35 8.04A5.994 5.994 0 0 0 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96zM14 13v4h-4v-4H7l5-5 5 5h-3z"/></svg>';
  function addButtons() {
    if (!on) return;
    targets(document).forEach(function (t) {
      var host = t.host; if (!visible(host)) return;
      if (host.querySelector(':scope > .gdx-btn')) return;
      if (getComputedStyle(host).position === 'static') host.style.position = 'relative';
      var b = document.createElement('button'); b.type = 'button'; b.className = 'gdx-btn gdx-' + t.kind; b.title = 'Save to Google Drive'; b.innerHTML = ICON;
      b.addEventListener('click', function (ev) {
        ev.preventDefault(); ev.stopPropagation(); if (b.classList.contains('gdx-busy')) return;
        b.classList.add('gdx-busy');
        var tt = targets(host.parentElement || document).filter(function (x) { return x.host === host; })[0] || t;
        capture(tt).then(function (p) { var id = 'c' + (++seq); store[id] = p; p.cid = id; window.Shiny.setInputValue('gdx_click', p, { priority: 'event' }); })
          .catch(function (e) { window.Shiny.setInputValue('gdx_err', String(e && e.message || e), { priority: 'event' }); })
          .then(function () { b.classList.remove('gdx-busy'); });
      });
      host.appendChild(b);
    });
  }
  function state(m) {
    on = !!m.on; if (m.kinds) { kinds = { plotly: false, svg: false, img: false, table: false }; [].concat(m.kinds).forEach(function (k) { kinds[k] = true; }); }
    document.body.classList.toggle('gdx-on', on);
    document.querySelectorAll('.gdx-btn').forEach(function (b) { var k = (b.className.match(/gdx-(plotly|svg|img|table)/) || [])[1]; if (!on || !kinds[k]) b.remove(); });
    addButtons();
  }
  // "save every item on this page": one at a time, the app answers each before the next is sent
  function sendNext() {
    if (!batch) return;
    if (batch.i >= batch.items.length) { window.Shiny.setInputValue('gdx_item', { batch: batch.id, done: true, n: batch.items.length }, { priority: 'event' }); batch = null; return; }
    var t = batch.items[batch.i];
    capture(t).then(function (p) { p.batch = batch.id; p.i = batch.i + 1; p.n = batch.items.length; p.formats = batch.formats; window.Shiny.setInputValue('gdx_item', p, { priority: 'event' }); })
      .catch(function () { batch.i++; sendNext(); });
  }
  function init() {
    if (!window.Shiny || !window.Shiny.addCustomMessageHandler) { setTimeout(init, 300); return; }
    window.Shiny.addCustomMessageHandler('gdx_state', state);
    window.Shiny.addCustomMessageHandler('gdx_all', function (m) {
      var pane = document.querySelector('.tab-pane[id^="shiny-tab-"].active') || document;
      if (m.kinds) { kinds = { plotly: false, svg: false, img: false, table: false }; [].concat(m.kinds).forEach(function (k) { kinds[k] = true; }); }
      var items = targets(pane).filter(function (t) { return visible(t.host); });
      batch = { id: m.id, items: items, i: 0, formats: m.formats || [] };
      window.Shiny.setInputValue('gdx_item', { batch: m.id, start: true, n: items.length }, { priority: 'event' });
    });
    window.Shiny.addCustomMessageHandler('gdx_ack', function (m) { if (batch && batch.id === m.batch) { if (!m.start) batch.i++; sendNext(); } });
    setInterval(addButtons, 2000);
    $(document).on('shown.bs.tab', function () { setTimeout(addButtons, 400); });
    $(document).on('shiny:value', function () { setTimeout(addButtons, 900); });
  }
  init();
})();
