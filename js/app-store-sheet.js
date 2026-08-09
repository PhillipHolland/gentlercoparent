/**
 * iOS App Store promo bottom sheet
 * - Official App Store destination (apps.apple.com)
 * - Shows once per 7 days (localStorage)
 * - Dismiss via button, overlay, or swipe down only (not every page click)
 */
(function () {
  'use strict';

  var APP_STORE_URL = 'https://apps.apple.com/us/app/gentler-coparent/id6742896499';
  var STORAGE_KEY = 'gcp_app_sheet_dismissed_at';
  var DISMISS_DAYS = 7;
  var SHOW_DELAY_MS = 1200;

  function isIOS() {
    var ua = navigator.userAgent || '';
    var iOS = /iPhone|iPad|iPod/i.test(ua);
    // iPadOS 13+ desktop UA
    var iPadOS = navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1;
    return iOS || iPadOS;
  }

  function wasDismissedRecently() {
    try {
      var raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return false;
      var ts = parseInt(raw, 10);
      if (isNaN(ts)) return false;
      var age = Date.now() - ts;
      return age < DISMISS_DAYS * 24 * 60 * 60 * 1000;
    } catch (e) {
      return false;
    }
  }

  function markDismissed() {
    try {
      localStorage.setItem(STORAGE_KEY, String(Date.now()));
    } catch (e) { /* private mode */ }
  }

  function qs(id) {
    return document.getElementById(id);
  }

  document.addEventListener('DOMContentLoaded', function () {
    var sheet = qs('app-bottom-sheet');
    var overlay = qs('app-bottom-sheet-overlay');
    var dismissBtn = qs('dismiss-bottom-sheet');
    var storeLink = document.querySelector('.app-store-cta');

    if (!sheet || !overlay || !dismissBtn) return;

    // Point all App Store CTAs at the canonical listing
    document.querySelectorAll('[data-app-store-link]').forEach(function (el) {
      el.setAttribute('href', APP_STORE_URL);
      el.setAttribute('rel', 'noopener noreferrer');
      if (!el.getAttribute('target')) el.setAttribute('target', '_blank');
    });

    if (!isIOS() || wasDismissedRecently()) {
      sheet.hidden = true;
      overlay.hidden = true;
      return;
    }

    var open = false;
    var touchStartY = 0;
    var touchCurrentY = 0;
    var dragging = false;

    function lockScroll(lock) {
      document.body.classList.toggle('no-scroll', !!lock);
    }

    function showSheet() {
      if (open) return;
      open = true;
      sheet.hidden = false;
      overlay.hidden = false;
      // force reflow for transition
      void sheet.offsetHeight;
      sheet.classList.remove('slide-down');
      sheet.classList.add('slide-up');
      overlay.classList.add('is-visible');
      lockScroll(true);
      sheet.setAttribute('aria-hidden', 'false');
      dismissBtn.focus({ preventScroll: true });
    }

    function hideSheet() {
      if (!open) return;
      open = false;
      sheet.classList.remove('slide-up');
      sheet.classList.add('slide-down');
      overlay.classList.remove('is-visible');
      sheet.setAttribute('aria-hidden', 'true');
      lockScroll(false);
      markDismissed();

      window.setTimeout(function () {
        if (!open) {
          sheet.hidden = true;
          overlay.hidden = true;
          sheet.style.transform = '';
        }
      }, 450);
    }

    dismissBtn.addEventListener('click', function (e) {
      e.preventDefault();
      hideSheet();
    });

    overlay.addEventListener('click', function () {
      hideSheet();
    });

    if (storeLink) {
      storeLink.addEventListener('click', function () {
        // Keep sheet open until they leave; still remember dismiss so it doesn't re-spam
        markDismissed();
      });
    }

    // Escape key
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && open) hideSheet();
    });

    // Swipe down to dismiss (handle area)
    var handle = sheet.querySelector('.grab-handle');
    var dragTarget = handle || sheet;

    dragTarget.addEventListener('touchstart', function (e) {
      if (!open) return;
      dragging = true;
      touchStartY = e.touches[0].clientY;
      touchCurrentY = touchStartY;
      sheet.setAttribute('data-dragging', 'true');
      sheet.style.transition = 'none';
    }, { passive: true });

    dragTarget.addEventListener('touchmove', function (e) {
      if (!dragging) return;
      touchCurrentY = e.touches[0].clientY;
      var delta = Math.max(0, touchCurrentY - touchStartY);
      sheet.style.transform = 'translateY(' + delta + 'px)';
      overlay.style.opacity = String(Math.max(0, 1 - delta / 280));
    }, { passive: true });

    dragTarget.addEventListener('touchend', function () {
      if (!dragging) return;
      dragging = false;
      sheet.setAttribute('data-dragging', 'false');
      sheet.style.transition = '';
      var delta = touchCurrentY - touchStartY;
      if (delta > 80) {
        hideSheet();
      } else {
        sheet.style.transform = '';
        overlay.style.opacity = '';
      }
    });

    // Delay so first paint / Smart App Banner can settle
    window.setTimeout(showSheet, SHOW_DELAY_MS);
  });
})();
