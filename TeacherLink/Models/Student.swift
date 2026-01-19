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
    var avatarStyle: AvatarStyle
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

    init(
        id: String? = nil,
        firstName: String,
        lastName: String,
        classId: String,
        parentIds: [String] = [],
        avatarStyle: AvatarStyle = AvatarStyle.random(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.classId = classId
        self.parentIds = parentIds
        self.avatarStyle = avatarStyle
        self.createdAt = createdAt
    }
}

struct AvatarStyle: Codable, Hashable {
    var backgroundColor: String
    var characterType: String
    var accessory: String?

    static let backgroundColors = [
        "avatarBlue", "avatarGreen", "avatarPurple", "avatarOrange",
        "avatarPink", "avatarTeal", "avatarYellow", "avatarRed"
    ]

    static let characterTypes = [
        "monster1", "monster2", "monster3", "monster4",
        "monster5", "monster6", "monster7", "monster8"
    ]

    static let accessories = [
        nil, "glasses", "hat", "bowtie", "crown", "headband"
    ]

    static func random() -> AvatarStyle {
        AvatarStyle(
            backgroundColor: backgroundColors.randomElement()!,
            characterType: characterTypes.randomElement()!,
            accessory: accessories.randomElement() ?? nil
        )
    }
}
