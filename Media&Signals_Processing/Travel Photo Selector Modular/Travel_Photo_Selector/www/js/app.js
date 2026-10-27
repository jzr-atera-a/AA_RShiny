// Travel Photo Selector - small JS bridge between photo tiles and Shiny
$(document).on('click', '.photo-grid .photo-toggle', function (e) {
  e.preventDefault();
  var tile = $(this).closest('.photo-tile');
  var grid = $(this).closest('.photo-grid');
  Shiny.setInputValue(grid.data('toggle-input'), { id: tile.data('id') }, { priority: 'event' });
});

$(document).on('click', '.photo-grid .photo-zoom', function (e) {
  e.preventDefault();
  var tile = $(this).closest('.photo-tile');
  var grid = $(this).closest('.photo-grid');
  Shiny.setInputValue(grid.data('zoom-input'), { id: tile.data('id') }, { priority: 'event' });
});

// Clicking a row of the "places" table jumps to that place
$(document).on('click', 'tr.goto-row', function () {
  Shiny.setInputValue($(this).closest('table').data('input'), $(this).data('value'), { priority: 'event' });
});

// Server tells us a photo was chosen / un-chosen: update every tile with that id
// Photo size slider (60–100 %) scales every photo frame immediately
function setPhotoScale(v) {
  var x = Math.max(60, Math.min(100, Number(v) || 100)) / 100;
  document.documentElement.style.setProperty('--photo-scale', x);
}
$(document).on('shiny:inputchanged', function (e) {
  if (/photoSize$/.test(e.name)) setPhotoScale(e.value);
});

$(document).on('shiny:connected', function () {
  // tell the server whether the app is shown inside RStudio (its window/viewer)
  var ua = navigator.userAgent || '';
  Shiny.setInputValue('client_is_rstudio', /RStudio/i.test(ua) || !!window.desktopHooks || !!window.rstudio);
  Shiny.addCustomMessageHandler('photo-selected', function (m) {
    $('.photo-tile[data-id="' + m.id + '"]').toggleClass('selected', !!m.selected);
  });
  // hide the sidebar menu (it can be opened again with the ☰ button)
  Shiny.addCustomMessageHandler('collapse-sidebar', function (m) {
    $('body').addClass('sidebar-collapse').removeClass('sidebar-open');
    setTimeout(function () { $(window).trigger('resize'); }, 350);
  });
  Shiny.addCustomMessageHandler('scroll-top', function (m) {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });
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
