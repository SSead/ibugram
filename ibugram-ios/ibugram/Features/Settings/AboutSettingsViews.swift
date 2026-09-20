import SwiftUI

struct OnDevicePrivacyView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Text("On-device processing")
                    .font(theme.typography.titleSmall)
                    .foregroundStyle(theme.colors.textPrimary)
                Text(copy)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(theme.spacing.screenMargin)
        }
        .background(theme.colors.background)
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var copy: String {
        """
        IBUgram generates alt text, hashtag suggestions and other image understanding on your iPhone. Photos are not uploaded to a cloud vision service for analysis.

        When you share a post, only the photo you chose and the caption you wrote leave the device. Face clustering, scene labels and language hints stay here.
        """
    }
}

struct LicencesView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        List {
            Section("IBUgram") {
                Text("IBUgram is a campus project of International Burch University. The client, server and shared contract are original work for the Senior Design Project.")
                    .font(theme.typography.footnote)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            Section("System frameworks") {
                LabeledContent("SwiftUI", value: "Apple")
                LabeledContent("Vision", value: "Apple")
                LabeledContent("NaturalLanguage", value: "Apple")
                LabeledContent("LocalAuthentication", value: "Apple")
            }
            Section("Packages") {
                LabeledContent("IBUgramKit", value: "Local package")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Licences")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Privacy") {
    NavigationStack { OnDevicePrivacyView() }
}

#Preview("Licences") {
    NavigationStack { LicencesView() }
}
