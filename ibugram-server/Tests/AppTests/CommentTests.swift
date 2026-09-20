import Foundation
import IBUgramKit
import Testing
import Vapor
import VaporTesting
@testable import App

@Suite("Comments", .serialized)
struct CommentTests {
    @Test("A comment is created on a post and listed in the thread")
    func createAndList() async throws {
        try await withSocialTestServer { context in
            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina")
            let post = try await context.createPost(token: amina.accessToken, userId: amina.user.id, caption: "talk")

            let created = try await context.app.testing().sendRequest(
                .POST,
                API.Posts.createComment(postId: post.id).fullPath,
                headers: context.authorized(amina.accessToken),
                beforeRequest: { try $0.content.encode(CreateCommentBody(body: "Nice shot @amina.h")) }
            )
            #expect(created.status == .created)
            let comment = try created.content.decode(IBUgramKit.Comment.self)
            #expect(comment.body == "Nice shot @amina.h")
            #expect(comment.postId == post.id)

            let list = try await context.get(API.Posts.comments(id: post.id).fullPath, token: amina.accessToken)
            #expect(try list.content.decode(Paginated<IBUgramKit.Comment>.self).items.map(\.id) == [comment.id])
        }
    }

    @Test("Comment endpoints reject a missing token")
    func commentsRequireAuthentication() async throws {
        try await withSocialTestServer { context in
            let id = UUID()
            let paths: [(HTTPMethod, String)] = [
                (.GET, API.Posts.comments(id: id).fullPath),
                (.POST, API.Posts.createComment(postId: id).fullPath),
                (.DELETE, API.Comments.delete(id: id).fullPath),
                (.POST, API.Comments.like(id: id).fullPath),
                (.DELETE, API.Comments.unlike(id: id).fullPath)
            ]
            for (method, path) in paths {
                let response = try await context.app.testing().sendRequest(method, path)
                #expect(response.status == .unauthorized)
            }
        }
    }

    @Test("Only the author may delete a comment")
    func deleteAuthorisation() async throws {
        try await withSocialTestServer { context in
            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina")
            let emir = try await context.signIn(as: "emir.k@stu.ibu.edu.ba")
            try await context.completeOnboarding(emir, username: "emir.k", displayName: "Emir")
            let post = try await context.createPost(token: amina.accessToken, userId: amina.user.id)

            let created = try await context.app.testing().sendRequest(
                .POST,
                API.Posts.createComment(postId: post.id).fullPath,
                headers: context.authorized(amina.accessToken),
                beforeRequest: { try $0.content.encode(CreateCommentBody(body: "mine")) }
            )
            let comment = try created.content.decode(IBUgramKit.Comment.self)

            let forbidden = try await context.app.testing().sendRequest(
                .DELETE,
                API.Comments.delete(id: comment.id).fullPath,
                headers: context.authorized(emir.accessToken)
            )
            #expect(forbidden.status == .forbidden)

            let deleted = try await context.app.testing().sendRequest(
                .DELETE,
                API.Comments.delete(id: comment.id).fullPath,
                headers: context.authorized(amina.accessToken)
            )
            #expect(deleted.status == .noContent)
        }
    }

    @Test("Comment likes are idempotent")
    func commentLikeIsIdempotent() async throws {
        try await withSocialTestServer { context in
            let amina = try await context.signIn(as: "amina.hodzic@stu.ibu.edu.ba")
            try await context.completeOnboarding(amina, username: "amina.h", displayName: "Amina")
            let post = try await context.createPost(token: amina.accessToken, userId: amina.user.id)
            let created = try await context.app.testing().sendRequest(
                .POST,
                API.Posts.createComment(postId: post.id).fullPath,
                headers: context.authorized(amina.accessToken),
                beforeRequest: { try $0.content.encode(CreateCommentBody(body: "like me")) }
            )
            let comment = try created.content.decode(IBUgramKit.Comment.self)
            let likePath = API.Comments.like(id: comment.id).fullPath
            #expect(try await context.app.testing().sendRequest(.POST, likePath, headers: context.authorized(amina.accessToken)).status == .noContent)
            #expect(try await context.app.testing().sendRequest(.POST, likePath, headers: context.authorized(amina.accessToken)).status == .noContent)

            let list = try await context.get(API.Posts.comments(id: post.id).fullPath, token: amina.accessToken)
            let loaded = try list.content.decode(Paginated<IBUgramKit.Comment>.self).items[0]
            #expect(loaded.likeCount == 1)
            #expect(loaded.viewer?.hasLiked == true)

            #expect(try await context.app.testing().sendRequest(.DELETE, likePath, headers: context.authorized(amina.accessToken)).status == .noContent)
        }
    }
}
