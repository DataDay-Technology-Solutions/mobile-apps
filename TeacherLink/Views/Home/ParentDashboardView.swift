//
//  ParentDashboardView.swift
//  HallPass (formerly TeacherLink)
//
//  Main dashboard for parents using Supabase
//

import SwiftUI

struct ParentDashboardView: View {
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

            // Messages Tab
            MessagesView()
                .tabItem {
                    Label("Messages", systemImage: "message")
                }

            // Points Tab (view only for parents)
            ParentScoreView()
                .tabItem {
                    Label("Points", systemImage: "star")
                }

            // Settings Tab
            ParentSettingsView()
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

                // Load classrooms for this parent
                Task {
                    await classroomViewModel.loadClassrooms(for: user)
                }
            }
        }
    }
}

// MARK: - Parent Settings View
struct ParentSettingsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingJoinClass = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)

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

                Section("Classroom") {
                    Button {
                        showingJoinClass = true
                    } label: {
                        Label("Join a Class", systemImage: "plus.circle")
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
            .sheet(isPresented: $showingJoinClass) {
                JoinClassView()
            }
        }
    }
}

#Preview {
    ParentDashboardView()
        .environmentObject(AuthenticationService())
}
