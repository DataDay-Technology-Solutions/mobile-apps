//
//  AppUser.swift
//  HallPass (formerly TeacherLink)
//
//  User models for Supabase integration
//

import Foundation

// MARK: - AppUser (App-level user model)
struct AppUser: Identifiable, Codable {
    let id: String
    let email: String
    let name: String
    let role: UserRole
    var classroomId: String?
    var classIds: [String]
    var studentIds: [String]
    var fcmToken: String?

    init(
        id: String,
        email: String,
        name: String,
        role: UserRole,
        classroomId: String? = nil,
        classIds: [String] = [],
        studentIds: [String] = [],
        fcmToken: String? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.role = role
        self.classroomId = classroomId
        self.classIds = classIds
        self.studentIds = studentIds
        self.fcmToken = fcmToken
    }
}

// MARK: - DatabaseUser (Database model for Supabase)
struct DatabaseUser: Codable {
    let id: String
    let email: String
    let name: String
    let displayName: String?
    let role: String
    let classroomId: String?
    let classIds: [String]
    let studentIds: [String]
    let parentId: String?
    let fcmToken: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case displayName = "display_name"
        case role
        case classroomId = "classroom_id"
        case classIds = "class_ids"
        case studentIds = "student_ids"
        case parentId = "parent_id"
        case fcmToken = "fcm_token"
        case createdAt = "created_at"
    }

    init(from appUser: AppUser) {
        self.id = appUser.id
        self.email = appUser.email
        self.name = appUser.name
        self.displayName = appUser.name
        self.role = appUser.role.rawValue
        self.classroomId = appUser.classroomId
        self.classIds = appUser.classIds
        self.studentIds = appUser.studentIds
        self.parentId = nil
        self.fcmToken = appUser.fcmToken
        self.createdAt = Date()
    }

    func toAppUser() -> AppUser {
        AppUser(
            id: id,
            email: email,
            name: name,
            role: UserRole(rawValue: role) ?? .parent,
            classroomId: classroomId,
            classIds: classIds,
            studentIds: studentIds,
            fcmToken: fcmToken
        )
    }
}
