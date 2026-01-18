//
//  MockDataService.swift
//  TeacherLink
//
//  Provides mock data for preview/testing without Firebase
//

import Foundation

class MockDataService {
    static let shared = MockDataService()

    private init() {}

    // MARK: - Mock Users

    let teacherUser = User(
        id: "teacher1",
        email: "teacher@school.com",
        displayName: "Mrs. Johnson",
        role: .teacher,
        classIds: ["class1"],
        createdAt: Date()
    )

    let parentUser = User(
        id: "parent1",
        email: "parent@email.com",
        displayName: "Sarah Smith",
        role: .parent,
        classIds: ["class1"],
        createdAt: Date()
    )

    // MARK: - Mock Classroom

    lazy var classroom = Classroom(
        id: "class1",
        name: "Mrs. Johnson's 1st Grade",
        gradeLevel: "1st Grade",
        teacherId: "teacher1",
        teacherName: "Mrs. Johnson",
        classCode: "ABC123",
        studentIds: students.compactMap { $0.id },
        parentIds: ["parent1", "parent2", "parent3"],
        createdAt: Date().addingTimeInterval(-86400 * 30),
        schoolYear: "2025-2026",
        avatarColor: "blue"
    )

    // MARK: - Mock Students

    let students: [Student] = [
        Student(id: "s1", firstName: "Emma", lastName: "Wilson", classId: "class1", parentIds: ["parent1"], avatarStyle: AvatarStyle(backgroundColor: "avatarPink", characterType: "monster1", accessory: nil)),
        Student(id: "s2", firstName: "Liam", lastName: "Brown", classId: "class1", parentIds: ["parent2"], avatarStyle: AvatarStyle(backgroundColor: "avatarBlue", characterType: "monster2", accessory: "glasses")),
        Student(id: "s3", firstName: "Olivia", lastName: "Davis", classId: "class1", parentIds: [], avatarStyle: AvatarStyle(backgroundColor: "avatarPurple", characterType: "monster3", accessory: nil)),
        Student(id: "s4", firstName: "Noah", lastName: "Miller", classId: "class1", parentIds: ["parent3"], avatarStyle: AvatarStyle(backgroundColor: "avatarGreen", characterType: "monster4", accessory: "hat")),
        Student(id: "s5", firstName: "Ava", lastName: "Garcia", classId: "class1", parentIds: [], avatarStyle: AvatarStyle(backgroundColor: "avatarOrange", characterType: "monster5", accessory: nil)),
        Student(id: "s6", firstName: "Ethan", lastName: "Martinez", classId: "class1", parentIds: [], avatarStyle: AvatarStyle(backgroundColor: "avatarTeal", characterType: "monster6", accessory: nil)),
        Student(id: "s7", firstName: "Sophia", lastName: "Anderson", classId: "class1", parentIds: [], avatarStyle: AvatarStyle(backgroundColor: "avatarYellow", characterType: "monster7", accessory: "crown")),
        Student(id: "s8", firstName: "Mason", lastName: "Taylor", classId: "class1", parentIds: [], avatarStyle: AvatarStyle(backgroundColor: "avatarRed", characterType: "monster8", accessory: nil))
    ]

    // MARK: - Mock Stories

    lazy var stories: [Story] = [
        Story(
            id: "story1",
            classId: "class1",
            authorId: "teacher1",
            authorName: "Mrs. Johnson",
            type: .announcement,
            content: "📚 Reminder: Tomorrow is Picture Day! Please have your children dress nicely and bring their best smiles!",
            isAnnouncement: true,
            isPinned: true,
            createdAt: Date().addingTimeInterval(-3600)
        ),
        Story(
            id: "story2",
            classId: "class1",
            authorId: "teacher1",
            authorName: "Mrs. Johnson",
            type: .text,
            content: "We had such a wonderful time learning about butterflies today! 🦋 The students were amazed to see the chrysalis starting to open. Ask your child about the butterfly lifecycle - they can tell you all about it!",
            likeCount: 12,
            likedByIds: ["parent1", "parent2"],
            commentCount: 3,
            createdAt: Date().addingTimeInterval(-7200)
        ),
        Story(
            id: "story3",
            classId: "class1",
            authorId: "teacher1",
            authorName: "Mrs. Johnson",
            type: .text,
            content: "Math centers were a huge hit today! We practiced counting by 5s and 10s using fun manipulatives. Your kids are getting so good at this!",
            likeCount: 8,
            commentCount: 1,
            createdAt: Date().addingTimeInterval(-86400)
        ),
        Story(
            id: "story4",
            classId: "class1",
            authorId: "teacher1",
            authorName: "Mrs. Johnson",
            type: .text,
            content: "🎨 Art project complete! We made handprint trees for fall. They turned out beautiful - can't wait to display them at parent night!",
            likeCount: 15,
            commentCount: 5,
            createdAt: Date().addingTimeInterval(-86400 * 2)
        )
    ]

    // MARK: - Mock Conversations

    lazy var conversations: [Conversation] = [
        Conversation(
            id: "conv1",
            participantIds: ["teacher1", "parent1"],
            participantNames: ["teacher1": "Mrs. Johnson", "parent1": "Sarah Smith"],
            classId: "class1",
            studentId: "s1",
            studentName: "Emma Wilson",
            lastMessage: "Thank you for letting me know!",
            lastMessageDate: Date().addingTimeInterval(-1800),
            lastMessageSenderId: "teacher1",
            unreadCounts: ["teacher1": 0, "parent1": 1]
        ),
        Conversation(
            id: "conv2",
            participantIds: ["teacher1", "parent2"],
            participantNames: ["teacher1": "Mrs. Johnson", "parent2": "John Brown"],
            classId: "class1",
            studentId: "s2",
            studentName: "Liam Brown",
            lastMessage: "Liam did great on his reading test today!",
            lastMessageDate: Date().addingTimeInterval(-86400),
            lastMessageSenderId: "teacher1",
            unreadCounts: ["teacher1": 0, "parent2": 0]
        )
    ]

    // MARK: - Mock Messages

    let messages: [String: [Message]] = [
        "conv1": [
            Message(id: "m1", conversationId: "conv1", senderId: "parent1", senderName: "Sarah Smith", content: "Hi Mrs. Johnson! Emma mentioned she forgot her jacket at school. Is it in the lost and found?", isRead: true, createdAt: Date().addingTimeInterval(-7200)),
            Message(id: "m2", conversationId: "conv1", senderId: "teacher1", senderName: "Mrs. Johnson", content: "Hi Sarah! Yes, I found Emma's pink jacket. I'll make sure she takes it home today.", isRead: true, createdAt: Date().addingTimeInterval(-3600)),
            Message(id: "m3", conversationId: "conv1", senderId: "parent1", senderName: "Sarah Smith", content: "Thank you so much! She was worried about it.", isRead: true, createdAt: Date().addingTimeInterval(-2700)),
            Message(id: "m4", conversationId: "conv1", senderId: "teacher1", senderName: "Mrs. Johnson", content: "Thank you for letting me know!", isRead: false, createdAt: Date().addingTimeInterval(-1800))
        ],
        "conv2": [
            Message(id: "m5", conversationId: "conv2", senderId: "teacher1", senderName: "Mrs. Johnson", content: "Liam did great on his reading test today!", isRead: true, createdAt: Date().addingTimeInterval(-86400))
        ]
    ]

    // MARK: - Mock Points

    lazy var pointsSummaries: [StudentPointsSummary] = [
        StudentPointsSummary(studentId: "s1", classId: "class1", totalPoints: 15, positiveCount: 18, negativeCount: 3),
        StudentPointsSummary(studentId: "s2", classId: "class1", totalPoints: 12, positiveCount: 14, negativeCount: 2),
        StudentPointsSummary(studentId: "s3", classId: "class1", totalPoints: 8, positiveCount: 10, negativeCount: 2),
        StudentPointsSummary(studentId: "s4", classId: "class1", totalPoints: 20, positiveCount: 22, negativeCount: 2),
        StudentPointsSummary(studentId: "s5", classId: "class1", totalPoints: 6, positiveCount: 8, negativeCount: 2),
        StudentPointsSummary(studentId: "s6", classId: "class1", totalPoints: 10, positiveCount: 12, negativeCount: 2),
        StudentPointsSummary(studentId: "s7", classId: "class1", totalPoints: 14, positiveCount: 15, negativeCount: 1),
        StudentPointsSummary(studentId: "s8", classId: "class1", totalPoints: 5, positiveCount: 9, negativeCount: 4)
    ]

    lazy var pointsHistory: [PointRecord] = [
        PointRecord(id: "p1", studentId: "s1", classId: "class1", behaviorId: "helping", behaviorName: "Helping Others", points: 1, awardedBy: "teacher1", awardedByName: "Mrs. Johnson", createdAt: Date().addingTimeInterval(-3600)),
        PointRecord(id: "p2", studentId: "s1", classId: "class1", behaviorId: "teamwork", behaviorName: "Teamwork", points: 1, awardedBy: "teacher1", awardedByName: "Mrs. Johnson", createdAt: Date().addingTimeInterval(-7200)),
        PointRecord(id: "p3", studentId: "s1", classId: "class1", behaviorId: "talking", behaviorName: "Talking Out", points: -1, awardedBy: "teacher1", awardedByName: "Mrs. Johnson", createdAt: Date().addingTimeInterval(-86400))
    ]
}
