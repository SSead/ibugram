import SwiftUI

struct RemoteImage: View {
    let url: URL?
    var blurhash: String?
    var altText: String?
    var contentMode: ContentMode = .fill

    @Environment(\.appContainer) private var container
    @Environment(\.theme) private var theme
    @State private var loaded: UIImage?
    @State private var placeholder: UIImage?

    var body: some View {
        ZStack {
            if let loaded {
                Image(uiImage: loaded)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity)
            } else if let placeholder {
                Image(uiImage: placeholder)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 2)
            } else {
                theme.colors.skeletonBase
                    .shimmering()
            }
        }
        .clipped()
        .animation(theme.motion.standard, value: loaded == nil)
        .accessibilityLabel(altText ?? "Image")
        .task(id: url) { await load() }
        .task(id: blurhash) { renderBlurhash() }
    }

    private func load() async {
        loaded = nil
        guard let url else { return }
        loaded = await container.imageLoader.image(for: url)
    }

    private func renderBlurhash() {
        guard let blurhash else {
            placeholder = nil
            return
        }
        placeholder = BlurHash.image(from: blurhash)
    }
}

#Preview("Remote image") {
    RemoteImage(url: nil, blurhash: "LEHV6nWB2yk8pyo0adR*.7kCMdnj", altText: "Campus lawn")
        .frame(width: 320, height: 200)
        .clipShape(.rect(cornerRadius: 20))
        .padding()
}

#Preview("Remote image · dark") {
    RemoteImage(url: nil, blurhash: "LEHV6nWB2yk8pyo0adR*.7kCMdnj", altText: "Campus lawn")
        .frame(width: 320, height: 200)
        .clipShape(.rect(cornerRadius: 20))
        .padding()
        .preferredColorScheme(.dark)
}
