//
//  User.swift
//  TeacherLink
//

import Foundation

enum UserRole: String, Codable {
    case teacher
    case parent
}

struct User: Identifiable, Codable {
    var id: String?
    var email: String
    var displayName: String
    var role: UserRole
    var avatarURL: String?
    var classIds: [String]
    var createdAt: Date
    var fcmToken: String?

    var initials: String {
        let names = displayName.split(separator: " ")
        if names.count >= 2 {
            return String(names[0].prefix(1) + names[1].prefix(1)).uppercased()
        }
        return String(displayName.prefix(2)).uppercased()
    }

    init(
        id: String? = nil,
        email: String,
        displayName: String,
        role: UserRole,
        avatarURL: String? = nil,
        classIds: [String] = [],
        createdAt: Date = Date(),
        fcmToken: String? = nil
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.role = role
        self.avatarURL = avatarURL
        self.classIds = classIds
        self.createdAt = createdAt
        self.fcmToken = fcmToken
    }
}
