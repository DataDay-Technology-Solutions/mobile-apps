//
//  Points.swift
//  TeacherLink
//
//  Behavior points system like ClassDojo
//

import Foundation

// Predefined behaviors that teachers can award/deduct
struct Behavior: Identifiable, Codable {
    var id: String
    var name: String
    var points: Int  // Positive for good, negative for needs work
    var icon: String
    var color: String
    var isPositive: Bool

    static let defaultPositive: [Behavior] = [
        Behavior(id: "helping", name: "Helping Others", points: 1, icon: "hand.raised.fill", color: "green", isPositive: true),
        Behavior(id: "teamwork", name: "Teamwork", points: 1, icon: "person.3.fill", color: "blue", isPositive: true),
        Behavior(id: "hardWork", name: "Hard Work", points: 1, icon: "star.fill", color: "yellow", isPositive: true),
        Behavior(id: "participation", name: "Participation", points: 1, icon: "hand.point.up.fill", color: "purple", isPositive: true),
        Behavior(id: "kindness", name: "Kindness", points: 1, icon: "heart.fill", color: "pink", isPositive: true),
        Behavior(id: "onTask", name: "On Task", points: 1, icon: "checkmark.circle.fill", color: "teal", isPositive: true),
        Behavior(id: "listening", name: "Good Listening", points: 1, icon: "ear.fill", color: "orange", isPositive: true),
        Behavior(id: "creativity", name: "Creativity", points: 1, icon: "paintbrush.fill", color: "indigo", isPositive: true)
    ]

    static let defaultNegative: [Behavior] = [
        Behavior(id: "offTask", name: "Off Task", points: -1, icon: "xmark.circle.fill", color: "red", isPositive: false),
        Behavior(id: "talking", name: "Talking Out", points: -1, icon: "speaker.wave.2.fill", color: "orange", isPositive: false),
        Behavior(id: "notListening", name: "Not Listening", points: -1, icon: "ear.trianglebadge.exclamationmark", color: "yellow", isPositive: false),
        Behavior(id: "unkind", name: "Unkind", points: -1, icon: "heart.slash.fill", color: "red", isPositive: false),
        Behavior(id: "unprepared", name: "Unprepared", points: -1, icon: "exclamationmark.triangle.fill", color: "orange", isPositive: false),
        Behavior(id: "noHomework", name: "Missing Homework", points: -1, icon: "doc.fill", color: "gray", isPositive: false)
    ]
}

// Individual point award/deduction record
struct PointRecord: Identifiable, Codable {
    var id: String?
    var studentId: String
    var classId: String
    var behaviorId: String
    var behaviorName: String
    var points: Int
    var note: String?
    var awardedBy: String
    var awardedByName: String
    var createdAt: Date

    var isPositive: Bool {
        points > 0
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    init(
        id: String? = nil,
        studentId: String,
        classId: String,
        behaviorId: String,
        behaviorName: String,
        points: Int,
        note: String? = nil,
        awardedBy: String,
        awardedByName: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.studentId = studentId
        self.classId = classId
        self.behaviorId = behaviorId
        self.behaviorName = behaviorName
        self.points = points
        self.note = note
        self.awardedBy = awardedBy
        self.awardedByName = awardedByName
        self.createdAt = createdAt
    }
}

// Student's aggregated points summary
struct StudentPointsSummary: Identifiable, Codable {
    var id: String  // Same as studentId
    var studentId: String
    var classId: String
    var totalPoints: Int
    var positiveCount: Int
    var negativeCount: Int
    var lastUpdated: Date

    init(
        studentId: String,
        classId: String,
        totalPoints: Int = 0,
        positiveCount: Int = 0,
        negativeCount: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.id = studentId
        self.studentId = studentId
        self.classId = classId
        self.totalPoints = totalPoints
        self.positiveCount = positiveCount
        self.negativeCount = negativeCount
        self.lastUpdated = lastUpdated
    }
}
