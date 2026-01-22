//
//  MessagesView.swift
//  TeacherLink
//

import SwiftUI

struct MessagesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @EnvironmentObject var messageViewModel: MessageViewModel

    @State private var showNewMessage = false

    var body: some View {
        NavigationStack {
            Group {
                if messageViewModel.isLoading && messageViewModel.conversations.isEmpty {
                    ProgressView()
                } else if messageViewModel.conversations.isEmpty {
                    EmptyMessagesView(isTeacher: authViewModel.isTeacher)
                } else {
                    List {
                        ForEach(messageViewModel.conversations) { conversation in
                            NavigationLink {
                                ChatView(conversation: conversation)
                                    .environmentObject(messageViewModel)
                            } label: {
                                ConversationRow(
                                    conversation: conversation,
                                    currentUserId: authViewModel.currentUser?.id ?? ""
                                )
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        if let userId = authViewModel.currentUser?.id {
                            await messageViewModel.loadConversations(userId: userId)
                        }
                    }
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                if authViewModel.isTeacher {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showNewMessage = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
            }
            .sheet(isPresented: $showNewMessage) {
                NewMessageView()
                    .environmentObject(classroomViewModel)
                    .environmentObject(messageViewModel)
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let currentUserId: String

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)

                Text(conversation.otherParticipantName(currentUserId: currentUserId).prefix(1))
                    .font(.headline)
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherParticipantName(currentUserId: currentUserId))
                        .font(.headline)

                    Spacer()

                    Text(conversation.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let studentName = conversation.studentName {
                    Text("About: \(studentName)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                HStack {
                    Text(conversation.lastMessage ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer()

                    if conversation.unreadCount(for: currentUserId) > 0 {
                        Text("\(conversation.unreadCount(for: currentUserId))")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyMessagesView: View {
    let isTeacher: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "message")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Messages Yet")
                .font(.title2.bold())

            Text(isTeacher
                 ? "Start a conversation with a parent"
                 : "Send a message to your child's teacher")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

#Preview {
    MessagesView()
        .environmentObject(AuthViewModel())
        .environmentObject(ClassroomViewModel())
        .environmentObject(MessageViewModel())
}
