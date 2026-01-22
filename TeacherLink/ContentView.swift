//
//  ContentView.swift
//  TeacherLink
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthenticationService

    var body: some View {
        Group {
            if authService.isLoading {
                // Show loading while checking auth state
                ProgressView("Loading...")
            } else if authService.needsEmailConfirmation {
                // Email confirmation required
                EmailConfirmationView()
                    .environmentObject(authService)
            } else if authService.isAuthenticated, let appUser = authService.appUser {
                // User is logged in - route based on role
                switch appUser.role {
                case .admin:
                    AdminDashboardView()
                        .environmentObject(authService)
                case .teacher:
                    TeacherDashboardView()
                        .environmentObject(authService)
                case .parent:
                    ParentDashboardView()
                        .environmentObject(authService)
                case .student:
                    // Students use parent view for now
                    ParentDashboardView()
                        .environmentObject(authService)
                }
            } else if authService.isAuthenticated {
                // Authenticated but no user profile yet - show setup screen
                AccountSetupView()
                    .environmentObject(authService)
            } else {
                // Not logged in - show login
                SupabaseLoginView()
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationService())
}
