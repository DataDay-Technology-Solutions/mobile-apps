//
//  Student.swift
//  TeacherLink
//

import Foundation

struct Student: Identifiable, Codable, Hashable {
    var id: String?
    var firstName: String
    var lastName: String
    var name: String  // Required by database - full name
    var classId: String
    var classroomId: String?  // Legacy field
    var parentIds: [String]
    var parentId: String?  // Legacy field - first parent
    var createdAt: Date

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var initials: String {
        String(firstName.prefix(1) + lastName.prefix(1)).uppercased()
    }

    // CodingKeys for proper Supabase snake_case mapping
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case name
        case classId = "class_id"
        case classroomId = "classroom_id"
        case parentIds = "parent_ids"
        case parentId = "parent_id"
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
        self.name = "\(firstName) \(lastName)"  // Auto-populate name
        self.classId = classId
        self.classroomId = classId  // Copy to legacy field
        self.parentIds = parentIds
        self.parentId = parentIds.first  // Copy first parent to legacy field
        self.createdAt = createdAt
    }
}
