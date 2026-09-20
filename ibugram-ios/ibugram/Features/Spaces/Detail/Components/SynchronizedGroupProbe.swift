import SwiftUI

/// Proof that a file added to a brand-new nested folder is compiled without editing
/// `project.pbxproj`. Safe to delete once a feature team populates this directory.
struct SynchronizedGroupProbe: View {
    @Environment(\.theme) private var theme

    var body: some View {
        TagChip(title: "Synchronized build group is live", icon: "checkmark.seal", style: .accent)
            .padding(theme.spacing.md)
    }
}

#Preview("Probe") {
    SynchronizedGroupProbe()
}

#Preview("Probe · dark") {
    SynchronizedGroupProbe()
        .preferredColorScheme(.dark)
}
