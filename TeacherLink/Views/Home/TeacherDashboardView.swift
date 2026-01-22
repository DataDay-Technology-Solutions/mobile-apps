//
//  TeacherDashboardView.swift
//  HallPass (formerly TeacherLink)
//
//  Main dashboard for teachers using Supabase
//

import SwiftUI

struct TeacherDashboardView: View {
    @EnvironmentObject var authService: AuthenticationService

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
    }
}

// MARK: - Teacher Settings View
struct TeacherSettingsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var classroomViewModel = ClassroomViewModel()
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

                Section("Classroom") {
                    Button {
                        showCreateClass = true
                    } label: {
                        Label("Create Class", systemImage: "plus.circle")
                    }

                    if let classroom = classroomViewModel.selectedClassroom {
                        NavigationLink {
                            ClassInviteView(classroom: classroom)
                        } label: {
                            Label("Class Code: \(classroom.classCode)", systemImage: "qrcode")
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
                    .environmentObject(AuthViewModel())
                    .environmentObject(classroomViewModel)
            }
        }
    }
}

#Preview {
    TeacherDashboardView()
        .environmentObject(AuthenticationService())
}
