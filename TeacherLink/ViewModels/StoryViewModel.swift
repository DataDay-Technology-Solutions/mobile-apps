//
//  StoryViewModel.swift
//  TeacherLink
//

import Foundation
import SwiftUI
import PhotosUI

@MainActor
class StoryViewModel: ObservableObject {
    @Published var stories: [Story] = []
    @Published var comments: [StoryComment] = []
    @Published var isLoading = false
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var errorMessage: String?

    init() {
        if USE_MOCK_DATA {
            stories = MockDataService.shared.stories
        }
    }

    func listenToStories(classId: String) {
        if USE_MOCK_DATA {
            stories = MockDataService.shared.stories
        }
    }

    func loadStories(classId: String) async {
        isLoading = true
        errorMessage = nil

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 300_000_000)
            stories = MockDataService.shared.stories
        }

        isLoading = false
    }

    func createTextStory(
        classId: String,
        authorId: String,
        authorName: String,
        content: String,
        isAnnouncement: Bool = false
    ) async {
        isLoading = true
        errorMessage = nil

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 300_000_000)

            let story = Story(
                id: UUID().uuidString,
                classId: classId,
                authorId: authorId,
                authorName: authorName,
                type: isAnnouncement ? .announcement : .text,
                content: content,
                isAnnouncement: isAnnouncement,
                createdAt: Date()
            )
            stories.insert(story, at: 0)
        }

        isLoading = false
    }

    func createPhotoStory(
        classId: String,
        authorId: String,
        authorName: String,
        content: String,
        imageData: Data
    ) async {
        isUploading = true
        errorMessage = nil
        uploadProgress = 0

        if USE_MOCK_DATA {
            // Simulate upload progress
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                uploadProgress = Double(i) / 10.0
            }

            let story = Story(
                id: UUID().uuidString,
                classId: classId,
                authorId: authorId,
                authorName: authorName,
                type: .photo,
                content: content,
                mediaURLs: ["mock://photo"],
                createdAt: Date()
            )
            stories.insert(story, at: 0)
        }

        isUploading = false
    }

    func createVideoStory(
        classId: String,
        authorId: String,
        authorName: String,
        content: String,
        videoURL: URL
    ) async {
        isUploading = true
        errorMessage = nil
        uploadProgress = 0

        if USE_MOCK_DATA {
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 150_000_000)
                uploadProgress = Double(i) / 10.0
            }

            let story = Story(
                id: UUID().uuidString,
                classId: classId,
                authorId: authorId,
                authorName: authorName,
                type: .video,
                content: content,
                mediaURLs: ["mock://video"],
                createdAt: Date()
            )
            stories.insert(story, at: 0)
        }

        isUploading = false
    }

    func toggleLike(story: Story, userId: String) async {
        guard let storyId = story.id,
              let index = stories.firstIndex(where: { $0.id == storyId }) else { return }

        if USE_MOCK_DATA {
            var updatedStory = stories[index]
            if updatedStory.likedByIds.contains(userId) {
                updatedStory.likedByIds.removeAll { $0 == userId }
                updatedStory.likeCount = max(0, updatedStory.likeCount - 1)
            } else {
                updatedStory.likedByIds.append(userId)
                updatedStory.likeCount += 1
            }
            stories[index] = updatedStory
        }
    }

    func deleteStory(_ story: Story) async {
        guard let storyId = story.id else { return }

        if USE_MOCK_DATA {
            stories.removeAll { $0.id == storyId }
        }
    }

    // MARK: - Comments

    func listenToComments(storyId: String) {
        if USE_MOCK_DATA {
            // Generate some mock comments
            comments = [
                StoryComment(id: "c1", storyId: storyId, authorId: "parent1", authorName: "Sarah Smith", content: "This is wonderful! Emma loved it!", createdAt: Date().addingTimeInterval(-1800)),
                StoryComment(id: "c2", storyId: storyId, authorId: "parent2", authorName: "John Brown", content: "Thank you for sharing!", createdAt: Date().addingTimeInterval(-3600))
            ]
        }
    }

    func loadComments(storyId: String) async {
        if USE_MOCK_DATA {
            listenToComments(storyId: storyId)
        }
    }

    func addComment(storyId: String, authorId: String, authorName: String, content: String) async {
        if USE_MOCK_DATA {
            let comment = StoryComment(
                id: UUID().uuidString,
                storyId: storyId,
                authorId: authorId,
                authorName: authorName,
                content: content,
                createdAt: Date()
            )
            comments.append(comment)

            // Update comment count on story
            if let index = stories.firstIndex(where: { $0.id == storyId }) {
                stories[index].commentCount += 1
            }
        }
    }

    func deleteComment(storyId: String, commentId: String) async {
        if USE_MOCK_DATA {
            comments.removeAll { $0.id == commentId }

            if let index = stories.firstIndex(where: { $0.id == storyId }) {
                stories[index].commentCount = max(0, stories[index].commentCount - 1)
            }
        }
    }
}
