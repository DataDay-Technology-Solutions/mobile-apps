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
    var lastMessage: String?
    var lastMessageDate: Date
    var lastMessageSenderId: String?
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

    // CodingKeys for proper Supabase snake_case mapping
    enum CodingKeys: String, CodingKey {
        case id
        case participantIds = "participant_ids"
        case participantNames = "participant_names"
        case classId = "class_id"
        case studentId = "student_id"
        case studentName = "student_name"
        case lastMessage = "last_message"
        case lastMessageDate = "last_message_date"
        case lastMessageSenderId = "last_message_sender_id"
        case unreadCounts = "unread_counts"
        case createdAt = "created_at"
    }

    init(
        id: String? = nil,
        participantIds: [String],
        participantNames: [String: String],
        classId: String,
        studentId: String? = nil,
        studentName: String? = nil,
        lastMessage: String? = nil,
        lastMessageDate: Date = Date(),
        lastMessageSenderId: String? = nil,
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

    // CodingKeys for proper Supabase snake_case mapping
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case senderName = "sender_name"
        case content
        case isRead = "is_read"
        case readAt = "read_at"
        case createdAt = "created_at"
    }

    init(
        id: String? = nil,
        conversationId: String,
        senderId: String,
        senderName: String,
        content: String,
        isRead: Bool = false,
        readAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderName = senderName
        self.content = content
        self.isRead = isRead
        self.readAt = readAt
        self.createdAt = createdAt
    }
}
