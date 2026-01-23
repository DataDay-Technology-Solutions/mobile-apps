//
//  PhotoAlbumsView.swift
//  TeacherLink
//
//  PhotoCircle-style photo albums for classroom memories
//

import SwiftUI

struct PhotoAlbumsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @EnvironmentObject var albumViewModel: PhotoAlbumViewModel

    @State private var showCreateAlbum = false
    @State private var searchText = ""

    var filteredAlbums: [PhotoAlbum] {
        if searchText.isEmpty {
            return albumViewModel.albums
        }
        return albumViewModel.albums.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search albums...", text: $searchText)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)

                    if albumViewModel.isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else if filteredAlbums.isEmpty {
                        EmptyAlbumsView(isTeacher: authViewModel.isTeacher)
                            .padding(.top, 40)
                    } else {
                        // Albums grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(filteredAlbums) { album in
                                NavigationLink(destination: AlbumDetailView(album: album)
                                    .environmentObject(albumViewModel)
                                    .environmentObject(authViewModel)) {
                                    AlbumCard(album: album)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Photo Albums")
            .toolbar {
                if authViewModel.isTeacher {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showCreateAlbum = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateAlbum) {
                CreateAlbumView()
                    .environmentObject(albumViewModel)
                    .environmentObject(classroomViewModel)
                    .environmentObject(authViewModel)
            }
            .refreshable {
                if let classId = classroomViewModel.selectedClassroom?.id {
                    await albumViewModel.loadAlbums(classId: classId)
                }
            }
            .onAppear {
                if let classId = classroomViewModel.selectedClassroom?.id {
                    Task {
                        await albumViewModel.loadAlbums(classId: classId)
                    }
                }
            }
        }
    }
}

struct AlbumCard: View {
    let album: PhotoAlbum

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover image
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .aspectRatio(1, contentMode: .fit)

                VStack {
                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)

                    Text("\(album.photoCount)")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text("photos")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            // Album info
            VStack(alignment: .leading, spacing: 4) {
                Text(album.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(album.timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct EmptyAlbumsView: View {
    let isTeacher: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Albums Yet")
                .font(.title2.bold())

            Text(isTeacher
                 ? "Create your first album to share classroom memories!"
                 : "Your teacher hasn't created any albums yet.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

struct CreateAlbumView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var albumViewModel: PhotoAlbumViewModel
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var name = ""
    @State private var description = ""
    @State private var shareWithParents = true
    @State private var allowParentContributions = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Album Details") {
                    TextField("Album Name", text: $name)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Sharing") {
                    Toggle("Share with Parents", isOn: $shareWithParents)
                    Toggle("Allow Parent Contributions", isOn: $allowParentContributions)
                        .disabled(!shareWithParents)
                }

                Section {
                    Text("Parents will be able to view and download photos from this album.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createAlbum()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func createAlbum() {
        guard let classId = classroomViewModel.selectedClassroom?.id,
              let userId = authViewModel.currentUser?.id,
              let userName = authViewModel.currentUser?.displayName else { return }

        Task {
            await albumViewModel.createAlbum(
                classId: classId,
                name: name,
                description: description,
                createdBy: userId,
                createdByName: userName,
                isSharedWithParents: shareWithParents,
                allowParentContributions: allowParentContributions
            )
            dismiss()
        }
    }
}

#Preview {
    PhotoAlbumsView()
        .environmentObject(AuthViewModel())
        .environmentObject(ClassroomViewModel())
        .environmentObject(PhotoAlbumViewModel())
}
