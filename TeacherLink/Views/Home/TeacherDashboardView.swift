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

    var body: some View {
        TabView {
            // Stories/Feed Tab
            StoriesView()
                .tabItem {
                    Label("Feed", systemImage: "newspaper")
                }

            // Students Tab
            StudentsView()
                .tabItem {
                    Label("Students", systemImage: "person.3")
                }

            // Messages Tab
            MessagesView()
                .tabItem {
                    Label("Messages", systemImage: "message")
                }

            // Points Tab
            PointsView()
                .tabItem {
                    Label("Points", systemImage: "star")
                }

            // Settings Tab
            TeacherSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .environmentObject(authViewModel)
        .environmentObject(classroomViewModel)
        .environmentObject(storyViewModel)
        .environmentObject(messageViewModel)
        .environmentObject(pointsViewModel)
        .onAppear {
            // Sync auth state from AuthenticationService to AuthViewModel
            if let appUser = authService.appUser {
                let user = User(
                    id: appUser.id,
                    email: appUser.email,
                    name: appUser.name,
                    displayName: appUser.name,
                    role: appUser.role
                )
                authViewModel.currentUser = user
                authViewModel.isAuthenticated = true

                // Load classrooms for this teacher
                Task {
                    await classroomViewModel.loadClassrooms(for: user)
                }
            }
        }
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
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading) {
                            Text(authService.currentUserName)
                                .font(.headline)
                            Text(authService.appUser?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

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
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }

                    Button {
                        showCreateClass = true
                    } label: {
                        Label("Create New Class", systemImage: "plus.circle")
                    }
                }

                // Class Code Section for selected classroom
                if let classroom = classroomViewModel.selectedClassroom {
                    Section("Invite Parents") {
                        NavigationLink {
                            ClassInviteView(classroom: classroom)
                        } label: {
                            Label("Class Code: \(classroom.classCode)", systemImage: "qrcode")
                        }

                        Button {
                            UIPasteboard.general.string = classroom.classCode
                        } label: {
                            Label("Copy Code", systemImage: "doc.on.doc")
                        }
                    }
                }

                Section {
                    Button(action: {
                        authService.signOut()
                    }) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
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
