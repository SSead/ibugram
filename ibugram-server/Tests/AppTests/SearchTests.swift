import Foundation
import IBUgramKit
import Testing
import Vapor
import VaporTesting
@testable import App

@Suite("Search", .serialized)
struct SearchTests {
    @Test("Search matches a post caption through the simple tsvector index")
    func searchMatchesCaption() async throws {
        try await withSocialTestServer { context in
            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina Hodzic")
            let post = try await context.createPost(
                token: amina.accessToken,
                userId: amina.user.id,
                caption: "Sarajevo library night #study"
            )

            let response = try await context.get(
                API.Search.query.fullPath + "?q=library&type=posts",
                token: amina.accessToken
            )
            #expect(response.status == .ok)
            let results = try response.content.decode(SearchResults.self)
            #expect(results.posts.map(\.id) == [post.id])
        }
    }

    @Test("Search endpoints reject a missing token")
    func searchRequiresAuthentication() async throws {
        try await withSocialTestServer { context in
            let paths = [
                API.Search.query.fullPath,
                API.Search.trending.fullPath,
                API.Search.hashtagPosts(tag: "ibu").fullPath
            ]
            for path in paths {
                let response = try await context.app.testing().sendRequest(.GET, path)
                #expect(response.status == .unauthorized)
            }
        }
    }

    @Test("Trending hashtags and the hashtag timeline include a newly tagged post")
    func trendingAndHashtagTimeline() async throws {
        try await withSocialTestServer { context in
            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina")
            let post = try await context.createPost(
                token: amina.accessToken,
                userId: amina.user.id,
                caption: "Welcome to #ibuweek"
            )

            let trending = try await context.get(API.Search.trending.fullPath, token: amina.accessToken)
            #expect(trending.status == .ok)
            let tags = try trending.content.decode([Hashtag].self)
            #expect(tags.map(\.tag).contains("ibuweek"))

            let tagged = try await context.get(
                API.Search.hashtagPosts(tag: "ibuweek").fullPath,
                token: amina.accessToken
            )
            #expect(try tagged.content.decode(Paginated<Post>.self).items.map(\.id) == [post.id])
        }
    }

    @Test("User search finds an onboarded account by username")
    func searchFindsUsers() async throws {
        try await withSocialTestServer { context in
            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina Hodzic")
            let response = try await context.get(
                API.Search.query.fullPath + "?q=amina&type=users",
                token: amina.accessToken
            )
            #expect(try response.content.decode(SearchResults.self).users.map(\.username) == ["amina.h"])
        }
    }
}
