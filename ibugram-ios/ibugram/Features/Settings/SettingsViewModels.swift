import Foundation
import LocalAuthentication

@MainActor
@Observable
final class AppLockSettingsStore {
    private let key = "ibugram.appLock.enabled"
    private let defaults: UserDefaults

    var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: key) }
    }

    var biometryTitle: String {
        switch biometryType {
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        case .opticID: "Optic ID"
        default: "Device passcode"
        }
    }

    var isBiometryAvailable: Bool { biometryType != .none || canEvaluate }

    private let biometryType: LABiometryType
    private let canEvaluate: Bool

    init(defaults: UserDefaults = .standard, context: LAContext = LAContext()) {
        self.defaults = defaults
        isEnabled = defaults.bool(forKey: key)
        var error: NSError?
        canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        biometryType = context.biometryType
    }
}

@MainActor
@Observable
final class ActiveSessionsViewModel: ErrorPresenting {
    private(set) var sessions: [DeviceSession] = []
    private(set) var phase: Phase = .idle
    var presentedError: PresentedError?

    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case failed(APIError)
    }

    private let api: any APIRequesting

    init(api: any APIRequesting) {
        self.api = api
    }

    func load() async {
        phase = .loading
        do {
            sessions = try await api.send(SettingsEndpoints.Sessions())
            phase = .loaded
        } catch {
            phase = .failed(error.asAPIError)
        }
    }

    func revoke(_ session: DeviceSession) async {
        guard !session.isCurrent else { return }
        let previous = sessions
        sessions.removeAll { $0.id == session.id }
        do {
            _ = try await api.send(SettingsEndpoints.RevokeSession(id: session.id))
        } catch {
            sessions = previous
            present(error) { [weak self] in await self?.revoke(session) }
        }
    }
}

@MainActor
@Observable
final class ChangeUsernameViewModel: ErrorPresenting {
    var username: String
    var presentedError: PresentedError?
    private(set) var status: OnboardingViewModel.UsernameStatus = .idle
    private(set) var isSubmitting = false

    private let api: any APIRequesting
    private let currentUsername: String
    private var availabilityCheck: Task<Void, Never>?

    init(api: any APIRequesting, currentUsername: String) {
        self.api = api
        self.currentUsername = currentUsername
        username = currentUsername
    }

    var canSubmit: Bool {
        let candidate = username.lowercased()
        return candidate != currentUsername.lowercased()
            && status == .available
            && !isSubmitting
    }

    var message: String? {
        switch status {
        case .idle: "Letters, numbers, dots and underscores."
        case .checking: "Checking availability…"
        case .available: "@\(username) is available."
        case .taken: "@\(username) is already taken."
        case .invalid(let reason): reason
        }
    }

    var validationState: IBUTextField.ValidationState {
        switch status {
        case .available: .valid
        case .taken, .invalid: .invalid
        case .idle, .checking: .neutral
        }
    }

    func usernameDidChange() {
        availabilityCheck?.cancel()
        let candidate = username.lowercased()
        if candidate == currentUsername.lowercased() {
            status = .idle
            return
        }
        if candidate.isEmpty {
            status = .invalid("Pick a username.")
            return
        }
        if candidate.count < 3 {
            status = .invalid("At least 3 characters.")
            return
        }
        if candidate.count > 24 {
            status = .invalid("At most 24 characters.")
            return
        }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._")
        if candidate.unicodeScalars.contains(where: { !allowed.contains($0) }) {
            status = .invalid("Only letters, numbers, dots and underscores.")
            return
        }
        status = .checking
        availabilityCheck = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard let self, !Task.isCancelled else { return }
            await self.checkAvailability(of: candidate)
        }
    }

    func submit() async -> User? {
        guard canSubmit else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            return try await api.send(UserEndpoint.claimUsername(username.lowercased()))
        } catch {
            present(error) { [weak self] in _ = await self?.submit() }
            return nil
        }
    }

    private func checkAvailability(of candidate: String) async {
        do {
            _ = try await api.send(UserEndpoint.profile(username: candidate))
            status = .taken
        } catch APIError.notFound {
            status = .available
        } catch {
            status = .idle
        }
    }
}
