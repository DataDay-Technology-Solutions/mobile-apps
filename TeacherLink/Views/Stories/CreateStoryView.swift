//
//  CreateStoryView.swift
//  TeacherLink
//

import SwiftUI
import PhotosUI

struct CreateStoryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @EnvironmentObject var storyViewModel: StoryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var content = ""
    @State private var isAnnouncement = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImageData: [Data] = []
    @State private var showPhotoPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Announcement Toggle
                if authViewModel.isTeacher {
                    HStack {
                        Toggle(isOn: $isAnnouncement) {
                            HStack {
                                Image(systemName: "megaphone.fill")
                                    .foregroundColor(.orange)
                                Text("Post as Announcement")
                            }
                        }
                        .tint(.orange)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                }

                // Text Input
                TextEditor(text: $content)
                    .padding()
                    .frame(minHeight: 150)
                    .overlay(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("What's happening in class today?")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 24)
                                .allowsHitTesting(false)
                        }
                    }

                // Selected Photos Preview
                if !selectedImageData.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(selectedImageData.enumerated()), id: \.offset) { index, data in
                                if let uiImage = UIImage(data: data) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .clipped()
                                            .cornerRadius(8)

                                        Button {
                                            selectedImageData.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .background(Circle().fill(.black.opacity(0.5)))
                                        }
                                        .padding(4)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color(.systemGray6))
                }

                // Upload Progress
                if storyViewModel.isUploading {
                    VStack(spacing: 8) {
                        ProgressView(value: storyViewModel.uploadProgress)
                            .tint(.blue)
                        Text("Uploading...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }

                Spacer()

                // Bottom Toolbar
                HStack {
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 4,
                        matching: .images
                    ) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }

                    Spacer()

                    Text("\(content.count)/500")
                        .font(.caption)
                        .foregroundColor(content.count > 500 ? .red : .secondary)
                }
                .padding()
                .background(Color(.systemGray6))
            }
            .navigationTitle("New Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        Task {
                            await postStory()
                            dismiss()
                        }
                    }
                    .font(.headline)
                    .disabled(!canPost || storyViewModel.isUploading)
                }
            }
            .onChange(of: selectedPhotos) { _, newItems in
                Task {
                    selectedImageData = []
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            selectedImageData.append(data)
                        }
                    }
                }
            }
        }
    }

    private var canPost: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        content.count <= 500
    }

    private func postStory() async {
        guard let classId = classroomViewModel.selectedClassroom?.id,
              let userId = authViewModel.currentUser?.id,
              let userName = authViewModel.currentUser?.displayName else { return }

        if let firstImageData = selectedImageData.first {
            await storyViewModel.createPhotoStory(
                classId: classId,
                authorId: userId,
                authorName: userName,
                content: content,
                imageData: firstImageData
            )
        } else {
            await storyViewModel.createTextStory(
                classId: classId,
                authorId: userId,
                authorName: userName,
                content: content,
                isAnnouncement: isAnnouncement
            )
        }
    }
}

#Preview {
    CreateStoryView()
        .environmentObject(AuthViewModel())
        .environmentObject(ClassroomViewModel())
        .environmentObject(StoryViewModel())
}
