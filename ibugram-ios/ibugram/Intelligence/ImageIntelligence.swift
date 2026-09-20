import Foundation
import Vision

struct ImageInsight: Sendable, Equatable {
    let suggestedAltText: String
    let sceneLabels: [String]

    static let empty = ImageInsight(suggestedAltText: "", sceneLabels: [])
}

/// On-device only. No image bytes leave the phone for analysis.
protocol ImageIntelligenceProviding: Sendable {
    func insight(forImageData data: Data) async throws -> ImageInsight
}

struct VisionImageIntelligence: ImageIntelligenceProviding {
    private let minimumConfidence: Float
    private let maximumLabels: Int

    init(minimumConfidence: Float = 0.25, maximumLabels: Int = 4) {
        self.minimumConfidence = minimumConfidence
        self.maximumLabels = maximumLabels
    }

    func insight(forImageData data: Data) async throws -> ImageInsight {
        let labels = try classify(data)
        guard !labels.isEmpty else { return .empty }
        return ImageInsight(suggestedAltText: Self.altText(from: labels), sceneLabels: labels)
    }

    private func classify(_ data: Data) throws -> [String] {
        let request = VNClassifyImageRequest()
        try VNImageRequestHandler(data: data).perform([request])
        let observations = request.results ?? []
        return observations
            .filter { $0.confidence >= minimumConfidence }
            .prefix(maximumLabels)
            .map { $0.identifier.replacingOccurrences(of: "_", with: " ") }
    }

    private static func altText(from labels: [String]) -> String {
        guard let first = labels.first else { return "" }
        let remainder = labels.dropFirst()
        guard !remainder.isEmpty else { return "A photo of \(first)." }
        return "A photo of \(first), showing \(remainder.joined(separator: ", "))."
    }
}

struct StubImageIntelligence: ImageIntelligenceProviding {
    let stubbed: ImageInsight

    init(stubbed: ImageInsight = ImageInsight(
        suggestedAltText: "A photo of students on the Burch campus lawn.",
        sceneLabels: ["campus", "students", "outdoors"]
    )) {
        self.stubbed = stubbed
    }

    func insight(forImageData data: Data) async throws -> ImageInsight { stubbed }
}
