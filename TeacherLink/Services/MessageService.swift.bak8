//
//  MessageService.swift
//  HallPass (formerly TeacherLink)
//

import Foundation
import Supabase

class MessageService {
    static let shared = MessageService()
    private let supabase = SupabaseConfig.client

    private init() {}

    // MARK: - Conversations

    func createConversation(_ conversation: Conversation) async throws -> Conversation {
        let response: [Conversation] = try await supabase
            .from("conversations")
            .insert(conversation)
            .select()
            .execute()
            .value

        guard let newConversation = response.first else {
            throw MessageError.sendFailed
        }
        return newConversation
    }

    func getOrCreateConversation(
        participantIds: [String],
        participantNames: [String: String],
        classId: String,
        studentId: String? = nil,
        studentName: String? = nil
    ) async throws -> Conversation {
        let sortedIds = participantIds.sorted()

        // Check if conversation already exists
        let existing: [Conversation] = try await supabase
            .from("conversations")
            .select()
            .eq("class_id", value: classId)
            .contains("participant_ids", value: sortedIds)
            .limit(1)
            .execute()
            .value

        if let conversation = existing.first {
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
        let response: [Conversation] = try await supabase
            .from("conversations")
            .select()
            .contains("participant_ids", value: [userId])
            .order("last_message_date", ascending: false)
            .execute()
            .value

        return response
    }

    func getConversation(id: String) async throws -> Conversation {
        let conversation: Conversation = try await supabase
            .from("conversations")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value

        return conversation
    }

    // MARK: - Messages

    func sendMessage(_ message: Message) async throws -> Message {
        guard !message.conversationId.isEmpty else {
            throw MessageError.invalidConversation
        }

        // Insert message
        let response: [Message] = try await supabase
            .from("messages")
            .insert(message)
            .select()
            .execute()
            .value

        guard let newMessage = response.first else {
            throw MessageError.sendFailed
        }

        // Update conversation
        let conversation = try await getConversation(id: message.conversationId)
        var unreadCounts = conversation.unreadCounts
        for participantId in conversation.participantIds {
            if participantId != message.senderId {
                unreadCounts[participantId] = (unreadCounts[participantId] ?? 0) + 1
            }
        }

        try await supabase
            .from("conversations")
            .update([
                "last_message": AnyJSON.string(message.content),
                "last_message_date": AnyJSON.string(ISO8601DateFormatter().string(from: message.createdAt)),
                "last_message_sender_id": AnyJSON.string(message.senderId),
                "unread_counts": AnyJSON.object(unreadCounts.mapValues { AnyJSON.integer($0) })
            ])
            .eq("id", value: message.conversationId)
            .execute()

        return newMessage
    }

    func getMessages(conversationId: String, limit: Int = 50) async throws -> [Message] {
        let response: [Message] = try await supabase
            .from("messages")
            .select()
            .eq("conversation_id", value: conversationId)
            .order("created_at", ascending: true)
            .limit(limit)
            .execute()
            .value

        return response
    }

    func markAsRead(conversationId: String, userId: String) async throws {
        // Update conversation unread count
        let conversation = try await getConversation(id: conversationId)
        var unreadCounts = conversation.unreadCounts
        unreadCounts[userId] = 0

        try await supabase
            .from("conversations")
            .update(["unread_counts": AnyJSON.object(unreadCounts.mapValues { AnyJSON.integer($0) })])
            .eq("id", value: conversationId)
            .execute()

        // Mark individual messages as read
        try await supabase
            .from("messages")
            .update([
                "is_read": AnyJSON.bool(true),
                "read_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
            ])
            .eq("conversation_id", value: conversationId)
            .neq("sender_id", value: userId)
            .eq("is_read", value: false)
            .execute()
    }

    func deleteMessage(conversationId: String, messageId: String) async throws {
        try await supabase
            .from("messages")
            .delete()
            .eq("id", value: messageId)
            .execute()
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
        for parentId in parentIds {
            let conversation = try await getOrCreateConversation(
                participantIds: [teacherId, parentId],
                participantNames: [teacherId: teacherName],
                classId: classId
            )

            guard let conversationId = conversation.id else { continue }

            let message = Message(
                conversationId: conversationId,
                senderId: teacherId,
                senderName: teacherName,
                content: content
            )

            _ = try await sendMessage(message)
        }
    }

    // MARK: - Real-time Listeners

    private var conversationsChannel: RealtimeChannelV2?
    private var messagesChannel: RealtimeChannelV2?

    func listenToConversations(userId: String, completion: @escaping ([Conversation]) -> Void) {
        // Initial fetch
        Task {
            let conversations = try? await getConversationsForUser(userId: userId)
            await MainActor.run {
                completion(conversations ?? [])
            }
        }

        // Set up realtime subscription
        conversationsChannel = supabase.realtimeV2.channel("conversations_\(userId)")

        Task {
            await conversationsChannel?.subscribe()

            let changes = conversationsChannel?.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "conversations"
            )

            if let changes = changes {
                for await _ in changes {
                    let conversations = try? await getConversationsForUser(userId: userId)
                    await MainActor.run {
                        completion(conversations ?? [])
                    }
                }
            }
        }
    }

    func listenToMessages(conversationId: String, completion: @escaping ([Message]) -> Void) {
        // Initial fetch
        Task {
            let messages = try? await getMessages(conversationId: conversationId)
            await MainActor.run {
                completion(messages ?? [])
            }
        }

        // Set up realtime subscription
        messagesChannel = supabase.realtimeV2.channel("messages_\(conversationId)")

        Task {
            await messagesChannel?.subscribe()

            let changes = messagesChannel?.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "messages",
                filter: "conversation_id=eq.\(conversationId)"
            )

            if let changes = changes {
                for await _ in changes {
                    let messages = try? await getMessages(conversationId: conversationId)
                    await MainActor.run {
                        completion(messages ?? [])
                    }
                }
            }
        }
    }

    func stopListening() {
        Task {
            await conversationsChannel?.unsubscribe()
            await messagesChannel?.unsubscribe()
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
