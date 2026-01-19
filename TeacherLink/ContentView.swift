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
            } else if authService.isAuthenticated {
                // User is logged in - route based on role
                if let appUser = authService.appUser {
                    switch appUser.role {
                    case .teacher:
                        TeacherDashboardView()
                    case .parent:
                        ParentDashboardView()
                    case .student:
                        // Students use parent view for now
                        ParentDashboardView()
                    }
                } else {
                    // Authenticated but no user profile yet - show loading
                    ProgressView("Setting up your account...")
                }
            } else {
                // Not logged in - show login
                LoginView()
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationService())
}
