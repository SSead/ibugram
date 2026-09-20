import SwiftUI
import IBUgramKit

struct SpaceJoinButton: View {
    let space: Space
    var isMutating = false
    var onJoin: () -> Void
    var onLeave: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Group {
            if SpaceJoinPolicy.canJoin(space) {
                Button(joinTitle, action: onJoin)
                    .buttonStyle(.ibuPrimary(isLoading: isMutating))
                    .accessibilityHint(joinHint)
            } else if SpaceJoinPolicy.canLeave(space) {
                Button(leaveTitle, action: onLeave)
                    .buttonStyle(.ibuSecondary(isLoading: isMutating))
                    .accessibilityHint("Leave this Space")
            } else if space.visibility == .invite, SpaceJoinPolicy.membership(of: space) == .none {
                Button("Invite only") {}
                    .buttonStyle(.ibuSecondary)
                    .disabled(true)
                    .accessibilityLabel("Invite only")
                    .accessibilityHint("This Space is invite only")
            } else if SpaceJoinPolicy.membership(of: space) == .owner {
                Button("Owner") {}
                    .buttonStyle(.ibuSecondary)
                    .disabled(true)
                    .accessibilityLabel("You own this Space")
            }
        }
        .disabled(isMutating)
    }

    private var joinTitle: String {
        space.visibility == .request ? "Request to join" : "Join"
    }

    private var joinHint: String {
        space.visibility == .request
            ? "Send a request to join this Space"
            : "Join this Space"
    }

    private var leaveTitle: String {
        SpaceJoinPolicy.membership(of: space) == .pending ? "Requested" : "Leave"
    }
}

#Preview("Join buttons") {
    VStack(spacing: 16) {
        SpaceJoinButton(space: SpaceFixtures.robotics, onJoin: {}, onLeave: {})
        SpaceJoinButton(space: SpaceFixtures.engineering, onJoin: {}, onLeave: {})
        SpaceJoinButton(space: SpaceFixtures.facultyCircle, onJoin: {}, onLeave: {})
        SpaceJoinButton(space: SpaceFixtures.filmClub, onJoin: {}, onLeave: {})
    }
    .padding()
    .appContainer(.preview())
}
