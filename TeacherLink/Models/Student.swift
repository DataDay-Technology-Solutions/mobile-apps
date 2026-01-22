//
//  Student.swift
//  TeacherLink
//

import Foundation

struct Student: Identifiable, Codable, Hashable {
    var id: String?
    var firstName: String
    var lastName: String
    var classId: String
    var parentIds: [String]
    var createdAt: Date

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var initials: String {
        String(firstName.prefix(1) + lastName.prefix(1)).uppercased()
    }

    /// Compatibility property for FirestoreService - returns first parent ID
    var parentId: String? {
        parentIds.first
    }

    /// Compatibility alias for fullName
    var name: String {
        fullName
    }

    /// Compatibility alias for classId
    var classroomId: String {
        classId
    }

    // CodingKeys for proper Supabase snake_case mapping
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case classId = "class_id"
        case parentIds = "parent_ids"
        case createdAt = "created_at"
    }

    init(
        id: String? = nil,
        firstName: String,
        lastName: String,
        classId: String,
        parentIds: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.classId = classId
        self.parentIds = parentIds
        self.createdAt = createdAt
    }
}
