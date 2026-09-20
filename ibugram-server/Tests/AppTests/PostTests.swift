import Foundation
import IBUgramKit
import Testing
import Vapor
import VaporTesting
@testable import App

@Suite("Posts", .serialized)
struct PostTests {
    @Test("Creating a post extracts hashtags and mentions from the caption")
    func createExtractsTags() async throws {
        try await withSocialTestServer { context in
            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina")
            let emir = try await context.signIn(as: "emir.k@stu.ibu.edu.ba")
            try await context.completeOnboarding(emir, username: "emir.k", displayName: "Emir")

            let post = try await context.createPost(
                token: amina.accessToken,
                userId: amina.user.id,
                caption: "Open day at #IBU with @emir.k and more #campus food"
            )
            #expect(Set(post.hashtags) == ["ibu", "campus"])
            #expect(post.mentions.map(\.username) == ["emir.k"])
            #expect(post.author.username == "amina.h")
            #expect(post.media.count == 1)
            #expect(post.viewer?.hasLiked == false)
        }
    }

    @Test("Post mutations require a bearer token")
    func postsRequireAuthentication() async throws {
        try await withSocialTestServer { context in
            let id = UUID()
            let paths: [(HTTPMethod, String)] = [
                (.POST, API.Posts.create.fullPath),
                (.GET, API.Posts.detail(id: id).fullPath),
                (.PATCH, API.Posts.update(id: id).fullPath),
                (.DELETE, API.Posts.delete(id: id).fullPath),
                (.POST, API.Posts.like(id: id).fullPath),
                (.DELETE, API.Posts.unlike(id: id).fullPath),
                (.POST, API.Posts.save(id: id).fullPath),
                (.DELETE, API.Posts.unsave(id: id).fullPath),
                (.GET, API.Posts.likes(id: id).fullPath),
                (.GET, API.Users.savedPosts.fullPath)
            ]
            for (method, path) in paths {
                let response = try await context.app.testing().sendRequest(method, path)
                #expect(response.status == .unauthorized)
            }
        }
    }

    @Test("Only the author may edit or delete a post")
    func authorisationIsEnforced() async throws {
        try await withSocialTestServer { context in
            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina")
            let emir = try await context.signIn(as: "emir.k@stu.ibu.edu.ba")
            try await context.completeOnboarding(emir, username: "emir.k", displayName: "Emir")
            let post = try await context.createPost(token: amina.accessToken, userId: amina.user.id, caption: "mine")

            let patched = try await context.app.testing().sendRequest(
                .PATCH,
                API.Posts.update(id: post.id).fullPath,
                headers: context.authorized(emir.accessToken),
                beforeRequest: { try $0.content.encode(UpdatePostBody(caption: "stolen")) }
            )
            #expect(patched.status == .forbidden)

            let deleted = try await context.app.testing().sendRequest(
                .DELETE,
                API.Posts.delete(id: post.id).fullPath,
                headers: context.authorized(emir.accessToken)
            )
            #expect(deleted.status == .forbidden)

            let ownEdit = try await context.app.testing().sendRequest(
                .PATCH,
                API.Posts.update(id: post.id).fullPath,
                headers: context.authorized(amina.accessToken),
                beforeRequest: { try $0.content.encode(UpdatePostBody(caption: "updated #newtag")) }
            )
            #expect(ownEdit.status == .ok)
            let updated = try ownEdit.content.decode(Post.self)
            #expect(updated.caption == "updated #newtag")
            #expect(updated.hashtags == ["newtag"])
            #expect(updated.editedAt != nil)
        }
    }

    @Test("Liking is idempotent and the trigger-maintained counter stays at one")
    func likeIsIdempotentAndCounted() async throws {
        try await withSocialTestServer { context in
            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina")
            let post = try await context.createPost(token: amina.accessToken, userId: amina.user.id)

            let likePath = API.Posts.like(id: post.id).fullPath
            #expect(try await context.app.testing().sendRequest(.POST, likePath, headers: context.authorized(amina.accessToken)).status == .noContent)
            #expect(try await context.app.testing().sendRequest(.POST, likePath, headers: context.authorized(amina.accessToken)).status == .noContent)

            let detail = try await context.get(API.Posts.detail(id: post.id).fullPath, token: amina.accessToken)
            let loaded = try detail.content.decode(Post.self)
            #expect(loaded.counts.likes == 1)
            #expect(loaded.viewer?.hasLiked == true)

            let likes = try await context.get(API.Posts.likes(id: post.id).fullPath, token: amina.accessToken)
            #expect(try likes.content.decode(Paginated<IBUgramKit.User>.self).items.map(\.id) == [amina.user.id])

            #expect(try await context.app.testing().sendRequest(.DELETE, likePath, headers: context.authorized(amina.accessToken)).status == .noContent)
            let after = try await context.get(API.Posts.detail(id: post.id).fullPath, token: amina.accessToken)
            #expect(try after.content.decode(Post.self).counts.likes == 0)
        }
    }

    @Test("Saving a post lists it under /me/saved and unsaving removes it")
    func saveAndUnsave() async throws {
        try await withSocialTestServer { context in
            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina")
            let post = try await context.createPost(token: amina.accessToken, userId: amina.user.id, caption: "keep")

            #expect(try await context.app.testing().sendRequest(
                .POST,
                API.Posts.save(id: post.id).fullPath,
                headers: context.authorized(amina.accessToken)
            ).status == .noContent)

            let saved = try await context.get(API.Users.savedPosts.fullPath, token: amina.accessToken)
            #expect(try saved.content.decode(Paginated<Post>.self).items.map(\.id) == [post.id])

            #expect(try await context.app.testing().sendRequest(
                .DELETE,
                API.Posts.unsave(id: post.id).fullPath,
                headers: context.authorized(amina.accessToken)
            ).status == .noContent)
            let empty = try await context.get(API.Users.savedPosts.fullPath, token: amina.accessToken)
            #expect(try empty.content.decode(Paginated<Post>.self).items.isEmpty)
        }
    }

    @Test("A profile post grid paginates with a terminating cursor")
    func profilePostsPaginate() async throws {
        try await withSocialTestServer { context in
            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina")
            var created: [UUID] = []
            for index in 1...3 {
                let post = try await context.createPost(
                    token: amina.accessToken,
                    userId: amina.user.id,
                    caption: "post \(index)"
                )
                created.append(post.id)
            }
            let first = try await context.get(API.Users.posts(username: "amina.h").fullPath + "?limit=2", token: amina.accessToken)
            let page = try first.content.decode(Paginated<Post>.self)
            #expect(page.items.count == 2)
            let cursor = try #require(page.nextCursor)
            let second = try await context.get(
                API.Users.posts(username: "amina.h").fullPath + "?limit=2&cursor=\(cursor)",
                token: amina.accessToken
            )
            let rest = try second.content.decode(Paginated<Post>.self)
            #expect(rest.items.count == 1)
            #expect(rest.nextCursor == nil)
        }
    }

    @Test("The author can delete their post")
    func authorCanDelete() async throws {
        try await withSocialTestServer { context in
            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina")
            let post = try await context.createPost(token: amina.accessToken, userId: amina.user.id)
            let deleted = try await context.app.testing().sendRequest(
                .DELETE,
                API.Posts.delete(id: post.id).fullPath,
                headers: context.authorized(amina.accessToken)
            )
            #expect(deleted.status == .noContent)
            let missing = try await context.get(API.Posts.detail(id: post.id).fullPath, token: amina.accessToken)
            #expect(missing.status == .notFound)
        }
    }
}
