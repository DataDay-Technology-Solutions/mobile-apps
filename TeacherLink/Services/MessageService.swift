//
//  MessageService.swift
//  TeacherLink
//

import Foundation
import FirebaseFirestore

class MessageService {
    static let shared = MessageService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Conversations

    func createConversation(_ conversation: Conversation) async throws -> Conversation {
        let docRef = db.collection("conversations").document()
        var newConversation = conversation
        newConversation.id = docRef.documentID

        try docRef.setData(from: newConversation)
        return newConversation
    }

    func getOrCreateConversation(
        participantIds: [String],
        participantNames: [String: String],
        classId: String,
        studentId: String? = nil,
        studentName: String? = nil
    ) async throws -> Conversation {
        // Check if conversation already exists
        let sortedIds = participantIds.sorted()
        let snapshot = try await db.collection("conversations")
            .whereField("participantIds", isEqualTo: sortedIds)
            .whereField("classId", isEqualTo: classId)
            .limit(to: 1)
            .getDocuments()

        if let existing = snapshot.documents.first,
           let conversation = try? existing.data(as: Conversation.self) {
            return conversation
        }

        // Create new conversation
        var unreadCounts: [String: Int] = [:]
        for id in participantIds {
            unreadCounts[id] = 0
        }

        let conversation = Conversation(
            participantIds: sortedIds,
            participantNames: participantNames,
            classId: classId,
            studentId: studentId,
            studentName: studentName,
            unreadCounts: unreadCounts
        )

        return try await createConversation(conversation)
    }

    func getConversationsForUser(userId: String) async throws -> [Conversation] {
        let snapshot = try await db.collection("conversations")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageDate", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Conversation.self) }
    }

    func getConversation(id: String) async throws -> Conversation {
        let document = try await db.collection("conversations").document(id).getDocument()
        guard let conversation = try? document.data(as: Conversation.self) else {
            throw MessageError.conversationNotFound
        }
        return conversation
    }

    // MARK: - Messages

    func sendMessage(_ message: Message) async throws -> Message {
        guard !message.conversationId.isEmpty else {
            throw MessageError.invalidConversation
        }

        let docRef = db.collection("conversations").document(message.conversationId)
            .collection("messages").document()

        var newMessage = message
        newMessage.id = docRef.documentID

        // Use batch to update conversation and add message atomically
        let batch = db.batch()

        try batch.setData(from: newMessage, forDocument: docRef)

        let conversationRef = db.collection("conversations").document(message.conversationId)

        // Get conversation to update unread counts
        let conversation = try await getConversation(id: message.conversationId)
        var unreadCounts = conversation.unreadCounts
        for participantId in conversation.participantIds {
            if participantId != message.senderId {
                unreadCounts[participantId] = (unreadCounts[participantId] ?? 0) + 1
            }
        }

        batch.updateData([
            "lastMessage": message.content,
            "lastMessageDate": Timestamp(date: message.createdAt),
            "lastMessageSenderId": message.senderId,
            "unreadCounts": unreadCounts
        ], forDocument: conversationRef)

        try await batch.commit()
        return newMessage
    }

    func getMessages(conversationId: String, limit: Int = 50) async throws -> [Message] {
        let snapshot = try await db.collection("conversations").document(conversationId)
            .collection("messages")
            .order(by: "createdAt", descending: false)
            .limit(toLast: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Message.self) }
    }

    func markAsRead(conversationId: String, userId: String) async throws {
        let conversationRef = db.collection("conversations").document(conversationId)

        try await conversationRef.updateData([
            "unreadCounts.\(userId)": 0
        ])

        // Mark individual messages as read
        let messagesSnapshot = try await conversationRef.collection("messages")
            .whereField("senderId", isNotEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()

        let batch = db.batch()
        for document in messagesSnapshot.documents {
            batch.updateData([
                "isRead": true,
                "readAt": Timestamp(date: Date())
            ], forDocument: document.reference)
        }

        try await batch.commit()
    }

    func deleteMessage(conversationId: String, messageId: String) async throws {
        try await db.collection("conversations").document(conversationId)
            .collection("messages").document(messageId).delete()
    }

    func getTotalUnreadCount(userId: String) async throws -> Int {
        let conversations = try await getConversationsForUser(userId: userId)
        return conversations.reduce(0) { $0 + $1.unreadCount(for: userId) }
    }

    // MARK: - Broadcast Messages (Teacher to All Parents)

    func sendBroadcastMessage(
        teacherId: String,
        teacherName: String,
        classId: String,
        parentIds: [String],
        content: String
    ) async throws {
        let batch = db.batch()

        for parentId in parentIds {
            let conversation = try await getOrCreateConversation(
                participantIds: [teacherId, parentId],
                participantNames: [teacherId: teacherName],
                classId: classId
            )

            guard let conversationId = conversation.id else { continue }

            let messageRef = db.collection("conversations").document(conversationId)
                .collection("messages").document()

            let message = Message(
                id: messageRef.documentID,
                conversationId: conversationId,
                senderId: teacherId,
                senderName: teacherName,
                content: content
            )

            try batch.setData(from: message, forDocument: messageRef)

            let conversationRef = db.collection("conversations").document(conversationId)
            batch.updateData([
                "lastMessage": content,
                "lastMessageDate": Timestamp(date: Date()),
                "lastMessageSenderId": teacherId,
                "unreadCounts.\(parentId)": FieldValue.increment(Int64(1))
            ], forDocument: conversationRef)
        }

        try await batch.commit()
    }

    // MARK: - Real-time Listeners

    func listenToConversations(userId: String, completion: @escaping ([Conversation]) -> Void) -> ListenerRegistration {
        return db.collection("conversations")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageDate", descending: true)
            .addSnapshotListener { snapshot, _ in
                let conversations = snapshot?.documents.compactMap { try? $0.data(as: Conversation.self) } ?? []
                completion(conversations)
            }
    }

    func listenToMessages(conversationId: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration {
        return db.collection("conversations").document(conversationId)
            .collection("messages")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, _ in
                let messages = snapshot?.documents.compactMap { try? $0.data(as: Message.self) } ?? []
                completion(messages)
            }
    }
}

enum MessageError: LocalizedError {
    case conversationNotFound
    case invalidConversation
    case sendFailed

    var errorDescription: String? {
        switch self {
        case .conversationNotFound:
            return "Conversation not found"
        case .invalidConversation:
            return "Invalid conversation"
        case .sendFailed:
            return "Failed to send message"
        }
    }
}
