//
//  PhotoAlbumViewModel.swift
//  TeacherLink
//
//  ViewModel for photo albums (PhotoCircle-style)
//

import Foundation
import SwiftUI

@MainActor
class PhotoAlbumViewModel: ObservableObject {
    @Published var albums: [PhotoAlbum] = []
    @Published var currentAlbumPhotos: [AlbumPhoto] = []
    @Published var photoComments: [PhotoComment] = []
    @Published var isLoading = false
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var errorMessage: String?
    @Published var searchQuery: String = ""

    var filteredAlbums: [PhotoAlbum] {
        if searchQuery.isEmpty {
            return albums
        }
        return albums.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery) ||
            $0.description.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    init() {
        if USE_MOCK_DATA {
            albums = MockDataService.shared.photoAlbums
        }
    }

    func loadAlbums(classId: String) async {
        isLoading = true
        errorMessage = nil

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 300_000_000)
            albums = MockDataService.shared.photoAlbums.filter { $0.classId == classId }
        }

        isLoading = false
    }

    func createAlbum(
        classId: String,
        name: String,
        description: String,
        createdBy: String,
        createdByName: String,
        isSharedWithParents: Bool = true,
        allowParentContributions: Bool = false
    ) async {
        isLoading = true

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 300_000_000)

            let album = PhotoAlbum(
                id: UUID().uuidString,
                classId: classId,
                name: name,
                description: description,
                createdBy: createdBy,
                createdByName: createdByName,
                isSharedWithParents: isSharedWithParents,
                allowParentContributions: allowParentContributions
            )
            albums.insert(album, at: 0)
        }

        isLoading = false
    }

    func deleteAlbum(_ album: PhotoAlbum) async {
        if USE_MOCK_DATA {
            albums.removeAll { $0.id == album.id }
        }
    }

    // MARK: - Photos

    func loadPhotos(albumId: String) async {
        isLoading = true

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 300_000_000)
            currentAlbumPhotos = MockDataService.shared.albumPhotos.filter { $0.albumId == albumId }
        }

        isLoading = false
    }

    func addPhoto(
        albumId: String,
        imageData: Data,
        caption: String?,
        uploadedBy: String,
        uploadedByName: String
    ) async {
        isUploading = true
        uploadProgress = 0

        if USE_MOCK_DATA {
            // Simulate upload progress
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                uploadProgress = Double(i) / 10.0
            }

            let photo = AlbumPhoto(
                id: UUID().uuidString,
                albumId: albumId,
                imageURL: "mock://photo/\(UUID().uuidString)",
                caption: caption,
                uploadedBy: uploadedBy,
                uploadedByName: uploadedByName
            )
            currentAlbumPhotos.insert(photo, at: 0)

            // Update album photo count
            if let index = albums.firstIndex(where: { $0.id == albumId }) {
                albums[index].photoCount += 1
            }
        }

        isUploading = false
    }

    func deletePhoto(_ photo: AlbumPhoto) async {
        if USE_MOCK_DATA {
            currentAlbumPhotos.removeAll { $0.id == photo.id }

            if let index = albums.firstIndex(where: { $0.id == photo.albumId }) {
                albums[index].photoCount = max(0, albums[index].photoCount - 1)
            }
        }
    }

    func toggleLike(photo: AlbumPhoto, userId: String) async {
        guard let photoId = photo.id,
              let index = currentAlbumPhotos.firstIndex(where: { $0.id == photoId }) else { return }

        if USE_MOCK_DATA {
            var updatedPhoto = currentAlbumPhotos[index]
            if updatedPhoto.likedByIds.contains(userId) {
                updatedPhoto.likedByIds.removeAll { $0 == userId }
                updatedPhoto.likeCount = max(0, updatedPhoto.likeCount - 1)
            } else {
                updatedPhoto.likedByIds.append(userId)
                updatedPhoto.likeCount += 1
            }
            currentAlbumPhotos[index] = updatedPhoto
        }
    }

    // MARK: - Comments

    func loadComments(photoId: String) async {
        if USE_MOCK_DATA {
            photoComments = [
                PhotoComment(id: "pc1", photoId: photoId, authorId: "parent1", authorName: "Sarah Smith", content: "What a great photo!", createdAt: Date().addingTimeInterval(-1800)),
                PhotoComment(id: "pc2", photoId: photoId, authorId: "parent2", authorName: "John Brown", content: "Love this!", createdAt: Date().addingTimeInterval(-3600))
            ]
        }
    }

    func addComment(photoId: String, authorId: String, authorName: String, content: String) async {
        if USE_MOCK_DATA {
            let comment = PhotoComment(
                id: UUID().uuidString,
                photoId: photoId,
                authorId: authorId,
                authorName: authorName,
                content: content
            )
            photoComments.append(comment)

            if let index = currentAlbumPhotos.firstIndex(where: { $0.id == photoId }) {
                currentAlbumPhotos[index].commentCount += 1
            }
        }
    }

    func deleteComment(_ comment: PhotoComment) async {
        if USE_MOCK_DATA {
            photoComments.removeAll { $0.id == comment.id }

            if let index = currentAlbumPhotos.firstIndex(where: { $0.id == comment.photoId }) {
                currentAlbumPhotos[index].commentCount = max(0, currentAlbumPhotos[index].commentCount - 1)
            }
        }
    }

    // MARK: - Search

    func searchPhotos(query: String, classId: String) -> [AlbumPhoto] {
        guard !query.isEmpty else { return [] }

        if USE_MOCK_DATA {
            return MockDataService.shared.albumPhotos.filter {
                $0.caption?.localizedCaseInsensitiveContains(query) == true
            }
        }
        return []
    }
}
