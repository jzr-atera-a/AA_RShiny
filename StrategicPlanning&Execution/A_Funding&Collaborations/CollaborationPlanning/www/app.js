// Sidebar: tab groups, burger toggle, active marks. Collaboration Planning.
function cpStore(k, v) { try { if (v === undefined) return localStorage.getItem(k); localStorage.setItem(k, v); } catch (e) { return null; } }

// burger: hide or show the whole sidebar (remembered in this browser)
function cpToggleSide() {
  var hidden = document.body.classList.toggle('side-hidden');
  cpStore('cp_side_hidden', hidden ? '1' : '0');
}
function cpRestoreSide() {
  if (cpStore('cp_side_hidden') === '1') document.body.classList.add('side-hidden');
  var closed = (cpStore('cp_closed_groups') || '').split(',');
  document.querySelectorAll('.side-group').forEach(function (g) {
    if (closed.indexOf(g.dataset.group) >= 0) g.classList.add('closed');
  });
}

// open or close one group's list of tabs
function cpToggleGroup(btn) {
  var g = btn.closest('.side-group'); g.classList.toggle('closed');
  var closed = []; document.querySelectorAll('.side-group.closed').forEach(function (x) { closed.push(x.dataset.group); });
  cpStore('cp_closed_groups', closed.join(','));
}

// go to a group and one of its tabs
function cpGo(group, sub) {
  Shiny.setInputValue('nav_to', { group: group, sub: sub, n: Date.now() }, { priority: 'event' });
  if (window.innerWidth < 820) { document.body.classList.add('side-hidden'); }
}

function cpMarkActive(group, sub) {
  document.querySelectorAll('.side-group').forEach(function (g) {
    var on = g.dataset.group === group; g.classList.toggle('active', on);
    if (on) g.classList.remove('closed');
  });
  document.querySelectorAll('.side-sub').forEach(function (a) {
    a.classList.toggle('active', a.closest('.side-group').dataset.group === group && a.dataset.sub === sub);
  });
}

$(document).on('shiny:connected', function () {
  Shiny.addCustomMessageHandler('cp-active', function (m) { cpMarkActive(m.group, m.sub); });
});
// keep the sidebar in step when someone clicks the pills inside a group page
$(document).on('shown.bs.tab', '.tabs-wrap a[data-bs-toggle="tab"], .tabs-wrap a[data-toggle="tab"]', function (e) {
  var nav = $(e.target).closest('ul.nav'); var id = nav.attr('data-tabsetid') ? null : null;
  var group = (nav.closest('.tab-pane[data-value]').attr('data-value')) || null;
  var sub = $(e.target).attr('data-value');
  if (group && sub) cpMarkActive(group, sub);
});
