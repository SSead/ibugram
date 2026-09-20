import Foundation
import UIKit
import IBUgramKit

@MainActor
@Observable
final class OnboardingViewModel: ErrorPresenting {
    enum UsernameStatus: Equatable {
        case idle
        case checking
        case available
        case taken
        case invalid(String)
    }

    var username = "" {
        didSet { scheduleAvailabilityCheck() }
    }

    var displayName = ""
    var department = ""
    var yearOfStudy: Int?
    var avatarImageData: Data?
    var presentedError: PresentedError?

    private(set) var usernameStatus: UsernameStatus = .idle
    private(set) var isSubmitting = false

    static let departments = [
        "Information Technologies",
        "Software Engineering",
        "Genetics and Bioengineering",
        "Architecture",
        "Economics",
        "Management",
        "English Language and Literature",
        "International Relations",
        "Psychology"
    ]

    private let api: any APIRequesting
    private var availabilityCheck: Task<Void, Never>?

    init(api: any APIRequesting, user: User) {
        self.api = api
        self.displayName = user.displayName
        self.department = user.department ?? ""
        self.yearOfStudy = user.yearOfStudy
    }

    var canSubmit: Bool {
        usernameStatus == .available && !trimmedDisplayName.isEmpty && !isSubmitting
    }

    var trimmedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var usernameMessage: String? {
        switch usernameStatus {
        case .idle: "Letters, numbers, dots and underscores. This is how people @mention you."
        case .checking: "Checking availability…"
        case .available: "@\(username) is available."
        case .taken: "@\(username) is already taken."
        case .invalid(let reason): reason
        }
    }

    var usernameValidationState: IBUTextField.ValidationState {
        switch usernameStatus {
        case .available: .valid
        case .taken, .invalid: .invalid
        case .idle, .checking: .neutral
        }
    }

    func submit() async -> User? {
        guard canSubmit else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let avatar = try await uploadAvatarIfNeeded()
            _ = try await api.send(UserEndpoint.claimUsername(username))
            return try await api.send(profileUpdate(avatarMediaID: avatar?.id))
        } catch {
            present(error) { [weak self] in _ = await self?.submit() }
            return nil
        }
    }

    private func uploadAvatarIfNeeded() async throws -> Media? {
        guard let avatarImageData else { return nil }
        return try await api.send(MediaEndpoint.upload(jpeg: avatarImageData, filename: "avatar.jpg"))
    }

    private func profileUpdate(avatarMediaID: UUID?) -> UserEndpoint.UpdateProfile {
        UserEndpoint.UpdateProfile(
            displayName: trimmedDisplayName,
            bio: nil,
            department: department.isEmpty ? nil : department,
            yearOfStudy: yearOfStudy,
            avatarMediaId: avatarMediaID
        )
    }
}

// MARK: - Username availability

private extension OnboardingViewModel {
    /// The contract has no availability endpoint, so a profile lookup stands in: `not_found`
    /// means the handle is free.
    func scheduleAvailabilityCheck() {
        availabilityCheck?.cancel()
        let candidate = username.lowercased()
        guard let problem = Self.validationProblem(for: candidate) else {
            usernameStatus = .checking
            availabilityCheck = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(400))
                guard let self, !Task.isCancelled, self.username.lowercased() == candidate else { return }
                await self.checkAvailability(of: candidate)
            }
            return
        }
        usernameStatus = candidate.isEmpty ? .idle : .invalid(problem)
    }

    func checkAvailability(of candidate: String) async {
        do {
            _ = try await api.send(UserEndpoint.profile(username: candidate))
            usernameStatus = .taken
        } catch APIError.notFound {
            usernameStatus = .available
        } catch {
            usernameStatus = .idle
        }
    }

    static func validationProblem(for candidate: String) -> String? {
        if candidate.isEmpty { return "Pick a username." }
        if candidate.count < 3 { return "At least 3 characters." }
        if candidate.count > 24 { return "At most 24 characters." }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._")
        if candidate.unicodeScalars.contains(where: { !allowed.contains($0) }) {
            return "Only letters, numbers, dots and underscores."
        }
        return nil
    }
}
