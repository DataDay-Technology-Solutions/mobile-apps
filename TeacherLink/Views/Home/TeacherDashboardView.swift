//
//  TeacherDashboardView.swift
//  HallPass (formerly TeacherLink)
//
//  Main dashboard for teachers using Supabase
//

import SwiftUI

struct TeacherDashboardView: View {
    @EnvironmentObject var authService: AuthenticationService

    // Create view models for child views
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var classroomViewModel = ClassroomViewModel()
    @StateObject private var storyViewModel = StoryViewModel()
    @StateObject private var messageViewModel = MessageViewModel()
    @StateObject private var pointsViewModel = PointsViewModel()

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Stories/Feed Tab
            StoriesView()
                .tabItem {
                    Label("Feed", systemImage: "house.fill")
                }
                .tag(0)

            // Students Tab
            StudentsView()
                .tabItem {
                    Label("Students", systemImage: "person.3.fill")
                }
                .tag(1)

            // Messages Tab
            MessagesView()
                .tabItem {
                    Label("Messages", systemImage: "message.fill")
                }
                .badge(messageViewModel.totalUnreadCount > 0 ? messageViewModel.totalUnreadCount : 0)
                .tag(2)

            // Points Tab
            PointsView()
                .tabItem {
                    Label("Points", systemImage: "star.fill")
                }
                .tag(3)

            // Settings Tab
            TeacherSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .environmentObject(authViewModel)
        .environmentObject(classroomViewModel)
        .environmentObject(storyViewModel)
        .environmentObject(messageViewModel)
        .environmentObject(pointsViewModel)
        .onAppear {
            setupTeacherData()
        }
    }

    private func setupTeacherData() {
        guard let appUser = authService.appUser else { return }

        // Sync auth state from AuthenticationService to AuthViewModel
        let user = User(
            id: appUser.id,
            email: appUser.email,
            name: appUser.name,
            displayName: appUser.name,
            role: appUser.role
        )
        authViewModel.currentUser = user
        authViewModel.isAuthenticated = true

        // Load classrooms for this teacher (this also loads students)
        Task {
            await classroomViewModel.loadClassrooms(for: user)

            // After classrooms load, load stories for the selected classroom
            if let classId = classroomViewModel.selectedClassroom?.id {
                storyViewModel.listenToStories(classId: classId)
            }
        }

        // Load conversations for this teacher
        messageViewModel.listenToConversations(userId: appUser.id, role: .teacher)
    }
}

// MARK: - Teacher Settings View
struct TeacherSettingsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @State private var showCreateClass = false

    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.blue.gradient)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(authService.currentUserName.prefix(1).uppercased())
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(authService.currentUserName)
                                .font(.headline)
                            Text(authService.appUser?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Classes Section
                Section("My Classes") {
                    ForEach(classroomViewModel.classrooms, id: \.uniqueId) { classroom in
                        Button {
                            classroomViewModel.selectClassroom(classroom)
                        } label: {
                            HStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Text(classroom.name.prefix(1))
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(classroom.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("\(classroom.gradeLevel) • \(classroom.studentCount) students")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if classroom.id == classroomViewModel.selectedClassroom?.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }

                    Button {
                        showCreateClass = true
                    } label: {
                        Label("Create New Class", systemImage: "plus.circle.fill")
                    }
                }

                // Class Code Section for selected classroom
                if let classroom = classroomViewModel.selectedClassroom {
                    Section("Invite Parents") {
                        NavigationLink {
                            ClassInviteView(classroom: classroom)
                        } label: {
                            HStack {
                                Label("Class Code", systemImage: "qrcode")
                                Spacer()
                                Text(classroom.classCode)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.blue)
                            }
                        }

                        Button {
                            UIPasteboard.general.string = classroom.classCode
                        } label: {
                            Label("Copy Code", systemImage: "doc.on.doc")
                        }
                    }
                }

                // Sign Out
                Section {
                    Button(role: .destructive) {
                        authService.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showCreateClass) {
                CreateClassView()
                    .environmentObject(authViewModel)
                    .environmentObject(classroomViewModel)
            }
        }
    }
}

#Preview {
    TeacherDashboardView()
        .environmentObject(AuthenticationService())
}
