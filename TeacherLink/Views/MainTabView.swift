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
    @StateObject private var albumViewModel = PhotoAlbumViewModel()

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            StoriesView()
                .environmentObject(classroomViewModel)
                .environmentObject(storyViewModel)
                .tabItem {
                    Label("Feed", systemImage: "house.fill")
                }
                .tag(0)

            PhotoAlbumsView()
                .environmentObject(classroomViewModel)
                .environmentObject(albumViewModel)
                .tabItem {
                    Label("Albums", systemImage: "photo.on.rectangle.angled")
                }
                .tag(1)

            MessagesView()
                .environmentObject(classroomViewModel)
                .environmentObject(messageViewModel)
                .tabItem {
                    Label("Messages", systemImage: "message.fill")
                }
                .badge(messageViewModel.totalUnreadCount > 0 ? messageViewModel.totalUnreadCount : 0)
                .tag(2)

            if authViewModel.isTeacher {
                FeaturesHubView()
                    .environmentObject(classroomViewModel)
                    .tabItem {
                        Label("Features", systemImage: "sparkles")
                    }
                    .tag(3)

                ClassroomManagementView()
                    .environmentObject(classroomViewModel)
                    .tabItem {
                        Label("Manage", systemImage: "person.crop.rectangle.stack.fill")
                    }
                    .tag(4)
            }

            SettingsView()
                .environmentObject(classroomViewModel)
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
                .tag(5)
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
                await albumViewModel.loadAlbums(classId: classId)
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
