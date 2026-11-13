// Start-up and on-demand table checks.
//  * app_boot: sent once, shortly after the page is connected, so the page appears BEFORE the API keys are loaded.
//  * bq_group_click: any click on a sidebar tab group header (the server only builds that group's tabs; tables load when a tab that needs them opens).
//  * bq_go: the server has marked a suite as "checking"; wait for the browser to paint it, then ask the server to do the work.
(function () {
  var registered = false;
  function reg() {
    if (registered || !window.Shiny || !Shiny.addCustomMessageHandler) return;
    registered = true;
    Shiny.addCustomMessageHandler('bq_go', function (m) {
      setTimeout(function () { Shiny.setInputValue('bq_go_run', { groups: m.groups || [], build: m.build || [], n: Math.random() }, { priority: 'event' }); }, 150);
    });
  }
  reg();
  $(document).on('shiny:connected', function () {
    reg();
    setTimeout(function () { Shiny.setInputValue('app_boot', Date.now(), { priority: 'event' }); }, 200);
  });
  $(document).on('click', '.sidebar-menu li.treeview > a', function () {
    var t = $(this).text().trim();
    if (window.Shiny && Shiny.setInputValue) Shiny.setInputValue('bq_group_click', { label: t, n: Math.random() }, { priority: 'event' });
  });
})();
