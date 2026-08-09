/**
 * App Store promos
 * - iOS / iPadOS: bottom sheet (swipe-down to dismiss, native feel)
 * - Desktop: corner card (not a mobile sheet)
 * - Shared: App Store URL, 7-day dismiss memory
 */
(function () {
  'use strict';

  var APP_STORE_URL = 'https://apps.apple.com/us/app/gentler-coparent/id6742896499';
  var STORAGE_KEY = 'gcp_app_promo_dismissed_at';
  var DISMISS_DAYS = 7;
  var SHOW_DELAY_MS = 900;
  var DISMISS_DISTANCE = 100;
  var DISMISS_VELOCITY = 0.45; // px/ms

  function isIOSFamily() {
    var ua = navigator.userAgent || '';
    if (/iPhone|iPad|iPod/i.test(ua)) return true;
    return navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1;
  }

  function isTouchPrimary() {
    return window.matchMedia('(hover: none) and (pointer: coarse)').matches
      || ('ontouchstart' in window && navigator.maxTouchPoints > 0);
  }

  function wasDismissedRecently() {
    try {
      var raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return false;
      var ts = parseInt(raw, 10);
      if (isNaN(ts)) return false;
      return Date.now() - ts < DISMISS_DAYS * 24 * 60 * 60 * 1000;
    } catch (e) {
      return false;
    }
  }

  function markDismissed() {
    try {
      localStorage.setItem(STORAGE_KEY, String(Date.now()));
    } catch (e) { /* private mode */ }
  }

  function trackAppStoreClick(el) {
    try {
      var label = (el.getAttribute('data-store-location')
        || el.className
        || 'app_store_link').toString().slice(0, 80);
      if (typeof window.gtag === 'function') {
        window.gtag('event', 'app_store_click', {
          event_category: 'conversion',
          event_label: label,
          transport_type: 'beacon'
        });
      }
      if (typeof window.va === 'function') {
        window.va('event', { name: 'app_store_click', data: { location: label } });
      }
    } catch (e) { /* ignore */ }
  }

  function wireStoreLinks() {
    document.querySelectorAll('[data-app-store-link]').forEach(function (el) {
      el.setAttribute('href', APP_STORE_URL);
      el.setAttribute('rel', 'noopener noreferrer');
      if (!el.getAttribute('target')) el.setAttribute('target', '_blank');
      if (el.dataset.storeTracked === '1') return;
      el.dataset.storeTracked = '1';
      el.addEventListener('click', function () {
        trackAppStoreClick(el);
      });
    });
  }

  // —— Mobile bottom sheet ——
  function initMobileSheet() {
    var sheet = document.getElementById('app-bottom-sheet');
    var overlay = document.getElementById('app-bottom-sheet-overlay');
    var dismissBtn = document.getElementById('dismiss-bottom-sheet');
    if (!sheet || !overlay || !dismissBtn) return;

    var open = false;
    var drag = null; // { startY, lastY, lastT, delta }

    function lockScroll(lock) {
      document.body.classList.toggle('no-scroll', !!lock);
    }

    function show() {
      if (open || wasDismissedRecently()) return;
      open = true;
      sheet.hidden = false;
      overlay.hidden = false;
      void sheet.offsetHeight;
      sheet.classList.remove('slide-down', 'is-dragging');
      sheet.classList.add('slide-up');
      sheet.style.transform = '';
      overlay.classList.add('is-visible');
      overlay.style.opacity = '';
      lockScroll(true);
      sheet.setAttribute('aria-hidden', 'false');
    }

    function hide() {
      if (!open) return;
      open = false;
      drag = null;
      sheet.classList.remove('slide-up', 'is-dragging');
      sheet.classList.add('slide-down');
      sheet.style.transform = '';
      overlay.classList.remove('is-visible');
      overlay.style.opacity = '';
      sheet.setAttribute('aria-hidden', 'true');
      lockScroll(false);
      markDismissed();
      window.setTimeout(function () {
        if (!open) {
          sheet.hidden = true;
          overlay.hidden = true;
        }
      }, 420);
    }

    dismissBtn.addEventListener('click', function (e) {
      e.preventDefault();
      hide();
    });
    overlay.addEventListener('click', hide);
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && open) hide();
    });
    sheet.querySelectorAll('[data-app-store-link]').forEach(function (el) {
      el.addEventListener('click', markDismissed);
    });

    function onPointerDown(clientY, id, target) {
      if (!open) return;
      // Allow button/link taps without starting a drag
      if (target.closest('a, button, input, textarea, select')) return;
      drag = {
        id: id,
        startY: clientY,
        lastY: clientY,
        lastT: performance.now(),
        delta: 0,
        velocity: 0
      };
      sheet.classList.add('is-dragging');
      sheet.setAttribute('data-dragging', 'true');
    }

    function onPointerMove(clientY) {
      if (!drag) return;
      var now = performance.now();
      var delta = Math.max(0, clientY - drag.startY);
      var dt = Math.max(1, now - drag.lastT);
      drag.velocity = (clientY - drag.lastY) / dt;
      drag.lastY = clientY;
      drag.lastT = now;
      drag.delta = delta;
      sheet.style.transform = 'translate3d(0,' + delta + 'px,0)';
      overlay.style.opacity = String(Math.max(0.08, 1 - delta / 320));
    }

    function onPointerUp() {
      if (!drag) return;
      var delta = drag.delta;
      var velocity = drag.velocity;
      sheet.classList.remove('is-dragging');
      sheet.setAttribute('data-dragging', 'false');
      sheet.style.transition = '';
      drag = null;

      var shouldDismiss = delta > DISMISS_DISTANCE || (delta > 40 && velocity > DISMISS_VELOCITY);
      if (shouldDismiss) {
        hide();
      } else {
        sheet.style.transform = '';
        overlay.style.opacity = '';
        // snap back
        sheet.classList.add('slide-up');
      }
    }

    // Touch (entire sheet — native swipe)
    sheet.addEventListener('touchstart', function (e) {
      if (e.touches.length !== 1) return;
      onPointerDown(e.touches[0].clientY, 'touch', e.target);
    }, { passive: true });

    sheet.addEventListener('touchmove', function (e) {
      if (!drag) return;
      onPointerMove(e.touches[0].clientY);
      // Only prevent scroll when actually dragging down
      if (drag && drag.delta > 4) {
        e.preventDefault();
      }
    }, { passive: false });

    sheet.addEventListener('touchend', onPointerUp, { passive: true });
    sheet.addEventListener('touchcancel', onPointerUp, { passive: true });

    // Pointer events (better for modern Safari)
    if (window.PointerEvent) {
      sheet.addEventListener('pointerdown', function (e) {
        if (e.pointerType === 'mouse' && e.button !== 0) return;
        if (e.pointerType === 'mouse' && !isTouchPrimary()) return; // desktop uses card
        onPointerDown(e.clientY, e.pointerId, e.target);
        try { sheet.setPointerCapture(e.pointerId); } catch (err) { /* ignore */ }
      });
      sheet.addEventListener('pointermove', function (e) {
        if (!drag) return;
        onPointerMove(e.clientY);
      });
      sheet.addEventListener('pointerup', onPointerUp);
      sheet.addEventListener('pointercancel', onPointerUp);
    }

    window.setTimeout(show, SHOW_DELAY_MS);
  }

  // —— Desktop corner card ——
  function initDesktopCard() {
    var card = document.getElementById('app-desktop-promo');
    var dismissBtn = document.getElementById('dismiss-desktop-promo');
    if (!card || !dismissBtn) return;

    if (wasDismissedRecently()) {
      card.hidden = true;
      return;
    }

    function show() {
      card.hidden = false;
      void card.offsetHeight;
      card.classList.add('is-visible');
      card.setAttribute('aria-hidden', 'false');
    }

    function hide() {
      card.classList.remove('is-visible');
      card.setAttribute('aria-hidden', 'true');
      markDismissed();
      window.setTimeout(function () {
        card.hidden = true;
      }, 320);
    }

    dismissBtn.addEventListener('click', function (e) {
      e.preventDefault();
      hide();
    });
    card.querySelectorAll('[data-app-store-link]').forEach(function (el) {
      el.addEventListener('click', markDismissed);
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && card.classList.contains('is-visible')) hide();
    });

    window.setTimeout(show, SHOW_DELAY_MS + 400);
  }

  document.addEventListener('DOMContentLoaded', function () {
    wireStoreLinks();
    if (wasDismissedRecently()) return;

    // Mobile / tablet touch → bottom sheet
    // Desktop with fine pointer → corner card
    if (isIOSFamily() || (isTouchPrimary() && window.innerWidth < 900)) {
      initMobileSheet();
    } else {
      initDesktopCard();
    }
  });
})();
