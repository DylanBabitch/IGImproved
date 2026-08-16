# FCKReels — iOS app

A free, open-source iOS app that loads Instagram in an in-app browser and
filters out Reels, Explore, suggested posts, and ads — each independently
toggleable in Settings. See [`../RESEARCH.md`](../RESEARCH.md) for the
background/approach writeup.

## CI

`.github/workflows/fckreels-ios.yml` (at the repo root) builds this project
on a hosted macOS GitHub Actions runner on every push/PR that touches
`FCKReels/ios/**`, using XcodeGen + an unsigned `xcodebuild build` against
the iOS Simulator destination. This is a compile-check only — no signing,
no TestFlight upload yet. Once there's an Apple Developer account and
distribution certs, this workflow is the place to add `xcodebuild archive`
+ `altool`/App Store Connect API upload steps.

## How it works

- `Sources/WebView/InstagramWebView.swift` loads `https://www.instagram.com`
  in a `WKWebView`.
- `Sources/Resources/filter.js` is injected as a `WKUserScript` at
  document-start. It hides Reels/Explore/Suggested/Ads-related DOM based on
  `aria-label`, link `href`, and visible text (Instagram's CSS class names
  are hashed and rotate, so we deliberately never match on them), and
  re-runs on every DOM mutation via a `MutationObserver` since Instagram is
  a client-routed single-page app.
- `Sources/Settings/FilterSettings.swift` persists the four toggles to
  `UserDefaults` and serializes them to JSON, which gets pushed into the
  page via `window.fckreelsUpdateConfig(...)` whenever a toggle flips.
- The Explore tab is additionally blocked natively, in
  `WKNavigationDelegate.decidePolicyFor`, as a second line of defense
  independent of the JS layer.
- No Instagram credentials, session data, or content ever leave the
  WKWebView / touch app code — login works exactly as it would in Safari.

## Building

This project has no macOS build environment available in this workspace
(it was written on Linux). To build it:

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen) on a Mac:
   `brew install xcodegen`
2. From this `ios/` directory: `xcodegen generate`
3. Open the generated `FCKReels.xcodeproj` in Xcode.
4. Set your own Team under Signing & Capabilities (`PRODUCT_BUNDLE_IDENTIFIER`
   in `project.yml` is a placeholder — change it to something under your own
   developer account).
5. Run on a simulator or your device.

If you'd rather not install XcodeGen, create a new Xcode "App" project
(SwiftUI lifecycle, iOS 16+), then drag the contents of `Sources/` into it,
making sure `filter.js` is added to the target's "Copy Bundle Resources"
build phase.

## App Store review considerations

Apps that are thin wrappers around a website risk rejection under
[Guideline 4.2](https://developer.apple.com/app-store/review/guidelines/#minimum-functionality)
(minimum functionality). This project mitigates that with native chrome
(tab bar, toolbar, Settings, onboarding, About) beyond the browser view
itself, but that's not a guarantee of approval — budget time for review
iteration, and consider sideloading to your own device via a free
developer account first if you just want it for personal use.

## Maintenance

`filter.js`'s selectors will need periodic updates as Instagram changes its
web UI. Treat it like a filter list: when a filter stops working, inspect
the live DOM for the new stable signal (aria-label, href pattern, visible
text) and update the corresponding block in `filter.js` rather than
rewriting the whole engine.
