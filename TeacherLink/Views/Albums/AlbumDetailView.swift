//
//  AlbumDetailView.swift
//  TeacherLink
//
//  Photo gallery view for albums (PhotoCircle-style)
//

import SwiftUI
import PhotosUI

struct AlbumDetailView: View {
    @EnvironmentObject var albumViewModel: PhotoAlbumViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    let album: PhotoAlbum
    @State private var selectedPhoto: AlbumPhoto?
    @State private var showAddPhoto = false
    @State private var showDeleteConfirm = false

    var canContribute: Bool {
        authViewModel.isTeacher || album.allowParentContributions
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Album header
                VStack(alignment: .leading, spacing: 8) {
                    Text(album.description)
                        .font(.body)
                        .foregroundColor(.secondary)

                    HStack {
                        Label("\(album.photoCount) photos", systemImage: "photo.stack")
                        Spacer()
                        Label(album.createdByName, systemImage: "person")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    if album.allowParentContributions {
                        Label("Parents can add photos", systemImage: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)

                // Photo grid
                if albumViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else if albumViewModel.currentAlbumPhotos.isEmpty {
                    EmptyPhotoGridView(canContribute: canContribute)
                        .padding(.top, 40)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2)
                    ], spacing: 2) {
                        ForEach(albumViewModel.currentAlbumPhotos) { photo in
                            PhotoGridItem(photo: photo)
                                .onTapGesture {
                                    selectedPhoto = photo
                                }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(album.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if canContribute {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddPhoto = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }

            if authViewModel.isTeacher {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete Album", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo)
                .environmentObject(albumViewModel)
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showAddPhoto) {
            AddPhotoView(albumId: album.id ?? "")
                .environmentObject(albumViewModel)
                .environmentObject(authViewModel)
        }
        .confirmationDialog("Delete Album", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task {
                    await albumViewModel.deleteAlbum(album)
                }
            }
        } message: {
            Text("Are you sure you want to delete this album? All photos will be permanently removed.")
        }
        .onAppear {
            if let albumId = album.id {
                Task {
                    await albumViewModel.loadPhotos(albumId: albumId)
                }
            }
        }
    }
}

struct PhotoGridItem: View {
    let photo: AlbumPhoto

    var body: some View {
        ZStack {
            // Placeholder gradient for mock photos
            Rectangle()
                .fill(LinearGradient(
                    colors: [
                        Color(hue: Double.random(in: 0...1), saturation: 0.3, brightness: 0.9),
                        Color(hue: Double.random(in: 0...1), saturation: 0.4, brightness: 0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .aspectRatio(1, contentMode: .fill)

            // Photo icon
            Image(systemName: "photo")
                .font(.title)
                .foregroundColor(.white.opacity(0.5))

            // Like indicator
            if photo.likeCount > 0 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 2) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                            Text("\(photo.likeCount)")
                                .font(.caption2)
                        }
                        .foregroundColor(.white)
                        .padding(4)
                        .background(.black.opacity(0.5))
                        .cornerRadius(4)
                        .padding(4)
                    }
                }
            }
        }
    }
}

struct EmptyPhotoGridView: View {
    let canContribute: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("No Photos Yet")
                .font(.headline)

            Text(canContribute
                 ? "Tap + to add the first photo!"
                 : "Photos will appear here once added.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PhotoDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var albumViewModel: PhotoAlbumViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    let photo: AlbumPhoto
    @State private var showComments = false
    @State private var showDeleteConfirm = false

    var isLiked: Bool {
        guard let userId = authViewModel.currentUser?.id else { return false }
        return photo.likedByIds.contains(userId)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Photo
                    ZStack {
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .aspectRatio(4/3, contentMode: .fit)

                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Caption
                    if let caption = photo.caption, !caption.isEmpty {
                        Text(caption)
                            .font(.body)
                            .padding(.horizontal)
                    }

                    // Photo info
                    HStack {
                        Text("By \(photo.uploadedByName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(photo.timeAgo)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    Divider()

                    // Actions
                    HStack(spacing: 32) {
                        // Like button
                        Button {
                            if let userId = authViewModel.currentUser?.id {
                                Task {
                                    await albumViewModel.toggleLike(photo: photo, userId: userId)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .foregroundColor(isLiked ? .red : .primary)
                                Text("\(photo.likeCount)")
                            }
                        }

                        // Comment button
                        Button {
                            showComments = true
                        } label: {
                            HStack {
                                Image(systemName: "bubble.right")
                                Text("\(photo.commentCount)")
                            }
                        }

                        // Download button
                        Button {
                            // In real app, this would save to photo library
                        } label: {
                            HStack {
                                Image(systemName: "arrow.down.circle")
                                Text("Save")
                            }
                        }

                        Spacer()
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal)

                    Divider()

                    // Quick reactions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reactions")
                            .font(.subheadline.bold())
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ReactionType.allCases, id: \.self) { reaction in
                                    ReactionButton(reaction: reaction) {
                                        // Handle reaction
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if photo.uploadedBy == authViewModel.currentUser?.id || authViewModel.isTeacher {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .sheet(isPresented: $showComments) {
                PhotoCommentsView(photo: photo)
                    .environmentObject(albumViewModel)
                    .environmentObject(authViewModel)
            }
            .confirmationDialog("Delete Photo", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    Task {
                        await albumViewModel.deletePhoto(photo)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ReactionButton: View {
    let reaction: ReactionType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Text(reaction.emoji)
                    .font(.title)
                Text(reaction.label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct AddPhotoView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var albumViewModel: PhotoAlbumViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    let albumId: String
    @State private var caption = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Photo picker
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    if selectedImageData != nil {
                        ZStack {
                            Rectangle()
                                .fill(Color.green.opacity(0.2))
                                .aspectRatio(4/3, contentMode: .fit)
                                .cornerRadius(12)

                            VStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.green)
                                Text("Photo Selected")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                Text("Tap to change")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        ZStack {
                            Rectangle()
                                .fill(Color(.systemGray6))
                                .aspectRatio(4/3, contentMode: .fit)
                                .cornerRadius(12)

                            VStack {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                Text("Tap to select photo")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Caption
                VStack(alignment: .leading, spacing: 8) {
                    Text("Caption (optional)")
                        .font(.subheadline.bold())
                    TextField("Add a caption...", text: $caption, axis: .vertical)
                        .lineLimit(2...4)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                // Upload progress
                if albumViewModel.isUploading {
                    VStack {
                        ProgressView(value: albumViewModel.uploadProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        Text("Uploading...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Add Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Upload") {
                        uploadPhoto()
                    }
                    .disabled(selectedImageData == nil || albumViewModel.isUploading)
                }
            }
            .onChange(of: selectedItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }
        }
    }

    private func uploadPhoto() {
        guard let imageData = selectedImageData,
              let userId = authViewModel.currentUser?.id,
              let userName = authViewModel.currentUser?.displayName else { return }

        Task {
            await albumViewModel.addPhoto(
                albumId: albumId,
                imageData: imageData,
                caption: caption.isEmpty ? nil : caption,
                uploadedBy: userId,
                uploadedByName: userName
            )
            dismiss()
        }
    }
}

struct PhotoCommentsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var albumViewModel: PhotoAlbumViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    let photo: AlbumPhoto
    @State private var newComment = ""

    var body: some View {
        NavigationStack {
            VStack {
                // Comments list
                if albumViewModel.photoComments.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No comments yet")
                            .font(.headline)
                        Text("Be the first to comment!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(albumViewModel.photoComments) { comment in
                            PhotoCommentRow(
                                authorName: comment.authorName,
                                content: comment.content,
                                timeAgo: comment.timeAgo,
                                canDelete: comment.authorId == authViewModel.currentUser?.id
                            ) {
                                Task {
                                    await albumViewModel.deleteComment(comment)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }

                // Comment input
                HStack {
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button {
                        sendComment()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(newComment.isEmpty ? .gray : .blue)
                    }
                    .disabled(newComment.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let photoId = photo.id {
                    Task {
                        await albumViewModel.loadComments(photoId: photoId)
                    }
                }
            }
        }
    }

    private func sendComment() {
        guard !newComment.isEmpty,
              let photoId = photo.id,
              let userId = authViewModel.currentUser?.id,
              let userName = authViewModel.currentUser?.displayName else { return }

        Task {
            await albumViewModel.addComment(
                photoId: photoId,
                authorId: userId,
                authorName: userName,
                content: newComment
            )
            newComment = ""
        }
    }
}

struct PhotoCommentRow: View {
    let authorName: String
    let content: String
    let timeAgo: String
    let canDelete: Bool
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(authorName)
                    .font(.subheadline.bold())
                Spacer()
                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if canDelete {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                    }
                }
            }
            Text(content)
                .font(.body)
        }
        .padding(.vertical, 4)
    }
}
