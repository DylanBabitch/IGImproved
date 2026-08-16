import SwiftUI

@main
struct FCKReelsApp: App {
    @StateObject private var settings = FilterSettings()

    var body: some Scene {
        WindowGroup {
            if settings.hasCompletedOnboarding {
                RootTabView()
                    .environmentObject(settings)
            } else {
                OnboardingView()
                    .environmentObject(settings)
            }
        }
    }
}
