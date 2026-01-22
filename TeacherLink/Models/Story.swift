//
//  Story.swift
//  TeacherLink
//

import Foundation

struct Story: Identifiable, Codable {
    var id: String?
    var classId: String
    var authorId: String
    var authorName: String
    var content: String?
    var mediaUrls: [String]
    var mediaType: String?  // "image", "video", "text"
    var likeCount: Int
    var likedByIds: [String]
    var commentCount: Int
    var createdAt: Date
    var updatedAt: Date

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    // CodingKeys for proper Supabase snake_case mapping
    enum CodingKeys: String, CodingKey {
        case id
        case classId = "class_id"
        case authorId = "author_id"
        case authorName = "author_name"
        case content
        case mediaUrls = "media_urls"
        case mediaType = "media_type"
        case likeCount = "like_count"
        case likedByIds = "liked_by_ids"
        case commentCount = "comment_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: String? = nil,
        classId: String,
        authorId: String,
        authorName: String,
        content: String? = nil,
        mediaUrls: [String] = [],
        mediaType: String? = nil,
        likeCount: Int = 0,
        likedByIds: [String] = [],
        commentCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.classId = classId
        self.authorId = authorId
        self.authorName = authorName
        self.content = content
        self.mediaUrls = mediaUrls
        self.mediaType = mediaType
        self.likeCount = likeCount
        self.likedByIds = likedByIds
        self.commentCount = commentCount
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

    // CodingKeys for proper Supabase snake_case mapping
    enum CodingKeys: String, CodingKey {
        case id
        case storyId = "story_id"
        case authorId = "author_id"
        case authorName = "author_name"
        case content
        case createdAt = "created_at"
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
