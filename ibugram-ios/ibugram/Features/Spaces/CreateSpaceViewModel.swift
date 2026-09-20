import Foundation
import IBUgramKit

@MainActor
@Observable
final class CreateSpaceViewModel: ErrorPresenting {
    var name = ""
    var slug = ""
    var description = ""
    var kind: SpaceKind = .community
    var visibility: SpaceVisibility = .public
    var isOfficial = false
    private(set) var isSubmitting = false
    var presentedError: PresentedError?

    let currentUser: User?
    private let api: any APIRequesting
    private var slugEdited = false

    init(api: any APIRequesting, currentUser: User?) {
        self.api = api
        self.currentUser = currentUser
    }

    var canMarkOfficial: Bool { currentUser?.role == .faculty }

    var canSubmit: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && SpaceSlug.isValid(slug) && !isSubmitting
    }

    func nameDidChange() {
        if !slugEdited {
            slug = Self.slug(from: name)
        }
    }

    func slugDidChange() {
        slugEdited = true
    }

    func submit() async -> Space? {
        guard canSubmit else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }
        let body = CreateSpaceBody(
            slug: slug,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: trimmedDescription,
            kind: kind,
            visibility: visibility,
            isOfficial: canMarkOfficial && isOfficial
        )
        do {
            return try await api.send(SpaceEndpoints.Create(bodyValue: body))
        } catch {
            present(error) { [weak self] in _ = await self?.submit() }
            return nil
        }
    }

    private var trimmedDescription: String? {
        let value = description.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    static func slug(from name: String) -> String {
        let lowered = name.lowercased()
        var slug = ""
        var lastWasHyphen = false
        for character in lowered {
            if character.isLetter || character.isNumber {
                slug.append(character)
                lastWasHyphen = false
            } else if character.isWhitespace || character == "_" || character == "-" {
                if !slug.isEmpty && !lastWasHyphen {
                    slug.append("-")
                    lastWasHyphen = true
                }
            }
        }
        while slug.hasSuffix("-") { slug.removeLast() }
        if slug.count > SpaceSlug.maximumLength {
            slug = String(slug.prefix(SpaceSlug.maximumLength))
            while slug.hasSuffix("-") { slug.removeLast() }
        }
        return slug
    }
}
