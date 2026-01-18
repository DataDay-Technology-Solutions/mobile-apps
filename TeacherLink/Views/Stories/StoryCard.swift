//
//  StoryCard.swift
//  TeacherLink
//

import SwiftUI

struct StoryCard: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var storyViewModel: StoryViewModel

    let story: Story
    @State private var showComments = false
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Author Avatar
                Circle()
                    .fill(story.isAnnouncement ? Color.orange : Color.blue)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: story.isAnnouncement ? "megaphone.fill" : "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(story.authorName)
                            .font(.subheadline.bold())

                        if story.isAnnouncement {
                            Text("ANNOUNCEMENT")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }
                    }

                    Text(story.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Menu (for author only)
                if story.authorId == authViewModel.currentUser?.id {
                    Menu {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
                            .padding(8)
                    }
                }
            }

            // Content
            if !story.content.isEmpty {
                Text(story.content)
                    .font(.body)
            }

            // Media
            if !story.mediaURLs.isEmpty {
                StoryMediaView(mediaURLs: story.mediaURLs, type: story.type)
            }

            // Actions
            HStack(spacing: 24) {
                // Like Button
                Button {
                    if let userId = authViewModel.currentUser?.id {
                        Task {
                            await storyViewModel.toggleLike(story: story, userId: userId)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isLikedByCurrentUser ? "heart.fill" : "heart")
                            .foregroundColor(isLikedByCurrentUser ? .red : .secondary)
                        Text("\(story.likeCount)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // Comment Button
                Button {
                    showComments = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .foregroundColor(.secondary)
                        Text("\(story.commentCount)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showComments) {
            CommentsView(story: story)
                .environmentObject(storyViewModel)
        }
        .confirmationDialog("Delete Story", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task {
                    await storyViewModel.deleteStory(story)
                }
            }
        } message: {
            Text("Are you sure you want to delete this story? This action cannot be undone.")
        }
    }

    private var isLikedByCurrentUser: Bool {
        guard let userId = authViewModel.currentUser?.id else { return false }
        return story.likedByIds.contains(userId)
    }
}

struct StoryMediaView: View {
    let mediaURLs: [String]
    let type: StoryType

    var body: some View {
        if type == .video {
            // Video placeholder - would use AVPlayer in real app
            ZStack {
                Rectangle()
                    .fill(Color.black.opacity(0.1))
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(12)

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
        } else if !mediaURLs.isEmpty {
            // Photo grid
            if mediaURLs.count == 1 {
                AsyncImage(url: URL(string: mediaURLs[0])) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(4/3, contentMode: .fit)
                            .cornerRadius(12)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 300)
                            .clipped()
                            .cornerRadius(12)
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(4/3, contentMode: .fit)
                            .cornerRadius(12)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                // Multi-photo grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 4) {
                    ForEach(Array(mediaURLs.prefix(4).enumerated()), id: \.offset) { index, url in
                        AsyncImage(url: URL(string: url)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fill)
                                    .clipped()
                            default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                        .overlay {
                            if index == 3 && mediaURLs.count > 4 {
                                Rectangle()
                                    .fill(.black.opacity(0.5))
                                    .overlay(
                                        Text("+\(mediaURLs.count - 4)")
                                            .font(.title2.bold())
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                    }
                }
                .cornerRadius(12)
            }
        }
    }
}

#Preview {
    StoryCard(story: Story(
        id: "1",
        classId: "class1",
        authorId: "teacher1",
        authorName: "Mrs. Smith",
        type: .text,
        content: "Today we learned about butterflies! The students were so engaged and curious. Ask your child about the butterfly lifecycle!",
        isAnnouncement: false
    ))
    .environmentObject(AuthViewModel())
    .environmentObject(StoryViewModel())
    .padding()
}
