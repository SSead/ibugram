import Foundation

enum ComposerFixtures {
    static let campusPlaces: [Place] = [FeedFixtures.campusLawn, FeedFixtures.cafeteria]
    static let spaces: [SpaceSummary] = [FeedFixtures.robotics]

    static let previewImage = ComposerDraftImage(
        data: Data(),
        altText: "Students on the Burch campus lawn.",
        suggestedAltText: "A photo of students on the Burch campus lawn."
    )
}
