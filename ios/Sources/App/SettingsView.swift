import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: FilterSettings

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Block Reels", isOn: $settings.blockReels)
                    Toggle("Block Explore", isOn: $settings.blockExplore)
                    Toggle("Hide Suggested Posts", isOn: $settings.blockSuggested)
                    Toggle("Hide Ads", isOn: $settings.blockAds)
                } header: {
                    Text("Filters")
                } footer: {
                    Text("Turn any filter off to see that content again. Changes apply immediately, even to a feed that's already open.")
                }

                Section {
                    Button("Turn everything off") {
                        settings.blockReels = false
                        settings.blockExplore = false
                        settings.blockSuggested = false
                        settings.blockAds = false
                    }
                    Button("Turn everything on") {
                        settings.blockReels = true
                        settings.blockExplore = true
                        settings.blockSuggested = true
                        settings.blockAds = true
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
