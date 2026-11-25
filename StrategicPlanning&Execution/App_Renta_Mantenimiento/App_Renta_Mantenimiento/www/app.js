// Enter para entrar
$(document).on('keyup', '#pin', function (e) { if (e.key === 'Enter') $('#btn_dueno').click(); });
$(document).on('keyup', '#email', function (e) { if (e.key === 'Enter') $('#btn_admin').click(); });
// En el teléfono, cerrar el menú lateral al elegir una sección
$(document).on('click', '.sidebar-menu a', function () {
  if (window.innerWidth < 768) $('body').removeClass('sidebar-open');
});
