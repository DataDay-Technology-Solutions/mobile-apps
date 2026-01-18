//
//  Classroom.swift
//  TeacherLink
//

import Foundation

struct Classroom: Identifiable, Codable {
    var id: String?
    var name: String
    var gradeLevel: String
    var teacherId: String
    var teacherName: String
    var classCode: String
    var studentIds: [String]
    var parentIds: [String]
    var createdAt: Date
    var schoolYear: String
    var avatarColor: String

    var studentCount: Int {
        studentIds.count
    }

    var parentCount: Int {
        parentIds.count
    }

    init(
        id: String? = nil,
        name: String,
        gradeLevel: String,
        teacherId: String,
        teacherName: String,
        classCode: String = "",
        studentIds: [String] = [],
        parentIds: [String] = [],
        createdAt: Date = Date(),
        schoolYear: String = "",
        avatarColor: String = "blue"
    ) {
        self.id = id
        self.name = name
        self.gradeLevel = gradeLevel
        self.teacherId = teacherId
        self.teacherName = teacherName
        self.classCode = classCode.isEmpty ? Classroom.generateClassCode() : classCode
        self.studentIds = studentIds
        self.parentIds = parentIds
        self.createdAt = createdAt
        self.schoolYear = schoolYear.isEmpty ? Classroom.currentSchoolYear() : schoolYear
        self.avatarColor = avatarColor
    }

    static func generateClassCode() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ"
        let numbers = "23456789"
        var code = ""
        for _ in 0..<3 {
            code += String(letters.randomElement()!)
        }
        for _ in 0..<3 {
            code += String(numbers.randomElement()!)
        }
        return code
    }

    static func currentSchoolYear() -> String {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        if month >= 8 {
            return "\(year)-\(year + 1)"
        } else {
            return "\(year - 1)-\(year)"
        }
    }
}
