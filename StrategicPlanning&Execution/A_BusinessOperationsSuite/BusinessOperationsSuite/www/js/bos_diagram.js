// www/js/bos_diagram.js - takes a PNG of a diagram in the browser for R/utils_diagram_export.R.
//   plotly : Plotly.toImage on the chart (exact, at 2x)
//   html   : an <svg> on its own is rasterised directly; anything else (canvases, Mermaid, HTML in an iframe)
//            is drawn with html2canvas (loaded from the CDN the first time it is needed)
// The server sends {target, kind, input, nonce, bg, width, height}; the answer goes back as input value
// {nonce, png: "data:image/png;base64,..."} or {nonce, error: "..."}.
(function () {
  var H2C = 'https://cdn.jsdelivr.net/npm/html2canvas@1.4.1/dist/html2canvas.min.js';
  var loading = {};

  function loadScript(src) {
    if (loading[src]) return loading[src];
    loading[src] = new Promise(function (resolve, reject) {
      var s = document.createElement('script');
      s.src = src;
      s.onload = resolve;
      s.onerror = function () { delete loading[src]; reject(new Error('could not load ' + src + ' (no internet?)')); };
      document.head.appendChild(s);
    });
    return loading[src];
  }

  function plotlyPng(el, m) {
    var gd = el.classList.contains('js-plotly-plot') ? el : el.querySelector('.js-plotly-plot');
    if (!gd || !window.Plotly || !gd.data) return Promise.reject(new Error('the chart is not drawn yet'));
    var w = m.width || Math.max(gd.clientWidth, 900), h = m.height || Math.max(gd.clientHeight, 500);
    return Plotly.toImage(gd, { format: 'png', width: w, height: h, scale: 2 });
  }

  function svgPng(svg, bg) {
    return new Promise(function (resolve, reject) {
      var box = svg.getBoundingClientRect();
      var vb = svg.viewBox && svg.viewBox.baseVal;
      var w = Math.ceil(box.width || (vb && vb.width) || 800), h = Math.ceil(box.height || (vb && vb.height) || 600);
      var clone = svg.cloneNode(true);
      clone.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
      clone.setAttribute('width', w);
      clone.setAttribute('height', h);
      var blob = new Blob([new XMLSerializer().serializeToString(clone)], { type: 'image/svg+xml;charset=utf-8' });
      var url = URL.createObjectURL(blob), img = new Image();
      img.onload = function () {
        var c = document.createElement('canvas');
        c.width = w * 2; c.height = h * 2;
        var g = c.getContext('2d');
        g.fillStyle = bg || '#ffffff'; g.fillRect(0, 0, c.width, c.height);
        g.scale(2, 2); g.drawImage(img, 0, 0, w, h);
        URL.revokeObjectURL(url);
        try { resolve(c.toDataURL('image/png')); } catch (e) { reject(e); }
      };
      img.onerror = function () { URL.revokeObjectURL(url); reject(new Error('the SVG could not be drawn')); };
      img.src = url;
    });
  }

  function htmlPng(el, m) {
    var bg = m.bg || '#ffffff';
    var frame = el.querySelector('iframe');
    var svgs = el.querySelectorAll('svg');
    if (!frame && svgs.length === 1 && !svgs[0].querySelector('foreignObject')) return svgPng(svgs[0], bg);
    return loadScript(H2C).then(function () {
      if (frame) {
        var doc = frame.contentDocument;
        if (!doc || !doc.documentElement) throw new Error('the diagram frame cannot be read');
        var root = doc.documentElement;
        return html2canvas(root, { backgroundColor: bg, scale: 2, useCORS: true, logging: false, window: frame.contentWindow,
                                   width: root.scrollWidth, height: root.scrollHeight, windowWidth: root.scrollWidth, windowHeight: root.scrollHeight });
      }
      return html2canvas(el, { backgroundColor: bg, scale: 2, useCORS: true, logging: false });
    }).then(function (canvas) { return canvas.toDataURL('image/png'); });
  }

  function register() {
    Shiny.addCustomMessageHandler('bos-capture', function (m) {
      var el = document.getElementById(m.target);
      var job = !el ? Promise.reject(new Error('the diagram is not on the page - open its tab first'))
                    : (m.kind === 'plotly' ? plotlyPng(el, m) : htmlPng(el, m));
      job.then(function (png) {
        Shiny.setInputValue(m.input, { nonce: m.nonce, png: png }, { priority: 'event' });
      }).catch(function (e) {
        Shiny.setInputValue(m.input, { nonce: m.nonce, error: String((e && e.message) || e) }, { priority: 'event' });
      });
    });
    // the hidden download button of a save bar is clicked once the files are ready
    Shiny.addCustomMessageHandler('bos-download', function (m) {
      var a = document.getElementById(m.id);
      if (a) a.click();
    });
  }

  // shiny:connected is a jQuery event, so listen with jQuery
  if (window.Shiny && Shiny.addCustomMessageHandler) register();
  else window.jQuery(document).one('shiny:connected', register);
})();
