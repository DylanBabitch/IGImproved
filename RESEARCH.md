# FCKReels — Research Notes (open-source SocialLite clone)

## 1. What SocialLite actually is
SocialLite ("Block Reels & Shorts") is a free iOS/Android app that wraps Instagram
(plus YouTube Shorts and other short-form feeds) and strips out the addictive parts:
Reels, algorithmic/suggested content, Explore, live streams, shopping tabs, and ads —
while keeping DMs, your own following feed, and profiles you deliberately visit. It
exposes granular toggles ("Block Reels", "Hide Ads & Suggested", etc.) and claims no
tracking/data sale.
- [App Store listing](https://apps.apple.com/us/app/sociallite-block-reels-shorts/id6757661674)
- [Google Play listing](https://play.google.com/store/apps/details?id=com.sociallite.android)

Because Apple/Google don't allow apps to hook into *other* apps' binaries, and
SocialLite ships through both app stores, it is almost certainly a **WebView wrapper
around the mobile web version of Instagram** (instagram.com / i.instagram.com),
with injected CSS/JS that hides specific UI regions based on DOM structure. It is not
reverse-engineering Instagram's app or private API — it's closer to a purpose-built
ad-blocker/reader-mode browser scoped to one site.

## 2. Technical approaches (ranked by fit for "free & open source" + cross-platform)

### A. WebView wrapper app injecting CSS/JS (recommended primary approach)
- Native/hybrid shell (Capacitor, or plain WKWebView on iOS + WebView on Android)
  loads `https://www.instagram.com` inside the app.
- On page load **and** on every in-app SPA navigation (Instagram is a client-side
  router — you need a `MutationObserver`/`history.pushState` hook, not just
  `DOMContentLoaded`), inject a stylesheet + JS that hides:
  - Reels tab/icon, Reels entries in home feed, Reels tray in Stories
  - Explore/search-grid page
  - "Suggested for you" / "Suggested Reels" injected posts in the main feed
  - Sponsored/ad posts (`<article>` blocks with "Sponsored" label)
  - Optionally: Shopping tab, Live badges
- Settings toggles in a native settings screen just flip flags that the injected JS
  reads (`window.__fckreels = {reels:false, explore:false, ads:false, suggested:false}`)
  before deciding what to hide — re-run the hide pass on every DOM mutation.
- **Selector strategy is the main engineering risk**: Instagram's CSS class names are
  obfuscated/hashed and rotate often. Robust selectors need to key off stable signals
  instead: `aria-label`, `role`, visible text content, SVG `<title>` values, and
  `href` patterns (e.g. links containing `/reels/`, `/explore/`). This ruleset will
  need ongoing maintenance as Instagram ships web UI changes — treat it like a
  filter-list project (uBlock Origin style), not a one-time build.
- Pros: single JS/CSS codebase covers iOS + Android; no jailbreak/root required; no
  private API keys/credentials; lowest legal exposure (functionally an ad-blocker,
  not an API client or app-binary hook).
- Cons: inherits limitations of Instagram's mobile *web* app (weaker camera/Stories
  creation UX, no push notifications, some features degraded vs. native app). App
  Store review risk under Guideline 4.2 ("minimum functionality" / thin wrappers) —
  mitigate with genuinely native chrome: real settings UI, native tab bar, onboarding,
  possibly a widget — not just a bare browser frame.

### B. Browser extension (content script + CSS injection)
Same DOM-hiding technique as (A), packaged as a WebExtension. Works great on
desktop Chrome/Firefox/Edge and on **Firefox for Android** (which supports
extensions; Chrome/Safari mobile do not). This is exactly what the existing
open-source project **IGPlus** already does:
- [IGPlus source](https://addons.mozilla.org/en-US/firefox/addon/igplus-extension/) —
  open-source Firefox extension, hides Reels/videos/comments/recommendations/trends.

Good complementary artifact (ship a desktop/Firefox-Android extension using the same
filter-list code as the mobile app), but doesn't give you an iOS/Chrome-Android app
by itself.

### C. Android root-level hook (Xposed/LSPosed module)
Hooks directly into the real Instagram native app's Java/Kotlin methods to
suppress reel-rendering, ad-injection, and recommendation calls at the source.
Existing open-source prior art:
- [InstaEclipse](https://github.com/ReSo7200/InstaEclipse) — Ghost Mode,
  Distraction-Free Mode (hides stories/reels/explore), ad-free browsing. Built on
  LSPosed + DexKit.
- IGExperiments — similar, works rootless via LSPatch too.

Pros: works against the *real* native app (full feature parity, push notifications,
native camera/Stories creation), most thorough blocking since it patches
Instagram's own logic rather than fighting the DOM.
Cons: **requires root (or LSPatch repackaging) on Android only** — no iOS
equivalent without a jailbreak, so this can't be your cross-platform story; it does
directly hook Instagram's app internals, which is a clearer ToS violation than (A)/(B)
and requires re-patching whenever Instagram updates its APK (heavier maintenance).
Reasonable as an optional "power user" companion module, not the main deliverable.

### D. Network-level filtering (custom DNS/VPN, blocking specific GraphQL endpoints)
Block specific Instagram API endpoints (e.g. reels-tray, suggested-content queries)
via a local VPN service (like NextDNS or a local mitm proxy). Cross-platform, no
root needed (iOS/Android both allow on-device VPN extensions for this).
Cons: Instagram multiplexes most data over a few generic GraphQL/API endpoints, so
you can't cleanly block "just Reels" without breaking the whole app — poor
granularity, not viable as primary mechanism, but could reinforce ad-domain blocking
(analytics/ad pixels) alongside approach A.

## 3. Legal / ToS considerations
- Instagram's terms explicitly prohibit reverse-engineering their APIs/apps and
  scraping. Approach C (Xposed hooking the real app) sits squarely against that.
- Approach A/B (loading the public instagram.com website in a browser/WebView and
  applying client-side CSS/JS hiding, with no scraping, storage, or automation of
  Instagram data) is functionally the same category as ad-blockers and reader-mode
  extensions — a long-standing, broadly tolerated practice — but note Meta has used
  DMCA takedowns against unofficial API tooling before, and could still target an
  app whose stated purpose is altering Instagram's product experience even without
  touching a private API. There is **no zero-risk option**; A/B is meaningfully lower
  risk than C.
- Practical mitigations: never ask users for their Instagram password/session inside
  your own servers (let the WebView handle login/cookies directly with
  instagram.com, same as a normal browser would — you should never see credentials);
  don't proxy or store any Instagram content/data; be upfront in the README that this
  is a personal-use content filter, not an Instagram product and not affiliated with
  Meta.

## 3.5 Decision: iOS-only, WebView app, aiming for App Store/TestFlight
Confirmed direction: this project targets **iOS only**. That actually
simplifies the decision above — there's no jailbreak-free equivalent of
Xposed on iOS, so approach A (WKWebView + injected CSS/JS filter) is the
only viable path, not just the recommended one. Aiming for TestFlight/App
Store distribution (rather than personal sideload) means Guideline 4.2
("minimum functionality" / thin wrapper rejection risk) needs real
mitigation: native tab bar, a real Settings screen, onboarding, and an
About screen with a clear non-affiliation disclaimer, all beyond the bare
browser view. The initial implementation (`ios/`) does this. See
[`ios/README.md`](ios/README.md) for the concrete architecture and build
steps.

## 4. Recommended plan for FCKReels
1. **Primary deliverable**: cross-platform WebView app (Capacitor or React Native
   WebView) around instagram.com, with a native settings screen exposing toggles for
   Reels / Explore / Suggested / Ads, backed by a maintainable, selector-based
   filter-rule module (JS+CSS, versioned like a filter list, easy to hot-patch when
   Instagram's DOM shifts).
2. **Secondary/companion**: package the same filter-rule module as a WebExtension
   for desktop Chrome/Firefox + Firefox for Android, reusing ~90% of the code.
3. **Optional stretch**: an LSPosed module for Android power users who want the
   toggles applied to the real native Instagram app instead of the web version —
   separate codebase, higher maintenance, ship later if there's demand.
4. Study InstaEclipse and IGPlus's actual selector/hiding code as reference
   implementations before writing your own ruleset.
5. Plan for ongoing maintenance: Instagram's web DOM and obfuscated class names
   change periodically; budget for a lightweight CI/monitoring check (e.g. a
   scheduled headless-browser smoke test) that flags when a selector stops matching.

## Sources
- https://apps.apple.com/us/app/sociallite-block-reels-shorts/id6757661674
- https://play.google.com/store/apps/details?id=com.sociallite.android
- https://mwm.ai/apps/socialliteapp/6757661674
- https://addons.mozilla.org/en-US/firefox/addon/igplus-extension/
- https://github.com/ReSo7200/InstaEclipse
- https://modules.lsposed.org/module/ps.reso.instaeclipse/
- https://magiskroot.net/igexperiments/
- https://www.criticalhit.net/technology/instagram-private-api-risks-capabilities-and-developer-considerations/
