//
//  StoryService.swift
//  TeacherLink
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

class StoryService {
    static let shared = StoryService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private init() {}

    // MARK: - Story CRUD

    func createStory(_ story: Story) async throws -> Story {
        let docRef = db.collection("stories").document()
        var newStory = story
        newStory.id = docRef.documentID

        try docRef.setData(from: newStory)
        return newStory
    }

    func getStoriesForClass(classId: String, limit: Int = 20) async throws -> [Story] {
        let snapshot = try await db.collection("stories")
            .whereField("classId", isEqualTo: classId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Story.self) }
    }

    func getStory(id: String) async throws -> Story {
        let document = try await db.collection("stories").document(id).getDocument()
        guard let story = try? document.data(as: Story.self) else {
            throw StoryError.notFound
        }
        return story
    }

    func updateStory(_ story: Story) async throws {
        guard let storyId = story.id else { return }
        var updatedStory = story
        updatedStory.updatedAt = Date()
        try db.collection("stories").document(storyId).setData(from: updatedStory, merge: true)
    }

    func deleteStory(id: String) async throws {
        // Delete associated media files
        let story = try await getStory(id: id)
        for url in story.mediaURLs {
            try? await deleteMedia(url: url)
        }
        try await db.collection("stories").document(id).delete()
    }

    // MARK: - Likes

    func toggleLike(storyId: String, userId: String) async throws {
        let storyRef = db.collection("stories").document(storyId)

        try await db.runTransaction { transaction, _ in
            guard let document = try? transaction.getDocument(storyRef),
                  var story = try? document.data(as: Story.self) else {
                return nil
            }

            if story.likedByIds.contains(userId) {
                story.likedByIds.removeAll { $0 == userId }
                story.likeCount = max(0, story.likeCount - 1)
            } else {
                story.likedByIds.append(userId)
                story.likeCount += 1
            }

            try? transaction.setData(from: story, forDocument: storyRef)
            return nil
        }
    }

    // MARK: - Comments

    func addComment(_ comment: StoryComment) async throws -> StoryComment {
        let docRef = db.collection("stories").document(comment.storyId)
            .collection("comments").document()

        var newComment = comment
        newComment.id = docRef.documentID

        try docRef.setData(from: newComment)

        try await db.collection("stories").document(comment.storyId).updateData([
            "commentCount": FieldValue.increment(Int64(1))
        ])

        return newComment
    }

    func getComments(storyId: String) async throws -> [StoryComment] {
        let snapshot = try await db.collection("stories").document(storyId)
            .collection("comments")
            .order(by: "createdAt", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: StoryComment.self) }
    }

    func deleteComment(storyId: String, commentId: String) async throws {
        try await db.collection("stories").document(storyId)
            .collection("comments").document(commentId).delete()

        try await db.collection("stories").document(storyId).updateData([
            "commentCount": FieldValue.increment(Int64(-1))
        ])
    }

    // MARK: - Media Upload

    func uploadImage(_ imageData: Data, storyId: String) async throws -> String {
        let filename = "\(UUID().uuidString).jpg"
        let path = "stories/\(storyId)/\(filename)"
        let storageRef = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let url = try await storageRef.downloadURL()
        return url.absoluteString
    }

    func uploadVideo(_ videoURL: URL, storyId: String) async throws -> String {
        let filename = "\(UUID().uuidString).mp4"
        let path = "stories/\(storyId)/\(filename)"
        let storageRef = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"

        _ = try await storageRef.putFileAsync(from: videoURL, metadata: metadata)
        let url = try await storageRef.downloadURL()
        return url.absoluteString
    }

    private func deleteMedia(url: String) async throws {
        let storageRef = storage.reference(forURL: url)
        try await storageRef.delete()
    }

    // MARK: - Real-time Listeners

    func listenToStories(classId: String, completion: @escaping ([Story]) -> Void) -> ListenerRegistration {
        return db.collection("stories")
            .whereField("classId", isEqualTo: classId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                let stories = snapshot?.documents.compactMap { try? $0.data(as: Story.self) } ?? []
                completion(stories)
            }
    }

    func listenToComments(storyId: String, completion: @escaping ([StoryComment]) -> Void) -> ListenerRegistration {
        return db.collection("stories").document(storyId)
            .collection("comments")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, _ in
                let comments = snapshot?.documents.compactMap { try? $0.data(as: StoryComment.self) } ?? []
                completion(comments)
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
