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
    var adminLevel: AdminLevel?
    var districtId: String?
    var schoolId: String?
    var classroomId: String?
    var classIds: [String]
    var studentIds: [String]
    var fcmToken: String?

    init(
        id: String,
        email: String,
        name: String,
        role: UserRole,
        adminLevel: AdminLevel? = nil,
        districtId: String? = nil,
        schoolId: String? = nil,
        classroomId: String? = nil,
        classIds: [String] = [],
        studentIds: [String] = [],
        fcmToken: String? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.role = role
        self.adminLevel = adminLevel
        self.districtId = districtId
        self.schoolId = schoolId
        self.classroomId = classroomId
        self.classIds = classIds
        self.studentIds = studentIds
        self.fcmToken = fcmToken
    }

    // Check if user is a super admin
    var isSuperAdmin: Bool {
        adminLevel == .superAdmin
    }

    // Check if user is a district admin
    var isDistrictAdmin: Bool {
        adminLevel == .districtAdmin
    }

    // Check if user is a principal
    var isPrincipal: Bool {
        adminLevel == .principal
    }

    // Check if user is a school admin
    var isSchoolAdmin: Bool {
        adminLevel == .schoolAdmin
    }

    // Check if user has any admin privileges
    var hasAdminAccess: Bool {
        role == .admin || (adminLevel != nil && adminLevel != .none)
    }
}

// MARK: - DatabaseUser (Database model for Supabase)
struct DatabaseUser: Codable {
    let id: String
    let email: String
    let name: String
    let displayName: String?
    let role: String
    let adminLevel: String?
    let districtId: String?
    let schoolId: String?
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

    init(from appUser: AppUser) {
        self.id = appUser.id
        self.email = appUser.email
        self.name = appUser.name
        self.displayName = appUser.name
        self.role = appUser.role.rawValue
        self.adminLevel = appUser.adminLevel?.rawValue
        self.districtId = appUser.districtId
        self.schoolId = appUser.schoolId
        self.classroomId = appUser.classroomId
        self.classIds = appUser.classIds
        self.studentIds = appUser.studentIds
        self.parentId = nil
        self.fcmToken = appUser.fcmToken
        self.createdAt = Date()
    }

    func toAppUser() -> AppUser {
        var level: AdminLevel? = nil
        if let adminLevelStr = adminLevel {
            level = AdminLevel(rawValue: adminLevelStr)
        }

        return AppUser(
            id: id,
            email: email,
            name: name,
            role: UserRole(rawValue: role) ?? .parent,
            adminLevel: level,
            districtId: districtId,
            schoolId: schoolId,
            classroomId: classroomId,
            classIds: classIds,
            studentIds: studentIds,
            fcmToken: fcmToken
        )
    }
}
