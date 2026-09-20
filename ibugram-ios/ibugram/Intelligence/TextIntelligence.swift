import Foundation
import NaturalLanguage

struct CaptionInsight: Sendable, Equatable {
    let suggestedHashtags: [String]
    let dominantLanguage: String?
    let sentiment: Double?

    static let empty = CaptionInsight(suggestedHashtags: [], dominantLanguage: nil, sentiment: nil)
}

protocol TextIntelligenceProviding: Sendable {
    func insight(forCaption caption: String) async -> CaptionInsight
}

struct NaturalLanguageTextIntelligence: TextIntelligenceProviding {
    private let maximumHashtags: Int

    init(maximumHashtags: Int = 6) {
        self.maximumHashtags = maximumHashtags
    }

    func insight(forCaption caption: String) async -> CaptionInsight {
        let trimmed = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }
        return CaptionInsight(
            suggestedHashtags: hashtags(in: trimmed),
            dominantLanguage: NLLanguageRecognizer.dominantLanguage(for: trimmed)?.rawValue,
            sentiment: sentiment(of: trimmed)
        )
    }

    private func hashtags(in caption: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameTypeOrLexicalClass])
        tagger.string = caption
        var candidates: [String] = []
        tagger.enumerateTags(
            in: caption.startIndex..<caption.endIndex,
            unit: .word,
            scheme: .nameTypeOrLexicalClass,
            options: [.omitWhitespace, .omitPunctuation, .omitOther]
        ) { tag, range in
            guard let tag, Self.hashtagWorthyTags.contains(tag) else { return true }
            let word = String(caption[range]).lowercased()
            if word.count > 2, !candidates.contains(word) { candidates.append(word) }
            return candidates.count < maximumHashtags
        }
        return candidates
    }

    private func sentiment(of caption: String) -> Double? {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = caption
        let (tag, _) = tagger.tag(at: caption.startIndex, unit: .paragraph, scheme: .sentimentScore)
        return tag.flatMap { Double($0.rawValue) }
    }

    private static let hashtagWorthyTags: Set<NLTag> = [
        .noun, .personalName, .placeName, .organizationName
    ]
}

struct StubTextIntelligence: TextIntelligenceProviding {
    let stubbed: CaptionInsight

    init(stubbed: CaptionInsight = CaptionInsight(
        suggestedHashtags: ["burch", "campus", "robotics"],
        dominantLanguage: "en",
        sentiment: 0.6
    )) {
        self.stubbed = stubbed
    }

    func insight(forCaption caption: String) async -> CaptionInsight { stubbed }
}
