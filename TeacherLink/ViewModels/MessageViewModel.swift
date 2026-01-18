//
//  MessageViewModel.swift
//  TeacherLink
//

import Foundation

@MainActor
class MessageViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var selectedConversation: Conversation?
    @Published var messages: [Message] = []
    @Published var totalUnreadCount: Int = 0
    @Published var isLoading = false
    @Published var isSending = false
    @Published var errorMessage: String?

    init() {
        if USE_MOCK_DATA {
            conversations = MockDataService.shared.conversations
            updateUnreadCount(userId: "teacher1")
        }
    }

    func listenToConversations(userId: String) {
        if USE_MOCK_DATA {
            conversations = MockDataService.shared.conversations
            updateUnreadCount(userId: userId)
        }
    }

    func loadConversations(userId: String) async {
        isLoading = true
        errorMessage = nil

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 300_000_000)
            conversations = MockDataService.shared.conversations
            updateUnreadCount(userId: userId)
        }

        isLoading = false
    }

    private func updateUnreadCount(userId: String) {
        totalUnreadCount = conversations.reduce(0) { $0 + $1.unreadCount(for: userId) }
    }

    func selectConversation(_ conversation: Conversation, userId: String) {
        selectedConversation = conversation
        if let conversationId = conversation.id {
            listenToMessages(conversationId: conversationId)
            Task {
                await markAsRead(conversationId: conversationId, userId: userId)
            }
        }
    }

    func listenToMessages(conversationId: String) {
        if USE_MOCK_DATA {
            messages = MockDataService.shared.messages[conversationId] ?? []
        }
    }

    func loadMessages(conversationId: String) async {
        isLoading = true
        errorMessage = nil

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 200_000_000)
            messages = MockDataService.shared.messages[conversationId] ?? []
        }

        isLoading = false
    }

    func sendMessage(content: String, senderId: String, senderName: String) async {
        guard let conversationId = selectedConversation?.id else { return }

        isSending = true
        errorMessage = nil

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 200_000_000)

            let message = Message(
                id: UUID().uuidString,
                conversationId: conversationId,
                senderId: senderId,
                senderName: senderName,
                content: content,
                createdAt: Date()
            )
            messages.append(message)

            // Update conversation preview
            if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
                conversations[index].lastMessage = content
                conversations[index].lastMessageDate = Date()
                conversations[index].lastMessageSenderId = senderId
            }
        }

        isSending = false
    }

    func startConversation(
        with user: User,
        currentUser: User,
        classId: String,
        studentId: String? = nil,
        studentName: String? = nil
    ) async -> Conversation? {
        guard let currentUserId = currentUser.id, let otherUserId = user.id else { return nil }

        isLoading = true
        errorMessage = nil

        var conversation: Conversation?

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 300_000_000)

            conversation = Conversation(
                id: UUID().uuidString,
                participantIds: [currentUserId, otherUserId].sorted(),
                participantNames: [
                    currentUserId: currentUser.displayName,
                    otherUserId: user.displayName
                ],
                classId: classId,
                studentId: studentId,
                studentName: studentName,
                unreadCounts: [currentUserId: 0, otherUserId: 0]
            )

            if let conv = conversation {
                conversations.insert(conv, at: 0)
            }
        }

        isLoading = false
        return conversation
    }

    func markAsRead(conversationId: String, userId: String) async {
        if USE_MOCK_DATA {
            if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
                conversations[index].unreadCounts[userId] = 0
                updateUnreadCount(userId: userId)
            }
        }
    }

    func sendBroadcastMessage(
        teacherId: String,
        teacherName: String,
        classId: String,
        parentIds: [String],
        content: String
    ) async {
        isSending = true
        errorMessage = nil

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 500_000_000)
            // In mock mode, just simulate success
        }

        isSending = false
    }

    func clearSelection() {
        selectedConversation = nil
        messages = []
    }
}
