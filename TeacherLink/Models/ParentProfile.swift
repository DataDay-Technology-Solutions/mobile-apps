//
//  ParentProfile.swift
//  TeacherLink
//
//  Parent profile with manual flagging for admin support
//

import Foundation

struct ParentProfile: Identifiable, Codable {
    var id: String?
    var userId: String
    var classId: String
    var studentIds: [String]

    // Manual flag status (teacher-controlled only)
    var isFlagged: Bool
    var flaggedByTeacherId: String?
    var flaggedAt: Date?
    var flagReason: String?

    // Admin CC status (only enabled when manually flagged)
    var adminCCEnabled: Bool

    var createdAt: Date
    var updatedAt: Date?

    init(
        id: String? = nil,
        userId: String,
        classId: String,
        studentIds: [String] = [],
        isFlagged: Bool = false,
        flaggedByTeacherId: String? = nil,
        flaggedAt: Date? = nil,
        flagReason: String? = nil,
        adminCCEnabled: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.classId = classId
        self.studentIds = studentIds
        self.isFlagged = isFlagged
        self.flaggedByTeacherId = flaggedByTeacherId
        self.flaggedAt = flaggedAt
        self.flagReason = flagReason
        self.adminCCEnabled = adminCCEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Flag parent and enable admin CC
    mutating func flag(byTeacherId: String, reason: String) {
        isFlagged = true
        flaggedByTeacherId = byTeacherId
        flaggedAt = Date()
        flagReason = reason
        adminCCEnabled = true
        updatedAt = Date()
    }

    // Remove flag and disable admin CC
    mutating func unflag() {
        isFlagged = false
        flaggedByTeacherId = nil
        flaggedAt = nil
        flagReason = nil
        adminCCEnabled = false
        updatedAt = Date()
    }
}

// User credentials for mock authentication
struct MockUserCredentials {
    let email: String
    let password: String
    let userId: String
    let role: UserRole
}
