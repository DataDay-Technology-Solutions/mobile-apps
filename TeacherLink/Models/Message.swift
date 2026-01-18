//
//  Message.swift
//  TeacherLink
//

import Foundation

struct Conversation: Identifiable, Codable {
    var id: String?
    var participantIds: [String]
    var participantNames: [String: String]
    var classId: String
    var studentId: String?
    var studentName: String?
    var lastMessage: String
    var lastMessageDate: Date
    var lastMessageSenderId: String
    var unreadCounts: [String: Int]
    var createdAt: Date

    func unreadCount(for userId: String) -> Int {
        unreadCounts[userId] ?? 0
    }

    func otherParticipantName(currentUserId: String) -> String {
        for (id, name) in participantNames {
            if id != currentUserId {
                return name
            }
        }
        return "Unknown"
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastMessageDate, relativeTo: Date())
    }

    init(
        id: String? = nil,
        participantIds: [String],
        participantNames: [String: String],
        classId: String,
        studentId: String? = nil,
        studentName: String? = nil,
        lastMessage: String = "",
        lastMessageDate: Date = Date(),
        lastMessageSenderId: String = "",
        unreadCounts: [String: Int] = [:],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.participantIds = participantIds
        self.participantNames = participantNames
        self.classId = classId
        self.studentId = studentId
        self.studentName = studentName
        self.lastMessage = lastMessage
        self.lastMessageDate = lastMessageDate
        self.lastMessageSenderId = lastMessageSenderId
        self.unreadCounts = unreadCounts
        self.createdAt = createdAt
    }
}

struct Message: Identifiable, Codable {
    var id: String?
    var conversationId: String
    var senderId: String
    var senderName: String
    var content: String
    var imageURL: String?
    var isRead: Bool
    var readAt: Date?
    var createdAt: Date

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(createdAt) {
            formatter.dateFormat = "h:mm a"
        } else if calendar.isDateInYesterday(createdAt) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
        }
        return formatter.string(from: createdAt)
    }

    init(
        id: String? = nil,
        conversationId: String,
        senderId: String,
        senderName: String,
        content: String,
        imageURL: String? = nil,
        isRead: Bool = false,
        readAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderName = senderName
        self.content = content
        self.imageURL = imageURL
        self.isRead = isRead
        self.readAt = readAt
        self.createdAt = createdAt
    }
}
