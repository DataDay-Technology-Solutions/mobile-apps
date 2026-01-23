//
//  User.swift
//  HallPass (formerly TeacherLink)
//

import Foundation

// MARK: - UserRole Enum
enum UserRole: String, Codable, CaseIterable {
    case admin = "admin"
    case teacher = "teacher"
    case parent = "parent"
    case student = "student"
}

// MARK: - AdminLevel Enum
enum AdminLevel: String, Codable, CaseIterable {
    case superAdmin = "super_admin"
    case districtAdmin = "district_admin"
    case principal = "principal"
    case schoolAdmin = "school_admin"
    case none = "none"
}

// MARK: - User Model
struct User: Identifiable, Codable {
    var id: String?
    var email: String
    var name: String
    var displayName: String?
    var role: UserRole
    var adminLevel: AdminLevel?
    var districtId: String?
    var schoolId: String?
    var classroomId: String?
    var classIds: [String]
    var studentIds: [String]
    var parentId: String?
    var fcmToken: String?
    var createdAt: Date

    var initials: String {
        let nameToUse = displayName ?? name
        let names = nameToUse.split(separator: " ")
        if names.count >= 2 {
            return String(names[0].prefix(1) + names[1].prefix(1)).uppercased()
        }
        return String(nameToUse.prefix(2)).uppercased()
    }

    // CodingKeys for proper Supabase snake_case mapping
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case displayName = "display_name"
        case role
        case adminLevel = "admin_level"
        case districtId = "district_id"
        case schoolId = "school_id"
        case classroomId = "classroom_id"
        case classIds = "class_ids"
        case studentIds = "student_ids"
        case parentId = "parent_id"
        case fcmToken = "fcm_token"
        case createdAt = "created_at"
    }

    init(
        id: String? = nil,
        email: String,
        name: String,
        displayName: String? = nil,
        role: UserRole,
        adminLevel: AdminLevel? = nil,
        districtId: String? = nil,
        schoolId: String? = nil,
        classroomId: String? = nil,
        classIds: [String] = [],
        studentIds: [String] = [],
        parentId: String? = nil,
        fcmToken: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.displayName = displayName
        self.role = role
        self.adminLevel = adminLevel
        self.districtId = districtId
        self.schoolId = schoolId
        self.classroomId = classroomId
        self.classIds = classIds
        self.studentIds = studentIds
        self.parentId = parentId
        self.fcmToken = fcmToken
        self.createdAt = createdAt
    }
}
