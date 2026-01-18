//
//  Story.swift
//  TeacherLink
//

import Foundation

enum StoryType: String, Codable {
    case text
    case photo
    case video
    case announcement
}

struct Story: Identifiable, Codable {
    var id: String?
    var classId: String
    var authorId: String
    var authorName: String
    var type: StoryType
    var content: String
    var mediaURLs: [String]
    var thumbnailURL: String?
    var likeCount: Int
    var likedByIds: [String]
    var commentCount: Int
    var isAnnouncement: Bool
    var isPinned: Bool
    var createdAt: Date
    var updatedAt: Date?

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    init(
        id: String? = nil,
        classId: String,
        authorId: String,
        authorName: String,
        type: StoryType = .text,
        content: String,
        mediaURLs: [String] = [],
        thumbnailURL: String? = nil,
        likeCount: Int = 0,
        likedByIds: [String] = [],
        commentCount: Int = 0,
        isAnnouncement: Bool = false,
        isPinned: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.classId = classId
        self.authorId = authorId
        self.authorName = authorName
        self.type = type
        self.content = content
        self.mediaURLs = mediaURLs
        self.thumbnailURL = thumbnailURL
        self.likeCount = likeCount
        self.likedByIds = likedByIds
        self.commentCount = commentCount
        self.isAnnouncement = isAnnouncement
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct StoryComment: Identifiable, Codable {
    var id: String?
    var storyId: String
    var authorId: String
    var authorName: String
    var content: String
    var createdAt: Date

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    init(
        id: String? = nil,
        storyId: String,
        authorId: String,
        authorName: String,
        content: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.storyId = storyId
        self.authorId = authorId
        self.authorName = authorName
        self.content = content
        self.createdAt = createdAt
    }
}
