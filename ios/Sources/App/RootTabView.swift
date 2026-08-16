import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            BrowserView()
                .tabItem { Label("Instagram", systemImage: "house.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }

            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
    }
}
