//
//  ParentDashboardView.swift
//  HallPass (formerly TeacherLink)
//
//  Main dashboard for parents using Supabase
//

import SwiftUI

struct ParentDashboardView: View {
    @EnvironmentObject var authService: AuthenticationService

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
