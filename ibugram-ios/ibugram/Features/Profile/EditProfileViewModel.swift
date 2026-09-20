import Foundation
import UIKit
import IBUgramKit

@MainActor
@Observable
final class EditProfileViewModel: ErrorPresenting {
    var displayName: String
    var bio: String
    var department: String
    var yearOfStudy: Int?
    var avatarImageData: Data?
    var presentedError: PresentedError?
    private(set) var isSubmitting = false

    private let api: any APIRequesting
    private let original: User

    init(api: any APIRequesting, user: User) {
        self.api = api
        original = user
        displayName = user.displayName
        bio = user.bio ?? ""
        department = user.department ?? ""
        yearOfStudy = user.yearOfStudy
    }

    var trimmedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSubmit: Bool {
        !trimmedDisplayName.isEmpty && !isSubmitting
    }

    func submit() async -> User? {
        guard canSubmit else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let media = try await uploadAvatarIfNeeded()
            return try await api.send(
                UserEndpoint.UpdateProfile(
                    displayName: trimmedDisplayName,
                    bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
                    department: department.isEmpty ? nil : department,
                    yearOfStudy: yearOfStudy,
                    avatarMediaId: media?.id
                )
            )
        } catch {
            present(error) { [weak self] in _ = await self?.submit() }
            return nil
        }
    }

    private func uploadAvatarIfNeeded() async throws -> Media? {
        guard let avatarImageData else { return nil }
        return try await api.send(MediaEndpoint.upload(jpeg: jpegData(from: avatarImageData), filename: "avatar.jpg"))
    }

    private func jpegData(from data: Data) -> Data {
        UIImage(data: data)?.jpegData(compressionQuality: 0.9) ?? data
    }
}
