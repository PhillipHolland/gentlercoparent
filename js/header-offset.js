/**
 * Fixed header height → --site-header-h on <html>
 * Also re-asserts position:fixed in case cached CSS is stale.
 */
(function () {
  'use strict';

  function pinHeader() {
    var header = document.querySelector('header.site-header, .site-header');
    if (!header) return null;
    header.style.setProperty('position', 'fixed', 'important');
    header.style.setProperty('top', '0', 'important');
    header.style.setProperty('left', '0', 'important');
    header.style.setProperty('right', '0', 'important');
    header.style.setProperty('width', '100%', 'important');
    header.style.setProperty('z-index', '99999', 'important');
    header.style.setProperty('margin', '0', 'important');
    return header;
  }

  function measure() {
    var header = pinHeader();
    if (!header) return;
    var h = Math.ceil(header.getBoundingClientRect().height);
    if (!h || h < 40) h = window.innerWidth <= 800 ? 120 : 88;
    document.documentElement.style.setProperty('--site-header-h', h + 'px');
    document.body.style.setProperty('padding-top', h + 'px', 'important');
  }

  function init() {
    measure();
    window.addEventListener('resize', measure, { passive: true });
    window.addEventListener('orientationchange', function () {
      window.setTimeout(measure, 150);
    }, { passive: true });
    window.addEventListener('load', measure, { passive: true });
    if (typeof ResizeObserver !== 'undefined') {
      var header = document.querySelector('header.site-header, .site-header');
      if (header) new ResizeObserver(measure).observe(header);
    }
    if (document.fonts && document.fonts.ready) {
      document.fonts.ready.then(measure).catch(function () {});
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
