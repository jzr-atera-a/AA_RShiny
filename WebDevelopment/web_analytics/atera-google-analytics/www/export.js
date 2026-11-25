/* Atera Analytics - chart export.
 * Adds a "Save" button to every chart card, renders the chosen formats in the
 * browser (HTML, PNG, SVG, PDF, GIF, JPEG, WebP, Plotly JSON, CSV), then either
 * downloads them (one file, or a .zip that mirrors the Drive folders) and/or
 * streams them to the R server in chunks for upload to Google Drive.
 */
(function () {
  'use strict';

  var SAVE_ICON = '<svg viewBox="0 0 24 24" width="15" height="15" aria-hidden="true"><path fill="currentColor" d="M19.35 10.04A7.49 7.49 0 0 0 12 4C9.11 4 6.6 5.64 5.35 8.04A6 6 0 0 0 6 20h13a5 5 0 0 0 .35-9.96zM14 13v4h-4v-4H7l5-5 5 5h-3z"/></svg>';
  var THEMES = {
    dark:  { bg: '#121c33', ink: '#e8edf7', ink2: '#aab6cf', muted: '#7f8cab', grid: '#22304f', land: '#1b2744', border: '#2a3a5e' },
    light: { bg: '#ffffff', ink: '#22313f', ink2: '#4a5a68', muted: '#6b7a86', grid: '#e6ecec', land: '#eef3f3', border: '#c9d6d6' }
  };
  var MIME = { png: 'image/png', jpeg: 'image/jpeg', webp: 'image/webp', svg: 'image/svg+xml', pdf: 'application/pdf',
               gif: 'image/gif', html: 'text/html', json: 'application/json', csv: 'text/csv' };
  var busy = false;

  // ---------- helpers ----------
  function sleep(ms) { return new Promise(function (r) { setTimeout(r, ms); }); }
  function esc(s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
  function utf8(s) { return new TextEncoder().encode(s); }
  function arr(v) { return Array.isArray(v) ? v : (v === undefined || v === null ? [] : [v]); }
  function clean(o) {
    return JSON.parse(JSON.stringify(o === undefined ? {} : o, function (k, v) {
      if (k && k.charAt(0) === '_') return undefined;
      if (v && ArrayBuffer.isView(v)) return Array.prototype.slice.call(v);
      return v;
    }));
  }
  function dataUrlBytes(url) {
    var i = url.indexOf(','), head = url.slice(0, i), body = url.slice(i + 1);
    if (/;base64$/.test(head)) {
      var bin = atob(body), out = new Uint8Array(bin.length);
      for (var k = 0; k < bin.length; k++) out[k] = bin.charCodeAt(k);
      return out;
    }
    return utf8(decodeURIComponent(body));
  }
  function b64(bytes) {
    var s = '', CH = 0x8000;
    for (var i = 0; i < bytes.length; i += CH) s += String.fromCharCode.apply(null, bytes.subarray(i, i + CH));
    return btoa(s);
  }
  function status(text, isErr, hideAfter) {
    var el = document.getElementById('atera-export-status');
    if (!el) { el = document.createElement('div'); el.id = 'atera-export-status'; el.setAttribute('role', 'status'); document.body.appendChild(el); }
    el.textContent = text;
    el.className = 'show' + (isErr ? ' err' : '');
    clearTimeout(el._t);
    if (hideAfter) el._t = setTimeout(function () { el.className = ''; }, hideAfter);
  }

  // ---------- finding charts ----------
  function gdOf(el) {
    if (!el) return null;
    if (el.classList && el.classList.contains('js-plotly-plot')) return el;
    return el.querySelector('.js-plotly-plot');
  }
  function isDrawn(el) {
    var gd = gdOf(el);
    return !!(gd && gd.data && gd.data.length && !el.classList.contains('shiny-output-error') && el.offsetParent !== null);
  }
  // The page id: the inner tab's value (pages shown as tabs), or the sidebar item for one-page groups.
  function pageOf(el) {
    var inner = el.closest('.section-tabs .tab-pane[data-value]');
    if (inner) { return inner.getAttribute('data-value'); }
    var outer = el.closest('.tab-pane');
    var first = outer && outer.querySelector('.tab-pane[data-value]');
    if (first) { return first.getAttribute('data-value'); }
    return outer ? (outer.getAttribute('data-page') || outer.id.replace(/^shiny-tab-/, '')) : '';
  }
  function chartInfo(el) {
    var card = el.closest('.ga-card'), t = card && card.querySelector('.ga-card-title');
    return { id: el.id, title: ((t && t.textContent) || el.id).trim(), tab: pageOf(el) };
  }
  function chartsIn(root) { return Array.prototype.slice.call((root || document).querySelectorAll('.ga-card .html-widget-output.plotly')); }

  function addButtons() {
    chartsIn(document).forEach(function (el) {
      var card = el.closest('.ga-card');
      if (!card || !el.id || card.querySelector('.chart-save-btn[data-target="' + el.id + '"]')) return;
      var btn = document.createElement('button');
      btn.type = 'button'; btn.className = 'chart-save-btn'; btn.setAttribute('data-target', el.id);
      btn.title = 'Save this chart to Google Drive or your computer';
      btn.innerHTML = SAVE_ICON + '<span>Save</span>';
      btn.addEventListener('click', function (ev) { ev.preventDefault(); openSave([el]); });
      var head = card.querySelector(':scope > .ga-card-head');
      if (head) {
        var tools = head.querySelector(':scope > .ga-card-tools');
        if (!tools) { tools = document.createElement('div'); tools.className = 'ga-card-tools'; head.appendChild(tools); }
        tools.insertBefore(btn, tools.firstChild);
      } else {
        btn.classList.add('floating');
        el.parentNode.insertBefore(btn, el);
      }
    });
  }

  function openSave(els) {
    if (busy) { status('A save is already running - please wait for it to finish.', true, 4000); return; }
    var ready = els.filter(isDrawn);
    if (!ready.length) { status('Nothing to save yet: the chart has not been drawn, or it is showing a message instead.', true, 5000); return; }
    Shiny.setInputValue('atera_save_open', JSON.stringify({
      charts: ready.map(chartInfo), skipped: els.length - ready.length, nonce: Date.now() + Math.random()
    }), { priority: 'event' });
  }

  window.ateraSaveTab = function () {
    var pane = document.querySelector('.content > .tab-content > .tab-pane.active, .tab-content > .tab-pane.active');
    var inner = pane && pane.querySelector('.section-tabs .tab-content > .tab-pane.active');
    var els = chartsIn(inner || pane);
    if (!els.length) { status('This page has no charts to save.', true, 4000); return; }
    openSave(els);
  };

  // ---------- figure preparation ----------
  function exportFigure(gd, ch, th, msg) {
    var data = clean(gd.data), layout = clean(gd.layout);
    var W = 1200, ratio = (gd.clientHeight || 360) / Math.max(400, gd.clientWidth || 800);
    var legend = layout.showlegend !== false && layout.legend && layout.showlegend;
    var top = legend ? 108 : 84;
    var H = Math.max(480, Math.min(900, Math.round(W * ratio) + top));
    layout.width = W; layout.height = H; layout.autosize = false;
    layout.paper_bgcolor = th.bg; layout.plot_bgcolor = th.bg;
    layout.font = Object.assign({}, layout.font, { color: th.ink2, family: 'Segoe UI, Helvetica, Arial, sans-serif' });
    layout.title = {
      text: '<b>' + esc(ch.title) + '</b><br><span style="font-size:12px;color:' + th.muted + '">' + esc(ch.subtitle || '') + '</span>',
      x: 0, xanchor: 'left', xref: 'container', y: 1, yref: 'container', yanchor: 'top',
      pad: { t: 18, l: 24 }, font: { color: th.ink, size: 18 }
    };
    layout.margin = { l: 24, r: 28, b: 24, t: top, pad: 0 };
    Object.keys(layout).forEach(function (k) {
      if (!/^[xy]axis\d*$/.test(k) || !layout[k]) return;
      var a = layout[k];
      if (!(a.gridcolor && /rgba\(0,\s*0,\s*0,\s*0\)/.test(a.gridcolor))) a.gridcolor = th.grid;
      a.linecolor = th.grid;
      if (a.zerolinecolor) a.zerolinecolor = th.muted;
      a.tickfont = Object.assign({}, a.tickfont, { color: th.muted });
      if (typeof a.title === 'string') a.title = { text: a.title };
      if (a.title && typeof a.title === 'object') a.title.font = Object.assign({}, a.title.font, { color: th.ink2 });
      a.automargin = true;
    });
    if (layout.legend) {
      layout.legend.font = Object.assign({}, layout.legend.font, { color: th.ink2 });
      layout.legend.y = 1.0; layout.legend.yanchor = 'bottom'; layout.legend.x = 0; layout.legend.xanchor = 'left';
    }
    if (layout.geo) Object.assign(layout.geo, { bgcolor: th.bg, landcolor: th.land, countrycolor: th.border });
    data.forEach(function (t) {
      if (t.textfont && /^#(aab6cf|4a5a68)$/i.test(t.textfont.color || '')) t.textfont.color = th.ink2;
      if (t.marker && t.marker.line && /^#(121c33|ffffff)$/i.test(t.marker.line.color || '')) t.marker.line.color = th.bg;
      if (t.connector && t.connector.fillcolor) t.connector.fillcolor = th.land;
    });
    return { data: data, layout: layout };
  }

  function withOffscreen(fig, fn) {
    var div = document.createElement('div');
    div.style.cssText = 'position:fixed;left:-30000px;top:0;pointer-events:none;width:' + fig.layout.width + 'px;height:' + fig.layout.height + 'px;';
    document.body.appendChild(div);
    var cfg = { staticPlot: true, displayModeBar: false };
    return Plotly.newPlot(div, fig.data, fig.layout, cfg)
      .then(function () { return fn(div, cfg); })
      .then(function (res) { cleanup(); return res; }, function (err) { cleanup(); throw err; });
    function cleanup() { try { Plotly.purge(div); } catch (e) { /* ignore */ } div.remove(); }
  }

  function renderImage(fig, format, scale) {
    return withOffscreen(fig, function (div) {
      return Plotly.toImage(div, { format: format, width: fig.layout.width, height: fig.layout.height, scale: scale });
    });
  }

  // ---------- formats ----------
  function makePdf(fig, ch) {
    return renderImage(fig, 'png', 2).then(function (png) {
      var JsPDF = window.jspdf && window.jspdf.jsPDF;
      if (!JsPDF) throw new Error('the PDF library did not load');
      var w = fig.layout.width * 0.75, h = fig.layout.height * 0.75;
      var doc = new JsPDF({ orientation: w > h ? 'landscape' : 'portrait', unit: 'pt', format: [w, h], compress: true });
      doc.setProperties({ title: ch.title, subject: ch.subtitle || '', creator: 'Atera Analytics dashboard' });
      doc.addImage(png, 'PNG', 0, 0, w, h, undefined, 'FAST');
      return new Uint8Array(doc.output('arraybuffer'));
    });
  }

  function isTimeX(t) {
    var x = t.x;
    return Array.isArray(x) && x.length >= 5 && (!t.type || t.type === 'scatter' || t.type === 'bar' || t.type === 'scattergl') &&
      typeof x[0] === 'string' && /^\d{4}-\d{2}-\d{2}/.test(x[0]);
  }
  function timeCuts(data) {
    var seen = {};
    data.forEach(function (t) { if (isTimeX(t)) t.x.forEach(function (v) { seen[String(v)] = 1; }); });
    var all = Object.keys(seen).sort();
    if (all.length < 5) return null;
    var N = Math.min(24, all.length), cuts = [];
    for (var k = 1; k <= N; k++) cuts.push(all[Math.max(0, Math.ceil(all.length * k / N) - 1)]);
    return cuts;
  }
  function sliceData(data, cut) {
    return data.map(function (t) {
      if (!isTimeX(t)) return t;
      var n = t.x.length, keep = t.x.map(function (v) { return String(v) <= cut; }), c = Object.assign({}, t);
      var pick = function (a) { return a.filter(function (_, i) { return keep[i]; }); };
      ['x', 'y', 'text', 'hovertext', 'customdata', 'ids'].forEach(function (k) { if (Array.isArray(t[k]) && t[k].length === n) c[k] = pick(t[k]); });
      if (t.marker && Array.isArray(t.marker.color) && t.marker.color.length === n) c.marker = Object.assign({}, t.marker, { color: pick(t.marker.color) });
      return c;
    });
  }

  function makeGif(fig0, animate) {
    var enc = window.gifenc;
    if (!enc) return Promise.reject(new Error('the GIF library did not load'));
    var fig = JSON.parse(JSON.stringify(fig0));
    var W = 960, H = Math.round(fig.layout.height * W / fig.layout.width);
    fig.layout.width = W; fig.layout.height = H;
    var cuts = animate ? timeCuts(fig.data) : null;
    return withOffscreen(fig, async function (div, cfg) {
      var canvas = document.createElement('canvas'); canvas.width = W; canvas.height = H;
      var ctx = canvas.getContext('2d', { willReadFrequently: true }), frames = [];
      async function grab() {
        var url = await Plotly.toImage(div, { format: 'png', width: W, height: H, scale: 1 });
        var img = new Image(); img.src = url; await img.decode();
        ctx.clearRect(0, 0, W, H); ctx.drawImage(img, 0, 0, W, H);
        frames.push(ctx.getImageData(0, 0, W, H).data);
      }
      if (cuts && cuts.length > 1) {
        var full = JSON.parse(JSON.stringify(fig.data)), lay = JSON.parse(JSON.stringify(fig.layout)), fl = div._fullLayout || {};
        Object.keys(fl).forEach(function (k) {   // freeze the axes so the chart "draws itself" without rescaling
          if (/^[xy]axis\d*$/.test(k) && fl[k] && Array.isArray(fl[k].range)) lay[k] = Object.assign({}, lay[k], { range: fl[k].range.slice(), autorange: false });
        });
        for (var i = 0; i < cuts.length; i++) {
          await Plotly.react(div, sliceData(full, cuts[i]), lay, cfg);
          await grab();
          status('Drawing animated GIF: frame ' + (i + 1) + ' of ' + cuts.length);
        }
      } else {
        await grab();
      }
      var palette = enc.quantize(frames[frames.length - 1], 256), gif = enc.GIFEncoder();
      frames.forEach(function (px, i) {
        gif.writeFrame(enc.applyPalette(px, palette), W, H, { palette: palette, delay: i === frames.length - 1 ? 2500 : 90 });
      });
      gif.finish();
      return gif.bytes();
    });
  }

  function figurePayload(fig, ch, msg) {
    var layout = Object.assign({}, fig.layout);
    delete layout.width; delete layout.height; layout.autosize = true;
    return {
      meta: { app: 'Atera Analytics', chart: ch.title, chart_id: ch.id, tab: ch.tab_label || ch.tab, subtitle: ch.subtitle || '',
              source: msg.source || '', saved_at: msg.saved_at || '', plotly_version: (window.Plotly && Plotly.version) || '' },
      data: fig.data, layout: layout
    };
  }

  function buildHtml(fig, ch, msg, th) {
    var payload = JSON.stringify(figurePayload(fig, ch, msg)).replace(/</g, '\\u003c');
    var ver = (window.Plotly && Plotly.version) || '2.11.1';
    return '<!doctype html>\n<html lang="en"><head><meta charset="utf-8">' +
      '<meta name="viewport" content="width=device-width, initial-scale=1">' +
      '<title>' + esc(ch.title) + '</title>' +
      '<script src="https://cdn.plot.ly/plotly-' + ver + '.min.js"></script>' +
      '<style>html,body{margin:0;background:' + th.bg + ';color:' + th.ink + ';font-family:Segoe UI,Helvetica,Arial,sans-serif}' +
      '#chart{width:100%;height:calc(100vh - 34px);min-height:420px}footer{font-size:12px;color:' + th.muted + ';padding:8px 16px}</style>' +
      '</head><body><div id="chart"></div>' +
      '<footer>' + esc(msg.source || '') + ' &middot; saved ' + esc(msg.saved_at || '') + '</footer>' +
      '<script type="application/json" id="atera-figure">' + payload + '</script>' +
      '<script>var f=JSON.parse(document.getElementById("atera-figure").textContent);' +
      'Plotly.newPlot("chart",f.data,f.layout,{responsive:true,displaylogo:false});</script>' +
      '</body></html>\n';
  }

  function csvCell(v) {
    if (v === null || v === undefined) return '';
    var s = String(v);
    return /[",\r\n]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
  }
  function chartCsv(fig) {
    var rows = [['series', 'x', 'y', 'z']];
    fig.data.forEach(function (t, i) {
      var name = t.name || ('series ' + (i + 1));
      if (t.type === 'heatmap' && Array.isArray(t.z)) {
        var xs = arr(t.x), ys = arr(t.y);
        t.z.forEach(function (row, r) { arr(row).forEach(function (v, c) { rows.push([name, xs.length ? xs[c] : c, ys.length ? ys[r] : r, v]); }); });
      } else if (t.type === 'choropleth') {
        var z = arr(t.z); arr(t.locations).forEach(function (l, k) { rows.push([name, l, z[k], '']); });
      } else if (t.type === 'pie') {
        var vals = arr(t.values); arr(t.labels).forEach(function (l, k) { rows.push([name, l, vals[k], '']); });
      } else {
        var x = arr(t.x), y = arr(t.y), n = Math.max(x.length, y.length);
        for (var k = 0; k < n; k++) rows.push([name, x[k], y[k], '']);
      }
    });
    return rows.map(function (r) { return r.map(csvCell).join(','); }).join('\r\n') + '\r\n';
  }

  async function buildFile(gd, ch, fmt, msg) {
    var th = msg.light ? THEMES.light : THEMES.dark, fig = exportFigure(gd, ch, th, msg);
    switch (fmt) {
      case 'png': case 'jpeg': case 'webp': return dataUrlBytes(await renderImage(fig, fmt, 2));
      case 'svg':  return dataUrlBytes(await renderImage(fig, 'svg', 1));
      case 'pdf':  return makePdf(fig, ch);
      case 'gif':  return makeGif(fig, msg.animate);
      case 'html': return utf8(buildHtml(fig, ch, msg, th));
      case 'json': return utf8(JSON.stringify(figurePayload(fig, ch, msg), null, 1));
      case 'csv':  return utf8('﻿' + chartCsv(fig));
    }
    throw new Error('unknown format ' + fmt);
  }

  // ---------- delivery ----------
  function send(obj) { Shiny.setInputValue('atera_export_msg', JSON.stringify(obj), { priority: 'event' }); }

  async function sendFile(req, chartId, ext, bytes) {
    var data = b64(bytes), CH = 1000000, n = Math.max(1, Math.ceil(data.length / CH));
    for (var i = 0; i < n; i++) {
      send({ type: 'file', req: req, chart_id: chartId, ext: ext, mime: MIME[ext], chunk: i, n_chunks: n,
             data: data.slice(i * CH, (i + 1) * CH) });
      await sleep(40);
    }
  }

  function saveBlob(blob, name) {
    var a = document.createElement('a');
    a.href = URL.createObjectURL(blob); a.download = name;
    document.body.appendChild(a); a.click();
    setTimeout(function () { URL.revokeObjectURL(a.href); a.remove(); }, 3000);
  }

  async function downloadLocal(files, zipName) {
    if (files.length === 1) {
      var f = files[0];
      saveBlob(new Blob([f.bytes], { type: MIME[f.ext] }), f.path.split('/').pop());
      return;
    }
    if (!window.JSZip) throw new Error('the ZIP library did not load');
    var zip = new JSZip();
    files.forEach(function (f) { zip.file(f.path, f.bytes); });
    saveBlob(await zip.generateAsync({ type: 'blob', compression: 'DEFLATE' }), zipName);
  }

  async function runExport(msg) {
    var toLocal = msg.dest !== 'drive', toDrive = msg.dest !== 'local';
    var local = [], total = msg.charts.length * msg.formats.length, done = 0, failed = 0;
    busy = true;
    try {
      status('Preparing 0 of ' + total + ' files...');
      for (var c = 0; c < msg.charts.length; c++) {
        var ch = msg.charts[c], el = document.getElementById(ch.id);
        if (!isDrawn(el)) {
          failed += msg.formats.length; done += msg.formats.length;
          if (toDrive) send({ type: 'skip', req: msg.req, chart_id: ch.id, reason: 'the chart was not drawn' });
          continue;
        }
        var gd = gdOf(el);
        for (var f = 0; f < msg.formats.length; f++) {
          var fmt = msg.formats[f], bytes;
          try {
            bytes = await buildFile(gd, ch, fmt, msg);
          } catch (e) {
            console.error('[atera export]', ch.id, fmt, e);
            failed++; done++;
            if (toDrive) send({ type: 'skip', req: msg.req, chart_id: ch.id, ext: fmt, reason: (e && e.message) || String(e) });
            continue;
          }
          if (toLocal) local.push({ path: ch.paths[fmt], ext: fmt, bytes: bytes });
          if (toDrive) await sendFile(msg.req, ch.id, fmt, bytes);
          done++;
          status('Prepared ' + done + ' of ' + total + ' files' + (toDrive ? ' (uploading as they are ready)' : ''));
        }
      }
      if (toLocal && local.length) await downloadLocal(local, msg.zip_name);
      if (toDrive) send({ type: 'done', req: msg.req, failed: failed });
      if (failed && !toDrive) status(failed + ' file(s) could not be made - see the browser console.', true, 6000);
      else status(toDrive ? 'All files handed to the server for upload.' : 'Downloaded ' + local.length + ' file(s).', false, 3500);
    } finally {
      busy = false;
    }
  }

  // ---------- wiring ----------
  function init() {
    addButtons();
    var pending = false;
    new MutationObserver(function () {
      if (pending) return;
      pending = true;
      setTimeout(function () { pending = false; addButtons(); }, 300);
    }).observe(document.body, { childList: true, subtree: true });
    Shiny.addCustomMessageHandler('atera-export', function (msg) {
      runExport(msg).catch(function (e) {
        console.error('[atera export]', e);
        status('Saving failed: ' + ((e && e.message) || e), true, 8000);
        if (msg.dest !== 'local') send({ type: 'done', req: msg.req, error: String((e && e.message) || e) });
      });
    });
  }
  if (window.Shiny && Shiny.addCustomMessageHandler) {
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
  } else {
    document.addEventListener('DOMContentLoaded', init);
  }
})();
