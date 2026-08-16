import SwiftUI
@preconcurrency import WebKit

/// Wraps a WKWebView pointed at instagram.com, seeding it with the
/// filter.js content-filtering engine and re-pushing the config whenever
/// settings change. Also acts as a second, native line of defense against
/// the Explore tab by intercepting navigation before it ever loads.
struct InstagramWebView: UIViewRepresentable {
    @ObservedObject var settings: FilterSettings
    let controller: WebViewController

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()

        if let scriptURL = Bundle.main.url(forResource: "filter", withExtension: "js"),
           let scriptSource = try? String(contentsOf: scriptURL, encoding: .utf8) {
            // Seed config *before* filter.js runs, and *before* Instagram's
            // own bundle runs, so nothing renders unfiltered even for a
            // frame.
            let seed = WKUserScript(
                source: "window.__fckreels = \(settings.configJSON);",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
            let filter = WKUserScript(
                source: scriptSource,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
            contentController.addUserScript(seed)
            contentController.addUserScript(filter)
        } else {
            assertionFailure("filter.js resource missing from bundle")
        }

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.websiteDataStore = .default() // persist login/session like a normal browser

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent =
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 " +
            "(KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

        controller.attach(webView)
        webView.load(URLRequest(url: URL(string: "https://www.instagram.com/")!))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Push the latest toggle state into the page whenever SwiftUI state
        // changes (e.g. the user flips a switch in Settings while the web
        // view is still alive in the background tab).
        webView.evaluateJavaScript(
            "window.fckreelsUpdateConfig && window.fckreelsUpdateConfig('\(settings.configJSON)');"
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(settings: settings)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let settings: FilterSettings
        init(settings: FilterSettings) { self.settings = settings }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if settings.blockExplore,
               let path = navigationAction.request.url?.path,
               path.hasPrefix("/explore") {
                decisionHandler(.cancel)
                if webView.url?.path.hasPrefix("/explore") != false {
                    webView.load(URLRequest(url: URL(string: "https://www.instagram.com/")!))
                }
                return
            }
            decisionHandler(.allow)
        }
    }
}

/// Thin owner of the live WKWebView instance so native chrome (back/forward/
/// reload buttons, pull-to-refresh) can drive it without SwiftUI needing to
/// hold a WKWebView reference directly.
final class WebViewController: ObservableObject {
    private(set) weak var webView: WKWebView?

    func attach(_ webView: WKWebView) {
        self.webView = webView
    }

    func goBack() { webView?.goBack() }
    func goForward() { webView?.goForward() }
    func reload() { webView?.reload() }
    func goHome() {
        webView?.load(URLRequest(url: URL(string: "https://www.instagram.com/")!))
    }
}
