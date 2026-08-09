/**
 * Keep --site-header-h in sync with the fixed header's real height
 * so body padding always clears the bar (desktop + mobile stack).
 */
(function () {
  'use strict';

  function measure() {
    var header = document.querySelector('.site-header, header.site-header');
    if (!header) return;
    var h = Math.ceil(header.getBoundingClientRect().height);
    if (!h || h < 40) return;
    document.documentElement.style.setProperty('--site-header-h', h + 'px');
  }

  function init() {
    measure();
    window.addEventListener('resize', measure, { passive: true });
    window.addEventListener('orientationchange', function () {
      window.setTimeout(measure, 120);
    }, { passive: true });

    if (typeof ResizeObserver !== 'undefined') {
      var header = document.querySelector('.site-header, header.site-header');
      if (header) {
        var ro = new ResizeObserver(function () { measure(); });
        ro.observe(header);
      }
    }

    // Fonts/logo can change height after first paint
    if (document.fonts && document.fonts.ready) {
      document.fonts.ready.then(measure).catch(function () {});
    }
    window.addEventListener('load', measure, { passive: true });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
