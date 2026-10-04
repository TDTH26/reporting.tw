// Light/dark switch. Loaded in <head> so a saved choice applies before the page paints.
// No saved choice: follow the device setting (prefers-color-scheme in site.css).
(function () {
  var KEY = 'theme';
  var root = document.documentElement;
  var saved = null;
  try { saved = localStorage.getItem(KEY); } catch (e) {}
  if (saved === 'light' || saved === 'dark') root.setAttribute('data-theme', saved);

  function current() {
    var t = root.getAttribute('data-theme');
    if (t) return t;
    return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }
  function label(btn) {
    var dark = current() === 'dark';
    btn.setAttribute('aria-pressed', dark ? 'true' : 'false');
    btn.title = dark ? 'Switch to light mode' : 'Switch to dark mode';
    btn.setAttribute('aria-label', btn.title);
  }
  document.addEventListener('DOMContentLoaded', function () {
    var btn = document.getElementById('theme');
    if (!btn) return;
    label(btn);
    btn.addEventListener('click', function () {
      var next = current() === 'dark' ? 'light' : 'dark';
      root.setAttribute('data-theme', next);
      try { localStorage.setItem(KEY, next); } catch (e) {}
      label(btn);
    });
    if (window.matchMedia) {
      var mq = window.matchMedia('(prefers-color-scheme: dark)');
      var onChange = function () { label(btn); };
      if (mq.addEventListener) mq.addEventListener('change', onChange); else if (mq.addListener) mq.addListener(onChange);
    }
  });
})();
