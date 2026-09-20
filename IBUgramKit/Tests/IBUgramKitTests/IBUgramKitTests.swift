import Testing
@testable import IBUgramKit

@Test func allowedDomainsAreRestrictedToTheUniversity() {
    #expect(IBUgram.allowedEmailDomains == ["ibu.edu.ba", "stu.ibu.edu.ba"])
}
