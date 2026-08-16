import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var settings: FilterSettings

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "eye.slash.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text("FCKReels")
                .font(.largeTitle.bold())

            Text("Browse Instagram without Reels, Explore, suggested posts, or ads. Turn any of them back on any time in Settings.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Text("FCKReels is an independent, open-source project and is not affiliated with, endorsed by, or sponsored by Instagram or Meta.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                settings.hasCompletedOnboarding = true
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
    }
}
