// www/js/infographic_export.js
//
// Download controls for the Infographic Studio. The infographic is ONE
// self-contained SVG (inline <style>, system fonts only), so every format starts
// from exactly the same picture:
//   PNG / JPEG : SVG -> <canvas> -> blob
//   GIF        : SVG -> <canvas> -> built-in GIF89a encoder (median-cut palette + LZW);
//                animated (one frame per slide) when the infographic has several pages
//   PDF        : SVG -> <canvas> -> jsPDF (one page per slide, a long page, or A4 slices)
//   PPTX       : SVG -> <canvas> -> PNG picture per slide, via pptxgenjs, with the slide text in the notes
//   HTML       : the SVG pages wrapped in a standalone page (links stay clickable)
//   several JPEG/PNG pages are delivered as one ZIP (built-in, no library)
// Entirely client side; external dependencies are jsPDF and pptxgenjs, which the app
// already loads for its other exports.

(function () {

  function safeName(name) {
    var s = (name || "infographic").replace(/[^a-z0-9_\- ]+/gi, "").trim().replace(/\s+/g, "_");
    return (s.length ? s : "infographic").substring(0, 80);
  }
  function download(blob, filename) {
    var url = URL.createObjectURL(blob), a = document.createElement("a");
    a.href = url; a.download = filename; document.body.appendChild(a); a.click();
    setTimeout(function () { document.body.removeChild(a); URL.revokeObjectURL(url); }, 200);
  }
  function indicator(label) {
    var el = document.createElement("div"); el.className = "export-preparing-indicator"; el.innerText = label;
    document.body.appendChild(el); return el;
  }
  function done(el) { if (el && el.parentNode) el.parentNode.removeChild(el); }

  function findPages(targetId) {
    var root = document.getElementById(targetId);
    return root ? Array.prototype.slice.call(root.querySelectorAll("svg.ig-svg")) : [];
  }
  function svgSize(svg) {
    var vb = (svg.getAttribute("viewBox") || "").split(/[\s,]+/).map(Number);
    return { w: vb[2] || parseFloat(svg.getAttribute("width")) || 900, h: vb[3] || parseFloat(svg.getAttribute("height")) || 1200 };
  }
  function svgString(svg) {
    var c = svg.cloneNode(true), s = svgSize(svg);
    c.setAttribute("xmlns", "http://www.w3.org/2000/svg");
    c.setAttribute("width", s.w); c.setAttribute("height", s.h); c.removeAttribute("style");
    return new XMLSerializer().serializeToString(c);
  }

  // SVG -> canvas at `scale` (capped so the bitmap stays within browser limits)
  function rasterize(svg, wantScale) {
    return new Promise(function (resolve, reject) {
      var s = svgSize(svg), scale = Math.min(wantScale, Math.sqrt(14e6 / (s.w * s.h)), 16000 / s.h);
      var img = new Image();
      img.onload = function () {
        var cv = document.createElement("canvas");
        cv.width = Math.round(s.w * scale); cv.height = Math.round(s.h * scale);
        var ctx = cv.getContext("2d");
        ctx.fillStyle = "#ffffff"; ctx.fillRect(0, 0, cv.width, cv.height);
        ctx.drawImage(img, 0, 0, cv.width, cv.height);
        resolve(cv);
      };
      img.onerror = function () { reject(new Error("The browser could not draw the infographic as an image.")); };
      img.src = "data:image/svg+xml;charset=utf-8," + encodeURIComponent(svgString(svg));
    });
  }
  function toBlob(cv, type, q) {
    return new Promise(function (resolve, reject) { cv.toBlob(function (b) { b ? resolve(b) : reject(new Error("Could not create the image.")); }, type, q); });
  }

  // ---------------------------------------------------------------- GIF encoder
  function quantize(data, w, h) {
    var hist = new Uint32Array(32768), n = w * h, i, key;
    for (i = 0; i < n; i++) { key = ((data[i * 4] >> 3) << 10) | ((data[i * 4 + 1] >> 3) << 5) | (data[i * 4 + 2] >> 3); hist[key]++; }
    var cols = [];
    for (key = 0; key < 32768; key++) if (hist[key]) cols.push(key);
    function comp(k, ax) { return ax === 0 ? (k >> 10) & 31 : ax === 1 ? (k >> 5) & 31 : k & 31; }
    var boxes = [cols];
    while (boxes.length < 256) {
      var bi = -1, best = 0, bax = 0, bb;
      for (var b = 0; b < boxes.length; b++) {
        var bx = boxes[b]; if (bx.length < 2) continue;
        for (var ax = 0; ax < 3; ax++) {
          var lo = 99, hi = -1;
          for (var q = 0; q < bx.length; q++) { var v = comp(bx[q], ax); if (v < lo) lo = v; if (v > hi) hi = v; }
          var score = (hi - lo) * Math.sqrt(bx.length);
          if (score > best) { best = score; bi = b; bax = ax; }
        }
      }
      if (bi < 0) break;
      bb = boxes[bi]; bb.sort(function (a, c) { return comp(a, bax) - comp(c, bax); });
      var total = 0, q2; for (q2 = 0; q2 < bb.length; q2++) total += hist[bb[q2]];
      var acc = 0, cut = 1; for (q2 = 0; q2 < bb.length - 1; q2++) { acc += hist[bb[q2]]; if (acc >= total / 2) { cut = q2 + 1; break; } cut = q2 + 1; }
      boxes.splice(bi, 1, bb.slice(0, cut), bb.slice(cut));
    }
    var pal = new Uint8Array(768), np = boxes.length;
    for (var p = 0; p < np; p++) {
      var sr = 0, sg = 0, sb = 0, sc = 0, bx2 = boxes[p];
      for (var t = 0; t < bx2.length; t++) { var c = hist[bx2[t]]; sr += ((bx2[t] >> 10) & 31) * c; sg += ((bx2[t] >> 5) & 31) * c; sb += (bx2[t] & 31) * c; sc += c; }
      pal[p * 3] = Math.min(255, Math.round(sr / sc * 8 + 4)); pal[p * 3 + 1] = Math.min(255, Math.round(sg / sc * 8 + 4)); pal[p * 3 + 2] = Math.min(255, Math.round(sb / sc * 8 + 4));
    }
    var map = new Int16Array(32768).fill(-1), idx = new Uint8Array(n);
    for (i = 0; i < n; i++) {
      key = ((data[i * 4] >> 3) << 10) | ((data[i * 4 + 1] >> 3) << 5) | (data[i * 4 + 2] >> 3);
      var m = map[key];
      if (m < 0) {
        var r = data[i * 4], g = data[i * 4 + 1], bl = data[i * 4 + 2], bd = 1e9, bp = 0;
        for (var pp = 0; pp < np; pp++) { var dr = r - pal[pp * 3], dg = g - pal[pp * 3 + 1], db = bl - pal[pp * 3 + 2], dd = dr * dr + dg * dg + db * db; if (dd < bd) { bd = dd; bp = pp; } }
        map[key] = m = bp;
      }
      idx[i] = m;
    }
    return { pal: pal, idx: idx };
  }

  function lzwEncode(idx, minSize) {
    var clear = 1 << minSize, eoi = clear + 1, freeEnt = clear + 2, nBits = minSize + 1, maxcode = (1 << nBits) - 1;
    var out = [], cur = 0, curBits = 0, clearFlg = false, dict = new Map();
    function output(code) {
      cur |= code << curBits; curBits += nBits;
      while (curBits >= 8) { out.push(cur & 255); cur >>= 8; curBits -= 8; }
      if (freeEnt > maxcode || clearFlg) {
        if (clearFlg) { nBits = minSize + 1; maxcode = (1 << nBits) - 1; clearFlg = false; }
        else { nBits++; maxcode = nBits === 12 ? 4096 : (1 << nBits) - 1; }
      }
    }
    output(clear);
    var ent = idx[0];
    for (var i = 1; i < idx.length; i++) {
      var c = idx[i], key = (ent << 8) | c, v = dict.get(key);
      if (v !== undefined) { ent = v; continue; }
      output(ent); ent = c;
      if (freeEnt < 4096) { dict.set(key, freeEnt++); }
      else { dict = new Map(); freeEnt = clear + 2; clearFlg = true; output(clear); }
    }
    output(ent); output(eoi);
    if (curBits > 0) out.push(cur & 255);
    return out;
  }

  function pushBlocks(bytes, data) {
    for (var i = 0; i < data.length; i += 255) { var n = Math.min(255, data.length - i); bytes.push(n); for (var k = 0; k < n; k++) bytes.push(data[i + k]); }
    bytes.push(0);
  }
  function encodeGIF(w, h, rgba) {
    var q = quantize(rgba, w, h), bytes = [];
    function w16(v) { bytes.push(v & 255, (v >> 8) & 255); }
    var hdr = "GIF89a"; for (var i = 0; i < 6; i++) bytes.push(hdr.charCodeAt(i));
    w16(w); w16(h); bytes.push(0xF7, 0, 0);
    for (i = 0; i < 768; i++) bytes.push(q.pal[i]);
    bytes.push(0x2C); w16(0); w16(0); w16(w); w16(h); bytes.push(0);
    bytes.push(8);
    pushBlocks(bytes, lzwEncode(q.idx, 8));
    bytes.push(0x3B);
    return new Blob([new Uint8Array(bytes)], { type: "image/gif" });
  }
  // animated: one full frame per page, each with its own 256-colour palette, looping forever
  function encodeGIFAnimated(w, h, frames, delayCs) {
    var bytes = [], i;
    function w16(v) { bytes.push(v & 255, (v >> 8) & 255); }
    var hdr = "GIF89a"; for (i = 0; i < 6; i++) bytes.push(hdr.charCodeAt(i));
    w16(w); w16(h); bytes.push(0x70, 0, 0);
    bytes.push(0x21, 0xFF, 0x0B); var app = "NETSCAPE2.0"; for (i = 0; i < 11; i++) bytes.push(app.charCodeAt(i)); bytes.push(3, 1, 0, 0, 0);
    frames.forEach(function (rgba) {
      var q = quantize(rgba, w, h);
      bytes.push(0x21, 0xF9, 4, 0x04); w16(delayCs); bytes.push(0, 0);
      bytes.push(0x2C); w16(0); w16(0); w16(w); w16(h); bytes.push(0x87);
      for (i = 0; i < 768; i++) bytes.push(q.pal[i]);
      bytes.push(8); pushBlocks(bytes, lzwEncode(q.idx, 8));
    });
    bytes.push(0x3B);
    return new Blob([new Uint8Array(bytes)], { type: "image/gif" });
  }
  window.__igEncodeGIF = encodeGIF; window.__igEncodeGIFAnimated = encodeGIFAnimated;

  // ---------------------------------------------------------------- ZIP (store only)
  var crcTable = (function () { var t = [], c, n, k; for (n = 0; n < 256; n++) { c = n; for (k = 0; k < 8; k++) c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1); t[n] = c >>> 0; } return t; })();
  function crc32(u8) { var c = 0xFFFFFFFF; for (var i = 0; i < u8.length; i++) c = crcTable[(c ^ u8[i]) & 255] ^ (c >>> 8); return (c ^ 0xFFFFFFFF) >>> 0; }
  function makeZip(files) {   // files: [{name, data: Uint8Array}]
    var parts = [], central = [], offset = 0, enc = new TextEncoder();
    function u16(v) { return [v & 255, (v >> 8) & 255]; }
    function u32(v) { return [v & 255, (v >>> 8) & 255, (v >>> 16) & 255, (v >>> 24) & 255]; }
    files.forEach(function (f) {
      var name = enc.encode(f.name), crc = crc32(f.data), size = f.data.length;
      var lh = new Uint8Array([0x50, 0x4B, 3, 4].concat(u16(20), u16(0x0800), u16(0), u16(0), u16(0x21), u32(crc), u32(size), u32(size), u16(name.length), u16(0)));
      parts.push(lh, name, f.data);
      central.push(new Uint8Array([0x50, 0x4B, 1, 2].concat(u16(20), u16(20), u16(0x0800), u16(0), u16(0), u16(0x21), u32(crc), u32(size), u32(size), u16(name.length), u16(0), u16(0), u16(0), u16(0), u32(0), u32(offset))), name);
      offset += lh.length + name.length + size;
    });
    var csize = 0; central.forEach(function (c) { csize += c.length; });
    var end = new Uint8Array([0x50, 0x4B, 5, 6].concat(u16(0), u16(0), u16(files.length), u16(files.length), u32(csize), u32(offset), u16(0)));
    return new Blob(parts.concat(central, [end]), { type: "application/zip" });
  }
  window.__igMakeZip = makeZip;

  // ---------------------------------------------------------------- PDF
  function jsPdfCtor() { return (window.jspdf && window.jspdf.jsPDF) ? window.jspdf.jsPDF : window.jsPDF; }
  function makePdfSlides(cvs, svgs) {   // one PDF page per slide, page size = slide size
    var Ctor = jsPdfCtor(); if (!Ctor) throw new Error("The PDF library (jsPDF) is not loaded; check the internet connection.");
    var pdf = null;
    cvs.forEach(function (cv, i) {
      var sz = svgSize(svgs[i]), pw = sz.w * 0.75, ph = sz.h * 0.75, o = ph > pw ? "p" : "l";
      if (i === 0) pdf = new Ctor({ orientation: o, unit: "pt", format: [pw, ph], compress: true }); else pdf.addPage([pw, ph], o);
      pdf.addImage(cv.toDataURL("image/jpeg", 0.92), "JPEG", 0, 0, pw, ph);
    });
    return pdf;
  }
  function makePdf(cv, s, a4) {
    var Ctor = jsPdfCtor(); if (!Ctor) throw new Error("The PDF library (jsPDF) is not loaded; check the internet connection.");
    if (!a4) {
      var pw = s.w * 0.75, ph = s.h * 0.75;
      var pdf = new Ctor({ orientation: ph > pw ? "p" : "l", unit: "pt", format: [pw, ph], compress: true });
      pdf.addImage(cv.toDataURL("image/jpeg", 0.92), "JPEG", 0, 0, pw, ph);
      return pdf;
    }
    var W = 595.28, H = 841.89, slices = sliceCanvas(cv, W / H);
    var pdf2 = new Ctor({ orientation: "p", unit: "pt", format: [W, H], compress: true });
    slices.forEach(function (t, p) { if (p > 0) pdf2.addPage([W, H], "p"); pdf2.addImage(t.toDataURL("image/jpeg", 0.92), "JPEG", 0, 0, W, H); });
    return pdf2;
  }
  // cut a tall canvas into pages of the given width/height ratio (the last page is padded with the bottom colour)
  function sliceCanvas(cv, ratio) {
    var sliceH = Math.floor(cv.width / ratio), pages = Math.ceil(cv.height / sliceH), out = [];
    var px = cv.getContext("2d").getImageData(0, cv.height - 1, 1, 1).data;
    for (var p = 0; p < pages; p++) {
      var tmp = document.createElement("canvas"); tmp.width = cv.width; tmp.height = sliceH;
      var tctx = tmp.getContext("2d"), hh = Math.min(sliceH, cv.height - p * sliceH);
      tctx.fillStyle = "rgb(" + px[0] + "," + px[1] + "," + px[2] + ")"; tctx.fillRect(0, 0, tmp.width, tmp.height);
      tctx.drawImage(cv, 0, p * sliceH, cv.width, hh, 0, 0, cv.width, hh); out.push(tmp);
    }
    return out;
  }

  // ---------------------------------------------------------------- PPTX
  function pageNotes(svg, k, n) {
    var texts = Array.prototype.map.call(svg.querySelectorAll("text"), function (t) { return (t.textContent || "").trim(); }).filter(Boolean);
    var links = []; Array.prototype.forEach.call(svg.querySelectorAll("a[href]"), function (a) { var h = a.getAttribute("href"); if (h && links.indexOf(h) < 0) links.push(h); });
    return "Slide " + k + " of " + n + " - text on this slide:\n" + texts.join("\n") + (links.length ? "\n\nSource links:\n" + links.join("\n") : "");
  }
  function makePptx(cvs, svgs, title) {
    var P = window.PptxGenJS || window.pptxgen; if (!P) throw new Error("The PowerPoint library (pptxgenjs) is not loaded; check the internet connection.");
    var pptx = new P(), c0 = cvs[0], longest = 13.333, w, h;
    if (c0.width >= c0.height) { w = longest; h = longest * c0.height / c0.width; } else { h = longest; w = longest * c0.width / c0.height; }
    pptx.defineLayout({ name: "IGLAYOUT", width: w, height: h }); pptx.layout = "IGLAYOUT"; pptx.title = title;
    cvs.forEach(function (cv, i) {
      var slide = pptx.addSlide();
      slide.addImage({ data: cv.toDataURL("image/png").replace(/^data:/, ""), x: 0, y: 0, w: w, h: h, altText: title + " - slide " + (i + 1) });
      slide.addNotes(svgs[i] ? pageNotes(svgs[i], i + 1, cvs.length) : title);
    });
    return pptx.write({ outputType: "blob" }).then(function (b) { return b instanceof Blob ? b : new Blob([b], { type: "application/vnd.openxmlformats-officedocument.presentationml.presentation" }); });
  }

  function htmlDoc(svgs, title) {
    var bg = (svgs[0].querySelector("rect") || {}).getAttribute ? svgs[0].querySelector("rect").getAttribute("fill") : "#ffffff";
    var multi = svgs.length > 1, body = svgs.map(function (s) { return svgString(s); }).join("\n");
    var css = multi ? "html,body{margin:0;background:#1f2933}body{padding:24px 12px}svg{display:block;margin:0 auto 28px;max-width:min(100%,1100px);height:auto;box-shadow:0 6px 24px rgba(0,0,0,.45);border-radius:6px}"
                    : "html,body{margin:0;background:" + (bg || "#fff") + "}svg{display:block;margin:0 auto;max-width:100%;height:auto}";
    return "<!doctype html>\n<html lang=\"en\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>" +
      title.replace(/</g, "&lt;") + "</title><style>" + css + "</style></head><body>\n" + body + "\n</body></html>";
  }

  function pad2(i) { return (i < 10 ? "0" : "") + i; }
  function seq(items, fn) {   // run async fn over items one at a time (keeps memory and the UI sane)
    var out = [], p = Promise.resolve();
    items.forEach(function (it, i) { p = p.then(function () { return fn(it, i); }).then(function (r) { out.push(r); }); });
    return p.then(function () { return out; });
  }
  function blobBytes(b) { return b.arrayBuffer().then(function (ab) { return new Uint8Array(ab); }); }

  window.exportInfographic = function (targetId, formatSelectId, defaultName) {
    var sel = document.getElementById(formatSelectId), fmt = sel ? sel.value : "pdf";
    var svgs = findPages(targetId);
    if (!svgs.length) { alert("Nothing to export yet - generate or load an infographic first."); return; }
    var root = document.getElementById(targetId), title = (root && root.getAttribute("data-export-title")) || defaultName || "infographic";
    var base = safeName(title), multi = svgs.length > 1, s0 = svgSize(svgs[0]);
    var ind = indicator("Preparing " + fmt.toUpperCase().replace("_", " ") + " ...");
    function fail(e) { done(ind); console.error("[infographic_export]", e); alert("Export failed: " + (e && e.message ? e.message : e)); }
    try {
      if (fmt === "html") { download(new Blob([htmlDoc(svgs, title)], { type: "text/html;charset=utf-8" }), base + ".html"); done(ind); return; }
      var scale = (fmt === "gif") ? 1 : 2;
      setTimeout(function () {
        seq(svgs, function (svg) { return rasterize(svg, scale); }).then(function (cvs) {
          var cv0 = cvs[0];
          if (fmt === "png" || fmt === "jpeg") {
            var type = fmt === "png" ? "image/png" : "image/jpeg", ext = fmt === "png" ? ".png" : ".jpg", q = fmt === "png" ? undefined : 0.93;
            if (!multi) return toBlob(cv0, type, q).then(function (b) { download(b, base + ext); });
            return seq(cvs, function (cv) { return toBlob(cv, type, q).then(blobBytes); }).then(function (datas) {
              download(makeZip(datas.map(function (d, i) { return { name: base + "_slide_" + pad2(i + 1) + ext, data: d }; })), base + "_slides_" + (fmt === "png" ? "png" : "jpeg") + ".zip");
            });
          }
          if (fmt === "gif") {
            if (!multi) { download(encodeGIF(cv0.width, cv0.height, cv0.getContext("2d").getImageData(0, 0, cv0.width, cv0.height).data), base + ".gif"); return; }
            var frames = cvs.map(function (cv) { return cv.getContext("2d").getImageData(0, 0, cv.width, cv.height).data; });
            download(encodeGIFAnimated(cv0.width, cv0.height, frames, 300), base + ".gif"); return;
          }
          if (fmt === "pdf" || fmt === "pdf_a4") {
            if (multi) { makePdfSlides(cvs, svgs).save(base + ".pdf"); return; }
            makePdf(cv0, s0, fmt === "pdf_a4").save(base + ".pdf"); return;
          }
          if (fmt === "pptx") {
            var slides = cvs, notes = svgs;
            if (!multi) { slides = sliceCanvas(cv0, 595.28 / 841.89); notes = []; }   // a tall poster is cut into A4-shaped slides
            return makePptx(slides, notes, title).then(function (b) { download(b, base + ".pptx"); });
          }
          throw new Error("Unknown format: " + fmt);
        }).then(function () { done(ind); }).catch(fail);
      }, 60);
    } catch (e) { fail(e); }
  };
})();
