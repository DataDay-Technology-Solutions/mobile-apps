//
//  StoriesView.swift
//  TeacherLink
//

import SwiftUI

struct StoriesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @EnvironmentObject var storyViewModel: StoryViewModel

    @State private var showCreateStory = false
    @State private var showClassPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Class Selector
                if classroomViewModel.classrooms.count > 1 {
                    ClassSelectorBar(
                        classroom: classroomViewModel.selectedClassroom,
                        showPicker: $showClassPicker
                    )
                }

                // Stories Feed
                if storyViewModel.isLoading && storyViewModel.stories.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if storyViewModel.stories.isEmpty {
                    EmptyStoriesView(isTeacher: authViewModel.isTeacher)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(storyViewModel.stories) { story in
                                StoryCard(story: story)
                                    .environmentObject(storyViewModel)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        if let classId = classroomViewModel.selectedClassroom?.id {
                            await storyViewModel.loadStories(classId: classId)
                        }
                    }
                }
            }
            .navigationTitle(classroomViewModel.selectedClassroom?.name ?? "Stories")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if authViewModel.isTeacher {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showCreateStory = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateStory) {
                CreateStoryView()
                    .environmentObject(classroomViewModel)
                    .environmentObject(storyViewModel)
            }
            .sheet(isPresented: $showClassPicker) {
                ClassPickerView(
                    classrooms: classroomViewModel.classrooms,
                    selectedClassroom: $classroomViewModel.selectedClassroom
                ) { classroom in
                    classroomViewModel.selectClassroom(classroom)
                    if let classId = classroom.id {
                        storyViewModel.listenToStories(classId: classId)
                    }
                    showClassPicker = false
                }
            }
            .onChange(of: classroomViewModel.selectedClassroom?.id) { _, newValue in
                if let classId = newValue {
                    storyViewModel.listenToStories(classId: classId)
                }
            }
        }
    }
}

struct ClassSelectorBar: View {
    let classroom: Classroom?
    @Binding var showPicker: Bool

    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(classroom?.name.prefix(1) ?? "?")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    )

                Text(classroom?.name ?? "Select Class")
                    .font(.subheadline.bold())

                Image(systemName: "chevron.down")
                    .font(.caption)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
        .foregroundColor(.primary)
    }
}

struct EmptyStoriesView: View {
    let isTeacher: Bool

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "photo.stack")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Stories Yet")
                .font(.title2.bold())

            Text(isTeacher
                 ? "Share your first classroom moment with parents!"
                 : "Your teacher hasn't posted any stories yet.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
    }
}

#Preview {
    StoriesView()
        .environmentObject(AuthViewModel())
        .environmentObject(ClassroomViewModel())
        .environmentObject(StoryViewModel())
}
