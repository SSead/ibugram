import Foundation
import Testing
@testable import IBUgramKit

@Suite("Email domain and role")
struct EmailDomainTests {
    @Test("Only the two university domains are allowed")
    func allowedDomains() {
        #expect(IBUgram.allowedEmailDomains == ["ibu.edu.ba", "stu.ibu.edu.ba"])
    }

    @Test("A student address derives the student role")
    func studentRole() {
        #expect(EmailAddress.role(for: "amina@stu.ibu.edu.ba") == .student)
        #expect(EmailAddress.domain(of: "amina@stu.ibu.edu.ba") == .student)
    }

    @Test("A staff address derives the faculty role")
    func facultyRole() {
        #expect(EmailAddress.role(for: "kovac@ibu.edu.ba") == .faculty)
        #expect(EmailAddress.domain(of: "kovac@ibu.edu.ba") == .faculty)
    }

    @Test("Addresses are matched case-insensitively and after trimming")
    func addressesAreNormalized() {
        #expect(EmailAddress.normalized("  Amina.H@STU.IBU.edu.BA ") == "amina.h@stu.ibu.edu.ba")
        #expect(EmailAddress.isAllowed("  Amina.H@STU.IBU.edu.BA "))
    }

    @Test(
        "Addresses outside the university are rejected",
        arguments: [
            "someone@gmail.com",
            "someone@notibu.edu.ba",
            "someone@sub.stu.ibu.edu.ba",
            "someone@ibu.edu.ba.attacker.com",
            "ibu.edu.ba",
            "@ibu.edu.ba",
            "someone@",
            "two@@ibu.edu.ba",
            "spaced person@ibu.edu.ba"
        ]
    )
    func rejectsForeignAddresses(address: String) {
        #expect(EmailAddress.isAllowed(address) == false)
        #expect(EmailAddress.role(for: address) == nil)
    }

    @Test("The local part is extracted from a valid address")
    func localPartIsExtracted() {
        #expect(EmailAddress.localPart(of: "Amina.H@stu.ibu.edu.ba") == "amina.h")
        #expect(EmailAddress.localPart(of: "nonsense") == nil)
    }
}

@Suite("Username rules")
struct UsernameTests {
    @Test(
        "Well-formed usernames are accepted",
        arguments: ["amina.h", "prof_kovac", "burch2026", "abc"]
    )
    func acceptsValidUsernames(candidate: String) {
        #expect(Username.isValid(candidate))
        #expect(Username.validate(candidate) == nil)
    }

    @Test("Each rejection reports why")
    func rejectionsAreExplained() {
        #expect(Username.validate("ab") == .tooShort)
        #expect(Username.validate(String(repeating: "a", count: 31)) == .tooLong)
        #expect(Username.validate("Amina") == .notLowercased)
        #expect(Username.validate("am ina") == .illegalCharacter)
        #expect(Username.validate("amina!") == .illegalCharacter)
        #expect(Username.validate(".amina") == .badBoundary)
        #expect(Username.validate("amina.") == .badBoundary)
        #expect(Username.validate("am..ina") == .repeatedSeparator)
        #expect(Username.validate("user_amina") == .reserved)
    }

    @Test("A suggestion derived from an email local part is itself valid")
    func suggestionsAreUsable() {
        #expect(Username.suggestion(fromEmailLocalPart: "Amina.Hodzic") == "amina.hodzic")
        #expect(Username.suggestion(fromEmailLocalPart: "amina+tag") == "amina.tag")
        #expect(Username.isValid(Username.suggestion(fromEmailLocalPart: "Amina.Hodzic")))
    }
}

@Suite("Content parsing")
struct HashtagParserTests {
    @Test("Hashtags and mentions are extracted casefolded and deduplicated")
    func parsesCaptions() {
        let caption = "Great night with @Prof.Kovac and @amina.h #Robotics #robotics #burch2026!"
        #expect(HashtagParser.hashtags(in: caption) == ["robotics", "burch2026"])
        #expect(HashtagParser.mentions(in: caption) == ["prof.kovac", "amina.h"])
    }

    @Test("A caption without markers yields nothing")
    func parsesPlainText() {
        #expect(HashtagParser.hashtags(in: "just a photo").isEmpty)
        #expect(HashtagParser.mentions(in: "just a photo").isEmpty)
    }
}
