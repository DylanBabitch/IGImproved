import SwiftUI

/// Native chrome around the WKWebView -- a real toolbar with back/forward/
/// reload/home, not a bare browser frame. Besides being more usable, this
/// gives the app genuine native functionality beyond "load a website",
/// which matters for App Store review (Guideline 4.2, minimum functionality).
struct BrowserView: View {
    @EnvironmentObject private var settings: FilterSettings
    @StateObject private var controller = WebViewController()

    var body: some View {
        NavigationStack {
            InstagramWebView(settings: settings, controller: controller)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button { controller.goBack() } label: {
                            Image(systemName: "chevron.left")
                        }
                        Spacer()
                        Button { controller.goHome() } label: {
                            Image(systemName: "house")
                        }
                        Spacer()
                        Button { controller.reload() } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        Spacer()
                        Button { controller.goForward() } label: {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
        }
    }
}
