import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("FCKReels loads instagram.com in a private, sandboxed browser view inside the app and filters what renders on the page -- Reels, Explore, suggested posts, and ads -- using on-device rules. It does not use Instagram's private API, does not read or store your Instagram data anywhere outside the browser view, and does not see your password (Instagram's own login page handles that, exactly as it would in Safari).")
                }

                Section("Open Source") {
                    Text("FCKReels is free and open source. Contributions and filter-rule fixes are welcome.")
                }

                Section {
                    Text("Not affiliated with, endorsed by, or sponsored by Instagram or Meta Platforms, Inc.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("About")
        }
    }
}
