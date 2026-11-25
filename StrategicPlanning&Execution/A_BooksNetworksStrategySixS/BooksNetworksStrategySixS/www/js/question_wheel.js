// www/js/question_wheel.js
// Pop-up boxes for the Hard Decision Questions Wheel (R/utils_question_wheel.R).
// Each rendered wheel (.qw-card) carries its pop-up content as JSON in <script class="qw-data">.
// A click (or Enter / Space) on any element with data-qw inside a card opens that entry;
// the pop-up has Previous / Next buttons to walk round the 20 questions and closes on X, Esc or a
// click outside. Delegated listeners, so wheels drawn later by Shiny work without re-binding.
(function () {
  'use strict';
  if (window.__qwBound) return;
  window.__qwBound = true;

  var overlay = null, current = null;

  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }

  function dataFor(card) {
    if (card.__qwData) return card.__qwData;
    var el = card.querySelector('script.qw-data');
    try { card.__qwData = el ? JSON.parse(el.textContent) : {}; } catch (e) { card.__qwData = {}; }
    return card.__qwData;
  }

  function close() {
    if (overlay) { overlay.remove(); overlay = null; }
    if (current && current.opener && current.opener.focus) { try { current.opener.focus(); } catch (e) {} }
    current = null;
  }

  function render(card, key, opener) {
    var all = dataFor(card), d = all[key];
    if (!d) return;
    if (!overlay) {
      overlay = document.createElement('div');
      overlay.className = 'qw-overlay';
      overlay.addEventListener('click', function (ev) {
        if (ev.target === overlay) { close(); return; }
        var b = ev.target.closest('[data-qw-go]');
        if (b) { ev.preventDefault(); render(current.card, b.getAttribute('data-qw-go')); return; }
        if (ev.target.closest('.qw-close')) { ev.preventDefault(); close(); }
      });
      document.body.appendChild(overlay);
    }
    current = { card: card, key: key, opener: opener || (current && current.opener) };
    var h = '<div class="qw-modal" role="dialog" aria-modal="true" aria-label="' + esc(d.title) + '" style="border-top-color:' + esc(d.color) + '">';
    h += '<button type="button" class="qw-close" aria-label="Close">&times;</button>';
    h += '<div class="qw-kicker" style="color:' + esc(d.color) + '">' + esc(d.kicker) + '</div>';
    h += '<h3 class="qw-title">' + esc(d.title) + '</h3>';
    if (d.badge) h += '<span class="qw-badge" style="background:' + esc(d.badge_color) + '">' + esc(d.badge) + '</span>';
    if (d.angle) h += '<p class="qw-angle"><strong>Angle of analysis:</strong> ' + esc(d.angle) + '</p>';
    (d.sections || []).forEach(function (s) {
      h += '<div class="qw-sec' + (s.accent ? ' qw-sec-accent' : '') + '"' + (s.accent ? ' style="border-left-color:' + esc(d.color) + '"' : '') + '>';
      h += '<div class="qw-sec-h">' + esc(s.h) + '</div>';
      if (s.p) h += '<p>' + esc(s.p) + '</p>';
      if (s.li) h += '<ul>' + s.li.map(function (x) { return '<li>' + esc(x) + '</li>'; }).join('') + '</ul>';
      if (s.links) h += '<ul class="qw-links">' + s.links.map(function (x) {
        return '<li><button type="button" class="qw-link" data-qw-go="' + esc(x.key) + '"><span class="qw-dot" style="background:' + esc(x.color) + '"></span>' + esc(x.text) + '</button></li>';
      }).join('') + '</ul>';
      h += '</div>';
    });
    if (d.prev || d.nxt) {
      h += '<div class="qw-nav">';
      h += d.prev ? '<button type="button" class="btn btn-default btn-sm" data-qw-go="' + esc(d.prev) + '">&larr; Previous</button>' : '<span></span>';
      h += d.nxt ? '<button type="button" class="btn btn-primary btn-sm" data-qw-go="' + esc(d.nxt) + '">Next &rarr;</button>' : '<span></span>';
      h += '</div>';
    }
    h += '</div>';
    overlay.innerHTML = h;
    var c = overlay.querySelector('.qw-close');
    if (c) c.focus();
  }

  function open(ev) {
    var t = ev.target.closest ? ev.target.closest('[data-qw]') : null;
    if (!t) return false;
    var card = t.closest('.qw-card');
    if (!card) return false;
    ev.preventDefault();
    render(card, t.getAttribute('data-qw'), t);
    return true;
  }

  document.addEventListener('click', function (ev) { open(ev); });
  document.addEventListener('keydown', function (ev) {
    if (overlay && ev.key === 'Escape') { close(); return; }
    if (overlay && current && (ev.key === 'ArrowRight' || ev.key === 'ArrowLeft')) {
      var d = dataFor(current.card)[current.key];
      var go = ev.key === 'ArrowRight' ? d && d.nxt : d && d.prev;
      if (go) { ev.preventDefault(); render(current.card, go); }
      return;
    }
    if ((ev.key === 'Enter' || ev.key === ' ') && ev.target && ev.target.getAttribute && ev.target.getAttribute('data-qw')) open(ev);
  });
})();
