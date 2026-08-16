import Foundation
import Combine

/// The four user-facing toggles, persisted to UserDefaults and mirrored
/// into the WKWebView's JS filter engine via `configJSON`.
final class FilterSettings: ObservableObject {
    @Published var blockReels: Bool {
        didSet { UserDefaults.standard.set(blockReels, forKey: Keys.reels) }
    }
    @Published var blockExplore: Bool {
        didSet { UserDefaults.standard.set(blockExplore, forKey: Keys.explore) }
    }
    @Published var blockSuggested: Bool {
        didSet { UserDefaults.standard.set(blockSuggested, forKey: Keys.suggested) }
    }
    @Published var blockAds: Bool {
        didSet { UserDefaults.standard.set(blockAds, forKey: Keys.ads) }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.onboarded) }
    }

    private enum Keys {
        static let reels = "fckreels.blockReels"
        static let explore = "fckreels.blockExplore"
        static let suggested = "fckreels.blockSuggested"
        static let ads = "fckreels.blockAds"
        static let onboarded = "fckreels.hasCompletedOnboarding"
    }

    init() {
        let d = UserDefaults.standard
        // Default every toggle to "on" (block it) on first launch, matching
        // SocialLite's default posture -- users opt back in per-feature.
        blockReels = d.object(forKey: Keys.reels) as? Bool ?? true
        blockExplore = d.object(forKey: Keys.explore) as? Bool ?? true
        blockSuggested = d.object(forKey: Keys.suggested) as? Bool ?? true
        blockAds = d.object(forKey: Keys.ads) as? Bool ?? true
        hasCompletedOnboarding = d.bool(forKey: Keys.onboarded)
    }

    /// JSON handed to `window.fckreelsUpdateConfig` / seeded as `window.__fckreels`.
    var configJSON: String {
        let dict: [String: Bool] = [
            "blockReels": blockReels,
            "blockExplore": blockExplore,
            "blockSuggested": blockSuggested,
            "blockAds": blockAds,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }
}
