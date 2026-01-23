//
//  StoryService.swift
//  HallPass (formerly TeacherLink)
//

import Foundation
import Supabase

class StoryService {
    static let shared = StoryService()
    private let supabase = SupabaseConfig.client

    private init() {}

    // MARK: - Story CRUD

    func createStory(_ story: Story) async throws -> Story {
        let response: [Story] = try await supabase
            .from("stories")
            .insert(story)
            .select()
            .execute()
            .value

        guard let newStory = response.first else {
            throw StoryError.uploadFailed
        }
        return newStory
    }

    func getStoriesForClass(classId: String, limit: Int = 20) async throws -> [Story] {
        let response: [Story] = try await supabase
            .from("stories")
            .select()
            .eq("class_id", value: classId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return response
    }

    func getStory(id: String) async throws -> Story {
        let story: Story = try await supabase
            .from("stories")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value

        return story
    }

    func updateStory(_ story: Story) async throws {
        guard let storyId = story.id else { return }
        var updatedStory = story
        updatedStory.updatedAt = Date()

        try await supabase
            .from("stories")
            .update(updatedStory)
            .eq("id", value: storyId)
            .execute()
    }

    func deleteStory(id: String) async throws {
        // Delete associated media files
        let story = try await getStory(id: id)
        for url in story.mediaURLs {
            try? await deleteMedia(url: url)
        }

        try await supabase
            .from("stories")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Likes

    func toggleLike(storyId: String, userId: String) async throws {
        var story = try await getStory(id: storyId)

        if story.likedByIds.contains(userId) {
            story.likedByIds.removeAll { $0 == userId }
            story.likeCount = max(0, story.likeCount - 1)
        } else {
            story.likedByIds.append(userId)
            story.likeCount += 1
        }

        try await supabase
            .from("stories")
            .update([
                "liked_by_ids": AnyJSON.array(story.likedByIds.map { .string($0) }),
                "like_count": AnyJSON.integer(story.likeCount)
            ])
            .eq("id", value: storyId)
            .execute()
    }

    // MARK: - Comments

    func addComment(_ comment: StoryComment) async throws -> StoryComment {
        let response: [StoryComment] = try await supabase
            .from("story_comments")
            .insert(comment)
            .select()
            .execute()
            .value

        guard let newComment = response.first else {
            throw StoryError.uploadFailed
        }

        // Update comment count
        try await supabase.rpc("increment_comment_count", params: ["story_id": comment.storyId]).execute()

        return newComment
    }

    func getComments(storyId: String) async throws -> [StoryComment] {
        let response: [StoryComment] = try await supabase
            .from("story_comments")
            .select()
            .eq("story_id", value: storyId)
            .order("created_at", ascending: true)
            .execute()
            .value

        return response
    }

    func deleteComment(storyId: String, commentId: String) async throws {
        try await supabase
            .from("story_comments")
            .delete()
            .eq("id", value: commentId)
            .execute()

        // Decrement comment count
        try await supabase.rpc("decrement_comment_count", params: ["story_id": storyId]).execute()
    }

    // MARK: - Media Upload (using Supabase Storage)

    func uploadImage(_ imageData: Data, storyId: String) async throws -> String {
        let filename = "\(UUID().uuidString).jpg"
        let path = "stories/\(storyId)/\(filename)"

        try await supabase.storage
            .from("media")
            .upload(path: path, file: imageData, options: FileOptions(contentType: "image/jpeg"))

        let publicURL = try supabase.storage
            .from("media")
            .getPublicURL(path: path)

        return publicURL.absoluteString
    }

    func uploadVideo(_ videoURL: URL, storyId: String) async throws -> String {
        let filename = "\(UUID().uuidString).mp4"
        let path = "stories/\(storyId)/\(filename)"
        let videoData = try Data(contentsOf: videoURL)

        try await supabase.storage
            .from("media")
            .upload(path: path, file: videoData, options: FileOptions(contentType: "video/mp4"))

        let publicURL = try supabase.storage
            .from("media")
            .getPublicURL(path: path)

        return publicURL.absoluteString
    }

    private func deleteMedia(url: String) async throws {
        // Extract path from URL
        guard let urlComponents = URLComponents(string: url),
              let path = urlComponents.path.components(separatedBy: "/media/").last else {
            return
        }

        try await supabase.storage
            .from("media")
            .remove(paths: [path])
    }

    // MARK: - Real-time Listeners

    private var storiesChannel: RealtimeChannelV2?
    private var commentsChannel: RealtimeChannelV2?

    func listenToStories(classId: String, completion: @escaping ([Story]) -> Void) {
        // Initial fetch
        Task {
            let stories = try? await getStoriesForClass(classId: classId)
            await MainActor.run {
                completion(stories ?? [])
            }
        }

        // Set up realtime subscription
        storiesChannel = supabase.realtimeV2.channel("stories_\(classId)")

        Task {
            await storiesChannel?.subscribe()

            let changes = storiesChannel?.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "stories",
                filter: "class_id=eq.\(classId)"
            )

            if let changes = changes {
                for await _ in changes {
                    let stories = try? await getStoriesForClass(classId: classId)
                    await MainActor.run {
                        completion(stories ?? [])
                    }
                }
            }
        }
    }

    func listenToComments(storyId: String, completion: @escaping ([StoryComment]) -> Void) {
        // Initial fetch
        Task {
            let comments = try? await getComments(storyId: storyId)
            await MainActor.run {
                completion(comments ?? [])
            }
        }

        // Set up realtime subscription
        commentsChannel = supabase.realtimeV2.channel("comments_\(storyId)")

        Task {
            await commentsChannel?.subscribe()

            let changes = commentsChannel?.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "story_comments",
                filter: "story_id=eq.\(storyId)"
            )

            if let changes = changes {
                for await _ in changes {
                    let comments = try? await getComments(storyId: storyId)
                    await MainActor.run {
                        completion(comments ?? [])
                    }
                }
            }
        }
    }

    func stopListening() {
        Task {
            await storiesChannel?.unsubscribe()
            await commentsChannel?.unsubscribe()
        }
    }
}

enum StoryError: LocalizedError {
    case notFound
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Story not found"
        case .uploadFailed:
            return "Failed to upload media"
        }
    }
}
