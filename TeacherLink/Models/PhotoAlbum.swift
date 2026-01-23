//
//  PhotoAlbum.swift
//  TeacherLink
//
//  Photo albums for organizing classroom memories (PhotoCircle-style)
//

import Foundation

struct PhotoAlbum: Identifiable, Codable {
    var id: String?
    var classId: String
    var name: String
    var description: String
    var coverPhotoURL: String?
    var photoCount: Int
    var createdBy: String
    var createdByName: String
    var isSharedWithParents: Bool
    var allowParentContributions: Bool
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
        name: String,
        description: String = "",
        coverPhotoURL: String? = nil,
        photoCount: Int = 0,
        createdBy: String,
        createdByName: String,
        isSharedWithParents: Bool = true,
        allowParentContributions: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.classId = classId
        self.name = name
        self.description = description
        self.coverPhotoURL = coverPhotoURL
        self.photoCount = photoCount
        self.createdBy = createdBy
        self.createdByName = createdByName
        self.isSharedWithParents = isSharedWithParents
        self.allowParentContributions = allowParentContributions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct AlbumPhoto: Identifiable, Codable {
    var id: String?
    var albumId: String
    var imageURL: String
    var thumbnailURL: String?
    var caption: String?
    var uploadedBy: String
    var uploadedByName: String
    var likeCount: Int
    var likedByIds: [String]
    var commentCount: Int
    var createdAt: Date

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    init(
        id: String? = nil,
        albumId: String,
        imageURL: String,
        thumbnailURL: String? = nil,
        caption: String? = nil,
        uploadedBy: String,
        uploadedByName: String,
        likeCount: Int = 0,
        likedByIds: [String] = [],
        commentCount: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.albumId = albumId
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
        self.caption = caption
        self.uploadedBy = uploadedBy
        self.uploadedByName = uploadedByName
        self.likeCount = likeCount
        self.likedByIds = likedByIds
        self.commentCount = commentCount
        self.createdAt = createdAt
    }
}

struct PhotoComment: Identifiable, Codable {
    var id: String?
    var photoId: String
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
        photoId: String,
        authorId: String,
        authorName: String,
        content: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.photoId = photoId
        self.authorId = authorId
        self.authorName = authorName
        self.content = content
        self.createdAt = createdAt
    }
}

// Reaction types for photos and stories
enum ReactionType: String, Codable, CaseIterable {
    case love = "love"
    case celebrate = "celebrate"
    case support = "support"
    case laugh = "laugh"
    case wow = "wow"

    var emoji: String {
        switch self {
        case .love: return "❤️"
        case .celebrate: return "🎉"
        case .support: return "👏"
        case .laugh: return "😄"
        case .wow: return "😮"
        }
    }

    var label: String {
        switch self {
        case .love: return "Love"
        case .celebrate: return "Celebrate"
        case .support: return "Support"
        case .laugh: return "Laugh"
        case .wow: return "Wow"
        }
    }
}
