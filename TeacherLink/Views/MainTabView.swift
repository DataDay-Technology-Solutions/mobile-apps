//
//  MainTabView.swift
//  TeacherLink
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var classroomViewModel = ClassroomViewModel()
    @StateObject private var storyViewModel = StoryViewModel()
    @StateObject private var messageViewModel = MessageViewModel()

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            StoriesView()
                .environmentObject(classroomViewModel)
                .environmentObject(storyViewModel)
                .tabItem {
                    Label("Stories", systemImage: "photo.stack.fill")
                }
                .tag(0)

            MessagesView()
                .environmentObject(classroomViewModel)
                .environmentObject(messageViewModel)
                .tabItem {
                    Label("Messages", systemImage: "message.fill")
                }
                .badge(messageViewModel.totalUnreadCount > 0 ? messageViewModel.totalUnreadCount : 0)
                .tag(1)

            if authViewModel.isTeacher {
                PointsView()
                    .environmentObject(classroomViewModel)
                    .tabItem {
                        Label("Points", systemImage: "star.fill")
                    }
                    .tag(2)

                StudentsView()
                    .environmentObject(classroomViewModel)
                    .tabItem {
                        Label("Students", systemImage: "person.3.fill")
                    }
                    .tag(3)
            }

            SettingsView()
                .environmentObject(classroomViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .onAppear {
            loadData()
        }
    }

    private func loadData() {
        guard let user = authViewModel.currentUser else { return }

        Task {
            await classroomViewModel.loadClassrooms(for: user)

            if let userId = user.id {
                messageViewModel.listenToConversations(userId: userId)
            }

            if let classId = classroomViewModel.selectedClassroom?.id {
                storyViewModel.listenToStories(classId: classId)
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
