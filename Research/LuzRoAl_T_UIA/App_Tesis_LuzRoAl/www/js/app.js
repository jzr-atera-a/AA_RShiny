// Mi Tesis - small JS bridge between buttons rendered by the server and Shiny

// Any button with class js-evt sends {id, action} to the input named in data-input
$(document).on('click', '.js-evt', function (e) {
  e.preventDefault();
  var b = $(this);
  Shiny.setInputValue(b.data('input'), { id: String(b.data('id')), action: b.data('action'), n: Date.now() }, { priority: 'event' });
});

$(document).on('shiny:connected', function () {
  // Administrador → "Tamaño de toda la pantalla"
  Shiny.addCustomMessageHandler('set-zoom', function (m) {
    document.documentElement.style.setProperty('--app-zoom', m.zoom);
  });
  Shiny.addCustomMessageHandler('scroll-top', function (m) {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });
});

// Warn before closing the window while a text is still being typed (autosave runs ~2 s after typing stops)
var lastKey = 0;
$(document).on('input', 'textarea, input[type=text]', function () { lastKey = Date.now(); });
window.addEventListener('beforeunload', function (e) {
  if (Date.now() - lastKey < 2500) { e.preventDefault(); e.returnValue = ''; }
});

// Translate the shinyFiles folder dialog (it ships with English labels) to Spanish
(function () {
  var es = {
    'Create new folder': 'Crear carpeta nueva', 'Create': 'Crear', 'Sort content': 'Ordenar',
    'Directories': 'Carpetas', 'Content': 'Contenido', 'No folder selected': 'Ninguna carpeta seleccionada',
    'Cancel': 'Cancelar', 'Select': 'Seleccionar', 'Name': 'Nombre', 'Type': 'Tipo', 'Size': 'Tamaño',
    'Created': 'Creado', 'Modified': 'Modificado', 'Ascending': 'Ascendente', 'Descending': 'Descendente',
    'Go back': 'Atrás', 'Go forward': 'Adelante', 'Go up a level': 'Subir un nivel', 'Show hidden files': 'Mostrar archivos ocultos',
    'Show details': 'Ver detalles', 'Show icons': 'Ver íconos', 'Change directory': 'Cambiar carpeta',
    'Volume': 'Unidad', 'Selected folder:': 'Carpeta elegida:', 'Folder name': 'Nombre de la carpeta'
  };
  function tr(root) {
    var w = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, null);
    var n;
    while ((n = w.nextNode())) {
      var t = n.nodeValue.trim();
      if (es[t]) n.nodeValue = n.nodeValue.replace(t, es[t]);
    }
    $(root).find('[title], [placeholder]').each(function () {
      if (es[this.title]) this.title = es[this.title];
      if (es[this.placeholder]) this.placeholder = es[this.placeholder];
    });
  }
  var busy = false;
  new MutationObserver(function () {
    if (busy) return;
    busy = true;
    $('.modal').filter(function () { return $(this).find('[class*="sF-"]').length > 0; }).each(function () { tr(this); });
    busy = false;
  }).observe(document.documentElement, { childList: true, subtree: true });
})();
