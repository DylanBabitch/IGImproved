// FCKReels content filter
//
// Injected into instagram.com by InstagramWebView as a WKUserScript at
// document-start (so `window.__fckreels` and this file's declarations exist
// before Instagram's own JS runs), and re-run continuously via a
// MutationObserver because Instagram is a client-side-routed SPA that never
// stops mutating the DOM.
//
// SELECTOR STRATEGY: Instagram's CSS class names are hashed/obfuscated and
// rotate on nearly every deploy, so we deliberately never match on class
// names. Instead we match on things that stay stable because they carry
// meaning to real users/screen readers: aria-label text, SVG <title> text,
// href patterns, and visible text content. This still needs periodic
// tuning as Instagram's markup evolves -- treat this file like a filter
// list, not a "finished" artifact.
(function () {
  "use strict";

  if (window.__fckreelsInstalled) return;
  window.__fckreelsInstalled = true;

  // Config is set by native Swift before this script's IIFE runs (for the
  // very first load) and updated later via window.fckreelsUpdateConfig().
  window.__fckreels = window.__fckreels || {
    blockReels: true,
    blockExplore: true,
    blockSuggested: true,
    blockAds: true,
  };

  var HIDE_ATTR = "data-fckreels-hidden";
  var SCAN_ATTR = "data-fckreels-scanned";

  function cfg() {
    return window.__fckreels;
  }

  function hide(el) {
    if (!el || el.nodeType !== 1) return;
    el.setAttribute(HIDE_ATTR, "1");
    el.style.setProperty("display", "none", "important");
  }

  function unhideAll() {
    document.querySelectorAll("[" + HIDE_ATTR + "]").forEach(function (el) {
      el.removeAttribute(HIDE_ATTR);
      el.style.removeProperty("display");
    });
  }

  // Walk up from `el` looking for the element that represents "one feed
  // unit" (a post, a reel tray, a suggested-content module) so we hide the
  // whole card instead of just the link/label we matched on. Instagram
  // wraps most feed units in <article>; fall back to a bounded walk.
  function hideFeedUnit(el, maxLevels) {
    if (!el) return;
    var node = el;
    for (var i = 0; i < (maxLevels || 8); i++) {
      if (!node || node === document.body) return;
      if (node.tagName === "ARTICLE") {
        hide(node);
        return;
      }
      node = node.parentElement;
    }
    // No <article> found within range -- hide the closest reasonably-sized
    // block ancestor instead of the raw link (avoids leaving a headline
    // like "Suggested for you" floating with no content beneath it).
    hide(el.closest("section, li, div") || el);
  }

  function matchesText(el, phrases) {
    var text = (el.textContent || "").trim();
    if (!text) return false;
    return phrases.some(function (p) {
      return text.toLowerCase() === p.toLowerCase();
    });
  }

  function labelMatches(el, words) {
    var label = (
      el.getAttribute("aria-label") ||
      (el.querySelector && el.querySelector("title")
        ? el.querySelector("title").textContent
        : "") ||
      ""
    ).toLowerCase();
    return words.some(function (w) { return label.indexOf(w) !== -1; });
  }

  function run() {
    var c = cfg();

    // --- Nav entry points (tab bar / top nav / side rail) ---------------
    document
      .querySelectorAll('a[href], [role="link"], [role="button"]')
      .forEach(function (el) {
        var href = el.getAttribute("href") || "";
        if (c.blockReels && /^\/reels?(\/|$)/.test(href)) hide(el);
        if (c.blockExplore && /^\/explore(\/|$)/.test(href)) hide(el);
        if ((c.blockReels || c.blockExplore) && labelMatches(el, ["reel", "explore"])) {
          if (c.blockReels && labelMatches(el, ["reel"])) hide(el);
          if (c.blockExplore && labelMatches(el, ["explore"])) hide(el);
        }
      });

    // --- Reels embedded in the home feed / stories tray ------------------
    if (c.blockReels) {
      document.querySelectorAll('a[href*="/reel/"], a[href^="/reels/"]').forEach(
        function (a) {
          if (a.getAttribute(SCAN_ATTR)) return;
          a.setAttribute(SCAN_ATTR, "1");
          hideFeedUnit(a);
        }
      );
    }

    // --- "Sponsored" posts (ads) -----------------------------------------
    if (c.blockAds) {
      document.querySelectorAll("span, a").forEach(function (el) {
        if (el.getAttribute(SCAN_ATTR)) return;
        if (matchesText(el, ["sponsored"])) {
          el.setAttribute(SCAN_ATTR, "1");
          hideFeedUnit(el);
        }
      });
    }

    // --- "Suggested for you" / "Suggested Reels" modules ------------------
    if (c.blockSuggested) {
      document
        .querySelectorAll('span, h2, div[role="heading"]')
        .forEach(function (el) {
          if (el.getAttribute(SCAN_ATTR)) return;
          if (
            matchesText(el, [
              "suggested for you",
              "suggested posts",
              "suggested reels",
            ])
          ) {
            el.setAttribute(SCAN_ATTR, "1");
            hideFeedUnit(el, 12);
          }
        });
    }
  }

  var pending = false;
  function schedule() {
    if (pending) return;
    pending = true;
    requestAnimationFrame(function () {
      pending = false;
      run();
    });
  }

  // Re-apply on every DOM mutation (infinite scroll, SPA route swaps).
  var observer = new MutationObserver(schedule);

  function startObserving() {
    if (!document.body) {
      document.addEventListener("DOMContentLoaded", startObserving, { once: true });
      return;
    }
    observer.observe(document.body, { childList: true, subtree: true });
    schedule();
  }
  startObserving();

  // Explore is a full page, not a feed unit -- bounce the SPA router back
  // home instead of trying to hide a grid one tile at a time. Native Swift
  // also intercepts this at the WKNavigationDelegate level as the primary
  // guard; this covers client-side (pushState) navigation the delegate
  // never sees.
  function guardExploreRoute() {
    if (cfg().blockExplore && /^\/explore(\/|$)/.test(location.pathname)) {
      history.replaceState(null, "", "/");
    }
  }
  ["pushState", "replaceState"].forEach(function (method) {
    var orig = history[method];
    history[method] = function () {
      var ret = orig.apply(this, arguments);
      guardExploreRoute();
      schedule();
      return ret;
    };
  });
  window.addEventListener("popstate", function () {
    guardExploreRoute();
    schedule();
  });
  guardExploreRoute();

  // Called from Swift whenever the user flips a toggle in Settings.
  window.fckreelsUpdateConfig = function (json) {
    try {
      window.__fckreels = JSON.parse(json);
    } catch (e) {
      return;
    }
    unhideAll();
    guardExploreRoute();
    schedule();
  };
})();
