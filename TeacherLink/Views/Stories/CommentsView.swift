//
//  CommentsView.swift
//  TeacherLink
//

import SwiftUI

struct CommentsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var storyViewModel: StoryViewModel
    @Environment(\.dismiss) private var dismiss

    let story: Story
    @State private var newComment = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Comments List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(storyViewModel.comments) { comment in
                                CommentRow(
                                    comment: comment,
                                    isAuthor: comment.authorId == authViewModel.currentUser?.id,
                                    onDelete: {
                                        if let storyId = story.id, let commentId = comment.id {
                                            Task {
                                                await storyViewModel.deleteComment(
                                                    storyId: storyId,
                                                    commentId: commentId
                                                )
                                            }
                                        }
                                    }
                                )
                                .id(comment.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: storyViewModel.comments.count) { _, _ in
                        if let lastId = storyViewModel.comments.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }

                // Empty State
                if storyViewModel.comments.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No comments yet")
                            .foregroundColor(.secondary)
                        Text("Be the first to comment!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }

                // Comment Input
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(authViewModel.currentUser?.initials ?? "?")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        )

                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(.roundedBorder)
                        .focused($isInputFocused)

                    Button {
                        sendComment()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(newComment.isEmpty ? .gray : .blue)
                    }
                    .disabled(newComment.isEmpty)
                }
                .padding()
                .background(Color(.systemGray6))
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let storyId = story.id {
                    storyViewModel.listenToComments(storyId: storyId)
                }
            }
        }
    }

    private func sendComment() {
        guard let storyId = story.id,
              let userId = authViewModel.currentUser?.id,
              let userName = authViewModel.currentUser?.displayName else { return }

        Task {
            await storyViewModel.addComment(
                storyId: storyId,
                authorId: userId,
                authorName: userName,
                content: newComment
            )
            newComment = ""
        }
    }
}

struct CommentRow: View {
    let comment: StoryComment
    let isAuthor: Bool
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(comment.authorName.prefix(1)))
                        .font(.caption.bold())
                        .foregroundColor(.primary)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.authorName)
                        .font(.subheadline.bold())
                    Text(comment.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(comment.content)
                    .font(.subheadline)
            }

            Spacer()

            if isAuthor {
                Menu {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                        .padding(4)
                }
            }
        }
        .confirmationDialog("Delete Comment", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}

#Preview {
    CommentsView(story: Story(
        id: "1",
        classId: "class1",
        authorId: "teacher1",
        authorName: "Mrs. Smith",
        content: "Great day in class!"
    ))
    .environmentObject(AuthViewModel())
    .environmentObject(StoryViewModel())
}
