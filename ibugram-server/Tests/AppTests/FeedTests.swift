import Foundation
import IBUgramKit
import Testing
import Vapor
import VaporTesting
@testable import App

@Suite("Feed", .serialized)
struct FeedTests {
    @Test("The following feed is reverse-chronological from followed users")
    func followingFeed() async throws {
        try await withSocialTestServer { context in
            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina")
            let emir = try await context.signIn(as: "emir.k@stu.ibu.edu.ba")
            try await context.completeOnboarding(emir, username: "emir.k", displayName: "Emir")
            let post = try await context.createPost(
                token: amina.accessToken,
                userId: amina.user.id,
                caption: "from amina"
            )
            _ = try await context.send(.POST, API.Users.follow(id: amina.user.id).fullPath, token: emir.accessToken)

            let feed = try await context.get(API.Feed.following.fullPath, token: emir.accessToken)
            #expect(feed.status == .ok)
            let items = try feed.content.decode(Paginated<Post>.self).items
            #expect(items.map(\.id) == [post.id])
        }
    }

    @Test("Feed endpoints reject a missing token")
    func feedRequiresAuthentication() async throws {
        try await withSocialTestServer { context in
            for path in [API.Feed.following.fullPath, API.Feed.discover.fullPath] {
                let response = try await context.app.testing().sendRequest(.GET, path)
                #expect(response.status == .unauthorized)
            }
        }
    }

    @Test("A blocked author's posts disappear from both feeds")
    func blockHidesFeedContent() async throws {
        try await withSocialTestServer { context in
            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina")
            let emir = try await context.signIn(as: "emir.k@stu.ibu.edu.ba")
            try await context.completeOnboarding(emir, username: "emir.k", displayName: "Emir")
            let post = try await context.createPost(token: amina.accessToken, userId: amina.user.id, caption: "visible then not")
            _ = try await context.send(.POST, API.Users.follow(id: amina.user.id).fullPath, token: emir.accessToken)

            let before = try await context.get(API.Feed.following.fullPath, token: emir.accessToken)
            #expect(try before.content.decode(Paginated<Post>.self).items.map(\.id) == [post.id])

            _ = try await context.send(.POST, API.Users.block(id: emir.user.id).fullPath, token: amina.accessToken)

            let following = try await context.get(API.Feed.following.fullPath, token: emir.accessToken)
            #expect(try following.content.decode(Paginated<Post>.self).items.isEmpty)

            let discover = try await context.get(API.Feed.discover.fullPath, token: emir.accessToken)
            #expect(try discover.content.decode(Paginated<Post>.self).items.map(\.id).contains(post.id) == false)
        }
    }

    @Test("Discover returns ranked campus posts and paginates to termination")
    func discoverRanksAndPaginates() async throws {
        try await withSocialTestServer { context in
            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina", department: "IT")
            var ids: [UUID] = []
            for index in 1...3 {
                let post = try await context.createPost(
                    token: amina.accessToken,
                    userId: amina.user.id,
                    caption: "discover \(index)"
                )
                ids.append(post.id)
            }
            let first = try await context.get(API.Feed.discover.fullPath + "?limit=2", token: amina.accessToken)
            #expect(first.status == .ok)
            let page = try first.content.decode(Paginated<Post>.self)
            #expect(page.items.count == 2)
            let cursor = try #require(page.nextCursor)
            let second = try await context.get(
                API.Feed.discover.fullPath + "?limit=2&cursor=\(cursor)",
                token: amina.accessToken
            )
            let rest = try second.content.decode(Paginated<Post>.self)
            #expect(rest.items.count == 1)
            #expect(rest.nextCursor == nil)
            #expect(Set(page.items.map(\.id)).isDisjoint(with: Set(rest.items.map(\.id))))
        }
    }
}
