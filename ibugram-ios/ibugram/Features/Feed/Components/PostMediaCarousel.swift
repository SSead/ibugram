import SwiftUI
import IBUgramKit

struct PostMediaCarousel: View {
    let media: [Media]
    var onDoubleTap: () -> Void = {}

    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var showsHeart = false

    var body: some View {
        ZStack {
            TabView(selection: $page) {
                ForEach(Array(media.enumerated()), id: \.element.id) { index, item in
                    RemoteImage(
                        url: item.resourceURL,
                        blurhash: item.blurhash,
                        altText: item.altText,
                        contentMode: .fill
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity)
            .aspectRatio(aspectRatio, contentMode: .fit)
            .onTapGesture(count: 2, perform: doubleTap)

            if showsHeart {
                Image(systemName: "heart.fill")
                    .font(theme.typography.displayLarge)
                    .foregroundStyle(theme.colors.textOnBrand)
                    .shadow(theme.shadows.elevated)
                    .scaleEffect(reduceMotion ? 1 : 1.15)
                    .transition(.opacity)
                    .accessibilityHidden(true)
            }

            if media.count > 1 {
                VStack {
                    Spacer()
                    pageIndicator
                        .padding(.bottom, theme.spacing.xs)
                }
                .allowsHitTesting(false)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(currentAltText)
        .accessibilityValue(media.count > 1 ? "Photo \(page + 1) of \(media.count)" : "")
        .accessibilityAddTraits(.isImage)
        .accessibilityHint("Double tap to like")
        .animation(reduceMotion ? nil : theme.motion.emphasis, value: showsHeart)
    }

    private var currentAltText: String {
        media[safe: page]?.altText ?? media.first?.altText ?? "Post photo"
    }

    private var aspectRatio: CGFloat {
        guard let item = media.first, item.height > 0 else { return 1 }
        let ratio = CGFloat(item.width) / CGFloat(item.height)
        return min(max(ratio, 4 / 5), 16 / 9)
    }

    private var pageIndicator: some View {
        HStack(spacing: theme.spacing.xxs) {
            ForEach(media.indices, id: \.self) { index in
                Circle()
                    .fill(index == page ? theme.colors.textOnBrand : theme.colors.textOnBrand.opacity(0.45))
                    .frame(width: theme.spacing.xxs, height: theme.spacing.xxs)
            }
        }
        .padding(.horizontal, theme.spacing.xs)
        .padding(.vertical, theme.spacing.xxs)
        .background(theme.colors.textPrimary.opacity(0.55), in: .capsule)
        .accessibilityHidden(true)
    }

    private func doubleTap() {
        onDoubleTap()
        if reduceMotion {
            showsHeart = true
            Task {
                try? await Task.sleep(for: .milliseconds(350))
                showsHeart = false
            }
            return
        }
        showsHeart = true
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            showsHeart = false
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
