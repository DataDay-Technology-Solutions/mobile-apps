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
    @Published var adminCCActive = false // Indicates if admin is being CC'd on current conversation

    private var currentUserId: String?
    private var currentUserRole: UserRole?

    init() {
        // Don't auto-load - wait for user info
    }

    func listenToConversations(userId: String, role: UserRole = .teacher) {
        currentUserId = userId
        currentUserRole = role

        if USE_MOCK_DATA {
            // CRITICAL: Filter conversations based on user role
            // Parents should ONLY see conversations they are a participant in
            // Teachers see all conversations for their class
            let allConversations = MockDataService.shared.conversations

            if role == .parent {
                // Parents only see their own conversations
                conversations = allConversations.filter { conversation in
                    conversation.participantIds.contains(userId)
                }
            } else {
                // Teachers see all conversations
                conversations = allConversations
            }

            updateUnreadCount(userId: userId)
        } else {
            MessageService.shared.listenToConversations(userId: userId) { [weak self] conversations in
                if role == .parent {
                    self?.conversations = conversations.filter { $0.participantIds.contains(userId) }
                } else {
                    self?.conversations = conversations
                }
                self?.updateUnreadCount(userId: userId)
            }
        }
    }

    func loadConversations(userId: String, role: UserRole = .teacher) async {
        isLoading = true
        errorMessage = nil
        currentUserId = userId
        currentUserRole = role

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 300_000_000)

            let allConversations = MockDataService.shared.conversations

            // Privacy: Filter based on role
            if role == .parent {
                conversations = allConversations.filter { $0.participantIds.contains(userId) }
            } else {
                conversations = allConversations
            }

            updateUnreadCount(userId: userId)
        } else {
            do {
                let allConversations = try await MessageService.shared.getConversationsForUser(userId: userId)

                if role == .parent {
                    conversations = allConversations.filter { $0.participantIds.contains(userId) }
                } else {
                    conversations = allConversations
                }

                updateUnreadCount(userId: userId)
            } catch {
                errorMessage = error.localizedDescription
            }
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
        } else {
            MessageService.shared.listenToMessages(conversationId: conversationId) { [weak self] messages in
                self?.messages = messages
            }
        }
    }

    func loadMessages(conversationId: String) async {
        isLoading = true
        errorMessage = nil

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 200_000_000)
            messages = MockDataService.shared.messages[conversationId] ?? []
        } else {
            do {
                messages = try await MessageService.shared.getMessages(conversationId: conversationId)
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    func sendMessage(content: String, senderId: String, senderName: String, senderRole: UserRole = .teacher) async {
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

            // If sender is a parent, check if admin should be CC'd
            if senderRole == .parent {
                checkAdminCC(parentId: senderId)
            }
        } else {
            do {
                let message = Message(
                    id: nil,
                    conversationId: conversationId,
                    senderId: senderId,
                    senderName: senderName,
                    content: content,
                    createdAt: Date()
                )
                let sent = try await MessageService.shared.sendMessage(message)
                messages.append(sent)

                // Update conversation preview
                if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
                    conversations[index].lastMessage = content
                    conversations[index].lastMessageDate = Date()
                    conversations[index].lastMessageSenderId = senderId
                }

                if senderRole == .parent {
                    checkAdminCC(parentId: senderId)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        isSending = false
    }

    // Check if admin should be CC'd on this conversation
    private func checkAdminCC(parentId: String) {
        if let profile = MockDataService.shared.getParentProfile(userId: parentId),
           profile.adminCCEnabled {
            adminCCActive = true
        }
    }

    // Check if admin should see this conversation
    func shouldAdminBeCC(parentUserId: String) -> Bool {
        guard let profile = MockDataService.shared.getParentProfile(userId: parentUserId) else {
            return false
        }
        return profile.adminCCEnabled
    }

    // Get admin info for CC display
    func getAdminForCC() -> User? {
        return MockDataService.shared.adminUser
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
                    currentUserId: currentUser.displayName ?? currentUser.name,
                    otherUserId: user.displayName ?? user.name
                ],
                classId: classId,
                studentId: studentId,
                studentName: studentName,
                unreadCounts: [currentUserId: 0, otherUserId: 0]
            )

            if let conv = conversation {
                conversations.insert(conv, at: 0)
            }
        } else {
            do {
                conversation = try await MessageService.shared.getOrCreateConversation(
                    participantIds: [currentUserId, otherUserId],
                    participantNames: [
                        currentUserId: currentUser.displayName ?? currentUser.name,
                        otherUserId: user.displayName ?? user.name
                    ],
                    classId: classId,
                    studentId: studentId,
                    studentName: studentName
                )

                if let conv = conversation, !conversations.contains(where: { $0.id == conv.id }) {
                    conversations.insert(conv, at: 0)
                }
            } catch {
                errorMessage = error.localizedDescription
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
        } else {
            do {
                try await MessageService.shared.markAsRead(conversationId: conversationId, userId: userId)
                if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
                    conversations[index].unreadCounts[userId] = 0
                    updateUnreadCount(userId: userId)
                }
            } catch {
                errorMessage = error.localizedDescription
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
        } else {
            do {
                try await MessageService.shared.sendBroadcastMessage(
                    teacherId: teacherId,
                    teacherName: teacherName,
                    classId: classId,
                    parentIds: parentIds,
                    content: content
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        isSending = false
    }

    func clearSelection() {
        selectedConversation = nil
        messages = []
    }

    // Get or create a conversation between participants
    func getOrCreateConversation(
        participantIds: [String],
        participantNames: [String: String],
        classId: String,
        studentId: String? = nil,
        studentName: String? = nil
    ) async -> Conversation? {
        isLoading = true
        errorMessage = nil

        let sortedIds = participantIds.sorted()

        // Check if conversation already exists
        if let existing = conversations.first(where: { $0.participantIds.sorted() == sortedIds }) {
            isLoading = false
            return existing
        }

        var conversation: Conversation?

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 200_000_000)

            conversation = Conversation(
                id: UUID().uuidString,
                participantIds: sortedIds,
                participantNames: participantNames,
                classId: classId,
                studentId: studentId,
                studentName: studentName,
                unreadCounts: Dictionary(uniqueKeysWithValues: sortedIds.map { ($0, 0) })
            )

            if let conv = conversation {
                conversations.insert(conv, at: 0)
            }
        } else {
            // Use real MessageService for Supabase
            do {
                conversation = try await MessageService.shared.getOrCreateConversation(
                    participantIds: sortedIds,
                    participantNames: participantNames,
                    classId: classId,
                    studentId: studentId,
                    studentName: studentName
                )

                if let conv = conversation, !conversations.contains(where: { $0.id == conv.id }) {
                    conversations.insert(conv, at: 0)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
        return conversation
    }
}
