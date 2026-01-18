//
//  ChatView.swift
//  TeacherLink
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var messageViewModel: MessageViewModel
    @Environment(\.dismiss) private var dismiss

    let conversation: Conversation
    @State private var newMessage = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messageViewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                isCurrentUser: message.senderId == authViewModel.currentUser?.id
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messageViewModel.messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onAppear {
                    scrollToBottom(proxy: proxy)
                }
            }

            // Input Bar
            HStack(spacing: 12) {
                TextField("Type a message...", text: $newMessage, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .focused($isInputFocused)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundColor(canSend ? .blue : .gray)
                }
                .disabled(!canSend)
            }
            .padding()
            .background(Color(.systemBackground))
            .overlay(alignment: .top) {
                Divider()
            }
        }
        .navigationTitle(conversation.otherParticipantName(currentUserId: authViewModel.currentUser?.id ?? ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let studentName = conversation.studentName {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(conversation.otherParticipantName(currentUserId: authViewModel.currentUser?.id ?? ""))
                            .font(.headline)
                        Text("About: \(studentName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear {
            if let conversationId = conversation.id {
                messageViewModel.listenToMessages(conversationId: conversationId)

                if let userId = authViewModel.currentUser?.id {
                    Task {
                        await messageViewModel.markAsRead(conversationId: conversationId, userId: userId)
                    }
                }
            }
        }
        .onDisappear {
            messageViewModel.clearSelection()
        }
    }

    private var canSend: Bool {
        !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !messageViewModel.isSending
    }

    private func sendMessage() {
        guard let userId = authViewModel.currentUser?.id,
              let userName = authViewModel.currentUser?.displayName else { return }

        let messageContent = newMessage
        newMessage = ""

        Task {
            await messageViewModel.sendMessage(
                content: messageContent,
                senderId: userId,
                senderName: userName
            )
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = messageViewModel.messages.last?.id {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool

    var body: some View {
        HStack {
            if isCurrentUser { Spacer(minLength: 60) }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isCurrentUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .cornerRadius(20)

                HStack(spacing: 4) {
                    Text(message.formattedTime)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if isCurrentUser && message.isRead {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }

            if !isCurrentUser { Spacer(minLength: 60) }
        }
    }
}

#Preview {
    NavigationStack {
        ChatView(conversation: Conversation(
            id: "1",
            participantIds: ["teacher1", "parent1"],
            participantNames: ["teacher1": "Mrs. Smith", "parent1": "John Doe"],
            classId: "class1",
            studentName: "Emma Doe"
        ))
        .environmentObject(AuthViewModel())
        .environmentObject(MessageViewModel())
    }
}
