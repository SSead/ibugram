import Foundation
import Testing
@testable import IBUgramKit

@Suite("Endpoint catalogue")
struct EndpointTests {
    @Test("Every route sits under the versioned prefix except health")
    func versionPrefixing() {
        #expect(API.Auth.requestCode.fullPath == "/api/v1/auth/request-code")
        #expect(API.Users.me.fullPath == "/api/v1/users/me")
        #expect(API.health.fullPath == "/health")
        #expect(API.versionedHealth.fullPath == "/api/v1/health")
    }

    @Test("Methods match the contract table")
    func methods() {
        #expect(API.Auth.verifyCode.method == .post)
        #expect(API.Users.updateMe.method == .patch)
        #expect(API.Users.unfollowTemplate.method == .delete)
        #expect(API.Events.rsvpTemplate.method == .put)
        #expect(API.Feed.discover.method == .get)
    }

    @Test("Templates expose their parameter names for server-side route registration")
    func templatesExposeParameters() {
        #expect(API.Users.profileTemplate.parameterNames == ["username"])
        #expect(API.Spaces.setMemberRoleTemplate.parameterNames == ["slug", "userID"])
        #expect(API.Posts.createCommentTemplate.parameterNames == ["id"])
        #expect(API.Auth.sessions.parameterNames.isEmpty)
    }

    @Test("Substituting a parameter produces the concrete path")
    func substitution() {
        let id = Fixture.postId
        #expect(API.Posts.like(id: id).fullPath == "/api/v1/posts/\(id.uuidString)/like")
        #expect(API.Users.profile(username: "amina.h").fullPath == "/api/v1/users/amina.h")
        #expect(API.Spaces.setMemberRole(slug: "burch-robotics", userId: id).fullPath
            == "/api/v1/spaces/burch-robotics/members/\(id.uuidString)/role")
    }

    @Test("A parameter containing path characters is percent-encoded")
    func substitutionEscapes() {
        #expect(API.Search.hashtagPosts(tag: "burch/2026").fullPath == "/api/v1/hashtags/burch%2F2026/posts")
        #expect(API.Users.profile(username: "a b").fullPath == "/api/v1/users/a%20b")
    }

    @Test("An endpoint builds an absolute URL with query items")
    func buildsURL() throws {
        let base = try #require(URL(string: "http://127.0.0.1:8080"))
        let url = API.Feed.following.url(relativeTo: base, query: PageRequest(limit: 20).queryItems)
        #expect(url?.absoluteString == "http://127.0.0.1:8080/api/v1/feed/following?limit=20")
    }

    @Test("A page request clamps the limit to the supported range")
    func pageRequestClamps() {
        #expect(PageRequest(limit: 0).limit == 1)
        #expect(PageRequest(limit: 5_000).limit == IBUgram.maxPageSize)
        #expect(PageRequest(limit: 20, cursor: "abc").queryItems.count == 2)
    }
}
